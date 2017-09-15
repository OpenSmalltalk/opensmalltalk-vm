Class {
	#name : #SpurSegmentInfo,
	#superclass : #VMStructType,
	#instVars : [
		'segStart',
		'segSize',
		'swizzle',
		'containsPinned',
		'savedSegSize',
		'lastFreeObject'
	],
	#category : 'VMMaker-SpurMemoryManager'
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

{ #category : #accessing }
SpurSegmentInfo >> containsPinned [
	"Answer the value of containsPinned"

	^ containsPinned
]

{ #category : #accessing }
SpurSegmentInfo >> containsPinned: anObject [
	"Set the value of containsPinned"

	^containsPinned := anObject
]

{ #category : #initialization }
SpurSegmentInfo >> initialize [
	segSize := segStart := swizzle := 0.
	containsPinned := false
]

{ #category : #accessing }
SpurSegmentInfo >> lastFreeObject [
	"Answer the value of lastFreeObject"

	^ lastFreeObject
]

{ #category : #accessing }
SpurSegmentInfo >> lastFreeObject: anObject [
	"Set the value of lastFreeObject"

	^lastFreeObject := anObject
]

{ #category : #printing }
SpurSegmentInfo >> printOn: aStream [
	<doNotGenerate>
	super printOn: aStream.
	(self class instVarNames copyReplaceAll: #('segSize') with: #('segSize' 'segLimit')) do:
		[:name| | iv |
		iv := self perform: name asSymbol.
		aStream space; nextPutAll: name; space; print: iv.
		(iv isInteger and: [iv ~= 0]) ifTrue:
			[aStream nextPut: $/.  iv storeOn: aStream base: 16]]
]

{ #category : #accessing }
SpurSegmentInfo >> savedSegSize [
	"Answer the value of savedSegSize"

	^ savedSegSize
]

{ #category : #accessing }
SpurSegmentInfo >> savedSegSize: anObject [
	"Set the value of savedSegSize"

	^savedSegSize := anObject
]

{ #category : #accessing }
SpurSegmentInfo >> segLimit [
	<returnTypeC: #usqInt>
	^segSize + segStart
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
SpurSegmentInfo >> segStart [
	"Answer the value of segStart"

	^ segStart
]

{ #category : #accessing }
SpurSegmentInfo >> segStart: anObject [
	"Set the value of segStart"

	^segStart := anObject
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
