"
This class adds the plugin functionality for the Balloon graphics engine.
BalloonEnginePlugin should be translated but its superclass should not since it is incorporated within this class's translation process. Nor should the simulation subclass be translated
"
Class {
	#name : #BalloonEnginePlugin,
	#superclass : #BalloonEngineBase,
	#category : #'VMMaker-Plugins'
}

{ #category : #'class initialization' }
BalloonEnginePlugin class >> declareCVarsIn: cg [
	"Nothing to declare"
]

{ #category : #private }
BalloonEnginePlugin >> absoluteSquared8Dot24: value [
	"Compute the squared value of a 8.24 number with 0.0 <= value < 1.0,
	e.g., compute (value * value) bitShift: -24"
	| word1 word2 |
	self inline: true.
	word1 _ value bitAnd: 16rFFFF.
	word2 _ (value bitShift: -16) bitAnd: 255.
	^(( (self cCoerce: (word1 * word1) to:'unsigned') bitShift: -16) +
		((word1 * word2) * 2) +
			((word2 * word2) bitShift: 16)) bitShift: -8
]

{ #category : #'beziers-wide' }
BalloonEnginePlugin >> adjustWideBezierLeft: bezier width: lineWidth offset: lineOffset endX: endX [
	"Adjust the wide bezier curve (dx < 0) to start/end at the right point"
	| lastX lastY |
	self inline: false.
	(self bezierUpdateDataOf: bezier) at: GBUpdateX put: 
		(((self bezierUpdateDataOf: bezier) at: GBUpdateX) - (lineOffset * 256)).
	"Set the lastX/Y value of the second curve lineWidth pixels right/down"
	lastX _ (self wideBezierUpdateDataOf: bezier) at: GBUpdateX.
	(self wideBezierUpdateDataOf: bezier) at: GBUpdateX put: lastX + (lineWidth - lineOffset * 256).
	"Set lineWidth pixels down"
	lastY _ (self wideBezierUpdateDataOf: bezier) at: GBUpdateY.
	(self wideBezierUpdateDataOf: bezier) at: GBUpdateY put: lastY + (lineWidth * 256).
	"Record the last X value"
	self bezierFinalXOf: bezier put: endX - lineOffset.

]

{ #category : #'beziers-wide' }
BalloonEnginePlugin >> adjustWideBezierRight: bezier width: lineWidth offset: lineOffset endX: endX [
	"Adjust the wide bezier curve (dx >= 0) to start/end at the right point"
	| lastX lastY |
	self inline: false.
	(self bezierUpdateDataOf: bezier) at: GBUpdateX put: 
		(((self bezierUpdateDataOf: bezier) at: GBUpdateX) + (lineOffset * 256)).
	"Set the lastX/Y value of the second curve lineWidth pixels right/down"
	"Set lineWidth-lineOffset pixels left"
	lastX _ (self wideBezierUpdateDataOf: bezier) at: GBUpdateX.
	(self wideBezierUpdateDataOf: bezier) at: GBUpdateX put: lastX - (lineWidth - lineOffset * 256).
	lastY _ (self wideBezierUpdateDataOf: bezier) at: GBUpdateY.
	"Set lineWidth pixels down"
	(self wideBezierUpdateDataOf: bezier) at: GBUpdateY put: lastY + (lineWidth * 256).
	"Record the last X value"
	self bezierFinalXOf: bezier put: endX - lineOffset + lineWidth.
]

{ #category : #'lines-wide' }
BalloonEnginePlugin >> adjustWideLine: line afterSteppingFrom: lastX to: nextX [
	"Adjust the wide line after it has been stepped from lastX to nextX.
	Special adjustments of line width and start position are made here
	to simulate a rectangular brush"
	|  yEntry yExit lineWidth lineOffset deltaX xDir baseWidth |
	self inline: false.	"Don't inline this"


	"Fetch the values the adjustment decisions are based on"
	yEntry _ (self wideLineEntryOf: line).
	yExit _ (self wideLineExitOf: line).
	baseWidth _ self wideLineExtentOf: line.
	lineOffset _ self offsetFromWidth: baseWidth.
	lineWidth _ self wideLineWidthOf: line.
	xDir _ self lineXDirectionOf: line.
	deltaX _ nextX - lastX.

	"Adjust the start of the line to fill an entire rectangle"
	yEntry < baseWidth ifTrue:[
		xDir < 0
			ifTrue:[	lineWidth _ lineWidth - deltaX] "effectively adding"
			ifFalse:[	lineWidth _ lineWidth + deltaX.
					self edgeXValueOf: line put: lastX].
	].

	"Adjust the end of x-major lines"
	((yExit + lineOffset) = 0) ifTrue:[
		xDir > 0
			ifTrue:[lineWidth _ lineWidth - (self lineXIncrementOf: line)]
			ifFalse:[lineWidth _ lineWidth + (self lineXIncrementOf: line).	"effectively subtracting"
					self edgeXValueOf: line put: lastX].
	].

	"Adjust the end of the line to fill an entire rectangle"
	(yExit + lineOffset) > 0 ifTrue:[
		xDir < 0
			ifTrue:[	lineWidth _ lineWidth + deltaX. "effectively subtracting"
					self edgeXValueOf: line put: lastX]
			ifFalse:[	lineWidth _ lineWidth - deltaX]
	].

	"Store the manipulated line width back"
	self wideLineWidthOf: line put: lineWidth.
]

{ #category : #allocation }
BalloonEnginePlugin >> allocateBezier [
	| bezier |
	(self allocateObjEntry: GBBaseSize) ifFalse:[^0].
	bezier _ objUsed.
	objUsed _ bezier + GBBaseSize.
	self objectTypeOf: bezier put: GEPrimitiveBezier.
	self objectIndexOf: bezier put: 0.
	self objectLengthOf: bezier put: GBBaseSize.
	^bezier
]

{ #category : #allocation }
BalloonEnginePlugin >> allocateBezierStackEntry [
	self wbStackPush: 6.
	^self wbStackSize
]

{ #category : #allocation }
BalloonEnginePlugin >> allocateBitmapFill: cmSize colormap: cmBits [
	| fill fillSize cm |
	self var:#cm declareC:'int *cm'.
	self var:#cmBits declareC:'int *cmBits'.
	fillSize _ GBMBaseSize + cmSize.
	(self allocateObjEntry: fillSize) ifFalse:[^0].
	fill _ objUsed.
	objUsed _ fill + fillSize.
	self objectTypeOf: fill put: GEPrimitiveClippedBitmapFill.
	self objectIndexOf: fill put: 0.
	self objectLengthOf: fill put: fillSize.
	cm _ self colormapOf: fill.
	self hasColorTransform ifTrue:[
		0 to: cmSize-1 do:[:i| cm at: i put: (self transformColor: (cmBits at: i))].
	] ifFalse:[
		0 to: cmSize-1 do:[:i| cm at: i put: (cmBits at: i)].
	].
	self bitmapCmSizeOf: fill put: cmSize.
	^fill
]

{ #category : #allocation }
BalloonEnginePlugin >> allocateGradientFill: ramp rampWidth: rampWidth isRadial: isRadial [
	| fill fillSize rampPtr |
	self var:#ramp declareC:'int *ramp'.
	self var:#rampPtr declareC:'int *rampPtr'.
	fillSize _ GGBaseSize + rampWidth.
	(self allocateObjEntry: fillSize) ifFalse:[^0].
	fill _ objUsed.
	objUsed _ fill + fillSize.
	isRadial
		ifTrue:[self objectTypeOf: fill put: GEPrimitiveRadialGradientFill]
		ifFalse:[self objectTypeOf: fill put: GEPrimitiveLinearGradientFill].
	self objectIndexOf: fill put: 0.
	self objectLengthOf: fill put: fillSize.
	rampPtr _ self gradientRampOf: fill.
	self hasColorTransform ifTrue:[
		0 to: rampWidth-1 do:[:i| rampPtr at: i put: (self transformColor: (ramp at: i))].
	] ifFalse:[
		0 to: rampWidth-1 do:[:i| rampPtr at: i put: (ramp at: i)].
	].
	self gradientRampLengthOf: fill put: rampWidth.
	^fill
]

{ #category : #allocation }
BalloonEnginePlugin >> allocateLine [
	| line |
	(self allocateObjEntry: GLBaseSize) ifFalse:[^0].
	line _ objUsed.
	objUsed _ line + GLBaseSize.
	self objectTypeOf: line put: GEPrimitiveLine.
	self objectIndexOf: line put: 0.
	self objectLengthOf: line put: GLBaseSize.
	^line
]

{ #category : #allocation }
BalloonEnginePlugin >> allocateWideBezier [
	| bezier |
	(self allocateObjEntry: GBWideSize) ifFalse:[^0].
	bezier _ objUsed.
	objUsed _ bezier + GBWideSize.
	self objectTypeOf: bezier put: GEPrimitiveWideBezier.
	self objectIndexOf: bezier put: 0.
	self objectLengthOf: bezier put: GBWideSize.
	^bezier
]

{ #category : #allocation }
BalloonEnginePlugin >> allocateWideLine [
	| line |
	(self allocateObjEntry: GLWideSize) ifFalse:[^0].
	line _ objUsed.
	objUsed _ line + GLWideSize.
	self objectTypeOf: line put: GEPrimitiveWideLine.
	self objectIndexOf: line put: 0.
	self objectLengthOf: line put: GLWideSize.
	^line
]

{ #category : #'bezier-loading' }
BalloonEnginePlugin >> assureValue: val1 between: val2 and: val3 [
	"Make sure that val1 is between val2 and val3."
	self inline: true.
	val2 > val3 ifTrue:[
		val1 > val2 ifTrue:[^val2].
		val1 < val3 ifTrue:[^val3].
	] ifFalse:[
		val1 < val2 ifTrue:[^val2].
		val1 > val3 ifTrue:[^val3].
	].
	^val1	
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bezierEndXOf: bezier [

	^self obj: bezier at: GBEndX
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bezierEndXOf: bezier put: value [

	^self obj: bezier at: GBEndX put: value
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bezierEndYOf: bezier [

	^self obj: bezier at: GBEndY
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bezierEndYOf: bezier put: value [

	^self obj: bezier at: GBEndY put: value
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bezierFinalXOf: bezier [

	^self obj: bezier at: GBFinalX
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bezierFinalXOf: bezier put: value [

	^self obj: bezier at: GBFinalX put: value
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bezierUpdateDataOf: bezier [
	self returnTypeC: 'int *'.

	^objBuffer + bezier + GBUpdateData
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bezierViaXOf: bezier [

	^self obj: bezier at: GBViaX
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bezierViaXOf: bezier put: value [

	^self obj: bezier at: GBViaX put: value
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bezierViaYOf: bezier [

	^self obj: bezier at: GBViaY
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bezierViaYOf: bezier put: value [

	^self obj: bezier at: GBViaY put: value
]

{ #category : #'accessing bitmaps' }
BalloonEnginePlugin >> bitmapCmSizeOf: bmFill [

	^self obj: bmFill at: GBColormapSize
]

{ #category : #'accessing bitmaps' }
BalloonEnginePlugin >> bitmapCmSizeOf: bmFill put: value [

	^self obj: bmFill at: GBColormapSize put: value
]

{ #category : #'accessing bitmaps' }
BalloonEnginePlugin >> bitmapDepthOf: bmFill [

	^self obj: bmFill at: GBBitmapDepth
]

{ #category : #'accessing bitmaps' }
BalloonEnginePlugin >> bitmapDepthOf: bmFill put: value [

	^self obj: bmFill at: GBBitmapDepth put: value
]

{ #category : #'accessing bitmaps' }
BalloonEnginePlugin >> bitmapHeightOf: bmFill [

	^self obj: bmFill at: GBBitmapHeight
]

{ #category : #'accessing bitmaps' }
BalloonEnginePlugin >> bitmapHeightOf: bmFill put: value [

	^self obj: bmFill at: GBBitmapHeight put: value
]

{ #category : #'accessing bitmaps' }
BalloonEnginePlugin >> bitmapRasterOf: bmFill [

	^self obj: bmFill at: GBBitmapRaster
]

{ #category : #'accessing bitmaps' }
BalloonEnginePlugin >> bitmapRasterOf: bmFill put: value [

	^self obj: bmFill at: GBBitmapRaster put: value
]

{ #category : #'accessing bitmaps' }
BalloonEnginePlugin >> bitmapSizeOf: bmFill [

	^self obj: bmFill at: GBBitmapSize
]

{ #category : #'accessing bitmaps' }
BalloonEnginePlugin >> bitmapSizeOf: bmFill put: value [

	^self obj: bmFill at: GBBitmapSize put: value
]

{ #category : #'accessing bitmaps' }
BalloonEnginePlugin >> bitmapTileFlagOf: bmFill [

	^self obj: bmFill at: GBTileFlag
]

{ #category : #'accessing bitmaps' }
BalloonEnginePlugin >> bitmapTileFlagOf: bmFill put: value [

	^self obj: bmFill at: GBTileFlag put: value
]

{ #category : #'fills-bitmaps' }
BalloonEnginePlugin >> bitmapValue: bmFill bits: bits atX: xp y: yp [

	| bmDepth bmRaster value rShift cMask r g b a |
	self inline: true.

	bmDepth _ self bitmapDepthOf: bmFill.
	bmRaster _ self bitmapRasterOf: bmFill.
	bmDepth = 32 ifTrue: [
		value _ (self cCoerce: bits to:'int*') at: (bmRaster * yp) + xp.
		(value ~= 0 and: [(value bitAnd: 16rFF000000) = 0])
				ifTrue: [value _ value bitOr: 16rFF000000].
		^self uncheckedTransformColor: value].
	"rShift - shift value to convert from pixel to word index"
	rShift _ self rShiftTable at: bmDepth.
	value _ self makeUnsignedFrom: 
		((self cCoerce: bits to:'int*') at: (bmRaster * yp) + (xp >> rShift)).
	"cMask - mask out the pixel from the word"
	cMask _ (1 << bmDepth) - 1.
	"rShift - shift value to move the pixel in the word to the lowest bit position"
	rShift _ 32 - bmDepth - ((xp bitAnd: (1 << rShift - 1)) * bmDepth).
	value _ (value >> rShift) bitAnd: cMask.
	bmDepth = 16 ifTrue: [
		"Must convert by expanding bits"
		value = 0 ifFalse: [
			b _ (value bitAnd: 31) << 3.		b _ b + (b >> 5).
			g _ (value >> 5 bitAnd: 31) << 3.	g _ g + (g >> 5).
			r _ (value >> 10 bitAnd: 31) << 3.	r _ r + (r >> 5).
			a _ 255.
			value _ b + (g << 8) + (r << 16) + (a << 24)].
	] ifFalse: [
		"Must convert by using color map"
		(self bitmapCmSizeOf: bmFill) = 0
			ifTrue: [value _ 0]
			ifFalse: [value _ self makeUnsignedFrom: ((self colormapOf: bmFill) at: value)].
	].
	^self uncheckedTransformColor: value.
]

{ #category : #'accessing bitmaps' }
BalloonEnginePlugin >> bitmapWidthOf: bmFill [

	^self obj: bmFill at: GBBitmapWidth
]

{ #category : #'accessing bitmaps' }
BalloonEnginePlugin >> bitmapWidthOf: bmFill put: value [

	^self obj: bmFill at: GBBitmapWidth put: value
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bzEndX: index [
	^self wbStackValue: self wbStackSize - index + 4
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bzEndX: index put: value [
	^self wbStackValue: self wbStackSize - index + 4 put: value
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bzEndY: index [
	^self wbStackValue: self wbStackSize - index + 5
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bzEndY: index put: value [
	^self wbStackValue: self wbStackSize - index + 5 put: value
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bzStartX: index [
	^self wbStackValue: self wbStackSize - index + 0
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bzStartX: index put: value [
	^self wbStackValue: self wbStackSize - index + 0 put: value
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bzStartY: index [
	^self wbStackValue: self wbStackSize - index + 1
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bzStartY: index put: value [
	^self wbStackValue: self wbStackSize - index + 1 put: value
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bzViaX: index [
	^self wbStackValue: self wbStackSize - index + 2
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bzViaX: index put: value [
	^self wbStackValue: self wbStackSize - index + 2 put: value
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bzViaY: index [
	^self wbStackValue: self wbStackSize - index + 3
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> bzViaY: index put: value [
	^self wbStackValue: self wbStackSize - index + 3 put: value
]

{ #category : #'shapes-compressed' }
BalloonEnginePlugin >> checkCompressedFillIndexList: fillList max: maxIndex segments: nSegs [
	"Check the fill indexes in the run-length encoded fillList"
	| length runLength runValue nFills fillPtr |
	self inline: false.
	self var: #fillPtr declareC:'int *fillPtr'.
	length _ interpreterProxy slotSizeOf: fillList.
	fillPtr _ interpreterProxy firstIndexableField: fillList.
	nFills _ 0.
	0 to: length-1 do:[:i |
		runLength _ self shortRunLengthAt: i from: fillPtr.
		runValue _ self shortRunValueAt: i from: fillPtr.
		(runValue >= 0 and:[runValue <= maxIndex]) ifFalse:[^false].
		nFills _ nFills + runLength.
	].
	^nFills = nSegs
]

{ #category : #'shapes-compressed' }
BalloonEnginePlugin >> checkCompressedFills: indexList [
	"Check if the indexList (containing fill handles) is okay."
	| fillPtr length fillIndex |
	self inline: false.
	self var: #fillPtr declareC:'int *fillPtr'.
	"First check if the oops have the right format"
	(interpreterProxy isWords: indexList) ifFalse:[^false].

	"Then check the fill entries"
	length _ interpreterProxy slotSizeOf: indexList.
	fillPtr _ interpreterProxy firstIndexableField: indexList.
	0 to: length-1 do:[:i |
		fillIndex _ fillPtr at: i.
		"Make sure the fill is okay"
		(self isFillOkay: fillIndex) ifFalse:[^false]].

	^ true
]

{ #category : #'shapes-compressed' }
BalloonEnginePlugin >> checkCompressedLineWidths: lineWidthList segments: nSegments [
	"Check the run-length encoded lineWidthList matches nSegments"
	| length runLength nItems ptr |
	self inline: false.
	self var: #ptr declareC:'int *ptr'.
	length _ interpreterProxy slotSizeOf: lineWidthList.
	ptr _ interpreterProxy firstIndexableField: lineWidthList.
	nItems _ 0.
	0 to: length-1 do:[:i|
		runLength _ self shortRunLengthAt: i from: ptr.
		nItems _ nItems + runLength.
	].
	^nItems = nSegments
]

{ #category : #'shapes-compressed' }
BalloonEnginePlugin >> checkCompressedPoints: points segments: nSegments [
	"Check if the given point array can be handled by the engine."
	| pSize |
	self inline: false.
	(interpreterProxy isWords: points) ifFalse:[^false].
	pSize _ interpreterProxy slotSizeOf: points.
	"The points must be either in PointArray format or ShortPointArray format.
	Also, we currently handle only quadratic segments (e.g., 3 points each) and thus either
		pSize = nSegments * 3,		for ShortPointArrays or,
		pSize = nSegments * 6,		for PointArrays"
	(pSize = (nSegments * 3) or:[pSize = (nSegments * 6)]) 
		ifFalse:[^false]. "Can't handle this"
	^true
]

{ #category : #'shapes-compressed' }
BalloonEnginePlugin >> checkCompressedShape: points segments: nSegments leftFills: leftFills rightFills: rightFills lineWidths: lineWidths lineFills: lineFills fillIndexList: fillIndexList [
	"Check if the given shape can be handled by the engine. 
	Since there are a number of requirements this is an extra method."
	| maxFillIndex |
	self inline: false.
	(self checkCompressedPoints: points segments: nSegments) 
		ifFalse:[^false].
	(self checkCompressedFills: fillIndexList)
		ifFalse:[^false].
	maxFillIndex _ interpreterProxy slotSizeOf: fillIndexList.
	(self checkCompressedFillIndexList: leftFills max: maxFillIndex segments: nSegments)
		ifFalse:[^false].
	(self checkCompressedFillIndexList: rightFills max: maxFillIndex segments: nSegments)
		ifFalse:[^false].
	(self checkCompressedFillIndexList: lineFills max: maxFillIndex segments: nSegments)
		ifFalse:[^false].
	(self checkCompressedLineWidths: lineWidths segments: nSegments)
		ifFalse:[^false].
	^true
]

{ #category : #'GET processing' }
BalloonEnginePlugin >> checkedAddBezierToGET: bezier [
	"Add the bezier to the global edge table if it intersects the clipping region"
	| lineWidth |
	self inline: true.

	(self isWide: bezier) 
		ifTrue:[lineWidth _ (self wideBezierExtentOf: bezier)]
		ifFalse:[lineWidth _ 0].
	(self bezierEndYOf: bezier) + lineWidth < (self fillMinYGet) ifTrue:[^0].
	"Overlaps in Y but may still be entirely right of clip region"
	((self edgeXValueOf: bezier) - lineWidth >= self fillMaxXGet and:[
		(self bezierEndXOf: bezier) - lineWidth >= self fillMaxXGet]) ifTrue:[^0].
	self addEdgeToGET: bezier.

]

{ #category : #'GET processing' }
BalloonEnginePlugin >> checkedAddEdgeToGET: edge [
	"Add the edge to the global edge table.
	For known edge types, check if the edge intersects the visible region"
	self inline: true.

	(self isLine: edge) ifTrue:[^self checkedAddLineToGET: edge].
	(self isBezier: edge) ifTrue:[^self checkedAddBezierToGET: edge].
	self addEdgeToGET: edge.

]

{ #category : #'GET processing' }
BalloonEnginePlugin >> checkedAddLineToGET: line [
	"Add the line to the global edge table if it intersects the clipping region"
	| lineWidth |
	self inline: true.

	(self isWide: line) 
		ifTrue:[lineWidth _ (self wideLineExtentOf: line)]
		ifFalse:[lineWidth _ 0].
	(self lineEndYOf: line) + lineWidth < (self fillMinYGet) ifTrue:[^0].
	"Overlaps in Y but may still be entirely right of clip region"
	((self edgeXValueOf: line) - lineWidth >= self fillMaxXGet and:[
		(self lineEndXOf: line) - lineWidth >= self fillMaxXGet]) ifTrue:[^0].
	self addEdgeToGET: line.

]

{ #category : #private }
BalloonEnginePlugin >> circleCosTable [
	| theTable |
	self returnTypeC:'double *'.
	self inline: false. "Don't you inline this!!!"
	self var:#theTable declareC:'static double theTable[33] =
		{1.0, 0.98078528040323, 0.923879532511287, 0.831469612302545,
		0.7071067811865475, 0.555570233019602, 0.38268343236509, 0.1950903220161286,
		0.0, -0.1950903220161283, -0.3826834323650896, -0.555570233019602,
		-0.707106781186547, -0.831469612302545, -0.9238795325112865, -0.98078528040323,
		-1.0, -0.98078528040323, -0.923879532511287, -0.831469612302545,
		-0.707106781186548, -0.555570233019602, -0.3826834323650903, -0.1950903220161287,
		0.0, 0.1950903220161282, 0.38268343236509, 0.555570233019602,
		0.707106781186547, 0.831469612302545, 0.9238795325112865, 0.98078528040323,
		1.0 }'.
	^theTable
]

{ #category : #private }
BalloonEnginePlugin >> circleSinTable [
	| theTable |
	self returnTypeC:'double *'.
	self inline: false. "Don't you inline this!!!"
	self var:#theTable declareC:'static double theTable[33] =
		{0.0, 0.1950903220161282, 0.3826834323650897, 0.555570233019602,
		0.707106781186547, 0.831469612302545, 0.923879532511287, 0.98078528040323,
		1.0, 0.98078528040323, 0.923879532511287, 0.831469612302545,
		0.7071067811865475, 0.555570233019602, 0.38268343236509, 0.1950903220161286,
		0.0, -0.1950903220161283, -0.3826834323650896, -0.555570233019602,
		-0.707106781186547, -0.831469612302545, -0.9238795325112865, -0.98078528040323,
		-1.0, -0.98078528040323, -0.923879532511287, -0.831469612302545,
		-0.707106781186548, -0.555570233019602, -0.3826834323650903, -0.1950903220161287,
		 0.0 }'.
	^theTable
]

{ #category : #'fills-bitmaps' }
BalloonEnginePlugin >> clampValue: value max: maxValue [

	self inline: true.
	value < 0 
		ifTrue:[^0]
		ifFalse:[value >= maxValue 
					ifTrue:[^maxValue-1]
					ifFalse:[^value]]
]

{ #category : #'accessing bitmaps' }
BalloonEnginePlugin >> colormapOf: bmFill [
	self returnTypeC:'int *'.
	^objBuffer + bmFill + GBColormapOffset
]

{ #category : #'bezier-loading' }
BalloonEnginePlugin >> computeBezier: index splitAt: param [
	"Split the bezier curve at the given parametric value.
	Note: Since this method is only invoked to make non-monoton
		beziers monoton we must check for the resulting y values
		to be *really* between the start and end value."
	| startX startY viaX viaY endX endY newIndex 
	leftViaX  leftViaY rightViaX rightViaY sharedX sharedY |
	self inline: false.

	self var: #param declareC:'double param'.
	leftViaX _ startX _ self bzStartX: index.
	leftViaY _ startY _ self bzStartY: index.
	rightViaX _ viaX _ self bzViaX: index.
	rightViaY _ viaY _ self bzViaY: index.
	endX _ self bzEndX: index.
	endY _ self bzEndY: index.

	"Compute intermediate points"
	sharedX _ leftViaX _ leftViaX + ((viaX - startX) asFloat * param) asInteger.
	sharedY _ leftViaY _ leftViaY + ((viaY - startY) asFloat * param) asInteger.
	rightViaX _ rightViaX + ((endX - viaX) asFloat * param) asInteger.
	rightViaY _ rightViaY + ((endY - viaY) asFloat * param) asInteger.
	"Compute new shared point"
	sharedX _ sharedX + ((rightViaX - leftViaX) asFloat * param) asInteger.
	sharedY _ sharedY + ((rightViaY - leftViaY) asFloat * param) asInteger.

	"Check the new via points"
	leftViaY _ self assureValue: leftViaY between: startY and: sharedY.
	rightViaY _ self assureValue: rightViaY between: sharedY and: endY.

	newIndex _ self allocateBezierStackEntry.
	engineStopped ifTrue:[^0]. "Something went wrong"

	"Store the first part back"
	self bzViaX: index put: leftViaX.
	self bzViaY: index put: leftViaY.
	self bzEndX: index put: sharedX.
	self bzEndY: index put: sharedY.
	"Store the second point back"
	self bzStartX: newIndex put: sharedX.
	self bzStartY: newIndex put: sharedY.
	self bzViaX: newIndex put: rightViaX.
	self bzViaY: newIndex put: rightViaY.
	self bzEndX: newIndex put: endX.
	self bzEndY: newIndex put: endY.

	^newIndex
]

{ #category : #'bezier-loading' }
BalloonEnginePlugin >> computeBezierSplitAtHalf: index [
	"Split the bezier curve at 0.5."
	| startX startY viaX viaY endX endY newIndex 
	leftViaX  leftViaY rightViaX rightViaY sharedX sharedY |
	self inline: false.

	newIndex _ self allocateBezierStackEntry.
	engineStopped ifTrue:[^0]. "Something went wrong"

	leftViaX _ startX _ self bzStartX: index.
	leftViaY _ startY _ self bzStartY: index.
	rightViaX _ viaX _ self bzViaX: index.
	rightViaY _ viaY _ self bzViaY: index.
	endX _ self bzEndX: index.
	endY _ self bzEndY: index.
	"Compute intermediate points"
	leftViaX _ leftViaX + ((viaX - startX) // 2).
	leftViaY _ leftViaY + ((viaY - startY) // 2).
	sharedX _ rightViaX _ rightViaX + ((endX - viaX) // 2).
	sharedY _ rightViaY _ rightViaY + ((endY - viaY) // 2).
	"Compute new shared point"
	sharedX _ sharedX + ((leftViaX - rightViaX) // 2).
	sharedY _ sharedY + ((leftViaY - rightViaY) // 2).
	"Store the first part back"
	self bzViaX: index put: leftViaX.
	self bzViaY: index put: leftViaY.
	self bzEndX: index put: sharedX.
	self bzEndY: index put: sharedY.
	"Store the second point back"
	self bzStartX: newIndex put: sharedX.
	self bzStartY: newIndex put: sharedY.
	self bzViaX: newIndex put: rightViaX.
	self bzViaY: newIndex put: rightViaY.
	self bzEndX: newIndex put: endX.
	self bzEndY: newIndex put: endY.

	^newIndex
]

{ #category : #'beziers-wide' }
BalloonEnginePlugin >> computeFinalWideBezierValues: bezier width: lineWidth [
	"Get both values from the two boundaries of the given bezier 
	and compute the actual position/width of the line"
	| leftX rightX temp |
	leftX _ ((self bezierUpdateDataOf: bezier) at: GBUpdateX) // 256.
	rightX _ ((self wideBezierUpdateDataOf: bezier) at: GBUpdateX) // 256.
	leftX > rightX ifTrue:[temp _ leftX. leftX _ rightX. rightX _ temp].
	self edgeXValueOf: bezier put: leftX.
	(rightX - leftX) > lineWidth ifTrue:[
		self wideBezierWidthOf: bezier put: (rightX - leftX).
	] ifFalse:[
		self wideBezierWidthOf: bezier put: lineWidth.
	].
]

{ #category : #'fills-bitmaps' }
BalloonEnginePlugin >> fillBitmapSpan [
	self inline: true.
	^self fillBitmapSpan: self lastExportedFillGet from: self lastExportedLeftXGet to: self lastExportedRightXGet at: self currentYGet
]

{ #category : #'fills-bitmaps' }
BalloonEnginePlugin >> fillBitmapSpan: bmFill from: leftX to: rightX at: yValue [
	| x x1 dsX ds dtX dt deltaX deltaY bits xp yp bmWidth bmHeight fillValue tileFlag |
	self inline: false.
	self var: #bits declareC:'int *bits'.
	self aaLevelGet = 1
		ifFalse:[^self fillBitmapSpanAA: bmFill from: leftX to: rightX at: yValue].

	bits _ self loadBitsFrom: bmFill.
	bits == nil ifTrue:[^nil].
	bmWidth _ self bitmapWidthOf: bmFill.
	bmHeight _ self bitmapHeightOf: bmFill.
	tileFlag _ (self bitmapTileFlagOf: bmFill) = 1.
	deltaX _ leftX - (self fillOriginXOf: bmFill).
	deltaY _ yValue - (self fillOriginYOf: bmFill).
	dsX _ self fillDirectionXOf: bmFill.
	dtX _ self fillNormalXOf: bmFill.

	ds _ (deltaX * dsX) + (deltaY * (self fillDirectionYOf: bmFill)).
	dt _ (deltaX * dtX) + (deltaY * (self fillNormalYOf: bmFill)).

	x _ leftX.
	x1 _ rightX.
	[x < x1] whileTrue:[
		tileFlag ifTrue:[
			ds _ self repeatValue: ds max: bmWidth << 16.
			dt _ self repeatValue: dt max: bmHeight << 16].
		xp _ ds // 16r10000.
		yp _ dt // 16r10000.
		tileFlag ifFalse:[
			xp _ self clampValue: xp max: bmWidth.
			yp _ self clampValue: yp max: bmHeight].
		(xp >= 0 and:[yp >= 0 and:[xp < bmWidth and:[yp < bmHeight]]]) ifTrue:[
			fillValue _ self bitmapValue: bmFill bits: bits atX: xp y: yp.
			spanBuffer at: x put: fillValue.
		].
		ds _ ds + dsX.
		dt _ dt + dtX.
		x _ x + 1.
	].
]

{ #category : #'fills-bitmaps' }
BalloonEnginePlugin >> fillBitmapSpanAA: bmFill from: leftX to: rightX at: yValue [
	| x dsX ds dtX dt deltaX deltaY bits xp yp bmWidth bmHeight fillValue baseShift cMask cShift idx aaLevel firstPixel lastPixel tileFlag |
	self inline: false.
	self var: #bits declareC:'int *bits'.
	bits _ self loadBitsFrom: bmFill.
	bits == nil ifTrue:[^nil].
	bmWidth _ self bitmapWidthOf: bmFill.
	bmHeight _ self bitmapHeightOf: bmFill.
	tileFlag _ (self bitmapTileFlagOf: bmFill) = 1.
	deltaX _ leftX - (self fillOriginXOf: bmFill).
	deltaY _ yValue - (self fillOriginYOf: bmFill).
	dsX _ self fillDirectionXOf: bmFill.
	dtX _ self fillNormalXOf: bmFill.

	ds _ (deltaX * dsX) + (deltaY * (self fillDirectionYOf: bmFill)).
	dt _ (deltaX * dtX) + (deltaY * (self fillNormalYOf: bmFill)).

	aaLevel _ self aaLevelGet.
	firstPixel _ self aaFirstPixelFrom: leftX to: rightX.
	lastPixel _ self aaLastPixelFrom: leftX to: rightX.
	baseShift _ self aaShiftGet.
	cMask _ self aaColorMaskGet.
	cShift _ self aaColorShiftGet.
	x _ leftX.
	[x < firstPixel] whileTrue:[
		tileFlag ifTrue:[
			ds _ self repeatValue: ds max: bmWidth << 16.
			dt _ self repeatValue: dt max: bmHeight << 16].
		xp _ ds // 16r10000.
		yp _ dt // 16r10000.
		tileFlag ifFalse:[
			xp _ self clampValue: xp max: bmWidth.
			yp _ self clampValue: yp max: bmHeight].
		(xp >= 0 and:[yp >= 0 and:[xp < bmWidth and:[yp < bmHeight]]]) ifTrue:[
			fillValue _ self bitmapValue: bmFill bits: bits atX: xp y: yp.
			fillValue _ (fillValue bitAnd: cMask) >> cShift.
			idx _ x >> baseShift.
			spanBuffer at: idx put: (spanBuffer at: idx) + fillValue.
		].
		ds _ ds + dsX.
		dt _ dt + dtX.
		x _ x + 1.
	].

	cMask _ (self aaColorMaskGet >> self aaShiftGet) bitOr: 16rF0F0F0F0.
	cShift _ self aaShiftGet.
	[x < lastPixel] whileTrue:[
		tileFlag ifTrue:[
			ds _ self repeatValue: ds max: bmWidth << 16.
			dt _ self repeatValue: dt max: bmHeight << 16].
		xp _ ds // 16r10000.
		yp _ dt // 16r10000.
		tileFlag ifFalse:[
			xp _ self clampValue: xp max: bmWidth.
			yp _ self clampValue: yp max: bmHeight].
		(xp >= 0 and:[yp >= 0 and:[xp < bmWidth and:[yp < bmHeight]]]) ifTrue:[
			fillValue _ self bitmapValue: bmFill bits: bits atX: xp y: yp.
			fillValue _ (fillValue bitAnd: cMask) >> cShift.
			idx _ x >> baseShift.
			spanBuffer at: idx put: (spanBuffer at: idx) + fillValue.
		].
		ds _ ds + (dsX << cShift).
		dt _ dt + (dtX << cShift).
		x _ x + aaLevel.
	].

	cMask _ self aaColorMaskGet.
	cShift _ self aaColorShiftGet.
	[x < rightX] whileTrue:[
		tileFlag ifTrue:[
			ds _ self repeatValue: ds max: bmWidth << 16.
			dt _ self repeatValue: dt max: bmHeight << 16].
		xp _ ds // 16r10000.
		yp _ dt // 16r10000.
		tileFlag ifFalse:[
			xp _ self clampValue: xp max: bmWidth.
			yp _ self clampValue: yp max: bmHeight].
		(xp >= 0 and:[yp >= 0 and:[xp < bmWidth and:[yp < bmHeight]]]) ifTrue:[
			fillValue _ self bitmapValue: bmFill bits: bits atX: xp y: yp.
			fillValue _ (fillValue bitAnd: cMask) >> cShift.
			idx _ x >> baseShift.
			spanBuffer at: idx put: (spanBuffer at: idx) + fillValue.
		].
		ds _ ds + dsX.
		dt _ dt + dtX.
		x _ x + 1.
	].

]

{ #category : #'accessing fills' }
BalloonEnginePlugin >> fillDirectionXOf: fill [

	^self obj: fill at: GFDirectionX
]

{ #category : #'accessing fills' }
BalloonEnginePlugin >> fillDirectionXOf: fill put: value [

	^self obj: fill at: GFDirectionX put: value
]

{ #category : #'accessing fills' }
BalloonEnginePlugin >> fillDirectionYOf: fill [

	^self obj: fill at: GFDirectionY
]

{ #category : #'accessing fills' }
BalloonEnginePlugin >> fillDirectionYOf: fill put: value [

	^self obj: fill at: GFDirectionY put: value
]

{ #category : #'fills-gradient' }
BalloonEnginePlugin >> fillLinearGradient [
	self inline: true.
	^self fillLinearGradient: self lastExportedFillGet from: self lastExportedLeftXGet to: self lastExportedRightXGet at: self currentYGet
]

{ #category : #'fills-gradient' }
BalloonEnginePlugin >> fillLinearGradient: fill from: leftX to: rightX at: yValue [
	"Draw a linear gradient fill."
	| x0 x1 ramp rampSize dsX ds x rampIndex |
	self inline: false.
	self var: #ramp declareC:'int *ramp'.
	ramp _ self gradientRampOf: fill.
	rampSize _ self gradientRampLengthOf: fill.

	dsX _ self fillDirectionXOf: fill.
	ds _ ((leftX - (self fillOriginXOf: fill)) * dsX) + 
			((yValue - (self fillOriginYOf: fill)) * (self fillDirectionYOf: fill)).

	x _ x0 _ leftX.
	x1 _ rightX.

	"Note: The inner loop has been divided into three parts for speed"
	"Part one: Fill everything outside the left boundary"
	[((rampIndex _ ds // 16r10000) < 0 or:[rampIndex >= rampSize]) and:[x < x1]] 
		whileTrue:[	x _ x + 1.
					ds _ ds + dsX].
	x > x0 ifTrue:[
		rampIndex < 0 ifTrue:[rampIndex _ 0].
		rampIndex >= rampSize ifTrue:[rampIndex _ rampSize - 1].
		self fillColorSpan: (self makeUnsignedFrom: (ramp at: rampIndex)) from: x0 to: x].

	"Part two: Fill everything inside the boundaries"
	self aaLevelGet = 1 ifTrue:[
		"Fast version w/o anti-aliasing"
		[((rampIndex _ ds // 16r10000) < rampSize and:[rampIndex >= 0]) and:[x < x1]] whileTrue:[
			spanBuffer at: x put: (self makeUnsignedFrom: (ramp at: rampIndex)).
			x _ x + 1.
			ds _ ds + dsX.
		].
	] ifFalse:[x _ self fillLinearGradientAA: fill ramp: ramp ds: ds dsX: dsX from: x to: rightX].
	"Part three fill everything outside right boundary"
	x < x1 ifTrue:[
		rampIndex < 0 ifTrue:[rampIndex _ 0].
		rampIndex >= rampSize ifTrue:[rampIndex _ rampSize-1].
		self fillColorSpan: (self makeUnsignedFrom: (ramp at: rampIndex)) from: x to: x1].

]

{ #category : #'fills-gradient' }
BalloonEnginePlugin >> fillLinearGradientAA: fill ramp: ramp ds: deltaS dsX: dsX from: leftX to: rightX [
	"This is the AA version of linear gradient filling."
	| colorMask colorShift baseShift rampIndex ds rampSize x idx rampValue 
	 aaLevel firstPixel lastPixel |
	self inline: false.
	self var: #ramp declareC:'int *ramp'.

	aaLevel _ self aaLevelGet.
	baseShift _ self aaShiftGet.
	rampSize _ self gradientRampLengthOf: fill.
	ds _ deltaS.
	x _ leftX.
	rampIndex _ ds // 16r10000.

	firstPixel _ self aaFirstPixelFrom: leftX to: rightX.
	lastPixel _ self aaLastPixelFrom: leftX to: rightX.

	"Deal with the first n sub-pixels"
	colorMask _ self aaColorMaskGet.
	colorShift _ self aaColorShiftGet.
	[x < firstPixel and:[rampIndex < rampSize and:[rampIndex >= 0]]] whileTrue:[
		rampValue _ self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
		rampValue _ (rampValue bitAnd: colorMask) >> colorShift.
		"Copy as many pixels as possible"
		[x < firstPixel and:[(ds//16r10000) = rampIndex]] whileTrue:[
			idx _ x >> baseShift.
			spanBuffer at: idx put: (spanBuffer at: idx) + rampValue.
			x _ x + 1.
			ds _ ds + dsX].
		rampIndex _ ds // 16r10000.
	].

	"Deal with the full pixels"
	colorMask _ (self aaColorMaskGet >> self aaShiftGet) bitOr: 16rF0F0F0F0.
	colorShift _ self aaShiftGet.
	[x < lastPixel and:[rampIndex < rampSize and:[rampIndex >= 0]]] whileTrue:[
		rampValue _ self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
		rampValue _ (rampValue bitAnd: colorMask) >> colorShift.
		"Copy as many pixels as possible"
		[x < lastPixel and:[(ds//16r10000) = rampIndex]] whileTrue:[
			idx _ x >> baseShift.
			spanBuffer at: idx put: (spanBuffer at: idx) + rampValue.
			x _ x + aaLevel.
			ds _ ds + (dsX << colorShift)].
		rampIndex _ ds // 16r10000.
	].

	"Deal with the last n sub-pixels"
	colorMask _ self aaColorMaskGet.
	colorShift _ self aaColorShiftGet.
	[x < rightX and:[rampIndex < rampSize and:[rampIndex>=0]]] whileTrue:[
		rampValue _ self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
		rampValue _ (rampValue bitAnd: colorMask) >> colorShift.
		"Copy as many pixels as possible"
		[x < rightX and:[(ds//16r10000) = rampIndex]] whileTrue:[
			idx _ x >> baseShift.
			spanBuffer at: idx put: (spanBuffer at: idx) + rampValue.
			x _ x + 1.
			ds _ ds + dsX].
		rampIndex _ ds // 16r10000.
	].
	^x
]

{ #category : #'accessing fills' }
BalloonEnginePlugin >> fillNormalXOf: fill [

	^self obj: fill at: GFNormalX
]

{ #category : #'accessing fills' }
BalloonEnginePlugin >> fillNormalXOf: fill put: value [

	^self obj: fill at: GFNormalX put: value
]

{ #category : #'accessing fills' }
BalloonEnginePlugin >> fillNormalYOf: fill [

	^self obj: fill at: GFNormalY
]

{ #category : #'accessing fills' }
BalloonEnginePlugin >> fillNormalYOf: fill put: value [

	^self obj: fill at: GFNormalY put: value
]

{ #category : #'accessing fills' }
BalloonEnginePlugin >> fillOriginXOf: fill [

	^self obj: fill at: GFOriginX
]

{ #category : #'accessing fills' }
BalloonEnginePlugin >> fillOriginXOf: fill put: value [

	^self obj: fill at: GFOriginX put: value
]

{ #category : #'accessing fills' }
BalloonEnginePlugin >> fillOriginYOf: fill [

	^self obj: fill at: GFOriginY
]

{ #category : #'accessing fills' }
BalloonEnginePlugin >> fillOriginYOf: fill put: value [

	^self obj: fill at: GFOriginY put: value
]

{ #category : #'fills-gradient' }
BalloonEnginePlugin >> fillRadialDecreasing: fill ramp: ramp deltaST: deltaST dsX: dsX dtX: dtX from: leftX to: rightX [
	"Part 2a) Compute the decreasing part of the ramp"
	| ds dt rampIndex rampValue length2 x x1 nextLength |
	self inline: true.
	ds _ (self cCoerce: deltaST to:'int*') at: 0.
	dt _ (self cCoerce: deltaST to:'int*') at: 1.
	rampIndex _ self accurateLengthOf: ds // 16r10000 with: dt // 16r10000.
	rampValue _ self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
	length2 _ (rampIndex-1) * (rampIndex-1).

	x _ leftX.
	x1 _ rightX.
	x1 > (self fillOriginXOf: fill) ifTrue:[x1 _ self fillOriginXOf: fill].
	[x < x1] whileTrue:[
		"Try to copy the current value more than just once"
		[x < x1 and:[(self squaredLengthOf: ds //  16r10000 with: dt // 16r10000) >= length2]]
			whileTrue:[	spanBuffer at: x put: rampValue.
						x _ x + 1.
						ds _ ds + dsX.
						dt _ dt + dtX].
		"Step to next ramp value"
		nextLength _ self squaredLengthOf: ds //  16r10000 with: dt // 16r10000.
		[nextLength < length2] whileTrue:[
			rampIndex _ rampIndex - 1.
			rampValue _ self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
			length2 _ (rampIndex-1) * (rampIndex-1).
		].
	].

	(self cCoerce: deltaST to: 'int *') at: 0 put: ds.
	(self cCoerce: deltaST to: 'int *') at: 1 put: dt.
	^x
]

{ #category : #'fills-gradient' }
BalloonEnginePlugin >> fillRadialDecreasingAA: fill ramp: ramp deltaST: deltaST dsX: dsX dtX: dtX from: leftX to: rightX [
	"Part 2a) Compute the decreasing part of the ramp"
	| ds dt rampIndex rampValue length2 x nextLength x1
	aaLevel colorMask colorShift baseShift index firstPixel lastPixel |
	self inline: false.
	self var: #ramp declareC:'int *ramp'.
	self var: #deltaST declareC:' int *deltaST'.

	ds _ (self cCoerce: deltaST to:'int*') at: 0.
	dt _ (self cCoerce: deltaST to:'int*') at: 1.
	aaLevel _ self aaLevelGet.
	baseShift _ self aaShiftGet.
	rampIndex _ self accurateLengthOf: ds // 16r10000 with: dt // 16r10000.
	length2 _ (rampIndex-1) * (rampIndex-1).

	x _ leftX.
	x1 _ self fillOriginXOf: fill.
	x1 > rightX ifTrue:[x1 _ rightX].
	firstPixel _ self aaFirstPixelFrom: leftX to: x1.
	lastPixel _ self aaLastPixelFrom: leftX to: x1.

	"Deal with the first n sub-pixels"
	(x < firstPixel) ifTrue:[
		colorMask _ self aaColorMaskGet.
		colorShift _ self aaColorShiftGet.
		rampValue _ self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
		rampValue _ (rampValue bitAnd: colorMask) >> colorShift.
		[x < firstPixel] whileTrue:[
			"Try to copy the current value more than just once"
			[x < firstPixel and:[(self squaredLengthOf: ds //  16r10000 with: dt // 16r10000) >= length2]]
				whileTrue:[	index _ x >> baseShift.
							spanBuffer at: index put: (spanBuffer at: index) + rampValue.
							x _ x + 1.
							ds _ ds + dsX.
							dt _ dt + dtX].
			"Step to next ramp value"
			nextLength _ self squaredLengthOf: ds //  16r10000 with: dt // 16r10000.
			[nextLength < length2] whileTrue:[
				rampIndex _ rampIndex - 1.
				rampValue _ self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
				rampValue _ (rampValue bitAnd: colorMask) >> colorShift.
				length2 _ (rampIndex-1) * (rampIndex-1).
			].
		].
	].

	"Deal with the full pixels"
	(x < lastPixel) ifTrue:[
		colorMask _ (self aaColorMaskGet >> self aaShiftGet) bitOr: 16rF0F0F0F0.
		colorShift _ self aaShiftGet.
		rampValue _ self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
		rampValue _ (rampValue bitAnd: colorMask) >> colorShift.
		[x < lastPixel] whileTrue:[
			"Try to copy the current value more than just once"
			[x < lastPixel and:[(self squaredLengthOf: ds //  16r10000 with: dt // 16r10000) >= length2]]
				whileTrue:[	index _ x >> baseShift.
							spanBuffer at: index put: (spanBuffer at: index) + rampValue.
							x _ x + aaLevel.
							ds _ ds + (dsX << colorShift).
							dt _ dt + (dtX << colorShift)].
			"Step to next ramp value"
			nextLength _ self squaredLengthOf: ds //  16r10000 with: dt // 16r10000.
			[nextLength < length2] whileTrue:[
				rampIndex _ rampIndex - 1.
				rampValue _ self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
				rampValue _ (rampValue bitAnd: colorMask) >> colorShift.
				length2 _ (rampIndex-1) * (rampIndex-1).
			].
		].
	].

	"Deal with the last n sub-pixels"
	(x < x1) ifTrue:[
		colorMask _ self aaColorMaskGet.
		colorShift _ self aaColorShiftGet.
		rampValue _ self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
		rampValue _ (rampValue bitAnd: colorMask) >> colorShift.
		[x < x1] whileTrue:[
			"Try to copy the current value more than just once"
			[x < x1 and:[(self squaredLengthOf: ds //  16r10000 with: dt // 16r10000) >= length2]]
				whileTrue:[	index _ x >> baseShift.
							spanBuffer at: index put: (spanBuffer at: index) + rampValue.
							x _ x + 1.
							ds _ ds + dsX.
							dt _ dt + dtX].
			"Step to next ramp value"
			nextLength _ self squaredLengthOf: ds //  16r10000 with: dt // 16r10000.
			[nextLength < length2] whileTrue:[
				rampIndex _ rampIndex - 1.
				rampValue _ self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
				rampValue _ (rampValue bitAnd: colorMask) >> colorShift.
				length2 _ (rampIndex-1) * (rampIndex-1).
			].
		].
	].
	"Done -- store stuff back"
	(self cCoerce: deltaST to: 'int *') at: 0 put: ds.
	(self cCoerce: deltaST to: 'int *') at: 1 put: dt.
	^x
]

{ #category : #'fills-gradient' }
BalloonEnginePlugin >> fillRadialGradient [
	self inline: true.
	^self fillRadialGradient: self lastExportedFillGet from: self lastExportedLeftXGet to: self lastExportedRightXGet at: self currentYGet
]

{ #category : #'fills-gradient' }
BalloonEnginePlugin >> fillRadialGradient: fill from: leftX to: rightX at: yValue [
	"Draw a radial gradient fill."
	| x x1 ramp rampSize dsX ds dtX dt length2 deltaX deltaY deltaST |
	self inline: false.
	self var: #ramp declareC:'int *ramp'.
	self var: #deltaST declareC:'int *deltaST'.

	ramp _ self gradientRampOf: fill.
	rampSize _ self gradientRampLengthOf: fill.

	deltaX _ leftX - (self fillOriginXOf: fill).
	deltaY _ yValue - (self fillOriginYOf: fill).

	dsX _ self fillDirectionXOf: fill.
	dtX _ self fillNormalXOf: fill.

	ds _ (deltaX * dsX) + (deltaY * (self fillDirectionYOf: fill)).
	dt _ (deltaX * dtX) + (deltaY * (self fillNormalYOf: fill)).

	x _ leftX.
	x1 _ rightX.

	"Note: The inner loop has been divided into three parts for speed"
	"Part one: Fill everything outside the left boundary"
	length2 _ (rampSize-1) * (rampSize-1). "This is the upper bound"
	[(self squaredLengthOf: ds // 16r10000 with: dt // 16r10000) >= length2 and:[x < x1]]
		whileTrue:[	x _ x + 1.	ds _ ds + dsX.	dt _ dt + dtX].
	x > leftX ifTrue:[self fillColorSpan: (self makeUnsignedFrom: (ramp at: rampSize-1)) from: leftX to: x].

	"Part two: Fill everything inside the boundaries"
	deltaST _ self point1Get.
	deltaST at: 0 put: ds.
	deltaST at: 1 put: dt.
	(x < (self fillOriginXOf: fill)) ifTrue:[
		"Draw the decreasing part"
		self aaLevelGet = 1 
			ifTrue:[x _ self fillRadialDecreasing: fill ramp: ramp deltaST: deltaST 
							dsX: dsX dtX: dtX from: x to: x1]
			ifFalse:[x _ self fillRadialDecreasingAA: fill ramp: ramp deltaST: deltaST 
							dsX: dsX dtX: dtX from: x to: x1].
	].
	x < x1 ifTrue:[
		"Draw the increasing part"
		self aaLevelGet = 1
			ifTrue:[x _ self fillRadialIncreasing: fill ramp: ramp deltaST: deltaST
							dsX: dsX dtX: dtX from: x to: x1]
			ifFalse:[x _ self fillRadialIncreasingAA: fill ramp: ramp deltaST: deltaST
							dsX: dsX dtX: dtX from: x to: x1].
	].

	"Part three fill everything outside right boundary"
	x < rightX ifTrue:[self fillColorSpan: (self makeUnsignedFrom: (ramp at: rampSize-1)) from: x to: rightX].

]

{ #category : #'fills-gradient' }
BalloonEnginePlugin >> fillRadialIncreasing: fill ramp: ramp deltaST: deltaST dsX: dsX dtX: dtX from: leftX to: rightX [
	"Part 2b) Compute the increasing part of the ramp"
	| ds dt rampIndex rampValue length2 x x1 nextLength rampSize lastLength |
	self inline: true.
	ds _ (self cCoerce: deltaST to:'int*') at: 0.
	dt _ (self cCoerce: deltaST to:'int*') at: 1.
	rampIndex _ self accurateLengthOf: ds // 16r10000 with: dt // 16r10000.
	rampValue _ self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
	rampSize _ self gradientRampLengthOf: fill.
	length2 _ (rampSize-1) * (rampSize-1). "This is the upper bound"
	nextLength _ (rampIndex+1) * (rampIndex+1).
	lastLength _ self squaredLengthOf: ds //  16r10000 with: dt // 16r10000.

	x _ leftX.
	x1 _ rightX.

	[x < x1 and:[lastLength < length2]] whileTrue:[
		"Try to copy the current value more than once"
		[x < x1 and:[(self squaredLengthOf: ds //  16r10000 with: dt // 16r10000) <= nextLength]]
			whileTrue:[	spanBuffer at: x put: rampValue.
						x _ x + 1.
						ds _ ds + dsX.
						dt _ dt + dtX].
		lastLength _ self squaredLengthOf: ds //  16r10000 with: dt // 16r10000.
		[lastLength > nextLength] whileTrue:[
			rampIndex _ rampIndex + 1.
			rampValue _ self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
			nextLength _ (rampIndex+1) * (rampIndex+1).
		].
	].

	(self cCoerce: deltaST to: 'int *') at: 0 put: ds.
	(self cCoerce: deltaST to: 'int *') at: 1 put: dt.
	^x
]

{ #category : #'fills-gradient' }
BalloonEnginePlugin >> fillRadialIncreasingAA: fill ramp: ramp deltaST: deltaST dsX: dsX dtX: dtX from: leftX to: rightX [
	"Part 2b) Compute the increasing part of the ramp"
	| ds dt rampIndex rampValue length2 x nextLength rampSize lastLength 
	aaLevel colorMask colorShift baseShift index firstPixel lastPixel |
	self inline: false.
	self var: #ramp declareC:'int *ramp'.
	self var: #deltaST declareC:' int *deltaST'.

	ds _ (self cCoerce: deltaST to:'int*') at: 0.
	dt _ (self cCoerce: deltaST to:'int*') at: 1.
	aaLevel _ self aaLevelGet.
	baseShift _ self aaShiftGet.
	rampIndex _ self accurateLengthOf: ds // 16r10000 with: dt // 16r10000.
	rampSize _ self gradientRampLengthOf: fill.
	length2 _ (rampSize-1) * (rampSize-1). "This is the upper bound"
	nextLength _ (rampIndex+1) * (rampIndex+1).
	lastLength _ self squaredLengthOf: ds //  16r10000 with: dt // 16r10000.

	x _ leftX.

	firstPixel _ self aaFirstPixelFrom: leftX to: rightX.
	lastPixel _ self aaLastPixelFrom: leftX to: rightX.

	"Deal with the first n subPixels"
	(x < firstPixel and:[lastLength < length2]) ifTrue:[
		colorMask _ self aaColorMaskGet.
		colorShift _ self aaColorShiftGet.
		rampValue _ self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
		rampValue _ (rampValue bitAnd: colorMask) >> colorShift.
		[x < firstPixel and:[lastLength < length2]] whileTrue:[
			"Try to copy the current value more than once"
			[x < firstPixel and:[(self squaredLengthOf: ds //  16r10000 with: dt // 16r10000) <= nextLength]]
				whileTrue:[	index _ x >> baseShift.
							spanBuffer at: index put: (spanBuffer at: index) + rampValue.
							x _ x + 1.
							ds _ ds + dsX.
							dt _ dt + dtX].
			lastLength _ self squaredLengthOf: ds //  16r10000 with: dt // 16r10000.
			[lastLength > nextLength] whileTrue:[
				rampIndex _ rampIndex + 1.
				rampValue _ self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
				rampValue _ (rampValue bitAnd: colorMask) >> colorShift.
				nextLength _ (rampIndex+1) * (rampIndex+1).
			].
		].
	].

	"Deal with the full pixels"
	(x < lastPixel and:[lastLength < length2]) ifTrue:[
		colorMask _ (self aaColorMaskGet >> self aaShiftGet) bitOr: 16rF0F0F0F0.
		colorShift _ self aaShiftGet.
		rampValue _ self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
		rampValue _ (rampValue bitAnd: colorMask) >> colorShift.
		[x < lastPixel and:[lastLength < length2]] whileTrue:[
			"Try to copy the current value more than once"
			[x < lastPixel and:[(self squaredLengthOf: ds //  16r10000 with: dt // 16r10000) <= nextLength]]
				whileTrue:[	index _ x >> baseShift.
							spanBuffer at: index put: (spanBuffer at: index) + rampValue.
							x _ x + aaLevel.
							ds _ ds + (dsX << colorShift).
							dt _ dt + (dtX << colorShift)].
			lastLength _ self squaredLengthOf: ds //  16r10000 with: dt // 16r10000.
			[lastLength > nextLength] whileTrue:[
				rampIndex _ rampIndex + 1.
				rampValue _ self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
				rampValue _ (rampValue bitAnd: colorMask) >> colorShift.
				nextLength _ (rampIndex+1) * (rampIndex+1).
			].
		].
	].

	"Deal with last n sub-pixels"
	(x < rightX and:[lastLength < length2]) ifTrue:[
		colorMask _ self aaColorMaskGet.
		colorShift _ self aaColorShiftGet.
		rampValue _ self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
		rampValue _ (rampValue bitAnd: colorMask) >> colorShift.
		[x < rightX and:[lastLength < length2]] whileTrue:[
			"Try to copy the current value more than once"
			[x < rightX and:[(self squaredLengthOf: ds //  16r10000 with: dt // 16r10000) <= nextLength]]
				whileTrue:[	index _ x >> baseShift.
							spanBuffer at: index put: (spanBuffer at: index) + rampValue.
							x _ x + 1.
							ds _ ds + dsX.
							dt _ dt + dtX].
			lastLength _ self squaredLengthOf: ds //  16r10000 with: dt // 16r10000.
			[lastLength > nextLength] whileTrue:[
				rampIndex _ rampIndex + 1.
				rampValue _ self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
				rampValue _ (rampValue bitAnd: colorMask) >> colorShift.
				nextLength _ (rampIndex+1) * (rampIndex+1).
			].
		].
	].
	"Done -- store stuff back"
	(self cCoerce: deltaST to: 'int *') at: 0 put: ds.
	(self cCoerce: deltaST to: 'int *') at: 1 put: dt.
	^x
]

{ #category : #'accessing gradients' }
BalloonEnginePlugin >> gradientRampLengthOf: fill [

	^self obj: fill at: GFRampLength
]

{ #category : #'accessing gradients' }
BalloonEnginePlugin >> gradientRampLengthOf: fill put: value [

	^self obj: fill at: GFRampLength put: value
]

{ #category : #'accessing gradients' }
BalloonEnginePlugin >> gradientRampOf: fill [
	self returnTypeC:'int *'.

	^objBuffer + fill +  GFRampOffset
]

{ #category : #testing }
BalloonEnginePlugin >> isBezier: bezier [
	^((self objectTypeOf: bezier) bitAnd: GEPrimitiveWideMask) = GEPrimitiveBezier
]

{ #category : #testing }
BalloonEnginePlugin >> isFillOkay: fill [
	self inline: false.
	^(fill = 0 or:[(self isFillColor: fill) or:[((self isObject: fill) and:[self isFill: fill])]]) 

]

{ #category : #testing }
BalloonEnginePlugin >> isLine: line [
	^((self objectTypeOf: line) bitAnd: GEPrimitiveWideMask) = GEPrimitiveLine
]

{ #category : #testing }
BalloonEnginePlugin >> isWideBezier: bezier [
	^(self isBezier: bezier) and:[self isWide: bezier]
]

{ #category : #testing }
BalloonEnginePlugin >> isWideLine: line [
	^(self isLine: line) and:[self isWide: line]
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> lineEndXOf: line [

	^self obj: line at: GLEndX
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> lineEndXOf: line put: value [

	^self obj: line at: GLEndX put: value
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> lineEndYOf: line [

	^self obj: line at: GLEndY
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> lineEndYOf: line put: value [

	^self obj: line at: GLEndY put: value
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> lineErrorAdjDownOf: line [

	^self obj: line at: GLErrorAdjDown
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> lineErrorAdjDownOf: line put: value [

	^self obj: line at: GLErrorAdjDown put: value
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> lineErrorAdjUpOf: line [

	^self obj: line at: GLErrorAdjUp
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> lineErrorAdjUpOf: line put: value [

	^self obj: line at: GLErrorAdjUp put: value
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> lineErrorOf: line [

	^self obj: line at: GLError
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> lineErrorOf: line put: value [

	^self obj: line at: GLError put: value
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> lineXDirectionOf: line [

	^self obj: line at: GLXDirection
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> lineXDirectionOf: line put: value [

	^self obj: line at: GLXDirection put: value
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> lineXIncrementOf: line [

	^self obj: line at: GLXIncrement
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> lineXIncrementOf: line put: value [

	^self obj: line at: GLXIncrement put: value
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> lineYDirectionOf: line [

	^self obj: line at: GLYDirection
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> lineYDirectionOf: line put: value [

	^self obj: line at: GLYDirection put: value
]

{ #category : #'bezier-loading' }
BalloonEnginePlugin >> loadAndSubdivideBezierFrom: point1 via: point2 to: point3 isWide: wideFlag [
	"Load and subdivide the bezier curve from point1/point2/point3.
	If wideFlag is set then make sure the curve is monoton in X."
	| bz1 bz2 index2 index1 |
	self inline: false.
	self var: #point1 declareC:'int *point1'.
	self var: #point2 declareC:'int *point2'.
	self var: #point3 declareC:'int *point3'.
	bz1 _ self allocateBezierStackEntry.	
	engineStopped ifTrue:[^0].
	"Load point1/point2/point3 on the top of the stack"
	self bzStartX: bz1 put: (point1 at: 0).
	self bzStartY: bz1 put: (point1 at: 1).
	self bzViaX: bz1 put: (point2 at: 0).
	self bzViaY: bz1 put: (point2 at: 1).
	self bzEndX: bz1 put: (point3 at: 0).
	self bzEndY: bz1 put: (point3 at: 1).

	"Now check if the bezier curve is monoton. If not, subdivide it."
	index2 _ bz2 _ self subdivideToBeMonoton: bz1 inX: wideFlag.
	bz1 to: bz2 by: 6 do:[:index|
		index1 _ self subdivideBezierFrom: index.
		index1 > index2 ifTrue:[index2 _ index1].
		engineStopped ifTrue:[^0]. "Something went wrong"
	].
	"Return the number of segments"
	^index2 // 6
]

{ #category : #'shapes-polygons' }
BalloonEnginePlugin >> loadArrayPolygon: points nPoints: nPoints fill: fillIndex lineWidth: lineWidth lineFill: lineFill [
	| x0 y0 x1 y1 |
	self loadPoint: self point1Get from: (interpreterProxy fetchPointer: 0 ofObject: points).
	interpreterProxy failed ifTrue:[^nil].
	x0 _ self point1Get at: 0.
	y0 _ self point1Get at: 1.
	1 to: nPoints-1 do:[:i|
		self loadPoint: self point1Get from: (interpreterProxy fetchPointer: i ofObject: points).
		interpreterProxy failed ifTrue:[^nil].
		x1 _ self point1Get at: 0.
		y1 _ self point1Get at: 1.
		self point1Get at: 0 put: x0.
		self point1Get at: 1 put: y0.
		self point2Get at: 0 put: x1.
		self point2Get at: 1 put: y1.
		self transformPoints: 2.
		self loadWideLine: lineWidth 
			from: self point1Get
			to: self point2Get
			lineFill: lineFill 
			leftFill: fillIndex
			rightFill: 0.
		engineStopped ifTrue:[^nil].
		x0 _ x1.
		y0 _ y1.
	].
]

{ #category : #'shapes-polygons' }
BalloonEnginePlugin >> loadArrayShape: points nSegments: nSegments fill: fillIndex lineWidth: lineWidth lineFill: lineFill [ 
	| pointOop x0 y0 x1 y1 x2 y2 segs |
	self inline: false.
	0 to: nSegments-1 do:[:i|
		pointOop _ interpreterProxy fetchPointer: (i * 3) ofObject: points.
		self loadPoint: self point1Get from: pointOop.
		pointOop _ interpreterProxy fetchPointer: (i * 3 + 1) ofObject: points.
		self loadPoint: self point2Get from: pointOop.
		pointOop _ interpreterProxy fetchPointer: (i * 3 + 2) ofObject: points.
		self loadPoint: self point3Get from: pointOop.
		interpreterProxy failed ifTrue:[^nil].
		self transformPoints: 3.
		x0 _ self point1Get at: 0.
		y0 _ self point1Get at: 1.
		x1 _ self point2Get at: 0.
		y1 _ self point2Get at: 1.
		x2 _ self point3Get at: 0.
		y2 _ self point3Get at: 1.
		"Check if we can use a line"
		((x0 = y0 and:[x1 = y1]) or:[x1 = x2 and:[y1 = y2]]) ifTrue:[
			self loadWideLine: lineWidth
				from: self point1Get
				to: self point3Get
				lineFill: lineFill
				leftFill: fillIndex
				rightFill: 0.
		] ifFalse:["Need bezier"
			segs _ self loadAndSubdivideBezierFrom: self point1Get
					via: self point2Get
					to: self point3Get
					isWide: (lineWidth ~= 0 and:[lineFill ~= 0]).
			engineStopped ifTrue:[^nil].
			self loadWideBezier: lineWidth
				lineFill: lineFill
				leftFill: fillIndex
				rightFill: 0
				n: segs.
		].
		engineStopped ifTrue:[^nil].
	].
]

{ #category : #'bezier-loading' }
BalloonEnginePlugin >> loadBezier: bezier segment: index leftFill: leftFillIndex rightFill: rightFillIndex offset: yOffset [
	"Initialize the bezier segment stored on the stack"
	self inline: false.
	(self bzEndY: index) >= (self bzStartY: index) ifTrue:[
		"Top to bottom"
		self edgeXValueOf: bezier put: (self bzStartX: index).
		self edgeYValueOf: bezier put: (self bzStartY: index) - yOffset.
		self bezierViaXOf: bezier put: (self bzViaX: index).
		self bezierViaYOf: bezier put: (self bzViaY: index) - yOffset.
		self bezierEndXOf: bezier put: (self bzEndX: index).
		self bezierEndYOf: bezier put: (self bzEndY: index) - yOffset.
	] ifFalse:[
		self edgeXValueOf: bezier put: (self bzEndX: index).
		self edgeYValueOf: bezier put: (self bzEndY: index) - yOffset.
		self bezierViaXOf: bezier put: (self bzViaX: index).
		self bezierViaYOf: bezier put: (self bzViaY: index) - yOffset.
		self bezierEndXOf: bezier put: (self bzStartX: index).
		self bezierEndYOf: bezier put: (self bzStartY: index) - yOffset.
	].
	self edgeZValueOf: bezier put: self currentZGet.
	self edgeLeftFillOf: bezier put: leftFillIndex.
	self edgeRightFillOf: bezier put: rightFillIndex.
	"self debugDrawBezier: bezier."
]

{ #category : #'fills-bitmaps' }
BalloonEnginePlugin >> loadBitmapFill: formOop colormap: cmOop tile: tileFlag from: point1 along: point2 normal: point3 xIndex: xIndex [
	"Load the bitmap fill."
	| bmFill cmSize cmBits bmBits bmBitsSize bmWidth bmHeight bmDepth ppw bmRaster |
	self var: #cmBits declareC:'int *cmBits'.
	self var: #point1 declareC:'int *point1'.
	self var: #point2 declareC:'int *point2'.
	self var: #point3 declareC:'int *point3'.

	cmOop == interpreterProxy nilObject ifTrue:[
		cmSize _ 0.
		cmBits _ nil.
	] ifFalse:[
		(interpreterProxy fetchClassOf: cmOop) == interpreterProxy classBitmap
			ifFalse:[^interpreterProxy primitiveFail].
		cmSize _ interpreterProxy slotSizeOf: cmOop.
		cmBits _ interpreterProxy firstIndexableField: cmOop.
	].
	(interpreterProxy isIntegerObject: formOop) 
		ifTrue:[^interpreterProxy primitiveFail].
	(interpreterProxy isPointers: formOop) 
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy slotSizeOf: formOop) < 5 
		ifTrue:[^interpreterProxy primitiveFail].
	bmBits _ interpreterProxy fetchPointer: 0 ofObject: formOop.
	(interpreterProxy fetchClassOf: bmBits) == interpreterProxy classBitmap
		ifFalse:[^interpreterProxy primitiveFail].
	bmBitsSize _ interpreterProxy slotSizeOf: bmBits.
	bmWidth _ interpreterProxy fetchInteger: 1 ofObject: formOop.
	bmHeight _ interpreterProxy fetchInteger: 2 ofObject: formOop.
	bmDepth _ interpreterProxy fetchInteger: 3 ofObject: formOop.
	interpreterProxy failed ifTrue:[^nil].
	(bmWidth >= 0 and:[bmHeight >= 0]) ifFalse:[^interpreterProxy primitiveFail].
	(bmDepth = 32) | (bmDepth = 8) | (bmDepth = 16) | 
		(bmDepth = 1) | (bmDepth = 2) | (bmDepth = 4)
			ifFalse:[^interpreterProxy primitiveFail].
	(cmSize = 0 or:[cmSize = (1 << bmDepth)])
		ifFalse:[^interpreterProxy primitiveFail].
	ppw _ 32 // bmDepth.
	bmRaster _ bmWidth + (ppw-1) // ppw.
	bmBitsSize = (bmRaster * bmHeight)
		ifFalse:[^interpreterProxy primitiveFail].
	bmFill _ self allocateBitmapFill: cmSize colormap: cmBits.
	engineStopped ifTrue:[^nil].
	self bitmapWidthOf: bmFill put: bmWidth.
	self bitmapHeightOf: bmFill put: bmHeight.
	self bitmapDepthOf: bmFill put: bmDepth.
	self bitmapRasterOf: bmFill put: bmRaster.
	self bitmapSizeOf: bmFill put: bmBitsSize.
	self bitmapTileFlagOf: bmFill put: tileFlag.
	self objectIndexOf: bmFill put: xIndex.
	self loadFillOrientation: bmFill
		from: point1 along: point2 normal: point3
		width: bmWidth height: bmHeight.
	^bmFill
]

{ #category : #'fills-bitmaps' }
BalloonEnginePlugin >> loadBitsFrom: bmFill [
	"Note: Assumes that the contents of formArray has been checked before"
	| xIndex formOop bitsOop bitsLen |
	self returnTypeC:'int *'.
	xIndex _ self objectIndexOf: bmFill.
	xIndex > (interpreterProxy slotSizeOf: formArray) ifTrue:[^nil].
	formOop _ interpreterProxy fetchPointer: xIndex ofObject: formArray.
	bitsOop _ interpreterProxy fetchPointer: 0 ofObject: formOop.
	bitsLen _ interpreterProxy slotSizeOf: bitsOop.
	bitsLen = (self bitmapSizeOf: bmFill) ifFalse:[^nil].
	^interpreterProxy firstIndexableField: bitsOop
]

{ #category : #'shapes-compressed' }
BalloonEnginePlugin >> loadCompressedSegment: segmentIndex from: points short: pointsShort leftFill: leftFill rightFill: rightFill lineWidth: lineWidth lineColor: lineFill [ 
	"Load the compressed segment identified by segment index"
	| x0 y0 x1 y1 x2 y2 index segs |
	self inline: true.

	"Check if have anything to do at all"
	(leftFill = rightFill and:[lineWidth = 0 or:[lineFill = 0]]) 
		ifTrue:[^nil]. "Nothing to do"

	index _ segmentIndex * 6. "3 points with x/y each"
	pointsShort ifTrue:["Load short points"
		x0 _ self loadPointShortAt: (index+0) from: points.
		y0 _ self loadPointShortAt: (index+1) from: points.
		x1 _ self loadPointShortAt: (index+2) from: points.
		y1 _ self loadPointShortAt: (index+3) from: points.
		x2 _ self loadPointShortAt: (index+4) from: points.
		y2 _ self loadPointShortAt: (index+5) from: points.
	] ifFalse:[
		x0 _ self loadPointIntAt: (index+0) from: points.
		y0 _ self loadPointIntAt: (index+1) from: points.
		x1 _ self loadPointIntAt: (index+2) from: points.
		y1 _ self loadPointIntAt: (index+3) from: points.
		x2 _ self loadPointIntAt: (index+4) from: points.
		y2 _ self loadPointIntAt: (index+5) from: points.
	].
	"Briefly check if can represent the bezier as a line"
	((x0 = x1 and:[y0 = y1]) or:[x1 = x2 and:[y1 = y2]]) ifTrue:[
		"We can use a line from x0/y0 to x2/y2"
		(x0 = x2 and:[y0 = y2]) ifTrue:[^nil]. "Nothing to do"
		"Load and transform points"
		self point1Get at: 0 put: x0.
		self point1Get at: 1 put: y0.
		self point2Get at: 0 put: x2.
		self point2Get at: 1 put: y2.
		self transformPoints: 2.
		^self loadWideLine: lineWidth 
			from: self point1Get
			to: self point2Get
			lineFill: lineFill 
			leftFill: leftFill 
			rightFill: rightFill.
	].
	"Need bezier curve"
	"Load and transform points"
	self point1Get at: 0 put: x0.
	self point1Get at: 1 put: y0.
	self point2Get at: 0 put: x1.
	self point2Get at: 1 put: y1.
	self point3Get at: 0 put: x2.
	self point3Get at: 1 put: y2.
	self transformPoints: 3.
	segs _ self loadAndSubdivideBezierFrom: self point1Get 
				via: self point2Get 
				to: self point3Get 
				isWide: (lineWidth ~= 0 and:[lineFill ~= 0]).
	engineStopped ifTrue:[^nil].
	self loadWideBezier: lineWidth lineFill: lineFill leftFill: leftFill rightFill: rightFill n: segs.

]

{ #category : #'shapes-compressed' }
BalloonEnginePlugin >> loadCompressedShape: points segments: nSegments leftFills: leftFills rightFills: rightFills lineWidths: lineWidths lineFills: lineFills fillIndexList: fillIndexList pointShort: pointsShort [
	"Load a compressed shape into the engine.
		WARNING: THIS METHOD NEEDS THE FULL FRAME SIZE!!!!
	"
	| leftRun rightRun widthRun lineFillRun
	leftLength rightLength widthLength lineFillLength
	leftValue rightValue widthValue lineFillValue |

	self inline: false. "Don't you!!!!"

	self var: #points declareC:'int *points'.
	self var: #leftFills declareC:'int *leftFills'.
	self var: #rightFills declareC:'int *rightFills'.
	self var: #lineWidths declareC:'int *lineWidths'.
	self var: #lineFills declareC:'int *lineFills'.
	self var: #fillIndexList declareC:'int *fillIndexList'.

	nSegments = 0 ifTrue:[^0].

	"Initialize run length encodings"
	leftRun _  rightRun _ widthRun _ lineFillRun _ -1.
	leftLength _ rightLength _ widthLength _ lineFillLength _ 1.
	leftValue _ rightValue _ widthValue _ lineFillValue _ 0.

	1 to: nSegments do:[:i|
		"Decrement current run length and load new stuff"
		(leftLength _ leftLength - 1) <= 0 ifTrue:[
			leftRun _ leftRun + 1.
			leftLength _ self shortRunLengthAt: leftRun from: leftFills.
			leftValue _ self shortRunValueAt: leftRun from: leftFills.
			leftValue = 0 ifFalse:[
				leftValue _ fillIndexList at: leftValue-1.
				leftValue _ self transformColor: leftValue.
				engineStopped ifTrue:[^nil]]].
		(rightLength _ rightLength - 1) <= 0 ifTrue:[
			rightRun _ rightRun + 1.
			rightLength _ self shortRunLengthAt: rightRun from: rightFills.
			rightValue _ self shortRunValueAt: rightRun from: rightFills.
			rightValue = 0 ifFalse:[
				rightValue _ fillIndexList at: rightValue-1.
				rightValue _ self transformColor: rightValue]].
		(widthLength _ widthLength - 1) <= 0 ifTrue:[
			widthRun _ widthRun + 1.
			widthLength _ self shortRunLengthAt: widthRun from: lineWidths.
			widthValue _ self shortRunValueAt: widthRun from: lineWidths.
			widthValue = 0 ifFalse:[widthValue _ self transformWidth: widthValue]].
		(lineFillLength _ lineFillLength - 1) <= 0 ifTrue:[
			lineFillRun _ lineFillRun + 1.
			lineFillLength _ self shortRunLengthAt: lineFillRun from: lineFills.
			lineFillValue _ self shortRunValueAt: lineFillRun from: lineFills.
			lineFillValue = 0 ifFalse:[lineFillValue _ fillIndexList at: lineFillValue-1]].
		self loadCompressedSegment: i - 1
			from: points 
			short: pointsShort 
			leftFill: leftValue 
			rightFill: rightValue 
			lineWidth: widthValue 
			lineColor: lineFillValue.
		engineStopped ifTrue:[^nil].
	].
]

{ #category : #'fills-gradient' }
BalloonEnginePlugin >> loadFillOrientation: fill from: point1 along: point2 normal: point3 width: fillWidth height: fillHeight [
	"Transform the points"
	| dirX dirY nrmX nrmY dsLength2 dsX dsY dtLength2 dtX dtY |
	self var: #point1 declareC:'int *point1'.
	self var: #point2 declareC:'int *point2'.
	self var: #point3 declareC:'int *point3'.

	point2 at: 0 put: (point2 at: 0) + (point1 at: 0).
	point2 at: 1 put: (point2 at: 1) + (point1 at: 1).
	point3 at: 0 put: (point3 at: 0) + (point1 at: 0).
	point3 at: 1 put: (point3 at: 1) + (point1 at: 1).
	self transformPoint: point1.
	self transformPoint: point2.
	self transformPoint: point3.
	dirX _ (point2 at: 0) - (point1 at: 0).
	dirY _ (point2 at: 1) - (point1 at: 1).
	nrmX _ (point3 at: 0) - (point1 at: 0).
	nrmY _ (point3 at: 1) - (point1 at: 1).

	"Compute the scale from direction/normal into ramp size"
	dsLength2 _ (dirX * dirX) + (dirY * dirY).
	dsLength2 > 0 ifTrue:[
		dsX _ (dirX asFloat * fillWidth asFloat * 65536.0 / dsLength2 asFloat) asInteger.
		dsY _ (dirY asFloat * fillWidth asFloat * 65536.0 / dsLength2 asFloat) asInteger.
	] ifFalse:[ dsX _ 0. dsY _ 0].
	dtLength2 _ (nrmX * nrmX) + (nrmY * nrmY).
	dtLength2 > 0 ifTrue:[
		dtX _ (nrmX asFloat * fillHeight asFloat * 65536.0 / dtLength2 asFloat) asInteger.
		dtY _ (nrmY asFloat * fillHeight asFloat * 65536.0 / dtLength2 asFloat) asInteger.
	] ifFalse:[dtX _ 0. dtY _ 0].
	self fillOriginXOf: fill put: (point1 at: 0).
	self fillOriginYOf: fill put: (point1 at: 1).
	self fillDirectionXOf: fill put: dsX.
	self fillDirectionYOf: fill put: dsY.
	self fillNormalXOf: fill put: dtX.
	self fillNormalYOf: fill put: dtY.

]

{ #category : #'fills-gradient' }
BalloonEnginePlugin >> loadGradientFill: rampOop from: point1 along: point2 normal: point3 isRadial: isRadial [
	"Load the gradient fill as defined by the color ramp."
	| rampWidth fill |
	self inline: false.
	self var: #point1 declareC:'int *point1'.
	self var: #point2 declareC:'int *point2'.
	self var: #point3 declareC:'int *point3'.
	(interpreterProxy fetchClassOf: rampOop) = interpreterProxy classBitmap
		ifFalse:[^interpreterProxy primitiveFail].
	rampWidth _ interpreterProxy slotSizeOf: rampOop.
	fill _ self allocateGradientFill: (interpreterProxy firstIndexableField: rampOop)
				rampWidth: rampWidth isRadial: isRadial.
	engineStopped ifTrue:[^nil].
	self loadFillOrientation: fill 
		from: point1 along: point2 normal: point3 
		width: rampWidth height: rampWidth.
	^fill
]

{ #category : #'lines-loading' }
BalloonEnginePlugin >> loadLine: line from: point1 to: point2 offset: yOffset leftFill: leftFill rightFill: rightFill [
	"Load the line defined by point1 and point2."
	| p1 p2 yDir |
	self var: #point1 declareC:'int *point1'.
	self var: #point2 declareC:'int *point2'.
	self var: #p1 declareC:'int *p1'.
	self var: #p2 declareC:'int *p2'.

	(point1 at: 1) <= (point2 at: 1) 
		ifTrue:[	p1 _ point1.
				p2 _ point2.
				yDir _ 1]
		ifFalse:[	p1 _ point2.
				p2 _ point1.
				yDir _ -1].
	self edgeXValueOf: line put: (p1 at: 0).
	self edgeYValueOf: line put: (p1 at: 1) - yOffset.
	self edgeZValueOf: line put: self currentZGet.
	self edgeLeftFillOf: line put: leftFill.
	self edgeRightFillOf: line put: rightFill.
	self lineEndXOf: line put: (p2 at: 0).
	self lineEndYOf: line put: (p2 at: 1) - yOffset.
	self lineYDirectionOf: line put: yDir.
]

{ #category : #'bezier-loading' }
BalloonEnginePlugin >> loadOval: lineWidth lineFill: lineFill leftFill: leftFill rightFill: rightFill [
	"Load a rectangular oval currently defined by point1/point2"
	| w h cx cy nSegments |
	self inline: false.
	w _ ((self point2Get at: 0) - (self point1Get at: 0)) // 2.
	h _ ((self point2Get at: 1) - (self point1Get at: 1)) // 2.
	cx _ ((self point2Get at: 0) + (self point1Get at: 0)) // 2.
	cy _ ((self point2Get at: 1) + (self point1Get at: 1)) // 2.
	0 to: 15 do:[:i|
		self loadOvalSegment: i w: w h: h cx: cx cy: cy.
		self transformPoints: 3.
		nSegments _ self loadAndSubdivideBezierFrom: self point1Get 
							via: self point2Get to: self point3Get
							isWide: (lineWidth ~= 0 and:[lineFill ~= 0]).
		engineStopped ifTrue:[^nil].
		self loadWideBezier: lineWidth lineFill: lineFill 
			leftFill: leftFill rightFill: rightFill n: nSegments.
		engineStopped ifTrue:[^nil].
	].
]

{ #category : #'bezier-loading' }
BalloonEnginePlugin >> loadOvalSegment: seg w: w h: h cx: cx cy: cy [
	| x0 y0 x2 y2 x1 y1 |
	self inline: false.
	"Load start point of segment"
	x0 _ ((self circleCosTable at: seg * 2 + 0) * w asFloat + cx) asInteger.
	y0 _ ((self circleSinTable at: seg * 2 + 0) * h asFloat + cy) asInteger.
	self point1Get at: 0 put: x0.
	self point1Get at: 1 put: y0.
	"Load end point of segment"
	x2 _ ((self circleCosTable at: seg * 2 + 2) * w asFloat + cx) asInteger.
	y2 _ ((self circleSinTable at: seg * 2 + 2) * h asFloat + cy) asInteger.
	self point3Get at: 0 put: x2.
	self point3Get at: 1 put: y2.
	"Load intermediate point of segment"
	x1 _ ((self circleCosTable at: seg * 2 + 1) * w asFloat + cx) asInteger.
	y1 _ ((self circleSinTable at: seg * 2 + 1) * h asFloat + cy) asInteger.
	"NOTE: The intermediate point is the point ON the curve
	and not yet the control point (which is OFF the curve)"
	x1 _ (x1 * 2) - (x0 + x2 // 2).
	y1 _ (y1 * 2) - (y0 + y2 // 2).
	self point2Get at: 0 put: x1.
	self point2Get at: 1 put: y1.
]

{ #category : #private }
BalloonEnginePlugin >> loadPointIntAt: index from: intArray [
	"Load the int value from the given index in intArray"
	^(self cCoerce: intArray to: 'int *') at: index
]

{ #category : #private }
BalloonEnginePlugin >> loadPointShortAt: index from: shortArray [
	"Load the short value from the given index in shortArray"
	self returnTypeC:'short'.
	^(self cCoerce: shortArray to: 'short *') at: index
]

{ #category : #'shapes-polygons' }
BalloonEnginePlugin >> loadPolygon: points nPoints: nPoints fill: fillIndex lineWidth: lineWidth lineFill: lineFill pointsShort: isShort [
	| x0 y0 x1 y1 |
	self var:#points declareC:'int *points'.
	isShort ifTrue:[
		x0 _ self loadPointShortAt: 0 from: points.
		y0 _ self loadPointShortAt: 1 from: points.
	] ifFalse:[
		x0 _ self loadPointIntAt: 0 from: points.
		y0 _ self loadPointIntAt: 1 from: points.
	].
	1 to: nPoints-1 do:[:i|
		isShort ifTrue:[
			x1 _ self loadPointShortAt: i*2 from: points.
			y1 _ self loadPointShortAt: i*2+1 from: points.
		] ifFalse:[
			x1 _ self loadPointIntAt: i*2 from: points.
			y1 _ self loadPointIntAt: i*2+1 from: points.
		].
		self point1Get at: 0 put: x0.
		self point1Get at: 1 put: y0.
		self point2Get at: 0 put: x1.
		self point2Get at: 1 put: y1.
		self transformPoints: 2.
		self loadWideLine: lineWidth 
			from: self point1Get
			to: self point2Get
			lineFill: lineFill 
			leftFill: fillIndex
			rightFill: 0.
		engineStopped ifTrue:[^nil].
		x0 _ x1.
		y0 _ y1.
	].
]

{ #category : #'lines-loading' }
BalloonEnginePlugin >> loadRectangle: lineWidth lineFill: lineFill leftFill: leftFill rightFill: rightFill [
	"Load a rectangle currently defined by point1-point4"

	self loadWideLine: lineWidth from: self point1Get to: self point2Get
		lineFill: lineFill leftFill: leftFill rightFill: rightFill.
	self loadWideLine: lineWidth from: self point2Get to: self point3Get
		lineFill: lineFill leftFill: leftFill rightFill: rightFill.
	self loadWideLine: lineWidth from: self point3Get to: self point4Get
		lineFill: lineFill leftFill: leftFill rightFill: rightFill.
	self loadWideLine: lineWidth from: self point4Get to: self point1Get
		lineFill: lineFill leftFill: leftFill rightFill: rightFill.

]

{ #category : #'shapes-polygons' }
BalloonEnginePlugin >> loadShape: points nSegments: nSegments fill: fillIndex lineWidth: lineWidth lineFill: lineFill  pointsShort: pointsShort [
	self inline: false.
	self var:#points declareC:'int *points'.
	1 to: nSegments do:[:i|
		self loadCompressedSegment: i-1
			from: points
			short: pointsShort
			leftFill: fillIndex
			rightFill: 0
			lineWidth: lineWidth
			lineColor: lineFill.
		engineStopped ifTrue:[^nil].
	].
]

{ #category : #'bezier-loading' }
BalloonEnginePlugin >> loadWideBezier: lineWidth lineFill: lineFill leftFill: leftFill rightFill: rightFill n: nSegments [
	"Load the (possibly wide) bezier from the segments currently on the bezier stack."
	| index bezier wide offset |
	self inline: false.
	(lineWidth = 0 or:[lineFill = 0])
		ifTrue:[wide _ false.
				offset _ 0]
		ifFalse:[wide _ true.
				offset _ self offsetFromWidth: lineWidth].
	index _ nSegments * 6.
	[index > 0] whileTrue:[
		wide 
			ifTrue:[bezier _ self allocateWideBezier]
			ifFalse:[bezier _ self allocateBezier].
		engineStopped ifTrue:[^0].
		self loadBezier: bezier 
			segment: index 
			leftFill: leftFill 
			rightFill: rightFill 
			offset: offset.
		wide ifTrue:[
			self wideBezierFillOf: bezier put: lineFill.
			self wideBezierWidthOf: bezier put: lineWidth.
			self wideBezierExtentOf: bezier put: lineWidth.
		].
		index _ index - 6.
	].
	self wbStackClear.
]

{ #category : #'lines-loading' }
BalloonEnginePlugin >> loadWideLine: lineWidth from: p1 to: p2 lineFill: lineFill leftFill: leftFill rightFill: rightFill [
	"Load a (possibly wide) line defined by the points p1 and p2"
	| line offset |
	self var: #p1 declareC:'int *p1'.
	self var: #p2 declareC:'int *p2'.
	(lineWidth = 0 or:[lineFill = 0])
		ifTrue:[	line _ self allocateLine.
				offset _ 0]
		ifFalse:[	line _ self allocateWideLine.
				offset _ self offsetFromWidth: lineWidth].
	engineStopped ifTrue:[^0].
	self loadLine: line 
		from: p1
		to: p2
		offset: offset 
		leftFill: leftFill
		rightFill: rightFill.
	(self isWide: line) ifTrue:[
		self wideLineFillOf: line put: lineFill.
		self wideLineWidthOf: line put: lineWidth.
		self wideLineExtentOf: line put: lineWidth].
]

{ #category : #private }
BalloonEnginePlugin >> makeRectFromPoints [
	self point2Get at: 0 put: (self point3Get at: 0).
	self point2Get at: 1 put: (self point1Get at: 1).
	self point4Get at: 0 put: (self point1Get at: 0).
	self point4Get at: 1 put: (self point3Get at: 1).
]

{ #category : #private }
BalloonEnginePlugin >> offsetFromWidth: lineWidth [
	"Common function so that we don't compute that wrong in any place
	and can easily find all the places where we deal with one-pixel offsets."
	self inline: true.
	^lineWidth // 2
]

{ #category : #primitives }
BalloonEnginePlugin >> primitiveAddBezier [
	| leftFill rightFill viaOop endOop startOop nSegments |
	self export: true.
	self inline: false.

	"Fail if we have the wrong number of arguments"
	interpreterProxy methodArgumentCount = 5 
		ifFalse:[^interpreterProxy primitiveFail].

	rightFill _ interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 0).
	leftFill _ interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 1).
	viaOop _ interpreterProxy stackObjectValue: 2.
	endOop _ interpreterProxy stackObjectValue: 3.
	startOop _ interpreterProxy stackObjectValue: 4.
	interpreterProxy failed ifTrue:[^nil].

	(self quickLoadEngineFrom: (interpreterProxy stackObjectValue: 5) requiredState: GEStateUnlocked)
		ifFalse:[^interpreterProxy primitiveFail].

	"Make sure the fills are okay"
	((self isFillOkay: leftFill) and:[self isFillOkay: rightFill])
			ifFalse:[^interpreterProxy primitiveFail].

	"Do a quick check if the fillIndices are equal - if so, just ignore it"
	leftFill = rightFill & false ifTrue:[
		^interpreterProxy pop: 6. "Leave rcvr on stack"
	].


	self loadPoint: self point1Get from: startOop.
	self loadPoint: self point2Get from: viaOop.
	self loadPoint: self point3Get from: endOop.
	interpreterProxy failed ifTrue:[^0].

	self transformPoints: 3.

	nSegments _ self loadAndSubdivideBezierFrom: self point1Get 
						via: self point2Get 
						to: self point3Get 
						isWide: false.
	self needAvailableSpace: nSegments * GBBaseSize.
	engineStopped ifFalse:[
		leftFill _ self transformColor: leftFill.
		rightFill _ self transformColor: rightFill].
	engineStopped ifFalse:[
		self loadWideBezier: 0 lineFill: 0 leftFill: leftFill rightFill: rightFill n: nSegments.
	].
	engineStopped ifTrue:[
		"Make sure the stack is okay"
		self wbStackClear.
		^interpreterProxy primitiveFail].

	interpreterProxy failed ifFalse:[
		self storeEngineStateInto: engine.
		interpreterProxy pop: 5. "Leave rcvr on stack"
	].
]

{ #category : #primitives }
BalloonEnginePlugin >> primitiveAddBezierShape [
	| points lineFill lineWidth fillIndex length isArray segSize nSegments |
	self export: true.
	self inline: false.

	"Fail if we have the wrong number of arguments"
	interpreterProxy methodArgumentCount = 5 
		ifFalse:[^interpreterProxy primitiveFail].

	lineFill _ interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 0).
	lineWidth _ interpreterProxy stackIntegerValue: 1.
	fillIndex _ interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 2).
	nSegments _ interpreterProxy stackIntegerValue: 3.
	points _ interpreterProxy stackObjectValue: 4.
	interpreterProxy failed ifTrue:[^nil].

	(self quickLoadEngineFrom: (interpreterProxy stackObjectValue: 5) requiredState: GEStateUnlocked)
		ifFalse:[^interpreterProxy primitiveFail].

	"First, do a check if the points look okay"
	length _ interpreterProxy slotSizeOf: points.
	(interpreterProxy isWords: points) ifTrue:[
		isArray _ false.
		"Either PointArray or ShortPointArray"
		(length = (nSegments * 3) or:[length = (nSegments * 6)])
			ifFalse:[^interpreterProxy primitiveFail].
	] ifFalse:["Must be Array of points"
		(interpreterProxy isArray: points)
			ifFalse:[^interpreterProxy primitiveFail].
		length = (nSegments * 3)
			ifFalse:[^interpreterProxy primitiveFail].
		isArray _ true.
	].

	"Now check that we have some hope to have enough free space.
	Do this by assuming nPoints boundaries of maximum size,
	hoping that most of the fills will be colors and many boundaries
	will be line segments"

	(lineWidth = 0 or:[lineFill = 0])
		ifTrue:[segSize _ GLBaseSize]
		ifFalse:[segSize _ GLWideSize].
	(self needAvailableSpace: segSize * nSegments)
		ifFalse:[^interpreterProxy primitiveFail].

	"Check the fills"
	((self isFillOkay: lineFill) and:[self isFillOkay: fillIndex])
		ifFalse:[^interpreterProxy primitiveFail]. 

	"Transform colors"
	lineFill _ self transformColor: lineFill.
	fillIndex _ self transformColor: fillIndex.
	engineStopped ifTrue:[^interpreterProxy primitiveFail].

	"Check if have anything at all to do"
	((lineFill = 0 or:[lineWidth = 0]) and:[fillIndex = 0])
		ifTrue:[^interpreterProxy pop: 5].

	"Transform the lineWidth"
	lineWidth = 0 ifFalse:[
		lineWidth _ self transformWidth: lineWidth.
		lineWidth < 1 ifTrue:[lineWidth _ 1]].

	"And load the actual shape"
	isArray ifTrue:[
		self loadArrayShape: points nSegments: nSegments
			fill: fillIndex lineWidth: lineWidth lineFill: lineFill.
	] ifFalse:[
		self loadShape: (interpreterProxy firstIndexableField: points) nSegments: nSegments
			fill: fillIndex lineWidth: lineWidth lineFill: lineFill 
			pointsShort: (nSegments * 3 = length)].

	engineStopped ifTrue:[^interpreterProxy primitiveFail].

	interpreterProxy failed ifFalse:[
		self needsFlushPut: 1.
		self storeEngineStateInto: engine.
		interpreterProxy pop: 5. "Leave rcvr on stack"
	].
]

{ #category : #primitives }
BalloonEnginePlugin >> primitiveAddBitmapFill [

	| nrmOop dirOop originOop tileFlag fill xIndex cmOop formOop |
	self export: true.
	self inline: false.

	"Fail if we have the wrong number of arguments"
	interpreterProxy methodArgumentCount = 7 
		ifFalse:[^interpreterProxy primitiveFail].

	xIndex _ interpreterProxy stackIntegerValue: 0.
	xIndex <= 0 ifTrue:[^interpreterProxy primitiveFail].
	nrmOop _ interpreterProxy stackObjectValue: 1.
	dirOop _ interpreterProxy stackObjectValue: 2.
	originOop _ interpreterProxy stackObjectValue: 3.
	tileFlag _ interpreterProxy booleanValueOf: (interpreterProxy stackValue: 4).
	tileFlag ifTrue:[tileFlag _ 1] ifFalse:[tileFlag _ 0].
	cmOop _ interpreterProxy stackObjectValue: 5.
	formOop _ interpreterProxy stackObjectValue: 6.
	interpreterProxy failed ifTrue:[^nil].

	(self quickLoadEngineFrom: (interpreterProxy stackObjectValue: 7) requiredState: GEStateUnlocked)
		ifFalse:[^interpreterProxy primitiveFail].

	self loadPoint: self point1Get from: originOop.
	self loadPoint: self point2Get from: dirOop.
	self loadPoint: self point3Get from: nrmOop.
	interpreterProxy failed ifTrue:[^0].

	fill _ self loadBitmapFill: formOop 
				colormap: cmOop
				tile: tileFlag
				from: self point1Get 
				along: self point2Get 
				normal: self point3Get 
				xIndex: xIndex-1.
	engineStopped ifTrue:[
		"Make sure the stack is okay"
		^interpreterProxy primitiveFail].

	interpreterProxy failed ifFalse:[
		self storeEngineStateInto: engine.
		interpreterProxy pop: 8.
		interpreterProxy push: (interpreterProxy positive32BitIntegerFor: fill).
	].
]

{ #category : #primitives }
BalloonEnginePlugin >> primitiveAddCompressedShape [
	| fillIndexList lineFills lineWidths rightFills leftFills nSegments points pointsShort |
	self export: true.
	self inline: false.

	"Fail if we have the wrong number of arguments"
	interpreterProxy methodArgumentCount = 7 
		ifFalse:[^interpreterProxy primitiveFail].

	fillIndexList _ interpreterProxy stackObjectValue: 0.
	lineFills _ interpreterProxy stackObjectValue: 1.
	lineWidths _ interpreterProxy stackObjectValue: 2.
	rightFills _ interpreterProxy stackObjectValue: 3.
	leftFills _ interpreterProxy stackObjectValue: 4.
	nSegments _ interpreterProxy stackIntegerValue: 5.
	points _ interpreterProxy stackObjectValue: 6.
	interpreterProxy failed ifTrue:[^nil].

	(self quickLoadEngineFrom: (interpreterProxy stackObjectValue: 7) requiredState: GEStateUnlocked)
		ifFalse:[^interpreterProxy primitiveFail].

	"First, do a check if the compressed shape is okay"
	(self checkCompressedShape: points 
			segments: nSegments 
			leftFills: leftFills 
			rightFills: rightFills 
			lineWidths: lineWidths 
			lineFills: lineFills 
			fillIndexList: fillIndexList) ifFalse:[^interpreterProxy primitiveFail].

	"Now check that we have some hope to have enough free space.
	Do this by assuming nSegments boundaries of maximum size,
	hoping that most of the fills will be colors and many boundaries
	will be line segments"

	(self needAvailableSpace: (GBBaseSize max: GLBaseSize) * nSegments)
		ifFalse:[^interpreterProxy primitiveFail].

	"Check if the points are short"
	pointsShort _ (interpreterProxy slotSizeOf: points) = (nSegments * 3).

	"Then actually load the compressed shape"
	self loadCompressedShape: (interpreterProxy firstIndexableField: points)
			segments: nSegments 
			leftFills: (interpreterProxy firstIndexableField: leftFills)
			rightFills: (interpreterProxy firstIndexableField: rightFills)
			lineWidths: (interpreterProxy firstIndexableField: lineWidths)
			lineFills: (interpreterProxy firstIndexableField: lineFills)
			fillIndexList: (interpreterProxy firstIndexableField: fillIndexList)
			pointShort: pointsShort.

	engineStopped ifTrue:[^interpreterProxy primitiveFail].

	interpreterProxy failed ifFalse:[
		self needsFlushPut: 1.
		self storeEngineStateInto: engine.
		interpreterProxy pop: 7. "Leave rcvr on stack"
	].
]

{ #category : #primitives }
BalloonEnginePlugin >> primitiveAddGradientFill [

	| isRadial nrmOop dirOop originOop rampOop fill |
	self export: true.
	self inline: false.

	"Fail if we have the wrong number of arguments"
	interpreterProxy methodArgumentCount = 5 
		ifFalse:[^interpreterProxy primitiveFail].

	isRadial _ interpreterProxy booleanValueOf: (interpreterProxy stackValue: 0).
	nrmOop _ interpreterProxy stackValue: 1.
	dirOop _ interpreterProxy stackValue: 2.
	originOop _ interpreterProxy stackValue: 3.
	rampOop _ interpreterProxy stackValue: 4.
	interpreterProxy failed ifTrue:[^nil].

	(self quickLoadEngineFrom: (interpreterProxy stackObjectValue: 5) requiredState: GEStateUnlocked)
		ifFalse:[^interpreterProxy primitiveFail].

	self loadPoint: self point1Get from: originOop.
	self loadPoint: self point2Get from: dirOop.
	self loadPoint: self point3Get from: nrmOop.
	interpreterProxy failed ifTrue:[^0].

	fill _ self loadGradientFill: rampOop 
				from: self point1Get 
				along: self point2Get 
				normal: self point3Get 
				isRadial: isRadial.
	engineStopped ifTrue:[
		"Make sure the stack is okay"
		^interpreterProxy primitiveFail].

	interpreterProxy failed ifFalse:[
		self storeEngineStateInto: engine.
		interpreterProxy pop: 6.
		interpreterProxy push: (interpreterProxy positive32BitIntegerFor: fill).
	].
]

{ #category : #primitives }
BalloonEnginePlugin >> primitiveAddLine [
	| leftFill rightFill endOop startOop |
	self export: true.
	self inline: false.

	"Fail if we have the wrong number of arguments"
	interpreterProxy methodArgumentCount = 4 
		ifFalse:[^interpreterProxy primitiveFail].

	rightFill _ interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 0).
	leftFill _ interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 1).
	endOop _ interpreterProxy stackObjectValue: 2.
	startOop _ interpreterProxy stackObjectValue: 3.
	interpreterProxy failed ifTrue:[^nil].

	(self quickLoadEngineFrom: (interpreterProxy stackObjectValue: 4) requiredState: GEStateUnlocked)
		ifFalse:[^interpreterProxy primitiveFail].

	"Make sure the fills are okay"
	((self isFillOkay: leftFill) and:[self isFillOkay: rightFill])
			ifFalse:[^interpreterProxy primitiveFail].

	"Load the points"
	self loadPoint: self point1Get from: startOop.
	self loadPoint: self point2Get from: endOop.
	interpreterProxy failed ifTrue:[^0].

	"Transform points"
	self transformPoints: 2.

	"Transform colors"
	leftFill _ self transformColor: leftFill.
	rightFill _ self transformColor: rightFill.
	engineStopped ifTrue:[^interpreterProxy primitiveFail].

	"Load line"
	self loadWideLine: 0 from: self point1Get to: self point2Get 
		lineFill: 0 leftFill: leftFill rightFill: rightFill.
	engineStopped ifTrue:[^interpreterProxy primitiveFail].

	interpreterProxy failed ifFalse:[
		self storeEngineStateInto: engine.
		interpreterProxy pop: 4. "Leave rcvr on stack"
	].
]

{ #category : #primitives }
BalloonEnginePlugin >> primitiveAddOval [
	| fillIndex borderWidth borderIndex endOop startOop |
	self export: true.
	self inline: false.

	"Fail if we have the wrong number of arguments"
	interpreterProxy methodArgumentCount = 5 
		ifFalse:[^interpreterProxy primitiveFail].

	borderIndex _ interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 0).
	borderWidth _ interpreterProxy stackIntegerValue: 1.
	fillIndex _ interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 2).
	endOop _ interpreterProxy stackObjectValue: 3.
	startOop _ interpreterProxy stackObjectValue: 4.
	interpreterProxy failed ifTrue:[^nil].

	(self quickLoadEngineFrom: (interpreterProxy stackObjectValue: 5) requiredState: GEStateUnlocked)
		ifFalse:[^interpreterProxy primitiveFail].

	"Make sure the fills are okay"
	((self isFillOkay: borderIndex) and:[self isFillOkay: fillIndex])
			ifFalse:[^interpreterProxy primitiveFail].

	"Transform colors"
	fillIndex _ self transformColor: fillIndex.
	borderIndex _ self transformColor: borderIndex.
	engineStopped ifTrue:[^interpreterProxy primitiveFail].

	"Check if we have anything at all to do"
	(fillIndex = 0 and:[borderIndex = 0 or:[borderWidth <= 0]]) ifTrue:[
		^interpreterProxy pop: 5. "Leave rcvr on stack"
	].

	"Make sure we have some space"
	(self needAvailableSpace: (16 * GBBaseSize)) 
		ifFalse:[^interpreterProxy primitiveFail].

	"Check if we need a border"
	(borderWidth > 0 and:[borderIndex ~= 0]) 
		ifTrue:[borderWidth _ self transformWidth: borderWidth]
		ifFalse:[borderWidth _ 0].


	"Load the rectangle points"
	self loadPoint: self point1Get from: startOop.
	self loadPoint: self point2Get from: endOop.
	interpreterProxy failed ifTrue:[^0].

	self loadOval: borderWidth lineFill: borderIndex 
		leftFill: 0 rightFill: fillIndex.

	engineStopped ifTrue:[
		self wbStackClear.
		^interpreterProxy primitiveFail.
	].
	interpreterProxy failed ifFalse:[
		self needsFlushPut: 1.
		self storeEngineStateInto: engine.
		interpreterProxy pop: 5. "Leave rcvr on stack"
	].
]

{ #category : #primitives }
BalloonEnginePlugin >> primitiveAddPolygon [
	| points lineFill lineWidth fillIndex nPoints length isArray segSize |
	self export: true.
	self inline: false.

	"Fail if we have the wrong number of arguments"
	interpreterProxy methodArgumentCount = 5 
		ifFalse:[^interpreterProxy primitiveFail].

	lineFill _ interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 0).
	lineWidth _ interpreterProxy stackIntegerValue: 1.
	fillIndex _ interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 2).
	nPoints _ interpreterProxy stackIntegerValue: 3.
	points _ interpreterProxy stackObjectValue: 4.
	interpreterProxy failed ifTrue:[^nil].

	(self quickLoadEngineFrom: (interpreterProxy stackObjectValue: 5) requiredState: GEStateUnlocked)
		ifFalse:[^interpreterProxy primitiveFail].

	"First, do a check if the points look okay"
	length _ interpreterProxy slotSizeOf: points.
	(interpreterProxy isWords: points) ifTrue:[
		isArray _ false.
		"Either PointArray or ShortPointArray"
		(length = nPoints or:[nPoints * 2 = length])
			ifFalse:[^interpreterProxy primitiveFail].
	] ifFalse:["Must be Array of points"
		(interpreterProxy isArray: points)
			ifFalse:[^interpreterProxy primitiveFail].
		length = nPoints
			ifFalse:[^interpreterProxy primitiveFail].
		isArray _ true.
	].

	"Now check that we have some hope to have enough free space.
	Do this by assuming nPoints boundaries of maximum size,
	hoping that most of the fills will be colors and many boundaries
	will be line segments"

	(lineWidth = 0 or:[lineFill = 0])
		ifTrue:[segSize _ GLBaseSize]
		ifFalse:[segSize _ GLWideSize].
	(self needAvailableSpace: segSize * nPoints)
		ifFalse:[^interpreterProxy primitiveFail].

	"Check the fills"
	((self isFillOkay: lineFill) and:[self isFillOkay: fillIndex])
		ifFalse:[^interpreterProxy primitiveFail]. 

	"Transform colors"
	lineFill _ self transformColor: lineFill.
	fillIndex _ self transformColor: fillIndex.
	engineStopped ifTrue:[^interpreterProxy primitiveFail].

	"Check if have anything at all to do"
	((lineFill = 0 or:[lineWidth = 0]) and:[fillIndex = 0])
		ifTrue:[^interpreterProxy pop: 6].

	"Transform the lineWidth"
	lineWidth = 0 ifFalse:[lineWidth _ self transformWidth: lineWidth].

	"And load the actual polygon"
	isArray ifTrue:[
		self loadArrayPolygon: points nPoints: nPoints
			fill: fillIndex lineWidth: lineWidth lineFill: lineFill
	] ifFalse:[
		self loadPolygon: (interpreterProxy firstIndexableField: points) nPoints: nPoints 
			fill: fillIndex lineWidth: lineWidth lineFill: lineFill 
			pointsShort: (nPoints = length)].

	engineStopped ifTrue:[^interpreterProxy primitiveFail].

	interpreterProxy failed ifFalse:[
		self needsFlushPut: 1.
		self storeEngineStateInto: engine.
		interpreterProxy pop: 5. "Leave rcvr on stack"
	].
]

{ #category : #primitives }
BalloonEnginePlugin >> primitiveAddRect [
	| fillIndex borderWidth borderIndex endOop startOop |
	self export: true.
	self inline: false.

	"Fail if we have the wrong number of arguments"
	interpreterProxy methodArgumentCount = 5 
		ifFalse:[^interpreterProxy primitiveFail].

	borderIndex _ interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 0).
	borderWidth _ interpreterProxy stackIntegerValue: 1.
	fillIndex _ interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 2).
	endOop _ interpreterProxy stackObjectValue: 3.
	startOop _ interpreterProxy stackObjectValue: 4.
	interpreterProxy failed ifTrue:[^nil].

	(self quickLoadEngineFrom: (interpreterProxy stackObjectValue: 5) requiredState: GEStateUnlocked)
		ifFalse:[^interpreterProxy primitiveFail].

	"Make sure the fills are okay"
	((self isFillOkay: borderIndex) and:[self isFillOkay: fillIndex])
			ifFalse:[^interpreterProxy primitiveFail].

	"Transform colors"
	borderIndex _ self transformColor: borderIndex.
	fillIndex _ self transformColor: fillIndex.
	engineStopped ifTrue:[^interpreterProxy primitiveFail].

	"Check if we have anything at all to do"
	(fillIndex = 0 and:[borderIndex = 0 or:[borderWidth = 0]]) ifTrue:[
		^interpreterProxy pop: 5. "Leave rcvr on stack"
	].

	"Make sure we have some space"
	(self needAvailableSpace: (4 * GLBaseSize)) 
		ifFalse:[^interpreterProxy primitiveFail].

	"Check if we need a border"
	(borderWidth > 0 and:[borderIndex ~= 0]) 
		ifTrue:[borderWidth _ self transformWidth: borderWidth]
		ifFalse:[borderWidth _ 0].

	"Load the rectangle"
	self loadPoint: self point1Get from: startOop.
	self loadPoint: self point3Get from: endOop.
	interpreterProxy failed ifTrue:[^nil].
	self point2Get at: 0 put: (self point3Get at: 0).
	self point2Get at: 1 put: (self point1Get at: 1).
	self point4Get at: 0 put: (self point1Get at: 0).
	self point4Get at: 1 put: (self point3Get at: 1).
	"Transform the points"
	self transformPoints: 4.

	self loadRectangle: borderWidth lineFill: borderIndex leftFill: 0 rightFill: fillIndex.

	interpreterProxy failed ifFalse:[
		self needsFlushPut: 1.
		self storeEngineStateInto: engine.
		interpreterProxy pop: 5. "Leave rcvr on stack"
	].
]

{ #category : #primitives }
BalloonEnginePlugin >> primitiveGetBezierStats [
	| statOop stats |
	self export: true.
	self inline: false.
	self var: #stats declareC:'int *stats'.

	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].

	statOop _ interpreterProxy stackObjectValue: 0.
	engine _ interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	(self quickLoadEngineFrom: engine)
		ifFalse:[^interpreterProxy primitiveFail].

	(interpreterProxy isWords: statOop)
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy slotSizeOf: statOop) < 4
		ifTrue:[^interpreterProxy primitiveFail].
	stats _ interpreterProxy firstIndexableField: statOop.
	stats at: 0 put: (stats at: 0) + (workBuffer at: GWBezierMonotonSubdivisions).
	stats at: 1 put: (stats at: 1) + (workBuffer at: GWBezierHeightSubdivisions).
	stats at: 2 put: (stats at: 2) + (workBuffer at: GWBezierOverflowSubdivisions).
	stats at: 3 put: (stats at: 3) + (workBuffer at: GWBezierLineConversions).

	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #private }
BalloonEnginePlugin >> rShiftTable [
	| theTable |
	self returnTypeC:'int *'.
	self inline: false. "Don't you inline this!!!"
	self var:#theTable declareC:'static int theTable[17] =
		{0, 5, 4, 0, 3, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1}'.
	^theTable
]

{ #category : #'fills-bitmaps' }
BalloonEnginePlugin >> repeatValue: delta max: maxValue [
	| newDelta |
	self inline: true.
	newDelta _ delta.
	[newDelta < 0] whileTrue:[newDelta _ newDelta + maxValue].
	[newDelta >= maxValue] whileTrue:[newDelta _ newDelta - maxValue].
	^newDelta
]

{ #category : #'beziers-wide' }
BalloonEnginePlugin >> returnWideBezierFill [
	^(dispatchReturnValue _ self wideBezierFillOf: dispatchedValue).
]

{ #category : #'beziers-wide' }
BalloonEnginePlugin >> returnWideBezierWidth [
	^(dispatchReturnValue _ self wideBezierWidthOf: dispatchedValue).
]

{ #category : #'lines-wide' }
BalloonEnginePlugin >> returnWideLineFill [
	"Return the fill of the (wide) line - this method is called from a case."
	^(dispatchReturnValue _ self wideLineFillOf: dispatchedValue).
]

{ #category : #'lines-wide' }
BalloonEnginePlugin >> returnWideLineWidth [
	"Return the width of the (wide) line - this method is called from a case."
	^(dispatchReturnValue _ self wideLineWidthOf: dispatchedValue).
]

{ #category : #private }
BalloonEnginePlugin >> shortRunLengthAt: i from: runArray [
	"Return the run-length value from the given ShortRunArray."
	^((self cCoerce: runArray to:'int *') at: i) bitShift: - 16
]

{ #category : #private }
BalloonEnginePlugin >> shortRunValueAt: i from: runArray [
	"Return the run-length value from the given ShortRunArray.
	Note: We don't need any coercion to short/int here, since
	we deal basically only with unsigned values."
	^(((self cCoerce: runArray to:'int *') at: i) bitAnd: 16rFFFF)
]

{ #category : #'beziers-simple' }
BalloonEnginePlugin >> stepToFirstBezier [
	"Initialize the current entry in the GET by stepping to the current scan line"
	self inline: true.
	^self stepToFirstBezierIn: (getBuffer at: self getStartGet) at: self currentYGet
]

{ #category : #'beziers-simple' }
BalloonEnginePlugin >> stepToFirstBezierIn: bezier at: yValue [
	"Initialize the bezier at yValue.
	TODO: Check if reducing maxSteps from 2*deltaY to deltaY 
		brings a *significant* performance improvement.
		In theory this should make for double step performance
		but will cost in quality. Might be that the AA stuff will
		compensate for this - but I'm not really sure."
	| updateData deltaY maxSteps scaledStepSize squaredStepSize 
	startX startY viaX viaY endX endY 
	fwX1 fwX2 fwY1 fwY2 
	fwDx fwDDx fwDy fwDDy |
	self inline: false. "Too many temps for useful inlining"
	self var: #updateData declareC:'int *updateData'.


	"Do a quick check if there is anything at all to do"
	((self isWide: bezier) not and:[yValue >= (self bezierEndYOf: bezier)])
		ifTrue:[^self edgeNumLinesOf: bezier put: 0].

	"Now really initialize bezier"
	startX _ self edgeXValueOf: bezier.
	startY _ self edgeYValueOf: bezier.
	viaX _ self bezierViaXOf: bezier.
	viaY _ self bezierViaYOf: bezier.
	endX _ self bezierEndXOf: bezier.
	endY _ self bezierEndYOf: bezier.
	deltaY _ endY - startY.

	"Initialize integer forward differencing"
	fwX1 _ (viaX - startX) * 2.
	fwX2 _ startX + endX - (viaX * 2).
	fwY1 _ (viaY - startY) * 2.
	fwY2 _ startY + endY - (viaY * 2).
	maxSteps _ deltaY * 2.
	maxSteps < 2 ifTrue:[maxSteps _ 2].
	scaledStepSize _ 16r1000000 // maxSteps.
	squaredStepSize _ self absoluteSquared8Dot24: scaledStepSize.
	fwDx _ fwX1 * scaledStepSize.
	fwDDx _ fwX2 * squaredStepSize * 2.
	fwDx _ fwDx + (fwDDx // 2).
	fwDy _ fwY1 * scaledStepSize.
	fwDDy _ fwY2 * squaredStepSize * 2.
	fwDy _ fwDy + (fwDDy // 2).

	"Store the values"
	self edgeNumLinesOf: bezier put: deltaY.

	updateData _ self bezierUpdateDataOf: bezier.
	updateData at: GBUpdateX put: (startX * 256).
	updateData at: GBUpdateY put: (startY * 256).
	updateData at: GBUpdateDX put: fwDx.
	updateData at: GBUpdateDY put: fwDy.
	updateData at: GBUpdateDDX put: fwDDx.
	updateData at: GBUpdateDDY put: fwDDy.

	"And step to the first scan line"
	(startY _ self edgeYValueOf: bezier) = yValue ifFalse:[
		self stepToNextBezierIn: bezier at: yValue.
		"Adjust number of lines remaining"
		self edgeNumLinesOf: bezier put: deltaY - (yValue - startY).
	].
]

{ #category : #'lines-simple' }
BalloonEnginePlugin >> stepToFirstLine [
	"Initialize the current entry in the GET by stepping to the current scan line"
	self inline: true.
	^self stepToFirstLineIn: (getBuffer at: self getStartGet) at: self currentYGet
]

{ #category : #'lines-simple' }
BalloonEnginePlugin >> stepToFirstLineIn: line at: yValue [
	"Initialize the line at yValue"
	| deltaX deltaY xDir widthX error xInc errorAdjUp startY |
	self inline: false.

	"Do a quick check if there is anything at all to do"
	((self isWide: line) not and:[yValue >= (self lineEndYOf: line)])
		ifTrue:[^self edgeNumLinesOf: line put: 0].

	deltaX _ (self lineEndXOf: line) - (self edgeXValueOf: line).
	deltaY _ (self lineEndYOf: line) - (self edgeYValueOf: line).

	"Check if edge goes left to right"
	deltaX >= 0 
		ifTrue:[	xDir _ 1.
				widthX _ deltaX.
				error _ 0]
		ifFalse:[	xDir _ -1.
				widthX _ 0 - deltaX.
				error _ 1 - deltaY].

	"Check if deltaY is zero.
	Note: We could actually get out here immediately 
	but wide lines rely on an accurate setup in this case"
	deltaY = 0
		ifTrue:[	error _ 0.			"No error for horizontal edges"
				xInc _ deltaX.		"Encodes width and direction"
				errorAdjUp _ 0]
		ifFalse:["Check if edge is y-major"
				deltaY > widthX "Note: The '>' instead of '>=' could be important here..."
					ifTrue:[	xInc _ 0.
							errorAdjUp _ widthX]
					ifFalse:[	xInc _ (widthX // deltaY) * xDir.
							errorAdjUp _ widthX \\ deltaY]].

	"Store the values"
	self edgeNumLinesOf: line put: deltaY.
	self lineXDirectionOf: line put: xDir.
	"self lineYDirectionOf: line put: yDir." "<-- Already set"
	self lineXIncrementOf: line put: xInc.
	self lineErrorOf: line put: error.
	self lineErrorAdjUpOf: line put: errorAdjUp.
	self lineErrorAdjDownOf: line put: deltaY.

	"And step to the first scan line"
	(startY _ self edgeYValueOf: line) = yValue ifFalse:[
		startY to: yValue-1 do:[:i| self stepToNextLineIn: line at: i].
		"Adjust number of lines remaining"
		self edgeNumLinesOf: line put: deltaY - (yValue - startY).
	].
]

{ #category : #'beziers-wide' }
BalloonEnginePlugin >> stepToFirstWideBezier [
	"Initialize the current entry in the GET by stepping to the current scan line"
	self inline: true.
	^self stepToFirstWideBezierIn: (getBuffer at: self getStartGet) at: self currentYGet
]

{ #category : #'beziers-wide' }
BalloonEnginePlugin >> stepToFirstWideBezierIn: bezier at: yValue [
	"Initialize the bezier at yValue"	
	| lineWidth startY nLines yEntry yExit lineOffset endX xDir |
	self inline: false.

	"Get some values"
	lineWidth _ self wideBezierExtentOf: bezier.
	lineOffset _ self offsetFromWidth: lineWidth.

	"Compute the incremental values of the bezier"
	endX _ self bezierEndXOf: bezier.
	startY _ self edgeYValueOf: bezier.
	self stepToFirstBezierIn: bezier at: startY.
	nLines _ (self edgeNumLinesOf: bezier).

	"Copy the incremental update data"
	0 to: 5 do:[:i|
		(self wideBezierUpdateDataOf: bezier) at: i put:
			((self bezierUpdateDataOf: bezier) at: i).
	].

	"Compute primary x direction of curve (e.g., 1: left to right; -1: right to left)."
	xDir _ ((self bezierUpdateDataOf: bezier) at: GBUpdateDX).
	xDir = 0 ifTrue:[((self bezierUpdateDataOf: bezier) at: GBUpdateDDX)].
	xDir >= 0 ifTrue:[xDir _ 1] ifFalse:[xDir _ -1].

	"Adjust the curve to start/end at the right position"
	xDir < 0
		ifTrue:[self adjustWideBezierLeft: bezier width: lineWidth offset: lineOffset endX: endX]
		ifFalse:[self adjustWideBezierRight: bezier width: lineWidth offset: lineOffset endX: endX].

	"Adjust the last value for horizontal lines"
	nLines = 0 ifTrue:[(self bezierUpdateDataOf: bezier) at: GBUpdateX put: 
						(self bezierFinalXOf: bezier) * 256].
	"Adjust the number of lines to include the lineWidth"
	self edgeNumLinesOf: bezier put: nLines + lineWidth.

	"Compute the points where we have to turn on/off the fills"
	yEntry _ 0.						"turned on at lineOffset"
	yExit _ 0 - nLines - lineOffset.	"turned off at zero"
	self wideBezierEntryOf: bezier put: yEntry.
	self wideBezierExitOf: bezier put: yExit.

	"Turn the fills on/off as necessary"
	(yEntry >= lineOffset and:[yExit < 0])
		ifTrue:[self edgeFillsValidate: bezier]
		ifFalse:[self edgeFillsInvalidate: bezier].

	self computeFinalWideBezierValues: bezier width: lineWidth.

	"And step to the first scan line"
	startY = yValue ifFalse:[
		"Note: Must single step here so that entry/exit works"
		startY to: yValue-1 do:[:i| self stepToNextWideBezierIn: bezier at: i].
		"Adjust number of lines remaining"
		self edgeNumLinesOf: bezier put: (self edgeNumLinesOf: bezier) - (yValue - startY).
	].
]

{ #category : #'lines-wide' }
BalloonEnginePlugin >> stepToFirstWideLine [
	"Initialize the current entry in the GET by stepping to the current scan line"
	self inline: true.
	^self stepToFirstWideLineIn: (getBuffer at: self getStartGet) at: self currentYGet
]

{ #category : #'lines-wide' }
BalloonEnginePlugin >> stepToFirstWideLineIn: line at: yValue [
	"Initialize the wide line at yValue."
	| startY yEntry yExit lineWidth nLines lineOffset startX xDir |
	self inline: false.

	"Get some values"
	lineWidth _ self wideLineExtentOf: line.
	lineOffset _ self offsetFromWidth: lineWidth.

	"Compute the incremental values of the line"
	startX _ self edgeXValueOf: line.
	startY _ self edgeYValueOf: line.
	self stepToFirstLineIn: line at: startY.
	nLines _ (self edgeNumLinesOf: line).
	xDir _ self lineXDirectionOf: line.

	"Adjust the line to start at the correct X position"
	self edgeXValueOf: line put: startX - lineOffset.

	"Adjust the number of lines to include the lineWidth"
	self edgeNumLinesOf: line put: nLines + lineWidth.

	"Adjust the values for x-major lines"
	xDir > 0 ifTrue:[
		self wideLineWidthOf: line put: (self lineXIncrementOf: line) + lineWidth.
	] ifFalse:[
		self wideLineWidthOf: line put: lineWidth - (self lineXIncrementOf: line). "adding"
		self edgeXValueOf: line put: (self edgeXValueOf: line) + (self lineXIncrementOf: line).
	].

	"Compute the points where we have to turn on/off the fills"
	yEntry _ 0.						"turned on at lineOffset"
	yExit _ 0 - nLines - lineOffset.	"turned off at zero"
	self wideLineEntryOf: line put: yEntry.
	self wideLineExitOf: line put: yExit.

	"Turn the fills on/off as necessary"
	(yEntry >= lineOffset and:[yExit < 0])
		ifTrue:[self edgeFillsValidate: line]
		ifFalse:[self edgeFillsInvalidate: line].

	"And step to the first scan line"
	startY = yValue ifFalse:[
		startY to: yValue-1 do:[:i| self stepToNextWideLineIn: line at: i].
		"Adjust number of lines remaining"
		self edgeNumLinesOf: line put: (self edgeNumLinesOf: line) - (yValue - startY).
	].

]

{ #category : #'beziers-simple' }
BalloonEnginePlugin >> stepToNextBezier [
	"Process the current entry in the AET by stepping to the next scan line"
	self inline: true.
	^self stepToNextBezierIn: (aetBuffer at: self aetStartGet) at: self currentYGet
]

{ #category : #'beziers-simple' }
BalloonEnginePlugin >> stepToNextBezierForward: updateData at: yValue [
	"Incrementally step to the next scan line in the given bezier update data.
	Note: This method has been written so that inlining works, e.g.,
		not declaring updateData as 'int*' but casting it on every use."
	| minY lastX lastY fwDx fwDy |
	self inline: true.
	lastX _ (self cCoerce: updateData to: 'int*') at: GBUpdateX.
	lastY _ (self cCoerce: updateData to: 'int*') at: GBUpdateY.
	fwDx _ (self cCoerce: updateData to: 'int*') at: GBUpdateDX.
	fwDy _ (self cCoerce: updateData to: 'int*') at: GBUpdateDY.
	minY _ yValue * 256.
	"Step as long as we haven't yet reached minY and also
	as long as fwDy is greater than zero thus stepping down.
	Note: The test for fwDy should not be necessary in theory
		but is a good insurance in practice."
	[minY > lastY and:[fwDy >= 0]] whileTrue:[
		lastX _ lastX + ((fwDx + 16r8000) // 16r10000).
		lastY _ lastY + ((fwDy + 16r8000) // 16r10000).
		fwDx _ fwDx + ((self cCoerce: updateData to: 'int*') at: GBUpdateDDX).
		fwDy _ fwDy + ((self cCoerce: updateData to: 'int*') at: GBUpdateDDY).
	].
	(self cCoerce: updateData to: 'int*') at: GBUpdateX put: lastX.
	(self cCoerce: updateData to: 'int*') at: GBUpdateY put: lastY.
	(self cCoerce: updateData to: 'int*') at: GBUpdateDX put: fwDx.
	(self cCoerce: updateData to: 'int*') at: GBUpdateDY put: fwDy.
	^lastX // 256

]

{ #category : #'beziers-simple' }
BalloonEnginePlugin >> stepToNextBezierIn: bezier at: yValue [
	"Incrementally step to the next scan line in the given bezier"
	|  xValue |
	self inline: true.
	xValue _ self stepToNextBezierForward: (self bezierUpdateDataOf: bezier) at: yValue.
	self edgeXValueOf: bezier put: xValue.
]

{ #category : #'lines-simple' }
BalloonEnginePlugin >> stepToNextLine [
	"Process the current entry in the AET by stepping to the next scan line"
	self inline: true.
	^self stepToNextLineIn: (aetBuffer at: self aetStartGet) at: self currentYGet
]

{ #category : #'lines-simple' }
BalloonEnginePlugin >> stepToNextLineIn: line at: yValue [
	"Incrementally step to the next scan line in the given line"
	| x  err |
	self inline: true.
	x _ (self edgeXValueOf: line) + (self lineXIncrementOf: line).
	err _ (self lineErrorOf: line) + (self lineErrorAdjUpOf: line).
	err > 0 ifTrue:[
		x _ x + (self lineXDirectionOf: line).
		err _ err - (self lineErrorAdjDownOf: line).
	].
	self lineErrorOf: line put: err.
	self edgeXValueOf: line put: x.
]

{ #category : #'beziers-wide' }
BalloonEnginePlugin >> stepToNextWideBezier [
	"Initialize the current entry in the GET by stepping to the current scan line"
	self inline: true.
	self stepToNextWideBezierIn: (aetBuffer at: self aetStartGet) at: self currentYGet.
]

{ #category : #'beziers-wide' }
BalloonEnginePlugin >> stepToNextWideBezierIn: bezier at: yValue [
	"Incrementally step to the next scan line in the given wide bezier"
	|  yEntry yExit lineWidth lineOffset |
	self inline: false.	"Don't inline this"

	lineWidth _ self wideBezierExtentOf: bezier.
	lineOffset _ self offsetFromWidth: lineWidth.

	yEntry _ (self wideBezierEntryOf: bezier) + 1.
	yExit _ (self wideBezierExitOf: bezier) + 1.
	self wideBezierEntryOf: bezier put: yEntry.
	self wideBezierExitOf: bezier put: yExit.
	yEntry >= lineOffset ifTrue:[self edgeFillsValidate: bezier].
	yExit >= 0 ifTrue:[self edgeFillsInvalidate: bezier].

	"Check if we have to step the upper curve"
	(yExit + lineOffset < 0) ifTrue:[
		self stepToNextBezierForward: (self bezierUpdateDataOf: bezier) at: yValue.
	] ifFalse:[
		"Adjust the last x value to the final x recorded previously"
		(self bezierUpdateDataOf: bezier) at: GBUpdateX put: (self bezierFinalXOf: bezier) * 256.
	].
	"Step the lower curve"
	self stepToNextBezierForward: (self wideBezierUpdateDataOf: bezier) at: yValue.

	self computeFinalWideBezierValues: bezier width: lineWidth.
]

{ #category : #'lines-wide' }
BalloonEnginePlugin >> stepToNextWideLine [
	"Process the current entry in the AET by stepping to the next scan line"
	self inline: true.
	^self stepToNextWideLineIn: (aetBuffer at: self aetStartGet) at: self currentYGet
]

{ #category : #'lines-wide' }
BalloonEnginePlugin >> stepToNextWideLineIn: line at: yValue [
	"Incrementally step to the next scan line in the given wide line"
	|  yEntry yExit lineWidth lineOffset lastX nextX |
	self inline: true.

	"Adjust entry/exit values"
	yEntry _ (self wideLineEntryOf: line) + 1.
	yExit _ (self wideLineExitOf: line) + 1.
	self wideLineEntryOf: line put: yEntry.
	self wideLineExitOf: line put: yExit.

	"Turn fills on/off"
	lineWidth _ self wideLineExtentOf: line.
	lineOffset _ self offsetFromWidth: lineWidth.
	yEntry >= lineOffset ifTrue:[self edgeFillsValidate: line].
	yExit >= 0 ifTrue:[self edgeFillsInvalidate: line].

	"Step to the next scan line"
	lastX _ self edgeXValueOf: line.
	self stepToNextLineIn: line at: yValue.
	nextX _ self edgeXValueOf: line.

	"Check for special start/end adjustments"
	(yEntry <= lineWidth or:[yExit+lineOffset >= 0]) ifTrue:[
		"Yes, need an update"
		self adjustWideLine: line afterSteppingFrom: lastX to: nextX.
	].
]

{ #category : #'bezier-loading' }
BalloonEnginePlugin >> subdivideBezier: index [
	"Subdivide the given bezier curve if necessary"
	| startX startY endX endY deltaX deltaY |
	self inline: false.
	startY _ self bzStartY: index.
	endY _ self bzEndY: index.

	"If the receiver is horizontal, don't do anything"
	(endY = startY) ifTrue:[^index].

	"TODO: If the curve can be represented as a line, then do so"

	"If the height of the curve exceeds 256 pixels, subdivide 
	(forward differencing is numerically not very stable)"
	deltaY _ endY - startY.
	deltaY < 0 ifTrue:[deltaY _ 0 - deltaY].
	(deltaY > 255) ifTrue:[
		self incrementStat: GWBezierHeightSubdivisions by: 1.
		^self computeBezierSplitAtHalf: index].

	"Check if the incremental values could possibly overflow the scaled integer range"
	startX _ self bzStartX: index.
	endX _ self bzEndX: index.
	deltaX _ endX - startX.
	deltaX < 0 ifTrue:[deltaX _ 0 - deltaX].
	deltaY * 32 < deltaX ifTrue:[
		self incrementStat: GWBezierOverflowSubdivisions by: 1.
		^self computeBezierSplitAtHalf: index].
	^index

]

{ #category : #'bezier-loading' }
BalloonEnginePlugin >> subdivideBezierFrom: index [
	"Recursively subdivide the curve on the bezier stack."
	| otherIndex index1 index2 |
	self inline: false.
	otherIndex _ self subdivideBezier: index.
	otherIndex = index ifFalse:[
		index1 _ self subdivideBezierFrom: index.
		engineStopped ifTrue:[^0].
		index2 _ self subdivideBezierFrom: otherIndex.
		engineStopped ifTrue:[^0].
		index1 >= index2
			ifTrue:[^index1]
			ifFalse:[^index2]
	].
	^index
]

{ #category : #'bezier-loading' }
BalloonEnginePlugin >> subdivideToBeMonoton: base inX: doTestX [
	"Check if the given bezier curve is monoton in Y, and, if desired in X. 
	If not, subdivide it"
	| index1 index2 base2 |
	self inline: false.
	base2 _ index1 _ index2 _ self subdivideToBeMonotonInY: base.
	doTestX ifTrue:[index1 _ self subdivideToBeMonotonInX: base].
	index1 > index2 ifTrue:[index2 _ index1].
	(base ~= base2 and:[doTestX]) ifTrue:[index1 _ self subdivideToBeMonotonInX: base2].
	index1 > index2 ifTrue:[index2 _ index1].
	^index2
]

{ #category : #'bezier-loading' }
BalloonEnginePlugin >> subdivideToBeMonotonInX: index [
	"Check if the given bezier curve is monoton in X. If not, subdivide it"
	| denom num startX viaX endX dx1 dx2 |
	self inline: false.
	startX _ self bzStartX: index.
	viaX _ self bzViaX: index.
	endX _ self bzEndX: index.

	dx1 _ viaX - startX.
	dx2 _ endX - viaX.
	(dx1 * dx2) >= 0 ifTrue:[^index]. "Bezier is monoton"

	self incrementStat: GWBezierMonotonSubdivisions by: 1.
	"Compute split value"
	denom _ dx2 - dx1.
	num _ dx1.
	num < 0 ifTrue:[num _ 0 - num].
	denom < 0 ifTrue:[denom _ 0 - denom].
	^self computeBezier: index splitAt: (num asFloat / denom asFloat).
]

{ #category : #'bezier-loading' }
BalloonEnginePlugin >> subdivideToBeMonotonInY: index [
	"Check if the given bezier curve is monoton in Y. If not, subdivide it"
	| startY viaY endY dy1 dy2 denom num |
	self inline: false.
	startY _ self bzStartY: index.
	viaY _ self bzViaY: index.
	endY _ self bzEndY: index.

	dy1 _ viaY - startY.
	dy2 _ endY - viaY.
	(dy1 * dy2) >= 0 ifTrue:[^index]. "Bezier is monoton"

	self incrementStat: GWBezierMonotonSubdivisions by: 1.
	"Compute split value"
	denom _ dy2 - dy1.
	num _ dy1.
	num < 0 ifTrue:[num _ 0 - num].
	denom < 0 ifTrue:[denom _ 0 - denom].
	^self computeBezier: index splitAt: (num asFloat / denom asFloat).
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> wideBezierEntryOf: line [

	^self obj: line at: GBWideEntry
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> wideBezierEntryOf: line put: value [

	^self obj: line at: GBWideEntry put: value
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> wideBezierExitOf: line [

	^self obj: line at: GBWideExit
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> wideBezierExitOf: line put: value [

	^self obj: line at: GBWideExit put: value
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> wideBezierExtentOf: bezier [

	^self obj: bezier at: GBWideExtent
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> wideBezierExtentOf: bezier put: value [

	^self obj: bezier at: GBWideExtent put: value
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> wideBezierFillOf: bezier [

	^self obj: bezier at: GBWideFill
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> wideBezierFillOf: bezier put: value [

	^self obj: bezier at: GBWideFill put: value
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> wideBezierUpdateDataOf: bezier [
	self returnTypeC: 'int *'.

	^objBuffer + bezier +  GBWideUpdateData
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> wideBezierWidthOf: line [

	^self obj: line at: GBWideWidth
]

{ #category : #'accessing beziers' }
BalloonEnginePlugin >> wideBezierWidthOf: line put: value [

	^self obj: line at: GBWideWidth put: value
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> wideLineEntryOf: line [

	^self obj: line at: GLWideEntry
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> wideLineEntryOf: line put: value [

	^self obj: line at: GLWideEntry put: value
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> wideLineExitOf: line [

	^self obj: line at: GLWideExit
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> wideLineExitOf: line put: value [

	^self obj: line at: GLWideExit put: value
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> wideLineExtentOf: line [

	^self obj: line at: GLWideExtent
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> wideLineExtentOf: line put: value [

	^self obj: line at: GLWideExtent put: value
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> wideLineFillOf: line [

	^self obj: line at: GLWideFill
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> wideLineFillOf: line put: value [

	^self obj: line at: GLWideFill put: value
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> wideLineWidthOf: line [

	^self obj: line at: GLWideWidth
]

{ #category : #'accessing lines' }
BalloonEnginePlugin >> wideLineWidthOf: line put: value [

	^self obj: line at: GLWideWidth put: value
]
