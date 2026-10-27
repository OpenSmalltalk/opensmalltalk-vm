"The native back end of the Oil optimizing JIT, its deopt stubs and the deoptimizer.
 - ProfilingCogit drives the compilation of an Oil method (oilCompile:receiverClass: runs Pass 1, oilGenerate: runs
   Pass 3 and builds the CogMethod and its deoptimization metadata) and owns ceOilDeoptTrampoline.
 - CoInterpreter>>ceOilDeoptimize: is the deoptimizer: on a failed guard it either unforwards and resumes the machine code
   (fast path), or rebuilds the interpreter frames of the method and of everything inlined into it at the guard,
   rematerializing the closures and temp vectors Oil dissolved, and continues in the interpreter.
 - CoInterpreter>>oilAutoCompile:receiver: compiles the hot methods the trip counters find (see ceOilTrip:) and installs
   their Oil code without disturbing their running activations.
 - primitiveOilCompile, primitiveOilSetColdSelectors, primitiveOilSetAutonomousCompilation, primitiveOilSetDisqualifyLimit
   and primitiveOilMethodInfo are the image's interface; primitiveOilContexts, primitiveOilDeoptimize and primitiveOilMetadata support debuggers and VM engineers: a
   frame suspended in a call maps, through the call's site record, to the activations it stands for.
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
	oilColdSelectors := 0.
	oilNoAutoCompile := false.
	oilExtraSelectors := 0.
	oilSpecializations := 0.
	oilKeepSpecializations := false.
	cogMethodSurrogateClass := (objectMemory ifNil: [self class objectMemoryClass]) wordSize = 4
										ifTrue: [CogSistaMethodSurrogate32]
										ifFalse: [CogSistaMethodSurrogate64]! !

!ProfilingCogit methodsFor: 'initialization' stamp: 'cb 10/25/2026 01:50'!
generateRunTimeTrampolines
	"Add the trampoline called when a trip counter reaches zero (it passes the kind of site, OilTripBackJump,
	 in SendNumArgsReg to ceOilTrip:, and preserves ReceiverResultReg, which may hold self),
	 and the trampoline called by the deopt sequence of Oil methods (it passes the deopt site index in
	 SendNumArgsReg to ceOilDeoptimize:, which answers the address to resume at in TempReg, unless it deoptimizes,
	 in which case it does not return)."
	super generateRunTimeTrampolines.
	"Let large (e.g. parser) methods get machine code, hence inline caches for Oil (the default limit is 60 literals)."
	coInterpreter oilRaiseMaxLiteralCountForCompile.
	ceOilTripTrampoline := self genTrampolineFor: #ceOilTrip:
								called: 'ceOilTripTrampoline'
								arg: SendNumArgsReg
								regsToSave: (self registerMaskFor: ReceiverResultReg and: ClassReg).
	ceOilDeoptTrampoline := self genTrampolineFor: #ceOilDeoptimize:
								called: 'ceOilDeoptTrampoline'
								arg: SendNumArgsReg
								result: TempReg! !


!ProfilingCogit methodsFor: 'oil code generation' stamp: 'cb 10/25/2026 00:30'!
oilGenDeoptCall
	"See OilCompiler>>genDeoptStubs."
	^self CallRT: ceOilDeoptTrampoline! !

!ProfilingCogit methodsFor: 'oil code generation' stamp: 'cb 10/26/2026 19:30'!
oilGenInterruptCheckCall
	"See OilCompiler>>genPollStubs."
	^self CallRT: ceCheckForInterruptTrampoline! !

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

!ProfilingCogit methodsFor: 'oil code generation' stamp: 'cb 10/26/2026 09:30'!
oilGenSend: selectorIndex numArgs: numArgs super: isSuper above: methodClass
	"An uninlined send from an Oil method, linked by the usual inline cache machinery: the receiver is in
	 ReceiverResultReg and the arguments in registers or on the stack (see OilCompiler>>genCallAt:site:).
	 A super send with a methodClass (not 0) is a directed super send (one of an inlined method), whose lookup
	 starts in the superclass of methodClass, passed to the trampoline in TempReg.
	 c.f. genMarshalledSend:numArgs:sendTable:"
	| sendTable annotation |
	<var: #sendTable type: #'sqInt *'>
	sendTable := isSuper
					ifTrue: [methodClass ~= 0 ifTrue: [directedSuperSendTrampolines] ifFalse: [superSendTrampolines]]
					ifFalse: [ordinarySendTrampolines].
	annotation := isSuper
					ifTrue: [methodClass ~= 0 ifTrue: [IsDirectedSuperSend] ifFalse: [IsSuperSend]]
					ifFalse: [IsSendCall].
	isSuper ifTrue: "Deal with stale super sends; see SpurMemoryManager's class comment."
		[objectRepresentation genEnsureOopInRegNotForwarded: ReceiverResultReg scratchReg: TempReg].
	numArgs >= (NumSendTrampolines - 1) ifTrue:
		[self MoveCq: numArgs R: SendNumArgsReg].
	methodClass ~= 0 ifTrue:
		[self genMoveConstant: methodClass R: TempReg].
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
	 (activateNewCogMethod:inInterpreter:) and enters them at the stack check.  The spill slots of the virtual
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


!ProfilingCogit methodsFor: 'oil compilation' stamp: 'cb 10/26/2026 15:00'!
oilRegisterSelectors
	"Tell Pass 1 the cold selectors, never inlined: those of the Array of Symbols the image supplied (see
	 primitiveOilSetColdSelectors), else the default ones, which it recognizes by name (numColdSelectors -1, see
	 OilInliningCompiler>>isColdSelector:), like the value selectors, bitXor: and the methods of the byte scans.
	 Re-registered before each compilation since the garbage collector moves selectors."
	| selectors selector |
	self resetSelectorRegistry.
	selectors := oilColdSelectors.
	(selectors = 0 or: [selectors = objectMemory nilObject]) ifTrue:
		[^self useDefaultColdSelectors].
	(objectMemory isForwarded: selectors) ifTrue:
		[selectors := objectMemory followForwarded: selectors.
		 oilColdSelectors := selectors].
	0 to: (objectMemory numSlotsOf: selectors) - 1 do:
		[:i|
		selector := objectMemory fetchPointer: i ofObject: selectors.
		(objectMemory isNonImmediate: selector) ifTrue:
			[(objectMemory isForwarded: selector) ifTrue: [selector := objectMemory followForwarded: selector].
			 self registerSelector: selector kind: 7]]! !

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

!ProfilingCogit methodsFor: 'oil compilation' stamp: 'cb 10/26/2026 20:30'!
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

!ProfilingCogit methodsFor: 'oil compilation' stamp: 'cb 10/26/2026 05:20'!
oilGenerateCogMethod
	"Assemble the abstract instructions into a CogMethod, like generateCogMethod:, then attach the
	 deoptimization metadata, a hidden old space object of CompiledMethod format, through the method's counters field (tagged with 1).
	 Uses a single-pass annotation map generated into a 512-byte stack buffer to eliminate the
	 preliminary generateMapAt: nil pass."
	<inline: true>
	| codeSize headerSize mapSize totalSize startAddress result metadata selector added writableMethod mapBuffer |
	<var: #writableMethod type: #'CogMethod *'>
	<var: #mapBuffer declareC: 'char mapBuffer[512]'>
	self planMetadata ifFalse:
		[^OilFailCodeSpace].
	metadata := coInterpreter oilAllocateMetadata: self mdNumLiterals numBytes: self mdNumBytes.
	metadata = 0 ifTrue:
		[^OilFailCodeSpace].
	headerSize := self sizeof: CogMethod.
	methodLabel address: methodZone freeStart.
	self computeMaximumSizes.
	methodLabel concretizeAt: methodZone freeStart.
	codeSize := self generateInstructionsAt: methodLabel address + headerSize.
	mapSize := self generateMapAt: (self cCode: '(usqInt)(mapBuffer + 511 - codeToDataDelta)'
									inSmalltalk: [nil])
					start: methodLabel address + cmNoCheckEntryOffset.
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
	(self cCode: [mapSize <= 512] inSmalltalk: [false])
		ifTrue:
			[self codeMemmove: startAddress + totalSize - mapSize
				_: (self cCode: 'mapBuffer + 512 - mapSize')
				_: mapSize]
		ifFalse:
			[self generateMapAt: startAddress + totalSize - 1 start: startAddress + cmNoCheckEntryOffset].
	self fillInBlockHeadersAt: startAddress.
	selector := coInterpreter maybeSelectorOfMethod: methodObj.
	selector isNil ifTrue: [selector := coInterpreter maybeSelectorOfMethod: oilHomeMethod].
	selector isNil ifTrue: [selector := objectMemory nilObject].
	(objectMemory isYoung: selector) ifTrue:
		[self setHasYoungReferent: true].
	"Oil frames hold the spill slots of the virtual registers below the temps, and marrying or divorcing a frame copies
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

!ProfilingCogit methodsFor: 'oil compilation' stamp: 'cb 10/27/2026 16:15'!
isOilMethod: cogMethod
	"Oil methods hold their deoptimization metadata in their counters field, tagged with 1; baseline methods hold 0 there
	 (their trip counters are in a ring buffer, see oilAllocateTripCounter)."
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod = 0 ifTrue: [^false].
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
setOilColdSelectors: anArray
	<api>
	oilColdSelectors := anArray! !

!ProfilingCogit methodsFor: 'oil compilation' stamp: 'cb 10/24/2026 15:00'!
getOilColdSelectors
	<api>
	^oilColdSelectors! !

!ProfilingCogit methodsFor: 'oil compilation' stamp: 'cb 10/24/2026 15:00'!
oilColdSelectorsAddress
	"Answer the address of the oilColdSelectors variable, for registering it as a GC root."
	<api>
	<returnTypeC: #'sqInt *'>
	^self addressOf: oilColdSelectors put: [:value| oilColdSelectors := value]! !

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

!ProfilingCogit methodsFor: 'oil selector table' stamp: 'cb 10/26/2026 20:40'!
oilExtraSelectorIndexOf: selector add: addIfAbsent
	"64-bit inline caches hold the index of their selector among the special selectors or the literals of the method.
	 Oil methods also send selectors of the methods they inline, which are not among their literals, so their inline
	 caches may hold OilExtraSelectorBase + k instead: the selector at index k of the Oil selector table
	 (oilExtraSelectors, allocated by CoInterpreter>>oilEnsureExtraSelectorTable, a GC root; see CogObjectRepresentationFor64BitSpur>>oilWrapSelectorIndexDereferenceRoutine
	 and indexForSelector:in:).  Answer selector's value, adding it if addIfAbsent, or OilNoLink if it is absent and not
	 added (no table, or the table is full)."
	| table tableSelector |
	table := oilExtraSelectors.
	table = 0 ifTrue: "(no table yet, see CoInterpreter>>oilEnsureExtraSelectorTable)"
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

!ProfilingCogit methodsFor: 'in-line cacheing' stamp: 'cb 10/26/2026 20:30'!
oilLinkedSendMcpcAt: bcpc in: aMethodObj
	"Answer the return address (mcpc) of the ordinary send at the 0-relative bytecode pc bcpc of aMethodObj (a
	 CompiledMethod or CompiledBlock) if its inline cache is linked, else 0 (no machine code, Oil code, no such send, or
	 an unlinked inline cache)."
	<returnTypeC: #usqInt>
	| mcpc |
	(coInterpreter methodHasCogMethod: aMethodObj) ifFalse: [^0].
	mcpc := self oilSendMcpcAt: bcpc in: (coInterpreter cogMethodOf: aMethodObj).
	(mcpc = 0 or: [(backEnd callTargetFromReturnAddress: mcpc) <= methodZoneBase]) ifTrue: [^0].
	^mcpc! !

!ProfilingCogit methodsFor: 'in-line cacheing' stamp: 'cb 10/26/2026 20:30'!
oilMonomorphicClassAt: bcpc in: aMethodObj
	"Type feedback for Oil's Pass 1: the receiver class of the send at the 0-relative bytecode pc bcpc of
	 aMethodObj (a CompiledMethod or CompiledBlock) if its inline cache is monomorphic, else 0."
	| mcpc targetMethod class |
	<var: #targetMethod type: #'CogMethod *'>
	mcpc := self oilLinkedSendMcpcAt: bcpc in: aMethodObj.
	mcpc = 0 ifTrue: [^0].
	self targetMethodAndSendTableFor: (backEnd callTargetFromReturnAddress: mcpc)
		annotation: IsSendCall
		into: [:target :sendTable| targetMethod := target].
	targetMethod isCMMethodEtAl ifFalse: [^0].
	class := objectRepresentation classForInlineCacheTag: (backEnd inlineCacheTagAt: mcpc).
	^class = objectMemory nilObject ifTrue: [0] ifFalse: [class]! !


!ProfilingCogit methodsFor: 'in-line cacheing' stamp: 'cb 10/26/2026 20:30'!
oilPolymorphicClass: caseIndex at: bcpc in: aMethodObj
	"Type feedback for Oil's bimorphic inlining: the receiver class of case caseIndex (0 or 1) of the send at the 0-relative
	 bytecode pc bcpc of aMethodObj if its inline cache is linked to a closed PIC of exactly two cases, both to methods
	 (not to the doesNotUnderstand: entry), else 0.  c.f. SistaCogit>>populate:withPICInfoFor:firstCacheTag:"
	| mcpc entryPoint targetMethod pc cacheTag class |
	<var: #targetMethod type: #'CogMethod *'>
	mcpc := self oilLinkedSendMcpcAt: bcpc in: aMethodObj.
	mcpc = 0 ifTrue: [^0].
	self targetMethodAndSendTableFor: (backEnd callTargetFromReturnAddress: mcpc)
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

!ProfilingCogit methodsFor: 'in-line cacheing' stamp: 'cb 10/26/2026 20:30'!
oilSendSiteUnlinkedAt: bcpc in: aMethodObj
	"Has the send at the 0-relative bytecode pc bcpc of aMethodObj never been sent, i.e. is its inline cache
	 unlinked (or does the method not have machine code yet)?  The baseline JIT inlines SmallInteger arithmetic
	 and comparisons and sends the message only for other receivers, so for those selectors an unlinked send
	 means only SmallIntegers were seen."
	(coInterpreter methodHasCogMethod: aMethodObj) ifFalse: [^true].
	(self isOilMethod: (coInterpreter cogMethodOf: aMethodObj)) ifTrue: [^false].
	^(self oilLinkedSendMcpcAt: bcpc in: aMethodObj) = 0! !


!ProfilingCogit methodsFor: 'oil support' stamp: 'cb 10/26/2026 20:40'!
oilMethodHasOilCode: aMethodObj
	"Is aMethodObj (or nil) a method whose machine code is Oil code (OilCompiler>>shouldInline:selector:numArgs:receiver:
	 then calls it)?"
	<api>
	^(objectMemory isOopCompiledMethod: aMethodObj)
	  and: [(coInterpreter methodHasCogMethod: aMethodObj)
	  and: [self isOilMethod: (coInterpreter cogMethodOf: aMethodObj)]]! !

!ProfilingCogit methodsFor: 'oil support' stamp: 'cb 10/24/2026 18:30'!
oilSendSiteNeverSentAt: bcpc in: aMethodObj
	"Does aMethodObj have baseline machine code in which the send at bcpc was never executed (unlinked inline cache)?"
	^(coInterpreter methodHasCogMethod: aMethodObj)
	  and: [self oilSendSiteUnlinkedAt: bcpc in: aMethodObj]! !

!ProfilingCogit methodsFor: 'invalidation' stamp: 'cb 10/27/2026 14:05'!
oilMethod: cogMethod inlinesSelector: aSelector
	"Answer whether cogMethod depends on the methods of aSelector: it is one of them, or Oil inlined one of them (a
	 method, quick method or intrinsic) or looked aSelector up (the inlined selectors of the metadata, see
	 OilInliningCompiler>>noteInlinedSelector:), filtered first by the 64-bit bloom filter of their identity hashes."
	| metadata numInlined bit mask |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod selector = aSelector ifTrue: [^true].
	metadata := self oilMetadataOf: cogMethod.
	bit := (coInterpreter oilApiHashBitsOf: aSelector) bitAnd: 63.
	mask := coInterpreter oilMDCounter: (bit < 32 ifTrue: [OilMDSelectorMask] ifFalse: [OilMDSelectorMask + 4]) of: metadata.
	((mask >> (bit bitAnd: 31)) bitAnd: 1) = 0 ifTrue: [^false].
	numInlined := coInterpreter oilMD: metadata header: OilMDInlinedSelectors.
	numInlined > 32767 ifTrue: [^true]. "-1 (s16): too many to record"
	0 to: numInlined - 1 do:
		[:selIndex| (objectMemory fetchPointer: OilMDFirstSelectorLiteral + selIndex ofObject: metadata) = aSelector ifTrue: [^true]].
	^false! !

