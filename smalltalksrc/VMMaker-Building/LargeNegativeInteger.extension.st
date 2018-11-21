Extension { #name : #LargeNegativeInteger }

{ #category : #'*VMMaker-plugin generation' }
LargeNegativeInteger class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg ccgLoad: aBlock expr: aString asMemberOfLargeNegativeIntegerFrom: anInteger
]
