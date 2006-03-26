"
B3DAcceleratorPlugin translate
"
Class {
	#name : #B3DAcceleratorPlugin,
	#superclass : #InterpreterPlugin,
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

{ #category : #'primitive support' }
B3DAcceleratorPlugin >> fetchLightSource: index ofObject: anArray [
	"Fetch the primitive light source from the given array.
	Note: No checks are done within here - that happened in stackLightArrayValue:"
	| lightOop |
	self inline: true.
	self returnTypeC:'void*'.
	lightOop _ interpreterProxy fetchPointer: index ofObject: anArray.
	^interpreterProxy firstIndexableField: lightOop
]

{ #category : #'initialize-release' }
B3DAcceleratorPlugin >> initialiseModule [
	self export: true.
	^self b3dxInitialize
]

{ #category : #'primitives-textures' }
B3DAcceleratorPlugin >> primitiveAllocateTexture [
	| h w d result renderer |
	self export: true.
	interpreterProxy methodArgumentCount = 4
		ifFalse:[^interpreterProxy primitiveFail].
	h _ interpreterProxy stackIntegerValue: 0.
	w _ interpreterProxy stackIntegerValue: 1.
	d _ interpreterProxy stackIntegerValue: 2.
	renderer _ interpreterProxy stackIntegerValue: 3.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxAllocateTexture(renderer, w, h, d)' inSmalltalk:[-1].
	result = -1 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 5. "args+rcvr"
	^interpreterProxy pushInteger: result.
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveClearDepthBuffer [
	| result handle |
	self export: true.
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle _ interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxClearDepthBuffer(handle)'.
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 1. "pop args; return rcvr"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveClearViewport [
	| result handle pv rgba |
	self export: true.
	interpreterProxy methodArgumentCount = 3
		ifFalse:[^interpreterProxy primitiveFail].
	pv _ interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 0).
	rgba _ interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 1).
	handle _ interpreterProxy stackIntegerValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxClearViewport(handle, rgba, pv)'.
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 3. "pop args; return rcvr"
]

{ #category : #'primitives-textures' }
B3DAcceleratorPlugin >> primitiveCompositeTexture [
	| result translucent y x w h texHandle rendererHandle |
	self export: true.
	interpreterProxy methodArgumentCount = 7
		ifFalse:[^interpreterProxy primitiveFail].
	translucent _ interpreterProxy booleanValueOf: (interpreterProxy stackValue: 0).
	h _ interpreterProxy stackIntegerValue: 1.
	w _ interpreterProxy stackIntegerValue: 2.
	y _ interpreterProxy stackIntegerValue: 3.
	x _ interpreterProxy stackIntegerValue: 4.
	texHandle _ interpreterProxy stackIntegerValue: 5.
	rendererHandle _ interpreterProxy stackIntegerValue: 6.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxCompositeTexture(rendererHandle, texHandle, x, y, w, h, translucent)' inSmalltalk:[false].
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 7. "args"

]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveCreateRenderer [
	"NOTE: This primitive is obsolete but should be supported for older images"
	| h w y x result allowHardware allowSoftware |
	self export: true.
	interpreterProxy methodArgumentCount = 6
		ifFalse:[^interpreterProxy primitiveFail].
	h _ interpreterProxy stackIntegerValue: 0.
	w _ interpreterProxy stackIntegerValue: 1.
	y _ interpreterProxy stackIntegerValue: 2.
	x _ interpreterProxy stackIntegerValue: 3.
	allowHardware _ interpreterProxy booleanValueOf: (interpreterProxy stackValue: 4).
	allowSoftware _ interpreterProxy booleanValueOf: (interpreterProxy stackValue: 5).
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxCreateRenderer(allowSoftware, allowHardware, x, y, w, h)'.
	result < 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 7.
	^interpreterProxy pushInteger: result.
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveCreateRendererFlags [
	| flags h w y x result  |
	self export: true.
	interpreterProxy methodArgumentCount = 5
		ifFalse:[^interpreterProxy primitiveFail].
	h _ interpreterProxy stackIntegerValue: 0.
	w _ interpreterProxy stackIntegerValue: 1.
	y _ interpreterProxy stackIntegerValue: 2.
	x _ interpreterProxy stackIntegerValue: 3.
	flags _ interpreterProxy stackIntegerValue: 4.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxCreateRendererFlags(x, y, w, h, flags)'.
	result < 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 6.
	^interpreterProxy pushInteger: result.
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveDestroyRenderer [
	| handle result |
	self export: true.
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle _ interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxDestroyRenderer(handle)' inSmalltalk:[false].
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 1. "pop arg; return rcvr"
]

{ #category : #'primitives-textures' }
B3DAcceleratorPlugin >> primitiveDestroyTexture [
	| handle result renderer |
	self export: true.
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	handle _ interpreterProxy stackIntegerValue: 0.
	renderer _ interpreterProxy stackIntegerValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxDestroyTexture(renderer, handle)' inSmalltalk:[false].
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 2. "pop arg; return rcvr"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveFinishRenderer [
	| handle result |
	self export: true.
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle _ interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxFinishRenderer(handle)' inSmalltalk:[false].
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 1. "pop arg; return rcvr"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveFlushRenderer [
	| handle result |
	self export: true.
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle _ interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxFlushRenderer(handle)' inSmalltalk:[false].
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 1. "pop arg; return rcvr"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveGetIntProperty [
	| handle prop result |
	self export: true.
	self inline: false.
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	prop _ interpreterProxy stackIntegerValue: 0.
	handle _ interpreterProxy stackIntegerValue: 1.
	result _ self cCode:'b3dxGetIntProperty(handle, prop)'.
	interpreterProxy pop: 3. "args+rcvr"
	^interpreterProxy pushInteger: result
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveGetRendererColorMasks [
	| handle result masks array arrayOop |
	self export: true.
	self var: #masks declareC:'int masks[4]'.
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	array _ interpreterProxy stackObjectValue: 0.
	handle _ interpreterProxy stackIntegerValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy fetchClassOf: array) = interpreterProxy classArray
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy slotSizeOf: array) = 4
		ifFalse:[^interpreterProxy primitiveFail].
	result _ self cCode:'b3dxGetRendererColorMasks(handle, masks)' inSmalltalk:[false].
	result ifFalse:[^interpreterProxy primitiveFail].
	arrayOop _ array.
	0 to: 3 do:[:i|
		interpreterProxy pushRemappableOop: arrayOop.
		result _ interpreterProxy positive32BitIntegerFor: (masks at: i).
		arrayOop _ interpreterProxy popRemappableOop.
		interpreterProxy storePointer: i ofObject: arrayOop withValue: result].
	^interpreterProxy pop: 2. "pop args return receiver"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveGetRendererSurfaceDepth [
	| handle result |
	self export: true.
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle _ interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxGetRendererSurfaceDepth(handle)' inSmalltalk:[-1].
	result < 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 2. "args+rcvr"
	^interpreterProxy pushInteger: result
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveGetRendererSurfaceHandle [
	| handle result |
	self export: true.
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle _ interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxGetRendererSurfaceHandle(handle)' inSmalltalk:[-1].
	result < 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 2. "args+rcvr"
	^interpreterProxy pushInteger: result
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveGetRendererSurfaceHeight [
	| handle result |
	self export: true.
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle _ interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxGetRendererSurfaceHeight(handle)' inSmalltalk:[-1].
	result < 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 2. "args+rcvr"
	^interpreterProxy pushInteger: result
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveGetRendererSurfaceWidth [
	| handle result |
	self export: true.
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle _ interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxGetRendererSurfaceWidth(handle)' inSmalltalk:[-1].
	result < 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 2. "args+rcvr"
	^interpreterProxy pushInteger: result
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveIsOverlayRenderer [
	| handle result |
	self export: true.
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle _ interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxIsOverlayRenderer(handle)' inSmalltalk:[false].
	interpreterProxy pop: 2. "args+rcvr"
	^interpreterProxy pushBool: result.
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveRenderVertexBuffer [
	| idxCount vtxCount vtxArray idxArray texHandle primType result flags handle |
	self export: true.
	self var: #idxArray type: 'int *'.
	self var: #vtxArray type: 'float *'.

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
	self export: true.
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
	self export: true.
	interpreterProxy methodArgumentCount = 5
		ifFalse:[^interpreterProxy primitiveFail].
	h _ interpreterProxy stackIntegerValue: 0.
	w _ interpreterProxy stackIntegerValue: 1.
	y _ interpreterProxy stackIntegerValue: 2.
	x _ interpreterProxy stackIntegerValue: 3.
	handle _ interpreterProxy stackIntegerValue: 4.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxSetBufferRect(handle, x, y, w, h)'.
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 5. "pop args; return rcvr"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveSetFog [
	| result handle rgba density fogType stop start |
	self export: true.
	self var: #density type:'double'.
	self var: #start type: 'double'.
	self var: #stop type: 'double'.
	interpreterProxy methodArgumentCount = 6
		ifFalse:[^interpreterProxy primitiveFail].
	rgba _ interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 0).
	stop _ interpreterProxy floatValueOf: (interpreterProxy stackValue: 1).
	start _ interpreterProxy floatValueOf: (interpreterProxy stackValue: 2).
	density _ interpreterProxy floatValueOf: (interpreterProxy stackValue: 3).
	fogType _ interpreterProxy stackIntegerValue: 4.
	handle _ interpreterProxy stackIntegerValue: 5.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxSetFog(handle, fogType, density, start, stop, rgba)'.
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 6. "pop args; return rcvr"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveSetIntProperty [
	| handle prop result value |
	self export: true.
	self inline: false.
	interpreterProxy methodArgumentCount = 3
		ifFalse:[^interpreterProxy primitiveFail].
	value _ interpreterProxy stackIntegerValue: 0.
	prop _ interpreterProxy stackIntegerValue: 1.
	handle _ interpreterProxy stackIntegerValue: 2.
	result _ self cCode:'b3dxSetIntProperty(handle, prop, value)'.
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 3. "args; return rcvr"

]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveSetLights [
	| lightArray lightCount light handle |
	self export: true.
	self inline: false.
	self var: #light type: 'void*'.

	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].

	lightArray _ self stackLightArrayValue: 0.
	handle _ interpreterProxy stackIntegerValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	(self b3dxDisableLights: handle)
		ifFalse:[^interpreterProxy primitiveFail].
	lightArray == nil ifTrue:[^nil].
	lightCount _ interpreterProxy slotSizeOf: lightArray.
	"For each enabled light source"
	0 to: lightCount-1 do:[:i|
		light _ self fetchLightSource: i ofObject: lightArray.
		(self cCode:'b3dxLoadLight(handle, i, light)' inSmalltalk:[false])
			ifFalse:[^interpreterProxy primitiveFail].
	].
	^interpreterProxy pop: 2. "args; return rcvr"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveSetMaterial [
	| material handle |
	self export: true.
	self inline: false.
	self var: #material type: 'void*'.

	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	material _ self stackMaterialValue: 0.
	handle _ interpreterProxy stackIntegerValue: 1.
	(self cCode:'b3dxLoadMaterial(handle, material)' inSmalltalk:[false])
		ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 2. "args; return rcvr"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveSetTransform [
	"Transform an entire vertex buffer using the supplied modelview and projection matrix."
	| projectionMatrix modelViewMatrix handle |
	self export: true.
	self inline: false.
	self var: #projectionMatrix declareC:'float *projectionMatrix'.
	self var: #modelViewMatrix declareC:'float *modelViewMatrix'.

	interpreterProxy methodArgumentCount = 3
		ifFalse:[^interpreterProxy primitiveFail].

	projectionMatrix _ self stackMatrix: 0.
	modelViewMatrix _ self stackMatrix: 1.
	handle _ interpreterProxy stackIntegerValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	self cCode: 'b3dxSetTransform(handle, modelViewMatrix, projectionMatrix)'.
	^interpreterProxy pop: 3. "Leave rcvr on stack"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveSetVerboseLevel [
	| result level |
	self export: true.
	self inline: false.
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	level _ interpreterProxy stackIntegerValue: 0.
	result _ self cCode:'b3dxSetVerboseLevel(level)'.
	interpreterProxy pop: 2. "args+rcvr"
	^interpreterProxy pushInteger: result
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveSetViewport [
	| h w y x result handle |
	self export: true.
	interpreterProxy methodArgumentCount = 5
		ifFalse:[^interpreterProxy primitiveFail].
	h _ interpreterProxy stackIntegerValue: 0.
	w _ interpreterProxy stackIntegerValue: 1.
	y _ interpreterProxy stackIntegerValue: 2.
	x _ interpreterProxy stackIntegerValue: 3.
	handle _ interpreterProxy stackIntegerValue: 4.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxSetViewport(handle, x, y, w, h)'.
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 5. "pop args; return rcvr"
]

{ #category : #'primitives-renderer' }
B3DAcceleratorPlugin >> primitiveSwapRendererBuffers [
	| handle result |
	self export: true.
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle _ interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxSwapRendererBuffers(handle)' inSmalltalk:[false].
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 1. "pop arg; return rcvr"
]

{ #category : #'primitives-textures' }
B3DAcceleratorPlugin >> primitiveTextureByteSex [
	| handle result renderer |
	self export: true.
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	handle _ interpreterProxy stackIntegerValue: 0.
	renderer _ interpreterProxy stackIntegerValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxTextureByteSex(renderer, handle)' inSmalltalk:[-1].
	result < 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 3.
	^interpreterProxy pushBool: result.
]

{ #category : #'primitives-textures' }
B3DAcceleratorPlugin >> primitiveTextureDepth [
	| handle result renderer |
	self export: true.
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	handle _ interpreterProxy stackIntegerValue: 0.
	renderer _ interpreterProxy stackIntegerValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxActualTextureDepth(renderer, handle)' inSmalltalk:[-1].
	result < 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 3.
	^interpreterProxy pushInteger: result.
]

{ #category : #'primitives-textures' }
B3DAcceleratorPlugin >> primitiveTextureGetColorMasks [
	| handle result masks array renderer arrayOop |
	self export: true.
	self var: #masks declareC:'int masks[4]'.
	interpreterProxy methodArgumentCount = 3
		ifFalse:[^interpreterProxy primitiveFail].
	array _ interpreterProxy stackObjectValue: 0.
	handle _ interpreterProxy stackIntegerValue: 1.
	renderer _ interpreterProxy stackIntegerValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy fetchClassOf: array) = interpreterProxy classArray
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy slotSizeOf: array) = 4
		ifFalse:[^interpreterProxy primitiveFail].
	result _ self cCode:'b3dxTextureColorMasks(renderer, handle, masks)' inSmalltalk:[false].
	result ifFalse:[^interpreterProxy primitiveFail].
	arrayOop _ array.
	0 to: 3 do:[:i|
		interpreterProxy pushRemappableOop: arrayOop.
		result _ interpreterProxy positive32BitIntegerFor: (masks at: i).
		arrayOop _ interpreterProxy popRemappableOop.
		interpreterProxy storePointer: i ofObject: arrayOop withValue: result].
	^interpreterProxy pop: 3. "pop args return receiver"
]

{ #category : #'primitives-textures' }
B3DAcceleratorPlugin >> primitiveTextureSurfaceHandle [
	| handle result renderer |
	self export: true.
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	handle _ interpreterProxy stackIntegerValue: 0.
	renderer _ interpreterProxy stackIntegerValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxTextureSurfaceHandle(renderer, handle)' inSmalltalk:[-1].
	result < 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 3.
	^interpreterProxy pushInteger: result
]

{ #category : #'primitives-textures' }
B3DAcceleratorPlugin >> primitiveTextureUpload [
	| h w d result form bits ppw bitsPtr handle renderer |
	self export: true.
	self var: #bitsPtr type: 'void*'.
	interpreterProxy methodArgumentCount = 3
		ifFalse:[^interpreterProxy primitiveFail].
	form _ interpreterProxy stackValue: 0.
	((interpreterProxy isPointers: form) and:[(interpreterProxy slotSizeOf: form) >= 4])
		ifFalse:[^interpreterProxy primitiveFail].
	bits _ interpreterProxy fetchPointer: 0 ofObject: form.
	w _ interpreterProxy fetchInteger: 1 ofObject: form.
	h _ interpreterProxy fetchInteger: 2 ofObject: form.
	d _ interpreterProxy fetchInteger: 3 ofObject: form.
	ppw _ 32 // d.
	(interpreterProxy isWords: bits)
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy slotSizeOf: bits) = (w + ppw - 1 // ppw * h)
		ifFalse:[^interpreterProxy primitiveFail].
	bitsPtr _ interpreterProxy firstIndexableField: bits.
	handle _ interpreterProxy stackIntegerValue: 1.
	renderer _ interpreterProxy stackIntegerValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	result _ self cCode:'b3dxUploadTexture(renderer, handle, w, h, d, bitsPtr)' inSmalltalk:[false].
	result ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 3. "args; return rcvr"
]

{ #category : #'initialize-release' }
B3DAcceleratorPlugin >> shutdownModule [
	self export: true.
	^self b3dxShutdown
]

{ #category : #'primitive support' }
B3DAcceleratorPlugin >> stackLightArrayValue: stackIndex [
	"Load an Array of B3DPrimitiveLights from the given stack index"
	| oop array arraySize |
	self inline: false.
	array := interpreterProxy stackObjectValue: stackIndex.
	array = nil ifTrue:[^nil].
	array = interpreterProxy nilObject ifTrue:[^nil].
	(interpreterProxy fetchClassOf: array) = interpreterProxy classArray
		ifFalse:[^interpreterProxy primitiveFail].
	arraySize := interpreterProxy slotSizeOf: array.
	0 to: arraySize-1 do:[:i|
		oop := interpreterProxy fetchPointer: i ofObject: array.
		(interpreterProxy isIntegerObject: oop)
			ifTrue:[^interpreterProxy primitiveFail].
		((interpreterProxy isWords: oop) and:[(interpreterProxy slotSizeOf: oop) = 32])
			ifFalse:[^interpreterProxy primitiveFail].
	].
	^array
]

{ #category : #'primitive support' }
B3DAcceleratorPlugin >> stackMaterialValue: stackIndex [
	"Load a B3DMaterial from the given stack index"
	| oop |
	self inline: false.
	self returnTypeC:'void *'.
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
	self inline: false.
	self returnTypeC:'void*'.
	oop _ interpreterProxy stackObjectValue: index.
	oop = nil ifTrue:[^nil].
	oop = interpreterProxy nilObject ifTrue:[^nil].
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
	self inline: false.
	self returnTypeC:'void*'.
	self var: #idxPtr declareC:'int *idxPtr'.

	oop _ interpreterProxy stackObjectValue: stackIndex.
	oop = nil ifTrue:[^nil].
	(interpreterProxy isWords: oop) ifFalse:[^nil].
 	oopSize _ interpreterProxy slotSizeOf: oop.
	oopSize < nItems ifTrue:[^nil].
	idxPtr _ self cCoerce: (interpreterProxy firstIndexableField: oop) to:'int *'.
	aBool ifTrue:[
		0 to: nItems-1 do:[:i|
			index _ idxPtr at: i.
			(index < 0 or:[index > maxIndex]) ifTrue:[^nil]]].
	^idxPtr
]

{ #category : #'primitive support' }
B3DAcceleratorPlugin >> stackPrimitiveVertex: index [
	"Load a primitive vertex from the interpreter stack.
	Return a pointer to the vertex data if successful, nil otherwise."
	| oop |
	self inline: false.
	self returnTypeC:'void*'.
	oop := interpreterProxy stackObjectValue: index.
	oop = nil ifTrue:[^nil].
	((interpreterProxy isWords: oop) and:[(interpreterProxy slotSizeOf: oop) = 16])
		ifTrue:[^interpreterProxy firstIndexableField: oop].
	^nil
]

{ #category : #'primitive support' }
B3DAcceleratorPlugin >> stackPrimitiveVertexArray: index ofSize: nItems [
	"Load a primitive vertex array from the interpreter stack.
	Return a pointer to the vertex data if successful, nil otherwise."
	| oop oopSize |
	self inline: false.
	self returnTypeC:'void*'.
	oop := interpreterProxy stackObjectValue: index.
	oop = nil ifTrue:[^nil].
	(interpreterProxy isWords: oop) ifTrue:[
 		oopSize := interpreterProxy slotSizeOf: oop.
		(oopSize >= nItems * 16 and:[oopSize \\ 16 = 0])
			ifTrue:[^interpreterProxy firstIndexableField: oop]].
	^nil
]
