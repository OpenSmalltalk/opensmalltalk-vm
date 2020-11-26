Class {
	#name : #MemoryTests,
	#superclass : #TestCase,
	#category : #'VMMaker-OriginalTests'
}

{ #category : #'test support' }
MemoryTests >> deepStack: n [
	"Not tail recursive."
	^0 = n ifTrue: [0] ifFalse: [n + (self deepStack: n - 1) + n]
]

{ #category : #tests }
MemoryTests >> expectedFailures [
	"As yet we don't support Spur on any big endian platforms, let alone 64-bit ones."
	^#(testBitmap64BitLongs)
]

{ #category : #tests }
MemoryTests >> testBitmap32BitLongs [
	"Test that Bitmap provides big-endian access for 32-bit accessors"
	| memory |
	memory := Bitmap new: 64.
	0 to: 30 do:
		[:shift|
		#(-1 1) do:
			[:initial| | value |
			value := initial bitShift: shift.
			memory longAt: 1 put: value.
			self assert: value equals: (memory longAt: 1).
			memory
				longAt: 5 put: 16r00005555;
				longAt: 9 put: 16r55550000.
			self assert: 16r55555555 equals: (memory longAt: 7).
			memory longAt: 7 put: value.
			self assert: (memory longAt: 7) equals: value.
			self assert: (memory at: (shift <= 15 = (initial >= 0) ifTrue: [5] ifFalse: [9])) equals: 0]].
	31 to: 32 do:
		[:shift|
		self should: [memory longAt: 1 put: -1 << shift - 1] raise: Error.
		self should: [memory longAt: 1 put: 1 << shift] raise: Error].
	0 to: 31 do:
		[:shift| | value |
		value := 1 bitShift: shift.
		memory unsignedLongAt: 1 put: value.
		self assert: value equals: (memory unsignedLongAt: 1).
			memory
				longAt: 5 put: 16r00005555;
				longAt: 9 put: 16r55550000.
			self assert: 16r55555555 equals: (memory longAt: 7).
		memory unsignedLongAt: 7 put: value.
		self assert: value equals: (memory unsignedLongAt: 7).
		self assert: 0 equals: (memory at: (shift <= 15 ifTrue: [5] ifFalse: [9]))].
	self should: [memory unsignedLongAt: 1 put: -1] raise: Error.
	32 to: 33 do:
		[:shift|
		self should: [memory unsignedLongAt: 1 put: 1 << shift] raise: Error]
]

{ #category : #tests }
MemoryTests >> testBitmap64BitLongs [
	"Test that Bitmap provides big-endian access for 64-bit accessors"
	| memory |
	memory := Bitmap new: 64.
	0 to: 62 do:
		[:shift|
		#(-1 1) do:
			[:initial| | value |
			memory atAllPut: 0.
			value := initial bitShift: shift.
			memory long64At: 1 put: value.
			self assert: value equals: (memory long64At: 1).
			memory
				long64At: 10 put: 16r0000000000555555;
				long64At: 18 put: 16r5555555555000000.
			self assert: 16r5555555555555555 equals: (memory long64At: 15).
			"(1 to: 7) collect: [:i| (memory at: i) hex]"
			memory long64At: 13 put: value.
			self assert: value equals: (memory long64At: 13).
			self assert: 0 equals: (memory at: (shift <= 15 = (initial >= 0) ifTrue: [9] ifFalse: [17])).
			self assert: 0 equals: (memory at: (shift <= 15 = (initial >= 0) ifTrue: [13] ifFalse: [21]))]].
	63 to: 64 do:
		[:shift|
		self should: [memory long64At: 1 put: -1 << shift - 1] raise: Error.
		self should: [memory long64At: 1 put: 1 << shift] raise: Error].
	0 to: 63 do:
		[:shift| | value |
		value := 1 bitShift: shift.
		memory unsignedLong64At: 1 put: value.
		self assert: value equals: (memory unsignedLong64At: 1).
			memory
				unsignedLong64At: 10 put: 16r0000000000555555;
				unsignedLong64At: 18 put: 16r5555555555000000.
			self assert: 16r5555555555555555 equals: (memory unsignedLong64At: 15).
		memory unsignedLong64At: 7 put: value.
		self assert: value equals: (memory unsignedLong64At: 7).
		self assert: 0 equals: (memory at: (shift <= 31 ifTrue: [9] ifFalse: [17])).
		self assert: 0 equals: (memory at: (shift <= 31  ifTrue: [13] ifFalse: [21]))].
	self should: [memory unsignedLong64At: 1 put: -1] raise: Error.
	64 to: 65 do:
		[:shift|
		self should: [memory unsignedLong64At: 1 put: 1 << shift] raise: Error]
]

{ #category : #tests }
MemoryTests >> testByteArray16BitShorts [
	"Test that ByteArray provides little-endian access for 16-bit accessors"
	self testLittleEndianShortAccessFor: ByteArray
]

{ #category : #tests }
MemoryTests >> testByteArray32BitLongs [
	"Test that ByteArray provides big-endian access for 32-bit accessors"
	self testLittleEndian32BitLongAccessFor: ByteArray
]

{ #category : #tests }
MemoryTests >> testByteArray64BitLongs [
	"Test that ByteArray provides big-endian access for 64-bit accessors"
	self testLittleEndian64BitLongAccessFor: ByteArray
]

{ #category : #tests }
MemoryTests >> testDoubleWordArray16BitShorts [
	"Test that DoubleWordArray provides little-endian access for 16-bit accessors"
	self testLittleEndianShortAccessFor: DoubleWordArray
]

{ #category : #tests }
MemoryTests >> testDoubleWordArray32BitLongs [
	"Test that DoubleWordArray provides little-endian access for 32-bit accessors"
	self testLittleEndian32BitLongAccessFor: DoubleWordArray
]

{ #category : #tests }
MemoryTests >> testDoubleWordArray64BitLongs [
	"Test that DoubleWordArray provides little-endian access for 64-bit accessors"
	self testLittleEndian64BitLongAccessFor: DoubleWordArray
]

{ #category : #tests }
MemoryTests >> testFrameActivationLeak [
	"This test tests if a remarried context hides a reference to an object... Thanks to Ryan Macnak for the test."
	| array object |
	array := WeakArray new: 1.
	object := Object new.

	array at: 1 put: object.
	self assert: (array at: 1) == object.

	Smalltalk garbageCollect.

	self assert: (array at: 1) == object.
	
	"Trigger stack overflow, causing this frame to be flushed to an activation. When control returns here, a new frame will be created for the activation."
	self assert: (self deepStack: 4096) = 16781312.

	"Clears the temporary in the frame."
	object := nil.
	Smalltalk garbageCollect.

	"Check the activation is not retaining a copy of our cleared temporary."
	self assert: (array at: 1) == nil.
]

{ #category : #'test support' }
MemoryTests >> testLittleEndian32BitLongAccessFor: aClass [
	"Test that ByteArray provides big-endian access for 32-bit accessors"
	"memory copy changeClassTo: ByteArray"
	| memory |
	memory := aClass new: 64 / (aClass new: 0) bytesPerElement.
	"signed access"
	0 to: 30 do:
		[:shift|
		#(-1 1) do:
			[:initial| | value |
			value := initial bitShift: shift.
			memory longAt: 1 put: value.
			self assert: value equals: (memory longAt: 1).
			"aligned store"
			memory
				longAt: 5 put: 16r55550000;
				longAt: 9 put: 16r00005555.
			self assert: 16r55555555 equals: (memory longAt: 7).
			memory longAt: 7 put: value.
			self assert: value equals: (memory longAt: 7).
			"check bytes either side have not been changed"
			5 to: 6 do:
				[:i| self assert: 0 equals: (memory byteAt: i)].
			11 to: 15 do:
				[:i| self assert: 0 equals: (memory byteAt: i)].
			"unaligned store"
			memory
				longAt: 6 put: 16r55550000;
				longAt: 10 put: 16r00005555.
			self assert: 16r55555555 equals: (memory longAt: 8).
			memory longAt: 8 put: value.
			self assert: value equals: (memory longAt: 8).
			"check bytes either side have not been changed"
			5 to: 7 do:
				[:i| self assert: 0 equals: (memory byteAt: i)].
			12 to: 15 do:
				[:i| self assert: 0 equals: (memory byteAt: i)]]].
	memory
		unsignedLongAt: 49 put: 16rAAAAAAAA;
		unsignedLongAt: 53 put: 16rAAAAAAAA.
	49 to: 52 do:
		[:i|
		 self assert: -1431655766 equals: (memory longAt: i)].
	"unsigned access"
	0 to: 31 do:
		[:shift| | value |
		value := 1 bitShift: shift.
		memory unsignedLongAt: 1 put: value.
		self assert: value equals: (memory unsignedLongAt: 1).
		"aligned store"
		memory
			longAt: 5 put: 16r55550000;
			longAt: 9 put: 16r00005555.
		self assert: 16r55555555 equals: (memory unsignedLongAt: 7).
		memory unsignedLongAt: 7 put: value.
		self assert: value equals: (memory unsignedLongAt: 7).
		"check bytes either side have not been changed"
		5 to: 6 do:
			[:i| self assert: 0 equals: (memory byteAt: i)].
		11 to: 15 do:
			[:i| self assert: 0 equals: (memory byteAt: i)].
		"unaligned store"
		memory
			longAt: 6 put: 16r55550000;
			longAt: 10 put: 16r00005555.
		self assert: 16r55555555 equals: (memory unsignedLongAt: 8).
		memory unsignedLongAt: 8 put: value.
		self assert: value equals: (memory unsignedLongAt: 8).
		"check bytes either side have not been changed"
		5 to: 7 do:
			[:i| self assert: 0 equals: (memory byteAt: i)].
		12 to: 15 do:
			[:i| self assert: 0 equals: (memory byteAt: i)]]
]

{ #category : #'test support' }
MemoryTests >> testLittleEndian64BitLongAccessFor: aClass [
	"Test that the given class provides little-endian access for 64-bit accessors"
	"memory copy changeClassTo: ByteArray"
	| memory |
	memory := aClass new: 64 / (aClass new: 0) bytesPerElement.
	"signed access"
	0 to: 62 do:
		[:shift|
		#(-1 1) do:
			[:initial| | value |
			value := initial bitShift: shift.
			memory long64At: 1 put: value.
			self assert: value equals: (memory long64At: 1).
			"aligned store"
			memory
				long64At: 9 put: 16r5555550000000000;
				long64At: 17 put: 16r0000005555555555.
			self assert: 16r5555555555555555 equals: (memory long64At: 14).
			memory long64At: 14 put: value.
			self assert: value equals: (memory long64At: 14).
			"check bytes either side have not been changed"
			9 to: 13 do:
				[:i| self assert: 0 equals: (memory byteAt: i)].
			22 to: 31 do:
				[:i| self assert: 0 equals: (memory byteAt: i)].
			"unaligned store"
			memory
				long64At: 10 put: 16r5555550000000000;
				long64At: 18 put: 16r0000005555555555.
			self assert: 16r5555555555555555 equals: (memory long64At: 15).
			memory long64At: 15 put: value.
			self assert: value equals: (memory long64At: 15).
			"check bytes either side have not been changed"
			9 to: 14 do:
				[:i| self assert: 0 equals: (memory byteAt: i)].
			23 to: 31 do:
				[:i| self assert: 0 equals: (memory byteAt: i)]]].
	memory
		unsignedLong64At: 49 put: 16rAAAAAAAAAAAAAAAA;
		unsignedLong64At: 57 put: 16rAAAAAAAAAAAAAAAA.
	49 to: 56 do:
		[:i|
		 self assert: -6148914691236517206 equals: (memory long64At: i)].
	"unsigned access"
	0 to: 63 do:
		[:shift| | value |
		value := 1 bitShift: shift.
		memory unsignedLong64At: 1 put: value.
		self assert: value equals: (memory unsignedLong64At: 1).
		"aligned store"
		memory
			unsignedLong64At: 9 put: 16r5555550000000000;
			unsignedLong64At: 17 put: 16r0000005555555555.
		self assert: 16r5555555555555555 equals: (memory unsignedLong64At: 14).
		memory unsignedLong64At: 14 put: value.
		self assert: value equals: (memory unsignedLong64At: 14).
		"check bytes either side have not been changed"
		9 to: 13 do:
			[:i| self assert: 0 equals: (memory byteAt: i)].
		22 to: 31 do:
			[:i| self assert: 0 equals: (memory byteAt: i)].
		"unaligned store"
		memory
			unsignedLong64At: 10 put: 16r5555550000000000;
			unsignedLong64At: 18 put: 16r0000005555555555.
		self assert: 16r5555555555555555 equals: (memory unsignedLong64At: 15).
		memory unsignedLong64At: 15 put: value.
		self assert: value equals: (memory unsignedLong64At: 15).
		"check bytes either side have not been changed"
		9 to: 14 do:
			[:i| self assert: 0 equals: (memory byteAt: i)].
		23 to: 31 do:
			[:i| self assert: 0 equals: (memory byteAt: i)]]
]

{ #category : #tests }
MemoryTests >> testLittleEndianBitmap16BitShorts [
	"Test that LittleEndianBitmap provides little-endian access for 16-bit accessors"
	self testLittleEndianShortAccessFor: LittleEndianBitmap
]

{ #category : #tests }
MemoryTests >> testLittleEndianBitmap32BitLongs [
	"Test that LittleEndianBitmap provides little-endian access for 32-bit accessors"
	self testLittleEndian32BitLongAccessFor: LittleEndianBitmap
]

{ #category : #tests }
MemoryTests >> testLittleEndianBitmap64BitLongs [
	"Test that LittleEndianBitmap provides little-endian access for 64-bit accessors"
	self testLittleEndian64BitLongAccessFor: LittleEndianBitmap
]

{ #category : #'test support' }
MemoryTests >> testLittleEndianShortAccessFor: aClass [
	| memory |
	1 to: 9 by: 2 do:
		[:i|
		memory := aClass new: 64 / (aClass new: 0) bytesPerElement.
		memory unsignedShortAt: i put: 16r7FFF.
		1 to: i - 1 do:
			[:j| self assert: 0 equals: (memory byteAt: j)].
		self assert: 16rFF equals: (memory byteAt: i).
		self assert: 16r7F equals: (memory byteAt: i + 1).
		(i + 2 to: 8) do:
			[:j| self assert: 0 equals: (memory byteAt: j)]].

	16 to: 32 do:
		[:shift|
		self should: [memory unsignedShortAt: 1 put: -1 << shift - 1] raise: Error.
		self should: [memory unsignedShortAt: 1 put: 1 << shift] raise: Error].

]

{ #category : #tests }
MemoryTests >> testSignedOutOfRangeAccess [
	{ByteArray. Bitmap. LittleEndianBitmap. DoubleWordArray} do:
		[:class| | bytesPerElement memory |
		bytesPerElement := (class new: 0) bytesPerElement.
		memory := class new: 64 / bytesPerElement.
		1 to: 16 do:
			[:i|
			self should: [memory byteAt: i put: 1 << 8] raise: Error.
			self should: [memory byteAt: i put: -1 << 7 - 1] raise: Error.
			self should: [memory shortAt: i put: 1 << 16] raise: Error.
			self should: [memory shortAt: i put: -1 << 15 - 1] raise: Error.
			self should: [memory longAt: i put: 1 << 32] raise: Error.
			self should: [memory longAt: i put: -1 << 31 - 1] raise: Error.
			self should: [memory long64At: i put: 1 << 64] raise: Error.
			self should: [memory long64At: i put: -1 << 63 - 1] raise: Error].
		1 to: memory size do:
			[:i|
			self assert: 0 equals: (memory at: i)]]
]

{ #category : #tests }
MemoryTests >> testUnsignedOutOfRangeAccess [
	{ByteArray. Bitmap. LittleEndianBitmap. DoubleWordArray} do:
		[:class| | bytesPerElement memory |
		bytesPerElement := (class new: 0) bytesPerElement.
		memory := class new: 64 / bytesPerElement.
		1 to: 16 do:
			[:i|
			self should: [memory unsignedByteAt: i put: 1 << 8] raise: Error.
			self should: [memory unsignedByteAt: i put: -1] raise: Error.
			self should: [memory unsignedShortAt: i put: 1 << 16] raise: Error.
			self should: [memory unsignedShortAt: i put: -1] raise: Error.
			self should: [memory unsignedLongAt: i put: 1 << 32] raise: Error.
			self should: [memory unsignedLongAt: i put: -1] raise: Error.
			self should: [memory unsignedLong64At: i put: 1 << 64] raise: Error.
			self should: [memory unsignedLong64At: i put: -1] raise: Error].
		1 to: memory size do:
			[:i|
			self assert: 0 equals: (memory at: i)]]
]
