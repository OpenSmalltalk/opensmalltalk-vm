Extension { #name : #LargePositiveInteger }

{ #category : #'*VMMaker-plugin generation' }
LargePositiveInteger class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg ccgLoad: aBlock expr: aString asMemberOfLargePositiveIntegerFrom: anInteger
]
