Class {
	#name : #CogObjectRepresentationFor32BitSpur,
	#superclass : #CogObjectRepresentationForSpur,
	#category : #'VMMaker-JIT'
}

{ #category : #'accessing class hierarchy' }
CogObjectRepresentationFor32BitSpur class >> defaultObjectMemoryClass [
	"For in-image compilation."
	^Spur32BitCoMemoryManager
]

{ #category : #'sista support' }
CogObjectRepresentationFor32BitSpur >> allocateCounters: nCounters [
	"On Spur allocate the counters on the heap as pinned objects.
	 Each counter occupies 32-bits.  The number of counters can
	 be derived from the number of slots in the obj."
	<inline: true>
	| objOop |
	objOop := objectMemory allocatePinnedSlots: nCounters.
	^objOop
		ifNil: [0]
		ifNotNil: [objOop + objectMemory baseHeaderSize]
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationFor32BitSpur >> branchIfInstanceOfBehavior: classObj branches: branches [
	"Generate a branch if ReceiverResultReg is an instance of classObj, otherwise fall-
	 through. Store the branch in branches and answer the number of branches generated."
	<var: #branches type: #'AbstractInstruction **'>
	| jmpImmediate classIndex |
	<var: #jmpImmediate type: #'AbstractInstruction *'>
	classIndex := objectMemory classTagForClass: classObj.
	cogit MoveR: ReceiverResultReg R: TempReg.
	(objectMemory isImmediateClass: classObj)
		ifTrue:
			[classIndex = objectMemory smallIntegerTag ifTrue:
				[jmpImmediate := self genJumpSmallIntegerInScratchReg: TempReg].
			 classIndex = objectMemory characterTag ifTrue:
				[jmpImmediate := self genJumpCharacterInScratchReg: TempReg].
			 branches at: 0 put: jmpImmediate]
		ifFalse:
			[jmpImmediate := self genJumpImmediateInScratchReg: TempReg.
			 self genGetClassIndexOfNonImm: ReceiverResultReg into: TempReg.
			 self genCmpClassIndex: classIndex R: TempReg.
			 branches at: 0 put: (cogit JumpZero: 0).
			 jmpImmediate jmpTarget: cogit Label].
	^1
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationFor32BitSpur >> branchIfInstanceOfBehaviors: arrayObj branches: branches [
	"Generate a branch if ReceiverResultReg is an instance of any of the classes in arrayObj,
	 otherwise fall-through. Store the branch in branches and answer the number of branches
	 generated."
	<var: #branches type: #'AbstractInstruction **'>
	| allImmediate noneImmediate immediateMask numNonImmediates classObj jmpNoMatch jmpImmediate branchIndex classIndex |
	<var: #jmpNoMatch type: #'AbstractInstruction *'>
	<var: #jmpImmediate type: #'AbstractInstruction *'>
	branchIndex := 0.
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

	noneImmediate ifTrue:
		[cogit MoveR: ReceiverResultReg R: TempReg.
		 jmpImmediate := self genJumpImmediateInScratchReg: TempReg.
		 self genGetCompactClassIndexNonImmOf: ReceiverResultReg into: TempReg.
		 0 to: (objectMemory numSlotsOf: arrayObj) - 1 do:
			[:i|
			 classObj := objectMemory fetchPointer: i ofObject: arrayObj.
			 self genCmpClassIndex: (objectMemory classTagForClass: classObj) R: TempReg.
			 branches at: branchIndex put: (cogit JumpZero: 0).
			 branchIndex := branchIndex + 1].
		 jmpImmediate jmpTarget: cogit Label].

	allImmediate ifTrue:
		[immediateMask = objectMemory tagMask
			ifTrue:
				[jmpImmediate := self genJumpImmediateInScratchReg: TempReg.
				 branches at: branchIndex put: jmpImmediate.
				 branchIndex := branchIndex + 1]
			ifFalse:
				[0 to: (objectMemory numSlotsOf: arrayObj) - 1 do:
					[:i|
					 cogit MoveR: ReceiverResultReg R: TempReg.
					 classObj := objectMemory fetchPointer: i ofObject: arrayObj.
					 classIndex := objectMemory classTagForClass: classObj.
					 classIndex = objectMemory smallIntegerTag ifTrue:
						[jmpImmediate := self genJumpSmallIntegerInScratchReg: TempReg].
					 classIndex = objectMemory characterTag ifTrue:
						[jmpImmediate := self genJumpCharacterInScratchReg: TempReg].
					 branches at: branchIndex put: jmpImmediate.
					 branchIndex := branchIndex + 1]]].

	(allImmediate or: [noneImmediate]) ifFalse:
		[cogit MoveR: ReceiverResultReg R: TempReg.
		 jmpImmediate := self genJumpImmediateInScratchReg: TempReg.
		 self genGetCompactClassIndexNonImmOf: ReceiverResultReg into: TempReg.
		 0 to: (objectMemory numSlotsOf: arrayObj) - 1 do:
			[:i|
			 classObj := objectMemory fetchPointer: i ofObject: arrayObj.
			 (objectMemory isImmediateClass: classObj) ifFalse:
			 	[self genCmpClassIndex: (objectMemory classTagForClass: classObj) R: TempReg.
				 branches at: branchIndex put: (cogit JumpZero: 0).
				 branchIndex := branchIndex + 1]].
		 jmpNoMatch := cogit Jump: 0.
		 jmpImmediate jmpTarget: cogit Label.
		 0 to: (objectMemory numSlotsOf: arrayObj) - 1 do:
			[:i|
			 classObj := objectMemory fetchPointer: i ofObject: arrayObj.
			 (objectMemory isImmediateClass: classObj) ifTrue:
			 	["first time through TempReg already contains tag pattern, so no need to reload it."
				 branchIndex > numNonImmediates ifTrue:
					[cogit MoveR: ReceiverResultReg R: TempReg].
				 classIndex := objectMemory classTagForClass: classObj.
				 classIndex = objectMemory smallIntegerTag ifTrue:
					[jmpImmediate := self genJumpSmallIntegerInScratchReg: TempReg].
				 classIndex = objectMemory characterTag ifTrue:
					[jmpImmediate := self genJumpCharacterInScratchReg: TempReg].
				 branches at: branchIndex put: jmpImmediate.
				 branchIndex := branchIndex + 1]].
		 jmpNoMatch jmpTarget: cogit Label].

	self assert: branchIndex <= (objectMemory numSlotsOf: arrayObj).
	^branchIndex
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genAddSmallIntegerTagsTo: aRegister [
	cogit AddCq: 1 R: aRegister.
	^0
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationFor32BitSpur >> genCmpClassIndex: classIndex R: reg [
	"It is safe to use a short comparison for the known classes; these will not
	 change with become, etc... But it's probably not safe to assume the hash of
	 some other class won't change over time, so to be sure of generating the
	 same size code over time, use a long comparison for unknown classes."
	classIndex < objectMemory classTablePageSize
		ifTrue: [cogit CmpCq: classIndex R: TempReg]
		ifFalse: [cogit CmpCw: classIndex R: TempReg].
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genConvertCharacterToSmallIntegerInReg: reg [
	"Convert the SmallInteger in reg to a Character, assuming
	 the SmallInteger's value is a valid character."
	"self assume: objectMemory smallIntegerTag = 1"
	self assert: (objectMemory characterTag = 2
				 and: [self numCharacterBits + 1 = self numSmallIntegerBits]).
	cogit LogicalShiftRightCq: 1 R: reg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genConvertIntegerToSmallIntegerInReg: reg [
	cogit LogicalShiftLeftCq: 1 R: reg.
	cogit AddCq: 1 R: reg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genConvertSmallIntegerToCharacterInReg: reg [
	"Convert the SmallInteger in reg to a Character, assuming
	 the SmallInteger's value is a valid character."
	"self assume: objectMemory smallIntegerTag = 1"
	self assert: (objectMemory characterTag = 2
				 and: [self numCharacterBits + 1 = self numSmallIntegerBits]).
	cogit LogicalShiftLeftCq: 1 R: reg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genConvertSmallIntegerToIntegerInReg: reg [
	cogit ArithmeticShiftRightCq: 1 R: reg.
	^0
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationFor32BitSpur >> genCreateClosureAt: bcpc numArgs: numArgs numCopied: numCopied contextNumArgs: ctxtNumArgs large: isLargeCtxt inBlock: isInBlock [
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
CogObjectRepresentationFor32BitSpur >> genFetchIndexRegister: indexReg from: tableObj into: destReg [
	"indexReg contains the 1-relative index of an element in tableObj.
	 Since BaseHeaderSize > BytesPerOop we must adjust it to use
	 it as a zero-relative index from the beginning of the object."
	self assert: indexReg ~= destReg.
	cogit AddCq: objectMemory baseHeaderSize / objectMemory wordSize - 1 R: indexReg.
	cogit annotate: (cogit MoveCw: tableObj R: destReg) objRef: tableObj.
	cogit MoveXwr: indexReg R: destReg R: destReg.
	^0
]

{ #category : #initialization }
CogObjectRepresentationFor32BitSpur >> genGetActiveContextLarge: isLarge inBlock: isInBlock [
	"Create a trampoline to answer the active context that will
	 answer it if a frame is already married, and create it otherwise.
	 Assume numArgs is in SendNumArgsReg and ClassReg is free."
	| header slotSize jumpSingle loopHead jumpNeedScavenge continuation exit |
	<var: #jumpNeedScavenge type: #'AbstractInstruction *'>
	<var: #continuation type: #'AbstractInstruction *'>
	<var: #jumpSingle type: #'AbstractInstruction *'>
	<var: #loopHead type: #'AbstractInstruction *'>
	<var: #exit type: #'AbstractInstruction *'>
	cogit
		MoveMw: FoxMethod r: FPReg R: TempReg;
		MoveR: TempReg R: ClassReg;
		AndCq: MFMethodFlagHasContextFlag R: TempReg.
	jumpSingle := cogit JumpZero: 0.
	cogit
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
	cogit
		MoveAw: objectMemory freeStartAddress R: ReceiverResultReg;
		MoveCq: (self low32BitsOf: header) R: TempReg;
		MoveR: TempReg Mw: 0 r: ReceiverResultReg;
		MoveCq: header >> 32 R: TempReg;
		MoveR: TempReg Mw: 4 r: ReceiverResultReg;
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

	"Now compute stack pointer; this is stackPointer (- 1 for return pc if a CISC) - framePointer - 4 (1 each for saved pc, method, context, receiver) + 1 (1-relative)"
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
			[cogit MoveCw: objectMemory nilObject R: TempReg].
	cogit MoveR: TempReg Mw: objectMemory baseHeaderSize + (ClosureIndex * objectMemory bytesPerOop) r: ReceiverResultReg.

	"Set the receiver"
	cogit
		MoveMw: FoxMFReceiver r: FPReg R: TempReg;
		MoveR: TempReg Mw: objectMemory baseHeaderSize + (ReceiverIndex * objectMemory bytesPerOop) r: ReceiverResultReg.

	"Now copy the arguments.  This is tricky because of the shortage of registers,.  ClassReg ranges
	 from 1 to numArgs (SendNumArgsReg), and from ReceiverIndex + 1 to ReceiverIndex + numArgs.
	 1 to: numArgs do:
		[:i|
		temp := longAt(FPReg + ((SendNumArgs - i + 2) * BytesPerWord)). +2 for saved pc and savedfp
		longAtput(FPReg + FoxMFReceiver + (i * BytesPerWord), temp)]"
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

	"Finally copy the temps.
	 ClassReg := FPReg + FoxMFReceiver.
	 SendNumArgsReg := SendNumArgsReg+ReceiverIndex.
	 [ClassReg := ClassReg - 4.
	  backEnd hasLinkRegister
			ifTrue: [ClassReg > SPReg]
			ifFalse: [ClassReg >= SPReg]] whileTrue:
		[receiver[SendNumArgsReg] := *ClassReg.
		 SendNumArgsReg := SendNumArgsReg + 1]]"
	cogit
		MoveR: FPReg R: ClassReg;
		AddCq: FoxMFReceiver R: ClassReg;
		AddCq: ReceiverIndex + 1 + (objectMemory baseHeaderSize / objectMemory wordSize) R: SendNumArgsReg.
	loopHead :=
	cogit SubCq: objectMemory wordSize R: ClassReg.
	cogit CmpR: SPReg R: ClassReg.
	exit := cogit backEnd hasLinkRegister
				ifTrue: [cogit JumpBelowOrEqual: 0]
				ifFalse: [cogit JumpBelow: 0].
	cogit
		MoveMw: 0 r: ClassReg R: TempReg;
		MoveR: TempReg Xwr: SendNumArgsReg R: ReceiverResultReg;
		AddCq: 1 R: SendNumArgsReg;
		Jump: loopHead.
	exit jmpTarget: cogit Label.

	cogit RetN: 0.
	
	jumpNeedScavenge jmpTarget:
		(cogit CallRT: ceScheduleScavengeTrampoline).
	cogit Jump: continuation.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genGetClassTagOf: instReg into: destReg scratchReg: scratchReg [
	^self genGetInlineCacheClassTagFrom: instReg into: destReg forEntry: true
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genGetHashFieldNonImmOf: instReg asSmallIntegerInto: destReg [
	"Fetch the instance's identity hash into destReg, encoded as a SmallInteger."
	"Get header word in scratchReg"
	cogit MoveMw: 4 r: instReg R: destReg.
	"Shift and mask the field leaving room for the SmallInteger tag."
	cogit AndCq: objectMemory identityHashHalfWordMask R: destReg.
	self genConvertIntegerToSmallIntegerInReg: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genGetHashFieldNonImmOf: instReg into: destReg [
	"Fetch the instance's identity hash into destReg, unencoded."
	cogit MoveMw: 4 r: instReg R: destReg.
	cogit AndCq: objectMemory identityHashHalfWordMask R: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genGetInlineCacheClassTagFrom: sourceReg into: destReg forEntry: forEntry [
	"Extract the inline cache tag for the object in sourceReg into destReg. The inline
	 cache tag for a given object is the value loaded in inline caches to distinguish
	 objects of different classes.  In Spur this is either the tags for immediates, (with
	 1 & 3 collapsed to 1 for SmallIntegers, and 2 collapsed to 0 for Characters), or
	 the receiver's classIndex.
	 If forEntry is true answer the entry label at which control is to enter (cmEntryOffset).
	 If forEntry is false, control enters at the start.
	If forEntry is false, generate something like this:
		Limm:
			andl $0x1, rDest
			j Lcmp
		Lentry:
			movl rSource, rDest
			andl $0x3, rDest
			jnz Limm
			movl 0(%edx), rDest
			andl $0x3fffff, rDest
		Lcmp:
	 If forEntry is true, generate something like the following.
	 At least on a 2.2GHz Intel Core i7 the following is slightly faster than the above,
	 136m sends/sec vs 130m sends/sec for nfib in tinyBenchmarks
		Lentry:
			movl rSource, rDest
			andl $0x3, rDest
			jz LnotImm
			andl $1, rDest
			j Lcmp
		LnotImm:
			movl 0(%edx), rDest
			andl $0x3fffff, rDest
		Lcmp:
	 But we expect most SmallInteger arithmetic to be performed in-line and so prefer the
	 version that is faster for non-immediates (because it branches for immediates only)."
	| immLabel jumpNotImm entryLabel jumpCompare |
	<var: #immLabel type: #'AbstractInstruction *'>
	<var: #jumpNotImm type: #'AbstractInstruction *'>
	<var: #entryLabel type: #'AbstractInstruction *'>
	<var: #jumpCompare type: #'AbstractInstruction *'>
	forEntry
		ifFalse:
			[entryLabel := cogit Label.
			 cogit AndCq: objectMemory tagMask R: sourceReg R: destReg.
			 jumpNotImm := cogit JumpZero: 0.
			 cogit AndCq: 1 R: destReg.
			 jumpCompare := cogit Jump: 0.
			 "Get least significant half of header word in destReg"
			 self flag: #endianness.
			 jumpNotImm jmpTarget:
				(cogit MoveMw: 0 r: sourceReg R: destReg).
			 jumpCompare jmpTarget:
				(cogit AndCq: objectMemory classIndexMask R: destReg)]
		ifTrue:
			[cogit AlignmentNops: objectMemory wordSize.
			 immLabel := cogit Label.
			 cogit AndCq: 1 R: destReg.
			 jumpCompare := cogit Jump: 0.
			 cogit AlignmentNops: objectMemory wordSize.
			 entryLabel := cogit Label.
			 cogit AndCq: objectMemory tagMask R: sourceReg R: destReg.
			 cogit JumpNonZero: immLabel.
			 self flag: #endianness.
			 "Get least significant half of header word in destReg"
			 cogit MoveMw: 0 r: sourceReg R: destReg.
			 cogit AndCq: objectMemory classIndexMask R: destReg.
			 jumpCompare jmpTarget: cogit Label].
	^entryLabel
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genGetNumBytesOf: srcReg into: destReg [
	"Get the size in byte-sized slots of the object in srcReg into destReg.
	 srcReg may equal destReg.
	 destReg <- numSlots << self shiftForWord - (fmt bitAnd: 3).
	 Assumes the object in srcReg has a byte format, i.e. 16 to 23 or 24 to 31 "
	<var: #jmp type: #'AbstractInstruction *'>
	| jmp |
	self genGetRawSlotSizeOfNonImm: srcReg into: destReg.
	cogit CmpCq: objectMemory numSlotsMask R: destReg.
	jmp := cogit JumpLess: 0.
	self genGetOverflowSlotsOf: srcReg into: destReg.
	jmp jmpTarget: (cogit LogicalShiftLeftCq: objectMemory shiftForWord R: destReg). 
	self genGetFormatOf: srcReg into: TempReg baseHeaderIntoScratch: nil.
	"Now: fmt bitAnd: 3 in TempReg"
	cogit SubR: TempReg R: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genGetNumSlotsOf: srcReg into: destReg [
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
CogObjectRepresentationFor32BitSpur >> genGetOverflowSlotsOf: srcReg into: destReg [
	cogit MoveMw: objectMemory baseHeaderSize negated r: srcReg R: destReg.
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> genGetSizeOf: sourceReg into: destReg formatReg: formatReg scratchReg: scratchReg abortJumpsInto: aBinaryBlock [
	"Get the size of the non-immediate object in sourceReg into destReg using formatReg
	 and scratchReg as temps.  None of these registers can overlap.  Supply the jumps
	 taken if the object in sourceReg is not indexable, or if the object in sourceReg is a
	 context.. Hack: If the object has a pointer format other than 2 leave the number of
	 fixed fields in formatReg.  Used by primitiveSize, primitiveAt, and primitiveAtPut"
	<returnTypeC: #'AbstractInstruction *'>
	| jumpNotIndexable
	  jumpBytesDone jumpShortsDone jumpArrayDone jump32BitLongsDone
	  jumpIsBytes jumpHasFixedFields jumpIsShorts jumpIsContext  |
	<inline: true>
	"c.f. StackInterpreter>>stSizeOf: SpurMemoryManager>>lengthOf:format: fixedFieldsOf:format:length:"
	<var: #jumpIsBytes type: #'AbstractInstruction *'>
	<var: #jumpIsShorts type: #'AbstractInstruction *'>
	<var: #jumpIsContext type: #'AbstractInstruction *'>
	<var: #jumpArrayDone type: #'AbstractInstruction *'>
	<var: #jumpNotIndexable type: #'AbstractInstruction *'>
	<var: #jumpHasFixedFields type: #'AbstractInstruction *'>
	<var: #jump32BitLongsDone type: #'AbstractInstruction *'>

	"formatReg := self formatOf: sourceReg"
	self genGetFormatOf: sourceReg
		into: formatReg
		leastSignificantHalfOfBaseHeaderIntoScratch: scratchReg.

	self genGetNumSlotsOf: sourceReg into: destReg.

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
					cogit CmpCq: objectMemory arrayFormat R: formatReg.
	jumpArrayDone := cogit JumpZero: 0.
	jumpNotIndexable := cogit JumpLess: 0.
					cogit CmpCq: objectMemory weakArrayFormat R: formatReg.
	jumpHasFixedFields := cogit JumpLessOrEqual: 0.
					cogit CmpCq: objectMemory firstShortFormat R: formatReg.
	jumpIsShorts := cogit JumpGreaterOrEqual: 0.
					cogit CmpCq: objectMemory firstLongFormat R: formatReg.
	jump32BitLongsDone := cogit JumpGreaterOrEqual: 0.
	"For now ignore 64-bit indexability."
	jumpNotIndexable jmpTarget: cogit Label.
	jumpNotIndexable := cogit Jump: 0.

	jumpIsBytes jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord R: destReg).
		cogit AndCq: objectMemory wordSize - 1 R: formatReg.
		cogit SubR: formatReg R: destReg.
	jumpBytesDone := cogit Jump: 0.

	jumpIsShorts jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord - 1 R: destReg).
		cogit AndCq: 1 R: formatReg.
		cogit SubR: formatReg R: destReg.
	jumpShortsDone := cogit Jump: 0.

	"formatReg contains fmt, now up for grabs.
	 destReg contains numSlots, precious.
	 sourceReg must be preserved"
	jumpHasFixedFields jmpTarget:
		(cogit AndCq: objectMemory classIndexMask R: scratchReg).
	cogit MoveR: scratchReg R: formatReg.
	cogit CmpCq: ClassMethodContextCompactIndex R: scratchReg.
	jumpIsContext := cogit JumpZero: 0.
	cogit PushR: destReg.
	self genGetClassObjectOfClassIndex: formatReg into: destReg scratchReg: scratchReg.
	self genLoadSlot: InstanceSpecificationIndex sourceReg: destReg destReg: formatReg.
	self genConvertSmallIntegerToIntegerInReg: formatReg.
	cogit
		PopR: destReg;
		AndCq: objectMemory fixedFieldsOfClassFormatMask R: formatReg;
		SubR: formatReg R: destReg.

	jumpArrayDone jmpTarget:
	(jump32BitLongsDone jmpTarget:
	(jumpShortsDone jmpTarget:
	(jumpBytesDone jmpTarget:
		cogit Label))).
	aBinaryBlock value: jumpNotIndexable value: jumpIsContext
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> genInnerPrimitiveAt: retNoffset [
	"Implement the guts of primitiveAt"
	| formatReg jumpNotIndexable jumpImmediate jumpBadIndex
	  jumpBytesDone jumpShortsDone jumpWordsDone jumpFixedFieldsDone
	  jumpIsBytes jumpIsShorts jumpIsWords jumpWordTooBig jumpIsArray jumpHasFixedFields jumpIsContext
	  jumpBytesOutOfBounds jumpShortsOutOfBounds jumpWordsOutOfBounds jumpArrayOutOfBounds jumpFixedFieldsOutOfBounds |
	<inline: true>
	"c.f. StackInterpreter>>stSizeOf: SpurMemoryManager>>lengthOf:format: fixedFieldsOf:format:length:"
	<var: #jumpIsBytes type: #'AbstractInstruction *'>
	<var: #jumpIsShorts type: #'AbstractInstruction *'>
	<var: #jumpBadIndex type: #'AbstractInstruction *'>
	<var: #jumpIsContext type: #'AbstractInstruction *'>
	<var: #jumpImmediate type: #'AbstractInstruction *'>
	<var: #jumpBytesDone type: #'AbstractInstruction *'>
	<var: #jumpShortsDone type: #'AbstractInstruction *'>
	<var: #jumpWordsDone type: #'AbstractInstruction *'>
	<var: #jumpWordTooBig type: #'AbstractInstruction *'>
	<var: #jumpNotIndexable type: #'AbstractInstruction *'>
	<var: #jumpHasFixedFields type: #'AbstractInstruction *'>
	<var: #jumpFixedFieldsDone type: #'AbstractInstruction *'>
	<var: #jumpArrayOutOfBounds type: #'AbstractInstruction *'>
	<var: #jumpBytesOutOfBounds type: #'AbstractInstruction *'>
	<var: #jumpShortsOutOfBounds type: #'AbstractInstruction *'>
	<var: #jumpWordsOutOfBounds type: #'AbstractInstruction *'>
	<var: #jumpFixedFieldsOutOfBounds type: #'AbstractInstruction *'>

	cogit MoveR: ReceiverResultReg R: TempReg.
	jumpImmediate := self genJumpImmediateInScratchReg: TempReg.
	cogit MoveR: Arg0Reg R: TempReg.
	cogit MoveR: Arg0Reg R: Arg1Reg.
	jumpBadIndex := self genJumpNotSmallIntegerInScratchReg: TempReg.
	self genConvertSmallIntegerToIntegerInReg: Arg1Reg.
	cogit SubCq: 1 R: Arg1Reg. "1-rel => 0-rel"

	"formatReg := self formatOf: ReceiverResultReg"
	self genGetFormatOf: ReceiverResultReg
		into: (formatReg := SendNumArgsReg)
		leastSignificantHalfOfBaseHeaderIntoScratch: TempReg.

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
	jumpIsBytes := cogit JumpAboveOrEqual: 0.
					cogit CmpCq: objectMemory arrayFormat R: formatReg.
	jumpIsArray := cogit JumpZero: 0.
	jumpNotIndexable := cogit JumpBelow: 0.
					cogit CmpCq: objectMemory weakArrayFormat R: formatReg.
	jumpHasFixedFields := cogit JumpBelowOrEqual: 0.
					cogit CmpCq: objectMemory firstShortFormat R: formatReg.
	jumpIsShorts := cogit JumpAboveOrEqual: 0.
					cogit CmpCq: objectMemory firstLongFormat R: formatReg.
	jumpIsWords := cogit JumpAboveOrEqual: 0.
	"For now ignore 64-bit indexability."
	jumpNotIndexable jmpTarget: cogit Label.
	jumpNotIndexable := cogit Jump: 0.

	jumpIsBytes jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord R: ClassReg).
		cogit AndCq: objectMemory wordSize - 1 R: formatReg.
		cogit SubR: formatReg R: ClassReg;
		CmpR: Arg1Reg R: ClassReg.
	jumpBytesOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddCq: objectMemory baseHeaderSize R: Arg1Reg.
	cogit MoveXbr: Arg1Reg R: ReceiverResultReg R: ReceiverResultReg.
	self genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
	jumpBytesDone := cogit Jump: 0.

	jumpIsShorts jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord - 1 R: ClassReg).
		cogit AndCq: 1 R: formatReg.
		cogit SubR: formatReg R: ClassReg;
		CmpR: Arg1Reg R: ClassReg.
	jumpShortsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddR: Arg1Reg R: ReceiverResultReg.
	cogit MoveM16: objectMemory baseHeaderSize r: ReceiverResultReg R: ReceiverResultReg.
	self genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
	jumpShortsDone := cogit Jump: 0.

	jumpIsWords jmpTarget:
		(cogit CmpR: Arg1Reg R: ClassReg).
	jumpWordsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg1Reg.
	cogit MoveXwr: Arg1Reg R: ReceiverResultReg R: TempReg.
	cogit SubCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg1Reg.
	jumpWordTooBig := self jumpNotSmallIntegerUnsignedValueInRegister: TempReg.
	cogit MoveR: TempReg R: ReceiverResultReg.
	self genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
	jumpWordsDone := cogit Jump: 0.

	jumpHasFixedFields jmpTarget:
		(cogit AndCq: objectMemory classIndexMask R: TempReg).
	cogit MoveR: TempReg R: formatReg.
	cogit CmpCq: ClassMethodContextCompactIndex R: TempReg.
	jumpIsContext := cogit JumpZero: 0.
	cogit PushR: ClassReg.
	self genGetClassObjectOfClassIndex: formatReg into: ClassReg scratchReg: TempReg.
	self genLoadSlot: InstanceSpecificationIndex sourceReg: ClassReg destReg: formatReg.
	cogit PopR: ClassReg.
	self genConvertSmallIntegerToIntegerInReg: formatReg.
	cogit
		AndCq: objectMemory fixedFieldsOfClassFormatMask R: formatReg;
		SubR: formatReg R: ClassReg;
		CmpR: Arg1Reg R: ClassReg.
	jumpFixedFieldsOutOfBounds := cogit JumpBelowOrEqual: 0.
	"index is (formatReg (fixed fields) + Arg1Reg (0-rel index)) * wordSize + baseHeaderSize"
	cogit AddR: formatReg R: Arg1Reg.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg1Reg.
	cogit MoveXwr: Arg1Reg R: ReceiverResultReg R: ReceiverResultReg.
	jumpFixedFieldsDone := cogit Jump: 0.

	jumpIsArray jmpTarget:
		(cogit CmpR: Arg1Reg R: ClassReg).
	jumpArrayOutOfBounds := cogit JumpBelowOrEqual: 0.	
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg1Reg.
	cogit MoveXwr: Arg1Reg R: ReceiverResultReg R: ReceiverResultReg.

	jumpFixedFieldsDone jmpTarget:
	(jumpWordsDone jmpTarget:
	(jumpShortsDone jmpTarget:
	(jumpBytesDone jmpTarget:
		(cogit RetN: retNoffset)))).

	jumpFixedFieldsOutOfBounds jmpTarget:
	(jumpArrayOutOfBounds jmpTarget:
	(jumpBytesOutOfBounds jmpTarget:
	(jumpShortsOutOfBounds jmpTarget:
	(jumpWordsOutOfBounds jmpTarget:
	(jumpWordTooBig jmpTarget:
	(jumpNotIndexable jmpTarget:
	(jumpIsContext jmpTarget:
	(jumpBadIndex jmpTarget:
	(jumpImmediate jmpTarget: cogit Label))))))))).

	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> genInnerPrimitiveAtPut: retNoffset [
	"Implement the guts of primitiveAtPut"
	| formatReg jumpImmediate jumpBadIndex
	  jumpNotIndexablePointers jumpNotIndexableBits
	  jumpIsContext jumpIsCompiledMethod jumpIsBytes jumpHasFixedFields
	  jumpArrayOutOfBounds jumpFixedFieldsOutOfBounds
	  jumpWordsOutOfBounds jumpBytesOutOfBounds jumpBytesOutOfRange
	  jumpNonSmallIntegerValue jumpShortsUnsupported jumpNotPointers
	  |
	<inline: true>
	"c.f. StackInterpreter>>stSizeOf: SpurMemoryManager>>lengthOf:format: fixedFieldsOf:format:length:"
	<var: #jumpIsBytes type: #'AbstractInstruction *'>
	<var: #jumpBadIndex type: #'AbstractInstruction *'>
	<var: #jumpIsContext type: #'AbstractInstruction *'>
	<var: #jumpImmediate type: #'AbstractInstruction *'>
	<var: #jumpHasFixedFields type: #'AbstractInstruction *'>
	<var: #jumpNotIndexableBits type: #'AbstractInstruction *'>
	<var: #jumpArrayOutOfBounds type: #'AbstractInstruction *'>
	<var: #jumpBytesOutOfBounds type: #'AbstractInstruction *'>
	<var: #jumpShortsUnsupported type: #'AbstractInstruction *'>
	<var: #jumpWordsOutOfBounds type: #'AbstractInstruction *'>
	<var: #jumpNotIndexablePointers type: #'AbstractInstruction *'>

	cogit MoveR: ReceiverResultReg R: TempReg.
	jumpImmediate := self genJumpImmediateInScratchReg: TempReg.
	cogit MoveR: Arg0Reg R: TempReg.
	jumpBadIndex := self genJumpNotSmallIntegerInScratchReg: TempReg.
	self genConvertSmallIntegerToIntegerInReg: Arg0Reg.
	cogit SubCq: 1 R: Arg0Reg. "1-rel => 0-rel"

	"formatReg := self formatOf: ReceiverResultReg"
	self genGetFormatOf: ReceiverResultReg
		into: (formatReg := SendNumArgsReg)
		leastSignificantHalfOfBaseHeaderIntoScratch: TempReg.

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
	cogit CmpCq: objectMemory weakArrayFormat R: formatReg.
	jumpNotPointers := cogit JumpAbove: 0.
	"optimistic store check; assume index in range (almost always is)."
	self genStoreCheckReceiverReg: ReceiverResultReg valueReg: Arg1Reg scratchReg: TempReg.

	cogit CmpCq: objectMemory arrayFormat R: formatReg.
	jumpNotIndexablePointers := cogit JumpBelow: 0.
	jumpHasFixedFields := cogit JumpNonZero: 0.
	cogit CmpR: Arg0Reg R: ClassReg.
	jumpArrayOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg0Reg.
	cogit MoveR: Arg1Reg Xwr: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit RetN: retNoffset.

	jumpHasFixedFields jmpTarget: cogit Label.
	self genGetClassIndexOfNonImm: ReceiverResultReg into: formatReg.
	cogit CmpCq: ClassMethodContextCompactIndex R: formatReg.
	jumpIsContext := cogit JumpZero: 0.
	"get # fixed fields in formatReg"
	cogit PushR: ClassReg.
	self genGetClassObjectOfClassIndex: formatReg into: ClassReg scratchReg: TempReg.
	self genLoadSlot: InstanceSpecificationIndex sourceReg: ClassReg destReg: formatReg.
	cogit PopR: ClassReg.
	self genConvertSmallIntegerToIntegerInReg: formatReg.
	cogit AndCq: objectMemory fixedFieldsOfClassFormatMask R: formatReg.
	cogit SubR: formatReg R: ClassReg.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: formatReg.
	cogit CmpR: Arg0Reg R: ClassReg.
	jumpFixedFieldsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddR: formatReg R: Arg0Reg.
	cogit MoveR: Arg1Reg Xwr: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit RetN: retNoffset.

	jumpNotPointers jmpTarget:
		(cogit CmpCq: objectMemory firstCompiledMethodFormat R: formatReg).
	jumpIsCompiledMethod := cogit JumpAboveOrEqual: 0.
	cogit MoveR: Arg1Reg R: TempReg.
	jumpNonSmallIntegerValue := self genJumpNotSmallIntegerInScratchReg: TempReg.
					cogit CmpCq: objectMemory firstByteFormat R: formatReg.
	jumpIsBytes := cogit JumpAboveOrEqual: 0.
					cogit CmpCq: objectMemory firstShortFormat R: formatReg.
	jumpShortsUnsupported := cogit JumpAboveOrEqual: 0.
					cogit CmpCq: objectMemory firstLongFormat R: formatReg.
	"For now ignore 64-bit indexability."
	jumpNotIndexableBits := cogit JumpBelow: 0.

	cogit CmpR: Arg0Reg R: ClassReg.
	jumpWordsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit MoveR: Arg1Reg R: TempReg.
	self genConvertSmallIntegerToIntegerInReg: TempReg.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg0Reg.
	cogit MoveR: TempReg Xwr: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit RetN: retNoffset.

	jumpIsBytes jmpTarget:
		(cogit CmpCq: (objectMemory integerObjectOf: 255) R: Arg1Reg).
	jumpBytesOutOfRange := cogit JumpAbove: 0.
	cogit LogicalShiftLeftCq: objectMemory shiftForWord R: ClassReg.
	cogit AndCq: objectMemory wordSize - 1 R: formatReg.
	cogit SubR: formatReg R: ClassReg;
	CmpR: Arg0Reg R: ClassReg.
	jumpBytesOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit MoveR: Arg1Reg R: TempReg.
	self genConvertSmallIntegerToIntegerInReg: TempReg.
	cogit AddCq: objectMemory baseHeaderSize R: Arg0Reg.
	cogit MoveR: TempReg Xbr: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit RetN: retNoffset.

	"there are no shorts as yet.  so this is dead code:
	jumpIsShorts jmpTarget:
		(cogit CmpCq: (objectMemory integerObjectOf: 65535) R: Arg1Reg).
	jumpShortsOutOfRange := cogit JumpAbove: 0.
	cogit LogicalShiftLeftCq: objectMemory shiftForWord - 1 R: ClassReg.
	cogit AndCq: 1 R: formatReg.
	cogit SubR: formatReg R: ClassReg;
	CmpR: Arg0Reg R: ClassReg.
	jumpShortsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit MoveR: Arg1Reg R: TempReg.
	cogit genConvertSmallIntegerToIntegerInReg: TempReg.
	cogit AddR: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: TempReg M16: objectMemory baseHeaderSize r: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	jumpShortsDone := cogit Jump: 0."

	jumpIsContext jmpTarget: 
	(jumpNotIndexableBits jmpTarget:
	(jumpBytesOutOfRange jmpTarget:
	(jumpIsCompiledMethod jmpTarget:
	(jumpArrayOutOfBounds jmpTarget:
	(jumpBytesOutOfBounds jmpTarget:
	(jumpShortsUnsupported jmpTarget:
	(jumpWordsOutOfBounds jmpTarget:
	(jumpNotIndexablePointers jmpTarget:
	(jumpNonSmallIntegerValue jmpTarget:
	(jumpFixedFieldsOutOfBounds jmpTarget: cogit Label)))))))))).

	cogit AddCq: 1 R: Arg0Reg. "0-rel => 1-rel"
	self genConvertIntegerToSmallIntegerInReg: Arg0Reg.

	jumpBadIndex jmpTarget: (jumpImmediate jmpTarget: cogit Label).

	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> genInnerPrimitiveIdentityHash: retNoffset [
	| jumpImm jumpSI jumpNotSet ret |
	<var: #jumpSI type: #'AbstractInstruction *'>
	<var: #jumpImm type: #'AbstractInstruction *'>
	<var: #jumpNotSet type: #'AbstractInstruction *'>
	cogit MoveR: ReceiverResultReg R: ClassReg.
	jumpImm := self genJumpImmediateInScratchReg: ClassReg.
	self genGetHashFieldNonImmOf: ReceiverResultReg asSmallIntegerInto: TempReg.
	cogit CmpCq: ConstZero R: TempReg.
	jumpNotSet := cogit JumpZero: 0.
	cogit MoveR: TempReg R: ReceiverResultReg.
	ret := cogit RetN: 0.
	jumpImm jmpTarget: (cogit MoveR: ReceiverResultReg R: ClassReg).
	jumpSI := self genJumpSmallIntegerInScratchReg: ClassReg.
	jumpSI jmpTarget: ret.
	self genConvertCharacterToSmallIntegerInReg: ReceiverResultReg.
	cogit Jump: ret.
	jumpNotSet jmpTarget: cogit Label.
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> genInnerPrimitiveMirrorNew: retNoffset [
	"Implement 1-arg (instantiateFixedClass:) primitiveNew for convenient cases:
	- the class argument has a hash
	- the class argument is fixed size (excluding ephemerons to save instructions & miniscule time)
	- single word header/num slots < numSlotsMask
	- the result fits in eden (actually below scavengeThreshold)"

	<option: #NewspeakVM>
	| halfHeaderReg fillReg instSpecReg byteSizeReg
	  jumpImmediate jumpUnhashed jumpNotFixedPointers jumpTooSmall jumpBadFormat
	  jumpNoSpace jumpTooBig jumpHasSlots jumpVariableOrEphemeron
	  fillLoop skip |
	<var: 'skip' type: #'AbstractInstruction *'>
	<var: 'fillLoop' type: #'AbstractInstruction *'>
	<var: 'jumpTooBig' type: #'AbstractInstruction *'>
	<var: 'jumpHasSlots' type: #'AbstractInstruction *'>
	<var: 'jumpNoSpace' type: #'AbstractInstruction *'>
	<var: 'jumpTooSmall' type: #'AbstractInstruction *'>
	<var: 'jumpUnhashed' type: #'AbstractInstruction *'>
	<var: 'jumpImmediate' type: #'AbstractInstruction *'>
	<var: 'jumpBadFormat' type: #'AbstractInstruction *'>
	<var: 'jumpNotFixedPointers' type: #'AbstractInstruction *'>
	<var: 'jumpVariableOrEphemeron' type: #'AbstractInstruction *'>

	"half header will contain 1st half of header (classIndex/class's hash & format),
	 then 2nd half of header (numSlots/fixed size) and finally fill value (nilObject)."
	halfHeaderReg := fillReg := SendNumArgsReg.
	"inst spec will hold class's instance specification, then byte size and finally end of new object."
	instSpecReg := byteSizeReg := ClassReg.

	"get freeStart as early as possible so as not to wait later..."
	cogit MoveAw: objectMemory freeStartAddress R: Arg1Reg.

	"validate class arg; sigh, this mirror crap hobbles unfairly; there is a better way with selector namespaces..."
	cogit MoveR: Arg0Reg R: TempReg.
	jumpImmediate := self genJumpImmediateInScratchReg: TempReg.

	"Is the class arg pointers with at least 3 fields?"
	self genGetFormatOf: Arg0Reg
		into: TempReg
		leastSignificantHalfOfBaseHeaderIntoScratch: nil.
	cogit CmpCq: objectMemory nonIndexablePointerFormat R: TempReg.
	jumpNotFixedPointers := cogit JumpNonZero: 0.
	
	self genGetRawSlotSizeOfNonImm: Arg0Reg into: TempReg.
	cogit CmpCq: InstanceSpecificationIndex + 1 R: TempReg.
	jumpTooSmall := cogit JumpLess: 0.

	"get class's hash & fail if 0"
	self genGetHashFieldNonImmOf: Arg0Reg into: halfHeaderReg.
	jumpUnhashed := cogit JumpZero: 0.

	"get class's format inst var for both inst spec (format field) and num fixed fields"
	self genLoadSlot: InstanceSpecificationIndex sourceReg: Arg0Reg destReg: instSpecReg.
	cogit MoveR: instSpecReg R: TempReg.
	jumpBadFormat := self genJumpNotSmallIntegerInScratchReg: TempReg.
	self genConvertSmallIntegerToIntegerInReg: instSpecReg.
	cogit LogicalShiftRightCq: objectMemory fixedFieldsFieldWidth R: TempReg.
	cogit AndCq: objectMemory formatMask R: TempReg.
	cogit AndCq: objectMemory fixedFieldsOfClassFormatMask R: instSpecReg.
	"fail if not fixed or if ephemeron (rare beasts so save the cycles)"
	cogit CmpCq: objectMemory nonIndexablePointerFormat R: TempReg.
	jumpVariableOrEphemeron := cogit JumpAbove: 0.
	cogit CmpCq: objectMemory numSlotsMask R: instSpecReg.
	jumpTooBig := cogit JumpAboveOrEqual: 0.
	"Add format to classIndex/format half header; other word contains numSlots"
	cogit LogicalShiftLeftCq: objectMemory formatShift R: TempReg.
	cogit AddR: TempReg R: halfHeaderReg.
	"write half header now; it frees halfHeaderReg"
	cogit MoveR: halfHeaderReg Mw: 0 r: Arg1Reg.
	"save unrounded numSlots for header"
	cogit MoveR: instSpecReg R: halfHeaderReg.
	"compute byte size; remember 0-sized objects still need 1 slot & allocation is
	 rounded up to 8 bytes."
	cogit CmpCq: 0 R: byteSizeReg. "a.k.a. instSpecReg"
	jumpHasSlots := cogit JumpNonZero: 0.
	cogit MoveCq: objectMemory baseHeaderSize * 2 R: byteSizeReg.
	skip := cogit Jump: 0.
	"round up to allocationUnit"
	jumpHasSlots jmpTarget:
	(cogit MoveR: byteSizeReg R: TempReg).
	cogit AndCq: 1 R: TempReg.
	cogit AddR: TempReg R: byteSizeReg.
	cogit AddCq: objectMemory baseHeaderSize / objectMemory wordSize R: byteSizeReg.
	cogit LogicalShiftLeftCq: objectMemory shiftForWord R: byteSizeReg.
	skip jmpTarget:
	"shift halfHeaderReg to put numSlots in correct place"
	(cogit LogicalShiftLeftCq: objectMemory numSlotsHalfShift R: halfHeaderReg).
	"check if allocation fits (freeSize + byteSize < scavengeThreshold); scavengeThreshold is constant."
	cogit AddR: Arg1Reg R: byteSizeReg.
	cogit CmpCq: objectMemory getScavengeThreshold R: byteSizeReg.
	jumpNoSpace := cogit JumpAboveOrEqual: 0.
	"write back new freeStart; get result. byteSizeReg holds new freeStart, the limit of the object"
	cogit MoveR: byteSizeReg Aw: objectMemory freeStartAddress.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	"write other half of header (numSlots/identityHash)"
	cogit MoveR: halfHeaderReg Mw: 4 r: Arg1Reg.
	"now fill"
	cogit LoadEffectiveAddressMw: objectMemory baseHeaderSize r: ReceiverResultReg R: Arg1Reg.
	cogit MoveCq: objectMemory nilObject R: fillReg.
	"at least two words; so can make this a [fill 2 words. reached limit?] whileFalse"
	fillLoop := 
	cogit MoveR: fillReg Mw: 0 r: Arg1Reg.
	cogit MoveR: fillReg Mw: 4 r: Arg1Reg.
	cogit AddCq: 8 R: Arg1Reg.
	cogit CmpR: Arg1Reg R: byteSizeReg.
	cogit JumpAbove: fillLoop.
	cogit RetN: retNoffset.

	jumpNotFixedPointers jmpTarget:
	(jumpBadFormat jmpTarget:
	(jumpTooSmall jmpTarget:
	(jumpImmediate jmpTarget:
	(jumpUnhashed jmpTarget:
	(jumpVariableOrEphemeron jmpTarget:
	(jumpTooBig jmpTarget:
	(jumpNoSpace jmpTarget: cogit Label))))))).

	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> genInnerPrimitiveMirrorNewWithArg: retNoffset [
	"Implement instantiateVariableClass:withSize: for convenient cases:
	- the class argument has a hash
	- the class argument is variable and not compiled method
	- single word header/num slots < numSlotsMask
	- the result fits in eden
	See superclass method for dynamic frequencies of formats.
	For the moment we implement only arrayFormat, firstByteFormat & firstLongFormat"

	<option: #NewspeakVM>
	| halfHeaderReg fillReg instSpecReg byteSizeReg maxSlots
	  jumpArrayTooBig jumpByteTooBig jumpLongTooBig
	  jumpArrayFormat jumpByteFormat jumpBytePrepDone jumpLongPrepDone
	  jumpUnhashed jumpTooSmall jumpImmediate jumpNotFixedPointers
	  jumpNElementsNonInt jumpFailCuzFixed jumpNoSpace jumpHasSlots fillLoop skip |
	<var: 'skip' type: #'AbstractInstruction *'>
	<var: 'fillLoop' type: #'AbstractInstruction *'>	
	<var: 'jumpHasSlots' type: #'AbstractInstruction *'>
	<var: 'jumpNoSpace' type: #'AbstractInstruction *'>
	<var: 'jumpTooSmall' type: #'AbstractInstruction *'>
	<var: 'jumpUnhashed' type: #'AbstractInstruction *'>
	<var: 'jumpImmediate' type: #'AbstractInstruction *'>
	<var: 'jumpByteFormat' type: #'AbstractInstruction *'>
	<var: 'jumpByteTooBig' type: #'AbstractInstruction *'>
	<var: 'jumpLongTooBig' type: #'AbstractInstruction *'>
	<var: 'jumpArrayFormat' type: #'AbstractInstruction *'>
	<var: 'jumpArrayTooBig' type: #'AbstractInstruction *'>
	<var: 'jumpFailCuzFixed' type: #'AbstractInstruction *'>
	<var: 'jumpBytePrepDone' type: #'AbstractInstruction *'>
	<var: 'jumpLongPrepDone' type: #'AbstractInstruction *'>
	<var: 'jumpNElementsNonInt' type: #'AbstractInstruction *'>
	<var: 'jumpNotFixedPointers' type: #'AbstractInstruction *'>

	"half header will contain 1st half of header (classIndex/class's hash & format),
	 then 2nd half of header (numSlots) and finally fill value (nilObject)."
	halfHeaderReg := fillReg := SendNumArgsReg.
	"inst spec will hold class's instance specification and then byte size and finally numSlots half of header"
	instSpecReg := byteSizeReg := ClassReg.
	"The max slots we'll allocate here are those for a single header"
	maxSlots := objectMemory numSlotsMask - 1.

	"check size and fail if not a +ve integer"
	cogit MoveR: Arg1Reg R: TempReg.
	jumpNElementsNonInt := self genJumpNotSmallIntegerInScratchReg: TempReg.

	"Is the class arg pointers with at least 3 fields?"
	cogit MoveR: Arg0Reg R: TempReg.
	jumpImmediate := self genJumpImmediateInScratchReg: TempReg.

	self genGetFormatOf: Arg0Reg
		into: TempReg
		leastSignificantHalfOfBaseHeaderIntoScratch: nil.
	cogit CmpCq: objectMemory nonIndexablePointerFormat R: TempReg.
	jumpNotFixedPointers := cogit JumpNonZero: 0.
	
	self genGetRawSlotSizeOfNonImm: Arg0Reg into: TempReg.
	cogit CmpCq: InstanceSpecificationIndex + 1 R: TempReg.
	jumpTooSmall := cogit JumpLess: 0.

	"get class's hash & fail if 0"
	self genGetHashFieldNonImmOf: Arg0Reg into: halfHeaderReg.
	jumpUnhashed := cogit JumpZero: 0.

	"The basicNew: code (genInnerPrimitiveNewWithArg:) expects class in ReceiverResultReg
	 and size in Arg0Reg.  Shuffle args to match, undoing on failure."
	cogit
		PushR: ReceiverResultReg;
		MoveR: Arg0Reg R: ReceiverResultReg;
		MoveR: Arg1Reg R: Arg0Reg.

	"get freeStart as early as possible so as not to wait later..."
	cogit MoveAw: objectMemory freeStartAddress R: Arg1Reg.
	"get class's hash & fail if 0"
	self genGetHashFieldNonImmOf: ReceiverResultReg into: halfHeaderReg.
	jumpUnhashed := cogit JumpZero: 0.
	"get class's format inst var for inst spec (format field)"
	self genLoadSlot: InstanceSpecificationIndex sourceReg: ReceiverResultReg destReg: instSpecReg.
	cogit LogicalShiftRightCq: objectMemory fixedFieldsFieldWidth + self numSmallIntegerTagBits R: instSpecReg.
	cogit AndCq: objectMemory formatMask R: instSpecReg.
	"Add format to classIndex/format half header now"
	cogit MoveR: instSpecReg R: TempReg.
	cogit LogicalShiftLeftCq: objectMemory formatShift R: TempReg.
	cogit AddR: TempReg R: halfHeaderReg.
	"get integer value of num fields in TempReg now"
	cogit MoveR: Arg0Reg R: TempReg.
	self genConvertSmallIntegerToIntegerInReg: TempReg.
	"dispatch on format, failing if not variable or if compiled method"
	cogit CmpCq: objectMemory arrayFormat R: instSpecReg.
	jumpArrayFormat := cogit JumpZero: 0.
	cogit CmpCq: objectMemory firstByteFormat R: instSpecReg.
	jumpByteFormat := cogit JumpZero: 0.
	cogit CmpCq: objectMemory firstLongFormat R: instSpecReg.
	jumpFailCuzFixed := cogit JumpNonZero: 0.

	cogit CmpCq: (objectMemory integerObjectOf: maxSlots) R: Arg0Reg.
	jumpLongTooBig := cogit JumpAbove: 0.
	"save num elements/slot size to instSpecReg"
	cogit MoveR: TempReg R: instSpecReg.
	"push fill value"
	cogit PushCq: 0.
	jumpLongPrepDone := cogit Jump: 0. "go allocate"

	jumpByteFormat jmpTarget:
	(cogit CmpCq: (objectMemory integerObjectOf: maxSlots * objectMemory wordSize) R: Arg0Reg).
	jumpByteTooBig := cogit JumpAbove: 0.
	"save num elements to instSpecReg"
	cogit MoveR: TempReg R: instSpecReg.
	"compute odd bits and add into halfHeaderReg; oddBits := 4 - nElements bitAnd: 3"
	cogit MoveCq: objectMemory wordSize R: TempReg.
	cogit SubR: instSpecReg R: TempReg.
	cogit AndCq: objectMemory wordSize - 1 R: TempReg.
	cogit LogicalShiftLeftCq: objectMemory formatShift R: TempReg.
	cogit AddR: TempReg R: halfHeaderReg.
	"round up num elements to numSlots in instSpecReg"
	cogit AddCq: objectMemory wordSize - 1 R: instSpecReg.
	cogit LogicalShiftRightCq: objectMemory shiftForWord R: instSpecReg.
	"push fill value"
	cogit PushCq: 0.
	jumpBytePrepDone := cogit Jump: 0. "go allocate"

	jumpArrayFormat jmpTarget:
		(cogit CmpCq: (objectMemory integerObjectOf: maxSlots) R: Arg0Reg).
	jumpArrayTooBig := cogit JumpAbove: 0.
	"save num elements/slot size to instSpecReg"
	cogit MoveR: TempReg R: instSpecReg.
	"push fill value"
	cogit PushCw: objectMemory nilObject.
	"fall through to allocate"

	jumpBytePrepDone jmpTarget:
	(jumpLongPrepDone jmpTarget: cogit Label).

	"write half header now; it frees halfHeaderReg"
	cogit MoveR: halfHeaderReg Mw: 0 r: Arg1Reg.
	"save numSlots to halfHeaderReg"
	cogit MoveR: instSpecReg R: halfHeaderReg.
	"compute byte size; remember 0-sized objects still need 1 slot & allocation is
	 rounded up to 8 bytes."
	cogit CmpCq: 0 R: byteSizeReg. "a.k.a. instSpecReg"
	jumpHasSlots := cogit JumpNonZero: 0.
	cogit MoveCq: objectMemory baseHeaderSize * 2 R: byteSizeReg.
	skip := cogit Jump: 0.
	"round up to allocationUnit"
	jumpHasSlots jmpTarget:
	(cogit MoveR: byteSizeReg R: TempReg).
	cogit AndCq: 1 R: TempReg.
	cogit AddR: TempReg R: byteSizeReg.
	cogit AddCq: objectMemory baseHeaderSize / objectMemory wordSize R: byteSizeReg.
	cogit LogicalShiftLeftCq: objectMemory shiftForWord R: byteSizeReg.
	skip jmpTarget:
	"shift halfHeaderReg to put numSlots in correct place"
	(cogit LogicalShiftLeftCq: objectMemory numSlotsHalfShift R: halfHeaderReg).
	"check if allocation fits"
	cogit AddR: Arg1Reg R: byteSizeReg.
	cogit CmpCq: objectMemory getScavengeThreshold R: byteSizeReg.
	jumpNoSpace := cogit JumpAboveOrEqual: 0.
	"get result, increment freeStart and write it back. Arg1Reg holds new freeStart, the limit of the object"
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit MoveR: byteSizeReg Aw: objectMemory freeStartAddress.
	"write other half of header (numSlots/0 identityHash)"
	cogit MoveR: halfHeaderReg Mw: 4 r: ReceiverResultReg.
	"now fill"
	cogit PopR: fillReg.
	cogit PopR: TempReg. "discard pushed receiver"
	cogit LoadEffectiveAddressMw: objectMemory baseHeaderSize r: ReceiverResultReg R: Arg1Reg.
	"at least two words; so can make this a [fill 2 words. reached limit?] whileFalse"
	fillLoop := 
	cogit MoveR: fillReg Mw: 0 r: Arg1Reg.
	cogit MoveR: fillReg Mw: 4 r: Arg1Reg.
	cogit AddCq: 8 R: Arg1Reg.
	cogit CmpR: Arg1Reg R: byteSizeReg.
	cogit JumpAbove: fillLoop.
	cogit RetN: retNoffset.

	"pop discarded fill value & fall through to failure"
	jumpNoSpace jmpTarget: (cogit PopR: TempReg).

	jumpFailCuzFixed jmpTarget:
	(jumpArrayTooBig jmpTarget:
	(jumpByteTooBig jmpTarget:
	(jumpLongTooBig jmpTarget: cogit Label))).

	"unshuffle arguments"
	cogit
		MoveR: Arg0Reg R: Arg1Reg;
		MoveR: ReceiverResultReg R: Arg0Reg;
		PopR: ReceiverResultReg.

	jumpUnhashed jmpTarget:
	(jumpImmediate jmpTarget:
	(jumpNotFixedPointers jmpTarget:
	(jumpTooSmall jmpTarget:
	(jumpNElementsNonInt jmpTarget: cogit Label)))).

	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> genInnerPrimitiveNew: retNoffset [
	"Implement primitiveNew for convenient cases:
	- the receiver has a hash
	- the receiver is fixed size (excluding ephemerons to save instructions & miniscule time)
	- single word header/num slots < numSlotsMask
	- the result fits in eden (actually below scavengeThreshold)"

	| halfHeaderReg fillReg instSpecReg byteSizeReg
	  jumpUnhashed jumpVariableOrEphemeron jumpNoSpace jumpTooBig jumpHasSlots
	  fillLoop skip |
	<var: 'skip' type: #'AbstractInstruction *'>
	<var: 'fillLoop' type: #'AbstractInstruction *'>
	<var: 'jumpTooBig' type: #'AbstractInstruction *'>
	<var: 'jumpHasSlots' type: #'AbstractInstruction *'>
	<var: 'jumpNoSpace' type: #'AbstractInstruction *'>
	<var: 'jumpUnhashed' type: #'AbstractInstruction *'>
	<var: 'jumpVariableOrEphemeron' type: #'AbstractInstruction *'>

	"half header will contain 1st half of header (classIndex/class's hash & format),
	 then 2nd half of header (numSlots/fixed size) and finally fill value (nilObject)."
	halfHeaderReg := fillReg := SendNumArgsReg.
	"inst spec will hold class's instance specification, then byte size and finally end of new object."
	instSpecReg := byteSizeReg := ClassReg.

	"get freeStart as early as possible so as not to wait later..."
	cogit MoveAw: objectMemory freeStartAddress R: Arg1Reg.
	"get class's hash & fail if 0"
	self genGetHashFieldNonImmOf: ReceiverResultReg into: halfHeaderReg.
	jumpUnhashed := cogit JumpZero: 0.
	"get class's format inst var for both inst spec (format field) and num fixed fields"
	self genLoadSlot: InstanceSpecificationIndex sourceReg: ReceiverResultReg destReg: TempReg.
	self genConvertSmallIntegerToIntegerInReg: TempReg.
	cogit MoveR: TempReg R: instSpecReg.
	cogit LogicalShiftRightCq: objectMemory fixedFieldsFieldWidth R: TempReg.
	cogit AndCq: objectMemory formatMask R: TempReg.
	cogit AndCq: objectMemory fixedFieldsOfClassFormatMask R: instSpecReg.
	"fail if not fixed or if ephemeron (rare beasts so save the cycles)"
	cogit CmpCq: objectMemory nonIndexablePointerFormat R: TempReg.
	jumpVariableOrEphemeron := cogit JumpAbove: 0.
	cogit CmpCq: objectMemory numSlotsMask R: instSpecReg.
	jumpTooBig := cogit JumpAboveOrEqual: 0.
	"Add format to classIndex/format half header; other word contains numSlots"
	cogit LogicalShiftLeftCq: objectMemory formatShift R: TempReg.
	cogit AddR: TempReg R: halfHeaderReg.
	"write half header now; it frees halfHeaderReg"
	cogit MoveR: halfHeaderReg Mw: 0 r: Arg1Reg.
	"save unrounded numSlots for header"
	cogit MoveR: instSpecReg R: halfHeaderReg.
	"compute byte size; remember 0-sized objects still need 1 slot & allocation is
	 rounded up to 8 bytes."
	cogit CmpCq: 0 R: byteSizeReg. "a.k.a. instSpecReg"
	jumpHasSlots := cogit JumpNonZero: 0.
	cogit MoveCq: objectMemory baseHeaderSize * 2 R: byteSizeReg.
	skip := cogit Jump: 0.
	"round up to allocationUnit"
	jumpHasSlots jmpTarget:
	(cogit MoveR: byteSizeReg R: TempReg).
	cogit AndCq: 1 R: TempReg.
	cogit AddR: TempReg R: byteSizeReg.
	cogit AddCq: objectMemory baseHeaderSize / objectMemory wordSize R: byteSizeReg.
	cogit LogicalShiftLeftCq: objectMemory shiftForWord R: byteSizeReg.
	skip jmpTarget:
	"shift halfHeaderReg to put numSlots in correct place"
	(cogit LogicalShiftLeftCq: objectMemory numSlotsHalfShift R: halfHeaderReg).
	"check if allocation fits (freeSize + byteSize < scavengeThreshold); scavengeThreshold is constant."
	cogit AddR: Arg1Reg R: byteSizeReg.
	cogit CmpCq: objectMemory getScavengeThreshold R: byteSizeReg.
	jumpNoSpace := cogit JumpAboveOrEqual: 0.
	"write back new freeStart; get result. byteSizeReg holds new freeStart, the limit of the object"
	cogit MoveR: byteSizeReg Aw: objectMemory freeStartAddress.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	"write other half of header (numSlots/identityHash)"
	cogit MoveR: halfHeaderReg Mw: 4 r: Arg1Reg.
	"now fill"
	cogit LoadEffectiveAddressMw: objectMemory baseHeaderSize r: ReceiverResultReg R: Arg1Reg.
	cogit MoveCq: objectMemory nilObject R: fillReg.
	"at least two words; so can make this a [fill 2 words. reached limit?] whileFalse"
	fillLoop := 
	cogit MoveR: fillReg Mw: 0 r: Arg1Reg.
	cogit MoveR: fillReg Mw: 4 r: Arg1Reg.
	cogit AddCq: 8 R: Arg1Reg.
	cogit CmpR: Arg1Reg R: byteSizeReg.
	cogit JumpAbove: fillLoop.
	cogit RetN: retNoffset.

	jumpUnhashed jmpTarget:
	(jumpVariableOrEphemeron jmpTarget:
	(jumpTooBig jmpTarget:
	(jumpNoSpace jmpTarget: cogit Label))).

	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> genInnerPrimitiveNewWithArg: retNoffset [
	"Implement primitiveNewWithArg for convenient cases:
	- the receiver has a hash
	- the receiver is variable and not compiled method
	- single word header/num slots < numSlotsMask
	- the result fits in eden
	See superclass method for dynamic frequencies of formats.
	For the moment we implement only arrayFormat, firstByteFormat & firstLongFormat"

	| halfHeaderReg fillReg instSpecReg byteSizeReg maxSlots
	  jumpArrayTooBig jumpByteTooBig jumpLongTooBig
	  jumpArrayFormat jumpByteFormat jumpBytePrepDone jumpLongPrepDone
	  jumpUnhashed jumpNElementsNonInt jumpFailCuzFixed jumpNoSpace jumpHasSlots fillLoop skip |
	<var: 'skip' type: #'AbstractInstruction *'>
	<var: 'fillLoop' type: #'AbstractInstruction *'>	
	<var: 'jumpHasSlots' type: #'AbstractInstruction *'>
	<var: 'jumpNoSpace' type: #'AbstractInstruction *'>
	<var: 'jumpUnhashed' type: #'AbstractInstruction *'>
	<var: 'jumpByteFormat' type: #'AbstractInstruction *'>
	<var: 'jumpByteTooBig' type: #'AbstractInstruction *'>
	<var: 'jumpLongTooBig' type: #'AbstractInstruction *'>
	<var: 'jumpArrayFormat' type: #'AbstractInstruction *'>
	<var: 'jumpArrayTooBig' type: #'AbstractInstruction *'>
	<var: 'jumpFailCuzFixed' type: #'AbstractInstruction *'>
	<var: 'jumpBytePrepDone' type: #'AbstractInstruction *'>
	<var: 'jumpLongPrepDone' type: #'AbstractInstruction *'>
	<var: 'jumpNElementsNonInt' type: #'AbstractInstruction *'>

	"half header will contain 1st half of header (classIndex/class's hash & format),
	 then 2nd half of header (numSlots) and finally fill value (nilObject)."
	halfHeaderReg := fillReg := SendNumArgsReg.
	"inst spec will hold class's instance specification and then byte size and finally numSlots half of header"
	instSpecReg := byteSizeReg := ClassReg.
	"The max slots we'll allocate here are those for a single header"
	maxSlots := objectMemory numSlotsMask - 1.

	"get freeStart as early as possible so as not to wait later..."
	cogit MoveAw: objectMemory freeStartAddress R: Arg1Reg.
	"get class's hash & fail if 0"
	self genGetHashFieldNonImmOf: ReceiverResultReg into: halfHeaderReg.
	jumpUnhashed := cogit JumpZero: 0.
	"get index and fail if not a +ve integer"
	cogit MoveR: Arg0Reg R: TempReg.
	jumpNElementsNonInt := self genJumpNotSmallIntegerInScratchReg: TempReg.
	"get class's format inst var for inst spec (format field)"
	self genLoadSlot: InstanceSpecificationIndex sourceReg: ReceiverResultReg destReg: instSpecReg.
	cogit LogicalShiftRightCq: objectMemory fixedFieldsFieldWidth + self numSmallIntegerTagBits R: instSpecReg.
	cogit AndCq: objectMemory formatMask R: instSpecReg.
	"Add format to classIndex/format half header now"
	cogit MoveR: instSpecReg R: TempReg.
	cogit LogicalShiftLeftCq: objectMemory formatShift R: TempReg.
	cogit AddR: TempReg R: halfHeaderReg.
	"get integer value of num fields in TempReg now"
	cogit MoveR: Arg0Reg R: TempReg.
	self genConvertSmallIntegerToIntegerInReg: TempReg.
	"dispatch on format, failing if not variable or if compiled method"
	cogit CmpCq: objectMemory arrayFormat R: instSpecReg.
	jumpArrayFormat := cogit JumpZero: 0.
	cogit CmpCq: objectMemory firstByteFormat R: instSpecReg.
	jumpByteFormat := cogit JumpZero: 0.
	cogit CmpCq: objectMemory firstLongFormat R: instSpecReg.
	jumpFailCuzFixed := cogit JumpNonZero: 0.

	cogit CmpCq: (objectMemory integerObjectOf: maxSlots) R: Arg0Reg.
	jumpLongTooBig := cogit JumpAbove: 0.
	"save num elements/slot size to instSpecReg"
	cogit MoveR: TempReg R: instSpecReg.
	"push fill value"
	cogit PushCq: 0.
	jumpLongPrepDone := cogit Jump: 0. "go allocate"

	jumpByteFormat jmpTarget:
	(cogit CmpCq: (objectMemory integerObjectOf: maxSlots * objectMemory wordSize) R: Arg0Reg).
	jumpByteTooBig := cogit JumpAbove: 0.
	"save num elements to instSpecReg"
	cogit MoveR: TempReg R: instSpecReg.
	"compute odd bits and add into halfHeaderReg; oddBits := 4 - nElements bitAnd: 3"
	cogit MoveCq: objectMemory wordSize R: TempReg.
	cogit SubR: instSpecReg R: TempReg.
	cogit AndCq: objectMemory wordSize - 1 R: TempReg.
	cogit LogicalShiftLeftCq: objectMemory formatShift R: TempReg.
	cogit AddR: TempReg R: halfHeaderReg.
	"round up num elements to numSlots in instSpecReg"
	cogit AddCq: objectMemory wordSize - 1 R: instSpecReg.
	cogit LogicalShiftRightCq: objectMemory shiftForWord R: instSpecReg.
	"push fill value"
	cogit PushCq: 0.
	jumpBytePrepDone := cogit Jump: 0. "go allocate"

	jumpArrayFormat jmpTarget:
		(cogit CmpCq: (objectMemory integerObjectOf: maxSlots) R: Arg0Reg).
	jumpArrayTooBig := cogit JumpAbove: 0.
	"save num elements/slot size to instSpecReg"
	cogit MoveR: TempReg R: instSpecReg.
	"push fill value"
	cogit PushCw: objectMemory nilObject.
	"fall through to allocate"

	jumpBytePrepDone jmpTarget:
	(jumpLongPrepDone jmpTarget: cogit Label).

	"write half header now; it frees halfHeaderReg"
	cogit MoveR: halfHeaderReg Mw: 0 r: Arg1Reg.
	"save numSlots to halfHeaderReg"
	cogit MoveR: instSpecReg R: halfHeaderReg.
	"compute byte size; remember 0-sized objects still need 1 slot & allocation is
	 rounded up to 8 bytes."
	cogit CmpCq: 0 R: byteSizeReg. "a.k.a. instSpecReg"
	jumpHasSlots := cogit JumpNonZero: 0.
	cogit MoveCq: objectMemory baseHeaderSize * 2 R: byteSizeReg.
	skip := cogit Jump: 0.
	"round up to allocationUnit"
	jumpHasSlots jmpTarget:
	(cogit MoveR: byteSizeReg R: TempReg).
	cogit AndCq: 1 R: TempReg.
	cogit AddR: TempReg R: byteSizeReg.
	cogit AddCq: objectMemory baseHeaderSize / objectMemory wordSize R: byteSizeReg.
	cogit LogicalShiftLeftCq: objectMemory shiftForWord R: byteSizeReg.
	skip jmpTarget:
	"shift halfHeaderReg to put numSlots in correct place"
	(cogit LogicalShiftLeftCq: objectMemory numSlotsHalfShift R: halfHeaderReg).
	"check if allocation fits"
	cogit AddR: Arg1Reg R: byteSizeReg.
	cogit CmpCq: objectMemory getScavengeThreshold R: byteSizeReg.
	jumpNoSpace := cogit JumpAboveOrEqual: 0.
	"get result, increment freeStart and write it back. Arg1Reg holds new freeStart, the limit of the object"
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit MoveR: byteSizeReg Aw: objectMemory freeStartAddress.
	"write other half of header (numSlots/0 identityHash)"
	cogit MoveR: halfHeaderReg Mw: 4 r: ReceiverResultReg.
	"now fill"
	cogit PopR: fillReg.
	cogit LoadEffectiveAddressMw: objectMemory baseHeaderSize r: ReceiverResultReg R: Arg1Reg.
	"at least two words; so can make this a [fill 2 words. reached limit?] whileFalse"
	fillLoop := 
	cogit MoveR: fillReg Mw: 0 r: Arg1Reg.
	cogit MoveR: fillReg Mw: 4 r: Arg1Reg.
	cogit AddCq: 8 R: Arg1Reg.
	cogit CmpR: Arg1Reg R: byteSizeReg.
	cogit JumpAbove: fillLoop.
	cogit RetN: retNoffset.

	"pop discarded fill value & fall through to failure"
	jumpNoSpace jmpTarget: (cogit PopR: TempReg).

	jumpUnhashed jmpTarget:
	(jumpFailCuzFixed jmpTarget:
	(jumpArrayTooBig jmpTarget:
	(jumpByteTooBig jmpTarget:
	(jumpLongTooBig jmpTarget:
	(jumpNElementsNonInt jmpTarget: cogit Label))))).

	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> genInnerPrimitiveStringAt: retNoffset [
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

	cogit MoveR: Arg0Reg R: TempReg.
	cogit MoveR: Arg0Reg R: Arg1Reg.
	jumpBadIndex := self genJumpNotSmallIntegerInScratchReg: TempReg.
	self genConvertSmallIntegerToIntegerInReg: Arg1Reg.
	cogit SubCq: 1 R: Arg1Reg. "1-rel => 0-rel"

	self genGetFormatOf: ReceiverResultReg
		into: (formatReg := SendNumArgsReg)
		leastSignificantHalfOfBaseHeaderIntoScratch: TempReg.

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

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> genInnerPrimitiveStringAtPut: retNoffset [
	"Implement the guts of primitiveStringAtPut"
	| formatReg jumpImmediate jumpBadIndex jumpBadArg
	  jumpWordsDone jumpBytesOutOfRange
	  jumpIsBytes jumpNotString jumpIsCompiledMethod
	  jumpBytesOutOfBounds jumpWordsOutOfBounds jumpShortsUnsupported |
	<inline: true>
	"c.f. StackInterpreter>>stSizeOf: SpurMemoryManager>>lengthOf:format: fixedFieldsOf:format:length:"
	<var: #jumpBadArg type: #'AbstractInstruction *'>
	<var: #jumpIsBytes type: #'AbstractInstruction *'>
	<var: #jumpBadIndex type: #'AbstractInstruction *'>
	<var: #jumpImmediate type: #'AbstractInstruction *'>
	<var: #jumpWordsDone type: #'AbstractInstruction *'>
	<var: #jumpBytesOutOfBounds type: #'AbstractInstruction *'>
	<var: #jumpShortsUnsupported type: #'AbstractInstruction *'>
	<var: #jumpWordsOutOfBounds type: #'AbstractInstruction *'>

	cogit MoveR: ReceiverResultReg R: TempReg.
	jumpImmediate := self genJumpImmediateInScratchReg: TempReg.
	cogit MoveR: Arg0Reg R: TempReg.
	jumpBadIndex := self genJumpNotSmallIntegerInScratchReg: TempReg.
	cogit MoveR: Arg1Reg R: TempReg.
	jumpBadArg := self genJumpNotCharacterInScratchReg: TempReg.
	self genConvertSmallIntegerToIntegerInReg: Arg0Reg.
	cogit SubCq: 1 R: Arg0Reg. "1-rel => 0-rel"

	"formatReg := self formatOf: ReceiverResultReg"
	self genGetFormatOf: ReceiverResultReg
		into: (formatReg := SendNumArgsReg)
		leastSignificantHalfOfBaseHeaderIntoScratch: TempReg.

	self genGetNumSlotsOf: ReceiverResultReg into: ClassReg.

	"dispatch on format; words and/or bytes.
		  0 to 8 = pointer objects, forwarders, reserved.
		  9 (?) 64-bit indexable
		10 - 11 32-bit indexable
		12 - 15 16-bit indexable (but unused)
		16 - 23 byte indexable
		24 - 31 compiled method"
	cogit CmpCq: objectMemory firstLongFormat R: formatReg.
	jumpNotString := cogit JumpBelowOrEqual: 0.
					cogit CmpCq: objectMemory firstCompiledMethodFormat R: formatReg.
	jumpIsCompiledMethod := cogit JumpAboveOrEqual: 0.
					cogit CmpCq: objectMemory firstByteFormat R: formatReg.
	jumpIsBytes := cogit JumpGreaterOrEqual: 0.
					cogit CmpCq: objectMemory firstShortFormat R: formatReg.
	jumpShortsUnsupported := cogit JumpGreaterOrEqual: 0.

	cogit CmpR: Arg0Reg R: ClassReg.
	jumpWordsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit MoveR: Arg1Reg R: TempReg.
	self genConvertSmallIntegerToIntegerInReg: TempReg.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg0Reg.
	cogit MoveR: TempReg Xwr: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	jumpWordsDone := cogit Jump: 0.

	"there are no shorts as yet.  so this is dead code:
	jumpIsShorts jmpTarget:
		(cogit CmpCq: (objectMemory integerObjectOf: 65535) R: Arg1Reg).
	jumpShortsOutOfRange := cogit JumpAbove: 0.
	cogit LogicalShiftLeftCq: objectMemory shiftForWord - 1 R: ClassReg.
	cogit AndCq: 1 R: formatReg.
	cogit SubR: formatReg R: ClassReg;
	CmpR: Arg0Reg R: ClassReg.
	jumpShortsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit MoveR: Arg1Reg R: TempReg.
	cogit genConvertSmallIntegerToIntegerInReg: TempReg.
	cogit AddR: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: TempReg M16: objectMemory baseHeaderSize r: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	jumpShortsDone := cogit Jump: 0."

	jumpIsBytes jmpTarget:
		(cogit CmpCq: (objectMemory characterObjectOf: 255) R: Arg1Reg).
	jumpBytesOutOfRange := cogit JumpAbove: 0.
	cogit LogicalShiftLeftCq: objectMemory shiftForWord R: ClassReg.
	cogit AndCq: objectMemory wordSize - 1 R: formatReg.
	cogit SubR: formatReg R: ClassReg;
	CmpR: Arg0Reg R: ClassReg.
	jumpBytesOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit MoveR: Arg1Reg R: TempReg.
	self genConvertCharacterToCodeInReg: TempReg.
	cogit AddCq: objectMemory baseHeaderSize R: Arg0Reg.
	cogit MoveR: TempReg Xbr: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.

	jumpWordsDone jmpTarget:
		(cogit RetN: retNoffset).

	jumpBadArg jmpTarget:
	(jumpNotString jmpTarget:
	(jumpBytesOutOfRange jmpTarget:
	(jumpIsCompiledMethod jmpTarget:
	(jumpBytesOutOfBounds jmpTarget:
	(jumpShortsUnsupported jmpTarget:
	(jumpWordsOutOfBounds jmpTarget: cogit Label)))))).

	cogit AddCq: 1 R: Arg0Reg. "0-rel => 1-rel"
	self genConvertIntegerToSmallIntegerInReg: Arg0Reg.

	jumpBadIndex jmpTarget: (jumpImmediate jmpTarget: cogit Label).

	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genJumpNotSmallIntegerInScratchReg: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit AndCq: 1 R: aRegister.
	^cogit JumpZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genJumpSmallIntegerInScratchReg: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit AndCq: 1 R: aRegister.
	^cogit JumpNonZero: 0
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationFor32BitSpur >> genNewArrayOfSize: size initialized: initialized [
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
	self flag: #endianness.
	cogit
		MoveAw: objectMemory freeStartAddress R: ReceiverResultReg;
		MoveCq: (self low32BitsOf: header) R: TempReg;
		MoveR: TempReg Mw: 0 r: ReceiverResultReg;
		MoveCq: header >> 32 R: TempReg;
		MoveR: TempReg Mw: 4 r: ReceiverResultReg.
	(initialized and: [size > 0]) ifTrue:
		[cogit MoveCw: objectMemory nilObject R: TempReg.
		 1 to: size do:
			[:i| cogit MoveR: TempReg Mw: i * 4 + 4 r: ReceiverResultReg]].
	cogit
		MoveR: ReceiverResultReg R: TempReg;
		AddCq: (objectMemory smallObjectBytesForSlots: size) R: TempReg;
		MoveR: TempReg Aw: objectMemory freeStartAddress;
		CmpCq: objectMemory getScavengeThreshold R: TempReg.
	skip := cogit JumpBelow: 0.
	cogit CallRT: ceScheduleScavengeTrampoline.
	skip jmpTarget: cogit Label.
	^0
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationFor32BitSpur >> genNoPopCreateClosureAt: bcpc numArgs: numArgs numCopied: numCopied contextNumArgs: ctxtNumArgs large: isLargeCtxt inBlock: isInBlock [
	"Create a closure with the given startpc, numArgs and numCopied
	 within a context with ctxtNumArgs, large if isLargeCtxt that is in a
	 block if isInBlock.  Do /not/ initialize the copied values."
	| slotSize header skip |
	<var: #skip type: #'AbstractInstruction *'>

	"First get thisContext into ReceiverResultRega and thence in ClassReg."
	self genGetActiveContextNumArgs: ctxtNumArgs large: isLargeCtxt inBlock: isInBlock.
	cogit MoveR: ReceiverResultReg R: ClassReg.

	slotSize := ClosureFirstCopiedValueIndex + numCopied.
	header := objectMemory
					headerForSlots: slotSize
					format: objectMemory indexablePointersFormat
					classIndex: ClassBlockClosureCompactIndex.
	cogit
		MoveAw: objectMemory freeStartAddress R: ReceiverResultReg;
		MoveCq: (self low32BitsOf: header) R: TempReg;
		MoveR: TempReg Mw: 0 r: ReceiverResultReg;
		MoveCq: header >> 32 R: TempReg;
		MoveR: TempReg Mw: 4 r: ReceiverResultReg;
		MoveR: ReceiverResultReg R: TempReg;
		AddCq: (objectMemory smallObjectBytesForSlots: slotSize) R: TempReg;
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
CogObjectRepresentationFor32BitSpur >> genRemoveSmallIntegerTagsInScratchReg: scratchReg [
	cogit SubCq: 1 R: scratchReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genSetSmallIntegerTagsIn: scratchReg [
	cogit OrCq: 1 R: scratchReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genShiftAwaySmallIntegerTagsInScratchReg: scratchReg [
	cogit ArithmeticShiftRightCq: 1 R: scratchReg.
	^0
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationFor32BitSpur >> illegalClassTag [
	<inline: true>
	^2
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationFor32BitSpur >> inlineCacheTagForClass: classOop [
	"Answer the relevant inline cache tag for a class.
	 c.f. inlineCacheTagForInstance:"
	| hash |
	hash := objectMemory classTagForClass: classOop.
	^hash <= objectMemory tagMask
		ifTrue: [hash bitAnd: 1]
		ifFalse: [hash]
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationFor32BitSpur >> inlineCacheTagForInstance: oop [
	"Answer the relevant inline cache tag for an instance.
	 c.f. getInlineCacheClassTagFrom:into: & inlineCacheTagForClass:"
	^(objectMemory isImmediate: oop)
		ifTrue: [oop bitAnd: 1] "SmallInteger => 1, Character => 0"
		ifFalse: [objectMemory classIndexOf: oop]
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> jumpNotSmallIntegerUnsignedValueInRegister: reg [
	cogit CmpCq: 16r3FFFFFFF R: reg.
	^cogit JumpAbove: 0
]

{ #category : #initialization }
CogObjectRepresentationFor32BitSpur >> log2BytesPerWord [
	^2
]

{ #category : #private }
CogObjectRepresentationFor32BitSpur >> low32BitsOf: a64BitHeader [
	<inline: true>
	^self cCode: [self cCoerceSimple: a64BitHeader to: #usqInt] inSmalltalk: [a64BitHeader bitAnd: 16rffffffff]
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> numCharacterBits [
	^30
]

{ #category : #'sista support' }
CogObjectRepresentationFor32BitSpur >> numCountersFor: theCounters [
	<var: #theCounters type: #usqInt>
	| objOop |
	theCounters = 0 ifTrue:
		[^0].
	objOop := theCounters - objectMemory baseHeaderSize.
	^objectMemory numSlotsOf: objOop
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> numSmallIntegerBits [
	^31
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> numSmallIntegerTagBits [
	^1
]

{ #category : #'debug support' }
CogObjectRepresentationFor32BitSpur >> validInlineCacheTag: classIndexOrTagPattern [
	"The two valid tag patterns are 0 (Character) and 1 (SmallInteger)"
	<var: 'classIndexOrTagPattern' type: #usqInt>
	^classIndexOrTagPattern <= 1
	  or: [(objectMemory classAtIndex: classIndexOrTagPattern) notNil]
]
