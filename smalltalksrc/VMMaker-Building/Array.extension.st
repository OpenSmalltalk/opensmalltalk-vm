Extension { #name : #Array }

{ #category : #'*VMMaker-plugin generation' }
Array class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg 
		ccgLoad: aBlock 
		expr: aString 
		asIntPtrFrom: anInteger
		andThen: (cg ccgValBlock: 'isIndexable')
]

{ #category : #'*VMMaker-plugin generation' }
Array class >> ccgDeclareCForVar: aSymbolOrString [

	^'sqInt *', aSymbolOrString
]

{ #category : #'*VMMaker-interpreter simulator' }
Array >> coerceTo: cTypeString sim: interpreterSimulator [

	^ self
]