!ProfilingCogit methodsFor: 'jit - api' stamp: 'cb 10/27/2026 15:05'!
unlinkSendsOf: selector isMNUSelector: isMNUSelector
	<api>
	"Also discard Oil methods that inlined selector, deoptimizing any suspended activations running them into contexts."
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	super unlinkSendsOf: selector isMNUSelector: isMNUSelector.
	methodZoneBase ifNil: [^self].
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[((self isOilMethod: cogMethod)
		  and: [self oilMethod: cogMethod inlinesSelector: selector]) ifTrue:
			[coInterpreter oilDeoptimizeFramesOf: cogMethod].
		 cogMethod := methodZone methodAfter: cogMethod]! !

!ProfilingCogit methodsFor: 'invalidation' stamp: 'cb 10/26/2026 00:40'!
oilSetMethodObjectOf: cogMethod to: aMethodObj
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	(self writableMethodFor: cogMethod) methodObject: aMethodObj! !

!ProfilingCogit methodsFor: 'compaction' stamp: 'cb 10/26/2026 20:30'!
maybeFreeCountersOf: aCogMethod
	"The method is being freed.  The deoptimization metadata of an Oil method is not freed explicitly: it is an ordinary
	 unpinned old space object, which the next full GC reclaims (nothing marks it any more, see maybeMarkCountersIn:)."
	<var: #aCogMethod type: #'CogMethod *'>
	<inline: true>
	"An Oil method that set the large context bit of its header (see oilGenerateCogMethod): freeMethod: has just put
	 its header back into the CompiledMethod, without the bit."
	((self isOilMethod: aCogMethod)
	 and: [aCogMethod cmUnusedFlag
	 and: [(coInterpreter rawHeaderOf: aCogMethod methodObject) = aCogMethod methodHeader]]) ifTrue:
		[coInterpreter
			rawHeaderOf: aCogMethod methodObject
			put: (coInterpreter oilHeaderWithoutLargeContext: aCogMethod methodHeader)]! !

!ProfilingCogit methodsFor: 'garbage collection & become' stamp: 'cb 10/26/2026 20:30'!
maybeMarkCountersIn: cogMethod
	"The Oil deoptimization metadata is a heap object which must be marked to avoid it being collected (and to trace the
	 objects it refers to).  It is not pinned: see mapObjectReferencesInMachineCodeForFullGC.  The counters field of a
	 method is 0 (a baseline method: its trip counters are in a ring buffer, see oilAllocateTripCounter), or the oop of an
	 Oil method's metadata tagged with 1."
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	(cogMethod counters bitAnd: 1) ~= 0 ifTrue:
		[objectMemory markAndTrace: cogMethod counters - 1]! !

!ProfilingCogit methodsFor: 'garbage collection & become' stamp: 'cb 10/26/2026 10:40'!
mapObjectReferencesInMachineCodeForFullGC
	"Also update the references of the Oil methods to their deoptimization metadata, which a full GC may move."
	super mapObjectReferencesInMachineCodeForFullGC.
	self oilRemapMetadataReferences! !

!ProfilingCogit methodsFor: 'garbage collection & become' stamp: 'cb 10/26/2026 10:40'!
mapObjectReferencesInMachineCodeForBecome
	super mapObjectReferencesInMachineCodeForBecome.
	self oilRemapMetadataReferences! !

!ProfilingCogit methodsFor: 'garbage collection & become' stamp: 'cb 10/26/2026 10:40'!
oilRemapMetadataReferences
	"Update the counters field of the Oil methods, their deoptimization metadata tagged with 1 (an unpinned old space
	 object, see CoInterpreter>>oilAllocateMetadata:numBytes:)."
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[(self isOilMethod: cogMethod) ifTrue:
			[(self writableMethodFor: cogMethod) counters: (objectRepresentation remapOop: cogMethod counters - 1) + 1].
		 cogMethod := methodZone methodAfter: cogMethod]! !

!ProfilingCogit class methodsFor: 'trampoline support' stamp: 'cb 10/25/2026 01:50'!
numTrampolines
	^super numTrampolines + 2 "ceOilTripTrampoline, ceOilDeoptTrampoline"! !

!ProfilingCogit class methodsFor: 'translation' stamp: 'cb 10/24/2026 19:35'!
ancilliaryClasses
	"Answer any extra classes to be included in the translation: the counters field of SistaCogMethod and
	 Oil's optimizing compiler hierarchy (scanner, base compiler, loop optimizer, full compiler)."
	^super ancilliaryClasses, {SistaCogMethod. OilBytecodeDescriptor. OilBytecodeScanner. OilFrame. OilVObj. OilCond. OilInliningCompiler. OilLoopOptimizer. OilFullCompiler}! !


