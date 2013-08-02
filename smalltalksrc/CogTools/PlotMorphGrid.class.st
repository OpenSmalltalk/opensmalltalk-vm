"
I'm the grid of a PlotMorph
"
Class {
	#name : #PlotMorphGrid,
	#superclass : #Object,
	#instVars : [
		'plot',
		'drawAxis',
		'drawGrid'
	],
	#category : #'CogTools-VMProfiler'
}

{ #category : #'instance creation' }
PlotMorphGrid class >> new [
	^ super new initialize
]

{ #category : #'instance creation' }
PlotMorphGrid class >> on: aPlotMorph [
	^ self new initializeOn: aPlotMorph
]

{ #category : #drawing }
PlotMorphGrid >> bestStep: aNumber [ 
	"answer the best step for grid drawing"
	| bestStep |
	bestStep := aNumber.
	2
		to: 40
		by: 2
		do: [:i | 
			| step | 
			step := aNumber / i.
			(step between: 25 and: 100)
				ifTrue: [bestStep := step]].
	^ bestStep
]

{ #category : #accessing }
PlotMorphGrid >> drawAxis: aBoolean [ 
	drawAxis := aBoolean
]

{ #category : #drawing }
PlotMorphGrid >> drawAxisOn: aCanvas [ 
	| axisColor yTo lighter darker baseColor bounds xTo |
	baseColor := plot baseColor alpha: 1.
	lighter := baseColor twiceLighter twiceLighter twiceLighter.
	darker := baseColor twiceDarker twiceDarker twiceDarker.
	axisColor := (lighter diff: baseColor)
					> (darker diff: baseColor)
				ifTrue: [lighter]
				ifFalse: [darker].
	""
	bounds := plot drawBounds.
	"Y axe"
	yTo := bounds topLeft - (0 @ 7).
	aCanvas
		line: bounds bottomLeft + (0 @ 5)
		to: yTo
		color: axisColor.
	aCanvas
		line: yTo
		to: yTo + (4 @ 4)
		color: axisColor.
	aCanvas
		line: yTo
		to: yTo + (-4 @ 4)
		color: axisColor.
	"X axe"
	xTo := bounds bottomRight + (7 @ 0).
	aCanvas
		line: bounds bottomLeft - (5 @ 0)
		to: xTo
		color: axisColor.
	aCanvas
		line: xTo
		to: xTo + (-4 @ -4)
		color: axisColor.
	aCanvas
		line: xTo
		to: xTo + (-4 @ 4)
		color: axisColor
]

{ #category : #accessing }
PlotMorphGrid >> drawGrid: aBoolean [ 
	drawGrid := aBoolean
]

{ #category : #drawing }
PlotMorphGrid >> drawGridOn: aCanvas [ 
	| gridColor lighter darker baseColor bounds |
	baseColor := plot baseColor alpha: 1.
	lighter := baseColor twiceLighter.
	darker := baseColor twiceDarker.
	gridColor := (lighter diff: baseColor)
					> (darker diff: baseColor)
				ifTrue: [lighter]
				ifFalse: [darker].
	bounds := plot drawBounds.
	(bounds left
		to: bounds right
		by: (self bestStep: bounds width))
		do: [:x | | xRounded |
			xRounded := x rounded.
			aCanvas
				line: xRounded @ bounds top
				to: xRounded @ bounds bottom
				color: gridColor].
	(bounds top
		to: bounds bottom
		by: (self bestStep: bounds height))
		do: [:y | | yRounded |
			yRounded := y rounded.
			aCanvas
				line: bounds left @ yRounded
				to: bounds right @ yRounded
				color: gridColor]
]

{ #category : #drawing }
PlotMorphGrid >> drawOn: aCanvas [ 
	drawGrid
		ifTrue: [self drawGridOn: aCanvas].
	drawAxis
		ifTrue: [self drawAxisOn: aCanvas]
]

{ #category : #initialization }
PlotMorphGrid >> initialize [
	drawAxis := true.
	drawGrid := true
]

{ #category : #initialization }
PlotMorphGrid >> initializeOn: aPlotMorph [
plot := aPlotMorph
]
