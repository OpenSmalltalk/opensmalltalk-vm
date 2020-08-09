Extension { #name : #LargePositiveInteger }

{ #category : #'*VMMaker-OriginalTests' }
LargePositiveInteger >> minus64: anInteger [ 
	"For unit test support only. Subtract two large integers, raising an error on failure."

	<primitive: 22>
	^self primitiveFailed
]
