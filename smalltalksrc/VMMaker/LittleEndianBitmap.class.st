Class {
	#name : #LittleEndianBitmap,
	#superclass : #Bitmap,
	#type : #words,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #converting }
LittleEndianBitmap >> asByteArray [
	"Faster way to make a byte array from me.
	copyFromByteArray: makes equal Bitmap."
	| f bytes hack |
	EndianDetector isLittleEndian ifTrue:
		[bytes := self shallowCopy.
		 ByteArray adoptInstance: bytes.
		 ^bytes].
	f := Form extent: 4@self size depth: 8 bits: self.
	bytes := ByteArray new: self size * 4.
	hack := Form new hackBits: bytes.
	hack swapEndianness.
	hack copyBits: f boundingBox
		from: f
		at: 0@0
		clippingBox: hack boundingBox
		rule: Form over
		fillColor: nil
		map: nil.
	"f displayOn: hack."
	^bytes
	"| v | v := LittleEndianBitmap withAll: (1 to: 4).
	 [v asByteArray] bench '19,700,000 per second. 50.8 nanoseconds per run.'"
	"| v | v := Bitmap withAll: (1 to: 4).
	[v asByteArray] bench '977,000 per second. 1.02 microseconds per run.'"
]

{ #category : #accessing }
LittleEndianBitmap >> byteAt: byteAddress [
	"Extract a byte from a Bitmap (little-endian version)"
	| lowBits |
	lowBits := byteAddress - 1 bitAnd: 3.
	^((self at: byteAddress - 1 - lowBits // 4 + 1)
		bitShift: lowBits * -8)
		bitAnd: 16rFF
]

{ #category : #accessing }
LittleEndianBitmap >> byteAt: byteAddress put: byte [
	"Insert a byte into a Bitmap (little-endian version).  N.B. Signedness will be lost since byteAt: answers non-negative values.
	 We can add a signedByteAt: if needed."
	| value longWord shift lowBits longAddr |
	(byte < 0 or:[byte > 255]) ifTrue:[^self errorImproperStore].
	value := byte < 0
				ifTrue: [byte < 128 ifTrue:
							[self errorImproperStore].
						16rFF bitAnd: byte]
				ifFalse: [16rFF < byte ifTrue:
							[self errorImproperStore].
						byte].
	lowBits := byteAddress - 1 bitAnd: 3.
	longWord := self at: (longAddr := (byteAddress - 1 - lowBits) // 4 + 1).
	shift := lowBits * 8.
	longWord := longWord
				- (longWord bitAnd: (16rFF bitShift: shift)) 
				+ (value bitShift: shift).
	self at: longAddr put: longWord.
	^byte
]

{ #category : #accessing }
LittleEndianBitmap >> long64At: byteAddress [
	| lowBits hiWord loWord midWord mask wordIndex result signBit |
	wordIndex := byteAddress - 1 // 4 + 1.
	(lowBits := byteAddress - 1 \\ 4) = 0 ifTrue:
		[loWord := self at: wordIndex.
		 hiWord := self at: wordIndex + 1.
		 ^hiWord = 0
			ifTrue: [loWord]
			ifFalse: [(hiWord signedIntFromLong bitShift: 32) + loWord]].
	"There will always be three accesses; two partial words and a full word in the middle"
	mask := 16rFFFFFFFF bitShift: 4 - lowBits * -8.
	loWord := (self at: wordIndex) bitAnd: mask bitInvert32.
	midWord := self at: wordIndex + 1.
	hiWord := (self at: wordIndex + 2) bitAnd: mask.
	result := loWord bitShift: lowBits * -8.
	midWord ~= 0 ifTrue:
		[result := result + (midWord bitShift: (4 - lowBits * 8))].
	hiWord ~= 0 ifTrue:
		[signBit := 1 << (lowBits * 8 - 1).
		 (signBit anyMask: hiWord) ifTrue:
			[hiWord := hiWord - signBit - signBit].
		 result := result + (hiWord bitShift: (4 - lowBits + 4 * 8))].
	^result
]

{ #category : #accessing }
LittleEndianBitmap >> long64At: byteIndex put: aValue [
	| lowBits mask wordIndex |
	(lowBits := byteIndex - 1 \\ 4) = 0 ifTrue:
		[self "N.B. Do the access that can fail first, before altering the receiver"
			longAt: byteIndex + 4 put: (aValue bitShift: -32);
			unsignedLongAt: byteIndex put: (aValue bitAnd: 16rffffffff).
		^aValue].
	"There will always be three accesses; two partial words and a full word in the middle"
	wordIndex := byteIndex - 1 // 4 + 1.
	aValue < 0
		ifTrue:
			[(aValue bitShift: -32) < -2147483648 ifTrue:
				[^self errorImproperStore]]
		ifFalse:
			[16r7FFFFFFF < (aValue bitShift: -32) ifTrue:
				[^self errorImproperStore]].
	mask := 16rFFFFFFFF bitShift: 4 - lowBits * -8.
	self at: wordIndex put: (((self at: wordIndex) bitAnd: mask) bitXor: ((aValue bitShift: lowBits * 8) bitAnd: mask bitInvert32)).
	self at: wordIndex + 1 put: ((aValue bitShift: 4 - lowBits * -8) bitAnd: 16rFFFFFFFF).
	self at: wordIndex + 2 put: (((self at: wordIndex + 2) bitAnd: mask bitInvert32) bitXor: ((aValue bitShift: 4 - lowBits + 4 * -8) bitAnd: mask)).
	^aValue
]

{ #category : #accessing }
LittleEndianBitmap >> longAt: byteIndex [
	^self longAt: byteIndex bigEndian: false
]

{ #category : #accessing }
LittleEndianBitmap >> longAt: byteIndex bigEndian: bigEndian [
	"Compatibility with the ByteArray method of the same name."
	| lowBits wordIndex value word0 word1 |
	lowBits := byteIndex - 1 bitAnd: 3.
	wordIndex := byteIndex - 1 // 4 + 1.
	lowBits = 0
		ifTrue:
			[value := self at: wordIndex]
		ifFalse:
			[word0 := self at: wordIndex.
			 word1 := self at: wordIndex + 1.
			 value := 16rFFFFFFFF bitAnd: (word0 bitShift: lowBits * -8) + (word1 bitShift: 4 - lowBits * 8)].
	bigEndian ifTrue:
		[value := ((value bitShift: -24) bitAnd: 16rFF)
				 + ((value bitShift: -8) bitAnd: 16rFF00)
 				 + ((value bitAnd: 16rFF00) bitShift: 8)
				 + ((value bitAnd: 16rFF) bitShift: 24)].
	(16r80000000 bitAnd: value) ~= 0 ifTrue:
		[value := (16r7FFFFFFF bitAnd: value) - 16r80000000].
	^value

	"| bm ba |
	(bm := LittleEndianBitmap new: 4)
		at: 1 put: 16r01234567;
		at: 2 put: 16r89ABCDEF;
		at: 3 put: 16r89ABCDEF;
		at: 4 put: 16r01234567.
	ba := bm asByteArray.
	(((1 to: 5), (9 to: 13) select:
		[:bi| (bm longAt: bi bigEndian: true) ~= (ba longAt: bi bigEndian: true)]) collect:
			[:i| { i. (bm longAt: i bigEndian: true) hex. (ba longAt: i bigEndian: true) hex}]),
	(((1 to: 5), (9 to: 13) select:
		[:bi| (bm longAt: bi bigEndian: false) ~= (ba longAt: bi bigEndian: false)]) collect:
			[:i| { i. (bm longAt: i bigEndian: false) hex. (ba longAt: i bigEndian: false) hex}])"
]

{ #category : #accessing }
LittleEndianBitmap >> longAt: byteIndex put: aValue [
	"Compatibility with the ByteArray method of the same name."
	| lowBits wordIndex mask |
	lowBits := byteIndex - 1 bitAnd: 3.
	wordIndex := byteIndex - 1 // 4 + 1.
	aValue < 0
		ifTrue:
			[aValue < -2147483648 ifTrue:
				[^self errorImproperStore]]
		ifFalse:
			[16r7FFFFFFF < aValue ifTrue:
				[^self errorImproperStore]].
	lowBits = 0 ifTrue:
		[self at: wordIndex put: (16rFFFFFFFF bitAnd: aValue).
		 ^aValue].
	mask := 16rFFFFFFFF bitShift: 4 - lowBits * -8.
	self at: wordIndex put: (((self at: wordIndex) bitAnd: mask) bitXor: ((aValue bitShift: lowBits * 8) bitAnd: mask bitInvert32)).
	self at: wordIndex + 1 put: (((self at: wordIndex + 1) bitAnd: mask bitInvert32) bitXor: ((aValue bitShift: 4 - lowBits * -8) bitAnd: mask)).
	^aValue

	"(1 to: 8) collect:
		[:ba| | bm |
		bm := LittleEndianBitmap new: 4.
		bm at: 1 put: 16r55555555.
		bm at: 2 put: 16rAAAAAAAA.
		bm longAt: ba put: 16r04030201.
		{ (bm at: 1) hex. (bm at: 2) hex }]"
]

{ #category : #accessing }
LittleEndianBitmap >> longAt: byteIndex put: aValue bigEndian: bigEndian [
	"Compatibility with the ByteArray method of the same name."
	| lowBits wordIndex value mask |
	lowBits := byteIndex - 1 bitAnd: 3.
	wordIndex := byteIndex - 1 // 4 + 1.
	value := aValue < 0
				ifTrue: [16rFFFFFFFF bitAnd: aValue]
				ifFalse: [16rFFFFFFFF < aValue ifTrue:
							[self errorImproperStore].
						aValue].
	bigEndian ifTrue:
		[value := ((value bitShift: -24) bitAnd: 16rFF)
				 + ((value bitShift: -8) bitAnd: 16rFF00)
 				 + ((value bitAnd: 16rFF00) bitShift: 8)
				 + ((value bitAnd: 16rFF) bitShift: 24)].
	lowBits = 0 ifTrue:
		[self at: wordIndex put: value.
		 ^aValue].
	mask := 16rFFFFFFFF bitShift: lowBits * -8.
	self at: wordIndex put: (((self at: wordIndex) bitAnd: mask) bitXor: ((value bitShift: lowBits * 8) bitAnd: mask bitInvert32)).
	self at: wordIndex + 1 put: (((self at: wordIndex + 1) bitAnd: mask bitInvert32) bitXor: ((value bitShift: 4 - lowBits * -8) bitAnd: mask)).
	^aValue

	"(1 to: 8) collect:
		[:ba| | bm |
		bm := LittleEndianBitmap new: 4.
		bm at: 1 put: 16r55555555.
		bm at: 2 put: 16rAAAAAAAA.
		bm longAt: ba put: 16r04030201 bigEndian: false.
		{ (bm at: 1) hex. (bm at: 2) hex }]"

	"(1 to: 8) collect:
		[:ba| | bm |
		bm := LittleEndianBitmap new: 4.
		bm at: 1 put: 16r55555555.
		bm at: 2 put: 16rAAAAAAAA.
		bm longAt: ba put: 16r01020304 bigEndian: true.
		{ (bm at: 1) hex. (bm at: 2) hex }]"
]

{ #category : #accessing }
LittleEndianBitmap >> unsignedByteAt: byteAddress [
	"Extract a byte from a Bitmap (little-endian version)"
	| lowBits |
	lowBits := byteAddress - 1 bitAnd: 3.
	^((self at: byteAddress - 1 - lowBits // 4 + 1)
		bitShift: lowBits * -8)
		bitAnd: 16rFF
]

{ #category : #accessing }
LittleEndianBitmap >> unsignedByteAt: byteAddress put: byte [
	"Insert a byte into a Bitmap (little-endian version)"
	| longWord shift lowBits longAddr |
	(byte < 0 or:[byte > 255]) ifTrue:[^self errorImproperStore].
	lowBits := byteAddress - 1 bitAnd: 3.
	longWord := self at: (longAddr := (byteAddress - 1 - lowBits) // 4 + 1).
	shift := lowBits * 8.
	longWord := longWord
				- (longWord bitAnd: (16rFF bitShift: shift)) 
				+ (byte bitShift: shift).
	self at: longAddr put: longWord.
	^byte
]

{ #category : #accessing }
LittleEndianBitmap >> unsignedLong64At: byteAddress [
	"memory is a Bitmap, a 32-bit indexable array of bits"
	| lowBits hiWord loWord midWord mask wordIndex result |
	wordIndex := byteAddress - 1 // 4 + 1.
	(lowBits := byteAddress - 1 \\ 4) = 0 ifTrue:
		[loWord := self at: wordIndex.
		 hiWord := self at: wordIndex + 1.
		 ^hiWord = 0
			ifTrue: [loWord]
			ifFalse: [(hiWord bitShift: 32) + loWord]].
	"There will always be three accesses; two partial words and a full word in the middle"
	mask := 16rFFFFFFFF bitShift: 4 - lowBits * -8.
	loWord := (self at: wordIndex) bitAnd: mask bitInvert32.
	midWord := self at: wordIndex + 1.
	hiWord := (self at: wordIndex + 2) bitAnd: mask.
	result := loWord bitShift: lowBits * -8.
	midWord ~= 0 ifTrue:
		[result := result + (midWord bitShift: (4 - lowBits * 8))].
	hiWord ~= 0 ifTrue:
		[result := result + (hiWord bitShift: (4 - lowBits + 4 * 8))].
	^result
]

{ #category : #accessing }
LittleEndianBitmap >> unsignedLong64At: byteIndex put: aValue [
	| lowBits mask wordIndex |
	(lowBits := byteIndex - 1 \\ 4) = 0 ifTrue:
		[self "N.B. Do the access that can fail first, before altering the receiver"
			unsignedLongAt: byteIndex + 4 put: (aValue bitShift: -32);
			unsignedLongAt: byteIndex put: (aValue bitAnd: 16rffffffff).
		^aValue].
	"There will always be three accesses; two partial words and a full word in the middle"
	wordIndex := byteIndex - 1 // 4 + 1.
	(aValue bitShift: -64) ~= 0 ifTrue:
		[^self errorImproperStore].
	mask := 16rFFFFFFFF bitShift: 4 - lowBits * -8.
	self at: wordIndex put: (((self at: wordIndex) bitAnd: mask) bitXor: ((aValue bitShift: lowBits * 8) bitAnd: mask bitInvert32)).
	self at: wordIndex + 1 put: ((aValue bitShift: 4 - lowBits * -8) bitAnd: 16rFFFFFFFF).
	self at: wordIndex + 2 put: (((self at: wordIndex + 2) bitAnd: mask bitInvert32) bitXor: ((aValue bitShift: 4 - lowBits + 4 * -8) bitAnd: mask)).
	^aValue
]

{ #category : #accessing }
LittleEndianBitmap >> unsignedLongAt: byteIndex [
	"Compatiblity with the ByteArray & Alien methods of the same name."
	^(byteIndex - 1 bitAnd: 3) = 0
		ifTrue: [self at: byteIndex - 1 // 4 + 1]
		ifFalse: [self unsignedLongAt: byteIndex bigEndian: false]
]

{ #category : #accessing }
LittleEndianBitmap >> unsignedLongAt: byteIndex bigEndian: bigEndian [
	"Compatiblity with the ByteArray method of the same name."
	| lowBits wordIndex value word0 word1 |
	lowBits := byteIndex - 1 bitAnd: 3.
	wordIndex := byteIndex - 1 // 4 + 1.
	lowBits = 0
		ifTrue:
			[value := self at: wordIndex]
		ifFalse:
			[word0 := self at: wordIndex.
			 word1 := self at: wordIndex + 1.
			 value := 16rFFFFFFFF bitAnd: (word0 bitShift: lowBits * -8) + (word1 bitShift: 4 - lowBits * 8)].
	bigEndian ifTrue:
		[value := ((value bitShift: -24) bitAnd: 16rFF)
				 + ((value bitShift: -8) bitAnd: 16rFF00)
 				 + ((value bitAnd: 16rFF00) bitShift: 8)
				 + ((value bitAnd: 16rFF) bitShift: 24)].
	^value

	"| bm ba |
	(bm := LittleEndianBitmap new: 4)
		at: 1 put: 16r01234567;
		at: 2 put: 16r89ABCDEF;
		at: 3 put: 16r89ABCDEF;
		at: 4 put: 16r01234567.
	ba := bm asByteArray.
	(((1 to: 5), (9 to: 13) select:
		[:bi| (bm unsignedLongAt: bi bigEndian: true) ~= (ba unsignedLongAt: bi bigEndian: true)]) collect:
			[:i| { i. (bm unsignedLongAt: i bigEndian: true) hex. (ba unsignedLongAt: i bigEndian: true) hex}]),
	(((1 to: 5), (9 to: 13) select:
		[:bi| (bm unsignedLongAt: bi bigEndian: false) ~= (ba unsignedLongAt: bi bigEndian: false)]) collect:
			[:i| { i. (bm unsignedLongAt: i bigEndian: false) hex. (ba unsignedLongAt: i bigEndian: false) hex}])"
]

{ #category : #accessing }
LittleEndianBitmap >> unsignedLongAt: byteIndex put: aValue [
	"Compatiblity with the ByteArray & Alien methods of the same name."
	| lowBits mask wordIndex |
	wordIndex := byteIndex - 1 // 4 + 1.
	(lowBits := byteIndex - 1 bitAnd: 3) = 0 ifTrue:
		[^self at: wordIndex put: aValue].
	(aValue bitShift: -32) = 0 ifFalse:
		[^self errorImproperStore].
	mask := 16rFFFFFFFF bitShift: 4 - lowBits * -8.
	self at: wordIndex put: (((self at: wordIndex) bitAnd: mask) bitXor: ((aValue bitShift: lowBits * 8) bitAnd: mask bitInvert32)).
	self at: wordIndex + 1 put: (((self at: wordIndex + 1) bitAnd: mask bitInvert32) bitXor: (16rFFFFFFFF bitAnd: ((aValue bitShift: 4 - lowBits * -8) bitAnd: mask))).
	^aValue
]

{ #category : #accessing }
LittleEndianBitmap >> unsignedShortAt: byteIndex [
	"Compatiblity with the ByteArray & Alien methods of the same name."
	| zi |
	^((zi := byteIndex - 1) bitAnd: 1) = 0
		ifTrue: [(zi bitAnd: 2) = 0
					ifTrue: [(self at: zi // 4 + 1) bitAnd: 16rFFFF]
					ifFalse: [(self at: zi - 2 // 4 + 1) bitShift: -16]]
		ifFalse: [(self unsignedLongAt: byteIndex bigEndian: false) bitAnd: 16rFFFF]
]

{ #category : #accessing }
LittleEndianBitmap >> unsignedShortAt: byteIndex put: aValue [
	"Compatiblity with the ByteArray & Alien methods of the same name."
	| zi |
	(aValue < 0 or: [aValue > 16rFFFF])  ifTrue:
		[^self errorImproperStore].
	((zi := byteIndex - 1) bitAnd: 1) = 0
		ifTrue: [(zi bitAnd: 2) = 0
					ifTrue: [self at: (zi := zi // 4 + 1) put: (16rFFFF0000 bitAnd: (self at: zi)) + aValue]
					ifFalse: [self at: (zi := zi - 2 // 4 + 1) put: (16rFFFF bitAnd: (self at: zi)) + (aValue bitShift: 16)]]
		ifFalse: [self notYetImplemented].
	^aValue
]
