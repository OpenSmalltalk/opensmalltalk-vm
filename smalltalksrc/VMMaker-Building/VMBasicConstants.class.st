"
I am a shared pool for basic constants upon which the VM as a whole depends.

self ensureClassPool.
self classPool declare: #BytesPerWord from: VMSqueakV3ObjectRepresentationConstants classPool.
self classPool declare: #BaseHeaderSize from: VMSqueakV3ObjectRepresentationConstants classPool
"
Class {
	#name : #VMBasicConstants,
	#superclass : #SharedPool,
	#classVars : [
		'BaseHeaderSize',
		'BytesPerOop',
		'BytesPerWord',
		'DisownVMLockOutFullGC',
		'DoAssertionChecks',
		'DoExpensiveAssertionChecks',
		'PrimErrBadArgument',
		'PrimErrBadIndex',
		'PrimErrBadMethod',
		'PrimErrBadNumArgs',
		'PrimErrBadReceiver',
		'PrimErrGenericFailure',
		'PrimErrInappropriate',
		'PrimErrNamedInternal',
		'PrimErrNoCMemory',
		'PrimErrNoMemory',
		'PrimErrNoModification',
		'PrimErrNotFound',
		'PrimErrObjectMayMove',
		'PrimErrUnsupported',
		'ShiftForWord'
	],
	#category : #'VMMaker-Interpreter'
}
