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
		'methods',
		'variablesSetCache',
		'headerFiles',
		'globalVariableUsage',
		'useSymbolicConstants',
		'generateDeadCode',
		'doNotRemoveMethodList'
	],
	#classVars : [
		'UseRightShiftForDivide'
	],
	#category : 'VMMaker-Translation to C'
}

{ #category : #'class initialization' }
CCodeGenerator class >> initialize [
	"CCodeGenerator initialize"

	UseRightShiftForDivide _ true.
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
	allClasses _ aClass withAllSuperclasses.
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
					source _ aClass sourceCodeAt: sel.
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
		val _ assoc value.
		(useSymbolicConstants and:[self isCLiteral: val])
			ifTrue:[node _ TDefineNode new setName: assoc key asString value: assoc value]
			ifFalse:[node _ TConstantNode new setValue: assoc value].
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
	classAndSelectorList do: 
		[:classAndSelector | 
		aClass _ Smalltalk at: (classAndSelector at: 1).
		self addAllClassVarsFor: aClass.
"TPR - should pool vars also be added here?"

		"find the method in either the class or the metaclass"
		sel _ classAndSelector at: 2.
		(aClass includesSelector: sel)
			ifTrue: [source _ aClass sourceCodeAt: sel]
			ifFalse: [source _ aClass class sourceCodeAt: sel].

		"compile the method source and convert to a suitable translation 
		method "
		meth _ (Compiler new
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
	verbose _ false.
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
			val _ assoc value.
			(useSymbolicConstants and:[self isCLiteral: val])
				ifTrue:[node _ TDefineNode new setName: assoc key asString value: assoc value]
				ifFalse:[node _ TConstantNode new setValue: assoc value].
			constants at: assoc key asString put: node]].
]

{ #category : #utilities }
CCodeGenerator >> builtin: sel [
	"Answer true if the given selector is one of the builtin selectors."

	((sel = #longAt:) or: [(sel = #longAt:put:) or: [sel = #error:]]) ifTrue: [ ^true ].
	((sel = #byteAt:) or: [sel = #byteAt:put:]) ifTrue: [ ^true ].
	^translationDict includesKey: sel
]

{ #category : #utilities }
CCodeGenerator >> cCodeForMethod: selector [
	"Answer a string containing the C code for the given method."
	"Example:
		((CCodeGenerator new initialize addClass: TestCClass1; prepareMethods)
			cCodeForMethod: #ifTests)"

	| m s |
	m _ self methodNamed: selector.
	m = nil ifTrue: [ self error: 'method not found in code base: ', selector ].

	s _ (ReadWriteStream on: '').
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
			ifFalse: [^ anObject printString , 'U']].
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
					item _ globalVariableUsage
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
	stream _ ReadWriteStream on: (String new: 1000).
	self emitCCodeOn: stream doInlining: true doAssertions: true.
	^stream contents
]

{ #category : #public }
CCodeGenerator >> codeStringForPrimitives: classAndSelectorList [ 
"TPR - appears to be obsolete now"
	self addMethodsForPrimitives: classAndSelectorList.
	^self generateCodeStringForPrimitives
]

{ #category : #inlining }
CCodeGenerator >> collectInlineList [
	"Make a list of methods that should be inlined."
	"Details: The method must not include any inline C, since the
translator cannot currently map variable names in inlined C code.
Methods to be inlined must be small or called from only one place."

	| methodsNotToInline callsOf inlineIt hasCCode nodeCount senderCount
sel |
	methodsNotToInline _ Set new: methods size.

	"build dictionary to record the number of calls to each method"
	callsOf _ Dictionary new: methods size * 2.
	methods keys do: [ :s | callsOf at: s put: 0 ].

	"For each method, scan its parse tree once to:
		1. determine if the method contains C code or declarations
		2. determine how many nodes it has
		3. increment the sender counts of the methods it calls
		4. determine if it includes any C declarations or code"
	inlineList _ Set new: methods size * 2.
	methods do: [ :m |
		inlineIt _ #dontCare.
		(translationDict includesKey: m selector) ifTrue: [
			hasCCode _ true.
		] ifFalse: [
			hasCCode _ m declarations size > 0.
			nodeCount _ 0.
			m parseTree nodesDo: [ :node |
				node isSend ifTrue: [
					sel _ node selector.
					(sel = #cCode: or: [sel = #cCode:inSmalltalk:])
						ifTrue: [ hasCCode _ true ].
					senderCount _ callsOf at: sel ifAbsent: [ nil ].
					nil = senderCount ifFalse: [
						callsOf at: sel put: senderCount + 1.
					].
				].
				nodeCount _ nodeCount + 1.
			].
			inlineIt _ m extractInlineDirective.  "may be true, false, or
#dontCare"
		].
		(hasCCode or: [inlineIt = false]) ifTrue: [
			"don't inline if method has C code and is contains negative inline
directive"
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
	pass _ 0.
	progress _ true.
	[progress] whileTrue: [
		"repeatedly attempt to inline methods until no further progress is made"
		progress _ false.
		('Inlining pass ', (pass _ pass + 1) printString, '...')
			displayProgressAt: Sensor cursorPoint
			from: 0 to: methods size
			during: [:bar |
				methods doWithIndex: [:m :i |
					bar value: i.
					(m tryToInlineMethodsIn: self)
						ifTrue: [progress _ true]]]].


]

{ #category : #inlining }
CCodeGenerator >> doInlining: inlineFlag [
	"Inline the bodies of all methods that are suitable for inlining."
	"Modified slightly for the core VM translator, since the first level of inlining for the interpret loop must be performed in order that the instruction implementations can easily discover their addresses. Remember to inline the bytecode routines as well"

	inlineFlag ifFalse: [
		self inlineDispatchesInMethodNamed: #interpret localizingVars: #().
		^ self].

	self doBasicInlining: inlineFlag.
	
	'Inlining bytecodes'
		displayProgressAt: Sensor cursorPoint
		from: 1 to: 2
		during: [:bar |
			self inlineDispatchesInMethodNamed: #interpret
				localizingVars: #(currentBytecode localIP localSP localHomeContext localReturnContext localReturnValue).
			bar value: 1.
			self removeMethodsReferingToGlobals: #(
					currentBytecode localIP localSP localHomeContext)
				except: #interpret.
			bar value: 2].

	"make receiver on the next line false to generate code for all methods, even those that are inlined or unused"
	true ifTrue: [
		(methods includesKey: #interpret) ifTrue: [
			"only prune when generating the interpreter itself"
			self pruneUnreachableMethods]].

]

{ #category : #utilities }
CCodeGenerator >> emitBuiltinConstructFor: msgNode on: aStream level: level [
	"If the given selector is in the translation dictionary, translate it into a target code construct and return true. Otherwise, do nothing and return false."

	| action |
	action _ translationDict at: msgNode selector ifAbsent: [ ^false ].
	self perform: action with: msgNode with: aStream with: level.
	^true
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCCodeOn: aStream doInlining: inlineFlag doAssertions: assertionFlag [
	"Emit C code for all methods in the code base onto the given stream. All inlined method calls should already have been expanded."

	| verbose methodList |
	"method preparation"
	verbose _ false.
	self prepareMethods.
	verbose ifTrue: [
		self printUnboundCallWarnings.
		self printUnboundVariableReferenceWarnings.
		Transcript cr.
	].
	assertionFlag ifFalse: [ self removeAssertions ].
	self doInlining: inlineFlag.

	"code generation"

	methodList _ methods asSortedCollection: [ :m1 :m2 | m1 selector < m2 selector ].
	"clean out no longer valid variable names and then handle any global
		variable usage in each method"
	methodList do: [:m | self checkForGlobalUsage: m removeUnusedTemps in: m].
	self localizeGlobalVariables.

	self emitCHeaderOn: aStream.
	self emitCConstantsOn: aStream.
	self emitCFunctionPrototypes: methodList on: aStream.
	self emitCVariablesOn: aStream.
'Writing Translated Code...'
displayProgressAt: Sensor cursorPoint
from: 0 to: methods size
during: [:bar |
	methodList doWithIndex: [ :m :i | bar value: i.
		m emitCCodeOn: aStream generator: self.
]].
	self emitExportsOn: aStream.

]

{ #category : #'C code generator' }
CCodeGenerator >> emitCConstantsOn: aStream [ 
	"Store the global variable declarations on the given stream."
	| unused constList node |
	unused := constants keys.
	methods do:[:meth|
		meth parseTree nodesDo:[:n|
			n isConstant ifTrue:[unused remove: n name ifAbsent:[]]]].
	constList _ constants keys reject:[:any| unused includes: any].
	aStream nextPutAll: '/*** Constants ***/';
		 cr.
	constList asSortedCollection do:[:varName|
		node _ constants at: varName.
		node name isEmpty ifFalse:[
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
		aParseNode emitCCodeOn: aStream level: 0 generator: self.
	] ifFalse: [
		aStream nextPut: $(.
		aParseNode emitCCodeOn: aStream level: 0 generator: self.
		aStream nextPut: $).
	].
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCFunctionPrototypes: methodList on: aStream [ 
	"Store prototype declarations for all non-inlined methods on the given stream."
	| exporting |
	aStream nextPutAll: '/*** Function Prototypes ***/'; cr.
	exporting _ false.
	methodList do: [:m | 
		m export
			ifTrue: [exporting
					ifFalse: 
						[aStream nextPutAll: '#pragma export on'; cr.
						exporting _ true]]
			ifFalse: [exporting
					ifTrue: 
						[aStream nextPutAll: '#pragma export off'; cr.
						exporting _ false]].
		m emitCFunctionPrototype: aStream generator: self.
		aStream nextPutAll: ';'; cr].
	exporting ifTrue: [aStream nextPutAll: '#pragma export off'; cr]
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCHeaderForPrimitivesOn: aStream [
	"Write a C file header for compiled primitives onto the given stream."

	aStream nextPutAll: '/* Automatically generated from Squeak on '.
	aStream nextPutAll: Time dateAndTimeNow printString.
	aStream nextPutAll: ' */'; cr; cr.

	aStream nextPutAll: '#include "sq.h"'; cr; cr.

	"Additional header files"
	headerFiles do:[:hdr|
		aStream nextPutAll:'#include '; nextPutAll: hdr; cr].

	aStream nextPutAll: '
/* Memory Access Macros */
#define byteAt(i) (*((unsigned char *) (i)))
#define byteAtput(i, val) (*((unsigned char *) (i)) = val)
#define longAt(i) (*((int *) (i)))
#define longAtput(i, val) (*((int *) (i)) = val)

/*** Imported Functions/Variables ***/
extern int stackValue(int);
extern int stackIntegerValue(int);
extern int successFlag;

/* allows accessing Strings in both C and Smalltalk */
#define asciiValue(c) c
'.
	aStream cr.
]

{ #category : #'C code generator' }
CCodeGenerator >> emitCHeaderOn: aStream [
	"Write a C file header onto the given stream."

	aStream nextPutAll: '/* Automatically generated from Squeak on '.
	aStream nextPutAll: Time dateAndTimeNow printString.
	aStream nextPutAll: ' */'; cr; cr.
	self emitGlobalStructFlagOn: aStream.
	aStream nextPutAll: '#include "sq.h"'; cr.

	"Additional header files"
	headerFiles do:[:hdr|
		aStream nextPutAll:'#include '; nextPutAll: hdr; cr].

	aStream nextPutAll: '
/* memory access macros */
#define byteAt(i) (*((unsigned char *) (i)))
#define byteAtput(i, val) (*((unsigned char *) (i)) = val)
#define longAt(i) (*((int *) (i)))
#define longAtput(i, val) (*((int *) (i)) = val)

int printCallStack(void);
void error(char *s);
void error(char *s) {
	/* Print an error message and exit. */
	static int printingStack = false;

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
		aBlockNode statements first emitCCodeOn: aStream level: 0 generator: self.
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
			varString _ var asString.
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
					aStream nextPutAll: 'int ' , varString , ';'; cr]].
	aStream cr
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

{ #category : #public }
CCodeGenerator >> exportedPrimitiveNames [
	"Return an array of all exported primitives"
	^methods select:[:m| m export] thenCollect:[:m| m selector copyWithout: $:].

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

	aStream nextPutAll:'((int) '.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' )'.
]

{ #category : #'C translation' }
CCodeGenerator >> generateAt: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: '['.
	msgNode args first emitCCodeOn: aStream level: level generator: self.
	aStream nextPutAll: ']'.
]

{ #category : #'C translation' }
CCodeGenerator >> generateAtPut: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: '['.
	msgNode args first emitCCodeOn: aStream level: level generator: self.
	aStream nextPutAll: '] = '.
	self emitCExpression: msgNode args last on: aStream.
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

	aStream nextPutAll: '~'.
	self emitCExpression: msgNode receiver on: aStream.
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
	arg _ msgNode args first.
	rcvr _ msgNode receiver.
	arg isConstant ifTrue: [
		"bit shift amount is a constant"
		aStream nextPutAll: '((unsigned) '.
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
		aStream nextPutAll: ' < 0) ? ((unsigned) '.
		self emitCExpression: rcvr on: aStream.
		aStream nextPutAll: ' >> -'.
		self emitCExpression: arg on: aStream.
		aStream nextPutAll: ') : ((unsigned) '.
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
	aStream nextPutAll: ')'.


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
	generateDeadCode _ aBool
]

{ #category : #'C translation' }
CCodeGenerator >> generateDivide: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| rcvr arg divisor |
	rcvr _ msgNode receiver.
	arg _ msgNode args first.
	(arg isConstant and:
	 [UseRightShiftForDivide and:
	 [(divisor _ arg value) isInteger and:
	 [divisor isPowerOfTwo and:
	 [divisor > 0 and:
	 [divisor <= (1 bitShift: 31)]]]]])
	ifTrue: [
		"use signed (arithmetic) right shift instead of divide"
		aStream nextPutAll: '((int) '.
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
	stmts _ msgNode receiver statements asOrderedCollection.
	testStmt _ stmts removeLast.
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
	stmts _ msgNode receiver statements asOrderedCollection.
	testStmt _ stmts removeLast.
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
	"Note: PP 2.3 compiler produces two arguments for ifFalse:, presumably
	 to help with inlining later. Taking the last agument should do the correct
	 thing even if your compiler is different."

	| const |
	const _ self nilOrBooleanConstantReceiverOf: msgNode.
	const ifNotNil: [
		const ifFalse: [msgNode args first emitCCodeOn: aStream level: level generator: self].
		^ self].

	aStream nextPutAll: 'if (!('.
	msgNode receiver emitCCodeOn: aStream level: level generator: self.
	aStream nextPutAll: ')) {'; cr.
	msgNode args last emitCCodeOn: aStream level: level + 1 generator: self.
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '}'.
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfFalseIfTrue: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."
	"Note: PP 2.3 compiler reverses the argument blocks for ifFalse:ifTrue:,
       presumably to help with inlining later. That is, the first argument
       is the block to be evaluated if the condition is true. Squeak's compiler
	  does not reverse the blocks, but you may need to fix this method if
	  you wish to cross-compile using VisualWorks."

	| const |
	const _ self nilOrBooleanConstantReceiverOf: msgNode.
	const ifNotNil: [
		const
			ifTrue: [msgNode args last emitCCodeOn: aStream level: level generator: self]
			ifFalse: [msgNode args first emitCCodeOn: aStream level: level generator: self].
		^ self].

	aStream nextPutAll: 'if ('.
	msgNode receiver emitCCodeOn: aStream level: level generator: self.
	aStream nextPutAll: ') {'; cr.
	msgNode args first emitCCodeOn: aStream level: level + 1 generator: self.
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '} else {'; cr.
	msgNode args last emitCCodeOn: aStream level: level + 1 generator: self.
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '}'.
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfTrue: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| const |
	const _ self nilOrBooleanConstantReceiverOf: msgNode.
	const ifNotNil: [
		const ifTrue: [msgNode args first emitCCodeOn: aStream level: level generator: self].
		^ self].

	aStream nextPutAll: 'if ('.
	msgNode receiver emitCCodeOn: aStream level: level generator: self.
	aStream nextPutAll: ') {'; cr.
	msgNode args first emitCCodeOn: aStream level: level + 1 generator: self.
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '}'.
]

{ #category : #'C translation' }
CCodeGenerator >> generateIfTrueIfFalse: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| const |
	const _ self nilOrBooleanConstantReceiverOf: msgNode.
	const ifNotNil: [
		const
			ifTrue: [msgNode args first emitCCodeOn: aStream level: level generator: self]
			ifFalse: [msgNode args last emitCCodeOn: aStream level: level generator: self].
		^ self].

	aStream nextPutAll: 'if ('.
	msgNode receiver emitCCodeOn: aStream level: level generator: self.
	aStream nextPutAll: ') {'; cr.
	msgNode args first emitCCodeOn: aStream level: level + 1 generator: self.
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '} else {'; cr.
	msgNode args last emitCCodeOn: aStream level: level + 1 generator: self.
	level timesRepeat: [ aStream tab ].
	aStream nextPutAll: '}'.
]

{ #category : #'C translation' }
CCodeGenerator >> generateInlineCCode: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	aStream nextPutAll: msgNode args first value.
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
	aStream nextPutAll: '('.
	(msgNode args copyFrom: 2 to: msgNode args size) do:[:arg|
		self emitCExpression: arg on: aStream.
	] separatedBy:[aStream nextPutAll:', '].
	aStream nextPutAll:')'.
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
	varNode _ msgNode receiver.
	varNode isVariable
		ifFalse: [ self error: 'preDecrement can only be applied to variables' ].
	aStream nextPutAll: '--'.
	aStream nextPutAll: (self returnPrefixFromVariable: varNode name).

]

{ #category : #'C translation' }
CCodeGenerator >> generatePreIncrement: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	| varNode |
	varNode _ msgNode receiver.
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
CCodeGenerator >> generateSequentialAnd: msgNode on: aStream indent: level [
	"Generate the C code for this message onto the given stream."

	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ' && ('.
	self emitCTestBlock: msgNode args first on: aStream.
	aStream nextPutAll: ')'.
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
	aStream nextPutAll: ')'.
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

	aStream nextPutAll: '((unsigned) '.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: ')'.
	aStream nextPutAll: ' >> '.
	self emitCExpression: msgNode args first on: aStream.
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

	| iterationVar step |
	(msgNode args last args size = 1) ifFalse: [
		self error: 'wrong number of block arguments'.
	].
	iterationVar _ msgNode args last args first.
	aStream nextPutAll: 'for (', iterationVar, ' = '.
	self emitCExpression: msgNode receiver on: aStream.
	aStream nextPutAll: '; ', iterationVar,
		(((step _ msgNode args at: 2) isConstant and: [step value < 0])
			ifTrue: [' >= '] ifFalse: [' <= ']).
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
	iterationVar _ msgNode args last args first.
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
	stmts _ msgNode receiver statements asOrderedCollection.
	testStmt _ stmts removeLast.
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
	stmts _ msgNode receiver statements asOrderedCollection.
	testStmt _ stmts removeLast.
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
		variablesSetCache _ variables asSet.
	].
	^ variablesSetCache
]

{ #category : #public }
CCodeGenerator >> initialize [
	translationDict _ Dictionary new.
	inlineList _ Array new.
	constants _ Dictionary new: 100.
	variables _ OrderedCollection new: 100.
	variableDeclarations _ Dictionary new: 100.
	methods _ Dictionary new: 500.
	self initializeCTranslationDictionary.
	headerFiles _ OrderedCollection new.
	globalVariableUsage _ Dictionary new.
	useSymbolicConstants _ true.
	generateDeadCode _ true.
]

{ #category : #'C translation' }
CCodeGenerator >> initializeCTranslationDictionary [ 
	"Initialize the dictionary mapping message names to actions for C code generation."

	| pairs |
	translationDict _ Dictionary new: 200.
	pairs _ #(
	#&				#generateAnd:on:indent:
	#|				#generateOr:on:indent:
	#and:			#generateSequentialAnd:on:indent:
	#or:			#generateSequentialOr:on:indent:
	#not			#generateNot:on:indent:

	#+				#generatePlus:on:indent:
	#-				#generateMinus:on:indent:
	#*				#generateTimes:on:indent:
	#/				#generateDivide:on:indent:
	#//				#generateDivide:on:indent:
	#\\				#generateModulo:on:indent:
	#<<				#generateShiftLeft:on:indent:
	#>>				#generateShiftRight:on:indent:
	#min:			#generateMin:on:indent:
	#max:			#generateMax:on:indent:

	#bitAnd:		#generateBitAnd:on:indent:
	#bitOr:			#generateBitOr:on:indent:
	#bitXor:			#generateBitXor:on:indent:
	#bitShift:		#generateBitShift:on:indent:
	#bitInvert32	#generateBitInvert32:on:indent:

	#<				#generateLessThan:on:indent:
	#<=				#generateLessThanOrEqual:on:indent:
	#=				#generateEqual:on:indent:
	#>				#generateGreaterThan:on:indent:
	#>=				#generateGreaterThanOrEqual:on:indent:
	#~=				#generateNotEqual:on:indent:
	#==				#generateEqual:on:indent:
	#~~				#generateNotEqual:on:indent:
	#isNil			#generateIsNil:on:indent:
	#notNil			#generateNotNil:on:indent:

	#whileTrue: 	#generateWhileTrue:on:indent:
	#whileFalse:	#generateWhileFalse:on:indent:
	#whileTrue 		#generateDoWhileTrue:on:indent:
	#whileFalse		#generateDoWhileFalse:on:indent:
	#to:do:			#generateToDo:on:indent:
	#to:by:do:		#generateToByDo:on:indent:

	#ifTrue:		#generateIfTrue:on:indent:
	#ifFalse:		#generateIfFalse:on:indent:
	#ifTrue:ifFalse:	#generateIfTrueIfFalse:on:indent:
	#ifFalse:ifTrue:	#generateIfFalseIfTrue:on:indent:

	#at:				#generateAt:on:indent:
	#at:put:			#generateAtPut:on:indent:
	#basicAt:		#generateAt:on:indent:
	#basicAt:put:	#generateAtPut:on:indent:

	#integerValueOf:	#generateIntegerValueOf:on:indent:
	#integerObjectOf:	#generateIntegerObjectOf:on:indent:
	#isIntegerObject: 	#generateIsIntegerObject:on:indent:
	#cCode:				#generateInlineCCode:on:indent:
	#cCode:inSmalltalk:	#generateInlineCCode:on:indent:
	#cCoerce:to:			#generateCCoercion:on:indent:
	#preIncrement		#generatePreIncrement:on:indent:
	#preDecrement		#generatePreDecrement:on:indent:
	#inline:				#generateInlineDirective:on:indent:
	#sharedCodeNamed:inCase:	#generateSharedCodeDirective:on:indent:
	#asFloat				#generateAsFloat:on:indent:
	#asInteger			#generateAsInteger:on:indent:
	#anyMask:			#generateBitAnd:on:indent:
	#raisedTo:			#generateRaisedTo:on:indent:
	#touch:				#generateTouch:on:indent:

	#perform:						#generatePerform:on:indent:
	#perform:with:					#generatePerform:on:indent:
	#perform:with:with:				#generatePerform:on:indent:
	#perform:with:with:with:		#generatePerform:on:indent:
	#perform:with:with:with:with:	#generatePerform:on:indent:

	).

	1 to: pairs size by: 2 do: [:i |
		translationDict at: (pairs at: i) put: (pairs at: i + 1)].

]

{ #category : #inlining }
CCodeGenerator >> inlineDispatchesInMethodNamed: selector localizingVars: varsList [
	"Inline dispatches (case statements) in the method with the given name."

	| m varString |
	m _ self methodNamed: selector.
	m = nil ifFalse: [
		m inlineCaseStatementBranchesIn: self localizingVars: varsList.
		m parseTree nodesDo: [ :n |
			n isCaseStmt ifTrue: [
				n customizeShortCasesForDispatchVar: 'currentBytecode' in: self method: m.
			].
		].
	].
	variables _ variables asOrderedCollection.
	varsList do: [ :v |
		varString _ v asString.
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

{ #category : #utilities }
CCodeGenerator >> localizeGlobalVariables [
	| candidates procedure |

	"find all globals used in only one method"
	candidates _ globalVariableUsage select: [:e | e size = 1].
	variables removeAllFoundIn: candidates keys.

	"move any suitable global to be local to the single method using it"
	candidates keysAndValuesDo: [:key :targets | 
		targets do: [:name |
			procedure _ methods at: name.
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
	methodsWithCCode _ Set new: methods size.
	sizesOf _ Dictionary new: methods size * 2.  "selector -> nodeCount"
	callsOf _ Dictionary new: methods size * 2.  "selector -> senderCount"

	"For each method, scan its parse tree once to:
		1. determine if the method contains C code or declarations
		2. determine how many nodes it has
		3. increment the sender counts of the methods it calls
		4. determine if it includes any C declarations or code"

	methods do: [ :m0 |  m _ m0.
		(translationDict includesKey: m selector) ifTrue: [
			hasCCode _ true.
		] ifFalse: [
			hasCCode _ m declarations size > 0.
			nodeCount _ 0.
			m parseTree nodesDo: [ :node |
				node isSend ifTrue: [
					selr _ node selector.
					selr = #cCode: ifTrue: [ hasCCode _ true ].
					senderCount _ callsOf at: selr ifAbsent: [ 0 ].
					callsOf at: selr put: senderCount + 1.
				].
				nodeCount _ nodeCount + 1.
			].
		].
		hasCCode ifTrue: [ methodsWithCCode add: m selector ].
		sizesOf at: m selector put: nodeCount.
	].

	s _ WriteStream on: (String new: 5000).
	methods keys asSortedCollection do: [ :sel |
		m _ methods at: sel.
		registers _ m locals size + m args size.
		calls _ callsOf at: sel ifAbsent: [0].
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
	out _ OrderedCollection new.
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
	out _ Set new.
	todo _ aSelectorList copy asOrderedCollection.
	[todo isEmpty] whileFalse: [
		sel _ todo removeFirst.
		out add: sel.
		methods do: [ :m |
			(m allCalls includes: sel) ifTrue: [
				mSelector _ m selector.
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
	rcvr _ sendNode receiver.
	rcvr isConstant ifTrue: [
		val _ rcvr value.
		((val == true) or: [val == false]) ifTrue: [^ val]].
	^ nil

]

{ #category : #utilities }
CCodeGenerator >> prepareMethods [
	"Prepare methods for browsing."

	| globals |
	globals _ Set new: 200.
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

{ #category : #private }
CCodeGenerator >> printArray: array on: aStream [
	| first |
	first _ true.
	1 to: array size do:
		[:i |
		first 
			ifTrue: [first _ false]
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
	undefinedCalls _ Dictionary new.
	knownSelectors _ translationDict keys asSet.
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
	undefinedRefs _ Dictionary new.
	globalVars _ Set new: 100.
	globalVars addAll: variables.
	methods do: [ :m |
		knownVars _ globalVars copy.
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
	newMethods _ Dictionary new: doNotRemoveMethodList size.
	doNotRemoveMethodList do:[:sel|
		methods at: sel ifPresent:[:meth| newMethods at: sel put: meth]].
	methods _ newMethods
]

{ #category : #inlining }
CCodeGenerator >> removeAssertions [
	"Remove all assertions in method bodies.  This is for the benefit of inlining, which
	fails to recognise and disregard empty method bodies when checking the inlinability
	of sends."

	| newMethods |
	newMethods _ Dictionary new.
	'Removing assertions...'
		displayProgressAt: Sensor cursorPoint
		from: 0 to: methods size
		during: [ :bar |
			methods doWithIndex: [ :m :i |
				bar value: i.
				m isAssertion ifFalse: [
					newMethods at: m selector put: m.
					m removeAssertions]]].
	methods _ newMethods.
]

{ #category : #inlining }
CCodeGenerator >> removeMethodsReferingToGlobals: varList except: methodName [
	"Remove any methods (presumably inlined) that still contain references to the given obsolete global variables."

	| varListAsStrings removeIt mVars |
	varListAsStrings _ varList collect: [ :sym | sym asString ].
	methods keys copy do: [ :sel |
		removeIt _ false.
		mVars _ (self methodNamed: sel) freeVariableReferences asSet.
		varListAsStrings do: [ :v |
			(mVars includes: v) ifTrue: [ removeIt _ true ].
		].
		(removeIt and: [sel ~= methodName]) ifTrue: [
			methods removeKey: sel ifAbsent: [].
		].
	].
]

{ #category : #utilities }
CCodeGenerator >> reportRecursiveMethods [
	"Report in transcript all methods that can call themselves directly or indirectly or via a chain of N intermediate methods."

	| visited calls newCalls sel called |
	methods do: [: m |
		visited _ translationDict keys asSet.
		calls _ m allCalls asOrderedCollection.
		5 timesRepeat: [
			newCalls _ Set new: 50.
			[calls isEmpty] whileFalse: [
				sel _ calls removeFirst.
				sel = m selector ifTrue: [
					Transcript show: m selector, ' is recursive'; cr.
				] ifFalse: [
					(visited includes: sel) ifFalse: [
						called _ self methodNamed: sel.
						called = nil ifFalse: [ newCalls addAll: called allCalls ].
					].
					visited add: sel.
				].
			].
			calls _ newCalls asOrderedCollection.
		].
	].
]

{ #category : #inlining }
CCodeGenerator >> retainMethods: aListOfMethodsToKeep [
"add aListOfMethodsToKeep to doNotRemoveMethodList so that they will not be pruned"
	doNotRemoveMethodList ifNil:[doNotRemoveMethodList _ Set new:100].
	doNotRemoveMethodList addAll: aListOfMethodsToKeep.
	^aListOfMethodsToKeep
]

{ #category : #utilities }
CCodeGenerator >> returnPrefixFromVariable: aName [
	^aName
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
	stream _ CrLfFileStream forceNewFileNamed: fileName.
	stream ifNil: [Error signal: 'Could not open C code file: ', fileName].
	self emitCCodeOn: stream doInlining: inlineFlag doAssertions: assertionFlag.
	stream close
]

{ #category : #utilities }
CCodeGenerator >> translationMethodClass [
	"return the class used to produce C translation methods from MethodNodes"
	^TMethod
]

{ #category : #utilities }
CCodeGenerator >> unreachableMethods [
	"Return a collection of methods that are never invoked."

	| sent out |
	sent _ Set new.
	methods do: [ :m |
		m export ifTrue:[sent add: m selector].
		sent addAll: m allCalls.
	].

	out _ OrderedCollection new.
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

	variableDeclarations at: varName asString put: declarationString.
]

{ #category : #public }
CCodeGenerator >> var: varName type: type [
	self var: varName declareC: type , ' ' , varName
]

{ #category : #public }
CCodeGenerator >> var: varName type: type array: array [
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
