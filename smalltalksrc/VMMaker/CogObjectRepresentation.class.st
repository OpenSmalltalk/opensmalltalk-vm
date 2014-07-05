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
		'CogMethodConstants',
		'CogRTLOpcodes',
		'VMBasicConstants',
		'VMObjectIndices',
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

{ #category : #'in-line cacheing' }
CogObjectRepresentation >> canLinkToYoungClasses [
	^self subclassResponsibility
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
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genEnsureOopInRegNotForwarded: reg scratchReg: scratch [
	"Make sure that the oop in reg is not forwarded.  By default there is
	 nothing to do.  Subclasses for memory managers that forward will override."
	^0
]

{ #category : #'bytecode generator support' }
CogObjectRepresentation >> genGetActiveContextNumArgs: numArgs large: isLargeContext inBlock: isInBlock [
	"Get the active context into ReceiverResultReg, creating it if necessary."
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
	ceStoreCheckTrampoline := cogit
									genTrampolineFor: #ceStoreCheck:
									called: 'ceStoreCheckTrampoline'
									arg: ReceiverResultReg
									result: cogit returnRegForStoreCheck
]

{ #category : #'bytecode generator support' }
CogObjectRepresentation >> getActiveContextAllocatesInMachineCode [
	"subclasses override if they want, and will have SendNumArgsReg and ClassReg
	 available in addition to ReceiverResultReg and TempReg if they do."
	^false
]

{ #category : #'in-line cacheing' }
CogObjectRepresentation >> inlineCacheTagForInstance: oop [
	"c.f. getInlineCacheClassTagFrom:into:"
	^self subclassResponsibility
]

{ #category : #'in-line cacheing' }
CogObjectRepresentation >> inlineCacheTagIsYoung: cacheTag [
	^self subclassResponsibility
]

{ #category : #'in-line cacheing' }
CogObjectRepresentation >> inlineCacheTagsMayBeObjects [
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

{ #category : #'garbage collection' }
CogObjectRepresentation >> markAndTraceLiteral: literal [
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

{ #category : #'sista support' }
CogObjectRepresentation >> maybeMarkCounters: theCounters [
	"In SIsta Spur counters are held on the heap in pinned objects which must be marked
	 to avoid them being garbage collected.  This is the hook through which that happens.
	 By default, do nothing."
	<var: #counters type: #usqInt>
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
