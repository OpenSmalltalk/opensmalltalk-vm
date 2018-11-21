Class {
	#name : #VMProfileGraphLabelMorph,
	#superclass : #Morph,
	#instVars : [
		'positionedLabels',
		'font',
		'getLabelsSelector',
		'model'
	],
	#category : #'CogTools-VMProfiler'
}

{ #category : #LICENSE }
VMProfileGraphLabelMorph class >> LICENSE [
	^'Project Squeak

	Copyright (c) 2005-2013, 3D Immersive Collaboration Consulting, LLC., All Rights Reserved

	Redistributions in source code form must reproduce the above copyright and this condition.

Licensed under MIT License (MIT)
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.'
]

{ #category : #'instance creation' }
VMProfileGraphLabelMorph class >> model: anObject font: aFont getLabels: aSelector [

	^self new
		model: anObject;
		font: aFont;
		getLabelsSelector: aSelector;
		yourself
]

{ #category : #updating }
VMProfileGraphLabelMorph >> changed [
	positionedLabels := model perform: getLabelsSelector.
	super changed
]

{ #category : #drawing }
VMProfileGraphLabelMorph >> drawClippedOn: clippedCanvas [
	"Display the labels at their relative positions sloping down at 45 degrees.
	 Draw a label every font height pixels along to avoid a mess when there are lots of labels."
	| labelForm lfc rotatedLabelForm rlfc warp degSin degCos side rect pts minDelta lastX margin range rotationOffset xs |
	labelForm := Form extent: self height * 2 @ font height depth: 4.
	rotatedLabelForm := Form extent: self height asPoint depth: 4.
	lfc := labelForm getCanvas.
	rlfc := rotatedLabelForm getCanvas.
	warp := (WarpBlt current toForm: rotatedLabelForm)
		sourceForm: labelForm;
		colorMap: (labelForm colormapIfNeededFor: rotatedLabelForm);
		cellSize: 2 "smooothing";  "installs a new colormap if cellSize > 1"
		combinationRule: Form paint.
	degSin := 45 degreeSin.
	degCos := 45 degreeCos.
	"See Form>>rotateBy:magnify:smoothing:"
	side := labelForm extent r.
	rect := (0@0 extent: side@side) align: (side / 2) asPoint with: labelForm extent / 2.
	pts := rect innerCorners collect:
			[:pt | | p |
			p := pt - rect center.
			((labelForm width / 2.0) + (p x asFloat*degCos) + (p y asFloat*degSin)) @
			((labelForm height / 2.0) - (p x asFloat*degSin) + (p y asFloat*degCos))].
	minDelta := font height / 1.5.
	lastX := font height negated.
	margin := model graphMargin.
	range := self width - margin - margin.
	rotationOffset := (labelForm height / 2 * 2 sqrt) ceiling.
	(xs := positionedLabels keys asSortedCollection) withIndexDo:
		[:fractionalX :index| | x |
		x := (fractionalX * range) rounded.
		(lastX + minDelta <= x
		or: [index < xs size
			and: [lastX + minDelta + minDelta <= ((xs at: index + 1) * range)]]) ifTrue:
			[lfc
				fillColor: Color black;
				drawString: (positionedLabels at: fractionalX) at: 0@0 font: font color: Color white.
			rlfc
				fillColor: Color black.
			warp copyQuad: pts toRect: rotatedLabelForm boundingBox.
			clippedCanvas
				image: rotatedLabelForm
				at: self bounds origin + ((fractionalX * range max: lastX + minDelta) floor + margin - rotationOffset@0)
				sourceRect: rotatedLabelForm boundingBox
				rule: Form erase.
			true ifTrue:
				[| box |
				 box := (self bounds origin + ((fractionalX * range) floor + margin@0)) extent: 1@6.
				 Display fill: box rule: Form over fillColor: Color gray].
			lastX := x]]
]

{ #category : #drawing }
VMProfileGraphLabelMorph >> drawOn: aCanvas [
	super drawOn: aCanvas.
	aCanvas
		clipBy: self bounds
		during:
			[:clippedCanvas|
			self drawClippedOn: clippedCanvas]
]

{ #category : #accessing }
VMProfileGraphLabelMorph >> font [
	"Answer the value of font"

	^ font
]

{ #category : #accessing }
VMProfileGraphLabelMorph >> font: anObject [
	"Set the value of font"

	font := anObject
]

{ #category : #accessing }
VMProfileGraphLabelMorph >> getLabelsSelector [
	"Answer the value of getLabelsSelector"

	^ getLabelsSelector
]

{ #category : #accessing }
VMProfileGraphLabelMorph >> getLabelsSelector: anObject [
	"Set the value of getLabelsSelector"

	getLabelsSelector := anObject
]

{ #category : #initialization }
VMProfileGraphLabelMorph >> initialize [
	super initialize.
	color := Color lightBlue lighter lighter.
	positionedLabels := Dictionary new.
	font := TextStyle default defaultFont.
	getLabelsSelector := #positionedLabels
]

{ #category : #accessing }
VMProfileGraphLabelMorph >> model [
	"Answer the value of model"

	^ model
]

{ #category : #accessing }
VMProfileGraphLabelMorph >> model: anObject [
	"Set my model and make me me a dependent of the given object."

	model ifNotNil: [model removeDependent: self].
	anObject ifNotNil: [anObject addDependent: self].
	model := anObject
]

{ #category : #updating }
VMProfileGraphLabelMorph >> update: aParameter [
	aParameter == getLabelsSelector ifTrue:
		[self changed]
]
