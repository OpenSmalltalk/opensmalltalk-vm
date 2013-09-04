Class {
	#name : #SpurNewSpaceSpace,
	#superclass : #VMStructType,
	#instVars : [
		'start',
		'limit'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #accessing }
SpurNewSpaceSpace >> limit [
	^limit
]

{ #category : #accessing }
SpurNewSpaceSpace >> start [
	^start
]

{ #category : #initialization }
SpurNewSpaceSpace >> start: startAddress limit: limitAddress [
	start := startAddress.
	limit := limitAddress
]
