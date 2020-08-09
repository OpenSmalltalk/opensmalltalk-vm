"
Various classes in the image contain methods that are intended to be translated to C and executed as primitives. IncludedMethodsTest provides tests to validate these methods.

"
Class {
	#name : #IncludedMethodsTest,
	#superclass : #TestCase,
	#category : #'VMMaker-OriginalTests'
}

{ #category : #primitives }
IncludedMethodsTest >> compare: string1 with: string2 collated: order [
	"Return 1, 2 or 3, if string1 is <, =, or > string2, with the collating order of characters given by the order array."

	<primitive: 'primitiveCompareString' module: 'MiscPrimitivePlugin'>
	self primitiveFailed

]

{ #category : #primitives }
IncludedMethodsTest >> compress: bm toByteArray: ba [

	<primitive: 'primitiveCompressToByteArray' module: 'MiscPrimitivePlugin'>
	self primitiveFailed
]

{ #category : #primitives }
IncludedMethodsTest >> convert8bitSignedFrom: aByteArray to16Bit: aSoundBuffer [
	"Copy the contents of the given array of signed 8-bit samples into the given array of 16-bit signed samples."

	<primitive: 'primitiveConvert8BitSigned' module: 'MiscPrimitivePlugin'>
	self primitiveFailed

]

{ #category : #primitives }
IncludedMethodsTest >> decompress: bm fromByteArray: ba at: index [

	<primitive: 'primitiveDecompressFromByteArray' module: 'MiscPrimitivePlugin'>
	self primitiveFailed

]

{ #category : #primitives }
IncludedMethodsTest >> findFirstInString: aString  inSet: inclusionMap  startingAt: start [

	<primitive: 'primitiveFindFirstInString' module: 'MiscPrimitivePlugin'>
	self primitiveFailed

]

{ #category : #primitives }
IncludedMethodsTest >> findSubstring: key in: body startingAt: start matchTable: matchTable [
	"Answer the index in the string body at which the substring key first occurs, at or beyond start.  The match is determined using matchTable, which can be used to effect, eg, case-insensitive matches.  If no match is found, zero will be returned."

	<primitive: 'primitiveFindSubstring' module: 'MiscPrimitivePlugin'>
	self primitiveFailed

]

{ #category : #primitives }
IncludedMethodsTest >> indexOfAscii: anInteger inString: aString startingAt: start [

	<primitive: 'primitiveIndexOfAsciiInString' module: 'MiscPrimitivePlugin'>
	self primitiveFailed

]

{ #category : #primitives }
IncludedMethodsTest >> mixSampleCount: n into: aSoundBuffer startingAt: startIndex leftVol: leftVol rightVol: rightVol [
	"Play samples from a wave table by stepping a fixed amount through the table on every sample. The table index and increment are scaled to allow fractional increments for greater pitch accuracy."
	"(FMSound pitch: 440.0 dur: 1.0 loudness: 0.5) play"

	<primitive:'primitiveMixFMSound' module:'SoundGenerationPlugin'>
	self primitiveFailed

]

{ #category : #'testing - MiscPrimitivePlugin' }
IncludedMethodsTest >> testCompareWithCollated [
	"Verify that primitive exists in the VM"

	self assert: 3 = (self compare: 'foo' with: 'bar' collated: ((0 to: 255) as: ByteArray))

]

{ #category : #'testing - MiscPrimitivePlugin' }
IncludedMethodsTest >> testCompressToByteArray [

	| bitmap byteArray |
	bitmap := Bitmap with: 16rFFFFFFFF.
	byteArray := ByteArray new:  4.
	self compress: bitmap toByteArray: byteArray.
	self should: byteArray = #[1 5 255 0]
]

{ #category : #'testing - MiscPrimitivePlugin' }
IncludedMethodsTest >> testConvert8bitSignedFromTo16Bit [
	"SampledSound class>>convert8bitSignedFrom:to16Bit:"


	| aByteArray aSoundBuffer |
	aByteArray := #[1 2 3 4 5 6 7 8 9].
	aSoundBuffer := SoundBuffer newMonoSampleCount: aByteArray size.
	self convert8bitSignedFrom: aByteArray to16Bit: aSoundBuffer.
	self assert: aSoundBuffer = ((SoundBuffer new: 10) at: 1 put: 256; at: 2 put: 512;
		at: 3 put: 768; at: 4 put: 1024; at: 5 put: 1280; at: 6 put: 1536; at: 7 put: 1792;
		at: 8 put: 2048; at: 9 put: 2304; at: 10 put: 0; yourself)
]

{ #category : #'testing - MiscPrimitivePlugin' }
IncludedMethodsTest >> testDecompressFromByteArrayAt [

	| bitmap byteArray s size |
	byteArray := #(1 5 255  0) asByteArray.
	s := ReadStream on: byteArray.
	size := Bitmap decodeIntFrom: s.
	bitmap := Bitmap new: size.
	self decompress: bitmap fromByteArray: byteArray at: s position + 1.
	self should: bitmap = ((Bitmap new: 1) at: 1 put: 4294967295; yourself)
]

{ #category : #'testing - MiscPrimitivePlugin' }
IncludedMethodsTest >> testFindFirstInStringInSetStartingAt [

	| position set |
	set := ((0 to: 255) collect: [:e | (e \\ 2) + $0 asciiValue]) asByteArray.
	position := self findFirstInString: 'abcdef' inSet: set startingAt: 1.
	self assert: position = 1

]

{ #category : #'testing - MiscPrimitivePlugin' }
IncludedMethodsTest >> testFindSubstring [
	"Verify that primitive exists in the VM and that non byte array arguments cause primitive to fail"

	| position |
	position := IncludedMethodsTest new
				findSubstring: 'bc'
				in: 'abcdef'
				startingAt: 1
				matchTable: ((0 to: 255)
						as: ByteArray).
	self assert: position = 2.
	self should: [IncludedMethodsTest new
				findSubstring: 'bc' asWideString
				in: 'abcdef'
				startingAt: 1
				matchTable: ((0 to: 255)
						as: ByteArray)]
					raise: Error.
	self should: [IncludedMethodsTest new
				findSubstring: 'bc'
				in: 'abcdef' asWideString
				startingAt: 1
				matchTable: ((0 to: 255)
						as: ByteArray)]
					raise: Error.
	self should: [IncludedMethodsTest new
				findSubstring: 'bc' asWideString
				in: 'abcdef' asWideString
				startingAt: 1
				matchTable: ((0 to: 255)
						as: ByteArray)]
					raise: Error

]

{ #category : #'testing - MiscPrimitivePlugin' }
IncludedMethodsTest >> testIindexOfAsciiInStringStartingAt [

	| position |
	position := self indexOfAscii: 50 inString: '012345' startingAt: 1.
	self assert: position = 3
]

{ #category : #'testing - SoundGeneratorPlugin' }
IncludedMethodsTest >> testMixSampleCountIntoStartingAtLeftVolRightVol [

	"mixSampleCount: n into: aSoundBuffer startingAt: startIndex leftVol: leftVol rightVol: rightVol"
]

{ #category : #'testing - MiscPrimitivePlugin' }
IncludedMethodsTest >> testTranslateFromToTable [
	"Verify that primitive exists in the VM"

	| s t |
	s := 'foo' copy. "copy so string is instantiated each time"
	t := ByteArray withAll: ((1 to: 255) as: ByteArray).
	self translate: s from: 1 to: 3 table: t.
	self assert: s = 'gpp'

]

{ #category : #'testing - ADPCMCodecPlugin' }
IncludedMethodsTest >> todoForADPCMCodecPlugin [
	"TODO - write tests for these"

	^#(
		(ADPCMCodec privateDecodeMono:)
		(ADPCMCodec privateDecodeStereo:)
		(ADPCMCodec privateEncodeMono:)
		(ADPCMCodec privateEncodeStereo:)
		(ADPCMCodec indexForDeltaFrom:to:)
		(ADPCMCodec nextBits:)
		(ADPCMCodec nextBits:put:)
		)
]

{ #category : #'testing - SoundGeneratorPlugin' }
IncludedMethodsTest >> todoForSoundGeneratorPlugin [
	"TODO - write tests for these"

	^#(
		(FMSound mixSampleCount:into:startingAt:leftVol:rightVol:)
		(PluckedSound mixSampleCount:into:startingAt:leftVol:rightVol:)
		(LoopedSampledSound mixSampleCount:into:startingAt:leftVol:rightVol:)
		(SampledSound mixSampleCount:into:startingAt:leftVol:rightVol:)
		(ReverbSound applyReverbTo:startingAt:count:)
		)
]

{ #category : #primitives }
IncludedMethodsTest >> translate: aString from: start  to: stop  table: table [
	"translate the characters in the string by the given table, in place"

	<primitive: 'primitiveTranslateStringWithTable' module: 'MiscPrimitivePlugin'>
	self primitiveFailed
]