!OilInliningCompiler methodsFor: 'native code generation' stamp: 'cb 10/25/2026 00:30'!
estimateOpcodes
	"An upper bound of the number of abstract instructions oilGenerate: emits (they are allocated on the C stack)."
	| irOffset estimatedCount |
	estimatedCount := 200 + (2 * oilNumSpillTemps) + (4 * numSites) + (4 * OilMaxReg // 16).
	irOffset := 0.
	[irOffset < irIndex] whileTrue:
		[estimatedCount := estimatedCount + (self estimateOpcodesOfInstructionAt: irOffset).
		 (oilIRTarget at: irOffset) = 2 ifTrue: "a loop header: its interrupt check and stub (see genPollBefore:)"
			[estimatedCount := estimatedCount + 8 + (2 * oilNumAllocRegs)].
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
	(opcode = OilIndexOfByte or: [opcode = OilSkipSeparators or: [opcode = OilFindFirstInString]]) ifTrue: [^160 + (4 * oilNumAllocRegs)].
	opcode = OilFindSubstring ifTrue: [^240 + (4 * oilNumAllocRegs)].
	^20! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/26/2026 10:00'!
planMetadata
	"Plan the deoptimization metadata (see fillMetadata:cogMethod:): collect its literals (deduplicated, see
	 mdLiteralIndexOf:) and compute the number of its bytes, in oilNumMDLiterals and oilMDNumBytes.  Answer false if it
	 would be too large: more than OilMaxMDLiterals literals, or byte offsets beyond 16 bits."
	| numBytes poolBase |
	0 to: OilMDLiteralHashSize - 1 do:
		[:hashIndex| oilMDLitHash at: hashIndex put: 0].
	oilNumMDLiterals := 0.
	self mdLiteralIndexOf: oilHomeMethod. "OilMDRootMethod"
	0 to: self numInlinedSelectorsInMetadata - 1 do: "from OilMDFirstSelectorLiteral (distinct selectors)"
		[:selIndex| self mdLiteralIndexOf: (oilInlinedSelectors at: selIndex)].
	0 to: numFrames - 1 do:
		[:frameIndex|
		self mdLiteralIndexOf: (self frameAt: frameIndex) method.
		self mdNoteDescriptorKind: (self frameAt: frameIndex) selfKind value: (self frameAt: frameIndex) selfValue].
	0 to: numVObjs - 1 do:
		[:vobjIndex|
		(self vobjAt: vobjIndex) kind = OilDescBlock
			ifTrue:
				[self mdLiteralIndexOf: (self vobjAt: vobjIndex) literal.
				 self mdNoteDescriptorKind: (self vobjAt: vobjIndex) rcvrKind value: (self vobjAt: vobjIndex) rcvrValue]
			ifFalse:
				[self mdLiteralIndexOf: (self vobjSelfConstant: vobjIndex)]].
	0 to: capturedTop - 1 do:
		[:capturedIndex| self mdNoteDescriptorKind: (capturedKind at: capturedIndex) value: (capturedValue at: capturedIndex)].
	numBytes := OilMDHeaderSize + (numFrames * OilMDFrameSize) + (numVObjs * OilMDVObjSize)
				+ (capturedTop * OilMDDescriptorSize) + (self numSpilledRegisters * OilMDSpillEntrySize) + (numSites * 2).
	0 to: numSites - 1 do:
		[:siteIndex| (oilSiteUsed at: siteIndex) ~= 0 ifTrue:
			[numBytes := numBytes + OilMDSiteHeaderSize.
			 ((self opcodeAt: (siteIR at: siteIndex)) = OilGuardClass and: [(oilSiteUsed at: siteIndex) < 2]) ifTrue:
				[numBytes := numBytes + OilMDSiteGuardSize].
			 (oilSiteUsed at: siteIndex) >= 2 ifTrue: "a call site (see noteCallSiteAt:) or an interrupt check (see genPollBefore:)"
				[numBytes := numBytes + OilMDSiteCallSize].
			 poolBase := siteSnapBase at: siteIndex.
			 0 to: (self siteStateSize: siteIndex) - 1 do:
				[:stateIndex|
				self mdNoteDescriptorKind: (sitePoolKind at: poolBase + stateIndex) value: (sitePoolValue at: poolBase + stateIndex).
				numBytes := numBytes + (self mdStateDescriptorSizeKind: (sitePoolKind at: poolBase + stateIndex)
											value: (sitePoolValue at: poolBase + stateIndex)
											reg: (self site: siteIndex stateRegister: stateIndex))]]].
	oilMDNumBytes := numBytes.
	^oilNumMDLiterals < (OilMaxMDLiterals - 1)
	  and: [(oilNumMDLiterals + 1 * objectMemory wordSize) + numBytes < 65536]! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/26/2026 10:00'!
metadataObjectBytes
	"The size of the metadata object planned, header included (for primitiveOilLastCompilation)."
	^(oilNumMDLiterals + 1 * objectMemory wordSize) + oilMDNumBytes + 7 // 8 * 8 + objectMemory baseHeaderSize! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/26/2026 10:00'!
mdNumLiterals
	"The number of literals of the metadata planned (after its header slot)."
	<inline: true>
	^oilNumMDLiterals! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/26/2026 10:00'!
mdNumBytes
	"The number of bytes of the metadata planned (after its literal frame)."
	<inline: true>
	^oilMDNumBytes! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/26/2026 10:00'!
mdLiteralIndexOf: oop
	"Answer the index of the literal oop of the metadata being planned (its slot index), adding it if absent: the literals
	 are deduplicated through an open addressing hash table (at most half full).  If the literal frame is full (see
	 planMetadata), answer OilMDRootMethod."
	| hashIndex litIndex |
	hashIndex := (oop bitShift: -3) bitAnd: OilMDLiteralHashSize - 1.
	[(litIndex := oilMDLitHash at: hashIndex) ~= 0] whileTrue:
		[(oilMDLiterals at: litIndex) = oop ifTrue: [^litIndex].
		 hashIndex := hashIndex + 1 bitAnd: OilMDLiteralHashSize - 1].
	oilNumMDLiterals >= (OilMaxMDLiterals - 1) ifTrue: [^OilMDRootMethod].
	oilNumMDLiterals := oilNumMDLiterals + 1.
	oilMDLiterals at: oilNumMDLiterals put: oop.
	oilMDLitHash at: hashIndex put: oilNumMDLiterals.
	^oilNumMDLiterals! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/26/2026 10:00'!
mdNoteDescriptorKind: kind value: value
	"A constant descriptor refers to its value as a literal (nil as literal 0)."
	<inline: true>
	(kind = OilDescConst and: [value ~= objectMemory nilObject]) ifTrue: [self mdLiteralIndexOf: value]! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/26/2026 10:30'!
mdDescriptorValueKind: kind value: value
	"The value field of a descriptor: the literal index of a constant (0 for nil), the register or virtual object index otherwise."
	<inline: true>
	^kind = OilDescConst
		ifTrue: [value = objectMemory nilObject ifTrue: [0] ifFalse: [self mdLiteralIndexOf: value]]
		ifFalse: [value]! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/26/2026 10:30'!
site: siteIndex stateRegister: stateIndex
	"The register that the descriptor stateIndex of the virtual state of siteIndex describes: the register window 0..top,
	 then the high registers high+1..OilMaxReg."
	<inline: true>
	^stateIndex <= (siteSnapTop at: siteIndex)
		ifTrue: [stateIndex]
		ifFalse: [(siteSnapHigh at: siteIndex) + stateIndex - (siteSnapTop at: siteIndex)]! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/26/2026 10:30'!
mdStateDescriptorSizeKind: kind value: value reg: reg
	"The number of bytes of a descriptor of a virtual state (see metadata:stateDescriptorAt:kind:value:reg:)."
	<inline: true>
	^((kind = OilDescReg and: [value = reg]) or: [kind = OilDescConst and: [value = objectMemory nilObject]])
		ifTrue: [1]
		ifFalse: [2]! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/26/2026 10:30'!
metadata: metadata stateDescriptorAt: index kind: kind value: value reg: reg
	"Write the descriptor of register reg in a virtual state at index (see CoInterpreter>>oilDecodeStateOf:metadata:into:):
	 1 byte for a register holding its own value (OilMDStateOwn) and for nil (OilMDStateNil), else 2 bytes, big endian:
	 128 + the kind (3 bits), then the value (12 bits).  Answer the number of bytes."
	| fieldValue |
	(kind = OilDescReg and: [value = reg]) ifTrue:
		[self metadata: metadata byteAt: index put: OilMDStateOwn.
		 ^1].
	(kind = OilDescConst and: [value = objectMemory nilObject]) ifTrue:
		[self metadata: metadata byteAt: index put: OilMDStateNil.
		 ^1].
	fieldValue := self mdDescriptorValueKind: kind value: value.
	self assert: (fieldValue >= 0 and: [fieldValue < 4096]).
	self metadata: metadata byteAt: index put: 128 + (kind << 4) + (fieldValue >> 8).
	self metadata: metadata byteAt: index + 1 put: fieldValue.
	^2! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/26/2026 10:00'!
vobjSelfConstant: vobjIndex
	"The self of a temp vector (nil) or of a scalar replaced object (its class) in the metadata."
	<inline: true>
	^(self vobjAt: vobjIndex) kind = OilDescObject
		ifTrue: [(self vobjAt: vobjIndex) vobjClass]
		ifFalse: [objectMemory nilObject]! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/26/2026 10:00'!
numSpilledRegisters
	"The number of virtual registers with a spill slot (the spill entries of the metadata)."
	| count |
	count := 0.
	0 to: OilNumRegs - 1 do:
		[:reg| (oilVRegSpillTemp at: reg) ~= 0 ifTrue: [count := count + 1]].
	^count! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/26/2026 14:30'!
numArgsOfCallAt: irOffset
	"The number of arguments of the call (OilCall0, OilCall1, OilCallN, OilCallSuper or OilCallDirectedSuper) at irOffset."
	| opcode |
	opcode := self opcodeAt: irOffset.
	opcode = OilCall0 ifTrue: [^0].
	opcode = OilCall1 ifTrue: [^1].
	^self fieldCAt: irOffset! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/26/2026 10:00'!
metadata: metadata byteAt: index put: value
	<inline: true>
	coInterpreter oilMD: metadata byteAt: index put: (value bitAnd: 255)! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/26/2026 10:00'!
metadata: metadata u16At: index put: value
	"Little endian; also for an s8/s16 (two's complement)."
	<inline: true>
	self metadata: metadata byteAt: index put: value.
	self metadata: metadata byteAt: index + 1 put: (value bitShift: -8)! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/26/2026 10:00'!
metadata: metadata u32At: index put: value
	<inline: true>
	self metadata: metadata u16At: index put: value.
	self metadata: metadata u16At: index + 2 put: (value bitShift: -16)! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/26/2026 10:00'!
metadata: metadata descriptorAt: index kind: kind value: value
	"A descriptor: its kind in the top 3 bits, and its value, the literal index of a constant (0 for nil), a register or a
	 virtual object index otherwise, in the low OilMDDescriptorValueBits bits."
	self assert: (value >= 0 and: [kind = OilDescConst or: [value < (1 << OilMDDescriptorValueBits)]]).
	self metadata: metadata
		u16At: index
		put: (kind << OilMDDescriptorValueBits) + (self mdDescriptorValueKind: kind value: value)! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/26/2026 10:00'!
fillMetadata: metadata cogMethod: cogMethodAddress
	"Fill in the deoptimization metadata of the Oil method at cogMethodAddress, a hidden pinned object of CompiledMethod
	 format that planMetadata planned (see the OilMD* constants in OilConstants).  Its literals: the root method, the inlined
	 selectors (see noteInlinedSelector:) and the objects the records refer to.  Its bytes: the header, the inlined frames,
	 the virtual objects (dissolved closures and temp vectors, scalar replaced objects) and their captured values, the spill
	 offsets (frame offsets) of the spilled virtual registers, a table from deopt site index to site record, and the records
	 of the sites used by the deopt stubs: kind, the guarded register and class tag (for the unforwarding fast path), the
	 offset of the instruction to resume at, the inlined frame and bytecode pc, and the virtual state (descriptors of the
	 register window and of the high registers)."
	<var: #cogMethodAddress type: #usqInt>
	| base frames vobjs captured spills siteTable index frameRecord vobjRecord poolBase parentFrame siteInstruction maskLow maskHigh bit |
	1 to: oilNumMDLiterals do:
		[:litIndex| objectMemory storePointer: litIndex ofObject: metadata withValue: (oilMDLiterals at: litIndex)].
	base := oilNumMDLiterals + 1 * objectMemory wordSize.
	frames := base + OilMDHeaderSize.
	vobjs := frames + (numFrames * OilMDFrameSize).
	captured := vobjs + (numVObjs * OilMDVObjSize).
	spills := captured + (capturedTop * OilMDDescriptorSize).
	siteTable := spills + (self numSpilledRegisters * OilMDSpillEntrySize).
	self metadata: metadata u32At: base + OilMDVersion put: OilMDMagic.
	self metadata: metadata u16At: base + OilMDNumSites put: numSites.
	self metadata: metadata u16At: base + OilMDSiteTable put: siteTable.
	self metadata: metadata u16At: base + OilMDNumFrames put: numFrames.
	self metadata: metadata u16At: base + OilMDFrames put: frames.
	self metadata: metadata u16At: base + OilMDNumVObjs put: numVObjs.
	self metadata: metadata u16At: base + OilMDVObjs put: vobjs.
	self metadata: metadata u16At: base + OilMDNumSpills put: self numSpilledRegisters.
	self metadata: metadata u16At: base + OilMDSpillOffsets put: spills.
	self metadata: metadata u32At: base + OilMDDeopts put: 0.
	self metadata: metadata u32At: base + OilMDFastPaths put: 0.
	self metadata: metadata u16At: base + OilMDNumArgs put: (self numArgsOf: oilHomeMethod).
	self metadata: metadata u16At: base + OilMDCaptured put: captured.
	self metadata: metadata u16At: base + OilMDInlinedSelectors put: (oilNumInlinedSelectors > OilMaxInlinedSelectors ifTrue: [-1] ifFalse: [oilNumInlinedSelectors]).
	oilNumInlinedSelectors > OilMaxInlinedSelectors
		ifTrue:
			[maskLow := 16rFFFFFFFF.
			 maskHigh := 16rFFFFFFFF]
		ifFalse:
			[maskLow := maskHigh := 0.
			 0 to: oilNumInlinedSelectors - 1 do:
				[:selIndex|
				bit := (coInterpreter oilApiHashBitsOf: (oilInlinedSelectors at: selIndex)) bitAnd: 63.
				bit < 32
					ifTrue: [maskLow := maskLow bitOr: (1 << bit)]
					ifFalse: [maskHigh := maskHigh bitOr: (1 << (bit - 32))]]].
	self metadata: metadata u32At: base + OilMDSelectorMask put: maskLow.
	self metadata: metadata u32At: base + OilMDSelectorMask + 4 put: maskHigh.
	0 to: numFrames - 1 do:
		[:frameIndex|
		frameRecord := frames + (frameIndex * OilMDFrameSize).
		parentFrame := (self frameAt: frameIndex) parent.
		self metadata: metadata u16At: frameRecord + OilMDFrameMethod put: (self mdLiteralIndexOf: (self frameAt: frameIndex) method).
		self metadata: metadata byteAt: frameRecord + OilMDFrameIsBlock put: ((self frameAt: frameIndex) isBlockFrame ifTrue: [1] ifFalse: [0]).
		self metadata: metadata byteAt: frameRecord + OilMDFrameBase put: (self frameAt: frameIndex) base.
		self metadata: metadata byteAt: frameRecord + OilMDFrameParent put: parentFrame.
		parentFrame < 0
			ifTrue: [self metadata: metadata u16At: frameRecord + OilMDFrameReturnPC put: -1]
			ifFalse: "the pc after the send that the frame was inlined at"
				[self setScanMethod: (self frameAt: parentFrame) method.
				 self decodeAt: (self frameAt: frameIndex) callPC.
				 self metadata: metadata u16At: frameRecord + OilMDFrameReturnPC put: oilNextPC].
		self metadata: metadata descriptorAt: frameRecord + OilMDFrameSelf kind: (self frameAt: frameIndex) selfKind value: (self frameAt: frameIndex) selfValue.
		self metadata: metadata byteAt: frameRecord + OilMDFrameNumArgs put: (self numArgsOf: (self frameAt: frameIndex) method)].
	0 to: numVObjs - 1 do:
		[:vobjIndex|
		vobjRecord := vobjs + (vobjIndex * OilMDVObjSize).
		self metadata: metadata byteAt: vobjRecord + OilMDVObjKind put: (self vobjAt: vobjIndex) kind.
		(self vobjAt: vobjIndex) kind = OilDescBlock
			ifTrue:
				[self metadata: metadata u16At: vobjRecord + OilMDVObjLiteralOrSize put: (self mdLiteralIndexOf: (self vobjAt: vobjIndex) literal).
				 self metadata: metadata byteAt: vobjRecord + OilMDVObjOuterFrame put: (self vobjAt: vobjIndex) outer.
				 self metadata: metadata descriptorAt: vobjRecord + OilMDVObjSelf kind: (self vobjAt: vobjIndex) rcvrKind value: (self vobjAt: vobjIndex) rcvrValue.
				 self metadata: metadata byteAt: vobjRecord + OilMDVObjNumCopied put: (self vobjAt: vobjIndex) copiedCount.
				 self metadata: metadata u16At: vobjRecord + OilMDVObjCopiedIndex put: captured + (OilMDDescriptorSize * (self vobjAt: vobjIndex) copiedBase)]
			ifFalse:
				["a temp vector, or a scalar replaced object (OilDescObject; its self is its class): slots in high registers"
				 self metadata: metadata u16At: vobjRecord + OilMDVObjLiteralOrSize put: (self vobjAt: vobjIndex) numSlots.
				 self metadata: metadata byteAt: vobjRecord + OilMDVObjOuterFrame put: -1.
				 self metadata: metadata descriptorAt: vobjRecord + OilMDVObjSelf kind: OilDescConst value: (self vobjSelfConstant: vobjIndex).
				 self metadata: metadata byteAt: vobjRecord + OilMDVObjSlotBase put: (self vobjAt: vobjIndex) slotBase]].
	0 to: capturedTop - 1 do:
		[:capturedIndex| self metadata: metadata descriptorAt: captured + (OilMDDescriptorSize * capturedIndex) kind: (capturedKind at: capturedIndex) value: (capturedValue at: capturedIndex)].
	index := spills.
	0 to: OilNumRegs - 1 do:
		[:reg| (oilVRegSpillTemp at: reg) ~= 0 ifTrue:
			[self metadata: metadata byteAt: index put: reg.
			 self metadata: metadata u16At: index + 1 put: (oilVRegSpillTemp at: reg).
			 index := index + OilMDSpillEntrySize]].
	index := siteTable + (numSites * 2).
	0 to: numSites - 1 do:
		[:siteIndex|
		(oilSiteUsed at: siteIndex) ~= 0 ifTrue: "(the entries of the unused sites stay 0)"
			[self metadata: metadata u16At: siteTable + (2 * siteIndex) put: index.
			 siteInstruction := siteIR at: siteIndex.
			 self metadata: metadata byteAt: index + OilMDSiteFrame put: (siteFrame at: siteIndex).
			 self metadata: metadata u16At: index + OilMDSitePC put: (sitePC at: siteIndex).
			 self metadata: metadata u16At: index + OilMDSiteResumeOffset put: (oilSiteResume at: siteIndex) address - cogMethodAddress.
			 self metadata: metadata byteAt: index + OilMDSiteTop put: (siteSnapTop at: siteIndex).
			 self metadata: metadata byteAt: index + OilMDSiteHigh put: (siteSnapHigh at: siteIndex).
			 ((self opcodeAt: siteInstruction) = OilGuardClass and: [(oilSiteUsed at: siteIndex) < 2])
				ifTrue: "a class guard: the unforwarding fast path needs its register and class tag"
					[self metadata: metadata byteAt: index + OilMDSiteKind put: (siteKind at: siteIndex) + OilMDSiteGuardFlag.
					 self metadata: metadata byteAt: index + OilMDSiteGuardReg put: (self fieldAAt: siteInstruction).
					 self metadata: metadata u32At: index + OilMDSiteClassTag put: (objectMemory classTagForClass: (self word64At: siteInstruction + 1)).
					 index := index + OilMDSiteHeaderSize + OilMDSiteGuardSize]
				ifFalse:
					[(oilSiteUsed at: siteIndex) >= 2
						ifTrue: "a call site (see noteCallSiteAt:): the size of the send bytecode and its number of arguments;
								 an interrupt check (see genPollBefore:): no send"
							[self metadata: metadata byteAt: index + OilMDSiteKind put: (siteKind at: siteIndex) + OilMDSiteCallFlag.
							 (oilSiteUsed at: siteIndex) = 2
								ifTrue:
									[self setScanMethod: (self frameAt: (siteFrame at: siteIndex)) method.
									 self decodeAt: (sitePC at: siteIndex).
									 self metadata: metadata byteAt: index + OilMDSiteSendSize put: oilNextPC - (sitePC at: siteIndex).
									 self metadata: metadata byteAt: index + OilMDSiteSendNumArgs put: (self numArgsOfCallAt: siteInstruction)]
								ifFalse:
									[self metadata: metadata byteAt: index + OilMDSiteSendSize put: 0.
									 self metadata: metadata byteAt: index + OilMDSiteSendNumArgs put: OilMDSiteNoSend].
							 index := index + OilMDSiteHeaderSize + OilMDSiteCallSize]
						ifFalse:
							[self metadata: metadata byteAt: index + OilMDSiteKind put: (siteKind at: siteIndex).
							 index := index + OilMDSiteHeaderSize]].
			 poolBase := siteSnapBase at: siteIndex.
			 0 to: (self siteStateSize: siteIndex) - 1 do:
				[:stateIndex|
				index := index + (self metadata: metadata
										stateDescriptorAt: index
										kind: (sitePoolKind at: poolBase + stateIndex)
										value: (sitePoolValue at: poolBase + stateIndex)
										reg: (self site: siteIndex stateRegister: stateIndex))]]].
	self assert: index = (base + oilMDNumBytes)! !


!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/25/2026 22:30'!
oilApiFloatBitsOf: floatOop
	"The bits of the double of a SmallFloat64 or a BoxedFloat64 (see OilInliningCompiler>>cacheFloatLiteral:in:)."
	<api>
	<essential: #ProfilingCogit>
	<returnTypeC: #sqLong>
	^(objectMemory isImmediate: floatOop)
		ifTrue: [objectMemory smallFloatBitsOf: floatOop]
		ifFalse: [objectMemory fetchLong64: 0 ofObject: floatOop]! !

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

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/26/2026 21:00'!
oilApiMethodClassAssociationOf: aMethod
	"The last literal of aMethod, its method class association, if it is a pointer object of at least two slots, else 0."
	<essential: #ProfilingCogit>
	| numLits lit |
	numLits := objectMemory literalCountOf: aMethod.
	numLits <= 0 ifTrue: [^0].
	lit := self literal: numLits - 1 ofMethod: aMethod.
	((objectMemory isNonImmediate: lit)
	 and: [(objectMemory isPointersNonImm: lit)
	 and: [(objectMemory numSlotsOf: lit) >= 2]]) ifFalse: [^0].
	^lit! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/26/2026 21:00'!
oilApiClassBindingClassOf: aMethod
	"The class of the last literal of aMethod, its method class association, if it is a class binding (pointers, at least
	 two slots, a key; on the class side the key is nil), else 0."
	<api>
	<essential: #ProfilingCogit>
	| lit |
	lit := self oilApiMethodClassAssociationOf: aMethod.
	(lit ~= 0 and: [(objectMemory fetchPointer: 0 ofObject: lit) ~= objectMemory nilObject]) ifFalse: [^0].
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

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/26/2026 10:00'!
oilAllocateMetadata: numLiterals numBytes: numBytes
	"Answer a hidden (class index pun), old space object of CompiledMethod format for the deoptimization metadata
	 of an Oil method: a method header (the number of literals), numLiterals literals (nil), then numBytes bytes (0); or 0.
	 It is referenced from the method (see ProfilingCogit>>maybeMarkCountersIn:): the garbage collectors trace its literal
	 frame only, like a method's, and never look at its bytes.  It is not pinned: a full GC may move it, and then updates
	 the method's reference (see ProfilingCogit>>mapObjectReferencesInMachineCodeForFullGC)."
	<api>
	<essential: #ProfilingCogit>
	| numTrailingBytes numSlots obj |
	numTrailingBytes := 0 - numBytes bitAnd: objectMemory wordSize - 1.
	numSlots := numLiterals + 1 + (numBytes + numTrailingBytes // objectMemory wordSize).
	obj := objectMemory
			allocateSlotsInOldSpace: numSlots
			bytes: (objectMemory objectBytesForSlots: numSlots)
			format: objectMemory firstCompiledMethodFormat + numTrailingBytes
			classIndex: objectMemory arrayClassIndexPun.
	obj isNil ifTrue: [^0].
	objectMemory storePointerUnchecked: 0 ofObject: obj withValue: (objectMemory integerObjectOf: numLiterals).
	1 to: numLiterals do:
		[:slotIndex| objectMemory storePointerUnchecked: slotIndex ofObject: obj withValue: objectMemory nilObject].
	numLiterals + 1 to: numSlots - 1 do:
		[:slotIndex| objectMemory storeLong64: slotIndex ofObject: obj withValue: 0].
	^obj! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:00'!
oilMD: metadata byteAt: index
	"The bytes of the Oil metadata (see OilInliningCompiler>>fillMetadata:cogMethod:) are little endian; index is a byte
	 index in the body of the object."
	<inline: true>
	<essential: #ProfilingCogit>
	^objectMemory fetchByte: index ofObject: metadata! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:00'!
oilMD: metadata byteAt: index put: byte
	"(for OilInliningCompiler>>fillMetadata:cogMethod:)"
	<api>
	<essential: #ProfilingCogit>
	objectMemory storeByte: index ofObject: metadata withValue: byte! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:00'!
oilMD: metadata s8At: index
	<inline: true>
	<essential: #ProfilingCogit>
	| byte |
	byte := self oilMD: metadata byteAt: index.
	^byte > 127 ifTrue: [byte - 256] ifFalse: [byte]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:00'!
oilMD: metadata u16At: index
	<inline: true>
	<essential: #ProfilingCogit>
	^(self oilMD: metadata byteAt: index) + ((self oilMD: metadata byteAt: index + 1) bitShift: 8)! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:00'!
oilMD: metadata s16At: index
	<inline: true>
	<essential: #ProfilingCogit>
	| value |
	value := self oilMD: metadata u16At: index.
	^value > 32767 ifTrue: [value - 65536] ifFalse: [value]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:00'!
oilMD: metadata u32At: index
	<inline: true>
	<essential: #ProfilingCogit>
	^(self oilMD: metadata u16At: index) + ((self oilMD: metadata u16At: index + 2) bitShift: 16)! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:00'!
oilMD: metadata u32At: index put: value
	<essential: #ProfilingCogit>
	objectMemory
		storeByte: index ofObject: metadata withValue: (value bitAnd: 255);
		storeByte: index + 1 ofObject: metadata withValue: ((value bitShift: -8) bitAnd: 255);
		storeByte: index + 2 ofObject: metadata withValue: ((value bitShift: -16) bitAnd: 255);
		storeByte: index + 3 ofObject: metadata withValue: ((value bitShift: -24) bitAnd: 255)! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:00'!
oilMDBase: metadata
	"The byte index of the header of the bytes of the Oil metadata, after its literal frame."
	<inline: true>
	<essential: #ProfilingCogit>
	^(objectMemory literalCountOf: metadata) + 1 * objectMemory wordSize! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:00'!
oilMD: metadata header: field
	"Answer the u16 header field of the Oil metadata at the byte offset field (OilMDNumSites, OilMDFrames...)."
	<api>
	<essential: #ProfilingCogit>
	^self oilMD: metadata u16At: (self oilMDBase: metadata) + field! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:00'!
oilMDCounter: field of: metadata
	"Answer the u32 counter of the Oil metadata at the byte offset field (OilMDDeopts or OilMDFastPaths)."
	<api>
	<essential: #ProfilingCogit>
	^self oilMD: metadata u32At: (self oilMDBase: metadata) + field! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:00'!
oilMDIncrement: field of: metadata
	<essential: #ProfilingCogit>
	self oilMD: metadata u32At: (self oilMDBase: metadata) + field put: (self oilMDCounter: field of: metadata) + 1! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:00'!
oilMD: metadata literalAt: index
	"Answer the literal of the Oil metadata whose index is the u16 at index."
	<api>
	<essential: #ProfilingCogit>
	^objectMemory fetchPointer: (self oilMD: metadata u16At: index) ofObject: metadata! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:00'!
oilMD: metadata descriptorValueAt: descIndex
	"The value of a descriptor: a register, a virtual object index, or, for a constant, its literal index."
	<inline: true>
	<essential: #ProfilingCogit>
	^(self oilMD: metadata u16At: descIndex) bitAnd: (1 << OilMDDescriptorValueBits) - 1! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:00'!
oilMD: metadata constantAt: descIndex
	"The object of the constant descriptor at descIndex."
	<inline: true>
	<essential: #ProfilingCogit>
	^self oilMD: metadata literal: (self oilMD: metadata descriptorValueAt: descIndex)! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:30'!
oilMD: metadata literal: litIndex
	"The constant of literal index litIndex of a descriptor: literal 0 (the header slot) stands for nil."
	<inline: true>
	<essential: #ProfilingCogit>
	^litIndex = 0
		ifTrue: [objectMemory nilObject]
		ifFalse: [objectMemory fetchPointer: litIndex ofObject: metadata]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:00'!
oilSpillOffsetOf: virtualReg metadata: metadata
	"Answer the spill offset (frame offset) of virtualReg in the Oil metadata, or 0 if it has no spill slot."
	<essential: #ProfilingCogit>
	| entry |
	entry := self oilMD: metadata header: OilMDSpillOffsets.
	1 to: (self oilMD: metadata header: OilMDNumSpills) do:
		[:spillIndex|
		 (self oilMD: metadata byteAt: entry) = virtualReg ifTrue:
			[^self oilMD: metadata s16At: entry + 1].
		 entry := entry + OilMDSpillEntrySize].
	^0! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:00'!
oilReadSpilledRegistersOf: theFP into: regValues metadata: metadata
	"Read the virtual registers from their spill slots in the frame at theFP into regValues (nil for those without one)."
	<essential: #ProfilingCogit>
	<var: #theFP type: #'char *'>
	<var: #regValues type: #'sqInt *'>
	| entry |
	0 to: OilNumRegs - 1 do:
		[:reg| regValues at: reg put: objectMemory nilObject].
	entry := self oilMD: metadata header: OilMDSpillOffsets.
	1 to: (self oilMD: metadata header: OilMDNumSpills) do:
		[:spillIndex|
		 regValues
			at: (self oilMD: metadata byteAt: entry)
			put: (stackPages longAt: theFP + (self oilMD: metadata s16At: entry + 1)).
		 entry := entry + OilMDSpillEntrySize]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/27/2026 15:05'!
ceOilDeoptimize: siteIndex
	"Called from ceOilDeoptTrampoline by the deopt sequence of an Oil method (see OilInliningCompiler>>genDeoptStubs)
	 when a guard fails at deopt site siteIndex.  framePointer is the Oil method's frame, whose virtual registers
	 have all been spilled to their spill slots; the top of stack is the return address into the deopt sequence.
	 Fast path: a class guard failed on a forwarder (become:) whose target passes the guard: store the target in
	 the register's spill slot and answer the address of the guard; the machine code reloads its registers and resumes
	 there, without deoptimizing.
	 Slow path: deoptimize.  Replace the frame by the contexts of the method and of the methods and blocks inlined
	 into it at the site, with the closures, temp vectors and objects Oil dissolved rematerialized, and continue in
	 the interpreter in the innermost context at the site's bytecode.  This does not return."
	<api>
	<essential: #ProfilingCogit>
	<returnTypeC: #usqInt>
	| cogMethod metadata siteRecord siteKind spillOffset value ctxt leaf |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := self mframeHomeMethod: framePointer.
	self assert: (cogit isOilMethod: cogMethod).
	metadata := cogit oilMetadataOf: cogMethod.
	siteRecord := self oilMD: metadata u16At: (self oilMD: metadata header: OilMDSiteTable) + (2 * siteIndex).
	self assert: siteRecord > 0.
	siteKind := (self oilMD: metadata byteAt: siteRecord + OilMDSiteKind) bitAnd: OilMDSiteCallFlag - 1.
	((self oilMD: metadata byteAt: siteRecord + OilMDSiteKind) >= OilMDSiteGuardFlag "a class guard"
	 and: [siteKind = OilSiteGuard
	 and: [(spillOffset := self oilSpillOffsetOf: (self oilMD: metadata byteAt: siteRecord + OilMDSiteGuardReg) metadata: metadata) ~= 0]]) ifTrue:
		[value := stackPages longAt: framePointer + spillOffset.
		 ((objectMemory isNonImmediate: value)
		  and: [objectMemory isForwarded: value]) ifTrue:
			[value := objectMemory followForwarded: value.
			 (objectMemory fetchClassTagOf: value) = (self oilMD: metadata u32At: siteRecord + OilMDSiteClassTag) ifTrue:
				[stackPages longAt: framePointer + spillOffset put: value.
				 self oilMDIncrement: OilMDFastPaths of: metadata.
				 ^cogMethod asUnsignedInteger + (self oilMD: metadata u16At: siteRecord + OilMDSiteResumeOffset)]]].
	siteKind ~= OilSiteAlloc ifTrue: "an allocation beyond the scavenge threshold is not a failed speculation"
		[self oilMDIncrement: OilMDDeopts of: metadata].
	instructionPointer := self popStack. "the return address into the deopt sequence"
	self setHeadFP: framePointer andSP: stackPointer inPage: stackPage.
	ctxt := self ensureFrameIsMarried: framePointer SP: framePointer + FoxMFReceiver.
	leaf := self oilDeoptimizeFrame: framePointer context: ctxt site: siteRecord.
	self nilStackPage.
	framePointer := 0.
	(self oilMDCounter: OilMDDeopts of: metadata) >= cogit oilDisqualifyLimit ifTrue:
		[self oilDisqualifyCogMethod: cogMethod].
	self marryContextInNewStackPageAndInitializeInterpreterRegisters: leaf.
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

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/27/2026 18:00'!
oilDisqualifyCogMethod: cogMethod
	"The Oil method cogMethod deoptimized OilDisqualifyDeopts times (its speculations do not hold): never compile its
	 method with Oil again, deoptimize any other activations running it, and free it, unlinking the sends to it, so that
	 the baseline JIT compiles the method again, instead of running it in the interpreter after each deopt."
	<essential: #ProfilingCogit>
	<var: #cogMethod type: #'CogMethod *'>
	cogit oilDisqualify: cogMethod methodObject.
	self oilDeoptimizeFramesOf: cogMethod! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/27/2026 15:05'!
oilFindSuspendedFrameOf: cogMethod
	"Answer a suspended machine code frame (not the active frame) running cogMethod, or 0."
	<essential: #ProfilingCogit>
	<returnTypeC: #'char *'>
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
				[(theFP ~= framePointer
				  and: [(self isMachineCodeFrame: theFP)
				  and: [(self mframeHomeMethod: theFP) = cogMethod]]) ifTrue: [^theFP].
				 theFP := self frameCallerFP: theFP]]].
	^0! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/27/2026 15:15'!
