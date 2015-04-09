Class {
	#name : #CogObjectRepresentationForSpur,
	#superclass : #CogObjectRepresentation,
	#instVars : [
		'ceScheduleScavengeTrampoline',
		'ceSmallActiveContextInMethodTrampoline',
		'ceSmallActiveContextInBlockTrampoline',
		'ceLargeActiveContextInMethodTrampoline',
		'ceLargeActiveContextInBlockTrampoline'
	],
	#pools : [
		'CogCompilationConstants',
		'VMBytecodeConstants',
		'VMSqueakClassIndices'
	],
	#category : #'VMMaker-JIT'
}

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
	cogit MoveCq: newFloatHeader R: scratch2.
	objectMemory wordSize = objectMemory baseHeaderSize
		ifTrue: [cogit MoveR: scratch2 Mw: 0 r: resultReg]
		ifFalse:
			[self flag: #endianness.
			 cogit MoveCq: newFloatHeader >> 32 R: scratch1.
			 cogit MoveR: scratch2 Mw: 0 r: resultReg.
			 cogit MoveR: scratch1 Mw: objectMemory wordSize r: resultReg].
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
CogObjectRepresentationForSpur >> genEnsureObjInRegNotForwarded: reg scratchReg: scratch updatingMw: offset r: baseReg [
	"Make sure that the object in reg is not forwarded, and update the field reg[offset] is
	 updated if the object in reg is forwarded.
	 Use the fact that isForwardedObjectClassIndexPun is a power of two to save an instruction."
	| loop imm ok |
	<var: #ok type: #'AbstractInstruction *'>
	<var: #imm type: #'AbstractInstruction *'>
	<var: #loop type: #'AbstractInstruction *'>
	self assert: reg ~= scratch.
	loop := cogit Label.
	cogit MoveR: reg R: scratch.
	imm := self genJumpImmediateInScratchReg: scratch.
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
CogObjectRepresentationForSpur >> genEnsureOopInRegNotForwarded: reg scratchReg: scratch [
	"Make sure that the oop in reg is not forwarded.  This routine assumes the object will
	 never be forwarded to an immediate, as it is used to unforward  literal variables (associations). 
	 Use the fact that isForwardedObjectClassIndexPun is a power of two to save an instruction."
	| skip loop ok |
	<var: #ok type: #'AbstractInstruction *'>
	<var: #skip type: #'AbstractInstruction *'>
	<var: #loop type: #'AbstractInstruction *'>
	self assert: reg ~= scratch.
	cogit MoveR: reg R: scratch.
	skip := self genJumpImmediateInScratchReg: scratch.
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
	skip jmpTarget: (ok jmpTarget: cogit Label).
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genFetchIndexRegister: indexReg from: tableObj into: destReg [
	"indexReg contains the 1-relative index of an element in tableObj."
	self subclassResponsibility
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
CogObjectRepresentationForSpur >> genGetClassIndexOfNonImm: sourceReg into: destReg [
	"Fetch the instance's class index into destReg."

	cogit MoveMw: 0 r: sourceReg R: destReg.
	cogit AndCq: objectMemory classIndexMask R: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetClassObjectOf: instReg into: destReg scratchReg: scratchReg instRegIsReceiver: instRegIsReceiver [
	"Fetch the instance's class into destReg.  If the instance is forwarded, follow forwarding."
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
CogObjectRepresentationForSpur >> genGetFormatOf: sourceReg into: destReg baseHeaderIntoScratch: scratchReg [
	cogit MoveMw: 0 r: sourceReg R: destReg.
	scratchReg ifNotNil:
		[cogit MoveR: destReg R: scratchReg]. "destReg := (at least) least significant half of self baseHeader: receiver"
	cogit LogicalShiftRightCq: objectMemory formatShift R: destReg.
	cogit AndCq: objectMemory formatMask R: destReg.	"formatReg := self formatOfHeader: destReg"
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetFormatOf: sourceReg into: destReg leastSignificantHalfOfBaseHeaderIntoScratch: scratchRegOrNil [
	"Get the format of the object in sourceReg into destReg.  If scratchRegOrNil
	 is not nil, load at least the least significant 32-bits (64-bits in 64-bits) of the
	 header word, which contains the format, into scratchRegOrNil."
	cogit MoveMw: 0 r: sourceReg R: destReg.
	scratchRegOrNil ifNotNil:
		[cogit MoveR: destReg R: scratchRegOrNil]. "destReg := (at least) least significant half of self baseHeader: receiver"
	cogit LogicalShiftRightCq: objectMemory formatShift R: destReg.
	cogit AndCq: objectMemory formatMask R: destReg.	"formatReg := self formatOfHeader: destReg"
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetRawSlotSizeOfNonImm: sourceReg into: destReg [
	"The raw numSlots field is the most significant byte of the 64-bit header word."
	cogit MoveMb: 7 r: sourceReg R: destReg.
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genInnerPrimitiveAsCharacter: retNOffset inReg: reg [
	| jumpNotInt jumpOutOfRange |
	<var: 'jumpNotInt' type: #'AbstractInstruction *'>
	<var: 'jumpOutOfRange' type: #'AbstractInstruction *'>
	reg ~= ReceiverResultReg ifTrue:
		[cogit MoveR: reg R: TempReg.
		 jumpNotInt := self genJumpNotSmallIntegerInScratchReg: TempReg].
	cogit MoveR: reg R: TempReg.
	self genConvertSmallIntegerToIntegerInReg: TempReg.
	cogit CmpCq: (1 << 30) - 1 R: TempReg.
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
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genInnerPrimitiveIdentical: retNoffset orNotIf: orNot [
	| jumpImmediate jumpCmp |
	<var: #jumpCmp type: #'AbstractInstruction *'>
	<var: #jumpImmediate type: #'AbstractInstruction *'>
	cogit MoveR: Arg0Reg R: TempReg.
	jumpImmediate := self genJumpImmediateInScratchReg: TempReg.
	self genEnsureObjInRegNotForwarded: Arg0Reg scratchReg: TempReg.
	jumpImmediate jmpTarget:
		(cogit CmpR: Arg0Reg R: ReceiverResultReg).
	jumpCmp := orNot
					ifTrue: [cogit JumpZero: 0]
					ifFalse: [cogit JumpNonZero: 0].
	cogit annotate: (cogit MoveCw: objectMemory trueObject R: ReceiverResultReg)
		objRef: objectMemory trueObject.
	cogit RetN: retNoffset.
	jumpCmp jmpTarget: (cogit annotate: (cogit MoveCw: objectMemory falseObject R: ReceiverResultReg)
								objRef: objectMemory falseObject).
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
CogObjectRepresentationForSpur >> genInnerPrimitiveSize: retNoffset [
	| jumpImm jumpNotIndexable jumpIsContext |
	"c.f. StackInterpreter>>stSizeOf: lengthOf:baseHeader:format: fixedFieldsOf:format:length:"
	<var: #jumpImm type: #'AbstractInstruction *'>
	<var: #jumpNotIndexable type: #'AbstractInstruction *'>
	<var: #jumpIsContext type: #'AbstractInstruction *'>
	cogit MoveR: ReceiverResultReg R: TempReg.
	jumpImm := self genJumpImmediateInScratchReg: TempReg.
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

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpCharacterInScratchReg: reg [ 
	cogit AndCq: objectMemory tagMask R: reg.
	cogit CmpCq: objectMemory characterTag R: reg.
	^cogit JumpZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpImmediateInScratchReg: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit AndCq: objectMemory tagMask R: aRegister.
	^cogit JumpNonZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpNotCharacterInScratchReg: reg [ 
	cogit AndCq: objectMemory tagMask R: reg.
	cogit CmpCq: objectMemory characterTag R: reg.
	^cogit JumpNonZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genLoadSlot: index sourceReg: sourceReg destReg: destReg [
	cogit
		MoveMw: index * objectMemory wordSize + objectMemory baseHeaderSize
		r: sourceReg
		R: destReg.
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
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genStoreCheckReceiverReg: destReg valueReg: valueReg scratchReg: scratchReg [
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
	"N.B. MoveMb:r:R: does not zero other bits"
	cogit MoveMb: rememberedBitByteOffset r: destReg R: scratchReg.
	cogit AndCq: mask R: scratchReg.
	jmpAlreadyRemembered := cogit JumpNonZero: 0.
	"Remembered bit is not set.  Call store check to insert dest into remembered table."
	self assert: destReg == ReceiverResultReg.
	cogit
		CallRT: ceStoreCheckTrampoline
		registersToBeSavedMask: ((cogit registerMaskFor: valueReg)
										bitOr: cogit callerSavedRegMask).
	jmpImmediate jmpTarget:
	(jmpDestYoung jmpTarget:
	(jmpSourceOld jmpTarget:
	(jmpAlreadyRemembered jmpTarget:
		cogit Label))).
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genStoreImmediateInSourceReg: sourceReg slotIndex: index destReg: destReg [
	cogit MoveR: sourceReg
		   Mw: index * objectMemory wordSize + objectMemory baseHeaderSize
		   r: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genStoreSourceReg: sourceReg slotIndex: index destReg: destReg scratchReg: scratchReg [
	"do the store"
	cogit MoveR: sourceReg
		   Mw: index * objectMemory wordSize + objectMemory baseHeaderSize
		   r: destReg.
	"now the check"
	^self genStoreCheckReceiverReg: destReg valueReg: sourceReg scratchReg: scratchReg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genStoreSourceReg: sourceReg slotIndex: index intoNewObjectInDestReg: destReg [
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
	ceStoreCheckTrampoline := cogit
									genTrampolineFor: #remember:
									called: 'ceStoreCheckTrampoline'
									arg: ReceiverResultReg
									result: cogit returnRegForStoreCheck.
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
CogObjectRepresentationForSpur >> markAndTraceCacheTagLiteral: literal in: cogMethodOrNil atpc: address [
	"Mark and trace a literal in an inline cache preceeding address in cogMethodOrNil.
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
	cogit backEnd rewriteInlineCacheTag: objOop at: address.
	self markAndTraceUpdatedLiteral: objOop in: cogMethodOrNil.
	^true
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
	"Mark and trace a literal in a machine code instruction preceeding address in cogMethodOrNil.
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
