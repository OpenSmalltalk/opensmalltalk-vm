Class {
	#name : #VMCodeCompactionTest,
	#superclass : #VMPrimitiveCallAbstractTest,
	#pools : [
		'CogRTLOpcodes'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #tests }
VMCodeCompactionTest >> fillCodeZone [

	| aMethod |

	[aMethod := self jitMethod: (self findMethod: #methodToCompile1).
	aMethod ifNotNil: [ aMethod cmUsageCount: 0 ].
	aMethod isNotNil ] whileTrue.


]

{ #category : #tests }
VMCodeCompactionTest >> testCompactDuringInterpreterPrimitiveThatMovesCurrentMethodShouldNotCrash [

	| firstMethod compactMethod |
	
	<expectedFailure>

	"Patching the primitive to execute the method I need to force the code compaction"
	interpreter primitiveTable at: 1 + 1 put: #primitiveForceMachineCodeCompaction.

	cogit sendTrace: 0.
	
	firstMethod := self jitMethod: (self findMethod: #methodToCompile1).
	compactMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:).
	
	self fillCodeZone.

	firstMethod cmUsageCount: 0.

	self createBaseFrame.
	
	"Initialize Stack to the correct pointers in the selected page"
	machineSimulator stackPointerRegisterValue: interpreter stackPointer.
	machineSimulator framePointerRegisterValue: interpreter framePointer.
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	
	cogit setCStackPointer: interpreter rumpCStackAddress.
	cogit setCFramePointer: interpreter rumpCStackAddress.
	
	self pushAddress: memory nilObject.
	self pushAddress: memory falseObject.

	self prepareCall.
	machineSimulator instructionPointerValue: compactMethod address + cogit noCheckEntryOffset. 
	
	self runFrom: compactMethod address + cogit noCheckEntryOffset until: callerAddress.

	self assert: machineSimulator receiverRegisterValue equals: memory trueObject.
	

]

{ #category : #tests }
VMCodeCompactionTest >> testCompactingAnUnusedMethodCompactsRemainingMethodToTheBeginning [

	| firstMethod compactMethod methodOop |
	firstMethod := self jitMethod: (self findMethod: #methodToCompile1) selector: memory trueObject.
	compactMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:) selector: memory falseObject.

	self fillCodeZone.

	methodOop := compactMethod methodObject.

	firstMethod cmUsageCount: 0.
	self createBaseFrame.

	self assert: (interpreter cogMethodOf: methodOop) equals: compactMethod address.

	interpreter commenceCogCompiledCodeCompaction.

	self assert: (interpreter cogMethodOf: methodOop) equals: firstMethod address

]
