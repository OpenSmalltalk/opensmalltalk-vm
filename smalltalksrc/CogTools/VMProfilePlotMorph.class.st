Class {
	#name : #VMProfilePlotMorph,
	#superclass : #PlotMorph,
	#instVars : [
		'alternateSeries',
		'selectionStart',
		'selectionStop',
		'oldSelectionRectangle',
		'model',
		'cachedAlternateMaxPoint',
		'cachedAlternateMinPoint',
		'aymax',
		'aymid',
		'aymin'
	],
	#category : #'CogTools-VMProfiler'
}

{ #category : #LICENSE }
VMProfilePlotMorph class >> LICENSE [
	^'Project Squeak

	Copyright (c) 2005-2013, 3D Immersive Collaboration Consulting, LLC., All Rights Reserved

	Redistributions in source code form must reproduce the above copyright and this condition.

Licensed under MIT License (MIT)
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.'
]

{ #category : #'instance creation' }
VMProfilePlotMorph class >> model: aProfiler [
	^self new model: aProfiler; yourself
]

{ #category : #drawing }
VMProfilePlotMorph >> alternateMaxPoint [
	cachedAlternateMaxPoint ifNil:
		[| maxPoints |
		 maxPoints := alternateSeries
						collect: [:serie | serie maxPoint]
						thenSelect: [:point | point notNil].
		 cachedAlternateMaxPoint := maxPoints isEmpty
								ifTrue: [1 @ 1]
								ifFalse: [maxPoints max]].
	^cachedAlternateMaxPoint
]

{ #category : #drawing }
VMProfilePlotMorph >> alternateMinPoint [
	cachedAlternateMinPoint ifNil:
		[| minPoints |
		 minPoints := alternateSeries
						collect: [:serie | serie minPoint]
						thenSelect: [:point | point notNil].
		 cachedAlternateMinPoint := minPoints isEmpty
										ifTrue: [1 @ 1]
										ifFalse: [minPoints min]].
	^cachedAlternateMinPoint
]

{ #category : #series }
VMProfilePlotMorph >> alternateSeries: aSeriesOrSymbol [ 
	"If aSeriesOrSymbol is a PlotSeries, simply answer it.  Otherwise, it should be a string, and the returned value is the series with that name."

	^ aSeriesOrSymbol isString
		ifTrue: [| symbol | 
			symbol := aSeriesOrSymbol asSymbol.
			alternateSeries
				at: symbol
				ifAbsentPut: [PlotSeries name: symbol]]
		ifFalse: [aSeriesOrSymbol]
]

{ #category : #'change reporting' }
VMProfilePlotMorph >> changed [

	cachedAlternateMaxPoint := cachedAlternateMinPoint := nil.
	super changed
]

{ #category : #accessing }
VMProfilePlotMorph >> clear [
	alternateSeries do:[:each | each clear].
	super clear
]

{ #category : #drawing }
VMProfilePlotMorph >> drawOn: aCanvas [
	self selectionRectangle ifNotNil:
		[:selectionRectangle|
		 aCanvas fillRectangle: selectionRectangle color: Color lightBlue].
	super drawOn: aCanvas
]

{ #category : #initialization }
VMProfilePlotMorph >> initialize [
	super initialize.

	alternateSeries := Dictionary new
]

{ #category : #initialization }
VMProfilePlotMorph >> initializeCotas [
	super initializeCotas.
	aymax := StringMorph contents: ''.
	aymid := StringMorph contents: ''.
	aymin := StringMorph contents: ''.
	self addMorph: aymax.
	self addMorph: aymid.
	self addMorph: aymin
]

{ #category : #selection }
VMProfilePlotMorph >> invalidateSelection [
	self selectionRectangle
		ifNil:
			[oldSelectionRectangle ifNotNil:
				[self invalidRect: oldSelectionRectangle.
				 oldSelectionRectangle := nil]]
		ifNotNil:
			[:selectionRectangle|
			 self invalidRect: (oldSelectionRectangle
								ifNil: [selectionRectangle]
								ifNotNil: [oldSelectionRectangle merge: selectionRectangle]).
			 oldSelectionRectangle := selectionRectangle]
]

{ #category : #accessing }
VMProfilePlotMorph >> model [
	^model
]

{ #category : #accessing }
VMProfilePlotMorph >> model: anObject [
	"Set my model and make me me a dependent of the given object."

	model ifNotNil: [model removeDependent: self].
	anObject ifNotNil: [anObject addDependent: self].
	model := anObject
]

{ #category : #'event handling' }
VMProfilePlotMorph >> mouseDown: anEvent [ 
	selectionStart := anEvent position x.
	self invalidateSelection
]

{ #category : #'event handling' }
VMProfilePlotMorph >> mouseMove: anEvent [ 
	selectionStop := anEvent position x.
	self invalidateSelection
]

{ #category : #'event handling' }
VMProfilePlotMorph >> mouseUp: anEvent [
	| selectionRect screenDrawBounds range |
	selectionRect := self selectionRectangle.
	screenDrawBounds := self bounds insetBy: margin.
	range := screenDrawBounds width asFloat.
	selectionStart := selectionStop := nil.
	self invalidateSelection.
	selectionRect ifNotNil:
		[model
			selectProportionFrom: ((selectionRect left - screenDrawBounds left) / range max: 0.0)
			to: ((selectionRect right - screenDrawBounds left) / range min: 1.0)]
]

{ #category : #drawing }
VMProfilePlotMorph >> scalePoints [
	super scalePoints.
	alternateSeries do:
		[:serie |
		 serie
			scaleTo: self drawBounds
			height: self height - (self borderWidth * 2)
			maxPoint: self alternateMaxPoint
			minPoint: self alternateMinPoint]
]

{ #category : #selection }
VMProfilePlotMorph >> selectionRectangle [
	^(selectionStart notNil and: [selectionStop notNil]) ifTrue:
		[| bounds |
		 bounds := self bounds.
		((selectionStart min: selectionStop) max: bounds left)@bounds top
			corner: ((selectionStart max: selectionStop) min: bounds right)@bounds bottom]
]

{ #category : #private }
VMProfilePlotMorph >> seriesChanged [
	cachedAlternateMaxPoint := cachedAlternateMinPoint := nil.
	super seriesChanged
]

{ #category : #drawing }
VMProfilePlotMorph >> updateCotas [
	
	| cotaColor |
	super updateCotas.
	aymax isNil
		ifTrue: [^ self].
	""
	cotaColor := self cotaColor.
	aymax color: cotaColor.
	aymid color: cotaColor.
	aymin color: cotaColor.
	aymax
		contents: (yAxisFormatter value: self alternateMaxPoint y).
	aymid
		contents: (yAxisFormatter value: self alternateMaxPoint y + self alternateMinPoint y / 2).
	aymin
		contents: (yAxisFormatter value: self alternateMinPoint y).
	""
	aymax position: self topRight
					- ((aymax width + self borderWidth) @ 0)
					+ (0@self borderWidth).
	aymid position: self topRight
					- (aymid width + self borderWidth @ 0)
					+ (0 @ (self height - aymid height / 2) rounded).
	aymin position: self topRight
					- (aymin width + self borderWidth @ 0)
					+ (0 @ (self height - aymin height - margin - self borderWidth) rounded).
]

{ #category : #drawing }
VMProfilePlotMorph >> updateForm [
	| canvas |
	super updateForm.
	canvas := form getCanvas.
	(alternateSeries values
		asSortedCollection: [:x :y | x name <= y name])
		do: [:serie | serie drawOn: canvas].

]
