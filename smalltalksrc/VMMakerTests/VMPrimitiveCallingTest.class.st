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
VMPrimitiveCallingTest >> initStack [

	self createBaseFrame.
	
	"Initialize Stack to the correct pointers in the selected page"
	machineSimulator smalltalkStackPointerRegisterValue: interpreter stackPointer.
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
		
	interpreter pluginList: OrderedCollection new.
	
	interpreter codeGeneratorToComputeAccessorDepth: (VMMockCodeGenerator for: interpreter).
	interpreter codeGeneratorToComputeAccessorDepth addPrimitive: #primitiveThatDoNothingWithOneArgument.
	interpreter codeGeneratorToComputeAccessorDepth initializeWithPrimitiveTable.
	
	self createActiveProcess
]

{ #category : #'tests - with tracing' }
VMPrimitiveCallingTest >> testCallingNamedPrimitiveTakingTracesWithInvalidNumbersExecutesFailbackCode [

	| callingMethod |

	callingMethod := self jitMethod: (self findMethod: #methodThatCallNamedPrimitive:).

	self initStack.	

	self 
		callCogMethod: callingMethod 
		receiver: memory nilObject 
		arguments: {memory integerObjectOf: 2}
		returnAddress: callerAddress.
	
	self assert: machineSimulator receiverRegisterValue equals: (memory integerObjectOf: 42 + 42).
	

]

{ #category : #'tests - with tracing' }
VMPrimitiveCallingTest >> testCallingNamedPrimitivesTakingTracesHasATraceForThePrimitive [

	| callingMethod |

	cogit sendTrace: 8.
	
	callingMethod := self jitMethod: (self findMethod: #methodThatCallNamedPrimitive:).
	
	self initStack.
	
	self 
		callCogMethod: callingMethod 
		receiver: (memory integerObjectOf: 1) 
		arguments: {memory integerObjectOf: 2}
		returnAddress: callerAddress.
	
	self assert: (interpreter primTraceLog at: 1) equals: callingMethod selector
]

{ #category : #'tests - with tracing' }
VMPrimitiveCallingTest >> testCallingNamedPrimitivesTakingTracesReturnsValidResults [

	| callingMethod |

	cogit sendTrace: 8.
	
	callingMethod := self jitMethod: (self findMethod: #methodThatCallNamedPrimitive:).
	
	self initStack.
	
	self 
		callCogMethod: callingMethod 
		receiver: (memory integerObjectOf: 1) 
		arguments: {memory integerObjectOf: 2}
		returnAddress: callerAddress.
	
	self assert: machineSimulator receiverRegisterValue equals: (memory integerObjectOf: 2)
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

{ #category : #'tests - newMethod' }
VMPrimitiveCallingTest >> testNamedPrimitiveCallSetsNewMethod [

	| callingMethod |

	callingMethod := self jitMethod: (self findMethod: #methodThatCallNamedPrimitive:).

	self initStack.	

	self 
		callCogMethod: callingMethod 
		receiver: memory nilObject 
		arguments: {memory nilObject}
		returnAddress: callerAddress.
	
	self 
		assert: interpreter newMethod
		equals: callingMethod methodObject
	

]

{ #category : #'tests - primitiveFunctionPointer' }
VMPrimitiveCallingTest >> testNamedPrimitiveCallSetsPrimitiveFunctionPointerWhenCallingCImplementation [

	| callingMethod |

	callingMethod := self jitMethod: (self findMethod: #methodThatCallNamedPrimitive:).

	self initStack.	

	self 
		callCogMethod: callingMethod 
		receiver: memory nilObject 
		arguments: {memory nilObject}
		returnAddress: callerAddress.
	
	self 
		assert: interpreter primitiveFunctionPointer
		equals: #primitiveThatDoNothingWithOneArgument
	

]

{ #category : #'tests - retry primitive' }
VMPrimitiveCallingTest >> testNamedPrimitiveFailingWithAccessorDepthWithForwardersDoesRetry [

	| callingMethod forwarder receiver |

	interpreter primitiveFailCount: 0.
	interpreter codeGeneratorToComputeAccessorDepth addPrimitive: #primitiveFailCounting accessorDepth: 1.

	callingMethod := self jitMethod: (self findMethod: #methodThatCallNamedPrimitiveCounting:).

	self initStack.	

	forwarder := self newZeroSizedObject.
	self keepObjectInVMVariable1: forwarder.

	interpreter gcMode: GCModeNewSpace.
	memory doScavenge: 1 "TenureByAge".

	self assert: (memory isForwarded: forwarder).

	receiver := self newObjectWithSlots: 1.
	memory storePointer: 0 ofObject: receiver withValue: forwarder. 

	self 
		callCogMethod: callingMethod 
		receiver: receiver 
		arguments: {memory trueObject}
		returnAddress: callerAddress.
	
	self assert: interpreter primitiveFailCount equals: 2.
	

]

{ #category : #'tests - retry primitive' }
VMPrimitiveCallingTest >> testNamedPrimitiveFailingWithAccessorDepthWithoutForwardersDoNotRetry [

	| callingMethod |

	interpreter primitiveFailCount: 0.
	interpreter codeGeneratorToComputeAccessorDepth addPrimitive: #primitiveFailCounting accessorDepth: 1.

	callingMethod := self jitMethod: (self findMethod: #methodThatCallNamedPrimitiveCounting:).

	self initStack.	

	self 
		callCogMethod: callingMethod 
		receiver: memory nilObject 
		arguments: {memory nilObject}
		returnAddress: callerAddress.
	
	self assert: interpreter primitiveFailCount equals: 1.
	

]

{ #category : #'tests - retry primitive' }
VMPrimitiveCallingTest >> testNamedPrimitiveFailingWithAccessorDepthZeroWithForwardersDoesNotRetry [

	| callingMethod forwarder receiver |

	interpreter primitiveFailCount: 0.
	interpreter codeGeneratorToComputeAccessorDepth addPrimitive: #primitiveFailCounting accessorDepth: 0.

	callingMethod := self jitMethod: (self findMethod: #methodThatCallNamedPrimitiveCounting:).

	self initStack.	

	forwarder := self newZeroSizedObject.
	self keepObjectInVMVariable1: forwarder.

	interpreter gcMode: GCModeNewSpace.
	memory doScavenge: 1 "TenureByAge".

	self assert: (memory isForwarded: forwarder).

	receiver := self newObjectWithSlots: 1.
	memory storePointer: 0 ofObject: receiver withValue: forwarder. 

	self 
		callCogMethod: callingMethod 
		receiver: receiver 
		arguments: {memory trueObject}
		returnAddress: callerAddress.
	
	self assert: interpreter primitiveFailCount equals: 1.
	

]

{ #category : #'tests - retry primitive' }
VMPrimitiveCallingTest >> testNamedPrimitiveFailingWithAccessorDepthZeroWithoutForwardersDoNotRetry [

	| callingMethod |

	interpreter primitiveFailCount: 0.
	interpreter codeGeneratorToComputeAccessorDepth addPrimitive: #primitiveFailCounting accessorDepth: 0.

	callingMethod := self jitMethod: (self findMethod: #methodThatCallNamedPrimitiveCounting:).

	self initStack.	

	self 
		callCogMethod: callingMethod 
		receiver: memory nilObject 
		arguments: {memory nilObject}
		returnAddress: callerAddress.
	
	self assert: interpreter primitiveFailCount equals: 1.
	

]

{ #category : #'tests - retry primitive' }
VMPrimitiveCallingTest >> testNamedPrimitiveFailingWithNegativeAccessorDepthWithForwardersDoNotRetry [

	| callingMethod forwarder receiver |

	interpreter primitiveFailCount: 0.
	interpreter codeGeneratorToComputeAccessorDepth addPrimitive: #primitiveFailCounting accessorDepth: -1.

	callingMethod := self jitMethod: (self findMethod: #methodThatCallNamedPrimitiveCounting:).

	self initStack.	

	forwarder := self newZeroSizedObject.
	self keepObjectInVMVariable1: forwarder.

	interpreter gcMode: GCModeNewSpace.
	memory doScavenge: 1 "TenureByAge".

	self assert: (memory isForwarded: forwarder).

	receiver := self newObjectWithSlots: 1.
	memory storePointer: 0 ofObject: receiver withValue: forwarder. 

	self 
		callCogMethod: callingMethod 
		receiver: receiver 
		arguments: {memory trueObject}
		returnAddress: callerAddress.
	
	self assert: interpreter primitiveFailCount equals: 1.
	

]

{ #category : #'tests - retry primitive' }
VMPrimitiveCallingTest >> testNamedPrimitiveFailingWithNegativeAccessorDepthWithoutForwardersDoNotRetry [

	| callingMethod |

	interpreter primitiveFailCount: 0.
	interpreter codeGeneratorToComputeAccessorDepth addPrimitive: #primitiveFailCounting accessorDepth: -1.

	callingMethod := self jitMethod: (self findMethod: #methodThatCallNamedPrimitiveCounting:).

	self initStack.	

	self 
		callCogMethod: callingMethod 
		receiver: memory nilObject 
		arguments: {memory nilObject}
		returnAddress: callerAddress.
	
	self assert: interpreter primitiveFailCount equals: 1.
	

]

{ #category : #'tests - with tracing' }
VMPrimitiveCallingTest >> testNamedPrimitiveIsNotTracedIfNotCalled [

	| callingMethod |

	cogit sendTrace: 8.
	
	callingMethod := self jitMethod: (self findMethod: #methodThatCallNamedPrimitive:).
	
	self initStack.
	
	1 to: interpreter primTraceLogEntries - 1 do:
		[:i| self assert: (interpreter primTraceLog at: i) = 0].
	

]

{ #category : #'tests - newMethod' }
VMPrimitiveCallingTest >> testPrimitiveCallSetsNewMethod [

	| callingMethod |

	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:).

	self initStack.	

	self 
		callCogMethod: callingMethod 
		receiver: memory nilObject 
		arguments: {memory nilObject}
		returnAddress: callerAddress.
	
	self 
		assert: interpreter newMethod
		equals: callingMethod methodObject
	

]

{ #category : #'tests - primitiveFunctionPointer' }
VMPrimitiveCallingTest >> testPrimitiveCallSetsPrimitiveFunctionPointerWhenCallingCImplementation [

	| callingMethod |

	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:).

	self initStack.	

	self 
		callCogMethod: callingMethod 
		receiver: memory nilObject 
		arguments: {memory nilObject}
		returnAddress: callerAddress.
	
	self 
		assert: (cogit simulatedTrampolines at: interpreter primitiveFunctionPointer) selector
		equals: #primitiveAdd
	

]

{ #category : #'tests - retry primitive' }
VMPrimitiveCallingTest >> testPrimitiveFailingWithAccessorDepthWithForwardersDoesRetry [

	| callingMethod forwarder receiver |

	"Patching the primitive to remove primitiveFunction"
	interpreter primitiveFailCount: 0.
	interpreter primitiveTable at: 1 + 1 put: #primitiveFailCounting.
	interpreter primitiveAccessorDepthTable at: 1 put: 1.

	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:).

	self initStack.	

	forwarder := self newZeroSizedObject.
	self keepObjectInVMVariable1: forwarder.

	interpreter gcMode: GCModeNewSpace.
	memory doScavenge: 1 "TenureByAge".

	self assert: (memory isForwarded: forwarder).

	receiver := self newObjectWithSlots: 1.
	memory storePointer: 0 ofObject: receiver withValue: forwarder. 

	self 
		callCogMethod: callingMethod 
		receiver: receiver 
		arguments: {memory trueObject}
		returnAddress: callerAddress.
	
	self assert: interpreter primitiveFailCount equals: 2.
	

]

{ #category : #'tests - retry primitive' }
VMPrimitiveCallingTest >> testPrimitiveFailingWithAccessorDepthWithoutForwardersDoNotRetry [

	| callingMethod |

	"Patching the primitive to remove primitiveFunction"
	interpreter primitiveFailCount: 0.
	interpreter primitiveTable at: 1 + 1 put: #primitiveFailCounting.
	interpreter primitiveAccessorDepthTable at: 1 put: 1.

	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:).

	self initStack.	

	self 
		callCogMethod: callingMethod 
		receiver: memory nilObject 
		arguments: {memory nilObject}
		returnAddress: callerAddress.
	
	self assert: interpreter primitiveFailCount equals: 1.
	

]

{ #category : #'tests - retry primitive' }
VMPrimitiveCallingTest >> testPrimitiveFailingWithAccessorDepthZeroWithForwardersDoesNotRetry [

	| callingMethod forwarder receiver |

	"Patching the primitive to remove primitiveFunction"
	interpreter primitiveFailCount: 0.
	interpreter primitiveTable at: 1 + 1 put: #primitiveFailCounting.
	interpreter primitiveAccessorDepthTable at: 1 put: 0.

	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:).

	self initStack.	

	forwarder := self newZeroSizedObject.
	self keepObjectInVMVariable1: forwarder.

	interpreter gcMode: GCModeNewSpace.
	memory doScavenge: 1 "TenureByAge".

	self assert: (memory isForwarded: forwarder).

	receiver := self newObjectWithSlots: 1.
	memory storePointer: 0 ofObject: receiver withValue: forwarder. 

	self 
		callCogMethod: callingMethod 
		receiver: receiver 
		arguments: {memory trueObject}
		returnAddress: callerAddress.
	
	self assert: interpreter primitiveFailCount equals: 1.
	

]

{ #category : #'tests - retry primitive' }
VMPrimitiveCallingTest >> testPrimitiveFailingWithAccessorDepthZeroWithoutForwardersDoNotRetry [

	| callingMethod |

	"Patching the primitive to remove primitiveFunction"
	interpreter primitiveFailCount: 0.
	interpreter primitiveAccessorDepthTable at: 1 put: 0.
	interpreter primitiveTable at: 1 + 1 put: #primitiveFailCounting.

	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:).

	self initStack.	

	self 
		callCogMethod: callingMethod 
		receiver: memory nilObject 
		arguments: {memory nilObject}
		returnAddress: callerAddress.
	
	self assert: interpreter primitiveFailCount equals: 1.
	

]

{ #category : #'tests - retry primitive' }
VMPrimitiveCallingTest >> testPrimitiveFailingWithNegativeAccessorDepthWithForwardersDoNotRetry [

	| callingMethod forwarder receiver |

	"Patching the primitive to remove primitiveFunction"
	interpreter primitiveFailCount: 0.
	interpreter primitiveTable at: 1 + 1 put: #primitiveFailCounting.
	interpreter primitiveAccessorDepthTable at: 1 put: -1.

	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:).

	self initStack.	

	forwarder := self newZeroSizedObject.
	self keepObjectInVMVariable1: forwarder.

	interpreter gcMode: GCModeNewSpace.
	memory doScavenge: 1 "TenureByAge".

	self assert: (memory isForwarded: forwarder).

	receiver := self newObjectWithSlots: 1.
	memory storePointer: 0 ofObject: receiver withValue: forwarder. 

	self 
		callCogMethod: callingMethod 
		receiver: receiver 
		arguments: {memory trueObject}
		returnAddress: callerAddress.
	
	self assert: interpreter primitiveFailCount equals: 1.
	

]

{ #category : #'tests - retry primitive' }
VMPrimitiveCallingTest >> testPrimitiveFailingWithNegativeAccessorDepthWithoutForwardersDoNotRetry [

	| callingMethod |

	"Patching the primitive to remove primitiveFunction"
	interpreter primitiveFailCount: 0.
	interpreter primitiveTable at: 1 + 1 put: #primitiveFailCounting.
	interpreter primitiveAccessorDepthTable at: 1 put: -1.

	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:).

	self initStack.	

	self 
		callCogMethod: callingMethod 
		receiver: memory nilObject 
		arguments: {memory nilObject}
		returnAddress: callerAddress.
	
	self assert: interpreter primitiveFailCount equals: 1.
	

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

{ #category : #'tests - fail fast' }
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

{ #category : #'tests - profile sampling' }
VMPrimitiveCallingTest >> testPrimitiveWithProfileSemaphoreAndNextTickTakesSample [

	| callingMethod |

	"I have a profile semaphore, because I want to generate the code"
	interpreter profileSemaphore: self newZeroSizedObject.
	"I will not take samples"
	interpreter nextProfileTick: 1.

	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:).


	self initStack.	

	"When the sampling C routine is call, a check interrupt is force, so the activation of the fallback code aborts and go to the abort routine"
	self 
		callCogMethod: callingMethod 
		receiver: memory nilObject 
		arguments: {memory nilObject}
		returnAddress: cogit ceMethodAbortTrampoline.

	self assert: machineSimulator instructionPointerValue equals: cogit ceMethodAbortTrampoline.
	self assert: interpreter nextProfileTick equals: 0
]

{ #category : #'tests - profile sampling' }
VMPrimitiveCallingTest >> testPrimitiveWithProfileSemaphoreButNotNextTickDoesNotTakeSample [

	| callingMethod |

	"I have a profile semaphore, because I want to generate the code"
	interpreter profileSemaphore: self newZeroSizedObject.
	"I will not take samples"
	interpreter nextProfileTick: 0.

	callingMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:).

	self initStack.	

	"If the profile routine is not call the fallback code is executed normally"
	self 
		callCogMethod: callingMethod 
		receiver: memory nilObject 
		arguments: {memory nilObject}
		returnAddress: callerAddress.
		
	self assert: machineSimulator receiverRegisterValue equals: (memory integerObjectOf: 42)
]

{ #category : #'tests - fail fast' }
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
