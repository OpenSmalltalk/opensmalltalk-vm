Extension { #name : #Bitmap }

{ #category : #'*VMMaker-interpreter simulator' }
Bitmap >> coerceTo: cTypeString sim: interpreter [

	^ self
]

{ #category : #'*VMMaker-JITSimulation' }
Bitmap >> long64At: byteAddress [
	| lowBits hiWord loWord midWord mask wordIndex result signBit |
	wordIndex := byteAddress - 1 // 4 + 1.
	(lowBits := byteAddress - 1 \\ 4) = 0 ifTrue:
		[hiWord := self at: wordIndex.
		 loWord := self at: wordIndex + 1.
		 ^hiWord = 0
			ifTrue: [loWord]
			ifFalse: [(hiWord signedIntFromLong bitShift: 32) + loWord]].
	"There will always be three accesses; two partial words and a full word in the middle"
	mask := 16rFFFFFFFF bitShift: 4 - lowBits * -8.
	hiWord := (self at: wordIndex) bitAnd: mask.
	midWord := self at: wordIndex + 1.
	loWord := (self at: wordIndex + 2) bitAnd: mask bitInvert32.
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

{ #category : #'*VMMaker-JITSimulation' }
Bitmap >> long64At: byteIndex put: aValue [
	| lowBits mask wordIndex |
	(lowBits := byteIndex - 1 \\ 4) = 0 ifTrue:
		[self "N.B. Do the access that can fail first, before altering the receiver"
			longAt: byteIndex put: (aValue bitShift: -32);
			unsignedLongAt: byteIndex + 4 put: (aValue bitAnd: 16rffffffff).
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
	mask := 16rFFFFFFFF bitShift: lowBits * -8.
	self at: wordIndex + 2 put: (((self at: wordIndex + 2) bitAnd: mask) bitXor: ((aValue bitShift: lowBits * 8) bitAnd: mask bitInvert32)).
	self at: wordIndex + 1 put: ((aValue bitShift: lowBits * -8) bitAnd: 16rFFFFFFFF).
	self at: wordIndex put: (((self at: wordIndex) bitAnd: mask bitInvert32) bitXor: ((aValue bitShift: 4 - lowBits + 4 * -8) bitAnd: mask)).
	"(wordIndex to: wordIndex + 2) collect: [:i| (self at: i) hex]"
	^aValue
]

{ #category : #'*VMMaker-JITSimulation' }
Bitmap >> longAt: byteIndex [
	"Default bigEndian access"
	| lowBits wordIndex value word0 word1 |
	lowBits := byteIndex - 1 bitAnd: 3.
	wordIndex := byteIndex - 1 // 4 + 1.
	lowBits = 0
		ifTrue:
			[value := self at: wordIndex]
		ifFalse:
			[word0 := self at: wordIndex.
			 word1 := self at: wordIndex + 1.
			 value := 16rFFFFFFFF bitAnd: (word0 bitShift: (lowBits * 8)) + (word1 bitShift: 0 - (4 - lowBits * 8))].
	(16r80000000 bitAnd: value) ~= 0 ifTrue:
		[value := (16r7FFFFFFF bitAnd: value) - 16r80000000].
	^value
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
			 value := 16rFFFFFFFF bitAnd: (word0 bitShift: (lowBits * 8)) + (word1 bitShift: 4 - lowBits * -8)].
	bigEndian ifFalse:
		[value := ((value bitShift: -24) bitAnd: 16rFF)
				 + ((value bitShift: -8) bitAnd: 16rFF00)
 				 + ((value bitAnd: 16rFF00) bitShift: 8)
				 + ((value bitAnd: 16rFF) bitShift: 24)].
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
Bitmap >> longAt: byteIndex put: aValue [
	"Default bigEndian access"
	| lowBits wordIndex value mask |
	wordIndex := byteIndex - 1 // 4 + 1.
	aValue < 0
		ifTrue:
			[aValue < -2147483648 ifTrue:
				[^self errorImproperStore].
			 value := 16rFFFFFFFF bitAnd: aValue]
		ifFalse:
			[16r7FFFFFFF < aValue ifTrue:
				[^self errorImproperStore].
			value := aValue].
	(lowBits := byteIndex - 1 bitAnd: 3) = 0 ifTrue:
		[self at: wordIndex put: value.
		 ^aValue].
	mask := 16rFFFFFFFF bitShift: lowBits * -8.
	self at: wordIndex put: (((self at: wordIndex) bitAnd: mask bitInvert) bitXor: ((value bitShift: lowBits * -8) bitAnd: mask)).
	self at: wordIndex + 1 put: (((self at: wordIndex + 1) bitAnd: mask) bitXor: (16rFFFFFFFF bitAnd: ((value bitShift: (4 - lowBits * 8)) bitAnd: mask bitInvert))).
	^aValue
]

{ #category : #'*VMMaker-JITSimulation' }
Bitmap >> longAt: byteIndex put: aValue bigEndian: bigEndian [
	"Compatibility with the ByteArray method of the same name."
	| lowBits wordIndex value mask |
	lowBits := byteIndex - 1 bitAnd: 3.
	wordIndex := byteIndex - 1 // 4 + 1.
	aValue < 0
		ifTrue:
			[value := 16rFFFFFFFF bitAnd: aValue.
			 value = 0 ifTrue:
				[self errorImproperStore]]
		ifFalse:
			[16rFFFFFFFF < aValue ifTrue:
				[self errorImproperStore].
			value := aValue].
	bigEndian ifFalse:
		[value := ((value bitShift: -24) bitAnd: 16rFF)
				 + ((value bitShift: -8) bitAnd: 16rFF00)
 				 + ((value bitAnd: 16rFF00) bitShift: 8)
				 + ((value bitAnd: 16rFF) bitShift: 24)].
	lowBits = 0 ifTrue:
		[self at: wordIndex put: value.
		 ^aValue].
	mask := 16rFFFFFFFF bitShift: lowBits * -8.
	self at: wordIndex put: (((self at: wordIndex) bitAnd: mask bitInvert) bitXor: ((value bitShift: lowBits * -8) bitAnd: mask)).
	self at: wordIndex + 1 put: (((self at: wordIndex + 1) bitAnd: mask) bitXor: (16rFFFFFFFF bitAnd: ((value bitShift: 4 - lowBits * 8) bitAnd: mask bitInvert))).
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
Bitmap >> unsignedLong64At: byteAddress [
	"memory is a Bitmap, a 32-bit indexable array of bits"
	| lowBits hiWord loWord midWord mask wordIndex result |
	wordIndex := byteAddress - 1 // 4 + 1.
	(lowBits := byteAddress - 1 \\ 4) = 0 ifTrue:
		[hiWord := self at: wordIndex.
		 loWord := self at: wordIndex + 1.
		 ^hiWord = 0
			ifTrue: [loWord]
			ifFalse: [(hiWord bitShift: 32) + loWord]].
	"There will always be three accesses; two partial words and a full word in the middle"
	mask := 16rFFFFFFFF bitShift: (4 - lowBits) * -8.
	hiWord := (self at: wordIndex) bitAnd: mask.
	midWord := self at: wordIndex + 1.
	loWord := (self at: wordIndex + 2) bitAnd: mask bitInvert32.
	result := loWord bitShift: lowBits * -8.
	midWord ~= 0 ifTrue:
		[result := result + (midWord bitShift: (4 - lowBits * 8))].
	hiWord ~= 0 ifTrue:
		[result := result + (hiWord bitShift: (4 - lowBits + 4 * 8))].
	^result
]

{ #category : #'*VMMaker-JITSimulation' }
Bitmap >> unsignedLong64At: byteIndex put: aValue [
	| lowBits mask wordIndex |
	(lowBits := byteIndex - 1 \\ 4) = 0 ifTrue:
		[self "N.B. Do the access that can fail first, before altering the receiver"
			unsignedLongAt: byteIndex put: (aValue bitShift: -32);
			unsignedLongAt: byteIndex + 4 put: (aValue bitAnd: 16rffffffff).
		^aValue].
	"There will always be three accesses; two partial words and a full word in the middle"
	wordIndex := byteIndex - 1 // 4 + 1.
	(aValue bitShift: -64) ~= 0 ifTrue:
		[^self errorImproperStore].
	mask := 16rFFFFFFFF bitShift: 4 - lowBits * -8.
	self at: wordIndex + 2 put: (((self at: wordIndex + 2) bitAnd: mask) bitXor: ((aValue bitShift: lowBits * 8) bitAnd: mask bitInvert32)).
	self at: wordIndex + 1 put: ((aValue bitShift: lowBits * -8) bitAnd: 16rFFFFFFFF).
	self at: wordIndex put: (((self at: wordIndex) bitAnd: mask bitInvert32) bitXor: ((aValue bitShift: 4 - lowBits + 4 * -8) bitAnd: mask)).
	"(wordIndex to: wordIndex + 2) collect: [:i| (self at: i) hex]"
	^aValue
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
			 value := 16rFFFFFFFF bitAnd: (word0 bitShift: lowBits * 8) + (word1 bitShift: 4 - lowBits * -8)].
	bigEndian ifFalse:
		[value := ((value bitShift: -24) bitAnd: 16rFF)
				 + ((value bitShift: -8) bitAnd: 16rFF00)
 				 + ((value bitAnd: 16rFF00) bitShift: 8)
				 + ((value bitAnd: 16rFF) bitShift: 24)].
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
	| lowBits mask wordIndex |
	wordIndex := byteIndex - 1 // 4 + 1.
	(lowBits := byteIndex - 1 bitAnd: 3) = 0 ifTrue:
		[^self at: wordIndex put: aValue].
	mask := 16rFFFFFFFF bitShift: lowBits * -8.
	(aValue bitShift: -32) = 0 ifFalse:
		[^self errorImproperStore].
	self at: wordIndex put: (((self at: wordIndex) bitAnd: mask bitInvert) bitXor: ((aValue bitShift: lowBits * -8) bitAnd: mask)).
	self at: wordIndex + 1 put: (((self at: wordIndex + 1) bitAnd: mask) bitXor: (16rFFFFFFFF bitAnd: ((aValue bitShift: (4 - lowBits * 8)) bitAnd: mask bitInvert))).
	^aValue
]
