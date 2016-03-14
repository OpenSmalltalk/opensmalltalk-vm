"
self ensureClassPool.
#(CtxtTempFrameStart LargeContextBit LargeContextSize SmallContextSize) do:
	[:k|
	self classPool declare: k from: ObjectMemory classPool]
"
Class {
	#name : #VMBytecodeConstants,
	#superclass : #SharedPool,
	#classVars : [
		'BytecodeSetHasDirectedSuperSend',
		'CtxtTempFrameStart',
		'LargeContextBit',
		'LargeContextSize',
		'LargeContextSlots',
		'SmallContextSize',
		'SmallContextSlots'
	],
	#pools : [
		'VMBasicConstants'
	],
	#category : #'VMMaker-Interpreter'
}
