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
		cogit JumpZero: targetFixUp ].
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
CogObjectRepresentationFor64BitSpur >> branchIf: reg hasNotImmediateTag: classIndex target: targetFixUp [
	| jmpImmediate|
	<inline: true>
	cogit MoveR: reg R: TempReg.
	classIndex = objectMemory smallIntegerTag ifTrue:
		[jmpImmediate := self genJumpNotSmallIntegerInScratchReg: TempReg].
	classIndex = objectMemory characterTag ifTrue:
		[jmpImmediate := self genJumpNotCharacterInScratchReg: TempReg].
	classIndex = objectMemory smallFloatTag ifTrue:
		[jmpImmediate := self genJumpNotSmallFloatInScratchReg: TempReg].
	jmpImmediate jmpTarget: targetFixUp
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
CogObjectRepresentationFor64BitSpur >> genConvertIntegerToSmallIntegerInReg: reg [
	cogit LogicalShiftLeftCq: self numTagBits R: reg.
	cogit AddCq: 1 R: reg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genConvertSmallIntegerToIntegerInReg: reg [
	cogit ArithmeticShiftRightCq: self numTagBits R: reg.
	^0
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

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genInnerPrimitiveNew: retNoffset [
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
	cogit RetN: retNoffset.

	jumpUnhashed jmpTarget:
	(jumpVariableOrEphemeron jmpTarget:
	(jumpTooBig jmpTarget:
	(jumpNoSpace jmpTarget: cogit Label))).

	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationFor64BitSpur >> genInnerPrimitiveNewWithArg: retNoffset [
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

	"header will contain classIndex/class's hash & format & numSlots/fixed size"
	headerReg := SendNumArgsReg.
	"Assume there's an available scratch register on 64-bit machines"
	fillReg := Scratch0Reg.
	self assert: (cogit backEnd concreteRegister: fillReg) > 0.
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
	jumpNElementsNonInt := self genJumpNotSmallInteger: Arg0Reg.
	jumpNElementsNonInt asInteger = UnimplementedOperation ifTrue:
		[cogit MoveR: Arg0Reg R: TempReg.
		 jumpNElementsNonInt := self genJumpNotSmallIntegerInScratchReg: TempReg].
	"get class's format inst var for inst spec (format field)"
	self genLoadSlot: InstanceSpecificationIndex sourceReg: ReceiverResultReg destReg: instSpecReg.
	cogit LogicalShiftRightCq: objectMemory fixedFieldsFieldWidth + self numSmallIntegerTagBits R: instSpecReg.
	cogit AndCq: objectMemory formatMask R: instSpecReg.
	"Add format to classIndex/format header now"
	cogit MoveR: instSpecReg R: TempReg.
	cogit LogicalShiftLeftCq: objectMemory formatShift R: TempReg.
	cogit AddR: TempReg R: headerReg.
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
	cogit MoveCq: 0 R: fillReg.
	jumpLongPrepDone := cogit Jump: 0. "go allocate"

	jumpByteFormat jmpTarget:
	(cogit CmpCq: (objectMemory integerObjectOf: maxSlots * objectMemory wordSize) R: Arg0Reg).
	jumpByteTooBig := cogit JumpAbove: 0.
	"save num elements to instSpecReg"
	cogit MoveR: TempReg R: instSpecReg.
	"compute odd bits and add into headerReg; oddBits := 4 - nElements bitAnd: 3"
	cogit MoveCq: objectMemory wordSize R: TempReg.
	cogit SubR: instSpecReg R: TempReg.
	cogit AndCq: objectMemory wordSize - 1 R: TempReg.
	cogit LogicalShiftLeftCq: objectMemory formatShift R: TempReg.
	cogit AddR: TempReg R: headerReg.
	"round up num elements to numSlots in instSpecReg"
	cogit AddCq: objectMemory wordSize - 1 R: instSpecReg.
	cogit LogicalShiftRightCq: objectMemory shiftForWord R: instSpecReg.
	"store numSlots to headerReg"
	cogit MoveR: instSpecReg R: TempReg.
	cogit LogicalShiftLeftCq: objectMemory numSlotsFullShift R: TempReg.
	cogit AddR: TempReg R: headerReg.
	cogit MoveCq: 0 R: fillReg.
	jumpBytePrepDone := cogit Jump: 0. "go allocate"

	jumpArrayFormat jmpTarget:
		(cogit CmpCq: (objectMemory integerObjectOf: maxSlots) R: Arg0Reg).
	jumpArrayTooBig := cogit JumpAbove: 0.
	"save num elements/slot size to instSpecReg"
	cogit MoveR: TempReg R: instSpecReg.
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
	"round up to allocationUnit"
	jumpHasSlots jmpTarget:
	(cogit MoveR: byteSizeReg R: TempReg).
	cogit AddR: TempReg R: byteSizeReg.
	cogit AddCq: objectMemory baseHeaderSize / objectMemory wordSize R: byteSizeReg.
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
	cogit RetN: retNoffset.
	
	jumpNoSpace jmpTarget:
	(jumpUnhashed jmpTarget:
	(jumpFailCuzFixed jmpTarget:
	(jumpArrayTooBig jmpTarget:
	(jumpByteTooBig jmpTarget:
	(jumpLongTooBig jmpTarget:
	(jumpNElementsNonInt jmpTarget: cogit Label)))))).

	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genJumpNotSmallInteger: reg scratchReg: scratch [
	"Generate a compare and branch to test if aRegister contains other than a SmallInteger.
	 Answer the jump.  Override since scratch is needed."
	cogit AndCq: objectMemory tagMask R: reg R: scratch.
	cogit CmpCq: objectMemory smallIntegerTag R: scratch.
	^cogit JumpNonZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genJumpNotSmallIntegerInScratchReg: aRegister [
	^self genJumpNotSmallInteger: aRegister scratchReg: TempReg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genJumpSmallInteger: reg scratchReg: scratch [
	"Generate a compare and branch to test if aRegister contains a SmallInteger.
	 Answer the jump.  Override since scratch is needed."
	cogit AndCq: objectMemory tagMask R: reg R: scratch.
	cogit CmpCq: objectMemory smallIntegerTag R: scratch.
	^cogit JumpZero: 0
]

{ #category : #initialization }
CogObjectRepresentationFor64BitSpur >> genLoadHeaderIntoNewInstance: header [
	"Generate the instructions to move the constant header into a new instance pointed to by ReceiverResultReg."
	<inline: true>
	self flag: #endianness.
	cogit
		MoveCq: header R: TempReg;
		MoveR: TempReg Mw: 0 r: ReceiverResultReg
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationFor64BitSpur >> genNoPopCreateClosureAt: bcpc numArgs: numArgs numCopied: numCopied contextNumArgs: ctxtNumArgs large: isLargeCtxt inBlock: isInBlock [
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
	cogit
		MoveAw: objectMemory freeStartAddress R: ReceiverResultReg;
		MoveCq: header R: TempReg;
		MoveR: TempReg Mw: 0 r: ReceiverResultReg;
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
CogObjectRepresentationFor64BitSpur >> genRemoveSmallIntegerTagsInScratchReg: scratchReg [
	cogit SubCq: 1 R: scratchReg.
	^0
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationFor64BitSpur >> illegalClassTag [
	<inline: true>
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

{ #category : #initialization }
CogObjectRepresentationFor64BitSpur >> maybeGenerateSelectorIndexDereferenceRoutine [
	"Generate the routine that converts selector indices into selector objects.
	 It is called from the send trampolines.
	 If the selector index is negative, convert it into a positive index into the
	 special selectors array and index that.  Otherwise, index the current method."
	| jumpNegative |
	<var: 'jumpNegative' type: #'AbstractInstruction *'>
	cogit zeroOpcodeIndex.
	cogit CmpCq: 0 R: ClassReg.
	jumpNegative := cogit JumpLess: 0.
	cogit
		MoveMw: FoxMethod r: FPReg R: Scratch0Reg;
		AddCq: 2 R: ClassReg; "Change selector index to 1-relative, skipping the method header"
		AndCq: methodZone alignment negated R: Scratch0Reg;
		MoveMw: (cogit offset: CogMethod of: #methodObject) r: Scratch0Reg R: Scratch1Reg;
		MoveXwr: ClassReg R: Scratch1Reg R: ClassReg;
		RetN: 0.
	jumpNegative jmpTarget: cogit Label.
	cogit
		NegateR: ClassReg;
		LogicalShiftLeftCq: 1 R: ClassReg;
		MoveAw: objectMemory specialObjectsArrayAddress R: Scratch0Reg;
		SubCq: 1 R: ClassReg;
		MoveMw: SpecialSelectors + 1 * objectMemory wordSize r: Scratch0Reg R: Scratch1Reg; "Index, including header size"
		MoveXwr: ClassReg R: Scratch1Reg R: ClassReg;
		RetN: 0.
	ceDereferenceSelectorIndex := cogit methodZoneBase.
	cogit
		outputInstructionsForGeneratedRuntimeAt: ceDereferenceSelectorIndex;
		recordGeneratedRunTime: 'ceDereferenceSelectorIndex' address: ceDereferenceSelectorIndex;
		recordRunTimeObjectReferences
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> numCharacterBits [
	^61
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

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> numTagBits [
	<inline: true>
	^3
]

{ #category : #'calling convention' }
CogObjectRepresentationFor64BitSpur >> selectorIndexDereferenceRoutine [
	"If the object representation is 64-bits, selectors must be accessed via indices in the inline caches.
	 Answer the routine that will map from indices to selector objects if so, otherwise nil."
	<inline: true>
	^ceDereferenceSelectorIndex
]

{ #category : #'debug support' }
CogObjectRepresentationFor64BitSpur >> validInlineCacheTag: classIndexOrTagPattern [
	"The three valid tag patterns are 1 (SmallInteger), 2 (Character) and 3 (SmallFloat64)."
	^(classIndexOrTagPattern >= 1
	  and: [classIndexOrTagPattern <= 3])
	  or: [(objectMemory classAtIndex: classIndexOrTagPattern) notNil]
]
