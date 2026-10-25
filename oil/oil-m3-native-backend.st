"The native back end of the Oil optimizing JIT, its deopt stubs and the deoptimizer.
 - ProfilingCogit drives the compilation of an Oil method (oilCompile:receiverClass: runs Pass 1, oilGenerate: runs
   Pass 3 and builds the CogMethod and its deoptimization metadata) and owns ceOilDeoptTrampoline.
 - CoInterpreter>>ceOilDeoptimize: is the deoptimizer: on a failed guard it either unforwards and resumes the machine code
   (fast path), or rebuilds the interpreter frames of the method and of everything inlined into it at the guard,
   rematerializing the closures and temp vectors Oil dissolved, and continues in the interpreter.
 - primitiveOilCompile, primitiveOilSetSelectors and primitiveOilMethodInfo are the image's interface.
 Author: cb."!

(CoInterpreter sharedPools includes: OilInstructionConstants) ifFalse:
	[CoInterpreter addSharedPool: OilInstructionConstants]!
(CoInterpreter sharedPools includes: OilConstants) ifFalse:
	[CoInterpreter addSharedPool: OilConstants]!

(CogObjectRepresentationFor64BitSpur sharedPools includes: OilInstructionConstants) ifFalse:
	[CogObjectRepresentationFor64BitSpur addSharedPool: OilInstructionConstants]!
(CogObjectRepresentationFor64BitSpur sharedPools includes: OilConstants) ifFalse:
	[CogObjectRepresentationFor64BitSpur addSharedPool: OilConstants]!

(ProfilingCogit sharedPools includes: OilInstructionConstants) ifFalse:
	[ProfilingCogit addSharedPool: OilInstructionConstants]!
(ProfilingCogit sharedPools includes: OilConstants) ifFalse:
	[ProfilingCogit addSharedPool: OilConstants]!

!Cogit methodsFor: '*VMMaker-JIT-Oil' stamp: 'cb 10/24/2026 15:00'!
isOilMethod: cogMethod
	"Answer whether cogMethod was compiled by the Oil optimizing JIT (see ProfilingCogit).
	 Oil methods' machine code does not correspond to their bytecodes, so the interpreter must not
	 map bytecode pcs into them."
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	^false! !

!CogBlockMethod methodsFor: '*VMMaker-JIT-Oil' stamp: 'cb 10/24/2026 18:00'!
cmUnusedFlag
	"Oil methods: whether Oil set the large context bit of the method header (see ProfilingCogit>>oilGenerateCogMethod)."
	^cmUnusedFlag! !

!CogBlockMethod methodsFor: '*VMMaker-JIT-Oil' stamp: 'cb 10/24/2026 18:00'!
cmUnusedFlag: aValue
	^cmUnusedFlag := aValue! !

!CogObjectRepresentationForSpur methodsFor: '*VMMaker-JIT-Oil' stamp: 'cb 10/24/2026 15:00'!
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
	oilSpecializations := 0.
	oilKeepSpecializations := false.
	cogMethodSurrogateClass := (objectMemory ifNil: [self class objectMemoryClass]) wordSize = 4
										ifTrue: [CogSistaMethodSurrogate32]
										ifFalse: [CogSistaMethodSurrogate64]! !

!ProfilingCogit methodsFor: 'initialization' stamp: 'cb 10/25/2026 01:50'!
generateRunTimeTrampolines
	"Add the trampoline called when a trip counter reaches zero (it passes the kind of site, OilTripBackJump or
	 OilTripBlockEntry, in SendNumArgsReg to ceOilTrip:, and preserves ReceiverResultReg, which may hold self),
	 and the trampoline called by the deopt sequence of Oil methods (it passes the deopt site index in
	 SendNumArgsReg to ceOilDeoptimize:, which answers the address to resume at in TempReg, unless it deoptimizes,
	 in which case it does not return)."
	super generateRunTimeTrampolines.
	"Let large (e.g. parser) methods get machine code, hence inline caches for Oil (the default limit is 60 literals)."
	coInterpreter oilRaiseMaxLiteralCountForCompile.
	ceOilTripTrampoline := self genTrampolineFor: #ceOilTrip:
								called: 'ceOilTripTrampoline'
								arg: SendNumArgsReg
								regsToSave: (self registerMaskFor: ReceiverResultReg).
	ceOilDeoptTrampoline := self genTrampolineFor: #ceOilDeoptimize:
								called: 'ceOilDeoptTrampoline'
								arg: SendNumArgsReg
								result: TempReg! !


!ProfilingCogit methodsFor: 'oil code generation' stamp: 'cb 10/25/2026 00:30'!
oilGenDeoptCall
	"See OilCompiler>>genDeoptStubs."
	^self CallRT: ceOilDeoptTrampoline! !

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

!ProfilingCogit methodsFor: 'oil code generation' stamp: 'cb 10/25/2026 03:00'!
oilGenGetHashOf: objReg into: destReg
	"The identity hash in the header of the non-immediate in objReg, as a SmallInteger (0 if it has none yet).
	 See OilCompiler>>genIdentityHashAt:."
	^objectRepresentation genGetHashFieldNonImmOf: objReg asSmallIntegerInto: destReg! !

!ProfilingCogit methodsFor: 'oil code generation' stamp: 'cb 10/25/2026 02:00'!
oilGenGetSmallFloatValueOf: oopReg scratch: scratchReg into: dpReg
	"The double value of the SmallFloat64 in oopReg (see OilCompiler>>genLoadDouble:into:ints:site:)."
	^objectRepresentation genGetSmallFloatValueOf: oopReg scratch: scratchReg into: dpReg! !

!ProfilingCogit methodsFor: 'oil code generation' stamp: 'cb 10/25/2026 02:00'!
oilGenJumpNotSmallFloatValueBits: reg scratch: scratchReg
	"Answer a jump taken if the double bits in reg are out of the SmallFloat64 range (see OilCompiler>>genBoxDouble:into:site:)."
	<returnTypeC: #'AbstractInstruction *'>
	^objectRepresentation genJumpNotSmallFloatValueBits: reg scratch: scratchReg! !

!ProfilingCogit methodsFor: 'oil code generation' stamp: 'cb 10/25/2026 02:00'!
oilGenConvertBitsToSmallFloatIn: reg scratch: scratchReg
	"Convert the in range double bits in reg into a SmallFloat64."
	^objectRepresentation genConvertBitsToSmallFloatIn: reg scratch: scratchReg! !

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
	| pairs numSlots kind selector |
	self resetSelectorRegistry.
	self oilDisqualifyLimit: 0.
	self oilResetUnrollParameters.
	pairs := oilSelectors.
	(pairs = 0 or: [pairs = objectMemory nilObject]) ifTrue: [^self].
	(objectMemory isForwarded: pairs) ifTrue:
		[pairs := objectMemory followForwarded: pairs.
		 oilSelectors := pairs].
	numSlots := objectMemory numSlotsOf: pairs.
	0 to: numSlots - 2 by: 2 do:
		[:i|
		kind := objectMemory fetchPointer: i ofObject: pairs.
		selector := objectMemory fetchPointer: i + 1 ofObject: pairs.
		((objectMemory isIntegerObject: kind) and: [objectMemory isNonImmediate: selector]) ifTrue:
			[(objectMemory isForwarded: selector) ifTrue: [selector := objectMemory followForwarded: selector].
			 self registerSelector: selector kind: (objectMemory integerValueOf: kind)].
		"kind 8: the number of deoptimizations after which an Oil method is disqualified (default OilDisqualifyDeopts)"
		(kind = (objectMemory integerObjectOf: 8) and: [objectMemory isIntegerObject: selector]) ifTrue:
			[self oilDisqualifyLimit: (objectMemory integerValueOf: selector)].
		"kinds 12 to 18: the loop unrolling parameters (see OilLoopOptimizer>>oilUnrollParameter:value:)"
		((objectMemory isIntegerObject: kind)
		 and: [((objectMemory integerValueOf: kind) between: 12 and: 18)
		 and: [objectMemory isIntegerObject: selector]]) ifTrue:
			[self oilUnrollParameter: (objectMemory integerValueOf: kind) value: (objectMemory integerValueOf: selector)]]! !

