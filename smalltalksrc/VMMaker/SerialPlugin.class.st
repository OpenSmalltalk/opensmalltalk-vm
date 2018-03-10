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
SerialPlugin >> primitiveSerialPortOpenByName: portName baudRate: baudRate stopBitsType: stopBitsType parityType: parityType dataBits: dataBits inFlowControlType: inFlowControl outFlowControlType: outFlowControl xOnByte: xOnChar xOffByte: xOffChar [
	<var: #port type: 'char *'>

	| port portNameSize |
	
	self primitive: 'primitiveSerialPortOpenByName'
		parameters: #(String SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger ).

	portNameSize := interpreterProxy slotSizeOf: (portName asOop: String).
	port := self cCode: 'calloc(portNameSize+1, sizeof(char))'.
	self cCode: 'memcpy(port, portName, portNameSize)'.
	
	self cCode: 'serialPortOpenByName(
			port, baudRate, stopBitsType, parityType, dataBits,
			inFlowControl, outFlowControl, xOnChar, xOffChar)'.
	
	self free: port.
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
SerialPlugin >> primitiveSerialPortReadByName: portName into: array startingAt: startIndex count: count [ 
	<var: #port type: 'char *'>

	| port portNameSize bytesRead arrayPtr |

	self primitive: 'primitiveSerialPortReadByName'
		parameters: #(String  ByteArray SmallInteger SmallInteger ).

	interpreterProxy success: (startIndex >= 1 and: [startIndex + count - 1 <= (interpreterProxy byteSizeOf: array cPtrAsOop)]).
	"adjust for zero-origin indexing"

	portNameSize := interpreterProxy slotSizeOf: (portName asOop: String).
	port := self cCode: 'calloc(portNameSize+1, sizeof(char))'.
	self cCode: 'memcpy(port, portName, portNameSize)'.

	arrayPtr := array + startIndex - 1.
	bytesRead := self cCode: 'serialPortReadIntoByName( port, count, arrayPtr)'.
	
	self free: port.
	
	^ bytesRead asSmallIntegerObj
]

{ #category : #primitives }
SerialPlugin >> primitiveSerialPortWrite: portNum from: array startingAt: startIndex count: count [ 
	| bytesWritten arrayPtr |
	self primitive: 'primitiveSerialPortWrite'
		parameters: #(SmallInteger ByteArray SmallInteger SmallInteger ).

	interpreterProxy success: (startIndex >= 1 and: [startIndex + count - 1 <= (interpreterProxy byteSizeOf: array cPtrAsOop)]).
	interpreterProxy failed
		ifFalse: [arrayPtr := array + startIndex - 1.
			bytesWritten := self
						serialPort: portNum
						Write: count
						From: arrayPtr].
	^ bytesWritten asSmallIntegerObj
]

{ #category : #primitives }
SerialPlugin >> primitiveSerialPortWriteByName: portName from: array startingAt: startIndex count: count [ 
	<var: #port type: 'char *'>

	| bytesWritten arrayPtr portNameSize port |
	
	self primitive: 'primitiveSerialPortWriteByName'
		parameters: #(String ByteArray SmallInteger SmallInteger ).

	portNameSize := interpreterProxy slotSizeOf: (portName asOop: String).
	port := self cCode: 'calloc(portNameSize+1, sizeof(char))'.
	self cCode: 'memcpy(port, portName, portNameSize)'.

	interpreterProxy success: (startIndex >= 1 and: [startIndex + count - 1 <= (interpreterProxy byteSizeOf: array cPtrAsOop)]).
	interpreterProxy failed
		ifFalse: [arrayPtr := array + startIndex - 1.
			bytesWritten := self cCode: 'serialPortWriteFromByName(port, count, arrayPtr)' ].
	
	self free: port.

	^ bytesWritten asSmallIntegerObj
]

{ #category : #'initialize-release' }
SerialPlugin >> shutdownModule [
	<export: true>
	^self cCode: 'serialPortShutdown()' inSmalltalk:[true]
]
