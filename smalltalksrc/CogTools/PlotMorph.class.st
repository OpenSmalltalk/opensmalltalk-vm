"
I can draw many series of Points in a XY grid.  See the methods testXXX in the class side.

Samples:

   PlotMorph test.
   PlotMorph test2.
   PlotMorph test4.
   PlotMorph testWithReferences.

"
Class {
	#name : #PlotMorph,
	#superclass : #AxesMorph,
	#instVars : [
		'series',
		'cachedMaxPoint',
		'cachedMinPoint',
		'lens',
		'scaledPoints',
		'references',
		'processMouseDown',
		'balloonFormatter'
	],
	#category : #'CogTools-VMProfiler'
}

{ #category : #'instance creation' }
PlotMorph class >> plotPoints: aPointOrderedCollection [ 
	| plotMorph |
	plotMorph := PlotMorph new.
	plotMorph color: Color black twiceLighter twiceLighter;
		 title: 'Colors';
		 extent: 700 @ 300;
		 useRoundedCorners;
		 borderRaised.
	plotMorph series: #series color: Color white;
		 series: #series drawLine: false.
	aPointOrderedCollection
		do: [:e | ""
			plotMorph series: #series addPoint: e].
	plotMorph openInWorld.
	^ plotMorph
]

{ #category : #'instance creation' }
PlotMorph class >> plotSeries: aPointOrderedCollection [ 
	| plotMorph |
	plotMorph := PlotMorph new.
	plotMorph color: Color gray lighter;
		 title: 'Colors';
		 extent: 700 @ 300;
		 useRoundedCorners;
		 borderRaised.
	plotMorph series: #series color: Color red;
		 series: #series drawLine: false.
	aPointOrderedCollection
		do: [:e | ""
			plotMorph series: #series addPoint: e].
	plotMorph openInWorld.
	^ plotMorph
]

{ #category : #testing }
PlotMorph class >> test [
	" 
	PlotMorph test  
	"
	| pm |
	pm := PlotMorph new.
	pm
		color: (Color
				r: 0.0
				g: 0.376
				b: 0.317);
		 extent: 320 @ 320;
		 borderWidth: 2;
		 useRoundedCorners;
		 setBorderStyle: #raised;
		 title: 'Some test functions'.
	pm series: #sin color: Color red;
		 series: #cos color: Color blue;
		 series: #test color: Color yellow.
	pm series: #sin drawArea: true;
		 series: #cos drawArea: true;
		 series: #test drawArea: true.
	pm series: #sin description: 'sin';
		 series: #cos description: 'cosin';
		 series: #test description: 'test'.
	pm series: #test type: #stepped.
	pm series: #sin width: 2;
		 series: #sin drawLine: false.
	""
	pm
		yAxisFormatter: [:y | (y roundTo: 0.1) asString].
	""
	0
		to: 360
		by: 10
		do: [:x | 
			pm series: #sin addPoint: x @ x degreesToRadians sin.
			pm series: #cos addPoint: x @ x degreesToRadians cos.
			pm series: #test addPoint: x @ (x degreesToRadians cos + x degreesToRadians sin)].
	""
	pm openInWorld
]

{ #category : #testing }
PlotMorph class >> test2 [
	" 
	PlotMorph test2  
	"
	| pm sigmoid |
	pm := PlotMorph new.
	pm title: 'Sigmoid';
		 extent: 250 @ 250;
		 color: Color black.
	""
	pm series: #sigmoid1 color: Color red;
		 series: #sigmoid1 drawPoints: false;
		 series: #sigmoid2 color: Color blue;
		 series: #sigmoid2 drawPoints: false;
		 series: #sigmoid3 color: Color yellow;
		 series: #sigmoid3 drawPoints: false;
		 series: #sigmoid4 color: Color green;
		 series: #sigmoid4 drawPoints: false;
		 series: #sigmoid5 color: Color white;
		 series: #sigmoid5 drawPoints: false.
	""
	pm
		yAxisFormatter: [:y | (y roundTo: 0.1) asString].
	sigmoid := [:x :slope | 1 / (1 + (slope * x) negated exp)].
	-10
		to: 10
		by: 0.25
		do: [:x | 
			pm series: #sigmoid1 addPoint: x
					@ (sigmoid value: x value: 3).
			pm series: #sigmoid2 addPoint: x
					@ (sigmoid value: x value: 2).
			pm series: #sigmoid3 addPoint: x
					@ (sigmoid value: x value: 1).
			pm series: #sigmoid4 addPoint: x
					@ (sigmoid value: x value: 1 / 2).
			pm series: #sigmoid5 addPoint: x
					@ (sigmoid value: x value: 1 / 3)].
	pm openInWorld
]

{ #category : #testing }
PlotMorph class >> test4 [
	" 
	PlotMorph test4
	"
	| pm function |
	pm := PlotMorph new.
	pm
		color: (Color blue twiceDarker twiceDarker twiceDarker alpha: 0.3);
		 extent: 300 @ 300;
		 useRoundedCorners.
	pm
		xAxisFormatter: [:x | x rounded asStringWithCommas].
	pm
		yAxisFormatter: [:y | y rounded asString].
	pm title: 'Some funny function'.
	pm series: #test2 color: Color red;
		 series: #test2 drawPoints: false.
	function := [:x | x degreesToRadians sin / 5 + ((x / 10) degreesToRadians cos + (x / 10) degreesToRadians sin) * 100].
	0
		to: 3000
		by: 5
		do: [:x | pm series: #test2 addPoint: x
					@ (function value: x)].
	pm openInWorld
]

{ #category : #testing }
PlotMorph class >> testWithReferences [
	" 
	PlotMorph testWithReferences.
	"
	| pm ref |
	ref := AlignmentMorph newColumn.
	ref color: Color magenta twiceDarker twiceDarker;
		 hResizing: #shrinkWrap;
		 vResizing: #shrinkWrap;
		 wrapCentering: #center;
		 cellPositioning: #leftCenter.
	""
	pm := PlotMorph new.
	pm references: ref.
	pm color: Color magenta twiceDarker twiceDarker;
		 extent: 300 @ 300;
		 borderWidth: 0;
		 title: 'Some test functions'.
	pm series: #sin color: Color red;
		 series: #cos color: Color blue;
		 series: #test color: Color yellow.
	pm series: #sin drawArea: true;
		 series: #cos drawArea: true;
		 series: #test drawArea: true.
	pm series: #sin description: 'sin';
		 series: #cos description: 'cosin';
		 series: #test description: 'test'.
	pm series: #test type: #stepped.
	0
		to: 360
		by: 10
		do: [:x | 
			pm series: #sin addPoint: x @ x degreesToRadians sin.
			pm series: #cos addPoint: x @ x degreesToRadians cos.
			pm series: #test addPoint: x @ (x degreesToRadians cos + x degreesToRadians sin)].
	""
	ref openInWorld.
	pm openInWorld
]

{ #category : #accessing }
PlotMorph >> balloonFormatter: anObject [
	balloonFormatter := anObject
]

{ #category : #'change reporting' }
PlotMorph >> changed [
	
	cachedMaxPoint := nil.
	cachedMinPoint := nil.
	super changed
]

{ #category : #accessing }
PlotMorph >> clear [
	series do:[:each | each clear].
	self seriesChanged
]

{ #category : #private }
PlotMorph >> exploreExtrasAt: nearPoint [ 
	| extras |
	extras := (self scaledPoints at: nearPoint)
				collect: [:each | each extra].
	extras := extras
				select: [:each | each notNil].

extras isEmpty ifFalse:[
	extras explore]
]

{ #category : #private }
PlotMorph >> findNearestPointTo: targetPoint [ 
	| nearestPoint |
	nearestPoint := nil.
	Cursor wait
				showWhile: [""
					self scaledPoints
						keysDo: [:scaledPoint | ""
							(nearestPoint isNil
									or: [(targetPoint dist: scaledPoint)
											< (targetPoint dist: nearestPoint)])
								ifTrue: [nearestPoint := scaledPoint]]].
	^ nearestPoint
]

{ #category : #'event handling' }
PlotMorph >> handlesMouseDown: evt [ 
	^ processMouseDown
]

{ #category : #initialization }
PlotMorph >> initialize [
	super initialize.

	series := Dictionary new.
	processMouseDown := true.
	lens := nil.
	balloonFormatter := [:aCollection | self textForBalloon: aCollection].
	self extent: 1 @ 1
]

{ #category : #initialization }
PlotMorph >> initializeCotas [
	"Don't put initial limits on the grid range... default is to compute them from series data."

	super initializeCotas.
	limitMinX := limitMaxX := limitMinY := limitMaxY := nil.
]

{ #category : #drawing }
PlotMorph >> maxPoint [
	cachedMaxPoint
		ifNil: [""
			limitMaxX notNil & limitMaxY notNil
				ifTrue: [cachedMaxPoint := limitMaxY @ limitMaxY]
				ifFalse: [| maxPoints | 
					maxPoints := series
								collect: [:serie | serie maxPoint]
								thenSelect: [:point | point notNil].
					cachedMaxPoint := maxPoints isEmpty
								ifTrue: [1 @ 1]
								ifFalse: [maxPoints max].
					limitMaxX notNil
						ifTrue: [cachedMaxPoint := limitMaxX @ cachedMaxPoint y].
					limitMaxY notNil
						ifTrue: [cachedMaxPoint := cachedMaxPoint x @ limitMaxY]]].
	^ cachedMaxPoint
]

{ #category : #drawing }
PlotMorph >> minPoint [
	cachedMinPoint
		ifNil: [""
			limitMinX notNil & limitMinY notNil
				ifTrue: [cachedMinPoint := limitMinX @ limitMinY]
				ifFalse: [| minPoints | 
					minPoints := series
								collect: [:serie | serie minPoint]
								thenSelect: [:point | point notNil].
					cachedMinPoint := minPoints isEmpty
								ifTrue: [0 @ 0]
								ifFalse: [minPoints min].
					limitMinX notNil
						ifTrue: [cachedMinPoint :=  limitMinX
										@ cachedMinPoint y].
					limitMinY notNil
						ifTrue: [cachedMinPoint := cachedMinPoint x
										@ limitMinY]]].
	^ cachedMinPoint
]

{ #category : #'event handling' }
PlotMorph >> mouseDown: anEvent [ 
	| nearPoint |
	nearPoint := self findNearestPointTo: anEvent position - self topLeft - self borderWidth.
	nearPoint
		ifNotNil: [anEvent redButtonChanged
				ifTrue: [self showLensAt: nearPoint]
				ifFalse: [self exploreExtrasAt: nearPoint]]
]

{ #category : #'event handling' }
PlotMorph >> mouseUp: anEvent [ 
	lens isNil ifTrue:[^ self].
""

			lens deleteBalloon.
			lens delete.
			lens := nil
]

{ #category : #accessing }
PlotMorph >> processMouseDown: aBoolean [ 
	processMouseDown := aBoolean
]

{ #category : #accessing }
PlotMorph >> references: aMorphOrNil [
	"Specifies a morph (if not nil) that is updated with the names of the plotted series, displayed in the same color as the actual plot."

	references := aMorphOrNil
]

{ #category : #drawing }
PlotMorph >> scalePoints [
	| |
	scaledPoints := nil.
	series
		do: [:serie | serie
				scaleTo: self drawBounds
				height: self height - (self borderWidth * 2)
				maxPoint: self maxPoint
				minPoint: self minPoint]
]

{ #category : #drawing }
PlotMorph >> scaledPoints [
	^ scaledPoints
		ifNil: [scaledPoints := Dictionary new.
			series
				do: [:serie | serie points
						do: [:point | 
							| allPoints | 
							allPoints := scaledPoints
										at: point scaledPoint
										ifAbsentPut: [OrderedCollection new].
							allPoints add: point]].
			scaledPoints]
]

{ #category : #accessing }
PlotMorph >> series [
	^series
]

{ #category : #series }
PlotMorph >> series: aSeriesOrSymbol [ 
	"If aSeriesOrSymbol is a PlotSeries, simply answer it.  Otherwise, it should be a string, and the returned value is the series with that name."

	^ aSeriesOrSymbol isString
		ifTrue: [| symbol | 
			symbol := aSeriesOrSymbol asSymbol.
			series
				at: symbol
				ifAbsentPut: [PlotSeries name: symbol]]
		ifFalse: [aSeriesOrSymbol]
]

{ #category : #series }
PlotMorph >> series: aSymbol addPoint: aPoint [ 
	"Find the appropriate series and set a property in it."

	(self series: aSymbol)
		addPoint: aPoint.
	self changed
]

{ #category : #series }
PlotMorph >> series: aSymbol addPoint: aPoint extra: anObject [ 
	"Find the appropriate series and set a property in it."

	(self series: aSymbol)
		addPoint: aPoint
		extra: anObject.
	self changed 
]

{ #category : #series }
PlotMorph >> series: aSymbol color: aColor [ 
	"Find the appropriate series and set a property in it."

	(self series:aSymbol) color:aColor.
	self changed
]

{ #category : #series }
PlotMorph >> series: aSymbol description: aString [
	"Find the appropriate series and set a property in it."

	(self series: aSymbol)
		description: aString.
	self changed
]

{ #category : #series }
PlotMorph >> series: aSymbol drawArea: aBoolean [ 
	"Find the appropriate series and set a property in it."

	(self series: aSymbol)
		drawArea: aBoolean.
	self changed
]

{ #category : #series }
PlotMorph >> series: aSymbol drawLine: aBoolean [ 
	"Find the appropriate series and set a property in it."

	(self series: aSymbol)
		drawLine: aBoolean.
	self changed
]

{ #category : #series }
PlotMorph >> series: aSymbol drawPoints: aBoolean [ 
	"Find the appropriate series and set a property in it."

	(self series: aSymbol)
		drawPoints: aBoolean.
	self changed
]

{ #category : #series }
PlotMorph >> series: seriesSymbol type: lineTypeSymbol [ 
	"Find the appropriate series and set a property in it."

	(self series: seriesSymbol)
		type: lineTypeSymbol.
	self changed
]

{ #category : #series }
PlotMorph >> series: aSymbol width: anInteger [ 
	"Find the appropriate series and set a property in it."

	(self series: aSymbol) width: anInteger.
	self changed
]

{ #category : #private }
PlotMorph >> seriesChanged [
	cachedMaxPoint := nil.
	cachedMinPoint := nil.
	"If the morphs has no owner, then the morph is not open yet"
	owner isNil 
ifTrue:[^ self].
""			
	self changed.
	self updateCotas
]

{ #category : #private }
PlotMorph >> showLensAt: nearPoint [ 
	lens := EllipseMorph new.
	lens
		color: (Color red alpha: 0.5).
	lens extent: 7 @ 7.
	self addMorph: lens.
	lens position: self topLeft + nearPoint - (3 @ 3) + self borderWidth.
	lens
		showBalloon: (balloonFormatter
				value: (self scaledPoints at: nearPoint))
]

{ #category : #private }
PlotMorph >> textForBalloon: aCollection [ 
	| stream point |
	point := aCollection anyOne.
	stream := String new writeStream.
	stream
		nextPutAll: (xAxisFormatter value: point x);
		 nextPutAll: '  ';
		
		nextPutAll: (yAxisFormatter value: point y);
		 nextPut: Character cr.
	aCollection
		do: [:each | 
			stream nextPutAll: each series name.
			each extra
				ifNotNil: [stream nextPutAll: ': ';
						 print: each extra]]
		separatedBy: [stream nextPut: Character cr].
	^ stream contents
]

{ #category : #drawing }
PlotMorph >> updateForm [
	"Override superclass implementation to do drawing of data."
	| canvas |

	self updateReferences.
	self updateCotas.
	self scalePoints.
	canvas := form getCanvas.
	grid drawOn: canvas.
	(series values
		asSortedCollection: [:x :y | x name <= y name])
		do: [:serie | serie drawOn: canvas].

]

{ #category : #drawing }
PlotMorph >> updateReferences [
	"Update a 'legend' displaying the description of each plotted series in the same color as that series."
	| seriesWithDescription sortedSeried |
	references isNil
		ifTrue: [^ self].
	""
	references removeAllMorphs.
""
	seriesWithDescription := series
				reject: [:each | each description isEmpty].
	sortedSeried := seriesWithDescription
				asSortedCollection: [:x :y | x description asLowercase <= y description asLowercase].
	sortedSeried
		do: [:serie | 
			| ref | 
			ref := StringMorph new.
			ref contents: serie description.
			ref color: serie color.
			references addMorphBack: ref.
			serie]
]
