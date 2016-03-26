"
This is the main class for the Balloon graphics Engine.

BalloonEnginePlugin should be translated but its superclass should not since it is incorporated within that class's translation process. Nor should the simulation subclass be translated
"
Class {
	#name : #BalloonEngineBase,
	#superclass : #InterpreterPlugin,
	#instVars : [
		'workBuffer',
		'objBuffer',
		'getBuffer',
		'aetBuffer',
		'spanBuffer',
		'engine',
		'formArray',
		'engineStopped',
		'geProfileTime',
		'dispatchedValue',
		'dispatchReturnValue',
		'objUsed',
		'doProfileStats',
		'copyBitsFn',
		'loadBBFn',
		'bbPluginName'
	],
	#classVars : [
		'EdgeInitTable',
		'EdgeStepTable',
		'FillTable',
		'WideLineFillTable',
		'WideLineWidthTable'
	],
	#pools : [
		'BalloonEngineConstants'
	],
	#category : #'VMMaker-Plugins'
}

{ #category : #documentation }
BalloonEngineBase class >> a1EngineOutline [
	"The following is a brief outline on how the engine works.

	In general, we're using a pretty straight-forward active edge approach, e.g., 
	we classify all edges into three different states:
		a) Waiting for processing
		b) Active (e.g., being processed)
		c) Finished
	Before the engine starts all edges are sorted by their y-value in a so-called
	'global edge table' (furthermore referred to as GET) and processed in top 
	to bottom order (the edges are also sorted by x-value but this is only for 
	simplifying the insertion when adding edges).

	Then, we start at the first visible scan line and execute the following steps:

	1) Move all edges starting at the current scan line from state a) to state b)

	This step requires the GET to be sorted so that we only need to check
	the first edges of the GET. After the initial state of the edge (e.g., it's current
	pixel value and data required for incremental updates) the edges are then 
	inserted in the 'active edge table' (called AET). The sort order in the AET is 
	defined by the pixel position of each edge at the current scan line and thus 
	edges are kept in increasing x-order.

	This step does occur for every edge only once and is therefore not the most
	time-critical part of the approach.

	2) Draw the current scan line

	This step includes two sub-parts. In the first part, the scan line is assembled.
	This involves walking through the AET and drawing the pixels between
	each two neighbour edges. Since each edge can have two associated fills
	(a 'left' and a 'right' fill) we need to make sure that edges falling on the
	same pixel position do not affect the painted image. This issue is discussed
	in the aetScanningProblems documentation.

	Wide edges (e.g., edges having an associated width) are also handled during
	this step. Wide edges are always preferred over interior fills - this ensures
	that the outline of an object cannot be overdrawn by any interior fill of
	a shape that ends very close to the edge (for more information see wideEdges 
	documentation).

	After the scan is assembled it is blitted to the screen. This only happens all
	'aaLevel' scan lines (for further information see the antiAliasing documentation).

	This second step is done at each scan line in the image, and is usually the most
	time-critical part.

	3) Update all currently active edges

	Updating the active edges basically means either to remove the edge from the AET
	(if it is at the end y value) or incrementally computing the pixel value for the
	next scan line. Based on the information gathered in the first step, this part
	should be executed as fast as possible - it happens for each edge in the AET
	at each scan line and may be the bottleneck if many edges are involved in
	the drawing operations (see the TODO list; part of it probably deals with the
	issue).

"
	^self error:'Comment only'
]

{ #category : #documentation }
BalloonEngineBase class >> a2AntiAliasing [
	"The engine currently used a very simple, but efficient anti-aliasing scheme. It is based on a square unweighted filter of size 1, 2, or 4 resulting in three levels of anti-aliasing:

	* No anti-aliasing (filter size 1)
	This simply draws each pixel 'as is' on the screen

	* Slight anti-aliasing (filter size 2)
	Doubles the rasterization size in each direction and assembles the pixel value as the medium of the four sub-pixels falling into the full pixel

	* Full anti-aliasing (filter size 4)
	Quadruples the rasterization in each direction and assembles the pixel value as the medium of the sixteen sub-pixels falling into the full pixel


The reason for using these three AA levels is simply efficiency of computing. Since the above filters (1x1, 2x2, 4x4) have all power of two elements (1, 4, and 16) we can compute the weighted sum of the final pixel by computing

	destColor := destColor + (srcColor // subPixels)

And, since we're only working on 32bit destination buffer we do not need to compute the components of each color separately but can neatly put the entire color into a single formula:

	destPixel32 := destPixel32 + ((srcPixel32 bitAnd: aaMask) >> aaShift).

with aaMask = 16rFFFFFFFF for aaLevel = 1, aaMask = 16rFCFCFCFC for aaLevel = 2, aaMask = 16rF0F0F0F0 for aaLevel = 4 and aaShift = 0, 2, or 4 for the different levels. However, while the above is efficient to compute, it also drops accuracy. So, for the 4x4 anti-aliasing we're effectively only using the high 4 bits of each color component. While is generally not a problem (we add 16 sub-pixels into this value) there is a simple arithmetic difficulty because the above cannot fill the entire range of values, e.g.,

	16 * (255 // 16) = 16 * 15 = 240

and not 255 as expected. We solve this problem by replicating the top n (n=0, 2, 4) bits of each component as the low bits in an adjustment step before blitting to scan line to the screen. This has the nice effect that a zero pixel value (e.g., transparent) will remain zero, a white pixel (as computed above) will result in a value of 255 for each component (defining opaque white) and each color inbetween linearly mapped between 0 and 255. 

"
	^self error:'Comment only'
]

{ #category : #documentation }
BalloonEngineBase class >> a3RasterizationRules [


	^self error:'Comment only'
]

{ #category : #documentation }
BalloonEngineBase class >> a4WideEdges [
]

{ #category : #documentation }
BalloonEngineBase class >> a5AETScanningProblems [
	"Due to having two fill entries (one left and one right) there can be problems while scanning the active edge table. In general, the AET should look like the following (ri - regions, ei - edges, fi - fills):

			|				\				|
	r1		|		r2		 \		r3		|		r4
			|				  \				|
			e1				 e2				e3		

	with:
		f(r1) = fLeft(e1) = 0				(empty fill, denoted -)
		f(r2) = fRight(e1) = fLeft(e2)		(denoted x)
		f(r3) = fRight(e2) = fLeft(e3)	(denoted o)
		f(r4) = fRight(e3) = 0

	However, due to integer arithmetic used during computations the AET may look like the following:
			X
			\|						|
			 | \						|
			 |   \					|
	r1		 | r2 \			r3		|		r4
			 |	   \					|
			e1		e2				e3		

	In this case, the starting point of e1 and e2 have the same x value at the first scan line but e2 has been sorted before e1 (Note: This can happen in *many* cases - the above is just a very simple example). Given the above outlined fill relations we have a problem. So, for instance, using the left/right fills as defined by the edges would lead to the effect that in the first scan line region r3 is actually filled with the right fill of e1 while it should actually be filled with the right fill of e2. This leads to noticable artifacts in the image and increasing resolution does not help.

	What we do here is defining an arbitrary sort order between fills (you can think of it as a depth value but the only thing that matters is that you can order the fills by this number and that the empty fill is always sorted at the end), and toggle the fills between an 'active' and an 'inactive' state at each edge. This is done as follows:
	For each edge ei in the AET do:
		* if fLeft(ei) isActive then removeActive(fLeft(ei)) else addActive(fLeft(ei))
		* if fRight(ei) isActive then removeActive(fRight(ei)) else addActive(fRight(ei))
		* draw the span from ei to ei+1 with currentActive
	where addActive adds the fill to the list of currently active fills, removeActive() removes the fill from the active list and currentActive returns the fill AS DEFINED BY THE SORT ORDER from the list of active fills. Note that this does not change anything in the first example above because the list will only contain one entry (besides the empty fill). In the second case however, it will lead to the following sequence:

	* toggle fLeft(e2) = f(r2) = 'x'
		- makes fLeft(e2) active
		- activeList = 'x'
	* toggle fRight(e2) = f(r3) = 'o'
		- makes fRight(e2) active
		- activeList = 'xo'
	* draw span from e2 to e1
		Depending on the sort order between 'x' and 'o' the region will be drawn with either one of the fills. It is significant to note here that the occurence of such a problem is generally only *very* few pixels large (in the above example zero pixels) and will therefore not be visually noticable. In any case, there is a unique decision for the fill to use here and that is what we need if the problem did not happen accidentally (e.g., someone has manually changed one fill of an edge but not the fill of the opposite edge).

	* toggle fLeft(e1) = f(r1) = '-'
		- makes fLeft(r1) visible
		- activeList = 'xo-'
		[Note: empty fills are a special case. 
		They can be ignored since they sort last
		and the activeList can return the empty
		fill if it is itself empty].
	* toggle fRight(e1) = f(r2) = 'x'
		- makes fRight(e1) invisible
		- activeList = 'o-'
	* draw span from e2 to e3
		Since the active list contains (besides the empty fill) only one fill value this will be used. Fortunately, this is the correct fill because it is the fill we had initially defined for the region r2.

An interesting side effect of the above is that there is no such notion as a 'left' or 'right' fill anymore. Another (not-so-nice) side effect is that the entire AET has to be scanned from the beginning even if only the last few edges actually affect the visible region.

PS. I need to find a way of clipping the edges for this. More on it later...
"
	^self error:'Comment only'
]

{ #category : #documentation }
BalloonEngineBase class >> a6StuffTODO [
	"This is an unordered list of things to do:

BalloonEnginePlugin>>stepToFirstBezierIn:at:
	1)	Check if reducing maxSteps from 2*deltaY to deltaY 
		brings a *significant* performance improvement.
		In theory this should make for double step performance
		but will cost in quality. Might be that the AA stuff will
		compensate for this - but I'm not really sure.

BalloonEngineBase>>dispatchOn:in:
	1)	Check what dispatches cost most and must be inlined
		by an #inlinedDispatchOn:in: Probably this will be
		stepping and eventually wide line stuff but we'll see.

BalloonEngineBase
	1)	Check which variables should become inst vars, if any.
		This will remove an indirection during memory access
		and might allow a couple of optimizations by the C compiler.

Anti-Aliasing:
	1)	Check if we can use a weighted 3x3 filter function of the form
				1	2	1
				2	4	2
				1	2	1
		Which should be *extremely* nice for fonts (it's sharpening
		edges). The good thing about the above is that it sums up to
		16 (as in the 4x4 case) but I don't know how to keep a history
		without needing two extra scan lines.

	2)	Check if we can - somehow - integrate more general filters.

	3) Unroll the loops during AA so we can copy and mask aaLevel pixels
	   in each step between start and end. This should speed up filling
	   by a factor of 2-4 (in particular for difficult stuff like radial gradients).

Clipping
	1)	Find a way of clipping edges left of the clip rectangle
		or at least ignoring most of them after the first scan line.
		The AET scanning problems discuss the issue but it should be
		possible to keep the color list between spans (if not empty)
		and speed up drawing at the very right (such as in the
		Winnie Pooh example where a lot of stuff is between the
		left border and the clipping rect.

	2)	Check if we can determine empty states of the color list and
		an edge that is longer than anything left of it. This should
		work in theory but might be relatively expensive to compute.

"
	^self error:'Comment only'
]

