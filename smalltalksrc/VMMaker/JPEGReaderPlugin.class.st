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
		'FIXn0n765366865',
		'PriorDCValueIndex',
		'FIXn1n77200',
		'MaxBits',
		'Pass1Div',
		'DCTSize',
		'FIXn0n390180644',
		'BlockWidthIndex',
		'Pass1Bits',
		'MCUWidthIndex',
		'Pass2Div',
		'FIXn1n175875602',
		'CurrentXIndex',
		'FIXn0n71414',
		'CurrentYIndex',
		'FIXn0n34414',
		'RedIndex',
		'FIXn2n562915447',
		'FIXn0n899976223',
		'FIXn1n847759065',
		'LookaheadSymbolIndex',
		'FIXn1n501321110',
		'FIXn0n298631336',
		'MaxSample',
		'FIXn1n40200',
		'BlueIndex',
		'FIXn3n072711026',
		'MinComponentSize',
		'FIXn0n541196100',
		'LookaheadBitsIndex',
		'HScaleIndex',
		'MaxcodeIndex',
		'SampleOffset',
		'MCUBlockIndex',
		'DCTSize2',
		'GreenIndex',
		'ConstBits',
		'FIXn1n961570560',
		'VScaleIndex',
		'FIXn2n053119869',
		'MaxMCUBlocks'
	],
	#category : #'VMMaker-Plugins'
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
	DCTSize _ 8.
	MaxSample _ (2 raisedToInteger: DCTSize) - 1.
	SampleOffset _ MaxSample // 2.
	DCTSize2 _ DCTSize squared.
	ConstBits _ 13.
	Pass1Bits _ 2.
	Pass1Div _ 1 bitShift: ConstBits - Pass1Bits.
	Pass2Div _ 1 bitShift: ConstBits + Pass1Bits + 3.

	"fixed-point Inverse Discrete Cosine Transform (IDCT) constants"
	FIXn0n298631336 _ 2446.
	FIXn0n390180644 _ 3196.
	FIXn0n541196100 _ 4433.
	FIXn0n765366865 _ 6270.
	FIXn0n899976223 _ 7373.
	FIXn1n175875602 _ 9633.
	FIXn1n501321110 _ 12299.
	FIXn1n847759065 _ 15137.
	FIXn1n961570560 _ 16069.
	FIXn2n053119869 _ 16819.
	FIXn2n562915447 _ 20995.
	FIXn3n072711026 _ 25172.

	"fixed-point color conversion constants"
	FIXn0n34414 _ 22554.
	FIXn0n71414 _ 46802.
	FIXn1n40200 _ 91881.
	FIXn1n77200 _  116130.

	CurrentXIndex _ 0.
	CurrentYIndex _ 1.
	HScaleIndex _ 2.
	VScaleIndex _ 3.
	MCUBlockIndex _ 4.
	BlockWidthIndex _ 5.
	MCUWidthIndex _ 8.
	PriorDCValueIndex _ 10.
	MinComponentSize _ 11.

	RedIndex _ 0.
	GreenIndex _ 1.
	BlueIndex _ 2.

	MaxMCUBlocks _ 128.
	MaxBits _ 16.
]

