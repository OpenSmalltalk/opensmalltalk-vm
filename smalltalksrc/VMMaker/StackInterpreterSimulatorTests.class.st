Class {
	#name : #StackInterpreterSimulatorTests,
	#superclass : #TestCase,
	#category : 'VMMaker-Tests'
}

{ #category : #accessing }
StackInterpreterSimulatorTests class >> imageNameForTests [
	"self imageNameForTests"
	| baseImageName |
	baseImageName := 'core32-preen.image'.
	#('.' 'oscogvm/image' '../oscogvm/image') do:
		[:dirName|
		 ((FileDirectory default directoryExists: dirName)
		  and: [(FileDirectory on: dirName) fileExists: baseImageName]) ifTrue:
			[^dirName, '/', baseImageName]].
	self error: 'cannot find ', baseImageName
]

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
					openOn: self class imageNameForTests extraMemory: 0]
		raise: Error
]

{ #category : #tests }
StackInterpreterSimulatorTests >> testSimulatorCanReloadImage [
	self shouldnt:
			[(StackInterpreterSimulator newWithOptions: #(ObjectMemory Spur32BitMemoryManager))
				openOn: self class imageNameForTests extraMemory: 0;
				openOn: self class imageNameForTests extraMemory: 0]
		raise: Error
]
