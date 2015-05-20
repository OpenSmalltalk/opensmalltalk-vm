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
		'zipDistTableSize',
		'readStreamInstSize'
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

{ #category : #simulation }
InflatePlugin class >> simulatorClass [
	"For running from Smalltalk - answer a class that can be used to simulate the receiver,
	 or nil if you want the primitives in this module to always fail, causing simulation to fall
	 through to the Smalltalk code.  By default every non-TestInterpreterPlugin can simulate itself."

	^DeflatePlugin
]

{ #category : #'primitive support' }
InflatePlugin >> determineSizeOfReadStream: rcvr [
	"Determine the inst size of the class above DeflateStream by
	 looking for the first class whose inst size is less than 13."
	| class |
	class := interpreterProxy fetchClassOf: rcvr.
	[class ~= interpreterProxy nilObject
	 and: [(interpreterProxy instanceSizeOf: class) >= 13]] whileTrue:
		[class := interpreterProxy superclassOf: class].
	class = interpreterProxy nilObject ifTrue:
		[^false].
	readStreamInstSize := interpreterProxy instanceSizeOf: class.
	^true
]

{ #category : #'initialize-release' }
InflatePlugin >> initialize [
	readStreamInstSize := 0
]

{ #category : #primitives }
InflatePlugin >> primitiveInflateDecompressBlock [
	"Primitive. Inflate a single block."
	| oop rcvr |
	<export: true>
	interpreterProxy methodArgumentCount = 2 ifFalse:
		[^interpreterProxy primitiveFail].
	"distance table"
	oop := interpreterProxy stackValue: 0.
	(interpreterProxy isWords: oop) ifFalse:
		[^interpreterProxy primitiveFail].
	zipDistTable := interpreterProxy firstIndexableField: oop.
	zipDistTableSize := interpreterProxy slotSizeOf: oop.

	"literal table"
	oop := interpreterProxy stackValue: 1.
	(interpreterProxy isWords: oop) ifFalse:
		[^interpreterProxy primitiveFail].
	zipLitTable := interpreterProxy firstIndexableField: oop.
	zipLitTableSize := interpreterProxy slotSizeOf: oop.


	"Receiver (InflateStream)"
	rcvr := interpreterProxy stackValue: 2.
	(interpreterProxy isPointers: rcvr) ifFalse:
		[^interpreterProxy primitiveFail].
	"All the integer instvars"
	readStreamInstSize = 0 ifTrue:
		[(self determineSizeOfReadStream: rcvr) ifFalse:
			[^interpreterProxy primitiveFail].
		 "If the receiver wasn't valid then we derived readStreamInstSize from an invalid source.  discard it."
		 (interpreterProxy slotSizeOf: rcvr) < (readStreamInstSize + 8) ifTrue:
			[readStreamInstSize := 0.
			 ^interpreterProxy primitiveFail]].
	(interpreterProxy slotSizeOf: rcvr) < (readStreamInstSize + 8) ifTrue:
		[^interpreterProxy primitiveFail].

	zipReadLimit := interpreterProxy fetchInteger: 2 ofObject: rcvr.
	zipState := interpreterProxy fetchInteger: readStreamInstSize + 0 ofObject: rcvr.
	zipBitBuf := interpreterProxy fetchInteger: readStreamInstSize + 1 ofObject: rcvr.
	zipBitPos := interpreterProxy fetchInteger: readStreamInstSize + 2 ofObject: rcvr.
	zipSourcePos := interpreterProxy fetchInteger: readStreamInstSize + 4 ofObject: rcvr.
	zipSourceLimit := interpreterProxy fetchInteger: readStreamInstSize + 5 ofObject: rcvr.
	interpreterProxy failed ifTrue:[^nil].
	zipReadLimit := zipReadLimit - 1.
	zipSourcePos := zipSourcePos - 1.
	zipSourceLimit := zipSourceLimit - 1.

	"collection"
	oop := interpreterProxy fetchPointer: 0 ofObject: rcvr.
	(interpreterProxy isBytes: oop) ifFalse:
		[^interpreterProxy primitiveFail].
	zipCollection := interpreterProxy firstIndexableField: oop.
	zipCollectionSize := interpreterProxy byteSizeOf: oop.

	"source"
	oop := interpreterProxy fetchPointer: readStreamInstSize + 3 ofObject: rcvr.
	(interpreterProxy isBytes: oop) ifFalse:
		[^interpreterProxy primitiveFail].
	zipSource := interpreterProxy firstIndexableField: oop.

	"do the primitive"
	self zipDecompressBlock.
	interpreterProxy failed ifFalse: "store modified values back"
		[interpreterProxy storeInteger: 2 ofObject: rcvr withValue: zipReadLimit + 1.
		interpreterProxy storeInteger: readStreamInstSize + 0 ofObject: rcvr withValue: zipState.
		interpreterProxy storeInteger: readStreamInstSize + 1 ofObject: rcvr withValue: zipBitBuf.
		interpreterProxy storeInteger: readStreamInstSize + 2 ofObject: rcvr withValue: zipBitPos.
		interpreterProxy storeInteger: readStreamInstSize + 4 ofObject: rcvr withValue: zipSourcePos + 1.
		interpreterProxy pop: 2]
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
