"
This class implements BitBlt, much as specified in the Blue Book spec.

Performance has been enhanced through the use of pointer variables such as sourceIndex and destIndex, and by separating several special cases of the inner loop.

Operation has been extended to color, with support for 1, 2, 4, 8, 16, and 32-bit pixel sizes.  Conversion between different pixel sizes is facilitated by accepting an optional color map.

In addition to the original 16 combination rules, this BitBlt supports
	16	fail (for old paint mode)
	17	fail (for old mask mode)
	18	sourceWord + destinationWord
	19	sourceWord - destinationWord
	20	rgbAdd: sourceWord with: destinationWord
	21	rgbSub: sourceWord with: destinationWord
	22	OLDrgbDiff: sourceWord with: destinationWord
	23	OLDtallyIntoMap: destinationWord -- old vers doesn't clip to bit boundary
	24	alphaBlend: sourceWord with: destinationWord
	25	pixPaint: sourceWord with: destinationWord
	26	pixMask: sourceWord with: destinationWord
	27	rgbMax: sourceWord with: destinationWord
	28	rgbMin: sourceWord with: destinationWord
	29	rgbMin: sourceWord bitInvert32 with: destinationWord
	30	alphaBlendConst: sourceWord with: destinationWord -- alpha passed as an arg
	31	alphaPaintConst: sourceWord with: destinationWord -- alpha passed as an arg
	32	rgbDiff: sourceWord with: destinationWord
	33	tallyIntoMap: destinationWord
	34	alphaBlendScaled: sourceWord with: destinationWord

This implementation has also been fitted with an experimental ""warp drive"" that allows abritrary scaling and rotation (and even limited affine deformations) with all BitBlt storage modes supported.

To add a new rule to BitBlt...
	1.  add the new rule method or methods in the category 'combination rules' of BBSim
	2.  describe it in the class comment  of BBSim and in the class comment for BitBlt
	3.  add refs to initializeRuleTable in proper positions
	4.  add refs to initBBOpTable, following the pattern

"
Class {
	#name : #BitBltSimulation,
	#superclass : #InterpreterPlugin,
	#instVars : [
		'destForm',
		'sourceForm',
		'halftoneForm',
		'combinationRule',
		'destX',
		'destY',
		'width',
		'height',
		'sourceX',
		'sourceY',
		'clipX',
		'clipY',
		'clipWidth',
		'clipHeight',
		'sourceWidth',
		'sourceHeight',
		'sourceDepth',
		'sourcePitch',
		'sourceBits',
		'sourcePPW',
		'sourceMSB',
		'destWidth',
		'destHeight',
		'destDepth',
		'destPitch',
		'destBits',
		'destPPW',
		'destMSB',
		'bitCount',
		'skew',
		'mask1',
		'mask2',
		'preload',
		'nWords',
		'destMask',
		'hDir',
		'vDir',
		'sourceIndex',
		'sourceDelta',
		'destIndex',
		'destDelta',
		'sx',
		'sy',
		'dx',
		'dy',
		'bbW',
		'bbH',
		'halftoneHeight',
		'noSource',
		'noHalftone',
		'halftoneBase',
		'sourceAlpha',
		'srcBitShift',
		'dstBitShift',
		'bitBltOop',
		'affectedL',
		'affectedR',
		'affectedT',
		'affectedB',
		'opTable',
		'maskTable',
		'ditherMatrix4x4',
		'ditherThresholds16',
		'ditherValues16',
		'hasSurfaceLock',
		'warpSrcShift',
		'warpSrcMask',
		'warpAlignShift',
		'warpAlignMask',
		'warpBitShiftTable',
		'querySurfaceFn',
		'lockSurfaceFn',
		'unlockSurfaceFn',
		'isWarping',
		'cmFlags',
		'cmMask',
		'cmShiftTable',
		'cmMaskTable',
		'cmLookupTable',
		'cmBitsPerColor',
		'dither8Lookup'
	],
	#classVars : [
		'CrossedX',
		'FormWidthIndex',
		'BBXTableIndex',
		'FormHeightIndex',
		'BBSourceYIndex',
		'BBSourceXIndex',
		'BBRuleIndex',
		'BBWarpBase',
		'BBColorMapIndex',
		'OpTable',
		'BBClipHeightIndex',
		'BBHalftoneFormIndex',
		'EndOfRun',
		'JitBltHookSize',
		'BBDestFormIndex',
		'GreenIndex',
		'BBClipYIndex',
		'ColorMapNewStyle',
		'FixedPt1',
		'FormBitsIndex',
		'RedIndex',
		'BBClipXIndex',
		'BlueIndex',
		'AlphaIndex',
		'BinaryPoint',
		'BBLastIndex',
		'ColorMapIndexedPart',
		'BBHeightIndex',
		'BBSourceFormIndex',
		'BBWidthIndex',
		'FormDepthIndex',
		'OpTableSize',
		'BBClipWidthIndex',
		'BBDestYIndex',
		'AllOnes',
		'BBDestXIndex',
		'ColorMapFixedPart',
		'ColorMapPresent'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #'system simulation' }
BitBltSimulation class >> copyBitsFrom: aBitBlt [
	"Simulate the copyBits primitive"
	| proxy bb |
	proxy _ InterpreterProxy new.
	proxy loadStackFrom: thisContext sender home.
	bb _ self simulatorClass new.
	bb initialiseModule.
	bb setInterpreter: proxy.
	proxy success: (bb loadBitBltFrom: aBitBlt).
	bb copyBits.
	proxy failed ifFalse:[
		proxy showDisplayBits: aBitBlt destForm Left: bb affectedLeft Top: bb affectedTop Right: bb affectedRight Bottom: bb affectedBottom].
	^proxy stackValue: 0
]

{ #category : #translation }
BitBltSimulation class >> declareCVarsIn: aCCodeGenerator [
	aCCodeGenerator var: 'opTable'
		declareC: 'void *opTable[' , OpTableSize printString , ']'.
	aCCodeGenerator var: 'maskTable'
		declareC:'int maskTable[33] = {
0, 1, 3, 0, 15, 31, 0, 0, 255, 0, 0, 0, 0, 0, 0, 0, 65535,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1
}'.
	aCCodeGenerator var: 'ditherMatrix4x4'
		declareC:'const int ditherMatrix4x4[16] = {
0,	8,	2,	10,
12,	4,	14,	6,
3,	11,	1,	9,
15,	7,	13,	5
}'.
	aCCodeGenerator var: 'ditherThresholds16'
		declareC:'const int ditherThresholds16[8] = { 0, 2, 4, 6, 8, 12, 14, 16 }'.
	aCCodeGenerator var: 'ditherValues16'
		declareC:'const int ditherValues16[32] = {
0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30
}'.

	aCCodeGenerator var: 'warpBitShiftTable'
		declareC:'int warpBitShiftTable[32]'.

	aCCodeGenerator var:'cmShiftTable' 
		declareC:'int *cmShiftTable'.
	aCCodeGenerator var:'cmMaskTable' 
		declareC:'unsigned int *cmMaskTable'.
	aCCodeGenerator var:'cmLookupTable' 
		declareC:'unsigned int *cmLookupTable'.

	aCCodeGenerator var: 'dither8Lookup'
		declareC:' unsigned char dither8Lookup[4096]'.

	aCCodeGenerator var: 'querySurfaceFn' declareC: 'void *querySurfaceFn'.
	aCCodeGenerator var: 'lockSurfaceFn' declareC: 'void *lockSurfaceFn'.
	aCCodeGenerator var: 'unlockSurfaceFn' declareC: 'void *unlockSurfaceFn'
]

