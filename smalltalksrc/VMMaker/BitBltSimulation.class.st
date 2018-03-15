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
	35 alphaBlendScaled: sourceWord with:	""unused here - only used by FXBlt""
	36 alphaBlendScaled: sourceWord with:	""unused here - only used by FXBlt""
	37 rgbMul: sourceWord with: destinationWord
	38 pixSwap: sourceWord with: destinationWord
	39 pixClear: sourceWord with: destinationWord
	40 fixAlpha: sourceWord with: destinationWord
	41 rgbComponentAlpha: sourceWord with: destinationWord

This implementation has also been fitted with an experimental ""warp drive"" that allows abritrary scaling and rotation (and even limited affine deformations) with all BitBlt storage modes supported.

To add a new rule to BitBlt...
	1.  add the new rule method or methods in the category 'combination rules' of BBSim
	2.  describe it in the class comment  of BBSim and in the class comment for BitBlt
	3.  add refs to initializeRuleTable in proper positions
	4.  add refs to initBBOpTable, following the pattern

"
Class {
	#name : #BitBltSimulation,
	#superclass : #SmartSyntaxInterpreterPlugin,
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
		'dither8Lookup',
		'componentAlphaModeColor',
		'componentAlphaModeAlpha',
		'ungammaLookupTable',
		'gammaLookupTable',
		'numGCsOnInvocation',
		'bitBltIsReceiver'
	],
	#classVars : [
		'AllOnes',
		'AlphaIndex',
		'BBClipHeightIndex',
		'BBClipWidthIndex',
		'BBClipXIndex',
		'BBClipYIndex',
		'BBColorMapIndex',
		'BBDestFormIndex',
		'BBDestXIndex',
		'BBDestYIndex',
		'BBHalftoneFormIndex',
		'BBHeightIndex',
		'BBLastIndex',
		'BBRuleIndex',
		'BBSourceFormIndex',
		'BBSourceXIndex',
		'BBSourceYIndex',
		'BBWarpBase',
		'BBWidthIndex',
		'BBXTableIndex',
		'BEBitBltIndex',
		'BinaryPoint',
		'BlueIndex',
		'ColorMapFixedPart',
		'ColorMapIndexedPart',
		'ColorMapNewStyle',
		'ColorMapPresent',
		'CrossedX',
		'EndOfRun',
		'FixedPt1',
		'FormBitsIndex',
		'FormDepthIndex',
		'FormHeightIndex',
		'FormWidthIndex',
		'GreenIndex',
		'OpTable',
		'OpTableSize',
		'RedIndex'
	],
	#category : 'VMMaker-Interpreter'
}

