Class {
	#name : #VMSimpleStackBasedCogitPolimorphicPICTest,
	#superclass : #VMSimpleStackBasedCogitMonomorphicPICTest,
	#instVars : [
		'selector',
		'compiledMethod0',
		'cogMethod0',
		'compiledMethod1',
		'cogMethod1'
	],
	#category : #VMMakerTests
}

{ #category : #'tests - PIC' }
VMSimpleStackBasedCogitPolimorphicPICTest >> assertPIC: pic hits: hitMethod withReceiver: receiver andCallSiteTag: theCallsiteTag [
	"Receiver is nil, class tag of the first entry is the receiver's class tag.
	 - the receiver matches class tag for case 0
	 - the receiver does not match with the class tag for case 1
	 - so it should call method for case 0"
	unicorn receiverRegisterValue: receiver.
	unicorn classRegisterValue: theCallsiteTag.

	"Should call method 1 just after the type check (to avoid it).
	The check was already done in the PIC"
	self runFrom: pic address + cogit entryOffset until: hitMethod address + cogit noCheckEntryOffset.

	"When a PIC Hits
	 - The instruction pointer is at no check entry offset of the hitted method
	 - The class register value case 0 tag regardless of the hit
	 - the receiver register value contains the receiver"
	self assert: unicorn instructionPointerValue equals: hitMethod address + cogit noCheckEntryOffset.
	self assert: unicorn classRegisterValue equals: theCallsiteTag.
	self assert: unicorn receiverRegisterValue equals: receiver
]

{ #category : #'tests - PIC' }
VMSimpleStackBasedCogitPolimorphicPICTest >> assertPICMiss: pic withReceiver: receiver andCallSiteTag: theCallsiteTag [

	"Receiver is nil, class tag of the first entry is 1 (a small integer).
	 - the receiver does not match with the class tag for case 0
	 - the receiver does not match with the class tag for case 1
	 - so it should call the closed pic miss trampoline"
	unicorn receiverRegisterValue: receiver.
	unicorn classRegisterValue: theCallsiteTag.

	self runFrom: pic address + cogit entryOffset until: cogit ceCPICMissTrampoline.

	"Failing all two PIC cases calls the pic trampoline.
	 - The instruction pointer is at the trampoline
	 - The class register value contains the pic
	 - the receiver register value contains the receiver"	
	self assert: unicorn instructionPointerValue equals: cogit ceCPICMissTrampoline.
	self assert: unicorn classRegisterValue equals: pic address.
	self assert: unicorn receiverRegisterValue equals: receiver
]

{ #category : #'tests - PIC' }
VMSimpleStackBasedCogitPolimorphicPICTest >> makePolymorphicPICWithCase0CogMethod: aCase0CogMethod case1CompiledMethod: aCase1CompiledMEthod case1MethodTag: cogMethod1Tag [
	
	^ cogit cogPICSelector: selector
		numArgs: 0
		Case0Method: aCase0CogMethod
		Case1Method: aCase1CompiledMEthod
		tag: cogMethod1Tag
		isMNUCase: false
]

{ #category : #'tests - PIC' }
VMSimpleStackBasedCogitPolimorphicPICTest >> setUp [

	super setUp.
	self setUpCogMethodEntry.
	cogit generateClosedPICPrototype. 

	cogit methodZone manageFrom: cogit methodZoneBase to: cogit methodZone effectiveLimit.

	"Prepare the methods to put in PICs"	
	selector := self newOldSpaceObjectWithSlots: 0.

	compiledMethod0 := self newMethodWithLiteral: selector at: 0.
	cogMethod0 := self generateCogMethod: [ cogit RetN: 0 ] selector: selector.
	cogit coInterpreter rawHeaderOf: compiledMethod0 put: cogMethod0 asInteger.
	
	compiledMethod1 := self newMethodWithLiteral: selector at: 0.
	cogMethod1 := self generateCogMethod: [ cogit RetN: 0 ] selector: selector.
	cogit coInterpreter rawHeaderOf: compiledMethod1 put: cogMethod1 asInteger.
]

{ #category : #'tests - PIC' }
VMSimpleStackBasedCogitPolimorphicPICTest >> testNewPolymorphicPICWithTwoCoggedMethodsCallsCase0OnHit [

	| cogMethod1Tag pic cogMethod0Tag receiver |	

	receiver := memory nilObject.
	cogMethod0Tag := memory classIndexOf: receiver.
	cogMethod1Tag := 2.
	
	pic := self
		makePolymorphicPICWithCase0CogMethod: cogMethod0
		case1CompiledMethod: compiledMethod1
		case1MethodTag: cogMethod1Tag.

	"Some preconditions.
	To hit case 0, the method tag of case 0 should be the receivers method tag too.
	The other case should not match the tag"
	self assert: (memory classIndexOf: receiver) equals: cogMethod0Tag.
	self deny: (memory classIndexOf: receiver) equals: cogMethod1Tag.

	self assertPIC: pic hits: cogMethod0 withReceiver: receiver andCallSiteTag: cogMethod0Tag.

]

{ #category : #'tests - PIC' }
VMSimpleStackBasedCogitPolimorphicPICTest >> testNewPolymorphicPICWithTwoCoggedMethodsCallsCase1OnHit [

	| cogMethod1Tag pic cogMethod0Tag receiver |	

	receiver := memory nilObject.
	cogMethod0Tag := 2.
	cogMethod1Tag := memory classIndexOf: receiver.

	pic := self
		makePolymorphicPICWithCase0CogMethod: cogMethod0
		case1CompiledMethod: compiledMethod1
		case1MethodTag: cogMethod1Tag.

	"Some preconditions.
	To hit case 1, the method tag of case 1 should be the receivers method tag too.
	The other case should not match the tag"
	self assert: (memory classIndexOf: receiver) equals: cogMethod1Tag.
	self deny: (memory classIndexOf: receiver) equals: cogMethod0Tag.

	self assertPIC: pic hits: cogMethod1 withReceiver: receiver andCallSiteTag: cogMethod0Tag.

]

{ #category : #'tests - PIC' }
VMSimpleStackBasedCogitPolimorphicPICTest >> testNewPolymorphicPICWithTwoCoggedMethodsCallsMissTrampolineOnMiss [

	| cogMethod1Tag pic cogMethod0Tag receiver |	

	cogMethod0Tag := 1.
	cogMethod1Tag := 2.
	receiver := memory nilObject.

	pic := self
		makePolymorphicPICWithCase0CogMethod: cogMethod0
		case1CompiledMethod: compiledMethod1
		case1MethodTag: cogMethod1Tag.

	"Some preconditions.
	To miss the PIC, the receivers method tag should not match any tag"
	self deny: (memory classIndexOf: receiver) equals: cogMethod1Tag.
	self deny: (memory classIndexOf: receiver) equals: cogMethod0Tag.

	self assertPICMiss: pic withReceiver: receiver andCallSiteTag: cogMethod0Tag
]

{ #category : #'tests - PIC' }
VMSimpleStackBasedCogitPolimorphicPICTest >> testPolymorphicPICHitDoesNotCallEntryOffset [

	| cogMethod1Tag pic cogMethod0Tag receiver methodCheckEntryPoint |	
	receiver := memory nilObject.
	cogMethod0Tag := (memory classIndexOf: receiver).
	cogMethod1Tag := 2.

	pic := self
		makePolymorphicPICWithCase0CogMethod: cogMethod0
		case1CompiledMethod: compiledMethod1
		case1MethodTag: cogMethod1Tag.

	"Receiver is nil, class tag of the first entry is the receiver's class tag.
	 - the receiver matches class tag for case 0
	 - the receiver does not match with the class tag for case 1
	 - so it should call method for case 0"
	unicorn receiverRegisterValue: receiver.
	self assert: (memory classIndexOf: receiver) equals: cogMethod0Tag.
	self deny: (memory classIndexOf: receiver) equals: cogMethod1Tag.
	unicorn classRegisterValue: cogMethod0Tag.

	"Should call method 1 just after the type check (to avoid it).
	The check was already done in the PIC.
	We execute from the PIC expecting to arrive to the entry offset of the cog method.
	Since we should never arrive there, this execution should timeout"
	[  methodCheckEntryPoint := cogMethod0 address + cogit entryOffset. 
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
