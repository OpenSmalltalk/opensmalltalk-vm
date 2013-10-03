Class {
	#name : #CogObjectRepresentationFor32BitSpur,
	#superclass : #CogObjectRepresentationForSpur,
	#category : #'VMMaker-JIT'
}

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genAddSmallIntegerTagsTo: aRegister [
	cogit AddCq: 1 R: aRegister.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genConvertIntegerToSmallIntegerInScratchReg: scratchReg [
	cogit LogicalShiftLeftCq: 1 R: scratchReg.
	cogit AddCq: 1 R: scratchReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genConvertSmallIntegerToIntegerInScratchReg: scratchReg [
	cogit ArithmeticShiftRightCq: 1 R: scratchReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genGetClassTagOf: instReg into: destReg scratchReg: scratchReg [
	^self getInlineCacheClassTagFrom: instReg into: destReg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genGetHashFieldNonImmOf: instReg asSmallIntegerInto: destReg [
	"Fetch the instance's identity hash into destReg, encoded as a SmallInteger."
	"Get header word in scratchReg"
	cogit MoveMw: 4 r: instReg R: destReg.
	"Shift and mask the field leaving room for the SmallInteger tag."
	cogit AndCq: objectMemory identityHashHalfWordMask R: destReg.
	self genConvertIntegerToSmallIntegerInScratchReg: destReg.
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
	| jumpNotIndexable jumpSmallSize
	  jumpBytesDone jumpShortsDone jumpArrayDone jump32BitLongsDone
	  jumpIsBytes jumpHasFixedFields jumpIsShorts jumpIsContext  |
	<inline: true>
	"c.f. StackInterpreter>>stSizeOf: SpurMemoryManager>>lengthOf:format: fixedFieldsOf:format:length:"
	<var: #jumpIsBytes type: #'AbstractInstruction *'>
	<var: #jumpIsShorts type: #'AbstractInstruction *'>
	<var: #jumpSmallSize type: #'AbstractInstruction *'>
	<var: #jumpIsContext type: #'AbstractInstruction *'>
	<var: #jumpArrayDone type: #'AbstractInstruction *'>
	<var: #jumpNotIndexable type: #'AbstractInstruction *'>
	<var: #jumpHasFixedFields type: #'AbstractInstruction *'>
	<var: #jump32BitLongsDone type: #'AbstractInstruction *'>

	cogit
		MoveMw: 0 r: sourceReg R: formatReg;				"formatReg := least significant half of self baseHeader: receiver"
		MoveR: formatReg R: scratchReg;
		LogicalShiftRightCq: objectMemory formatShift R: formatReg;
		AndCq: objectMemory formatMask R: formatReg.	"formatReg := self formatOfHeader: destReg"

	"get numSlots into destReg."
	cogit MoveCq: 0 R: destReg. "N.B. MoveMb:r:R: does not zero other bits"
	cogit MoveMb: 7 r: sourceReg R: destReg. "MSB of header"
	cogit CmpCq: objectMemory numSlotsMask R: destReg.
	jumpSmallSize := cogit JumpLess: 0.
	cogit MoveMw: -8 r: sourceReg R: destReg. "LSW of overflow size header"

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
	jumpSmallSize jmpTarget:
					(cogit CmpCq: objectMemory firstByteFormat R: formatReg).
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
	self genConvertSmallIntegerToIntegerInScratchReg: formatReg.
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
	"Implement the guts of primitiveAt; dispatch on size"
	<returnTypeC: #'AbstractInstruction *'>
	| formatReg jumpNotIndexable jumpSmallSize jumpImmediate jumpBadIndex
	  jumpBytesDone jumpShortsDone jumpWordsDone jumpFixedFieldsDone
	  jumpIsBytes jumpIsShorts jumpIsWords jumpWordTooBig jumpIsArray jumpHasFixedFields jumpIsContext
	  jumpBytesOutOfBounds jumpShortsOutOfBounds jumpWordsOutOfBounds jumpArrayOutOfBounds jumpFixedFieldsOutOfBounds |
	<inline: true>
	"c.f. StackInterpreter>>stSizeOf: SpurMemoryManager>>lengthOf:format: fixedFieldsOf:format:length:"
	<var: #jumpIsBytes type: #'AbstractInstruction *'>
	<var: #jumpIsShorts type: #'AbstractInstruction *'>
	<var: #jumpBadIndex type: #'AbstractInstruction *'>
	<var: #jumpSmallSize type: #'AbstractInstruction *'>
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
	jumpBadIndex := self genJumpNotSmallIntegerInScratchReg: TempReg.
	self genConvertSmallIntegerToIntegerInScratchReg: Arg0Reg.
	cogit SubCq: 1 R: Arg0Reg. "1-rel => 0-rel"

	formatReg := SendNumArgsReg.
	cogit
		MoveMw: 0 r: ReceiverResultReg R: formatReg;				"formatReg := least significant half of self baseHeader: receiver"
		MoveR: formatReg R: TempReg;
		LogicalShiftRightCq: objectMemory formatShift R: formatReg;
		AndCq: objectMemory formatMask R: formatReg.	"formatReg := self formatOfHeader: destReg"

	"get numSlots into ClassReg."
	cogit MoveCq: 0 R: ClassReg. "N.B. MoveMb:r:R: does not zero other bits"
	cogit MoveMb: 7 r: ReceiverResultReg R: ClassReg. "MSB of header"
	cogit CmpCq: objectMemory numSlotsMask R: ClassReg.
	jumpSmallSize := cogit JumpLess: 0.
	cogit MoveMw: -8 r: ReceiverResultReg R: ClassReg. "LSW of overflow size header"

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
	jumpSmallSize jmpTarget:
					(cogit CmpCq: objectMemory firstByteFormat R: formatReg).
	jumpIsBytes := cogit JumpGreaterOrEqual: 0.
					cogit CmpCq: objectMemory arrayFormat R: formatReg.
	jumpIsArray := cogit JumpZero: 0.
	jumpNotIndexable := cogit JumpLess: 0.
					cogit CmpCq: objectMemory weakArrayFormat R: formatReg.
	jumpHasFixedFields := cogit JumpLessOrEqual: 0.
					cogit CmpCq: objectMemory firstShortFormat R: formatReg.
	jumpIsShorts := cogit JumpGreaterOrEqual: 0.
					cogit CmpCq: objectMemory firstLongFormat R: formatReg.
	jumpIsWords := cogit JumpGreaterOrEqual: 0.
	"For now ignore 64-bit indexability."
	jumpNotIndexable jmpTarget: cogit Label.
	jumpNotIndexable := cogit Jump: 0.

	jumpIsBytes jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord R: ClassReg).
		cogit AndCq: objectMemory wordSize - 1 R: formatReg.
		cogit SubR: formatReg R: ClassReg;
		CmpR: Arg0Reg R: ClassReg.
	jumpBytesOutOfBounds := cogit JumpAboveOrEqual: 0.
	cogit AddCq: objectMemory baseHeaderSize R: Arg0Reg.
	cogit MoveXbr: Arg0Reg R: ReceiverResultReg R: ReceiverResultReg.
	self genConvertIntegerToSmallIntegerInScratchReg: ReceiverResultReg.
	jumpBytesDone := cogit Jump: 0.

	jumpIsShorts jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord - 1 R: ClassReg).
		cogit AndCq: 1 R: formatReg.
		cogit SubR: formatReg R: ClassReg;
		CmpR: Arg0Reg R: ClassReg.
	jumpShortsOutOfBounds := cogit JumpAboveOrEqual: 0.
	cogit AddR: Arg0Reg R: ReceiverResultReg.
	cogit MoveM16: objectMemory baseHeaderSize r: ReceiverResultReg R: ReceiverResultReg.
	self genConvertIntegerToSmallIntegerInScratchReg: ReceiverResultReg.
	jumpShortsDone := cogit Jump: 0.

	jumpIsWords jmpTarget:
		(cogit CmpR: Arg0Reg R: ClassReg).
	jumpWordsOutOfBounds := cogit JumpAboveOrEqual: 0.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg0Reg.
	cogit MoveXwr: Arg0Reg R: ReceiverResultReg R: TempReg.
	cogit SubCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg0Reg.
	jumpWordTooBig := self jumpNotSmallIntegerUnsignedValueInRegister: TempReg.
	cogit MoveR: TempReg R: ReceiverResultReg.
	self genConvertIntegerToSmallIntegerInScratchReg: ReceiverResultReg.
	jumpWordsDone := cogit Jump: 0.

	jumpHasFixedFields jmpTarget:
		(cogit AndCq: objectMemory classIndexMask R: TempReg).
	cogit CmpCq: ClassMethodContextCompactIndex R: TempReg.
	cogit MoveR: TempReg R: formatReg.
	cogit CmpCq: ClassMethodContextCompactIndex R: TempReg.
	jumpIsContext := cogit JumpZero: 0.
	cogit PushR: ClassReg.
	self genGetClassObjectOfClassIndex: formatReg into: ClassReg scratchReg: TempReg.
	self genLoadSlot: InstanceSpecificationIndex sourceReg: ClassReg destReg: formatReg.
	cogit PopR: ClassReg.
	self genConvertSmallIntegerToIntegerInScratchReg: formatReg.
	cogit
		AndCq: objectMemory fixedFieldsOfClassFormatMask R: formatReg;
		SubR: formatReg R: ClassReg;
		CmpR: Arg0Reg R: ClassReg.
	jumpFixedFieldsOutOfBounds := cogit JumpAboveOrEqual: 0.
	"index is (formatReg (fixed fields) + Arg0Reg (0-rel index)) * wordSize + baseHeaderSize"
	cogit AddR: formatReg R: Arg0Reg.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg0Reg.
	cogit MoveXwr: Arg0Reg R: ReceiverResultReg R: ReceiverResultReg.
	jumpFixedFieldsDone := cogit Jump: 0.

	jumpIsArray jmpTarget:
		(cogit CmpR: Arg0Reg R: ClassReg).
	jumpArrayOutOfBounds := cogit JumpAboveOrEqual: 0.	
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg0Reg.
	cogit MoveXwr: Arg0Reg R: ReceiverResultReg R: ReceiverResultReg.

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
	(jumpIsContext jmpTarget: cogit Label))))))).

	cogit AddCq: 1 R: Arg0Reg. "0-rel => 1-rel"
	self genConvertIntegerToSmallIntegerInScratchReg: Arg0Reg.

	(jumpBadIndex jmpTarget: (jumpImmediate jmpTarget: cogit Label)).

	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> genInnerPrimitiveStringAt: retNoffset [
	"Implement the guts of primitiveStringAt; dispatch on size"
	<returnTypeC: #'AbstractInstruction *'>
	| formatReg jumpNotIndexable jumpSmallSize jumpBadIndex done
	  jumpIsBytes jumpIsShorts jumpIsWords jumpWordTooBig
	  jumpBytesOutOfBounds jumpShortsOutOfBounds jumpWordsOutOfBounds |
	<inline: true>
	"c.f. StackInterpreter>>stSizeOf: SpurMemoryManager>>lengthOf:format: fixedFieldsOf:format:length:"
	<var: #done type: #'AbstractInstruction *'>
	<var: #jumpIsBytes type: #'AbstractInstruction *'>
	<var: #jumpIsShorts type: #'AbstractInstruction *'>
	<var: #jumpIsWords type: #'AbstractInstruction *'>
	<var: #jumpBadIndex type: #'AbstractInstruction *'>
	<var: #jumpSmallSize type: #'AbstractInstruction *'>
	<var: #jumpWordTooBig type: #'AbstractInstruction *'>
	<var: #jumpNotIndexable type: #'AbstractInstruction *'>
	<var: #jumpBytesOutOfBounds type: #'AbstractInstruction *'>
	<var: #jumpShortsOutOfBounds type: #'AbstractInstruction *'>
	<var: #jumpWordsOutOfBounds type: #'AbstractInstruction *'>

	cogit MoveR: Arg0Reg R: TempReg.
	jumpBadIndex := self genJumpNotSmallIntegerInScratchReg: TempReg.
	self genConvertSmallIntegerToIntegerInScratchReg: Arg0Reg.
	cogit SubCq: 1 R: Arg0Reg. "1-rel => 0-rel"

	formatReg := SendNumArgsReg.
	cogit
		MoveMw: 0 r: ReceiverResultReg R: formatReg;				"formatReg := least significant half of self baseHeader: receiver"
		MoveR: formatReg R: TempReg;
		LogicalShiftRightCq: objectMemory formatShift R: formatReg;
		AndCq: objectMemory formatMask R: formatReg.	"formatReg := self formatOfHeader: destReg"

	"get numSlots into ClassReg."
	cogit MoveCq: 0 R: ClassReg. "N.B. MoveMb:r:R: does not zero other bits"
	cogit MoveMb: 7 r: ReceiverResultReg R: ClassReg. "MSB of header"
	cogit CmpCq: objectMemory numSlotsMask R: ClassReg.
	jumpSmallSize := cogit JumpLess: 0.
	cogit MoveMw: -8 r: ReceiverResultReg R: ClassReg. "LSW of overflow size header"

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
	jumpSmallSize jmpTarget:
					(cogit CmpCq: objectMemory firstByteFormat R: formatReg).
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
		CmpR: Arg0Reg R: ClassReg.
	jumpBytesOutOfBounds := cogit JumpAboveOrEqual: 0.
	cogit AddCq: objectMemory baseHeaderSize R: Arg0Reg.
	cogit MoveXbr: Arg0Reg R: ReceiverResultReg R: ReceiverResultReg.
	done := cogit Label.
	self genConvertIntegerToCharacterInScratchReg: ReceiverResultReg.
	cogit RetN: retNoffset.

	jumpIsShorts jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord - 1 R: ClassReg).
		cogit AndCq: 1 R: formatReg.
		cogit SubR: formatReg R: ClassReg;
		CmpR: Arg0Reg R: ClassReg.
	jumpShortsOutOfBounds := cogit JumpAboveOrEqual: 0.
	cogit AddR: Arg0Reg R: ReceiverResultReg.
	cogit MoveM16: objectMemory baseHeaderSize r: ReceiverResultReg R: ReceiverResultReg.
	cogit Jump: done.

	jumpIsWords jmpTarget:
		(cogit CmpR: Arg0Reg R: ClassReg).
	jumpWordsOutOfBounds := cogit JumpAboveOrEqual: 0.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg0Reg.
	cogit MoveXwr: Arg0Reg R: ReceiverResultReg R: TempReg.
	cogit SubCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg0Reg.
	jumpWordTooBig := self jumpNotCharacterUnsignedValueInRegister: TempReg.
	cogit MoveR: TempReg R: ReceiverResultReg.
	cogit Jump: done.

	jumpBytesOutOfBounds jmpTarget:
	(jumpShortsOutOfBounds jmpTarget:
	(jumpWordsOutOfBounds jmpTarget:
	(jumpWordTooBig jmpTarget:
	(jumpNotIndexable jmpTarget: cogit Label)))).

	cogit AddCq: 1 R: Arg0Reg. "0-rel => 1-rel"
	self genConvertIntegerToSmallIntegerInScratchReg: Arg0Reg.

	jumpBadIndex jmpTarget: cogit Label.

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

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> getInlineCacheClassTagFrom: sourceReg into: destReg [
	"Extract the inline cache tag for the object in sourceReg into destReg. The inline
	 cache tag for a given object is the value loaded in inline caches to distinguish objects
	 of different classes.  In Spur this is either the tags for immediates, (with 1 & 3 collapsed
	 to 1 for SmallIntegers), or the receiver's classIndex.  Generate something like this:
		Limm:
			andl $0x1, rDest
			j Lcmp
		Lentry:
			movl rSource, rDest
			andl $0x3, rDest
			jnz Limm
			movl 0x4(%edx), rDest
			andl $0x3fffff, rDest
		Lcmp
	"
	| immLabel entryLabel jumpCompare |
	<var: #immLabel type: #'AbstractInstruction *'>
	<var: #entryLabel type: #'AbstractInstruction *'>
	<var: #jumpCompare type: #'AbstractInstruction *'>
	cogit AlignmentNops: BytesPerWord.
	immLabel := cogit Label.
	cogit AndCq: 1 R: destReg.
	jumpCompare := cogit Jump: 0.
	cogit AlignmentNops: BytesPerWord.
	entryLabel := cogit Label.
	cogit MoveR: sourceReg R: destReg.
	cogit AndCq: objectMemory tagMask R: destReg.
	cogit JumpNonZero: immLabel.
	self flag: #endianness.
	"Get least significant half of header word in destReg"
	cogit MoveMw: 0 r: sourceReg R: destReg.
	cogit AndCq: objectMemory classIndexMask R: destReg.
	jumpCompare jmpTarget: cogit Label.
	^entryLabel
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> jumpNotSmallIntegerUnsignedValueInRegister: reg [
	cogit CmpCq: 16r3FFFFFFF R: reg.
	^cogit JumpAbove: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> numSmallIntegerBits [
	^31
]
