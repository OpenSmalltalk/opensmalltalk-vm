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

{ #category : #private }
SerialPlugin >> allocateTerminatedString: unterminatedCharactersInStringObject [
	"Allocate a C string with contents of a String value. May cause garbage collection."

	| len terminatedString p |
	<inline: true>
	<returnTypeC: 'char *'>
	<var: #unterminatedCharactersInStringObject type: 'char *'>
	<var: #p type: 'char *'>
	len := interpreterProxy sizeOfSTArrayFromCPrimitive: unterminatedCharactersInStringObject.
	terminatedString := interpreterProxy
		instantiateClass: interpreterProxy classString
		indexableSize: len + 1.
	p := interpreterProxy arrayValueOf: terminatedString.
	p at: len put: 0. "null terminator"
	[len >= 0] whileTrue:
		[len := len - 1.
		p at: len put: (unterminatedCharactersInStringObject at: len)].
	^ p

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
SerialPlugin >> primitiveSerialPortCloseByName: deviceName [

	| cString |
	<var: #cString type: 'char *'>
	self primitive: 'primitiveSerialPortCloseByName'
		parameters: #(ByteArray).
	cString := self allocateTerminatedString: deviceName.
	self serialPortCloseByName: cString
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
SerialPlugin >> primitiveSerialPortOpenByName: deviceName baudRate: baudRate stopBitsType: stopBitsType parityType: parityType dataBits: dataBits inFlowControlType: inFlowControl outFlowControlType: outFlowControl xOnByte: xOnChar xOffByte: xOffChar [

	| cString |
	<var: #cString type: 'char *'>
	self primitive: 'primitiveSerialPortOpenByName'
		parameters: #(ByteArray SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger ).
	cString := self allocateTerminatedString: deviceName.
	self cCode: 'serialPortOpenByName(
			cString, baudRate, stopBitsType, parityType, dataBits,
			inFlowControl, outFlowControl, xOnChar, xOffChar)'
]

{ #category : #primitives }
SerialPlugin >> primitiveSerialPortRead: portNum into: array startingAt: startIndex count: count [ 
	| bytesRead |
	self primitive: 'primitiveSerialPortRead'
		parameters: #(SmallInteger ByteArray SmallInteger SmallInteger ).

	interpreterProxy success: (startIndex >= 1 and: [startIndex + count - 1 <= (interpreterProxy byteSizeOf: array cPtrAsOop)]).
	"adjust for zero-origin indexing"
	bytesRead := self
			serialPort: portNum
			Read: count
			Into: array + startIndex - 1.
	^ bytesRead asSmallIntegerObj
]

{ #category : #primitives }
SerialPlugin >> primitiveSerialPortReadByName: deviceName into: array startingAt: startIndex count: count [ 
	| bytesRead cString |
	<var: #cString type: 'char *'>
	self primitive: 'primitiveSerialPortReadByName'
		parameters: #(ByteArray ByteArray SmallInteger SmallInteger ).

	interpreterProxy success: (startIndex >= 1 and: [startIndex + count - 1 <= (interpreterProxy byteSizeOf: array cPtrAsOop)]).
	cString := self allocateTerminatedString: deviceName.
	"adjust for zero-origin indexing"
	bytesRead := self
			serialPort: cString
			Read: count
			IntoByName: array + startIndex - 1.
	^ bytesRead asSmallIntegerObj
]

{ #category : #primitives }
SerialPlugin >> primitiveSerialPortWrite: portNum from: array startingAt: startIndex count: count [ 
	| bytesWritten |
	self primitive: 'primitiveSerialPortWrite'
		parameters: #(SmallInteger ByteArray SmallInteger SmallInteger ).

	interpreterProxy success: (startIndex >= 1 and: [startIndex + count - 1 <= (interpreterProxy byteSizeOf: array cPtrAsOop)]).
	interpreterProxy failed
		ifFalse: [bytesWritten := self
						serialPort: portNum
						Write: count
						From: array + startIndex - 1].
	^ bytesWritten asSmallIntegerObj
]

{ #category : #primitives }
SerialPlugin >> primitiveSerialPortWriteByName: deviceName from: array startingAt: startIndex count: count [ 
	| bytesWritten cString |
	<var: #cString type: 'char *'>
	self primitive: 'primitiveSerialPortWriteByName'
		parameters: #(ByteArray ByteArray SmallInteger SmallInteger ).
	interpreterProxy success: (startIndex >= 1 and: [startIndex + count - 1 <= (interpreterProxy byteSizeOf: array cPtrAsOop)]).
	interpreterProxy failed
		ifFalse: [cString := self allocateTerminatedString: deviceName.
				bytesWritten := self
						serialPort: cString
						Write: count
						FromByName: array + startIndex - 1].
	^ bytesWritten asSmallIntegerObj
]

{ #category : #'initialize-release' }
SerialPlugin >> shutdownModule [
	<export: true>
	^self cCode: 'serialPortShutdown()' inSmalltalk:[true]
]
