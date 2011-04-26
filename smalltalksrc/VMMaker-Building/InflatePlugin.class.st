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
		'MaxBits',
		'StateNoMoreData'
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
	MaxBits := 16.
	StateNoMoreData := 1.
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
	<export: true>
	interpreterProxy methodArgumentCount = 2 ifFalse:[^interpreterProxy primitiveFail].
	"distance table"
	oop := interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isWords: oop)
		ifFalse:[^interpreterProxy primitiveFail].
	zipDistTable := interpreterProxy firstIndexableField: oop.
	zipDistTableSize := interpreterProxy slotSizeOf: oop.

	"literal table"
	oop := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isWords: oop)
		ifFalse:[^interpreterProxy primitiveFail].
	zipLitTable := interpreterProxy firstIndexableField: oop.
	zipLitTableSize := interpreterProxy slotSizeOf: oop.


	"Receiver (InflateStream)"
	rcvr := interpreterProxy stackObjectValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isPointers: rcvr)
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy slotSizeOf: rcvr) < 9
		ifTrue:[^interpreterProxy primitiveFail].

	"All the integer instvars"
	zipReadLimit := interpreterProxy fetchInteger: 2 ofObject: rcvr.
	zipState := interpreterProxy fetchInteger: 3 ofObject: rcvr.
	zipBitBuf := interpreterProxy fetchInteger: 4 ofObject: rcvr.
	zipBitPos := interpreterProxy fetchInteger: 5 ofObject: rcvr.
	zipSourcePos := interpreterProxy fetchInteger: 7 ofObject: rcvr.
	zipSourceLimit := interpreterProxy fetchInteger: 8 ofObject: rcvr.
	interpreterProxy failed ifTrue:[^nil].
	zipReadLimit := zipReadLimit - 1.
	zipSourcePos := zipSourcePos - 1.
	zipSourceLimit := zipSourceLimit - 1.

	"collection"
	oop := interpreterProxy fetchPointer: 0 ofObject: rcvr.
	(interpreterProxy isIntegerObject: oop)
		ifTrue:[^interpreterProxy primitiveFail].
	(interpreterProxy isBytes: oop)
		ifFalse:[^interpreterProxy primitiveFail].
	zipCollection := interpreterProxy firstIndexableField: oop.
	zipCollectionSize := interpreterProxy byteSizeOf: oop.

	"source"
	oop := interpreterProxy fetchPointer: 6 ofObject: rcvr.
	(interpreterProxy isIntegerObject: oop)
		ifTrue:[^interpreterProxy primitiveFail].
	(interpreterProxy isBytes: oop)
		ifFalse:[^interpreterProxy primitiveFail].
	zipSource := interpreterProxy firstIndexableField: oop.

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
	<var: #table type:'unsigned int *'>
	bitsNeeded := (table at: 0) bitShift: -24.	"Initial bits needed"
	bitsNeeded > MaxBits ifTrue:[interpreterProxy primitiveFail. ^0].
	tableIndex := 2.							"First real table"
	[true] whileTrue:[
		bits := self zipNextBits: bitsNeeded.		"Get bits"
		index := tableIndex + bits - 1.
		index >= tableSize ifTrue:[interpreterProxy primitiveFail. ^0].
		value := table at: index.					"Lookup entry in table"
		(value bitAnd: 16r3F000000) = 0 ifTrue:[^value]. "Check if it is a leaf node"
		"Fetch sub table"
		tableIndex := value bitAnd: 16rFFFF.	"Table offset in low 16 bit"
		bitsNeeded := (value bitShift: -24) bitAnd: 255. "Additional bits in high 8 bit"
		bitsNeeded > MaxBits ifTrue:[interpreterProxy primitiveFail. ^0]].
	^0
]

{ #category : #inflating }
InflatePlugin >> zipDecompressBlock [
	| value extra length distance oldPos oldBits oldBitPos dstPos srcPos max |
	<inline: false>
	max := zipCollectionSize - 1.
	[zipReadLimit < max and:[zipSourcePos <= zipSourceLimit]] whileTrue:[
		"Back up stuff if we're running out of space"
		oldBits := zipBitBuf.
		oldBitPos := zipBitPos.
		oldPos := zipSourcePos.
		value := self zipDecodeValueFrom: zipLitTable size: zipLitTableSize.
		value < 256 ifTrue:[ "A literal"
			zipCollection at: (zipReadLimit := zipReadLimit + 1) put: value.
		] ifFalse:["length/distance or end of block"
			value = 256 ifTrue:["End of block"
				zipState := zipState bitAnd: StateNoMoreData.
				^0].
			"Compute the actual length value (including possible extra bits)"
			extra := (value bitShift: -16) - 1.
			length := value bitAnd: 16rFFFF.
			extra > 0 ifTrue:[length := length + (self zipNextBits: extra)].
			"Compute the distance value"
			value := self zipDecodeValueFrom: zipDistTable size: zipDistTableSize.
			extra := (value bitShift: -16).
			distance := value bitAnd: 16rFFFF.
			extra > 0 ifTrue:[distance := distance + (self zipNextBits: extra)].
			(zipReadLimit + length >= max) ifTrue:[
				zipBitBuf := oldBits.
				zipBitPos := oldBitPos.
				zipSourcePos := oldPos.
				^0].
			dstPos := zipReadLimit.
			srcPos := zipReadLimit - distance.
			1 to: length do:[:i|
				zipCollection at: dstPos+i put: (zipCollection at: srcPos+i)].
			zipReadLimit := zipReadLimit + length.
		].
	].
]

{ #category : #inflating }
InflatePlugin >> zipNextBits: n [
	| bits byte |
	<inline: true>
	[zipBitPos < n] whileTrue:[
		byte := zipSource at: (zipSourcePos := zipSourcePos + 1).
		zipBitBuf := zipBitBuf + (byte << zipBitPos).
		zipBitPos := zipBitPos + 8].
	bits := zipBitBuf bitAnd: (1 << n)-1.
	zipBitBuf := zipBitBuf >> n.
	zipBitPos := zipBitPos - n.
	^bits
]
