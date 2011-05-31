"
self ensureClassPool.
#(CtxtTempFrameStart LargeContextBit LargeContextSize SmallContextSize) do:
	[:k|
	self classPool declare: k from: ObjectMemory classPool]
"
Class {
	#name : #VMSqueakV3BytecodeConstants,
	#superclass : #VMBasicConstants,
	#classVars : [
		'CtxtTempFrameStart',
		'LargeContextBit',
		'LargeContextSize',
		'SmallContextSize'
	],
	#pools : [
		'VMBasicConstants'
	],
	#category : #'VMMaker-Interpreter'
}
