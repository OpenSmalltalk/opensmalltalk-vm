"
Read my superclass' class comment.  I am a CogObjectRepresentation for the Squeak V3 object representation.
"
Class {
	#name : #CogObjectRepresentationForSqueakV3,
	#superclass : #CogObjectRepresentation,
	#classVars : [
		'RootBitDigitLength'
	],
	#pools : [
		'VMSqueakV3ObjectRepresentationConstants'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'class initialization' }
CogObjectRepresentationForSqueakV3 class >> initialize [
	RootBit ifNil: [ObjectMemory initializeObjectHeaderConstants].
	RootBitDigitLength := RootBit digitLength
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> allYoungObjectsAgeInFullGC [
	^true
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> assertIsValidOop: anOop [
	<doNotGenerate>
	"Method map assertion chekcing only (development time only).
	 Note we never put SmallIntegers in the map."
	^objectMemory addressCouldBeObj: anOop
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> cacheTagIsMarked: cacheTag [
	"Answer if the cacheTag is not unmarked, i.e. answer true for compact
	 class indices and immediates; only answer false for unmarked objects"
	(self couldBeObject: cacheTag) ifFalse: [^true].
	self assert: (objectMemory addressCouldBeObj: cacheTag).
	^objectMemory isMarked: cacheTag
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> checkValidInlineCacheTag: cacheTag [
	^((cacheTag bitAnd: 1 << ShiftForWord - 1) = 0
		and: [cacheTag
				between: 1 << ShiftForWord
				and: (objectMemory compactClassIndexOfHeader: -1) << ShiftForWord])
	   or: [self checkValidObjectReference: cacheTag]
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> checkValidObjectReference: anOop [
	^(objectMemory isIntegerObject: anOop)
	   or: [(self heapMapAtWord: (self pointerForOop: anOop)) ~= 0]
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationForSqueakV3 >> classForInlineCacheTag: inlineCacheTag [
	(objectMemory isIntegerObject: inlineCacheTag) ifTrue:
		[^objectMemory classSmallInteger].
	(self couldBeObject: inlineCacheTag) ifTrue:
		[^inlineCacheTag].
	^objectMemory compactClassAt: inlineCacheTag >> ShiftForWord
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> compactClassFieldMask [
	"This is the mask for the field when shifted into the least significant bits"
	<inline: true>
	^(1 << objectMemory compactClassFieldWidth) - 1
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> couldBeObject: oop [
	^(objectMemory isNonIntegerObject: oop)
	  and: [oop asUnsignedInteger >= objectMemory nilObject]
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genAddSmallIntegerTagsTo: aRegister [
	cogit AddCq: 1 R: aRegister.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genAllocFloatValue: dpreg into: resultReg scratchReg: scratch1 scratchReg: scratch2 [
	<returnTypeC: #'AbstractInstruction *'>
	| allocSize newFloatHeaderSansHash jumpFail |
	<var: #jumpFail type: #'AbstractInstruction *'>
	allocSize := BaseHeaderSize + (objectMemory sizeof: #double).
	newFloatHeaderSansHash := ((objectMemory classFloatCompactIndex << objectMemory compactClassFieldLSB
									bitOr: (objectMemory formatOfClass: objectMemory classFloat))
									bitOr: allocSize)
									 bitOr: HeaderTypeShort.
	cogit MoveAw: objectMemory freeStartAddress R: resultReg.
	cogit MoveR: resultReg R: scratch1.
	cogit AddCq: allocSize R: scratch1.
	cogit MoveAw: objectMemory scavengeThresholdAddress R: scratch2.
	cogit CmpR: scratch2 R: scratch1.
	jumpFail := cogit JumpAboveOrEqual: 0.
	cogit MoveR: resultReg R: scratch2.
	self flag: #newObjectHash.
	cogit AndCq: HashMaskUnshifted << BytesPerWord R: scratch2.
	cogit LogicalShiftLeftCq: HashBitsOffset - BytesPerWord R: scratch2.
	cogit OrCq: newFloatHeaderSansHash R: scratch2.
	cogit MoveR: scratch2 Mw: 0 r: resultReg.
	cogit MoveRd: dpreg M64: BaseHeaderSize r: resultReg.
	cogit MoveR: scratch1 Aw: objectMemory freeStartAddress.
	^jumpFail
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genConvertIntegerToSmallIntegerInScratchReg: scratchReg [
	cogit LogicalShiftLeftCq: 1 R: scratchReg.
	cogit AddCq: 1 R: scratchReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genConvertSmallIntegerToIntegerInScratchReg: scratchReg [
	cogit ArithmeticShiftRightCq: 1 R: scratchReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genFetchIndexRegister: indexReg from: tableObj into: destReg [
	self assert: indexReg ~= destReg.
	cogit annotate: (cogit MoveCw: tableObj R: destReg) objRef: tableObj.
	cogit MoveXwr: indexReg R: destReg R: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genGetClassFormatOfNonInt: instReg into: destReg scratchReg: scratchReg [
	"Fetch the instance's class format into destReg, assuming the object is non-int."
	| jumpCompact jumpGotClass |
	<var: #jumpCompact type: #'AbstractInstruction *'>
	<var: #jumpGotClass type: #'AbstractInstruction *'>
	"Get header word in destReg"
	cogit MoveMw: 0 r: instReg R: destReg.
	"Form the byte index of the compact class field"
	cogit LogicalShiftRightCq: (objectMemory compactClassFieldLSB - ShiftForWord) R: destReg.
	cogit AndCq: self compactClassFieldMask << ShiftForWord R: destReg.
	jumpCompact := cogit JumpNonZero: 0.
	cogit MoveMw: objectMemory classFieldOffset r: instReg R: scratchReg.
	"The use of signedIntFromLong is a hack to get round short addressing mode computations.
	 Much easier if offsets are signed and the arithmetic machinery we have makes it difficult to
	 mix signed and unsigned offsets."
	cogit AndCq: AllButTypeMask signedIntFromLong R: scratchReg.
	jumpGotClass := cogit Jump: 0.
	"Don't have to subtract one from the destReg compactClassArray index because of the header word."
	self assert: BaseHeaderSize = BytesPerWord.
	jumpCompact jmpTarget:
		(cogit annotate: (cogit MoveMw: objectMemory compactClassTable r: destReg R: scratchReg)
			objRef: objectMemory compactClassTable).
	jumpGotClass jmpTarget:
		(cogit MoveMw: InstanceSpecificationIndex << ShiftForWord + BytesPerWord r: scratchReg R: destReg).
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genGetClassObjectOf: instReg into: destReg scratchReg: scratchReg [
	"Fetch the instance's class into destReg.  This is almost identical
	 to genGetClassFormatOfNonInt:into:scratchReg: but because we
	 put the fetch of SmallInteger between the then and the else for 
	 compact class/non-compact class we cannot easily share code."
	| jumpIsInt jumpCompact jumpGotClass jumpGotClass2 |
	<var: #jumpIsInt type: #'AbstractInstruction *'>
	<var: #jumpCompact type: #'AbstractInstruction *'>
	<var: #jumpGotClass type: #'AbstractInstruction *'>
	<var: #jumpGotClass2 type: #'AbstractInstruction *'>
	cogit MoveR: instReg R: scratchReg.
	cogit AndCq: 1 R: scratchReg.
	jumpIsInt := cogit JumpNonZero: 0.
	"Get header word in scratchReg"
	cogit MoveMw: 0 r: instReg R: scratchReg.
	"Form the byte index of the compact class field"
	cogit LogicalShiftRightCq: (objectMemory compactClassFieldLSB - ShiftForWord) R: scratchReg.
	cogit AndCq: self compactClassFieldMask << ShiftForWord R: scratchReg.
	jumpCompact := cogit JumpNonZero: 0.
	cogit MoveMw: objectMemory classFieldOffset r: instReg R: destReg.
	cogit AndCq: AllButTypeMask signedIntFromLong R: destReg.
	jumpGotClass := cogit Jump: 0.
	jumpIsInt jmpTarget:
		(cogit annotate: (cogit MoveCw: objectMemory classSmallInteger R: destReg)
				objRef: objectMemory classSmallInteger).
	jumpGotClass2 := cogit Jump: 0.
	"Don't have to subtract one from the destReg compactClassArray index because of the header word."
	self assert: BaseHeaderSize = BytesPerWord.
	jumpCompact jmpTarget:
		(cogit annotate: (cogit MoveMw: objectMemory compactClassTable r: scratchReg R: destReg)
			objRef: objectMemory compactClassTable).
	jumpGotClass jmpTarget:
	(jumpGotClass2 jmpTarget: cogit Label).
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genGetCompactClassIndexNonIntOf: instReg into: destReg [
	"Fetch the instance's compact class index into destReg."
	"Get header word in scratchReg"
	cogit MoveMw: 0 r: instReg R: destReg.
	"Form the byte index of the compact class field"
	cogit LogicalShiftRightCq: objectMemory compactClassFieldLSB R: destReg.
	cogit AndCq: self compactClassFieldMask R: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genGetDoubleValueOf: srcReg into: destFPReg [ 
	cogit MoveM64: BaseHeaderSize r: srcReg Rd: destFPReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genGetFixedFieldsOfPointerNonInt: instReg into: destReg scratchReg: scratchReg [
	"Fetch the instance's class format into destReg, assuming the object is pointers and non-int"
	self genGetClassFormatOfNonInt: instReg into: destReg scratchReg: scratchReg.
	"compute  (classFormat >> 11 bitAnd: 16rC0) + (classFormat >> 2 bitAnd: 16r3F) - 1"
	cogit
		MoveR: destReg R: scratchReg;
		LogicalShiftRightCq: 2 R: destReg;
		LogicalShiftRightCq: 11 R: scratchReg;
		AndCq: 16r3F R: destReg;
		AndCq: 16rC0 R: scratchReg;
		SubCq: 1 R: destReg;
		AddR: scratchReg R: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genGetHashFieldNonIntOf: instReg asSmallIntegerInto: destReg [
	"Fetch the instance's identity hash into destReg, encoded as a SmallInteger."
	"Get header word in scratchReg"
	cogit MoveMw: 0 r: instReg R: destReg.
	"Shift and mask the field leaving room for the SmallInteger tag."
	cogit LogicalShiftRightCq: HashBitsOffset - 1 R: destReg.
	cogit AndCq: HashMaskUnshifted << 1 R: destReg.
	"Set the SmallInteger tag."
	cogit AddCq: 1 R: destReg.
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSqueakV3 >> genGetSizeOf: sourceReg into: destReg formatReg: formatReg scratchReg: scratchReg abortJumpsInto: aBinaryBlock [
	"Get the size of the non-immediate object in sourceReg into destReg using formatReg
	 and scratchReg as temps.  None of these registers can overlap.  Supply the jumps
	 taken if the object in sourceReg is not indexable, or if the object in sourceReg is a
	 context.. Hack: If the object has a pointer format other than 2 leave the number of
	 fixed fields in formatReg.  Used by primitiveSize, primitiveAt, and primitiveAtPut"
	<returnTypeC: #'AbstractInstruction *'>
	| jumpNotIndexable jumpIsContext jumpShortHeader jumpSkip
	  jumpFmtLe4 jumpFmtIs2 jmpFmtGe8 jumpGotByteSize jumpGotWordSize |
	<inline: true>
	"c.f. StackInterpreter>>stSizeOf: lengthOf:baseHeader:format: fixedFieldsOf:format:length:"
	"and one wonders why Squeak V1 through V3 are slow..."
	<var: #jumpNotIndexable type: #'AbstractInstruction *'>
	<var: #jumpIsContext type: #'AbstractInstruction *'>
	<var: #jumpShortHeader type: #'AbstractInstruction *'>
	<var: #jumpSkip type: #'AbstractInstruction *'>
	<var: #jumpFmtLe4 type: #'AbstractInstruction *'>
	<var: #jumpFmtIs2 type: #'AbstractInstruction *'>
	<var: #jmpFmtGe8 type: #'AbstractInstruction *'>
	<var: #jumpGotByteSize type: #'AbstractInstruction *'>
	<var: #jumpGotWordSize type: #'AbstractInstruction *'>
	cogit
		MoveMw: 0 r: sourceReg R: formatReg;				"destReg := self baseHeader: receiver"
		MoveR: formatReg R: destReg;
		LogicalShiftRightCq: objectMemory instFormatFieldLSB R: formatReg;
		AndCq: self instFormatFieldMask R: formatReg;		"formatReg := self formatOfHeader: destReg"
		CmpCq: 2 R: formatReg.
	jumpNotIndexable := cogit JumpLess: 0.
	cogit
		MoveR: destReg R: scratchReg;
		LogicalShiftRightCq: objectMemory compactClassFieldLSB R: scratchReg;
		AndCq: self compactClassFieldMask R: scratchReg;	"scratchReg := self compactClassIndexOfHeader: destReg"
		CmpCq: ClassMethodContextCompactIndex R: scratchReg.
	jumpIsContext := cogit JumpZero: 0.
	cogit
		MoveR: destReg R: scratchReg;
		AndCq: TypeMask R: scratchReg;
		CmpCq: HeaderTypeSizeAndClass R: scratchReg.	"(hdr bitAnd: TypeMask) = HeaderTypeSizeAndClass"
	jumpShortHeader := cogit JumpNonZero: 0.
	self assert: Size4Bit = 0.
	cogit
		MoveMw: 0 - (2 * BytesPerWord) r: sourceReg R: destReg; "(self sizeHeader: oop) bitAnd: LongSizeMask"
		AndCq: LongSizeMask signedIntFromLong R: destReg.
	jumpSkip :=  cogit Jump: 0.
	jumpShortHeader jmpTarget: (cogit AndCq: SizeMask R: destReg).	"hdr bitAnd: SizeMask"
	jumpSkip jmpTarget: (cogit SubCq: BaseHeaderSize R: destReg). "sz - BaseheaderSize for all three arms"
	cogit CmpCq: 4 R: formatReg.	"fmt <= 4"
	jumpFmtLe4 := cogit JumpLessOrEqual: 0.
	cogit CmpCq: 8 R: formatReg.
	jmpFmtGe8 := cogit JumpLess: 0.
	cogit
		AndCq: 3 R: formatReg;	"(sz - BaseHeaderSize) - (fmt bitAnd: 3) bytes"
		SubR: formatReg R: destReg.
	jumpGotByteSize := cogit Jump: 0.
	jmpFmtGe8 jmpTarget: (cogit LogicalShiftRightCq: 2 R: destReg). "(sz - BaseHeaderSize) >> 2 32-bit longs"
	jumpGotWordSize := cogit Jump: 0.
	jumpFmtLe4 jmpTarget: cogit Label.
	cogit
		LogicalShiftRightCq: ShiftForWord R: destReg; "(sz - BaseHeaderSize) >> ShiftForWord words"
		CmpCq: 2 R: formatReg.
	jumpFmtIs2 := cogit JumpZero: 0.
	self genGetFixedFieldsOfPointerNonInt: sourceReg into: formatReg scratchReg: scratchReg.
	cogit SubR: formatReg R: destReg.
	jumpFmtIs2 jmpTarget:
	(jumpGotWordSize jmpTarget:
	(jumpGotByteSize jmpTarget:
		cogit Label)).
	aBinaryBlock value: jumpNotIndexable value: jumpIsContext
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSqueakV3 >> genInnerPrimitiveAt: retNoffset [
	| jumpSI jumpNotSI jumpNotIndexable jumpIsContext jumpBounds jumpFmtGt4 jumpFmtEq2 jumpFmtLt8 jumpFmtGt11 jumpLarge |
	"c.f. StackInterpreter>>stSizeOf: lengthOf:baseHeader:format: fixedFieldsOf:format:length:"
	<var: #jumpSI type: #'AbstractInstruction *'>
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpNotIndexable type: #'AbstractInstruction *'>
	<var: #jumpIsContext type: #'AbstractInstruction *'>
	<var: #jumpBounds type: #'AbstractInstruction *'>
	<var: #jumpFmtGt4 type: #'AbstractInstruction *'>
	<var: #jumpFmtEq2 type: #'AbstractInstruction *'>
	<var: #jumpFmtLt8 type: #'AbstractInstruction *'>
	<var: #jumpFmtGt11 type: #'AbstractInstruction *'>
	<var: #jumpLarge type: #'AbstractInstruction *'>
	cogit MoveR: ReceiverResultReg R: TempReg.
	jumpSI := self genJumpSmallIntegerInScratchReg: TempReg.
	cogit MoveR: Arg0Reg R: TempReg.
	cogit MoveR: Arg0Reg R: Arg1Reg.
	jumpNotSI := self genJumpNotSmallIntegerInScratchReg: TempReg.
	self
		genGetSizeOf: ReceiverResultReg
		into: ClassReg
		formatReg: SendNumArgsReg
		scratchReg: TempReg
		abortJumpsInto: [:jnx :jic| jumpNotIndexable := jnx. jumpIsContext := jic].
	self genConvertSmallIntegerToIntegerInScratchReg: Arg1Reg.
	cogit SubCq: 1 R: Arg1Reg.
	cogit CmpR: ClassReg R: Arg1Reg.
	jumpBounds := cogit JumpAboveOrEqual: 0.
	"This is tedious.  Because of register pressure on x86 (and the baroque
	 complexity of the size computation) we have to recompute the format
	 because it may have been smashed computing the fixed fields.  But at
	 least we have the fixed fields, if any, in formatReg and recomputing
	 these is more expensive than recomputing format.  In any case this
	 should still be faster than the interpreter and we hope this object
	 representation's days are numbered."
	cogit
		MoveMw: 0 r: ReceiverResultReg R: ClassReg;	"self baseHeader: receiver"
		LogicalShiftRightCq: objectMemory instFormatFieldLSB R: ClassReg;
		AndCq: self instFormatFieldMask R: ClassReg;	"self formatOfHeader: ClassReg"
		CmpCq: 4 R: ClassReg.
	jumpFmtGt4 := cogit JumpGreater: 0.
	cogit CmpCq: 2 R: ClassReg.	"Common case, e.g. Array, has format = 2"
	jumpFmtEq2 := cogit JumpZero: 0.
	cogit AddR: SendNumArgsReg R: Arg1Reg. "Add fixed fields to index"
	jumpFmtEq2 jmpTarget: cogit Label.
	cogit "Too lazy [knackered, more like. ed.] to define index with displacement addressing right now"
		AddCq: BaseHeaderSize / BytesPerWord R: Arg1Reg;
		MoveXwr: Arg1Reg R: ReceiverResultReg R: ReceiverResultReg;
		RetN: retNoffset.
	jumpFmtGt4 jmpTarget: cogit Label.
	"Byte objects have formats 8 through 15, Compiled methods being 12 through 15;
	 fail for CompiledMethod allowing the CoInterpeter to impose stricter bounds checks."
	cogit CmpCq: 8 R: ClassReg.
	jumpFmtLt8 := cogit JumpLess: 0.
	cogit CmpCq: 11 R: ClassReg.
	jumpFmtGt11 := cogit JumpGreater: 0.
	cogit
		AddCq: BaseHeaderSize R: Arg1Reg;
		MoveXbr: Arg1Reg R: ReceiverResultReg R: ReceiverResultReg.
	self genConvertIntegerToSmallIntegerInScratchReg: ReceiverResultReg.
	cogit RetN: retNoffset.
	jumpFmtLt8 jmpTarget: cogit Label.
	self assert: BytesPerWord = 4. "documenting my laziness"
	cogit "Too lazy [knackered, more like. ed.] to define index with displacement addressing right now"
		AddCq: BaseHeaderSize / BytesPerWord R: Arg1Reg;
		MoveXwr: Arg1Reg R: ReceiverResultReg R: ReceiverResultReg;
		CmpCq: 16r3FFFFFFF R: ReceiverResultReg.
	jumpLarge := cogit JumpAbove: 0.
	self genConvertIntegerToSmallIntegerInScratchReg: ReceiverResultReg.
	cogit RetN: retNoffset.
	jumpLarge jmpTarget: (cogit CallRT: cogit cePositive32BitIntegerTrampoline).
	cogit
		MoveR: TempReg R: ReceiverResultReg;
		RetN: retNoffset.
	jumpSI jmpTarget:
	(jumpNotSI jmpTarget:
	(jumpNotIndexable jmpTarget:
	(jumpIsContext jmpTarget:
	(jumpBounds jmpTarget:
	(jumpFmtGt11 jmpTarget:
		cogit Label))))).
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSqueakV3 >> genInnerPrimitiveSize: retNoffset [
	| jumpNotSI jumpNotIndexable jumpIsContext |
	"c.f. StackInterpreter>>stSizeOf: lengthOf:baseHeader:format: fixedFieldsOf:format:length:"
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpNotIndexable type: #'AbstractInstruction *'>
	<var: #jumpIsContext type: #'AbstractInstruction *'>
	cogit MoveR: ReceiverResultReg R: TempReg.
	jumpNotSI := self genJumpSmallIntegerInScratchReg: TempReg.
	self
		genGetSizeOf: ReceiverResultReg
		into: ClassReg
		formatReg: SendNumArgsReg
		scratchReg: TempReg
		abortJumpsInto: [:jnx :jic| jumpNotIndexable := jnx. jumpIsContext := jic].
	self genConvertIntegerToSmallIntegerInScratchReg: ClassReg.
	cogit MoveR: ClassReg R: ReceiverResultReg.
	self flag: 'currently caller pushes result'.
	cogit RetN: retNoffset.
	jumpNotSI jmpTarget: (jumpNotIndexable jmpTarget: (jumpIsContext jmpTarget: cogit Label)).
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSqueakV3 >> genInnerPrimitiveStringAt: retNOffset [
	| jumpSI jumpNotSI jumpNotByteIndexable jumpBounds jumpShortHeader jumpSkip |
	"c.f. StackInterpreter>>stSizeOf: lengthOf:baseHeader:format: fixedFieldsOf:format:length:"
	<var: #jumpSI type: #'AbstractInstruction *'>
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpNotByteIndexable type: #'AbstractInstruction *'>
	<var: #jumpBounds type: #'AbstractInstruction *'>
	<var: #jumpShortHeader type: #'AbstractInstruction *'>
	<var: #jumpSkip type: #'AbstractInstruction *'>
	cogit MoveR: ReceiverResultReg R: TempReg.
	jumpSI := self genJumpSmallIntegerInScratchReg: TempReg.
	cogit MoveR: Arg0Reg R: TempReg.
	cogit MoveR: Arg0Reg R: Arg1Reg.
	jumpNotSI := self genJumpNotSmallIntegerInScratchReg: TempReg.
	cogit
		MoveMw: 0 r: ReceiverResultReg R: TempReg;	"self baseHeader: receiver"
		MoveR: TempReg R: ClassReg;					"copy header word; we'll need it later"
		LogicalShiftRightCq: objectMemory instFormatFieldLSB R: TempReg;
		AndCq: self instFormatFieldMask R: TempReg;	"self formatOfHeader: destReg"
		MoveR: TempReg R: SendNumArgsReg;
		AndCq: 3 R: SendNumArgsReg;					"get odd bytes from format (if it turns out to be bytes)"
		SubR: SendNumArgsReg R: TempReg;
		CmpCq: 8 R: TempReg.							"check format is 8"
	jumpNotByteIndexable := cogit JumpNonZero: 0.
	cogit
		MoveR: ClassReg R: TempReg;
		AndCq: TypeMask R: TempReg;
		CmpCq: HeaderTypeSizeAndClass R: TempReg.	"(hdr bitAnd: TypeMask) = HeaderTypeSizeAndClass"
	jumpShortHeader := cogit JumpNonZero: 0.
	self assert: Size4Bit = 0.
	cogit
		MoveMw: 0 - (2 * BytesPerWord) r: ReceiverResultReg R: ClassReg; "(self sizeHeader: oop) bitAnd: LongSizeMask"
		AndCq: LongSizeMask signedIntFromLong R: ClassReg.
	jumpSkip :=  cogit Jump: 0.
	jumpShortHeader jmpTarget: (cogit AndCq: SizeMask R: ClassReg).	"hdr bitAnd: SizeMask"
	jumpSkip jmpTarget: (cogit SubCq: BaseHeaderSize R: ClassReg). "sz - BaseHeaderSize"
	cogit SubR: SendNumArgsReg R: ClassReg. "sz - (fmt bitAnd: 3)"
	self genConvertSmallIntegerToIntegerInScratchReg: Arg1Reg.
	cogit SubCq: 1 R: Arg1Reg.
	cogit CmpR: ClassReg R: Arg1Reg.
	jumpBounds := cogit JumpAboveOrEqual: 0.
	cogit AddCq: BaseHeaderSize R: Arg1Reg.
	cogit annotate: (cogit MoveCw: objectMemory characterTable R: Arg0Reg)
		objRef: objectMemory characterTable.
	cogit MoveXbr: Arg1Reg R: ReceiverResultReg R: ReceiverResultReg;
		AddCq: BaseHeaderSize / BytesPerWord R: ReceiverResultReg.
	cogit MoveXwr: ReceiverResultReg R: Arg0Reg R: ReceiverResultReg.
	cogit RetN: retNOffset.
	jumpSI jmpTarget:
	(jumpNotSI jmpTarget:
	(jumpNotByteIndexable jmpTarget:
	(jumpBounds jmpTarget:
		cogit Label))).
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genJumpNotSmallIntegerInScratchReg: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit AndCq: 1 R: aRegister.
	^cogit JumpZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genJumpSmallIntegerInScratchReg: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit AndCq: 1 R: aRegister.
	^cogit JumpNonZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genLoadSlot: index sourceReg: sourceReg destReg: destReg [
	cogit MoveMw: index * BytesPerWord + BaseHeaderSize r: sourceReg R: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genRemoveSmallIntegerTagsInScratchReg: scratchReg [ 
	cogit SubCq: 1 R: scratchReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genSSPushSlot: index reg: baseReg [
	^cogit ssPushBase: baseReg offset: (self slotOffsetOfInstVarIndex: index)
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genSetSmallIntegerTagsIn: scratchReg [ 
	cogit OrCq: 1 R: scratchReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genShiftAwaySmallIntegerTagsInScratchReg: scratchReg [
	cogit ArithmeticShiftRightCq: 1 R: scratchReg.
	^0
]

{ #category : #initialization }
CogObjectRepresentationForSqueakV3 >> genStoreCheckTrampoline [
	"Call noteAsRoot: with the object stored into"
	^cogit
		genTrampolineFor: #ceStoreCheck:
		called: 'ceStoreCheckTrampoline'
		arg: ReceiverResultReg
		result: cogit returnRegForStoreCheck
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genStoreImmediateInSourceReg: sourceReg slotIndex: index destReg: destReg [
	cogit MoveR: sourceReg Mw: index * BytesPerWord + BaseHeaderSize r: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genStoreSourceReg: sourceReg slotIndex: index destReg: destReg scratchReg: scratchReg [
	| jmpImmediate jmpDestYoung jmpSourceOld jmpAlreadyRoot mask rootBitByteOffset |
	<var: #jmpImmediate type: #'AbstractInstruction *'>
	<var: #jmpDestYoung type: #'AbstractInstruction *'>
	<var: #jmpSourceOld type: #'AbstractInstruction *'>
	<var: #jmpAlreadyRoot type: #'AbstractInstruction *'>
	"do the store"
	cogit MoveR: sourceReg Mw: index * BytesPerWord + BaseHeaderSize r: destReg.
	"now the check.  Is value stored an integer?  If so we're done"
	cogit MoveR: sourceReg R: scratchReg.
	cogit AndCq: 1 R: scratchReg.
	jmpImmediate := cogit JumpNonZero: 0.
	"Get the old/new boundary in scratchReg"
	cogit MoveAw: objectMemory youngStartAddress R: scratchReg.
	"Is target young?  If so we're done"
	cogit CmpR: scratchReg R: destReg. "N.B. FLAGS := destReg - scratchReg"
	jmpDestYoung := cogit JumpAboveOrEqual: 0.
	"Is value stored old?  If so we're done."
	cogit CmpR: scratchReg R: sourceReg. "N.B. FLAGS := sourceReg - scratchReg"
	jmpSourceOld := cogit JumpBelow: 0.
	"value is young and target is old.
	 Need to make this a root if the root bit is not already set.
	 Test the root bit.  Only need to fetch the byte containing it,
	 which reduces the size of the mask constant."
	rootBitByteOffset := jmpSourceOld isBigEndian
							ifTrue: [BytesPerWord - RootBitDigitLength]
							ifFalse:[RootBitDigitLength - 1].
	mask := RootBitDigitLength > 1
				ifTrue: [RootBit >> (RootBitDigitLength - 1 * 8)]
				ifFalse: [RootBit].
	cogit MoveMb: rootBitByteOffset r: destReg R: scratchReg.
	cogit AndCq: mask R: scratchReg.
	jmpAlreadyRoot := cogit JumpNonZero: 0.
	"Root bit is not set.  Call store check to insert dest into root table."
	self assert: destReg == ReceiverResultReg.
	cogit CallRT: cogit ceStoreCheckTrampoline.
	jmpImmediate jmpTarget:
	(jmpDestYoung jmpTarget:
	(jmpSourceOld jmpTarget:
	(jmpAlreadyRoot jmpTarget:
		cogit Label))).
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genStoreSourceReg: sourceReg slotIndex: index intoNewObjectInDestReg: destReg [
	cogit MoveR: sourceReg Mw: index * BytesPerWord + BaseHeaderSize r: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> getInlineCacheClassTagFrom: sourceReg into: destReg [
	"Extract the inline cache tag for the object in sourceReg into destReg. The inline
	 cache tag for a given object is the value loaded in inline caches to distinguish objects
	 of different classes.  In SqueakV3 the tag is the integer tag bit for SmallIntegers (1),
	 the compact class index shifted by log: 2 word size for objects with compact classes
	 (1 * 4 to: 31 * 4 by: 4), or the class.  These ranges cannot overlap because the heap
	 (and hence the lowest class object) is beyond the machine code zone."
	| jumpIsInt jumpCompact |
	<var: #jumpIsInt type: #'AbstractInstruction *'>
	<var: #jumpCompact type: #'AbstractInstruction *'>
	cogit MoveR: sourceReg R: destReg.
	cogit AndCq: 1 R: destReg.
	jumpIsInt := cogit JumpNonZero: 0.
	"Get header word in destReg"
	cogit MoveMw: 0 r: sourceReg R: destReg.
	"Form the byte index of the compact class field"
	cogit LogicalShiftRightCq: (objectMemory compactClassFieldLSB - ShiftForWord) R: destReg.
	cogit AndCq: self compactClassFieldMask << ShiftForWord R: destReg.
	jumpCompact := cogit JumpNonZero: 0.
	cogit MoveMw: objectMemory classFieldOffset r: sourceReg R: destReg.
	"The use of signedIntFromLong is a hack to get round short addressing mode computations.
	 Much easier if offsets are signed and the arithmetic machinery we have makes it difficult to
	 mix signed and unsigned offsets."
	cogit AndCq: AllButTypeMask signedIntFromLong R: destReg.
	jumpCompact jmpTarget: (jumpIsInt jmpTarget: cogit Label).
	^0
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> hasValidHeaderPostGC: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	^cogMethod objectHeader = objectMemory nullHeaderForMachineCodeMethod
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationForSqueakV3 >> inlineCacheTagForInstance: oop [
	"c.f. getInlineCacheClassTagFrom:into:"
	| cci |
	(objectMemory isIntegerObject: oop) ifTrue:
		[^objectMemory integerObjectOf: 0]. "the SmallInteger tag"
	(cci :=  objectMemory compactClassIndexOf: oop) > 0 ifTrue:
		[^cci << ShiftForWord].
	^(objectMemory classHeader: oop) bitAnd: AllButTypeMask
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationForSqueakV3 >> inlineCacheTagIsYoung: cacheTag [
	^objectMemory isYoung: cacheTag
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> instFormatFieldMask [
	"This is the mask for the field when shifted into the least significant bits"
	<inline: true>
	^(1 << objectMemory instFormatFieldWidth) - 1
]

{ #category : #'object representation' }
CogObjectRepresentationForSqueakV3 >> isImmediate: anOop [
	^objectMemory isIntegerObject: anOop
]

{ #category : #'object representation' }
CogObjectRepresentationForSqueakV3 >> isSmallIntegerTagNonZero [
	^true
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> markAndTraceLiteral: literal [
	(self couldBeObject: literal) ifTrue:
		[self assert: (objectMemory addressCouldBeObj: literal).
		 objectMemory markAndTrace: literal]
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> markAndTraceLiteralIfYoung: literal [
	((self couldBeObject: literal)
	 and: [objectMemory isYoung: literal]) ifTrue:
		[self assert: (objectMemory addressCouldBeObj: literal).
		 objectMemory markAndTrace: literal]
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> numSmallIntegerBits [
	^31
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> numSmallIntegerTagBits [
	^1
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> remapCacheTag: cacheTag [
	^(self couldBeObject: cacheTag)
		ifTrue: [objectMemory remap: cacheTag]
		ifFalse: [cacheTag]
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> remapOop: oop [
	^(objectMemory isIntegerObject: oop)
		ifTrue: [oop]
		ifFalse: [objectMemory remap: oop]
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> shouldAnnotateObjectReference: anOop [
	"self assert: ((objectMemory isIntegerObject: anOop)
				or: [objectMemory addressCouldBeObj: anOop])."
	^(objectMemory isNonIntegerObject: anOop)
	  and: [anOop > objectMemory trueObject]
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> slotOffsetOfInstVarIndex: index [
	^index * BytesPerWord + BaseHeaderSize
]
