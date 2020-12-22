Class {
	#name : #CogObjectRepresentationFor32BitSpur,
	#superclass : #CogObjectRepresentationForSpur,
	#instVars : [
		'ceSigned32BitIntegerTrampoline',
		'ceSigned32BitValueOfTrampoline',
		'cePositive32BitValueOfTrampoline',
		'cePositive32BitIntegerTrampoline'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'accessing class hierarchy' }
CogObjectRepresentationFor32BitSpur class >> defaultObjectMemoryClass [
	"For in-image compilation."
	^Spur32BitCoMemoryManager
]

{ #category : #'sista support' }
CogObjectRepresentationFor32BitSpur >> allImmediate: immediateMask branchIf: reg instanceOfBehaviors: arrayObj target: targetFixUp [
	< inline: true>	
	<var: #targetFixUp type: #'AbstractInstruction *'>
	self assert: immediateMask = objectMemory tagMask.
	(self genJumpImmediate: reg) jmpTarget: targetFixUp.
	^0
]

{ #category : #'sista support' }
CogObjectRepresentationFor32BitSpur >> allImmediate: immediateMask branchIf: reg notInstanceOfBehaviors: arrayObj target: targetFixUp [
	< inline: true>	
	<var: #targetFixUp type: #'AbstractInstruction *'>
	self assert: immediateMask = objectMemory tagMask.
	(self genJumpNotImmediate: reg) jmpTarget: targetFixUp.
	^0
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

{ #category : #'sista support' }
CogObjectRepresentationFor32BitSpur >> branch2CasesIf: reg instanceOfBehaviors: arrayObj target: targetFixUp [
	<inline: true>
	self Jump: targetFixUp
]

{ #category : #'sista support' }
CogObjectRepresentationFor32BitSpur >> branch2CasesIf: reg notInstanceOfBehaviors: arrayObj target: targetFixUp [
	"nothing to do, 2 immediates so all immediates are allowed"
	<inline: true>
]

{ #category : #'sista support' }
CogObjectRepresentationFor32BitSpur >> branchIf: reg hasImmediateTag: classIndex target: targetFixUp [
	<var: #targetFixUp type: #'AbstractInstruction *'>
	| jmpImmediate|
	<inline: true>
	classIndex = objectMemory smallIntegerTag ifTrue:
		[jmpImmediate := self genJumpSmallInteger: reg].
	classIndex = objectMemory characterTag ifTrue:
		[cogit MoveR: reg R: TempReg.
		 jmpImmediate := self genJumpCharacterInScratchReg: reg].
	jmpImmediate jmpTarget: targetFixUp
]

{ #category : #'sista support' }
CogObjectRepresentationFor32BitSpur >> branchIf: reg hasNotImmediateTag: classIndex target: targetFixUp [
	<var: #targetFixUp type: #'AbstractInstruction *'>
	| jmpImmediate |
	<inline: true>
	classIndex = objectMemory smallIntegerTag ifTrue:
		[jmpImmediate := self genJumpNotSmallInteger: reg].
	classIndex = objectMemory characterTag ifTrue:
		["Character test destroy register value in Spur"
		 cogit MoveR: reg R: TempReg.
		 jmpImmediate := self genJumpNotCharacterInScratchReg: TempReg].
	jmpImmediate jmpTarget: targetFixUp
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationFor32BitSpur >> classForInlineCacheTag: inlineCacheTag [
	"Character gets mapped to zero.  See inlineCacheTagForInstance:."
	^objectMemory classOrNilAtIndex: (inlineCacheTag = 0
											ifTrue: [objectMemory characterTag]
											ifFalse: [inlineCacheTag])
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genAddSmallIntegerTagsTo: aRegister [
	cogit AddCq: 1 R: aRegister.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genClearAndSetSmallIntegerTagsIn: scratchReg [
	"Set the SmallInteger tag bits when the tag bits may be filled with garbage."
	^self genSetSmallIntegerTagsIn: scratchReg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genConvertCharacterToSmallIntegerInReg: reg [
	"Convert the Character in reg to a SmallInteger, assuming
	 the Character's value is a valid character."
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

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genFetchIndexRegister: indexReg from: tableObj into: destReg [
	"indexReg contains the 1-relative index of an element in tableObj.
	 Since BaseHeaderSize > BytesPerOop we must adjust it to use
	 it as a zero-relative index from the beginning of the object."
	self assert: indexReg ~= destReg.
	cogit AddCq: objectMemory baseHeaderSize / objectMemory wordSize - 1 R: indexReg.
	cogit genMoveConstant: tableObj R: destReg.
	cogit MoveXwr: indexReg R: destReg R: destReg.
	^0
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
	 If forEntry is true, generate something like this:
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
	 If forEntry is false, generate something like the following.
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
	self genGetBits: 3 ofFormatByteOf: srcReg into: TempReg.
	"Now: fmt bitAnd: 3 in TempReg"
	cogit SubR: TempReg R: destReg.
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
	  jumpBytesDone jumpShortsDone jumpArrayDone jump32BitLongsDone jump64BitLongsDone
	  jumpIsBytes jumpHasFixedFields jumpIsShorts jumpIs64BitLongs jumpIsContext  |
	<inline: true>
	"c.f. StackInterpreter>>stSizeOf: SpurMemoryManager>>lengthOf:format: fixedFieldsOf:format:length:"

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
		  9 64-bit indexable
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
					cogit CmpCq: objectMemory sixtyFourBitIndexableFormat R: formatReg.
	jumpIs64BitLongs := cogit JumpZero: 0.
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

	jumpIs64BitLongs jmpTarget:
		(cogit LogicalShiftRightCq: 1 R: destReg).
	jump64BitLongsDone := cogit Jump: 0.

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
	(jump64BitLongsDone jmpTarget:
	(jump32BitLongsDone jmpTarget:
	(jumpShortsDone jmpTarget:
	(jumpBytesDone jmpTarget:
		cogit Label)))).
	aBinaryBlock value: jumpNotIndexable value: jumpIsContext
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genJumpIsSmallIntegerValue: aRegister scratch: scratchReg [
	"Generate a test for aRegister containing an integer value in the SmallInteger range, and a jump if so, answering the jump.
	 c.f. Spur32BitMemoryManager>>isIntegerValue:"
	<returnTypeC: #'AbstractInstruction *'>
	^cogit
		MoveR: aRegister R: scratchReg;
		LogicalShiftLeftCq: 1 R: scratchReg;
		XorR: aRegister R: scratchReg;
		JumpGreaterOrEqual: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genJumpNotSmallInteger: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit TstCq: 1 R: aRegister.
	^cogit JumpZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genJumpNotSmallIntegerInScratchReg: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit AndCq: 1 R: aRegister.
	^cogit JumpZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genJumpNotSmallIntegerValue: aRegister scratch: scratchReg [
	"Generate a test for aRegister containing an integer value outside the SmallInteger range, and a jump if so, answering the jump.
	 c.f. Spur32BitMemoryManager>>isIntegerValue:"
	<returnTypeC: #'AbstractInstruction *'>
	^cogit
		MoveR: aRegister R: scratchReg;
		ArithmeticShiftRightCq: 1 R: scratchReg;
		XorR: aRegister R: scratchReg;
		JumpLess: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genJumpSmallInteger: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit TstCq: 1 R: aRegister.
	^cogit JumpNonZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genJumpSmallIntegerInScratchReg: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit AndCq: 1 R: aRegister.
	^cogit JumpNonZero: 0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> genPrimitiveAtPut [
	| formatReg nSlotsOrBytesReg methodInBounds
	  jumpImmediate jumpBadIndex jumpImmutable jumpNotIndexablePointers jumpNotIndexableBits
	  jumpIsContext jumpIsCompiledMethod jumpIsBytes jumpIsShorts jumpHasFixedFields
	  jumpArrayOutOfBounds jumpFixedFieldsOutOfBounds
	  jumpWordsOutOfBounds jumpShortsOutOfBounds jumpBytesOutOfBounds
	  jumpShortsOutOfRange jumpWordsOutOfRange jumpBytesOutOfRange
	  jumpNonSmallIntegerValue jumpNotPointers
	  |
	"c.f. StackInterpreter>>stSizeOf: SpurMemoryManager>>lengthOf:format: fixedFieldsOf:format:length:"
	<var: #jumpIsBytes type: #'AbstractInstruction *'>
	<var: #jumpIsShorts type: #'AbstractInstruction *'>
	<var: #jumpBadIndex type: #'AbstractInstruction *'>
	<var: #jumpIsContext type: #'AbstractInstruction *'>
	<var: #jumpImmediate type: #'AbstractInstruction *'>
	<var: #methodInBounds type: #'AbstractInstruction *'>
	<var: #jumpHasFixedFields type: #'AbstractInstruction *'>
	<var: #jumpNotIndexableBits type: #'AbstractInstruction *'>
	<var: #jumpBytesOutOfRange type: #'AbstractInstruction *'>
	<var: #jumpWordsOutOfRange type: #'AbstractInstruction *'>
	<var: #jumpShortsOutOfRange type: #'AbstractInstruction *'>
	<var: #jumpArrayOutOfBounds type: #'AbstractInstruction *'>
	<var: #jumpBytesOutOfBounds type: #'AbstractInstruction *'>
	<var: #jumpWordsOutOfBounds type: #'AbstractInstruction *'>
	<var: #jumpShortsOutOfBounds type: #'AbstractInstruction *'>
	<var: #jumpNotIndexablePointers type: #'AbstractInstruction *'>

	nSlotsOrBytesReg := ClassReg.

	cogit genLoadArgAtDepth: 1 into: Arg0Reg.
	cogit genLoadArgAtDepth: 0 into: Arg1Reg.
	jumpImmediate := self genJumpImmediate: ReceiverResultReg.
	jumpBadIndex := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	self genConvertSmallIntegerToIntegerInReg: Arg0Reg.
	cogit SubCq: 1 R: Arg0Reg. "1-rel => 0-rel"

	"formatReg := self formatOf: ReceiverResultReg"
	self cppIf: IMMUTABILITY
		ifTrue:
		[ self genGetFormatOf: ReceiverResultReg
			into: (formatReg := SendNumArgsReg)
			leastSignificantHalfOfBaseHeaderIntoScratch: TempReg.
		jumpImmutable := self genJumpBaseHeaderImmutable: TempReg ]
		ifFalse: 
		[ self genGetFormatOf: ReceiverResultReg
			into: (formatReg := SendNumArgsReg)
			leastSignificantHalfOfBaseHeaderIntoScratch: NoReg ].

	self genGetNumSlotsOf: ReceiverResultReg into: nSlotsOrBytesReg.

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
		  9 64-bit indexable
		10 - 11 32-bit indexable
		12 - 15 16-bit indexable
		16 - 23 byte indexable
		24 - 31 compiled method"
	cogit CmpCq: objectMemory weakArrayFormat R: formatReg.
	jumpNotPointers := cogit JumpAbove: 0.
	"optimistic store check; assume index in range (almost always is)."
	self genStoreCheckReceiverReg: ReceiverResultReg
		valueReg: Arg1Reg
		scratchReg: TempReg
		inFrame: false.

	cogit CmpCq: objectMemory arrayFormat R: formatReg.
	jumpNotIndexablePointers := cogit JumpBelow: 0.
	jumpHasFixedFields := cogit JumpNonZero: 0.
	cogit CmpR: Arg0Reg R: nSlotsOrBytesReg.
	jumpArrayOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg0Reg.
	cogit MoveR: Arg1Reg Xwr: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit genPrimReturn.

	jumpHasFixedFields jmpTarget: cogit Label.
	self genGetClassIndexOfNonImm: ReceiverResultReg into: formatReg.
	cogit CmpCq: ClassMethodContextCompactIndex R: formatReg.
	jumpIsContext := cogit JumpZero: 0.
	"get # fixed fields in formatReg"
	cogit PushR: nSlotsOrBytesReg.
	self genGetClassObjectOfClassIndex: formatReg into: nSlotsOrBytesReg scratchReg: TempReg.
	self genLoadSlot: InstanceSpecificationIndex sourceReg: nSlotsOrBytesReg destReg: formatReg.
	cogit PopR: nSlotsOrBytesReg.
	self genConvertSmallIntegerToIntegerInReg: formatReg.
	cogit AndCq: objectMemory fixedFieldsOfClassFormatMask R: formatReg.
	cogit SubR: formatReg R: nSlotsOrBytesReg.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: formatReg.
	cogit CmpR: Arg0Reg R: nSlotsOrBytesReg.
	jumpFixedFieldsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddR: formatReg R: Arg0Reg.
	cogit MoveR: Arg1Reg Xwr: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit genPrimReturn.

	jumpNotPointers jmpTarget: cogit Label.
	jumpNonSmallIntegerValue := self genJumpNotSmallInteger: Arg1Reg scratchReg: TempReg.
					cogit CmpCq: objectMemory firstByteFormat R: formatReg.
	jumpIsBytes := cogit JumpAboveOrEqual: 0.
					cogit CmpCq: objectMemory firstShortFormat R: formatReg.
	jumpIsShorts := cogit JumpAboveOrEqual: 0.
					cogit CmpCq: objectMemory firstLongFormat R: formatReg.
	"For now ignore 64-bit indexability."
	jumpNotIndexableBits := cogit JumpBelow: 0.

	"fall through to double words"
	cogit CmpR: Arg0Reg R: nSlotsOrBytesReg.
	jumpWordsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit MoveR: Arg1Reg R: TempReg.
	self genConvertSmallIntegerToIntegerInReg: TempReg.
	(cogit lastOpcode setsConditionCodesFor: JumpLess) ifFalse:
		[cogit CmpCq: 0 R: TempReg]. "N.B. FLAGS := TempReg - 0"
	jumpWordsOutOfRange := cogit JumpLess: 0.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg0Reg.
	cogit MoveR: TempReg Xwr: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit genPrimReturn.

	jumpIsBytes jmpTarget:
		(cogit CmpCq: (objectMemory integerObjectOf: 255) R: Arg1Reg).
	jumpBytesOutOfRange := cogit JumpAbove: 0.
	cogit LogicalShiftLeftCq: objectMemory shiftForWord R: nSlotsOrBytesReg.
	cogit AndCq: objectMemory wordSize - 1 R: formatReg R: TempReg.
	cogit SubR: TempReg R: nSlotsOrBytesReg.
	cogit CmpR: Arg0Reg R: nSlotsOrBytesReg.
	jumpBytesOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit CmpCq: objectMemory firstCompiledMethodFormat R: formatReg.
	jumpIsCompiledMethod := cogit JumpAboveOrEqual: 0.
	methodInBounds :=
	cogit MoveR: Arg1Reg R: TempReg.
	self genConvertSmallIntegerToIntegerInReg: TempReg.
	cogit AddCq: objectMemory baseHeaderSize R: Arg0Reg.
	cogit MoveR: TempReg Xbr: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit genPrimReturn.

	jumpIsShorts jmpTarget:
		(cogit CmpCq: (objectMemory integerObjectOf: 65535) R: Arg1Reg).
	jumpShortsOutOfRange := cogit JumpAbove: 0.
	cogit LogicalShiftLeftCq: objectMemory shiftForWord - 1 R: nSlotsOrBytesReg.
	cogit AndCq: objectMemory wordSize / 2 - 1 R: formatReg.
	cogit SubR: formatReg R: nSlotsOrBytesReg.
	cogit CmpR: Arg0Reg R: nSlotsOrBytesReg.
	jumpShortsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit MoveR: Arg1Reg R: TempReg.
	self genConvertSmallIntegerToIntegerInReg: TempReg.
	cogit AddR: Arg0Reg R: ReceiverResultReg.
	cogit AddR: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: TempReg M16: objectMemory baseHeaderSize r: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit genPrimReturn.

	"Now check that the index is beyond the method's literals..."
	jumpIsCompiledMethod jmpTarget: cogit Label.
	self getLiteralCountOf: ReceiverResultReg plusOne: true inBytes: true into: nSlotsOrBytesReg scratch: TempReg.
	cogit CmpR: Arg0Reg R: nSlotsOrBytesReg.
	cogit JumpBelow: methodInBounds.

	jumpIsContext jmpTarget: 
	(jumpNotIndexableBits jmpTarget:
	(jumpBytesOutOfRange jmpTarget:
	(jumpWordsOutOfRange jmpTarget:
	(jumpShortsOutOfRange jmpTarget:
	(jumpIsCompiledMethod jmpTarget:
	(jumpArrayOutOfBounds jmpTarget:
	(jumpBytesOutOfBounds jmpTarget:
	(jumpShortsOutOfBounds jmpTarget:
	(jumpWordsOutOfBounds jmpTarget:
	(jumpNotIndexablePointers jmpTarget:
	(jumpNonSmallIntegerValue jmpTarget:
	(jumpFixedFieldsOutOfBounds jmpTarget: cogit Label)))))))))))).
	
	self cppIf: IMMUTABILITY
		ifTrue: [jumpImmutable jmpTarget: jumpIsContext getJmpTarget].

	cogit AddCq: 1 R: Arg0Reg. "0-rel => 1-rel"
	self genConvertIntegerToSmallIntegerInReg: Arg0Reg.

	jumpBadIndex jmpTarget: (jumpImmediate jmpTarget: cogit Label).

	^0 "Can't be complete because of contexts."
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> genPrimitiveAtPutSigned: signedVersion [
	"Generate the code for primitives 61 & 165, at:put:/basicAt:put: & integerAt:put:.  If signedVersion is true
	 then generate signed accesses to the bits classes (a la 164 & 165).  If signedVersion is false,
	 generate unsigned accesses (a la 60, 61, 63 & 64)."
	| formatReg nSlotsOrBytesReg methodInBounds
	  jumpImmediate jumpBadIndex jumpImmutable jumpNotIndexablePointers jumpNotIndexableBits
	  jumpIsContext jumpIsCompiledMethod jumpIsBytes jumpIsShorts jumpHasFixedFields
	  jumpArrayOutOfBounds jumpFixedFieldsOutOfBounds
	  jumpWordsOutOfBounds jumpShortsOutOfBounds jumpBytesOutOfBounds
	  jumpShortsOutOfRange jumpWordsOutOfRange jumpBytesOutOfRange
	  jumpNonSmallIntegerValue jumpNotPointers
	  |
	"c.f. StackInterpreter>>stSizeOf: SpurMemoryManager>>lengthOf:format: fixedFieldsOf:format:length:"

	nSlotsOrBytesReg := ClassReg.

	cogit genLoadArgAtDepth: 1 into: Arg0Reg.
	cogit genLoadArgAtDepth: 0 into: Arg1Reg.
	jumpImmediate := self genJumpImmediate: ReceiverResultReg.
	jumpBadIndex := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	self genConvertSmallIntegerToIntegerInReg: Arg0Reg.
	cogit SubCq: 1 R: Arg0Reg. "1-rel => 0-rel"

	"formatReg := self formatOf: ReceiverResultReg"
	self cppIf: IMMUTABILITY
		ifTrue:
		[ self genGetFormatOf: ReceiverResultReg
			into: (formatReg := SendNumArgsReg)
			leastSignificantHalfOfBaseHeaderIntoScratch: TempReg.
		jumpImmutable := self genJumpBaseHeaderImmutable: TempReg ]
		ifFalse: 
		[ self genGetFormatOf: ReceiverResultReg
			into: (formatReg := SendNumArgsReg)
			leastSignificantHalfOfBaseHeaderIntoScratch: NoReg ].

	self genGetNumSlotsOf: ReceiverResultReg into: nSlotsOrBytesReg.

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
		  9 64-bit indexable
		10 - 11 32-bit indexable
		12 - 15 16-bit indexable
		16 - 23 byte indexable
		24 - 31 compiled method"
	cogit CmpCq: objectMemory weakArrayFormat R: formatReg.
	jumpNotPointers := cogit JumpAbove: 0.
	"optimistic store check; assume index in range (almost always is)."
	self genStoreCheckReceiverReg: ReceiverResultReg
		valueReg: Arg1Reg
		scratchReg: TempReg
		inFrame: false.

	cogit CmpCq: objectMemory arrayFormat R: formatReg.
	jumpNotIndexablePointers := cogit JumpBelow: 0.
	jumpHasFixedFields := cogit JumpNonZero: 0.
	cogit CmpR: Arg0Reg R: nSlotsOrBytesReg.
	jumpArrayOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg0Reg.
	cogit MoveR: Arg1Reg Xwr: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit genPrimReturn.

	jumpHasFixedFields jmpTarget: cogit Label.
	self genGetClassIndexOfNonImm: ReceiverResultReg into: formatReg.
	cogit CmpCq: ClassMethodContextCompactIndex R: formatReg.
	jumpIsContext := cogit JumpZero: 0.
	"get # fixed fields in formatReg"
	cogit PushR: nSlotsOrBytesReg.
	self genGetClassObjectOfClassIndex: formatReg into: nSlotsOrBytesReg scratchReg: TempReg.
	self genLoadSlot: InstanceSpecificationIndex sourceReg: nSlotsOrBytesReg destReg: formatReg.
	cogit PopR: nSlotsOrBytesReg.
	self genConvertSmallIntegerToIntegerInReg: formatReg.
	cogit AndCq: objectMemory fixedFieldsOfClassFormatMask R: formatReg.
	cogit SubR: formatReg R: nSlotsOrBytesReg.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: formatReg.
	cogit CmpR: Arg0Reg R: nSlotsOrBytesReg.
	jumpFixedFieldsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddR: formatReg R: Arg0Reg.
	cogit MoveR: Arg1Reg Xwr: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit genPrimReturn.

	jumpNotPointers jmpTarget: cogit Label.
	jumpNonSmallIntegerValue := self genJumpNotSmallInteger: Arg1Reg scratchReg: TempReg.
					cogit CmpCq: objectMemory firstByteFormat R: formatReg.
	jumpIsBytes := cogit JumpAboveOrEqual: 0.
					cogit CmpCq: objectMemory firstShortFormat R: formatReg.
	jumpIsShorts := cogit JumpAboveOrEqual: 0.
					cogit CmpCq: objectMemory firstLongFormat R: formatReg.
	"For now ignore 64-bit indexability."
	jumpNotIndexableBits := cogit JumpBelow: 0.

	"fall through to words"
	cogit CmpR: Arg0Reg R: nSlotsOrBytesReg.
	jumpWordsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit MoveR: Arg1Reg R: TempReg.
	self genConvertSmallIntegerToIntegerInReg: TempReg.
	signedVersion ifFalse:
		[(cogit lastOpcode setsConditionCodesFor: JumpLess) ifFalse:
			[cogit CmpCq: 0 R: TempReg]. "N.B. FLAGS := TempReg - 0"
		jumpWordsOutOfRange := cogit JumpLess: 0].
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg0Reg.
	cogit MoveR: TempReg Xwr: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit genPrimReturn.

	signedVersion
		ifTrue:
			[jumpIsBytes jmpTarget:
			 (cogit MoveR: SendNumArgsReg R: TempReg).
			 cogit ArithmeticShiftRightCq: 7 R: TempReg. "Maps in range to -1,0".
			 cogit AddCq: 1 R: TempReg. "Maps in range to 0,1"
			 cogit CmpCq: 1 R: TempReg]
		ifFalse:
			[jumpIsBytes jmpTarget:
			 (cogit CmpCq: (objectMemory integerObjectOf: 255) R: Arg1Reg)].
	jumpBytesOutOfRange := cogit JumpAbove: 0.
	cogit LogicalShiftLeftCq: objectMemory shiftForWord R: nSlotsOrBytesReg.
	cogit AndCq: objectMemory wordSize - 1 R: formatReg R: TempReg.
	cogit SubR: TempReg R: nSlotsOrBytesReg.
	cogit CmpR: Arg0Reg R: nSlotsOrBytesReg.
	jumpBytesOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit CmpCq: objectMemory firstCompiledMethodFormat R: formatReg.
	jumpIsCompiledMethod := cogit JumpAboveOrEqual: 0.
	methodInBounds :=
	cogit MoveR: Arg1Reg R: TempReg.
	self genConvertSmallIntegerToIntegerInReg: TempReg.
	cogit AddCq: objectMemory baseHeaderSize R: Arg0Reg.
	cogit MoveR: TempReg Xbr: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit genPrimReturn.

	signedVersion
		ifTrue:
			[jumpIsShorts jmpTarget:
			 (cogit MoveR: SendNumArgsReg R: TempReg).
			 cogit ArithmeticShiftRightCq: 15 R: TempReg. "Maps in range to -1,0".
			 cogit AddCq: 1 R: TempReg. "Maps in range to 0,1"
			 cogit CmpCq: 1 R: TempReg]
		ifFalse:
			[jumpIsShorts jmpTarget:
			 (cogit CmpCq: (objectMemory integerObjectOf: 65535) R: Arg1Reg)].
	jumpShortsOutOfRange := cogit JumpAbove: 0.
	cogit LogicalShiftLeftCq: objectMemory shiftForWord - 1 R: nSlotsOrBytesReg.
	cogit AndCq: objectMemory wordSize / 2 - 1 R: formatReg.
	cogit SubR: formatReg R: nSlotsOrBytesReg.
	cogit CmpR: Arg0Reg R: nSlotsOrBytesReg.
	jumpShortsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit MoveR: Arg1Reg R: TempReg.
	self genConvertSmallIntegerToIntegerInReg: TempReg.
	cogit AddR: Arg0Reg R: ReceiverResultReg.
	cogit AddR: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: TempReg M16: objectMemory baseHeaderSize r: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit genPrimReturn.

	"Now check that the index is beyond the method's literals..."
	jumpIsCompiledMethod jmpTarget: cogit Label.
	self getLiteralCountOf: ReceiverResultReg plusOne: true inBytes: true into: nSlotsOrBytesReg scratch: TempReg.
	cogit CmpR: Arg0Reg R: nSlotsOrBytesReg.
	cogit JumpBelow: methodInBounds.

	jumpIsContext jmpTarget: 
	(jumpNotIndexableBits jmpTarget:
	(jumpBytesOutOfRange jmpTarget:
	(jumpShortsOutOfRange jmpTarget:
	(jumpIsCompiledMethod jmpTarget:
	(jumpArrayOutOfBounds jmpTarget:
	(jumpBytesOutOfBounds jmpTarget:
	(jumpShortsOutOfBounds jmpTarget:
	(jumpWordsOutOfBounds jmpTarget:
	(jumpNotIndexablePointers jmpTarget:
	(jumpNonSmallIntegerValue jmpTarget:
	(jumpFixedFieldsOutOfBounds jmpTarget: cogit Label))))))))))).
	
	signedVersion ifFalse:
		[jumpWordsOutOfRange jmpTarget: jumpIsContext getJmpTarget].
	self cppIf: IMMUTABILITY
		ifTrue: [jumpImmutable jmpTarget: jumpIsContext getJmpTarget].

	cogit AddCq: 1 R: Arg0Reg. "0-rel => 1-rel"
	self genConvertIntegerToSmallIntegerInReg: Arg0Reg.

	jumpBadIndex jmpTarget: (jumpImmediate jmpTarget: cogit Label).

	^0 "Can't be complete because of contexts."
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> genPrimitiveAtSigned: signedVersion [
	"Generate the code for primitives 60 & 164, at:/basicAt: & integerAt:.  If signedVersion is true
	 then generate signed accesses to the bits classes (a la 164 & 165).  If signedVersion is false,
	 generate unsigned accesses (a la 60, 61, 63 & 64)."
	| formatReg nSlotsOrBytesReg convertToIntAndReturn methodInBounds
	  jumpNotIndexable jumpImmediate jumpBadIndex
	  jumpIsBytes jumpIsShorts jumpIsWords jumpIsMethod
	  jumpWordTooBig jumpIsArray jumpHasFixedFields jumpIsContext
	  jumpBytesOutOfBounds jumpShortsOutOfBounds jumpWordsOutOfBounds
	  jumpArrayOutOfBounds jumpFixedFieldsOutOfBounds |
	"c.f. StackInterpreter>>stSizeOf: SpurMemoryManager>>lengthOf:format: fixedFieldsOf:format:length:"

	nSlotsOrBytesReg := ClassReg.

	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	jumpImmediate := self genJumpImmediate: ReceiverResultReg.
	cogit MoveR: Arg0Reg R: Arg1Reg.
	jumpBadIndex := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	self genConvertSmallIntegerToIntegerInReg: Arg1Reg.
	cogit SubCq: 1 R: Arg1Reg. "1-rel => 0-rel"

	"formatReg := self formatOf: ReceiverResultReg"
	self genGetFormatOf: ReceiverResultReg
		into: (formatReg := SendNumArgsReg)
		leastSignificantHalfOfBaseHeaderIntoScratch: TempReg.

	self genGetNumSlotsOf: ReceiverResultReg into: nSlotsOrBytesReg.

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
		  9 64-bit indexable
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

	jumpIsArray jmpTarget:
		(cogit CmpR: Arg1Reg R: nSlotsOrBytesReg).
	jumpArrayOutOfBounds := cogit JumpBelowOrEqual: 0.	
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg1Reg.
	cogit MoveXwr: Arg1Reg R: ReceiverResultReg R: ReceiverResultReg.
	cogit genPrimReturn.

	jumpIsBytes jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord R: nSlotsOrBytesReg).
		cogit AndCq: objectMemory wordSize - 1 R: formatReg R: TempReg.
		cogit SubR: TempReg R: nSlotsOrBytesReg;
		CmpR: Arg1Reg R: nSlotsOrBytesReg.
	jumpBytesOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit CmpCq: objectMemory firstCompiledMethodFormat R: formatReg.
	jumpIsMethod := cogit JumpAboveOrEqual: 0.
	methodInBounds :=
	cogit AddCq: objectMemory baseHeaderSize R: Arg1Reg.
	(cogit backEnd byteReadsZeroExtend
	 or: [signedVersion])
		ifTrue:
			[cogit MoveXbr: Arg1Reg R: ReceiverResultReg R: ReceiverResultReg]
		ifFalse:
			[cogit "formatReg already contains a value <= 16r1f, so no need to zero it"
				MoveXbr: Arg1Reg R: ReceiverResultReg R: formatReg;
				MoveR: formatReg R: ReceiverResultReg].
	signedVersion ifTrue:
		[cogit SignExtend8R: ReceiverResultReg R: ReceiverResultReg].
	convertToIntAndReturn := cogit Label.
	self genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
	cogit genPrimReturn.

	jumpIsShorts jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord - 1 R: nSlotsOrBytesReg).
		cogit AndCq: 1 R: formatReg.
		cogit SubR: formatReg R: nSlotsOrBytesReg;
		CmpR: Arg1Reg R: nSlotsOrBytesReg.
	jumpShortsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddR: Arg1Reg R: ReceiverResultReg.
	cogit AddR: Arg1Reg R: ReceiverResultReg.
	cogit MoveM16: objectMemory baseHeaderSize r: ReceiverResultReg R: ReceiverResultReg.
	signedVersion ifTrue:
		[cogit SignExtend16R: ReceiverResultReg R: ReceiverResultReg].
	cogit Jump: convertToIntAndReturn.

	jumpIsWords jmpTarget:
		(cogit CmpR: Arg1Reg R: nSlotsOrBytesReg).
	jumpWordsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg1Reg.
	cogit MoveXwr: Arg1Reg R: ReceiverResultReg R: TempReg.
	jumpWordTooBig := self jumpNotSmallIntegerUnsignedValueInRegister: TempReg.
	cogit MoveR: TempReg R: ReceiverResultReg.
	cogit Jump: convertToIntAndReturn.

	jumpHasFixedFields jmpTarget:
		(cogit AndCq: objectMemory classIndexMask R: TempReg).
	cogit MoveR: TempReg R: formatReg.
	cogit CmpCq: ClassMethodContextCompactIndex R: TempReg.
	jumpIsContext := cogit JumpZero: 0.
	cogit PushR: nSlotsOrBytesReg.
	self genGetClassObjectOfClassIndex: formatReg into: nSlotsOrBytesReg scratchReg: TempReg.
	self genLoadSlot: InstanceSpecificationIndex sourceReg: nSlotsOrBytesReg destReg: formatReg.
	cogit PopR: nSlotsOrBytesReg.
	self genConvertSmallIntegerToIntegerInReg: formatReg.
	cogit
		AndCq: objectMemory fixedFieldsOfClassFormatMask R: formatReg;
		SubR: formatReg R: nSlotsOrBytesReg;
		CmpR: Arg1Reg R: nSlotsOrBytesReg.
	jumpFixedFieldsOutOfBounds := cogit JumpBelowOrEqual: 0.
	"index is (formatReg (fixed fields) + Arg1Reg (0-rel index)) * wordSize + baseHeaderSize"
	cogit AddR: formatReg R: Arg1Reg.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg1Reg.
	cogit MoveXwr: Arg1Reg R: ReceiverResultReg R: ReceiverResultReg.
	cogit genPrimReturn.

	jumpIsMethod jmpTarget: cogit Label.
	"Now check that the index is beyond the method's literals..."
	self getLiteralCountOf: ReceiverResultReg plusOne: true inBytes: true into: nSlotsOrBytesReg scratch: TempReg.
	cogit CmpR: Arg1Reg R: nSlotsOrBytesReg.
	cogit JumpBelow: methodInBounds.

	jumpWordTooBig jmpTarget:
	(jumpFixedFieldsOutOfBounds jmpTarget:
	(jumpArrayOutOfBounds jmpTarget:
	(jumpBytesOutOfBounds jmpTarget:
	(jumpShortsOutOfBounds jmpTarget:
	(jumpWordsOutOfBounds jmpTarget:
	(jumpNotIndexable jmpTarget:
	(jumpIsContext jmpTarget:
	(jumpBadIndex jmpTarget:
	(jumpImmediate jmpTarget: cogit Label))))))))).

	^0 "Can't be complete because of contexts."
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> genPrimitiveIdentityHash [
	"Arguably we should fail for immediates, but so far no one has complained, so..."
	| jumpImm jumpSI jumpNotSet ret |
	<var: #jumpSI type: #'AbstractInstruction *'>
	<var: #jumpImm type: #'AbstractInstruction *'>
	<var: #jumpNotSet type: #'AbstractInstruction *'>
	jumpImm := self genJumpImmediate: ReceiverResultReg.
	self genGetHashFieldNonImmOf: ReceiverResultReg asSmallIntegerInto: TempReg.
	cogit CmpCq: ConstZero R: TempReg.
	jumpNotSet := cogit JumpZero: 0.
	cogit MoveR: TempReg R: ReceiverResultReg.
	ret := cogit genPrimReturn.
	jumpImm jmpTarget: cogit Label.
	jumpSI := self genJumpSmallInteger: ReceiverResultReg.
	jumpSI jmpTarget: ret.
	self genConvertCharacterToSmallIntegerInReg: ReceiverResultReg.
	cogit Jump: ret.
	jumpNotSet jmpTarget: cogit Label.
	"For non-behaviors we can call ceNewHash to assign a fresh hash.
	 For behaviors we must fail into the interpreter primitive to enter the receiver into the class table."
	cogit getPrimitiveIndex = 75 ifFalse:
		[^0].
	cogit backEnd saveAndRestoreLinkRegAround:
		[cogit CallRT: ceNewHashTrampoline].
	cogit genPrimReturn.
	^UnfailingPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> genPrimitiveImmediateAsInteger [
	":Assume the receiuver is never a SmallInteger.  One would use ^self for that."
	self genConvertCharacterToSmallIntegerInReg: ReceiverResultReg.
	cogit genPrimReturn.
	^UnfailingPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> genPrimitiveNew [
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

	cogit methodNumArgs ~= 0 ifTrue:
		[^UnimplementedPrimitive].

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
	cogit genPrimReturn.

	jumpUnhashed jmpTarget:
	(jumpVariableOrEphemeron jmpTarget:
	(jumpTooBig jmpTarget:
	(jumpNoSpace jmpTarget: cogit Label))).

	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> genPrimitiveNewWithArg [
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

	cogit methodNumArgs ~= 1 ifTrue:
		[^UnimplementedPrimitive].
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.

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
	jumpNElementsNonInt := self genJumpNotSmallInteger: Arg0Reg.
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
	cogit genPrimReturn.

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
CogObjectRepresentationFor32BitSpur >> genPrimitiveShallowCopy [
	"Implement primitiveShallowCopy/primitiveClone for convenient cases:
	- the receiver is not a context
	- the receiver is not a compiled method
	- the result fits in eden (actually below scavengeThreshold)"

	| formatReg resultReg slotsReg ptrReg
	  jumpImmediate jumpIsMethod jumpVariable jumpTooBig jumpEmpty jumpNoSpace
	  continuance copyLoop |
	<var: #copyLoop type: #'AbstractInstruction *'>
	<var: #jumpTooBig type: #'AbstractInstruction *'>
	<var: #continuance type: #'AbstractInstruction *'>
	<var: #jumpVariable type: #'AbstractInstruction *'>
	<var: #jumpNoSpace type: #'AbstractInstruction *'>
	<var: #jumpIsMethod type: #'AbstractInstruction *'>
	<var: #jumpImmediate type: #'AbstractInstruction *'>

	jumpImmediate := self genJumpImmediate: ReceiverResultReg.
	resultReg := Arg0Reg.
	slotsReg := Arg1Reg.
	"get freeStart as early as possible so as not to wait later..."
	cogit MoveAw: objectMemory freeStartAddress R: resultReg.

	"formatReg := self formatOf: ReceiverResultReg"
	self genGetFormatOf: ReceiverResultReg
		into: (ptrReg := formatReg := SendNumArgsReg)
		leastSignificantHalfOfBaseHeaderIntoScratch: NoReg.

	cogit CmpCq: objectMemory firstCompiledMethodFormat R: formatReg.
	jumpIsMethod := cogit JumpAboveOrEqual: 0.
	cogit CmpCq: objectMemory indexablePointersFormat R: formatReg.
	jumpVariable := cogit JumpZero: 0.
	continuance := cogit Label.

	self genGetRawSlotSizeOfNonImm: ReceiverResultReg into: slotsReg.
	cogit CmpCq: objectMemory numSlotsMask R: slotsReg.
	jumpTooBig := cogit JumpZero: 0.

	cogit CmpCq: 0 R: slotsReg.
	jumpEmpty := cogit JumpZero: 0.

	"round up to allocationUnit"
	cogit
		MoveR: slotsReg R: TempReg;
		AndCq: 1 R: TempReg;
		AddR: TempReg R: slotsReg;
		AddCq: objectMemory baseHeaderSize / objectMemory wordSize R: slotsReg;
		LogicalShiftLeftCq: objectMemory shiftForWord R: slotsReg;
	"check if allocation fits (freeSize + byteSize < scavengeThreshold); scavengeThreshold is constant."
		AddR: resultReg R: slotsReg;
		CmpCq: objectMemory getScavengeThreshold R: slotsReg.
	jumpNoSpace := cogit JumpAboveOrEqual: 0.
	cogit
		MoveR: resultReg R: ptrReg;
	"write back new freeStart; get result. slotsReg holds new freeStart, the limit of the object"
		MoveR: slotsReg Aw: objectMemory freeStartAddress;
	"set up loop bounds"
		SubCq: objectMemory wordSize * 2 R: slotsReg;
	"copy header, masking off irrelevant bits"
		MoveMw: 0 r: ReceiverResultReg R: TempReg;
		AndCq: objectMemory formatMask << objectMemory formatShift + objectMemory classIndexMask R: TempReg;
		MoveR: TempReg Mw: 0 r: resultReg;
		MoveMw: objectMemory wordSize r: ReceiverResultReg R: TempReg;
		AndCq: objectMemory numSlotsMask << objectMemory numSlotsHalfShift R: TempReg;
		MoveR: TempReg Mw: objectMemory wordSize r: resultReg.
	"copy two fields at a time..."
	copyLoop := cogit Label.
	cogit
		AddCq: objectMemory wordSize * 2 R: ReceiverResultReg;
		AddCq: objectMemory wordSize * 2 R: ptrReg;
		MoveMw: 0 r: ReceiverResultReg R: TempReg;
		MoveR: TempReg Mw: 0 r: ptrReg;
		MoveMw: objectMemory wordSize r: ReceiverResultReg R: TempReg;
		MoveR: TempReg Mw: objectMemory wordSize r: ptrReg;
		CmpR: ptrReg R: slotsReg;
		JumpAbove: copyLoop;
		MoveR: resultReg R: ReceiverResultReg;
		genPrimReturn.

	"If the receiver is variable pointers, fail if its a context, otherwise continue"
	jumpVariable jmpTarget: cogit Label.
	self genGetClassIndexOfNonImm: ReceiverResultReg into: ClassReg.
	cogit
		CmpCq: ClassMethodContextCompactIndex R: ClassReg;
		JumpNonZero: continuance.

	jumpImmediate jmpTarget:
	(jumpNoSpace jmpTarget:
	(jumpIsMethod jmpTarget:
	(jumpTooBig jmpTarget:
	(jumpEmpty jmpTarget: cogit Label)))).

	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> genPrimitiveStringAt [
	| formatReg jumpNotIndexable jumpBadIndex done
	  jumpIsBytes jumpIsShorts jumpWordTooBig jumpWordsDone
	  jumpBytesOutOfBounds jumpShortsOutOfBounds jumpWordsOutOfBounds |
	"c.f. StackInterpreter>>stSizeOf: SpurMemoryManager>>lengthOf:format: fixedFieldsOf:format:length:"
	<var: #done type: #'AbstractInstruction *'>
	<var: #jumpIsBytes type: #'AbstractInstruction *'>
	<var: #jumpIsShorts type: #'AbstractInstruction *'>
	<var: #jumpBadIndex type: #'AbstractInstruction *'>
	<var: #jumpWordsDone type: #'AbstractInstruction *'>
	<var: #jumpWordTooBig type: #'AbstractInstruction *'>
	<var: #jumpNotIndexable type: #'AbstractInstruction *'>
	<var: #jumpBytesOutOfBounds type: #'AbstractInstruction *'>
	<var: #jumpShortsOutOfBounds type: #'AbstractInstruction *'>
	<var: #jumpWordsOutOfBounds type: #'AbstractInstruction *'>

	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	cogit MoveR: Arg0Reg R: Arg1Reg.
	jumpBadIndex := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
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
		  9 64-bit indexable
		10 - 11 32-bit indexable
		12 - 15 16-bit indexable
		16 - 23 byte indexable
		24 - 31 compiled method"
	cogit CmpCq: objectMemory firstByteFormat R: formatReg.
	jumpIsBytes := cogit JumpGreaterOrEqual: 0.
					cogit CmpCq: objectMemory firstShortFormat R: formatReg.
	jumpIsShorts := cogit JumpGreaterOrEqual: 0.
					cogit CmpCq: objectMemory firstLongFormat R: formatReg.
	jumpNotIndexable := cogit JumpLess: 0.

	"fall through to double words"
	cogit CmpR: Arg1Reg R: ClassReg.
	jumpWordsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg1Reg.
	cogit MoveXwr: Arg1Reg R: ReceiverResultReg R: TempReg.
	jumpWordTooBig := self jumpNotCharacterUnsignedValueInRegister: TempReg.
	cogit MoveR: TempReg R: ReceiverResultReg.
	jumpWordsDone := cogit Jump: 0.

	jumpIsBytes jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord R: ClassReg).
	cogit AndCq: objectMemory wordSize - 1 R: formatReg.
	cogit SubR: formatReg R: ClassReg.
	cogit CmpR: Arg1Reg R: ClassReg.
	jumpBytesOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddCq: objectMemory baseHeaderSize R: Arg1Reg.
	cogit MoveXbr: Arg1Reg R: ReceiverResultReg R: ReceiverResultReg.
	cogit backEnd byteReadsZeroExtend ifFalse:
			[cogit AndCq: 255 R: ReceiverResultReg].
	jumpWordsDone jmpTarget: (done := cogit Label).
	self genConvertIntegerToCharacterInReg: ReceiverResultReg.
	cogit genPrimReturn.

	jumpIsShorts jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord - 1 R: ClassReg).
	cogit AndCq: objectMemory wordSize / 1 - 1 R: formatReg.
	cogit SubR: formatReg R: ClassReg.
	cogit CmpR: Arg1Reg R: ClassReg.
	jumpShortsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddR: Arg1Reg R: ReceiverResultReg.
	cogit MoveM16: objectMemory baseHeaderSize r: ReceiverResultReg R: ReceiverResultReg.
	cogit Jump: done.


	jumpWordTooBig jmpTarget:
	(jumpBytesOutOfBounds jmpTarget:
	(jumpShortsOutOfBounds jmpTarget:
	(jumpWordsOutOfBounds jmpTarget:
	(jumpNotIndexable jmpTarget: 
	(jumpBadIndex jmpTarget: cogit Label))))).

	^CompletePrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor32BitSpur >> genPrimitiveStringAtPut [
	| formatReg jumpBadIndex jumpBadArg jumpImmutable
	  jumpIsBytes jumpIsShorts jumpNotString jumpIsCompiledMethod
	  jumpBytesOutOfRange jumpShortsOutOfRange jumpWordsOutOfRange
	  jumpBytesOutOfBounds jumpWordsOutOfBounds jumpShortsOutOfBounds |
	"c.f. StackInterpreter>>stSizeOf: SpurMemoryManager>>lengthOf:format: fixedFieldsOf:format:length:"
	<var: #jumpBadArg type: #'AbstractInstruction *'>
	<var: #jumpIsBytes type: #'AbstractInstruction *'>
	<var: #jumpIsShorts type: #'AbstractInstruction *'>
	<var: #jumpBadIndex type: #'AbstractInstruction *'>
	<var: #jumpBytesOutOfRange type: #'AbstractInstruction *'>
	<var: #jumpShortsOutOfRange type: #'AbstractInstruction *'>
	<var: #jumpWordsOutOfRange type: #'AbstractInstruction *'>
	<var: #jumpBytesOutOfBounds type: #'AbstractInstruction *'>
	<var: #jumpShortsOutOfBounds type: #'AbstractInstruction *'>
	<var: #jumpWordsOutOfBounds type: #'AbstractInstruction *'>

	cogit genLoadArgAtDepth: 1 into: Arg0Reg.
	cogit genLoadArgAtDepth: 0 into: Arg1Reg.

	jumpBadIndex := self genJumpNotSmallInteger: Arg0Reg.
	cogit MoveR: Arg1Reg R: TempReg.
	jumpBadArg := self genJumpNotCharacterInScratchReg: TempReg.
	self genConvertSmallIntegerToIntegerInReg: Arg0Reg.
	cogit SubCq: 1 R: Arg0Reg. "1-rel => 0-rel"

	"formatReg := self formatOf: ReceiverResultReg"
	self cppIf: IMMUTABILITY
		ifTrue:
		[ self genGetFormatOf: ReceiverResultReg
			into: (formatReg := SendNumArgsReg)
			leastSignificantHalfOfBaseHeaderIntoScratch: TempReg.
		jumpImmutable := self genJumpBaseHeaderImmutable: TempReg ]
		ifFalse: 
		[ self genGetFormatOf: ReceiverResultReg
			into: (formatReg := SendNumArgsReg)
			leastSignificantHalfOfBaseHeaderIntoScratch: NoReg ].

	self genGetNumSlotsOf: ReceiverResultReg into: ClassReg.

	"dispatch on format; words and/or bytes.
		  0 to 8 = pointer objects, forwarders, reserved.
		  9 64-bit indexable
		10 - 11 32-bit indexable
		12 - 15 16-bit indexable
		16 - 23 byte indexable
		24 - 31 compiled method"
	cogit CmpCq: objectMemory firstLongFormat R: formatReg.
	jumpNotString := cogit JumpBelow: 0.
					cogit CmpCq: objectMemory firstCompiledMethodFormat R: formatReg.
	jumpIsCompiledMethod := cogit JumpAboveOrEqual: 0.
					cogit CmpCq: objectMemory firstByteFormat R: formatReg.
	jumpIsBytes := cogit JumpAboveOrEqual: 0.
					cogit CmpCq: objectMemory firstShortFormat R: formatReg.
	jumpIsShorts := cogit JumpAboveOrEqual: 0.

	"fall through to double words"
	cogit CmpCq: 0 R: Arg1Reg.
	jumpWordsOutOfRange := cogit JumpLess: 0.
	cogit CmpR: Arg0Reg R: ClassReg.
	jumpWordsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit MoveR: Arg1Reg R: TempReg.
	self genConvertCharacterToCodeInReg: TempReg.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg0Reg.
	cogit MoveR: TempReg Xwr: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit genPrimReturn.

	jumpIsShorts jmpTarget:
		(cogit CmpCq: (objectMemory characterObjectOf: 65535) R: Arg1Reg).
	jumpShortsOutOfRange := cogit JumpAbove: 0.
	cogit LogicalShiftLeftCq: objectMemory shiftForWord - 1 R: ClassReg.
	cogit AndCq: objectMemory wordSize / 2 - 1 R: formatReg.
	cogit SubR: formatReg R: ClassReg.
	cogit CmpR: Arg0Reg R: ClassReg.
	jumpShortsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit MoveR: Arg1Reg R: TempReg.
	self genConvertCharacterToCodeInReg: TempReg.
	cogit AddR: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: TempReg M16: objectMemory baseHeaderSize r: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit genPrimReturn.

	jumpIsBytes jmpTarget:
		(cogit CmpCq: (objectMemory characterObjectOf: 255) R: Arg1Reg).
	jumpBytesOutOfRange := cogit JumpAbove: 0.
	cogit LogicalShiftLeftCq: objectMemory shiftForWord R: ClassReg.
	cogit AndCq: objectMemory wordSize - 1 R: formatReg.
	cogit SubR: formatReg R: ClassReg.
	cogit CmpR: Arg0Reg R: ClassReg.
	jumpBytesOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit MoveR: Arg1Reg R: TempReg.
	self genConvertCharacterToCodeInReg: TempReg.
	cogit AddCq: objectMemory baseHeaderSize R: Arg0Reg.
	cogit MoveR: TempReg Xbr: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit genPrimReturn.

	jumpNotString jmpTarget:
	(jumpBytesOutOfRange jmpTarget:
	(jumpShortsOutOfRange jmpTarget:
	(jumpWordsOutOfRange jmpTarget:
	(jumpIsCompiledMethod jmpTarget:
	(jumpBytesOutOfBounds jmpTarget:
	(jumpShortsOutOfBounds jmpTarget:
	(jumpWordsOutOfBounds jmpTarget: cogit Label))))))).

	self cppIf: IMMUTABILITY
		ifTrue: [jumpImmutable jmpTarget: jumpNotString getJmpTarget].

	cogit AddCq: 1 R: Arg0Reg. "0-rel => 1-rel"
	self genConvertIntegerToSmallIntegerInReg: Arg0Reg.

	jumpBadArg jmpTarget:
	(jumpBadIndex jmpTarget: cogit Label).

	^CompletePrimitive
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genRemoveSmallIntegerTagsInScratchReg: scratchReg [
	cogit SubCq: 1 R: scratchReg.
	^0
]

{ #category : #initialization }
CogObjectRepresentationFor32BitSpur >> genStoreHeader: header intoNewInstance: rcvrReg using: scratchReg [
	"Generate the instructions to move the constant header into a new instance pointed to by rcvrReg."
	<inline: true>
	self flag: #endianness.
	cogit
		MoveCq: (self low32BitsOf: header) R: scratchReg;
		MoveR: scratchReg Mw: 0 r: rcvrReg;
		MoveCq: header >> 32 R: scratchReg;
		MoveR: scratchReg Mw: 4 r: rcvrReg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> getLiteralCountOf: methodReg plusOne: plusOne inBytes: inBytes into: litCountReg scratch: scratchReg [
	"Get the literal count of a CompiledMethod into headerReg, plus one if requested.
	  If inBytes is true, scale the count by the word size.  Deal with the possibility of
	 the method being cogged."
	self genGetMethodHeaderOf: methodReg into: litCountReg scratch: scratchReg.
	inBytes
		ifTrue:
			[cogit
				AndCq: coInterpreter alternateHeaderNumLiteralsMask << 1 R: litCountReg;
				LogicalShiftLeftCq: 1 R: litCountReg]
		ifFalse:
			[cogit
				LogicalShiftRightCq: 1 R: litCountReg;
				AndCq: coInterpreter alternateHeaderNumLiteralsMask R: litCountReg].
	plusOne ifTrue:
		[cogit AddCq: (inBytes ifTrue: [objectMemory wordSize] ifFalse: [1]) R: litCountReg].
	^0
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationFor32BitSpur >> illegalClassTag [
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

{ #category : #'garbage collection' }
CogObjectRepresentationFor32BitSpur >> markAndTraceCacheTagLiteral: literal in: cogMethodOrNil atpc: address [
	"Mark and trace a literal in an inline cache preceding address in cogMethodOrNil.
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

{ #category : #'object representation' }
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
