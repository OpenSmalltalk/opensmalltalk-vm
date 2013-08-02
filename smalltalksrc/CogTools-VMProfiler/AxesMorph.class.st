"
I am responsible for drawing a pair of axes, a grid, and various labels.  I am not responsible for the display of any data, or for handling user input in any special way.
"
Class {
	#name : #AxesMorph,
	#superclass : #RectangleMorph,
	#instVars : [
		'form',
		'limitMaxX',
		'limitMinX',
		'limitMaxY',
		'limitMinY',
		'title',
		'xmax',
		'xmid',
		'xmin',
		'ymax',
		'ymid',
		'ymin',
		'xAxisFormatter',
		'yAxisFormatter',
		'margin',
		'grid',
		'drawCotas'
	],
	#category : #'CogTools-VMProfiler'
}

{ #category : #accessing }
AxesMorph >> baseColor [
	"Answer the base color to calculate other colors from"
	| baseColor current |

	baseColor := self color.
	current := self.
	[current notNil & (baseColor = Color transparent)]
		whileTrue: [""
			baseColor := current color.
			current := current owner].
	^ baseColor
]

{ #category : #'change reporting' }
AxesMorph >> changed [

	super changed.
	form := nil.
]

{ #category : #accessing }
AxesMorph >> color: aColor [ 
	
	super color: aColor.
	self updateCotas
]

{ #category : #drawing }
AxesMorph >> cotaColor [
	| baseColor lighter darker |
	baseColor := self baseColor asNontranslucentColor.
	baseColor = Color white
		ifTrue: [^ Color black].
	""
	lighter := baseColor muchLighter.
	darker := baseColor muchDarker.
	""
	^ (lighter diff: baseColor) > (darker diff: baseColor)
		ifTrue: [lighter]
		ifFalse: [darker]
]

{ #category : #utility }
AxesMorph >> dataPointToGridPoint: aPoint [
	"Compute the pixel coordinates wrt the grid origin of the given data point."
	| drawBounds |

	drawBounds := self drawBounds.
	^ (aPoint - self minPoint) * (drawBounds width @ drawBounds height negated).

]

{ #category : #utility }
AxesMorph >> dataPointToWorldPoint: aPoint [
	"Compute the pixel coordinates wrt the World origin of the given data point."

	^ (self dataPointToGridPoint: aPoint) + self gridOrigin
]

{ #category : #geometry }
AxesMorph >> drawBounds [
	"answer the rectangle inside the morph where the plot is drawn"
	^ (0 @ 0 rect: self width @ self height - (self borderWidth * 2))
		insetBy: margin
]

{ #category : #drawing }
AxesMorph >> drawGridOn: aCanvas [ 
	| gridColor right bottom width height lighter darker baseColor |
	baseColor := self baseColor.
	lighter := baseColor twiceLighter.
	darker := baseColor twiceDarker.
	gridColor := (lighter diff: baseColor) 
				> (darker diff: baseColor) ifTrue: [lighter] ifFalse: [darker].
	""
	right := self bounds width - margin.
	width := self bounds width - (margin * 2).
	bottom := self bounds height - margin.
	height := self bounds height - (margin * 2).
	(margin to: right by: width / 10) do: 
			[:x | | xRounded |
			xRounded := x rounded.
			aCanvas 
				line: xRounded @ margin
				to: xRounded @ bottom
				color: gridColor].
	(margin to: bottom by: height / 10) do: 
			[:y | | yRounded |
			yRounded := y rounded.
			aCanvas 
				line: margin @ yRounded
				to: right @ yRounded
				color: gridColor]
]

{ #category : #drawing }
AxesMorph >> drawOn: aCanvas [ 
	super drawOn: aCanvas.
	aCanvas
		image: self form
		at: self topLeft + self borderWidth
		rule: Form blend
]

{ #category : #geometry }
AxesMorph >> extent: aPoint [ 
	super
		extent: (aPoint max: self minExtent)
]

{ #category : #naming }
AxesMorph >> externalName [
	^ super externalName, (title contents isEmpty ifTrue:[''] ifFalse:[' - ', title contents])
]

{ #category : #drawing }
AxesMorph >> form [

	form ifNil: [
		Cursor wait showWhile: [
			form := Form 
						extent: (self bounds insetBy: self borderWidth) extent
						depth: Display depth.
			form fillColor: self color. 
			self updateForm]].
	^ form
]

{ #category : #accessing }
AxesMorph >> graphBounds: aRectangle [
 	"Sets the axes and then draws."

	Transcript cr; print: aRectangle; flush.
	limitMinX := aRectangle left.
	limitMinY := aRectangle bottom.
	limitMaxX := aRectangle right.
	limitMaxY := aRectangle top.
	self changed
]

{ #category : #accessing }
AxesMorph >> gridOrigin [
	"Answer the intersection of the two axes (lower left corner of the grid)"
	| inset |

	inset := self borderWidth + margin.
	^ self bottomLeft + (inset @ inset negated)
]

{ #category : #utility }
AxesMorph >> gridPointToDataPoint: aPoint [
	"Compute the coordinates of the data point corresponding to the given grid point (given in pixel coordinates wrt the grid origin)."
	| drawBounds |

	drawBounds := self drawBounds.
	^ (aPoint x @ aPoint y negated) / (drawBounds extent) + self minPoint

]

{ #category : #initialization }
AxesMorph >> initialize [

	super initialize.

	self color: Color gray.
	grid := PlotMorphGrid on: self.

	xAxisFormatter := [:x | x printString].
	yAxisFormatter := [:y | y printString].
	self initializeCotas.
	margin := 15 max: (title height + 2).
	form := nil.
	self extent: 1@1.
]

{ #category : #initialization }
AxesMorph >> initializeCotas [
	drawCotas := true.
	""
	title := StringMorph contents: '' font: TextStyle defaultFont emphasis: 1.
	xmax := StringMorph contents: ''.
	xmid := StringMorph contents: ''.
	xmin := StringMorph contents: ''.
	ymax := StringMorph contents: ''.
	ymid := StringMorph contents: ''.
	ymin := StringMorph contents: ''.
	""
	self addMorph: title.
	self addMorph: xmax.
	self addMorph: xmid.
	self addMorph: xmin.
	self addMorph: ymax.
	self addMorph: ymid.
	self addMorph: ymin.
	""
	limitMinX := 0.
	limitMaxX := 1.0.
	limitMinY := 0.
	limitMaxY := 1.0.
]

{ #category : #accessing }
AxesMorph >> limitMaxX: aNumberOrNil [
 	"Set the maximum value along the X axis.  If nil, this value will be computed from the data points to be displayed (subclass responsibility, since AxesMorph doesn't know anything about data)."

	limitMaxX := aNumberOrNil.
	self changed.
]

{ #category : #accessing }
AxesMorph >> limitMaxY: aNumberOrNil [
 	"Set the maximum value along the X axis.  If nil, this value will be computed from the data points to be displayed (subclass responsibility, since AxesMorph doesn't know anything about data)."
 
	limitMaxY := aNumberOrNil.
	self changed
]

{ #category : #accessing }
AxesMorph >> limitMinX: aNumberOrNil [ 
 	"Set the maximum value along the X axis.  If nil, this value will be computed from the data points to be displayed (subclass responsibility, since AxesMorph doesn't know anything about data)."

	limitMinX := aNumberOrNil. 
	self changed
]

{ #category : #accessing }
AxesMorph >> limitMinX: minNumberOrNil limitMaxX: maxNumberOrNil [
 	"Set the minimum and maximum values along the X axis.  If nil, these
	 values will be computed from the data points to be displayed (subclass
	 responsibility, since AxesMorph doesn't know anything about data)."

	limitMinX := minNumberOrNil.
	limitMaxX := maxNumberOrNil.
	self changed
]

{ #category : #accessing }
AxesMorph >> limitMinY: aNumberOrNil [ 
 	"Set the maximum value along the X axis.  If nil, this value will be computed from the data points to be displayed (subclass responsibility, since AxesMorph doesn't know anything about data)."

	limitMinY := aNumberOrNil. 
	self changed
]

{ #category : #accessing }
AxesMorph >> margin [
	"Answer the width of the margin surrounding the grid."
 
	^margin
]

{ #category : #accessing }
AxesMorph >> margin: anInteger [
	"Set the size of the margin surrounding the grid."
 
	margin := anInteger.
	self changed
]

{ #category : #drawing }
AxesMorph >> maxPoint [
	"Limit values must be non-nil"

	^ limitMaxX @ limitMaxY
]

{ #category : #geometry }
AxesMorph >> minExtent [
	^ 125 @ 125 + margin 
]

{ #category : #drawing }
AxesMorph >> minPoint [
	"Limit values must be non-nil"

	^ limitMinX @ limitMinY
]

{ #category : #accessing }
AxesMorph >> referenceColor [
	"This name is confusing because it sounds like it has something to do with PlotMorphs 'references' instance variable."

	self deprecatedExplanation: 'use #baseColor instead'.
	^ self baseColor
]

{ #category : #accessing }
AxesMorph >> shouldDrawAxis: aBoolean [ 

	grid drawAxis: aBoolean.
	self changed
]

{ #category : #accessing }
AxesMorph >> shouldDrawCotas: aBoolean [ 
	aBoolean = drawCotas ifTrue: [^self].
	""
	drawCotas := aBoolean.
	title visible: aBoolean.
	xmax visible: aBoolean.
	xmid visible: aBoolean.
	xmin visible: aBoolean.
	ymax visible: aBoolean.
	ymid visible: aBoolean.
	ymin visible: aBoolean.
	""
	self changed
]

{ #category : #accessing }
AxesMorph >> shouldDrawGrid: aBoolean [ 

	grid drawGrid: aBoolean.
	self changed
]

{ #category : #accessing }
AxesMorph >> title:aString [

	title contents: aString
]

{ #category : #drawing }
AxesMorph >> updateCotas [
	
	| cotaColor |
	xmax isNil
		ifTrue: [^ self].
	""
	cotaColor := self cotaColor.
	title color: cotaColor.
	xmax color: cotaColor.
	xmid color: cotaColor.
	xmin color: cotaColor.
	ymax color: cotaColor.
	ymid color: cotaColor.
	ymin color: cotaColor.
	""
	xmax
		contents: (xAxisFormatter value: self maxPoint x).
	xmid
		contents: (xAxisFormatter value: self maxPoint x + self minPoint x / 2).
	xmin
		contents: (xAxisFormatter value: self minPoint x).
	ymax
		contents: (yAxisFormatter value: self maxPoint y).
	ymid
		contents: (yAxisFormatter value: self maxPoint y + self minPoint y / 2).
	ymin
		contents: (yAxisFormatter value: self minPoint y).
	""
	title position: self topLeft + ((self width - title width / 2) rounded @ 0) + (0 @ self borderWidth).
	""
	xmax position: self topLeft + (self width - xmax width @ (self height - xmax height)) - (margin @ self borderWidth).
	xmid position: self topLeft + ((self width - xmid width / 2) rounded @ (self height - xmid height)) - (0 @ self borderWidth).
	xmin position: self topLeft + (0 @ (self height - xmin height)) + (margin @ 0) - (0 @ self borderWidth).
	""
	ymax position: self topLeft + ((0 - ymax width max: 0)
				@ 0) + (self borderWidth @ margin).
	ymid position: self topLeft + ((15 - ymid width max: 0)
				@ (self height - ymid height / 2) rounded) + (self borderWidth @ 0).
	ymin position: self topLeft + ((0 - ymin width max: 0)
				@ (self height - ymin height)) - (0 @ margin) + (self borderWidth @ 0)
]

{ #category : #drawing }
AxesMorph >> updateForm [

	self updateCotas.
	grid drawOn: form getCanvas.
]

{ #category : #utility }
AxesMorph >> worldPointToDataPoint: aPoint [
	"Compute the pixel coordinates of the given data point wrt the World origin."

	^ self gridPointToDataPoint: aPoint - self gridOrigin
	
]

{ #category : #accessing }
AxesMorph >> xAxisFormatter: aFormatterBlock [ 

	xAxisFormatter := aFormatterBlock.
	self updateCotas
]

{ #category : #accessing }
AxesMorph >> yAxisFormatter: aFormatterBlock [ 

	yAxisFormatter := aFormatterBlock.
	self updateCotas
]
