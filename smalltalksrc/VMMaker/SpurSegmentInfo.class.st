Class {
	#name : #SpurSegmentInfo,
	#superclass : #VMStructType,
	#instVars : [
		'start',
		'segSize',
		'swizzle'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #translation }
SpurSegmentInfo class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"Enumerate aBinaryBlock with the names and C type strings for the inst vars to include in the typedef for the reciever."
	"self typedef"
	self instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn = 'swizzle'
							ifTrue: [#sqInt]
							ifFalse: [#usqInt])]
]

{ #category : #printing }
SpurSegmentInfo >> printOn: aStream [
	super printOn: aStream.
	self class instVarNames do:
		[:name|
		aStream space; nextPutAll: name; space; print: (self instVarNamed: name)]
]

{ #category : #accessing }
SpurSegmentInfo >> segSize [
	"Answer the value of segSize"

	^ segSize
]

{ #category : #accessing }
SpurSegmentInfo >> segSize: anObject [
	"Set the value of segSize"

	^segSize := anObject
]

{ #category : #accessing }
SpurSegmentInfo >> start [
	"Answer the value of start"

	^ start
]

{ #category : #accessing }
SpurSegmentInfo >> start: anObject [
	"Set the value of start"

	^start := anObject
]

{ #category : #accessing }
SpurSegmentInfo >> swizzle [
	"Answer the value of swizzle"

	^ swizzle
]

{ #category : #accessing }
SpurSegmentInfo >> swizzle: anObject [
	"Set the value of swizzle"

	^swizzle := anObject
]