oilDeoptimizeFramesOf: cogMethod
	"Deoptimize every suspended machine code frame running the Oil method cogMethod into heap contexts (see
	 oilDeoptimizeFrame:context:), then free cogMethod if no frame is still running it."
	<api>
	<essential: #ProfilingCogit>
	<var: #cogMethod type: #'CogMethod *'>
	<var: #theFP type: #'char *'>
	| inInterpreter activeContext theFP ctxt |
	(self oilFindSuspendedFrameOf: cogMethod) ~= 0 ifTrue:
		[inInterpreter := instructionPointer >= objectMemory startOfMemory.
		 activeContext := stackPage ifNotNil: [self oilMarryActiveFrame].
		 [(theFP := self oilFindSuspendedFrameOf: cogMethod) ~= 0] whileTrue:
			[stackPage ifNotNil: [stackPages markStackPageMostRecentlyUsed: stackPage].
			 ctxt := self ensureFrameIsMarried: theFP SP: theFP + FoxMFReceiver.
			 (self oilDeoptimizeFrame: theFP context: ctxt) = 0 ifTrue:
				[activeContext ifNotNil:
					[self oilResumeContext: activeContext.
					 inInterpreter ifTrue: [instructionPointer := self iframeSavedIP: framePointer]].
				 ^self]].
		 activeContext ifNotNil:
			[self oilResumeContext: activeContext.
			 inInterpreter ifTrue: [instructionPointer := self iframeSavedIP: framePointer]]].
	(self oilHasFramesOf: cogMethod) ifFalse:
		[cogit unlinkSendsTo: cogMethod methodObject andFreeIf: true]! !

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

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:30'!
oilDecodeStateOf: site metadata: metadata into: state
	"Decode the virtual state of the site record at site into state: the descriptor (kind << OilMDDescriptorValueBits + value) of each
	 register of the register window 0..top and of the high registers high+1..OilMaxReg, OilMDNoDescriptor for the
	 others.  The state descriptors are 1 byte for the commonest (a register holding its own value: OilMDStateOwn; nil:
	 OilMDStateNil), else 2 bytes, big endian, the first with its top bit set: the kind (3 bits), then a 12-bit value."
	<essential: #ProfilingCogit>
	<var: #state type: #'unsigned short *'>
	| top high index byte reg |
	top := self oilMD: metadata byteAt: site + OilMDSiteTop.
	high := self oilMD: metadata byteAt: site + OilMDSiteHigh.
	index := site + (self oilMDSiteHeaderSizeOf: site metadata: metadata).
	0 to: OilNumRegs - 1 do:
		[:i| state at: i put: OilMDNoDescriptor].
	0 to: top + (OilMaxReg - high) do:
		[:stateIndex|
		reg := stateIndex <= top ifTrue: [stateIndex] ifFalse: [high + stateIndex - top].
		byte := self oilMD: metadata byteAt: index.
		index := index + 1.
		byte = OilMDStateOwn
			ifTrue: [state at: reg put: reg] "(OilDescReg is 0)"
			ifFalse:
				[byte = OilMDStateNil
					ifTrue: [state at: reg put: OilDescConst << OilMDDescriptorValueBits] "(literal 0: nil)"
					ifFalse:
						[self assert: byte >= 128.
						 state
							at: reg
							put: ((byte >> 4 bitAnd: 7) << OilMDDescriptorValueBits)
								+ ((byte bitAnd: 15) << 8)
								+ (self oilMD: metadata byteAt: index).
						 index := index + 1]]]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:30'!
oilMDSiteHeaderSizeOf: site metadata: metadata
	"The site records of class guards (OilMDSiteGuardFlag) have the guarded register and the class tag after the header,
	 those of calls (OilMDSiteCallFlag) the size of the send bytecode and its number of arguments."
	<inline: true>
	<essential: #ProfilingCogit>
	| kind |
	kind := self oilMD: metadata byteAt: site + OilMDSiteKind.
	kind >= OilMDSiteGuardFlag ifTrue: [^OilMDSiteHeaderSize + OilMDSiteGuardSize].
	(kind bitAnd: OilMDSiteCallFlag) ~= 0 ifTrue: [^OilMDSiteHeaderSize + OilMDSiteCallSize].
	^OilMDSiteHeaderSize! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/25/2026 15:00'!
oilIsVirtualObjectKind: kind
	"Is kind the descriptor kind of a virtual object (a dissolved closure or temp vector, or a scalar replaced object)?"
	<inline: true>
	<essential: #ProfilingCogit>
	^kind = OilDescBlock or: [kind = OilDescTempVector or: [kind = OilDescObject]]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:30'!
oilValueOf: desc metadata: metadata values: regValues vobjs: vobjOops
	"Answer the value described by the descriptor desc (or nil for OilMDNoDescriptor): a register's value (read from its
	 spill slot before the frame was rewritten), a constant (a literal of the metadata), or a rematerialized virtual
	 object (or nil if not yet allocated)."
	<essential: #ProfilingCogit>
	<var: #regValues type: #'sqInt *'>
	<var: #vobjOops type: #'sqInt *'>
	| kind value |
	desc = OilMDNoDescriptor ifTrue: [^objectMemory nilObject].
	kind := desc >> OilMDDescriptorValueBits.
	value := desc bitAnd: (1 << OilMDDescriptorValueBits) - 1.
	kind = OilDescConst ifTrue:
		[^self oilMD: metadata literal: value].
	(self oilIsVirtualObjectKind: kind) ifTrue:
		[^(vobjOops at: value) = 0
			ifTrue: [objectMemory nilObject]
			ifFalse: [vobjOops at: value]].
	^regValues at: value! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/27/2026 15:05'!
oilNeedVObjOf: desc needed: needed
	"If the descriptor desc is a virtual object, mark it as needed."
	<essential: #ProfilingCogit>
	<var: #needed type: #'char *'>
	| vobjIndex |
	desc = OilMDNoDescriptor ifTrue: [^self].
	(self oilIsVirtualObjectKind: desc >> OilMDDescriptorValueBits) ifFalse: [^self].
	vobjIndex := desc bitAnd: (1 << OilMDDescriptorValueBits) - 1.
	(needed at: vobjIndex) = 0 ifTrue: [needed at: vobjIndex put: 1]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 10:30'!
oilMarkVObjsNeededBy: needed state: state metadata: metadata
	"Mark as needed the virtual objects that the needed ones refer to, transitively: a closure's receiver and copied
	 values, a temp vector's or scalar replaced object's slots (registers of the decoded state).  needed at: i is 0 (not
	 needed), 1 (needed, its references not marked yet) or 2 (needed, its references marked)."
	<essential: #ProfilingCogit>
	<var: #needed type: #'char *'>
	<var: #state type: #'unsigned short *'>
	| vobjsBase numVObjs vobjRecord more |
	vobjsBase := self oilMD: metadata header: OilMDVObjs.
	numVObjs := self oilMD: metadata header: OilMDNumVObjs.
	more := true.
	[more] whileTrue:
		[more := false.
		 0 to: numVObjs - 1 do:
			[:i|
			(needed at: i) = 1 ifTrue:
				[needed at: i put: 2.
				 more := true.
				 vobjRecord := vobjsBase + (i * OilMDVObjSize).
				 (self oilMD: metadata byteAt: vobjRecord + OilMDVObjKind) = OilDescBlock
					ifTrue:
						[self oilNeedVObjOf: (self oilMD: metadata u16At: vobjRecord + OilMDVObjSelf) needed: needed.
						 0 to: (self oilMD: metadata byteAt: vobjRecord + OilMDVObjNumCopied) - 1 do:
							[:j| self oilNeedVObjOf: (self oilMD: metadata u16At: (self oilMD: metadata u16At: vobjRecord + OilMDVObjCopiedIndex) + (OilMDDescriptorSize * j)) needed: needed]]
					ifFalse:
						[0 to: (self oilMD: metadata u16At: vobjRecord + OilMDVObjLiteralOrSize) - 1 do:
							[:j| self oilNeedVObjOf: (state at: (self oilMD: metadata byteAt: vobjRecord + OilMDVObjSlotBase) + j) needed: needed]]]]]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/25/2026 15:00'!
