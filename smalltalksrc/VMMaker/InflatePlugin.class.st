"
This plugin implements the one crucial function for efficiently decompressing streams.
"
Class {
	#name : #InflatePlugin,
	#superclass : #InterpreterPlugin,
	#instVars : [
		'zipCollection',
		'zipReadLimit',
		'zipPosition',
		'zipState',
		'zipBitBuf',
		'zipBitPos',
		'zipSource',
		'zipSourcePos',
		'zipSourceLimit',
		'zipLitTable',
		'zipDistTable',
		'zipCollectionSize',
		'zipLitTableSize',
		'zipDistTableSize'
	],
	#classVars : [
		'StateNoMoreData',
		'MaxBits'
	],
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
InflatePlugin class >> declareCVarsIn: cg [
	cg var: #zipCollection type: #'unsigned char*'.
	cg var: #zipSource type: #'unsigned char*'.
	cg var: #zipLitTable type: #'unsigned int*'.
	cg var: #zipDistTable type: #'unsigned int*'
]

{ #category : #'class initialization' }
InflatePlugin class >> initialize [
	"InflatePlugin initialize"
	MaxBits _ 16.
	StateNoMoreData _ 1.
]

{ #category : #translation }
InflatePlugin class >> moduleName [
	^'ZipPlugin'
]

{ #category : #translation }
InflatePlugin class >> shouldBeTranslated [
"InflatePlugin should not be translated but its subclass should since it is incorporated within that class's translation process"
	^self ~= InflatePlugin
]

{ #category : #primitives }
InflatePlugin >> primitiveInflateDecompressBlock [
	"Primitive. Inflate a single block."
	| oop rcvr |
	self export: true.
	interpreterProxy methodArgumentCount = 2 ifFalse:[^interpreterProxy primitiveFail].
	"distance table"
	oop _ interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isWords: oop)
		ifFalse:[^interpreterProxy primitiveFail].
	zipDistTable _ interpreterProxy firstIndexableField: oop.
	zipDistTableSize _ interpreterProxy slotSizeOf: oop.

	"literal table"
	oop _ interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isWords: oop)
		ifFalse:[^interpreterProxy primitiveFail].
	zipLitTable _ interpreterProxy firstIndexableField: oop.
	zipLitTableSize _ interpreterProxy slotSizeOf: oop.


	"Receiver (InflateStream)"
	rcvr _ interpreterProxy stackObjectValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isPointers: rcvr)
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy slotSizeOf: rcvr) < 9
		ifTrue:[^interpreterProxy primitiveFail].

	"All the integer instvars"
	zipReadLimit _ interpreterProxy fetchInteger: 2 ofObject: rcvr.
	zipState _ interpreterProxy fetchInteger: 3 ofObject: rcvr.
	zipBitBuf _ interpreterProxy fetchInteger: 4 ofObject: rcvr.
	zipBitPos _ interpreterProxy fetchInteger: 5 ofObject: rcvr.
	zipSourcePos _ interpreterProxy fetchInteger: 7 ofObject: rcvr.
	zipSourceLimit _ interpreterProxy fetchInteger: 8 ofObject: rcvr.
	interpreterProxy failed ifTrue:[^nil].
	zipReadLimit _ zipReadLimit - 1.
	zipSourcePos _ zipSourcePos - 1.
	zipSourceLimit _ zipSourceLimit - 1.

	"collection"
	oop _ interpreterProxy fetchPointer: 0 ofObject: rcvr.
	(interpreterProxy isIntegerObject: oop)
		ifTrue:[^interpreterProxy primitiveFail].
	(interpreterProxy isBytes: oop)
		ifFalse:[^interpreterProxy primitiveFail].
	zipCollection _ interpreterProxy firstIndexableField: oop.
	zipCollectionSize _ interpreterProxy byteSizeOf: oop.

	"source"
	oop _ interpreterProxy fetchPointer: 6 ofObject: rcvr.
	(interpreterProxy isIntegerObject: oop)
		ifTrue:[^interpreterProxy primitiveFail].
	(interpreterProxy isBytes: oop)
		ifFalse:[^interpreterProxy primitiveFail].
	zipSource _ interpreterProxy firstIndexableField: oop.

	"do the primitive"
	self zipDecompressBlock.
	interpreterProxy failed ifFalse:[
		"store modified values back"
		interpreterProxy storeInteger: 2 ofObject: rcvr withValue: zipReadLimit + 1.
		interpreterProxy storeInteger: 3 ofObject: rcvr withValue: zipState.
		interpreterProxy storeInteger: 4 ofObject: rcvr withValue: zipBitBuf.
		interpreterProxy storeInteger: 5 ofObject: rcvr withValue: zipBitPos.
		interpreterProxy storeInteger: 7 ofObject: rcvr withValue: zipSourcePos + 1.
		interpreterProxy pop: 2.
	].
]

