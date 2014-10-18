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
		'Byte0Mask',
		'Byte0Shift',
		'Byte1Mask',
		'Byte1Shift',
		'Byte1ShiftNegated',
		'Byte2Mask',
		'Byte2Shift',
		'Byte3Mask',
		'Byte3Shift',
		'Byte3ShiftNegated',
		'Byte4Mask',
		'Byte4Shift',
		'Byte4ShiftNegated',
		'Byte5Mask',
		'Byte5Shift',
		'Byte5ShiftNegated',
		'Byte6Mask',
		'Byte6Shift',
		'Byte7Mask',
		'Byte7Shift',
		'Byte7ShiftNegated',
		'Bytes3to0Mask',
		'Bytes7to4Mask',
		'BytesPerOop',
		'BytesPerWord',
		'COGMTVM',
		'COGVM',
		'DisownVMLockOutFullGC',
		'DoAssertionChecks',
		'DoExpensiveAssertionChecks',
		'GCModeBecome',
		'GCModeFull',
		'GCModeIncr',
		'GCModeScavenge',
		'IMMUTABILITY',
		'MULTIPLEBYTECODESETS',
		'NewspeakVM',
		'PrimErrBadArgument',
		'PrimErrBadIndex',
		'PrimErrBadMethod',
		'PrimErrBadNumArgs',
		'PrimErrBadReceiver',
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
		'PrimErrUnsupported',
		'PrimErrWritePastObject',
		'PrimNoErr',
		'STACKVM',
		'ShiftForWord',
		'SistaVM',
		'VMBIGENDIAN'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #accessing }
VMBasicConstants class >> mostBasicConstantNames [
	"c.f. CCodeGenerator class>>#mostBasicConstantSelectors"
	^#(BaseHeaderSize BytesPerWord BytesPerOop)
]
