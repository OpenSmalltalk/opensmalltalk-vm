"
This is another JPEG reader plugin, this time not requiring jpeglib support. 
"
Class {
	#name : #JPEGReaderPlugin,
	#superclass : #InterpreterPlugin,
	#instVars : [
		'yComponent',
		'crComponent',
		'cbComponent',
		'ySampleStream',
		'crSampleStream',
		'cbSampleStream',
		'yBlocks',
		'crBlocks',
		'cbBlocks',
		'residuals',
		'ditherMask',
		'jpegBits',
		'jpegBitsSize',
		'jpegNaturalOrder',
		'jsCollection',
		'jsPosition',
		'jsReadLimit',
		'jsBitBuffer',
		'jsBitCount',
		'acTable',
		'dcTable',
		'acTableSize',
		'dcTableSize'
	],
	#classVars : [
		'BlockWidthIndex',
		'BlueIndex',
		'ConstBits',
		'CurrentXIndex',
		'CurrentYIndex',
		'DCTSize',
		'DCTSize2',
		'FIXn0n298631336',
		'FIXn0n34414',
		'FIXn0n390180644',
		'FIXn0n541196100',
		'FIXn0n71414',
		'FIXn0n765366865',
		'FIXn0n899976223',
		'FIXn1n175875602',
		'FIXn1n40200',
		'FIXn1n501321110',
		'FIXn1n77200',
		'FIXn1n847759065',
		'FIXn1n961570560',
		'FIXn2n053119869',
		'FIXn2n562915447',
		'FIXn3n072711026',
		'GreenIndex',
		'HScaleIndex',
		'LookaheadBitsIndex',
		'LookaheadSymbolIndex',
		'MCUBlockIndex',
		'MCUWidthIndex',
		'MaxBits',
		'MaxMCUBlocks',
		'MaxSample',
		'MaxcodeIndex',
		'MinComponentSize',
		'Pass1Bits',
		'Pass1Div',
		'Pass2Div',
		'PriorDCValueIndex',
		'RedIndex',
		'SampleOffset',
		'VScaleIndex'
	],
	#category : 'VMMaker-Plugins'
}

{ #category : #translation }
JPEGReaderPlugin class >> declareCVarsIn: cg [
	cg var: 'yComponent'
		declareC: 'int yComponent[' , MinComponentSize printString , ']'.
	cg var: 'crComponent'
		declareC: 'int crComponent[' , MinComponentSize printString , ']'.
	cg var: 'cbComponent'
		declareC: 'int cbComponent[' , MinComponentSize printString , ']'.
	cg var: 'yBlocks'
		declareC: 'int *yBlocks[' , MaxMCUBlocks printString , ']'.
	cg var: 'crBlocks'
		declareC: 'int *crBlocks[' , MaxMCUBlocks printString  , ']'.
	cg var: 'cbBlocks'
		declareC: 'int *cbBlocks[' , MaxMCUBlocks printString  , ']'.
	cg var: 'residuals'
		declareC: 'int *residuals'.
	cg var: 'jpegBits'
		declareC: 'int *jpegBits'.

	cg var: 'jpegNaturalOrder'
		declareC: 'int jpegNaturalOrder[64] = {
	0, 1, 8, 16, 9, 2, 3, 10, 
	17, 24, 32, 25, 18, 11, 4, 5, 
	12, 19, 26, 33, 40, 48, 41, 34, 
	27, 20, 13, 6, 7, 14, 21, 28, 
	35, 42, 49, 56, 57, 50, 43, 36, 
	29, 22, 15, 23, 30, 37, 44, 51, 
	58, 59, 52, 45, 38, 31, 39, 46, 
	53, 60, 61, 54, 47, 55, 62, 63
}'.

	cg var: 'jsCollection' 
		declareC:'unsigned char *jsCollection'.
	cg var: 'acTable' 
		declareC:'int *acTable'.
	cg var: 'dcTable' 
		declareC:'int *dcTable'.

]

