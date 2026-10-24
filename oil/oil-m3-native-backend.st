"Oil Milestone 3: the native back end of the Oil optimizing JIT, its bailout stubs and the deoptimizer.
 File in after oil-m1-profiling-cogit.st and image/oil/{OilConstants,OilBytecodeScanner,OilCompiler,OilCompilerBackend,OilCompilerPass2}.st (then oil-m4-pass2.st).

 - ProfilingCogit drives the compilation of an Oil method (oilCompile:receiverClass: runs Pass 1, oilGenerate: runs
   Pass 3 and builds the CogMethod and its deoptimization metadata) and owns ceOilBailoutTrampoline.
 - CoInterpreter>>ceOilBailout: is the deoptimizer: on a failed guard it either unforwards and resumes the machine code
   (fast path), or rebuilds the interpreter frames of the method and of everything inlined into it at the guard,
   rematerializing the closures and temp vectors Oil dissolved, and continues in the interpreter.
 - primitiveOilCompile, primitiveOilSetSelectors and primitiveOilMethodInfo are the image's interface.
 Author: cb."!

(CoInterpreter sharedPools includes: OilConstants) ifFalse:
	[CoInterpreter addSharedPool: OilConstants]!

(CogObjectRepresentationFor64BitSpur sharedPools includes: OilConstants) ifFalse:
	[CogObjectRepresentationFor64BitSpur addSharedPool: OilConstants]!

(ProfilingCogit sharedPools includes: OilConstants) ifFalse:
	[ProfilingCogit addSharedPool: OilConstants]!

!Cogit methodsFor: '*Cogit-Oil' stamp: 'cb 10/24/2026 15:00'!
isOilMethod: cogMethod
	"Answer whether cogMethod was compiled by the Oil optimizing JIT (see ProfilingCogit).
	 Oil methods' machine code does not correspond to their bytecodes, so the interpreter must not
	 map bytecode pcs into them."
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	^false! !

!CogBlockMethod methodsFor: '*Cogit-Oil' stamp: 'cb 10/24/2026 18:00'!
cmUnusedFlag
	"Oil methods: whether Oil set the large context bit of the method header (see ProfilingCogit>>oilGenerateCogMethod)."
	^cmUnusedFlag! !

!CogBlockMethod methodsFor: '*Cogit-Oil' stamp: 'cb 10/24/2026 18:00'!
cmUnusedFlag: aValue
	^cmUnusedFlag := aValue! !

!CogObjectRepresentationForSpur methodsFor: '*Cogit-Oil' stamp: 'cb 10/24/2026 15:00'!
oilGenStoreCheckTrampolineCall
	"The slow path of an Oil store check: remember the object in ReceiverResultReg."
	<option: #ProfilingCogit>
	^cogit CallRT: ceStoreCheckTrampoline! !

!ProfilingCogit methodsFor: 'initialization' stamp: 'cb 10/24/2026 19:15'!
defaultCogCodeSize
	"With Oil, allocate at least 4 MB: 2 MB for baseline Cogit machine code and 2 MB for Oil methods."
	<api>
	^4 * 1024 * 1024! !

!ProfilingCogit methodsFor: 'initialization' stamp: 'cb 10/24/2026 15:00'!
initialize
	super initialize.
	oilTripLog := 0.
	oilSelectors := 0.
	oilExtraSelectors := 0.
	cogMethodSurrogateClass := (objectMemory ifNil: [self class objectMemoryClass]) wordSize = 4
										ifTrue: [CogSistaMethodSurrogate32]
										ifFalse: [CogSistaMethodSurrogate64]! !

!ProfilingCogit methodsFor: 'initialization' stamp: 'cb 10/24/2026 15:00'!
generateRunTimeTrampolines
	"Add the trampoline called when a trip counter reaches zero (it passes the kind of site, OilTripBackJump or
	 OilTripBlockEntry, in SendNumArgsReg to ceOilTrip:, and preserves ReceiverResultReg, which may hold self),
	 and the trampoline called by the bailout sequence of Oil methods (it passes the deopt site index in
	 SendNumArgsReg to ceOilBailout:, which answers the address to resume at in TempReg, unless it deoptimizes,
	 in which case it does not return)."
	super generateRunTimeTrampolines.
	"Let large (e.g. parser) methods get machine code, hence inline caches for Oil (the default limit is 60 literals)."
	coInterpreter oilRaiseMaxLiteralCountForCompile.
	ceOilTripTrampoline := self genTrampolineFor: #ceOilTrip:
								called: 'ceOilTripTrampoline'
								arg: SendNumArgsReg
								regsToSave: (self registerMaskFor: ReceiverResultReg).
	ceOilBailoutTrampoline := self genTrampolineFor: #ceOilBailout:
								called: 'ceOilBailoutTrampoline'
								arg: SendNumArgsReg
								result: TempReg! !


!ProfilingCogit methodsFor: 'oil code generation' stamp: 'cb 10/24/2026 15:00'!
oilGenBailoutCall
	"See OilCompiler>>genBailoutStubs."
	^self CallRT: ceOilBailoutTrampoline! !

!ProfilingCogit methodsFor: 'oil code generation' stamp: 'cb 10/24/2026 15:00'!
oilGenStoreCheckCall
	^objectRepresentation oilGenStoreCheckTrampolineCall! !

!ProfilingCogit methodsFor: 'oil code generation' stamp: 'cb 10/24/2026 15:00'!
oilGenJumpRemembered: objReg scratch: scratchReg
	<returnTypeC: #'AbstractInstruction *'>
	^objectRepresentation genCheckRememberedBitOf: objReg scratch: scratchReg! !

!ProfilingCogit methodsFor: 'oil code generation' stamp: 'cb 10/24/2026 15:00'!
oilGenGetNumSlotsOf: srcReg into: destReg
	^objectRepresentation genGetNumSlotsOf: srcReg into: destReg! !

!ProfilingCogit methodsFor: 'oil code generation' stamp: 'cb 10/24/2026 18:00'!
oilGenGetNumBytesOf: srcReg into: destReg
	"The number of bytes of the byte object in srcReg (clobbers TempReg)."
	^objectRepresentation genGetNumBytesOf: srcReg into: destReg! !

!ProfilingCogit methodsFor: 'oil code generation' stamp: 'cb 10/24/2026 17:30'!
oilGenStoreHeader: header into: objReg scratch: scratchReg
	"Store the 64-bit header of a new object (see OilCompiler>>genAllocate:header:site:)."
	^objectRepresentation genStoreHeader: header intoNewInstance: objReg using: scratchReg! !

!ProfilingCogit methodsFor: 'oil code generation' stamp: 'cb 10/24/2026 17:30'!
oilGenGetActiveContextInto: destReg
	"Get the context of the current (Oil, i.e. method) frame into destReg, marrying the frame if necessary, through the
	 baseline JIT's active context trampolines (which clobber the caller saved registers)."
	objectRepresentation
		genGetActiveContextNumArgs: methodOrBlockNumArgs
		large: true "see oilGenerateCogMethod"
		inBlock: 0.
	destReg ~= ReceiverResultReg ifTrue:
		[self MoveR: ReceiverResultReg R: destReg].
	^0! !

!ProfilingCogit methodsFor: 'oil code generation' stamp: 'cb 10/24/2026 15:00'!
oilGenReturnFrom: numArgs
	"Tear down the frame and return, popping the receiver and arguments (the result is in ReceiverResultReg)."
	self MoveR: FPReg R: SPReg.
	self PopR: FPReg.
	backEnd hasLinkRegister ifTrue:
		[self PopR: LinkReg].
	self RetN: numArgs + 1 * objectMemory wordSize! !

!ProfilingCogit methodsFor: 'oil code generation' stamp: 'cb 10/24/2026 15:00'!
oilGenSend: selectorIndex numArgs: numArgs super: isSuper
	"An uninlined send from an Oil method, linked by the usual inline cache machinery: the receiver is in
	 ReceiverResultReg and the arguments in registers or on the stack (see OilCompiler>>genCallAt:site:).
	 c.f. genMarshalledSend:numArgs:sendTable:"
	| sendTable annotation |
	<var: #sendTable type: #'sqInt *'>
	sendTable := isSuper ifTrue: [superSendTrampolines] ifFalse: [ordinarySendTrampolines].
	annotation := isSuper ifTrue: [IsSuperSend] ifFalse: [IsSendCall].
	isSuper ifTrue: "Deal with stale super sends; see SpurMemoryManager's class comment."
		[objectRepresentation genEnsureOopInRegNotForwarded: ReceiverResultReg scratchReg: TempReg].
	numArgs >= (NumSendTrampolines - 1) ifTrue:
		[self MoveCq: numArgs R: SendNumArgsReg].
	selectorIndex >= OilExtraSelectorBase
		ifTrue: [self MoveUniqueC32: selectorIndex R: ClassReg] "an index into the Oil selector table"
		ifFalse:
			[self genLoadInlineCacheWithSelector: selectorIndex.
			 maxLitIndex := maxLitIndex max: selectorIndex].
	(self Call: (sendTable at: (numArgs min: NumSendTrampolines - 1))) annotation: annotation! !

!ProfilingCogit methodsFor: 'oil code generation' stamp: 'cb 10/24/2026 15:00'!
oilCompileFrameBuild
	"Build an ordinary machine code frame, with the method's temps, and the stack overflow check (also the event
	 check), exactly like SimpleStackBasedCogit>>compileFrameBuild: the CoInterpreter builds such frames itself
	 (activateNewCogMethod:inInterpreter:) and enters them at the stack check.  The home slots of the virtual
	 registers are pushed by OilCompiler>>generateNativeCode, after the stack check."
	self genPushRegisterArgs.
	backEnd hasLinkRegister ifTrue: [self PushR: LinkReg].
	self PushR: FPReg.
	self MoveR: SPReg R: FPReg.
	methodLabel addDependent: (self annotateAbsolutePCRef:
		(self PushCw: methodLabel asInteger)). "method"
	self genMoveNilR: SendNumArgsReg.
	self PushR: SendNumArgsReg. "context"
	self PushR: ReceiverResultReg.
	methodOrBlockNumArgs + 1 to: methodOrBlockNumTemps do:
		[:i| self PushR: SendNumArgsReg].
	stackCheckLabel := self compileStackOverflowCheck: (coInterpreter
														canContextSwitchIfActivating: methodObj
														header: methodHeader)! !


