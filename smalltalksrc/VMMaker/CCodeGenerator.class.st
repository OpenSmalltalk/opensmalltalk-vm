"
This class oversees the translation of a subset of Smalltalk to C, allowing the comforts of Smalltalk during development and the efficiency and portability of C for the resulting interpreter.  
See VMMaker for more useful info
"
Class {
	#name : #CCodeGenerator,
	#superclass : #Object,
	#instVars : [
		'translationDict',
		'inlineList',
		'constants',
		'variables',
		'variableDeclarations',
		'scopeStack',
		'methods',
		'preparedMethodList',
		'variablesSetCache',
		'headerFiles',
		'globalVariableUsage',
		'useSymbolicConstants',
		'generateDeadCode',
		'doNotRemoveMethodList',
		'asArgumentTranslationDict',
		'vmClass',
		'currentMethod'
	],
	#classVars : [
		'UseRightShiftForDivide'
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
	| source |
	self checkClassForNameConflicts: aClass.
	self addClassVarsFor: aClass.
	"ikp..."
	self addPoolVarsFor: aClass.
	variables addAll: aClass instVarNames.
	self retainMethods: aClass requiredMethodNames.
	
	'Adding Class ' , aClass name , '...'
		displayProgressAt: Sensor cursorPoint
		from: 0
		to: aClass selectors size
		during: [:bar | aClass selectors
				doWithIndex: 
					[:sel :i | 
					bar value: i.
					source := aClass sourceCodeAt: sel.
					self addMethod: ((Compiler new
							parse: source
							in: aClass
							notifying: nil)
							asTranslationMethodOfClass: self translationMethodClass)]].
	aClass declareCVarsIn: self
]

