Class {
	#name : #VMSimpleStackBasedCogitMonomorphicPICTest,
	#superclass : #VMSimpleStackBasedCogitBytecodeTest,
	#category : #VMMakerTests
}

{ #category : #'tests - PIC' }
VMSimpleStackBasedCogitMonomorphicPICTest >> setUpCogMethodEntry [
	
	cogit ceCPICMissTrampoline: (self compile: [ cogit RetN: 0 ]).
	cogit cePICAbortTrampoline: (self compile: [ cogit RetN: 0 ]).
	cogit ceMethodAbortTrampoline: (self compile: [ cogit RetN: 0 ]).
	
	cogit computeEntryOffsets.
]

{ #category : #'tests - PIC' }
VMSimpleStackBasedCogitMonomorphicPICTest >> testCalculateClosePICSize [

	"Calculate the size of the Closed Pic"
	self setUpCogMethodEntry.
	cogit generateClosedPICPrototype.
	
	self assert: cogit closedPICSize isNotNil
]

{ #category : #'tests - PIC' }
VMSimpleStackBasedCogitMonomorphicPICTest >> testLinkCallDuringSendInTrampolineReplacesTheCallTargetWithTheCogMethodAddress [

	"This is for the monomorphic case"

	| sendingMethod targetCog selector executedTheTrampoline |
	self setUpCogMethodEntry.
	sendTrampolineAddress := self compile: [ cogit RetN: 0 ].
	cogit ordinarySendTrampolineAt: 0 "num args" put: sendTrampolineAddress.

	selector := memory falseObject.
	targetCog := self generateCogMethod: [ cogit RetN: 0 ] selector: selector.
	
	self createFramefulCallFrom: callerAddress.
	
	cogit byte0: 0.
	sendingMethod := self newMethodWithLiteral: selector at: 0.
	cogit methodObj: sendingMethod.
	sendAddress := self compile: [ cogit genSendLiteralSelector0ArgsBytecode ].

	"Push receiver then send"
	self pushAddress: memory falseObject.
	self runFrom: sendAddress until: sendTrampolineAddress.
	
	cogit 
		linkSendAt: unicorn getReturnAddress 
		in: sendingMethod 
		to: targetCog 
		offset: cogit entryOffset 
		receiver: memory falseObject.

	self pushAddress: memory falseObject.

	executedTheTrampoline := false.
	unicorn 
		registerHook: [executedTheTrampoline := true] 
		atAddress: sendTrampolineAddress.

	self runFrom: sendAddress until: targetCog asInteger + cogit entryOffset.
  	self deny: executedTheTrampoline.

]

{ #category : #'tests - PIC' }
VMSimpleStackBasedCogitMonomorphicPICTest >> testMissOffsetIsEqualsToEntryOffset [

	"Calculate the size of the Closed Pic"
	self setUpCogMethodEntry.
	cogit generateClosedPICPrototype.

	self assert: cogit missOffset equals: cogit entryOffset
]
