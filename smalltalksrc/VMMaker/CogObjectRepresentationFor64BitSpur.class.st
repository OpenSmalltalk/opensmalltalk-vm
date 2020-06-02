Class {
	#name : #CogObjectRepresentationFor64BitSpur,
	#superclass : #CogObjectRepresentationForSpur,
	#instVars : [
		'ceDereferenceSelectorIndex'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'accessing class hierarchy' }
CogObjectRepresentationFor64BitSpur class >> defaultObjectMemoryClass [
	"For in-image compilation.  Spur64BitCoMemoryManager is as yet undefined."
	^Smalltalk classNamed: #Spur64BitCoMemoryManager
]

{ #category : #accessing }
CogObjectRepresentationFor64BitSpur class >> wordSize [
	^8
]

{ #category : #'sista support' }
CogObjectRepresentationFor64BitSpur >> allImmediate: immediateMask branchIf: reg instanceOfBehaviors: arrayObj target: targetFixUp [
	| tag1 tag2 |
	<var: #targetFixUp type: #'AbstractInstruction *'>
	immediateMask = objectMemory tagMask ifTrue: [(self genJumpImmediate: reg) jmpTarget: targetFixUp. ^0].
	"TempReg holds the rcvr tag"
	"In this case one immediate tag out of the three is not present in arrayObj."
	tag1 := objectMemory classTagForClass: (objectMemory fetchPointer: 0 ofObject: arrayObj).
	tag2 := objectMemory classTagForClass: (objectMemory fetchPointer: 1 ofObject: arrayObj).
	(tag1 = objectMemory smallIntegerTag or: [tag2 = objectMemory smallIntegerTag]) ifTrue:
		[(self genJumpSmallIntegerInScratchReg: TempReg) jmpTarget: targetFixUp].
	(tag1 = objectMemory characterTag or: [tag2 = objectMemory characterTag]) ifTrue:
		[(self genJumpCharacterInScratchReg: TempReg) jmpTarget: targetFixUp].
	(tag1 = objectMemory smallFloatTag or: [tag2 = objectMemory smallFloatTag]) ifTrue:
		[(self genJumpSmallFloatInScratchReg: TempReg) jmpTarget: targetFixUp].
	^0
]

{ #category : #'sista support' }
CogObjectRepresentationFor64BitSpur >> allImmediate: immediateMask branchIf: reg notInstanceOfBehaviors: arrayObj target: targetFixUp [
	| incorrectTag tag1 tag2 |
	<var: #targetFixUp type: #'AbstractInstruction *'>
	(self genJumpNotImmediate: reg) jmpTarget: targetFixUp. 
	immediateMask = objectMemory tagMask ifFalse: 
		[ "TempReg holds the rcvr tag"
		"In this case one immediate tag out of the three is not present in arrayObj. 
		We look for it, and generate a jump to the fixup if the rcvr tag matches"
		tag1 := objectMemory classTagForClass: (objectMemory fetchPointer: 0 ofObject: arrayObj).
		tag2 := objectMemory classTagForClass: (objectMemory fetchPointer: 1 ofObject: arrayObj).
		incorrectTag :=  self fetchImmediateTagOtherThanTag1: tag1 tag2: tag2.
		cogit CmpCq: incorrectTag R: TempReg.
		cogit JumpZero: targetFixUp].
	^0
]

{ #category : #'sista support' }
CogObjectRepresentationFor64BitSpur >> allocateCounters: nCounters [
	"On Spur allocate the counters on the heap as pinned objects.
	 Each counter occupies 32-bits.  The number of counters can
	 be derived from the number of slots in the obj."
	<inline: true>
	| objOop |
	objOop := objectMemory allocatePinnedSlots: nCounters + 1 // 2.
	^objOop
		ifNil: [0]
		ifNotNil: [objOop + objectMemory baseHeaderSize]
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationFor64BitSpur >> bitAndByteOffsetOfIsFullBlockBitInto: aBlock [
	<inline: true>
	"This supplies the bitmask for the isFullBlock bit, and the offset of the byte containing
	 that bit in a CogMethod header to aBlock.  We don't have named variables holding this
	 offset.  The following assert tests whether the values are correct by creating a surrogate
	 on an empty ByteArray, setting the bit, and checking that the expected values are set
	 in the ByteArray."
	self cCode: [] inSmalltalk:
		[| m |
		m := ByteArray new: 16.
		CogBlockMethodSurrogate64 new
			at: 0 memory: m headerSize: 8 cogit: nil;
			cpicHasMNUCaseOrCMIsFullBlock: true.
		self assert: m = #[0 0 0 0 0 0 0 0 0 16 0 0 0 0 0 0].
		self assert: (m at: objectMemory baseHeaderSize + 2) = 16].
	aBlock value: 16 value: objectMemory baseHeaderSize + 1 "zero-relative"
]

{ #category : #'sista support' }
CogObjectRepresentationFor64BitSpur >> branch2CasesIf: reg instanceOfBehaviors: arrayObj target: targetFixUp [
	| classObj tag1 tag2 |
	< inline: true>		
	
	"look for the 2 tags requiring jmps"
	0 to: (objectMemory numSlotsOf: arrayObj) - 1 do:
		[:i|
		 classObj := objectMemory fetchPointer: i ofObject: arrayObj.
		 (objectMemory isImmediateClass: classObj)
			ifTrue: [ tag1
				ifNil: [tag1 := objectMemory classTagForClass: classObj ]
				ifNotNil: [tag2 := objectMemory classTagForClass: classObj ] ] ].
		
	(tag1 = objectMemory smallIntegerTag or: [tag2 = objectMemory smallIntegerTag]) ifTrue:
		[(self genJumpSmallIntegerInScratchReg: TempReg) jmpTarget: targetFixUp].
	(tag1 = objectMemory characterTag or: [tag2 = objectMemory characterTag]) ifTrue:
		[(self genJumpCharacterInScratchReg: TempReg) jmpTarget: targetFixUp].
	(tag1 = objectMemory smallFloatTag or: [tag2 = objectMemory smallFloatTag]) ifTrue:
		[(self genJumpSmallFloatInScratchReg: TempReg) jmpTarget: targetFixUp].
	^ 0
]

{ #category : #'sista support' }
CogObjectRepresentationFor64BitSpur >> branch2CasesIf: reg notInstanceOfBehaviors: arrayObj target: targetFixUp [
	"Only 2 immediate type allowed out of the three. Look for the third and jump to target fixup if it's the third.
	TempReg currently holds the rcvr tag and the receiver is immediate."
	
	| incorrectTag classObj tag1 tag2 |
	< inline: true>		
	
	"look for the 2 allowed tags"
	0 to: (objectMemory numSlotsOf: arrayObj) - 1 do:
		[:i|
		 classObj := objectMemory fetchPointer: i ofObject: arrayObj.
		 (objectMemory isImmediateClass: classObj)
			ifTrue: [ tag1
				ifNil: [tag1 := objectMemory classTagForClass: classObj ]
				ifNotNil: [tag2 := objectMemory classTagForClass: classObj ] ] ].
	
	incorrectTag := self fetchImmediateTagOtherThanTag1: tag1 tag2: tag2.
	cogit CmpCq: incorrectTag R: TempReg.
	cogit JumpZero: targetFixUp.
	
]

{ #category : #'sista support' }
CogObjectRepresentationFor64BitSpur >> branchIf: reg hasImmediateTag: classIndex target: targetFixUp [
	<var: #targetFixUp type: #'AbstractInstruction *'>
	| jmpImmediate |
	<inline: true>
	classIndex = objectMemory smallIntegerTag ifTrue:
		[jmpImmediate := self genJumpSmallInteger: reg].
	classIndex = objectMemory characterTag ifTrue:
		[jmpImmediate := self genJumpCharacter: reg].
	classIndex = objectMemory smallFloatTag ifTrue:
		[jmpImmediate := self genJumpSmallFloat: reg].
	jmpImmediate jmpTarget: targetFixUp
]

{ #category : #'sista support' }
CogObjectRepresentationFor64BitSpur >> branchIf: reg hasNotImmediateTag: classIndex target: targetFixUp [
	<var: #targetFixUp type: #'AbstractInstruction *'>
	| jmpImmediate |
	<inline: true>
	classIndex = objectMemory smallIntegerTag ifTrue:
		[jmpImmediate := self genJumpNotSmallInteger: reg].
	classIndex = objectMemory characterTag ifTrue:
		[jmpImmediate := self genJumpNotCharacter: reg].
	classIndex = objectMemory smallFloatTag ifTrue:
		[jmpImmediate := self genJumpNotSmallFloat: reg].
	jmpImmediate jmpTarget: targetFixUp
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationFor64BitSpur >> classForInlineCacheTag: classIndex [
	^objectMemory classOrNilAtIndex: classIndex
]

{ #category : #'sista support' }
CogObjectRepresentationFor64BitSpur >> fetchImmediateTagOtherThanTag1: tag1 tag2: tag2 [
	"Answers the immediate tag which is not tag1 nor tag2, usually Character."
	<inline: true>
	(tag1 = objectMemory characterTag or: [ tag2 = objectMemory characterTag ]) ifFalse: 
		[ ^ objectMemory characterTag ].
	(tag1 = objectMemory smallIntegerTag or: [ tag2 = objectMemory smallIntegerTag ]) ifFalse: 
		[ ^ objectMemory smallIntegerTag ].
	^ objectMemory smallFloatTag
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genAddSmallIntegerTagsTo: aRegister [
	cogit AddCq: 1 R: aRegister.
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genAlloc64BitPositiveIntegerValue: valueReg into: resultReg scratchReg: scratch1 scratchReg: scratch2 [
	<returnTypeC: #'AbstractInstruction *'>
	| allocSize newLPIHeader jumpFail |
	allocSize := objectMemory baseHeaderSize + objectMemory wordSize.
	newLPIHeader := objectMemory
							headerForSlots: 1
							format: objectMemory firstByteFormat
							classIndex: ClassLargePositiveIntegerCompactIndex.
	cogit MoveAw: objectMemory freeStartAddress R: resultReg.
	cogit LoadEffectiveAddressMw: allocSize r: resultReg R: scratch1.
	cogit CmpCq: objectMemory getScavengeThreshold R: scratch1.
	jumpFail := cogit JumpAboveOrEqual: 0.
	cogit MoveR: scratch1 Aw: objectMemory freeStartAddress.
	self genStoreHeader: newLPIHeader intoNewInstance: resultReg using: scratch1.
	cogit MoveR: valueReg Mw: objectMemory baseHeaderSize r: resultReg.
	^jumpFail
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genAlloc64BitSignedIntegerValue: valueReg into: resultReg scratchReg: scratch1 scratchReg: scratch2 [
	<returnTypeC: #'AbstractInstruction *'>
	| allocSize newLNIHeader jumpFail jumpNeg |
	allocSize := objectMemory baseHeaderSize + objectMemory wordSize.
	newLNIHeader := objectMemory
							headerForSlots: 1
							format: objectMemory firstByteFormat
							classIndex: ClassLargeNegativeIntegerCompactIndex.
	cogit MoveAw: objectMemory freeStartAddress R: resultReg.
	cogit LoadEffectiveAddressMw: allocSize r: resultReg R: scratch1.
	cogit CmpCq: objectMemory getScavengeThreshold R: scratch1.
	jumpFail := cogit JumpAboveOrEqual: 0.
	cogit MoveR: scratch1 Aw: objectMemory freeStartAddress.
	cogit MoveCq: newLNIHeader R: scratch1.
	cogit CmpCq: 0 R: valueReg.
	jumpNeg := cogit JumpLess: 0.
	"We can avoid duplicating the large constant and a jump choosing between
	 the alternatives by incrementing the single constant if positive.  The assert
	 checks that the hack works. Compact code is to be preferred because it is
	 an uncommon case; usually the value will fit in a SmallInteger."
	self assert: (objectMemory headerForSlots: 0 format: 0 classIndex: 1) = 1.
	cogit AddCq: ClassLargePositiveIntegerCompactIndex - ClassLargeNegativeIntegerCompactIndex R: scratch1.
	jumpNeg jmpTarget:
	(cogit MoveR: scratch1 Mw: 0 r: resultReg).
	"The old less compact code was
	cogit CmpCq: 0 R: valueReg.
	jumpNeg := cogit JumpLess: 0.
	cogit MoveCq: newLPIHeader R: scratch1.
	jumpJoin := cogit Jump: 0.
	jumpNeg jmpTarget:
	(cogit MoveCq: newLNIHeader R: scratch1).
	jumpJoin jmpTarget:
	(cogit MoveR: scratch1 Mw: 0 r: resultReg)."
	cogit MoveR: valueReg Mw: objectMemory baseHeaderSize r: resultReg.
	^jumpFail
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genAllocFloatValue: dpreg into: resultReg scratchReg: scratch1 scratchReg: scratch2 [
	"Override to answer a SmallFloat64 if possible."
	<returnTypeC: #'AbstractInstruction *'>
	| jumpFail jumpNotSF jumpMerge |
	<var: #jumpFail type: #'AbstractInstruction *'>
	<var: #jumpNotSF type: #'AbstractInstruction *'>
	<var: #jumpMerge type: #'AbstractInstruction *'>
	cogit MoveRd: dpreg R: resultReg.
	jumpNotSF := self genJumpNotSmallFloatValueBits: resultReg scratch: scratch1.
	self genConvertBitsToSmallFloatIn: resultReg scratch: scratch1.
	jumpMerge := cogit Jump: 0.
	jumpNotSF jmpTarget: cogit Label.
	jumpFail := super genAllocFloatValue: dpreg into: resultReg scratchReg: scratch1 scratchReg: scratch2.
	jumpMerge jmpTarget: cogit Label.
	^jumpFail
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genBoxedOrSmallFloat: floatOopReg scratchReg: scratchReg into: destReg [
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpNonSmallFloat type: #'AbstractInstruction *'>
	<var: #jumpMerge type: #'AbstractInstruction *'>
	<var: #jumpFail type: #'AbstractInstruction *'>
	| jumpNonSmallFloat jumpMerge jumpFail |
	jumpNonSmallFloat := self genJumpNotSmallFloat: floatOopReg.
	"Small float case"
	self genGetSmallFloatValueOf: floatOopReg scratch: scratchReg into: destReg.
	jumpMerge := cogit Jump: 0.	

	jumpNonSmallFloat jmpTarget: cogit Label.
	jumpFail := super genBoxedOrSmallFloat: floatOopReg scratchReg: scratchReg into: destReg.
	
	jumpMerge jmpTarget: cogit Label.
	^ jumpFail
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genClearAndSetSmallIntegerTagsIn: scratchReg [
	"Set the SmallInteger tag bits when the tag bits may be filled with garbage."
	cogit
		AndCq: -1 - objectMemory tagMask R: scratchReg;
		OrCq: 1 R: scratchReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genConvertBitsToSmallFloatIn: reg scratch: scratch [
	"Convert the in-SmallFloat64-range floating point value in integer register into a tagged SmallFloat64 oop.
	 c.f. Spur64BitMemoryManager>>smallFloatObjectOf:"
	| jumpZero |
	<var: #jumpZero type: #'AbstractInstruction *'>
	cogit
		RotateLeftCq: 1 R: reg;
		CmpCq: 1 R: reg.
	jumpZero :=
	cogit JumpBelowOrEqual: 0.
	cogit
		SubCq: objectMemory smallFloatExponentOffset << (objectMemory smallFloatMantissaBits + 1) R: reg.
	jumpZero jmpTarget:
	(cogit LogicalShiftLeftCq: objectMemory numTagBits R: reg).
	cogit AddCq: objectMemory smallFloatTag R: reg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genConvertCharacterToSmallIntegerInReg: reg [
	"Convert the Character in reg to a SmallInteger, assuming
	 the Character's value is a valid character."
	cogit SubCq: objectMemory characterTag - objectMemory smallIntegerTag R: reg
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genConvertDataFormat: formatReg numSlots: slotsRegister intoBytes: destReg [
	| jumpIsBytes jumpIsShorts jumpIsLongs jumpLongLongsDone jumpBytesDone jumpShortsDone jumpLongsDone |
	slotsRegister ~= destReg ifTrue: [
		cogit MoveR: slotsRegister R: destReg.
	].

	cogit CmpCq: objectMemory firstByteFormat R: formatReg.
	jumpIsBytes := cogit JumpAboveOrEqual: 0.
	
	cogit CmpCq: objectMemory firstShortFormat R: formatReg.
	jumpIsShorts := cogit JumpAboveOrEqual: 0.
	
	cogit CmpCq: objectMemory firstLongFormat R: formatReg.
	jumpIsLongs := cogit JumpAboveOrEqual: 0.

	"Long long"
	cogit LogicalShiftLeftCq: objectMemory shiftForWord R: destReg.
	jumpLongLongsDone := cogit Jump: 0.
	
	"Bytes"
	jumpIsBytes jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord R: destReg).
		cogit AndCq: objectMemory wordSize - 1 R: formatReg.
		cogit SubR: formatReg R: destReg.
	jumpBytesDone := cogit Jump: 0.
	
	jumpIsShorts jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord - 1 R: destReg).
		cogit AndCq: (objectMemory wordSize >> 1) - 1 R: formatReg.
		cogit SubR: formatReg R: destReg.
		cogit LogicalShiftLeftCq: 1 R: destReg.
	jumpShortsDone := cogit Jump: 0.
	
	jumpIsLongs jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord - 2 R: destReg).
		cogit AndCq: (objectMemory wordSize >> 2) - 1 R: formatReg.
		cogit SubR: formatReg R: destReg.
		cogit LogicalShiftLeftCq: 2 R: destReg.
	jumpLongsDone := cogit Jump: 0.
	
	jumpLongLongsDone jmpTarget:
	(jumpLongsDone jmpTarget:
	(jumpShortsDone jmpTarget:
	(jumpBytesDone jmpTarget:
		cogit Label))).
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genConvertIntegerToSmallIntegerInReg: reg [
	cogit LogicalShiftLeftCq: objectMemory numTagBits R: reg.
	cogit AddCq: 1 R: reg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genConvertSmallFloatToSmallFloatHashAsIntegerInReg: reg scratch: scratch [
	"Convert the SmallFloat in reg to its identityHash as a SmallInteger.
	 Rotate the sign bit from bit 3 (zero-relative) to the sign bit.  
	 c.f. Spur64BitMemoryManager>>rotatedFloatBitsOf:"
	self assert: objectMemory smallFloatTag >> 1 - objectMemory smallIntegerTag = objectMemory smallIntegerTag.
	cogit
		LogicalShiftRightCq: 1 R: reg;
		AndCq: 1 << (objectMemory numTagBits - 1) R: reg R: scratch;
		SubR: scratch R: reg;
		SubCq: objectMemory smallFloatTag >> 1 - objectMemory smallIntegerTag R: reg;
		LogicalShiftLeftCq: 63 - (objectMemory numTagBits - 1) R: scratch;
		OrR: scratch R: reg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genConvertSmallIntegerToCharacterInReg: reg [
	"Convert the SmallInteger in reg to a Character, assuming
	 the SmallInteger's value is a valid character."
	cogit AddCq: objectMemory characterTag - objectMemory smallIntegerTag R: reg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genConvertSmallIntegerToIntegerInReg: reg [
	cogit ArithmeticShiftRightCq: objectMemory numTagBits R: reg.
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genDoubleArithmetic: arithmeticOperator preOpCheck: preOpCheckOrNil [
	<inline: true>
	^self genFloatArithmetic: arithmeticOperator preOpCheck: preOpCheckOrNil boxed: true
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genDoubleComparison: jumpOpcodeGenerator invert: invertComparison [
	<inline: true>
	^self genFloatComparison: jumpOpcodeGenerator invert: invertComparison boxed: true
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genFetchIndexRegister: indexReg from: tableObj into: destReg [
	"indexReg contains the 1-relative index of an element in tableObj.
	 Since BaseHeaderSize = BytesPerOop we can use it as a
	 zero-relative index from the beginning of the object."
	self assert: indexReg ~= destReg.
	cogit genMoveConstant: tableObj R: destReg.
	cogit MoveXwr: indexReg R: destReg R: destReg.
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genFloatArithmetic: arithmeticOperator preOpCheck: preOpCheckOrNil boxed: rcvrBoxed [
	<var: #preOpCheckOrNil declareC: 'AbstractInstruction *(*preOpCheckOrNil)(int rcvrReg, int argReg)'>
	<inline: false>
	| jumpFailAlloc jumpFailCheck jumpImmediate jumpNotSmallFloat jumpNotSmallInteger jumpNotBoxedFloat doOp |
	<var: #jumpNotSmallInteger type: #'AbstractInstruction *'>
	<var: #jumpNotBoxedFloat type: #'AbstractInstruction *'>
	<var: #jumpNotSmallFloat type: #'AbstractInstruction *'>
	<var: #jumpImmediate type: #'AbstractInstruction *'>
	<var: #jumpFailCheck type: #'AbstractInstruction *'>
	<var: #jumpFailAlloc type: #'AbstractInstruction *'>
	<var: #doOp type: #'AbstractInstruction *'>
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	rcvrBoxed
		ifTrue: [self genGetDoubleValueOf: ReceiverResultReg into: DPFPReg0]
		ifFalse: [self genGetSmallFloatValueOf: ReceiverResultReg scratch: TempReg into: DPFPReg0].
	jumpNotSmallFloat := self genJumpNotSmallFloat: Arg0Reg.
	self genGetSmallFloatValueOf: Arg0Reg scratch: TempReg into: DPFPReg1.
	doOp := cogit Label.
	preOpCheckOrNil ifNotNil:
		[jumpFailCheck := cogit perform: preOpCheckOrNil with: DPFPReg0 with: DPFPReg1].
	cogit gen: arithmeticOperator operand: DPFPReg1 operand: DPFPReg0.
	jumpFailAlloc := self genAllocFloatValue: DPFPReg0 into: SendNumArgsReg scratchReg: ClassReg scratchReg: TempReg.
	cogit MoveR: SendNumArgsReg R: ReceiverResultReg.
	cogit genPrimReturn.
	jumpNotSmallFloat jmpTarget: cogit Label.
	jumpNotSmallInteger := self genJumpNotSmallInteger: Arg0Reg.
	cogit MoveR: Arg0Reg R: Arg1Reg.
	self genConvertSmallIntegerToIntegerInReg: Arg1Reg.
	cogit ConvertR: Arg1Reg Rd: DPFPReg1.
	cogit Jump: doOp.
	jumpNotSmallInteger jmpTarget: cogit Label.
	jumpImmediate := self genJumpImmediate: Arg0Reg.
	self genGetCompactClassIndexNonImmOf: Arg0Reg into: SendNumArgsReg.
	self genCmpClassFloatCompactIndexR: SendNumArgsReg.
	jumpNotBoxedFloat := cogit JumpNonZero: 0.
	self genGetDoubleValueOf: Arg0Reg into: DPFPReg1.
	cogit Jump: doOp.
	jumpImmediate jmpTarget:
	(jumpNotBoxedFloat jmpTarget:
	(jumpNotSmallInteger jmpTarget:
	(jumpFailAlloc jmpTarget: cogit Label))).
	preOpCheckOrNil ifNotNil:
		[jumpFailCheck jmpTarget: jumpFailAlloc getJmpTarget].
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genFloatComparison: jumpOpcodeGenerator invert: invertComparison boxed: rcvrBoxed [
	<var: #jumpOpcodeGenerator declareC: 'AbstractInstruction *(*jumpOpcodeGenerator)(void *)'>
	<inline: false>
	| jumpImmediate jumpNotSmallFloat jumpNotSmallInteger jumpNotBoxedFloat jumpCond compare |
	<var: #jumpNotSmallInteger type: #'AbstractInstruction *'>
	<var: #jumpNotBoxedFloat type: #'AbstractInstruction *'>
	<var: #jumpNotSmallFloat type: #'AbstractInstruction *'>
	<var: #jumpImmediate type: #'AbstractInstruction *'>
	<var: #jumpCond type: #'AbstractInstruction *'>
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	rcvrBoxed
		ifTrue: [self genGetDoubleValueOf: ReceiverResultReg into: DPFPReg0]
		ifFalse: [self genGetSmallFloatValueOf: ReceiverResultReg scratch: TempReg into: DPFPReg0].
	jumpNotSmallFloat := self genJumpNotSmallFloat: Arg0Reg.
	self genGetSmallFloatValueOf: Arg0Reg scratch: TempReg into: DPFPReg1.
	compare := invertComparison "May need to invert for NaNs"
					ifTrue: [cogit CmpRd: DPFPReg0 Rd: DPFPReg1]
					ifFalse: [cogit CmpRd: DPFPReg1 Rd: DPFPReg0].
	jumpCond := cogit perform: jumpOpcodeGenerator with: 0. "FP jumps are a little weird"
	cogit genMoveFalseR: ReceiverResultReg.
	cogit genPrimReturn.
	jumpCond jmpTarget: (cogit genMoveTrueR: ReceiverResultReg).
	cogit genPrimReturn.
	jumpNotSmallFloat jmpTarget: cogit Label.
	jumpNotSmallInteger := self genJumpNotSmallInteger: Arg0Reg.
	self genConvertSmallIntegerToIntegerInReg: Arg0Reg.
	cogit ConvertR: Arg0Reg Rd: DPFPReg1.
	cogit Jump: compare.
	jumpNotSmallInteger jmpTarget: cogit Label.
	jumpImmediate := self genJumpImmediate: Arg0Reg.
	self genGetCompactClassIndexNonImmOf: Arg0Reg into: SendNumArgsReg.
	self genCmpClassFloatCompactIndexR: SendNumArgsReg.
	jumpNotBoxedFloat := cogit JumpNonZero: 0.
	self genGetDoubleValueOf: Arg0Reg into: DPFPReg1.
	cogit Jump: compare.
	jumpImmediate jmpTarget:
	(jumpNotBoxedFloat jmpTarget: cogit Label).
	^CompletePrimitive
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genGetHashFieldNonImmOf: instReg asSmallIntegerInto: destReg [
	"Fetch the instance's identity hash into destReg, encoded as a SmallInteger."
	cogit
		MoveMw: 0 r: instReg R: destReg;
		"Shift and mask the field leaving room for the SmallInteger tag."
		LogicalShiftRightCq: objectMemory identityHashFullWordShift - objectMemory numTagBits R: destReg;
		AndCq: objectMemory identityHashHalfWordMask << objectMemory numTagBits R: destReg;
		AddCq: objectMemory smallIntegerTag R: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genGetHashFieldNonImmOf: instReg into: destReg [
	"Fetch the instance's identity hash into destReg, unencoded."
	cogit
		MoveMw: 0 r: instReg R: destReg;
		LogicalShiftRightCq: 32 R: destReg;
		AndCq: objectMemory identityHashHalfWordMask R: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genGetInlineCacheClassTagFrom: sourceReg into: destReg forEntry: forEntry [
	"Extract the inline cache tag for the object in sourceReg into destReg. The inline
	 cache tag for a given object is the value loaded in inline caches to distinguish
	 objects of different classes.  In Spur this is either the tags for immediates, or
	 the receiver's classIndex.  Answer the label for the start of the sequence."
	| jumpImm entryLabel |
	<var: #jumpImm type: #'AbstractInstruction *'>
	<var: #entryLabel type: #'AbstractInstruction *'>
	forEntry ifTrue:
		[cogit AlignmentNops: objectMemory wordSize].
	entryLabel := cogit Label.
	cogit AndCq: objectMemory tagMask R: sourceReg R: destReg.
	jumpImm := cogit JumpNonZero: 0.
	"Get least significant half of header word in destReg"
	self flag: #endianness.
	cogit MoveMw: 0 r: sourceReg R: destReg.
	cogit AndCq: objectMemory classIndexMask R: destReg.
	jumpImm jmpTarget: cogit Label.
	^entryLabel
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genGetNumBytesOf: srcReg into: destReg [
	"Get the size in byte-sized slots of the object in srcReg into destReg.
	 srcReg may equal destReg.
	 destReg <- numSlots << self shiftForWord - (fmt bitAnd: 7).
	 Assumes the object in srcReg has a byte format, i.e. 16 to 23 or 24 to 31 "
	<var: #jmp type: #'AbstractInstruction *'>
	| jmp |
	self genGetRawSlotSizeOfNonImm: srcReg into: destReg.
	cogit CmpCq: objectMemory numSlotsMask R: destReg.
	jmp := cogit JumpLess: 0.
	self genGetOverflowSlotsOf: srcReg into: destReg.
	jmp jmpTarget: (cogit LogicalShiftLeftCq: objectMemory shiftForWord R: destReg). 
	self genGetBits: 7 ofFormatByteOf: srcReg into: TempReg.
	"Now: fmt bitAnd: 3 in TempReg"
	cogit SubR: TempReg R: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genGetOverflowSlotsOf: srcReg into: destReg [
	cogit
		MoveMw: objectMemory baseHeaderSize negated r: srcReg R: destReg;
		LogicalShiftLeftCq: 8 R: destReg;
		LogicalShiftRightCq: 8 R: destReg.
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genGetSizeOf: sourceReg into: destReg formatReg: formatReg scratchReg: scratchReg abortJumpsInto: aBinaryBlock [
	"Get the size of the non-immediate object in sourceReg into destReg using formatReg
	 and scratchReg as temps.  None of these registers can overlap.  Supply the jumps
	 taken if the object in sourceReg is not indexable, or if the object in sourceReg is a
	 context.. Hack: If the object has a pointer format other than 2 leave the number of
	 fixed fields in formatReg.  Used by primitiveSize, primitiveAt, and primitiveAtPut"
	<returnTypeC: #'AbstractInstruction *'>
	| jumpNotIndexable
	  jumpBytesDone jumpShortsDone jumpArrayDone jump32BitLongsDone jump64BitLongsDone
	  jumpIsBytes jumpHasFixedFields jumpIsShorts jumpIs32BitLongs jumpIsContext  |
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
	jumpIs32BitLongs := cogit JumpGreaterOrEqual: 0.
					cogit CmpCq: objectMemory sixtyFourBitIndexableFormat R: formatReg.
	jump64BitLongsDone := cogit JumpZero: 0.
	jumpNotIndexable jmpTarget: cogit Label.
	jumpNotIndexable := cogit Jump: 0.

	jumpIsBytes jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord R: destReg).
		cogit AndCq: objectMemory wordSize - 1 R: formatReg.
		cogit SubR: formatReg R: destReg.
	jumpBytesDone := cogit Jump: 0.

	jumpIsShorts jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord - 1 R: destReg).
		cogit AndCq: objectMemory wordSize >> 1 - 1 R: formatReg.
		cogit SubR: formatReg R: destReg.
	jumpShortsDone := cogit Jump: 0.

	jumpIs32BitLongs jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord - 2 R: destReg).
		cogit AndCq: objectMemory wordSize >> 2 - 1 R: formatReg.
		cogit SubR: formatReg R: destReg.
	jump32BitLongsDone := cogit Jump: 0.

	"formatReg contains fmt, now up for grabs.
	 destReg contains numSlots, precious.
	 sourceReg must be preserved"
	jumpHasFixedFields jmpTarget:
		(cogit AndCq: objectMemory classIndexMask R: scratchReg).
	cogit MoveR: scratchReg R: formatReg.
	cogit CmpCq: ClassMethodContextCompactIndex R: scratchReg.
	jumpIsContext := cogit JumpZero: 0.
	self genGetClassObjectOfClassIndex: formatReg into: Extra0Reg scratchReg: scratchReg.
	self genLoadSlot: InstanceSpecificationIndex sourceReg: Extra0Reg destReg: formatReg.
	self genConvertSmallIntegerToIntegerInReg: formatReg.
	cogit
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
CogObjectRepresentationFor64BitSpur >> genGetSmallFloatValueOf: oopReg scratch: scratch into: dpReg [
	"Convert the SmallFloat oop in ooppReg into the corresponding float value in dpReg.
	 c.f. Spur64BitMemoryManager>>smallFloatBitsOf:"
	| jumpSFZero |
	<var: 'jumpSFZero' type: #'AbstractInstruction *'>
	cogit
		MoveR: oopReg R: scratch;
		LogicalShiftRightCq: objectMemory numTagBits R: scratch;
		CmpCq: 1 R: scratch.
	jumpSFZero := cogit JumpLessOrEqual: 0.
	cogit AddCq: objectMemory smallFloatExponentOffset << (objectMemory smallFloatMantissaBits + 1) R: scratch.
	jumpSFZero jmpTarget: (cogit RotateRightCq: 1 R: scratch).
	cogit MoveR: scratch Rd: dpReg.
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genIntegerTo64BitPositiveIntegerValue: valueReg into: resultReg scratchReg: scratch1 scratchReg: scratch2 [
	<var: #jumpFail type: #'AbstractInstruction *'>
	<var: #jumpNotSmallInteger type: #'AbstractInstruction *'>
	<var: #jumpMerge type: #'AbstractInstruction *'>
	
	| jumpNotSmallInteger jumpMerge jumpFail |
	cogit MoveR: valueReg R: scratch1.
	cogit LogicalShiftRightCq: self numSmallIntegerBits - 1 R: scratch1. "If in range this is now 0"
	(cogit lastOpcode setsConditionCodesFor: JumpZero) ifFalse:
		[cogit CmpCq: 0 R: scratch1]. "N.B. FLAGS := ClassReg - 0"
	jumpNotSmallInteger := cogit JumpNonZero: 0.
	
	cogit MoveR: valueReg R: resultReg.
	self genConvertIntegerToSmallIntegerInReg: resultReg.
	jumpMerge := cogit Jump: 0.
			
	jumpNotSmallInteger jmpTarget: cogit Label.
	jumpFail := self genAlloc64BitPositiveIntegerValue: valueReg into: resultReg scratchReg: scratch1 scratchReg: scratch2.

	jumpMerge jmpTarget: cogit Label.
	^ jumpFail.
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genIntegerTo64BitSignedIntegerValue: valueReg into: resultReg scratchReg: scratch1 scratchReg: scratch2 [
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpFail type: #'AbstractInstruction *'>
	<var: #jumpNotSmallInteger type: #'AbstractInstruction *'>
	<var: #jumpMerge type: #'AbstractInstruction *'>
	
	| jumpNotSmallInteger jumpMerge jumpFail |
	cogit MoveR: valueReg R: scratch1.
	cogit ArithmeticShiftRightCq: self numSmallIntegerBits R: scratch1. "If in range this is now 0 or -1"
	cogit AddCq: 1 R: scratch1.
	cogit CmpCq: 1 R: scratch1.
	jumpNotSmallInteger := cogit JumpAbove: 0.
	
	cogit MoveR: valueReg R: resultReg.
	self genConvertIntegerToSmallIntegerInReg: resultReg.
	jumpMerge := cogit Jump: 0.
			
	jumpNotSmallInteger jmpTarget: cogit Label.
	jumpFail := self genAlloc64BitSignedIntegerValue: valueReg into: resultReg scratchReg: scratch1 scratchReg: scratch2.

	jumpMerge jmpTarget: cogit Label.
	^ jumpFail
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genJumpCharacter: reg [
	"Generate a compare and branch to test if aRegister contains a Character."
	^cogit
		TstCq: objectMemory characterTag R: reg;
		JumpNonZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genJumpCharacterInScratchReg: aRegister [
	^self genJumpCharacter: aRegister
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genJumpIsSmallIntegerValue: aRegister scratch: scratchReg [
	"Generate a test for aRegister containing an integer value in the SmallInteger range, and a jump if so, answering the jump.
	 c.f. Spur64BitMemoryManager>>isIntegerValue:"
	<returnTypeC: #'AbstractInstruction *'>
	^cogit
		MoveR: aRegister R: scratchReg;
		ArithmeticShiftRightCq: 63 - objectMemory numTagBits R: scratchReg;
		AddCq: 1 R: scratchReg;
		AndCq: 1 << (objectMemory numTagBits + 1) - 1 R: scratchReg; "sign and top numTags bits must be the same"
		CmpCq: 1 R: scratchReg;
		JumpLessOrEqual: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genJumpNotCharacter: reg [
	"Generate a compare and branch to test if aRegister contains other than a Character."
	^cogit
		TstCq: objectMemory characterTag R: reg;
		JumpZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genJumpNotCharacterInScratchReg: reg [ 
	<inline: true>
	^self genJumpNotCharacter: reg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genJumpNotSmallFloat: reg [
	"Generate a compare and branch to test if aRegister contains other than a SmallFloat.
	 Answer the jump."
	^cogit
		TstCq: objectMemory smallFloatTag R: reg;
		JumpZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genJumpNotSmallFloatInScratchReg: aRegister [
	<inline: true>
	^self genJumpNotSmallFloat: aRegister
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genJumpNotSmallFloatValueBits: reg scratch: exponent [
	"Generate a test to check that the integer register contains a floating point value within the SmallFloat64 range,
	 and answer the jump.  c.f. Spur64BitMemoryManager>>isSmallFloatValue:"
	| jumpFail jumpTest jumpMinExponent jumpMaxExponent jumpZeroMantissa |
	<var: #jumpFail type: #'AbstractInstruction *'>
	<var: #jumpTest type: #'AbstractInstruction *'>
	<var: #jumpMinExponent type: #'AbstractInstruction *'>
	<var: #jumpMaxExponent type: #'AbstractInstruction *'>
	<var: #jumpZeroMantissa type: #'AbstractInstruction *'>
	self flag: 'if we combine the exponent range test with the conversion to tagged representation we test for a zero exponent only once. further, if we extract tags once into a scratch on the input side we test for immediates, SmallInteger and SmallFloat using the same intermediate result.  so to do is to move fp arithmetic into the object representations'.
	cogit MoveR: reg R: exponent.
	true
		ifTrue: [cogit
				LogicalShiftLeftCq: 1 R: exponent; "drop sign"
				LogicalShiftRightCq: objectMemory smallFloatMantissaBits + 1 R: exponent] "shift exponent down"
		ifFalse: [cogit
				LogicalShiftRightCq: objectMemory smallFloatMantissaBits R: exponent;
				AndCq: 16r7FF R: exponent].  "ieee double precision mantissa is 11 bits"
	cogit CmpCq: objectMemory smallFloatExponentOffset R: exponent.
	jumpMinExponent := cogit JumpLessOrEqual: 0.
	cogit CmpCq: 255 + objectMemory smallFloatExponentOffset R: exponent. "SmallFloat exponent is 8 bits"
	jumpMaxExponent := cogit JumpLessOrEqual: 0.
	jumpFail :=
	cogit Jump: 0.
	jumpMinExponent jmpTarget:
	(cogit TstCq: 1 << objectMemory smallFloatMantissaBits - 1 R: reg). "test mantissa bits"
	jumpZeroMantissa := cogit JumpZero: 0.
	cogit CmpCq: objectMemory smallFloatExponentOffset R: exponent.
	jumpTest :=
	cogit Jump: 0.
	jumpZeroMantissa jmpTarget:
	(cogit CmpCq: 0 R: exponent).
	jumpTest jmpTarget:
	(cogit JumpNonZero: jumpFail).
	jumpMaxExponent jmpTarget: cogit Label.
	^jumpFail
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genJumpNotSmallInteger: reg [
	"Generate a compare and branch to test if aRegister contains other than a SmallInteger."
	^cogit
		TstCq: objectMemory smallIntegerTag R: reg;
		JumpZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genJumpNotSmallIntegerInScratchReg: aRegister [
	<inline: true>
	^self genJumpNotSmallInteger: aRegister
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genJumpNotSmallIntegerValue: aRegister scratch: scratchReg [
	"Generate a test for aRegister containing an integer value outside the SmallInteger range, and a jump if so, answering the jump.
	 c.f. Spur64BitMemoryManager>>isIntegerValue:"
	<returnTypeC: #'AbstractInstruction *'>
	^cogit
		MoveR: aRegister R: scratchReg;
		ArithmeticShiftRightCq: 64 - objectMemory numTagBits R: scratchReg;
		AddCq: 1 R: scratchReg;
		AndCq: 1 << (objectMemory numTagBits + 1) - 1 R: scratchReg; "sign and top numTags bits must be the same"
		CmpCq: 1 R: scratchReg;
		JumpGreater: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genJumpSmallFloat: aRegister [
	"Generate a compare and branch to test if aRegister contains a SmallFloat.
	 Answer the jump, or UnimplementedOperation if this cannot be done with
	 a single register."
	^cogit
		TstCq: objectMemory smallFloatTag R: aRegister;
		JumpNonZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genJumpSmallFloatInScratchReg: aRegister [
	^self genJumpSmallFloat: aRegister
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genJumpSmallInteger: aRegister [
	"Generate a compare and branch to test if aRegister contains a SmallInteger.
	 Answer the jump, or UnimplementedOperation if this cannot be done with
	 a single register."
	^cogit
		TstCq: objectMemory smallIntegerTag R: aRegister;
		JumpNonZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genJumpSmallIntegerInScratchReg: aRegister [
	^self genJumpSmallInteger: aRegister
]

{ #category : #'inline primitive support' }
CogObjectRepresentationFor64BitSpur >> genLcInt32ToOop: value [
	<option: #LowcodeVM>
	cogit SignExtend32R: value R: value.
	self genConvertIntegerToSmallIntegerInReg: value.
	cogit ssPushRegister: value.
	^ 0
]

{ #category : #'inline primitive support' }
CogObjectRepresentationFor64BitSpur >> genLcOopToInt32: value [
	<option: #LowcodeVM>
	self genConvertSmallIntegerToIntegerInReg: value.
	cogit ssPushNativeRegister: value.
	^ 0
]

{ #category : #'inline primitive support' }
CogObjectRepresentationFor64BitSpur >> genLcOopToUInt32: value [
	<option: #LowcodeVM>
	self genConvertSmallIntegerToIntegerInReg: value.
	cogit ssPushNativeRegister: value.
	^ 0
]

{ #category : #'inline primitive support' }
CogObjectRepresentationFor64BitSpur >> genLcUInt32ToOop: value [
	<option: #LowcodeVM>
	cogit ZeroExtend32R: value R: value.
	self genConvertIntegerToSmallIntegerInReg: value.
	cogit ssPushRegister: value.
	^ 0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveAtPutSigned: signedVersion [
	"Generate the code for primitives 61 & 165, at:put:/basicAt:put: & integerAt:put:.  If signedVersion is true
	 then generate signed accesses to the bits classes (a la 164 & 165).  If signedVersion is false,
	 generate unsigned accesses (a la 60, 61, 63 & 64)."
	| formatReg nSlotsOrBytesReg methodInBounds
	  jumpImmediate jumpBadIndex jumpImmutable jumpNotIndexablePointers jumpNotIndexableBits
	  jumpIsContext jumpIsCompiledMethod jumpIsBytes jumpIsShorts jumpIsWords jumpHasFixedFields
	  jumpArrayOutOfBounds jumpFixedFieldsOutOfBounds
	  jumpWordsOutOfBounds jumpShortsOutOfBounds jumpBytesOutOfBounds
	  jumpShortsOutOfRange jumpWordsOutOfRange jumpBytesOutOfRange jumpDoubleWordsOutOfRange
	  jumpNonSmallIntegerValue jumpNotPointers
	  rejoin jumpNegative jump64BitsOutOfBounds jumpNot64BitIndexable jump64BitArgIsImmediate jumpNot8ByteInteger
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
	self genGetClassObjectOfClassIndex: formatReg into: Extra0Reg scratchReg: TempReg.
	self genLoadSlot: InstanceSpecificationIndex sourceReg: Extra0Reg destReg: formatReg.
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
	jumpIsWords := cogit JumpAboveOrEqual: 0.
					cogit CmpCq: objectMemory sixtyFourBitIndexableFormat R: formatReg.
	jumpNotIndexableBits := cogit JumpNonZero: 0.
	"fall through to 64-bit words"
	cogit MoveR: Arg1Reg R: SendNumArgsReg.
	self genConvertSmallIntegerToIntegerInReg: SendNumArgsReg.
	signedVersion ifFalse:
		[cogit CmpCq: 0 R: SendNumArgsReg.
		 jumpNegative := cogit JumpLess: 0].
	rejoin :=
	cogit CmpR: Arg0Reg R: nSlotsOrBytesReg.
	jump64BitsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg0Reg.
	cogit MoveR: SendNumArgsReg Xwr: Arg0Reg R: ReceiverResultReg.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit genPrimReturn.

	"Handle LargePositiveInteger (unsigned) or LargePositiveInteger and LargeNegativeInteger (signed)
	 for sixtyFourBitIndexableFormat"
	jumpNonSmallIntegerValue jmpTarget:
		(cogit CmpCq: objectMemory sixtyFourBitIndexableFormat R: formatReg).
	jumpNot64BitIndexable := cogit JumpNonZero: 0.
	jump64BitArgIsImmediate := self genJumpImmediate: Arg1Reg.
	signedVersion ifTrue: "Test top bit of 64-bit word in large integer for range check."
		[cogit MoveMw: objectMemory baseHeaderSize r: Arg1Reg R: TempReg.
		 cogit CmpCq: 0 R: TempReg.
		 jumpDoubleWordsOutOfRange := cogit JumpLess: 0].
	"Now check if the header is that of an 8 byte LargePositiveInteger"
	cogit MoveMw: 0 r: Arg1Reg R: SendNumArgsReg.
	cogit AndCq: (objectMemory
						headerForSlots: objectMemory numSlotsMask
						format: objectMemory formatMask
						classIndex: objectMemory classIndexMask)
		R: SendNumArgsReg.
	cogit CmpCq: (objectMemory
						headerForSlots: 1
						format: objectMemory firstByteFormat
						classIndex: ClassLargePositiveIntegerCompactIndex)
		R: SendNumArgsReg.
	jumpNot8ByteInteger := cogit JumpNonZero: 0.
	cogit MoveMw: objectMemory baseHeaderSize r: Arg1Reg R: SendNumArgsReg.
	cogit Jump: rejoin.
	signedVersion ifTrue:
		["Now check if the header is that of an 8 byte LargeNegativeInteger"
		 jumpNot8ByteInteger jmpTarget:
		 (cogit CmpCq: (objectMemory
							headerForSlots: 1
							format: objectMemory firstByteFormat
							classIndex: ClassLargeNegativeIntegerCompactIndex)
				R: SendNumArgsReg).
		 jumpNot8ByteInteger := cogit JumpNonZero: 0.
		 cogit MoveMw: objectMemory baseHeaderSize r: Arg1Reg R: TempReg.
		 cogit MoveCq: 0 R: SendNumArgsReg.
		 cogit SubR: TempReg R: SendNumArgsReg.
		 cogit Jump: rejoin].

	signedVersion
		ifTrue:
			[jumpIsWords jmpTarget:
			 (cogit MoveR: SendNumArgsReg R: TempReg).
			 cogit ArithmeticShiftRightCq: 31 R: TempReg. "Maps in range to -1,0".
			 cogit AddCq: 1 R: TempReg. "Maps in range to 0,1"
			 cogit CmpCq: 1 R: TempReg]
		ifFalse:
			[jumpIsWords jmpTarget:
			 (cogit CmpCq: (objectMemory integerObjectOf: 16rFFFFFFFF) R: Arg1Reg)].
	jumpWordsOutOfRange := cogit JumpAbove: 0.
	cogit LogicalShiftLeftCq: objectMemory shiftForWord - 2 R: nSlotsOrBytesReg.
	cogit AndCq: objectMemory wordSize / 4 - 1 R: formatReg.
	cogit SubR: formatReg R: nSlotsOrBytesReg.
	cogit CmpR: Arg0Reg R: nSlotsOrBytesReg.
	jumpWordsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit MoveR: Arg1Reg R: TempReg.
	self genConvertSmallIntegerToIntegerInReg: TempReg.
	cogit AddCq: objectMemory baseHeaderSize >> (objectMemory shiftForWord - 1) R: Arg0Reg.
	cogit MoveR: TempReg X32r: Arg0Reg R: ReceiverResultReg.
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

	
	jumpNot8ByteInteger jmpTarget:
	(jump64BitArgIsImmediate jmpTarget:
	(jumpNot64BitIndexable jmpTarget:
	(jumpIsContext jmpTarget:
	(jumpNotIndexableBits jmpTarget:
	(jumpBytesOutOfRange jmpTarget:
	(jumpShortsOutOfRange jmpTarget:
	(jumpWordsOutOfRange jmpTarget:
	(jumpIsCompiledMethod jmpTarget:
	(jumpArrayOutOfBounds jmpTarget:
	(jumpBytesOutOfBounds jmpTarget:
	(jumpShortsOutOfBounds jmpTarget:
	(jumpWordsOutOfBounds jmpTarget:
	(jump64BitsOutOfBounds jmpTarget:
	(jumpNotIndexablePointers jmpTarget:
	(jumpFixedFieldsOutOfBounds jmpTarget: cogit Label))))))))))))))).
	signedVersion
		ifTrue: [jumpDoubleWordsOutOfRange jmpTarget: jumpIsContext getJmpTarget]
		ifFalse: [jumpNegative jmpTarget: jumpIsContext getJmpTarget].
	self cppIf: IMMUTABILITY
		ifTrue: [jumpImmutable jmpTarget: jumpIsContext getJmpTarget].

	cogit AddCq: 1 R: Arg0Reg. "0-rel => 1-rel"
	self genConvertIntegerToSmallIntegerInReg: Arg0Reg.

	jumpBadIndex jmpTarget: (jumpImmediate jmpTarget: cogit Label).

	^0 "Can't be complete because of contexts."
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveAtSigned: signedVersion [
	"Generate the code for primitives 60 & 164, at:/basicAt: & integerAt:.  If signedVersion is true
	 then generate signed accesses to the bits classes (a la 164 & 165).  If signedVersion is false,
	 generate unsigned accesses (a la 60, 61, 63 & 64)."
	| formatReg nSlotsOrElementsReg convertToIntAndReturn methodInBounds
	  jumpNotIndexable jumpImmediate jumpBadIndex
	  jumpIsBytes jumpIsShorts jumpIsWords jumpIsLongs jumpIsMethod jumpIsArray jumpIsContext
	  jumpHasFixedFields jumpArrayOutOfBounds jumpFixedFieldsOutOfBounds
	  jumpBytesOutOfBounds jumpShortsOutOfBounds jumpWordsOutOfBounds jumpLongsOutOfBounds
	  jumpFailAlloc jumpNotSmallInteger |
	"c.f. StackInterpreter>>stSizeOf: SpurMemoryManager>>lengthOf:format: fixedFieldsOf:format:length:"

	nSlotsOrElementsReg := ClassReg.

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

	self genGetNumSlotsOf: ReceiverResultReg into: nSlotsOrElementsReg.

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
					cogit CmpCq: objectMemory sixtyFourBitIndexableFormat R: formatReg.
	jumpIsLongs := cogit JumpZero: 0.
	jumpNotIndexable jmpTarget: cogit Label.
	jumpNotIndexable := cogit Jump: 0.

	jumpIsArray jmpTarget:
		(cogit CmpR: Arg1Reg R: nSlotsOrElementsReg).
	jumpArrayOutOfBounds := cogit JumpBelowOrEqual: 0.	
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg1Reg.
	cogit MoveXwr: Arg1Reg R: ReceiverResultReg R: ReceiverResultReg.
	cogit genPrimReturn.

	jumpIsBytes jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord R: nSlotsOrElementsReg).
		cogit AndCq: 7 R: formatReg R: TempReg.
		cogit SubR: TempReg R: nSlotsOrElementsReg;
		CmpR: Arg1Reg R: nSlotsOrElementsReg.
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
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord - 1 R: nSlotsOrElementsReg).
		cogit AndCq: 3 R: formatReg.
		cogit SubR: formatReg R: nSlotsOrElementsReg;
		CmpR: Arg1Reg R: nSlotsOrElementsReg.
	jumpShortsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddR: Arg1Reg R: ReceiverResultReg.
	cogit AddR: Arg1Reg R: ReceiverResultReg.
	cogit MoveM16: objectMemory baseHeaderSize r: ReceiverResultReg R: ReceiverResultReg.
	signedVersion ifTrue:
		[cogit SignExtend16R: ReceiverResultReg R: ReceiverResultReg].
	cogit Jump: convertToIntAndReturn.

	jumpIsWords jmpTarget:
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord - 2 R: nSlotsOrElementsReg).
		cogit AndCq: 1 R: formatReg.
		cogit SubR: formatReg R: nSlotsOrElementsReg;
		CmpR: Arg1Reg R: nSlotsOrElementsReg.
	jumpWordsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddCq: objectMemory baseHeaderSize >>  (objectMemory shiftForWord - 1) R: Arg1Reg.
	cogit MoveX32r: Arg1Reg R: ReceiverResultReg R: TempReg.
	cogit MoveR: TempReg R: ReceiverResultReg.
	signedVersion ifTrue:
		[cogit SignExtend32R: ReceiverResultReg R: ReceiverResultReg].
	cogit Jump: convertToIntAndReturn.

	jumpHasFixedFields jmpTarget:
		(cogit AndCq: objectMemory classIndexMask R: TempReg).
	cogit MoveR: TempReg R: formatReg.
	cogit CmpCq: ClassMethodContextCompactIndex R: TempReg.
	jumpIsContext := cogit JumpZero: 0.
	self genGetClassObjectOfClassIndex: formatReg into: Extra0Reg scratchReg: TempReg.
	self genLoadSlot: InstanceSpecificationIndex sourceReg: Extra0Reg destReg: formatReg.
	self genConvertSmallIntegerToIntegerInReg: formatReg.
	cogit
		AndCq: objectMemory fixedFieldsOfClassFormatMask R: formatReg;
		SubR: formatReg R: nSlotsOrElementsReg;
		CmpR: Arg1Reg R: nSlotsOrElementsReg.
	jumpFixedFieldsOutOfBounds := cogit JumpBelowOrEqual: 0.
	"index is (formatReg (fixed fields) + Arg1Reg (0-rel index)) * wordSize + baseHeaderSize"
	cogit AddR: formatReg R: Arg1Reg.
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg1Reg.
	cogit MoveXwr: Arg1Reg R: ReceiverResultReg R: ReceiverResultReg.
	cogit genPrimReturn.

	jumpIsLongs jmpTarget:
		(cogit CmpR: Arg1Reg R: nSlotsOrElementsReg).
	jumpLongsOutOfBounds := cogit JumpBelowOrEqual: 0.	
	cogit AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg1Reg.
	cogit MoveXwr: Arg1Reg R: ReceiverResultReg R: ClassReg.
	cogit MoveR: ClassReg R: TempReg.
	signedVersion
		ifTrue: "c.f. Spur64BitMemoryManager>>#isIntegerValue:"
			[cogit ArithmeticShiftRightCq: self numSmallIntegerBits R: TempReg. "If in range this is now 0 or -1"
			 cogit AndCq: 16rF R: TempReg.
			 cogit CmpCq: 1 R: TempReg.
			 jumpNotSmallInteger := cogit JumpAbove: 0.
			 cogit MoveR: ClassReg R: ReceiverResultReg.
			 cogit Jump: convertToIntAndReturn.
			 jumpNotSmallInteger jmpTarget: cogit Label.
			 jumpFailAlloc := self genAlloc64BitSignedIntegerValue: ClassReg into: SendNumArgsReg scratchReg: Extra0Reg scratchReg: TempReg.
			 cogit MoveR: SendNumArgsReg R: ReceiverResultReg.
			 cogit genPrimReturn]
		ifFalse:
			[cogit LogicalShiftRightCq: self numSmallIntegerBits - 1 R: TempReg. "If in range this is now 0"
			 (cogit lastOpcode setsConditionCodesFor: JumpZero) ifFalse:
				[cogit CmpCq: 0 R: TempReg]. "N.B. FLAGS := ClassReg - 0"
			 jumpNotSmallInteger := cogit JumpNonZero: 0.
			 cogit MoveR: ClassReg R: ReceiverResultReg.
			 cogit Jump: convertToIntAndReturn.
			 jumpNotSmallInteger jmpTarget: cogit Label.
			 jumpFailAlloc := self genAlloc64BitPositiveIntegerValue: ClassReg into: SendNumArgsReg scratchReg: Extra0Reg scratchReg: TempReg.
			 cogit MoveR: SendNumArgsReg R: ReceiverResultReg.
			 cogit genPrimReturn].

	jumpIsMethod jmpTarget: cogit Label.
	"Now check that the index is beyond the method's literals..."
	self getLiteralCountOf: ReceiverResultReg plusOne: true inBytes: true into: nSlotsOrElementsReg scratch: TempReg.
	cogit CmpR: Arg1Reg R: nSlotsOrElementsReg.
	cogit JumpBelow: methodInBounds.

	jumpFailAlloc jmpTarget:
	(jumpLongsOutOfBounds jmpTarget:
	(jumpFixedFieldsOutOfBounds jmpTarget:
	(jumpArrayOutOfBounds jmpTarget:
	(jumpBytesOutOfBounds jmpTarget:
	(jumpShortsOutOfBounds jmpTarget:
	(jumpWordsOutOfBounds jmpTarget:
	(jumpNotIndexable jmpTarget:
	(jumpIsContext jmpTarget:
	(jumpBadIndex jmpTarget:
	(jumpImmediate jmpTarget: cogit Label)))))))))).

	^0 "Can't be complete because of contexts."
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveIdentityHash [
	"Arguably we should fail for immediates, but so far no one has complained, so..."
	| jumpImm jumpNotSet jumpNotCharacter ret |
	<var: #jumpImm type: #'AbstractInstruction *'>
	<var: #jumpNotSet type: #'AbstractInstruction *'>
	<var: #jumpNotCharacter type: #'AbstractInstruction *'>
	jumpImm := self genJumpImmediate: ReceiverResultReg. "uses TstCqR"
	self genGetHashFieldNonImmOf: ReceiverResultReg asSmallIntegerInto: TempReg.
	cogit CmpCq: ConstZero R: TempReg.
	jumpNotSet := cogit JumpZero: 0.
	cogit MoveR: TempReg R: ReceiverResultReg.
	ret := cogit genPrimReturn.
	jumpImm jmpTarget: (cogit AndCq: objectMemory tagMask R: ReceiverResultReg R: TempReg).
	cogit CmpCq: objectMemory characterTag R: TempReg.
	jumpNotCharacter := cogit JumpNonZero: 0.
	self genConvertCharacterToSmallIntegerInReg: ReceiverResultReg.
	ret := cogit genPrimReturn.
	jumpNotCharacter jmpTarget: (cogit CmpCq: objectMemory smallFloatTag R: TempReg).
	cogit JumpNonZero: ret.
	self genConvertSmallFloatToSmallFloatHashAsIntegerInReg: ReceiverResultReg scratch: TempReg.
	cogit genPrimReturn.
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
CogObjectRepresentationFor64BitSpur >> genPrimitiveImmediateAsInteger [
	| jumpNotCharacter ret |
	<var: #jumpNotCharacter type: #'AbstractInstruction *'>
	jumpNotCharacter := cogit
		AndCq: objectMemory tagMask R: ReceiverResultReg R: TempReg;
		CmpCq: objectMemory characterTag R: TempReg;
		JumpNonZero: 0.
	self genConvertCharacterToSmallIntegerInReg: ReceiverResultReg.
	ret := cogit genPrimReturn.
	jumpNotCharacter jmpTarget:
		(cogit CmpCq: objectMemory smallFloatTag R: TempReg).
	cogit JumpNonZero: ret.
	self genConvertSmallFloatToSmallFloatHashAsIntegerInReg: ReceiverResultReg scratch: TempReg.
	cogit genPrimReturn.
	^UnfailingPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveLoadInt32FromBytes [
	^ self genPrimitiveLoad: 4 fromBytesWith: [ :sourcePointer |
		cogit MoveM32: 0 r: sourcePointer R: ReceiverResultReg.
		cogit SignExtend32R: ReceiverResultReg R: ReceiverResultReg.
	
		self genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
		cogit genPrimReturn
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveLoadInt32FromExternalAddress [
	^ self genPrimitiveLoadFromExternalAddressWith: [ :sourcePointer |
		cogit MoveM32: 0 r: sourcePointer R: ReceiverResultReg.
		cogit SignExtend32R: ReceiverResultReg R: ReceiverResultReg.
	
		self genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
		cogit genPrimReturn
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveLoadInt64FromBytes [
	^ self genPrimitiveLoad: 8 fromBytesWith: [ :sourcePointer |
		| jumpFailAlloc |
		cogit MoveM64: 0 r: sourcePointer R: ClassReg.
		jumpFailAlloc := self genIntegerTo64BitSignedIntegerValue: ClassReg into: SendNumArgsReg scratchReg: Extra0Reg scratchReg: TempReg.
		cogit MoveR: SendNumArgsReg R: ReceiverResultReg.
		cogit genPrimReturn.
		jumpFailAlloc jmpTarget: cogit Label
	] needsToTrap: true.
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveLoadInt64FromExternalAddress [
	^ self genPrimitiveLoadFromExternalAddressWith: [ :sourcePointer |
		| jumpFailAlloc |
		cogit MoveM64: 0 r: sourcePointer R: ClassReg.
		jumpFailAlloc := self genIntegerTo64BitSignedIntegerValue: ClassReg into: SendNumArgsReg scratchReg: Extra0Reg scratchReg: TempReg.
		cogit MoveR: SendNumArgsReg R: ReceiverResultReg.
		cogit genPrimReturn.
		jumpFailAlloc jmpTarget: cogit Label
	] needsToTrap: true.
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveLoadUInt32FromBytes [
	^ self genPrimitiveLoad: 4 fromBytesWith: [ :sourcePointer |
		cogit MoveM32: 0 r: sourcePointer R: ReceiverResultReg.
		cogit ZeroExtend32R: ReceiverResultReg R: ReceiverResultReg.
	
		self genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
		cogit genPrimReturn
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveLoadUInt32FromExternalAddress [
	^ self genPrimitiveLoadFromExternalAddressWith: [ :sourcePointer |
		cogit MoveM32: 0 r: sourcePointer R: ReceiverResultReg.
		cogit ZeroExtend32R: ReceiverResultReg R: ReceiverResultReg.
	
		self genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
		cogit genPrimReturn
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveLoadUInt64FromBytes [
	^ self genPrimitiveLoad: 8 fromBytesWith: [ :sourcePointer |
		| jumpFailAlloc |
		cogit MoveM64: 0 r: sourcePointer R: ClassReg.
		jumpFailAlloc := self genIntegerTo64BitPositiveIntegerValue: ClassReg into: SendNumArgsReg scratchReg: Extra0Reg scratchReg: TempReg.
		cogit MoveR: SendNumArgsReg R: ReceiverResultReg.
		cogit genPrimReturn.
		jumpFailAlloc jmpTarget: cogit Label
	] needsToTrap: true.
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveLoadUInt64FromExternalAddress [
	^ self genPrimitiveLoadFromExternalAddressWith: [ :sourcePointer |
		| jumpFailAlloc |
		cogit MoveM64: 0 r: sourcePointer R: ClassReg.
		jumpFailAlloc := self genIntegerTo64BitPositiveIntegerValue: ClassReg into: SendNumArgsReg scratchReg: Extra0Reg scratchReg: TempReg.
		cogit MoveR: SendNumArgsReg R: ReceiverResultReg.
		cogit genPrimReturn.
		jumpFailAlloc jmpTarget: cogit Label
	] needsToTrap: true.
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveMirrorNew [
	"Implement 1-arg (instantiateFixedClass:) primitiveNew for convenient cases:
	- the class argument has a hash
	- the class argument is fixed size (excluding ephemerons to save instructions & miniscule time)
	- single word header/num slots < numSlotsMask
	- the result fits in eden (actually below scavengeThreshold)"

	<option: #NewspeakVM>
	| headerReg fillReg instSpecReg byteSizeReg
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

	self assert: cogit methodNumArgs = 1.
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.

	"header will contain classIndex/class's hash & format & numSlots/fixed size and finally fill value (nilObject)."
	headerReg := fillReg := SendNumArgsReg.
	"inst spec will hold class's instance specification, then byte size and finally end of new object."
	instSpecReg := byteSizeReg := ClassReg.

	"get freeStart as early as possible so as not to wait later..."
	cogit MoveAw: objectMemory freeStartAddress R: Arg1Reg.

	"validate class arg; sigh, this mirror crap hobbles unfairly; there is a better way with selector namespaces..."
	jumpImmediate := self genJumpImmediate: Arg0Reg.

	"Is the class arg pointers with at least 3 fields?"
	self genGetFormatOf: Arg0Reg
		into: TempReg
		leastSignificantHalfOfBaseHeaderIntoScratch: NoReg.
	cogit CmpCq: objectMemory nonIndexablePointerFormat R: TempReg.
	jumpNotFixedPointers := cogit JumpNonZero: 0.
	
	self genGetRawSlotSizeOfNonImm: Arg0Reg into: TempReg.
	cogit CmpCq: InstanceSpecificationIndex + 1 R: TempReg.
	jumpTooSmall := cogit JumpLess: 0.

	"get class's hash & fail if 0"
	self genGetHashFieldNonImmOf: Arg0Reg into: headerReg.
	jumpUnhashed := cogit JumpZero: 0.

	"get class's format inst var for both inst spec (format field) and num fixed fields"
	self genLoadSlot: InstanceSpecificationIndex sourceReg: Arg0Reg destReg: instSpecReg.
	jumpBadFormat := self genJumpNotSmallInteger: instSpecReg scratchReg: TempReg.
	self genConvertSmallIntegerToIntegerInReg: instSpecReg.
	cogit MoveR: instSpecReg R: TempReg.
	cogit LogicalShiftRightCq: objectMemory fixedFieldsFieldWidth R: TempReg.
	cogit AndCq: objectMemory formatMask R: TempReg.
	cogit AndCq: objectMemory fixedFieldsOfClassFormatMask R: instSpecReg.
	"fail if not fixed or if ephemeron (rare beasts so save the cycles)"
	cogit CmpCq: objectMemory nonIndexablePointerFormat R: TempReg.
	jumpVariableOrEphemeron := cogit JumpAbove: 0.
	cogit CmpCq: objectMemory numSlotsMask R: instSpecReg.
	jumpTooBig := cogit JumpAboveOrEqual: 0.
	"Add format to classIndex/format in header; then add in numSlots"
	cogit LogicalShiftLeftCq: objectMemory formatShift R: TempReg.
	cogit AddR: TempReg R: headerReg.
	cogit MoveR: instSpecReg R: TempReg.
	cogit LogicalShiftLeftCq: objectMemory numSlotsFullShift R: TempReg.
	cogit AddR: TempReg R: headerReg.
	"compute byte size; remember 0-sized objects still need 1 slot."
	cogit CmpCq: 0 R: byteSizeReg. "a.k.a. instSpecReg"
	jumpHasSlots := cogit JumpNonZero: 0.
	cogit MoveCq: objectMemory baseHeaderSize * 2 R: byteSizeReg.
	skip := cogit Jump: 0.
	"round up to allocationUnit"
	jumpHasSlots jmpTarget:
	(cogit AddCq: objectMemory baseHeaderSize / objectMemory wordSize R: byteSizeReg).
	cogit LogicalShiftLeftCq: objectMemory shiftForWord R: byteSizeReg.
	skip jmpTarget:
	"check if allocation fits (freeSize + byteSize < scavengeThreshold); scavengeThreshold is constant."
	(cogit AddR: Arg1Reg R: byteSizeReg).
	cogit CmpCq: objectMemory getScavengeThreshold R: byteSizeReg.
	jumpNoSpace := cogit JumpAboveOrEqual: 0.
	"write back new freeStart; get result. byteSizeReg holds new freeStart, the limit of the object"
	cogit MoveR: byteSizeReg Aw: objectMemory freeStartAddress.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	"write header"
	cogit MoveR: headerReg Mw: 0 r: Arg1Reg.
	"now fill"
	cogit LoadEffectiveAddressMw: objectMemory baseHeaderSize r: ReceiverResultReg R: Arg1Reg.
	cogit MoveCq: objectMemory nilObject R: fillReg.
	fillLoop := 
	cogit MoveR: fillReg Mw: 0 r: Arg1Reg.
	cogit AddCq: 8 R: Arg1Reg.
	cogit CmpR: Arg1Reg R: byteSizeReg.
	cogit JumpAbove: fillLoop.
	cogit genPrimReturn.

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
CogObjectRepresentationFor64BitSpur >> genPrimitiveMirrorNewWithArg [
	"Implement instantiateVariableClass:withSize: for convenient cases:
	- the class argument has a hash
	- the class argument is variable and not compiled method
	- single word header/num slots < numSlotsMask
	- the result fits in eden
	See superclass method for dynamic frequencies of formats.
	For the moment we implement only arrayFormat, firstByteFormat & firstLongFormat"

	<option: #NewspeakVM>
	| headerReg fillReg instSpecReg byteSizeReg maxSlots
	  jumpArrayTooBig jumpByteTooBig jumpLongTooBig
	  jumpArrayFormat jumpByteFormat jumpBytePrepDone jumpLongPrepDone
	  jumpUnhashed jumpTooSmall jumpImmediate
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

	self assert: cogit methodNumArgs = 2.
	cogit genLoadArgAtDepth: 1 into: Arg0Reg. "class arg"
	cogit genLoadArgAtDepth: 0 into: Arg1Reg. "num indexable slots arg"
	"header will contain classIndex/class's hash & format & numSlots/fixed size"
	headerReg := SendNumArgsReg.
	"Assume there's an available scratch register on 64-bit machines.  This holds the saved numFixedFields and then the value to fill with"
	fillReg := Extra0Reg.
	self assert: fillReg > 0.
	"inst spec will hold class's instance specification and then byte size"
	instSpecReg := byteSizeReg := ClassReg.
	"The max slots we'll allocate here are those for a single header"
	maxSlots := objectMemory numSlotsMask - 1.

	"check size and fail if not a +ve integer"
	jumpNElementsNonInt := self genJumpNotSmallInteger: Arg1Reg scratchReg: TempReg.

	"Is the class arg pointers with at least 3 fields?"
	jumpImmediate := self genJumpImmediate: Arg0Reg.
	self genGetRawSlotSizeOfNonImm: Arg0Reg into: TempReg.
	cogit CmpCq: InstanceSpecificationIndex + 1 R: TempReg.
	jumpTooSmall := cogit JumpLess: 0.

	"get freeStart as early as possible so as not to wait later..."
	cogit MoveAw: objectMemory freeStartAddress R: Arg1Reg.
	"get class's hash & fail if 0"
	self genGetHashFieldNonImmOf: ReceiverResultReg into: headerReg.
	jumpUnhashed := cogit JumpZero: 0.

	"The basicNew: code below (copied from genPrimitiveNewWithArg) expects class
	 in ReceiverResultReg and size in Arg0Reg.  Shuffle args to match, undoing on failure."
	cogit
		PushR: ReceiverResultReg;
		MoveR: Arg0Reg R: ReceiverResultReg;
		MoveR: Arg1Reg R: Arg0Reg.

	"get class's format inst var for inst spec (format field)"
	self genLoadSlot: InstanceSpecificationIndex sourceReg: ReceiverResultReg destReg: instSpecReg.
	cogit LogicalShiftRightCq: objectMemory fixedFieldsFieldWidth + self numSmallIntegerTagBits R: instSpecReg.
	cogit AndCq: objectMemory formatMask R: instSpecReg.
	"Add format to classIndex/format header now"
	cogit MoveR: instSpecReg R: TempReg.
	cogit LogicalShiftLeftCq: objectMemory formatShift R: TempReg.
	cogit AddR: TempReg R: headerReg.
	"get integer value of num fields in fillReg now"
	cogit MoveR: Arg0Reg R: fillReg.
	self genConvertSmallIntegerToIntegerInReg: fillReg.
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
	cogit MoveR: fillReg R: instSpecReg.
	"compute odd bits and add into headerReg; oddBits := 2 - nElements bitAnd: 1"
	cogit MoveCq: objectMemory wordSize / 4 R: TempReg.
	cogit SubR: instSpecReg R: TempReg.
	cogit AndCq: objectMemory wordSize / 4 - 1 R: TempReg.
	cogit LogicalShiftLeftCq: objectMemory formatShift R: TempReg.
	cogit AddR: TempReg R: headerReg.
	"round up num elements to numSlots in instSpecReg"
	cogit AddCq: objectMemory wordSize / 4 - 1 R: instSpecReg.
	cogit LogicalShiftRightCq: objectMemory shiftForWord - 2 R: instSpecReg.
	cogit MoveCq: 0 R: fillReg.
	jumpLongPrepDone := cogit Jump: 0. "go allocate"

	jumpByteFormat jmpTarget:
	(cogit CmpCq: (objectMemory integerObjectOf: maxSlots * objectMemory wordSize) R: Arg0Reg).
	jumpByteTooBig := cogit JumpAbove: 0.
	"save num elements to instSpecReg"
	cogit MoveR: fillReg R: instSpecReg.
	"compute odd bits and add into headerReg; oddBits := 4 - nElements bitAnd: 3"
	cogit MoveCq: objectMemory wordSize R: TempReg.
	cogit SubR: instSpecReg R: TempReg.
	cogit AndCq: objectMemory wordSize - 1 R: TempReg.
	cogit LogicalShiftLeftCq: objectMemory formatShift R: TempReg.
	cogit AddR: TempReg R: headerReg.
	"round up num elements to numSlots in instSpecReg"
	cogit AddCq: objectMemory wordSize - 1 R: instSpecReg.
	cogit LogicalShiftRightCq: objectMemory shiftForWord R: instSpecReg.
	cogit MoveCq: 0 R: fillReg.
	jumpBytePrepDone := cogit Jump: 0. "go allocate"

	jumpArrayFormat jmpTarget:
		(cogit CmpCq: (objectMemory integerObjectOf: maxSlots) R: Arg0Reg).
	jumpArrayTooBig := cogit JumpAbove: 0.
	"save num elements/slot size to instSpecReg"
	cogit MoveR: fillReg R: instSpecReg.
	cogit MoveCq: objectMemory nilObject R: fillReg.
	"fall through to allocate"

	jumpBytePrepDone jmpTarget:
	(jumpLongPrepDone jmpTarget: cogit Label).

	"store numSlots to headerReg"
	cogit MoveR: instSpecReg R: TempReg.
	cogit LogicalShiftLeftCq: objectMemory numSlotsFullShift R: TempReg.
	cogit AddR: TempReg R: headerReg.
	"compute byte size; remember 0-sized objects still need 1 slot."
	cogit CmpCq: 0 R: byteSizeReg. "a.k.a. instSpecReg"
	jumpHasSlots := cogit JumpNonZero: 0.
	cogit MoveCq: objectMemory baseHeaderSize * 2 R: byteSizeReg.
	skip := cogit Jump: 0.
	jumpHasSlots jmpTarget:
	(cogit AddCq: objectMemory baseHeaderSize / objectMemory wordSize R: byteSizeReg).
	cogit LogicalShiftLeftCq: objectMemory shiftForWord R: byteSizeReg.
	skip jmpTarget:
	"check if allocation fits"
	(cogit AddR: Arg1Reg R: byteSizeReg).
	cogit CmpCq: objectMemory getScavengeThreshold R: byteSizeReg.
	jumpNoSpace := cogit JumpAboveOrEqual: 0.
	"get result, increment freeStart and write it back. Arg1Reg holds new freeStart, the limit of the object"
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit MoveR: byteSizeReg Aw: objectMemory freeStartAddress.
	"write other half of header (numSlots/0 identityHash)"
	cogit MoveR: headerReg Mw: 0 r: ReceiverResultReg.
	"now fill"
	cogit PopR: TempReg. "discard pushed receiver"
	cogit LoadEffectiveAddressMw: objectMemory baseHeaderSize r: ReceiverResultReg R: Arg1Reg.
	fillLoop := 
	cogit MoveR: fillReg Mw: 0 r: Arg1Reg.
	cogit AddCq: 8 R: Arg1Reg.
	cogit CmpR: Arg1Reg R: byteSizeReg.
	cogit JumpAbove: fillLoop.
	cogit genPrimReturn.

	jumpFailCuzFixed jmpTarget:
	(jumpArrayTooBig jmpTarget:
	(jumpByteTooBig jmpTarget:
	(jumpLongTooBig jmpTarget:
	(jumpNoSpace jmpTarget:  cogit Label)))).

	"unshuffle arguments"
	cogit
		MoveR: Arg0Reg R: Arg1Reg;
		MoveR: ReceiverResultReg R: Arg0Reg;
		PopR: ReceiverResultReg.

	jumpUnhashed jmpTarget:
	(jumpImmediate jmpTarget:
	(jumpTooSmall jmpTarget:
	(jumpNElementsNonInt jmpTarget: cogit Label))).

	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveNew [
	"Implement primitiveNew for convenient cases:
	- the receiver has a hash
	- the receiver is fixed size (excluding ephemerons to save instructions & miniscule time)
	- single word header/num slots < numSlotsMask
	- the result fits in eden (actually below scavengeThreshold)"

	| headerReg fillReg instSpecReg byteSizeReg
	  jumpUnhashed jumpVariableOrEphemeron jumpNoSpace jumpTooBig jumpHasSlots
	  fillLoop skip |
	<var: 'skip' type: #'AbstractInstruction *'>
	<var: 'fillLoop' type: #'AbstractInstruction *'>
	<var: 'jumpTooBig' type: #'AbstractInstruction *'>
	<var: 'jumpHasSlots' type: #'AbstractInstruction *'>
	<var: 'jumpNoSpace' type: #'AbstractInstruction *'>
	<var: 'jumpUnhashed' type: #'AbstractInstruction *'>
	<var: 'jumpVariableOrEphemeron' type: #'AbstractInstruction *'>

	NewspeakVM ifTrue:
		[cogit methodNumArgs = 1 ifTrue:
			[^self genPrimitiveMirrorNew]].
	cogit methodNumArgs ~= 0 ifTrue:
		[^UnimplementedPrimitive].

	"header will contain classIndex/class's hash & format & numSlots/fixed size and finally fill value (nilObject)."
	headerReg := fillReg := SendNumArgsReg.
	"inst spec will hold class's instance specification, then byte size and finally end of new object."
	instSpecReg := byteSizeReg := ClassReg.

	"get freeStart as early as possible so as not to wait later..."
	cogit MoveAw: objectMemory freeStartAddress R: Arg1Reg.
	"get class's hash & fail if 0"
	self genGetHashFieldNonImmOf: ReceiverResultReg into: headerReg.
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
	"Add format to classIndex/format in header; the add in numSlots"
	cogit LogicalShiftLeftCq: objectMemory formatShift R: TempReg.
	cogit AddR: TempReg R: headerReg.
	cogit MoveR: instSpecReg R: TempReg.
	cogit LogicalShiftLeftCq: objectMemory numSlotsFullShift R: TempReg.
	cogit AddR: TempReg R: headerReg.
	"compute byte size; remember 0-sized objects still need 1 slot."
	cogit CmpCq: 0 R: byteSizeReg. "a.k.a. instSpecReg"
	jumpHasSlots := cogit JumpNonZero: 0.
	cogit MoveCq: objectMemory baseHeaderSize * 2 R: byteSizeReg.
	skip := cogit Jump: 0.
	"round up to allocationUnit"
	jumpHasSlots jmpTarget:
	(cogit AddCq: objectMemory baseHeaderSize / objectMemory wordSize R: byteSizeReg).
	cogit LogicalShiftLeftCq: objectMemory shiftForWord R: byteSizeReg.
	skip jmpTarget:
	"check if allocation fits (freeSize + byteSize < scavengeThreshold); scavengeThreshold is constant."
	(cogit AddR: Arg1Reg R: byteSizeReg).
	cogit CmpCq: objectMemory getScavengeThreshold R: byteSizeReg.
	jumpNoSpace := cogit JumpAboveOrEqual: 0.
	"write back new freeStart; get result. byteSizeReg holds new freeStart, the limit of the object"
	cogit MoveR: byteSizeReg Aw: objectMemory freeStartAddress.
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	"write header"
	cogit MoveR: headerReg Mw: 0 r: Arg1Reg.
	"now fill"
	cogit LoadEffectiveAddressMw: objectMemory baseHeaderSize r: ReceiverResultReg R: Arg1Reg.
	cogit MoveCq: objectMemory nilObject R: fillReg.
	fillLoop := 
	cogit MoveR: fillReg Mw: 0 r: Arg1Reg.
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
CogObjectRepresentationFor64BitSpur >> genPrimitiveNewWithArg [
	"Implement primitiveNewWithArg for convenient cases:
	- the receiver has a hash
	- the receiver is variable and not compiled method
	- single word header/num slots < numSlotsMask
	- the result fits in eden
	See superclass method for dynamic frequencies of formats.
	For the moment we implement only arrayFormat, firstByteFormat & firstLongFormat"

	| headerReg fillReg instSpecReg byteSizeReg maxSlots
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

	NewspeakVM ifTrue:
		[cogit methodNumArgs = 2 ifTrue:
			[^self genPrimitiveMirrorNewWithArg]].
	cogit methodNumArgs ~= 1 ifTrue:
		[^UnimplementedPrimitive].
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.

	"header will contain classIndex/class's hash & format & numSlots/fixed size"
	headerReg := SendNumArgsReg.
	"Assume there's an available scratch register on 64-bit machines.  This holds the saved numFixedFields and then the value to fill with"
	fillReg := Extra0Reg.
	self assert: fillReg > 0.
	"inst spec will hold class's instance specification and then byte size"
	instSpecReg := byteSizeReg := ClassReg.
	"The max slots we'll allocate here are those for a single header"
	maxSlots := objectMemory numSlotsMask - 1.

	"get freeStart as early as possible so as not to wait later..."
	cogit MoveAw: objectMemory freeStartAddress R: Arg1Reg.
	"get class's hash & fail if 0"
	self genGetHashFieldNonImmOf: ReceiverResultReg into: headerReg.
	jumpUnhashed := cogit JumpZero: 0.
	"get index and fail if not a +ve integer"
	jumpNElementsNonInt := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	"get class's format inst var for inst spec (format field)"
	self genLoadSlot: InstanceSpecificationIndex sourceReg: ReceiverResultReg destReg: instSpecReg.
	cogit LogicalShiftRightCq: objectMemory fixedFieldsFieldWidth + self numSmallIntegerTagBits R: instSpecReg.
	cogit AndCq: objectMemory formatMask R: instSpecReg.
	"Add format to classIndex/format header now"
	cogit MoveR: instSpecReg R: TempReg.
	cogit LogicalShiftLeftCq: objectMemory formatShift R: TempReg.
	cogit AddR: TempReg R: headerReg.
	"get integer value of num fields in fillReg now"
	cogit MoveR: Arg0Reg R: fillReg.
	self genConvertSmallIntegerToIntegerInReg: fillReg.
	"dispatch on format, failing if not variable or if compiled method"
	cogit CmpCq: objectMemory arrayFormat R: instSpecReg.
	jumpArrayFormat := cogit JumpZero: 0.
	cogit CmpCq: objectMemory firstByteFormat R: instSpecReg.
	jumpByteFormat := cogit JumpZero: 0.
	cogit CmpCq: objectMemory firstLongFormat R: instSpecReg.
	jumpFailCuzFixed := cogit JumpNonZero: 0.

	cogit CmpCq: (objectMemory integerObjectOf: maxSlots * 2) R: Arg0Reg.
	jumpLongTooBig := cogit JumpAbove: 0.
	"save num elements/slot size to instSpecReg"
	cogit MoveR: fillReg R: instSpecReg.
	"compute odd bits and add into headerReg; oddBits := 2 - nElements bitAnd: 1"
	cogit MoveCq: objectMemory wordSize / 4 R: TempReg.
	cogit SubR: instSpecReg R: TempReg.
	cogit AndCq: objectMemory wordSize / 4 - 1 R: TempReg.
	cogit LogicalShiftLeftCq: objectMemory formatShift R: TempReg.
	cogit AddR: TempReg R: headerReg.
	"round up num elements to numSlots in instSpecReg"
	cogit AddCq: objectMemory wordSize / 4 - 1 R: instSpecReg.
	cogit LogicalShiftRightCq: objectMemory shiftForWord - 2 R: instSpecReg.
	cogit MoveCq: 0 R: fillReg.
	jumpLongPrepDone := cogit Jump: 0. "go allocate"

	jumpByteFormat jmpTarget:
	(cogit CmpCq: (objectMemory integerObjectOf: maxSlots * objectMemory wordSize) R: Arg0Reg).
	jumpByteTooBig := cogit JumpAbove: 0.
	"save num elements to instSpecReg"
	cogit MoveR: fillReg R: instSpecReg.
	"compute odd bits and add into headerReg; oddBits := 4 - nElements bitAnd: 3"
	cogit MoveCq: objectMemory wordSize R: TempReg.
	cogit SubR: instSpecReg R: TempReg.
	cogit AndCq: objectMemory wordSize - 1 R: TempReg.
	cogit LogicalShiftLeftCq: objectMemory formatShift R: TempReg.
	cogit AddR: TempReg R: headerReg.
	"round up num elements to numSlots in instSpecReg"
	cogit AddCq: objectMemory wordSize - 1 R: instSpecReg.
	cogit LogicalShiftRightCq: objectMemory shiftForWord R: instSpecReg.
	cogit MoveCq: 0 R: fillReg.
	jumpBytePrepDone := cogit Jump: 0. "go allocate"

	jumpArrayFormat jmpTarget:
		(cogit CmpCq: (objectMemory integerObjectOf: maxSlots) R: Arg0Reg).
	jumpArrayTooBig := cogit JumpAbove: 0.
	"save num elements/slot size to instSpecReg"
	cogit MoveR: fillReg R: instSpecReg.
	cogit MoveCq: objectMemory nilObject R: fillReg.
	"fall through to allocate"

	jumpBytePrepDone jmpTarget:
	(jumpLongPrepDone jmpTarget: cogit Label).

	"store numSlots to headerReg"
	cogit MoveR: instSpecReg R: TempReg.
	cogit LogicalShiftLeftCq: objectMemory numSlotsFullShift R: TempReg.
	cogit AddR: TempReg R: headerReg.
	"compute byte size; remember 0-sized objects still need 1 slot."
	cogit CmpCq: 0 R: byteSizeReg. "a.k.a. instSpecReg"
	jumpHasSlots := cogit JumpNonZero: 0.
	cogit MoveCq: objectMemory baseHeaderSize * 2 R: byteSizeReg.
	skip := cogit Jump: 0.
	jumpHasSlots jmpTarget:
	(cogit AddCq: objectMemory baseHeaderSize / objectMemory wordSize R: byteSizeReg).
	cogit LogicalShiftLeftCq: objectMemory shiftForWord R: byteSizeReg.
	skip jmpTarget:
	"check if allocation fits"
	(cogit AddR: Arg1Reg R: byteSizeReg).
	cogit CmpCq: objectMemory getScavengeThreshold R: byteSizeReg.
	jumpNoSpace := cogit JumpAboveOrEqual: 0.
	"get result, increment freeStart and write it back. Arg1Reg holds new freeStart, the limit of the object"
	cogit MoveR: Arg1Reg R: ReceiverResultReg.
	cogit MoveR: byteSizeReg Aw: objectMemory freeStartAddress.
	"write other half of header (numSlots/0 identityHash)"
	cogit MoveR: headerReg Mw: 0 r: ReceiverResultReg.
	"now fill"
	cogit LoadEffectiveAddressMw: objectMemory baseHeaderSize r: ReceiverResultReg R: Arg1Reg.
	fillLoop := 
	cogit MoveR: fillReg Mw: 0 r: Arg1Reg.
	cogit AddCq: 8 R: Arg1Reg.
	cogit CmpR: Arg1Reg R: byteSizeReg.
	cogit JumpAbove: fillLoop.
	cogit genPrimReturn.
	
	jumpNoSpace jmpTarget:
	(jumpUnhashed jmpTarget:
	(jumpFailCuzFixed jmpTarget:
	(jumpArrayTooBig jmpTarget:
	(jumpByteTooBig jmpTarget:
	(jumpLongTooBig jmpTarget:
	(jumpNElementsNonInt jmpTarget: cogit Label)))))).

	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveShallowCopy [
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

	"compute byte size for slots"
	cogit
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
		AndCq: (objectMemory
					headerForSlots: objectMemory numSlotsMask
					format: objectMemory formatMask
					classIndex: objectMemory classIndexMask) R: TempReg;
		MoveR: TempReg Mw: 0 r: resultReg.
	copyLoop := cogit Label.
	cogit
		AddCq: objectMemory wordSize R: ReceiverResultReg;
		AddCq: objectMemory wordSize R: ptrReg;
		MoveMw: 0 r: ReceiverResultReg R: TempReg;
		MoveR: TempReg Mw: 0 r: ptrReg;
		CmpR: ptrReg R: slotsReg;
		JumpAboveOrEqual: copyLoop;
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
CogObjectRepresentationFor64BitSpur >> genPrimitiveStoreInt32IntoBytes [
	^ self genPrimitiveStore: 4 intoBytesWith: [ :destPointer :valueOop |
		| jumpNonSmallInteger |
		jumpNonSmallInteger := self genJumpNotSmallInteger: valueOop scratchReg: TempReg.
		cogit MoveR: valueOop R: ReceiverResultReg.
	
		self genConvertSmallIntegerToIntegerInReg: valueOop.
		cogit MoveR: valueOop M32: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonSmallInteger jmpTarget: cogit Label
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveStoreInt32IntoExternalAddress [
	^ self genPrimitiveStoreIntoExternalAddressWith: [ :destPointer :valueOop |
		| jumpNonSmallInteger |
		jumpNonSmallInteger := self genJumpNotSmallInteger: valueOop scratchReg: TempReg.
		cogit MoveR: valueOop R: ReceiverResultReg.
	
		self genConvertSmallIntegerToIntegerInReg: valueOop.
		cogit MoveR: valueOop M32: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonSmallInteger jmpTarget: cogit Label
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveStoreInt64IntoBytes [
	^ self genPrimitiveStore: 8 intoBytesWith: [ :destPointer :valueOop |
		| jumpNonSmallInteger |
		jumpNonSmallInteger := self genJumpNotSmallInteger: valueOop scratchReg: TempReg.
		cogit MoveR: valueOop R: ReceiverResultReg.
	
		self genConvertSmallIntegerToIntegerInReg: valueOop.
		cogit MoveR: valueOop M64: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonSmallInteger jmpTarget: cogit Label
	] needsToTrap: true.
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveStoreInt64IntoExternalAddress [
	^ self genPrimitiveStoreIntoExternalAddressWith: [ :destPointer :valueOop |
		| jumpNonSmallInteger |
		jumpNonSmallInteger := self genJumpNotSmallInteger: valueOop scratchReg: TempReg.
		cogit MoveR: valueOop R: ReceiverResultReg.
	
		self genConvertSmallIntegerToIntegerInReg: valueOop.
		cogit MoveR: valueOop M64: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonSmallInteger jmpTarget: cogit Label
	] needsToTrap: true.
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveStoreUInt32IntoBytes [
	^ self genPrimitiveStore: 4 intoBytesWith: [ :destPointer :valueOop |
		| jumpNonSmallInteger jumpNegative |
		jumpNonSmallInteger := self genJumpNotSmallInteger: valueOop scratchReg: TempReg.
		cogit CmpCq: 0 R: valueOop.
		jumpNegative := cogit JumpLess: 0.
		
		cogit MoveR: valueOop R: ReceiverResultReg.
	
		self genConvertSmallIntegerToIntegerInReg: valueOop.
		cogit MoveR: valueOop M32: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonSmallInteger jmpTarget: (jumpNegative jmpTarget: cogit Label)
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveStoreUInt32IntoExternalAddress [
	^ self genPrimitiveStoreIntoExternalAddressWith: [ :destPointer :valueOop |
		| jumpNonSmallInteger jumpNegative |
		jumpNonSmallInteger := self genJumpNotSmallInteger: valueOop scratchReg: TempReg.
		cogit CmpCq: 0 R: valueOop.
		jumpNegative := cogit JumpLess: 0.
		
		cogit MoveR: valueOop R: ReceiverResultReg.
	
		self genConvertSmallIntegerToIntegerInReg: valueOop.
		cogit MoveR: valueOop M32: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonSmallInteger jmpTarget: (jumpNegative jmpTarget: cogit Label)
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveStoreUInt64IntoBytes [
	^ self genPrimitiveStore: 8 intoBytesWith: [ :destPointer :valueOop |
		| jumpNonSmallInteger jumpNegative |
		jumpNonSmallInteger := self genJumpNotSmallInteger: valueOop scratchReg: TempReg.
		cogit CmpCq: 0 R: valueOop.
		jumpNegative := cogit JumpLess: 0.
		
		cogit MoveR: valueOop R: ReceiverResultReg.
	
		self genConvertSmallIntegerToIntegerInReg: valueOop.
		cogit MoveR: valueOop M64: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonSmallInteger jmpTarget: (jumpNegative jmpTarget: cogit Label)
	] needsToTrap: true.
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveStoreUInt64IntoExternalAddress [
	^ self genPrimitiveStoreIntoExternalAddressWith: [ :destPointer :valueOop |
		| jumpNonSmallInteger jumpNegative |
		jumpNonSmallInteger := self genJumpNotSmallInteger: valueOop scratchReg: TempReg.
		cogit CmpCq: 0 R: valueOop.
		jumpNegative := cogit JumpLess: 0.
		
		cogit MoveR: valueOop R: ReceiverResultReg.
	
		self genConvertSmallIntegerToIntegerInReg: valueOop.
		cogit MoveR: valueOop M64: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonSmallInteger jmpTarget: (jumpNegative jmpTarget: cogit Label)
	] needsToTrap: true.
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genPrimitiveStringAt [
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
	cogit LogicalShiftLeftCq: objectMemory shiftForWord - 2 R: ClassReg.
	cogit AndCq: objectMemory wordSize / 4 - 1 R: formatReg.
	cogit SubR: formatReg R: ClassReg.
	cogit CmpR: Arg1Reg R: ClassReg.
	jumpWordsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit AddCq: objectMemory baseHeaderSize >> (objectMemory shiftForWord - 1) R: Arg1Reg.
	cogit MoveX32r: Arg1Reg R: ReceiverResultReg R: TempReg.
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
	cogit AndCq: objectMemory wordSize / 2 - 1 R: formatReg.
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
CogObjectRepresentationFor64BitSpur >> genPrimitiveStringAtPut [
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
	jumpBadArg := self genJumpNotCharacter: Arg1Reg.
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
	cogit CmpCq: (objectMemory characterObjectOf: 1 << self numCharacterBits - 1) R: Arg1Reg.
	jumpWordsOutOfRange := cogit JumpAbove: 0.
	cogit LogicalShiftLeftCq: objectMemory shiftForWord - 2 R: ClassReg.
	cogit AndCq: objectMemory wordSize / 4 - 1 R: formatReg.
	cogit SubR: formatReg R: ClassReg.
	cogit CmpR: Arg0Reg R: ClassReg.
	jumpWordsOutOfBounds := cogit JumpBelowOrEqual: 0.
	cogit MoveR: Arg1Reg R: TempReg.
	self genConvertCharacterToCodeInReg: TempReg.
	cogit AddCq: objectMemory baseHeaderSize >> (objectMemory shiftForWord - 1) R: Arg0Reg.
	cogit MoveR: TempReg X32r: Arg0Reg R: ReceiverResultReg.
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
CogObjectRepresentationFor64BitSpur >> genRemoveSmallIntegerTagsInScratchReg: scratchReg [
	cogit SubCq: 1 R: scratchReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genShiftAwaySmallIntegerTagsInScratchReg: scratchReg [
	cogit ArithmeticShiftRightCq: objectMemory numTagBits R: scratchReg.
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genSmallFloatArithmetic: arithmeticOperator preOpCheck: preOpCheckOrNil [
	<inline: true>
	^self genFloatArithmetic: arithmeticOperator preOpCheck: preOpCheckOrNil boxed: false
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genSmallFloatComparison: jumpOpcodeGenerator invert: invertComparison [
	<inline: true>
	^self genFloatComparison: jumpOpcodeGenerator invert: invertComparison boxed: false
]

{ #category : #initialization }
CogObjectRepresentationFor64BitSpur >> genStoreHeader: header intoNewInstance: rcvrReg using: scratchReg [
	"Generate the instructions to move the constant header into a new instance pointed to by rcvrReg."
	<inline: true>
	cogit
		MoveCq: header R: scratchReg;
		MoveR: scratchReg Mw: 0 r: rcvrReg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> getLiteralCountOf: methodReg plusOne: plusOne inBytes: inBytes into: litCountReg scratch: scratchReg [
	"Get the literal count of a CompiledMethod into headerReg, plus one if requested.
	  If inBytes is true, scale the count by the word size.  Deal with the possibility of
	 the method being cogged."
	self genGetMethodHeaderOf: methodReg into: litCountReg scratch: scratchReg.
	self assert: 1 << objectMemory numTagBits = objectMemory wordSize.
	inBytes
		ifTrue:
			[cogit
				AndCq: coInterpreter alternateHeaderNumLiteralsMask << objectMemory numTagBits
				R: litCountReg]
		ifFalse:
			[cogit
				LogicalShiftRightCq: objectMemory numTagBits R: litCountReg;
				AndCq: coInterpreter alternateHeaderNumLiteralsMask R: litCountReg].
	plusOne ifTrue:
		[cogit
			AddCq: (inBytes
						ifTrue: [LiteralStart * objectMemory wordSize]
						ifFalse: [LiteralStart])
			R: litCountReg].
	^0
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationFor64BitSpur >> illegalClassTag [
	^0
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationFor64BitSpur >> inlineCacheTagForClass: classOop [
	"Answer the relevant inline cache tag for a class.
	 c.f. inlineCacheTagForInstance:"
	^objectMemory classTagForClass: classOop
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationFor64BitSpur >> inlineCacheTagForInstance: oop [
	"Answer the relevant inline cache tag for an instance.
	 c.f. getInlineCacheClassTagFrom:into: & inlineCacheTagForClass:"
	^(objectMemory isImmediate: oop)
		ifTrue: [oop bitAnd: objectMemory tagMask]
		ifFalse: [objectMemory classIndexOf: oop]
]

{ #category : #initialization }
CogObjectRepresentationFor64BitSpur >> log2BytesPerWord [
	^3
]

{ #category : #'garbage collection' }
CogObjectRepresentationFor64BitSpur >> markAndTraceCacheTagLiteral: literal in: cogMethodOrNil atpc: address [
	"Mark and trace a literal in an inline cache preceding address in cogMethodOrNil.
	 Answer if code was modified.  In 64-bit Spur, cache tags are either selector
	 indices or class indices and so this is a noop."
	<var: #cogMethodOrNil type: #'CogMethod *'>
	<var: #address type: #usqInt>
	<inline: true>
	^false
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> maybeGenConvertIfSmallFloatIn: oopReg scratchReg: scratch into: dpReg andJumpTo: targetInst [
	"Generate a test for a smallFloat in oopReg, converting it to the float value in dpReg
	 and jumping to targetInst. If oopReg does not contain a SmallFloat, fall through."
	<var: 'targetInst' type: #'AbstractInstruction *'>
	| jumpNotSF |
	<var: 'jumpNotSF' type: #'AbstractInstruction *'>
	jumpNotSF := self genJumpNotSmallFloat: oopReg.
	self genGetSmallFloatValueOf: oopReg scratch: scratch into: dpReg.
	cogit Jump: targetInst.
	jumpNotSF jmpTarget: cogit Label.
	^0
]

{ #category : #initialization }
CogObjectRepresentationFor64BitSpur >> maybeGenerateSelectorIndexDereferenceRoutine [
	"Generate the routine that converts selector indices into selector objects.
	 It is called from the send trampolines.
	 If the selector index is negative, convert it into a positive index into the
	 special selectors array and index that.  Otherwise, index the current method.
	 The routine uses Extra0Reg & Extra1Reg, which are available, since they
	 are not live at point of send."
	| jumpNegative jumpNotBlock jumpFullBlock |
	<var: 'jumpNegative' type: #'AbstractInstruction *'>
	<var: 'jumpNotBlock' type: #'AbstractInstruction *'>
	<var: 'jumpFullBlock' type: #'AbstractInstruction *'>
	cogit zeroOpcodeIndex.
	cogit CmpCq: 0 R: ClassReg.
	jumpNegative := cogit JumpLess: 0.
	cogit
		MoveMw: FoxMethod r: FPReg R: Extra0Reg;
		AddCq: 2 R: ClassReg; "Change selector index to 1-relative, skipping the method header"
		TstCq: MFMethodFlagIsBlockFlag R: Extra0Reg.
	jumpNotBlock := cogit JumpZero: 0.
	"If in a block, need to find the home method...  If using full blocks, need to test the cpicHasMNUCaseOrCMIsFullBlock bit"
	cogit AndCq: methodZone zoneAlignment negated R: Extra0Reg.
	SistaV1BytecodeSet ifTrue:
		[self bitAndByteOffsetOfIsFullBlockBitInto:
			[:bitmask :byteOffset|
			jumpFullBlock := cogit
				MoveMb: byteOffset r: Extra0Reg R: Extra1Reg;
				TstCq: bitmask R: Extra1Reg;
				JumpNonZero: 0]].
	cogit 
		MoveM16: 0 r: Extra0Reg R: Extra1Reg;
		SubR: Extra1Reg R: Extra0Reg.
	jumpNotBlock jmpTarget: cogit Label.
	SistaV1BytecodeSet ifTrue:
		[jumpFullBlock jmpTarget: jumpNotBlock getJmpTarget].
	cogit "Now fetch the method object and index with the literal index to retrieve the selector"
		AndCq: methodZone zoneAlignment negated R: Extra0Reg;
		MoveMw: (cogit offset: CogMethod of: #methodObject) r: Extra0Reg R: Extra1Reg;
		MoveXwr: ClassReg R: Extra1Reg R: ClassReg;
		RetN: 0.
	jumpNegative jmpTarget: cogit Label.
	cogit
		NegateR: ClassReg;
		LogicalShiftLeftCq: 1 R: ClassReg;
		MoveAw: objectMemory specialObjectsArrayAddress R: Extra0Reg;
		SubCq: 1 R: ClassReg;
		MoveMw: SpecialSelectors + 1 * objectMemory wordSize r: Extra0Reg R: Extra1Reg; "Index, including header size"
		MoveXwr: ClassReg R: Extra1Reg R: ClassReg;
		RetN: 0.
	ceDereferenceSelectorIndex := cogit methodZoneBase.
	cogit
		outputInstructionsForGeneratedRuntimeAt: ceDereferenceSelectorIndex;
		recordGeneratedRunTime: 'ceDereferenceSelectorIndex' address: ceDereferenceSelectorIndex;
		recordRunTimeObjectReferences
]

{ #category : #'sista support' }
CogObjectRepresentationFor64BitSpur >> numCountersFor: theCounters [
	<var: #theCounters type: #usqInt>
	| objOop |
	theCounters = 0 ifTrue:
		[^0].
	objOop := theCounters - objectMemory baseHeaderSize.
	^2 * (objectMemory numSlotsOf: objOop)
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> numSmallIntegerBits [
	^61
]

{ #category : #'object representation' }
CogObjectRepresentationFor64BitSpur >> numSmallIntegerTagBits [
	^3
]

{ #category : #'calling convention' }
CogObjectRepresentationFor64BitSpur >> selectorIndexDereferenceRoutine [
	"If the object representation is 64-bits, selectors must be accessed via indices in the inline caches.
	 Answer the routine that will map from indices to selector objects if so, otherwise nil."
	^ceDereferenceSelectorIndex
]

{ #category : #'debug support' }
CogObjectRepresentationFor64BitSpur >> validInlineCacheTag: classIndexOrTagPattern [
	"The three valid tag patterns are 1 (SmallInteger), 2 (Character) and 3 (SmallFloat64)."
	^(classIndexOrTagPattern >= 1
	  and: [classIndexOrTagPattern <= 3])
	  or: [(objectMemory classAtIndex: classIndexOrTagPattern) notNil]
]
