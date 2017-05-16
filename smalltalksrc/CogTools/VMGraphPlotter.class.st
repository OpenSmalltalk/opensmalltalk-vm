"
A VMGraphPlotter manages the details of adding points to the histogram and integral graphs in VMProfiler>>plotSamplesFrom:to:intoHistogram:andIntegral:
"
Class {
	#name : #VMGraphPlotter,
	#superclass : #Object,
	#instVars : [
		'histogramSeries',
		'integralSeries',
		'startAddress',
		'integral',
		'plotAsBars'
	],
	#category : #'CogTools-VMProfiler'
}

{ #category : #plotting }
VMGraphPlotter >> addPlotFor: sum at: address [
	sum = 0 ifTrue:
		[(histogramSeries points notEmpty
		  and: [histogramSeries points last y > 0]) ifTrue:
			[plotAsBars ifTrue:
				[histogramSeries addPoint: address @ histogramSeries points last y].
			 histogramSeries addPoint: address @ 0].
		 ^self].

	histogramSeries points isEmpty
		ifTrue:
			[histogramSeries addPoint: startAddress @ 0.
			 address > startAddress ifTrue:
				[histogramSeries addPoint: address @ 0]]
		ifFalse:
			[histogramSeries points last y = 0 ifTrue:
				[histogramSeries addPoint: address @ 0]].
	plotAsBars ifTrue:
		[histogramSeries addPoint: address @ histogramSeries points last y].
	histogramSeries addPoint: address @ sum.

	integralSeries points isEmpty ifTrue:
		[integralSeries addPoint: startAddress @ 0.
		 address > startAddress ifTrue:
			[integralSeries addPoint: address @ 0]].
		 
	integral := integral + sum.
	integralSeries addPoint: address @ integral
]

{ #category : #'initialize-release' }
VMGraphPlotter >> histogram: histogramPlotSeries integral: integralPlotSeries startAddress: start [
	histogramSeries := histogramPlotSeries.
	integralSeries := integralPlotSeries.
	startAddress := start.
	integral := 0.
	plotAsBars := false
]

{ #category : #accessing }
VMGraphPlotter >> plotAsBars [
	^plotAsBars
]

{ #category : #accessing }
VMGraphPlotter >> plotAsBars: aBoolean [
	plotAsBars := aBoolean
]
