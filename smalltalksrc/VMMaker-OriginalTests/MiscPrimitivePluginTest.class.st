"
Various classes in the image contain methods intended for translation to C for execution as primitives in MiscPrimitivePlugin. MiscPrimitivePluginTest provides tests to validate these methods.

"
Class {
	#name : #MiscPrimitivePluginTest,
	#superclass : #TestCase,
	#category : #'VMMaker-OriginalTests'
}

{ #category : #primitives }
MiscPrimitivePluginTest >> compare: string1 with: string2 collated: order [
	"Return 1, 2 or 3, if string1 is <, =, or > string2, with the collating order of characters given by the order array."

	<primitive: 'primitiveCompareString' module: 'MiscPrimitivePlugin'  error: ec>
	^ec
]

{ #category : #primitives }
MiscPrimitivePluginTest >> compress: bm toByteArray: ba [

	<primitive: 'primitiveCompressToByteArray' module: 'MiscPrimitivePlugin' error: ec>
	^ec
]

{ #category : #primitives }
MiscPrimitivePluginTest >> convert8bitSignedFrom: aByteArray to16Bit: aSoundBuffer [
	"Copy the contents of the given array of signed 8-bit samples into the given array of 16-bit signed samples."

	<primitive: 'primitiveConvert8BitSigned' module: 'MiscPrimitivePlugin' error: ec>
	^ec
]

{ #category : #primitives }
MiscPrimitivePluginTest >> decompress: bm fromByteArray: ba at: index [

	<primitive: 'primitiveDecompressFromByteArray' module: 'MiscPrimitivePlugin' error: ec>
	^ec
]

{ #category : #testing }
MiscPrimitivePluginTest >> expectedFailures [

	^#(testFindSubstringOldVersionWithMissingTypeChecks
		testFindSubstringInWideString)

]

{ #category : #primitives }
MiscPrimitivePluginTest >> findFirstInString: aString  inSet: inclusionMap  startingAt: start [

	<primitive: 'primitiveFindFirstInString' module: 'MiscPrimitivePlugin'  error: ec>
	^ec
]

{ #category : #primitives }
MiscPrimitivePluginTest >> findSubstring: key in: body startingAt: start matchTable: matchTable [
	"Answer the index in the string body at which the substring key first occurs, at or beyond start.  The match is determined using matchTable, which can be used to effect, eg, case-insensitive matches.  If no match is found, zero will be returned."

	<primitive: 'primitiveFindSubstring' module: 'MiscPrimitivePlugin' error: ec>
	^ec
]

{ #category : #primitives }
MiscPrimitivePluginTest >> hashBytes: aByteArray startingWith: speciesHash [
	"Answer the hash of a byte-indexed collection,
	using speciesHash as the initial value.
	See SmallInteger>>hashMultiply.

	The primitive should be renamed at a
	suitable point in the future"

	<primitive: 'primitiveStringHash' module: 'MiscPrimitivePlugin' error: ec>
	^ec
]

{ #category : #primitives }
MiscPrimitivePluginTest >> indexOfAscii: anInteger inString: aString startingAt: start [

	<primitive: 'primitiveIndexOfAsciiInString' module: 'MiscPrimitivePlugin' error: ec>
	^ec
]

{ #category : #testing }
MiscPrimitivePluginTest >> testCompareWithCollated [

	| collation |
	collation := (0 to: 255) asByteArray.
	self 
		assert: #'bad argument' 
			equals: (self compare: nil with: '' collated: collation)
			description: 'First argument must be a bytes object';
		assert: #'bad argument'
			equals: (self compare: '' with: nil collated: collation)
			description: 'Second argument must be a bytes object';
		assert: #'bad argument'
			equals: (self compare: '' with: '' collated: nil)
			description: 'Third argument must be a bytes object';
		assert: #'bad argument'
			equals: (self compare: '' with: '' collated: collation allButLast)
			description: 'Size of third argument must be at least 256'.
	self
		assert: 1 equals: (self compare: '' with: 'foo' collated: collation);
		assert: 1 equals: (self compare: 'bar' with: 'foo' collated: collation);
		assert: 1 equals: (self compare: 'bar' with: 'bare' collated: collation);		
		assert: 2 equals: (self compare: '' with: '' collated: collation);
		assert: 2 equals: (self compare: 'bar' with: 'bar' collated: collation);
		assert: 2 equals: (self compare: 'bar' with: 'bar' copy collated: collation);
		assert: 3 equals: (self compare: 'foo' with: '' collated: collation);
		assert: 3 equals: (self compare: 'foo' with: 'bar' collated: collation);
		assert: 3 equals: (self compare: 'bare' with: 'bar' collated: collation).
	collation
		at: $b asInteger + 1 put: $f asInteger;
		at: $a asInteger + 1 put: $o asInteger;
		at: $r asInteger + 1 put: $o asInteger.
	self
		assert: 2 equals: (self compare: 'bar' with: 'foo' collated: collation);
		assert: 2 equals: (self compare: 'foo' with: 'bar' collated: collation)
]

{ #category : #testing }
MiscPrimitivePluginTest >> testCompressToByteArray [

	| bitmap byteArray n |
	bitmap := Bitmap with: 16rFFFFFFFF.
	byteArray := ByteArray new:  12. "Primitive makes an estimate; hence output must have at least 11 bytes"
	n := self compress: bitmap toByteArray: byteArray.
	self assert: n = 3.
	self assert: #[1 5 255] equals: (byteArray copyFrom: 1 to: n)
]

{ #category : #testing }
MiscPrimitivePluginTest >> testConvert8bitSignedFromTo16Bit [
	"SampledSound class>>convert8bitSignedFrom:to16Bit:"


	| aByteArray aSoundBuffer |
	aByteArray := #[1 2 3 4 5 6 7 8 9].
	aSoundBuffer := SoundBuffer newMonoSampleCount: aByteArray size.
	self convert8bitSignedFrom: aByteArray to16Bit: aSoundBuffer.
	self assert: aSoundBuffer = ((SoundBuffer new: 10) at: 1 put: 256; at: 2 put: 512;
		at: 3 put: 768; at: 4 put: 1024; at: 5 put: 1280; at: 6 put: 1536; at: 7 put: 1792;
		at: 8 put: 2048; at: 9 put: 2304; at: 10 put: 0; yourself)
]

{ #category : #testing }
MiscPrimitivePluginTest >> testDecompressFromByteArrayAt [

	| bitmap byteArray s size |
	byteArray := #[1 5 255].
	s := ReadStream on: byteArray.
	size := Bitmap decodeIntFrom: s.
	bitmap := Bitmap new: size.
	self decompress: bitmap fromByteArray: byteArray at: s position + 1.
	self assert: (Bitmap with: 16rFFFFFFFF) equals: bitmap
]

{ #category : #testing }
MiscPrimitivePluginTest >> testFindFirstInStringInSetStartingAt [

	| position set |
	set := ((0 to: 255) collect: [:e | (e \\ 2) + $0 asciiValue]) asByteArray.
	position := self findFirstInString: 'abcdef' inSet: set startingAt: 1.
	self assert: position = 1

]

{ #category : #testing }
MiscPrimitivePluginTest >> testFindSubstringInByteString [
	"Verify that primitive exists in the VM and works as expected for byte
	sized string and key. If key is a WideString, as may be the case if testing
	for a WideString as substring of a byte sized string, then the primitive
	should fail. Earlier version of the primitive would accept the non-bytes
	parameter, leading to incorrect results, as documented in
	testFindSubstringOldVersionWithMissingTypeChecks"

	self
		assert: 2
		equals: (self
			findSubstring: 'bc'
			in: 'abcdef'
			startingAt: 1
			matchTable: (0 to: 255) asByteArray).
	self
		assert: #'bad argument'
		equals: (self
			findSubstring: 'bc' asWideString
			in: 'abcdef'
			startingAt: 1
			matchTable: (0 to: 255) asByteArray)

]

{ #category : #testing }
MiscPrimitivePluginTest >> testFindSubstringInWideString [
	"The primitive will fail if invoked on a non-byte receiver. WideString does
	not call the primitive, so this is an expected failure."

	| position |
	position := MiscPrimitivePluginTest new
				findSubstring: 'bc'
				in: 'abcdef' asWideString
				startingAt: 1
				matchTable: ((0 to: 255)
						as: ByteArray).
	self assert: position = 0.
	position := MiscPrimitivePluginTest new
				findSubstring: 'bc' asWideString
				in: 'abcdef' asWideString
				startingAt: 1
				matchTable: ((0 to: 255)
						as: ByteArray).
	self assert: position = 2

]

{ #category : #testing }
MiscPrimitivePluginTest >> testFindSubstringOldVersionWithMissingTypeChecks [
	"Verify that primitive exists in the VM. This test documents the behavior of older versions
	of the primitive that did not perform type checking on to fail on WideString parameters.
	Newer versions of the primitive handle this properly, hence this test is an expectedFailure.
	The fix for this issue (by Andreas Raab) is in TMethod>>argConversionExprFor:stackIndex:
	which was added to VMMaker in VMMaker-dtl.202.
	
	If this test passes, it is an indication that the TMethod>>argConversionExprFor:stackIndex:
	update is missing from the VMMaker code generator that produced the VM."
	
	"(MiscPrimitivePluginTest selector: #testArgsAsFlatArrayAndOffsets) run"

	| position |
	"If both receiver and argument are byte size, the primitive performs correctly"
	position := MiscPrimitivePluginTest new
				findSubstring: 'bc'
				in: 'abcdef'
				startingAt: 1
				matchTable: ((0 to: 255)
						as: ByteArray).
	self assert: position = 2.

	"Plugin accepts wide string argument, but should not do so."
	position := MiscPrimitivePluginTest new
				findSubstring: 'bc' asWideString
				in: 'abcdef'
				startingAt: 1
				matchTable: ((0 to: 255)
						as: ByteArray).
	self assert: position = 0.

	position := MiscPrimitivePluginTest new
				findSubstring: 'bc'
				in: 'abcdef' asWideString
				startingAt: 1
				matchTable: ((0 to: 255)
						as: ByteArray).
	self assert: position = 0.

	"Older versions of the plugin produce incorrect results here"
	position := MiscPrimitivePluginTest new
				findSubstring: 'bc' asWideString
				in: 'abcdef' asWideString
				startingAt: 1
				matchTable: ((0 to: 255)
						as: ByteArray).
	self assert: position = 5 "Incorrect!"

]

{ #category : #testing }
MiscPrimitivePluginTest >> testHashBytesStartingWith [

	| ba result |
	ba := #[1 2 3 4 5 6 7 8 9].
	result := self hashBytes: ba startingWith: 12345.
	self assert: result = 170953102

]

{ #category : #testing }
MiscPrimitivePluginTest >> testIindexOfAsciiInStringStartingAt [

	| position |
	position := self indexOfAscii: 50 inString: '012345' startingAt: 1.
	self assert: position = 3
]

{ #category : #testing }
MiscPrimitivePluginTest >> testTranslateFromToTable [
	"Verify that primitive exists in the VM"

	| s t |
	s := 'foo' copy. "copy so string is instantiated each time"
	t := (0 to: 255) asByteArray replace: [ :each | each + 1 \\ 256 ].
	self assert: self equals: (self translate: s from: 1 to: 3 table: t).
	self assert: s = 'gpp'

]

{ #category : #primitives }
MiscPrimitivePluginTest >> translate: aString from: start  to: stop  table: table [
	"translate the characters in the string by the given table, in place"

	<primitive: 'primitiveTranslateStringWithTable' module: 'MiscPrimitivePlugin' error: ec>
	^ec
]
