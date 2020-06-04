Class {
	#name : #VMSimpleStackBasedCogitPolymorphicPICTest,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
	#instVars : [
		'selector',
		'numArgs',
		'receiver',
		'receiverTag',
		'picTypeTags',
		'cogMethods',
		'compiledMethods',
		'configuredPicCases'
	],
	#pools : [
		'CogMethodConstants'
	],
	#category : #VMMakerTests
}

{ #category : #'building suites' }
VMSimpleStackBasedCogitPolymorphicPICTest class >> testParameters [

	^ super testParameters * 
		(ParametrizedTestMatrix new
			forSelector: #configuredPicCases addOptions: (2 to: 6);
			yourself)
]

{ #category : #helpers }
VMSimpleStackBasedCogitPolymorphicPICTest >> assertHitAtCase: aCase [
	| pic |
	"Only run this test if the test is configured for so much cases"
	aCase < self configuredPicCases ifFalse: [ ^ self skip ].
	
	picTypeTags at: aCase put: receiverTag.
	pic := self makePolymorphicPIC.
	self assertPIC: pic hits: (cogMethods at: aCase)
]

{ #category : #helpers }
VMSimpleStackBasedCogitPolymorphicPICTest >> assertPIC: pic hits: hitMethod [
	"Receiver is nil, class tag of the first entry is the receiver's class tag.
	 - the receiver matches class tag for case 0
	 - the receiver does not match with the class tag for case 1
	 - so it should call method for case 0"
	machineSimulator receiverRegisterValue: receiver.
	machineSimulator classRegisterValue: (picTypeTags at: 0).

	"Should call method 1 just after the type check (to avoid it).
	The check was already done in the PIC"
	self runFrom: pic address + cogit entryOffset until: hitMethod address + cogit noCheckEntryOffset.

	"When a PIC Hits
	 - The instruction pointer is at no check entry offset of the hitted method
	 - The class register value case 0 tag regardless of the hit
	 - the receiver register value contains the receiver"
	self assert: machineSimulator instructionPointerValue equals: hitMethod address + cogit noCheckEntryOffset.
	self assert: machineSimulator classRegisterValue equals: (picTypeTags at: 0).
	self assert: machineSimulator receiverRegisterValue equals: receiver
]

{ #category : #helpers }
VMSimpleStackBasedCogitPolymorphicPICTest >> assertPICMiss: pic [

	"Receiver is nil, class tag of the first entry is 1 (a small integer).
	 - the receiver does not match with the class tag for case 0
	 - the receiver does not match with the class tag for case 1
	 - so it should call the closed pic miss trampoline"
	machineSimulator receiverRegisterValue: receiver.
	machineSimulator classRegisterValue: (picTypeTags at: 0).

	self runFrom: pic address + cogit entryOffset until: cogit ceCPICMissTrampoline.

	"Failing all two PIC cases calls the pic trampoline.
	 - The instruction pointer is at the trampoline
	 - The class register value contains the pic
	 - the receiver register value contains the receiver"	
	self assert: machineSimulator instructionPointerValue equals: cogit ceCPICMissTrampoline.
	self assert: machineSimulator classRegisterValue equals: pic address.
	self assert: machineSimulator receiverRegisterValue equals: receiver
]

{ #category : #helpers }
VMSimpleStackBasedCogitPolymorphicPICTest >> configuredPicCases [
	
	^ configuredPicCases
]

{ #category : #helpers }
VMSimpleStackBasedCogitPolymorphicPICTest >> configuredPicCases: aNumber [
	
	configuredPicCases := aNumber
]

{ #category : #helpers }
VMSimpleStackBasedCogitPolymorphicPICTest >> extendPIC: aPic [

	cogit
		cogExtendPIC: aPic
		CaseNMethod: (compiledMethods at: aPic cPICNumCases)
		tag: (picTypeTags at: aPic cPICNumCases)
		isMNUCase: false.
]

{ #category : #helpers }
VMSimpleStackBasedCogitPolymorphicPICTest >> makePolymorphicPIC [

	| pic |
	pic := cogit cogPICSelector: selector
		numArgs: numArgs
		Case0Method: (cogMethods at: 0)
		Case1Method: (compiledMethods at: 1)
		tag: (picTypeTags at: 1)
		isMNUCase: false.
	3 to: self configuredPicCases do: [ :extraCase |
		self extendPIC: pic ].
	^ pic
]

{ #category : #running }
VMSimpleStackBasedCogitPolymorphicPICTest >> setUp [

	super setUp.
	self setUpCogMethodEntry.
	cogit generateClosedPICPrototype.

	cogit methodZone manageFrom: cogit methodZoneBase to: cogit methodZone effectiveLimit.

	"Prepare the methods to put in PICs"	
	receiver := memory nilObject.
	selector := self newOldSpaceObjectWithSlots: 0.
	numArgs := 0.

	receiverTag := memory classIndexOf: receiver.
	picTypeTags := Dictionary new.
	compiledMethods := Dictionary new.
	cogMethods := Dictionary new.
	"Configure by default some type tags.
	None of them should match by costruction the tag of the receiver.
	Specific tests should override this to force a PIC HIT"
	1 to: 6 "Maximum polymorphic  cases" do: [ :index | | cogMethod compiledMethod |
		picTypeTags at: index - 1 put: receiverTag + index.

		compiledMethod := self newMethodWithLiteral: selector at: 0.
		cogMethod := self generateCogMethod: [ cogit RetN: 0 ] selector: selector.
		cogit coInterpreter rawHeaderOf: compiledMethod put: cogMethod asInteger.
		
		compiledMethods at: index - 1 put: compiledMethod.
		cogMethods at: index - 1 put: cogMethod.
	]
]

{ #category : #'tests - metadata' }
VMSimpleStackBasedCogitPolymorphicPICTest >> testHasConfiguredCases [
	| pic |	

	pic := self makePolymorphicPIC.

	self assert: pic cPICNumCases equals: self configuredPicCases
]

{ #category : #'tests - metadata' }
VMSimpleStackBasedCogitPolymorphicPICTest >> testHasJumpToAbortTrampoline [
	| pic |	
	pic := self makePolymorphicPIC.

	self assert: (cogit backend callTargetFromReturnAddress: pic asInteger + cogit missOffset) equals: (cogit picAbortTrampolineFor: numArgs)
]

{ #category : #'tests - hit/miss' }
VMSimpleStackBasedCogitPolymorphicPICTest >> testHitCase0 [

	self assertHitAtCase: 0
]

{ #category : #'tests - hit/miss' }
VMSimpleStackBasedCogitPolymorphicPICTest >> testHitCase1 [

	self assertHitAtCase: 1
]

{ #category : #'tests - hit/miss' }
VMSimpleStackBasedCogitPolymorphicPICTest >> testHitCase2 [

	self assertHitAtCase: 2
]

{ #category : #'tests - hit/miss' }
VMSimpleStackBasedCogitPolymorphicPICTest >> testHitCase3 [

	self assertHitAtCase: 3
]

{ #category : #'tests - hit/miss' }
VMSimpleStackBasedCogitPolymorphicPICTest >> testHitCase4 [

	self assertHitAtCase: 4
]

{ #category : #'tests - hit/miss' }
VMSimpleStackBasedCogitPolymorphicPICTest >> testHitCase5 [
	"This is the last case. Cog PICs have 6 cases (0-based)"
	self assertHitAtCase: 5
]

{ #category : #'tests - metadata' }
VMSimpleStackBasedCogitPolymorphicPICTest >> testIsClosedPic [
	| pic |	
	pic := self makePolymorphicPIC.

	self assert: pic cmType equals: CMClosedPIC. 
]

{ #category : #'tests - hit/miss' }
VMSimpleStackBasedCogitPolymorphicPICTest >> testMiss [

	| pic |	

	pic := self makePolymorphicPIC.

	self assertPICMiss: pic
]

{ #category : #'tests - metadata' }
VMSimpleStackBasedCogitPolymorphicPICTest >> testNumberOfArgumentsInHeader [
	| pic |
	
	pic := self makePolymorphicPIC.

	self assert: pic cmNumArgs equals: numArgs
]

{ #category : #'tests - hit/miss' }
VMSimpleStackBasedCogitPolymorphicPICTest >> testPolymorphicPICHitDoesNotCallEntryOffset [

	| pic methodCheckEntryPoint methodNoCheckEntryPoint passedByCheckEntryPoint |	
	picTypeTags at: 0 put: receiverTag.
	
	pic := self makePolymorphicPIC.

	"Receiver is nil, class tag of the first entry is the receiver's class tag.
	 - the receiver matches class tag for case 0
	 - the receiver does not match with the class tag for case 1
	 - so it should call method for case 0"
	machineSimulator receiverRegisterValue: receiver.
	machineSimulator classRegisterValue: (picTypeTags at: 0).

	"Should call method of case 0 just after the type check (to avoid it).
	The check was already done in the PIC.
	We execute from the PIC expecting to arrive to the no entry offset of the cog method, checking we never pass through the check entry"
	methodCheckEntryPoint := (cogMethods at: 0) address + cogit entryOffset.
	methodNoCheckEntryPoint := (cogMethods at: 0) address + cogit noCheckEntryOffset.
	passedByCheckEntryPoint := false.
	machineSimulator 
		registerHook: [ passedByCheckEntryPoint := true ] 
		atAddress: methodCheckEntryPoint.
	self
		runFrom: pic address + cogit entryOffset
		until: methodNoCheckEntryPoint.

	self deny: passedByCheckEntryPoint
]

{ #category : #'tests - metadata' }
VMSimpleStackBasedCogitPolymorphicPICTest >> testSelectorInHeader [
	| pic |	

	pic := self makePolymorphicPIC.

	self assert: pic selector equals: selector
]