oilAllocateVObjAt: vobjRecord metadata: metadata
	"Allocate the object of the virtual object record at vobjRecord, filled with nil: a FullBlockClosure, an instance
	 of the class of a scalar replaced object (with its current shape) or a temp vector (an Array)."
	<essential: #ProfilingCogit>
	| kind obj |
	kind := self oilMD: metadata byteAt: vobjRecord + OilMDVObjKind.
	obj := kind = OilDescBlock
			ifTrue:
				[objectMemory
					allocateSlots: FullClosureFirstCopiedValueIndex + (self oilMD: metadata byteAt: vobjRecord + OilMDVObjNumCopied)
					format: objectMemory indexablePointersFormat
					classIndex: ClassFullBlockClosureCompactIndex]
			ifFalse:
				[kind = OilDescObject
					ifTrue:
						[objectMemory
							allocateSlots: (objectMemory fixedFieldsOfClass: (self oilMD: metadata constantAt: vobjRecord + OilMDVObjSelf))
							format: (objectMemory instSpecOfClass: (self oilMD: metadata constantAt: vobjRecord + OilMDVObjSelf))
							classIndex: (objectMemory ensureBehaviorHash: (self oilMD: metadata constantAt: vobjRecord + OilMDVObjSelf))]
					ifFalse:
						[objectMemory
							allocateSlots: (self oilMD: metadata u16At: vobjRecord + OilMDVObjLiteralOrSize)
							format: objectMemory arrayFormat
							classIndex: ClassArrayCompactIndex]].
	obj isNil ifTrue: [^nil]. "(out of memory: see oilDeoptimizeFrame:context:)"
	objectMemory fillObj: obj numSlots: (objectMemory numSlotsOf: obj) with: objectMemory nilObject.
	^obj! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 20:50'!
oilTopRegs: topRegs chain: chain numFrames: numFrames innermost: innermostTop metadata: metadata
	"Fill topRegs with the top register of each activation of chain's part of the register window: innermostTop for the
	 innermost one, the register below the base register of the next one for the others."
	<essential: #ProfilingCogit>
	<var: #topRegs type: #'sqInt *'>
	<var: #chain type: #'sqInt *'>
	| framesBase |
	framesBase := self oilMD: metadata header: OilMDFrames.
	topRegs at: numFrames - 1 put: innermostTop.
	0 to: numFrames - 2 do:
		[:i| topRegs at: i put: (self oilMD: metadata byteAt: framesBase + ((chain at: i + 1) * OilMDFrameSize) + OilMDFrameBase) - 1]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 20:50'!
oilOuterChainIndexOf: vobjRecord chain: chain numFrames: numFrames metadata: metadata
	"Answer the index in chain of the activation that created the closure of the virtual object record vobjRecord, or -1
	 if it is not on the chain (or vobjRecord is not a closure's)."
	<essential: #ProfilingCogit>
	<var: #chain type: #'sqInt *'>
	| outerFrame |
	(self oilMD: metadata byteAt: vobjRecord + OilMDVObjKind) = OilDescBlock ifFalse: [^-1].
	outerFrame := self oilMD: metadata s8At: vobjRecord + OilMDVObjOuterFrame.
	0 to: numFrames - 1 do:
		[:j| (chain at: j) = outerFrame ifTrue: [^j]].
	^-1! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/26/2026 20:50'!
oilFillVObj: obj record: vobjRecord outerContext: context state: state metadata: metadata values: regValues vobjs: vobjOops
	"Fill in obj, the rematerialized object of the virtual object record vobjRecord: a closure's outerContext (context),
	 compiled block, number of arguments, receiver and copied values, or the slots of a temp vector or scalar replaced
	 object (registers of the decoded state)."
	<essential: #ProfilingCogit>
	<var: #state type: #'unsigned short *'>
	<var: #regValues type: #'sqInt *'>
	<var: #vobjOops type: #'sqInt *'>
	| numCopied |
	(self oilMD: metadata byteAt: vobjRecord + OilMDVObjKind) = OilDescBlock
		ifTrue:
			[numCopied := self oilMD: metadata byteAt: vobjRecord + OilMDVObjNumCopied.
			 objectMemory
				storePointer: ClosureOuterContextIndex ofObject: obj withValue: context;
				storePointer: FullClosureCompiledBlockIndex ofObject: obj withValue: (self oilMD: metadata literalAt: vobjRecord + OilMDVObjLiteralOrSize);
				storePointer: ClosureNumArgsIndex ofObject: obj withValue: (objectMemory integerObjectOf: (self argumentCountOf: (self oilMD: metadata literalAt: vobjRecord + OilMDVObjLiteralOrSize)));
				storePointer: FullClosureReceiverIndex ofObject: obj withValue: (self oilValueOf: (self oilMD: metadata u16At: vobjRecord + OilMDVObjSelf) metadata: metadata values: regValues vobjs: vobjOops).
			 0 to: numCopied - 1 do:
				[:j|
				objectMemory
					storePointer: FullClosureFirstCopiedValueIndex + j
					ofObject: obj
					withValue: (self oilValueOf: (self oilMD: metadata u16At: (self oilMD: metadata u16At: vobjRecord + OilMDVObjCopiedIndex) + (OilMDDescriptorSize * j)) metadata: metadata values: regValues vobjs: vobjOops)]]
		ifFalse:
			[0 to: ((self oilMD: metadata u16At: vobjRecord + OilMDVObjLiteralOrSize) min: (objectMemory numSlotsOf: obj)) - 1 do:
				[:j|
				objectMemory
					storePointer: j
					ofObject: obj
					withValue: (self oilValueOf: (state at: (self oilMD: metadata byteAt: vobjRecord + OilMDVObjSlotBase) + j) metadata: metadata values: regValues vobjs: vobjOops)]]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/27/2026 15:05'!
divorceFramesIn: aStackPage
	"Divorce all frames in aStackPage into MethodContexts.  Under #Oil, the frame of an Oil method becomes the contexts of
	 the activations it stands for (see oilContextsOfFrame:context:site:), the innermost of which is the sender of the
	 context of the frame above."
	<var: #aStackPage type: #'StackPage *'>
	| theFP calleeFP theSP theIP calleeContext theContext cogMethod leaf site |
	<var: #cogMethod type: #'CogMethod *'>
	<inline: false>
	statStackPageDivorce := statStackPageDivorce + 1.

	theFP := aStackPage headFP.
	theSP := aStackPage headSP.
	theIP := stackPages longAt: theSP.
	theSP := theSP + objectMemory wordSize. "theSP points at hottest item on frame's stack"
	calleeContext := nil.

	[leaf := 0.
	 self cppIf: #Oil ifTrue:
		[((self isMachineCodeFrame: theFP)
		  and: [cogit isOilMethod: (cogMethod := self mframeCogMethod: theFP)]) ifTrue:
			[theContext := self ensureFrameIsMarried: theFP SP: theFP + FoxMFReceiver.
			 site := self oilCallSiteForIP: theIP inCogMethod: cogMethod metadata: (cogit oilMetadataOf: cogMethod).
			 leaf := self oilContextsOfFrame: theFP context: theContext site: site]].
	 leaf = 0 ifTrue:
		[theContext := self ensureFrameIsMarried: theFP SP: theSP.
		 self updateStateOfSpouseContextForFrame: theFP WithSP: theSP.
		 objectMemory storePointerUnchecked: InstructionPointerIndex
			ofObject: theContext
			withValue: (self contextInstructionPointer: theIP frame: theFP).
		 self assert: (self frameReceiver: theFP)
					= (objectMemory followField: ReceiverIndex ofObject: theContext).
		 leaf := theContext].
	 calleeContext ifNotNil:
		[objectMemory storePointer: SenderIndex
			ofObject: calleeContext
			withValue: leaf].
	 calleeContext := theContext.
	 calleeFP := theFP.
	 theIP := self frameCallerSavedIP: theFP.
	 theFP := self frameCallerFP: theFP.
	 theFP ~= 0] whileTrue:
		["theSP points at stacked hottest item on frame's stack"
		 theSP := self frameCallerSP: calleeFP].

	objectMemory storePointer: SenderIndex
		ofObject: theContext
		withValue: (self frameCallerContext: calleeFP).

	"The page is now free; mark it so."
	aStackPage baseFP: 0! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-deoptimization' stamp: 'cb 10/27/2026 15:05'!
externalDivorceFrame: theFP andContext: ctxt
	"Divorce a single frame and its context.  If it is not the top frame of a stack this means splitting its stack.
	 Under #Oil, the frame of an Oil method becomes the contexts of the activations it stands for (see
	 oilDeoptimizeFrame:context:)."
	<var: 'theFP' type: #'char *'>
	<inline: false>
	| thePage onCurrent theSP callerCtx newPage frameAbove callerFP callerSP callerIP theIP |
	"stackPage needs to have current head pointers to avoid confusion."
	self assert: (stackPage isNil or: [stackPage = stackPages mostRecentlyUsedPage]).
	self cppIf: #Oil ifTrue:
		[((self isMachineCodeFrame: theFP)
		  and: [cogit isOilMethod: (self mframeCogMethod: theFP)]) ifTrue:
			[self oilDeoptimizeFrame: theFP context: ctxt.
			 ^self]].
	thePage := stackPages stackPageFor: theFP.
	(onCurrent := thePage = stackPage) ifFalse:
		[stackPages markStackPageNextMostRecentlyUsed: thePage].
	theSP := self findSPOf: theFP on: thePage.
	self updateStateOfSpouseContextForFrame: theFP WithSP: theSP.
	callerCtx := self ensureCallerContext: theFP.
	(frameAbove := self findFrameAbove: theFP inPage: thePage) = 0
		ifTrue: "If we're divorcing the top frame we can simply peel it off."
			[theIP := stackPages longAt: thePage headSP]
		ifFalse: "othewise move all frames above to a new stack and then peel the frame off."
			[newPage := stackPages newStackPage.
			 theIP := self frameCallerSavedIP: frameAbove.
			 frameAbove := self moveFramesIn: thePage through: frameAbove toPage: newPage.
			 onCurrent
				ifTrue:
					[self setStackPageAndLimit: newPage.
					 self setStackPointersFromPage: newPage]
				ifFalse:
					[stackPages markStackPageMostRecentlyUsed: newPage].
			 self assert: (self frameCallerContext: frameAbove) = ctxt].
	objectMemory storePointerUnchecked: InstructionPointerIndex
		ofObject: ctxt
		withValue: (self contextInstructionPointer: theIP frame: theFP).
	objectMemory storePointer: SenderIndex
		ofObject: ctxt
		withValue: callerCtx.
	callerFP := self frameCallerFP: theFP.
	callerFP = 0 "theFP is a base frame; it is now alone; free the entire page"
		ifTrue: [stackPages freeStackPage: thePage]
		ifFalse:
			[callerIP := self frameCallerSavedIP: theFP.
			 callerSP := (self frameCallerSP: theFP) - objectMemory wordSize.
			 stackPages longAt: callerSP put: callerIP.
			 self setHeadFP: callerFP andSP: callerSP inPage: thePage]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-initialization' stamp: 'cb 10/26/2026 05:00'!
checkImageHeaderLoad
	"Oil's minimum: a 4 MB code zone, and at least 128 stack pages.
	 Stack page eviction of an Oil frame requires deoptimizing it into interpreter
	 contexts, because an Oil frame inlines callees, holds spilled virtual registers,
	 and cannot be represented as a machine-code-offset context. To avoid premature
	 deoptimization of suspended processes (e.g. Delay>>wait, Semaphores, UI loop),
	 ensure the VM has at least 128 stack pages so eviction is an exceptional event."
	<inline: #always>
	cogCodeSize < (4 * 1024 * 1024) ifTrue:
		[cogCodeSize := 4 * 1024 * 1024].
	self cppIf: #Oil ifTrue:
		["Stack page eviction requires deoptimization"
		 numStackPages < 128 ifTrue:
			[numStackPages := 128]]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-initialization' stamp: 'cb 10/26/2026 05:00'!
attemptToSwitchToMachineCode: bcpc
	"Attempt to convert the current interpreted activation into a machine code
	 activation, and if this is popssible, jump into machine code.  bcpc is the
	 0-relative pc of the backward branch bytecode (not any preceding extension).
	 An Oil method's machine code does not correspond to its bytecodes: stay in the interpreter."
	| cogMethod pc cls |
	<inline: false>
	<var: #cogMethod type: #'CogMethod *'>
	self cppIf: #Oil ifTrue:
		[((self methodHasCogMethod: method)
		  and: [cogit isOilMethod: (self cogMethodOf: method)]) ifTrue:
			[^nil]].
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


!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/26/2026 20:30'!
oilMarryActiveFrame
	"Before a primitive frees machine code (c.f. primitiveVoidVMStateForMethod), marry the active frame, push the
	 instruction pointer and write back the head frame pointers.  Answer the context of the active frame (see
	 oilReturnToContext:pushing:)."
	<essential: #ProfilingCogit>
	| activeContext |
	activeContext := self ensureFrameIsMarried: framePointer SP: stackPointer.
	self ensurePushedInstructionPointer.
	self externalWriteBackHeadFramePointers.
	^activeContext! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/26/2026 20:30'!
oilResumeContext: activeContext
	"Resume the frame of activeContext (see oilMarryActiveFrame), still married: make its page current and pop its
	 instruction pointer."
	<essential: #ProfilingCogit>
	| theFrame thePage |
	<var: #theFrame type: #'char *'>
	<var: #thePage type: #'StackPage *'>
	theFrame := self frameOfMarriedContext: activeContext.
	thePage := stackPages stackPageFor: theFrame.
	self assert: thePage headFP = theFrame.
	self setStackPageAndLimit: thePage.
	self setStackPointersFromPage: thePage.
	instructionPointer := self popStack! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/26/2026 20:30'!
oilReturnToContext: activeContext pushing: resultOop
	"Return from the primitive to activeContext (see oilMarryActiveFrame) with resultOop.  If freeing machine code
	 divorced it, continue in the interpreter."
	<essential: #ProfilingCogit>
	(self isStillMarriedContext: activeContext) ifFalse:
		[self nilStackPage. "to avoid assert in marryContextInNewStackPageAndInitializeInterpreterRegisters:"
		 self marryContextInNewStackPageAndInitializeInterpreterRegisters: activeContext.
		 self popStack. "pop bogus machine-code instructionPointer"
		 self pop: argumentCount + 1 thenPush: resultOop.
		 cogit ceInvokeInterpret
		 "NOTREACHED"].
	self oilResumeContext: activeContext.
	self pop: argumentCount + 1 thenPush: resultOop! !

!CoInterpreterPrimitives methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/26/2026 20:30'!
primitiveOilCompile
	"Receiver: a CompiledMethod; argument: the class of the receivers to specialize it for.
	 Compile the method with the Oil optimizing JIT and install the result as its machine code, replacing any
	 baseline machine code.  The inline caches of the baseline machine code (and of the methods and blocks it
	 calls) are the type feedback, so run the method first.  Answer a SmallInteger, 0 (OilOK) on success, else an
	 Oil failure code (see OilConstants), in which case the method is left as it was."
	<export: true>
	<essential: #ProfilingCogit>
	| methodObj classObj result activeContext |
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
	self oilEnsureExtraSelectorTable ifFalse:
		[^self primitiveFailFor: PrimErrNoMemory].
	"Pass 1 first, while the baseline inline caches (type feedback) are there."
	result := cogit oilCompile: methodObj receiverClass: classObj.
	result ~= OilOK ifTrue:
		[^self pop: 2 thenPush: (objectMemory integerObjectOf: result)].
	"Free the baseline machine code, then run Pass 3 and install."
	activeContext := self oilMarryActiveFrame.
	self oilFreeMachineCodeOf: methodObj.
	result := cogit oilGenerate: methodObj.
	self oilReturnToContext: activeContext pushing: (objectMemory integerObjectOf: result)! !

!CoInterpreterPrimitives methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/27/2026 14:05'!
primitiveOilGetOrSetColdSelectors
	"The cold selectors Oil never inlines (error paths, slow paths).  Without argument, answer them: the Array of Symbols
	 the image set, or nil for the default ones (see OilInliningCompiler class>>defaultColdSelectors).  With an argument,
	 an Array of Symbols or nil (the default ones), set them and answer the previous ones (an Array or nil)."
	<export: true>
	<inline: false>
	<essential: #ProfilingCogit>
	| previous err |
	argumentCount > 1 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	previous := self oilColdSelectorsObject.
	argumentCount = 0 ifTrue:
		[^self pop: 1 thenPush: previous].
	err := self oilSetColdSelectorsObject: self stackTop.
	err ~= 0 ifTrue:
		[^self primitiveFailFor: err].
	self pop: 2 thenPush: previous! !

!CoInterpreterPrimitives methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/27/2026 14:05'!
primitiveOilSetColdSelectors
	<export: true>
	<essential: #ProfilingCogit>
	self primitiveOilGetOrSetColdSelectors! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/27/2026 14:05'!
