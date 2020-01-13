"
Read my superclass' class comment.  I am a CogObjectRepresentation for the Squeak V3 object representation.
"
Class {
	#name : #CogObjectRepresentationForSqueakV3,
	#superclass : #CogObjectRepresentation,
	#instVars : [
		'ceCreateNewArrayTrampoline',
		'cePositive32BitIntegerTrampoline',
		'ceActiveContextTrampoline',
		'ceClosureCopyTrampoline',
		'ceSigned32BitIntegerTrampoline',
		'ceSigned32BitValueOfTrampoline',
		'cePositive32BitValueOfTrampoline'
	],
	#classVars : [
		'RootBitDigitLength'
	],
	#pools : [
		'VMSqueakClassIndices',
		'VMSqueakV3ObjectRepresentationConstants'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'accessing class hierarchy' }
CogObjectRepresentationForSqueakV3 class >> defaultObjectMemoryClass [
	"For in-image compilation."
	^NewCoObjectMemory
]

{ #category : #'class initialization' }
CogObjectRepresentationForSqueakV3 class >> initialize [
	RootBit ifNil: [ ObjectMemory initializeObjectHeaderConstants ].
	RootBitDigitLength := RootBit bytesCount
]

{ #category : #accessing }
CogObjectRepresentationForSqueakV3 class >> numTrampolines [
	^super numTrampolines + 4 + (LowcodeVM ifTrue: [ 3 ] ifFalse: [ 0 ])
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> allYoungObjectsAgeInFullGC [
	^true
]

{ #category : #'sista support' }
CogObjectRepresentationForSqueakV3 >> allocateCounters: nCounters [
	"Malloc the counter space.  Fill the first slot with the number of counters for resetCountersIn:"
	| theCounters |
	<var: #theCounters type: #usqInt>
	theCounters := self malloc: nCounters + 1 * (self sizeof: #sqInt).
	theCounters = 0 ifTrue:
		[^theCounters].
	self longAt: theCounters put: nCounters.
	^theCounters + (self sizeof: #sqInt)
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
CogObjectRepresentationForSqueakV3 >> checkValidOopReference: anOop [
	^(objectMemory isIntegerObject: anOop)
	   or: [(objectMemory heapMapAtWord: (self pointerForOop: anOop)) ~= 0]
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationForSqueakV3 >> classForInlineCacheTag: inlineCacheTag [
	(objectMemory isIntegerObject: inlineCacheTag) ifTrue:
		[^objectMemory classSmallInteger].
	(self couldBeObject: inlineCacheTag) ifTrue:
		[^inlineCacheTag].
	^objectMemory compactClassAt: inlineCacheTag >> objectMemory compactClassFieldLSB
]

{ #category : #'object representation' }
CogObjectRepresentationForSqueakV3 >> compactClassFieldMask [
	"This is the mask for the field when shifted into the least significant bits"
	<inline: true>
	^(1 << objectMemory compactClassFieldWidth) - 1
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> couldBeObject: oop [
	"Note this version filters-out compact class indices via the >= nilObj clause"
	^(objectMemory isNonIntegerObject: oop)
	  and: [self oop: oop isGreaterThanOrEqualTo: objectMemory nilObject]
]

{ #category : #'sista support' }
CogObjectRepresentationForSqueakV3 >> freeCounters: theCounters [
	<var: #theCounters type: #usqInt>
	theCounters ~= 0 ifTrue:
		[self free: theCounters - (self sizeof: #sqInt)]
]

{ #category : #initialization }
CogObjectRepresentationForSqueakV3 >> genActiveContextTrampoline [
	"Short-circuit the interpreter call if a frame is already married."
	| jumpSingle |
	<var: #jumpSingle type: #'AbstractInstruction *'>
	cogit
		zeroOpcodeIndex;
		MoveMw: FoxMethod r: FPReg R: TempReg;
		AndCq: MFMethodFlagHasContextFlag R: TempReg.
	jumpSingle := cogit JumpZero: 0.
	cogit
		MoveMw: FoxThisContext r: FPReg R: ReceiverResultReg;
		RetN: 0.
	jumpSingle jmpTarget: cogit Label.
	^cogit genTrampolineFor: #ceActiveContext
		called: 'ceActiveContextTrampoline'
		numArgs: 0
		arg: nil
		arg: nil
		arg: nil
		arg: nil
		regsToSave: cogit emptyRegisterMask
		pushLinkReg: true
		resultReg: ReceiverResultReg
		appendOpcodes: true
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
	allocSize := objectMemory baseHeaderSize + (objectMemory sizeof: #double).
	newFloatHeaderSansHash := ((ClassFloatCompactIndex << objectMemory compactClassFieldLSB
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
	cogit AndCq: HashMaskUnshifted << objectMemory wordSize R: scratch2.
	cogit LogicalShiftLeftCq: HashBitsOffset - objectMemory wordSize R: scratch2.
	cogit OrCq: newFloatHeaderSansHash R: scratch2.
	cogit MoveR: scratch2 Mw: 0 r: resultReg.
	cogit MoveRd: dpreg M64: objectMemory baseHeaderSize r: resultReg.
	cogit MoveR: scratch1 Aw: objectMemory freeStartAddress.
	^jumpFail
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genClearAndSetSmallIntegerTagsIn: scratchReg [
	"Set the SmallInteger tag bits when the tag bits may be filled with garbage."
	^self genSetSmallIntegerTagsIn: scratchReg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genConvertIntegerToSmallIntegerInReg: reg [
	cogit LogicalShiftLeftCq: 1 R: reg.
	cogit AddCq: 1 R: reg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genConvertSmallIntegerToIntegerInReg: reg [
	cogit ArithmeticShiftRightCq: 1 R: reg.
	^0
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationForSqueakV3 >> genCreateClosureAt: bcpc numArgs: numArgs numCopied: numCopied contextNumArgs: ctxtNumArgs large: isLargeCtxt inBlock: isInBlock [
	"Create a closure with the given startpc, numArgs and numCopied
	 within a context with ctxtNumArgs, large if isLargeCtxt that is in a
	 block if isInBlock.  If numCopied > 0 pop those values off the stack."
	
	"see ceClosureCopyDescriptor:"
	cogit MoveCq: numArgs + (numCopied << 6) + (bcpc << 12) R: SendNumArgsReg.
	cogit CallRT: ceClosureCopyTrampoline.
	numCopied > 0 ifTrue:
		[cogit AddCq: numCopied * objectMemory wordSize R: SPReg].
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genFetchIndexRegister: indexReg from: tableObj into: destReg [
	"indexReg contains the 1-relative index of an element in tableObj.
	 Since BaseHeaderSize = BytesPerOop we can use it as a
	 zero-relative index from the beginning of the object."
	self assert: indexReg ~= destReg.
	cogit genMoveConstant: tableObj R: destReg.
	cogit MoveXwr: indexReg R: destReg R: destReg.
	^0
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationForSqueakV3 >> genGetActiveContextNumArgs: numArgs large: isLargeContext inBlock: isInBlock [
	"Get the active context into ReceiverResultReg, creating it if necessary."
	cogit CallRT: ceActiveContextTrampoline
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
	cogit LogicalShiftRightCq: (objectMemory compactClassFieldLSB - objectMemory shiftForWord) R: destReg.
	cogit AndCq: self compactClassFieldMask << objectMemory shiftForWord R: destReg.
	jumpCompact := cogit JumpNonZero: 0.
	cogit MoveMw: objectMemory classFieldOffset r: instReg R: scratchReg.
	"The use of signedIntFromLong is a hack to get round short addressing mode computations.
	 Much easier if offsets are signed and the arithmetic machinery we have makes it difficult to
	 mix signed and unsigned offsets."
	cogit AndCq: AllButTypeMask signedIntFromLong R: scratchReg.
	jumpGotClass := cogit Jump: 0.
	"Don't have to subtract one from the destReg compactClassArray index because of the header word."
	self assert: objectMemory baseHeaderSize = objectMemory wordSize.
	jumpCompact jmpTarget:
		(cogit annotate: (cogit MoveMw: (objectMemory splObj: CompactClasses) r: destReg R: scratchReg)
			objRef: (objectMemory splObj: CompactClasses)).
	jumpGotClass jmpTarget:
		(cogit MoveMw: InstanceSpecificationIndex << objectMemory shiftForWord + objectMemory wordSize r: scratchReg R: destReg).
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genGetClassObjectOf: instReg into: destReg scratchReg: scratchReg instRegIsReceiver: instRegIsReceiver [
	"Fetch the instance's class into destReg.  This is almost identical
	 to genGetClassFormatOfNonInt:into:scratchReg: but because we
	 put the fetch of SmallInteger between the then and the else for 
	 compact class/non-compact class we cannot easily share code.
	 instRegIsReceiver is ignored.  It is for Spur compatibility where
	 objects may be forwarded."
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
	cogit LogicalShiftRightCq: (objectMemory compactClassFieldLSB - objectMemory shiftForWord) R: scratchReg.
	cogit AndCq: self compactClassFieldMask << objectMemory shiftForWord R: scratchReg.
	jumpCompact := cogit JumpNonZero: 0.
	cogit MoveMw: objectMemory classFieldOffset r: instReg R: destReg.
	cogit AndCq: AllButTypeMask signedIntFromLong R: destReg.
	jumpGotClass := cogit Jump: 0.
	jumpIsInt jmpTarget: (cogit genMoveConstant: objectMemory classSmallInteger R: destReg).
	jumpGotClass2 := cogit Jump: 0.
	"Don't have to subtract one from the destReg compactClassArray index because of the header word."
	self assert: objectMemory baseHeaderSize = objectMemory wordSize.
	jumpCompact jmpTarget:
		(cogit annotate: (cogit MoveMw: (objectMemory splObj: CompactClasses) r: scratchReg R: destReg)
			objRef: (objectMemory splObj: CompactClasses)).
	jumpGotClass jmpTarget:
	(jumpGotClass2 jmpTarget: cogit Label).
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genGetClassObjectOfNonCompact: instReg into: destReg [
	cogit
		MoveMw: objectMemory classFieldOffset r: instReg R: destReg;
		AndCq: AllButTypeMask signedIntFromLong R: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genGetClassTagOf: instReg into: destReg scratchReg: scratchReg [
	"Compatibility with SpurObjectRepresentation/SpurMemoryManager."
	| entryLabel |
	<var: #entryLabel type: #'AbstractInstruction *'>
	cogit AlignmentNops: (objectMemory wordSize max: 8).
	entryLabel := cogit Label.
	(self genGetClassObjectOf: instReg into: destReg scratchReg: scratchReg instRegIsReceiver: nil) ~= 0 ifTrue:
		[self error: 'internal error'].
	^entryLabel
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genGetCompactClassIndexNonImmOf: instReg into: destReg [
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
	cogit MoveM64: objectMemory baseHeaderSize r: srcReg Rd: destFPReg.
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

{ #category : #'primitive generators' }
CogObjectRepresentationForSqueakV3 >> genGetFormatOf: srcReg into: destReg [
	"Get the format field of the object in srcReg into destReg.
	 srcReg may equal destReg."
	<inline: true>
	cogit
		MoveMw: 0 r: srcReg R: destReg;
		LogicalShiftRightCq: objectMemory instFormatFieldLSB R: destReg;
		AndCq: self instFormatFieldMask R: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genGetHashFieldNonImmOf: instReg asSmallIntegerInto: destReg [
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

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genGetInlineCacheClassTagFrom: sourceReg into: destReg forEntry: forEntry [
	"Extract the inline cache tag for the object in sourceReg into destReg. The inline cache tag
	 for a given object is the value loaded in inline caches to distinguish objects of different
	 classes.  In Spur this is either the tags for immediates, or the receiver's classIndex.
	 The inline cache tag for a given object is the value loaded in inline caches to distinguish
	 objects of different classes.  In SqueakV3 the tag is the integer tag bit for SmallIntegers (1),
	 the compact class index shifted by log: 2 word size for objects with compact classes
	 (1 * 4 to: 31 * 4 by: 4), or the class.  These ranges cannot overlap because the heap
	 (and hence the lowest class object) is beyond the machine code zone.
	 If forEntry is true answer the entry label at which control is to enter (cmEntryOffset).
	 If forEntry is false, control enters at the start."
	| entryLabel jumpIsInt jumpCompact |
	<var: #entryLabel type: #'AbstractInstruction *'>
	<var: #jumpIsInt type: #'AbstractInstruction *'>
	<var: #jumpCompact type: #'AbstractInstruction *'>
	cogit AlignmentNops: (objectMemory wordSize max: 8).
	entryLabel := cogit Label.
	cogit MoveR: sourceReg R: destReg.
	cogit AndCq: 1 R: destReg.
	jumpIsInt := cogit JumpNonZero: 0.
	"Get header word in destReg"
	cogit MoveMw: 0 r: sourceReg R: destReg.
	"Extract the compact class field, and if non-zero use it as the tag.."
	self assert: self compactClassFieldMask << objectMemory compactClassFieldLSB < objectMemory nilObject asUnsignedInteger.
	cogit AndCq: self compactClassFieldMask << objectMemory compactClassFieldLSB R: destReg.
	jumpCompact := cogit JumpNonZero: 0.
	cogit MoveMw: objectMemory classFieldOffset r: sourceReg R: destReg.
	"The use of signedIntFromLong is a hack to get round short addressing mode computations.
	 Much easier if offsets are signed and the arithmetic machinery we have makes it difficult to
	 mix signed and unsigned offsets."
	cogit AndCq: AllButTypeMask signedIntFromLong R: destReg.
	jumpCompact jmpTarget: (jumpIsInt jmpTarget: cogit Label).
	^entryLabel
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genGetNumSlotsOf: srcRegister into: destRegister [
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
	  jumpFmtLeWeakArray jumpFmtIsArray jmpFmtGeFirstByte jumpGotByteSize jumpGotWordSize |
	<inline: true>
	"c.f. StackInterpreter>>stSizeOf: lengthOf:baseHeader:format: fixedFieldsOf:format:length:"
	"and one wonders why Squeak V1 through V3 are slow..."
	<var: #jumpNotIndexable type: #'AbstractInstruction *'>
	<var: #jumpIsContext type: #'AbstractInstruction *'>
	<var: #jumpShortHeader type: #'AbstractInstruction *'>
	<var: #jumpSkip type: #'AbstractInstruction *'>
	<var: #jumpFmtLeWeakArray type: #'AbstractInstruction *'>
	<var: #jumpFmtIsArray type: #'AbstractInstruction *'>
	<var: #jmpFmtGeFirstByte type: #'AbstractInstruction *'>
	<var: #jumpGotByteSize type: #'AbstractInstruction *'>
	<var: #jumpGotWordSize type: #'AbstractInstruction *'>
	cogit
		MoveMw: 0 r: sourceReg R: formatReg;				"destReg := self baseHeader: receiver"
		MoveR: formatReg R: destReg;
		LogicalShiftRightCq: objectMemory instFormatFieldLSB R: formatReg;
		AndCq: self instFormatFieldMask R: formatReg;		"formatReg := self formatOfHeader: destReg"
		CmpCq: objectMemory arrayFormat R: formatReg.
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
		MoveMw: 0 - (2 * objectMemory wordSize) r: sourceReg R: destReg; "(self sizeHeader: oop) bitAnd: LongSizeMask"
		AndCq: LongSizeMask signedIntFromLong R: destReg.
	jumpSkip :=  cogit Jump: 0.
	jumpShortHeader jmpTarget: (cogit AndCq: SizeMask R: destReg).	"hdr bitAnd: SizeMask"
	jumpSkip jmpTarget: (cogit SubCq: objectMemory baseHeaderSize R: destReg). "sz - BaseheaderSize for all three arms"
	cogit CmpCq: objectMemory weakArrayFormat R: formatReg.	"fmt <= 4"
	jumpFmtLeWeakArray := cogit JumpLessOrEqual: 0.
	cogit CmpCq: objectMemory firstByteFormat R: formatReg.
	jmpFmtGeFirstByte := cogit JumpLess: 0.
	cogit
		AndCq: 3 R: formatReg;	"(sz - BaseHeaderSize) - (fmt bitAnd: 3) bytes"
		SubR: formatReg R: destReg.
	jumpGotByteSize := cogit Jump: 0.
	jmpFmtGeFirstByte jmpTarget: (cogit LogicalShiftRightCq: 2 R: destReg). "(sz - BaseHeaderSize) >> 2 32-bit longs"
	jumpGotWordSize := cogit Jump: 0.
	jumpFmtLeWeakArray jmpTarget: cogit Label.
	cogit
		LogicalShiftRightCq: objectMemory shiftForWord R: destReg; "(sz - BaseHeaderSize) >> ShiftForWord words"
		CmpCq: objectMemory arrayFormat R: formatReg.
	jumpFmtIsArray := cogit JumpZero: 0.
	self genGetFixedFieldsOfPointerNonInt: sourceReg into: formatReg scratchReg: scratchReg.
	cogit SubR: formatReg R: destReg.
	jumpFmtIsArray jmpTarget:
	(jumpGotWordSize jmpTarget:
	(jumpGotByteSize jmpTarget:
		cogit Label)).
	aBinaryBlock value: jumpNotIndexable value: jumpIsContext
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genInlinedIdenticalOrNotIfGuts: orNot [
	<inline: true>
	^ cogit genVanillaInlinedIdenticalOrNotIf: orNot
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genJumpImmediate: aRegister [
	^self genJumpSmallInteger: aRegister
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genJumpInOldSpace: reg [
	"Jump if reg is old."
	<inline: true>
	^cogit
		MoveAw: objectMemory youngStartAddress R: TempReg;
		CmpR: TempReg R: reg;	"N.B. FLAGS := destReg - scratchReg"
		JumpBelow: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genJumpIsSmallIntegerValue: aRegister scratch: scratchReg [
	"Generate a test for aRegister containing an integer value in the SmallInteger range, and a jump if so, answering the jump.
	 c.f. ObjectMemory>>isIntegerValue:"
	<returnTypeC: #'AbstractInstruction *'>
	^cogit
		MoveR: aRegister R: scratchReg;
		LogicalShiftLeftCq: 1 R: scratchReg;
		XorR: aRegister R: scratchReg;
		JumpGreaterOrEqual: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genJumpNotImmediate: aRegister [
	<inline: true>
	^self genJumpNotSmallInteger: aRegister
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genJumpNotSmallInteger: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit TstCq: 1 R: aRegister.
	^cogit JumpZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genJumpNotSmallIntegerInScratchReg: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit AndCq: 1 R: aRegister.
	^cogit JumpZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genJumpNotSmallIntegerValue: aRegister scratch: scratchReg [
	"Generate a test for aRegister containing an integer value outside the SmallInteger range, and a jump if so, answering the jump.
	 c.f. ObjectMemory>>isIntegerValue:"
	<returnTypeC: #'AbstractInstruction *'>
	^cogit
		MoveR: aRegister R: scratchReg;
		ArithmeticShiftRightCq: 1 R: scratchReg;
		XorR: aRegister R: scratchReg;
		JumpLess: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genJumpSmallInteger: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit TstCq: 1 R: aRegister.
	^cogit JumpNonZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genJumpSmallIntegerInScratchReg: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit AndCq: 1 R: aRegister.
	^cogit JumpNonZero: 0
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSqueakV3 >> genLcFirstFieldPointer: objectReg [
	<option: #LowcodeVM>
	cogit AddCq: 4 R: objectReg.
	cogit ssPushNativeRegister: objectReg.
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSqueakV3 >> genLcFirstIndexableFieldPointer: objectReg [
	<option: #LowcodeVM>
	"TODO: Fixme for fixed fields"
	cogit AddCq: 4 R: objectReg.
	cogit ssPushNativeRegister: objectReg.
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSqueakV3 >> genLcInt32ToOop: value [
	<option: #LowcodeVM>
	value ~= ReceiverResultReg ifTrue: [ cogit MoveR: value R: ReceiverResultReg.].
	cogit CallRT: ceSigned32BitIntegerTrampoline.

	cogit MoveR: TempReg R: ReceiverResultReg.
	cogit ssPushRegister: ReceiverResultReg.
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSqueakV3 >> genLcIsBytes: objectReg to: valueReg [
	<option: #LowcodeVM>
	| isInteger isNotBytes falseTarget cont |
	
	"Check for integer"
	cogit MoveR: objectReg R: TempReg.
	cogit AndCq: 1 R: TempReg.
	isInteger := cogit JumpNonZero: 0.

	"Get the class format"
	self genGetClassFormatOfNonInt: objectReg into: valueReg scratchReg: TempReg.

	"Hack: consider a compiled method as bytes too."
	cogit CmpCq: 8 R: valueReg.
	isNotBytes := cogit JumpLess: 0.

	"True result"
	cogit MoveCq: 1 R: valueReg.
	cont := cogit Jump: 0.

	"False result"
	falseTarget := cogit Label.
	isInteger jmpTarget: falseTarget.
	isNotBytes jmpTarget: falseTarget.
	cogit MoveCq: 0 R: valueReg.

	"Return"
	cont jmpTarget: cogit Label.
	cogit ssPushNativeRegister: valueReg.
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSqueakV3 >> genLcIsFloatObject: objectReg to: valueReg [
	<option: #LowcodeVM>
	"TODO: Implement this one"
	cogit MoveCq: 1 R: valueReg.
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSqueakV3 >> genLcIsIndexable: objectReg to: valueReg [
	<option: #LowcodeVM>
	| isInteger isNotIndexable falseTarget cont |
	
	"Check for integer"
	cogit MoveR: objectReg R: TempReg.
	cogit AndCq: 1 R: TempReg.
	isInteger := cogit JumpNonZero: 0.

	"Get the class format"
	self genGetClassFormatOfNonInt: objectReg into: valueReg scratchReg: TempReg.

	"Hack: consider a compiled method as bytes too."
	cogit CmpCq: 2 R: valueReg.
	isNotIndexable := cogit JumpLess: 0.

	"True result"
	cogit MoveCq: 1 R: valueReg.
	cont := cogit Jump: 0.

	"False result"
	falseTarget := cogit Label.
	isInteger jmpTarget: falseTarget.
	isNotIndexable jmpTarget: falseTarget.
	cogit MoveCq: 0 R: valueReg.

	"Return"
	cont jmpTarget: cogit Label.
	cogit ssPushNativeRegister: valueReg.
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSqueakV3 >> genLcIsIntegerObject: objectReg to: valueReg [
	<option: #LowcodeVM>
	"TODO: Support larger integers"
	cogit AndCq: 1 R: objectReg.
	cogit ssPushNativeRegister: objectReg.
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSqueakV3 >> genLcIsPointers: objectReg to: valueReg [
	<option: #LowcodeVM>
	| isInteger isNotIndexable falseTarget cont |
	
	"Check for integer"
	cogit MoveR: objectReg R: TempReg.
	cogit AndCq: 1 R: TempReg.
	isInteger := cogit JumpNonZero: 0.

	"Get the class format"
	self genGetClassFormatOfNonInt: objectReg into: valueReg scratchReg: TempReg.

	"Hack: consider a compiled method as bytes too."
	cogit CmpCq: 3 R: valueReg.
	isNotIndexable := cogit JumpGreater: 0.

	"True result"
	cogit MoveCq: 1 R: valueReg.
	cont := cogit Jump: 0.

	"False result"
	falseTarget := cogit Label.
	isInteger jmpTarget: falseTarget.
	isNotIndexable jmpTarget: falseTarget.
	cogit MoveCq: 0 R: valueReg.

	"Return"
	cont jmpTarget: cogit Label.
	cogit ssPushNativeRegister: valueReg.
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSqueakV3 >> genLcIsWords: objectReg to: valueReg [
	<option: #LowcodeVM>
	| isInteger isNotWords falseTarget cont |
	
	"Check for integer"
	cogit MoveR: objectReg R: TempReg.
	cogit AndCq: 1 R: TempReg.
	isInteger := cogit JumpNonZero: 0.

	"Get the class format"
	self genGetClassFormatOfNonInt: objectReg into: valueReg scratchReg: TempReg.

	"Check for the words format"
	cogit CmpCq: 6 R: valueReg.
	isNotWords := cogit JumpNonZero: 0.

	"True result"
	cogit MoveCq: 1 R: valueReg.
	cont := cogit Jump: 0.

	"False result"
	falseTarget := cogit Label.
	isInteger jmpTarget: falseTarget.
	isNotWords jmpTarget: falseTarget.
	cogit MoveCq: 0 R: valueReg.

	"Return"
	cont jmpTarget: cogit Label.
	cogit ssPushNativeRegister: valueReg.
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSqueakV3 >> genLcIsWordsOrBytes: objectReg to: valueReg [
	<option: #LowcodeVM>
	| isInteger isNotBytes falseTarget cont |
	
	"Check for integer"
	cogit MoveR: objectReg R: TempReg.
	cogit AndCq: 1 R: TempReg.
	isInteger := cogit JumpNonZero: 0.

	"Get the class format"
	self genGetClassFormatOfNonInt: objectReg into: valueReg scratchReg: TempReg.

	"Hack: consider a compiled method as bytes too."
	cogit CmpCq: 6 R: valueReg.
	isNotBytes := cogit JumpLess: 0.

	"True result"
	cogit MoveCq: 1 R: valueReg.
	cont := cogit Jump: 0.

	"False result"
	falseTarget := cogit Label.
	isInteger jmpTarget: falseTarget.
	isNotBytes jmpTarget: falseTarget.
	cogit MoveCq: 0 R: valueReg.

	"Return"
	cont jmpTarget: cogit Label.
	cogit ssPushNativeRegister: valueReg.
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSqueakV3 >> genLcLoadObject: object at: fieldIndex [
	<option: #LowcodeVM>
	cogit AddCq: 1 R: fieldIndex.
	cogit MoveXwr: fieldIndex R: object R: object.
	cogit ssPushRegister: object
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSqueakV3 >> genLcLoadObject: object field: fieldIndex [
	<option: #LowcodeVM>
	cogit MoveMw: (fieldIndex+ 1) * BytesPerWord r: object R: object.
	cogit ssPushRegister: object
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSqueakV3 >> genLcOopToInt32: value [
	<option: #LowcodeVM>
	value ~= ReceiverResultReg ifTrue: [ cogit MoveR: value R: ReceiverResultReg.].
	cogit CallRT: ceSigned32BitValueOfTrampoline.

	cogit MoveR: TempReg R: ReceiverResultReg.
	cogit ssPushNativeRegister: ReceiverResultReg.
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSqueakV3 >> genLcOopToUInt32: value [
	<option: #LowcodeVM>
	value ~= ReceiverResultReg ifTrue: [ cogit MoveR: value R: ReceiverResultReg.].
	cogit CallRT: cePositive32BitValueOfTrampoline.

	cogit MoveR: TempReg R: ReceiverResultReg.
	cogit ssPushNativeRegister: ReceiverResultReg.
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSqueakV3 >> genLcStore: value object: object at: fieldIndex [
	<option: #LowcodeVM>
	cogit AddCq: 1 R: fieldIndex.
	cogit MoveR: value Xwr: fieldIndex R: object
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSqueakV3 >> genLcStore: value object: object field: fieldIndex [
	<option: #LowcodeVM>
	cogit MoveR: value Mw: (fieldIndex+ 1) * BytesPerWord r: object
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSqueakV3 >> genLcUInt32ToOop: value [
	<option: #LowcodeVM>
	value ~= ReceiverResultReg ifTrue: [ cogit MoveR: value R: ReceiverResultReg.].
	cogit CallRT: cePositive32BitIntegerTrampoline.

	cogit MoveR: TempReg R: ReceiverResultReg.
	cogit ssPushRegister: ReceiverResultReg.
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationForSqueakV3 >> genNewArrayOfSize: size initialized: initialized [
	"Generate a call to code that allocates a new Array of size.
	 The Array should be initialized with nils iff initialized is true.
	 The size arg is passed in SendNumArgsReg, the result
	 must come back in ReceiverResultReg."
	cogit
		MoveCq: size R: SendNumArgsReg;
		CallRT: ceCreateNewArrayTrampoline
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSqueakV3 >> genPrimitiveAt [
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
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	jumpSI := self genJumpSmallInteger: ReceiverResultReg.
	cogit MoveR: Arg0Reg R: Arg1Reg.
	jumpNotSI := self genJumpNotSmallInteger: Arg0Reg.
	self
		genGetSizeOf: ReceiverResultReg
		into: ClassReg
		formatReg: SendNumArgsReg
		scratchReg: TempReg
		abortJumpsInto: [:jnx :jic| jumpNotIndexable := jnx. jumpIsContext := jic].
	self genConvertSmallIntegerToIntegerInReg: Arg1Reg.
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
		AddCq: objectMemory baseHeaderSize / objectMemory wordSize R: Arg1Reg;
		MoveXwr: Arg1Reg R: ReceiverResultReg R: ReceiverResultReg;
		genPrimReturn.
	jumpFmtGt4 jmpTarget: cogit Label.
	"Byte objects have formats 8 through 15, Compiled methods being 12 through 15;
	 fail for CompiledMethod allowing the CoInterpeter to impose stricter bounds checks."
	cogit CmpCq: 8 R: ClassReg.
	jumpFmtLt8 := cogit JumpLess: 0.
	cogit CmpCq: 11 R: ClassReg.
	jumpFmtGt11 := cogit JumpGreater: 0.
	cogit
		AddCq: objectMemory baseHeaderSize R: Arg1Reg;
		MoveXbr: Arg1Reg R: ReceiverResultReg R: ReceiverResultReg.
	self genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
	cogit genPrimReturn.
	jumpFmtLt8 jmpTarget: cogit Label.
	self assert: objectMemory wordSize = 4. "documenting my laziness"
	cogit "Too lazy [knackered, more like. ed.] to define index with displacement addressing right now"
		AddCq: objectMemory baseHeaderSize / objectMemory wordSize R: Arg1Reg;
		MoveXwr: Arg1Reg R: ReceiverResultReg R: ReceiverResultReg;
		CmpCq: 16r3FFFFFFF R: ReceiverResultReg.
	jumpLarge := cogit JumpAbove: 0.
	self genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
	cogit genPrimReturn.
	jumpLarge jmpTarget: (cogit CallRT: cePositive32BitIntegerTrampoline).
	cogit
		MoveR: TempReg R: ReceiverResultReg;
		genPrimReturn.
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
CogObjectRepresentationForSqueakV3 >> genPrimitiveIdenticalOrNotIf: orNot [
	| jumpCmp |
	<var: #jumpCmp type: #'AbstractInstruction *'>
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	cogit CmpR: Arg0Reg R: ReceiverResultReg.
	jumpCmp := orNot
					ifTrue: [cogit JumpZero: 0]
					ifFalse: [cogit JumpNonZero: 0].
	cogit genMoveTrueR: ReceiverResultReg.
	cogit genPrimReturn.
	jumpCmp jmpTarget: (cogit genMoveFalseR: ReceiverResultReg).
	cogit genPrimReturn.
	^UnfailingPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSqueakV3 >> genPrimitiveIdentityHash [
	| jumpSI |
	<var: #jumpSI type: #'AbstractInstruction *'>
	jumpSI := self genJumpSmallInteger: ReceiverResultReg.
	self genGetHashFieldNonImmOf: ReceiverResultReg asSmallIntegerInto: TempReg.
	cogit MoveR: TempReg R: ReceiverResultReg.
	cogit genPrimReturn.
	jumpSI jmpTarget: cogit Label.
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSqueakV3 >> genPrimitiveSize [
	| jumpSI jumpNotIndexable jumpIsContext |
	"c.f. StackInterpreter>>stSizeOf: lengthOf:baseHeader:format: fixedFieldsOf:format:length:"
	<var: #jumpSI type: #'AbstractInstruction *'>
	<var: #jumpIsContext type: #'AbstractInstruction *'>
	<var: #jumpNotIndexable type: #'AbstractInstruction *'>
	jumpSI := self genJumpSmallInteger: ReceiverResultReg.
	self
		genGetSizeOf: ReceiverResultReg
		into: ClassReg
		formatReg: SendNumArgsReg
		scratchReg: TempReg
		abortJumpsInto: [:jnx :jic| jumpNotIndexable := jnx. jumpIsContext := jic].
	self genConvertIntegerToSmallIntegerInReg: ClassReg.
	cogit MoveR: ClassReg R: ReceiverResultReg.
	cogit genPrimReturn.
	jumpSI jmpTarget: (jumpNotIndexable jmpTarget: (jumpIsContext jmpTarget: cogit Label)).
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSqueakV3 >> genPrimitiveStringAt [
	| jumpNotSI jumpNotByteIndexable jumpBounds jumpShortHeader jumpSkip |
	"c.f. StackInterpreter>>stSizeOf: lengthOf:baseHeader:format: fixedFieldsOf:format:length:"
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpNotByteIndexable type: #'AbstractInstruction *'>
	<var: #jumpBounds type: #'AbstractInstruction *'>
	<var: #jumpShortHeader type: #'AbstractInstruction *'>
	<var: #jumpSkip type: #'AbstractInstruction *'>
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	cogit MoveR: Arg0Reg R: Arg1Reg.
	jumpNotSI := self genJumpNotSmallInteger: Arg0Reg.
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
		MoveMw: 0 - (2 * objectMemory wordSize) r: ReceiverResultReg R: ClassReg; "(self sizeHeader: oop) bitAnd: LongSizeMask"
		AndCq: LongSizeMask signedIntFromLong R: ClassReg.
	jumpSkip :=  cogit Jump: 0.
	jumpShortHeader jmpTarget: (cogit AndCq: SizeMask R: ClassReg).	"hdr bitAnd: SizeMask"
	jumpSkip jmpTarget: (cogit SubCq: objectMemory baseHeaderSize R: ClassReg). "sz - BaseHeaderSize"
	cogit SubR: SendNumArgsReg R: ClassReg. "sz - (fmt bitAnd: 3)"
	self genConvertSmallIntegerToIntegerInReg: Arg1Reg.
	cogit SubCq: 1 R: Arg1Reg.
	cogit CmpR: ClassReg R: Arg1Reg.
	jumpBounds := cogit JumpAboveOrEqual: 0.
	cogit AddCq: objectMemory baseHeaderSize R: Arg1Reg.
	cogit genMoveConstant: objectMemory characterTable R: Arg0Reg.
	cogit MoveXbr: Arg1Reg R: ReceiverResultReg R: ReceiverResultReg;
		AddCq: objectMemory baseHeaderSize / objectMemory wordSize R: ReceiverResultReg.
	cogit MoveXwr: ReceiverResultReg R: Arg0Reg R: ReceiverResultReg.
	cogit genPrimReturn.
	jumpNotSI jmpTarget:
	(jumpNotByteIndexable jmpTarget:
	(jumpBounds jmpTarget:
		cogit Label)).
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genRemoveSmallIntegerTagsInScratchReg: scratchReg [ 
	cogit SubCq: 1 R: scratchReg.
	^0
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

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genStoreSourceReg: sourceReg slotIndex: index destReg: destReg scratchReg: scratchReg inFrame: inFrame needsStoreCheck: needsStoreCheck [
	| jmpImmediate jmpDestYoung jmpSourceOld jmpAlreadyRoot mask rootBitByteOffset |
	<var: #jmpImmediate type: #'AbstractInstruction *'>
	<var: #jmpDestYoung type: #'AbstractInstruction *'>
	<var: #jmpSourceOld type: #'AbstractInstruction *'>
	<var: #jmpAlreadyRoot type: #'AbstractInstruction *'>
	
	cogit genTraceStores.
	"do the store"
	cogit MoveR: sourceReg Mw: index * objectMemory wordSize + objectMemory baseHeaderSize r: destReg.
	"if no need for the store check then returns"
	needsStoreCheck ifFalse: [ ^ 0 ].
	"now the check.  Is value stored an integer?  If so we're done"
	jmpImmediate := self genJumpImmediate: sourceReg.
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
							ifTrue: [objectMemory wordSize - RootBitDigitLength]
							ifFalse:[RootBitDigitLength - 1].
	mask := RootBitDigitLength > 1
				ifTrue: [RootBit >> (RootBitDigitLength - 1 * 8)]
				ifFalse: [RootBit].
	cogit MoveMb: rootBitByteOffset r: destReg R: scratchReg.
	cogit AndCq: mask R: scratchReg.
	jmpAlreadyRoot := cogit JumpNonZero: 0.
	"Root bit is not set.  Call store check to insert dest into root table."
	self assert: destReg == ReceiverResultReg.
	cogit 
		evaluateTrampolineCallBlock: [cogit CallRT: ceStoreCheckTrampoline]
		protectLinkRegIfNot: inFrame.
	jmpImmediate jmpTarget:
	(jmpDestYoung jmpTarget:
	(jmpSourceOld jmpTarget:
	(jmpAlreadyRoot jmpTarget:
		cogit Label))).
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> genStoreSourceReg: sourceReg slotIndex: index intoNewObjectInDestReg: destReg [
	cogit MoveR: sourceReg Mw: index * objectMemory wordSize + objectMemory baseHeaderSize r: destReg.
	^0
]

{ #category : #initialization }
CogObjectRepresentationForSqueakV3 >> generateObjectRepresentationTrampolines [
	"Do the store check.  Answer the argument for the benefit of the code generator;
	 ReceiverResultReg may be caller-saved and hence smashed by this call.  Answering
	 it allows the code generator to reload ReceiverResultReg cheaply."
	ceStoreCheckTrampoline := cogit
									genTrampolineFor: #ceStoreCheck:
									called: 'ceStoreCheckTrampoline'
									arg: ReceiverResultReg
									regsToSave: (CallerSavedRegisterMask bitClear: (cogit registerMaskFor: ReceiverResultReg))
									result: cogit returnRegForStoreCheck.
	ceCreateNewArrayTrampoline := cogit genTrampolineFor: #ceNewArraySlotSize:
											called: 'ceCreateNewArrayTrampoline'
											arg: SendNumArgsReg
											regsToSave: (CallerSavedRegisterMask bitClear: (cogit registerMaskFor: ReceiverResultReg))
											result: ReceiverResultReg.
	cePositive32BitIntegerTrampoline := cogit genTrampolineFor: #positive32BitIntegerFor:
												called: 'cePositive32BitIntegerTrampoline'
												arg: ReceiverResultReg
												regsToSave: (CallerSavedRegisterMask bitClear: (cogit registerMaskFor: ReceiverResultReg))
												result: TempReg.
	ceActiveContextTrampoline := self genActiveContextTrampoline.
	ceClosureCopyTrampoline := cogit genTrampolineFor: #ceClosureCopyDescriptor:
										called: 'ceClosureCopyTrampoline'
										arg: SendNumArgsReg
										regsToSave: (CallerSavedRegisterMask bitClear: (cogit registerMaskFor: ReceiverResultReg))
										result: ReceiverResultReg.
										
	LowcodeVM ifTrue:
		[cePositive32BitValueOfTrampoline := cogit genTrampolineFor: #positive32BitValueOf:
													called: 'cePositive32BitValueOfTrampoline'
													arg: ReceiverResultReg
													result: TempReg.
		ceSigned32BitIntegerTrampoline := cogit genTrampolineFor: #signed32BitIntegerFor:
													called: 'ceSigned32BitIntegerTrampoline'
													arg: ReceiverResultReg
													result: TempReg.
		ceSigned32BitValueOfTrampoline := cogit genTrampolineFor: #signed32BitValueOf:
													called: 'ceSigned32BitValueOfTrampoline'
													arg: ReceiverResultReg
													result: TempReg.

		self generateLowcodeObjectTrampolines]
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> hasValidHeaderPostGC: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	^cogMethod objectHeader = objectMemory nullHeaderForMachineCodeMethod
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationForSqueakV3 >> illegalClassTag [
	^0
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationForSqueakV3 >> inlineCacheTagForClass: classOop [
	"Answer the relevant inline cache tag for a class.
	 c.f. inlineCacheTagForInstance:"
	| cci |
	classOop = objectMemory classSmallInteger ifTrue:
		[^objectMemory integerObjectOf: 0]. "the SmallInteger tag"
	(cci :=  objectMemory noShiftCompactClassIndexOfHeader: (objectMemory formatOfClass: classOop)) > 0 ifTrue:
		[^cci].
	^classOop
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationForSqueakV3 >> inlineCacheTagForInstance: oop [
	"Answer the relevant inline cache tag for an instance.
	 c.f. getInlineCacheClassTagFrom:into: & inlineCacheTagForClass:"
	| cci |
	(objectMemory isIntegerObject: oop) ifTrue:
		[^objectMemory integerObjectOf: 0]. "the SmallInteger tag"
	(cci :=  objectMemory noShiftCompactClassIndexOf: oop) > 0 ifTrue:
		[^cci].
	^(objectMemory classHeader: oop) bitAnd: AllButTypeMask
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationForSqueakV3 >> inlineCacheTagIsYoung: cacheTag [
	^objectMemory isYoung: cacheTag
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationForSqueakV3 >> inlineCacheTagsMayBeObjects [
	^true
]

{ #category : #'object representation' }
CogObjectRepresentationForSqueakV3 >> instFormatFieldMask [
	"This is the mask for the field when shifted into the least significant bits"
	<inline: true>
	^(1 << objectMemory instFormatFieldWidth) - 1
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> isOopForwarded: oop [
	"Compatibility wth SpurMemoryManager.  In ObjectMemory, no forwarding pointers
	 are visible to the VM."
	<inline: true>
	^false
]

{ #category : #'object representation' }
CogObjectRepresentationForSqueakV3 >> isSmallIntegerTagNonZero [
	^true
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> markAndTraceCacheTagLiteral: literal in: cogMethodOrNil atpc: address [
	"Mark and trace a literal in an inline cache preceding address in cogMethodOrNil.
	 Answer if code was modified."
	<var: #cogMethodOrNil type: #'CogMethod *'>
	<var: #address type: #usqInt>
	<inline: true>
	self markAndTraceLiteral: literal.
	^false
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> markAndTraceLiteral: literal [
	(self couldBeObject: literal) ifTrue:
		[self assert: (objectMemory addressCouldBeObj: literal).
		 objectMemory markAndTrace: literal]
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> markAndTraceLiteral: literal in: cogMethod at: address [
	"Mark and trace a literal in a sqInt variable of cogMethod."
	<var: #cogMethod type: #'CogMethod *'>
	<var: #address type: #'sqInt *'>
	<inline: true>
	self markAndTraceLiteral: literal
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> markAndTraceLiteral: literal in: cogMethodOrNil atpc: address [
	"Mark and trace a literal in a machine code instruction preceding address in cogMethodOrNil.
	 Answer if code was modified."
	<var: #cogMethodOrNil type: #'CogMethod *'>
	<var: #address type: #usqInt>
	<inline: true>
	self markAndTraceLiteral: literal.
	^false
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> markAndTraceLiteralIfYoung: literal [
	((self couldBeObject: literal)
	 and: [objectMemory isYoungObject: literal]) ifTrue:
		[self assert: (objectMemory addressCouldBeObj: literal).
		 objectMemory markAndTrace: literal]
]

{ #category : #'sista support' }
CogObjectRepresentationForSqueakV3 >> numCountersFor: theCounters [
	<var: #theCounters type: #usqInt>
	^objectMemory longAt: theCounters - (self sizeof: #sqInt)
]

{ #category : #'calling convention' }
CogObjectRepresentationForSqueakV3 >> numRegArgs [
	"Define how many register arguments a StackToRegisterMappingCogit can
	 and should use with the receiver.  The value must be 0, 1 or 2.  Note that a
	 SimpleStackBasedCogit always has 0 register args (although the receiver is
	 passed in a register).  CogObjectRepresentationForSqueakV3 only implements
	 at most 1-arg primitives, because the complexity of the object representation
	 makes it difficult to implement at:put:, the most performance-critical 2-argument
	 primitive..  The method must be inlined in CoInterpreter, and dead code eliminated
	 so that the register-popping enilopmarts such as enterRegisterArgCogMethod:-
	 at:receiver: do not have to be implemented in SimpleStackBasedCogit."
	<api>
	<option: #StackToRegisterMappingCogit>
	^1
]

{ #category : #'object representation' }
CogObjectRepresentationForSqueakV3 >> numSmallIntegerBits [
	^31
]

{ #category : #'object representation' }
CogObjectRepresentationForSqueakV3 >> numSmallIntegerTagBits [
	^1
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> remapObject: objOop [
	self assert: (objectMemory addressCouldBeObj: objOop).
	^objectMemory remap: objOop
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> remapOop: oop [
	^(objectMemory isIntegerObject: oop)
		ifTrue: [oop]
		ifFalse: [objectMemory remap: oop]
]

{ #category : #'sista support' }
CogObjectRepresentationForSqueakV3 >> resetCountersIn: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	<api>
	<option: #SistaCogit>
	cogit
		fillInCounters: (self numCountersFor: cogMethod counters)
		atStartAddress: cogMethod counters
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> shouldAnnotateObjectReference: anOop [
	"self assert: ((objectMemory isIntegerObject: anOop)
				or: [objectMemory addressCouldBeObj: anOop])."
	^(objectMemory isNonIntegerObject: anOop)
	  and: [self oop: anOop isGreaterThan: objectMemory trueObject]
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSqueakV3 >> slotOffsetOfInstVarIndex: index [
	^index * objectMemory wordSize + objectMemory baseHeaderSize
]

{ #category : #testing }
CogObjectRepresentationForSqueakV3 >> smallIntegerIsOnlyImmediateType [
	^true
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSqueakV3 >> validInlineCacheTag: cacheTag [
	^cacheTag = ConstZero
	  or: [((cacheTag bitAnd: 1 << objectMemory shiftForWord - 1) = 0
		   and: [cacheTag
				between: 1 << objectMemory compactClassFieldLSB
				and: (objectMemory compactClassIndexOfHeader: -1) << objectMemory compactClassFieldLSB])
		 or: [self checkValidObjectReference: cacheTag]]
]

{ #category : #'sista support' }
CogObjectRepresentationForSqueakV3 >> valueOfAssociation: association [
	^objectMemory fetchPointer: ValueIndex ofObject: association
]
