"
I am an abstract superclass for all classes in the VM that want to maintain a source timeStamp.  I am also the holder of the InitializationOptions class variable which holds options such as which JIT or which memory manager to use when creating or generating a VM.
"
Class {
	#name : #VMClass,
	#superclass : #SlangClass,
	#classVars : [
		'DefaultBase',
		'InitializationOptions'
	],
	#pools : [
		'VMBasicConstants',
		'VMObjectIndices'
	],
	#classInstVars : [
		'timeStamp'
	],
	#category : #'VMMaker-Support'
}

{ #category : #translation }
VMClass class >> apiExportHeaderName [
	"VM classesd that want to generate an api export header override this."
	^nil
]

{ #category : #'adding/removing methods' }
VMClass class >> basicRemoveSelector: aSelector [
	"Override to update the timeStamp"
	^(super basicRemoveSelector: aSelector) ifNotNil:
		[:oldMethod| self touch. oldMethod]
]

{ #category : #accessing }
VMClass class >> bytesPerOop [
	
	^ BytesPerOop
]

{ #category : #accessing }
VMClass class >> bytesPerWord [
	
	^ BytesPerWord 
]

{ #category : #'accessing class hierarchy' }
VMClass class >> cogitClass [
	"Answer the cogitClass in effect.  Ensure that StackInterpreter has a nil cogitClass."
	(self isInterpreterClass and: [self hasCogit not]) ifTrue:
		[^nil].
	^Smalltalk classNamed: (InitializationOptions
								at: #Cogit
								ifAbsent: [#StackToRegisterMappingCogit])
]

{ #category : #'accessing class hierarchy' }
VMClass class >> constantClass [

	^ VMBasicConstants
]

{ #category : #'accessing class hierarchy' }
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
VMClass class >> declareCAsOop: arrayOfVariableNames in: aCCodeGenerator [
	"Declare the variables in arrayOfVariableNames with type representing position in object memory."

	arrayOfVariableNames do:
		[:varName| aCCodeGenerator var: varName type: #usqInt]
]

{ #category : #translation }
VMClass class >> declareCAsUSqLong: arrayOfVariableNames in: aCCodeGenerator [
	"Declare the variables in arrayOfVariableNames with type representing position in object memory."

	arrayOfVariableNames do:
		[:varName| aCCodeGenerator var: varName type: #usqLong]
]

{ #category : #translation }
VMClass class >> declareCVarsIn: aCCodeGenerator [ 
	"Declare any additional variables and/or add type declarations for existing variables."
	aCCodeGenerator
		var: #expensiveAsserts
		declareC: 'char expensiveAsserts = 0'
]

{ #category : #translation }
VMClass class >> declareInterpreterVersionIn: aCCodeGenerator defaultName: defaultName [	
	aCCodeGenerator
		var: #interpreterVersion
		declareC: 'const char *interpreterVersion = "Croquet Closure ', defaultName, ' VM [',
					(aCCodeGenerator shortMonticelloDescriptionForClass: self),']"'.
]

{ #category : #'accessing class hierarchy' }
VMClass class >> defaultObjectMemoryClass [
	"Default for all-in-one VMs where the interpreter inherits from the object memory."
	^nil
]

{ #category : #'accessing class hierarchy' }
VMClass class >> hasCogit [
	^false
]

{ #category : #translation }
VMClass class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#sqInt
]

{ #category : #initialization }
VMClass class >> initializationOptions [
	^InitializationOptions
]

{ #category : #initialization }
VMClass class >> initialize [
	InitializationOptions ifNil: [InitializationOptions := Dictionary new].
	ExpensiveAsserts := false
]

{ #category : #initialization }
VMClass class >> initializeForPlugins: optionsDictionaryOrArray [
	"Do a default initialization, suitable for generating plugin sources."
	StackInterpreterSimulator
		initializeWithOptions: optionsDictionaryOrArray

]

{ #category : #initialization }
VMClass class >> initializeMiscConstants [
	"Falsify the `what type of VM is this?' flags that are defined in the various interp.h files.
	 Subclass implementations need to include a super initializeMiscConstants"

	| omc |
	VMBIGENDIAN class. "Mention this for the benefit of CCodeGenerator>>emitCConstantsOn:"
	SPURVM := STACKVM := COGVM := COGMTVM := false.

	"Assignment needs to be in here to recognized this constant as a compile-time defined macro"
	FEATURE_FFI := FEATURE_THREADED_FFI := false.

	InitializationOptions ifNil: [InitializationOptions := Dictionary new].
	omc := InitializationOptions at: #ObjectMemory ifAbsent: [self error: 'Please specify an object memory'].

	InitializationOptions
		at: #SpurObjectMemory		"the new contender"
			ifAbsentPut: (omc
					ifNil: [false]
					ifNotNil: [(Smalltalk at: omc) includesBehavior: SpurMemoryManager]).

	"Use ifAbsentPut: so that they will get copied back to the
	 VMMaker's options and dead code will likely be eliminated."
	PharoVM := InitializationOptions at: #PharoVM ifAbsentPut: [false].
	SistaVM := InitializationOptions at: #SistaVM ifAbsentPut: [false].
	TempVectReadBarrier := InitializationOptions at: #TempVectReadBarrier ifAbsentPut: [false].
	LowcodeVM := InitializationOptions at: #LowcodeVM ifAbsentPut: [false].
	MULTIPLEBYTECODESETS := InitializationOptions at: #MULTIPLEBYTECODESETS ifAbsentPut: [false].
	"Simulation only; on by default..."
	CloneOnGC := InitializationOptions at: #CloneOnGC ifAbsentPut: [true].
	CloneOnScavenge := InitializationOptions at: #CloneOnScavenge ifAbsentPut: [true].

	"These must be set only if specified, not defaulted, because they are set on the command line or in include files."
	InitializationOptions
		at: #VMBIGENDIAN	ifPresent: [:value| VMBIGENDIAN := value];
		at: #ObjectMemory	ifPresent: [:value| SPURVM := value beginsWith: 'Spur'];
		at: #STACKVM		ifPresent: [:value| STACKVM := value];
		at: #COGVM		ifPresent: [:value| COGVM := InitializationOptions at: #COGVM];
		at: #COGMTVM		ifPresent: [:value| COGMTVM := InitializationOptions at: #COGMTVM].

	"consistency checks"
	SPURVM
		ifTrue:
			[(TempVectReadBarrier not
			  and: [{SpurMemoryManager compactorClass}, (SpurMemoryManager compactorClass ancilliaryClasses) anySatisfy:
						[:c| c == SpurSelectiveCompactor]]) ifTrue:
				[self error: 'Selective compactor requires read barrier']]
		ifFalse:
			[TempVectReadBarrier ifTrue: [self error: 'read barrier works with spur VM only...'].
			 SistaVM ifTrue: [self error: 'Sista VM works with spur VM only...']].

	"And not these; they're compile-time"
	IMMUTABILITY := InitializationOptions at: #IMMUTABILITY ifAbsent: [SPURVM] "Default as enabled for Spur VMs"
]

{ #category : #initialization }
VMClass class >> initializePrimitiveErrorCodes [
	"Define the VM's primitive error codes.  N.B. these are
	 replicated in platforms/Cross/vm/sqVirtualMachine.h."
	"VMClass initializePrimitiveErrorCodes"
	| pet |
	PrimErrTableIndex := 51. "Zero-relative"
	"See SmalltalkImage>>recreateSpecialObjectsArray for the table definition.
	 If the table exists and is large enough the corresponding entry is returned as
	 the primitive error, otherwise the error is answered numerically."
	pet := Smalltalk specialObjectsArray at: PrimErrTableIndex + 1 ifAbsent: [#()].
	pet isArray ifFalse: [pet := #()].
	PrimNoErr := 0. "for helper methods that need to answer success or an error code."
	PrimErrGenericFailure		:= pet indexOf: nil ifAbsent: 1.
	PrimErrBadReceiver			:= pet indexOf: #'bad receiver' ifAbsent: 2.
	PrimErrBadArgument		:= pet indexOf: #'bad argument' ifAbsent: 3.
	PrimErrBadIndex			:= pet indexOf: #'bad index' ifAbsent: 4.
	PrimErrBadNumArgs		:= pet indexOf: #'bad number of arguments' ifAbsent: 5.
	PrimErrInappropriate		:= pet indexOf: #'inappropriate operation' ifAbsent: 6.
	PrimErrUnsupported		:= pet indexOf: #'unsupported operation' ifAbsent: 7.
	PrimErrNoModification		:= pet indexOf: #'no modification' ifAbsent: 8.
	PrimErrNoMemory			:= pet indexOf: #'insufficient object memory' ifAbsent: 9.
	PrimErrNoCMemory			:= pet indexOf: #'insufficient C memory' ifAbsent: 10.
	PrimErrNotFound			:= pet indexOf: #'not found' ifAbsent: 11.
	PrimErrBadMethod			:= pet indexOf: #'bad method' ifAbsent: 12.
	PrimErrNamedInternal		:= pet indexOf: #'internal error in named primitive machinery' ifAbsent: 13.
	PrimErrObjectMayMove		:= pet indexOf: #'object may move' ifAbsent: 14.
	PrimErrLimitExceeded		:= pet indexOf: #'resource limit exceeded' ifAbsent: 15.
	PrimErrObjectIsPinned		:= pet indexOf: #'object is pinned' ifAbsent: 16.
	PrimErrWritePastObject		:= pet indexOf: #'primitive write beyond end of object' ifAbsent: 17.
	PrimErrObjectMoved		:= pet indexOf: #'object moved' ifAbsent: 18.
	PrimErrObjectNotPinned	:= pet indexOf: #'object not pinned' ifAbsent: 19.
	PrimErrCallbackError		:= pet indexOf: #'error in callback' ifAbsent: 20.
	PrimErrOSError				:= pet indexOf: #'operating system error' ifAbsent: 21.
	PrimErrFFIException		:= pet indexOf: #'ffi call exception' ifAbsent: 22.
	PrimErrNeedCompaction	:= pet indexOf: #'heap compaction needed' ifAbsent: 23. "N.B. This is currently an internal error in Spur image segment saving."
	PrimErrOperationFailed		:= pet indexOf: #'operation failed' ifAbsent: 24
]

{ #category : #initialization }
VMClass class >> initializeWithOptions: optionsDictionaryOrArray [
	"Initialize the receiver, typically initializing class variables. Initialize any class variables
	 whose names occur in optionsDictionary with the corresponding values there-in."
	InitializationOptions := optionsDictionaryOrArray isArray
								ifTrue: [Dictionary newFromPairs: optionsDictionaryOrArray]
								ifFalse: [optionsDictionaryOrArray].

	ExpensiveAsserts := InitializationOptions at: #ExpensiveAsserts ifAbsent: [false]
]

{ #category : #'accessing class hierarchy' }
VMClass class >> interpreterClass [
	^self isInterpreterClass ifTrue: [self]
]

{ #category : #accessing }
VMClass class >> interpreterVersion [ 
	^ self subclassResponsibility
]

{ #category : #translation }
VMClass class >> isAcceptableAncilliaryClass: aClass [
	^true
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
VMClass class >> isNonArgumentImplicitReceiverVariableName: aString [
	^false
]

{ #category : #translation }
VMClass class >> isPluginClass [
	"InterpreterPlugin class override this."
	^false
]

{ #category : #translation }
VMClass class >> isSpurMemoryManagerClass [

	^ false
]

{ #category : #accessing }
VMClass class >> memoryManagerVersion [ 
	^ self subclassResponsibility
]

{ #category : #translation }
VMClass class >> monticelloDescription [
	"Answer the Monticello version of the packlage containing the receiver.
	 This is a hook to allow subclasses to expand upon the default monticello description."
	^CCodeGenerator monticelloDescriptionFor: self
]

{ #category : #translation }
VMClass class >> mustBeGlobal: var [
	"Answer if a variable must be global and exported.  Used for inst vars that are accessed from VM support code."

	^var = #expensiveAsserts
]

{ #category : #translation }
VMClass class >> noteCompilationOf: aSelector meta: isMeta [
	"note the recompiliation by resetting the timeStamp "
	timeStamp := Time totalSeconds.
	^super noteCompilationOf: aSelector meta: isMeta
]

{ #category : #'accessing class hierarchy' }
VMClass class >> objectMemoryClass [

	^Smalltalk at: (InitializationOptions
					at: #ObjectMemory
					ifAbsent: [ #Spur32BitMemoryManager ])
]

{ #category : #'accessing class hierarchy' }
VMClass class >> objectRepresentationClass [
	^self objectMemoryClass objectRepresentationClass
]

{ #category : #translation }
VMClass class >> shouldGenerateTypedefFor: aStructClass [
	"Hack to work-around multiple definitions.  Sometimes a type has been defined in an include."
	^aStructClass shouldBeGenerated
]

{ #category : #translation }
VMClass class >> shouldIncludeMethodForSelector: selector [
	"Answer whether a primitive method should be translated.  Emit a warning to the transcript if the method doesn't exist."
	^(self whichClassIncludesSelector: selector)
		ifNotNil:
			[:c|
			 (c >> selector pragmaAt: #option:)
				ifNotNil:
					[:pragma|
					(self constantClass defineAtCompileTime: pragma arguments first)
					 or: [InitializationOptions
							at: pragma arguments first
							ifAbsent: [(self bindingOf: pragma arguments first)
										ifNil: [false]
										ifNotNil: [:binding| binding value ~~ #undefined]]]]
				ifNil: [true]]
		ifNil:
			[Transcript nextPutAll: 'Cannot find implementation of '; nextPutAll: selector; nextPutAll: ' in hierarchy of '; print: self; cr; flush.
			 false]
]

{ #category : #simulation }
VMClass class >> simulatorClass [
	"For running from Smalltalk - answer a class that can be used to simulate the receiver."

	^self
]

{ #category : #translation }
VMClass class >> specialValueForConstant: constantName default: defaultValue [
	^nil
]

{ #category : #translation }
VMClass class >> staticallyResolvePolymorphicSelector: aSelectorSymbol [
	^((self name select: [:ea| ea isUppercase]), '_', aSelectorSymbol) asSymbol
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
	"Return the class to use as the interpreterCLass when translating.  For the all-in-one
	 VMs that inherit from ObjectMemory this is the receiver.  But for the separate VMs
	 where most primitives are in a subclass it will be the subclass with the primitives."
	^self
]

{ #category : #translation }
VMClass class >> writeVMHeaderTo: aStream bytesPerWord: bytesPerWord generator: aCCodeGenerator [
	"Generate the contents of interp.h on aStream.  Specific Interpreter subclasses
	 override to add more stuff."
	aCCodeGenerator
		putDefineOf: 'VM_PROXY_MAJOR' as: self vmProxyMajorVersion on: aStream;
		putDefineOf: 'VM_PROXY_MINOR' as: self vmProxyMinorVersion on: aStream.
	aStream cr.
	aCCodeGenerator
		putDefineOf: 'SQ_VI_BYTES_PER_WORD' as: bytesPerWord on: aStream.
	aStream cr.

	"The most basic constants must be defined here, not in e.g. the plugin sources, to allow those
	 other sources to be shared between different builds (Spur vs SqueakV3, 32-bit vs 64-bit, etc)"
	self constantClass mostBasicConstantNames asSet sorted do:
		[:constName|
		(self constantClass classPool at: constName ifAbsent: []) ifNotNil:
			[:const| aCCodeGenerator putDefineOf: constName as: const on: aStream]].
	aStream cr.

	((self constantClass classPool associations select: [:a| a key beginsWith: 'PrimErr'])
		sorted: [:a1 :a2| a1 value <= a2 value])
		do: [:a| aCCodeGenerator putDefineOf: a key as: a value on: aStream].
	aStream cr.

	aCCodeGenerator
		putDefineOf: 'MinSmallInteger' as: self objectMemoryClass minSmallInteger on: aStream;
		putDefineOf: 'MaxSmallInteger' as: self objectMemoryClass maxSmallInteger on: aStream;
		putDefineOf: 'NumSmallIntegerTagBits' as: self objectMemoryClass numSmallIntegerTagBits on: aStream.
	aStream cr
]

{ #category : #'translation support' }
VMClass >> addressOf: anObject [
	<doNotGenerate>
	"Translates into &anObject in C."
	^anObject
]

{ #category : #'translation support' }
VMClass >> addressOf: anObject put: aBlock [
	<doNotGenerate>
	"Simulate a C pointer.  Translates into &anObject in C. Provides something
	 that evaluates aBlock with the new value in response to at:put:"
	| thing |
	thing := anObject.
	^CPluggableAccessor new
		setObject: nil;
		atBlock: [:obj :idx| thing]
		atPutBlock: [:obj :idx :val| aBlock value: (thing := val)]
]

{ #category : #'C library simulation' }
VMClass >> alloca: size [
	"Simulation of alloca(3)"
	<doNotGenerate>
	^CArrayAccessor on: (ByteArray new: size)
]

{ #category : #'C library extensions' }
VMClass >> alloca: numElements type: elementType [
	<cmacro: '(numElements, elementType) alloca((numElements)*sizeof(elementType))'>
	^CArrayAccessor on: ((1 to: numElements) collect: [:ign| elementType new])
]

{ #category : #'translation support' }
VMClass >> asAddress: address put: aBlock [
	<doNotGenerate>
	"Simulate a C pointer.  Translates into address in C. Provides something
	 that evaluates aBlock with the new value in response to at:put:"
	^CPluggableAccessor new
		setObject: nil;
		atBlock: [:obj :idx| self error: 'cannot dereference pseudo-pointers']
		atPutBlock: [:obj :idx :val| aBlock value: val]
]

{ #category : #'C library extensions' }
VMClass >> asByteArray: aStringOrStringIndex [
	"aStringOrStringIndex is either a string or an address in the heap.
	 Create a ByteArray of the requested length form the bytes in the
	 heap starting at stringIndex."
	<doNotGenerate>
	| sz |
	aStringOrStringIndex isString ifTrue:
		[^aStringOrStringIndex asByteArray].
	sz := self strlen: aStringOrStringIndex.
	^self strncpy: (ByteArray new: sz) _: aStringOrStringIndex _: sz
]

{ #category : #'C library extensions' }
VMClass >> asByteArray: baIndex size: baSize [
	"baIndex is an address in the heap.  Create a ByteArray of the requested length
	form the bytes in the heap starting at baIndex."
	<doNotGenerate>
	^self strncpy: (ByteArray new: baSize) _: baIndex _: baSize
]

{ #category : #'C library extensions' }
VMClass >> asString: aStringOrStringIndex [
	"aStringOrStringIndex is either a string or an address in the heap.
	 Create a String of the requested length form the bytes in the
	 heap starting at stringIndex."
	<doNotGenerate>
	| sz |
	aStringOrStringIndex isString ifTrue:
		[^aStringOrStringIndex].
	sz := self strlen: aStringOrStringIndex.
	^self strncpy: (ByteString new: sz) _: aStringOrStringIndex _: sz
]

{ #category : #'C library extensions' }
VMClass >> asString: stringIndex size: stringSize [
	"stringIndex is an address in the heap.  Create a String of the requested length
	form the bytes in the heap starting at stringIndex."
	<doNotGenerate>
	^self strncpy: (ByteString new: stringSize) _: stringIndex _: stringSize
]

{ #category : #'debug support' }
VMClass >> assert: aBooleanExpression l: linenum [
	<doNotGenerate>
	^self assert: aBooleanExpression
]

{ #category : #'debug support' }
VMClass >> asserta: aBooleanExpression [
	<doNotGenerate>
	| result |
	(result := aBooleanExpression value) ifFalse:
		[AssertionFailure signal: 'Assertion failed'].
	^result
]

{ #category : #'debug support' }
VMClass >> asserta: aBooleanExpression l: linenum [
	<doNotGenerate>
	^self asserta: aBooleanExpression
]

{ #category : #'memory access' }
VMClass >> cCoerce: value to: cTypeString [
	"Type coercion. For translation a cast will be emmitted. When running in Smalltalk
	  answer a suitable wrapper for correct indexing."
	<doNotGenerate>
	^value
		ifNil: [value]
		ifNotNil: [value coerceTo: cTypeString sim: self]
]

{ #category : #'translation support' }
VMClass >> cPreprocessorDirective: codeString [
	"For translation only; noop when running in Smalltalk."
	<doNotGenerate>
]

{ #category : #'C library simulation' }
VMClass >> calloc: num _: size [ 

	<doNotGenerate>
	^ self malloc: num * size
]

{ #category : #'translation support' }
VMClass >> cppIf: conditionBlockOrValue ifTrue: trueExpressionOrBlock [
	"When translated, produces #if (condition) #else #endif CPP directives.
	 Example usage:

		self cppIf: IMMUTABILITY
			ifTrue: [(self internalIsImmutable: obj) ifTrue:
						[^self primitiveFailFor: PrimErrNoModification]]"
	<doNotGenerate>
	^self cppIf: conditionBlockOrValue ifTrue: trueExpressionOrBlock ifFalse: nil
]

{ #category : #'C pre-processor extensions' }
VMClass >> defined: aSymbol [
	"Simulated version of the C pre-processor defined()"
	<doNotGenerate>
	^(self class bindingOf: aSymbol)
		ifNil: [false]
		ifNotNil: [:binding| binding value ~~ #undefined]
]

{ #category : #'memory access' }
VMClass >> fetchSingleFloatAtPointer: pointer into: aFloat [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and aFloat is a 32-bit single precision float."
	<doNotGenerate>

	^self fetchSingleFloatAt: pointer into: aFloat
]

{ #category : #'memory access' }
VMClass >> floatAtPointer: pointer [
	<doNotGenerate>
	self halt.
]

{ #category : #'memory access' }
VMClass >> floatAtPointer: pointer put: value [
	<doNotGenerate>
	self halt.
]

{ #category : #'C library simulation' }
VMClass >> free: pointer [
	<doNotGenerate>
	"Do nothing"
]

{ #category : #'memory access' }
VMClass >> int16AtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 16 bit integer."
	<doNotGenerate>

	^self shortAt: pointer
]

{ #category : #'memory access' }
VMClass >> int16AtPointer: pointer put: value [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 16 bit integer."
	<doNotGenerate>

	^self shortAt: pointer put: value
]

{ #category : #'memory access' }
VMClass >> int32AtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 32 bit integer."
	<doNotGenerate>

	^self longAt: pointer
]

{ #category : #'memory access' }
VMClass >> int32AtPointer: pointer put: value [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 32 bit integer."
	<doNotGenerate>

	^self longAt: pointer put: value
]

{ #category : #'memory access' }
VMClass >> int64AtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is the width of a machine word."
	<doNotGenerate>

	^self halt
]

{ #category : #'memory access' }
VMClass >> int64AtPointer: pointer put: longValue [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and longValue is the width of a machine word."
	<doNotGenerate>

	^self halt.
]

{ #category : #'memory access' }
VMClass >> int8AtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 16 bit integer."
	<doNotGenerate>

	^self at: pointer
]

{ #category : #'memory access' }
VMClass >> int8AtPointer: pointer put: value [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 16 bit integer."
	<doNotGenerate>

	^self at: pointer put: value
]

{ #category : #testing }
VMClass >> isCurrentImageFacade [
	^false
]

{ #category : #'plugin support' }
VMClass >> isInterpreterProxy [
	<doNotGenerate>
	"Return false since I am a real Interpreter simulation"
	^false
]

{ #category : #'hack compatibility' }
VMClass >> localNameFor: aString [
	<doNotGenerate>
	^ aString asFileReference basename
]

{ #category : #'memory access' }
VMClass >> long64AtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is the width of a machine word."
	<doNotGenerate>

	^self halt
]

{ #category : #'memory access' }
VMClass >> long64AtPointer: pointer put: longValue [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and longValue is the width of a machine word."
	<doNotGenerate>

	^self halt.
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

{ #category : #'simulation support' }
VMClass >> majorVersion [
	"This is implemented in sqVirtualMachine.c, so this form is for simulation only."
	<doNotGenerate>
	^self class vmProxyMajorVersion
]

{ #category : #'C library simulation' }
VMClass >> malloc: size [
	<doNotGenerate>
	^CArrayAccessor on: (ByteArray new: size)
]

{ #category : #'C library simulation' }
VMClass >> memcpy: dest _: src _: bytes [
	<doNotGenerate>
	"implementation of memcpy(3). N.B. If ranges overlap, must use memmove."
	| getBlock setBlock source destination |

	source := src isVMSimulationAddress
		ifTrue: [src asInteger]
		ifFalse: [src].
	destination := dest isVMSimulationAddress
		ifTrue: [dest asInteger]
		ifFalse: [dest].
	(source isInteger and: [destination isInteger]) ifTrue:
		[ self deny: ((destination <= source and: [destination + bytes > source])
					or: [source <= destination and: [source + bytes > destination]])].

	"Determine the source and destination access blocks based on the parameter type"
	getBlock := source isCollection ifTrue: 
		[source isString ifTrue: 
			"basicAt: answers integers"
			[[ :idx | source basicAt: idx]]
		ifFalse: 
			[source class == ByteArray ifTrue: 
				[[ :idx | source at: idx]]]]
	ifFalse: 
		[source isInteger ifTrue: 
			[[ :idx | self byteAt: source + idx - 1]]
		ifFalse: 
			[source isCArray ifTrue:
				[[ :idx | source at: idx - 1]]]].
	getBlock ifNil: [self error: 'unhandled type of source string'].
	setBlock := destination isCollection ifTrue: 
		[destination isString ifTrue:
			"basicAt:put: stores integers"
			[[ :idx | destination basicAt: idx put: (getBlock value: idx)]] 
		ifFalse: 
			[destination class == ByteArray ifTrue: 
				[[ :idx | destination at: idx put: (getBlock value: idx)]]]]
	ifFalse: 
		[destination isInteger ifTrue:
			[[ :idx | self byteAt: destination + idx - 1 put: (getBlock value: idx)]]
		ifFalse:
			[destination isCArray ifTrue:
				[[ :idx | destination at: idx - 1 put: (getBlock value: idx)]]]].
	setBlock ifNil: [self error: 'unhandled type of destination string'].
	1 to: bytes do: setBlock.

	^destination
]

{ #category : #'C library simulation' }
VMClass >> memmove: destAddress _: sourceAddress _: bytes [
	<doNotGenerate>
	| dst src  |
	dst := destAddress asInteger.
	src := sourceAddress asInteger.
	"Emulate the c library memmove function"
	self assert: bytes \\ 4 = 0.
	destAddress > sourceAddress
		ifTrue:
			[bytes - 4 to: 0 by: -4 do:
				[:i| self longAt: dst + i put: (self longAt: src + i)]]
		ifFalse:
			[0 to: bytes - 4 by: 4 do:
				[:i| self longAt: dst + i put: (self longAt: src + i)]]
]

{ #category : #'simulation support' }
VMClass >> minorVersion [
	"This is implemented in sqVirtualMachine.c, so this form is for simulation only."
	<doNotGenerate>
	^self class vmProxyMinorVersion
]

{ #category : #'translation support' }
VMClass >> notYetImplemented [

	<inline: true>

	self
		cCode: [ 
			self logError: 'not yet implemented'.
			self abort ]
		inSmalltalk: [ super notYetImplemented ]
]

{ #category : #'translation support' }
VMClass >> numElementsIn: anArray [
	<cmacro: '(anArray) (sizeof(anArray)/sizeof(anArray[0]))'>
	^anArray size
]

{ #category : #accessing }
VMClass >> objectRepresentationClass [
	<doNotGenerate>
	^self class objectRepresentationClass
]

{ #category : #'oop comparison' }
VMClass >> oop: anOop isGreaterThan: otherOop [
	"Compare two oop values, treating them as object memory locations; i.e. use unsigned comparisons.
	 Use a macro, instead of #cCoerce:to: to provide fast simulation and inline code in conditionals,
	 since the inliner doesn't inline in condtionals."
	<cmacro: '(anOop,otherOop) ((usqInt)(anOop) > (usqInt)(otherOop))'>
	^anOop > otherOop
]

{ #category : #'oop comparison' }
VMClass >> oop: anOop isGreaterThan: baseOop andLessThan: limitOop [
	"Compare two oop values, treating them as object memory locations; i.e. use unsigned comparisons.
	 Use a macro, instead of #cCoerce:to: to provide fast simulation and inline code in conditionals,
	 since the inliner doesn't inline in condtionals."
	<cmacro: '(anOop,baseOop,limitOop) ((usqInt)(anOop) > (usqInt)(baseOop) && (usqInt)(anOop) < (usqInt)(limitOop))'>
	^anOop > baseOop and: [anOop < limitOop]
]

{ #category : #'oop comparison' }
VMClass >> oop: anOop isGreaterThanOrEqualTo: otherOop [
	"Compare two oop values, treating them as object memory locations; i.e. use unsigned comparisons.
	 Use a macro, instead of #cCoerce:to: to provide fast simulation and inline code in conditionals,
	 since the inliner doesn't inline in condtionals."
	<cmacro: '(anOop,otherOop) ((usqInt)(anOop) >= (usqInt)(otherOop))'>
	^anOop >= otherOop
]

{ #category : #'oop comparison' }
VMClass >> oop: anOop isGreaterThanOrEqualTo: baseOop andLessThan: limitOop [
	"Compare two oop values, treating them as object memory locations; i.e. use unsigned comparisons.
	 Use a macro, instead of #cCoerce:to: to provide fast simulation and inline code in conditionals,
	 since the inliner doesn't inline in condtionals."
	<cmacro: '(anOop,baseOop,limitOop) ((usqInt)(anOop) >= (usqInt)(baseOop) && (usqInt)(anOop) < (usqInt)(limitOop))'>
	^anOop >= baseOop and: [anOop < limitOop]
]

{ #category : #'oop comparison' }
VMClass >> oop: anOop isGreaterThanOrEqualTo: baseOop andLessThanOrEqualTo: limitOop [
	"Compare two oop values, treating them as object memory locations; i.e. use unsigned comparisons.
	 Use a macro, instead of #cCoerce:to: to provide fast simulation and inline code in conditionals,
	 since the inliner doesn't inline in condtionals."
	<cmacro: '(anOop,baseOop,limitOop) ((usqInt)(anOop) >= (usqInt)(baseOop) && (usqInt)(anOop) <= (usqInt)(limitOop))'>
	^anOop >= baseOop and: [anOop <= limitOop]
]

{ #category : #'oop comparison' }
VMClass >> oop: anOop isLessThan: otherOop [
	"Compare two oop values, treating them as object memory locations; i.e. use unsigned comparisons.
	 Use a macro, instead of #cCoerce:to: to provide fast simulation and inline code in conditionals,
	 since the inliner doesn't inline in condtionals."
	<cmacro: '(anOop,otherOop) ((usqInt)(anOop) < (usqInt)(otherOop))'>
	^anOop < otherOop
]

{ #category : #'oop comparison' }
VMClass >> oop: anOop isLessThanOrEqualTo: otherOop [
	"Compare two oop values, treating them as object memory locations; i.e. use unsigned comparisons.
	 Use a macro, instead of #cCoerce:to: to provide fast simulation and inline code in conditionals,
	 since the inliner doesn't inline in condtionals."
	<cmacro: '(anOop,otherOop) ((usqInt)(anOop) <= (usqInt)(otherOop))'>
	^anOop <= otherOop
]

{ #category : #'memory access' }
VMClass >> oopForPointer: pointerOrSurrogate [
	"This gets implemented by Macros in C, where its types will also be checked.
	 oop is the width of a machine word, and pointer is a raw address."
	<doNotGenerate>
	^pointerOrSurrogate asInteger
]

{ #category : #'memory access' }
VMClass >> pointerAtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is the width of a machine word."
	<doNotGenerate>

	^self longAt: pointer
]

{ #category : #'memory access' }
VMClass >> pointerAtPointer: pointer put: value [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is the width of a machine word."
	<doNotGenerate>

	^self longAt: pointer put: value
]

{ #category : #'translation support' }
VMClass >> pointerForOop: oop [
	"This gets implemented by Macros in C, where its types will also be checked.
	 oop is the width of a machine word, and pointer is a raw address."
	<doNotGenerate>

	^oop
]

{ #category : #'simulation support' }
VMClass >> promptHex: string [
	<doNotGenerate>
	| s |
	s := UIManager default request: string, ' (hex)'.
	s := s withBlanksTrimmed.
	^(s notEmpty and: ['-+0123456789abcdefABCDEF' includes: s first]) ifTrue:
		[(s includes: $r)
			ifTrue:
				[Number readFrom: s readStream]
			ifFalse:
				[(#('0x' '-0x') detect: [:prefix| s beginsWith: prefix] ifNone: []) ifNotNil:
					[:prefix|
					s := s allButFirst: prefix size.
					prefix first = $- ifTrue: [s := '-', s]].
				Integer readFrom: s readStream base: 16]]
]

{ #category : #'simulation support' }
VMClass >> promptNum: string [
	<doNotGenerate>
	| s |
	s := UIManager default request: string, ' (dec)'.
	s := s withBlanksTrimmed.
	^s notEmpty ifTrue:
		[Number readFrom: s readStream]
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
VMClass >> simulationOnly: aBlock [

	"Evaluate piece of code only during simulation.
	This should get translated as a NOP"
	<inline: #always>
	self
		cCode: [  ]
		inSmalltalk: aBlock
]

{ #category : #'memory access' }
VMClass >> singleFloatAtPointer: pointer [
	<doNotGenerate>
	self halt.
]

{ #category : #'memory access' }
VMClass >> singleFloatAtPointer: pointer put: value [
	<doNotGenerate>
	self halt.
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

{ #category : #'C library simulation' }
VMClass >> strcat: aString _: bString [
	<doNotGenerate>
	"implementation of strcat(3)"
	^(self asString: aString), (self asString: bString)
]

{ #category : #'C library extensions' }
VMClass >> stretch: s1 cat: s2 [
	<var: 's1' type: #'char *'>
	<var: 's2' type: #'char *'>
	| ns |
	<var: 'ns' type: #'char *'>
	^self
		cCode:
			[ns := self malloc: (self strlen: s1) + (self strlen: s2) + 2.
			 self strcpy: ns _: s1.
			 self strcat: ns  _: s2]
		inSmalltalk: [self strcat: s1  _: s2]
]

{ #category : #'C library simulation' }
VMClass >> strlen: aCString [
	"Simulate strlen(3)"
	<doNotGenerate>
	| len |

	aCString isCArray ifTrue:
		[len := 0.
		 [(aCString at: len) = 0 ifTrue: [^len].
		 len := len + 1] repeat]
	ifFalse:
		[aCString isString ifTrue: 
			[^aCString size]
		ifFalse:
			[aCString class == ByteArray ifTrue: [
				"ByteArrays may be 0 terminated or the correct length (in the simulator)"
				len := 0.
				[(len = aCString size or: [(aCString at: len+1) = 0]) ifTrue: [^len].
				len := len + 1] repeat]]].
	"Must be an address"
	len := 0.
	[(self byteAt: aCString + len) = 0 ifTrue: [^len].
	len := len + 1] repeat
]

{ #category : #'C library simulation' }
VMClass >> strncmp: aString _: bString _: n [
	<doNotGenerate>
	"implementation of strncmp(3)"
	bString isString
		ifTrue:
			[1 to: n do:
				[:i| | v |
				 v := (aString basicAt: i) - (bString basicAt: i).
				 v ~= 0 ifTrue: [^v]]]
		ifFalse:
			[1 to: n do:
				[:i| | v |
				 v := (aString basicAt: i) - (self byteAt: bString + i - 1).
				 v ~= 0 ifTrue: [^v]]].
	^0
]

{ #category : #'C library simulation' }
VMClass >> strncpy: dest _: src _: n [
	<doNotGenerate>
	"implementation of strncpy(3).
	 See e.g. https://manpages.debian.org/stretch/manpages-dev/strncpy.3.en.html
	 The C version always takes an address; the simulation allows a String, ByteArray,
	 CArray or address within the simulation object memory (Positive Integer)"
	| getBlock setBlock count |
	count := n.
	"Determine the source and destination access blocks based on the parameter type"
	getBlock := src isCollection
					ifTrue:
						[count := count min: src size.
						 src isString
							ifTrue: [[ :idx | src basicAt: idx]] "basicAt: answers integers"
							ifFalse:
								[src class == ByteArray ifTrue:
									[[ :idx | src at: idx]]]]
					ifFalse:
						[src isInteger
							ifTrue: [[ :idx | self byteAt: src + idx - 1]]
							ifFalse:
								[src isCArray ifTrue:
									[[ :idx | src at: idx - 1]]]].
	getBlock ifNil: [self error: 'unhandled type of source string'].
	setBlock := dest isCollection
					ifTrue:
						[dest isString
							ifTrue: [[ :idx | dest basicAt: idx put: (getBlock value: idx)]] "basicAt:put: stores integers"
							ifFalse:
								[dest class == ByteArray ifTrue:
									[[ :idx | dest at: idx put: (getBlock value: idx)]]]]
					ifFalse:
						[dest isInteger ifTrue: 
							[[ :idx | self byteAt: dest + idx - 1 put: (getBlock value: idx)]]].
	setBlock ifNil: [self error: 'unhandled type of destination string'].
	1 to: count do: setBlock.
	"SVr4, 4.3BSD, C89, C99 require the remainder of the buffer be filled with nulls"
	getBlock := [:idx| 0].
	count + 1 to: n do: setBlock.
	^dest
]

{ #category : #'hack compatibility' }
VMClass >> uiProcess [
	<doNotGenerate>
	^ UIManager default uiProcess
]

{ #category : #'memory access' }
VMClass >> uint16AtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 16 bit integer."
	<doNotGenerate>

	^self shortAt: pointer
]

{ #category : #'memory access' }
VMClass >> uint16AtPointer: pointer put: value [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 16 bit integer."
	<doNotGenerate>

	^self shortAt: pointer put: value
]

{ #category : #'memory access' }
VMClass >> uint32AtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 32 bit integer."
	<doNotGenerate>

	^self longAt: pointer
]

{ #category : #'memory access' }
VMClass >> uint32AtPointer: pointer put: value [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 32 bit integer."
	<doNotGenerate>

	^self longAt: pointer put: value
]

{ #category : #'memory access' }
VMClass >> uint64AtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is the width of a machine word."
	<doNotGenerate>

	^self halt
]

{ #category : #'memory access' }
VMClass >> uint64AtPointer: pointer put: longValue [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and longValue is the width of a machine word."
	<doNotGenerate>

	^self halt.
]

{ #category : #'memory access' }
VMClass >> uint8AtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 16 bit integer."
	<doNotGenerate>

	^self at: pointer
]

{ #category : #'memory access' }
VMClass >> uint8AtPointer: pointer put: value [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is an 16 bit integer."
	<doNotGenerate>

	^self at: pointer put: value
]

{ #category : #simulation }
VMClass >> unalignedAccessError [
	^self error: 'unaligned access'
]

{ #category : #'debug support' }
VMClass >> unreachable [
	<inline: true>
	self error: 'UNREACHABLE'
]

{ #category : #'hack compatibility' }
VMClass >> vmPath [
	<doNotGenerate>
	^ (Smalltalk classNamed: #VirtualMachine)
		  ifNotNil: [ :project | "Squeak" Smalltalk vm directory ]
		  ifNil: [ "Pharo" Smalltalk vmPath ]
]

{ #category : #'hack compatibility' }
VMClass >> vmPathSize [
	<doNotGenerate>
	^self vmPath size
]
