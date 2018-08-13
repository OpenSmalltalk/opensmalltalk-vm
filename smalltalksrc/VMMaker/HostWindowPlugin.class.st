"
This plugin provides access to creating, destroying and manipulating host OS windows. See the Cross/plugins/HostWindowPlugin/HostWindowPlugin.h file for documented declarations for the C functions you need to provide.
"
Class {
	#name : #HostWindowPlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
HostWindowPlugin class >> hasHeaderFile [
	^true
]

{ #category : #translation }
HostWindowPlugin class >> requiresPlatformFiles [
	^true
]

{ #category : #support }
HostWindowPlugin >> pointFromCompactPointEncoding: encodedPoint [
	"Answer a point from one of the funky encoded x,y position/size values the VM uses.
	 The issue here is that the values can be negative, each value being in the range -32768 to 32767"
	<inline: #always>
	^interpreterProxy
		makePointwithxValue: (self cCoerceSimple: encodedPoint >> 16 to: #short)
		yValue: (self cCoerceSimple: (encodedPoint bitAnd: 16rFFFF) to: #short)
]

{ #category : #'system primitives' }
HostWindowPlugin >> primitiveCloseHostWindow: windowIndex [
"Close a host window. windowIndex is the SmallInt handle returned previously by primitiveCreateHostWindow. Fail if the index is invalid or the platform code fails"
	| ok |
	self primitive: 'primitiveCloseHostWindow'
		parameters: #(SmallInteger).
	
	ok := self closeWindow: windowIndex.
	ok ifFalse:[interpreterProxy primitiveFail].

]

{ #category : #'system primitives' }
HostWindowPlugin >> primitiveCreateHostWindowWidth: w height: h originX: x y: y attributes: list [
"Create a host window of width 'w' pixels, height 'h' with the origin of the
user area at 'x@y' from the topleft corner of the screen.
Return the SmallInt value of the internal index to the window description block
- which is whatever the host platform code needs it to be."
	| windowIndex listLength |
	self primitive: 'primitiveCreateHostWindow'
		parameters: #(SmallInteger SmallInteger SmallInteger SmallInteger ByteArray).

	"createWindowWidthheightoriginXyattr(int w, int h, int x, int y, int*
attributeList) must create a hostwindow and return an integer index. Return 0 if
failed"
	listLength := interpreterProxy slotSizeOf: list cPtrAsOop.
	windowIndex := self createWindowWidth: w height: h originX: x y: y attr: list
length: listLength.
	windowIndex > 0 ifTrue:[^windowIndex asSmallIntegerObj]
		ifFalse:[^interpreterProxy primitiveFail].

]

{ #category : #'system primitives' }
HostWindowPlugin >> primitiveHostWindowIcon: id path: pathString [
	"Set the icon of the window by fetching the logo in given path. Fail if the windowIndex is invalid or the platform routine returns -1 to indicate failure"
	| res pathLength |
	self primitive: 'primitiveHostWindowIcon'
		parameters: #(SmallInteger ByteArray).
	pathLength := interpreterProxy slotSizeOf: pathString cPtrAsOop.
	res := self cCode: 'ioSetIconOfWindow(id, pathString, pathLength)'.
	res = 0 ifTrue: [^ self ].
	res = -1 ifTrue: [^ interpreterProxy primitiveFailFor: PrimErrBadArgument ].
	"As the GetLastError function can return 0, but it is still an error, 1 is added to all the GetLastError error codes."
	^ interpreterProxy primitiveFail
]

{ #category : #'system primitives' }
HostWindowPlugin >> primitiveHostWindowPosition: windowIndex [ 
	"Return the origin position of the user area of the window in pixels from the topleft corner of the screen. Fail if the windowIndex is invalid or the platform routine returns -1 to indicate failure"
	| pos |
	self primitive: 'primitiveHostWindowPosition'
		parameters: #(SmallInteger ).
	pos := self ioPositionOfWindow: windowIndex.
	pos = -1 ifTrue:
		[^interpreterProxy primitiveFail].
	^self pointFromCompactPointEncoding: pos
]

{ #category : #'system primitives' }
HostWindowPlugin >> primitiveHostWindowPositionSet: windowIndex x: x y: y [
	"Set the origin position of the user area of the window in pixels from the topleft corner of the screen- return the position actually set by the OS/GUI/window manager. Fail if the windowIndex is invalid or the platform routine returns -1 to indicate failure"
	| pos |
	self primitive: 'primitiveHostWindowPositionSet'
		parameters: #(SmallInteger SmallInteger SmallInteger).
	pos := self ioPositionOfWindowSet: windowIndex x: x y: y.
	pos = -1 ifTrue:
		[^interpreterProxy primitiveFail].
	^self pointFromCompactPointEncoding: pos
]

{ #category : #'system primitives' }
HostWindowPlugin >> primitiveHostWindowScreenWorkAreaPosition: windex [
	<option: #TerfVM>
	"Answer the platform's notion of the available work area on the screen containing the given window."
	| size |
	self primitive: 'primitiveHostWindowScreenWorkAreaPosition'
		parameters: #(SmallInteger).
	size := self ioPositionOfScreenWorkArea: windex.
	size = -1 ifTrue:
		[^interpreterProxy primitiveFail].
	^self pointFromCompactPointEncoding: size
]

{ #category : #'system primitives' }
HostWindowPlugin >> primitiveHostWindowScreenWorkAreaSize: windex [
	<option: #TerfVM>
	"Answer the platform's notion of the available work area on the screen containing the given window."
	| size |
	self primitive: 'primitiveHostWindowScreenWorkAreaSize'
		parameters: #(SmallInteger).
	size := self ioSizeOfScreenWorkArea: windex.
	size = -1 ifTrue:
		[^interpreterProxy primitiveFail].
	^self pointFromCompactPointEncoding: size
]

{ #category : #'system primitives' }
HostWindowPlugin >> primitiveHostWindowSize: windowIndex [ 
	"Return the size of the user area of the window in pixels. Fail if the windowIndex is invalid or the platform routine returns -1 to indicate failure"
	| size |
	self primitive: 'primitiveHostWindowSize'
		parameters: #(SmallInteger ).
	size := self ioSizeOfWindow: windowIndex.
	size = -1 ifTrue:
		[^interpreterProxy primitiveFail].
	^self pointFromCompactPointEncoding: size
]

{ #category : #'system primitives' }
HostWindowPlugin >> primitiveHostWindowSizeSet: windowIndex x: x y: y [
	"Set the size of the user area of the window in pixels - return what is actually set by the OS/GUI/window manager. Fail if the windowIndex is invalid or the platform routine returns -1 to indicate failure"
	| size |
	self primitive: 'primitiveHostWindowSizeSet'
		parameters: #(SmallInteger SmallInteger SmallInteger).
	size := self ioSizeOfWindowSet: windowIndex x: x y: y.
	size = -1 ifTrue:
		[^interpreterProxy primitiveFail].
	^self pointFromCompactPointEncoding: size
]

{ #category : #'system primitives' }
HostWindowPlugin >> primitiveHostWindowTitle: id string: titleString [
	"Set the title bar label of the window. Fail if the windowIndex is invalid or the platform routine returns -1 to indicate failure"
	| res titleLength |
	self primitive: 'primitiveHostWindowTitle'
		parameters: #(SmallInteger String).
	titleLength := interpreterProxy slotSizeOf: titleString cPtrAsOop.
	res := self cCode: 'ioSetTitleOfWindow(id, titleString, titleLength)'.
	res = -1
		ifTrue: [interpreterProxy primitiveFail]
]

{ #category : #'system primitives' }
HostWindowPlugin >> primitiveNativeDisplayPosition: windowHandle [
	<option: #TerfVM>
	"Answer the origin position of the user area of the given native window in pixels from the topleft corner of the screen.
	 Fail if the windowHandle is invalid or the platform routine returns -1 to indicate failure"
	| pos |
	self primitive: 'primitiveNativeDisplayPosition'
		parameters: #(Unsigned).
	pos := self ioPositionOfNativeDisplay: windowHandle.
	pos = -1 ifTrue:
		[^interpreterProxy primitiveFail].
	^self pointFromCompactPointEncoding: pos
]

{ #category : #'system primitives' }
HostWindowPlugin >> primitiveNativeDisplaySize: windowHandle [
	<option: #TerfVM>
	"Answer the size of the user area of the given native window in pixels.
	 Fail if the windowHandle is invalid or the platform routine returns -1 to indicate failure"
	| size |
	self primitive: 'primitiveNativeDisplaySize'
		parameters: #(Unsigned).
	size := self ioSizeOfNativeDisplay: windowHandle.
	size = -1 ifTrue:
		[^interpreterProxy primitiveFail].
	^self pointFromCompactPointEncoding: size
]

{ #category : #'system primitives' }
HostWindowPlugin >> primitiveNativeWindowPosition: windowHandle [
	<option: #TerfVM>
	"Answer the origin position of the given native window in pixels from the topleft corner of the screen.
	 Fail if the windowHandle is invalid or the platform routine returns -1 to indicate failure"
	| pos |
	self primitive: 'primitiveNativeWindowPosition'
		parameters: #(Unsigned).
	pos := self ioPositionOfNativeWindow: windowHandle.
	pos = -1 ifTrue:
		[^interpreterProxy primitiveFail].
	^self pointFromCompactPointEncoding: pos
]

{ #category : #'system primitives' }
HostWindowPlugin >> primitiveNativeWindowSize: windowHandle [
	<option: #TerfVM>
	"Answer the size of the given native window in pixels.
	 Fail if the windowHandle is invalid or the platform routine returns -1 to indicate failure"
	| size |
	self primitive: 'primitiveNativeWindowSize'
		parameters: #(Unsigned).
	size := self ioSizeOfNativeWindow: windowHandle.
	size = -1 ifTrue:
		[^interpreterProxy primitiveFail].
	^self pointFromCompactPointEncoding: size
]

{ #category : #'system primitives' }
HostWindowPlugin >> primitiveSetCursorPositionX: x Y: y [
	<option: #TerfVM>
	"Set the position of the cursor to the specified position on the desktop.
	 Fail if the platform routine returns -1 to indicate failure."
	| result |
	self primitive: 'primitiveSetCursorPosition'
		parameters: #(SmallInteger SmallInteger).
	result := self ioSetCursorPositionX: x Y: y.
	result = -1 ifTrue:
		[^interpreterProxy primitiveFail]
]

{ #category : #'system primitives' }
HostWindowPlugin >> primitiveShowHostWindow: windowIndex bits: dispBits width: w height: h depth: d
left: left right: right top: top bottom: bottom [
"Host window analogue of DisplayScreen> primShowRectLeft:right:top:bottom:
(Interpreter>primitiveShowDisplayRect) which takes the window index, bitmap
details and the rectangle bounds. Fail if the windowIndex is invalid or the
platform routine returns false to indicate failure"
	|ok|
	self primitive: 'primitiveShowHostWindowRect'
		parameters: #(SmallInteger WordArray SmallInteger SmallInteger SmallInteger
SmallInteger SmallInteger SmallInteger SmallInteger).

	"Tell the vm to copy pixel's from dispBits to the screen - this is just
ioShowDisplay with the extra parameter of the windowIndex integer"
	ok := self cCode: 'ioShowDisplayOnWindow(dispBits, w, h, d, left, right, top,
bottom, windowIndex)'.
	ok ifFalse:[interpreterProxy primitiveFail]
]

{ #category : #'system primitives' }
HostWindowPlugin >> primitiveSqueakWindowHandle [
	<option: #TerfVM>
	"Answer the native Squeak window handle, presumably a pointer, as an unsigned integer.
	 This value should be usable in native calls to the window manager as well as
	 the argument to primitiveNativeWindowPosition:"
	| handle |
	<var: #handle type: 'void *'>
	self primitive: 'primitiveSqueakWindowHandle'.
	handle := self ioGetWindowHandle.
	handle = 0 ifTrue:
		[^interpreterProxy primitiveFail].
	^interpreterProxy positiveMachineIntegerFor: (self cCoerceSimple: handle to: #sqInt)
]

{ #category : #'initialize-release' }
HostWindowPlugin >> shutdownModule [
"do any window related VM closing down work your platform requires."
	<export: true>
	^self cCode: 'ioCloseAllWindows()' inSmalltalk:[true]
]
