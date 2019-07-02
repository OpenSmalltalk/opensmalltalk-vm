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
ByteArray >> long64At: index [
	"Answer a 64-bit integer in Smalltalk order (little-endian)."
	^self integerAt: index size: 8 signed: true
]

{ #category : #'*VMMaker-accessing' }
ByteArray >> long64At: index put: value [
	"I store 64-bit integers in Smalltalk (little-endian) order."
	^self integerAt: index put: value size: 8 signed: true
]

{ #category : #'*VMMaker-accessing' }
ByteArray >> longAt: byteIndex [
	"Store a 32bit signed integer starting at the given byte offset"
	^self integerAt: byteIndex size: 4 signed: true
]

{ #category : #'*VMMaker-accessing' }
ByteArray >> longAt: byteIndex put: aValue [
	"Store a 32bit signed integer starting at the given byte offset"
	^self integerAt: byteIndex put: aValue size: 4 signed: true
]

{ #category : #'*VMMaker-printing' }
ByteArray >> storeOn: aStream base: base [
	aStream nextPutAll: '#['.
	self
		do: [:each| each storeOn: aStream base: base]
		separatedBy: [aStream nextPut: $ ].
	aStream nextPut: $]
]

{ #category : #'*VMMaker-accessing' }
ByteArray >> unsignedLong64At: byteOffset [
	"Answer a 64-bit integer in Smalltalk order (little-endian)."
	^self integerAt: byteOffset size: 8 signed: false
]

{ #category : #'*VMMaker-accessing' }
ByteArray >> unsignedLong64At: byteOffset put: value [
	"I store 64-bit integers in Smalltalk (little-endian) order."
	^self integerAt: byteOffset put: value size: 8 signed: false
]
