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

{ #category : #'private-support' }
SerialPlugin >> copyPortNameToCString: portName [
	<returnTypeC: #'char *'>
	| port portNameSize |
	<inline: #always>
	<var: 'port' type: #'char *'>
	portNameSize := interpreterProxy slotSizeOf: (portName asOop: String).
	port := self alloca: portNameSize + 1.
	self memcpy: port _: portName _: portNameSize.
	port at: portNameSize put: 0.
	^port
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
SerialPlugin >> primitiveSerialPortCloseByName: portName [
	| port |
	self primitive: 'primitiveSerialPortCloseByName'
		parameters: #(String).
	port := self copyPortNameToCString: portName.
	self serialPortCloseByName: port
]

{ #category : #primitives }
SerialPlugin >> primitiveSerialPortOpen: portNum baudRate: baudRate stopBitsType: stopBitsType parityType: parityType dataBits: dataBits inFlowControlType: inFlowControl outFlowControlType: outFlowControl xOnByte: xOnChar xOffByte: xOffChar [

	self primitive: 'primitiveSerialPortOpen'
		parameters: #(SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger).

	self serialPortOpen: portNum _: baudRate _: stopBitsType _: parityType _: dataBits
					_: inFlowControl _: outFlowControl _: xOnChar _: xOffChar
]

{ #category : #primitives }
SerialPlugin >> primitiveSerialPortOpenByName: portName baudRate: baudRate stopBitsType: stopBitsType parityType: parityType dataBits: dataBits inFlowControlType: inFlowControl outFlowControlType: outFlowControl xOnByte: xOnChar xOffByte: xOffChar [

	| port |
	self primitive: 'primitiveSerialPortOpenByName'
		parameters: #(String SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger).

	port := self copyPortNameToCString: portName.
	self serialPortOpenByName: port _: baudRate _: stopBitsType _: parityType _: dataBits
							_: inFlowControl _: outFlowControl _: xOnChar _: xOffChar
]

{ #category : #primitives }
SerialPlugin >> primitiveSerialPortRead: portNum into: array startingAt: startIndex count: count [ 
	| bytesRead |
	self primitive: 'primitiveSerialPortRead'
		parameters: #(SmallInteger ByteArray SmallInteger SmallInteger).

	(startIndex >= 1 and: [startIndex + count - 1 <= (interpreterProxy byteSizeOf: array cPtrAsOop)]) ifTrue:
		[bytesRead := self serialPortReadInto: portNum _: count _: array + startIndex - 1.
		 ^bytesRead asSmallIntegerObj].
	interpreterProxy success: false
]

{ #category : #primitives }
SerialPlugin >> primitiveSerialPortReadByName: portName into: array startingAt: startIndex count: count [
	| port bytesRead |
	<var: #port type: #'char *'>
	self primitive: 'primitiveSerialPortReadByName'
		parameters: #(String  ByteArray SmallInteger SmallInteger).

	(startIndex >= 1 and: [startIndex + count - 1 <= (interpreterProxy byteSizeOf: array cPtrAsOop)]) ifTrue:
		[port := self copyPortNameToCString: portName.
		 bytesRead := self serialPortReadIntoByName: port _: count _: array + startIndex - 1.
		 ^bytesRead asSmallIntegerObj].
	interpreterProxy success: false
]

{ #category : #primitives }
SerialPlugin >> primitiveSerialPortWrite: portNum from: array startingAt: startIndex count: count [ 
	| bytesWritten |
	self primitive: 'primitiveSerialPortWrite'
		parameters: #(SmallInteger ByteArray SmallInteger SmallInteger).

	(startIndex >= 1 and: [startIndex + count - 1 <= (interpreterProxy byteSizeOf: array cPtrAsOop)]) ifTrue:
		[bytesWritten := self serialPort: portNum Write: count From: array + startIndex - 1.
		 ^bytesWritten asSmallIntegerObj].
	interpreterProxy success: false
]

{ #category : #primitives }
SerialPlugin >> primitiveSerialPortWriteByName: portName from: array startingAt: startIndex count: count [ 
	| bytesWritten port |
	self primitive: 'primitiveSerialPortWriteByName'
		parameters: #(String ByteArray SmallInteger SmallInteger).

	(startIndex >= 1 and: [startIndex + count - 1 <= (interpreterProxy byteSizeOf: array cPtrAsOop)]) ifTrue:
		[port := self copyPortNameToCString: portName.
		 bytesWritten := self serialPortWriteFromByName: port _: count _: array + startIndex - 1.
		 ^bytesWritten asSmallIntegerObj].
	interpreterProxy success: false
]

{ #category : #'initialize-release' }
SerialPlugin >> shutdownModule [
	<export: true>
	^self cCode: 'serialPortShutdown()' inSmalltalk:[true]
]
