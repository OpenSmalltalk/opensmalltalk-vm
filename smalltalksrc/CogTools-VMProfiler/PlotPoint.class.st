"
PlotPoint is a point that have more data used to draw in a PlotMorph
"
Class {
	#name : #PlotPoint,
	#superclass : #Point,
	#instVars : [
		'series',
		'scaledPoint',
		'extra'
	],
	#category : #'CogTools-VMProfiler'
}

{ #category : #'instance creation' }
PlotPoint class >> at: aPoint serie: aPlotSerie [ 
	^ self new initializeAt: aPoint series: aPlotSerie
]

{ #category : #'instance creation' }
PlotPoint class >> at: aPoint serie: aPlotSerie extra: anObject [ 
	^ self new
		initializeAt: aPoint
		serie: aPlotSerie
		extra: anObject
]

{ #category : #'instance creation' }
PlotPoint class >> at: aPoint series: aPlotSeries [
	^ self new initializeAt: aPoint series: aPlotSeries
]

{ #category : #'instance creation' }
PlotPoint class >> at: aPoint series: aPlotSeries extra: anObject [ 
	^ self new
		initializeAt: aPoint
		series: aPlotSeries
		extra: anObject
]

{ #category : #'instance creation' }
PlotPoint class >> new [
^super new initialize
]

{ #category : #comparing }
PlotPoint >> = anObject [ 
	^ super = anObject
		and: [series = anObject series
				and: [extra = anObject extra]]
]

{ #category : #accessing }
PlotPoint >> extra [
	^extra
]

{ #category : #comparing }
PlotPoint >> hash [
	^ super hash
		bitXor: (series hash bitXor: extra hash)
]

{ #category : #initialization }
PlotPoint >> initialize [
scaledPoint := self
]

{ #category : #initialization }
PlotPoint >> initializeAt: aPoint series: aPlotSeries [ 
	self setX: aPoint x setY: aPoint y.
	series := aPlotSeries
]

{ #category : #initialization }
PlotPoint >> initializeAt: aPoint series: aPlotSeries extra: anObject [ 
	self setX: aPoint x setY: aPoint y.
	series := aPlotSeries.
	extra := anObject
]

{ #category : #printing }
PlotPoint >> printOn: aStream [ 
	super printOn: aStream.
	aStream nextPutAll: ' series:(';
		 print: series;
		 nextPutAll: ') scaled:';
		 print: scaledPoint.
	extra isNil
		ifFalse: [aStream nextPutAll: ' extra:';
				 print: extra]
]

{ #category : #accessing }
PlotPoint >> scaledPoint [
	^ scaledPoint ifNil:[self]
]

{ #category : #accessing }
PlotPoint >> scaledPoint: anObject [
	scaledPoint := anObject
]

{ #category : #accessing }
PlotPoint >> series [
	^ series
]
