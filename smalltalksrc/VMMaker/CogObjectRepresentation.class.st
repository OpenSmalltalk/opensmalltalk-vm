"
I am an abstract superclass for object representations whose job it is to generate abstract instructions for accessing objects.  It is hoped that this level of indirection between the Cogit code generator and object access makes it easier to adapt the code generator to different garbage collectors, object representations and languages.
"
Class {
	#name : #CogObjectRepresentation,
	#superclass : #CogClass,
	#instVars : [
		'cogit',
		'methodZone',
		'objectMemory',
		'coInterpreter',
		'ceStoreCheckTrampoline',
		'ceByteSizeOfTrampoline',
		'ceInstantiateClassTrampoline',
		'ceInstantiateClassIndexableSizeTrampoline',
		'ceFloatObjectOfTrampoline',
		'ceFloatValueOfTrampoline',
		'ceSigned64BitIntegerTrampoline',
		'ceSigned64BitValueOfTrampoline',
		'cePositive64BitIntegerTrampoline',
		'cePositive64BitValueOfTrampoline'
	],
	#pools : [
		'CogAbstractRegisters',
		'CogCompilationConstants',
		'CogMethodConstants',
		'CogRTLOpcodes',
		'VMBasicConstants',
		'VMObjectIndices',
		'VMSqueakClassIndices',
		'VMStackFrameOffsets'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'instance creation' }
CogObjectRepresentation class >> forCogit: aCogit methodZone: methodZone [
	^self new setCogit: aCogit methodZone: methodZone
]

