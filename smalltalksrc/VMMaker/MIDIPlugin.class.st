"
Provide MIDI support, if your platform provides it. 
"
Class {
	#name : #MIDIPlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#category : 'VMMaker-Plugins'
}

{ #category : #translation }
MIDIPlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #translation }
MIDIPlugin class >> requiresPlatformFiles [
	"this plugin requires platform specific files in order to work"
	^true
]

{ #category : #'initialize-release' }
MIDIPlugin >> initialiseModule [
	self export: true.
	^self cCode: 'midiInit()' inSmalltalk:[true]
]

{ #category : #primitives }
MIDIPlugin >> primitiveMIDIClosePort: portNum [

	self primitive: 'primitiveMIDIClosePort'
		parameters: #(SmallInteger).
	self sqMIDIClosePort: portNum
]

{ #category : #primitives }
MIDIPlugin >> primitiveMIDIGetClock [
	"Return the value of the MIDI clock as a SmallInteger. The range is limited to SmallInteger maxVal / 2 to allow scheduling MIDI events into the future without overflowing a SmallInteger. The sqMIDIGetClock function is assumed to wrap at or before 16r20000000."

	| clockValue |
	self primitive: 'primitiveMIDIGetClock'.
	clockValue _ self sqMIDIGetClock bitAnd: 16r1FFFFFFF.
	^clockValue asSmallIntegerObj
]

{ #category : #primitives }
MIDIPlugin >> primitiveMIDIGetPortCount [

	| n |
	self primitive: 'primitiveMIDIGetPortCount'.
	n _ self sqMIDIGetPortCount.
	^n asSmallIntegerObj

]

{ #category : #primitives }
MIDIPlugin >> primitiveMIDIGetPortDirectionality: portNum [

	|  dir |
	self primitive: 'primitiveMIDIGetPortDirectionality'
		parameters: #(SmallInteger).
	dir _ self sqMIDIGetPortDirectionality: portNum.
	^dir asSmallIntegerObj
]

{ #category : #primitives }
MIDIPlugin >> primitiveMIDIGetPortName: portNum [

	| portName sz nameObj namePtr |
	self var: #portName declareC: 'char portName[256]'.
	self var: #namePtr declareC: 'char * namePtr'.
	self primitive: 'primitiveMIDIGetPortName'
		parameters: #(SmallInteger).

	sz _ self cCode: 'sqMIDIGetPortName(portNum, (int) &portName, 255)'.
	nameObj _ interpreterProxy instantiateClass: interpreterProxy classString indexableSize: sz.
	interpreterProxy failed ifTrue:[^nil].
	namePtr _ nameObj asValue: String .
	self cCode: 'memcpy(namePtr, portName, sz)'.
	^nameObj
]

{ #category : #primitives }
MIDIPlugin >> primitiveMIDIOpenPort: portNum sema: semaIndex speed: clockRate [

	self primitive: 'primitiveMIDIOpenPort'
		parameters: #(SmallInteger SmallInteger SmallInteger).
	self cCode: 'sqMIDIOpenPort(portNum, semaIndex, clockRate)'
]

{ #category : #primitives }
MIDIPlugin >> primitiveMIDIParameterGet: whichParameter [

	|  currentValue |
	"read parameter"
	self primitive: 'primitiveMIDIParameterGet'
		parameters: #(SmallInteger).
	currentValue _ self cCode: 'sqMIDIParameterGet(whichParameter)'.
	^currentValue asSmallIntegerObj
]

{ #category : #primitives }
MIDIPlugin >> primitiveMIDIParameterGetOrSet [
	"Backward compatibility"
	self export: true.
	interpreterProxy methodArgumentCount = 1
		ifTrue:[^self primitiveMIDIParameterGet]
		ifFalse:[^self primitiveMIDIParameterSet]
]

{ #category : #primitives }
MIDIPlugin >> primitiveMIDIParameterSet: whichParameter value: newValue [

	"write parameter"
	self primitive:'primitiveMIDIParameterSet'
		parameters:#(SmallInteger SmallInteger).
	self cCode: 'sqMIDIParameterSet(whichParameter, newValue)'
]

{ #category : #primitives }
MIDIPlugin >> primitiveMIDIRead: portNum into: array [

	| arrayLength bytesRead |
	self primitive: 'primitiveMIDIRead'
		parameters: #(SmallInteger ByteArray).
	arrayLength _ interpreterProxy byteSizeOf: array cPtrAsOop.
	bytesRead _ self sqMIDIPort: portNum
			Read: arrayLength
			Into: array asInteger.
	^bytesRead asSmallIntegerObj
]

{ #category : #primitives }
MIDIPlugin >> primitiveMIDIWrite: portNum from: array at: time [

	| arrayLength bytesWritten |
	self primitive: 'primitiveMIDIWrite'
		parameters: #(SmallInteger ByteArray SmallInteger).
	arrayLength _ interpreterProxy byteSizeOf: array cPtrAsOop.
	bytesWritten _ self sqMIDIPort: portNum
			Write: arrayLength
			From: array asInteger
			At: time.
	^bytesWritten asSmallIntegerObj
]

{ #category : #'initialize-release' }
MIDIPlugin >> shutdownModule [
	self export: true.
	^self cCode: 'midiShutdown()' inSmalltalk:[true]
]
