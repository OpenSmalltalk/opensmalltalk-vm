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
		'ceStoreCheckTrampoline'
	],
	#pools : [
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

{ #category : #translation }
CogObjectRepresentation class >> typeForSelf [
	^#implicit
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
	<inline: true>
	^false
]

{ #category : #'garbage collection' }
CogObjectRepresentation >> checkValidObjectReference: anOop [
	^(objectMemory isImmediate: anOop) not
	   and: [(objectMemory heapMapAtWord: (self pointerForOop: anOop)) ~= 0]
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
CogObjectRepresentation >> genCmpClassFloatCompactIndexR: reg [
	^cogit CmpCq: ClassFloatCompactIndex R: reg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genCmpClassMethodContextCompactIndexR: reg [
	^cogit CmpCq: ClassMethodContextCompactIndex R: reg
]

{ #category : #'bytecode generator support' }
CogObjectRepresentation >> genCreateClosureAt: bcpc numArgs: numArgs numCopied: numCopied contextNumArgs: ctxtNumArgs large: isLargeCtxt inBlock: isInBlock [
	"Create a closure with the given startpc, numArgs and numCopied
	 within a context with ctxtNumArgs, large if isLargeCtxt that is in a
	 block if isInBlock.  If numCopied > 0 pop those values off the stack."
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genEnsureObjInRegNotForwarded: reg scratchReg: scratch [
	"Make sure that the object in reg is not forwarded.  By default there is
	 nothing to do.  Subclasses for memory managers that forward will override."
	<inline: true>
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genEnsureObjInRegNotForwarded: reg scratchReg: scratch updatingMw: offset r: baseReg [
	"Make sure that the non-immediate oop in reg is not forwarded, updating the field
	 at offset from baseReg.  By default there is nothing to do.  Subclasses for memory
	 managers that forward will override."
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
CogObjectRepresentation >> genGetNumSlotsOf: srcReg into: destReg [
	"Get the size in word-sized slots of the object in srcReg into destReg.
	 srcReg may equal destReg."
	self subclassResponsibility
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genInnerPrimitiveAsCharacter: retNOffset inReg: reg [
	"subclasses override if they can"
	^cogit unimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genInnerPrimitiveAtPut: retNoffset [
	"subclasses override if they can"
	^cogit unimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genInnerPrimitiveCharacterValue: retNOffset [
	"subclasses override if they can"
	^cogit unimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genInnerPrimitiveMirrorNew: retNoffset [
	<option: #NewspeakVM>
	"subclasses override if they can"
	^cogit unimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genInnerPrimitiveMirrorNewWithArg: retNoffset [
	<option: #NewspeakVM>
	"subclasses override if they can"
	^cogit unimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genInnerPrimitiveNew: retNoffset [
	"subclasses override if they can"
	^cogit unimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genInnerPrimitiveNewMethod: retNoffset [
	"subclasses override if they can"
	^cogit unimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genInnerPrimitiveNewWithArg: retNoffset [
	"subclasses override if they can"
	^cogit unimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genInnerPrimitiveStringAtPut: retNoffset [
	"subclasses override if they can"
	^cogit unimplementedPrimitive
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genJumpImmediate: aRegister [
	"Generate a compare and branch to test if aRegister contains an immediate.
	 Answer the jump."
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
CogObjectRepresentation >> genJumpSmallInteger: aRegister [
	"Generate a compare and branch to test if aRegister contains a SmallInteger.
	 Answer the jump, or UnimplementedOperation if this cannot be done with
	 a single register."
	<returnTypeC: #'AbstractInstruction *'>
	<inline: true>
	^cogit cCoerceSimple: UnimplementedOperation to: #'AbstractInstruction *'
]

{ #category : #'bytecode generator support' }
CogObjectRepresentation >> genNewArrayOfSize: size initialized: initialized [
	"Generate a call to code that allocates a new Array of size.
	 The Array should be initialized with nils iff initialized is true.
	 The size arg is passed in SendNumArgsReg, the result
	 must come back in ReceiverResultReg."
	self subclassResponsibility
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
	^ simStackEntry type = SSConstant 
		and: [(self shouldAnnotateObjectReference: simStackEntry constant) not ]
]

{ #category : #'garbage collection' }
CogObjectRepresentation >> markAndTraceCacheTagLiteral: literal in: cogMethodOrNil atpc: address [
	"Mark and trace a literal in an inline cache preceeding address in cogMethodOrNil.
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
	"Mark and trace a literal in a machine code instruction preceeding address in cogMethodOrNil.
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
CogObjectRepresentation >> maybeCompileRetry: retryInst onPrimitiveFail: primIndex [
	<var: #retryInst type: #'AbstractInstruction *'>
	"Object representations with lazy forwarding will want to check for
	 forwarding pointers on primitive failure and retry the primitive if found.
	 By default do nothing."
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> maybeCompileRetry: retryInst onPrimitiveFail: primIndex primPropertyFlags: flags [
	<var: #retryInst type: #'AbstractInstruction *'>
	"Object representations with lazy forwarding will want to check for
	 forwarding pointers on primitive failure and retry the primitive if found.
	 By default do nothing."
]

{ #category : #'sista support' }
CogObjectRepresentation >> maybeMarkCounters: theCounters [
	"In SIsta Spur counters are held on the heap in pinned objects which must be marked
	 to avoid them being garbage collected.  This is the hook through which that happens.
	 By default, do nothing."
	<var: #theCounters type: #usqInt>
	<inline: true>
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