{ #category : #'system simulation' }
BitBltSimulation class >> copyBitsFrom: aBitBlt [
	"Simulate the copyBits primitive"
	| proxy bb |
	proxy := InterpreterProxy new.
	proxy loadStackFrom: thisContext sender home.
	bb := self simulatorClass new.
	bb initialiseModule.
	bb setInterpreter: proxy.
	proxy success: (bb loadBitBltFrom: aBitBlt).
	bb primitiveCopyBits.
	^ proxy stackValue: 0
]

{ #category : #translation }
BitBltSimulation class >> declareCVarsIn: aCCodeGenerator [

	"add option of  fast path BitBLT code header"
	aCCodeGenerator
		addHeaderFile:'"sqAssert.h"';
		addHeaderFile:'#ifdef ENABLE_FAST_BLT
#include "BitBltDispatch.h"
#else
// to handle the unavoidable decl in the spec of copyBitsFallback();
#define operation_t void
#endif'.
		
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
		type:'int *'.
	aCCodeGenerator var:'cmMaskTable' 
		type:'unsigned int *'.
	aCCodeGenerator var:'cmLookupTable' 
		type:'unsigned int *'.

	aCCodeGenerator var: 'dither8Lookup'
		declareC:' unsigned char dither8Lookup[4096]'.

	aCCodeGenerator var:'ungammaLookupTable' 
		type: 'unsigned char *'.
	aCCodeGenerator var:'gammaLookupTable' 
		type: 'unsigned char *'.

	aCCodeGenerator
		var: 'querySurfaceFn' declareC: 'int (*querySurfaceFn)(sqIntptr_t, int*, int*, int*, int*)';
		var: 'lockSurfaceFn' declareC: 'sqIntptr_t (*lockSurfaceFn)(sqIntptr_t, int*, int, int, int, int)';
		var: 'unlockSurfaceFn' declareC: 'int (*unlockSurfaceFn)(sqIntptr_t, int, int, int, int)'.
	
	#(sourcePitch sourceWidth sourceHeight sourceDepth sourceMSB sx sy
		destPitch destWidth destHeight destDepth destMSB dx dy bbW bbH)
		do: [:ivar | aCCodeGenerator var: ivar type: #int]
]

{ #category : #initialization }
BitBltSimulation class >> initialize [
	"BitBltSimulation initialize"

	self initializeRuleTable.

	"Mask constants"
	AllOnes := 16rFFFFFFFF.
	BinaryPoint := 14.
	FixedPt1 := 1 << BinaryPoint.  "Value of 1.0 in Warp's fixed-point representation"
 
	"Indices into stopConditions for scanning"
	EndOfRun := 257.
	CrossedX := 258.
 
	"Form fields"
	FormBitsIndex := 0.
	FormWidthIndex := 1.
	FormHeightIndex := 2.
	FormDepthIndex := 3.
 
	"BitBlt fields"
	BBDestFormIndex := 0.
	BBSourceFormIndex := 1.
	BBHalftoneFormIndex := 2.
	BBRuleIndex := 3.
	BBDestXIndex := 4.
	BBDestYIndex := 5.
	BBWidthIndex := 6.
	BBHeightIndex := 7.
	BBSourceXIndex := 8.
	BBSourceYIndex := 9.
	BBClipXIndex := 10.
	BBClipYIndex := 11.
	BBClipWidthIndex := 12.
	BBClipHeightIndex := 13.
	BBColorMapIndex := 14.
	BBWarpBase := 15.
	BBLastIndex := 15.
	BBXTableIndex := 16.

	"BalloonEngineFields"
	BEBitBltIndex := (Smalltalk classNamed: #BalloonEngine)
						ifNil: [2]
						ifNotNil: [:be| (be allInstVarNames indexOf: 'bitBlt') - 1].

	"RGBA indexes"
	RedIndex := 0.
	GreenIndex := 1.
	BlueIndex := 2.
	AlphaIndex := 3.

	"Color map flags"
	ColorMapPresent := 1.		"do we have one?"
	ColorMapFixedPart := 2.		"does it have a fixed part?"
	ColorMapIndexedPart := 4.	"does it have an indexed part?"
	ColorMapNewStyle := 8.		"new style color map"
]

{ #category : #initialization }
BitBltSimulation class >> initializeRuleTable [
	"BitBltSimulation initializeRuleTable"
	"**WARNING** You MUST change initBBOpTable if you change this"
	OpTable := #(
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
		"41" rgbComponentAlpha:with:
	).
	OpTableSize := OpTable size + 1.  "0-origin indexing"

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
BitBltSimulation class >> requiredMethodNames: options [
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
			f := (Form extent: i @ 5) fillBlack.
			0 to: 20 do: [:x | f displayOn: Display at: x * 13 @ (i * 10)]]
]

{ #category : #testing }
BitBltSimulation class >> timingTest: extent [ 
	"BitBltSimulation timingTest: 640@480"
	| f f2 map |
	f := Form extent: extent depth: 8.
	f2 := Form extent: extent depth: 8.
	map := Bitmap new: 1 << f2 depth.
	^ Array
		with: (Time millisecondsToRun: [100 timesRepeat: [f fillWithColor: Color white]])
		with: (Time millisecondsToRun: [100 timesRepeat: [f copy: f boundingBox from: 0 @ 0 in: f2 rule: Form over]])
		with: (Time millisecondsToRun: [100 timesRepeat: [f copyBits: f boundingBox from: f2 at: 0 @ 0 colorMap: map]])
]

{ #category : #'system simulation' }
BitBltSimulation class >> warpBitsFrom: aBitBlt [
	"Simulate the warpBits primitive"
	| proxy bb |
	proxy := InterpreterProxy new.
	proxy loadStackFrom: thisContext sender home.
	bb := self simulatorClass new.
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
	<inline: false>
	destDepth < 16 ifTrue:
		["Just xor and count differing bits if not RGB"
		diff := sourceWord bitXor: destinationWord.
		pixMask := maskTable at: destDepth.
		[diff = 0] whileFalse:
			[(diff bitAnd: pixMask) ~= 0 ifTrue: [bitCount := bitCount + 1].
			diff := diff >> destDepth].
		^ destinationWord "for no effect"].
 	destDepth = 16
		ifTrue:
		[diff := (self partitionedSub: sourceWord from: destinationWord
						nBits: 5 nPartitions: 3).
		bitCount := bitCount + (diff bitAnd: 16r1F)
							+ (diff>>5 bitAnd: 16r1F)
							+ (diff>>10 bitAnd: 16r1F).
		diff := (self partitionedSub: sourceWord>>16 from: destinationWord>>16
						nBits: 5 nPartitions: 3).
		bitCount := bitCount + (diff bitAnd: 16r1F)
							+ (diff>>5 bitAnd: 16r1F)
							+ (diff>>10 bitAnd: 16r1F)]
		ifFalse:
		[diff := (self partitionedSub: sourceWord from: destinationWord
						nBits: 8 nPartitions: 3).
		bitCount := bitCount + (diff bitAnd: 16rFF)
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
		pixMask := (maskTable at: destDepth) bitAnd: cmMask.
		shiftWord := destinationWord.
		1 to: destPPW do:
			[:i |
			mapIndex := shiftWord bitAnd: pixMask.
			self tallyMapAt: mapIndex put: (self tallyMapAt: mapIndex) + 1.
			shiftWord := shiftWord >> destDepth].
		^ destinationWord].
	destDepth = 16 ifTrue:
		["Two pixels  Tally the right half..."
		mapIndex := self rgbMap: (destinationWord bitAnd: 16rFFFF) from: 5 to: cmBitsPerColor.
		self tallyMapAt: mapIndex put: (self tallyMapAt: mapIndex) + 1.
		"... and then left half"
		mapIndex := self rgbMap: destinationWord>>16 from: 5 to: cmBitsPerColor.
		self tallyMapAt: mapIndex put: (self tallyMapAt: mapIndex) + 1]
	ifFalse:
		["Just one pixel."
		mapIndex := self rgbMap: destinationWord from: 8 to: cmBitsPerColor.
		self tallyMapAt: mapIndex put: (self tallyMapAt: mapIndex) + 1].
	^ destinationWord  "For no effect on dest"
]

{ #category : #'combination rules' }
BitBltSimulation >> addWord: sourceWord with: destinationWord [
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
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
	| alpha unAlpha result blendRB blendAG |
	<inline: false>
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	<var: #blendRB type: 'unsigned int'>
	<var: #blendAG type: 'unsigned int'>
	<var: #result type: 'unsigned int'>
	<var: #alpha type: 'unsigned int'>
	<var: #unAlpha type: 'unsigned int'>
	alpha := sourceWord >> 24.  "High 8 bits of source pixel"
	alpha = 0 ifTrue: [ ^ destinationWord ].
	alpha = 255 ifTrue: [ ^ sourceWord ].
	unAlpha := 255 - alpha.

	blendRB := ((sourceWord bitAnd: 16rFF00FF) * alpha) +
				((destinationWord bitAnd: 16rFF00FF) * unAlpha)
				+ 16rFF00FF.	"blend red and blue"

	blendAG := (((sourceWord>> 8 bitOr: 16rFF0000) bitAnd: 16rFF00FF) * alpha) +
				((destinationWord>>8 bitAnd: 16rFF00FF) * unAlpha)
				+ 16rFF00FF.	"blend alpha and green"

	blendRB := blendRB + (blendRB - 16r10001 >> 8 bitAnd: 16rFF00FF) >> 8 bitAnd: 16rFF00FF.	"divide by 255"
	blendAG := blendAG + (blendAG - 16r10001 >> 8 bitAnd: 16rFF00FF) >> 8 bitAnd: 16rFF00FF.
	result := blendRB bitOr: blendAG<<8.
	^ result

]

{ #category : #'combination rules' }
BitBltSimulation >> alphaBlendConst: sourceWord with: destinationWord [
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>

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

	| pixMask destShifted sourceShifted destPixVal rgbMask sourcePixVal unAlpha result pixBlend shift blend maskShifted bitsPerColor blendAG blendRB |
	<inline: false>
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	<var: #blendRB type: 'unsigned int'>
	<var: #blendAG type: 'unsigned int'>
	<var: #result type: 'unsigned int'>
	<var: #sourceAlpha type: 'unsigned int'>
	<var: #unAlpha type: 'unsigned int'>
	<var: #sourceShifted type: 'unsigned int'>
	<var: #destShifted type: 'unsigned int'>
	<var: #maskShifted type: 'unsigned int'>
	<var: #pixMask type: 'unsigned int'>
	<var: #rgbMask type: 'unsigned int'>
	<var: #pixBlend type: 'unsigned int'>
	<var: #blend type: 'unsigned int'>
	destDepth < 16 ifTrue: [^ destinationWord "no-op"].
	unAlpha := 255 - sourceAlpha.
	result := destinationWord.
	destPPW = 1 ifTrue:["32bpp blends include alpha"
		paintMode & (sourceWord = 0)  "painting a transparent pixel" ifFalse:[

				blendRB := ((sourceWord bitAnd: 16rFF00FF) * sourceAlpha) +
						((destinationWord bitAnd: 16rFF00FF) * unAlpha) + 16rFF00FF.	"blendRB red and blue"

				blendAG := ((sourceWord>> 8 bitAnd: 16rFF00FF) * sourceAlpha) +
						((destinationWord>>8 bitAnd: 16rFF00FF) * unAlpha) + 16rFF00FF.	"blendRB alpha and green"

				blendRB := blendRB + (blendRB - 16r10001 >> 8 bitAnd: 16rFF00FF) >> 8 bitAnd: 16rFF00FF.	"divide by 255"
				blendAG := blendAG + (blendAG - 16r10001 >> 8 bitAnd: 16rFF00FF) >> 8 bitAnd: 16rFF00FF.
				result := blendRB bitOr: blendAG<<8.
		].
	] ifFalse:[
		pixMask := maskTable at: destDepth.
		bitsPerColor := 5.
		rgbMask := 16r1F.
		maskShifted := destMask.
		destShifted := destinationWord.
		sourceShifted := sourceWord.
		1 to: destPPW do:[:j |
			sourcePixVal := sourceShifted bitAnd: pixMask.
			((maskShifted bitAnd: pixMask) = 0  "no effect if outside of dest rectangle"
				or: [paintMode & (sourcePixVal = 0)  "or painting a transparent pixel"])
			ifFalse:
				[destPixVal := destShifted bitAnd: pixMask.
				pixBlend := 0.
				1 to: 3 do:
					[:i | shift := (i-1)*bitsPerColor.
					blend := (((sourcePixVal>>shift bitAnd: rgbMask) * sourceAlpha)
								+ ((destPixVal>>shift bitAnd: rgbMask) * unAlpha))
						 	+ 254 // 255 bitAnd: rgbMask.
					pixBlend := pixBlend bitOr: blend<<shift].
				result := (result bitAnd: (pixMask << (j-1*16)) bitInvert32)
								bitOr: pixBlend << (j-1*16)].
			maskShifted := maskShifted >> destDepth.
			sourceShifted := sourceShifted >> destDepth.
			destShifted := destShifted >> destDepth].
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
	| unAlpha rb ag |
	<inline: false>	"Do NOT inline this into optimized loops"
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	<var: #rb type: 'unsigned int'>
	<var: #ag type: 'unsigned int'>
	<var: #unAlpha type: 'unsigned int'>
	unAlpha := 255 - (sourceWord >> 24).  "High 8 bits of source pixel is source opacity (ARGB format)"
	rb := ((destinationWord bitAnd: 16rFF00FF) * unAlpha >> 8 bitAnd: 16rFF00FF) + (sourceWord bitAnd: 16rFF00FF). "blend red and blue components"
	ag := ((destinationWord>>8 bitAnd: 16rFF00FF) * unAlpha >> 8 bitAnd: 16rFF00FF) + (sourceWord>>8 bitAnd: 16rFF00FF). "blend alpha and green components"
	rb := (rb bitAnd: 16rFF00FF) bitOr: (rb bitAnd: 16r1000100) * 16rFF >> 8. "saturate red and blue components if there is a carry"
	ag := (ag bitAnd: 16rFF00FF) << 8 bitOr: (ag bitAnd: 16r1000100) * 16rFF. "saturate alpha and green components if there is a carry"
	^ag bitOr: rb "recompose"
]

{ #category : #'combination rules' }
BitBltSimulation >> alphaPaintConst: sourceWord with: destinationWord [
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>

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
	<inline: false> "This particular method should be optimized in itself"
	<var: #sourceWord type: #'unsigned int'>
	<var: #destWord type: #'unsigned int'>
	<var: #dstMask type: #'unsigned int'>
	deltaY := bbH + 1. "So we can pre-decrement"
	srcY := sy.
	dstY := dy.
	srcShift := (dx bitAnd: 1) * 16.
	destMSB ifTrue:[srcShift := 16 - srcShift].
	mask1 := 16rFFFF << (16 - srcShift).
	"This is the outer loop"
	[(deltaY := deltaY - 1) ~= 0] whileTrue:[
		srcIndex := sourceBits + (srcY * sourcePitch) + (sx * 4).
		dstIndex := destBits + (dstY * destPitch) + (dx // 2 * 4).
		ditherBase := (dstY bitAnd: 3) * 4.
		ditherIndex := (sx bitAnd: 3) - 1. "For pre-increment"
		deltaX := bbW + 1. "So we can pre-decrement"
		dstMask := mask1.
		dstMask = 16rFFFF ifTrue:[srcShift := 16] ifFalse:[srcShift := 0].

		"This is the inner loop"
		[(deltaX := deltaX - 1) ~= 0] whileTrue:[
			ditherThreshold := ditherMatrix4x4 at: ditherBase + (ditherIndex := ditherIndex + 1 bitAnd: 3).
			sourceWord := self srcLongAt: srcIndex.
			srcAlpha := sourceWord >> 24.
			srcAlpha = 255 ifTrue:[
				"Dither from 32 to 16 bit"
				sourceWord := self dither32To16: sourceWord threshold: ditherThreshold.
				sourceWord = 0 
					ifTrue:[sourceWord := 1 << srcShift]
					ifFalse: [sourceWord := sourceWord << srcShift].
				"Store masked value"
				self dstLongAt: dstIndex put: sourceWord mask: dstMask.
			] ifFalse:[ "srcAlpha ~= 255"
				srcAlpha = 0 ifFalse:[ "0 < srcAlpha < 255"
					"If we have to mix colors then just copy a single word"
					destWord := self dstLongAt: dstIndex.
					destWord := destWord bitAnd: dstMask bitInvert32.
					destWord := destWord >> srcShift.
					"Expand from 16 to 32 bit by adding zero bits"
					destWord := (((destWord bitAnd: 16r7C00) bitShift: 9) bitOr:
									((destWord bitAnd: 16r3E0) bitShift: 6)) bitOr:
								(((destWord bitAnd: 16r1F) bitShift: 3) bitOr:
									16rFF000000).
					"Mix colors"
					sourceWord := self alphaBlendScaled: sourceWord with: destWord.
					"And dither"
					sourceWord := self dither32To16: sourceWord threshold: ditherThreshold.
					sourceWord = 0 
						ifTrue:[sourceWord := 1 << srcShift]
						ifFalse:[sourceWord := sourceWord << srcShift].
					"Store back"
					self dstLongAt: dstIndex put: sourceWord mask: dstMask.
				].
			].
			srcIndex := srcIndex + 4.
			destMSB
				ifTrue:[srcShift = 0 ifTrue:[dstIndex := dstIndex + 4]]
				ifFalse:[srcShift = 0 ifFalse:[dstIndex := dstIndex + 4]].
			srcShift := srcShift bitXor: 16. "Toggle between 0 and 16"
			dstMask := dstMask bitInvert32. "Mask other half word"
		].
		srcY := srcY + 1.
		dstY := dstY + 1.
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
	<inline: false> "This particular method should be optimized in itself"
	<var: #sourceWord type: #'unsigned int'>
	<var: #destWord type: #'unsigned int'>

	"Give the compile a couple of hints"

	"The following should be declared as pointers so the compiler will
	notice that they're used for accessing memory locations 
	(good to know on an Intel architecture) but then the increments
	would be different between ST code and C code so must hope the
	compiler notices what happens (MS Visual C does)"

	deltaY := bbH + 1. "So we can pre-decrement"
	srcY := sy.
	dstY := dy.

	"This is the outer loop"
	[(deltaY := deltaY - 1) ~= 0] whileTrue:[
		srcIndex := sourceBits + (srcY * sourcePitch) + (sx * 4).
		dstIndex := destBits + (dstY * destPitch) + (dx * 4).
		deltaX := bbW + 1. "So we can pre-decrement"

		"This is the inner loop"
		[(deltaX := deltaX - 1) ~= 0] whileTrue:[
			sourceWord := self srcLongAt: srcIndex.
			srcAlpha := sourceWord >> 24.
			srcAlpha = 255 ifTrue:[
				self dstLongAt: dstIndex put: sourceWord.
				srcIndex := srcIndex + 4.
				dstIndex := dstIndex + 4.
				"Now copy as many words as possible with alpha = 255"
				[(deltaX := deltaX - 1) ~= 0 and:[
					(sourceWord := self srcLongAt: srcIndex) >> 24 = 255]]
						whileTrue:[
							self dstLongAt: dstIndex put: sourceWord.
							srcIndex := srcIndex + 4.
							dstIndex := dstIndex + 4.
						].
				"Adjust deltaX"
				deltaX := deltaX + 1.
			] ifFalse:[ "srcAlpha ~= 255"
				srcAlpha = 0 ifTrue:[
					srcIndex := srcIndex + 4.
					dstIndex := dstIndex + 4.
					"Now skip as many words as possible,"
					[(deltaX := deltaX - 1) ~= 0 and:[
						(sourceWord := self srcLongAt: srcIndex) >> 24 = 0]]
						whileTrue:[
							srcIndex := srcIndex + 4.
							dstIndex := dstIndex + 4.
						].
					"Adjust deltaX"
					deltaX := deltaX + 1.
				] ifFalse:[ "0 < srcAlpha < 255"
					"If we have to mix colors then just copy a single word"
					destWord := self dstLongAt: dstIndex.
					destWord := self alphaBlendScaled: sourceWord with: destWord.
					self dstLongAt: dstIndex put: destWord.
					srcIndex := srcIndex + 4.
					dstIndex := dstIndex + 4.
				].
			].
		].
		srcY := srcY + 1.
		dstY := dstY + 1.
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
	<inline: false>
	<var: #mappingTable type:'unsigned int *'>
	<var: #sourceWord type: #'unsigned int'>
	<var: #destWord type: #'unsigned int'>
	<var: #dstMask type: #'unsigned int'>
	mappingTable := self default8To32Table.
	mapperFlags := cmFlags bitAnd: ColorMapNewStyle bitInvert32.
	deltaY := bbH + 1. "So we can pre-decrement"
	srcY := sy.
	dstY := dy.
	mask1 := ((dx bitAnd: 3) * 8).
	destMSB ifTrue:[mask1 := 24 - mask1].
	mask2 := AllOnes bitXor:(16rFF << mask1).
	(dx bitAnd: 1) = 0 
		ifTrue:[adjust := 0]
		ifFalse:[adjust := 16r1F1F1F1F].
	(dy bitAnd: 1) = 0
		ifTrue:[adjust := adjust bitXor: 16r1F1F1F1F].
	"This is the outer loop"
	[(deltaY := deltaY - 1) ~= 0] whileTrue:[
		adjust := adjust bitXor: 16r1F1F1F1F.
		srcIndex := sourceBits + (srcY * sourcePitch) + (sx * 4).
		dstIndex := destBits + (dstY * destPitch) + (dx // 4 * 4).
		deltaX := bbW + 1. "So we can pre-decrement"
		srcShift := mask1.
		dstMask := mask2.

		"This is the inner loop"
		[(deltaX := deltaX - 1) ~= 0] whileTrue:[
			sourceWord := ((self srcLongAt: srcIndex) bitAnd: (adjust bitInvert32)) + adjust.
			srcAlpha := sourceWord >> 24.
			srcAlpha > 31 ifTrue:["Everything below 31 is transparent"
				srcAlpha < 224 ifTrue:["Everything above 224 is opaque"
					destWord := self dstLongAt: dstIndex.
					destWord := destWord bitAnd: dstMask bitInvert32.
					destWord := destWord >> srcShift.
					destWord := mappingTable at: destWord.
					sourceWord := self alphaBlendScaled: sourceWord with: destWord.
				].
				sourceWord := self mapPixel: sourceWord flags: mapperFlags.
				sourceWord := sourceWord << srcShift.
				"Store back"
				self dstLongAt: dstIndex put: sourceWord mask: dstMask.
			].
			srcIndex := srcIndex + 4.
			destMSB ifTrue:[
				srcShift = 0 
					ifTrue:[dstIndex := dstIndex + 4.
							srcShift := 24.
							dstMask := 16r00FFFFFF]
					ifFalse:[srcShift := srcShift - 8.
							dstMask := (dstMask >> 8) bitOr: 16rFF000000].
			] ifFalse:[
				srcShift = 24
					ifTrue:[dstIndex := dstIndex + 4.
							srcShift := 0.
							dstMask := 16rFFFFFF00]
					ifFalse:[srcShift := srcShift + 8.
							dstMask := dstMask << 8 bitOr: 255].
			].
			adjust := adjust bitXor: 16r1F1F1F1F.
		].
		srcY := srcY + 1.
		dstY := dstY + 1.
	].
]

{ #category : #'combination rules' }
BitBltSimulation >> bitAnd: sourceWord with: destinationWord [
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	^sourceWord bitAnd: destinationWord
]

{ #category : #'combination rules' }
BitBltSimulation >> bitAndInvert: sourceWord with: destinationWord [
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	^sourceWord bitAnd: destinationWord bitInvert32
]

{ #category : #'combination rules' }
BitBltSimulation >> bitInvertAnd: sourceWord with: destinationWord [
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	^sourceWord bitInvert32 bitAnd: destinationWord
]

{ #category : #'combination rules' }
BitBltSimulation >> bitInvertAndInvert: sourceWord with: destinationWord [
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	^sourceWord bitInvert32 bitAnd: destinationWord bitInvert32
]

{ #category : #'combination rules' }
BitBltSimulation >> bitInvertDestination: sourceWord with: destinationWord [
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	^destinationWord bitInvert32
]

{ #category : #'combination rules' }
BitBltSimulation >> bitInvertOr: sourceWord with: destinationWord [
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	^sourceWord bitInvert32 bitOr: destinationWord
]

{ #category : #'combination rules' }
BitBltSimulation >> bitInvertOrInvert: sourceWord with: destinationWord [
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	^sourceWord bitInvert32 bitOr: destinationWord bitInvert32
]

{ #category : #'combination rules' }
BitBltSimulation >> bitInvertSource: sourceWord with: destinationWord [
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	^sourceWord bitInvert32
]

{ #category : #'combination rules' }
BitBltSimulation >> bitInvertXor: sourceWord with: destinationWord [
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	^sourceWord bitInvert32 bitXor: destinationWord
]

{ #category : #'combination rules' }
BitBltSimulation >> bitOr: sourceWord with: destinationWord [
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	^sourceWord bitOr: destinationWord
]

{ #category : #'combination rules' }
BitBltSimulation >> bitOrInvert: sourceWord with: destinationWord [
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	^sourceWord bitOr: destinationWord bitInvert32
]

{ #category : #'combination rules' }
BitBltSimulation >> bitXor: sourceWord with: destinationWord [
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	^sourceWord bitXor: destinationWord
]

{ #category : #setup }
BitBltSimulation >> checkSourceOverlap [
	"check for possible overlap of source and destination"
	"ar 10/19/1999: This method requires surfaces to be locked."
	| t |
	<inline: true>
	(sourceForm = destForm and: [dy >= sy]) ifTrue:
		[dy > sy ifTrue:
			["have to start at bottom"
			vDir := -1.
			sy := sy + bbH - 1.
			dy := dy + bbH - 1]
		ifFalse:
			[(dy = sy) & (dx > sx) ifTrue:
				["y's are equal, but x's are backward"
				hDir := -1.
				sx := sx + bbW - 1.
				"start at right"
				dx := dx + bbW - 1.
				"and fix up masks"
				nWords > 1 ifTrue: 
					[t := mask1.
					mask1 := mask2.
					mask2 := t]]].
		"Dest inits may be affected by this change"
		destIndex := destBits + (dy * destPitch) + ((dx // destPPW) *4).
		destDelta := (destPitch * vDir) - (4 * (nWords * hDir))]
]

{ #category : #'combination rules' }
BitBltSimulation >> clearWord: sourceWord with: destinationWord [
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	^ 0
]

{ #category : #setup }
BitBltSimulation >> clipRange [
	"clip and adjust source origin and extent appropriately"
	"first in x"
	destX >= clipX
		ifTrue: [sx := sourceX.
				dx := destX.
				bbW := width]
		ifFalse: [sx := sourceX + (clipX - destX).
				bbW := width - (clipX - destX).
				dx := clipX].
	(dx + bbW) > (clipX + clipWidth)
		ifTrue: [bbW := bbW - ((dx + bbW) - (clipX + clipWidth))].
	"then in y"
	destY >= clipY
		ifTrue: [sy := sourceY.
				dy := destY.
				bbH := height]
		ifFalse: [sy := sourceY + clipY - destY.
				bbH := height - (clipY - destY).
				dy := clipY].
	(dy + bbH) > (clipY + clipHeight)
		ifTrue: [bbH := bbH - ((dy + bbH) - (clipY + clipHeight))].
	noSource ifTrue: [^ nil].
	sx < 0
		ifTrue: [dx := dx - sx.
				bbW := bbW + sx.
				sx := 0].
	sx + bbW > sourceWidth
		ifTrue: [bbW := bbW - (sx + bbW - sourceWidth)].
	sy < 0
		ifTrue: [dy := dy - sy.
				bbH := bbH + sy.
				sy := 0].
	sy + bbH > sourceHeight
		ifTrue: [bbH := bbH - (sy + bbH - sourceHeight)]
]

{ #category : #setup }
BitBltSimulation >> copyBits [
	"This function is exported for the Balloon engine"
	<export: true>
	<inline: false>
	self clipRange.
	(bbW <= 0 or: [bbH <= 0]) ifTrue:
		["zero width or height; noop"
		affectedL := affectedR := affectedT := affectedB := 0.
		^ nil].
	"Lock the surfaces"
	self lockSurfaces ifFalse:[^interpreterProxy primitiveFail].

	self
		cppIf: #'ENABLE_FAST_BLT'
		ifTrue:["you really, really mustn't call this unless you have the rest of the code to link to"
			self copyBitsFastPathSpecialised]
		ifFalse:[self copyBitsLockedAndClipped].

	self unlockSurfaces.
]

{ #category : #setup }
BitBltSimulation >> copyBits: op Fallback: flags [
	"Recover from the fast path specialised code saying Help-I-cant-cope"
	|done |
	<static: false>
	<returnTypeC: 'void'>
	<inline: false>
	<var: #op type: 'operation_t *'>
	<var: #flags type:'unsigned int'>
	self cppIf: #'ENABLE_FAST_BLT'
		ifTrue:[
			"recover values from the operation struct used by the fast ARM code"
			self cCode:'
	combinationRule = op->combinationRule;
	noSource = op->noSource;
	sourceBits = (sqInt) op->src.bits;
	sourcePitch = op->src.pitch;
	sourceDepth = op->src.depth;
	sourceMSB = op->src.msb;
	sx = op->src.x;
	sy = op->src.y;
	destBits = (sqInt) op->dest.bits;
	destPitch = op->dest.pitch;
	destDepth = op->dest.depth;
	destMSB = op->dest.msb;
	dx = op->dest.x;
	dy = op->dest.y;
	bbW = op->width;
	bbH = op->height;
	cmFlags = op->cmFlags;
	cmShiftTable = (void *) op->cmShiftTable;
	cmMaskTable = (void *) op->cmMaskTable;
	cmMask = op->cmMask;
	cmLookupTable = (void *) op->cmLookupTable;
	noHalftone = op->noHalftone;
	halftoneHeight = op->halftoneHeight;
	halftoneBase = (sqInt) op->halftoneBase;
	if (combinationRule == 30 || combinationRule == 31) {
		sourceAlpha = op->opt.sourceAlpha;
	}
	if (combinationRule == 41) {
		componentAlphaModeColor = op->opt.componentAlpha.componentAlphaModeColor;
		componentAlphaModeAlpha = op->opt.componentAlpha.componentAlphaModeAlpha;
		gammaLookupTable = (void *) op->opt.componentAlpha.gammaLookupTable;
		ungammaLookupTable = (void *) op->opt.componentAlpha.ungammaLookupTable;
	}'.
	
				destPPW := 32 / destDepth.
				cmBitsPerColor := 0.
				cmMask = 16r1FF ifTrue: [cmBitsPerColor := 3].
				cmMask = 16rFFF ifTrue: [cmBitsPerColor := 4].
				cmMask = 16r7FFF ifTrue: [cmBitsPerColor := 5].
	
				"Try a shortcut for stuff that should be run as quickly as possible"
				done := self tryCopyingBitsQuickly.
				done ifTrue:[^nil].

				bitCount := 0.
				"Choose and perform the actual copy loop."
				self performCopyLoop]

	



]

{ #category : #setup }
BitBltSimulation >> copyBitsFastPathSpecialised [
	"Perform the actual copyBits operation using the fast path specialised code; fail some cases by falling back to normal code.
	Assume: Surfaces have been locked and clipping was performed."
	<inline: false>

	self
		cppIf: #'ENABLE_FAST_BLT'
		ifTrue:[
	"set the affected area to 0 first"
	affectedL := affectedR := affectedT := affectedB := 0.
	
	self copyBitsRule41Test.	
	(interpreterProxy failed not)
		ifFalse: [^ interpreterProxy primitiveFail].

 	"we skip the tryCopyingBitsQuickly and leave that to falback code"
	 
	(combinationRule = 30) | (combinationRule = 31) ifTrue:
		["Check and fetch source alpha parameter for alpha blend"
		interpreterProxy methodArgumentCount = 1
			ifTrue: [sourceAlpha := interpreterProxy stackIntegerValue: 0.
					(interpreterProxy failed not and: [(sourceAlpha >= 0) & (sourceAlpha <= 255)])
						ifFalse: [^ interpreterProxy primitiveFail]]
			ifFalse: [^ interpreterProxy primitiveFail]].

	"we don't worry about bitCount"
	"bitCount := 0."

	"We don't  do - Choose and perform the actual copy loop."
	"self performCopyLoop."

	"this is done inversely to plain copyBitsLockedAndClipped"
	(combinationRule ~= 22) & (combinationRule ~= 32) ifTrue:
		["zero width and height; return the count"
		affectedL := dx.
		affectedR := dx + bbW.
		affectedT := dy.
		affectedB := dy + bbH].
	
	"Now we fill the 'operation' structure and pass it to the sneaky ARM code"
	self cCode:'
	// fill the operation structure
	operation_t op;
	op.combinationRule = combinationRule;
	op.noSource = noSource;
	op.src.bits = (void *) sourceBits;
	op.src.pitch = sourcePitch;
	op.src.depth = sourceDepth;
	op.src.msb = sourceMSB;
	op.src.x = sx;
	op.src.y = sy;
	op.dest.bits = (void *) destBits;
	op.dest.pitch = destPitch;
	op.dest.depth = destDepth;
	op.dest.msb = destMSB;
	op.dest.x = dx;
	op.dest.y = dy;
	op.width = bbW;
	op.height = bbH;
	op.cmFlags = cmFlags;
	op.cmShiftTable = (void *) cmShiftTable;
	op.cmMaskTable = (void *) cmMaskTable;
	op.cmMask = cmMask;
	op.cmLookupTable = (void *) cmLookupTable;
	op.noHalftone = noHalftone;
	op.halftoneHeight = halftoneHeight;
	op.halftoneBase = (void *) halftoneBase;
	if (combinationRule == 30 || combinationRule == 31) {
		op.opt.sourceAlpha = sourceAlpha;
	}
	if (combinationRule == 41) {
		op.opt.componentAlpha.componentAlphaModeColor = componentAlphaModeColor;
		op.opt.componentAlpha.componentAlphaModeAlpha = componentAlphaModeAlpha;
		op.opt.componentAlpha.gammaLookupTable = (void *) gammaLookupTable;
		op.opt.componentAlpha.ungammaLookupTable = (void *) ungammaLookupTable;
	}
	// call the sneaky code
	copyBitsDispatch(&op)'
	]
]

{ #category : #setup }
BitBltSimulation >> copyBitsFrom: startX to: stopX at: yValue [
	"Support for the balloon engine."
	<export: true>
	destX := startX.
	destY := yValue.
	sourceX := startX.
	width := (stopX - startX).
	self copyBits.
	self showDisplayBits.
]

{ #category : #setup }
BitBltSimulation >> copyBitsLockedAndClipped [
	"Perform the actual copyBits operation.
	Assume: Surfaces have been locked and clipping was performed."
	| done |
	<inline: false>
	
	self copyBitsRule41Test.	
	(interpreterProxy failed not)
		ifFalse: [^ interpreterProxy primitiveFail].

 	"Try a shortcut for stuff that should be run as quickly as possible"
	done := self tryCopyingBitsQuickly.
	done ifTrue:[^nil].

	(combinationRule = 30) | (combinationRule = 31) ifTrue:
		["Check and fetch source alpha parameter for alpha blend"
		interpreterProxy methodArgumentCount = 1
			ifTrue: [sourceAlpha := interpreterProxy stackIntegerValue: 0.
					(interpreterProxy failed not and: [(sourceAlpha >= 0) & (sourceAlpha <= 255)])
						ifFalse: [^ interpreterProxy primitiveFail]]
			ifFalse: [^ interpreterProxy primitiveFail]].

	bitCount := 0.
	"Choose and perform the actual copy loop."
	self performCopyLoop.

	(combinationRule = 22) | (combinationRule = 32) ifTrue:
		["zero width and height; return the count"
		affectedL := affectedR := affectedT := affectedB := 0]. 
	hDir > 0
		ifTrue: [affectedL := dx.
				affectedR := dx + bbW]
		ifFalse: [affectedL := dx - bbW + 1.
				affectedR := dx + 1].
	vDir > 0
		ifTrue: [affectedT := dy.
				affectedB := dy + bbH]
		ifFalse: [affectedT := dy - bbH + 1.
				affectedB := dy + 1]
]

{ #category : #setup }
BitBltSimulation >> copyBitsRule41Test [
	"Test possible use of rule 41, rgbComponentAlpha:with: Nothing to return, just set up some variables"
	| gammaLookupTableOop ungammaLookupTableOop |
	<inline: false>
	
	combinationRule = 41
		ifTrue:["fetch the forecolor into componentAlphaModeColor."
			componentAlphaModeAlpha := 255.
			componentAlphaModeColor := 16777215.
			gammaLookupTable := nil.
			ungammaLookupTable := nil.
			interpreterProxy methodArgumentCount >= 2
				ifTrue:[
					componentAlphaModeAlpha := interpreterProxy stackIntegerValue: (interpreterProxy methodArgumentCount - 2).
					(interpreterProxy failed not)
						ifFalse: [^ interpreterProxy primitiveFail].
					componentAlphaModeColor := interpreterProxy stackIntegerValue: (interpreterProxy methodArgumentCount - 1).
					(interpreterProxy failed not)
						ifFalse: [^ interpreterProxy primitiveFail].
					interpreterProxy methodArgumentCount = 4
						ifTrue:[
							gammaLookupTableOop := interpreterProxy stackObjectValue: 1.
							(interpreterProxy isBytes: gammaLookupTableOop) 
								ifTrue:[gammaLookupTable := interpreterProxy firstIndexableField: gammaLookupTableOop.].
							ungammaLookupTableOop := interpreterProxy stackObjectValue: 0.
							(interpreterProxy isBytes: ungammaLookupTableOop) 
								ifTrue:[ungammaLookupTable := interpreterProxy firstIndexableField: ungammaLookupTableOop]]]
				ifFalse:[
					interpreterProxy methodArgumentCount = 1
						ifTrue: [
							componentAlphaModeColor := interpreterProxy stackIntegerValue: 0.
							(interpreterProxy failed not)
								ifFalse: [^ interpreterProxy primitiveFail]]
						ifFalse:[^ interpreterProxy primitiveFail]]].	



]

{ #category : #'inner loop' }
BitBltSimulation >> copyLoop [
	| prevWord thisWord skewWord halftoneWord mergeWord hInc y unskew skewMask notSkewMask mergeFnwith destWord |
	"This version of the inner loop assumes noSource = false."
	<inline: false>
	<var: #prevWord type: #'unsigned int'>
	<var: #thisWord type: #'unsigned int'>
	<var: #skewWord type: #'unsigned int'>
	<var: #halftoneWord type: #'unsigned int'>
	<var: #mergeWord type: #'unsigned int'>
	<var: #destWord type: #'unsigned int'>
	<var: #skewMask type: #'unsigned int'>
	<var: #notSkewMask type: #'unsigned int'>
	<var: #unskew type: #int> "unskew is a bitShift and MUST remain signed, while skewMask is unsigned."
	<var: #mergeFnwith declareC: 'unsigned int (*mergeFnwith)(unsigned int, unsigned int)'>
	mergeFnwith := self cCoerce: (opTable at: combinationRule+1) to: 'unsigned int (*)(unsigned int, unsigned int)'.
	mergeFnwith.  "null ref for compiler"

	hInc := hDir * 4.  "Byte delta"
	"degenerate skew fixed for Sparc. 10/20/96 ikp"
	skew = -32
		ifTrue: [skew := unskew := skewMask := 0]
		ifFalse:
			[skew < 0
				ifTrue:
					[unskew := skew+32.
					skewMask := AllOnes << (0-skew)]
				ifFalse:
					[skew = 0
						ifTrue:
							[unskew := 0.
							skewMask := AllOnes]
						ifFalse:
							[unskew := skew-32.
							skewMask := AllOnes >> skew]]].
	notSkewMask := skewMask bitInvert32.
	noHalftone
		ifTrue: [halftoneWord := AllOnes.  halftoneHeight := 0]
		ifFalse: [halftoneWord := self halftoneAt: 0].

	y := dy.
	"Here is the vertical loop, in two versions, one for the combinationRule = 3 copy mode, one for the general case."
	combinationRule = 3
		ifTrue:
			[1 to: bbH do: "here is the vertical loop for combinationRule = 3 copy mode; no need to call merge"
				[ :i |
				halftoneHeight > 1 ifTrue:  "Otherwise, its always the same"
					[halftoneWord := self halftoneAt: y.
					y := y + vDir].
				preload
					ifTrue: "load the 64-bit shifter"
						[prevWord := self srcLongAt: sourceIndex.
						self incSrcIndex: hInc]
					ifFalse:
						[prevWord := 0].

				"Note: the horizontal loop has been expanded into three parts for speed:"

				"This first section requires masking of the destination store..."
				destMask := mask1.
				thisWord := self srcLongAt: sourceIndex.  "pick up next word"
				self incSrcIndex: hInc.
				skewWord := ((prevWord bitAnd: notSkewMask) bitShift: unskew)
								bitOr:  "32-bit rotate"
									((thisWord bitAnd: skewMask) bitShift: skew).
				prevWord := thisWord.
				destWord := self dstLongAt: destIndex.
				destWord := (destMask bitAnd: (skewWord bitAnd: halftoneWord))
								bitOr: (destWord bitAnd: destMask bitInvert32).
				self dstLongAt: destIndex put: destWord.
				self incDestIndex: hInc.

				"This central horizontal loop requires no store masking"
				destMask := AllOnes.
				(skew = 0 and: [halftoneWord = AllOnes])
					ifTrue: "Very special inner loop for STORE mode with no skew -- just move words"
						[hDir = -1
							ifTrue: "Woeful patch: revert to older code for hDir = -1"
								[2 to: nWords-1 do: 
									[ :word |
									thisWord := self srcLongAt: sourceIndex.
									self incSrcIndex: hInc.
									self dstLongAt: destIndex put: thisWord.
									self incDestIndex: hInc]]
							ifFalse:
								[2 to: nWords-1 do: 
									[ :word |  "Note loop starts with prevWord loaded (due to preload)"
									self dstLongAt: destIndex put: prevWord.
									self incDestIndex: hInc.
									prevWord := self srcLongAt: sourceIndex.
									self incSrcIndex: hInc]]]
						ifFalse:
							[2 to: nWords-1 do: 
								[ :word |
								thisWord := self srcLongAt: sourceIndex.
								self incSrcIndex: hInc.
								skewWord := ((prevWord bitAnd: notSkewMask) bitShift: unskew)
												bitOr:  "32-bit rotate"
											((thisWord bitAnd: skewMask) bitShift: skew).
								prevWord := thisWord.
								self dstLongAt: destIndex put: (skewWord bitAnd: halftoneWord).
								self incDestIndex: hInc]].

				"This last section, if used, requires masking of the destination store..."
				nWords > 1 ifTrue:
					[destMask := mask2.
					thisWord := self srcLongAt: sourceIndex.  "pick up next word"
					self incSrcIndex: hInc.
					skewWord := ((prevWord bitAnd: notSkewMask) bitShift: unskew)
									bitOr:  "32-bit rotate"
										((thisWord bitAnd: skewMask) bitShift: skew).
					destWord := self dstLongAt: destIndex.
					destWord := (destMask bitAnd: (skewWord bitAnd: halftoneWord))
									bitOr: (destWord bitAnd: destMask bitInvert32).
					self dstLongAt: destIndex put: destWord.
					self incDestIndex: hInc].

				self incSrcIndex: sourceDelta.
				self incDestIndex: destDelta]]
		ifFalse:
			[1 to: bbH do: "here is the vertical loop for the general case (combinationRule ~= 3)"
				[ :i |
				halftoneHeight > 1 ifTrue:  "Otherwise, its always the same"
					[halftoneWord := self halftoneAt: y.
					y := y + vDir].
				preload
					ifTrue: "load the 64-bit shifter"
						[prevWord := self srcLongAt: sourceIndex.
						self incSrcIndex: hInc]
					ifFalse:
						[prevWord := 0].

				"Note: the horizontal loop has been expanded into three parts for speed:"

				"This first section requires masking of the destination store..."
				destMask := mask1.
				thisWord := self srcLongAt: sourceIndex.  "pick up next word"
				self incSrcIndex: hInc.
				skewWord := ((prevWord bitAnd: notSkewMask) bitShift: unskew)
								bitOr:  "32-bit rotate"
							((thisWord bitAnd: skewMask) bitShift: skew).
				prevWord := thisWord.
				destWord := self dstLongAt: destIndex.
				mergeWord := self mergeFn: (skewWord bitAnd: halftoneWord) with: destWord.
				destWord := (destMask bitAnd: mergeWord)
								bitOr: (destWord bitAnd: destMask bitInvert32).
				self dstLongAt: destIndex put: destWord.
				self incDestIndex: hInc.

				"This central horizontal loop requires no store masking"
				destMask := AllOnes.
				2 to: nWords-1 do: "Normal inner loop does merge:"
					[ :word |
					thisWord := self srcLongAt: sourceIndex.  "pick up next word"
					self incSrcIndex: hInc.
					skewWord := ((prevWord bitAnd: notSkewMask) bitShift: unskew)
									bitOr:  "32-bit rotate"
								((thisWord bitAnd: skewMask) bitShift: skew).
					prevWord := thisWord.
					mergeWord := self mergeFn: (skewWord bitAnd: halftoneWord)
									with: (self dstLongAt: destIndex).
					self dstLongAt: destIndex put: mergeWord.
					self incDestIndex: hInc].

				"This last section, if used, requires masking of the destination store..."
				nWords > 1 ifTrue:
					[destMask := mask2.
					thisWord := self srcLongAt: sourceIndex.  "pick up next word"
					self incSrcIndex: hInc.
					skewWord := ((prevWord bitAnd: notSkewMask) bitShift: unskew)
									bitOr:  "32-bit rotate"
								((thisWord bitAnd: skewMask) bitShift: skew).
					destWord := self dstLongAt: destIndex.
					mergeWord := self mergeFn: (skewWord bitAnd: halftoneWord) with: destWord.
					destWord := (destMask bitAnd: mergeWord)
									bitOr: (destWord bitAnd: destMask bitInvert32).
					self dstLongAt: destIndex put: destWord.
					self incDestIndex: hInc].

				self incSrcIndex: sourceDelta.
				self incDestIndex: destDelta]]
]

{ #category : #'inner loop' }
BitBltSimulation >> copyLoopNoSource [
	"Faster copyLoop when source not used.  hDir and vDir are both
	positive, and perload and skew are unused"
	| halftoneWord mergeWord mergeFnwith destWord |
	<inline: false>
	<var: #mergeFnwith declareC: 'unsigned int (*mergeFnwith)(unsigned int, unsigned int)'>
	<var: #halftoneWord type: #'unsigned int'>
	<var: #mergeWord type: #'unsigned int'>
	<var: #destWord type: #'unsigned int'>
	mergeFnwith := self cCoerce: (opTable at: combinationRule+1) to: 'unsigned int (*)(unsigned int, unsigned int)'.
	mergeFnwith.  "null ref for compiler"

	1 to: bbH do: "here is the vertical loop"
		[ :i |
		noHalftone
			ifTrue: [halftoneWord := AllOnes]
			ifFalse: [halftoneWord := self halftoneAt: dy+i-1].

	"Note: the horizontal loop has been expanded into three parts for speed:"

			"This first section requires masking of the destination store..."
			destMask := mask1.
			destWord := self dstLongAt: destIndex.
			mergeWord := self mergeFn: halftoneWord
							with: destWord.
			destWord := (destMask bitAnd: mergeWord) bitOr: 
							(destWord bitAnd: destMask bitInvert32).
			self dstLongAt: destIndex put: destWord.
			self incDestIndex: 4.

		"This central horizontal loop requires no store masking"
			destMask := AllOnes.
			combinationRule = 3 ifTrue: ["Special inner loop for STORE"
				destWord := halftoneWord.
				2 to: nWords-1 do:[ :word |
					self dstLongAt: destIndex put: destWord.
					self incDestIndex: 4].
			] ifFalse:[ "Normal inner loop does merge"
				2 to: nWords-1 do:[ :word | "Normal inner loop does merge"
					destWord := self dstLongAt: destIndex.
					mergeWord := self mergeFn: halftoneWord with: destWord.
					self dstLongAt: destIndex put: mergeWord.
					self incDestIndex: 4].
			].

		"This last section, if used, requires masking of the destination store..."
		nWords > 1 ifTrue:
			[destMask := mask2.
			destWord := self dstLongAt: destIndex.
			mergeWord := self mergeFn: halftoneWord with: destWord.
			destWord := (destMask bitAnd: mergeWord) bitOr:
							(destWord bitAnd: destMask bitInvert32).
			self dstLongAt: destIndex put: destWord.
			self incDestIndex: 4].

	self incDestIndex: destDelta]
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
	<inline: false>
	<var: #mergeFnwith declareC: 'unsigned int (*mergeFnwith)(unsigned int, unsigned int)'>
	<var: #skewWord type: #'unsigned int'>
	<var: #halftoneWord type: #'unsigned int'>
	<var: #mergeWord type: #'unsigned int'>
	<var: #destWord type: #'unsigned int'>
	<var: #sourcePixMask type: #'unsigned int'>
	<var: #destPixMask type: #'unsigned int'>
	mergeFnwith := self cCoerce: (opTable at: combinationRule+1) to: 'unsigned int (*)(unsigned int, unsigned int)'.
	mergeFnwith.  "null ref for compiler"

	"Additional inits peculiar to unequal source and dest pix size..."
	sourcePPW := 32//sourceDepth.
	sourcePixMask := maskTable at: sourceDepth.
	destPixMask := maskTable at: destDepth.
	mapperFlags := cmFlags bitAnd: ColorMapNewStyle bitInvert32.
	sourceIndex := sourceBits +
					(sy * sourcePitch) + ((sx // sourcePPW) *4).
	scrStartBits := sourcePPW - (sx bitAnd: sourcePPW-1).
	bbW < scrStartBits
		ifTrue: [nSourceIncs := 0]
		ifFalse: [nSourceIncs := (bbW - scrStartBits)//sourcePPW + 1].
	sourceDelta := sourcePitch - (nSourceIncs * 4).

	"Note following two items were already calculated in destmask setup!"
	startBits := destPPW - (dx bitAnd: destPPW-1).
	endBits := ((dx + bbW - 1) bitAnd: destPPW-1) + 1.

	bbW < startBits ifTrue:[startBits := bbW].

	"Precomputed shifts for pickSourcePixels"
	srcShift := ((sx bitAnd: sourcePPW - 1) * sourceDepth).
	dstShift := ((dx bitAnd: destPPW - 1) * destDepth).
	srcShiftInc := sourceDepth.
	dstShiftInc := destDepth.
	dstShiftLeft := 0.
	sourceMSB ifTrue:[
		srcShift := 32 - sourceDepth - srcShift.
		srcShiftInc := 0 - srcShiftInc].
	destMSB ifTrue:[
		dstShift := 32 - destDepth - dstShift.
		dstShiftInc := 0 - dstShiftInc.
		dstShiftLeft := 32 - destDepth].

	1 to: bbH do: "here is the vertical loop"
		[ :i |
		"*** is it possible at all that noHalftone == false? ***"
		noHalftone
			ifTrue:[halftoneWord := AllOnes]
			ifFalse: [halftoneWord := self halftoneAt: dy+i-1].
		"setup first load"
		srcBitShift := srcShift.
		dstBitShift := dstShift.
		destMask := mask1.
		nPix := startBits.
		"Here is the horizontal loop..."
		words := nWords.
			["pick up the word"
			skewWord := self pickSourcePixels: nPix flags: mapperFlags 
								srcMask: sourcePixMask destMask: destPixMask
								srcShiftInc: srcShiftInc dstShiftInc: dstShiftInc.
			"align next word to leftmost pixel"
			dstBitShift := dstShiftLeft.

			destMask = AllOnes ifTrue:["avoid read-modify-write"
				mergeWord := self mergeFn: (skewWord bitAnd: halftoneWord)
								with: (self dstLongAt: destIndex).
				self dstLongAt: destIndex put: (destMask bitAnd: mergeWord).
			] ifFalse:[ "General version using dest masking"
				destWord := self dstLongAt: destIndex.
				mergeWord := self mergeFn: (skewWord bitAnd: halftoneWord)
								with: (destWord bitAnd: destMask).
				destWord := (destMask bitAnd: mergeWord) bitOr:
								(destWord bitAnd: destMask bitInvert32).
				self dstLongAt: destIndex put: destWord.
			].
			self incDestIndex: 4.
			words = 2 "e.g., is the next word the last word?"
				ifTrue:["set mask for last word in this row"
						destMask := mask2.
						nPix := endBits]
				ifFalse:["use fullword mask for inner loop"
						destMask := AllOnes.
						nPix := destPPW].
			(words := words - 1) = 0] whileFalse.
		"--- end of inner loop ---"
		self incSrcIndex: sourceDelta.
		self incDestIndex: destDelta]

]

{ #category : #'pixel mapping' }
BitBltSimulation >> default8To32Table [
	"Return the default translation table from 1..8 bit indexed colors to 32bit"
	"The table has been generated by the following statements"
	"| pvs hex |
	String streamContents:[:s|
		s nextPutAll:'static unsigned int theTable[256] = { '.
		pvs := (Color colorMapIfNeededFrom: 8 to: 32) asArray.
		1 to: pvs size do:[:i|
			i > 1 ifTrue:[s nextPutAll:', '].
			(i-1 \\ 8) = 0 ifTrue:[s cr].
			s nextPutAll:'0x'.
			hex := (pvs at: i) printStringBase: 16.
			s nextPutAll: (hex copyFrom: 4 to: hex size).
		].
		s nextPutAll:'};'.
	]."
	| theTable |
	<returnTypeC:'unsigned int *'>
	<var: #theTable declareC:'static unsigned int theTable[256] = { 
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
0xFFFFCCCC, 0xFFFFFFCC, 0xFFFF00FF, 0xFFFF33FF, 0xFFFF66FF, 0xFFFF99FF, 0xFFFFCCFF, 0xFFFFFFFF};'>
	^theTable
]

{ #category : #'pixel mapping' }
BitBltSimulation >> deltaFrom: x1 to: x2 nSteps: n [
	"Utility routine for computing Warp increments."
	<inline: true>
	x2 > x1
		ifTrue: [^ x2 - x1 + FixedPt1 // (n+1) + 1]
		ifFalse: [x2 = x1 ifTrue: [^ 0].
				^ 0 - (x1 - x2 + FixedPt1 // (n+1) + 1)]
]

{ #category : #setup }
BitBltSimulation >> destMaskAndPointerInit [
	"Compute masks for left and right destination words"
	| startBits pixPerM1 endBits |
	<inline: true>
	pixPerM1 := destPPW - 1.  "A mask, assuming power of two"
	"how many pixels in first word"
	startBits := destPPW - (dx bitAnd: pixPerM1).
	destMSB
		ifTrue:[ mask1 := AllOnes >> (32 - (startBits*destDepth))] 
		ifFalse:[ mask1 := AllOnes << (32 - (startBits*destDepth))].
	"how many pixels in last word"
	endBits := ((dx + bbW - 1) bitAnd: pixPerM1) + 1.
	destMSB 
		ifTrue:[mask2 := AllOnes << (32 - (endBits*destDepth))] 
		ifFalse:[mask2 := AllOnes >> (32 - (endBits*destDepth))].
	"determine number of words stored per line; merge masks if only 1"
	bbW < startBits
		ifTrue: [mask1 := mask1 bitAnd: mask2.
				mask2 := 0.
				nWords := 1]
		ifFalse: [nWords := (bbW - startBits) + pixPerM1 // destPPW + 1].
	hDir := vDir := 1. "defaults for no overlap with source"

	"calculate byte addr and delta, based on first word of data"
	"Note pitch is bytes and nWords is longs, not bytes"
	destIndex := destBits + (dy * destPitch) + ((dx // destPPW) *4).
	destDelta := destPitch * vDir - (4 * (nWords * hDir)).  "byte addr delta"

]

{ #category : #'combination rules' }
BitBltSimulation >> destinationWord: sourceWord with: destinationWord [
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	^destinationWord
]

{ #category : #'pixel mapping' }
BitBltSimulation >> dither32To16: srcWord threshold: ditherValue [
	"Dither the given 32bit word to 16 bit. Ignore alpha."
	| addThreshold  |
	<inline: true> "You bet"
	<returnTypeC: 'unsigned int'>
	<var: #srcWord type: 'unsigned int'>
	addThreshold := ditherValue bitShift: 8.
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
		ifTrue: [dx1 := 1]
		ifFalse: [xDelta = 0
				ifTrue: [dx1 := 0]
				ifFalse: [dx1 := -1]].
	yDelta > 0
		ifTrue: [dy1 := 1]
		ifFalse: [yDelta = 0
				ifTrue: [dy1 := 0]
				ifFalse: [dy1 := -1]].
	px := yDelta abs.
	py := xDelta abs.
	affL := affT := 9999.  "init null rectangle"
	affR := affB := -9999.
	py > px
		ifTrue: 
			["more horizontal"
			P := py // 2.
			1 to: py do: 
				[:i |
				destX := destX + dx1.
				(P := P - px) < 0 ifTrue: 
					[destY := destY + dy1.
					P := P + py].
				i < py ifTrue:
					[self copyBits.
					interpreterProxy failed ifTrue:
						[^ nil "bail out now on failure -- avoid storing x,y"].
					(affectedL < affectedR and: [affectedT < affectedB]) ifTrue:
						["Affected rectangle grows along the line"
						affL := affL min: affectedL.
						affR := affR max: affectedR.
						affT := affT min: affectedT.
						affB := affB max: affectedB.
						(affR - affL) * (affB - affT) > 4000 ifTrue:
							["If affected rectangle gets large, update it in chunks"
							affectedL := affL.  affectedR := affR.
							affectedT := affT.  affectedB := affB.
							self showDisplayBits.
							affL := affT := 9999.  "init null rectangle"
							affR := affB := -9999]].
					]]]
		ifFalse: 
			["more vertical"
			P := px // 2.
			1 to: px do:
				[:i |
				destY := destY + dy1.
				(P := P - py) < 0 ifTrue: 
					[destX := destX + dx1.
					P := P + px].
				i < px ifTrue:
					[self copyBits.
					interpreterProxy failed ifTrue:
						[^ nil "bail out now on failure -- avoid storing x,y"].
					(affectedL < affectedR and: [affectedT < affectedB]) ifTrue:
						["Affected rectangle grows along the line"
						affL := affL min: affectedL.
						affR := affR max: affectedR.
						affT := affT min: affectedT.
						affB := affB max: affectedB.
						(affR - affL) * (affB - affT) > 4000 ifTrue:
							["If affected rectangle gets large, update it in chunks"
							affectedL := affL.  affectedR := affR.
							affectedT := affT.  affectedB := affB.
							self showDisplayBits.
							affL := affT := 9999.  "init null rectangle"
							affR := affB := -9999]].
					]]].

	"Remaining affected rect"
	affectedL := affL.  affectedR := affR.
	affectedT := affT.  affectedB := affB.

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
	<inline: true>
	dstValue := self dstLongAt: idx.
	dstValue := dstValue bitAnd: dstMask.
	dstValue := dstValue bitOr: srcValue.
	self dstLongAt: idx put: dstValue.
]

{ #category : #setup }
BitBltSimulation >> ensureDestAndSourceFormsAreValid [
	"If a GC has occurred, update destForm and sourceForm from the stack."
	<inline: #always>
	numGCsOnInvocation ~= interpreterProxy statNumGCs ifTrue:
		[self reloadDestAndSourceForms]
]

{ #category : #'pixel mapping' }
BitBltSimulation >> expensiveDither32To16: srcWord threshold: ditherValue [
	"Dither the given 32bit word to 16 bit. Ignore alpha."
	| pv threshold value out |
	<inline: true> "You bet"
	<returnTypeC: 'unsigned int'>
	<var: #srcWord type: 'unsigned int'>
	pv := srcWord bitAnd: 255.
	threshold := ditherThresholds16 at: (pv bitAnd: 7).
	value := ditherValues16 at: (pv bitShift: -3).
	ditherValue < threshold
		ifTrue:[out := value + 1]
		ifFalse:[out := value].
	pv := (srcWord bitShift: -8) bitAnd: 255.
	threshold := ditherThresholds16 at: (pv bitAnd: 7).
	value := ditherValues16 at: (pv bitShift: -3).
	ditherValue < threshold
		ifTrue:[out := out bitOr: (value+1 bitShift:5)]
		ifFalse:[out := out bitOr: (value bitShift: 5)].
	pv := (srcWord bitShift: -16) bitAnd: 255.
	threshold := ditherThresholds16 at: (pv bitAnd: 7).
	value := ditherValues16 at: (pv bitShift: -3).
	ditherValue < threshold
		ifTrue:[out := out bitOr: (value+1 bitShift:10)]
		ifFalse:[out := out bitOr: (value bitShift: 10)].
	^out
]

{ #category : #'interpreter interface' }
BitBltSimulation >> fetchIntOrFloat: fieldIndex ofObject: objectPointer [
	"Return the integer value of the given field of the given object. If the field contains a Float, truncate it and return its integral part. Fail if the given field does not contain a small integer or Float, or if the truncated Float is out of the range of small integers."
	| fieldOop floatValue |
	<var: #floatValue type:'double '>
	fieldOop := interpreterProxy fetchPointer: fieldIndex ofObject: objectPointer.
	(interpreterProxy isIntegerObject: fieldOop)
		ifTrue:[^interpreterProxy integerValueOf: fieldOop].
	floatValue := interpreterProxy floatValueOf: fieldOop.
	(-2147483648.0 <= floatValue and:[floatValue <= 2147483647.0])
		ifFalse:[interpreterProxy primitiveFail. ^0].
	^floatValue asInteger
]

{ #category : #'interpreter interface' }
BitBltSimulation >> fetchIntOrFloat: fieldIndex ofObject: objectPointer ifNil: defaultValue [
	"Return the integer value of the given field of the given object. If the field contains a Float, truncate it and return its integral part. Fail if the given field does not contain a small integer or Float, or if the truncated Float is out of the range of small integers."
	| fieldOop floatValue |
	<var: #floatValue type:'double '>
	fieldOop := interpreterProxy fetchPointer: fieldIndex ofObject: objectPointer.
	(interpreterProxy isIntegerObject: fieldOop)
		ifTrue:[^interpreterProxy integerValueOf: fieldOop].
	(fieldOop = interpreterProxy nilObject) ifTrue:[^defaultValue].
	floatValue := interpreterProxy floatValueOf: fieldOop.
	(-2147483648.0 <= floatValue and:[floatValue <= 2147483647.0])
		ifFalse:[interpreterProxy primitiveFail. ^0].
	^floatValue asInteger
]

{ #category : #'combination rules' }
BitBltSimulation >> fixAlpha: sourceWord with: destinationWord [
	"For any non-zero pixel value in destinationWord with zero alpha channel take the alpha from sourceWord and fill it in. Intended for fixing alpha channels left at zero during 16->32 bpp conversions."
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
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

{ #category : #'memory access' }
BitBltSimulation >> incDestIndex: offset [
	<inline: true>
	^ destIndex := destIndex + offset

]

{ #category : #'memory access' }
BitBltSimulation >> incSrcIndex: offset [
	<inline: true>
	^ sourceIndex := sourceIndex + offset

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
	self cCode: 'opTable[41+1] = (void *)rgbComponentAlphawith'.
]

{ #category : #'initialize-release' }
BitBltSimulation >> initDither8Lookup [	
	<inline: false> 
	0 to: 255 do: [:b | 
		0 to: 15 do: [:t | | value |
			value := self expensiveDither32To16: b threshold: t.
			dither8Lookup at: ((t << 8)+b)put: value]].
	
]

{ #category : #'initialize-release' }
BitBltSimulation >> initialiseModule [
	<export: true>
	self initBBOpTable.
	self initDither8Lookup.
	self cppIf: #'ENABLE_FAST_BLT'
		ifTrue:[self initialiseCopyBits].
	^true
]

{ #category : #'interpreter interface' }
BitBltSimulation >> isIdentityMap: shifts with: masks [
	"Return true if shiftTable/maskTable define an identity mapping."
	<var: #shifts type:'int *'>
	<var: #masks type:'unsigned int *'>
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
	"Load the dest form for BitBlt. Answer false if anything is wrong, true otherwise."

	| destBitsSize |
	<inline: true>
	destBits := interpreterProxy fetchPointer: FormBitsIndex ofObject: destForm.
	destWidth := interpreterProxy fetchInteger: FormWidthIndex ofObject: destForm.
	destHeight := interpreterProxy fetchInteger: FormHeightIndex ofObject: destForm.
	(destWidth >= 0 and: [destHeight >= 0]) ifFalse:
		[^false].
	destDepth := interpreterProxy fetchInteger: FormDepthIndex ofObject: destForm.
	destMSB := destDepth > 0.
	destDepth < 0 ifTrue:
		[destDepth := 0 - destDepth].
	"Ignore an integer bits handle for Display in which case 
	the appropriate values will be obtained by calling ioLockSurfaceBits()."
	(interpreterProxy isIntegerObject: destBits)
		ifTrue: "Query for actual surface dimensions"
			[querySurfaceFn = 0 ifTrue: [self loadSurfacePlugin ifFalse: [^false]].
			 (self query: (interpreterProxy integerValueOf: destBits)
				Sur: (self addressOf: destWidth)
				fa: (self addressOf: destHeight)
				ce: (self addressOf: destDepth)
				Fn: (self addressOf: destMSB)) ifFalse:
					[interpreterProxy primitiveFailFor: PrimErrCallbackError.
					 ^false].
			destPPW := 32 // destDepth.
			destBits := destPitch := 0]
		ifFalse:
			[destPPW := 32 // destDepth.
			destPitch := destWidth + (destPPW-1) // destPPW * 4.
			destBitsSize := interpreterProxy byteSizeOf: destBits.
			((interpreterProxy isWordsOrBytes: destBits)
			 and: [destBitsSize >= (destPitch * destHeight)]) ifFalse:
				[^false].
			"Skip header since external bits don't have one"
			destBits := self oopForPointer: (interpreterProxy firstIndexableField: destBits)].
	^true
]

{ #category : #'interpreter interface' }
BitBltSimulation >> loadBitBltFrom: bbObj [
	"Load BitBlt from the oop.
	This function is exported for the Balloon engine."
	<export: true>
	^self loadBitBltFrom: bbObj warping: false.
]

{ #category : #'interpreter interface' }
BitBltSimulation >> loadBitBltFrom: bbObj warping: aBool [
	"Load context from BitBlt instance.  Return false if anything is amiss"
	"NOTE this should all be changed to minX/maxX coordinates for simpler clipping
		-- once it works!"
	| ok |
	<inline: false>
	bitBltOop := bbObj.
	isWarping := aBool.
	bitBltIsReceiver := bbObj = (interpreterProxy stackValue: interpreterProxy methodArgumentCount).
	numGCsOnInvocation := interpreterProxy statNumGCs.
	combinationRule := interpreterProxy fetchInteger: BBRuleIndex ofObject: bitBltOop.
	(interpreterProxy failed
		or: [combinationRule < 0 or: [combinationRule > (OpTableSize - 2)]])
		 ifTrue: [^false  "operation out of range"].
	(combinationRule >= 16 and: [combinationRule <= 17])
		 ifTrue: [^false  "fail for old simulated paint, erase modes"].
	sourceForm := interpreterProxy fetchPointer: BBSourceFormIndex ofObject: bitBltOop.
	noSource := self ignoreSourceOrHalftone: sourceForm.
	halftoneForm := interpreterProxy fetchPointer: BBHalftoneFormIndex ofObject: bitBltOop.
	noHalftone := self ignoreSourceOrHalftone: halftoneForm.

	destForm := interpreterProxy fetchPointer: BBDestFormIndex ofObject: bbObj.
	((interpreterProxy isPointers: destForm) and: [(interpreterProxy slotSizeOf: destForm) >= 4])
		ifFalse: [^false].
	ok := self loadBitBltDestForm.
	ok ifFalse:[^false].

	destX := self fetchIntOrFloat: BBDestXIndex ofObject: bitBltOop ifNil: 0.
	destY := self fetchIntOrFloat: BBDestYIndex ofObject: bitBltOop ifNil: 0.
	width := self fetchIntOrFloat: BBWidthIndex ofObject: bitBltOop ifNil: destWidth.
	height := self fetchIntOrFloat: BBHeightIndex ofObject: bitBltOop ifNil: destHeight.
	interpreterProxy failed ifTrue: [^false].

	noSource
		ifTrue:
			[sourceX := sourceY := 0]
		ifFalse: 
			[((interpreterProxy isPointers: sourceForm) and: [(interpreterProxy slotSizeOf: sourceForm) >= 4])
				ifFalse: [^false].
			ok := self loadBitBltSourceForm.
			ok ifFalse:[^false].
			ok := self loadColorMap.
			ok ifFalse:[^false].
			"Need the implicit setup here in case of 16<->32 bit conversions"
			(cmFlags bitAnd: ColorMapNewStyle) = 0 ifTrue:[self setupColorMasks].
			sourceX := self fetchIntOrFloat: BBSourceXIndex ofObject: bitBltOop ifNil: 0.
			sourceY := self fetchIntOrFloat: BBSourceYIndex ofObject: bitBltOop ifNil: 0].

	ok := self loadHalftoneForm.
	ok ifFalse:[^false].
	clipX := self fetchIntOrFloat: BBClipXIndex ofObject: bitBltOop ifNil: 0.
	clipY := self fetchIntOrFloat: BBClipYIndex ofObject: bitBltOop ifNil: 0.
	clipWidth := self fetchIntOrFloat: BBClipWidthIndex ofObject: bitBltOop ifNil: destWidth.
	clipHeight := self fetchIntOrFloat: BBClipHeightIndex ofObject: bitBltOop ifNil: destHeight.
	interpreterProxy failed ifTrue: [^ false  "non-integer value"].
	clipX < 0 ifTrue: [clipWidth := clipWidth + clipX.  clipX := 0].
	clipY < 0 ifTrue: [clipHeight := clipHeight + clipY.  clipY := 0].
	clipX+clipWidth > destWidth ifTrue: [clipWidth := destWidth - clipX].
	clipY+clipHeight > destHeight ifTrue: [clipHeight := destHeight - clipY].
	numGCsOnInvocation ~= interpreterProxy statNumGCs ifTrue: "querySurface could be a callback in loadSourceFor: and loadDestForm:"
		[interpreterProxy primitiveFailFor: PrimErrObjectMoved.
		 ^false].
	^true
]

{ #category : #'interpreter interface' }
BitBltSimulation >> loadBitBltSourceForm [
	"Load the source form for BitBlt. Return false if anything is wrong, true otherwise."
	| sourceBitsSize |
	<inline: true>
	sourceBits := interpreterProxy fetchPointer: FormBitsIndex ofObject: sourceForm.
	sourceWidth := self fetchIntOrFloat: FormWidthIndex ofObject: sourceForm.
	sourceHeight := self fetchIntOrFloat: FormHeightIndex ofObject: sourceForm.
	(sourceWidth >= 0 and: [sourceHeight >= 0]) ifFalse:
		[^false].
	sourceDepth := interpreterProxy fetchInteger: FormDepthIndex ofObject: sourceForm.
	sourceMSB := sourceDepth > 0.
	sourceDepth < 0 ifTrue:
		[sourceDepth := 0 - sourceDepth].
	"Ignore an integer bits handle for Display in which case 
	 the appropriate values will be obtained by calling ioLockSurfaceBits()."
	(interpreterProxy isIntegerObject: sourceBits)
		ifTrue: "Query for actual surface dimensions"
			[querySurfaceFn = 0 ifTrue: [self loadSurfacePlugin ifFalse:[^false]].
			 (self query: (interpreterProxy integerValueOf: sourceBits)
				Sur: (self addressOf: sourceWidth)
				fa: (self addressOf: sourceHeight)
				ce: (self addressOf: sourceDepth)
				Fn: (self addressOf: sourceMSB)) ifFalse:
					[interpreterProxy primitiveFailFor: PrimErrCallbackError.
					 ^false].
			sourcePPW := 32 // sourceDepth.
			sourceBits := sourcePitch := 0]
		ifFalse:
			[sourcePPW := 32 // sourceDepth.
			sourcePitch := sourceWidth + (sourcePPW-1) // sourcePPW * 4.
			sourceBitsSize := interpreterProxy byteSizeOf: sourceBits.
			((interpreterProxy isWordsOrBytes: sourceBits)
			 and: [sourceBitsSize >= (sourcePitch * sourceHeight)]) ifFalse:
				[^false].
			"Skip header since external bits don't have one"
			sourceBits := self oopForPointer: (interpreterProxy firstIndexableField: sourceBits)].
	^true
]

{ #category : #'interpreter interface' }
BitBltSimulation >> loadColorMap [
	"ColorMap, if not nil, must be longWords, and 
	2^N long, where N = sourceDepth for 1, 2, 4, 8 bits, 
	or N = 9, 12, or 15 (3, 4, 5 bits per color) for 16 or 32 bits."
	| cmSize oldStyle oop cmOop |
	<inline: true>
	cmFlags := cmMask := cmBitsPerColor := 0.
	cmShiftTable := nil.
	cmMaskTable := nil.
	cmLookupTable := nil.
	cmOop := interpreterProxy fetchPointer: BBColorMapIndex ofObject: bitBltOop.
	cmOop = interpreterProxy nilObject ifTrue:[^true].
	cmFlags := ColorMapPresent. "even if identity or somesuch - may be cleared later"
	oldStyle := false.
	(interpreterProxy isWords: cmOop) ifTrue:[
		"This is an old-style color map (indexed only, with implicit RGBA conversion)"
		cmSize := interpreterProxy slotSizeOf: cmOop.
		cmLookupTable := interpreterProxy firstIndexableField: cmOop.
		oldStyle := true.
	] ifFalse: [
		"A new-style color map (fully qualified)"
		((interpreterProxy isPointers: cmOop) 
			and:[(interpreterProxy slotSizeOf: cmOop) >= 3]) ifFalse:[^false].
		cmShiftTable := self loadColorMapShiftOrMaskFrom:
			(interpreterProxy fetchPointer: 0 ofObject: cmOop).
		cmMaskTable := self loadColorMapShiftOrMaskFrom:
			(interpreterProxy fetchPointer: 1 ofObject: cmOop).
		oop := interpreterProxy fetchPointer: 2 ofObject: cmOop.
		oop = interpreterProxy nilObject 
			ifTrue:[cmSize := 0]
			ifFalse:[(interpreterProxy isWords: oop) ifFalse:[^false].
					cmSize := (interpreterProxy slotSizeOf: oop).
					cmLookupTable := interpreterProxy firstIndexableField: oop].
		cmFlags := cmFlags bitOr: ColorMapNewStyle.
		self cCode: '' inSmalltalk:
			[].
	].
	(cmSize bitAnd: cmSize - 1) = 0 ifFalse:[^false].
	cmMask := cmSize - 1.
	cmBitsPerColor := 0.
	cmSize = 512 ifTrue: [cmBitsPerColor := 3].
	cmSize = 4096 ifTrue: [cmBitsPerColor := 4].
	cmSize = 32768 ifTrue: [cmBitsPerColor := 5].
	cmSize = 0
		ifTrue:[cmLookupTable := nil. cmMask := 0]
		ifFalse:[cmFlags := cmFlags bitOr: ColorMapIndexedPart].
	oldStyle "needs implicit conversion"
		ifTrue:[	self setupColorMasks].
	"Check if colorMap is just identity mapping for RGBA parts"
	(self isIdentityMap: cmShiftTable with: cmMaskTable)
		ifTrue:[ cmMaskTable := nil. cmShiftTable := nil ]
		ifFalse:[ cmFlags := cmFlags bitOr: ColorMapFixedPart].
	^true
]

{ #category : #'interpreter interface' }
BitBltSimulation >> loadColorMapShiftOrMaskFrom: mapOop [
	<returnTypeC:'void *'>
	mapOop = interpreterProxy nilObject ifTrue:[^nil].
	((interpreterProxy isWords: mapOop) 
		and:[(interpreterProxy slotSizeOf: mapOop) = 4])
			ifFalse:[interpreterProxy primitiveFail. ^nil].
	^interpreterProxy firstIndexableField: mapOop
]

{ #category : #'interpreter interface' }
BitBltSimulation >> loadHalftoneForm [
	"Load the halftone form"
	| halftoneBits |
	<inline: true>
	noHalftone ifTrue:[
		halftoneBase := nil.
		^true].
	((interpreterProxy isPointers: halftoneForm) and: [(interpreterProxy slotSizeOf: halftoneForm) >= 4])
		ifTrue:
		["Old-style 32xN monochrome halftone Forms"
		halftoneBits := interpreterProxy fetchPointer: FormBitsIndex ofObject: halftoneForm.
		halftoneHeight := interpreterProxy fetchInteger: FormHeightIndex ofObject: halftoneForm.
		(interpreterProxy isWords: halftoneBits)
			ifFalse: [noHalftone := true]]
		ifFalse:
		["New spec accepts, basically, a word array"
		((interpreterProxy isPointers: halftoneForm) not
			and: [interpreterProxy isWords: halftoneForm])
			ifFalse: [^ false].
		halftoneBits := halftoneForm.
		halftoneHeight := interpreterProxy slotSizeOf: halftoneBits].
	halftoneBase := self oopForPointer: (interpreterProxy firstIndexableField: halftoneBits).
	^true
]

{ #category : #'surface support' }
BitBltSimulation >> loadSurfacePlugin [
	"Load the surface support plugin"
	querySurfaceFn := interpreterProxy ioLoadFunction:'ioGetSurfaceFormat' From:'SurfacePlugin'.
	lockSurfaceFn := interpreterProxy ioLoadFunction:'ioLockSurface' From:'SurfacePlugin'.
	unlockSurfaceFn := interpreterProxy ioLoadFunction:'ioUnlockSurface' From:'SurfacePlugin'.
	^querySurfaceFn ~= 0 and:[lockSurfaceFn ~= 0 and:[unlockSurfaceFn ~= 0]]
]

{ #category : #'interpreter interface' }
BitBltSimulation >> loadWarpBltFrom: bbObj [
	^self loadBitBltFrom: bbObj warping: true
]

{ #category : #'surface support' }
BitBltSimulation >> lock: sourceHandle Su: pitchPtr rf: x ac: y eF: w n: h [
	"Simulate the lockSurfaceFn function call as a failure to load the surface."
	<doNotGenerate>
	^0
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

	* Fail if a GC has occurred since the primitive started (presumably in the lockSurface
	   function), because one or more of the primitives' parameters may have been moved.
	"
	| sourceHandle destHandle l r t b |
	<inline: true>
	self assert: numGCsOnInvocation = interpreterProxy statNumGCs.
	hasSurfaceLock := false.
	destBits = 0 ifTrue: "Blitting *to* OS surface"
		[lockSurfaceFn = 0 ifTrue: [self loadSurfacePlugin ifFalse: [^false]].
		 destHandle := interpreterProxy fetchInteger: FormBitsIndex ofObject: destForm.
		 (sourceBits ~= 0 or: [noSource]) ifFalse:
			[sourceHandle := interpreterProxy fetchInteger: FormBitsIndex ofObject: sourceForm.
			 "Handle the special case of equal source and dest handles"
			 sourceHandle = destHandle ifTrue:
				"If we have overlapping source/dest we lock the entire area
				so that there is only one area transmitted"
				[isWarping
					ifFalse: "When warping we always need the entire surface for the source"
						[sourceBits := self lock: sourceHandle
											Su: (self addressOf: sourcePitch)
											rf: 0
											ac: 0
											eF: sourceWidth
											n: sourceHeight]
					ifTrue: "Otherwise use overlapping area"
						[l := sx min: dx. r := (sx max: dx) + bbW.
						t := sy min: dy. b := (sy max: dy) + bbH.
						sourceBits := self lock: sourceHandle
											Su: (self addressOf: sourcePitch)
											rf: l
											ac: t
											eF: r - l
											n: b - t].
				destBits := sourceBits.
				destPitch := sourcePitch.
				hasSurfaceLock := true.
				numGCsOnInvocation ~= interpreterProxy statNumGCs ifTrue:
					[self unlockSurfaces.
					 interpreterProxy primitiveFailFor: PrimErrObjectMoved.
					 ^false].
				destBits = 0 ifTrue:
					[self unlockSurfaces.
					 interpreterProxy primitiveFailFor: PrimErrCallbackError.
					 ^false].
				^true]].
		"Fall through - if not equal it'll be handled below"
		destBits := self lock: destHandle
						Su: (self addressOf: destPitch)
						rf: dx
						ac: dy
						eF: bbW
						n: bbH.
		hasSurfaceLock := true.
		numGCsOnInvocation ~= interpreterProxy statNumGCs ifTrue:
			[self unlockSurfaces.
			 interpreterProxy primitiveFailFor: PrimErrObjectMoved.
			 ^false].
		destBits = 0 ifTrue:
			[interpreterProxy primitiveFailFor: PrimErrCallbackError]].

	(sourceBits ~= 0 or: [noSource]) ifFalse: "Blitting *from* OS surface"
		[sourceHandle := interpreterProxy fetchInteger: FormBitsIndex ofObject: sourceForm.
		 interpreterProxy failed ifTrue: [^false]. "fetch sourceHandle could fail"
		lockSurfaceFn = 0 ifTrue:[self loadSurfacePlugin ifFalse:[^false]].
		"Warping requiring the entire surface"
		isWarping
			ifTrue:
				[sourceBits := self lock: sourceHandle
												Su: (self addressOf: sourcePitch)
												rf: 0
												ac: 0
												eF: sourceWidth
												n: sourceHeight]
			ifFalse:
				[sourceBits := self lock: sourceHandle
									Su: (self addressOf: sourcePitch)
									rf: sx
									ac: sy
									eF: bbW
									n: bbH].
		hasSurfaceLock := true.
		numGCsOnInvocation ~= interpreterProxy statNumGCs ifTrue:
			[self unlockSurfaces.
			 interpreterProxy primitiveFailFor: PrimErrObjectMoved.
			 ^false].
		sourceBits = 0 ifTrue:
			[interpreterProxy primitiveFailFor: PrimErrCallbackError]].
	^destBits ~= 0 and: [sourceBits ~= 0 or: [noSource]]
]

{ #category : #'color mapping' }
BitBltSimulation >> mapPixel: sourcePixel flags: mapperFlags [
	"Color map the given source pixel."
	| pv |
	<inline: true>
	pv := sourcePixel.
	(mapperFlags bitAnd: ColorMapPresent) ~= 0 ifTrue:[
		(mapperFlags bitAnd: ColorMapFixedPart) ~= 0 ifTrue:[
			pv := self rgbMapPixel: sourcePixel flags: mapperFlags.
			"avoid introducing transparency by color reduction"
			(pv = 0 and:[sourcePixel ~= 0]) ifTrue:[pv := 1]].
		(mapperFlags bitAnd: ColorMapIndexedPart) ~= 0
			ifTrue:[pv := cmLookupTable at: (pv bitAnd: cmMask)].
	].
	^pv
]

{ #category : #'combination rules' }
BitBltSimulation >> merge: sourceWord with: destinationWord [
	| mergeFnwith |
	"Sender warpLoop is too big to include this in-line"
	<var: #mergeFnwith declareC: 'unsigned int (*mergeFnwith)(unsigned int, unsigned int)'>
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	mergeFnwith := self cCoerce: (opTable at: combinationRule+1) to: 'unsigned int (*)(unsigned int, unsigned int)'.
	mergeFnwith.  "null ref for compiler"

	^ self mergeFn: sourceWord with: destinationWord
]

{ #category : #'initialize-release' }
BitBltSimulation >> moduleUnloaded: aModuleName [
	"The module with the given name was just unloaded.
	 Make sure we have no dangling references."
	<export: true>
	<var: #aModuleName type: 'char *'>
	(aModuleName strcmp: 'SurfacePlugin') = 0 ifTrue: "The surface plugin just shut down. How nasty."
		[querySurfaceFn := 0.
		 lockSurfaceFn := 0.
		 unlockSurfaceFn := 0]
]

{ #category : #'combination rules' }
BitBltSimulation >> partitionedAND: word1 to: word2 nBits: nBits nPartitions: nParts [
	"AND word1 to word2 as nParts partitions of nBits each.
	Any field of word1 not all-ones is treated as all-zeroes.
	Used for erasing, eg, brush shapes prior to ORing in a color"
	| mask result |
	<returnTypeC: 'unsigned int'>
	<var: #word1 type: 'unsigned int'>
	<var: #word2 type: 'unsigned int'>
	<var: #result type: 'unsigned int'>
	mask := maskTable at: nBits.  "partition mask starts at the right"
	result := 0.
	1 to: nParts do:
		[:i |
		(word1 bitAnd: mask) = mask
			ifTrue: [result := result bitOr: (word2 bitAnd: mask)].
		mask := mask << nBits  "slide left to next partition"].
	^ result

]

{ #category : #'combination rules' }
BitBltSimulation >> partitionedAdd: word1 to: word2 nBits: nBits componentMask: componentMask carryOverflowMask: carryOverflowMask [
	"Add word1 to word2 as nParts partitions of nBits each.
	This is useful for packed pixels, or packed colors"
	| carryOverflow sum w1 w2 |
	"Use unsigned int everywhere because it has a well known arithmetic model without undefined behavior w.r.t. overflow and shifts"
	<returnTypeC: 'unsigned int'>
	 <var: #word1 type: 'unsigned int'>
	<var: #word2 type: 'unsigned int'>
	 <var: #w1 type: 'unsigned int'>
	<var: #w2 type: 'unsigned int'>
	<var: #componentMask type: 'unsigned int'>
	<var: #carryOverflowMask type: 'unsigned int'>
	<var: #carryOverflow type: 'unsigned int'>
	<var: #sum type: 'unsigned int'>
	w1 := word1 bitAnd: carryOverflowMask. "mask to remove high bit of each component"
	w2 := word2 bitAnd: carryOverflowMask.
	sum := (word1 bitXor: w1)+(word2 bitXor: w2). "sum without high bit to avoid overflowing over next component"
	carryOverflow := (w1 bitAnd: w2) bitOr: ((w1 bitOr: w2) bitAnd: sum). "detect overflow condition for saturating"
	^((sum bitXor: w1)bitXor:w2) "sum high bit without overflow"
		bitOr: carryOverflow>>(nBits-1) * componentMask "saturate in case of overflow"
]

{ #category : #'combination rules' }
BitBltSimulation >> partitionedMax: word1 with: word2 nBits: nBits nPartitions: nParts [
	"Max word1 to word2 as nParts partitions of nBits each"
	| mask result |
	"In C, most arithmetic operations answer the same bit pattern regardless of the operands being signed or unsigned ints
	(this is due to the way 2's complement numbers work). However, comparisions might fail. Add the proper declaration of
	words as unsigned int in those cases where comparisions are done (jmv)"
	<returnTypeC: 'unsigned int'>
	<var: #word1 type: 'unsigned int'>
	<var: #word2 type: 'unsigned int'>
	<var: #mask type: 'unsigned int'>
	<var: #result type: 'unsigned int'>
	mask := maskTable at: nBits.  "partition mask starts at the right"
	result := 0.
	1 to: nParts do:
		[:i |
		result := result bitOr: ((word2 bitAnd: mask) max: (word1 bitAnd: mask)).
		mask := mask << nBits  "slide left to next partition"].
	^ result

]

{ #category : #'combination rules' }
BitBltSimulation >> partitionedMin: word1 with: word2 nBits: nBits nPartitions: nParts [
	"Min word1 to word2 as nParts partitions of nBits each"
	| mask result |
	"In C, most arithmetic operations answer the same bit pattern regardless of the operands being signed or unsigned ints
	(this is due to the way 2's complement numbers work). However, comparisions might fail. Add the proper declaration of
	words as unsigned int in those cases where comparisions are done (jmv)"
	<returnTypeC: 'unsigned int'>
	<var: #word1 type: 'unsigned int'>
	<var: #word2 type: 'unsigned int'>
	<var: #mask type: 'unsigned int'>
	<var: #result type: 'unsigned int'>
	mask := maskTable at: nBits.  "partition mask starts at the right"
	result := 0.
	1 to: nParts do:
		[:i |
		result := result bitOr: ((word2 bitAnd: mask) min: (word1 bitAnd: mask)).
		mask := mask << nBits  "slide left to next partition"].
	^ result

]

{ #category : #'combination rules' }
BitBltSimulation >> partitionedMul: word1 with: word2 nBits: nBits nPartitions: nParts [
	"Multiply word1 with word2 as nParts partitions of nBits each.
	This is useful for packed pixels, or packed colors.
	Bug in loop version when non-white background"

	| sMask product result dMask |
	"In C, integer multiplication might answer a wrong value if the unsigned values are declared as signed.
	This problem does not affect this method, because the most significant bit (i.e. the sign bit) will
	always be zero (jmv)"
	<returnTypeC: 'unsigned int'>
	<var: #word1 type: 'unsigned int'>
	<var: #word2 type: 'unsigned int'>
	<var: #sMask type: 'unsigned int'>
	<var: #dMask type: 'unsigned int'>
	<var: #result type: 'unsigned int'>
	<var: #product type: 'unsigned int'>
	sMask := maskTable at: nBits.  "partition mask starts at the right"
	dMask :=  sMask << nBits.
	result := (((word1 bitAnd: sMask)+1) * ((word2 bitAnd: sMask)+1) - 1 
				bitAnd: dMask) >> nBits.	"optimized first step"
	nParts = 1
		ifTrue: [ ^result ].
	product := (((word1>>nBits bitAnd: sMask)+1) * ((word2>>nBits bitAnd: sMask)+1) - 1 bitAnd: dMask).
	result := result bitOr: product.
	nParts = 2
		ifTrue: [ ^result ].
	product := (((word1>>(2*nBits) bitAnd: sMask)+1) * ((word2>>(2*nBits) bitAnd: sMask)+1) - 1 bitAnd: dMask).
	result := result bitOr: product << nBits.
	nParts = 3
		ifTrue: [ ^result ].
	product := (((word1>>(3*nBits) bitAnd: sMask)+1) * ((word2>>(3*nBits) bitAnd: sMask)+1) - 1 bitAnd: dMask).
	result := result bitOr: product << (2*nBits).
	^ result

"	| sMask product result dMask |
	sMask := maskTable at: nBits.  'partition mask starts at the right'
	dMask :=  sMask << nBits.
	result := (((word1 bitAnd: sMask)+1) * ((word2 bitAnd: sMask)+1) - 1 
				bitAnd: dMask) >> nBits.	'optimized first step'
	nBits to: nBits * (nParts-1) by: nBits do: [:ofs |
		product := (((word1>>ofs bitAnd: sMask)+1) * ((word2>>ofs bitAnd: sMask)+1) - 1 bitAnd: dMask).
		result := result bitOr: (product bitAnd: dMask) << (ofs-nBits)].
	^ result"
]

{ #category : #'combination rules' }
BitBltSimulation >> partitionedRgbComponentAlpha: sourceWord dest: destWord nBits: nBits nPartitions: nParts [
	| mask result p1 p2 v |
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destWord type: 'unsigned int'>
	<var: #p1 type: 'unsigned int'>
	<var: #p2 type: 'unsigned int'>
	<var: #mask type: 'unsigned int'>
	<var: #result type: 'unsigned int'>
	mask := maskTable at: nBits.  "partition mask starts at the right"
	result := 0.
	1 to: nParts do:
		[:i |
		p1 := (sourceWord bitAnd: mask) >> ((i - 1)*nBits).
		p2 := (destWord bitAnd: mask) >> ((i - 1)*nBits).
		nBits = 32
			ifFalse:[
				nBits = 16
					ifTrue:[
						p1 := (self rgbMap16To32: p1) bitOr: 16rFF000000.
						p2 := (self rgbMap16To32: p2) bitOr: 16rFF000000]
					ifFalse:[
						p1 := (self rgbMap: p1 from: nBits to: 32) bitOr: 16rFF000000.
						p2 := (self rgbMap: p2 from: nBits to: 32) bitOr: 16rFF000000.]].
		v := self rgbComponentAlpha32: p1 with: p2.
		nBits = 32
			ifFalse:[
				v := self rgbMap: v from: 32 to: nBits].
		result := result bitOr: (v <<  ((i - 1)*nBits)). 
		mask := mask << nBits  "slide left to next partition"].
	^ result

]

{ #category : #'combination rules' }
BitBltSimulation >> partitionedSub: word1 from: word2 nBits: nBits nPartitions: nParts [
	"Subtract word1 from word2 as nParts partitions of nBits each.
	This is useful for packed pixels, or packed colors"
	| mask result p1 p2 |
	"In C, most arithmetic operations answer the same bit pattern regardless of the operands being signed or unsigned ints
	(this is due to the way 2's complement numbers work). However, comparisions might fail. Add the proper declaration of
	words as unsigned int in those cases where comparisions are done (jmv)"
	<returnTypeC: 'unsigned int'>
	<var: #word1 type: 'unsigned int'>
	<var: #word2 type: 'unsigned int'>
	<var: #p1 type: 'unsigned int'>
	<var: #p2 type: 'unsigned int'>
	<var: #mask type: 'unsigned int'>
	<var: #result type: 'unsigned int'>
	mask := maskTable at: nBits.  "partition mask starts at the right"
	result := 0.
	1 to: nParts do:
		[:i |
		p1 := word1 bitAnd: mask.
		p2 := word2 bitAnd: mask.
		p1 < p2  "result is really abs value of thedifference"
			ifTrue: [result := result bitOr: p2 - p1]
			ifFalse: [result := result bitOr: p1 - p2].
		mask := mask << nBits  "slide left to next partition"].
	^ result

]

{ #category : #setup }
BitBltSimulation >> performCopyLoop [
	"Based on the values provided during setup choose and
	perform the appropriate inner loop function."
	<inline: true> "Should be inlined into caller for speed"
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
	<inline: true> "oh please"
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: #'unsigned int'>
	<var: #destWord type: #'unsigned int'>
	sourceWord := self srcLongAt: sourceIndex.
	destWord := 0.
	srcShift := srcBitShift. "Hint: Keep in register"
	dstShift := dstBitShift. "Hint: Keep in register"
	nPix := nPixels. "always > 0 so we can use do { } while(--nPix);"
	(mapperFlags = (ColorMapPresent bitOr: ColorMapIndexedPart)) ifTrue:[
		"a little optimization for (pretty crucial) blits using indexed lookups only"
		[	"grab, colormap and mix in pixel"
			sourcePix := sourceWord >> srcShift bitAnd: srcMask.
			destPix := cmLookupTable at: (sourcePix bitAnd: cmMask).
			destWord := destWord bitOr: (destPix bitAnd: dstMask) << dstShift.
			"adjust dest pix index"
			dstShift := dstShift + dstShiftInc.
			"adjust source pix index"
			((srcShift := srcShift + srcShiftInc) bitAnd: 16rFFFFFFE0) = 0 ifFalse:[
				sourceMSB ifTrue:[srcShift := srcShift + 32] ifFalse:[srcShift := srcShift - 32].
				sourceWord := self srcLongAt: (self incSrcIndex: 4)].
		(nPix := nPix - 1) = 0] whileFalse.
	] ifFalse:[
		[	"grab, colormap and mix in pixel"
			sourcePix := sourceWord >> srcShift bitAnd: srcMask.
			destPix := self mapPixel: sourcePix flags: mapperFlags.
			destWord := destWord bitOr: (destPix bitAnd: dstMask) << dstShift.
			"adjust dest pix index"
			dstShift := dstShift + dstShiftInc.
			"adjust source pix index"
			((srcShift := srcShift + srcShiftInc) bitAnd: 16rFFFFFFE0) = 0 ifFalse:[
				sourceMSB ifTrue:[srcShift := srcShift + 32] ifFalse:[srcShift := srcShift - 32].
				sourceWord := self srcLongAt: (self incSrcIndex: 4)].
		(nPix := nPix - 1) = 0] whileFalse.
	].
	srcBitShift := srcShift. "Store back"
	^destWord

]

{ #category : #'pixel mapping' }
BitBltSimulation >> pickWarpPixelAtX: xx y: yy [
	"Pick a single pixel from the source for WarpBlt.
	Note: This method is crucial for WarpBlt speed w/o smoothing
	and still relatively important when smoothing is used."
	| x y srcIndex sourceWord sourcePix |
	<inline: true> "*please*"
	<returnTypeC: #'unsigned int'>
	<var: #sourceWord type: #'unsigned int'>

	"note: it would be much faster if we could just
	avoid these stupid tests for being inside sourceForm."
	(xx < 0 or:[yy < 0 or:[
		(x := xx >> BinaryPoint) >= sourceWidth or:[
			(y := yy >> BinaryPoint) >= sourceHeight]]]) ifTrue:[^0]. "out of bounds"

	"Fetch source word.
	Note: We should really update srcIndex with sx and sy so that
	we don't have to do the computation below. We might even be
	able to simplify the out of bounds test from above."
	srcIndex := sourceBits + (y * sourcePitch) + (x >> warpAlignShift * 4).
	sourceWord := self srcLongAt: srcIndex.

	"Extract pixel from word"
	srcBitShift := warpBitShiftTable at: (x bitAnd: warpAlignMask).
	sourcePix := sourceWord >> srcBitShift bitAnd: warpSrcMask.
	^sourcePix
]

{ #category : #'combination rules' }
BitBltSimulation >> pixClear: sourceWord with: destinationWord [
	"Clear all pixels in destinationWord for which the pixels of sourceWord have the same values. Used to clear areas of some constant color to zero."
	| mask result nBits pv |
	<inline: false>
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	<var: #mask type: 'unsigned int'>
	<var: #pv type: 'unsigned int'>
	<var: #result type: 'unsigned int'>
	destDepth = 32 ifTrue:[
		sourceWord = destinationWord ifTrue:[^0] ifFalse:[^destinationWord].
	].
	nBits := destDepth.
	mask := maskTable at: nBits.  "partition mask starts at the right"
	result := 0.
	1 to: destPPW do:[:i |
		pv := destinationWord bitAnd: mask.
		(sourceWord bitAnd: mask) = pv ifTrue:[pv := 0].
		result := result bitOr: pv.
		mask := mask << nBits "slide left to next partition"].
	^ result
]

{ #category : #'combination rules' }
BitBltSimulation >> pixMask: sourceWord with: destinationWord [
	<inline: false>
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	^ self partitionedAND: sourceWord bitInvert32 to: destinationWord
					nBits: destDepth nPartitions: destPPW
]

{ #category : #'combination rules' }
BitBltSimulation >> pixPaint: sourceWord with: destinationWord [
	<inline: false>
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	sourceWord = 0 ifTrue: [^ destinationWord].
	^ sourceWord bitOr:
		(self partitionedAND: sourceWord bitInvert32 to: destinationWord
						nBits: destDepth nPartitions: destPPW)
]

{ #category : #'combination rules' }
BitBltSimulation >> pixSwap: sourceWord with: destWord [
	"Swap the pixels in destWord"
	| result shift lowMask highMask |
	<inline: false>
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destWord type: 'unsigned int'>
	<var: #lowMask type: 'unsigned int'>
	<var: #highMask type: 'unsigned int'>
	<var: #result type: 'unsigned int'>
	destPPW = 1 ifTrue:[^destWord]. "a single pixel per word"
	result := 0.
	lowMask := (1 << destDepth) - 1. "mask low pixel"
	highMask := lowMask << (destPPW-1 * destDepth). "mask high pixel"
	shift := 32 - destDepth.
	result := result bitOr: (
				(destWord bitAnd: lowMask) << shift bitOr:
					(destWord bitAnd: highMask) >> shift).
	destPPW <= 2 ifTrue:[^result].
	2 to: destPPW // 2 do:[:i|
		lowMask := lowMask << destDepth.
		highMask := highMask >> destDepth.
		shift := shift - (destDepth * 2).
		result := result bitOr: (
					(destWord bitAnd: lowMask) << shift bitOr:
						(destWord bitAnd: highMask) >> shift)].
	^result
]

{ #category : #primitives }
BitBltSimulation >> primitiveCompareColorA: colorA to: colorB test: testID [ 
	"Invoke the pixel color comparing primitive.Only applicable if compiling
	with ENABLE_FAST_BLT"
	| rcvr val |
	<export: true>
	rcvr := self
				primitive: 'primitiveCompareColors'
				parameters: #(#Unsigned #Unsigned #SmallInteger )
				receiver: #Oop.
	self
		cppIf: #'ENABLE_FAST_BLT'
		ifTrue: [(self loadBitBltFrom: rcvr)
					ifFalse: [^ interpreterProxy primitiveFail].
			self clipRange.
			(bbW <= 0 or: [bbH <= 0])
				ifTrue: ["zero width or height; noop"
					^ interpreterProxy primitiveFail].
			self cCode: '
	compare_operation_t op;
	op.matchRule = testID & 3;
	op.tally = testID & (1u<<3);
	op.srcA.bits = (void *) sourceBits;
	op.srcA.pitch = sourcePitch;
	op.srcA.depth = sourceDepth;
	op.srcA.msb = sourceMSB;
	op.srcA.x = sx;
	op.srcA.y = sy;
	op.srcB.bits = (void *) destBits;
	op.srcB.pitch = destPitch;
	op.srcB.depth = destDepth;
	op.srcB.msb = destMSB;
	op.srcB.x = dx;
	op.srcB.y = dy;
	op.width = bbW;
	op.height = bbH;
	op.colorA = colorA;
	op.colorB = colorB;

	val = compareColorsDispatch(&op);'.
	^val asPositiveIntegerObj]
		ifFalse: [interpreterProxy primitiveFail]
]

{ #category : #primitives }
BitBltSimulation >> primitiveCopyBits [
	"Invoke the copyBits primitive. If the destination is the display, then copy it to the screen."
	| rcvr |
	<export: true>
	rcvr := interpreterProxy stackValue: interpreterProxy methodArgumentCount.
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
	<export: true>
	<var: #sourcePtr type: 'char *'>
	interpreterProxy methodArgumentCount = 6 ifFalse:
		[^interpreterProxy primitiveFail].
	kernDelta := interpreterProxy stackIntegerValue: 0.
	xTable := interpreterProxy stackObjectValue: 1.
	glyphMap := interpreterProxy stackObjectValue: 2.
	stopIndex := interpreterProxy stackIntegerValue: 3.
	startIndex := interpreterProxy stackIntegerValue: 4.
	sourceString := interpreterProxy stackObjectValue: 5.
	bbObj := interpreterProxy stackObjectValue: 6.
	interpreterProxy failed ifTrue:
		[^nil].

	((interpreterProxy isArray: xTable)
	 and: [(interpreterProxy isArray: glyphMap)
	 and: [(interpreterProxy slotSizeOf: glyphMap) = 256
	 and: [(interpreterProxy isBytes: sourceString)
	 and: [startIndex > 0
	 and: [stopIndex > 0
	 and: [stopIndex <= (interpreterProxy byteSizeOf: sourceString)
	 and: [(self loadBitBltFrom: bbObj)
	 and: [combinationRule ~= 30 "these two need extra source alpha"
	 and: [combinationRule ~= 31]]]]]]]]]) ifFalse:
		[^interpreterProxy primitiveFail].
	maxGlyph := (interpreterProxy slotSizeOf: xTable) - 2.
	"See if we can go directly into copyLoopPixMap (usually we can)"
	quickBlt := destBits ~= 0 "no OS surfaces please"
				and:[sourceBits ~= 0 "and again"
				and:[noSource = false "needs a source"
				and:[sourceForm ~= destForm "no blits onto self"
				and:[cmFlags ~= 0 
					 or:[sourceMSB ~= destMSB 
					 or:[sourceDepth ~= destDepth]]]]]]. "no point using slower version"
	left := destX.
	sourcePtr := interpreterProxy firstIndexableField: sourceString.
	startIndex to: stopIndex do:[:charIndex|
		ascii := interpreterProxy byteAtPointer: sourcePtr + charIndex - 1.
		glyphIndex := interpreterProxy fetchInteger: ascii ofObject: glyphMap.
		(glyphIndex < 0 or:[glyphIndex > maxGlyph]) 
			ifTrue:[^interpreterProxy primitiveFail].
		sourceX := interpreterProxy fetchInteger: glyphIndex ofObject: xTable.
		width := (interpreterProxy fetchInteger: glyphIndex+1 ofObject: xTable) - sourceX.
		interpreterProxy failed ifTrue:[^nil].
		self clipRange.	"Must clip here"
		(bbW > 0 and:[bbH > 0]) ifTrue: [
			quickBlt ifTrue:[
				self destMaskAndPointerInit.
				self copyLoopPixMap.
				"both, hDir and vDir are known to be > 0"
				affectedL := dx.
				affectedR := dx + bbW.
				affectedT := dy.
				affectedB := dy + bbH.
			] ifFalse:[self copyBits]].
		interpreterProxy failed ifTrue:[^nil].
		destX := destX + width + kernDelta.
	 ].
	affectedL := left.
	self showDisplayBits.
	"store destX back"	
	interpreterProxy storeInteger: BBDestXIndex ofObject: bbObj withValue: destX.
	interpreterProxy pop: 6. "pop args, return rcvr"
]

{ #category : #primitives }
BitBltSimulation >> primitiveDrawLoop [
	"Invoke the line drawing primitive."
	| rcvr xDelta yDelta |
	<export: true>
	rcvr := interpreterProxy stackValue: 2.
	xDelta := interpreterProxy stackIntegerValue: 1.
	yDelta := interpreterProxy stackIntegerValue: 0.
	(self loadBitBltFrom: rcvr) ifFalse:[^interpreterProxy primitiveFail].
	interpreterProxy failed ifFalse:[
		self drawLoopX: xDelta Y: yDelta.
		self showDisplayBits].
	interpreterProxy failed ifFalse:[interpreterProxy pop: 2].
]

{ #category : #primitives }
BitBltSimulation >> primitivePixelValueAtX: xVal y: yVal [
	"returns the single pixel at x@y.
	It does not handle LSB bitmaps right now.
	If x or y are < 0, return 0 to indicate transparent (cf BitBlt>bitPeekerFromForm: usage).
	Likewise if x>width or y>depth.
	Fail if the rcvr doesn't seem to be a Form, or x|y seem wrong"
	| rcvr bitmap depth ppW stride bitsSize word mask shift pixel |
	rcvr := self primitive: 'primitivePixelValueAt' parameters: #(SmallInteger SmallInteger) receiver: #Oop.
	
	"possible quick exit if x or y is -ve"
	(xVal < 0 or: [ yVal < 0 ] ) ifTrue:[^interpreterProxy integerObjectOf: 0].
	"check that rcvr is plausibly a Form or subclass"	
	rcvr := interpreterProxy stackValue: interpreterProxy methodArgumentCount.
	((interpreterProxy isPointers: rcvr) and: [(interpreterProxy slotSizeOf: rcvr) >= 4])
		ifFalse: [^interpreterProxy primitiveFail].

	"get the bits oop and width/height/depth"
	bitmap := interpreterProxy fetchPointer: FormBitsIndex ofObject: rcvr.
	(interpreterProxy isWordsOrBytes: bitmap) ifFalse: [^interpreterProxy primitiveFail].
	width := interpreterProxy fetchInteger: FormWidthIndex ofObject: rcvr.
	height := interpreterProxy fetchInteger: FormHeightIndex ofObject: rcvr.
	depth := interpreterProxy fetchInteger: FormDepthIndex ofObject: rcvr.
	"if width/height/depth are not integer, fail"
	interpreterProxy failed ifTrue:[^nil].

	"possible quick exit if x or y is >= extent of form. This also catches cases where the width/height are < 0"
	(xVal >= width or: [ yVal >= height ] ) ifTrue:[^interpreterProxy integerObjectOf: 0].

	"we don't handle LSB Forms yet"
	depth < 0 ifTrue:[^interpreterProxy primitiveFail].
	
	"OK so now we know we have a plausible Form, the width/height/depth/x/y are all reasonable and it's time to plunder the bitmap"
	ppW := 32//depth. "pixels in each word"
	stride := (width + (ppW  -1)) // ppW. "how many words per row of pixels"
	bitsSize := interpreterProxy byteSizeOf: bitmap.
	bitsSize >= (stride * height * 4 "bytes per word")
		ifFalse: [^interpreterProxy primitiveFail].
	word := interpreterProxy fetchLong32:(yVal * stride) + (xVal//ppW) ofObject: bitmap. "load the word that contains our target"
	mask := 16rFFFFFFFF >> (32 - depth). "make a mask to isolate the pixel within that word"
	shift := 32 - (((xVal bitAnd: ppW-1) + 1) * depth). "this is the tricky MSB part - we mask the xVal to find how far into the word we need, then add 1 for the pixel we're looking for, then * depth to get the bit shift"
	pixel := (word >> shift) bitAnd: mask. "shift, mask and dim the lights"
	^ pixel asPositiveIntegerObj "pop the incoming and push our answer"

]

{ #category : #primitives }
BitBltSimulation >> primitiveWarpBits [
	"Invoke the warpBits primitive. If the destination is the display, then copy it to the screen."
	| rcvr |
	<export: true>
	rcvr := interpreterProxy stackValue: interpreterProxy methodArgumentCount.
	(self loadWarpBltFrom: rcvr) 
		ifFalse:[^interpreterProxy primitiveFail].
	self warpBits.
	interpreterProxy failed ifTrue:[^nil].
	self showDisplayBits.
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy pop: interpreterProxy methodArgumentCount.
]

{ #category : #'surface support' }
BitBltSimulation >> query: handle Sur: widthPtr fa: heightPtr ce: depthPtr Fn: endianPtr [
	"Query the dimension of an OS surface.
	This method is provided so that in case the inst vars of the
	source form are broken, *actual* values of the OS surface
	can be obtained. This might, for instance, happen if the user
	resizes the main window.
	This is a simulation of the querySurfaceFn function call; simulate as a failure."
	<doNotGenerate>
	^false
]

{ #category : #setup }
BitBltSimulation >> reloadDestAndSourceForms [
	"A GC has occurred.  The destForm must be updated.  But where to derive it from?
	  For copyBits and warpBits it is derived from the receiver.  But for a BalloonEnginePlugin
	  it should be obtained from (interpreterProxy fetchPointer: BEBitBltIndex ofObject: engine).
	  For the moment implement something that works for these two cases."
	<inline: false>
	| receiver |
	receiver := interpreterProxy stackValue: interpreterProxy methodArgumentCount.
	bitBltIsReceiver ifFalse: [receiver := interpreterProxy fetchPointer: BEBitBltIndex ofObject: receiver].
	destForm := interpreterProxy fetchPointer: BBDestFormIndex ofObject: receiver.
	sourceForm := interpreterProxy fetchPointer: BBSourceFormIndex ofObject: receiver
]

{ #category : #'combination rules' }
BitBltSimulation >> rgbAdd: sourceWord with: destinationWord [
	<inline: false>
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	<var: #carryOverflowMask type: 'unsigned int'>
	<var: #componentMask type: 'unsigned int'>
	| componentMask carryOverflowMask |
	destDepth < 16 ifTrue:
		["Add each pixel separately"
		componentMask := 1<<destDepth-1.
		carryOverflowMask := 16rFFFFFFFF//componentMask<<(destDepth-1).
		^ self partitionedAdd: sourceWord to: destinationWord
						nBits: destDepth componentMask: componentMask carryOverflowMask: carryOverflowMask].
	destDepth = 16 ifTrue:
		["Add RGB components of each pixel separately"
		componentMask := 16r1F.
		carryOverflowMask := 16r42104210.
		^ (self partitionedAdd: (sourceWord bitAnd: 16r7FFF7FFF) to: (destinationWord bitAnd: 16r7FFF7FFF) "make sure that the unused bit is at 0"
						nBits: 5 componentMask: componentMask carryOverflowMask: carryOverflowMask)]
	ifFalse:
		["Add RGBA components of the pixel separately"
		componentMask := 16rFF.
		carryOverflowMask := 16r80808080.
		^ self partitionedAdd: sourceWord to: destinationWord
						nBits: 8 componentMask: componentMask carryOverflowMask: carryOverflowMask]
]

{ #category : #'combination rules' }
BitBltSimulation >> rgbComponentAlpha16 [
	"This version assumes 
		combinationRule = 41
		sourcePixSize = 32
		destPixSize = 16
		sourceForm ~= destForm.
	"
	<inline: false>  "This particular method should be optimized in itself"
	<var: #sourceWord type: #'unsigned int'>
	<var: #destWord type: #'unsigned int'>
	<var: #dstMask type: #'unsigned int'>
	
	| srcIndex dstIndex sourceWord srcAlpha destWord deltaX deltaY 
	srcY dstY dstMask srcShift ditherBase ditherIndex ditherThreshold |

	deltaY := bbH + 1. "So we can pre-decrement"
	srcY := sy.
	dstY := dy.
	srcShift := (dx bitAnd: 1) * 16.
	destMSB ifTrue:[srcShift := 16 - srcShift].
	mask1 := 16rFFFF << (16 - srcShift).
	"This is the outer loop"
	[(deltaY := deltaY - 1) ~= 0] whileTrue:[
		srcIndex := sourceBits + (srcY * sourcePitch) + (sx * 4).
		dstIndex := destBits + (dstY * destPitch) + (dx // 2 * 4).
		ditherBase := (dstY bitAnd: 3) * 4.
		ditherIndex := (sx bitAnd: 3) - 1. "For pre-increment"
		deltaX := bbW + 1. "So we can pre-decrement"
		dstMask := mask1.
		dstMask = 16rFFFF ifTrue:[srcShift := 16] ifFalse:[srcShift := 0].

		"This is the inner loop"
		[(deltaX := deltaX - 1) ~= 0] whileTrue:[
			ditherThreshold := ditherMatrix4x4 at: ditherBase + (ditherIndex := ditherIndex + 1 bitAnd: 3).
			sourceWord := self srcLongAt: srcIndex.
			srcAlpha := sourceWord bitAnd: 16rFFFFFF.
				srcAlpha = 0 ifFalse:[ "0 < srcAlpha"
					"If we have to mix colors then just copy a single word"
					destWord := self dstLongAt: dstIndex.
					destWord := destWord bitAnd: dstMask bitInvert32.
					destWord := destWord >> srcShift.
					"Expand from 16 to 32 bit by adding zero bits"
					destWord := (((destWord bitAnd: 16r7C00) bitShift: 9) bitOr:
									((destWord bitAnd: 16r3E0) bitShift: 6)) bitOr:
								(((destWord bitAnd: 16r1F) bitShift: 3) bitOr:
									16rFF000000).
					"Mix colors"
					sourceWord := self rgbComponentAlpha32: sourceWord with: destWord.
					"And dither"
					sourceWord := self dither32To16: sourceWord threshold: ditherThreshold.
					sourceWord = 0 
						ifTrue:[sourceWord := 1 << srcShift]
						ifFalse:[sourceWord := sourceWord << srcShift].
					"Store back"
					self dstLongAt: dstIndex put: sourceWord mask: dstMask.
				].
			srcIndex := srcIndex + 4.
			destMSB
				ifTrue:[srcShift = 0 ifTrue:[dstIndex := dstIndex + 4]]
				ifFalse:[srcShift = 0 ifFalse:[dstIndex := dstIndex + 4]].
			srcShift := srcShift bitXor: 16. "Toggle between 0 and 16"
			dstMask := dstMask bitInvert32. "Mask other half word"
		].
		srcY := srcY + 1.
		dstY := dstY + 1.
	].

]

{ #category : #'combination rules' }
BitBltSimulation >> rgbComponentAlpha32 [
	"This version assumes 
		combinationRule = 41
		sourcePixSize = destPixSize = 32
		sourceForm ~= destForm.
	Note: The inner loop has been optimized for dealing
		with the special case of aR = aG = aB = 0 
	"
	| srcIndex dstIndex sourceWord srcAlpha destWord deltaX deltaY srcY dstY |

	<inline: false> "This particular method should be optimized in itself"

	"Give the compile a couple of hints"
	<var: #deltaX type: 'register sqInt'>
	<var: #sourceWord type: #'unsigned int'>
	<var: #destWord type: #'unsigned int'>

	"The following should be declared as pointers so the compiler will
	notice that they're used for accessing memory locations 
	(good to know on an Intel architecture) but then the increments
	would be different between ST code and C code so must hope the
	compiler notices what happens (MS Visual C does)"
	<var: #srcIndex type: 'register sqIntptr_t'>
	<var: #dstIndex type: 'register sqIntptr_t'>
	
	deltaY := bbH + 1. "So we can pre-decrement"
	srcY := sy.
	dstY := dy.

	"This is the outer loop"
	[(deltaY := deltaY - 1) ~= 0] whileTrue:[
		srcIndex := sourceBits + (srcY * sourcePitch) + (sx * 4).
		dstIndex := destBits + (dstY * destPitch) + (dx * 4).
		deltaX := bbW + 1. "So we can pre-decrement"

		"This is the inner loop"
		[(deltaX := deltaX - 1) ~= 0] whileTrue:[
			sourceWord := self srcLongAt: srcIndex.
			srcAlpha := sourceWord bitAnd:16rFFFFFF.
				srcAlpha = 0 ifTrue:[
					srcIndex := srcIndex + 4.
					dstIndex := dstIndex + 4.
					"Now skip as many words as possible,"
					[(deltaX := deltaX - 1) ~= 0 and:[
						((sourceWord := self srcLongAt: srcIndex) bitAnd:16rFFFFFF) = 0]]
						whileTrue:[
							srcIndex := srcIndex + 4.
							dstIndex := dstIndex + 4.
						].
					"Adjust deltaX"
					deltaX := deltaX + 1.
				] ifFalse:[ "0 < srcAlpha"
					"If we have to mix colors then just copy a single word"
					destWord := self dstLongAt: dstIndex.
					destWord := self rgbComponentAlpha32: sourceWord with: destWord.
					self dstLongAt: dstIndex put: destWord.
					srcIndex := srcIndex + 4.
					dstIndex := dstIndex + 4.
				].
		].
		srcY := srcY + 1.
		dstY := dstY + 1.
	].
]

{ #category : #'combination rules' }
BitBltSimulation >> rgbComponentAlpha32: sourceWord with: destinationWord [
	"
	componentAlphaModeColor is the color,
	sourceWord contains an alpha value for each component of RGB
	each of which is encoded as0 meaning 0.0 and 255 meaning 1.0 .
	the rule is...
	
	color = componentAlphaModeColor.
	colorAlpha = componentAlphaModeAlpha.
	mask = sourceWord.
	dst.A =  colorAlpha + (1 - colorAlpha) * dst.A
      dst.R = color.R * mask.R * colorAlpha + (1 - (mask.R * colorAlpha)) * dst.R
      dst.G = color.G * mask.G * colorAlpha + (1 - (mask.G* colorAlpha)) * dst.G
      dst.B = color.B * mask.B * colorAlpha + (1 - (mask.B* colorAlpha)) * dst.B
	"
	<inline: false> "Do NOT inline this into optimized loops"
	| alpha dstMask srcColor srcAlpha b g r a aB aG aR aA answer s d |
		
	alpha := sourceWord.
	alpha = 0 ifTrue:[^destinationWord].
	srcColor := componentAlphaModeColor.
	srcAlpha := componentAlphaModeAlpha bitAnd: 255.
	
	aB := alpha bitAnd: 255.
	alpha := alpha >> 8.
	aG := alpha bitAnd: 255.
	alpha := alpha >> 8.
	aR := alpha bitAnd: 255.
	alpha := alpha >> 8.
	aA := alpha bitAnd: 255.	

	srcAlpha = 255 
		ifFalse:[
			aA := aA * srcAlpha >> 8.
			aR := aR * srcAlpha >> 8.
			aG := aG * srcAlpha >> 8.
			aB := aB * srcAlpha >> 8].
			
	dstMask := destinationWord.
	d := dstMask bitAnd: 255.
	s := srcColor bitAnd: 255.
	ungammaLookupTable == nil
		ifFalse:[
			d := ungammaLookupTable at: d.
			s := ungammaLookupTable at: s.].
	b := (d * (255 - aB) >> 8) + (s * aB >> 8).
	b > 255 ifTrue:[b := 255].
	gammaLookupTable == nil
		ifFalse:[	
			b := gammaLookupTable at: b].
	dstMask := dstMask >> 8.
	srcColor := srcColor >> 8.
	d := dstMask bitAnd: 255.
	s := srcColor bitAnd: 255.
	ungammaLookupTable == nil
		ifFalse:[
			d := ungammaLookupTable at: d.
			s := ungammaLookupTable at: s.].
	g := (d * (255 - aG) >> 8) + (s * aG >> 8).
	g > 255 ifTrue:[g := 255].
	gammaLookupTable == nil
		ifFalse:[	
			g := gammaLookupTable at: g].
	dstMask := dstMask >> 8.
	srcColor := srcColor >> 8.
	d := dstMask bitAnd: 255.
	s := srcColor bitAnd: 255.
	ungammaLookupTable == nil
		ifFalse:[
			d := ungammaLookupTable at: d.
			s := ungammaLookupTable at: s.].
	r := (d * (255 - aR) >> 8) + (s * aR >> 8).
	r > 255 ifTrue:[r := 255].
	gammaLookupTable == nil
		ifFalse:[	
			r := gammaLookupTable at: r].
	dstMask := dstMask >> 8.
	srcColor := srcColor >> 8.
	a := ((dstMask bitAnd: 255) * (255 - aA) >> 8) + aA. "no need to gamma correct alpha value ?"
	a > 255 ifTrue:[a := 255].
	answer := (((((a << 8) + r) << 8) + g) << 8) + b.
	^answer	
]

{ #category : #'combination rules' }
BitBltSimulation >> rgbComponentAlpha8 [
	"This version assumes 
		combinationRule = 41
		sourcePixSize = 32
		destPixSize = 8
		sourceForm ~= destForm.
	Note: This is not real blending since we don't have the source colors available.
	"
	
	| srcIndex dstIndex sourceWord srcAlpha destWord deltaX deltaY 
	srcY dstY dstMask srcShift adjust mappingTable mapperFlags |
	
	<inline: false>  "This particular method should be optimized in itself"
	<var: #mappingTable declareC:'unsigned int *mappingTable'>
	<var: #sourceWord type: #'unsigned int'>
	<var: #destWord type: #'unsigned int'>
	<var: #dstMask type: #'unsigned int'>
	
	mappingTable := self default8To32Table.
	mapperFlags := cmFlags bitAnd: ColorMapNewStyle bitInvert32.
	deltaY := bbH + 1. "So we can pre-decrement"
	srcY := sy.
	dstY := dy.
	mask1 := ((dx bitAnd: 3) * 8).
	destMSB ifTrue:[mask1 := 24 - mask1].
	mask2 := AllOnes bitXor:(16rFF << mask1).
	(dx bitAnd: 1) = 0 
		ifTrue:[adjust := 0]
		ifFalse:[adjust := 16r1F1F1F1F].
	(dy bitAnd: 1) = 0
		ifTrue:[adjust := adjust bitXor: 16r1F1F1F1F].
	"This is the outer loop"
	[(deltaY := deltaY - 1) ~= 0] whileTrue:[
		adjust := adjust bitXor: 16r1F1F1F1F.
		srcIndex := sourceBits + (srcY * sourcePitch) + (sx * 4).
		dstIndex := destBits + (dstY * destPitch) + (dx // 4 * 4).
		deltaX := bbW + 1. "So we can pre-decrement"
		srcShift := mask1.
		dstMask := mask2.

		"This is the inner loop"
		[(deltaX := deltaX - 1) ~= 0] whileTrue:[
			sourceWord := ((self srcLongAt: srcIndex) bitAnd: (adjust bitInvert32)) + adjust.
			srcAlpha := sourceWord bitAnd: 16rFFFFFF.
			"set srcAlpha to the average of the 3 separate aR,Ag,AB values"
			srcAlpha := ((srcAlpha >> 16) + (srcAlpha >> 8 bitAnd: 16rFF) + (srcAlpha bitAnd: 16rFF)) // 3.
			srcAlpha > 31 ifTrue:["Everything below 31 is transparent"
				srcAlpha > 224 
					ifTrue: ["treat everything above 224 as opaque"
						sourceWord := 16rFFFFFFFF].
				destWord := self dstLongAt: dstIndex.
				destWord := destWord bitAnd: dstMask bitInvert32.
				destWord := destWord >> srcShift.
				destWord := mappingTable at: destWord.
				sourceWord := self rgbComponentAlpha32: sourceWord with: destWord.
				sourceWord := self mapPixel: sourceWord flags: mapperFlags.
				sourceWord := sourceWord << srcShift.
				"Store back"
				self dstLongAt: dstIndex put: sourceWord mask: dstMask.
			].
			srcIndex := srcIndex + 4.
			destMSB ifTrue:[
				srcShift = 0 
					ifTrue:[dstIndex := dstIndex + 4.
							srcShift := 24.
							dstMask := 16r00FFFFFF]
					ifFalse:[srcShift := srcShift - 8.
							dstMask := (dstMask >> 8) bitOr: 16rFF000000].
			] ifFalse:[
				srcShift = 32
					ifTrue:[dstIndex := dstIndex + 4.
							srcShift := 0.
							dstMask := 16rFFFFFF00]
					ifFalse:[srcShift := srcShift + 8.
							dstMask := dstMask << 8 bitOr: 255].
			].
			adjust := adjust bitXor: 16r1F1F1F1F.
		].
		srcY := srcY + 1.
		dstY := dstY + 1.
	].

]

{ #category : #'combination rules' }
BitBltSimulation >> rgbComponentAlpha: sourceWord with: destinationWord [
	"
	componentAlphaModeColor is the color,
	sourceWord contains an alpha value for each component of RGB
	each of which is encoded as0 meaning 0.0 and 255 meaning 1.0 .
	the rule is...
	
	color = componentAlphaModeColor.
	colorAlpha = componentAlphaModeAlpha.
	mask = sourceWord.
	dst.A =  colorAlpha + (1 - colorAlpha) * dst.A
      dst.R = color.R * mask.R * colorAlpha + (1 - (mask.R * colorAlpha)) * dst.R
      dst.G = color.G * mask.G * colorAlpha + (1 - (mask.G* colorAlpha)) * dst.G
      dst.B = color.B * mask.B * colorAlpha + (1 - (mask.B* colorAlpha)) * dst.B
	"
	<inline: false> "Do NOT inline this into optimized loops"
	| alpha |
		
	alpha := sourceWord.
	alpha = 0 ifTrue:[^destinationWord].
	^self partitionedRgbComponentAlpha: sourceWord dest: destinationWord nBits: destDepth nPartitions: destPPW.
]

{ #category : #'combination rules' }
BitBltSimulation >> rgbDiff: sourceWord with: destinationWord [
	"Subract the pixels in the source and destination, color by color,
	and return the sum of the absolute value of all the differences.
	For non-rgb, return the number of differing pixels."
	| pixMask destShifted sourceShifted destPixVal bitsPerColor rgbMask sourcePixVal diff maskShifted |
	<inline: false>
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	<var: #sourceShifted type: 'unsigned int'>
	<var: #destShifted type: 'unsigned int'>
	<var: #maskShifted type: 'unsigned int'>
	<var: #pixMask type: 'unsigned int'>
	<var: #rgbMask type: 'unsigned int'>
	pixMask := maskTable at: destDepth.
	destDepth = 16
		ifTrue: [bitsPerColor := 5.  rgbMask := 16r1F]
		ifFalse: [bitsPerColor := 8.  rgbMask := 16rFF].
	maskShifted := destMask.
	destShifted := destinationWord.
	sourceShifted := sourceWord.
	1 to: destPPW do:
		[:i |
		(maskShifted bitAnd: pixMask) > 0 ifTrue:
			["Only tally pixels within the destination rectangle"
			destPixVal := destShifted bitAnd: pixMask.
			sourcePixVal := sourceShifted bitAnd: pixMask.
			destDepth < 16
				ifTrue: [sourcePixVal = destPixVal
							ifTrue: [diff := 0]
							ifFalse: [diff := 1]]
				ifFalse: [diff := (self partitionedSub: sourcePixVal from: destPixVal
								nBits: bitsPerColor nPartitions: 3).
						diff := (diff bitAnd: rgbMask)
							+ (diff>>bitsPerColor bitAnd: rgbMask)
							+ ((diff>>bitsPerColor)>>bitsPerColor bitAnd: rgbMask)].
			bitCount := bitCount + diff].
		maskShifted := maskShifted >> destDepth.
		sourceShifted := sourceShifted >> destDepth.
		destShifted := destShifted >> destDepth].
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
	<inline: true>
	(d := nBitsOut - nBitsIn) > 0
		ifTrue:
			["Expand to more bits by zero-fill"
			mask := (1 << nBitsIn) - 1.  "Transfer mask"
			srcPix := sourcePixel << d.
			mask := mask << d.
			destPix := srcPix bitAnd: mask.
			mask := mask << nBitsOut.
			srcPix := srcPix << d.
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
			d := nBitsIn - nBitsOut.
			mask := (1 << nBitsOut) - 1.  "Transfer mask"
			srcPix := sourcePixel >> d.
			destPix := srcPix bitAnd: mask.
			mask := mask << nBitsOut.
			srcPix := srcPix >> d.
			destPix := destPix + (srcPix bitAnd: mask)
					+ (srcPix >> d bitAnd: mask << nBitsOut).
			destPix = 0 ifTrue: [^ 1].  "Dont fall into transparent by truncation"
			^ destPix]
]

{ #category : #'color mapping' }
BitBltSimulation >> rgbMapPixel: sourcePixel flags: mapperFlags [
	"Perform the RGBA conversion for the given source pixel"
	| val |
	<inline: true>
	val := 			((sourcePixel bitAnd: (cmMaskTable at: 0)) bitShift: (cmShiftTable at: 0) signedIntFromLong).
	val := val bitOr: ((sourcePixel bitAnd: (cmMaskTable at: 1)) bitShift: (cmShiftTable at: 1) signedIntFromLong).
	val := val bitOr: ((sourcePixel bitAnd: (cmMaskTable at: 2)) bitShift: (cmShiftTable at: 2) signedIntFromLong).
		  ^val bitOr: ((sourcePixel bitAnd: (cmMaskTable at: 3)) bitShift: (cmShiftTable at: 3) signedIntFromLong).

]

{ #category : #'combination rules' }
BitBltSimulation >> rgbMax: sourceWord with: destinationWord [
	<inline: false>
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
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
		["Max RGBA components of the pixel separately"
		^ self partitionedMax: sourceWord with: destinationWord
						nBits: 8 nPartitions: 4]
]

{ #category : #'combination rules' }
BitBltSimulation >> rgbMin: sourceWord with: destinationWord [
	<inline: false>
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
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
		["Min RGBA components of the pixel separately"
		^ self partitionedMin: sourceWord with: destinationWord
						nBits: 8 nPartitions: 4]
]

{ #category : #'combination rules' }
BitBltSimulation >> rgbMinInvert: wordToInvert with: destinationWord [
	| sourceWord |
	<inline: false>
	<returnTypeC: 'unsigned int'>
	<var: #wordToInvert type: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	sourceWord := wordToInvert bitInvert32.
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
		["Min RGBA components of the pixel separately"
		^ self partitionedMin: sourceWord with: destinationWord
						nBits: 8 nPartitions: 4]
]

{ #category : #'combination rules' }
BitBltSimulation >> rgbMul: sourceWord with: destinationWord [
	<inline: false>
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
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
		["Mul RGBA components of the pixel separately"
		^ self partitionedMul: sourceWord with: destinationWord
						nBits: 8 nPartitions: 4]

"	| scanner |
	Display repaintMorphicDisplay.
	scanner := DisplayScanner quickPrintOn: Display.
	MessageTally time: [0 to: 760 by: 4 do:  [:y |scanner drawString: 'qwrepoiuasfd=)(/&()=#!lkjzxv.,mn124+09857907QROIYTOAFDJZXNBNB,M-.,Mqwrepoiuasfd=)(/&()=#!lkjzxv.,mn124+09857907QROIYTOAFDJZXNBNB,M-.,M1234124356785678' at: 0@y]]. "
]

{ #category : #'combination rules' }
BitBltSimulation >> rgbSub: sourceWord with: destinationWord [
	<inline: false>
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
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
		["Sub RGBA components of the pixel separately"
		^ self partitionedSub: sourceWord from: destinationWord
						nBits: 8 nPartitions: 4]
]

{ #category : #'interpreter interface' }
BitBltSimulation >> setupColorMasks [
	"WARNING: For WarpBlt w/ smoothing the source depth is wrong here!"
	| bits targetBits |
	bits := targetBits := 0.
	sourceDepth <= 8 ifTrue:[^nil].
	sourceDepth = 16 ifTrue:[bits := 5].
	sourceDepth = 32 ifTrue:[bits := 8].

	cmBitsPerColor = 0
		ifTrue:["Convert to destDepth"
				destDepth <= 8 ifTrue:[^nil].
				destDepth = 16 ifTrue:[targetBits := 5].
				destDepth = 32 ifTrue:[targetBits := 8]]
		ifFalse:[targetBits := cmBitsPerColor].

	self setupColorMasksFrom: bits to: targetBits
]

{ #category : #'interpreter interface' }
BitBltSimulation >> setupColorMasksFrom: srcBits to: targetBits [
	"Setup color masks for converting an incoming RGB pixel value from srcBits to targetBits."
	| mask shifts masks deltaBits |
	<var: #shifts declareC:'static int shifts[4] = {0, 0, 0, 0}'>
	<var: #masks declareC:'static unsigned int masks[4] = {0, 0, 0, 0}'>
	self cCode:'' inSmalltalk:[
		shifts := CArrayAccessor on: (IntegerArray new: 4).
		masks := CArrayAccessor on: (WordArray new: 4).
	].
	deltaBits := targetBits - srcBits.
	deltaBits = 0 ifTrue:[^0].
	deltaBits <= 0
		ifTrue:[	mask := 1 << targetBits - 1.
				"Mask for extracting a color part of the source"
				masks at: RedIndex put: mask << (srcBits*2 - deltaBits).
				masks at: GreenIndex put: mask << (srcBits - deltaBits).
				masks at: BlueIndex put: mask << (0 - deltaBits).
				masks at: AlphaIndex put: 0]
		ifFalse:[	mask := 1 << srcBits - 1.
				"Mask for extracting a color part of the source"
				masks at: RedIndex put: mask << (srcBits*2).
				masks at: GreenIndex put: mask << srcBits.
				masks at: BlueIndex put: mask].

	"Shifts for adjusting each value in a cm RGB value"
	shifts at: RedIndex put: deltaBits * 3.
	shifts at: GreenIndex put: deltaBits * 2.
	shifts at: BlueIndex put: deltaBits.
	shifts at: AlphaIndex put: 0.

	cmShiftTable := shifts.
	cmMaskTable := masks.
	cmFlags := cmFlags bitOr: (ColorMapPresent bitOr: ColorMapFixedPart).

]

{ #category : #'interpreter interface' }
BitBltSimulation >> showDisplayBits [
	self ensureDestAndSourceFormsAreValid.
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
	<inline: true>
	pixPerM1 := destPPW - 1.  "A mask, assuming power of two"
	sxLowBits := sx bitAnd: pixPerM1.
	dxLowBits := dx bitAnd: pixPerM1.
	"check if need to preload buffer
	(i.e., two words of source needed for first word of destination)"
	hDir > 0 ifTrue:
		["n Bits stored in 1st word of dest"
		dWid := bbW min: destPPW - dxLowBits.
		preload := (sxLowBits + dWid) > pixPerM1]
	ifFalse:
		[dWid := bbW min: dxLowBits + 1.
		preload := (sxLowBits - dWid + 1) < 0].

	"calculate right-shift skew from source to dest"
	sourceMSB
		ifTrue:[skew := (sxLowBits - dxLowBits) * destDepth] 
		ifFalse:[skew := (dxLowBits - sxLowBits) * destDepth].  " -32..32 "
	preload ifTrue: 
		[skew < 0
			ifTrue: [skew := skew+32]
			ifFalse: [skew := skew-32]].

	"Calc byte addr and delta from longWord info"
	sourceIndex := sourceBits + (sy * sourcePitch) + ((sx // (32//sourceDepth)) *4).
	"calculate increments from end of 1 line to start of next"
	sourceDelta := (sourcePitch * vDir) - (4 * (nWords * hDir)).

	preload ifTrue:
		["Compensate for extra source word fetched"
		sourceDelta := sourceDelta - (4*hDir)].
]

{ #category : #'combination rules' }
BitBltSimulation >> sourceWord: sourceWord with: destinationWord [
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	^sourceWord
]

{ #category : #'memory access' }
BitBltSimulation >> srcLongAt: idx [

	^self long32At: idx
]

{ #category : #'combination rules' }
BitBltSimulation >> subWord: sourceWord with: destinationWord [
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	^sourceWord - destinationWord
]

{ #category : #'combination rules' }
BitBltSimulation >> tallyIntoMap: sourceWord with: destinationWord [
	"Tally pixels into the color map.  Those tallied are exactly those
	in the destination rectangle.  Note that the source should be 
	specified == destination, in order for the proper color map checks 
	to be performed at setup."
	| mapIndex pixMask destShifted maskShifted pixVal |
	<inline: false>
	<returnTypeC: 'unsigned int'>
	<var: #sourceWord type: 'unsigned int'>
	<var: #destinationWord type: 'unsigned int'>
	<var: #pixMask type: 'unsigned int'>
	<var: #destShifted type: 'unsigned int'>
	<var: #maskShifted type: 'unsigned int'>
	(cmFlags bitAnd: (ColorMapPresent bitOr: ColorMapIndexedPart)) = 
		(ColorMapPresent bitOr: ColorMapIndexedPart)
			ifFalse: [^ destinationWord "no op"].
	pixMask := maskTable at: destDepth.
	destShifted := destinationWord.
	maskShifted := destMask.
	1 to: destPPW do:
		[:i |
		(maskShifted bitAnd: pixMask) = 0 ifFalse:
			["Only tally pixels within the destination rectangle"
			pixVal := destShifted bitAnd: pixMask.
			destDepth < 16
				ifTrue: [mapIndex := pixVal]
				ifFalse: [destDepth = 16
					ifTrue: [mapIndex := self rgbMap: pixVal from: 5 to: cmBitsPerColor]
					ifFalse: [mapIndex := self rgbMap: pixVal from: 8 to: cmBitsPerColor]].
			self tallyMapAt: mapIndex put: (self tallyMapAt: mapIndex) + 1].
		maskShifted := maskShifted >> destDepth.
		destShifted := destShifted >> destDepth].
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
	<inline: true>
	"We need a source."
	noSource ifTrue:[^false].
	"We handle only combinationRule 34 and combinationRule 41"	
	(combinationRule = 34 or:[combinationRule = 41]) ifFalse:[^false].
	"We handle only sourceDepth 32"
	(sourceDepth = 32) ifFalse:[^false].
	"We don't handle overlaps"
	(sourceForm = destForm) ifTrue:[^false].
	
	(combinationRule = 41)
		ifTrue:[
			destDepth = 32 
				ifTrue:[
					self rgbComponentAlpha32.
					affectedL := dx.
					affectedR := dx + bbW.
					affectedT := dy.
					affectedB := dy + bbH.
					^true].
			destDepth = 16 
				ifTrue:[
					self rgbComponentAlpha16.
					affectedL := dx.
					affectedR := dx + bbW.
					affectedT := dy.
					affectedB := dy + bbH.
					^true].
			destDepth = 8 
				ifTrue:[
					self rgbComponentAlpha8.
					affectedL := dx.
					affectedR := dx + bbW.
					affectedT := dy.
					affectedB := dy + bbH.
					^true].
			^false].
	
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
	affectedL := dx.
	affectedR := dx + bbW.
	affectedT := dy.
	affectedB := dy + bbH.
	^true
]

{ #category : #'surface support' }
BitBltSimulation >> unlock: handle Sur: x fa: y ce: w Fn: h [
	"Simulate the unlockSurfaceFn function call."
	<doNotGenerate>
	^self
]

{ #category : #'surface support' }
BitBltSimulation >> unlockSurfaces [
	"Unlock the bits of any OS surfaces."
	"See the comment in lockSurfaces. Similar rules apply. That is, the area provided in ioUnlockSurface
	 can be used to determine the dirty region after drawing. If a source is unlocked, then the area will
	 be (0,0,0,0) to indicate that no portion is dirty.  Note that if a GC happens during unlockSourceFn
	 (if it is effectively a callback) no matter.  No bits are touched after unlock."
	| sourceHandle destHandle destLocked |
	hasSurfaceLock ifFalse: [^self].
	unlockSurfaceFn = 0 ifTrue:
		[self loadSurfacePlugin ifFalse:
			[^self]].
	self ensureDestAndSourceFormsAreValid.
	destLocked := false.
	destHandle := interpreterProxy fetchPointer: FormBitsIndex ofObject: destForm.
	(interpreterProxy isIntegerObject: destHandle) ifTrue: "The destBits are always assumed to be dirty"
		[self unlock: (interpreterProxy integerValueOf: destHandle)
			Sur: affectedL
			fa: affectedT
			ce: affectedR - affectedL
			Fn: affectedB - affectedT.
		 destBits := destPitch := 0.
		 destLocked := true].
	noSource ifFalse:
		[self ensureDestAndSourceFormsAreValid.
		 sourceHandle := interpreterProxy fetchPointer: FormBitsIndex ofObject: sourceForm.
		 (interpreterProxy isIntegerObject: sourceHandle) ifTrue:
			["Only unlock sourceHandle if different from destHandle"
			 (destLocked and: [sourceHandle = destHandle]) ifFalse:
				[self unlock: (interpreterProxy integerValueOf: sourceHandle) Sur: 0 fa: 0 ce: 0 Fn: 0].
			sourceBits := sourcePitch := 0]].
	hasSurfaceLock := false.
	self cCode: [] inSmalltalk:
		[interpreterProxy displayObject = destForm ifTrue:
			[interpreterProxy getDeferDisplayUpdates ifFalse:
				[interpreterProxy fullDisplayUpdate]]]
]

{ #category : #setup }
BitBltSimulation >> warpBits [
	| ns |
	<inline: true>
	ns := noSource.  noSource := true.
		self clipRange.  "noSource suppresses sourceRect clipping"
		noSource := ns.
	(noSource or: [bbW <= 0 or: [bbH <= 0]]) ifTrue:
		["zero width or height; noop"
		affectedL := affectedR := affectedT := affectedB := 0.
		^ nil].

	self lockSurfaces ifFalse:[^interpreterProxy primitiveFail].
	self destMaskAndPointerInit.
	self warpLoop.
 
	hDir > 0
		ifTrue: [affectedL := dx.
				affectedR := dx + bbW]
		ifFalse: [affectedL := dx - bbW + 1.
				affectedR := dx + 1].
	vDir > 0
		ifTrue: [affectedT := dy.
				affectedB := dy + bbH]
		ifFalse: [affectedT := dy - bbH + 1.
				affectedB := dy + 1].
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
	<inline: false>	
	<var: #mergeFnwith declareC: 'unsigned int (*mergeFnwith)(unsigned int, unsigned int)'>
	<var: #skewWord type: #'unsigned int'>
	<var: #halftoneWord type: #'unsigned int'>
	<var: #mergeWord type: #'unsigned int'>
	<var: #destWord type: #'unsigned int'>
	mergeFnwith := self cCoerce: (opTable at: combinationRule+1) to: 'unsigned int (*)(unsigned int, unsigned int)'.
	mergeFnwith.  "null ref for compiler"

	(interpreterProxy slotSizeOf: bitBltOop) >= (BBWarpBase+12)
		ifFalse: [^ interpreterProxy primitiveFail].
	nSteps := height-1.  nSteps <= 0 ifTrue: [nSteps := 1].

	pAx := self fetchIntOrFloat: BBWarpBase ofObject: bitBltOop.
	words := self fetchIntOrFloat: BBWarpBase+3 ofObject: bitBltOop.
	deltaP12x := self deltaFrom: pAx to: words nSteps: nSteps.
	deltaP12x < 0 ifTrue: [pAx := words - (nSteps*deltaP12x)].

	pAy := self fetchIntOrFloat: BBWarpBase+1 ofObject: bitBltOop.
	words := self fetchIntOrFloat: BBWarpBase+4 ofObject: bitBltOop.
	deltaP12y := self deltaFrom: pAy to: words nSteps: nSteps.
	deltaP12y < 0 ifTrue: [pAy := words - (nSteps*deltaP12y)].

	pBx := self fetchIntOrFloat: BBWarpBase+9 ofObject: bitBltOop.
	words := self fetchIntOrFloat: BBWarpBase+6 ofObject: bitBltOop.
	deltaP43x := self deltaFrom: pBx to: words nSteps: nSteps.
	deltaP43x < 0 ifTrue: [pBx := words - (nSteps*deltaP43x)].

	pBy := self fetchIntOrFloat: BBWarpBase+10 ofObject: bitBltOop.
	words := self fetchIntOrFloat: BBWarpBase+7 ofObject: bitBltOop.
	deltaP43y := self deltaFrom: pBy to: words nSteps: nSteps.
	deltaP43y < 0 ifTrue: [pBy := words - (nSteps*deltaP43y)].

	interpreterProxy failed ifTrue: [^ false].  "ie if non-integers above"
	interpreterProxy methodArgumentCount = 2
		ifTrue: [smoothingCount := interpreterProxy stackIntegerValue: 1.
				sourceMapOop := interpreterProxy stackValue: 0.
				sourceMapOop = interpreterProxy nilObject
				ifTrue: [sourceDepth < 16 ifTrue:
					["color map is required to smooth non-RGB dest"
					^ interpreterProxy primitiveFail]]
				ifFalse: [(interpreterProxy slotSizeOf: sourceMapOop)
							< (1 << sourceDepth) ifTrue:
					["sourceMap must be long enough for sourceDepth"
					^ interpreterProxy primitiveFail].
					sourceMapOop := self oopForPointer: (interpreterProxy firstIndexableField: sourceMapOop)]]
		ifFalse: [smoothingCount := 1.
				sourceMapOop := interpreterProxy nilObject].
	nSteps := width-1.  nSteps <= 0 ifTrue: [nSteps := 1].
	startBits := destPPW - (dx bitAnd: destPPW-1).
	endBits := ((dx + bbW - 1) bitAnd: destPPW-1) + 1.
 	bbW < startBits ifTrue:[startBits := bbW].

	destY < clipY ifTrue:[
		"Advance increments if there was clipping in y"
		pAx := pAx + (clipY - destY * deltaP12x).
		pAy := pAy + (clipY - destY * deltaP12y).
		pBx := pBx + (clipY - destY * deltaP43x).
		pBy := pBy + (clipY - destY * deltaP43y)].

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
	mapperFlags := cmFlags bitAnd: ColorMapNewStyle bitInvert32.

	destMSB
		ifTrue:[	dstShiftInc := 0 - destDepth.
				dstShiftLeft := 32 - destDepth]
		ifFalse:[	dstShiftInc := destDepth.
				dstShiftLeft := 0].
	1 to: bbH do:
		[ :i | "here is the vertical loop..."
		xDelta := self deltaFrom: pAx to: pBx nSteps: nSteps.
 		xDelta >= 0 ifTrue: [sx := pAx] ifFalse: [sx := pBx - (nSteps*xDelta)].
		yDelta := self deltaFrom: pAy to: pBy nSteps: nSteps.
 		yDelta >= 0 ifTrue: [sy := pAy] ifFalse: [sy := pBy - (nSteps*yDelta)].

		destMSB
			ifTrue:[dstBitShift := 32 - ((dx bitAnd: destPPW - 1) + 1 * destDepth)]
			ifFalse:[dstBitShift := (dx bitAnd: destPPW - 1) * destDepth].

		(destX < clipX) ifTrue:[
			"Advance increments if there was clipping in x"
			sx := sx + (clipX - destX * xDelta).
			sy := sy + (clipX - destX * yDelta).
		].

		noHalftone
			ifTrue: [halftoneWord := AllOnes]
			ifFalse: [halftoneWord := self halftoneAt: dy+i-1].
		destMask := mask1.
		nPix := startBits.
		"Here is the inner loop..."
		words := nWords.
			["pick up word"
			smoothingCount = 1 ifTrue:["Faster if not smoothing"
				skewWord := self warpPickSourcePixels: nPix
								xDeltah: xDelta yDeltah: yDelta
								xDeltav: deltaP12x yDeltav: deltaP12y
								dstShiftInc: dstShiftInc flags: mapperFlags.
			] ifFalse:["more difficult with smoothing"
				skewWord := self warpPickSmoothPixels: nPix
						xDeltah: xDelta yDeltah: yDelta
						xDeltav: deltaP12x yDeltav: deltaP12y
						sourceMap: sourceMapOop
						smoothing: smoothingCount
						dstShiftInc: dstShiftInc.
			].
			"align next word access to left most pixel"
			dstBitShift := dstShiftLeft.
			destMask = AllOnes ifTrue:["avoid read-modify-write"
				mergeWord := self mergeFn: (skewWord bitAnd: halftoneWord)
								with: (self dstLongAt: destIndex).
				self dstLongAt: destIndex put: (destMask bitAnd: mergeWord).
			] ifFalse:[ "General version using dest masking"
				destWord := self dstLongAt: destIndex.
				mergeWord := self mergeFn: (skewWord bitAnd: halftoneWord)
								with: (destWord bitAnd: destMask).
				destWord := (destMask bitAnd: mergeWord) bitOr:
								(destWord bitAnd: destMask bitInvert32).
				self dstLongAt: destIndex put: destWord.
			].
			self incDestIndex: 4.
			words = 2 "e.g., is the next word the last word?"
				ifTrue:["set mask for last word in this row"
						destMask := mask2.
						nPix := endBits]
				ifFalse:["use fullword mask for inner loop"
						destMask := AllOnes.
						nPix := destPPW].
			(words := words - 1) = 0] whileFalse.
		"--- end of inner loop ---"
		pAx := pAx + deltaP12x.
		pAy := pAy + deltaP12y.
		pBx := pBx + deltaP43x.
		pBy := pBy + deltaP43y.
		self incDestIndex: destDelta]
]

{ #category : #'pixel mapping' }
BitBltSimulation >> warpLoopSetup [
	"Setup values for faster pixel fetching."
	| words |
	<inline: true>

	"warpSrcShift = log2(sourceDepth)"
	warpSrcShift := 0.
	words := sourceDepth. "recycle temp"
	[words = 1] whileFalse:[
		warpSrcShift := warpSrcShift + 1.
		words := words >> 1].

	"warpSrcMask = mask for extracting one pixel from source word"
	warpSrcMask := maskTable at: sourceDepth.

	"warpAlignShift: Shift for aligning x position to word boundary"
	warpAlignShift := 5 - warpSrcShift.

	"warpAlignMask: Mask for extracting the pixel position from an x position"
	warpAlignMask := 1 << warpAlignShift - 1.

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
	<inline: false> "nope - too much stuff in here"
	<var: #rgb type: #'unsigned int'>
	dstMask := maskTable at: destDepth.
	destWord := 0.
	n = 2 "Try avoiding divides for most common n (divide by 2 is generated as shift)"
		ifTrue:[xdh := xDeltah // 2. ydh := yDeltah // 2. 
				xdv := xDeltav // 2. ydv := yDeltav // 2]
		ifFalse:[xdh := xDeltah // n. ydh := yDeltah // n. 
				xdv := xDeltav // n. ydv := yDeltav // n].
	i := nPixels.
	[
		x := sx. y := sy.
		a := r := g := b := 0.
		"Pick and average n*n subpixels"
		nPix := 0.  "actual number of pixels (not clipped and not transparent)"
		j := n.
		[
			xx := x. yy := y.
			k := n.
			[
				"get a single subpixel"
				rgb := self pickWarpPixelAtX: xx y: yy.
				(combinationRule=25 "PAINT" and: [rgb = 0]) ifFalse:[
					"If not clipped and not transparent, then tally rgb values"
					nPix := nPix + 1.
					sourceDepth < 16 ifTrue:[
						"Get RGBA values from sourcemap table"
						rgb := self long32At: sourceMap + (rgb << 2).
					] ifFalse:["Already in RGB format"
						sourceDepth = 16 
								ifTrue:[rgb := self rgbMap16To32: rgb]
								ifFalse:[rgb := self rgbMap32To32: rgb]].
					b := b + (rgb bitAnd: 255).
					g := g + (rgb >> 8 bitAnd: 255).
					r := r + (rgb >> 16 bitAnd: 255).
					a := a + (rgb >> 24)].
				xx := xx + xdh.
				yy := yy + ydh.
			(k := k - 1) = 0] whileFalse.
			x := x + xdv.
			y := y + ydv.
		(j := j - 1) = 0] whileFalse.

		(nPix = 0 or: [combinationRule=25 "PAINT" and: [nPix < (n * n // 2)]]) ifTrue:[
			rgb := 0  "All pixels were 0, or most were transparent"
		] ifFalse:[
			"normalize rgba sums"
			nPix = 4 "Try to avoid divides for most common n"
				ifTrue:[r := r >> 2.	g := g >> 2.	b := b >> 2.	a := a >> 2]
				ifFalse:[	r := r // nPix.	g := g // nPix.	b := b // nPix.	a := a // nPix].
			rgb := (a << 24) + (r << 16) + (g << 8) + b.

			"map the pixel"
			rgb = 0 ifTrue: [
				"only generate zero if pixel is really transparent"
				(r + g + b + a) > 0 ifTrue: [rgb := 1]].
			rgb := self mapPixel: rgb flags: cmFlags.
		].
		"Mix it in"
		destWord := destWord bitOr: (rgb bitAnd: dstMask) << dstBitShift.
		dstBitShift := dstBitShift + dstShiftInc.
		sx := sx + xDeltah.
		sy := sy + yDeltah.
	(i := i - 1) = 0] whileFalse.

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
	<inline: true> "Yepp - this should go into warpLoop"
	dstMask := maskTable at: destDepth.
	destWord := 0.
	nPix := nPixels.
	(mapperFlags = (ColorMapPresent bitOr: ColorMapIndexedPart)) ifTrue:[
		"a little optimization for (pretty crucial) blits using indexed lookups only"
		[	"grab, colormap and mix in pixel"
			sourcePix := self pickWarpPixelAtX: sx y: sy.
			destPix := cmLookupTable at: (sourcePix bitAnd: cmMask).
			destWord := destWord bitOr: (destPix bitAnd: dstMask) << dstBitShift.
			dstBitShift := dstBitShift + dstShiftInc.
			sx := sx + xDeltah.
			sy := sy + yDeltah.
		(nPix := nPix - 1) = 0] whileFalse.
	] ifFalse:[
		[	"grab, colormap and mix in pixel"
			sourcePix := self pickWarpPixelAtX: sx y: sy.
			destPix := self mapPixel: sourcePix flags: mapperFlags.
			destWord := destWord bitOr: (destPix bitAnd: dstMask) << dstBitShift.
			dstBitShift := dstBitShift + dstShiftInc.
			sx := sx + xDeltah.
			sy := sy + yDeltah.
		(nPix := nPix - 1) = 0] whileFalse.
	].
	^destWord

]
