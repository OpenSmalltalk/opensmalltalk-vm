"
This plugin provide GSM typecodec capabilities.
"
Class {
	#name : #SoundCodecPlugin,
	#superclass : #InterpreterPlugin,
	#category : 'VMMaker-Plugins'
}

{ #category : #accessing }
SoundCodecPlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #accessing }
SoundCodecPlugin class >> moduleName [

	^ 'SoundCodecPrims' "Needs to be the name used for module specification..."

]

{ #category : #accessing }
SoundCodecPlugin class >> requiresCrossPlatformFiles [
	"If there cross platform files to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #'gsm 6.10 codec' }
SoundCodecPlugin >> primitiveGSMDecode [

	| dstIndex dst srcIndex src frameCount state srcSize dstSize result srcDelta dstDelta |
	self export: true.
	dstIndex _ interpreterProxy stackIntegerValue: 0.
	dst _ interpreterProxy stackObjectValue: 1.
	srcIndex _ interpreterProxy stackIntegerValue: 2.
	src _ interpreterProxy stackObjectValue: 3.
	frameCount _ interpreterProxy stackIntegerValue: 4.
	state _ interpreterProxy stackObjectValue: 5.
	interpreterProxy success: (interpreterProxy isWords: dst).
	interpreterProxy success: (interpreterProxy isBytes: src).
	interpreterProxy success: (interpreterProxy isBytes: state).
	interpreterProxy failed ifTrue:[^ nil].
	srcSize _ interpreterProxy slotSizeOf: src.
	dstSize _ (interpreterProxy slotSizeOf: dst) * 2.
	self cCode: 'gsmDecode(state + 4, frameCount, src, srcIndex, srcSize, dst, dstIndex, dstSize, &srcDelta, &dstDelta)'.
	interpreterProxy failed ifTrue:[^ nil].
	result _ interpreterProxy makePointwithxValue: srcDelta yValue: dstDelta.
	interpreterProxy failed ifTrue:[^ nil].
	interpreterProxy pop: 6.
	interpreterProxy push: result.

]

{ #category : #'gsm 6.10 codec' }
SoundCodecPlugin >> primitiveGSMEncode [

	| dstIndex dst srcIndex src frameCount state srcSize dstSize result srcDelta dstDelta |
	self export: true.
	dstIndex _ interpreterProxy stackIntegerValue: 0.
	dst _ interpreterProxy stackObjectValue: 1.
	srcIndex _ interpreterProxy stackIntegerValue: 2.
	src _ interpreterProxy stackObjectValue: 3.
	frameCount _ interpreterProxy stackIntegerValue: 4.
	state _ interpreterProxy stackObjectValue: 5.
	interpreterProxy success: (interpreterProxy isBytes: dst).
	interpreterProxy success: (interpreterProxy isWords: src).
	interpreterProxy success: (interpreterProxy isBytes: state).
	interpreterProxy failed ifTrue:[^ nil].
	srcSize _ (interpreterProxy slotSizeOf: src) * 2.
	dstSize _ interpreterProxy slotSizeOf: dst.
	self cCode: 'gsmEncode(state + 4, frameCount, src, srcIndex, srcSize, dst, dstIndex, dstSize, &srcDelta, &dstDelta)'.
	interpreterProxy failed ifTrue:[^ nil].
	result _ interpreterProxy makePointwithxValue: srcDelta yValue: dstDelta.
	interpreterProxy failed ifTrue:[^ nil].
	interpreterProxy pop: 6.
	interpreterProxy push: result.

]

{ #category : #'gsm 6.10 codec' }
SoundCodecPlugin >> primitiveGSMNewState [

	| stateBytes state |
	self export: true.
	stateBytes _ self cCode: 'gsmStateBytes()'.
	state _ interpreterProxy
		instantiateClass: interpreterProxy classByteArray
		indexableSize: stateBytes.
	self cCode: 'gsmInitState(state + 4)'.
	interpreterProxy push: state.

]
