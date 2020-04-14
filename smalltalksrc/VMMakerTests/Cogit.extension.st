Extension { #name : #Cogit }

{ #category : #'*VMMakerTests' }
Cogit >> byte0: anInteger [

	byte0 := anInteger
]

{ #category : #'*VMMakerTests' }
Cogit >> inBlock: anInteger [ 
	inBlock := anInteger
]

{ #category : #'*VMMakerTests' }
Cogit >> methodOrBlockNumArgs: anInteger [ 
	methodOrBlockNumArgs := anInteger
]

{ #category : #'*VMMakerTests' }
Cogit >> needsFrame [ 

	^ true
]

{ #category : #'*VMMakerTests' }
Cogit >> needsFrame: aFalse [ 
	needsFrame := aFalse
]
