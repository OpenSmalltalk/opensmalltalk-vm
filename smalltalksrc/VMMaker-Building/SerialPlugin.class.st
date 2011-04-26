"
Implement the serial port primitives.  Since it requires platform support it will only be built when supported on your platform
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
