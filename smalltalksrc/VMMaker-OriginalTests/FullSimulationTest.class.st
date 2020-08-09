Class {
	#name : #FullSimulationTest,
	#superclass : #TestCase,
	#category : #'VMMaker-OriginalTests'
}

{ #category : #'as yet unclassified' }
FullSimulationTest >> testSimulate2MillionBytecodes [
	<timeout: 120>
	| vm om |
	vm := StackInterpreterSimulator newWithOptions: (Smalltalk isRunningSpur
		ifTrue: [Smalltalk wordSize = 4
			ifTrue: [#(#ObjectMemory #Spur32BitMemoryManager )]
			ifFalse: [#(#ObjectMemory #Spur64BitMemoryManager )]]
		ifFalse: [#(#ObjectMemory)]).
	om := vm objectMemory.
	vm desiredNumStackPages: 8. "Makes simulation faster by creating fewer stack pages."
	vm openOn: Smalltalk imageName.
	vm instVarNamed: 'assertVEPAES' put: false. "This makes the simulation faster by turning off some expensive asserts"
	[[vm runForNBytes: 1500000]
		on: Halt , ProvideAnswerNotification "This exception handler ignores some halts and confirmers occurring during simulation"
		do: [:ex | 
			ex messageText == #primitiveExecuteMethodArgsArray
				ifTrue: [ex resume].
			ex messageText = 'clear transcript?'
				ifTrue: [ex resume: false].
			ex pass]] ensure: [Display restore].
]