oilColdSelectorsObject
	<essential: #ProfilingCogit>
	| previous |
	previous := cogit getOilColdSelectors.
	^previous = 0
		ifTrue: [objectMemory nilObject]
		ifFalse: [objectMemory followMaybeForwarded: previous]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/27/2026 14:05'!
oilSetColdSelectorsObject: selectors
	"Validate and set selectors (an Array of Symbols or nil).  Answer 0 on success, or a PrimErr* code."
	<inline: false>
	<essential: #ProfilingCogit>
	| symbolTag wasUnset selector |
	selectors ~= objectMemory nilObject ifTrue:
		[((objectMemory isNonImmediate: selectors) and: [objectMemory isArrayNonImm: selectors]) ifFalse:
			[^PrimErrBadArgument].
		 symbolTag := objectMemory fetchClassTagOf: (objectMemory splObj: SelectorDoesNotUnderstand).
		 0 to: (objectMemory numSlotsOf: selectors) - 1 do:
			[:i|
			selector := objectMemory followMaybeForwarded: (objectMemory fetchPointer: i ofObject: selectors).
			((objectMemory isNonImmediate: selector) and: [(objectMemory fetchClassTagOf: selector) = symbolTag]) ifFalse:
				[^PrimErrBadArgument]]].
	wasUnset := cogit getOilColdSelectors = 0.
	cogit setOilColdSelectors: selectors.
	wasUnset ifTrue: "(the variable becomes a GC root when it first holds an object)"
		[(objectMemory addGCRoot: cogit oilColdSelectorsAddress) ifFalse:
			[cogit setOilColdSelectors: 0.
			 ^PrimErrNoMemory]].
	^0! !

!CoInterpreterPrimitives methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/27/2026 14:05'!
primitiveOilGetOrSetParameter
	"Unified tuning parameter primitive (see OilInliningCompiler>>oilParameterAt:):
	 - 0 arguments: answer an Array of pairs {index. value. ...} for parameters 1, 2, 3, 4, 5, 7, 8, 12, 14, 19.
	 - 1 argument (index): answer the current value of parameter index.
	 - 2 arguments (index, value): set parameter index to value (0 or nil resets to default) and answer the previous value."
	<export: true>
	<inline: false>
	<essential: #ProfilingCogit>
	| result indices index val prev err paramIndex paramObj |
	<var: #indices declareC: 'static const sqInt indices[10] = {1, 2, 3, 4, 5, 7, 8, 12, 14, 19}'>
	argumentCount > 2 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	argumentCount = 0 ifTrue:
		[self cCode: [] inSmalltalk: [indices := CArrayAccessor on: #(1 2 3 4 5 7 8 12 14 19)].
		 result := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: 20.
		 result ifNil: [^self primitiveFailFor: PrimErrNoMemory].
		 0 to: 9 do:
			[:i|
			paramIndex := indices at: i.
			paramObj := paramIndex = 7
				ifTrue: [self oilColdSelectorsObject]
				ifFalse: [paramIndex = 19
					ifTrue: [objectMemory integerObjectOf: (cogit oilAutoCompileEnabled ifTrue: [1] ifFalse: [0])]
					ifFalse: [objectMemory integerObjectOf: (cogit oilParameterAt: paramIndex)]].
			objectMemory storePointer: i * 2 ofObject: result withValue: (objectMemory integerObjectOf: paramIndex).
			objectMemory storePointer: i * 2 + 1 ofObject: result withValue: paramObj].
		 ^self pop: 1 thenPush: result].
	(objectMemory isIntegerObject: (self stackValue: argumentCount - 1)) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	index := objectMemory integerValueOf: (self stackValue: argumentCount - 1).
	argumentCount = 1 ifTrue:
		[index = 7 ifTrue: [^self pop: 2 thenPush: self oilColdSelectorsObject].
		 index = 19 ifTrue: [^self pop: 2 thenPush: (objectMemory integerObjectOf: (cogit oilAutoCompileEnabled ifTrue: [1] ifFalse: [0]))].
		 prev := cogit oilParameterAt: index.
		 prev < 0 ifTrue: [^self primitiveFailFor: PrimErrBadArgument].
		 ^self pop: 2 thenPush: (objectMemory integerObjectOf: prev)].
	val := self stackTop.
	index = 7 ifTrue:
		[prev := self oilColdSelectorsObject.
		 err := self oilSetColdSelectorsObject: val.
		 err ~= 0 ifTrue: [^self primitiveFailFor: err].
		 ^self pop: 3 thenPush: prev].
	index = 19 ifTrue:
		[prev := cogit oilAutoCompileEnabled ifTrue: [1] ifFalse: [0].
		 (val = objectMemory trueObject or: [val = (objectMemory integerObjectOf: 1)])
			ifTrue: [cogit oilSetAutoCompileEnabled: true]
			ifFalse:
				[(val = objectMemory falseObject or: [val = (objectMemory integerObjectOf: 0)])
					ifTrue: [cogit oilSetAutoCompileEnabled: false]
					ifFalse: [^self primitiveFailFor: PrimErrBadArgument]].
		 ^self pop: 3 thenPush: (objectMemory integerObjectOf: prev)].
	(objectMemory isIntegerObject: val) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	prev := cogit oilParameterAt: index put: (objectMemory integerValueOf: val).
	prev < 0 ifTrue:
		[^self primitiveFailFor: PrimErrBadArgument].
	self pop: 3 thenPush: (objectMemory integerObjectOf: prev)! !

!CoInterpreterPrimitives methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/27/2026 14:05'!
primitiveOilSetParameter
	<export: true>
	<essential: #ProfilingCogit>
	self primitiveOilGetOrSetParameter! !

!CoInterpreterPrimitives methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/26/2026 22:20'!
primitiveOilSetAutonomousCompilation
	"Argument: true (the default) or 1 to compile the hot methods the trip counters find with Oil (see ceOilTrip:), false or
	 0 not to.  Answer the receiver."
	<export: true>
	<essential: #ProfilingCogit>
	| flag |
	argumentCount ~= 1 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	flag := self stackTop.
	(flag = objectMemory trueObject or: [flag = (objectMemory integerObjectOf: 1)]) ifTrue:
		[cogit oilSetAutoCompileEnabled: true.
		 ^self pop: 1].
	(flag = objectMemory falseObject or: [flag = (objectMemory integerObjectOf: 0)]) ifTrue:
		[cogit oilSetAutoCompileEnabled: false.
		 ^self pop: 1].
	self primitiveFailFor: PrimErrBadArgument! !

!CoInterpreterPrimitives methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/26/2026 22:20'!
primitiveOilSetDisqualifyLimit
	"Argument: a SmallInteger, the number of deoptimizations after which an Oil method is freed and disqualified (0 or less:
	 the default, OilDisqualifyDeopts).  Answer the receiver."
	<export: true>
	<essential: #ProfilingCogit>
	argumentCount ~= 1 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	(objectMemory isIntegerObject: self stackTop) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	cogit oilSetDisqualifyLimit: (objectMemory integerValueOf: self stackTop).
	self pop: 1! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/26/2026 15:00'!
oilEnsureExtraSelectorTable
	"Allocate the Oil selector table (a GC root, see ProfilingCogit>>oilExtraSelectorIndexOf:add:) if not yet done.  Answer
	 whether there is one.  (Allocation cannot run the garbage collector.)"
	<essential: #ProfilingCogit>
	| table |
	cogit getOilExtraSelectors ~= 0 ifTrue: [^true].
	table := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: OilMaxExtraSelectors.
	table isNil ifTrue: [^false].
	cogit setOilExtraSelectors: table.
	(objectMemory addGCRoot: cogit oilExtraSelectorsAddress) ifFalse:
		[cogit setOilExtraSelectors: 0.
		 ^false].
	^true! !

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
	cogMethod := ((self methodHasCogMethod: methodObj)
				  and: [cogit isOilMethod: (self cogMethodOf: methodObj)])
					ifTrue: [self cogMethodOf: methodObj]
					ifFalse: [cogit oilFirstSpecializedCogMethodOf: methodObj].
	cogMethod ifNil:
		[^self pop: argumentCount + 1 thenPush: objectMemory nilObject].
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
		storePointerUnchecked: 0 ofObject: result withValue: (objectMemory integerObjectOf: (self oilMDCounter: OilMDDeopts of: metadata));
		storePointerUnchecked: 1 ofObject: result withValue: (objectMemory integerObjectOf: (self oilMDCounter: OilMDFastPaths of: metadata));
		storePointer: 2 ofObject: result withValue: code;
		storePointerUnchecked: 3 ofObject: result withValue: (objectMemory integerObjectOf: cogMethod asUnsignedInteger).
	self pop: argumentCount + 1 thenPush: result! !

!CoInterpreterPrimitives methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/26/2026 20:30'!
primitiveOilLastCompilation
	"Answer an Array describing the last Oil compilation, for debugging:
	 { failure code. IR words (an Array of SmallIntegers). eager closures (0/1). IR index the back end failed at.
	   number of deopt sites. number of inlined frames. number of spill slots. number of allocated registers.
	   microseconds Passes 1 to 3 took (including assembling the CogMethod and its metadata, not freeing the baseline code).
	   Pass 1 IR words (after loop unrolling, the IR Pass 2 optimized again, see OilLoopOptimizer>>loopOptimize).
	   Pass 2 statistics (see OilCompiler>>pass2Statistics:).
	   bytes of the deoptimization metadata object }"
	<export: true>
	<essential: #ProfilingCogit>
	| irWordCount irArray result statsArray |
	irWordCount := cogit oilDebugInfo: 1 at: 0.
	irArray := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: irWordCount.
	result := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: 12.
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
	statsArray := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: 27.
	statsArray isNil ifTrue: [^self primitiveFailFor: PrimErrNoMemory].
	0 to: 26 do:
		[:slotIndex| objectMemory storePointerUnchecked: slotIndex ofObject: statsArray withValue: (objectMemory integerObjectOf: (cogit oilDebugInfo: 13 at: slotIndex))].
	objectMemory storePointer: 10 ofObject: result withValue: statsArray.
	objectMemory storePointerUnchecked: 11 ofObject: result withValue: (objectMemory integerObjectOf: (cogit oilDebugInfo: 9 at: 0)).
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


!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-debugging' stamp: 'cb 10/26/2026 14:30'!
oilFrameOfContext: ctxt
	"If ctxt is a context married to the frame of an Oil method, answer the frame, else 0."
	<essential: #ProfilingCogit>
	<returnTypeC: #'char *'>
	| theFP |
	<var: #theFP type: #'char *'>
	((objectMemory isContext: ctxt) and: [self isStillMarriedContext: ctxt]) ifFalse: [^0].
	theFP := self frameOfMarriedContext: ctxt.
	((self isMachineCodeFrame: theFP) and: [cogit isOilMethod: (self mframeHomeMethod: theFP)]) ifFalse: [^0].
	^theFP! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-debugging' stamp: 'cb 10/27/2026 15:05'!
oilInstructionPointerOfFrame: theFP
	"The machine code pc of the frame theFP: the active frame's is instructionPointer, any other frame's is the return
	 address its callee saved, or, for the top frame of a page, the one at the head of the page.  The head frame pointers
	 must have been written back."
	<essential: #ProfilingCogit>
	<var: #theFP type: #'char *'>
	<returnTypeC: #usqInt>
	| thePage frameAbove |
	<var: #thePage type: #'StackPage *'>
	<var: #frameAbove type: #'char *'>
	(theFP = framePointer and: [instructionPointer ~= 0]) ifTrue: [^instructionPointer].
	thePage := stackPages stackPageFor: theFP.
	frameAbove := self findFrameAbove: theFP inPage: thePage.
	^frameAbove = 0
		ifTrue: [stackPages longAt: thePage headSP]
		ifFalse: [self frameCallerSavedIP: frameAbove]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-debugging' stamp: 'cb 10/26/2026 14:30'!
oilCallSiteForIP: theIP inCogMethod: cogMethod metadata: metadata
	"Answer the record of the call site of the Oil method cogMethod whose return address is theIP, or 0.  A frame that is
	 not the active frame is suspended in a call (or at its stack check, before any call): the record of the call
	 (OilMDSiteCallFlag, see OilInliningCompiler>>noteCallSiteAt:) describes the activations the frame stands for."
	<essential: #ProfilingCogit>
	<var: #cogMethod type: #'CogMethod *'>
	<var: #theIP type: #usqInt>
	| offset siteTable siteRecord |
	offset := theIP - cogMethod asUnsignedInteger.
	siteTable := self oilMD: metadata header: OilMDSiteTable.
	0 to: (self oilMD: metadata header: OilMDNumSites) - 1 do:
		[:siteIndex|
		 siteRecord := self oilMD: metadata u16At: siteTable + (2 * siteIndex).
		 (siteRecord > 0
		  and: [((self oilMD: metadata byteAt: siteRecord + OilMDSiteKind) bitAnd: OilMDSiteCallFlag) ~= 0
		  and: [(self oilMD: metadata u16At: siteRecord + OilMDSiteResumeOffset) = offset]]) ifTrue:
			[^siteRecord]].
	^0! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-debugging' stamp: 'cb 10/26/2026 14:30'!
oilFrameChainOf: site metadata: metadata into: chain
	"Fill chain with the inlined frames of the site record site, from the root (0) to the innermost; answer their number."
	<essential: #ProfilingCogit>
	<var: #chain type: #'sqInt *'>
	| framesBase frameIndex numFrames chainIndex |
	framesBase := self oilMD: metadata header: OilMDFrames.
	numFrames := 0.
	frameIndex := self oilMD: metadata byteAt: site + OilMDSiteFrame.
	[frameIndex >= 0] whileTrue:
		[numFrames := numFrames + 1.
		 frameIndex := self oilMD: metadata s8At: framesBase + (frameIndex * OilMDFrameSize) + OilMDFrameParent].
	frameIndex := self oilMD: metadata byteAt: site + OilMDSiteFrame.
	chainIndex := numFrames - 1.
	[frameIndex >= 0] whileTrue:
		[chain at: chainIndex put: frameIndex.
		 chainIndex := chainIndex - 1.
		 frameIndex := self oilMD: metadata s8At: framesBase + (frameIndex * OilMDFrameSize) + OilMDFrameParent].
	^numFrames! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-debugging' stamp: 'cb 10/27/2026 15:05'!
oilContextPCOf: chainIndex chain: chain numFrames: numFrames site: site metadata: metadata
	"The pc (1-relative, as in a context) of the activation chainIndex of the chain of inlined frames of the site record
	 site: for the innermost, the bytecode of the deopt site or following the call; for the others, the bytecode following
	 the send it was inlined at."
	<essential: #ProfilingCogit>
	<var: #chain type: #'sqInt *'>
	^chainIndex = (numFrames - 1)
		ifTrue:
			[(self oilMD: metadata u16At: site + OilMDSitePC)
			 + (((self oilMD: metadata byteAt: site + OilMDSiteKind) bitAnd: OilMDSiteCallFlag) ~= 0
					ifTrue: [self oilMD: metadata byteAt: site + OilMDSiteSendSize]
					ifFalse: [0])
			 + 1]
		ifFalse:
			[(self oilMD: metadata u16At: (self oilMD: metadata header: OilMDFrames) + ((chain at: chainIndex + 1) * OilMDFrameSize) + OilMDFrameReturnPC)
			 + 1]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-debugging' stamp: 'cb 10/26/2026 14:30'!
oilAllocateContextFor: aMethod slots: numStackSlots
	"Answer a new context (all nil) for an activation of aMethod (a CompiledMethod or CompiledBlock) with numStackSlots
	 arguments, temps and stack values, or nil if out of memory."
	<essential: #ProfilingCogit>
	| numSlots context |
	numSlots := ((self methodNeedsLargeContext: aMethod) or: [numStackSlots > (SmallContextSlots - ReceiverIndex - 1)])
					ifTrue: [LargeContextSlots]
					ifFalse: [SmallContextSlots].
	numStackSlots > (numSlots - ReceiverIndex - 1) ifTrue: [^nil].
	context := objectMemory
				allocateSlots: numSlots
				format: objectMemory indexablePointersFormat
				classIndex: ClassMethodContextCompactIndex.
	context isNil ifTrue: [^nil].
	objectMemory fillObj: context numSlots: numSlots with: objectMemory nilObject.
	^context! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-debugging' stamp: 'cb 10/27/2026 15:05'!
