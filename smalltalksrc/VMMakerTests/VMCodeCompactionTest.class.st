Class {
	#name : #VMCodeCompactionTest,
	#superclass : #VMPrimitiveCallAbstractTest,
	#pools : [
		'CogRTLOpcodes'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #tests }
VMCodeCompactionTest >> fillCodeZone [

	| aMethod |

	[aMethod := self jitMethod: (self findMethod: #methodToCompile1).
	aMethod notNil and: [ | headerSize methodSize |
		headerSize := cogit sizeof: CogMethod.
		methodSize := headerSize + aMethod blockSize.
		(cogit methodZone methodAfter: aMethod) asInteger + methodSize
			< cogit methodZone effectiveLimit ] ] whileTrue.


]

{ #category : #tests }
VMCodeCompactionTest >> testCompactDuringInterpreterPrimitiveThatMovesCurrentMethodShouldNotCrash [

	| firstMethod compactMethod |
	
	<expectedFailure>

	"Patching the primitive to execute the method I need to force the code compaction"
	interpreter primitiveTable at: 1 + 1 put: #primitiveForceMachineCodeCompaction.

	cogit sendTrace: 0.
	
	firstMethod := self jitMethod: (self findMethod: #methodToCompile1).
	compactMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:).
	
	self fillCodeZone.

	firstMethod cmUsageCount: 0.

	self createBaseFrame.
	
	"Initialize Stack to the correct pointers in the selected page"
	machineSimulator stackPointerRegisterValue: interpreter stackPointer.
	machineSimulator framePointerRegisterValue: interpreter framePointer.
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	
	cogit setCStackPointer: interpreter rumpCStackAddress.
	cogit setCFramePointer: interpreter rumpCStackAddress.
	
	self pushAddress: memory nilObject.
	self pushAddress: memory falseObject.

	self prepareCall.
	machineSimulator instructionPointerValue: compactMethod address + cogit noCheckEntryOffset. 
	
	self runFrom: compactMethod address + cogit noCheckEntryOffset until: callerAddress.

	self assert: machineSimulator receiverRegisterValue equals: memory trueObject.
	

]

{ #category : #tests }
VMCodeCompactionTest >> testCompactingAnUnusedMethodCompactsRemainingMethodToTheBeginning [

	| firstMethod compactMethod methodOop |
	firstMethod := self jitMethod: (self findMethod: #methodToCompile1) selector: memory trueObject.
	compactMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:) selector: memory falseObject.

	self fillCodeZone.

	methodOop := compactMethod methodObject.
	firstMethod cmUsageCount: 0.
	compactMethod cmUsageCount: 5.

	self createBaseFrame.

	self assert: (interpreter cogMethodOf: methodOop) equals: compactMethod address.

	interpreter commenceCogCompiledCodeCompaction.

	self assert: (interpreter cogMethodOf: methodOop) equals: firstMethod address

]

{ #category : #tests }
VMCodeCompactionTest >> testCompactingShouldRelocateInSendsLiterals [

	| firstMethod cogMethod methodOop |
	"Create a method that will be collected and force compaction of all the next ones"
	firstMethod := self jitMethod: (self findMethod: #methodToCompile1) selector: memory trueObject.
	firstMethod cmUsageCount: 0.
	
	"Method that will be linked to"
	cogMethod := self jitMethod: (self findMethod: #methodSendingNilArgument) selector: memory falseObject.
	cogMethod cmUsageCount: 4.
	methodOop := cogMethod methodObject.

	"Fill the code zone with more methods to force compaction"
	self fillCodeZone.

	"Launch code compaction"		
	self createBaseFrame.
	interpreter commenceCogCompiledCodeCompaction.
	
	"After compaction the send should arrive to the callee entry offset"
	self createFramefulCallFrom: callerAddress.
	self prepareStackForSendReceiver: memory falseObject.

	self
		runFrom: (interpreter cogMethodOf: methodOop) address + cogit noCheckEntryOffset
		until: send1TrampolineAddress.

	interpreter stackPointer: machineSimulator smalltalkStackPointerRegisterValue.
	"If in CISC, the call to the trampoline has pushed the caller's IP so we need to skip one in the stack"
	self
		assert: (interpreter stackValue: (cogit backEnd hasLinkRegister ifTrue: [0] ifFalse: [1]))
		equals: memory nilObject
]

{ #category : #tests }
VMCodeCompactionTest >> testCompactingShouldRelocateLiterals [

	| firstMethod cogMethod methodOop |
	"Create a method that will be collected and force compaction of all the next ones"
	firstMethod := self jitMethod: (self findMethod: #methodToCompile1) selector: memory trueObject.
	firstMethod cmUsageCount: 0.
	
	"Method that will be linked to"
	cogMethod := self jitMethod: (self findMethod: #methodReturningNil) selector: memory falseObject.
	cogMethod cmUsageCount: 4.
	methodOop := cogMethod methodObject.

	"Fill the code zone with more methods to force compaction"
	self fillCodeZone.

	"Launch code compaction"		
	self createBaseFrame.
	interpreter commenceCogCompiledCodeCompaction.
	
	"After compaction the send should arrive to the callee entry offset"
	self createFramefulCallFrom: callerAddress.
	self prepareStackForSendReceiver: memory falseObject.
	
	self
		runFrom: (interpreter cogMethodOf: methodOop) address + cogit noCheckEntryOffset
		until: callerAddress.

	self
		assert: machineSimulator receiverRegisterValue
		equals: memory nilObject
]

{ #category : #tests }
VMCodeCompactionTest >> testCompactingShouldRelocateMethodReference [

	| firstMethod cogMethod methodOop |
	"Create a method that will be collected and force compaction of all the next ones"
	firstMethod := self jitMethod: (self findMethod: #methodToCompile1) selector: memory trueObject.
	firstMethod cmUsageCount: 0.
	
	cogMethod := self jitMethod: (self findMethod: #methodWithSend) selector: memory falseObject.
	cogMethod cmUsageCount: 4.
	methodOop := cogMethod methodObject.

	"Fill the code zone with more methods to force compaction"
	self fillCodeZone.
	
	"Compact"
	self createBaseFrame.
	interpreter commenceCogCompiledCodeCompaction.
	
	"After compaction the send should arrive to the trampoline and should have created a frame with the right method"
	self createFramefulCallFrom: callerAddress.
	self pushAddress: memory falseObject.

	self
		runFrom: (interpreter cogMethodOf: methodOop) address + cogit noCheckEntryOffset
		until: sendTrampolineAddress.

	"Assert that activating the method should have pushed the right method to the stack"
	self
		assert: (interpreter mframeHomeMethod: (machineSimulator framePointerRegisterValue))
		equals: (interpreter cogMethodOf: methodOop)
]

{ #category : #tests }
VMCodeCompactionTest >> testCompactingShouldRelocateMonomorphicCallsite [

	| firstMethod callerMethodOop calleeCogMethod selector callerCogMethod calleeMethodOop |
	"Create a method that will be collected and force compaction of all the next ones"
	firstMethod := self jitMethod: (self findMethod: #methodToCompile1) selector: memory trueObject.
	firstMethod cmUsageCount: 0.
	
	"Method that will be linked to"
	calleeCogMethod := self jitMethod: (self findMethod: #methodThatCallPrimitive1:) selector: memory falseObject.
	calleeCogMethod cmUsageCount: 4.
	calleeMethodOop := calleeCogMethod methodObject.

	selector := memory falseObject.
	callerCogMethod := self jitMethod: (self findMethod: #methodWithSend) selector: selector.
	callerCogMethod cmUsageCount: 4.
	callerMethodOop := callerCogMethod methodObject.

	"Fill the code zone with more methods to force compaction"
	self fillCodeZone.
	
	"Setup the frame to do the patch"
	"Push receiver then send, to finally stop at the trampoline and patch the call-site"
	self createFramefulCallFrom: callerAddress.
	self pushAddress: memory falseObject.
	self runFrom: callerCogMethod address + cogit noCheckEntryOffset until: sendTrampolineAddress.

	cogit 
		linkSendAt: machineSimulator getReturnAddress 
		in: callerMethodOop 
		to: calleeCogMethod
		offset: cogit entryOffset 
		receiver: memory falseObject.
		
	self createBaseFrame.
	interpreter commenceCogCompiledCodeCompaction.
	
	"After compaction the send should arrive to the callee entry offset"
	self createFramefulCallFrom: callerAddress.
	self pushAddress: memory falseObject.

	self
		runFrom: (interpreter cogMethodOf: callerMethodOop) address + cogit noCheckEntryOffset
		until: (interpreter cogMethodOf: calleeMethodOop) asInteger + cogit entryOffset.

	self
		assert: machineSimulator instructionPointerValue
		equals: (interpreter cogMethodOf: calleeMethodOop) asInteger + cogit entryOffset
]

{ #category : #tests }
VMCodeCompactionTest >> testCompactingShouldRelocatePolymorphicPICCallsite [

	"This method sets up a method A that is linked to a polymorphic PIC linked to B and C.
	Code compaction is launched so both A, B, C and the PIC are moved and remapped.
	Re-sending a message should still work and arrive to all cases of the PIC after remap."

	| firstMethod callerMethodOop calleeCogMethod selector callerCogMethod calleeMethodOop calleeCogMethod2 calleeMethodOop2 pic |
	"Create a method that will be collected and force compaction of all the next ones"
	firstMethod := self jitMethod: (self findMethod: #methodToCompile1) selector: memory trueObject.
	firstMethod cmUsageCount: 0.
	
	"Caller that will be linked to the PIC"
	selector := memory falseObject.
	callerCogMethod := self jitMethod: (self findMethod: #methodWithSend:) selector: selector.
	callerCogMethod cmUsageCount: 4.
	callerMethodOop := callerCogMethod methodObject.
	
	"Methods that will be linked to"
	calleeCogMethod := self jitMethod: (self findMethod: #methodWithSend) selector: selector.
	calleeCogMethod cmUsageCount: 4.
	calleeMethodOop := calleeCogMethod methodObject.
	
	calleeCogMethod2 := self jitMethod: (self findMethod: #methodWithSend) selector: selector.
	calleeCogMethod2 cmUsageCount: 4.
	calleeMethodOop2 := calleeCogMethod2 methodObject.
	
	"Setup the frame to do the patch"
	"Push receiver then send, to finally stop at the trampoline and patch the call-site"
	self createFramefulCallFrom: callerAddress.
	self prepareStackForSendReceiver: memory falseObject arguments: { memory falseObject }.
	self runFrom: callerCogMethod address + cogit noCheckEntryOffset until: sendTrampolineAddress.

	"First monomorphic link"
	cogit 
		linkSendAt: machineSimulator getReturnAddress
		in: callerMethodOop 
		to: calleeCogMethod
		offset: cogit entryOffset 
		receiver: memory falseObject.

	"Then create the PIC and link it"
	pic := cogit cogPICSelector: selector
		numArgs: 1
		Case0Method: calleeCogMethod
		Case1Method: calleeMethodOop2
		tag: (cogit objectRepresentation inlineCacheTagForInstance: (memory integerObjectOf: 7))
		isMNUCase: false.
	pic cmUsageCount: 4.
	cogit backEnd
		rewriteCallAt: machineSimulator getReturnAddress
		target: pic asInteger + cogit entryOffset.
		
	"Fill the code zone with more methods to force compaction"
	self fillCodeZone.
		
	self createBaseFrame.
	interpreter commenceCogCompiledCodeCompaction.
	
	"After compaction the send should arrive to the callee entry offset"
	
	"Check case 1"
	self createFramefulCallFrom: callerAddress.
	self prepareStackForSendReceiver: memory falseObject arguments: { memory falseObject }.
	self
		runFrom: (interpreter cogMethodOf: callerMethodOop) address + cogit noCheckEntryOffset
		until: (interpreter cogMethodOf: calleeMethodOop) asInteger + cogit noCheckEntryOffset.

	self
		assert: machineSimulator instructionPointerValue
		equals: (interpreter cogMethodOf: calleeMethodOop) asInteger + cogit noCheckEntryOffset.
	
	"Check case 2"
	self createFramefulCallFrom: callerAddress.
	self prepareStackForSendReceiver: memory falseObject arguments: { memory integerObjectOf: 7 }.
	self
		runFrom: (interpreter cogMethodOf: callerMethodOop) address + cogit noCheckEntryOffset
		until: (interpreter cogMethodOf: calleeMethodOop2) asInteger + cogit noCheckEntryOffset.

	self
		assert: machineSimulator instructionPointerValue
		equals: (interpreter cogMethodOf: calleeMethodOop2) asInteger + cogit noCheckEntryOffset.
	
	"Check PIC MISS trampoline"
	self createFramefulCallFrom: callerAddress.
	self prepareStackForSendReceiver: memory falseObject arguments: { memory characterObjectOf: 7 }.
	self
		runFrom: (interpreter cogMethodOf: callerMethodOop) address + cogit noCheckEntryOffset
		until: cogit ceCPICMissTrampoline.

	self
		assert: machineSimulator instructionPointerValue
		equals: cogit ceCPICMissTrampoline
]

{ #category : #tests }
VMCodeCompactionTest >> testCompactingShouldRelocatePolymorphicPICInterpreterAbortCallsite [

	"This method sets up a method A that is linked to a polymorphic PIC linked to B and C.
	Code compaction is launched so both A, B, C and the PIC are moved and remapped.
	Re-sending a message should still work and arrive to all cases of the PIC after remap."

	| firstMethod callerMethodOop calleeCogMethod selector callerCogMethod calleeMethodOop calleeCogMethod2 calleeMethodOop2 pic |
	"Create a method that will be collected and force compaction of all the next ones"
	firstMethod := self jitMethod: (self findMethod: #methodToCompile1) selector: memory trueObject.
	firstMethod cmUsageCount: 0.
	
	"Caller that will be linked to the PIC"
	selector := memory falseObject.
	callerCogMethod := self jitMethod: (self findMethod: #methodWithSend:) selector: selector.
	callerCogMethod cmUsageCount: 4.
	callerMethodOop := callerCogMethod methodObject.
	
	"Methods that will be linked to"
	calleeCogMethod := self jitMethod: (self findMethod: #methodWithSend) selector: selector.
	calleeCogMethod cmUsageCount: 4.
	calleeMethodOop := calleeCogMethod methodObject.
	
	calleeMethodOop2 := methodBuilder fillFromPharoMethod: (self findMethod: #methodWithSend); buildMethod.
	
	"Setup the frame to do the patch"
	"Push receiver then send, to finally stop at the trampoline and patch the call-site"
	self createFramefulCallFrom: callerAddress.
	self prepareStackForSendReceiver: memory falseObject arguments: { memory falseObject }.
	self runFrom: callerCogMethod address + cogit noCheckEntryOffset until: sendTrampolineAddress.

	"First monomorphic link"
	cogit 
		linkSendAt: machineSimulator getReturnAddress
		in: callerMethodOop 
		to: calleeCogMethod
		offset: cogit entryOffset 
		receiver: memory falseObject.

	"Then create the PIC and link it"
	interpreter setBreakSelectorLength: memory minSmallInteger.
	pic := cogit cogPICSelector: selector
		numArgs: 1
		Case0Method: calleeCogMethod
		Case1Method: calleeMethodOop2
		tag: (cogit objectRepresentation inlineCacheTagForInstance: (memory integerObjectOf: 7))
		isMNUCase: false.
	pic cmUsageCount: 4.
	cogit backEnd
		rewriteCallAt: machineSimulator getReturnAddress
		target: pic asInteger + cogit entryOffset.
		
	"Fill the code zone with more methods to force compaction"
	self fillCodeZone.
		
	self createBaseFrame.
	interpreter commenceCogCompiledCodeCompaction.
	
	"After compaction the send should arrive to the callee entry offset"
	
	"Check case 2"
	self createFramefulCallFrom: callerAddress.
	self prepareStackForSendReceiver: memory falseObject arguments: { memory integerObjectOf: 7 }.
	self
		runFrom: (interpreter cogMethodOf: callerMethodOop) address + cogit noCheckEntryOffset
		until: cogit cePICAbortTrampoline.

	self
		assert: machineSimulator instructionPointerValue
		equals: cogit cePICAbortTrampoline
]

{ #category : #tests }
VMCodeCompactionTest >> testCompactingShouldRelocatePolymorphicPICMNUAbortCallsite [

	"This method sets up a method A that is linked to a polymorphic PIC linked to B and C.
	Code compaction is launched so both A, B, C and the PIC are moved and remapped.
	Re-sending a message should still work and arrive to all cases of the PIC after remap."

	| firstMethod callerMethodOop calleeCogMethod selector callerCogMethod calleeMethodOop calleeCogMethod2 calleeMethodOop2 pic |
	"Create a method that will be collected and force compaction of all the next ones"
	firstMethod := self jitMethod: (self findMethod: #methodToCompile1) selector: memory trueObject.
	firstMethod cmUsageCount: 0.
	
	"Caller that will be linked to the PIC"
	selector := memory falseObject.
	callerCogMethod := self jitMethod: (self findMethod: #methodWithSend:) selector: selector.
	callerCogMethod cmUsageCount: 4.
	callerMethodOop := callerCogMethod methodObject.
	
	"Methods that will be linked to"
	calleeCogMethod := self jitMethod: (self findMethod: #methodWithSend) selector: selector.
	calleeCogMethod cmUsageCount: 4.
	calleeMethodOop := calleeCogMethod methodObject.
	
	calleeCogMethod2 := self jitMethod: (self findMethod: #methodWithSend) selector: selector.
	calleeCogMethod2 cmUsageCount: 4.
	calleeMethodOop2 := calleeCogMethod2 methodObject.
	
	"Setup the frame to do the patch"
	"Push receiver then send, to finally stop at the trampoline and patch the call-site"
	self createFramefulCallFrom: callerAddress.
	self prepareStackForSendReceiver: memory falseObject arguments: { memory falseObject }.
	self runFrom: callerCogMethod address + cogit noCheckEntryOffset until: sendTrampolineAddress.

	"First monomorphic link"
	cogit 
		linkSendAt: machineSimulator getReturnAddress
		in: callerMethodOop 
		to: calleeCogMethod
		offset: cogit entryOffset 
		receiver: memory falseObject.

	"Then create the PIC and link it"
	interpreter setBreakSelectorLength: memory minSmallInteger.
	pic := cogit cogPICSelector: selector
		numArgs: 1
		Case0Method: calleeCogMethod
		Case1Method: calleeMethodOop2
		tag: (cogit objectRepresentation inlineCacheTagForInstance: (memory integerObjectOf: 7))
		isMNUCase: true.
	pic cmUsageCount: 4.
	cogit backEnd
		rewriteCallAt: machineSimulator getReturnAddress
		target: pic asInteger + cogit entryOffset.
		
	"Fill the code zone with more methods to force compaction"
	self fillCodeZone.
		
	self createBaseFrame.
	interpreter commenceCogCompiledCodeCompaction.
	
	"After compaction the send should arrive to the callee entry offset"
	
	"Check case 2"
	self createFramefulCallFrom: callerAddress.
	self prepareStackForSendReceiver: memory falseObject arguments: { memory integerObjectOf: 7 }.
	self
		runFrom: (interpreter cogMethodOf: callerMethodOop) address + cogit noCheckEntryOffset
		until: cogit cePICAbortTrampoline.

	self
		assert: machineSimulator instructionPointerValue
		equals: cogit cePICAbortTrampoline
]
