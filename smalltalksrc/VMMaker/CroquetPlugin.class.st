"
An assorted list of useful primitives for Croquet.
"
Class {
	#name : #CroquetPlugin,
	#superclass : #InterpreterPlugin,
	#category : 'VMMaker-Plugins'
}

{ #category : #translation }
CroquetPlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #translation }
CroquetPlugin class >> requiresCrossPlatformFiles [
	"default is ok for most, any plugin needing platform specific files must say so"
	^true
]

{ #category : #cryptography }
CroquetPlugin >> primitiveARC4Transform [
	"Perform an ARC4 transform of input.
	Arguments:
		buffer		<ByteArray> transformed data
		startIndex 	<Integer>	start of transform
		stopIndex	<Integer>	end of transform
		m			<ByteArray>	key stream data
		x			<Integer>	key state value
		y			<Integer>	key state value
	Return value:
		x@y - updated key state value
	"

	| y x mOop stopIndex startIndex bufOop bufSize buffer a m b mask ptOop xOop yOop |
	<export: true>
	<var: 'buffer' type: 'unsigned char *'>
	<var: 'm' type: 'unsigned char *'>

	interpreterProxy methodArgumentCount = 6
		ifFalse:[^interpreterProxy primitiveFail].
	"pick up arguments"
	y := interpreterProxy stackIntegerValue: 0.
	x := interpreterProxy stackIntegerValue: 1.
	mOop := interpreterProxy stackObjectValue: 2.
	stopIndex := interpreterProxy stackIntegerValue: 3.
	startIndex := interpreterProxy stackIntegerValue: 4.
	bufOop := interpreterProxy stackObjectValue: 5.
	interpreterProxy failed ifTrue:[^nil].
	((interpreterProxy isBytes: mOop) and:[interpreterProxy isBytes: bufOop])
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy byteSizeOf: mOop) = 256
		ifFalse:[^interpreterProxy primitiveFail].
	bufSize := interpreterProxy byteSizeOf: bufOop.
	(startIndex > 0 and:[startIndex <= bufSize])
		ifFalse:[^interpreterProxy primitiveFail].
	(stopIndex >= startIndex and:[stopIndex <= bufSize])
		ifFalse:[^interpreterProxy primitiveFail].
	m := interpreterProxy firstIndexableField: mOop.
	buffer := interpreterProxy firstIndexableField: bufOop.
	startIndex-1 to: stopIndex-1 do:[:i|
		x := (x + 1) bitAnd: 255.
		a := m at: x.
		y := (y + a) bitAnd: 255.
		b := m at: y.
		m at: x put: b.
		m at: y put: a.
		mask := m at: ((a + b) bitAnd: 255).
		buffer at: i put: ((buffer at: i) bitXor: mask).
	].
	ptOop := interpreterProxy instantiateClass: interpreterProxy classPoint indexableSize: 0.
	interpreterProxy pushRemappableOop: ptOop.
	xOop := interpreterProxy positive32BitIntegerFor: x.
	interpreterProxy pushRemappableOop: xOop.
	yOop := interpreterProxy positive32BitIntegerFor: y.
	xOop := interpreterProxy popRemappableOop.
	ptOop := interpreterProxy popRemappableOop.
	interpreterProxy storePointer: 0 ofObject: ptOop withValue: xOop.
	interpreterProxy storePointer: 1 ofObject: ptOop withValue: yOop.
	interpreterProxy pop: interpreterProxy methodArgumentCount + 1.
	^interpreterProxy push: ptOop.

]

{ #category : #transforms }
CroquetPlugin >> primitiveAdj3 [
	"Computes the adjoint of the Matrix4x4 receiver,
	placing the results the the Matrix4x4 argument,
	"
	| 	
		argc 
		srcOop src 
		dstOop dst
		m11 m12 m13 m21 m22 m23 m31 m32 m33 
		c11 c12 c13 c21 c22 c23 c31 c32 c33 
		  
	|
	<export: true>
	<inline: true>
	<var: #c11 declareC: 'const int c11 = 0'>
	<var: #c12 declareC: 'const int c12 = 1'>
	<var: #c13 declareC: 'const int c13 = 2'>
	"<var: #c14 declareC: 'const int c14 = 3'>"
	<var: #c21 declareC: 'const int c21 = 4'>
	<var: #c22 declareC: 'const int c22 = 5'>
	<var: #c23 declareC: 'const int c23 = 6'>
	"<var: #c24 declareC: 'const int c24 = 7'>"
	<var: #c31 declareC: 'const int c31 = 8'>
	<var: #c32 declareC: 'const int c32 = 9'>
	<var: #c33 declareC: 'const int c33 = 10'>
	"<var: #c34 declareC: 'const int c34 = 11'>"
	<var: #src type: 'float *'>
	<var: #dst type: 'float *'>
	<var: #m11 type:  'double'>
	<var: #m12 type:  'double'>
	<var: #m13 type:  'double'>
	<var: #m21 type:  'double'>
	<var: #m22 type:  'double'>
	<var: #m23 type:  'double'>
	<var: #m31 type:  'double'>
	<var: #m32 type:  'double'>
	<var: #m33 type:  'double'>

	"then we need the following no-op to make Smalltalk shut up about vars not being initted."
	self cCode: '' inSmalltalk: [ 
		c11 := 0. 
		c12 := 1.
		c13 := 2.
		"c14 := 3."
		c21 := 4.
		c22 := 5.
		c23 := 6.
		"c24 := 7."
		c31 := 8.
		c32 := 9.
		c33 := 10.
		"c34 := 11."
	].

	"NOTE: the bottom row of a OpenGL-ordered matrix is always 0 0 0 1, 
	so we don't need consts here for those elements."

	"do the dance to get our receiver and argument"
	argc := interpreterProxy methodArgumentCount.
	argc = 1
		ifFalse:[^interpreterProxy primitiveFail].

	"stackArgvObject is something I added to Interpreter, but since it's not in there yet,
	this won't compile - use it when it's there.  Yes, it would be nice if Smalltalk had #ifdefs..."
	self flag: #stackArgv.
"
	srcOop := interpreterProxy stackArgvObject: 0.	
	src := interpreterProxy firstIndexableField: srcOop.

	dstOop := interpreterProxy stackArgvObject: 1.
	dst := interpreterProxy firstIndexableField: dstOop.
"
	srcOop := interpreterProxy stackObjectValue: argc.	
	src := interpreterProxy firstIndexableField: srcOop.

	dstOop := interpreterProxy stackObjectValue: (argc - 1).
	dst := interpreterProxy firstIndexableField: dstOop.


	"read in the source matrix 3x3, which contains the encoded rotation and scale factors"
	m11 := src at: c11.
	m12 := src at: c12.
	m13 := src at: c13.
	m21 := src at: c21.
	m22 := src at: c22.
	m23 := src at: c23.
	m31 := src at: c31.
	m32 := src at: c32.
	m33 := src at: c33.

	"do the actual work"

	"compute our cofactors and transpose.  adj = transpose of cofactors"
	dst at: c11 put:  ((m22 * m33) - (m23 *  m32)) .
	dst at: c21 put: (0.0 - ((m21 * m33) - (m23 * m31))).
	dst at: c31 put: ((m21 * m32) - (m22 * m31)).

	dst at: c12 put: (0.0 - ((m12 * m33) - (m13 * m32))).
	dst at: c22 put: ((m11 * m33) - (m13 * m31)).
	dst at: c32 put: (0.0 - ((m11 * m32) - (m12 * m31))).

	dst at: c13 put: ((m12 * m23) - (m13 * m22)).
	dst at: c23 put: (0.0 - ((m11 * m23) - (m13 * m21))).
	dst at: c33 put: ((m11 * m22) - (m12 * m21)).
	
	interpreterProxy pop: argc + 1 thenPush: dstOop

]

{ #category : #transforms }
CroquetPlugin >> primitiveDet3 [
	"Computes the determinant of the upper 3x3 of a Matrix4x4"
	| argc  srcOop src det m11 m12 m13 m21 m22 m23 m31 m32 m33 |
	<export: true>
	<inline: true>
	<var: #src type: 'float *'>
	<var: #m11 type:  'double'>
	<var: #m12 type:  'double'>
	<var: #m13 type:  'double'>
	<var: #m21 type:  'double'>
	<var: #m22 type:  'double'>
	<var: #m23 type:  'double'>
	<var: #m31 type:  'double'>
	<var: #m32 type:  'double'>
	<var: #m33 type:  'double'>
	<var: #det type: 'double'>

	argc := interpreterProxy methodArgumentCount.
	argc = 0
		ifFalse:[^interpreterProxy primitiveFail].


	"
		Load element vars using C version of Matrix4x4 storage, as 0-based, 1-dimensional array:
			0 1 2 3
			4 5 6 7
			8 9 10 11
	"

	"stackArgvObject is something I added to Interpreter, but since it's not in there yet,
	this won't compile - use it when it's there.  Yes, it would be nice if Smalltalk had #ifdefs..."
	self flag: #stackArgv.
"
	srcOop := interpreterProxy stackArgvObject: 0.	
	src := interpreterProxy firstIndexableField: srcOop.
"
	srcOop := interpreterProxy stackObjectValue: argc.	
	src := interpreterProxy firstIndexableField: srcOop.


	m11 := src at: 0.
	m12 := src at: 1.
	m13 := src at: 2.
	m21 := src at: 4.
	m22 := src at: 5.
	m23 := src at: 6.
	m31 := src at: 8.
	m32 := src at: 9.
	m33 := src at: 10.


	"do the actual work"
	det := 
		( m11 * ((m22 * m33) - (m23 * m32))) +
			(m12 * ((m23 * m31) - (m21 * m33))) +
				(m13 * ((m21 * m32) - (m22 * m31))).

	
	interpreterProxy pop: argc + 1.
	^interpreterProxy pushFloat: det.

]

{ #category : #cryptography }
CroquetPlugin >> primitiveGatherEntropy [
	"Primitive. Gather good random entropy from a system source."
	| bufOop bufSize bufPtr okay |
	<export: true>
	<var: 'bufPtr' type: 'void *'>
	(interpreterProxy methodArgumentCount = 1)
		ifFalse:[^interpreterProxy primitiveFail].
	bufOop := interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isBytes: bufOop)
		ifFalse:[^interpreterProxy primitiveFail].
	bufSize := interpreterProxy byteSizeOf: bufOop.
	bufPtr := interpreterProxy firstIndexableField: bufOop.
	okay := self cCode: 'ioGatherEntropy(bufPtr, bufSize)' inSmalltalk:[bufPtr. bufSize. false].
	okay ifFalse:[^interpreterProxy primitiveFail].
	interpreterProxy pop: interpreterProxy methodArgumentCount + 1.
	^interpreterProxy pushBool: true.
]

{ #category : #transforms }
CroquetPlugin >> primitiveInplaceHouseHolderInvert [
	"Primitive. Perform an inplace house holder matrix inversion"
	| rcvr d x sigma beta sum s m |
	<export: true>
	<var: #rcvr declareC:'float *rcvr'>
	<var: #m declareC:'double m[4][4]'>
	<var: #x declareC:'double x[4][4] = { {1, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 1, 0}, {0, 0, 0, 1} }'>
	<var: #d declareC:'double d[4][4]'>
	<var: #sigma declareC:'double sigma'>
	<var: #beta declareC:'double beta'>
	<var: #sum declareC:'double sum'>
	<var: #s declareC:'double s'>

	self cCode:'' inSmalltalk:[
		m := CArrayAccessor on: 
				((1 to: 4) collect:[:i| CArrayAccessor on: (Array new: 4)]).
		x := CArrayAccessor on: (Array
				with: (CArrayAccessor on: #(1.0 0.0 0.0 0.0) copy)
				with: (CArrayAccessor on: #(0.0 1.0 0.0 0.0) copy)
				with: (CArrayAccessor on: #(0.0 0.0 1.0 0.0) copy)
				with: (CArrayAccessor on: #(0.0 0.0 0.0 1.0) copy)).
		d := CArrayAccessor on: 
				((1 to: 4) collect:[:i| CArrayAccessor on: (Array new: 4)]).
	].
	rcvr := self stackMatrix: 0.
	0 to: 3 do:[:i| 0 to: 3 do:[:j|
		(m at: i) at: j put: (rcvr at: i*4+j)]].
	0 to: 3 do:[:j|
		sigma := 0.0.
		j to: 3 do:[:i| sigma := sigma + (((m at: i) at: j)  * ((m at: i) at: j))].
		sigma < 1.0e-10 ifTrue:[^interpreterProxy primitiveFail]. "matrix is singular"
		(((m at: j) at: j) < 0.0) 
			ifTrue:[ s:= sigma sqrt]
			ifFalse:[ s:= 0.0 - sigma sqrt].
		0 to: 3 do:[:r| (d at: j) at: r put: s].
		beta := 1.0 / ( s * ((m at: j) at: j) - sigma).
		(m at: j) at: j put: (((m at: j) at: j) - s).
		"update remaining columns"
		j+1 to: 3 do:[:k|
			sum := 0.0.
			j to: 3 do:[:i| sum := sum + (((m at: i) at: j) * ((m at: i) at: k))].
			sum := sum * beta.
			j to: 3 do:[:i| 
				(m at: i) at: k put: (((m at: i) at: k) + (((m at: i) at: j) * sum))]].
		"update vector"
		0 to: 3 do:[:r|
			sum := 0.0.
			j to: 3 do:[:i| 
				sum := sum + (((x at: i) at: r) * ((m at: i) at: j))].
			sum := sum * beta.
			j to: 3 do:[:i| 
				(x at: i) at: r put:(((x at: i) at: r) + (sum * ((m at: i) at: j)))].
		].
	].
	"Now calculate result"
	0 to: 3 do:[:r|
		3 to: 0 by: -1 do:[:i|
			i+1 to: 3 do:[:j|
				(x at: i) at: r put: (((x at: i) at: r) - (((x at: j) at: r) * ((m at: i) at: j))) ].
			(x at: i) at: r put: (((x at: i) at: r) / ((d at: i) at: r))].
	].
	0 to: 3 do:[:i| 0 to: 3 do:[:j|
		rcvr at: i*4+j put: (self cCoerce: ((x at: i) at: j) to:'float')]].
	"Return receiver"
	^nil
]

{ #category : #transforms }
CroquetPlugin >> primitiveInverseByAdjoint [
	"Computes the inverse of the Matrix4x4 receiver, using the 'classical adjoint' method,
	placing the results the the Matrix4x4 argument,
	"
	| 	
		srcOop src 
		dstOop dst
		det 
		m11 m12 m13 m21 m22 m23 m31 m32 m33 
		c11 c12 c13 c14 c21 c22 c23 c24 c31 c32 c33 c34 
		x y z  
	argc |
	<export: true>
	<inline: true>
	<var: #c11 declareC: 'const int c11 = 0'>
	<var: #c12 declareC: 'const int c12 = 1'>
	<var: #c13 declareC: 'const int c13 = 2'>
	<var: #c14 declareC: 'const int c14 = 3'>
	<var: #c21 declareC: 'const int c21 = 4'>
	<var: #c22 declareC: 'const int c22 = 5'>
	<var: #c23 declareC: 'const int c23 = 6'>
	<var: #c24 declareC: 'const int c24 = 7'>
	<var: #c31 declareC: 'const int c31 = 8'>
	<var: #c32 declareC: 'const int c32 = 9'>
	<var: #c33 declareC: 'const int c33 = 10'>
	<var: #c34 declareC: 'const int c34 = 11'>
	<var: #src type: 'float *'>
	<var: #dst type: 'float *'>
	<var: #m11 type:  'double'>
	<var: #m12 type:  'double'>
	<var: #m13 type:  'double'>
	<var: #m21 type:  'double'>
	<var: #m22 type:  'double'>
	<var: #m23 type:  'double'>
	<var: #m31 type:  'double'>
	<var: #m32 type:  'double'>
	<var: #m33 type:  'double'>
	<var: #x type: 'double'>
	<var: #y type: 'double'>
	<var: #z type: 'double'>
	<var: #det type: 'double'>

	"then we need the following no-op to make Smalltalk shut up about vars not being initted."
	self cCode: '' inSmalltalk: [ 
		c11 := 0. 
		c12 := 1.
		c13 := 2.
		c14 := 3.
		c21 := 4.
		c22 := 5.
		c23 := 6.
		c24 := 7.
		c31 := 8.
		c32 := 9.
		c33 := 10.
		c34 := 11.
	].

	"NOTE: the bottom row of a OpenGL-ordered matrix is always 0 0 0 1, 
	so we don't need consts here for those elements."

	"do the dance to get our receiver and argument"
	argc := interpreterProxy methodArgumentCount.
	argc = 1
		ifFalse:[^interpreterProxy primitiveFail].

	"stackArgvObject is something I added to Interpreter, but since it's not in there yet,
	this won't compile - use it when it's there.  Yes, it would be nice if Smalltalk had #ifdefs..."
	self flag: #stackArgv.
"
	srcOop := interpreterProxy stackArgvObject: 0.	
	src := interpreterProxy firstIndexableField: srcOop.

	dstOop := interpreterProxy stackArgvObject: 1.
	dst := interpreterProxy firstIndexableField: dstOop.
"
	srcOop := interpreterProxy stackObjectValue: argc.	
	src := interpreterProxy firstIndexableField: srcOop.

	dstOop := interpreterProxy stackObjectValue: (argc - 1).
	dst := interpreterProxy firstIndexableField: dstOop.


	"read in the source matrix 3x3, which contains the encoded rotation and scale factors"
	m11 := src at: c11.
	m12 := src at: c12.
	m13 := src at: c13.
	m21 := src at: c21.
	m22 := src at: c22.
	m23 := src at: c23.
	m31 := src at: c31.
	m32 := src at: c32.
	m33 := src at: c33.

	"read in the source translation vector"
	x := src at: c14.
	y := src at: c24.
	z := src at: c34.

	"do the actual work"

	"first, compute the determinant of the upper 3x3 of the source"
	det := 
		( m11 * ((m22 * m33) - (m23 * m32))) +
			(m12 * ((m23 * m31) - (m21 * m33))) +
				(m13 * ((m21 * m32) - (m22 * m31))).

	"Compute the classical adjunct of the source, and divide by the source determinant
	storing in the destination.  adjoint = transpose of cofactors, so we'll transpose as we store."

	det := 1 / det.		"let's make div by det a multiply"
	dst at: c11 put:  ((m22 * m33) - (m23 *  m32)) * det .
	dst at: c21 put: (0.0 - ((m21 * m33) - (m23 * m31))) * det.
	dst at: c31 put: ((m21 * m32) - (m22 * m31)) * det.

	dst at: c12 put: (0.0 - ((m12 * m33) - (m13 * m32))) * det.
	dst at: c22 put: ((m11 * m33) - (m13 * m31)) * det.
	dst at: c32 put: (0.0 - ((m11 * m32) - (m12 * m31))) * det.

	dst at: c13 put: ((m12 * m23) - (m13 * m22)) * det.
	dst at: c23 put: (0.0 - ((m11 * m23) - (m13 * m21))) * det.
	dst at: c33 put: ((m11 * m22) - (m12 * m21)) * det.
	
	"finally, apply the inversed rotation transform to our translation"
	
	"read in the source matrix 3x3"
	m11 := dst at: c11.
	m12 := dst at: c12.
	m13 := dst at: c13.
	m21 := dst at: c21.
	m22 := dst at: c22.
	m23 := dst at: c23.
	m31 := dst at: c31.
	m32 := dst at: c32.
	m33 := dst at: c33.

	dst at: c14 put: 0.0 - ((x * m11) + (y * m12) + (z * m13)).
	dst at: c24 put: 0.0 - ((x * m21) + (y * m22) + (z * m23)).
	dst at: c34 put: 0.0 - ((x * m31) + (y * m32) + (z * m33)).

	interpreterProxy pop: argc + 1.
	^interpreterProxy push: dstOop.

]

{ #category : #cryptography }
CroquetPlugin >> primitiveMD5Transform [
	"Perform an MD5 transform of input"
	| bufOop hashOop hash buffer |
	<export: true>
	<var: 'hash' type: 'unsigned int *'>
	<var: 'buffer' type: 'unsigned int *'>
	interpreterProxy methodArgumentCount = 2 
		ifFalse:[^interpreterProxy primitiveFail].

	hashOop := interpreterProxy stackObjectValue: 0.
	((interpreterProxy isWords: hashOop) and:[(interpreterProxy slotSizeOf: hashOop) = 4])
		ifFalse:[^interpreterProxy primitiveFail].
	hash := interpreterProxy firstIndexableField: hashOop.

	bufOop := interpreterProxy stackObjectValue: 1.
	((interpreterProxy isWords: bufOop) and:[(interpreterProxy slotSizeOf: bufOop) = 16])
		ifFalse:[^interpreterProxy primitiveFail].
	buffer := interpreterProxy firstIndexableField: bufOop.


	self cCode:'MD5Transform(hash, buffer)' inSmalltalk:[
		hash. buffer. 
		^interpreterProxy primitiveFail].
	"Pop args; return buffer"
	interpreterProxy pop: interpreterProxy methodArgumentCount+1.
	^interpreterProxy push: bufOop.
]

{ #category : #'mesh processing' }
CroquetPlugin >> primitiveOptimizeVertexIndicesForCacheLocality [
	"Given a list of integer indices for rendering a triangle-mesh in indexed-triangles mode, reorganize the indices in-place to provide better vertex cache locality.
	We use Tom Forsyth's algorithm:
		http://home.comcast.net/~tom_forsyth/papers/fast_vert_cache_opt.html
	... and the MIT-licensed implementation by Michael Georgoulpoulos at:
		http://code.google.com/p/vcacne/"
	| indicesOop indices byteSize triCount result |
	<export: true>
	<inline: true>
	<var: #indices type: 'void *'>

	"Get the oop of the IntegerArray containing the indices."
	(interpreterProxy methodArgumentCount = 1) ifFalse: [^interpreterProxy primitiveFail].
	indicesOop := interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue: [^nil].
	(interpreterProxy isWords: indicesOop) ifFalse: [^interpreterProxy primitiveFail].
	
	"Ensure that the number of indices is a multiple of 3."
	byteSize := interpreterProxy byteSizeOf: indicesOop.
	triCount := byteSize / 12.
	(triCount * 12) = byteSize ifFalse: [^interpreterProxy primitiveFail].
	
	"Get an int* to the indices, and optimize 'em."
	indices := interpreterProxy firstIndexableField: indicesOop.
	self touch: indices.
	interpreterProxy failed ifTrue: [^nil].
	result := self cCode: 'optimizeVertexIndices((int*)indices, triCount)'.
	result = 0 "success" ifFalse: [^interpreterProxy primitiveFail].
	^interpreterProxy pop: 1
]

{ #category : #transforms }
CroquetPlugin >> primitiveOrthoNormInverseMatrix [
	| srcOop dstOop src dst x y z rx ry rz |
	<export: true>
	<var: #src declareC:'float *src'>
	<var: #dst declareC:'float *dst'>
	<var: #x declareC:'double x'>
	<var: #y declareC:'double y'>
	<var: #z declareC:'double z'>
	<var: #rx declareC:'double rx'>
	<var: #ry declareC:'double ry'>
	<var: #rz declareC:'double rz'>

	interpreterProxy methodArgumentCount = 0
		ifFalse:[^interpreterProxy primitiveFail].
	srcOop := interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	((interpreterProxy isWords: srcOop) and:[(interpreterProxy slotSizeOf: srcOop) = 16])
		ifFalse:[^interpreterProxy primitiveFail].
	dstOop := interpreterProxy clone: srcOop.
	"reload srcOop in case of GC"
	srcOop := interpreterProxy stackObjectValue: 0.
	src := interpreterProxy firstIndexableField: srcOop.
	dst := interpreterProxy firstIndexableField: dstOop.

	"Transpose upper 3x3 matrix"
	"dst at: 0 put: (src at: 0)."	dst at: 1 put: (src at: 4). 	dst at: 2 put: (src at: 8). 
	dst at: 4 put: (src at: 1). 	"dst at: 5 put: (src at: 5)."	dst at: 6 put: (src at: 9). 
	dst at: 8 put: (src at: 2). 	dst at: 9 put: (src at: 6). 	"dst at: 10 put: (src at: 10)."

	"Compute inverse translation vector"
	x := src at: 3.
	y := src at: 7.
	z := src at: 11.
	rx := (x * (dst at: 0)) + (y * (dst at: 1)) + (z * (dst at: 2)).
	ry := (x * (dst at: 4)) + (y * (dst at: 5)) + (z * (dst at: 6)).
	rz := (x * (dst at: 8)) + (y * (dst at: 9)) + (z * (dst at: 10)).

	dst at: 3 put: (self cCoerce: 0.0-rx to: 'float').
	dst at: 7 put: (self cCoerce: 0.0-ry to: 'float').
	dst at: 11 put: (self cCoerce: 0.0-rz to: 'float').

	interpreterProxy pop: 1.
	^interpreterProxy push: dstOop.

]

{ #category : #transforms }
CroquetPlugin >> primitiveTransformDirection [
	| x y z rx ry rz matrix vertex v3Oop |
	<export: true>
	<var: #vertex declareC:'float *vertex'>
	<var: #matrix declareC:'float *matrix'>
	<var: #x declareC:'double x'>
	<var: #y declareC:'double y'>
	<var: #z declareC:'double z'>
	<var: #rx declareC:'double rx'>
	<var: #ry declareC:'double ry'>
	<var: #rz declareC:'double rz'>

	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	v3Oop := interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	((interpreterProxy isWords: v3Oop) and:[(interpreterProxy slotSizeOf: v3Oop) = 3])
		ifFalse:[^interpreterProxy primitiveFail].
	vertex := interpreterProxy firstIndexableField: v3Oop.
	matrix := self stackMatrix: 1.
	(matrix == nil) ifTrue:[^interpreterProxy primitiveFail].

	x := vertex at: 0.
	y := vertex at: 1.
	z := vertex at: 2.

	rx := (x * (matrix at: 0)) + (y * (matrix at: 1)) + (z * (matrix at: 2)).
	ry := (x * (matrix at: 4)) + (y * (matrix at: 5)) + (z * (matrix at: 6)).
	rz := (x * (matrix at: 8)) + (y * (matrix at: 9)) + (z * (matrix at: 10)).

	v3Oop := interpreterProxy clone: v3Oop.
	vertex := interpreterProxy firstIndexableField: v3Oop.

	vertex at: 0 put: (self cCoerce: rx to: 'float').
	vertex at: 1 put: (self cCoerce: ry to:'float').
	vertex at: 2 put: (self cCoerce: rz to: 'float').

	interpreterProxy pop: 2.
	^interpreterProxy push: v3Oop.

]

{ #category : #transforms }
CroquetPlugin >> primitiveTransformMatrixWithInto [
	"Transform two matrices into the third"
	| m1 m2 m3 |
	<export: true>
	<inline: false>
	<var: #m1 declareC:'float *m1'>
	<var: #m2 declareC:'float *m2'>
	<var: #m3 declareC:'float *m3'>

	m3 := self stackMatrix: 0.
	m2 := self stackMatrix: 1.
	m1 := self stackMatrix: 2.
	(m1 = nil) | (m2 = nil) | (m3 = nil) 
		ifTrue:[^interpreterProxy primitiveFail].
	m2 == m3 ifTrue:[^interpreterProxy primitiveFail].
	self transformMatrix: m1 with: m2 into: m3.
	^interpreterProxy pop: 3. "Leave rcvr on stack"
]

{ #category : #transforms }
CroquetPlugin >> primitiveTransformVector3 [
	| x y z rx ry rz rw matrix vertex v3Oop |
	<export: true>
	<var: #vertex declareC:'float *vertex'>
	<var: #matrix declareC:'float *matrix'>
	<var: #x declareC:'double x'>
	<var: #y declareC:'double y'>
	<var: #z declareC:'double z'>
	<var: #rx declareC:'double rx'>
	<var: #ry declareC:'double ry'>
	<var: #rz declareC:'double rz'>
	<var: #rw declareC:'double rw'>

	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	v3Oop := interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	((interpreterProxy isWords: v3Oop) and:[(interpreterProxy slotSizeOf: v3Oop) = 3])
		ifFalse:[^interpreterProxy primitiveFail].
	vertex := interpreterProxy firstIndexableField: v3Oop.
	matrix := self stackMatrix: 1.
	(matrix == nil) ifTrue:[^interpreterProxy primitiveFail].

	x := vertex at: 0.
	y := vertex at: 1.
	z := vertex at: 2.

	rx := (x * (matrix at: 0)) + (y * (matrix at: 1)) + (z * (matrix at: 2)) + (matrix at: 3).
	ry := (x * (matrix at: 4)) + (y * (matrix at: 5)) + (z * (matrix at: 6)) + (matrix at: 7).
	rz := (x * (matrix at: 8)) + (y * (matrix at: 9)) + (z * (matrix at: 10)) + (matrix at: 11).
	rw := (x * (matrix at: 12)) + (y * (matrix at: 13)) + (z * (matrix at: 14)) + (matrix at: 15).

	v3Oop := interpreterProxy clone: v3Oop.
	vertex := interpreterProxy firstIndexableField: v3Oop.

	rw = 1.0 ifTrue:[
		vertex at: 0 put: (self cCoerce: rx to: 'float').
		vertex at: 1 put: (self cCoerce: ry to:'float').
		vertex at: 2 put: (self cCoerce: rz to: 'float').
	] ifFalse:[
		rw = 0.0 
			ifTrue:[rw := 0.0]
			ifFalse:[rw := 1.0 / rw].
		vertex at: 0 put: (self cCoerce: rx*rw to:'float').
		vertex at: 1 put: (self cCoerce: ry*rw to:'float').
		vertex at: 2 put: (self cCoerce: rz*rw to: 'float').
	].
	interpreterProxy pop: 2.
	^interpreterProxy push: v3Oop.

]

{ #category : #transforms }
CroquetPlugin >> primitiveTransposeMatrix [
	| srcOop dstOop src dst |
	<export: true>
	<var: #src declareC:'float *src'>
	<var: #dst declareC:'float *dst'>

	interpreterProxy methodArgumentCount = 0
		ifFalse:[^interpreterProxy primitiveFail].
	srcOop := interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	((interpreterProxy isWords: srcOop) and:[(interpreterProxy slotSizeOf: srcOop) = 16])
		ifFalse:[^interpreterProxy primitiveFail].
	dstOop := interpreterProxy clone: srcOop.
	"reload srcOop in case of GC"
	srcOop := interpreterProxy stackObjectValue: 0.
	src := interpreterProxy firstIndexableField: srcOop.
	dst := interpreterProxy firstIndexableField: dstOop.

	"dst at: 0 put: (src at: 0)."
	dst at: 1 put: (src at: 4). 
	dst at: 2 put: (src at: 8). 
	dst at: 3 put: (src at: 12).

	dst at: 4 put: (src at: 1). 
	"dst at: 5 put: (src at: 5)."
	dst at: 6 put: (src at: 9). 
	dst at: 7 put: (src at: 13).

	dst at: 8 put: (src at: 2). 
	dst at: 9 put: (src at: 6). 
	"dst at: 10 put: (src at: 10)."
	dst at: 11 put: (src at: 14).

	dst at: 12 put: (src at: 3). 
	dst at: 13 put: (src at: 7). 
	dst at: 14 put: (src at: 11). 
	"dst at: 15 put: (src at: 15)."

	interpreterProxy pop: 1.
	^interpreterProxy push: dstOop.

]

{ #category : #transforms }
CroquetPlugin >> primitiveTriBoxIntersects [
	"Primitive. Answer whether an AABB intersects with a given triangle"
	| minCorner maxCorner v0 v1 v2 result |
	<export: true>
	<var: #minCorner type: #'float *'>
	<var: #maxCorner type: #'float *'>
	<var: #v0 type: #'float *'>
	<var: #v1 type: #'float *'>
	<var: #v2 type: #'float *'>

	interpreterProxy methodArgumentCount = 5
		ifFalse:[^interpreterProxy primitiveFail].
	v2 := self stackVector3: 0.
	v1 := self stackVector3: 1.
	v0 := self stackVector3: 2.
	maxCorner := self stackVector3: 3.
	minCorner := self stackVector3: 4.

	result := self cCode:'triBoxOverlap(minCorner, maxCorner, v0, v1, v2)' 
				inSmalltalk:[minCorner. maxCorner. v0. v1. v2. -1].
	result < 0 ifTrue:[^interpreterProxy primitiveFail].

	interpreterProxy pop: 6. "args+rcvr"
	^interpreterProxy pushBool: result.
]

{ #category : #transforms }
CroquetPlugin >> stackMatrix: index [
	"Load a 4x4 transformation matrix from the interpreter stack.
	Return a pointer to the matrix data if successful, nil otherwise."
	| oop |
	<inline: false>
	<returnTypeC:'void*'>
	oop := interpreterProxy stackObjectValue: index.
	oop = nil ifTrue:[^nil].
	((interpreterProxy isWords: oop) and:[(interpreterProxy slotSizeOf: oop) = 16])
		ifTrue:[^interpreterProxy firstIndexableField: oop].
	^nil
]

{ #category : #transforms }
CroquetPlugin >> stackVector3: index [
	"Load a Vector3 from the interpreter stack.
	Return a pointer to the float data if successful, nil otherwise."
	| oop |
	<inline: false>
	<returnTypeC:'void*'>
	oop := interpreterProxy stackObjectValue: index.
	oop = nil ifTrue:[^nil].
	((interpreterProxy isWords: oop) and:[(interpreterProxy slotSizeOf: oop) = 3])
		ifTrue:[^interpreterProxy firstIndexableField: oop].
	^nil
]

{ #category : #transforms }
CroquetPlugin >> transformMatrix: src with: arg into: dst [
	"Transform src with arg into dst.
	It is allowed that src == dst but not arg == dst"
	| m1 m2 m3 c1 c2 c3 c4 |
	<var: #src declareC:'float *src'>
	<var: #arg declareC:'float *arg'>
	<var: #dst declareC:'float *dst'>
	<var: #m1 declareC:'float *m1'>
	<var: #m2 declareC:'float *m2'>
	<var: #m3 declareC:'float *m3'>

	<var: #c1 declareC:'double c1'>
	<var: #c2 declareC:'double c2'>
	<var: #c3 declareC:'double c3'>
	<var: #c4 declareC:'double c4'>

	m1 := self cCoerce: src to:'float *'.
	m2 := self cCoerce: arg to: 'float *'.
	m3 := self cCoerce: dst to: 'float *'.

	0 to: 3 do:[:i|

		"Compute next row"
		c1 := ((m1 at: 0) asFloat * (m2 at: 0) asFloat) + ((m1 at: 1) asFloat * (m2 at: 4) asFloat) +
			((m1 at: 2) asFloat * (m2 at: 8) asFloat) + ((m1 at: 3) asFloat * (m2 at: 12) asFloat).

		c2 := ((m1 at: 0) asFloat * (m2 at: 1) asFloat) + ((m1 at: 1) asFloat * (m2 at: 5) asFloat) +
			((m1 at: 2) asFloat * (m2 at: 9) asFloat) + ((m1 at: 3) asFloat * (m2 at: 13) asFloat).

		c3 := ((m1 at: 0) asFloat * (m2 at: 2) asFloat) + ((m1 at: 1) asFloat * (m2 at: 6) asFloat) +
			((m1 at: 2) asFloat * (m2 at: 10) asFloat) + ((m1 at: 3) asFloat * (m2 at: 14) asFloat).

		c4 := ((m1 at: 0) asFloat * (m2 at: 3) asFloat) + ((m1 at: 1) asFloat * (m2 at: 7) asFloat) +
			((m1 at: 2) asFloat * (m2 at: 11) asFloat) + ((m1 at: 3) asFloat * (m2 at: 15) asFloat).

		"Store result"
		m3 at: 0 put: c1.
		m3 at: 1 put: c2.
		m3 at: 2 put: c3.
		m3 at: 3 put: c4.

		"Skip src and dst to next row"
		m1 := m1 + 4.
		m3 := m3 + 4.
	].

	^nil

]