oilDeoptimizeFrame: theFP context: ctxt
	"Replace the frame theFP of an Oil method, married to ctxt, by the contexts of the activations it stands for at the call
	 it is suspended in (or at its entry stack check, see oilDeoptimizeFrame:context:site:)."
	<essential: #ProfilingCogit>
	<var: #theFP type: #'char *'>
	| cogMethod site |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := self mframeHomeMethod: theFP.
	site := self
				oilCallSiteForIP: (self oilInstructionPointerOfFrame: theFP)
				inCogMethod: cogMethod
				metadata: (cogit oilMetadataOf: cogMethod).
	^self oilDeoptimizeFrame: theFP context: ctxt site: site! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-debugging' stamp: 'cb 10/27/2026 15:05'!
oilDeoptimizeFrame: theFP context: ctxt site: site
	"Replace the frame theFP of an Oil method, married to ctxt, by the contexts of the activations it stands for at site
	 (see oilContextsOfFrame:context:site:).  ctxt is divorced from theFP (c.f. externalDivorceFrame:andContext:): the frames
	 above theFP move to a new stack page, whose base frame then returns to the innermost context, and theFP is peeled off
	 its page.  The caller has pushed the instruction pointer and written back the head frame pointers.  Answer the innermost
	 context, or 0 if out of memory (unchanged)."
	<essential: #ProfilingCogit>
	<var: #theFP type: #'char *'>
	| thePage frameAbove onCurrent newPage callerCtx callerFP callerIP callerSP leaf |
	<var: #thePage type: #'StackPage *'>
	<var: #newPage type: #'StackPage *'>
	<var: #frameAbove type: #'char *'>
	<var: #callerFP type: #'char *'>
	<var: #callerSP type: #'char *'>
	leaf := self oilContextsOfFrame: theFP context: ctxt site: site.
	leaf = 0 ifTrue: [^0].
	"Divorce ctxt: move the frames above theFP to a new page, whose base frame then returns to the innermost context, and
	 peel theFP off its page."
	thePage := stackPages stackPageFor: theFP.
	frameAbove := self findFrameAbove: theFP inPage: thePage.
	onCurrent := thePage = stackPage.
	(onCurrent or: [thePage = stackPages mostRecentlyUsedPage]) ifFalse:
		[stackPages markStackPageNextMostRecentlyUsed: thePage].
	callerCtx := self ensureCallerContext: theFP.
	frameAbove ~= 0 ifTrue:
		[newPage := stackPages newStackPage.
		 frameAbove := self moveFramesIn: thePage through: frameAbove toPage: newPage.
		 onCurrent
			ifTrue:
				[self setStackPageAndLimit: newPage.
				 self setStackPointersFromPage: newPage]
			ifFalse:
				[stackPages markStackPageMostRecentlyUsed: newPage].
		 self assert: (self frameCallerContext: frameAbove) = ctxt.
		 stackPages longAt: newPage baseAddress put: leaf].
	callerFP := self frameCallerFP: theFP.
	callerFP = 0 "theFP is a base frame; it is now alone; free the entire page"
		ifTrue: [stackPages freeStackPage: thePage]
		ifFalse:
			[callerIP := self frameCallerSavedIP: theFP.
			 callerSP := (self frameCallerSP: theFP) - objectMemory wordSize.
			 stackPages longAt: callerSP put: callerIP.
			 self setHeadFP: callerFP andSP: callerSP inPage: thePage].
	objectMemory storePointer: SenderIndex ofObject: ctxt withValue: callerCtx.
	^leaf! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-debugging' stamp: 'cb 10/27/2026 15:05'!
oilContextsOfFrame: theFP context: ctxt site: site
	"Fill in the contexts of the activations the frame theFP of an Oil method, married to ctxt, stands for at the site
	 record site (or 0 if at its entry stack check): ctxt for the Oil method, then a new context for each method and block
	 inlined at site, the innermost last, with the closures, temp vectors and objects Oil dissolved (virtual objects)
	 rematerialized (a closure's outerContext is the context of the activation that created it, if on the chain).  The values
	 are read from the frame (the deopt stub or call spilled the registers); the frame itself is not changed, and the sender
	 of ctxt is left to the caller, which divorces ctxt from the frame (oilDeoptimizeFrame:context:site:, divorceFramesIn:).
	 Answer the innermost context, or 0 if out of memory (nothing is changed before the allocations succeeded, and they
	 cannot run the garbage collector)."
	<essential: #ProfilingCogit>
	<var: #theFP type: #'char *'>
	| cogMethod metadata numFrames framesBase vobjsBase numVObjs frameRecord baseReg numArgs top context obj outerIndex
	  sendNumArgs value vobjRecord chain topRegs contexts regValues vobjOops needed state rootArgs |
	<var: #cogMethod type: #'CogMethod *'>
	<var: #chain declareC: 'sqInt chain[OilMaxFrames]'>
	<var: #topRegs declareC: 'sqInt topRegs[OilMaxFrames]'>
	<var: #contexts declareC: 'sqInt contexts[OilMaxFrames]'>
	<var: #regValues declareC: 'sqInt regValues[OilNumRegs]'>
	<var: #vobjOops declareC: 'sqInt vobjOops[OilMaxVObjs]'>
	<var: #needed declareC: 'char needed[OilMaxVObjs]'>
	<var: #state declareC: 'unsigned short state[OilNumRegs]'>
	<var: #rootArgs declareC: 'sqInt rootArgs[16]'>
	self cCode: [] inSmalltalk:
		[chain := CArrayAccessor on: (Array new: OilMaxFrames).
		 topRegs := CArrayAccessor on: (Array new: OilMaxFrames).
		 contexts := CArrayAccessor on: (Array new: OilMaxFrames).
		 regValues := CArrayAccessor on: (Array new: OilNumRegs).
		 vobjOops := CArrayAccessor on: (Array new: OilMaxVObjs).
		 needed := CArrayAccessor on: (ByteArray new: OilMaxVObjs).
		 state := CArrayAccessor on: (Array new: OilNumRegs).
		 rootArgs := CArrayAccessor on: (Array new: 16)].
	cogMethod := self mframeHomeMethod: theFP.
	metadata := cogit oilMetadataOf: cogMethod.
	site = 0 ifTrue:
		[frameRecord := self oilMD: metadata header: OilMDFrames.
		 numArgs := self oilMD: metadata byteAt: frameRecord + OilMDFrameNumArgs.
		 value := self oilMD: metadata literalAt: frameRecord + OilMDFrameMethod.
		 top := self temporaryCountOfMethodHeader: (objectMemory methodHeaderOf: value).
		 objectMemory
			storePointerUnchecked: InstructionPointerIndex ofObject: ctxt withValue: (objectMemory integerObjectOf: (self startPCOfMethod: value) + 1);
			storePointerUnchecked: StackPointerIndex ofObject: ctxt withValue: (objectMemory integerObjectOf: top);
			storePointer: MethodIndex ofObject: ctxt withValue: value;
			storePointerUnchecked: ClosureIndex ofObject: ctxt withValue: objectMemory nilObject;
			storePointer: ReceiverIndex ofObject: ctxt withValue: (self mframeReceiver: theFP).
		 1 to: numArgs do:
			[:slotIndex| objectMemory storePointer: ReceiverIndex + slotIndex ofObject: ctxt withValue: (self temporary: slotIndex - 1 in: theFP)].
		 ReceiverIndex + numArgs + 1 to: (objectMemory numSlotsOf: ctxt) - 1 do:
			[:slotIndex| objectMemory storePointerUnchecked: slotIndex ofObject: ctxt withValue: objectMemory nilObject].
		 ^ctxt].
	"1. The activations (root first), the top register of each one's part of the register window (the innermost's
	    excludes the receiver and arguments of the send, which the call consumed), and the values of the registers, read
	    from their spill slots, and of the root's arguments."
	numFrames := self oilFrameChainOf: site metadata: metadata into: chain.
	framesBase := self oilMD: metadata header: OilMDFrames.
	vobjsBase := self oilMD: metadata header: OilMDVObjs.
	numVObjs := self oilMD: metadata header: OilMDNumVObjs.
	self oilDecodeStateOf: site metadata: metadata into: state.
	sendNumArgs := ((self oilMD: metadata byteAt: site + OilMDSiteKind) bitAnd: OilMDSiteCallFlag) ~= 0
						ifTrue: [self oilMD: metadata byteAt: site + OilMDSiteSendNumArgs]
						ifFalse: [OilMDSiteNoSend].
	self
		oilTopRegs: topRegs
		chain: chain
		numFrames: numFrames
		innermost: (sendNumArgs = OilMDSiteNoSend "a deopt site or interrupt check: the whole state, at the site's bytecode"
					ifTrue: [self oilMD: metadata byteAt: site + OilMDSiteTop]
					ifFalse: [(self oilMD: metadata byteAt: site + OilMDSiteTop) - sendNumArgs - 1])
		metadata: metadata.
	0 to: numFrames - 1 do:
		[:i|
		frameRecord := framesBase + ((chain at: i) * OilMDFrameSize).
		(topRegs at: i) < ((self oilMD: metadata byteAt: frameRecord + OilMDFrameBase) + (self oilMD: metadata byteAt: frameRecord + OilMDFrameNumArgs)) ifTrue:
			[^0]]. "(an inconsistent site)"
	self oilReadSpilledRegistersOf: theFP into: regValues metadata: metadata.
	numArgs := self oilMD: metadata byteAt: framesBase + ((chain at: 0) * OilMDFrameSize) + OilMDFrameNumArgs.
	0 to: numArgs - 1 do:
		[:i| rootArgs at: i put: (self temporary: i in: theFP)].
	"2. The virtual objects the contexts refer to, transitively."
	0 to: OilMaxVObjs - 1 do:
		[:i| vobjOops at: i put: 0. needed at: i put: 0].
	0 to: numFrames - 1 do:
		[:i|
		frameRecord := framesBase + ((chain at: i) * OilMDFrameSize).
		baseReg := self oilMD: metadata byteAt: frameRecord + OilMDFrameBase.
		self oilNeedVObjOf: (self oilMD: metadata u16At: frameRecord + OilMDFrameSelf) needed: needed.
		(i = 0 ifTrue: [baseReg + numArgs + 1] ifFalse: [baseReg]) to: (topRegs at: i) do:
			[:reg| self oilNeedVObjOf: (state at: reg) needed: needed]].
	self oilMarkVObjsNeededBy: needed state: state metadata: metadata.
	"3. Allocate the contexts of the inlined activations and the virtual objects."
	contexts at: 0 put: ctxt.
	1 to: numFrames - 1 do:
		[:i|
		frameRecord := framesBase + ((chain at: i) * OilMDFrameSize).
		context := self
					oilAllocateContextFor: (self oilMD: metadata literalAt: frameRecord + OilMDFrameMethod)
					slots: (topRegs at: i) - (self oilMD: metadata byteAt: frameRecord + OilMDFrameBase).
		context isNil ifTrue: [^0].
		contexts at: i put: context].
	0 to: numVObjs - 1 do:
		[:i|
		(needed at: i) ~= 0 ifTrue:
			[obj := self oilAllocateVObjAt: vobjsBase + (i * OilMDVObjSize) metadata: metadata.
			 obj isNil ifTrue: [^0].
			 vobjOops at: i put: obj]].
	"4. Fill in the virtual objects."
	0 to: numVObjs - 1 do:
		[:i|
		(needed at: i) ~= 0 ifTrue:
			[vobjRecord := vobjsBase + (i * OilMDVObjSize).
			 outerIndex := self oilOuterChainIndexOf: vobjRecord chain: chain numFrames: numFrames metadata: metadata.
			 self
				oilFillVObj: (vobjOops at: i)
				record: vobjRecord
				outerContext: (outerIndex < 0 ifTrue: [objectMemory nilObject] ifFalse: [contexts at: outerIndex])
				state: state
				metadata: metadata
				values: regValues
				vobjs: vobjOops]].
	"5. Fill in the contexts (all but the sender of ctxt): the receiver (the closure for a block) and arguments of an inlined
	    activation and its temps and stack are registers of its part of the window, from its base register; the root's
	    arguments are the frame's."
	0 to: numFrames - 1 do:
		[:i|
		context := contexts at: i.
		frameRecord := framesBase + ((chain at: i) * OilMDFrameSize).
		baseReg := self oilMD: metadata byteAt: frameRecord + OilMDFrameBase.
		numArgs := self oilMD: metadata byteAt: frameRecord + OilMDFrameNumArgs.
		top := topRegs at: i.
		i > 0 ifTrue:
			[objectMemory storePointer: SenderIndex ofObject: context withValue: (contexts at: i - 1)].
		objectMemory
			storePointerUnchecked: InstructionPointerIndex ofObject: context withValue: (objectMemory integerObjectOf: (self oilContextPCOf: i chain: chain numFrames: numFrames site: site metadata: metadata));
			storePointerUnchecked: StackPointerIndex ofObject: context withValue: (objectMemory integerObjectOf: top - baseReg);
			storePointer: MethodIndex ofObject: context withValue: (self oilMD: metadata literalAt: frameRecord + OilMDFrameMethod);
			storePointer: ClosureIndex ofObject: context withValue: ((self oilMD: metadata byteAt: frameRecord + OilMDFrameIsBlock) ~= 0
																		ifTrue: [self oilValueOf: (state at: baseReg) metadata: metadata values: regValues vobjs: vobjOops]
																		ifFalse: [objectMemory nilObject]);
			storePointer: ReceiverIndex ofObject: context withValue: (self oilValueOf: (self oilMD: metadata u16At: frameRecord + OilMDFrameSelf) metadata: metadata values: regValues vobjs: vobjOops).
		1 to: top - baseReg do:
			[:slotIndex|
			value := (i = 0 and: [slotIndex <= numArgs])
						ifTrue: [rootArgs at: slotIndex - 1]
						ifFalse: [self oilValueOf: (state at: baseReg + slotIndex) metadata: metadata values: regValues vobjs: vobjOops].
			objectMemory storePointer: ReceiverIndex + slotIndex ofObject: context withValue: value].
		ReceiverIndex + top - baseReg + 1 to: (objectMemory numSlotsOf: context) - 1 do:
			[:slotIndex| objectMemory storePointerUnchecked: slotIndex ofObject: context withValue: objectMemory nilObject]].
	^contexts at: numFrames - 1! !

!CoInterpreterPrimitives methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/26/2026 20:30'!
primitiveOilDeoptimize
	"Context>>deoptimize (no argument: the receiver) or any receiver and a Context argument.  If the context is married to
	 the frame of an Oil method suspended in a call, replace the frame by the contexts of the activations it stands for (see
	 oilDeoptimizeFrame:context:) and answer the innermost one, whose sender chain leads to the context, which is the Oil
	 method's.  Otherwise (not married, not Oil code, the active frame, not at a call) answer the context."
	<export: true>
	<essential: #ProfilingCogit>
	| ctxt theFP result activeContext |
	<var: #theFP type: #'char *'>
	argumentCount > 1 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	ctxt := self stackTop.
	(objectMemory isContext: ctxt) ifFalse:
		[^self primitiveFailFor: (argumentCount = 0 ifTrue: [PrimErrBadReceiver] ifFalse: [PrimErrBadArgument])].
	theFP := self oilFrameOfContext: ctxt.
	(theFP = 0 or: [theFP = framePointer]) ifTrue:
		[^self pop: argumentCount + 1 thenPush: ctxt].
	activeContext := self oilMarryActiveFrame.
	result := self oilDeoptimizeFrame: theFP context: ctxt.
	self oilResumeContext: activeContext.
	result = 0 ifTrue:
		[^self primitiveFailFor: PrimErrNoMemory].
	self pop: argumentCount + 1 thenPush: result! !

