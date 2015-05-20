"
Implement the serial port primitives.  Since it requires platform support it will only be built when supported on your platform.

IMPORTANT: So far, we are converting everytime a string into a char* and then we look for it in the ports array. That can be optimized a lot by just answering the external handler (the position in the array perhaps) after open and using it instead the name.
Also, using open by id functions doesn't help because internally they are also converted into a char* (using sprintf).

If needed, that can be optimized then. 
"
Class {
	#name : #SerialPlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
SerialPlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #translation }
SerialPlugin class >> requiresPlatformFiles [
	"this plugin requires platform specific files in order to work"
	^true
]

{ #category : #'initialize-release' }
SerialPlugin >> initialiseModule [
	<export: true>
	^self cCode: 'serialPortInit()' inSmalltalk:[true]
]

{ #category : #primitives }
SerialPlugin >> primitiveSerialPortClose: portNum [

	self primitive: 'primitiveSerialPortClose'
		parameters: #(SmallInteger).
	self serialPortClose: portNum
]

{ #category : #primitives }
SerialPlugin >> primitiveSerialPortOpen: portNum baudRate: baudRate stopBitsType: stopBitsType parityType: parityType dataBits: dataBits inFlowControlType: inFlowControl outFlowControlType: outFlowControl xOnByte: xOnChar xOffByte: xOffChar [

	self primitive: 'primitiveSerialPortOpen'
		parameters: #(SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger ).

	self cCode: 'serialPortOpen(
			portNum, baudRate, stopBitsType, parityType, dataBits,
			inFlowControl, outFlowControl, xOnChar, xOffChar)'
]

{ #category : #primitives }
SerialPlugin >> primitiveSerialPortRead: portNum into: array startingAt: startIndex count: count [ 
	| bytesRead arrayPtr |
	self primitive: 'primitiveSerialPortRead'
		parameters: #(SmallInteger ByteArray SmallInteger SmallInteger ).

	interpreterProxy success: (startIndex >= 1 and: [startIndex + count - 1 <= (interpreterProxy byteSizeOf: array cPtrAsOop)]).
	"adjust for zero-origin indexing"
	arrayPtr := array asInteger + startIndex - 1.
	bytesRead := self cCode: 'serialPortReadInto( portNum, count, arrayPtr)'.
	^ bytesRead asSmallIntegerObj
]

{ #category : #primitives }
SerialPlugin >> primitiveSerialPortWrite: portNum from: array startingAt: startIndex count: count [ 
	| bytesWritten arrayPtr |
	self primitive: 'primitiveSerialPortWrite'
		parameters: #(SmallInteger ByteArray SmallInteger SmallInteger ).

	interpreterProxy success: (startIndex >= 1 and: [startIndex + count - 1 <= (interpreterProxy byteSizeOf: array cPtrAsOop)]).
	interpreterProxy failed
		ifFalse: [arrayPtr := array asInteger + startIndex - 1.
			bytesWritten := self
						serialPort: portNum
						Write: count
						From: arrayPtr].
	^ bytesWritten asSmallIntegerObj
]

{ #category : #'initialize-release' }
SerialPlugin >> shutdownModule [
	<export: true>
	^self cCode: 'serialPortShutdown()' inSmalltalk:[true]
]