{ #category : #translation }
BalloonEngineBase class >> declareCVarsIn: cg [

	"Buffers"
	cg var: #workBuffer type: #'int*'.
	cg var: #objBuffer type: #'int*'.
	cg var: #getBuffer type: #'int*'.
	cg var: #aetBuffer type: #'int*'.
	cg var: #spanBuffer type: #'unsigned int*'.
	cg var: #edgeTransform declareC: 'float edgeTransform[6]'.
	cg var: #doProfileStats declareC: 'int doProfileStats = 0'.
	cg var: 'bbPluginName' declareC:'char bbPluginName[256] = "BitBltPlugin"'.
	"Functions"
	cg var: 'copyBitsFn'	type: 'void *'.
	cg var: 'loadBBFn'	type: 'void *'.
]

{ #category : #'class initialization' }
BalloonEngineBase class >> initialize [
	"BalloonEngineBase initialize"
	"BalloonEnginePlugin translateDoInlining: true."
	EdgeInitTable := self initializeEdgeInitTable.
	EdgeStepTable := self initializeEdgeStepTable.
	WideLineWidthTable := self initializeWideLineWidthTable.
	WideLineFillTable := self initializeWideLineFillTable.
	FillTable := self initializeFillTable.

	(Smalltalk classNamed: #BalloonEngineConstants) ifNotNil:
		[:balloonEngineConstants|
		(balloonEngineConstants classPool anySatisfy: [:classVarValue| classVarValue isNil]) ifTrue:
			[balloonEngineConstants initialize]]
]

{ #category : #'class initialization' }
BalloonEngineBase class >> initializeEdgeInitTable [
	"BalloonEngineBase initialize"
	^#(
		errorWrongIndex
		errorWrongIndex
		errorWrongIndex
		errorWrongIndex

		stepToFirstLine
		stepToFirstWideLine
		stepToFirstBezier
		stepToFirstWideBezier
	)
]

{ #category : #'class initialization' }
BalloonEngineBase class >> initializeEdgeStepTable [
	"BalloonEngineBase initialize"
	^#(
		errorWrongIndex
		errorWrongIndex
		errorWrongIndex
		errorWrongIndex

		stepToNextLine
		stepToNextWideLine
		stepToNextBezier
		stepToNextWideBezier
	)
]

{ #category : #'class initialization' }
BalloonEngineBase class >> initializeFillTable [
	"BalloonEngineBase initialize"
	^#(
		errorWrongIndex "Type zero - undefined"
		errorWrongIndex "Type one - external fill"

		fillLinearGradient "Linear gradient fill"
		fillRadialGradient "Radial gradient fill"

		fillBitmapSpan	"Clipped bitmap fill"
		fillBitmapSpan	"Repeated bitmap fill"
	)
]

{ #category : #'class initialization' }
BalloonEngineBase class >> initializeWideLineFillTable [
	"BalloonEngineBase initialize"
	^#(
		errorWrongIndex
		errorWrongIndex
		returnWideLineFill
		returnWideBezierFill
	)
]

{ #category : #'class initialization' }
BalloonEngineBase class >> initializeWideLineWidthTable [
	"BalloonEngineBase initialize"
	^#(
		errorWrongIndex
		errorWrongIndex
		returnWideLineWidth
		returnWideBezierWidth
	)
]

{ #category : #translation }
BalloonEngineBase class >> moduleName [
	^'B2DPlugin'
]

{ #category : #translation }
BalloonEngineBase class >> shouldBeTranslated [
"BalloonEnginePlugin should be translated but its superclasse should not since it is incorporated within this class's translation process. Nor should the simulation subclass be translated"
	^self == BalloonEnginePlugin
]

{ #category : #simulation }
BalloonEngineBase class >> simulatorClass [
	^BalloonEngineSimulation
]

{ #category : #'accessing state' }
BalloonEngineBase >> aaColorMaskGet [
	^workBuffer at: GWAAColorMask
]

{ #category : #'accessing state' }
BalloonEngineBase >> aaColorMaskPut: value [
	^workBuffer at: GWAAColorMask put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> aaColorShiftGet [
	^workBuffer at: GWAAColorShift
]

{ #category : #'accessing state' }
BalloonEngineBase >> aaColorShiftPut: value [
	^workBuffer at: GWAAColorShift put: value
]

{ #category : #displaying }
BalloonEngineBase >> aaFirstPixelFrom: leftX to: rightX [
	"Common function to compute the first full pixel for AA drawing"
	| firstPixel |
	<inline: true>
	firstPixel := (leftX + self aaLevelGet - 1) bitAnd: (self aaLevelGet - 1) bitInvert32.
	firstPixel > rightX 
		ifTrue:[^rightX]
		ifFalse:[^firstPixel]
]

{ #category : #'accessing state' }
BalloonEngineBase >> aaHalfPixelGet [
	^workBuffer at: GWAAHalfPixel
]

{ #category : #'accessing state' }
BalloonEngineBase >> aaHalfPixelPut: value [
	^workBuffer at: GWAAHalfPixel put: value
]

{ #category : #displaying }
BalloonEngineBase >> aaLastPixelFrom: leftX to: rightX [
	"Common function to compute the last full pixel for AA drawing"
	<inline: true>
	^(rightX - 1) bitAnd: (self aaLevelGet - 1) bitInvert32.
]

{ #category : #'accessing state' }
BalloonEngineBase >> aaLevelGet [
	^workBuffer at: GWAALevel
]

{ #category : #'accessing state' }
BalloonEngineBase >> aaLevelPut: value [
	^workBuffer at: GWAALevel put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> aaScanMaskGet [
	^workBuffer at: GWAAScanMask
]

{ #category : #'accessing state' }
BalloonEngineBase >> aaScanMaskPut: value [
	^workBuffer at: GWAAScanMask put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> aaShiftGet [
	^workBuffer at: GWAAShift
]

{ #category : #'accessing state' }
BalloonEngineBase >> aaShiftPut: value [
	^workBuffer at: GWAAShift put: value
]

{ #category : #other }
BalloonEngineBase >> accurateLengthOf: deltaX with: deltaY [
	"Return the accurate length of the vector described by deltaX and deltaY"
	| length2 |
	deltaX = 0 ifTrue:[deltaY < 0 ifTrue:[^0-deltaY] ifFalse:[^deltaY]].
	deltaY = 0 ifTrue:[deltaX < 0 ifTrue:[^0-deltaX] ifFalse:[^deltaX]].
	length2 := (deltaX * deltaX) + (deltaY * deltaY).
	^self computeSqrt: length2
]

{ #category : #'GET processing' }
BalloonEngineBase >> addEdgeToGET: edge [
	<inline: false>
	(self allocateGETEntry: 1) ifFalse:[^0].
	"Install edge in the GET"
	getBuffer at: self getUsedGet put: edge.
	self getUsedPut: self getUsedGet + 1.
]

{ #category : #displaying }
BalloonEngineBase >> adjustAALevel [

		"NOTE: 	This method is (hopefully) obsolete due to unrolling 
				the fill loops to deal with full pixels."

	"Adjust the span buffers values by the appropriate color offset for anti-aliasing.
	We do this by replicating the top bits of each color in the lower bits. The idea is that we can scale each color value uniquely from 0 to 255 and thus fill the entire range of colors."
	| adjustShift adjustMask x0 x1 pixelValue |
	<inline: false>
	adjustShift := 8 - self aaColorShiftGet.
	adjustMask := self aaColorMaskGet bitInvert32.
	x0 := self spanStartGet >> self aaShiftGet.
	x1 := self spanEndGet >> self aaShiftGet.
	[x0 < x1] whileTrue:[
		pixelValue := spanBuffer at: x0.
		spanBuffer at: x0 put: (pixelValue bitOr: (pixelValue >> adjustShift bitAnd: adjustMask)).
		x0 := x0 + 1].
]

{ #category : #'accessing state' }
BalloonEngineBase >> aetStartGet [
	^workBuffer at: GWAETStart
]

{ #category : #'accessing state' }
BalloonEngineBase >> aetStartPut: value [
	^workBuffer at: GWAETStart put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> aetUsedGet [
	^workBuffer at: GWAETUsed
]

{ #category : #'accessing state' }
BalloonEngineBase >> aetUsedPut: value [
	^workBuffer at: GWAETUsed put: value
]

{ #category : #allocating }
BalloonEngineBase >> allocateAETEntry: nSlots [
	"Allocate n slots in the active edge table"
	^self needAvailableSpace: nSlots
]

{ #category : #allocating }
BalloonEngineBase >> allocateGETEntry: nSlots [
	"Allocate n slots in the global edge table"
	| srcIndex dstIndex |
	<inline: false>
	"First allocate nSlots in the AET"
	(self allocateAETEntry: nSlots) ifFalse:[^false].
	self aetUsedGet = 0 ifFalse:["Then move the AET upwards"
		srcIndex := self aetUsedGet.
		dstIndex := self aetUsedGet + nSlots.
		1 to: self aetUsedGet do:[:i|
			aetBuffer at: (dstIndex := dstIndex - 1) put: (aetBuffer at: (srcIndex := srcIndex - 1))].
	].
	aetBuffer := aetBuffer + nSlots.
	^true
]

{ #category : #allocating }
BalloonEngineBase >> allocateObjEntry: nSlots [
	"Allocate n slots in the object buffer"
	| srcIndex dstIndex |
	<inline: false>
	"First allocate nSlots in the GET"
	(self allocateGETEntry: nSlots) ifFalse:[^false].
	self getUsedGet = 0 ifFalse:["Then move the GET upwards"
		srcIndex := self getUsedGet.
		dstIndex := self getUsedGet + nSlots.
		1 to: self getUsedGet do:[:i|
			getBuffer at: (dstIndex := dstIndex - 1) put: (getBuffer at: (srcIndex := srcIndex - 1))].
	].
	getBuffer := getBuffer + nSlots.
	^true
]

{ #category : #allocating }
BalloonEngineBase >> allocateStackEntry: nSlots [
	"AET and Stack allocation are symmetric"
	^self needAvailableSpace: nSlots
]

{ #category : #allocating }
BalloonEngineBase >> allocateStackFillEntry [
	^self wbStackPush: self stackFillEntryLength
]

{ #category : #testing }
BalloonEngineBase >> areEdgeFillsValid: edge [

	^((self objectHeaderOf: edge) bitAnd: GEEdgeFillsInvalid) = 0
]

{ #category : #displaying }
BalloonEngineBase >> clearSpanBuffer [
	"Clear the current span buffer.
	The span buffer is only cleared in the area that has been used by the previous scan line."
	| x0 x1 |
	<inline: false>
	x0 := self spanStartGet >> self aaShiftGet.
	x1 := self spanEndGet >> self aaShiftGet + 1.
	x0 < 0 ifTrue:[x0 := 0].
	x1 > self spanSizeGet ifTrue:[x1 := self spanSizeGet].
	[x0 < x1] whileTrue:[
		spanBuffer at: x0 put: 0.
		x0 := x0 + 1].
	self spanStartPut: self spanSizeGet.
	self spanEndPut: 0.
]

{ #category : #'accessing state' }
BalloonEngineBase >> clearSpanBufferGet [
	^workBuffer at: GWClearSpanBuffer
]

{ #category : #'accessing state' }
BalloonEngineBase >> clearSpanBufferPut: value [
	^workBuffer at: GWClearSpanBuffer put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> clipMaxXGet [
	^workBuffer at: GWClipMaxX
]

{ #category : #'accessing state' }
BalloonEngineBase >> clipMaxXPut: value [
	^workBuffer at: GWClipMaxX put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> clipMaxYGet [
	^workBuffer at: GWClipMaxY
]

{ #category : #'accessing state' }
BalloonEngineBase >> clipMaxYPut: value [
	^workBuffer at: GWClipMaxY put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> clipMinXGet [
	^workBuffer at: GWClipMinX
]

{ #category : #'accessing state' }
BalloonEngineBase >> clipMinXPut: value [
	^workBuffer at: GWClipMinX put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> clipMinYGet [
	^workBuffer at: GWClipMinY
]

{ #category : #'accessing state' }
BalloonEngineBase >> clipMinYPut: value [
	^workBuffer at: GWClipMinY put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> colorTransform [
	<returnTypeC:'float *'>
	^self cCoerce: workBuffer + GWColorTransform to:'float *'
]

{ #category : #other }
BalloonEngineBase >> computeSqrt: length2 [
	length2 < 32 
		ifTrue:[^self smallSqrtTable at: length2]
		ifFalse:[^(length2 asFloat sqrt + 0.5) asInteger]
]

{ #category : #private }
BalloonEngineBase >> copyBitsFrom: x0 to: x1 at: yValue [

	copyBitsFn = 0 ifTrue: [
		"We need copyBits here so try to load it implicitly"
		self initialiseModule ifFalse: [^false].
	].
	^self cCode: '((sqInt (*)(sqInt, sqInt, sqInt))copyBitsFn)(x0, x1, yValue)'
]

{ #category : #'GET processing' }
BalloonEngineBase >> createGlobalEdgeTable [
	"Create the global edge table"
	| object end |
	<inline: false>
	object := 0.
	end := objUsed.
	[object < end] whileTrue:[
		"Note: addEdgeToGET: may fail on insufficient space but that's not a problem here"
		(self isEdge: object) ifTrue:[
			"Check if the edge starts below fillMaxY."
			(self edgeYValueOf: object) >= self fillMaxYGet ifFalse:[
				self checkedAddEdgeToGET: object.
			].
		].
		object := object + (self objectLengthOf: object).
	].
]

{ #category : #'accessing state' }
BalloonEngineBase >> currentYGet [
	^workBuffer at: GWCurrentY
]

{ #category : #'accessing state' }
BalloonEngineBase >> currentYPut: value [
	^workBuffer at: GWCurrentY put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> currentZGet [
	^workBuffer at: GWCurrentZ
]

{ #category : #'accessing state' }
BalloonEngineBase >> currentZPut: value [
	^workBuffer at: GWCurrentZ put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> destOffsetXGet [
	^workBuffer at: GWDestOffsetX
]

{ #category : #'accessing state' }
BalloonEngineBase >> destOffsetXPut: value [
	^workBuffer at: GWDestOffsetX put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> destOffsetYGet [
	^workBuffer at: GWDestOffsetY
]

{ #category : #'accessing state' }
BalloonEngineBase >> destOffsetYPut: value [
	^workBuffer at: GWDestOffsetY put: value
]

{ #category : #displaying }
BalloonEngineBase >> displaySpanBufferAt: y [
	"Display the span buffer at the current scan line."
	| targetX0 targetX1 targetY |
	<inline: false>
	"self aaLevelGet > 1 ifTrue:[self adjustAALevel]."
	targetX0 := self spanStartGet >> self aaShiftGet.
	targetX0 < self clipMinXGet ifTrue:[targetX0 := self clipMinXGet].
	targetX1 := (self spanEndGet + self aaLevelGet - 1) >> self aaShiftGet.
	targetX1 > self clipMaxXGet ifTrue:[targetX1 := self clipMaxXGet].
	targetY := y >> self aaShiftGet.
	(targetY < self clipMinYGet or:[targetY >= self clipMaxYGet or:[
		targetX1 < self clipMinXGet or:[targetX0 >= self clipMaxXGet]]]) ifTrue:[^0].
	self copyBitsFrom: targetX0 to: targetX1 at: targetY.
]

{ #category : #displaying }
BalloonEngineBase >> drawWideEdge: edge from: leftX [
	"Draw the given edge starting from leftX with the edge's fill.
	Return the end value of the drawing operation."
	| rightX fill type lineWidth |
	<inline: false> "Not for the moment"
	type := self edgeTypeOf: edge.
	dispatchedValue := edge.
	self dispatchOn: type in: WideLineWidthTable.
	lineWidth := dispatchReturnValue.
	self dispatchOn: type in: WideLineFillTable.
	fill := self makeUnsignedFrom: dispatchReturnValue.
	fill = 0 ifTrue:[^leftX].
	"Check if this line is only partially visible"
	"self assert:(self isFillColor: fill)."
	rightX := leftX + lineWidth.
	self fillSpan: fill from: leftX to: rightX.
	^rightX
]

{ #category : #'accessing edges' }
BalloonEngineBase >> edgeFillsInvalidate: edge [

	^self objectTypeOf: edge put: 
		((self objectTypeOf: edge) bitOr: GEEdgeFillsInvalid)
]

{ #category : #'accessing edges' }
BalloonEngineBase >> edgeFillsValidate: edge [

	^self objectTypeOf: edge put: 
		((self objectTypeOf: edge) bitAnd: GEEdgeFillsInvalid bitInvert32)
]

{ #category : #'accessing edges' }
BalloonEngineBase >> edgeLeftFillOf: edge [

	^self obj: edge at: GEFillIndexLeft
]

{ #category : #'accessing edges' }
BalloonEngineBase >> edgeLeftFillOf: edge put: value [

	^self obj: edge at: GEFillIndexLeft put: value
]

{ #category : #'accessing edges' }
BalloonEngineBase >> edgeNumLinesOf: edge [

	^self obj: edge at: GENumLines
]

{ #category : #'accessing edges' }
BalloonEngineBase >> edgeNumLinesOf: edge put: value [

	^self obj: edge at: GENumLines put: value
]

{ #category : #'accessing edges' }
BalloonEngineBase >> edgeRightFillOf: edge [

	^self obj: edge at: GEFillIndexRight
]

{ #category : #'accessing edges' }
BalloonEngineBase >> edgeRightFillOf: edge put: value [

	^self obj: edge at: GEFillIndexRight put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> edgeTransform [
	<returnTypeC:'float *'>
	^self cCoerce: workBuffer + GWEdgeTransform to:'float *'
]

{ #category : #'accessing edges' }
BalloonEngineBase >> edgeTypeOf: edge [
	"Return the edge type (e.g., witout the wide edge flag)"

	^(self objectTypeOf: edge) >> 1
]

{ #category : #'accessing edges' }
BalloonEngineBase >> edgeXValueOf: edge [

	^self obj: edge at: GEXValue
]

{ #category : #'accessing edges' }
BalloonEngineBase >> edgeXValueOf: edge put: value [

	^self obj: edge at: GEXValue put: value
]

{ #category : #'accessing edges' }
BalloonEngineBase >> edgeYValueOf: edge [

	^self obj: edge at: GEYValue
]

{ #category : #'accessing edges' }
BalloonEngineBase >> edgeYValueOf: edge put: value [

	^self obj: edge at: GEYValue put: value
]

{ #category : #'accessing edges' }
BalloonEngineBase >> edgeZValueOf: edge [

	^self obj: edge at: GEZValue
]

{ #category : #'accessing edges' }
BalloonEngineBase >> edgeZValueOf: edge put: value [

	^self obj: edge at: GEZValue put: value
]

{ #category : #private }
BalloonEngineBase >> errorWrongIndex [
	"Ignore dispatch errors when translating to C
	(since we have no entry point for #error in the VM proxy)"
	self cCode:'' inSmalltalk:[self error:'BalloonEngine: Fatal dispatch error']
]

{ #category : #other }
BalloonEngineBase >> estimatedLengthOf: deltaX with: deltaY [
	"Estimate the length of the vector described by deltaX and deltaY.
	This method may be extremely inaccurate - use it only
	if you know exactly that this doesn't matter. Otherwise
	use #accurateLengthOf:width:"
	| absDx absDy |
	deltaX >= 0 ifTrue:[absDx := deltaX] ifFalse:[absDx := 0 - deltaX].
	deltaY >= 0 ifTrue:[absDy := deltaY] ifFalse:[absDy := 0 - deltaY].
	absDx > absDy 
		ifTrue:[^absDx + (absDy // 2)]
		ifFalse:[^absDy + (absDx // 2)]


]

{ #category : #displaying }
BalloonEngineBase >> fillAllFrom: leftX to: rightX [
	"Fill the span buffer from leftX to rightX with the given fill."
	| fill startX stopX |
	<inline: true>
	fill := self topFill.
	startX := leftX.
	stopX := self topRightX.
	[stopX < rightX] whileTrue:[
		fill := self makeUnsignedFrom: self topFill.
		fill = 0 ifFalse:[
			(self fillSpan: fill from: startX to: stopX) ifTrue:[^true]].
		self quickRemoveInvalidFillsAt: stopX.
		startX := stopX.
		stopX := self topRightX].
	fill := self makeUnsignedFrom: self topFill.
	fill = 0 ifFalse:[^self fillSpan: fill from: startX to: rightX].
	^false
]

{ #category : #displaying }
BalloonEngineBase >> fillBitmapSpan: bits from: leftX to: rightX [
	"Fill the span buffer between leftEdge and rightEdge using the given bits.
	Note: We always start from zero - this avoids using huge bitmap buffers if the bitmap is to be displayed at the very far right hand side and also gives us a chance of using certain bitmaps (e.g., those with depth 32) directly."
	| x0 x1 x bitX colorMask colorShift baseShift fillValue |
	<inline: false>
	<var: #bits type:'int *'>

	x0 := leftX.
	x1 := rightX.
	bitX := -1. "Hack for pre-increment"
	self aaLevelGet = 1 ifTrue:["Speedy version for no anti-aliasing"
		[x0 < x1] whileTrue:[
			fillValue := (self cCoerce: bits to: 'int *') at: (bitX := bitX + 1).
			spanBuffer at: x0 put: fillValue.
			x0 := x0 + 1.
		].
	] ifFalse:["Generic version with anti-aliasing"
		colorMask := self aaColorMaskGet.
		colorShift := self aaColorShiftGet.
		baseShift := self aaShiftGet.
		[x0 < x1] whileTrue:[
			x := x0 >> baseShift.
			fillValue := (self cCoerce: bits to: 'int *') at: (bitX := bitX + 1).
			fillValue := (fillValue bitAnd: colorMask) >> colorShift.
			spanBuffer at: x put: (spanBuffer at: x) + fillValue.
			x0 := x0 + 1.
		].
	].
	x1 > self spanEndGet ifTrue:[self spanEndPut: x1].
	x1 > self spanEndAAGet ifTrue:[self spanEndAAPut: x1].
]

{ #category : #displaying }
BalloonEngineBase >> fillColorSpan: pixelValue32 from: leftX to: rightX [
	"Fill the span buffer between leftEdge and rightEdge with the given pixel value."
	| x0 x1 |
	<inline: true>
	"Use a unrolled version for anti-aliased fills..."
	self aaLevelGet = 1
		ifFalse:[^self fillColorSpanAA: pixelValue32 x0: leftX x1: rightX].
	x0 := leftX.
	x1 := rightX.
	"Unroll the inner loop four times, since we're only storing data."
	[x0 + 4 < x1] whileTrue:[
		spanBuffer at: x0 put: pixelValue32.
		spanBuffer at: x0+1 put: pixelValue32.
		spanBuffer at: x0+2 put: pixelValue32.
		spanBuffer at: x0+3 put: pixelValue32.
		x0 := x0+4.
	].
	[x0 < x1] whileTrue:[
		spanBuffer at: x0 put: pixelValue32.
		x0 := x0 + 1.
	].
]

{ #category : #displaying }
BalloonEngineBase >> fillColorSpanAA: pixelValue32 x0: leftX x1: rightX [
	"This is the inner loop for solid color fills with anti-aliasing.
	This loop has been unrolled for speed and quality into three parts:
		a) copy all pixels that fall into the first full pixel.
		b) copy aaLevel pixels between the first and the last full pixel
		c) copy all pixels that fall in the last full pixel"
	| colorMask baseShift x idx firstPixel lastPixel aaLevel pv32 |
	<inline: false> "Not now -- maybe later"
	"Compute the pixel boundaries."
	firstPixel := self aaFirstPixelFrom: leftX to: rightX.
	lastPixel := self aaLastPixelFrom: leftX to: rightX.
	aaLevel := self aaLevelGet.
	baseShift := self aaShiftGet.
	x := leftX.

	"Part a: Deal with the first n sub-pixels"
	x < firstPixel ifTrue:[
		pv32 := (pixelValue32 bitAnd: self aaColorMaskGet) >> self aaColorShiftGet.
		[x < firstPixel] whileTrue:[
			idx := x >> baseShift.
			spanBuffer at: idx put: (spanBuffer at: idx) + pv32.
			x := x + 1.
		].
	].

	"Part b: Deal with the full pixels"
	x < lastPixel ifTrue:[
		colorMask := (self aaColorMaskGet >> self aaShiftGet) bitOr: 16rF0F0F0F0.
		pv32 := (pixelValue32 bitAnd: colorMask) >> self aaShiftGet.
		[x < lastPixel] whileTrue:[
			idx := x >> baseShift.
			spanBuffer at: idx put: (spanBuffer at: idx) + pv32.
			x := x + aaLevel.
		].
	].

	"Part c: Deal with the last n sub-pixels"
	x < rightX ifTrue:[
		pv32 := (pixelValue32 bitAnd: self aaColorMaskGet) >> self aaColorShiftGet.
		[x < rightX] whileTrue:[
			idx := x >> baseShift.
			spanBuffer at: idx put: (spanBuffer at: idx) + pv32.
			x := x + 1.
		].
	].
]

{ #category : #'accessing state' }
BalloonEngineBase >> fillMaxXGet [
	^workBuffer at: GWFillMaxX
]

{ #category : #'accessing state' }
BalloonEngineBase >> fillMaxXPut: value [
	^workBuffer at: GWFillMaxX put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> fillMaxYGet [
	^workBuffer at: GWFillMaxY
]

{ #category : #'accessing state' }
BalloonEngineBase >> fillMaxYPut: value [
	^workBuffer at: GWFillMaxY put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> fillMinXGet [
	^workBuffer at: GWFillMinX
]

{ #category : #'accessing state' }
BalloonEngineBase >> fillMinXPut: value [
	^workBuffer at: GWFillMinX put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> fillMinYGet [
	^workBuffer at: GWFillMinY
]

{ #category : #'accessing state' }
BalloonEngineBase >> fillMinYPut: value [
	^workBuffer at: GWFillMinY put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> fillOffsetXGet [
	^workBuffer at: GWFillOffsetX
]

{ #category : #'accessing state' }
BalloonEngineBase >> fillOffsetXPut: value [
	^workBuffer at: GWFillOffsetX put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> fillOffsetYGet [
	^workBuffer at: GWFillOffsetY
]

{ #category : #'accessing state' }
BalloonEngineBase >> fillOffsetYPut: value [
	^workBuffer at: GWFillOffsetY put: value
]

{ #category : #'FILL processing' }
BalloonEngineBase >> fillSorts: fillEntry1 before: fillEntry2 [
	"Return true if fillEntry1 should be drawn before fillEntry2"
	| diff |
	<inline: false>
	"First check the depth value"
	diff := (self stackFillDepth: fillEntry1) - (self stackFillDepth: fillEntry2).
	diff = 0 ifFalse:[^diff > 0].
	"See the class comment for aetScanningProblems"
	^(self cCoerce: (self makeUnsignedFrom: (self stackFillValue: fillEntry1)) to:'unsigned') <
		(self cCoerce: (self makeUnsignedFrom: (self stackFillValue: fillEntry2)) to: 'unsigned')
]

{ #category : #displaying }
BalloonEngineBase >> fillSpan: fill from: leftX to: rightX [
	"Fill the span buffer from leftX to rightX with the given fill.
	Clip before performing any operations. Return true if the fill must
	be handled by some Smalltalk code."
	| x0 x1 type |
	<var: #fill type: 'unsigned int'>
	<inline: false>
	fill = 0 ifTrue:[^false]. "Nothing to do"
	"Start from spEnd - we must not paint pixels twice at a scan line"
	leftX < self spanEndAAGet 
		ifTrue:[x0 := self spanEndAAGet]
		ifFalse:[x0 := leftX].
	rightX > (self spanSizeGet << self aaShiftGet) 
		ifTrue:[x1 := (self spanSizeGet << self aaShiftGet)]
		ifFalse:[x1 := rightX].

	"Clip left and right values"
	x0 < self fillMinXGet ifTrue:[x0 := self fillMinXGet].
	x1 > self fillMaxXGet ifTrue:[x1 := self fillMaxXGet].

	"Adjust start and end values of span"
	x0 < self spanStartGet ifTrue:[self spanStartPut: x0].
	x1 > self spanEndGet ifTrue:[self spanEndPut: x1].
	x1 > self spanEndAAGet ifTrue:[self spanEndAAPut: x1].

	x0 >= x1 ifTrue:[^false]. "Nothing to do"

	(self isFillColor: fill) ifTrue:[
		self fillColorSpan: fill from: x0 to: x1.
	] ifFalse:[
		"Store the values for the dispatch"
		self lastExportedFillPut: fill.
		self lastExportedLeftXPut: x0.
		self lastExportedRightXPut: x1.
		type := self fillTypeOf: fill.
		type <= 1 ifTrue:[^true].
		self dispatchOn: type in: FillTable.
	].
	^false
]

{ #category : #'accessing fills' }
BalloonEngineBase >> fillTypeOf: fill [
	^((self objectTypeOf: fill) bitAnd: GEPrimitiveFillMask) >> 8
]

{ #category : #'AET processing' }
BalloonEngineBase >> findNextAETEdgeFrom: leftEdge [
	| depth rightEdge |
	depth := self edgeZValueOf: leftEdge.
	[self aetStartGet < self aetUsedGet] whileTrue:[
		rightEdge := aetBuffer at: self aetStartGet.
		(self edgeZValueOf: rightEdge) >= depth ifTrue:[^rightEdge].
		self aetStartPut: self aetStartGet + 1.
	].
	^nil
]

{ #category : #'GET processing' }
BalloonEngineBase >> findNextExternalEntryFromGET [
	"Check the global edge table for any entries that cannot be handled by the engine itself.
	If there are any, return true. Otherwise, initialize the the edge and add it to the AET"
	| yValue edge type |
	yValue := self currentYGet.
	"As long as we have entries in the GET"
	[self getStartGet < self getUsedGet] whileTrue:[
		edge := getBuffer at: self getStartGet.
		(self edgeYValueOf: edge) > yValue ifTrue:[^false]. "No more edges to add"
		type := self objectTypeOf: edge.
		(type bitAnd: GEPrimitiveWideMask) = GEPrimitiveEdge 
			ifTrue:[^true]. "This is an external edge"
		"Note: We must make sure not to do anything with the edge if there is not
		enough room in the AET"
		(self needAvailableSpace: 1) ifFalse:[^false]. "No more room"
		"Process the edge in the engine itself"
		self dispatchOn: type in: EdgeInitTable.
		"Insert the edge into the AET"
		self insertEdgeIntoAET: edge.
		self getStartPut: self getStartGet + 1.
	].
	"No entries in GET"
	^false
]

{ #category : #'AET processing' }
BalloonEngineBase >> findNextExternalFillFromAET [
	"Scan the active edge table. If there is any fill that cannot be handled by the engine itself,  return true. Otherwise handle the fills and return false."
	| leftEdge rightEdge leftX rightX |
"self currentYGet >= 680 ifTrue:[
self printAET.
self halt.
]."

	<inline: false>
	leftX := rightX := self fillMaxXGet.
	[self aetStartGet < self aetUsedGet] whileTrue:[
		leftEdge := rightEdge := aetBuffer at: self aetStartGet.
		"TODO: We should check if leftX from last operation 
			is  greater than leftX from next edge.
			Currently, we rely here on spanEndAA
			from the span buffer fill."
		leftX := rightX := self edgeXValueOf: leftEdge.
		leftX >= self fillMaxXGet ifTrue:[^false]. "Nothing more visible"
		self quickRemoveInvalidFillsAt: leftX.
		"Check if we need to draw the edge"
		(self isWide: leftEdge) ifTrue:[
			self toggleWideFillOf: leftEdge.
			"leftX := rightX := self drawWideEdge: leftEdge from: leftX."
		].
		(self areEdgeFillsValid: leftEdge) ifTrue:[
			self toggleFillsOf: leftEdge. "Adjust the fills"
			engineStopped ifTrue:[^false].
		].
		self aetStartPut: self aetStartGet + 1.
		self aetStartGet < self aetUsedGet ifTrue:[
			rightEdge := aetBuffer at: self aetStartGet.
			rightX := self edgeXValueOf: rightEdge.
			rightX >= self fillMinXGet ifTrue:["This is the visible portion"
				self fillAllFrom: leftX to: rightX.
				"Fetch the currently active fill"
				"fill := self makeUnsignedFrom: self topFill.
				fill = 0 ifFalse:[self fillSpan: fill from: leftX to: rightX max: self topRightX]"
			].
		].
	].
	"Note: Due to pre-clipping we may have to draw remaining stuff with the last fill"
	rightX < self fillMaxXGet ifTrue:[
		self fillAllFrom: rightX to: self fillMaxXGet.
		"fill := self makeUnsignedFrom: self topFill.
		fill = 0 ifFalse:[self fillSpan: fill from: rightX to: self fillMaxXGet max: self topRightX]."
	].
	^false
]

{ #category : #'AET processing' }
BalloonEngineBase >> findNextExternalUpdateFromAET [
	"Check the active edge table for any entries that cannot be handled by the engine itself.
	If there are any, return true. Otherwise, step the the edge to the next y value."
	| edge count type |
	<inline: false>
	[self aetStartGet < self aetUsedGet] whileTrue:[
		edge := aetBuffer at: self aetStartGet.
		count := (self edgeNumLinesOf: edge) - 1.
		count = 0 ifTrue:[
			"Edge at end -- remove it"
			self removeFirstAETEntry
		] ifFalse:[
			"Store remaining lines back"
			self edgeNumLinesOf: edge put: count.
			type := self objectTypeOf: edge.
			(type bitAnd: GEPrimitiveWideMask) = GEPrimitiveEdge 
				ifTrue:[^true]. "This is an external edge"
			self dispatchOn: type in: EdgeStepTable.
			self resortFirstAETEntry.
			self aetStartPut: self aetStartGet+1.
		].
	].
	^false
]

{ #category : #'FILL processing' }
BalloonEngineBase >> findStackFill: fillIndex depth: depth [
	| index |
	index := 0.
	[index < self stackFillSize and:[
		(self stackFillValue: index) ~= fillIndex or:[
			(self stackFillDepth: index) ~= depth]]]
				whileTrue:[index := index + self stackFillEntryLength].
	index >= self stackFillSize 
		ifTrue:[^-1]
		ifFalse:[^index].

]

{ #category : #testing }
BalloonEngineBase >> finishedProcessing [
	"Return true if processing is finished"
	^self stateGet = GEStateCompleted
]

{ #category : #'accessing state' }
BalloonEngineBase >> firstPointListGet [
	^workBuffer at: GWPointListFirst
]

{ #category : #'accessing state' }
BalloonEngineBase >> firstPointListPut: value [
	^workBuffer at: GWPointListFirst put: value
]

{ #category : #allocating }
BalloonEngineBase >> freeStackFillEntry [
	self wbStackPop: self stackFillEntryLength.
]

{ #category : #'GET processing' }
BalloonEngineBase >> getSorts: edge1 before: edge2 [
	"Return true if the edge at index i should sort before the edge at index j."
	| diff |
	<inline: false>
	edge1 = edge2 ifTrue:[^true].
	"First, sort by Y"
	diff := (self edgeYValueOf: edge1) - (self edgeYValueOf: edge2).
	diff = 0 ifFalse:[^diff < 0].
	"Then, by X"
	diff := (self edgeXValueOf: edge1) - (self edgeXValueOf: edge2).
	^diff < 0
]

{ #category : #'accessing state' }
BalloonEngineBase >> getStartGet [
	^workBuffer at: GWGETStart
]

{ #category : #'accessing state' }
BalloonEngineBase >> getStartPut: value [
	^workBuffer at: GWGETStart put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> getUsedGet [
	^workBuffer at: GWGETUsed
]

{ #category : #'accessing state' }
BalloonEngineBase >> getUsedPut: value [
	^workBuffer at: GWGETUsed put: value
]

{ #category : #testing }
BalloonEngineBase >> hasColorTransform [
	^self hasColorTransformGet ~= 0
]

{ #category : #'accessing state' }
BalloonEngineBase >> hasColorTransformGet [
	^workBuffer at: GWHasColorTransform
]

{ #category : #'accessing state' }
BalloonEngineBase >> hasColorTransformPut: value [
	^workBuffer at: GWHasColorTransform put: value
]

{ #category : #testing }
BalloonEngineBase >> hasEdgeTransform [
	^self hasEdgeTransformGet ~= 0
]

{ #category : #'accessing state' }
BalloonEngineBase >> hasEdgeTransformGet [
	^workBuffer at: GWHasEdgeTransform
]

{ #category : #'accessing state' }
BalloonEngineBase >> hasEdgeTransformPut: value [
	^workBuffer at: GWHasEdgeTransform put: value
]

{ #category : #'FILL processing' }
BalloonEngineBase >> hideFill: fillIndex depth: depth [
	"Make the fill style with the given index invisible"
	| index newTopIndex newTop newDepth newRightX |
	<inline: false>
	index := self findStackFill: fillIndex depth: depth.
	index = -1 ifTrue:[^false].

	index = 0 ifTrue:[
		self freeStackFillEntry.
		^true].

	"Fill is visible - replace it with the last entry on the stack"
	self stackFillValue: index put: (self stackFillValue: 0).
	self stackFillDepth: index put: (self stackFillDepth: 0).
	self stackFillRightX: index put: (self stackFillRightX: 0).
	self freeStackFillEntry.
	(self stackFillSize <= self stackFillEntryLength) ifTrue:[^true]. "Done"

	"Find the new top fill"
	newTopIndex := 0.
	index := self stackFillEntryLength.
	[index < self stackFillSize] whileTrue:[
		(self fillSorts: index before: newTopIndex)
			ifTrue:[newTopIndex := index].
		index := index + self stackFillEntryLength.
	].
	(newTopIndex + self stackFillEntryLength = self stackFillSize) 
		ifTrue:[^true]. "Top fill not changed"
	newTop := self stackFillValue: newTopIndex.
	self stackFillValue: newTopIndex put: self topFillValue.
	self topFillValuePut: newTop.
	newDepth := self stackFillDepth: newTopIndex.
	self stackFillDepth: newTopIndex put: self topFillDepth.
	self topFillDepthPut: newDepth.
	newRightX := self stackFillRightX: newTopIndex.
	self stackFillRightX: newTopIndex put: self topFillRightX.
	self topFillRightXPut: newRightX.
	^true
]

{ #category : #transforming }
BalloonEngineBase >> incrementPoint: point by: delta [
	<var: #point type:'int *'>
	point at: 0 put: (point at: 0) + delta.
	point at: 1 put: (point at: 1) + delta.
]

{ #category : #'accessing state' }
BalloonEngineBase >> incrementStat: statIndex by: value [

	^workBuffer at: statIndex put: (workBuffer at: statIndex) + value
]

{ #category : #'AET processing' }
BalloonEngineBase >> indexForInsertingIntoAET: edge [
	"Find insertion point for the given edge in the AET"
	| initialX index |
	<inline: false>
	initialX := self edgeXValueOf: edge.
	index := 0.
	[index < self aetUsedGet and:[
		(self edgeXValueOf: (aetBuffer at: index)) < initialX]]
			whileTrue:[index := index + 1].
	[index < self aetUsedGet and:[
		(self edgeXValueOf: (aetBuffer at: index)) = initialX and:[
			(self getSorts: (aetBuffer at: index) before: edge)]]]
				whileTrue:[index := index + 1].
	^index
]

{ #category : #other }
BalloonEngineBase >> initColorTransform [
	| transform |
	<inline: false>
	<var: #transform type:'float *'>
	transform := self colorTransform.
	transform at: 0 put: (self cCoerce: 1.0 to: 'float').
	transform at: 1 put: (self cCoerce: 0.0 to: 'float').
	transform at: 2 put: (self cCoerce: 1.0 to: 'float').
	transform at: 3 put: (self cCoerce: 0.0 to: 'float').
	transform at: 4 put: (self cCoerce: 1.0 to: 'float').
	transform at: 5 put: (self cCoerce: 0.0 to: 'float').
	transform at: 6 put: (self cCoerce: 1.0 to: 'float').
	transform at: 7 put: (self cCoerce: 0.0 to: 'float').
	self hasColorTransformPut: 0.
]

{ #category : #other }
BalloonEngineBase >> initEdgeTransform [
	| transform |
	<inline: false>
	<var: #transform type:'float *'>
	transform := self edgeTransform.
	transform at: 0 put: (self cCoerce: 1.0 to: 'float').
	transform at: 1 put: (self cCoerce: 0.0 to: 'float').
	transform at: 2 put: (self cCoerce: 0.0 to: 'float').
	transform at: 3 put: (self cCoerce: 0.0 to: 'float').
	transform at: 4 put: (self cCoerce: 1.0 to: 'float').
	transform at: 5 put: (self cCoerce: 0.0 to: 'float').
	self hasEdgeTransformPut: 0.
]

{ #category : #'initialize-release' }
BalloonEngineBase >> initialiseModule [
	<export: true>

	loadBBFn := interpreterProxy ioLoadFunction: 'loadBitBltFrom' From: bbPluginName.
	copyBitsFn := interpreterProxy ioLoadFunction: 'copyBitsFromtoat' From: bbPluginName.
	^(loadBBFn ~= 0 and:[copyBitsFn ~= 0])
]

{ #category : #'GET processing' }
BalloonEngineBase >> initializeGETProcessing [
	"Initialization stuff that needs to be done before any processing can take place."
	<inline: false>

	"Make sure aaLevel is initialized"
	self setAALevel: self aaLevelGet.

	self clipMinXGet < 0 ifTrue:[self clipMinXPut: 0].
	self clipMaxXGet > self spanSizeGet ifTrue:[self clipMaxXPut: self spanSizeGet].
	"Convert clipRect to aaLevel"
	self fillMinXPut: self clipMinXGet << self aaShiftGet.
	self fillMinYPut: self clipMinYGet << self aaShiftGet.
	self fillMaxXPut: self clipMaxXGet << self aaShiftGet.
	self fillMaxYPut: self clipMaxYGet << self aaShiftGet.

	"Reset GET and AET"
	self getUsedPut: 0.
	self aetUsedPut: 0.
	getBuffer := objBuffer + objUsed.
	aetBuffer := objBuffer + objUsed.

	"Create the global edge table"
	self createGlobalEdgeTable.
	engineStopped ifTrue:[^nil].

	self getUsedGet = 0 ifTrue:[
		"Nothing to do"
		self currentYPut: self fillMaxYGet.
		^0].

	"Sort entries in the GET"
	self sortGlobalEdgeTable.

	"Find the first y value to be processed"
	self currentYPut: (self edgeYValueOf: (getBuffer at: 0)).
	self currentYGet < self fillMinYGet ifTrue:[self currentYPut: self fillMinYGet].

	"Load and clear the span buffer"
	self spanStartPut: 0.
	self spanEndPut: (self spanSizeGet << self aaShiftGet) - 1.
	self clearSpanBuffer. "@@: Is this really necessary?!"
]

{ #category : #'AET processing' }
BalloonEngineBase >> insertEdgeIntoAET: edge [
	"Insert the edge with the given index from the global edge table into the active edge table.
	The edge has already been stepped to the initial yValue -- thus remainingLines and rasterX
	are both set."
	| index |
	<inline: false>

	"Check for the number of lines remaining"
	(self edgeNumLinesOf: edge) <= 0 ifTrue:[^nil]. "Nothing to do"

	"Find insertion point"
	index := self indexForInsertingIntoAET: edge.

	"And insert edge"
	self insertToAET: edge beforeIndex: index.
]

{ #category : #'AET processing' }
BalloonEngineBase >> insertToAET: edge beforeIndex: index [
	"Insert the given edge into the AET."
	| i |
	<inline: false>
	"Make sure we have space in the AET"
	(self allocateAETEntry: 1) ifFalse:[^nil]. "Insufficient space in AET"

	i := self aetUsedGet-1.
	[i < index] whileFalse:[
		aetBuffer at: i+1 put: (aetBuffer at: i).
		i := i - 1.
	].
	aetBuffer at: index put: edge.
	self aetUsedPut: self aetUsedGet + 1.
]

{ #category : #testing }
BalloonEngineBase >> isEdge: edge [
	| type |
	type := self objectTypeOf: edge.
	type > GEPrimitiveEdgeMask ifTrue:[^false].
	^((self objectTypeOf: edge) bitAnd: GEPrimitiveEdgeMask) ~= 0
]

{ #category : #testing }
BalloonEngineBase >> isFill: fill [
	^(self isFillColor: fill) or:[self isRealFill: fill]
]

{ #category : #testing }
BalloonEngineBase >> isFillColor: fill [
	^((self makeUnsignedFrom: fill) bitAnd: 16rFF000000) ~= 0
]

{ #category : #testing }
BalloonEngineBase >> isObject: obj [
	^obj >= 0 and:[obj < objUsed]
]

{ #category : #testing }
BalloonEngineBase >> isRealFill: fill [
	^((self objectTypeOf: fill) bitAnd: GEPrimitiveFillMask) ~= 0
]

{ #category : #testing }
BalloonEngineBase >> isStackEntry: entry [
	^entry >= self wbTopGet and:[entry < self wbSizeGet]
]

{ #category : #testing }
BalloonEngineBase >> isStackIndex: index [
	^index >= 0 and:[index < self wbStackSize]
]

{ #category : #testing }
BalloonEngineBase >> isWide: object [

	^((self objectTypeOf: object) bitAnd: GEPrimitiveWide) ~= 0
]

{ #category : #'accessing state' }
BalloonEngineBase >> lastExportedEdgeGet [
	^workBuffer at: GWLastExportedEdge
]

{ #category : #'accessing state' }
BalloonEngineBase >> lastExportedEdgePut: value [
	^workBuffer at: GWLastExportedEdge put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> lastExportedFillGet [
	^workBuffer at: GWLastExportedFill
]

{ #category : #'accessing state' }
BalloonEngineBase >> lastExportedFillPut: value [
	^workBuffer at: GWLastExportedFill put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> lastExportedLeftXGet [
	^workBuffer at: GWLastExportedLeftX
]

{ #category : #'accessing state' }
BalloonEngineBase >> lastExportedLeftXPut: value [
	^workBuffer at: GWLastExportedLeftX put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> lastExportedRightXGet [
	^workBuffer at: GWLastExportedRightX
]

{ #category : #'accessing state' }
BalloonEngineBase >> lastExportedRightXPut: value [
	^workBuffer at: GWLastExportedRightX put: value
]

{ #category : #'loading state' }
BalloonEngineBase >> loadArrayTransformFrom: transformOop into: destPtr length: n [
	"Load a transformation from the given array."
	| value |
	<inline: false>
	<var: #destPtr type:'float *'>
	0 to: n-1 do:[:i|
		value := interpreterProxy fetchPointer: i ofObject: transformOop.
		((interpreterProxy isIntegerObject: value) or:[interpreterProxy isFloatObject: value])
			ifFalse:[^interpreterProxy primitiveFail].
		(interpreterProxy isIntegerObject: value)
			ifTrue:[destPtr at: i put: 
				(self cCoerce: (interpreterProxy integerValueOf: value) asFloat to:'float')]
			ifFalse:[destPtr at: i put: 
				(self cCoerce: (interpreterProxy floatValueOf: value) to: 'float')].
	].
]

{ #category : #private }
BalloonEngineBase >> loadBitBltFrom: bbObj [

	loadBBFn = 0 ifTrue: [
		"We need copyBits here so try to load it implicitly"
		self initialiseModule ifFalse:[^false].
	].
	^self cCode: '((sqInt (*)(sqInt))loadBBFn)(bbObj)'
]

{ #category : #'loading state' }
BalloonEngineBase >> loadColorTransformFrom: transformOop [
	"Load a 2x3 transformation matrix from the given oop.
	Return true if the matrix is not nil, false otherwise"
	| okay transform |
	<var: #transform type:'float *'>
	transform := self colorTransform.
	self hasColorTransformPut: 0.
	okay := self loadTransformFrom: transformOop into: transform length: 8.
	okay ifFalse:[^false].
	self hasColorTransformPut: 1.
	"Scale transform to be in 0-256 range"
	transform at: 1 put: (transform at: 1) * (self cCoerce: 256.0 to:'float').
	transform at: 3 put: (transform at: 3) * (self cCoerce: 256.0 to:'float').
	transform at: 5 put: (transform at: 5) * (self cCoerce: 256.0 to:'float').
	transform at: 7 put: (transform at: 7) * (self cCoerce: 256.0 to:'float').
	^okay
]

{ #category : #'loading state' }
BalloonEngineBase >> loadEdgeStateFrom: edgeOop [
	| edge |
	<inline: false>
	edge := self lastExportedEdgeGet.
	(interpreterProxy slotSizeOf: edgeOop) < ETBalloonEdgeDataSize 
		ifTrue:[^nil].
	self edgeXValueOf: edge 
		put: (interpreterProxy fetchInteger: ETXValueIndex ofObject: edgeOop).
	self edgeYValueOf: edge 
		put: (interpreterProxy fetchInteger: ETYValueIndex ofObject: edgeOop).
	self edgeZValueOf: edge 
		put: (interpreterProxy fetchInteger: ETZValueIndex ofObject: edgeOop).
	self edgeNumLinesOf: edge 
		put: (interpreterProxy fetchInteger: ETLinesIndex ofObject: edgeOop).
	^edge
]

{ #category : #'loading state' }
BalloonEngineBase >> loadEdgeTransformFrom: transformOop [
	"Load a 2x3 transformation matrix from the given oop.
	Return true if the matrix is not nil, false otherwise"
	| transform okay |
	<inline: false>
	<var: #transform type:'float *'>
	self hasEdgeTransformPut: 0.
	transform := self edgeTransform.
	okay := self loadTransformFrom: transformOop into: transform length: 6.
	interpreterProxy failed ifTrue:[^nil].
	okay ifFalse:[^false].
	self hasEdgeTransformPut: 1.
	"Add the fill offset to the matrix"
	transform at: 2 put: 
		(self cCoerce: (transform at: 2) + self destOffsetXGet asFloat to:'float').
	transform at: 5 put: 
		(self cCoerce: (transform at: 5) + self destOffsetYGet asFloat to:'float').
	^true
]

{ #category : #'loading state' }
BalloonEngineBase >> loadFormsFrom: arrayOop [
	"Check all the forms from arrayOop."
	| formOop bmBits bmBitsSize bmWidth bmHeight bmDepth ppw bmRaster |
	(interpreterProxy isArray: arrayOop) ifFalse:[^false].
	formArray := arrayOop.
	0 to: (interpreterProxy slotSizeOf: formArray) - 1 do:[:i|
		formOop := interpreterProxy fetchPointer: i ofObject: formArray.
		(interpreterProxy isPointers: formOop) ifFalse:[^false].
		(interpreterProxy slotSizeOf: formOop) < 5 ifTrue:[^false].
		bmBits := interpreterProxy fetchPointer: 0 ofObject: formOop.
		(interpreterProxy fetchClassOf: bmBits) = interpreterProxy classBitmap
			ifFalse:[^false].
		bmBitsSize := interpreterProxy slotSizeOf: bmBits.
		bmWidth := interpreterProxy fetchInteger: 1 ofObject: formOop.
		bmHeight := interpreterProxy fetchInteger: 2 ofObject: formOop.
		bmDepth := interpreterProxy fetchInteger: 3 ofObject: formOop.
		interpreterProxy failed ifTrue:[^false].
		(bmWidth >= 0 and:[bmHeight >= 0]) ifFalse:[^false].
		ppw := 32 // bmDepth.
		bmRaster := bmWidth + (ppw-1) // ppw.
		bmBitsSize = (bmRaster * bmHeight)
			ifFalse:[^false].
	].
	^true
]

{ #category : #'loading state' }
BalloonEngineBase >> loadPoint: pointArray from: pointOop [
	"Load the contents of pointOop into pointArray"
	| value |
	<inline: false>
	<var: #pointArray type:'int *'>
	(interpreterProxy fetchClassOf: pointOop) = interpreterProxy classPoint 
		ifFalse:[^interpreterProxy primitiveFail].
	value := interpreterProxy fetchPointer: 0 ofObject: pointOop.
	((interpreterProxy isIntegerObject: value) or:[interpreterProxy isFloatObject: value])
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy isIntegerObject: value)
		ifTrue:[pointArray at: 0 put: (interpreterProxy integerValueOf: value)]
		ifFalse:[pointArray at: 0 put: (interpreterProxy floatValueOf: value) asInteger].
	value := interpreterProxy fetchPointer: 1 ofObject: pointOop.
	((interpreterProxy isIntegerObject: value) or:[interpreterProxy isFloatObject: value])
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy isIntegerObject: value)
		ifTrue:[pointArray at: 1 put: (interpreterProxy integerValueOf: value)]
		ifFalse:[pointArray at: 1 put: (interpreterProxy floatValueOf: value) asInteger].

]

{ #category : #'primitives-rendering' }
BalloonEngineBase >> loadRenderingState [
	"Load the entire state from the interpreter for the rendering primitives.
	 Answer 0 on success or a non-zero failure code on failure."
	| failCode edgeOop fillOop state |
	<inline: false>
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^PrimErrBadNumArgs].

	(failCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 2)) ~= 0 ifTrue:
		[^failCode].

	fillOop := interpreterProxy stackObjectValue: 0.
	edgeOop := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue: [^PrimErrBadArgument].

	"Load span buffer and bitBlt"
	(failCode := self loadSpanBufferFrom:
		(interpreterProxy fetchPointer: BESpanIndex ofObject: engine)) = 0 ifFalse:
		[^failCode].
	(self loadBitBltFrom: 
		(interpreterProxy fetchPointer: BEBitBltIndex ofObject: engine)) ifFalse:
		[^GEFBitBltLoadFailed].
	(self loadFormsFrom:
		(interpreterProxy fetchPointer: BEFormsIndex ofObject: engine)) ifFalse:
		[^GEFFormLoadFailed].
	"Check edgeOop and fillOop"
	(interpreterProxy slotSizeOf: edgeOop) < ETBalloonEdgeDataSize 
		ifTrue:[^GEFEdgeDataTooSmall].
	(interpreterProxy slotSizeOf: fillOop) < FTBalloonFillDataSize 
		ifTrue:[^GEFFillDataTooSmall].

	"Note: Rendering can only take place if we're not in one of the intermediate
	(e.g., external) states."
	state := self stateGet.
	(state = GEStateWaitingForEdge or:[
		state = GEStateWaitingForFill or:[
			state = GEStateWaitingChange]]) ifTrue:[^GEFWrongState].

	^0
]

{ #category : #'loading state' }
BalloonEngineBase >> loadSpanBufferFrom: spanOop [
	"Load the span buffer from the given oop.
	 Answer 0 on success or a non-zero failure code on failure."
	<inline: false>
	(interpreterProxy fetchClassOf: spanOop) = (interpreterProxy classBitmap) ifFalse:[^GEFClassMismatch].
	spanBuffer := interpreterProxy firstIndexableField: spanOop.
	"Leave last entry unused to avoid complications"
	self spanSizePut: (interpreterProxy slotSizeOf: spanOop) - 1.
	^0
]

{ #category : #'loading state' }
BalloonEngineBase >> loadTransformFrom: transformOop into: destPtr length: n [
	"Load a transformation from transformOop into the float array
	defined by destPtr. The transformation is assumed to be either
	an array or a FloatArray of length n."
	<inline: false>
	<var: #destPtr type:'float *'>
	transformOop = interpreterProxy nilObject ifTrue:[^false].
	(interpreterProxy isImmediate: transformOop)
		ifTrue:[^interpreterProxy primitiveFail].
	(interpreterProxy slotSizeOf: transformOop) = n 
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy isWords: transformOop) 
		ifTrue:[self loadWordTransformFrom: transformOop into: destPtr length: n]
		ifFalse:[self loadArrayTransformFrom: transformOop into: destPtr length: n].
	^true
]

{ #category : #'loading state' }
BalloonEngineBase >> loadWordTransformFrom: transformOop into: destPtr length: n [
	"Load a float array transformation from the given oop"
	| srcPtr |
	<inline: false>
	<var: #srcPtr type:'float *'>
	<var: #destPtr type:'float *'>
	srcPtr := self cCoerce: (interpreterProxy firstIndexableField: transformOop) to: 'float *'.
	0 to: n-1 do:[:i| destPtr at: i put: (srcPtr at: i)].
]

{ #category : #'loading state' }
BalloonEngineBase >> loadWorkBufferFrom: wbOop [
	"Load the working buffer from the given oop"
	<inline: false>
	(interpreterProxy isImmediate: wbOop) ifTrue:[^GEFWorkBufferIsInteger].
	(interpreterProxy isWords: wbOop) ifFalse:[^GEFWorkBufferIsPointers].
	(interpreterProxy slotSizeOf: wbOop) < GWMinimalSize ifTrue:[^GEFWorkBufferTooSmall].
	self workBufferPut: wbOop.
	self magicNumberGet = GWMagicNumber ifFalse:[^GEFWorkBufferBadMagic].
	"Sanity checks"
	(self wbSizeGet = (interpreterProxy slotSizeOf: wbOop)) ifFalse:[^GEFWorkBufferWrongSize].
	self objStartGet = GWHeaderSize ifFalse:[^GEFWorkBufferStartWrong].

	"Load buffers"
	objBuffer := workBuffer + self objStartGet.
	getBuffer := objBuffer + self objUsedGet.
	aetBuffer := getBuffer + self getUsedGet.

	"Make sure we don't exceed the work buffer"
	GWHeaderSize + self objUsedGet + self getUsedGet + self aetUsedGet
	> self wbSizeGet ifTrue:[^GEFWorkTooBig].

	^0
]

{ #category : #'accessing state' }
BalloonEngineBase >> magicNumberGet [
	^workBuffer at: GWMagicIndex
]

{ #category : #'accessing state' }
BalloonEngineBase >> magicNumberPut: value [
	^workBuffer at: GWMagicIndex put: value
]

{ #category : #private }
BalloonEngineBase >> makeUnsignedFrom: someIntegerValue [
	^someIntegerValue
]

{ #category : #'initialize-release' }
BalloonEngineBase >> moduleUnloaded: aModuleName [
	"The module with the given name was just unloaded.
	Make sure we have no dangling references."
	<export: true>
	<var: #aModuleName type: 'char *'>
	(aModuleName strcmp: bbPluginName) = 0 ifTrue:[
		"BitBlt just shut down. How nasty."
		loadBBFn := 0.
		copyBitsFn := 0.
	].
]

{ #category : #'AET processing' }
BalloonEngineBase >> moveAETEntryFrom: index edge: edge x: xValue [
	"The entry at index is not in the right position of the AET. 
	Move it to the left until the position is okay."
	| newIndex |
	<inline: false>
	newIndex := index.
	[newIndex > 0 and:[(self edgeXValueOf: (aetBuffer at: newIndex-1)) > xValue]]
		whileTrue:[	aetBuffer at: newIndex put: (aetBuffer at: newIndex-1).
					newIndex := newIndex - 1].
	aetBuffer at: newIndex put: edge.
]

{ #category : #allocating }
BalloonEngineBase >> needAvailableSpace: nSlots [
	"Check if we have n slots available"
	GWHeaderSize + objUsed + self getUsedGet + self aetUsedGet + nSlots > self wbTopGet ifTrue:[
		self stopBecauseOf: GErrorNoMoreSpace.
		^false
	].
	^true
]

{ #category : #testing }
BalloonEngineBase >> needsFlush [
	^self needsFlushGet ~= 0
]

{ #category : #'accessing state' }
BalloonEngineBase >> needsFlushGet [
	^workBuffer at: GWNeedsFlush
]

{ #category : #'accessing state' }
BalloonEngineBase >> needsFlushPut: value [
	^workBuffer at: GWNeedsFlush put: value
]

{ #category : #'accessing objects' }
BalloonEngineBase >> obj: object at: index [
	^objBuffer at: object + index
]

{ #category : #'accessing objects' }
BalloonEngineBase >> obj: object at: index put: value [
	^objBuffer at: object + index put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> objStartGet [
	^workBuffer at: GWObjStart
]

{ #category : #'accessing state' }
BalloonEngineBase >> objStartPut: value [
	^workBuffer at: GWObjStart put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> objUsedGet [
	^workBuffer at: GWObjUsed
]

{ #category : #'accessing state' }
BalloonEngineBase >> objUsedPut: value [
	^workBuffer at: GWObjUsed put: value
]

{ #category : #'accessing objects' }
BalloonEngineBase >> objectHeaderOf: obj [

	^self makeUnsignedFrom:(self obj: obj at: GEObjectType)
]

{ #category : #'accessing objects' }
BalloonEngineBase >> objectIndexOf: obj [

	^self obj: obj at: GEObjectIndex
]

{ #category : #'accessing objects' }
BalloonEngineBase >> objectIndexOf: obj put: value [

	^self obj: obj at: GEObjectIndex put: value
]

{ #category : #'accessing objects' }
BalloonEngineBase >> objectLengthOf: obj [

	^self obj: obj at: GEObjectLength
]

{ #category : #'accessing objects' }
BalloonEngineBase >> objectLengthOf: obj put: value [

	^self obj: obj at: GEObjectLength put: value
]

{ #category : #'accessing objects' }
BalloonEngineBase >> objectTypeOf: obj [

	^(self makeUnsignedFrom:(self obj: obj at: GEObjectType)) bitAnd: GEPrimitiveTypeMask
]

{ #category : #'accessing objects' }
BalloonEngineBase >> objectTypeOf: obj put: value [

	^self obj: obj at: GEObjectType put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> point1Get [
	<returnTypeC:'int *'>
	^self cCoerce: workBuffer + GWPoint1 to:'int *'
]

{ #category : #'accessing state' }
BalloonEngineBase >> point2Get [
	<returnTypeC:'int *'>
	^self cCoerce: workBuffer + GWPoint2 to:'int *'
]

{ #category : #'accessing state' }
BalloonEngineBase >> point3Get [
	<returnTypeC:'int *'>
	^self cCoerce: workBuffer + GWPoint3 to:'int *'
]

{ #category : #'accessing state' }
BalloonEngineBase >> point4Get [
	<returnTypeC:'int *'>
	^self cCoerce: workBuffer + GWPoint4 to:'int *'
]

{ #category : #displaying }
BalloonEngineBase >> postDisplayAction [
	"We have just blitted a scan line to the screen.
	Do whatever seems to be a good idea here."
	"Note: In the future we may check the time needed for this scan line and interrupt processing to give the Smalltalk code a chance to run at a certain time."

	<inline: false>

	"Check if there is any more work to do."
	(self getStartGet >= self getUsedGet and:[self aetUsedGet = 0]) ifTrue:[
		"No more entries to process"
		self statePut: GEStateCompleted.
	].
	(self currentYGet >= self fillMaxYGet) ifTrue:[
		"Out of clipping range"
		self statePut: GEStateCompleted.
	].
]

{ #category : #'primitives-other' }
BalloonEngineBase >> primitiveAbortProcessing [
	<export: true>
	<inline: false>
	| failureCode |
	interpreterProxy methodArgumentCount = 0
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].
	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 0)) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].
	self statePut: GEStateCompleted.
	self storeEngineStateInto: engine.
]

{ #category : #'primitives-incremental' }
BalloonEngineBase >> primitiveAddActiveEdgeEntry [
	"Note: No need to load either bitBlt or spanBuffer"
	| failureCode edgeOop edge |
	<export: true>
	<inline: false>
	doProfileStats ifTrue:[geProfileTime := interpreterProxy ioMicroMSecs].
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].
	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 1)
						requiredState: GEStateWaitingForEdge) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	edgeOop := interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	edge := self loadEdgeStateFrom: edgeOop.
	edge = nil ifTrue:[^interpreterProxy primitiveFailFor: GEFEdgeDataTooSmall].

	(self needAvailableSpace: 1) 
		ifFalse:[^interpreterProxy primitiveFailFor: GEFWorkTooBig].

	(self edgeNumLinesOf: edge) > 0 ifTrue:[
		self insertEdgeIntoAET: edge.
	].

	engineStopped ifTrue:[^interpreterProxy primitiveFailFor: GEFEngineStopped].

	self statePut: GEStateAddingFromGET. "Back to adding edges from GET"
	self storeEngineStateInto: engine.
	interpreterProxy pop: 1. "Leave rcvr on stack"
	doProfileStats ifTrue:[
		self incrementStat: GWCountAddAETEntry by: 1.
		self incrementStat: GWTimeAddAETEntry by: (interpreterProxy ioMicroMSecs - geProfileTime)].

]

{ #category : #'primitives-incremental' }
BalloonEngineBase >> primitiveChangedActiveEdgeEntry [
	"Note: No need to load either bitBlt or spanBuffer"
	| failureCode edgeOop edge |
	<export: true>
	<inline: false>
	doProfileStats ifTrue:[geProfileTime := interpreterProxy ioMicroMSecs].
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].

	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 1)
						requiredState: GEStateWaitingChange) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	edgeOop := interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	edge := self loadEdgeStateFrom: edgeOop.
	edge = nil ifTrue:[^interpreterProxy primitiveFailFor: GEFEdgeDataTooSmall].

	(self edgeNumLinesOf: edge) = 0 
		ifTrue:[	self removeFirstAETEntry]
		ifFalse:[	self resortFirstAETEntry.
				self aetStartPut: self aetStartGet + 1].

	self statePut: GEStateUpdateEdges. "Back to updating edges"
	self storeEngineStateInto: engine.
	interpreterProxy pop: 1. "Leave rcvr on stack"
	doProfileStats ifTrue:[
		self incrementStat: GWCountChangeAETEntry by: 1.
		self incrementStat: GWTimeChangeAETEntry by: (interpreterProxy ioMicroMSecs - geProfileTime)].

]

{ #category : #'primitives-other' }
BalloonEngineBase >> primitiveCopyBuffer [
	| failCode buf1 buf2 diff src dst |
	<export: true>
	<inline: false>
	<var: #src type:'int * '>
	<var: #dst type:'int * '>

	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].

	buf2 := interpreterProxy stackValue: 0.
	buf1 := interpreterProxy stackValue: 1.
	"Make sure the old buffer is properly initialized"
	(failCode := self loadWorkBufferFrom: buf1) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failCode].
	"Make sure the buffers are of the same type"
	(interpreterProxy fetchClassOf: buf1) = (interpreterProxy fetchClassOf: buf2)
		ifFalse:[^interpreterProxy primitiveFailFor: GEFClassMismatch].
	"Make sure buf2 is at least of the size of buf1"
	diff := (interpreterProxy slotSizeOf: buf2) - (interpreterProxy slotSizeOf: buf1).
	diff < 0 ifTrue:[^interpreterProxy primitiveFailFor: GEFSizeMismatch].

	"Okay - ready for copying. First of all just copy the contents up to wbTop"
	src := workBuffer.
	dst := interpreterProxy firstIndexableField: buf2.
	0 to: self wbTopGet-1 do:[:i|
		dst at: i put: (src at: i).
	].
	"Adjust wbSize and wbTop in the new buffer"
	dst at: GWBufferTop put: self wbTopGet + diff.
	dst at: GWSize put: self wbSizeGet + diff.
	"Now copy the entries from wbTop to wbSize"
	src := src + self wbTopGet.
	dst := dst + self wbTopGet + diff.
	0 to: (self wbSizeGet - self wbTopGet - 1) do:[:i|
		dst at: i put: (src at: i).
	].
	"Okay, done. Check the new buffer by loading the state from it"
	(failCode := self loadWorkBufferFrom: buf2) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failCode].
	interpreterProxy pop: 2. "Leave rcvr on stack"

]

{ #category : #'primitives-incremental' }
BalloonEngineBase >> primitiveDisplaySpanBuffer [
	"Note: Must load bitBlt and spanBuffer"
	<export: true>
	<inline: false>
	| failureCode |
	doProfileStats ifTrue:[geProfileTime := interpreterProxy ioMicroMSecs].
	interpreterProxy methodArgumentCount = 0
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].
	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 0)
						requiredState: GEStateBlitBuffer) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].
	"Load span buffer and bitBlt"
	(failureCode := self loadSpanBufferFrom:
		(interpreterProxy fetchPointer: BESpanIndex ofObject: engine)) = 0
			ifFalse:[^interpreterProxy primitiveFailFor: failureCode].
	(self loadBitBltFrom: 
		(interpreterProxy fetchPointer: BEBitBltIndex ofObject: engine))
			ifFalse:[^interpreterProxy primitiveFailFor: GEFBitBltLoadFailed].
	(self currentYGet bitAnd: self aaScanMaskGet) = self aaScanMaskGet ifTrue:[
		self displaySpanBufferAt: self currentYGet.
		self postDisplayAction.
	].
	self finishedProcessing ifFalse:[
		self aetStartPut: 0.
		self currentYPut: self currentYGet + 1.
		self statePut: GEStateUpdateEdges].
	self storeEngineStateInto: engine.
	doProfileStats ifTrue:[
		self incrementStat: GWCountDisplaySpan by: 1.
		self incrementStat: GWTimeDisplaySpan by: (interpreterProxy ioMicroMSecs - geProfileTime)].

]

{ #category : #'primitives-other' }
BalloonEngineBase >> primitiveDoProfileStats [
	"Turn on/off profiling. Return the old value of the flag."
	| oldValue newValue |
	<inline: false>
	<export: true>
	oldValue := doProfileStats.
	newValue := interpreterProxy stackObjectValue: 0.
	newValue := interpreterProxy booleanValueOf: newValue.
	interpreterProxy failed ifFalse:[
		doProfileStats := newValue.
		interpreterProxy pop: 2. "Pop rcvr, arg"
		interpreterProxy pushBool: oldValue.
	].
]

{ #category : #'primitives-other' }
BalloonEngineBase >> primitiveFinishedProcessing [
	| finished failureCode |
	<export: true>
	<inline: false>
	doProfileStats ifTrue:[geProfileTime := interpreterProxy ioMicroMSecs].
	interpreterProxy methodArgumentCount = 0
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].
	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 0)) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].
	finished := self finishedProcessing.
	self storeEngineStateInto: engine.
	interpreterProxy pop: 1.
	interpreterProxy pushBool: finished.
	doProfileStats ifTrue:[
		self incrementStat: GWCountFinishTest by: 1.
		self incrementStat: GWTimeFinishTest by: (interpreterProxy ioMicroMSecs - geProfileTime)].

]

{ #category : #'primitives-access' }
BalloonEngineBase >> primitiveGetAALevel [
	<export: true>
	<inline: false>
	| failureCode |
	interpreterProxy methodArgumentCount = 0
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].
	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 0)) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].
	interpreterProxy pop: 1.
	interpreterProxy pushInteger: self aaLevelGet.
]

{ #category : #'primitives-access' }
BalloonEngineBase >> primitiveGetClipRect [
	| failureCode rectOop pointOop |
	<export: true>
	<inline: false>

	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].

	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 1)) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	rectOop := interpreterProxy stackObjectValue: 0.
	(interpreterProxy failed not
	and: [(interpreterProxy isPointers: rectOop)
	and: [(interpreterProxy slotSizeOf: rectOop) >= 2]])
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	interpreterProxy pushRemappableOop: rectOop.
	pointOop := interpreterProxy makePointwithxValue: self clipMinXGet yValue: self clipMinYGet.
	interpreterProxy storePointer: 0 ofObject: interpreterProxy topRemappableOop withValue: pointOop.
	pointOop := interpreterProxy makePointwithxValue: self clipMaxXGet yValue: self clipMaxYGet.
	rectOop := interpreterProxy popRemappableOop.
	interpreterProxy storePointer: 1 ofObject: rectOop withValue: pointOop.

	interpreterProxy pop: 2 thenPush: rectOop.
]

{ #category : #'primitives-access' }
BalloonEngineBase >> primitiveGetCounts [
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
	and: [(interpreterProxy slotSizeOf: statOop) >= 9]])
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	stats := interpreterProxy firstIndexableField: statOop.
	stats at: 0 put: (stats at: 0) + (workBuffer at: GWCountInitializing).
	stats at: 1 put: (stats at: 1) + (workBuffer at: GWCountFinishTest).
	stats at: 2 put: (stats at: 2) + (workBuffer at: GWCountNextGETEntry).
	stats at: 3 put: (stats at: 3) + (workBuffer at: GWCountAddAETEntry).
	stats at: 4 put: (stats at: 4) + (workBuffer at: GWCountNextFillEntry).
	stats at: 5 put: (stats at: 5) + (workBuffer at: GWCountMergeFill).
	stats at: 6 put: (stats at: 6) + (workBuffer at: GWCountDisplaySpan).
	stats at: 7 put: (stats at: 7) + (workBuffer at: GWCountNextAETEntry).
	stats at: 8 put: (stats at: 8) + (workBuffer at: GWCountChangeAETEntry).

	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'primitives-access' }
BalloonEngineBase >> primitiveGetDepth [
	<export: true>
	<inline: false>
	| failureCode |
	interpreterProxy methodArgumentCount = 0
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].
	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 0)) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].
	interpreterProxy pop: 1.
	interpreterProxy pushInteger: self currentZGet.
]

{ #category : #'primitives-access' }
BalloonEngineBase >> primitiveGetFailureReason [
	"Return the reason why the last operation failed."
	<export: true>
	<inline: false>
	| failCode |
	interpreterProxy methodArgumentCount = 0
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].
	engine := interpreterProxy stackValue: 0.
	"Note -- don't call loadEngineFrom here because this will override the stopReason with Zero"
	(interpreterProxy isImmediate: engine) ifTrue:[^interpreterProxy primitiveFailFor: GEFEngineIsInteger].
	(interpreterProxy isPointers: engine) ifFalse:[^interpreterProxy primitiveFailFor: GEFEngineIsWords].
	(interpreterProxy slotSizeOf: engine) < BEBalloonEngineSize ifTrue:[^interpreterProxy primitiveFailFor: GEFEngineTooSmall].
	(failCode := self loadWorkBufferFrom: 
		(interpreterProxy fetchPointer: BEWorkBufferIndex ofObject: engine)) = 0
			ifFalse:[^interpreterProxy primitiveFailFor: failCode].
	interpreterProxy pop: 1.
	interpreterProxy pushInteger: self stopReasonGet.
]

{ #category : #'primitives-access' }
BalloonEngineBase >> primitiveGetOffset [
	| failureCode pointOop |
	<export: true>
	<inline: false>

	interpreterProxy methodArgumentCount = 0
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].

	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 0)) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].
	pointOop := interpreterProxy makePointwithxValue: self destOffsetXGet yValue: self destOffsetYGet.
	interpreterProxy pop: 1 thenPush: pointOop.
]

{ #category : #'primitives-access' }
BalloonEngineBase >> primitiveGetTimes [
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
	and: [(interpreterProxy slotSizeOf: statOop) >= 9]])
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	stats := interpreterProxy firstIndexableField: statOop.
	stats at: 0 put: (stats at: 0) + (workBuffer at: GWTimeInitializing).
	stats at: 1 put: (stats at: 1) + (workBuffer at: GWTimeFinishTest).
	stats at: 2 put: (stats at: 2) + (workBuffer at: GWTimeNextGETEntry).
	stats at: 3 put: (stats at: 3) + (workBuffer at: GWTimeAddAETEntry).
	stats at: 4 put: (stats at: 4) + (workBuffer at: GWTimeNextFillEntry).
	stats at: 5 put: (stats at: 5) + (workBuffer at: GWTimeMergeFill).
	stats at: 6 put: (stats at: 6) + (workBuffer at: GWTimeDisplaySpan).
	stats at: 7 put: (stats at: 7) + (workBuffer at: GWTimeNextAETEntry).
	stats at: 8 put: (stats at: 8) + (workBuffer at: GWTimeChangeAETEntry).

	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'primitives-other' }
BalloonEngineBase >> primitiveInitializeBuffer [
	| wbOop size |
	<export: true>
	<inline: false>
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	wbOop := interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isWords: wbOop) 
		ifFalse:[^interpreterProxy primitiveFail].
	(size := interpreterProxy slotSizeOf: wbOop) < GWMinimalSize
		ifTrue:[^interpreterProxy primitiveFail].
	self workBufferPut: wbOop.
	objBuffer := workBuffer + GWHeaderSize.
	self magicNumberPut: GWMagicNumber.
	self wbSizePut: size.
	self wbTopPut: size.
	self statePut: GEStateUnlocked.
	self objStartPut: GWHeaderSize.
	self objUsedPut: 4.	"Dummy fill object"
	self objectTypeOf: 0 put: GEPrimitiveFill.
	self objectLengthOf: 0 put: 4.
	self objectIndexOf: 0 put: 0.
	self getStartPut: 0.
	self getUsedPut: 0.
	self aetStartPut: 0.
	self aetUsedPut: 0.
	self stopReasonPut: 0.
	self needsFlushPut: 0.
	self clipMinXPut: 0.
	self clipMaxXPut: 0.
	self clipMinYPut: 0.
	self clipMaxYPut: 0.
	self currentZPut: 0.
	self resetGraphicsEngineStats.
	self initEdgeTransform.
	self initColorTransform.
	interpreterProxy pop: 2.
	interpreterProxy push: wbOop.
]

{ #category : #'primitives-incremental' }
BalloonEngineBase >> primitiveInitializeProcessing [
	"Note: No need to load bitBlt but must load spanBuffer"
	<export: true>
	<inline: false>
	| failureCode |
	doProfileStats ifTrue:[geProfileTime := interpreterProxy ioMicroMSecs].
	interpreterProxy methodArgumentCount = 0
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].
	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 0)
						requiredState: GEStateUnlocked) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].
	"Load span buffer for clear operation"
	(failureCode := self loadSpanBufferFrom:
		(interpreterProxy fetchPointer: BESpanIndex ofObject: engine)) = 0
			ifFalse:[^interpreterProxy primitiveFailFor: failureCode].
	self initializeGETProcessing.
	engineStopped ifTrue:[^interpreterProxy primitiveFailFor: GEFEngineStopped].
	self statePut: GEStateAddingFromGET. "Initialized"
	interpreterProxy failed ifFalse:[self storeEngineStateInto: engine].
	doProfileStats ifTrue:[
		self incrementStat: GWCountInitializing by: 1.
		self incrementStat: GWTimeInitializing by: (interpreterProxy ioMicroMSecs - geProfileTime)].

]

{ #category : #'primitives-incremental' }
BalloonEngineBase >> primitiveMergeFillFrom [
	"Note: No need to load bitBlt but must load spanBuffer"
	| failureCode fillOop bitsOop value |
	<export: true>
	<inline: false>
	doProfileStats ifTrue:[geProfileTime := interpreterProxy ioMicroMSecs].
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].
	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 2)
						requiredState: GEStateWaitingForFill) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].
	"Load span buffer for merging the fill"
	(failureCode := self loadSpanBufferFrom:
		(interpreterProxy fetchPointer: BESpanIndex ofObject: engine)) = 0
			ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	fillOop := interpreterProxy stackObjectValue: 0.
	bitsOop := interpreterProxy stackObjectValue: 1.
	"Check bitmap"
	(interpreterProxy failed not
	and: [(interpreterProxy fetchClassOf: bitsOop) = interpreterProxy classBitmap])
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	"Check fillOop"
	(interpreterProxy slotSizeOf: fillOop) < FTBalloonFillDataSize
		ifTrue:[^interpreterProxy primitiveFailFor: GEFFillDataTooSmall].
	"Check if this was the fill we have exported"
	value := interpreterProxy fetchInteger: FTIndexIndex ofObject: fillOop.
	(self objectIndexOf: self lastExportedFillGet) = value
		ifFalse:[^interpreterProxy primitiveFailFor: GEFWrongFill].
	value := interpreterProxy fetchInteger: FTMinXIndex ofObject: fillOop.
	self lastExportedLeftXGet = value
		ifFalse:[^interpreterProxy primitiveFailFor: GEFWrongFill].
	value := interpreterProxy fetchInteger: FTMaxXIndex ofObject: fillOop.
	self lastExportedRightXGet = value
		ifFalse:[^interpreterProxy primitiveFailFor: GEFWrongFill].

	(interpreterProxy slotSizeOf: bitsOop) < (self lastExportedRightXGet - self lastExportedLeftXGet)
		ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	interpreterProxy failed ifTrue:[^nil].

	self fillBitmapSpan: (interpreterProxy firstIndexableField: bitsOop)
		from: self lastExportedLeftXGet
		to: self lastExportedRightXGet.

	self statePut: GEStateScanningAET. "Back to scanning AET"
	self storeEngineStateInto: engine.
	interpreterProxy pop: 2. "Leave rcvr on stack"
	doProfileStats ifTrue:[
		self incrementStat: GWCountMergeFill by: 1.
		self incrementStat: GWTimeMergeFill by: (interpreterProxy ioMicroMSecs - geProfileTime)].

]

{ #category : #'primitives-access' }
BalloonEngineBase >> primitiveNeedsFlush [
	| failureCode needFlush |
	<export: true>
	<inline: false>
	interpreterProxy methodArgumentCount = 0
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].
	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 0)) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].
	needFlush := self needsFlush.
	self storeEngineStateInto: engine.
	interpreterProxy pop: 1.
	interpreterProxy pushBool: needFlush.
]

{ #category : #'primitives-access' }
BalloonEngineBase >> primitiveNeedsFlushPut [
	| failureCode needFlush |
	<export: true>
	<inline: false>
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].

	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 1)) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	needFlush := interpreterProxy booleanValueOf: (interpreterProxy stackValue: 0).
	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	needFlush == true 
		ifTrue:[self needsFlushPut: 1]
		ifFalse:[self needsFlushPut: 0].
	self storeEngineStateInto: engine.
	interpreterProxy pop: 1. "Leave rcvr on stack"

]

{ #category : #'primitives-incremental' }
BalloonEngineBase >> primitiveNextActiveEdgeEntry [
	"Note: No need to load either bitBlt or spanBuffer"
	| failureCode edgeOop hasEdge edge |
	<export: true>
	<inline: false>
	doProfileStats ifTrue:[geProfileTime := interpreterProxy ioMicroMSecs].
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].
	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 1)
						requiredState: GEStateUpdateEdges or: GEStateCompleted) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	edgeOop := interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	hasEdge := false.
	self stateGet = GEStateCompleted ifFalse:[
		hasEdge := self findNextExternalUpdateFromAET.
		hasEdge ifTrue:[
			edge := aetBuffer at: self aetStartGet.
			self storeEdgeStateFrom: edge into: edgeOop.
			"Do not advance to the next aet entry yet"
			"self aetStartPut: self aetStartGet + 1."
			self statePut: GEStateWaitingChange. "Wait for changed edge"
		] ifFalse:[self statePut: GEStateAddingFromGET]. "Start over"
	].
	interpreterProxy failed ifTrue:[^nil].

	self storeEngineStateInto: engine.

	interpreterProxy pop: 2.
	interpreterProxy pushBool: hasEdge not.
	doProfileStats ifTrue:[
		self incrementStat: GWCountNextAETEntry by: 1.
		self incrementStat: GWTimeNextAETEntry by: (interpreterProxy ioMicroMSecs - geProfileTime)].

]

{ #category : #'primitives-incremental' }
BalloonEngineBase >> primitiveNextFillEntry [
	"Note: No need to load bitBlt but must load spanBuffer"
	| failureCode fillOop hasFill |
	<export: true>
	<inline: false>
	doProfileStats ifTrue:[geProfileTime := interpreterProxy ioMicroMSecs].
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].
	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 1)
						requiredState: GEStateScanningAET) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].
	"Load span buffer for internal handling of fills"
	(failureCode := self loadSpanBufferFrom:
		(interpreterProxy fetchPointer: BESpanIndex ofObject: engine)) = 0
			ifFalse:[^interpreterProxy primitiveFailFor: failureCode].
	(self loadFormsFrom:
		(interpreterProxy fetchPointer: BEFormsIndex ofObject: engine))
			ifFalse:[^interpreterProxy primitiveFailFor: GEFFormLoadFailed].

	"Check if we have to clear the span buffer before proceeding"
	(self clearSpanBufferGet = 0) ifFalse:[
		(self currentYGet bitAnd: self aaScanMaskGet) = 0
			ifTrue:[self clearSpanBuffer].
		self clearSpanBufferPut: 0].

	fillOop := interpreterProxy stackObjectValue: 0.
	hasFill := self findNextExternalFillFromAET.
	engineStopped ifTrue:[^interpreterProxy primitiveFailFor: GEFEngineStopped].
	hasFill ifTrue:[self storeFillStateInto: fillOop].
	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: GEFWrongFill].
	hasFill
		ifTrue:[	self statePut: GEStateWaitingForFill]
		ifFalse:[	self wbStackClear.
				self spanEndAAPut: 0.
				self statePut: GEStateBlitBuffer].
	self storeEngineStateInto: engine.
	interpreterProxy pop: 2.
	interpreterProxy pushBool: hasFill not.
	doProfileStats ifTrue:[
		self incrementStat: GWCountNextFillEntry by: 1.
		self incrementStat: GWTimeNextFillEntry by: (interpreterProxy ioMicroMSecs - geProfileTime)]
]

{ #category : #'primitives-incremental' }
BalloonEngineBase >> primitiveNextGlobalEdgeEntry [
	"Note: No need to load either bitBlt or spanBuffer"
	| failureCode edgeOop hasEdge edge |
	<export: true>
	<inline: false>
	doProfileStats ifTrue:[geProfileTime := interpreterProxy ioMicroMSecs].
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].
	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 1)
						requiredState: GEStateAddingFromGET) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	edgeOop := interpreterProxy stackObjectValue: 0.
	hasEdge := self findNextExternalEntryFromGET.
	hasEdge ifTrue:[
		edge := getBuffer at: self getStartGet.
		self storeEdgeStateFrom: edge into: edgeOop.
		self getStartPut: self getStartGet + 1].

	interpreterProxy failed ifTrue:[^interpreterProxy primitiveFailFor: GEFWrongEdge].

	hasEdge
		ifTrue:[	self statePut: GEStateWaitingForEdge] "Wait for adding edges"
		ifFalse:[ "Start scanning the AET"
				self statePut: GEStateScanningAET.
				self clearSpanBufferPut: 1. "Clear span buffer at next entry"
				self aetStartPut: 0.
				self wbStackClear].
	self storeEngineStateInto: engine.

	interpreterProxy pop: 2.
	interpreterProxy pushBool: hasEdge not.
	doProfileStats ifTrue:[
		self incrementStat: GWCountNextGETEntry by: 1.
		self incrementStat: GWTimeNextGETEntry by: (interpreterProxy ioMicroMSecs - geProfileTime)].

]

{ #category : #'primitives-other' }
BalloonEngineBase >> primitiveRegisterExternalEdge [
	| failureCode rightFillIndex leftFillIndex initialZ initialY initialX index  edge |
	<export: true>
	<inline: false>
	interpreterProxy methodArgumentCount = 6 
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].
	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 6)
						requiredState: GEStateUnlocked) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	rightFillIndex := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 0).
	leftFillIndex := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 1).
	initialZ := interpreterProxy stackIntegerValue: 2.
	initialY := interpreterProxy stackIntegerValue: 3.
	initialX := interpreterProxy stackIntegerValue: 4.
	index := interpreterProxy stackIntegerValue: 5.
	interpreterProxy failed
		ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	(self allocateObjEntry: GEBaseEdgeSize) 
		ifFalse:[^interpreterProxy primitiveFailFor: GEFWorkTooBig].

	"Make sure the fills are okay"
	((self isFillOkay: leftFillIndex)
	and: [self isFillOkay: rightFillIndex])
		ifFalse:[^interpreterProxy primitiveFailFor: GEFWrongFill].

	edge := objUsed.
	objUsed := edge + GEBaseEdgeSize.
	"Install type and length"
	self objectTypeOf: edge put: GEPrimitiveEdge.
	self objectLengthOf: edge put: GEBaseEdgeSize.
	self objectIndexOf: edge put: index.
	"Install remaining stuff"
	self edgeXValueOf: edge put: initialX.
	self edgeYValueOf: edge put: initialY.
	self edgeZValueOf: edge put: initialZ.
	self edgeLeftFillOf: edge put: (self transformColor: leftFillIndex).
	self edgeRightFillOf: edge put: (self transformColor: rightFillIndex).
	engineStopped ifTrue:[^interpreterProxy primitiveFailFor: GEFEngineStopped].

	interpreterProxy failed ifFalse:[
		self storeEngineStateInto: engine.
		interpreterProxy pop: 6. "Leave rcvr on stack"
	].
]

{ #category : #'primitives-other' }
BalloonEngineBase >> primitiveRegisterExternalFill [
	| failureCode index  fill |
	<export: true>
	<inline: false>
	interpreterProxy methodArgumentCount = 1 
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].
	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 1)
						requiredState: GEStateUnlocked) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	index := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	"Note: We *must* not allocate any fill with index 0"
	fill := 0.
	[fill = 0] whileTrue:[
		(self allocateObjEntry: GEBaseEdgeSize) 
			ifFalse:[^interpreterProxy primitiveFailFor: GEFWorkTooBig].
		fill := objUsed.
		objUsed := fill + GEBaseFillSize.
		"Install type and length"
		self objectTypeOf: fill put: GEPrimitiveFill.
		self objectLengthOf: fill put: GEBaseFillSize.
		self objectIndexOf: fill put: index.
	].

	interpreterProxy failed ifFalse:[
		self storeEngineStateInto: engine.
		interpreterProxy pop: 2.
		interpreterProxy pushInteger: fill.
	].
]

{ #category : #'primitives-rendering' }
BalloonEngineBase >> primitiveRenderImage [
	"Start/Proceed rendering the entire image"
	<export: true>
	<inline: false>
	| failCode |
	(failCode := self loadRenderingState) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failCode].

	self proceedRenderingScanline. "Finish this scan line"
	engineStopped ifTrue:[^self storeRenderingState].
	self proceedRenderingImage. "And go on as usual"

	self storeRenderingState.
]

{ #category : #'primitives-rendering' }
BalloonEngineBase >> primitiveRenderScanline [
	"Start rendering the entire image"
	<export: true>
	<inline: false>
	| failCode |
	(failCode := self loadRenderingState) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failCode].

	self proceedRenderingScanline. "Finish the current scan line"

	self storeRenderingState.
]

{ #category : #'primitives-access' }
BalloonEngineBase >> primitiveSetAALevel [
	| failureCode level |
	<export: true>
	<inline: false>
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].
	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 1)
						requiredState: GEStateUnlocked) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].
	level := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed
		ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	self setAALevel: level.
	self storeEngineStateInto: engine.
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'primitives-access' }
BalloonEngineBase >> primitiveSetBitBltPlugin [
	"Primitive. Set the BitBlt plugin to use."
	| pluginName length ptr needReload |
	<export: true>
	<var: #ptr type:'char *'>
	pluginName := interpreterProxy stackValue: 0.
	"Must be string to work"
	(interpreterProxy isBytes: pluginName) 
		ifFalse:[^interpreterProxy primitiveFail].
	length := interpreterProxy byteSizeOf: pluginName.
	length >= 256 
		ifTrue:[^interpreterProxy primitiveFail].
	ptr := interpreterProxy firstIndexableField: pluginName.
	needReload := false.
	0 to: length-1 do:[:i|
		"Compare and store the plugin to be used"
		(bbPluginName at: i) = (ptr at: i) ifFalse:[
			bbPluginName at: i put: (ptr at: i).
			needReload := true]].
	(bbPluginName at: length) = 0 ifFalse:[
		bbPluginName at: length put: 0.
		needReload := true].
	needReload ifTrue:[
		self initialiseModule 
			ifFalse:[^interpreterProxy primitiveFail]].
	interpreterProxy pop: 1. "Return receiver"
]

{ #category : #'primitives-access' }
BalloonEngineBase >> primitiveSetClipRect [
	| failureCode rectOop |
	<export: true>
	<inline: false>

	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].

	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 1)
						requiredState: GEStateUnlocked) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	rectOop := interpreterProxy stackObjectValue: 0.
	(interpreterProxy failed not
	and: [(interpreterProxy isPointers: rectOop)
	and: [(interpreterProxy slotSizeOf: rectOop) >= 2]])
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	self loadPoint: self point1Get from: (interpreterProxy fetchPointer: 0 ofObject: rectOop).
	self loadPoint: self point2Get from: (interpreterProxy fetchPointer: 1 ofObject: rectOop).
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	self clipMinXPut: (self point1Get at: 0).
	self clipMinYPut: (self point1Get at: 1).
	self clipMaxXPut: (self point2Get at: 0).
	self clipMaxYPut: (self point2Get at: 1).
	self storeEngineStateInto: engine.
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'primitives-access' }
BalloonEngineBase >> primitiveSetColorTransform [
	| failureCode transformOop |
	<export: true>
	<inline: false>

	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].

	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 1)
						requiredState: GEStateUnlocked) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	transformOop := interpreterProxy stackObjectValue: 0.
	interpreterProxy failed
		ifTrue: [^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	self loadColorTransformFrom: transformOop.
	interpreterProxy failed
		ifTrue: [^interpreterProxy primitiveFailFor: GEFEntityLoadFailed].
	self storeEngineStateInto: engine.
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'primitives-access' }
BalloonEngineBase >> primitiveSetDepth [
	| failureCode depth |
	<export: true>
	<inline: false>

	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].

	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 1)
						requiredState: GEStateUnlocked) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	depth := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed
		ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	self currentZPut: depth.

	self storeEngineStateInto: engine.
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'primitives-access' }
BalloonEngineBase >> primitiveSetEdgeTransform [
	| failureCode transformOop |
	<export: true>
	<inline: false>

	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].

	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 1)
						requiredState: GEStateUnlocked) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	transformOop := interpreterProxy stackObjectValue: 0.
	interpreterProxy failed
		ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	self loadEdgeTransformFrom: transformOop.
	interpreterProxy failed
		ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	self storeEngineStateInto: engine.
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'primitives-access' }
BalloonEngineBase >> primitiveSetOffset [
	| failureCode pointOop |
	<export: true>
	<inline: false>

	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadNumArgs].

	(failureCode := self quickLoadEngineFrom: (interpreterProxy stackValue: 1)
						requiredState: GEStateUnlocked) = 0
		ifFalse:[^interpreterProxy primitiveFailFor: failureCode].

	pointOop := interpreterProxy stackValue: 0.
	(interpreterProxy fetchClassOf: pointOop) = interpreterProxy classPoint
		ifFalse:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	self loadPoint: self point1Get from: pointOop.
	interpreterProxy failed
		ifTrue:[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	self destOffsetXPut: (self point1Get at: 0).
	self destOffsetYPut: (self point1Get at: 1).
	self storeEngineStateInto: engine.
	interpreterProxy pop: 1. "Leave rcvr on stack"
]

{ #category : #'primitives-rendering' }
BalloonEngineBase >> proceedRenderingImage [
	"This is the main rendering entry"
	| external |
	<inline: false>
	[self finishedProcessing] whileFalse:[
		doProfileStats ifTrue:[geProfileTime := interpreterProxy ioMicroMSecs].
		external := self findNextExternalEntryFromGET.
		doProfileStats ifTrue:[
			self incrementStat: GWCountNextGETEntry by: 1.
			self incrementStat: GWTimeNextGETEntry by: (interpreterProxy ioMicroMSecs - geProfileTime)].
		engineStopped ifTrue:[^self statePut: GEStateAddingFromGET].
		external ifTrue:[
			self statePut: GEStateWaitingForEdge.
			^self stopBecauseOf: GErrorGETEntry.
		]. 
		self aetStartPut: 0.
		self wbStackClear.
		self clearSpanBufferPut: 1.

		doProfileStats ifTrue:[geProfileTime := interpreterProxy ioMicroMSecs].
		(self clearSpanBufferGet ~= 0 and:[(self currentYGet bitAnd: self aaScanMaskGet) = 0])
			ifTrue:[self clearSpanBuffer].
		self clearSpanBufferPut: 0.
		external := self findNextExternalFillFromAET.
		doProfileStats ifTrue:[
			self incrementStat: GWCountNextFillEntry by: 1.
			self incrementStat: GWTimeNextFillEntry by: (interpreterProxy ioMicroMSecs - geProfileTime)].
		engineStopped ifTrue:[^self statePut: GEStateScanningAET].
		external ifTrue:[
			self statePut: GEStateWaitingForFill.
			^self stopBecauseOf: GErrorFillEntry.
		].
		self wbStackClear.
		self spanEndAAPut: 0.

		doProfileStats ifTrue:[geProfileTime := interpreterProxy ioMicroMSecs].
		(self currentYGet bitAnd: self aaScanMaskGet) = self aaScanMaskGet ifTrue:[
			self displaySpanBufferAt: self currentYGet.
			self postDisplayAction.
		].
		doProfileStats ifTrue:[
			self incrementStat: GWCountDisplaySpan by: 1.
			self incrementStat: GWTimeDisplaySpan by: (interpreterProxy ioMicroMSecs - geProfileTime)].
		engineStopped ifTrue:[^self statePut: GEStateBlitBuffer].
		self finishedProcessing ifTrue:[^0].
		self aetStartPut: 0.
		self currentYPut: self currentYGet + 1.

		doProfileStats ifTrue:[geProfileTime := interpreterProxy ioMicroMSecs].
		external := self findNextExternalUpdateFromAET.
		doProfileStats ifTrue:[
			self incrementStat: GWCountNextAETEntry by: 1.
			self incrementStat: GWTimeNextAETEntry by: (interpreterProxy ioMicroMSecs - geProfileTime)].
		engineStopped ifTrue:[^self statePut: GEStateUpdateEdges].
		external ifTrue:[
			self statePut: GEStateWaitingChange.
			^self stopBecauseOf: GErrorAETEntry.
		].
	].
]

{ #category : #'primitives-rendering' }
BalloonEngineBase >> proceedRenderingScanline [
	"Proceed rendering the current scan line.
	This method may be called after some Smalltalk code has been executed inbetween."
	"This is the main rendering entry"
	| external state |
	<inline: false>
	state := self stateGet.

	state = GEStateUnlocked ifTrue:[
		self initializeGETProcessing.
		engineStopped ifTrue:[^0].
		state := GEStateAddingFromGET.
	]. 

	state = GEStateAddingFromGET ifTrue:[
		doProfileStats ifTrue:[geProfileTime := interpreterProxy ioMicroMSecs].
		external := self findNextExternalEntryFromGET.
		doProfileStats ifTrue:[
			self incrementStat: GWCountNextGETEntry by: 1.
			self incrementStat: GWTimeNextGETEntry by: (interpreterProxy ioMicroMSecs - geProfileTime)].
		engineStopped ifTrue:[^self statePut: GEStateAddingFromGET].
		external ifTrue:[
			self statePut: GEStateWaitingForEdge.
			^self stopBecauseOf: GErrorGETEntry.
		]. 
		self aetStartPut: 0.
		self wbStackClear.
		self clearSpanBufferPut: 1.
		state := GEStateScanningAET.
	].

	state = GEStateScanningAET ifTrue:[
		doProfileStats ifTrue:[geProfileTime := interpreterProxy ioMicroMSecs].
		(self clearSpanBufferGet ~= 0 and:[(self currentYGet bitAnd: self aaScanMaskGet) = 0])
			ifTrue:[self clearSpanBuffer].
		self clearSpanBufferPut: 0.
		external := self findNextExternalFillFromAET.
		doProfileStats ifTrue:[
			self incrementStat: GWCountNextFillEntry by: 1.
			self incrementStat: GWTimeNextFillEntry by: (interpreterProxy ioMicroMSecs - geProfileTime)].
		engineStopped ifTrue:[^self statePut: GEStateScanningAET].
		external ifTrue:[
			self statePut: GEStateWaitingForFill.
			^self stopBecauseOf: GErrorFillEntry.
		].
		state := GEStateBlitBuffer.
		self wbStackClear.
		self spanEndAAPut: 0.
	].

	state = GEStateBlitBuffer ifTrue:[
		doProfileStats ifTrue:[geProfileTime := interpreterProxy ioMicroMSecs].
		(self currentYGet bitAnd: self aaScanMaskGet) = self aaScanMaskGet ifTrue:[
			self displaySpanBufferAt: self currentYGet.
			self postDisplayAction.
		].
		doProfileStats ifTrue:[
			self incrementStat: GWCountDisplaySpan by: 1.
			self incrementStat: GWTimeDisplaySpan by: (interpreterProxy ioMicroMSecs - geProfileTime)].
		engineStopped ifTrue:[^self statePut: GEStateBlitBuffer].
		self finishedProcessing ifTrue:[^0].
		state := GEStateUpdateEdges.
		self aetStartPut: 0.
		self currentYPut: self currentYGet + 1.
	].

	state = GEStateUpdateEdges ifTrue:[
		doProfileStats ifTrue:[geProfileTime := interpreterProxy ioMicroMSecs].
		external := self findNextExternalUpdateFromAET.
		doProfileStats ifTrue:[
			self incrementStat: GWCountNextAETEntry by: 1.
			self incrementStat: GWTimeNextAETEntry by: (interpreterProxy ioMicroMSecs - geProfileTime)].
		engineStopped ifTrue:[^self statePut: GEStateUpdateEdges].
		external ifTrue:[
			self statePut: GEStateWaitingChange.
			^self stopBecauseOf: GErrorAETEntry.
		].
		self statePut: GEStateAddingFromGET.
	].
]

{ #category : #'loading state' }
BalloonEngineBase >> quickLoadEngineFrom: engineOop [
	"Load the minimal required state from the engineOop, e.g., just the work buffer.
	 Answer 0 on success or non-zero a failure code on failure"
	<inline: false>
	| failCode |
	interpreterProxy failed ifTrue:[^GEFAlreadyFailed].
	(interpreterProxy isImmediate: engineOop) ifTrue:[^GEFEngineIsInteger].
	(interpreterProxy isPointers: engineOop) ifFalse:[^GEFEngineIsWords].
	(interpreterProxy slotSizeOf: engineOop) < BEBalloonEngineSize ifTrue:[^GEFEngineTooSmall].
	engine := engineOop.
	(failCode := self loadWorkBufferFrom: (interpreterProxy
											fetchPointer: BEWorkBufferIndex
											ofObject: engineOop)) = 0
		ifFalse: [^failCode].
	self stopReasonPut: 0.
	objUsed := self objUsedGet.
	engineStopped := false.
	^0
]

{ #category : #'loading state' }
BalloonEngineBase >> quickLoadEngineFrom: oop requiredState: requiredState [
	<inline: false>
	| failureCode |
	(failureCode := self quickLoadEngineFrom: oop) = 0 ifFalse:[^failureCode].
	self stateGet = requiredState ifTrue:[^0].
	self stopReasonPut: GErrorBadState.
	^GEFWrongState
]

{ #category : #'loading state' }
BalloonEngineBase >> quickLoadEngineFrom: oop requiredState: requiredState or: alternativeState [
	<inline: false>
	| failureCode |
	(failureCode := self quickLoadEngineFrom: oop) = 0 ifFalse:[^failureCode].
	self stateGet = requiredState ifTrue:[^0].
	self stateGet = alternativeState ifTrue:[^0].
	self stopReasonPut: GErrorBadState.
	^GEFWrongState
]

{ #category : #'FILL processing' }
BalloonEngineBase >> quickRemoveInvalidFillsAt: leftX [
	"Remove any top fills if they have become invalid."
	self stackFillSize = 0 ifTrue:[^nil].
	[self topRightX <= leftX] whileTrue:[
		self hideFill: self topFill depth: self topDepth.
		self stackFillSize = 0 ifTrue:[^nil].
	].
]

{ #category : #'GET processing' }
BalloonEngineBase >> quickSortGlobalEdgeTable: array from: i to: j [ 
	"Sort elements i through j of self to be nondescending according to
	sortBlock."
	"Note: The original loop has been heavily re-written for C translation"
	| di dij dj tt ij k l n tmp again before |
	<var: #array type:'int *'>
	<inline: false>
	"The prefix d means the data at that index."
	(n := j + 1  - i) <= 1 ifTrue: [^0].	"Nothing to sort." 
	 "Sort di,dj."
	di := array at: i.
	dj := array at: j.
	before := self getSorts: di before: dj. "i.e., should di precede dj?"
	before ifFalse:[
		tmp := array at: i.
		array at: i put: (array at: j).
		array at: j put: tmp.
		tt := di.	di := dj.	dj := tt].
	n <= 2 ifTrue:[^0].

	"More than two elements."
	ij := (i + j) // 2.  "ij is the midpoint of i and j."
	dij := array at: ij.  "Sort di,dij,dj.  Make dij be their median."
	before := (self getSorts: di before: dij). "i.e. should di precede dij?"
	before ifTrue:[
		before := (self getSorts: dij before: dj). "i.e., should dij precede dj?"
		before ifFalse:["i.e., should dij precede dj?"
			tmp := array at: j.
			array at: j put: (array at: ij).
			array at: ij put: tmp.
			dij := dj]
	] ifFalse:[  "i.e. di should come after dij"
		tmp := array at: i.
		array at: i put: (array at: ij).
		array at: ij put: tmp.
		 dij := di].
	n <= 3 ifTrue:[^0].

	 "More than three elements."
	"Find k>i and l<j such that dk,dij,dl are in reverse order.
	Swap k and l.  Repeat this procedure until k and l pass each other."
	k := i.
	l := j.

	again := true.
	[again] whileTrue:[
		before := true.
		[before] whileTrue:[
			k <= (l := l - 1)
				ifTrue:[	tmp := array at: l.
						before := self getSorts: dij before: tmp]
				ifFalse:[before := false].
		].
		before := true.
		[before] whileTrue:[
			(k := k + 1) <= l
				ifTrue:[	tmp := array at: k.
						before := self getSorts: tmp before: dij]
				ifFalse:[before := false]].

		again := k <= l.
		again ifTrue:[
			tmp := array at: k.
			array at: k put: (array at: l).
			array at: l put: tmp]].

	"Now l<k (either 1 or 2 less), and di through dl are all less than or equal to dk
	through dj.  Sort those two segments."
	self quickSortGlobalEdgeTable: array from: i to: l.
	self quickSortGlobalEdgeTable: array from: k to: j.
]

{ #category : #'AET processing' }
BalloonEngineBase >> removeFirstAETEntry [
	| index |
	<inline: false>
	index := self aetStartGet.
	self aetUsedPut: self aetUsedGet - 1.
	[index < self aetUsedGet] whileTrue:[
		aetBuffer at: index put: (aetBuffer at: index + 1).
		index := index + 1.
	].
]

{ #category : #other }
BalloonEngineBase >> resetGraphicsEngineStats [
	<inline: false>
	workBuffer at: GWTimeInitializing put: 0.
	workBuffer at: GWTimeFinishTest put: 0.
	workBuffer at: GWTimeNextGETEntry put: 0.
	workBuffer at: GWTimeAddAETEntry put: 0.
	workBuffer at: GWTimeNextFillEntry put: 0.
	workBuffer at: GWTimeMergeFill put: 0.
	workBuffer at: GWTimeDisplaySpan put: 0.
	workBuffer at: GWTimeNextAETEntry put: 0.
	workBuffer at: GWTimeChangeAETEntry put: 0.

	workBuffer at: GWCountInitializing put: 0.
	workBuffer at: GWCountFinishTest put: 0.
	workBuffer at: GWCountNextGETEntry put: 0.
	workBuffer at: GWCountAddAETEntry put: 0.
	workBuffer at: GWCountNextFillEntry put: 0.
	workBuffer at: GWCountMergeFill put: 0.
	workBuffer at: GWCountDisplaySpan put: 0.
	workBuffer at: GWCountNextAETEntry put: 0.
	workBuffer at: GWCountChangeAETEntry put: 0.

	workBuffer at: GWBezierMonotonSubdivisions put: 0.
	workBuffer at: GWBezierHeightSubdivisions put: 0.
	workBuffer at: GWBezierOverflowSubdivisions put: 0.
	workBuffer at: GWBezierLineConversions put: 0.

]

{ #category : #'AET processing' }
BalloonEngineBase >> resortFirstAETEntry [
	| edge xValue leftEdge |
	<inline: false>
	self aetStartGet = 0 ifTrue:[^nil]. "Nothing to resort"
	edge := aetBuffer at: self aetStartGet.
	xValue := self edgeXValueOf: edge.
	leftEdge := aetBuffer at: (self aetStartGet - 1).
	(self edgeXValueOf: leftEdge) <= xValue ifTrue:[^nil]. "Okay"
	self moveAETEntryFrom: self aetStartGet edge: edge x: xValue.
]

{ #category : #other }
BalloonEngineBase >> setAALevel: level [
	"Set the anti-aliasing level. Three levels are supported:
		1 - No antialiasing
		2 - 2x2 unweighted anti-aliasing
		4 - 4x4 unweighted anti-aliasing.
	"
	| aaLevel |
	<inline: false>
	level >= 4 ifTrue:[aaLevel := 4].
	(level >= 2) & (level < 4) ifTrue:[aaLevel := 2].
	level < 2 ifTrue:[aaLevel := 1].
	self aaLevelPut: aaLevel.
	aaLevel = 1 ifTrue:[
		self aaShiftPut: 0.
		self aaColorMaskPut: 16rFFFFFFFF.
		self aaScanMaskPut: 0.
	].
	aaLevel = 2 ifTrue:[
		self aaShiftPut: 1.
		self aaColorMaskPut: 16rFCFCFCFC.
		self aaScanMaskPut: 1.
	].
	aaLevel = 4 ifTrue:[
		self aaShiftPut: 2.
		self aaColorMaskPut: 16rF0F0F0F0.
		self aaScanMaskPut: 3.
	].
	self aaColorShiftPut: self aaShiftGet * 2.
	self aaHalfPixelPut: self aaShiftGet.

]

{ #category : #'FILL processing' }
BalloonEngineBase >> showFill: fillIndex depth: depth rightX: rightX [
	<inline: false>
	(self allocateStackFillEntry) ifFalse:[^nil]. "Insufficient space"
	self stackFillValue: 0 put: fillIndex.
	self stackFillDepth: 0 put: depth.
	self stackFillRightX: 0 put: rightX.
	self stackFillSize = self stackFillEntryLength ifTrue:[^nil]. "No need to update"

	(self fillSorts: 0 before: self stackFillSize - self stackFillEntryLength) ifTrue:[
		"New top fill"
		self stackFillValue: 0 put: self topFillValue.
		self stackFillDepth: 0 put: self topFillDepth.
		self stackFillRightX: 0 put: self topFillRightX.
		self topFillValuePut: fillIndex.
		self topFillDepthPut: depth.
		self topFillRightXPut: rightX.
	].
]

{ #category : #other }
BalloonEngineBase >> smallSqrtTable [
	| theTable |
	<inline: false>
	<returnTypeC:'int *'>
	<var: #theTable declareC:'static int theTable[32] = 
	{0, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6}'>
	^theTable
]

{ #category : #'GET processing' }
BalloonEngineBase >> sortGlobalEdgeTable [
	"Sort the entire global edge table"
	self quickSortGlobalEdgeTable: getBuffer from: 0 to: self getUsedGet-1.
]

{ #category : #'accessing state' }
BalloonEngineBase >> spanEndAAGet [
	^workBuffer at: GWSpanEndAA
]

{ #category : #'accessing state' }
BalloonEngineBase >> spanEndAAPut: value [
	^workBuffer at: GWSpanEndAA put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> spanEndGet [
	^workBuffer at: GWSpanEnd
]

{ #category : #'accessing state' }
BalloonEngineBase >> spanEndPut: value [
	^workBuffer at: GWSpanEnd put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> spanSizeGet [
	^workBuffer at: GWSpanSize
]

{ #category : #'accessing state' }
BalloonEngineBase >> spanSizePut: value [
	^workBuffer at: GWSpanSize put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> spanStartGet [
	^workBuffer at: GWSpanStart
]

{ #category : #'accessing state' }
BalloonEngineBase >> spanStartPut: value [
	^workBuffer at: GWSpanStart put: value
]

{ #category : #other }
BalloonEngineBase >> squaredLengthOf: deltaX with: deltaY [
	^(deltaX * deltaX) + (deltaY * deltaY)
]

{ #category : #'accessing fills' }
BalloonEngineBase >> stackFillDepth: index [
	^self wbStackValue: index+1
]

{ #category : #'accessing fills' }
BalloonEngineBase >> stackFillDepth: index put: value [
	^self wbStackValue: index+1 put: value
]

{ #category : #'accessing fills' }
BalloonEngineBase >> stackFillEntryLength [
	^3
]

{ #category : #'accessing fills' }
BalloonEngineBase >> stackFillRightX: index [
	^self wbStackValue: index+2
]

{ #category : #'accessing fills' }
BalloonEngineBase >> stackFillRightX: index put: value [
	^self wbStackValue: index+2 put: value
]

{ #category : #'accessing fills' }
BalloonEngineBase >> stackFillSize [
	^self wbStackSize
]

{ #category : #'accessing fills' }
BalloonEngineBase >> stackFillValue: index [
	^self wbStackValue: index
]

{ #category : #'accessing fills' }
BalloonEngineBase >> stackFillValue: index put: value [
	^self wbStackValue: index put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> stateGet [
	^workBuffer at: GWState
]

{ #category : #'accessing state' }
BalloonEngineBase >> statePut: value [
	^workBuffer at: GWState put: value
]

{ #category : #other }
BalloonEngineBase >> stopBecauseOf: stopReason [
	self stopReasonPut: stopReason.
	engineStopped := true.
]

{ #category : #'accessing state' }
BalloonEngineBase >> stopReasonGet [
	^workBuffer at: GWStopReason
]

{ #category : #'accessing state' }
BalloonEngineBase >> stopReasonPut: value [
	^workBuffer at: GWStopReason put: value
]

{ #category : #'storing state' }
BalloonEngineBase >> storeEdgeStateFrom: edge into: edgeOop [

	<inline: false>
	(interpreterProxy slotSizeOf: edgeOop) < ETBalloonEdgeDataSize 
		ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy storeInteger: ETIndexIndex ofObject: edgeOop withValue: 
		(self objectIndexOf: edge).
	interpreterProxy storeInteger: ETXValueIndex ofObject: edgeOop withValue: 
		(self edgeXValueOf: edge).
	interpreterProxy storeInteger: ETYValueIndex ofObject: edgeOop withValue: 
		(self currentYGet).
	interpreterProxy storeInteger: ETZValueIndex ofObject: edgeOop withValue: 
		(self edgeZValueOf: edge).
	interpreterProxy storeInteger: ETLinesIndex ofObject: edgeOop withValue: 
		(self edgeNumLinesOf: edge).
	self lastExportedEdgePut: edge.
]

{ #category : #'storing state' }
BalloonEngineBase >> storeEngineStateInto: oop [
	self objUsedPut: objUsed.
]

{ #category : #'storing state' }
BalloonEngineBase >> storeFillStateInto: fillOop [
	| fillIndex leftX rightX |
	<inline: false>
	fillIndex := self lastExportedFillGet.
	leftX := self lastExportedLeftXGet.
	rightX := self lastExportedRightXGet.

	(interpreterProxy slotSizeOf: fillOop) < FTBalloonFillDataSize 
		ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy storeInteger: FTIndexIndex ofObject: fillOop withValue: 
		(self objectIndexOf: fillIndex).
	interpreterProxy storeInteger: FTMinXIndex ofObject: fillOop withValue: leftX.
	interpreterProxy storeInteger: FTMaxXIndex ofObject: fillOop withValue: rightX.
	interpreterProxy storeInteger: FTYValueIndex ofObject: fillOop withValue: self currentYGet.
]

{ #category : #'primitives-rendering' }
BalloonEngineBase >> storeRenderingState [
	<inline: false>
	interpreterProxy failed ifTrue:[^nil].
	engineStopped ifTrue:[
		"Check the stop reason and store the required information"
		self storeStopStateIntoEdge: (interpreterProxy stackObjectValue: 1) 
			fill: (interpreterProxy stackObjectValue: 0).
	].
	self storeEngineStateInto: engine.
	interpreterProxy pop: 3.
	interpreterProxy pushInteger: self stopReasonGet.
]

{ #category : #'storing state' }
BalloonEngineBase >> storeStopStateIntoEdge: edgeOop fill: fillOop [
	| reason edge |
	reason := self stopReasonGet.

	reason = GErrorGETEntry ifTrue:[
		edge := getBuffer at: self getStartGet.
		self storeEdgeStateFrom: edge into: edgeOop.
		self getStartPut: self getStartGet + 1.
	].

	reason = GErrorFillEntry ifTrue:[
		self storeFillStateInto: fillOop.
	].

	reason = GErrorAETEntry ifTrue:[
		edge := aetBuffer at: self aetStartGet.
		self storeEdgeStateFrom: edge into: edgeOop.
		"Do not advance to the next aet entry yet"
		"self aetStartPut: self aetStartGet + 1."
	].
]

{ #category : #'FILL processing' }
BalloonEngineBase >> toggleFill: fillIndex depth: depth rightX: rightX [
	"Make the fill style with the given index either visible or invisible"
	| hidden |
	<inline: false>

	self stackFillSize = 0 ifTrue:[
		(self allocateStackFillEntry) ifTrue:[
			self topFillValuePut: fillIndex.
			self topFillDepthPut: depth.
			self topFillRightXPut: rightX.
		].
	] ifFalse:[
		hidden := self hideFill: fillIndex depth: depth.
		hidden ifFalse:[self showFill: fillIndex depth: depth rightX: rightX].
	].
]

{ #category : #'FILL processing' }
BalloonEngineBase >> toggleFillsOf: edge [
	| depth fillIndex |
	<inline: false>

	(self needAvailableSpace: self stackFillEntryLength * 2) 
		ifFalse:[^nil]. "Make sure we have enough space left"
	depth := (self edgeZValueOf: edge) << 1.
	fillIndex := self edgeLeftFillOf: edge.
	fillIndex = 0 ifFalse:[self toggleFill: fillIndex depth: depth rightX: 999999999].
	fillIndex := self edgeRightFillOf: edge.
	fillIndex = 0 ifFalse:[self toggleFill: fillIndex depth: depth rightX: 999999999].
	self quickRemoveInvalidFillsAt: (self edgeXValueOf: edge).
]

{ #category : #'FILL processing' }
BalloonEngineBase >> toggleWideFillOf: edge [
	| fill type lineWidth depth rightX index |
	<inline: false>
	type := self edgeTypeOf: edge.
	dispatchedValue := edge.
	self dispatchOn: type in: WideLineWidthTable.
	lineWidth := dispatchReturnValue.
	self dispatchOn: type in: WideLineFillTable.
	fill := dispatchReturnValue.
	fill = 0 ifTrue:[^nil].
	(self needAvailableSpace: self stackFillEntryLength) 
		ifFalse:[^nil]. "Make sure we have enough space left"
	depth := (self edgeZValueOf: edge) << 1 + 1. "So lines sort before interior fills"
	rightX := (self edgeXValueOf: edge) + lineWidth.
	index := self findStackFill: fill depth: depth.
	index = -1 ifTrue:[
		self showFill: fill 
			depth: depth
			rightX: rightX.
	] ifFalse:[
		(self stackFillRightX: index) < rightX
			ifTrue:[self stackFillRightX: index put: rightX].
	].
	self quickRemoveInvalidFillsAt: (self edgeXValueOf: edge).
]

{ #category : #'accessing fills' }
BalloonEngineBase >> topDepth [
	self stackFillSize = 0
		ifTrue:[^-1]
		ifFalse:[^self topFillDepth].
]

{ #category : #'accessing fills' }
BalloonEngineBase >> topFill [
	self stackFillSize = 0
		ifTrue:[^0]
		ifFalse:[^self topFillValue].
]

{ #category : #'accessing fills' }
BalloonEngineBase >> topFillDepth [
	^self stackFillDepth: self stackFillSize - self stackFillEntryLength
]

{ #category : #'accessing fills' }
BalloonEngineBase >> topFillDepthPut: value [
	^self stackFillDepth: self stackFillSize - self stackFillEntryLength put: value
]

{ #category : #'accessing fills' }
BalloonEngineBase >> topFillRightX [
	^self stackFillRightX: self stackFillSize - self stackFillEntryLength
]

{ #category : #'accessing fills' }
BalloonEngineBase >> topFillRightXPut: value [
	^self stackFillRightX: self stackFillSize - self stackFillEntryLength put: value
]

{ #category : #'accessing fills' }
BalloonEngineBase >> topFillValue [
	^self stackFillValue: self stackFillSize - self stackFillEntryLength
]

{ #category : #'accessing fills' }
BalloonEngineBase >> topFillValuePut: value [
	^self stackFillValue: self stackFillSize - self stackFillEntryLength put: value
]

{ #category : #'accessing fills' }
BalloonEngineBase >> topRightX [
	self stackFillSize = 0
		ifTrue:[^999999999]
		ifFalse:[^self topFillRightX].
]

{ #category : #transforming }
BalloonEngineBase >> transformColor: fillIndex [
	| r g b a transform alphaScale |
	<var: #transform type:'float *'>
	<var: #alphaScale type:'double '>
	(fillIndex = 0 or:[self isFillColor: fillIndex]) ifFalse:[^fillIndex].
	b := fillIndex bitAnd: 255.
	g := (fillIndex >> 8) bitAnd: 255.
	r := (fillIndex >> 16) bitAnd: 255.
	a := (fillIndex >> 24) bitAnd: 255.
	(self hasColorTransform) ifTrue:[
		transform := self colorTransform.
		alphaScale := (a * (transform at: 6) + (transform at: 7)) / a.
		r := (r * (transform at: 0) + (transform at: 1) * alphaScale) asInteger.
		g := (g * (transform at: 2) + (transform at: 3) * alphaScale) asInteger.
		b := (b * (transform at: 4) + (transform at: 5) * alphaScale) asInteger.
		a := a * alphaScale.
		r := r max: 0. r := r min: 255.
		g := g max: 0. g := g min: 255.
		b := b max: 0. b := b min: 255.
		a := a max: 0. a := a min: 255.
	].
	a < 1 ifTrue:[^0]."ALWAYS return zero for transparent fills"
	"If alpha is not 255 (or close thereto) then we need to flush the engine before proceeding"
	(a < 255 and:[self needsFlush]) 
		ifTrue:[self stopBecauseOf: GErrorNeedFlush].
	^b + (g << 8) + (r << 16) + (a << 24)
]

{ #category : #transforming }
BalloonEngineBase >> transformPoint: point [
	"Transform the given point. If haveMatrix is true then use the current transformation."
	<var:#point type:'int *'>
	self hasEdgeTransform ifFalse:[
		"Multiply each component by aaLevel and add a half pixel"
		point at: 0 put: (point at: 0) + self destOffsetXGet * self aaLevelGet.
		point at: 1 put: (point at: 1) + self destOffsetYGet * self aaLevelGet.
	] ifTrue:[
		"Note: AA adjustment is done in #transformPoint: for higher accuracy"
		self transformPoint: point into: point.
	].
]

{ #category : #transforming }
BalloonEngineBase >> transformPoint: srcPoint into: dstPoint [
	"Transform srcPoint into dstPoint by using the currently loaded matrix"
	"Note: This method has been rewritten so that inlining works (e.g., removing
	the declarations and adding argument coercions at the appropriate points)"
	<inline: true>
	self transformPointX: ((self cCoerce: srcPoint to: 'int *') at: 0) asFloat 
		y: ((self cCoerce: srcPoint to:'int *') at: 1) asFloat
		into: (self cCoerce: dstPoint to: 'int *')
]

{ #category : #transforming }
BalloonEngineBase >> transformPointX: xValue y: yValue into: dstPoint [
	"Transform srcPoint into dstPoint by using the currently loaded matrix"
	"Note: This should be rewritten so that inlining works (e.g., removing
	the declarations and adding argument coercions at the appropriate points)"
	| x y transform |
	<inline: true>
	<var: #dstPoint type:'int *'>
	<var: #xValue type: 'double '>
	<var: #yValue type: 'double '>
	<var: #transform type:'float *'>
	transform := self edgeTransform.
	x := ((((transform at: 0) * xValue) +
		((transform at: 1) * yValue) +
		(transform at: 2)) * self aaLevelGet asFloat) asInteger.
	y := ((((transform at: 3) * xValue) +
		((transform at: 4) * yValue) +
		(transform at: 5)) * self aaLevelGet asFloat) asInteger.
	dstPoint at: 0 put: x.
	dstPoint at: 1 put: y.
]

{ #category : #transforming }
BalloonEngineBase >> transformPoints: n [
	"Transform n (n=1,2,3) points.
	If haveMatrix is true then the matrix contains the actual transformation."
	<inline: true>
	n > 0 ifTrue:[self transformPoint: self point1Get].
	n > 1 ifTrue:[self transformPoint: self point2Get].
	n > 2 ifTrue:[self transformPoint: self point3Get].
	n > 3 ifTrue:[self transformPoint: self point4Get].
]

{ #category : #transforming }
BalloonEngineBase >> transformWidth: w [
	"Transform the given width"
	| deltaX deltaY dstWidth dstWidth2 |
	<inline: false>
	<var: #deltaX type:'double '>
	<var: #deltaY type:'double '>
	w = 0 ifTrue:[^0].
	self point1Get at: 0 put: 0.
	self point1Get at: 1 put: 0.
	self point2Get at: 0 put: w * 256.
	self point2Get at: 1 put: 0.
	self point3Get at: 0 put: 0.
	self point3Get at: 1 put: w * 256.
	self transformPoints: 3.
	deltaX := ((self point2Get at: 0) - (self point1Get at: 0)) asFloat.
	deltaY := ((self point2Get at: 1) - (self point1Get at: 1)) asFloat.
	dstWidth := (((deltaX * deltaX) + (deltaY * deltaY)) sqrt asInteger + 128) // 256.
	deltaX := ((self point3Get at: 0) - (self point1Get at: 0)) asFloat.
	deltaY := ((self point3Get at: 1) - (self point1Get at: 1)) asFloat.
	dstWidth2 := (((deltaX * deltaX) + (deltaY * deltaY)) sqrt asInteger + 128) // 256.
	dstWidth2 < dstWidth ifTrue:[dstWidth := dstWidth2].
	dstWidth = 0
		ifTrue:[^1]
		ifFalse:[^dstWidth]
]

{ #category : #transforming }
BalloonEngineBase >> uncheckedTransformColor: fillIndex [
	| r g b a transform |
	<var: #transform type:'float *'>
	(self hasColorTransform) ifFalse:[^fillIndex].
	b := fillIndex bitAnd: 255.
	g := (fillIndex >> 8) bitAnd: 255.
	r := (fillIndex >> 16) bitAnd: 255.
	a := (fillIndex >> 24) bitAnd: 255.
	transform := self colorTransform.
	r := (r * (transform at: 0) + (transform at: 1)) asInteger.
	g := (g * (transform at: 2) + (transform at: 3)) asInteger.
	b := (b * (transform at: 4) + (transform at: 5)) asInteger.
	a := (a * (transform at: 6) + (transform at: 7)) asInteger.
	r := r max: 0. r := r min: 255.
	g := g max: 0. g := g min: 255.
	b := b max: 0. b := b min: 255.
	a := a max: 0. a := a min: 255.
	a < 16 ifTrue:[^0]."ALWAYS return zero for transparent fills"
	^b + (g << 8) + (r << 16) + (a << 24)
]

{ #category : #'accessing state' }
BalloonEngineBase >> wbSizeGet [
	^workBuffer at: GWSize
]

{ #category : #'accessing state' }
BalloonEngineBase >> wbSizePut: value [
	^workBuffer at: GWSize put: value
]

{ #category : #'accessing stack' }
BalloonEngineBase >> wbStackClear [
	self wbTopPut: self wbSizeGet.
]

{ #category : #'accessing stack' }
BalloonEngineBase >> wbStackPop: nItems [

	self wbTopPut: self wbTopGet + nItems.
]

{ #category : #'accessing stack' }
BalloonEngineBase >> wbStackPush: nItems [
	(self allocateStackEntry: nItems) ifFalse:[^false].
	self wbTopPut: self wbTopGet - nItems.
	^true
]

{ #category : #'accessing stack' }
BalloonEngineBase >> wbStackSize [
	^self wbSizeGet - self wbTopGet
]

{ #category : #'accessing stack' }
BalloonEngineBase >> wbStackValue: index [

	^workBuffer at: self wbTopGet + index
]

{ #category : #'accessing stack' }
BalloonEngineBase >> wbStackValue: index put: value [

	^workBuffer at: self wbTopGet + index put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> wbTopGet [
	^workBuffer at: GWBufferTop
]

{ #category : #'accessing state' }
BalloonEngineBase >> wbTopPut: value [
	^workBuffer at: GWBufferTop put: value
]

{ #category : #'accessing state' }
BalloonEngineBase >> workBufferPut: wbOop [
	workBuffer := interpreterProxy firstIndexableField: wbOop.
]
