"
A SpurCircularBuffer is a region of memory being used as a circular buffer.  The buffer is empty when last < start.  The buffer is full when first = (last + wordSize > limit ifTrue: [start] ifFalse: [last + wordSize]).

Instance Variables
	first:		<Integer address>
	last:		<Integer address>

first
	- pointer to the first element in the buffer

last
	- pointer to the last element in the buffer

"
Class {
	#name : #SpurCircularBuffer,
	#superclass : #SpurNewSpaceSpace,
	#instVars : [
		'manager',
		'first',
		'last'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #accessing }
SpurCircularBuffer >> addLast: element [
	| newLast |
	newLast := last + manager wordSize.
	newLast >= limit ifTrue:
		[newLast := start].
	(newLast = first and: [last >= start]) ifTrue: "wrapped; bump first"
		[(first := newLast + manager wordSize) >= limit ifTrue:
			[first := start]].
	last := newLast.
	self assert: (first >= start and: [first < limit]).
	self assert: (last >= start and: [last < limit]).
	manager longAt: newLast put: element
]

{ #category : #accessing }
SpurCircularBuffer >> first [
	"Answer the value of first"

	^ first
]

{ #category : #accessing }
SpurCircularBuffer >> first: anObject [
	"Set the value of first"

	^first := anObject
]

{ #category : #enumerating }
SpurCircularBuffer >> from: initialPtr reverseDo: aBlock [
	<inline: true>
	| ptr |
	last >= start ifTrue:
		[ptr := initialPtr.
		 first <= last
			ifTrue: "enum in first to last range, last to first"
				[ptr >= first ifTrue:
					[[aBlock value: (manager longAt: ptr).
					  (ptr := ptr - manager wordSize) < first ifTrue:
						[^nil]] repeat]]
			ifFalse: "enum in start to last range, last to start"
				[ptr <= last ifTrue:
					[[ptr >= start] whileTrue:
						[aBlock value: (manager longAt: ptr).
						 ptr := ptr - manager wordSize].
					 ptr := limit].
				 "now enum in first to limit range, limit to first"
				 [ptr >= first] whileTrue:
					[aBlock value: (manager longAt: ptr).
					 ptr := ptr - manager wordSize]]].
	^nil
]

{ #category : #initialization }
SpurCircularBuffer >> initializeStart: aStart limit: aLimit [
	self start: aStart;
		limit: aLimit;
		first: aStart;
		last: aStart - manager wordSize
]

{ #category : #testing }
SpurCircularBuffer >> isEmpty [
	^last < start
]

{ #category : #accessing }
SpurCircularBuffer >> last [
	"Answer the value of last"

	^ last
]

{ #category : #accessing }
SpurCircularBuffer >> last: anObject [
	"Set the value of last"

	^last := anObject
]

{ #category : #accessing }
SpurCircularBuffer >> manager [
	"Answer the value of manager"

	^ manager
]

{ #category : #accessing }
SpurCircularBuffer >> manager: anObject [
	"Set the value of manager"
	<doNotGenerate>
	^manager := anObject
]

{ #category : #printing }
SpurCircularBuffer >> printOn: aStream [
	<doNotGenerate>
	super printOn: aStream.
	first ifNotNil:
		[aStream nextPutAll: ' first: '; nextPutAll: first hex].
	last ifNotNil:
		[aStream nextPutAll: ' last: '; nextPutAll: last hex]
]

{ #category : #accessing }
SpurCircularBuffer >> resetAsEmpty [
	first := start.
	last := start - manager wordSize
]

{ #category : #enumerating }
SpurCircularBuffer >> reverseDo: aBlock [
	| ptr |
	last >= start ifTrue:
		[ptr := last.
		 [self assert: (first <= last
						ifTrue: [first <= ptr and: [ptr <= last]]
						ifFalse: [(start <= ptr and: [ptr <= last]) or: [first <= ptr and: [ptr <= limit]]]).
		  aBlock value: (manager longAt: ptr).
		  ptr = first ifTrue: [^nil].
		  (ptr := ptr - manager wordSize) < start ifTrue:
			[ptr := limit]] repeat].
	^nil
]

{ #category : #accessing }
SpurCircularBuffer >> usedSize [
	^last < start
		ifTrue: [0]
		ifFalse:
			[last >= first
				ifTrue: [last - first / manager wordSize + 1]
				ifFalse: [limit - start - (first - last) / manager wordSize - 1]]
]
