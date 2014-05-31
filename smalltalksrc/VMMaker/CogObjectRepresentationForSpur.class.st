Class {
	#name : #CogObjectRepresentationForSpur,
	#superclass : #CogObjectRepresentation,
	#instVars : [
		'ceSheduleScavengeTrampoline',
		'ceSmallActiveContextInMethodTrampoline',
		'ceSmallActiveContextInBlockTrampoline',
		'ceLargeActiveContextInMethodTrampoline',
		'ceLargeActiveContextInBlockTrampoline'
	],
	#pools : [
		'CogCompilationConstants',
		'VMSqueakClassIndices',
		'VMSqueakV3BytecodeConstants'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> allYoungObjectsAgeInFullGC [
	^false
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> cacheTagIsMarked: cacheTag [
	"Answer if the cacheTag is not unmarked, i.e. answer true for compact class
	 indices and immediates; only answer false for unmarked objects.  In Spur
	 linked send cache tags are class indices so effectively they're always marked."
	^true
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationForSpur >> canLinkToYoungClasses [
	<api>
	<cmacro: '() true'>
	^true
]

{ #category : #'debug support' }
CogObjectRepresentationForSpur >> checkValidInlineCacheTag: classIndexOrTagPattern [
	^classIndexOrTagPattern <= objectMemory tagMask
	  or: [(objectMemory classAtIndex: classIndexOrTagPattern) notNil]
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

{ #category : #initialization }
CogObjectRepresentationForSpur >> genActiveContextTrampolineLarge: isLarge inBlock: isBlock [
	"Create a trampoline to answer the active context that will
	 answer it if a frame is already married, and create it otherwise.
	 Assume numArgs is in SendNumArgsReg."
	self subclassResponsibility
]

{ #category : #initialization }
CogObjectRepresentationForSpur >> genActiveContextTrampolineLarge: isLarge inBlock: isInBlock called: aString [
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
							classIndex: objectMemory classFloatCompactIndex.
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
	"Make sure that the object in reg is not forwarded."
	| loop ok |
	<var: #ok type: #'AbstractInstruction *'>
	<var: #loop type: #'AbstractInstruction *'>
	self assert: reg ~= scratch.
	loop := cogit Label.
	self genGetClassIndexOfNonImm: reg into: scratch.
	cogit CmpCq: objectMemory isForwardedObjectClassIndexPun
		R: TempReg.
	ok := cogit JumpNonZero:  0.
	self genLoadSlot: 0 sourceReg: reg destReg: reg.
	cogit Jump: loop.
	ok jmpTarget: cogit Label.
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
										bitAnd: cogit callerSavedRegMask).
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
	super generateObjectRepresentationTrampolines.
	ceSheduleScavengeTrampoline := cogit
											genSafeTrampolineFor: #ceSheduleScavenge
											called: 'ceSheduleScavengeTrampoline'.
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

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> getInlineCacheClassTagFrom: sourceReg into: destReg [
	"Extract the inline cache tag for the object in sourceReg into destReg. The inline cache tag
	 for a given object is the value loaded in inline caches to distinguish objects of different
	 classes.  In Spur this is either the tags for immediates, or the receiver's classIndex."
	^self subclassResponsibility
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> hasValidHeaderPostGC: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	^cogMethod objectHeader = objectMemory nullHeaderForMachineCodeMethod
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationForSpur >> inlineCacheTagForInstance: oop [
	"c.f. getInlineCacheClassTagFrom:into:"
	(objectMemory isImmediate: oop) ifTrue:
		[(objectMemory isIntegerObject: oop) ifTrue:
			[^objectMemory integerObjectOf: 0]. "the SmallInteger tag"
		 ^oop bitAnd: objectMemory tagMask]. "the other tags"
	^objectMemory classIndexOf: oop
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
CogObjectRepresentationForSpur >> markAndTraceLiteral: literal [
	(self couldBeObject: literal) ifTrue:
		[self assert: (objectMemory addressCouldBeObj: literal).
		 objectMemory markAndTrace: literal]
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> markAndTraceLiteralIfYoung: literal [
	((self couldBeObject: literal)
	 and: [objectMemory isYoungObject: literal]) ifTrue:
		[self assert: (objectMemory addressCouldBeObj: literal).
		 objectMemory markAndTrace: literal]
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
