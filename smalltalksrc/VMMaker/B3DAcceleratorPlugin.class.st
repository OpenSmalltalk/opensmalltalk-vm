"
B3DAcceleratorPlugin translate
"
Class {
	#name : #B3DAcceleratorPlugin,
	#superclass : #InterpreterPlugin,
	#instVars : [
		'doRangeChecks'
	],
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
B3DAcceleratorPlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #translation }
B3DAcceleratorPlugin class >> moduleName [
	^'B3DAcceleratorPlugin'
]

{ #category : #translation }
B3DAcceleratorPlugin class >> requiresCrossPlatformFiles [
	"default is ok for most, any plugin needing platform specific files must say so"
	^true
]

{ #category : #translation }
B3DAcceleratorPlugin class >> requiresPlatformFiles [
	"default is ok for most, any plugin needing platform specific files must say so"
	^true
]

{ #category : #testing }
B3DAcceleratorPlugin class >> testLoadPlugin [
	"B3DAcceleratorPlugin testLoadPlugin"
	<primitive: 'primitiveRendererVersion' module: 'B3DAcceleratorPlugin' error: ec>
	self primitiveFailed
]

{ #category : #'primitives-qwaq' }
B3DAcceleratorPlugin >> checkBoundsRange: vertices faces: facePtr count: faceCount [
	"Verify the bounds condition on the entire faces array"
	| vtxSize |
	<var: #facePtr type: 'unsigned int *'>
	vtxSize := (interpreterProxy slotSizeOf: vertices) / 3.
	0 to: faceCount-1 do:[:i|
		(facePtr at: i) > vtxSize
			ifTrue:[^interpreterProxy primitiveFail]].

]

{ #category : #'primitives-qwaq' }
B3DAcceleratorPlugin >> checkVertexData: vertices [
	"Check the entire vertex data to ensure no nan/inf values"
	| vtxSize vtxPtr f |
	<var: #vtxPtr type: 'float *'>
	<var: #f type: 'float'>
	vtxSize := interpreterProxy slotSizeOf: vertices.
	vtxPtr := interpreterProxy firstIndexableField: vertices.
	0 to: vtxSize-1 do:[:i|
		f := vtxPtr at: i.
		(self isnan: (f-f)) ifTrue:[^interpreterProxy primitiveFail].
	].

]

{ #category : #'primitive support' }
B3DAcceleratorPlugin >> fetchLightSource: index ofObject: anArray [
	"Fetch the primitive light source from the given array.
	Note: No checks are done within here - that happened in stackLightArrayValue:"
	| lightOop |
	<inline: true>
	<returnTypeC:'void*'>
	lightOop := interpreterProxy fetchPointer: index ofObject: anArray.
	^interpreterProxy firstIndexableField: lightOop
]

{ #category : #'initialize-release' }
B3DAcceleratorPlugin >> initialiseModule [
	<export: true>
	doRangeChecks := true.
	^self b3dxInitialize
]

{ #category : #'primitives-qwaq' }
B3DAcceleratorPlugin >> loadClientState: handle vertices: vertices colors: colors normals: normals texCoords: texCoords [
	"Common method to set up client state for some render ops"
	| nilOop vtxSize sz colorPtr normalPtr txPtr vertexPtr ok |
	<var: #colorPtr type: 'void *'>
	<var: #normalPtr type: 'void *'>
	<var: #txPtr type: 'void *'>
	<var: #vertexPtr type: 'void *'>

	colorPtr := normalPtr := txPtr := vertexPtr := nil.
	sz := 0.

	"Verify vertex data"
	(interpreterProxy isWords: vertices) ifFalse:
		[^interpreterProxy primitiveFail].
	vtxSize := (interpreterProxy slotSizeOf: vertices) / 3.

	"Verify assumptions of color, normal, texCoords data"
	nilOop := interpreterProxy nilObject.
	(colors = nilOop
	 or: [(interpreterProxy isWords: colors)
		and: [(interpreterProxy slotSizeOf: colors) = (vtxSize * 4)]]) ifFalse:
		[^interpreterProxy primitiveFail].
	(normals = nilOop
	 or: [(interpreterProxy isWords: normals)
		and: [(interpreterProxy slotSizeOf: normals) = (vtxSize * 3)]]) ifFalse:
		[^interpreterProxy primitiveFail].
	"Don't check size for texCoords since they can be 2,3,4 elements"
	(texCoords = nilOop
	 or: [(interpreterProxy isWords: texCoords)]) ifFalse:
		[^interpreterProxy primitiveFail].

	"Finally submit the data to OpenGL"
	colors = nilOop ifFalse:
		[colorPtr := interpreterProxy firstIndexableField: colors].
	normals = nilOop ifFalse:
		[normalPtr := interpreterProxy firstIndexableField: normals].
	texCoords = nilOop ifFalse:
		[sz := (interpreterProxy slotSizeOf: texCoords) / vtxSize.
		txPtr := interpreterProxy firstIndexableField: texCoords].
	vertexPtr := interpreterProxy firstIndexableField: vertices.
	interpreterProxy failed ifFalse:
		[ok := self
				cCode:'b3dLoadClientState(handle, vertexPtr, 3, colorPtr, 4, normalPtr, 3, txPtr, sz)'
				inSmalltalk: [vertexPtr. colorPtr. normalPtr. txPtr. sz touch].
		 ok ifFalse: [interpreterProxy primitiveFail]].
	^nil "keep compiler quiet"

]

{ #category : #'primitives-textures' }
B3DAcceleratorPlugin >> primitiveAllocateTexture [
	| h w d result renderer |
	<export: true>
	interpreterProxy methodArgumentCount = 4
		ifFalse:[^interpreterProxy primitiveFail].
	h := interpreterProxy stackIntegerValue: 0.
	w := interpreterProxy stackIntegerValue: 1.
	d := interpreterProxy stackIntegerValue: 2.
	renderer := interpreterProxy stackIntegerValue: 3.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxAllocateTexture(renderer, w, h, d)' inSmalltalk:[-1].
	result = -1 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 5. "args+rcvr"
	^interpreterProxy pushInteger: result.
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveClearDepthBuffer [
	| result handle |
	<export: true>
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxClearDepthBuffer(handle)'.
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 1. "pop args; return rcvr"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveClearViewport [
	| result handle pv rgba |
	<export: true>
	interpreterProxy methodArgumentCount = 3
		ifFalse:[^interpreterProxy primitiveFail].
	pv := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 0).
	rgba := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 1).
	handle := interpreterProxy stackIntegerValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxClearViewport(handle, rgba, pv)'.
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 3. "pop args; return rcvr"
]

{ #category : #'primitives-textures' }
B3DAcceleratorPlugin >> primitiveCompositeTexture [
	| result translucent y x w h texHandle rendererHandle |
	<export: true>
	interpreterProxy methodArgumentCount = 7
		ifFalse:[^interpreterProxy primitiveFail].
	translucent := interpreterProxy booleanValueOf: (interpreterProxy stackValue: 0).
	h := interpreterProxy stackIntegerValue: 1.
	w := interpreterProxy stackIntegerValue: 2.
	y := interpreterProxy stackIntegerValue: 3.
	x := interpreterProxy stackIntegerValue: 4.
	texHandle := interpreterProxy stackIntegerValue: 5.
	rendererHandle := interpreterProxy stackIntegerValue: 6.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxCompositeTexture(rendererHandle, texHandle, x, y, w, h, translucent)' inSmalltalk:[false].
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 7. "args"

]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveCreateRenderer [
	"NOTE: This primitive is obsolete but should be supported for older images"
	| h w y x result allowHardware allowSoftware |
	<export: true>
	interpreterProxy methodArgumentCount = 6
		ifFalse:[^interpreterProxy primitiveFail].
	h := interpreterProxy stackIntegerValue: 0.
	w := interpreterProxy stackIntegerValue: 1.
	y := interpreterProxy stackIntegerValue: 2.
	x := interpreterProxy stackIntegerValue: 3.
	allowHardware := interpreterProxy booleanValueOf: (interpreterProxy stackValue: 4).
	allowSoftware := interpreterProxy booleanValueOf: (interpreterProxy stackValue: 5).
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxCreateRenderer(allowSoftware, allowHardware, x, y, w, h)'.
	result < 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 7.
	^interpreterProxy pushInteger: result.
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveCreateRendererFlags [
	| flags h w y x result  |
	<export: true>
	interpreterProxy methodArgumentCount = 5
		ifFalse:[^interpreterProxy primitiveFail].
	h := interpreterProxy stackIntegerValue: 0.
	w := interpreterProxy stackIntegerValue: 1.
	y := interpreterProxy stackIntegerValue: 2.
	x := interpreterProxy stackIntegerValue: 3.
	flags := interpreterProxy stackIntegerValue: 4.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxCreateRendererFlags(x, y, w, h, flags)'.
	result < 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 6.
	^interpreterProxy pushInteger: result.
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveDestroyRenderer [
	| handle result |
	<export: true>
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxDestroyRenderer(handle)' inSmalltalk:[false].
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 1. "pop arg; return rcvr"
]

{ #category : #'primitives-textures' }
B3DAcceleratorPlugin >> primitiveDestroyTexture [
	| handle result renderer |
	<export: true>
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	handle := interpreterProxy stackIntegerValue: 0.
	renderer := interpreterProxy stackIntegerValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxDestroyTexture(renderer, handle)' inSmalltalk:[false].
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 2. "pop arg; return rcvr"
]

{ #category : #'primitives-qwaq' }
B3DAcceleratorPlugin >> primitiveDrawArrays [
	"Primitive. Setup non-VBO client state and call drawRangeElements in one go to avoid
	garbage collection to move the buffers underneith."
	| maxIdx minIdx mode texCoords normals colors vertices handle vtxSize ok |
	<export: true>

	interpreterProxy methodArgumentCount = 8 ifFalse:
		[^interpreterProxy primitiveFail].

	maxIdx := interpreterProxy stackIntegerValue: 0.
	minIdx := interpreterProxy stackIntegerValue: 1.
	mode := interpreterProxy stackIntegerValue: 2.
	texCoords := interpreterProxy stackValue: 3.
	normals := interpreterProxy stackValue: 4.
	colors := interpreterProxy stackValue: 5.
	vertices := interpreterProxy stackValue: 6.
	handle := interpreterProxy stackIntegerValue: 7.

	self loadClientState: handle vertices: vertices colors: colors normals: normals texCoords: texCoords.
	interpreterProxy failed ifTrue:[^nil].
	doRangeChecks ifTrue:
		["Verify the vertex data itself"
		self checkVertexData: vertices.

		"Verify min-max range in bounds for given vertex array"
		vtxSize := (interpreterProxy slotSizeOf: vertices) / 3.
		(minIdx < 0 or:[minIdx > maxIdx or:[maxIdx > vtxSize]]) ifTrue:
			[interpreterProxy primitiveFail]].
	interpreterProxy failed ifFalse:
		[ok := self cCode: 'b3dDrawArrays(handle, mode, minIdx, maxIdx)' 
					inSmalltalk:[mode. false].
		 ok ifTrue:
			[interpreterProxy pop: interpreterProxy methodArgumentCount]].
	^nil "keep compiler quiet"

]

{ #category : #'primitives-qwaq' }
B3DAcceleratorPlugin >> primitiveDrawElements [
	"Primitive. Setup non-VBO client state and call drawElements in one go to avoid
	garbage collection to move the buffers underneith."
	| faces mode texCoords normals colors vertices handle ok facePtr faceSize |
	<export: true>
	<var: #facePtr type: 'unsigned int *'>

	interpreterProxy methodArgumentCount = 7 ifFalse:
		[^interpreterProxy primitiveFail].

	faces := interpreterProxy stackValue: 0.
	(interpreterProxy isWords: faces) ifFalse:
		[^interpreterProxy primitiveFail].
	faceSize := interpreterProxy slotSizeOf: faces.
	facePtr := interpreterProxy firstIndexableField: faces.

	mode := interpreterProxy stackIntegerValue: 1.
	texCoords := interpreterProxy stackValue: 2.
	normals := interpreterProxy stackValue: 3.
	colors := interpreterProxy stackValue: 4.
	vertices := interpreterProxy stackValue: 5.
	handle := interpreterProxy stackIntegerValue: 6.

	self loadClientState: handle vertices: vertices colors: colors normals: normals texCoords: texCoords.
	interpreterProxy failed ifTrue:[^nil].

	doRangeChecks ifTrue:
		["Verify the vertex data itself"
		self checkVertexData: vertices.
		"Change bounds range to make sure the data is valid"
		self checkBoundsRange: vertices faces: facePtr count: faceSize].

	interpreterProxy failed ifFalse:
		[ok := self cCode: 'b3dDrawElements(handle, mode, faceSize, facePtr)'
					inSmalltalk:[mode. facePtr. false].
		 ok ifTrue:
			[interpreterProxy pop: interpreterProxy methodArgumentCount]].
	^nil "keep compiler quiet"

]

{ #category : #'primitives-qwaq' }
B3DAcceleratorPlugin >> primitiveDrawRangeElements [
	"Primitive. Setup non-VBO client state and call drawRangeElements in one go to avoid
	garbage collection to move the buffers underneith."
	| faces maxIdx minIdx mode texCoords normals colors vertices handle vtxSize ok facePtr faceSize |
	<export: true>
	<var: #facePtr type: 'unsigned int *'>

	interpreterProxy methodArgumentCount = 9 ifFalse:
		[^interpreterProxy primitiveFail].

	faces := interpreterProxy stackValue: 0.
	(interpreterProxy isWords: faces) ifFalse:
		[^interpreterProxy primitiveFail].
	faceSize := interpreterProxy slotSizeOf: faces.
	facePtr := interpreterProxy firstIndexableField: faces.

	maxIdx := interpreterProxy stackIntegerValue: 1.
	minIdx := interpreterProxy stackIntegerValue: 2.
	mode := interpreterProxy stackIntegerValue: 3.
	texCoords := interpreterProxy stackValue: 4.
	normals := interpreterProxy stackValue: 5.
	colors := interpreterProxy stackValue: 6.
	vertices := interpreterProxy stackValue: 7.
	handle := interpreterProxy stackIntegerValue: 8.

	self loadClientState: handle vertices: vertices colors: colors normals: normals texCoords: texCoords.
	interpreterProxy failed ifTrue:[^nil].

	doRangeChecks ifTrue:
		["Verify the vertex data itself"
		self checkVertexData: vertices.
		"Change bounds range to make sure the data is valid"
		self checkBoundsRange: vertices faces: facePtr count: faceSize.
		"Verify min-max range in bounds for given vertex array"
		vtxSize := (interpreterProxy slotSizeOf: vertices) / 3.
		(minIdx < 0 or:[minIdx > maxIdx or:[maxIdx > vtxSize]]) ifTrue:
			[interpreterProxy primitiveFail]].

	interpreterProxy failed ifFalse:
		[ok := self cCode: 'b3dDrawRangeElements(handle, mode, minIdx, maxIdx, faceSize,  facePtr)'
					inSmalltalk:[mode. facePtr. false].
		ok ifTrue:
			[interpreterProxy pop: interpreterProxy methodArgumentCount]].
	^nil "keep compiler quiet"

]

{ #category : #'primitives-qwaq' }
B3DAcceleratorPlugin >> primitiveEnableDrawRangeChecks [
	"Primitive. Enable/disable draw (range) checks"
	| enabled |
	<export: true>
	interpreterProxy methodArgumentCount = 0 ifTrue:
		[interpreterProxy pop: 1.
		^interpreterProxy pushBool: doRangeChecks].
	interpreterProxy methodArgumentCount = 1 ifTrue:
		[enabled := interpreterProxy booleanValueOf: (interpreterProxy stackValue: 0).
		 interpreterProxy failed ifFalse:
			[doRangeChecks := enabled.
			^interpreterProxy pop: 1]]. "pop arg; return rcvr"
	^nil "keep compiler quiet"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveFinishRenderer [
	| handle result |
	<export: true>
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxFinishRenderer(handle)' inSmalltalk:[false].
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 1. "pop arg; return rcvr"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveFlushRenderer [
	| handle result |
	<export: true>
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxFlushRenderer(handle)' inSmalltalk:[false].
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 1. "pop arg; return rcvr"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveGetIntProperty [
	| handle prop result |
	<export: true>
	<inline: false>
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	prop := interpreterProxy stackIntegerValue: 0.
	handle := interpreterProxy stackIntegerValue: 1.
	result := self cCode:'b3dxGetIntProperty(handle, prop)'.
	interpreterProxy pop: 3. "args+rcvr"
	^interpreterProxy pushInteger: result
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveGetRendererColorMasks [
	| handle masks array |
	<export: true>
	<var: #masks declareC:'unsigned int masks[4]'>
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	array := interpreterProxy stackObjectValue: 0.
	handle := interpreterProxy stackIntegerValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	((interpreterProxy isArray: array)
	and: [(interpreterProxy slotSizeOf: array) = 4
	and: [self cCode:'b3dxGetRendererColorMasks(handle, masks)' inSmalltalk:[false]]])
		ifFalse:[^interpreterProxy primitiveFail].
	interpreterProxy pushRemappableOop: array.
	0 to: 3 do: [:i|
		interpreterProxy
			storePointer: i
			ofObject: interpreterProxy topRemappableOop
			withValue: (interpreterProxy positive32BitIntegerFor: (masks at: i))].
	interpreterProxy popRemappableOop.
	^interpreterProxy pop: 2 "pop args return receiver"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveGetRendererSurfaceDepth [
	| handle result |
	<export: true>
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxGetRendererSurfaceDepth(handle)' inSmalltalk:[-1].
	result < 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 2. "args+rcvr"
	^interpreterProxy pushInteger: result
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveGetRendererSurfaceHandle [
	| handle result |
	<export: true>
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxGetRendererSurfaceHandle(handle)' inSmalltalk:[-1].
	result < 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 2. "args+rcvr"
	^interpreterProxy pushInteger: result
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveGetRendererSurfaceHeight [
	| handle result |
	<export: true>
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxGetRendererSurfaceHeight(handle)' inSmalltalk:[-1].
	result < 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 2. "args+rcvr"
	^interpreterProxy pushInteger: result
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveGetRendererSurfaceWidth [
	| handle result |
	<export: true>
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxGetRendererSurfaceWidth(handle)' inSmalltalk:[-1].
	result < 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 2. "args+rcvr"
	^interpreterProxy pushInteger: result
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveIsOverlayRenderer [
	| handle result |
	<export: true>
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxIsOverlayRenderer(handle)' inSmalltalk:[false].
	interpreterProxy pop: 2. "args+rcvr"
	^interpreterProxy pushBool: result.
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveRenderVertexBuffer [
	| idxCount vtxCount vtxArray idxArray texHandle primType result flags handle |
	<export: true>
	<var: #idxArray type: 'int *'>
	<var: #vtxArray type: 'float *'>

	interpreterProxy methodArgumentCount = 8
		ifFalse:[^interpreterProxy primitiveFail].
	idxCount := interpreterProxy stackIntegerValue: 0.
	vtxCount := interpreterProxy stackIntegerValue: 2.
	texHandle := interpreterProxy stackIntegerValue: 4.
	flags := interpreterProxy stackIntegerValue: 5.
	primType := interpreterProxy stackIntegerValue: 6.
	handle := interpreterProxy stackIntegerValue: 7.

	interpreterProxy failed ifTrue:[^nil].
	vtxArray := self stackPrimitiveVertexArray: 3 ofSize: vtxCount.
	idxArray := self stackPrimitiveIndexArray: 1 ofSize: idxCount validate: true forVertexSize: vtxCount.

	(vtxArray == nil or:[idxArray == nil 
		or:[primType < 1 or:[primType > 6 
			or:[interpreterProxy failed]]]])
				ifTrue:[^interpreterProxy primitiveFail].

	result := self cCode:'b3dxRenderVertexBuffer(handle, primType, flags, texHandle, vtxArray, vtxCount, idxArray, idxCount)' inSmalltalk:[false].
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 8. "pop args; return rcvr"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveRendererVersion [
	<export: true>
	interpreterProxy methodArgumentCount = 0
		ifFalse:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 1.
	^interpreterProxy pushInteger: 1.
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveSetBufferRect [
	"Primitive. Set the buffer rectangle (e.g., the pixel area on screen) to use for this renderer.
	The viewport is positioned within the buffer rectangle."
	| h w y x result handle |
	<export: true>
	interpreterProxy methodArgumentCount = 5
		ifFalse:[^interpreterProxy primitiveFail].
	h := interpreterProxy stackIntegerValue: 0.
	w := interpreterProxy stackIntegerValue: 1.
	y := interpreterProxy stackIntegerValue: 2.
	x := interpreterProxy stackIntegerValue: 3.
	handle := interpreterProxy stackIntegerValue: 4.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxSetBufferRect(handle, x, y, w, h)'.
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 5. "pop args; return rcvr"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveSetFog [
	| result handle rgba density fogType stop start |
	<export: true>
	<var: #density type:'double'>
	<var: #start type: 'double'>
	<var: #stop type: 'double'>
	interpreterProxy methodArgumentCount = 6
		ifFalse:[^interpreterProxy primitiveFail].
	rgba := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 0).
	stop := interpreterProxy floatValueOf: (interpreterProxy stackValue: 1).
	start := interpreterProxy floatValueOf: (interpreterProxy stackValue: 2).
	density := interpreterProxy floatValueOf: (interpreterProxy stackValue: 3).
	fogType := interpreterProxy stackIntegerValue: 4.
	handle := interpreterProxy stackIntegerValue: 5.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxSetFog(handle, fogType, density, start, stop, rgba)'.
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 6. "pop args; return rcvr"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveSetIntProperty [
	| handle prop result value |
	<export: true>
	<inline: false>
	interpreterProxy methodArgumentCount = 3
		ifFalse:[^interpreterProxy primitiveFail].
	value := interpreterProxy stackIntegerValue: 0.
	prop := interpreterProxy stackIntegerValue: 1.
	handle := interpreterProxy stackIntegerValue: 2.
	result := self cCode:'b3dxSetIntProperty(handle, prop, value)'.
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 3. "args; return rcvr"

]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveSetLights [
	| lightArray lightCount light handle |
	<export: true>
	<inline: false>
	<var: #light type: 'void*'>

	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].

	lightArray := self stackLightArrayValue: 0.
	handle := interpreterProxy stackIntegerValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	(self b3dxDisableLights: handle)
		ifFalse:[^interpreterProxy primitiveFail].
	lightArray == nil ifTrue:[^nil].
	lightCount := interpreterProxy slotSizeOf: lightArray.
	"For each enabled light source"
	0 to: lightCount-1 do:[:i|
		light := self fetchLightSource: i ofObject: lightArray.
		(self cCode:'b3dxLoadLight(handle, i, light)' inSmalltalk:[false])
			ifFalse:[^interpreterProxy primitiveFail].
	].
	^interpreterProxy pop: 2. "args; return rcvr"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveSetMaterial [
	| material handle |
	<export: true>
	<inline: false>
	<var: #material type: 'void*'>

	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	material := self stackMaterialValue: 0.
	handle := interpreterProxy stackIntegerValue: 1.
	(self cCode:'b3dxLoadMaterial(handle, material)' inSmalltalk:[false])
		ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 2. "args; return rcvr"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveSetTransform [
	"Transform an entire vertex buffer using the supplied modelview and projection matrix."
	| projectionMatrix modelViewMatrix handle |
	<export: true>
	<inline: false>
	<var: #projectionMatrix declareC:'float *projectionMatrix'>
	<var: #modelViewMatrix declareC:'float *modelViewMatrix'>

	interpreterProxy methodArgumentCount = 3
		ifFalse:[^interpreterProxy primitiveFail].

	projectionMatrix := self stackMatrix: 0.
	modelViewMatrix := self stackMatrix: 1.
	handle := interpreterProxy stackIntegerValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	self cCode: 'b3dxSetTransform(handle, modelViewMatrix, projectionMatrix)'.
	^interpreterProxy pop: 3. "Leave rcvr on stack"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveSetVerboseLevel [
	| result level |
	<export: true>
	<inline: false>
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	level := interpreterProxy stackIntegerValue: 0.
	result := self cCode:'b3dxSetVerboseLevel(level)'.
	interpreterProxy pop: 2. "args+rcvr"
	^interpreterProxy pushInteger: result
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveSetViewport [
	| h w y x result handle |
	<export: true>
	interpreterProxy methodArgumentCount = 5
		ifFalse:[^interpreterProxy primitiveFail].
	h := interpreterProxy stackIntegerValue: 0.
	w := interpreterProxy stackIntegerValue: 1.
	y := interpreterProxy stackIntegerValue: 2.
	x := interpreterProxy stackIntegerValue: 3.
	handle := interpreterProxy stackIntegerValue: 4.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxSetViewport(handle, x, y, w, h)'.
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 5. "pop args; return rcvr"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveSwapRendererBuffers [
	| handle result |
	<export: true>
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxSwapRendererBuffers(handle)' inSmalltalk:[false].
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 1. "pop arg; return rcvr"
]

{ #category : #'primitives-textures' }
B3DAcceleratorPlugin >> primitiveTextureByteSex [
	| handle result renderer |
	<export: true>
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	handle := interpreterProxy stackIntegerValue: 0.
	renderer := interpreterProxy stackIntegerValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxTextureByteSex(renderer, handle)' inSmalltalk:[-1].
	result < 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 3.
	^interpreterProxy pushBool: result.
]

{ #category : #'primitives-textures' }
B3DAcceleratorPlugin >> primitiveTextureDepth [
	| handle result renderer |
	<export: true>
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	handle := interpreterProxy stackIntegerValue: 0.
	renderer := interpreterProxy stackIntegerValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxActualTextureDepth(renderer, handle)' inSmalltalk:[-1].
	result < 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 3.
	^interpreterProxy pushInteger: result.
]

{ #category : #'primitives-textures' }
B3DAcceleratorPlugin >> primitiveTextureGetColorMasks [
	| handle masks array renderer |
	<export: true>
	<var: #masks declareC:'unsigned int masks[4]'>
	interpreterProxy methodArgumentCount = 3
		ifFalse:[^interpreterProxy primitiveFail].
	array := interpreterProxy stackObjectValue: 0.
	handle := interpreterProxy stackIntegerValue: 1.
	renderer := interpreterProxy stackIntegerValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	((interpreterProxy isArray: array)
	 and: [(interpreterProxy slotSizeOf: array) = 4
	 and: [self cCode:'b3dxTextureColorMasks(renderer, handle, masks)' inSmalltalk:[false]]])
		ifFalse:[^interpreterProxy primitiveFail].
	interpreterProxy pushRemappableOop: array.
	0 to: 3 do: [:i|
		interpreterProxy
			storePointer: i
			ofObject: interpreterProxy topRemappableOop
			withValue: (interpreterProxy positive32BitIntegerFor: (masks at: i))].
	interpreterProxy popRemappableOop.
	^interpreterProxy pop: 3 "pop args return receiver"
]

{ #category : #'primitives-textures' }
B3DAcceleratorPlugin >> primitiveTextureSurfaceHandle [
	| handle result renderer |
	<export: true>
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	handle := interpreterProxy stackIntegerValue: 0.
	renderer := interpreterProxy stackIntegerValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxTextureSurfaceHandle(renderer, handle)' inSmalltalk:[-1].
	result < 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 3.
	^interpreterProxy pushInteger: result
]

{ #category : #'primitives-textures' }
B3DAcceleratorPlugin >> primitiveTextureUpload [
	| h w d result form bits ppw bitsPtr handle renderer |
	<export: true>
	<var: #bitsPtr type: 'void*'>
	interpreterProxy methodArgumentCount = 3
		ifFalse:[^interpreterProxy primitiveFail].
	form := interpreterProxy stackValue: 0.
	((interpreterProxy isPointers: form) and:[(interpreterProxy slotSizeOf: form) >= 4])
		ifFalse:[^interpreterProxy primitiveFail].
	bits := interpreterProxy fetchPointer: 0 ofObject: form.
	w := interpreterProxy fetchInteger: 1 ofObject: form.
	h := interpreterProxy fetchInteger: 2 ofObject: form.
	d := interpreterProxy fetchInteger: 3 ofObject: form.
	ppw := 32 // d.
	(interpreterProxy isWords: bits)
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy slotSizeOf: bits) = (w + ppw - 1 // ppw * h)
		ifFalse:[^interpreterProxy primitiveFail].
	bitsPtr := interpreterProxy firstIndexableField: bits.
	handle := interpreterProxy stackIntegerValue: 1.
	renderer := interpreterProxy stackIntegerValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode:'b3dxUploadTexture(renderer, handle, w, h, d, bitsPtr)' inSmalltalk:[false].
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 3. "args; return rcvr"
]

{ #category : #'initialize-release' }
B3DAcceleratorPlugin >> shutdownModule [
	<export: true>
	^self b3dxShutdown
]

{ #category : #'primitive support' }
B3DAcceleratorPlugin >> stackLightArrayValue: stackIndex [
	"Load an Array of B3DPrimitiveLights from the given stack index"
	| oop array arraySize |
	<inline: false>
	array := interpreterProxy stackObjectValue: stackIndex.
	array = nil ifTrue:[^nil]. "really??"
	array = interpreterProxy nilObject ifTrue:[^nil].
	(interpreterProxy isArray: array)
		ifFalse:[^interpreterProxy primitiveFail].
	arraySize := interpreterProxy slotSizeOf: array.
	0 to: arraySize-1 do:[:i|
		oop := interpreterProxy fetchPointer: i ofObject: array.
		((interpreterProxy isWords: oop) and:[(interpreterProxy slotSizeOf: oop) = 32])
			ifFalse:[^interpreterProxy primitiveFail].
	].
	^array
]

{ #category : #'primitive support' }
B3DAcceleratorPlugin >> stackMaterialValue: stackIndex [
	"Load a B3DMaterial from the given stack index"
	| oop |
	<inline: false>
	<returnTypeC:'void *'>
	oop := interpreterProxy stackObjectValue: stackIndex.
	oop = nil ifTrue:[^nil].
	oop = interpreterProxy nilObject ifTrue:[^nil].
	((interpreterProxy isWords: oop) and:[(interpreterProxy slotSizeOf: oop) =  17])
		ifTrue:[^interpreterProxy firstIndexableField: oop].
	^nil
]

{ #category : #'primitive support' }
B3DAcceleratorPlugin >> stackMatrix: index [
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

{ #category : #'primitive support' }
B3DAcceleratorPlugin >> stackPrimitiveIndexArray: stackIndex ofSize: nItems validate: aBool forVertexSize: maxIndex [
	"Load a primitive index array from the interpreter stack.
	If aBool is true then check that all the indexes are in the range (1,maxIndex).
	Return a pointer to the index data if successful, nil otherwise."
	| oop oopSize idxPtr index |
	<inline: false>
	<returnTypeC:'void*'>
	<var: #idxPtr declareC:'int *idxPtr'>

	oop := interpreterProxy stackObjectValue: stackIndex.
	oop = nil ifTrue:[^nil].
	(interpreterProxy isWords: oop) ifFalse:[^nil].
 	oopSize := interpreterProxy slotSizeOf: oop.
	oopSize < nItems ifTrue:[^nil].
	idxPtr := self cCoerce: (interpreterProxy firstIndexableField: oop) to:'int *'.
	aBool ifTrue:[
		0 to: nItems-1 do:[:i|
			index := idxPtr at: i.
			(index < 0 or:[index > maxIndex]) ifTrue:[^nil]]].
	^idxPtr
]

{ #category : #'primitive support' }
B3DAcceleratorPlugin >> stackPrimitiveVertexArray: index ofSize: nItems [
	"Load a primitive vertex array from the interpreter stack.
	Return a pointer to the vertex data if successful, nil otherwise."
	| oop oopSize |
	<inline: false>
	<returnTypeC:'void*'>
	oop := interpreterProxy stackObjectValue: index.
	oop = nil ifTrue:[^nil].
	(interpreterProxy isWords: oop) ifTrue:[
 		oopSize := interpreterProxy slotSizeOf: oop.
		(oopSize >= nItems * 16 and:[oopSize \\ 16 = 0])
			ifTrue:[^interpreterProxy firstIndexableField: oop]].
	^nil
]
