Extension { #name : #SmallInteger }

{ #category : #'*VMMakerTests' }
SmallInteger >> forMemory: aMemory [
	
	(self > aMemory maxSmallInteger or: [ self < aMemory minSmallInteger ]) ifTrue: [ self halt ].
	
	^ aMemory integerObjectOf: self
]
