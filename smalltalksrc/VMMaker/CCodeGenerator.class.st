"
This class oversees the translation of a subset of Smalltalk to C, allowing the comforts of Smalltalk during development and the efficiency and portability of C for the resulting interpreter.  
See VMMaker for more useful info
"
Class {
	#name : #CCodeGenerator,
	#superclass : #Object,
	#instVars : [
		'vmClass',
		'structClasses',
		'translationDict',
		'asArgumentTranslationDict',
		'inlineList',
		'constants',
		'variables',
		'variableDeclarations',
		'scopeStack',
		'methods',
		'macros',
		'apiMethods',
		'apiVariables',
		'kernelReturnTypes',
		'currentMethod',
		'headerFiles',
		'globalVariableUsage',
		'useSymbolicConstants',
		'generateDeadCode',
		'requiredSelectors',
		'previousCommentMarksInlining',
		'previousCommenter',
		'logger',
		'suppressAsmLabels',
		'asmLabelCounts',
		'pools',
		'selectorTranslations',
		'staticallyResolvedPolymorphicReceivers',
		'optionsDictionary',
		'breakSrcInlineSelectors',
		'breakDestInlineSelectors',
		'breakOnInline',
		'vmMaker'
	],
	#classVars : [
		'NoRegParmsInAssertVMs'
	],
	#pools : [
		'VMBasicConstants'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #'class initialization' }
CCodeGenerator class >> initialize [
	"CCodeGenerator initialize"

	NoRegParmsInAssertVMs := true
		"If NoRegParmsInAssertVMs is true the generator spits out an attribute turning off register parameters for static functions in the Assert and Debug VMs which makes debugging easier, since all functions can be safely called from gdb.  One might hope that -mregparm=0 would work but at least on Mac OS X's gcc 4.2.1 it does not and hence we have to use a per funciton attribute.  Sigh..."
]

