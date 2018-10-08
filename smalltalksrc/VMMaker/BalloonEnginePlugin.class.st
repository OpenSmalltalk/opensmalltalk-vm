"
This class adds the plugin functionality for the Balloon graphics engine.
BalloonEnginePlugin should be translated but its superclass should not since it is incorporated within this class's translation process. Nor should the simulation subclass be translated
"
Class {
	#name : #BalloonEnginePlugin,
	#superclass : #BalloonEngineBase,
	#category : 'VMMaker-Plugins'
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
	<inline: true>
	<var: 'word1' type: #'unsigned int'>
	<var: 'word2' type: #'unsigned int'>
	word1 := value bitAnd: 16rFFFF.
	word2 := (value bitShift: -16) bitAnd: 255.
	^(( (word1 * word1) bitShift: -16) +
		((word1 * word2) * 2) +
			((word2 * word2) bitShift: 16)) bitShift: -8
]

{ #category : #'beziers-wide' }
BalloonEnginePlugin >> adjustWideBezierLeft: bezier width: lineWidth offset: lineOffset endX: endX [
	"Adjust the wide bezier curve (dx < 0) to start/end at the right point"
	| lastX lastY |
	<inline: false>
	(self bezierUpdateDataOf: bezier) at: GBUpdateX put: 
		(((self bezierUpdateDataOf: bezier) at: GBUpdateX) - (lineOffset * 256)).
	"Set the lastX/Y value of the second curve lineWidth pixels right/down"
	lastX := (self wideBezierUpdateDataOf: bezier) at: GBUpdateX.
	(self wideBezierUpdateDataOf: bezier) at: GBUpdateX put: lastX + (lineWidth - lineOffset * 256).
	"Set lineWidth pixels down"
	lastY := (self wideBezierUpdateDataOf: bezier) at: GBUpdateY.
	(self wideBezierUpdateDataOf: bezier) at: GBUpdateY put: lastY + (lineWidth * 256).
	"Record the last X value"
	self bezierFinalXOf: bezier put: endX - lineOffset.

]

{ #category : #'beziers-wide' }
BalloonEnginePlugin >> adjustWideBezierRight: bezier width: lineWidth offset: lineOffset endX: endX [
	"Adjust the wide bezier curve (dx >= 0) to start/end at the right point"
	| lastX lastY |
	<inline: false>
	(self bezierUpdateDataOf: bezier) at: GBUpdateX put: 
		(((self bezierUpdateDataOf: bezier) at: GBUpdateX) + (lineOffset * 256)).
	"Set the lastX/Y value of the second curve lineWidth pixels right/down"
	"Set lineWidth-lineOffset pixels left"
	lastX := (self wideBezierUpdateDataOf: bezier) at: GBUpdateX.
	(self wideBezierUpdateDataOf: bezier) at: GBUpdateX put: lastX - (lineWidth - lineOffset * 256).
	lastY := (self wideBezierUpdateDataOf: bezier) at: GBUpdateY.
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
	<inline: false>	"Don't inline this"


	"Fetch the values the adjustment decisions are based on"
	yEntry := (self wideLineEntryOf: line).
	yExit := (self wideLineExitOf: line).
	baseWidth := self wideLineExtentOf: line.
	lineOffset := self offsetFromWidth: baseWidth.
	lineWidth := self wideLineWidthOf: line.
	xDir := self lineXDirectionOf: line.
	deltaX := nextX - lastX.

	"Adjust the start of the line to fill an entire rectangle"
	yEntry < baseWidth ifTrue:[
		xDir < 0
			ifTrue:[	lineWidth := lineWidth - deltaX] "effectively adding"
			ifFalse:[	lineWidth := lineWidth + deltaX.
					self edgeXValueOf: line put: lastX].
	].

	"Adjust the end of x-major lines"
	((yExit + lineOffset) = 0) ifTrue:[
		xDir > 0
			ifTrue:[lineWidth := lineWidth - (self lineXIncrementOf: line)]
			ifFalse:[lineWidth := lineWidth + (self lineXIncrementOf: line).	"effectively subtracting"
					self edgeXValueOf: line put: lastX].
	].

	"Adjust the end of the line to fill an entire rectangle"
	(yExit + lineOffset) > 0 ifTrue:[
		xDir < 0
			ifTrue:[	lineWidth := lineWidth + deltaX. "effectively subtracting"
					self edgeXValueOf: line put: lastX]
			ifFalse:[	lineWidth := lineWidth - deltaX]
	].

	"Store the manipulated line width back"
	self wideLineWidthOf: line put: lineWidth.
]

{ #category : #allocation }
BalloonEnginePlugin >> allocateBezier [
	| bezier |
	(self allocateObjEntry: GBBaseSize) ifFalse:[^0].
	bezier := objUsed.
	objUsed := bezier + GBBaseSize.
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
	<var:#cm type:'int *'>
	<var:#cmBits type:'int *'>
	fillSize := GBMBaseSize + cmSize.
	(self allocateObjEntry: fillSize) ifFalse:[^0].
	fill := objUsed.
	objUsed := fill + fillSize.
	self objectTypeOf: fill put: GEPrimitiveClippedBitmapFill.
	self objectIndexOf: fill put: 0.
	self objectLengthOf: fill put: fillSize.
	cm := self colormapOf: fill.
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
	<var:#ramp type:'int *'>
	<var:#rampPtr type:'int *'>
	fillSize := GGBaseSize + rampWidth.
	(self allocateObjEntry: fillSize) ifFalse:[^0].
	fill := objUsed.
	objUsed := fill + fillSize.
	isRadial
		ifTrue:[self objectTypeOf: fill put: GEPrimitiveRadialGradientFill]
		ifFalse:[self objectTypeOf: fill put: GEPrimitiveLinearGradientFill].
	self objectIndexOf: fill put: 0.
	self objectLengthOf: fill put: fillSize.
	rampPtr := self gradientRampOf: fill.
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
	line := objUsed.
	objUsed := line + GLBaseSize.
	self objectTypeOf: line put: GEPrimitiveLine.
	self objectIndexOf: line put: 0.
	self objectLengthOf: line put: GLBaseSize.
	^line
]

{ #category : #allocation }
BalloonEnginePlugin >> allocateWideBezier [
	| bezier |
	(self allocateObjEntry: GBWideSize) ifFalse:[^0].
	bezier := objUsed.
	objUsed := bezier + GBWideSize.
	self objectTypeOf: bezier put: GEPrimitiveWideBezier.
	self objectIndexOf: bezier put: 0.
	self objectLengthOf: bezier put: GBWideSize.
	^bezier
]

{ #category : #allocation }
BalloonEnginePlugin >> allocateWideLine [
	| line |
	(self allocateObjEntry: GLWideSize) ifFalse:[^0].
	line := objUsed.
	objUsed := line + GLWideSize.
	self objectTypeOf: line put: GEPrimitiveWideLine.
	self objectIndexOf: line put: 0.
	self objectLengthOf: line put: GLWideSize.
	^line
]

{ #category : #'bezier-loading' }
BalloonEnginePlugin >> assureValue: val1 between: val2 and: val3 [
	"Make sure that val1 is between val2 and val3."
	<inline: true>
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
	<returnTypeC: 'int *'>

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
	<inline: true>

	bmDepth := self bitmapDepthOf: bmFill.
	bmRaster := self bitmapRasterOf: bmFill.
	bmDepth = 32 ifTrue: [
		value := (self cCoerce: bits to:'int*') at: (bmRaster * yp) + xp.
		(value ~= 0 and: [(value bitAnd: 16rFF000000) = 0])
				ifTrue: [value := value bitOr: 16rFF000000].
		^self uncheckedTransformColor: value].
	"rShift - shift value to convert from pixel to word index"
	rShift := self rShiftTable at: bmDepth.
	value := self makeUnsignedFrom: 
		((self cCoerce: bits to:'int*') at: (bmRaster * yp) + (xp >> rShift)).
	"cMask - mask out the pixel from the word"
	cMask := (1 << bmDepth) - 1.
	"rShift - shift value to move the pixel in the word to the lowest bit position"
	rShift := 32 - bmDepth - ((xp bitAnd: (1 << rShift - 1)) * bmDepth).
	value := (value >> rShift) bitAnd: cMask.
	bmDepth = 16 ifTrue: [
		"Must convert by expanding bits"
		value = 0 ifFalse: [
			b := (value bitAnd: 31) << 3.		b := b + (b >> 5).
			g := (value >> 5 bitAnd: 31) << 3.	g := g + (g >> 5).
			r := (value >> 10 bitAnd: 31) << 3.	r := r + (r >> 5).
			a := 255.
			value := b + (g << 8) + (r << 16) + (a << 24)].
	] ifFalse: [
		"Must convert by using color map"
		(self bitmapCmSizeOf: bmFill) = 0
			ifTrue: [value := 0]
			ifFalse: [value := self makeUnsignedFrom: ((self colormapOf: bmFill) at: value)].
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
	<inline: false>
	<var: #fillPtr type:'int *'>
	length := interpreterProxy slotSizeOf: fillList.
	fillPtr := interpreterProxy firstIndexableField: fillList.
	nFills := 0.
	0 to: length-1 do:[:i |
		runLength := self shortRunLengthAt: i from: fillPtr.
		runValue := self shortRunValueAt: i from: fillPtr.
		(runValue >= 0 and:[runValue <= maxIndex]) ifFalse:[^false].
		nFills := nFills + runLength.
	].
	^nFills = nSegs
]

{ #category : #'shapes-compressed' }
BalloonEnginePlugin >> checkCompressedFills: indexList [
	"Check if the indexList (containing fill handles) is okay."
	| fillPtr length fillIndex |
	<inline: false>
	<var: #fillPtr type:'int *'>
	"First check if the oops have the right format"
	(interpreterProxy isWords: indexList) ifFalse:[^false].

	"Then check the fill entries"
	length := interpreterProxy slotSizeOf: indexList.
	fillPtr := interpreterProxy firstIndexableField: indexList.
	0 to: length-1 do:[:i |
		fillIndex := fillPtr at: i.
		"Make sure the fill is okay"
		(self isFillOkay: fillIndex) ifFalse:[^false]].

	^ true
]

{ #category : #'shapes-compressed' }
BalloonEnginePlugin >> checkCompressedLineWidths: lineWidthList segments: nSegments [
	"Check the run-length encoded lineWidthList matches nSegments"
	| length runLength nItems ptr |
	<inline: false>
	<var: #ptr type:'int *'>
	length := interpreterProxy slotSizeOf: lineWidthList.
	ptr := interpreterProxy firstIndexableField: lineWidthList.
	nItems := 0.
	0 to: length-1 do:[:i|
		runLength := self shortRunLengthAt: i from: ptr.
		nItems := nItems + runLength.
	].
	^nItems = nSegments
]

{ #category : #'shapes-compressed' }
BalloonEnginePlugin >> checkCompressedPoints: points segments: nSegments [
	"Check if the given point array can be handled by the engine."
	| pSize |
	<inline: false>
	(interpreterProxy isWords: points) ifFalse:[^false].
	pSize := interpreterProxy slotSizeOf: points.
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
	<inline: false>
	(self checkCompressedPoints: points segments: nSegments) 
		ifFalse:[^false].
	(self checkCompressedFills: fillIndexList)
		ifFalse:[^false].
	maxFillIndex := interpreterProxy slotSizeOf: fillIndexList.
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
	<inline: true>

	(self isWide: bezier) 
		ifTrue:[lineWidth := (self wideBezierExtentOf: bezier)]
		ifFalse:[lineWidth := 0].
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
	<inline: true>

	(self isLine: edge) ifTrue:[^self checkedAddLineToGET: edge].
	(self isBezier: edge) ifTrue:[^self checkedAddBezierToGET: edge].
	self addEdgeToGET: edge.

]

{ #category : #'GET processing' }
BalloonEnginePlugin >> checkedAddLineToGET: line [
	"Add the line to the global edge table if it intersects the clipping region"
	| lineWidth |
	<inline: true>

	(self isWide: line) 
		ifTrue:[lineWidth := (self wideLineExtentOf: line)]
		ifFalse:[lineWidth := 0].
	(self lineEndYOf: line) + lineWidth < (self fillMinYGet) ifTrue:[^0].
	"Overlaps in Y but may still be entirely right of clip region"
	((self edgeXValueOf: line) - lineWidth >= self fillMaxXGet and:[
		(self lineEndXOf: line) - lineWidth >= self fillMaxXGet]) ifTrue:[^0].
	self addEdgeToGET: line.

]

{ #category : #private }
BalloonEnginePlugin >> circleCosTable [
	| theTable |
	<returnTypeC:'double *'>
	<inline: false>
	<var:#theTable declareC:'static double theTable[33] =
		{1.0, 0.98078528040323, 0.923879532511287, 0.831469612302545,
		0.7071067811865475, 0.555570233019602, 0.38268343236509, 0.1950903220161286,
		0.0, -0.1950903220161283, -0.3826834323650896, -0.555570233019602,
		-0.707106781186547, -0.831469612302545, -0.9238795325112865, -0.98078528040323,
		-1.0, -0.98078528040323, -0.923879532511287, -0.831469612302545,
		-0.707106781186548, -0.555570233019602, -0.3826834323650903, -0.1950903220161287,
		0.0, 0.1950903220161282, 0.38268343236509, 0.555570233019602,
		0.707106781186547, 0.831469612302545, 0.9238795325112865, 0.98078528040323,
		1.0 }'>
	^theTable
]

{ #category : #private }
BalloonEnginePlugin >> circleSinTable [
	| theTable |
	<returnTypeC:'double *'>
	<inline: false>
	<var:#theTable declareC:'static double theTable[33] =
		{0.0, 0.1950903220161282, 0.3826834323650897, 0.555570233019602,
		0.707106781186547, 0.831469612302545, 0.923879532511287, 0.98078528040323,
		1.0, 0.98078528040323, 0.923879532511287, 0.831469612302545,
		0.7071067811865475, 0.555570233019602, 0.38268343236509, 0.1950903220161286,
		0.0, -0.1950903220161283, -0.3826834323650896, -0.555570233019602,
		-0.707106781186547, -0.831469612302545, -0.9238795325112865, -0.98078528040323,
		-1.0, -0.98078528040323, -0.923879532511287, -0.831469612302545,
		-0.707106781186548, -0.555570233019602, -0.3826834323650903, -0.1950903220161287,
		 0.0 }'>
	^theTable
]

{ #category : #'fills-bitmaps' }
BalloonEnginePlugin >> clampValue: value max: maxValue [

	<inline: true>
	value < 0 
		ifTrue:[^0]
		ifFalse:[value >= maxValue 
					ifTrue:[^maxValue-1]
					ifFalse:[^value]]
]

{ #category : #'accessing bitmaps' }
BalloonEnginePlugin >> colormapOf: bmFill [
	<returnTypeC:'int *'>
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
	<inline: false>
	<var: #param type:'double '>
	leftViaX := startX := self bzStartX: index.
	leftViaY := startY := self bzStartY: index.
	rightViaX := viaX := self bzViaX: index.
	rightViaY := viaY := self bzViaY: index.
	endX := self bzEndX: index.
	endY := self bzEndY: index.

	"Compute intermediate points"
	sharedX := leftViaX := leftViaX + ((viaX - startX) asFloat * param) asInteger.
	sharedY := leftViaY := leftViaY + ((viaY - startY) asFloat * param) asInteger.
	rightViaX := rightViaX + ((endX - viaX) asFloat * param) asInteger.
	rightViaY := rightViaY + ((endY - viaY) asFloat * param) asInteger.
	"Compute new shared point"
	sharedX := sharedX + ((rightViaX - leftViaX) asFloat * param) asInteger.
	sharedY := sharedY + ((rightViaY - leftViaY) asFloat * param) asInteger.

	"Check the new via points"
	leftViaY := self assureValue: leftViaY between: startY and: sharedY.
	rightViaY := self assureValue: rightViaY between: sharedY and: endY.

	newIndex := self allocateBezierStackEntry.
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
	<inline: false>

	newIndex := self allocateBezierStackEntry.
	engineStopped ifTrue:[^0]. "Something went wrong"

	leftViaX := startX := self bzStartX: index.
	leftViaY := startY := self bzStartY: index.
	rightViaX := viaX := self bzViaX: index.
	rightViaY := viaY := self bzViaY: index.
	endX := self bzEndX: index.
	endY := self bzEndY: index.
	"Compute intermediate points"
	leftViaX := leftViaX + ((viaX - startX) // 2).
	leftViaY := leftViaY + ((viaY - startY) // 2).
	sharedX := rightViaX := rightViaX + ((endX - viaX) // 2).
	sharedY := rightViaY := rightViaY + ((endY - viaY) // 2).
	"Compute new shared point"
	sharedX := sharedX + ((leftViaX - rightViaX) // 2).
	sharedY := sharedY + ((leftViaY - rightViaY) // 2).
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
	leftX := ((self bezierUpdateDataOf: bezier) at: GBUpdateX) // 256.
	rightX := ((self wideBezierUpdateDataOf: bezier) at: GBUpdateX) // 256.
	leftX > rightX ifTrue:[temp := leftX. leftX := rightX. rightX := temp].
	self edgeXValueOf: bezier put: leftX.
	(rightX - leftX) > lineWidth ifTrue:[
		self wideBezierWidthOf: bezier put: (rightX - leftX).
	] ifFalse:[
		self wideBezierWidthOf: bezier put: lineWidth.
	].
]

{ #category : #'fills-bitmaps' }
BalloonEnginePlugin >> fillBitmapSpan [
	<inline: true>
	^self fillBitmapSpan: self lastExportedFillGet from: self lastExportedLeftXGet to: self lastExportedRightXGet at: self currentYGet
]

{ #category : #'fills-bitmaps' }
BalloonEnginePlugin >> fillBitmapSpan: bmFill from: leftX to: rightX at: yValue [
	| x x1 dsX ds dtX dt deltaX deltaY bits xp yp bmWidth bmHeight fillValue tileFlag |
	<inline: false>
	<var: #bits type:'int *'>
	self aaLevelGet = 1
		ifFalse:[^self fillBitmapSpanAA: bmFill from: leftX to: rightX at: yValue].

	bits := self loadBitsFrom: bmFill.
	bits == nil ifTrue:[^nil].
	bmWidth := self bitmapWidthOf: bmFill.
	bmHeight := self bitmapHeightOf: bmFill.
	tileFlag := (self bitmapTileFlagOf: bmFill) = 1.
	deltaX := leftX - (self fillOriginXOf: bmFill).
	deltaY := yValue - (self fillOriginYOf: bmFill).
	dsX := self fillDirectionXOf: bmFill.
	dtX := self fillNormalXOf: bmFill.

	ds := (deltaX * dsX) + (deltaY * (self fillDirectionYOf: bmFill)).
	dt := (deltaX * dtX) + (deltaY * (self fillNormalYOf: bmFill)).

	x := leftX.
	x1 := rightX.
	[x < x1] whileTrue:[
		tileFlag ifTrue:[
			ds := self repeatValue: ds max: bmWidth << 16.
			dt := self repeatValue: dt max: bmHeight << 16].
		xp := ds // 16r10000.
		yp := dt // 16r10000.
		tileFlag ifFalse:[
			xp := self clampValue: xp max: bmWidth.
			yp := self clampValue: yp max: bmHeight].
		(xp >= 0 and:[yp >= 0 and:[xp < bmWidth and:[yp < bmHeight]]]) ifTrue:[
			fillValue := self bitmapValue: bmFill bits: bits atX: xp y: yp.
			spanBuffer at: x put: fillValue.
		].
		ds := ds + dsX.
		dt := dt + dtX.
		x := x + 1.
	].
]

{ #category : #'fills-bitmaps' }
BalloonEnginePlugin >> fillBitmapSpanAA: bmFill from: leftX to: rightX at: yValue [
	| x dsX ds dtX dt deltaX deltaY bits xp yp bmWidth bmHeight fillValue baseShift cMask cShift idx aaLevel firstPixel lastPixel tileFlag |
	<inline: false>
	<var: #bits type:'int *'>
	bits := self loadBitsFrom: bmFill.
	bits == nil ifTrue:[^nil].
	bmWidth := self bitmapWidthOf: bmFill.
	bmHeight := self bitmapHeightOf: bmFill.
	tileFlag := (self bitmapTileFlagOf: bmFill) = 1.
	deltaX := leftX - (self fillOriginXOf: bmFill).
	deltaY := yValue - (self fillOriginYOf: bmFill).
	dsX := self fillDirectionXOf: bmFill.
	dtX := self fillNormalXOf: bmFill.

	ds := (deltaX * dsX) + (deltaY * (self fillDirectionYOf: bmFill)).
	dt := (deltaX * dtX) + (deltaY * (self fillNormalYOf: bmFill)).

	aaLevel := self aaLevelGet.
	firstPixel := self aaFirstPixelFrom: leftX to: rightX.
	lastPixel := self aaLastPixelFrom: leftX to: rightX.
	baseShift := self aaShiftGet.
	cMask := self aaColorMaskGet.
	cShift := self aaColorShiftGet.
	x := leftX.
	[x < firstPixel] whileTrue:[
		tileFlag ifTrue:[
			ds := self repeatValue: ds max: bmWidth << 16.
			dt := self repeatValue: dt max: bmHeight << 16].
		xp := ds // 16r10000.
		yp := dt // 16r10000.
		tileFlag ifFalse:[
			xp := self clampValue: xp max: bmWidth.
			yp := self clampValue: yp max: bmHeight].
		(xp >= 0 and:[yp >= 0 and:[xp < bmWidth and:[yp < bmHeight]]]) ifTrue:[
			fillValue := self bitmapValue: bmFill bits: bits atX: xp y: yp.
			fillValue := (fillValue bitAnd: cMask) >> cShift.
			idx := x >> baseShift.
			spanBuffer at: idx put: (spanBuffer at: idx) + fillValue.
		].
		ds := ds + dsX.
		dt := dt + dtX.
		x := x + 1.
	].

	cMask := (self aaColorMaskGet >> self aaShiftGet) bitOr: 16rF0F0F0F0.
	cShift := self aaShiftGet.
	[x < lastPixel] whileTrue:[
		tileFlag ifTrue:[
			ds := self repeatValue: ds max: bmWidth << 16.
			dt := self repeatValue: dt max: bmHeight << 16].
		xp := ds // 16r10000.
		yp := dt // 16r10000.
		tileFlag ifFalse:[
			xp := self clampValue: xp max: bmWidth.
			yp := self clampValue: yp max: bmHeight].
		(xp >= 0 and:[yp >= 0 and:[xp < bmWidth and:[yp < bmHeight]]]) ifTrue:[
			fillValue := self bitmapValue: bmFill bits: bits atX: xp y: yp.
			fillValue := (fillValue bitAnd: cMask) >> cShift.
			idx := x >> baseShift.
			spanBuffer at: idx put: (spanBuffer at: idx) + fillValue.
		].
		ds := ds + (dsX << cShift).
		dt := dt + (dtX << cShift).
		x := x + aaLevel.
	].

	cMask := self aaColorMaskGet.
	cShift := self aaColorShiftGet.
	[x < rightX] whileTrue:[
		tileFlag ifTrue:[
			ds := self repeatValue: ds max: bmWidth << 16.
			dt := self repeatValue: dt max: bmHeight << 16].
		xp := ds // 16r10000.
		yp := dt // 16r10000.
		tileFlag ifFalse:[
			xp := self clampValue: xp max: bmWidth.
			yp := self clampValue: yp max: bmHeight].
		(xp >= 0 and:[yp >= 0 and:[xp < bmWidth and:[yp < bmHeight]]]) ifTrue:[
			fillValue := self bitmapValue: bmFill bits: bits atX: xp y: yp.
			fillValue := (fillValue bitAnd: cMask) >> cShift.
			idx := x >> baseShift.
			spanBuffer at: idx put: (spanBuffer at: idx) + fillValue.
		].
		ds := ds + dsX.
		dt := dt + dtX.
		x := x + 1.
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
	<inline: true>
	^self fillLinearGradient: self lastExportedFillGet from: self lastExportedLeftXGet to: self lastExportedRightXGet at: self currentYGet
]

{ #category : #'fills-gradient' }
BalloonEnginePlugin >> fillLinearGradient: fill from: leftX to: rightX at: yValue [
	"Draw a linear gradient fill."
	| x0 x1 ramp rampSize dsX ds x rampIndex |
	<inline: false>
	<var: #ramp type:'int *'>
	ramp := self gradientRampOf: fill.
	rampSize := self gradientRampLengthOf: fill.

	dsX := self fillDirectionXOf: fill.
	ds := ((leftX - (self fillOriginXOf: fill)) * dsX) + 
			((yValue - (self fillOriginYOf: fill)) * (self fillDirectionYOf: fill)).

	x := x0 := leftX.
	x1 := rightX.

	"Note: The inner loop has been divided into three parts for speed"
	"Part one: Fill everything outside the left boundary"
	[((rampIndex := ds // 16r10000) < 0 or:[rampIndex >= rampSize]) and:[x < x1]] 
		whileTrue:[	x := x + 1.
					ds := ds + dsX].
	x > x0 ifTrue:[
		rampIndex < 0 ifTrue:[rampIndex := 0].
		rampIndex >= rampSize ifTrue:[rampIndex := rampSize - 1].
		self fillColorSpan: (self makeUnsignedFrom: (ramp at: rampIndex)) from: x0 to: x].

	"Part two: Fill everything inside the boundaries"
	self aaLevelGet = 1 ifTrue:[
		"Fast version w/o anti-aliasing"
		[((rampIndex := ds // 16r10000) < rampSize and:[rampIndex >= 0]) and:[x < x1]] whileTrue:[
			spanBuffer at: x put: (self makeUnsignedFrom: (ramp at: rampIndex)).
			x := x + 1.
			ds := ds + dsX.
		].
	] ifFalse:[x := self fillLinearGradientAA: fill ramp: ramp ds: ds dsX: dsX from: x to: rightX].
	"Part three fill everything outside right boundary"
	x < x1 ifTrue:[
		rampIndex < 0 ifTrue:[rampIndex := 0].
		rampIndex >= rampSize ifTrue:[rampIndex := rampSize-1].
		self fillColorSpan: (self makeUnsignedFrom: (ramp at: rampIndex)) from: x to: x1].

]

{ #category : #'fills-gradient' }
BalloonEnginePlugin >> fillLinearGradientAA: fill ramp: ramp ds: deltaS dsX: dsX from: leftX to: rightX [
	"This is the AA version of linear gradient filling."
	| colorMask colorShift baseShift rampIndex ds rampSize x idx rampValue 
	 aaLevel firstPixel lastPixel |
	<inline: false>
	<var: #ramp type:'int *'>

	aaLevel := self aaLevelGet.
	baseShift := self aaShiftGet.
	rampSize := self gradientRampLengthOf: fill.
	ds := deltaS.
	x := leftX.
	rampIndex := ds // 16r10000.

	firstPixel := self aaFirstPixelFrom: leftX to: rightX.
	lastPixel := self aaLastPixelFrom: leftX to: rightX.

	"Deal with the first n sub-pixels"
	colorMask := self aaColorMaskGet.
	colorShift := self aaColorShiftGet.
	[x < firstPixel and:[rampIndex < rampSize and:[rampIndex >= 0]]] whileTrue:[
		rampValue := self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
		rampValue := (rampValue bitAnd: colorMask) >> colorShift.
		"Copy as many pixels as possible"
		[x < firstPixel and:[(ds//16r10000) = rampIndex]] whileTrue:[
			idx := x >> baseShift.
			spanBuffer at: idx put: (spanBuffer at: idx) + rampValue.
			x := x + 1.
			ds := ds + dsX].
		rampIndex := ds // 16r10000.
	].

	"Deal with the full pixels"
	colorMask := (self aaColorMaskGet >> self aaShiftGet) bitOr: 16rF0F0F0F0.
	colorShift := self aaShiftGet.
	[x < lastPixel and:[rampIndex < rampSize and:[rampIndex >= 0]]] whileTrue:[
		rampValue := self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
		rampValue := (rampValue bitAnd: colorMask) >> colorShift.
		"Copy as many pixels as possible"
		[x < lastPixel and:[(ds//16r10000) = rampIndex]] whileTrue:[
			idx := x >> baseShift.
			spanBuffer at: idx put: (spanBuffer at: idx) + rampValue.
			x := x + aaLevel.
			ds := ds + (dsX << colorShift)].
		rampIndex := ds // 16r10000.
	].

	"Deal with the last n sub-pixels"
	colorMask := self aaColorMaskGet.
	colorShift := self aaColorShiftGet.
	[x < rightX and:[rampIndex < rampSize and:[rampIndex>=0]]] whileTrue:[
		rampValue := self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
		rampValue := (rampValue bitAnd: colorMask) >> colorShift.
		"Copy as many pixels as possible"
		[x < rightX and:[(ds//16r10000) = rampIndex]] whileTrue:[
			idx := x >> baseShift.
			spanBuffer at: idx put: (spanBuffer at: idx) + rampValue.
			x := x + 1.
			ds := ds + dsX].
		rampIndex := ds // 16r10000.
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
	<inline: true>
	ds := (self cCoerce: deltaST to:'int*') at: 0.
	dt := (self cCoerce: deltaST to:'int*') at: 1.
	rampIndex := self accurateLengthOf: ds // 16r10000 with: dt // 16r10000.
	rampValue := self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
	length2 := (rampIndex-1) * (rampIndex-1).

	x := leftX.
	x1 := rightX.
	x1 > (self fillOriginXOf: fill) ifTrue:[x1 := self fillOriginXOf: fill].
	[x < x1] whileTrue:[
		"Try to copy the current value more than just once"
		[x < x1 and:[(self squaredLengthOf: ds //  16r10000 with: dt // 16r10000) >= length2]]
			whileTrue:[	spanBuffer at: x put: rampValue.
						x := x + 1.
						ds := ds + dsX.
						dt := dt + dtX].
		"Step to next ramp value"
		nextLength := self squaredLengthOf: ds //  16r10000 with: dt // 16r10000.
		[nextLength < length2] whileTrue:[
			rampIndex := rampIndex - 1.
			rampValue := self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
			length2 := (rampIndex-1) * (rampIndex-1).
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
	<inline: false>
	<var: #ramp type:'int *'>
	<var: #deltaST type:' int *'>

	ds := (self cCoerce: deltaST to:'int*') at: 0.
	dt := (self cCoerce: deltaST to:'int*') at: 1.
	aaLevel := self aaLevelGet.
	baseShift := self aaShiftGet.
	rampIndex := self accurateLengthOf: ds // 16r10000 with: dt // 16r10000.
	length2 := (rampIndex-1) * (rampIndex-1).

	x := leftX.
	x1 := self fillOriginXOf: fill.
	x1 > rightX ifTrue:[x1 := rightX].
	firstPixel := self aaFirstPixelFrom: leftX to: x1.
	lastPixel := self aaLastPixelFrom: leftX to: x1.

	"Deal with the first n sub-pixels"
	(x < firstPixel) ifTrue:[
		colorMask := self aaColorMaskGet.
		colorShift := self aaColorShiftGet.
		rampValue := self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
		rampValue := (rampValue bitAnd: colorMask) >> colorShift.
		[x < firstPixel] whileTrue:[
			"Try to copy the current value more than just once"
			[x < firstPixel and:[(self squaredLengthOf: ds //  16r10000 with: dt // 16r10000) >= length2]]
				whileTrue:[	index := x >> baseShift.
							spanBuffer at: index put: (spanBuffer at: index) + rampValue.
							x := x + 1.
							ds := ds + dsX.
							dt := dt + dtX].
			"Step to next ramp value"
			nextLength := self squaredLengthOf: ds //  16r10000 with: dt // 16r10000.
			[nextLength < length2] whileTrue:[
				rampIndex := rampIndex - 1.
				rampValue := self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
				rampValue := (rampValue bitAnd: colorMask) >> colorShift.
				length2 := (rampIndex-1) * (rampIndex-1).
			].
		].
	].

	"Deal with the full pixels"
	(x < lastPixel) ifTrue:[
		colorMask := (self aaColorMaskGet >> self aaShiftGet) bitOr: 16rF0F0F0F0.
		colorShift := self aaShiftGet.
		rampValue := self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
		rampValue := (rampValue bitAnd: colorMask) >> colorShift.
		[x < lastPixel] whileTrue:[
			"Try to copy the current value more than just once"
			[x < lastPixel and:[(self squaredLengthOf: ds //  16r10000 with: dt // 16r10000) >= length2]]
				whileTrue:[	index := x >> baseShift.
							spanBuffer at: index put: (spanBuffer at: index) + rampValue.
							x := x + aaLevel.
							ds := ds + (dsX << colorShift).
							dt := dt + (dtX << colorShift)].
			"Step to next ramp value"
			nextLength := self squaredLengthOf: ds //  16r10000 with: dt // 16r10000.
			[nextLength < length2] whileTrue:[
				rampIndex := rampIndex - 1.
				rampValue := self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
				rampValue := (rampValue bitAnd: colorMask) >> colorShift.
				length2 := (rampIndex-1) * (rampIndex-1).
			].
		].
	].

	"Deal with the last n sub-pixels"
	(x < x1) ifTrue:[
		colorMask := self aaColorMaskGet.
		colorShift := self aaColorShiftGet.
		rampValue := self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
		rampValue := (rampValue bitAnd: colorMask) >> colorShift.
		[x < x1] whileTrue:[
			"Try to copy the current value more than just once"
			[x < x1 and:[(self squaredLengthOf: ds //  16r10000 with: dt // 16r10000) >= length2]]
				whileTrue:[	index := x >> baseShift.
							spanBuffer at: index put: (spanBuffer at: index) + rampValue.
							x := x + 1.
							ds := ds + dsX.
							dt := dt + dtX].
			"Step to next ramp value"
			nextLength := self squaredLengthOf: ds //  16r10000 with: dt // 16r10000.
			[nextLength < length2] whileTrue:[
				rampIndex := rampIndex - 1.
				rampValue := self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
				rampValue := (rampValue bitAnd: colorMask) >> colorShift.
				length2 := (rampIndex-1) * (rampIndex-1).
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
	<inline: true>
	^self fillRadialGradient: self lastExportedFillGet from: self lastExportedLeftXGet to: self lastExportedRightXGet at: self currentYGet
]

{ #category : #'fills-gradient' }
BalloonEnginePlugin >> fillRadialGradient: fill from: leftX to: rightX at: yValue [
	"Draw a radial gradient fill."
	| x x1 ramp rampSize dsX ds dtX dt length2 deltaX deltaY deltaST |
	<inline: false>
	<var: #ramp type:'int *'>
	<var: #deltaST type:'int *'>

	ramp := self gradientRampOf: fill.
	rampSize := self gradientRampLengthOf: fill.

	deltaX := leftX - (self fillOriginXOf: fill).
	deltaY := yValue - (self fillOriginYOf: fill).

	dsX := self fillDirectionXOf: fill.
	dtX := self fillNormalXOf: fill.

	ds := (deltaX * dsX) + (deltaY * (self fillDirectionYOf: fill)).
	dt := (deltaX * dtX) + (deltaY * (self fillNormalYOf: fill)).

	x := leftX.
	x1 := rightX.

	"Note: The inner loop has been divided into three parts for speed"
	"Part one: Fill everything outside the left boundary"
	length2 := (rampSize-1) * (rampSize-1). "This is the upper bound"
	[(self squaredLengthOf: ds // 16r10000 with: dt // 16r10000) >= length2 and:[x < x1]]
		whileTrue:[	x := x + 1.	ds := ds + dsX.	dt := dt + dtX].
	x > leftX ifTrue:[self fillColorSpan: (self makeUnsignedFrom: (ramp at: rampSize-1)) from: leftX to: x].

	"Part two: Fill everything inside the boundaries"
	deltaST := self point1Get.
	deltaST at: 0 put: ds.
	deltaST at: 1 put: dt.
	(x < (self fillOriginXOf: fill)) ifTrue:[
		"Draw the decreasing part"
		self aaLevelGet = 1 
			ifTrue:[x := self fillRadialDecreasing: fill ramp: ramp deltaST: deltaST 
							dsX: dsX dtX: dtX from: x to: x1]
			ifFalse:[x := self fillRadialDecreasingAA: fill ramp: ramp deltaST: deltaST 
							dsX: dsX dtX: dtX from: x to: x1].
	].
	x < x1 ifTrue:[
		"Draw the increasing part"
		self aaLevelGet = 1
			ifTrue:[x := self fillRadialIncreasing: fill ramp: ramp deltaST: deltaST
							dsX: dsX dtX: dtX from: x to: x1]
			ifFalse:[x := self fillRadialIncreasingAA: fill ramp: ramp deltaST: deltaST
							dsX: dsX dtX: dtX from: x to: x1].
	].

	"Part three fill everything outside right boundary"
	x < rightX ifTrue:[self fillColorSpan: (self makeUnsignedFrom: (ramp at: rampSize-1)) from: x to: rightX].

]

{ #category : #'fills-gradient' }
BalloonEnginePlugin >> fillRadialIncreasing: fill ramp: ramp deltaST: deltaST dsX: dsX dtX: dtX from: leftX to: rightX [
	"Part 2b) Compute the increasing part of the ramp"
	| ds dt rampIndex rampValue length2 x x1 nextLength rampSize lastLength |
	<inline: true>
	ds := (self cCoerce: deltaST to:'int*') at: 0.
	dt := (self cCoerce: deltaST to:'int*') at: 1.
	rampIndex := self accurateLengthOf: ds // 16r10000 with: dt // 16r10000.
	rampValue := self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
	rampSize := self gradientRampLengthOf: fill.
	length2 := (rampSize-1) * (rampSize-1). "This is the upper bound"
	nextLength := (rampIndex+1) * (rampIndex+1).
	lastLength := self squaredLengthOf: ds //  16r10000 with: dt // 16r10000.

	x := leftX.
	x1 := rightX.

	[x < x1 and:[lastLength < length2]] whileTrue:[
		"Try to copy the current value more than once"
		[x < x1 and:[(self squaredLengthOf: ds //  16r10000 with: dt // 16r10000) <= nextLength]]
			whileTrue:[	spanBuffer at: x put: rampValue.
						x := x + 1.
						ds := ds + dsX.
						dt := dt + dtX].
		lastLength := self squaredLengthOf: ds //  16r10000 with: dt // 16r10000.
		[lastLength > nextLength] whileTrue:[
			rampIndex := rampIndex + 1.
			rampValue := self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
			nextLength := (rampIndex+1) * (rampIndex+1).
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
	<inline: false>
	<var: #ramp type:'int *'>
	<var: #deltaST type:' int *'>

	ds := (self cCoerce: deltaST to:'int*') at: 0.
	dt := (self cCoerce: deltaST to:'int*') at: 1.
	aaLevel := self aaLevelGet.
	baseShift := self aaShiftGet.
	rampIndex := self accurateLengthOf: ds // 16r10000 with: dt // 16r10000.
	rampSize := self gradientRampLengthOf: fill.
	length2 := (rampSize-1) * (rampSize-1). "This is the upper bound"
	nextLength := (rampIndex+1) * (rampIndex+1).
	lastLength := self squaredLengthOf: ds //  16r10000 with: dt // 16r10000.

	x := leftX.

	firstPixel := self aaFirstPixelFrom: leftX to: rightX.
	lastPixel := self aaLastPixelFrom: leftX to: rightX.

	"Deal with the first n subPixels"
	(x < firstPixel and:[lastLength < length2]) ifTrue:[
		colorMask := self aaColorMaskGet.
		colorShift := self aaColorShiftGet.
		rampValue := self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
		rampValue := (rampValue bitAnd: colorMask) >> colorShift.
		[x < firstPixel and:[lastLength < length2]] whileTrue:[
			"Try to copy the current value more than once"
			[x < firstPixel and:[(self squaredLengthOf: ds //  16r10000 with: dt // 16r10000) <= nextLength]]
				whileTrue:[	index := x >> baseShift.
							spanBuffer at: index put: (spanBuffer at: index) + rampValue.
							x := x + 1.
							ds := ds + dsX.
							dt := dt + dtX].
			lastLength := self squaredLengthOf: ds //  16r10000 with: dt // 16r10000.
			[lastLength > nextLength] whileTrue:[
				rampIndex := rampIndex + 1.
				rampValue := self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
				rampValue := (rampValue bitAnd: colorMask) >> colorShift.
				nextLength := (rampIndex+1) * (rampIndex+1).
			].
		].
	].

	"Deal with the full pixels"
	(x < lastPixel and:[lastLength < length2]) ifTrue:[
		colorMask := (self aaColorMaskGet >> self aaShiftGet) bitOr: 16rF0F0F0F0.
		colorShift := self aaShiftGet.
		rampValue := self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
		rampValue := (rampValue bitAnd: colorMask) >> colorShift.
		[x < lastPixel and:[lastLength < length2]] whileTrue:[
			"Try to copy the current value more than once"
			[x < lastPixel and:[(self squaredLengthOf: ds //  16r10000 with: dt // 16r10000) <= nextLength]]
				whileTrue:[	index := x >> baseShift.
							spanBuffer at: index put: (spanBuffer at: index) + rampValue.
							x := x + aaLevel.
							ds := ds + (dsX << colorShift).
							dt := dt + (dtX << colorShift)].
			lastLength := self squaredLengthOf: ds //  16r10000 with: dt // 16r10000.
			[lastLength > nextLength] whileTrue:[
				rampIndex := rampIndex + 1.
				rampValue := self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
				rampValue := (rampValue bitAnd: colorMask) >> colorShift.
				nextLength := (rampIndex+1) * (rampIndex+1).
			].
		].
	].

	"Deal with last n sub-pixels"
	(x < rightX and:[lastLength < length2]) ifTrue:[
		colorMask := self aaColorMaskGet.
		colorShift := self aaColorShiftGet.
		rampValue := self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
		rampValue := (rampValue bitAnd: colorMask) >> colorShift.
		[x < rightX and:[lastLength < length2]] whileTrue:[
			"Try to copy the current value more than once"
			[x < rightX and:[(self squaredLengthOf: ds //  16r10000 with: dt // 16r10000) <= nextLength]]
				whileTrue:[	index := x >> baseShift.
							spanBuffer at: index put: (spanBuffer at: index) + rampValue.
							x := x + 1.
							ds := ds + dsX.
							dt := dt + dtX].
			lastLength := self squaredLengthOf: ds //  16r10000 with: dt // 16r10000.
			[lastLength > nextLength] whileTrue:[
				rampIndex := rampIndex + 1.
				rampValue := self makeUnsignedFrom: ((self cCoerce: ramp to:'int *') at: rampIndex).
				rampValue := (rampValue bitAnd: colorMask) >> colorShift.
				nextLength := (rampIndex+1) * (rampIndex+1).
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
	<returnTypeC:'int *'>

	^objBuffer + fill +  GFRampOffset
]

{ #category : #testing }
BalloonEnginePlugin >> isBezier: bezier [
	^((self objectTypeOf: bezier) bitAnd: GEPrimitiveWideMask) = GEPrimitiveBezier
]

{ #category : #testing }
BalloonEnginePlugin >> isFillOkay: fill [
	<inline: false>
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
	<inline: false>
	<var: #point1 type:'int *'>
	<var: #point2 type:'int *'>
	<var: #point3 type:'int *'>
	bz1 := self allocateBezierStackEntry.	
	engineStopped ifTrue:[^0].
	"Load point1/point2/point3 on the top of the stack"
	self bzStartX: bz1 put: (point1 at: 0).
	self bzStartY: bz1 put: (point1 at: 1).
	self bzViaX: bz1 put: (point2 at: 0).
	self bzViaY: bz1 put: (point2 at: 1).
	self bzEndX: bz1 put: (point3 at: 0).
	self bzEndY: bz1 put: (point3 at: 1).

	"Now check if the bezier curve is monoton. If not, subdivide it."
	index2 := bz2 := self subdivideToBeMonoton: bz1 inX: wideFlag.
	bz1 to: bz2 by: 6 do:[:index|
		index1 := self subdivideBezierFrom: index.
		index1 > index2 ifTrue:[index2 := index1].
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
	x0 := self point1Get at: 0.
	y0 := self point1Get at: 1.
	1 to: nPoints-1 do:[:i|
		self loadPoint: self point1Get from: (interpreterProxy fetchPointer: i ofObject: points).
		interpreterProxy failed ifTrue:[^nil].
		x1 := self point1Get at: 0.
		y1 := self point1Get at: 1.
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
		x0 := x1.
		y0 := y1.
	].
]

{ #category : #'shapes-polygons' }
BalloonEnginePlugin >> loadArrayShape: points nSegments: nSegments fill: fillIndex lineWidth: lineWidth lineFill: lineFill [ 
	| pointOop x0 y0 x1 y1 x2 y2 segs |
	<inline: false>
	0 to: nSegments-1 do:[:i|
		pointOop := interpreterProxy fetchPointer: (i * 3) ofObject: points.
		self loadPoint: self point1Get from: pointOop.
		pointOop := interpreterProxy fetchPointer: (i * 3 + 1) ofObject: points.
		self loadPoint: self point2Get from: pointOop.
		pointOop := interpreterProxy fetchPointer: (i * 3 + 2) ofObject: points.
		self loadPoint: self point3Get from: pointOop.
		interpreterProxy failed ifTrue:[^nil].
		self transformPoints: 3.
		x0 := self point1Get at: 0.
		y0 := self point1Get at: 1.
		x1 := self point2Get at: 0.
		y1 := self point2Get at: 1.
		x2 := self point3Get at: 0.
		y2 := self point3Get at: 1.
		"Check if we can use a line"
		((x0 = y0 and:[x1 = y1]) or:[x1 = x2 and:[y1 = y2]]) ifTrue:[
			self loadWideLine: lineWidth
				from: self point1Get
				to: self point3Get
				lineFill: lineFill
				leftFill: fillIndex
				rightFill: 0.
		] ifFalse:["Need bezier"
			segs := self loadAndSubdivideBezierFrom: self point1Get
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
	<inline: false>
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
	<var: #cmBits type: #'int *'>
	<var: #point1 type: #'int *'>
	<var: #point2 type: #'int *'>
	<var: #point3 type: #'int *'>

	cmOop == interpreterProxy nilObject ifTrue:[
		cmSize := 0.
		cmBits := nil.
	] ifFalse:[
		(interpreterProxy fetchClassOf: cmOop) = interpreterProxy classBitmap
			ifFalse:[^interpreterProxy primitiveFail].
		cmSize := interpreterProxy slotSizeOf: cmOop.
		cmBits := interpreterProxy firstIndexableField: cmOop.
	].
	(interpreterProxy isPointers: formOop) 
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy slotSizeOf: formOop) < 5 
		ifTrue:[^interpreterProxy primitiveFail].
	bmBits := interpreterProxy fetchPointer: 0 ofObject: formOop.
	(interpreterProxy fetchClassOf: bmBits) = interpreterProxy classBitmap
		ifFalse:[^interpreterProxy primitiveFail].
	bmBitsSize := interpreterProxy slotSizeOf: bmBits.
	bmWidth := interpreterProxy fetchInteger: 1 ofObject: formOop.
	bmHeight := interpreterProxy fetchInteger: 2 ofObject: formOop.
	bmDepth := interpreterProxy fetchInteger: 3 ofObject: formOop.
	interpreterProxy failed ifTrue:[^nil].
	(bmWidth >= 0 and:[bmHeight >= 0]) ifFalse:[^interpreterProxy primitiveFail].
	(bmDepth = 32) | (bmDepth = 8) | (bmDepth = 16) | 
		(bmDepth = 1) | (bmDepth = 2) | (bmDepth = 4)
			ifFalse:[^interpreterProxy primitiveFail].
	(cmSize = 0 or:[cmSize = (1 << bmDepth)])
		ifFalse:[^interpreterProxy primitiveFail].
	ppw := 32 // bmDepth.
	bmRaster := bmWidth + (ppw-1) // ppw.
	bmBitsSize = (bmRaster * bmHeight)
		ifFalse:[^interpreterProxy primitiveFail].
	bmFill := self allocateBitmapFill: cmSize colormap: cmBits.
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
	<returnTypeC:'int *'>
	xIndex := self objectIndexOf: bmFill.
	xIndex > (interpreterProxy slotSizeOf: formArray) ifTrue:[^nil].
	formOop := interpreterProxy fetchPointer: xIndex ofObject: formArray.
	bitsOop := interpreterProxy fetchPointer: 0 ofObject: formOop.
	bitsLen := interpreterProxy slotSizeOf: bitsOop.
	bitsLen = (self bitmapSizeOf: bmFill) ifFalse:[^nil].
	^interpreterProxy firstIndexableField: bitsOop
]

{ #category : #'shapes-compressed' }
BalloonEnginePlugin >> loadCompressedSegment: segmentIndex from: points short: pointsShort leftFill: leftFill rightFill: rightFill lineWidth: lineWidth lineColor: lineFill [ 
	"Load the compressed segment identified by segment index"
	| x0 y0 x1 y1 x2 y2 index segs |
	<inline: true>

	"Check if have anything to do at all"
	(leftFill = rightFill and:[lineWidth = 0 or:[lineFill = 0]]) 
		ifTrue:[^nil]. "Nothing to do"

	index := segmentIndex * 6. "3 points with x/y each"
	pointsShort ifTrue:["Load short points"
		x0 := self loadPointShortAt: (index+0) from: points.
		y0 := self loadPointShortAt: (index+1) from: points.
		x1 := self loadPointShortAt: (index+2) from: points.
		y1 := self loadPointShortAt: (index+3) from: points.
		x2 := self loadPointShortAt: (index+4) from: points.
		y2 := self loadPointShortAt: (index+5) from: points.
	] ifFalse:[
		x0 := self loadPointIntAt: (index+0) from: points.
		y0 := self loadPointIntAt: (index+1) from: points.
		x1 := self loadPointIntAt: (index+2) from: points.
		y1 := self loadPointIntAt: (index+3) from: points.
		x2 := self loadPointIntAt: (index+4) from: points.
		y2 := self loadPointIntAt: (index+5) from: points.
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
	segs := self loadAndSubdivideBezierFrom: self point1Get 
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

	<inline: false>
	<var: #points type:'int *'>
	<var: #leftFills type:'int *'>
	<var: #rightFills type:'int *'>
	<var: #lineWidths type:'int *'>
	<var: #lineFills type:'int *'>
	<var: #fillIndexList type:'int *'>

	nSegments = 0 ifTrue:[^0].

	"Initialize run length encodings"
	leftRun :=  rightRun := widthRun := lineFillRun := -1.
	leftLength := rightLength := widthLength := lineFillLength := 1.
	leftValue := rightValue := widthValue := lineFillValue := 0.

	1 to: nSegments do:[:i|
		"Decrement current run length and load new stuff"
		(leftLength := leftLength - 1) <= 0 ifTrue:[
			leftRun := leftRun + 1.
			leftLength := self shortRunLengthAt: leftRun from: leftFills.
			leftValue := self shortRunValueAt: leftRun from: leftFills.
			leftValue = 0 ifFalse:[
				leftValue := fillIndexList at: leftValue-1.
				leftValue := self transformColor: leftValue.
				engineStopped ifTrue:[^nil]]].
		(rightLength := rightLength - 1) <= 0 ifTrue:[
			rightRun := rightRun + 1.
			rightLength := self shortRunLengthAt: rightRun from: rightFills.
			rightValue := self shortRunValueAt: rightRun from: rightFills.
			rightValue = 0 ifFalse:[
				rightValue := fillIndexList at: rightValue-1.
				rightValue := self transformColor: rightValue]].
		(widthLength := widthLength - 1) <= 0 ifTrue:[
			widthRun := widthRun + 1.
			widthLength := self shortRunLengthAt: widthRun from: lineWidths.
			widthValue := self shortRunValueAt: widthRun from: lineWidths.
			widthValue = 0 ifFalse:[widthValue := self transformWidth: widthValue]].
		(lineFillLength := lineFillLength - 1) <= 0 ifTrue:[
			lineFillRun := lineFillRun + 1.
			lineFillLength := self shortRunLengthAt: lineFillRun from: lineFills.
			lineFillValue := self shortRunValueAt: lineFillRun from: lineFills.
			lineFillValue = 0 ifFalse:[lineFillValue := fillIndexList at: lineFillValue-1]].
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
	<var: #point1 type:'int *'>
	<var: #point2 type:'int *'>
	<var: #point3 type:'int *'>

	point2 at: 0 put: (point2 at: 0) + (point1 at: 0).
	point2 at: 1 put: (point2 at: 1) + (point1 at: 1).
	point3 at: 0 put: (point3 at: 0) + (point1 at: 0).
	point3 at: 1 put: (point3 at: 1) + (point1 at: 1).
	self transformPoint: point1.
	self transformPoint: point2.
	self transformPoint: point3.
	dirX := (point2 at: 0) - (point1 at: 0).
	dirY := (point2 at: 1) - (point1 at: 1).
	nrmX := (point3 at: 0) - (point1 at: 0).
	nrmY := (point3 at: 1) - (point1 at: 1).

	"Compute the scale from direction/normal into ramp size"
	dsLength2 := (dirX * dirX) + (dirY * dirY).
	dsLength2 > 0 ifTrue:[
		dsX := (dirX asFloat * fillWidth asFloat * 65536.0 / dsLength2 asFloat) asInteger.
		dsY := (dirY asFloat * fillWidth asFloat * 65536.0 / dsLength2 asFloat) asInteger.
	] ifFalse:[ dsX := 0. dsY := 0].
	dtLength2 := (nrmX * nrmX) + (nrmY * nrmY).
	dtLength2 > 0 ifTrue:[
		dtX := (nrmX asFloat * fillHeight asFloat * 65536.0 / dtLength2 asFloat) asInteger.
		dtY := (nrmY asFloat * fillHeight asFloat * 65536.0 / dtLength2 asFloat) asInteger.
	] ifFalse:[dtX := 0. dtY := 0].
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
	<inline: false>
	<var: #point1 type:'int *'>
	<var: #point2 type:'int *'>
	<var: #point3 type:'int *'>
	(interpreterProxy fetchClassOf: rampOop) = interpreterProxy classBitmap
		ifFalse:[^interpreterProxy primitiveFail].
	rampWidth := interpreterProxy slotSizeOf: rampOop.
	fill := self allocateGradientFill: (interpreterProxy firstIndexableField: rampOop)
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
	<var: #point1 type:'int *'>
	<var: #point2 type:'int *'>
	<var: #p1 type:'int *'>
	<var: #p2 type:'int *'>

	(point1 at: 1) <= (point2 at: 1) 
		ifTrue:[	p1 := point1.
				p2 := point2.
				yDir := 1]
		ifFalse:[	p1 := point2.
				p2 := point1.
				yDir := -1].
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
	<inline: false>
	w := ((self point2Get at: 0) - (self point1Get at: 0)) // 2.
	h := ((self point2Get at: 1) - (self point1Get at: 1)) // 2.
	cx := ((self point2Get at: 0) + (self point1Get at: 0)) // 2.
	cy := ((self point2Get at: 1) + (self point1Get at: 1)) // 2.
	0 to: 15 do:[:i|
		self loadOvalSegment: i w: w h: h cx: cx cy: cy.
		self transformPoints: 3.
		nSegments := self loadAndSubdivideBezierFrom: self point1Get 
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
	<inline: false>
	"Load start point of segment"
	x0 := ((self circleCosTable at: seg * 2 + 0) * w asFloat + cx) asInteger.
	y0 := ((self circleSinTable at: seg * 2 + 0) * h asFloat + cy) asInteger.
	self point1Get at: 0 put: x0.
	self point1Get at: 1 put: y0.
	"Load end point of segment"
	x2 := ((self circleCosTable at: seg * 2 + 2) * w asFloat + cx) asInteger.
	y2 := ((self circleSinTable at: seg * 2 + 2) * h asFloat + cy) asInteger.
	self point3Get at: 0 put: x2.
	self point3Get at: 1 put: y2.
	"Load intermediate point of segment"
	x1 := ((self circleCosTable at: seg * 2 + 1) * w asFloat + cx) asInteger.
	y1 := ((self circleSinTable at: seg * 2 + 1) * h asFloat + cy) asInteger.
	"NOTE: The intermediate point is the point ON the curve
	and not yet the control point (which is OFF the curve)"
	x1 := (x1 * 2) - (x0 + x2 // 2).
	y1 := (y1 * 2) - (y0 + y2 // 2).
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
	<returnTypeC:'short'>
	^(self cCoerce: shortArray to: 'short *') at: index
]

{ #category : #'shapes-polygons' }
BalloonEnginePlugin >> loadPolygon: points nPoints: nPoints fill: fillIndex lineWidth: lineWidth lineFill: lineFill pointsShort: isShort [
	| x0 y0 x1 y1 |
	<var:#points type:'int *'>
	isShort ifTrue:[
		x0 := self loadPointShortAt: 0 from: points.
		y0 := self loadPointShortAt: 1 from: points.
	] ifFalse:[
		x0 := self loadPointIntAt: 0 from: points.
		y0 := self loadPointIntAt: 1 from: points.
	].
	1 to: nPoints-1 do:[:i|
		isShort ifTrue:[
			x1 := self loadPointShortAt: i*2 from: points.
			y1 := self loadPointShortAt: i*2+1 from: points.
		] ifFalse:[
			x1 := self loadPointIntAt: i*2 from: points.
			y1 := self loadPointIntAt: i*2+1 from: points.
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
		x0 := x1.
		y0 := y1.
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
	<inline: false>
	<var:#points type:'int *'>
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
	<inline: false>
	(lineWidth = 0 or:[lineFill = 0])
		ifTrue:[wide := false.
				offset := 0]
		ifFalse:[wide := true.
				offset := self offsetFromWidth: lineWidth].
	index := nSegments * 6.
	[index > 0] whileTrue:[
		wide 
			ifTrue:[bezier := self allocateWideBezier]
			ifFalse:[bezier := self allocateBezier].
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
		index := index - 6.
	].
	self wbStackClear.
]

{ #category : #'lines-loading' }
BalloonEnginePlugin >> loadWideLine: lineWidth from: p1 to: p2 lineFill: lineFill leftFill: leftFill rightFill: rightFill [
	"Load a (possibly wide) line defined by the points p1 and p2"
	| line offset |
	<var: #p1 type:'int *'>
	<var: #p2 type:'int *'>
	(lineWidth = 0 or:[lineFill = 0])
		ifTrue:[	line := self allocateLine.
				offset := 0]
		ifFalse:[	line := self allocateWideLine.
				offset := self offsetFromWidth: lineWidth].
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
	<inline: true>
	^lineWidth // 2
]

{ #category : #primitives }
BalloonEnginePlugin >> primitiveAddBezier [
	| failureCode leftFill rightFill viaOop endOop startOop nSegments |
	<export: true>
	<inline: false>

	"Fail if we have the wrong number of arguments"
	interpreterProxy methodArgumentCount = 5 
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].

	rightFill := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 0).
	leftFill := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 1).
	viaOop := interpreterProxy stackObjectValue: 2.
	endOop := interpreterProxy stackObjectValue: 3.
	startOop := interpreterProxy stackObjectValue: 4.
	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 5)
						requiredState: GEStateUnlocked) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	"Make sure the fills are okay"
	((self isFillOkay: leftFill) and:[self isFillOkay: rightFill])
		ifFalse:[^interpreterProxy primitiveFailFor: GEFWrongFill].

	"Do a quick check if the fillIndices are equal - if so, just ignore it"
	leftFill = rightFill & false ifTrue:[
		^interpreterProxy pop: 6. "Leave rcvr on stack"
	].


	self loadPoint: self point1Get from: startOop.
	self loadPoint: self point2Get from: viaOop.
	self loadPoint: self point3Get from: endOop.
	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	self transformPoints: 3.

	nSegments := self loadAndSubdivideBezierFrom: self point1Get 
						via: self point2Get 
						to: self point3Get 
						isWide: false.
	self needAvailableSpace: nSegments * GBBaseSize.
	engineStopped ifFalse:[
		leftFill := self transformColor: leftFill.
		rightFill := self transformColor: rightFill].
	engineStopped ifFalse:[
		self loadWideBezier: 0 lineFill: 0 leftFill: leftFill rightFill: rightFill n: nSegments.
	].
	engineStopped ifTrue:[
		"Make sure the stack is okay"
		self wbStackClear.
		^interpreterProxy primitiveFailFor: GEFEngineStopped].

	interpreterProxy failed
		ifTrue:[^interpreterProxy primitiveFailFor: GEFEntityLoadFailed].
	self storeEngineStateInto: engine.
	interpreterProxy pop: 5. "Leave rcvr on stack"
]

{ #category : #primitives }
BalloonEnginePlugin >> primitiveAddBezierShape [
	| failureCode points lineFill lineWidth fillIndex length pointsIsArray segSize nSegments |
	<export: true>
	<inline: false>

	"Fail if we have the wrong number of arguments"
	interpreterProxy methodArgumentCount = 5 
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].

	lineFill := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 0).
	lineWidth := interpreterProxy stackIntegerValue: 1.
	fillIndex := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 2).
	nSegments := interpreterProxy stackIntegerValue: 3.
	points := interpreterProxy stackObjectValue: 4.
	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 5)
						requiredState: GEStateUnlocked) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	"First, do a check if the points look okay"
	length := interpreterProxy slotSizeOf: points.
	(interpreterProxy isWords: points) ifTrue:[
		pointsIsArray := false.
		"Either PointArray or ShortPointArray"
		(length = (nSegments * 3) or:[length = (nSegments * 6)])
			ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	] ifFalse:["Must be Array of points"
		(interpreterProxy isArray: points)
			ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
		length = (nSegments * 3)
			ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
		pointsIsArray := true.
	].

	"Now check that we have some hope to have enough free space.
	Do this by assuming nPoints boundaries of maximum size,
	hoping that most of the fills will be colors and many boundaries
	will be line segments"

	(lineWidth = 0 or:[lineFill = 0])
		ifTrue:[segSize := GLBaseSize]
		ifFalse:[segSize := GLWideSize].
	(self needAvailableSpace: segSize * nSegments)
		ifFalse:[^interpreterProxy primitiveFailFor: GEFWorkTooBig].

	"Check the fills"
	((self isFillOkay: lineFill) and:[self isFillOkay: fillIndex])
		ifFalse:[^interpreterProxy primitiveFailFor: GEFWrongFill]. 

	"Transform colors"
	lineFill := self transformColor: lineFill.
	fillIndex := self transformColor: fillIndex.
	engineStopped ifTrue:[^interpreterProxy primitiveFailFor: GEFEngineStopped].

	"Check if have anything at all to do"
	((lineFill = 0 or:[lineWidth = 0]) and:[fillIndex = 0])
		ifTrue:[^interpreterProxy pop: 5].

	"Transform the lineWidth"
	lineWidth = 0 ifFalse:[
		lineWidth := self transformWidth: lineWidth.
		lineWidth < 1 ifTrue:[lineWidth := 1]].

	"And load the actual shape"
	pointsIsArray ifTrue:[
		self loadArrayShape: points nSegments: nSegments
			fill: fillIndex lineWidth: lineWidth lineFill: lineFill.
	] ifFalse:[
		self loadShape: (interpreterProxy firstIndexableField: points) nSegments: nSegments
			fill: fillIndex lineWidth: lineWidth lineFill: lineFill 
			pointsShort: (nSegments * 3 = length)].

	engineStopped ifTrue:[^interpreterProxy primitiveFailFor: GEFEngineStopped].

	interpreterProxy failed
		ifTrue:[^interpreterProxy primitiveFailFor: GEFEntityLoadFailed].
	self needsFlushPut: 1.
	self storeEngineStateInto: engine.
	interpreterProxy pop: 5. "Leave rcvr on stack"
]

{ #category : #primitives }
BalloonEnginePlugin >> primitiveAddBitmapFill [

	| failureCode nrmOop dirOop originOop tileFlag fill xIndex cmOop formOop |
	<export: true>
	<inline: false>

	"Fail if we have the wrong number of arguments"
	interpreterProxy methodArgumentCount = 7 
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].

	xIndex := interpreterProxy stackIntegerValue: 0.
	xIndex <= 0 ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	nrmOop := interpreterProxy stackObjectValue: 1.
	dirOop := interpreterProxy stackObjectValue: 2.
	originOop := interpreterProxy stackObjectValue: 3.
	tileFlag := interpreterProxy booleanValueOf: (interpreterProxy stackValue: 4).
	cmOop := interpreterProxy stackObjectValue: 5.
	formOop := interpreterProxy stackObjectValue: 6.
	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 7)
						requiredState: GEStateUnlocked) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	self loadPoint: self point1Get from: originOop.
	self loadPoint: self point2Get from: dirOop.
	self loadPoint: self point3Get from: nrmOop.
	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: GEFBadPoint].

	fill := self loadBitmapFill: formOop 
				colormap: cmOop
				tile: (tileFlag ifTrue:[1] ifFalse:[0])
				from: self point1Get 
				along: self point2Get 
				normal: self point3Get 
				xIndex: xIndex-1.
	engineStopped ifTrue:[
		"Make sure the stack is okay"
		^interpreterProxy primitiveFailFor: GEFEngineStopped].

	interpreterProxy failed
		ifTrue:[^interpreterProxy primitiveFailFor: GEFEntityLoadFailed].
	self storeEngineStateInto: engine.
	interpreterProxy pop: 8 thenPush: (interpreterProxy positive32BitIntegerFor: fill)
]

{ #category : #primitives }
BalloonEnginePlugin >> primitiveAddCompressedShape [
	| failureCode fillIndexList lineFills lineWidths rightFills leftFills nSegments points pointsShort |
	<export: true>
	<inline: false>

	"Fail if we have the wrong number of arguments"
	interpreterProxy methodArgumentCount = 7 
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].

	fillIndexList := interpreterProxy stackObjectValue: 0.
	lineFills := interpreterProxy stackObjectValue: 1.
	lineWidths := interpreterProxy stackObjectValue: 2.
	rightFills := interpreterProxy stackObjectValue: 3.
	leftFills := interpreterProxy stackObjectValue: 4.
	nSegments := interpreterProxy stackIntegerValue: 5.
	points := interpreterProxy stackObjectValue: 6.
	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 7)
						requiredState: GEStateUnlocked) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	"First, do a check if the compressed shape is okay"
	(self checkCompressedShape: points 
			segments: nSegments 
			leftFills: leftFills 
			rightFills: rightFills 
			lineWidths: lineWidths 
			lineFills: lineFills 
			fillIndexList: fillIndexList) ifFalse:[^interpreterProxy primitiveFailFor: GEFEntityCheckFailed].

	"Now check that we have some hope to have enough free space.
	Do this by assuming nSegments boundaries of maximum size,
	hoping that most of the fills will be colors and many boundaries
	will be line segments"

	(self needAvailableSpace: (GBBaseSize max: GLBaseSize) * nSegments)
		ifFalse:[^interpreterProxy primitiveFailFor: GEFWorkTooBig].

	"Check if the points are short"
	pointsShort := (interpreterProxy slotSizeOf: points) = (nSegments * 3).

	"Then actually load the compressed shape"
	self loadCompressedShape: (interpreterProxy firstIndexableField: points)
			segments: nSegments 
			leftFills: (interpreterProxy firstIndexableField: leftFills)
			rightFills: (interpreterProxy firstIndexableField: rightFills)
			lineWidths: (interpreterProxy firstIndexableField: lineWidths)
			lineFills: (interpreterProxy firstIndexableField: lineFills)
			fillIndexList: (interpreterProxy firstIndexableField: fillIndexList)
			pointShort: pointsShort.

	engineStopped ifTrue:[^interpreterProxy primitiveFailFor: GEFEngineStopped].

	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: GEFEntityLoadFailed].
	self needsFlushPut: 1.
	self storeEngineStateInto: engine.
	interpreterProxy pop: 7. "Leave rcvr on stack"
]

{ #category : #primitives }
BalloonEnginePlugin >> primitiveAddGradientFill [

	| failureCode isRadial nrmOop dirOop originOop rampOop fill |
	<export: true>
	<inline: false>

	"Fail if we have the wrong number of arguments"
	interpreterProxy methodArgumentCount = 5 
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].

	isRadial := interpreterProxy booleanValueOf: (interpreterProxy stackValue: 0).
	nrmOop := interpreterProxy stackValue: 1.
	dirOop := interpreterProxy stackValue: 2.
	originOop := interpreterProxy stackValue: 3.
	rampOop := interpreterProxy stackValue: 4.
	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 5)
						requiredState: GEStateUnlocked) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	self loadPoint: self point1Get from: originOop.
	self loadPoint: self point2Get from: dirOop.
	self loadPoint: self point3Get from: nrmOop.
	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: GEFBadPoint].

	fill := self loadGradientFill: rampOop 
				from: self point1Get 
				along: self point2Get 
				normal: self point3Get 
				isRadial: isRadial.
	engineStopped ifTrue:[
		"Make sure the stack is okay"
		^interpreterProxy primitiveFailFor: GEFEngineStopped].

	interpreterProxy failed
		ifTrue: [^interpreterProxy primitiveFailFor: GEFEntityLoadFailed].
	self storeEngineStateInto: engine.
	interpreterProxy pop: 6 thenPush: (interpreterProxy positive32BitIntegerFor: fill)
]

{ #category : #primitives }
BalloonEnginePlugin >> primitiveAddLine [
	| failureCode leftFill rightFill endOop startOop |
	<export: true>
	<inline: false>

	"Fail if we have the wrong number of arguments"
	interpreterProxy methodArgumentCount = 4 
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].

	rightFill := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 0).
	leftFill := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 1).
	endOop := interpreterProxy stackObjectValue: 2.
	startOop := interpreterProxy stackObjectValue: 3.
	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 4)
			requiredState: GEStateUnlocked) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	"Make sure the fills are okay"
	((self isFillOkay: leftFill) and:[self isFillOkay: rightFill])
			ifFalse:[^interpreterProxy primitiveFailFor: GEFWrongFill].

	"Load the points"
	self loadPoint: self point1Get from: startOop.
	self loadPoint: self point2Get from: endOop.
	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: GEFBadPoint].

	"Transform points"
	self transformPoints: 2.

	"Transform colors"
	leftFill := self transformColor: leftFill.
	rightFill := self transformColor: rightFill.
	engineStopped ifTrue:[^interpreterProxy primitiveFailFor: GEFEngineStopped].

	"Load line"
	self loadWideLine: 0 from: self point1Get to: self point2Get 
		lineFill: 0 leftFill: leftFill rightFill: rightFill.
	engineStopped ifTrue:[^interpreterProxy primitiveFailFor: GEFEngineStopped].

	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: GEFEntityLoadFailed].
	self storeEngineStateInto: engine.
	interpreterProxy pop: 4. "Leave rcvr on stack"
]

{ #category : #primitives }
BalloonEnginePlugin >> primitiveAddOval [
	| failureCode fillIndex borderWidth borderIndex endOop startOop |
	<export: true>
	<inline: false>

	"Fail if we have the wrong number of arguments"
	interpreterProxy methodArgumentCount = 5 
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].

	borderIndex := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 0).
	borderWidth := interpreterProxy stackIntegerValue: 1.
	fillIndex := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 2).
	endOop := interpreterProxy stackObjectValue: 3.
	startOop := interpreterProxy stackObjectValue: 4.
	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 5)
					requiredState: GEStateUnlocked) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	"Make sure the fills are okay"
	((self isFillOkay: borderIndex) and:[self isFillOkay: fillIndex])
			ifFalse:[^interpreterProxy primitiveFailFor: GEFWrongFill].

	"Transform colors"
	fillIndex := self transformColor: fillIndex.
	borderIndex := self transformColor: borderIndex.
	engineStopped ifTrue:[^interpreterProxy primitiveFailFor: GEFEngineStopped].

	"Check if we have anything at all to do"
	(fillIndex = 0 and:[borderIndex = 0 or:[borderWidth <= 0]]) ifTrue:[
		^interpreterProxy pop: 5. "Leave rcvr on stack"
	].

	"Make sure we have some space"
	(self needAvailableSpace: (16 * GBBaseSize)) 
		ifFalse:[^interpreterProxy primitiveFailFor: GEFWorkTooBig].

	"Check if we need a border"
	(borderWidth > 0 and:[borderIndex ~= 0]) 
		ifTrue:[borderWidth := self transformWidth: borderWidth]
		ifFalse:[borderWidth := 0].


	"Load the rectangle points"
	self loadPoint: self point1Get from: startOop.
	self loadPoint: self point2Get from: endOop.
	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: GEFBadPoint].

	self loadOval: borderWidth lineFill: borderIndex 
		leftFill: 0 rightFill: fillIndex.

	engineStopped ifTrue:[
		self wbStackClear.
		^interpreterProxy primitiveFailFor: GEFEngineStopped.
	].
	interpreterProxy failed
		ifTrue:[^interpreterProxy primitiveFailFor: GEFEntityLoadFailed].
	self needsFlushPut: 1.
	self storeEngineStateInto: engine.
	interpreterProxy pop: 5. "Leave rcvr on stack"
]

{ #category : #primitives }
BalloonEnginePlugin >> primitiveAddPolygon [
	| failureCode points lineFill lineWidth fillIndex nPoints length pointsIsArray segSize |
	<export: true>
	<inline: false>

	"Fail if we have the wrong number of arguments"
	interpreterProxy methodArgumentCount = 5 
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].

	lineFill := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 0).
	lineWidth := interpreterProxy stackIntegerValue: 1.
	fillIndex := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 2).
	nPoints := interpreterProxy stackIntegerValue: 3.
	points := interpreterProxy stackObjectValue: 4.
	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 5)
						requiredState: GEStateUnlocked) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	"First, do a check if the points look okay"
	length := interpreterProxy slotSizeOf: points.
	(interpreterProxy isWords: points) ifTrue:[
		pointsIsArray := false.
		"Either PointArray or ShortPointArray"
		(length = nPoints or:[nPoints * 2 = length])
			ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	] ifFalse:["Must be Array of points"
		(interpreterProxy isArray: points)
			ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
		length = nPoints
			ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
		pointsIsArray := true.
	].

	"Now check that we have some hope to have enough free space.
	Do this by assuming nPoints boundaries of maximum size,
	hoping that most of the fills will be colors and many boundaries
	will be line segments"

	(lineWidth = 0 or:[lineFill = 0])
		ifTrue:[segSize := GLBaseSize]
		ifFalse:[segSize := GLWideSize].
	(self needAvailableSpace: segSize * nPoints)
		ifFalse:[^interpreterProxy primitiveFail].

	"Check the fills"
	((self isFillOkay: lineFill) and:[self isFillOkay: fillIndex])
		ifFalse:[^interpreterProxy primitiveFailFor: GEFWrongFill]. 

	"Transform colors"
	lineFill := self transformColor: lineFill.
	fillIndex := self transformColor: fillIndex.
	engineStopped ifTrue:[^interpreterProxy primitiveFailFor: GEFEngineStopped].

	"Check if have anything at all to do"
	((lineFill = 0 or:[lineWidth = 0]) and:[fillIndex = 0])
		ifTrue:[^interpreterProxy pop: 5].

	"Transform the lineWidth"
	lineWidth = 0 ifFalse:[lineWidth := self transformWidth: lineWidth].

	"And load the actual polygon"
	pointsIsArray ifTrue:[
		self loadArrayPolygon: points nPoints: nPoints
			fill: fillIndex lineWidth: lineWidth lineFill: lineFill
	] ifFalse:[
		self loadPolygon: (interpreterProxy firstIndexableField: points) nPoints: nPoints 
			fill: fillIndex lineWidth: lineWidth lineFill: lineFill 
			pointsShort: (nPoints = length)].

	engineStopped ifTrue:[^interpreterProxy primitiveFailFor: GEFEngineStopped].

	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: GEFEntityLoadFailed].
	self needsFlushPut: 1.
	self storeEngineStateInto: engine.
	interpreterProxy pop: 5. "Leave rcvr on stack"
]

{ #category : #primitives }
BalloonEnginePlugin >> primitiveAddRect [
	| failureCode fillIndex borderWidth borderIndex endOop startOop |
	<export: true>
	<inline: false>

	"Fail if we have the wrong number of arguments"
	interpreterProxy methodArgumentCount = 5 
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].

	borderIndex := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 0).
	borderWidth := interpreterProxy stackIntegerValue: 1.
	fillIndex := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 2).
	endOop := interpreterProxy stackObjectValue: 3.
	startOop := interpreterProxy stackObjectValue: 4.
	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 5)
						requiredState: GEStateUnlocked) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	"Make sure the fills are okay"
	((self isFillOkay: borderIndex) and:[self isFillOkay: fillIndex])
		ifFalse:[^interpreterProxy primitiveFailFor: GEFWrongFill].

	"Transform colors"
	borderIndex := self transformColor: borderIndex.
	fillIndex := self transformColor: fillIndex.
	engineStopped ifTrue:[^interpreterProxy primitiveFailFor: GEFEngineStopped].

	"Check if we have anything at all to do"
	(fillIndex = 0 and:[borderIndex = 0 or:[borderWidth = 0]]) ifTrue:[
		^interpreterProxy pop: 5. "Leave rcvr on stack"
	].

	"Make sure we have some space"
	(self needAvailableSpace: (4 * GLBaseSize)) 
		ifFalse:[^interpreterProxy primitiveFailFor: GEFWorkTooBig].

	"Check if we need a border"
	(borderWidth > 0 and:[borderIndex ~= 0]) 
		ifTrue:[borderWidth := self transformWidth: borderWidth]
		ifFalse:[borderWidth := 0].

	"Load the rectangle"
	self loadPoint: self point1Get from: startOop.
	self loadPoint: self point3Get from: endOop.
	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: GEFBadPoint].
	self point2Get at: 0 put: (self point3Get at: 0).
	self point2Get at: 1 put: (self point1Get at: 1).
	self point4Get at: 0 put: (self point1Get at: 0).
	self point4Get at: 1 put: (self point3Get at: 1).
	"Transform the points"
	self transformPoints: 4.

	self loadRectangle: borderWidth lineFill: borderIndex leftFill: 0 rightFill: fillIndex.

	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: GEFEntityLoadFailed].
	self needsFlushPut: 1.
	self storeEngineStateInto: engine.
	interpreterProxy pop: 5. "Leave rcvr on stack"
]

{ #category : #primitives }
BalloonEnginePlugin >> primitiveGetBezierStats [
	| failureCode statOop stats |
	<export: true>
	<inline: false>
	<var: #stats type:'int *'>

	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].

	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 1)) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	statOop := interpreterProxy stackObjectValue: 0.
	(interpreterProxy failed not
	and: [(interpreterProxy isWords: statOop)
	and: [(interpreterProxy slotSizeOf: statOop) >= 4]])
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	stats := interpreterProxy firstIndexableField: statOop.
	stats at: 0 put: (stats at: 0) + (workBuffer at: GWBezierMonotonSubdivisions).
	stats at: 1 put: (stats at: 1) + (workBuffer at: GWBezierHeightSubdivisions).
	stats at: 2 put: (stats at: 2) + (workBuffer at: GWBezierOverflowSubdivisions).
	stats at: 3 put: (stats at: 3) + (workBuffer at: GWBezierLineConversions).

	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #private }
BalloonEnginePlugin >> rShiftTable [
	| theTable |
	<returnTypeC:'int *'>
	<inline: false>
	<var:#theTable declareC:'static int theTable[17] =
		{0, 5, 4, 0, 3, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1}'>
	^theTable
]

{ #category : #'fills-bitmaps' }
BalloonEnginePlugin >> repeatValue: delta max: maxValue [
	| newDelta |
	<inline: true>
	newDelta := delta.
	[newDelta < 0] whileTrue:[newDelta := newDelta + maxValue].
	[newDelta >= maxValue] whileTrue:[newDelta := newDelta - maxValue].
	^newDelta
]

{ #category : #'beziers-wide' }
BalloonEnginePlugin >> returnWideBezierFill [
	^(dispatchReturnValue := self wideBezierFillOf: dispatchedValue).
]

{ #category : #'beziers-wide' }
BalloonEnginePlugin >> returnWideBezierWidth [
	^(dispatchReturnValue := self wideBezierWidthOf: dispatchedValue).
]

{ #category : #'lines-wide' }
BalloonEnginePlugin >> returnWideLineFill [
	"Return the fill of the (wide) line - this method is called from a case."
	^(dispatchReturnValue := self wideLineFillOf: dispatchedValue).
]

{ #category : #'lines-wide' }
BalloonEnginePlugin >> returnWideLineWidth [
	"Return the width of the (wide) line - this method is called from a case."
	^(dispatchReturnValue := self wideLineWidthOf: dispatchedValue).
]

{ #category : #private }
BalloonEnginePlugin >> shortRunLengthAt: i from: runArray [
	"Return the run-length value from the given ShortRunArray."
	^((self cCoerce: runArray to:'int *') at: i) bitShift: -16
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
	<inline: true>
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
	<inline: false>
	<var: #updateData type:'int *'>


	"Do a quick check if there is anything at all to do"
	((self isWide: bezier) not and:[yValue >= (self bezierEndYOf: bezier)])
		ifTrue:[^self edgeNumLinesOf: bezier put: 0].

	"Now really initialize bezier"
	startX := self edgeXValueOf: bezier.
	startY := self edgeYValueOf: bezier.
	viaX := self bezierViaXOf: bezier.
	viaY := self bezierViaYOf: bezier.
	endX := self bezierEndXOf: bezier.
	endY := self bezierEndYOf: bezier.
	deltaY := endY - startY.

	"Initialize integer forward differencing"
	fwX1 := (viaX - startX) * 2.
	fwX2 := startX + endX - (viaX * 2).
	fwY1 := (viaY - startY) * 2.
	fwY2 := startY + endY - (viaY * 2).
	maxSteps := deltaY * 2.
	maxSteps < 2 ifTrue:[maxSteps := 2].
	scaledStepSize := 16r1000000 // maxSteps.
	squaredStepSize := self absoluteSquared8Dot24: scaledStepSize.
	fwDx := fwX1 * scaledStepSize.
	fwDDx := fwX2 * squaredStepSize * 2.
	fwDx := fwDx + (fwDDx // 2).
	fwDy := fwY1 * scaledStepSize.
	fwDDy := fwY2 * squaredStepSize * 2.
	fwDy := fwDy + (fwDDy // 2).

	"Store the values"
	self edgeNumLinesOf: bezier put: deltaY.

	updateData := self bezierUpdateDataOf: bezier.
	updateData at: GBUpdateX put: (startX * 256).
	updateData at: GBUpdateY put: (startY * 256).
	updateData at: GBUpdateDX put: fwDx.
	updateData at: GBUpdateDY put: fwDy.
	updateData at: GBUpdateDDX put: fwDDx.
	updateData at: GBUpdateDDY put: fwDDy.

	"And step to the first scan line"
	(startY := self edgeYValueOf: bezier) = yValue ifFalse:[
		self stepToNextBezierIn: bezier at: yValue.
		"Adjust number of lines remaining"
		self edgeNumLinesOf: bezier put: deltaY - (yValue - startY).
	].
]

{ #category : #'lines-simple' }
BalloonEnginePlugin >> stepToFirstLine [
	"Initialize the current entry in the GET by stepping to the current scan line"
	<inline: true>
	^self stepToFirstLineIn: (getBuffer at: self getStartGet) at: self currentYGet
]

{ #category : #'lines-simple' }
BalloonEnginePlugin >> stepToFirstLineIn: line at: yValue [
	"Initialize the line at yValue"
	| deltaX deltaY xDir widthX error xInc errorAdjUp startY |
	<inline: false>

	"Do a quick check if there is anything at all to do"
	((self isWide: line) not and:[yValue >= (self lineEndYOf: line)])
		ifTrue:[^self edgeNumLinesOf: line put: 0].

	deltaX := (self lineEndXOf: line) - (self edgeXValueOf: line).
	deltaY := (self lineEndYOf: line) - (self edgeYValueOf: line).

	"Check if edge goes left to right"
	deltaX >= 0 
		ifTrue:[	xDir := 1.
				widthX := deltaX.
				error := 0]
		ifFalse:[	xDir := -1.
				widthX := 0 - deltaX.
				error := 1 - deltaY].

	"Check if deltaY is zero.
	Note: We could actually get out here immediately 
	but wide lines rely on an accurate setup in this case"
	deltaY = 0
		ifTrue:[	error := 0.			"No error for horizontal edges"
				xInc := deltaX.		"Encodes width and direction"
				errorAdjUp := 0]
		ifFalse:["Check if edge is y-major"
				deltaY > widthX "Note: The '>' instead of '>=' could be important here..."
					ifTrue:[	xInc := 0.
							errorAdjUp := widthX]
					ifFalse:[	xInc := (widthX // deltaY) * xDir.
							errorAdjUp := widthX \\ deltaY]].

	"Store the values"
	self edgeNumLinesOf: line put: deltaY.
	self lineXDirectionOf: line put: xDir.
	"self lineYDirectionOf: line put: yDir." "<-- Already set"
	self lineXIncrementOf: line put: xInc.
	self lineErrorOf: line put: error.
	self lineErrorAdjUpOf: line put: errorAdjUp.
	self lineErrorAdjDownOf: line put: deltaY.

	"And step to the first scan line"
	(startY := self edgeYValueOf: line) = yValue ifFalse:[
		startY to: yValue-1 do:[:i| self stepToNextLineIn: line at: i].
		"Adjust number of lines remaining"
		self edgeNumLinesOf: line put: deltaY - (yValue - startY).
	].
]

{ #category : #'beziers-wide' }
BalloonEnginePlugin >> stepToFirstWideBezier [
	"Initialize the current entry in the GET by stepping to the current scan line"
	<inline: true>
	^self stepToFirstWideBezierIn: (getBuffer at: self getStartGet) at: self currentYGet
]

{ #category : #'beziers-wide' }
BalloonEnginePlugin >> stepToFirstWideBezierIn: bezier at: yValue [
	"Initialize the bezier at yValue"	
	| lineWidth startY nLines yEntry yExit lineOffset endX xDir |
	<inline: false>

	"Get some values"
	lineWidth := self wideBezierExtentOf: bezier.
	lineOffset := self offsetFromWidth: lineWidth.

	"Compute the incremental values of the bezier"
	endX := self bezierEndXOf: bezier.
	startY := self edgeYValueOf: bezier.
	self stepToFirstBezierIn: bezier at: startY.
	nLines := (self edgeNumLinesOf: bezier).

	"Copy the incremental update data"
	0 to: 5 do:[:i|
		(self wideBezierUpdateDataOf: bezier) at: i put:
			((self bezierUpdateDataOf: bezier) at: i).
	].

	"Compute primary x direction of curve (e.g., 1: left to right; -1: right to left)."
	xDir := ((self bezierUpdateDataOf: bezier) at: GBUpdateDX).
	xDir = 0 ifTrue:[xDir := ((self bezierUpdateDataOf: bezier) at: GBUpdateDDX)].
	xDir >= 0 ifTrue:[xDir := 1] ifFalse:[xDir := -1].

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
	yEntry := 0.						"turned on at lineOffset"
	yExit := 0 - nLines - lineOffset.	"turned off at zero"
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
	<inline: true>
	^self stepToFirstWideLineIn: (getBuffer at: self getStartGet) at: self currentYGet
]

{ #category : #'lines-wide' }
BalloonEnginePlugin >> stepToFirstWideLineIn: line at: yValue [
	"Initialize the wide line at yValue."
	| startY yEntry yExit lineWidth nLines lineOffset startX xDir |
	<inline: false>

	"Get some values"
	lineWidth := self wideLineExtentOf: line.
	lineOffset := self offsetFromWidth: lineWidth.

	"Compute the incremental values of the line"
	startX := self edgeXValueOf: line.
	startY := self edgeYValueOf: line.
	self stepToFirstLineIn: line at: startY.
	nLines := (self edgeNumLinesOf: line).
	xDir := self lineXDirectionOf: line.

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
	yEntry := 0.						"turned on at lineOffset"
	yExit := 0 - nLines - lineOffset.	"turned off at zero"
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
	<inline: true>
	^self stepToNextBezierIn: (aetBuffer at: self aetStartGet) at: self currentYGet
]

{ #category : #'beziers-simple' }
BalloonEnginePlugin >> stepToNextBezierForward: updateData at: yValue [
	"Incrementally step to the next scan line in the given bezier update data.
	Note: This method has been written so that inlining works, e.g.,
		not declaring updateData as 'int*' but casting it on every use."
	<var: #updateData type:'int *'>
	| minY lastX lastY fwDx fwDy |
	<inline: true>
	lastX := updateData at: GBUpdateX.
	lastY := updateData at: GBUpdateY.
	fwDx := updateData at: GBUpdateDX.
	fwDy := updateData at: GBUpdateDY.
	minY := yValue * 256.
	"Step as long as we haven't yet reached minY and also
	as long as fwDy is greater than zero thus stepping down.
	Note: The test for fwDy should not be necessary in theory
		but is a good insurance in practice."
	[minY > lastY and:[fwDy >= 0]] whileTrue:[
		lastX := lastX + ((fwDx + 16r8000) signedBitShift: -16).
		lastY := lastY + ((fwDy + 16r8000) signedBitShift: -16).
		fwDx := fwDx + (updateData at: GBUpdateDDX).
		fwDy := fwDy + (updateData at: GBUpdateDDY).
	].
	updateData at: GBUpdateX put: lastX.
	updateData at: GBUpdateY put: lastY.
	updateData at: GBUpdateDX put: fwDx.
	updateData at: GBUpdateDY put: fwDy.
	^lastX signedBitShift: -8

]

{ #category : #'beziers-simple' }
BalloonEnginePlugin >> stepToNextBezierIn: bezier at: yValue [
	"Incrementally step to the next scan line in the given bezier"
	|  xValue |
	<inline: true>
	xValue := self stepToNextBezierForward: (self bezierUpdateDataOf: bezier) at: yValue.
	self edgeXValueOf: bezier put: xValue.
]

{ #category : #'lines-simple' }
BalloonEnginePlugin >> stepToNextLine [
	"Process the current entry in the AET by stepping to the next scan line"
	<inline: true>
	^self stepToNextLineIn: (aetBuffer at: self aetStartGet) at: self currentYGet
]

{ #category : #'lines-simple' }
BalloonEnginePlugin >> stepToNextLineIn: line at: yValue [
	"Incrementally step to the next scan line in the given line"
	| x  err |
	<inline: true>
	x := (self edgeXValueOf: line) + (self lineXIncrementOf: line).
	err := (self lineErrorOf: line) + (self lineErrorAdjUpOf: line).
	err > 0 ifTrue:[
		x := x + (self lineXDirectionOf: line).
		err := err - (self lineErrorAdjDownOf: line).
	].
	self lineErrorOf: line put: err.
	self edgeXValueOf: line put: x.
]

{ #category : #'beziers-wide' }
BalloonEnginePlugin >> stepToNextWideBezier [
	"Initialize the current entry in the GET by stepping to the current scan line"
	<inline: true>
	self stepToNextWideBezierIn: (aetBuffer at: self aetStartGet) at: self currentYGet.
]

{ #category : #'beziers-wide' }
BalloonEnginePlugin >> stepToNextWideBezierIn: bezier at: yValue [
	"Incrementally step to the next scan line in the given wide bezier"
	|  yEntry yExit lineWidth lineOffset |
	<inline: false>	"Don't inline this"

	lineWidth := self wideBezierExtentOf: bezier.
	lineOffset := self offsetFromWidth: lineWidth.

	yEntry := (self wideBezierEntryOf: bezier) + 1.
	yExit := (self wideBezierExitOf: bezier) + 1.
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
	<inline: true>
	^self stepToNextWideLineIn: (aetBuffer at: self aetStartGet) at: self currentYGet
]

{ #category : #'lines-wide' }
BalloonEnginePlugin >> stepToNextWideLineIn: line at: yValue [
	"Incrementally step to the next scan line in the given wide line"
	|  yEntry yExit lineWidth lineOffset lastX nextX |
	<inline: true>

	"Adjust entry/exit values"
	yEntry := (self wideLineEntryOf: line) + 1.
	yExit := (self wideLineExitOf: line) + 1.
	self wideLineEntryOf: line put: yEntry.
	self wideLineExitOf: line put: yExit.

	"Turn fills on/off"
	lineWidth := self wideLineExtentOf: line.
	lineOffset := self offsetFromWidth: lineWidth.
	yEntry >= lineOffset ifTrue:[self edgeFillsValidate: line].
	yExit >= 0 ifTrue:[self edgeFillsInvalidate: line].

	"Step to the next scan line"
	lastX := self edgeXValueOf: line.
	self stepToNextLineIn: line at: yValue.
	nextX := self edgeXValueOf: line.

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
	<inline: false>
	startY := self bzStartY: index.
	endY := self bzEndY: index.

	"If the receiver is horizontal, don't do anything"
	(endY = startY) ifTrue:[^index].

	"TODO: If the curve can be represented as a line, then do so"

	"If the height of the curve exceeds 256 pixels, subdivide 
	(forward differencing is numerically not very stable)"
	deltaY := endY - startY.
	deltaY < 0 ifTrue:[deltaY := 0 - deltaY].
	(deltaY > 255) ifTrue:[
		self incrementStat: GWBezierHeightSubdivisions by: 1.
		^self computeBezierSplitAtHalf: index].

	"Check if the incremental values could possibly overflow the scaled integer range"
	startX := self bzStartX: index.
	endX := self bzEndX: index.
	deltaX := endX - startX.
	deltaX < 0 ifTrue:[deltaX := 0 - deltaX].
	deltaY * 32 < deltaX ifTrue:[
		self incrementStat: GWBezierOverflowSubdivisions by: 1.
		^self computeBezierSplitAtHalf: index].
	^index

]

{ #category : #'bezier-loading' }
BalloonEnginePlugin >> subdivideBezierFrom: index [
	"Recursively subdivide the curve on the bezier stack."
	| otherIndex index1 index2 |
	<inline: false>
	otherIndex := self subdivideBezier: index.
	otherIndex = index ifFalse:[
		index1 := self subdivideBezierFrom: index.
		engineStopped ifTrue:[^0].
		index2 := self subdivideBezierFrom: otherIndex.
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
	<inline: false>
	base2 := index1 := index2 := self subdivideToBeMonotonInY: base.
	doTestX ifTrue:[index1 := self subdivideToBeMonotonInX: base].
	index1 > index2 ifTrue:[index2 := index1].
	(base ~= base2 and:[doTestX]) ifTrue:[index1 := self subdivideToBeMonotonInX: base2].
	index1 > index2 ifTrue:[index2 := index1].
	^index2
]

{ #category : #'bezier-loading' }
BalloonEnginePlugin >> subdivideToBeMonotonInX: index [
	"Check if the given bezier curve is monoton in X. If not, subdivide it"
	| denom num startX viaX endX dx1 dx2 |
	<inline: false>
	startX := self bzStartX: index.
	viaX := self bzViaX: index.
	endX := self bzEndX: index.

	dx1 := viaX - startX.
	dx2 := endX - viaX.
	(dx1 * dx2) >= 0 ifTrue:[^index]. "Bezier is monoton"

	self incrementStat: GWBezierMonotonSubdivisions by: 1.
	"Compute split value"
	denom := dx2 - dx1.
	num := dx1.
	num < 0 ifTrue:[num := 0 - num].
	denom < 0 ifTrue:[denom := 0 - denom].
	^self computeBezier: index splitAt: (num asFloat / denom asFloat).
]

{ #category : #'bezier-loading' }
BalloonEnginePlugin >> subdivideToBeMonotonInY: index [
	"Check if the given bezier curve is monoton in Y. If not, subdivide it"
	| startY viaY endY dy1 dy2 denom num |
	<inline: false>
	startY := self bzStartY: index.
	viaY := self bzViaY: index.
	endY := self bzEndY: index.

	dy1 := viaY - startY.
	dy2 := endY - viaY.
	(dy1 * dy2) >= 0 ifTrue:[^index]. "Bezier is monoton"

	self incrementStat: GWBezierMonotonSubdivisions by: 1.
	"Compute split value"
	denom := dy2 - dy1.
	num := dy1.
	num < 0 ifTrue:[num := 0 - num].
	denom < 0 ifTrue:[denom := 0 - denom].
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
	<returnTypeC: 'int *'>

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
