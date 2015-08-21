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
	| n1 n2 |
	n1 := self unsignedLongAt: index bigEndian: false.
	n2 := self unsignedLongAt: index+4 bigEndian: false.
	^(n2 bitShift: 32) + n1
]

{ #category : #'*VMMaker-accessing' }
ByteArray >> long64At: index put: val [
	"I store 64-bit integers in Smalltalk (little-endian) order."
	self unsignedLongAt: index put: (val bitAnd: 16rFFFFFFFF) bigEndian: false.
	self unsignedLongAt: index+4 put: (val bitShift: -32) bigEndian: false.
	^val

]

{ #category : #'*VMMaker-accessing' }
ByteArray >> longAt: byteIndex [
	^self signedLongAt: byteIndex
]

{ #category : #'*VMMaker-accessing' }
ByteArray >> longAt: byteIndex put: aValue [
	^self signedLongAt: byteIndex put: aValue
]
