"
This class oversees the translation of a subset of Smalltalk to C, allowing the comforts of Smalltalk during development and the efficiency and portability of C for the resulting interpreter.  
See VMMaker for more useful info
"
Class {
	#name : #CCodeGenerator,
	#superclass : #Object,
	#instVars : [
		'vmClass',
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
		'currentMethod',
		'headerFiles',
		'globalVariableUsage',
		'useSymbolicConstants',
		'generateDeadCode',
		'requiredSelectors',
		'logger',
		'asmLabelCounts',
		'pools',
		'selectorTranslations'
	],
	#classVars : [
		'UseRightShiftForDivide'
	],
	#pools : [
		'VMBasicConstants'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #'class initialization' }
CCodeGenerator class >> initialize [
	"CCodeGenerator initialize"

	UseRightShiftForDivide := true.
		"If UseRightShiftForDivide is true, the translator will generate a right-shift when it encounters a division by a constant that is a small power of two. For example, 'x / 8' will generate '((int) x >> 3)'. The coercion to int is done to make it clear that the C compiler should generate a signed shift."
		"Note: The Kernighan and Ritchie 2nd Edition C manual, p. 49, leaves the semantics of right-shifting a negative number open to the discretion of the compiler implementor. However, it strongly suggests that most compilers should generate an arithmetic right shift (i.e., shifting in the sign bit), which is the same as dividing by a power of two. If your compiler does not generate or simulate an arithmetic shift, then make this class variable false and re-translate."

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
		[variables addAll: aClass instVarNames].
	self retainMethods: aClass requiredMethodNames.
	
	'Adding Class ' , aClass name , '...'
		displayProgressAt: Sensor cursorPoint
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
	aClass classPool associationsDo: [:assoc | | val node |
		val := assoc value.
		node := (useSymbolicConstants and:[self isCLiteral: val])
				ifTrue:[TDefineNode new setName: assoc key asString value: assoc value]
				ifFalse:[TConstantNode new setValue: assoc value].
		constants at: assoc key asString put: node].

]

