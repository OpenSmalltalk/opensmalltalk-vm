Class {
	#name : #CogObjectRepresentationForSpur,
	#superclass : #CogObjectRepresentation,
	#instVars : [
		'ceScheduleScavengeTrampoline',
		'ceSmallActiveContextInMethodTrampoline',
		'ceSmallActiveContextInBlockTrampoline',
		'ceLargeActiveContextInMethodTrampoline',
		'ceLargeActiveContextInBlockTrampoline',
		'ceStoreCheckContextReceiverTrampoline',
		'ceCannotAssignToWithIndexTrampoline'
	],
	#pools : [
		'VMBytecodeConstants',
		'VMSqueakClassIndices'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #accessing }
CogObjectRepresentationForSpur class >> numTrampolines [
	(initializationOptions at: #IMMUTABILITY ifAbsent: [false])
		ifTrue: [ ^ super numTrampolines + 7 ]
		ifFalse: [ ^ super numTrampolines + 6 ]
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> allYoungObjectsAgeInFullGC [
	^false
]

{ #category : #'newspeak support' }
CogObjectRepresentationForSpur >> allocateNPinnedSlots: nSlots [
	"On Newspeak allocate the implicit receiver caches on the heap as pinned objects."
	<inline: true>
	<option: #NewspeakVM>
	| objOop |
	objOop := objectMemory allocatePinnedSlots: nSlots.
	^objOop
		ifNil: [0]
		ifNotNil: [objOop + objectMemory baseHeaderSize]
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> branchIf: reg notInstanceOfBehavior: classObj target: targetFixUp [
	"Generate a branch if reg is an instance of classObj, otherwise fall-
	 through. Cannot change the value of reg (may be used afterwards)."
	| classIndex |
	<inline: true>
	<var: #targetFixUp type: #'AbstractInstruction *'>
	classIndex := objectMemory classTagForClass: classObj.
	(objectMemory isImmediateClass: classObj)
		ifTrue:
			[self branchIf: reg hasNotImmediateTag: classIndex target: targetFixUp ]
		ifFalse:
			[(self genJumpImmediate: reg) jmpTarget: targetFixUp.
			 self genGetClassIndexOfNonImm: reg into: TempReg.
			 self genCmpClassIndex: classIndex R: TempReg.
			 cogit JumpNonZero: targetFixUp ].
	^0
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> branchIf: reg notInstanceOfBehaviors: arrayObj target: targetFixUp [
	"Generate a branch if reg is an instance of any of the classes in arrayObj,
	 otherwise fall-through. reg should not be edited."
	
	| allImmediate noneImmediate immediateMask numNonImmediates classObj |
	<var: #targetFixUp type: #'AbstractInstruction *'>
	
	"let me tell you all about it, let me falsify"
	allImmediate := true. noneImmediate := true. immediateMask := 0. numNonImmediates := 0.
	0 to: (objectMemory numSlotsOf: arrayObj) - 1 do:
		[:i|
		 classObj := objectMemory fetchPointer: i ofObject: arrayObj.
		 (objectMemory isImmediateClass: classObj)
			ifTrue:
				[noneImmediate := false.
				 immediateMask := immediateMask + (objectMemory classTagForClass: classObj)]
			ifFalse:
				[allImmediate := false.
				 numNonImmediates := numNonImmediates + 1]].

	noneImmediate ifTrue: [ ^ self noneImmediateBranchIf: reg notInstanceOfBehaviors: arrayObj target: targetFixUp ].

	allImmediate ifTrue: [ ^ self allImmediate: immediateMask branchIf: reg notInstanceOfBehaviors: arrayObj target: targetFixUp ].

	^ self mixed: numNonImmediates branchIf: reg notInstanceOfBehaviors: arrayObj target: targetFixUp
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> cacheTagIsMarked: cacheTag [
	"Answer if the cacheTag is not unmarked, i.e. answer true for compact class
	 indices and immediates; only answer false for unmarked objects.  In Spur
	 linked send cache tags are class indices so effectively they're always marked."
	^true
]

{ #category : #testing }
CogObjectRepresentationForSpur >> canPinObjects [
	"Answer if the memory manager supports pinned objects."
	<inline: true>
	^true
]

{ #category : #'debug support' }
CogObjectRepresentationForSpur >> checkValidOopReference: anOop [
	^(objectMemory isImmediate: anOop)
	   or: [(objectMemory heapMapAtWord: (self pointerForOop: anOop)) ~= 0]
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationForSpur >> classForInlineCacheTag: classIndex [
	^objectMemory classOrNilAtIndex: classIndex
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> couldBeObject: literal [
	^(objectMemory isNonImmediate: literal)
	  and: [self oop: literal isGreaterThanOrEqualTo: objectMemory startOfMemory]
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationForSpur >> createsArraysInline [
	"Answer if the object representation allocates arrays inline.  By
	 default answer false. Better code can be generated when creating
	 arrays inline if values are /not/ flushed to the stack."
	^true
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationForSpur >> createsClosuresInline [
	"Answer if the object representation allocates closures inline.  By
	 default answer false. Better code can be generated when creating
	 closures inline if copied values are /not/ flushed to the stack."
	^true
]

{ #category : #initialization }
CogObjectRepresentationForSpur >> ensureNoForwardedLiteralsIn: aMethodObj [
	"Ensure there are no forwarded literals in the argument."
	<doNotGenerate>
	objectMemory ensureNoForwardedLiteralsIn: aMethodObj
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> freeCounters: theCounters [
	<var: #theCounters type: #usqInt>
	<inline: true>
	<option: #SistaStackToRegisterMappingCogit>
	theCounters ~= 0 ifTrue:
		[objectMemory freeObject: theCounters - objectMemory baseHeaderSize]
]

{ #category : #'newspeak support' }
CogObjectRepresentationForSpur >> freeIRCs: maybeIRCs [
	<var: #maybeIRCs type: #usqInt>
	<option: #NewspeakVM>
	<inline: true>
	(self oop: maybeIRCs isGreaterThan: objectMemory nilObject) ifTrue:
		[objectMemory freeObject: maybeIRCs - objectMemory baseHeaderSize]
]

{ #category : #initialization }
CogObjectRepresentationForSpur >> genActiveContextTrampolineLarge: isLarge inBlock: isInBlock called: aString [
	<var: #aString type: #'char *'>
	"Create a trampoline to answer the active context that will
	 answer it if a frame is already married, and create it otherwise.
	 Assume numArgs is in SendNumArgsReg and ClassReg is free."
	| startAddress |
	startAddress := cogit methodZoneBase.
	cogit zeroOpcodeIndex.
	self genGetActiveContextLarge: isLarge inBlock: isInBlock.
	cogit outputInstructionsForGeneratedRuntimeAt: startAddress.
	cogit recordGeneratedRunTime: aString address: startAddress.
	cogit recordRunTimeObjectReferences.
	^startAddress
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genAllocFloatValue: dpreg into: resultReg scratchReg: scratch1 scratchReg: scratch2 [
	<returnTypeC: #'AbstractInstruction *'>
	| allocSize newFloatHeader jumpFail |
	<var: #jumpFail type: #'AbstractInstruction *'>
	allocSize := objectMemory baseHeaderSize + (objectMemory sizeof: #double).
	newFloatHeader := objectMemory
							headerForSlots: (self sizeof: #double) / objectMemory wordSize
							format: objectMemory firstLongFormat
							classIndex: ClassFloatCompactIndex.
	cogit MoveAw: objectMemory freeStartAddress R: resultReg.
	cogit LoadEffectiveAddressMw: allocSize r: resultReg R: scratch1.
	cogit CmpCq: objectMemory getScavengeThreshold R: scratch1.
	jumpFail := cogit JumpAboveOrEqual: 0.
	cogit MoveR: scratch1 Aw: objectMemory freeStartAddress.
	self genStoreHeader: newFloatHeader intoNewInstance: resultReg using: scratch1.
	cogit MoveRd: dpreg M64: objectMemory baseHeaderSize r: resultReg.
	^jumpFail
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genConvertCharacterToCodeInReg: reg [ 
	cogit LogicalShiftRightCq: objectMemory numTagBits R: reg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genConvertIntegerToCharacterInReg: reg [
	cogit
		LogicalShiftLeftCq: objectMemory numTagBits R: reg;
		AddCq: objectMemory characterTag R: reg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genConvertSmallIntegerToCharacterInReg: reg [
	self subclassResponsibility
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationForSpur >> genCreateClosureAt: bcpc numArgs: numArgs numCopied: numCopied contextNumArgs: ctxtNumArgs large: isLargeCtxt inBlock: isInBlock [
	"Create a closure with the given startpc, numArgs and numCopied
	 within a context with ctxtNumArgs, large if isLargeCtxt that is in a
	 block if isInBlock.  If numCopied > 0 pop those values off the stack."
	self genNoPopCreateClosureAt: bcpc
		numArgs: numArgs
		numCopied: numCopied
		contextNumArgs: ctxtNumArgs
		large: isLargeCtxt
		inBlock: isInBlock.
	1 to: numCopied do:
		[:i|
		cogit
			PopR: TempReg;
			MoveR: TempReg
				Mw: numCopied - i + ClosureFirstCopiedValueIndex * objectMemory bytesPerOop + objectMemory baseHeaderSize
					r: ReceiverResultReg].
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genEnsureObjInRegNotForwarded: reg scratchReg: scratch [
	"Make sure that the object in reg is not forwarded.  This routine assumes the object will
	 never be forwarded to an immediate, as it is used to unforward  literal variables (associations). 
	 Use the fact that isForwardedObjectClassIndexPun is a power of two to save an instruction."
	| loop ok |
	<var: #ok type: #'AbstractInstruction *'>
	<var: #loop type: #'AbstractInstruction *'>
	self assert: reg ~= scratch.
	loop := cogit Label.
	"notionally
		self genGetClassIndexOfNonImm: reg into: scratch.
		cogit CmpCq: objectMemory isForwardedObjectClassIndexPun R: TempReg.
	 but the following is an instruction shorter:"
	cogit MoveMw: 0 r: reg R: scratch.
	cogit
		AndCq: objectMemory classIndexMask - objectMemory isForwardedObjectClassIndexPun
		R: scratch.
	ok := cogit JumpNonZero:  0.
	self genLoadSlot: 0 sourceReg: reg destReg: reg.
	cogit Jump: loop.
	ok jmpTarget: cogit Label.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genEnsureOopInRegNotForwarded: reg scratchReg: scratch [
	^ self 
		genEnsureOopInRegNotForwarded: reg 
		scratchReg: scratch 
		jumpBackTo: cogit Label "label is just before the forwarder check"
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genEnsureOopInRegNotForwarded: reg scratchReg: scratch ifForwarder: fwdJumpTarget ifNotForwarder: nonFwdJumpTargetOrZero [
	"Make sure that the oop in reg is not forwarded.  
	 Use the fact that isForwardedObjectClassIndexPun is a power of two to save an instruction."
	| imm ok finished |
	<inline: true>
	<var: #ok type: #'AbstractInstruction *'>
	<var: #imm type: #'AbstractInstruction *'>
	<var: #finished type: #'AbstractInstruction *'>
	self assert: reg ~= scratch.
	imm := self genJumpImmediate: reg.
	"notionally
		self genGetClassIndexOfNonImm: reg into: scratch.
		cogit CmpCq: objectMemory isForwardedObjectClassIndexPun R: TempReg.
	 but the following is an instruction shorter:"
	cogit MoveMw: 0 r: reg R: scratch.
	cogit
		AndCq: objectMemory classIndexMask - objectMemory isForwardedObjectClassIndexPun
		R: scratch.
	ok := cogit JumpNonZero: 0.
	self genLoadSlot: 0 sourceReg: reg destReg: reg.
	cogit Jump: fwdJumpTarget.
	finished := nonFwdJumpTargetOrZero = 0
		ifTrue: [ cogit Label ]
		ifFalse: [ self cCoerceSimple: nonFwdJumpTargetOrZero to: #'AbstractInstruction *' ].
	imm jmpTarget: (ok jmpTarget: finished).
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genEnsureOopInRegNotForwarded: reg scratchReg: scratch jumpBackTo: instruction [
	<var: #instruction type: #'AbstractInstruction *'>
	^ self 
		genEnsureOopInRegNotForwarded: reg 
		scratchReg: scratch 
		ifForwarder: instruction
		ifNotForwarder: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genEnsureOopInRegNotForwarded: reg scratchReg: scratch updatingMw: offset r: baseReg [
	"Make sure that the oop in reg is not forwarded, and the field reg[offset] is updated
	 if the object in reg is forwarded.  Use the fact that isForwardedObjectClassIndexPun is
	 a power of two to save an instruction."
	| loop imm ok |
	<var: #ok type: #'AbstractInstruction *'>
	<var: #imm type: #'AbstractInstruction *'>
	<var: #loop type: #'AbstractInstruction *'>
	self assert: (reg ~= scratch and: [baseReg ~= scratch]).
	loop := cogit Label.
	imm := self genJumpImmediate: reg.
	"notionally
		self genGetClassIndexOfNonImm: reg into: scratch.
		cogit CmpCq: objectMemory isForwardedObjectClassIndexPun R: TempReg.
	 but the following is an instruction shorter:"
	cogit MoveMw: 0 r: reg R: scratch.
	cogit
		AndCq: objectMemory classIndexMask - objectMemory isForwardedObjectClassIndexPun
		R: scratch.
	ok := cogit JumpNonZero:  0.
	self genLoadSlot: 0 sourceReg: reg destReg: reg.
	cogit MoveR: reg Mw: offset r: baseReg.
	cogit Jump: loop.
	ok jmpTarget: (imm jmpTarget: cogit Label).
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genEnsureOopInRegNotForwarded: reg scratchReg: scratch updatingSlot: index in: objReg [
	"Make sure that the oop in reg is not forwarded, updating the slot in objReg with the value."
	| loop imm ok |
	<var: #ok type: #'AbstractInstruction *'>
	<var: #imm type: #'AbstractInstruction *'>
	<var: #loop type: #'AbstractInstruction *'>
	"Open-code
		self genEnsureOopInRegNotForwarded: reg
			scratchReg: scratch
			updatingMw: index * objectMemory wordSize + objectMemory baseHeaderSize
			r: objReg.
	 to avoid calling the store check unless the receiver is forwarded."
	self assert: (reg ~= scratch and: [objReg ~= scratch]).
	loop := cogit Label.
	imm := self genJumpImmediate: reg.
	"notionally
		self genGetClassIndexOfNonImm: reg into: scratch.
		cogit CmpCq: objectMemory isForwardedObjectClassIndexPun R: TempReg.
	 but the following is an instruction shorter:"
	cogit MoveMw: 0 r: reg R: scratch.
	cogit
		AndCq: objectMemory classIndexMask - objectMemory isForwardedObjectClassIndexPun
		R: scratch.
	ok := cogit JumpNonZero:  0.
	self genLoadSlot: 0 sourceReg: reg destReg: reg.
	cogit MoveR: reg Mw: index * objectMemory wordSize + objectMemory baseHeaderSize r: objReg.

	"Check that we're meeting the contract of ceStoreCheckContextReceiverTrampoline."
	self assert: (reg = Arg0Reg and: [scratch = TempReg and: [objReg = ReceiverResultReg]]).
	cogit CallRT: ceStoreCheckContextReceiverTrampoline.

	cogit Jump: loop.
	ok jmpTarget: (imm jmpTarget: cogit Label).
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genFetchIndexRegister: indexReg from: tableObj into: destReg [
	"indexReg contains the 1-relative index of an element in tableObj."
	self subclassResponsibility
]

{ #category : #initialization }
CogObjectRepresentationForSpur >> genGetActiveContextLarge: isLarge inBlock: isInBlock [
	"Create a trampoline to answer the active context that will
	 answer it if a frame is already married, and create it otherwise.
	 Assume numArgs is in SendNumArgsReg and ClassReg is free."
	| header slotSize jumpSingle loopHead jumpNeedScavenge continuation exit |
	<var: #jumpNeedScavenge type: #'AbstractInstruction *'>
	<var: #continuation type: #'AbstractInstruction *'>
	<var: #jumpSingle type: #'AbstractInstruction *'>
	<var: #loopHead type: #'AbstractInstruction *'>
	<var: #exit type: #'AbstractInstruction *'>
	cogit "load the flag; stash it in both TempReg & ClassReg; do the compare (a prime candidated for use of AndCq:R:R:)"
		MoveMw: FoxMethod r: FPReg R: ClassReg;
		AndCq: MFMethodFlagHasContextFlag R: ClassReg R: TempReg.
	jumpSingle := cogit JumpZero: 0. "jump if flag bit not set"
	cogit "since the flag bit was set, get the context in the receiver reg and return"
		MoveMw: FoxThisContext r: FPReg R: ReceiverResultReg;
		RetN: 0.
	jumpSingle jmpTarget: cogit Label.

	"OK, it doesn't exist; instantiate and initialize it"
	"set the hasContext flag; See CoInterpreter class>>initializeFrameIndices"
	cogit
		OrCq: MFMethodFlagHasContextFlag R: ClassReg;
		MoveR: ClassReg Mw: FoxMethod r: FPReg.
	"now get the home CogMethod into ClassReg and save for post-instantiation."
	isInBlock
		ifTrue:
			[cogit
				SubCq: 3 R: ClassReg; "-3 is -(hasContext+isBlock) flags"
				MoveM16: 0 r: ClassReg R: TempReg;
				SubR: TempReg R: ClassReg]
		ifFalse:
			[cogit SubCq: 1 R: ClassReg]. "-1 is hasContext flag"

	"instantiate the context..."
	slotSize := isLarge ifTrue: [LargeContextSlots] ifFalse: [SmallContextSlots].
	header := objectMemory
					headerForSlots: slotSize
					format: objectMemory indexablePointersFormat
					classIndex: ClassMethodContextCompactIndex.
	self flag: #endianness.
	cogit MoveAw: objectMemory freeStartAddress R: ReceiverResultReg.
	self genStoreHeader: header intoNewInstance: ReceiverResultReg using: TempReg.
	cogit
		MoveR: ReceiverResultReg R: TempReg;
		AddCq: (objectMemory smallObjectBytesForSlots: slotSize) R: TempReg;
		MoveR: TempReg Aw: objectMemory freeStartAddress;
		CmpCq: objectMemory getScavengeThreshold R: TempReg.
	jumpNeedScavenge := cogit JumpAboveOrEqual: 0.

	"Now initialize the fields of the context.  See CoInterpreter>>marryFrame:SP:copyTemps:"
	"sender gets frame pointer as a SmallInteger"
	continuation :=
	cogit MoveR: FPReg R: TempReg.
	self genSetSmallIntegerTagsIn: TempReg.
	cogit MoveR: TempReg Mw: objectMemory baseHeaderSize + (SenderIndex * objectMemory bytesPerOop) r: ReceiverResultReg.

	"pc gets frame caller as a SmallInteger"
	cogit MoveMw: FoxSavedFP r: FPReg R: TempReg.
	self genSetSmallIntegerTagsIn: TempReg.
	cogit MoveR: TempReg Mw: objectMemory baseHeaderSize + (InstructionPointerIndex * objectMemory bytesPerOop) r: ReceiverResultReg.

	"Set the method field, freeing up ClassReg again, and frame's context field,"
	cogit
		MoveMw: (cogit offset: CogMethod of: #methodObject) r: ClassReg R: TempReg;
		MoveR: TempReg Mw: objectMemory baseHeaderSize + (MethodIndex * objectMemory wordSize) r: ReceiverResultReg;
		MoveR: ReceiverResultReg Mw: FoxThisContext r: FPReg.

	"Now compute stack pointer; this is stackPointer (- 1 for return pc if a CISC) - framePointer - wordSize (1 each for saved pc, method, context, receiver) + 1 (1-relative) + numArgs"
	"TPR note - the code here is actually doing
	context stackPointer := ((((fp - sp) / wordSize) - [3|4]) + num args) asSmallInteger"
	cogit
		MoveR: FPReg R: TempReg;
		SubR: SPReg R: TempReg;
		LogicalShiftRightCq: self log2BytesPerWord R: TempReg;
		SubCq: (cogit backEnd hasLinkRegister ifTrue: [3] ifFalse: [4]) R: TempReg;
		AddR: SendNumArgsReg R: TempReg.
	self genConvertIntegerToSmallIntegerInReg: TempReg.
	cogit MoveR: TempReg Mw: objectMemory baseHeaderSize + (StackPointerIndex * objectMemory bytesPerOop) r: ReceiverResultReg.

	"Set closureOrNil to either the stacked receiver or nil"
	isInBlock
		ifTrue:
			[cogit
				MoveR: SendNumArgsReg R: TempReg;
				AddCq: 2 R: TempReg; "+2 for saved fp and saved pc"
				MoveXwr: TempReg R: FPReg R: TempReg]
		ifFalse:
			[cogit genMoveConstant: objectMemory nilObject R: TempReg].
	cogit MoveR: TempReg Mw: objectMemory baseHeaderSize + (ClosureIndex * objectMemory bytesPerOop) r: ReceiverResultReg.

	"Set the receiver"
	cogit
		MoveMw: FoxMFReceiver r: FPReg R: TempReg;
		MoveR: TempReg Mw: objectMemory baseHeaderSize + (ReceiverIndex * objectMemory bytesPerOop) r: ReceiverResultReg.

	"Now copy the arguments.  This is tricky because of the shortage of registers,.  ClassReg ranges
	 from 1 to numArgs (SendNumArgsReg), and from ReceiverIndex + 1 to ReceiverIndex + numArgs.
	 1 to: numArgs do:
		[:i|
		temp := longAt(FPReg + ((SendNumArgs - i + 2) * wordSize)). +2 for saved pc and savedfp
		longAtput(FPReg + FoxMFReceiver + (i * wordSize), temp)]"
	"TPR note: this is a prime candidate for passing off to the backend to do at least faintly optimal code"
	cogit MoveCq: 1 R: ClassReg.
	loopHead := cogit CmpR: SendNumArgsReg R: ClassReg.
	exit := cogit JumpGreater: 0.
	cogit
		MoveR: SendNumArgsReg R: TempReg;
		SubR: ClassReg R: TempReg;
		AddCq: 2 R: TempReg; "+2 for saved fp and saved pc"
		MoveXwr: TempReg R: FPReg R: TempReg;
		AddCq: ReceiverIndex + (objectMemory baseHeaderSize / objectMemory wordSize) R: ClassReg; "Now convert ClassReg from frame index to context index"
		MoveR: TempReg Xwr: ClassReg R: ReceiverResultReg;
		SubCq: ReceiverIndex + (objectMemory baseHeaderSize / objectMemory wordSize) - 1 R: ClassReg; "convert back adding 1 ;-)"
		Jump: loopHead.
	exit jmpTarget: cogit Label.

	"Finally nil or copy the non-argument temps.
	 ClassReg := FPReg + FoxMFReceiver.
	 SendNumArgsReg := SendNumArgsReg+ReceiverIndex.
	 [ClassReg := ClassReg - wordSize.
	  backEnd hasLinkRegister
			ifTrue: [ClassReg > SPReg]
			ifFalse: [ClassReg >= SPReg]] whileTrue:
		[receiver[SendNumArgsReg] := *ClassReg.
		 SendNumArgsReg := SendNumArgsReg + 1]]"
	coInterpreter marryFrameCopiesTemps ifFalse:
		[cogit MoveCq: objectMemory nilObject R: TempReg].
	cogit
		MoveR: FPReg R: ClassReg;
		AddCq: FoxMFReceiver R: ClassReg;
		AddCq: ReceiverIndex + 1 + (objectMemory baseHeaderSize / objectMemory wordSize) R: SendNumArgsReg.
	loopHead :=
	cogit SubCq: objectMemory wordSize R: ClassReg.
	cogit CmpR: SPReg R: ClassReg.
	"If on a CISC there's a retpc for the trampoline call on top of stack; if on a RISC there isn't."
	exit := cogit backEnd hasLinkRegister
				ifTrue: [cogit JumpBelow: 0]
				ifFalse: [cogit JumpBelowOrEqual: 0].
	coInterpreter marryFrameCopiesTemps ifTrue:
		[cogit MoveMw: 0 r: ClassReg R: TempReg].
	cogit
		MoveR: TempReg Xwr: SendNumArgsReg R: ReceiverResultReg;
		AddCq: 1 R: SendNumArgsReg;
		Jump: loopHead.
	exit jmpTarget: cogit Label.

	cogit RetN: 0.
	
	jumpNeedScavenge jmpTarget: cogit Label.
	cogit backEnd saveAndRestoreLinkRegAround:
		[cogit CallRT: ceScheduleScavengeTrampoline].
	cogit Jump: continuation.
	^0
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationForSpur >> genGetActiveContextNumArgs: numArgs large: isLargeContext inBlock: isInBlock [
	"Get the active context into ReceiverResultReg, creating it if necessary."
	| routine |
	routine := isLargeContext
				ifFalse: [isInBlock
							ifFalse: [ceSmallActiveContextInMethodTrampoline]
							ifTrue: [ceSmallActiveContextInBlockTrampoline]]
				ifTrue: [isInBlock
							ifFalse: [ceLargeActiveContextInMethodTrampoline]
							ifTrue: [ceLargeActiveContextInBlockTrampoline]].
	cogit
		MoveCq: numArgs R: SendNumArgsReg;
		CallRT: routine.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetBits: mask ofFormatByteOf: sourceReg into: destReg [
	self flag: #endianness.
	cogit MoveMb: 3 r: sourceReg R: destReg.
	cogit AndCq: mask R: destReg.	"formatReg := self formatOfHeader: destReg"
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetClassIndexOfNonImm: sourceReg into: destReg [
	"Fetch the instance's class index into destReg."

	cogit MoveMw: 0 r: sourceReg R: destReg.
	cogit AndCq: objectMemory classIndexMask R: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetClassObjectOf: instReg into: destReg scratchReg: scratchReg instRegIsReceiver: instRegIsReceiver [
	"Fetch the instance's class into destReg.  If the instance is not the receiver and is forwarded, follow forwarding."
	| jumpIsImm jumpNotForwarded loop |
	<var: #jumpIsImm type: #'AbstractInstruction *'>
	<var: #jumpNotForwarded type: #'AbstractInstruction *'>
	<var: #loop type: #'AbstractInstruction *'>
	instReg = destReg ifTrue:
		[^BadRegisterSet].
	loop := cogit MoveR: instReg R: scratchReg.
	cogit AndCq: objectMemory tagMask R: scratchReg.
	jumpIsImm := cogit JumpNonZero: 0.
	self flag: #endianness.
	"Get least significant half of header word in destReg"
	cogit MoveMw: 0 r: instReg R: scratchReg.
	"mask off class index"
	cogit AndCq: objectMemory classIndexMask R: scratchReg.
	instRegIsReceiver ifFalse:
		["if it is forwarded..."
		cogit CmpCq: objectMemory isForwardedObjectClassIndexPun R: scratchReg.
		jumpNotForwarded := cogit JumpNonZero: 0.
		"...follow the forwarding pointer and loop to fetch its classIndex"
		cogit MoveMw: objectMemory baseHeaderSize r: instReg R: instReg.
		cogit Jump: loop.
		jumpNotForwarded jmpTarget: cogit Label].
	jumpIsImm jmpTarget:
	(cogit MoveR: scratchReg R: destReg).
	cogit PushR: instReg.
	self genGetClassObjectOfClassIndex: destReg into: instReg scratchReg: TempReg.
	cogit MoveR: instReg R: destReg.
	cogit PopR: instReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetClassObjectOfClassIndex: instReg into: destReg scratchReg: scratchReg [
	"Fetch the class object whose index is in instReg into destReg.
	 It is non-obvious, but the Cogit assumes loading a class does not involve
	 a runtime call, so do not call classAtIndex:"
	self assert: instReg ~= destReg.
	self assert: instReg ~= scratchReg.
	self assert: destReg ~= scratchReg.
	cogit
		MoveR: instReg R: scratchReg;
		LogicalShiftRightCq: objectMemory classTableMajorIndexShift R: scratchReg;
		LogicalShiftLeftCq: objectMemory shiftForWord R: scratchReg.
	self assert: (self shouldAnnotateObjectReference: objectMemory classTableRootObj) not.
	cogit
		MoveMw: objectMemory classTableRootObj + objectMemory baseHeaderSize r: scratchReg R: destReg;
		MoveR: instReg R: scratchReg;
		AndCq: objectMemory classTableMinorIndexMask R: scratchReg;
		AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: scratchReg;
		MoveXwr: scratchReg R: destReg R: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetClassTagOf: instReg into: destReg scratchReg: scratchReg [
	^self genGetInlineCacheClassTagFrom: instReg into: destReg forEntry: true
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetCompactClassIndexNonImmOf: instReg into: destReg [
	"Fetch the instance's class index into destReg."
	^self genGetClassIndexOfNonImm: instReg into: destReg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetDoubleValueOf: srcReg into: destFPReg [ 
	cogit MoveM64: objectMemory baseHeaderSize r: srcReg Rd: destFPReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetFormatOf: srcReg into: destReg [
	"Get the format field of the object in srcReg into destReg.
	 srcReg may equal destReg."
	^self genGetBits: objectMemory formatMask ofFormatByteOf: srcReg into: destReg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetFormatOf: sourceReg into: destReg leastSignificantHalfOfBaseHeaderIntoScratch: scratchRegOrNone [
	"Get the format of the object in sourceReg into destReg.  If scratchRegOrNone
	 is not NoReg, load at least the least significant 32-bits (64-bits in 64-bits) of the
	 header word, which contains the format, into scratchRegOrNone."
	scratchRegOrNone = NoReg
		ifTrue:
			[self flag: #endianness.
			 cogit MoveMb: 3 r: sourceReg R: destReg]
		ifFalse:
			[cogit MoveMw: 0 r: sourceReg R: destReg.
			 cogit MoveR: destReg R: scratchRegOrNone. "destReg := (at least) least significant half of self baseHeader: receiver"
			 cogit LogicalShiftRightCq: objectMemory formatShift R: destReg].
	cogit AndCq: objectMemory formatMask R: destReg.	"formatReg := self formatOfHeader: destReg"
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetNumSlotsOf: srcReg into: destReg [
	"Get the size in word-sized slots of the object in srcReg into destReg.
	 srcReg may equal destReg."
	<var: #jmp type: #'AbstractInstruction *'>
	| jmp |
	self assert: srcReg ~= destReg.
	self genGetRawSlotSizeOfNonImm: srcReg into: destReg.
	cogit CmpCq: objectMemory numSlotsMask R: destReg.
	jmp := cogit JumpLess: 0.
	self genGetOverflowSlotsOf: srcReg into: destReg.
	jmp jmpTarget: cogit Label.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetOverflowSlotsOf: srcReg into: destReg [
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetRawSlotSizeOfNonImm: sourceReg into: destReg [
	"The raw numSlots field is the most significant byte of the 64-bit header word.
	 MoveMbrR zero-extends."
	cogit backEnd byteReadsZeroExtend ifFalse:
		[cogit MoveCq: 0 R: destReg].
	cogit MoveMb: 7 r: sourceReg R: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genImmutableCheck: regHoldingObjectMutated slotIndex: index sourceReg: regHoldingValueToStore scratchReg: scratchReg popBoolean: popBoolean needRestoreRcvr: needRestoreRcvr [
	| mutableJump fail |
	<var: #mutableJump type: #'AbstractInstruction *'>
	<var: #fail type: #'AbstractInstruction *'>
	<inline: true>
	"Trampoline convention: 
	- objectMutated passed in RcvrResultReg
	- index (unboxed) passed in TempReg
	- valueToStore passed in Arg1Reg.
	Simulated stack is flushed until simulatedStackPointer - 1, which implies full flush 
	if popBoolean is true, else top value may not be flushed.
	We spill the top value (the value to store) for the trampoline if needed."
	self assert: regHoldingObjectMutated == ReceiverResultReg. 
	self assert: scratchReg == TempReg.
	self assert: regHoldingValueToStore == ClassReg.
	mutableJump := self genJumpMutable: ClassReg scratchReg: TempReg.
	
	"We reach this code if the object mutated is immutable."
	"simulatedStack state altered for the trampoline, spill top value if needed"
	(popBoolean or: [ cogit ssTop spilled ]) ifFalse:
		[ self assert: (cogit ssTop type = SSRegister and: [cogit ssTop register = ClassReg]).
		  cogit PushR: ClassReg ].
	"pass the unboxed index using TempReg"
	cogit MoveCq: index R: TempReg.
	"trampoline call and mcpc to bcpc annotation."
	cogit CallRT: ceCannotAssignToWithIndexTrampoline.
	cogit annotateBytecode: cogit Label.
	"Top of stack is consumed by the trampoline. In case of store with non spilled value, 
	restore ClassReg to match simulated stack state"
	(popBoolean or: [ cogit ssTop spilled ]) ifFalse:
		[cogit popR: ClassReg].
	"restore ReceiverResultReg state if needed"
	needRestoreRcvr ifTrue: [ self putSelfInReceiverResultReg ].
	fail := cogit Jump: 0.
	
	"We reach this code is the object mutated is mutable"
	mutableJump jmpTarget: cogit Label.
	
	^ fail
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genInnerPrimitiveAsCharacter: retNOffset inReg: reg [
	| jumpNotInt jumpOutOfRange |
	<var: 'jumpNotInt' type: #'AbstractInstruction *'>
	<var: 'jumpOutOfRange' type: #'AbstractInstruction *'>
	reg ~= ReceiverResultReg ifTrue:
		[jumpNotInt := self genJumpNotSmallInteger: reg scratch: TempReg].
	cogit MoveR: reg R: TempReg.
	self genConvertSmallIntegerToIntegerInReg: TempReg.
	cogit CmpCq: 1 << 30 - 1 R: TempReg.
	jumpOutOfRange := cogit JumpAbove: 0.
	self genConvertSmallIntegerToCharacterInReg: reg.
	reg ~= ReceiverResultReg ifTrue:
		[cogit MoveR: reg R: ReceiverResultReg].
	cogit RetN: retNOffset.
	jumpOutOfRange jmpTarget: cogit Label.
	reg ~= ReceiverResultReg ifTrue:
		[jumpNotInt jmpTarget: jumpOutOfRange getJmpTarget].
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genInnerPrimitiveCharacterValue: retNOffset [
	self genConvertCharacterToSmallIntegerInReg: ReceiverResultReg.
	cogit RetN: retNOffset.
	^UnfailingPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genInnerPrimitiveIdentical: retNoffset orNotIf: orNot [
	| jumpImmediate jumpCmp |
	<var: #jumpCmp type: #'AbstractInstruction *'>
	<var: #jumpImmediate type: #'AbstractInstruction *'>
	jumpImmediate := self genJumpImmediate: Arg0Reg.
	self genEnsureObjInRegNotForwarded: Arg0Reg scratchReg: TempReg.
	jumpImmediate jmpTarget:
		(cogit CmpR: Arg0Reg R: ReceiverResultReg).
	jumpCmp := orNot
					ifTrue: [cogit JumpZero: 0]
					ifFalse: [cogit JumpNonZero: 0].
	cogit genMoveTrueR: ReceiverResultReg.
	cogit RetN: retNoffset.
	jumpCmp jmpTarget: (cogit genMoveFalseR: ReceiverResultReg).
	cogit RetN: retNoffset.
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genInnerPrimitiveIdentityHash: retNoffset [
	self subclassResponsibility
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genInnerPrimitiveNew: retNoffset [
	"Implement primitiveNew for convenient cases:
	- the receiver has a hash
	- the receiver is fixed size (excluding ephemerons to save instructions & miniscule time)
	- single word header/num slots < numSlotsMask
	- the result fits in eden"

	self subclassResponsibility
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genInnerPrimitiveNewWithArg: retNoffset [
	"Implement primitiveNewWithArg for convenient cases:
	- the receiver has a hash
	- the receiver is variable and not compiled method
	- single word header/num slots < numSlotsMask
	- the result fits in eden

	Here are some dynamic frequencies of class formats in the interpreter doing startUp
	and recompiling ArrayedCollection in a Squeak4.1 image:
		{3251->#arrayFormat.		(Array)
		 1685->#firstByteFormat.	(ByteString, LargePositiveInteger, very few ByteArray)
		 1533->#firstLongFormat.	(Bitmaps, Floats, MatrixTransform2x3, WordArray)
		 110->#weakArrayFormat.	(WeakArray, WeakMessageSend)
		 35->#indexablePointersFormat.	(MethodContext)
		 5->#nonIndexablePointerFormat	(DirectoryEntry)}"

	self subclassResponsibility
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genInnerPrimitiveObjectAt: retNOffset [
	| headerReg
	  jumpBadIndex jumpNotCogMethod jumpBounds jumpNotHeaderIndex |
	<var: #jumpBounds type: #'AbstractInstruction *'>
	<var: #jumpBadIndex type: #'AbstractInstruction *'>
	<var: #jumpNotCogMethod type: #'AbstractInstruction *'>
	<var: #jumpNotHeaderIndex type: #'AbstractInstruction *'>
	jumpBadIndex := self genJumpNotSmallInteger: Arg0Reg scratch: TempReg.
	"get header into Arg1Reg..."
	cogit MoveMw: objectMemory baseHeaderSize r: ReceiverResultReg R: (headerReg := Arg1Reg).
	jumpNotCogMethod := self genJumpSmallInteger: headerReg scratch: TempReg.
	cogit MoveMw: (cogit offset: CogMethod of: #methodHeader) r: headerReg R: headerReg.
	jumpNotCogMethod jmpTarget: (cogit
		CmpCq: (objectMemory integerObjectOf: 1) R: Arg0Reg).
	jumpNotHeaderIndex := cogit JumpNonZero: 0.
	cogit
		MoveR: headerReg R: ReceiverResultReg;
		RetN: retNOffset.
	jumpNotHeaderIndex jmpTarget: (cogit
		AndCq: (objectMemory integerObjectOf: coInterpreter alternateHeaderNumLiteralsMask) R: headerReg).
	cogit
		SubCq: (objectMemory integerObjectOf: 1) - objectMemory smallIntegerTag R: Arg0Reg;
		CmpR: headerReg R: Arg0Reg.
	jumpBounds := cogit JumpAbove: 0.

	self genConvertSmallIntegerToIntegerInReg: Arg0Reg.
	cogit
		AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg0Reg;
		MoveXwr: Arg0Reg R: ReceiverResultReg R: ReceiverResultReg;
		RetN: retNOffset.

	jumpBounds jmpTarget: (cogit
		AddCq: (objectMemory integerObjectOf: 1) - objectMemory smallIntegerTag R: Arg0Reg).
	jumpBadIndex jmpTarget: cogit Label.
	^CompletePrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genInnerPrimitiveSize: retNoffset [
	| jumpImm jumpNotIndexable jumpIsContext |
	"c.f. StackInterpreter>>stSizeOf: lengthOf:baseHeader:format: fixedFieldsOf:format:length:"
	<var: #jumpImm type: #'AbstractInstruction *'>
	<var: #jumpIsContext type: #'AbstractInstruction *'>
	<var: #jumpNotIndexable type: #'AbstractInstruction *'>
	jumpImm := self genJumpImmediate: ReceiverResultReg.
	self
		genGetSizeOf: ReceiverResultReg
		into: ClassReg
		formatReg: SendNumArgsReg
		scratchReg: TempReg
		abortJumpsInto: [:jnx :jic| jumpNotIndexable := jnx. jumpIsContext := jic].
	self genConvertIntegerToSmallIntegerInReg: ClassReg.
	cogit MoveR: ClassReg R: ReceiverResultReg.
	cogit RetN: retNoffset.
	jumpImm jmpTarget: (jumpNotIndexable jmpTarget: (jumpIsContext jmpTarget: cogit Label)).
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genInnerPrimitiveStringAt: retNoffset [
	"Implement the guts of primitiveStringAt; dispatch on size"
	| formatReg jumpNotIndexable jumpBadIndex done
	  jumpIsBytes jumpIsShorts jumpIsWords jumpWordTooBig
	  jumpBytesOutOfBounds jumpShortsOutOfBounds jumpWordsOutOfBounds |
	<inline: true>
	"c.f. StackInterpreter>>stSizeOf: SpurMemoryManager>>lengthOf:format: fixedFieldsOf:format:length:"
	<var: #done type: #'AbstractInstruction *'>
	<var: #jumpIsBytes type: #'AbstractInstruction *'>
	<var: #jumpIsShorts type: #'AbstractInstruction *'>
	<var: #jumpIsWords type: #'AbstractInstruction *'>
	<var: #jumpBadIndex type: #'AbstractInstruction *'>
	<var: #jumpWordTooBig type: #'AbstractInstruction *'>
	<var: #jumpNotIndexable type: #'AbstractInstruction *'>
	<var: #jumpBytesOutOfBounds type: #'AbstractInstruction *'>
	<var: #jumpShortsOutOfBounds type: #'AbstractInstruction *'>
	<var: #jumpWordsOutOfBounds type: #'AbstractInstruction *'>

	cogit MoveR: Arg0Reg R: Arg1Reg.
	jumpBadIndex := self genJumpNotSmallInteger: Arg0Reg scratch: TempReg.
	self genConvertSmallIntegerToIntegerInReg: Arg1Reg.
	cogit SubCq: 1 R: Arg1Reg. "1-rel => 0-rel"

	self genGetFormatOf: ReceiverResultReg
		into: (formatReg := SendNumArgsReg)
		leastSignificantHalfOfBaseHeaderIntoScratch: NoReg.

	self genGetNumSlotsOf: ReceiverResultReg into: ClassReg.

	"dispatch on format in a combination of highest dynamic frequency order first and convenience.
		  0 = 0 sized objects (UndefinedObject True False et al)
		  1 = non-indexable objects with inst vars (Point et al)
		  2 = indexable objects with no inst vars (Array et al)
		  3 = indexable objects with inst vars (MethodContext AdditionalMethodState et al)
		  4 = weak indexable objects with inst vars (WeakArray et al)
		  5 = weak non-indexable objects with inst vars (ephemerons) (Ephemeron)
		  6 unused, reserved for exotic pointer objects?
		  7 Forwarded Object, 1st field is pointer, rest of fields are ignored
		  8 unused, reserved for exotic non-pointer objects?
		  9 (?) 64-bit indexable
		10 - 11 32-bit indexable
		12 - 15 16-bit indexable
		16 - 23 byte indexable
		24 - 31 compiled method"
	cogit CmpCq: objectMemory firstByteFormat R: formatReg.
	jumpIsBytes := cogit JumpGreaterOrEqual: 0.
					cogit CmpCq: objectMemory firstShortFormat R: formatReg.
	jumpIsShorts := cogit JumpGreaterOrEqual: 0.
					cogit CmpCq: objectMemory firstLongFormat R: formatReg.
	jumpIsWords := cogit JumpGreaterOrEqual: 0.
	jumpNotIndexable := cogit Jump: 0.

	jumpIsBytes jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord R: ClassReg).
		cogit AndCq: objectMemory wordSize - 1 R: formatReg.
		cogit SubR: formatReg R: ClassReg;
		CmpR: Arg1Reg R: ClassReg.
	jumpBytesOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddCq: objectMemory baseHeaderSize R: Arg1Reg.
	cogit MoveXbr: Arg1Reg R: ReceiverResultReg R: ReceiverResultReg.
	cogit backEnd byteReadsZeroExtend ifFalse:
			[cogit AndCq: 255 R: ReceiverResultReg].
	done := cogit Label.
	self genConvertIntegerToCharacterInReg: ReceiverResultReg.
	cogit RetN: retNoffset.

	jumpIsShorts jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord - 1 R: ClassReg).
		cogit AndCq: 1 R: formatReg.
		cogit SubR: formatReg R: ClassReg;
		CmpR: Arg1Reg R: ClassReg.
	jumpShortsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddR: Arg1Reg R: ReceiverResultReg.
	cogit MoveM16: objectMemory baseHeaderSize r: ReceiverResultReg R: ReceiverResultReg.
	cogit Jump: done.

	jumpIsWords jmpTarget:
		(cogit CmpR: Arg1Reg R: ClassReg).
	jumpWordsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg1Reg.
	cogit MoveXwr: Arg1Reg R: ReceiverResultReg R: TempReg.
	cogit SubCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg1Reg.
	jumpWordTooBig := self jumpNotCharacterUnsignedValueInRegister: TempReg.
	cogit MoveR: TempReg R: ReceiverResultReg.
	cogit Jump: done.

	jumpBytesOutOfBounds jmpTarget:
	(jumpShortsOutOfBounds jmpTarget:
	(jumpWordsOutOfBounds jmpTarget:
	(jumpWordTooBig jmpTarget:
	(jumpNotIndexable jmpTarget: 
	(jumpBadIndex jmpTarget: cogit Label))))).

	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpBaseHeaderImmutable: baseHeaderReg [
	"baseHeader holds at least the least significant 32 bits of the object"
	<returnTypeC: #'AbstractInstruction *'>
	cogit TstCq: objectMemory immutableBitMask R: baseHeaderReg.
	^ cogit JumpNonZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpBaseHeaderMutable: baseHeaderReg [
	"baseHeader holds at least the least significant 32 bits of the object"
	<returnTypeC: #'AbstractInstruction *'>
	cogit TstCq: objectMemory immutableBitMask R: baseHeaderReg.
	^ cogit JumpZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpCharacterInScratchReg: reg [ 
	cogit AndCq: objectMemory tagMask R: reg.
	cogit CmpCq: objectMemory characterTag R: reg.
	^cogit JumpZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpImmediate: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit TstCq: objectMemory tagMask R: aRegister.
	^cogit JumpNonZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpImmediateInScratchReg: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit AndCq: objectMemory tagMask R: aRegister.
	^cogit JumpNonZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpImmutable: sourceReg scratchReg: scratchReg [
	<returnTypeC: #'AbstractInstruction *'>
	cogit MoveMw: 0 r: sourceReg R: scratchReg. 
	^ self genJumpBaseHeaderImmutable: scratchReg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpMutable: sourceReg scratchReg: scratchReg [
	<returnTypeC: #'AbstractInstruction *'>
	cogit MoveMw: 0 r: sourceReg R: scratchReg. 
	^ self genJumpBaseHeaderMutable: scratchReg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpNotCharacterInScratchReg: reg [ 
	cogit AndCq: objectMemory tagMask R: reg.
	cogit CmpCq: objectMemory characterTag R: reg.
	^cogit JumpNonZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpNotImmediate: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit TstCq: objectMemory tagMask R: aRegister.
	^cogit JumpZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpNotImmediateInScratchReg: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit AndCq: objectMemory tagMask R: aRegister.
	^cogit JumpZero: 0
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationForSpur >> genNewArrayOfSize: size initialized: initialized [
	"Generate a call to code that allocates a new Array of size.
	 The Array should be initialized with nils iff initialized is true.
	 The size arg is passed in SendNumArgsReg, the result
	 must come back in ReceiverResultReg."
	| header skip |
	<var: #skip type: #'AbstractInstruction *'>
	self assert: size < objectMemory numSlotsMask.
	header := objectMemory
					headerForSlots: size
					format: objectMemory arrayFormat
					classIndex: ClassArrayCompactIndex.
	cogit MoveAw: objectMemory freeStartAddress R: ReceiverResultReg.
	self genStoreHeader: header intoNewInstance: ReceiverResultReg using: TempReg.
	(initialized and: [size > 0]) ifTrue:
		[cogit genMoveConstant: objectMemory nilObject R: TempReg.
		 0 to: size - 1 do:
			[:i| cogit MoveR: TempReg
					Mw: i * objectMemory wordSize + objectMemory baseHeaderSize
					r: ReceiverResultReg]].
	cogit
		LoadEffectiveAddressMw: (objectMemory smallObjectBytesForSlots: size) r: ReceiverResultReg R: TempReg;
		MoveR: TempReg Aw: objectMemory freeStartAddress;
		CmpCq: objectMemory getScavengeThreshold R: TempReg.
	skip := cogit JumpBelow: 0.
	cogit CallRT: ceScheduleScavengeTrampoline.
	skip jmpTarget: cogit Label.
	^0
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationForSpur >> genNoPopCreateClosureAt: bcpc numArgs: numArgs numCopied: numCopied contextNumArgs: ctxtNumArgs large: isLargeCtxt inBlock: isInBlock [
	"Create a closure with the given startpc, numArgs and numCopied
	 within a context with ctxtNumArgs, large if isLargeCtxt that is in a
	 block if isInBlock.  Do /not/ initialize the copied values."
	| numSlots byteSize header skip |
	<var: #skip type: #'AbstractInstruction *'>

	"First get thisContext into ReceiverResultRega and thence in ClassReg."
	self genGetActiveContextNumArgs: ctxtNumArgs large: isLargeCtxt inBlock: isInBlock.
	cogit MoveR: ReceiverResultReg R: ClassReg.

	numSlots := ClosureFirstCopiedValueIndex + numCopied.
	byteSize := objectMemory smallObjectBytesForSlots: numSlots.
	header := objectMemory
					headerForSlots: numSlots
					format: objectMemory indexablePointersFormat
					classIndex: ClassBlockClosureCompactIndex.
	cogit MoveAw: objectMemory freeStartAddress R: ReceiverResultReg.
	self genStoreHeader: header intoNewInstance: ReceiverResultReg using: TempReg.
	cogit
		LoadEffectiveAddressMw: byteSize r: ReceiverResultReg R: TempReg;
		MoveR: TempReg Aw: objectMemory freeStartAddress;
		CmpCq: objectMemory getScavengeThreshold R: TempReg.
	skip := cogit JumpBelow: 0.
	cogit CallRT: ceScheduleScavengeTrampoline.
	skip jmpTarget: cogit Label.

	cogit
		MoveR: ClassReg Mw: ClosureOuterContextIndex * objectMemory bytesPerOop + objectMemory baseHeaderSize r: ReceiverResultReg;
		MoveCq: (objectMemory integerObjectOf: bcpc) R: TempReg;
		MoveR: TempReg Mw: ClosureStartPCIndex * objectMemory bytesPerOop + objectMemory baseHeaderSize r: ReceiverResultReg;
		MoveCq: (objectMemory integerObjectOf: numArgs) R: TempReg;
		MoveR: TempReg Mw: ClosureNumArgsIndex * objectMemory bytesPerOop + objectMemory baseHeaderSize r: ReceiverResultReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genRemoveCharacterTagsInScratchReg: scratchReg [
	cogit SubCq: objectMemory characterTag R: scratchReg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genRemoveSmallIntegerTagsInScratchReg: scratchReg [
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genSetCharacterTagsIn: reg [
	cogit OrCq: objectMemory characterTag R: reg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genSetSmallIntegerTagsIn: scratchReg [
	cogit OrCq: 1 R: scratchReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genSpecialSelectorEqualsEqualsGuts [
	< inline: true >
	^ cogit genSpecialSelectorEqualsEqualsWithForwarders
]

{ #category : #initialization }
CogObjectRepresentationForSpur >> genStoreCheckContextReceiverTrampoline [
	"Create a trampoline to store-check the update of the receiver in a closure's
	 outerContext in compileBlockFrameBuild:."
	| startAddress |
	startAddress := cogit methodZoneBase.
	cogit zeroOpcodeIndex.
	self genStoreCheckReceiverReg: ReceiverResultReg valueReg: Arg0Reg scratchReg: TempReg inFrame: false.
	cogit RetN: 0.
	cogit outputInstructionsForGeneratedRuntimeAt: startAddress.
	cogit recordGeneratedRunTime: 'ceStoreCheckContextReceiver' address: startAddress.
	cogit recordRunTimeObjectReferences.
	^startAddress
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genStoreCheckReceiverReg: destReg valueReg: valueReg scratchReg: scratchReg inFrame: inFrame [
	"Generate the code for a store check of valueReg into destReg."
	| jmpImmediate jmpDestYoung jmpSourceOld jmpAlreadyRemembered mask rememberedBitByteOffset |
	<var: #jmpImmediate type: #'AbstractInstruction *'>
	<var: #jmpDestYoung type: #'AbstractInstruction *'>
	<var: #jmpSourceOld type: #'AbstractInstruction *'>
	<var: #jmpAlreadyRemembered type: #'AbstractInstruction *'>
	"Is value stored an integer?  If so we're done"
	cogit MoveR: valueReg R: scratchReg.
	cogit AndCq: objectMemory tagMask R: scratchReg.
	jmpImmediate := cogit JumpNonZero: 0.
	"Get the old/new boundary in scratchReg"
	cogit MoveCw: objectMemory storeCheckBoundary R: scratchReg.
	"Is target young?  If so we're done"
	cogit CmpR: scratchReg R: destReg. "N.B. FLAGS := destReg - scratchReg"
	jmpDestYoung := cogit JumpBelow: 0.
	"Is value stored old?  If so we're done."
	cogit CmpR: scratchReg R: valueReg. "N.B. FLAGS := valueReg - scratchReg"
	jmpSourceOld := cogit JumpAboveOrEqual: 0.
	"value is young and target is old.
	 Need to remember this only if the remembered bit is not already set.
	 Test the remembered bit.  Only need to fetch the byte containing it,
	 which reduces the size of the mask constant."
	rememberedBitByteOffset := jmpSourceOld isBigEndian
									ifTrue: [objectMemory baseHeaderSize - 1 - (objectMemory rememberedBitShift // 8)]
									ifFalse:[objectMemory rememberedBitShift // 8].
	mask := 1 << (objectMemory rememberedBitShift \\ 8).
	cogit MoveMb: rememberedBitByteOffset r: destReg R: scratchReg.
	cogit AndCq: mask R: scratchReg.
	jmpAlreadyRemembered := cogit JumpNonZero: 0.
	"Remembered bit is not set.  Call store check to insert dest into remembered table."
	self assert: destReg == ReceiverResultReg.
	cogit 
		evaluateTrampolineCallBlock:
			[cogit
				CallRT: ceStoreCheckTrampoline
				registersToBeSavedMask: (((cogit registerMaskFor: valueReg)
												bitOr: cogit callerSavedRegMask)
												bitClear: (cogit registerMaskFor: ReceiverResultReg))]
		protectLinkRegIfNot: inFrame.
	jmpImmediate jmpTarget:
	(jmpDestYoung jmpTarget:
	(jmpSourceOld jmpTarget:
	(jmpAlreadyRemembered jmpTarget:
		cogit Label))).
	^0
]

{ #category : #initialization }
CogObjectRepresentationForSpur >> genStoreHeader: header intoNewInstance: rcvrReg using: scratchReg [
	"Generate the instructions to move the constant header into a new instance pointed to by rcvrReg."
	<inline: true>
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genStoreSourceReg: sourceReg slotIndex: index destReg: destReg scratchReg: scratchReg inFrame: inFrame needsStoreCheck: needsStoreCheck [
	"do the store"
	cogit MoveR: sourceReg
		   Mw: index * objectMemory wordSize + objectMemory baseHeaderSize
		   r: destReg.
	"now the check. needStoreCheck is false if the JIT has figured out that the value stored does not need the check (immediate, nil, true, false)"
	needsStoreCheck ifTrue: 
		[ ^ self 
			genStoreCheckReceiverReg: destReg 
			valueReg: sourceReg 
			scratchReg: scratchReg 
			inFrame: inFrame ].
	^ 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genStoreSourceReg: sourceReg slotIndex: index intoNewObjectInDestReg: destReg [
	"This method is used for unchecked stores in objects after their creation (typically, inlined creation of Array, closures and some temp vectors). 
	Currently there is no need to do the immutability check here"
	cogit MoveR: sourceReg
		   Mw: index * objectMemory wordSize + objectMemory baseHeaderSize
		   r: destReg.
	^0
]

{ #category : #initialization }
CogObjectRepresentationForSpur >> generateObjectRepresentationTrampolines [
	"Do the store check.  Answer the argument for the benefit of the code generator;
	 ReceiverResultReg may be caller-saved and hence smashed by this call.  Answering
	 it allows the code generator to reload ReceiverResultReg cheaply.
	 In Spur the only thing we leave to the run-time is adding the receiver to the
	 remembered set and setting its isRemembered bit."
	self 
		cppIf: IMMUTABILITY
		ifTrue: 
			[ "Arg1Reg is used as resultReg because cogit needs to restore the valueToStore
			in the reg expected. The reg for the valueToStore is dynamically allocated, but 
			in most case, in the non-sista VM, it ends up being Arg1Reg."
			  ceCannotAssignToWithIndexTrampoline := cogit
									genTrampolineFor: #ceCannotAssignTo:withIndex:valueToAssign:
									called: 'ceCannotAssignToWithIndexTrampoline'
									arg: ReceiverResultReg 
									arg: TempReg
									arg: ClassReg ].
	ceStoreCheckTrampoline := cogit
									genTrampolineFor: #remember:
									called: 'ceStoreCheckTrampoline'
									arg: ReceiverResultReg
									result: cogit returnRegForStoreCheck.
	ceStoreCheckContextReceiverTrampoline := self genStoreCheckContextReceiverTrampoline.
	ceScheduleScavengeTrampoline := cogit
											genSafeTrampolineFor: #ceScheduleScavenge
											called: 'ceScheduleScavengeTrampoline'.
	ceSmallActiveContextInMethodTrampoline := self genActiveContextTrampolineLarge: false inBlock: false called: 'ceSmallMethodContext'.
	ceSmallActiveContextInBlockTrampoline := self genActiveContextTrampolineLarge: false inBlock: true called: 'ceSmallBlockContext'.
	ceLargeActiveContextInMethodTrampoline := self genActiveContextTrampolineLarge: true inBlock: false called: 'ceLargeMethodContext'.
	ceLargeActiveContextInBlockTrampoline := self genActiveContextTrampolineLarge: true inBlock: true called: 'ceLargeBlockContext'
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationForSpur >> getActiveContextAllocatesInMachineCode [
	"Make sure SendNumArgsReg and ClassReg are available in addition to
	 ReceiverResultReg and TempReg in genGetActiveContextNumArgs:large:inBlock:."
	^true
]

{ #category : #testing }
CogObjectRepresentationForSpur >> hasSpurMemoryManagerAPI [
	^true
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> hasValidHeaderPostGC: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	^cogMethod objectHeader = objectMemory nullHeaderForMachineCodeMethod
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> inlineCacheTagIsYoung: cacheTag [
	"Since all cache tags in Spur are class indices none of
	 them are young or have to be updated in a scavenge."
	^false
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationForSpur >> inlineCacheTagsMayBeObjects [
	<inline: true>
	^false
]

{ #category : #'object representation' }
CogObjectRepresentationForSpur >> isSmallIntegerTagNonZero [
	^true
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> jumpNotCharacterUnsignedValueInRegister: reg [
	cogit CmpCq: 16r3FFFFFFF R: reg.
	^cogit JumpAbove: 0
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> markAndTraceLiteral: literal [
	(self couldBeObject: literal) ifTrue:
		[self assert: (objectMemory addressCouldBeObj: literal).
		 objectMemory markAndTrace: literal]
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> markAndTraceLiteral: literal in: cogMethod at: address [
	"Mark and trace a literal in a sqInt variable of cogMethod."
	<var: #cogMethod type: #'CogMethod *'>
	<var: #address type: #'sqInt *'>
	| objOop |
	(self couldBeObject: literal) ifFalse:
		[^self].
	self assert: (objectMemory addressCouldBeObj: literal).
	(objectMemory isForwarded: literal) ifFalse:
		[objectMemory markAndTrace: literal.
		 ^self].
	objOop := objectMemory followForwarded: literal.
	address at: 0 put: objOop.
	self markAndTraceUpdatedLiteral: objOop in: cogMethod
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> markAndTraceLiteral: literal in: cogMethodOrNil atpc: address [
	"Mark and trace a literal in a machine code instruction preceding address in cogMethodOrNil.
	 Answer if code was modified."
	<var: #cogMethodOrNil type: #'CogMethod *'>
	<var: #address type: #usqInt>
	| objOop |
	(self couldBeObject: literal) ifFalse:
		[^false].
	self assert: (objectMemory addressCouldBeObj: literal).
	(objectMemory isForwarded: literal) ifFalse:
		[objectMemory markAndTrace: literal.
		 ^false].
	objOop := objectMemory followForwarded: literal.
	cogit backEnd storeLiteral: objOop beforeFollowingAddress: address.
	self markAndTraceUpdatedLiteral: objOop in: cogMethodOrNil.
	^true
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> markAndTraceLiteralIfYoung: literal [
	((self couldBeObject: literal)
	 and: [objectMemory isYoungObject: literal]) ifTrue:
		[self assert: (objectMemory addressCouldBeObj: literal).
		 objectMemory markAndTrace: literal]
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> markAndTraceUpdatedLiteral: objOop in: cogMethodOrNil [
	"Common code to mark a literal in cogMethod and add
	 the cogMethod to youngReferrers if the literal is young."
	<var: #cogMethodOrNil type: #'CogMethod *'>
	(objectMemory isNonImmediate: objOop) ifTrue:
		[(cogMethodOrNil notNil
		  and: [objectMemory isYoungObject: objOop]) ifTrue:
			[methodZone ensureInYoungReferrers: cogMethodOrNil].
		 objectMemory markAndTrace: objOop]
]

{ #category : #'newspeak support' }
CogObjectRepresentationForSpur >> markIfIRC: maybeIRCs [
	"If maybeIRCs (from some cogMehtod's nextMethodOrIRCs) is in old space it is
	 a pointer to the first field of a pinned object in old space holding the implicit
	 receiver caches for a method.  If so, map it back to an oop and mark it."
	<var: #maybeIRCs type: #usqInt>
	<option: #NewspeakVM>
	(self oop: maybeIRCs isGreaterThan: objectMemory nilObject) ifTrue:
		[objectMemory markAndTrace: maybeIRCs - objectMemory baseHeaderSize]
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> maybeCompileRetry: retryInst onPrimitiveFail: primIndex [
	<var: #retryInst type: #'AbstractInstruction *'>
	"If primIndex has an accessorDepth, check for primitive failure and call
	 ceCheckForAndFollowForwardedPrimitiveState if so  If ceCheck.... answers
	 true, retry the primitive."
	| jmp |
	<var: #jmp type: #'AbstractInstruction *'>
	(coInterpreter accessorDepthForPrimitiveIndex: primIndex) < 0 ifTrue:
		[^0].
	cogit MoveAw: coInterpreter primFailCodeAddress R: TempReg.
	cogit CmpCq: 0 R: TempReg.
	jmp := cogit JumpZero: 0.
	cogit
		compileCallFor: #ceCheckForAndFollowForwardedPrimitiveState
		numArgs: 0
		arg: nil
		arg: nil
		arg: nil
		arg: nil
		resultReg: TempReg
		saveRegs: false.
	cogit CmpCq: 0 R: TempReg.
	cogit JumpNonZero: retryInst.
	jmp jmpTarget: cogit Label.
	^0
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> maybeMarkCounters: theCounters [
	"In SIsta Spur counters are held on the heap in pinned objects which must be marked
	 to avoid them being garbage collected.  This is the hook through which that happens."
	<var: #theCounters type: #usqInt>
	<option: #SistaStackToRegisterMappingCogit>
	<inline: true>
	theCounters ~= 0 ifTrue:
		[objectMemory markAndTrace: theCounters - objectMemory baseHeaderSize]
]

{ #category : #compilation }
CogObjectRepresentationForSpur >> maybeNoteDescriptor: descriptor blockStart: blockStart [
	"Override to note inst var refs in blocks.  Used to avoid checking
	 for forwarded receivers in blocks that don't refer to inst vars."
	<var: #blockStart type: #'BlockStart *'>
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<inline: true>
	descriptor isInstVarRef ifTrue:
		[blockStart hasInstVarRef: true]
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> mixed: numNonImmediates branchIf: reg notInstanceOfBehaviors: arrayObj target: targetFixUp [
	| jmpImmediate jumps label numCases classObj index |
	<var: #label type: #'AbstractInstruction *'>
	<var: #jmpImmediate type: #'AbstractInstruction *'>
	<var: #jumps type: #'AbstractInstruction **'>
	<var: #targetFixUp type: #'AbstractInstruction *'>
	numCases := objectMemory numSlotsOf: arrayObj.
	jmpImmediate := self genJumpImmediate: reg.
	
	"Rcvr is non immediate"
	jumps := self alloca: numNonImmediates type: (self cCode: [#'AbstractInstruction *'] inSmalltalk: [cogit backEnd class]).
	self genGetClassIndexOfNonImm: reg into: TempReg.
	index := 0.
	0 to: numCases - 1 do:
		[:i|
			classObj := objectMemory fetchPointer: i ofObject: arrayObj.
			(objectMemory isImmediateClass: classObj) ifFalse: [
				self genCmpClassIndex: (objectMemory classTagForClass: classObj) R: TempReg.
				jumps at: index put: (cogit JumpZero: 0).
				index := index + 1 ] ].
	cogit Jump: targetFixUp.
	
	"Rcvr is immediate"
	jmpImmediate jmpTarget: cogit Label.
	numCases - numNonImmediates "num Immediates allowed"
		caseOf:
		{[ 1 ] -> [ "1 immediate allowed. jump to targetFixUp if the rcvr is not this immediate"
			0 to: numCases - 1 do:
				[ :j |
				classObj := objectMemory fetchPointer: j ofObject: arrayObj.
				(objectMemory isImmediateClass: classObj) ifTrue: [
					self branchIf: reg hasNotImmediateTag: (objectMemory classTagForClass: classObj) target: targetFixUp ] ] ] .
		[ 2 ] -> [ "2 immediates allowed. On 32 bits nothing to do, all immediate are allowed, on 64 bits generates the jump to fixup for the third tag"
				self branch2CasesIf: reg notInstanceOfBehaviors: arrayObj target: targetFixUp ] .
		[ 3 ] -> [ "nothing to do, all immediates are allowed." ] }.
	
	label := self Label.
	0 to: numNonImmediates - 1 do: [:i |
		(jumps at: i) jmpTarget: label ].
	
	^ 0
		
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> noneImmediateBranchIf: reg notInstanceOfBehaviors: arrayObj target: targetFixUp [
	"All classes in arrayObj are not immediate"
	| label numJumps jumps classObj |
	<var: #targetFixUp type: #'AbstractInstruction *'>
	<var: #label type: #'AbstractInstruction *'>
	<var: #jumps type: #'AbstractInstruction **'>
	jumps := self alloca: (objectMemory numSlotsOf: arrayObj) type: (self cCode: [#'AbstractInstruction *'] inSmalltalk: [cogit backEnd class]).
	(self genJumpImmediate: reg) jmpTarget: targetFixUp.
	self genGetClassIndexOfNonImm: reg into: TempReg.
	0 to: (numJumps := objectMemory numSlotsOf: arrayObj) - 1 do:
		[:i|
		 classObj := objectMemory fetchPointer: i ofObject: arrayObj.
		 self genCmpClassIndex: (objectMemory classTagForClass: classObj) R: TempReg.
		jumps at: i put: (cogit JumpZero: 0) ].
	cogit Jump: targetFixUp.
	label := self Label.
	0 to: numJumps - 1 do: [:i |
		(jumps at: i) jmpTarget: label ].
	^0
]

{ #category : #'calling convention' }
CogObjectRepresentationForSpur >> numRegArgs [
	"Define how many register arguments a StackToRegisterMappingCogit can
	 and should use with the receiver.  The value must be 0, 1 or 2.  Note that a
	 SimpleStackBasedCogit always has 0 register args (although the receiver is
	 passed in a register).  The Spur object representation is simple enough that
	 implementing at:put: is straight-forward and hence 2 register args are worth
	 while.  The method must be inlined in CoInterpreter, and dead code eliminated
	 so that the register-popping enilopmarts such as enterRegisterArgCogMethod:-
	 at:receiver: do not have to be implemented in SimpleStackBasedCogit."
	<api>
	<option: #StackToRegisterMappingCogit>
	<inline: true>
	^2
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> remapObject: objOop [
	^(objectMemory shouldRemapObj: objOop)
		ifTrue: [objectMemory remapObj: objOop]
		ifFalse: [objOop]
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> remapOop: objOop [
	^(objectMemory shouldRemapOop: objOop)
		ifTrue: [objectMemory remapObj: objOop]
		ifFalse: [objOop]
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> resetCountersIn: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	<api>
	<option: #SistaStackToRegisterMappingCogit>
	cogit fillInCounters: (self numCountersFor: cogMethod counters) atStartAddress: cogMethod counters
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> shouldAnnotateObjectReference: anOop [
	"Objects in newSpace or oldSpace except nil, true, false & classTableRootObj need to be annotated."
	^(objectMemory isNonImmediate: anOop)
	  and: [(self oop: anOop isGreaterThan: objectMemory classTableRootObj)
		or: [self oop: anOop isLessThan: objectMemory nilObject]]
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> slotOffsetOfInstVarIndex: index [
	^index * objectMemory wordSize + objectMemory baseHeaderSize
]

{ #category : #testing }
CogObjectRepresentationForSpur >> smallIntegerIsOnlyImmediateType [
	^false
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> valueOfAssociation: associationOop [
	| association |
	association := associationOop.
	(objectMemory isForwarded: association) ifTrue:
		[association := objectMemory followForwarded: association].
	^objectMemory fetchPointer: ValueIndex ofObject: association
]