{ #category : #decoding }
JPEGReaderPlugin >> cbColorComponentFrom: oop [
	^(self colorComponent: cbComponent from: oop)
		and:[self colorComponentBlocks: cbBlocks from: oop]
]

{ #category : #decoding }
JPEGReaderPlugin >> colorComponent: aColorComponent from: oop [
	self var: #aColorComponent type: 'int *'.
	(interpreterProxy isIntegerObject: oop) ifTrue:[^false].
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
	self var: #blocks type: 'int **'.
	(interpreterProxy isIntegerObject: oop) ifTrue:[^false].
	(interpreterProxy isPointers: oop) ifFalse:[^false].
	(interpreterProxy slotSizeOf: oop) < MinComponentSize ifTrue:[^false].

	arrayOop _ interpreterProxy fetchPointer: MCUBlockIndex ofObject: oop.
	(interpreterProxy isIntegerObject: arrayOop) ifTrue:[^false].
	(interpreterProxy isPointers: arrayOop) ifFalse:[^false].
	max _ interpreterProxy slotSizeOf: arrayOop.
	max > MaxMCUBlocks ifTrue:[^false].
	0 to: max-1 do:[:i|
		blockOop _ interpreterProxy fetchPointer: i ofObject: arrayOop.
		(interpreterProxy isIntegerObject: blockOop) ifTrue:[^false].
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
		y _ self nextSampleY.
		y _ y + (residuals at: GreenIndex).
		y _ y min: MaxSample.
		residuals at: GreenIndex put: (y bitAnd: ditherMask).
		y _ y bitAnd: MaxSample - ditherMask.
		y _ y max: 1.
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
		y _ self nextSampleY.
		cb _ self nextSampleCb.
		cb _ cb - SampleOffset.
		cr _ self nextSampleCr.
		cr _ cr - SampleOffset.
		red _ y + ((FIXn1n40200 * cr) // 65536) + (residuals at: RedIndex).
		red _ red min: MaxSample. red _ red max: 0.
		residuals at: RedIndex put: (red bitAnd: ditherMask).
		red _ red bitAnd: MaxSample - ditherMask.
		red _ red max: 1.
		green _ y - ((FIXn0n34414 * cb) // 65536) -
			((FIXn0n71414 * cr) // 65536) + (residuals at: GreenIndex).
		green _ green min: MaxSample. green _ green max: 0.
		residuals at: GreenIndex put: (green bitAnd: ditherMask).
		green _ green bitAnd: MaxSample - ditherMask.
		green _ green max: 1.
		blue _ y + ((FIXn1n77200 * cb) // 65536) + (residuals at: BlueIndex).
		blue _ blue min: MaxSample. blue _ blue max: 0.
		residuals at: BlueIndex put: (blue bitAnd: ditherMask).
		blue _ blue bitAnd: MaxSample - ditherMask.
		blue _ blue max: 1.
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
	self var: #anArray type: 'int *'.
	self var: #aColorComponent type: 'int *'.
	byte _ self jpegDecodeValueFrom: dcTable size: dcTableSize.
	byte < 0 ifTrue:[^interpreterProxy primitiveFail].
	byte ~= 0 ifTrue: [
		bits _ self getBits: byte.
		byte _ self scaleAndSignExtend: bits inFieldWidth: byte].
	byte _ aColorComponent 
				at: PriorDCValueIndex 
				put: (aColorComponent at: PriorDCValueIndex) + byte.
	anArray at: 0 put: byte.
	1 to: DCTSize2 - 1 do:[:i| anArray at: i put: 0].
	index _ 1.
	[index < DCTSize2] whileTrue:[
		byte _ self jpegDecodeValueFrom: acTable size: acTableSize.
		byte < 0 ifTrue:[^interpreterProxy primitiveFail].
		zeroCount _ byte >> 4.
		byte _ byte bitAnd: 16r0F.
		byte ~= 0 ifTrue:[
			index _ index + zeroCount.
			bits _  self getBits: byte.
			byte _ self scaleAndSignExtend: bits inFieldWidth: byte.
			(index < 0 or:[index >= DCTSize2]) ifTrue:[^interpreterProxy primitiveFail].
			anArray at:	 (jpegNaturalOrder at: index) put: byte.
		] ifFalse:[
			zeroCount = 15 ifTrue: [index _ index + zeroCount] ifFalse: [^ nil].
		].
		index _ index + 1
	].
]

{ #category : #'stream support' }
JPEGReaderPlugin >> fillBuffer [
	| byte |
	[jsBitCount <= 16] whileTrue:[
		jsPosition < jsReadLimit ifFalse:[^jsBitCount].
		byte _ jsCollection at: jsPosition.
		jsPosition _ jsPosition + 1.
		byte = 16rFF ifTrue:["peek for 00"
			((jsPosition < jsReadLimit) and:[(jsCollection at: jsPosition) = 16r00]) ifFalse:[
				jsPosition _ jsPosition - 1.
				^jsBitCount].
			jsPosition _ jsPosition + 1].
		jsBitBuffer _ (jsBitBuffer bitShift: 8) bitOr: byte.
		jsBitCount _ jsBitCount + 8].
	^jsBitCount
]

{ #category : #'stream support' }
JPEGReaderPlugin >> getBits: requestedBits [
	| value |
	requestedBits > jsBitCount ifTrue:[
		self fillBuffer.
		requestedBits > jsBitCount ifTrue:[^-1]].
	value _ jsBitBuffer bitShift: (requestedBits - jsBitCount).
	jsBitBuffer _ jsBitBuffer bitAnd: (1 bitShift: (jsBitCount - requestedBits)) -1.
	jsBitCount _ jsBitCount - requestedBits.
	^ value
]

{ #category : #decoding }
JPEGReaderPlugin >> idctBlockInt: anArray qt: qt [
	| ws anACTerm dcval z2 z3 z1 t2 t3 t0 t1 t10 t13 t11 t12 z4 z5 v |
	self var: #anArray type:'int *'.
	self var: #qt type:'int *'.
	self var: #ws declareC:'int ws[64]'.
	self cCode:'' inSmalltalk:[ws _ CArrayAccessor on: (IntegerArray new: 64)].
	"Pass 1: process columns from anArray, store into work array"
	0 to: DCTSize-1 do:[:i |
		anACTerm _ -1.
		1 to: DCTSize-1 do:[:row|
			anACTerm = -1 ifTrue:[
				(anArray at: row * DCTSize + i) = 0 ifFalse:[anACTerm _ row]]].
		anACTerm = -1 ifTrue:[
			dcval _ (anArray at: i) * (qt at: 0) bitShift: Pass1Bits.
			0 to: DCTSize-1 do: [:j | ws at: (j * DCTSize + i) put: dcval]
		] ifFalse:[
			z2 _ (anArray at: (DCTSize * 2 + i)) * (qt at: (DCTSize * 2 + i)).
			z3 _ (anArray at: (DCTSize * 6 + i)) * (qt at: (DCTSize * 6 + i)).
			z1 _ (z2 + z3) * FIXn0n541196100.
			t2 _ z1 + (z3 * (0 - FIXn1n847759065)).
			t3 _ z1 + (z2 * FIXn0n765366865).
			z2 _ (anArray at: i) * (qt at: i).
			z3 _ (anArray at: (DCTSize * 4 + i)) * (qt at: (DCTSize * 4 + i)).
			t0 _ (z2 + z3) bitShift: ConstBits.
			t1 _ (z2 - z3) bitShift: ConstBits.
			t10 _ t0 + t3.
			t13 _ t0 - t3.
			t11 _ t1 + t2.
			t12 _ t1 - t2.
			t0 _ (anArray at: (DCTSize * 7 + i)) * (qt at: (DCTSize * 7 + i)).
			t1 _ (anArray at: (DCTSize * 5 + i)) * (qt at: (DCTSize * 5 + i)).
			t2 _ (anArray at: (DCTSize * 3 + i)) * (qt at: (DCTSize * 3 + i)).
			t3 _ (anArray at: (DCTSize + i)) * (qt at: (DCTSize + i)).
			z1 _ t0 + t3.
			z2 _ t1 + t2.
			z3 _ t0 + t2.
			z4 _ t1 + t3.
			z5 _ (z3 + z4) * FIXn1n175875602.
			t0 _ t0 * FIXn0n298631336.
			t1 _ t1 * FIXn2n053119869.
			t2 _ t2 * FIXn3n072711026.
			t3 _ t3 * FIXn1n501321110.
			z1 _ z1 * (0 - FIXn0n899976223).
			z2 _ z2 * (0 - FIXn2n562915447).
			z3 _ z3 * (0 - FIXn1n961570560).
			z4 _ z4 * (0 - FIXn0n390180644).
			z3 _ z3 + z5.
			z4 _ z4 + z5.
			t0 _ t0 + z1 + z3.
			t1 _ t1 +z2 +z4.
			t2 _ t2 + z2 + z3.
			t3 _ t3 + z1 + z4.
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
		z2 _ ws at: i + 2.
		z3 _ ws at: i + 6.
		z1 _ (z2 + z3) * FIXn0n541196100.
		t2 _ z1 + (z3 * (0-FIXn1n847759065)).
		t3 _ z1 + (z2 * FIXn0n765366865).
		t0 _ (ws at: i) + (ws at: (i + 4)) bitShift: ConstBits.
		t1 _ (ws at: i) - (ws at: (i + 4)) bitShift: ConstBits.
		t10 _ t0 + t3.
		t13 _ t0 - t3.
		t11 _ t1 + t2.
		t12 _ t1 -t2.
		t0 _ ws at: (i + 7).
		t1 _ ws at: (i + 5).
		t2 _ ws at: (i + 3).
		t3 _ ws at: (i + 1).
		z1 _ t0 + t3.
		z2 _ t1 + t2.
		z3 _ t0 + t2.
		z4 _ t1 + t3.
		z5 _ (z3 + z4) * FIXn1n175875602.
		t0 _ t0 * FIXn0n298631336.
		t1 _ t1 * FIXn2n053119869.
		t2 _ t2 * FIXn3n072711026.
		t3 _ t3 * FIXn1n501321110.
		z1 _ z1 * (0-FIXn0n899976223).
		z2 _ z2 * (0-FIXn2n562915447).
		z3 _ z3 * (0-FIXn1n961570560).
		z4 _ z4 * (0-FIXn0n390180644).
		z3 _ z3 + z5.
		z4 _ z4 + z5.
		t0 _ t0 + z1 + z3.
		t1 _ t1 + z2 + z4.
		t2 _ t2 + z2 + z3.
		t3 _ t3 + z1 + z4.
		v _ (t10 + t3) // Pass2Div + SampleOffset.
		v _ v min: MaxSample. v _ v max: 0.
		anArray at: i put: v.
		v _ (t10 - t3) // Pass2Div + SampleOffset.
		v _ v min: MaxSample. v _ v max: 0.
		anArray at: (i + 7) put: v.
		v _ (t11 + t2) // Pass2Div + SampleOffset. 
		v _ v min: MaxSample. v _ v max: 0.
		anArray at: (i + 1) put: v.
		v _ (t11 - t2) // Pass2Div + SampleOffset.
		v _ v min: MaxSample. v _ v max: 0.
		anArray at: (i + 6) put: v.
		v _  (t12 + t1) // Pass2Div + SampleOffset.
		v _ v min: MaxSample. v _ v max: 0.
		anArray at: (i + 2) put: v.
		v _  (t12 - t1) // Pass2Div + SampleOffset.
		v _ v min: MaxSample. v _ v max: 0.
		anArray at: (i + 5) put: v.
		v _ (t13 + t0) // Pass2Div + SampleOffset.
		v _ v min: MaxSample. v _ v max: 0.
		anArray at: (i + 3) put: v.
		v _ (t13 - t0) // Pass2Div + SampleOffset.
		v _ v min: MaxSample. v _ v max: 0.
		anArray at: (i + 4) put: v].
]

{ #category : #'stream support' }
JPEGReaderPlugin >> jpegDecodeValueFrom: table size: tableSize [
	"Decode the next value in the receiver using the given huffman table."
	| bits bitsNeeded tableIndex value index |
	self var: #table declareC:'int *table'.
	bitsNeeded _ (table at: 0) >> 24.	"Initial bits needed"
	bitsNeeded > MaxBits ifTrue:[^-1].
	tableIndex _ 2.							"First real table"
	[true] whileTrue:[
		bits _ self getBits: bitsNeeded.		"Get bits"
		bits < 0 ifTrue:[^-1].
		index _ tableIndex + bits - 1.
		index >= tableSize ifTrue:[^-1].
		value _ table at: index.					"Lookup entry in table"
		(value bitAnd: 16r3F000000) = 0 ifTrue:[^value]. "Check if it is a leaf node"
		"Fetch sub table"
		tableIndex _ value bitAnd: 16rFFFF.	"Table offset in low 16 bit"
		bitsNeeded _ (value >> 24) bitAnd: 255. "Additional bits in high 8 bit"
		bitsNeeded > MaxBits ifTrue:[^-1]].
	^-1
]

{ #category : #'stream support' }
JPEGReaderPlugin >> loadJPEGStreamFrom: streamOop [
	| oop sz |
	(interpreterProxy slotSizeOf: streamOop) < 5 ifTrue:[^false].
	(interpreterProxy isPointers: streamOop) ifFalse:[^false].
	oop _ interpreterProxy fetchPointer: 0 ofObject: streamOop.
	(interpreterProxy isIntegerObject: oop) ifTrue:[^false].
	(interpreterProxy isBytes: oop) ifFalse:[^false].
	jsCollection _ interpreterProxy firstIndexableField: oop.
	sz _ interpreterProxy byteSizeOf: oop.
	jsPosition _ interpreterProxy fetchInteger: 1 ofObject: streamOop.
	jsReadLimit _ interpreterProxy fetchInteger: 2 ofObject: streamOop.
	jsBitBuffer _ interpreterProxy fetchInteger: 3 ofObject: streamOop.
	jsBitCount _ interpreterProxy fetchInteger: 4 ofObject: streamOop.
	interpreterProxy failed ifTrue:[^false].
	sz < jsReadLimit ifTrue:[^false].
	(jsPosition < 0 or:[jsPosition >= jsReadLimit]) ifTrue:[^false].
	^true
]

{ #category : #decoding }
JPEGReaderPlugin >> nextSampleCb [
	| dx dy blockIndex sampleIndex sample curX sx sy |
	self inline: true.
	dx _ curX _ cbComponent at: CurrentXIndex.
	dy _ cbComponent at: CurrentYIndex.
	sx _ cbComponent at: HScaleIndex.
	sy _ cbComponent at: VScaleIndex.
	(sx = 0 and:[sy = 0]) ifFalse:[
		dx _ dx // sx.
		dy _ dy // sy.
	].
	blockIndex _ (dy bitShift: -3) * (cbComponent at: BlockWidthIndex) + (dx bitShift: -3).
	sampleIndex _ ((dy bitAnd: 7) bitShift: 3) + (dx bitAnd: 7).
	sample _ (cbBlocks at: blockIndex) at: sampleIndex.
	curX _ curX + 1.
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
	self inline: true.
	dx _ curX _ crComponent at: CurrentXIndex.
	dy _ crComponent at: CurrentYIndex.
	sx _ crComponent at: HScaleIndex.
	sy _ crComponent at: VScaleIndex.
	(sx = 0 and:[sy = 0]) ifFalse:[
		dx _ dx // sx.
		dy _ dy // sy.
	].
	blockIndex _ (dy bitShift: -3) * (crComponent at: BlockWidthIndex) + (dx bitShift: -3).
	sampleIndex _ ((dy bitAnd: 7) bitShift: 3) + (dx bitAnd: 7).
	sample _ (crBlocks at: blockIndex) at: sampleIndex.
	curX _ curX + 1.
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
	self var: #aComponent type: 'int *'.
	self var: #aBlockArray type: 'int **'.
	self inline: true.
	dx _ curX _ aComponent at: CurrentXIndex.
	dy _ aComponent at: CurrentYIndex.
	sx _ aComponent at: HScaleIndex.
	sy _ aComponent at: VScaleIndex.
	(sx = 0 and:[sy = 0]) ifFalse:[
		dx _ dx // sx.
		dy _ dy // sy.
	].
	blockIndex _ (dy bitShift: -3) * (aComponent at: BlockWidthIndex) + (dx bitShift: -3).
	sampleIndex _ ((dy bitAnd: 7) bitShift: 3) + (dx bitAnd: 7).
	sample _ (aBlockArray at: blockIndex) at: sampleIndex.
	curX _ curX + 1.
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
	self inline: true.
	dx _ curX _ yComponent at: CurrentXIndex.
	dy _ yComponent at: CurrentYIndex.
	sx _ yComponent at: HScaleIndex.
	sy _ yComponent at: VScaleIndex.
	(sx = 0 and:[sy = 0]) ifFalse:[
		dx _ dx // sx.
		dy _ dy // sy.
	].
	blockIndex _ (dy bitShift: -3) * (yComponent at: BlockWidthIndex) + (dx bitShift: -3).
	sampleIndex _ ((dy bitAnd: 7) bitShift: 3) + (dx bitAnd: 7).
	sample _ (yBlocks at: blockIndex) at: sampleIndex.
	curX _ curX + 1.
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
	self export: true.
	self stInit.
	interpreterProxy methodArgumentCount = 4
		ifFalse:[^interpreterProxy primitiveFail].
	ditherMask _ interpreterProxy stackIntegerValue: 0.
	arrayOop _ interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	((interpreterProxy isWords: arrayOop) and:[(interpreterProxy slotSizeOf: arrayOop) = 3])
		ifFalse:[^interpreterProxy primitiveFail].
	residuals _ interpreterProxy firstIndexableField: arrayOop.
	arrayOop _ interpreterProxy stackObjectValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isWords: arrayOop)
		ifFalse:[^interpreterProxy primitiveFail].
	jpegBitsSize _ interpreterProxy slotSizeOf: arrayOop.
	jpegBits _ interpreterProxy firstIndexableField: arrayOop.
	arrayOop _ interpreterProxy stackObjectValue: 3.
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
	self export: true.
	self stInit.
	interpreterProxy methodArgumentCount = 4
		ifFalse:[^interpreterProxy primitiveFail].
	ditherMask _ interpreterProxy stackIntegerValue: 0.
	arrayOop _ interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	((interpreterProxy isWords: arrayOop) and:[(interpreterProxy slotSizeOf: arrayOop) = 3])
		ifFalse:[^interpreterProxy primitiveFail].
	residuals _ interpreterProxy firstIndexableField: arrayOop.
	arrayOop _ interpreterProxy stackObjectValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isWords: arrayOop)
		ifFalse:[^interpreterProxy primitiveFail].
	jpegBitsSize _ interpreterProxy slotSizeOf: arrayOop.
	jpegBits _ interpreterProxy firstIndexableField: arrayOop.
	arrayOop _ interpreterProxy stackObjectValue: 3.
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
	self export: true.
	self var: #anArray type: 'int *'.
	self cCode:'' inSmalltalk:[self stInit].

	interpreterProxy methodArgumentCount = 5 
		ifFalse:[^interpreterProxy primitiveFail].

	oop _ interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	(self loadJPEGStreamFrom: oop)
		ifFalse:[^interpreterProxy primitiveFail].

	arrayOop _ interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isWords: arrayOop)
		ifFalse:[^interpreterProxy primitiveFail].
	acTableSize _ interpreterProxy slotSizeOf: arrayOop.
	acTable _ interpreterProxy firstIndexableField: arrayOop.

	arrayOop _ interpreterProxy stackObjectValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isWords: arrayOop)
		ifFalse:[^interpreterProxy primitiveFail].
	dcTableSize _ interpreterProxy slotSizeOf: arrayOop.
	dcTable _ interpreterProxy firstIndexableField: arrayOop.

	oop _ interpreterProxy stackObjectValue: 3.
	interpreterProxy failed ifTrue:[^nil].
	(self colorComponent: yComponent from: oop)
		ifFalse:[^interpreterProxy primitiveFail].

	arrayOop _ interpreterProxy stackObjectValue: 4.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isWords: arrayOop)
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy slotSizeOf: arrayOop) = DCTSize2
		ifFalse:[^interpreterProxy primitiveFail].
	anArray _ interpreterProxy firstIndexableField: arrayOop.

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
	self export: true.
	self var: #anArray type: 'int *'.
	self var: #qt type: 'int *'.
	self cCode:'' inSmalltalk:[self stInit].
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	arrayOop _ interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	((interpreterProxy isWords: arrayOop) and:[(interpreterProxy slotSizeOf: arrayOop) = DCTSize2])
		ifFalse:[^interpreterProxy primitiveFail].
	qt _ interpreterProxy firstIndexableField: arrayOop.
	arrayOop _ interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	((interpreterProxy isWords: arrayOop) and:[(interpreterProxy slotSizeOf: arrayOop) = DCTSize2])
		ifFalse:[^interpreterProxy primitiveFail].
	anArray _ interpreterProxy firstIndexableField: arrayOop.
	self idctBlockInt: anArray qt: qt.
	interpreterProxy pop: 2.
]

{ #category : #decoding }
JPEGReaderPlugin >> scaleAndSignExtend: aNumber inFieldWidth: w [
	self inline: true.
	aNumber < (1 bitShift: (w - 1))
		ifTrue: [^aNumber - (1 bitShift: w) + 1]
		ifFalse: [^aNumber]
]

{ #category : #initialize }
JPEGReaderPlugin >> stInit [
	self cCode:'' inSmalltalk:[
		yComponent _ CArrayAccessor on: (IntegerArray new: MinComponentSize).
		cbComponent _ CArrayAccessor on: (IntegerArray new: MinComponentSize).
		crComponent _ CArrayAccessor on: (IntegerArray new: MinComponentSize).
		yBlocks _ CArrayAccessor on: (Array new: MaxMCUBlocks).
		crBlocks _ CArrayAccessor on: (Array new: MaxMCUBlocks).
		cbBlocks _ CArrayAccessor on: (Array new: MaxMCUBlocks).
		jpegNaturalOrder _ CArrayAccessor on: #(
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
