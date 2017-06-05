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
		'DisownVMLockOutFullGC',
		'DoAssertionChecks',
		'DoExpensiveAssertionChecks',
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
		'LowcodeVM',
		'MULTIPLEBYTECODESETS',
		'NewspeakVM',
		'PharoVM',
		'PrimErrBadArgument',
		'PrimErrBadIndex',
		'PrimErrBadMethod',
		'PrimErrBadNumArgs',
		'PrimErrBadReceiver',
		'PrimErrCallbackError',
		'PrimErrGenericFailure',
		'PrimErrInappropriate',
		'PrimErrLimitExceeded',
		'PrimErrNamedInternal',
		'PrimErrNoCMemory',
		'PrimErrNoMemory',
		'PrimErrNoModification',
		'PrimErrNotFound',
		'PrimErrObjectIsPinned',
		'PrimErrObjectMayMove',
		'PrimErrObjectMoved',
		'PrimErrObjectNotPinned',
		'PrimErrUnsupported',
		'PrimErrWritePastObject',
		'PrimNoErr',
		'SPURVM',
		'STACKVM',
		'SistaVM',
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
	 default values."
	^#(	VMBIGENDIAN
		IMMUTABILITY
		STACKVM COGVM COGMTVM SPURVM
		PharoVM								"Pharo vs Squeak"
		EnforceAccessControl					"Newspeak"
		CheckRememberedInTrampoline		"IMMUTABILITY"
		LLDB)									"As of lldb-370.0.42 Swift-3.1, passing funciton parameters to printOopsSuchThat fails with Internal error [IRForTarget]: Couldn't rewrite one of the arguments of a function call.  Turning off link time optimization with -fno0lto has no effect.  hence we define some debugging functions as being <option: LLDB>"
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
