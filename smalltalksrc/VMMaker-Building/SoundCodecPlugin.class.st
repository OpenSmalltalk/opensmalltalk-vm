"
This plugin provide GSM typecodec capabilities.
"
Class {
	#name : #SoundCodecPlugin,
	#superclass : #InterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #accessing }
SoundCodecPlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #translation }
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
	<export: true>
	dstIndex := interpreterProxy stackIntegerValue: 0.
	dst := interpreterProxy stackValue: 1.
	srcIndex := interpreterProxy stackIntegerValue: 2.
	src := interpreterProxy stackValue: 3.
	frameCount := interpreterProxy stackIntegerValue: 4.
	state := interpreterProxy stackValue: 5.
	interpreterProxy success: (interpreterProxy isWords: dst).
	interpreterProxy success: (interpreterProxy isBytes: src).
	interpreterProxy success: (interpreterProxy isBytes: state).
	interpreterProxy failed ifTrue:[^ nil].
	srcSize := interpreterProxy slotSizeOf: src.
	dstSize := (interpreterProxy slotSizeOf: dst) * 2.
	self cCode: 'gsmDecode(state + BaseHeaderSize, frameCount, src, srcIndex, srcSize, dst, dstIndex, dstSize, &srcDelta, &dstDelta)'.
	interpreterProxy failed ifTrue:[^ nil].
	result := interpreterProxy makePointwithxValue: srcDelta yValue: dstDelta.
	interpreterProxy failed ifTrue:[^ nil].
	interpreterProxy pop: 6 thenPush: result
]

{ #category : #'gsm 6.10 codec' }
SoundCodecPlugin >> primitiveGSMEncode [

	| dstIndex dst srcIndex src frameCount state srcSize dstSize result srcDelta dstDelta |
	<export: true>
	dstIndex := interpreterProxy stackIntegerValue: 0.
	dst := interpreterProxy stackValue: 1.
	srcIndex := interpreterProxy stackIntegerValue: 2.
	src := interpreterProxy stackValue: 3.
	frameCount := interpreterProxy stackIntegerValue: 4.
	state := interpreterProxy stackValue: 5.
	interpreterProxy success: (interpreterProxy isBytes: dst).
	interpreterProxy success: (interpreterProxy isWords: src).
	interpreterProxy success: (interpreterProxy isBytes: state).
	interpreterProxy failed ifTrue:[^ nil].
	srcSize := (interpreterProxy slotSizeOf: src) * 2.
	dstSize := interpreterProxy slotSizeOf: dst.
	self cCode: 'gsmEncode(state + BaseHeaderSize, frameCount, src, srcIndex, srcSize, dst, dstIndex, dstSize, &srcDelta, &dstDelta)'.
	interpreterProxy failed ifTrue:[^ nil].
	result := interpreterProxy makePointwithxValue: srcDelta yValue: dstDelta.
	interpreterProxy failed ifTrue:[^ nil].
	interpreterProxy pop: 6 thenPush: result
]

{ #category : #'gsm 6.10 codec' }
SoundCodecPlugin >> primitiveGSMNewState [

	| state |
	<export: true>
	state := interpreterProxy
				instantiateClass: interpreterProxy classByteArray
				indexableSize: self gsmStateBytes.
	self gsmInitState: state + interpreterProxy baseHeaderSize.
	interpreterProxy pop: 1 thenPush: state
]
