"
This plugin defines primitives accelerators to support StarSqueak. The plugin library, usually named ""StarSqueakPlugin"", should be put in the same folder as the Squeak interpreter. If this plugin is not available the primitives will still work, but they will be run much more slowly, since they will be running as Squeak code.

"
Class {
	#name : #StarSqueakPlugin,
	#superclass : #InterpreterPlugin,
	#category : 'VMMaker-Plugins'
}

{ #category : #all }
StarSqueakPlugin >> checkedUnsignedIntPtrOf: oop [
	"Return an unsigned int pointer to the first indexable word of oop, which must be a words object."

	<returnTypeC: 'unsigned int *'>
	interpreterProxy success: (interpreterProxy isWords: oop).
	interpreterProxy failed ifTrue: [^ 0].
	^ self cCoerce: (interpreterProxy firstIndexableField: oop) to: 'unsigned int *'

]

{ #category : #all }
StarSqueakPlugin >> primitiveDiffuseFromToWidthHeightDelta [
	"Diffuse the integer values of the source patch variable Bitmap into the output Bitmap. Each cell of the output is the average of the NxN area around it in the source, where N = (2 * delta) + 1."

	| srcOop dstOop height width delta src dst area startY endY startX endX sum rowStart |
	<export: true>
	<var: 'src' type: 'unsigned int *'>
	<var: 'dst' type: 'unsigned int *'>

	srcOop := interpreterProxy stackValue: 4.
	dstOop := interpreterProxy stackValue: 3.
	width := interpreterProxy stackIntegerValue: 2.
	height := interpreterProxy stackIntegerValue: 1.
	delta := interpreterProxy stackIntegerValue: 0.
	src := self checkedUnsignedIntPtrOf: srcOop.
	dst := self checkedUnsignedIntPtrOf: dstOop.
	interpreterProxy success:
		(interpreterProxy stSizeOf: srcOop) = (interpreterProxy stSizeOf: dstOop).
	interpreterProxy success:
		(interpreterProxy stSizeOf: srcOop) = (width * height).
	interpreterProxy failed ifTrue: [^ nil].

	area := ((2 * delta) + 1) * ((2 * delta) + 1).
	0 to: height - 1 do: [:y |
		startY := y - delta.
		startY < 0 ifTrue: [startY := 0].
		endY := y + delta.
		endY >= height ifTrue: [endY := height - 1].
		0 to: width - 1 do: [:x |
			startX := x - delta.
			startX < 0 ifTrue: [startX := 0].
			endX := x + delta.
			endX >= width ifTrue: [endX := width - 1].

			sum := 0.
			startY to: endY do: [:y2 |
				rowStart := y2 * width.
				startX to: endX do: [:x2 |
					sum := sum + (src at: rowStart + x2)]].

			dst at: ((y * width) + x) put: (sum // area)]].

	interpreterProxy pop: 5.  "pop args, leave rcvr on stack"

]

{ #category : #all }
StarSqueakPlugin >> primitiveEvaporateRate [
	"Evaporate the integer values of the source Bitmap at the given rate. The rate is an integer between 0 and 1024, where 1024 is a scale factor of 1.0 (i.e., no evaporation)."

	| patchVarOop rate patchVar sz |
	<export: true>
	<var: 'patchVar' type: 'unsigned int *'>

	patchVarOop := interpreterProxy stackValue: 1.
	rate := interpreterProxy stackIntegerValue: 0.
	patchVar := self checkedUnsignedIntPtrOf: patchVarOop.
	sz := interpreterProxy stSizeOf: patchVarOop.
	interpreterProxy failed ifTrue: [^ nil].

	0 to: sz - 1 do: [:i |
		patchVar at: i put: (((patchVar at: i) * rate) >> 10)].

	interpreterProxy pop: 2.  "pop args, leave rcvr on stack"

]

{ #category : #all }
StarSqueakPlugin >> primitiveMapFromToWidthHeightPatchSizeRgbFlagsShift [

	| srcOop dstOop w h patchSize rgbFlags shiftAmount src dst rgbMult srcIndex level pixel offset |
	<export: true>
	<var: 'src' type: 'unsigned int *'>
	<var: 'dst' type: 'unsigned int *'>

	srcOop := interpreterProxy stackValue: 6.
	dstOop := interpreterProxy stackValue: 5.
	w := interpreterProxy stackIntegerValue: 4.
	h := interpreterProxy stackIntegerValue: 3.
	patchSize := interpreterProxy stackIntegerValue: 2.
	rgbFlags := interpreterProxy stackIntegerValue: 1.
	shiftAmount := interpreterProxy stackIntegerValue: 0.

	src := self checkedUnsignedIntPtrOf: srcOop.
	dst := self checkedUnsignedIntPtrOf: dstOop.
	interpreterProxy success:
		(interpreterProxy stSizeOf: dstOop) = (w * h).
	interpreterProxy success:
		(interpreterProxy stSizeOf: dstOop) = ((interpreterProxy stSizeOf: srcOop) * patchSize * patchSize).
	interpreterProxy failed ifTrue: [^ nil].

	rgbMult := 0.
	(rgbFlags bitAnd: 2r100) > 0 ifTrue: [rgbMult := rgbMult + 16r10000].
	(rgbFlags bitAnd: 2r10) > 0 ifTrue: [rgbMult := rgbMult + 16r100].
	(rgbFlags bitAnd: 2r1) > 0 ifTrue: [rgbMult := rgbMult + 16r1].
	srcIndex := -1.
	0 to: (h // patchSize) - 1 do: [:y |
		0 to: (w // patchSize) - 1 do: [:x |
			level := (src at: (srcIndex := srcIndex + 1)) bitShift: shiftAmount.
			level > 255 ifTrue: [level := 255].
			level <= 0
				ifTrue: [pixel := 1]  "non-transparent black"
				ifFalse: [pixel := level * rgbMult].

			"fill a patchSize x patchSize square with the pixel value"
			offset := ((y * w) + x) * patchSize.
			offset to: offset + ((patchSize - 1) * w) by: w do: [:rowStart |
				rowStart to: rowStart + patchSize - 1 do: [:dstIndex |
					dst at: dstIndex put: pixel]] ]].

	interpreterProxy pop: 7.  "pop args, leave rcvr on stack"

]
