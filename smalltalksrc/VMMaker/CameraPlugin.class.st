Class {
	#name : #CameraPlugin,
	#superclass : #InterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
CameraPlugin class >> hasHeaderFile [

	^true
]

{ #category : #primitives }
CameraPlugin >> primCameraName [
	"Get the name for the camera with the given number. Fail if the camera number is greater than the number of available cameras."

	| cameraNum nameStr count resultOop dst |
	<export: true>
	<var: 'nameStr' declareC: 'char* nameStr'>
	<var: 'dst' declareC: 'char* dst'>

	cameraNum := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue: [^ 0].

	nameStr := self cCode: 'CameraName(cameraNum)'.
	nameStr = nil ifTrue: [
		interpreterProxy success: false.
		^ 0].

	count := self cCode: '(int) strlen(nameStr)'.
	resultOop := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: count.
	dst := self cCoerce: (interpreterProxy firstIndexableField: resultOop) to: 'char *'.
	0 to: count - 1 do: [:i | dst at: i put: (nameStr at: i)].

	interpreterProxy pop: 2 thenPush: resultOop.  "pop arg and rcvr, push result"
	^ 0

]

{ #category : #primitives }
CameraPlugin >> primCloseCamera [
	"Close the camera. Do nothing if it was not open."

	| cameraNum |
	<export: true>
	cameraNum := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue: [^ 0].

	self cCode: 'CameraClose(cameraNum)'.

	interpreterProxy pop: 1.  "pop arg, leave rcvr on stack"
	^ 0

]

{ #category : #primitives }
CameraPlugin >> primFrameExtent [
	"Answer the frame extent of the given camera, or zero if the camera is not open. The extent is 16 bits of width and height packed into a single integer."

	| cameraNum |
	<export: true>
	cameraNum := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifFalse:
		[interpreterProxy methodReturnInteger: (self CameraExtent: cameraNum)]
]

{ #category : #primitives }
CameraPlugin >> primGetFrame [
	"Copy a camera frame into the given Bitmap. The Bitmap should be for a Form of depth 32 that is the same width and height as the current camera frame. Fail if the camera is not open or if the bitmap is not the right size. If successful, answer the number of frames received from the camera since the last call. If this is zero, then there has been no change."

	| cameraNum bitmapOop bitmap pixCount result |
	<export: true>
	<var: 'bitmap' type: #'unsigned char *'>

	cameraNum := interpreterProxy stackIntegerValue: 1.
	bitmapOop := interpreterProxy stackValue: 0.
	interpreterProxy success: (interpreterProxy isWords: bitmapOop).
	interpreterProxy failed ifTrue:
		[^ 0].
	bitmap := self cCoerce: (interpreterProxy firstIndexableField: bitmapOop) to: #'unsigned char *'.
	pixCount := interpreterProxy stSizeOf: bitmapOop.

	result := self Camera: cameraNum Get: bitmap Frame: pixCount.
	result < 0 ifTrue:
		[^interpreterProxy primitiveFail].

	interpreterProxy methodReturnInteger: result
]

{ #category : #primitives }
CameraPlugin >> primGetParam [
	"Answer the given integer parameter of the given camera."

	| cameraNum paramNum |
	<export: true>
	cameraNum := interpreterProxy stackIntegerValue: 1.
	paramNum := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifFalse:
		[interpreterProxy methodReturnInteger: (self Camera: cameraNum GetParam: paramNum)]
]

{ #category : #primitives }
CameraPlugin >> primOpenCamera [
	"Open a camera. Takes one argument, the index of the device to open."

	| cameraNum desiredFrameWidth desiredFrameHeight ok |
	<export: true>

	cameraNum := interpreterProxy stackIntegerValue: 2.
	desiredFrameWidth := interpreterProxy stackIntegerValue: 1.
	desiredFrameHeight := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue: [^ 0].

	ok := self cCode: 'CameraOpen(cameraNum, desiredFrameWidth, desiredFrameHeight)'.
	ok = 0 ifTrue: [
		interpreterProxy success: false.
		^ 0].

	interpreterProxy pop: 3.  "pop args, leave rcvr on stack"
	^ 0

]
