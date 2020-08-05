Class {
	#name : #VMSpecialSendArithmethicTest,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
	#instVars : [
		'methodReceiver',
		'receiverOperationBlock',
		'argumentOperation',
		'codeAddress',
		'receiverValue',
		'argumentValue',
		'arguments'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #builder }
VMSpecialSendArithmethicTest >> argumentOperation: aFullBlockClosure [ 
	
	argumentOperation := aFullBlockClosure
]

{ #category : #builder }
VMSpecialSendArithmethicTest >> arguments: aCollection [ 
	arguments := aCollection
]

{ #category : #running }
VMSpecialSendArithmethicTest >> assertSpecialSendTo: receiverOop withArg: argOop [ 

	self assert: machineSimulator instructionPointerValue equals: sendTrampolineAddress.
	self assert: machineSimulator receiverRegisterValue equals: receiverOop.
	self assert: machineSimulator arg0RegisterValue equals: argOop.
]

{ #category : #builder }
VMSpecialSendArithmethicTest >> buildStackFrame [
	"Let's prepare the trampoline in case of non-optimized path"
	sentSelector := #+.
	self createSpecialSelectorArray.

	"We will call to this address"
	sendTrampolineAddress := self compile: [ cogit RetN: 0 ].
	cogit ordinarySendTrampolineAt: sentSelector numArgs put: sendTrampolineAddress.
	
	"Setting a value that is not the SmallInteger tag"
	cogit methodOrBlockNumTemps: "methodOrBlockNumTemps" 0 + arguments size.
	cogit methodOrBlockNumArgs: arguments size.
	cogit initSimStackForFramefulMethod: 0.
	cogit receiverTags: (memory fetchClassTagOf: methodReceiver).
	cogit regArgsHaveBeenPushed: false.

	self createFramefulCallFrom: callerAddress receiver: methodReceiver arguments: arguments temporaries: #().

]

{ #category : #builder }
VMSpecialSendArithmethicTest >> compileMethod [

	codeAddress := self compile: [ 
		               receiverOperationBlock value.
		               argumentOperation value.

		               cogit byte0: 176. "Special Send:#+"
		               cogit genSpecialSelectorArithmetic.
		               cogit genReturnTopFromMethod ]
]

{ #category : #running }
VMSpecialSendArithmethicTest >> jitCompilerClass [

	^ StackToRegisterMappingCogit 
]

{ #category : #builder }
VMSpecialSendArithmethicTest >> methodReceiver: anOop [ 
	methodReceiver := anOop
]

{ #category : #builder }
VMSpecialSendArithmethicTest >> receiverOperation: aFullBlockClosure [ 
	
	receiverOperationBlock := aFullBlockClosure
]

{ #category : #running }
VMSpecialSendArithmethicTest >> setUp [

	super setUp.
	methodReceiver := memory nilObject.
	arguments := #().
]

{ #category : #builder }
VMSpecialSendArithmethicTest >> shouldCallTrampolineWith: receiverOfOperation and: argumentOfOperation [ 

	self buildStackFrame.
	self compileMethod.
	
	self runFrom: codeAddress until: sendTrampolineAddress.
	self assertSpecialSendTo: receiverOfOperation value withArg: argumentOfOperation value
]

{ #category : #builder }
VMSpecialSendArithmethicTest >> shouldPerformOperationReturning: aValue [ 

	self buildStackFrame.
	self compileMethod.
	
	self runFrom: codeAddress until: callerAddress.
	
	self assert: machineSimulator receiverRegisterValue equals: (memory integerObjectOf: aValue).
]

{ #category : #'tests - receiver integer argument' }
VMSpecialSendArithmethicTest >> testSmallIntegerArgumentPlusIntegerSelfReturnsSmallInteger [
	
	self
		methodReceiver: (memory integerObjectOf: 42);
		arguments: { memory integerObjectOf: 52 };
		receiverOperation: [ cogit genPushTemporaryVariable: 0 ];
		argumentOperation: [ cogit ssPushDesc: cogit simSelf ];
		shouldPerformOperationReturning: 94
]

{ #category : #'tests - receiver integer argument' }
VMSpecialSendArithmethicTest >> testSmallIntegerArgumentPlusSmallIntegerArgumentCallsTrampoline [
	
	self
		arguments: { memory integerObjectOf: 52. memory integerObjectOf: 42. };
		receiverOperation: [ cogit genPushTemporaryVariable: 0 ];
		argumentOperation: [ cogit genPushTemporaryVariable: 1 ];
		shouldCallTrampolineWith: (memory integerObjectOf: 52) and: (memory integerObjectOf: 42)
]

{ #category : #'tests - receiver integer argument' }
VMSpecialSendArithmethicTest >> testSmallIntegerArgumentPlusSmallIntegerConstReturnsSmallInteger [
	
	self
		arguments: { memory integerObjectOf: 52 };
		receiverOperation: [ cogit genPushTemporaryVariable: 0 ];
		argumentOperation: [ cogit ssPushConstant: (memory integerObjectOf: 42) ];
		shouldPerformOperationReturning: 94.
]

{ #category : #'tests - receiver integer argument' }
VMSpecialSendArithmethicTest >> testSmallIntegerArgumentPlusTrueConstCallsTrampoline [
	
	self
		arguments: { memory integerObjectOf: 52 };
		receiverOperation: [ cogit genPushTemporaryVariable: 0 ];
		argumentOperation: [ cogit ssPushConstant: (memory trueObject) ];
		shouldCallTrampolineWith: (memory integerObjectOf: 52) and: memory trueObject
]

{ #category : #'tests - receiver integer argument' }
VMSpecialSendArithmethicTest >> testSmallIntegerArgumentPlusTrueSelfCallsTrampoline [
	
	self
		methodReceiver: memory trueObject;
		arguments: { memory integerObjectOf: 52 };
		receiverOperation: [ cogit genPushTemporaryVariable: 0 ];
		argumentOperation: [ cogit ssPushDesc: cogit simSelf ];
		shouldCallTrampolineWith: (memory integerObjectOf: 52) and: memory trueObject
]

{ #category : #'tests - receiver constant integer' }
VMSpecialSendArithmethicTest >> testSmallIntegerConstPlusSmallIntegerArgumentReturnsSmallInteger [
	
	self
		arguments: { memory integerObjectOf: 52 };
		receiverOperation: [ cogit ssPushConstant: (memory integerObjectOf: 42) ];
		argumentOperation: [ cogit genPushTemporaryVariable: 0 ];
		shouldPerformOperationReturning: 94.	

]

{ #category : #'tests - receiver constant integer' }
VMSpecialSendArithmethicTest >> testSmallIntegerConstPlusSmallIntegerConstReturnsSmallInteger [
	
	self
		receiverOperation: [ cogit ssPushConstant: (memory integerObjectOf: 42) ];
		argumentOperation: [ cogit ssPushConstant: (memory integerObjectOf: 52) ];
		shouldPerformOperationReturning: 94.	

]

{ #category : #'tests - receiver constant integer' }
VMSpecialSendArithmethicTest >> testSmallIntegerConstPlusSmallIntegerSelfReturnsSmallInteger [
	
	self
		methodReceiver: (memory integerObjectOf: 52);
		receiverOperation: [ cogit ssPushConstant: (memory integerObjectOf: 42) ];
		argumentOperation: [ cogit ssPushDesc: cogit simSelf ];
		shouldPerformOperationReturning: 94.	
	
]

{ #category : #'tests - receiver constant integer' }
VMSpecialSendArithmethicTest >> testSmallIntegerConstPlusTrueArgumentCallsTrampoline [
	
	
	self
		arguments: { memory trueObject };
		receiverOperation: [ cogit ssPushConstant: (memory integerObjectOf: 42) ];
		argumentOperation: [ cogit genPushTemporaryVariable: 0 ];
		shouldCallTrampolineWith: [ memory integerObjectOf: 42 ] and: [ memory trueObject ].	
]

{ #category : #'tests - receiver constant integer' }
VMSpecialSendArithmethicTest >> testSmallIntegerConstPlusTrueConstCallsTrampoline [
	
	self
		receiverOperation: [ cogit ssPushConstant: (memory integerObjectOf: 42) ];
		argumentOperation: [ cogit ssPushConstant: memory trueObject ];
		shouldCallTrampolineWith: [ memory integerObjectOf: 42 ] and: [ memory trueObject ].	

]

{ #category : #'tests - receiver constant integer' }
VMSpecialSendArithmethicTest >> testSmallIntegerConstPlusTrueSelfCallsTrampoline [


	self
		methodReceiver: memory trueObject;
		receiverOperation: [ cogit ssPushConstant: (memory integerObjectOf: 42) ];
		argumentOperation: [ cogit ssPushDesc: cogit ssSelfDescriptor ];
		shouldCallTrampolineWith: [ memory integerObjectOf: 42 ] and: [ memory trueObject ].	
]

{ #category : #'tests - receiver integer self' }
VMSpecialSendArithmethicTest >> testSmallIntegerSelfPlusSmallIntegerArgumentReturnsSmallInteger [
		
	self
		methodReceiver: (memory integerObjectOf: 42);
		arguments: { (memory integerObjectOf: 52) };
		receiverOperation: [ cogit ssPushDesc: cogit ssSelfDescriptor ];
		argumentOperation: [ cogit genPushTemporaryVariable: 0 ];
		shouldPerformOperationReturning: 94
]

{ #category : #'tests - receiver integer self' }
VMSpecialSendArithmethicTest >> testSmallIntegerSelfPlusSmallIntegerConstReturnsSmallInteger [
	
	self
		methodReceiver: (memory integerObjectOf: 52);
		receiverOperation: [ cogit ssPushDesc: cogit simSelf ];
		argumentOperation: [ cogit ssPushConstant: (memory integerObjectOf: 42) ];
		shouldPerformOperationReturning: 94.	

]

{ #category : #'tests - receiver integer self' }
VMSpecialSendArithmethicTest >> testSmallIntegerSelfPlusSmallIntegerSelfReturnsSmallInteger [
		
	self
		methodReceiver: (memory integerObjectOf: 42);
		receiverOperation: [ cogit ssPushDesc: cogit ssSelfDescriptor ];
		argumentOperation: [ cogit ssPushDesc: cogit ssSelfDescriptor ];
		shouldPerformOperationReturning: 84
]

{ #category : #'tests - receiver integer self' }
VMSpecialSendArithmethicTest >> testSmallIntegerSelfPlusTrueArgumentCallsTrampoline [
		
	self
		methodReceiver: (memory integerObjectOf: 42);
		arguments: { memory trueObject };
		receiverOperation: [ cogit ssPushDesc: cogit ssSelfDescriptor ];
		argumentOperation: [ cogit genPushTemporaryVariable: 0];
		shouldCallTrampolineWith: [ memory integerObjectOf: 42 ] and: [ memory trueObject ]
]

{ #category : #'tests - receiver integer self' }
VMSpecialSendArithmethicTest >> testSmallIntegerSelfPlusTrueConstCallsTrampoline [
		
	self
		methodReceiver: (memory integerObjectOf: 42);
		receiverOperation: [ cogit ssPushDesc: cogit ssSelfDescriptor ];
		argumentOperation: [ cogit ssPushConstant: (memory trueObject)];
		shouldCallTrampolineWith: [ memory integerObjectOf: 42 ] and: [ memory trueObject ]
]

{ #category : #'tests - receiver constant not integer' }
VMSpecialSendArithmethicTest >> testTrueConstPlusFalseArgumentCallsTrampoline [
	
	self
		arguments: {memory falseObject};
		receiverOperation: [ cogit ssPushConstant: (memory trueObject) ];
		argumentOperation: [ cogit genPushTemporaryVariable: 0 ];
		shouldCallTrampolineWith: [ memory trueObject ] and: [ memory falseObject ]
]

{ #category : #'tests - receiver constant not integer' }
VMSpecialSendArithmethicTest >> testTrueConstPlusFalseConstCallsTrampoline [
	
	self
		receiverOperation: [ cogit ssPushConstant: (memory trueObject) ];
		argumentOperation: [ cogit ssPushConstant: (memory falseObject)];
		shouldCallTrampolineWith: [ memory trueObject ] and: [ memory falseObject ]
]

{ #category : #'tests - receiver constant not integer' }
VMSpecialSendArithmethicTest >> testTrueConstPlusFalseSelfCallsTrampoline [
	
	self
		methodReceiver: (memory falseObject);
		receiverOperation: [ cogit ssPushConstant: (memory trueObject) ];
		argumentOperation: [ cogit ssPushDesc: cogit ssSelfDescriptor ];
		shouldCallTrampolineWith: [ memory trueObject ] and: [ memory falseObject ]
]

{ #category : #'tests - receiver constant not integer' }
VMSpecialSendArithmethicTest >> testTrueConstPlusSmallIntegerArgumentCallsTrampoline [
	
	self
		arguments: {memory integerObjectOf: 42};
		receiverOperation: [ cogit ssPushConstant: (memory trueObject) ];
		argumentOperation: [ cogit genPushTemporaryVariable: 0 ];
		shouldCallTrampolineWith: [ memory trueObject ] and: [ memory integerObjectOf: 42 ]
]

{ #category : #'tests - receiver constant not integer' }
VMSpecialSendArithmethicTest >> testTrueConstPlusSmallIntegerConstCallsTrampoline [
	
	self
		receiverOperation: [ cogit ssPushConstant: (memory trueObject) ];
		argumentOperation: [ cogit ssPushConstant: (memory integerObjectOf: 42) ];
		shouldCallTrampolineWith: [ memory trueObject ] and: [ memory integerObjectOf: 42 ].		
]

{ #category : #'tests - receiver constant not integer' }
VMSpecialSendArithmethicTest >> testTrueConstPlusSmallIntegerSelfCallsTrampoline [
	
	self
		methodReceiver: (memory integerObjectOf: 17);
		receiverOperation: [ cogit ssPushConstant: (memory trueObject) ];
		argumentOperation: [ cogit ssPushDesc: cogit ssSelfDescriptor ];
		shouldCallTrampolineWith: [ memory trueObject ] and: [ methodReceiver ]
]

{ #category : #'tests - receiver non integer self' }
VMSpecialSendArithmethicTest >> testTrueSelfPlusFalseArgumentCallsTrampoline [
			
	self
		methodReceiver: memory trueObject;
		arguments: { memory falseObject };
		receiverOperation: [ cogit ssPushDesc: cogit ssSelfDescriptor ];
		argumentOperation: [ cogit genPushTemporaryVariable: 0 ];
		shouldCallTrampolineWith: [ memory trueObject ] and: [ memory falseObject ].		
]

{ #category : #'tests - receiver non integer self' }
VMSpecialSendArithmethicTest >> testTrueSelfPlusFalseConstCallsTrampoline [
			
	self
		methodReceiver: memory trueObject;
		receiverOperation: [ cogit ssPushDesc: cogit ssSelfDescriptor ];
		argumentOperation: [ cogit ssPushConstant: (memory falseObject) ];
		shouldCallTrampolineWith: [ memory trueObject ] and: [ memory falseObject ].		
]

{ #category : #'tests - receiver non integer self' }
VMSpecialSendArithmethicTest >> testTrueSelfPlusSmallIntegerArgumentCallsTrampoline [
			
	self
		methodReceiver: memory trueObject;
		arguments: { memory integerObjectOf: 42 };
		receiverOperation: [ cogit ssPushDesc: cogit ssSelfDescriptor ];
		argumentOperation: [ cogit genPushTemporaryVariable: 0 ];
		shouldCallTrampolineWith: [ memory trueObject ] and: [ memory integerObjectOf: 42 ].		
]

{ #category : #'tests - receiver non integer self' }
VMSpecialSendArithmethicTest >> testTrueSelfPlusSmallIntegerConstCallsTrampoline [
			
	self
		methodReceiver: memory trueObject;
		receiverOperation: [ cogit ssPushDesc: cogit ssSelfDescriptor ];
		argumentOperation: [ cogit ssPushConstant: (memory integerObjectOf: 42) ];
		shouldCallTrampolineWith: [ memory trueObject ] and: [ memory integerObjectOf: 42 ].		
]

{ #category : #'tests - receiver non integer self' }
VMSpecialSendArithmethicTest >> testTrueSelfPlusTrueSelfCallsTrampoline [
			
	self
		methodReceiver: memory trueObject;
		receiverOperation: [ cogit ssPushDesc: cogit ssSelfDescriptor ];
		argumentOperation: [ cogit ssPushDesc: cogit ssSelfDescriptor ];
		shouldCallTrampolineWith: [ memory trueObject ] and: [ memory trueObject ].		
]
