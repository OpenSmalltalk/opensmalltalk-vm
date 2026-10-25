SharedPool subclass: #OilConstants
	instanceVariableNames: ''
	classVariableNames: 'OilCondLt OilCondGt OilCondLe OilCondGe OilCondEq OilCondNe OilCondIdentical OilCondNotIdentical OilTagUnknown OilTagPushRcvrVar OilTagPushLitVar OilTagPushLitConst OilTagPushTemp OilTagPushSelf OilTagPushTrue OilTagPushFalse OilTagPushNil OilTagPushInteger OilTagPushCharacter OilTagDup OilTagPop OilTagReturnSelf OilTagReturnTrue OilTagReturnFalse OilTagReturnNil OilTagReturnTop OilTagBlockReturnNil OilTagBlockReturnTop OilTagNop OilTagSendSpecial OilTagSend OilTagSendSuper OilTagJump OilTagJumpTrue OilTagJumpFalse OilTagStoreRcvrVar OilTagPopIntoRcvrVar OilTagStoreTemp OilTagPopIntoTemp OilTagStoreLitVar OilTagPopIntoLitVar OilTagPushNewArray OilTagPushRemoteTemp OilTagStoreRemoteTemp OilTagPopIntoRemoteTemp OilTagPushFullClosure OilTagExtension OilModeNone OilModeLow OilModeByte1 OilModeByte1ExtB OilModeSend OilModeLowSend OilModeNewArray OilModeRemoteTemp OilModeFullClosure OilModeByte1Temp OilDescReg OilDescConst OilDescBlock OilDescTempVector OilDescCond OilFlagImmutable OilFlagTVSlot OilBufferWords OilIRBudget OilMaxInlineDepth OilLargeMethodDepth OilMediumMethodDepth OilAccessorBytes OilMediumMethodBytes OilMaxIteratorBytes OilNumRegs OilFlagsReg OilMaxReg OilMaxFrames OilPCMapSize OilMaxVObjs OilMaxCaptured OilMaxSites OilMaxConds OilMaxColdSelectors OilNoLink OilSiteGuard OilSiteArith OilSiteBounds OilSiteCall OilSiteBranch OilSiteStore OilSiteAlloc OilSitePoolSize OilOK OilFailUnsupportedBytecode OilFailThisContext OilFailPrimitiveMethod OilFailBufferFull OilFailOutOfRegisters OilFailTooManyFrames OilFailPCMapFull OilFailTooManyVirtualObjects OilFailTooManySites OilFailEagerClosuresFailed OilFailInternal OilFailBackend OilFailCodeSpace OilFailUnsafeSite OilFailNotSistaV1 OilMDVersion OilMDRootMethod OilMDNumSites OilMDSiteTable OilMDNumFrames OilMDFrames OilMDNumVObjs OilMDVObjs OilMDHomes OilMDDeopts OilMDFastPaths OilMDNumArgs OilMDCaptured OilMDHeaderSize OilMDFrameSize OilMDVObjSize OilMDSiteHeaderSize OilMDMagic OilP2Delete OilP2NoCheck OilP2RotBack OilP2ToMove OilFloatChained OilFloatUnboxed OilNumXmms OilMaxFacts OilMaxUndos OilFailDisqualified OilDisqualifyDeopts OilMaxDisqualified OilExtraSelectorBase OilMaxExtraSelectors OilFailSpecialization OilMaxSpecializations OilMaxPICCases OilSpecializationSize'
	poolDictionaries: 'OilInstructionConstants'
	category: 'VMMaker-JIT-Oil'!

!OilConstants commentStamp: 'cb 10/25/2026 00:15' prior: 0!
I hold the non-instruction constants of Oil, the optimizing JIT for the 64-bit Spur Cog VM: comparison condition codes, bytecode classification tags and operand decoding modes of OilBytecodeScanner, virtual register descriptor kinds and flags, sizes and limits of the preallocated compiler tables, deopt site kinds, failure codes, and the flags Pass 2 (OilCompiler>>loopOptimize) marks instructions with.  The 32-bit linear IR opcodes are defined in OilInstructionConstants (imported via poolDictionaries).  Initialize with OilConstants initialize.!