!CoInterpreterPrimitives methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/26/2026 14:30'!
primitiveOilContexts
	"Context>>contexts (no argument: the receiver) or any receiver and a Context argument.  If the context is married to the
	 frame of an Oil method, answer { method. pc. method. pc ... } for the activations the frame stands for, innermost
	 first: those of the methods and blocks inlined at the call it is suspended in (the pcs follow the sends, as in the
	 contexts primitiveOilDeoptimize makes), then the Oil method's (its pc is nil if the frame is not in a call, e.g. it is
	 the active frame).  Fail for any other context: the fallback code answers its method and pc."
	<export: true>
	<essential: #ProfilingCogit>
	| ctxt theFP cogMethod metadata site numFrames framesBase result chainIndex chain |
	<var: #theFP type: #'char *'>
	<var: #cogMethod type: #'CogMethod *'>
	<var: #chain declareC: 'sqInt chain[OilMaxFrames]'>
	self cCode: [] inSmalltalk: [chain := CArrayAccessor on: (Array new: OilMaxFrames)].
	argumentCount > 1 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	ctxt := self stackTop.
	theFP := self oilFrameOfContext: ctxt.
	theFP = 0 ifTrue:
		[^self primitiveFailFor: (argumentCount = 0 ifTrue: [PrimErrBadReceiver] ifFalse: [PrimErrBadArgument])].
	self externalWriteBackHeadFramePointers.
	cogMethod := self mframeHomeMethod: theFP.
	metadata := cogit oilMetadataOf: cogMethod.
	site := self oilCallSiteForIP: (self oilInstructionPointerOfFrame: theFP) inCogMethod: cogMethod metadata: metadata.
	numFrames := site = 0 ifTrue: [1] ifFalse: [self oilFrameChainOf: site metadata: metadata into: chain].
	result := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: 2 * numFrames.
	result isNil ifTrue:
		[^self primitiveFailFor: PrimErrNoMemory].
	site = 0 ifTrue:
		[objectMemory storePointer: 0 ofObject: result withValue: (objectMemory fetchPointer: OilMDRootMethod ofObject: metadata).
		 ^self pop: argumentCount + 1 thenPush: result].
	framesBase := self oilMD: metadata header: OilMDFrames.
	0 to: numFrames - 1 do:
		[:i|
		chainIndex := numFrames - 1 - i.
		objectMemory
			storePointer: 2 * i
				ofObject: result
					withValue: (self oilMD: metadata literalAt: framesBase + ((chain at: chainIndex) * OilMDFrameSize) + OilMDFrameMethod);
			storePointerUnchecked: 2 * i + 1
				ofObject: result
					withValue: (objectMemory integerObjectOf: (self oilContextPCOf: chainIndex chain: chain numFrames: numFrames site: site metadata: metadata))].
	self pop: argumentCount + 1 thenPush: result! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-debugging' stamp: 'cb 10/26/2026 22:15'!
oilMetadataCopyOf: metadata class: classObj methodClass: methodClassObj
	"Answer { classObj. copy }, copy a clone of the deoptimization metadata object metadata that is an instance of
	 methodClassObj (CompiledMethod, the class of the method the metadata belongs to): its header, a SmallInteger, is the number of its literals (a method header without any other flag),
	 its literal frame and bytes are those of metadata.  Answer nil if out of memory.
	 Why a clone, and why re-classed: the metadata object itself must never be handed to the image.  The deoptimizer reads
	 it (ceOilDeoptimize:, oilContextsOfFrame:context:site:), so an at:put: or instVarAt:put: from the image would corrupt
	 the deoptimization state and could crash the VM.  And it is hidden: its class index is the arrayClassIndexPun (it is
	 not an instance of any class the image knows, see oilAllocateMetadata:numBytes:), with the format of a CompiledMethod,
	 so the image could not use it as it is.  The clone is an ordinary CompiledMethod (never run), whose literals and bytes
	 the image reads with literalAt: and at: (see OilDeoptMetadataReader)."
	<essential: #ProfilingCogit>
	| numLiterals numBytes copy pair literal |
	numLiterals := objectMemory literalCountOf: metadata.
	numBytes := objectMemory numBytesOf: metadata.
	copy := objectMemory instantiateCompiledMethodClass: methodClassObj indexableSize: numBytes.
	pair := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: 2.
	(copy isNil or: [pair isNil]) ifTrue: [^nil]. "(Spur does not move objects when allocating)"
	objectMemory storePointerUnchecked: 0 ofObject: copy withValue: (objectMemory fetchPointer: 0 ofObject: metadata).
	1 to: numLiterals do:
		[:i|
		literal := objectMemory fetchPointer: i ofObject: metadata.
		((objectMemory isNonImmediate: literal) and: [objectMemory isForwarded: literal]) ifTrue:
			[literal := objectMemory followForwarded: literal].
		objectMemory storePointer: i ofObject: copy withValue: literal].
	numLiterals + 1 * objectMemory wordSize to: numBytes - 1 do:
		[:i| objectMemory storeByte: i ofObject: copy withValue: (objectMemory fetchByte: i ofObject: metadata)].
	objectMemory
		storePointer: 0 ofObject: pair withValue: classObj;
		storePointer: 1 ofObject: pair withValue: copy.
	^pair! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-debugging' stamp: 'cb 10/26/2026 21:00'!
oilMetadataCopyOfMachineCodeOf: methodObj class: classObj
	"(see oilMetadataCopyOf:class:methodClass:)"
	<essential: #ProfilingCogit>
	^self
		oilMetadataCopyOf: (cogit oilMetadataOf: (self cogMethodOf: methodObj))
		class: classObj
		methodClass: (objectMemory fetchClassOfNonImm: methodObj)! !

!CoInterpreterPrimitives methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/26/2026 21:00'!
primitiveOilMetadata
	"CompiledMethod>>oilMetadata (no argument), CompiledMethod>>oilMetadataFor: aClass, or any receiver and a CompiledMethod
	 argument.  Answer copies of the deoptimization metadata of the method's Oil code (see oilMetadataCopyOf:class:methodClass:), never
	 the metadata object itself: nil if it has none, else an Array of pairs { class or nil. metadata (a CompiledMethod) }:
	 one, with nil, for Oil code of its own (primitiveOilCompile), else one per specialization (primitiveOilSpecialize).
	 With a class argument answer the pair for that class (or the one of the method's own Oil code), or nil."
	<export: true>
	<essential: #ProfilingCogit>
	| methodObj classObj direct count result entry entryIndex copy |
	argumentCount > 1 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	methodObj := self stackTop.
	classObj := objectMemory nilObject.
	(argumentCount = 1
	 and: [(objectMemory isNonImmediate: methodObj) not
		or: [(objectMemory isOopCompiledMethod: methodObj) not]]) ifTrue:
		[classObj := methodObj.
		 methodObj := self stackValue: 1].
	((objectMemory isNonImmediate: methodObj)
	 and: [objectMemory isOopCompiledMethod: methodObj]) ifFalse:
		[^self primitiveFailFor: (argumentCount = 0 ifTrue: [PrimErrBadReceiver] ifFalse: [PrimErrBadArgument])].
	direct := (self methodHasCogMethod: methodObj) and: [cogit isOilMethod: (self cogMethodOf: methodObj)].
	classObj ~= objectMemory nilObject ifTrue:
		[direct
			ifTrue: [entry := self oilMetadataCopyOfMachineCodeOf: methodObj class: objectMemory nilObject]
			ifFalse:
				[entry := objectMemory nilObject.
				 entryIndex := (objectMemory isNonImmediate: classObj)
									ifTrue: [cogit oilSpecializationOf: methodObj tag: (objectMemory classTagForClass: classObj)]
									ifFalse: [-1].
				 (entryIndex >= 0 and: [cogit oilIsLiveSpecialization: entryIndex of: methodObj]) ifTrue:
					[copy := cogit oilSpecializationAt: entryIndex field: OilSpecCopy.
					 entry := self oilMetadataCopyOfMachineCodeOf: copy class: classObj]].
		 entry isNil ifTrue: [^self primitiveFailFor: PrimErrNoMemory].
		 ^self pop: argumentCount + 1 thenPush: entry].
	count := direct ifTrue: [1] ifFalse: [cogit oilNumSpecializationsOf: methodObj].
	count = 0 ifTrue:
		[^self pop: argumentCount + 1 thenPush: objectMemory nilObject].
	result := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: count.
	result isNil ifTrue: [^self primitiveFailFor: PrimErrNoMemory].
	direct
		ifTrue:
			[entry := self oilMetadataCopyOfMachineCodeOf: methodObj class: objectMemory nilObject.
			 entry isNil ifTrue: [^self primitiveFailFor: PrimErrNoMemory].
			 objectMemory storePointer: 0 ofObject: result withValue: entry]
		ifFalse:
			[count := 0.
			 0 to: OilMaxSpecializations - 1 do:
				[:index|
				(cogit oilIsLiveSpecialization: index of: methodObj) ifTrue:
					[copy := cogit oilSpecializationAt: index field: OilSpecCopy.
					 entry := self oilMetadataCopyOfMachineCodeOf: copy class: (cogit oilSpecializationAt: index field: OilSpecClass).
					 entry isNil ifTrue: [^self primitiveFailFor: PrimErrNoMemory].
					 objectMemory storePointer: count ofObject: result withValue: entry.
					 count := count + 1]]].
	self pop: argumentCount + 1 thenPush: result! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/26/2026 21:00'!
oilApiMethodClassOf: aMethod
	"The class of aMethod: the value of its last literal, its method class association, or 0."
	<api>
	<essential: #ProfilingCogit>
	| lit |
	lit := self oilApiMethodClassAssociationOf: aMethod.
	lit = 0 ifTrue: [^0].
	^objectMemory followMaybeForwarded: (objectMemory fetchPointer: ValueIndex ofObject: lit)! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/26/2026 15:00'!
oilApiClass: aClass isNamed: aCString
	"Is aClass a class whose name is aCString?"
	<api>
	<essential: #ProfilingCogit>
	<var: #aCString type: #'char *'>
	^(objectMemory isNonImmediate: aClass)
	  and: [(objectMemory isPointersNonImm: aClass)
	  and: [self classNameOf: aClass Is: aCString]]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/26/2026 21:00'!
oilApiIsSynchronizationMethod: aMethod
	"Is aMethod a method of the process synchronization and timer classes (Semaphore, Mutex, Monitor, Delay, Process,
	 ProcessorScheduler, or their metaclasses)?  Oil neither compiles them on trips (see oilAutoCompile:receiver:) nor
	 inlines them (see OilInliningCompiler>>shouldInline:selector:numArgs:receiver:): the timer process runs them, and their
	 unwind blocks guard semaphores, which a deoptimization or a termination in the middle of them must not lose."
	<api>
	<essential: #ProfilingCogit>
	| methodClass |
	methodClass := self oilApiMethodClassOf: aMethod.
	((objectMemory isNonImmediate: methodClass) and: [objectMemory isPointersNonImm: methodClass]) ifFalse:
		[^false].
	((objectMemory numSlotsOf: methodClass) = metaclassNumSlots "a metaclass: its sole instance"
	 and: [thisClassIndex < metaclassNumSlots]) ifTrue:
		[methodClass := objectMemory fetchPointer: thisClassIndex ofObject: methodClass].
	^(self oilApiClass: methodClass isNamed: 'Semaphore')
	  or: [(self oilApiClass: methodClass isNamed: 'Mutex')
	  or: [(self oilApiClass: methodClass isNamed: 'Monitor')
	  or: [(self oilApiClass: methodClass isNamed: 'Delay')
	  or: [(self oilApiClass: methodClass isNamed: 'Process')
	  or: [self oilApiClass: methodClass isNamed: 'ProcessorScheduler']]]]]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-support' stamp: 'cb 10/26/2026 15:00'!
oilApiByteStringMetaclass
	<api>
	<essential: #ProfilingCogit>
	^objectMemory fetchClassOf: (objectMemory splObj: ClassByteString)! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-autonomous' stamp: 'cb 10/27/2026 18:00'!
oilAutoCompile: homeMethod receiver: receiver
	"A trip counter found that homeMethod, activated for receiver, runs a hot loop (see ceOilTrip:).  Compile an Oil
	 specialization of homeMethod for the class of receiver (up to oilMaxSpecialization specializations), and install it in
	 oilSpecializations for its next activations; its running activations keep running its baseline code (see
	 oilUnhookBaselineCodeOf:).  Called on the trip path: nothing here collects garbage or changes the stack."
	<essential: #ProfilingCogit>
	| cogMethod selector classObj classTag entryIndex specCopy result |
	<var: #cogMethod type: #'CogMethod *'>
	((objectMemory isNonImmediate: homeMethod)
	 and: [(objectMemory isOopCompiledMethod: homeMethod)
	 and: [(self isFullBlockMethod: homeMethod) not
	 and: [self methodHasCogMethod: homeMethod]]]) ifFalse:
		[^nil].
	cogMethod := self cogMethodOf: homeMethod.
	((cogit isOilMethod: cogMethod)
	 or: [(cogit oilIsDisqualified: homeMethod)
	 or: [self oilApiIsSynchronizationMethod: homeMethod]]) ifTrue:
		[^nil].
	self oilEnsureSpecializationTable ifFalse:
		[^nil].
	classObj := objectMemory fetchClassOf: receiver.
	classTag := objectMemory fetchClassTagOf: receiver.
	entryIndex := cogit oilSpecializationOf: homeMethod tag: classTag.
	entryIndex >= 0
		ifTrue:
			[specCopy := cogit oilSpecializationAt: entryIndex field: OilSpecCopy.
			 ((cogit oilMethodHasOilCode: specCopy)
			  or: [(cogit oilIsDisqualified: specCopy)
			  or: [(cogit oilCopy: specCopy isCopyOf: homeMethod) not]]) ifTrue:
				[^nil]]
		ifFalse:
			[(cogit oilNumSpecializationsOf: homeMethod) >= cogit oilMaxSpecialization ifTrue:
				[^nil].
			 specCopy := objectMemory cloneInOldSpace: homeMethod forPinning: false.
			 specCopy = 0 ifTrue:
				[^nil]].
	self oilEnsureExtraSelectorTable ifFalse:
		[^nil].
	selector := cogMethod selector.
	result := cogit oilCompile: homeMethod receiverClass: classObj.
	result = OilOK ifTrue:
		[(self oilUnhookBaselineCodeOf: homeMethod) ifFalse:
			[^nil].
		 result := cogit oilGenerate: specCopy.
		 (result = OilOK and: [entryIndex < 0]) ifTrue:
			[cogit oilAddSpecialization: homeMethod class: classObj copy: specCopy].
		 cogit cog: homeMethod selector: selector].
	(result ~= OilOK and: [result ~= OilFailCodeSpace]) ifTrue:
		[cogit oilDisqualify: homeMethod].
	^nil! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-autonomous' stamp: 'cb 10/27/2026 18:00'!
oilUnhookBaselineCodeOf: methodObj
	"Give the baseline machine code of methodObj, which activations may be running, to a copy of methodObj: the sends
	 linked to it are unlinked and methodObj gets its bytecoded header back, ready for its Oil code.  The copy, which
	 nothing sends to, owns the baseline code (and the contexts of its machine code frames) until its activations have
	 returned; it is disqualified, so that its trip counters do not compile it.  Its divorced contexts with machine code
	 pcs get bytecode pcs first.  Answer whether it was unhooked (not if the copy cannot be allocated).  Nothing here
	 collects garbage or changes the stack."
	<essential: #ProfilingCogit>
	<var: #cogMethod type: #'CogMethod *'>
	<var: #aPage type: #'StackPage *'>
	<var: #theFP type: #'char *'>
	| cogMethod copy aPage theFP |
	cogMethod := self cogMethodOf: methodObj.
	copy := objectMemory cloneInOldSpace: methodObj forPinning: false.
	copy = 0 ifTrue: [^false].
	objectMemory allObjectsDo:
		[:obj|
		((objectMemory isContextNonImm: obj)
		 and: [(objectMemory fetchPointer: MethodIndex ofObject: obj) = methodObj
		 and: [(self isMarriedOrWidowedContext: obj) not]]) ifTrue:
			[self ensureContextHasBytecodePC: obj]].
	self flushMethodCacheForMethod: methodObj.
	cogit oilUnlinkSendsKeepingSpecializationsTo: methodObj.
	self rawHeaderOf: methodObj put: cogMethod methodHeader.
	self rawHeaderOf: copy put: cogMethod asUnsignedInteger.
	cogit oilSetMethodObjectOf: cogMethod to: copy.
	0 to: numStackPages - 1 do:
		[:i|
		aPage := stackPages stackPageAt: i.
		(stackPages isFree: aPage) ifFalse:
			[theFP := aPage = stackPage ifTrue: [framePointer] ifFalse: [aPage headFP].
			 [theFP ~= 0] whileTrue:
				[((self isMachineCodeFrame: theFP)
				  and: [(self mframeHomeMethod: theFP) = cogMethod
				  and: [self frameHasContext: theFP]]) ifTrue:
					[objectMemory storePointer: MethodIndex ofObject: (self frameContext: theFP) withValue: copy].
				 theFP := self frameCallerFP: theFP]]].
	cogit oilDisqualify: copy.
	^true! !

