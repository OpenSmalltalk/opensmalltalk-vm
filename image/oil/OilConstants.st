SharedPool subclass: #OilConstants
	instanceVariableNames: ''
	classVariableNames: 'OilCondLt OilCondGt OilCondLe OilCondGe OilCondEq OilCondNe OilCondIdentical OilCondNotIdentical OilTagUnknown OilTagPushRcvrVar OilTagPushLitVar OilTagPushLitConst OilTagPushTemp OilTagPushSelf OilTagPushTrue OilTagPushFalse OilTagPushNil OilTagPushInteger OilTagPushCharacter OilTagDup OilTagPop OilTagReturnSelf OilTagReturnTrue OilTagReturnFalse OilTagReturnNil OilTagReturnTop OilTagBlockReturnNil OilTagBlockReturnTop OilTagNop OilTagSendSpecial OilTagSend OilTagSendSuper OilTagJump OilTagJumpTrue OilTagJumpFalse OilTagStoreRcvrVar OilTagPopIntoRcvrVar OilTagStoreTemp OilTagPopIntoTemp OilTagStoreLitVar OilTagPopIntoLitVar OilTagPushNewArray OilTagPushRemoteTemp OilTagStoreRemoteTemp OilTagPopIntoRemoteTemp OilTagPushFullClosure OilTagExtension OilModeNone OilModeLow OilModeByte1 OilModeByte1ExtB OilModeSend OilModeLowSend OilModeNewArray OilModeRemoteTemp OilModeFullClosure OilModeByte1Temp OilDescReg OilDescConst OilDescBlock OilDescTempVector OilDescCond OilDescObject OilDescSelect OilFlagImmutable OilFlagTVSlot OilBufferWords OilIRBudget OilMaxInlineDepth OilLargeMethodDepth OilMediumMethodDepth OilAccessorBytes OilMediumMethodBytes OilMaxCalleeBytes OilNumRegs OilFlagsReg OilMaxReg OilMaxFrames OilPCMapSize OilMaxVObjs OilMaxCaptured OilMaxSites OilMaxConds OilMaxColdSelectors OilNoLink OilSiteGuard OilSiteArith OilSiteBounds OilSiteCall OilSiteBranch OilSiteStore OilSiteAlloc OilSitePoolSize OilOK OilFailUnsupportedBytecode OilFailThisContext OilFailPrimitiveMethod OilFailBufferFull OilFailOutOfRegisters OilFailTooManyFrames OilFailPCMapFull OilFailTooManyVirtualObjects OilFailTooManySites OilFailEagerClosuresFailed OilFailInternal OilFailBackend OilFailCodeSpace OilFailUnsafeSite OilFailNotSistaV1 OilMDVersion OilMDRootMethod OilMDNumSites OilMDSiteTable OilMDNumFrames OilMDFrames OilMDNumVObjs OilMDVObjs OilMDSpillOffsets OilMDDeopts OilMDFastPaths OilMDNumArgs OilMDCaptured OilMDHeaderSize OilMDFrameSize OilMDVObjSize OilMDSiteHeaderSize OilMDFrameMethod OilMDFrameIsBlock OilMDFrameBase OilMDFrameParent OilMDFrameReturnPC OilMDFrameSelf OilMDFrameNumArgs OilMDVObjKind OilMDVObjLiteralOrSize OilMDVObjOuterFrame OilMDVObjSelf OilMDVObjNumCopied OilMDVObjCopiedIndex OilMDVObjSlotBase OilMDSiteKind OilMDSiteGuardReg OilMDSiteClassTag OilMDSiteResumeOffset OilMDSiteFrame OilMDSitePC OilMDSiteTop OilMDSiteHigh OilMDMagic OilMDSiteGuardSize OilMDSiteGuardFlag OilMDStateOwn OilMDStateNil OilMDNoDescriptor OilMDFirstSelectorLiteral OilMDNumSpills OilMDSpillEntrySize OilMDDescriptorSize OilMDDescriptorValueBits OilMaxMDLiterals OilMDLiteralHashSize OilP2Delete OilP2NoCheck OilP2RotBack OilP2ToMove OilFloatChained OilFloatUnboxed OilNumXmms OilMaxFacts OilMaxUndos OilFailDisqualified OilDisqualifyDeopts OilMaxDisqualified OilExtraSelectorBase OilMaxExtraSelectors OilFailSpecialization OilMaxSpecializations OilMaxPICCases OilSpecializationSize OilSpecMethod OilSpecClassTag OilSpecCopy OilSpecClass OilMaxEagerSites OilMaxVObjSlots OilP2Unroll OilP2UnrollPartial OilMaxUnrolls OilUnrollMaxTrips OilUnrollFullBudget OilUnrollTinyBody OilUnrollMaxBody OilLoopAlignment OilMaxFloatLoops OilMaxPinnedXmms OilMaxFloatExits OilMDInlinedSelectors OilMaxInlinedSelectors OilMDSiteCallFlag OilMDSiteCallSize OilMDSiteSendSize OilMDSiteSendNumArgs OilMDSiteNoSend OilMaxPolls'
	poolDictionaries: 'OilInstructionConstants'
	category: 'VMMaker-JIT-Oil'!