{ #category : #public }
CCodeGenerator >> addClassVarsFor: aClass [
	"Add the class variables for the given class to the code base as constants."
	| val node |
	aClass classPool associationsDo: [:assoc | 
		val := assoc value.
		(useSymbolicConstants and:[self isCLiteral: val])
			ifTrue:[node := TDefineNode new setName: assoc key asString value: assoc value]
			ifFalse:[node := TConstantNode new setValue: assoc value].
		constants at: assoc key asString put: node].

]

{ #category : #public }
CCodeGenerator >> addHeaderFile: aString [
	"Add a header file. The argument must be a quoted string!"
	headerFiles addLast: aString.
]

{ #category : #utilities }
CCodeGenerator >> addMethod: aTMethod [
	"Add the given method to the code base."

	(methods includesKey:  aTMethod selector) ifTrue: [
		self error: 'Method name conflict: ', aTMethod selector.
	].
	methods at: aTMethod selector put: aTMethod.
]

{ #category : #public }
CCodeGenerator >> addMethodsForPrimitives: classAndSelectorList [ 
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
	self doInlining: true.

	methods do:[:m|
		"if this method is supposed to be a primitive (rather than a helper 
		routine), add assorted prolog and epilog items"
		m primitive > 0 ifTrue: [m preparePrimitivePrologue]].
]

{ #category : #public }
CCodeGenerator >> addPoolVarsFor: aClass [ 
	"Add the pool variables for the given class to the code base as constants."
	| val node |
	aClass sharedPools do: [:pool |
		pool bindingsDo: [:assoc |
			val := assoc value.
			(useSymbolicConstants and:[self isCLiteral: val])
				ifTrue:[node := TDefineNode new setName: assoc key asString value: assoc value]
				ifFalse:[node := TConstantNode new setValue: assoc value].
			constants at: assoc key asString put: node]].
]

{ #category : #utilities }
CCodeGenerator >> builtin: sel [ 
	"Answer true if the given selector is one of the builtin selectors."
	^ sel = #error:
		or: [(self memoryAccessSelectors includes: sel)
				or: [translationDict includesKey: sel]]
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
	^aSelector copyWithout: $:
]

{ #category : #'C code generator' }
CCodeGenerator >> cLiteralFor: anObject [
	"Return a string representing the C literal value for the given object."
	(anObject isKindOf: Integer) ifTrue: [
		(anObject < 16r7FFFFFFF)
			ifTrue: [^ anObject printString]
			ifFalse: [^ anObject printString , ObjectMemory unsignedIntegerSuffix "ikp"]].
	(anObject isKindOf: String) ifTrue: [^ '"', anObject, '"' ].
	(anObject isKindOf: Float) ifTrue: [^ anObject printString ].
	anObject == nil ifTrue: [^ 'null' ].
	anObject == true ifTrue: [^ '1' ].			"ikp"
	anObject == false ifTrue: [^ '0' ].			"ikp"
	(anObject isKindOf: Character) ifTrue:[^anObject asString printString]. "ar"
	self error:								"ikp"
		'Warning: A Smalltalk literal could not be translated into a C constant: ', anObject printString.
	^'"XXX UNTRANSLATABLE CONSTANT XXX"'
]

{ #category : #'error notification' }
CCodeGenerator >> checkClassForNameConflicts: aClass [
	"Verify that the given class does not have constant, variable, or method names that conflict with those of previously added classes. Raise an error if a conflict is found, otherwise just return."

	"check for constant name collisions"
	aClass classPool associationsDo: [ :assoc |
		(constants includesKey: assoc key asString) ifTrue: [
			self error: 'Constant was defined in a previously added class: ', assoc key.
		].
	].
	"ikp..."
	aClass sharedPools do: [:pool |
		pool bindingsDo: [ :assoc |
			(constants includesKey: assoc key asString) ifTrue: [
				self error: 'Constant was defined in a previously added class: ', assoc key.
			].
		].
	].

	"check for instance variable name collisions"
	aClass instVarNames do: [ :varName |
		(variables includes: varName) ifTrue: [
			self error: 'Instance variable was defined in a previously added class: ', varName.
		].
	].

	"check for method name collisions"
	aClass selectors do: [ :sel |
		(methods includesKey: sel) ifTrue: [
			self error: 'Method was defined in a previously added class: ', sel.
		].
	].
]

{ #category : #utilities }
CCodeGenerator >> checkForGlobalUsage: vars in: aTMethod [ 
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
					item add: aTMethod selector]].
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
CCodeGenerator >> collectInlineList [
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

{ #category : #inlining }
CCodeGenerator >> doBasicInlining: inlineFlag [
	"Inline the bodies of all methods that are suitable for inlining.
	This method does only the basic inlining suitable for both the core VM and plugins - no bytecode inlining etc"

	| pass progress |
	self collectInlineList.
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
CCodeGenerator >> doInlining: inlineFlag [
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

	"make receiver on the next line false to generate code for all methods, even those that are inlined or unused"
	true ifTrue: [
		(methods includesKey: #interpret) ifTrue: [
			"only prune when generating the interpreter itself"
			self pruneUnreachableMethods]].

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
CCodeGenerator >> emitCCodeOn: aStream doAssertions: assertionFlag [
	"Emit C code for all methods in the code base onto the given stream. All inlined method calls should already have been expanded."

	self emitCHeaderOn: aStream.
	self emitCConstantsOn: aStream.
	self emitCFunctionPrototypes: preparedMethodList on: aStream.
	self emitCVariablesOn: aStream.
'Writing Translated Code...'
displayProgressAt: Sensor cursorPoint
from: 0 to: methods size
during: [:bar |
	preparedMethodList doWithIndex: [ :m :i | bar value: i.
		m emitCCodeOn: aStream generator: self.
]].
	self emitExportsOn: aStream.

]

{ #category : #'C code generator' }
CCodeGenerator >> emitCCodeOn: aStream doInlining: inlineFlag doAssertions: assertionFlag [
	"Emit C code for all methods in the code base onto the given stream. All inlined method calls should already have been expanded."

	self prepareMethodsInlined: inlineFlag doAssertions: assertionFlag.
	^ self emitCCodeOn: aStream doAssertions: assertionFlag

]

{ #category : #'C code generator' }
CCodeGenerator >> emitCConstantsOn: aStream [
	"Store the global variable declarations on the given stream."
	| unused constList node |
	unused := constants keys asSet.
	methods do: [ :meth |
		meth parseTree nodesDo: [ :n |
			n isConstant ifTrue: [ unused remove: n name ifAbsent: []]]].
	constList := constants keys reject: [ :any | unused includes: any].
	aStream nextPutAll: '/*** Constants ***/';
		 cr.
	constList asSortedCollection do: [ :varName |
		node := constants at: varName.
		node name isEmpty ifFalse: [
			aStream nextPutAll: '#define '.
			aStream nextPutAll: node name.
			aStream space.
			aStream nextPutAll: (self cLiteralFor: node value).
			aStream cr
		].
	].
	aStream cr.
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCExpression: aParseNode on: aStream [
	"Emit C code for the expression described by the given parse node."

	aParseNode isLeaf ifTrue: [
		"omit parens"
		aParseNode asExpression emitCCodeOn: aStream level: 0 generator: self.
	] ifFalse: [
		aStream nextPut: $(.
		aParseNode asExpression emitCCodeOn: aStream level: 0 generator: self.
		aStream nextPut: $).
	].
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCFunctionPrototypes: methodList on: aStream [ 
	"Store prototype declarations for all non-inlined methods on the given stream."
	| exporting |
	aStream nextPutAll: '/*** Function Prototypes ***/'; cr.
	exporting := false.
	methodList do: [:m | 
		m export
			ifTrue: [exporting
					ifFalse: 
						[aStream nextPutAll: '#pragma export on'; cr.
						exporting := true]]
			ifFalse: [exporting
					ifTrue: 
						[aStream nextPutAll: '#pragma export off'; cr.
						exporting := false]].
		m emitCFunctionPrototype: aStream generator: self.
		aStream nextPutAll: ';'; cr].
	exporting ifTrue: [aStream nextPutAll: '#pragma export off'; cr]
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCHeaderForPrimitivesOn: aStream [
	"Write a C file header for compiled primitives onto the given stream."

	aStream
		nextPutAll: '/* Automatically generated from Squeak (';
		nextPutAll: VMMaker versionString;
		nextPutAll: ') on '.
	Time dateAndTimeNow do: [:e | aStream nextPutAll: e asString; nextPut: Character space].
	aStream
		nextPutAll: '*/';
		cr; cr;
		nextPutAll: '#include "sq.h"'; cr; cr.

	"Additional header files"
	headerFiles do:[:hdr|
		aStream nextPutAll:'#include '; nextPutAll: hdr; cr].

	aStream nextPutAll: '
#include "sqMemoryAccess.h"

/*** Imported Functions/Variables ***/
extern sqInt stackValue(sqInt);
extern sqInt stackIntegerValue(sqInt);
extern sqInt successFlag;

/* allows accessing Strings in both C and Smalltalk */
#define asciiValue(c) c
'.
	aStream cr.
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCHeaderOn: aStream [
	"Write a C file header onto the given stream."

	aStream nextPutAll: '/* '.
	aStream nextPutAll: VMMaker headerNotice.
	aStream nextPutAll: ' */'; cr.
	self emitGlobalStructFlagOn: aStream.
	aStream nextPutAll: '#include "sq.h"'; cr.

	"Additional header files"
	headerFiles do:[:hdr|
		aStream nextPutAll:'#include '; nextPutAll: hdr; cr].

	"Default definitions for optional functions, provided for backward compatibility"
	self emitDefaultMacrosOn: aStream.

	aStream nextPutAll: '
#include "sqMemoryAccess.h"

sqInt printCallStack(void);
void defaultErrorProc(char *s) {
	/* Print an error message and exit. */
	static sqInt printingStack = false;

	printf("\n%s\n\n", s);
	if (!printingStack) {
		/* flag prevents recursive error when trying to print a broken stack */
		printingStack = true;
		printCallStack();
	}
	exit(-1);
}
'.
	aStream cr.
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCTestBlock: aBlockNode on: aStream [
	"Emit C code for the given block node to be used as a loop test."

	aBlockNode statements size > 1 ifTrue: [
		aBlockNode emitCCodeOn: aStream level: 0 generator: self.
	] ifFalse: [
		aBlockNode statements first asExpression emitCCodeOn: aStream level: 0 generator: self.
	].
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCVariablesOn: aStream [ 
	"Store the global variable declarations on the given stream."
	| varString |
	aStream nextPutAll: '/*** Variables ***/';
		 cr.
	variables asSortedCollection
		do: [:var | 
			varString := var asString.
			self isGeneratingPluginCode
				ifTrue: [varString = 'interpreterProxy'
						ifTrue: ["quite special..."
							aStream cr; nextPutAll: '#ifdef SQUEAK_BUILTIN_PLUGIN'.
							aStream cr; nextPutAll: 'extern'.
							aStream cr; nextPutAll: '#endif'; cr]
						ifFalse: [aStream nextPutAll: 'static ']].
			(variableDeclarations includesKey: varString)
				ifTrue: [aStream nextPutAll: (variableDeclarations at: varString) , ';'; cr]
				ifFalse: ["default variable declaration"
					aStream nextPutAll: 'sqInt ' , varString , ';'; cr]].
	aStream cr
]

{ #category : #'C code generator' }
CCodeGenerator >> emitDefaultMacrosOn: aStream [
	"Emit macros to provide default implementations of certain functions used by
	the interpreter. If not previously defined in config.h they will be defined here.
	The definitions will be available to any module that includes sqMemoryAccess.h.
	The default macros are chosen for backward compatibility with existing platform
	support code."

	aStream cr;
		nextPutAll: '#ifndef allocateMemoryMinimumImageFileHeaderSize'; cr;
		nextPutAll: ' /* Called by Interpreter>>allocateMemory:minimum:imageFile:headerSize: */'; cr;
		nextPutAll: ' /* Default definition if not previously defined in config.h */'; cr;
		nextPutAll: ' #define allocateMemoryMinimumImageFileHeaderSize(',
						'heapSize, minimumMemory, fileStream, headerSize) \'; cr;
		nextPutAll: '    sqAllocateMemory(minimumMemory, heapSize)'; cr;
		nextPutAll: '#endif'; cr; cr;

		nextPutAll: '#ifndef sqImageFileReadEntireImage'; cr;
		nextPutAll: ' /* Called by Interpreter>>sqImage:read:size:length: */'; cr;
		nextPutAll: ' /* Default definition if not previously defined in config.h */'; cr;
		nextPutAll: ' #define sqImageFileReadEntireImage(memoryAddress, ',
						'elementSize,  length, fileStream) \'; cr;
		nextPutAll: '    sqImageFileRead(memoryAddress, elementSize,  length, fileStream)'; cr;
		nextPutAll: '#endif'; cr; cr;

		nextPutAll: '#ifndef error'; cr;
		nextPutAll: ' /* error() function called from Interpreter */'; cr;
		nextPutAll: ' /* Default definition if not previously defined in config.h */'; cr;
		nextPutAll: ' #define error(str) defaultErrorProc(str)'; cr;
		nextPutAll: '#endif'; cr; cr;

		nextPutAll: '#ifndef ioMicroSecondClock'; cr;
		nextPutAll: ' /* Called by Interpreter>>primitiveMicrosecondClock and GC methods */'; cr;
		nextPutAll: ' /* Default definition if not previously defined in config.h */'; cr;
		nextPutAll: ' #define ioMicroSecondClock ioMSecs'; cr;
		nextPutAll: '#endif'; cr; cr;

		nextPutAll: '#ifndef ioUtcWithOffset'; cr;
		nextPutAll: ' /* Called by Interpreter>>primitiveUtcWithOffset */'; cr;
		nextPutAll: ' /* Default definition if not previously defined in config.h */'; cr;
		nextPutAll: ' #define ioUtcWithOffset(clock, offset) setMicroSecondsandOffset(clock, offset)'; cr;
		nextPutAll: '#endif'; cr.

		self flag: #setMicroSeconds:andOffset:	"referenced by these macros"

]

{ #category : #'C code generator' }
CCodeGenerator >> emitDefineBytesPerWordOn: aStream [
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
		nextPutAll: '#endif //  (BYTES_PER_WORD == 4)'; cr
	

]

{ #category : #'C code generator' }
CCodeGenerator >> emitDefineMemoryAccessInImageOn: aStream [
	"If MemoryAccess is present in the image, then define MEMORY_ACCESS_IN_IMAGE as
	a C preprocessor macro. When MEMORY_ACCESS_IN_IMAGE is defined, the traditional
	C preprocessor macros for low level memory access are ignored and will be replaced
	by directly translated (and inlined) SLANG versions of the same. This enables visibility
	of the memory access functions for debuggers and profilers."

	(Smalltalk classNamed: #MemoryAccess)
		ifNotNilDo: [:ma | ma isEnabled
			ifTrue: [aStream nextPutAll: '#define MEMORY_ACCESS_IN_IMAGE 1'; cr]]
]

{ #category : #'C code generator' }
CCodeGenerator >> emitExportsOn: aStream [
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

{ #category : #'C code generator' }
CCodeGenerator >> emitGlobalStructFlagOn: aStream [
	"Default: do nothing.  Overridden in CCGenGlobalStruct."

]

{ #category : #'C code generator' }
CCodeGenerator >> emitVmmVersionOn: aStream [
	"Emit a version string macro suitable for identifying source code version
	of this interpreter. This is expected to be used in conjunction with a similar
	identifier for platform source code version, such the the VM can identify
	the source code version for its platform source and matching VMMaker source."

	aStream nextPutAll: '#define VMMAKER_VERSION "';
		nextPutAll: VMMaker versionString;
		nextPut: $";
		cr

]

{ #category : #public }
CCodeGenerator >> exportedPrimitiveNames [
	"Return an array of all exported primitives"
	^methods select:[:m| m export] thenCollect:[:m| m selectorForCodeGeneration copyWithout: $:].

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
CCodeGenerator >> generateBaseHeaderSize: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: 'BASE_HEADER_SIZE'


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
CCodeGenerator >> generateBytesPerWord: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: 'BYTES_PER_WORD'

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
	testStmt asExpression emitCCodeOn: aStream level: 0 generator: self.
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
	testStmt asExpression emitCCodeOn: aStream level: 0 generator: self.
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
			aStream tab: level; nextPut: $}; nextPutAll: ' else {'; cr.
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
			aStream tab: level; nextPut: $}; nextPutAll: ' else {'; cr.
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
			msgNode receiver emitCCodeAsArgumentOn: aStream level: level generator: self.
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
		ifTrue: [aStream nextPutAll: msgNode args first value]
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
		ifTrue: [aStream nextPutAll: msgNode args first value]
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
CCodeGenerator >> generateInlineCppDirective: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream cr; nextPutAll: '# ', msgNode args first value.
]

{ #category : #'C translation' }
CCodeGenerator >> generateInlineCppIfDef: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| comment |
	aStream cr; nextPutAll: '# ifdef ', msgNode args first value.
	comment := msgNode args third value.
	(comment isKindOf: String)
		ifTrue: [aStream nextPutAll: '  // ', comment]
		ifFalse: ["nil argument, ignore it"].
	aStream cr.
	msgNode isExpression
		ifTrue:
			[aStream tab: level + 1; nextPut: $(.
			msgNode args fourth asExpression
				emitCCodeOn: aStream level: level + 1 generator: self.
			aStream nextPut: $); cr]
		ifFalse:
			[msgNode args fourth
				emitCCodeOn: aStream level: level generator: self].
	aStream nextPutAll: '# endif  // ', msgNode args first value; cr; tab: level
]

{ #category : #'C translation' }
CCodeGenerator >> generateInlineCppIfDefElse: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| comment alternateBlock alternateBlockIsNil |
	aStream cr; nextPutAll: '# ifdef ', msgNode args first value.
	comment := msgNode args third value.
	(comment isKindOf: String)
		ifTrue: [aStream nextPutAll: '  // ', comment]
		ifFalse: ["nil argument, ignore it"].
	aStream cr.
	msgNode isExpression
		ifTrue:
			[aStream tab: level + 1; nextPut: $(.
			msgNode args fourth asExpression
				emitCCodeOn: aStream level: level + 1 generator: self.
			aStream nextPut: $); cr]
		ifFalse:
			[msgNode args fourth
				emitCCodeOn: aStream level: level generator: self].
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
					emitCCodeOn: aStream level: level + 1 generator: self.
				aStream nextPut: $); cr]
			ifFalse:
				[alternateBlock
					emitCCodeOn: aStream level: level generator: self]].
	aStream nextPutAll: '# endif  // ', msgNode args first value; cr; tab: level

]

{ #category : #'C translation' }
CCodeGenerator >> generateInlineCppIfElse: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| comment alternateBlock alternateBlockIsNil |
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
				emitCCodeOn: aStream level: level + 1 generator: self.
			aStream nextPut: $); cr]
		ifFalse:
			[msgNode args fourth
				emitCCodeOn: aStream level: level generator: self].
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
					emitCCodeOn: aStream level: level + 1 generator: self.
				aStream nextPut: $); cr]
			ifFalse:
				[alternateBlock
					emitCCodeOn: aStream level: level generator: self]].
	aStream nextPutAll: '# endif  // ', msgNode args first value; cr; tab: level

]

{ #category : #'C translation' }
CCodeGenerator >> generateInlineDirective: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: '/* inline: '.
	aStream nextPutAll: msgNode args first value asString.
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
	aStream nextPutAll: ' && ('.
	self emitCTestBlock: msgNode args first on: aStream.
	aStream nextPut: $)
]

{ #category : #'C translation' }
CCodeGenerator >> generateSequentialOr: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."
	"Note: PP 2.3 compiler produces two arguments for or:, presumably
	 to help with inlining later. Taking the last agument should do the correct
	 thing even if your compiler is different."

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' || ('.
	self emitCTestBlock: msgNode args last on: aStream.
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

	aStream nextPutAll: '((usqInt) '.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ')'.
	aStream nextPutAll: ' >> '.
	self emitCExpression: msgNode args first on: aStream.
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
	self emitCTestBlock: msgNode receiver on: aStream.
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
	testStmt asExpression emitCCodeOn: aStream level: 0 generator: self.
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
	testStmt asExpression emitCCodeOn: aStream level: 0 generator: self.
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
	self emitCTestBlock: msgNode receiver on: aStream.
	aStream nextPutAll: ') {'; cr.
	msgNode args first isNilStmtListNode ifFalse:
		[msgNode args first emitCCodeOn: aStream level: level + 1 generator: self].
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '}'.
]

{ #category : #public }
CCodeGenerator >> globalsAsSet [
	"Used by the inliner to avoid name clashes with global variables."

	((variablesSetCache == nil) or:
	 [variablesSetCache size ~= variables size]) ifTrue: [
		variablesSetCache := variables asSet.
	].
	^ variablesSetCache
]

{ #category : #public }
CCodeGenerator >> initialize [
	translationDict := Dictionary new.
	inlineList := Array new.
	constants := Dictionary new: 100.
	variables := OrderedCollection new: 100.
	variableDeclarations := Dictionary new: 100.
	methods := Dictionary new: 500.
	self initializeCTranslationDictionary.
	headerFiles := OrderedCollection new.
	globalVariableUsage := Dictionary new.
	useSymbolicConstants := true.
	generateDeadCode := true.
	scopeStack := OrderedCollection new.
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

	#bitAnd:		#generateBitAnd:on:indent:
	#bitOr:			#generateBitOr:on:indent:
	#bitXor:		#generateBitXor:on:indent:
	#bitShift:		#generateBitShift:on:indent:
	#signedBitShift:	#generateSignedBitShift:on:indent:
	#bitInvert32		#generateBitInvert32:on:indent:

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

]

{ #category : #inlining }
CCodeGenerator >> inlineCaseStatementBranchesInMethodNamed: selector localizingVars: varsList [ 
	"Inline case statement branches in the method with the given name."
	(self methodNamed: selector)
		ifNotNilDo: [:m | m inlineCaseStatementBranchesIn: self localizingVars: varsList]
]

{ #category : #inlining }
CCodeGenerator >> inlineDispatchesInMethodNamed: selector localizingVars: varsList [
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

{ #category : #utilities }
CCodeGenerator >> isGeneratingPluginCode [
	^false
]

{ #category : #public }
CCodeGenerator >> isGlobalStructureBuild [
	^false
]

{ #category : #'C code generator' }
CCodeGenerator >> isNonArgumentImplicitReceiverVariableName: aString [
	^(self typeOfVariable: aString) == #implicit
	    or: [vmClass
			ifNil: [#('interpreterProxy' 'self') includes: aString]
	 		ifNotNil: [vmClass isNonArgumentImplicitReceiverVariableName: aString]]
]

{ #category : #'C code generator' }
CCodeGenerator >> isPointerToStructVariableName: varName [ "<String>"
	^self isTypePointerToStruct: (self typeOfVariable: varName)
]

{ #category : #'C code generator' }
CCodeGenerator >> isTypePointerToStruct: type [ "<String>"
	^vmClass notNil
	  and: [vmClass isTypePointerToStruct: type]
]

{ #category : #utilities }
CCodeGenerator >> localizeGlobalVariables [
	| candidates procedure |

	"find all globals used in only one method"
	candidates := globalVariableUsage select: [:e | e size = 1].
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

{ #category : #inlining }
CCodeGenerator >> mayInline: sel [
	"Answer true if the method with the given selector may be inlined."

	^ inlineList includes: sel
]

{ #category : #utilities }
CCodeGenerator >> memoryAccessSelectors [
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
CCodeGenerator >> methodNamed: selector [
	"Answer the method in the code base with the given selector."

	^ methods at: selector ifAbsent: [ nil ]
]

{ #category : #inlining }
CCodeGenerator >> methodStatsString [
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
CCodeGenerator >> prepareMethods [
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
		m bindClassVariablesIn: constants.
		m prepareMethodIn: self.
	].
]

{ #category : #'C code generator' }
CCodeGenerator >> prepareMethodsInlined: inlineFlag doAssertions: assertionFlag [
	"Prepare to emit C code for all methods in the code base. All inlined method calls should be expanded. Answer a list of methods to be emitted as C code."

	| verbose methodList |
	"method preparation"
	verbose := false.
	self prepareMethods.
	verbose ifTrue: [
		self printUnboundCallWarnings.
		self printUnboundVariableReferenceWarnings.
		Transcript cr.
	].
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

	Transcript cr.
	undefinedCalls keys asSortedCollection do: [ :undefined |
		Transcript show: undefined, ' -- undefined method sent by:'; cr.
		(undefinedCalls at: undefined) do: [ :caller |
			Transcript tab; show: caller; cr.
		].
	].
]

{ #category : #'error notification' }
CCodeGenerator >> printUnboundVariableReferenceWarnings [
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
CCodeGenerator >> pruneMethods: selectorList [
	"Explicitly prune some methods"
	selectorList do:[:sel| methods removeKey: sel ifAbsent:[]].
]

{ #category : #inlining }
CCodeGenerator >> pruneUnreachableMethods [
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

{ #category : #inlining }
CCodeGenerator >> removeMethodsReferingToGlobals: varList except: methodNames [
	"Remove any methods (presumably inlined) that still contain references to the given obsolete global variables."

	| varListAsStrings mVars |
	varListAsStrings := varList collect: [ :sym | sym asString ].
		(methods keys copyWithoutAll: methodNames) do: [ :sel |
			mVars := (self methodNamed: sel) freeVariableReferences asSet.
			(mVars includesAnyOf: varListAsStrings)
				ifTrue: [methods removeKey: sel ifAbsent: []]]

]

{ #category : #utilities }
CCodeGenerator >> reportRecursiveMethods [
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
CCodeGenerator >> retainMethods: aListOfMethodsToKeep [
"add aListOfMethodsToKeep to doNotRemoveMethodList so that they will not be pruned"
	doNotRemoveMethodList ifNil:[doNotRemoveMethodList := Set new:100].
	doNotRemoveMethodList addAll: aListOfMethodsToKeep.
	^aListOfMethodsToKeep
]

{ #category : #utilities }
CCodeGenerator >> returnPrefixFromVariable: aName [
	^aName
]

{ #category : #'C code generator' }
CCodeGenerator >> selectorReturnsPointerToStruct: selector [ "<Symbol>"
	| tMethod |
	^vmClass notNil
	  and: [(tMethod := methods at: selector ifAbsent: []) notNil
	  and: [vmClass isTypePointerToStruct: tMethod returnType]]
]

{ #category : #utilities }
CCodeGenerator >> sortMethods: aTMethodCollection [
	"We need to define this since different Squeak versions answer different results
	 for asSortedCollection and if sort order changes, generated code changes too."
	^aTMethodCollection asSortedCollection:
		[:a :b| a selector caseSensitiveLessOrEqual: b selector]
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
	stream := CrLfFileStream forceNewFileNamed: fileName.
	stream ifNil: [Error signal: 'Could not open C code file: ', fileName].
	self emitCCodeOn: stream doInlining: inlineFlag doAssertions: assertionFlag.
	stream close
]

{ #category : #public }
CCodeGenerator >> storeHeaderOnFile: fileName [
	"Store C header code for this interpreter on the given file."

	| aStream |
	aStream := CrLfFileStream forceNewFileNamed: fileName.
	aStream ifNil: [Error signal: 'Could not open C header file: ', fileName].
	aStream
		nextPutAll: '/* ';
		nextPutAll: VMMaker headerNotice;
		nextPutAll: ' */'; cr; cr.
	self emitVmmVersionOn: aStream.
	self emitDefineBytesPerWordOn: aStream.
	self emitDefineMemoryAccessInImageOn: aStream.
	aStream cr.
	aStream close

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
"Use this in preference to #var:declareC: whenver possible since it avoids typing the varname twice and thus avoids the potential for a typo. See also #var:type:array:"
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
