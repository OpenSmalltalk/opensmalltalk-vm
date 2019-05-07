Extension { #name : #SystemNavigation }

{ #category : #'*VMMakerCompatibilityForPharo6' }
SystemNavigation >> allCallsOn: aSymbol localTo: aClass [ 

	^ self allCallsOn: aSymbol from: aClass
]
