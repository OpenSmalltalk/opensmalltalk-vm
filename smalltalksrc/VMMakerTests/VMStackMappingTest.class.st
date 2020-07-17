Class {
	#name : #VMStackMappingTest,
	#superclass : #VMSpurMemoryManagerTest,
	#category : #'VMMakerTests-MemoryTests'
}

{ #category : #helpers }
VMStackMappingTest >> newContext [
	| method |
	method:= self newMethodWithBytecodes: #(1 2 3 4 5 6 7 8).
	^self newSmallContextReceiver: memory nilObject method: method arguments: #() temporaries: #() ip: 10.
]

{ #category : #tests }
VMStackMappingTest >> testCreatingNewContextByHandShouldbeSingle [

	self assert: (interpreter isSingleContext: self newContext)
]

{ #category : #tests }
VMStackMappingTest >> testDivorceAMarriedContextShuoldMakeItSingle [
	| context fp |
	context := self newContext.
	interpreter marryContextInNewStackPageAndInitializeInterpreterRegisters: context.
	fp := interpreter frameOfMarriedContext: context. 
	interpreter externalDivorceFrame: fp andContext: context.
	self assert: (interpreter isSingleContext: context)
]

{ #category : #tests }
VMStackMappingTest >> testMarryNewContextIsMarried [
	| context |
	context := self newContext.
	interpreter marryContextInNewStackPageAndInitializeInterpreterRegisters: context.
	self assert: (interpreter isStillMarriedContext: context)
]
