Extension { #name : #Bitmap }

{ #category : #'*VMMaker-interpreter simulator' }
Bitmap >> coerceTo: cTypeString sim: interpreter [

	^ self
]

{ #category : #'*VMMaker-JITSimulation' }
Bitmap >> longAt: byteIndex bigEndian: bigEndian [
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
			 value := 16rFFFFFFFF bitAnd: word0 << (lowBits * 8) + (word1 >> (4 - lowBits * 8))].
	bigEndian ifFalse:
		[value := (value >> 24 bitAnd: 16rFF)
				 + (value >> 8 bitAnd: 16rFF00)
 				 + ((value bitAnd: 16rFF00) << 8)
				 + ((value bitAnd: 16rFF) << 24)].
	(16r80000000 bitAnd: value) ~= 0 ifTrue:
		[value := (16r7FFFFFFF bitAnd: value) - 16r80000000].
	^value

	"| bm ba |
	(bm := Bitmap new: 4)
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

{ #category : #'*VMMaker-JITSimulation' }
Bitmap >> longAt: byteIndex put: aValue bigEndian: bigEndian [
	"Compatibility with the ByteArray method of the same name."
	| lowBits wordIndex value mask |
	lowBits := byteIndex - 1 bitAnd: 3.
	wordIndex := byteIndex - 1 // 4 + 1.
	value := aValue < 0
				ifTrue: [16rFFFFFFFF bitAnd: value]
				ifFalse: [16rFFFFFFFF < aValue ifTrue:
							[self errorImproperStore].
						aValue].
	bigEndian ifFalse:
		[value := (value >> 24 bitAnd: 16rFF)
				 + (value >> 8 bitAnd: 16rFF00)
 				 + ((value bitAnd: 16rFF00) << 8)
				 + ((value bitAnd: 16rFF) << 24)].
	lowBits = 0 ifTrue:
		[self at: wordIndex put: value.
		 ^aValue].
	mask := 16rFFFFFFFF bitAnd: 16rFFFFFFFF >> (lowBits * 8).
	self at: wordIndex put: (((self at: wordIndex) bitAnd: mask bitInvert) bitXor: (value >> (lowBits * 8) bitAnd: mask)).
	self at: wordIndex + 1 put: (((self at: wordIndex + 1) bitAnd: mask) bitXor: (16rFFFFFFFF bitAnd: (value << (4 - lowBits * 8) bitAnd: mask bitInvert))).
	^aValue

	"(1 to: 8) collect:
		[:ba| | bm |
		bm := Bitmap new: 4.
		bm at: 1 put: 16r55555555.
		bm at: 2 put: 16rAAAAAAAA.
		bm longAt: ba put: 16r04030201 bigEndian: true.
		{ (bm at: 1) hex. (bm at: 2) hex }]"

	"(1 to: 8) collect:
		[:ba| | bm |
		bm := Bitmap new: 4.
		bm at: 1 put: 16r55555555.
		bm at: 2 put: 16rAAAAAAAA.
		bm longAt: ba put: 16r01020304 bigEndian: false.
		{ (bm at: 1) hex. (bm at: 2) hex }]"
]

{ #category : #'*VMMaker-JITSimulation' }
Bitmap >> unsignedByteAt: byteAddress [
	"Compatibility with the ByteArray and Alien methods of the same name."
	| lowBits |
	lowBits := byteAddress - 1 bitAnd: 3.
	^((self at: byteAddress - 1 - lowBits // 4 + 1)
		bitShift: (lowBits - 3) * 8)
		bitAnd: 16rFF
]

{ #category : #'*VMMaker-JITSimulation' }
Bitmap >> unsignedByteAt: byteAddress put: byte [
	"Compatibility with the ByteArray and Alien methods of the same name."
	| longWord shift lowBits longAddr |
	(byte < 0 or:[byte > 255]) ifTrue:[^self errorImproperStore].
	lowBits := byteAddress - 1 bitAnd: 3.
	longWord := self at: (longAddr := (byteAddress - 1 - lowBits) // 4 + 1).
	shift := (3 - lowBits) * 8.
	longWord := longWord - (longWord bitAnd: (16rFF bitShift: shift)) 
		+ (byte bitShift: shift).
	self at: longAddr put: longWord.
	^ byte
]

{ #category : #'*VMMaker-JITSimulation' }
Bitmap >> unsignedLongAt: byteIndex [
	"Compatiblity with the ByteArray & Alien methods of the same name."
	^(byteIndex - 1 bitAnd: 3) = 0
		ifTrue: [self at: byteIndex - 1 // 4 + 1]
		ifFalse: [self unsignedLongAt: byteIndex bigEndian: true]
]

{ #category : #'*VMMaker-JITSimulation' }
Bitmap >> unsignedLongAt: byteIndex bigEndian: bigEndian [
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
			 value := 16rFFFFFFFF bitAnd: word0 << (lowBits * 8) + (word1 >> (4 - lowBits * 8))].
	bigEndian ifFalse:
		[value := (value >> 24 bitAnd: 16rFF)
				 + (value >> 8 bitAnd: 16rFF00)
 				 + ((value bitAnd: 16rFF00) << 8)
				 + ((value bitAnd: 16rFF) << 24)].
	^value

	"| bm ba |
	(bm := Bitmap new: 4)
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

{ #category : #'*VMMaker-JITSimulation' }
Bitmap >> unsignedLongAt: byteIndex put: aValue [
	"Compatiblity with the ByteArray & Alien methods of the same name."
	^(byteIndex - 1 bitAnd: 3) = 0
		ifTrue: [self at: byteIndex - 1 // 4 + 1 put: aValue]
		ifFalse: [self notYetImplemented]
]
