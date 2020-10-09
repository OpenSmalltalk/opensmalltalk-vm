Class {
	#name : #VMPrimitiveCallingTest,
	#superclass : #VMPrimitiveCallAbstractTest,
	#instVars : [
		'classLargeInteger'
	],
	#pools : [
		'CogRTLOpcodes'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #helpers }
VMPrimitiveCallingTest >> callCogMethod: callingMethod receiver: receiver arguments: arguments returnAddress: returnAddress [

	machineSimulator receiverRegisterValue: receiver.
	self pushAddress: receiver.
	
	arguments do: [ :e | self pushAddress: e ].
	
	machineSimulator hasLinkRegister 
		ifTrue: [ machineSimulator linkRegisterValue: returnAddress ] 
		ifFalse: [ self pushAddress: returnAddress ].
	
	machineSimulator instructionPointerValue: callingMethod address + cogit noCheckEntryOffset. 
	
	self runFrom: callingMethod address + cogit noCheckEntryOffset until: returnAddress.

]

{ #category : #helpers }
VMPrimitiveCallingTest >> initStack [

	self createBaseFrame.
	
	"Initialize Stack to the correct pointers in the selected page"
	machineSimulator stackPointerRegisterValue: interpreter stackPointer.
	machineSimulator framePointerRegisterValue: interpreter framePointer.
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	
	cogit setCStackPointer: interpreter rumpCStackAddress.
	cogit setCFramePointer: interpreter rumpCStackAddress.

]

{ #category : #'tests - without tracing' }
VMPrimitiveCallingTest >> setUp [
	super setUp.

	"Initializing the primTraceLog table"
	interpreter movePrimTraceLogToMemoryAt:
		cogit methodZoneBase + interpreter cogCodeSize + stackSpaceSize
		+ methodCacheSize.

	classLargeInteger := self newClassInOldSpaceWithSlots: 0 instSpec: memory firstByteFormat.
	
	memory setHashBitsOf: classLargeInteger to: ClassLargePositiveIntegerCompactIndex.
	memory
		storePointer: ClassLargePositiveIntegerCompactIndex
		ofObject: memory classTableFirstPage
		withValue: classLargeInteger.
]

{ #category : #'tests - run on smalltalk stack' }
VMPrimitiveCallingTest >> testCallingPrimitiveInSmalltalkStackWithInvalidReceiverRunsFallbackCode [

	| callingMethod |

	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive159).

	self initStack.	

	self 
		callCogMethod: callingMethod 
		receiver: memory nilObject 
		arguments: {}
		returnAddress: callerAddress.
	
	self assert: machineSimulator receiverRegisterValue equals: (memory integerObjectOf: 42).
	

]

{ #category : #'tests - run on smalltalk stack' }
VMPrimitiveCallingTest >> testCallingPrimitiveInSmalltalkStackWithLargeIntegerWillExecuteThePrimitiveAndReturnASmallInteger [

	| callingMethod |

	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive159).

	self initStack.	

	self 
		callCogMethod: callingMethod 
		receiver: (memory signed64BitIntegerFor: SmallInteger maxVal + 1) 
		arguments: {}
		returnAddress: callerAddress.
	
	self assert: machineSimulator receiverRegisterValue equals: (memory integerObjectOf: (SmallInteger maxVal + 1) hashMultiply).
	

]

{ #category : #'tests - run on smalltalk stack' }
VMPrimitiveCallingTest >> testCallingPrimitiveInSmalltalkStackWithSmallIntegerReceiverReturnsSmallInteger [

	| callingMethod |

	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive159).

	self initStack.	

	self 
		callCogMethod: callingMethod 
		receiver: (memory integerObjectOf: 5) 
		arguments: {}
		returnAddress: callerAddress.
	
	self assert: machineSimulator receiverRegisterValue equals: (memory integerObjectOf: 5 hashMultiply).
	

]

{ #category : #'tests - with tracing' }
VMPrimitiveCallingTest >> testCallingPrimitiveTakingTracesWithInvalidNumbersExecutesFailbackCode [

	| callingMethod |

	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:).

	self initStack.	

	self 
		callCogMethod: callingMethod 
		receiver: memory nilObject 
		arguments: {memory integerObjectOf: 2}
		returnAddress: callerAddress.
	
	self assert: machineSimulator receiverRegisterValue equals: (memory integerObjectOf: 42).
	

]

{ #category : #'tests - without tracing' }
VMPrimitiveCallingTest >> testCallingPrimitiveWithoutTakingTracesReturnsValidResult [

	| callingMethod |

	cogit sendTrace: 0.
	
	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:).
	
	self initStack.
	
	self 
		callCogMethod: callingMethod 
		receiver: (memory integerObjectOf: 1) 
		arguments: {memory integerObjectOf: 2}
		returnAddress: callerAddress.
	
	self assert: machineSimulator receiverRegisterValue equals: (memory integerObjectOf: 3)
]

{ #category : #'tests - without tracing' }
VMPrimitiveCallingTest >> testCallingPrimitiveWithoutTakingTracesWithInvalidNumbersExecutesFailbackCode [

	| callingMethod |

	cogit sendTrace: 0.
	
	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:).

	self initStack.	

	self 
		callCogMethod: callingMethod 
		receiver: memory nilObject 
		arguments: {memory integerObjectOf: 2}
		returnAddress: callerAddress.
	
	self assert: machineSimulator receiverRegisterValue equals: (memory integerObjectOf: 42).
	

]

{ #category : #'tests - with tracing' }
VMPrimitiveCallingTest >> testCallingPrimitivesTakingTracesHasATraceForThePrimitive [

	| callingMethod |

	cogit sendTrace: 8.
	
	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:).
	
	self initStack.
	
	self 
		callCogMethod: callingMethod 
		receiver: (memory integerObjectOf: 1) 
		arguments: {memory integerObjectOf: 2}
		returnAddress: callerAddress.
	
	self assert: (interpreter primTraceLog at: 1) equals: callingMethod selector
]

{ #category : #'tests - with tracing' }
VMPrimitiveCallingTest >> testCallingPrimitivesTakingTracesReturnsValidResults [

	| callingMethod |

	cogit sendTrace: 8.
	
	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:).
	
	self initStack.
	
	self 
		callCogMethod: callingMethod 
		receiver: (memory integerObjectOf: 1) 
		arguments: {memory integerObjectOf: 2}
		returnAddress: callerAddress.
	
	self assert: machineSimulator receiverRegisterValue equals: (memory integerObjectOf: 3)
]

{ #category : #'tests - with tracing' }
VMPrimitiveCallingTest >> testPrimitiveIsNotTracedIfNotCalled [

	| callingMethod |

	cogit sendTrace: 8.
	
	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:).
	
	self initStack.
	
	1 to: interpreter primTraceLogEntries - 1 do:
		[:i| self assert: (interpreter primTraceLog at: i) = 0].
	

]

{ #category : #'test - fail fast' }
VMPrimitiveCallingTest >> testPrimitiveWithPrimitiveFailExecutesFallbackCode [

	| callingMethod |

	"Patching the primitive to remove primitiveFunction"
	interpreter primitiveTable at: 1 + 1 put: #primitiveFail.

	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:).

	self initStack.	

	self 
		callCogMethod: callingMethod 
		receiver: memory nilObject 
		arguments: {memory nilObject}
		returnAddress: callerAddress.
	
	self assert: machineSimulator receiverRegisterValue equals: (memory integerObjectOf: 42).
	

]

{ #category : #'test - fail fast' }
VMPrimitiveCallingTest >> testPrimitiveWithoutFunctionExecutesFallbackCode [

	| callingMethod |

	"Patching the primitive to remove primitiveFunction"
	interpreter primitiveTable at: 1 + 1 put: 0.

	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:).

	self initStack.	

	self 
		callCogMethod: callingMethod 
		receiver: memory nilObject 
		arguments: {memory nilObject}
		returnAddress: callerAddress.
	
	self assert: machineSimulator receiverRegisterValue equals: (memory integerObjectOf: 42).
	

]
