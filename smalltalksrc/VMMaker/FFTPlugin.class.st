"
FFTPlugin is an example  of how plugins are written. It shows the use of FloatArray for heavy numerical stuff as well as the simulation of plugins from Squeak.

See also:
		FFT pluginTransformData:

"
Class {
	#name : #FFTPlugin,
	#superclass : #InterpreterPlugin,
	#instVars : [
		'nu',
		'fftSize',
		'sinTable',
		'sinTableSize',
		'permTable',
		'permTableSize',
		'realData',
		'realDataSize',
		'imagData',
		'imagDataSize'
	],
	#category : 'VMMaker-Plugins'
}

{ #category : #'translation to C' }
FFTPlugin class >> declareCVarsIn: cg [
	cg var: #sinTable type: #'float*'.
	cg var: #realData type:  #'float*'.
	cg var: #imagData type: #'float*'.
	cg var: #permTable type: #'unsigned int*'
]

{ #category : #private }
FFTPlugin >> checkedFloatPtrOf: oop [
	"Return the first indexable word of oop which is assumed to be variableWordSubclass"
	self returnTypeC:'float *'.
	interpreterProxy success: (interpreterProxy isWords: oop).
	interpreterProxy failed ifTrue:[^0].
	^self cCoerce: (interpreterProxy firstIndexableField: oop) to:'float *'
]

{ #category : #private }
FFTPlugin >> checkedWordPtrOf: oop [
	"Return the first indexable word of oop which is assumed to be variableWordSubclass"
	self returnTypeC:'unsigned int *'.
	interpreterProxy success: (interpreterProxy isWords: oop).
	^self cCoerce: (interpreterProxy firstIndexableField: oop) to: 'unsigned int *'
]

{ #category : #private }
FFTPlugin >> loadFFTFrom: fftOop [
	| oop |
	interpreterProxy success: (interpreterProxy slotSizeOf: fftOop) >= 6.
	interpreterProxy failed ifTrue:[^false].
	nu _ interpreterProxy fetchInteger: 0 ofObject: fftOop.
	fftSize _ interpreterProxy fetchInteger: 1 ofObject: fftOop.

	oop _ interpreterProxy fetchPointer: 2 ofObject: fftOop.
	sinTableSize _ interpreterProxy stSizeOf: oop.
	sinTable _ self checkedFloatPtrOf: oop.

	oop _ interpreterProxy fetchPointer: 3 ofObject: fftOop.
	permTableSize _ interpreterProxy stSizeOf: oop.
	permTable _ self checkedWordPtrOf: oop.

	oop _ interpreterProxy fetchPointer: 4 ofObject: fftOop.
	realDataSize _ interpreterProxy stSizeOf: oop.
	realData _ self checkedFloatPtrOf: oop.

	oop _ interpreterProxy fetchPointer: 5 ofObject: fftOop.
	imagDataSize _ interpreterProxy stSizeOf: oop.
	imagData _ self checkedFloatPtrOf: oop.

	"Check assumptions about sizes"
	interpreterProxy success:
		(1 << nu = fftSize) & 
		(fftSize // 4 + 1 = sinTableSize) & 
		(fftSize = realDataSize) & 
		(fftSize = imagDataSize) &
		(realDataSize = imagDataSize).

	^interpreterProxy failed == false
]

{ #category : #transforming }
FFTPlugin >> permuteData [
	| i end a b tmp |
	self var: #tmp declareC: 'float tmp'.
	i _ 0.
	end _ permTableSize.
	[i < end] whileTrue:
		[a _ (permTable at: i) - 1.
		b _ (permTable at: i+1) - 1.

		(a < realDataSize and:[b < realDataSize]) ifFalse:[^interpreterProxy success: false].

		tmp _ realData at: a.
		realData at: a put: (realData at: b).
		realData at: b put: tmp.

		tmp _ imagData at: a.
		imagData at: a put: (imagData at: b).
		imagData at: b put: tmp.

		i _ i + 2]
]

{ #category : #primitives }
FFTPlugin >> primitiveFFTPermuteData [
	| rcvr |
	self export: true.
	rcvr _ interpreterProxy stackObjectValue: 0.
	(self loadFFTFrom: rcvr) ifFalse:[^nil].
	self permuteData.
	interpreterProxy failed ifTrue:[
		"permuteData went wrong. Do the permutation again -- this will restore the original order"
		self permuteData].
]

{ #category : #primitives }
FFTPlugin >> primitiveFFTScaleData [
	| rcvr |
	self export: true.
	rcvr _ interpreterProxy stackObjectValue: 0.
	(self loadFFTFrom: rcvr) ifFalse:[^nil].
	self scaleData.
]

{ #category : #primitives }
FFTPlugin >> primitiveFFTTransformData [
	| rcvr forward |
	self export: true.
	forward _ interpreterProxy booleanValueOf: (interpreterProxy stackValue: 0).
	rcvr _ interpreterProxy stackObjectValue: 1.
	(self loadFFTFrom: rcvr) ifFalse:[^nil].
	self transformData: forward.
	interpreterProxy failed ifFalse:[
		interpreterProxy pop: 1. "Leave rcvr on stack"
	].
]

{ #category : #transforming }
FFTPlugin >> scaleData [
	"Scale all elements by 1/n when doing inverse"
	| realN |
	self var: #realN declareC: 'float realN'.
	fftSize <= 1 ifTrue:[^nil].
	realN _ self cCoerce: (1.0 / (self cCoerce: fftSize to: 'double')) to: 'float'.
	0 to: fftSize-1 do:
		[:i |
		realData at: i put: (realData at: i) * realN.
		imagData at: i put: (imagData at: i) * realN]
]

{ #category : #transforming }
FFTPlugin >> transformData: forward [
	self permuteData.
	interpreterProxy failed ifTrue:[
		"permuteData went wrong. Do the permutation again -- this will restore the original order"
		self permuteData.
		^nil].
	self transformForward: forward.
	forward ifFalse: [self scaleData]  "Reverse transform must scale to be an inverse"
]

{ #category : #transforming }
FFTPlugin >> transformForward: forward [
	| lev lev1 ip theta realU imagU realT imagT i fftSize2 fftSize4 fftScale ii |
	self var: #realU declareC:'float realU'.
	self var: #realT declareC:'float realT'.
	self var: #imagU declareC:'float imagU'.
	self var: #imagT declareC:'float imagT'.
	fftSize2 _ fftSize // 2.
	fftSize4 _ fftSize // 4.
	1 to: nu do:
		[:level |
		lev _ 1 bitShift: level.
		lev1 _ lev // 2.
		fftScale _ fftSize // lev.
		1 to: lev1 do:
			[:j |
			theta _ j-1 * fftScale.   "pi * (j-1) / lev1 mapped onto 0..n/2"
			theta < fftSize4  "Compute U, the complex multiplier for each level"
				ifTrue:
					[realU _ sinTable at: sinTableSize - theta - 1.
					imagU _ sinTable at: theta]
				ifFalse:
					[realU _ 0.0 - (sinTable at: theta - fftSize4).
					imagU _ sinTable at: fftSize2 - theta].
			forward ifFalse: [imagU _ 0.0 - imagU].
"
			Here is the inner loop...
			j to: n by: lev do:
				[:i |   hand-transformed to whileTrue...
"
			i _ j.
			[i <= fftSize] whileTrue:
				[ip _ i + lev1 - 1.
				ii _ i-1.
				realT _ ((realData at: ip) * realU) - ((imagData at: ip) * imagU).
				imagT _ ((realData at: ip) * imagU) + ((imagData at: ip) * realU).
				realData at: ip put: (realData at: ii) - realT.
				imagData at: ip put: (imagData at: ii) - imagT.
				realData at: ii put: (realData at: ii) + realT.
				imagData at: ii put: (imagData at: ii) + imagT.
				i _ i + lev]]].
]
