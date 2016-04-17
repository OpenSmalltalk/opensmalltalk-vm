"
RegisterAllocatingCogit is an optimizing code generator that is specialized in register allocation..

On the contrary to StackToRegisterMappingCogit, RegisterAllocatingCogit keeps at each control flow merge point the state of the simulated stack to merge into and not only an integer fixup. Each branch and jump record the current state of the simulated stack, and each fixup is responsible for merging this state into the saved simulated stack.

"
Class {
	#name : #RegisterAllocatingCogit,
	#superclass : #StackToRegisterMappingCogit,
	#instVars : [
		'numFixups',
		'mergeSimStacksBase',
		'nextFixup'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'compile abstract instructions' }
RegisterAllocatingCogit >> allocateMergeFixups [
	"Allocate the various arrays needed to allocate the merge fixups, failing if the size
	 needed is considered too high.

	 This *must* be inlined since the arrays are alloca'ed (stack allocated)
	 so that they are freed when compilation is done.

	 N.B. We do one single alloca to save embarrassing C optimizers that
	 generate incorrect code as both gcc and the intel compiler do on x86."
	<inline: true>
	| mergeSimStackBytes |
	mergeSimStackBytes := numFixups * self simStackSlots * (self sizeof: CogSimStackEntry).
	nextFixup := 0.
	self cCode:
		[mergeSimStacksBase := self alloca: mergeSimStackBytes.
		 self b: mergeSimStacksBase zero: mergeSimStackBytes]
]

