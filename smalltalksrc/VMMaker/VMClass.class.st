"
I am an abstract superclass for all classes in the VM that want to maintain a source timeStamp.
"
Class {
	#name : #VMClass,
	#superclass : #Object,
	#pools : [
		'VMBasicConstants'
	],
	#classInstVars : [
		'timeStamp'
	],
	#category : #'VMMaker-Support'
}

{ #category : #translation }
VMClass class >> ancilliaryClasses [
	"Answer any extra classes to be included in the translation."
	^#()
]

{ #category : #translation }
VMClass class >> ancilliaryStructClasses [
	^#()
]

{ #category : #translation }
VMClass class >> apiExportHeaderName [
	"VM classesd that want to generate an api export header override this."
	^nil
]

{ #category : #translation }
VMClass class >> coreInterpreterClass [
	"While the interpreterClass/vmClass for translation may be
	 a subclass that holds a few primitives we want the actual
	 interpreter name at the head of the generated file."
	^((name endsWith: 'Primitives')
	   and: [name beginsWith: superclass name])
		ifTrue: [superclass]
		ifFalse: [self]
]

{ #category : #translation }
VMClass class >> declareC: arrayOfVariableNames as: aCType in: aCCodeGenerator [
	"Declare the variables in arrayOfVariableNames with the given type."

	arrayOfVariableNames
		do: [:varName | aCCodeGenerator var: varName type: aCType]
]

{ #category : #translation }
VMClass class >> declareCVarsIn: aCCodeGenerator [ 
	"Declare any additional variables and/or add type declarations for existing variables."
]

{ #category : #debugger }
VMClass class >> defaultIntegerBaseInDebugger [
	^16
]

{ #category : #translation }
VMClass class >> emitExportPragma [	
	"#pragma export -- seems only to have been for CodeWarrior on Mac."
	^false
]

{ #category : #translation }
VMClass class >> exportAPISelectors [
	^self exportAPISelectorsFor: self
]

{ #category : #translation }
VMClass class >> exportAPISelectorsFor: aClass [
	^(aClass selectors select:
		[:s| | m |
		((m := aClass compiledMethodAt: s) pragmaAt: #api) notNil or: [(m pragmaAt: #api:) notNil]]) asSet
]

{ #category : #translation }
VMClass class >> getVMMaker [
	^Notification new tag: #getVMMaker; signal
]

{ #category : #translation }
VMClass class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#sqInt
]

{ #category : #translation }
VMClass class >> isAccessor: aSelector [
	"Answer if aSelector is simply an accessor method for one of our fields.
	 Answer false by default.  VMStructType classes redefine this appropriately."
	^false
]

{ #category : #translation }
VMClass class >> isCogitClass [
	"The various Cogit classes override this."
	^false
]

{ #category : #translation }
VMClass class >> isInterpreterClass [
	"The various Interpreter classes override this."
	^false
]

{ #category : #translation }
VMClass class >> noteCompilationOf: aSelector meta: isMeta [
	"note the recompiliation by resetting the timeStamp "
	timeStamp := Time totalSeconds.
	^super noteCompilationOf: aSelector meta: isMeta
]

{ #category : #'accessing class hierarchy' }
VMClass class >> objectMemoryClass [
	"Default for all-in-one VMs where the interpreter inherits from the object memory."
	^nil
]

{ #category : #utilities }
VMClass class >> openCogMultiWindowBrowser [
	"Answer a new multi-window browser on the ObjectMemory classes, the Cog Interpreter classes, and the main JIT classes"
	| b |
	b := Browser open.
	#(	ObjectMemory NewObjectMemory NewCoObjectMemory
		InterpreterPrimitives StackInterpreter StackInterpreterPrimitives CoInterpreter CoInterpreterPrimitives CoInterpreterMT
		Cogit SimpleStackBasedCogit StackToRegisterMappingCogit
		VMStructClass VMMaker CCodeGenerator TMethod)
		do: [:className|
			(Smalltalk classNamed: className) ifNotNil:
				[:class| b selectCategoryForClass: class; selectClass: class]]
		separatedBy:
			[b multiWindowState addNewWindow].
	b multiWindowState selectWindowIndex: 1
]

{ #category : #utilities }
VMClass class >> openObjectMemoriesInterpretersBrowser [
	"Answer a new multi-window browser on the ObjectMemory classes and the Cog Interpreter classes"
	| b |
	b := Browser open.
	#(	ObjectMemory NewObjectMemory NewCoObjectMemory
		InterpreterPrimitives StackInterpreter StackInterpreterPrimitives
		CoInterpreter CoInterpreterPrimitives CoInterpreterMT)
		do: [:className|
			(Smalltalk classNamed: className) ifNotNil:
				[:class| b selectCategoryForClass: class; selectClass: class]]
		separatedBy:
			[b multiWindowState addNewWindow].
	b multiWindowState selectWindowIndex: 1
]

{ #category : #translation }
VMClass class >> prepareToBeAddedToCodeGenerator: aCCodeGenerator [ 
	"Hook for translation.  e.g. allows a subclass to override its
	 superclass's methods by deleting them before it adds its own."
]

{ #category : #translation }
VMClass class >> requiredMethodNames [
	"Answer a list of method names that should be retained for export or other
	 support reasons.  These are typically entry-points that unless explicitly noted
	 will be deleted by the code generator since it will assume these are not used."
	^#()
]

{ #category : #translation }
VMClass class >> shouldGenerateTypedefFor: aStructClass [
	"Hack to work-around multiple definitions.  Sometimes a type has been defined in an include."
	^true
]

{ #category : #translation }
VMClass class >> specialValueForConstant: constantName default: defaultValue [
	^nil
]

{ #category : #translation }
VMClass class >> timeStamp [
	^timeStamp ifNil:[0]
]

{ #category : #translation }
VMClass class >> touch [
	"Reset the timeStamp"
	"Smalltalk allClasses select:
		[:c| (c category includesSubString: 'VMMaker-JIT') ifTrue: [c touch]]"
	"InterpreterPlugin withAllSubclassesDo:[:pl| pl touch]"
	timeStamp := Time totalSeconds
]

{ #category : #translation }
VMClass class >> translationClass [
	"Return te class to use as the interpreterCLass when translating.  For the all-in-one
	 VMs that inherit from ObjectMemory this is the receiver.  But for the separate VMs
	 where most primitives are in a subclass it will be the subclass with the primitives."
	^self
]

{ #category : #translation }
VMClass class >> typeForSelf [
	"Answer the type to give self if appropriate, or nil if not."
	^nil
]

{ #category : #translation }
VMClass class >> writeVMHeaderTo: tempStream bytesPerWord: bytesPerWord [
	"No op hook allowing ancialliary classes to write whatever they deem fit to interp.h"
]

{ #category : #'translation support' }
VMClass >> addressOf: anObject [
	<doNotGenerate>
	"Translates into &anObject in C."
	^anObject
]

{ #category : #'debug support' }
VMClass >> asserta: aBooleanExpression [
	<doNotGenerate>
	| result |
	(result := aBooleanExpression value) ifFalse:
		[AssertionFailure signal: 'Assertion failed'].
	^result
]

{ #category : #accessing }
VMClass >> bytesPerOop [
	^BytesPerOop
]

{ #category : #'translation support' }
VMClass >> cppIf: conditionBlock ifTrue: trueExpressionOrBlock [
	"When translated, produces #if (condition) #else #endif CPP directives.
	 Example usage:

		self cppIf: [BytesPerWord = 8]
			ifTrue: [self doSomethingFor64Bit]
			ifFalse: [self doSomethingFor32Bit]"
	self cppIf: conditionBlock ifTrue: trueExpressionOrBlock ifFalse: []
]

{ #category : #'translation support' }
VMClass >> cppIf: conditionBlock ifTrue: trueExpressionOrBlock ifFalse: falseExpressionOrBlockOrNil [
	"When translated, produces #if (condition) #else #endif CPP directives.
	 Example usage:

		self cppIf: [BytesPerWord = 8]
			ifTrue: [self doSomethingFor64Bit]
			ifFalse: [self doSomethingFor32Bit]"
	(conditionBlock value
		ifNil: [false]
		ifNotNil: [:value|
			value isInteger
				ifTrue: [value ~= 0]
				ifFalse: [value]])
		ifTrue: trueExpressionOrBlock
		ifFalse: falseExpressionOrBlockOrNil
]

{ #category : #'simulation support' }
VMClass >> doOrDefer: aBlock [
	<doNotGenerate>
	"Either evaluate aBlock immediately if in the uiProcess or defer aBlock as a UI message"
	Processor activeProcess == Project uiProcess
		ifTrue: [aBlock value]
		ifFalse: [WorldState addDeferredUIMessage: aBlock]
]

{ #category : #'memory access' }
VMClass >> fetchFloatAtPointer: pointer into: aFloat [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and aFloat is a 64-bit double precision float."
	<doNotGenerate>

	^self fetchFloatAt: pointer into: aFloat
]

{ #category : #'memory access' }
VMClass >> fetchSingleFloatAtPointer: pointer into: aFloat [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and aFloat is a 32-bit single precision float."
	<doNotGenerate>

	^self fetchSingleFloatAt: pointer into: aFloat
]

{ #category : #'plugin support' }
VMClass >> isInterpreterProxy [
	<doNotGenerate>
	"Return false since I am a real Interpreter simulation"
	^false
]

{ #category : #'memory access' }
VMClass >> longAtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is the width of a machine word."
	<doNotGenerate>

	^self longAt: pointer
]

{ #category : #'memory access' }
VMClass >> longAtPointer: pointer put: longValue [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and longValue is the width of a machine word."
	<doNotGenerate>

	^self longAt: pointer put: longValue
]

{ #category : #'oop comparison' }
VMClass >> oop: anOop isGreaterThan: otherOop [
	"Compare two oop values, treating them as object memory locations.
	Use #cCoerce:to: to ensure comparison of unsigned magnitudes. This
	method will be inlined during C translation."
	<inline: true>
	^(self cCoerce: anOop to: #usqInt)
		> (self cCoerce: otherOop to: #usqInt)
]

{ #category : #'oop comparison' }
VMClass >> oop: anOop isGreaterThan: baseOop andLessThan: limitOop [
	"Compare two oop values, treating them as object memory locations.
	Use #cCoerce:to: to ensure comparison of unsigned magnitudes. This
	method will be inlined during C translation."
	<inline: true>
	^(self cCoerce: anOop to: #usqInt) > (self cCoerce: baseOop to: #usqInt)
	  and: [(self cCoerce: anOop to: #usqInt) < (self cCoerce: limitOop to: #usqInt)]
]

{ #category : #'oop comparison' }
VMClass >> oop: anOop isGreaterThanOrEqualTo: otherOop [
	"Compare two oop values, treating them as object memory locations.
	Use #cCoerce:to: to ensure comparison of unsigned magnitudes. This
	method will be inlined during C translation."
	<inline: true>
	^(self cCoerce: anOop to: #usqInt)
		>= (self cCoerce: otherOop to: #usqInt)
]

{ #category : #'oop comparison' }
VMClass >> oop: anOop isLessThan: otherOop [
	"Compare two oop values, treating them as object memory locations.
	Use #cCoerce:to: to ensure comparison of unsigned magnitudes. This
	method will be inlined during C translation."
	<inline: true>
	^(self cCoerce: anOop to: #usqInt) < (self cCoerce: otherOop to: #usqInt)
]

{ #category : #'oop comparison' }
VMClass >> oop: anOop isLessThanOrEqualTo: otherOop [
	"Compare two oop values, treating them as object memory locations.
	Use #cCoerce:to: to ensure comparison of unsigned magnitudes. This
	method will be inlined during C translation."
	<inline: true>
	^(self cCoerce: anOop to: #usqInt)
		<= (self cCoerce: otherOop to: #usqInt)
]

{ #category : #'memory access' }
VMClass >> oopForPointer: pointerOrSurrogate [
	"This gets implemented by Macros in C, where its types will also be checked.
	 oop is the width of a machine word, and pointer is a raw address."
	<doNotGenerate>
	^pointerOrSurrogate asInteger
]

{ #category : #'translation support' }
VMClass >> pointerForOop: oop [
	"This gets implemented by Macros in C, where its types will also be checked.
	 oop is the width of a machine word, and pointer is a raw address."
	<doNotGenerate>

	^oop
]

{ #category : #arithmetic }
VMClass >> safe: signedInteger mod: positiveModulus [
	<inline>
	| remainder |
	^(remainder := signedInteger \\ positiveModulus) < 0
		ifTrue: [remainder + positiveModulus]
		ifFalse: [remainder]
]

{ #category : #'translation support' }
VMClass >> sizeof: objectSymbolOrClass [
	<doNotGenerate>
	| index |
	objectSymbolOrClass isInteger ifTrue:
		[self flag: #Dan.
		 ^BytesPerWord].
	objectSymbolOrClass isSymbol ifTrue:
		[(objectSymbolOrClass last == $*
		 or: [#long == objectSymbolOrClass
		 or: [#'unsigned long' == objectSymbolOrClass]]) ifTrue:
			[^BytesPerWord].
		index := #(	#sqLong #usqLong #double
					#int #'unsigned int' #float
					#short #'unsigned short'
					#char #'unsigned char' #'signed char')
						indexOf: objectSymbolOrClass
						ifAbsent: [self error: 'unrecognized C type name'].
		^#(8 8 8
			4 4 4
			2 2
			1 1 1) at: index].
	^(objectSymbolOrClass isBehavior
		ifTrue: [objectSymbolOrClass]
		ifFalse: [objectSymbolOrClass class]) alignedByteSizeForClient: self
]

{ #category : #'simulation support' }
VMClass >> sqLowLevelMFence [
	<doNotGenerate>
	"A no-op in the simulator"
]

{ #category : #'memory access' }
VMClass >> storeFloatAtPointer: pointer from: aFloat [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and aFloat is a 64-bit double precision float."
	<doNotGenerate>

	^self storeFloatAt: pointer from: aFloat
]

{ #category : #'memory access' }
VMClass >> storeSingleFloatAtPointer: pointer from: aFloat [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and aFloat is a 32-bit single precision float."
	<doNotGenerate>

	^self storeSingleFloatAt: pointer from: aFloat
]