{ #category : #inflating }
InflatePlugin >> zipDecodeValueFrom: table size: tableSize [
	"Decode the next value in the receiver using the given huffman table."
	| bits bitsNeeded tableIndex value index |
	self var: #table declareC:'unsigned int *table'.
	bitsNeeded _ (table at: 0) bitShift: -24.	"Initial bits needed"
	bitsNeeded > MaxBits ifTrue:[interpreterProxy primitiveFail. ^0].
	tableIndex _ 2.							"First real table"
	[true] whileTrue:[
		bits _ self zipNextBits: bitsNeeded.		"Get bits"
		index _ tableIndex + bits - 1.
		index >= tableSize ifTrue:[interpreterProxy primitiveFail. ^0].
		value _ table at: index.					"Lookup entry in table"
		(value bitAnd: 16r3F000000) = 0 ifTrue:[^value]. "Check if it is a leaf node"
		"Fetch sub table"
		tableIndex _ value bitAnd: 16rFFFF.	"Table offset in low 16 bit"
		bitsNeeded _ (value bitShift: -24) bitAnd: 255. "Additional bits in high 8 bit"
		bitsNeeded > MaxBits ifTrue:[interpreterProxy primitiveFail. ^0]].
	^0
]

{ #category : #inflating }
InflatePlugin >> zipDecompressBlock [
	| value extra length distance oldPos oldBits oldBitPos dstPos srcPos max |
	self inline: false.
	max _ zipCollectionSize - 1.
	[zipReadLimit < max and:[zipSourcePos <= zipSourceLimit]] whileTrue:[
		"Back up stuff if we're running out of space"
		oldBits _ zipBitBuf.
		oldBitPos _ zipBitPos.
		oldPos _ zipSourcePos.
		value _ self zipDecodeValueFrom: zipLitTable size: zipLitTableSize.
		value < 256 ifTrue:[ "A literal"
			zipCollection at: (zipReadLimit _ zipReadLimit + 1) put: value.
		] ifFalse:["length/distance or end of block"
			value = 256 ifTrue:["End of block"
				zipState _ zipState bitAnd: StateNoMoreData.
				^0].
			"Compute the actual length value (including possible extra bits)"
			extra _ (value bitShift: -16) - 1.
			length _ value bitAnd: 16rFFFF.
			extra > 0 ifTrue:[length _ length + (self zipNextBits: extra)].
			"Compute the distance value"
			value _ self zipDecodeValueFrom: zipDistTable size: zipDistTableSize.
			extra _ (value bitShift: -16).
			distance _ value bitAnd: 16rFFFF.
			extra > 0 ifTrue:[distance _ distance + (self zipNextBits: extra)].
			(zipReadLimit + length >= max) ifTrue:[
				zipBitBuf _ oldBits.
				zipBitPos _ oldBitPos.
				zipSourcePos _ oldPos.
				^0].
			dstPos _ zipReadLimit.
			srcPos _ zipReadLimit - distance.
			1 to: length do:[:i|
				zipCollection at: dstPos+i put: (zipCollection at: srcPos+i)].
			zipReadLimit _ zipReadLimit + length.
		].
	].
]

{ #category : #inflating }
InflatePlugin >> zipNextBits: n [
	| bits byte |
	self inline: true.
	[zipBitPos < n] whileTrue:[
		byte _ zipSource at: (zipSourcePos _ zipSourcePos + 1).
		zipBitBuf _ zipBitBuf + (byte << zipBitPos).
		zipBitPos _ zipBitPos + 8].
	bits _ zipBitBuf bitAnd: (1 << n)-1.
	zipBitBuf _ zipBitBuf >> n.
	zipBitPos _ zipBitPos - n.
	^bits
]
