Extension { #name : #ByteArray }

{ #category : #'*VMMaker-plugin generation' }
ByteArray class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg 
		ccgLoad: aBlock 
		expr: aString 
		asCharPtrFrom: anInteger
		andThen: (cg ccgValBlock: 'isBytes')
]

{ #category : #'*VMMaker-plugin generation' }
ByteArray class >> ccgDeclareCForVar: aSymbolOrString [

	^'char *', aSymbolOrString
]

{ #category : #'*VMMaker-coercing' }
ByteArray >> coerceTo: cTypeString sim: interpreterSimulator [
	^CLiteralArray on: self
]

{ #category : #'*VMMaker-accessing' }
ByteArray >> longAt: byteIndex [
	^self signedLongAt: byteIndex
]

{ #category : #'*VMMaker-accessing' }
ByteArray >> longAt: byteIndex put: aValue [
	^self signedLongAt: byteIndex put: aValue
]
