"
This plugin defines primitives accelerators to support StarSqueak. The plugin library, usually named ""StarSqueakPlugin"", should be put in the same folder as the Squeak interpreter. If this plugin is not available the primitives will still work, but they will be run much more slowly, since they will be running as Squeak code.

"
Class {
	#name : #StarSqueakPlugin,
	#superclass : #InterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #all }
StarSqueakPlugin >> checkedUnsignedIntPtrOf: oop [
	"Return an unsigned int pointer to the first indexable word of oop, which must be a words object."

	self returnTypeC: 'unsigned int *'.
	interpreterProxy success: (interpreterProxy isWords: oop).
	interpreterProxy failed ifTrue: [^ 0].
	^ self cCoerce: (interpreterProxy firstIndexableField: oop) to: 'unsigned int *'

]

{ #category : #all }
StarSqueakPlugin >> primitiveDiffuseFromToWidthHeightDelta [
	"Diffuse the integer values of the source patch variable Bitmap into the output Bitmap. Each cell of the output is the average of the NxN area around it in the source, where N = (2 * delta) + 1."

	| srcOop dstOop height width delta src dst area startY endY startX endX sum rowStart |
	self export: true.
	self var: 'src' declareC: 'unsigned int *src'.
	self var: 'dst' declareC: 'unsigned int *dst'.

	srcOop _ interpreterProxy stackValue: 4.
	dstOop _ interpreterProxy stackValue: 3.
	width _ interpreterProxy stackIntegerValue: 2.
	height _ interpreterProxy stackIntegerValue: 1.
	delta _ interpreterProxy stackIntegerValue: 0.
	src _ self checkedUnsignedIntPtrOf: srcOop.
	dst _ self checkedUnsignedIntPtrOf: dstOop.
	interpreterProxy success:
		(interpreterProxy stSizeOf: srcOop) = (interpreterProxy stSizeOf: dstOop).
	interpreterProxy success:
		(interpreterProxy stSizeOf: srcOop) = (width * height).
	interpreterProxy failed ifTrue: [^ nil].

	area _ ((2 * delta) + 1) * ((2 * delta) + 1).
	0 to: height - 1 do: [:y |
		startY _ y - delta.
		startY < 0 ifTrue: [startY _ 0].
		endY _ y + delta.
		endY >= height ifTrue: [endY _ height - 1].
		0 to: width - 1 do: [:x |
			startX _ x - delta.
			startX < 0 ifTrue: [startX _ 0].
			endX _ x + delta.
			endX >= width ifTrue: [endX _ width - 1].

			sum _ 0.
			startY to: endY do: [:y2 |
				rowStart _ y2 * width.
				startX to: endX do: [:x2 |
					sum _ sum + (src at: rowStart + x2)]].

			dst at: ((y * width) + x) put: (sum // area)]].

	interpreterProxy pop: 5.  "pop args, leave rcvr on stack"

]

{ #category : #all }
StarSqueakPlugin >> primitiveEvaporateRate [
	"Evaporate the integer values of the source Bitmap at the given rate. The rate is an integer between 0 and 1024, where 1024 is a scale factor of 1.0 (i.e., no evaporation)."

	| patchVarOop rate patchVar sz |
	self export: true.
	self var: 'patchVar' declareC: 'unsigned int *patchVar'.

	patchVarOop _ interpreterProxy stackValue: 1.
	rate _ interpreterProxy stackIntegerValue: 0.
	patchVar _ self checkedUnsignedIntPtrOf: patchVarOop.
	sz _ interpreterProxy stSizeOf: patchVarOop.
	interpreterProxy failed ifTrue: [^ nil].

	0 to: sz - 1 do: [:i |
		patchVar at: i put: (((patchVar at: i) * rate) >> 10)].

	interpreterProxy pop: 2.  "pop args, leave rcvr on stack"

]

{ #category : #all }
StarSqueakPlugin >> primitiveMapFromToWidthHeightPatchSizeRgbFlagsShift [

	| srcOop dstOop w h patchSize rgbFlags shiftAmount src dst rgbMult srcIndex level pixel offset |
	self export: true.
	self var: 'src' declareC: 'unsigned int *src'.
	self var: 'dst' declareC: 'unsigned int *dst'.

	srcOop _ interpreterProxy stackValue: 6.
	dstOop _ interpreterProxy stackValue: 5.
	w _ interpreterProxy stackIntegerValue: 4.
	h _ interpreterProxy stackIntegerValue: 3.
	patchSize _ interpreterProxy stackIntegerValue: 2.
	rgbFlags _ interpreterProxy stackIntegerValue: 1.
	shiftAmount _ interpreterProxy stackIntegerValue: 0.

	src _ self checkedUnsignedIntPtrOf: srcOop.
	dst _ self checkedUnsignedIntPtrOf: dstOop.
	interpreterProxy success:
		(interpreterProxy stSizeOf: dstOop) = (w * h).
	interpreterProxy success:
		(interpreterProxy stSizeOf: dstOop) = ((interpreterProxy stSizeOf: srcOop) * patchSize * patchSize).
	interpreterProxy failed ifTrue: [^ nil].

	rgbMult _ 0.
	(rgbFlags bitAnd: 2r100) > 0 ifTrue: [rgbMult _ rgbMult + 16r10000].
	(rgbFlags bitAnd: 2r10) > 0 ifTrue: [rgbMult _ rgbMult + 16r100].
	(rgbFlags bitAnd: 2r1) > 0 ifTrue: [rgbMult _ rgbMult + 16r1].
	srcIndex _ -1.
	0 to: (h // patchSize) - 1 do: [:y |
		0 to: (w // patchSize) - 1 do: [:x |
			level _ (src at: (srcIndex _ srcIndex + 1)) bitShift: shiftAmount.
			level > 255 ifTrue: [level _ 255].
			level <= 0
				ifTrue: [pixel _ 1]  "non-transparent black"
				ifFalse: [pixel _ level * rgbMult].

			"fill a patchSize x patchSize square with the pixel value"
			offset _ ((y * w) + x) * patchSize.
			offset to: offset + ((patchSize - 1) * w) by: w do: [:rowStart |
				rowStart to: rowStart + patchSize - 1 do: [:dstIndex |
					dst at: dstIndex put: pixel]] ]].

	interpreterProxy pop: 7.  "pop args, leave rcvr on stack"

]
