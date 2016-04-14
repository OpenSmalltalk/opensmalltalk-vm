"
This plugin implements the interface to the joystick and tablet input devices, if you have one.  Since it requires platform support it will only be built when supported on your platform
"
Class {
	#name : #JoystickTabletPlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
JoystickTabletPlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #translation }
JoystickTabletPlugin class >> requiresPlatformFiles [
	" this plugin requires platform specific files in order to work"
	^true
]

{ #category : #'initialize-release' }
JoystickTabletPlugin >> initialiseModule [
	<export: true>
	^self cCode: 'joystickInit()' inSmalltalk:[true]
]

{ #category : #primitives }
JoystickTabletPlugin >> primitiveGetTabletParameters: cursorIndex [
	"Get information on the pen tablet attached to this machine. Fail if there is no tablet. If successful, the result is an array of integers; see the Smalltalk call on this primitive for its interpretation."

	| resultSize result resultPtr |
	<var: #resultPtr type: 'int * '>
	self primitive: 'primitiveGetTabletParameters'
		parameters: #(SmallInteger).
	resultSize := self tabletResultSize.
	result := interpreterProxy instantiateClass: interpreterProxy classBitmap indexableSize: resultSize.
	resultPtr := result asIntPtr.
	interpreterProxy success: (self cCode: 'tabletGetParameters(cursorIndex, resultPtr)').
	^result
]

{ #category : #primitives }
JoystickTabletPlugin >> primitiveReadJoystick: index [
	"Read an input word from the joystick with the given index."

	self primitive: 'primitiveReadJoystick'
		parameters: #(SmallInteger).
	^(self joystickRead: index) asPositiveIntegerObj
]

{ #category : #primitives }
JoystickTabletPlugin >> primitiveReadTablet: cursorIndex [
	"Get the current state of the cursor of the pen tablet specified by my argument. Fail if there is no tablet. If successful, the result is an array of integers; see the Smalltalk call on this primitive for its interpretation."

	| resultSize result resultPtr|
	<var: #resultPtr type: 'int * '>
	self primitive: 'primitiveReadTablet'
		parameters: #(SmallInteger).
	resultSize := self tabletResultSize.
	result := interpreterProxy instantiateClass: interpreterProxy classBitmap indexableSize: resultSize.
	resultPtr := result asIntPtr.
	interpreterProxy success: (self cCode: 'tabletRead(cursorIndex, resultPtr)').
	^result
]

{ #category : #'initialize-release' }
JoystickTabletPlugin >> shutdownModule [
	<export: true>
	^self cCode: 'joystickShutdown()' inSmalltalk:[true]
]
