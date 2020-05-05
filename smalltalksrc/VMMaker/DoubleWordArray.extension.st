Extension { #name : #DoubleWordArray }

{ #category : #'*VMMaker-JITSimulation' }
DoubleWordArray >> byteAt: byteAddress [
	"Extract a byte from a DoubleWordArray (little-endian version)"
	| lowBits |
	lowBits := byteAddress - 1 bitAnd: 7.
	^((self at: byteAddress - 1 - lowBits // 8 + 1)
		bitShift: lowBits * -8)
		bitAnd: 16rFF
]

{ #category : #'*VMMaker-debugger' }
DoubleWordArray class >> defaultIntegerBaseInDebugger [
	^16
]

{ #category : #'*VMMaker-JITSimulation' }
DoubleWordArray >> long64At: byteIndex [
	| lowBits wordIndex value high low |

	wordIndex := byteIndex - 1 // 8 + 1.
	(lowBits := byteIndex - 1 \\ 8) = 0
		ifTrue:
			[value := self at: wordIndex]
		ifFalse:
			[high := ((self at: wordIndex + 1) bitAnd: (1 bitShift: (lowBits bitShift: 3)) - 1) bitShift: ((8 - lowBits) bitShift: 3).
			 low := (self at: wordIndex) bitShift: lowBits * -8.
			 high = 0 ifTrue:
				[^low].
			 value := high + low].
	 ^(value bitShift: -56) <= 127
		ifTrue: [value]
		ifFalse: [value - 16r10000000000000000]
]

{ #category : #'*VMMaker-JITSimulation' }
DoubleWordArray >> long64At: byteIndex put: aValue [
	"Compatiblity with the ByteArray & Alien methods of the same name."
	| wordIndex lowBits mask allOnes |
	wordIndex := byteIndex - 1 // 8 + 1.
	((aValue bitShift: -63) between: -1 and: 0) ifFalse:
		[self errorImproperStore].
	allOnes := 16rFFFFFFFFFFFFFFFF.
	(lowBits := byteIndex - 1 bitAnd: 7) = 0 ifTrue:
		[^self at: wordIndex put: (aValue >= 0 ifTrue: [aValue] ifFalse: [aValue bitAnd: allOnes])].
	mask := allOnes bitShift: ((lowBits-8) bitShift:3).
	self at: wordIndex put: (((self at: wordIndex) bitAnd: mask) bitXor: ((aValue bitShift: lowBits * 8) bitAnd: allOnes - mask)).
	self at: wordIndex + 1 put: (((self at: wordIndex + 1) bitAnd: allOnes - mask) bitXor: (allOnes bitAnd: ((aValue bitShift: ((lowBits-8) bitShift:3)) bitAnd: mask))).
	^aValue
]

{ #category : #'*VMMaker-JITSimulation' }
DoubleWordArray >> longAt: byteIndex [
	"Compatiblity with the ByteArray & Alien methods of the same name."
	| wordIndex lowBits word hiWord |
	wordIndex := byteIndex - 1 // 8 + 1.
	lowBits := byteIndex - 1 bitAnd: 7.
	word := (self at: wordIndex) bitShift: lowBits * -8.
	lowBits > 4 ifTrue: "access straddles two words"
		[hiWord := (self at: wordIndex + 1) bitShift: 8 - lowBits * 8.
		 word := word + hiWord].
	word := word bitAnd: 16rFFFFFFFF.
	(word bitShift: -24) > 127 ifTrue:
		[word := word - 16r100000000].
	^word
]

{ #category : #'*VMMaker-JITSimulation' }
DoubleWordArray >> longAt: byteIndex bigEndian: bigEndian [
	"Compatiblity with the ByteArray & Alien methods of the same name."
	| wordIndex lowBits word hiWord |
	wordIndex := byteIndex - 1 // 8 + 1.
	lowBits := byteIndex - 1 bitAnd: 7.
	word := (self at: wordIndex) bitShift: lowBits * -8.
	lowBits > 4 ifTrue: "access straddles two words"
		[hiWord := (self at: wordIndex + 1) bitShift: 8 - lowBits * 8.
		 word := word + hiWord].
	word := word bitAnd: 16rFFFFFFFF.
	bigEndian ifTrue:
		[word := ((word bitShift: -24) bitAnd: 16rFF)
				 + ((word bitShift: -8) bitAnd: 16rFF00)
 				 + ((word bitAnd: 16rFF00) bitShift: 8)
				 + ((word bitAnd: 16rFF) bitShift: 24)].
	(word bitShift: -24) > 127 ifTrue:
		[word := word - 16r100000000].
	^word
]

{ #category : #'*VMMaker-JITSimulation' }
DoubleWordArray >> longAt: byteIndex put: aValue [
	"Compatiblity with the ByteArray & Alien methods of the same name."
	| wordIndex lowBits word allOnes loMask hiMask |
	wordIndex := byteIndex - 1 // 8 + 1.
	lowBits := byteIndex - 1 bitAnd: 7.
	((aValue bitShift: -31) between: -1 and: 0) ifFalse:
		[self errorImproperStore].
	lowBits <= 4 ifTrue: "access fits in a single word"
		[| mask |
		 mask := 16rFFFFFFFF bitShift: lowBits * 8.
		 word := self at: wordIndex.
		 self at: wordIndex put: ((word bitOr: mask) bitXor: (((aValue bitShift: lowBits * 8) bitAnd: mask) bitXor: mask)).
		 ^aValue].
	"access straddles two words; make lowMask ones where destination is unchanged to avoid overflow"
	allOnes := 16rFFFFFFFFFFFFFFFF.
	loMask := allOnes bitShift: 8 - lowBits * -8.
	hiMask := 16rFFFFFFFF bitShift: 8 - lowBits * -8.
	word := self at: wordIndex.
	self at: wordIndex put: ((word bitAnd: loMask) bitOr: ((aValue bitAnd: (16rFFFFFFFF bitShift: (lowBits bitAnd: 3) * -8)) bitShift: lowBits * 8)).
	word := self at: wordIndex + 1.
	self at: wordIndex + 1 put: ((word bitOr: hiMask) bitXor: ((((aValue bitShift: 4 - (lowBits bitAnd: 3) * -8)) bitAnd: hiMask) bitXor: hiMask)).
	^aValue
]

{ #category : #'*VMMaker-JITSimulation' }
DoubleWordArray >> unsignedByteAt: byteAddress [
	"Extract a byte from a 64-bit word array (little-endian version)"
	| lowBits |
	lowBits := byteAddress - 1 bitAnd: 7.
	^((self at: byteAddress - 1 - lowBits // 8 + 1)
		bitShift: lowBits * -8)
		bitAnd: 16rFF
]

{ #category : #'*VMMaker-JITSimulation' }
DoubleWordArray >> unsignedByteAt: byteAddress put: byte [
	"Insert a byte into a 64-bit word (little-endian version)"
	| longWord shift lowBits longAddr |
	(byte < 0 or: [byte > 255]) ifTrue:[^self errorImproperStore].
	lowBits := byteAddress - 1 bitAnd: 7.
	longWord := self at: (longAddr := (byteAddress - 1 - lowBits) // 8 + 1).
	shift := lowBits * 8.
	longWord := longWord
				- (longWord bitAnd: (16rFF bitShift: shift)) 
				+ (byte bitShift: shift).
	self at: longAddr put: longWord.
	^byte
]

{ #category : #'*VMMaker-JITSimulation' }
DoubleWordArray >> unsignedLong64At: byteIndex [
	"Compatiblity with the ByteArray & Alien methods of the same name."
	| wordIndex lowBits high low |
	wordIndex := byteIndex - 1 // 8 + 1.
	(lowBits := byteIndex - 1 bitAnd: 7) = 0 ifTrue:
		[^self at: wordIndex].
	high := ((self at: wordIndex + 1) bitAnd: (1 bitShift: lowBits * 8) - 1) bitShift: 8 - lowBits * 8.
	low := (self at: wordIndex) bitShift: lowBits * -8.
	^high = 0 ifTrue: [low] ifFalse: [high + low]
]

{ #category : #'*VMMaker-JITSimulation' }
DoubleWordArray >> unsignedLong64At: byteIndex put: aValue [
	"Compatiblity with the ByteArray & Alien methods of the same name."
	| wordIndex lowBits mask allOnes |
	wordIndex := byteIndex - 1 // 8 + 1.
	(lowBits := byteIndex - 1 bitAnd: 7) = 0 ifTrue:
		[^self at: wordIndex put: aValue].
	(aValue bitShift: -64) = 0 ifFalse:
		[self errorImproperStore].
	mask := (allOnes := 16rFFFFFFFFFFFFFFFF) bitShift: 8 - lowBits * -8.
	self at: wordIndex put: (((self at: wordIndex) bitAnd: mask) bitXor: ((aValue bitShift: lowBits * 8) bitAnd: allOnes - mask)).
	self at: wordIndex + 1 put: (((self at: wordIndex + 1) bitAnd: allOnes - mask) bitXor: (allOnes bitAnd: ((aValue bitShift: 8 - lowBits * -8) bitAnd: mask))).
	^aValue
]

{ #category : #'*VMMaker-JITSimulation' }
DoubleWordArray >> unsignedLongAt: byteIndex [
	"Compatiblity with the ByteArray & Alien methods of the same name."
	| wordIndex lowBits word hiWord |
	wordIndex := byteIndex - 1 // 8 + 1.
	lowBits := byteIndex - 1 bitAnd: 7.
	word := (self at: wordIndex) bitShift: lowBits * -8.
	lowBits > 4 ifTrue: "access straddles two words"
		[hiWord := (self at: wordIndex + 1) bitShift: 8 - lowBits * 8.
		 word := word + hiWord].
	^word bitAnd: 16rFFFFFFFF
]

{ #category : #'*VMMaker-JITSimulation' }
DoubleWordArray >> unsignedLongAt: byteIndex put: aValue [
	"Compatiblity with the ByteArray & Alien methods of the same name."
	| wordIndex lowBits word allOnes loMask hiMask |
	wordIndex := byteIndex - 1 // 8 + 1.
	lowBits := byteIndex - 1 bitAnd: 7.
	(aValue bitShift: -32) ~= 0 ifTrue:
		[self errorImproperStore].
	lowBits <= 4 ifTrue: "access fits in a single word"
		[| mask |
		 mask := 16rFFFFFFFF bitShift: lowBits * 8.
		 word := self at: wordIndex.
		 self at: wordIndex put: ((word bitOr: mask) bitXor: (((aValue bitShift: lowBits * 8) bitAnd: mask) bitXor: mask)).
		 ^aValue].
	"access straddles two words; make lowMask ones where destination is unchanged to avoid overflow"
	allOnes := 16rFFFFFFFFFFFFFFFF.
	loMask := allOnes bitShift: 8 - lowBits * -8.
	hiMask := 16rFFFFFFFF bitShift: 8 - lowBits * -8.
	word := self at: wordIndex.
	self at: wordIndex put: ((word bitAnd: loMask) bitOr: ((aValue bitAnd: (16rFFFFFFFF bitShift: (lowBits bitAnd: 3) * -8)) bitShift: lowBits * 8)).
	word := self at: wordIndex + 1.
	self at: wordIndex + 1 put: ((word bitOr: hiMask) bitXor: ((((aValue bitShift: 4 - (lowBits bitAnd: 3) * -8)) bitAnd: hiMask) bitXor: hiMask)).
	^aValue
]

{ #category : #'*VMMaker-JITSimulation' }
DoubleWordArray >> unsignedShortAt: byteIndex [
	"Compatiblity with the ByteArray & Alien methods of the same name."
	| zi word |
	zi := byteIndex - 1.
	word := self at: zi // 8 + 1.
	(zi bitAnd: 1) ~= 0 ifTrue:
		[self notYetImplemented]. "i.e. odd access implies implementing straddling two words"
	(zi bitAnd: 7) ~= 0 ifTrue:
		[word := word bitShift: (zi bitAnd: 7) * -8].
	^word bitAnd: 16rFFFF
]

{ #category : #'*VMMaker-JITSimulation' }
DoubleWordArray >> unsignedShortAt: byteAddress put: short [
	"Insert a double byte into a 64-bit word (little-endian version)"
	| longWord shift lowBits longAddr |
	(short < 0 or: [short > 65535]) ifTrue:[^self errorImproperStore].
	lowBits := byteAddress - 1 bitAnd: 7.
	(lowBits bitAnd: 1) ~= 0 ifTrue:
		[self notYetImplemented]. "i.e. odd access implies implementing straddling two words"
	longWord := self at: (longAddr := (byteAddress - 1 - lowBits) // 8 + 1).
	shift := lowBits * 8.
	longWord := longWord
				- (longWord bitAnd: (16rFFFF bitShift: shift)) 
				+ (short bitShift: shift).
	self at: longAddr put: longWord.
	^short
]
