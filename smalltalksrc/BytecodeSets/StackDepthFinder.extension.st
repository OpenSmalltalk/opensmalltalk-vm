Extension { #name : #StackDepthFinder }

{ #category : #'*BytecodeSets-SistaV1-decoding' }
StackDepthFinder >> branchIfNotInstanceOf: behaviorOrArrayOfBehavior distance: delta [ 
	self drop.
	self doJump: delta
]
