Class {
	#name : #MemoryTests,
	#superclass : #TestCase,
	#category : 'VMMaker-Tests'
}

{ #category : #debugger }
MemoryTests class >> defaultIntegerBaseInDebugger [
	^16
]

{ #category : #testing }
MemoryTests >> test64BitBitmapAccessViaByteArray [
	"MemoryTests new test64BitBitmapAccessViaByteArray"
	"(1 to: bits size) collect: [:i| (bits at: i) hex] #('16r23456700' '16rABCDEF01' '16r89' '16r0')"
	| bigPositive littlePositive bigNegative littleNegative |
	ByteArray adoptInstance: ((bigPositive := Bitmap new: 2)
									at: 1 put: 16r01234567;
									at: 2 put: 16r89ABCDEF;
									yourself).
	ByteArray adoptInstance: ((bigNegative := Bitmap new: 2)
									at: 1 put: 16rFEDCBA98;
									at: 2 put: 16r76543210;
									yourself).
	ByteArray adoptInstance: ((littlePositive := LittleEndianBitmap new: 2)
									at: 1 put: 16r89ABCDEF;
									at: 2 put: 16r01234567;
									yourself).
	ByteArray adoptInstance: ((littleNegative := LittleEndianBitmap new: 2)
									at: 1 put: 16r76543210;
									at: 2 put: 16rFEDCBA98;
									yourself).
	1 to: 8 do:
		[:i|
		(0 to: 7) do: [:j| | bytes bits | "In a true block so that one can restart"
			"BigEndian is just plain perverse, sigh..."
			i + j - 1 \\ 4 = 0 ifTrue:
				[(bytes := ByteArray new: 32)
					replaceFrom: i + j
					to: i + j + 7
					with: bigPositive
					startingAt: 1.
				Bitmap adoptInstance: (bits := bytes copy).
				self assert: 16r0123456789ABCDEF equals: (bits unsignedLong64At: i + j).
				self assert: 16r0123456789ABCDEF equals: (bits long64At: i + j).
				(bytes := ByteArray new: 32)
					replaceFrom: i + j
					to: i + j + 7
					with: bigNegative
					startingAt: 1.
				Bitmap adoptInstance: (bits := bytes copy).
				self assert: 16rFEDCBA9876543210 equals: (bits unsignedLong64At: i + j).
				self assert: (bits long64At: i + j) < 0.
				self assert: 16rFEDCBA9876543210 equals: ((bits long64At: i + j) bitAnd: 16rFFFFFFFFFFFFFFFF)].
			(bytes := ByteArray new: 32)
				replaceFrom: i + j
				to: i + j + 7
				with: littlePositive
				startingAt: 1.
			LittleEndianBitmap adoptInstance: (bits := bytes copy).
			self assert: 16r0123456789ABCDEF equals: (bits unsignedLong64At: i + j).
			self assert: 16r0123456789ABCDEF equals: (bits long64At: i + j).
			(bytes := ByteArray new: 32)
				replaceFrom: i + j
				to: i + j + 7
				with: littleNegative
				startingAt: 1.
			LittleEndianBitmap adoptInstance: (bits := bytes copy).
			self assert: 16rFEDCBA9876543210 equals: (bits unsignedLong64At: i + j).
			self assert: (bits long64At: i + j) < 0.
			self assert: 16rFEDCBA9876543210 equals: ((bits long64At: i + j) bitAnd: 16rFFFFFFFFFFFFFFFF)]]
]

{ #category : #testing }
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

{ #category : #testing }
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

{ #category : #testing }
MemoryTests >> testLittleEndianBitmap32BitLongs [
	"Test that LittleEndianBitmap provides little-endian access for 32-bit accessors"
	| memory |
	memory := LittleEndianBitmap new: 64.
	0 to: 30 do:
		[:shift|
		#(-1 1) do:
			[:initial| | value |
			value := initial bitShift: shift.
			memory longAt: 1 put: value.
			self assert: value equals: (memory longAt: 1).
			memory
				longAt: 5 put: 16r55550000;
				longAt: 9 put: 16r00005555.
			self assert: 16r55555555 equals: (memory longAt: 7).
			memory longAt: 7 put: value.
			self assert: value equals: (memory longAt: 7).
			self assert: 0 equals: (memory at: (shift <= 15 = (initial >= 0) ifTrue: [9] ifFalse: [5]))]].
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
				longAt: 5 put: 16r55550000;
				longAt: 9 put: 16r00005555.
		self assert: 16r55555555 equals: (memory unsignedLongAt: 7).
		memory unsignedLongAt: 7 put: value.
		self assert: value equals: (memory unsignedLongAt: 7).
		self assert: 0 equals: (memory at: (shift <= 15 ifTrue: [9] ifFalse: [5]))].
	self should: [memory unsignedLongAt: 1 put: -1] raise: Error.
	32 to: 33 do:
		[:shift|
		self should: [memory unsignedLongAt: 1 put: 1 << shift] raise: Error]
]

{ #category : #testing }
MemoryTests >> testLittleEndianBitmap64BitLongs [
	"Test that Bitmap provides little-endian access for 64-bit accessors"
	| memory |
	memory := LittleEndianBitmap new: 64.
	0 to: 62 do:
		[:shift|
		#(-1 1) do:
			[:initial| | value |
			value := initial bitShift: shift.
			memory long64At: 1 put: value.
			self assert: value equals: (memory long64At: 1).
			memory
				long64At: 10 put: 16r5555550000000000;
				long64At: 18 put: 16r0000005555555555.
			self assert: 16r5555555555555555 equals: (memory long64At: 15).
			"(1 to: 6) collect: [:i| (memory at: i) hex]"
			memory long64At: 13 put: value.
			self assert: value equals: (memory long64At: 13).
			self assert: 0 equals: (memory at: (shift <= 15 = (initial >= 0) ifTrue: [17] ifFalse: [13])).
			self assert: 0 equals: (memory at: (shift <= 15 = (initial >= 0) ifTrue: [21] ifFalse: [13]))]].
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
				unsignedLong64At: 10 put: 16r5555550000000000;
				unsignedLong64At: 18 put: 16r0000005555555555.
			self assert: 16r5555555555555555 equals: (memory unsignedLong64At: 15).
		memory unsignedLong64At: 7 put: value.
		self assert: value equals: (memory unsignedLong64At: 7).
		self assert: 0 equals: (memory at: (shift <= 31 ifTrue: [17] ifFalse: [9])).
		self assert: 0 equals: (memory at: (shift <= 31  ifTrue: [21] ifFalse: [13]))].
	self should: [memory unsignedLong64At: 1 put: -1] raise: Error.
	64 to: 65 do:
		[:shift|
		self should: [memory unsignedLong64At: 1 put: 1 << shift] raise: Error]
]