!ProfilingCogit methodsFor: 'oil compilation' stamp: 'cb 10/24/2026 19:35'!
oilMethod: aMethodObj receiverClass: classObj
	"Compile aMethodObj with the Oil optimizing JIT for receivers of class classObj
	 and answer the resulting CogMethod, or nil if compilation fails."
	<api>
	<option: #ProfilingCogit>
	<returnTypeC: #'CogMethod *'>
	(self oilCompile: aMethodObj receiverClass: classObj) ~= OilOK ifTrue: [^nil].
	(self oilGenerate: aMethodObj) ~= OilOK ifTrue: [^nil].
	^coInterpreter cogMethodOf: aMethodObj! !

!ProfilingCogit methodsFor: 'oil compilation' stamp: 'cb 10/24/2026 15:00'!
oilCompile: aMethodObj receiverClass: classObj
	"Run Pass 1 of Oil (inlining, linear IR, deopt states) on aMethodObj for receivers of class classObj.  This must
	 happen while the inline caches of the baseline machine code (the type feedback) are still there.
	 Answer OilOK or a failure code; see oilGenerate: for Pass 3."
	<api>
	<option: #ProfilingCogit>
	| start result |
	start := coInterpreter ioUTCMicrosecondsNow.
	self oilRegisterSelectors.
	result := (self compileMethod: aMethodObj receiverClass: classObj)
				ifTrue: [OilOK]
				ifFalse: [self oilFailureCode].
	oilCompileMicroseconds := coInterpreter ioUTCMicrosecondsNow - start.
	^result! !

!ProfilingCogit methodsFor: 'oil compilation' stamp: 'cb 10/24/2026 19:35'!
oilGenerate: aMethodObj
	"Run the optimization pipeline (#pipe) and Pass 3 of Oil on the IR just produced by oilCompile:receiverClass:
	 and install the resulting CogMethod as aMethodObj's machine code, which must have none.
	 Answer OilOK or a failure code.  oilCompileMicroseconds is then the time both took.
	 N.B. Like cog:selector: this never reclaims the method zone (it calls for a compaction if it is full)."
	<api>
	<option: #ProfilingCogit>
	| start result |
	start := coInterpreter ioUTCMicrosecondsNow.
	result := self oilGenerateCode: aMethodObj.
	oilCompileMicroseconds := oilCompileMicroseconds + (coInterpreter ioUTCMicrosecondsNow - start).
	^result! !

