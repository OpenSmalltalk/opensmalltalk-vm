Extension { #name : #Array }

{ #category : #'*VMMakerTests' }
Array >> forMemory: aMemory [

	^ aMemory newArrayWith:
		  (self collect: [ :anElement | anElement forMemory: aMemory ])
]