!OilConstants class methodsFor: 'class initialization' stamp: 'cb 10/25/2026 00:15'!
initialize
	"OilConstants initialize"
	"operand condition codes: Pass 1 maps the special selectors < > <= >= = ~= (indices 2 to 7) to index - 1"
	OilCondLt := 1.
	OilCondGt := 2.
	OilCondLe := 3.
	OilCondGe := 4.
	OilCondEq := 5.
	OilCondNe := 6.
	OilCondIdentical := 7.
	OilCondNotIdentical := 8.
	"bytecode classification tags (OilBytecodeDescriptor kind)"
	OilTagUnknown := 0.
	OilTagPushRcvrVar := 1.
	OilTagPushLitVar := 2.
	OilTagPushLitConst := 3.
	OilTagPushTemp := 4.
	OilTagPushSelf := 5.
	OilTagPushTrue := 6.
	OilTagPushFalse := 7.
	OilTagPushNil := 8.
	OilTagPushInteger := 9.
	OilTagPushCharacter := 10.
	OilTagDup := 11.
	OilTagPop := 12.
	OilTagReturnSelf := 13.
	OilTagReturnTrue := 14.
	OilTagReturnFalse := 15.
	OilTagReturnNil := 16.
	OilTagReturnTop := 17.
	OilTagBlockReturnNil := 19.
	OilTagBlockReturnTop := 20.
	OilTagNop := 21.
	OilTagSendSpecial := 22.
	OilTagSend := 23.
	OilTagSendSuper := 24.
	OilTagJump := 25.
	OilTagJumpTrue := 26.
	OilTagJumpFalse := 27.
	OilTagStoreRcvrVar := 28.
	OilTagPopIntoRcvrVar := 29.
	OilTagStoreTemp := 30.
	OilTagPopIntoTemp := 31.
	OilTagStoreLitVar := 32.
	OilTagPopIntoLitVar := 33.
	OilTagPushNewArray := 34.
	OilTagPushRemoteTemp := 35.
	OilTagStoreRemoteTemp := 36.
	OilTagPopIntoRemoteTemp := 37.
	OilTagPushFullClosure := 38.
	OilTagExtension := 42.
	"operand decoding modes (OilBytecodeDescriptor operandMode)"
	OilModeNone := 0.
	OilModeLow := 1.
	OilModeByte1 := 2.
	OilModeByte1ExtB := 3.
	OilModeSend := 4.
	OilModeLowSend := 5.
	OilModeNewArray := 6.
	OilModeRemoteTemp := 7.
	OilModeFullClosure := 8.
	OilModeByte1Temp := 17.
	"virtual register descriptor kinds"
	OilDescReg := 0.
	OilDescConst := 1.
	OilDescBlock := 2.
	OilDescTempVector := 3.
	OilDescCond := 4.
	"virtual register flags"
	OilFlagImmutable := 1.
	OilFlagTVSlot := 4.
	"sizes and limits"
	OilBufferWords := 4096.
	OilIRBudget := 1024.
	OilMaxInlineDepth := 8.
	OilLargeMethodDepth := 2.
	OilMediumMethodDepth := 4.
	OilAccessorBytes := 10.
	OilMediumMethodBytes := 30.
	OilMaxIteratorBytes := 160.
	OilNumRegs := 256.
	OilFlagsReg := 255.
	OilMaxReg := 254.
	OilMaxFrames := 64.
	OilPCMapSize := 8192.
	OilMaxVObjs := 64.
	OilMaxCaptured := 512.
	OilMaxSites := 256.
	OilMaxConds := 128.
	OilMaxColdSelectors := 32.
	OilNoLink := 65535.
	OilSitePoolSize := 16384.
	"deopt site kinds"
	OilSiteGuard := 1.
	OilSiteArith := 2.
	OilSiteBounds := 3.
	OilSiteCall := 4.
	OilSiteBranch := 5.
	OilSiteStore := 6.
	"an allocation that does not fit before the scavenge threshold: not a failed speculation (not counted)"
	OilSiteAlloc := 7.
	"failure codes"
	OilOK := 0.
	OilFailUnsupportedBytecode := 1.
	OilFailThisContext := 2.
	OilFailPrimitiveMethod := 3.
	OilFailBufferFull := 4.
	OilFailOutOfRegisters := 5.
	OilFailTooManyFrames := 6.
	OilFailPCMapFull := 7.
	OilFailTooManyVirtualObjects := 8.
	OilFailTooManySites := 9.
	OilFailEagerClosuresFailed := 10.
	OilFailInternal := 11.
	OilFailBackend := 12.
	OilFailCodeSpace := 13.
	OilFailUnsafeSite := 14.
	OilFailNotSistaV1 := 15.
	OilFailDisqualified := 16.
	"(primitiveOilSpecialize) the method has OilMaxPICCases specializations already, or Oil code of its own (primitiveOilCompile)"
	OilFailSpecialization := 17.
	"deoptimization metadata (a hidden pinned Array referenced from the Oil CogMethod): header slots"
	OilMDVersion := 0.
	OilMDRootMethod := 1.
	OilMDNumSites := 2.
	OilMDSiteTable := 3.
	OilMDNumFrames := 4.
	OilMDFrames := 5.
	OilMDNumVObjs := 6.
	OilMDVObjs := 7.
	OilMDHomes := 8.
	OilMDDeopts := 9.
	OilMDFastPaths := 10.
	OilMDNumArgs := 11.
	OilMDCaptured := 12.
	OilMDHeaderSize := 13.
	"frame records: method isBlock base parent returnPC selfKind selfValue numArgs"
	OilMDFrameSize := 8.
	"virtual object records: kind literalOrSize outerFrame selfKind selfValue numCopied copiedIndex slotBase"
	OilMDVObjSize := 8.
	"site records: kind guardVReg expectedTag resumeOffset frame pc top high, then the state's descriptor pairs"
	OilMDSiteHeaderSize := 8.
	OilMDMagic := 16r4F494C33.
	"Pass 2 per-instruction flags (oilIRFlag)"
	OilP2Delete := 1.
	OilP2NoCheck := 2.
	OilP2RotBack := 8.
	OilP2ToMove := 16.
	"OilFullCompiler>>fuseFloats, on the final IR (oilIRFlag, cleared first): an instruction of a float chain (whose deopts
	 all go to the site in oilIRAux, the one of its first instruction), and a float result left unboxed in an XMM register"
	OilFloatChained := 32.
	OilFloatUnboxed := 64.
	"Pass 3: the XMM registers holding the values of a float chain (DPFPReg0..)"
	OilNumXmms := 8.
	"OilFullCompiler>>valueNumber: the facts (loaded fields, sizes, bounds and class checks) known at a time"
	OilMaxFacts := 64.
	"Pass 3: in-place tagged adds (with an undo stub before deoptimizing) per method"
	OilMaxUndos := 64.
	"deoptimization: an Oil method that deoptimizes this many times is freed (back to the baseline JIT) and not recompiled"
	OilDisqualifyDeopts := 2.
	OilMaxDisqualified := 64.
	"inline caches of Oil methods hold OilExtraSelectorBase + k for the selector at index k of the Oil selector table, a
	 selector that is neither special nor among the literals of the method (see ProfilingCogit>>oilExtraSelectorIndexOf:add:)"
	OilExtraSelectorBase := 16r100000.
	OilMaxExtraSelectors := 2048.
	"method-level specialization (see CoInterpreterPrimitives>>primitiveOilSpecialize): entries (method, class tag, copy, class) of the
	 specialization table, and receiver classes per method (its baseline code is the generic sixth case, as in a closed PIC)"
	OilMaxSpecializations := 64.
	OilSpecializationSize := 4.
	OilMaxPICCases := 5.! !

!OilConstants class methodsFor: 'accessing' stamp: 'cb 10/25/2026 00:15'!
opcodeNames
	"Answer the opcode names (delegated to OilInstructionConstants)."
	^OilInstructionConstants opcodeNames! !

!OilConstants class methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:00'!
conditionNames
	^#(Lt Gt Le Ge Eq Ne Identical NotIdentical)! !

!OilConstants class methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:00'!
failureNames
	"Indexed by failure code + 1."
	^#(OK FailUnsupportedBytecode FailThisContext FailPrimitiveMethod FailBufferFull FailOutOfRegisters FailTooManyFrames FailPCMapFull FailTooManyVirtualObjects FailTooManySites FailEagerClosuresFailed FailInternal FailBackend FailCodeSpace FailUnsafeSite FailNotSistaV1 FailDisqualified)! !

OilConstants initialize!
