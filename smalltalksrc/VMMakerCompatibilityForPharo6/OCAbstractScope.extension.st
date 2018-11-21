Extension { #name : #OCAbstractScope }

{ #category : #'*VMMakerCompatibilityForPharo6-results' }
OCAbstractScope >> childrenDo: aBlock after: pBlock suchThat: selectBlock [
	children ifNotNil:
		[children do:
			[:child|
			 (selectBlock value: child) ifTrue:
				[aBlock value: child.
				 child childrenDo: aBlock after: pBlock suchThat: selectBlock.
				 pBlock value: child]]]
]

{ #category : #'*VMMakerCompatibilityForPharo6-results' }
OCAbstractScope >> childrenDo: aBlock suchThat: selectBlock [
	children ifNotNil:
		[children do:
			[:child|
			 (selectBlock value: child) ifTrue:
				[aBlock value: child.
				 child childrenDo: aBlock suchThat: selectBlock]]]
]
