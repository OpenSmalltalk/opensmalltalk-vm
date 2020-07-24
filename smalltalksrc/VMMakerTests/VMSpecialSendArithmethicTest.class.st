Class {
	#name : #VMSpecialSendArithmethicTest,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
	#instVars : [
		'argument1',
		'constant2',
		'receiver',
		'argument2',
		'constant1'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #running }
VMSpecialSendArithmethicTest >> assertSpecialSendTo: receiverOop withArg: argOop [ 

	self assert: machineSimulator instructionPointerValue equals: sendTrampolineAddress.
	self assert: machineSimulator receiverRegisterValue equals: receiverOop.
	self assert: machineSimulator arg0RegisterValue equals: argOop.
]

{ #category : #running }
VMSpecialSendArithmethicTest >> assertSumOfIntegerReceiver: aReceiverBlock andIntegerArgument: anArgumentBlock returns: aValue [

	| codeAddress  argument arguments receiverOop |
	
	receiverOop :=  memory integerObjectOf: receiver.
	argument := memory integerObjectOf: argument1.
	arguments := { argument }.

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
	cogit receiverTags: memory smallIntegerTag.
	cogit regArgsHaveBeenPushed: false.

	self
		createFramefulCallFrom: callerAddress
		receiver: receiverOop
		arguments: arguments
		temporaries: #().
	
	codeAddress := self compile: [
		aReceiverBlock value.
		anArgumentBlock value.
		
		cogit byte0: 176. "Special Send:#+"
		cogit genSpecialSelectorArithmetic.
		cogit genReturnTopFromMethod ].
	
	self runFrom: codeAddress until: callerAddress.
	
	self assert: machineSimulator receiverRegisterValue equals: (memory integerObjectOf: aValue).
]

{ #category : #'tests non smi sum' }
VMSpecialSendArithmethicTest >> assertSumOfIntegerReceiver: aReceiverBlock andNonIntegerArgument: anArgumentBlock callsTrampolineWithReceiver: receiverValue andArgument: argumentValue [
	
	| codeAddress |

	"Let's prepare the trampoline in case of non-optimized path"
	sentSelector := #+.
	self createSpecialSelectorArray.

	"We will call to this address"
	sendTrampolineAddress := self compile: [ cogit RetN: 0 ].
	cogit ordinarySendTrampolineAt: sentSelector numArgs put: sendTrampolineAddress.
	
	"Setting a value that is not the SmallInteger tag"
	cogit methodOrBlockNumTemps: 0.
	cogit initSimStackForFramefulMethod: 0.
	cogit receiverTags: 0.
	cogit regArgsHaveBeenPushed: false.

	self createFramefulCallFrom: callerAddress receiver: memory trueObject arguments: #() temporaries: #().
	
	codeAddress := self compile: [
		aReceiverBlock value.
		anArgumentBlock value.

		cogit byte0: 176. "Special Send:#+"
		cogit genSpecialSelectorArithmetic.
		cogit genReturnTopFromMethod ].
	
	self runFrom: codeAddress until: sendTrampolineAddress.
	
	self assertSpecialSendTo: receiverValue withArg: argumentValue
]

{ #category : #running }
VMSpecialSendArithmethicTest >> jitCompilerClass [

	^ StackToRegisterMappingCogit 
]

{ #category : #running }
VMSpecialSendArithmethicTest >> setUp [

	super setUp.
	receiver := 1.
	argument1 := 10.
	argument2 := 100.
	constant1 := 1000.
	constant2 := 10000.
]

{ #category : #'tests smi + smi' }
VMSpecialSendArithmethicTest >> testSmallIntegerArgumentPlusSmallIntegerConstReturnsSmallInteger [
	
	self
		assertSumOfIntegerReceiver: [ cogit genPushTemporaryVariable: 0 ]
		andIntegerArgument: [ cogit ssPushConstant: (memory integerObjectOf: constant2) ]
		returns: argument1 + constant2
]

{ #category : #'tests smi + smi' }
VMSpecialSendArithmethicTest >> testSmallIntegerConstPlusSmallIntegerArgumentReturnsSmallInteger [
	
	self
		assertSumOfIntegerReceiver: [ cogit ssPushConstant: (memory integerObjectOf: constant2) ]
		andIntegerArgument: [ cogit genPushTemporaryVariable: 0 ]
		returns: argument1 + constant2
]

{ #category : #'tests smi + smi' }
VMSpecialSendArithmethicTest >> testSmallIntegerConstPlusSmallIntegerConstReturnsSmallInteger [
	
	self
		assertSumOfIntegerReceiver: [ cogit ssPushConstant: (memory integerObjectOf: constant1) ]
		andIntegerArgument: [ cogit ssPushConstant: (memory integerObjectOf: constant2) ]
		returns: constant1 + constant2
]

{ #category : #'tests smi + smi' }
VMSpecialSendArithmethicTest >> testSmallIntegerConstPlusSmallIntegerSelfReturnsSmallInteger [
	
	self
		assertSumOfIntegerReceiver: [ cogit ssPushConstant: (memory integerObjectOf: constant1) ]
		andIntegerArgument: [ cogit ssPushDesc: cogit simSelf ]
		returns: constant1 + receiver
]

{ #category : #'tests non smi sum' }
VMSpecialSendArithmethicTest >> testSmallIntegerConstPlusTrueConstCallsTrampoline [
	
	self
		assertSumOfIntegerReceiver: [ cogit ssPushConstant: (memory integerObjectOf: 42) ]
		andNonIntegerArgument: [ cogit ssPushConstant: memory trueObject ]
		callsTrampolineWithReceiver: (memory integerObjectOf: 42)
		andArgument: memory trueObject
]

{ #category : #'tests non smi sum' }
VMSpecialSendArithmethicTest >> testSmallIntegerConstPlusTrueSelfCallsTrampoline [
	
	self
		assertSumOfIntegerReceiver: [ cogit ssPushConstant: (memory integerObjectOf: 54) ]
		andNonIntegerArgument: [ cogit ssPushDesc: cogit ssSelfDescriptor ]
		callsTrampolineWithReceiver: (memory integerObjectOf: 54)
		andArgument: memory trueObject
]

{ #category : #'tests smi + smi' }
VMSpecialSendArithmethicTest >> testSmallIntegerSelfPlusSmallIntegerConstReturnsSmallInteger [
	
	self
		assertSumOfIntegerReceiver: [ cogit ssPushDesc: cogit ssSelfDescriptor. ]
		andIntegerArgument: [ cogit ssPushConstant: (memory integerObjectOf: constant2) ]
		returns: receiver + constant2
]

{ #category : #'tests non smi sum' }
VMSpecialSendArithmethicTest >> testTrueConstPlusFalseConstCallsTrampoline [
	
	self
		assertSumOfIntegerReceiver: [ cogit ssPushConstant: memory falseObject ]
		andNonIntegerArgument: [ cogit ssPushConstant: memory trueObject ]
		callsTrampolineWithReceiver: memory falseObject
		andArgument: memory trueObject
]

{ #category : #'tests non smi sum' }
VMSpecialSendArithmethicTest >> testTrueConstPlusSmallIntegerConstCallsTrampoline [
	
	self
		assertSumOfIntegerReceiver: [ cogit ssPushConstant: memory trueObject ]
		andNonIntegerArgument: [ cogit ssPushConstant: (memory integerObjectOf: 42) ]
		callsTrampolineWithReceiver: memory trueObject
		andArgument: (memory integerObjectOf: 42)
]

{ #category : #'tests non smi sum' }
VMSpecialSendArithmethicTest >> testTrueSelfPlusSmallIntegerConstCallsTrampoline [
	
	self
		assertSumOfIntegerReceiver: [ cogit ssPushDesc: cogit ssSelfDescriptor. ]
		andNonIntegerArgument: [ cogit ssPushConstant: (memory integerObjectOf: 54) ]
		callsTrampolineWithReceiver: memory trueObject
		andArgument: (memory integerObjectOf: 54)
]
