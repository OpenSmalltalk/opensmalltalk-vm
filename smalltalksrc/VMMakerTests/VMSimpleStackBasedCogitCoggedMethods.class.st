Class {
	#name : #VMSimpleStackBasedCogitCoggedMethods,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
	#pools : [
		'CogMethodConstants'
	],
	#category : #VMMakerTests
}

{ #category : #running }
VMSimpleStackBasedCogitCoggedMethods >> setUp [
	super setUp.
	self setUpCogMethodEntry.
]

{ #category : #tests }
VMSimpleStackBasedCogitCoggedMethods >> testUsingEntryOffsetChecksClassRegisterAndContinue [

	| cogMethod otherBlock |
	otherBlock := self compile: [ cogit Nop ].
	cogMethod := self generateCogMethod: [ cogit Jump: otherBlock ] selector: memory falseObject.
	
	"Let's set the receiver class index in the classRegister"
	machineSimulator classRegisterValue: (memory classIndexOf: memory nilObject).
	
	self runFrom: cogMethod address + cogit entryOffset until: otherBlock.

	self assert: machineSimulator instructionPointerValue equals: otherBlock 
]

{ #category : #tests }
VMSimpleStackBasedCogitCoggedMethods >> testUsingEntryOffsetChecksClassRegisterAndGoesToAbort [

	| cogMethod otherBlock |
	otherBlock := self compile: [ cogit Nop ].
	cogMethod := self generateCogMethod: [ cogit Jump: otherBlock ] selector: memory falseObject.
	
	"Let's set any value in the ClassRegister"
	machineSimulator classRegisterValue: 16rFF.
	
	self runFrom: cogMethod address + cogit entryOffset until: cogit ceMethodAbortTrampoline.

	self assert: machineSimulator instructionPointerValue equals: cogit ceMethodAbortTrampoline 
]

{ #category : #tests }
VMSimpleStackBasedCogitCoggedMethods >> testUsingNoCheckEntryDoesNotCheckClassTag [

	| cogMethod otherBlock |
	otherBlock := self compile: [ cogit Nop ].
	cogMethod := self generateCogMethod: [ cogit Jump: otherBlock ] selector: memory falseObject.
	
	"Let's set any value in the ClassRegister"
	machineSimulator classRegisterValue: 16rFF.
	
	self runFrom: cogMethod address + cogit noCheckEntryOffset until: otherBlock.

	self assert: machineSimulator instructionPointerValue equals: otherBlock 
]