{ #category : #'class initialization' }
JPEGReaderPlugin class >> initialize [
	"JPEGReaderPlugin initialize"
	DCTSize := 8.
	MaxSample := (2 raisedToInteger: DCTSize) - 1.
	SampleOffset := MaxSample // 2.
	DCTSize2 := DCTSize squared.
	ConstBits := 13.
	Pass1Bits := 2.
	Pass1Div := 1 bitShift: ConstBits - Pass1Bits.
	Pass2Div := 1 bitShift: ConstBits + Pass1Bits + 3.

	"fixed-point Inverse Discrete Cosine Transform (IDCT) constants"
	FIXn0n298631336 := 2446.
	FIXn0n390180644 := 3196.
	FIXn0n541196100 := 4433.
	FIXn0n765366865 := 6270.
	FIXn0n899976223 := 7373.
	FIXn1n175875602 := 9633.
	FIXn1n501321110 := 12299.
	FIXn1n847759065 := 15137.
	FIXn1n961570560 := 16069.
	FIXn2n053119869 := 16819.
	FIXn2n562915447 := 20995.
	FIXn3n072711026 := 25172.

	"fixed-point color conversion constants"
	FIXn0n34414 := 22554.
	FIXn0n71414 := 46802.
	FIXn1n40200 := 91881.
	FIXn1n77200 :=  116130.

	CurrentXIndex := 0.
	CurrentYIndex := 1.
	HScaleIndex := 2.
	VScaleIndex := 3.
	MCUBlockIndex := 4.
	BlockWidthIndex := 5.
	MCUWidthIndex := 8.
	PriorDCValueIndex := 10.
	MinComponentSize := 11.

	RedIndex := 0.
	GreenIndex := 1.
	BlueIndex := 2.

	MaxMCUBlocks := 128.
	MaxBits := 16.
]

{ #category : #decoding }
JPEGReaderPlugin >> cbColorComponentFrom: oop [
	^(self colorComponent: cbComponent from: oop)
		and:[self colorComponentBlocks: cbBlocks from: oop]
]

{ #category : #decoding }
JPEGReaderPlugin >> colorComponent: aColorComponent from: oop [
	<var: #aColorComponent type: 'int *'>
	(interpreterProxy isPointers: oop) ifFalse:[^false].
	(interpreterProxy slotSizeOf: oop) < MinComponentSize ifTrue:[^false].
	aColorComponent at: CurrentXIndex put: 
		(interpreterProxy fetchInteger: CurrentXIndex ofObject: oop).
	aColorComponent at: CurrentYIndex put: 
		(interpreterProxy fetchInteger: CurrentYIndex ofObject: oop).
	aColorComponent at: HScaleIndex put: 
		(interpreterProxy fetchInteger: HScaleIndex ofObject: oop).
	aColorComponent at: VScaleIndex put: 
		(interpreterProxy fetchInteger: VScaleIndex ofObject: oop).
	aColorComponent at: BlockWidthIndex put: 
		(interpreterProxy fetchInteger: BlockWidthIndex ofObject: oop).
	aColorComponent at: MCUWidthIndex put: 
		(interpreterProxy fetchInteger: MCUWidthIndex ofObject: oop).
	aColorComponent at: PriorDCValueIndex put: 
		(interpreterProxy fetchInteger: PriorDCValueIndex ofObject: oop).
	^interpreterProxy failed not
]

{ #category : #decoding }
JPEGReaderPlugin >> colorComponentBlocks: blocks from: oop [
	| arrayOop max blockOop |
	<var: #blocks type: 'int **'>
	(interpreterProxy isPointers: oop) ifFalse:[^false].
	(interpreterProxy slotSizeOf: oop) < MinComponentSize ifTrue:[^false].

	arrayOop := interpreterProxy fetchPointer: MCUBlockIndex ofObject: oop.
	(interpreterProxy isPointers: arrayOop) ifFalse:[^false].
	max := interpreterProxy slotSizeOf: arrayOop.
	max > MaxMCUBlocks ifTrue:[^false].
	0 to: max-1 do:[:i|
		blockOop := interpreterProxy fetchPointer: i ofObject: arrayOop.
		(interpreterProxy isWords: blockOop) ifFalse:[^false].
		(interpreterProxy slotSizeOf: blockOop) = DCTSize2 ifFalse:[^false].
		blocks at: i put: (interpreterProxy firstIndexableField: blockOop).
	].
	^interpreterProxy failed not
]

{ #category : #decoding }
JPEGReaderPlugin >> colorConvertGrayscaleMCU [
	| y |
	yComponent at: CurrentXIndex put: 0.
	yComponent at: CurrentYIndex put: 0.
	0 to: jpegBitsSize-1 do:[:i|
		y := self nextSampleY.
		y := y + (residuals at: GreenIndex).
		y := y min: MaxSample.
		residuals at: GreenIndex put: (y bitAnd: ditherMask).
		y := y bitAnd: MaxSample - ditherMask.
		y := y max: 1.
		jpegBits at: i put: 16rFF000000 + (y<<16) + (y<<8) + y.
	].
]

{ #category : #decoding }
JPEGReaderPlugin >> colorConvertMCU [
	| y cb cr red green blue |
	yComponent at: CurrentXIndex put: 0.
	yComponent at: CurrentYIndex put: 0.
	cbComponent at: CurrentXIndex put: 0.
	cbComponent at: CurrentYIndex put: 0.
	crComponent at: CurrentXIndex put: 0.
	crComponent at: CurrentYIndex put: 0.
	0 to: jpegBitsSize-1 do:[:i|
		y := self nextSampleY.
		cb := self nextSampleCb.
		cb := cb - SampleOffset.
		cr := self nextSampleCr.
		cr := cr - SampleOffset.
		red := y + ((FIXn1n40200 * cr) // 65536) + (residuals at: RedIndex).
		red := red min: MaxSample. red := red max: 0.
		residuals at: RedIndex put: (red bitAnd: ditherMask).
		red := red bitAnd: MaxSample - ditherMask.
		red := red max: 1.
		green := y - ((FIXn0n34414 * cb) // 65536) -
			((FIXn0n71414 * cr) // 65536) + (residuals at: GreenIndex).
		green := green min: MaxSample. green := green max: 0.
		residuals at: GreenIndex put: (green bitAnd: ditherMask).
		green := green bitAnd: MaxSample - ditherMask.
		green := green max: 1.
		blue := y + ((FIXn1n77200 * cb) // 65536) + (residuals at: BlueIndex).
		blue := blue min: MaxSample. blue := blue max: 0.
		residuals at: BlueIndex put: (blue bitAnd: ditherMask).
		blue := blue bitAnd: MaxSample - ditherMask.
		blue := blue max: 1.
		jpegBits at: i put: 16rFF000000 + (red bitShift: 16) + (green bitShift: 8) + blue.
	].
]

{ #category : #decoding }
JPEGReaderPlugin >> crColorComponentFrom: oop [
	^(self colorComponent: crComponent from: oop)
		and:[self colorComponentBlocks: crBlocks from: oop]
]

{ #category : #decoding }
JPEGReaderPlugin >> decodeBlockInto: anArray component: aColorComponent [
	| byte zeroCount bits index |
	<var: #anArray type: 'int *'>
	<var: #aColorComponent type: 'int *'>
	byte := self jpegDecodeValueFrom: dcTable size: dcTableSize.
	byte < 0 ifTrue:[^interpreterProxy primitiveFail].
	byte ~= 0 ifTrue: [
		bits := self getBits: byte.
		byte := self scaleAndSignExtend: bits inFieldWidth: byte].
	byte := aColorComponent 
				at: PriorDCValueIndex 
				put: (aColorComponent at: PriorDCValueIndex) + byte.
	anArray at: 0 put: byte.
	1 to: DCTSize2 - 1 do:[:i| anArray at: i put: 0].
	index := 1.
	[index < DCTSize2] whileTrue:[
		byte := self jpegDecodeValueFrom: acTable size: acTableSize.
		byte < 0 ifTrue:[^interpreterProxy primitiveFail].
		zeroCount := byte >> 4.
		byte := byte bitAnd: 16r0F.
		byte ~= 0 ifTrue:[
			index := index + zeroCount.
			bits :=  self getBits: byte.
			byte := self scaleAndSignExtend: bits inFieldWidth: byte.
			(index < 0 or:[index >= DCTSize2]) ifTrue:[^interpreterProxy primitiveFail].
			anArray at:	 (jpegNaturalOrder at: index) put: byte.
		] ifFalse:[
			zeroCount = 15 ifTrue: [index := index + zeroCount] ifFalse: [^ nil].
		].
		index := index + 1
	].
]

{ #category : #'stream support' }
JPEGReaderPlugin >> fillBuffer [
	| byte |
	[jsBitCount <= 16] whileTrue:[
		jsPosition < jsReadLimit ifFalse:[^jsBitCount].
		byte := jsCollection at: jsPosition.
		jsPosition := jsPosition + 1.
		byte = 16rFF ifTrue:["peek for 00"
			((jsPosition < jsReadLimit) and:[(jsCollection at: jsPosition) = 16r00]) ifFalse:[
				jsPosition := jsPosition - 1.
				^jsBitCount].
			jsPosition := jsPosition + 1].
		jsBitBuffer := (jsBitBuffer bitShift: 8) bitOr: byte.
		jsBitCount := jsBitCount + 8].
	^jsBitCount
]

{ #category : #'stream support' }
JPEGReaderPlugin >> getBits: requestedBits [
	| value |
	requestedBits > jsBitCount ifTrue:[
		self fillBuffer.
		requestedBits > jsBitCount ifTrue:[^-1]].
	jsBitCount := jsBitCount - requestedBits.
	value := jsBitBuffer >> jsBitCount.
	jsBitBuffer := jsBitBuffer bitAnd: (1 << jsBitCount) -1.
	^ value
]

{ #category : #decoding }
JPEGReaderPlugin >> idctBlockInt: anArray qt: qt [
	| ws anACTerm dcval z2 z3 z1 t2 t3 t0 t1 t10 t13 t11 t12 z4 z5 v |
	<var: #anArray type: 'int *'>
	<var: #qt type: 'int *'>
	<var: #ws declareC: 'int ws[64]'>
	self cCode:'' inSmalltalk:[ws := CArrayAccessor on: (IntegerArray new: 64)].
	"Pass 1: process columns from anArray, store into work array"
	0 to: DCTSize-1 do:[:i |
		anACTerm := -1.
		1 to: DCTSize-1 do:[:row|
			anACTerm = -1 ifTrue:[
				(anArray at: row * DCTSize + i) = 0 ifFalse:[anACTerm := row]]].
		anACTerm = -1 ifTrue:[
			dcval := (anArray at: i) * (qt at: 0) << Pass1Bits.
			0 to: DCTSize-1 do: [:j | ws at: (j * DCTSize + i) put: dcval]
		] ifFalse:[
			z2 := (anArray at: (DCTSize * 2 + i)) * (qt at: (DCTSize * 2 + i)).
			z3 := (anArray at: (DCTSize * 6 + i)) * (qt at: (DCTSize * 6 + i)).
			z1 := (z2 + z3) * FIXn0n541196100.
			t2 := z1 + (z3 * (0 - FIXn1n847759065)).
			t3 := z1 + (z2 * FIXn0n765366865).
			z2 := (anArray at: i) * (qt at: i).
			z3 := (anArray at: (DCTSize * 4 + i)) * (qt at: (DCTSize * 4 + i)).
			t0 := (z2 + z3) << ConstBits.
			t1 := (z2 - z3) << ConstBits.
			t10 := t0 + t3.
			t13 := t0 - t3.
			t11 := t1 + t2.
			t12 := t1 - t2.
			t0 := (anArray at: (DCTSize * 7 + i)) * (qt at: (DCTSize * 7 + i)).
			t1 := (anArray at: (DCTSize * 5 + i)) * (qt at: (DCTSize * 5 + i)).
			t2 := (anArray at: (DCTSize * 3 + i)) * (qt at: (DCTSize * 3 + i)).
			t3 := (anArray at: (DCTSize + i)) * (qt at: (DCTSize + i)).
			z1 := t0 + t3.
			z2 := t1 + t2.
			z3 := t0 + t2.
			z4 := t1 + t3.
			z5 := (z3 + z4) * FIXn1n175875602.
			t0 := t0 * FIXn0n298631336.
			t1 := t1 * FIXn2n053119869.
			t2 := t2 * FIXn3n072711026.
			t3 := t3 * FIXn1n501321110.
			z1 := z1 * (0 - FIXn0n899976223).
			z2 := z2 * (0 - FIXn2n562915447).
			z3 := z3 * (0 - FIXn1n961570560).
			z4 := z4 * (0 - FIXn0n390180644).
			z3 := z3 + z5.
			z4 := z4 + z5.
			t0 := t0 + z1 + z3.
			t1 := t1 +z2 +z4.
			t2 := t2 + z2 + z3.
			t3 := t3 + z1 + z4.
			ws at: i put: (t10 + t3) // Pass1Div.
			ws at: (DCTSize * 7 + i) put: (t10 - t3) // Pass1Div.
			ws at: (DCTSize * 1 + i) put: (t11 + t2) // Pass1Div.
			ws at: (DCTSize * 6 + i) put: (t11 - t2) // Pass1Div.
			ws at: (DCTSize * 2 + i) put: (t12 + t1) // Pass1Div.
			ws at: (DCTSize * 5 + i) put: (t12 - t1) // Pass1Div.
			ws at: (DCTSize * 3 + i) put: (t13 + t0) // Pass1Div.
			ws at: (DCTSize * 4 + i) put: (t13 - t0) // Pass1Div]].

	"Pass 2: process rows from work array, store back into anArray"
	0 to: DCTSize2-DCTSize by: DCTSize do:[:i |
		z2 := ws at: i + 2.
		z3 := ws at: i + 6.
		z1 := (z2 + z3) * FIXn0n541196100.
		t2 := z1 + (z3 * (0-FIXn1n847759065)).
		t3 := z1 + (z2 * FIXn0n765366865).
		t0 := (ws at: i) + (ws at: (i + 4)) << ConstBits.
		t1 := (ws at: i) - (ws at: (i + 4)) << ConstBits.
		t10 := t0 + t3.
		t13 := t0 - t3.
		t11 := t1 + t2.
		t12 := t1 -t2.
		t0 := ws at: (i + 7).
		t1 := ws at: (i + 5).
		t2 := ws at: (i + 3).
		t3 := ws at: (i + 1).
		z1 := t0 + t3.
		z2 := t1 + t2.
		z3 := t0 + t2.
		z4 := t1 + t3.
		z5 := (z3 + z4) * FIXn1n175875602.
		t0 := t0 * FIXn0n298631336.
		t1 := t1 * FIXn2n053119869.
		t2 := t2 * FIXn3n072711026.
		t3 := t3 * FIXn1n501321110.
		z1 := z1 * (0-FIXn0n899976223).
		z2 := z2 * (0-FIXn2n562915447).
		z3 := z3 * (0-FIXn1n961570560).
		z4 := z4 * (0-FIXn0n390180644).
		z3 := z3 + z5.
		z4 := z4 + z5.
		t0 := t0 + z1 + z3.
		t1 := t1 + z2 + z4.
		t2 := t2 + z2 + z3.
		t3 := t3 + z1 + z4.
		v := (t10 + t3) // Pass2Div + SampleOffset.
		v := v min: MaxSample. v := v max: 0.
		anArray at: i put: v.
		v := (t10 - t3) // Pass2Div + SampleOffset.
		v := v min: MaxSample. v := v max: 0.
		anArray at: (i + 7) put: v.
		v := (t11 + t2) // Pass2Div + SampleOffset. 
		v := v min: MaxSample. v := v max: 0.
		anArray at: (i + 1) put: v.
		v := (t11 - t2) // Pass2Div + SampleOffset.
		v := v min: MaxSample. v := v max: 0.
		anArray at: (i + 6) put: v.
		v :=  (t12 + t1) // Pass2Div + SampleOffset.
		v := v min: MaxSample. v := v max: 0.
		anArray at: (i + 2) put: v.
		v :=  (t12 - t1) // Pass2Div + SampleOffset.
		v := v min: MaxSample. v := v max: 0.
		anArray at: (i + 5) put: v.
		v := (t13 + t0) // Pass2Div + SampleOffset.
		v := v min: MaxSample. v := v max: 0.
		anArray at: (i + 3) put: v.
		v := (t13 - t0) // Pass2Div + SampleOffset.
		v := v min: MaxSample. v := v max: 0.
		anArray at: (i + 4) put: v].
]

{ #category : #'stream support' }
JPEGReaderPlugin >> jpegDecodeValueFrom: table size: tableSize [
	"Decode the next value in the receiver using the given huffman table."
	| bits bitsNeeded tableIndex value index |
	<var: #table type: 'int *'>
	bitsNeeded := (table at: 0) >> 24.	"Initial bits needed"
	bitsNeeded > MaxBits ifTrue:[^-1].
	tableIndex := 2.							"First real table"
	[true] whileTrue:[
		bits := self getBits: bitsNeeded.		"Get bits"
		bits < 0 ifTrue:[^-1].
		index := tableIndex + bits - 1.
		index >= tableSize ifTrue:[^-1].
		value := table at: index.					"Lookup entry in table"
		(value bitAnd: 16r3F000000) = 0 ifTrue:[^value]. "Check if it is a leaf node"
		"Fetch sub table"
		tableIndex := value bitAnd: 16rFFFF.	"Table offset in low 16 bit"
		bitsNeeded := (value >> 24) bitAnd: 255. "Additional bits in high 8 bit"
		bitsNeeded > MaxBits ifTrue:[^-1]].
	^-1
]

{ #category : #'stream support' }
JPEGReaderPlugin >> loadJPEGStreamFrom: streamOop [
	| oop sz |
	(interpreterProxy isPointers: streamOop) ifFalse:[^false].
	(interpreterProxy slotSizeOf: streamOop) < 5 ifTrue:[^false].
	oop := interpreterProxy fetchPointer: 0 ofObject: streamOop.
	(interpreterProxy isBytes: oop) ifFalse:[^false].
	jsCollection := interpreterProxy firstIndexableField: oop.
	sz := interpreterProxy byteSizeOf: oop.
	jsPosition := interpreterProxy fetchInteger: 1 ofObject: streamOop.
	jsReadLimit := interpreterProxy fetchInteger: 2 ofObject: streamOop.
	jsBitBuffer := interpreterProxy fetchInteger: 3 ofObject: streamOop.
	jsBitCount := interpreterProxy fetchInteger: 4 ofObject: streamOop.
	interpreterProxy failed ifTrue:[^false].
	sz < jsReadLimit ifTrue:[^false].
	(jsPosition < 0 or:[jsPosition >= jsReadLimit]) ifTrue:[^false].
	^true
]

{ #category : #decoding }
JPEGReaderPlugin >> nextSampleCb [
	| dx dy blockIndex sampleIndex sample curX sx sy |
	<inline: true>
	dx := curX := cbComponent at: CurrentXIndex.
	dy := cbComponent at: CurrentYIndex.
	sx := cbComponent at: HScaleIndex.
	sy := cbComponent at: VScaleIndex.
	(sx = 0 and:[sy = 0]) ifFalse:[
		dx := dx // sx.
		dy := dy // sy.
	].
	blockIndex := (dy bitShift: -3) * (cbComponent at: BlockWidthIndex) + (dx bitShift: -3).
	sampleIndex := ((dy bitAnd: 7) bitShift: 3) + (dx bitAnd: 7).
	sample := (cbBlocks at: blockIndex) at: sampleIndex.
	curX := curX + 1.
	curX < ((cbComponent at: MCUWidthIndex) * 8) ifTrue:[
		cbComponent at: CurrentXIndex put: curX.
	] ifFalse:[
		cbComponent at: CurrentXIndex put: 0.
		cbComponent at: CurrentYIndex put: (cbComponent at: CurrentYIndex) + 1.
	].
	^ sample
]

{ #category : #decoding }
JPEGReaderPlugin >> nextSampleCr [
	| dx dy blockIndex sampleIndex sample curX sx sy |
	<inline: true>
	dx := curX := crComponent at: CurrentXIndex.
	dy := crComponent at: CurrentYIndex.
	sx := crComponent at: HScaleIndex.
	sy := crComponent at: VScaleIndex.
	(sx = 0 and:[sy = 0]) ifFalse:[
		dx := dx // sx.
		dy := dy // sy.
	].
	blockIndex := (dy bitShift: -3) * (crComponent at: BlockWidthIndex) + (dx bitShift: -3).
	sampleIndex := ((dy bitAnd: 7) bitShift: 3) + (dx bitAnd: 7).
	sample := (crBlocks at: blockIndex) at: sampleIndex.
	curX := curX + 1.
	curX < ((crComponent at: MCUWidthIndex) * 8) ifTrue:[
		crComponent at: CurrentXIndex put: curX.
	] ifFalse:[
		crComponent at: CurrentXIndex put: 0.
		crComponent at: CurrentYIndex put: (crComponent at: CurrentYIndex) + 1.
	].
	^ sample
]

{ #category : #decoding }
JPEGReaderPlugin >> nextSampleFrom: aComponent blocks: aBlockArray [
	| dx dy blockIndex sampleIndex sample curX sx sy |
	<var: #aComponent type: 'int *'>
	<var: #aBlockArray type: 'int **'>
	<inline: true>
	dx := curX := aComponent at: CurrentXIndex.
	dy := aComponent at: CurrentYIndex.
	sx := aComponent at: HScaleIndex.
	sy := aComponent at: VScaleIndex.
	(sx = 0 and:[sy = 0]) ifFalse:[
		dx := dx // sx.
		dy := dy // sy.
	].
	blockIndex := (dy bitShift: -3) * (aComponent at: BlockWidthIndex) + (dx bitShift: -3).
	sampleIndex := ((dy bitAnd: 7) bitShift: 3) + (dx bitAnd: 7).
	sample := (aBlockArray at: blockIndex) at: sampleIndex.
	curX := curX + 1.
	curX < ((aComponent at: MCUWidthIndex) * 8) ifTrue:[
		aComponent at: CurrentXIndex put: curX.
	] ifFalse:[
		aComponent at: CurrentXIndex put: 0.
		aComponent at: CurrentYIndex put: (aComponent at: CurrentYIndex) + 1.
	].
	^ sample
]

{ #category : #decoding }
JPEGReaderPlugin >> nextSampleY [
	| dx dy blockIndex sampleIndex sample curX sx sy |
	<inline: true>
	dx := curX := yComponent at: CurrentXIndex.
	dy := yComponent at: CurrentYIndex.
	sx := yComponent at: HScaleIndex.
	sy := yComponent at: VScaleIndex.
	(sx = 0 and:[sy = 0]) ifFalse:[
		dx := dx // sx.
		dy := dy // sy.
	].
	blockIndex := (dy bitShift: -3) * (yComponent at: BlockWidthIndex) + (dx bitShift: -3).
	sampleIndex := ((dy bitAnd: 7) bitShift: 3) + (dx bitAnd: 7).
	sample := (yBlocks at: blockIndex) at: sampleIndex.
	curX := curX + 1.
	curX < ((yComponent at: MCUWidthIndex) * 8) ifTrue:[
		yComponent at: CurrentXIndex put: curX.
	] ifFalse:[
		yComponent at: CurrentXIndex put: 0.
		yComponent at: CurrentYIndex put: (yComponent at: CurrentYIndex) + 1.
	].
	^ sample
]

{ #category : #primitives }
JPEGReaderPlugin >> primitiveColorConvertGrayscaleMCU [
	"Requires:
		JPEGColorComponent
		bits
		WordArray with: 3*Integer (residuals)
		ditherMask
	"
	| arrayOop |
	<export: true>
	self stInit.
	interpreterProxy methodArgumentCount = 4
		ifFalse:[^interpreterProxy primitiveFail].
	ditherMask := interpreterProxy stackIntegerValue: 0.
	arrayOop := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	((interpreterProxy isWords: arrayOop) and:[(interpreterProxy slotSizeOf: arrayOop) = 3])
		ifFalse:[^interpreterProxy primitiveFail].
	residuals := interpreterProxy firstIndexableField: arrayOop.
	arrayOop := interpreterProxy stackObjectValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isWords: arrayOop)
		ifFalse:[^interpreterProxy primitiveFail].
	jpegBitsSize := interpreterProxy slotSizeOf: arrayOop.
	jpegBits := interpreterProxy firstIndexableField: arrayOop.
	arrayOop := interpreterProxy stackObjectValue: 3.
	interpreterProxy failed ifTrue:[^nil].
	(self yColorComponentFrom: arrayOop)
		ifFalse:[^interpreterProxy primitiveFail].
	self colorConvertGrayscaleMCU.
	interpreterProxy pop: 4.
]

{ #category : #primitives }
JPEGReaderPlugin >> primitiveColorConvertMCU [
	"Requires:
		Array with: 3*JPEGColorComponent
		bits
		WordArray with: 3*Integer (residuals)
		ditherMask
	"
	| arrayOop |
	<export: true>
	self stInit.
	interpreterProxy methodArgumentCount = 4
		ifFalse:[^interpreterProxy primitiveFail].
	ditherMask := interpreterProxy stackIntegerValue: 0.
	arrayOop := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	((interpreterProxy isWords: arrayOop) and:[(interpreterProxy slotSizeOf: arrayOop) = 3])
		ifFalse:[^interpreterProxy primitiveFail].
	residuals := interpreterProxy firstIndexableField: arrayOop.
	arrayOop := interpreterProxy stackObjectValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isWords: arrayOop)
		ifFalse:[^interpreterProxy primitiveFail].
	jpegBitsSize := interpreterProxy slotSizeOf: arrayOop.
	jpegBits := interpreterProxy firstIndexableField: arrayOop.
	arrayOop := interpreterProxy stackObjectValue: 3.
	interpreterProxy failed ifTrue:[^nil].
	((interpreterProxy isPointers: arrayOop) and:[(interpreterProxy slotSizeOf: arrayOop) = 3])
		ifFalse:[^interpreterProxy primitiveFail].
	(self yColorComponentFrom: (interpreterProxy fetchPointer: 0 ofObject: arrayOop))
		ifFalse:[^interpreterProxy primitiveFail].
	(self cbColorComponentFrom: (interpreterProxy fetchPointer: 1 ofObject: arrayOop))
		ifFalse:[^interpreterProxy primitiveFail].
	(self crColorComponentFrom: (interpreterProxy fetchPointer: 2 ofObject: arrayOop))
		ifFalse:[^interpreterProxy primitiveFail].
	self colorConvertMCU.
	interpreterProxy pop: 4.
]

{ #category : #primitives }
JPEGReaderPlugin >> primitiveDecodeMCU [
	"In:
		anArray 		WordArray of: DCTSize2
		aColorComponent JPEGColorComponent
		dcTable			WordArray
		acTable			WordArray
		stream			JPEGStream
	"
	| arrayOop oop anArray |
	<export: true>
	<var: #anArray type: 'int *'>
	self cCode:'' inSmalltalk:[self stInit].

	interpreterProxy methodArgumentCount = 5 
		ifFalse:[^interpreterProxy primitiveFail].

	oop := interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	(self loadJPEGStreamFrom: oop)
		ifFalse:[^interpreterProxy primitiveFail].

	arrayOop := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isWords: arrayOop)
		ifFalse:[^interpreterProxy primitiveFail].
	acTableSize := interpreterProxy slotSizeOf: arrayOop.
	acTable := interpreterProxy firstIndexableField: arrayOop.

	arrayOop := interpreterProxy stackObjectValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isWords: arrayOop)
		ifFalse:[^interpreterProxy primitiveFail].
	dcTableSize := interpreterProxy slotSizeOf: arrayOop.
	dcTable := interpreterProxy firstIndexableField: arrayOop.

	oop := interpreterProxy stackObjectValue: 3.
	interpreterProxy failed ifTrue:[^nil].
	(self colorComponent: yComponent from: oop)
		ifFalse:[^interpreterProxy primitiveFail].

	arrayOop := interpreterProxy stackObjectValue: 4.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isWords: arrayOop)
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy slotSizeOf: arrayOop) = DCTSize2
		ifFalse:[^interpreterProxy primitiveFail].
	anArray := interpreterProxy firstIndexableField: arrayOop.

	interpreterProxy failed ifTrue:[^nil].

	self decodeBlockInto: anArray component: yComponent.

	interpreterProxy failed ifTrue:[^nil].
	self storeJPEGStreamOn: (interpreterProxy stackValue: 0).
	interpreterProxy 
		storeInteger: PriorDCValueIndex 
		ofObject: (interpreterProxy stackValue: 3) 
		withValue: (yComponent at: PriorDCValueIndex).

	interpreterProxy pop: 5.
]

{ #category : #primitives }
JPEGReaderPlugin >> primitiveIdctInt [
	"In:
		anArray: IntegerArray new: DCTSize2
		qt: IntegerArray new: DCTSize2.
	"
	| arrayOop anArray qt |
	<export: true>
	<var: #anArray type: 'int *'>
	<var: #qt type: 'int *'>
	self cCode:'' inSmalltalk:[self stInit].
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	arrayOop := interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	((interpreterProxy isWords: arrayOop) and:[(interpreterProxy slotSizeOf: arrayOop) = DCTSize2])
		ifFalse:[^interpreterProxy primitiveFail].
	qt := interpreterProxy firstIndexableField: arrayOop.
	arrayOop := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	((interpreterProxy isWords: arrayOop) and:[(interpreterProxy slotSizeOf: arrayOop) = DCTSize2])
		ifFalse:[^interpreterProxy primitiveFail].
	anArray := interpreterProxy firstIndexableField: arrayOop.
	self idctBlockInt: anArray qt: qt.
	interpreterProxy pop: 2.
]

{ #category : #decoding }
JPEGReaderPlugin >> scaleAndSignExtend: aNumber inFieldWidth: w [
	<inline: true>
	aNumber < (1 << (w - 1))
		ifTrue: [^aNumber - (1 << w) + 1]
		ifFalse: [^aNumber]
]

{ #category : #initialize }
JPEGReaderPlugin >> stInit [
	self cCode:'' inSmalltalk:[
		yComponent := CArrayAccessor on: (IntegerArray new: MinComponentSize).
		cbComponent := CArrayAccessor on: (IntegerArray new: MinComponentSize).
		crComponent := CArrayAccessor on: (IntegerArray new: MinComponentSize).
		yBlocks := CArrayAccessor on: (Array new: MaxMCUBlocks).
		crBlocks := CArrayAccessor on: (Array new: MaxMCUBlocks).
		cbBlocks := CArrayAccessor on: (Array new: MaxMCUBlocks).
		jpegNaturalOrder := CArrayAccessor on: #(
			0 1 8 16 9 2 3 10 
			17 24 32 25 18 11 4 5 
			12 19 26 33 40 48 41 34 
			27 20 13 6 7 14 21 28 
			35 42 49 56 57 50 43 36 
			29 22 15 23 30 37 44 51 
			58 59 52 45 38 31 39 46 
			53 60 61 54 47 55 62 63).
	].
]

{ #category : #'stream support' }
JPEGReaderPlugin >> storeJPEGStreamOn: streamOop [
	interpreterProxy storeInteger: 1 ofObject: streamOop withValue: jsPosition.
	interpreterProxy storeInteger: 3 ofObject: streamOop withValue: jsBitBuffer.
	interpreterProxy storeInteger: 4 ofObject: streamOop withValue: jsBitCount.
]

{ #category : #decoding }
JPEGReaderPlugin >> yColorComponentFrom: oop [
	^(self colorComponent: yComponent from: oop)
		and:[self colorComponentBlocks: yBlocks from: oop]
]