!ProfilingCogit methodsFor: 'oil compilation' stamp: 'cb 10/24/2026 19:35'!
oilGenerateCode: aMethodObj
	"See oilGenerate:."
	<option: #ProfilingCogit>
	| result estimate |
	(coInterpreter methodHasCogMethod: aMethodObj) ifTrue:
		[^OilFailInternal].
	methodObj := aMethodObj.
	methodHeader := objectMemory methodHeaderOf: aMethodObj.
	result := self pipe.
	result ~= OilOK ifTrue:
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
	oilNumMethodPICCases := 0. "(see compileEntry)"
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
	| codeSize headerSize mapSize totalSize startAddress result metadata selector added writableMethod |
	<var: #writableMethod type: #'CogMethod *'>
	metadata := coInterpreter oilAllocateMetadata: self metadataSize.
	metadata = 0 ifTrue:
		[^OilFailCodeSpace].
	headerSize := self sizeof: CogMethod.
	methodLabel address: methodZone freeStart.
	self computeMaximumSizes.
	methodLabel concretizeAt: methodZone freeStart.
	codeSize := self generateInstructionsAt: methodLabel address + headerSize.
	mapSize := self generateMapAt: nil start: methodLabel address + cmNoCheckEntryOffset.
	totalSize := methodZone roundUpLength: headerSize + codeSize + mapSize.
	totalSize > MaxMethodSize ifTrue:
		[objectMemory freeObject: metadata.
		 ^OilFailCodeSpace].
	startAddress := methodZone allocate: totalSize.
	startAddress = 0 ifTrue:
		[objectMemory freeObject: metadata.
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
	writableMethod counters: metadata + 1.
	self fillMetadata: metadata cogMethod: startAddress.
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

!ProfilingCogit methodsFor: 'oil compilation' stamp: 'cb 10/25/2026 04:00'!
getOilCompileMicroseconds
	<api>
	^oilCompileMicroseconds! !

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
	 added (no table, or the table is full)."
	| table tableSelector |
	table := oilExtraSelectors.
	(table = 0 or: [table = objectMemory nilObject]) ifTrue:
		[^OilNoLink].
	0 to: (objectMemory numSlotsOf: table) - 1 do:
		[:index|
		tableSelector := objectMemory fetchPointer: index ofObject: table.
		tableSelector = selector ifTrue:
			[^OilExtraSelectorBase + index].
		tableSelector = objectMemory nilObject ifTrue:
			[(addIfAbsent and: [objectMemory isNonImmediate: selector]) ifFalse:
				[^OilNoLink].
			 "(with the write barrier: a young selector, e.g. of a method just compiled, remembers the table)"
			 coInterpreter oilApiStorePointer: index ofObject: table withValue: selector.
			 ^OilExtraSelectorBase + index]].
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

!CogObjectRepresentationFor64BitSpur methodsFor: '*VMMaker-JIT-Oil' stamp: 'cb 10/24/2026 18:00'!
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


!ProfilingCogit methodsFor: 'in-line cacheing' stamp: 'cb 10/25/2026 09:30'!
oilPolymorphicClass: caseIndex at: bcpc in: aMethodObj
	"Type feedback for Oil's bimorphic inlining: the receiver class of case caseIndex (0 or 1) of the send at the 0-relative
	 bytecode pc bcpc of aMethodObj if its inline cache is linked to a closed PIC of exactly two cases, both to methods
	 (not to the doesNotUnderstand: entry), else 0.  c.f. SistaCogit>>populate:withPICInfoFor:firstCacheTag:"
	| mcpc entryPoint targetMethod pc cacheTag class |
	<var: #targetMethod type: #'CogMethod *'>
	(coInterpreter methodHasCogMethod: aMethodObj) ifFalse: [^0].
	mcpc := self oilSendMcpcAt: bcpc in: (coInterpreter cogMethodOf: aMethodObj).
	mcpc = 0 ifTrue: [^0].
	entryPoint := backEnd callTargetFromReturnAddress: mcpc.
	entryPoint <= methodZoneBase ifTrue: [^0].
	self targetMethodAndSendTableFor: entryPoint
		annotation: IsSendCall
		into: [:target :sendTable| targetMethod := target].
	(targetMethod isCMClosedPIC and: [targetMethod cPICNumCases = 2]) ifFalse: [^0].
	1 to: 2 do:
		[:i|
		pc := self addressOfEndOfCase: i inCPIC: targetMethod.
		entryPoint := i = 1
						ifTrue: [backEnd jumpLongTargetBeforeFollowingAddress: pc]
						ifFalse: [backEnd jumpLongConditionalTargetBeforeFollowingAddress: pc].
		(targetMethod containsAddress: entryPoint) ifTrue: [^0]]. "a case of the PIC sends doesNotUnderstand:"
	pc := self addressOfEndOfCase: caseIndex + 1 inCPIC: targetMethod.
	cacheTag := caseIndex = 0
					ifTrue: [backEnd inlineCacheTagAt: mcpc]
					ifFalse: [backEnd literal32BeforeFollowingAddress: pc - backEnd jumpLongConditionalByteSize].
	class := objectRepresentation classForInlineCacheTag: cacheTag.
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
	| metadata nFrames frames inlinedMethod |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod selector = aSelector ifTrue: [^true].
	metadata := self oilMetadataOf: cogMethod.
	nFrames := objectMemory integerValueOf: (objectMemory fetchPointer: OilMDNumFrames ofObject: metadata).
	frames := objectMemory integerValueOf: (objectMemory fetchPointer: OilMDFrames ofObject: metadata).
	0 to: nFrames - 1 do:
		[:frameIndex|
		inlinedMethod := objectMemory fetchPointer: frames + (frameIndex * OilMDFrameSize) + OilMDFrameMethod ofObject: metadata.
		(coInterpreter maybeSelectorOfMethod: inlinedMethod) = aSelector ifTrue: [^true]].
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

!ProfilingCogit class methodsFor: 'trampoline support' stamp: 'cb 10/25/2026 01:50'!
numTrampolines
	^super numTrampolines + 2 "ceOilTripTrampoline, ceOilDeoptTrampoline"! !

!ProfilingCogit class methodsFor: 'translation' stamp: 'cb 10/24/2026 19:35'!
ancilliaryClasses
	"Answer any extra classes to be included in the translation: the counters field of SistaCogMethod and
	 Oil's optimizing compiler hierarchy (scanner, base compiler, loop optimizer, full compiler)."
	^super ancilliaryClasses, {SistaCogMethod. OilBytecodeDescriptor. OilBytecodeScanner. OilInliningCompiler. OilLoopOptimizer. OilFullCompiler}! !


!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:30'!
estimateOpcodes
	"An upper bound of the number of abstract instructions oilGenerate: emits (they are allocated on the C stack)."
	| irOffset estimatedCount |
	estimatedCount := 200 + (2 * oilNumSpillTemps) + (4 * numSites) + (4 * OilMaxReg // 16).
	irOffset := 0.
	[irOffset < irIndex] whileTrue:
		[estimatedCount := estimatedCount + (self estimateOpcodesOfInstructionAt: irOffset).
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^estimatedCount + (4 * oilNumAllocRegs) + (3 * OilMaxUndos)! !

!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 15:00'!
estimateOpcodesOfInstructionAt: irOffset
	"An upper bound of the number of abstract instructions generated for the IR instruction at irOffset."
	| opcode |
	opcode := self opcodeAt: irOffset.
	(self isSendOpcode: opcode) ifTrue: [^48 + (2 * (self fieldCAt: irOffset))].
	(opcode = OilStoreField or: [opcode = OilStoreElement]) ifTrue: [^48].
	(opcode = OilNewArray or: [opcode = OilMakeClosure or: [opcode = OilNewObject]]) ifTrue:
		[^40 + (2 * (self fieldCAt: irOffset)) + (2 * OilMaxReg // 16)].
	(opcode = OilStreamNext or: [opcode = OilStreamNextPut or: [opcode = OilCompareBytes]]) ifTrue: [^140].
	opcode = OilStringHash ifTrue: [^100].
	opcode = OilIdentityHash ifTrue: [^60].
	(opcode = OilIndexOfByte or: [opcode = OilSkipSeparators]) ifTrue: [^160 + (4 * oilNumAllocRegs)].
	^20! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/25/2026 00:30'!
metadataSize
	"The number of slots of the deoptimization metadata (see fillMetadata:cogMethod:)."
	| totalSlots |
	totalSlots := OilMDHeaderSize + (numFrames * OilMDFrameSize) + (numVObjs * OilMDVObjSize) + (capturedTop * 2) + OilNumRegs + numSites.
	0 to: numSites - 1 do:
		[:siteIndex| (oilSiteUsed at: siteIndex) ~= 0 ifTrue:
			[totalSlots := totalSlots + OilMDSiteHeaderSize + (2 * (self siteStateSize: siteIndex))]].
	^totalSlots! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/24/2026 15:00'!
metadata: metadata at: index put: value
	<inline: true>
	objectMemory storePointer: index ofObject: metadata withValue: value! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/24/2026 15:00'!
metadata: metadata at: index putInt: value
	<inline: true>
	objectMemory storePointer: index ofObject: metadata withValue: (objectMemory integerObjectOf: value)! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/24/2026 15:00'!
metadata: metadata at: index putKind: kind value: value
	"A descriptor: its kind and its value, an object for a constant, a SmallInteger (register or virtual object) otherwise."
	self metadata: metadata at: index putInt: kind.
	kind = OilDescConst
		ifTrue: [self metadata: metadata at: index + 1 put: value]
		ifFalse: [self metadata: metadata at: index + 1 putInt: value]! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/24/2026 15:00'!
fillMetadata: metadata cogMethod: cogMethodAddress
	"Fill in the deoptimization metadata of the Oil method at cogMethodAddress, a hidden pinned Array:
	 header (OilMD*), the inlined frames, the virtual objects (dissolved closures and temp vectors) and their
	 captured values, the home slot (frame offset) of every virtual register, a table from deopt site index to
	 site record, and the records of the sites used by the deopt stubs: kind, the guarded register and class
	 tag (for the unforwarding fast path), the offset of the instruction to resume at, the inlined frame and
	 bytecode pc, and the virtual state (descriptors of the register window and of the high registers)."
	<var: #cogMethodAddress type: #usqInt>
	| frames vobjs captured homes siteTable index frameRecord vobjRecord poolBase opcode parentFrame |
	frames := OilMDHeaderSize.
	vobjs := frames + (numFrames * OilMDFrameSize).
	captured := vobjs + (numVObjs * OilMDVObjSize).
	homes := captured + (capturedTop * 2).
	siteTable := homes + OilNumRegs.
	self metadata: metadata at: OilMDVersion putInt: OilMDMagic.
	self metadata: metadata at: OilMDRootMethod put: oilHomeMethod.
	self metadata: metadata at: OilMDNumSites putInt: numSites.
	self metadata: metadata at: OilMDSiteTable putInt: siteTable.
	self metadata: metadata at: OilMDNumFrames putInt: numFrames.
	self metadata: metadata at: OilMDFrames putInt: frames.
	self metadata: metadata at: OilMDNumVObjs putInt: numVObjs.
	self metadata: metadata at: OilMDVObjs putInt: vobjs.
	self metadata: metadata at: OilMDHomes putInt: homes.
	self metadata: metadata at: OilMDDeopts putInt: 0.
	self metadata: metadata at: OilMDFastPaths putInt: 0.
	self metadata: metadata at: OilMDNumArgs putInt: (self numArgsOf: oilHomeMethod).
	self metadata: metadata at: OilMDCaptured putInt: captured.
	0 to: numFrames - 1 do:
		[:frameIndex|
		frameRecord := frames + (frameIndex * OilMDFrameSize).
		parentFrame := frameParent at: frameIndex.
		self metadata: metadata at: frameRecord + OilMDFrameMethod put: (frameMethod at: frameIndex).
		self metadata: metadata at: frameRecord + OilMDFrameIsBlock putInt: ((frameIsBlock at: frameIndex) ifTrue: [1] ifFalse: [0]).
		self metadata: metadata at: frameRecord + OilMDFrameBase putInt: (frameBase at: frameIndex).
		self metadata: metadata at: frameRecord + OilMDFrameParent putInt: parentFrame.
		parentFrame < 0
			ifTrue: [self metadata: metadata at: frameRecord + OilMDFrameReturnPC putInt: -1]
			ifFalse: "the pc after the send that the frame was inlined at"
				[self setScanMethod: (frameMethod at: parentFrame).
				 self decodeAt: (frameCallPC at: frameIndex).
				 self metadata: metadata at: frameRecord + OilMDFrameReturnPC putInt: oilNextPC].
		self metadata: metadata at: frameRecord + OilMDFrameSelf putKind: (frameSelfKind at: frameIndex) value: (frameSelfValue at: frameIndex).
		self metadata: metadata at: frameRecord + OilMDFrameNumArgs putInt: (self numArgsOf: (frameMethod at: frameIndex))].
	0 to: numVObjs - 1 do:
		[:vobjIndex|
		vobjRecord := vobjs + (vobjIndex * OilMDVObjSize).
		self metadata: metadata at: vobjRecord + OilMDVObjKind putInt: (vobjKind at: vobjIndex).
		(vobjKind at: vobjIndex) = OilDescBlock
			ifTrue:
				[self metadata: metadata at: vobjRecord + OilMDVObjLiteralOrSize put: (vobjLiteral at: vobjIndex).
				 self metadata: metadata at: vobjRecord + OilMDVObjOuterFrame putInt: (vobjOuter at: vobjIndex).
				 self metadata: metadata at: vobjRecord + OilMDVObjSelf putKind: (vobjSelfKind at: vobjIndex) value: (vobjSelfValue at: vobjIndex).
				 self metadata: metadata at: vobjRecord + OilMDVObjNumCopied putInt: (vobjNumCopied at: vobjIndex).
				 self metadata: metadata at: vobjRecord + OilMDVObjCopiedIndex putInt: captured + (2 * (vobjCopiedBase at: vobjIndex)).
				 self metadata: metadata at: vobjRecord + OilMDVObjSlotBase putInt: 0]
			ifFalse:
				["a temp vector, or a scalar replaced object (OilDescObject; selfValue is its class): slots in high registers"
				 self metadata: metadata at: vobjRecord + OilMDVObjLiteralOrSize putInt: (vobjSize at: vobjIndex).
				 self metadata: metadata at: vobjRecord + OilMDVObjOuterFrame putInt: -1.
				 self metadata: metadata at: vobjRecord + OilMDVObjSelf putKind: OilDescConst value: ((vobjKind at: vobjIndex) = OilDescObject ifTrue: [vobjSelfClass at: vobjIndex] ifFalse: [objectMemory nilObject]).
				 self metadata: metadata at: vobjRecord + OilMDVObjNumCopied putInt: 0.
				 self metadata: metadata at: vobjRecord + OilMDVObjCopiedIndex putInt: 0.
				 self metadata: metadata at: vobjRecord + OilMDVObjSlotBase putInt: (vobjSlotBase at: vobjIndex)]].
	0 to: capturedTop - 1 do:
		[:j| self metadata: metadata at: captured + (2 * j) putKind: (capturedKind at: j) value: (capturedValue at: j)].
	0 to: OilNumRegs - 1 do:
		[:reg| self metadata: metadata at: homes + reg putInt: (oilVRegSpillTemp at: reg)].
	index := siteTable + numSites.
	0 to: numSites - 1 do:
		[:siteIndex|
		(oilSiteUsed at: siteIndex) = 0
			ifTrue: [self metadata: metadata at: siteTable + siteIndex putInt: -1]
			ifFalse:
				[self metadata: metadata at: siteTable + siteIndex putInt: index.
				 opcode := self opcodeAt: (siteIR at: siteIndex).
				 self metadata: metadata at: index + OilMDSiteKind putInt: (siteKind at: siteIndex).
				 opcode = OilGuardClass
					ifTrue:
						[self metadata: metadata at: index + OilMDSiteGuardReg putInt: (self fieldAAt: (siteIR at: siteIndex)).
						 self metadata: metadata at: index + OilMDSiteClassTag putInt: (objectMemory classTagForClass: (self word64At: (siteIR at: siteIndex) + 1))]
					ifFalse:
						[self metadata: metadata at: index + OilMDSiteGuardReg putInt: -1.
						 self metadata: metadata at: index + OilMDSiteClassTag putInt: 0].
				 self metadata: metadata at: index + OilMDSiteResumeOffset putInt: (oilSiteResume at: siteIndex) address - cogMethodAddress.
				 self metadata: metadata at: index + OilMDSiteFrame putInt: (siteFrame at: siteIndex).
				 self metadata: metadata at: index + OilMDSitePC putInt: (sitePC at: siteIndex).
				 self metadata: metadata at: index + OilMDSiteTop putInt: (siteSnapTop at: siteIndex).
				 self metadata: metadata at: index + OilMDSiteHigh putInt: (siteSnapHigh at: siteIndex).
				 index := index + OilMDSiteHeaderSize.
				 poolBase := siteSnapBase at: siteIndex.
				 0 to: (siteSnapTop at: siteIndex) + (OilMaxReg - (siteSnapHigh at: siteIndex)) do:
					[:j|
					self metadata: metadata at: index putKind: (sitePoolKind at: poolBase + j) value: (sitePoolValue at: poolBase + j).
					index := index + 2]]]! !


!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/24/2026 15:00'!
oilApiLookupSelector: selector inClass: class
	<api>
	<essential: #ProfilingCogit>
	"lookupSelector:inClass: answers nil, i.e. 0, if not found."
	^self lookupSelector: selector inClass: class! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/24/2026 15:00'!
oilApiSuperclassOf: class
	<api>
	<essential: #ProfilingCogit>
	^self superclassOf: class! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/24/2026 15:00'!
oilApiInstSpecOfClass: class
	<api>
	<essential: #ProfilingCogit>
	^objectMemory instSpecOfClass: class! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/25/2026 09:30'!
oilApiClassIndexOfClass: class
	"The class index of class (its identity hash), or 0 if it has none (never instantiated)."
	<api>
	<essential: #ProfilingCogit>
	^objectMemory rawHashBitsOf: class! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/25/2026 09:30'!
oilApiStorePointer: index ofObject: obj withValue: value
	"A store with the write barrier (the generational store check)."
	<api>
	<essential: #ProfilingCogit>
	^objectMemory storePointer: index ofObject: obj withValue: value! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/25/2026 09:30'!
oilApiIsImmutable: oop
	<api>
	<essential: #ProfilingCogit>
	^(objectMemory isNonImmediate: oop) and: [objectMemory isImmutable: oop]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/25/2026 09:30'!
oilApiFormatOfClass: class
	"The format slot of class (a SmallInteger oop: instance specification and number of fixed fields)."
	<api>
	<essential: #ProfilingCogit>
	^objectMemory fetchPointer: InstanceSpecificationIndex ofObject: class! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/25/2026 09:30'!
oilApiClassAtIndex: classIndex
	"The class of index classIndex in the class table (e.g. FullBlockClosure)."
	<api>
	<essential: #ProfilingCogit>
	^objectMemory classAtIndex: classIndex! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/25/2026 09:30'!
oilApiFixedFieldsOfClass: class
	<api>
	<essential: #ProfilingCogit>
	^objectMemory fixedFieldsOfClass: class! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/25/2026 09:30'!
oilApiHashBitsOf: oop
	"The identity hash of the non-immediate oop, assigned now if it has none yet (as primitive 75 does)."
	<api>
	<essential: #ProfilingCogit>
	^objectMemory hashBitsOf: oop! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/25/2026 09:30'!
oilApiClassBindingClassOf: aMethod
	"The class of the last literal of aMethod, its method class association, if it is a class binding (pointers, at least
	 two slots, a key; on the class side the key is nil), else 0."
	<api>
	<essential: #ProfilingCogit>
	| numLits lit |
	numLits := objectMemory literalCountOf: aMethod.
	numLits <= 0 ifTrue: [^0].
	lit := self literal: numLits - 1 ofMethod: aMethod.
	((objectMemory isNonImmediate: lit)
	 and: [(objectMemory isPointersNonImm: lit)
	 and: [(objectMemory numSlotsOf: lit) >= 2
	 and: [(objectMemory fetchPointer: 0 ofObject: lit) ~= objectMemory nilObject]]]) ifFalse: [^0].
	^objectMemory fetchClassOf: lit! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/25/2026 09:30'!
oilApiIsStringHashMethod: aMethod
	"Is aMethod's primitive primitiveStringHash (of the MiscPrimitivePlugin, e.g. String>>hashWithInitialHash:)?
	 Its first literal is then the named primitive's spec, whose second element is the function's name."
	<api>
	<essential: #ProfilingCogit>
	| lit name ptr |
	<var: #ptr type: #'char *'>
	(self primitiveIndexOf: aMethod) = PrimNumberExternalCall ifFalse: [^false].
	(objectMemory literalCountOf: aMethod) > 0 ifFalse: [^false].
	lit := self literal: 0 ofMethod: aMethod.
	((objectMemory isNonImmediate: lit)
	 and: [(objectMemory isPointersNonImm: lit)
	 and: [(objectMemory numSlotsOf: lit) >= 2]]) ifFalse: [^false].
	name := objectMemory fetchPointer: 1 ofObject: lit.
	((objectMemory isNonImmediate: name)
	 and: [(objectMemory isBytesNonImm: name)
	 and: [(objectMemory numBytesOf: name) = 19]]) ifFalse: [^false].
	ptr := objectMemory firstIndexableField: name.
	^(self strncmp: ptr _: 'primitiveStringHash' _: 19) = 0! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/25/2026 09:30'!
oilApiStringHashOf: oop initialHash: speciesHash
	"primitiveStringHash of the byte object oop (see MiscPrimitivePlugin>>primitiveStringHash)."
	<api>
	<essential: #ProfilingCogit>
	| hash numBytes |
	<var: #hash type: #'unsigned int'>
	hash := speciesHash.
	numBytes := objectMemory numBytesOf: oop.
	0 to: numBytes - 1 do:
		[:pos| hash := hash + (objectMemory fetchByte: pos ofObject: oop) * 16r19660D].
	^hash bitAnd: 16r0FFFFFFF! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/24/2026 15:00'!
oilApiFetchClassOf: oop
	<api>
	<essential: #ProfilingCogit>
	^objectMemory fetchClassOf: oop! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/24/2026 15:00'!
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

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/24/2026 15:00'!
oilMD: metadata at: index
	"Answer the SmallInteger value of slot index of the Oil metadata."
	<inline: true>
	<essential: #ProfilingCogit>
	^objectMemory integerValueOf: (objectMemory fetchPointer: index ofObject: metadata)! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/24/2026 15:00'!
oilMDIncrement: index of: metadata
	<essential: #ProfilingCogit>
	objectMemory
		storePointerUnchecked: index
		ofObject: metadata
		withValue: (objectMemory integerObjectOf: (self oilMD: metadata at: index) + 1)! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/25/2026 00:30'!
ceOilDeoptimize: siteIndex
	"Called from ceOilDeoptTrampoline by the deopt sequence of an Oil method (see OilCompiler>>genDeoptStubs)
	 when a guard fails at deopt site siteIndex.  framePointer is the Oil method's frame, whose virtual registers
	 have all been spilled to their homes; the top of stack is the return address into the deopt sequence.
	 Fast path: a class guard failed on a forwarder (become:) whose target passes the guard: store the target in
	 the register's home and answer the address of the guard; the machine code reloads its registers and resumes
	 there, without deoptimizing.
	 Slow path: deoptimize.  Rebuild the interpreter frames of the method and of the methods and blocks inlined into
	 it at the site, with the closures and temp vectors Oil dissolved rematerialized, and continue in the
	 interpreter at the site's bytecode.  This does not return."
	<api>
	<essential: #ProfilingCogit>
	<returnTypeC: #usqInt>
	| cogMethod metadata siteRecord virtualReg homeOffset value |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := self mframeHomeMethod: framePointer.
	self assert: (cogit isOilMethod: cogMethod).
	metadata := cogit oilMetadataOf: cogMethod.
	siteRecord := self oilMD: metadata at: (self oilMD: metadata at: OilMDSiteTable) + siteIndex.
	self assert: siteRecord > 0.
	(self oilMD: metadata at: siteRecord + OilMDSiteKind) = OilSiteGuard ifTrue:
		[virtualReg := self oilMD: metadata at: siteRecord + OilMDSiteGuardReg.
		 homeOffset := self oilMD: metadata at: (self oilMD: metadata at: OilMDHomes) + virtualReg.
		 value := stackPages longAt: framePointer + homeOffset.
		 ((objectMemory isNonImmediate: value)
		  and: [objectMemory isForwarded: value]) ifTrue:
			[value := objectMemory followForwarded: value.
			 (objectMemory fetchClassTagOf: value) = (self oilMD: metadata at: siteRecord + OilMDSiteClassTag) ifTrue:
				[stackPages longAt: framePointer + homeOffset put: value.
				 self oilMDIncrement: OilMDFastPaths of: metadata.
				 ^cogMethod asUnsignedInteger + (self oilMD: metadata at: siteRecord + OilMDSiteResumeOffset)]]].
	(self oilMD: metadata at: siteRecord + OilMDSiteKind) ~= OilSiteAlloc ifTrue: "an allocation beyond the scavenge threshold is not a failed speculation"
		[self oilMDIncrement: OilMDDeopts of: metadata].
	instructionPointer := self popStack. "the return address into the deopt sequence"
	self oilDeoptimizeFrame: framePointer metadata: metadata site: siteRecord.
	(self oilMD: metadata at: OilMDDeopts) >= cogit oilDisqualifyLimit ifTrue:
		[self oilDisqualifyCogMethod: cogMethod].
	"and now continue in the interpreter..."
	cogit ceInvokeInterpret.
	"NOTREACHED"
	^0! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/24/2026 18:30'!
oilRaiseMaxLiteralCountForCompile
	"Methods with more literals than maxLiteralCountForCompile are not JIT-compiled.  Raise the limit to 512 literals."
	<api>
	<essential: #ProfilingCogit>
	maxLiteralCountForCompile := maxLiteralCountForCompile max: 512! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/24/2026 17:30'!
oilDisqualifyCogMethod: cogMethod
	"The Oil method cogMethod deoptimized OilDisqualifyDeopts times (its speculations do not hold): never compile its
	 method with Oil again and, unless other activations still run it, free it, unlinking the sends to it, so that
	 the baseline JIT compiles the method again, instead of running it in the interpreter after each deopt."
	<essential: #ProfilingCogit>
	<var: #cogMethod type: #'CogMethod *'>
	| methodObj |
	methodObj := cogMethod methodObject.
	"(the root method: for a specialization, methodObj is a copy of it, see primitiveOilSpecialize)"
	cogit oilDisqualify: (objectMemory fetchPointer: OilMDRootMethod ofObject: (cogit oilMetadataOf: cogMethod)).
	(self oilHasFramesOf: cogMethod) ifFalse:
		[cogit unlinkSendsTo: methodObj andFreeIf: true]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/24/2026 17:30'!
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

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/24/2026 15:00'!
oilDescriptorIndex: reg site: site metadata: metadata
	"Answer the metadata index of the descriptor of register r in the virtual state of the site record at site,
	 or 0 if the state does not describe r."
	<essential: #ProfilingCogit>
	| top high |
	top := self oilMD: metadata at: site + OilMDSiteTop.
	high := self oilMD: metadata at: site + OilMDSiteHigh.
	reg <= top ifTrue:
		[^site + OilMDSiteHeaderSize + (2 * reg)].
	(reg > high and: [reg <= OilMaxReg]) ifTrue:
		[^site + OilMDSiteHeaderSize + (2 * (top + 1)) + (2 * (reg - high - 1))].
	^0! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/25/2026 15:00'!
oilIsVirtualObjectKind: kind
	"Is kind the descriptor kind of a virtual object (a dissolved closure or temp vector, or a scalar replaced object)?"
	<inline: true>
	<essential: #ProfilingCogit>
	^kind = OilDescBlock or: [kind = OilDescTempVector or: [kind = OilDescObject]]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/24/2026 15:00'!
oilValueAt: descIndex metadata: metadata values: regValues vobjs: vobjOops
	"Answer the value described by the descriptor at metadata index p: a register's value (read from its home before
	 the frame was rewritten), a constant, or a rematerialized virtual object (or nil if not yet allocated)."
	<essential: #ProfilingCogit>
	<var: #regValues type: #'sqInt *'>
	<var: #vobjOops type: #'sqInt *'>
	| kind |
	descIndex = 0 ifTrue: [^objectMemory nilObject].
	kind := self oilMD: metadata at: descIndex.
	kind = OilDescConst ifTrue:
		[^objectMemory fetchPointer: descIndex + 1 ofObject: metadata].
	(self oilIsVirtualObjectKind: kind) ifTrue:
		[^(vobjOops at: (self oilMD: metadata at: descIndex + 1)) = 0
			ifTrue: [objectMemory nilObject]
			ifFalse: [vobjOops at: (self oilMD: metadata at: descIndex + 1)]].
	^regValues at: (self oilMD: metadata at: descIndex + 1)! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/24/2026 15:00'!
oilNeedVObjAt: descIndex metadata: metadata needed: needed
	"If the descriptor at metadata index p is a virtual object, mark it as needed."
	<essential: #ProfilingCogit>
	<var: #needed type: #'char *'>
	| kind vobjIndex |
	descIndex = 0 ifTrue: [^self].
	kind := self oilMD: metadata at: descIndex.
	(self oilIsVirtualObjectKind: kind) ifFalse: [^self].
	vobjIndex := self oilMD: metadata at: descIndex + 1.
	(needed at: vobjIndex) = 0 ifTrue: [needed at: vobjIndex put: 1]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/24/2026 15:00'!
oilStore: descIndex at: address metadata: metadata values: regValues vobjs: vobjOops needed: needed fixupAddrs: fixupAddrs fixupVObjs: fixupVObjs numFixups: numFixups
	"Store the value described by the descriptor at metadata index p into the frame slot at address.  A virtual
	 object is marked as needed and the slot recorded, to be stored once the object exists.  Answer numFixups."
	<essential: #ProfilingCogit>
	<var: #address type: #'char *'>
	<var: #regValues type: #'sqInt *'>
	<var: #vobjOops type: #'sqInt *'>
	<var: #needed type: #'char *'>
	<var: #fixupAddrs type: #'char **'>
	<var: #fixupVObjs type: #'sqInt *'>
	| kind |
	stackPages longAt: address put: (self oilValueAt: descIndex metadata: metadata values: regValues vobjs: vobjOops).
	descIndex = 0 ifTrue: [^numFixups].
	kind := self oilMD: metadata at: descIndex.
	((self oilIsVirtualObjectKind: kind) and: [numFixups < OilNumRegs]) ifFalse:
		[^numFixups].
	self oilNeedVObjAt: descIndex metadata: metadata needed: needed.
	fixupAddrs at: numFixups put: address.
	fixupVObjs at: numFixups put: (self oilMD: metadata at: descIndex + 1).
	^numFixups + 1! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/25/2026 15:00'!
oilMarkVObjsNeededBy: needed site: site metadata: metadata
	"Mark as needed the virtual objects that the needed ones refer to, transitively: a closure's receiver and copied
	 values, a temp vector's or scalar replaced object's slots.  needed at: i is 0 (not needed), 1 (needed, its
	 references not marked yet) or 2 (needed, its references marked)."
	<essential: #ProfilingCogit>
	<var: #needed type: #'char *'>
	| vobjsBase numVObjs vobjRecord more |
	vobjsBase := self oilMD: metadata at: OilMDVObjs.
	numVObjs := self oilMD: metadata at: OilMDNumVObjs.
	more := true.
	[more] whileTrue:
		[more := false.
		 0 to: numVObjs - 1 do:
			[:i|
			(needed at: i) = 1 ifTrue:
				[needed at: i put: 2.
				 more := true.
				 vobjRecord := vobjsBase + (i * OilMDVObjSize).
				 (self oilMD: metadata at: vobjRecord + OilMDVObjKind) = OilDescBlock
					ifTrue:
						[self oilNeedVObjAt: vobjRecord + OilMDVObjSelf metadata: metadata needed: needed.
						 0 to: (self oilMD: metadata at: vobjRecord + OilMDVObjNumCopied) - 1 do:
							[:j| self oilNeedVObjAt: (self oilMD: metadata at: vobjRecord + OilMDVObjCopiedIndex) + (2 * j) metadata: metadata needed: needed]]
					ifFalse:
						[0 to: (self oilMD: metadata at: vobjRecord + OilMDVObjLiteralOrSize) - 1 do:
							[:j| self oilNeedVObjAt: (self oilDescriptorIndex: (self oilMD: metadata at: vobjRecord + OilMDVObjSlotBase) + j site: site metadata: metadata) metadata: metadata needed: needed]]]]]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/25/2026 15:00'!
oilAllocateVObjAt: vobjRecord metadata: metadata
	"Allocate the object of the virtual object record at vobjRecord, filled with nil: a FullBlockClosure, an instance
	 of the class of a scalar replaced object (with its current shape) or a temp vector (an Array)."
	<essential: #ProfilingCogit>
	| kind obj |
	kind := self oilMD: metadata at: vobjRecord + OilMDVObjKind.
	obj := kind = OilDescBlock
			ifTrue:
				[objectMemory
					allocateSlots: FullClosureFirstCopiedValueIndex + (self oilMD: metadata at: vobjRecord + OilMDVObjNumCopied)
					format: objectMemory indexablePointersFormat
					classIndex: ClassFullBlockClosureCompactIndex]
			ifFalse:
				[kind = OilDescObject
					ifTrue:
						[objectMemory
							allocateSlots: (objectMemory fixedFieldsOfClass: (objectMemory fetchPointer: vobjRecord + OilMDVObjClass ofObject: metadata))
							format: (objectMemory instSpecOfClass: (objectMemory fetchPointer: vobjRecord + OilMDVObjClass ofObject: metadata))
							classIndex: (objectMemory ensureBehaviorHash: (objectMemory fetchPointer: vobjRecord + OilMDVObjClass ofObject: metadata))]
					ifFalse:
						[objectMemory
							allocateSlots: (self oilMD: metadata at: vobjRecord + OilMDVObjLiteralOrSize)
							format: objectMemory arrayFormat
							classIndex: ClassArrayCompactIndex]].
	self assert: obj notNil.
	objectMemory fillObj: obj numSlots: (objectMemory numSlotsOf: obj) with: objectMemory nilObject.
	^obj! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/24/2026 15:00'!
oilDeoptimizeFrame: oilFP metadata: metadata site: site
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
	| theFP framesBase vobjsBase homes numVObjs chain numFrames frameIndex chainIndex baseReg numArgs homeMethod frameRecord sp newFP needed vobjOops regValues
	  fixupAddrs fixupVObjs numFixups newPage numWords finalSP vobjRecord obj numCopied outerFrame context sitePC innermost topRegs framePointers stackPointers |
	<var: #theFP type: #'char *'>
	<var: #sp type: #'char *'>
	<var: #newFP type: #'char *'>
	<var: #finalSP type: #'char *'>
	<var: #newPage type: #'StackPage *'>
	<var: #chain declareC: 'sqInt chain[OilMaxFrames]'>
	<var: #topRegs declareC: 'sqInt topRegs[OilMaxFrames]'>
	<var: #framePointers declareC: 'char *framePointers[OilMaxFrames]'>
	<var: #stackPointers declareC: 'char *stackPointers[OilMaxFrames]'>
	<var: #regValues declareC: 'sqInt regValues[OilNumRegs]'>
	<var: #vobjOops declareC: 'sqInt vobjOops[OilMaxVObjs]'>
	<var: #needed declareC: 'char needed[OilMaxVObjs]'>
	<var: #fixupAddrs declareC: 'char *fixupAddrs[OilNumRegs]'>
	<var: #fixupVObjs declareC: 'sqInt fixupVObjs[OilNumRegs]'>
	self cCode: [] inSmalltalk:
		[chain := CArrayAccessor on: (Array new: OilMaxFrames).
		 topRegs := CArrayAccessor on: (Array new: OilMaxFrames).
		 framePointers := CArrayAccessor on: (Array new: OilMaxFrames).
		 stackPointers := CArrayAccessor on: (Array new: OilMaxFrames).
		 regValues := CArrayAccessor on: (Array new: OilNumRegs).
		 vobjOops := CArrayAccessor on: (Array new: OilMaxVObjs).
		 needed := CArrayAccessor on: (ByteArray new: OilMaxVObjs).
		 fixupAddrs := CArrayAccessor on: (Array new: OilNumRegs).
		 fixupVObjs := CArrayAccessor on: (Array new: OilNumRegs)].
	theFP := oilFP.
	framesBase := self oilMD: metadata at: OilMDFrames.
	vobjsBase := self oilMD: metadata at: OilMDVObjs.
	homes := self oilMD: metadata at: OilMDHomes.
	numVObjs := self oilMD: metadata at: OilMDNumVObjs.
	sitePC := self oilMD: metadata at: site + OilMDSitePC.
	"1. The chain of inlined frames, root first, and the top register of each frame's part of the window."
	numFrames := 0.
	frameIndex := self oilMD: metadata at: site + OilMDSiteFrame.
	[frameIndex >= 0] whileTrue:
		[numFrames := numFrames + 1.
		 frameIndex := self oilMD: metadata at: framesBase + (frameIndex * OilMDFrameSize) + OilMDFrameParent].
	frameIndex := self oilMD: metadata at: site + OilMDSiteFrame.
	chainIndex := numFrames - 1.
	[frameIndex >= 0] whileTrue:
		[chain at: chainIndex put: frameIndex.
		 chainIndex := chainIndex - 1.
		 frameIndex := self oilMD: metadata at: framesBase + (frameIndex * OilMDFrameSize) + OilMDFrameParent].
	topRegs at: numFrames - 1 put: (self oilMD: metadata at: site + OilMDSiteTop).
	0 to: numFrames - 2 do:
		[:i| topRegs at: i put: (self oilMD: metadata at: framesBase + ((chain at: i + 1) * OilMDFrameSize) + OilMDFrameBase) - 1].
	"2. Make room: the interpreter frames are larger than the machine code frame."
	frameRecord := framesBase + ((chain at: 0) * OilMDFrameSize).
	numWords := 5 + (topRegs at: 0) - (self oilMD: metadata at: frameRecord + OilMDFrameNumArgs).
	1 to: numFrames - 1 do:
		[:i|
		frameRecord := framesBase + ((chain at: i) * OilMDFrameSize).
		numWords := numWords + 8 + (topRegs at: i) - (self oilMD: metadata at: frameRecord + OilMDFrameBase)].
	finalSP := theFP - (numWords * objectMemory wordSize).
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
		[:reg|
		regValues at: reg put: ((self oilMD: metadata at: homes + reg) = 0
							ifTrue: [objectMemory nilObject]
							ifFalse: [stackPages longAt: theFP + (self oilMD: metadata at: homes + reg)])].
	0 to: OilMaxVObjs - 1 do:
		[:i| vobjOops at: i put: 0. needed at: i put: 0].
	numFixups := 0.
	"4. Convert the root frame in place, then push the inlined frames.  Slots holding virtual objects are
	    written later (fixupAddrs/fixupVObjs), once the objects and the contexts they refer to exist."
	frameRecord := framesBase + ((chain at: 0) * OilMDFrameSize).
	homeMethod := objectMemory fetchPointer: frameRecord + OilMDFrameMethod ofObject: metadata.
	numArgs := self oilMD: metadata at: frameRecord + OilMDFrameNumArgs.
	stackPages
		longAt: theFP + FoxIFrameFlags
			put: (self encodeFrameFieldHasContext: (self mframeHasContext: theFP) isBlock: false numArgs: numArgs);
		longAt: theFP + FoxMethod put: homeMethod;
		longAt: theFP + FoxIFSavedIP put: 0;
		longAt: theFP + FoxIFReceiver put: (self oilValueAt: frameRecord + OilMDFrameSelf metadata: metadata values: regValues vobjs: vobjOops).
	framePointers at: 0 put: theFP.
	sp := theFP + FoxIFReceiver.
	0 to: numFrames - 1 do:
		[:i|
		frameRecord := framesBase + ((chain at: i) * OilMDFrameSize).
		baseReg := self oilMD: metadata at: frameRecord + OilMDFrameBase.
		numArgs := self oilMD: metadata at: frameRecord + OilMDFrameNumArgs.
		i > 0 ifTrue:
			["The stacked receiver (the closure, for a block) and the arguments, on the caller's stack."
			 baseReg to: baseReg + numArgs do:
				[:reg|
				sp := sp - objectMemory wordSize.
				numFixups := self oilStore: (self oilDescriptorIndex: reg site: site metadata: metadata) at: sp metadata: metadata values: regValues vobjs: vobjOops needed: needed fixupAddrs: fixupAddrs fixupVObjs: fixupVObjs numFixups: numFixups].
			 "The caller's instruction pointer: the bytecode after the send (pre-incremented)."
			 sp := sp - objectMemory wordSize.
			 stackPages
				longAt: sp
				put: (objectMemory fetchPointer: framesBase + ((chain at: i - 1) * OilMDFrameSize) + OilMDFrameMethod ofObject: metadata)
					+ objectMemory baseHeaderSize
					+ (self oilMD: metadata at: frameRecord + OilMDFrameReturnPC)
					- 1.
			 sp := sp - objectMemory wordSize.
			 stackPages longAt: sp put: (framePointers at: i - 1) asUnsignedInteger.
			 newFP := sp.
			 framePointers at: i put: newFP.
			 sp := sp - objectMemory wordSize.
			 stackPages longAt: sp put: (objectMemory fetchPointer: frameRecord + OilMDFrameMethod ofObject: metadata).
			 sp := sp - objectMemory wordSize.
			 stackPages longAt: sp put: objectMemory nilObject.
			 sp := sp - objectMemory wordSize.
			 stackPages longAt: sp put: (self encodeFrameFieldHasContext: false isBlock: (self oilMD: metadata at: frameRecord + OilMDFrameIsBlock) ~= 0 numArgs: numArgs).
			 sp := sp - objectMemory wordSize.
			 stackPages longAt: sp put: 0.
			 sp := sp - objectMemory wordSize.
			 self assert: sp = (newFP + FoxIFReceiver).
			 numFixups := self oilStore: frameRecord + OilMDFrameSelf at: sp metadata: metadata values: regValues vobjs: vobjOops needed: needed fixupAddrs: fixupAddrs fixupVObjs: fixupVObjs numFixups: numFixups].
		"The temps (after the arguments) and the stack of the frame."
		baseReg + numArgs + 1 to: (topRegs at: i) do:
			[:reg|
			sp := sp - objectMemory wordSize.
			numFixups := self oilStore: (self oilDescriptorIndex: reg site: site metadata: metadata) at: sp metadata: metadata values: regValues vobjs: vobjOops needed: needed fixupAddrs: fixupAddrs fixupVObjs: fixupVObjs numFixups: numFixups].
		stackPointers at: i put: sp].
	"5. The virtual objects needed, transitively (a closure's receiver and copied values, a temp vector's slots)."
	self oilMarkVObjsNeededBy: needed site: site metadata: metadata.
	"6. Allocate them (no GC can happen here: allocation at worst schedules a scavenge)..."
	0 to: numVObjs - 1 do:
		[:i|
		(needed at: i) ~= 0 ifTrue:
			[vobjOops at: i put: (self oilAllocateVObjAt: vobjsBase + (i * OilMDVObjSize) metadata: metadata)]].
	"...then fill them in.  A closure's outerContext is the context of the frame that created it, if on the chain."
	0 to: numVObjs - 1 do:
		[:i|
		(needed at: i) ~= 0 ifTrue:
			[vobjRecord := vobjsBase + (i * OilMDVObjSize).
			 obj := vobjOops at: i.
			 (self oilMD: metadata at: vobjRecord + OilMDVObjKind) = OilDescBlock
				ifTrue:
					[outerFrame := self oilMD: metadata at: vobjRecord + OilMDVObjOuterFrame.
					 context := objectMemory nilObject.
					 0 to: numFrames - 1 do:
						[:j| (chain at: j) = outerFrame ifTrue:
							[context := self ensureFrameIsMarried: (framePointers at: j) SP: (stackPointers at: j)]].
					 numCopied := self oilMD: metadata at: vobjRecord + OilMDVObjNumCopied.
					 objectMemory
						storePointer: ClosureOuterContextIndex ofObject: obj withValue: context;
						storePointer: FullClosureCompiledBlockIndex ofObject: obj withValue: (objectMemory fetchPointer: vobjRecord + OilMDVObjLiteralOrSize ofObject: metadata);
						storePointer: ClosureNumArgsIndex ofObject: obj withValue: (objectMemory integerObjectOf: (self argumentCountOf: (objectMemory fetchPointer: vobjRecord + OilMDVObjLiteralOrSize ofObject: metadata)));
						storePointer: FullClosureReceiverIndex ofObject: obj withValue: (self oilValueAt: vobjRecord + OilMDVObjSelf metadata: metadata values: regValues vobjs: vobjOops).
					 0 to: numCopied - 1 do:
						[:j|
						objectMemory
							storePointer: FullClosureFirstCopiedValueIndex + j
							ofObject: obj
							withValue: (self oilValueAt: (self oilMD: metadata at: vobjRecord + OilMDVObjCopiedIndex) + (2 * j) metadata: metadata values: regValues vobjs: vobjOops)]]
				ifFalse:
					[0 to: ((self oilMD: metadata at: vobjRecord + OilMDVObjLiteralOrSize) min: (objectMemory numSlotsOf: obj)) - 1 do:
						[:j|
						objectMemory
							storePointer: j
							ofObject: obj
							withValue: (self oilValueAt: (self oilDescriptorIndex: (self oilMD: metadata at: vobjRecord + OilMDVObjSlotBase) + j site: site metadata: metadata) metadata: metadata values: regValues vobjs: vobjOops)]]]].
	0 to: numFixups - 1 do:
		[:i| stackPages longAt: (fixupAddrs at: i) put: (vobjOops at: (fixupVObjs at: i))].
	"7. Continue in the innermost frame, at the site's bytecode."
	innermost := objectMemory fetchPointer: framesBase + ((chain at: numFrames - 1) * OilMDFrameSize) + OilMDFrameMethod ofObject: metadata.
	framePointer := framePointers at: numFrames - 1.
	stackPointer := sp.
	instructionPointer := innermost + objectMemory baseHeaderSize + sitePC - 1.
	self setMethod: innermost! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-initialization' stamp: 'cb 10/24/2026 19:15'!
checkImageHeaderLoad
	"Oil's minimum: a 4 MB code zone."
	<inline: #always>
	cogCodeSize < (4 * 1024 * 1024) ifTrue:
		[cogCodeSize := 4 * 1024 * 1024]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-initialization' stamp: 'cb 10/24/2026 15:00'!
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


!CoInterpreterPrimitives methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/24/2026 15:00'!
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

!CoInterpreterPrimitives methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/24/2026 15:00'!
primitiveOilSetSelectors
	"Argument: an Array of pairs kind, selector telling the Oil compiler which selectors it treats specially
	 (0-4: value, value:, ... by arity; 5: bitXor:; 6: iterators to inline; 7: cold selectors never inlined;
	 8 with a SmallInteger: the number of deoptimizations after which an Oil method is disqualified;
	 12-18 with a SmallInteger: the loop unrolling parameters, see OilLoopOptimizer>>oilUnrollParameter:value:).
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

!CoInterpreterPrimitives methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/24/2026 15:00'!
primitiveOilMethodInfo
	"Receiver: a CompiledMethod.  If its machine code was compiled by Oil answer
	 { number of deoptimizations. number of deopts resumed by the unforwarding fast path.
	   the machine code (a ByteArray, from the CogMethod header to the end of the code). its address }
	 otherwise answer nil."
	<export: true>
	<essential: #ProfilingCogit>
	| methodObj cogMethod metadata code result size |
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
		[:byteOffset| objectMemory storeByte: byteOffset ofObject: code withValue: (objectMemory byteAt: cogMethod asUnsignedInteger + byteOffset)].
	metadata := cogit oilMetadataOf: cogMethod.
	objectMemory
		storePointerUnchecked: 0 ofObject: result withValue: (objectMemory fetchPointer: OilMDDeopts ofObject: metadata);
		storePointerUnchecked: 1 ofObject: result withValue: (objectMemory fetchPointer: OilMDFastPaths ofObject: metadata);
		storePointer: 2 ofObject: result withValue: code;
		storePointerUnchecked: 3 ofObject: result withValue: (objectMemory integerObjectOf: cogMethod asUnsignedInteger).
	self pop: argumentCount + 1 thenPush: result! !

!CoInterpreterPrimitives methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/25/2026 00:30'!
primitiveOilLastCompilation
	"Answer an Array describing the last Oil compilation, for debugging:
	 { failure code. IR words (an Array of SmallIntegers). eager closures (0/1). IR index the back end failed at.
	   number of deopt sites. number of inlined frames. number of homes. number of allocated registers.
	   microseconds Passes 1 to 3 took (including assembling the CogMethod and its metadata, not freeing the baseline code).
	   Pass 1 IR words (after loop unrolling, the IR Pass 2 optimized again, see OilLoopOptimizer>>loopOptimize).
	   Pass 2 statistics (see OilCompiler>>pass2Statistics:) }"
	<export: true>
	<essential: #ProfilingCogit>
	| irWordCount irArray result statsArray |
	irWordCount := cogit oilDebugInfo: 1 at: 0.
	irArray := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: irWordCount.
	result := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: 11.
	(irArray isNil or: [result isNil]) ifTrue:
		[^self primitiveFailFor: PrimErrNoMemory].
	0 to: irWordCount - 1 do:
		[:wordIndex| objectMemory storePointerUnchecked: wordIndex ofObject: irArray withValue: (objectMemory integerObjectOf: (cogit oilDebugInfo: 2 at: wordIndex))].
	objectMemory
		storePointerUnchecked: 0 ofObject: result withValue: (objectMemory integerObjectOf: (cogit oilDebugInfo: 0 at: 0));
		storePointer: 1 ofObject: result withValue: irArray.
	2 to: 7 do:
		[:slotIndex| objectMemory storePointerUnchecked: slotIndex ofObject: result withValue: (objectMemory integerObjectOf: (cogit oilDebugInfo: slotIndex + 1 at: 0))].
	objectMemory storePointerUnchecked: 8 ofObject: result withValue: (objectMemory integerObjectOf: cogit getOilCompileMicroseconds).
	"Pass 1's IR (Buffer 1; the IR above is Pass 2's) and Pass 2's statistics."
	irWordCount := cogit oilDebugInfo: 11 at: 0.
	irArray := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: irWordCount.
	irArray isNil ifTrue: [^self primitiveFailFor: PrimErrNoMemory].
	0 to: irWordCount - 1 do:
		[:wordIndex| objectMemory storePointerUnchecked: wordIndex ofObject: irArray withValue: (objectMemory integerObjectOf: (cogit oilDebugInfo: 12 at: wordIndex))].
	objectMemory storePointer: 9 ofObject: result withValue: irArray.
	statsArray := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: 26.
	statsArray isNil ifTrue: [^self primitiveFailFor: PrimErrNoMemory].
	0 to: 25 do:
		[:slotIndex| objectMemory storePointerUnchecked: slotIndex ofObject: statsArray withValue: (objectMemory integerObjectOf: (cogit oilDebugInfo: 13 at: slotIndex))].
	objectMemory storePointer: 10 ofObject: result withValue: statsArray.
	self pop: argumentCount + 1 thenPush: result! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil' stamp: 'cb 10/24/2026 18:00'!
oilHeaderWithLargeContext: methodHeader
	<api>
	<essential: #ProfilingCogit>
	^methodHeader bitOr: LargeContextBit! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil' stamp: 'cb 10/24/2026 18:00'!
oilHeaderWithoutLargeContext: methodHeader
	<api>
	<essential: #ProfilingCogit>
	^methodHeader bitAnd: LargeContextBit bitInvert! !