{ #category : #testing }
CCodeGenerator class >> isVarargsSelector: aSymbol [
	^aSymbol endsWith: 'printf:'
]

{ #category : #'C code generator' }
CCodeGenerator class >> monticelloDescriptionFor: aClass [
	"Answer a suitable Monticello package stamp to include in the header."
	| pkgInfo pkg uuid |
	pkgInfo := PackageOrganizer default packageOfClass: aClass.
	pkg := MCWorkingCopy allManagers detect: [:ea| ea packageName = pkgInfo packageName].
	pkg ancestry ancestors isEmpty ifFalse:
		[uuid := pkg ancestry ancestors first id].
	^aClass name, (pkg modified ifTrue: [' * '] ifFalse: [' ']), pkg ancestry ancestorString, ' uuid: ', uuid asString
]

{ #category : #'removing from system' }
CCodeGenerator class >> removeCompilerMethods [
	"Before removing the C code generator classes from the system, use this method to remove the compiler node methods that support it. This avoids leaving dangling references to C code generator classes in the compiler node classes."

	ParseNode withAllSubclasses do: [ :nodeClass |
		nodeClass removeCategory: 'C translation'.
	].
	Smalltalk at: #AbstractSound ifPresent: [:abstractSound |
		 abstractSound class removeCategory: 'primitive generation'].

]

{ #category : #'C code generator' }
CCodeGenerator class >> shortMonticelloDescriptionForClass: aClass [
	"Answer a suitable Monticello package stamp to include in a moduleName."
	| mdesc |
	mdesc := [self monticelloDescriptionFor: aClass]
				on: Error
				do: [:ex| ^' ', Date today asString].
	^mdesc copyFrom: 1 to: (mdesc indexOfSubCollection: ' uuid:') - 1
]

{ #category : #accessing }
CCodeGenerator >> abortBlock [
	^vmMaker ifNotNil: [:vmm| vmm abortBlock]
]

{ #category : #'spur primitive compilation' }
CCodeGenerator >> accessorChainsForMethod: method interpreterClass: interpreterClass [
	"Answer a set of access paths from arguments through objects, in the method, assuming
	 it is a primitive. This is in support of Spur's lazy become.  A primitive may fail because it
	 may encounter a forwarder.  The primitive failure code needs to know to what depth it
	 must follow arguments to follow forwarders and, if any are found and followed, retry the
	 primitive. This method determines that depth. It starts by collecting references to the
	 stack and then follows these through assignments to variables and use of accessor
	 methods such as fetchPointer:ofObject:. For example
		| obj field  |
		obj := self stackTop.
		field := objectMemory fetchPointer: 1 ofObject: obj.
		self storePointer: 1 ofObject: field withValue: (self stackValue: 1)
	has depth 2, since field is accessed, and field is an element of obj."

	| accessors assignments roots chains extendedChains extended lastPass |
	self accessorsAndAssignmentsForMethod: method
		actuals: (self actualsForMethod: method)
		depth: 0
		interpreterClass: interpreterClass
		into: [:theRoots :theAccessors :theAssignments|
			roots := theRoots.
			accessors := theAccessors.
			assignments := theAssignments].
	"Compute the transitive closure of assignments of accessor sends or variables to variables from the roots.
	 Start from the stack accesses (the roots).
	 On the last pass look only for accessors of the targets of the tip assignments."
	chains := OrderedCollection new.
	roots do: [:root| chains addAll: (assignments
									select: [:assignment| assignment expression = root]
									thenCollect: [:assignment| OrderedCollection with: assignment])].
	lastPass := false.
	[extended := false.
	 extendedChains := OrderedCollection new: chains size * 2.
	 chains do:
		[:chain| | tip refs accessorRefs variableRefs |
		tip := chain last variable.
		refs := accessors select: [:send| send args anySatisfy: [:arg| tip isSameAs: arg]].
		lastPass ifFalse:
			[accessorRefs := refs collect: [:send|
											assignments
												detect: [:assignment|
														assignment expression = send
														and: [(chain includes: assignment) not]]
												ifNone: []]
									thenSelect: [:assignmentOrNil| assignmentOrNil notNil].
			 variableRefs := assignments select:
								[:assignment|
								 (tip isSameAs: assignment expression)
								 and: [(tip isSameAs: assignment variable) not
								 and: [(chain includes: assignment) not]]].
			 refs := (Set withAll: accessorRefs) addAll: variableRefs; yourself].
		refs isEmpty
			ifTrue:
				[extendedChains add: chain]
			ifFalse:
				[lastPass ifFalse: [extended := true].
				 self assert: (refs noneSatisfy: [:assignment| chain includes: assignment]).
				 extendedChains addAll: (refs collect: [:assignment| chain, {assignment}])]].
	 extended or: [lastPass not]] whileTrue:
		[chains := extendedChains.
		 extended ifFalse: [lastPass := true]].
	^chains
]

{ #category : #'spur primitive compilation' }
CCodeGenerator >> accessorDepthDeterminationFollowsSelfSends [
	^false
]

{ #category : #'spur primitive compilation' }
CCodeGenerator >> accessorDepthForChain: chain [ "OrderedCollection"
	"Answer the actual number of accessors in the access chain, filtering out assignments of variables to variables."
	| accessorDepth |
	accessorDepth := 0.
	chain do:
		[:node|
		 ((node isAssignment and: [node expression isVariable])
		  or: [node isSend and: [SpurMemoryManager isSameLevelObjectAccessor: node selector]]) ifFalse:
			[accessorDepth := accessorDepth + 1]].
	^accessorDepth
]

{ #category : #'spur primitive compilation' }
CCodeGenerator >> accessorDepthForMethod: method [
	"Compute the depth the method traverses object structure, assuming it is a primitive.
	 This is in support of Spur's lazy become.  A primitive may fail because it may encounter
	 a forwarder.  The primitive failure code needs to know to what depth it must follow
	  arguments to follow forwarders and, if any are found and followed, retry the primitive.
	 This method determines that depth. It starts by collecting references to the stack and
	 then follows these through assignments to variables and use of accessor methods
	 such as fetchPointer:ofObject:. For example
		| obj field  |
		obj := self stackTop.
		field := objectMemory fetchPointer: 1 ofObject: obj.
		self storePointer: 1 ofObject: field withValue: (self stackValue: 1)
	has depth 2, since field is accessed, and field is an element of obj."

	^((method definingClass includesSelector: method selector) ifTrue:
			[(method definingClass >> method selector) pragmaAt: #accessorDepth:])
		ifNil:
			[((self
					accessorChainsForMethod: method
					interpreterClass: (vmClass ifNil: [StackInterpreter]))
				inject: 0
				into: [:length :chain| length max: (self accessorDepthForChain: chain)]) - 1]
		ifNotNil: [:pragma| pragma arguments first]
]

{ #category : #'spur primitive compilation' }
CCodeGenerator >> accessorDepthForSelector: selector [
	^(selector = #initialiseModule
	   or: [InterpreterPlugin includesSelector: selector]) ifFalse:
		[(self methodNamed: selector) ifNotNil:
			[:m| self accessorDepthForMethod: m]]
]

{ #category : #'spur primitive compilation' }
CCodeGenerator >> accessorsAndAssignmentsForMethod: method actuals: actualParameters depth: depth interpreterClass: interpreterClass into: aTrinaryBlock [
	"Evaluate aTrinaryBlock with the root accessor sends, accessor sends and assignments in the method."
	| accessors assignments roots |
	accessors := Set new.
	assignments := Set new.
	roots := Set new.
	actualParameters with: method args do:
		[:actual :argName|
		 (actual isVariable or: [actual isSend]) ifTrue:
			[(actual isSend and: [self isStackAccessor: actual selector given: interpreterClass]) ifTrue:
				[roots add: actual].
			assignments add: (TAssignmentNode new
									setVariable: (TVariableNode new setName: argName)
									expression: actual)]].
	method parseTree nodesDo:
		[:node|
		node isSend ifTrue:
			[(self isStackAccessor: node selector given: interpreterClass) ifTrue:
				[roots add: node].
			 (self isObjectAccessor: node selector given: interpreterClass) ifTrue:
				[accessors add: node].
			 (self accessorDepthDeterminationFollowsSelfSends
			  and: [node receiver isVariable
			  and: [node receiver name = 'self'
			  and: [roots isEmpty
				or: [node args anySatisfy:
					[:arg|
					 (roots includes: arg)
					 or: [(accessors includes: arg)
					 or: [assignments anySatisfy: [:assignment| assignment variable isSameAs: arg]]]]]]]]) ifTrue:
				[self accessorsAndAssignmentsForSubMethodNamed: node selector
					actuals: node args
					depth: depth + 1
					interpreterClass: interpreterClass
					into: [:subRoots :subAccessors :subAssignments|
						(subRoots isEmpty and: [subAccessors isEmpty and: [subAssignments isEmpty]]) ifFalse:
							[roots addAll: subRoots.
							 accessors add: node.
							 accessors addAll: subAccessors.
							 assignments addAll: subAssignments]]]].
		(node isAssignment
		 and: [(node expression isSend and: [SpurMemoryManager isTerminalObjectAccessor: node expression selector]) not
		 and: [(roots includes: node expression)
			or: [(accessors includes: node expression)
			or: [node expression isVariable and: [node expression name ~= 'nil']]]]]) ifTrue:
			[assignments add: node]].
	^aTrinaryBlock
		value: roots
		value: accessors
		value: assignments
]

{ #category : #'spur primitive compilation' }
CCodeGenerator >> actualsForMethod: aTMethod [
	"Normal primitives have no arguments, but translated primitives do.
	 This class doesn't handle translated primitives and so smply answers an empty array.
	 Subclasses override as required."
	^#()
]

{ #category : #public }
CCodeGenerator >> addAllClassVarsFor: aClass [
	"Add the class variables for the given class (and its superclasses) to the code base as constants."

	| allClasses |
	allClasses := aClass withAllSuperclasses.
	allClasses do: [:c | self addClassVarsFor: c].

]

{ #category : #public }
CCodeGenerator >> addClass: aClass [
	"Add the variables and methods of the given class to the code base."

	aClass prepareToBeAddedToCodeGenerator: self.
	self checkClassForNameConflicts: aClass.
	self addClassVarsFor: aClass.
	"ikp..."
	self addPoolVarsFor: aClass.
	(aClass inheritsFrom: VMStructType) ifFalse:
		[variables addAll: (self instVarNamesForClass: aClass)].
	self retainMethods: (aClass requiredMethodNames: self options).
	
	UIManager default
		displayProgress: 'Adding Class ' , aClass name , '...'
		from: 0
		to: aClass selectors size
		during:
			[:bar |
			 aClass selectors doWithIndex:
				[:sel :i | | source |
				bar value: i.
				self addMethodFor: aClass selector: sel]].
	aClass declareCVarsIn: self
]

{ #category : #public }
CCodeGenerator >> addClassVarsFor: aClass [
	"Add the class variables for the given class to the code base as constants."
	aClass classPool associationsDo:
		[:assoc | self addConstantForBinding: assoc]
]

{ #category : #public }
CCodeGenerator >> addConstantForBinding: variableBinding [
	"Add the pool variable to the code base as a constant."
	| node val |
	val := variableBinding value.
	node := (useSymbolicConstants and: [self isCLiteral: val])
				ifTrue:[TDefineNode new
							setName: variableBinding key
							value: variableBinding value]
				ifFalse:[TConstantNode new setValue: variableBinding value].
	constants at: variableBinding key put: node
]

{ #category : #public }
CCodeGenerator >> addHeaderFile: aString [
	"Add a header file. As a hack we allow C preprocessor defs such as #ifdef"
	self assert: (('"<#' includes: aString first) or: [(aString last: 2) = '_H']).
	(aString first ~= $#
	 and: [headerFiles includes: aString]) ifTrue:
		[logger nextPutAll: 'warning, attempt to include ', aString, ' a second time'; cr; flush.
		 ^self].
	headerFiles addLast: aString
]

{ #category : #public }
CCodeGenerator >> addHeaderFileFirst: aString [
	"Add a header file to the front of the sequence."
	self assert: (('"<' includes: aString first) and: ['">' includes: aString last]).
	self assert: (headerFiles includes: aString) not.
	headerFiles addFirst: aString
]

{ #category : #public }
CCodeGenerator >> addMacro: aString for: selector [
	"Add a macro. aString must be the macro arguments and body without the leading #define or name"
	macros at: selector put: aString
]

{ #category : #utilities }
CCodeGenerator >> addMethod: aTMethod [
	"Add the given method to the code base and answer it.
	 Only allow duplicate definitions for struct accessors, since we don't actually
	 generate code for these methods and hence the conflict doesn't matter.
	 Allow subclasses to redefine methods (Smalltalk has inheritance after all)."

	(methods at: aTMethod selector ifAbsent: []) ifNotNil:
		[:conflict |
		aTMethod compiledMethod isSubclassResponsibility ifTrue:
			[^nil].
		(conflict isStructAccessor
		 and: [aTMethod isStructAccessor
		 and: [conflict compiledMethod decompileString = aTMethod compiledMethod decompileString]]) ifTrue:
			[^nil].
		((aTMethod definingClass inheritsFrom: conflict definingClass)
		 or: [(aTMethod compiledMethod pragmaAt: #option:) notNil]) ifFalse:
			[self error: 'Method name conflict: ', aTMethod selector]].
	^methods at: aTMethod selector put: aTMethod
]

{ #category : #utilities }
CCodeGenerator >> addMethodFor: aClass selector: selector [
	"Add the given method to the code base and answer its translation
	 or nil if it shouldn't be translated."

	| method tmethod |
	method := aClass compiledMethodAt: selector.
	(method pragmaAt: #doNotGenerate) ifNotNil:
		["only remove a previous method if this one overrides it, i.e. this is a subclass method.
		 If the existing method is in a different hierarchy this method must be merely a redeirect."
		 (methods at: selector ifAbsent: []) ifNotNil:
			[:tm|
			(aClass includesBehavior: tm definingClass) ifTrue:
				[self removeMethodForSelector: selector]].
		 ^nil].
	method isSubclassResponsibility ifTrue:
		[^nil].
	(self shouldIncludeMethodFor: aClass selector: selector) ifFalse:
		[^nil].
	tmethod := self compileToTMethodSelector: selector in: aClass.
	"Even though we exclude initialize methods, we must consider their
	 global variable usage, otherwise globals may be incorrectly localized."
	selector == #initialize ifTrue:
		[self checkForGlobalUsage: (tmethod allReferencedVariablesUsing: self) in: tmethod.
		 ^nil].
	self addMethod: tmethod.
	"If the method has a macro then add the macro.  But keep the method
	 for analysis purposes (e.g. its variable accesses)."
	(method pragmaAt: #cmacro:) ifNotNil:
		[:pragma|
		self addMacro: (pragma argumentAt: 1) for: selector.
		(inlineList includes: selector) ifTrue:
			[inlineList := inlineList copyWithout: selector]].
	(method pragmaAt: #cmacro) ifNotNil:
		[:pragma| | literal | "Method should be just foo ^const"
		self assert: (method numArgs = 0 and: [method numLiterals = 3 or: [method isQuick]]).
		literal := method isQuick
					ifTrue: [method decompile quickMethodReturnLiteral]
					ifFalse: [method literalAt: 1].
		self addMacro: '() ', (method isReturnField
								ifTrue: [literal]
								ifFalse: [self cLiteralFor: literal value name: method selector]) for: selector.
		(inlineList includes: selector) ifTrue:
			[inlineList := inlineList copyWithout: selector]].
	^tmethod
]

{ #category : #public }
CCodeGenerator >> addMethodsForTranslatedPrimitives: classAndSelectorList [ 
	| verbose |
	verbose := false.
	classAndSelectorList do:
		[:classAndSelector | | aClass selector meth |
		aClass := Smalltalk at: classAndSelector first.
		selector := classAndSelector last.
		self addAllClassVarsFor: aClass.

		"compile the method source and convert to a suitable translation method.
		 find the method in either the class or the metaclass"
		meth := self
					compileToTMethodSelector: selector
					in: ((aClass includesSelector: selector)
							ifTrue: [aClass]
							ifFalse: [aClass class]).
		meth primitive > 0 ifTrue:
			[meth preparePrimitiveName].
		meth replaceSizeMessages.
		self addMethod: meth].

	self prepareMethods
]

{ #category : #public }
CCodeGenerator >> addPoolVarsFor: aClass [ 
	"Add the pool variables for the given class to the code base as constants."

	(aClass sharedPools reject: [:pool| pools includes: pool]) do:
		[:pool |
		pools add: pool.
		pool bindingsDo:
			[:binding |
			self addConstantForBinding: binding]]
]

{ #category : #public }
CCodeGenerator >> addSelectorTranslation: aSelector to: aString [
	selectorTranslations at: aSelector asSymbol put: aString
]

{ #category : #public }
CCodeGenerator >> addStructClass: aClass [
	"Add the non-accessor methods of the given struct class to the code base."

	aClass prepareToBeAddedToCodeGenerator: self.
	self addClassVarsFor: aClass.
	self addPoolVarsFor: aClass.
	self retainMethods: (aClass requiredMethodNames: self options).
	
	UIManager default
		displayProgress: 'Adding Class ' , aClass name , '...'
		from: 0
		to: aClass selectors size
		during:
			[:bar |
			 aClass selectors doWithIndex:
				[:sel :i | | source |
				bar value: i.
				self addStructMethodFor: aClass selector: sel]].
	aClass declareCVarsIn: self
]

{ #category : #accessing }
CCodeGenerator >> addStructClasses: classes [
	"Add the struct classes and save them for emitCTypesOn: later."
	structClasses := classes.
	structClasses do:
		[:structClass|
		 (structClass withAllSuperclasses copyUpTo: VMStructType) do:
			[:structClassOrSuperclass|
			 self addStructClass: structClassOrSuperclass]]
]

{ #category : #utilities }
CCodeGenerator >> addStructMethodFor: aClass selector: selector [ 
	"Add the given struct method to the code base and answer its translation
	 or nil if it shouldn't be translated."
	(self methodNamed: selector) ifNotNil:
		[:tmethod|
		 "If we're repeating an attempt to add the same thing, or
		  if the existing method overrides this one,don't complain."
		 (tmethod definingClass includesBehavior: aClass) ifTrue:
			[^self].
		 "If the methods are both simple accessors, don't complain."
		 ((tmethod definingClass isAccessor: selector)
		 and: [aClass isAccessor: selector]) ifTrue:
			[^self].
		 "If the method is overriding a method in a superclass, don't complain"
		 (aClass inheritsFrom: tmethod definingClass)
			ifTrue: [methods removeKey: selector]
			ifFalse: [self error: 'conflicting implementations for ', selector storeString]].
	^(self addMethodFor: aClass selector: selector) ifNotNil:
		[:tmethod|
		tmethod transformToStructClassMethodFor: self.
		tmethod]
]

{ #category : #utilities }
CCodeGenerator >> addVariablesInVerbatimCIn: aCCodeSendNode to: aCollection [
	"If aCCodeSendNode has a string argument, parse it and extract anything
	 that looks like a variable, and add the resulting vars to aCollection."
	| separators tokens |
	(aCCodeSendNode isSend
	 and: [(aCCodeSendNode selector beginsWith: #cCode:)
	 and: [aCCodeSendNode args first isConstant
	 and: [aCCodeSendNode args first value isString]]]) ifFalse:
		[^self].
	separators := (Character space to: 255 asCharacter) reject:
					[:char|
					char isLetter or: [char isDigit or: [char = $_]]].
	tokens := aCCodeSendNode args first value findTokens: separators.
	aCollection addAll: (tokens select: [:token| token first isLetter]) asSet
]

{ #category : #utilities }
CCodeGenerator >> anyMethodNamed: selector [
	"Answer any method in the code base (including api methods) with the given selector."

	^methods
		at: selector
		ifAbsent:
			[apiMethods ifNotNil:
				[apiMethods
					at: selector
					ifAbsent: []]]
]

{ #category : #utilities }
CCodeGenerator >> arrayInitializerCalled: varName for: array sizeString: sizeStringOrNil type: cType [
	"array is a literal array or a CArray on some array."
	^String streamContents:
		[:s| | sequence lastLine index newLine allIntegers |
		sequence := array isCollection ifTrue: [array] ifFalse: [array object].
		"this is to align -ve and +ve integers nicely in the primitiveAccessorDepthTable"
		allIntegers := sequence allSatisfy: [:element| element isInteger].
		lastLine := index := 0.
		newLine := [sequence size >= 20
						ifTrue: [s cr; nextPutAll: '/*'; print: index; nextPutAll: '*/'; tab]
						ifFalse: [s crtab: 2].
					 lastLine := s position].
		s	nextPutAll: cType;
			space;
			nextPutAll: varName;
			nextPut: $[.
		sizeStringOrNil ifNotNil: [s nextPutAll: sizeStringOrNil].
		s nextPutAll: '] = '.
		sequence isString
			ifTrue: [s nextPutAll: (self cLiteralFor: sequence)]
			ifFalse:
				[s nextPut: ${.
				 newLine value.
				 sequence
					do: [:element|
						(allIntegers
						 and: [element < 0
						 and: [s peekLast = Character space]]) ifTrue:
							[s skip: -1].
						s nextPutAll: (self cLiteralFor: element). index := index + 1]
					separatedBy:
						[s nextPut: $,.
						 ((s position - lastLine) >= 76
						 or: [(index \\ 20) = 0])
							ifTrue: [newLine value]
							ifFalse: [s space]].
				 s crtab; nextPut: $}]]
]

{ #category : #utilities }
CCodeGenerator >> baseTypeForPointerType: aCType [
	"Answer the type of the referent of a pointer type."
	self assert: aCType last == $*.
	^self baseTypeForType: aCType allButLast
]

{ #category : #utilities }
CCodeGenerator >> baseTypeForType: aCType [
	"Reduce various declarations to the most basic type we can determine."
	| type fpIndex closeidx openidx |
	type := aCType.
	((openidx := type indexOfSubCollection: 'const ') > 0
	and: [openidx = 1 or: [(type at: openidx) isSeparator]]) ifTrue:
		[type := type copyReplaceFrom: openidx to: openidx + 5 with: ''].
	((type beginsWith: 'unsigned') and: [(type includes: $:) and: [type last isDigit]]) ifTrue:
		[^#usqInt].
	"collapse e.g. void (*foo(int bar))(void) to void (*)(void)"
	(fpIndex := type indexOfSubCollection: '(*') > 0 ifTrue:
		["elide the function arguments after *, if there are any"
		 type := type copyReplaceFrom: (type indexOf: $( startingAt: fpIndex + 1)
					to: (type indexOf: $) startingAt: fpIndex + 1)
					with: ''.
		 "elide the function name after *, if there is one"
		 type := type copyReplaceFrom: fpIndex + 2
					to: (type indexOf: $) startingAt: fpIndex + 1)
					with: ')'].
	"collapse [size] to *"
	openidx := 0.
	[(openidx := type indexOf: $[ startingAt: openidx + 1) > 0
	 and: [(closeidx := type indexOf: $] startingAt: openidx + 1) > 0]] whileTrue:
		[type := type copyReplaceFrom: openidx to: closeidx with: '*'].

	"map foo* to foo *"
	^self conventionalTypeForType: type
]

{ #category : #accessing }
CCodeGenerator >> breakDestInlineSelector: aSelector [
	breakDestInlineSelectors add: aSelector
]

{ #category : #accessing }
CCodeGenerator >> breakOnInline: aBooleanOrNil [
	breakOnInline := aBooleanOrNil
]

{ #category : #accessing }
CCodeGenerator >> breakSrcInlineSelector: aSelector [
	breakSrcInlineSelectors add: aSelector
]

{ #category : #utilities }
CCodeGenerator >> cCodeForMethod: selector [
	"Answer a string containing the C code for the given method."
	"Example:
		((CCodeGenerator new initialize addClass: TestCClass1; prepareMethods)
			cCodeForMethod: #ifTests)"

	| m s |
	m := self methodNamed: selector.
	m = nil ifTrue: [ self error: 'method not found in code base: ', selector ].

	s := (ReadWriteStream on: '').
	m emitCCodeOn: s generator: self.
	^ s contents
]

{ #category : #'C code generator' }
CCodeGenerator >> cFunctionNameFor: aSelector [
	"Create a C function name from the given selector by finding
	 a specific translation, or if none, simply omitting colons, and
	 any trailing underscores (this supports a varargs convention)."
	^selectorTranslations
		at: aSelector
		ifAbsent:
			[| cSelector |
			 cSelector := aSelector copyWithout: $:.
			 aSelector last = $: ifTrue:
				[[cSelector last = $_] whileTrue:
					[cSelector := cSelector allButLast]].
			 cSelector]
]

{ #category : #'C code generator' }
CCodeGenerator >> cLiteralFor: anObject [
	"Return a string representing the C literal value for the given object."
	anObject isNumber
		ifTrue:
			[anObject isInteger ifTrue:
				[| hex |
				 hex := (anObject > 0
								and: [(anObject >> anObject lowBit + 1) isPowerOfTwo
								and: [(anObject highBit = anObject lowBit and: [anObject > 65536])
									  or: [anObject highBit - anObject lowBit >= 4]]]).
				^self cLiteralForInteger: anObject hex: hex].
			anObject isFloat ifTrue:
				[^anObject printString]]
		ifFalse:
			[anObject isSymbol ifTrue:
				[^self cFunctionNameFor: anObject].
			anObject isString ifTrue:
				[^'"', (anObject copyReplaceAll: (String with: Character cr) with: '\n') , '"'].
			anObject == nil ifTrue: [^ 'null' ].
			anObject == true ifTrue: [^ '1' ].
			anObject == false ifTrue: [^ '0' ].
			anObject isCharacter ifTrue:
				[^anObject == $'
					ifTrue: ['''\'''''] "i.e. '\''"
					ifFalse: [anObject asString printString]]].
	self error: 'Warning: A Smalltalk literal could not be translated into a C constant: ', anObject printString.
	^'"XXX UNTRANSLATABLE CONSTANT XXX"'
]

{ #category : #'C code generator' }
CCodeGenerator >> cLiteralFor: anObject name: smalltalkName [
	"Return a string representing the C literal value for the given object.
	 This version may use hex for integers that are bit masks."
	anObject isInteger ifTrue:
		[| hex dec useHexa |
		hex := anObject printStringBase: 16.
		dec := anObject printStringBase: 10.
		useHexa := ((smalltalkName endsWith: 'Mask')
				or: [anObject digitLength > 1
					and: [(hex asSet size * 3) <= (dec asSet size * 2)
					and: [(smalltalkName endsWith: 'Size') not]]]).
		^self cLiteralForInteger: anObject hex: useHexa].
	^self cLiteralFor: anObject
]

{ #category : #'C code generator' }
CCodeGenerator >> cLiteralForInteger: anInteger hex: aBoolean [
	"Answer the string for generating a literal integer.
	Use hexadecimal notation as prescribed by aBoolean.
	Use long long suffix (LL) if the integer does not fit on 32 bits.
	Use unsigned suffix (U) if the integer does not fit on a signed integer (resp. long long).
	Correctly generate INT_MIN and LONG_LONG_MIN.
	Indeed -0x8000000 is parsed as - (0x8000000) by C Compiler.
	0x8000000 does not fit on a signed int, it is interpreted as unsigned.
	That makes INT_MIN unsigned which is badly broken..."
	
	| printString |
	printString := aBoolean
		ifTrue: [anInteger positive
			ifTrue: ['0x' , (anInteger printStringBase: 16)]
			ifFalse: ['-0x' , (anInteger negated printStringBase: 16)]]
		ifFalse: [anInteger printString].
	^anInteger positive
		ifTrue: [anInteger > 16r7FFFFFFF "INT_MAX"
			ifTrue: [anInteger > 16rFFFFFFFF "UINT_MAX"
				ifTrue: [anInteger > 16r7FFFFFFFFFFFFFFF "LONG_LONG_MAX"
					ifTrue: [printString , 'ULL']
					ifFalse: [printString , 'LL']]
				ifFalse: [printString , 'U']]
			ifFalse: [printString]]
		ifFalse: [anInteger < -16r8000000
			ifTrue: [anInteger = -16r800000000000000	"LONG_LONG_MIN"
				ifTrue: ['(-0x7FFFFFFFFFFFFFFFLL-1)']
				ifFalse: [printString , 'LL']]
			ifFalse: [anInteger = -16r8000000	"INT_MIN"
				ifTrue: ['(-0x7FFFFFFF-1)']
				ifFalse: [printString]]]
]

{ #category : #'C code generator' }
CCodeGenerator >> cLiteralForPrintfString: aString [
	^(('"', (PrintfFormatString new setFormat: aString) transformForVMMaker, '"')
		copyReplaceAll: (String with: Character cr) with: '\n')
			copyReplaceAll: (String with: Character tab) with: '\t'
]

{ #category : #'C code generator' }
CCodeGenerator >> cLiteralForUnsignedInteger: anInteger hex: aBoolean longlong: llBoolean [
	"Answer the string for generating an unsigned literal integer.
	Use hexadecimal notation as prescribed by aBoolean.
	Force long long suffix (LL) if the integer does not fit on 32 bits, or if llBoolean is true."
	
	| printString |
	printString := aBoolean
		ifTrue: [anInteger positive
			ifTrue: ['0x' , (anInteger printStringBase: 16)]
			ifFalse: ['-0x' , (anInteger negated printStringBase: 16)]]
		ifFalse: [anInteger printString].
	^anInteger positive
		ifTrue: [(llBoolean or: [anInteger > 16rFFFFFFFF "UINT_MAX"])
			ifTrue: [printString , 'ULL']
			ifFalse: [printString , 'U']]
		ifFalse: [self error: 'please provide positive integer']
]

{ #category : #'C code generator' }
CCodeGenerator >> cLiteralForUnsignedInteger: anInteger longlong: llBoolean [
	"Answer the string for generating an unsigned literal integer.
	Eventually use hexadecimal.
	Force long long suffix (LL) if the integer does not fit on 32 bits, or if llBoolean is true."
	
	| hex |
	hex := (anInteger > 0
				and: [(anInteger >> anInteger lowBit + 1) isPowerOfTwo
				and: [(anInteger highBit = anInteger lowBit and: [anInteger > 65536])
					  or: [anInteger highBit - anInteger lowBit >= 4]]]).
	^self cLiteralForUnsignedInteger: anInteger hex: hex longlong: llBoolean
]

{ #category : #inlining }
CCodeGenerator >> cannotInline: selector [

	self error: 'Failed to inline ', selector,
			' as it contains unrenamable C declarations or C code'
]

{ #category : #'error notification' }
CCodeGenerator >> checkClassForNameConflicts: aClass [
	"Verify that the given class does not have constant, variable, or method names that conflict with
	 those of previously added classes. Raise an error if a conflict is found, otherwise just return."

	"check for constant name collisions in class pools"
	aClass classPool associationsDo:
		[:assoc |
		(constants includesKey: assoc key) ifTrue:
			[self error: 'Constant ', assoc key, ' was defined in a previously added class']].

	"and in shared pools"
	(aClass sharedPools reject: [:pool| pools includes: pool]) do:
		[:pool |
		pool bindingsDo:
			[:assoc |
			(constants includesKey: assoc key) ifTrue:
				[self error: 'Constant ', assoc key, ' was defined in a previously added class']]].

	"check for instance variable name collisions"
	(aClass inheritsFrom: VMStructType) ifFalse:
		[(self instVarNamesForClass: aClass) do:
			[:varName |
			(variables includes: varName) ifTrue:
				[self error: 'Instance variable ', varName, ' was defined in a previously added class']]].

	"check for method name collisions"
	aClass selectors do:
		[:sel | | tmeth meth |
		((self shouldIncludeMethodFor: aClass selector: sel)
		and: [(tmeth := methods at: sel ifAbsent: nil) notNil
		and: [(aClass isStructClass and: [(aClass isAccessor: sel)
				and: [(methods at: sel) isStructAccessor]]) not
		and: [(meth := aClass >> sel) isSubclassResponsibility not
		and: [(aClass includesBehavior: tmeth definingClass) not]]]]) ifTrue:
			[((aClass >>sel) pragmaAt: #option:)
				ifNil: [self error: 'Method ', sel, ' was defined in a previously added class.']
				ifNotNil:
					[logger
						ensureCr;
						show: 'warning, method ', aClass name, '>>', sel storeString,
								' overrides ', tmeth definingClass, '>>', sel storeString;
						cr]]]
]

{ #category : #utilities }
CCodeGenerator >> checkDeleteVariable: aName [
	"Hook for debugging variable deletion."
]

{ #category : #utilities }
CCodeGenerator >> checkForGlobalUsage: vars in: aTMethod [ 
	vars do:
		[:var |
		(variables includes: var) ifTrue: "find the set of method names using this global var"
			[(globalVariableUsage at: var ifAbsentPut: [Set new])
				add: aTMethod selector]].
	aTMethod clearReferencesToGlobalStruct.
	(aTMethod locals select: [:l| self reservedWords includes: l]) do:
		[:l| | em |
		em := aTMethod definingClass name, '>>', aTMethod smalltalkSelector, ' has variable that is a C reserved word: ', l.
		self error: em.
		self logger cr; nextPutAll: em; cr; flush]
]

{ #category : #public }
CCodeGenerator >> codeString [
	"Return a string containing all the C code for the code base. Used for testing."

	| stream |
	stream := ReadWriteStream on: (String new: 1000).
	self emitCCodeOn: stream doInlining: true doAssertions: true.
	^stream contents
]

{ #category : #inlining }
CCodeGenerator >> collectInlineList: strategy [
	"Make a list of methods that should be inlined.  If inlineFlagOrSymbol == #asSpecified
	 only inline methods marked with <inline: true>.  If inlineFlagOrSymbol == #asSpecifiedOrQuick
	 only inline methods marked with <inline: true> or methods that are quick (^constant, ^inst var)."
	"Details: The method must not include any inline C, since the
	 translator cannot currently map variable names in inlined C code.
	 Methods to be inlined must be small or called from only one place."
	
	| selectorsOfMethodsNotToInline callsOf inlineStrategy |
	inlineStrategy := strategy asCCodeInlineStrategy.
	inlineStrategy codeGenerator: self.
		
	selectorsOfMethodsNotToInline := Set new: methods size.
	selectorsOfMethodsNotToInline addAll: macros keys.
	apiMethods ifNotNil: [ selectorsOfMethodsNotToInline addAll: apiMethods keys ].
	selectorsOfMethodsNotToInline addAll: self structAccessorSelectors.

	"build dictionary to record the number of calls to each method"
	callsOf := Dictionary new: methods size * 2.
	methods keysAndValuesDo:
		[:s :m|
		(m isRealMethod
		 and: [self shouldGenerateMethod: m]) ifTrue:
			[callsOf at: s put: 0]].

	"For each method, scan its parse tree once or twice to:
		1. determine if the method contains unrenamable C code or declarations or has a C builtin
		2. determine how many nodes it has
		3. increment the sender counts of the methods it calls"
	inlineList := Set new: methods size * 2.
	methods
		reject: [:m|
			(selectorsOfMethodsNotToInline includes: m selector)
				or: [ self isSpecialSelector: m selector ] ]
		thenDo: [:m|
			m parseTree nodesDo: [:node|
				node isSend ifTrue: [
					callsOf
						at: node selector
						ifPresent: [:senderCount| callsOf at: node selector put: senderCount + 1 ] ] ].

		inlineStrategy validateCanInline: m.
		(inlineStrategy shouldInlineMethod: m)
			ifTrue: [ 
				"inline if method has no C code and is either small or contains inline directive"
				inlineList add: m selector]
			ifFalse: [
				inlineStrategy isSelectiveInlineStrategy
					ifTrue: [selectorsOfMethodsNotToInline add: m selector] ] ].

	inlineStrategy isSelectiveInlineStrategy
		ifTrue:
			[methods do: [:m| m inline ifNil: [m inline: (inlineList includes: m selector)]]]
		ifFalse:
			[callsOf associationsDo:
				[:assoc|
				(assoc value = 1
				 and: [(selectorsOfMethodsNotToInline includes: assoc key) not]) ifTrue:
					[inlineList add: assoc key]]]
]

{ #category : #utilities }
CCodeGenerator >> compileToTMethodSelector: selector in: aClass [
	"Compile a method to a TMethod"
	^(aClass >> selector) asTranslationMethodOfClass: self translationMethodClass

	"was:
	| implementingClass |
	implementingClass := aClass.
	^(Compiler new
		parse: ([aClass sourceCodeAt: selector]
					on: KeyNotFound
					do: [:ex| ""Quick hack for simulating Pharo images...""
						(PharoVM and: [aClass == String class and: [selector == #findSubstringViaPrimitive:in:startingAt:matchTable:]]) ifFalse:
							[ex pass].
						(implementingClass := ByteString) sourceCodeAt: #findSubstring:in:startingAt:matchTable:])
		in: implementingClass
		notifying: nil)
			asTranslationMethodOfClass: self translationMethodClass"
]

{ #category : #public }
CCodeGenerator >> computeKernelReturnTypes [
	| dictionary |
	dictionary := Dictionary newFromPairs:
		#(oopAt: #sqInt oopAt:put: #sqInt
			oopAtPointer: #sqInt oopAtPointer:put: #sqInt
		 byteAt: #sqInt byteAt:put: #sqInt
			byteAtPointer: #sqInt byteAtPointer:put: #sqInt
		 shortAt: #sqInt shortAt:put: #sqInt
			shortAtPointer: #sqInt shortAtPointer:put: #sqInt
		 intAt: #sqInt intAt:put: #sqInt
			intAtPointer: #sqInt intAtPointer:put: #sqInt
		 longAt: #sqInt longAt:put: #sqInt
			longAtPointer: #sqInt longAtPointer:put: #sqInt
				long32At: #int long32At:put: #int
					unalignedLongAt: #sqInt unalignedLongAt:put: #sqInt
						unalignedLong32At: #int unalignedLong32At:put: #int

		 long64At: #sqLong long64At:put: #sqLong
		 long64AtPointer: #sqLong long64AtPointer:put: #sqLong
	
		singleFloatAtPointer: #float singleFloatAtPointerPut: #float		
		floatAtPointer: #double floatAtPointerPut: #double
				
		 fetchFloatAt:into: #void storeFloatAt:from: #void
			fetchFloatAtPointer:into: #void storeFloatAtPointer:from: #void
		 fetchSingleFloatAt:into: #void storeSingleFloatAt:from: #void
			fetchSingleFloatAtPointer:into: #void storeSingleFloatAtPointer:from: #void

		 pointerForOop: #'char *' oopForPointer: #sqInt
		 baseHeaderSize #sqInt wordSize #sqInt bytesPerOop #sqInt).
	BytesPerWord = 8 ifTrue:
		[#(long32At: long32At:put: unalignedLong32At: unalignedLong32At:put:) do:
			[:accessor|
			dictionary at: accessor put: #int]].
	^dictionary
]

{ #category : #public }
CCodeGenerator >> const: constName declareC: declarationString [
	"Record the given C declaration for a constant."

	constants
		at: constName
		put: (TDefineNode new
				setName: constName
				value: declarationString)
]

{ #category : #utilities }
CCodeGenerator >> conventionalTypeForType: aCTypeString [
	"The pointer type convention in this version of VMMaker is to have a space between the base type and any *'s.
	 C type comparisons are simple string comparisons; therefore the convention matters.
	 Ensure there is a space between the base type and any trailing *'s. Trim whitespace."
	| type index |
	type := aCTypeString withBlanksTrimmed.
	index := type size.
	[(type at: index) == $*] whileTrue:
		[index := index - 1].
	(index < type size
	 and: [(type at: index) ~~ Character space]) ifTrue:
		[type := (type copyFrom: 1 to: index), ' ', (type copyFrom: index + 1 to: type size)].
	^type
]

{ #category : #accessing }
CCodeGenerator >> currentMethod [
	^currentMethod
]

{ #category : #accessing }
CCodeGenerator >> currentMethod: aTMethod [
	previousCommenter := nil.
	currentMethod := aTMethod
]

{ #category : #public }
CCodeGenerator >> declareModuleName: nameString [
	"add the declaration of a module name, version and local/external tag"

	self var: #moduleName declareC:'const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"', nameString,' (i)"
#else
	"', nameString,' (e)"
#endif
'.
	"and for run-time use, answer the string"
	^nameString, ' (i)'
]

{ #category : #public }
CCodeGenerator >> declareVar: varName type: type [
	"This both creates a varable and provides its type"
	self var: (variables add: varName asString) type: type
]

{ #category : #inlining }
CCodeGenerator >> doBasicInlining: inlineFlagOrSymbol [
	"Inline the bodies of all methods that are suitable for inlining.
	This method does only the basic inlining suitable for both the core VM and plugins - no bytecode inlining etc"

	| pass progress |
	self collectInlineList: inlineFlagOrSymbol.
	pass := 0.
	progress := true.
	[progress] whileTrue: [
		"repeatedly attempt to inline methods until no further progress is made"
		progress := false.
		UIManager default
			displayProgress: ('Inlining pass ', (pass := pass + 1) printString, '...')
			from: 0 to: methods size
			during: [:bar |
				(self sortMethods: methods) doWithIndex: [:m :i |
					bar value: i.
					currentMethod := m.
					(m tryToInlineMethodsIn: self)
						ifTrue: [progress := true]]]].


]

{ #category : #inlining }
CCodeGenerator >> doInlining: inlineFlagOrSymbol [
	"Inline the bodies of all methods that are suitable for inlining."
	"Modified slightly for the core VM translator, since the first level of inlining for the interpret loop must be performed in order that the instruction implementations can easily discover their addresses. Remember to inline the bytecode routines as well"

	| removed |
	inlineFlagOrSymbol isSymbol ifTrue:
		[self inlineDispatchesInMethodNamed: #interpret localizingVars: #().	
		 self doBasicInlining: inlineFlagOrSymbol.
		 self pruneUnreachableMethods.
		 ^self].

	inlineFlagOrSymbol ifFalse:
		[self inlineDispatchesInMethodNamed: #interpret localizingVars: #().	
		self pruneUnreachableMethods.
		^self].

	self doBasicInlining: inlineFlagOrSymbol.

	vmClass ifNil: [^self].

	UIManager default
		displayProgress: 'Inlining bytecodes'
		from: 1 to: 2
		during: [:bar |
			self inlineDispatchesInMethodNamed: #interpret
				localizingVars: vmClass namesOfVariablesToLocalize.
			bar value: 1.
			removed := self removeMethodsReferingToGlobals: vmClass namesOfVariablesToLocalize
							except: #interpret.
			bar value: 2].

	"only prune when generating the interpreter itself"
	self pruneUnreachableMethods.

	self reportShouldNotBeRemoved: removed  varList: vmClass namesOfVariablesToLocalize
]

{ #category : #utilities }
CCodeGenerator >> emitBuiltinConstructAsArgumentFor: msgNode on: aStream level: level [
	"If the given selector is in the translation dictionary, translate it into a target code construct and return true. Otherwise, do nothing and return false."

	| action |
	(self shouldGenerateAsInterpreterProxySend: msgNode) ifTrue:
		[^false].
	action := asArgumentTranslationDict
				at: msgNode selector
				ifAbsent: [translationDict at: msgNode selector ifAbsent: [ ^false ]].
	self perform: action with: msgNode with: aStream with: level.
	^true
]

{ #category : #utilities }
CCodeGenerator >> emitBuiltinConstructFor: msgNode on: aStream level: level [
	"If the given selector is in the translation dictionary, translate it into a target code construct and return true. Otherwise, do nothing and return false."

	| action |
	(self shouldGenerateAsInterpreterProxySend: msgNode) ifTrue:
		[^false].
	action := translationDict at: msgNode selector ifAbsent: [ ^false ].
	self perform: action with: msgNode with: aStream with: level.
	^true
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCAPIExportHeaderOn: aStream [ 
	"Store prototype declarations for all API methods on the given stream."
	| exportedAPIMethods usedConstants |
	exportedAPIMethods := self sortMethods: (methods select: [:m| m isAPIMethod]).
	exportedAPIMethods do:
		[:m|
		m static ifTrue:
			[logger ensureCr; show: m selector, ' excluded from export API because it is static'; cr]].
	self emitCFunctionPrototypes: exportedAPIMethods on: aStream.
	self emitGlobalCVariablesOn: aStream.
	usedConstants := self emitCMacros: exportedAPIMethods on: aStream.
	self emitCConstants: usedConstants on: aStream
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCCodeOn: aStream doInlining: inlineFlag doAssertions: assertionFlag [
	"Emit C code for all methods in the code base onto the given stream. All inlined method calls should already have been expanded."

	| verbose methodList |
	"method preparation"
	verbose := false.
	self prepareMethods.
	verbose ifTrue: [
		self printUnboundCallWarnings.
		self printUnboundVariableReferenceWarnings.
		logger cr.
	].
	assertionFlag ifFalse: [ self removeAssertions ].
	self doInlining: inlineFlag.

	"code generation"
	"If we're outputting the VM put the main interpreter loop first for two reasons.
	 1, so that the dispdbg.h header included at the bytecode dispatch can define
	 macros that affect all C code in the interpreter,  and 2, so that all primitive
	 functions will come after and have relatively high addresses.  This provides safety
	 in the use of primitiveFunctionPointer as a function pointer and an index by trying
	 to ensure that primitives have addresses much higher than any indices."
	methodList := self sortMethods: methods.
	(methods includesKey: #interpret) ifTrue:
		[methodList := { methods at: #interpret }, (methodList copyWithout: (methods at: #interpret))].
	"clean out no longer valid variable names and then
	 handle any global variable usage in each method"
	methodList do: [:m | self checkForGlobalUsage: (m removeUnusedTempsAndNilIfRequiredIn: self) in: m].
	self localizeGlobalVariables.

	self emitCHeaderOn: aStream.
	self emitCConstantsOn: aStream.
	self emitCTypesOn: aStream. "Emitting types after constants allows use of constant names, e.g. in declaring arrays."
	self emitCFunctionPrototypes: methodList on: aStream.
	self emitCVariablesOn: aStream.
	self emitCMacros: methodList on: aStream.
	self emitCMethods: methodList on: aStream.
	self emitExportsOn: aStream.

]

{ #category : #'C code generator' }
CCodeGenerator >> emitCConstants: constList on: aStream [
	"Store the global variable declarations on the given stream."
	constList isEmpty ifTrue: [^self].
	aStream cr; nextPutAll: '/*** Constants ***/'; cr.
	(self sortStrings: constList) do:
		[:varName| | node default value |
		node := constants at: varName.
		node name isEmpty ifFalse:
			["If the definition includes a C comment, or looks like a conditional, take it as is, otherwise convert
			  the value from Smalltalk to C.
			  Allow the class to provide an alternative definition, either of just the value or the whole shebang."
			default := (node value isString
						and: [(node value includesSubstring: '/*')
								or: [(node value includesSubstring: ' ? ') and: [node value includesSubstring: ' : ']]])
							ifTrue: [node value]
							ifFalse: [self cLiteralFor: node value name: varName].
			default = #undefined
				ifTrue: [aStream nextPutAll: '#undef '; nextPutAll: node name; cr]
				ifFalse:
					[value := vmClass
								ifNotNil:
									[(vmClass specialValueForConstant: node name default: default)
										ifNotNil: [:specialDef| specialDef]
										ifNil: [default]]
								ifNil: [default].
					((vmClass ifNil: VMBasicConstants) defineAtCompileTime: node name)
						ifTrue: [self putConditionalDefineOf: node name
									as: value
									comment: 'Allow this to be overridden on the compiler command line'
									on: aStream]
						ifFalse: [self putDefineOf: node name as: value on: aStream]]]].
	aStream cr
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCConstantsOn: aStream [ 
	"Store the global variable declarations on the given stream."
	| unused |
	unused := constants keys asSet.
	"Don't generate any defines for the externally defined constants,
	 STACKVM, COGVM, COGMTVM et al, unless they're actually used."
	(VMClass class>>#initializeMiscConstants) literalsDo:
		[:lit|
		(lit isVariableBinding and: [lit key isString]) ifTrue:
			[unused add: lit key]].
	methods do:
		[:meth|
		meth declarations keysDo:
			[:v|
			(meth typeFor: v in: self) ifNotNil:
				[:type| unused remove: type ifAbsent: []]].
		unused remove: meth returnType ifAbsent: [].
		meth parseTree nodesDo:
			[:n| n isConstant ifTrue: [unused remove: n name ifAbsent: []]]].
	unused copy do:
		[:const|
		(variableDeclarations anySatisfy: [:value| value includesSubstring: const]) ifTrue:
			[unused remove: const ifAbsent: []]].
	"and VMBasicConstants mostBasicConstantNames *must* be taken from interp.h"
	unused addAll: VMBasicConstants mostBasicConstantNames.
	self emitCConstants: (constants keys reject: [:any| unused includes: any]) on: aStream
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCExpression: aParseNode on: aStream [ 
	"Emit C code for the expression described by the given parse node."

	self emitCExpression: aParseNode on: aStream indent: 0
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCExpression: aParseNode on: aStream indent: level [
	"Emit C code for the expression described by the given parse node."

	(aParseNode isLeaf
	 or: [aParseNode isSend
		 and: [#(bytesPerOop bytesPerWord baseHeaderSize wordSize) includes: aParseNode selector]])
		ifTrue: 
			["omit parens"
			 aParseNode emitCCodeAsExpressionOn: aStream level: level generator: self]
		ifFalse: 
			[aStream nextPut: $(.
			 aParseNode emitCCodeAsExpressionOn: aStream level: level generator: self.
			 aStream nextPut: $)]
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCFunctionPrototypes: methodList on: aStream [ 
	"Store prototype declarations for all non-inlined methods on the given stream.
	 Add a define for a NoDbgRegParms attribute for static functions used for debugging.
	 gcc and other compilers will use non-standard calling conventions for static functions
	 when optimizing.  The optimization can render the functions unusable in gdb.  The sqConfig.h
	 file for the platform should define PlatformNoDbgRegParms suitably for the platform's
	 compiler, if the compiler can be persuaded not to generate such functions.
	 Add a define for a NeverInline attribute that tells the compiler never to inline functions
	 with the attribute.  We mark functions we want to observe in a profiler as NeverInline.
	 The sqConfig.h file for the platform should define NeverInline suitably for the platform's
	 compiler, if the compiler can be persuaded not to inline certain functions."
	aStream cr; nextPutAll: '/*** Function Prototypes ***/'; cr.
	vmClass ifNotNil:
		[NoRegParmsInAssertVMs ifTrue:
			[aStream nextPutAll: '\\#if !PRODUCTION && defined(PlatformNoDbgRegParms)\# define NoDbgRegParms PlatformNoDbgRegParms\#endif' withCRs.
			 aStream nextPutAll: '\\#if !defined(NoDbgRegParms)\# define NoDbgRegParms /*empty*/\#endif\\' withCRs].
		 aStream nextPutAll: '\\#if !defined(NeverInline)\# define NeverInline /*empty*/\#endif\\' withCRs].
	(methodList select: [:m| m isRealMethod and: [self shouldGenerateMethod: m]]) do:
		[:m |
		vmClass ifNotNil:
			[(NoRegParmsInAssertVMs and: [m export not and: [m isStatic and: [m args notEmpty]]]) ifTrue:
				[m addFunctionAttribute: 'NoDbgRegParms'].
			 m inline == #never ifTrue:
				[m addFunctionAttribute: 'NeverInline']].
		m emitCFunctionPrototype: aStream generator: self].
	aStream cr
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCHeaderOn: aStream [
	"Emit the initial part of a source file on aStream, comprising the version stamp,
	 the global struct usage flags, the header files and preamble code."

	| headerClass |
	headerClass := [vmClass coreInterpreterClass]
						on: MessageNotUnderstood
						do: [:ex| vmClass].
	aStream nextPutAll: (self fileHeaderVersionStampForSourceClass: headerClass); cr; cr.
	self emitGlobalStructFlagOn: aStream.

	self addHeaderFileFirst: '"sq.h"'.
	"Additional header files; include C library ones first."
	self emitHeaderFiles: (headerFiles select: [:hdr| hdr includes: $<]) on: aStream.
	"Additional header files; include squeak VM ones last"
	self emitHeaderFiles: (headerFiles reject: [:hdr| hdr includes: $<]) on: aStream.

	vmClass isInterpreterClass ifTrue:
		[self maybePutPreambleFor: vmClass on: aStream].

	aStream cr
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCMacros: methodList on: aStream [ 
	"Store the global variable declarations on the given stream.  Answer any constants used in the macros."
	| usedConstants |
	macros isEmpty ifTrue: [^#()].
	aStream cr; nextPutAll: '/*** Macros ***/'; cr.
	usedConstants := Set new.
	(methodList reject: [:m| m isRealMethod]) do:
		[:m |
		m definedAsMacro ifTrue:
			[aStream
				nextPutAll: '#define ';
				nextPutAll:(self cFunctionNameFor: m selector);
				nextPutAll: (macros at: m selector); cr.
			 m compiledMethod literalsDo:
				[:lit|
				(lit isVariableBinding and: [(macros at: m selector) includesSubstring: lit key]) ifTrue:
					[usedConstants add: lit key]]]].
	aStream cr.
	^usedConstants
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCMethods: methodList on: aStream [
	UIManager default
		displayProgress: 'Writing Translated Code...'
		from: 0 to: methods size
		during:
			[:bar |
			methodList doWithIndex:
				[ :m :i |
				bar value: i.
				(m isRealMethod
				 and: [self shouldGenerateMethod: m]) ifTrue:
					[m emitCCodeOn: aStream generator: self]]]
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCTestBlock: aBlockNode on: aStream indent: level [
	"Emit C code for the given block node to be used as a loop test."

	(aBlockNode statements size > 1
			ifTrue: [aBlockNode]
			ifFalse: [aBlockNode statements first])
		emitCCodeAsExpressionOn: aStream level: level generator: self
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCTypesOn: aStream [ 
	"Store local type declarations on the given stream."
	structClasses ifNotNil:
		[structClasses do:
			[:structClass|
			(structClass isAbstract not
			 and: [vmClass shouldGenerateTypedefFor: structClass]) ifTrue:
				[structClass printTypedefOn: aStream.
				 aStream cr; cr]]]
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCVariablesOn: aStream [ 
	"Store the global variable declarations on the given stream."

	aStream cr; nextPutAll: '/*** Variables ***/'; cr.
	(self sortStrings: variables) do:
		[:var | | varString decl |
		varString := var asString.
		decl := variableDeclarations at: varString ifAbsent: ['sqInt ' , varString].
		decl first == $# "support cgen var: #bytecodeSetSelector declareC: '#define bytecodeSetSelector 0' hack"
			ifTrue:
				[aStream nextPutAll: decl; cr]
			ifFalse:
				[self isGeneratingPluginCode
					ifTrue:
						[varString = 'interpreterProxy'
							ifTrue: "quite special..."
								[self preDeclareInterpreterProxyOn: aStream]
							ifFalse: [(decl beginsWith: 'static') ifFalse:
										[aStream nextPutAll: 'static ']]]
					ifFalse:
						[(vmClass mustBeGlobal: varString)
							ifTrue:
								[(decl beginsWith: 'static ') ifTrue:
									[decl := decl allButFirst: 7]]
							ifFalse:
								[(decl beginsWith: 'static') ifFalse:
									[aStream nextPutAll: 'static ']]].
				aStream
					nextPutAll: decl;
					nextPut: $;;
					cr]].
	aStream cr
]

{ #category : #'C code generator' }
CCodeGenerator >> emitExportsNamed: exportsNamePrefix pluginName: pluginName on: aStream [
	"Store all the exported primitives in the form used by the internal named prim system."
	| nilVMClass excludeDepth |
	(nilVMClass := vmClass isNil) ifTrue: "We need a vmClass temporarily to compute accessor depths."
		[vmClass := StackInterpreter].
	"Don't include the depth in the vm's named primitives if the vm is non-Spur."
	excludeDepth := exportsNamePrefix = 'vm'
					  and: [pluginName isEmpty
					  and: [vmClass objectMemoryClass hasSpurMemoryManagerAPI not]].
	aStream cr; cr; nextPutAll: 'static char _m[] = "'; nextPutAll: pluginName; nextPutAll: '";'.
	aStream cr; nextPutAll: 'void* '; nextPutAll: exportsNamePrefix; nextPutAll: '_exports[][3] = {'; cr.
	self sortedExportMethods do:
		[:method|
		self withOptionalConditionalDefineFor: method
			on: aStream
			do: [| primName |
				 primName := self cFunctionNameFor: method selector.
				 aStream tab; nextPutAll: '{(void*)_m, "'; nextPutAll: primName.
				 excludeDepth ifFalse:
					[(self accessorDepthForSelector: primName asSymbol) ifNotNil:
						[:depth| "store the accessor depth in a hidden byte immediately after the primName"
						self assert: depth < 128.
						aStream
							nextPutAll: '\000\';
							nextPutAll: ((depth bitAnd: 255) printStringBase: 8 nDigits: 3)]].
				 aStream nextPutAll: '", (void*)'; nextPutAll: primName; nextPutAll: '},'; cr]].
	aStream tab; nextPutAll: '{NULL, NULL, NULL}'; cr; nextPutAll: '};'; cr.
	nilVMClass ifTrue:
		[vmClass := nil]
]

{ #category : #'C code generator' }
CCodeGenerator >> emitExportsOn: aStream [
	"Store all the exported primitives in the form used by the internal named prim system."
	(vmClass isNil or: [vmClass isInterpreterClass]) ifTrue:
		[self emitExportsNamed: 'vm' pluginName: '' on: aStream]
]

{ #category : #'C code generator' }
CCodeGenerator >> emitGlobalCVariablesOn: aStream [
	"Store the global variable declarations on the given stream."

	aStream cr; nextPutAll: '/*** Global Variables ***/'; cr.
	
	(self sortStrings: (variables select: [:v| vmClass mustBeGlobal: v])) do:
		[:var | | varString decl |
		varString := var asString.
		decl := variableDeclarations at: varString ifAbsent: ['sqInt ' , varString].
		decl first == $# "support cgen var: #bytecodeSetSelector declareC: '#define bytecodeSetSelector 0' hack"
			ifTrue:
				[aStream nextPutAll: decl; cr]
			ifFalse:
				[(decl includesSubstring: ' private ') ifFalse: "work-around hack to prevent localization of variables only referenced once."
					[(decl beginsWith: 'static') ifFalse: [aStream nextPutAll: 'VM_EXPORT '].
					(decl includes: $=) ifTrue:
						[decl := decl copyFrom: 1 to: (decl indexOf: $=) - 1].
					aStream
						nextPutAll: decl;
						nextPut: $;;
						cr]]].
	aStream cr
]

{ #category : #'C code generator' }
CCodeGenerator >> emitGlobalStructFlagOn: aStream [
	"Default: do nothing.  Overridden in CCGenGlobalStruct."

]

{ #category : #'C code generator' }
CCodeGenerator >> emitHeaderFiles: headerFilesSubSequence on: aStream [
	headerFilesSubSequence do:
		[:hdr|
		hdr first ~= $# ifTrue:
			[aStream nextPutAll: '#include '].
		aStream nextPutAll: hdr; cr]
]

{ #category : #public }
CCodeGenerator >> exportedPrimitiveNames [
	"Return an array of all exported primitives"
	^methods select:[:m| m export] thenCollect:[:m| self cFunctionNameFor: m selector].

]

{ #category : #utilities }
CCodeGenerator >> extractTypeFor: aVariable fromDeclaration: aVariableDeclaration [
	"Eliminate inessentials from aVariableDeclaration to answer a C type without the variable,
	 or initializations etc"
	| decl |
	((aVariableDeclaration beginsWith: 'static ')
	 or: [aVariableDeclaration beginsWith: 'extern ']) ifTrue:
		[^self extractTypeFor: aVariable fromDeclaration: (aVariableDeclaration allButFirst: 7)].
	decl := (aVariableDeclaration indexOf: $= ifAbsent: [])
				ifNotNil: [:index| aVariableDeclaration copyFrom: 1 to: index - 1]
				ifNil: [aVariableDeclaration].
	decl := decl copyReplaceAll: aVariable with: '' tokenish: [:ch| ch = $_ or: [ch isAlphaNumeric]].
	^self baseTypeForType: decl
]

{ #category : #'C code generator' }
CCodeGenerator >> fileHeaderVersionStampForSourceClass: sourceClass [
	"Answer a suitable version stamp to include in the header."
	| exportBuildInfo slangDescription sourceDescription |
	[exportBuildInfo := sourceClass isInterpreterClass
						ifTrue: ['char *__interpBuildInfo = __buildInfo;']
						ifFalse:
							[sourceClass isCogitClass
								ifTrue: ['char *__cogitBuildInfo = __buildInfo;']
								ifFalse:
									[sourceClass isPluginClass ifTrue:
										[sourceClass exportBuildInfoOrNil]]]]
		on: MessageNotUnderstood
		do: [:ex| ex resume: false].
	[slangDescription := self class monticelloDescriptionFor: self class.
	 sourceClass ifNotNil:
		[sourceDescription := [sourceClass monticelloDescription]
								on: MessageNotUnderstood
								do: [:ex| self class monticelloDescriptionFor: sourceClass]]]
		on: Error
		do: [:ex| | now |
			now := Time dateAndTimeNow printString.
			^String streamContents:
				[:s|
				s nextPutAll: '/* Automatically generated from Squeak on '.
				s nextPutAll: now.
				s nextPutAll: ' */'; cr; cr.
				s nextPutAll: 'static char __buildInfo[] = "Generated on '.
				s nextPutAll: now.
				s nextPutAll: '. Compiled on "'.
				s nextPutAll: '__DATE__ ;'; cr.
				exportBuildInfo ifNotNil:
					[s nextPutAll: exportBuildInfo; cr].
				s cr]].
	^String streamContents:
		[:s|
		s nextPutAll: '/* Automatically generated by\	' withCRs.
		s nextPutAll: slangDescription.
		sourceDescription ifNotNil:
			[s nextPutAll: '\   from\	' withCRs; nextPutAll: (sourceDescription copyReplaceAll: '\' withCRs with: '\	' withCRs)].
		s cr; nextPutAll: ' */'; cr.
		sourceDescription ifNotNil:
			[s nextPutAll: 'static char __buildInfo[] = "'.
			 s nextPutAll: (sourceDescription copyReplaceAll: '\' withCRs with: '\n\', '\' withCRs).
			 s nextPutAll: ' " __DATE__ ;'; cr.
			exportBuildInfo ifNotNil:
				[s nextPutAll: exportBuildInfo; cr].
			s cr]]
]

{ #category : #'C translation' }
CCodeGenerator >> generateAbs: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| type strippedType absFun |
	type := self typeFor: msgNode receiver in: currentMethod.
	strippedType := (type beginsWith: 'unsigned ')
		ifTrue: [type allButFirst: 'unsigned ' size]
		ifFalse: [(type beginsWith: 'u')
			ifTrue: [type allButFirst: 1]
			ifFalse: [type]].
	absFun :=
		(#(	('long long' llabs) ('__int64' #llabs) ('int64_t' #llabs)
			(sqInt SQABS)
			(sqLong SQLABS)
			(double fabs)
			(float fabsf))
				detect: [:tuple| strippedType beginsWith: tuple first]
				ifNone: [])
			ifNotNil: [:tuple| tuple last]
			ifNil: [#abs].
	
	aStream nextPutAll: absFun.
	aStream nextPut: $(.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateAddressOf: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPut: $(; nextPut: $&.
	self emitCExpression: msgNode args first on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateAllMask: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '(('.
	self generateBitAnd: msgNode on: aStream indent: level.
	aStream nextPutAll: ') == '.
	self emitCExpression: msgNode args first on: aStream indent: level.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateAnd: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream indent: level.
	aStream nextPutAll: ' && '.
	self emitCExpression: msgNode args first on: aStream indent: level
]

{ #category : #'C translation' }
CCodeGenerator >> generateAsAddress: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode args first on: aStream
]

{ #category : #'C translation support' }
CCodeGenerator >> generateAsConstantExpression: msgNode on: aStream [
	"Attempt to generate the C code for this message onto the given stream.
	 Answer if the attempt succeeded.  This handles integer overflow of int
	 expressions in a 64-bit compiler."

	msgNode constantNumbericValueOrNil ifNotNil:
		[:value|
		 (value between: -1 << 31 and: 1 << 31 - 1) ifFalse:
			[aStream nextPutAll: (self cLiteralFor: value).
			 ^true]].
	^false
]

{ #category : #'C translation' }
CCodeGenerator >> generateAsFloat: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll:'((double) '.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' )'.
]

{ #category : #'C translation' }
CCodeGenerator >> generateAsInteger: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll:'((sqInt)'.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateAsIntegerPtr: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll:'((sqIntptr_t)'.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateAsLong: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll:'((long)'.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateAsSymbol: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream.
	 The receiver is expected to be a TConstantNode."

	aStream nextPutAll: (self cFunctionNameFor: msgNode receiver nameOrValue)
]

{ #category : #'C translation' }
CCodeGenerator >> generateAsUnsignedInteger: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll:'((usqInt)'.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateAsUnsignedIntegerPtr: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll:'((usqIntptr_t)'.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateAsUnsignedLong: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll:'((unsigned long)'.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateAsUnsignedLongLong: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll:'((unsigned long long)'.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateAsVoidPointer: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '((void *)'.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateAt: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPut: $[.
	msgNode args first emitCCodeAsExpressionOn: aStream level: level + 1 generator: self.
	aStream nextPut: $]
]

{ #category : #'C translation' }
CCodeGenerator >> generateAtPut: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPut: $[.
	msgNode args first emitCCodeAsExpressionOn: aStream level: level + 1 generator: self.
	aStream nextPutAll: '] = '.
	self emitCExpression: msgNode args last on: aStream
]

{ #category : #'C translation' }
CCodeGenerator >> generateBaseHeaderSize: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: 'BaseHeaderSize'

]

{ #category : #'C translation' }
CCodeGenerator >> generateBetweenAnd: msgNode on: aStream indent: level [
	"Generate the C code for the between:and: message onto the given stream."

	aStream nextPutAll: '(('.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' >= '.
	self emitCExpression: msgNode args first on: aStream.
	aStream nextPutAll: ') && ('.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' <= '.
	self emitCExpression: msgNode args second on: aStream.
	aStream nextPutAll: '))'
]

{ #category : #'C translation' }
CCodeGenerator >> generateBitAnd: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream indent: level.
	aStream nextPutAll: ' & '.
	self emitCExpression: msgNode args first on: aStream indent: level
]

{ #category : #'C translation' }
CCodeGenerator >> generateBitClear: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream next: 2 put: $(.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' | '.
	self emitCExpression: msgNode args first on: aStream.
	aStream nextPutAll: ') - '.
	self emitCExpression: msgNode args first on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateBitInvert: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream.
	 If the selector is bitInvert32 then cast to unsigned int to ensure
	 a 32-bit value on 64-bit platforms."

	| castToUnsignedInt castToUnsignedLong castToUnsignedLongLong |
	(castToUnsignedInt := msgNode selector = #bitInvert32) ifTrue:
		[aStream nextPutAll: '(unsigned int)'].
	aStream nextPut: $~.
	(castToUnsignedLong := msgNode selector = #bitInvert64 and: [vmClass notNil and: [vmClass objectMemoryClass wordSize = 8]]) ifTrue:
		[aStream nextPutAll: '(usqIntptr_t)'].
	(castToUnsignedLongLong := msgNode selector = #bitInvert64 and: [vmClass isNil or: [vmClass objectMemoryClass wordSize = 4]]) ifTrue:
		[aStream nextPutAll: '(unsigned long long)'].
	self assert: castToUnsignedInt asBit + castToUnsignedLong asBit + castToUnsignedLongLong asBit <= 1. "We should only do a single cast"
	self emitCExpression: msgNode receiver on: aStream
]

{ #category : #'C translation' }
CCodeGenerator >> generateBitOr: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream indent: level.
	aStream nextPutAll: ' | '.
	self emitCExpression: msgNode args first on: aStream indent: level
]

{ #category : #'C translation' }
CCodeGenerator >> generateBitShift: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| arg rcvr shift |
	arg := msgNode args first.
	rcvr := msgNode receiver.
	(self isConstantNode: arg valueInto: [:shiftValue| shift := shiftValue])
		ifTrue: "bit shift amount is a constant"
			[aStream nextPutAll: '((usqInt) '.
			self emitCExpression: rcvr on: aStream.
			shift < 0
				ifTrue: [aStream nextPutAll: ' >> '; print: shift negated]
				ifFalse: [aStream nextPutAll: ' << '; print: shift].
			aStream nextPut: $)]
		ifFalse: "bit shift amount is an expression"
			[aStream nextPutAll: '(('.
			self emitCExpression: arg on: aStream indent: level.
			aStream nextPutAll: ' < 0) ? ((usqInt) '.
			self emitCExpression: rcvr on: aStream indent: level.
			aStream nextPutAll: ' >> -'.
			self emitCExpression: arg on: aStream indent: level.
			aStream nextPutAll: ') : ((usqInt) '.
			self emitCExpression: rcvr on: aStream indent: level.
			aStream nextPutAll: ' << '.
			self emitCExpression: arg on: aStream indent: level.
			aStream nextPutAll: '))']
]

{ #category : #'C translation' }
CCodeGenerator >> generateBitXor: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream indent: level.
	aStream nextPutAll: ' ^ '.
	self emitCExpression: msgNode args first on: aStream indent: level
]

{ #category : #'C translation' }
CCodeGenerator >> generateByteSwap32: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: #'SQ_SWAP_4_BYTES'.
	aStream nextPut: $(.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateByteSwap32IfBigEndian: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: #'SQ_SWAP_4_BYTES_IF_BIGENDIAN'.
	aStream nextPut: $(.
	self emitCExpression: msgNode args first on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateByteSwap64: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: #'SQ_SWAP_8_BYTES'.
	aStream nextPut: $(.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateByteSwap64IfBigEndian: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: #'SQ_SWAP_8_BYTES_IF_BIGENDIAN'.
	aStream nextPut: $(.
	self emitCExpression: msgNode args first on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateBytesPerOop: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream.
	 Would prefer to use OopSize than BytesPerOop (shorter)."

	aStream nextPutAll: 'BytesPerOop'
]

{ #category : #'C translation' }
CCodeGenerator >> generateBytesPerWord: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream.
	 Would prefer to use WordSize than BytesPerWord (shorter) but e.g.
	 mpegtype.h has a parameter named WordSize."

	aStream nextPutAll: 'BytesPerWord'
]

{ #category : #'C translation' }
CCodeGenerator >> generateCCoercion: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| cExpr cType literal |
	cExpr := msgNode args first.
	cType := msgNode args last value.
	(cType = #float
	 and: [cExpr isConstant
	 and: [cExpr value isFloat
	 and: [(literal := self cLiteralFor: cExpr value) allSatisfy: [:c| c == $. or: [c isDigit]]]]]) ifTrue:
		[aStream nextPutAll: literal; nextPut: $f.
		 ^self].
	aStream nextPutAll: '(('.
	aStream nextPutAll: cType.
	aStream nextPutAll: ') '.
	self emitCExpression: cExpr on: aStream.
	aStream nextPut: $)
]

{ #category : #accessing }
CCodeGenerator >> generateDeadCode [
	"Answer whether we should generate 'dead code' branches. This can be useful for hacking the VM when used in conjunction with #useSymbolicConstants, e.g., for code like:
		DoAssertionChecks ifTrue:[
			...
		].

	we will generate

		#define DoAssertionChecks 0
		...
		if(DoAssertionChecks) {
			...
		}.

	allowing us to change the #define (or redefine it as a variable) for later use."
	^generateDeadCode
]

{ #category : #accessing }
CCodeGenerator >> generateDeadCode: aBool [
	"Indicate whether we should generate 'dead code' branches."
	generateDeadCode := aBool
]

{ #category : #'C translation' }
CCodeGenerator >> generateDeny: denyMsgNode on: aStream indent: level [
	"Generate the C code for a deny: expr onto the given stream."

	aStream nextPutAll: 'assert(!('.
	self emitCExpression: denyMsgNode args first on: aStream.
	aStream nextPutAll: '))'
]

{ #category : #'C translation' }
CCodeGenerator >> generateDivide: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| rcvr arg divisor check |
	rcvr := msgNode receiver.
	arg := msgNode args first.
	check :=	false "If you need to check the validity of divides that had been implemented by signed shifts, change this to true..."
				and: [arg isConstant
				and: [(divisor := arg value) isInteger
				and: [divisor isPowerOfTwo
				and: [divisor > 0
				and: [divisor <= (1 bitShift: 31)]]]]].
	check ifTrue:
		[(headerFiles includes: '"sqAssert.h"') ifFalse:
			[self addHeaderFile: '"sqAssert.h"'].
		aStream nextPut: $(; nextPutAll: 'assert(((sqInt) '.
		 self emitCExpression: rcvr on: aStream.
		 aStream nextPutAll: ' >> ', (divisor log: 2) asInteger printString.
		 aStream nextPutAll: ') == ('.
		 self emitCExpression: rcvr on: aStream.
		aStream nextPutAll: ' / '.
		self emitCExpression: msgNode args first on: aStream.
		aStream nextPutAll: ')),'].
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' / '.
	self emitCExpression: msgNode args first on: aStream.
	check ifTrue:
		[aStream nextPut: $)]
]

{ #category : #'C translation' }
CCodeGenerator >> generateDoWhileFalse: msgNode on: aStream indent: level [
	"Generate do {stmtList} while(!(cond))"

	| testStmt receiverWithoutTest |
	testStmt := msgNode receiver statements last.
	receiverWithoutTest := TStmtListNode new setStatements: msgNode receiver statements allButLast.
	aStream nextPutAll: 'do {'; cr.
	receiverWithoutTest emitCCodeOn: aStream level: level + 1 generator: self.
	aStream tab: level.
	aStream nextPutAll: '} while(!('.
	testStmt emitCCodeAsExpressionOn: aStream level: level + 1 generator: self.
	aStream nextPutAll: '))'
]

{ #category : #'C translation' }
CCodeGenerator >> generateDoWhileTrue: msgNode on: aStream indent: level [
	"Generate do {stmtList} while(cond)"

	| testStmt receiverWithoutTest |
	testStmt := msgNode receiver statements last.
	receiverWithoutTest := TStmtListNode new setStatements: msgNode receiver statements allButLast.
	aStream nextPutAll: 'do {'; cr.
	receiverWithoutTest emitCCodeOn: aStream level: level + 1 generator: self.
	aStream tab: level.
	aStream nextPutAll: '} while('.
	testStmt emitCCodeAsExpressionOn: aStream level: level + 1 generator: self.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateEqual: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream indent: level.
	aStream nextPutAll: ' == '.
	self emitCExpression: msgNode args first on: aStream indent: level
]

{ #category : #'C translation' }
CCodeGenerator >> generateFlag: msgNode on: aStream indent: level [
	"Compoensate for the use of self flag: #aSymbol.  We used to translate  symbols
	 as strings unless they were quoted via #aSymbol asSymbol. But this is too tedious,
	 so we now translate symbols directly.  The only use that this affected was in
		 self flag: #aSymbol,
	 so hard-code it to produce a string value.  Note that this isn't strictly necessary
	 because there's a
		#define flag(foo) 0
	 in C land, but it makes the generated C less dissonant."

	aStream
		nextPutAll: 'flag(';
		nextPutAll: (self cLiteralFor: msgNode args last value asString);
		nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateGreaterThan: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream indent: level.
	aStream nextPutAll: ' > '.
	self emitCExpression: msgNode args first on: aStream indent: level
]

{ #category : #'C translation' }
CCodeGenerator >> generateGreaterThanOrEqual: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream indent: level.
	aStream nextPutAll: ' >= '.
	self emitCExpression: msgNode args first on: aStream indent: level
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfFalse: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode receiver)
		ifNil:
			["Eliminate double-negatives"
			 (msgNode receiver isSend and: [msgNode receiver selector == #not]) ifTrue:
				[^self generateIfTrue: (TSendNode new
											setSelector: msgNode selector
											receiver: msgNode receiver receiver
											arguments: msgNode args
											isBuiltInOp: msgNode isBuiltinOperator)
					on: aStream
					indent: level].
			aStream nextPutAll: 'if (!'.
			msgNode receiver isLeaf ifFalse: [aStream nextPut: $(]. "grrrrr"
			msgNode receiver emitCCodeAsExpressionOn: aStream level: level + 1 generator: self.
			msgNode receiver isLeaf ifFalse: [aStream nextPut: $)]. "grrrrr"
			aStream nextPutAll: ') {'; cr.
			msgNode args last emitCCodeOn: aStream level: level + 1 generator: self.
			aStream tab: level.
			aStream nextPut: $}]
		ifNotNil:
			[:const |
			const ifFalse:
				[msgNode args first emitCCodeOn: aStream level: level generator: self]]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfFalseAsArgument: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode receiver)
		ifNil:
			["Eliminate double-negatives"
			 (msgNode receiver isSend and: [msgNode receiver selector == #not]) ifTrue:
				[^self generateIfTrueAsArgument: (TSendNode new
														setSelector: msgNode selector
														receiver: msgNode receiver receiver
														arguments: msgNode args
														isBuiltInOp: msgNode isBuiltinOperator)
					on: aStream
					indent: level].
			aStream nextPutAll: '(!('.
			msgNode receiver emitCCodeAsArgumentOn: aStream level: 0 generator: self.
			aStream nextPut: $); crtab: level + 1; nextPut: $?; space.
			msgNode args last emitCCodeAsArgumentOn: aStream level: level + 2 generator: self.
			aStream crtab: level + 1; nextPutAll: ': 0)']
		ifNotNil:
			[:const|
			const
				ifFalse: [msgNode args first emitCCodeAsArgumentOn: aStream level: level generator: self]
				ifTrue: [aStream nextPutAll: (self cLiteralFor: nil)]]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfFalseIfTrue: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode receiver)
		ifNil:
			[(self tryToCollapseBothArmsOfConditional: msgNode on: aStream indent: level) ifFalse:
				[aStream nextPutAll: 'if ('.
				 msgNode receiver emitCCodeAsExpressionOn: aStream level: level generator: self.
				 aStream nextPutAll: ') {'; cr.
				 msgNode args last emitCCodeOn: aStream level: level + 1 generator: self.
				 aStream tab: level; nextPut: $}; crtab: level; nextPutAll: 'else {'; cr.
				 msgNode args first emitCCodeOn: aStream level: level + 1 generator: self.
				 aStream tab: level; nextPut: $}]]
		ifNotNil:
			[:const |
			 (const ifTrue: [msgNode args last] ifFalse: [msgNode args first])
				emitCCodeOn: aStream level: level generator: self]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfFalseIfTrueAsArgument: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode receiver)
		ifNil:
			[(self tryToCollapseBothArmsOfConditionalExpression: msgNode on: aStream indent: level) ifFalse:
				[aStream nextPut: $(.
				 msgNode receiver emitCCodeAsArgumentOn: aStream level: level generator: self.
				 aStream crtab: level + 1; nextPut: $?; space.
				 msgNode args last emitCCodeAsArgumentOn: aStream level: level + 2 generator: self.
				 aStream crtab: level + 1; nextPut: $:; space.
				 msgNode args first emitCCodeAsArgumentOn: aStream level: level + 2 generator: self.
				 aStream nextPut: $)]]
		ifNotNil:
			[:const|
			(const
				ifTrue: [msgNode args last]
				ifFalse: [msgNode args first])
					emitCCodeAsArgumentOn: aStream level: level generator: self]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfNil: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self isNilConstantReceiverOf: msgNode)
		ifFalse:
			[aStream nextPutAll: 'if (!('.
			 msgNode receiver emitCCodeAsExpressionOn: aStream level: level + 1 generator: self.
			 aStream nextPutAll: ')) {'; cr.
			 msgNode args last emitCCodeOn: aStream level: level + 1 generator: self.
			 aStream tab: level; nextPut: $}]
		ifTrue:
			[msgNode args first emitCCodeOn: aStream level: level generator: self]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfNilAsArgument: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self isNilConstantReceiverOf: msgNode)
		ifFalse:
			[aStream nextPutAll: '(!('.
			 msgNode receiver emitCCodeAsArgumentOn: aStream level: 0 generator: self.
			 aStream nextPut: $); crtab: level + 1; nextPut: $?; space.
			 msgNode args last emitCCodeAsArgumentOn: aStream level: level + 2 generator: self.
			 aStream crtab: level + 1; nextPut: $:; space.
			 msgNode receiver emitCCodeAsArgumentOn: aStream level: 0 generator: self.
			 (msgNode receiver isLeaf
			  or: [msgNode receiver isSend
				  and: [(self isStructSend: msgNode receiver)
				  and: [msgNode receiver receiver isLeaf]]]) ifFalse:
				[logger cr; nextPutAll: 'sending ifNil: to non-leaf in '; nextPutAll: currentMethod selector].
			 aStream nextPut: $)]
		ifTrue:
			[msgNode args first emitCCodeAsArgumentOn: aStream level: level generator: self]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfNilIfNotNil: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self isNilConstantReceiverOf: msgNode)
		ifFalse:
			[aStream nextPutAll: 'if ('.
			msgNode receiver emitCCodeAsExpressionOn: aStream level: level generator: self.
			aStream nextPutAll: ') {'; cr.
			msgNode args last emitCCodeOn: aStream level: level + 1 generator: self.
			aStream tab: level; nextPut: $}; cr; tab: level; nextPutAll: 'else {'; cr.
			msgNode args first emitCCodeOn: aStream level: level + 1 generator: self.
			aStream tab: level; nextPut: $}]
		ifTrue:
			[msgNode args first emitCCodeOn: aStream level: level generator: self]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfNilIfNotNilAsArgument: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self isNilConstantReceiverOf: msgNode)
		ifFalse:
			[aStream nextPut: $(.
			msgNode receiver emitCCodeAsArgumentOn: aStream level: level generator: self.
			aStream crtab: level + 1; nextPut: $?; space.
			msgNode args last emitCCodeAsArgumentOn: aStream level: level + 2 generator: self.
			aStream crtab: level + 1; nextPut: $:; space.
			msgNode args first emitCCodeAsArgumentOn: aStream level: level + 2 generator: self.
			aStream nextPut: $)]
		ifTrue:
			[msgNode args first emitCCodeAsArgumentOn: aStream level: level generator: self]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfNotNil: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self isNilConstantReceiverOf: msgNode)
		ifFalse:
			[aStream nextPutAll: 'if ('.
			msgNode receiver emitCCodeAsExpressionOn: aStream level: level generator: self.
			aStream nextPutAll: ') {'; cr.
			msgNode args first emitCCodeOn: aStream level: level + 1 generator: self.
			level timesRepeat: [ aStream tab ].
			aStream nextPut: $}]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfNotNilAsArgument: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self isNilConstantReceiverOf: msgNode)
		ifFalse:
			[aStream nextPut: $(.
			 msgNode receiver emitCCodeAsArgumentOn: aStream level: level generator: self.
			 aStream crtab: level + 1; nextPut: $?; space.
			 msgNode args first emitCCodeAsArgumentOn: aStream level: level + 2 generator: self.
			 aStream crtab: level + 1; nextPutAll: ': 0)']
		ifTrue:
			[aStream nextPutAll: (self cLiteralFor: nil)]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfNotNilIfNil: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self isNilConstantReceiverOf: msgNode)
		ifFalse:
			[aStream nextPutAll: 'if ('.
			msgNode receiver emitCCodeAsExpressionOn: aStream level: level generator: self.
			aStream nextPutAll: ') {'; cr.
			msgNode args first emitCCodeOn: aStream level: level + 1 generator: self.
			aStream tab: level; nextPut: $}; cr; tab: level; nextPutAll: 'else {'; cr.
			msgNode args last emitCCodeOn: aStream level: level + 1 generator: self.
			aStream tab: level; nextPut: $}]
		ifTrue:
			[msgNode args last emitCCodeOn: aStream level: level generator: self]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfNotNilIfNilAsArgument: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self isNilConstantReceiverOf: msgNode)
		ifFalse:
			[aStream nextPut: $(.
			msgNode receiver emitCCodeAsExpressionOn: aStream level: level generator: self.
			aStream crtab: level + 1; nextPut: $?; space.
			msgNode args first emitCCodeAsArgumentOn: aStream level: level + 2 generator: self.
			aStream crtab: level + 1; nextPut: $:; space.
			msgNode args last emitCCodeAsArgumentOn: aStream level: level + 2 generator: self.
			aStream nextPut: $)]
		ifTrue:
			[msgNode args last emitCCodeAsArgumentOn: aStream level: level generator: self]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfTrue: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode receiver)
		ifNil:
			[aStream nextPutAll: 'if ('.
			msgNode receiver emitCCodeAsExpressionOn: aStream level: level generator: self.
			aStream nextPutAll: ') {'; cr.
			msgNode args first emitCCodeOn: aStream level: level + 1 generator: self.
			aStream tab: level.
			aStream nextPut: $}]
		ifNotNil:
			[:const |
			const ifTrue:
				[msgNode args first emitCCodeOn: aStream level: level generator: self]]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfTrueAsArgument: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode receiver)
		ifNil:
			[aStream nextPut: $(.
			 msgNode receiver emitCCodeAsArgumentOn: aStream level: level generator: self.
			 aStream crtab: level + 1; nextPut: $?; space.
			 msgNode args first emitCCodeAsArgumentOn: aStream level: level + 2 generator: self.
			 aStream crtab: level + 1; nextPutAll: ': 0)']
		ifNotNil:
			[:const|
			const
				ifTrue: [msgNode args first emitCCodeAsArgumentOn: aStream level: level generator: self]
				ifFalse: [aStream nextPutAll: (self cLiteralFor: nil)]]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfTrueIfFalse: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode receiver)
		ifNil:
			[(self tryToCollapseBothArmsOfConditional: msgNode on: aStream indent: level) ifFalse:
				[aStream nextPutAll: 'if ('.
				 msgNode receiver emitCCodeAsExpressionOn: aStream level: level generator: self.
				 aStream nextPutAll: ') {'; cr.
				 msgNode args first emitCCodeOn: aStream level: level + 1 generator: self.
				 aStream tab: level; nextPut: $}; crtab: level; nextPutAll: 'else {'; cr.
				 msgNode args last emitCCodeOn: aStream level: level + 1 generator: self.
				 aStream tab: level; nextPut: $}]]
		ifNotNil:
			[:const |
			(const ifTrue: [msgNode args first] ifFalse: [msgNode args last])
				emitCCodeOn: aStream level: level generator: self]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfTrueIfFalseAsArgument: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode receiver)
		ifNil:
			[(self tryToCollapseBothArmsOfConditionalExpression: msgNode on: aStream indent: level) ifFalse:
				[aStream nextPut: $(.
				 msgNode receiver emitCCodeAsExpressionOn: aStream level: level generator: self.
				 aStream crtab: level + 1; nextPut: $?; space.
				 msgNode args first emitCCodeAsArgumentOn: aStream level: level + 2 generator: self.
				 aStream crtab: level + 1; nextPut: $:; space.
				 msgNode args last emitCCodeAsArgumentOn: aStream level: level + 2 generator: self.
				 aStream nextPut: $)]]
		ifNotNil:
			[:const|
			(const
				ifTrue: [msgNode args first]
				ifFalse: [msgNode args last])
					emitCCodeAsArgumentOn: aStream level: level generator: self]
]

{ #category : #'C translation' }
CCodeGenerator >> generateInlineCCode: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream.
	 There are two forms, self cCode: aString ... and self cCode: aBlock."

	msgNode args first isConstant
		ifTrue:
			[(msgNode args first value at: 1 ifAbsent: nil) = $# ifTrue:
				[aStream cr].
			aStream nextPutAll: msgNode args first value.
			self noteVariableUsageInString: msgNode args first value]
		ifFalse: [msgNode args first
					emitCCodeOn: aStream
					level: level
					generator: self]
]

{ #category : #'C translation' }
CCodeGenerator >> generateInlineCCodeAsArgument: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream.
	 There are two forms, self cCode: aString ... and self cCode: aBlock."

	(msgNode args first isConstant
	 and: [msgNode args first value isString])
		ifTrue:
			[(msgNode args first value at: 1 ifAbsent: nil) = $# ifTrue:
				[aStream cr].
			aStream nextPutAll: msgNode args first value.
			self noteVariableUsageInString: msgNode args first value]
		ifFalse: [msgNode args first
					emitCCodeAsArgumentOn: aStream
					level: level
					generator: self]
]

{ #category : #'C translation' }
CCodeGenerator >> generateInlineCPreprocessorDirective: msgNode on: aStream indent: level [
	"Generate the C preprocessor directive for this message onto the given stream."

	aStream cr; nextPutAll: msgNode args first value.
	self noteVariableUsageInString: msgNode args first value
]

{ #category : #'C translation' }
CCodeGenerator >> generateInlineCppIfElse: msgNode asArgument: asArgument on: aStream indent: level [
	"Generate the C code for this message onto the given stream."
	| expr putStatement |
	"Compile-time expansion for constants set in the options dictionary,
	 e.g. to cut down on noise for MULTIPLEBYTECODESETS."
	putStatement := asArgument
		ifTrue: "emitCCodeAsArgumentOn: doesn't indent, the code needs indenting if it takes multiple lines, so post-process."
			[[:node| | expansion |
			  expansion := String streamContents: [:s| node emitCCodeAsArgumentOn: s level: level generator: self].
			  aStream nextPutAll:
			  ((expansion includes: Character cr)
				ifTrue:
					[(String streamContents:
							[:s|
							s position > 0 ifTrue: [s tab: level + 1].
							node emitCCodeAsArgumentOn: s level: level generator: self])
						copyReplaceAll: (String with: Character cr)
						with: (String with: Character cr), (String new: level + 1 withAll: Character tab)]
				ifFalse: [expansion])]]
		ifFalse:
			[[:node| | expansion |
			  expansion := String streamContents: [:s| node emitCCodeOn: s level: level generator: self].
			 "Remove tabs from first line to avoid indenting a second time"
			 expansion ifNotEmpty:
				[expansion := expansion allButFirst: (expansion findFirst: [:c| c ~~ Character tab]) - 1].
			 aStream nextPutAll: expansion]].

	(self nilOrBooleanConditionFor: msgNode args first) ifNotNil:
		[:condition|
		 condition
			ifTrue:
				[putStatement value: msgNode args second]
			ifFalse:
				[msgNode args size >= 3 ifTrue:
					[putStatement value: msgNode args third]].
		 ^self].

	"Full #if ... #else..."
	putStatement := asArgument
		ifTrue: "emitCCodeAsArgumentOn: doesn't indent, the code needs indenting in this case, so post-process."
			[[:node|
			  aStream nextPutAll:
				((String streamContents:
						[:s|
						s next: level + 1 put: Character tab.
						node emitCCodeAsArgumentOn: s level: level generator: self])
					copyReplaceAll: (String with: Character cr)
					with: (String with: Character cr), (String new: level + 1 withAll: Character tab))]]
		ifFalse:
			[[:node| node emitCCodeOn: aStream level: level generator: self]].

	expr := String streamContents:
				[:es|
				msgNode args first
					emitCCodeAsArgumentOn: es
					level: 0
					generator: self].
	[expr last isSeparator] whileTrue:
		[expr := expr allButLast].
	aStream
		ensureCr;
		nextPut: $#; next: level * 2 put: Character space; nextPutAll: 'if '; nextPutAll: expr; cr.

	self with: msgNode args first
		ifAppropriateSetTo: true
		do: [putStatement value: msgNode args second].
	expr := ' /* ', expr, ' */'.
	msgNode args size >= 3 ifTrue:
		[aStream
			ensureCr;
			nextPut: $#; next: level * 2 put: Character space; nextPutAll: 'else'; nextPutAll: expr;
			cr.
		self with: msgNode args first
			ifAppropriateSetTo: false
			do: [putStatement value: msgNode args third]].
	aStream
		ensureCr;
		nextPut: $#; next: level * 2 put: Character space; nextPutAll: 'endif'; nextPutAll: expr;
		cr.
	asArgument ifTrue:
		[aStream next: level + 1 put: Character tab]
]

{ #category : #'C translation' }
CCodeGenerator >> generateInlineCppIfElse: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."
	self generateInlineCppIfElse: msgNode asArgument: false on: aStream indent: level
]

{ #category : #'C translation' }
CCodeGenerator >> generateInlineCppIfElseAsArgument: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."
	self generateInlineCppIfElse: msgNode asArgument: true on: aStream indent: level
]

{ #category : #'C translation' }
CCodeGenerator >> generateInlineDirective: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '/* inline: '.
	aStream nextPutAll: msgNode args first name.
	aStream nextPutAll: ' */'.

]

{ #category : #'C translation' }
CCodeGenerator >> generateIntegerObjectOf: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."
	| expr mustCastToUnsigned type typeIsUnsigned |
	expr := msgNode args first.
	aStream nextPutAll: '(('.
	"Note that the default type of an integer constant in C is int.  Hence we /must/
	 cast expression to long if in the 64-bit world, since e.g. in 64-bits
		(int)(16r1FFFFF << 3) = (int)16rFFFFFFF8 = -8
	 whereas
		(long)(16r1FFFFF << 3) = (long) 16rFFFFFFF8 = 4294967288."
	type := self typeFor: expr in: currentMethod.
	typeIsUnsigned := type first = $u.
	mustCastToUnsigned := typeIsUnsigned not
		or: [(self sizeOfIntegralCType: type) < (self sizeOfIntegralCType: #usqInt)].
	mustCastToUnsigned ifTrue:
		[aStream nextPutAll: '(usqInt)'].
	self emitCExpression: expr on: aStream.
	aStream
		nextPutAll: ' << ';
		print: vmClass objectMemoryClass numSmallIntegerTagBits;
		nextPutAll: ') | 1)'
]

{ #category : #'C translation' }
CCodeGenerator >> generateIntegerValueOf: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPut: $(.
	self emitCExpression: msgNode args first on: aStream.
	aStream nextPutAll: ' >> ';
		print: vmClass objectMemoryClass numSmallIntegerTagBits;
		nextPut: $).
]

{ #category : #'C translation' }
CCodeGenerator >> generateIsIntegerObject: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	vmClass objectMemoryClass numSmallIntegerTagBits = 1
		ifTrue:
			[aStream nextPutAll: '('.
			 self emitCExpression: msgNode args first on: aStream.
			 aStream nextPutAll: ' & 1)']
		ifFalse:
			[aStream nextPutAll: '((('.
			 self emitCExpression: msgNode args first on: aStream.
			 aStream
				nextPutAll: ') & ';
				print: 1 << vmClass objectMemoryClass numSmallIntegerTagBits - 1;
				nextPutAll: ') == 1)']
]

{ #category : #'C translation' }
CCodeGenerator >> generateIsNil: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' == '.
	aStream nextPutAll: (self cLiteralFor: nil).
]

{ #category : #'C translation' }
CCodeGenerator >> generateLessThan: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream indent: level.
	aStream nextPutAll: ' < '.
	self emitCExpression: msgNode args first on: aStream indent: level
]

{ #category : #'C translation' }
CCodeGenerator >> generateLessThanOrEqual: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream indent: level.
	aStream nextPutAll: ' <= '.
	self emitCExpression: msgNode args first on: aStream indent: level
]

{ #category : #'C translation' }
CCodeGenerator >> generateMax: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '(('.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' < '.
	self emitCExpression: msgNode args first on: aStream.
	aStream nextPutAll: ') ? '.
	self emitCExpression: msgNode args first on: aStream.
	aStream nextPutAll: ' : '.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'C translation' }
CCodeGenerator >> generateMin: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '(('.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' < '.
	self emitCExpression: msgNode args first on: aStream.
	aStream nextPutAll: ') ? '.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' : '.
	self emitCExpression: msgNode args first on: aStream.
	aStream nextPutAll: ')'.
]

{ #category : #'C translation' }
CCodeGenerator >> generateMinus: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self generateAsConstantExpression: msgNode on: aStream) ifFalse:
		[msgNode args first constantNumbericValueOrNil ifNotNil:
			[:value|
			 value = 0 ifTrue:
				[^self emitCExpression: msgNode receiver on: aStream]].
		 self emitCExpression: msgNode receiver on: aStream.
		 aStream nextPutAll: ' - '.
		 self emitCExpression: msgNode args first on: aStream]
]

{ #category : #'C translation' }
CCodeGenerator >> generateModulo: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' % '.
	self emitCExpression: msgNode args first on: aStream.
]

{ #category : #'C translation' }
CCodeGenerator >> generateNegated: msgNode on: aStream indent: level [
	"Generate the C code for teh negated message onto the given stream."

	aStream nextPut: $-.
	self emitCExpression: msgNode receiver on: aStream
]

{ #category : #'C translation' }
CCodeGenerator >> generateNoMask: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPut: $(.
	self generateBitAnd: msgNode on: aStream indent: level.
	aStream nextPutAll: ') == 0'
]

{ #category : #'C translation' }
CCodeGenerator >> generateNot: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '!'.
	self emitCExpression: msgNode receiver on: aStream indent: level
]

{ #category : #'C translation' }
CCodeGenerator >> generateNotEqual: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream indent: level.
	aStream nextPutAll: ' != '.
	self emitCExpression: msgNode args first on: aStream indent: level
]

{ #category : #'C translation' }
CCodeGenerator >> generateNotNil: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' != '.
	aStream nextPutAll: (self cLiteralFor: nil).
]

{ #category : #'C translation' }
CCodeGenerator >> generateOr: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' || '.
	self emitCExpression: msgNode args first on: aStream.
]

{ #category : #'C translation' }
CCodeGenerator >> generatePerform: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode args first on: aStream.
	aStream nextPut: $(.
	(msgNode args copyFrom: 2 to: msgNode args size) do:[:arg|
		self emitCExpression: arg on: aStream.
	] separatedBy:[aStream nextPutAll:', '].
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generatePlus: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."
	(self generateAsConstantExpression: msgNode on: aStream) ifFalse:
		[msgNode args first constantNumbericValueOrNil ifNotNil:
			[:value|
			 value = 0 ifTrue:
				[^self emitCExpression: msgNode receiver on: aStream]].
		 self emitCExpression: msgNode receiver on: aStream.
		 aStream nextPutAll: ' + '.
		 self emitCExpression: msgNode args first on: aStream]
]

{ #category : #'C translation' }
CCodeGenerator >> generatePreDecrement: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| varNode |
	varNode := msgNode receiver.
	varNode isVariable
		ifFalse: [ self error: 'preDecrement can only be applied to variables' ].
	aStream nextPutAll: '--'.
	aStream nextPutAll: (self returnPrefixFromVariable: varNode name).

]

{ #category : #'C translation' }
CCodeGenerator >> generatePreIncrement: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| varNode |
	varNode := msgNode receiver.
	varNode isVariable
		ifFalse: [ self error: 'preIncrement can only be applied to variables' ].
	aStream nextPutAll: '++'.
	aStream nextPutAll: (self returnPrefixFromVariable: varNode name).

]

{ #category : #'C translation' }
CCodeGenerator >> generateRaisedTo: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll:'pow('.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ','.
	self emitCExpression: msgNode args first on: aStream.
	aStream nextPutAll:')'.
]

{ #category : #'C translation' }
CCodeGenerator >> generateRepeat: msgNode on: aStream indent: level [
	"Generate while(1) { stmtList } "

	aStream nextPutAll: 'while(1) {'; cr.
	msgNode receiver emitCCodeOn: aStream level: level + 1 generator: self.
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '}'

]

{ #category : #'C translation' }
CCodeGenerator >> generateRounded: msgNode on: aStream indent: level [
	"Generate the C code for rounded onto the given stream."

	aStream nextPutAll: 'round('.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateSequentialAnd: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode receiver)
		ifNil:
			[self emitCExpression: msgNode receiver on: aStream indent: level.
			 "Don't eliminate the first expression if the second one is false, because of potential side-effects;
			  leave that to the C compiler. But /do/ eliminate the second expression if it is vaccuously true."
			 (self nilOrBooleanConstantReceiverOf: msgNode args first) ifNotNil:
				[:const| const == true ifTrue: [^self]].
			 aStream crtab: level; nextPutAll: ' && ('.
			 self emitCTestBlock: msgNode args first on: aStream indent: level.
			 aStream nextPut: $)]
		ifNotNil:
			[:const |
			const
				ifTrue: [self emitCTestBlock: msgNode args first on: aStream indent: level]
				ifFalse: [aStream nextPut: $0]]
]

{ #category : #'C translation' }
CCodeGenerator >> generateSequentialOr: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."
	"Note: PP 2.3 compiler produces two arguments for or:, presumably
	 to help with inlining later. Taking the last agument should do the correct
	 thing even if your compiler is different."

	(self nilOrBooleanConstantReceiverOf: msgNode receiver)
		ifNil:
			[self emitCExpression: msgNode receiver on: aStream indent: level.
			 "Don't eliminate the first expression if the second one is true, because of potential side-effects;
			  leave that to the C compiler. But /do/ eliminate the second expression if it is vaccuously false."
			 (self nilOrBooleanConstantReceiverOf: msgNode args last) ifNotNil:
				[:const| const == false ifTrue: [^self]].
			 aStream crtab: level; nextPutAll: ' || ('.
			 self emitCTestBlock: msgNode args last on: aStream indent: level.
			 aStream nextPut: $)]
		ifNotNil:
			[:const |
			const
				ifTrue: [aStream nextPut: $1]
				ifFalse: [self emitCTestBlock: msgNode args last on: aStream indent: level]]
]

{ #category : #'C translation' }
CCodeGenerator >> generateSharedCodeDirective: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '/* common code: '.
	aStream nextPutAll: msgNode args first value.
	aStream nextPutAll: ' */'.

]

{ #category : #'C translation' }
CCodeGenerator >> generateShiftLeft: msgNode on: aStream indent: level [
	"Generate a C bitShift.  If we can determine the result
	 would overflow the word size, cast to a long integer."
	| rcvr arg castToLong type mustCastBackToSign mustCastToUnsigned canSuffixTheConstant typeIsUnsigned |
	rcvr := msgNode receiver.
	arg := msgNode args first.
	castToLong := false.
	(rcvr constantNumbericValueIfAtAllPossibleOrNilIn: self) ifNotNil:
		[:rcvrVal |
		 (arg constantNumbericValueIfAtAllPossibleOrNilIn: self)
			ifNil: [castToLong := vmClass notNil and: [vmClass objectMemoryClass wordSize = 8]]
			ifNotNil:
				[:argVal |
				| valueBeyondInt |
				valueBeyondInt := 1 bitShift: 32. "The default type of const << N is int."
				castToLong := rcvrVal < valueBeyondInt
								  and: [(rcvrVal bitShift: argVal) >= valueBeyondInt]]].
	canSuffixTheConstant := rcvr isConstant and: [rcvr name isEmpty and: [rcvr value >= 0]].
	canSuffixTheConstant
		ifTrue:
			[aStream nextPutAll: (self cLiteralForUnsignedInteger: rcvr value longlong: castToLong).
			aStream nextPutAll: ' << '.
			self emitCExpression: arg on: aStream indent: level.
			^self].
	type := self typeFor: rcvr in: currentMethod.
	castToLong := castToLong and: [(self sizeOfIntegralCType: type) < (self sizeOfIntegralCType: #usqLong)].
	typeIsUnsigned := type first = $u.
	mustCastToUnsigned := typeIsUnsigned not
		or: [castToLong
		or: [(self sizeOfIntegralCType: type) < (self sizeOfIntegralCType: #usqInt)]].
	mustCastBackToSign := typeIsUnsigned not.
	mustCastBackToSign
		ifTrue:
			[| promotedType |
			promotedType := castToLong
				ifTrue: [#sqLong]
				ifFalse: [(self sizeOfIntegralCType: type) < (self sizeOfIntegralCType: #sqInt)
					ifTrue: [#sqInt]
					ifFalse: [type]].
			aStream nextPutAll: '(('; nextPutAll: promotedType; nextPut: $)].
	mustCastToUnsigned
		ifTrue:
			[| unsigned |
			unsigned := castToLong
				ifTrue: [#usqLong]
				ifFalse: [(self sizeOfIntegralCType: type) < (self sizeOfIntegralCType: #usqLong)
					ifTrue: [#usqInt]
					ifFalse: [self unsignedTypeForIntegralType: type]].
			aStream nextPutAll: '(('; nextPutAll: unsigned; nextPutAll: ')('].
	self emitCExpression: rcvr on: aStream indent: level.
	mustCastToUnsigned ifTrue: [aStream nextPut: $)].
		aStream nextPutAll: ' << '.
		self emitCExpression: arg on: aStream indent: level.
	mustCastToUnsigned ifTrue: [aStream nextPut: $)].
	mustCastBackToSign ifTrue: [aStream nextPut: $)].
]

{ #category : #'C translation' }
CCodeGenerator >> generateShiftRight: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| type |
	"If the variable is a 64-bit type then don't cast it to usqInt (typically a 32-bit type)"
	(self is64BitIntegralVariable: msgNode receiver typeInto: [:t| type := t])
		ifTrue:
			["If not unsigned cast it to unsigned."
			 type first ~= $u ifTrue:
				[aStream nextPutAll: '((unsigned '; nextPutAll: type; nextPut: $)].
			 self emitCExpression: msgNode receiver on: aStream indent: level.
			 type first ~= $u ifTrue:
				[aStream nextPut: $)]]
		ifFalse:
			[aStream nextPutAll: '((usqInt) '.
			 self emitCExpression: msgNode receiver on: aStream indent: level.
			 aStream nextPut: $)].
	aStream nextPutAll: ' >> '.
	self emitCExpression: msgNode args first on: aStream indent: level
]

{ #category : #'C translation' }
CCodeGenerator >> generateSignedBitShift: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| cast type arg shift |
	"since ``signed'' is a synonym for ``signed int'' do not cast 64-bit values to signed if at all possible."
	cast := (self is64BitIntegralVariable: msgNode receiver typeInto: [:t| type := t])
				ifTrue: ['(', (type first = $u ifTrue: [type allButFirst: (type second = $n ifTrue: [2] ifFalse: [1])] ifFalse: [type]), ')']
				ifFalse: ['(signed)'].
	(self isConstantNode: (arg := msgNode args first) valueInto: [:shiftValue| shift := shiftValue])
		ifTrue: "bit shift amount is a constant"
			[aStream nextPut: $(; nextPutAll: cast.
			self emitCExpression: msgNode receiver on: aStream.
			shift < 0
				ifTrue: [aStream nextPutAll: ' >> '; print: shift negated]
				ifFalse: [aStream nextPutAll: ' << '; print: shift].
			aStream nextPut: $)]
		ifFalse: "bit shift amount is an expression"
			[aStream nextPutAll: '(('.
			self emitCExpression: arg on: aStream.
			aStream nextPutAll: ' < 0) ? ('; nextPutAll: cast.
			self emitCExpression: msgNode receiver on: aStream.
			aStream nextPutAll: ' >> -'.
			self emitCExpression: arg on: aStream.
			aStream nextPutAll: ') : ('; nextPutAll: cast.
			self emitCExpression: msgNode receiver on: aStream.
			aStream nextPutAll: ' << '.
			self emitCExpression: arg on: aStream.
			aStream nextPutAll: '))']
]

{ #category : #'C translation' }
CCodeGenerator >> generateSignedIntFromLong64: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '((sqLong) '.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateSignedIntFromLong: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '((int) '.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateSignedIntFromShort: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '((short)'.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateSignedIntToLong64: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '((usqInt) '.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateSignedIntToLong: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '((usqInt) '.
	(vmClass notNil
	 and: [vmClass objectMemoryClass wordSize = 8]) ifTrue:
		[aStream nextPutAll: '(int)'].
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateSignedIntToShort: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '((usqInt) (short)'.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateSignedShiftRight: msgNode on: aStream indent: level [
	"Generate the C code for >>> onto the given stream."

	(self is64BitIntegralVariable: msgNode receiver typeInto: [:t|])
		ifTrue:
			[aStream nextPutAll: '((sqLong) ']
		ifFalse:
			[aStream nextPutAll: '((sqInt) '].
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ') >> '.
	self emitCExpression: msgNode args first on: aStream
]

{ #category : #'C translation' }
CCodeGenerator >> generateSmallIntegerConstant: aSendNode on: aStream indent: indent [
	aSendNode selector = #minSmallInteger ifTrue:
		[^aStream nextPutAll: 'MinSmallInteger'].
	aSendNode selector = #maxSmallInteger ifTrue:
		[^aStream nextPutAll: 'MaxSmallInteger'].
	self error: 'unknown SmallInteger constant'
]

{ #category : #'C translation' }
CCodeGenerator >> generateSmalltalkMetaError: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: 'error("'; nextPutAll: msgNode selector; nextPutAll: '")'
]

{ #category : #'C translation' }
CCodeGenerator >> generateTimes: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self generateAsConstantExpression: msgNode on: aStream) ifFalse:
		[msgNode args first constantNumbericValueOrNil ifNotNil:
			[:value|
			 value = 0 ifTrue:
				[^self emitCExpression: msgNode args first on: aStream].
			 value = 1 ifTrue:
				[^self emitCExpression: msgNode receiver on: aStream]].
		 self emitCExpression: msgNode receiver on: aStream.
		 aStream nextPutAll: ' * '.
		 self emitCExpression: msgNode args first on: aStream]
]

{ #category : #'C translation' }
CCodeGenerator >> generateTimesRepeat: msgNode on: aStream indent: level [
	"Generate while(1) { stmtList } "

	msgNode receiver value timesRepeat:
		[msgNode args first emitCCodeOn: aStream level: level generator: self]
]

{ #category : #'C translation' }
CCodeGenerator >> generateToByDo: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."
	"N.B. MessageNode>>asTranslatorNodeIn: adds the limit var as a hidden fourth argument."
	| blockExpr iterationVar limitExpr mayHaveSideEffects limitVar step |
	blockExpr := msgNode args third.
	blockExpr args size = 1 ifFalse:
		[self error: 'wrong number of block arguments'].
	iterationVar := blockExpr args first.
	limitExpr := msgNode args first.
	aStream nextPutAll: 'for (', iterationVar, ' = '.
	self noteUsedVariableName: iterationVar.
	self emitCExpression: msgNode receiver on: aStream.
	mayHaveSideEffects := msgNode args size = 4. "See TMethod>>prepareMethodIn:"
	mayHaveSideEffects ifTrue:
		[limitVar := msgNode args last.
		 aStream nextPutAll: ', ', limitVar name, ' = '.
		 self emitCExpression: limitExpr on: aStream.
		 limitExpr := limitVar].
	aStream nextPutAll: '; ', iterationVar.
	step := msgNode args at: 2.
	self generateToByDoLimitExpression: limitExpr
		negative: (self stepExpressionIsNegative: step)
		on: aStream.
	aStream nextPutAll: '; ', iterationVar, ' += '.
	self emitCExpression: step on: aStream.
	aStream nextPutAll: ') {'; cr.
	blockExpr emitCCodeOn: aStream level: level + 1 generator: self.
	aStream tab: level.
	aStream nextPut: $}
]

{ #category : #'C translation' }
CCodeGenerator >> generateToByDoLimitExpression: limitExpr negative: negative on: aStream [
	"Generate the limit expression for a to:do: or to:by:do:.
	 If the limitExpr is of the form foo - 1 use < foo or > foo, as appropriate, instead of
	 <= (foo - 1) or >= (foo - 1), so as to avoid underflowing an unsigned value to maxint."
	(limitExpr isSend
	 and: [limitExpr selector = #-
	 and: [limitExpr args first isConstant
	 and: [limitExpr args first value = 1]]])
		ifTrue:
			[aStream nextPutAll: (negative ifTrue: [' > '] ifFalse: [' < ']).
			 self emitCExpression: limitExpr receiver on: aStream]
		ifFalse:
			[aStream nextPutAll: (negative ifTrue: [' >= '] ifFalse: [' <= ']).
			 self emitCExpression: limitExpr on: aStream]
]

{ #category : #'C translation' }
CCodeGenerator >> generateToDo: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| iterationVar |
	(msgNode args last args size = 1) ifFalse: [
		self error: 'wrong number of block arguments'.
	].
	iterationVar := msgNode args last args first.
	aStream nextPutAll: 'for (', iterationVar, ' = '.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: '; ', iterationVar.
	self generateToByDoLimitExpression: msgNode args first negative: false on: aStream.
	aStream nextPutAll: '; ', iterationVar, '++) {'; cr.
	msgNode args last emitCCodeOn: aStream level: level + 1 generator: self.
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '}'.
]

{ #category : #'C translation' }
CCodeGenerator >> generateTouch: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream - which is to say absolutely nothing"

]

{ #category : #'C translation' }
CCodeGenerator >> generateTruncateTo: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| arg |
	(self isConstantNode: msgNode args first valueInto: [:a| arg := a]) ifFalse:
		[self error: 'can''t find method for inlining truncateTo:'].
	self assert: (arg isInteger and: [arg isPowerOfTwo]).
	aStream nextPut: $(.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' & ~'; print: arg - 1; nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateValue: aTSendNode on: aStream indent: level [
	"Reduce [:formal ... :formalN| body ] value: actual ... value: actualN
	 to body with formals substituted for by actuals."
	| substitution substitutionDict newLabels |
	self assert: aTSendNode receiver isStmtList.
	self assert: aTSendNode receiver args size = aTSendNode args size.
	substitution := aTSendNode receiver copy.
	substitution renameLabelsForInliningInto: currentMethod.
	substitutionDict := Dictionary new: aTSendNode args size * 2.
	aTSendNode receiver args with: aTSendNode args do:
		[ :argName :exprNode |
		exprNode isLeaf
			ifTrue: [substitutionDict at: argName put: exprNode]
			ifFalse:
				[aStream nextPutAll: argName; nextPutAll: ' = '.
				 self noteUsedVariableName: argName.
				 exprNode emitCCodeAsExpressionOn: aStream level: level generator: self.
				 aStream nextPut: $; ; crtab: level]].
	substitution
		bindVariablesIn: substitutionDict;
		emitCCodeOn: aStream level: level generator: self.
	newLabels := Set withAll: currentMethod labels.
	substitution nodesDo:
		[:node| node isLabel ifTrue: [node label ifNotNil: [:label| newLabels add: label]]].
	"now add the new labels so that a subsequent inline of
	 the same block will be renamed with different labels."
	currentMethod labels: newLabels
]

{ #category : #'C translation' }
CCodeGenerator >> generateValueAsArgument: aTSendNode on: aStream indent: level [
	"Reduce [:formal ... :formalN| body ] value: actual ... value: actualN
	 to body with formals substituted for by actuals."
	| substitution substitutionDict newLabels |
	self assert: aTSendNode receiver isStmtList.
	self assert: aTSendNode receiver args size = aTSendNode args size.
	substitution := aTSendNode receiver copy.
	substitution renameLabelsForInliningInto: currentMethod.
	substitutionDict := Dictionary new: aTSendNode args size * 2.
	aTSendNode receiver args with: aTSendNode args do:
		[ :argName :exprNode |
		substitutionDict at: argName put: exprNode].
	substitution
		bindVariablesIn: substitutionDict;
		emitCCodeAsArgumentOn: aStream level: level generator: self.
	newLabels := Set withAll: currentMethod labels.
	substitution nodesDo:
		[:node| node isLabel ifTrue: [node label ifNotNil: [:label| newLabels add: label]]].
	"now add the new labels so that a subsequent inline of
	 the same block will be renamed with different labels."
	currentMethod labels: newLabels
]

{ #category : #'C translation' }
CCodeGenerator >> generateWhile: boolean loop: msgNode on: aStream indent: level [
	"Generate while(cond) {stmtList} or while(!(cond)) {stmtList}."

	aStream nextPutAll: 'while ('.
	boolean ifFalse: [aStream nextPutAll: '!('].
	self emitCTestBlock: msgNode receiver on: aStream indent: level.
	boolean ifFalse: [aStream nextPut: $)].
	aStream nextPutAll: ') {'; cr.
	msgNode args first isNilStmtListNode ifFalse:
		[msgNode args first emitCCodeOn: aStream level: level + 1 generator: self].
	aStream tab: level.
	aStream nextPut: $}
]

{ #category : #'C translation' }
CCodeGenerator >> generateWhileFalse: msgNode on: aStream indent: level [
	"Generate C code for a loop in one of the following formats, as appropriate:
		while(!(cond)) { stmtList }
		do {stmtList} while(!(cond))
		while(1) {stmtListA; if (cond) break; stmtListB}"

	msgNode receiver statements size <= 1
		ifTrue: [^self generateWhile: false loop: msgNode on: aStream indent: level].
	msgNode args first isNilStmtListNode
		ifTrue: [^self generateDoWhileFalse: msgNode on: aStream indent: level].
	^self generateWhileForeverBreakIf: true loop: msgNode on: aStream indent: level
]

{ #category : #'C translation' }
CCodeGenerator >> generateWhileForeverBreakIf: breakBoolean loop: msgNode on: aStream indent: level [
	"Generate either of
		while(1) {stmtListA; if(cond) break; stmtListB}
		while(1) {stmtListA; if(!(cond)) break; stmtListB}."

	| testStmt receiverWithoutTest |
	aStream peekLast ~~ Character tab ifTrue:
		[aStream tab: level - 1].
	aStream nextPutAll: 'while (1) {'; cr.
	testStmt := msgNode receiver statements last.
	receiverWithoutTest := TStmtListNode new setStatements: msgNode receiver statements allButLast.
	receiverWithoutTest emitCCodeOn: aStream level: level + 1 generator: self.
	aStream tab: level + 1; nextPutAll: 'if ('.
	breakBoolean ifFalse: [aStream nextPut: $!; nextPut: $(].
	testStmt emitCCodeAsExpressionOn: aStream level: level + 1 generator: self.
	breakBoolean ifFalse: [aStream nextPut: $)].
	aStream nextPutAll: ') break;'; cr.
	msgNode args first emitCCodeOn: aStream level: level + 1 generator: self.
	aStream tab: level; nextPut: $}
]

{ #category : #'C translation' }
CCodeGenerator >> generateWhileTrue: msgNode on: aStream indent: level [
	"Generate C code for a loop in one of the following formats, as appropriate:
		while(cond) { stmtList }
		do {stmtList} while(cond)
		while(1) {stmtListA; if (!(cond)) break; stmtListB}"

	msgNode receiver statements size <= 1
		ifTrue: [^self generateWhile: true loop: msgNode on: aStream indent: level].
	msgNode args first isNilStmtListNode
		ifTrue: [^self generateDoWhileTrue: msgNode on: aStream indent: level].
	^self generateWhileForeverBreakIf: false loop: msgNode on: aStream indent: level
]

{ #category : #public }
CCodeGenerator >> globalsAsSet [
	"Used by the inliner to avoid name clashes with global variables."

	^variables
]

{ #category : #'type inference' }
CCodeGenerator >> harmonizeReturnTypesIn: aSetOfTypes [
	"Eliminate signed/unsigned conflicts in aSetOfTypes. Non-negative integers can be either
	 signed or unsigned. Ignore them unless there are no types, in which case default to sqInt."
	| constantIntegers sqs usqs |
	constantIntegers := aSetOfTypes select: [:element| element isInteger].
	aSetOfTypes removeAll: constantIntegers.
	"N.B. Because of LP64 vs LLP64 issues do *not* rename #long to #sqInt or #'unsigned long' to #usqInt"
	#(char short int #'long long' #'unsigned char' #'unsigned short' #'unsigned int' #'unsigned long long')
		with: #(sqInt sqInt sqInt sqLong usqInt usqInt usqInt usqLong)
		do: [:type :replacement|
			(aSetOfTypes includes: type) ifTrue:
				[aSetOfTypes remove: type; add: replacement]].
	sqs := aSetOfTypes select: [:t| t beginsWith: 'sq'].
	usqs := aSetOfTypes select: [:t| t beginsWith: 'usq'].
	^(sqs size + usqs size = aSetOfTypes size
	   and: [sqs notEmpty
	   and: [sqs allSatisfy: [:t| usqs includes: 'u', t]]])
		ifTrue: [sqs]
		ifFalse: [(aSetOfTypes isEmpty and: [constantIntegers notEmpty])
					ifTrue: [Set with: #sqInt]
					ifFalse: [aSetOfTypes]]
]

{ #category : #public }
CCodeGenerator >> ifStaticallyResolvedPolymorphicReceiverThenUpdateSelectorIn: aSendNode [
	"We allow a limited amount of polymorphism; if a class chooses, its selectoers can be
	 prefixed with a given string to disambiguate. This hack allows us to use two different
	 compaction algorithms with the same API at the same time; the selection being done
	 by a class which holds the flag stating which algorithm is in effect at the current time."
	| class |
	staticallyResolvedPolymorphicReceivers ifNil: [^self].
	aSendNode receiver isVariable ifFalse:
		[^self].
	class := staticallyResolvedPolymorphicReceivers
				at: aSendNode receiver name
				ifAbsent: [^self].
	aSendNode selector: (class staticallyResolvePolymorphicSelector: aSendNode selector)
]

{ #category : #'type inference' }
CCodeGenerator >> implicitReturnTypeFor: aSelector [
	"Answer the default return type for mthods of the defining class of
	 aSelector. Default to #sqInt if there is no method, or if the method's
	 defining class doesn't understand implicitReturnTypeFor:."
	| m |
	m := methods at: aSelector ifAbsent: [^#sqInt].
	^[m definingClass implicitReturnTypeFor: aSelector]
		on: MessageNotUnderstood
		do: [:ex|
			ex message selector ~~ #implicitReturnTypeFor: ifTrue:
				[ex pass].
			#sqInt]
]

{ #category : #accessing }
CCodeGenerator >> includeAPIFrom: aCCodeGenerator [
	apiMethods := aCCodeGenerator selectAPIMethods.
	apiVariables := aCCodeGenerator selectAPIVariables
]

{ #category : #'type inference' }
CCodeGenerator >> inferTypesForImplicitlyTypedVariablesAndMethods [
	"Infer the return tupe and the types of untyped variables.
	 As far as variables go, for now we try only to infer variables
	 assigned the result of #longLongAt:, but much more could be
	 done here."

	"Iterate over all methods, inferring #void return types, until we reach a fixed point."
	| allMethods |
	allMethods := apiMethods
					ifNil: [methods]
					ifNotNil: [(Set withAll: methods)
								addAll: apiMethods;
								yourself].
	"Make an initial pass to assign the return types of all simple methods that return constants,
	 or those that have explicit return types."						
	allMethods do:
		[:m|
		m removeFinalSelfReturnIn: self. "must precede recordDeclarationsIn: because it may set returnType"
		m recordDeclarationsIn: self.
		(m returnType isNil
		 and: [m isReturnConstant]) ifTrue:
			[m inferReturnTypeIn: self]].

	"now iterate until we reach a fixed point"
	[| changedReturnType |
	 changedReturnType := false.
	 allMethods do:
		[:m|
		 m inferTypesForImplicitlyTypedVariablesIn: self.
		 (m inferReturnTypeIn: self) ifTrue:
			[changedReturnType := true]].
	 changedReturnType] whileTrue.

	"Type all as-yet-untyped methods as the default"
	methods do:
		[:m|
		m returnType ifNil:
			[m returnType: (m returnsExpression
								ifTrue: [#sqInt]
								ifFalse: [self implicitReturnTypeFor: m])].
		m transformReturns].

	"Make a final pass to type anything assigned from the default type"
	allMethods do:
		[:m|
		 m inferTypesForImplicitlyTypedVariablesIn: self]
]

{ #category : #'initialize-release' }
CCodeGenerator >> initialize [
	translationDict := Dictionary new.
	inlineList := Array new.
	constants := Dictionary new: 100.
	variables := Set new: 100.
	variableDeclarations := Dictionary new: 100.
	methods := Dictionary new: 500.
	kernelReturnTypes := self computeKernelReturnTypes.
	macros := Dictionary new.
	self initializeCTranslationDictionary.
	headerFiles := OrderedCollection new.
	globalVariableUsage := Dictionary new.
	useSymbolicConstants := true.
	generateDeadCode := true.
	scopeStack := OrderedCollection new.
	logger := (ProvideAnswerNotification new tag: #logger; signal) ifNil: [Transcript].
	pools := IdentitySet new.
	selectorTranslations := IdentityDictionary new.
	suppressAsmLabels := false.
	previousCommentMarksInlining := false.
	previousCommenter := nil.
	breakSrcInlineSelectors := IdentitySet new.
	breakDestInlineSelectors := IdentitySet new
]

{ #category : #'C translation support' }
CCodeGenerator >> initializeCTranslationDictionary [ 
	"Initialize the dictionary mapping message names to actions for C code generation."

	| pairs |
	
	translationDict := Dictionary new: 200.
	pairs := #(
	#&				#generateAnd:on:indent:
	#|				#generateOr:on:indent:
	#abs			#generateAbs:on:indent:
	#and:			#generateSequentialAnd:on:indent:
	#or:			#generateSequentialOr:on:indent:
	#not			#generateNot:on:indent:

	#+				#generatePlus:on:indent:
	#-				#generateMinus:on:indent:
	#negated		#generateNegated:on:indent:
	#*				#generateTimes:on:indent:
	#/				#generateDivide:on:indent:
	#//				#generateDivide:on:indent:
	#\\				#generateModulo:on:indent:
	#<<			#generateShiftLeft:on:indent:
	#>>			#generateShiftRight:on:indent:
	#>>>			#generateSignedShiftRight:on:indent:
	#min:			#generateMin:on:indent:
	#max:			#generateMax:on:indent:
	#between:and:	#generateBetweenAnd:on:indent:

	#bitAnd:			#generateBitAnd:on:indent:
	#bitOr:				#generateBitOr:on:indent:
	#bitXor:			#generateBitXor:on:indent:
	#bitShift:			#generateBitShift:on:indent:
	#signedBitShift:	#generateSignedBitShift:on:indent:
	#bitInvert32		#generateBitInvert:on:indent:
	#bitInvert64		#generateBitInvert:on:indent:
	#bitClear:			#generateBitClear:on:indent:
	#truncateTo:		#generateTruncateTo:on:indent:
	#rounded			#generateRounded:on:indent:

	#byteSwap32		#generateByteSwap32:on:indent:
	#byteSwap64		#generateByteSwap64:on:indent:
	#byteSwapped32IfBigEndian:	generateByteSwap32IfBigEndian:on:indent:
	#byteSwapped64IfBigEndian:	generateByteSwap64IfBigEndian:on:indent:
	
	#<				#generateLessThan:on:indent:
	#<=			#generateLessThanOrEqual:on:indent:
	#=				#generateEqual:on:indent:
	#>				#generateGreaterThan:on:indent:
	#>=			#generateGreaterThanOrEqual:on:indent:
	#~=			#generateNotEqual:on:indent:
	#==			#generateEqual:on:indent:
	#~~			#generateNotEqual:on:indent:
	#isNil			#generateIsNil:on:indent:
	#notNil			#generateNotNil:on:indent:

	#whileTrue: 	#generateWhileTrue:on:indent:
	#whileFalse:	#generateWhileFalse:on:indent:
	#whileTrue 	#generateDoWhileTrue:on:indent:
	#whileFalse		#generateDoWhileFalse:on:indent:
	#to:do:			#generateToDo:on:indent:
	#to:by:do:		#generateToByDo:on:indent:
	#repeat 		#generateRepeat:on:indent:
	#timesRepeat:	#generateTimesRepeat:on:indent:

	#ifTrue:			#generateIfTrue:on:indent:
	#ifFalse:		#generateIfFalse:on:indent:
	#ifTrue:ifFalse:	#generateIfTrueIfFalse:on:indent:
	#ifFalse:ifTrue:	#generateIfFalseIfTrue:on:indent:

	#ifNotNil:		#generateIfNotNil:on:indent:
	#ifNil:			#generateIfNil:on:indent:
	#ifNotNil:ifNil:	#generateIfNotNilIfNil:on:indent:
	#ifNil:ifNotNil:	#generateIfNilIfNotNil:on:indent:

	#at:				#generateAt:on:indent:
	#at:put:			#generateAtPut:on:indent:
	#basicAt:		#generateAt:on:indent:
	#basicAt:put:	#generateAtPut:on:indent:

	#integerValueOf:			#generateIntegerValueOf:on:indent:
	#integerObjectOf:			#generateIntegerObjectOf:on:indent:
	#isIntegerObject: 			#generateIsIntegerObject:on:indent:
	#cCode:					#generateInlineCCode:on:indent:
	#cCode:inSmalltalk:			#generateInlineCCode:on:indent:
	#cPreprocessorDirective:	#generateInlineCPreprocessorDirective:on:indent:
	#cppIf:ifTrue:ifFalse:		#generateInlineCppIfElse:on:indent:
	#cppIf:ifTrue:				#generateInlineCppIfElse:on:indent:
	#cCoerce:to:				#generateCCoercion:on:indent:
	#cCoerceSimple:to:			#generateCCoercion:on:indent:
	#addressOf:				#generateAddressOf:on:indent:
	#addressOf:put:			#generateAddressOf:on:indent:
	#asAddress:put:			#generateAsAddress:on:indent:
	#signedIntFromLong64		#generateSignedIntFromLong64:on:indent:
	#signedIntFromLong		#generateSignedIntFromLong:on:indent:
	#signedIntFromShort		#generateSignedIntFromShort:on:indent:
	#signedIntToLong64		#generateSignedIntToLong64:on:indent:
	#signedIntToLong			#generateSignedIntToLong:on:indent:
	#signedIntToShort			#generateSignedIntToShort:on:indent:
	#preIncrement				#generatePreIncrement:on:indent:
	#preDecrement			#generatePreDecrement:on:indent:
	#inline:						#generateInlineDirective:on:indent:
	#asFloat					#generateAsFloat:on:indent:
	#asInteger					#generateAsInteger:on:indent:
	#asIntegerPtr				#generateAsIntegerPtr:on:indent:
	#asUnsignedInteger		#generateAsUnsignedInteger:on:indent:
	#asUnsignedIntegerPtr		#generateAsUnsignedIntegerPtr:on:indent:
	#asLong					#generateAsLong:on:indent:
	#asUnsignedLong			#generateAsUnsignedLong:on:indent:
	#asUnsignedLongLong		#generateAsUnsignedLongLong:on:indent:
	#asVoidPointer				#generateAsVoidPointer:on:indent:
	#asSymbol					#generateAsSymbol:on:indent:
	#flag:						#generateFlag:on:indent:
	#anyMask:					#generateBitAnd:on:indent:
	#allMask:					#generateAllMask:on:indent:
	#noMask:					#generateNoMask:on:indent:
	#raisedTo:					#generateRaisedTo:on:indent:
	#touch:						#generateTouch:on:indent:

	#bytesPerOop 				#generateBytesPerOop:on:indent:
	#bytesPerWord 			#generateBytesPerWord:on:indent:
	#wordSize		 			#generateBytesPerWord:on:indent:
	#baseHeaderSize			#generateBaseHeaderSize:on:indent:
	#minSmallInteger			#generateSmallIntegerConstant:on:indent:
	#maxSmallInteger			#generateSmallIntegerConstant:on:indent:
	
	#sharedCodeNamed:inCase:		#generateSharedCodeDirective:on:indent:

	#perform:							#generatePerform:on:indent:
	#perform:with:						#generatePerform:on:indent:
	#perform:with:with:					#generatePerform:on:indent:
	#perform:with:with:with:				#generatePerform:on:indent:
	#perform:with:with:with:with:		#generatePerform:on:indent:
	#perform:with:with:with:with:with:	#generatePerform:on:indent:

	#value								#generateValue:on:indent:
	#value:								#generateValue:on:indent:
	#value:value:						#generateValue:on:indent:
	#value:value:value:					#generateValue:on:indent:
	#value:value:value:value:			#generateValue:on:indent:
	#value:value:value:value:value:			#generateValue:on:indent:
	#value:value:value:value:value:value:	#generateValue:on:indent:

	#deny:								#generateDeny:on:indent:

	#shouldNotImplement				#generateSmalltalkMetaError:on:indent:
	#shouldBeImplemented			#generateSmalltalkMetaError:on:indent:
	#subclassResponsibility			#generateSmalltalkMetaError:on:indent:
	).

	1 to: pairs size by: 2 do: [:i |
		translationDict at: (pairs at: i) put: (pairs at: i + 1)].

	pairs := #(
	#ifTrue:					#generateIfTrueAsArgument:on:indent:	
	#ifFalse:				#generateIfFalseAsArgument:on:indent:
	#ifTrue:ifFalse:			#generateIfTrueIfFalseAsArgument:on:indent:
	#ifFalse:ifTrue:			#generateIfFalseIfTrueAsArgument:on:indent:
	#ifNotNil:				#generateIfNotNilAsArgument:on:indent:	
	#ifNil:					#generateIfNilAsArgument:on:indent:
	#ifNotNil:ifNil:			#generateIfNotNilIfNilAsArgument:on:indent:
	#ifNil:ifNotNil:			#generateIfNilIfNotNilAsArgument:on:indent:
	#cCode:				#generateInlineCCodeAsArgument:on:indent:
	#cCode:inSmalltalk:		#generateInlineCCodeAsArgument:on:indent:
	#cppIf:ifTrue:ifFalse:	#generateInlineCppIfElseAsArgument:on:indent:
	#cppIf:ifTrue:			#generateInlineCppIfElseAsArgument:on:indent:

	#value					#generateValueAsArgument:on:indent:
	#value:					#generateValueAsArgument:on:indent:
	#value:value:			#generateValueAsArgument:on:indent:
	).

	asArgumentTranslationDict := Dictionary new: 8.
	1 to: pairs size by: 2 do: [:i |
		asArgumentTranslationDict at: (pairs at: i) put: (pairs at: i + 1)].

]

{ #category : #inlining }
CCodeGenerator >> initializerForInstVar: varName in: aClass [
	| instVarIndex |
	instVarIndex := aClass instVarIndexFor: varName ifAbsent: [^nil].
	aClass selectorsAndMethodsDo:
		[:s :m| | tmeth |
		((s beginsWith: 'initialize')
		 and: [m writesField: instVarIndex]) ifTrue:
			[tmeth := m asTranslationMethodOfClass: TMethod.
			 tmeth parseTree nodesDo:
				[:node| | exprOrAssignment |
				(node isAssignment
				 and: [node variable name = varName]) ifTrue:
					[exprOrAssignment := node.
					 [exprOrAssignment isAssignment] whileTrue:
						[exprOrAssignment := exprOrAssignment expression].
					 ^exprOrAssignment]]]].
	^nil
]

{ #category : #inlining }
CCodeGenerator >> initializerForInstVar: varName inStartClass: aClass [
	| allClasses sizeBefore |
	(aClass inheritsFrom: VMClass) ifFalse:
		[^false].
	allClasses := (aClass withAllSuperclasses copyUpTo: VMClass) asSet.
	[sizeBefore := allClasses size.
	 allClasses copy do:
		[:class|
		class ancilliaryClasses do:
			[:ancilliary|
			allClasses addAll: (ancilliary withAllSuperclasses copyUpTo: VMClass)]].
	 sizeBefore ~= allClasses size] whileTrue.
	allClasses do:
		[:class|
		(self initializerForInstVar: varName in: class) ifNotNil:
			[:initializer| ^initializer]].
	^nil
]

{ #category : #inlining }
CCodeGenerator >> inlineDispatchesInMethodNamed: selector localizingVars: varsList [
	"Inline dispatches (case statements) in the method with the given name."

	| m |
	m := self methodNamed: selector.
	m = nil ifFalse: [
		m inlineCaseStatementBranchesIn: self localizingVars: varsList.
		m parseTree nodesDo: [ :n |
			n isCaseStmt ifTrue: [
				n customizeShortCasesForDispatchVar: 'currentBytecode' in: self method: m.
			].
		].
	].
	varsList do: [ :v | | varString |
		varString := v asString.
		self checkDeleteVariable: varString.
		variables remove: varString ifAbsent: [].
		(variableDeclarations includesKey: varString) ifTrue: [
			m declarationAt: v asString put: (variableDeclarations at: varString).
			variableDeclarations removeKey: varString.
		].
	]
]

{ #category : #utilities }
CCodeGenerator >> instVarNamesForClass: aClass [
	^vmClass
		ifNil: [aClass instVarNames]
		ifNotNil: [aClass instVarNames reject:
					[:ivn| vmClass isNonArgumentImplicitReceiverVariableName: ivn]]
]

{ #category : #accessing }
CCodeGenerator >> interpreterVersion [
	^self vmClass interpreterVersion, '[', self vmClass objectMemoryClass memoryManagerVersion, ']'
]

{ #category : #'C translation support' }
CCodeGenerator >> is64BitIntegralVariable: node typeInto: aBlock [
	| decl |
	^node isVariable
	  and: [(decl := self typeOfVariable: node name) notNil
	  and: [(#('usqLong' 'sqLong' 'unsigned long long' 'long long' 'unsigned __int64' '__int64')
			anySatisfy: [:type| decl beginsWith: type])
	  and: [aBlock value: ((decl endsWith: node name)
							ifTrue: [decl allButLast: node name size + 1]
							ifFalse: [decl]).
			true]]]
]

{ #category : #inlining }
CCodeGenerator >> isActualType: actualTypeOrNil compatibleWithFormalType: formalTypeOrNil [ 
	| actualType formalType |
	actualType := actualTypeOrNil ifNil: [#sqInt].
	formalType := formalTypeOrNil ifNil: [#sqInt].
	((self isIntegralCType: actualType)
	 and: [self isIntegralCType: formalType]) ifFalse:
		[^actualType = formalType
		 or: [formalType = #double and: [actualType = #float]]].
	"For now, insist that the signedness agrees.  If the actual's type is unknown allow inlining.
	 A formal defaults to #sqInt. Allowing inlining an unsigned type within a sqInt formal is wrong;
	 snd for testing, it breaks e.g. the BitBltPlugin."
	^(actualType first = $u) = (formalType first = $u)
	  or: [actualTypeOrNil isNil] 
]

{ #category : #inlining }
CCodeGenerator >> isAssertSelector: selector [
	^#(assert: asserta: assert:l: asserta:l: deny: eassert:) includes: selector
]

{ #category : #utilities }
CCodeGenerator >> isBuiltinSelector: sel [
	"Answer true if the given selector is one of the builtin selectors."

	^(self isKernelSelector: sel) or: [translationDict includesKey: sel]
]

{ #category : #'C code generator' }
CCodeGenerator >> isCLiteral: anObject [
	anObject isInteger ifTrue: [^true].
	anObject isString ifTrue: [^true].
	anObject isFloat ifTrue: [^true].
	anObject == nil ifTrue: [^true].
	anObject == true ifTrue: [^true].			"ikp"
	anObject == false ifTrue: [^true].			"ikp"
	anObject isCharacter ifTrue:[^true]. "ar"
	^false
]

{ #category : #utilities }
CCodeGenerator >> isConstantNode: aNode valueInto: aBlock [
	"Answer if aNode evaluates to a constant, and if so, evaluate aBlock with the value of that constant."

	aNode isConstant ifTrue:
		[(aNode isDefine
		  and: [(vmClass ifNil: [VMBasicConstants]) defineAtCompileTime: aNode name]) ifTrue:
			[^false].
		 aBlock value: aNode value.
		 ^true].
	(aNode isVariable
	 and: [aNode name = #nil]) ifTrue:
		[aBlock value: nil.
		 ^true].
	aNode isSend ifTrue:
		[(self anyMethodNamed: aNode selector)
			ifNil:
				[(VMBasicConstants valueOfBasicSelector: aNode selector) ifNotNil:
					[:value|
					 aBlock value: value.
					 ^true].
				 aNode constantNumbericValueOrNil ifNotNil:
					[:value|
					 aBlock value: value.
					 ^true]]
			ifNotNil:
				[:m|
				(m statements size = 1
				 and: [m statements last isReturn]) ifTrue:
					[^self isConstantNode: m statements last expression valueInto: aBlock]]].
	^false
]

{ #category : #inlining }
CCodeGenerator >> isFloatingPointCType: aCType [ "<String>"
	^#('float' 'double' 'long double') includes: aCType asString
]

{ #category : #'type inference' }
CCodeGenerator >> isFunctionalCType: aType [
	"Answer if aType is either a function or a pointer to a function."
	^aType last == $) and: [(aType indexOf: $() > 0]
]

{ #category : #utilities }
CCodeGenerator >> isGeneratingPluginCode [
	^false
]

{ #category : #public }
CCodeGenerator >> isGlobalStructureBuild [
	^false
]

{ #category : #inlining }
CCodeGenerator >> isIntegralCType: aCType [ "<String>"
	^(#('sqLong' 'usqLong' 'sqInt' 'usqInt' 'sqIntptr_t' 'usqIntptr_t'
		'long' 'long long' 'int' 'short' 'short int' 'char' 'signed char'
		'size_t' 'pid_t') includes: aCType asString)
	or: [(aCType beginsWith: 'unsigned') "Accept e.g. 'unsigned long' and also 'unsigned  : 8'"
		and: [(aCType includesAnyOf: '[*]') not]]
]

{ #category : #utilities }
CCodeGenerator >> isKernelSelector: sel [
	"Answer true if the given selector is one of the kernel selectors that are implemented as macros."

	^(#(error:
		 oopAt: oopAt:put: oopAtPointer: oopAtPointer:put:
		 byteAt: byteAt:put: byteAtPointer: byteAtPointer:put:
		 shortAt: shortAt:put: shortAtPointer: shortAtPointer:put:
		 intAt: intAt:put: intAtPointer: intAtPointer:put:
		 longAt: longAt:put: longAtPointer: longAtPointer:put:
		 long32At: long32At:put: long64At: long64At:put:
		 fetchFloatAt:into: storeFloatAt:from: fetchFloatAtPointer:into: storeFloatAtPointer:from:
		 fetchSingleFloatAt:into: storeSingleFloatAt:from: fetchSingleFloatAtPointer:into: storeSingleFloatAtPointer:from:
		 pointerForOop: oopForPointer:
		 cCoerce:to: cCoerceSimple:to:)
			includes: sel)
]

{ #category : #utilities }
CCodeGenerator >> isNilConstantReceiverOf: sendNode [
	"Answer true if the receiver of the given message send is the constant nil. Used to suppress conditional code when the condition is a translation-time constant."

	| val |
	generateDeadCode ifTrue: [^false].
	^(self isConstantNode: sendNode receiver valueInto: [:v| val := v])
	  and: [val isNil]
]

{ #category : #'type inference' }
CCodeGenerator >> isNode: aNode constantValueWithinRangeOfType: aType [
	"Answer if aNode is a constant value within the range of an integral type.
	 If aNode isn't an integral constant or aType isn't an integral type then answer false."
	| value |
	^aNode expression isConstant
	  and: [(self isIntegralCType: aType)
	  and: [(value := aNode expression value) isInteger
	  and: [value positive
	  and: [(aType first = $u
			ifTrue: [value digitLength]
			ifFalse: [value highBit + 7 // 8]) <= (self sizeOfIntegralCType: aType)]]]]
]

{ #category : #'C code generator' }
CCodeGenerator >> isNonArgumentImplicitReceiverVariableName: aString [
	^(self typeOfVariable: aString) == #implicit
	    or: [vmClass
			ifNil: [#('interpreterProxy' 'self') includes: aString]
	 		ifNotNil: [vmClass isNonArgumentImplicitReceiverVariableName: aString]]
]

{ #category : #'spur primitive compilation' }
CCodeGenerator >> isObjectAccessor: selector given: interpreterClass [
	^interpreterClass isObjectAccessor: selector
]

{ #category : #'type inference' }
CCodeGenerator >> isPointerCType: aType [
	^aType last == $*
]

{ #category : #inlining }
CCodeGenerator >> isQuickCompiledMethod: aCompiledMethod [
	^aCompiledMethod isQuick
	 or: [(#(pushConstant: pushLiteralVariable:) includes: (aCompiledMethod abstractBytecodeMessageAt: aCompiledMethod initialPC) selector)
		and: [(aCompiledMethod abstractBytecodeMessageAt: (InstructionStream on: aCompiledMethod) followingPc) selector == #methodReturnTop]]
]

{ #category : #'type inference' }
CCodeGenerator >> isSimpleType: aType [
	"For the purposes of the read-before-written initializer, answer if
	 aType is simple, e.g. not a structure, and array or an opaque type."
	^(self isPointerCType: aType)
	  or: [self isIntegralCType: aType]
]

{ #category : #inlining }
CCodeGenerator >> isSpecialSelector: aSelector [
		
	^ translationDict includesKey: aSelector
]

{ #category : #'spur primitive compilation' }
CCodeGenerator >> isStackAccessor: selector given: interpreterClass [
	^interpreterClass isStackAccessor: selector
]

{ #category : #utilities }
CCodeGenerator >> isStructSend: aTSendNode [
	"Answer if the argument aTSendNode is a send of a structure accessor.
	 This is tricky.  We want
		foo bar => foo->bar
		foo bar => foo.bar
		foo bar: expr => foo->bar = expr
		foo bar: expr => foo.bar = expr
	 depending on whether foo is a struct or a pointer to a struct,
	 but only if both foo is a struct type and bar is a field accessor.
	 The tricky cases are self-sends within struct class methods.  Here we need to
	 distinguish between self-sends of ordinary methods from self sends of accessors."
	^aTSendNode numArgs <= 1
	   and: [(aTSendNode receiver structTargetKindIn: self) notNil
	   and: [(self methodNamed: aTSendNode selector)
				ifNil: [false]
				ifNotNil: [:method| method isStructAccessor]]]
]

{ #category : #inlining }
CCodeGenerator >> isVoidPointer: aCType [ "<String>"
	"sigh..."
	^#('void *' 'void*') includes: aCType asString
]

{ #category : #utilities }
CCodeGenerator >> localizeGlobalVariables [
	| candidates elected localized |

	"find all globals used in only one method"
	candidates := globalVariableUsage select: [:e | e size = 1].
	"Don't localize globals; nor those that are only assigned to; they're for debugging..."
	(candidates keys select: [:k| (vmClass mustBeGlobal: k)
								or: [(self methodNamed: (globalVariableUsage at: k) anyOne)
										ifNil: [false]
										ifNotNil: [:m| (m readsVariable: k) not]]]) do:
		[:k| candidates removeKey: k].
	
	elected := Set new.
	localized := Dictionary new. "for an ordered report"
	"move any suitable global to be local to the single method using it"
	candidates keysAndValuesDo:
		[:key :targets |
		targets do:
			[:name |
			(methods at: name ifAbsent: []) ifNotNil:
				[:procedure | | newDeclaration |
				(procedure isRealMethod
				 and: [self shouldGenerateMethod: procedure]) ifTrue:
					[(localized at: name ifAbsentPut: [SortedCollection new]) add: key.
					elected add: (procedure locals add: key).
					newDeclaration := variableDeclarations at: key ifAbsent: ['sqInt ', key].
					(self initializerForInstVar: key inStartClass: procedure definingClass) ifNotNil:
						[:initializerNode|
						newDeclaration := String streamContents:
												[:s|
												 s nextPutAll: newDeclaration; nextPutAll: ' = '.
												 initializerNode emitCCodeOn: s level: 0 generator: self]].
					procedure declarationAt: key put: newDeclaration.
					variableDeclarations removeKey: key ifAbsent: []]]]].
	logger ifNotNil:
		[localized keys asSortedCollection do:
			[:name|
			(localized at: name) do:
				[:var|
				logger ensureCr; show: var, ' localised to ', name; cr]]].
	elected do: [:ea| (variables includes: ea) ifTrue: [self checkDeleteVariable: ea]].
	variables removeAllFoundIn: elected
]

{ #category : #utilities }
CCodeGenerator >> logger [
	^logger
]

{ #category : #utilities }
CCodeGenerator >> logger: aTranscriptStream [
	logger := aTranscriptStream
]

{ #category : #inlining }
CCodeGenerator >> mayInline: sel [
	"Answer if the method with the given selector may be inlined."

	^(self isAssertSelector: sel) not and: [inlineList includes: sel]
]

{ #category : #inlining }
CCodeGenerator >> maybeBreakForInlineOf: aNode in: aTMethod [
	"convenient for debugging..."
	(aNode isSend
	and: [breakSrcInlineSelectors size + breakDestInlineSelectors size > 0
	and: [(breakSrcInlineSelectors isEmpty or: [breakSrcInlineSelectors includes: aNode selector])
	and: [(breakDestInlineSelectors isEmpty or: [(breakDestInlineSelectors includes: aTMethod selector)])
	and: [breakOnInline ~~ false]]]]) ifTrue:
		[aTMethod halt: aTMethod selector, ' ', aNode selector]
]

{ #category : #inlining }
CCodeGenerator >> maybeBreakForTestOfInliningOf: aNodeOrSelector [
	"convenient for debugging..."
	| selector |
	selector := aNodeOrSelector isSymbol
					ifTrue: [aNodeOrSelector]
					ifFalse:
						[aNodeOrSelector isSend
							ifTrue: [aNodeOrSelector selector]
							ifFalse: [^self]].
	((breakSrcInlineSelectors includes: selector)
	 and: [breakDestInlineSelectors isEmpty
	 and: [breakOnInline == true]]) ifTrue:
		[self halt: selector]
]

{ #category : #inlining }
CCodeGenerator >> maybeBreakForTestToInline: aNodeOrSelector in: aTMethod [
	"convenient for debugging..."
	| selector |
	selector := aNodeOrSelector isSymbol
					ifTrue: [aNodeOrSelector]
					ifFalse:
						[aNodeOrSelector isSend
							ifTrue: [aNodeOrSelector selector]
							ifFalse: [^self]].
	(breakSrcInlineSelectors size + breakDestInlineSelectors size > 0
	and: [(breakSrcInlineSelectors isEmpty or: [breakSrcInlineSelectors includes: selector])
	and: [(breakDestInlineSelectors isEmpty or: [(breakDestInlineSelectors includes: aTMethod selector)])
	and: [breakOnInline ~~ true]]]) ifTrue:
		[aTMethod halt: aTMethod selector, ' ', selector]
]

{ #category : #'C translation support' }
CCodeGenerator >> maybeEmitPrimitiveFailureDefineFor: selector on: aStream [
	 (vmClass notNil
	 and: [(vmClass inheritsFrom: InterpreterPrimitives)
	 and: [(vmClass primitiveTable includes: selector)]]) ifTrue:
		[aStream nextPutAll: '#else\# define ' withCRs; nextPutAll: selector; nextPutAll: ' (void (*)(void))0\' withCRs]
]

{ #category : #'C code generator' }
CCodeGenerator >> maybePutPreambleFor: aClass on: aStream [
	aClass preambleCCode ifNotNil:
		[:preamble| | actualClass |
		 actualClass := aClass class whichClassIncludesSelector: #preambleCCode.
		 aStream
			ensureCr; cr;
			nextPutAll: '/* '; print: actualClass; nextPutAll: '>>preambleCCode */'; cr;
			nextPutAll: preamble; cr;
			nextPutAll: '/* end '; print: actualClass; nextPutAll: '>>preambleCCode */'; cr]
]

{ #category : #'type inference' }
CCodeGenerator >> mergeTypeOf: var in: aDictionary with: newType method: tMethod [
	"var is a variable that has been assigned an expression of type  newType.
	 Either assign its type, if it is as yet untyped, or merge newType with its existing type.
	 N.B. We refuse to promote a variable that already has integral type to a floating point
	 type.  The existing plugins depend on this; one can always use an explicit type in future."
	| existingType mergedType |
	existingType := self
						extractTypeFor: var
						fromDeclaration: (aDictionary at: var ifAbsentPut: [newType, ' ', var]).
	existingType ~= newType ifTrue:
		[((self isPointerCType: existingType)
		  or: [self isPointerCType: newType])
			ifTrue:
				[existingType = #'void *' ifTrue: [^newType].
				 newType = #'void *' ifTrue: [^existingType].
				 self logger show: 'conflicting types ', existingType, ' ', newType, ' for ', var, ' in ', tMethod selector.
				 ^existingType]
			ifFalse:
				[((self isIntegralCType: existingType)
				  and: [self isFloatingPointCType: newType]) ifFalse:
					[mergedType := self promoteArithmeticTypes: existingType and: newType.
					 aDictionary at: var put: mergedType, ' ', var]]]
]

{ #category : #utilities }
CCodeGenerator >> messageReceiverIsInterpreterProxy: sendNode [
	^self isGeneratingPluginCode
	  and: [sendNode receiver isVariable
	  and: ['interpreterProxy' = sendNode receiver name
	  and: [(self isKernelSelector: sendNode selector) not]]]
]

{ #category : #utilities }
CCodeGenerator >> methodNamed: selector [
	"Answer the method in the code base with the given selector."

	^ methods at: selector ifAbsent: [ nil ]
]

{ #category : #inlining }
CCodeGenerator >> methodStatsString [
	"Return a string describing the size, # of locals, and # of senders of
	 each method. Note methods that have inline C code or C declarations."

	| methodsWithCCode sizesOf callsOf s |
	methodsWithCCode := Set new: methods size.
	sizesOf := Dictionary new: methods size * 2.  "selector -> nodeCount"
	callsOf := Dictionary new: methods size * 2.  "selector -> senderCount"

	"For each method, scan its parse tree once to:
		1. determine if the method contains C code or declarations
		2. determine how many nodes it has
		3. increment the sender counts of the methods it calls
		4. determine if it includes any C declarations or code"

	methods do: [ :m | | hasCCode nodeCount |
		(translationDict includesKey: m selector) ifTrue: [
			hasCCode := true.
		] ifFalse: [
			hasCCode := m declarations size > 0.
			nodeCount := 0.
			m parseTree nodesDo: [ :node | | selr senderCount |
				node isSend ifTrue: [
					selr := node selector.
					node isNonNullCCode ifTrue: [ hasCCode := true ].
					senderCount := callsOf at: selr ifAbsent: [ 0 ].
					callsOf at: selr put: senderCount + 1.
				].
				nodeCount := nodeCount + 1.
			].
		].
		hasCCode ifTrue: [ methodsWithCCode add: m selector ].
		sizesOf at: m selector put: nodeCount.
	].

	s := WriteStream on: (String new: 5000).
	(self sortStrings: methods keys) do: [ :sel | | m calls registers |
		m := methods at: sel.
		registers := m locals size + m args size.
		calls := callsOf at: sel ifAbsent: [0].
		registers > 11 ifTrue: [
			s nextPutAll: sel; tab.
			s nextPutAll: (sizesOf at: sel) printString; tab.
			s nextPutAll: calls printString; tab.
			s nextPutAll: registers printString; tab.
			(methodsWithCCode includes: sel) ifTrue: [ s nextPutAll: 'CCode' ].
		s cr.
		].
	].
	^ s contents
]

{ #category : #utilities }
CCodeGenerator >> methodsForDefiningClass: dc [
	"Answer a collection of methods that refer to the given global variable."

	^methods select: [:tMethod| tMethod definingClass == dc]
]

{ #category : #utilities }
CCodeGenerator >> methodsReferringToGlobal: v [
	"Return a collection of methods that refer to the given global variable."

	| out |
	out := OrderedCollection new.
	methods associationsDo: [ :assoc |
		(assoc value freeVariableReferences includes: v) ifTrue: [
			out add: assoc key.
		].
	].
	^ out
]

{ #category : #utilities }
CCodeGenerator >> methodsThatCanInvoke: aSelectorList [
	"Return a set of methods that can invoke one of the given selectors, either directly or via a sequence of intermediate methods."

	| out todo sel |
	out := Set new.
	todo := aSelectorList copy asOrderedCollection.
	[todo isEmpty] whileFalse: [
		sel := todo removeFirst.
		out add: sel.
		methods do: [ :m | | mSelector |
			(m allCalls includes: sel) ifTrue: [
				mSelector := m selector.
				((out includes: mSelector) or:
				 [todo includes: mSelector]) ifFalse: [
					todo add: mSelector.
				].
			].
		].
	].
	^ out
	
]

{ #category : #'C code generator' }
CCodeGenerator >> needToGenerateHeader: headerName file: interpHdrPath contents: newContentsArg [
	"Check if we need to regenerate a header file.  We always need to if the contents have changed.
	 But if not we can avoid needless recompilations by not regenerating.  So only regenerate if the
	 package stamp is dirty and the monticello stamp is clean."
	| newContents oldContents dirtyStamp |
	(FileDirectory default fileExists: interpHdrPath) ifFalse:
		[^true].
	newContents := newContentsArg.
	oldContents := (FileDirectory default oldFileNamed: interpHdrPath) contentsOfEntireFile.
	oldContents := oldContents copyReplaceAll: {Character cr. Character lf} with: {Character cr}.
	oldContents replaceAll: Character lf with: Character cr.
	dirtyStamp := (oldContents indexOfSubCollection: '* VMMaker') ~= 0.
	(newContents beginsWith: '/*') = (oldContents beginsWith: '/*') ifFalse:
		[(newContents beginsWith: '/*') ifTrue:
			[newContents := newContents readStream upToAll: '*/'; skipSeparators; upToEnd].
		 (oldContents beginsWith: '/*') ifTrue:
			[oldContents := oldContents readStream upToAll: '*/'; skipSeparators; upToEnd]].
	^oldContents ~= newContents
	 or: [(dirtyStamp and: [[((self class monticelloDescriptionFor: vmClass) includes: $*) not]
							on: Error do: [:ex| false]]) "If no stamp don't worry"
	 or: [self confirm: headerName, ' contents are unchanged.\Writing the file may cause recompilation of support files.\Do you want to write the header file?' withCRs]]
]

{ #category : #utilities }
CCodeGenerator >> nilOrBooleanConditionFor: nodeOrNil [
	"If nodeOrNil is one of the conditional sends for which we do translation-time dead code elimination
	 (i.e. cppIf:ifTrue: et al or ifTrue: et al) and the conditional does evaluate to a translation-time
	 boolean constant, answer that constant, otherwise answer nil.  Used to prune dead code,
	 either for code generaton or dead variable elimination."
	generateDeadCode ifTrue: [^nil].
	nodeOrNil ifNil:
		[^nil].
	nodeOrNil isSend ifFalse:
		[^nil].
	(#(ifTrue: ifFalse: ifTrue:ifFalse: ifFalse:ifTrue:) includes: nodeOrNil selector) ifTrue:
		[^self nilOrBooleanConstantReceiverOf: nodeOrNil receiver].
	(#(and: or:) includes: nodeOrNil selector) ifTrue:
		[^self nilOrBooleanConstantReceiverOf: nodeOrNil].
	(#(cppIf:ifTrue: cppIf:ifTrue:ifFalse:) includes: nodeOrNil selector) ifTrue:
		[| maybeName value |
		(vmClass notNil
		 and: [nodeOrNil args first isConstant
		 and: [(value := nodeOrNil args first value) isSymbol
		 and: [((vmClass ifNil: [VMBasicConstants]) defineAtCompileTime: value) not
		 and: [(vmClass bindingOf: value) notNil]]]]) ifTrue:
			[self logger
					nextPutAll: 'Warning: cppIf: reference to ';
					store: value;
					nextPutAll: ' when variable of same name exists.'; cr].

		maybeName := nodeOrNil args first isConstant ifTrue:
							[nodeOrNil args first nameOrValue].
		 ^(optionsDictionary notNil
		   and: [nodeOrNil args first isConstant
		   and: [(#(true false) includes: (optionsDictionary at: maybeName ifAbsent: [nil]))
		   and: [((vmClass ifNil: [VMBasicConstants]) defineAtCompileTime: maybeName) not]]]) ifTrue:
			[optionsDictionary at: nodeOrNil args first name]].
	^nil
]

{ #category : #utilities }
CCodeGenerator >> nilOrBooleanConstantReceiverOf: aNode [
	"Answer nil or the boolean constant that is the receiver of the given message send.
	 Used to suppress conditional code when the condition is a translation-time constant."

	| val receiver argument arms |
	generateDeadCode ifTrue:[^nil].
	((self isConstantNode: aNode valueInto: [:v| val := v])
	 and: [#(true false) includes: val]) ifTrue:
		[^val].
	aNode isSend ifTrue:
		[aNode selector == #not ifTrue:
			[(self nilOrBooleanConstantReceiverOf: aNode receiver) ifNotNil:
				[:bool| ^bool not]].
		 ((#(isNil notNil) includes: aNode selector)
		  and: [self isNilConstantReceiverOf: aNode]) ifTrue:
			[^aNode selector == #isNil].
		 ((#(or: and:) includes: aNode selector)
		 and: [aNode args last isStmtList
		 and: [aNode args last statements size = 1]]) ifTrue:
			[(self nilOrBooleanConstantReceiverOf: aNode receiver) ifNotNil:
				[:rcvr|
				((rcvr == false and: [aNode selector == #and:])
				 or: [rcvr == true and: [aNode selector == #or:]]) ifTrue:
					[^rcvr].
				(self nilOrBooleanConstantReceiverOf: aNode args last statements first) ifNotNil:
					[:arg|
					^rcvr perform: aNode selector with: [arg]]].
			 "We can also eliminate expr and: [false], expr or: [true], but only if expr is side-effect free.
			  This is a weak test; we don't traverse calls.  Caveat emptor!"
			 ((aNode receiver noneSatisfy: [:node| node isAssignment]) "No side-effects in the elided expression"
			  and: [aNode args last statements size = 1]) ifTrue:
				[(self nilOrBooleanConstantReceiverOf: aNode args last statements first) ifNotNil:
					[:arg|
					((arg == false and: [aNode selector == #and:])
					 or: [arg == true and: [aNode selector == #or:]]) ifTrue:
						[^arg]]]].
		"Look for Const ifTrue: [self foo] ifFalse: [false] => false"
		 ((#(ifTrue:ifFalse: ifFalse:ifTrue:) includes: aNode selector)
		  and: [(self isConstantNode: aNode receiver valueInto: [:v| val := v])
		  and: [(#(true false) includes: val)
		  and: [arms := aNode args collect:
							[:altBlock| | bval |
							 (altBlock statements size = 1
							 and: [(self isConstantNode: altBlock statements last valueInto: [:v| bval := v])
							 and: [#(true false) includes: bval]]) ifTrue:
								[bval]].
				arms asArray ~= #(nil nil)]]]) ifTrue:
			[| arm |
			 arm := aNode selector == #ifTrue:ifFalse: == val
						ifTrue: [arms first]
						ifFalse: [arms last].
			 (#(true false) includes: arm) ifTrue:
				[^arm]].
		 ((#(= ~= < > <= >=) includes: aNode selector)
		  and: [(self isConstantNode: aNode receiver valueInto: [:v| receiver := v])
		  and: [receiver isInteger
		  and: [(self isConstantNode: aNode args first valueInto: [:v| argument := v])
		  and: [argument isInteger]]]]) ifTrue:
			[^receiver perform: aNode selector with: argument].
		 "Inlining for e.g. CharacterTable ifNil: [...] ifNotNil: [...]], which compiles to CharacterTable == nil ifTrue: [...] ifFalse: [...]"
		(aNode selector == #==
		 and: [aNode args first isVariable
		 and: [aNode args first name = 'nil'
		 and: [aNode receiver isConstant
		 and: [aNode receiver value == nil]]]]) ifTrue:
			[^true]].
	^nil
]

{ #category : #inlining }
CCodeGenerator >> node: exprNode typeCompatibleWith: argName inliningInto: targetMethod in: aTMethod [
	"Answer either exprNode or, if required, a cast of exprNode to the type of argName.
	 The cast is required if
		- argName is typed and exprNode is untyped
		- argName is untyped and exprNode is an arithmetic type of size > #sqInt
		- both argName and exprNode are typed but they are incompatible"
	| formalType actualType |
	formalType := targetMethod typeFor: argName in: self.
	actualType := self typeFor: exprNode in: aTMethod.
	^((exprNode isSend or: [exprNode isVariable])
	   and: [(formalType notNil and: [actualType isNil])
			or: [(formalType isNil and: [actualType notNil and: [(self isIntegralCType: actualType) and: [(self sizeOfIntegralCType: actualType) > (self sizeOfIntegralCType: #sqInt)]]])
			or: [(self variableOfType: formalType acceptsValue: exprNode ofType: actualType) not]]])
		ifTrue: [self nodeToCast: exprNode to: (formalType ifNil: [#sqInt])]
		ifFalse:
			[((exprNode isSend or: [exprNode isVariable])
			  and: [(self
					variableOfType: (targetMethod typeFor: argName in: self)
					acceptsValue: exprNode
					ofType: (self typeFor: exprNode in: aTMethod)) not]) ifTrue:
				[logger
					nextPutAll:
						'type mismatch for formal ', argName, ' and actual "', exprNode asString,
						'" when inlining ', targetMethod selector, ' in ', aTMethod selector, '. Use a cast.';
					cr; flush]. 
			exprNode]
]

{ #category : #utilities }
CCodeGenerator >> nodeIsDeadCode: aNode withParent: parentNode [
	"Answer if aNode would not be generated due to dead code elimination."
	^(self nilOrBooleanConditionFor: parentNode)
		ifNil: [false]
		ifNotNil:
			[:cond| | filter |
			filter := parentNode selector caseOf:
							{   "First element is accessor for filtered (eliminated) node if expression is true.
								Second element is accessor for filtered (eliminated) node if expression is false."
								[#ifFalse:]				-> [#(first nil)].
								[#ifFalse:ifTrue:] 		-> [#(first last)].
								[#ifTrue:]				-> [#(nil first)].
								[#ifTrue:ifFalse:]			-> [#(last first)].
								[#and:]					-> [#(nil first)].
								[#or:]					-> [#(last nil)].
								[#cppIf:ifTrue:]			-> [#(nil #second)].
								[#cppIf:ifTrue:ifFalse:]	-> [#(third #second)] }.
			(cond ifTrue: [filter first] ifFalse: [filter last])
				ifNil: [false]
				ifNotNil: [:accessor| aNode == (parentNode args perform: accessor)]]
]

{ #category : #inlining }
CCodeGenerator >> nodeToCast: exprNode to: cType [
	^TSendNode new
		setSelector: #cCoerceSimple:to:
		receiver: (TVariableNode new setName: 'self')
		arguments: { exprNode. TConstantNode new setValue: cType }
		isBuiltInOp: true
]

{ #category : #utilities }
CCodeGenerator >> nonStructClassesForTranslationClasses: classes [
	"Answer in superclass order (any superclass precedes any subclass)
	 the ancilliaryClasses that are not struct classes for all the given classes."
	| nonStructClasses |
	nonStructClasses := OrderedCollection new.
	classes do:
		[:aTranslationClass|
		([aTranslationClass ancilliaryClasses]
				on: MessageNotUnderstood
				do: [:ex|
					ex message selector == #ancilliaryClasses
						ifTrue: [#()]
						ifFalse: [ex pass]]) do:
			[:class|
			(vmClass isNil or: [vmClass isAcceptableAncilliaryClass: class]) ifTrue:
				[(class isStructClass
				 or: [(nonStructClasses includes: class)
				 or: [classes includes: class]]) ifFalse:
					[nonStructClasses addLast: class]]]].
	^self superclassOrder: nonStructClasses
]

{ #category : #utilities }
CCodeGenerator >> noteUsedVariableName: variableName [
	currentMethod ifNotNil:
		[:m| m noteUsedVariableName: variableName]
]

{ #category : #utilities }
CCodeGenerator >> noteVariableUsageInString: aString [
	currentMethod ifNotNil:
		[:m|
		 (Scanner new typedScanTokens: aString) do:
			[:token|
			 (token isString and: [token first isLetter or: [token first == $_]]) ifTrue:
				[m noteUsedVariableName: token]]]
]

{ #category : #utilities }
CCodeGenerator >> optionIsTrue: pragma in: aClass [
	"Answer whether an option: or notOption: pragma is true in the context of aClass.
	 The argument to the option: pragma is interpreted as either a Cogit class name
	 or a class variable name or a variable name in VMBasicConstants."
	| key |
	key := pragma argumentAt: 1.

	"If the option is one to be defined at compile time we'll generate a
	 conditional around its declaration and definition."
	((vmClass ifNil: [VMBasicConstants]) defineAtCompileTime: key) ifTrue:
		[^true].

	"If the option is the name of a subclass of Cogit, include it if it inherits from the Cogit class."
	(Smalltalk classNamed: key) ifNotNil:
		[:optionClass|
		 aClass cogitClass ifNotNil:
			[:cogitClass|
			 (optionClass includesBehavior: Cogit) ifTrue:
				[^cogitClass includesBehavior: optionClass]].
		 aClass objectMemoryClass ifNotNil:
			[:objectMemoryClass|
			 ((optionClass includesBehavior: ObjectMemory)
			   or: [optionClass includesBehavior: SpurMemoryManager]) ifTrue:
				[^objectMemoryClass includesBehavior: optionClass]]].
	"Lookup options in options, class variables of the defining class, VMBasicConstants, the interpreterClass and the objectMemoryClass"
	{aClass initializationOptions.
	  aClass.
	  VMBasicConstants.
	  aClass interpreterClass.
	  aClass objectMemoryClass} do:
		[:scopeOrNil|
		 scopeOrNil ifNotNil:
			[:scope|
			 (scope bindingOf: key) ifNotNil:
				[:binding|
				binding value ~~ false ifTrue: [^true]]]].
	^false
]

{ #category : #accessing }
CCodeGenerator >> options [
	^optionsDictionary
]

{ #category : #accessing }
CCodeGenerator >> options: aDictionary [
	"Set optionsDictionary to the argument and scan it for accessors on the receiver,
	 performing the accessor with the value, allowing one to specify things like
	 generateDeadCode: false in the options."
	optionsDictionary := aDictionary.
	optionsDictionary keysAndValuesDo:
		[:k :v| | accessor |
		((self class instVarNames includes: k)
		and: [(Symbol hasInterned: k, ':' ifTrue: [:s| accessor := s])
		and: [self class canUnderstand: accessor]]) ifTrue:
			[self perform: accessor with: v]]
]

{ #category : #utilities }
CCodeGenerator >> outputAsmLabel: selector on: aStream [
	| count |
	suppressAsmLabels ifTrue: [^self].
	asmLabelCounts ifNil:
		[asmLabelCounts := Dictionary new].
	count := asmLabelCounts
				at: selector
				put: 1 + (asmLabelCounts at: selector ifAbsent: [-1]).
	 aStream
		nextPutAll: 'VM_LABEL(';
		nextPutAll: (self cFunctionNameFor: selector);
		nextPutAll: (count = 0 ifTrue: [''] ifFalse: [count printString]);
		nextPut: $);
		nextPut: $;
]

{ #category : #'C code generator' }
CCodeGenerator >> preDeclareInterpreterProxyOn: aStream [
	"Put the necessary #defines needed before interpreterProxy.  Basically
	 internal plugins use the VM's interpreterProxy variable and external plugins use
	 their own.  In addition the VMPluginCodeGenerator can choose to keep local copies
	 all functions."
	aStream cr; nextPutAll: '#ifdef SQUEAK_BUILTIN_PLUGIN'.
	aStream cr; nextPutAll: 'extern'.
	aStream cr; nextPutAll: '#endif'; cr
]

{ #category : #utilities }
CCodeGenerator >> prepareMethods [
	| globals |
	globals := Set new: 200.
	globals addAll: variables.
	methods do:
		[:m |
		m locals, m args do:
			[:var |
			(globals includes: var) ifTrue:
				[self error: 'Local variable ''', var, ''' may mask global when inlining ', m selector].
			((methods at: var ifAbsent: [nil]) ifNil: [false] ifNotNil: [:m1| m1 isStructAccessor not]) ifTrue:
				[logger
					ensureCr;
					nextPutAll: 'Local variable name ''', var, ''' in ';
					nextPutAll: m selector;
					nextPutAll: ' may mask method when inlining';
					cr]].
		m bindClassVariablesIn: constants.
		m prepareMethodIn: self]
]

{ #category : #accessing }
CCodeGenerator >> previousCommentMarksInlining [
	^previousCommentMarksInlining
]

{ #category : #accessing }
CCodeGenerator >> previousCommentMarksInlining: aBoolean [
	| previousValue |
	previousValue := previousCommentMarksInlining.
	previousCommentMarksInlining := aBoolean.
	^previousValue
]

{ #category : #accessing }
CCodeGenerator >> previousCommenter [
	^previousCommenter
]

{ #category : #accessing }
CCodeGenerator >> previousCommenter: aTParseNodeOrNil [
	| previousValue |
	previousValue := previousCommenter.
	previousCommenter := aTParseNodeOrNil.
	^previousValue
]

{ #category : #'error notification' }
CCodeGenerator >> printUnboundCallWarnings [
	"Print a warning message for every unbound method call in the code base."

	| knownSelectors undefinedCalls |
	undefinedCalls := Dictionary new.
	knownSelectors := translationDict keys asSet.
	knownSelectors add: #error:.
	methods do: [ :m | knownSelectors add: m selector ].
	methods do: [ :m |
		m allCalls do: [ :sel |
			(knownSelectors includes: sel) ifFalse: [
				(undefinedCalls includesKey: sel)
					ifTrue: [ (undefinedCalls at: sel) add: m selector ]
					ifFalse: [ undefinedCalls at: sel put: (OrderedCollection with: m selector) ].
			].
		].
	].

	logger cr.
	(self sortStrings: undefinedCalls keys) do: [ :undefined |
		logger show: undefined, ' -- undefined method sent by:'; cr.
		(undefinedCalls at: undefined) do: [ :caller |
			logger tab; show: caller; cr.
		].
	].
]

{ #category : #'error notification' }
CCodeGenerator >> printUnboundVariableReferenceWarnings [
	"Print a warning message for every unbound variable reference in the code base."

	| undefinedRefs globalVars |
	undefinedRefs := Dictionary new.
	globalVars := Set new: 100.
	globalVars addAll: variables.
	methods do: [ :m | | knownVars |
		knownVars := globalVars copy.
		m args do: [ :var | knownVars add: var ].
		m locals do: [ :var | knownVars add: var ].
		m freeVariableReferences do: [ :varName |
			(knownVars includes: varName) ifFalse: [
				(undefinedRefs includesKey: varName)
					ifTrue: [ (undefinedRefs at: varName) add: m selector ]
					ifFalse: [ undefinedRefs at: varName put: (OrderedCollection with: m selector) ].
			].
		].
	].

	logger cr.
	(self sortStrings: undefinedRefs keys) do: [ :var |
		logger show: var, ' -- undefined variable used in:'; cr.
		(undefinedRefs at: var) do: [ :sel |
			logger tab; show: sel; cr.
		].
	].
]

{ #category : #'type inference' }
CCodeGenerator >> promoteArithmeticTypes: firstType and: secondType [
	"Answer the return type for an arithmetic send.  This is so that the inliner can still inline
	 simple expressions.  Deal with pointer arithmetic, floating point arithmetic and promotion.
	 It is important to choose deterministically to get stable source generation.
	 Also, the behaviour of inlined and non inlined code should be unchanged."
	((#(#double float) includes: firstType)
	 or: [#(#double float) includes: secondType]) ifTrue:
		[^(firstType = #double or: [secondType = #double])
			ifTrue: [#double]
			ifFalse: [#float] "in C99 6.3.1.8, float+int, int is converted as a float"].
	"deal with unknowns, answering nil."
	(firstType isNil or: [secondType isNil]) ifTrue:
		[^nil].
	"Deal with integer promotion and arithmetic conversion"
	^self promoteIntegerArithmeticTypes: firstType and: secondType
]

{ #category : #'type inference' }
CCodeGenerator >> promoteIntegerArithmeticTypes: firstType and: secondType [
	"Answer the return type for an arithmetic send.
	Deal with integer promotion rules of C99.
	See section 6.3 Conversions of the standard.
	
	6.3.1.1 ...snip...
		If an int can represent all values of the original type, the value is converted to an int;
		otherwise, it is converted to an unsigned int. These are called the integer promotions.
		All other types are unchanged by the integer promotions

	6.3.1.8 ...snip...
		Otherwise, the integer promotions are performed on both operands
		Then the following rules are applied to the promoted operands:

			If both operands have the same type, then no further conversion is needed.

			Otherwise, if both operands have signed integer types or both have unsigned integer
			types, the operand with the type of lesser integer conversion rank is converted to the
			type of the operand with greater rank.

			Otherwise, if the operand that has unsigned integer type has rank greater or equal to
			the rank of the type of the other operand, then the operand with signed integer type
			is converted to the type of the operand with unsigned integer type.

			Otherwise, if the type of the operand with signed integer type can represent all of the
			values of the type of the operand with unsigned integer type, then the operand with
			unsigned integer type is converted to the type of the operand with signed integer type.

			Otherwise, both operands are converted to the unsigned integer type corresponding to
			the type of the operand with signed integer type.

	This is so that the generated code behaviour is insensitive to inlining."
	| length1 length2 intSize |
	length1 := self sizeOfIntegralCType: firstType.
	length2 := self sizeOfIntegralCType: secondType.
	intSize := self sizeOfIntegralCType: #int.
	(length1 < intSize and: [length2 < intSize]) ifTrue: [^#int].	"Integer promotion"
	length1 > length2 ifTrue: [^firstType].
	length2 > length1 ifTrue: [^secondType].
	firstType first = $u ifTrue: [^firstType].
	secondType first = $u ifTrue: [^secondType].
	^firstType
]

{ #category : #inlining }
CCodeGenerator >> pruneMethods: selectorList [
	"Explicitly prune some methods"
	selectorList do: [:sel| self removeMethodForSelector: sel]
]

{ #category : #inlining }
CCodeGenerator >> pruneUnreachableMethods [
	"Remove any methods that are not reachable. Retain methods needed by the translated classes - see implementors of requiredMethodNames"
 	
	| neededSelectors newMethods previousSize visited |
	"add all the exported methods and all the called methods to the requiredSelectors"
	"keep all the fake methods (macros and struct accessors; these are needed
	 to ensure correct code generation."

	neededSelectors := Set withAll: requiredSelectors.
	methods do: [ :m |
		m export ifTrue:
			[neededSelectors add: m selector].
		m isAPIMethod ifTrue:
			[neededSelectors add: m selector].
		m isRealMethod ifFalse:
			[neededSelectors add: m selector]].

	"Now compute the transitive closure..."
	previousSize := neededSelectors size.
	visited := IdentitySet new: methods size.
	[neededSelectors do:
		[:s|
		(methods at: s ifAbsent: []) ifNotNil:
			[:m|
			(visited includes: m) ifFalse:
				[visited add: m.
				 (m isRealMethod
				  and: [self shouldGenerateMethod: m]) ifTrue:
					[neededSelectors addAll: m allCalls]]]].
	 neededSelectors size > previousSize]
		whileTrue:
			[previousSize := neededSelectors size].

	"build a new dictionary of methods from the collection of all the ones to keep"			
	newMethods := Dictionary new: neededSelectors size.
	neededSelectors do:
		[:sel|
		methods at: sel ifPresent: [:meth| newMethods at: sel put: meth]].
	methods := newMethods
]

{ #category : #'C code generator' }
CCodeGenerator >> pushScope: variableToType "<Dictionary>" while: aBlock [
	scopeStack addLast: variableToType.
	^aBlock ensure: [scopeStack removeLast]
]

{ #category : #'C code generator' }
CCodeGenerator >> putConditionalDefineOf: aConstantNameString as: valueOrValueString comment: commentOrNil on: aStream [
	self withConditionalDefineOf: aConstantNameString
		comment: commentOrNil
		on: aStream
		do: [| valueAsString |
			 valueAsString := valueOrValueString asString.
			 valueAsString first ~= $# ifTrue:
				[aStream nextPutAll: '# define '; nextPutAll: aConstantNameString; space].
			 aStream nextPutAll: valueAsString; cr]
]

{ #category : #'C code generator' }
CCodeGenerator >> putDefineOf: aConstantNameString as: valueOrValueString on: aStream [
	aStream
		nextPutAll: '#define ';
		nextPutAll: aConstantNameString;
		space;
		nextPutAll: valueOrValueString asString;
		cr
]

{ #category : #inlining }
CCodeGenerator >> removeAssertions [
	"Remove all assertions in method bodies.  This is for the benefit of inlining, which
	fails to recognise and disregard empty method bodies when checking the inlinability
	of sends."

	| newMethods |
	newMethods := Dictionary new.
	'Removing assertions...'
		displayProgressAt: Sensor cursorPoint
		from: 0 to: methods size
		during: [ :bar |
			methods doWithIndex: [ :m :i |
				bar value: i.
				m isAssertion ifFalse: [
					newMethods at: m selector put: m.
					m removeAssertions]]].
	methods := newMethods.
]

{ #category : #utilities }
CCodeGenerator >> removeConstant: aName [
	"Remove the given (class) variable from the code base."

	constants removeKey:  aName ifAbsent: []
]

{ #category : #utilities }
CCodeGenerator >> removeMethodForSelector: aSelector [
	"Remove the given method from the code base"
	((breakSrcInlineSelectors includes: aSelector)
	 or: [(breakDestInlineSelectors includes: aSelector)]) ifTrue:
		[self halt].
	methods removeKey:  aSelector ifAbsent: []
]

{ #category : #inlining }
CCodeGenerator >> removeMethodsReferingToGlobals: varList except: methodName [
	"Remove any methods (presumably inlined) that still contain references to the given
	 global variables. Answer a Dictionary of the removed methods for later reporting."

	| varListAsStrings removed |
	varListAsStrings := varList collect: [ :sym | sym asString ].
	removed := Dictionary new: methods size / 2.
	methods copy keysAndValuesDo:
		[ :sel :meth| | mVars |
		sel ~= methodName ifTrue:
			[mVars := meth freeVariableReferences asSet.
			 (varListAsStrings anySatisfy: [ :v | mVars includes: v]) ifTrue:
				[removed at: sel put: meth.
				self removeMethodForSelector: sel]]].

	^removed
]

{ #category : #utilities }
CCodeGenerator >> removeVariable: aName [
	"Remove the given (instance) variable from the code base."
	self removeVariable: aName
		ifAbsent:
			[(vmClass notNil
			  and: [vmClass isNonArgumentImplicitReceiverVariableName: aName]) ifFalse:
				[logger
					ensureCr;
					show: 'warning, variable '
						, aName
						, ' doesn''t exist or has already been removed';
						cr]]
]

{ #category : #utilities }
CCodeGenerator >> removeVariable: aName ifAbsent: ifAbsentBlock [
	"Remove the given (instance) variable from the code base."
	self checkDeleteVariable: aName.
	variableDeclarations removeKey: aName ifAbsent: [].
	^variables remove: aName ifAbsent: ifAbsentBlock
]

{ #category : #utilities }
CCodeGenerator >> reportRecursiveMethods [
	"Report in transcript all methods that can call themselves directly or indirectly or via a chain of N intermediate methods."

	methods do: [: m | | visited calls newCalls sel called |
		visited := translationDict keys asSet.
		calls := m allCalls asOrderedCollection.
		5 timesRepeat: [
			newCalls := Set new: 50.
			[calls isEmpty] whileFalse: [
				sel := calls removeFirst.
				sel = m selector ifTrue: [
					logger ensureCr; show: m selector, ' is recursive'; cr.
				] ifFalse: [
					(visited includes: sel) ifFalse: [
						called := self methodNamed: sel.
						called = nil ifFalse: [ newCalls addAll: called allCalls ].
					].
					visited add: sel.
				].
			].
			calls := newCalls asOrderedCollection.
		].
	].
]

{ #category : #inlining }
CCodeGenerator >> reportShouldNotBeRemoved: removed varList: varList [
	"Report whether any of the removed methods are still used."
	| varListAsStrings shouldNotBeRemoved |
	varListAsStrings := varList collect: [ :sym | sym asString ].
	shouldNotBeRemoved := Set new.
	removed do:
		[:m|
		m isAPIMethod ifTrue:
			[shouldNotBeRemoved add: m selector]].
	methods do:
		[:m|
		(m selector = #interpret
		 or: [removed includes: m selector]) ifFalse:
			[m allCalls do:
				[:sel|
				(removed includesKey: sel) ifTrue:
					[shouldNotBeRemoved add: sel]]]].
	vmClass additionalSelectorTables do:
		[:selectorTable|
		 selectorTable do:
			[:selOrInteger|
			selOrInteger isInteger ifFalse:
				[(removed includesKey: selOrInteger) ifTrue:
					[shouldNotBeRemoved add: selOrInteger]]]].
	shouldNotBeRemoved do:
		[:sel| | str |
		str := String streamContents:
				[:strm| | them |
				strm
					nextPutAll: 'Removed ';
					nextPutAll: sel;
					nextPutAll: ' because it refers to the local variable'.
				them := (removed at: sel) freeVariableReferences asSet intersection: varListAsStrings.
				them size > 1 ifTrue:
					[strm nextPut: $s.
					 them := self sortStrings: them].
				them do: [:var| strm space; nextPutAll: var].

				strm
					nextPutAll: ' of interpret.';
					cr;
					nextPutAll: 'But it is either used outside of interpret or exported!!';
					cr].
		logger ensureCr; show: str.
		self inform: str]
]

{ #category : #'C translation support' }
CCodeGenerator >> reservedWords [
	^#(	'auto'
		'break'
		'case' 'char' 'const' 'continue'
		'default' 'do' 'double'
		'else' "'entry' obsolete" 'enum' 'extern'
		'float' 'for'
		'goto'
		'if' 'int'
		'long'
		'register' 'return'
		'short' 'signed' 'sizeof' 'static' 'struct' 'switch'
		'typedef'
		'union' 'unsigned'
		'void' 'volatile'
		'while')
]

{ #category : #inlining }
CCodeGenerator >> retainMethods: aListOfSelectorsToKeep [
	"add aListOfSelectorsToKeep to requiredSelectors so that they will not be pruned"
	requiredSelectors ifNil:[requiredSelectors := Set new:100].
	requiredSelectors addAll: aListOfSelectorsToKeep.
	^aListOfSelectorsToKeep
]

{ #category : #utilities }
CCodeGenerator >> returnPrefixFromVariable: aName [
	^aName
]

{ #category : #'type inference' }
CCodeGenerator >> returnTypeForSend: sendNode in: aTMethod ifNil: typeIfNil [
	"Answer the return type for a send.  Unbound sends default to typeIfNil.
	 Methods with types as yet unknown have a type determined either by the
	 kernelReturnTypes or the table below, or, if they are in neither set, then nil.
	 The inferred type should match as closely as possible the C type of
	 generated expessions so that inlining would not change the expression.
	 If there is a method for sel but its return type is as yet unknown it mustn't
	 be defaulted, since on a subsequent pass its type may be computable."
	| sel methodOrNil |
	methodOrNil := self anyMethodNamed: (sel := sendNode selector).
	(methodOrNil notNil and: [methodOrNil returnType notNil]) ifTrue:
		[^self baseTypeForType: methodOrNil returnType].
	^kernelReturnTypes
		at: sel
		ifAbsent:
			[sel
				caseOf: {
				[#integerValueOf:]		->	[#sqInt].
				[#isIntegerObject:]		->	[#int].
				[#negated]				->	[self promoteArithmeticTypes: (sendNode receiver typeFrom: self in: aTMethod) and: #int].
				[#+]					->	[self typeForArithmetic: sendNode in: aTMethod].
				[#-]						->	[self typeForArithmetic: sendNode in: aTMethod].
				[#*]					->	[self typeForArithmetic: sendNode in: aTMethod].
				[#/]						->	[self typeForArithmetic: sendNode in: aTMethod].
				[#//]					->	[self typeForArithmetic: sendNode in: aTMethod].
				[#\\]					->	[self typeForArithmetic: sendNode in: aTMethod].
				[#rem:]					->	[self typeForArithmetic: sendNode in: aTMethod].
				[#quo:]					->	[self typeForArithmetic: sendNode in: aTMethod].
				"C99 Sec Bitwise shift operators ... 3 Sematics ...
				 The integer promotions are performed on each of the operands. The type of the result is that of the promoted left operand..."
				[#>>]					->	[sendNode receiver typeFrom: self in: aTMethod].
				[#<<]					->	[sendNode receiver typeFrom: self in: aTMethod].
				[#addressOf:]			->	[(sendNode receiver typeFrom: self in: aTMethod)
												ifNil: [#sqInt]
												ifNotNil: [:type| type, (type last isLetter ifTrue: [' *'] ifFalse: ['*'])]].
				[#at:]					->	[self typeForDereference: sendNode in: aTMethod].
				[#bitAnd:]				->	[self typeForArithmetic: sendNode in: aTMethod].
				[#bitOr:]				->	[self typeForArithmetic: sendNode in: aTMethod].
				[#bitXor:]				->	[self typeForArithmetic: sendNode in: aTMethod].
				[#bitClear:]				->	[self typeForArithmetic: sendNode in: aTMethod].
				[#bitInvert32]			->	[#'unsigned int'].
				[#bitInvert64]			->	[self promoteArithmeticTypes: (sendNode receiver typeFrom: self in: aTMethod) and: #int].
				[#byteSwap32]			->	[#'unsigned int'].
				[#byteSwap64]			->	[#'unsigned long long'].
				[#byteSwapped32IfBigEndian:]	->	[#'unsigned int'].
				[#byteSwapped64IfBigEndian:]	->	[#'unsigned long long'].
				[#=]					->	[#int].
				[#~=]					->	[#int].
				[#==]					->	[#int].
				[#~~]					->	[#int].
				[#<]					->	[#int].
				[#<=]					->	[#int].
				[#>]					->	[#int].
				[#>=]					->	[#int].
				[#between:and:]		->	[#int].
				[#anyMask:]				->	[#int].
				[#allMask:]				->	[#int].
				[#noMask:]				->	[#int].
				[#isNil]					->	[#int].
				[#notNil]				->	[#int].
				[#&]					->	[#int].
				[#|]						->	[#int].
				[#not]					->	[#int].
				[#asFloat]				->	[#double].
				[#atan]					->	[#double].
				[#exp]					->	[#double].
				[#log]					->	[#double].
				[#sin]					->	[#double].
				[#sqrt]					->	[#double].
				[#asLong]				->	[#long].
				[#asInteger]			->	[#sqInt].
				[#asIntegerPtr]			->	[#'sqIntptr_t'].
				[#asUnsignedInteger]	->	[#usqInt].
				[#asUnsignedIntegerPtr]->	[#'usqIntptr_t'].
				[#asUnsignedLong]		->	[#'unsigned long'].
				[#asUnsignedLongLong]		->	[#'unsigned long long'].
				[#asVoidPointer]		->	[#'void *'].
				[#signedIntToLong]		->	[#usqInt]. "c.f. generateSignedIntToLong:on:indent:"
				[#signedIntToShort]	->	[#usqInt]. "c.f. generateSignedIntToShort:on:indent:"
				[#cCoerce:to:]			->	[self conventionalTypeForType: sendNode args last value].
				[#cCoerceSimple:to:]	->	[self conventionalTypeForType: sendNode args last value].
				[#sizeof:]				->	[#'usqIntptr_t']. "Technically it's a size_t but it matches on target architectures so far..."
				[#ifTrue:ifFalse:]		->	[self typeForConditional: sendNode in: aTMethod].
				[#ifFalse:ifTrue:]		->	[self typeForConditional: sendNode in: aTMethod].
				[#ifTrue:]				->	[self typeForConditional: sendNode in: aTMethod].
				[#ifFalse:]				->	[self typeForConditional: sendNode in: aTMethod].
				[#and:]					->	[#sqInt].
				[#or:]					->	[#sqInt].
				[#caseOf:]				->	[self typeFor: sendNode args first in: aTMethod] }
				otherwise: "If there /is/ a method for sel but its return type is as yet unknown it /mustn't/ be defaulted,
							since on a subsequent pass its type may be computable.  Only default unbound selectors."
					[methodOrNil ifNotNil: [nil] ifNil: [typeIfNil]]]
]

{ #category : #accessing }
CCodeGenerator >> selectAPIMethods [
	^methods select: [:m| m isAPIMethod]
]

{ #category : #accessing }
CCodeGenerator >> selectAPIVariables [
	^variableDeclarations reject: [:decl| decl includesSubstring: 'static ']
]

{ #category : #'C code generator' }
CCodeGenerator >> selectorReturnsPointerToStruct: selector [ "<Symbol>"
	| tMethod |
	^(tMethod := methods
					at: selector
					ifAbsent:
						[apiMethods ifNotNil:
							[apiMethods at: selector ifAbsent: []]]) notNil
	  and: [VMStructType isTypePointerToStruct: tMethod returnType]
]

{ #category : #'C code generator' }
CCodeGenerator >> selectorReturnsStruct: selector [ "<Symbol>"
	| tMethod |
	^(tMethod := methods
					at: selector
					ifAbsent:
						[apiMethods ifNotNil:
							[apiMethods at: selector ifAbsent: []]]) notNil
	  and: [VMStructType isTypeStruct: tMethod returnType]
]

{ #category : #utilities }
CCodeGenerator >> selectorsAndMethodsDo: aBinaryBlock [
	methods keysAndValuesDo: aBinaryBlock
]

{ #category : #'C code generator' }
CCodeGenerator >> shortMonticelloDescriptionForClass: aClass [
	"Answer a suitable Monticello package stamp to include in a moduleName."
	^self class shortMonticelloDescriptionForClass: aClass
]

{ #category : #utilities }
CCodeGenerator >> shouldGenerateAsInterpreterProxySend: aSendNode [
	^(self messageReceiverIsInterpreterProxy: aSendNode)
	  and: [(VMBasicConstants mostBasicConstantSelectors includes: aSendNode selector) not]
]

{ #category : #utilities }
CCodeGenerator >> shouldGenerateMethod: aTMethod [
	^(self isBuiltinSelector: aTMethod selector)
		ifTrue: [requiredSelectors includes: aTMethod selector]
		ifFalse: [aTMethod inline ~~ #always]
]

{ #category : #utilities }
CCodeGenerator >> shouldIncludeMethodFor: aClass selector: selector [
	"Answer whether a method shoud be translated.  Process optional methods by
	 interpreting the argument to the option: pragma as either a Cogit class name
	 or a class variable name or a variable name in VMBasicConstants.  Exclude
	 methods with the doNotGenerate pragma."
	| optionPragmas notOptionPragmas |
	(aClass >> selector pragmaAt: #doNotGenerate) ifNotNil:
		[^false].

	"where is pragmasAt: ??"
	optionPragmas := (aClass >> selector) pragmas select: [:p| p keyword == #option:].
	notOptionPragmas := (aClass >> selector) pragmas select: [:p| p keyword == #notOption:].
	(optionPragmas notEmpty or: [notOptionPragmas notEmpty]) ifTrue:
		[^(optionPragmas allSatisfy: [:pragma| self optionIsTrue: pragma in: aClass])
		   and: [notOptionPragmas noneSatisfy: [:pragma| self optionIsTrue: pragma in: aClass]]].

	^true
]

{ #category : #'type inference' }
CCodeGenerator >> signedTypeForIntegralType: aCTypeString [
	(aCTypeString beginsWith: 'unsigned ') ifTrue:
		[^aCTypeString allButFirst: 8].
	
	(aCTypeString beginsWith: 'usq') ifTrue:
		[^aCTypeString allButFirst].

	aCTypeString = 'size_t' ifTrue: [^#usqIntptr_t].
	
	self error: 'unknown type'.
	^#long
]

{ #category : #inlining }
CCodeGenerator >> sizeOfIntegralCType: anIntegralCType [ "<String>"
	"N.B. Only works for values for which isIntegralCType: answers true."
	| prunedCType index |
	(anIntegralCType beginsWith: 'register ') ifTrue:
		[^self sizeOfIntegralCType: (anIntegralCType allButFirst: 9)].
	prunedCType := (anIntegralCType beginsWith: 'unsigned ')
						ifTrue: [(anIntegralCType allButFirst: 9) withBlanksTrimmed]
						ifFalse: [(anIntegralCType beginsWith: 'signed ')
									ifTrue: [(anIntegralCType allButFirst: 7) withBlanksTrimmed]
									ifFalse: [anIntegralCType]].
	
	^prunedCType asString caseOf: {
		['sqLong']	->	[8].
		['usqLong']	->	[8].
		['long long']	->	[8].
		['sqInt']		->	[BytesPerOop].
		['usqInt']	->	[BytesPerOop].
		['sqIntptr_t']	->	[BytesPerWord].
		['usqIntptr_t']	->	[BytesPerWord].
		['int']		->	[4].
		['short']		->	[2].
		['short int']	->	[2].
		['char']		->	[1].
		['long']		->	[BytesPerWord]. "It's ambiguous on LLP64 and we'll later remove it"
		['size_t']	->	[BytesPerWord].
		['pid_t']		->	[BytesPerWord].
	}
	otherwise:
		[((anIntegralCType beginsWith: 'unsigned') "e.g. 'unsigned  : 8'"
		  and: [(anIntegralCType includesAnyOf: '[*]') not
		  and: [(index := anIntegralCType indexOf: $:) > 0]])
			ifTrue: [(Integer readFrom: (anIntegralCType copyFrom: index + 1 to: anIntegralCType size) withBlanksTrimmed readStream) + 7 // 8]
			ifFalse: [self error: 'unrecognized integral type']]
]

{ #category : #utilities }
CCodeGenerator >> sortMethods: aTMethodCollection [
	"We need to define this since different Squeak versions answer different results
	 for asSortedCollection and if sort order changes, generated code changes too.
	 When generating VM code, use class name as major sort index as this groups
	 some methods by functionality (e.g. SpurGenerationScavenger) and that makes
	 the VMProfiler more useful."
	^aTMethodCollection asSortedCollection:
		(self isGeneratingPluginCode
			ifTrue:
				[[:a :b| a selector caseSensitiveLessOrEqual: b selector]]
			ifFalse:
				[[:a :b|
				  a definingClass = b definingClass
					ifTrue: [a selector caseSensitiveLessOrEqual: b selector]
					ifFalse: [a definingClass name caseSensitiveLessOrEqual: b definingClass name]]])
]

{ #category : #utilities }
CCodeGenerator >> sortStrings: aStringOrSymbolCollection [
	"We need to define this since different Squeak versions answer different results
	 for asSortedCollection and if sort order changes, generated code changes too."
	^aStringOrSymbolCollection asSortedCollection: [:a :b| a caseSensitiveLessOrEqual: b]
]

{ #category : #public }
CCodeGenerator >> sortedExportMethods [
	"Answer a suitably-sorted array of all exported TMethods"
	^(methods select: [:m| m export]) asSortedCollection: [:a :b| a selector caseSensitiveLessOrEqual: b selector]
]

{ #category : #public }
CCodeGenerator >> staticallyResolveMethodNamed: selector forClass: aClass to: staticallyResolvedSelector [
	"We allow a limited amount of polymorphism; if a class chooses, its selectoers can be
	 prefixed with a given string to disambiguate. This hack allows us to use two different
	 compaction algorithms with the same API at the same time; the selection being done
	 by a class which holds the flag stating which algorithm is in effect at the current time."
	| method |
	method := methods
					removeKey: selector
					ifAbsent:
						[self logger cr; nextPutAll: 'warning: did not find ', selector, ' to be able to map to ', staticallyResolvedSelector.
						^self].
	method selector: staticallyResolvedSelector.
	methods at: staticallyResolvedSelector put: method
]

{ #category : #public }
CCodeGenerator >> staticallyResolvedPolymorphicReceiver: variableName to: aClass [
	"We allow a limited amount of polymorphism; if a class chooses, its selectoers can be
	 prefixed with a given string to disambiguate. This hack allows us to use two different
	 compaction algorithms with the same API at the same time; the selection being done
	 by a class which holds the flag stating which algorithm is in effect at the current time."
	(staticallyResolvedPolymorphicReceivers ifNil: [staticallyResolvedPolymorphicReceivers := Dictionary new])
		at: variableName
		put: aClass
]

{ #category : #'C translation support' }
CCodeGenerator >> stepExpressionIsNegative: aNode [
	"Answer if the step expression (the by: argument in a to:by:do:) is negative."
	self isConstantNode: aNode valueInto: [:stepValue| ^stepValue < 0].
	(aNode isSend and: [aNode selector == #negated]) ifTrue:
		[self isConstantNode: aNode receiver valueInto: [:stepValue| ^stepValue > 0]].
	^false
]

{ #category : #public }
CCodeGenerator >> storeAPIExportHeader: headerName OnFile: fullHeaderPath [
	"Store C header code on the given file. Evaluate
	 aBlock with the stream to generate its contents."

	| header |
	header := String streamContents:
				[:s|
				 s nextPutAll: (self fileHeaderVersionStampForSourceClass: nil); cr.
				 self emitCAPIExportHeaderOn: s].
	(self needToGenerateHeader: headerName file: fullHeaderPath contents: header) ifTrue:
		[self storeHeaderOnFile: fullHeaderPath contents: header]
]

{ #category : #public }
CCodeGenerator >> storeCodeOnFile: fileName doInlining: inlineFlag [
	"Store C code for this code base on the given file."

	self storeCodeOnFile: fileName doInlining: inlineFlag doAssertions: true
]

{ #category : #public }
CCodeGenerator >> storeCodeOnFile: fileName doInlining: inlineFlag doAssertions: assertionFlag [
	"Store C code for this code base on the given file."

	| stream |
	stream := VMMaker forceNewFileNamed: fileName.
	stream ifNil: [Error signal: 'Could not open C code file: ', fileName].
	self emitCCodeOn: stream doInlining: inlineFlag doAssertions: assertionFlag.
	stream close
]

{ #category : #public }
CCodeGenerator >> storeHeaderOnFile: fileName contents: contents [
	"Store C header code on the given file. Evaluate
	 aBlock with the stream to generate its contents."

	| aStream |
	aStream := VMMaker forceNewFileNamed: fileName.
	aStream ifNil: [Error signal: 'Could not open C header file: ', fileName].
	[(contents beginsWith: '/* Automatic') ifFalse:
		[aStream nextPutAll: (self fileHeaderVersionStampForSourceClass: nil); cr].
	 aStream nextPutAll: contents]
		ensure: [aStream close]
]

{ #category : #inlining }
CCodeGenerator >> structAccessorSelectors [
		
	^ methods
		select: [ :m | m isStructAccessor ]
		thenCollect: [ :m | m selector]
]

{ #category : #accessing }
CCodeGenerator >> structClasses [
	^structClasses
]

{ #category : #utilities }
CCodeGenerator >> structClassesForTranslationClasses: classes [
	"Answer in superclass order (any superclass precedes any subclass)
	 the ancilliaryClasses that are struct classes for all the given classes."
	| theStructClasses |
	theStructClasses := OrderedCollection new.
	classes do:
		[:aTranslationClass|
		([aTranslationClass ancilliaryClasses]
				on: MessageNotUnderstood
				do: [:ex|
					ex message selector == #ancilliaryClasses
						ifTrue: [#()]
						ifFalse: [ex pass]]) do:
			[:class|
			(class isStructClass
			 and: [(vmClass isNil or: [vmClass isAcceptableAncilliaryClass: class])
			 and: [(theStructClasses includes: class) not]]) ifTrue:
				[theStructClasses addLast: class]]].
	^self superclassOrder: theStructClasses
]

{ #category : #'C code generator' }
CCodeGenerator >> structTargetKindForDeclaration: typeName [ "<String>"
	^VMStructType structTargetKindForDeclaration: typeName
]

{ #category : #'C code generator' }
CCodeGenerator >> structTargetKindForVariableName: varName [ "<String>"
	^(self typeOfVariable: varName) ifNotNil:
		[:declaration|
		 self structTargetKindForDeclaration: declaration]
]

{ #category : #utilities }
CCodeGenerator >> superclassOrder: classes [
	^[ChangeSet superclassOrder: classes] "Squeak"
		on: MessageNotUnderstood
		do: [ :ex|
			ex message selector == #superclassOrder: ifFalse:
				[ex pass].
			Class superclassOrder: classes] "Pharo"
]

{ #category : #accessing }
CCodeGenerator >> suppressAsmLabels [
	^suppressAsmLabels
]

{ #category : #accessing }
CCodeGenerator >> suppressAsmLabels: aBoolean [
	suppressAsmLabels := aBoolean
]

{ #category : #utilities }
CCodeGenerator >> suppressAsmLabelsWhile: aBlock [
	| oldSuppressAsmLabels |
	oldSuppressAsmLabels := suppressAsmLabels.
	suppressAsmLabels := true.
	^aBlock ensure: [suppressAsmLabels := oldSuppressAsmLabels]
]

{ #category : #utilities }
CCodeGenerator >> testInliningFor: selector as: inlineFlagOrSymbol [
	"Test inlining for the method with the given selector.
	 Do all inlining first (cuz that's how the algorithm works).
	 Then try and inline into a copy of the method.  This isn't
	 exactly what happens in the real deal but is close enough."
	| meth |
	((breakDestInlineSelectors includes:  selector)
	 or: [(breakSrcInlineSelectors includes:  selector)]) ifTrue:
		[self halt].
	meth := (self methodNamed: selector) copy.
	self doBasicInlining: inlineFlagOrSymbol.
	self halt.
	meth tryToInlineMethodsIn: self
]

{ #category : #utilities }
CCodeGenerator >> translationMethodClass [
	"return the class used to produce C translation methods from MethodNodes"
	^TMethod
]

{ #category : #'C translation support' }
CCodeGenerator >> tryToCollapseBothArmsOfConditional: msgNode on: aStream indent: level [
	"Attempt to generate the code for an ifTrue:ifFalse: if both arms are found to be the same, in which case
	 answer true.  Otherwise output nothing and answer false."
	(msgNode args first isSameAs: msgNode args second) ifFalse:
		[^false].
	msgNode receiver hasSideEffect ifTrue:
		[msgNode receiver emitCCodeAsExpressionOn: aStream level: level generator: self.
		 aStream nextPut: $; ; crtab: level].
	msgNode args first emitCCodeOn: aStream level: level generator: self.
	^true
]

{ #category : #'C translation support' }
CCodeGenerator >> tryToCollapseBothArmsOfConditionalExpression: msgNode on: aStream indent: level [
	"Attempt to generate the code for an ifTrue:ifFalse: if both arms are found to be the same, in which case
	 answer true.  Otherwise output nothing and answer false."
	(msgNode args first isSameAs: msgNode args second) ifFalse:
		[^false].
	aStream nextPut: $(.
	msgNode receiver hasSideEffect ifTrue:
		[msgNode receiver emitCCodeAsExpressionOn: aStream level: level generator: self.
		 aStream nextPut: $, ; crtab: level]..
	msgNode args first emitCCodeAsArgumentOn: aStream level: level generator: self.
	aStream nextPut: $).
	^true
]

{ #category : #'type inference' }
CCodeGenerator >> typeFor: aNode in: aTMethod [
	^aNode typeFrom: self in: aTMethod
]

{ #category : #'type inference' }
CCodeGenerator >> typeForArithmetic: sendNode in: aTMethod [
	"Answer the return type for an arithmetic sendThis is so that the inliner can still
	 inline simple expressions.  Deal with pointer arithmetic, floating point arithmetic
	 and promotion."
	| rcvrType argType arg |
	rcvrType := sendNode receiver typeOrNilFrom: self in: aTMethod.
	argType := (arg := sendNode args first) typeOrNilFrom: self in: aTMethod.
	"deal with pointer arithmetic"
	((rcvrType notNil and: [rcvrType last == $*]) or: [argType notNil and: [argType last == $*]]) ifTrue:
		[(rcvrType isNil or: [argType isNil]) ifTrue:
			[^nil].
		 (rcvrType last == $* and: [argType last == $*]) ifTrue:
			[sendNode selector == #- ifTrue:
				[^#int].
			 self error: 'invalid pointer arithmetic'].
		 ^rcvrType last == $*
			ifTrue: [rcvrType]
			ifFalse: [argType]].
	^(self promoteArithmeticTypes: rcvrType and: argType) ifNotNil:
		[:promotedType|
		 "We have to be very careful with subtraction.  The difference between two unsigned types is signed.
		  But we don't want unsigned - constant to be signed.  We almost always want this to stay unsigned."
		 (sendNode selector == #- and: [promotedType first == $u and: [(arg isConstant and: [arg value isInteger]) not]])
			ifTrue: [promotedType allButFirst: ((promotedType beginsWith: 'unsigned') ifTrue: [9] ifFalse: [1])]
			ifFalse: [promotedType]]
]

{ #category : #'type inference' }
CCodeGenerator >> typeForConditional: sendNode in: aTMethod [
	"Answer the return type for a conditional, ifTrue:ifFalse: et al"
	| firstType secondType |
	firstType := self typeFor: sendNode args first statements last in: aTMethod.
	sendNode selector numArgs = 1 ifTrue:
		[^firstType].
	secondType := self typeFor: sendNode args second statements last in: aTMethod.
	((firstType notNil and: [(self isIntegralCType: firstType) or: [self isFloatingPointCType: firstType]])
	 and: [secondType notNil and: [(self isIntegralCType: secondType) or: [self isFloatingPointCType: secondType]]]) ifTrue:
		[^self promoteArithmeticTypes: firstType and: secondType].
	^firstType ifNil: [secondType]
]

{ #category : #'type inference' }
CCodeGenerator >> typeForDereference: sendNode in: aTMethod [
	(self typeFor: sendNode receiver in: aTMethod) ifNotNil:
		[:type|
		 type last = $* ifTrue:
			[^type allButLast withBlanksTrimmed]].
	"It would be nice to warn here, but there are contexts when the type is unknown, for example determining
	 the return types of apiMethods.  inferTypesForImplicitlyTypedVariablesAndMethods could provide a signal
	 handler to suppress the warnings in that case but that's too fancy.  Instead we live with the default."
	"logger
		nextPutAll: 'warning, cannot determine type of at: for ', sendNode receiver asString, ' in ', aTMethod selector;
		cr."
	^#sqInt
]

{ #category : #'C code generator' }
CCodeGenerator >> typeOfVariable: varName [ "<String>"
	self assert: varName isString.
	scopeStack reverseDo:
		[:dict|
		(dict includesKey: varName) ifTrue:
			[^self
				extractTypeFor: varName
				fromDeclaration: (dict at: varName)]].
	(variableDeclarations
		at: varName
		ifAbsent:
			[apiVariables
				ifNotNil: [apiVariables at: varName ifAbsent: []]
				ifNil: []]) ifNotNil:
		[:decl| ^self extractTypeFor: varName fromDeclaration: decl].
	^(constants at: varName ifAbsent: []) ifNotNil:
		[:const|
		const value isInteger
			ifTrue: [#sqInt]
			ifFalse:
				[const value isFloat ifTrue:
					[#double]]]
]

{ #category : #utilities }
CCodeGenerator >> unreachableMethods [
	"Return a collection of methods that are never invoked."

	| neededSelectors previousSize visited |
	neededSelectors := Set new.
	"collect the exports"
	methods do:
		[:m|
		 m export ifTrue:
			[neededSelectors add: m selector]].

	"Now compute the transitive closure..."
	previousSize := neededSelectors size.
	visited := IdentitySet new: methods size.
	[neededSelectors do:
		[:s|
		(methods at: s ifAbsent: []) ifNotNil:
			[:m|
			(visited includes: m) ifFalse:
				[visited add: m.
				 neededSelectors
					add: m selector;
					addAll: m allCalls]]].
	 neededSelectors size > previousSize]
		whileTrue:
			[previousSize := neededSelectors size].

	^methods reject: [:m| neededSelectors includes: m selector]
]

{ #category : #'type inference' }
CCodeGenerator >> unsignedTypeForIntegralType: aCTypeString [
	^aCTypeString first = $u
		ifTrue: [aCTypeString]
		ifFalse:
			[(aCTypeString beginsWith: 'sq')
				ifTrue: ['u' , aCTypeString]
				ifFalse: ['unsigned ' , aCTypeString]]
]

{ #category : #accessing }
CCodeGenerator >> useSymbolicConstants [
	"Answer whether we should generate symbolic constants instead of their actual values"
	^useSymbolicConstants
]

{ #category : #accessing }
CCodeGenerator >> useSymbolicConstants: aBool [
	"Indicate whether we should generate symbolic constants instead of their actual values"
	useSymbolicConstants := aBool
]

{ #category : #public }
CCodeGenerator >> var: varName declareC: declarationString [
	"Record the given C declaration for a global variable."

	(declarationString includesSubstring: varName) ifFalse:
		[self error: 'declaration omits variable name.  probably an error.  use e.g. var:type:'].
	variableDeclarations at: varName asString put: declarationString.
]

{ #category : #public }
CCodeGenerator >> var: varName type: type [
	"Use this in preference to #var:declareC: when ever possible since it avoids typing
	 the varname twice and thus avoids the potential for a typo. See also #var:type:array:"
	self var: varName declareC: type , ' ' , varName
]

{ #category : #public }
CCodeGenerator >> var: varName type: cType array: array [
	"Use this in preference to #var:declareC: when possible. This produces a C
	 statment of the form
		int * fooArray[]={1,2,3}
	 See also #var:type: for simple var decls" 
	self
		var: varName
		declareC: (self arrayInitializerCalled: varName for: array sizeString: nil type: cType)
]

{ #category : #public }
CCodeGenerator >> var: varName type: cType sizeString: sizeString array: array [
	"Use this in preference to #var:declareC: when possible. This produces a C
	 statment of the form
		int * fooArray[3 /* Foo */]={1,2,3}
	 See also #var:type: for simple var decls" 
	self
		var: varName
		declareC: (self arrayInitializerCalled: varName for: array sizeString: sizeString type: cType)
]

{ #category : #inlining }
CCodeGenerator >> variableOfType: variableType acceptsValue: exprNode ofType: expressionType [
	"Simple type checking for assignment/return values"

	^variableType isNil "means as yet untyped, hence can adapt"
	  or: [expressionType isNil "means we don't know.  Potentially dangerous to say yes, but Slang is traditionally lax :("
	  or: [variableType = expressionType
	  or: [variableType notNil
		 and: [(variableType includes: $*)
				ifTrue:
					[(exprNode isVariable and: [exprNode name = 'nil'])
					  or: [expressionType last = $*
						   and: [(self isVoidPointer: variableType)
								or: [self isVoidPointer: expressionType]]]]
				ifFalse: "Require a cast if assigning integral with floating-point but not the other way around"
					[((self isIntegralCType: variableType)
					   and: [(self isIntegralCType: expressionType)
					   and: [(self sizeOfIntegralCType: variableType) >= (self sizeOfIntegralCType: expressionType)]])
					or: [(self isFloatingPointCType: variableType)
						and: [(self isFloatingPointCType: expressionType)
							or: [self isIntegralCType: expressionType]]]]]]]]
]

{ #category : #accessing }
CCodeGenerator >> vmClass [
	"Answer the interpreter class if any.  This is nil other than for the core VM."
	^vmClass
]

{ #category : #accessing }
CCodeGenerator >> vmClass: aClass [
	"Set the main translation class if any.  This is nil other than for the core VM.
	 It may be an interpreter or a cogit"
	vmClass := aClass.
	vmClass ifNotNil:
		[generateDeadCode := vmClass shouldGenerateDeadCode]
]

{ #category : #public }
CCodeGenerator >> vmHeaderContentsWithBytesPerWord: bytesPerWord [
	"Store C header code on the given stream."

	^ ByteString
		streamContents: [ :tempStream | vmClass writeVMHeaderTo: tempStream bytesPerWord: bytesPerWord generator: self ]
]

{ #category : #accessing }
CCodeGenerator >> vmMaker [
	^vmMaker
]

{ #category : #accessing }
CCodeGenerator >> vmMaker: aVMMaker [
	vmMaker := aVMMaker
]

{ #category : #utilities }
CCodeGenerator >> with: aNode ifAppropriateSetTo: aBoolean do: aBlock [
	"If aNode is a TDefineNode for a variable, set it to the supplied boolean for the duration
	 of aBlock.  This avoids duplicating both arms of nested cppIf:ifTrue:[ifFalse:]'s."
	| savedOptions |
	(aNode isConstant and: [aNode name notEmpty and: [aNode name first isLetter]]) ifFalse:
		[^aBlock value].
	savedOptions := optionsDictionary.
	optionsDictionary := savedOptions
							ifNil: [Dictionary new]
							ifNotNil: [savedOptions copy].
	optionsDictionary at: aNode name put: aBoolean.
	^aBlock ensure: [optionsDictionary := savedOptions]
]

{ #category : #'C code generator' }
CCodeGenerator >> withConditionalDefineOf: aConstantNameString comment: commentOrNil on: aStream do: aBlock [
	| start |
	aStream nextPutAll: '#if !defined('; nextPutAll: aConstantNameString; nextPut: $).
	commentOrNil ifNotNil: [aStream nextPutAll: ' /* '; nextPutAll: commentOrNil; nextPutAll: ' */'].
	aStream cr.
	start := aStream position.
	aBlock value.
	aStream nextPutAll: '#endif'.
	aStream position - start > 80 ifTrue:
		[aStream nextPutAll: ' /* !defined('; nextPutAll: aConstantNameString; nextPutAll: ') */'].
	aStream cr
]

{ #category : #'C code generator' }
CCodeGenerator >> withOptionalConditionalDefineFor: aTMethod on: aStream do: aBlock [
	"Evaluate aBlock, surrounded by an appropriate conditional define added to the stream if required."
	| compileTimeOptionPragmas |
	(compileTimeOptionPragmas := aTMethod compileTimeOptionPragmas) notEmpty ifTrue:
		[aTMethod outputConditionalDefineFor: compileTimeOptionPragmas on: aStream].
	aBlock value.
	aTMethod terminateConditionalDefineFor: compileTimeOptionPragmas on: aStream
]