{ #category : #'simulation only' }
RegisterAllocatingCogit >> bytecodeFixupClass [
	<doNotGenerate>
	^CogRASSBytecodeFixup
]

{ #category : #'compile abstract instructions' }
RegisterAllocatingCogit >> compileEntireFullBlockMethod: numCopied [
	"Compile the abstract instructions for the entire full block method."
	self allocateMergeFixups.
	^super compileEntireFullBlockMethod: numCopied
]

{ #category : #'compile abstract instructions' }
RegisterAllocatingCogit >> compileEntireMethod [
	"Compile the abstract instructions for the entire method, including blocks."
	self allocateMergeFixups.
	^super compileEntireMethod
]

{ #category : #'simulation only' }
RegisterAllocatingCogit >> copySimStack [
	<doNotGenerate>
	^CArrayAccessor on: (simStack object collect: [:stackEntry| stackEntry copy])
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> ensureFixupAt: targetIndex [
	| fixup |	
	<var: #fixup type: #'BytecodeFixup *'>
	fixup := self fixupAt: targetIndex.
	fixup needsFixup 
		ifTrue: [self mergeCurrentSimStackWith: fixup mergeSimStack ]
		ifFalse: 
			[self assert: fixup mergeSimStack isNil.
			self moveSimStackConstantsToRegisters.
			self setMergeSimStackOf: fixup ].
	^super ensureFixupAt: targetIndex.

]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> flushLiveRegistersForCRunTimeCall [
	<inline: true>
	0 to: simStackPtr do:
		[:i| | reg |
		 self assert: (self simStackAt: i) type = (i <= methodOrBlockNumTemps
													ifTrue: [SSBaseOffset]
													ifFalse: [SSSpill]).
		 reg := (self simStackAt: i) liveRegister.
		 (reg ~= NoReg and: [(self isCallerSavedReg: reg)]) ifTrue:
			[(self simStackAt: i) liveRegister: NoReg]]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> flushLiveRegistersForSend [
	<inline: true>
	0 to: simStackPtr do:
		[:i|
		 self assert: (self simStackAt: i) type = (i <= methodOrBlockNumTemps
													ifTrue: [SSBaseOffset]
													ifFalse: [SSSpill]).
		 (self simStackAt: i) liveRegister: NoReg]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> genJumpIf: boolean to: targetBytecodePC [
	<inline: false>
	| desc fixup ok |
	<var: #desc type: #'CogSimStackEntry *'>
	<var: #fixup type: #'BytecodeFixup *'>
	<var: #ok type: #'AbstractInstruction *'>
	1halt.
	self ssFlushTo: simStackPtr - 1.
	desc := self ssTop.
	self ssPop: 1.
	(desc type == SSConstant
	 and: [desc constant = objectMemory trueObject or: [desc constant = objectMemory falseObject]]) ifTrue:
		["Must arrange there's a fixup at the target whether it is jumped to or
		  not so that the simStackPtr can be kept correct."
		 fixup := self ensureFixupAt: targetBytecodePC - initialPC.
		 "Must enter any annotatedConstants into the map"
		 desc annotateUse ifTrue:
			[self annotateBytecode: (self prevInstIsPCAnnotated
											ifTrue: [self Nop]
											ifFalse: [self Label])].
		 "Must annotate the bytecode for correct pc mapping."
		 self annotateBytecode: (desc constant = boolean
									ifTrue: [self Jump: fixup]
									ifFalse: [self prevInstIsPCAnnotated
												ifTrue: [self Nop]
												ifFalse: [self Label]]).
		 ^0].
	desc popToReg: TempReg.
	"Cunning trick by LPD.  If true and false are contiguous subtract the smaller.
	 Correct result is either 0 or the distance between them.  If result is not 0 or
	 their distance send mustBeBoolean."
	self assert: (objectMemory objectAfter: objectMemory falseObject) = objectMemory trueObject.
	self genSubConstant: boolean R: TempReg.
	self JumpZero: (self ensureFixupAt: targetBytecodePC - initialPC).

	self extASpecifiesNoMustBeBoolean ifTrue: 
		[ extA := 0. 
		self annotateBytecode: self lastOpcode.
		^ 0].
	extA := 0.
	
.	self CmpCq: (boolean == objectMemory falseObject
					ifTrue: [objectMemory trueObject - objectMemory falseObject]
					ifFalse: [objectMemory falseObject - objectMemory trueObject])
		R: TempReg.
	ok := self JumpZero: 0.
	self CallRT: (boolean == objectMemory falseObject
					ifTrue: [ceSendMustBeBooleanAddFalseTrampoline]
					ifFalse: [ceSendMustBeBooleanAddTrueTrampoline]).
	ok jmpTarget: (self annotateBytecode: self Label).
	^0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> genJumpTo: targetBytecodePC [
	self Jump: (self ensureFixupAt: targetBytecodePC - initialPC).
	^ 0
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> genMarshalledSend: selectorIndex numArgs: numArgs sendTable: sendTable [
	self flushLiveRegistersForSend.
	^super genMarshalledSend: selectorIndex numArgs: numArgs sendTable: sendTable
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> genStorePop: popBoolean TemporaryVariable: tempIndex [
	"Override so that if a register other than TempReg is allocated, the temp is marked as being live in that register."
	| reg |
	self ssFlushUpThroughTemporaryVariable: tempIndex.
	reg := self ssStorePop: popBoolean toPreferredReg: TempReg.
	self MoveR: reg
		Mw: (self frameOffsetOfTemporary: tempIndex)
		r: FPReg.
	reg ~= TempReg ifTrue:
		[(self simStackAt: tempIndex) liveRegister: reg].
	^0
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> initSimStackForFramefulMethod: startpc [
	super initSimStackForFramefulMethod: startpc.
	simSelf liveRegister: NoReg.
	0 to: simStackPtr do:
		[:i| (self simStackAt: i) liveRegister: NoReg]
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> initSimStackForFramelessBlock: startpc [
	super initSimStackForFramelessBlock: startpc.
	simSelf liveRegister: simSelf register.
	0 to: simStackPtr do:
		[:i| (self simStackAt: i) liveRegister: NoReg]
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> initSimStackForFramelessMethod: startpc [
	super initSimStackForFramelessMethod: startpc.
	simSelf liveRegister: NoReg.
	0 to: simStackPtr do:
		[:i| | desc |
		desc := self simStackAt: 1.
		desc liveRegister: (desc type = SSRegister ifTrue: [desc register] ifFalse: [NoReg])]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> mergeCurrentSimStackWith: mergeSimStack [
	<var: #mergeSimStack type: #'SimStackEntry *'>
	<var: #currentSSEntry type: #'SimStackEntry *'>
	<var: #expectedSSEntry type: #'SimStackEntry *'>
	"At merge point the cogit expects the stack to be in the same state as mergeSimStack.
	The logic is very naive, we align the existing state from the current stack to the merge stack
	from simStackPtr to methodOrBlockNumTemps, and if a conflict happen, we flush what remains
	to be merged."
	self flag: #TODO. "we could have a better algorithm with the current set of live registers to avoid flushing"
	simStackPtr to: methodOrBlockNumTemps by: -1 do:
		[:i|
			| currentSSEntry expectedSSEntry |
			currentSSEntry := self simStackAt: i.
			expectedSSEntry := self simStack: mergeSimStack at: i.
			expectedSSEntry
				caseOf: {
					[SSBaseOffset]	-> [ self assert: (expectedSSEntry register = ReceiverResultReg or: [ expectedSSEntry register = FPReg ]).
										(expectedSSEntry register = ReceiverResultReg and: [needsFrame]) ifTrue: 
											[optStatus isReceiverResultRegLive ifFalse: 
												[self ssFlushFrom: i - 1 upThroughRegister: ReceiverResultReg.
											 	 self putSelfInReceiverResultReg ].
											 optStatus isReceiverResultRegLive: true].  ].
					[SSSpill]		-> [currentSSEntry ensureSpilledAt: (self frameOffsetOfTemporary: i) from: FPReg].
					[SSConstant]	-> [self assert: expectedSSEntry liveRegister notNil. 
										currentSSEntry storeToReg: expectedSSEntry liveRegister ].
					[SSRegister]	-> [(currentSSEntry type = SSRegister and: [currentSSEntry register = expectedSSEntry register])
											ifFalse: 
												[ self ssFlushFrom: i - 1 upThroughRegister: expectedSSEntry register.
												currentSSEntry storeToReg: expectedSSEntry register ] ]}.
			 ]
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> moveSimStackConstantsToRegisters [
	<inline: true>
	(simSpillBase max: 0) to: simStackPtr do: 
		[:i|
			| desc |
			desc := self simStackAt: i.
			(desc type = SSConstant and: [desc liveRegister = NoReg])
				ifTrue: [ desc storeToReg: (self allocateRegNotConflictingWith: 0) ] ]
]

{ #category : #'compile abstract instructions' }
RegisterAllocatingCogit >> scanMethod [
	"Overrides to count the number of fixups."
	"Scan the method (and all embedded blocks) to determine
		- what the last bytecode is; extra bytes at the end of a method are used to encode things like source pointers or temp names
		- if the method needs a frame or not
		- what are the targets of any backward branches.
		- how many blocks it creates
	 Answer the block count or on error a negative error code"
	| latestContinuation nExts descriptor pc numBlocks distance targetPC framelessStackDelta |
	<var: #descriptor type: #'BytecodeDescriptor *'>
	needsFrame := false.
	numFixups := 0.
	prevBCDescriptor := nil.
	NewspeakVM ifTrue:
		[numIRCs := 0].
	(primitiveIndex > 0
	 and: [coInterpreter isQuickPrimitiveIndex: primitiveIndex]) ifTrue:
		[^0].
	pc := latestContinuation := initialPC.
	numBlocks := framelessStackDelta := nExts := extA := extB := 0.
	[pc <= endPC] whileTrue:
		[byte0 := (objectMemory fetchByte: pc ofObject: methodObj) + bytecodeSetOffset.
		 descriptor := self generatorAt: byte0.
		 descriptor isExtension ifTrue:
			[descriptor opcode = Nop ifTrue: "unknown bytecode tag; see Cogit class>>#generatorTableFrom:"
				[^EncounteredUnknownBytecode].
			 self loadSubsequentBytesForDescriptor: descriptor at: pc.
			 self perform: descriptor generator].
		 (descriptor isReturn
		  and: [pc >= latestContinuation]) ifTrue:
			[endPC := pc].
		 needsFrame ifFalse:
			[(descriptor needsFrameFunction isNil
			  or: [self perform: descriptor needsFrameFunction with: framelessStackDelta])
				ifTrue: [needsFrame := true]
				ifFalse: [framelessStackDelta := framelessStackDelta + descriptor stackDelta]].
		 descriptor isBranch ifTrue:
			[distance := self spanFor: descriptor at: pc exts: nExts in: methodObj.
			 targetPC := pc + descriptor numBytes + distance.
			 (self isBackwardBranch: descriptor at: pc exts: nExts in: methodObj)
				ifTrue: [self initializeFixupAt: targetPC - initialPC]
				ifFalse: 
					[latestContinuation := latestContinuation max: targetPC.
					numFixups := numFixups + 1]].
		 descriptor isBlockCreation ifTrue:
			[numBlocks := numBlocks + 1.
			 distance := self spanFor: descriptor at: pc exts: nExts in: methodObj.
			 targetPC := pc + descriptor numBytes + distance.
			 latestContinuation := latestContinuation max: targetPC.
			 numFixups := numFixups + 1].
		 NewspeakVM ifTrue:
			[descriptor hasIRC ifTrue:
				[numIRCs := numIRCs + 1]].
		 pc := pc + descriptor numBytes.
		 descriptor isExtension
			ifTrue: [nExts := nExts + 1]
			ifFalse: [nExts := extA := extB := 0].
		 prevBCDescriptor := descriptor].
	^numBlocks
]

{ #category : #'bytecode generator support' }
RegisterAllocatingCogit >> setMergeSimStackOf: fixup [
	<var: #fixup type: #'BytecodeFixup *'>
	self assert: nextFixup < numFixups.
	self moveSimStackConstantsToRegisters.
	self cCode: [fixup mergeSimStack: mergeSimStacksBase + (nextFixup * self simStackSlots * (self sizeof: CogSimStackEntry))].
	nextFixup := nextFixup + 1.
	self cCode: [self mem: fixup mergeSimStack cp: self simStackSlots * (self sizeof: CogSimStackEntry) y: simStack]
		inSmalltalk: [fixup mergeSimStack: self copySimStack]
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> simStack: stack at: index [
	<cmacro: '(index) (stack + (index))'>
	<returnTypeC: #'CogSimStackEntry *'>
	^self addressOf: (stack at: index)
]

{ #category : #initialization }
RegisterAllocatingCogit >> simStackEntryClass [
	<doNotGenerate>
	^CogRegisterAllocatingSimStackEntry
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> ssFlushFrom: start upThrough: unaryBlock [
	"Any occurrences on the stack of the value being stored (which is the top of stack)
	 must be flushed, and hence any values colder than them stack."
	<inline: true>
	start to: (simSpillBase max: 0) by: -1 do:
		[ :index |
		(unaryBlock value: (self simStackAt: index)) ifTrue: [ ^ self ssFlushTo: index ] ]
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> ssFlushFrom: start upThroughRegister: reg [
	"Any occurrences on the stack of the register must be
	 flushed, and hence any values colder than them stack."
	<var: #desc type: #'CogSimStackEntry *'>
	self ssFlushFrom: start upThrough: [ :desc | desc type = SSRegister and: [ desc register = reg ] ]
]

{ #category : #'simulation stack' }
RegisterAllocatingCogit >> ssStorePop: popBoolean toPreferredReg: preferredReg [
	"Store or pop the top simulated stack entry to a register.
	 Use preferredReg if the entry is not itself a register.
	 Answer the actual register the result ends up in."
	| actualReg |
	actualReg := preferredReg.
	self ssTop type = SSRegister ifTrue: 
		[self assert: self ssTop liveRegister = self ssTop register.
		self assert: self ssTop annotateUse not.
		self assert: self ssTop spilled not].
	self ssTop liveRegister ~= NoReg ifTrue:
		[actualReg := self ssTop liveRegister].
	self ssStorePop: popBoolean toReg: actualReg. "generates nothing if ssTop is already in actualReg"
	^ actualReg
]