!ProfilingCogit methodsFor: 'oil compilation' stamp: 'cb 10/24/2026 15:00'!
oilRegisterSelectors
	"Tell Pass 1 the selectors it treats specially, from the Array supplied by the image (primitiveOilSetSelectors):
	 pairs of kind (0-4 value selectors by arity, 5 bitXor:, 6 iterators, 7 cold) and selector.  Re-registered
	 before each compilation since the garbage collector moves selectors."
	| sels n kind sel |
	self resetSelectorRegistry.
	self oilDisqualifyLimit: 0.
	sels := oilSelectors.
	(sels = 0 or: [sels = objectMemory nilObject]) ifTrue: [^self].
	(objectMemory isForwarded: sels) ifTrue:
		[sels := objectMemory followForwarded: sels.
		 oilSelectors := sels].
	n := objectMemory numSlotsOf: sels.
	0 to: n - 2 by: 2 do:
		[:i|
		kind := objectMemory fetchPointer: i ofObject: sels.
		sel := objectMemory fetchPointer: i + 1 ofObject: sels.
		((objectMemory isIntegerObject: kind) and: [objectMemory isNonImmediate: sel]) ifTrue:
			[(objectMemory isForwarded: sel) ifTrue: [sel := objectMemory followForwarded: sel].
			 self registerSelector: sel kind: (objectMemory integerValueOf: kind)].
		"kind 8: the number of deoptimizations after which an Oil method is disqualified (default OilDisqualifyDeopts)"
		(kind = (objectMemory integerObjectOf: 8) and: [objectMemory isIntegerObject: sel]) ifTrue:
			[self oilDisqualifyLimit: (objectMemory integerValueOf: sel)]]! !

!ProfilingCogit methodsFor: 'oil compilation' stamp: 'cb 10/24/2026 15:00'!
oilCompile: aMethodObj receiverClass: classObj
	"Run Pass 1 of Oil (inlining, linear IR, deopt states) on aMethodObj for receivers of class classObj.  This must
	 happen while the inline caches of the baseline machine code (the type feedback) are still there.
	 Answer OilOK or a failure code; see oilGenerate: for Pass 3."
	<api>
	<option: #ProfilingCogit>
	self oilRegisterSelectors.
	^(self compileMethod: aMethodObj receiverClass: classObj)
		ifTrue: [OilOK]
		ifFalse: [self oilFailureCode]! !

!ProfilingCogit methodsFor: 'oil compilation' stamp: 'cb 10/24/2026 15:00'!
oilGenerate: aMethodObj
	"Run Pass 3 of Oil on the IR just produced by oilCompile:receiverClass: and install the resulting CogMethod as
	 aMethodObj's machine code, which must have none.  Answer OilOK or a failure code.
	 N.B. Like cog:selector: this never reclaims the method zone (it calls for a compaction if it is full)."
	<api>
	<option: #ProfilingCogit>
	| result estimate |
	(coInterpreter methodHasCogMethod: aMethodObj) ifTrue:
		[^OilFailInternal].
	methodObj := aMethodObj.
	methodHeader := objectMemory methodHeaderOf: aMethodObj.
	(result := self pass2Optimize) ~= OilOK ifTrue:
		[^result].
	(result := self prepareNativeCode) ~= OilOK ifTrue:
		[^result].
	self setHasMovableLiteral: false.
	self setHasYoungReferent: (objectMemory isYoungObject: methodObj).
	methodOrBlockNumArgs := coInterpreter argumentCountOf: methodObj.
	methodOrBlockNumTemps := coInterpreter tempCountOf: methodObj.
	inBlock := 0.
	maxLitIndex := -1.
	needsFrame := true.
	useTwoPaths := false.
	regArgsHaveBeenPushed := false.
	primitiveIndex := 0.
	initialPC := coInterpreter startPCOfMethod: methodObj.
	endPC := objectMemory numBytesOf: methodObj.
	bytecodeSetOffset := (coInterpreter headerIndicatesAlternateBytecodeSet: methodHeader)
							ifTrue: [256]
							ifFalse: [0].
	counters := 0.
	numCounters := 0.
	blockCount := 0.
	blockEntryLabel := nil.
	receiverTags := -1.
	estimate := self estimateOpcodes.
	self allocateOpcodes: estimate
		bytecodes: 0
		ifFail: [^OilFailBackend].
	methodLabel dependent: nil.
	self preenMethodLabel.
	self compileAbort.
	self compileEntry.
	self oilCompileFrameBuild.
	(result := self generateNativeCode) ~= OilOK ifTrue:
		[^result].
	opcodeIndex >= numAbstractOpcodes ifTrue:
		[self error: 'Oil: abstract opcode estimate exceeded'.
		 ^OilFailInternal].
	^self oilGenerateCogMethod! !

!ProfilingCogit methodsFor: 'oil compilation' stamp: 'cb 10/24/2026 15:00'!
oilGenerateCogMethod
	"Assemble the abstract instructions into a CogMethod, like generateCogMethod:, then attach the
	 deoptimization metadata, a hidden pinned Array, through the method's counters field (tagged with 1)."
	<inline: true>
	| codeSize headerSize mapSize totalSize startAddress result md selector added writableMethod |
	<var: #writableMethod type: #'CogMethod *'>
	md := coInterpreter oilAllocateMetadata: self metadataSize.
	md = 0 ifTrue:
		[^OilFailCodeSpace].
	headerSize := self sizeof: CogMethod.
	methodLabel address: methodZone freeStart.
	self computeMaximumSizes.
	methodLabel concretizeAt: methodZone freeStart.
	codeSize := self generateInstructionsAt: methodLabel address + headerSize.
	mapSize := self generateMapAt: nil start: methodLabel address + cmNoCheckEntryOffset.
	totalSize := methodZone roundUpLength: headerSize + codeSize + mapSize.
	totalSize > MaxMethodSize ifTrue:
		[objectMemory freeObject: md.
		 ^OilFailCodeSpace].
	startAddress := methodZone allocate: totalSize.
	startAddress = 0 ifTrue:
		[objectMemory freeObject: md.
		 coInterpreter callForCogCompiledCodeCompaction.
		 ^OilFailCodeSpace].
	self assert: startAddress + cmEntryOffset = entry address.
	self assert: startAddress + cmNoCheckEntryOffset = noCheckEntry address.
	result := self outputInstructionsAt: startAddress + headerSize.
	self assert: startAddress + headerSize + codeSize = result.
	backEnd padIfPossibleWithStopsFrom: result to: startAddress + totalSize - mapSize - 1.
	self generateMapAt: startAddress + totalSize - 1 start: startAddress + cmNoCheckEntryOffset.
	self fillInBlockHeadersAt: startAddress.
	selector := coInterpreter maybeSelectorOfMethod: methodObj.
	selector isNil ifTrue: [selector := objectMemory nilObject].
	"Oil frames hold the home slots of the virtual registers below the temps, and marrying or divorcing a frame copies
	 all its slots into its context: give the method large contexts (prepareNativeCode keeps the frame within
	 LargeContextSlots), and note whether the bit must be cleared from the method's header when it is freed."
	added := (coInterpreter methodNeedsLargeContext: methodObj) not.
	methodHeader := coInterpreter oilHeaderWithLargeContext: methodHeader.
	writableMethod := self writableMethodFor: startAddress.
	self fillInMethodHeader: writableMethod
		size: totalSize
		selector: selector.
	writableMethod cmUnusedFlag: added.
	"Oil methods are expensive to compile and hot: start with the maximum usage count."
	writableMethod cmUsageCount: CMMaxUsageCount.
	writableMethod counters: md + 1.
	self fillMetadata: md cogMethod: startAddress.
	backEnd flushICacheFrom: startAddress to: startAddress + totalSize.
	^OilOK! !

!ProfilingCogit methodsFor: 'oil compilation' stamp: 'cb 10/24/2026 15:00'!
isOilMethod: cogMethod
	"Oil methods hold their deoptimization metadata in their counters field, tagged with 1;
	 baseline methods hold their (8-byte aligned) trip counters there, or 0."
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	^cogMethod isCMMethodEtAl
	  and: [(cogMethod counters bitAnd: 1) ~= 0]! !

!ProfilingCogit methodsFor: 'oil compilation' stamp: 'cb 10/24/2026 15:00'!
oilMetadataOf: cogMethod
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	self assert: (self isOilMethod: cogMethod).
	^cogMethod counters - 1! !

!ProfilingCogit methodsFor: 'oil compilation' stamp: 'cb 10/24/2026 15:00'!
setOilSelectors: anArray
	<api>
	oilSelectors := anArray! !

!ProfilingCogit methodsFor: 'oil compilation' stamp: 'cb 10/24/2026 15:00'!
getOilSelectors
	<api>
	^oilSelectors! !

!ProfilingCogit methodsFor: 'oil compilation' stamp: 'cb 10/24/2026 15:00'!
oilSelectorsAddress
	"Answer the address of the oilSelectors variable, for registering it as a GC root."
	<api>
	<returnTypeC: #'sqInt *'>
	^self addressOf: oilSelectors put: [:value| oilSelectors := value]! !

!ProfilingCogit methodsFor: 'oil selector table' stamp: 'cb 10/24/2026 18:00'!
setOilExtraSelectors: anArray
	<api>
	oilExtraSelectors := anArray! !

