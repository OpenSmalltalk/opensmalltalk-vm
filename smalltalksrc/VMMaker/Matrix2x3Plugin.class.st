Class {
	#name : #Matrix2x3Plugin,
	#superclass : #InterpreterPlugin,
	#instVars : [
		'm23ResultX',
		'm23ResultY',
		'm23ArgX',
		'm23ArgY'
	],
	#category : #'VMMaker-Plugins'
}

{ #category : #'class initialization' }
Matrix2x3Plugin class >> declareCVarsIn: cg [ 
	cg var: #m23ResultX type: #double.
	cg var: #m23ResultY type: #double.
	cg var: #m23ArgX type: #double.
	cg var: #m23ArgY type: #double
]

{ #category : #private }
Matrix2x3Plugin >> loadArgumentMatrix: matrix [
	"Load the argument matrix"
	self returnTypeC:'float *'.
	interpreterProxy failed ifTrue:[^nil].
	((interpreterProxy isWords: matrix) and:[(interpreterProxy slotSizeOf: matrix) = 6]) 
		ifFalse:[interpreterProxy primitiveFail.
				^nil].
	^self cCoerce: (interpreterProxy firstIndexableField: matrix) to:'float *'.
]

{ #category : #private }
Matrix2x3Plugin >> loadArgumentPoint: point [
	"Load the argument point into m23ArgX and m23ArgY"
	| oop isInt |
	interpreterProxy failed ifTrue:[^nil].
	"Check class of point"
	(interpreterProxy fetchClassOf: point) = (interpreterProxy classPoint) 
		ifFalse:[^interpreterProxy primitiveFail].
	"Load X value"
	oop _ interpreterProxy fetchPointer: 0 ofObject: point.
	isInt _ interpreterProxy isIntegerObject: oop.
	(isInt or:[interpreterProxy isFloatObject: oop])
		ifFalse:[^interpreterProxy primitiveFail].
	isInt
		ifTrue:[m23ArgX _ interpreterProxy integerValueOf: oop]
		ifFalse:[m23ArgX _ interpreterProxy floatValueOf: oop].

	"Load Y value"
	oop _ interpreterProxy fetchPointer: 1 ofObject: point.
	isInt _ interpreterProxy isIntegerObject: oop.
	(isInt or:[interpreterProxy isFloatObject: oop])
		ifFalse:[^interpreterProxy primitiveFail].
	isInt
		ifTrue:[m23ArgY _ interpreterProxy integerValueOf: oop]
		ifFalse:[m23ArgY _ interpreterProxy floatValueOf: oop].


]

{ #category : #transforming }
Matrix2x3Plugin >> matrix2x3ComposeMatrix: m1 with: m2 into: m3 [
	"Multiply matrix m1 with m2 and store the result into m3."
	| a11 a12 a13 a21 a22 a23 |
	self var: #m1 declareC:'const float *m1'.
	self var: #m2 declareC:'const float *m2'.
	self var: #m3 declareC:'float *m3'.

	self var: #a11 declareC:'double a11'.
	self var: #a12 declareC:'double a12'.
	self var: #a13 declareC:'double a13'.
	self var: #a21 declareC:'double a21'.
	self var: #a22 declareC:'double a22'.
	self var: #a23 declareC:'double a23'.

	a11 _ ((m1 at: 0) * (m2 at: 0)) + ((m1 at: 1) * (m2 at: 3)).
	a12 _ ((m1 at: 0) * (m2 at: 1)) + ((m1 at: 1) * (m2 at: 4)).
	a13 _ ((m1 at: 0) * (m2 at: 2)) + ((m1 at: 1) * (m2 at: 5)) + (m1 at: 2).
	a21 _ ((m1 at: 3) * (m2 at: 0)) + ((m1 at: 4) * (m2 at: 3)).
	a22 _ ((m1 at: 3) * (m2 at: 1)) + ((m1 at: 4) * (m2 at: 4)).
	a23 _ ((m1 at: 3) * (m2 at: 2)) + ((m1 at: 4) * (m2 at: 5)) + (m1 at: 5).

	m3 at: 0 put: (self cCoerce: a11 to: 'float').
	m3 at: 1 put: (self cCoerce: a12 to: 'float').
	m3 at: 2 put: (self cCoerce: a13 to: 'float').
	m3 at: 3 put: (self cCoerce: a21 to: 'float').
	m3 at: 4 put: (self cCoerce: a22 to: 'float').
	m3 at: 5 put: (self cCoerce: a23 to: 'float').

]

{ #category : #transforming }
Matrix2x3Plugin >> matrix2x3InvertPoint: m [
	"Invert the pre-loaded argument point by the given matrix"
	| x y det detX detY |
	self var: #m declareC:'float *m'.
	self var: #x declareC:'double x'.
	self var: #y declareC:'double y'.
	self var: #det declareC:'double det'.
	self var: #detX declareC:'double detX'.
	self var: #detY declareC:'double detY'.

	x _ m23ArgX - (m at: 2).
	y _ m23ArgY - (m at: 5).
	det _ ((m at: 0) * (m at: 4)) - ((m at: 1) * (m at: 3)).
	det = 0.0 ifTrue:[^interpreterProxy primitiveFail]."Matrix is singular."
	det _ 1.0 / det.
	detX _ (x * (m at: 4)) - ((m at: 1) * y).
	detY _ ((m at: 0) * y) - (x * (m at: 3)).
	m23ResultX _ detX * det.
	m23ResultY _ detY * det.
]

{ #category : #transforming }
Matrix2x3Plugin >> matrix2x3TransformPoint: m [
	"Transform the pre-loaded argument point by the given matrix"
	self var: #m declareC:'float *m'.
	m23ResultX _ (m23ArgX * (m at: 0)) + (m23ArgY * (m at: 1)) + (m at: 2).
	m23ResultY _ (m23ArgX * (m at: 3)) + (m23ArgY * (m at: 4)) + (m at: 5).
]

{ #category : #private }
Matrix2x3Plugin >> okayIntValue: value [
	^(value >= -1073741824 asFloat and:[m23ResultX <= 1073741823 asFloat]) 

]

{ #category : #primitives }
Matrix2x3Plugin >> primitiveComposeMatrix [
	| m1 m2 m3 result |
	self export: true.
	self inline: false.
	self var: #m1 declareC:'float *m1'.
	self var: #m2 declareC:'float *m2'.
	self var: #m3 declareC:'float *m3'.
	m3 _ self loadArgumentMatrix: (result _ interpreterProxy stackObjectValue: 0).
	m2 _ self loadArgumentMatrix: (interpreterProxy stackObjectValue: 1).
	m1 _ self loadArgumentMatrix: (interpreterProxy stackObjectValue: 2).
	interpreterProxy failed ifTrue:[^nil].
	self matrix2x3ComposeMatrix: m1 with: m2 into: m3.
	interpreterProxy pop: 3.
	interpreterProxy push: result.
]

{ #category : #primitives }
Matrix2x3Plugin >> primitiveInvertPoint [
	| matrix |
	self export: true.
	self inline: false.
	self var: #matrix declareC:'float *matrix'.
	self loadArgumentPoint: (interpreterProxy stackObjectValue: 0).
	matrix _ self loadArgumentMatrix: (interpreterProxy stackObjectValue: 1).
	interpreterProxy failed ifTrue:[^nil].
	self matrix2x3InvertPoint: matrix.
	interpreterProxy failed ifFalse:[self roundAndStoreResultPoint: 2].
]

{ #category : #primitives }
Matrix2x3Plugin >> primitiveInvertRectInto [
	| matrix srcOop dstOop originX originY cornerX cornerY minX maxX minY maxY |
	self export: true.
	self inline: false.
	self var: #matrix declareC:'float *matrix'.
	self var: #originX declareC:'double originX'.
	self var: #originY declareC:'double originY'.
	self var: #cornerX declareC:'double cornerX'.
	self var: #cornerY declareC:'double cornerY'.
	self var: #minX declareC:'double minX'.
	self var: #maxX declareC:'double maxX'.
	self var: #minY declareC:'double minY'.
	self var: #maxY declareC:'double maxY'.

	dstOop _ interpreterProxy stackObjectValue: 0.
	srcOop _ interpreterProxy stackObjectValue: 1.
	matrix _ self loadArgumentMatrix: (interpreterProxy stackObjectValue: 2).
	interpreterProxy failed ifTrue:[^nil].

	(interpreterProxy fetchClassOf: srcOop) = (interpreterProxy fetchClassOf: dstOop)
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy isPointers: srcOop)
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy slotSizeOf: srcOop) = 2
		ifFalse:[^interpreterProxy primitiveFail].

	"Load top-left point"
	self loadArgumentPoint: (interpreterProxy fetchPointer: 0 ofObject: srcOop).
	interpreterProxy failed ifTrue:[^nil].
	originX _ m23ArgX.
	originY _ m23ArgY.
	self matrix2x3InvertPoint: matrix.
	minX _ maxX _ m23ResultX.
	minY _ maxY _ m23ResultY.

	"Load bottom-right point"
	self loadArgumentPoint:(interpreterProxy fetchPointer: 1 ofObject: srcOop).
	interpreterProxy failed ifTrue:[^nil].
	cornerX _ m23ArgX.
	cornerY _ m23ArgY.
	self matrix2x3InvertPoint: matrix.
	minX _ minX min: m23ResultX.
	maxX _ maxX max: m23ResultX.
	minY _ minY min: m23ResultY.
	maxY _ maxY max: m23ResultY.

	"Load top-right point"
	m23ArgX _ cornerX.
	m23ArgY _ originY.
	self matrix2x3InvertPoint: matrix.
	minX _ minX min: m23ResultX.
	maxX _ maxX max: m23ResultX.
	minY _ minY min: m23ResultY.
	maxY _ maxY max: m23ResultY.

	"Load bottom-left point"
	m23ArgX _ originX.
	m23ArgY _ cornerY.
	self matrix2x3InvertPoint: matrix.
	minX _ minX min: m23ResultX.
	maxX _ maxX max: m23ResultX.
	minY _ minY min: m23ResultY.
	maxY _ maxY max: m23ResultY.

	interpreterProxy failed ifFalse:[
		dstOop _ self roundAndStoreResultRect: dstOop x0: minX y0: minY x1: maxX y1: maxY].
	interpreterProxy failed ifFalse:[
		interpreterProxy pop: 3.
		interpreterProxy push: dstOop.
	].
]

{ #category : #primitives }
Matrix2x3Plugin >> primitiveIsIdentity [
	| matrix |
	self export: true.
	self inline: false.
	self var: #matrix declareC:'float *matrix'.
	matrix _ self loadArgumentMatrix: (interpreterProxy stackObjectValue: 0).
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy pop: 1.
	interpreterProxy pushBool:(
		((matrix at: 0) = (self cCoerce: 1.0 to: 'float')) &
		((matrix at: 1) = (self cCoerce: 0.0 to: 'float')) &
		((matrix at: 2) = (self cCoerce: 0.0 to: 'float')) &
		((matrix at: 3) = (self cCoerce: 0.0 to: 'float')) &
		((matrix at: 4) = (self cCoerce: 1.0 to: 'float')) &
		((matrix at: 5) = (self cCoerce: 0.0 to: 'float'))).
]

{ #category : #primitives }
Matrix2x3Plugin >> primitiveIsPureTranslation [
	| matrix |
	self export: true.
	self inline: false.
	self var: #matrix declareC:'float *matrix'.
	matrix _ self loadArgumentMatrix: (interpreterProxy stackObjectValue: 0).
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy pop: 1.
	interpreterProxy pushBool:(
		((matrix at: 0) = (self cCoerce: 1.0 to: 'float')) &
		((matrix at: 1) = (self cCoerce: 0.0 to: 'float')) &
		((matrix at: 3) = (self cCoerce: 0.0 to: 'float')) &
		((matrix at: 4) = (self cCoerce: 1.0 to: 'float'))).
]

{ #category : #primitives }
Matrix2x3Plugin >> primitiveTransformPoint [
	| matrix |
	self export: true.
	self inline: false.
	self var: #matrix declareC:'float *matrix'.
	self loadArgumentPoint: (interpreterProxy stackObjectValue: 0).
	matrix _ self loadArgumentMatrix: (interpreterProxy stackObjectValue: 1).
	interpreterProxy failed ifTrue:[^nil].
	self matrix2x3TransformPoint: matrix.
	self roundAndStoreResultPoint: 2.
]

{ #category : #primitives }
Matrix2x3Plugin >> primitiveTransformRectInto [
	| matrix srcOop dstOop originX originY cornerX cornerY minX maxX minY maxY |
	self export: true.
	self inline: false.
	self var: #matrix declareC:'float *matrix'.
	self var: #originX declareC:'double originX'.
	self var: #originY declareC:'double originY'.
	self var: #cornerX declareC:'double cornerX'.
	self var: #cornerY declareC:'double cornerY'.
	self var: #minX declareC:'double minX'.
	self var: #maxX declareC:'double maxX'.
	self var: #minY declareC:'double minY'.
	self var: #maxY declareC:'double maxY'.

	dstOop _ interpreterProxy stackObjectValue: 0.
	srcOop _ interpreterProxy stackObjectValue: 1.
	matrix _ self loadArgumentMatrix: (interpreterProxy stackObjectValue: 2).
	interpreterProxy failed ifTrue:[^nil].

	(interpreterProxy fetchClassOf: srcOop) = (interpreterProxy fetchClassOf: dstOop)
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy isPointers: srcOop)
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy slotSizeOf: srcOop) = 2
		ifFalse:[^interpreterProxy primitiveFail].

	"Load top-left point"
	self loadArgumentPoint: (interpreterProxy fetchPointer: 0 ofObject: srcOop).
	interpreterProxy failed ifTrue:[^nil].
	originX _ m23ArgX.
	originY _ m23ArgY.
	self matrix2x3TransformPoint: matrix.
	minX _ maxX _ m23ResultX.
	minY _ maxY _ m23ResultY.

	"Load bottom-right point"
	self loadArgumentPoint:(interpreterProxy fetchPointer: 1 ofObject: srcOop).
	interpreterProxy failed ifTrue:[^nil].
	cornerX _ m23ArgX.
	cornerY _ m23ArgY.
	self matrix2x3TransformPoint: matrix.
	minX _ minX min: m23ResultX.
	maxX _ maxX max: m23ResultX.
	minY _ minY min: m23ResultY.
	maxY _ maxY max: m23ResultY.

	"Load top-right point"
	m23ArgX _ cornerX.
	m23ArgY _ originY.
	self matrix2x3TransformPoint: matrix.
	minX _ minX min: m23ResultX.
	maxX _ maxX max: m23ResultX.
	minY _ minY min: m23ResultY.
	maxY _ maxY max: m23ResultY.

	"Load bottom-left point"
	m23ArgX _ originX.
	m23ArgY _ cornerY.
	self matrix2x3TransformPoint: matrix.
	minX _ minX min: m23ResultX.
	maxX _ maxX max: m23ResultX.
	minY _ minY min: m23ResultY.
	maxY _ maxY max: m23ResultY.

	dstOop _ self roundAndStoreResultRect: dstOop x0: minX y0: minY x1: maxX y1: maxY.
	interpreterProxy failed ifFalse:[
		interpreterProxy pop: 3.
		interpreterProxy push: dstOop.
	].
]

{ #category : #private }
Matrix2x3Plugin >> roundAndStoreResultPoint: nItemsToPop [
	"Store the result of a previous operation.
	Fail if we cannot represent the result as SmallInteger"
	m23ResultX _ m23ResultX + 0.5.
	m23ResultY _ m23ResultY + 0.5.
	(self okayIntValue: m23ResultX) ifFalse:[^interpreterProxy primitiveFail].
	(self okayIntValue: m23ResultY) ifFalse:[^interpreterProxy primitiveFail].
	interpreterProxy pop: nItemsToPop.
	interpreterProxy push:
		(interpreterProxy makePointwithxValue: m23ResultX asInteger 
							yValue: m23ResultY asInteger).
]

{ #category : #private }
Matrix2x3Plugin >> roundAndStoreResultRect: dstOop x0: x0 y0: y0 x1: x1 y1: y1 [
	"Check, round and store the result of a rectangle operation"
	| minX maxX minY maxY originOop cornerOop rectOop |
	self var: #x0 declareC:'double x0'.
	self var: #y0 declareC:'double y0'.
	self var: #x1 declareC:'double x1'.
	self var: #y1 declareC:'double y1'.
	self var: #minX declareC:'double minX'.
	self var: #maxX declareC:'double maxX'.
	self var: #minY declareC:'double minY'.
	self var: #maxY declareC:'double maxY'.

	minX _ x0 + 0.5.
	(self okayIntValue: minX) ifFalse:[^interpreterProxy primitiveFail].
	maxX _ x1 + 0.5.
	(self okayIntValue: maxX) ifFalse:[^interpreterProxy primitiveFail].
	minY _ y0 + 0.5.
	(self okayIntValue: minY) ifFalse:[^interpreterProxy primitiveFail].
	maxY _ y1 + 0.5.
	(self okayIntValue: maxY) ifFalse:[^interpreterProxy primitiveFail].

	interpreterProxy pushRemappableOop: dstOop.
	originOop _ interpreterProxy makePointwithxValue: minX asInteger yValue: minY asInteger.
	interpreterProxy pushRemappableOop: originOop.
	cornerOop _ interpreterProxy makePointwithxValue: maxX asInteger yValue: maxY asInteger.
	originOop _ interpreterProxy popRemappableOop.
	rectOop _ interpreterProxy popRemappableOop.
	interpreterProxy storePointer: 0 ofObject: rectOop withValue: originOop.
	interpreterProxy storePointer: 1 ofObject: rectOop withValue: cornerOop.
	^rectOop
]
