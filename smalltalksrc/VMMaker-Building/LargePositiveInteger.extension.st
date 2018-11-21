Extension { #name : #LargePositiveInteger }

{ #category : #'*VMMaker-plugin generation' }
LargePositiveInteger class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg ccgLoad: aBlock expr: aString asMemberOfLargePositiveIntegerFrom: anInteger
]

{ #category : #'*VMMaker-Tests' }
LargePositiveInteger >> minus64: anInteger [ 
	"For unit test support only. Subtract two large integers, raising an error on failure."

	<primitive: 22>
	^self primitiveFailed
]
