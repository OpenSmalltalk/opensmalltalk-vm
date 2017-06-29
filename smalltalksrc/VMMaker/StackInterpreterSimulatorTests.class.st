Class {
	#name : #StackInterpreterSimulatorTests,
	#superclass : #TestCase,
	#category : #'VMMaker-Tests'
}

{ #category : #tests }
StackInterpreterSimulatorTests >> testEmptySimulatorCanCloneSimulation [
	self shouldnt:
			[(StackInterpreterSimulator newWithOptions: #(ObjectMemory Spur32BitMemoryManager))
				cloneSimulation cloneSimulation]
		raise: Error
]

{ #category : #tests }
StackInterpreterSimulatorTests >> testEmptySimulatorCloneCanLoadImage [
	self shouldnt:
			[(StackInterpreterSimulator newWithOptions: #(ObjectMemory Spur32BitMemoryManager))
				cloneSimulation
					openOn: SpurImageTestResource imageNameForTests extraMemory: 0]
		raise: Error
]

{ #category : #tests }
StackInterpreterSimulatorTests >> testSimulatorCanReloadImage [
	self shouldnt:
			[(StackInterpreterSimulator newWithOptions: #(ObjectMemory Spur32BitMemoryManager))
				openOn: SpurImageTestResource imageNameForTests extraMemory: 0;
				openOn: SpurImageTestResource imageNameForTests extraMemory: 0]
		raise: Error
]
