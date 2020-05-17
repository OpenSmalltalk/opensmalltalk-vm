Class {
	#name : #VMSimpleStackBasedCogitPolimorphicPICTest,
	#superclass : #VMSimpleStackBasedCogitMonomorphicPICTest,
	#instVars : [
		'selector',
		'numArgs',
		'receiver',
		'receiverTag',
		'picTypeTags',
		'cogMethods',
		'compiledMethods'
	],
	#category : #VMMakerTests
}

{ #category : #helpers }
VMSimpleStackBasedCogitPolimorphicPICTest >> assertPIC: pic hits: hitMethod [
	"Receiver is nil, class tag of the first entry is the receiver's class tag.
	 - the receiver matches class tag for case 0
	 - the receiver does not match with the class tag for case 1
	 - so it should call method for case 0"
	unicorn receiverRegisterValue: receiver.
	unicorn classRegisterValue: (picTypeTags at: 0).

	"Should call method 1 just after the type check (to avoid it).
	The check was already done in the PIC"
	self runFrom: pic address + cogit entryOffset until: hitMethod address + cogit noCheckEntryOffset.

	"When a PIC Hits
	 - The instruction pointer is at no check entry offset of the hitted method
	 - The class register value case 0 tag regardless of the hit
	 - the receiver register value contains the receiver"
	self assert: unicorn instructionPointerValue equals: hitMethod address + cogit noCheckEntryOffset.
	self assert: unicorn classRegisterValue equals: (picTypeTags at: 0).
	self assert: unicorn receiverRegisterValue equals: receiver
]

{ #category : #helpers }
VMSimpleStackBasedCogitPolimorphicPICTest >> assertPICMiss: pic [

	"Receiver is nil, class tag of the first entry is 1 (a small integer).
	 - the receiver does not match with the class tag for case 0
	 - the receiver does not match with the class tag for case 1
	 - so it should call the closed pic miss trampoline"
	unicorn receiverRegisterValue: receiver.
	unicorn classRegisterValue: (picTypeTags at: 0).

	self runFrom: pic address + cogit entryOffset until: cogit ceCPICMissTrampoline.

	"Failing all two PIC cases calls the pic trampoline.
	 - The instruction pointer is at the trampoline
	 - The class register value contains the pic
	 - the receiver register value contains the receiver"	
	self assert: unicorn instructionPointerValue equals: cogit ceCPICMissTrampoline.
	self assert: unicorn classRegisterValue equals: pic address.
	self assert: unicorn receiverRegisterValue equals: receiver
]

{ #category : #helpers }
VMSimpleStackBasedCogitPolimorphicPICTest >> extendPIC: aPic [

	cogit
		cogExtendPIC: aPic
		CaseNMethod: (compiledMethods at: aPic cPICNumCases)
		tag: (picTypeTags at: aPic cPICNumCases)
		isMNUCase: false.
]

{ #category : #helpers }
VMSimpleStackBasedCogitPolimorphicPICTest >> makePolymorphicPIC [

	^ cogit cogPICSelector: selector
		numArgs: numArgs
		Case0Method: (cogMethods at: 0)
		Case1Method: (compiledMethods at: 1)
		tag: (picTypeTags at: 1)
		isMNUCase: false
]

{ #category : #helpers }
VMSimpleStackBasedCogitPolimorphicPICTest >> makePolymorphicPICWithCase0CogMethod: aCase0CogMethod [

	^ cogit cogPICSelector: selector
		numArgs: numArgs
		Case0Method: (cogMethods at: 0)
		Case1Method: (compiledMethods at: 1)
		tag: (picTypeTags at: 1)
		isMNUCase: false
]

{ #category : #running }
VMSimpleStackBasedCogitPolimorphicPICTest >> setUp [

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

{ #category : #'tests - extension' }
VMSimpleStackBasedCogitPolimorphicPICTest >> testExtendTwoCasePicWithCoggedMethodHasThreeCases [

	| pic |
	pic := self makePolymorphicPIC.
	
	self extendPIC: pic.

	self assert: pic cPICNumCases equals: 3
]

{ #category : #'tests - new polymorphic PICs' }
VMSimpleStackBasedCogitPolimorphicPICTest >> testNewPolymorphicPICWithTwoCoggedMethodsCallsCase0OnHit [

	| pic |	
	picTypeTags at: 0 put: receiverTag.
	
	pic := self makePolymorphicPIC.

	self assertPIC: pic hits: (cogMethods at: 0)
]

{ #category : #'tests - new polymorphic PICs' }
VMSimpleStackBasedCogitPolimorphicPICTest >> testNewPolymorphicPICWithTwoCoggedMethodsCallsCase1OnHit [

	| pic |	
	picTypeTags at: 1 put: receiverTag.

	pic := self makePolymorphicPIC.

	self assertPIC: pic hits: (cogMethods at: 1)
]

{ #category : #'tests - new polymorphic PICs' }
VMSimpleStackBasedCogitPolimorphicPICTest >> testNewPolymorphicPICWithTwoCoggedMethodsCallsMissTrampolineOnMiss [

	| pic |	

	pic := self makePolymorphicPIC.

	self assertPICMiss: pic
]

{ #category : #'tests - metadata' }
VMSimpleStackBasedCogitPolimorphicPICTest >> testNewPolymorphicPICWithTwoCoggedMethodsHasGivenNumberOfArguments [
	| pic |
	
	pic := self makePolymorphicPIC.

	self assert: pic cmNumArgs equals: numArgs
]

{ #category : #'tests - metadata' }
VMSimpleStackBasedCogitPolimorphicPICTest >> testNewPolymorphicPICWithTwoCoggedMethodsHasGivenSelector [
	| pic |	

	pic := self makePolymorphicPIC.

	self assert: pic selector equals: selector
]

{ #category : #'tests - metadata' }
VMSimpleStackBasedCogitPolimorphicPICTest >> testNewPolymorphicPICWithTwoCoggedMethodsHasJumpToAbortTrampoline [
	| pic |	
	pic := self makePolymorphicPIC.

	self assert: (cogit backend callTargetFromReturnAddress: pic asInteger + cogit missOffset) equals: (cogit picAbortTrampolineFor: numArgs)
]

{ #category : #'tests - metadata' }
VMSimpleStackBasedCogitPolimorphicPICTest >> testNewPolymorphicPICWithTwoCoggedMethodsHasTwoCases [
	| pic |	

	pic := self makePolymorphicPIC.

	self assert: pic cPICNumCases equals: 2
]

{ #category : #'tests - metadata' }
VMSimpleStackBasedCogitPolimorphicPICTest >> testNewPolymorphicPICWithTwoCoggedMethodsIsClosedPic [
	| pic |	
	pic := self makePolymorphicPIC.

	self assert: pic cmType equals: 4"CMClosedPIC".
]

{ #category : #'tests - new polymorphic PICs' }
VMSimpleStackBasedCogitPolimorphicPICTest >> testPolymorphicPICHitDoesNotCallEntryOffset [

	| pic methodCheckEntryPoint |	
	picTypeTags at: 0 put: receiverTag.
	
	pic := self makePolymorphicPIC.

	"Receiver is nil, class tag of the first entry is the receiver's class tag.
	 - the receiver matches class tag for case 0
	 - the receiver does not match with the class tag for case 1
	 - so it should call method for case 0"
	unicorn receiverRegisterValue: receiver.
	unicorn classRegisterValue: (picTypeTags at: 0).

	"Should call method 1 just after the type check (to avoid it).
	The check was already done in the PIC.
	We execute from the PIC expecting to arrive to the entry offset of the cog method.
	Since we should never arrive there, this execution should timeout"
	[  methodCheckEntryPoint := (cogMethods at: 0) address + cogit entryOffset. 
		self
			runFrom: pic address + cogit entryOffset
			until: methodCheckEntryPoint
			timeout: 100.
			"fail if it does not timeout"
			self fail ]
			on: UnicornTimeout
			do: [ :e | 
				"Let's assert that at this point the execution went above that instruction pointer"
				self assert: unicorn instructionPointerValue > methodCheckEntryPoint ].
]
