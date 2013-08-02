"
I'm a serie of a PlotMorph
"
Class {
	#name : #PlotSeries,
	#superclass : #Object,
	#instVars : [
		'name',
		'description',
		'color',
		'width',
		'points',
		'drawPoints',
		'drawLine',
		'drawArea',
		'type'
	],
	#category : #'CogTools-VMProfiler'
}

{ #category : #'instance creation' }
PlotSeries class >> name: aString [ 
	^ self new
		initializeName: aString
		
]

{ #category : #points }
PlotSeries >> addPoint: aPoint [ 
	points
		add: (PlotPoint at: aPoint serie: self)
]

{ #category : #points }
PlotSeries >> addPoint: aPoint extra:anObject [
	points
		add: (PlotPoint at: aPoint serie: self extra:anObject)
]

{ #category : #'accessing-color' }
PlotSeries >> areaColor [
	^ color alpha: 0.25
]

{ #category : #accessing }
PlotSeries >> clear [
points := OrderedCollection new
]

{ #category : #accessing }
PlotSeries >> color [
	^color
]

{ #category : #'accessing-color' }
PlotSeries >> color: anObject [
	color := anObject
]

{ #category : #accessing }
PlotSeries >> description [
	^ description ifNil:[name]
]

{ #category : #accessing }
PlotSeries >> description: aString [
	description := aString
]

{ #category : #accessing }
PlotSeries >> drawArea: aBoolean [ 
	drawArea := aBoolean
]

{ #category : #accessing }
PlotSeries >> drawLine: aBoolean [ 
	drawLine := aBoolean
]

{ #category : #drawing }
PlotSeries >> drawOn: aCanvas [ 
	points isEmpty
		ifTrue: [^ self].
""
			drawArea
				ifTrue: [""
					type == #straightened
						ifTrue: [self drawStraightenedAreaOn: aCanvas].
					type == #stepped
						ifTrue: [self drawSteppedAreaOn: aCanvas]].
			drawLine
				ifTrue: [""
					type == #straightened
						ifTrue: [self drawStraightenedLineOn: aCanvas].
					type == #stepped
						ifTrue: [self drawSteppedLineOn: aCanvas]].
			drawPoints
				ifTrue: [self drawPointsOn: aCanvas]
]

{ #category : #accessing }
PlotSeries >> drawPoints: aBoolean [ 
	drawPoints := aBoolean
]

{ #category : #drawing }
PlotSeries >> drawPointsOn: aCanvas [ 
	| pointColor minus plus |
	pointColor := self pointColor.
	minus := width @ width.
	plus := minus * 2.
	points
		do: [:point | 
			| scaledPoint | 
			scaledPoint := point scaledPoint.
			aCanvas
				fillOval: (scaledPoint - minus rect: scaledPoint + plus)
				color: pointColor]
]

{ #category : #drawing }
PlotSeries >> drawSteppedAreaOn: aCanvas [ 
	| areaColor areaPoints lastScaledPoint | 
			areaColor := self areaColor.
			areaPoints := OrderedCollection new.
			lastScaledPoint := nil.
			points
				do: [:each | 
					| scaledPoint | 
					scaledPoint := each scaledPoint.
					lastScaledPoint
						ifNotNil: [areaPoints add: scaledPoint x @ lastScaledPoint y].
					areaPoints add: scaledPoint.
					lastScaledPoint := scaledPoint].
			aCanvas
				drawPolygon: areaPoints
				color: areaColor
				borderWidth: 0
				borderColor: areaColor
]

{ #category : #drawing }
PlotSeries >> drawSteppedLineOn: aCanvas [ 
	| lineColor lastScaledPoint |
	lineColor := self lineColor.
	lastScaledPoint := nil.
	points
		do: [:point | 
			| scaledPoint | 
			scaledPoint := point scaledPoint.
			lastScaledPoint
				ifNotNil: [""aCanvas
						line: lastScaledPoint
						to: scaledPoint x @ lastScaledPoint y
						width: width
						color: lineColor.
					aCanvas
						line: scaledPoint x @ lastScaledPoint y
						to: scaledPoint
						width: width
						color: lineColor].
			lastScaledPoint := scaledPoint]
]

{ #category : #drawing }
PlotSeries >> drawStraightenedAreaOn: aCanvas [ 
	| areaColor | 
			areaColor := self areaColor.
			aCanvas
				drawPolygon: (points
						collect: [:each | each scaledPoint])
				color: areaColor
				borderWidth: 0
				borderColor: areaColor
]

{ #category : #drawing }
PlotSeries >> drawStraightenedLineOn: aCanvas [ 
	| lineColor lastScaledPoint |
	lineColor := self lineColor.
	lastScaledPoint := nil.
	points
		do: [:point | 
			| scaledPoint | 
			scaledPoint := point scaledPoint.
			lastScaledPoint
				ifNotNil: [aCanvas
						line: lastScaledPoint
						to: scaledPoint
						width: width
						color: lineColor].
			lastScaledPoint := scaledPoint]
]

{ #category : #initialization }
PlotSeries >> initializeName: aString [ 
	name := aString.
	""
	color := Color black.

	""
	width := 1.
	drawPoints := true.
	drawLine := true.
	drawArea := false.
	type := #straightened.
	points := OrderedCollection new
]

{ #category : #'accessing-color' }
PlotSeries >> lineColor [
	^ color
		alpha: 0.85
]

{ #category : #points }
PlotSeries >> maxPoint [
	^ points isEmpty
		ifTrue: [nil]
		ifFalse: [points max]
]

{ #category : #points }
PlotSeries >> minPoint [
	^ points isEmpty
		ifTrue: [nil]
		ifFalse: [points min]
]

{ #category : #accessing }
PlotSeries >> name [
	^ name
]

{ #category : #'accessing-color' }
PlotSeries >> pointColor [
	^ color twiceLighter alpha: 0.85
]

{ #category : #accessing }
PlotSeries >> points [
	^points
]

{ #category : #printing }
PlotSeries >> printOn: aStream [ 
	aStream nextPutAll: 'Serie:';
		 nextPutAll: name;
		 nextPutAll: ', color:';
		 nextPutAll: color asString;
		 nextPutAll: ', width:';
		 nextPutAll: width asString;
		 nextPutAll: ', drawPoints:';
		 nextPutAll: drawPoints asString;
		 nextPutAll: ', drawLine:';
		 nextPutAll: drawLine asString;
		 nextPutAll: ', drawArea:';
		 nextPutAll: drawArea asString
]

{ #category : #points }
PlotSeries >> scaleTo: anRectangle height: heightInteger maxPoint: maxPoint minPoint: minPoint [ 
	| drawExtent scaleFrom scaleTo|
	drawExtent := 1 @ 1 max: maxPoint - minPoint.
	drawExtent isZero ifTrue:[^ self].
""

			scaleFrom := 0 @ 0 rect: drawExtent.
			scaleTo := anRectangle.
			points do: 
					[:point | 
					| tempPoint |
					tempPoint := point - minPoint scaleFrom: scaleFrom to: scaleTo.
					point scaledPoint: tempPoint x @ (heightInteger - tempPoint y)]
]

{ #category : #accessing }
PlotSeries >> type: aSymbol [ 
	"Line Type (#straightened, #stepped)"
	type := aSymbol
]

{ #category : #accessing }
PlotSeries >> width: anObject [
	width := anObject
]
