"
I am a shared pool for basic constants upon which the VM as a whole depends.

self ensureClassPool.
self classPool declare: #BytesPerWord from: VMSqueakV3ObjectRepresentationConstants classPool.
self classPool declare: #BaseHeaderSize from: VMSqueakV3ObjectRepresentationConstants classPool
(ObjectMemory classPool keys select: [:k| k beginsWith: 'Byte']) do:
	[:k| self classPool declare: k from: ObjectMemory classPool]
"
Class {
	#name : #VMBasicConstants,
	#superclass : #SharedPool,
	#classVars : [
		'BaseHeaderSize',
		'BytecodeSetHasExtensions',
		'BytesPerOop',
		'BytesPerWord',
		'COGMTVM',
		'COGVM',
		'CloneOnGC',
		'CloneOnScavenge',
		'DisownVMForFFICall',
		'DisownVMForProcessorRelinquish',
		'DisownVMForThreading',
		'DisownVMLockOutFullGC',
		'DoAssertionChecks',
		'DoExpensiveAssertionChecks',
		'FEATURE_FFI',
		'FEATURE_THREADED_FFI',
		'GCCheckPrimCall',
		'GCModeBecome',
		'GCModeFreeSpace',
		'GCModeFull',
		'GCModeImageSegment',
		'GCModeIncremental',
		'GCModeNewSpace',
		'HashMultiplyConstant',
		'HashMultiplyMask',
		'IMMUTABILITY',
		'MULTIPLEBYTECODESETS',
		'NewspeakVM',
		'PharoVM',
		'PrimErrBadArgument',
		'PrimErrBadIndex',
		'PrimErrBadMethod',
		'PrimErrBadNumArgs',
		'PrimErrBadReceiver',
		'PrimErrCallbackError',
		'PrimErrFFIException',
		'PrimErrGenericFailure',
		'PrimErrInappropriate',
		'PrimErrLimitExceeded',
		'PrimErrNamedInternal',
		'PrimErrNeedCompaction',
		'PrimErrNoCMemory',
		'PrimErrNoMemory',
		'PrimErrNoModification',
		'PrimErrNotFound',
		'PrimErrOSError',
		'PrimErrObjectIsPinned',
		'PrimErrObjectMayMove',
		'PrimErrObjectMoved',
		'PrimErrObjectNotPinned',
		'PrimErrOperationFailed',
		'PrimErrUnsupported',
		'PrimErrWritePastObject',
		'PrimNoErr',
		'SPURVM',
		'STACKVM',
		'SistaVM',
		'TempVectReadBarrier',
		'VMBIGENDIAN'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #'C translation' }
VMBasicConstants class >> defineAtCompileTime: anObject [
	^anObject isSymbol
	 and: [self namesDefinedAtCompileTime includes: anObject]
]

{ #category : #'C translation' }
VMBasicConstants class >> mostBasicConstantNames [
	"c.f. mostBasicConstantSelectors"
	^#(BaseHeaderSize BytesPerWord BytesPerOop ShiftForWord BytesPerWord)
]

{ #category : #'C translation' }
VMBasicConstants class >> mostBasicConstantSelectors [
	"c.f. mostBasicConstantNames"
	^#(	baseHeaderSize wordSize bytesPerOop shiftForWord
		bytesPerWord "bytesPerWord isn't used, but kept for history"
		minSmallInteger maxSmallInteger)
]

{ #category : #'C translation' }
VMBasicConstants class >> namesDefinedAtCompileTime [
	"Answer the set of names for variables that should be defined at compile time.
	 Some of these get default values during simulation, and hence get defaulted in
	 the various initializeMiscConstants methods.  But that they have values should
	 /not/ cause the code generator to do dead code elimination based on their
	 default values.  In particular, methods marked with <option: ANameDefinedAtCompileTime>
	 will be emitted within #if defined(ANameDefinedAtCompileTime)...#endif."
	^#(	VMBIGENDIAN
		IMMUTABILITY
		STACKVM COGVM COGMTVM SPURVM
		PharoVM								"Pharo vs Squeak"
		CheckRememberedInTrampoline		"IMMUTABILITY"
		LLDB									"As of lldb-370.0.42 Swift-3.1, passing funciton parameters to printOopsSuchThat fails with Internal error [IRForTarget]: Couldn't rewrite one of the arguments of a function call.  Turning off link time optimization with -fno-lto has no effect.  hence we define some debugging functions as being <option: LLDB>"

		"processor related"
		__ARM_ARCH__ __arm__ __arm32__ ARM32 __arm64__ ARM64
		_M_I386 _X86_ i386 i486 i586 i686 __i386__ __386__ X86 I386
		x86_64 __amd64 __x86_64 __amd64__ __x86_64__ _M_AMD64 _M_X64

		"os related"
		ACORN
		__GNUC__
		__linux__
		__MINGW32__
		__OpenBSD__
		__osf__
		UNIX
		WIN32 _WIN32 _WIN32_WCE
		WIN64 _WIN64 _WIN64_WCE
		
		FEATURE_FFI
		FEATURE_THREADED_FFI)
]

{ #category : #'C translation' }
VMBasicConstants class >> valueOfBasicSelector: selector [
	"Answer the numberic value of a basic constant accessed via the selector.
	 Answer nil if selector is not a basic constant accessor."
	"self mostBasicConstantSelectors collect: [:s| {s. self valueOfBasicSelector: s}]"
	| index key |
	^((index := self mostBasicConstantSelectors indexOf: selector) > 0
	  and: [(key := self mostBasicConstantNames at: index ifAbsent: []) notNil
	  and: [self includesKey: key]]) ifTrue:
		[classPool at: key]
]
