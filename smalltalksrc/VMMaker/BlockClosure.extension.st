Extension { #name : #BlockClosure }

{ #category : #'*VMMaker-interpreter simulator' }
BlockClosure >> shouldStopIfAtPC: address [
	<primitive: 202>
	^self value: address
]
