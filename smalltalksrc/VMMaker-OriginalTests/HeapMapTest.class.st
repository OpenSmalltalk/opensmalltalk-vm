Class {
	#name : #HeapMapTest,
	#superclass : #TestCase,
	#category : #'VMMaker-OriginalTests'
}

{ #category : #tests }
HeapMapTest >> test32BitHeapMap [
	| heapMap |
	heapMap := CogCheck32BitHeapMap new.

	"all bits shoud be clear in a new map"
	0 to: 1024 * 1024 - 4 by: 4 do:
		[:addr| self assert: (heapMap heapMapAtWord: addr) = 0].
	(2 raisedTo: 30) to: 1024 * 1024 - 4 + (2 raisedTo: 30) by: 4 do:
		[:addr| self assert: (heapMap heapMapAtWord: addr) = 0].

	"set every 9th bit to 1"
	0 to: 1024 * 1024 - 4 by: 36 do:
		[:addr| heapMap heapMapAtWord: addr Put: 1].	
	(2 raisedTo: 30) to: 1024 * 1024 - 4 + (2 raisedTo: 30) by:36 do:
		[:addr| heapMap heapMapAtWord: addr Put: 1].

	"check every 9th bit is set and all intervening bits are zero"
	0 to: 1024 * 1024 - 4 by: 36 do:
		[:addr|
		 addr - 32 > 0 ifTrue:
			[addr - 32 to: addr - 4 by: 4 do:
				[:zeroAddr| self assert: (heapMap heapMapAtWord: zeroAddr) = 0]].
		self assert: (heapMap heapMapAtWord: addr) = 1].
	
	(2 raisedTo: 30) to: 1024 * 1024 - 4 + (2 raisedTo: 30) by:36 do:
		[:addr|
		 addr - 32 > 0 ifTrue:
			[addr - 32 to: addr - 4 by: 4 do:
				[:zeroAddr| self assert: (heapMap heapMapAtWord: zeroAddr) = 0]].
		self assert: (heapMap heapMapAtWord: addr) = 1].

	"clear the bits"
	0 to: 1024 * 1024 - 4 by: 36 do:
		[:addr| heapMap heapMapAtWord: addr Put: 0].	
	(2 raisedTo: 30) to: 1024 * 1024 - 4 + (2 raisedTo: 30) by:36 do:
		[:addr| heapMap heapMapAtWord: addr Put: 0].

	"check everything is zero again"
	0 to: 1024 * 1024 - 4 by: 4 do:
		[:addr| self assert: (heapMap heapMapAtWord: addr) = 0].
	(2 raisedTo: 30) to: 1024 * 1024 - 4 + (2 raisedTo: 30) by: 4 do:
		[:addr| self assert: (heapMap heapMapAtWord: addr) = 0]
]