{ #category : #initialization }
BitBltSimulation class >> initialize [
	"BitBltSimulation initialize"

	self initializeRuleTable.

	"Mask constants"
	AllOnes _ 16rFFFFFFFF.
	BinaryPoint _ 14.
	FixedPt1 _ 1 << BinaryPoint.  "Value of 1.0 in Warp's fixed-point representation"
 
	"Indices into stopConditions for scanning"
	EndOfRun _ 257.
	CrossedX _ 258.
 
	"Form fields"
	FormBitsIndex _ 0.
	FormWidthIndex _ 1.
	FormHeightIndex _ 2.
	FormDepthIndex _ 3.
 
	"BitBlt fields"
	BBDestFormIndex _ 0.
	BBSourceFormIndex _ 1.
	BBHalftoneFormIndex _ 2.
	BBRuleIndex _ 3.
	BBDestXIndex _ 4.
	BBDestYIndex _ 5.
	BBWidthIndex _ 6.
	BBHeightIndex _ 7.
	BBSourceXIndex _ 8.
	BBSourceYIndex _ 9.
	BBClipXIndex _ 10.
	BBClipYIndex _ 11.
	BBClipWidthIndex _ 12.
	BBClipHeightIndex _ 13.
	BBColorMapIndex _ 14.
	BBWarpBase _ 15.
	BBLastIndex _ 15.
	BBXTableIndex _ 16.

	"RGBA indexes"
	RedIndex _ 0.
	GreenIndex _ 1.
	BlueIndex _ 2.
	AlphaIndex _ 3.

	"Color map flags"
	ColorMapPresent _ 1.		"do we have one?"
	ColorMapFixedPart _ 2.		"does it have a fixed part?"
	ColorMapIndexedPart _ 4.	"does it have an indexed part?"
	ColorMapNewStyle _ 8.		"new style color map"
]

{ #category : #initialization }
BitBltSimulation class >> initializeRuleTable [
	"BitBltSimulation initializeRuleTable"
	"**WARNING** You MUST change initBBOpTable if you change this"
	OpTable _ #(
		"0" clearWord:with:
		"1" bitAnd:with:
		"2" bitAndInvert:with:
		"3" sourceWord:with:
		"4" bitInvertAnd:with:
		"5" destinationWord:with:
		"6" bitXor:with:
		"7" bitOr:with:
		"8" bitInvertAndInvert:with:
		"9" bitInvertXor:with:
		"10" bitInvertDestination:with:
		"11" bitOrInvert:with:
		"12" bitInvertSource:with:
		"13" bitInvertOr:with:
		"14" bitInvertOrInvert:with:
		"15" destinationWord:with:
		"16" destinationWord:with: "unused - was old paint"
		"17" destinationWord:with: "unused - was old mask"
		"18" addWord:with:
		"19" subWord:with:
		"20" rgbAdd:with:
		"21" rgbSub:with:
		"22" OLDrgbDiff:with:
		"23" OLDtallyIntoMap:with:
		"24" alphaBlend:with:
		"25" pixPaint:with:
		"26" pixMask:with:
		"27" rgbMax:with:
		"28" rgbMin:with:
		"29" rgbMinInvert:with:
		"30" alphaBlendConst:with:
		"31" alphaPaintConst:with:
		"32" rgbDiff:with:
		"33" tallyIntoMap:with:
		"34" alphaBlendScaled:with:

		"35" alphaBlendScaled:with:	"unused here - only used by FXBlt"
		"36" alphaBlendScaled:with:	"unused here - only used by FXBlt"
		"37" rgbMul:with:
		"38" pixSwap:with:
		"39" pixClear:with:
		"40" fixAlpha:with:
	).
	OpTableSize _ OpTable size + 1.  "0-origin indexing"

]

{ #category : #translation }
BitBltSimulation class >> moduleName [
	^'BitBltPlugin'
]

{ #category : #translation }
BitBltSimulation class >> opTable [

	^ OpTable

]

{ #category : #translation }
BitBltSimulation class >> requiredMethodNames [
	^self opTable asSet
]

{ #category : #'system simulation' }
BitBltSimulation class >> simulatorClass [
	^BitBltSimulator
]

{ #category : #testing }
BitBltSimulation class >> test2 [
	"BitBltSimulation test2"
	| f |
	Display fillWhite: (0 @ 0 extent: 300 @ 140).
	1 to: 12 do: [:i | 
			f _ (Form extent: i @ 5) fillBlack.
			0 to: 20 do: [:x | f displayOn: Display at: x * 13 @ (i * 10)]]
]

{ #category : #testing }
BitBltSimulation class >> timingTest: extent [ 
	"BitBltSimulation timingTest: 640@480"
	| f f2 map |
	f _ Form extent: extent depth: 8.
	f2 _ Form extent: extent depth: 8.
	map _ Bitmap new: 1 << f2 depth.
	^ Array
		with: (Time millisecondsToRun: [100 timesRepeat: [f fillWithColor: Color white]])
		with: (Time millisecondsToRun: [100 timesRepeat: [f copy: f boundingBox from: 0 @ 0 in: f2 rule: Form over]])
		with: (Time millisecondsToRun: [100 timesRepeat: [f copyBits: f boundingBox from: f2 at: 0 @ 0 colorMap: map]])
]

{ #category : #'system simulation' }
BitBltSimulation class >> warpBitsFrom: aBitBlt [
	"Simulate the warpBits primitive"
	| proxy bb |
	proxy _ InterpreterProxy new.
	proxy loadStackFrom: thisContext sender home.
	bb _ self simulatorClass new.
	bb initialiseModule.
	bb setInterpreter: proxy.
	proxy success: (bb loadWarpBltFrom: aBitBlt).
	bb warpBits.
	proxy failed ifFalse:[
		proxy showDisplayBits: aBitBlt destForm Left: bb affectedLeft Top: bb affectedTop Right: bb affectedRight Bottom: bb affectedBottom].
	^proxy stackValue: 0
]

{ #category : #'combination rules' }
BitBltSimulation >> OLDrgbDiff: sourceWord with: destinationWord [
	"Subract the pixels in the source and destination, color by color,
	and return the sum of the absolute value of all the differences.
	For non-rgb, XOR the two and return the number of differing pixels.
	Note that the region is not clipped to bit boundaries, but only to the
	nearest (enclosing) word.  This is because copyLoop does not do
	pre-merge masking.  For accurate results, you must subtract the
	values obtained from the left and right fringes."
	| diff pixMask |
	self inline: false.
	destDepth < 16 ifTrue:
		["Just xor and count differing bits if not RGB"
		diff _ sourceWord bitXor: destinationWord.
		pixMask _ maskTable at: destDepth.
		[diff = 0] whileFalse:
			[(diff bitAnd: pixMask) ~= 0 ifTrue: [bitCount _ bitCount + 1].
			diff _ diff >> destDepth].
		^ destinationWord "for no effect"].
 	destDepth = 16
		ifTrue:
		[diff _ (self partitionedSub: sourceWord from: destinationWord
						nBits: 5 nPartitions: 3).
		bitCount _ bitCount + (diff bitAnd: 16r1F)
							+ (diff>>5 bitAnd: 16r1F)
							+ (diff>>10 bitAnd: 16r1F).
		diff _ (self partitionedSub: sourceWord>>16 from: destinationWord>>16
						nBits: 5 nPartitions: 3).
		bitCount _ bitCount + (diff bitAnd: 16r1F)
							+ (diff>>5 bitAnd: 16r1F)
							+ (diff>>10 bitAnd: 16r1F)]
		ifFalse:
		[diff _ (self partitionedSub: sourceWord from: destinationWord
						nBits: 8 nPartitions: 3).
		bitCount _ bitCount + (diff bitAnd: 16rFF)
							+ (diff>>8 bitAnd: 16rFF)
							+ (diff>>16 bitAnd: 16rFF)].
	^ destinationWord  "For no effect on dest"
]

{ #category : #'combination rules' }
BitBltSimulation >> OLDtallyIntoMap: sourceWord with: destinationWord [
	"Tally pixels into the color map.  Note that the source should be 
	specified = destination, in order for the proper color map checks 
	to be performed at setup.
	Note that the region is not clipped to bit boundaries, but only to the
	nearest (enclosing) word.  This is because copyLoop does not do
	pre-merge masking.  For accurate results, you must subtract the
	values obtained from the left and right fringes."
	| mapIndex pixMask shiftWord |
	(cmFlags bitAnd: (ColorMapPresent bitOr: ColorMapIndexedPart)) =
		(ColorMapPresent bitOr: ColorMapIndexedPart)
			ifFalse: [^ destinationWord "no op"].
	destDepth < 16 ifTrue:
		["loop through all packed pixels."
		pixMask _ (maskTable at: destDepth) bitAnd: cmMask.
		shiftWord _ destinationWord.
		1 to: destPPW do:
			[:i |
			mapIndex _ shiftWord bitAnd: pixMask.
			self tallyMapAt: mapIndex put: (self tallyMapAt: mapIndex) + 1.
			shiftWord _ shiftWord >> destDepth].
		^ destinationWord].
	destDepth = 16 ifTrue:
		["Two pixels  Tally the right half..."
		mapIndex _ self rgbMap: (destinationWord bitAnd: 16rFFFF) from: 5 to: cmBitsPerColor.
		self tallyMapAt: mapIndex put: (self tallyMapAt: mapIndex) + 1.
		"... and then left half"
		mapIndex _ self rgbMap: destinationWord>>16 from: 5 to: cmBitsPerColor.
		self tallyMapAt: mapIndex put: (self tallyMapAt: mapIndex) + 1]
	ifFalse:
		["Just one pixel."
		mapIndex _ self rgbMap: destinationWord from: 8 to: cmBitsPerColor.
		self tallyMapAt: mapIndex put: (self tallyMapAt: mapIndex) + 1].
	^ destinationWord  "For no effect on dest"
]

{ #category : #'combination rules' }
BitBltSimulation >> addWord: sourceWord with: destinationWord [
	^sourceWord + destinationWord
]

{ #category : #accessing }
BitBltSimulation >> affectedBottom [

	^affectedB
]

{ #category : #accessing }
BitBltSimulation >> affectedLeft [

	^affectedL
]

{ #category : #accessing }
BitBltSimulation >> affectedRight [

	^affectedR
]

{ #category : #accessing }
BitBltSimulation >> affectedTop [

	^affectedT
]

{ #category : #'combination rules' }
BitBltSimulation >> alphaBlend: sourceWord with: destinationWord [
	"Blend sourceWord with destinationWord, assuming both are 32-bit pixels.
	The source is assumed to have 255*alpha in the high 8 bits of each pixel,
	while the high 8 bits of the destinationWord will be ignored.
	The blend produced is alpha*source + (1-alpha)*dest, with
	the computation being performed independently on each color
	component.  The high byte of the result will be 0."
	| alpha unAlpha colorMask result blend shift |
	self inline: false.
	alpha _ sourceWord >> 24.  "High 8 bits of source pixel"
	alpha = 0 ifTrue: [ ^ destinationWord ].
	alpha = 255 ifTrue: [ ^ sourceWord ].
	unAlpha _ 255 - alpha.
	colorMask _ 16rFF.
	result _ 0.

	"red"
	shift := 0.
	blend := ((sourceWord >> shift bitAnd: colorMask) * alpha) +
				((destinationWord>>shift bitAnd: colorMask) * unAlpha)
			 	+ 254 // 255 bitAnd: colorMask.
	result _ result bitOr: blend << shift.
	"green"
	shift := 8.
	blend := ((sourceWord >> shift bitAnd: colorMask) * alpha) +
				((destinationWord>>shift bitAnd: colorMask) * unAlpha)
			 	+ 254 // 255 bitAnd: colorMask.
	result _ result bitOr: blend << shift.
	"blue"
	shift := 16.
	blend := ((sourceWord >> shift bitAnd: colorMask) * alpha) +
				((destinationWord>>shift bitAnd: colorMask) * unAlpha)
			 	+ 254 // 255 bitAnd: colorMask.
	result _ result bitOr: blend << shift.
	"alpha (pre-multiplied)"
	shift := 24.
	blend := (alpha * 255) +
				((destinationWord>>shift bitAnd: colorMask) * unAlpha)
			 	+ 254 // 255 bitAnd: colorMask.
	result _ result bitOr: blend << shift.
	^ result

]

{ #category : #'combination rules' }
BitBltSimulation >> alphaBlendConst: sourceWord with: destinationWord [

	^ self alphaBlendConst: sourceWord with: destinationWord paintMode: false
]

{ #category : #'combination rules' }
BitBltSimulation >> alphaBlendConst: sourceWord with: destinationWord paintMode: paintMode [
	"Blend sourceWord with destinationWord using a constant alpha.
	Alpha is encoded as 0 meaning 0.0, and 255 meaning 1.0.
	The blend produced is alpha*source + (1.0-alpha)*dest, with the
	computation being performed independently on each color component.
	This function could eventually blend into any depth destination,
	using the same color averaging and mapping as warpBlt.
	paintMode = true means do nothing if the source pixel value is zero."

	"This first implementation works with dest depths of 16 and 32 bits only.
	Normal color mapping will allow sources of lower depths in this case,
	and results can be mapped directly by truncation, so no extra color maps are needed.
	To allow storing into any depth will require subsequent addition of two other
	colormaps, as is the case with WarpBlt."

	| pixMask destShifted sourceShifted destPixVal rgbMask sourcePixVal unAlpha result pixBlend shift blend maskShifted bitsPerColor |
	self inline: false.
	destDepth < 16 ifTrue: [^ destinationWord "no-op"].
	unAlpha _ 255 - sourceAlpha.
	pixMask _ maskTable at: destDepth.
	destDepth = 16 
		ifTrue: [bitsPerColor _ 5]
		ifFalse:[bitsPerColor _ 8].
	rgbMask _ (1<<bitsPerColor) - 1.
	maskShifted _ destMask.
	destShifted _ destinationWord.
	sourceShifted _ sourceWord.
	result _ destinationWord.
	destPPW = 1 ifTrue:["32bpp blends include alpha"
		paintMode & (sourceWord = 0)  "painting a transparent pixel" ifFalse:[
			result _ 0.
			1 to: 4 do:[:i|
				shift _ (i-1)*8.
				blend _ (((sourceWord>>shift bitAnd: rgbMask) * sourceAlpha)
							+ ((destinationWord>>shift bitAnd: rgbMask) * unAlpha))
					 	+ 254 // 255 bitAnd: rgbMask.
				result _ result bitOr: blend<<shift].
		].
	] ifFalse:[
		1 to: destPPW do:[:j |
			sourcePixVal _ sourceShifted bitAnd: pixMask.
			((maskShifted bitAnd: pixMask) = 0  "no effect if outside of dest rectangle"
				or: [paintMode & (sourcePixVal = 0)  "or painting a transparent pixel"])
			ifFalse:
				[destPixVal _ destShifted bitAnd: pixMask.
				pixBlend _ 0.
				1 to: 3 do:
					[:i | shift _ (i-1)*bitsPerColor.
					blend _ (((sourcePixVal>>shift bitAnd: rgbMask) * sourceAlpha)
								+ ((destPixVal>>shift bitAnd: rgbMask) * unAlpha))
						 	+ 254 // 255 bitAnd: rgbMask.
					pixBlend _ pixBlend bitOr: blend<<shift].
				destDepth = 16
					ifTrue: [result _ (result bitAnd: (pixMask << (j-1*16)) bitInvert32)
										bitOr: pixBlend << (j-1*16)]
					ifFalse: [result _ pixBlend]].
			maskShifted _ maskShifted >> destDepth.
			sourceShifted _ sourceShifted >> destDepth.
			destShifted _ destShifted >> destDepth].
	].
	^ result

]

{ #category : #'combination rules' }
BitBltSimulation >> alphaBlendScaled: sourceWord with: destinationWord [
	"Blend sourceWord with destinationWord using the alpha value from sourceWord.
	Alpha is encoded as 0 meaning 0.0, and 255 meaning 1.0.
	In contrast to alphaBlend:with: the color produced is

		srcColor + (1-srcAlpha) * dstColor

	e.g., it is assumed that the source color is already scaled."
	| unAlpha dstMask srcMask b g r a |
	self inline: false.	"Do NOT inline this into optimized loops"
	unAlpha _ 255 - (sourceWord >> 24).  "High 8 bits of source pixel"
	dstMask _ destinationWord.
	srcMask _ sourceWord.
	b _ (dstMask bitAnd: 255) * unAlpha >> 8 + (srcMask bitAnd: 255).
	b > 255 ifTrue:[b _ 255].
	dstMask _ dstMask >> 8.
	srcMask _ srcMask >> 8.
	g _ (dstMask bitAnd: 255) * unAlpha >> 8 + (srcMask bitAnd: 255).
	g > 255 ifTrue:[g _ 255].
	dstMask _ dstMask >> 8.
	srcMask _ srcMask >> 8.
	r _ (dstMask bitAnd: 255) * unAlpha >> 8 + (srcMask bitAnd: 255).
	r > 255 ifTrue:[r _ 255].
	dstMask _ dstMask >> 8.
	srcMask _ srcMask >> 8.
	a _ (dstMask bitAnd: 255) * unAlpha >> 8 + (srcMask bitAnd: 255).
	a > 255 ifTrue:[a _ 255].
	^(((((a << 8) + r) << 8) + g) << 8) + b
]

{ #category : #'combination rules' }
BitBltSimulation >> alphaPaintConst: sourceWord with: destinationWord [

	sourceWord = 0 ifTrue: [^ destinationWord  "opt for all-transparent source"].
	^ self alphaBlendConst: sourceWord with: destinationWord paintMode: true
]

{ #category : #'inner loop' }
BitBltSimulation >> alphaSourceBlendBits16 [
	"This version assumes 
		combinationRule = 34
		sourcePixSize = 32
		destPixSize = 16
		sourceForm ~= destForm.
	"
	| srcIndex dstIndex sourceWord srcAlpha destWord deltaX deltaY 
	srcY dstY dstMask srcShift ditherBase ditherIndex ditherThreshold |
	self inline: false. "This particular method should be optimized in itself"
	deltaY _ bbH + 1. "So we can pre-decrement"
	srcY _ sy.
	dstY _ dy.
	srcShift _ (dx bitAnd: 1) * 16.
	destMSB ifTrue:[srcShift _ 16 - srcShift].
	mask1 _ 16rFFFF << (16 - srcShift).
	"This is the outer loop"
	[(deltaY _ deltaY - 1) ~= 0] whileTrue:[
		srcIndex _ sourceBits + (srcY * sourcePitch) + (sx * 4).
		dstIndex _ destBits + (dstY * destPitch) + (dx // 2 * 4).
		ditherBase _ (dstY bitAnd: 3) * 4.
		ditherIndex _ (sx bitAnd: 3) - 1. "For pre-increment"
		deltaX _ bbW + 1. "So we can pre-decrement"
		dstMask _ mask1.
		dstMask = 16rFFFF ifTrue:[srcShift _ 16] ifFalse:[srcShift _ 0].

		"This is the inner loop"
		[(deltaX _ deltaX - 1) ~= 0] whileTrue:[
			ditherThreshold _ ditherMatrix4x4 at: ditherBase + (ditherIndex _ ditherIndex + 1 bitAnd: 3).
			sourceWord _ self srcLongAt: srcIndex.
			srcAlpha _ sourceWord >> 24.
			srcAlpha = 255 ifTrue:[
				"Dither from 32 to 16 bit"
				sourceWord _ self dither32To16: sourceWord threshold: ditherThreshold.
				sourceWord = 0 
					ifTrue:[sourceWord _ 1 << srcShift]
					ifFalse: [sourceWord _ sourceWord << srcShift].
				"Store masked value"
				self dstLongAt: dstIndex put: sourceWord mask: dstMask.
			] ifFalse:[ "srcAlpha ~= 255"
				srcAlpha = 0 ifFalse:[ "0 < srcAlpha < 255"
					"If we have to mix colors then just copy a single word"
					destWord _ self dstLongAt: dstIndex.
					destWord _ destWord bitAnd: dstMask bitInvert32.
					destWord _ destWord >> srcShift.
					"Expand from 16 to 32 bit by adding zero bits"
					destWord _ (((destWord bitAnd: 16r7C00) bitShift: 9) bitOr:
									((destWord bitAnd: 16r3E0) bitShift: 6)) bitOr:
								(((destWord bitAnd: 16r1F) bitShift: 3) bitOr:
									16rFF000000).
					"Mix colors"
					sourceWord _ self alphaBlendScaled: sourceWord with: destWord.
					"And dither"
					sourceWord _ self dither32To16: sourceWord threshold: ditherThreshold.
					sourceWord = 0 
						ifTrue:[sourceWord _ 1 << srcShift]
						ifFalse:[sourceWord _ sourceWord << srcShift].
					"Store back"
					self dstLongAt: dstIndex put: sourceWord mask: dstMask.
				].
			].
			srcIndex _ srcIndex + 4.
			destMSB
				ifTrue:[srcShift = 0 ifTrue:[dstIndex _ dstIndex + 4]]
				ifFalse:[srcShift = 0 ifFalse:[dstIndex _ dstIndex + 4]].
			srcShift _ srcShift bitXor: 16. "Toggle between 0 and 16"
			dstMask _ dstMask bitInvert32. "Mask other half word"
		].
		srcY _ srcY + 1.
		dstY _ dstY + 1.
	].
]

{ #category : #'inner loop' }
BitBltSimulation >> alphaSourceBlendBits32 [
	"This version assumes 
		combinationRule = 34
		sourcePixSize = destPixSize = 32
		sourceForm ~= destForm.
	Note: The inner loop has been optimized for dealing
		with the special cases of srcAlpha = 0.0 and srcAlpha = 1.0 
	"
	| srcIndex dstIndex sourceWord srcAlpha destWord deltaX deltaY srcY dstY |
	self inline: false. "This particular method should be optimized in itself"

	"Give the compile a couple of hints"

	"The following should be declared as pointers so the compiler will
	notice that they're used for accessing memory locations 
	(good to know on an Intel architecture) but then the increments
	would be different between ST code and C code so must hope the
	compiler notices what happens (MS Visual C does)"

	deltaY _ bbH + 1. "So we can pre-decrement"
	srcY _ sy.
	dstY _ dy.

	"This is the outer loop"
	[(deltaY _ deltaY - 1) ~= 0] whileTrue:[
		srcIndex _ sourceBits + (srcY * sourcePitch) + (sx * 4).
		dstIndex _ destBits + (dstY * destPitch) + (dx * 4).
		deltaX _ bbW + 1. "So we can pre-decrement"

		"This is the inner loop"
		[(deltaX _ deltaX - 1) ~= 0] whileTrue:[
			sourceWord _ self srcLongAt: srcIndex.
			srcAlpha _ sourceWord >> 24.
			srcAlpha = 255 ifTrue:[
				self dstLongAt: dstIndex put: sourceWord.
				srcIndex _ srcIndex + 4.
				dstIndex _ dstIndex + 4.
				"Now copy as many words as possible with alpha = 255"
				[(deltaX _ deltaX - 1) ~= 0 and:[
					(sourceWord _ self srcLongAt: srcIndex) >> 24 = 255]]
						whileTrue:[
							self dstLongAt: dstIndex put: sourceWord.
							srcIndex _ srcIndex + 4.
							dstIndex _ dstIndex + 4.
						].
				"Adjust deltaX"
				deltaX _ deltaX + 1.
			] ifFalse:[ "srcAlpha ~= 255"
				srcAlpha = 0 ifTrue:[
					srcIndex _ srcIndex + 4.
					dstIndex _ dstIndex + 4.
					"Now skip as many words as possible,"
					[(deltaX _ deltaX - 1) ~= 0 and:[
						(sourceWord _ self srcLongAt: srcIndex) >> 24 = 0]]
						whileTrue:[
							srcIndex _ srcIndex + 4.
							dstIndex _ dstIndex + 4.
						].
					"Adjust deltaX"
					deltaX _ deltaX + 1.
				] ifFalse:[ "0 < srcAlpha < 255"
					"If we have to mix colors then just copy a single word"
					destWord _ self dstLongAt: dstIndex.
					destWord _ self alphaBlendScaled: sourceWord with: destWord.
					self dstLongAt: dstIndex put: destWord.
					srcIndex _ srcIndex + 4.
					dstIndex _ dstIndex + 4.
				].
			].
		].
		srcY _ srcY + 1.
		dstY _ dstY + 1.
	].
]

{ #category : #'inner loop' }
BitBltSimulation >> alphaSourceBlendBits8 [
	"This version assumes 
		combinationRule = 34
		sourcePixSize = 32
		destPixSize = 8
		sourceForm ~= destForm.
	Note: This is not real blending since we don't have the source colors available.
	"
	| srcIndex dstIndex sourceWord srcAlpha destWord deltaX deltaY 
	srcY dstY dstMask srcShift adjust mappingTable mapperFlags |
	self inline: false. "This particular method should be optimized in itself"
	self var: #mappingTable declareC:'unsigned int *mappingTable'.
	mappingTable _ self default8To32Table.
	mapperFlags _ cmFlags bitAnd: ColorMapNewStyle bitInvert32.
	deltaY _ bbH + 1. "So we can pre-decrement"
	srcY _ sy.
	dstY _ dy.
	mask1 _ ((dx bitAnd: 3) * 8).
	destMSB ifTrue:[mask1 _ 24 - mask1].
	mask2 _ AllOnes bitXor:(16rFF << mask1).
	(dx bitAnd: 1) = 0 
		ifTrue:[adjust _ 0]
		ifFalse:[adjust _ 16r1F1F1F1F].
	(dy bitAnd: 1) = 0
		ifTrue:[adjust _ adjust bitXor: 16r1F1F1F1F].
	"This is the outer loop"
	[(deltaY _ deltaY - 1) ~= 0] whileTrue:[
		adjust _ adjust bitXor: 16r1F1F1F1F.
		srcIndex _ sourceBits + (srcY * sourcePitch) + (sx * 4).
		dstIndex _ destBits + (dstY * destPitch) + (dx // 4 * 4).
		deltaX _ bbW + 1. "So we can pre-decrement"
		srcShift _ mask1.
		dstMask _ mask2.

		"This is the inner loop"
		[(deltaX _ deltaX - 1) ~= 0] whileTrue:[
			sourceWord _ ((self srcLongAt: srcIndex) bitAnd: (adjust bitInvert32)) + adjust.
			srcAlpha _ sourceWord >> 24.
			srcAlpha > 31 ifTrue:["Everything below 31 is transparent"
				srcAlpha < 224 ifTrue:["Everything above 224 is opaque"
					destWord _ self dstLongAt: dstIndex.
					destWord _ destWord bitAnd: dstMask bitInvert32.
					destWord _ destWord >> srcShift.
					destWord _ mappingTable at: destWord.
					sourceWord _ self alphaBlendScaled: sourceWord with: destWord.
				].
				sourceWord _ self mapPixel: sourceWord flags: mapperFlags.
				sourceWord _ sourceWord << srcShift.
				"Store back"
				self dstLongAt: dstIndex put: sourceWord mask: dstMask.
			].
			srcIndex _ srcIndex + 4.
			destMSB ifTrue:[
				srcShift = 0 
					ifTrue:[dstIndex _ dstIndex + 4.
							srcShift _ 24.
							dstMask _ 16r00FFFFFF]
					ifFalse:[srcShift _ srcShift - 8.
							dstMask _ (dstMask >> 8) bitOr: 16rFF000000].
			] ifFalse:[
				srcShift = 32
					ifTrue:[dstIndex _ dstIndex + 4.
							srcShift _ 0.
							dstMask _ 16rFFFFFF00]
					ifFalse:[srcShift _ srcShift + 8.
							dstMask _ dstMask << 8 bitOr: 255].
			].
			adjust _ adjust bitXor: 16r1F1F1F1F.
		].
		srcY _ srcY + 1.
		dstY _ dstY + 1.
	].
]

{ #category : #'combination rules' }
BitBltSimulation >> bitAnd: sourceWord with: destinationWord [
	^sourceWord bitAnd: destinationWord
]

{ #category : #'combination rules' }
BitBltSimulation >> bitAndInvert: sourceWord with: destinationWord [
	^sourceWord bitAnd: destinationWord bitInvert32
]

{ #category : #'combination rules' }
BitBltSimulation >> bitInvertAnd: sourceWord with: destinationWord [
	^sourceWord bitInvert32 bitAnd: destinationWord
]

{ #category : #'combination rules' }
BitBltSimulation >> bitInvertAndInvert: sourceWord with: destinationWord [
	^sourceWord bitInvert32 bitAnd: destinationWord bitInvert32
]

{ #category : #'combination rules' }
BitBltSimulation >> bitInvertDestination: sourceWord with: destinationWord [
	^destinationWord bitInvert32
]

{ #category : #'combination rules' }
BitBltSimulation >> bitInvertOr: sourceWord with: destinationWord [
	^sourceWord bitInvert32 bitOr: destinationWord
]

{ #category : #'combination rules' }
BitBltSimulation >> bitInvertOrInvert: sourceWord with: destinationWord [
	^sourceWord bitInvert32 bitOr: destinationWord bitInvert32
]

{ #category : #'combination rules' }
BitBltSimulation >> bitInvertSource: sourceWord with: destinationWord [
	^sourceWord bitInvert32
]

{ #category : #'combination rules' }
BitBltSimulation >> bitInvertXor: sourceWord with: destinationWord [
	^sourceWord bitInvert32 bitXor: destinationWord
]

{ #category : #'combination rules' }
BitBltSimulation >> bitOr: sourceWord with: destinationWord [
	^sourceWord bitOr: destinationWord
]

{ #category : #'combination rules' }
BitBltSimulation >> bitOrInvert: sourceWord with: destinationWord [
	^sourceWord bitOr: destinationWord bitInvert32
]

{ #category : #'combination rules' }
BitBltSimulation >> bitXor: sourceWord with: destinationWord [
	^sourceWord bitXor: destinationWord
]

{ #category : #setup }
BitBltSimulation >> checkSourceOverlap [
	"check for possible overlap of source and destination"
	"ar 10/19/1999: This method requires surfaces to be locked."
	| t |
	self inline: true.
	(sourceForm = destForm and: [dy >= sy]) ifTrue:
		[dy > sy ifTrue:
			["have to start at bottom"
			vDir _ -1.
			sy _ sy + bbH - 1.
			dy _ dy + bbH - 1]
		ifFalse:
			[(dy = sy) & (dx > sx) ifTrue:
				["y's are equal, but x's are backward"
				hDir _ -1.
				sx _ sx + bbW - 1.
				"start at right"
				dx _ dx + bbW - 1.
				"and fix up masks"
				nWords > 1 ifTrue: 
					[t _ mask1.
					mask1 _ mask2.
					mask2 _ t]]].
		"Dest inits may be affected by this change"
		destIndex _ destBits + (dy * destPitch) + ((dx // destPPW) *4).
		destDelta _ (destPitch * vDir) - (4 * (nWords * hDir))]
]

{ #category : #'combination rules' }
BitBltSimulation >> clearWord: source with: destination [
	^ 0
]

{ #category : #setup }
BitBltSimulation >> clipRange [
	"clip and adjust source origin and extent appropriately"
	"first in x"
	destX >= clipX
		ifTrue: [sx _ sourceX.
				dx _ destX.
				bbW _ width]
		ifFalse: [sx _ sourceX + (clipX - destX).
				bbW _ width - (clipX - destX).
				dx _ clipX].
	(dx + bbW) > (clipX + clipWidth)
		ifTrue: [bbW _ bbW - ((dx + bbW) - (clipX + clipWidth))].
	"then in y"
	destY >= clipY
		ifTrue: [sy _ sourceY.
				dy _ destY.
				bbH _ height]
		ifFalse: [sy _ sourceY + clipY - destY.
				bbH _ height - (clipY - destY).
				dy _ clipY].
	(dy + bbH) > (clipY + clipHeight)
		ifTrue: [bbH _ bbH - ((dy + bbH) - (clipY + clipHeight))].
	noSource ifTrue: [^ nil].
	sx < 0
		ifTrue: [dx _ dx - sx.
				bbW _ bbW + sx.
				sx _ 0].
	sx + bbW > sourceWidth
		ifTrue: [bbW _ bbW - (sx + bbW - sourceWidth)].
	sy < 0
		ifTrue: [dy _ dy - sy.
				bbH _ bbH + sy.
				sy _ 0].
	sy + bbH > sourceHeight
		ifTrue: [bbH _ bbH - (sy + bbH - sourceHeight)]
]

{ #category : #setup }
BitBltSimulation >> copyBits [
	"This function is exported for the Balloon engine"
	self export: true.
	self inline: false.
	self clipRange.
	(bbW <= 0 or: [bbH <= 0]) ifTrue:
		["zero width or height; noop"
		affectedL _ affectedR _ affectedT _ affectedB _ 0.
		^ nil].
	"Lock the surfaces"
	self lockSurfaces ifFalse:[^interpreterProxy primitiveFail].
	self copyBitsLockedAndClipped.
	self unlockSurfaces.
]

{ #category : #setup }
BitBltSimulation >> copyBitsFrom: startX to: stopX at: yValue [
	"Support for the balloon engine."
	self export: true.
	destX _ startX.
	destY _ yValue.
	sourceX _ startX.
	width _ (stopX - startX).
	self copyBits.
	self showDisplayBits.
]

{ #category : #setup }
BitBltSimulation >> copyBitsLockedAndClipped [
	"Perform the actual copyBits operation.
	Assume: Surfaces have been locked and clipping was performed."
	| done |
	self inline: true.
	"Try a shortcut for stuff that should be run as quickly as possible"
 	done _ self tryCopyingBitsQuickly.
	done ifTrue:[^nil].

	(combinationRule = 30) | (combinationRule = 31) ifTrue:
		["Check and fetch source alpha parameter for alpha blend"
		interpreterProxy methodArgumentCount = 1
			ifTrue: [sourceAlpha _ interpreterProxy stackIntegerValue: 0.
					(interpreterProxy failed not and: [(sourceAlpha >= 0) & (sourceAlpha <= 255)])
						ifFalse: [^ interpreterProxy primitiveFail]]
			ifFalse: [^ interpreterProxy primitiveFail]].

	bitCount _ 0.
	"Choose and perform the actual copy loop."
	self performCopyLoop.

	(combinationRule = 22) | (combinationRule = 32) ifTrue:
		["zero width and height; return the count"
		affectedL _ affectedR _ affectedT _ affectedB _ 0]. 
	hDir > 0
		ifTrue: [affectedL _ dx.
				affectedR _ dx + bbW]
		ifFalse: [affectedL _ dx - bbW + 1.
				affectedR _ dx + 1].
	vDir > 0
		ifTrue: [affectedT _ dy.
				affectedB _ dy + bbH]
		ifFalse: [affectedT _ dy - bbH + 1.
				affectedB _ dy + 1]
]

{ #category : #'inner loop' }
BitBltSimulation >> copyLoop [
	| prevWord thisWord skewWord halftoneWord mergeWord hInc y unskew skewMask notSkewMask mergeFnwith destWord |
	"This version of the inner loop assumes noSource = false."
	self inline: false.
	self var: #mergeFnwith declareC: 'sqInt (*mergeFnwith)(sqInt, sqInt)'.
	mergeFnwith _ self cCoerce: (opTable at: combinationRule+1) to: 'sqInt (*)(sqInt, sqInt)'.
	mergeFnwith.  "null ref for compiler"

	hInc _ hDir*4.  "Byte delta"
	"degenerate skew fixed for Sparc. 10/20/96 ikp"
	skew == -32
		ifTrue: [skew _ unskew _ skewMask _ 0]
		ifFalse: [skew < 0
			ifTrue:
				[unskew _ skew+32.
				skewMask _ AllOnes << (0-skew)]
			ifFalse:
				[skew = 0
					ifTrue:
						[unskew _ 0.
						skewMask _ AllOnes]
					ifFalse:
						[unskew _ skew-32.
						skewMask _ AllOnes >> skew]]].
	notSkewMask _ skewMask bitInvert32.
	noHalftone
		ifTrue: [halftoneWord _ AllOnes.  halftoneHeight _ 0]
		ifFalse: [halftoneWord _ self halftoneAt: 0].

	y _ dy.
	1 to: bbH do: "here is the vertical loop"
		[ :i |
		halftoneHeight > 1 ifTrue:  "Otherwise, its always the same"
			[halftoneWord _ self halftoneAt: y.
			y _ y + vDir].
		preload ifTrue:
			["load the 64-bit shifter"
			prevWord _ self srcLongAt: sourceIndex.
			sourceIndex _ sourceIndex + hInc]
			ifFalse:
			[prevWord _ 0].

	"Note: the horizontal loop has been expanded into three parts for speed:"

			"This first section requires masking of the destination store..."
			destMask _ mask1.
			thisWord _ self srcLongAt: sourceIndex.  "pick up next word"
			sourceIndex _ sourceIndex + hInc.
			skewWord _ ((prevWord bitAnd: notSkewMask) bitShift: unskew)
							bitOr:  "32-bit rotate"
						((thisWord bitAnd: skewMask) bitShift: skew).
			prevWord _ thisWord.
			destWord _ self dstLongAt: destIndex.
			mergeWord _ self mergeFn: (skewWord bitAnd: halftoneWord) with: destWord.
			destWord _ (destMask bitAnd: mergeWord) bitOr:
							(destWord bitAnd: destMask bitInvert32).
			self dstLongAt: destIndex put: destWord.
			destIndex _ destIndex + hInc.

		"This central horizontal loop requires no store masking"
		destMask _ AllOnes.
combinationRule = 3
ifTrue: [(skew = 0) & (halftoneWord = AllOnes)
		ifTrue: 
		["Very special inner loop for STORE mode with no skew -- just move words"
		hDir = -1
		ifTrue: ["Woeful patch: revert to older code for hDir = -1"
				2 to: nWords-1 do: 
					[ :word |
					thisWord _ self srcLongAt: sourceIndex.
					sourceIndex _ sourceIndex + hInc.
					self dstLongAt: destIndex put: thisWord.
					destIndex _ destIndex + hInc]]
		ifFalse: [2 to: nWords-1 do: 
					[ :word |  "Note loop starts with prevWord loaded (due to preload)"
					self dstLongAt: destIndex put: prevWord.
					destIndex _ destIndex + hInc.
					prevWord _ self srcLongAt: sourceIndex.
					sourceIndex _ sourceIndex + hInc]]]
		ifFalse:
		["Special inner loop for STORE mode -- no need to call merge"
		2 to: nWords-1 do: 
			[ :word |
			thisWord _ self srcLongAt: sourceIndex.
			sourceIndex _ sourceIndex + hInc.
			skewWord _ ((prevWord bitAnd: notSkewMask) bitShift: unskew)
							bitOr:  "32-bit rotate"
						((thisWord bitAnd: skewMask) bitShift: skew).
			prevWord _ thisWord.
			self dstLongAt: destIndex put: (skewWord bitAnd: halftoneWord).
			destIndex _ destIndex + hInc]]
] ifFalse: [2 to: nWords-1 do: "Normal inner loop does merge:"
			[ :word |
			thisWord _ self srcLongAt: sourceIndex.  "pick up next word"
			sourceIndex _ sourceIndex + hInc.
			skewWord _ ((prevWord bitAnd: notSkewMask) bitShift: unskew)
							bitOr:  "32-bit rotate"
						((thisWord bitAnd: skewMask) bitShift: skew).
			prevWord _ thisWord.
			mergeWord _ self mergeFn: (skewWord bitAnd: halftoneWord)
							with: (self dstLongAt: destIndex).
			self dstLongAt: destIndex put: mergeWord.
			destIndex _ destIndex + hInc]
].

		"This last section, if used, requires masking of the destination store..."
		nWords > 1 ifTrue:
			[destMask _ mask2.
			thisWord _ self srcLongAt: sourceIndex.  "pick up next word"
			sourceIndex _ sourceIndex + hInc.
			skewWord _ ((prevWord bitAnd: notSkewMask) bitShift: unskew)
							bitOr:  "32-bit rotate"
						((thisWord bitAnd: skewMask) bitShift: skew).
			destWord _ self dstLongAt: destIndex.
			mergeWord _ self mergeFn: (skewWord bitAnd: halftoneWord) with: destWord.
			destWord _ (destMask bitAnd: mergeWord) bitOr:
							(destWord bitAnd: destMask bitInvert32).
			self dstLongAt: destIndex put: destWord.
			destIndex _ destIndex + hInc].

	sourceIndex _ sourceIndex + sourceDelta.
	destIndex _ destIndex + destDelta]
]

{ #category : #'inner loop' }
BitBltSimulation >> copyLoopNoSource [
	"Faster copyLoop when source not used.  hDir and vDir are both
	positive, and perload and skew are unused"
	| halftoneWord mergeWord mergeFnwith destWord |
	self inline: false.
	self var: #mergeFnwith declareC: 'sqInt (*mergeFnwith)(sqInt, sqInt)'.
	mergeFnwith _ self cCoerce: (opTable at: combinationRule+1) to: 'sqInt (*)(sqInt, sqInt)'.
	mergeFnwith.  "null ref for compiler"

	1 to: bbH do: "here is the vertical loop"
		[ :i |
		noHalftone
			ifTrue: [halftoneWord _ AllOnes]
			ifFalse: [halftoneWord _ self halftoneAt: dy+i-1].

	"Note: the horizontal loop has been expanded into three parts for speed:"

			"This first section requires masking of the destination store..."
			destMask _ mask1.
			destWord _ self dstLongAt: destIndex.
			mergeWord _ self mergeFn: halftoneWord
							with: destWord.
			destWord _ (destMask bitAnd: mergeWord) bitOr: 
							(destWord bitAnd: destMask bitInvert32).
			self dstLongAt: destIndex put: destWord.
			destIndex _ destIndex + 4.

		"This central horizontal loop requires no store masking"
			destMask _ AllOnes.
			combinationRule = 3 ifTrue: ["Special inner loop for STORE"
				destWord _ halftoneWord.
				2 to: nWords-1 do:[ :word |
					self dstLongAt: destIndex put: destWord.
					destIndex _ destIndex + 4].
			] ifFalse:[ "Normal inner loop does merge"
				2 to: nWords-1 do:[ :word | "Normal inner loop does merge"
					destWord _ self dstLongAt: destIndex.
					mergeWord _ self mergeFn: halftoneWord with: destWord.
					self dstLongAt: destIndex put: mergeWord.
					destIndex _ destIndex + 4].
			].

		"This last section, if used, requires masking of the destination store..."
		nWords > 1 ifTrue:
			[destMask _ mask2.
			destWord _ self dstLongAt: destIndex.
			mergeWord _ self mergeFn: halftoneWord with: destWord.
			destWord _ (destMask bitAnd: mergeWord) bitOr:
							(destWord bitAnd: destMask bitInvert32).
			self dstLongAt: destIndex put: destWord.
			destIndex _ destIndex + 4].

	destIndex _ destIndex + destDelta]
]

{ #category : #'inner loop' }
BitBltSimulation >> copyLoopPixMap [
	"This version of the inner loop maps source pixels
	to a destination form with different depth.  Because it is already
	unweildy, the loop is not unrolled as in the other versions.
	Preload, skew and skewMask are all overlooked, since pickSourcePixels
	delivers its destination word already properly aligned.
	Note that pickSourcePixels could be copied in-line at the top of
	the horizontal loop, and some of its inits moved out of the loop."
	"ar 12/7/1999:
	The loop has been rewritten to use only one pickSourcePixels call.
	The idea is that the call itself could be inlined. If we decide not
	to inline pickSourcePixels we could optimize the loop instead."
	| skewWord halftoneWord mergeWord scrStartBits nSourceIncs startBits endBits sourcePixMask destPixMask mergeFnwith nPix srcShift dstShift destWord words srcShiftInc dstShiftInc dstShiftLeft mapperFlags |
	self inline: false.
	self var: #mergeFnwith declareC: 'sqInt (*mergeFnwith)(sqInt, sqInt)'.
	mergeFnwith _ self cCoerce: (opTable at: combinationRule+1) to: 'sqInt (*)(sqInt, sqInt)'.
	mergeFnwith.  "null ref for compiler"

	"Additional inits peculiar to unequal source and dest pix size..."
	sourcePPW _ 32//sourceDepth.
	sourcePixMask _ maskTable at: sourceDepth.
	destPixMask _ maskTable at: destDepth.
	mapperFlags _ cmFlags bitAnd: ColorMapNewStyle bitInvert32.
	sourceIndex _ sourceBits +
					(sy * sourcePitch) + ((sx // sourcePPW) *4).
	scrStartBits _ sourcePPW - (sx bitAnd: sourcePPW-1).
	bbW < scrStartBits
		ifTrue: [nSourceIncs _ 0]
		ifFalse: [nSourceIncs _ (bbW - scrStartBits)//sourcePPW + 1].
	sourceDelta _ sourcePitch - (nSourceIncs * 4).

	"Note following two items were already calculated in destmask setup!"
	startBits _ destPPW - (dx bitAnd: destPPW-1).
	endBits _ ((dx + bbW - 1) bitAnd: destPPW-1) + 1.

	bbW < startBits ifTrue:[startBits _ bbW].

	"Precomputed shifts for pickSourcePixels"
	srcShift _ ((sx bitAnd: sourcePPW - 1) * sourceDepth).
	dstShift _ ((dx bitAnd: destPPW - 1) * destDepth).
	srcShiftInc _ sourceDepth.
	dstShiftInc _ destDepth.
	dstShiftLeft _ 0.
	sourceMSB ifTrue:[
		srcShift _ 32 - sourceDepth - srcShift.
		srcShiftInc _ 0 - srcShiftInc].
	destMSB ifTrue:[
		dstShift _ 32 - destDepth - dstShift.
		dstShiftInc _ 0 - dstShiftInc.
		dstShiftLeft _ 32 - destDepth].

	1 to: bbH do: "here is the vertical loop"
		[ :i |
		"*** is it possible at all that noHalftone == false? ***"
		noHalftone
			ifTrue:[halftoneWord _ AllOnes]
			ifFalse: [halftoneWord _ self halftoneAt: dy+i-1].
		"setup first load"
		srcBitShift _ srcShift.
		dstBitShift _ dstShift.
		destMask _ mask1.
		nPix _ startBits.
		"Here is the horizontal loop..."
		words _ nWords.
			["pick up the word"
			skewWord _ self pickSourcePixels: nPix flags: mapperFlags 
								srcMask: sourcePixMask destMask: destPixMask
								srcShiftInc: srcShiftInc dstShiftInc: dstShiftInc.
			"align next word to leftmost pixel"
			dstBitShift _ dstShiftLeft.

			destMask = AllOnes ifTrue:["avoid read-modify-write"
				mergeWord _ self mergeFn: (skewWord bitAnd: halftoneWord)
								with: (self dstLongAt: destIndex).
				self dstLongAt: destIndex put: (destMask bitAnd: mergeWord).
			] ifFalse:[ "General version using dest masking"
				destWord _ self dstLongAt: destIndex.
				mergeWord _ self mergeFn: (skewWord bitAnd: halftoneWord)
								with: (destWord bitAnd: destMask).
				destWord _ (destMask bitAnd: mergeWord) bitOr:
								(destWord bitAnd: destMask bitInvert32).
				self dstLongAt: destIndex put: destWord.
			].
			destIndex _ destIndex + 4.
			words = 2 "e.g., is the next word the last word?"
				ifTrue:["set mask for last word in this row"
						destMask _ mask2.
						nPix _ endBits]
				ifFalse:["use fullword mask for inner loop"
						destMask _ AllOnes.
						nPix _ destPPW].
			(words _ words - 1) = 0] whileFalse.
		"--- end of inner loop ---"
		sourceIndex _ sourceIndex + sourceDelta.
		destIndex _ destIndex + destDelta]

]

{ #category : #'pixel mapping' }
BitBltSimulation >> default8To32Table [
	"Return the default translation table from 1..8 bit indexed colors to 32bit"
	"The table has been generated by the following statements"
	"| pvs hex |
	String streamContents:[:s|
		s nextPutAll:'static unsigned int theTable[256] = { '.
		pvs _ (Color colorMapIfNeededFrom: 8 to: 32) asArray.
		1 to: pvs size do:[:i|
			i > 1 ifTrue:[s nextPutAll:', '].
			(i-1 \\ 8) = 0 ifTrue:[s cr].
			s nextPutAll:'0x'.
			hex _ (pvs at: i) printStringBase: 16.
			s nextPutAll: (hex copyFrom: 4 to: hex size).
		].
		s nextPutAll:'};'.
	]."
	| theTable |
	self returnTypeC:'unsigned int *'.
	self var: #theTable declareC:'static unsigned int theTable[256] = { 
0x0, 0xFF000001, 0xFFFFFFFF, 0xFF808080, 0xFFFF0000, 0xFF00FF00, 0xFF0000FF, 0xFF00FFFF, 
0xFFFFFF00, 0xFFFF00FF, 0xFF202020, 0xFF404040, 0xFF606060, 0xFF9F9F9F, 0xFFBFBFBF, 0xFFDFDFDF, 
0xFF080808, 0xFF101010, 0xFF181818, 0xFF282828, 0xFF303030, 0xFF383838, 0xFF484848, 0xFF505050, 
0xFF585858, 0xFF686868, 0xFF707070, 0xFF787878, 0xFF878787, 0xFF8F8F8F, 0xFF979797, 0xFFA7A7A7, 
0xFFAFAFAF, 0xFFB7B7B7, 0xFFC7C7C7, 0xFFCFCFCF, 0xFFD7D7D7, 0xFFE7E7E7, 0xFFEFEFEF, 0xFFF7F7F7, 
0xFF000001, 0xFF003300, 0xFF006600, 0xFF009900, 0xFF00CC00, 0xFF00FF00, 0xFF000033, 0xFF003333, 
0xFF006633, 0xFF009933, 0xFF00CC33, 0xFF00FF33, 0xFF000066, 0xFF003366, 0xFF006666, 0xFF009966, 
0xFF00CC66, 0xFF00FF66, 0xFF000099, 0xFF003399, 0xFF006699, 0xFF009999, 0xFF00CC99, 0xFF00FF99, 
0xFF0000CC, 0xFF0033CC, 0xFF0066CC, 0xFF0099CC, 0xFF00CCCC, 0xFF00FFCC, 0xFF0000FF, 0xFF0033FF, 
0xFF0066FF, 0xFF0099FF, 0xFF00CCFF, 0xFF00FFFF, 0xFF330000, 0xFF333300, 0xFF336600, 0xFF339900, 
0xFF33CC00, 0xFF33FF00, 0xFF330033, 0xFF333333, 0xFF336633, 0xFF339933, 0xFF33CC33, 0xFF33FF33, 
0xFF330066, 0xFF333366, 0xFF336666, 0xFF339966, 0xFF33CC66, 0xFF33FF66, 0xFF330099, 0xFF333399, 
0xFF336699, 0xFF339999, 0xFF33CC99, 0xFF33FF99, 0xFF3300CC, 0xFF3333CC, 0xFF3366CC, 0xFF3399CC, 
0xFF33CCCC, 0xFF33FFCC, 0xFF3300FF, 0xFF3333FF, 0xFF3366FF, 0xFF3399FF, 0xFF33CCFF, 0xFF33FFFF, 
0xFF660000, 0xFF663300, 0xFF666600, 0xFF669900, 0xFF66CC00, 0xFF66FF00, 0xFF660033, 0xFF663333, 
0xFF666633, 0xFF669933, 0xFF66CC33, 0xFF66FF33, 0xFF660066, 0xFF663366, 0xFF666666, 0xFF669966, 
0xFF66CC66, 0xFF66FF66, 0xFF660099, 0xFF663399, 0xFF666699, 0xFF669999, 0xFF66CC99, 0xFF66FF99, 
0xFF6600CC, 0xFF6633CC, 0xFF6666CC, 0xFF6699CC, 0xFF66CCCC, 0xFF66FFCC, 0xFF6600FF, 0xFF6633FF, 
0xFF6666FF, 0xFF6699FF, 0xFF66CCFF, 0xFF66FFFF, 0xFF990000, 0xFF993300, 0xFF996600, 0xFF999900, 
0xFF99CC00, 0xFF99FF00, 0xFF990033, 0xFF993333, 0xFF996633, 0xFF999933, 0xFF99CC33, 0xFF99FF33, 
0xFF990066, 0xFF993366, 0xFF996666, 0xFF999966, 0xFF99CC66, 0xFF99FF66, 0xFF990099, 0xFF993399, 
0xFF996699, 0xFF999999, 0xFF99CC99, 0xFF99FF99, 0xFF9900CC, 0xFF9933CC, 0xFF9966CC, 0xFF9999CC, 
0xFF99CCCC, 0xFF99FFCC, 0xFF9900FF, 0xFF9933FF, 0xFF9966FF, 0xFF9999FF, 0xFF99CCFF, 0xFF99FFFF, 
0xFFCC0000, 0xFFCC3300, 0xFFCC6600, 0xFFCC9900, 0xFFCCCC00, 0xFFCCFF00, 0xFFCC0033, 0xFFCC3333, 
0xFFCC6633, 0xFFCC9933, 0xFFCCCC33, 0xFFCCFF33, 0xFFCC0066, 0xFFCC3366, 0xFFCC6666, 0xFFCC9966, 
0xFFCCCC66, 0xFFCCFF66, 0xFFCC0099, 0xFFCC3399, 0xFFCC6699, 0xFFCC9999, 0xFFCCCC99, 0xFFCCFF99, 
0xFFCC00CC, 0xFFCC33CC, 0xFFCC66CC, 0xFFCC99CC, 0xFFCCCCCC, 0xFFCCFFCC, 0xFFCC00FF, 0xFFCC33FF, 
0xFFCC66FF, 0xFFCC99FF, 0xFFCCCCFF, 0xFFCCFFFF, 0xFFFF0000, 0xFFFF3300, 0xFFFF6600, 0xFFFF9900, 
0xFFFFCC00, 0xFFFFFF00, 0xFFFF0033, 0xFFFF3333, 0xFFFF6633, 0xFFFF9933, 0xFFFFCC33, 0xFFFFFF33, 
0xFFFF0066, 0xFFFF3366, 0xFFFF6666, 0xFFFF9966, 0xFFFFCC66, 0xFFFFFF66, 0xFFFF0099, 0xFFFF3399, 
0xFFFF6699, 0xFFFF9999, 0xFFFFCC99, 0xFFFFFF99, 0xFFFF00CC, 0xFFFF33CC, 0xFFFF66CC, 0xFFFF99CC, 
0xFFFFCCCC, 0xFFFFFFCC, 0xFFFF00FF, 0xFFFF33FF, 0xFFFF66FF, 0xFFFF99FF, 0xFFFFCCFF, 0xFFFFFFFF};'.
	^theTable
]

{ #category : #'pixel mapping' }
BitBltSimulation >> deltaFrom: x1 to: x2 nSteps: n [
	"Utility routine for computing Warp increments."
	self inline: true.
	x2 > x1
		ifTrue: [^ x2 - x1 + FixedPt1 // (n+1) + 1]
		ifFalse: [x2 = x1 ifTrue: [^ 0].
				^ 0 - (x1 - x2 + FixedPt1 // (n+1) + 1)]
]

{ #category : #setup }
BitBltSimulation >> destMaskAndPointerInit [
	"Compute masks for left and right destination words"
	| startBits pixPerM1 endBits |
	self inline: true.
	pixPerM1 _ destPPW - 1.  "A mask, assuming power of two"
	"how many pixels in first word"
	startBits _ destPPW - (dx bitAnd: pixPerM1).
	destMSB
		ifTrue:[ mask1 _ AllOnes >> (32 - (startBits*destDepth))] 
		ifFalse:[ mask1 _ AllOnes << (32 - (startBits*destDepth))].
	"how many pixels in last word"
	endBits _ ((dx + bbW - 1) bitAnd: pixPerM1) + 1.
	destMSB 
		ifTrue:[mask2 _ AllOnes << (32 - (endBits*destDepth))] 
		ifFalse:[mask2 _ AllOnes >> (32 - (endBits*destDepth))].
	"determine number of words stored per line; merge masks if only 1"
	bbW < startBits
		ifTrue: [mask1 _ mask1 bitAnd: mask2.
				mask2 _ 0.
				nWords _ 1]
		ifFalse: [nWords _ (bbW - startBits) + pixPerM1 // destPPW + 1].
	hDir _ vDir _ 1. "defaults for no overlap with source"

	"calculate byte addr and delta, based on first word of data"
	"Note pitch is bytes and nWords is longs, not bytes"
	destIndex _ destBits + (dy * destPitch) + ((dx // destPPW) *4).
	destDelta _ destPitch * vDir - (4 * (nWords * hDir)).  "byte addr delta"

]

{ #category : #'combination rules' }
BitBltSimulation >> destinationWord: sourceWord with: destinationWord [
	^destinationWord
]

{ #category : #'pixel mapping' }
BitBltSimulation >> dither32To16: srcWord threshold: ditherValue [
	"Dither the given 32bit word to 16 bit. Ignore alpha."
	| addThreshold  |
	self inline: true. "You bet"
	addThreshold _ ditherValue bitShift: 8.
	^((dither8Lookup at: (addThreshold+((srcWord bitShift: -16) bitAnd: 255))) bitShift: 10) + 
		((dither8Lookup at: (addThreshold+((srcWord bitShift: -8) bitAnd: 255))) bitShift: 5) + 
		(dither8Lookup at: (addThreshold+(srcWord bitAnd: 255))).

]

{ #category : #'interpreter interface' }
BitBltSimulation >> drawLoopX: xDelta Y: yDelta [ 
	"This is the primitive implementation of the line-drawing loop.
	See the comments in BitBlt>>drawLoopX:Y:"
	| dx1 dy1 px py P affL affR affT affB |
	xDelta > 0
		ifTrue: [dx1 _ 1]
		ifFalse: [xDelta = 0
				ifTrue: [dx1 _ 0]
				ifFalse: [dx1 _ -1]].
	yDelta > 0
		ifTrue: [dy1 _ 1]
		ifFalse: [yDelta = 0
				ifTrue: [dy1 _ 0]
				ifFalse: [dy1 _ -1]].
	px _ yDelta abs.
	py _ xDelta abs.
	affL _ affT _ 9999.  "init null rectangle"
	affR _ affB _ -9999.
	py > px
		ifTrue: 
			["more horizontal"
			P _ py // 2.
			1 to: py do: 
				[:i |
				destX _ destX + dx1.
				(P _ P - px) < 0 ifTrue: 
					[destY _ destY + dy1.
					P _ P + py].
				i < py ifTrue:
					[self copyBits.
					interpreterProxy failed ifTrue:
						[^ nil "bail out now on failure -- avoid storing x,y"].
					(affectedL < affectedR and: [affectedT < affectedB]) ifTrue:
						["Affected rectangle grows along the line"
						affL _ affL min: affectedL.
						affR _ affR max: affectedR.
						affT _ affT min: affectedT.
						affB _ affB max: affectedB.
						(affR - affL) * (affB - affT) > 4000 ifTrue:
							["If affected rectangle gets large, update it in chunks"
							affectedL _ affL.  affectedR _ affR.
							affectedT _ affT.  affectedB _ affB.
							self showDisplayBits.
							affL _ affT _ 9999.  "init null rectangle"
							affR _ affB _ -9999]].
					]]]
		ifFalse: 
			["more vertical"
			P _ px // 2.
			1 to: px do:
				[:i |
				destY _ destY + dy1.
				(P _ P - py) < 0 ifTrue: 
					[destX _ destX + dx1.
					P _ P + px].
				i < px ifTrue:
					[self copyBits.
					interpreterProxy failed ifTrue:
						[^ nil "bail out now on failure -- avoid storing x,y"].
					(affectedL < affectedR and: [affectedT < affectedB]) ifTrue:
						["Affected rectangle grows along the line"
						affL _ affL min: affectedL.
						affR _ affR max: affectedR.
						affT _ affT min: affectedT.
						affB _ affB max: affectedB.
						(affR - affL) * (affB - affT) > 4000 ifTrue:
							["If affected rectangle gets large, update it in chunks"
							affectedL _ affL.  affectedR _ affR.
							affectedT _ affT.  affectedB _ affB.
							self showDisplayBits.
							affL _ affT _ 9999.  "init null rectangle"
							affR _ affB _ -9999]].
					]]].

	"Remaining affected rect"
	affectedL _ affL.  affectedR _ affR.
	affectedT _ affT.  affectedB _ affB.

	"store destX, Y back"	
	interpreterProxy storeInteger: BBDestXIndex ofObject: bitBltOop withValue: destX.
	interpreterProxy storeInteger: BBDestYIndex ofObject: bitBltOop withValue: destY.
]

{ #category : #'memory access' }
BitBltSimulation >> dstLongAt: idx [

	^self long32At: idx
]

{ #category : #'memory access' }
BitBltSimulation >> dstLongAt: idx put: value [

	^self long32At: idx put: value
]

{ #category : #'memory access' }
BitBltSimulation >> dstLongAt: idx put: srcValue mask: dstMask [
	"Store the given value back into destination form, using dstMask
	to mask out the bits to be modified. This is an essiantial
	read-modify-write operation on the destination form."
	| dstValue |
	self inline: true.
	dstValue _ self dstLongAt: idx.
	dstValue _ dstValue bitAnd: dstMask.
	dstValue _ dstValue bitOr: srcValue.
	self dstLongAt: idx put: dstValue.
]

{ #category : #'pixel mapping' }
BitBltSimulation >> expensiveDither32To16: srcWord threshold: ditherValue [
	"Dither the given 32bit word to 16 bit. Ignore alpha."
	| pv threshold value out |
	self inline: true. "You bet"
	pv _ srcWord bitAnd: 255.
	threshold _ ditherThresholds16 at: (pv bitAnd: 7).
	value _ ditherValues16 at: (pv bitShift: -3).
	ditherValue < threshold
		ifTrue:[out _ value + 1]
		ifFalse:[out _ value].
	pv _ (srcWord bitShift: -8) bitAnd: 255.
	threshold _ ditherThresholds16 at: (pv bitAnd: 7).
	value _ ditherValues16 at: (pv bitShift: -3).
	ditherValue < threshold
		ifTrue:[out _ out bitOr: (value+1 bitShift:5)]
		ifFalse:[out _ out bitOr: (value bitShift: 5)].
	pv _ (srcWord bitShift: -16) bitAnd: 255.
	threshold _ ditherThresholds16 at: (pv bitAnd: 7).
	value _ ditherValues16 at: (pv bitShift: -3).
	ditherValue < threshold
		ifTrue:[out _ out bitOr: (value+1 bitShift:10)]
		ifFalse:[out _ out bitOr: (value bitShift: 10)].
	^out
]

{ #category : #'interpreter interface' }
BitBltSimulation >> fetchIntOrFloat: fieldIndex ofObject: objectPointer [
	"Return the integer value of the given field of the given object. If the field contains a Float, truncate it and return its integral part. Fail if the given field does not contain a small integer or Float, or if the truncated Float is out of the range of small integers."
	| fieldOop floatValue |
	self var: #floatValue declareC:'double floatValue'.
	fieldOop _ interpreterProxy fetchPointer: fieldIndex ofObject: objectPointer.
	(interpreterProxy isIntegerObject: fieldOop)
		ifTrue:[^interpreterProxy integerValueOf: fieldOop].
	floatValue _ interpreterProxy floatValueOf: fieldOop.
	(-2147483648.0 <= floatValue and:[floatValue <= 2147483647.0])
		ifFalse:[interpreterProxy primitiveFail. ^0].
	^floatValue asInteger
]

{ #category : #'interpreter interface' }
BitBltSimulation >> fetchIntOrFloat: fieldIndex ofObject: objectPointer ifNil: defaultValue [
	"Return the integer value of the given field of the given object. If the field contains a Float, truncate it and return its integral part. Fail if the given field does not contain a small integer or Float, or if the truncated Float is out of the range of small integers."
	| fieldOop floatValue |
	self var: #floatValue declareC:'double floatValue'.
	fieldOop _ interpreterProxy fetchPointer: fieldIndex ofObject: objectPointer.
	(interpreterProxy isIntegerObject: fieldOop)
		ifTrue:[^interpreterProxy integerValueOf: fieldOop].
	(fieldOop = interpreterProxy nilObject) ifTrue:[^defaultValue].
	floatValue _ interpreterProxy floatValueOf: fieldOop.
	(-2147483648.0 <= floatValue and:[floatValue <= 2147483647.0])
		ifFalse:[interpreterProxy primitiveFail. ^0].
	^floatValue asInteger
]

{ #category : #'combination rules' }
BitBltSimulation >> fixAlpha: sourceWord with: destinationWord [
	"For any non-zero pixel value in destinationWord with zero alpha channel take the alpha from sourceWord and fill it in. Intended for fixing alpha channels left at zero during 16->32 bpp conversions."
	destDepth = 32 ifFalse:[^destinationWord]. "no-op for non 32bpp"
	destinationWord = 0 ifTrue:[^0].
	(destinationWord bitAnd: 16rFF000000) = 0 ifFalse:[^destinationWord].
	^destinationWord bitOr: (sourceWord bitAnd: 16rFF000000)

]

{ #category : #'memory access' }
BitBltSimulation >> halftoneAt: idx [
	"Return a value from the halftone pattern."

	^self long32At: halftoneBase + (idx \\ halftoneHeight * 4)
]

{ #category : #setup }
BitBltSimulation >> ignoreSourceOrHalftone: formPointer [

	formPointer = interpreterProxy nilObject ifTrue: [ ^true ].
	combinationRule = 0 ifTrue: [ ^true ].
	combinationRule = 5 ifTrue: [ ^true ].
	combinationRule = 10 ifTrue: [ ^true ].
	combinationRule = 15 ifTrue: [ ^true ].
	^false
]

{ #category : #'initialize-release' }
BitBltSimulation >> initBBOpTable [
	self cCode: 'opTable[0+1] = (void *)clearWordwith'.
	self cCode: 'opTable[1+1] = (void *)bitAndwith'.
	self cCode: 'opTable[2+1] = (void *)bitAndInvertwith'.
	self cCode: 'opTable[3+1] = (void *)sourceWordwith'.
	self cCode: 'opTable[4+1] = (void *)bitInvertAndwith'.
	self cCode: 'opTable[5+1] = (void *)destinationWordwith'.
	self cCode: 'opTable[6+1] = (void *)bitXorwith'.
	self cCode: 'opTable[7+1] = (void *)bitOrwith'.
	self cCode: 'opTable[8+1] = (void *)bitInvertAndInvertwith'.
	self cCode: 'opTable[9+1] = (void *)bitInvertXorwith'.
	self cCode: 'opTable[10+1] = (void *)bitInvertDestinationwith'.
	self cCode: 'opTable[11+1] = (void *)bitOrInvertwith'.
	self cCode: 'opTable[12+1] = (void *)bitInvertSourcewith'.
	self cCode: 'opTable[13+1] = (void *)bitInvertOrwith'.
	self cCode: 'opTable[14+1] = (void *)bitInvertOrInvertwith'.
	self cCode: 'opTable[15+1] = (void *)destinationWordwith'.
	self cCode: 'opTable[16+1] = (void *)destinationWordwith'.
	self cCode: 'opTable[17+1] = (void *)destinationWordwith'.
	self cCode: 'opTable[18+1] = (void *)addWordwith'.
	self cCode: 'opTable[19+1] = (void *)subWordwith'.
	self cCode: 'opTable[20+1] = (void *)rgbAddwith'.
	self cCode: 'opTable[21+1] = (void *)rgbSubwith'.
	self cCode: 'opTable[22+1] = (void *)OLDrgbDiffwith'.
	self cCode: 'opTable[23+1] = (void *)OLDtallyIntoMapwith'.
	self cCode: 'opTable[24+1] = (void *)alphaBlendwith'.
	self cCode: 'opTable[25+1] = (void *)pixPaintwith'.
	self cCode: 'opTable[26+1] = (void *)pixMaskwith'.
	self cCode: 'opTable[27+1] = (void *)rgbMaxwith'.
	self cCode: 'opTable[28+1] = (void *)rgbMinwith'.
	self cCode: 'opTable[29+1] = (void *)rgbMinInvertwith'.
	self cCode: 'opTable[30+1] = (void *)alphaBlendConstwith'.
	self cCode: 'opTable[31+1] = (void *)alphaPaintConstwith'.
	self cCode: 'opTable[32+1] = (void *)rgbDiffwith'.
	self cCode: 'opTable[33+1] = (void *)tallyIntoMapwith'.
	self cCode: 'opTable[34+1] = (void *)alphaBlendScaledwith'.
	self cCode: 'opTable[35+1] = (void *)alphaBlendScaledwith'.
	self cCode: 'opTable[36+1] = (void *)alphaBlendScaledwith'.	
	self cCode: 'opTable[37+1] = (void *)rgbMulwith'.
	self cCode: 'opTable[38+1] = (void *)pixSwapwith'.
	self cCode: 'opTable[39+1] = (void *)pixClearwith'.
	self cCode: 'opTable[40+1] = (void *)fixAlphawith'.
]

{ #category : #'initialize-release' }
BitBltSimulation >> initDither8Lookup [	
	self inline: false. 
	0 to: 255 do: [:b | 
		0 to: 15 do: [:t | | value |
			value _ self expensiveDither32To16: b threshold: t.
			dither8Lookup at: ((t << 8)+b)put: value]].
	
]

{ #category : #'initialize-release' }
BitBltSimulation >> initialiseModule [
	self export: true.
	self initBBOpTable.
	self initDither8Lookup.
	^true
]

{ #category : #'interpreter interface' }
BitBltSimulation >> isIdentityMap: shifts with: masks [
	"Return true if shiftTable/maskTable define an identity mapping."
	self var: #shifts declareC:'int *shifts'.
	self var: #masks declareC:'unsigned int *masks'.
	(shifts == nil or:[masks == nil]) ifTrue:[^true].
	((shifts at: RedIndex) = 0 
		and:[(shifts at: GreenIndex) = 0
		and:[(shifts at: BlueIndex) = 0 
		and:[(shifts at: AlphaIndex) = 0
			and:[((masks at: RedIndex) = 16rFF0000)
			and:[((masks at: GreenIndex) = 16r00FF00)
			and:[((masks at: BlueIndex) = 16r0000FF)
			and:[((masks at: AlphaIndex) = 16rFF000000)]]]]]]])
		ifTrue:[^true].
	^false
]

{ #category : #'interpreter interface' }
BitBltSimulation >> loadBitBltDestForm [
	"Load the dest form for BitBlt. Return false if anything is wrong, true otherwise."

	| destBitsSize |
	self inline: true.
	destBits _ interpreterProxy fetchPointer: FormBitsIndex ofObject: destForm.
	destWidth _ interpreterProxy fetchInteger: FormWidthIndex ofObject: destForm.
	destHeight _ interpreterProxy fetchInteger: FormHeightIndex ofObject: destForm.
	(destWidth >= 0 and: [destHeight >= 0])
		ifFalse: [^ false].
	destDepth _ interpreterProxy fetchInteger: FormDepthIndex ofObject: destForm.
	destMSB _ destDepth > 0.
	destDepth < 0 ifTrue:[destDepth _ 0 - destDepth].
	"Ignore an integer bits handle for Display in which case 
	the appropriate values will be obtained by calling ioLockSurfaceBits()."
	(interpreterProxy isIntegerObject: destBits) ifTrue:[
		"Query for actual surface dimensions"
		(self queryDestSurface: (interpreterProxy integerValueOf: destBits))
			ifFalse:[^false].
		destPPW _ 32 // destDepth.
		destBits _ destPitch _ 0.
	] ifFalse:[
		destPPW _ 32 // destDepth.
		destPitch _ destWidth + (destPPW-1) // destPPW * 4.
		destBitsSize _ interpreterProxy byteSizeOf: destBits.
		((interpreterProxy isWordsOrBytes: destBits)
			and: [destBitsSize = (destPitch * destHeight)])
			ifFalse: [^ false].
		"Skip header since external bits don't have one"
		destBits _ self oopForPointer: (interpreterProxy firstIndexableField: destBits).
	].
	^true
]

{ #category : #'interpreter interface' }
BitBltSimulation >> loadBitBltFrom: bbObj [
	"Load BitBlt from the oop.
	This function is exported for the Balloon engine."
	self export: true.
	^self loadBitBltFrom: bbObj warping: false.
]

{ #category : #'interpreter interface' }
BitBltSimulation >> loadBitBltFrom: bbObj warping: aBool [
	"Load context from BitBlt instance.  Return false if anything is amiss"
	"NOTE this should all be changed to minX/maxX coordinates for simpler clipping
		-- once it works!"
	| ok |
	self inline: false.
	bitBltOop _ bbObj.
	isWarping _ aBool.
	combinationRule _ interpreterProxy fetchInteger: BBRuleIndex ofObject: bitBltOop.
	(interpreterProxy failed
		or: [combinationRule < 0 or: [combinationRule > (OpTableSize - 2)]])
		 ifTrue: [^ false  "operation out of range"].
	(combinationRule >= 16 and: [combinationRule <= 17])
		 ifTrue: [^ false  "fail for old simulated paint, erase modes"].
	sourceForm _ interpreterProxy fetchPointer: BBSourceFormIndex ofObject: bitBltOop.
	noSource _ self ignoreSourceOrHalftone: sourceForm.
	halftoneForm _ interpreterProxy fetchPointer: BBHalftoneFormIndex ofObject: bitBltOop.
	noHalftone _ self ignoreSourceOrHalftone: halftoneForm.

	destForm _ interpreterProxy fetchPointer: BBDestFormIndex ofObject: bbObj.
	((interpreterProxy isPointers: destForm) and: [(interpreterProxy slotSizeOf: destForm) >= 4])
		ifFalse: [^ false].
	ok _ self loadBitBltDestForm.
	ok ifFalse:[^false].

	destX _ self fetchIntOrFloat: BBDestXIndex ofObject: bitBltOop ifNil: 0.
	destY _ self fetchIntOrFloat: BBDestYIndex ofObject: bitBltOop ifNil: 0.
	width _ self fetchIntOrFloat: BBWidthIndex ofObject: bitBltOop ifNil: destWidth.
	height _ self fetchIntOrFloat: BBHeightIndex ofObject: bitBltOop ifNil: destHeight.
		interpreterProxy failed ifTrue: [^ false  "non-integer value"].

	noSource ifTrue:
		[sourceX _ sourceY _ 0]
		ifFalse: 
		[((interpreterProxy isPointers: sourceForm) and: [(interpreterProxy slotSizeOf: sourceForm) >= 4])
			ifFalse: [^ false].
		ok _ self loadBitBltSourceForm.
		ok ifFalse:[^false].
		ok _ self loadColorMap.
		ok ifFalse:[^false].
		"Need the implicit setup here in case of 16<->32 bit conversions"
		(cmFlags bitAnd: ColorMapNewStyle) = 0 ifTrue:[self setupColorMasks].
		sourceX _ self fetchIntOrFloat: BBSourceXIndex ofObject: bitBltOop ifNil: 0.
		sourceY _ self fetchIntOrFloat: BBSourceYIndex ofObject: bitBltOop ifNil: 0].

	ok _ self loadHalftoneForm.
	ok ifFalse:[^false].
	clipX _ self fetchIntOrFloat: BBClipXIndex ofObject: bitBltOop ifNil: 0.
	clipY _ self fetchIntOrFloat: BBClipYIndex ofObject: bitBltOop ifNil: 0.
	clipWidth _ self fetchIntOrFloat: BBClipWidthIndex ofObject: bitBltOop ifNil: destWidth.
	clipHeight _ self fetchIntOrFloat: BBClipHeightIndex ofObject: bitBltOop ifNil: destHeight.
		interpreterProxy failed ifTrue: [^ false  "non-integer value"].
	clipX < 0 ifTrue: [clipWidth _ clipWidth + clipX.  clipX _ 0].
	clipY < 0 ifTrue: [clipHeight _ clipHeight + clipY.  clipY _ 0].
	clipX+clipWidth > destWidth ifTrue: [clipWidth _ destWidth - clipX].
	clipY+clipHeight > destHeight ifTrue: [clipHeight _ destHeight - clipY].
	^ true
]

{ #category : #'interpreter interface' }
BitBltSimulation >> loadBitBltSourceForm [
	"Load the source form for BitBlt. Return false if anything is wrong, true otherwise."
	| sourceBitsSize |
	self inline: true.
	sourceBits _ interpreterProxy fetchPointer: FormBitsIndex ofObject: sourceForm.
	sourceWidth _ self fetchIntOrFloat: FormWidthIndex ofObject: sourceForm.
	sourceHeight _ self fetchIntOrFloat: FormHeightIndex ofObject: sourceForm.
	(sourceWidth >= 0 and: [sourceHeight >= 0])
		ifFalse: [^ false].
	sourceDepth _ interpreterProxy fetchInteger: FormDepthIndex ofObject: sourceForm.
	sourceMSB _ sourceDepth > 0.
	sourceDepth < 0 ifTrue:[sourceDepth _ 0 - sourceDepth].
	"Ignore an integer bits handle for Display in which case 
	the appropriate values will be obtained by calling ioLockSurfaceBits()."
	(interpreterProxy isIntegerObject: sourceBits) ifTrue:[
		"Query for actual surface dimensions"
		(self querySourceSurface: (interpreterProxy integerValueOf: sourceBits))
			ifFalse:[^false].
		sourcePPW _ 32 // sourceDepth.
		sourceBits _ sourcePitch _ 0.
	] ifFalse:[
		sourcePPW _ 32 // sourceDepth.
		sourcePitch _ sourceWidth + (sourcePPW-1) // sourcePPW * 4.
		sourceBitsSize _ interpreterProxy byteSizeOf: sourceBits.
		((interpreterProxy isWordsOrBytes: sourceBits)
			and: [sourceBitsSize = (sourcePitch * sourceHeight)])
			ifFalse: [^ false].
		"Skip header since external bits don't have one"
		sourceBits _ self oopForPointer: (interpreterProxy firstIndexableField: sourceBits).
	].
	^true
]

{ #category : #'interpreter interface' }
BitBltSimulation >> loadColorMap [
	"ColorMap, if not nil, must be longWords, and 
	2^N long, where N = sourceDepth for 1, 2, 4, 8 bits, 
	or N = 9, 12, or 15 (3, 4, 5 bits per color) for 16 or 32 bits."
	| cmSize oldStyle oop cmOop |
	self inline: true.
	cmFlags _ cmMask _ cmBitsPerColor _ 0.
	cmShiftTable _ nil.
	cmMaskTable _ nil.
	cmLookupTable _ nil.
	cmOop _ interpreterProxy fetchPointer: BBColorMapIndex ofObject: bitBltOop.
	cmOop = interpreterProxy nilObject ifTrue:[^true].
	cmFlags _ ColorMapPresent. "even if identity or somesuch - may be cleared later"
	oldStyle _ false.
	(interpreterProxy isWords: cmOop) ifTrue:[
		"This is an old-style color map (indexed only, with implicit RGBA conversion)"
		cmSize _ interpreterProxy slotSizeOf: cmOop.
		cmLookupTable _ interpreterProxy firstIndexableField: cmOop.
		oldStyle _ true.
	] ifFalse: [
		"A new-style color map (fully qualified)"
		((interpreterProxy isPointers: cmOop) 
			and:[(interpreterProxy slotSizeOf: cmOop) >= 3]) ifFalse:[^false].
		cmShiftTable _ self loadColorMapShiftOrMaskFrom:
			(interpreterProxy fetchPointer: 0 ofObject: cmOop).
		cmMaskTable _ self loadColorMapShiftOrMaskFrom:
			(interpreterProxy fetchPointer: 1 ofObject: cmOop).
		oop _ interpreterProxy fetchPointer: 2 ofObject: cmOop.
		oop = interpreterProxy nilObject 
			ifTrue:[cmSize _ 0]
			ifFalse:[(interpreterProxy isWords: oop) ifFalse:[^false].
					cmSize _ (interpreterProxy slotSizeOf: oop).
					cmLookupTable _ interpreterProxy firstIndexableField: oop].
		cmFlags _ cmFlags bitOr: ColorMapNewStyle.
	].
	(cmSize bitAnd: cmSize - 1) = 0 ifFalse:[^false].
	cmMask _ cmSize - 1.
	cmBitsPerColor _ 0.
	cmSize = 512 ifTrue: [cmBitsPerColor _ 3].
	cmSize = 4096 ifTrue: [cmBitsPerColor _ 4].
	cmSize = 32768 ifTrue: [cmBitsPerColor _ 5].
	cmSize = 0
		ifTrue:[cmLookupTable _ nil. cmMask _ 0]
		ifFalse:[cmFlags _ cmFlags bitOr: ColorMapIndexedPart].
	oldStyle "needs implicit conversion"
		ifTrue:[	self setupColorMasks].
	"Check if colorMap is just identity mapping for RGBA parts"
	(self isIdentityMap: cmShiftTable with: cmMaskTable)
		ifTrue:[ cmMaskTable _ nil. cmShiftTable _ nil ]
		ifFalse:[ cmFlags _ cmFlags bitOr: ColorMapFixedPart].
	^true
]

{ #category : #'interpreter interface' }
BitBltSimulation >> loadColorMapShiftOrMaskFrom: mapOop [
	self returnTypeC:'void *'.
	mapOop = interpreterProxy nilObject ifTrue:[^nil].
	(interpreterProxy isIntegerObject: mapOop) 
		ifTrue:[interpreterProxy primitiveFail. ^nil].
	((interpreterProxy isWords: mapOop) 
		and:[(interpreterProxy slotSizeOf: mapOop) = 4])
			ifFalse:[interpreterProxy primitiveFail. ^nil].
	^interpreterProxy firstIndexableField: mapOop
]

{ #category : #'interpreter interface' }
BitBltSimulation >> loadHalftoneForm [
	"Load the halftone form"
	| halftoneBits |
	self inline: true.
	noHalftone ifTrue:[
		halftoneBase _ nil.
		^true].
	((interpreterProxy isPointers: halftoneForm) and: [(interpreterProxy slotSizeOf: halftoneForm) >= 4])
		ifTrue:
		["Old-style 32xN monochrome halftone Forms"
		halftoneBits _ interpreterProxy fetchPointer: FormBitsIndex ofObject: halftoneForm.
		halftoneHeight _ interpreterProxy fetchInteger: FormHeightIndex ofObject: halftoneForm.
		(interpreterProxy isWords: halftoneBits)
			ifFalse: [noHalftone _ true]]
		ifFalse:
		["New spec accepts, basically, a word array"
		((interpreterProxy isPointers: halftoneForm) not
			and: [interpreterProxy isWords: halftoneForm])
			ifFalse: [^ false].
		halftoneBits _ halftoneForm.
		halftoneHeight _ interpreterProxy slotSizeOf: halftoneBits].
	halftoneBase _ self oopForPointer: (interpreterProxy firstIndexableField: halftoneBits).
	^true
]

{ #category : #'surface support' }
BitBltSimulation >> loadSurfacePlugin [
	"Load the surface support plugin"
	querySurfaceFn _ interpreterProxy ioLoadFunction:'ioGetSurfaceFormat' From:'SurfacePlugin'.
	lockSurfaceFn _ interpreterProxy ioLoadFunction:'ioLockSurface' From:'SurfacePlugin'.
	unlockSurfaceFn _ interpreterProxy ioLoadFunction:'ioUnlockSurface' From:'SurfacePlugin'.
	^querySurfaceFn ~= 0 and:[lockSurfaceFn ~= 0 and:[unlockSurfaceFn ~= 0]]
]

{ #category : #'interpreter interface' }
BitBltSimulation >> loadWarpBltFrom: bbObj [
	^self loadBitBltFrom: bbObj warping: true
]

{ #category : #'surface support' }
BitBltSimulation >> lockSurfaces [
	"Get a pointer to the bits of any OS surfaces."
	"Notes: 
	* For equal source/dest handles only one locking operation is performed.
	This is to prevent locking of overlapping areas which does not work with
	certain APIs (as an example, DirectDraw prevents locking of overlapping areas). 
	A special case for non-overlapping but equal source/dest handle would 
	be possible but we would have to transfer this information over to 
	unlockSurfaces somehow (currently, only one unlock operation is 
	performed for equal source and dest handles). Also, this would require
	a change in the notion of ioLockSurface() which is right now interpreted
	as a hint and not as a requirement to lock only the specific portion of
	the surface.

	* The arguments in ioLockSurface() provide the implementation with
	an explicit hint what area is affected. It can be very useful to
	know the max. affected area beforehand if getting the bits requires expensive
	copy operations (e.g., like a roundtrip to the X server or a glReadPixel op).
	However, the returned pointer *MUST* point to the virtual origin of the surface
	and not to the beginning of the rectangle. The promise made by BitBlt
	is to never access data outside the given rectangle (aligned to 4byte boundaries!)
	so it is okay to return a pointer to the virtual origin that is actually outside
	the valid memory area.

	* The area provided in ioLockSurface() is already clipped (e.g., it will always
	be inside the source and dest boundingBox) but it is not aligned to word boundaries
	yet. It is up to the support code to compute accurate alignment if necessary.

	* Warping always requires the entire source surface to be locked because
	there is no beforehand knowledge about what area will actually be traversed.

	"
	| sourceHandle destHandle l r t b fn |
	self inline: true. "If the CCodeGen learns how to inline #cCode: methods"
	self var: #fn declareC:'sqInt (*fn)(sqInt, sqInt*, sqInt, sqInt, sqInt, sqInt)'.
	hasSurfaceLock _ false.
	destBits = 0 ifTrue:["Blitting *to* OS surface"
		lockSurfaceFn = 0 ifTrue:[self loadSurfacePlugin ifFalse:[^nil]].
		fn _ self cCoerce: lockSurfaceFn to: 'sqInt (*)(sqInt, sqInt*, sqInt, sqInt, sqInt, sqInt)'.
		destHandle _ interpreterProxy fetchInteger: FormBitsIndex ofObject: destForm.
		(sourceBits = 0 and:[noSource not]) ifTrue:[
			sourceHandle _ interpreterProxy fetchInteger: FormBitsIndex ofObject: sourceForm.
			"Handle the special case of equal source and dest handles"
			(sourceHandle = destHandle) ifTrue:[
				"If we have overlapping source/dest we lock the entire area
				so that there is only one area transmitted"
				isWarping ifFalse:[
					"When warping we always need the entire surface for the source"
					sourceBits _ self cCode:'fn(sourceHandle, &sourcePitch, 0,0, sourceWidth, sourceHeight)'.
				] ifTrue:[
					"Otherwise use overlapping area"
					l _ sx min: dx. r _ (sx max: dx) + bbW.
					t _ sy min: dy. b _ (sy max: sy) + bbH.
					sourceBits _ self cCode:'fn(sourceHandle, &sourcePitch, l, t, r-l, b-t)'.
				].
				destBits _ sourceBits.
				destPitch _ sourcePitch.
				hasSurfaceLock _ true.
				^destBits ~~ 0
			].
			"Fall through - if not equal it'll be handled below"
		].
		destBits _ self cCode:'fn(destHandle, &destPitch, dx, dy, bbW, bbH)'.
		hasSurfaceLock _ true.
	].
	(sourceBits == 0 and:[noSource not]) ifTrue:["Blitting *from* OS surface"
		sourceHandle _ interpreterProxy fetchInteger: FormBitsIndex ofObject: sourceForm.
		lockSurfaceFn = 0 ifTrue:[self loadSurfacePlugin ifFalse:[^nil]].
		fn _ self cCoerce: lockSurfaceFn to: 'sqInt (*)(sqInt, sqInt*, sqInt, sqInt, sqInt, sqInt)'.
		"Warping requiring the entire surface"
		isWarping ifTrue:[
			sourceBits _ self cCode:'fn(sourceHandle, &sourcePitch, 0, 0, sourceWidth, sourceHeight)'.
		] ifFalse:[
			sourceBits _ self cCode:'fn(sourceHandle, &sourcePitch, sx, sy, bbW, bbH)'.
		].
		hasSurfaceLock _ true.
	].
	^destBits ~~ 0 and:[sourceBits ~~ 0 or:[noSource]].
]

{ #category : #'color mapping' }
BitBltSimulation >> mapPixel: sourcePixel flags: mapperFlags [
	"Color map the given source pixel."
	| pv |
	self inline: true.
	pv _ sourcePixel.
	(mapperFlags bitAnd: ColorMapPresent) ~= 0 ifTrue:[
		(mapperFlags bitAnd: ColorMapFixedPart) ~= 0 ifTrue:[
			pv _ self rgbMapPixel: sourcePixel flags: mapperFlags.
			"avoid introducing transparency by color reduction"
			(pv = 0 and:[sourcePixel ~= 0]) ifTrue:[pv _ 1]].
		(mapperFlags bitAnd: ColorMapIndexedPart) ~= 0
			ifTrue:[pv _ cmLookupTable at: (pv bitAnd: cmMask)].
	].
	^pv
]

{ #category : #'combination rules' }
BitBltSimulation >> merge: sourceWord with: destinationWord [
	| mergeFnwith |
	"Sender warpLoop is too big to include this in-line"
	self var: #mergeFnwith declareC: 'sqInt (*mergeFnwith)(sqInt, sqInt)'.
	mergeFnwith _ self cCoerce: (opTable at: combinationRule+1) to: 'sqInt (*)(sqInt, sqInt)'.
	mergeFnwith.  "null ref for compiler"

	^ self mergeFn: sourceWord with: destinationWord
]

{ #category : #'initialize-release' }
BitBltSimulation >> moduleUnloaded: aModuleName [
	"The module with the given name was just unloaded.
	Make sure we have no dangling references."
	self export: true.
	self var: #aModuleName type: 'char *'.
	(aModuleName strcmp: 'SurfacePlugin') = 0 ifTrue:[
		"The surface plugin just shut down. How nasty."
		querySurfaceFn _ lockSurfaceFn _ unlockSurfaceFn _ 0.
	].
]

{ #category : #'combination rules' }
BitBltSimulation >> partitionedAND: word1 to: word2 nBits: nBits nPartitions: nParts [
	"AND word1 to word2 as nParts partitions of nBits each.
	Any field of word1 not all-ones is treated as all-zeroes.
	Used for erasing, eg, brush shapes prior to ORing in a color"
	| mask result |
	mask _ maskTable at: nBits.  "partition mask starts at the right"
	result _ 0.
	1 to: nParts do:
		[:i |
		(word1 bitAnd: mask) = mask
			ifTrue: [result _ result bitOr: (word2 bitAnd: mask)].
		mask _ mask << nBits  "slide left to next partition"].
	^ result

]

{ #category : #'combination rules' }
BitBltSimulation >> partitionedAdd: word1 to: word2 nBits: nBits nPartitions: nParts [
	"Add word1 to word2 as nParts partitions of nBits each.
	This is useful for packed pixels, or packed colors"
	| mask sum result |
	mask _ maskTable at: nBits.  "partition mask starts at the right"
	result _ 0.
	1 to: nParts do:
		[:i |
		sum _ (word1 bitAnd: mask) + (word2 bitAnd: mask).
		sum <= mask  "result must not carry out of partition"
			ifTrue: [result _ result bitOr: sum]
			ifFalse: [result _ result bitOr: mask].
		mask _ mask << nBits  "slide left to next partition"].
	^ result

]

{ #category : #'combination rules' }
BitBltSimulation >> partitionedMax: word1 with: word2 nBits: nBits nPartitions: nParts [
	"Max word1 to word2 as nParts partitions of nBits each"
	| mask result |
	mask _ maskTable at: nBits.  "partition mask starts at the right"
	result _ 0.
	1 to: nParts do:
		[:i |
		result _ result bitOr: ((word2 bitAnd: mask) max: (word1 bitAnd: mask)).
		mask _ mask << nBits  "slide left to next partition"].
	^ result

]

{ #category : #'combination rules' }
BitBltSimulation >> partitionedMin: word1 with: word2 nBits: nBits nPartitions: nParts [
	"Min word1 to word2 as nParts partitions of nBits each"
	| mask result |
	mask _ maskTable at: nBits.  "partition mask starts at the right"
	result _ 0.
	1 to: nParts do:
		[:i |
		result _ result bitOr: ((word2 bitAnd: mask) min: (word1 bitAnd: mask)).
		mask _ mask << nBits  "slide left to next partition"].
	^ result

]

{ #category : #'combination rules' }
BitBltSimulation >> partitionedMul: word1 with: word2 nBits: nBits nPartitions: nParts [
	"Multiply word1 with word2 as nParts partitions of nBits each.
	This is useful for packed pixels, or packed colors.
	Bug in loop version when non-white background"

	| sMask product result dMask |
	sMask _ maskTable at: nBits.  "partition mask starts at the right"
	dMask _  sMask << nBits.
	result _ (((word1 bitAnd: sMask)+1) * ((word2 bitAnd: sMask)+1) - 1 
				bitAnd: dMask) >> nBits.	"optimized first step"
	product _ (((word1>>nBits bitAnd: sMask)+1) * ((word2>>nBits bitAnd: sMask)+1) - 1 bitAnd: dMask).
	result _ result bitOr: (product bitAnd: dMask).
	product _ (((word1>>(2*nBits) bitAnd: sMask)+1) * ((word2>>(2*nBits) bitAnd: sMask)+1) - 1 bitAnd: dMask).
	result _ result bitOr: (product bitAnd: dMask) << nBits.
	^ result


"	| sMask product result dMask |
	sMask _ maskTable at: nBits.  'partition mask starts at the right'
	dMask _  sMask << nBits.
	result _ (((word1 bitAnd: sMask)+1) * ((word2 bitAnd: sMask)+1) - 1 
				bitAnd: dMask) >> nBits.	'optimized first step'
	nBits to: nBits * (nParts-1) by: nBits do: [:ofs |
		product _ (((word1>>ofs bitAnd: sMask)+1) * ((word2>>ofs bitAnd: sMask)+1) - 1 bitAnd: dMask).
		result _ result bitOr: (product bitAnd: dMask) << (ofs-nBits)].
	^ result"
]

{ #category : #'combination rules' }
BitBltSimulation >> partitionedSub: word1 from: word2 nBits: nBits nPartitions: nParts [
	"Subtract word1 from word2 as nParts partitions of nBits each.
	This is useful for packed pixels, or packed colors"
	| mask result p1 p2 |
	mask _ maskTable at: nBits.  "partition mask starts at the right"
	result _ 0.
	1 to: nParts do:
		[:i |
		p1 _ word1 bitAnd: mask.
		p2 _ word2 bitAnd: mask.
		p1 < p2  "result is really abs value of thedifference"
			ifTrue: [result _ result bitOr: p2 - p1]
			ifFalse: [result _ result bitOr: p1 - p2].
		mask _ mask << nBits  "slide left to next partition"].
	^ result

]

{ #category : #setup }
BitBltSimulation >> performCopyLoop [
	"Based on the values provided during setup choose and
	perform the appropriate inner loop function."
	self inline: true. "Should be inlined into caller for speed"
	self destMaskAndPointerInit.
	noSource ifTrue: ["Simple fill loop"
		self copyLoopNoSource.
	] ifFalse: ["Loop using source and dest"
		self checkSourceOverlap.
		(sourceDepth ~= destDepth or: [(cmFlags ~= 0) or:[sourceMSB ~= destMSB]]) ifTrue: [
			"If we must convert between pixel depths or use
			color lookups or swap pixels use the general version"
			self copyLoopPixMap.
		] ifFalse: [
			"Otherwise we simple copy pixels and can use a faster version"
			self sourceSkewAndPointerInit.
			self copyLoop.
		]
	].
]

{ #category : #'combination rules' }
BitBltSimulation >> pickSourcePixels: nPixels flags: mapperFlags srcMask: srcMask destMask: dstMask srcShiftInc: srcShiftInc dstShiftInc: dstShiftInc [
	"Pick nPix pixels starting at srcBitIndex from the source, map by the
	color map, and justify them according to dstBitIndex in the resulting destWord."
	| sourceWord destWord sourcePix destPix srcShift dstShift nPix |
	self inline: true. "oh please"
	sourceWord _ self srcLongAt: sourceIndex.
	destWord _ 0.
	srcShift _ srcBitShift. "Hint: Keep in register"
	dstShift _ dstBitShift. "Hint: Keep in register"
	nPix _ nPixels. "always > 0 so we can use do { } while(--nPix);"
	(mapperFlags = (ColorMapPresent bitOr: ColorMapIndexedPart)) ifTrue:[
		"a little optimization for (pretty crucial) blits using indexed lookups only"
		[	"grab, colormap and mix in pixel"
			sourcePix _ sourceWord >> srcShift bitAnd: srcMask.
			destPix _ self tableLookup: cmLookupTable at: (sourcePix bitAnd: cmMask).
			destWord _ destWord bitOr: (destPix bitAnd: dstMask) << dstShift.
			"adjust dest pix index"
			dstShift _ dstShift + dstShiftInc.
			"adjust source pix index"
			((srcShift _ srcShift + srcShiftInc) bitAnd: 16rFFFFFFE0) = 0 ifFalse:[
				sourceMSB ifTrue:[srcShift _ srcShift + 32] ifFalse:[srcShift _ srcShift - 32].
				sourceWord _ self srcLongAt: (sourceIndex _ sourceIndex + 4)].
		(nPix _ nPix - 1) = 0] whileFalse.
	] ifFalse:[
		[	"grab, colormap and mix in pixel"
			sourcePix _ sourceWord >> srcShift bitAnd: srcMask.
			destPix _ self mapPixel: sourcePix flags: mapperFlags.
			destWord _ destWord bitOr: (destPix bitAnd: dstMask) << dstShift.
			"adjust dest pix index"
			dstShift _ dstShift + dstShiftInc.
			"adjust source pix index"
			((srcShift _ srcShift + srcShiftInc) bitAnd: 16rFFFFFFE0) = 0 ifFalse:[
				sourceMSB ifTrue:[srcShift _ srcShift + 32] ifFalse:[srcShift _ srcShift - 32].
				sourceWord _ self srcLongAt: (sourceIndex _ sourceIndex + 4)].
		(nPix _ nPix - 1) = 0] whileFalse.
	].
	srcBitShift _ srcShift. "Store back"
	^destWord

]

{ #category : #'pixel mapping' }
BitBltSimulation >> pickWarpPixelAtX: xx y: yy [
	"Pick a single pixel from the source for WarpBlt.
	Note: This method is crucial for WarpBlt speed w/o smoothing
	and still relatively important when smoothing is used."
	| x y srcIndex sourceWord sourcePix |
	self inline: true. "*please*"

	"note: it would be much faster if we could just
	avoid these stupid tests for being inside sourceForm."
	(xx < 0 or:[yy < 0 or:[
		(x _ xx >> BinaryPoint) >= sourceWidth or:[
			(y _ yy >> BinaryPoint) >= sourceHeight]]]) ifTrue:[^0]. "out of bounds"

	"Fetch source word.
	Note: We should really update srcIndex with sx and sy so that
	we don't have to do the computation below. We might even be
	able to simplify the out of bounds test from above."
	srcIndex _ sourceBits + (y * sourcePitch) + (x >> warpAlignShift * 4).
	sourceWord _ self srcLongAt: srcIndex.

	"Extract pixel from word"
	srcBitShift _ warpBitShiftTable at: (x bitAnd: warpAlignMask).
	sourcePix _ sourceWord >> srcBitShift bitAnd: warpSrcMask.
	^sourcePix
]

{ #category : #'combination rules' }
BitBltSimulation >> pixClear: sourceWord with: destinationWord [
	"Clear all pixels in destinationWord for which the pixels of sourceWord have the same values. Used to clear areas of some constant color to zero."
	| mask result nBits pv |
	self inline: false.
	destDepth = 32 ifTrue:[
		sourceWord = destinationWord ifTrue:[^0] ifFalse:[^destinationWord].
	].
	nBits := destDepth.
	mask _ maskTable at: nBits.  "partition mask starts at the right"
	result _ 0.
	1 to: destPPW do:[:i |
		pv := destinationWord bitAnd: mask.
		(sourceWord bitAnd: mask) = pv ifTrue:[pv := 0].
		result := result bitOr: pv.
		mask := mask << nBits "slide left to next partition"].
	^ result
]

{ #category : #'combination rules' }
BitBltSimulation >> pixMask: sourceWord with: destinationWord [
	self inline: false.
	^ self partitionedAND: sourceWord bitInvert32 to: destinationWord
					nBits: destDepth nPartitions: destPPW
]

{ #category : #'combination rules' }
BitBltSimulation >> pixPaint: sourceWord with: destinationWord [
	self inline: false.
	sourceWord = 0 ifTrue: [^ destinationWord].
	^ sourceWord bitOr:
		(self partitionedAND: sourceWord bitInvert32 to: destinationWord
						nBits: destDepth nPartitions: destPPW)
]

{ #category : #'combination rules' }
BitBltSimulation >> pixSwap: sourceWord with: destWord [
	"Swap the pixels in destWord"
	| result shift lowMask highMask |
	self inline: false.
	destPPW = 1 ifTrue:[^destWord]. "a single pixel per word"
	result _ 0.
	lowMask _ (1 << destDepth) - 1. "mask low pixel"
	highMask _ lowMask << (destPPW-1 * destDepth). "mask high pixel"
	shift _ 32 - destDepth.
	result _ result bitOr: (
				(destWord bitAnd: lowMask) << shift bitOr:
					(destWord bitAnd: highMask) >> shift).
	destPPW <= 2 ifTrue:[^result].
	2 to: destPPW // 2 do:[:i|
		lowMask _ lowMask << destDepth.
		highMask _ highMask >> destDepth.
		shift _ shift - (destDepth * 2).
		result _ result bitOr: (
					(destWord bitAnd: lowMask) << shift bitOr:
						(destWord bitAnd: highMask) >> shift)].
	^result
]

{ #category : #primitives }
BitBltSimulation >> primitiveCopyBits [
	"Invoke the copyBits primitive. If the destination is the display, then copy it to the screen."
	| rcvr |
	self export: true.
	rcvr _ interpreterProxy stackValue: interpreterProxy methodArgumentCount.
	(self loadBitBltFrom: rcvr)  ifFalse:[^interpreterProxy primitiveFail].
	self copyBits.
	interpreterProxy failed ifTrue:[^nil].
	self showDisplayBits.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy pop: interpreterProxy methodArgumentCount.
	(combinationRule = 22) | (combinationRule = 32) ifTrue:[
		interpreterProxy pop: 1.
		^ interpreterProxy pushInteger: bitCount].
]

{ #category : #primitives }
BitBltSimulation >> primitiveDisplayString [

	| kernDelta xTable glyphMap stopIndex startIndex sourceString bbObj maxGlyph ascii glyphIndex sourcePtr left quickBlt |
	self export: true.
	self var: #sourcePtr type: 'char *'.
	interpreterProxy methodArgumentCount = 6 
		ifFalse:[^interpreterProxy primitiveFail].
	kernDelta _ interpreterProxy stackIntegerValue: 0.
	xTable _ interpreterProxy stackObjectValue: 1.
	glyphMap _ interpreterProxy stackObjectValue: 2.
	((interpreterProxy fetchClassOf: xTable) = interpreterProxy classArray and:[
		(interpreterProxy fetchClassOf: glyphMap) = interpreterProxy classArray])
			ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy slotSizeOf: glyphMap) = 256 ifFalse:[^interpreterProxy primitiveFail].
	interpreterProxy failed ifTrue:[^nil].
	maxGlyph _ (interpreterProxy slotSizeOf: xTable) - 2.

	stopIndex _ interpreterProxy stackIntegerValue: 3.
	startIndex _ interpreterProxy stackIntegerValue: 4.
	sourceString _ interpreterProxy stackObjectValue: 5.
	(interpreterProxy isBytes: sourceString) ifFalse:[^interpreterProxy primitiveFail].
	(startIndex > 0 and:[stopIndex > 0 and:[
		stopIndex <= (interpreterProxy byteSizeOf: sourceString)]])
			ifFalse:[^interpreterProxy primitiveFail].

	bbObj _ interpreterProxy stackObjectValue: 6.
	(self loadBitBltFrom: bbObj) ifFalse:[^interpreterProxy primitiveFail].
	(combinationRule = 30 or:[combinationRule = 31]) "needs extra source alpha"
		ifTrue:[^interpreterProxy primitiveFail].
	"See if we can go directly into copyLoopPixMap (usually we can)"
	quickBlt _ destBits ~= 0 "no OS surfaces please"
				and:[sourceBits ~= 0 "and again"
				and:[noSource = false "needs a source"
				and:[sourceForm ~= destForm "no blits onto self"
				and:[(cmFlags ~= 0 
						or:[sourceMSB ~= destMSB 
						or:[sourceDepth ~= destDepth]]) "no point using slower version"
				]]]].
	left _ destX.
	sourcePtr _ interpreterProxy firstIndexableField: sourceString.
	startIndex to: stopIndex do:[:charIndex|
		ascii _ interpreterProxy byteAtPointer: sourcePtr + charIndex - 1.
		glyphIndex _ interpreterProxy fetchInteger: ascii ofObject: glyphMap.
		(glyphIndex < 0 or:[glyphIndex > maxGlyph]) 
			ifTrue:[^interpreterProxy primitiveFail].
		sourceX _ interpreterProxy fetchInteger: glyphIndex ofObject: xTable.
		width _ (interpreterProxy fetchInteger: glyphIndex+1 ofObject: xTable) - sourceX.
		interpreterProxy failed ifTrue:[^nil].
		self clipRange.	"Must clip here"
		(bbW > 0 and:[bbH > 0]) ifTrue: [
			quickBlt ifTrue:[
				self destMaskAndPointerInit.
				self copyLoopPixMap.
				"both, hDir and vDir are known to be > 0"
				affectedL _ dx.
				affectedR _ dx + bbW.
				affectedT _ dy.
				affectedB _ dy + bbH.
			] ifFalse:[self copyBits]].
		interpreterProxy failed ifTrue:[^nil].
		destX _ destX + width + kernDelta.
	 ].
	affectedL _ left.
	self showDisplayBits.
	interpreterProxy pop: 6. "pop args, return rcvr"
]

{ #category : #primitives }
BitBltSimulation >> primitiveDrawLoop [
	"Invoke the line drawing primitive."
	| rcvr xDelta yDelta |
	self export: true.
	rcvr _ interpreterProxy stackValue: 2.
	xDelta _ interpreterProxy stackIntegerValue: 1.
	yDelta _ interpreterProxy stackIntegerValue: 0.
	(self loadBitBltFrom: rcvr) ifFalse:[^interpreterProxy primitiveFail].
	interpreterProxy failed ifFalse:[
		self drawLoopX: xDelta Y: yDelta.
		self showDisplayBits].
	interpreterProxy failed ifFalse:[interpreterProxy pop: 2].
]

{ #category : #primitives }
BitBltSimulation >> primitiveWarpBits [
	"Invoke the warpBits primitive. If the destination is the display, then copy it to the screen."
	| rcvr |
	self export: true.
	rcvr _ interpreterProxy stackValue: interpreterProxy methodArgumentCount.
	(self loadWarpBltFrom: rcvr) 
		ifFalse:[^interpreterProxy primitiveFail].
	self warpBits.
	interpreterProxy failed ifTrue:[^nil].
	self showDisplayBits.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy pop: interpreterProxy methodArgumentCount.
]

{ #category : #'surface support' }
BitBltSimulation >> queryDestSurface: handle [
	"Query the dimension of an OS surface.
	This method is provided so that in case the inst vars of the
	source form are broken, *actual* values of the OS surface
	can be obtained. This might, for instance, happen if the user
	resizes the main window.
	Note: Moved to a separate function for better inlining of the caller."
	querySurfaceFn = 0 ifTrue:[self loadSurfacePlugin ifFalse:[^false]].
	^(self cCode:' ((sqInt (*) (sqInt, sqInt*, sqInt*, sqInt*, sqInt*))querySurfaceFn)
		(handle, &destWidth, &destHeight, &destDepth, &destMSB)'
			 inSmalltalk:[false])
]

{ #category : #'surface support' }
BitBltSimulation >> querySourceSurface: handle [
	"Query the dimension of an OS surface.
	This method is provided so that in case the inst vars of the
	source form are broken, *actual* values of the OS surface
	can be obtained. This might, for instance, happen if the user
	resizes the main window.
	Note: Moved to a separate function for better inlining of the caller."
	querySurfaceFn = 0 ifTrue:[self loadSurfacePlugin ifFalse:[^false]].
	^(self cCode:' ((sqInt (*) (sqInt, sqInt*, sqInt*, sqInt*, sqInt*))querySurfaceFn)
		(handle, &sourceWidth, &sourceHeight, &sourceDepth, &sourceMSB)'
			inSmalltalk:[false])
]

{ #category : #'combination rules' }
BitBltSimulation >> rgbAdd: sourceWord with: destinationWord [
	self inline: false.
	destDepth < 16 ifTrue:
		["Add each pixel separately"
		^ self partitionedAdd: sourceWord to: destinationWord
						nBits: destDepth nPartitions: destPPW].
	destDepth = 16 ifTrue:
		["Add RGB components of each pixel separately"
		^ (self partitionedAdd: sourceWord to: destinationWord
						nBits: 5 nPartitions: 3)
		+ ((self partitionedAdd: sourceWord>>16 to: destinationWord>>16
						nBits: 5 nPartitions: 3) << 16)]
	ifFalse:
		["Add RGB components of the pixel separately"
		^ self partitionedAdd: sourceWord to: destinationWord
						nBits: 8 nPartitions: 3]
]

{ #category : #'combination rules' }
BitBltSimulation >> rgbDiff: sourceWord with: destinationWord [
	"Subract the pixels in the source and destination, color by color,
	and return the sum of the absolute value of all the differences.
	For non-rgb, return the number of differing pixels."
	| pixMask destShifted sourceShifted destPixVal bitsPerColor rgbMask sourcePixVal diff maskShifted |
	self inline: false.
	pixMask _ maskTable at: destDepth.
	destDepth = 16
		ifTrue: [bitsPerColor _ 5.  rgbMask _ 16r1F]
		ifFalse: [bitsPerColor _ 8.  rgbMask _ 16rFF].
	maskShifted _ destMask.
	destShifted _ destinationWord.
	sourceShifted _ sourceWord.
	1 to: destPPW do:
		[:i |
		(maskShifted bitAnd: pixMask) > 0 ifTrue:
			["Only tally pixels within the destination rectangle"
			destPixVal _ destShifted bitAnd: pixMask.
			sourcePixVal _ sourceShifted bitAnd: pixMask.
			destDepth < 16
				ifTrue: [sourcePixVal = destPixVal
							ifTrue: [diff _ 0]
							ifFalse: [diff _ 1]]
				ifFalse: [diff _ (self partitionedSub: sourcePixVal from: destPixVal
								nBits: bitsPerColor nPartitions: 3).
						diff _ (diff bitAnd: rgbMask)
							+ (diff>>bitsPerColor bitAnd: rgbMask)
							+ ((diff>>bitsPerColor)>>bitsPerColor bitAnd: rgbMask)].
			bitCount _ bitCount + diff].
		maskShifted _ maskShifted >> destDepth.
		sourceShifted _ sourceShifted >> destDepth.
		destShifted _ destShifted >> destDepth].
	^ destinationWord  "For no effect on dest"

]

{ #category : #'color mapping' }
BitBltSimulation >> rgbMap16To32: sourcePixel [
	"Convert the given 16bit pixel value to a 32bit RGBA value.
 	Note: This method is intended to deal with different source formats."
	^(((sourcePixel bitAnd: 31) << 3) bitOr:
		((sourcePixel bitAnd: 16r3E0) << 6)) bitOr:
			((sourcePixel bitAnd: 16r7C00) << 9)
]

{ #category : #'color mapping' }
BitBltSimulation >> rgbMap32To32: sourcePixel [
	"Convert the given 32bit pixel value to a 32bit RGBA value.
 	Note: This method is intended to deal with different source formats."
	^sourcePixel "For now do it simple"
]

{ #category : #'pixel mapping' }
BitBltSimulation >> rgbMap: sourcePixel from: nBitsIn to: nBitsOut [
	"Convert the given pixel value with nBitsIn bits for each color component to a pixel value with nBitsOut bits for each color component. Typical values for nBitsIn/nBitsOut are 3, 5, or 8."
	| mask d srcPix destPix |
	self inline: true.
	(d _ nBitsOut - nBitsIn) > 0
		ifTrue:
			["Expand to more bits by zero-fill"
			mask _ (1 << nBitsIn) - 1.  "Transfer mask"
			srcPix _ sourcePixel << d.
			mask _ mask << d.
			destPix _ srcPix bitAnd: mask.
			mask _ mask << nBitsOut.
			srcPix _ srcPix << d.
			^ destPix + (srcPix bitAnd: mask)
				 	+ (srcPix << d bitAnd: mask << nBitsOut)]
		ifFalse:
			["Compress to fewer bits by truncation"
			d = 0 ifTrue:
				[nBitsIn = 5 ifTrue:
					["Sometimes called with 16 bits, though pixel is 15,
					but we must never return more than 15."
					^ sourcePixel bitAnd: 16r7FFF].
				nBitsIn = 8 ifTrue:
					["Sometimes called with 32 bits, though pixel is 24,
					but we must never return more than 24."
					^ sourcePixel bitAnd: 16rFFFFFF].
				^ sourcePixel].  "no compression"
			sourcePixel = 0 ifTrue: [^ sourcePixel].  "always map 0 (transparent) to 0"
			d _ nBitsIn - nBitsOut.
			mask _ (1 << nBitsOut) - 1.  "Transfer mask"
			srcPix _ sourcePixel >> d.
			destPix _ srcPix bitAnd: mask.
			mask _ mask << nBitsOut.
			srcPix _ srcPix >> d.
			destPix _ destPix + (srcPix bitAnd: mask)
					+ (srcPix >> d bitAnd: mask << nBitsOut).
			destPix = 0 ifTrue: [^ 1].  "Dont fall into transparent by truncation"
			^ destPix]
]

{ #category : #'color mapping' }
BitBltSimulation >> rgbMapPixel: sourcePixel flags: mapperFlags [
	"Perform the RGBA conversion for the given source pixel"
	| val |
	self inline: true.
	val _ 			((sourcePixel bitAnd: (cmMaskTable at: 0)) bitShift: (cmShiftTable at: 0)).
	val _ val bitOr: ((sourcePixel bitAnd: (cmMaskTable at: 1)) bitShift: (cmShiftTable at: 1)).
	val _ val bitOr: ((sourcePixel bitAnd: (cmMaskTable at: 2)) bitShift: (cmShiftTable at: 2)).
		  ^val bitOr: ((sourcePixel bitAnd: (cmMaskTable at: 3)) bitShift: (cmShiftTable at: 3)).

]

{ #category : #'combination rules' }
BitBltSimulation >> rgbMax: sourceWord with: destinationWord [
	self inline: false.
	destDepth < 16 ifTrue:
		["Max each pixel separately"
		^ self partitionedMax: sourceWord with: destinationWord
						nBits: destDepth nPartitions: destPPW].
	destDepth = 16 ifTrue:
		["Max RGB components of each pixel separately"
		^ (self partitionedMax: sourceWord with: destinationWord
						nBits: 5 nPartitions: 3)
		+ ((self partitionedMax: sourceWord>>16 with: destinationWord>>16
						nBits: 5 nPartitions: 3) << 16)]
	ifFalse:
		["Max RGB components of the pixel separately"
		^ self partitionedMax: sourceWord with: destinationWord
						nBits: 8 nPartitions: 3]
]

{ #category : #'combination rules' }
BitBltSimulation >> rgbMin: sourceWord with: destinationWord [
	self inline: false.
	destDepth < 16 ifTrue:
		["Min each pixel separately"
		^ self partitionedMin: sourceWord with: destinationWord
						nBits: destDepth nPartitions: destPPW].
	destDepth = 16 ifTrue:
		["Min RGB components of each pixel separately"
		^ (self partitionedMin: sourceWord with: destinationWord
						nBits: 5 nPartitions: 3)
		+ ((self partitionedMin: sourceWord>>16 with: destinationWord>>16
						nBits: 5 nPartitions: 3) << 16)]
	ifFalse:
		["Min RGB components of the pixel separately"
		^ self partitionedMin: sourceWord with: destinationWord
						nBits: 8 nPartitions: 3]
]

{ #category : #'combination rules' }
BitBltSimulation >> rgbMinInvert: wordToInvert with: destinationWord [
	| sourceWord |
	self inline: false.
	sourceWord _ wordToInvert bitInvert32.
	destDepth < 16 ifTrue:
		["Min each pixel separately"
		^ self partitionedMin: sourceWord with: destinationWord
						nBits: destDepth nPartitions: destPPW].
	destDepth = 16 ifTrue:
		["Min RGB components of each pixel separately"
		^ (self partitionedMin: sourceWord with: destinationWord
						nBits: 5 nPartitions: 3)
		+ ((self partitionedMin: sourceWord>>16 with: destinationWord>>16
						nBits: 5 nPartitions: 3) << 16)]
	ifFalse:
		["Min RGB components of the pixel separately"
		^ self partitionedMin: sourceWord with: destinationWord
						nBits: 8 nPartitions: 3]
]

{ #category : #'combination rules' }
BitBltSimulation >> rgbMul: sourceWord with: destinationWord [
	self inline: false.
	destDepth < 16 ifTrue:
		["Mul each pixel separately"
		^ self partitionedMul: sourceWord with: destinationWord
						nBits: destDepth nPartitions: destPPW].
	destDepth = 16 ifTrue:
		["Mul RGB components of each pixel separately"
		^ (self partitionedMul: sourceWord with: destinationWord
						nBits: 5 nPartitions: 3)
		+ ((self partitionedMul: sourceWord>>16 with: destinationWord>>16
						nBits: 5 nPartitions: 3) << 16)]
	ifFalse:
		["Mul RGB components of the pixel separately"
		^ self partitionedMul: sourceWord with: destinationWord
						nBits: 8 nPartitions: 3]

"	| scanner |
	Display repaintMorphicDisplay.
	scanner _ DisplayScanner quickPrintOn: Display.
	MessageTally time: [0 to: 760 by: 4 do:  [:y |scanner drawString: 'qwrepoiuasfd=)(/&()=#!¡lkjzxv.,mn124+09857907QROIYTOAFDJZXNBNB,M-.,Mqwrepoiuasfd=)(/&()=#!¡lkjzxv.,mn124+09857907QROIYTOAFDJZXNBNB,M-.,M1234124356785678' at: 0@y]]. "
]

{ #category : #'combination rules' }
BitBltSimulation >> rgbSub: sourceWord with: destinationWord [
	self inline: false.
	destDepth < 16 ifTrue:
		["Sub each pixel separately"
		^ self partitionedSub: sourceWord from: destinationWord
						nBits: destDepth nPartitions: destPPW].
	destDepth = 16 ifTrue:
		["Sub RGB components of each pixel separately"
		^ (self partitionedSub: sourceWord from: destinationWord
						nBits: 5 nPartitions: 3)
		+ ((self partitionedSub: sourceWord>>16 from: destinationWord>>16
						nBits: 5 nPartitions: 3) << 16)]
	ifFalse:
		["Sub RGB components of the pixel separately"
		^ self partitionedSub: sourceWord from: destinationWord
						nBits: 8 nPartitions: 3]
]

{ #category : #'interpreter interface' }
BitBltSimulation >> setupColorMasks [
	"WARNING: For WarpBlt w/ smoothing the source depth is wrong here!"
	| bits targetBits |
	bits _ targetBits _ 0.
	sourceDepth <= 8 ifTrue:[^nil].
	sourceDepth = 16 ifTrue:[bits _ 5].
	sourceDepth = 32 ifTrue:[bits _ 8].

	cmBitsPerColor = 0
		ifTrue:["Convert to destDepth"
				destDepth <= 8 ifTrue:[^nil].
				destDepth = 16 ifTrue:[targetBits _ 5].
				destDepth = 32 ifTrue:[targetBits _ 8]]
		ifFalse:[targetBits _ cmBitsPerColor].

	self setupColorMasksFrom: bits to: targetBits
]

{ #category : #'interpreter interface' }
BitBltSimulation >> setupColorMasksFrom: srcBits to: targetBits [
	"Setup color masks for converting an incoming RGB pixel value from srcBits to targetBits."
	| mask shifts masks deltaBits |
	self var: #shifts declareC:'static int shifts[4] = {0, 0, 0, 0}'.
	self var: #masks declareC:'static unsigned int masks[4] = {0, 0, 0, 0}'.
	self cCode:'' inSmalltalk:[
		shifts _ CArrayAccessor on: (IntegerArray new: 4).
		masks _ CArrayAccessor on: (WordArray new: 4).
	].
	deltaBits _ targetBits - srcBits.
	deltaBits = 0 ifTrue:[^0].
	deltaBits <= 0
		ifTrue:[	mask _ 1 << targetBits - 1.
				"Mask for extracting a color part of the source"
				masks at: RedIndex put: mask << (srcBits*2 - deltaBits).
				masks at: GreenIndex put: mask << (srcBits - deltaBits).
				masks at: BlueIndex put: mask << (0 - deltaBits).
				masks at: AlphaIndex put: 0]
		ifFalse:[	mask _ 1 << srcBits - 1.
				"Mask for extracting a color part of the source"
				masks at: RedIndex put: mask << (srcBits*2).
				masks at: GreenIndex put: mask << srcBits.
				masks at: BlueIndex put: mask].

	"Shifts for adjusting each value in a cm RGB value"
	shifts at: RedIndex put: deltaBits * 3.
	shifts at: GreenIndex put: deltaBits * 2.
	shifts at: BlueIndex put: deltaBits.
	shifts at: AlphaIndex put: 0.

	cmShiftTable _ shifts.
	cmMaskTable _ masks.
	cmFlags _ cmFlags bitOr: (ColorMapPresent bitOr: ColorMapFixedPart).

]

{ #category : #'interpreter interface' }
BitBltSimulation >> showDisplayBits [
	interpreterProxy 
		showDisplayBits: destForm
		Left: affectedL
		Top: affectedT
		Right: affectedR
		Bottom: affectedB
]

{ #category : #setup }
BitBltSimulation >> sourceSkewAndPointerInit [
	"This is only used when source and dest are same depth,
	ie, when the barrel-shift copy loop is used."
	| dWid sxLowBits dxLowBits pixPerM1 |
	self inline: true.
	pixPerM1 _ destPPW - 1.  "A mask, assuming power of two"
	sxLowBits _ sx bitAnd: pixPerM1.
	dxLowBits _ dx bitAnd: pixPerM1.
	"check if need to preload buffer
	(i.e., two words of source needed for first word of destination)"
	hDir > 0 ifTrue:
		["n Bits stored in 1st word of dest"
		dWid _ bbW min: destPPW - dxLowBits.
		preload _ (sxLowBits + dWid) > pixPerM1]
	ifFalse:
		[dWid _ bbW min: dxLowBits + 1.
		preload _ (sxLowBits - dWid + 1) < 0].

	"calculate right-shift skew from source to dest"
	sourceMSB
		ifTrue:[skew _ (sxLowBits - dxLowBits) * destDepth] 
		ifFalse:[skew _ (dxLowBits - sxLowBits) * destDepth].  " -32..32 "
	preload ifTrue: 
		[skew < 0
			ifTrue: [skew _ skew+32]
			ifFalse: [skew _ skew-32]].

	"Calc byte addr and delta from longWord info"
	sourceIndex _ sourceBits + (sy * sourcePitch) + ((sx // (32//sourceDepth)) *4).
	"calculate increments from end of 1 line to start of next"
	sourceDelta _ (sourcePitch * vDir) - (4 * (nWords * hDir)).

	preload ifTrue:
		["Compensate for extra source word fetched"
		sourceDelta _ sourceDelta - (4*hDir)].
]

{ #category : #'combination rules' }
BitBltSimulation >> sourceWord: sourceWord with: destinationWord [
	^sourceWord
]

{ #category : #'memory access' }
BitBltSimulation >> srcLongAt: idx [

	^self long32At: idx
]

{ #category : #'combination rules' }
BitBltSimulation >> subWord: sourceWord with: destinationWord [
	^sourceWord - destinationWord
]

{ #category : #'memory access' }
BitBltSimulation >> tableLookup: table at: index [
	"Note: Nasty coercion only necessary for the non-inlined version of this method in C. Duh? Oh well, here's the full story. The code below will definitely be inlined so everything that calls this method is fine. But... the translator doesn't quite prune this method so it generates a C function that tries to attempt an array access on an int - and most compilers don't like this. If you don't know what I'm talking about try to remove the C coercion and you'll see what happens when you try to compile a new VM..."
	self var: #table type: 'unsigned int *'.
	^table at: index

]

{ #category : #'combination rules' }
BitBltSimulation >> tallyIntoMap: sourceWord with: destinationWord [
	"Tally pixels into the color map.  Those tallied are exactly those
	in the destination rectangle.  Note that the source should be 
	specified == destination, in order for the proper color map checks 
	to be performed at setup."
	| mapIndex pixMask destShifted maskShifted pixVal |
	self inline: false.
	(cmFlags bitAnd: (ColorMapPresent bitOr: ColorMapIndexedPart)) = 
		(ColorMapPresent bitOr: ColorMapIndexedPart)
			ifFalse: [^ destinationWord "no op"].
	pixMask _ maskTable at: destDepth.
	destShifted _ destinationWord.
	maskShifted _ destMask.
	1 to: destPPW do:
		[:i |
		(maskShifted bitAnd: pixMask) = 0 ifFalse:
			["Only tally pixels within the destination rectangle"
			pixVal _ destShifted bitAnd: pixMask.
			destDepth < 16
				ifTrue: [mapIndex _ pixVal]
				ifFalse: [destDepth = 16
					ifTrue: [mapIndex _ self rgbMap: pixVal from: 5 to: cmBitsPerColor]
					ifFalse: [mapIndex _ self rgbMap: pixVal from: 8 to: cmBitsPerColor]].
			self tallyMapAt: mapIndex put: (self tallyMapAt: mapIndex) + 1].
		maskShifted _ maskShifted >> destDepth.
		destShifted _ destShifted >> destDepth].
	^ destinationWord  "For no effect on dest"
]

{ #category : #'memory access' }
BitBltSimulation >> tallyMapAt: idx [
	"Return the word at position idx from the colorMap"
	^cmLookupTable at: (idx bitAnd: cmMask)
]

{ #category : #'memory access' }
BitBltSimulation >> tallyMapAt: idx put: value [
	"Store the word at position idx in the colorMap"
	^cmLookupTable at: (idx bitAnd: cmMask) put: value
]

{ #category : #setup }
BitBltSimulation >> tryCopyingBitsQuickly [
	"Shortcut for stuff that's being run from the balloon engine.
	Since we do this at each scan line we should avoid the expensive 
	setup for source and destination."
	self inline: true.
	"We need a source."
	noSource ifTrue:[^false].
	"We handle only combinationRule 34"
	(combinationRule = 34) ifFalse:[^false].
	"We handle only sourceDepth 32"
	(sourceDepth = 32) ifFalse:[^false].
	"We don't handle overlaps"
	(sourceForm = destForm) ifTrue:[^false].
	"We need at least 8bit deep dest forms"
	(destDepth < 8) ifTrue:[^false].
	"If 8bit, then we want a color map"
	(destDepth = 8 and:[(cmFlags bitAnd: ColorMapPresent) = 0]) ifTrue:[^false].
	destDepth = 32 
		ifTrue:[self alphaSourceBlendBits32].
	destDepth = 16
		ifTrue:[self alphaSourceBlendBits16].
	destDepth = 8
		ifTrue:[self alphaSourceBlendBits8].
	affectedL _ dx.
	affectedR _ dx + bbW.
	affectedT _ dy.
	affectedB _ dy + bbH.
	^true
]

{ #category : #'surface support' }
BitBltSimulation >> unlockSurfaces [
	"Unlock the bits of any OS surfaces."
	"See the comment in lockSurfaces. Similar rules apply. That is, the area provided in ioUnlockSurface can be used to determine the dirty region after drawing. If a source is unlocked, then the area will be (0,0,0,0) to indicate that no portion is dirty."
	| sourceHandle destHandle destLocked fn |
	self var: #fn declareC:'sqInt (*fn)(sqInt, sqInt, sqInt, sqInt, sqInt)'.
	hasSurfaceLock ifTrue:[
		unlockSurfaceFn = 0 ifTrue:[self loadSurfacePlugin ifFalse:[^nil]].
		fn _ self cCoerce: unlockSurfaceFn to: 'sqInt (*)(sqInt, sqInt, sqInt, sqInt, sqInt)'.
		destLocked _ false.
		destHandle _ interpreterProxy fetchPointer: FormBitsIndex ofObject: destForm.
		(interpreterProxy isIntegerObject: destHandle) ifTrue:[
			destHandle _ interpreterProxy integerValueOf: destHandle.
			"The destBits are always assumed to be dirty"
			self cCode:'fn(destHandle, affectedL, affectedT, affectedR-affectedL, affectedB-affectedT)'.
			destBits _ destPitch _ 0.
			destLocked _ true.
		].
		noSource ifFalse:[
			sourceHandle _ interpreterProxy fetchPointer: FormBitsIndex ofObject: sourceForm.
			(interpreterProxy isIntegerObject: sourceHandle) ifTrue:[
				sourceHandle _ interpreterProxy integerValueOf: sourceHandle.
				"Only unlock sourceHandle if different from destHandle"
				(destLocked and:[sourceHandle = destHandle]) 
					ifFalse:[self cCode: 'fn(sourceHandle, 0, 0, 0, 0)'].
				sourceBits _ sourcePitch _ 0.
			].
		].
		hasSurfaceLock _ false.
	].
]

{ #category : #setup }
BitBltSimulation >> warpBits [
	| ns |
	self inline: true.
	ns _ noSource.  noSource _ true.
		self clipRange.  "noSource suppresses sourceRect clipping"
		noSource _ ns.
	(noSource or: [bbW <= 0 or: [bbH <= 0]]) ifTrue:
		["zero width or height; noop"
		affectedL _ affectedR _ affectedT _ affectedB _ 0.
		^ nil].

 	self lockSurfaces.
	self destMaskAndPointerInit.
	self warpLoop.
 
	hDir > 0
		ifTrue: [affectedL _ dx.
				affectedR _ dx + bbW]
		ifFalse: [affectedL _ dx - bbW + 1.
				affectedR _ dx + 1].
	vDir > 0
		ifTrue: [affectedT _ dy.
				affectedB _ dy + bbH]
		ifFalse: [affectedT _ dy - bbH + 1.
				affectedB _ dy + 1].
	self unlockSurfaces.
]

{ #category : #'inner loop' }
BitBltSimulation >> warpLoop [
	"This version of the inner loop traverses an arbirary quadrilateral
	source, thus producing a general affine transformation."
	| skewWord halftoneWord mergeWord startBits
	  deltaP12x deltaP12y deltaP43x deltaP43y pAx pAy pBx pBy
	  xDelta yDelta smoothingCount sourceMapOop
	  nSteps nPix words destWord endBits mergeFnwith dstShiftInc dstShiftLeft mapperFlags |
	self inline: false.
	self var: #mergeFnwith declareC: 'sqInt (*mergeFnwith)(sqInt, sqInt)'.
	mergeFnwith _ self cCoerce: (opTable at: combinationRule+1) to: 'sqInt (*)(sqInt, sqInt)'.
	mergeFnwith.  "null ref for compiler"

	(interpreterProxy slotSizeOf: bitBltOop) >= (BBWarpBase+12)
		ifFalse: [^ interpreterProxy primitiveFail].
	nSteps _ height-1.  nSteps <= 0 ifTrue: [nSteps _ 1].

	pAx _ self fetchIntOrFloat: BBWarpBase ofObject: bitBltOop.
	words _ self fetchIntOrFloat: BBWarpBase+3 ofObject: bitBltOop.
	deltaP12x _ self deltaFrom: pAx to: words nSteps: nSteps.
	deltaP12x < 0 ifTrue: [pAx _ words - (nSteps*deltaP12x)].

	pAy _ self fetchIntOrFloat: BBWarpBase+1 ofObject: bitBltOop.
	words _ self fetchIntOrFloat: BBWarpBase+4 ofObject: bitBltOop.
	deltaP12y _ self deltaFrom: pAy to: words nSteps: nSteps.
	deltaP12y < 0 ifTrue: [pAy _ words - (nSteps*deltaP12y)].

	pBx _ self fetchIntOrFloat: BBWarpBase+9 ofObject: bitBltOop.
	words _ self fetchIntOrFloat: BBWarpBase+6 ofObject: bitBltOop.
	deltaP43x _ self deltaFrom: pBx to: words nSteps: nSteps.
	deltaP43x < 0 ifTrue: [pBx _ words - (nSteps*deltaP43x)].

	pBy _ self fetchIntOrFloat: BBWarpBase+10 ofObject: bitBltOop.
	words _ self fetchIntOrFloat: BBWarpBase+7 ofObject: bitBltOop.
	deltaP43y _ self deltaFrom: pBy to: words nSteps: nSteps.
	deltaP43y < 0 ifTrue: [pBy _ words - (nSteps*deltaP43y)].

	interpreterProxy failed ifTrue: [^ false].  "ie if non-integers above"
	interpreterProxy methodArgumentCount = 2
		ifTrue: [smoothingCount _ interpreterProxy stackIntegerValue: 1.
				sourceMapOop _ interpreterProxy stackValue: 0.
				sourceMapOop = interpreterProxy nilObject
				ifTrue: [sourceDepth < 16 ifTrue:
					["color map is required to smooth non-RGB dest"
					^ interpreterProxy primitiveFail]]
				ifFalse: [(interpreterProxy slotSizeOf: sourceMapOop)
							< (1 << sourceDepth) ifTrue:
					["sourceMap must be long enough for sourceDepth"
					^ interpreterProxy primitiveFail].
					sourceMapOop _ self oopForPointer: (interpreterProxy firstIndexableField: sourceMapOop)]]
		ifFalse: [smoothingCount _ 1.
				sourceMapOop _ interpreterProxy nilObject].
	nSteps _ width-1.  nSteps <= 0 ifTrue: [nSteps _ 1].
	startBits _ destPPW - (dx bitAnd: destPPW-1).
	endBits _ ((dx + bbW - 1) bitAnd: destPPW-1) + 1.
 	bbW < startBits ifTrue:[startBits _ bbW].

	destY < clipY ifTrue:[
		"Advance increments if there was clipping in y"
		pAx _ pAx + (clipY - destY * deltaP12x).
		pAy _ pAy + (clipY - destY * deltaP12y).
		pBx _ pBx + (clipY - destY * deltaP43x).
		pBy _ pBy + (clipY - destY * deltaP43y)].

	"Setup values for faster pixel fetching."
	self warpLoopSetup.
	"Setup color mapping if not provided"
	(smoothingCount > 1 and:[(cmFlags bitAnd: ColorMapNewStyle) = 0]) ifTrue:[
		cmLookupTable == nil ifTrue:[
			destDepth = 16 ifTrue:[self setupColorMasksFrom: 8 to: 5].
		] ifFalse:[
			self setupColorMasksFrom: 8 to: cmBitsPerColor.
		].
	].
	mapperFlags _ cmFlags bitAnd: ColorMapNewStyle bitInvert32.

	destMSB
		ifTrue:[	dstShiftInc _ 0 - destDepth.
				dstShiftLeft _ 32 - destDepth]
		ifFalse:[	dstShiftInc _ destDepth.
				dstShiftLeft _ 0].
	1 to: bbH do:
		[ :i | "here is the vertical loop..."
		xDelta _ self deltaFrom: pAx to: pBx nSteps: nSteps.
 		xDelta >= 0 ifTrue: [sx _ pAx] ifFalse: [sx _ pBx - (nSteps*xDelta)].
		yDelta _ self deltaFrom: pAy to: pBy nSteps: nSteps.
 		yDelta >= 0 ifTrue: [sy _ pAy] ifFalse: [sy _ pBy - (nSteps*yDelta)].

		destMSB
			ifTrue:[dstBitShift _ 32 - ((dx bitAnd: destPPW - 1) + 1 * destDepth)]
			ifFalse:[dstBitShift _ (dx bitAnd: destPPW - 1) * destDepth].

		(destX < clipX) ifTrue:[
			"Advance increments if there was clipping in x"
			sx _ sx + (clipX - destX * xDelta).
			sy _ sy + (clipX - destX * yDelta).
		].

		noHalftone
			ifTrue: [halftoneWord _ AllOnes]
			ifFalse: [halftoneWord _ self halftoneAt: dy+i-1].
		destMask _ mask1.
		nPix _ startBits.
		"Here is the inner loop..."
		words _ nWords.
			["pick up word"
			smoothingCount = 1 ifTrue:["Faster if not smoothing"
				skewWord _ self warpPickSourcePixels: nPix
								xDeltah: xDelta yDeltah: yDelta
								xDeltav: deltaP12x yDeltav: deltaP12y
								dstShiftInc: dstShiftInc flags: mapperFlags.
			] ifFalse:["more difficult with smoothing"
				skewWord _ self warpPickSmoothPixels: nPix
						xDeltah: xDelta yDeltah: yDelta
						xDeltav: deltaP12x yDeltav: deltaP12y
						sourceMap: sourceMapOop
						smoothing: smoothingCount
						dstShiftInc: dstShiftInc.
			].
			"align next word access to left most pixel"
			dstBitShift _ dstShiftLeft.
			destMask = AllOnes ifTrue:["avoid read-modify-write"
				mergeWord _ self mergeFn: (skewWord bitAnd: halftoneWord)
								with: (self dstLongAt: destIndex).
				self dstLongAt: destIndex put: (destMask bitAnd: mergeWord).
			] ifFalse:[ "General version using dest masking"
				destWord _ self dstLongAt: destIndex.
				mergeWord _ self mergeFn: (skewWord bitAnd: halftoneWord)
								with: (destWord bitAnd: destMask).
				destWord _ (destMask bitAnd: mergeWord) bitOr:
								(destWord bitAnd: destMask bitInvert32).
				self dstLongAt: destIndex put: destWord.
			].
			destIndex _ destIndex + 4.
			words = 2 "e.g., is the next word the last word?"
				ifTrue:["set mask for last word in this row"
						destMask _ mask2.
						nPix _ endBits]
				ifFalse:["use fullword mask for inner loop"
						destMask _ AllOnes.
						nPix _ destPPW].
			(words _ words - 1) = 0] whileFalse.
		"--- end of inner loop ---"
		pAx _ pAx + deltaP12x.
		pAy _ pAy + deltaP12y.
		pBx _ pBx + deltaP43x.
		pBy _ pBy + deltaP43y.
		destIndex _ destIndex + destDelta]
]

{ #category : #'pixel mapping' }
BitBltSimulation >> warpLoopSetup [
	"Setup values for faster pixel fetching."
	| words |
	self inline: true.

	"warpSrcShift = log2(sourceDepth)"
	warpSrcShift _ 0.
	words _ sourceDepth. "recycle temp"
	[words = 1] whileFalse:[
		warpSrcShift _ warpSrcShift + 1.
		words _ words >> 1].

	"warpSrcMask = mask for extracting one pixel from source word"
	warpSrcMask _ maskTable at: sourceDepth.

	"warpAlignShift: Shift for aligning x position to word boundary"
	warpAlignShift _ 5 - warpSrcShift.

	"warpAlignMask: Mask for extracting the pixel position from an x position"
	warpAlignMask _ 1 << warpAlignShift - 1.

	"Setup the lookup table for source bit shifts"
	"warpBitShiftTable: given an sub-word x value what's the bit shift?"
	0 to: warpAlignMask do:[:i|
		sourceMSB
			ifTrue:[warpBitShiftTable at: i put: 32 - ( i + 1 << warpSrcShift )]
			ifFalse:[warpBitShiftTable at: i put: (i << warpSrcShift)]].

]

{ #category : #'pixel mapping' }
BitBltSimulation >> warpPickSmoothPixels: nPixels
	xDeltah: xDeltah yDeltah: yDeltah
	xDeltav: xDeltav yDeltav: yDeltav
	sourceMap: sourceMap
	smoothing: n
	dstShiftInc: dstShiftInc [
	"Pick n (sub-) pixels from the source form, mapped by sourceMap,
	average the RGB values, map by colorMap and return the new word.
	This version is only called from WarpBlt with smoothingCount > 1"
	| rgb x y a r g b xx yy xdh ydh xdv ydv dstMask destWord i j k nPix |
	self inline: false. "nope - too much stuff in here"
	dstMask _ maskTable at: destDepth.
	destWord _ 0.
	n = 2 "Try avoiding divides for most common n (divide by 2 is generated as shift)"
		ifTrue:[xdh _ xDeltah // 2. ydh _ yDeltah // 2. 
				xdv _ xDeltav // 2. ydv _ yDeltav // 2]
		ifFalse:[xdh _ xDeltah // n. ydh _ yDeltah // n. 
				xdv _ xDeltav // n. ydv _ yDeltav // n].
	i _ nPixels.
	[
		x _ sx. y _ sy.
		a _ r _ g _ b _ 0.
		"Pick and average n*n subpixels"
		nPix _ 0.  "actual number of pixels (not clipped and not transparent)"
		j _ n.
		[
			xx _ x. yy _ y.
			k _ n.
			[
				"get a single subpixel"
				rgb _ self pickWarpPixelAtX: xx y: yy.
				(combinationRule=25 "PAINT" and: [rgb = 0]) ifFalse:[
					"If not clipped and not transparent, then tally rgb values"
					nPix _ nPix + 1.
					sourceDepth < 16 ifTrue:[
						"Get RGBA values from sourcemap table"
						rgb _ self long32At: sourceMap + (rgb << 2).
					] ifFalse:["Already in RGB format"
						sourceDepth = 16 
								ifTrue:[rgb _ self rgbMap16To32: rgb]
								ifFalse:[rgb _ self rgbMap32To32: rgb]].
					b _ b + (rgb bitAnd: 255).
					g _ g + (rgb >> 8 bitAnd: 255).
					r _ r + (rgb >> 16 bitAnd: 255).
					a _ a + (rgb >> 24)].
				xx _ xx + xdh.
				yy _ yy + ydh.
			(k _ k - 1) = 0] whileFalse.
			x _ x + xdv.
			y _ y + ydv.
		(j _ j - 1) = 0] whileFalse.

		(nPix = 0 or: [combinationRule=25 "PAINT" and: [nPix < (n * n // 2)]]) ifTrue:[
			rgb _ 0  "All pixels were 0, or most were transparent"
		] ifFalse:[
			"normalize rgba sums"
			nPix = 4 "Try to avoid divides for most common n"
				ifTrue:[r _ r >> 2.	g _ g >> 2.	b _ b >> 2.	a _ a >> 2]
				ifFalse:[	r _ r // nPix.	g _ g // nPix.	b _ b // nPix.	a _ a // nPix].
			rgb _ (a << 24) + (r << 16) + (g << 8) + b.

			"map the pixel"
			rgb = 0 ifTrue: [
				"only generate zero if pixel is really transparent"
				(r + g + b + a) > 0 ifTrue: [rgb _ 1]].
			rgb _ self mapPixel: rgb flags: cmFlags.
		].
		"Mix it in"
		destWord _ destWord bitOr: (rgb bitAnd: dstMask) << dstBitShift.
		dstBitShift _ dstBitShift + dstShiftInc.
		sx _ sx + xDeltah.
		sy _ sy + yDeltah.
	(i _ i - 1) = 0] whileFalse.

	^destWord

]

{ #category : #'pixel mapping' }
BitBltSimulation >> warpPickSourcePixels: nPixels
	xDeltah: xDeltah yDeltah: yDeltah
	xDeltav: xDeltav yDeltav: yDeltav
	dstShiftInc: dstShiftInc
	flags: mapperFlags [
	"Pick n pixels from the source form,
	map by colorMap and return aligned by dstBitShift.
	This version is only called from WarpBlt with smoothingCount = 1"
	| dstMask destWord nPix sourcePix destPix |
	self inline: true. "Yepp - this should go into warpLoop"
	dstMask _ maskTable at: destDepth.
	destWord _ 0.
	nPix _ nPixels.
	(mapperFlags = (ColorMapPresent bitOr: ColorMapIndexedPart)) ifTrue:[
		"a little optimization for (pretty crucial) blits using indexed lookups only"
		[	"grab, colormap and mix in pixel"
			sourcePix _ self pickWarpPixelAtX: sx y: sy.
			destPix _ cmLookupTable at: (sourcePix bitAnd: cmMask).
			destWord _ destWord bitOr: (destPix bitAnd: dstMask) << dstBitShift.
			dstBitShift _ dstBitShift + dstShiftInc.
			sx _ sx + xDeltah.
			sy _ sy + yDeltah.
		(nPix _ nPix - 1) = 0] whileFalse.
	] ifFalse:[
		[	"grab, colormap and mix in pixel"
			sourcePix _ self pickWarpPixelAtX: sx y: sy.
			destPix _ self mapPixel: sourcePix flags: mapperFlags.
			destWord _ destWord bitOr: (destPix bitAnd: dstMask) << dstBitShift.
			dstBitShift _ dstBitShift + dstShiftInc.
			sx _ sx + xDeltah.
			sy _ sy + yDeltah.
		(nPix _ nPix - 1) = 0] whileFalse.
	].
	^destWord

]