{ #category : #public }
CCodeGenerator >> addHeaderFile: aString [
	"Add a header file. The argument must be a quoted string!"
	headerFiles addLast: aString.
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
	 generate code for these methods and hence the conflict doesn't matter."

	(methods at:  aTMethod selector ifAbsent: []) ifNotNil:
		[:conflict |
		(conflict isStructAccessor
		 and: [aTMethod isStructAccessor
		 and: [conflict compiledMethod decompileString = aTMethod compiledMethod decompileString]]) ifTrue:
			[^nil].
		self error: 'Method name conflict: ', aTMethod selector].
	^methods at: aTMethod selector put: aTMethod
]

{ #category : #utilities }
CCodeGenerator >> addMethodFor: aClass selector: selector [
	"Add the given method to the code base and answer its translation
	 or nil if it shouldn't be translated."

	| method tmethod |
	method := aClass compiledMethodAt: selector.
	(method pragmaAt: #doNotGenerate) ifNotNil:
		[^nil].
	"process optional methods by interpreting the argument to the option: pragma as either
	 a Cogit class name or a class variable name or a variable name in VMBasicConstants."
	(method pragmaAt: #option:) ifNotNil:
		[:pragma| | key |
		key := pragma argumentAt: 1.
		((Cogit withAllSubclasses anySatisfy: [:c| c name = key])
		and: [VMClass getVMMaker cogitClassName ~= key]) ifTrue:
			[^nil].
		(aClass bindingOf: key) ifNotNil:
			[:binding|
			binding value ifFalse: [^nil]].
		(VMBasicConstants bindingOf: key) ifNotNil:
			[:binding|
			binding value ifFalse: [^nil]]].
	tmethod := self addMethod: (self compileToTMethodSelector: selector in: aClass).
	"If the method has a macro then add the macro.  But keep the method
	 for analysis purposes (e.g. its variable accesses)."
	(method pragmaAt: #cmacro:) ifNotNil:
		[:pragma|
		self addMacro: (pragma argumentAt: 1) for: selector.
		tmethod inline: false].
	(method propertyValueAt: #cmacro:) ifNotNil:
		[:macro|
		self addMacro: macro for: selector.
		tmethod inline: false].
	^tmethod
]

{ #category : #public }
CCodeGenerator >> addMethodsForPrimitives: classAndSelectorList [ 
	| verbose |
	classAndSelectorList do: 
		[:classAndSelector | | aClass sel meth source |
		aClass := Smalltalk at: (classAndSelector at: 1).
		self addAllClassVarsFor: aClass.
"TPR - should pool vars also be added here?"

		"find the method in either the class or the metaclass"
		sel := classAndSelector at: 2.
		source := (aClass includesSelector: sel)
					ifTrue: [aClass sourceCodeAt: sel]
					ifFalse: [aClass class sourceCodeAt: sel].

		"compile the method source and convert to a suitable translation 
		method "
		meth := (Compiler new
					parse: source
					in: aClass
					notifying: nil)
					asTranslationMethodOfClass: self translationMethodClass.

		(aClass includesSelector: sel)
			ifTrue: [meth definingClass: aClass]
			ifFalse: [meth definingClass: aClass class].
		meth primitive > 0 ifTrue:[meth preparePrimitiveName].
		"for old-style array accessing: 
		meth covertToZeroBasedArrayReferences."
		meth replaceSizeMessages.
		self addMethod: meth].

	"method preparation"
	verbose := false.
	self prepareMethods.
	verbose
		ifTrue: 
			[self printUnboundCallWarnings.
			self printUnboundVariableReferenceWarnings.
			logger cr].

	"code generation"
	self doInlining: true.

	methods do:[:m|
		"if this method is supposed to be a primitive (rather than a helper 
		routine), add assorted prolog and epilog items"
		m primitive > 0 ifTrue: [m preparePrimitivePrologue]].
]

{ #category : #public }
CCodeGenerator >> addPoolVarsFor: aClass [ 
	"Add the pool variables for the given class to the code base as constants."

	(aClass sharedPools reject: [:pool| pools includes: pool]) do:
		[:pool |
		pools add: pool.
		pool bindingsDo: [:assoc | | val node |
			val := assoc value.
			node := (useSymbolicConstants and:[self isCLiteral: val])
						ifTrue:[TDefineNode new setName: assoc key asString value: assoc value]
						ifFalse:[TConstantNode new setValue: assoc value].
			constants at: assoc key asString put: node]].
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
	self retainMethods: aClass requiredMethodNames.
	
	'Adding Class ' , aClass name , '...'
		displayProgressAt: Sensor cursorPoint
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

{ #category : #utilities }
CCodeGenerator >> addStructMethodFor: aClass selector: selector [ 
	"Add the given struct method to the code base and answer its translation
	 or nil if it shouldn't be translated."
	^(self addMethodFor: aClass selector: selector) ifNotNil:
		[:tmethod|
		tmethod transformToStructClassMethodFor: self.
		tmethod]
]

{ #category : #accessing }
CCodeGenerator >> apiMethods: aDictionary [
	apiMethods := aDictionary
]

{ #category : #utilities }
CCodeGenerator >> builtin: sel [
	"Answer true if the given selector is one of the builtin selectors."

	^(#(error:
		 byteAt: byteAt:put: byteAtPointer: byteAtPointer:put:
		 intAt: intAt:put: intAtPointer: intAtPointer:put:
		 longAt: longAt:put: longAtPointer: longAtPointer:put:
		 shortAt: shortAt:put: shortAtPointer: shortAtPointer:put:
		 fetchFloatAt:into: storeFloatAt:from:
				fetchFloatAtPointer:into: storeFloatAtPointer:from:
		 fetchSingleFloatAt:into: storeSingleFloatAt:from:
				fetchSingleFloatAtPointer:into: storeSingleFloatAtPointer:from:)
			includes: sel)
	  or: [translationDict includesKey: sel]
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
	"Create a C function name from the given selector by omitting colons
	and prefixing with the plugin name if the method is exported."
	^selectorTranslations at: aSelector ifAbsent: [aSelector copyWithout: $:]
]

{ #category : #'C code generator' }
CCodeGenerator >> cLiteralFor: anObject [
	"Return a string representing the C literal value for the given object."
	anObject isNumber
		ifTrue:
			[anObject isInteger ifTrue:
				[^(anObject < 16r7FFFFFFF)
					ifTrue: [anObject printString]
					ifFalse: [anObject printString , ObjectMemory unsignedIntegerSuffix "ikp"]].
			anObject isFloat ifTrue: [^anObject printString]]
		ifFalse:
			[anObject isString ifTrue:
				[^'"', anObject, '"'].
			anObject == nil ifTrue: [^ 'null' ].
			anObject == true ifTrue: [^ '1' ].			"ikp"
			anObject == false ifTrue: [^ '0' ].			"ikp"
			anObject isCharacter ifTrue:[^anObject asString printString]]. "ar"
	self error:								"ikp"
		'Warning: A Smalltalk literal could not be translated into a C constant: ', anObject printString.
	^'"XXX UNTRANSLATABLE CONSTANT XXX"'
]

{ #category : #'C code generator' }
CCodeGenerator >> cLiteralFor: anObject name: smalltalkName [
	"Return a string representing the C literal value for the given object."
	anObject isInteger ifTrue:
		[| hex dec rep |
		hex := anObject printStringBase: 16.
		dec := anObject printStringBase: 10.
		rep := ((smalltalkName endsWith: 'Mask')
				or: [anObject digitLength > 1
					and: [(hex asSet size * 3) <= (dec asSet size * 2)
					and: [(smalltalkName endsWith: 'Size') not]]])
					ifTrue: [hex first = $- ifTrue: ['-0x', hex allButFirst] ifFalse: ['0x', hex]]
					ifFalse: [dec].
		^(anObject < 16r7FFFFFFF)
			ifTrue: [rep]
			ifFalse: [rep, ObjectMemory unsignedIntegerSuffix "ikp"]].
	anObject isFloat ifTrue:
		[^anObject printString].
	anObject isString ifTrue:
		[^'"', anObject, '"'].
	anObject == nil ifTrue: [^ 'null' ].
	anObject == true ifTrue: [^ '1' ].			"ikp"
	anObject == false ifTrue: [^ '0' ].			"ikp"
	anObject isCharacter ifTrue:[^anObject asString printString]. "ar"
	self error: 'Warning: A Smalltalk literal could not be translated into a C constant: ', anObject printString.
	^'"XXX UNTRANSLATABLE CONSTANT XXX"'
]

{ #category : #'error notification' }
CCodeGenerator >> checkClassForNameConflicts: aClass [
	"Verify that the given class does not have constant, variable, or method names that conflict with
	 those of previously added classes. Raise an error if a conflict is found, otherwise just return."

	"check for constant name collisions in class pools"
	aClass classPool associationsDo:
		[:assoc |
		(constants includesKey: assoc key asString) ifTrue:
			[self error: 'Constant ', assoc key, ' was defined in a previously added class']].

	"and in shared pools"
	(aClass sharedPools reject: [:pool| pools includes: pool]) do:
		[:pool |
		pool bindingsDo:
			[:assoc |
			(constants includesKey: assoc key asString) ifTrue:
				[self error: 'Constant ', assoc key, ' was defined in a previously added class']]].

	"check for instance variable name collisions"
	(aClass inheritsFrom: VMStructType) ifFalse:
		[aClass instVarNames do:
			[:varName |
			(variables includes: varName) ifTrue:
				[self error: 'Instance variable ', varName, ' was defined in a previously added class']]].

	"check for method name collisions"
	aClass selectors do:
		[:sel |
		((methods includesKey: sel)
		and: [((aClass compiledMethodAt: sel) pragmaAt: #doNotGenerate) isNil]) ifTrue:
			[self error: 'Method ', sel, ' was defined in a previously added class.']]
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
	aTMethod referencesGlobalStructMakeZero
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
CCodeGenerator >> collectInlineList: inlineFlagOrSymbol [
	"Make a list of methods that should be inlined.  If inlineFlagOrSymbol == #asSpecified
	 only inline methods marked with <inline: true>."
	"Details: The method must not include any inline C, since the
	 translator cannot currently map variable names in inlined C code.
	 Methods to be inlined must be small or called from only one place."

	| selectorsOfMethodsNotToInline callsOf |
	self assert: (#(true false asSpecified) includes: inlineFlagOrSymbol).
	selectorsOfMethodsNotToInline := Set new: methods size.
	selectorsOfMethodsNotToInline addAll: macros keys.
	methods do:
		[:m|
		m isStructAccessor ifTrue:
			[selectorsOfMethodsNotToInline add: m selector]].

	"build dictionary to record the number of calls to each method"
	callsOf := Dictionary new: methods size * 2.
	methods keysAndValuesDo:
		[ :s :m |
		m isRealMethod ifTrue: [callsOf at: s put: 0]].

	"For each method, scan its parse tree once or twice to:
		1. determine if the method contains unrenamable C code or declarations or has a C builtin
		2. determine how many nodes it has
		3. increment the sender counts of the methods it calls"
	inlineList := Set new: methods size * 2.
	(methods reject: [:m| selectorsOfMethodsNotToInline includes: m selector]) do:
		[ :m | | inlineIt hasUnrenamableCCode nodeCount  |
		inlineIt := #dontCare.
		(translationDict includesKey: m selector)
			ifTrue: [hasUnrenamableCCode := true]
			ifFalse:
				[hasUnrenamableCCode := m hasUnrenamableCCode.
				 nodeCount := 0.
				 m parseTree nodesDo:
					[ :node | | sel |
					node isSend ifTrue:
						[sel := node selector.
						 (callsOf at: sel ifAbsent: [ nil ]) ifNotNil:
							[:senderCount| callsOf at: sel put: senderCount + 1]].
					 nodeCount := nodeCount + 1].
				inlineIt := m extractInlineDirective].  "may be true, false, or #dontCare"
		(hasUnrenamableCCode or: [inlineIt == false])
			ifTrue: "don't inline if method has C code or contains negative inline directive"
				[inlineIt == true ifTrue:
					[logger
						ensureCr;
						nextPutAll: 'failed to inline ';
						nextPutAll: m selector;
						nextPutAll: ' as it contains unrenamable C declarations or C code';
						cr; flush].
				selectorsOfMethodsNotToInline add: m selector]
			ifFalse:
				[(inlineFlagOrSymbol == #asSpecified
					ifTrue: [inlineIt == true]
					ifFalse: [nodeCount < 40 or: [inlineIt == true]]) ifTrue:
				"inline if method has no C code and is either small or contains inline directive"
					[inlineList add: m selector]]].

	inlineFlagOrSymbol ~~ #asSpecified ifTrue:
		[callsOf associationsDo:
			[:assoc|
			(assoc value = 1
			 and: [(selectorsOfMethodsNotToInline includes: assoc key) not]) ifTrue:
				[inlineList add: assoc key]]]
]

{ #category : #utilities }
CCodeGenerator >> compileToTMethodSelector: selector in: aClass [
	"Compile a method to a TMethod"

	^(Compiler new
		parse: (aClass sourceCodeAt: selector)
		in: aClass
		notifying: nil)
			asTranslationMethodOfClass: self translationMethodClass
]

{ #category : #accessing }
CCodeGenerator >> currentMethod [
	^currentMethod
]

{ #category : #accessing }
CCodeGenerator >> currentMethod: aTMethod [
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
		('Inlining pass ', (pass := pass + 1) printString, '...')
			displayProgressAt: Sensor cursorPoint
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

	'Inlining bytecodes'
		displayProgressAt: Sensor cursorPoint
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
	action := translationDict at: msgNode selector ifAbsent: [ ^false ].
	self perform: action with: msgNode with: aStream with: level.
	^true
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCAPIExportHeaderOn: aStream [ 
	"Store prototype declarations for all non-inlined methods on the given stream."
	| api methodList |
	api := vmClass translationClass exportAPISelectors.
	methodList := api select: [:s| (methods includesKey: s) or: [(vmClass whichClassIncludesSelector: s) notNil]]
					  thenCollect:
						[:s|
						methods
							at: s
							ifAbsent: [self compileToTMethodSelector: s
										   in: (vmClass whichClassIncludesSelector: s)]].
	methodList := self sortMethods: methodList.
	methodList do:
		[:m|
		m static ifTrue:
			[logger ensureCr; show: m selector, ' excluded from export API because it is static'; cr]].
	self emitCFunctionPrototypes: methodList on: aStream.
	self emitGlobalCVariablesOn: aStream.
	self emitCMacros: methodList on: aStream
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
	methodList do: [:m | self checkForGlobalUsage: m removeUnusedTemps in: m].
	self localizeGlobalVariables.

	self emitCHeaderOn: aStream.
	self emitCTypesOn: aStream.
	self emitCConstantsOn: aStream.
	self emitCFunctionPrototypes: methodList on: aStream.
	self emitCVariablesOn: aStream.
	self emitCMacros: methodList on: aStream.
	self emitCMethods: methodList on: aStream.
	self emitExportsOn: aStream.

]

{ #category : #'C code generator' }
CCodeGenerator >> emitCConstantsOn: aStream [ 
	"Store the global variable declarations on the given stream."
	| unused constList |
	unused := constants keys asSet.
	methods do:
		[:meth|
		meth parseTree nodesDo:
			[:n| n isConstant ifTrue: [unused remove: n name ifAbsent: []]]].
	unused copy do:
		[:const|
		(variableDeclarations anySatisfy: [:value| value includesSubString: const]) ifTrue:
			[unused remove: const ifAbsent: []]].
	"Don't generate any defines for the externally defined constants, STACKVM, COGVM, COGMTVM et al."
	(VMClass class>>#initializeMiscConstantsWith:) literalsDo:
		[:lit|
		lit isVariableBinding ifTrue:
			[unused add: lit key]].
	constList := constants keys reject:[:any| unused includes: any].
	aStream cr; nextPutAll: '/*** Constants ***/'; cr.
	(self sortStrings: constList) do:
		[:varName| | node default value |
		node := constants at: varName.
		node name isEmpty ifFalse:
			["Allow the class to provide an alternative definition, either of just the value or the whole shebang"
			default := self cLiteralFor: node value name: varName.
			value := vmClass
						ifNotNil:
							[(vmClass specialValueForConstant: node name default: default)
								ifNotNil: [:specialDef| specialDef]
								ifNil: [default]]
						ifNil: [default].
			value first ~= $# ifTrue:
				[aStream nextPutAll: '#define '; nextPutAll: node name; space].
			aStream nextPutAll: value; cr]].
	aStream cr
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCExpression: aParseNode on: aStream [ 
	"Emit C code for the expression described by the given parse node."

	aParseNode isLeaf 
		ifTrue: 
			["omit parens"
			 aParseNode emitCCodeAsExpressionOn: aStream level: 0 generator: self]
		ifFalse: 
			[aStream nextPut: $(.
			 aParseNode emitCCodeAsExpressionOn: aStream level: 0 generator: self.
			 aStream nextPut: $)]
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCFunctionPrototypes: methodList on: aStream [ 
	"Store prototype declarations for all non-inlined methods on the given stream."
	| exporting |
	aStream cr; nextPutAll: '/*** Function Prototypes ***/'; cr.
	exporting := false.
	(methodList select: [:m| m isRealMethod]) do:
		[:m |
		self emitExportPragma ifTrue:
			[m export
				ifTrue: [exporting ifFalse: 
							[aStream nextPutAll: '#pragma export on'; cr.
							exporting := true]]
				ifFalse: [exporting ifTrue: 
							[aStream nextPutAll: '#pragma export off'; cr.
							exporting := false]]].
		m emitCFunctionPrototype: aStream generator: self.
		aStream nextPut: $; ; cr].
	exporting ifTrue: [aStream nextPutAll: '#pragma export off'; cr].
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

	headerFiles addFirst: '"sq.h"'.
	vmClass isInterpreterClass ifTrue:
		[headerFiles addLast: '"sqMemoryAccess.h"'].
	"Additional header files; include C library ones first."
	self emitHeaderFiles: (headerFiles select: [:hdr| hdr includes: $<]) on: aStream.
	"Additional header files; include squeak VM ones last"
	self emitHeaderFiles: (headerFiles reject: [:hdr| hdr includes: $<]) on: aStream.

	vmClass isInterpreterClass ifTrue:
		[aStream cr; cr; nextPutAll: vmClass preambleCCode].

	aStream cr
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCMacros: methodList on: aStream [ 
	"Store the global variable declarations on the given stream."
	macros isEmpty ifTrue: [^self].
	aStream cr; nextPutAll: '/*** Macros ***/'; cr.

	(methodList reject: [:m| m isRealMethod]) do:
		[:m |
		m definedAsMacro ifTrue:
			[aStream
				nextPutAll: '#define ';
				nextPutAll:(self cFunctionNameFor: m selector);
				nextPutAll: (macros at: m selector); cr]].
	aStream cr
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCMethods: methodList on: aStream [
	'Writing Translated Code...'
		displayProgressAt: Sensor cursorPoint
		from: 0 to: methods size
		during:
			[:bar |
			methodList doWithIndex:
				[ :m :i |
				bar value: i.
				m isRealMethod ifTrue:
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
	vmClass ifNotNil:
		[vmClass ancilliaryStructClasses do:
			[:structClass|
			(vmClass shouldGenerateTypedefFor: structClass) ifTrue:
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
		self isGeneratingPluginCode
			ifTrue:
				[varString = 'interpreterProxy'
					ifTrue: ["quite special..."
						aStream cr; nextPutAll: '#ifdef SQUEAK_BUILTIN_PLUGIN'.
						aStream cr; nextPutAll: 'extern'.
						aStream cr; nextPutAll: '#endif'; cr]
					ifFalse: [(decl beginsWith: 'static') ifFalse:
								[aStream nextPutAll: 'static ']]]
			ifFalse:
				[(vmClass mustBeGlobal: varString) ifFalse:
					[(decl beginsWith: 'static') ifFalse:
						[aStream nextPutAll: 'static ']]].
		aStream
			nextPutAll: decl;
			nextPut: $;;
			cr].
	aStream cr
]

{ #category : #'C code generator' }
CCodeGenerator >> emitExportPragma [
	"Controls emission of  #pragma export on / #pragma export off,
	 which is not relevant to any current platform that anyone could name."
	^[vmClass emitExportPragma]
		on: MessageNotUnderstood
		do: [:ex| false]
]

{ #category : #'C code generator' }
CCodeGenerator >> emitExportsOn: aStream [
	"Store all the exported primitives in a form to be used by the internal named prim system"
	(vmClass isNil or: [vmClass isInterpreterClass]) ifFalse:
		[^self].
	aStream nextPutAll:'

void* vm_exports[][3] = {'.
	(self sortStrings: self exportedPrimitiveNames) do:[:primName|
		aStream cr;
			nextPutAll:'	{"", "'; 
			nextPutAll: primName; 
			nextPutAll:'", (void*)'; 
			nextPutAll: primName;
			nextPutAll:'},'.
	].
	aStream nextPutAll:'
	{NULL, NULL, NULL}
};
'
]

{ #category : #'C code generator' }
CCodeGenerator >> emitGlobalCVariablesOn: aStream [
	"Store the global variable declarations on the given stream."

	aStream cr; nextPutAll: '/*** Global Variables ***/'; cr.
	(self sortStrings: (variables select: [:v| vmClass mustBeGlobal: v])) do:
		[:var | | varString decl |
		varString := var asString.
		decl := variableDeclarations at: varString ifAbsent: ['sqInt ' , varString].
		((decl includesSubString: ' private ')
		  or: [decl beginsWith: 'static']) ifFalse: "work-around hack to prevent localization of variables only referenced once."
			[(decl includes: $=) ifTrue:
				[decl := decl copyFrom: 1 to: (decl indexOf: $=) - 1].
			aStream
				nextPutAll: decl;
				nextPut: $;;
				cr]].
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
	^methods select:[:m| m export] thenCollect:[:m| m selector copyWithout: $:].

]

{ #category : #'C code generator' }
CCodeGenerator >> fileHeaderVersionStampForSourceClass: sourceClass [
	"Answer a suitable versiomn stamp to include in the header."
	| exportBuildInfo slangDescription sourceDescription |
	[exportBuildInfo := sourceClass isInterpreterClass
						ifTrue: ['char *__interpBuildInfo = __buildInfo;']
						ifFalse:
							[sourceClass isCogitClass
								ifTrue: ['char *__cogitBuildInfo = __buildInfo;']]]
		on: MessageNotUnderstood
		do: [:ex| ex resume: false].
	[slangDescription := self monticelloDescriptionFor: self class.
	 sourceClass ifNotNil:
		[sourceDescription := self monticelloDescriptionFor: sourceClass]]
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
		s nextPutAll: '/* Automatically generated by'.
		s crtab.
		s nextPutAll: slangDescription.
		sourceDescription ifNotNil:
			[s cr; nextPutAll: '   from'; crtab; nextPutAll: sourceDescription].
		s cr; nextPutAll: ' */'; cr.
		sourceDescription ifNotNil:
			[s nextPutAll: 'static char __buildInfo[] = "'.
			 s nextPutAll: sourceDescription.
			 s nextPutAll: ' " __DATE__ ;'; cr.
			exportBuildInfo ifNotNil:
				[s nextPutAll: exportBuildInfo; cr].
			s cr]]
]

{ #category : #'C translation' }
CCodeGenerator >> generateAddressOf: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPut: $(; nextPut: $&.
	self emitCExpression: msgNode args first on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateAnd: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' && '.
	self emitCExpression: msgNode args first on: aStream.
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

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' & '.
	self emitCExpression: msgNode args first on: aStream.
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
CCodeGenerator >> generateBitInvert32: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPut: $~.
	self emitCExpression: msgNode receiver on: aStream
]

{ #category : #'C translation' }
CCodeGenerator >> generateBitOr: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' | '.
	self emitCExpression: msgNode args first on: aStream.
]

{ #category : #'C translation' }
CCodeGenerator >> generateBitShift: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| arg rcvr |
	arg := msgNode args first.
	rcvr := msgNode receiver.
	arg isConstant ifTrue: [
		"bit shift amount is a constant"
		aStream nextPutAll: '((usqInt) '.
		self emitCExpression: rcvr on: aStream.
		arg value < 0 ifTrue: [
			aStream nextPutAll: ' >> ', arg value negated printString.
		] ifFalse: [
			aStream nextPutAll: ' << ', arg value printString.
		].
		aStream nextPutAll: ')'.
	] ifFalse: [
		"bit shift amount is an expression"
		aStream nextPutAll: '(('.
		self emitCExpression: arg on: aStream.
		aStream nextPutAll: ' < 0) ? ((usqInt) '.
		self emitCExpression: rcvr on: aStream.
		aStream nextPutAll: ' >> -'.
		self emitCExpression: arg on: aStream.
		aStream nextPutAll: ') : ((usqInt) '.
		self emitCExpression: rcvr on: aStream.
		aStream nextPutAll: ' << '.
		self emitCExpression: arg on: aStream.
		aStream nextPutAll: '))'.
	].
]

{ #category : #'C translation' }
CCodeGenerator >> generateBitXor: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' ^ '.
	self emitCExpression: msgNode args first on: aStream.
]

{ #category : #'C translation' }
CCodeGenerator >> generateCCoercion: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '(('.
	aStream nextPutAll: msgNode args last value.
	aStream nextPutAll: ') '.
	self emitCExpression: msgNode args first on: aStream.
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
CCodeGenerator >> generateDivide: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| rcvr arg divisor |
	rcvr := msgNode receiver.
	arg := msgNode args first.
	(arg isConstant and:
	 [UseRightShiftForDivide and:
	 [(divisor := arg value) isInteger and:
	 [divisor isPowerOfTwo and:
	 [divisor > 0 and:
	 [divisor <= (1 bitShift: 31)]]]]])
	ifTrue: [
		"use signed (arithmetic) right shift instead of divide"
		aStream nextPutAll: '((sqInt) '.
		self emitCExpression: rcvr on: aStream.
		aStream nextPutAll: ' >> ', (divisor log: 2) asInteger printString.
		aStream nextPutAll: ')'.
	] ifFalse: [
		self emitCExpression: rcvr on: aStream.
		aStream nextPutAll: ' / '.
		self emitCExpression: arg on: aStream].

]

{ #category : #'C translation' }
CCodeGenerator >> generateDoWhileFalse: msgNode on: aStream indent: level [
	"Generate do {stmtList} while(!(cond))"

	| stmts testStmt |
	stmts := msgNode receiver statements asOrderedCollection.
	testStmt := stmts removeLast.
	msgNode receiver setStatements: stmts.
	aStream nextPutAll: 'do {'; cr.
	msgNode receiver emitCCodeOn: aStream level: level + 1 generator: self.
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '} while(!('.
	testStmt emitCCodeOn: aStream level: 0 generator: self.
	aStream nextPutAll: '))'.
]

{ #category : #'C translation' }
CCodeGenerator >> generateDoWhileTrue: msgNode on: aStream indent: level [
	"Generate do {stmtList} while(cond)"

	| stmts testStmt |
	stmts := msgNode receiver statements asOrderedCollection.
	testStmt := stmts removeLast.
	msgNode receiver setStatements: stmts.
	aStream nextPutAll: 'do {'; cr.
	msgNode receiver emitCCodeOn: aStream level: level + 1 generator: self.
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '} while('.
	testStmt emitCCodeOn: aStream level: 0 generator: self.
	aStream nextPutAll: ')'.
]

{ #category : #'C translation' }
CCodeGenerator >> generateEqual: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' == '.
	self emitCExpression: msgNode args first on: aStream.
]

{ #category : #'C translation' }
CCodeGenerator >> generateGreaterThan: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' > '.
	self emitCExpression: msgNode args first on: aStream.
]

{ #category : #'C translation' }
CCodeGenerator >> generateGreaterThanOrEqual: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' >= '.
	self emitCExpression: msgNode args first on: aStream.
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfFalse: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode)
		ifNil:
			[aStream nextPutAll: 'if (!('.
			msgNode receiver emitCCodeAsExpressionOn: aStream level: level + 1 generator: self.
			aStream nextPutAll: ')) {'; cr.
			msgNode args last emitCCodeOn: aStream level: level + 1 generator: self.
			level timesRepeat: [aStream tab].
			aStream nextPut: $}]
		ifNotNil:
			[:const |
			const ifFalse:
				[msgNode args first emitCCodeOn: aStream level: level generator: self]]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfFalseAsArgument: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode)
		ifNil:
			[aStream nextPutAll: '(!('.
			 msgNode receiver emitCCodeAsArgumentOn: aStream level: 0 generator: self.
			aStream nextPut: $); crtab: level + 1; nextPut: $?; space.
			msgNode args last emitCCodeAsArgumentOn: aStream level: level + 2 generator: self.
			aStream crtab: level + 1; nextPutAll: ': 0)']
		ifNotNil:
			[:const|
			const ifFalse:
				[msgNode args first emitCCodeAsArgumentOn: aStream level: level generator: self]]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfFalseIfTrue: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode)
		ifNil:
			[aStream nextPutAll: 'if ('.
			msgNode receiver emitCCodeAsExpressionOn: aStream level: level generator: self.
			aStream nextPutAll: ') {'; cr.
			msgNode args last emitCCodeOn: aStream level: level + 1 generator: self.
			aStream tab: level; nextPut: $}; cr; tab: level; nextPutAll: 'else {'; cr.
			msgNode args first emitCCodeOn: aStream level: level + 1 generator: self.
			aStream tab: level; nextPut: $}]
		ifNotNil:
			[:const |
			 (const ifTrue: [msgNode args last] ifFalse: [msgNode args first])
				emitCCodeOn: aStream level: level generator: self]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfFalseIfTrueAsArgument: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode)
		ifNil:
			[aStream nextPut: $(.
			msgNode receiver emitCCodeAsArgumentOn: aStream level: level generator: self.
			aStream crtab: level + 1; nextPut: $?; space.
			msgNode args last emitCCodeAsArgumentOn: aStream level: level + 2 generator: self.
			aStream crtab: level + 1; nextPut: $:; space.
			msgNode args first emitCCodeAsArgumentOn: aStream level: level + 2 generator: self.
			aStream nextPut: $)]
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
			level timesRepeat: [aStream tab].
			aStream nextPut: $}]
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
			aStream crtab: level + 1; nextPutAll: ': 0)']
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

	(self nilOrBooleanConstantReceiverOf: msgNode)
		ifNil:
			[aStream nextPutAll: 'if ('.
			msgNode receiver emitCCodeAsExpressionOn: aStream level: level generator: self.
			aStream nextPutAll: ') {'; cr.
			msgNode args first emitCCodeOn: aStream level: level + 1 generator: self.
			level timesRepeat: [ aStream tab ].
			aStream nextPut: $}]
		ifNotNil:
			[:const |
			const ifTrue:
				[msgNode args first emitCCodeOn: aStream level: level generator: self]]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfTrueAsArgument: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode)
		ifNil:
			[aStream nextPut: $(.
			 msgNode receiver emitCCodeAsArgumentOn: aStream level: level generator: self.
			 aStream crtab: level + 1; nextPut: $?; space.
			 msgNode args first emitCCodeAsArgumentOn: aStream level: level + 2 generator: self.
			 aStream crtab: level + 1; nextPutAll: ': 0)']
		ifNotNil:
			[:const|
			const ifTrue:
				[msgNode args first emitCCodeAsArgumentOn: aStream level: level generator: self]]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfTrueIfFalse: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode)
		ifNil:
			[aStream nextPutAll: 'if ('.
			msgNode receiver emitCCodeAsExpressionOn: aStream level: level generator: self.
			aStream nextPutAll: ') {'; cr.
			msgNode args first emitCCodeOn: aStream level: level + 1 generator: self.
			aStream tab: level; nextPut: $}; cr; tab: level; nextPutAll: 'else {'; cr.
			msgNode args last emitCCodeOn: aStream level: level + 1 generator: self.
			aStream tab: level; nextPut: $}]
		ifNotNil:
			[:const |
			(const ifTrue: [msgNode args first] ifFalse: [msgNode args last])
				emitCCodeOn: aStream level: level generator: self]
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfTrueIfFalseAsArgument: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode)
		ifNil:
			[aStream nextPut: $(.
			msgNode receiver emitCCodeAsExpressionOn: aStream level: level generator: self.
			aStream crtab: level + 1; nextPut: $?; space.
			msgNode args first emitCCodeAsArgumentOn: aStream level: level + 2 generator: self.
			aStream crtab: level + 1; nextPut: $:; space.
			msgNode args last emitCCodeAsArgumentOn: aStream level: level + 2 generator: self.
			aStream nextPut: $)]
		ifNotNil:
			[:const|
			(const ifTrue: [msgNode args first] ifFalse: [msgNode args last])
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
			aStream nextPutAll: msgNode args first value]
		ifFalse: [msgNode args first
					emitCCodeOn: aStream
					level: level
					generator: self]
]

{ #category : #'C translation' }
CCodeGenerator >> generateInlineCCodeAsArgument: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream.
	 There are two forms, self cCode: aString ... and self cCode: aBlock."

	msgNode args first isConstant
		ifTrue:
			[(msgNode args first value at: 1 ifAbsent: nil) = $# ifTrue:
				[aStream cr].
			aStream nextPutAll: msgNode args first value]
		ifFalse: [msgNode args first
					emitCCodeAsArgumentOn: aStream
					level: level
					generator: self]
]

{ #category : #'C translation' }
CCodeGenerator >> generateInlineCPreprocessorDirective: msgNode on: aStream indent: level [
	"Generate the C preprocessor directive for this message onto the given stream."

	aStream cr; nextPutAll: msgNode args first value
]

{ #category : #'C translation' }
CCodeGenerator >> generateInlineCppIfElse: msgNode asArgument: asArgument on: aStream indent: level [
	"Generate the C code for this message onto the given stream."
	| expr putStatement |
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

	putStatement value: msgNode args second.
	expr := ' /* ', expr, ' */'.
	msgNode args size >= 3 ifTrue:
		[aStream
			ensureCr;
			nextPut: $#; next: level * 2 put: Character space; nextPutAll: 'else'; nextPutAll: expr;
			cr.
		putStatement value: msgNode args third].
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

	aStream nextPutAll: '(('.
	self emitCExpression: msgNode args first on: aStream.
	aStream nextPutAll: ' << 1) | 1)'.
]

{ #category : #'C translation' }
CCodeGenerator >> generateIntegerValueOf: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '('.
	self emitCExpression: msgNode args first on: aStream.
	aStream nextPutAll: ' >> 1)'.
]

{ #category : #'C translation' }
CCodeGenerator >> generateIsIntegerObject: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '('.
	self emitCExpression: msgNode args first on: aStream.
	aStream nextPutAll: ' & 1)'.
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

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' < '.
	self emitCExpression: msgNode args first on: aStream.
]

{ #category : #'C translation' }
CCodeGenerator >> generateLessThanOrEqual: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' <= '.
	self emitCExpression: msgNode args first on: aStream.
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

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' - '.
	self emitCExpression: msgNode args first on: aStream.
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
CCodeGenerator >> generateNot: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '!'.
	self emitCExpression: msgNode receiver on: aStream.
]

{ #category : #'C translation' }
CCodeGenerator >> generateNotEqual: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' != '.
	self emitCExpression: msgNode args first on: aStream.
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

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' + '.
	self emitCExpression: msgNode args first on: aStream.
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
CCodeGenerator >> generateSequentialAnd: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream.
	aStream crtab: level; nextPutAll: ' && ('.
	self emitCTestBlock: msgNode args first on: aStream indent: level.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateSequentialOr: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."
	"Note: PP 2.3 compiler produces two arguments for or:, presumably
	 to help with inlining later. Taking the last agument should do the correct
	 thing even if your compiler is different."

	self emitCExpression: msgNode receiver on: aStream.
	aStream crtab: level; nextPutAll: ' || ('.
	self emitCTestBlock: msgNode args last on: aStream indent: level.
	aStream nextPutAll: ')'
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
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' << '.
	self emitCExpression: msgNode args first on: aStream.
]

{ #category : #'C translation' }
CCodeGenerator >> generateShiftRight: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| decl |
	"If the variable is a 64-bit type then don't cast it to usqInt (typically a 32-bit type)"
	(msgNode receiver isVariable
	 and: [(decl := self typeOfVariable: msgNode receiver name) notNil
	 and: [#('usqLong' 'sqLong' 'unsigned long long' 'long long' 'unsigned __int64' '__int64')
			anySatisfy: [:type| decl beginsWith: type]]])
		ifTrue:
			["If not unsigned cast it to unsigned."
			 (decl first = $u) ifFalse:
				[aStream
					nextPutAll: '((unsigned ';
					nextPutAll: (decl allButLast: msgNode receiver name size);
					nextPut: $)].
			 self emitCExpression: msgNode receiver on: aStream.
			 (decl first = $u) ifFalse:
				[aStream nextPut: $)]]
		ifFalse:
			[aStream nextPutAll: '((usqInt) '.
			 self emitCExpression: msgNode receiver on: aStream.
			 aStream nextPut: $)].
	aStream nextPutAll: ' >> '.
	self emitCExpression: msgNode args first on: aStream
]

{ #category : #'C translation' }
CCodeGenerator >> generateSignedBitShift: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| arg |
	(arg := msgNode args first) isConstant
		ifTrue: "bit shift amount is a constant"
			[aStream nextPut: $(; nextPutAll: '(signed)'.
			self emitCExpression: msgNode receiver on: aStream.
			arg value < 0
				ifTrue: [aStream nextPutAll: ' >> ', arg value negated printString]
				ifFalse: [aStream nextPutAll: ' << ', arg value printString].
			aStream nextPut: $)]
		ifFalse: "bit shift amount is an expression"
			[aStream nextPutAll: '(('.
			self emitCExpression: arg on: aStream.
			aStream nextPutAll: ' < 0) ? ('; nextPutAll: '(signed)'.
			self emitCExpression: msgNode receiver on: aStream.
			aStream nextPutAll: ' >> -'.
			self emitCExpression: arg on: aStream.
			aStream nextPutAll: ') : ('; nextPutAll: '(signed)'.
			self emitCExpression: msgNode receiver on: aStream.
			aStream nextPutAll: ' << '.
			self emitCExpression: arg on: aStream.
			aStream nextPutAll: '))']
]

{ #category : #'C translation' }
CCodeGenerator >> generateSignedIntFromLong: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '((sqInt) '.
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
CCodeGenerator >> generateSignedIntToLong: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '((usqInt) '.
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
CCodeGenerator >> generateSmalltalkMetaError: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: 'error("'; nextPutAll: msgNode selector; nextPutAll: '")'
]

{ #category : #'C translation' }
CCodeGenerator >> generateTimes: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' * '.
	self emitCExpression: msgNode args first on: aStream.
]

{ #category : #'C translation' }
CCodeGenerator >> generateToByDo: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| iterationVar step negative |
	(msgNode args last args size = 1) ifFalse: [
		self error: 'wrong number of block arguments'.
	].
	iterationVar := msgNode args last args first.
	aStream nextPutAll: 'for (', iterationVar, ' = '.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: '; ', iterationVar.
	negative := ((step := msgNode args at: 2) isConstant and: [step value < 0])
				or: [step isSend and: [step selector == #negated
					and: [step receiver isConstant and: [step receiver value >= 0]]]].
	aStream nextPutAll: (negative ifTrue: [' >= '] ifFalse: [' <= ']).
	self emitCExpression: msgNode args first on: aStream.
	aStream nextPutAll: '; ', iterationVar, ' += '.
	self emitCExpression: step on: aStream.
	aStream nextPutAll: ') {'; cr.
	msgNode args last emitCCodeOn: aStream level: level + 1 generator: self.
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '}'.
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
	aStream nextPutAll: '; ', iterationVar, ' <= '.
	self emitCExpression: msgNode args first on: aStream.
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
CCodeGenerator >> generateValue: aTSendNode on: aStream indent: level [
	"Reduce [:formal ... :formalN| body ] value: actual ... value: actualN
	 to body with formals substituted for by actuals."
	| substitution substitutionDict |
	self assert: aTSendNode receiver isStmtList.
	self assert: aTSendNode receiver args size = aTSendNode args size.
	substitution := aTSendNode receiver copy.
	substitutionDict := Dictionary new: aTSendNode args size * 2.
	aTSendNode receiver args with: aTSendNode args do:
		[ :argName :exprNode |
		substitutionDict at: argName put: exprNode].
	substitution
		bindVariablesIn: substitutionDict;
		emitCCodeOn: aStream level: level generator: self
]

{ #category : #'C translation' }
CCodeGenerator >> generateWhileFalse: msgNode on: aStream indent: level [
	"Generate C code for a loop in one of the following formats, as appropriate:
		while(!(cond)) { stmtList }
		do {stmtList} while(!(cond))
		while(1) {stmtListA; if (cond) break; stmtListB}"

	msgNode receiver statements size <= 1
		ifTrue: [^self generateWhileFalseLoop: msgNode on: aStream indent: level].
	msgNode args first isNilStmtListNode
		ifTrue: [^self generateDoWhileFalse: msgNode on: aStream indent: level].
	^self generateWhileForeverBreakTrueLoop: msgNode on: aStream indent: level
]

{ #category : #'C translation' }
CCodeGenerator >> generateWhileFalseLoop: msgNode on: aStream indent: level [
	"Generate while(!(cond)) {stmtList}."

	aStream nextPutAll: 'while (!('.
	self emitCTestBlock: msgNode receiver on: aStream indent: level.
	aStream nextPutAll: ')) {'; cr.
	msgNode args first isNilStmtListNode ifFalse:
		[msgNode args first emitCCodeOn: aStream level: level + 1 generator: self].
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '}'.
]

{ #category : #'C translation' }
CCodeGenerator >> generateWhileForeverBreakFalseLoop: msgNode on: aStream indent: level [
	"Generate while(1) {stmtListA; if(!(cond)) break; stmtListB}."

	| stmts testStmt |
	stmts := msgNode receiver statements asOrderedCollection.
	testStmt := stmts removeLast.
	msgNode receiver setStatements: stmts.
	level - 1 timesRepeat: [ aStream tab ].
	aStream nextPutAll: 'while (1) {'; cr.
	msgNode receiver emitCCodeOn: aStream level: level + 1 generator: self.
	(level + 1) timesRepeat: [ aStream tab ].
	aStream nextPutAll: 'if (!('.
	testStmt emitCCodeOn: aStream level: 0 generator: self.
	aStream nextPutAll: ')) break;'; cr.
	msgNode args first emitCCodeOn: aStream level: level + 1 generator: self.
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '}'.
]

{ #category : #'C translation' }
CCodeGenerator >> generateWhileForeverBreakTrueLoop: msgNode on: aStream indent: level [
	"Generate while(1) {stmtListA; if(cond) break; stmtListB}."

	| stmts testStmt |
	stmts := msgNode receiver statements asOrderedCollection.
	testStmt := stmts removeLast.
	msgNode receiver setStatements: stmts.
	level - 1 timesRepeat: [ aStream tab ].
	aStream nextPutAll: 'while (1) {'; cr.
	msgNode receiver emitCCodeOn: aStream level: level + 1 generator: self.
	(level + 1) timesRepeat: [ aStream tab ].
	aStream nextPutAll: 'if ('.
	testStmt emitCCodeOn: aStream level: 0 generator: self.
	aStream nextPutAll: ') break;'; cr.
	msgNode args first emitCCodeOn: aStream level: level + 1 generator: self.
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '}'.
]

{ #category : #'C translation' }
CCodeGenerator >> generateWhileTrue: msgNode on: aStream indent: level [
	"Generate C code for a loop in one of the following formats, as appropriate:
		while(cond) { stmtList }
		do {stmtList} while(cond)
		while(1) {stmtListA; if (!(cond)) break; stmtListB}"

	msgNode receiver statements size <= 1
		ifTrue: [^self generateWhileTrueLoop: msgNode on: aStream indent: level].
	msgNode args first isNilStmtListNode
		ifTrue: [^self generateDoWhileTrue: msgNode on: aStream indent: level].
	^self generateWhileForeverBreakFalseLoop: msgNode on: aStream indent: level
]

{ #category : #'C translation' }
CCodeGenerator >> generateWhileTrueLoop: msgNode on: aStream indent: level [
	"Generate while(cond) {stmtList}."

	aStream nextPutAll: 'while ('.
	self emitCTestBlock: msgNode receiver on: aStream indent: level.
	aStream nextPutAll: ') {'; cr.
	msgNode args first isNilStmtListNode ifFalse:
		[msgNode args first emitCCodeOn: aStream level: level + 1 generator: self].
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '}'.
]

{ #category : #public }
CCodeGenerator >> globalsAsSet [
	"Used by the inliner to avoid name clashes with global variables."

	^variables
]

{ #category : #public }
CCodeGenerator >> initialize [
	translationDict := Dictionary new.
	inlineList := Array new.
	constants := Dictionary new: 100.
	variables := Set new: 100.
	variableDeclarations := Dictionary new: 100.
	methods := Dictionary new: 500.
	macros := Dictionary new.
	self initializeCTranslationDictionary.
	headerFiles := OrderedCollection new.
	globalVariableUsage := Dictionary new.
	useSymbolicConstants := true.
	generateDeadCode := true.
	scopeStack := OrderedCollection new.
	logger := (ProvideAnswerNotification new tag: #logger; signal) ifNil: [Transcript].
	pools := IdentitySet new.
	selectorTranslations := IdentityDictionary new
]

{ #category : #'C translation' }
CCodeGenerator >> initializeCTranslationDictionary [ 
	"Initialize the dictionary mapping message names to actions for C code generation."

	| pairs |
	translationDict := Dictionary new: 200.
	pairs := #(
	#&				#generateAnd:on:indent:
	#|				#generateOr:on:indent:
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
	#min:			#generateMin:on:indent:
	#max:			#generateMax:on:indent:
	#between:and:	#generateBetweenAnd:on:indent:

	#bitAnd:			#generateBitAnd:on:indent:
	#bitOr:				#generateBitOr:on:indent:
	#bitXor:			#generateBitXor:on:indent:
	#bitShift:			#generateBitShift:on:indent:
	#signedBitShift:	#generateSignedBitShift:on:indent:
	#bitInvert32		#generateBitInvert32:on:indent:
	#bitClear:			#generateBitClear:on:indent:

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
	#signedIntFromLong		#generateSignedIntFromLong:on:indent:
	#signedIntToLong			#generateSignedIntToLong:on:indent:
	#signedIntFromShort		#generateSignedIntFromShort:on:indent:
	#signedIntToShort			#generateSignedIntToShort:on:indent:
	#preIncrement				#generatePreIncrement:on:indent:
	#preDecrement			#generatePreDecrement:on:indent:
	#inline:						#generateInlineDirective:on:indent:
	#asFloat					#generateAsFloat:on:indent:
	#asInteger					#generateAsInteger:on:indent:
	#asUnsignedInteger		#generateAsUnsignedInteger:on:indent:
	#asSymbol					#generateAsSymbol:on:indent:
	#anyMask:					#generateBitAnd:on:indent:
	#raisedTo:					#generateRaisedTo:on:indent:
	#touch:						#generateTouch:on:indent:

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

	#shouldNotImplement				#generateSmalltalkMetaError:on:indent:
	#shouldBeImplemented			#generateSmalltalkMetaError:on:indent:
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
	).

	asArgumentTranslationDict := Dictionary new: 8.
	1 to: pairs size by: 2 do: [:i |
		asArgumentTranslationDict at: (pairs at: i) put: (pairs at: i + 1)].

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

{ #category : #'C code generator' }
CCodeGenerator >> isCLiteral: anObject [
	(anObject isKindOf: Integer) ifTrue: [^true].
	(anObject isKindOf: String) ifTrue: [^true].
	(anObject isKindOf: Float) ifTrue: [^true].
	anObject == nil ifTrue: [^true].
	anObject == true ifTrue: [^true].			"ikp"
	anObject == false ifTrue: [^true].			"ikp"
	(anObject isKindOf: Character) ifTrue:[^true]. "ar"
	^false
]

{ #category : #inlining }
CCodeGenerator >> isFloatingPointCType: aCType [ "<String>"
	^#('float' 'double' 'long double') includes: aCType asString
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
	^(#('sqLong' 'usqLong' 'sqInt' 'usqInt'
		'long' 'int' 'short' 'char' 'signed char'
		'size_t' 'pid_t') includes: aCType asString)
	or: [(aCType beginsWith: 'unsigned') "Accept e.g. 'unsigned long' and also 'unsigned  : 8'"
		and: [(aCType includesAnyOf: '[*]') not]]
]

{ #category : #utilities }
CCodeGenerator >> isNilConstantReceiverOf: sendNode [
	"Answer true if the receiver of the given message send is the constant nil. Used to suppress conditional code when the condition is a translation-time constant."

	generateDeadCode ifTrue: [^false].
	^sendNode receiver isConstant and: [sendNode receiver value isNil]
]

{ #category : #'C code generator' }
CCodeGenerator >> isNonArgumentImplicitReceiverVariableName: aString [
	^(self typeOfVariable: aString) == #implicit
	    or: [vmClass
			ifNil: [#('interpreterProxy' 'self') includes: aString]
	 		ifNotNil: [vmClass isNonArgumentImplicitReceiverVariableName: aString]]
]

{ #category : #inlining }
CCodeGenerator >> isVoidPointer: aCType [ "<String>"
	"sigh..."
	^#('void *' 'void*') includes: aCType asString
]

{ #category : #utilities }
CCodeGenerator >> localizeGlobalVariables [
	| candidates elected |

	"find all globals used in only one method"
	candidates := globalVariableUsage select: [:e | e size = 1].
	(candidates keys select: [:k| vmClass mustBeGlobal: k]) do:
		[:k| candidates removeKey: k].
	elected := Set new.

	"move any suitable global to be local to the single method using it"
	candidates keysAndValuesDo:
		[:key :targets | 
		targets do:
			[:name | | procedure |
			procedure := methods at: name.
			procedure isRealMethod ifTrue:
				[logger notNil ifTrue:
					[logger ensureCr; show: key, ' localised to ', name; cr].
				elected add: (procedure locals add: key).
				variableDeclarations at: key ifPresent:
					[:v |
					procedure declarationAt: key put: v.
					variableDeclarations removeKey: key]]]].
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
	"Answer true if the method with the given selector may be inlined."

	^sel ~~ #assert: and: [inlineList includes: sel]
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
CCodeGenerator >> monticelloDescriptionFor: aClass [
	"Answer a suitable Monticello package stamp to include in the header."
	| pkgInfo pkg uuid |
	pkgInfo := PackageOrganizer default packageOfClass: aClass.
	pkg := MCWorkingCopy allManagers detect: [:ea| ea packageName = pkgInfo packageName].
	pkg ancestry ancestors isEmpty ifFalse:
		[uuid := pkg ancestry ancestors first id].
	^aClass name, (pkg modified ifTrue: [' * '] ifFalse: [' ']), pkg ancestry ancestorString, ' uuid: ', uuid asString
]

{ #category : #'C code generator' }
CCodeGenerator >> needToGenerateHeader: headerName file: interpHdrPath contents: newContentsArg [
	"Check if we need to regenerate a header file.  We always need to if the contents have changed.
	 But if not we can avoid needless recompilations by not regenerating.  So only regenerate if the
	 package is clean (version doesn't include a '*').  If we can't find a package version ask the user."
	| newContents oldContents |
	(FileDirectory default fileExists: interpHdrPath) ifFalse:
		[^true].
	newContents := newContentsArg.
	oldContents := (FileDirectory default oldFileNamed: interpHdrPath) contentsOfEntireFile.
	(newContents beginsWith: '/*') = (oldContents beginsWith: '/*') ifFalse:
		[(newContents beginsWith: '/*') ifTrue:
			[newContents := newContents readStream upToAll: '*/'; skipSeparators; upToEnd].
		 (oldContents beginsWith: '/*') ifTrue:
			[oldContents := oldContents readStream upToAll: '*/'; skipSeparators; upToEnd]].
	oldContents := oldContents copyReplaceAll: {Character cr. Character lf} with: {Character cr}.
	oldContents replaceAll: Character lf with: Character cr.
	^oldContents ~= newContents
	 or: [[((self monticelloDescriptionFor: vmClass) includes: $*) not]
			on: Error
			do: [:ex|
				self confirm: headerName, ' contents are unchanged.\Writing the file may cause recompilation of support files.\Do you want to write the header file?\The interpreter will still be written either way.' withCRs]]
]

{ #category : #utilities }
CCodeGenerator >> nilOrBooleanConstantReceiverOf: sendNode [
	"Answer nil or the boolean constant that is the receiver of the given message send. Used to suppress conditional code when the condition is a translation-time constant."

	| rcvr val |
	generateDeadCode ifTrue:[^nil].
	rcvr := sendNode receiver.
	rcvr isConstant ifTrue: [
		val := rcvr value.
		((val == true) or: [val == false]) ifTrue: [^ val]].
	^ nil

]

{ #category : #utilities }
CCodeGenerator >> outputAsmLabel: selector on: aStream [
	| count |
	asmLabelCounts isNil ifTrue:
		[asmLabelCounts := Dictionary new].
	count := asmLabelCounts
				at: selector
				put: 1 + (asmLabelCounts at: selector ifAbsent: [-1]).
	 aStream
		nextPutAll: 'VM_LABEL(';
		print: count;
		nextPutAll: (self cFunctionNameFor: selector);
		nextPut: $);
		nextPut: $;
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
				[self error: 'Local variable name may mask global when inlining: ' , var].
			((methods at: var ifAbsent: [nil]) ifNil: [false] ifNotNil: [:m1| m1 isStructAccessor not]) ifTrue:
				[logger
					ensureCr;
					nextPutAll: 'Local variable name ', var, ' in ';
					nextPutAll: m selector;
					nextPutAll: ' may mask method when inlining: ' , var]].
		m bindClassVariablesIn: constants.
		m prepareMethodIn: self]
]

{ #category : #private }
CCodeGenerator >> printArray: array on: aStream [
	| first |
	first := true.
	1 to: array size do:
		[:i |
		first 
			ifTrue: [first := false]
			ifFalse: [aStream nextPutAll: ', '].
		i \\ 16 = 1 ifTrue: [aStream cr].
		self printInt: (array at: i) on: aStream]
]

{ #category : #private }
CCodeGenerator >> printInt: int on: aStream [
	aStream print: int.
	(int between: -2147483648 and: 2147483647)
		ifFalse: [(int between: 2147483648 and: 4294967295)
			ifTrue: [aStream nextPut: $U]
			ifFalse: [aStream nextPut: $L]]
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

{ #category : #inlining }
CCodeGenerator >> pruneMethods: selectorList [
	"Explicitly prune some methods"
	selectorList do: [:sel| self removeMethodForSelector: sel]
]

{ #category : #inlining }
CCodeGenerator >> pruneUnreachableMethods [
	"Remove any methods that are not reachable. Retain methods needed by the translated classes - see implementors of requiredMethodNames"
 	
	| newMethods previousSize visited |
	"add all the exported methods and all the called methods to the requiredSelectors"
	"keep all the fake methods (macros and struct accessors; these are needed
	 to ensure correct code generation."

	methods do: [ :m |
		m export ifTrue:
			[requiredSelectors add: m selector].
		m isRealMethod ifFalse:
			[requiredSelectors add: m selector]].

	"Now compute the transitive closure..."
	previousSize := requiredSelectors size.
	visited := IdentitySet new: methods size.
	[requiredSelectors do:
		[:s|
		(methods at: s ifAbsent: []) ifNotNil:
			[:m|
			(visited includes: m) ifFalse:
				[visited add: m.
				 m isRealMethod ifTrue:
					[requiredSelectors addAll: m allCalls]]]].
	 requiredSelectors size > previousSize]
		whileTrue:
			[previousSize := requiredSelectors size].

	"build a new dictionary of methods from the collection of all the ones to keep"			
	newMethods := Dictionary new: requiredSelectors size.
	requiredSelectors do:
		[:sel|
		methods at: sel ifPresent:[:meth| newMethods at: sel put: meth]].
	methods := newMethods
]

{ #category : #'C code generator' }
CCodeGenerator >> pushScope: variableToType "<Dictionary>" while: aBlock [
	scopeStack addLast: variableToType.
	^aBlock ensure: [scopeStack removeLast]
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

{ #category : #public }
CCodeGenerator >> removeUnneededBuiltins [
	| toRemove |
	toRemove := Set new: 64.
	methods keysDo:
		[:sel|
		(self builtin: sel) ifTrue:
			[(requiredSelectors includes: sel) ifFalse:
				[toRemove add: sel]]].
	toRemove do:
		[:sel| self removeMethodForSelector: sel]
]

{ #category : #utilities }
CCodeGenerator >> removeVariable: aName [
	"Remove the given (instance) variable from the code base."
	self checkDeleteVariable: aName.
	variables
		remove: aName
		ifAbsent:
			[(vmClass notNil
			  and: [vmClass isNonArgumentImplicitReceiverVariableName: aName]) ifFalse:
				[logger
					ensureCr;
					show: 'warning, variable '
						, aName
						, ' doesn''t exist or has already been removed';
						cr]].
	variableDeclarations removeKey: aName ifAbsent: []
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

{ #category : #accessing }
CCodeGenerator >> selectAPIMethods [
	^methods select: [:m| m isAPIMethod]
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

{ #category : #utilities }
CCodeGenerator >> selectorsAndMethodsDo: aBinaryBlock [
	methods keysAndValuesDo: aBinaryBlock
]

{ #category : #'C code generator' }
CCodeGenerator >> shortMonticelloDescriptionForClass: aClass [
	"Answer a suitable Monticello package stamp to include in a moduleName."
	| mdesc |
	mdesc := [self monticelloDescriptionFor: aClass]
				on: Error
				do: [:ex| ^' ', Date today asString].
	^mdesc copyFrom: 1 to: (mdesc indexOfSubCollection: ' uuid:') - 1
]

{ #category : #inlining }
CCodeGenerator >> sizeOfIntegralCType: anIntegralCType [ "<String>"
	"N.B. Only works for values for which isIntegralCType: answers true."
	| prunedCType index |
	prunedCType := (anIntegralCType beginsWith: 'unsigned ')
						ifTrue: [(anIntegralCType allButFirst: 9) withBlanksTrimmed]
						ifFalse: [(anIntegralCType beginsWith: 'signed ')
									ifTrue: [(anIntegralCType allButFirst: 7) withBlanksTrimmed]
									ifFalse: [anIntegralCType]].
	^prunedCType asString caseOf: {
		['sqLong']	->	[8].
		['usqLong']	->	[8].
		['sqInt']		->	[BytesPerWord].
		['usqInt']	->	[BytesPerWord].
		['int']		->	[4].
		['short']		->	[2].
		['char']		->	[1].
		['long']		->	[BytesPerWord].
		['size_t']		->	[BytesPerWord].
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
	 for asSortedCollection and if sort order changes, generated code changes too."
	^aTMethodCollection asSortedCollection:
		[:a :b| a selector caseSensitiveLessOrEqual: b selector]
]

{ #category : #utilities }
CCodeGenerator >> sortStrings: aStringOrSymbolCollection [
	"We need to define this since different Squeak versions answer different results
	 for asSortedCollection and if sort order changes, generated code changes too."
	^aStringOrSymbolCollection asSortedCollection: [:a :b| a caseSensitiveLessOrEqual: b]
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
CCodeGenerator >> storeHeaderOnFile: fileName bytesPerWord: bytesPerWord [
	"Store C header code for this interpreter on the given file."

	| aStream |
	aStream := VMMaker forceNewFileNamed: fileName.
	aStream ifNil: [Error signal: 'Could not open C header file: ', fileName].
	aStream
		nextPutAll: '/* ';
		nextPutAll: VMMaker headerNotice;
		nextPutAll: ' */'; cr; cr.
	self writeDefineBytesPerWord: bytesPerWord on: aStream.
	self writeDefineMemoryAccessInImageOn: aStream.
	self writeDefaultMacrosOn: aStream.
	aStream close
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

{ #category : #utilities }
CCodeGenerator >> structClassesForTranslationClasses: classes [
	"Answer in superclass order (any superclass precedes any subclass) the ancilliaryStructClasses for all the given classes."
	| structClasses |

	structClasses := Set new.
	classes do:
		[:aTranslationClass|
		structClasses addAll:
			([aTranslationClass ancilliaryStructClasses]
				on: MessageNotUnderstood
				do: [:ex|
					ex message selector == #ancilliaryStructClasses
						ifTrue: [#()]
						ifFalse: [ex pass]])].
	^ChangeSet superclassOrder: structClasses asArray
]

{ #category : #'C code generator' }
CCodeGenerator >> structTargetKindForVariableName: varName [ "<String>"
	^VMStructType structTargetKindForDeclaration: (self typeOfVariable: varName)
]

{ #category : #utilities }
CCodeGenerator >> translationMethodClass [
	"return the class used to produce C translation methods from MethodNodes"
	^TMethod
]

{ #category : #'C code generator' }
CCodeGenerator >> typeOfVariable: varName [ "<String>" 
	scopeStack reverseDo:
		[:dict|
		(dict includesKey: varName) ifTrue:
			[^dict at: varName]].
	^variableDeclarations at: varName ifAbsent: nil
]

{ #category : #utilities }
CCodeGenerator >> unreachableMethods [
	"Return a collection of methods that are never invoked."

	| sent out |
	sent := Set new.
	methods do: [ :m |
		m export ifTrue:[sent add: m selector].
		sent addAll: m allCalls.
	].

	out := OrderedCollection new.
	methods keys do: [ :sel |
		(sent includes: sel) ifFalse: [ out add: sel ].
	].
	^ out
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

	(declarationString includesSubString: varName) ifFalse:
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
CCodeGenerator >> var: varName type: type array: array [
"use this in preference to #var:declareC: when possible. This produces a C statment of the form
int * fooArray[]={1,2,3}
See also #var:type: for simple var decls" 
	self
		var: varName
		declareC: (String streamContents: [:s |
			s nextPutAll: type.
			s space.
			s nextPutAll: varName.
			s nextPutAll: '[] = {'.
			self printArray: array on: s.
			s nextPut: $}])
]

{ #category : #inlining }
CCodeGenerator >> variableOfType: variableType acceptsValueOfType: expressionType [
	"Simple type checking for assignment/return values"

	^variableType isNil "means as yet untyped, hence can adapt"
	  or: [expressionType isNil "means we don't know.  Potentially dangerous to say yes, but Slang is traditionally lax :("
	  or: [variableType = expressionType
	  or: [variableType notNil
		 and: [(variableType includes: $*)
				ifTrue:
					 [expressionType last = $*
					   and: [(self isVoidPointer: variableType)
							or: [self isVoidPointer: expressionType]]]
				ifFalse: "Require a cast if assigning integral with floating-point but not the other way around"
					[((self isIntegralCType: variableType)
					   and: [(self isIntegralCType: expressionType)
					   and: [(self sizeOfIntegralCType: variableType) >= (self sizeOfIntegralCType: expressionType)]])
					or: [(self isFloatingPointCType: variableType)
						and: [(self isFloatingPointCType: expressionType)
							or: [self isIntegralCType: expressionType]]]]]]]]
]

{ #category : #public }
CCodeGenerator >> vmClass [
	"Answer the interpreter classs if any.  This is nil other than for the core VM."
	^vmClass
]

{ #category : #public }
CCodeGenerator >> vmClass: aClass [
	"Set the interpreter class if any.  This is nil other than for the core VM."
	vmClass := aClass
]

{ #category : #public }
CCodeGenerator >> vmHeaderContentsWithBytesPerWord: bytesPerWord [
	"Store C header code on the given stream."

	^ByteString streamContents:
		[:tempStream|
		vmClass writeVMHeaderTo: tempStream bytesPerWord: bytesPerWord]
]

{ #category : #utilities }
CCodeGenerator >> wantsLabels [
	"Only label the VM, not plugins (internal or external).  This to cut down the scope
	 of problems with labels being duplicated by C compiler optimizer inlining and
	 loop unrolling.  We use the asmLabel: directive to control labelling in the
	 interpreter proper. But it is too much work doing that for plugins too."
	^vmClass notNil and: [vmClass wantsLabels]
]

{ #category : #public }
CCodeGenerator >> writeDefaultMacrosOn: aStream [
	"Write macros to provide default implementations of certain functions used by
	the interpreter. If not previously defined in config.h they will be defined here.
	The definitions will be available to any module that includes sqMemoryAccess.h.
	The default macros are chosen for backward compatibility with existing platform
	support code."

	aStream cr;
		nextPutAll: '#ifndef allocateMemoryMinimumImageFileHeaderSize'; cr;
		nextPutAll: ' /* Called by Interpreter>>allocateMemory:minimum:imageFile:headerSize: */'; cr;
		nextPutAll: ' #define allocateMemoryMinimumImageFileHeaderSize(',
						'heapSize, minimumMemory, fileStream, headerSize) \'; cr;
		nextPutAll: '    sqAllocateMemory(minimumMemory, heapSize)'; cr;
		nextPutAll: '#endif'; cr; cr;
		nextPutAll: '#ifndef sqImageFileReadEntireImage'; cr;
		nextPutAll: ' /* Called by Interpreter>>sqImage:read:size:length: */'; cr;
		nextPutAll: ' #define sqImageFileReadEntireImage(memoryAddress, fileStream, ',
						'elementSize,  length) \'; cr;
		nextPutAll: '    sqImageFileRead(memoryAddress, fileStream, elementSize,  length)'; cr;
		nextPutAll: '#endif'; cr; cr

]

{ #category : #public }
CCodeGenerator >> writeDefineBytesPerWord: bytesPerWord on: aStream [
	aStream
		nextPutAll: '#define SQ_VI_BYTES_PER_WORD ';
		print: bytesPerWord;
		cr

]

{ #category : #public }
CCodeGenerator >> writeDefineMemoryAccessInImageOn: aStream [
	"If MemoryAccess is present in the image, then define MEMORY_ACCESS_IN_IMAGE as
	a C preprocessor macro. When MEMORY_ACCESS_IN_IMAGE is defined, the traditional
	C preprocessor macros for low level memory access are ignored and will be replaced
	by directly translated (and inlined) SLANG versions of the same. This enables visibility
	of the memory access functions for debuggers and profilers."

	(Smalltalk classNamed: #MemoryAccess)
		ifNotNilDo: [:ma | ma isEnabled
			ifTrue: [aStream nextPutAll: '#define MEMORY_ACCESS_IN_IMAGE 1'; cr]]

]
