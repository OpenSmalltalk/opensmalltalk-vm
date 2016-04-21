"
A CogCheckHeapMap is a simulation of the code in platforms/Cross/vm/sqHeapMap.c.  This is a map for leak checking that allocates 1 bit for every 4 bytes of address space.  It uses an array of pages to keep space overhead low, only allocating a page if that portion of the address space is used.  So the maximum overhead is address space size / (word size * bits per byte), or (2 raisedTo: 32) / (4 * 8) or 134,217,728 bytes.

Instance Variables
	pages:		<Array of: ByteArray>

pages
	- array of pages of bits, 1 bit per word of address space

"
Class {
	#name : #CogCheck32BitHeapMap,
	#superclass : #Object,
	#instVars : [
		'pages'
	],
	#classVars : [
		'ByteShift',
		'NumPages',
		'PageMask',
		'PageShift',
		'PageSize'
	],
	#category : 'VMMaker-InterpreterSimulation'
}

{ #category : #'class initialization' }
CogCheck32BitHeapMap class >> initialize [
	"self initialize"
	| wordSize bitsPerByte |
	wordSize := 4. "4 bytes per bit in the map"
	bitsPerByte := 8.
	NumPages := 256.
	PageShift := -24. "(32 - (NumPages log: 2)) negated asInteger"
	PageSize := 2 << 32 / wordSize / NumPages / bitsPerByte.
	PageMask := PageSize - 1.
	ByteShift := -5 "1 bit per 4 bytes, 8 bits per byte = 32 bytes of address space per map byte"
]

{ #category : #accessing }
CogCheck32BitHeapMap >> bitIndex: address [
	^(address bitShift: -2) bitAnd: 7
]

{ #category : #accessing }
CogCheck32BitHeapMap >> byteIndex: address [ 
	^((address bitShift: ByteShift) bitAnd: PageMask) + 1
]

{ #category : #accessing }
CogCheck32BitHeapMap >> clearHeapMap [
	pages do:
		[:p| p ifNotNil: [p atAllPut: 0]]
]

{ #category : #accessing }
CogCheck32BitHeapMap >> heapMapAtWord: address [
	"answer the bit corresponding to address aBit in the map"
	^(pages at: (self pageIndex: address))
		ifNil: [0]
		ifNotNil:
			[:page|
			((page at: (self byteIndex: address))
				bitShift: 0 - (self bitIndex: address))
					bitAnd: 1]
]

{ #category : #accessing }
CogCheck32BitHeapMap >> heapMapAtWord: address Put: aBit [
	"set the bit corresponding to address in the map to aBit"
	| pageIndex page bitIndex byte byteIndex |
	pageIndex := self pageIndex: address.
	page := pages at: pageIndex.
	page ifNil:
		[page := pages at: pageIndex put: (ByteArray new: PageSize)].
	byteIndex := self byteIndex: address.
	bitIndex := self bitIndex: address.
	byte := page at: byteIndex.
	byte := aBit = 0
				ifTrue: [byte - (byte bitAnd: 1 << bitIndex)]
				ifFalse: [byte bitOr: 1 << bitIndex].
	page at: byteIndex put: byte
]

{ #category : #'instance initialization' }
CogCheck32BitHeapMap >> initialize [
	pages := Array new: 256
]

{ #category : #accessing }
CogCheck32BitHeapMap >> pageIndex: address [
	^(address bitShift: PageShift) + 1 "32 - (pageSize log: 2)"
]

{ #category : #accessing }
CogCheck32BitHeapMap >> pageSize [
	self shouldBeImplemented
]