!ProfilingCogit methodsFor: 'oil selector table' stamp: 'cb 10/24/2026 18:00'!
getOilExtraSelectors
	<api>
	^oilExtraSelectors! !

!ProfilingCogit methodsFor: 'oil selector table' stamp: 'cb 10/24/2026 18:00'!
oilExtraSelectorsAddress
	"Answer the address of the oilExtraSelectors variable, a GC root, which ceDereferenceSelectorIndex reads."
	<api>
	<returnTypeC: #'sqInt *'>
	^self addressOf: oilExtraSelectors put: [:value| oilExtraSelectors := value]! !

!ProfilingCogit methodsFor: 'oil selector table' stamp: 'cb 10/24/2026 18:00'!
oilExtraSelectorIndexOf: selector add: addIfAbsent
	"64-bit inline caches hold the index of their selector among the special selectors or the literals of the method.
	 Oil methods also send selectors of the methods they inline, which are not among their literals, so their inline
	 caches may hold OilExtraSelectorBase + k instead: the selector at index k of the Oil selector table
	 (oilExtraSelectors, allocated by primitiveOilSetSelectors, a GC root; see CogObjectRepresentationFor64BitSpur>>oilWrapSelectorIndexDereferenceRoutine
	 and indexForSelector:in:).  Answer selector's value, adding it if addIfAbsent, or OilNoLink if it is absent and not
	 added (no table, table full, or a young selector, which the table, perhaps old, must not refer to)."
	| table sel |
	table := oilExtraSelectors.
	(table = 0 or: [table = objectMemory nilObject]) ifTrue:
		[^OilNoLink].
	0 to: (objectMemory numSlotsOf: table) - 1 do:
		[:k|
		sel := objectMemory fetchPointer: k ofObject: table.
		sel = selector ifTrue:
			[^OilExtraSelectorBase + k].
		sel = objectMemory nilObject ifTrue:
			[(addIfAbsent
			  and: [(objectMemory isNonImmediate: selector)
			  and: [(objectMemory isYoungObject: selector) not]]) ifFalse:
				[^OilNoLink].
			 objectMemory storePointerUnchecked: k ofObject: table withValue: selector.
			 ^OilExtraSelectorBase + k]].
	^OilNoLink! !

!ProfilingCogit methodsFor: 'oil selector table' stamp: 'cb 10/24/2026 18:00'!
indexForSelector: selector in: cogMethod
	"Answer the value to put in an inline-cache that is being loaded with the selector (when unlinking a send).
	 Oil methods' sends may also use the Oil selector table (see oilExtraSelectorIndexOf:add:)."
	<var: #cogMethod type: #'CogMethod *'>
	<inline: false>
	| index |
	(self isOilMethod: cogMethod) ifTrue:
		[index := self oilExtraSelectorIndexOf: selector add: false.
		 index ~= OilNoLink ifTrue:
			[^index]].
	^super indexForSelector: selector in: cogMethod! !