!OilConstants commentStamp: 'cb 10/25/2026 00:15' prior: 0!
I hold the non-instruction constants of Oil, the optimizing JIT for the 64-bit Spur Cog VM: comparison condition codes, bytecode classification tags and operand decoding modes of OilBytecodeScanner, virtual register descriptor kinds and flags, sizes and limits of the preallocated compiler tables, deopt site kinds, failure codes, and the flags Pass 2 (OilLoopOptimizer>>loopOptimize) marks instructions with.  The 32-bit linear IR opcodes are defined in OilInstructionConstants (imported via poolDictionaries).  Initialize with OilConstants initialize.!

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
	"a scalar replaced instance of a class with fixed pointer fields only (a virtual object: its slots are high registers)"
	OilDescObject := 5.
	"a lazy class dependent value: the result of a bimorphic send answering nil for one class and a known non-nil value
	 (self or a constant) for the other, whose comparison with nil is the class test (see OilInliningCompiler>>genBimorphicSelect:...)"
	OilDescSelect := 6.
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
	OilMaxCalleeBytes := 160.
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
	"deoptimization metadata (a hidden pinned object of CompiledMethod format referenced from the Oil CogMethod, see
	 OilInliningCompiler>>fillMetadata:cogMethod:).  Literal frame: slot 0 a method header (the number of literals), slot
	 OilMDRootMethod the root method, from slot OilMDFirstSelectorLiteral the inlined selectors, then the other objects
	 the records refer to by literal index (frame methods, CompiledBlocks, classes, constants).  Then bytes, little endian:
	 a header (the byte offsets of its fields below, from the end of the literal frame), and records whose offsets are
	 byte indices in the body of the object (as in fetchByte:ofObject:, so below 65536)."
	OilMDRootMethod := 1.
	OilMDFirstSelectorLiteral := 2.
	OilMDVersion := 0. "u32: OilMDMagic"
	OilMDNumSites := 4. "u16"
	OilMDSiteTable := 6. "u16: the offset of the table of the u16 offsets of the site records (0: unused site)"
	OilMDNumFrames := 8. "u16"
	OilMDFrames := 10. "u16: the offset of the frame records"
	OilMDNumVObjs := 12. "u16"
	OilMDVObjs := 14. "u16: the offset of the virtual object records"
	OilMDNumSpills := 16. "u16"
	OilMDSpillOffsets := 18. "u16: the offset of the spill entries: virtual register (u8), spill offset (s16), for the spilled registers only"
	OilMDDeopts := 20. "u32"
	OilMDFastPaths := 24. "u32"
	OilMDNumArgs := 28. "u16"
	OilMDCaptured := 30. "u16: the offset of the descriptors of the captured values"
	OilMDInlinedSelectors := 32. "s16: the number of inlined selectors (-1: too many to record), literals from OilMDFirstSelectorLiteral"
	OilMDHeaderSize := 34.
	OilMDSpillEntrySize := 3.
	"a descriptor: u16, its kind in the top 3 bits, its value in the low 13 bits: a register, a literal index (a constant; 0,
	 the header slot, stands for nil) or a virtual object index"
	OilMDDescriptorSize := 2.
	OilMDDescriptorValueBits := 13.
	OilMaxMDLiterals := 1024.
	OilMDLiteralHashSize := 2048.
	"frame records: method (u16 literal index) isBlock (u8) base (u8) parent (s8) returnPC (u16) self (descriptor) numArgs (u8)"
	OilMDFrameSize := 10.
	OilMDFrameMethod := 0.
	OilMDFrameIsBlock := 2.
	OilMDFrameBase := 3.
	OilMDFrameParent := 4.
	OilMDFrameReturnPC := 5.
	OilMDFrameSelf := 7.
	OilMDFrameNumArgs := 9.
	"virtual object records: kind (u8) literalOrSize (u16: a closure's CompiledBlock as a literal index, or the number of slots
	 of a temp vector or object) outerFrame (s8) self (descriptor; the class of a scalar replaced object) numCopied (u8)
	 copiedIndex (u16 offset of the descriptors of the copied values) slotBase (u8)"
	OilMDVObjSize := 10.
	OilMDVObjKind := 0.
	OilMDVObjLiteralOrSize := 1.
	OilMDVObjOuterFrame := 3.
	OilMDVObjSelf := 4.
	OilMDVObjNumCopied := 6.
	OilMDVObjCopiedIndex := 7.
	OilMDVObjSlotBase := 9.
	"site records: kind (u8, plus OilMDSiteGuardFlag for a class guard) frame (u8) pc (u16) resumeOffset (u16) top (u8)
	 high (u8), then, for a class guard, guardVReg (u8) expectedTag (u32), then the state's descriptors, of 1 or 2 bytes (see
	 CoInterpreter>>oilDecodeStateOf:metadata:into:)"
	OilMDSiteHeaderSize := 8.
	OilMDSiteKind := 0.
	OilMDSiteFrame := 1.
	OilMDSitePC := 2.
	OilMDSiteResumeOffset := 4.
	OilMDSiteTop := 6.
	OilMDSiteHigh := 7.
	OilMDSiteGuardReg := 8.
	OilMDSiteClassTag := 9.
	OilMDSiteGuardSize := 5.
	OilMDSiteGuardFlag := 128.
	"a call site (OilMDSiteCallFlag, see OilInliningCompiler>>noteCallSiteAt:): its resume offset is the return address of the
	 call, and the header is followed by the size of the send bytecode (u8) and its number of arguments (u8), so that a
	 frame suspended in the call maps to the activations it stands for (see CoInterpreter>>oilDeoptimizeFrame:context:)"
	OilMDSiteCallFlag := 64.
	OilMDSiteSendSize := 8.
	OilMDSiteSendNumArgs := 9.
	OilMDSiteCallSize := 2.
	"the number of arguments of the call record of an interrupt check (see OilInliningCompiler>>genPollBefore:): no send,
	 the frame resumes at the site's bytecode with the whole state"
	OilMDSiteNoSend := 255.
	"Pass 3: the interrupt checks of the loops of a method (see OilInliningCompiler>>genPollBefore:)"
	OilMaxPolls := 64.
	OilMDStateOwn := 0. "a register holding its own value"
	OilMDStateNil := 1. "the constant nil"
	OilMDNoDescriptor := 16rFFFF. "a register a state does not describe"
	OilMDMagic := 16r4F494C34.
	"Pass 2 per-instruction flags (oilIRFlag)"
	OilP2Delete := 1.
	OilP2NoCheck := 2.
	OilP2RotBack := 8.
	OilP2ToMove := 16.
	"Pass 2 loop unrolling (OilLoopOptimizer>>unrollLoops): the header of a fully unrolled loop, the exit branch of the header
	 of a partially unrolled one (the unrolled loop follows it)"
	OilP2Unroll := 4.
	OilP2UnrollPartial := 128.
	"OilFullCompiler>>fuseFloats, on the final IR (oilIRFlag, cleared first): an instruction of a float chain (whose deopts
	 all go to the site in oilIRAux, the one of its first instruction), and a float result left unboxed in an XMM register"
	OilFloatChained := 32.
	OilFloatUnboxed := 64.
	"Pass 3: the XMM registers holding the values of a float chain (DPFPReg0..)"
	OilNumXmms := 8.
	"OilFullCompiler>>valueNumberAt: the facts (loaded fields, sizes, bounds and class checks) known at a time"
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
	OilSpecMethod := 0.
	OilSpecClassTag := 1.
	OilSpecCopy := 2.
	OilSpecClass := 3.
	OilMaxPICCases := 5.
	"scalar replacement: the allocation sites (method, pc) whose objects are materialized when created (they escaped after a
	 branch or a label, see OilInliningCompiler>>materializeVObj:), and the largest scalar replaced object"
	OilMaxEagerSites := 16.
	OilMaxVObjSlots := 16.
	"loop unrolling (OilLoopOptimizer>>unrollLoops), per method: unrolled loops; a loop of at most OilUnrollMaxTrips iterations
	 known at compile time is fully unrolled if iterations * body size (IR instructions) <= OilUnrollFullBudget; other counted
	 leaf loops are unrolled 4 times if their body has at most OilUnrollTinyBody instructions, else twice if at most
	 OilUnrollMaxBody (the image can override these, see OilInliningCompiler>>oilUnrollParameter:value:).  Tuned (M9): 8
	 iterations and a budget of 48 instructions (about 80 bytecodes) are faster than 5 and 25 (8 x 2 instructions: 1.35
	 times faster when unrolled; 5 x 6: 1.15 times); the body sizes (4 and 16) make no measurable difference."
	OilMaxUnrolls := 16.
	OilUnrollMaxTrips := 8.
	OilUnrollFullBudget := 48.
	OilUnrollTinyBody := 4.
	OilUnrollMaxBody := 16.
	"Pass 3: the alignment of loop headers (bytes, at most 16; 1: none), see OilInliningCompiler>>loopAlignment"
	OilLoopAlignment := 16.
	"Pass 3 float loop registers (M10, OilInliningCompiler>>prepareFloatLoops): loops per method whose float variables live in
	 XMM registers, the XMM registers (DPFPReg8..) they get, and the exits of a loop"
	OilMaxFloatLoops := 4.
	OilMaxPinnedXmms := 8.
	OilMaxFloatExits := 32.
	"the selectors (inlined methods, quick methods, intrinsics) whose lookup an Oil method depends on, recorded in its
	 metadata for invalidation (see ProfilingCogit>>oilMethod:inlinesSelector:); with more, any selector invalidates it"
	OilMaxInlinedSelectors := 64.! !

!OilConstants class methodsFor: 'accessing' stamp: 'cb 10/25/2026 00:15'!
opcodeNames
	"Answer the opcode names (delegated to OilInstructionConstants)."
	^OilInstructionConstants opcodeNames! !

!OilConstants class methodsFor: 'accessing' stamp: 'cb 10/26/2026 20:50'!
failureNames
	"Indexed by failure code + 1."
	^#(OK FailUnsupportedBytecode FailThisContext FailPrimitiveMethod FailBufferFull FailOutOfRegisters FailTooManyFrames FailPCMapFull FailTooManyVirtualObjects FailTooManySites FailEagerClosuresFailed FailInternal FailBackend FailCodeSpace FailUnsafeSite FailNotSistaV1 FailDisqualified FailSpecialization)! !

OilConstants initialize!
