Class {
	#name : #VMTestMockInterpreter,
	#superclass : #StackInterpreterSimulatorLSB,
	#instVars : [
		'interpreteBlock'
	],
	#category : #VMMakerTests
}

{ #category : #accessing }
VMTestMockInterpreter >> enterSmalltalkExecutiveImplementation [ 

	interpreteBlock value
]

{ #category : #accessing }
VMTestMockInterpreter >> interpreteBlock [
	^ interpreteBlock
]

{ #category : #accessing }
VMTestMockInterpreter >> interpreteBlock: anObject [
	interpreteBlock := anObject
]
