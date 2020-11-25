Extension { #name : #Character }

{ #category : #'*VMMakerTests' }
Character >> forMemory: aMemory [

	^ aMemory characterObjectOf: self codePoint
]
