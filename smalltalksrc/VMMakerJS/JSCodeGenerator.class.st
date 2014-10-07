"
This class is a copy of CCodeGenerator hacked to generate JavaScript instead of C for use with the SqueakJS virtual machine.

C and JS semantics are pretty close except for pointers, types, and divide/modulo/shift operations. 
"
Class {
	#name : #JSCodeGenerator,
	#superclass : #Object,
	#instVars : [
		'translationDict',
		'inlineList',
		'constants',
		'variables',
		'variableDeclarations',
		'scopeStack',
		'methods',
		'macros',
		'preparedMethodList',
		'variablesSetCache',
		'headerFiles',
		'globalVariableUsage',
		'useSymbolicConstants',
		'generateDeadCode',
		'doNotRemoveMethodList',
		'asArgumentTranslationDict',
		'receiverDict',
		'vmClass',
		'currentMethod',
		'logger',
		'declareMethodsStatic',
		'permitMethodPruning',
		'pools',
		'abstractDeclarations',
		'uncheckedAbstractMethods',
		'cCodeTranslationDict',
		'oneBasedArrays'
	],
	#classVars : [
		'IsActive',
		'UseRightShiftForDivide'
	],
	#category : #'VMMakerJS-Translation to JS'
}

{ #category : #'class initialization' }
JSCodeGenerator class >> initialize [
	"JSCodeGenerator initialize"

	UseRightShiftForDivide := true.
		"If UseRightShiftForDivide is true, the translator will generate a right-shift when it encounters a division by a constant that is a small power of two. For example, 'x / 8' will generate '((int) x >> 3)'. The coercion to int is done to make it clear that the C compiler should generate a signed shift."
		"Note: The Kernighan and Ritchie 2nd Edition C manual, p. 49, leaves the semantics of right-shifting a negative number open to the discretion of the compiler implementor. However, it strongly suggests that most compilers should generate an arithmetic right shift (i.e., shifting in the sign bit), which is the same as dividing by a power of two. If your compiler does not generate or simulate an arithmetic shift, then make this class variable false and re-translate."

]

{ #category : #preferences }
JSCodeGenerator class >> isActive [
	"should I be used instead of CCodeGenerator?"
	^IsActive == true
]

{ #category : #preferences }
JSCodeGenerator class >> isActive: aBoolean [
	"should I be used instead of CCodeGenerator?"
	IsActive := aBoolean
]

{ #category : #'JS code generator' }
JSCodeGenerator class >> monticelloDescriptionFor: aClass [
	"Answer a suitable Monticello package stamp to include in the header."
	| pkgInfo pkg uuid |
	pkgInfo := PackageOrganizer default packageOfClass: aClass.
	pkg := MCWorkingCopy allManagers detect: [:ea| ea packageName = pkgInfo packageName].
	pkg ancestry ancestors isEmpty ifFalse:
		[uuid := pkg ancestry ancestors first id].
	^aClass name, (pkg modified ifTrue: [' * '] ifFalse: [' ']), pkg ancestry ancestorString, ' uuid: ', uuid asString
]

{ #category : #'removing from system' }
JSCodeGenerator class >> removeCompilerMethods [
	"Before removing the C code generator classes from the system, use this method to remove the compiler node methods that support it. This avoids leaving dangling references to C code generator classes in the compiler node classes."

	ParseNode withAllSubclasses do: [ :nodeClass |
		nodeClass removeCategory: 'C translation'.
	].
	Smalltalk at: #AbstractSound ifPresent: [:abstractSound |
		 abstractSound class removeCategory: 'primitive generation'].

]

{ #category : #public }
JSCodeGenerator >> addAllClassVarsFor: aClass [
	"Add the class variables for the given class (and its superclasses) to the code base as constants."

	| allClasses |
	allClasses := aClass withAllSuperclasses.
	allClasses do: [:c | self addClassVarsFor: c].

]

{ #category : #public }
JSCodeGenerator >> addClass: aClass [
	"Add the variables and methods of the given class to the code base."

	aClass prepareToBeAddedToCodeGenerator: self.
	self checkClassForNameConflicts: aClass.
	self addClassVarsFor: aClass.
	"ikp..."
	self addPoolVarsFor: aClass.
	variables addAll: aClass instVarNames.
	self retainMethods: aClass requiredMethodNames.

	"The identity of the translated class is kept in vmClass for use in identifying the
	translated source. Unless otherwise overridden, the first class to be added to the
	code generator will provide this identifier."
	vmClass ifNil: [self vmClass: aClass].
	'Adding Class ' , aClass name , '...'
		displayProgressAt: Sensor cursorPoint
		from: 0
		to: aClass selectors size
		during:
			[:bar |
			 aClass selectors doWithIndex: [:sel :i |
				bar value: i.
				self addMethodFor: aClass selector: sel]].
	aClass declareCVarsIn: self
]

{ #category : #composition }
JSCodeGenerator >> addClass: aClass selectorPrefix: prefix [
	"Incorporate the methods of aClass, and rename with prefixes reflecting the
	variable name. This is a simple transformation intended to support MemoryAccess,
	with renaming to avoid conflict with standard sqMemoryAccess.h macros."

	self addClass: aClass.
	aClass selectors do: [:sel |
		self renameSelector: sel
			as: (prefix, '_', sel) asSymbol].

]

{ #category : #composition }
JSCodeGenerator >> addClass: aClass upTo: aSuperclass asInstanceVariable: varName [
	"For an instance variable var in one of the classes that has been added to
	this code generator, assume that an instance of aClass would normally be
	assigned to that variable. Arrange for the methods in aClass and all superclasses
	up to but not including aSuperclass to be incorporated into the generated C source
	module as if they had been methods in the class with instance variable var.
	
	n.b. See #addStructureClass: mechanism in Cog."

	| cls |
	cls := aClass.
	[cls == aSuperclass]
		whileFalse: [self addClass: cls.
				self mapVar: varName asInstanceOf: cls to: 'self'.
				cls := cls superclass]

]

{ #category : #public }
JSCodeGenerator >> addClassVarsFor: aClass [
	"Add the class variables for the given class to the code base as constants."
	| val node |
	aClass classPool associationsDo: [:assoc | 
		val := assoc value.
		(useSymbolicConstants and:[self isJSLiteral: val])
			ifTrue:[node := TDefineNode new setName: assoc key asString value: assoc value]
			ifFalse:[node := TConstantNode new setValue: assoc value].
		constants at: assoc key asString put: node].

]

{ #category : #public }
JSCodeGenerator >> addHeaderFile: aString [
	"Add a header file. The argument must be a quoted string!"
	headerFiles addLast: aString.
]

{ #category : #public }
JSCodeGenerator >> addMacro: aString for: selector [
	"Add a macro. aString must be the macro arguments and body without the leading #define or name"
	macros at: selector put: aString
]

{ #category : #utilities }
JSCodeGenerator >> addMethod: aJSMethod [
	"Add the given method to the code base."

	(methods includesKey:  aJSMethod selector) ifTrue: [
		self error: 'Method name conflict: ', aJSMethod selector.
	].
	methods at: aJSMethod selector put: aJSMethod.
]

{ #category : #utilities }
JSCodeGenerator >> addMethodFor: aClass selector: selector [
	"Add the given method to the code base and answer its translation
	 or nil if it shouldn't be translated."

	| method tmethod |
	method := aClass compiledMethodAt: selector.
	method requiresConcreteImplementation ifTrue: [abstractDeclarations add: selector].
	method isAbstract ifTrue: [^nil].
	(method pragmaAt: #doNotGenerate) ifNotNil: [^nil].
	"process optional methods by interpreting the argument to the option: pragma as either
	 a Cogit class name or a class variable name or a variable name in VMBasicConstants."
	(method pragmaAt: #option:) ifNotNil:
		[:pragma| | key |
		key := pragma argumentAt: 1.
		"((Cogit withAllSubclasses anySatisfy: [:c| c name = key])
		and: [VMClass getVMMaker cogitClassName ~= key]) ifTrue:
			[^nil]."
		(aClass bindingOf: key) ifNotNil:
			[:binding|
			binding value ifFalse: [^nil]].
		(VMBasicConstants bindingOf: key) ifNotNil:
			[:binding|
			binding value ifFalse: [^nil]]].
	tmethod := self compileToJSMethodSelector: selector in: aClass.
	tmethod hasDoNotGenerateStatement ifTrue: [^nil].
	self addMethod: tmethod.
	"If the method has a macro then add the macro.  But keep the method
	 for analysis purposes (e.g. its variable accesses)."
	(method pragmaAt: #cmacro:) ifNotNil:
		[:pragma|
		self addMacro: (pragma argumentAt: 1) for: selector].
	(method propertyValueAt: #cmacro:) ifNotNil:
		[:macro|
		self addMacro: macro for: selector].
	^tmethod
]

{ #category : #public }
JSCodeGenerator >> addMethodsForPrimitives: classAndSelectorList [ 
	| sel aClass source verbose meth |
	classAndSelectorList do:[:classAndSelector | 
		aClass := Smalltalk at: (classAndSelector at: 1) ifAbsent:[nil].
		aClass ifNotNil:[
			self addAllClassVarsFor: aClass.
			"TPR - should pool vars also be added here?"

			"find the method in either the class or the metaclass"
			sel := classAndSelector at: 2.
			(aClass includesSelector: sel)
				ifTrue: [source := aClass sourceCodeAt: sel ifAbsent:[nil]]
				ifFalse: [source := aClass class sourceCodeAt: sel ifAbsent:[nil]].
		].
		source ifNil:[
			Transcript cr; show: 'WARNING: Compiled primitive ', classAndSelector first, '>>', classAndSelector last, ' not present'.
		] ifNotNil:[
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
			self addMethod: meth.
		].
	].
	"method preparation"
	verbose := false.
	self prepareMethods.
	verbose
		ifTrue: 
			[self printUnboundCallWarnings.
			self printUnboundVariableReferenceWarnings.
			Transcript cr].

	"code generation"
	self doInlining: false.

	methods do:[:m|
		"if this method is supposed to be a primitive (rather than a helper 
		routine), add assorted prolog and epilog items"
		m primitive > 0 ifTrue: [m preparePrimitivePrologue].
		"check for one-based array access"	
		m oneBasedArrays ifNotNil: [self oneBasedArrays: true].
	].
]

{ #category : #public }
JSCodeGenerator >> addPoolVarsFor: aClass [ 
	"Add the pool variables for the given class to the code base as constants."

	(aClass sharedPools reject: [:pool| pools includes: pool]) do:
		[:pool |
		pools add: pool.
		pool bindingsDo: [:assoc | | val node |
			val := assoc value.
			node := (useSymbolicConstants and:[self isJSLiteral: val])
						ifTrue:[TDefineNode new setName: assoc key asString value: assoc value]
						ifFalse:[TConstantNode new setValue: assoc value].
			constants at: assoc key asString put: node]].
]

{ #category : #utilities }
JSCodeGenerator >> builtin: sel [ 
	"Answer true if the given selector is one of the builtin selectors."
	^ sel = #error:
		or: [(self memoryAccessSelectors includes: sel)
				or: [translationDict includesKey: sel]]
]

{ #category : #utilities }
JSCodeGenerator >> cCodeForMethod: selector [
	"Answer a string containing the C code for the given method."
	"Example:
		((JSCodeGenerator new initialize addClass: TestCClass1; prepareMethods)
			cCodeForMethod: #ifTests)"

	| m s |
	m := self methodNamed: selector.
	m = nil ifTrue: [ self error: 'method not found in code base: ', selector ].

	s := (ReadWriteStream on: '').
	m emitJSCodeOn: s generator: self.
	^ s contents
]

{ #category : #'error notification' }
JSCodeGenerator >> checkAbstractMethods [
	"For each method that has been declared abstract, ensure that a concrete
	implementation has been provided. This check should be performed prior to
	inlining because methods may be removed during the inlining process."

	| selectors |
	selectors := methods keys, self uncheckedAbstractMethods.
	abstractDeclarations do: [:sel |
		(selectors includes: sel)
			ifFalse: [self notify: 'missing implementation for ', sel]]

]

{ #category : #'error notification' }
JSCodeGenerator >> checkClassForNameConflicts: aClass [
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
		((methods includesKey: sel) and:
			[ | meth |
			meth := aClass compiledMethodAt: sel.
			meth isAbstract not and: [(meth pragmaAt: #doNotGenerate) isNil]]) ifTrue:
				[self error: 'Method ', sel, ' was defined in a previously added class.']]
]

{ #category : #utilities }
JSCodeGenerator >> checkDeleteVariable: aName [
	"Hook for debugging variable deletion."
]

{ #category : #utilities }
JSCodeGenerator >> checkForGlobalUsage: vars in: aJSMethod [ 
	| item |
	vars
		do: [:var | 
			"TPR - why the use of globalsAsSet here instead of globalVariables? 
			JMM - globalVariables is not initialized yet, variables is an OrderedCollection, 
				globalsAsSet returns variables as needed set"
			(self globalsAsSet includes: var)
				ifTrue: ["find the set of method names using this global var"
					item := globalVariableUsage
								at: var
								ifAbsent: [globalVariableUsage at: var put: Set new].
					"add this method name to that set"
					item add: aJSMethod selector]].
	aJSMethod referencesGlobalStructMakeZero
]

{ #category : #private }
JSCodeGenerator >> checkNonPointer: node op: op [
	node isVariable
		ifTrue: [(self typeOfVariable: node name) ifNotNil: [:type |
			(type includes: $*) ifTrue: [self halt: 'cannot do ', op, ' with ', type]]].
]

{ #category : #public }
JSCodeGenerator >> codeString [
	"Return a string containing all the C code for the code base. Used for testing."

	| stream |
	stream := ReadWriteStream on: (String new: 1000).
	self emitJSCodeOn: stream doInlining: true doAssertions: true.
	^stream contents
]

{ #category : #inlining }
JSCodeGenerator >> collectInlineList [
	"Make a list of methods that should be inlined."
	"Details: The method must not include any inline C, since the translator cannot
	currently map variable names in inlined C code. The #inline: directive may be
	used to override this for cases in which the C code or declarations are harmless.
	Methods to be inlined must be small or called from only one place."

	| methodsNotToInline callsOf inlineIt hasCCode nodeCount senderCount
sel |
	methodsNotToInline := Set new: methods size.

	"build dictionary to record the number of calls to each method"
	callsOf := Dictionary new: methods size * 2.
	methods keys do: [ :s | callsOf at: s put: 0 ].

	"For each method, scan its parse tree once to:
		1. determine if the method contains C code or declarations
		2. determine how many nodes it has
		3. increment the sender counts of the methods it calls
		4. determine if it includes any C declarations or code"
	inlineList := Set new: methods size * 2.
	methods do: [ :m |
		inlineIt := #dontCare.
		(translationDict includesKey: m selector) ifTrue: [
			hasCCode := true.
		] ifFalse: [
			hasCCode := m declarations size > 0.
			nodeCount := 0.
			m parseTree nodesDo: [ :node |
				node isSend ifTrue: [
					sel := node selector.
					(sel = #cCode: or: [sel = #cCode:inSmalltalk:])
						ifTrue: [ hasCCode := true ].
					senderCount := callsOf at: sel ifAbsent: [ nil ].
					nil = senderCount ifFalse: [
						callsOf at: sel put: senderCount + 1.
					].
				].
				nodeCount := nodeCount + 1.
			].
			inlineIt := m extractInlineDirective.  "may be true, false, or
#dontCare"
		].
		(inlineIt ~= true and: [hasCCode or: [inlineIt = false]]) ifTrue: [
			"Don't inline if method has C code or if it contains a negative inline
			directive. If it contains a positive inline directive, permit inlining even
			if C code is present."
			methodsNotToInline add: m selector.
		] ifFalse: [
			((nodeCount < 40) or: [inlineIt = true]) ifTrue: [
				"inline if method has no C code and is either small or contains
inline directive"
				inlineList add: m selector.
			].
		].
	].

	callsOf associationsDo: [ :assoc |
		((assoc value = 1) and: [(methodsNotToInline includes: assoc key)
not]) ifTrue: [
			inlineList add: assoc key.
		].
	].
]

{ #category : #utilities }
JSCodeGenerator >> compileToJSMethodSelector: selector in: aClass [
	"Compile a method to a JSMethod"

	^(Compiler new
		parse: (aClass sourceCodeAt: selector)
		in: aClass
		notifying: nil)
			asTranslationMethodOfClass: self translationMethodClass
]

{ #category : #accessing }
JSCodeGenerator >> currentMethod [
	^currentMethod
]

{ #category : #accessing }
JSCodeGenerator >> currentMethod: aJSMethod [
	currentMethod := aJSMethod
]

{ #category : #accessing }
JSCodeGenerator >> declareMethodsStatic [
	"If true generated methods will be declared static. Default is true,
	appropriate for plugins."
	^ declareMethodsStatic
		ifNil: [declareMethodsStatic := true]
]

{ #category : #accessing }
JSCodeGenerator >> declareMethodsStatic: aBoolean [
	"If set false, generated methods will be not declared static.
	Default value is true."
	declareMethodsStatic := aBoolean
]

{ #category : #public }
JSCodeGenerator >> declareModuleName: nameString [
	"add the declaration of a module name, version and local/external tag"

	self var: #moduleName declareC: 'var moduleName = "', nameString,' (e)"'.
]

{ #category : #public }
JSCodeGenerator >> declareVar: varName type: type [
	"This both creates a varable and provides its type"
	self var: (variables add: varName asString) type: type
]

{ #category : #inlining }
JSCodeGenerator >> doBasicInlining: inlineFlag [
	"Inline the bodies of all methods that are suitable for inlining.
	This method does only the basic inlining suitable for both the core VM and plugins - no bytecode inlining etc"

	| pass progress max |
	inlineFlag ifFalse: [^self].
	self collectInlineList.
	pass := 0.
	max := 12. "More than this is probably due to infinite recursion" 
	progress := true.
	[progress] whileTrue: [
		"repeatedly attempt to inline methods until no further progress is made"
		progress := false.
		pass > max
			ifTrue: [self notify: 'too many inlining steps, inlining terminated']
			ifFalse: [('Inlining pass ', (pass := pass + 1) printString, '...')
						displayProgressAt: Sensor cursorPoint
						from: 0 to: methods size
						during: [:bar |
							(self sortMethods: methods) doWithIndex: [:m :i |
								bar value: i.
								currentMethod := m.
								(m tryToInlineMethodsIn: self)
									ifTrue: [progress := true]]]]].


]

{ #category : #inlining }
JSCodeGenerator >> doInlining: inlineFlag [
	"Inline the bodies of all methods that are suitable for inlining."
	"Modified slightly for the core VM translator, since the first level of inlining for the interpret loop must be performed in order that the instruction implementations can easily discover their addresses. Remember to inline the bytecode routines as well"

	inlineFlag ifFalse: [
		self inlineDispatchesInMethodNamed: #interpret localizingVars: #().
		^ self].
	self doBasicInlining: inlineFlag.
	self inlineCaseStatementBranchesInMethodNamed: #interpret localizingVars: #().
	'Inlining bytecodes'
		displayProgressAt: Sensor cursorPoint
		from: 1 to: 2
		during: [:bar |
			self inlineDispatchesInMethodNamed: #interpret
				localizingVars: #(currentBytecode localIP localSP localHomeContext localReturnContext localReturnValue).
			bar value: 1.
			self removeMethodsReferingToGlobals: #(
					currentBytecode localIP localSP localHomeContext)
				except: #(interpret).
			bar value: 2].
	self permitMethodPruning
		ifTrue: [self pruneUnreachableMethods]

]

{ #category : #utilities }
JSCodeGenerator >> emitBuiltinConstructAsArgumentFor: msgNode on: aStream level: level [
	"If the given selector is in the translation dictionary, translate it into a target code construct and return true. Otherwise, do nothing and return false."

	| action |
	action := asArgumentTranslationDict
				at: msgNode selector
				ifAbsent: [translationDict at: msgNode selector ifAbsent: [ ^false ]].
	self perform: action with: msgNode with: aStream with: level.
	^true
]

{ #category : #utilities }
JSCodeGenerator >> emitBuiltinConstructFor: msgNode on: aStream level: level [
	"If the given selector is in the translation dictionary, translate it into a target code construct and return true. Otherwise, do nothing and return false."

	| action |
	action := translationDict at: msgNode selector ifAbsent: [ ^false ].
	self perform: action with: msgNode with: aStream with: level.
	^true
]

{ #category : #'JS code generator' }
JSCodeGenerator >> emitDefineBytesPerWordOn: aStream [
	"Define word size dependent constants. These are mirrored by class
	variables in ObjectMemory. The macro definitions here are used at compile
	time to permit building a VM for either 32-bit or 64-bit object memory from
	a single generated code base.
	
	If SQ_VI_BYTES_PER_WORD is defined as 8 (e.g. in config.h), then a VM for
	64-bit image will be built. Otherwise, a VM for 32-bit image is built."

	aStream cr;
		nextPutAll: '/*'; cr;
		nextPutAll: ' * define SQ_VI_BYTES_PER_WORD 8 for a 64-bit word size VM'; cr;
		nextPutAll: ' * and default to SQ_VI_BYTES_PER_WORD 4 for a 32-bit word size VM'; cr;
		nextPutAll: ' */'; cr;
		nextPutAll: '#ifndef SQ_VI_BYTES_PER_WORD'; cr;
		nextPutAll: '# define SQ_VI_BYTES_PER_WORD ';
		print: 4; cr; "default to word size 4"
		nextPutAll: '#endif'; cr; cr;
		nextPutAll: '#define BYTES_PER_WORD SQ_VI_BYTES_PER_WORD'; cr;
		nextPutAll: '#define BASE_HEADER_SIZE SQ_VI_BYTES_PER_WORD'; cr;

		"Define various constants that depend on BytesPerWord"
		nextPutAll: '#if (BYTES_PER_WORD == 4) // 32-bit object memory'; cr;
		nextPutAll: '# define WORD_MASK 0xffffffff'; cr; "(1 bitShift: BytesPerWord*8) - 1"
		nextPutAll: '# define SHIFT_FOR_WORD 2'; cr; "(BytesPerWord log: 2) rounded"
		nextPutAll: '# define SMALL_CONTEXT_SIZE 92'; cr; "ContextFixedSizePlusHeader + 16 * BytesPerWord"
		"Large contexts have 56 indexable fileds.  Max with single header word."
		"However note that in 64 bits, for now, large contexts have 3-word headers"
		nextPutAll: '# define LARGE_CONTEXT_SIZE 252'; cr; "ContextFixedSizePlusHeader + 56 * BytesPerWord."
		nextPutAll: '# define SIZE_MASK 0xfc'; cr; "Base header word bit field"
		nextPutAll: '# define LONG_SIZE_MASK 0xfffffffc'; cr; "Base header word bit field"
		nextPutAll: '# define SIZE_4_BIT 0'; cr;
		nextPutAll: '# define MARK_BIT 0x80000000'; cr; "Top bit, 1 bitShift: BytesPerWord*8 - 1"
		nextPutAll: '# define ROOT_BIT 0x40000000'; cr; "Next-to-top bit, 1 bitShift: BytesPerWord*8 - 2"
		nextPutAll: '# define ALL_BUT_MARK_BIT 0x7fffffff'; cr; "WordMask - MarkBit."
		nextPutAll: '# define ALL_BUT_ROOT_BIT 0xbfffffff'; cr; "WordMask - RootBit"
		nextPutAll: '# define ALL_BUT_TYPE_MASK 0xfffffffc'; cr; "WordMask - TypeMask"
		nextPutAll: '# define ALL_BUT_MARK_BIT_AND_TYPE_MASK 0x7ffffffc'; cr; "AllButTypeMask - MarkBit"
		nextPutAll: '# define ALL_BUT_HASH_BITS 0xe001ffff'; cr;
		nextPutAll: '# define SMALL_CONTEXT_SIZE 92'; cr; "16 indexable fields"
		nextPutAll: '# define LARGE_CONTEXT_SIZE 252'; cr; "56 indexable fields"

		nextPutAll: '#else // 64-bit object memory'; cr;
		nextPutAll: '# define WORD_MASK 0xffffffffffffffff'; cr;
		nextPutAll: '# define SHIFT_FOR_WORD 3'; cr;
		nextPutAll: '# define SMALL_CONTEXT_SIZE 184'; cr;
		nextPutAll: '# define LARGE_CONTEXT_SIZE 504'; cr;
		nextPutAll: '# define SIZE_MASK 0xf8'; cr; "Lose the 4 bit in temp 64-bit chunk format"
		nextPutAll: '# define LONG_SIZE_MASK 0xfffffffffffffff8'; cr;
		"The 4 bit is excluded from SIZE_MASK for 64-bit object memory, but need it"
		"for ST size, so define SIZE_4_BIT."
		nextPutAll: '# define SIZE_4_BIT 4'; cr;
		nextPutAll: '# define MARK_BIT 0x8000000000000000'; cr;
		nextPutAll: '# define ROOT_BIT 0x4000000000000000'; cr;
		nextPutAll: '# define ALL_BUT_MARK_BIT 0x7fffffffffffffff'; cr;
		nextPutAll: '# define ALL_BUT_ROOT_BIT 0xbfffffffffffffff'; cr;
		nextPutAll: '# define ALL_BUT_TYPE_MASK 0xfffffffffffffffc'; cr;
		nextPutAll: '# define ALL_BUT_MARK_BIT_AND_TYPE_MASK 0x7ffffffffffffffc'; cr;
		nextPutAll: '# define ALL_BUT_HASH_BITS 0xffffffffe001ffff'; cr;
		nextPutAll: '# define SMALL_CONTEXT_SIZE 184'; cr;
		nextPutAll: '# define LARGE_CONTEXT_SIZE 504'; cr;
		nextPutAll: '#endif //  (BYTES_PER_WORD == 4)'; cr
	

]

{ #category : #'JS code generator' }
JSCodeGenerator >> emitDefineMemoryAccessInImageOn: aStream [
	"If MemoryAccess is present in the image, then define MEMORY_ACCESS_IN_IMAGE as
	a C preprocessor macro. When MEMORY_ACCESS_IN_IMAGE is defined, the traditional
	C preprocessor macros for low level memory access are ignored and will be replaced
	by directly translated (and inlined) SLANG versions of the same. This enables visibility
	of the memory access functions for debuggers and profilers."

	(Smalltalk classNamed: #MemoryAccess)
		ifNotNilDo: [:ma | ma isEnabled
			ifTrue: [aStream nextPutAll: '#define MEMORY_ACCESS_IN_IMAGE 1'; cr]]
]

{ #category : #'JS code generator' }
JSCodeGenerator >> emitExportsOn: aStream [
	"Store all the exported primitives in a form to be used by the internal named prim system"
	aStream nextPutAll:'

void* vm_exports[][3] = {'.
	self exportedPrimitiveNames do:[:primName|
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
'.
]

{ #category : #'JS code generator' }
JSCodeGenerator >> emitGlobalStructFlagOn: aStream [
	"Default: do nothing.  Overridden in CCGenGlobalStruct."

]

{ #category : #'JS code generator' }
JSCodeGenerator >> emitJSCodeOn: aStream doAssertions: assertionFlag [
	"Emit C code for all methods in the code base onto the given stream. All inlined method calls should already have been expanded."

	self emitJSHeaderOn: aStream.
	self emitJSTypesOn: aStream.
	self emitJSConstantsOn: aStream.
	self emitJSVariablesOn: aStream.
"'Writing Translated Code...'
displayProgressAt: Sensor cursorPoint
from: 0 to: methods size
during: [:bar |"
	preparedMethodList doWithIndex: [ :m :i | "bar value: i."
		m emitJSCodeOn: aStream generator: self].
"]."
	self emitExportsOn: aStream.

]

{ #category : #'JS code generator' }
JSCodeGenerator >> emitJSCodeOn: aStream doInlining: inlineFlag doAssertions: assertionFlag [
	"Emit C code for all methods in the code base onto the given stream. All inlined method calls should already have been expanded."

	self prepareMethodsInlined: inlineFlag doAssertions: assertionFlag.
	^ self emitJSCodeOn: aStream doAssertions: assertionFlag

]

{ #category : #'JS code generator' }
JSCodeGenerator >> emitJSConstantsOn: aStream [
	"Store the global variable declarations on the given stream."
	| unused constList node |
	unused := constants keys asSet.
	methods do: [ :meth |
		meth parseTree nodesDo: [ :n |
			n isConstant ifTrue: [ unused remove: n name ifAbsent: []]]].
	constList := constants keys reject: [ :any | unused includes: any].
	constList isEmpty ifTrue: [^self].
	aStream nextPutAll: '/*** Constants ***/';
		 cr.
	constList asSortedCollection do: [ :varName |
		node := constants at: varName.
		node name isEmpty ifFalse: [
			aStream nextPutAll: 'var '.
			aStream nextPutAll: node name.
			aStream nextPutAll: ' = '.
			aStream nextPutAll: (self jsLiteralFor: node value).
			aStream nextPut: $;.
			aStream cr
		].
	].
	aStream cr.
]

{ #category : #'JS code generator' }
JSCodeGenerator >> emitJSExpression: aParseNode on: aStream [ 
	"Emit C code for the expression described by the given parse node."

	aParseNode isLeaf 
		ifTrue: 
			["omit parens"
			 aParseNode emitJSCodeAsExpressionOn: aStream level: 0 generator: self]
		ifFalse: 
			[aStream nextPut: $(.
			 aParseNode emitJSCodeAsExpressionOn: aStream level: 0 generator: self.
			 aStream nextPut: $)]
]

{ #category : #'JS code generator' }
JSCodeGenerator >> emitJSHeaderOn: aStream [
	self halt.
]

{ #category : #'JS code generator' }
JSCodeGenerator >> emitJSTestBlock: aBlockNode on: aStream [
	"Emit JS code for the given block node to be used as a loop test."

	aBlockNode statements size > 1 ifTrue: [
		aBlockNode emitJSCodeOn: aStream level: 0 generator: self.
	] ifFalse: [
		aBlockNode statements first asExpression emitJSCodeOn: aStream level: 0 generator: self.
	].
]

{ #category : #'JS code generator' }
JSCodeGenerator >> emitJSTypesOn: aStream [ 
	"Store local type declarations on the given stream."
	vmClass ifNotNil:
		[vmClass ancilliaryStructClasses do:
			[:structClass|
			(vmClass shouldGenerateTypedefFor: structClass) ifTrue:
				[structClass printTypedefOn: aStream.
				 aStream cr; cr]]]
]

{ #category : #'JS code generator' }
JSCodeGenerator >> emitJSVariablesOn: aStream [ 
	"Store the global variable declarations on the given stream."
	aStream nextPutAll: '/*** Variables ***/'; cr.
	variables asSortedCollection
		do: [:var | 	| varString varDecl |
			varString := var asString.
			aStream nextPutAll: 'var ', varString.
			varDecl := variableDeclarations at: varString ifAbsent: [''].
			(varDecl includes: $=)
				ifTrue: [ | const |
					const := ((varDecl copyAfter: $=) replaceAll: ${ with: $[) replaceAll: $} with: $].
					aStream nextPutAll: ' =', const]
				ifFalse: [(varDecl includesAnyOf: '*[')
					ifTrue: [(varDecl includes: $[)
						ifTrue: [ | size |
							size := (varDecl copyAfter: $[) copyUpTo: $].
							size ifEmpty: [self halt].
							aStream nextPutAll: ' = new Array(', size, ')']
						ifFalse: [aStream nextPutAll: ' = null']]
					ifFalse: [aStream nextPutAll: ' = 0']].
			aStream nextPutAll: ';'; cr].
	aStream cr.

]

{ #category : #'JS code generator' }
JSCodeGenerator >> emitVmmVersionOn: aStream [
	"Emit a version string macro suitable for identifying source code version
	of this interpreter. This is expected to be used in conjunction with a similar
	identifier for platform source code version, such the the VM can identify
	the source code version for its platform source and matching VMMaker source."

	aStream nextPutAll: 'var VMMAKER_VERSION = "';
		nextPutAll: VMMaker versionString;
		nextPut: $";
		cr

]

{ #category : #public }
JSCodeGenerator >> exportedPrimitiveNames [
	"Return an array of all exported primitives"
	^methods select:[:m| m export] thenCollect:[:m| m selectorForCodeGeneration copyWithout: $:].

]

{ #category : #'JS code generator' }
JSCodeGenerator >> fileHeaderVersionStampForSourceClass: sourceClass [
	"Answer a suitable version stamp to include in the header."
	|  slangDescription sourceDescription |
	slangDescription := self class monticelloDescriptionFor: self class.
	sourceClass ifNotNil:
		[sourceDescription := [sourceClass monticelloDescription]
								on: MessageNotUnderstood
								do: [:ex| self class monticelloDescriptionFor: sourceClass]].
	^String streamContents:
		[:s|
		s nextPutAll: '/* Automatically generated by\	' withCRs.
		s nextPutAll: slangDescription.
		sourceDescription ifNotNil:
			[s nextPutAll: '\   from\	' withCRs; nextPutAll: (sourceDescription copyReplaceAll: '\' withCRs with: '\	' withCRs)].
		s cr; nextPutAll: ' */'; cr]
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateAbs: msgNode on: aStream indent: level [
	"Generate the JS code for the negated message onto the given stream."

	aStream nextPutAll: 'Math.abs('.
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ')'.

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateAddressOf: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
self halt.
	aStream nextPut: $(; nextPut: $&.
	self emitJSExpression: msgNode args first on: aStream.
	aStream nextPut: $)
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateAnd: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' && '.
	self emitJSExpression: msgNode args first on: aStream.
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateAsFloat: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
	self emitJSExpression: msgNode receiver on: aStream.

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateAsInteger: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
	aStream nextPutAll:'('.
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: '|0)'
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateAsSymbol: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream.
	 The receiver is expected to be a JSConstantNode."

	aStream nextPutAll: (self jsFunctionNameFor: msgNode receiver nameOrValue)
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateAsUnsignedInteger: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
self halt.
	aStream nextPutAll:'((usqInt)'.
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPut: $)
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateAt: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
	| arrayNode indexNode subtractOne complex |
	arrayNode := msgNode receiver.
	indexNode := msgNode args first.
	subtractOne := self isOneBasedArray: arrayNode name in: currentMethod.
	(subtractOne and: [indexNode isPlusOne]) ifTrue: [
		subtractOne := false.
		indexNode := indexNode receiver.	"remove + 1"
	].
	complex := subtractOne and: [indexNode isLeaf not].
	self emitJSExpression: arrayNode on: aStream.
	aStream nextPut: $[.
	complex ifTrue: [aStream nextPut: $(].
	indexNode emitJSCodeAsExpressionOn: aStream level: level + 1 generator: self.
	complex ifTrue: [aStream nextPut: $)].
	subtractOne ifTrue: [aStream nextPutAll: ' - 1'].
	aStream nextPut: $].
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateAtPut: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
	| putExpr incExpr |
	self generateAt: msgNode on: aStream indent: level.

	(putExpr := msgNode args last) isPlusOne ifTrue: [
		((incExpr := putExpr receiver) isSend and: [incExpr selector = #at: and: [
			incExpr receiver asString = msgNode receiver asString and: [
			incExpr args first asString = msgNode args first asString]]])
				ifTrue: [^aStream nextPutAll: '++'.]].

	aStream nextPutAll: ' = '.
	self emitJSExpression: putExpr on: aStream
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateBaseHeaderSize: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
self halt.
	aStream nextPutAll: 'BASE_HEADER_SIZE'


]

{ #category : #'JS translation' }
JSCodeGenerator >> generateBetweenAnd: msgNode on: aStream indent: level [
	"Generate the JS code for the between:and: message onto the given stream."

	aStream nextPutAll: '(('.
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' >= '.
	self emitJSExpression: msgNode args first on: aStream.
	aStream nextPutAll: ') && ('.
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' <= '.
	self emitJSExpression: msgNode args second on: aStream.
	aStream nextPutAll: '))'
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateBitAnd: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' & '.
	self emitJSExpression: msgNode args first on: aStream.
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateBitClear: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	aStream nextPutAll: '(('.
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' | '.
	self emitJSExpression: msgNode args first on: aStream.
	aStream nextPutAll: ') - '.
	self emitJSExpression: msgNode args first on: aStream.
	aStream nextPut: '|0))'
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateBitInvert32: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	aStream nextPut: $~.
	self emitJSExpression: msgNode receiver on: aStream
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateBitOr: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' | '.
	self emitJSExpression: msgNode args first on: aStream.
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateBitShift: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	| arg rcvr |
	arg := msgNode args first.
	rcvr := msgNode receiver.
	arg isConstant ifTrue: [
		"bit shift amount is a constant"
		self emitJSExpression: rcvr on: aStream.
		arg value < 0 ifTrue: [
			aStream nextPutAll: ' >>> ', arg value negated printString.
		] ifFalse: [
			aStream nextPutAll: ' << ', arg value printString.
		].
	] ifFalse: [
		"bit shift amount is an expression"
		aStream nextPutAll: 'SHIFT('.
		self emitJSExpression: rcvr on: aStream.
		aStream nextPutAll: ', '.
		self emitJSExpression: arg on: aStream.
		aStream nextPutAll: ')'.
	].
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateBitXor: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' ^ '.
	self emitJSExpression: msgNode args first on: aStream.
]

{ #category : #'JS hacks' }
JSCodeGenerator >> generateByteAtPointer: msgNode on: aStream indent: level [
	msgNode args first asString = 'sourcePtr + charIndex - 1'
		ifTrue: [^aStream nextPutAll: 'sourcePtr[charIndex - 1]'].
	self halt
	
]

{ #category : #'JS hacks' }
JSCodeGenerator >> generateByteSizeOf: msgNode on: aStream indent: level [
	aStream nextPutAll: 'BYTESIZEOF('.
	msgNode args first emitJSCodeOn: aStream level: level generator: self.
	aStream nextPutAll: ')'.

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateBytesPerWord: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
self halt.
	aStream nextPutAll: 'BYTES_PER_WORD'

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateCCoercion: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
	| expr cType |.
	expr := msgNode args first.
	cType := msgNode args second value.
	(expr isSend and: [expr receiver name = 'interpreterProxy' and: [expr selector = #firstIndexableField:]]) ifTrue: [
		cType := msgNode args second value.
		self emitJSExpression: expr args first on: aStream.
		cType = 'unsigned char *' ifTrue: [^aStream nextPutAll: '.bytes'].
		cType = 'unsigned int *' ifTrue: [^aStream nextPutAll: '.words'].
		cType = 'int *' ifTrue: [^aStream nextPutAll: '.wordsAsInt32Array()'].
		cType = 'short *' ifTrue: [^aStream nextPutAll: '.wordsAsInt16Array()'].
		cType = 'float *' ifTrue: [^aStream nextPutAll: '.wordsAsFloat32Array()'].
		cType = 'double *' ifTrue: [^aStream nextPutAll: '.wordsAsFloat64Array()'].
		self halt.
	] ifFalse: [
		(#('int' 'unsigned int') includes: cType) ifTrue: [
			aStream nextPutAll: '('.
			self emitJSExpression: expr on: aStream.
			^aStream nextPutAll: '|0)'].
		((#('double' 'float') includes: cType) or: ['sqInt (*)(*)'match: cType])
			ifFalse: [self halt].
		self emitJSExpression: expr on: aStream.
	]

]

{ #category : #'JS hacks' }
JSCodeGenerator >> generateCDigitCopy: msgNode on: aStream indent: level [
	"LargeIntegerPlugin>>cDigitReplace:from:to:with:startingAt: uses pointer arithmetic. Replace it here"
	msgNode args first selector = #+ ifFalse: [
		^msgNode emitJSCodeAsFunctionCallOn: aStream level: level generator: self].
	msgNode asString = 'self cDigitCopyFrom: pFrom + repStart to: pTo + start len: stop - start + 1'
		ifFalse: [self halt: 'not handled: ', msgNode asString].
	aStream nextPutAll: 'function() {
		// inlining ', msgNode asString, '
		var len = stop - start + 1;
		for (var i = 0; i < len; i++) {
			pTo[i + start] = pFrom[i + repStart];
		}
		return 0;
	}();
'
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateCos: msgNode on: aStream indent: level [
	"Generate the JS code for the message onto the given stream."

	aStream nextPutAll: 'Math.cos('.
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ')'.

]

{ #category : #accessing }
JSCodeGenerator >> generateDeadCode [
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
JSCodeGenerator >> generateDeadCode: aBool [
	"Indicate whether we should generate 'dead code' branches."
	generateDeadCode := aBool
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateDivide: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	| rcvr arg divisor |
	rcvr := msgNode receiver.
	arg := msgNode args first.
	(msgNode selector == #/ and: [self pluginName = 'ScratchPlugin']) ifTrue: [
		self emitJSExpression: rcvr on: aStream.
		aStream nextPutAll: ' / '.
		^self emitJSExpression: arg on: aStream].
	(arg isConstant and:
	 [UseRightShiftForDivide and:
	 [(divisor := arg value) isInteger and:
	 [divisor isPowerOfTwo and:
	 [divisor > 0 and:
	 [divisor <= (1 bitShift: 31)]]]]])
	ifTrue: [
		"use signed (arithmetic) right shift instead of divide"
		self emitJSExpression: rcvr on: aStream.
		aStream nextPutAll: ' >> ', (divisor log: 2) asInteger printString.
	] ifFalse: [
		"use float divide and coerce to integer"
		aStream nextPutAll: 'DIV('.
		self emitJSExpression: rcvr on: aStream.
		aStream nextPutAll: ', '.
		self emitJSExpression: arg on: aStream.
		aStream nextPutAll: ')'.
	].

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateDoWhileFalse: msgNode on: aStream indent: level [
	"Generate do {stmtList} while(!(cond))"

	| stmts testStmt |
	stmts := msgNode receiver statements asOrderedCollection.
	testStmt := stmts removeLast.
	msgNode receiver setStatements: stmts.
	aStream nextPutAll: 'do {'; cr.
	msgNode receiver emitJSCodeOn: aStream level: level + 1 generator: self.
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '} while(!('.
	testStmt asExpression emitJSCodeOn: aStream level: 0 generator: self.
	aStream nextPutAll: '))'.
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateDoWhileTrue: msgNode on: aStream indent: level [
	"Generate do {stmtList} while(cond)"

	| stmts testStmt |
	stmts := msgNode receiver statements asOrderedCollection.
	testStmt := stmts removeLast.
	msgNode receiver setStatements: stmts.
	aStream nextPutAll: 'do {'; cr.
	msgNode receiver emitJSCodeOn: aStream level: level + 1 generator: self.
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '} while('.
	testStmt asExpression emitJSCodeOn: aStream level: 0 generator: self.
	aStream nextPutAll: ')'.
]

{ #category : #'JS hacks' }
JSCodeGenerator >> generateDstLongAt: msgNode on: aStream indent: level [
	aStream nextPutAll: 'destBits['.
	msgNode args first emitJSCodeAsExpressionOn: aStream level: level generator: self.
	aStream nextPutAll: ' >>> 2]'.
	

]

{ #category : #'JS hacks' }
JSCodeGenerator >> generateDstLongAtPut: msgNode on: aStream indent: level [
	aStream nextPutAll: 'destBits['.
	msgNode args first emitJSCodeAsExpressionOn: aStream level: level generator: self.
	aStream nextPutAll: ' >>> 2] = '.
	msgNode args second emitJSCodeOn: aStream level: level generator: self.
	

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateEqual: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
	| argNode test |
	argNode :=  msgNode args first.
	"quick test for nil, true, false"
	argNode isInterpreterProxyConstant ifTrue: [
		test := #(isNil isTrue isFalse) at: (#(nilObject trueObject falseObject) indexOf: argNode selector).
		self emitJSExpression: msgNode receiver on: aStream.
		^aStream nextPut: $.; nextPutAll: test].
	"cannot compare pointers to 0"
	(argNode isConstantNull or: [argNode isConstantZero and: [self isPointer: msgNode receiver]]) ifTrue: [
		aStream nextPutAll: '!'.
		^self emitJSExpression: msgNode receiver on: aStream].
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' === '.
	self emitJSExpression: argNode on: aStream.
]

{ #category : #'JS hacks' }
JSCodeGenerator >> generateFetchClassOf: msgNode on: aStream indent: level [
	aStream nextPutAll: 'CLASSOF('.
	msgNode args first emitJSCodeOn: aStream level: level generator: self.
	aStream nextPut: $).

]

{ #category : #'JS hacks' }
JSCodeGenerator >> generateFirstIndexableField: msgNode on: aStream indent: level [
	| parent cType accessor |
	self oneBasedArrays: false.
	"HACK: detect cType from parent node"
	parent := thisContext sender sender sender.
	cType := parent method == (TAssignmentNode>>#emitJSCodeOn:level:generator:) 
			ifTrue: [self typeOfVariable: parent receiver variable name] ifFalse: [
		parent method == (TSendNode>>#emitJSCodeAsFunctionCallOn:level:generator:)
			ifTrue: [self typeOfArgument: (parent receiver args indexOf: msgNode) in: parent receiver selector] ifFalse: [
		msgNode asString = 'interpreterProxy firstIndexableField: mapOop'
			ifTrue: ['unsigned int*'] ifFalse: [
		msgNode asString = 'interpreterProxy firstIndexableField: blockOop'
			ifTrue: ['int*'] ifFalse: [
		self halt]]]].
	cType ifNotNil: [
		cType := cType copyReplaceAll: ' *' with: '* '.
		accessor := (cType beginsWith: 'unsigned char*') ifTrue: ['.bytes']
			ifFalse: [(cType beginsWith: 'unsigned int*') ifTrue: ['.words']
			ifFalse: [(cType beginsWith: 'int*') ifTrue: ['.wordsAsInt32Array()']
			ifFalse: [(cType beginsWith: 'char*') ifTrue: ['.bytes']
			ifFalse: [(cType beginsWith: 'float*') ifTrue: ['.wordsAsFloat32Array()']
			ifFalse: [self halt: 'need to handle ', cType]]]]].
		accessor ifNotNil: [msgNode args first emitJSCodeOn: aStream level: level generator: self.
			^aStream nextPutAll: accessor]].
	"generic code below, not needed ever hopefully"
	aStream nextPutAll: 'interpreterProxy.'.
	^ msgNode emitJSCodeAsFunctionCallOn: aStream level: level generator: self
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateGreaterThan: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' > '.
	self emitJSExpression: msgNode args first on: aStream.
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateGreaterThanOrEqual: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' >= '.
	self emitJSExpression: msgNode args first on: aStream.
]

{ #category : #'JS hacks' }
JSCodeGenerator >> generateIdentityUnary: msgNode on: aStream indent: level [
	"ignore this send, just use its value"
	msgNode receiver emitJSCodeOn: aStream level: level generator: self.

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateIfFalse: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode)
		ifNil:
			[aStream nextPutAll: 'if ('.
			self generateNot: (TSendNode new
					setSelector: #not receiver: msgNode receiver arguments: #())
				on: aStream indent: level + 1.
			aStream nextPutAll: ') {'; cr.
			msgNode args last emitJSCodeOn: aStream level: level + 1 generator: self.
			level timesRepeat: [aStream tab].
			aStream nextPut: $}]
		ifNotNil:
			[:const |
			const ifFalse:
				[msgNode args first emitJSCodeOn: aStream level: level generator: self]]
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateIfFalseAsArgument: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode)
		ifNil:
			[aStream nextPut: $(.
			 msgNode receiver emitJSCodeAsArgumentOn: aStream level: level generator: self.
			 aStream crtab: level + 1; nextPutAll: ' ? 0 : '.
			 msgNode args first emitJSCodeAsArgumentOn: aStream level: level + 2 generator: self.
			 aStream crtab: level + 1; nextPut: $)]
		ifNotNil:
			[:const|
			const ifFalse:
				[msgNode args first emitJSCodeAsArgumentOn: aStream level: level generator: self]]
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateIfFalseIfTrue: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode)
		ifNil:
			[aStream nextPutAll: 'if ('.
			msgNode receiver emitJSCodeAsExpressionOn: aStream level: level generator: self.
			aStream nextPutAll: ') {'; cr.
			msgNode args last emitJSCodeOn: aStream level: level + 1 generator: self.
			aStream tab: level; nextPut: $}; nextPutAll: ' else {'; cr.
			msgNode args first emitJSCodeOn: aStream level: level + 1 generator: self.
			aStream tab: level; nextPut: $}]
		ifNotNil:
			[:const |
			 (const ifTrue: [msgNode args last] ifFalse: [msgNode args first])
				emitJSCodeOn: aStream level: level generator: self]
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateIfFalseIfTrueAsArgument: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode)
		ifNil:
			[aStream nextPut: $(.
			msgNode receiver emitJSCodeAsArgumentOn: aStream level: level generator: self.
			aStream crtab: level + 1; nextPut: $?; space.
			msgNode args last emitJSCodeAsArgumentOn: aStream level: level + 2 generator: self.
			aStream crtab: level + 1; nextPut: $:; space.
			msgNode args first emitJSCodeAsArgumentOn: aStream level: level + 2 generator: self.
			aStream nextPut: $)]
		ifNotNil:
			[:const|
			(const
				ifTrue: [msgNode args last]
				ifFalse: [msgNode args first])
					emitJSCodeAsArgumentOn: aStream level: level generator: self]
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateIfTrue: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode)
		ifNil:
			[aStream nextPutAll: 'if ('.
			msgNode receiver emitJSCodeAsExpressionOn: aStream level: level generator: self.
			aStream nextPutAll: ') {'; cr.
			msgNode args first emitJSCodeOn: aStream level: level + 1 generator: self.
			level timesRepeat: [ aStream tab ].
			aStream nextPut: $}]
		ifNotNil:
			[:const |
			const ifTrue:
				[msgNode args first emitJSCodeOn: aStream level: level generator: self]]
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateIfTrueAsArgument: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode)
		ifNil:
			[aStream nextPut: $(.
			 msgNode receiver emitJSCodeAsArgumentOn: aStream level: level generator: self.
			 aStream crtab: level + 1; nextPut: $?; space.
			 msgNode args first emitJSCodeAsArgumentOn: aStream level: level + 2 generator: self.
			 aStream crtab: level + 1; nextPutAll: ': 0)']
		ifNotNil:
			[:const|
			const ifTrue:
				[msgNode args first emitJSCodeAsArgumentOn: aStream level: level generator: self]]
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateIfTrueIfFalse: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode)
		ifNil:
			[aStream nextPutAll: 'if ('.
			msgNode receiver emitJSCodeAsExpressionOn: aStream level: level generator: self.
			aStream nextPutAll: ') {'; cr.
			msgNode args first emitJSCodeOn: aStream level: level + 1 generator: self.
			aStream tab: level; nextPut: $}; nextPutAll: ' else {'; cr.
			msgNode args last emitJSCodeOn: aStream level: level + 1 generator: self.
			aStream tab: level; nextPut: $}]
		ifNotNil:
			[:const |
			(const ifTrue: [msgNode args first] ifFalse: [msgNode args last])
				emitJSCodeOn: aStream level: level generator: self]
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateIfTrueIfFalseAsArgument: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	(self nilOrBooleanConstantReceiverOf: msgNode)
		ifNil:
			[aStream nextPut: $(.
			msgNode receiver emitJSCodeAsArgumentOn: aStream level: level generator: self.
			aStream crtab: level + 1; nextPut: $?; space.
			msgNode args first emitJSCodeAsArgumentOn: aStream level: level + 2 generator: self.
			aStream crtab: level + 1; nextPut: $:; space.
			msgNode args last emitJSCodeAsArgumentOn: aStream level: level + 2 generator: self.
			aStream nextPut: $)]
		ifNotNil:
			[:const|
			(const ifTrue: [msgNode args first] ifFalse: [msgNode args last])
				emitJSCodeAsArgumentOn: aStream level: level generator: self]
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateInlineCCode: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream.
	 There are two forms, self cCode: aString ... and self cCode: aBlock."
	msgNode args first isConstant
		ifTrue: [
			self generateJSCodeForCcode: msgNode args first value on: aStream indent: level]
		ifFalse: [
			msgNode args first
					emitCCodeOn: aStream
					level: level
					generator: self]
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateInlineCCodeAsArgument: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream.
	 There are two forms, self cCode: aString ... and self cCode: aBlock."

	msgNode args first isConstant
		ifTrue: [self generateJSCodeForCcode: msgNode args first value
			on: aStream indent: level]
		ifFalse: [msgNode args first
					emitCCodeAsArgumentOn: aStream
					level: level
					generator: self]
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateInlineCPreprocessorDirective: msgNode on: aStream indent: level [
	"Generate the C preprocessor directive for this message onto the given stream."
self halt.
	aStream cr; nextPutAll: msgNode args first value
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateInlineCppDirective: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."
self halt.
	aStream cr; nextPutAll: '# ', msgNode args first value.
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateInlineCppIfDef: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '// skipping ifdef ', msgNode args first value
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateInlineCppIfDefElse: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| alternateBlock alternateBlockIsNil |
	aStream nextPutAll: '// skipping ifdef ', msgNode args first value; cr.

	alternateBlock := msgNode args fifth.
	alternateBlockIsNil := true. "check for nil #else clause"
	alternateBlock nodesDo: [:n |
		(n ~= alternateBlock and: [n name ~= 'nil'])
			ifTrue: [alternateBlockIsNil := false ]].
	(alternateBlockIsNil) ifFalse:
		[msgNode isExpression
			ifTrue:
				[aStream tab: level + 1; nextPut: $(.
				alternateBlock asExpression
					emitJSCodeOn: aStream level: level + 1 generator: self.
				aStream nextPut: $); cr]
			ifFalse:
				[alternateBlock
					emitJSCodeOn: aStream level: level generator: self]].


]

{ #category : #'JS translation' }
JSCodeGenerator >> generateInlineCppIfElse: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| comment alternateBlock alternateBlockIsNil |
self halt.
	aStream cr; nextPutAll: '# if (', msgNode args first value, ')'.
	comment := msgNode args third value.
	(comment isKindOf: String)
		ifTrue: [aStream nextPutAll: '  // ', comment]
		ifFalse: ["nil argument, ignore it"].
	aStream cr.
	msgNode isExpression
		ifTrue:
			[aStream tab: level + 1; nextPut: $(.
			msgNode args fourth asExpression
				emitJSCodeOn: aStream level: level + 1 generator: self.
			aStream nextPut: $); cr]
		ifFalse:
			[msgNode args fourth
				emitJSCodeOn: aStream level: level generator: self].
	alternateBlock := msgNode args fifth.
	alternateBlockIsNil := true. "check for nil #else clause"
	alternateBlock nodesDo: [:n |
		(n ~= alternateBlock and: [n name ~= 'nil'])
			ifTrue: [alternateBlockIsNil := false ]].
	(alternateBlockIsNil) ifFalse:
		[aStream nextPutAll: '# else'; cr.
		msgNode isExpression
			ifTrue:
				[aStream tab: level + 1; nextPut: $(.
				alternateBlock asExpression
					emitJSCodeOn: aStream level: level + 1 generator: self.
				aStream nextPut: $); cr]
			ifFalse:
				[alternateBlock
					emitJSCodeOn: aStream level: level generator: self]].
	aStream nextPutAll: '# endif  // ', msgNode args first value; cr; tab: level

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateInlineDirective: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	aStream nextPutAll: '/* inline: '.
	aStream nextPutAll: msgNode args first value asString.
	aStream nextPutAll: ' */'.

]

{ #category : #'JS hacks' }
JSCodeGenerator >> generateInstanceSizeOf: msgNode on: aStream indent: level [
	msgNode args first emitJSCodeOn: aStream level: level generator: self.
	aStream nextPutAll: '.classInstSize()'.

]

{ #category : #'JS hacks' }
JSCodeGenerator >> generateIntAtPointer: msgNode on: aStream indent: level [
	msgNode args first asString = 'self cCoerce: argPtr + i to: ''char*'''
		ifTrue: [^aStream nextPutAll: 'argPtr[i]'].
	self halt
	
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateIntegerObjectOf: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	self emitJSExpression: msgNode args first on: aStream.

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateIntegerValueOf: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	self emitJSExpression: msgNode args first on: aStream.

]

{ #category : #'JS hacks' }
JSCodeGenerator >> generateInterpreterProxyCall: msgNode on: aStream indent: level [
	aStream nextPutAll: 'interpreterProxy.'.
	^ msgNode emitJSCodeAsFunctionCallOn: aStream level: level generator: self
]

{ #category : #'JS hacks' }
JSCodeGenerator >> generateIsFloatObject: msgNode on: aStream indent: level [
	msgNode args first emitJSCodeOn: aStream level: level generator: self.
	aStream nextPutAll: '.isFloat'.

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateIsIntegerObject: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	aStream nextPutAll: 'typeof '.
	self emitJSExpression: msgNode args first on: aStream.
	aStream nextPutAll: ' === "number"'.
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateIsNil: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	aStream nextPutAll: '!'.
	self emitJSExpression: msgNode receiver on: aStream.

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateJSCodeForCcode: cCode on: aStream indent: level [
	cCode = '' ifTrue: [^self].
	aStream nextPutAll: (cCodeTranslationDict at: cCode ifAbsent: [
		(#('sqrt' 'sin' 'cos' 'tan' 'atan' 'atan2' 'log' 'min' 'max' 'floor') anySatisfy: [:fn | fn,'(*)' match: cCode])
			ifTrue: ['Math.', cCode] ifFalse: [
		('opTable[*] = (void *)*' match: cCode)
			ifTrue: [cCode copyReplaceAll: '(void *)' with: ''] ifFalse: [
		('fn(*Handle, &*Pitch, *)' match: cCode)
			ifTrue: [(cCode copyReplaceAll: '&' with: 'function(p){') copyReplaceAll: 'Pitch' with: 'Pitch = p}'] ifFalse: [
		(' ((*)querySurfaceFn)*(handle, &destWidth, &destHeight, &destDepth, &destMSB)' match: cCode)
			ifTrue: [ 'querySurfaceFn(handle, function(w, h, d, m){destWidth = w; destHeight = h; destDepth = d; destMSB = m; })'] ifFalse: [
		(' ((*)querySurfaceFn)*(handle, &sourceWidth, &sourceHeight, &sourceDepth, &sourceMSB)' match: cCode)
			ifTrue: [ 'querySurfaceFn(handle, function(w, h, d, m){sourceWidth = w; sourceHeight = h; sourceDepth = d; sourceMSB = m; })'] ifFalse: [
		(#('fn(destHandle, affectedL, affectedT, affectedR-affectedL, affectedB-affectedT)',
			'fn(sourceHandle, 0, 0, 0, 0)') includes: cCode)
			ifTrue: [cCode] ifFalse: [
		"See initializeCTranslationDictionary"
		self error: 'C: ' , cCode]]]]]]])

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateLessThan: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' < '.
	self emitJSExpression: msgNode args first on: aStream.
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateLessThanOrEqual: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' <= '.
	self emitJSExpression: msgNode args first on: aStream.
]

{ #category : #'JS hacks' }
JSCodeGenerator >> generateLong32At: msgNode on: aStream indent: level [
	| expr index |
	expr := msgNode args first.
	(expr isSend and: [expr selector = #+]) ifFalse: [self halt].
	expr receiver emitJSCodeOn: aStream level: level generator: self.
	index := expr args first.
	aStream nextPut: $[.
	index isTimesFour
		ifTrue: [index receiver emitJSCodeOn: aStream level: level generator: self]
		ifFalse: [
			index emitJSCodeAsExpressionOn: aStream level: level generator: self.
			aStream nextPutAll: ' >>> 2'].
	aStream nextPut: $].

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateMax: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	aStream nextPutAll: 'Math.max('.
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ', '.
	self emitJSExpression: msgNode args first on: aStream.
	aStream nextPutAll: ')'.

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateMin: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	aStream nextPutAll: 'Math.min('.
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ', '.
	self emitJSExpression: msgNode args first on: aStream.
	aStream nextPutAll: ')'.

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateMinus: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
	self checkNonPointer: msgNode receiver op: '-'.
	self checkNonPointer: msgNode args first op: '-'.

	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' - '.
	self emitJSExpression: msgNode args first on: aStream.
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateModulo: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	aStream nextPutAll: 'MOD('.
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ', '.
	self emitJSExpression: msgNode args first on: aStream.
	aStream nextPutAll: ')'.

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateNegated: msgNode on: aStream indent: level [
	"Generate the JS code for the negated message onto the given stream."

	"-0 is a float, 0 - 0 an integer"
	aStream nextPutAll: '(0 - '.
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ')'.

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateNot: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
	| expr |
	expr := msgNode receiver.
	"generate (a != b) instead of !(a == b)"
	expr isEqualityTest ifTrue: [
		^(msgNode selector includes: $~)
			ifTrue: [self generateEqual: expr on: aStream indent: level]
			ifFalse: [self generateNotEqual: expr on: aStream indent: level]].
	"eliminate not not"
	(expr isSend and: [expr selector = #not]) ifTrue: [
		^self emitJSExpression: expr receiver on: aStream].
	aStream nextPutAll: '!'.
	self emitJSExpression: expr on: aStream.
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateNotEqual: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
	| argNode test |
	argNode :=  msgNode args first.
	"quick test for nil, true, false"
	argNode isInterpreterProxyConstant ifTrue: [
		test := #(isNil isTrue isFalse) at: (#(nilObject trueObject falseObject) indexOf: argNode selector).
		aStream nextPut: $!.
		self emitJSExpression: msgNode receiver on: aStream.
		^aStream nextPut: $.; nextPutAll: test].
	"cannot compare pointers to 0"
	(argNode isConstantNull or: [argNode isConstantZero and: [self isPointer: msgNode receiver]]) ifTrue: [
		aStream nextPutAll: '!!'.
		^self emitJSExpression: msgNode receiver on: aStream].
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' !== '.
	self emitJSExpression: msgNode args first on: aStream.
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateNotNil: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	aStream nextPutAll: '!!'.
	self emitJSExpression: msgNode receiver on: aStream.

]

{ #category : #'JS hacks' }
JSCodeGenerator >> generateOopForPointer: msgNode on: aStream indent: level [
	| arg |
	arg := msgNode args first asString.
	arg = 'interpreterProxy firstIndexableField: destBits'
		ifTrue: [^aStream nextPutAll: 'destBits.wordsOrBytes()'].
	arg = 'interpreterProxy firstIndexableField: sourceBits'
		ifTrue: [^aStream nextPutAll: 'sourceBits.wordsOrBytes()'].
	arg =  'interpreterProxy firstIndexableField: halftoneBits'
		ifTrue: [^aStream nextPutAll: 'halftoneBits.wordsOrBytes()'].
	arg =  'interpreterProxy firstIndexableField: sourceMapOop'
		ifTrue: [^aStream nextPutAll: 'sourceMapOop.wordsOrBytes()'].
	self halt

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateOr: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' || '.
	self emitJSExpression: msgNode args first on: aStream.
]

{ #category : #'JS translation' }
JSCodeGenerator >> generatePerform: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
self halt.
	self emitJSExpression: msgNode args first on: aStream.
	aStream nextPut: $(.
	(msgNode args copyFrom: 2 to: msgNode args size) do:[:arg|
		self emitJSExpression: arg on: aStream.
	] separatedBy:[aStream nextPutAll:', '].
	aStream nextPut: $)
]

{ #category : #'JS translation' }
JSCodeGenerator >> generatePlus: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
	msgNode receiver isBitBltPtr ifFalse: [
		self checkNonPointer: msgNode receiver op: '+'.
		self checkNonPointer: msgNode args first op: '+'.
		self emitJSExpression: msgNode receiver on: aStream.
		aStream nextPutAll: ' + '].
	self emitJSExpression: msgNode args first on: aStream.
]

{ #category : #'JS translation' }
JSCodeGenerator >> generatePreDecrement: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	| varNode |
	varNode := msgNode receiver.
	varNode isVariable
		ifFalse: [ self error: 'preDecrement can only be applied to variables' ].
	self checkNonPointer: varNode op: '--'.
	aStream nextPutAll: '--'.
	aStream nextPutAll: (self returnPrefixFromVariable: varNode name).

]

{ #category : #'JS translation' }
JSCodeGenerator >> generatePreIncrement: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	| varNode |
	varNode := msgNode receiver.
	varNode isVariable
		ifFalse: [ self error: 'preIncrement can only be applied to variables' ].
	aStream nextPutAll: '++'.
	self checkNonPointer: varNode op: '++'.
	aStream nextPutAll: (self returnPrefixFromVariable: varNode name).

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateRaisedTo: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	aStream nextPutAll:'Math.pow('.
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ','.
	self emitJSExpression: msgNode args first on: aStream.
	aStream nextPutAll:')'.
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateRepeat: msgNode on: aStream indent: level [
	"Generate while(true) { stmtList } "

	aStream nextPutAll: 'while(true) {'; cr.
	msgNode receiver emitJSCodeOn: aStream level: level + 1 generator: self.
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '}'

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateSequentialAnd: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' && ('.
	self emitJSTestBlock: msgNode args first on: aStream.
	aStream nextPut: $)
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateSequentialOr: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' || ('.
	self emitJSTestBlock: msgNode args last on: aStream.
	aStream nextPutAll: ')'
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateSharedCodeDirective: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	aStream nextPutAll: '/* common code: '.
	aStream nextPutAll: msgNode args first value.
	aStream nextPutAll: ' */'.

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateShiftLeft: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
	| arg rcvr |
	rcvr := msgNode receiver.
	arg := msgNode args first.
	arg isConstant ifTrue: [
		"bit shift amount is a constant"
		arg value < 31 ifTrue: [
			self emitJSExpression: rcvr on: aStream.
				aStream nextPutAll: ' << ', arg value printString.
		] ifFalse: [
			self error: 'cannot shift by more than 31'
		].
	] ifFalse: [
		"bit shift amount is an expression"
		aStream nextPutAll: 'SHL('.
		self emitJSExpression: rcvr on: aStream.
		aStream nextPutAll: ', '.
		self emitJSExpression: arg on: aStream.
		aStream nextPutAll: ')'.
	].
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateShiftRight: msgNode on: aStream indent: level [
	"Generate the JS code for unsigned right-shift onto the given stream."
	| rcvr arg |

	rcvr := msgNode receiver.
	arg := msgNode args first.
	arg isConstant ifTrue: [
		"bit shift amount is a constant"
		arg value < 31 ifTrue: [
			self emitJSExpression: rcvr on: aStream.
				aStream nextPutAll: ' >>> ', arg value printString.
		] ifFalse: [
			self error: 'cannot shift by more than 31'
		].
	] ifFalse: [
		"bit shift amount is an expression"
		aStream nextPutAll: 'SHR('.
		self emitJSExpression: rcvr on: aStream.
		aStream nextPutAll: ', '.
		self emitJSExpression: arg on: aStream.
		aStream nextPutAll: ')'.
	].
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateSignedBitShift: msgNode on: aStream indent: level [
	"Generate the JS code for signedBitShift: onto the given stream."

	| arg rcvr |
	arg := msgNode args first.
	rcvr := msgNode receiver.
	arg isConstant ifTrue: [
		"bit shift amount is a constant"
		self emitJSExpression: rcvr on: aStream.
		arg value < 0 ifTrue: [
			arg value < -31 ifTrue: [self error: 'cannot shift by more than 31']. 
			aStream nextPutAll: ' >> ', arg value negated printString.
		] ifFalse: [
			arg value > 31 ifTrue: [self error: 'cannot shift by more than 31']. 
			aStream nextPutAll: ' << ', arg value printString.
		].
	] ifFalse: [
		self error: 'non-constant signed shift not implemented yet'
	].
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateSignedIntFromLong: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
self halt.
	aStream nextPutAll: '((sqInt) '.
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPut: $)


]

{ #category : #'JS translation' }
JSCodeGenerator >> generateSignedIntFromShort: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
self halt.
	aStream nextPutAll: '((short)'.
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPut: $)


]

{ #category : #'JS translation' }
JSCodeGenerator >> generateSignedIntToLong: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
self halt.
	aStream nextPutAll: '((usqInt) '.
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPut: $)


]

{ #category : #'JS translation' }
JSCodeGenerator >> generateSignedIntToShort: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
self halt.
	aStream nextPutAll: '((usqInt) (short)'.
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPut: $)


]

{ #category : #'JS translation' }
JSCodeGenerator >> generateSin: msgNode on: aStream indent: level [
	"Generate the JS code for the message onto the given stream."

	aStream nextPutAll: 'Math.sin('.
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ')'.

]

{ #category : #'JS hacks' }
JSCodeGenerator >> generateSizeOfSTArrayFromCPrimitive: msgNode on: aStream indent: level [
	| cType sizer |
	cType := self typeOfVariable: msgNode args first name.
	cType ifNotNil: [
		sizer := (cType includesSubString: 'char *') ifTrue: ['.length'] ifFalse: [
			(cType beginsWith: 'int *') ifTrue: ['.length'] 
			ifFalse: [self halt: 'need to handle ', cType]]].
		sizer ifNotNil: [msgNode args first emitJSCodeOn: aStream level: level generator: self.
			^aStream nextPutAll: sizer].
	self halt.
	"generic code below, not needed ever hopefully"
	aStream nextPutAll: 'interpreterProxy.'.
	^ msgNode emitJSCodeAsFunctionCallOn: aStream level: level generator: self
]

{ #category : #'JS hacks' }
JSCodeGenerator >> generateSlotSizeOf: msgNode on: aStream indent: level [
	aStream nextPutAll: 'SIZEOF('.
	msgNode args first emitJSCodeOn: aStream level: level generator: self.
	aStream nextPut: $).

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateSmalltalkMetaError: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	aStream nextPutAll: 'throw Error("'; nextPutAll: msgNode selector; nextPutAll: '")'
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateSqrt: msgNode on: aStream indent: level [
	"Generate the JS code for the message onto the given stream."

	aStream nextPutAll: 'Math.sqrt('.
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ')'.

]

{ #category : #'JS hacks' }
JSCodeGenerator >> generateSrcLongAt: msgNode on: aStream indent: level [
	aStream nextPutAll: 'sourceBits['.
	msgNode args first emitJSCodeAsExpressionOn: aStream level: level generator: self.
	aStream nextPutAll: ' >>> 2]'.
	

]

{ #category : #'JS hacks' }
JSCodeGenerator >> generateSuperclassOf: msgNode on: aStream indent: level [
	msgNode args first emitJSCodeOn: aStream level: level generator: self.
	aStream nextPutAll: '.superclass()'.

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateTimes: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' * '.
	self emitJSExpression: msgNode args first on: aStream.
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateToByDo: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."
	"N.B. MessageNode>>asTranslatorNodeIn: adds the limit var as a hidden fourth argument."
	| blockExpr iterationVar limitExpr mayHaveSideEffects limitVar step negative |
	blockExpr := msgNode args third.
	blockExpr args size = 1 ifFalse:
		[self error: 'wrong number of block arguments'].
	iterationVar := blockExpr args first.
	limitExpr := msgNode args first.
	aStream nextPutAll: 'for (', iterationVar, ' = '.
	self emitJSExpression: msgNode receiver on: aStream.
	mayHaveSideEffects := msgNode args size = 4. "See TMethod>>prepareMethodIn:"
	mayHaveSideEffects ifTrue:
		[limitVar := msgNode args last.
		 aStream nextPutAll: ', ', limitVar name, ' = '.
		 self emitJSExpression: limitExpr on: aStream.
		 limitExpr := limitVar].
	aStream nextPutAll: '; ', iterationVar.
	negative := ((step := msgNode args at: 2) isConstant and: [step value < 0])
				or: [step isSend and: [step selector == #negated
					and: [step receiver isConstant and: [step receiver value >= 0]]]].
	aStream nextPutAll: (negative ifTrue: [' >= '] ifFalse: [' <= ']).
	self emitJSExpression: limitExpr on: aStream.
	(step isConstant and: step value = 1)
		ifTrue: [aStream nextPutAll: '; ', iterationVar, '++']
		ifFalse: [aStream nextPutAll: '; ', iterationVar, ' += '.
			self emitJSExpression: step on: aStream].
	aStream nextPutAll: ') {'; cr.
	blockExpr emitJSCodeOn: aStream level: level + 1 generator: self.
	aStream tab: level.
	aStream nextPut: $}
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateToDo: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream."

	| iterationVar |
	(msgNode args last args size = 1) ifFalse: [
		self error: 'wrong number of block arguments'.
	].
	iterationVar := msgNode args last args first.
	aStream nextPutAll: 'for (', iterationVar, ' = '.
	self emitJSExpression: msgNode receiver on: aStream.
	aStream nextPutAll: '; ', iterationVar, ' <= '.
	self emitJSExpression: msgNode args first on: aStream.
	aStream nextPutAll: '; ', iterationVar, '++) {'; cr.
	msgNode args last emitJSCodeOn: aStream level: level + 1 generator: self.
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '}'.
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateTouch: msgNode on: aStream indent: level [
	"Generate the JS code for this message onto the given stream - which is to say absolutely nothing"

]

{ #category : #'JS translation' }
JSCodeGenerator >> generateWhileFalse: msgNode on: aStream indent: level [
	"Generate JS code for a loop in one of the following formats, as appropriate:
		while(!(cond)) { stmtList }
		do {stmtList} while(!(cond))
		while(true) {stmtListA; if (cond) break; stmtListB}"

	msgNode receiver statements size <= 1
		ifTrue: [^self generateWhileFalseLoop: msgNode on: aStream indent: level].
	msgNode args first isNilStmtListNode
		ifTrue: [^self generateDoWhileFalse: msgNode on: aStream indent: level].
	^self generateWhileForeverBreakTrueLoop: msgNode on: aStream indent: level
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateWhileFalseLoop: msgNode on: aStream indent: level [
	"Generate while(!(cond)) {stmtList}."

	aStream nextPutAll: 'while (!('.
	self emitJSTestBlock: msgNode receiver on: aStream.
	aStream nextPutAll: ')) {'; cr.
	msgNode args first isNilStmtListNode ifFalse:
		[msgNode args first emitJSCodeOn: aStream level: level + 1 generator: self].
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '}'.
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateWhileForeverBreakFalseLoop: msgNode on: aStream indent: level [
	"Generate while(true) {stmtListA; if(!(cond)) break; stmtListB}."

	| stmts testStmt |
	stmts := msgNode receiver statements asOrderedCollection.
	testStmt := stmts removeLast.
	msgNode receiver setStatements: stmts.
	level - 1 timesRepeat: [ aStream tab ].
	aStream nextPutAll: 'while (true) {'; cr.
	msgNode receiver emitJSCodeOn: aStream level: level + 1 generator: self.
	(level + 1) timesRepeat: [ aStream tab ].
	aStream nextPutAll: 'if (!('.
	testStmt asExpression emitJSCodeOn: aStream level: 0 generator: self.
	aStream nextPutAll: ')) break;'; cr.
	msgNode args first emitJSCodeOn: aStream level: level + 1 generator: self.
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '}'.
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateWhileForeverBreakTrueLoop: msgNode on: aStream indent: level [
	"Generate while(true) {stmtListA; if(cond) break; stmtListB}."

	| stmts testStmt |
	stmts := msgNode receiver statements asOrderedCollection.
	testStmt := stmts removeLast.
	msgNode receiver setStatements: stmts.
	level - 1 timesRepeat: [ aStream tab ].
	aStream nextPutAll: 'while (true) {'; cr.
	msgNode receiver emitJSCodeOn: aStream level: level + 1 generator: self.
	(level + 1) timesRepeat: [ aStream tab ].
	aStream nextPutAll: 'if ('.
	testStmt asExpression emitJSCodeOn: aStream level: 0 generator: self.
	aStream nextPutAll: ') break;'; cr.
	msgNode args first emitJSCodeOn: aStream level: level + 1 generator: self.
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '}'.
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateWhileTrue: msgNode on: aStream indent: level [
	"Generate C code for a loop in one of the following formats, as appropriate:
		while(cond) { stmtList }
		do {stmtList} while(cond)
		while(true) {stmtListA; if (!(cond)) break; stmtListB}"

	msgNode receiver statements size <= 1
		ifTrue: [^self generateWhileTrueLoop: msgNode on: aStream indent: level].
	msgNode args first isNilStmtListNode
		ifTrue: [^self generateDoWhileTrue: msgNode on: aStream indent: level].
	^self generateWhileForeverBreakFalseLoop: msgNode on: aStream indent: level
]

{ #category : #'JS translation' }
JSCodeGenerator >> generateWhileTrueLoop: msgNode on: aStream indent: level [
	"Generate while(cond) {stmtList}."

	aStream nextPutAll: 'while ('.
	self emitJSTestBlock: msgNode receiver on: aStream.
	aStream nextPutAll: ') {'; cr.
	msgNode args first isNilStmtListNode ifFalse:
		[msgNode args first emitJSCodeOn: aStream level: level + 1 generator: self].
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '}'.
]

{ #category : #public }
JSCodeGenerator >> globalsAsSet [
	"Used by the inliner to avoid name clashes with global variables."

	((variablesSetCache == nil) or:
	 [variablesSetCache size ~= variables size]) ifTrue: [
		variablesSetCache := variables asSet.
	].
	^ variablesSetCache
]

{ #category : #public }
JSCodeGenerator >> ignoredMethods [
	^#()
]

{ #category : #public }
JSCodeGenerator >> initialize [
	translationDict := Dictionary new.
	inlineList := Array new.
	constants := Dictionary new: 100.
	variables := OrderedCollection new: 100.
	variableDeclarations := Dictionary new: 100.
	methods := Dictionary new: 500.
	macros := Dictionary new.
	self initializeCTranslationDictionary.
	receiverDict := Dictionary new.
	headerFiles := OrderedCollection new.
	globalVariableUsage := Dictionary new.
	useSymbolicConstants := true.
	generateDeadCode := false.
	scopeStack := OrderedCollection new.
	logger := (ProvideAnswerNotification new tag: #logger; signal) ifNil: [Transcript].
	pools := IdentitySet new.
	abstractDeclarations := IdentitySet new.
	uncheckedAbstractMethods := OrderedCollection new.

]

{ #category : #'JS translation' }
JSCodeGenerator >> initializeCTranslationDictionary [ 
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
	#abs			#generateAbs:on:indent:
	#sqrt			#generateSqrt:on:indent:
	#sin			#generateSin:on:indent:
	#cos			#generateCos:on:indent:
	#*				#generateTimes:on:indent:
	#/				#generateDivide:on:indent:
	#//				#generateDivide:on:indent:
	#\\				#generateModulo:on:indent:
	#<<			#generateShiftLeft:on:indent:
	#>>			#generateShiftRight:on:indent:
	#min:			#generateMin:on:indent:
	#max:			#generateMax:on:indent:
	#between:and:	#generateBetweenAnd:on:indent:

	#bitAnd:		#generateBitAnd:on:indent:
	#bitOr:			#generateBitOr:on:indent:
	#bitXor:		#generateBitXor:on:indent:
	#bitShift:		#generateBitShift:on:indent:
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
	#whileTrue 		#generateDoWhileTrue:on:indent:
	#whileFalse		#generateDoWhileFalse:on:indent:
	#to:do:			#generateToDo:on:indent:
	#to:by:do:		#generateToByDo:on:indent:
	#repeat 		#generateRepeat:on:indent:

	#ifTrue:			#generateIfTrue:on:indent:
	#ifFalse:		#generateIfFalse:on:indent:
	#ifTrue:ifFalse:	#generateIfTrueIfFalse:on:indent:
	#ifFalse:ifTrue:	#generateIfFalseIfTrue:on:indent:

	#at:			#generateAt:on:indent:
	#at:put:			#generateAtPut:on:indent:
	#basicAt:		#generateAt:on:indent:
	#basicAt:put:	#generateAtPut:on:indent:

	#integerValueOf:			#generateIntegerValueOf:on:indent:
	#integerObjectOf:			#generateIntegerObjectOf:on:indent:
	#isIntegerObject: 			#generateIsIntegerObject:on:indent:
	#cCode:					#generateInlineCCode:on:indent:
	#cCode:inSmalltalk:			#generateInlineCCode:on:indent:
	#cPreprocessorDirective:	#generateInlineCPreprocessorDirective:on:indent:
	#preprocessorExpression:	#generateInlineCppDirective:on:indent:
	#isDefined:inSmalltalk:comment:ifTrue:	#generateInlineCppIfDef:on:indent:
	#isDefined:inSmalltalk:comment:ifTrue:ifFalse:	#generateInlineCppIfDefElse:on:indent:
	#isDefinedTrueExpression:inSmalltalk:comment:ifTrue:ifFalse:	#generateInlineCppIfElse:on:indent:
	#cCoerce:to:				#generateCCoercion:on:indent:
	#cCoerceSimple:to:			#generateCCoercion:on:indent:
	#addressOf:				#generateAddressOf:on:indent:
	#signedIntFromLong			#generateSignedIntFromLong:on:indent:
	#signedIntToLong			#generateSignedIntToLong:on:indent:
	#signedIntFromShort		#generateSignedIntFromShort:on:indent:
	#signedIntToShort			#generateSignedIntToShort:on:indent:
	#preIncrement				#generatePreIncrement:on:indent:
	#preDecrement				#generatePreDecrement:on:indent:
	#inline:						#generateInlineDirective:on:indent:
	#asFloat					#generateAsFloat:on:indent:
	#asInteger					#generateAsInteger:on:indent:
	#asUnsignedInteger			#generateAsUnsignedInteger:on:indent:
	#asSymbol					#generateAsSymbol:on:indent:
	#anyMask:					#generateBitAnd:on:indent:
	#raisedTo:					#generateRaisedTo:on:indent:
	#touch:						#generateTouch:on:indent:
	#bytesPerWord		#generateBytesPerWord:on:indent:
	#baseHeaderSize		#generateBaseHeaderSize:on:indent:

	#sharedCodeNamed:inCase:		#generateSharedCodeDirective:on:indent:

	#perform:							#generatePerform:on:indent:
	#perform:with:						#generatePerform:on:indent:
	#perform:with:with:					#generatePerform:on:indent:
	#perform:with:with:with:				#generatePerform:on:indent:
	#perform:with:with:with:with:		#generatePerform:on:indent:
	#perform:with:with:with:with:with:	#generatePerform:on:indent:

	#shouldNotImplement				#generateSmalltalkMetaError:on:indent:
	#shouldBeImplemented				#generateSmalltalkMetaError:on:indent:

	"optimized interpreterProxy calls"
	#firstIndexableField:				#generateFirstIndexableField:on:indent:
	#slotSizeOf:						#generateSlotSizeOf:on:indent:
	#stSizeOf:							#generateSlotSizeOf:on:indent:
	#byteSizeOfBytes:					#generateByteSizeOf:on:indent:
	#byteSizeOf:						#generateByteSizeOf:on:indent:
	#fetchClassOf:						#generateFetchClassOf:on:indent:
	#superclassOf:						#generateSuperclassOf:on:indent:
	#instanceSizeOf:					#generateInstanceSizeOf:on:indent:
	#is:KindOf: 							#generateIsKindOf:on:indent:
	#isFloatObject:						#generateIsFloatObject:on:indent:
	#cDigitCopyFrom:to:len:				#generateCDigitCopy:on:indent:
	#sizeOfSTArrayFromCPrimitive:		#generateSizeOfSTArrayFromCPrimitive:on:indent:
	#asciiValue							#generateIdentityUnary:on:indent:
	#primitiveFail						#generateInterpreterProxyCall:on:indent:
	#intAtPointer:						#generateIntAtPointer:on:indent:
	#byteAtPointer:						#generateByteAtPointer:on:indent:
	#oopForPointer:					#generateOopForPointer:on:indent:
	#long32At:							#generateLong32At:on:indent:
	#srcLongAt:						#generateSrcLongAt:on:indent:
	#dstLongAt:						#generateDstLongAt:on:indent:
	#dstLongAt:put:					#generateDstLongAtPut:on:indent:
	).

	1 to: pairs size by: 2 do: [:i |
		translationDict at: (pairs at: i) put: (pairs at: i + 1)].

	pairs := #(
	#ifTrue:				#generateIfTrueAsArgument:on:indent:	
	#ifFalse:			#generateIfFalseAsArgument:on:indent:
	#ifTrue:ifFalse:		#generateIfTrueIfFalseAsArgument:on:indent:
	#ifFalse:ifTrue:		#generateIfFalseIfTrueAsArgument:on:indent:
	#cCode:			#generateInlineCCodeAsArgument:on:indent:
	#cCode:inSmalltalk:	#generateInlineCCodeAsArgument:on:indent:
	).

	asArgumentTranslationDict := Dictionary new: 8.
	1 to: pairs size by: 2 do: [:i |
		asArgumentTranslationDict at: (pairs at: i) put: (pairs at: i + 1)].

	cCodeTranslationDict := Dictionary new: 8.
	pairs := #(
		'fprintf(stderr, "\n%s: %s", moduleName, s)'					'console.log(moduleName + ": " + s)'
		'interpreterProxy->majorVersion() == VM_PROXY_MAJOR'	'interpreterProxy.majorVersion() == VM_PROXY_MAJOR'
		'interpreterProxy->minorVersion() >= VM_PROXY_MINOR'	'interpreterProxy.minorVersion() >= VM_PROXY_MINOR'
		'rand()'														'Math.random()'
		'*src++'													'src[_src++]' 	
		'*dst++ = max'												'dst[_dst++] = max'
		'src++'		 												'_src++'
		'*dst++ = *src; src += 2'									'dst[_dst++] = src[_src]; _src += 2'
		'tX'															'tX'
		'tY'															'tY'
	).
	1 to: pairs size by: 2 do: [:i |
		cCodeTranslationDict at: (pairs at: i) put: (pairs at: i + 1)].

]

{ #category : #inlining }
JSCodeGenerator >> inlineCaseStatementBranchesInMethodNamed: selector localizingVars: varsList [ 
	"Inline case statement branches in the method with the given name."
	(self methodNamed: selector)
		ifNotNilDo: [:m | m inlineCaseStatementBranchesIn: self localizingVars: varsList]
]

{ #category : #inlining }
JSCodeGenerator >> inlineDispatchesInMethodNamed: selector localizingVars: varsList [
	"Inline dispatches (case statements) in the method with the given name."

	| m varString |
	m := self methodNamed: selector.
	m = nil ifFalse: [
		m inlineCaseStatementBranchesIn: self localizingVars: varsList.
		m parseTree nodesDo: [ :n |
			n isCaseStmt ifTrue: [
				n customizeShortCasesForDispatchVar: 'currentBytecode' in: self method: m.
			].
		].
	].
	variables := variables asOrderedCollection.
	varsList do: [ :v |
		varString := v asString.
		variables remove: varString ifAbsent: [].
		(variableDeclarations includesKey: varString) ifTrue: [
			m declarations at: v asString put: (variableDeclarations at: varString).
			variableDeclarations removeKey: varString.
		].
	].

]

{ #category : #inlining }
JSCodeGenerator >> isAssertSelector: selector [
	^#(assert: asserta: assert:l: asserta:l:) includes: selector
]

{ #category : #utilities }
JSCodeGenerator >> isBuiltinSelector: sel [
	"Answer true if the given selector is one of the builtin selectors."

	^(self isKernelSelector: sel) or: [translationDict includesKey: sel]
]

{ #category : #utilities }
JSCodeGenerator >> isGeneratingPluginCode [
	^false
]

{ #category : #public }
JSCodeGenerator >> isGlobalStructureBuild [
	^false
]

{ #category : #'JS code generator' }
JSCodeGenerator >> isJSLiteral: anObject [
	(anObject isKindOf: Integer) ifTrue: [^true].
	(anObject isKindOf: String) ifTrue: [^true].
	(anObject isKindOf: Float) ifTrue: [^true].
	anObject == nil ifTrue: [^true].
	anObject == true ifTrue: [^true].
	anObject == false ifTrue: [^true].
	^false
]

{ #category : #utilities }
JSCodeGenerator >> isKernelSelector: sel [
	"Answer true if the given selector is one of the kernel selectors that are implemented as macros."

	^(#(error:
		 oopAt: oopAt:put: oopAtPointer: oopAtPointer:put:
		 byteAt: byteAt:put: byteAtPointer: byteAtPointer:put:
		 shortAt: shortAt:put: shortAtPointer: shortAtPointer:put:
		 intAt: intAt:put: intAtPointer: intAtPointer:put:
		 longAt: longAt:put: longAtPointer: longAtPointer:put:
		 longLongAt: longLongAt:put: longLongAtPointer: longLongAtPointer:put:
		 fetchFloatAt:into: storeFloatAt:from:
				fetchFloatAtPointer:into: storeFloatAtPointer:from:
		 fetchSingleFloatAt:into: storeSingleFloatAt:from:
				fetchSingleFloatAtPointer:into: storeSingleFloatAtPointer:from:
		 pointerForOop: oopForPointer:
		 cCoerce:to: cCoerceSimple:to:)
			includes: sel)
]

{ #category : #'JS code generator' }
JSCodeGenerator >> isNonArgumentImplicitReceiverVariableName: aString [
	^(self typeOfVariable: aString) == #implicit
	    or: [vmClass
			ifNil: [#('interpreterProxy' 'self') includes: aString]
	 		ifNotNil: [vmClass isNonArgumentImplicitReceiverVariableName: aString]]
]

{ #category : #'JS hacks' }
JSCodeGenerator >> isOneBasedArray: varName in: method [
	^(method isOneBasedArray: varName)
		ifNil: [self oneBasedArrays]
		ifNotNil: [:oneBased | self oneBasedArrays: oneBased]
]

{ #category : #private }
JSCodeGenerator >> isPointer: node [
	node isVariable ifFalse: [^false].
	(self typeOfVariable: node name) ifNotNil: [:type | ^type includes: $*].
	^false
]

{ #category : #'JS code generator' }
JSCodeGenerator >> isPointerToStructVariableName: varName [ "<String>"
	^self isTypePointerToStruct: (self typeOfVariable: varName)
]

{ #category : #'JS code generator' }
JSCodeGenerator >> isTypePointerToStruct: type [ "<String>"
	^vmClass notNil
	  and: [vmClass isTypePointerToStruct: type]
]

{ #category : #'JS code generator' }
JSCodeGenerator >> jsFunctionNameFor: aSelector [
	"Create a JS function name from the given selector by omitting colons
	and prefixing with the plugin name if the method is exported."
	^aSelector copyWithout: $:
]

{ #category : #'JS code generator' }
JSCodeGenerator >> jsLiteralFor: anObject [
	"Return a string representing theJS literal value for the given object."
	(anObject isKindOf: Integer) ifTrue: [^ anObject printString].
	(anObject isKindOf: String) ifTrue: [^ '"', anObject, '"' ].
	(anObject isKindOf: Float) ifTrue: [^ anObject printString ].
	anObject == nil ifTrue: [^ 'null' ].
	anObject == true ifTrue: [^ 'true' ].
	anObject == false ifTrue: [^ 'false' ].
	self error:
		'Warning: A Smalltalk literal could not be translated into a JS constant: ', anObject printString.
	^'"XXX UNTRANSLATABLE CONSTANT XXX"'
]

{ #category : #utilities }
JSCodeGenerator >> localizeGlobalVariables [
	| candidates procedure |

	"find all globals used in only one method"
	candidates := globalVariableUsage select: [:e | e size = 1].
	(candidates keys select: [:k| vmClass mustBeGlobal: k]) do:
		[:k| candidates removeKey: k].
	variables removeAllFoundIn: candidates keys.

	"move any suitable global to be local to the single method using it"
	candidates keysAndValuesDo: [:key :targets | 
		targets do: [:name |
			procedure := methods at: name.
			procedure locals add: key.
			variableDeclarations at: key ifPresent: [:v | 
				procedure declarations at: key put: v.
				variableDeclarations removeKey: key]]].
]

{ #category : #utilities }
JSCodeGenerator >> logger [
	^logger
]

{ #category : #utilities }
JSCodeGenerator >> logger: aTranscriptStream [
	logger := aTranscriptStream
]

{ #category : #composition }
JSCodeGenerator >> mapVar: instanceVarName asInstanceOf: aClass to: newName [
	"A class that has been added to this code generator has an instance variable
	instanceVarName that should point to an instance of aClass. Treat sends to
	that object as if they were sends to newName. When newName is 'self', all
	such methods are translated to C as functions in the current C module."

	receiverDict at: instanceVarName asString
		ifPresent: [ :previousMapping |
			previousMapping = newName
				ifFalse: [ self error: aClass name,'>>', instanceVarName, ' previously mapped to ',
					previousMapping, ' by another class, cannot be remapped to ', newName ]]
		ifAbsent: [ receiverDict at: instanceVarName asString put: newName.
			variables remove: instanceVarName ifAbsent: [] ]

]

{ #category : #inlining }
JSCodeGenerator >> mayInline: sel [
	"Answer true if the method with the given selector may be inlined."

	^ inlineList includes: sel
]

{ #category : #utilities }
JSCodeGenerator >> memoryAccessSelectors [
	"Answer the selectors used for low level memory access. These are traditionally
	implemented as C preprocessor macros (or static inlined functions) in the external
	support code, but may also be implemented as Smalltalk methods for translation to C."

	^ { #byteAt: . #byteAt:put: .
		#shortAt: . #shortAt:put: .
		#intAt: . #intAt:put: .
		#longAt: . #longAt:put: .
		#byteAtPointer: . #byteAtPointer:put: .
		#shortAtPointer: . #shortAtPointer:put: .
		#intAtPointer: . #intAtPointer:put: .
		#longAtPointer: . #longAtPointer:put: }
]

{ #category : #utilities }
JSCodeGenerator >> methodNamed: selector [
	"Answer the method in the code base with the given selector."

	^ methods at: selector ifAbsent: [ nil ]
]

{ #category : #inlining }
JSCodeGenerator >> methodStatsString [
	"Return a string describing the size, # of locals, and # of senders of
each method. Note methods that have inline C code or C declarations."

	| methodsWithCCode sizesOf callsOf hasCCode nodeCount senderCount s
calls registers selr m |
	methodsWithCCode := Set new: methods size.
	sizesOf := Dictionary new: methods size * 2.  "selector -> nodeCount"
	callsOf := Dictionary new: methods size * 2.  "selector -> senderCount"

	"For each method, scan its parse tree once to:
		1. determine if the method contains C code or declarations
		2. determine how many nodes it has
		3. increment the sender counts of the methods it calls
		4. determine if it includes any C declarations or code"

	methods do: [ :m0 |  m := m0.
		(translationDict includesKey: m selector) ifTrue: [
			hasCCode := true.
		] ifFalse: [
			hasCCode := m declarations size > 0.
			nodeCount := 0.
			m parseTree nodesDo: [ :node |
				node isSend ifTrue: [
					selr := node selector.
					selr = #cCode: ifTrue: [ hasCCode := true ].
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
	methods keys asSortedCollection do: [ :sel |
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
JSCodeGenerator >> methodsReferringToGlobal: v [
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
JSCodeGenerator >> methodsThatCanInvoke: aSelectorList [
	"Return a set of methods that can invoke one of the given selectors, either directly or via a sequence of intermediate methods."

	| out todo sel mSelector |
	out := Set new.
	todo := aSelectorList copy asOrderedCollection.
	[todo isEmpty] whileFalse: [
		sel := todo removeFirst.
		out add: sel.
		methods do: [ :m |
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

{ #category : #'JS code generator' }
JSCodeGenerator >> needToGenerateHeader: headerName file: interpHdrPath contents: newContentsArg [
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
JSCodeGenerator >> nilOrBooleanConstantReceiverOf: sendNode [
	"Answer nil or the boolean constant that is the receiver of the given message send. Used to suppress conditional code when the condition is a translation-time constant."

	| rcvr val |
	generateDeadCode ifTrue:[^nil].
	rcvr := sendNode receiver.
	rcvr isConstant ifTrue: [
		val := rcvr value.
		((val == true) or: [val == false]) ifTrue: [^ val]].
	^ nil

]

{ #category : #'JS hacks' }
JSCodeGenerator >> oneBasedArrays [
	oneBasedArrays ifNil: [oneBasedArrays := false].
	^oneBasedArrays
]

{ #category : #'JS hacks' }
JSCodeGenerator >> oneBasedArrays: aBoolean [
	oneBasedArrays ifNil: [^oneBasedArrays := aBoolean].
	oneBasedArrays = aBoolean ifFalse: [
		self halt: 'mixed one-based and zero-based array access'].
	^aBoolean
]

{ #category : #accessing }
JSCodeGenerator >> permitMethodPruning [
	"If false, pruning unreferenced methods will be disabled"
	^ permitMethodPruning ~= false
]

{ #category : #accessing }
JSCodeGenerator >> permitMethodPruning: aBoolean [
	"If false, pruning unreferenced methods will be disabled"
	permitMethodPruning := aBoolean
]

{ #category : #utilities }
JSCodeGenerator >> prepareMethods [
	"Prepare methods for browsing."

	| globals |
	globals := Set new: 200.
	globals addAll: variables.
	methods do: [ :m |
		(m locals, m args) do: [ :var |
			(globals includes: var) ifTrue: [
				self error: 'Local variable name may mask global when inlining: ', var.
			].
			(methods includesKey: var) ifTrue: [
				self error: 'Local variable name may mask method when inlining: ', var.
			].	
		].
		m mapReceiversIn: receiverDict.
		m bindClassVariablesIn: constants.
		m prepareMethodIn: self.
	].
]

{ #category : #'JS code generator' }
JSCodeGenerator >> prepareMethodsInlined: inlineFlag doAssertions: assertionFlag [
	"Prepare to emit JS code for all methods in the code base. All inlined method calls should be expanded. Answer a list of methods to be emitted as C code."

	| verbose methodList |
	"method preparation"
	verbose := false.
	self pruneMethods: self ignoredMethods.
	self prepareMethods.
	verbose ifTrue: [
		self printUnboundCallWarnings.
		self printUnboundVariableReferenceWarnings.
		Transcript cr.
	].
	self checkAbstractMethods.
	assertionFlag ifFalse: [ self removeAssertions ].
	self doInlining: inlineFlag.

	"code generation"

	methodList := methods asSortedCollection: [ :m1 :m2 | m1 selector < m2 selector ].
	"clean out no longer valid variable names and then handle any global
		variable usage in each method"
	methodList do: [:m | self checkForGlobalUsage: m removeUnusedTemps in: m].
	self localizeGlobalVariables.
	^ preparedMethodList := methodList

]

{ #category : #private }
JSCodeGenerator >> printArray: array on: aStream [
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
JSCodeGenerator >> printInt: int on: aStream [
	aStream print: int.

]

{ #category : #'error notification' }
JSCodeGenerator >> printUnboundCallWarnings [
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

	Transcript cr.
	undefinedCalls keys asSortedCollection do: [ :undefined |
		Transcript show: undefined, ' -- undefined method sent by:'; cr.
		(undefinedCalls at: undefined) do: [ :caller |
			Transcript tab; show: caller; cr.
		].
	].
]

{ #category : #'error notification' }
JSCodeGenerator >> printUnboundVariableReferenceWarnings [
	"Print a warning message for every unbound variable reference in the code base."

	| undefinedRefs globalVars knownVars |
	undefinedRefs := Dictionary new.
	globalVars := Set new: 100.
	globalVars addAll: variables.
	methods do: [ :m |
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

	Transcript cr.
	undefinedRefs keys asSortedCollection do: [ :var |
		Transcript show: var, ' -- undefined variable used in:'; cr.
		(undefinedRefs at: var) do: [ :sel |
			Transcript tab; show: sel; cr.
		].
	].
]

{ #category : #inlining }
JSCodeGenerator >> pruneMethods: selectorList [
	"Explicitly prune some methods"
	selectorList do:[:sel| methods removeKey: sel ifAbsent:[]].
]

{ #category : #inlining }
JSCodeGenerator >> pruneUnreachableMethods [
	"Remove any methods that are not reachable. Retain methods needed by the translated classes - see implementors of requiredMethodNames"
 	
	| newMethods |
	"add all the exported methods and all the called methods to the dNRML"
	methods do: [ :m |
		m export ifTrue:[doNotRemoveMethodList add: m selector].
		doNotRemoveMethodList addAll: m allCalls].

	"build a new dictionary of methods from the collection of all the ones to keep"			
	newMethods := Dictionary new: doNotRemoveMethodList size.
	doNotRemoveMethodList do:[:sel|
		methods at: sel ifPresent:[:meth| newMethods at: sel put: meth]].
	methods := newMethods
]

{ #category : #'JS code generator' }
JSCodeGenerator >> pushScope: variableToType "<Dictionary>" while: aBlock [
	scopeStack addLast: variableToType.
	^aBlock ensure: [scopeStack removeLast]
]

{ #category : #inlining }
JSCodeGenerator >> removeAssertions [
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
JSCodeGenerator >> removeMethodForSelector: aSelector [
	"Remove the given method from the code base"
	methods removeKey:  aSelector ifAbsent: []
]

{ #category : #inlining }
JSCodeGenerator >> removeMethodsReferingToGlobals: varList except: methodNames [
	"Remove any methods (presumably inlined) that still contain references to the given obsolete global variables."

	| varListAsStrings mVars |
	varListAsStrings := varList collect: [ :sym | sym asString ].
		(methods keys copyWithoutAll: methodNames) do: [ :sel |
			mVars := (self methodNamed: sel) freeVariableReferences asSet.
			(mVars includesAnyOf: varListAsStrings)
				ifTrue: [methods removeKey: sel ifAbsent: []]]

]

{ #category : #utilities }
JSCodeGenerator >> removeVariable: aName [
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

{ #category : #composition }
JSCodeGenerator >> renameSelector: selectorName as: newSelectorName [
	"Rename selectors such that generated code will use the newSelectorName. This
	is intended to allow methods that may have default implementations in the support
	code to be renamed for code generation, such that the renamed versions will
	be referenced rather than the default platform implementations. For example,
	if #pointerForOop: is implemented in Smalltalk, it may be renamed such that
	the generated pointerForOop() function will be renamed to avoid conflict with
	the standard definitions provided in sqMemoryAccess.h."

	(methods includesKey: selectorName)
		ifFalse: [ self error: 'no such selector: ', selectorName ].
	methods do: [ :m |
		m renameSelector: selectorName as: newSelectorName ].
	methods at: newSelectorName put: (methods at: selectorName).
	methods removeKey: selectorName

]

{ #category : #utilities }
JSCodeGenerator >> reportRecursiveMethods [
	"Report in transcript all methods that can call themselves directly or indirectly or via a chain of N intermediate methods."

	| visited calls newCalls sel called |
	methods do: [: m |
		visited := translationDict keys asSet.
		calls := m allCalls asOrderedCollection.
		5 timesRepeat: [
			newCalls := Set new: 50.
			[calls isEmpty] whileFalse: [
				sel := calls removeFirst.
				sel = m selector ifTrue: [
					Transcript show: m selector, ' is recursive'; cr.
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
JSCodeGenerator >> retainMethods: aListOfMethodsToKeep [
"add aListOfMethodsToKeep to doNotRemoveMethodList so that they will not be pruned"
	doNotRemoveMethodList ifNil:[doNotRemoveMethodList := Set new:100].
	doNotRemoveMethodList addAll: aListOfMethodsToKeep.
	^aListOfMethodsToKeep
]

{ #category : #utilities }
JSCodeGenerator >> returnPrefixFromVariable: aName [
	aName = 'class'
		ifTrue: [^'sq_class'].
	aName = 'in'
		ifTrue: [^'in_'].
	^aName
]

{ #category : #'JS code generator' }
JSCodeGenerator >> selectorReturnsPointerToStruct: selector [ "<Symbol>"
	| tMethod |
	^vmClass notNil
	  and: [(tMethod := methods at: selector ifAbsent: []) notNil
	  and: [vmClass isTypePointerToStruct: tMethod returnType]]
]

{ #category : #'JS code generator' }
JSCodeGenerator >> shortMonticelloDescriptionForClass: aClass [
	"Answer a suitable Monticello package stamp to include in a moduleName."
	| mdesc |
	mdesc := [self monticelloDescriptionFor: aClass]
				on: Error
				do: [:ex| ^' ', Date today asString].
	^mdesc copyFrom: 1 to: (mdesc indexOfSubCollection: ' uuid:') - 1
]

{ #category : #utilities }
JSCodeGenerator >> sortMethods: aJSMethodCollection [
	"We need to define this since different Squeak versions answer different results
	 for asSortedCollection and if sort order changes, generated code changes too."
	^aJSMethodCollection asSortedCollection:
		[:a :b| a selector caseSensitiveLessOrEqual: b selector]
]

{ #category : #public }
JSCodeGenerator >> storeCodeOnFile: fileName doInlining: inlineFlag [
	"Store JS code for this code base on the given file."

	self storeCodeOnFile: fileName doInlining: inlineFlag doAssertions: true
]

{ #category : #public }
JSCodeGenerator >> storeCodeOnFile: fileName doInlining: inlineFlag doAssertions: assertionFlag [
	"Store JS code for this code base on the given file."

	| stream |
	stream := CrLfFileStream forceNewFileNamed: fileName.
	stream ifNil: [Error signal: 'Could not open JS code file: ', fileName].
	self emitJSCodeOn: stream doInlining: inlineFlag doAssertions: assertionFlag.
	stream close
]

{ #category : #public }
JSCodeGenerator >> storeHeaderFor: interpreterClassName onFile: fileName [
	"Store C header code for this interpreter on the given file."

	| aStream |
	aStream := CrLfFileStream forceNewFileNamed: fileName.
	aStream ifNil: [Error signal: 'Could not open C header file: ', fileName].
	aStream
		nextPutAll: '/* ';
		nextPutAll: VMMaker headerNotice;
		nextPutAll: ' */'; cr; cr;
		nextPutAll: '#ifndef HAVE_INTERP_H'; cr;
		nextPutAll: '# define HAVE_INTERP_H'; cr;
		nextPutAll: '#endif'; cr; cr.
	self emitVmmVersionOn: aStream.
	(Smalltalk classNamed: interpreterClassName)
		emitInterpreterProxyVersionOn: aStream.
	self emitDefineBytesPerWordOn: aStream.
	self emitDefineMemoryAccessInImageOn: aStream.
	aStream cr.
	aStream close

]

{ #category : #public }
JSCodeGenerator >> storeHeaderOnFile: fileName contents: contents [
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

{ #category : #'JS code generator' }
JSCodeGenerator >> structTargetKindForVariableName: varName [ "<String>"
	^VMStructType structTargetKindForDeclaration: (self typeOfVariable: varName)
]

{ #category : #utilities }
JSCodeGenerator >> translationMethodClass [
	"return the class used to produce JS translation methods from MethodNodes"
	^JSMethod
]

{ #category : #'JS code generator' }
JSCodeGenerator >> typeOfArgument: argIndex in: selector [
	| method |
	method := methods at: selector.
	^method declarations at: (method args at: argIndex).

]

{ #category : #'JS code generator' }
JSCodeGenerator >> typeOfVariable: varName [ "<String>" 
	scopeStack reverseDo:
		[:dict|
		(dict includesKey: varName) ifTrue:
			[^dict at: varName]].
	^variableDeclarations at: varName ifAbsent: nil
]

{ #category : #accessing }
JSCodeGenerator >> uncheckedAbstractMethods [
	"Answer the selectors for methods that should not be checked to ensure existence
	of concrete implementations, such as methods that are generated directly by the
	code generator itself."

	^uncheckedAbstractMethods


]

{ #category : #utilities }
JSCodeGenerator >> unreachableMethods [
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
JSCodeGenerator >> useSymbolicConstants [
	"Answer whether we should generate symbolic constants instead of their actual values"
	^useSymbolicConstants
]

{ #category : #accessing }
JSCodeGenerator >> useSymbolicConstants: aBool [
	"Indicate whether we should generate symbolic constants instead of their actual values"
	useSymbolicConstants := aBool
]

{ #category : #public }
JSCodeGenerator >> var: varName declareC: declarationString [
	"Record the given C declaration for a global variable."

	(declarationString includesSubString: varName) ifFalse:
		[self error: 'declaration omits variable name.  probably an error.  use e.g. var:type:'].
	variableDeclarations at: varName asString put: declarationString.
]

{ #category : #public }
JSCodeGenerator >> var: varName type: type [
"Use this in preference to #var:declareC: whenver possible since it avoids typing the varname twice and thus avoids the potential for a typo. See also #var:type:array:"
	self var: varName declareC: type , ' ' , varName
]

{ #category : #public }
JSCodeGenerator >> var: varName type: type array: array [
"use this in preference to #var:declareC: when possible. This produces a JS statment of the form
var fooArray = [1,2,3]
See also #var:type: for simple var decls" 
	self
		var: varName
		declareC: (String streamContents: [:s |
			s nextPutAll: type.
			s space.
			s nextPutAll: varName.
			s nextPutAll: ' = ['.
			self printArray: array on: s.
			s nextPut: $]])
]

{ #category : #public }
JSCodeGenerator >> vmClass [
	"Answer the interpreter classs if any.  This is nil other than for the core VM."
	^vmClass
]

{ #category : #public }
JSCodeGenerator >> vmClass: aClass [
	"Set the interpreter class if any.  This is nil other than for the core VM."
	vmClass := aClass
]