{ #category : #translation }
CogObjectRepresentation class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #initialization }
CogObjectRepresentation class >> initializeMiscConstants [
	"Override to avoid inheriting (and hence repeating) VMClass class>>initializeMiscConstants.
	 Subclasses that have misc constants to initialize will override further."
]

{ #category : #accessing }
CogObjectRepresentation class >> numTrampolines [
	^1 "ceStoreCheckTrampoline"
]

{ #category : #translation }
CogObjectRepresentation class >> typeForSelf [
	^#implicit
]

{ #category : #accessing }
CogObjectRepresentation class >> wordSize [
	^4
]

{ #category : #'garbage collection' }
CogObjectRepresentation >> allYoungObjectsAgeInFullGC [
	^self subclassResponsibility
]

{ #category : #'sista support' }
CogObjectRepresentation >> allocateCounters: nCounters [
	self subclassResponsibility
]

{ #category : #testing }
CogObjectRepresentation >> canPinObjects [
	"Answer if the memory manager supports pinned objects."
	^false
]

{ #category : #accessing }
CogObjectRepresentation >> ceStoreCheckTrampoline: anAddress [
	<doNotGenerate>
	ceStoreCheckTrampoline := anAddress
]

{ #category : #'garbage collection' }
CogObjectRepresentation >> checkValidObjectReference: anOop [
	^(objectMemory isImmediate: anOop) not
	   and: [(objectMemory heapMapAtWord: (self pointerForOop: anOop)) ~= 0]
]

{ #category : #'in-line cacheing' }
CogObjectRepresentation >> classForInlineCacheTag: classIndex [
	^self subclassResponsibility
]

{ #category : #'bytecode generator support' }
CogObjectRepresentation >> createsArraysInline [
	"Answer if the object representation allocates arrays inline.  By
	 default answer false. Better code can be generated when creating
	 arrays inline if values are /not/ flushed to the stack."
	^false
]

{ #category : #'bytecode generator support' }
CogObjectRepresentation >> createsClosuresInline [
	"Answer if the object representation allocates closures inline.  By
	 default answer false. Better code can be generated when creating
	 closures inline if copied values are /not/ flushed to the stack."
	^false
]

{ #category : #compilation }
CogObjectRepresentation >> ensureNoForwardedLiteralsIn: aMethodObj [
	"Ensure there are no forwarded literals in the argument.
	 By default this is a noop.  Subclasses redefine as necessary."
	<inline: true>
]

{ #category : #'sista support' }
CogObjectRepresentation >> freeCounters: theCounters [
	<var: #theCounters type: #usqInt>
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genClearAndSetSmallIntegerTagsIn: scratchReg [
	"Set the SmallInteger tag bits when the tag bits may be filled with garbage."
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genCmpClassFloatCompactIndexR: reg [
	^cogit CmpCq: ClassFloatCompactIndex R: reg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genCmpClassMethodContextCompactIndexR: reg [
	^cogit CmpCq: ClassMethodContextCompactIndex R: reg
]

{ #category : #'sista support' }
CogObjectRepresentation >> genConvertSmallFloatToSmallFloatHashAsIntegerInReg: reg scratch: scratch [
	^EncounteredUnknownBytecode
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genConvertSmallIntegerToIntegerInReg: aRegister [

	self subclassResponsibility
]

{ #category : #'bytecode generator support' }
CogObjectRepresentation >> genCreateClosureAt: bcpc numArgs: numArgs numCopied: numCopied contextNumArgs: ctxtNumArgs large: isLargeCtxt inBlock: isInBlock [
	"Create a closure with the given startpc, numArgs and numCopied
	 within a context with ctxtNumArgs, large if isLargeCtxt that is in a
	 block if isInBlock.  If numCopied > 0 pop those values off the stack."
	self subclassResponsibility
]

{ #category : #'bytecode generator support' }
CogObjectRepresentation >> genCreateFullClosure: compiledBlock numArgs: numArgs numCopied: numCopied ignoreContext: ignoreContext contextNumArgs: contextNumArgs large: contextIsLarge inBlock: contextIsBlock [
	"Create a full closure"
	self subclassResponsibility
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genDoubleArithmetic: arithmeticOperator preOpCheck: preOpCheckOrNil [
	<option: #DPFPReg0>
	<var: #preOpCheckOrNil declareC: 'AbstractInstruction *(*preOpCheckOrNil)(int rcvrReg, int argReg)'>
	| jumpFailClass jumpFailAlloc jumpFailCheck jumpImmediate jumpNonInt doOp |
	<var: #jumpFailClass type: #'AbstractInstruction *'>
	<var: #jumpFailAlloc type: #'AbstractInstruction *'>
	<var: #jumpImmediate type: #'AbstractInstruction *'>
	<var: #jumpNonInt type: #'AbstractInstruction *'>
	<var: #jumpFailCheck type: #'AbstractInstruction *'>
	<var: #doOp type: #'AbstractInstruction *'>
	cogit processorHasDoublePrecisionFloatingPointSupport ifFalse:
		[^UnimplementedPrimitive].
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	self genGetDoubleValueOf: ReceiverResultReg into: DPFPReg0.
	cogit MoveR: Arg0Reg R: ClassReg.
	jumpImmediate := self genJumpImmediate: Arg0Reg.
	self genGetCompactClassIndexNonImmOf: Arg0Reg into: SendNumArgsReg.
	self genCmpClassFloatCompactIndexR: SendNumArgsReg.
	jumpFailClass := cogit JumpNonZero: 0.
	self genGetDoubleValueOf: Arg0Reg into: DPFPReg1.
	doOp := cogit Label.
	preOpCheckOrNil ifNotNil:
		[jumpFailCheck := cogit perform: preOpCheckOrNil with: DPFPReg0 with: DPFPReg1].
	cogit gen: arithmeticOperator operand: DPFPReg1 operand: DPFPReg0.
	jumpFailAlloc := self
						genAllocFloatValue: DPFPReg0
						into: SendNumArgsReg
						scratchReg: ClassReg
						scratchReg: TempReg.
	cogit MoveR: SendNumArgsReg R: ReceiverResultReg.
	cogit genPrimReturn.
	jumpImmediate jmpTarget: cogit Label.
	self maybeGenConvertIfSmallFloatIn: Arg0Reg scratchReg: TempReg into: DPFPReg1 andJumpTo: doOp.
	self smallIntegerIsOnlyImmediateType ifFalse:
		[jumpNonInt := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg].
	self genConvertSmallIntegerToIntegerInReg: ClassReg.
	cogit ConvertR: ClassReg Rd: DPFPReg1.
	cogit Jump: doOp.
	jumpFailAlloc jmpTarget:  (jumpFailClass jmpTarget: cogit Label).
	self smallIntegerIsOnlyImmediateType ifFalse:
		[jumpNonInt jmpTarget: jumpFailClass getJmpTarget].
	preOpCheckOrNil ifNotNil:
		[jumpFailCheck jmpTarget: jumpFailClass getJmpTarget].
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genDoubleComparison: jumpOpcodeGenerator invert: invertComparison [
	<option: #DPFPReg0>
	<var: #jumpOpcodeGenerator declareC: 'AbstractInstruction * NoDbgRegParms (*jumpOpcodeGenerator)(void *)'>
	| jumpFail jumpImmediate jumpNonInt jumpCond compare |
	<var: #jumpImmediate type: #'AbstractInstruction *'>
	<var: #jumpNonInt type: #'AbstractInstruction *'>
	<var: #jumpCond type: #'AbstractInstruction *'>
	<var: #compare type: #'AbstractInstruction *'>
	<var: #jumpFail type: #'AbstractInstruction *'>
	cogit processorHasDoublePrecisionFloatingPointSupport ifFalse:
		[^UnimplementedPrimitive].
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	self genGetDoubleValueOf: ReceiverResultReg into: DPFPReg0.
	jumpImmediate := self genJumpImmediate: Arg0Reg.
	self genGetCompactClassIndexNonImmOf: Arg0Reg into: SendNumArgsReg.
	self genCmpClassFloatCompactIndexR: SendNumArgsReg.
	jumpFail := cogit JumpNonZero: 0.
	self genGetDoubleValueOf: Arg0Reg into: DPFPReg1.
	invertComparison "May need to invert for NaNs"
		ifTrue: [compare := cogit CmpRd: DPFPReg0 Rd: DPFPReg1]
		ifFalse: [compare := cogit CmpRd: DPFPReg1 Rd: DPFPReg0].
	jumpCond := cogit perform: jumpOpcodeGenerator with: 0. "FP jumps are a little weird"
	cogit genMoveFalseR: ReceiverResultReg.
	cogit genPrimReturn.
	jumpCond jmpTarget: (cogit genMoveTrueR: ReceiverResultReg).
	cogit genPrimReturn.
	jumpImmediate jmpTarget: cogit Label.
	self maybeGenConvertIfSmallFloatIn: Arg0Reg scratchReg: TempReg into: DPFPReg1 andJumpTo: compare.
	self smallIntegerIsOnlyImmediateType ifFalse:
		[jumpNonInt := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg].
	self genConvertSmallIntegerToIntegerInReg: Arg0Reg.
	cogit ConvertR: Arg0Reg Rd: DPFPReg1.
	cogit Jump: compare.
	jumpFail jmpTarget: cogit Label.
	self smallIntegerIsOnlyImmediateType ifFalse:
		[jumpNonInt jmpTarget: jumpFail getJmpTarget].
	^CompletePrimitive
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genEnsureObjInRegNotForwarded: reg scratchReg: scratch [
	"Make sure that the object in reg is not forwarded.  By default there is
	 nothing to do.  Subclasses for memory managers that forward will override."
	<inline: true>
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genEnsureOopInRegNotForwarded: reg scratchReg: scratch [
	"Make sure that the oop in reg is not forwarded.  By default there is
	 nothing to do.  Subclasses for memory managers that forward will override."
	<inline: true>
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genEnsureOopInRegNotForwarded: reg scratchReg: scratch ifForwarder: fwdJumpTarget ifNotForwarder: nonFwdJumpTargetOrZero [
	"Make sure that the oop in reg is not forwarded.  By default there is
	 nothing to do.  Subclasses for memory managers that forward will override."
	<inline: true>
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genEnsureOopInRegNotForwarded: reg scratchReg: scratch jumpBackTo: instruction [
	"Make sure that the oop in reg is not forwarded.  By default there is
	 nothing to do.  Subclasses for memory managers that forward will override."
	<var: #instruction type: #'AbstractInstruction *'>
	<inline: true>
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genEnsureOopInRegNotForwarded: reg scratchReg: scratch updatingMw: offset r: baseReg [
	"Make sure that the oop in reg is not forwarded, updating the field at offset from baseReg.
	 By default there is nothing to do.  Subclasses for memory managers that forward will override."
	<inline: true>
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genEnsureOopInRegNotForwarded: reg scratchReg: scratch updatingSlot: index in: objReg [
	"Make sure that the oop in reg is not forwarded, updating the slot in objReg with the value."
	<inline: true>
	self flag: 'not safe unless there''s also a store check!!'.
	self assert: false.
	^self genEnsureOopInRegNotForwarded: reg
		scratchReg: scratch
		updatingMw: index * objectMemory wordSize + objectMemory baseHeaderSize
		r: objReg
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genFastPrimFail [
	<doNotGenerate>
	^cogit genFastPrimFail
]

{ #category : #'bytecode generator support' }
CogObjectRepresentation >> genGetActiveContextNumArgs: numArgs large: isLargeContext inBlock: isInBlock [
	"Get the active context into ReceiverResultReg, creating it if necessary."
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genGetFormatOf: srcReg into: destReg [
	"Get the format field of the object in srcReg into destReg.
	 srcReg may equal destReg."
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genGetInlineCacheClassTagFrom: sourceReg into: destReg forEntry: forEntry [
	"Extract the inline cache tag for the object in sourceReg into destReg. The inline cache tag
	 for a given object is the value loaded in inline caches to distinguish objects of different
	 classes. If forEntry is true answer the entry label at which control is to enter (cmEntryOffset).
	 If forEntry is false, control enters at the start."
	<returnTypeC: #'AbstractInstruction *'>
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genGetMethodHeaderOf: methodReg into: headerReg scratch: scratchReg [
	"Get the method header (first word) of a CompiledMethod into headerReg.
	 Deal with the method possibly being cogged."
	| jumpNotCogged |
	<var: #jumpNotCogged type: #'AbstractInstruction *'>
	cogit MoveMw: objectMemory baseHeaderSize r: methodReg R: headerReg.
	jumpNotCogged := self genJumpSmallInteger: headerReg scratchReg: scratchReg.
	cogit MoveMw: (cogit offset: CogMethod of: #methodHeader) r: headerReg R: headerReg.
	jumpNotCogged jmpTarget: cogit Label.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genGetNumSlotsOf: srcReg into: destReg [
	"Get the size in word-sized slots of the object in srcReg into destReg.
	 srcReg may equal destReg."
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genJumpImmediate: aRegister [
	"Generate a compare and branch to test if aRegister contains an immediate.
	 Answer the jump."
	<returnTypeC: #'AbstractInstruction *'>
	self subclassResponsibility
	
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genJumpIsSmallIntegerValue: aRegister scratch: scratchReg [
	"Generate a test for aRegister containing an integer value in the SmallInteger range, and a jump if so, answering the jump."
	<returnTypeC: #'AbstractInstruction *'>
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genJumpNotImmediate: aRegister [
	"Generate a compare and branch to test if aRegister contains a non-immediate.
	 Answer the jump."
	<returnTypeC: #'AbstractInstruction *'>
	self subclassResponsibility
	
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genJumpNotSmallInteger: aRegister [
	"Generate a compare and branch to test if aRegister contains other than a SmallInteger.
	 Answer the jump, or UnimplementedOperation if this cannot be done with a single register."
	<returnTypeC: #'AbstractInstruction *'>
	<inline: true>
	^cogit cCoerceSimple: UnimplementedOperation to: #'AbstractInstruction *'
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genJumpNotSmallInteger: aRegister scratchReg: scratch [
	"Generate a compare and branch to test if aRegister contains other than a SmallInteger.
	 Answer the jump.  Use scratch if required.  Subclasses will override if scratch is needed."
	<inline: true>
	^self genJumpNotSmallInteger: aRegister
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genJumpNotSmallIntegerInScratchReg: aRegister [
	"Generate a test for aRegister containing an integer value outside the SmallInteger range, and a jump if so, answering the jump."
	<returnTypeC: #'AbstractInstruction *'>
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genJumpNotSmallIntegerValue: aRegister scratch: scratchReg [
	"Generate a test for aRegister containing an integer value outside the SmallInteger range, and a jump if so, answering the jump."
	<returnTypeC: #'AbstractInstruction *'>
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genJumpNotSmallIntegersIn: aRegister and: bRegister scratch: scratchRegister [
	"Generate a compare and branch to test if aRegister and bRegister contains other than SmallIntegers,
	 i.e. don't branch if both aRegister and bRegister contain SmallIntegers.
	 Answer the jump.  Destroy scratchRegister if required."
	<returnTypeC: #'AbstractInstruction *'>
	<inline: true>
	cogit
		MoveR: aRegister R: scratchRegister;
		AndR: bRegister R: scratchRegister.
	^self genJumpNotSmallIntegerInScratchReg: scratchRegister
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genJumpSmallInteger: aRegister [
	"Generate a compare and branch to test if aRegister contains a SmallInteger.
	 Answer the jump, or UnimplementedOperation if this cannot be done with
	 a single register."
	<returnTypeC: #'AbstractInstruction *'>
	<inline: true>
	^cogit cCoerceSimple: UnimplementedOperation to: #'AbstractInstruction *'
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genJumpSmallInteger: aRegister scratchReg: scratch [
	"Generate a compare and branch to test if aRegister contains a SmallInteger.
	 Answer the jump.  Use scratch if required.  Subclasses will override if scratch is needed."
	<inline: true>
	^self genJumpSmallInteger: aRegister
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genLoadSlot: index sourceReg: sourceReg destReg: destReg [
	cogit
		MoveMw: index * objectMemory wordSize + objectMemory baseHeaderSize
		r: sourceReg
		R: destReg.
	^0
]

{ #category : #'bytecode generator support' }
CogObjectRepresentation >> genNewArrayOfSize: size initialized: initialized [
	"Generate a call to code that allocates a new Array of size.
	 The Array should be initialized with nils iff initialized is true.
	 The size arg is passed in SendNumArgsReg, the result
	 must come back in ReceiverResultReg."
	self subclassResponsibility
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveAdd [
	| jumpNotSI jumpOvfl |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpOvfl type: #'AbstractInstruction *'>
	cogit mclassIsSmallInteger ifFalse:
		[^UnimplementedPrimitive].
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	cogit MoveR: Arg0Reg R: ClassReg.
	jumpNotSI := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	self genRemoveSmallIntegerTagsInScratchReg: ClassReg.
	cogit AddR: ReceiverResultReg R: ClassReg.
	jumpOvfl := cogit JumpOverflow: 0.
	cogit MoveR: ClassReg R: ReceiverResultReg.
	cogit genPrimReturn.
	jumpOvfl jmpTarget: (jumpNotSI jmpTarget: cogit Label).
	^CompletePrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveAsCharacter [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveAsFloat [
	<option: #DPFPReg0>
	| jumpFailAlloc |
	<var: #jumpFailAlloc type: #'AbstractInstruction *'>
	cogit mclassIsSmallInteger ifFalse:
		[^UnimplementedPrimitive].
	cogit processorHasDoublePrecisionFloatingPointSupport ifFalse:
		[^UnimplementedPrimitive].
	cogit MoveR: ReceiverResultReg R: TempReg.
	self genConvertSmallIntegerToIntegerInReg: TempReg.
	cogit ConvertR: TempReg Rd: DPFPReg0.
	jumpFailAlloc := self
						genAllocFloatValue: DPFPReg0
						into: SendNumArgsReg
						scratchReg: ClassReg
						scratchReg: TempReg.
	cogit MoveR: SendNumArgsReg R: ReceiverResultReg.
	cogit genPrimReturn.
	jumpFailAlloc jmpTarget: cogit Label.
	^ CompletePrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveAt [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveAtPut [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveBitAnd [
	| jumpNotSI |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	cogit mclassIsSmallInteger ifFalse:
		[^UnimplementedPrimitive].
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	jumpNotSI := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	"Whether the SmallInteger tags are zero or non-zero, anding them together will preserve them."
	cogit AndR: Arg0Reg R: ReceiverResultReg.
	cogit genPrimReturn.
	jumpNotSI jmpTarget: cogit Label.
	^CompletePrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveBitOr [
	| jumpNotSI |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	cogit mclassIsSmallInteger ifFalse:
		[^UnimplementedPrimitive].
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	jumpNotSI := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	"Whether the SmallInteger tags are zero or non-zero, oring them together will preserve them."
	cogit OrR: Arg0Reg R: ReceiverResultReg.
	cogit genPrimReturn.
	jumpNotSI jmpTarget: cogit Label.
	^CompletePrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveBitShift [
	"rTemp := rArg0
	rClass := tTemp
	rTemp := rTemp & 1
	jz nonInt
	rClass >>= 1
	cmp 0,rClass
	jge neg
	cmp 31,rClass // numSmallIntegerBits, jge for sign
	jge tooBig
	rTemp := rReceiver
	rTemp <<= rClass
	rTemp >>= rClass (arithmetic)
	cmp rTemp,rReceiver
	jnz ovfl
	rReceiver := rReceiver - 1
	rReceiver := rReceiver <<= rClass
	rReceiver := rReceiver + 1
	ret
neg:
	rClass := 0 - rClass
	cmp 31,rClass // numSmallIntegerBits
	jge inRange
	rClass := 31
inRange
	rReceiver := rReceiver >>= rClass.
	rReceiver := rReceiver | smallIntegerTags.
	ret
ovfl
tooBig
nonInt:
	fail"
	| jumpNotSI jumpOvfl jumpNegative jumpTooBig jumpInRange |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpOvfl type: #'AbstractInstruction *'>
	<var: #jumpNegative type: #'AbstractInstruction *'>
	<var: #jumpTooBig type: #'AbstractInstruction *'>
	<var: #jumpInRange type: #'AbstractInstruction *'>
	cogit mclassIsSmallInteger ifFalse:
		[^UnimplementedPrimitive].
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	cogit MoveR: Arg0Reg R: ClassReg.
	jumpNotSI := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	self genConvertSmallIntegerToIntegerInReg: ClassReg.
	(cogit lastOpcode setsConditionCodesFor: JumpNegative) ifFalse:
		[cogit CmpCq: 0 R: ClassReg]. "N.B. FLAGS := ClassReg - 0"
	jumpNegative := cogit JumpNegative: 0.
	cogit CmpCq: self numSmallIntegerBits R: ClassReg. "N.B. FLAGS := ClassReg - numSmallIntegerBits"
	jumpTooBig := cogit JumpGreaterOrEqual: 0.
	cogit MoveR: ReceiverResultReg R: TempReg.
	cogit LogicalShiftLeftR: ClassReg R: TempReg.
	cogit ArithmeticShiftRightR: ClassReg R: TempReg.
	cogit CmpR: TempReg R: ReceiverResultReg. "N.B. FLAGS := RRReg - TempReg"
	jumpOvfl := cogit JumpNonZero: 0.
	self genRemoveSmallIntegerTagsInScratchReg: ReceiverResultReg.
	cogit LogicalShiftLeftR: ClassReg R: ReceiverResultReg.
	self genAddSmallIntegerTagsTo: ReceiverResultReg.
	cogit genPrimReturn.
	jumpNegative jmpTarget: (cogit NegateR: ClassReg).
	cogit CmpCq: self numSmallIntegerBits R: ClassReg. "N.B. FLAGS := ClassReg - numSmallIntegerBits"
	jumpInRange := cogit JumpLessOrEqual: 0.
	cogit MoveCq: self numSmallIntegerBits R: ClassReg.
	jumpInRange jmpTarget: (cogit ArithmeticShiftRightR: ClassReg R: ReceiverResultReg).
	self genClearAndSetSmallIntegerTagsIn: ReceiverResultReg.
	cogit genPrimReturn.
	jumpNotSI jmpTarget: (jumpTooBig jmpTarget: (jumpOvfl jmpTarget: cogit Label)).
	^CompletePrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveBitXor [
	| jumpNotSI |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	cogit mclassIsSmallInteger ifFalse:
		[^UnimplementedPrimitive].
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	jumpNotSI := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	"Clear one or the other tag so that xoring will preserve them."
	self genRemoveSmallIntegerTagsInScratchReg: Arg0Reg.
	cogit XorR: Arg0Reg R: ReceiverResultReg.
	cogit genPrimReturn.
	jumpNotSI jmpTarget: cogit Label.
	^CompletePrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveClass [
	| reg |
	reg := ReceiverResultReg.
	cogit methodNumArgs > 0 ifTrue:
		[cogit methodNumArgs > 1 ifTrue:
			[^UnimplementedPrimitive].
		 cogit genLoadArgAtDepth: 0 into: (reg := Arg0Reg)].
	(self
			genGetClassObjectOf: reg
			into: ReceiverResultReg
			scratchReg: TempReg
			instRegIsReceiver: reg = ReceiverResultReg) = BadRegisterSet ifTrue:
		[self
			genGetClassObjectOf: reg
			into: ClassReg
			scratchReg: TempReg
			instRegIsReceiver: reg = ReceiverResultReg.
		 cogit MoveR: ClassReg R: ReceiverResultReg].
	cogit genPrimReturn.
	^UnfailingPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveClosureValue [
	"Defer to the cogit for this one.  This is for two reasons:
	 a)	Cogit's version speeds up cull: et al by not calling the interpreter primitive if numArgs is wrong.
		Our convention for compiling the interpreter primitive call doesn't agree with this usage.
	b)	Cogit refuses to compile primitiveClosureValueNoContextSwitch until the blockNoContextSwitchOffset
		is known, and that isn't information the CogObjectRepresentation is privvy to."
	<doNotGenerate>
	^cogit genPrimitiveClosureValue
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveDiv [
	| jumpNotSI jumpIsSI jumpZero jumpExact jumpSameSign convert |
	<var: #convert type: #'AbstractInstruction *'>
	<var: #jumpIsSI type: #'AbstractInstruction *'>
	<var: #jumpZero type: #'AbstractInstruction *'>
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpExact type: #'AbstractInstruction *'>
	<var: #jumpSameSign type: #'AbstractInstruction *'>
	cogit processorHasDivQuoRemAndMClassIsSmallInteger ifFalse:
		[^UnimplementedPrimitive].
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	cogit MoveR: Arg0Reg R: ClassReg.
	cogit MoveR: Arg0Reg R: Arg1Reg.
	jumpNotSI := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	"We must shift away the tags, not just subtract them, so that the
	 overflow case doesn't actually overflow the machine instruction."
	self genConvertSmallIntegerToIntegerInReg: ClassReg.
	(cogit lastOpcode setsConditionCodesFor: JumpZero) ifFalse:
		[cogit CmpCq: 0 R: ClassReg].
	jumpZero := cogit JumpZero: 0.
	cogit MoveR: ReceiverResultReg R: TempReg.
	self genConvertSmallIntegerToIntegerInReg: TempReg.
	cogit DivR: ClassReg R: TempReg Quo: TempReg Rem: ClassReg.
	"If remainder is zero we must check for overflow."
	cogit CmpCq: 0 R: ClassReg.
	jumpExact := cogit JumpZero: 0.
	"If arg and remainder signs are different we must round down."
	cogit XorR: ClassReg R: Arg1Reg.
	(cogit lastOpcode setsConditionCodesFor: JumpZero) ifFalse:
		[cogit CmpCq: 0 R: Arg1Reg].
	jumpSameSign := cogit JumpGreaterOrEqual: 0.
	cogit SubCq: 1 R: TempReg.
	jumpSameSign jmpTarget: (convert := cogit Label).
	self genConvertIntegerToSmallIntegerInReg: TempReg.
	cogit MoveR: TempReg R: ReceiverResultReg.
	cogit genPrimReturn.
	"test for overflow; the only case is SmallInteger minVal // -1"
	jumpExact jmpTarget: cogit Label.
	jumpIsSI := self genJumpIsSmallIntegerValue: TempReg scratch: Arg1Reg.
	jumpIsSI jmpTarget: convert.
	jumpZero jmpTarget: (jumpNotSI jmpTarget: cogit Label).
	^CompletePrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveDivide [
	| jumpNotSI jumpZero jumpInexact jumpOverflow |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpZero type: #'AbstractInstruction *'>
	<var: #jumpInexact type: #'AbstractInstruction *'>
	<var: #jumpOverflow type: #'AbstractInstruction *'>
	cogit processorHasDivQuoRemAndMClassIsSmallInteger ifFalse:
		[^UnimplementedPrimitive].
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	cogit MoveR: Arg0Reg R: ClassReg.
	jumpNotSI := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	"We must shift away the tags, not just subtract them, so that the
	 overflow case doesn't actually overflow the machine instruction."
	self genConvertSmallIntegerToIntegerInReg: ClassReg.
	jumpZero := cogit JumpZero: 0.
	cogit MoveR: ReceiverResultReg R: TempReg.
	self genConvertSmallIntegerToIntegerInReg: TempReg.
	cogit DivR: ClassReg R: TempReg Quo: TempReg Rem: ClassReg.
	"If remainder is non-zero fail."
	cogit CmpCq: 0 R: ClassReg.
	jumpInexact := cogit JumpNonZero: 0.
	"test for overflow; the only case is SmallInteger minVal / -1"
	jumpOverflow := self genJumpNotSmallIntegerValue: TempReg scratch: Arg1Reg.
	self genConvertIntegerToSmallIntegerInReg: TempReg.
	cogit MoveR: TempReg R: ReceiverResultReg.
	cogit genPrimReturn.
	jumpOverflow jmpTarget: (jumpInexact jmpTarget: (jumpZero jmpTarget: (jumpNotSI jmpTarget: cogit Label))).
	^CompletePrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveEqual [
	^self 
		genSmallIntegerComparison: JumpZero
		orDoubleComparison: #JumpFPEqual:
		invert: false
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveFloatAdd [
	<option: #DPFPReg0>
	^self genDoubleArithmetic: AddRdRd preOpCheck: nil
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveFloatDivide [
	<option: #DPFPReg0>
	^self 
		genDoubleArithmetic: DivRdRd
		preOpCheck: #genDoubleFailIfZeroArgRcvr:arg:
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveFloatEqual [
	<option: #DPFPReg0>
	^self genDoubleComparison: #JumpFPEqual: invert: false
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveFloatGreaterOrEqual [
	<option: #DPFPReg0>
	^self genDoubleComparison: #JumpFPGreaterOrEqual: invert: false
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveFloatGreaterThan [
	<option: #DPFPReg0>
	^self genDoubleComparison: #JumpFPGreater: invert: false
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveFloatLessOrEqual [
	<option: #DPFPReg0>
	^self genDoubleComparison: #JumpFPGreaterOrEqual: invert: true
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveFloatLessThan [
	<option: #DPFPReg0>
	^self genDoubleComparison: #JumpFPGreater: invert: true
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveFloatMultiply [
	<option: #DPFPReg0>
	^self genDoubleArithmetic: MulRdRd preOpCheck: nil
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveFloatNotEqual [
	<option: #DPFPReg0>
	^self genDoubleComparison: #JumpFPNotEqual: invert: false
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveFloatSquareRoot [
	<option: #DPFPReg0>
	| jumpFailAlloc |
	<var: #jumpFailAlloc type: #'AbstractInstruction *'>
	cogit processorHasDoublePrecisionFloatingPointSupport ifFalse:
		[^UnimplementedPrimitive].
	self genGetDoubleValueOf: ReceiverResultReg into: DPFPReg0.
	cogit SqrtRd: DPFPReg0.
	jumpFailAlloc := self
						genAllocFloatValue: DPFPReg0
						into: SendNumArgsReg
						scratchReg: ClassReg
						scratchReg: TempReg.
	cogit MoveR: SendNumArgsReg R: ReceiverResultReg.
	cogit genPrimReturn.
	jumpFailAlloc jmpTarget: cogit Label.
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveFloatSubtract [
	<option: #DPFPReg0>
	^self genDoubleArithmetic: SubRdRd preOpCheck: nil
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveFullClosureValue [
	"Defer to the cogit for this one, to match the split for genPrimitiveClosureValue."
	<doNotGenerate>
	<option: #SistaV1BytecodeSet>
	^cogit genPrimitiveFullClosureValue
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveGreaterOrEqual [
	^self 
		genSmallIntegerComparison: JumpGreaterOrEqual
		orDoubleComparison: #JumpFPGreaterOrEqual:
		invert: false
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveGreaterThan [
	^self
		genSmallIntegerComparison: JumpGreater
		orDoubleComparison: #JumpFPGreater:
		invert: false
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveHashMultiply [
	<doNotGenerate>
	^cogit genPrimitiveHashMultiply
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveIdentical [
	^self genPrimitiveIdenticalOrNotIf: false
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveImmediateAsInteger [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveIntegerAt [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveIntegerAtPut [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLessOrEqual [
	^self
		genSmallIntegerComparison: JumpLessOrEqual
		orDoubleComparison: #JumpFPGreaterOrEqual:
		invert: true
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLessThan [
	^self
		genSmallIntegerComparison: JumpLess
		orDoubleComparison: #JumpFPGreater:
		invert: true
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadBoolean8FromBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadBoolean8FromExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadChar16FromBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadChar16FromExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadChar32FromBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadChar32FromExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadChar8FromBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadChar8FromExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadFloat32FromBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadFloat32FromExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadFloat64FromBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadFloat64FromExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadInt16FromBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadInt16FromExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadInt32FromBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadInt32FromExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadInt64FromBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadInt64FromExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadInt8FromBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadInt8FromExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadPointerFromBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadPointerFromExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadUInt16FromBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadUInt16FromExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadUInt32FromBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadUInt32FromExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadUInt64FromBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadUInt64FromExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadUInt8FromBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveLoadUInt8FromExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveMod [
	| jumpNotSI jumpZero jumpExact jumpSameSign |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpZero type: #'AbstractInstruction *'>
	<var: #jumpExact type: #'AbstractInstruction *'>
	<var: #jumpSameSign type: #'AbstractInstruction *'>
	cogit processorHasDivQuoRemAndMClassIsSmallInteger ifFalse:
		[^UnimplementedPrimitive].
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	cogit MoveR: Arg0Reg R: ClassReg.
	jumpNotSI := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	self genRemoveSmallIntegerTagsInScratchReg: ClassReg.
	jumpZero := cogit JumpZero: 0.
	cogit MoveR: ClassReg R: Arg1Reg.
	cogit MoveR: ReceiverResultReg R: TempReg.
	self genRemoveSmallIntegerTagsInScratchReg: TempReg.
	cogit DivR: ClassReg R: TempReg Quo: TempReg Rem: ClassReg.
	"If remainder is zero we're done."
	cogit CmpCq: 0 R: ClassReg.
	jumpExact := cogit JumpZero: 0.
	"If arg and remainder signs are different we must reflect around zero."
	cogit XorR: ClassReg R: Arg1Reg.
	(cogit lastOpcode setsConditionCodesFor: JumpZero) ifFalse:
		[cogit CmpCq: 0 R: Arg1Reg].
	jumpSameSign := cogit JumpGreaterOrEqual: 0.
	cogit XorR: ClassReg R: Arg1Reg.
	cogit AddR: Arg1Reg R: ClassReg.
	jumpSameSign jmpTarget: (jumpExact jmpTarget: cogit Label).
	self genSetSmallIntegerTagsIn: ClassReg.
	cogit MoveR: ClassReg R: ReceiverResultReg.
	cogit genPrimReturn.
	jumpZero jmpTarget: (jumpNotSI jmpTarget: cogit Label).
	^CompletePrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveMultiply [
	| jumpNotSI jumpOvfl |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpOvfl type: #'AbstractInstruction *'>
	(cogit processorHasMultiplyAndMClassIsSmallInteger) ifFalse:
		[^UnimplementedPrimitive].
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	cogit MoveR: Arg0Reg R: ClassReg.
	cogit MoveR: ReceiverResultReg R: Arg1Reg.
	jumpNotSI := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	self genConvertSmallIntegerToIntegerInReg: ClassReg.
	self genRemoveSmallIntegerTagsInScratchReg: Arg1Reg.
	cogit MulR: Arg1Reg R: ClassReg.
	jumpOvfl := cogit JumpMultiplyOverflow: 0.
	self genSetSmallIntegerTagsIn: ClassReg.
	cogit MoveR: ClassReg R: ReceiverResultReg.
	cogit genPrimReturn.
	jumpOvfl jmpTarget: (jumpNotSI jmpTarget: cogit Label).
	^CompletePrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveNew [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveNewMethod [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveNewWithArg [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveNotEqual [
	^self
		genSmallIntegerComparison: JumpNonZero
		orDoubleComparison: #JumpFPNotEqual:
		invert: false
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveNotIdentical [
	^self genPrimitiveIdenticalOrNotIf: true
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveObjectAt [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitivePerform [
	"Defer to the cogit for this one.  All the code is method-cache related."
	<doNotGenerate>
	^cogit genPrimitivePerform
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveQuo [
	| convert jumpNotSI jumpZero jumpIsSI jumpExact |
	<var: #convert type: #'AbstractInstruction *'>
	<var: #jumpIsSI type: #'AbstractInstruction *'>
	<var: #jumpZero type: #'AbstractInstruction *'>
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpExact type: #'AbstractInstruction *'>
	cogit processorHasDivQuoRemAndMClassIsSmallInteger ifFalse:
		[^UnimplementedPrimitive].
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	cogit MoveR: Arg0Reg R: ClassReg.
	jumpNotSI := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	"We must shift away the tags, not just subtract them, so that the
	 overflow case doesn't actually overflow the machine instruction."
	self genConvertSmallIntegerToIntegerInReg: ClassReg.
	(cogit lastOpcode setsConditionCodesFor: JumpZero) ifFalse:
		[cogit CmpCq: 0 R: ClassReg].
	jumpZero := cogit JumpZero: 0.
	cogit MoveR: ReceiverResultReg R: TempReg.
	self genConvertSmallIntegerToIntegerInReg: TempReg.
	cogit DivR: ClassReg R: TempReg Quo: TempReg Rem: ClassReg.
	"If remainder is zero we must check for overflow."
	cogit CmpCq: 0 R: ClassReg.
	jumpExact := cogit JumpZero: 0.
	convert := cogit Label.
	self genConvertIntegerToSmallIntegerInReg: TempReg.
	cogit MoveR: TempReg R: ReceiverResultReg.
	cogit genPrimReturn.
	jumpExact jmpTarget: cogit Label.
	jumpIsSI := self genJumpIsSmallIntegerValue: TempReg scratch: Arg1Reg.
	jumpIsSI jmpTarget: convert.
	jumpZero jmpTarget: (jumpNotSI jmpTarget: cogit Label).
	^CompletePrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveShallowCopy [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveSmallFloatAdd [
	<option: #Spur64BitMemoryManager>
	^self genSmallFloatArithmetic: AddRdRd preOpCheck: nil
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveSmallFloatDivide [
	<option: #Spur64BitMemoryManager>
	^self genSmallFloatArithmetic: DivRdRd preOpCheck: #genDoubleFailIfZeroArgRcvr:arg:
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveSmallFloatEqual [
	<option: #Spur64BitMemoryManager>
	^self genSmallFloatComparison: #JumpFPEqual: invert: false
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveSmallFloatGreaterOrEqual [
	<option: #Spur64BitMemoryManager>
	^self genSmallFloatComparison: #JumpFPGreaterOrEqual: invert: false
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveSmallFloatGreaterThan [
	<option: #Spur64BitMemoryManager>
	^self genSmallFloatComparison: #JumpFPGreater: invert: false
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveSmallFloatLessOrEqual [
	<option: #Spur64BitMemoryManager>
	^self genSmallFloatComparison: #JumpFPGreaterOrEqual: invert: true
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveSmallFloatLessThan [
	<option: #Spur64BitMemoryManager>
	^self genSmallFloatComparison: #JumpFPGreater: invert: true
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveSmallFloatMultiply [
	<option: #Spur64BitMemoryManager>
	^self genSmallFloatArithmetic: MulRdRd preOpCheck: nil
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveSmallFloatNotEqual [
	<option: #Spur64BitMemoryManager>
	^self genSmallFloatComparison: #JumpFPNotEqual: invert: false
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveSmallFloatSquareRoot [
	<option: #Spur64BitMemoryManager>
	| jumpFailAlloc jumpNegative |
	<var: #jumpFailAlloc type: #'AbstractInstruction *'>
	<var: #jumpNegative type: #'AbstractInstruction *'>
	self genGetSmallFloatValueOf: ReceiverResultReg scratch: SendNumArgsReg into: DPFPReg0.
	cogit
		XorRd: DPFPReg1 Rd: DPFPReg1; "+0.0 is all zeros"
		CmpRd: DPFPReg0 Rd: DPFPReg1.
	jumpNegative := cogit JumpFPGreater: 0.
	cogit SqrtRd: DPFPReg0.
	jumpFailAlloc := self
						genAllocFloatValue: DPFPReg0
						into: SendNumArgsReg
						scratchReg: ClassReg
						scratchReg: TempReg.
	cogit MoveR: SendNumArgsReg R: ReceiverResultReg.
	cogit genPrimReturn.
	jumpNegative jmpTarget: (jumpFailAlloc jmpTarget: cogit Label).
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveSmallFloatSubtract [
	<option: #Spur64BitMemoryManager>
	^self genSmallFloatArithmetic: SubRdRd preOpCheck: nil
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreBoolean8IntoBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreBoolean8IntoExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreChar16IntoBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreChar16IntoExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreChar32IntoBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreChar32IntoExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreChar8IntoBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreChar8IntoExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreFloat32IntoBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreFloat32IntoExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreFloat64IntoBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreFloat64IntoExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreInt16IntoBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreInt16IntoExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreInt32IntoBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreInt32IntoExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreInt64IntoBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreInt64IntoExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreInt8IntoBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreInt8IntoExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStorePointerIntoBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStorePointerIntoExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreUInt16IntoBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreUInt16IntoExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreUInt32IntoBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreUInt32IntoExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreUInt64IntoBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreUInt64IntoExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreUInt8IntoBytes [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStoreUInt8IntoExternalAddress [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStringAtPut [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStringCompareWith [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveStringReplace [
	"subclasses override if they can"
	^UnimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genPrimitiveSubtract [
	| jumpNotSI jumpOvfl |
	<var: #jumpNotSI type: #'AbstractInstruction *'>
	<var: #jumpOvfl type: #'AbstractInstruction *'>
	cogit mclassIsSmallInteger ifFalse:
		[^UnimplementedPrimitive].
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	jumpNotSI := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	cogit MoveR: ReceiverResultReg R: TempReg.
	cogit SubR: Arg0Reg R: TempReg.
	jumpOvfl := cogit JumpOverflow: 0.
	self genAddSmallIntegerTagsTo: TempReg.
	cogit MoveR: TempReg R: ReceiverResultReg.
	cogit genPrimReturn.
	jumpOvfl jmpTarget: (jumpNotSI jmpTarget: cogit Label).
	^CompletePrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genQuickReturnConst [
	<doNotGenerate>
	^cogit genQuickReturnConst
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genQuickReturnInstVar [
	<doNotGenerate>
	^cogit genQuickReturnInstVar
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genQuickReturnSelf [
	<doNotGenerate>
	^cogit genQuickReturnSelf
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genRemoveSmallIntegerTagsInScratchReg: scratchReg [
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genSetSmallIntegerTagsIn: scratchReg [
	self subclassResponsibility
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genSmallIntegerComparison: jumpOpcode [
	| jumpFail jumpTrue |
	<var: #jumpFail type: #'AbstractInstruction *'>
	<var: #jumpTrue type: #'AbstractInstruction *'>
	cogit mclassIsSmallInteger ifFalse:
		[^UnimplementedPrimitive].
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	jumpFail := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	cogit CmpR: Arg0Reg R: ReceiverResultReg. "N.B. FLAGS := RRReg - Arg0Reg"
	jumpTrue := cogit genConditionalBranch: jumpOpcode operand: 0.
	cogit genMoveFalseR: ReceiverResultReg.
	cogit genPrimReturn.
	jumpTrue jmpTarget: (cogit genMoveTrueR: ReceiverResultReg).
	cogit genPrimReturn.
	jumpFail jmpTarget: cogit Label.
	^CompletePrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genSmallIntegerComparison: jumpOpcode orDoubleComparison: jumpFPOpcodeGenerator invert: invertComparison [
	"Stack looks like
		return address"
	| jumpNonInt jumpFail jumpCond r |
	<var: #jumpFPOpcodeGenerator declareC: 'AbstractInstruction * NoDbgRegParms (*jumpFPOpcodeGenerator)(void *)'>
	<var: #jumpNonInt type: #'AbstractInstruction *'>
	<var: #jumpCond type: #'AbstractInstruction *'>
	<var: #jumpFail type: #'AbstractInstruction *'>
	r := self genSmallIntegerComparison: jumpOpcode.
	r < 0 ifTrue:
		[^r].
	self cppIf: (self defined: #DPFPReg0) ifTrue:
	"Fall through on non-SmallInteger argument.  Argument may be a Float : let us check or fail"
	"If we are compiling in a platform where the only immediate values are smallintegers, then at this point we know we have a non-immediate (since it was tested before).
	Otherwise, check if this is an immediate value or not. If it is immediate (e.g., a character) then just jump to the end."
	[self smallIntegerIsOnlyImmediateType ifFalse:
		[jumpNonInt := self genJumpImmediate: Arg0Reg].
	self genGetCompactClassIndexNonImmOf: Arg0Reg into: SendNumArgsReg.
	self genCmpClassFloatCompactIndexR: SendNumArgsReg.
	jumpFail := cogit JumpNonZero: 0.

	"It was a Float, so convert the receiver to double and perform the operation"
	self genConvertSmallIntegerToIntegerInReg: ReceiverResultReg.
	cogit ConvertR: ReceiverResultReg Rd: DPFPReg0.
	self genGetDoubleValueOf: Arg0Reg into: DPFPReg1.
	invertComparison "May need to invert for NaNs"
		ifTrue: [cogit CmpRd: DPFPReg0 Rd: DPFPReg1]
		ifFalse: [cogit CmpRd: DPFPReg1 Rd: DPFPReg0].
	jumpCond := cogit perform: jumpFPOpcodeGenerator with: 0. "FP jumps are a little weird"
	cogit genMoveFalseR: ReceiverResultReg.
	cogit genPrimReturn.
	jumpCond jmpTarget: (cogit genMoveTrueR: ReceiverResultReg).
	cogit genPrimReturn.

	self smallIntegerIsOnlyImmediateType
		ifTrue: [jumpFail jmpTarget: cogit Label]
		ifFalse: [jumpNonInt jmpTarget: (jumpFail jmpTarget: cogit Label)]].
	^CompletePrimitive
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genStoreSourceReg: sourceReg slotIndex: index destReg: destReg scratchReg: scratchReg inFrame: inFrame [
	<inline: true>
	self 
		cppIf: IMMUTABILITY
		ifTrue:
			[ ^ self 
				genStoreWithImmutabilityCheckSourceReg: sourceReg 
				slotIndex: index 
				destReg: destReg 
				scratchReg: scratchReg 
				needsStoreCheck: true 
				needRestoreRcvr: false "RcvrResultReg doesn't need to be live across the instructions" ]
		ifFalse: 
			[ ^ self 
				genStoreSourceReg: sourceReg 
				slotIndex: index 
				destReg: destReg 
				scratchReg: scratchReg 
				inFrame: inFrame 
				needsStoreCheck: true ]
]

{ #category : #initialization }
CogObjectRepresentation >> generateObjectRepresentationTrampolines [
	"Do the store check.  Answer the argument for the benefit of the code generator;
	 ReceiverResultReg may be caller-saved and hence smashed by this call.  Answering
	 it allows the code generator to reload ReceiverResultReg cheaply."
	self subclassResponsibility
]

{ #category : #'bytecode generator support' }
CogObjectRepresentation >> getActiveContextAllocatesInMachineCode [
	"subclasses override if they want, and will have SendNumArgsReg and ClassReg
	 available in addition to ReceiverResultReg and TempReg if they do."
	^false
]

{ #category : #testing }
CogObjectRepresentation >> hasSpurMemoryManagerAPI [
	^false
]

{ #category : #'in-line cacheing' }
CogObjectRepresentation >> illegalClassTag [
	"Answer a class tag that will fail for every object."
	self subclassResponsibility
]

{ #category : #'in-line cacheing' }
CogObjectRepresentation >> inlineCacheTagForClass: classOop [
	"Answer the relevant inline cache tag for a class.
	 c.f. inlineCacheTagForInstance:"
	self subclassResponsibility
]

{ #category : #'in-line cacheing' }
CogObjectRepresentation >> inlineCacheTagForInstance: oop [
	"Answer the relevant inline cache tag for an instance.
	 c.f. getInlineCacheClassTagFrom:into: & inlineCacheTagForClass:"
	^self subclassResponsibility
]

{ #category : #'in-line cacheing' }
CogObjectRepresentation >> inlineCacheTagIsYoung: cacheTag [
	^self subclassResponsibility
]

{ #category : #'in-line cacheing' }
CogObjectRepresentation >> inlineCacheTagsMayBeObjects [
	<inline: true>
	^self subclassResponsibility
]

{ #category : #testing }
CogObjectRepresentation >> isImmediate: oop [
	<doNotGenerate>
	^objectMemory isImmediate: oop
]

{ #category : #testing }
CogObjectRepresentation >> isSmallIntegerTagNonZero [
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> isUnannotatableConstant: simStackEntry [
	<inline: true>
	<var: 'simStackEntry' type: #'CogSimStackEntry *'>
	^simStackEntry type = SSConstant 
	  and: [(objectMemory isImmediate: simStackEntry constant)
		or: [(self shouldAnnotateObjectReference: simStackEntry constant) not]]
]

{ #category : #'garbage collection' }
CogObjectRepresentation >> markAndTraceCacheTagLiteral: literal in: cogMethodOrNil atpc: address [
	"Mark and trace a literal in an inline cache preceding address in cogMethodOrNil.
	 Answer if code was modified."
	<var: #cogMethodOrNil type: #'CogMethod *'>
	<var: #address type: #usqInt>
	self subclassResponsibility
]

{ #category : #'garbage collection' }
CogObjectRepresentation >> markAndTraceLiteral: literal [
	self subclassResponsibility
]

{ #category : #'garbage collection' }
CogObjectRepresentation >> markAndTraceLiteral: literal in: cogMethod at: address [
	"Mark and trace a literal in a sqInt variable of cogMethod."
	<var: #cogMethod type: #'CogMethod *'>
	<var: #address type: #'sqInt *'>
	self subclassResponsibility
]

{ #category : #'garbage collection' }
CogObjectRepresentation >> markAndTraceLiteral: literal in: cogMethodOrNil atpc: address [
	"Mark and trace a literal in a machine code instruction preceding address in cogMethodOrNil.
	 Answer if code was modified."
	<var: #cogMethodOrNil type: #'CogMethod *'>
	<var: #address type: #usqInt>
	self subclassResponsibility
]

{ #category : #'garbage collection' }
CogObjectRepresentation >> markAndTraceLiteralIfYoung: literal [
	self subclassResponsibility
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> maybeCompileRetry: retryInst onPrimitiveFail: primIndex primPropertyFlags: flags [
	<var: #retryInst type: #'AbstractInstruction *'>
	"Object representations with lazy forwarding will want to check for
	 forwarding pointers on primitive failure and retry the primitive if found.
	 By default do nothing."
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> maybeCompileRetryOnPrimitiveFail: primIndex [
	"Object representations with lazy forwarding will want to check for
	 forwarding pointers on primitive failure and retry the primitive if found.
	 By default do nothing."
	<inline: true>
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> maybeGenConvertIfSmallFloatIn: oopReg scratchReg: scratch into: dpReg andJumpTo: targetInst [
	"If the receiver supports immediate floats then generate a test for a smallFloat in  oopReg,
	 converting it to the float value in dpReg and jumping to targetInst.  Otherwise do nothing."
	<var: 'targetInst' type: #'AbstractInstruction *'>
	^0
]

{ #category : #initialization }
CogObjectRepresentation >> maybeGenerateSelectorIndexDereferenceRoutine [
	"If required, generate the routine that converts selector indices into selector objects.
	 If it exists, it is called from the send trampolines.
	 If the selector index is negative, convert it into a positive index into the
	 special selectors array and index that.  Otherwise, index the current method.
	 This is only required on 64-bit platforms."
]

{ #category : #'sista support' }
CogObjectRepresentation >> maybeMarkCounters: theCounters [
	"In SIsta Spur counters are held on the heap in pinned objects which must be marked
	 to avoid them being garbage collected.  This is the hook through which that happens.
	 By default, do nothing."
	<var: #theCounters type: #usqInt>
	<inline: true>
]

{ #category : #compilation }
CogObjectRepresentation >> maybeNoteDescriptor: descriptor blockStart: blockStart [
	"A hook for the object representation to set state in a blockStart during scanBlock:.
	 By default do nothing.  Subclasses that need to do something special will override."
	<var: #blockStart type: #'BlockStart *'>
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<inline: true>
]

{ #category : #'method cacheing' }
CogObjectRepresentation >> maybeShiftClassTagRegisterForMethodCacheProbe: classTagReg [
	"If required, generate a shift of the register containing the class tag in a method cache probe.
	 By default this is a no-op.  Subclasses redefine as required."

	^0
]

{ #category : #'sista support' }
CogObjectRepresentation >> numCountersFor: theCounters [
	<var: #counters type: #usqInt>
	self subclassResponsibility
]

{ #category : #'calling convention' }
CogObjectRepresentation >> numRegArgs [
	"Define how many register arguments a StackToRegisterMappingCogit can and should use
	 with the receiver.  The value must be 0, 1 or 2.  Note that a SimpleStackBasedCogit always
	 has 0 register args (although the receiver is passed in a register).  The method must
	 be inlined in CoInterpreter, and dead code eliminated so that the register-popping
	 enilopmarts such as enterRegisterArgCogMethod:at:receiver: do not have to be
	 implemented in SimpleStackBasedCogit."
	<api>
	<option: #StackToRegisterMappingCogit>
	<inline: true>
	self subclassResponsibility
]

{ #category : #'sista support' }
CogObjectRepresentation >> resetCountersIn: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	<api>
	self subclassResponsibility
]

{ #category : #'calling convention' }
CogObjectRepresentation >> selectorIndexDereferenceRoutine [
	"If the object representation is 64-bits, selectors must be accessed via indices in the inline caches.
	 Answer the routine that will map from indices to selector objects if so, otherwise nil."
	^nil
]

{ #category : #initialization }
CogObjectRepresentation >> setCogit: aCogit methodZone: aMethodZone [
	<doNotGenerate>
	cogit := aCogit.
	methodZone := aMethodZone.
	coInterpreter := aCogit coInterpreter.
	objectMemory := (coInterpreter isKindOf: StackInterpreter)
						ifTrue: [coInterpreter objectMemory]
						ifFalse: [coInterpreter]
]

{ #category : #testing }
CogObjectRepresentation >> smallIntegerIsOnlyImmediateType [
	self subclassResponsibility
]

{ #category : #'debug support' }
CogObjectRepresentation >> validInlineCacheTag: classIndexOrTagPattern [
	self subclassResponsibility
]

{ #category : #'sista support' }
CogObjectRepresentation >> valueOfAssociation: association [
	self subclassResponsibility
]

{ #category : #accessing }
CogObjectRepresentation >> wordSize [
	<doNotGenerate>
	^objectMemory wordSize
]