!CogObjectRepresentationFor64BitSpur methodsFor: '*Cogit-Oil' stamp: 'cb 10/24/2026 18:00'!
oilWrapSelectorIndexDereferenceRoutine
	"Oil methods' inline caches may also hold OilExtraSelectorBase + k, for the selector at index k of the Oil selector
	 table (see ProfilingCogit>>oilExtraSelectorIndexOf:add:).  Put a routine that maps those in front of the one
	 generated by maybeGenerateSelectorIndexDereferenceRoutine, which the send trampolines call."
	| jumpNotOil |
	<var: 'jumpNotOil' type: #'AbstractInstruction *'>
	cogit zeroOpcodeIndex.
	cogit CmpCq: OilExtraSelectorBase R: ClassReg.
	jumpNotOil := cogit JumpLess: 0.
	cogit
		SubCq: OilExtraSelectorBase - 1 R: ClassReg; "1-relative, skipping the header"
		MoveAw: (self cCoerceSimple: cogit oilExtraSelectorsAddress to: #usqInt) R: Extra1Reg;
		MoveXwr: ClassReg R: Extra1Reg R: ClassReg;
		RetN: 0.
	"(not JumpFullRT:, which clobbers TempReg, an argument of the directed super send trampolines)"
	jumpNotOil jmpTarget: (cogit Jump: (self cCoerceSimple: ceDereferenceSelectorIndex to: #'AbstractInstruction *')).
	ceDereferenceSelectorIndex := cogit methodZoneBase.
	cogit
		outputInstructionsForGeneratedRuntimeAt: ceDereferenceSelectorIndex;
		recordGeneratedRunTime: 'ceOilDereferenceSelectorIndex' address: ceDereferenceSelectorIndex;
		recordRunTimeObjectReferences! !

!ProfilingCogit methodsFor: 'oil selector table' stamp: 'cb 10/24/2026 18:00'!
generateSendTrampolines
	objectRepresentation oilWrapSelectorIndexDereferenceRoutine.
	super generateSendTrampolines! !


!ProfilingCogit methodsFor: 'in-line cacheing' stamp: 'cb 10/24/2026 15:00'!
oilSendMcpcAt: bcpc in: cogMethod
	"Answer the return address (mcpc) of the ordinary send at the 0-relative bytecode pc bcpc in cogMethod,
	 or 0 if cogMethod is frameless, an Oil method, or has no such send."
	<var: #cogMethod type: #'CogMethod *'>
	<returnTypeC: #usqInt>
	((self isOilMethod: cogMethod) or: [cogMethod stackCheckOffset = 0]) ifTrue:
		[^0].
	^self
		mapFor: (self cCoerceSimple: cogMethod to: #'CogBlockMethod *')
		bcpc: (coInterpreter startPCOfMethodHeader: cogMethod methodHeader)
		performUntil: #oilFindSendAt:Annotation:Mcpc:Bcpc:Method:
		arg: (self cCoerceSimple: bcpc to: #'void *')! !

!ProfilingCogit methodsFor: 'in-line cacheing' stamp: 'cb 10/24/2026 15:00'!
oilMonomorphicClassAt: bcpc in: aMethodObj
	"Type feedback for Oil's Pass 1: the receiver class of the send at the 0-relative bytecode pc bcpc of
	 aMethodObj (a CompiledMethod or CompiledBlock) if its inline cache is monomorphic, else 0."
	| mcpc entryPoint targetMethod class |
	<var: #targetMethod type: #'CogMethod *'>
	(coInterpreter methodHasCogMethod: aMethodObj) ifFalse: [^0].
	mcpc := self oilSendMcpcAt: bcpc in: (coInterpreter cogMethodOf: aMethodObj).
	mcpc = 0 ifTrue: [^0].
	entryPoint := backEnd callTargetFromReturnAddress: mcpc.
	entryPoint <= methodZoneBase ifTrue: [^0].
	self targetMethodAndSendTableFor: entryPoint
		annotation: IsSendCall
		into: [:target :sendTable| targetMethod := target].
	targetMethod isCMMethodEtAl ifFalse: [^0].
	class := objectRepresentation classForInlineCacheTag: (backEnd inlineCacheTagAt: mcpc).
	^class = objectMemory nilObject ifTrue: [0] ifFalse: [class]! !


!ProfilingCogit methodsFor: 'in-line cacheing' stamp: 'cb 10/24/2026 15:00'!
oilSendSiteUnlinkedAt: bcpc in: aMethodObj
	"Has the send at the 0-relative bytecode pc bcpc of aMethodObj never been sent, i.e. is its inline cache
	 unlinked (or does the method not have machine code yet)?  The baseline JIT inlines SmallInteger arithmetic
	 and comparisons and sends the message only for other receivers, so for those selectors an unlinked send
	 means only SmallIntegers were seen."
	| cogMethod mcpc |
	<var: #cogMethod type: #'CogMethod *'>
	(coInterpreter methodHasCogMethod: aMethodObj) ifFalse: [^true].
	cogMethod := coInterpreter cogMethodOf: aMethodObj.
	(self isOilMethod: cogMethod) ifTrue: [^false].
	mcpc := self oilSendMcpcAt: bcpc in: cogMethod.
	^mcpc = 0 or: [(backEnd callTargetFromReturnAddress: mcpc) <= methodZoneBase]! !


!ProfilingCogit methodsFor: 'oil support' stamp: 'cb 10/24/2026 18:00'!
oilMethodHasOilCode: aMethodObj
	"Is aMethodObj's machine code Oil code (OilCompiler>>shouldInline:selector:numArgs:receiver: then calls it)?"
	^(coInterpreter methodHasCogMethod: aMethodObj)
	  and: [self isOilMethod: (coInterpreter cogMethodOf: aMethodObj)]! !

!ProfilingCogit methodsFor: 'oil support' stamp: 'cb 10/24/2026 18:30'!
oilSendSiteNeverSentAt: bcpc in: aMethodObj
	"Does aMethodObj have baseline machine code in which the send at bcpc was never executed (unlinked inline cache)?"
	^(coInterpreter methodHasCogMethod: aMethodObj)
	  and: [self oilSendSiteUnlinkedAt: bcpc in: aMethodObj]! !

!ProfilingCogit methodsFor: 'invalidation' stamp: 'cb 10/24/2026 19:20'!
oilMethod: cogMethod inlinesSelector: aSelector
	"Answer whether cogMethod or any method inlined into it sends/defines aSelector."
	| md nFrames frames m |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod selector = aSelector ifTrue: [^true].
	md := self oilMetadataOf: cogMethod.
	nFrames := objectMemory integerValueOf: (objectMemory fetchPointer: OilMDNumFrames ofObject: md).
	frames := objectMemory integerValueOf: (objectMemory fetchPointer: OilMDFrames ofObject: md).
	0 to: nFrames - 1 do:
		[:fr|
		m := objectMemory fetchPointer: frames + (fr * OilMDFrameSize) ofObject: md.
		(coInterpreter maybeSelectorOfMethod: m) = aSelector ifTrue: [^true]].
	^false! !

!ProfilingCogit methodsFor: 'jit - api' stamp: 'cb 10/24/2026 19:20'!
unlinkSendsOf: selector isMNUSelector: isMNUSelector
	<api>
	"Also discard Oil methods that inlined selector (unless an activation is currently running on the stack)."
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	super unlinkSendsOf: selector isMNUSelector: isMNUSelector.
	methodZoneBase ifNil: [^self].
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[((self isOilMethod: cogMethod)
		  and: [(self oilMethod: cogMethod inlinesSelector: selector)
		  and: [(coInterpreter oilHasFramesOf: cogMethod) not]]) ifTrue:
			[self unlinkSendsTo: cogMethod methodObject andFreeIf: true].
		 cogMethod := methodZone methodAfter: cogMethod]! !

!ProfilingCogit methodsFor: 'compaction' stamp: 'cb 10/24/2026 15:00'!
maybeFreeCountersOf: aCogMethod
	"Free the pinned object holding the method's trip counters, or its Oil deoptimization metadata, if any."
	<var: #aCogMethod type: #'CogMethod *'>
	<inline: true>
	"An Oil method that set the large context bit of its header (see oilGenerateCogMethod): freeMethod: has just put
	 its header back into the CompiledMethod, without the bit."
	((aCogMethod counters bitAnd: 1) ~= 0
	 and: [aCogMethod cmUnusedFlag
	 and: [(coInterpreter rawHeaderOf: aCogMethod methodObject) = aCogMethod methodHeader]]) ifTrue:
		[coInterpreter
			rawHeaderOf: aCogMethod methodObject
			put: (coInterpreter oilHeaderWithoutLargeContext: aCogMethod methodHeader)].
	self freeOilCounters: aCogMethod counters! !

!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/24/2026 15:00'!
countersObjectOf: theCounters
	"theCounters is the counters field of a method: 0, the address of the first counter (an 8-byte aligned slot
	 of a pinned object), or the oop of an Oil method's metadata tagged with 1.  Answer the heap object, or 0."
	<var: #theCounters type: #usqInt>
	<inline: true>
	theCounters = 0 ifTrue: [^0].
	^(theCounters bitAnd: 1) ~= 0
		ifTrue: [theCounters - 1]
		ifFalse: [theCounters - objectMemory baseHeaderSize]! !

!ProfilingCogit methodsFor: 'compile abstract instructions' stamp: 'cb 10/24/2026 15:00'!
freeOilCounters: theCounters
	<var: #theCounters type: #usqInt>
	<inline: true>
	| obj |
	obj := self countersObjectOf: theCounters.
	obj ~= 0 ifTrue: [objectMemory freeObject: obj]! !

!ProfilingCogit methodsFor: 'garbage collection & become' stamp: 'cb 10/24/2026 15:00'!
maybeMarkCountersIn: cogMethod
	"The trip counters and the Oil deoptimization metadata are held in pinned objects on the heap which must be
	 marked to avoid them being collected (and, for the metadata, to trace the objects it refers to)."
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	| obj |
	obj := self countersObjectOf: cogMethod counters.
	obj ~= 0 ifTrue: [objectMemory markAndTrace: obj]! !

!ProfilingCogit class methodsFor: 'trampoline support' stamp: 'cb 10/24/2026 15:00'!
numTrampolines
	^super numTrampolines + 2 "ceOilTripTrampoline ceOilBailoutTrampoline"! !

!ProfilingCogit class methodsFor: 'translation' stamp: 'cb 10/24/2026 15:00'!
ancilliaryClasses
	"Answer any extra classes to be included in the translation: the counters field of SistaCogMethod and
	 Oil's optimizing compiler (its scanner, Pass 1 and Pass 3), which emits Cogit abstract instructions."
	^super ancilliaryClasses, {SistaCogMethod. OilBytecodeDescriptor. OilBytecodeScanner. OilCompiler}! !


!OilCompiler methodsFor: 'native code generation' stamp: 'cb 10/24/2026 15:00'!
estimateOpcodes
	"An upper bound of the number of abstract instructions oilGenerate: emits (they are allocated on the C stack)."
	| i op n |
	n := 200 + (2 * oilNumHomes) + (4 * numSites) + (4 * OilMaxReg // 16).
	i := 0.
	[i < irIndex] whileTrue:
		[op := self opcodeAt: i.
		 n := n + ((op = OilCall0 or: [op = OilCall1 or: [op = OilCallN or: [op = OilCallSuper]]])
					ifTrue: [48 + (2 * (self fieldCAt: i))]
					ifFalse:
						[(op = OilStoreField or: [op = OilStoreElement])
							ifTrue: [48]
							ifFalse:
								[(op = OilNewArray or: [op = OilMakeClosure])
									ifTrue: [40 + (2 * (self fieldCAt: i)) + (2 * OilMaxReg // 16)]
									ifFalse:
										[(op = OilStreamNext or: [op = OilStreamNextPut or: [op = OilCompareBytes]])
											ifTrue: [140]
											ifFalse: [20]]]]).
		 i := i + (self instructionLengthAt: i)].
	^n + (4 * oilNumAllocRegs) + (3 * OilMaxUndos)! !

!OilCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/24/2026 19:20'!
metadataSize
	"The number of slots of the deoptimization metadata (see fillMetadata:cogMethod:)."
	| n |
	n := OilMDHeaderSize + (numFrames * OilMDFrameSize) + (numVObjs * OilMDVObjSize) + (capturedTop * 2) + OilNumRegs + numSites.
	0 to: numSites - 1 do:
		[:s| (oilSiteUsed at: s) ~= 0 ifTrue:
			[n := n + OilMDSiteHeaderSize + (2 * (self siteStateSize: s))]].
	^n! !

!OilCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/24/2026 15:00'!
md: md at: index put: value
	<inline: true>
	objectMemory storePointer: index ofObject: md withValue: value! !

!OilCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/24/2026 15:00'!
md: md at: index putInt: value
	<inline: true>
	objectMemory storePointer: index ofObject: md withValue: (objectMemory integerObjectOf: value)! !

!OilCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/24/2026 15:00'!
md: md at: index putKind: kind value: value
	"A descriptor: its kind and its value, an object for a constant, a SmallInteger (register or virtual object) otherwise."
	self md: md at: index putInt: kind.
	kind = OilDescConst
		ifTrue: [self md: md at: index + 1 put: value]
		ifFalse: [self md: md at: index + 1 putInt: value]! !

!OilCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/24/2026 15:00'!
fillMetadata: md cogMethod: cogMethodAddress
	"Fill in the deoptimization metadata of the Oil method at cogMethodAddress, a hidden pinned Array:
	 header (OilMD*), the inlined frames, the virtual objects (dissolved closures and temp vectors) and their
	 captured values, the home slot (frame offset) of every virtual register, a table from deopt site index to
	 site record, and the records of the sites used by the bailout stubs: kind, the guarded register and class
	 tag (for the unforwarding fast path), the offset of the instruction to resume at, the inlined frame and
	 bytecode pc, and the virtual state (descriptors of the register window and of the high registers)."
	<var: #cogMethodAddress type: #usqInt>
	| frames vobjs captured homes siteTable index f p op g |
	frames := OilMDHeaderSize.
	vobjs := frames + (numFrames * OilMDFrameSize).
	captured := vobjs + (numVObjs * OilMDVObjSize).
	homes := captured + (capturedTop * 2).
	siteTable := homes + OilNumRegs.
	self md: md at: OilMDVersion putInt: OilMDMagic.
	self md: md at: OilMDRootMethod put: rootMethod.
	self md: md at: OilMDNumSites putInt: numSites.
	self md: md at: OilMDSiteTable putInt: siteTable.
	self md: md at: OilMDNumFrames putInt: numFrames.
	self md: md at: OilMDFrames putInt: frames.
	self md: md at: OilMDNumVObjs putInt: numVObjs.
	self md: md at: OilMDVObjs putInt: vobjs.
	self md: md at: OilMDHomes putInt: homes.
	self md: md at: OilMDDeopts putInt: 0.
	self md: md at: OilMDFastPaths putInt: 0.
	self md: md at: OilMDNumArgs putInt: (self numArgsOf: rootMethod).
	self md: md at: OilMDCaptured putInt: captured.
	0 to: numFrames - 1 do:
		[:fr|
		f := frames + (fr * OilMDFrameSize).
		g := frameParent at: fr.
		self md: md at: f put: (frameMethod at: fr).
		self md: md at: f + 1 putInt: ((frameIsBlock at: fr) ifTrue: [1] ifFalse: [0]).
		self md: md at: f + 2 putInt: (frameBase at: fr).
		self md: md at: f + 3 putInt: g.
		g < 0
			ifTrue: [self md: md at: f + 4 putInt: -1]
			ifFalse: "the pc after the send that the frame was inlined at"
				[self setScanMethod: (frameMethod at: g).
				 self decodeAt: (frameCallPC at: fr).
				 self md: md at: f + 4 putInt: oilNextPC].
		self md: md at: f + 5 putKind: (frameSelfKind at: fr) value: (frameSelfValue at: fr).
		self md: md at: f + 7 putInt: (self numArgsOf: (frameMethod at: fr))].
	0 to: numVObjs - 1 do:
		[:v|
		p := vobjs + (v * OilMDVObjSize).
		self md: md at: p putInt: (vobjKind at: v).
		(vobjKind at: v) = OilDescBlock
			ifTrue:
				[self md: md at: p + 1 put: (vobjLiteral at: v).
				 self md: md at: p + 2 putInt: (vobjOuter at: v).
				 self md: md at: p + 3 putKind: (vobjSelfKind at: v) value: (vobjSelfValue at: v).
				 self md: md at: p + 5 putInt: (vobjNumCopied at: v).
				 self md: md at: p + 6 putInt: captured + (2 * (vobjCopiedBase at: v)).
				 self md: md at: p + 7 putInt: 0]
			ifFalse:
				[self md: md at: p + 1 putInt: (vobjSize at: v).
				 self md: md at: p + 2 putInt: -1.
				 self md: md at: p + 3 putKind: OilDescConst value: objectMemory nilObject.
				 self md: md at: p + 5 putInt: 0.
				 self md: md at: p + 6 putInt: 0.
				 self md: md at: p + 7 putInt: (vobjSlotBase at: v)]].
	0 to: capturedTop - 1 do:
		[:j| self md: md at: captured + (2 * j) putKind: (capturedKind at: j) value: (capturedValue at: j)].
	0 to: OilNumRegs - 1 do:
		[:r| self md: md at: homes + r putInt: (oilVRegHome at: r)].
	index := siteTable + numSites.
	0 to: numSites - 1 do:
		[:s|
		(oilSiteUsed at: s) = 0
			ifTrue: [self md: md at: siteTable + s putInt: -1]
			ifFalse:
				[self md: md at: siteTable + s putInt: index.
				 op := self opcodeAt: (siteIR at: s).
				 self md: md at: index putInt: (siteKind at: s).
				 op = OilGuardClass
					ifTrue:
						[self md: md at: index + 1 putInt: (self fieldAAt: (siteIR at: s)).
						 self md: md at: index + 2 putInt: (objectMemory classTagForClass: (self word64At: (siteIR at: s) + 1))]
					ifFalse:
						[self md: md at: index + 1 putInt: -1.
						 self md: md at: index + 2 putInt: 0].
				 self md: md at: index + 3 putInt: (oilSiteResume at: s) address - cogMethodAddress.
				 self md: md at: index + 4 putInt: (siteFrame at: s).
				 self md: md at: index + 5 putInt: (sitePC at: s).
				 self md: md at: index + 6 putInt: (siteSnapTop at: s).
				 self md: md at: index + 7 putInt: (siteSnapHigh at: s).
				 index := index + OilMDSiteHeaderSize.
				 p := siteSnapBase at: s.
				 0 to: (siteSnapTop at: s) + (OilMaxReg - (siteSnapHigh at: s)) do:
					[:j|
					self md: md at: index putKind: (sitePoolKind at: p + j) value: (sitePoolValue at: p + j).
					index := index + 2]]]! !


!CoInterpreter methodsFor: '*Cogit-Oil-support' stamp: 'cb 10/24/2026 15:00'!
oilApiLookupSelector: selector inClass: class
	<api>
	<essential: #ProfilingCogit>
	"lookupSelector:inClass: answers nil, i.e. 0, if not found."
	^self lookupSelector: selector inClass: class! !

!CoInterpreter methodsFor: '*Cogit-Oil-support' stamp: 'cb 10/24/2026 15:00'!
oilApiSuperclassOf: class
	<api>
	<essential: #ProfilingCogit>
	^self superclassOf: class! !

!CoInterpreter methodsFor: '*Cogit-Oil-support' stamp: 'cb 10/24/2026 15:00'!
oilApiInstSpecOfClass: class
	<api>
	<essential: #ProfilingCogit>
	^objectMemory instSpecOfClass: class! !

!CoInterpreter methodsFor: '*Cogit-Oil-support' stamp: 'cb 10/24/2026 15:00'!
oilApiFetchClassOf: oop
	<api>
	<essential: #ProfilingCogit>
	^objectMemory fetchClassOf: oop! !

!CoInterpreter methodsFor: '*Cogit-Oil-support' stamp: 'cb 10/24/2026 15:00'!
oilAllocateMetadata: numSlots
	"Answer a hidden (class index pun), pinned, old space Array of numSlots nils for the deoptimization metadata
	 of an Oil method, or 0.  It is referenced from the method (see ProfilingCogit>>maybeMarkCountersIn:)."
	<api>
	<essential: #ProfilingCogit>
	| obj |
	obj := objectMemory
			allocateSlotsForPinningInOldSpace: numSlots
			bytes: (objectMemory objectBytesForSlots: numSlots)
			format: objectMemory arrayFormat
			classIndex: objectMemory arrayClassIndexPun.
	obj isNil ifTrue: [^0].
	objectMemory fillObj: obj numSlots: numSlots with: objectMemory nilObject.
	^obj! !

!CoInterpreter methodsFor: '*Cogit-Oil-deoptimization' stamp: 'cb 10/24/2026 15:00'!
oilMD: md at: index
	"Answer the SmallInteger value of slot index of Oil metadata md."
	<inline: true>
	<essential: #ProfilingCogit>
	^objectMemory integerValueOf: (objectMemory fetchPointer: index ofObject: md)! !

!CoInterpreter methodsFor: '*Cogit-Oil-deoptimization' stamp: 'cb 10/24/2026 15:00'!
oilMDIncrement: index of: md
	<essential: #ProfilingCogit>
	objectMemory
		storePointerUnchecked: index
		ofObject: md
		withValue: (objectMemory integerObjectOf: (self oilMD: md at: index) + 1)! !

!CoInterpreter methodsFor: '*Cogit-Oil-deoptimization' stamp: 'cb 10/24/2026 15:00'!
ceOilBailout: siteIndex
	"Called from ceOilBailoutTrampoline by the bailout sequence of an Oil method (see OilCompiler>>genBailoutStubs)
	 when a guard fails at deopt site siteIndex.  framePointer is the Oil method's frame, whose virtual registers
	 have all been spilled to their homes; the top of stack is the return address into the bailout sequence.
	 Fast path: a class guard failed on a forwarder (become:) whose target passes the guard: store the target in
	 the register's home and answer the address of the guard; the machine code reloads its registers and resumes
	 there, without deoptimizing.
	 Slow path: deoptimize.  Rebuild the interpreter frames of the method and of the methods and blocks inlined into
	 it at the site, with the closures and temp vectors Oil dissolved rematerialized, and continue in the
	 interpreter at the site's bytecode.  This does not return."
	<api>
	<essential: #ProfilingCogit>
	<returnTypeC: #usqInt>
	| cogMethod md site vreg home value |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := self mframeHomeMethod: framePointer.
	self assert: (cogit isOilMethod: cogMethod).
	md := cogit oilMetadataOf: cogMethod.
	site := self oilMD: md at: (self oilMD: md at: OilMDSiteTable) + siteIndex.
	self assert: site > 0.
	(self oilMD: md at: site) = OilSiteGuard ifTrue:
		[vreg := self oilMD: md at: site + 1.
		 home := self oilMD: md at: (self oilMD: md at: OilMDHomes) + vreg.
		 value := stackPages longAt: framePointer + home.
		 ((objectMemory isNonImmediate: value)
		  and: [objectMemory isForwarded: value]) ifTrue:
			[value := objectMemory followForwarded: value.
			 (objectMemory fetchClassTagOf: value) = (self oilMD: md at: site + 2) ifTrue:
				[stackPages longAt: framePointer + home put: value.
				 self oilMDIncrement: OilMDFastPaths of: md.
				 ^cogMethod asUnsignedInteger + (self oilMD: md at: site + 3)]]].
	(self oilMD: md at: site) ~= OilSiteAlloc ifTrue: "an allocation beyond the scavenge threshold is not a failed speculation"
		[self oilMDIncrement: OilMDDeopts of: md].
	instructionPointer := self popStack. "the return address into the bailout sequence"
	self oilDeoptimizeFrame: framePointer metadata: md site: site.
	(self oilMD: md at: OilMDDeopts) >= cogit oilDisqualifyLimit ifTrue:
		[self oilDisqualifyCogMethod: cogMethod].
	"and now continue in the interpreter..."
	cogit ceInvokeInterpret.
	"NOTREACHED"
	^0! !

!CoInterpreter methodsFor: '*Cogit-Oil-support' stamp: 'cb 10/24/2026 18:30'!
oilRaiseMaxLiteralCountForCompile
	"Methods with more literals than maxLiteralCountForCompile are not JIT-compiled.  Raise the limit to 512 literals."
	<api>
	<essential: #ProfilingCogit>
	maxLiteralCountForCompile := maxLiteralCountForCompile max: 512! !

!CoInterpreter methodsFor: '*Cogit-Oil-deoptimization' stamp: 'cb 10/24/2026 17:30'!
oilDisqualifyCogMethod: cogMethod
	"The Oil method cogMethod deoptimized OilDisqualifyDeopts times (its speculations do not hold): never compile its
	 method with Oil again and, unless other activations still run it, free it, unlinking the sends to it, so that
	 the baseline JIT compiles the method again, instead of running it in the interpreter after each deopt."
	<essential: #ProfilingCogit>
	<var: #cogMethod type: #'CogMethod *'>
	| methodObj |
	methodObj := cogMethod methodObject.
	cogit oilDisqualify: methodObj.
	(self oilHasFramesOf: cogMethod) ifFalse:
		[cogit unlinkSendsTo: methodObj andFreeIf: true]! !

!CoInterpreter methodsFor: '*Cogit-Oil-deoptimization' stamp: 'cb 10/24/2026 17:30'!
oilHasFramesOf: cogMethod
	"Is there a machine code frame running cogMethod on a stack page?"
	<api>
	<essential: #ProfilingCogit>
	<var: #cogMethod type: #'CogMethod *'>
	<var: #aPage type: #'StackPage *'>
	<var: #theFP type: #'char *'>
	| aPage theFP |
	0 to: numStackPages - 1 do:
		[:i|
		aPage := stackPages stackPageAt: i.
		(stackPages isFree: aPage) ifFalse:
			[theFP := aPage = stackPage ifTrue: [framePointer] ifFalse: [aPage headFP].
			 [theFP ~= 0] whileTrue:
				[((self isMachineCodeFrame: theFP)
				  and: [(self mframeHomeMethod: theFP) = cogMethod]) ifTrue: [^true].
				 theFP := self frameCallerFP: theFP]]].
	^false! !

!CoInterpreter methodsFor: '*Cogit-Oil-deoptimization' stamp: 'cb 10/24/2026 15:00'!
oilDescriptorIndex: r site: site metadata: md
	"Answer the metadata index of the descriptor of register r in the virtual state of the site record at site,
	 or 0 if the state does not describe r."
	<essential: #ProfilingCogit>
	| top high |
	top := self oilMD: md at: site + 6.
	high := self oilMD: md at: site + 7.
	r <= top ifTrue:
		[^site + OilMDSiteHeaderSize + (2 * r)].
	(r > high and: [r <= OilMaxReg]) ifTrue:
		[^site + OilMDSiteHeaderSize + (2 * (top + 1)) + (2 * (r - high - 1))].
	^0! !

!CoInterpreter methodsFor: '*Cogit-Oil-deoptimization' stamp: 'cb 10/24/2026 15:00'!
oilValueAt: p metadata: md values: vals vobjs: vobjOops
	"Answer the value described by the descriptor at metadata index p: a register's value (read from its home before
	 the frame was rewritten), a constant, or a rematerialized virtual object (or nil if not yet allocated)."
	<essential: #ProfilingCogit>
	<var: #vals type: #'sqInt *'>
	<var: #vobjOops type: #'sqInt *'>
	| kind |
	p = 0 ifTrue: [^objectMemory nilObject].
	kind := self oilMD: md at: p.
	kind = OilDescConst ifTrue:
		[^objectMemory fetchPointer: p + 1 ofObject: md].
	(kind = OilDescBlock or: [kind = OilDescTempVector]) ifTrue:
		[^(vobjOops at: (self oilMD: md at: p + 1)) = 0
			ifTrue: [objectMemory nilObject]
			ifFalse: [vobjOops at: (self oilMD: md at: p + 1)]].
	^vals at: (self oilMD: md at: p + 1)! !

!CoInterpreter methodsFor: '*Cogit-Oil-deoptimization' stamp: 'cb 10/24/2026 15:00'!
oilNeedVObjAt: p metadata: md needed: needed
	"If the descriptor at metadata index p is a virtual object, mark it as needed."
	<essential: #ProfilingCogit>
	<var: #needed type: #'char *'>
	| kind v |
	p = 0 ifTrue: [^self].
	kind := self oilMD: md at: p.
	(kind = OilDescBlock or: [kind = OilDescTempVector]) ifFalse: [^self].
	v := self oilMD: md at: p + 1.
	(needed at: v) = 0 ifTrue: [needed at: v put: 1]! !

!CoInterpreter methodsFor: '*Cogit-Oil-deoptimization' stamp: 'cb 10/24/2026 15:00'!
oilStore: p at: address metadata: md values: vals vobjs: vobjOops needed: needed fixAddr: fixAddr fixVObj: fixVObj numFix: numFix
	"Store the value described by the descriptor at metadata index p into the frame slot at address.  A virtual
	 object is marked as needed and the slot recorded, to be stored once the object exists.  Answer numFix."
	<essential: #ProfilingCogit>
	<var: #address type: #'char *'>
	<var: #vals type: #'sqInt *'>
	<var: #vobjOops type: #'sqInt *'>
	<var: #needed type: #'char *'>
	<var: #fixAddr type: #'char **'>
	<var: #fixVObj type: #'sqInt *'>
	| kind |
	stackPages longAt: address put: (self oilValueAt: p metadata: md values: vals vobjs: vobjOops).
	p = 0 ifTrue: [^numFix].
	kind := self oilMD: md at: p.
	((kind = OilDescBlock or: [kind = OilDescTempVector]) and: [numFix < OilNumRegs]) ifFalse:
		[^numFix].
	self oilNeedVObjAt: p metadata: md needed: needed.
	fixAddr at: numFix put: address.
	fixVObj at: numFix put: (self oilMD: md at: p + 1).
	^numFix + 1! !

!CoInterpreter methodsFor: '*Cogit-Oil-deoptimization' stamp: 'cb 10/24/2026 15:00'!
oilDeoptimizeFrame: oilFP metadata: md site: site
	"Replace the Oil method's machine code frame at oilFP (the top frame) by the interpreter frames it stands for at
	 the deopt site record site: the root method's frame (converted in place: its receiver and arguments are already
	 above it) and one frame per method or block inlined at the site, from the root to the innermost.  Each frame's
	 temps and stack are the values of the registers of its part of the register window (see OilCompiler), its
	 callers' instruction pointers are the bytecode following their sends, and the innermost one's is the site's
	 bytecode.  Closures and temp vectors that Oil dissolved (virtual objects) are rematerialized, and a closure's
	 outerContext is the (married) context of the frame that created it.  Set the interpreter's registers to the
	 innermost frame; the caller then enters the interpreter."
	<essential: #ProfilingCogit>
	<var: #oilFP type: #'char *'>
	| theFP framesBase vobjsBase homes numVObjs chain n g k base numArgs rootMethod fr sp newFP needed vobjOops vals
	  fixAddr fixVObj numFix newPage words finalSP more vr kind obj numCopied outer ctx sitePC innermost tops fps sps |
	<var: #theFP type: #'char *'>
	<var: #sp type: #'char *'>
	<var: #newFP type: #'char *'>
	<var: #finalSP type: #'char *'>
	<var: #newPage type: #'StackPage *'>
	<var: #chain declareC: 'sqInt chain[OilMaxFrames]'>
	<var: #tops declareC: 'sqInt tops[OilMaxFrames]'>
	<var: #fps declareC: 'char *fps[OilMaxFrames]'>
	<var: #sps declareC: 'char *sps[OilMaxFrames]'>
	<var: #vals declareC: 'sqInt vals[OilNumRegs]'>
	<var: #vobjOops declareC: 'sqInt vobjOops[OilMaxVObjs]'>
	<var: #needed declareC: 'char needed[OilMaxVObjs]'>
	<var: #fixAddr declareC: 'char *fixAddr[OilNumRegs]'>
	<var: #fixVObj declareC: 'sqInt fixVObj[OilNumRegs]'>
	self cCode: [] inSmalltalk:
		[chain := CArrayAccessor on: (Array new: OilMaxFrames).
		 tops := CArrayAccessor on: (Array new: OilMaxFrames).
		 fps := CArrayAccessor on: (Array new: OilMaxFrames).
		 sps := CArrayAccessor on: (Array new: OilMaxFrames).
		 vals := CArrayAccessor on: (Array new: OilNumRegs).
		 vobjOops := CArrayAccessor on: (Array new: OilMaxVObjs).
		 needed := CArrayAccessor on: (ByteArray new: OilMaxVObjs).
		 fixAddr := CArrayAccessor on: (Array new: OilNumRegs).
		 fixVObj := CArrayAccessor on: (Array new: OilNumRegs)].
	theFP := oilFP.
	framesBase := self oilMD: md at: OilMDFrames.
	vobjsBase := self oilMD: md at: OilMDVObjs.
	homes := self oilMD: md at: OilMDHomes.
	numVObjs := self oilMD: md at: OilMDNumVObjs.
	sitePC := self oilMD: md at: site + 5.
	"1. The chain of inlined frames, root first, and the top register of each frame's part of the window."
	n := 0.
	g := self oilMD: md at: site + 4.
	[g >= 0] whileTrue:
		[n := n + 1.
		 g := self oilMD: md at: framesBase + (g * OilMDFrameSize) + 3].
	g := self oilMD: md at: site + 4.
	k := n - 1.
	[g >= 0] whileTrue:
		[chain at: k put: g.
		 k := k - 1.
		 g := self oilMD: md at: framesBase + (g * OilMDFrameSize) + 3].
	tops at: n - 1 put: (self oilMD: md at: site + 6).
	0 to: n - 2 do:
		[:i| tops at: i put: (self oilMD: md at: framesBase + ((chain at: i + 1) * OilMDFrameSize) + 2) - 1].
	"2. Make room: the interpreter frames are larger than the machine code frame."
	fr := framesBase + ((chain at: 0) * OilMDFrameSize).
	words := 5 + (tops at: 0) - (self oilMD: md at: fr + 7).
	1 to: n - 1 do:
		[:i|
		fr := framesBase + ((chain at: i) * OilMDFrameSize).
		words := words + 8 + (tops at: i) - (self oilMD: md at: fr + 2)].
	finalSP := theFP - (words * objectMemory wordSize).
	(finalSP < (stackPage realStackLimit + (LargeContextSlots * objectMemory bytesPerOop))
	 and: [(self isBaseFrame: theFP) not]) ifTrue:
		[self setHeadFP: framePointer andSP: stackPointer inPage: stackPage.
		 self ensureCallerContext: theFP.
		 newPage := stackPages newStackPage.
		 theFP := self moveFramesIn: stackPage through: theFP toPage: newPage.
		 self setStackPageAndLimit: newPage.
		 self setStackPointersFromPage: newPage.
		 self assert: theFP = framePointer].
	"3. Read the virtual registers from their homes before the frame is overwritten."
	0 to: OilNumRegs - 1 do:
		[:r|
		vals at: r put: ((self oilMD: md at: homes + r) = 0
							ifTrue: [objectMemory nilObject]
							ifFalse: [stackPages longAt: theFP + (self oilMD: md at: homes + r)])].
	0 to: OilMaxVObjs - 1 do:
		[:i| vobjOops at: i put: 0. needed at: i put: 0].
	numFix := 0.
	"4. Convert the root frame in place, then push the inlined frames.  Slots holding virtual objects are
	    written later (fixAddr/fixVObj), once the objects and the contexts they refer to exist."
	fr := framesBase + ((chain at: 0) * OilMDFrameSize).
	rootMethod := objectMemory fetchPointer: fr ofObject: md.
	numArgs := self oilMD: md at: fr + 7.
	stackPages
		longAt: theFP + FoxIFrameFlags
			put: (self encodeFrameFieldHasContext: (self mframeHasContext: theFP) isBlock: false numArgs: numArgs);
		longAt: theFP + FoxMethod put: rootMethod;
		longAt: theFP + FoxIFSavedIP put: 0;
		longAt: theFP + FoxIFReceiver put: (self oilValueAt: fr + 5 metadata: md values: vals vobjs: vobjOops).
	fps at: 0 put: theFP.
	sp := theFP + FoxIFReceiver.
	0 to: n - 1 do:
		[:i|
		fr := framesBase + ((chain at: i) * OilMDFrameSize).
		base := self oilMD: md at: fr + 2.
		numArgs := self oilMD: md at: fr + 7.
		i > 0 ifTrue:
			["The stacked receiver (the closure, for a block) and the arguments, on the caller's stack."
			 base to: base + numArgs do:
				[:r|
				sp := sp - objectMemory wordSize.
				numFix := self oilStore: (self oilDescriptorIndex: r site: site metadata: md) at: sp metadata: md values: vals vobjs: vobjOops needed: needed fixAddr: fixAddr fixVObj: fixVObj numFix: numFix].
			 "The caller's instruction pointer: the bytecode after the send (pre-incremented)."
			 sp := sp - objectMemory wordSize.
			 stackPages
				longAt: sp
				put: (objectMemory fetchPointer: framesBase + ((chain at: i - 1) * OilMDFrameSize) ofObject: md)
					+ objectMemory baseHeaderSize
					+ (self oilMD: md at: fr + 4)
					- 1.
			 sp := sp - objectMemory wordSize.
			 stackPages longAt: sp put: (fps at: i - 1) asUnsignedInteger.
			 newFP := sp.
			 fps at: i put: newFP.
			 sp := sp - objectMemory wordSize.
			 stackPages longAt: sp put: (objectMemory fetchPointer: fr ofObject: md).
			 sp := sp - objectMemory wordSize.
			 stackPages longAt: sp put: objectMemory nilObject.
			 sp := sp - objectMemory wordSize.
			 stackPages longAt: sp put: (self encodeFrameFieldHasContext: false isBlock: (self oilMD: md at: fr + 1) ~= 0 numArgs: numArgs).
			 sp := sp - objectMemory wordSize.
			 stackPages longAt: sp put: 0.
			 sp := sp - objectMemory wordSize.
			 self assert: sp = (newFP + FoxIFReceiver).
			 numFix := self oilStore: fr + 5 at: sp metadata: md values: vals vobjs: vobjOops needed: needed fixAddr: fixAddr fixVObj: fixVObj numFix: numFix].
		"The temps (after the arguments) and the stack of the frame."
		base + numArgs + 1 to: (tops at: i) do:
			[:r|
			sp := sp - objectMemory wordSize.
			numFix := self oilStore: (self oilDescriptorIndex: r site: site metadata: md) at: sp metadata: md values: vals vobjs: vobjOops needed: needed fixAddr: fixAddr fixVObj: fixVObj numFix: numFix].
		sps at: i put: sp].
	"5. The virtual objects needed, transitively (a closure's receiver and copied values, a temp vector's slots)."
	more := true.
	[more] whileTrue:
		[more := false.
		 0 to: numVObjs - 1 do:
			[:i|
			(needed at: i) = 1 ifTrue:
				[needed at: i put: 2.
				 more := true.
				 vr := vobjsBase + (i * OilMDVObjSize).
				 (self oilMD: md at: vr) = OilDescBlock
					ifTrue:
						[self oilNeedVObjAt: vr + 3 metadata: md needed: needed.
						 0 to: (self oilMD: md at: vr + 5) - 1 do:
							[:j| self oilNeedVObjAt: (self oilMD: md at: vr + 6) + (2 * j) metadata: md needed: needed]]
					ifFalse:
						[0 to: (self oilMD: md at: vr + 1) - 1 do:
							[:j| self oilNeedVObjAt: (self oilDescriptorIndex: (self oilMD: md at: vr + 7) + j site: site metadata: md) metadata: md needed: needed]]]]].
	"6. Allocate them (no GC can happen here: allocation at worst schedules a scavenge)..."
	0 to: numVObjs - 1 do:
		[:i|
		(needed at: i) ~= 0 ifTrue:
			[vr := vobjsBase + (i * OilMDVObjSize).
			 kind := self oilMD: md at: vr.
			 obj := kind = OilDescBlock
					ifTrue:
						[objectMemory
							allocateSlots: FullClosureFirstCopiedValueIndex + (self oilMD: md at: vr + 5)
							format: objectMemory indexablePointersFormat
							classIndex: ClassFullBlockClosureCompactIndex]
					ifFalse:
						[objectMemory
							allocateSlots: (self oilMD: md at: vr + 1)
							format: objectMemory arrayFormat
							classIndex: ClassArrayCompactIndex].
			 self assert: obj notNil.
			 objectMemory fillObj: obj numSlots: (objectMemory numSlotsOf: obj) with: objectMemory nilObject.
			 vobjOops at: i put: obj]].
	"...then fill them in.  A closure's outerContext is the context of the frame that created it, if on the chain."
	0 to: numVObjs - 1 do:
		[:i|
		(needed at: i) ~= 0 ifTrue:
			[vr := vobjsBase + (i * OilMDVObjSize).
			 obj := vobjOops at: i.
			 (self oilMD: md at: vr) = OilDescBlock
				ifTrue:
					[outer := self oilMD: md at: vr + 2.
					 ctx := objectMemory nilObject.
					 0 to: n - 1 do:
						[:j| (chain at: j) = outer ifTrue:
							[ctx := self ensureFrameIsMarried: (fps at: j) SP: (sps at: j)]].
					 numCopied := self oilMD: md at: vr + 5.
					 objectMemory
						storePointer: ClosureOuterContextIndex ofObject: obj withValue: ctx;
						storePointer: FullClosureCompiledBlockIndex ofObject: obj withValue: (objectMemory fetchPointer: vr + 1 ofObject: md);
						storePointer: ClosureNumArgsIndex ofObject: obj withValue: (objectMemory integerObjectOf: (self argumentCountOf: (objectMemory fetchPointer: vr + 1 ofObject: md)));
						storePointer: FullClosureReceiverIndex ofObject: obj withValue: (self oilValueAt: vr + 3 metadata: md values: vals vobjs: vobjOops).
					 0 to: numCopied - 1 do:
						[:j|
						objectMemory
							storePointer: FullClosureFirstCopiedValueIndex + j
							ofObject: obj
							withValue: (self oilValueAt: (self oilMD: md at: vr + 6) + (2 * j) metadata: md values: vals vobjs: vobjOops)]]
				ifFalse:
					[0 to: (self oilMD: md at: vr + 1) - 1 do:
						[:j|
						objectMemory
							storePointer: j
							ofObject: obj
							withValue: (self oilValueAt: (self oilDescriptorIndex: (self oilMD: md at: vr + 7) + j site: site metadata: md) metadata: md values: vals vobjs: vobjOops)]]]].
	0 to: numFix - 1 do:
		[:i| stackPages longAt: (fixAddr at: i) put: (vobjOops at: (fixVObj at: i))].
	"7. Continue in the innermost frame, at the site's bytecode."
	innermost := objectMemory fetchPointer: framesBase + ((chain at: n - 1) * OilMDFrameSize) ofObject: md.
	framePointer := fps at: n - 1.
	stackPointer := sp.
	instructionPointer := innermost + objectMemory baseHeaderSize + sitePC - 1.
	self setMethod: innermost! !

!CoInterpreter methodsFor: '*Cogit-Oil-initialization' stamp: 'cb 10/24/2026 19:15'!
checkImageHeaderLoad
	<inline: #always>
	cogCodeSize < (4 * 1024 * 1024) ifTrue:
		[cogCodeSize := 4 * 1024 * 1024]! !

!CoInterpreter methodsFor: '*Cogit-Oil-initialization' stamp: 'cb 10/24/2026 15:00'!
attemptToSwitchToMachineCode: bcpc
	"Attempt to convert the current interpreted activation into a machine code
	 activation, and if this is popssible, jump into machine code.  bcpc is the
	 0-relative pc of the backward branch bytecode (not any preceding extension).
	 An Oil method's machine code does not correspond to its bytecodes: stay in the interpreter."
	| cogMethod pc cls |
	<inline: false>
	<var: #cogMethod type: #'CogMethod *'>
	((self methodHasCogMethod: method)
	 and: [cogit isOilMethod: (self cogMethodOf: method)]) ifTrue:
		[^nil].
	(self methodHasCogMethod: method)
		ifFalse: 
			[SistaV1BytecodeSet
				ifTrue: 
					[ ((self iframeIsBlockActivation: framePointer) 
					   and: [(self isVanillaBlockClosure: (cls := self frameStackedReceiver: framePointer numArgs: (self frameNumArgs: framePointer))) not ])
						ifTrue: 
							["Compiled block / full closure"
							 cogit cogFullBlockMethod: method numCopied: (objectMemory numPointerSlotsOf: cls) - FullClosureFirstCopiedValueIndex]
						ifFalse: 
							["Compiled method"
							cogit cog: method selector: objectMemory nilObject] ]
				ifFalse: 
					[cogit cog: method selector: objectMemory nilObject] ].
	(self methodHasCogMethod: method) ifTrue:
		[cogMethod := self cogMethodOf: method.
		 pc := self convertToMachineCodeFrame: cogMethod bcpc: bcpc.
		 self assertValidMachineCodeFrame: pc.
		 self push: pc.
		 self push: objectMemory nilObject.
		 cogit ceEnterCogCodePopReceiverReg]! !


!CoInterpreterPrimitives methodsFor: '*Cogit-Oil-primitives' stamp: 'cb 10/24/2026 15:00'!
primitiveOilCompile
	"Receiver: a CompiledMethod; argument: the class of the receivers to specialize it for.
	 Compile the method with the Oil optimizing JIT and install the result as its machine code, replacing any
	 baseline machine code.  The inline caches of the baseline machine code (and of the methods and blocks it
	 calls) are the type feedback, so run the method first.  Answer a SmallInteger, 0 (OilOK) on success, else an
	 Oil failure code (see OilConstants), in which case the method is left as it was."
	<export: true>
	<essential: #ProfilingCogit>
	| methodObj classObj result activeContext theFrame thePage |
	argumentCount ~= 1 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	methodObj := self stackValue: 1.
	classObj := self stackTop.
	((objectMemory isNonImmediate: methodObj)
	 and: [(objectMemory isOopCompiledMethod: methodObj)
	 and: [(self isFullBlockMethod: methodObj) not
	 and: [objectMemory isNonImmediate: classObj]]]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	((self methodHasCogMethod: methodObj)
	 and: [cogit isOilMethod: (self cogMethodOf: methodObj)]) ifTrue:
		[^self pop: 2 thenPush: (objectMemory integerObjectOf: OilOK)].
	"Pass 1 first, while the baseline inline caches (type feedback) are there."
	result := cogit oilCompile: methodObj receiverClass: classObj.
	result ~= OilOK ifTrue:
		[^self pop: 2 thenPush: (objectMemory integerObjectOf: result)].
	"Free the baseline machine code (c.f. primitiveVoidVMStateForMethod), then run Pass 3 and install."
	self flushMethodCacheForMethod: methodObj.
	activeContext := self ensureFrameIsMarried: framePointer SP: stackPointer.
	self ensurePushedInstructionPointer.
	self externalWriteBackHeadFramePointers.
	(self methodHasCogMethod: methodObj) ifTrue:
		[self divorceMachineCodeFramesWithMethod: methodObj.
		 self ensureAllContextsWithMethodHaveBytecodePCs: methodObj.
		 cogit unlinkSendsTo: methodObj andFreeIf: true].
	result := cogit oilGenerate: methodObj.
	"If flushing led to divorce continue in the interpreter."
	(self isStillMarriedContext: activeContext) ifFalse:
		[self nilStackPage. "to avoid assert in marryContextInNewStackPageAndInitializeInterpreterRegisters:"
		 self marryContextInNewStackPageAndInitializeInterpreterRegisters: activeContext.
		 self popStack. "pop bogus machine-code instructionPointer"
		 self pop: argumentCount + 1 thenPush: (objectMemory integerObjectOf: result).
		 cogit ceInvokeInterpret
		 "NOTREACHED"].
	"If not, work out where we are and continue"
	theFrame := self frameOfMarriedContext: activeContext.
	thePage := stackPages stackPageFor: theFrame.
	self assert: thePage headFP = theFrame.
	self setStackPageAndLimit: thePage.
	self setStackPointersFromPage: thePage.
	instructionPointer := self popStack.
	self pop: argumentCount + 1 thenPush: (objectMemory integerObjectOf: result)! !

!CoInterpreterPrimitives methodsFor: '*Cogit-Oil-primitives' stamp: 'cb 10/24/2026 15:00'!
primitiveOilSetSelectors
	"Argument: an Array of pairs kind, selector telling the Oil compiler which selectors it treats specially
	 (0-4: value, value:, ... by arity; 5: bitXor:; 6: iterators to inline; 7: cold selectors never inlined;
	 8 with a SmallInteger: the number of deoptimizations after which an Oil method is disqualified).
	 Answer the previous Array, or nil."
	<export: true>
	<essential: #ProfilingCogit>
	| previous sels |
	argumentCount ~= 1 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	sels := self stackTop.
	((objectMemory isNonImmediate: sels)
	 and: [objectMemory isArrayNonImm: sels]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	"The Oil selector table (see ProfilingCogit>>oilExtraSelectorIndexOf:add:), allocated once."
	cogit getOilExtraSelectors = 0 ifTrue:
		[| table |
		 table := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: OilMaxExtraSelectors.
		 table isNil ifTrue:
			[^self primitiveFailFor: PrimErrNoMemory].
		 cogit setOilExtraSelectors: table.
		 (objectMemory addGCRoot: cogit oilExtraSelectorsAddress) ifFalse:
			[cogit setOilExtraSelectors: 0.
			 ^self primitiveFailFor: PrimErrNoMemory]].
	previous := cogit getOilSelectors.
	cogit setOilSelectors: sels.
	previous = 0 ifTrue:
		[(objectMemory addGCRoot: cogit oilSelectorsAddress) ifFalse:
			[cogit setOilSelectors: 0.
			 ^self primitiveFailFor: PrimErrNoMemory].
		 previous := objectMemory nilObject].
	self pop: 2 thenPush: previous! !

!CoInterpreterPrimitives methodsFor: '*Cogit-Oil-primitives' stamp: 'cb 10/24/2026 15:00'!
primitiveOilMethodInfo
	"Receiver: a CompiledMethod.  If its machine code was compiled by Oil answer
	 { number of deoptimizations. number of bailouts resumed by the unforwarding fast path.
	   the machine code (a ByteArray, from the CogMethod header to the end of the code). its address }
	 otherwise answer nil."
	<export: true>
	<essential: #ProfilingCogit>
	| methodObj cogMethod md code result size |
	<var: #cogMethod type: #'CogMethod *'>
	methodObj := self stackTop.
	((objectMemory isNonImmediate: methodObj)
	 and: [objectMemory isOopCompiledMethod: methodObj]) ifFalse:
		[^self primitiveFailFor: PrimErrBadReceiver].
	((self methodHasCogMethod: methodObj)
	 and: [cogit isOilMethod: (self cogMethodOf: methodObj)]) ifFalse:
		[^self pop: argumentCount + 1 thenPush: objectMemory nilObject].
	cogMethod := self cogMethodOf: methodObj.
	size := cogMethod blockSize.
	code := objectMemory instantiateClass: (objectMemory splObj: ClassByteArray) indexableSize: size.
	result := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: 4.
	(code isNil or: [result isNil]) ifTrue:
		[^self primitiveFailFor: PrimErrNoMemory].
	"Allocation neither moves objects nor frees machine code."
	0 to: size - 1 do:
		[:i| objectMemory storeByte: i ofObject: code withValue: (objectMemory byteAt: cogMethod asUnsignedInteger + i)].
	md := cogit oilMetadataOf: cogMethod.
	objectMemory
		storePointerUnchecked: 0 ofObject: result withValue: (objectMemory fetchPointer: OilMDDeopts ofObject: md);
		storePointerUnchecked: 1 ofObject: result withValue: (objectMemory fetchPointer: OilMDFastPaths ofObject: md);
		storePointer: 2 ofObject: result withValue: code;
		storePointerUnchecked: 3 ofObject: result withValue: (objectMemory integerObjectOf: cogMethod asUnsignedInteger).
	self pop: argumentCount + 1 thenPush: result! !

!CoInterpreterPrimitives methodsFor: '*Cogit-Oil-primitives' stamp: 'cb 10/24/2026 15:00'!
primitiveOilLastCompilation
	"Answer an Array describing the last Oil compilation, for debugging:
	 { failure code. IR words (an Array of SmallIntegers). eager closures (0/1). IR index the back end failed at.
	   number of deopt sites. number of inlined frames. number of homes. number of allocated registers. nil.
	   Pass 1 IR words. Pass 2 statistics (see OilCompiler>>pass2Statistics:) }"
	<export: true>
	<essential: #ProfilingCogit>
	| n irArray result statsArray |
	n := cogit oilDebugInfo: 1 at: 0.
	irArray := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: n.
	result := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: 11.
	(irArray isNil or: [result isNil]) ifTrue:
		[^self primitiveFailFor: PrimErrNoMemory].
	0 to: n - 1 do:
		[:i| objectMemory storePointerUnchecked: i ofObject: irArray withValue: (objectMemory integerObjectOf: (cogit oilDebugInfo: 2 at: i))].
	objectMemory
		storePointerUnchecked: 0 ofObject: result withValue: (objectMemory integerObjectOf: (cogit oilDebugInfo: 0 at: 0));
		storePointer: 1 ofObject: result withValue: irArray.
	2 to: 7 do:
		[:i| objectMemory storePointerUnchecked: i ofObject: result withValue: (objectMemory integerObjectOf: (cogit oilDebugInfo: i + 1 at: 0))].
	objectMemory storePointerUnchecked: 8 ofObject: result withValue: objectMemory nilObject.
	"Pass 1's IR (Buffer 1; the IR above is Pass 2's) and Pass 2's statistics."
	n := cogit oilDebugInfo: 11 at: 0.
	irArray := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: n.
	irArray isNil ifTrue: [^self primitiveFailFor: PrimErrNoMemory].
	0 to: n - 1 do:
		[:i| objectMemory storePointerUnchecked: i ofObject: irArray withValue: (objectMemory integerObjectOf: (cogit oilDebugInfo: 12 at: i))].
	objectMemory storePointer: 9 ofObject: result withValue: irArray.
	statsArray := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: 8.
	statsArray isNil ifTrue: [^self primitiveFailFor: PrimErrNoMemory].
	0 to: 7 do:
		[:i| objectMemory storePointerUnchecked: i ofObject: statsArray withValue: (objectMemory integerObjectOf: (cogit oilDebugInfo: 13 at: i))].
	objectMemory storePointer: 10 ofObject: result withValue: statsArray.
	self pop: argumentCount + 1 thenPush: result! !

!CoInterpreter methodsFor: '*Cogit-Oil' stamp: 'cb 10/24/2026 18:00'!
oilHeaderWithLargeContext: methodHeader
	<api>
	<essential: #ProfilingCogit>
	^methodHeader bitOr: LargeContextBit! !

!CoInterpreter methodsFor: '*Cogit-Oil' stamp: 'cb 10/24/2026 18:00'!
oilHeaderWithoutLargeContext: methodHeader
	<api>
	<essential: #ProfilingCogit>
	^methodHeader bitAnd: LargeContextBit bitInvert! !


