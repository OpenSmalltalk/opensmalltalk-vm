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
CogObjectRepresentationFor32BitSpur >> genConvertIntegerToSmallIntegerInReg: reg [
	cogit LogicalShiftLeftCq: 1 R: reg.
	cogit AddCq: 1 R: reg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genConvertIntegerToSmallIntegerInScratchReg: scratchReg [
	cogit LogicalShiftLeftCq: 1 R: scratchReg.
	cogit AddCq: 1 R: scratchReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genConvertSmallIntegerToIntegerInReg: reg [
	cogit ArithmeticShiftRightCq: 1 R: reg.
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
	cogit MoveR: Arg0Reg R: Arg1Reg.
	jumpBadIndex := self genJumpNotSmallIntegerInScratchReg: TempReg.
	self genConvertSmallIntegerToIntegerInReg: Arg1Reg.
	cogit SubCq: 1 R: Arg1Reg. "1-rel => 0-rel"

	formatReg := SendNumArgsReg.
	cogit
		MoveMw: 0 r: ReceiverResultReg R: formatReg;		"formatReg := least significant half of self baseHeader: receiver"
		MoveR: formatReg R: TempReg;
		LogicalShiftRightCq: objectMemory formatShift R: formatReg;
		AndCq: objectMemory formatMask R: formatReg.	"formatReg := self formatOfHeader: destReg"

	"get numSlots into ClassReg."
	cogit MoveCq: 0 R: ClassReg. "N.B. MoveMb:r:R: does not zero other bits"
	cogit MoveMb: 7 r: ReceiverResultReg R: ClassReg. "MSB of header"
	cogit CmpCq: objectMemory numSlotsMask R: ClassReg.
	jumpSmallSize := cogit JumpBelow: 0.
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
	self genConvertIntegerToSmallIntegerInScratchReg: ReceiverResultReg.
	jumpShortsDone := cogit Jump: 0.

	jumpIsWords jmpTarget:
		(cogit CmpR: Arg1Reg R: ClassReg).
	jumpWordsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg1Reg.
	cogit MoveXwr: Arg1Reg R: ReceiverResultReg R: TempReg.
	cogit SubCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg1Reg.
	jumpWordTooBig := self jumpNotSmallIntegerUnsignedValueInRegister: TempReg.
	cogit MoveR: TempReg R: ReceiverResultReg.
	self genConvertIntegerToSmallIntegerInScratchReg: ReceiverResultReg.
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
	  jumpSmallSize jumpNotIndexablePointers jumpNotIndexableBits
	  jumpIsContext jumpIsCompiledMethod jumpIsBytes jumpHasFixedFields
	  jumpArrayOutOfBounds jumpFixedFieldsOutOfBounds
	  jumpWordsOutOfBounds jumpBytesOutOfBounds jumpBytesOutOfRange
	  jumpNonSmallIntegerValue jumpShortsUnsupported jumpNotPointers
	  |
	<inline: true>
	"c.f. StackInterpreter>>stSizeOf: SpurMemoryManager>>lengthOf:format: fixedFieldsOf:format:length:"
	<var: #jumpIsBytes type: #'AbstractInstruction *'>
	<var: #jumpBadIndex type: #'AbstractInstruction *'>
	<var: #jumpSmallSize type: #'AbstractInstruction *'>
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

	formatReg := SendNumArgsReg.
	cogit
		MoveMw: 0 r: ReceiverResultReg R: formatReg;		"formatReg := least significant half of self baseHeader: receiver"
		MoveR: formatReg R: TempReg;
		LogicalShiftRightCq: objectMemory formatShift R: formatReg;
		AndCq: objectMemory formatMask R: formatReg.	"formatReg := self formatOfHeader: destReg"

	"get numSlots into ClassReg."
	cogit MoveCq: 0 R: ClassReg. "N.B. MoveMb:r:R: does not zero other bits"
	cogit MoveMb: 7 r: ReceiverResultReg R: ClassReg. "MSB of header"
	cogit CmpCq: objectMemory numSlotsMask R: ClassReg.
	jumpSmallSize := cogit JumpBelow: 0.
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
					(cogit CmpCq: objectMemory weakArrayFormat R: formatReg).
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
	self genConvertIntegerToSmallIntegerInScratchReg: Arg0Reg.

	jumpBadIndex jmpTarget: (jumpImmediate jmpTarget: cogit Label).

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
	cogit MoveCq: 0 R: TempReg.
	cogit PushR: TempReg.
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
	cogit MoveCq: 0 R: TempReg.
	cogit PushR: TempReg.
	jumpBytePrepDone := cogit Jump: 0. "go allocate"

	jumpArrayFormat jmpTarget:
		(cogit CmpCq: (objectMemory integerObjectOf: maxSlots) R: Arg0Reg).
	jumpArrayTooBig := cogit JumpAbove: 0.
	"save num elements/slot size to instSpecReg"
	cogit MoveR: TempReg R: instSpecReg.
	"push fill value"
	cogit MoveCw: objectMemory nilObject R: TempReg.
	cogit PushR: TempReg.
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
	cogit MoveR: Arg0Reg R: Arg1Reg.
	jumpBadIndex := self genJumpNotSmallIntegerInScratchReg: TempReg.
	self genConvertSmallIntegerToIntegerInReg: Arg1Reg.
	cogit SubCq: 1 R: Arg1Reg. "1-rel => 0-rel"

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
	| formatReg jumpSmallSize jumpImmediate jumpBadIndex jumpBadArg
	  jumpWordsDone jumpBytesOutOfRange
	  jumpIsBytes jumpNotString jumpIsCompiledMethod
	  jumpBytesOutOfBounds jumpWordsOutOfBounds jumpShortsUnsupported |
	<inline: true>
	"c.f. StackInterpreter>>stSizeOf: SpurMemoryManager>>lengthOf:format: fixedFieldsOf:format:length:"
	<var: #jumpBadArg type: #'AbstractInstruction *'>
	<var: #jumpIsBytes type: #'AbstractInstruction *'>
	<var: #jumpBadIndex type: #'AbstractInstruction *'>
	<var: #jumpSmallSize type: #'AbstractInstruction *'>
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

	formatReg := SendNumArgsReg.
	cogit
		MoveMw: 0 r: ReceiverResultReg R: formatReg;		"formatReg := least significant half of self baseHeader: receiver"
		MoveR: formatReg R: TempReg;
		LogicalShiftRightCq: objectMemory formatShift R: formatReg;
		AndCq: objectMemory formatMask R: formatReg.	"formatReg := self formatOfHeader: destReg"

	"get numSlots into ClassReg."
	cogit MoveCq: 0 R: ClassReg. "N.B. MoveMb:r:R: does not zero other bits"
	cogit MoveMb: 7 r: ReceiverResultReg R: ClassReg. "MSB of header"
	cogit CmpCq: objectMemory numSlotsMask R: ClassReg.
	jumpSmallSize := cogit JumpBelow: 0.
	cogit MoveMw: -8 r: ReceiverResultReg R: ClassReg. "LSW of overflow size header"

	"dispatch on format; words and/or bytes.
		  0 to 8 = pointer objects, forwarders, reserved.
		  9 (?) 64-bit indexable
		10 - 11 32-bit indexable
		12 - 15 16-bit indexable (but unused)
		16 - 23 byte indexable
		24 - 31 compiled method"
	jumpSmallSize jmpTarget:
					(cogit CmpCq: objectMemory firstLongFormat R: formatReg).
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
	self genConvertIntegerToSmallIntegerInScratchReg: Arg0Reg.

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
	 cache tag for a given object is the value loaded in inline caches to distinguish
	 objects of different classes.  In Spur this is either the tags for immediates, (with
	 1 & 3 collapsed to 1 for SmallIntegers, and 2 collapsed to 0 for Characters), or
	 the receiver's classIndex.  Generate something like this:
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
	 At least on a 2.2GHz Intel Core i7 it is slightly faster,
	 136m sends/sec vs 130m sends/sec for nfib in tinyBenchmarks, than
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
	"
	| jumpNotImm entryLabel jumpCompare |
	<var: #jumpNotImm type: #'AbstractInstruction *'>
	<var: #entryLabel type: #'AbstractInstruction *'>
	<var: #jumpCompare type: #'AbstractInstruction *'>
	cogit AlignmentNops: (BytesPerWord max: 8).
	entryLabel := cogit Label.
	cogit MoveR: sourceReg R: destReg.
	cogit AndCq: objectMemory tagMask R: destReg.
	jumpNotImm := cogit JumpZero: 0.
	cogit AndCq: 1 R: destReg.
	jumpCompare := cogit Jump: 0.
	"Get least significant half of header word in destReg"
	self flag: #endianness.
	jumpNotImm jmpTarget:
		(cogit MoveMw: 0 r: sourceReg R: destReg).
	jumpCompare jmpTarget:
		(cogit AndCq: objectMemory classIndexMask R: destReg).
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

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> numSmallIntegerTagBits [
	^1
]
