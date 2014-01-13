"
self ensureClassPool.
#(CtxtTempFrameStart LargeContextBit LargeContextSize SmallContextSize) do:
	[:k|
	self classPool declare: k from: ObjectMemory classPool]
"
Class {
	#name : #VMSqueakV3BytecodeConstants,
	#superclass : #SharedPool,
	#classVars : [
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
