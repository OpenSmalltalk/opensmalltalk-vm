Class {
	#name : #VMInterpreterTests,
	#superclass : #VMSpurMemoryManagerTest,
	#category : #'VMMakerTests-InterpreterTests'
}

{ #category : #running }
VMInterpreterTests >> setUp [
	
	"taken from VMSimpleStackBasedCogitBytecodeTest >> #setup"
	super setUp.
	
	memory nilObject: (self newObjectWithSlots: 0).
	memory trueObject: (self newObjectWithSlots: 0).
	memory falseObject: (self newObjectWithSlots: 0).
	
	"We don't access its contents, but we need it to be after nil, true and false"
	memory hiddenRootsObject: (self newObjectWithSlots: 0).
	interpreter := memory interpreter.
		
	self initializeOldSpaceForScavenger.

	


]
