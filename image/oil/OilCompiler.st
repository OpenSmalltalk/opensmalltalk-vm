OilBytecodeScanner subclass: #OilBaseCompiler
	instanceVariableNames: 'oilIRBuffer irIndex irInstCount lastInstIR lastLabelIR irBudget slotKind slotValue slotFlags knownClass affineBase affineConst affineVersion regVersion lastDefIR simStackTop highRegTop frameMethod frameBase frameParent frameHome frameCallPC frameIsBlock frameSelfKind frameSelfValue frameSelfClass frameTempStart frameStackStart frameMaxReg framePCBase frameStartPC frameEndPC frameExitChain frameHasLazy frameLazyKind frameLazyValue frameDepth numFrames currentFrame currentPC pcTarget pcLabelIR pcChain pcDepth pcMapTop vobjKind vobjLiteral vobjSelfKind vobjSelfValue vobjSelfClass vobjNumCopied vobjCopiedBase vobjHome vobjSize vobjSlotBase numVObjs capturedKind capturedValue capturedTop siteIR siteFrame sitePC siteKind numSites oilDeadCode failed failureCode needsRestart eagerClosures nilHandle trueHandle falseHandle smallIntegerClassHandle bitXorSelector valueSelectors iteratorSelectors numIteratorSelectors coldSelectors numColdSelectors condCond condRA condRB condImm condUseImm condIdentity condFrame condPC numConds pendingCondSlot pendingCondIndex typeFeedback simHandles simHandleIndex rootMethod rootClass snapFrame snapPC snapTop snapHighTop snapKind snapValue sitePoolKind sitePoolValue sitePoolTop siteSnapBase siteSnapTop siteSnapHigh condSite emittingCond vobjOuter oilUseWeight oilVRegReg oilVRegHome oilNumHomes oilIRTarget oilIRLabel oilIRSite oilNumFixups oilFixupJump oilFixupTarget oilNumStubJumps oilStubJump oilStubSite oilSiteResume oilSiteStub oilSiteUsed oilAllocRegs oilNumAllocRegs oilLoopDepth oilFailIndex oilTagged oilIRBuffer1 oilIRBuffer2 oilIRMap oilIRFlag oilIRAux oilVRegDefs oilVRegUses oilPass1Words oilNumRotated oilNumBoundsRemoved oilNumDeadRemoved oilNumSizesShared oilNumNoCheck oilUndoJump oilUndoSite oilUndoReg oilUndoSrc oilNumUndos oilUseProbe oilUseProbeHit pcLoop oilNumGuardsRemoved oilDisqualified oilNumDisqualified oilDisqualifyLimitValue oilNoInline oilNumNoInline oilRestartNoInline oilXmmRegs oilXmmVReg oilXmmKind oilXmmChain oilIndexOfAsciiMethod oilSkipSeparatorsMethod oilByteStreamClass'
	classVariableNames: ''
	poolDictionaries: 'OilInstructionConstants OilConstants CogAbstractRegisters VMStackFrameOffsets VMObjectIndices VMSqueakClassIndices'
	category: 'VMMaker-JIT-Oil'!

!OilBaseCompiler commentStamp: 'cb 10/25/2026 00:45' prior: 0!
I am the base compiler of Oil, the optimizing JIT of the 64-bit Spur Cog VM (OilBytecodeScanner -> OilBaseCompiler -> OilLoopCompiler -> OilFullCompiler).  Given the outer (home) method of a hot loop and the class of its receiver, Pass 1 translates its bytecodes, recursively inlining blocks, collection iterators and small methods, into a flat 32-bit compact linear IR in a preallocated static buffer, applying peephole reductions for tagged SmallInteger arithmetic on the fly.  Subclasses add optimization passes in #pipe (OilLoopCompiler adds Pass 2, the streaming loop optimizer), and Pass 3 (the native backend) generates machine code.  I allocate nothing: every table is a fixed size array (static/BSS memory in the VM, invisible to the GC).

IR format: oilIRBuffer is an array of OilBufferWords (4096) 32-bit words (16 KB).  An instruction is one word [Opcode:8 | Dest:8 | Src1:8 | Src2/Imm:8], possibly followed by a 64-bit operand (2 words, low word first) and packed argument words.  See the OilConstants class comment and OilCompiler>>printIROn: for the opcode set.  Branch targets are absolute IR word indices.  Instructions that can deoptimize (guards, bounds checks, tagged arithmetic, calls, non-boolean branches) are recorded in a side table of deopt sites (IR index, inlined frame, bytecode pc), and the frame table describes the inlined frames (method, base register, caller frame, call site pc) for the deoptimization metadata.

Virtual registers (256, 8-bit operands) are allocated like a register window: the root method's receiver is r0, its arguments r1..rN, its temporaries follow, then its expression stack.  An inlined method's frame starts at the register holding its receiver on the caller's stack, so arguments are bound in place and the method's result is left in the register the caller expects for the send's result.  Scalar replaced temp vectors live in high registers (allocated downwards from r254); r255 means "condition flags".

Each register has a descriptor (slotKind/slotValue): its own register, an alias of another register, a not yet materialized constant, a virtual (not allocated) closure, or a virtual temp vector.  Expression stack entries are descriptors, which enables constant folding, copy propagation and the dissolving of closures and temp vectors whose blocks are inlined.  At every control flow merge all mutable registers are made canonical (own register), which keeps the linear pass simple and correct without SSA or phis.  If a closure must exist (it escapes), compilation restarts once in eager mode where closures and temp vectors are materialized.

Inlining policy: see shouldInline:selector:numArgs:receiver:.  Receiver classes come from constants, from facts established by guards and inlining, or from type feedback (the inline caches of ProfilingCogit in the VM, simulated execution in the image).  Sends that are not inlined become OilCall0/OilCall1/OilCallN/OilCallSuper or uncommon traps (OilTrap).!

!OilBaseCompiler methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:30'!
initialize
	"Simulation only: in the VM all tables are static (BSS) arrays, see OilCompiler class>>declareCVarsIn:."
	<doNotGenerate>
	super initialize.
	self setUpSimulationTables! !

!OilBaseCompiler methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:30'!
setUpSimulationTables
	<doNotGenerate>
	oilIRBuffer1 := CArrayAccessor on: (WordArray new: OilBufferWords).
	oilIRBuffer2 := CArrayAccessor on: (WordArray new: OilBufferWords).
	oilIRBuffer := oilIRBuffer1.
	slotKind := self newTable: OilNumRegs.
	slotValue := self newTable: OilNumRegs.
	slotFlags := self newTable: OilNumRegs.
	knownClass := self newTable: OilNumRegs.
	affineBase := self newTable: OilNumRegs.
	affineConst := self newTable: OilNumRegs.
	affineVersion := self newTable: OilNumRegs.
	regVersion := self newTable: OilNumRegs.
	lastDefIR := self newTable: OilNumRegs.
	frameMethod := self newTable: OilMaxFrames.
	frameBase := self newTable: OilMaxFrames.
	frameParent := self newTable: OilMaxFrames.
	frameHome := self newTable: OilMaxFrames.
	frameCallPC := self newTable: OilMaxFrames.
	frameIsBlock := self newTable: OilMaxFrames.
	frameSelfKind := self newTable: OilMaxFrames.
	frameSelfValue := self newTable: OilMaxFrames.
	frameSelfClass := self newTable: OilMaxFrames.
	frameTempStart := self newTable: OilMaxFrames.
	frameStackStart := self newTable: OilMaxFrames.
	frameMaxReg := self newTable: OilMaxFrames.
	framePCBase := self newTable: OilMaxFrames.
	frameStartPC := self newTable: OilMaxFrames.
	frameEndPC := self newTable: OilMaxFrames.
	frameExitChain := self newTable: OilMaxFrames.
	frameHasLazy := self newTable: OilMaxFrames.
	frameLazyKind := self newTable: OilMaxFrames.
	frameLazyValue := self newTable: OilMaxFrames.
	frameDepth := self newTable: OilMaxFrames.
	pcTarget := self newTable: OilPCMapSize.
	pcLabelIR := self newTable: OilPCMapSize.
	pcChain := self newTable: OilPCMapSize.
	pcDepth := self newTable: OilPCMapSize.
	pcLoop := self newTable: OilPCMapSize.
	oilDisqualified := self newTable: OilMaxDisqualified.
	oilNoInline := self newTable: 16.
	oilNumNoInline := 0.
	oilNumDisqualified := 0.
	vobjKind := self newTable: OilMaxVObjs.
	vobjLiteral := self newTable: OilMaxVObjs.
	vobjSelfKind := self newTable: OilMaxVObjs.
	vobjSelfValue := self newTable: OilMaxVObjs.
	vobjSelfClass := self newTable: OilMaxVObjs.
	vobjNumCopied := self newTable: OilMaxVObjs.
	vobjCopiedBase := self newTable: OilMaxVObjs.
	vobjHome := self newTable: OilMaxVObjs.
	vobjSize := self newTable: OilMaxVObjs.
	vobjSlotBase := self newTable: OilMaxVObjs.
	capturedKind := self newTable: OilMaxCaptured.
	capturedValue := self newTable: OilMaxCaptured.
	siteIR := self newTable: OilMaxSites.
	siteFrame := self newTable: OilMaxSites.
	sitePC := self newTable: OilMaxSites.
	siteKind := self newTable: OilMaxSites.
	valueSelectors := self newTable: 5.
	iteratorSelectors := self newTable: 32.
	coldSelectors := self newTable: OilMaxColdSelectors.
	condCond := self newTable: OilMaxConds.
	condRA := self newTable: OilMaxConds.
	condRB := self newTable: OilMaxConds.
	condImm := self newTable: OilMaxConds.
	condUseImm := self newTable: OilMaxConds.
	condIdentity := self newTable: OilMaxConds.
	condFrame := self newTable: OilMaxConds.
	condPC := self newTable: OilMaxConds.
	condSite := self newTable: OilMaxConds.
	snapKind := self newTable: OilNumRegs.
	snapValue := self newTable: OilNumRegs.
	sitePoolKind := self newTable: OilSitePoolSize.
	sitePoolValue := self newTable: OilSitePoolSize.
	siteSnapBase := self newTable: OilMaxSites.
	siteSnapTop := self newTable: OilMaxSites.
	siteSnapHigh := self newTable: OilMaxSites.
	vobjOuter := self newTable: OilMaxVObjs.
	oilIRMap := self newTable: OilBufferWords + 1.
	oilIRFlag := self newTable: OilBufferWords.
	oilIRAux := self newTable: OilBufferWords.
	oilVRegDefs := self newTable: OilNumRegs.
	oilVRegUses := self newTable: OilNumRegs.
	oilTagged := self newTable: OilNumRegs.
	oilLoopDepth := self newTable: OilBufferWords.
	oilIRTarget := self newTable: OilBufferWords.
	oilIRSite := self newTable: OilBufferWords.
	oilXmmRegs := self newTable: OilNumXmms.
	oilXmmVReg := self newTable: OilNumXmms.
	oilXmmKind := self newTable: OilNumXmms.
	simHandles := OrderedCollection new.
	simHandleIndex := IdentityDictionary new.
	irBudget := OilIRBudget.
	self setUpSimulationHandles.
	self resetForCompilation! !

!OilBaseCompiler methodsFor: 'initialization' stamp: 'cb 10/25/2026 00:45'!
newTable: tableSize
	<doNotGenerate>
	^CArrayAccessor on: (Array new: tableSize withAll: 0)! !

!OilBaseCompiler methodsFor: 'initialization' stamp: 'cb 10/25/2026 00:45'!
setUpSimulationHandles
	"In the VM, nil/true/false/SmallInteger are the object memory's oops (see resetForCompilation) and the special
	 selectors are registered before compilation with registerSelector:kind:.  In the image they are simulated handles (see handleFor:)."
	<doNotGenerate>
	nilHandle := self handleFor: nil.
	trueHandle := self handleFor: true.
	falseHandle := self handleFor: false.
	smallIntegerClassHandle := self handleFor: SmallInteger.
	numIteratorSelectors := numColdSelectors := 0.
	#(value value: value:value: value:value:value: value:value:value:value:) doWithIndex:
		[:sel :selIdx| self registerSelector: (self handleFor: sel) kind: selIdx - 1].
	self registerSelector: (self handleFor: #bitXor:) kind: 5.
	#(do: reverseDo: collect: select: reject: detect: detect:ifNone: detect:ifFound:ifNone: inject:into: do:separatedBy: doWithIndex: withIndexDo: keysAndValuesDo: timesRepeat: to:do: to:by:do: scanFor: findElementOrNil: with:do: allSatisfy: anySatisfy: noneSatisfy: count: detectMax: detectMin:) do:
		[:sel| self registerSelector: (self handleFor: sel) kind: 6].
	"Error paths are cold: never inlined (they would bloat the IR of the hot loop for nothing)."
	#(error: errorNoFreeSpace errorNotFound: errorSubscriptBounds: errorNoSuchElement errorEmptyCollection errorKeyNotFound: errorKeyNotFound errorImproperStore errorNonIntegerIndex errorNotIndexable subclassResponsibility shouldNotImplement notYetImplemented halt halt: deprecated: deprecated signal signal: doesNotUnderstand: cannotReturn: primitiveFailed primitiveFailed:) do:
		[:sel| self registerSelector: (self handleFor: sel) kind: 7].
	"The methods and the stream class of the word-at-a-time byte scans (see genScanIntrinsic:selector:receiver:numArgs:class:guard:)."
	self registerSelector: (ByteString class >> #indexOfAscii:inString:startingAt:) kind: 9.
	self registerSelector: (PositionableStream >> #skipSeparators) kind: 10.
	self registerSelector: (self handleFor: ReadStream) kind: 11! !

!OilBaseCompiler methodsFor: 'initialization' stamp: 'cb 10/25/2026 00:45'!
registerSelector: selector kind: kind
	"Tell Oil about a selector it treats specially:
	 kind 0-4: value selectors by arity, 5: bitXor:, 6: iterators, 7: cold (error paths);
	 9: the method ByteString class>>indexOfAscii:inString:startingAt:, 10: the method PositionableStream>>skipSeparators,
	 11: the class ReadStream (see genScanIntrinsic:selector:receiver:numArgs:class:guard:)."
	kind <= 4 ifTrue:
		[valueSelectors at: kind put: selector.
		 ^self].
	kind = 5 ifTrue:
		[bitXorSelector := selector.
		 ^self].
	kind = 9 ifTrue:
		[oilIndexOfAsciiMethod := selector.
		 ^self].
	kind = 10 ifTrue:
		[oilSkipSeparatorsMethod := selector.
		 ^self].
	kind = 11 ifTrue:
		[oilByteStreamClass := selector.
		 ^self].
	kind = 6 ifTrue:
		[numIteratorSelectors < 32 ifTrue:
			[iteratorSelectors at: numIteratorSelectors put: selector.
			 numIteratorSelectors := numIteratorSelectors + 1].
		 ^self].
	numColdSelectors < OilMaxColdSelectors ifTrue:
		[coldSelectors at: numColdSelectors put: selector.
		 numColdSelectors := numColdSelectors + 1]! !

!OilBaseCompiler methodsFor: 'initialization' stamp: 'cb 10/25/2026 00:45'!
resetSelectorRegistry
	"Forget the registered special selectors (the VM re-registers them before each compilation, since
	 selector oops move when the garbage collector compacts the heap)."
	0 to: 4 do: [:selIndex| valueSelectors at: selIndex put: 0].
	bitXorSelector := oilIndexOfAsciiMethod := oilSkipSeparatorsMethod := oilByteStreamClass := 0.
	numIteratorSelectors := numColdSelectors := 0! !

!OilBaseCompiler methodsFor: 'initialization' stamp: 'cb 10/25/2026 00:45'!
resetForCompilation
	self cCode:
		[nilHandle := objectMemory nilObject.
		 trueHandle := objectMemory trueObject.
		 falseHandle := objectMemory falseObject.
		 smallIntegerClassHandle := objectMemory classSmallInteger].
	oilIRBuffer := oilIRBuffer1. "Pass 1 writes Buffer 1; Pass 2 (loopOptimize) streams it into Buffer 2"
	irIndex := irInstCount := 0.
	oilPass1Words := 0.
	lastInstIR := -1.
	lastLabelIR := 0.
	0 to: OilNumRegs - 1 do:
		[:vreg|
		slotKind at: vreg put: OilDescReg.
		slotValue at: vreg put: vreg.
		slotFlags at: vreg put: 0.
		knownClass at: vreg put: 0.
		affineBase at: vreg put: -1.
		affineConst at: vreg put: 0.
		affineVersion at: vreg put: 0.
		regVersion at: vreg put: 0.
		lastDefIR at: vreg put: -1].
	simStackTop := -1.
	highRegTop := OilMaxReg.
	numFrames := pcMapTop := numVObjs := capturedTop := numSites := numConds := 0.
	sitePoolTop := 0.
	snapFrame := snapPC := snapTop := snapHighTop := -1.
	emittingCond := -1.
	pendingCondSlot := -1.
	currentFrame := -1.
	currentPC := 0.
	oilDeadCode := failed := needsRestart := oilRestartNoInline := false.
	failureCode := OilOK! !

!OilBaseCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
irBudget: anInteger
	irBudget := anInteger! !

!OilBaseCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
typeFeedback: aTypeFeedbackOracle
	<doNotGenerate>
	typeFeedback := aTypeFeedbackOracle! !

!OilBaseCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
failed
	^failed! !

!OilBaseCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
failureCode
	^failureCode! !

!OilBaseCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
eagerClosures
	^eagerClosures! !

!OilBaseCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
irIndex
	^irIndex! !

!OilBaseCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
irInstCount
	^irInstCount! !

!OilBaseCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
irWordAt: index
	^oilIRBuffer at: index! !

!OilBaseCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
numFrames
	^numFrames! !

!OilBaseCompiler methodsFor: 'compilation' stamp: 'cb 10/24/2026 19:35'!
pipe
	"Optimization pipeline hook between Pass 1 and Pass 3. Subclasses override to add optimization passes."
	<inline: true>
	oilPass1Words := irIndex.
	^OilOK! !

!OilBaseCompiler methodsFor: 'compilation' stamp: 'cb 10/24/2026 10:30'!
compileMethod: aMethod receiverClass: classHandle
	"Pass 1: translate aMethod, the outer (home) method of a hot loop, specialized for receivers of class classHandle,
	 into the linear IR buffer.  Closures and temp vectors are first kept virtual (dissolved when their blocks are inlined);
	 restarts (up to 12 times) materialize them when one escapes or stop inlining a frame the back end cannot encode.
	 Answer true on success."
	| restarts |
	eagerClosures := false.
	irBudget = 0 ifTrue: [irBudget := OilIRBudget]. "in the VM nothing else initializes it"
	oilNumNoInline := 0.
	restarts := 0.
	[self compileOnce: aMethod receiverClass: classHandle.
	 needsRestart and: [restarts < 12]] whileTrue:
		[restarts := restarts + 1.
		 oilRestartNoInline ifFalse:
			[eagerClosures ifTrue: [^false].
			 eagerClosures := true]].
	^failed not! !

!OilBaseCompiler methodsFor: 'compilation' stamp: 'cb 10/25/2026 00:45'!
compileOnce: aMethod receiverClass: classHandle
	<inline: false>
	| rootFrame |
	self resetForCompilation.
	rootMethod := aMethod.
	rootClass := classHandle.
	(self oilIsSistaV1Method: aMethod) ifFalse: "Oil only decodes SistaV1: leave the method to the baseline Cogit"
		[^self abortCompilation: OilFailNotSistaV1].
	(self oilIsDisqualified: aMethod) ifTrue: "it deoptimized too often"
		[^self abortCompilation: OilFailDisqualified].
	(self isContextClass: classHandle) ifTrue: "see isContextClass:"
		[^self abortCompilation: OilFailUnsupportedBytecode].
	(self oilPrimitiveIndexOf: aMethod) ~= 0 ifTrue:
		[^self abortCompilation: OilFailPrimitiveMethod].
	rootFrame := self newFrameFor: aMethod base: 0 isBlock: false.
	rootFrame < 0 ifTrue:
		[^self abortCompilation: OilFailUnsupportedBytecode].
	frameSelfKind at: rootFrame put: OilDescReg.
	frameSelfValue at: rootFrame put: 0.
	frameSelfClass at: rootFrame put: classHandle.
	knownClass at: 0 put: classHandle.
	self bindFrame: rootFrame base: 0 numArgs: (self numArgsOf: aMethod) numCopied: 0.
	"The receiver's class is a speculation (inlined self sends are bound to it): guard it at entry.
	 Deoptimizing there resumes the method from its first bytecode in the interpreter."
	currentFrame := rootFrame.
	currentPC := frameStartPC at: rootFrame.
	self takeSnapshotFrame: rootFrame pc: currentPC.
	self emitGuardOn: 0 class: classHandle.
	self translateFrame: rootFrame! !

!OilBaseCompiler methodsFor: 'disqualification' stamp: 'cb 10/24/2026 17:30'!
oilDisqualify: aMethod
	"Remember that aMethod deoptimized too often: it will not be compiled again (oilDisqualified is a ring of the
	 last OilMaxDisqualified methods; the entries are only compared, so stale ones after a compaction are harmless)."
	<api>
	(self oilIsDisqualified: aMethod) ifTrue: [^self].
	oilDisqualified at: oilNumDisqualified \\ OilMaxDisqualified put: aMethod.
	oilNumDisqualified := oilNumDisqualified + 1! !

!OilBaseCompiler methodsFor: 'disqualification' stamp: 'cb 10/24/2026 17:30'!
oilDisqualifyLimit
	"The number of deoptimizations after which an Oil method is disqualified (see CoInterpreter>>oilDisqualify:)."
	<api>
	^oilDisqualifyLimitValue > 0 ifTrue: [oilDisqualifyLimitValue] ifFalse: [OilDisqualifyDeopts]! !

!OilBaseCompiler methodsFor: 'disqualification' stamp: 'cb 10/24/2026 17:30'!
oilDisqualifyLimit: limit
	oilDisqualifyLimitValue := limit! !

!OilBaseCompiler methodsFor: 'disqualification' stamp: 'cb 10/25/2026 00:45'!
includes: anItem in: table count: count
	<var: #table type: #'sqInt *'>
	0 to: count - 1 do:
		[:index| (table at: index) = anItem ifTrue: [^true]].
	^false! !

!OilBaseCompiler methodsFor: 'disqualification' stamp: 'cb 10/25/2026 00:45'!
oilIsDisqualified: aMethod
	^self includes: aMethod in: oilDisqualified count: (oilNumDisqualified min: OilMaxDisqualified)! !

!OilBaseCompiler methodsFor: 'compilation' stamp: 'cb 10/25/2026 00:45'!
abortCompilation: code
	failed ifFalse: [failureCode := code].
	failed := true! !

!OilBaseCompiler methodsFor: 'compilation' stamp: 'cb 10/25/2026 00:45'!
requireEagerClosures
	"A virtual closure or temp vector must be materialized.  Restart in eager mode (or give up if already eager)."
	eagerClosures
		ifTrue: [self abortCompilation: OilFailEagerClosuresFailed]
		ifFalse: [needsRestart := true. failed := true]! !

!OilBaseCompiler methodsFor: 'frames' stamp: 'cb 10/25/2026 00:45'!
newFrameFor: aMethod base: baseReg isBlock: isBlock
	"Allocate a frame for aMethod whose receiver (or closure) is in register baseReg, and pre-scan its bytecodes
	 for branch targets.  Answer the frame index, or -1 if the method cannot be translated or resources are exhausted."
	| frameIndex mapSize regsNeeded |
	(self oilIsSistaV1Method: aMethod) ifFalse: [^-1]. "not inlined: sent instead"
	numFrames >= OilMaxFrames ifTrue: [^-1].
	regsNeeded := baseReg + 2 + (self frameSizeOf: aMethod).
	regsNeeded >= highRegTop ifTrue: [^-1].
	mapSize := (self oilEndPCOf: aMethod) - (self startPCOf: aMethod) + 2.
	pcMapTop + mapSize > OilPCMapSize ifTrue: [^-1].
	frameIndex := numFrames.
	frameMethod at: frameIndex put: aMethod.
	frameBase at: frameIndex put: baseReg.
	frameIsBlock at: frameIndex put: isBlock.
	frameHome at: frameIndex put: frameIndex.
	frameStartPC at: frameIndex put: (self startPCOf: aMethod).
	frameEndPC at: frameIndex put: (self oilEndPCOf: aMethod).
	framePCBase at: frameIndex put: pcMapTop.
	frameMaxReg at: frameIndex put: regsNeeded.
	frameExitChain at: frameIndex put: OilNoLink.
	frameHasLazy at: frameIndex put: false.
	frameParent at: frameIndex put: currentFrame.
	frameCallPC at: frameIndex put: currentPC.
	frameDepth at: frameIndex put: (currentFrame < 0 ifTrue: [0] ifFalse: [(frameDepth at: currentFrame) + 1]).
	(self preScanFrame: frameIndex) ifFalse: [^-1].
	numFrames := frameIndex + 1.
	pcMapTop := pcMapTop + mapSize.
	^frameIndex! !

!OilBaseCompiler methodsFor: 'frames' stamp: 'cb 10/25/2026 00:45'!
bindFrame: frameIndex base: baseReg numArgs: numArgs numCopied: numCopied
	"Registers of frame frameIndex, whose receiver (or closure) is in baseReg: receiver and arguments are immutable
	 (copied values, bound by the caller, follow the arguments), temps start as nil, then the stack."
	| numTemps firstTemp |
	slotFlags at: baseReg put: OilFlagImmutable.
	1 to: numArgs do:
		[:argIndex|
		self stabilizeIncomingSlot: baseReg + argIndex.
		slotFlags at: baseReg + argIndex put: OilFlagImmutable].
	numTemps := self numTempsOf: (frameMethod at: frameIndex).
	firstTemp := baseReg + numArgs + numCopied + 1.
	firstTemp to: baseReg + numTemps do:
		[:tempReg|
		slotFlags at: tempReg put: 0.
		self setSlot: tempReg kind: OilDescConst value: nilHandle.
		knownClass at: tempReg put: 0.
		affineBase at: tempReg put: -1].
	frameTempStart at: frameIndex put: firstTemp.
	frameStackStart at: frameIndex put: baseReg + numTemps + 1.
	simStackTop := baseReg + numTemps! !

!OilBaseCompiler methodsFor: 'frames' stamp: 'cb 10/25/2026 00:45'!
preScanFrame: frameIndex
	"Mark the branch targets of frame frameIndex's method in its pc map region, and the pcs inside loops (pcLoop, from a
	 backward branch's target to the branch).  Answer false if the method contains a bytecode Oil does not translate."
	| pc end start base |
	start := frameStartPC at: frameIndex.
	end := frameEndPC at: frameIndex.
	base := framePCBase at: frameIndex.
	base to: base + (end - start) + 1 do:
		[:entryIndex|
		pcTarget at: entryIndex put: 0.
		pcLabelIR at: entryIndex put: -1.
		pcChain at: entryIndex put: OilNoLink.
		pcDepth at: entryIndex put: 0.
		pcLoop at: entryIndex put: 0].
	self setScanMethod: (frameMethod at: frameIndex).
	pc := start.
	[pc <= end] whileTrue:
		[self decodeAt: pc.
		 opcodeTag = OilTagUnknown ifTrue: [^false].
		 oilTargetPC >= 0 ifTrue:
			[(oilTargetPC < start or: [oilTargetPC > end]) ifTrue: [^false].
			 pcTarget at: base + oilTargetPC - start put: 1.
			 oilTargetPC <= instrPC ifTrue:
				[oilTargetPC to: instrPC do: [:loopPC| pcLoop at: base + loopPC - start put: 1]]].
		 pc := oilNextPC].
	^true! !

!OilBaseCompiler methodsFor: 'frames' stamp: 'cb 10/25/2026 00:45'!
isFrameActive: frameIndex
	| activeFrame |
	activeFrame := currentFrame.
	[activeFrame >= 0] whileTrue:
		[activeFrame = frameIndex ifTrue: [^true].
		 activeFrame := frameParent at: activeFrame].
	^false! !

!OilBaseCompiler methodsFor: 'frames' stamp: 'cb 10/25/2026 00:45'!
isMethodOnInlineStack: aMethod
	| activeFrame |
	activeFrame := currentFrame.
	[activeFrame >= 0] whileTrue:
		[(frameMethod at: activeFrame) = aMethod ifTrue: [^true].
		 activeFrame := frameParent at: activeFrame].
	^false! !

!OilBaseCompiler methodsFor: 'frames' stamp: 'cb 10/24/2026 10:30'!
tempReg: index frame: frameIndex
	<inline: true>
	^(frameBase at: frameIndex) + 1 + index! !

!OilBaseCompiler methodsFor: 'frames' stamp: 'cb 10/25/2026 00:45'!
pcMapIndex: pc frame: frameIndex
	<inline: true>
	^(framePCBase at: frameIndex) + pc - (frameStartPC at: frameIndex)! !

!OilBaseCompiler methodsFor: 'frames' stamp: 'cb 10/25/2026 00:45'!
exitFrame: frameIndex
	"Bind the exit label of the inlined frame frameIndex: all its returns leave the result in its base register
	 (or, for a single final return, as a lazy descriptor).  The base register becomes the caller's stack top."
	| baseReg chain |
	baseReg := frameBase at: frameIndex.
	chain := frameExitChain at: frameIndex.
	currentFrame := frameParent at: frameIndex.
	currentPC := frameCallPC at: frameIndex.
	chain ~= OilNoLink
		ifTrue:
			["A final jump to the exit label that immediately precedes it is useless"
			 (oilDeadCode and: [lastInstIR = chain and: [(self opcodeAt: chain) = OilJump]]) ifTrue:
				[chain := self imm16At: chain.
				 self retractLastInstruction].
			 self patchChain: chain to: irIndex.
			 oilDeadCode := false.
			 self forgetKnowledgeAtLabel.
			 self resetTVSlotsToOwn.
			 self setOwn: baseReg]
		ifFalse:
			[(frameHasLazy at: frameIndex) ifTrue:
				[self setSlot: baseReg kind: (frameLazyKind at: frameIndex) value: (frameLazyValue at: frameIndex).
				 (frameLazyKind at: frameIndex) = OilDescCond ifTrue:
					[pendingCondSlot := baseReg.
					 pendingCondIndex := frameLazyValue at: frameIndex].
				 oilDeadCode := false]].
	simStackTop := baseReg.
	baseReg to: (frameMaxReg at: frameIndex) do: [:regIndex| slotFlags at: regIndex put: 0].
	pcMapTop := framePCBase at: frameIndex! !

!OilBaseCompiler methodsFor: 'translation' stamp: 'cb 10/25/2026 00:45'!
translateFrame: frameIndex
	<inline: false>
	"Translate the bytecodes of frame frameIndex into the IR buffer.  Answer false if compilation failed."
	| pc end next tag op1 op2 target ipc |
	pc := frameStartPC at: frameIndex.
	end := frameEndPC at: frameIndex.
	[pc <= end and: [failed not]] whileTrue:
		[self setScanMethod: (frameMethod at: frameIndex).
		 self decodeAt: pc.
		 next := oilNextPC. tag := opcodeTag. op1 := operand1. op2 := operand2. target := oilTargetPC. ipc := instrPC.
		 currentFrame := frameIndex.
		 currentPC := ipc.
		 (pcTarget at: (self pcMapIndex: ipc frame: frameIndex)) ~= 0 ifTrue:
			[self bindLabelAt: ipc frame: frameIndex].
		 oilDeadCode ifFalse:
			[self takeSnapshotFrame: frameIndex pc: ipc.
			 next := self translateTag: tag op1: op1 op2: op2 target: target next: next frame: frameIndex].
		 pc := next].
	^failed not! !

!OilBaseCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/25/2026 00:45'!
takeSnapshotFrame: frameIndex pc: pc
	"Record the virtual state at the start of the bytecode at pc of frame frameIndex: the descriptors of all live
	 registers (the register window 0..simStackTop, which holds the receivers, temps and stacks of frameIndex and of
	 all the frames inlining it) and of the scalar replaced temp vector slots and captures (high registers).
	 A deopt site recorded while translating this bytecode resumes the interpreter right before it, in this
	 state.  Descriptors are copied: the translation of the bytecode may change them before the site."
	<inline: false>
	snapFrame := frameIndex.
	snapPC := pc.
	snapTop := simStackTop.
	snapHighTop := highRegTop.
	0 to: simStackTop do:
		[:vreg|
		snapKind at: vreg put: (slotKind at: vreg).
		snapValue at: vreg put: (slotValue at: vreg)].
	highRegTop + 1 to: OilMaxReg do:
		[:vreg|
		snapKind at: vreg put: (slotKind at: vreg).
		snapValue at: vreg put: (slotValue at: vreg)]! !

!OilBaseCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/25/2026 00:45'!
copySnapshotToSite: siteIndex
	"Append the current snapshot to the site pool for deopt site siteIndex.  A lazy comparison in the snapshot
	 is materialized (in its own register) before the site's instruction is emitted (see recordSite:),
	 so it is recorded as that register."
	| base |
	<inline: false>
	base := sitePoolTop.
	base + snapTop + 1 + (OilMaxReg - snapHighTop) > OilSitePoolSize ifTrue:
		[siteSnapBase at: siteIndex put: -1.
		 ^self].
	siteSnapBase at: siteIndex put: base.
	siteSnapTop at: siteIndex put: snapTop.
	siteSnapHigh at: siteIndex put: snapHighTop.
	0 to: snapTop do:
		[:vreg|
		(snapKind at: vreg) = OilDescCond
			ifTrue:
				[sitePoolKind at: base put: OilDescReg.
				 sitePoolValue at: base put: vreg]
			ifFalse:
				[sitePoolKind at: base put: (snapKind at: vreg).
				 sitePoolValue at: base put: (snapValue at: vreg)].
		base := base + 1].
	snapHighTop + 1 to: OilMaxReg do:
		[:vreg|
		sitePoolKind at: base put: (snapKind at: vreg).
		sitePoolValue at: base put: (snapValue at: vreg).
		base := base + 1].
	sitePoolTop := base! !

!OilBaseCompiler methodsFor: 'translation' stamp: 'cb 10/25/2026 00:45'!
translateTag: tag op1: op1 op2: op2 target: target next: next frame: frameIndex
	<inline: false>
	"Translate one (logical) bytecode.  Answer the pc of the next bytecode to translate."
	| isBlock |
	isBlock := frameIsBlock at: frameIndex.
	tag caseOf: {
		[OilTagPushRcvrVar]		-> [self genPushRcvrVar: op1 frame: frameIndex].
		[OilTagPushLitVar]		-> [self genPushLitVar: op1 frame: frameIndex].
		[OilTagPushLitConst]		-> [self push: OilDescConst value: (self literalHandle: op1 frame: frameIndex)].
		[OilTagPushTemp]			-> [self genPushTemp: op1 frame: frameIndex].
		[OilTagPushSelf]			-> [self push: (frameSelfKind at: frameIndex) value: (frameSelfValue at: frameIndex)].
		[OilTagPushTrue]			-> [self push: OilDescConst value: trueHandle].
		[OilTagPushFalse]		-> [self push: OilDescConst value: falseHandle].
		[OilTagPushNil]			-> [self push: OilDescConst value: nilHandle].
		[OilTagPushInteger]		-> [self push: OilDescConst value: (self handleForSmallInteger: op1)].
		[OilTagPushCharacter]	-> [self push: OilDescConst value: (self handleForCharacter: op1)].
		[OilTagDup]				-> [self genDup].
		[OilTagPop]				-> [simStackTop := simStackTop - 1].
		[OilTagNop]				-> [].
		[OilTagReturnSelf]		-> [self genReturnKind: (frameSelfKind at: frameIndex) value: (frameSelfValue at: frameIndex) nonLocal: isBlock frame: frameIndex next: next].
		[OilTagReturnTrue]		-> [self genReturnKind: OilDescConst value: trueHandle nonLocal: isBlock frame: frameIndex next: next].
		[OilTagReturnFalse]		-> [self genReturnKind: OilDescConst value: falseHandle nonLocal: isBlock frame: frameIndex next: next].
		[OilTagReturnNil]		-> [self genReturnKind: OilDescConst value: nilHandle nonLocal: isBlock frame: frameIndex next: next].
		[OilTagReturnTop]		-> [self genReturnTopNonLocal: isBlock frame: frameIndex next: next].
		[OilTagBlockReturnNil]	-> [self genReturnKind: OilDescConst value: nilHandle nonLocal: false frame: frameIndex next: next].
		[OilTagBlockReturnTop]	-> [self genReturnTopNonLocal: false frame: frameIndex next: next].
		[OilTagSendSpecial]		-> [^self genSpecialSend: op1 numArgs: op2 frame: frameIndex next: next].
		[OilTagSend]				-> [self genSend: (self literalHandle: op1 frame: frameIndex) numArgs: op2 super: false frame: frameIndex].
		[OilTagSendSuper]		-> [self genSend: (self literalHandle: op1 frame: frameIndex) numArgs: op2 super: true frame: frameIndex].
		[OilTagJump]				-> [self genJumpTo: target frame: frameIndex].
		[OilTagJumpTrue]			-> [self genJumpIf: true to: target frame: frameIndex].
		[OilTagJumpFalse]		-> [self genJumpIf: false to: target frame: frameIndex].
		[OilTagStoreRcvrVar]		-> [self genStoreRcvrVar: op1 pop: false frame: frameIndex].
		[OilTagPopIntoRcvrVar]	-> [self genStoreRcvrVar: op1 pop: true frame: frameIndex].
		[OilTagStoreTemp]		-> [self storeTopIntoReg: (self tempReg: op1 frame: frameIndex) pop: false].
		[OilTagPopIntoTemp]		-> [self storeTopIntoReg: (self tempReg: op1 frame: frameIndex) pop: true].
		[OilTagStoreLitVar]		-> [self genStoreLitVar: op1 pop: false frame: frameIndex].
		[OilTagPopIntoLitVar]	-> [self genStoreLitVar: op1 pop: true frame: frameIndex].
		[OilTagPushNewArray]		-> [self genPushNewArray: op1 pop: op2 = 1].
		[OilTagPushRemoteTemp]	-> [self genPushRemoteTemp: op1 inVector: op2 frame: frameIndex].
		[OilTagStoreRemoteTemp]	-> [self genStoreRemoteTemp: op1 inVector: op2 pop: false frame: frameIndex].
		[OilTagPopIntoRemoteTemp] -> [self genStoreRemoteTemp: op1 inVector: op2 pop: true frame: frameIndex].
		[OilTagPushFullClosure]	-> [self genPushFullClosure: op1 flags: op2 frame: frameIndex] }
		otherwise: [self abortCompilation: OilFailUnsupportedBytecode].
	^next! !

!OilBaseCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
bindLabelAt: pc frame: frameIndex
	"pc is a branch target of frame frameIndex.  Make the state canonical (or, coming out of dead code,
	 adopt the canonical state of the branches to it), resolve pending forward branches and record the label."
	| mapIndex |
	mapIndex := self pcMapIndex: pc frame: frameIndex.
	oilDeadCode
		ifTrue:
			[(pcChain at: mapIndex) = OilNoLink ifTrue: [^self]. "unreachable"
			 oilDeadCode := false.
			 simStackTop := pcDepth at: mapIndex.
			 self resetMutableSlotsOfFrame: frameIndex]
		ifFalse:
			[self flushFrame: frameIndex].
	self patchChain: (pcChain at: mapIndex) to: irIndex.
	pcChain at: mapIndex put: OilNoLink.
	pcLabelIR at: mapIndex put: irIndex.
	self forgetKnowledgeAtLabel! !

!OilBaseCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
patchChain: head to: targetIndex
	"Forward branches to a not yet bound label are chained through their 16-bit target fields."
	| link next |
	link := head.
	[link ~= OilNoLink] whileTrue:
		[next := self imm16At: link.
		 self patchBranch: link to: targetIndex.
		 link := next]! !

!OilBaseCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
patchBranch: index to: targetIndex
	oilIRBuffer at: index put: (((oilIRBuffer at: index) bitAnd: 16rFFFF0000) bitOr: (targetIndex bitAnd: 16rFFFF))! !

!OilBaseCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
forgetKnowledgeAtLabel
	"At a merge point, facts established on one path are lost: tagged-arithmetic relations and guarded classes.
	 Only the classes of the active frames' receivers dominate every label (guarded before frame entry)."
	| ancestorFrame |
	lastLabelIR := irIndex.
	0 to: OilMaxReg do:
		[:regIndex|
		affineBase at: regIndex put: -1.
		knownClass at: regIndex put: 0].
	ancestorFrame := currentFrame.
	[ancestorFrame >= 0] whileTrue:
		[(frameSelfKind at: ancestorFrame) = OilDescReg ifTrue:
			[knownClass at: (frameSelfValue at: ancestorFrame) put: (frameSelfClass at: ancestorFrame)].
		 ancestorFrame := frameParent at: ancestorFrame]! !

!OilBaseCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
flushFrame: frameIndex
	"Before a branch or a label: make every mutable register of frame frameIndex (temps and stack) and every
	 scalar replaced temp vector slot hold its value in its own register, so that all paths agree."
	(frameTempStart at: frameIndex) to: simStackTop do:
		[:slotIndex| ((self isImmutable: slotIndex) or: [(slotKind at: slotIndex) = OilDescTempVector]) ifFalse: [self materializeSlot: slotIndex]].
	self flushTVSlots! !

!OilBaseCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
flushTVSlots
	highRegTop + 1 to: OilMaxReg do:
		[:highReg| ((slotFlags at: highReg) bitAnd: OilFlagTVSlot) ~= 0 ifTrue: [self materializeSlot: highReg]]! !

!OilBaseCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
resetMutableSlotsOfFrame: frameIndex
	(frameTempStart at: frameIndex) to: simStackTop do:
		[:slotIndex|
		((self isImmutable: slotIndex) or: [(slotKind at: slotIndex) = OilDescTempVector]) ifFalse:
			[self setOwn: slotIndex]].
	self resetTVSlotsToOwn! !

!OilBaseCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
resetTVSlotsToOwn
	highRegTop + 1 to: OilMaxReg do:
		[:highReg| ((slotFlags at: highReg) bitAnd: OilFlagTVSlot) ~= 0 ifTrue: [self setOwn: highReg]]! !

!OilBaseCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
emitBranch: op cond: condReg to: target frame: frameIndex
	"Emit a jump/branch to bytecode pc target of frame frameIndex: backward branches go to a bound label,
	 forward branches are chained until their label is bound."
	| mapIndex labelIndex chainInst |
	mapIndex := self pcMapIndex: target frame: frameIndex.
	target <= currentPC
		ifTrue:
			[labelIndex := pcLabelIR at: mapIndex.
			 labelIndex < 0 ifTrue: [^self abortCompilation: OilFailInternal].
			 self emitOp: op a: condReg imm16: labelIndex]
		ifFalse:
			[chainInst := self emitOp: op a: condReg imm16: (pcChain at: mapIndex).
			 pcChain at: mapIndex put: chainInst.
			 pcDepth at: mapIndex put: simStackTop]! !

!OilBaseCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
emitOp: op a: a b: b c: c
	<inline: false>
	"Append the one word instruction [op | a | b | c].  Answer its index.
	 A pending lazy comparison result is materialized first: nothing may clobber its operands."
	| idx |
	pendingCondSlot >= 0 ifTrue: [self materializePendingCond].
	irIndex >= (OilBufferWords - 8) ifTrue:
		[self abortCompilation: OilFailBufferFull.
		 ^0].
	idx := irIndex.
	oilIRBuffer at: idx put: ((op bitShift: 24)
								bitOr: (((a bitAnd: 255) bitShift: 16)
								bitOr: (((b bitAnd: 255) bitShift: 8)
								bitOr: (c bitAnd: 255)))).
	irIndex := idx + 1.
	irInstCount := irInstCount + 1.
	lastInstIR := idx.
	^idx! !

!OilBaseCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
emitOp: op a: a imm16: imm
	^self emitOp: op a: a b: ((imm bitShift: -8) bitAnd: 255) c: (imm bitAnd: 255)! !

!OilBaseCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
emitWord: word
	irIndex < OilBufferWords ifTrue:
		[oilIRBuffer at: irIndex put: (word bitAnd: 16rFFFFFFFF).
		 irIndex := irIndex + 1]! !

!OilBaseCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
emit64: value
	"64-bit operand (an oop: literal, selector, class tag), low word first."
	self emitWord: (value bitAnd: 16rFFFFFFFF).
	self emitWord: ((value bitShift: -32) bitAnd: 16rFFFFFFFF)! !

!OilBaseCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
emitPackedArgs: firstReg count: n
	"OilCallN/OilCallSuper argument registers, four 8-bit register numbers per word (unused bytes are 255)."
	| word |
	0 to: n - 1 by: 4 do:
		[:i|
		word := 0.
		0 to: 3 do:
			[:j|
			word := (word bitShift: 8) bitOr: (i + j < n ifTrue: [firstReg + i + j] ifFalse: [255])].
		self emitWord: word]! !

!OilBaseCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
noteDef: r at: index
	"Register r is (re)defined by the instruction at index."
	lastDefIR at: r put: index.
	regVersion at: r put: (regVersion at: r) + 1.
	affineBase at: r put: -1.
	knownClass at: r put: 0! !

!OilBaseCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
emitConst: handle into: r
	"OilConstTagged for SmallIntegers whose tagged value fits 16 signed bits, OilConst64 otherwise."
	| idx |
	((self isSmallIntegerHandle: handle)
	 and: [(self smallIntegerValueOf: handle) between: -4096 and: 4095])
		ifTrue:
			[idx := self emitOp: OilConstTagged a: r imm16: (handle bitAnd: 16rFFFF).
			 self noteDef: r at: idx.
			 knownClass at: r put: smallIntegerClassHandle]
		ifFalse:
			[idx := self emitOp: OilConst64 a: r b: 0 c: 0.
			 self emit64: handle.
			 self noteDef: r at: idx]! !

!OilBaseCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
emitMove: dst from: src
	| idx |
	dst = src ifTrue: [^self].
	idx := self emitOp: OilMove a: dst b: src c: 0.
	self noteDef: dst at: idx.
	knownClass at: dst put: (knownClass at: src)! !

!OilBaseCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
emitGuardOn: r class: classHandle
	| site |
	site := self recordSite: OilSiteGuard.
	self emitOp: OilGuardClass a: r imm16: site.
	self emit64: classHandle.
	knownClass at: r put: classHandle! !

!OilBaseCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
recordSite: kind
	"Record a deopt site for the instruction about to be emitted: its IR index, the inlined frame and the bytecode pc,
	 plus a copy of the virtual state at the start of that bytecode (see takeSnapshotFrame:pc:).  A pending lazy
	 comparison is materialized first so that the site's IR index is the index of its instruction.  A site recorded
	 outside of the bytecode whose state was snapshotted has no state (siteSnapBase -1): the back end refuses it."
	| n |
	pendingCondSlot >= 0 ifTrue: [self materializePendingCond].
	n := numSites.
	n >= OilMaxSites ifTrue:
		[self abortCompilation: OilFailTooManySites.
		 ^0].
	siteIR at: n put: irIndex.
	siteFrame at: n put: currentFrame.
	sitePC at: n put: currentPC.
	siteKind at: n put: kind.
	(currentFrame = snapFrame and: [currentPC = snapPC])
		ifTrue: [self copySnapshotToSite: n]
		ifFalse: [siteSnapBase at: n put: -1].
	numSites := n + 1.
	^n! !

!OilBaseCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
retractLastInstruction
	"Delete the last emitted instruction (a one word instruction).  Its deopt site, if any, becomes dead
	 (IR index -2); sites are not removed since a pending lazy comparison site (IR index -1) may follow."
	irIndex := lastInstIR.
	irInstCount := irInstCount - 1.
	numSites - 1 to: 0 by: -1 do:
		[:s| (siteIR at: s) >= irIndex ifTrue: [siteIR at: s put: -2]].
	lastInstIR := -1! !

!OilBaseCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
retractIfDeadDefinitionOf: r
	"r is a consumed expression stack register.  If the last instruction only computed r, delete it."
	(lastInstIR >= 0
	 and: [lastInstIR >= lastLabelIR
	 and: [(lastDefIR at: r) = lastInstIR
	 and: [(slotFlags at: r) = 0
	 and: [(self instructionLengthAt: lastInstIR) = 1]]]]) ifFalse: [^false].
	self retractLastInstruction.
	lastDefIR at: r put: -1.
	^true! !

!OilBaseCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
retarget: src to: dst
	"src is a dead expression stack register.  If the last instruction defined it, make it define dst instead.
	 Answer whether this was done (otherwise the caller emits a move)."
	| idx word |
	idx := lastDefIR at: src.
	(idx >= 0 and: [idx = lastInstIR and: [idx >= lastLabelIR]]) ifFalse: [^false].
	word := oilIRBuffer at: idx.
	(self opcodeHasDest: (word bitShift: -24)) ifFalse: [^false].
	((word bitShift: -16) bitAnd: 255) = src ifFalse: [^false].
	oilIRBuffer at: idx put: ((word bitAnd: 16rFF00FFFF) bitOr: (dst bitShift: 16)).
	lastDefIR at: dst put: idx.
	lastDefIR at: src put: -1.
	affineBase at: dst put: (affineBase at: src).
	affineConst at: dst put: (affineConst at: src).
	affineVersion at: dst put: (affineVersion at: src).
	regVersion at: dst put: (regVersion at: dst) + 1.
	knownClass at: dst put: (knownClass at: src).
	^true! !

!OilBaseCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
opcodeHasDest: op
	^op = OilConstTagged or: [op = OilConst64 or: [op = OilMove or: [(op between: OilAddTagged and: OilOddTagged)
		or: [op = OilLoadField or: [op = OilLoadElement or: [(op between: OilCall0 and: OilAddImmTagged)
		or: [op = OilLoadSize or: [op = OilMakeClosure or: [op = OilNewArray or: [op = OilCallSuper or: [op = OilAddImmTaggedNC or: [op = OilModTagged
		or: [(op between: OilLoadByteSize and: OilLoadChar) or: [op = OilCompareBytes or: [op = OilCharValue
		or: [op = OilStreamNext or: [op = OilStreamNextPut or: [(op between: OilAddFloat and: OilDivFloat) or: [op between: OilIdentityHash and: OilSkipSeparators]]]]]]]]]]]]]]]]]]]! !

!OilBaseCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
setSlot: i kind: k value: v
	<inline: true>
	slotKind at: i put: k.
	slotValue at: i put: v! !

!OilBaseCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
setOwn: i
	<inline: true>
	slotKind at: i put: OilDescReg.
	slotValue at: i put: i! !

!OilBaseCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
isImmutable: i
	<inline: true>
	^((slotFlags at: i) bitAnd: OilFlagImmutable) ~= 0! !

!OilBaseCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
push: k value: v
	| i |
	i := simStackTop + 1.
	i >= highRegTop ifTrue:
		[self abortCompilation: OilFailOutOfRegisters.
		 ^i].
	simStackTop := i.
	slotFlags at: i put: 0.
	self setSlot: i kind: k value: v.
	^i! !

!OilBaseCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
pushOwnSlot
	"Push a stack entry whose value the caller is about to compute into its own register."
	| newSlot |
	newSlot := self push: OilDescReg value: simStackTop + 1.
	knownClass at: newSlot put: 0.
	affineBase at: newSlot put: -1.
	^newSlot! !

!OilBaseCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
pushResultOf: opcode b: srcReg1 c: srcReg2 site: aSiteKind
	"Push a stack entry computed into its own register by the one word instruction [opcode | dest | srcReg1 | srcReg2]
	 (which can deoptimize if aSiteKind ~= 0).  Answer the instruction's index (64-bit operands may follow)."
	| destReg instIndex |
	aSiteKind ~= 0 ifTrue: [self recordSite: aSiteKind].
	destReg := self pushOwnSlot.
	instIndex := self emitOp: opcode a: destReg b: srcReg1 c: srcReg2.
	self noteDef: destReg at: instIndex.
	^instIndex! !

!OilBaseCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
pushSmallIntegerResultOf: opcode b: srcReg1 c: srcReg2
	"Tagged SmallInteger arithmetic: deoptimizes on a non-SmallInteger operand or on overflow."
	self pushResultOf: opcode b: srcReg1 c: srcReg2 site: OilSiteArith.
	knownClass at: simStackTop put: smallIntegerClassHandle.
	^true! !

!OilBaseCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
regForKind: descKind value: descValue scratch: scratchReg
	"Answer a register holding the value described by (descKind, descValue), materializing a constant into scratchReg."
	descKind = OilDescReg ifTrue: [^descValue].
	descKind = OilDescConst ifTrue:
		[self emitConst: descValue into: scratchReg.
		 ^scratchReg].
	descKind = OilDescCond ifTrue:
		[self emitCond: descValue booleanInto: scratchReg.
		 ^scratchReg].
	self requireEagerClosures.
	^scratchReg! !

!OilBaseCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
regForSlot: slotIndex
	"Answer a register holding slotIndex's value.  A constant is materialized in slotIndex's own register
	 (re-materialized at each use if slotIndex is immutable, so that no path dependent state is created)."
	((slotKind at: slotIndex) = OilDescConst and: [self isImmutable: slotIndex]) ifTrue:
		[^self regForKind: OilDescConst value: (slotValue at: slotIndex) scratch: slotIndex].
	(slotKind at: slotIndex) = OilDescReg ifTrue: [^slotValue at: slotIndex].
	self materializeSlot: slotIndex.
	^slotIndex! !

!OilBaseCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
materializeSlot: slotIndex
	"Make slotIndex hold its value in its own register (e.g. for a send's receiver and arguments)."
	(slotKind at: slotIndex) = OilDescReg
		ifTrue: [self emitMove: slotIndex from: (slotValue at: slotIndex)]
		ifFalse: [self regForKind: (slotKind at: slotIndex) value: (slotValue at: slotIndex) scratch: slotIndex].
	self setOwn: slotIndex! !

!OilBaseCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
stabilizeIncomingSlot: slotIndex
	"An inlined frame's receiver/argument must not alias a temp vector slot register, which inlined blocks may assign."
	| regVal |
	(slotKind at: slotIndex) = OilDescCond ifTrue: [^self materializeSlot: slotIndex].
	(slotKind at: slotIndex) = OilDescReg ifFalse: [^self].
	regVal := slotValue at: slotIndex.
	(regVal ~= slotIndex and: [((slotFlags at: regVal) bitAnd: OilFlagTVSlot) ~= 0]) ifTrue:
		[self emitMove: slotIndex from: regVal.
		 self setOwn: slotIndex]! !

!OilBaseCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
invalidateAliasesOf: targetReg
	"targetReg, a named temp or temp vector slot register, is about to be assigned.  Copy its current value into
	 every live mutable slot aliasing it.  A live virtual closure or immutable slot that captured targetReg
	 forces eager closures."
	| descKind |
	(pendingCondSlot >= 0
	 and: [(condRA at: pendingCondIndex) = targetReg
		or: [(condUseImm at: pendingCondIndex) not and: [(condRB at: pendingCondIndex) = targetReg]]]) ifTrue:
		[self materializePendingCond].
	0 to: simStackTop do:
		[:slotIndex|
		descKind := slotKind at: slotIndex.
		(descKind = OilDescReg and: [(slotValue at: slotIndex) = targetReg and: [slotIndex ~= targetReg]]) ifTrue:
			[(self isImmutable: slotIndex)
				ifTrue: [self requireEagerClosures]
				ifFalse: [self emitMove: slotIndex from: targetReg. self setOwn: slotIndex]].
		(descKind = OilDescBlock and: [self virtualBlock: (slotValue at: slotIndex) captures: targetReg]) ifTrue:
			[self requireEagerClosures]]! !

!OilBaseCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
virtualBlock: vobjIndex captures: targetReg
	"Does the virtual closure vobjIndex (or a virtual closure it captured, transitively) capture register targetReg?
	 Iterative (explicit work stack) so that it translates to plain C."
	| stack sp currentVObj baseIndex descKind |
	<inline: false>
	<var: #stack declareC: 'sqInt stack[OilMaxVObjs]'>
	self cCode: [] inSmalltalk: [stack := CArrayAccessor on: (Array new: OilMaxVObjs)].
	stack at: 0 put: vobjIndex.
	sp := 1.
	[sp > 0] whileTrue:
		[sp := sp - 1.
		 currentVObj := stack at: sp.
		 ((vobjSelfKind at: currentVObj) = OilDescReg and: [(vobjSelfValue at: currentVObj) = targetReg]) ifTrue: [^true].
		 baseIndex := vobjCopiedBase at: currentVObj.
		 0 to: (vobjNumCopied at: currentVObj) - 1 do:
			[:copiedIndex|
			descKind := capturedKind at: baseIndex + copiedIndex.
			(descKind = OilDescReg and: [(capturedValue at: baseIndex + copiedIndex) = targetReg]) ifTrue: [^true].
			(descKind = OilDescBlock and: [sp < OilMaxVObjs]) ifTrue:
				[stack at: sp put: (capturedValue at: baseIndex + copiedIndex).
				 sp := sp + 1]]].
	^false! !

!OilBaseCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
newVObj: kind
	| vobjIndex |
	numVObjs >= OilMaxVObjs ifTrue:
		[self abortCompilation: OilFailTooManyVirtualObjects.
		 ^0].
	vobjIndex := numVObjs.
	numVObjs := vobjIndex + 1.
	vobjKind at: vobjIndex put: kind.
	vobjNumCopied at: vobjIndex put: 0.
	vobjCopiedBase at: vobjIndex put: capturedTop.
	vobjSize at: vobjIndex put: 0.
	vobjSlotBase at: vobjIndex put: 0.
	vobjSelfClass at: vobjIndex put: 0.
	^vobjIndex! !

!OilBaseCompiler methodsFor: 'stores' stamp: 'cb 10/24/2026 10:30'!
storeTopIntoReg: targetReg pop: popFlag
	"Store the top of stack into targetReg, a named temp or a scalar replaced temp vector slot.
	 Constants and virtual temp vectors are stored as descriptors; a value just computed into the stack top
	 is retargeted to targetReg instead of being moved."
	| topSlot descKind slotVal |
	topSlot := simStackTop.
	(slotKind at: topSlot) = OilDescCond ifTrue: [self materializeSlot: topSlot].
	descKind := slotKind at: topSlot.
	slotVal := slotValue at: topSlot.
	(descKind = OilDescReg and: [slotVal = targetReg]) ifTrue: "x := x"
		[popFlag ifTrue: [simStackTop := topSlot - 1].
		 ^self].
	self invalidateAliasesOf: targetReg.
	descKind = OilDescBlock ifTrue:
		[^self requireEagerClosures].
	descKind = OilDescTempVector
		ifTrue:
			[((slotFlags at: targetReg) bitAnd: OilFlagTVSlot) ~= 0 ifTrue:
				[^self requireEagerClosures].
			 self setSlot: targetReg kind: descKind value: slotVal]
		ifFalse:
			[descKind = OilDescConst
				ifTrue:
					[self setSlot: targetReg kind: descKind value: slotVal.
					 regVersion at: targetReg put: (regVersion at: targetReg) + 1.
					 affineBase at: targetReg put: -1.
					 knownClass at: targetReg put: 0]
				ifFalse:
					[(slotVal = topSlot and: [self retarget: topSlot to: targetReg]) ifFalse:
						[self emitMove: targetReg from: slotVal].
					 self setOwn: targetReg]].
	popFlag
		ifTrue: [simStackTop := topSlot - 1]
		ifFalse:
			[(slotKind at: targetReg) = OilDescReg
				ifTrue: [self setSlot: topSlot kind: OilDescReg value: targetReg]
				ifFalse: [self setSlot: topSlot kind: (slotKind at: targetReg) value: (slotValue at: targetReg)]]! !

!OilBaseCompiler methodsFor: 'stores' stamp: 'cb 10/24/2026 10:30'!
genStoreRcvrVar: instVarIndex pop: popFlag frame: frameIndex
	| valReg rcvrReg |
	instVarIndex > 255 ifTrue: [^self abortCompilation: OilFailUnsupportedBytecode].
	valReg := self regForSlot: simStackTop.
	rcvrReg := self selfRegOfFrame: frameIndex scratch: simStackTop + 1.
	self recordSite: OilSiteStore. "the store fails on an immutable object: the interpreter retries it"
	self emitOp: OilStoreField a: valReg b: rcvrReg c: instVarIndex.
	popFlag ifTrue: [simStackTop := simStackTop - 1]! !

!OilBaseCompiler methodsFor: 'stores' stamp: 'cb 10/24/2026 10:30'!
genStoreLitVar: literalIndex pop: popFlag frame: frameIndex
	"Store into a global/class variable's binding (value is slot 1 of the binding)."
	| valReg scratchReg |
	valReg := self regForSlot: simStackTop.
	scratchReg := simStackTop + 1.
	self emitConst: (self literalHandle: literalIndex frame: frameIndex) into: scratchReg.
	self recordSite: OilSiteStore.
	self emitOp: OilStoreField a: valReg b: scratchReg c: 1.
	popFlag ifTrue: [simStackTop := simStackTop - 1]! !

!OilBaseCompiler methodsFor: 'stores' stamp: 'cb 10/24/2026 10:30'!
genStoreRemoteTemp: remoteIndex inVector: vectorIndex pop: popFlag frame: frameIndex
	| vectorReg valReg vecReg |
	vectorReg := self tempReg: vectorIndex frame: frameIndex.
	(slotKind at: vectorReg) = OilDescTempVector ifTrue:
		[^self storeTopIntoReg: (vobjSlotBase at: (slotValue at: vectorReg)) + remoteIndex pop: popFlag].
	valReg := self regForSlot: simStackTop.
	vecReg := self regForSlot: vectorReg.
	self recordSite: OilSiteStore.
	self emitOp: OilStoreField a: valReg b: vecReg c: remoteIndex.
	popFlag ifTrue: [simStackTop := simStackTop - 1]! !

!OilBaseCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
selfRegOfFrame: frameIndex scratch: scratchReg
	^self regForKind: (frameSelfKind at: frameIndex) value: (frameSelfValue at: frameIndex) scratch: scratchReg! !

!OilBaseCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
genPushTemp: tempIndex frame: frameIndex
	| tempReg |
	tempReg := self tempReg: tempIndex frame: frameIndex.
	self push: (slotKind at: tempReg) value: (slotValue at: tempReg)! !

!OilBaseCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
genDup
	| top |
	top := simStackTop.
	(slotKind at: top) = OilDescCond ifTrue: [self materializeSlot: top].
	self push: (slotKind at: top) value: (slotValue at: top)! !

!OilBaseCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
genPushRcvrVar: instVarIndex frame: frameIndex
	instVarIndex > 255 ifTrue: [^self abortCompilation: OilFailUnsupportedBytecode].
	self pushResultOf: OilLoadField b: (self selfRegOfFrame: frameIndex scratch: simStackTop + 1) c: instVarIndex site: 0! !

!OilBaseCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
genPushLitVar: literalIndex frame: frameIndex
	"Read-only bindings (classes) fold to their value; other globals load slot 1 (value) of their binding."
	| binding |
	binding := self oilLiteral: literalIndex ofMethod: (frameMethod at: frameIndex).
	(self isReadOnlyBinding: binding) ifTrue:
		[^self push: OilDescConst value: (self bindingValueHandle: binding)].
	self emitConst: (self handleFor: binding) into: simStackTop + 1.
	self pushResultOf: OilLoadField b: simStackTop + 1 c: 1 site: 0! !

!OilBaseCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
genPushNewArray: arraySize pop: popFlag
	"A brace array {a. b} is allocated.  A temp vector (Array new: n, created by the bytecode compiler for
	 temps assigned in closures) is scalar replaced: its slots become high registers."
	| firstSlot vobjIndex baseReg |
	(popFlag or: [eagerClosures]) ifTrue:
		[popFlag ifTrue:
			[firstSlot := simStackTop - arraySize + 1.
			 firstSlot to: simStackTop do: [:slotIndex| self materializeSlot: slotIndex].
			 simStackTop := firstSlot - 1].
		 self pushResultOf: OilNewArray b: (popFlag ifTrue: [firstSlot] ifFalse: [OilFlagsReg]) c: arraySize site: OilSiteAlloc.
		 ^self].
	baseReg := highRegTop - arraySize + 1.
	baseReg <= (simStackTop + 32) ifTrue:
		[^self abortCompilation: OilFailOutOfRegisters].
	vobjIndex := self newVObj: OilDescTempVector.
	vobjSize at: vobjIndex put: arraySize.
	vobjSlotBase at: vobjIndex put: baseReg.
	highRegTop := baseReg - 1.
	baseReg to: baseReg + arraySize - 1 do:
		[:highReg|
		slotFlags at: highReg put: OilFlagTVSlot.
		self setSlot: highReg kind: OilDescConst value: nilHandle].
	self push: OilDescTempVector value: vobjIndex! !

!OilBaseCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
genPushRemoteTemp: remoteIndex inVector: vectorIndex frame: frameIndex
	| vectorReg slotRegister |
	vectorReg := self tempReg: vectorIndex frame: frameIndex.
	(slotKind at: vectorReg) = OilDescTempVector ifTrue:
		[slotRegister := (vobjSlotBase at: (slotValue at: vectorReg)) + remoteIndex.
		 ^self push: (slotKind at: slotRegister) value: (slotValue at: slotRegister)].
	self pushResultOf: OilLoadField b: (self regForSlot: vectorReg) c: remoteIndex site: 0! !

!OilBaseCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
genPushFullClosure: literalIndex flags: closureFlags frame: frameIndex
	"SistaV1 pushFullClosure.  flags = siyyyyyy: yyyyyy numCopied, s receiverOnStack, i ignoreOuterContext.
	 Normally the closure stays virtual (no allocation): its copied values are captured as descriptors.
	 In eager mode it is materialized with OilMakeClosure."
	| block numCopied rcvrOnStack firstSlot lowestSlot selfReg vobjIndex |
	block := self oilLiteral: literalIndex ofMethod: (frameMethod at: frameIndex).
	numCopied := closureFlags bitAnd: 63.
	rcvrOnStack := (closureFlags bitAnd: 128) ~= 0.
	firstSlot := simStackTop - numCopied + 1.
	lowestSlot := rcvrOnStack ifTrue: [firstSlot - 1] ifFalse: [firstSlot].
	eagerClosures ifTrue:
		[(frameIndex ~= 0 and: [(closureFlags bitAnd: 64) = 0]) ifTrue: "its outerContext would be the context of an inlined frame"
			[^self refuseInliningOfFrameOf: frameIndex].
		 lowestSlot to: simStackTop do: [:slotIndex| self materializeSlot: slotIndex].
		 selfReg := rcvrOnStack
						ifTrue: [firstSlot - 1]
						ifFalse: [self selfRegOfFrame: frameIndex scratch: simStackTop + 1].
		 simStackTop := lowestSlot - 1.
		 self pushResultOf: OilMakeClosure b: firstSlot c: numCopied site: OilSiteAlloc.
		 self emit64: (self handleFor: block).
		 "selfReg, the ignoreOuterContext flag and the frame whose context is the outerContext"
		 self emitWord: selfReg + ((closureFlags bitAnd: 64) ~= 0 ifTrue: [256] ifFalse: [0]) + (frameIndex bitShift: 16).
		 ^self].
	vobjIndex := self newVObj: OilDescBlock.
	failed ifTrue: [^self].
	vobjLiteral at: vobjIndex put: block.
	vobjHome at: vobjIndex put: (frameHome at: frameIndex).
	vobjOuter at: vobjIndex put: frameIndex. "the frame whose context is the closure's outerContext (deoptimization)"
	rcvrOnStack
		ifTrue:
			[self capture: firstSlot - 1 frame: frameIndex.
			 capturedTop := capturedTop - 1.
			 vobjSelfKind at: vobjIndex put: (capturedKind at: capturedTop).
			 vobjSelfValue at: vobjIndex put: (capturedValue at: capturedTop)]
		ifFalse:
			[vobjSelfKind at: vobjIndex put: (frameSelfKind at: frameIndex).
			 vobjSelfValue at: vobjIndex put: (frameSelfValue at: frameIndex).
			 vobjSelfClass at: vobjIndex put: (frameSelfClass at: frameIndex)].
	vobjCopiedBase at: vobjIndex put: capturedTop.
	vobjNumCopied at: vobjIndex put: numCopied.
	firstSlot to: simStackTop do: [:slotIndex| self capture: slotIndex frame: frameIndex].
	simStackTop := lowestSlot - 1.
	self push: OilDescBlock value: vobjIndex! !

!OilBaseCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
capture: slotIndex frame: frameIndex
	"Append slotIndex's descriptor to the captured values pool.  A value living in one of the current frame's
	 expression stack registers (about to be reused) is first copied to a stable high register."
	| descKind slotVal highReg |
	capturedTop >= OilMaxCaptured ifTrue:
		[^self abortCompilation: OilFailTooManyVirtualObjects].
	(slotKind at: slotIndex) = OilDescCond ifTrue: [self materializeSlot: slotIndex].
	descKind := slotKind at: slotIndex.
	slotVal := slotValue at: slotIndex.
	(descKind = OilDescReg and: [slotVal >= (frameStackStart at: frameIndex) and: [slotVal <= simStackTop]]) ifTrue:
		[highReg := highRegTop.
		 highReg <= (simStackTop + 32) ifTrue: [^self abortCompilation: OilFailOutOfRegisters].
		 highRegTop := highReg - 1.
		 slotFlags at: highReg put: OilFlagImmutable.
		 self emitMove: highReg from: slotVal.
		 self setOwn: highReg.
		 slotVal := highReg].
	capturedKind at: capturedTop put: descKind.
	capturedValue at: capturedTop put: slotVal.
	capturedTop := capturedTop + 1! !

!OilBaseCompiler methodsFor: 'returns' stamp: 'cb 10/24/2026 10:30'!
genReturnTopNonLocal: isNonLocal frame: frameIndex next: nextPC
	| topSlot |
	topSlot := simStackTop.
	simStackTop := topSlot - 1.
	self genReturnKind: (slotKind at: topSlot) value: (slotValue at: topSlot) nonLocal: isNonLocal frame: frameIndex next: nextPC! !

!OilBaseCompiler methodsFor: 'returns' stamp: 'cb 10/24/2026 10:30'!
genReturnKind: descKind value: descVal nonLocal: isNonLocal frame: frameIndex next: nextPC
	<inline: false>
	"Return (descKind, descVal) from frameIndex, or, for a non-local return from an inlined block, from its home frame.
	 From the compiled method this is OilReturn.  From an inlined frame the result is left in the frame's base
	 register (or, for a single final return, kept as a lazy descriptor) and control jumps to the frame's exit."
	| targetFrame baseReg retReg isLast instIndex retVal |
	oilDeadCode := true.
	targetFrame := isNonLocal ifTrue: [frameHome at: frameIndex] ifFalse: [frameIndex].
	(descKind = OilDescBlock or: [descKind = OilDescTempVector]) ifTrue:
		[^self requireEagerClosures].
	targetFrame = 0 ifTrue:
		[retReg := self regForKind: descKind value: descVal scratch: simStackTop + 1.
		 self emitOp: OilReturn a: retReg b: 0 c: 0.
		 ^self].
	(self isFrameActive: targetFrame) ifFalse:
		[^self abortCompilation: OilFailInternal].
	baseReg := frameBase at: targetFrame.
	isLast := isNonLocal not and: [nextPC > (frameEndPC at: frameIndex)].
	(isLast and: [(frameExitChain at: frameIndex) = OilNoLink]) ifTrue:
		[retVal := descVal.
		 (descKind = OilDescReg and: [descVal > baseReg and: [descVal <= highRegTop]]) ifTrue:
			"the value lives in a register of the dying frame: bring it to the result register"
			[(self retarget: descVal to: baseReg) ifFalse: [self emitMove: baseReg from: descVal].
			 retVal := baseReg].
		 frameHasLazy at: frameIndex put: true.
		 frameLazyKind at: frameIndex put: descKind.
		 frameLazyValue at: frameIndex put: retVal.
		 ^self].
	descKind = OilDescReg
		ifTrue: [descVal ~= baseReg ifTrue: [(self retarget: descVal to: baseReg) ifFalse: [self emitMove: baseReg from: descVal]]]
		ifFalse: [self regForKind: descKind value: descVal scratch: baseReg].
	self flushTVSlots.
	isLast ifTrue: [^self]. "falls through into the exit label"
	instIndex := self emitOp: OilJump a: 0 imm16: (frameExitChain at: targetFrame).
	frameExitChain at: targetFrame put: instIndex! !

!OilBaseCompiler methodsFor: 'jumps' stamp: 'cb 10/24/2026 10:30'!
genJumpTo: targetPC frame: frameIndex
	self flushFrame: frameIndex.
	self emitBranch: OilJump cond: 0 to: targetPC frame: frameIndex.
	oilDeadCode := true! !

!OilBaseCompiler methodsFor: 'jumps' stamp: 'cb 10/24/2026 10:30'!
genJumpIf: aBoolean to: targetPC frame: frameIndex
	| topSlot descKind slotVal condReg |
	topSlot := simStackTop.
	descKind := slotKind at: topSlot.
	slotVal := slotValue at: topSlot.
	simStackTop := topSlot - 1.
	descKind = OilDescCond ifTrue:
		["a lazy comparison result: compare and branch on the flags"
		 pendingCondSlot := -1.
		 self flushFrame: frameIndex.
		 self emitCondCompare: slotVal.
		 self emitBranch: (aBoolean ifTrue: [OilBranchTrue] ifFalse: [OilBranchFalse]) cond: OilFlagsReg to: targetPC frame: frameIndex.
		 ^self].
	(descKind = OilDescConst and: [slotVal = trueHandle or: [slotVal = falseHandle]]) ifTrue:
		["constant condition: the branch is folded"
		 (slotVal = trueHandle) = aBoolean ifTrue:
			[self genJumpTo: targetPC frame: frameIndex].
		 ^self].
	condReg := self regForKind: descKind value: slotVal scratch: topSlot.
	self flushFrame: frameIndex.
	self recordSite: OilSiteBranch. "mustBeBoolean"
	self emitBranch: (aBoolean ifTrue: [OilBranchTrue] ifFalse: [OilBranchFalse]) cond: condReg to: targetPC frame: frameIndex! !

!OilBaseCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
genSpecialSend: index numArgs: numArgs frame: frameIndex next: nextPC
	<inline: false>
	"Special selectors: inline tagged SmallInteger arithmetic and comparisons, Float arithmetic and comparisons, identity,
	 class; others are ordinary sends.  Answer the pc to continue at (a comparison may be fused with the following
	 conditional jump)."
	| floatPC |
	(index between: 2 and: 7) ifTrue:
		[(self canInlineSmallIntegerOpOn: simStackTop - 1 arg: simStackTop) ifTrue:
			[^self genCompare: index - 1 identity: false frame: frameIndex next: nextPC]] "OilCondLt..OilCondNe".
	(index = 22 or: [index = 24]) ifTrue:
		[^self genCompare: (index = 22 ifTrue: [OilCondIdentical] ifFalse: [OilCondNotIdentical]) identity: true frame: frameIndex next: nextPC].
	index = 23 ifTrue:
		[(self genClassOf: simStackTop) ifTrue: [^nextPC]].
	((index between: 0 and: 1) or: [index = 8 or: [(index between: 10 and: 15) and: [index ~= 11]]]) ifTrue:
		[(self canInlineSmallIntegerOpOn: simStackTop - 1 arg: simStackTop) ifTrue:
			[(self genArith: index) ifTrue: [^nextPC]]].
	(index <= 9 and: [(floatPC := self genFloatSend: index frame: frameIndex next: nextPC) >= 0]) ifTrue:
		[^floatPC].
	self genSend: (self specialSelectorHandle: index) numArgs: numArgs super: false frame: frameIndex.
	^nextPC! !

!OilBaseCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
canInlineSmallIntegerOpOn: rcvrSlot arg: argSlot
	"Speculate SmallInteger arithmetic if the receiver is a SmallInteger constant, is known to be a SmallInteger,
	 or its send site only saw SmallIntegers; the argument must not be a non-SmallInteger constant or a virtual object.
	 The tagged opcodes check their operands' tags and deoptimize on failure or overflow."
	| argKind profiledCls |
	argKind := slotKind at: argSlot.
	(argKind = OilDescBlock or: [argKind = OilDescTempVector or: [argKind = OilDescCond]]) ifTrue: [^false].
	(argKind = OilDescConst and: [(self isSmallIntegerHandle: (slotValue at: argSlot)) not]) ifTrue: [^false].
	(self isFloatSlot: argSlot) ifTrue: [^false]. "e.g. 2 * aFloat: see genFloatSend:frame:next:"
	(self isKnownSmallInteger: rcvrSlot) ifTrue: [^true].
	(slotKind at: rcvrSlot) = OilDescReg ifFalse: [^false].
	"The baseline JIT inlines SmallInteger arithmetic and comparisons and only sends the message for other
	 receivers.  So a send site whose inline cache is still unlinked has only ever seen SmallIntegers: speculate."
	profiledCls := self profiledClassAt: currentPC.
	^profiledCls = smallIntegerClassHandle
	  or: [profiledCls = 0 and: [self isUnlinkedSendAt: currentPC]]! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 14:00'!
isUnlinkedSendAt: pc
	"Has the send at pc in the current frame's method never been sent (no inline cache information at all)?"
	^self
		cCode: [cogit oilSendSiteUnlinkedAt: pc in: (frameMethod at: currentFrame)]
		inSmalltalk:
			[typeFeedback isNil
			 or: [(typeFeedback hasSiteAt: pc in: (frameMethod at: currentFrame)) not]]! !

!OilBaseCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
isKnownSmallInteger: slotIndex
	(slotKind at: slotIndex) = OilDescConst ifTrue: [^self isSmallIntegerHandle: (slotValue at: slotIndex)].
	^(slotKind at: slotIndex) = OilDescReg and: [(knownClass at: (slotValue at: slotIndex)) = smallIntegerClassHandle]! !

!OilBaseCompiler methodsFor: 'float arithmetic' stamp: 'cb 10/25/2026 02:00'!
genFloatSend: index frame: frameIndex next: nextPC
	"Special selectors + - < > <= >= = ~= * / on Floats: the receiver is a Float (see canInlineFloatOpOn:arg:) and
	 the argument a number, or, for + * and the comparisons, the reverse (the operands are swapped).  The opcodes
	 (OilAddFloat..OilCmpFloat) deoptimize unless the receiver is a Float and the argument a Float or a SmallInteger.
	 Answer the pc to continue at, or -1 if the send is not inlined."
	<inline: false>
	| rcvrSlot argSlot swapped rcvrReg argReg cond |
	rcvrSlot := simStackTop - 1.
	argSlot := simStackTop.
	swapped := (self canInlineFloatOpOn: rcvrSlot arg: argSlot) not.
	(swapped and: [(index = 1 or: [index = 9])
				or: [(self isFloatSlot: argSlot) not or: [(self isNumberSlot: rcvrSlot) not]]]) ifTrue:
		[^-1].
	rcvrReg := self regForSlot: rcvrSlot.
	argReg := self regForSlot: argSlot.
	swapped ifTrue: [| reg | reg := rcvrReg. rcvrReg := argReg. argReg := reg].
	simStackTop := rcvrSlot - 1.
	(index between: 2 and: 7) ifFalse:
		[self pushResultOf: (index <= 1 ifTrue: [OilAddFloat + index] ifFalse: [OilMulFloat + index - 8])
			b: rcvrReg c: argReg site: OilSiteArith.
		 ^nextPC].
	cond := swapped ifTrue: [self reversedCondition: index - 1] ifFalse: [index - 1].
	^self genFloatCompare: cond rcvr: rcvrReg arg: argReg frame: frameIndex next: nextPC! !

!OilBaseCompiler methodsFor: 'float arithmetic' stamp: 'cb 10/25/2026 02:00'!
genFloatCompare: cond rcvr: rcvrReg arg: argReg frame: frameIndex next: nextPC
	"OilCmpFloat fused with the following conditional jump, or, if there is none, answering true or false."
	| brTag brTarget brNext falseJump exitJump destReg |
	(nextPC >= 0 and: [self canFuseBranchAt: nextPC frame: frameIndex]) ifTrue:
		[brTag := opcodeTag. brTarget := oilTargetPC. brNext := oilNextPC.
		 self flushFrame: frameIndex.
		 self recordSite: OilSiteArith.
		 self emitOp: OilCmpFloat a: cond b: rcvrReg c: argReg.
		 self emitBranch: (brTag = OilTagJumpTrue ifTrue: [OilBranchTrue] ifFalse: [OilBranchFalse])
			cond: OilFlagsReg to: brTarget frame: frameIndex.
		 ^brNext].
	self recordSite: OilSiteArith.
	self emitOp: OilCmpFloat a: cond b: rcvrReg c: argReg.
	falseJump := self emitOp: OilBranchFalse a: OilFlagsReg imm16: 0.
	destReg := self pushOwnSlot.
	self emitConst: trueHandle into: destReg.
	exitJump := self emitOp: OilJump a: 0 imm16: 0.
	self patchBranch: falseJump to: irIndex.
	self emitConst: falseHandle into: destReg.
	self patchBranch: exitJump to: irIndex.
	lastLabelIR := irIndex.
	^nextPC! !

!OilBaseCompiler methodsFor: 'float arithmetic' stamp: 'cb 10/25/2026 02:00'!
canInlineFloatOpOn: rcvrSlot arg: argSlot
	"Speculate Float arithmetic if the receiver is known to be a Float or its send site only saw Floats (SmallFloat64
	 or BoxedFloat64) and the argument may be a number."
	(self isNumberSlot: argSlot) ifFalse: [^false].
	(self isFloatSlot: rcvrSlot) ifTrue: [^true].
	^(slotKind at: rcvrSlot) = OilDescReg
	  and: [self isFloatClass: (self profiledClassAt: currentPC)]! !

!OilBaseCompiler methodsFor: 'float arithmetic' stamp: 'cb 10/25/2026 02:00'!
isNumberSlot: slotIndex
	"May slotIndex hold a SmallInteger or a Float (a register, or such a constant)?"
	(slotKind at: slotIndex) = OilDescReg ifTrue: [^true].
	^(slotKind at: slotIndex) = OilDescConst
	  and: [(self isSmallIntegerHandle: (slotValue at: slotIndex)) or: [self isFloatHandle: (slotValue at: slotIndex)]]! !

!OilBaseCompiler methodsFor: 'float arithmetic' stamp: 'cb 10/25/2026 02:00'!
isFloatSlot: slotIndex
	"Is slotIndex a Float constant, or a register of a known Float class or last assigned by Float arithmetic?"
	| reg def |
	(slotKind at: slotIndex) = OilDescConst ifTrue: [^self isFloatHandle: (slotValue at: slotIndex)].
	(slotKind at: slotIndex) = OilDescReg ifFalse: [^false].
	reg := slotValue at: slotIndex.
	(self isFloatClass: (knownClass at: reg)) ifTrue: [^true].
	def := lastDefIR at: reg.
	^def >= 0 and: [def < irIndex and: [(self opcodeAt: def) between: OilAddFloat and: OilDivFloat]]! !

!OilBaseCompiler methodsFor: 'float arithmetic' stamp: 'cb 10/25/2026 02:00'!
isFloatClass: classHandle
	"Is classHandle SmallFloat64 or BoxedFloat64?"
	classHandle = 0 ifTrue: [^false].
	^self
		cCode: [(objectMemory classTagForClass: classHandle) = objectMemory smallFloatTag
				or: [(objectMemory classTagForClass: classHandle) = ClassFloatCompactIndex]]
		inSmalltalk: [(self objectFor: classHandle) includesBehavior: Float]! !

!OilBaseCompiler methodsFor: 'float arithmetic' stamp: 'cb 10/25/2026 02:00'!
isFloatHandle: aHandle
	^self isFloatClass: (self classHandleOf: aHandle)! !

!OilBaseCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
genClassOf: slotIndex
	"#class: fold when the receiver's class is known."
	| classHandle |
	classHandle := self staticClassOfSlot: slotIndex.
	classHandle = 0 ifTrue: [^false].
	simStackTop := slotIndex - 1.
	self push: OilDescConst value: classHandle.
	^true! !

!OilBaseCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
genSend: selector numArgs: numArgs super: isSuper frame: frameIndex
	<inline: false>
	"A message send: inline a virtual block's evaluation, a quick method, an intrinsic primitive or the method
	 itself when the receiver's class is known (constant, established fact, or monomorphic type feedback guarded
	 by OilGuardClass); otherwise emit a call."
	| rcvrSlot descKind rcvrClass guard method prim |
	rcvrSlot := simStackTop - numArgs.
	descKind := slotKind at: rcvrSlot.
	(descKind = OilDescBlock and: [isSuper not]) ifTrue:
		[((self isValueSelector: selector numArgs: numArgs)
		  and: [self inlineBlock: (slotValue at: rcvrSlot) receiver: rcvrSlot numArgs: numArgs]) ifTrue: [^self].
		 ^self genCall: selector numArgs: numArgs receiver: rcvrSlot super: false].
	(isSuper not and: [selector = bitXorSelector and: [numArgs = 1
	 and: [self canInlineSmallIntegerOpOn: rcvrSlot arg: rcvrSlot + 1]]]) ifTrue:
		[(self genBitOp: OilXorTagged) ifTrue: [^self]].
	guard := false.
	isSuper
		ifTrue: [rcvrClass := self superclassHandleOfMethodClassOf: (frameMethod at: (frameHome at: frameIndex))]
		ifFalse:
			[rcvrClass := self staticClassOfSlot: rcvrSlot.
			 rcvrClass = 0 ifTrue:
				[rcvrClass := self profiledClassAt: currentPC.
				 guard := rcvrClass ~= 0]].
	(rcvrClass = 0 or: [self isContextClass: rcvrClass]) ifTrue:
		[^self genCall: selector numArgs: numArgs receiver: rcvrSlot super: isSuper].
	method := self lookup: selector inClass: rcvrClass.
	method = 0 ifTrue: [^self genCall: selector numArgs: numArgs receiver: rcvrSlot super: isSuper].
	prim := self oilPrimitiveIndexOf: method.
	(self oilIsQuickPrimitiveIndex: prim) ifTrue:
		[guard ifTrue: [self emitGuardOn: (self regForSlot: rcvrSlot) class: rcvrClass].
		 ^self genQuickMethod: prim receiver: rcvrSlot numArgs: numArgs].
	(self genScanIntrinsic: method selector: selector receiver: rcvrSlot numArgs: numArgs class: rcvrClass guard: guard) ifTrue:
		[^self].
	prim ~= 0 ifTrue:
		[(self canInlineIntrinsic: prim class: rcvrClass numArgs: numArgs) ifTrue:
			[guard ifTrue: [self emitGuardOn: (self regForSlot: rcvrSlot) class: rcvrClass].
			 self genIntrinsic: prim selector: selector receiver: rcvrSlot numArgs: numArgs bytes: (self oilInstSpecOfClass: rcvrClass) >= 16.
			 ^self].
		 ^self genCall: selector numArgs: numArgs receiver: rcvrSlot super: isSuper].
	(self shouldInline: method selector: selector numArgs: numArgs receiver: rcvrSlot) ifTrue:
		[(self inlineMethod: method receiver: rcvrSlot numArgs: numArgs class: rcvrClass guard: guard) ifTrue:
			[^self]].
	self genCall: selector numArgs: numArgs receiver: rcvrSlot super: isSuper! !

!OilBaseCompiler methodsFor: 'sends' stamp: 'cb 10/25/2026 03:00'!
isContextClass: classHandle
	"Is classHandle Context?  The sender, pc and stackp of a context married to a stack frame are not in its slots (the
	 interpreter and the baseline JIT map them from the frame), so Oil neither compiles nor inlines methods of contexts."
	classHandle = 0 ifTrue: [^false].
	^self
		cCode: [(objectMemory classTagForClass: classHandle) = ClassMethodContextCompactIndex]
		inSmalltalk: [(self objectFor: classHandle) == Context]! !

!OilBaseCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
staticClassOfSlot: slotIndex
	| descKind |
	descKind := slotKind at: slotIndex.
	descKind = OilDescConst ifTrue: [^self classHandleOf: (slotValue at: slotIndex)].
	descKind = OilDescReg ifTrue: [^knownClass at: (slotValue at: slotIndex)].
	^0! !

!OilBaseCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
isValueSelector: selector numArgs: numArgs
	^numArgs <= 4 and: [(valueSelectors at: numArgs) = selector]! !

!OilBaseCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
isIteratorSelector: selector
	^self includes: selector in: iteratorSelectors count: numIteratorSelectors! !

!OilBaseCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
isColdSelector: selector
	^self includes: selector in: coldSelectors count: numColdSelectors! !

!OilBaseCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
shouldInline: method selector: selector numArgs: numArgs receiver: rcvrSlot
	"Inlining policy (see the class comment)."
	| depth size takesBlock |
	depth := (frameDepth at: currentFrame) + 1.
	depth > OilMaxInlineDepth ifTrue: [^false].
	(self isColdSelector: selector) ifTrue: [^false].
	(self isNoInline: method) ifTrue: [^false].
	(self isMethodOnInlineStack: method) ifTrue: [^false].
	size := (self oilEndPCOf: method) - (self startPCOf: method) + 1.
	irInstCount + size > irBudget ifTrue: [^false].
	takesBlock := false.
	rcvrSlot + 1 to: rcvrSlot + numArgs do: [:slotIndex| (slotKind at: slotIndex) = OilDescBlock ifTrue: [takesBlock := true]].
	(takesBlock or: [self isIteratorSelector: selector]) ifTrue:
		[^size <= OilMaxIteratorBytes].
	size <= OilAccessorBytes ifTrue: [^true].
	"A method with Oil code of its own: calling it runs that code, while an inlined copy would lack the type feedback of
	 its baseline inline caches (gone with its baseline code), so its own sends would not be inlined."
	(self hasOilCode: method) ifTrue: [^false].
	"A send in a loop (of this frame or of a frame it is inlined in) is hot: inline larger methods deeper."
	(size <= OilMaxIteratorBytes
	 and: [depth <= OilMediumMethodDepth
	 and: [self isInLoopFrame: currentFrame pc: currentPC]]) ifTrue: [^true].
	size <= OilMediumMethodBytes ifTrue: [^depth <= OilMediumMethodDepth].
	^depth <= OilLargeMethodDepth and: [size <= OilMaxIteratorBytes]! !

!OilBaseCompiler methodsFor: 'inlining' stamp: 'cb 10/24/2026 17:00'!
isInLoopFrame: frameIndex pc: targetPC
	"Is targetPC of frameIndex inside a loop of its method, or is frameIndex inlined (transitively) from a pc inside a loop?"
	| walkFrame walkPC |
	walkFrame := frameIndex.
	walkPC := targetPC.
	[walkFrame >= 0] whileTrue:
		[(pcLoop at: (self pcMapIndex: walkPC frame: walkFrame)) ~= 0 ifTrue: [^true].
		 walkPC := frameCallPC at: walkFrame.
		 walkFrame := frameParent at: walkFrame].
	^false! !

!OilBaseCompiler methodsFor: 'inlining' stamp: 'cb 10/24/2026 18:30'!
isNeverSentAt: pc
	"Has the method of the current frame machine code whose send at pc was never executed (an unlinked inline cache)?"
	^self
		cCode: [cogit oilSendSiteNeverSentAt: pc in: (frameMethod at: currentFrame)]
		inSmalltalk: [typeFeedback notNil and: [(typeFeedback hasSiteAt: pc in: (frameMethod at: currentFrame)) not]]! !

!OilBaseCompiler methodsFor: 'inlining' stamp: 'cb 10/24/2026 18:30'!
genUncommonTrapForSendAt: rcvrSlot numArgs: numArgs
	"A send in an inlined frame that the back end cannot encode, but that never executed: instead of a call, deoptimize
	 there (an uncommon trap: the interpreter then performs the send; this counts as a deoptimization).  The send's
	 result is an unknown own register (the code after the trap is unreachable)."
	rcvrSlot to: rcvrSlot + numArgs do: [:slotIndex| self materializeSlot: slotIndex].
	failed ifTrue: [^self].
	self emitOp: OilTrap a: 0 b: 0 c: (self recordSite: OilSiteCall).
	simStackTop := rcvrSlot - 1.
	self pushResultOf: OilConstTagged b: 0 c: 1 site: 0! !

!OilBaseCompiler methodsFor: 'inlining' stamp: 'cb 10/24/2026 18:00'!
hasOilCode: aMethod
	^self
		cCode: [cogit oilMethodHasOilCode: aMethod]
		inSmalltalk: [false]! !

!OilBaseCompiler methodsFor: 'inlining' stamp: 'cb 10/24/2026 17:30'!
isNoInline: aMethod
	^self includes: aMethod in: oilNoInline count: oilNumNoInline! !

!OilBaseCompiler methodsFor: 'inlining' stamp: 'cb 10/24/2026 17:30'!
isEncodableCall: selector super: isSuper
	"Can the back end emit a send of selector?  Inline caches hold the index of their selector in the literals of the
	 method (the root), among the special selectors or in the Oil selector table (which this adds selector to, see
	 ProfilingCogit>>oilExtraSelectorIndexOf:add:), and a super send binds to the root method's class."
	isSuper ifTrue: [^currentFrame = 0].
	0 to: 31 do:
		[:k| (self specialSelectorHandle: k) = selector ifTrue: [^true]].
	0 to: (self cCode: [objectMemory literalCountOf: rootMethod] inSmalltalk: [rootMethod numLiterals]) - 1 do:
		[:k|
		(self cCode: [coInterpreter literal: k ofMethod: rootMethod]
			inSmalltalk: [self handleFor: (rootMethod literalAt: k + 1)]) = selector ifTrue: [^true]].
	^self cCode: [(cogit oilExtraSelectorIndexOf: selector add: true) ~= OilNoLink] inSmalltalk: [false]! !

!OilBaseCompiler methodsFor: 'inlining' stamp: 'cb 10/24/2026 17:30'!
refuseInliningOfFrameOf: frameIndex
	"Frame frameIndex (inlined) needs something the back end cannot do: a send of a selector that is not among the root
	 method's literals, a super send, or a closure whose outerContext is frameIndex's context.  Compile again without inlining
	 the method that the root sends and that leads to frameIndex (its send is encodable)."
	| walkFrame |
	walkFrame := frameIndex.
	[walkFrame > 0 and: [(frameParent at: walkFrame) > 0]] whileTrue:
		[walkFrame := frameParent at: walkFrame].
	(walkFrame <= 0 or: [(frameIsBlock at: walkFrame) or: [oilNumNoInline >= 16]]) ifTrue:
		[^self abortCompilation: OilFailBackend].
	oilNoInline at: oilNumNoInline put: (frameMethod at: walkFrame).
	oilNumNoInline := oilNumNoInline + 1.
	oilRestartNoInline := true.
	needsRestart := true.
	failed := true! !

!OilBaseCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
genCall: selector numArgs: numArgs receiver: rcvrSlot super: isSuper
	"A non-inlined send: receiver and arguments in consecutive registers rcvrSlot..rcvrSlot+numArgs, result in rcvrSlot.
	 OilCall0 [Op|Dest|Rcvr|0], OilCall1 [Op|Dest|Rcvr|Arg0], OilCallN/OilCallSuper [Op|Dest|Rcvr|NumArgs];
	 then the 64-bit selector; then, for OilCallN/OilCallSuper, the packed argument registers."
	| instIndex |
	(self isEncodableCall: selector super: isSuper) ifFalse:
		[(currentFrame > 0 and: [self isNeverSentAt: currentPC]) ifTrue:
			[^self genUncommonTrapForSendAt: rcvrSlot numArgs: numArgs].
		 ^self refuseInliningOfFrameOf: currentFrame].
	rcvrSlot to: rcvrSlot + numArgs do: [:slotIndex| self materializeSlot: slotIndex].
	failed ifTrue: [^self].
	self recordSite: OilSiteCall.
	(isSuper or: [numArgs >= 2])
		ifTrue:
			[instIndex := self emitOp: (isSuper ifTrue: [OilCallSuper] ifFalse: [OilCallN]) a: rcvrSlot b: rcvrSlot c: numArgs.
			 self emit64: selector.
			 self emitPackedArgs: rcvrSlot + 1 count: numArgs]
		ifFalse:
			[instIndex := self emitOp: (numArgs = 0 ifTrue: [OilCall0] ifFalse: [OilCall1]) a: rcvrSlot b: rcvrSlot c: (numArgs = 0 ifTrue: [0] ifFalse: [rcvrSlot + 1]).
			 self emit64: selector].
	simStackTop := rcvrSlot.
	self setOwn: rcvrSlot.
	self noteDef: rcvrSlot at: instIndex! !

!OilBaseCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
genQuickMethod: prim receiver: rcvrSlot numArgs: numArgs
	"Quick primitives: 256 ^self, 257 ^true, 258 ^false, 259 ^nil, 260-263 ^-1/0/1/2, 264-519 ^instVar (prim - 264)."
	| descKind slotVal rcvrReg |
	descKind := slotKind at: rcvrSlot.
	slotVal := slotValue at: rcvrSlot.
	prim = 256 ifTrue:
		[simStackTop := rcvrSlot - 1.
		 ^self push: descKind value: slotVal].
	prim <= 259 ifTrue:
		[simStackTop := rcvrSlot - 1.
		 ^self push: OilDescConst value: (prim = 257 ifTrue: [trueHandle] ifFalse: [prim = 258 ifTrue: [falseHandle] ifFalse: [nilHandle]])].
	prim <= 263 ifTrue:
		[simStackTop := rcvrSlot - 1.
		 ^self push: OilDescConst value: (self handleForSmallInteger: prim - 261)].
	rcvrReg := self regForSlot: rcvrSlot.
	simStackTop := rcvrSlot - 1.
	self pushResultOf: OilLoadField b: rcvrReg c: prim - 264 site: 0! !

!OilBaseCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
canInlineIntrinsic: prim class: cls numArgs: n
	"at: (60), at:put: (61) and size (62) of pointer indexable objects without fixed fields (Array) and of byte objects
	 (ByteArray, ByteString), at: (63) and at:put: (64) of byte strings (Characters), compareWith: (158, the byte
	 comparison of String>>=) of byte objects, == (110), identityHash (75) of non-immediates, Character>>asInteger (171),
	 and ReadStream>>next (65) and WriteStream>>nextPut: (66)."
	| spec |
	prim = 110 ifTrue: [^n = 1].
	spec := self oilInstSpecOfClass: cls.
	((prim = 60 and: [n = 1]) or: [(prim = 61 and: [n = 2]) or: [prim = 62 and: [n = 0]]]) ifTrue:
		[^spec = 2 or: [spec >= 16 and: [spec <= 23]]].
	((prim = 63 and: [n = 1]) or: [(prim = 64 and: [n = 2]) or: [prim = 158 and: [n = 1]]]) ifTrue:
		[^spec >= 16 and: [spec <= 23]].
	(prim = 171 and: [n = 0]) ifTrue: "Character>>asInteger / value (immediate format)"
		[^spec = 7].
	(prim = 75 and: [n = 0]) ifTrue: "identityHash of a non-immediate (immediates override it)"
		[^spec ~= 7].
	((prim = 65 and: [n = 0]) or: [prim = 66 and: [n = 1]]) ifTrue: "ReadStream>>next, WriteStream>>nextPut: (fixed pointer fields)"
		[^spec = 1].
	^false! !

!OilBaseCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
genIntrinsic: prim selector: selector receiver: rcvrSlot numArgs: numArgs bytes: isBytes
	<inline: false>
	| arrayReg indexReg valReg limitReg instIndex descKind slotVal |
	prim = 110 ifTrue:
		[^self genCompare: OilCondIdentical identity: true frame: currentFrame next: -1].
	prim = 75 ifTrue: "the hash in the header (no deopt site: the back end falls back to the send if there is none yet)"
		[arrayReg := self regForSlot: rcvrSlot.
		 simStackTop := rcvrSlot - 1.
		 self pushResultOf: OilIdentityHash b: arrayReg c: 0 site: 0.
		 self emit64: selector.
		 knownClass at: simStackTop put: smallIntegerClassHandle.
		 ^self].
	(prim = 65 or: [prim = 66]) ifTrue: "the back end falls back to the send itself, so no deopt site"
		[rcvrSlot to: rcvrSlot + numArgs do: [:slotIndex| self materializeSlot: slotIndex].
		 simStackTop := rcvrSlot - 1.
		 self pushResultOf: (prim = 65 ifTrue: [OilStreamNext] ifFalse: [OilStreamNextPut])
			b: rcvrSlot c: (prim = 65 ifTrue: [0] ifFalse: [rcvrSlot + 1]) site: 0.
		 self emit64: (self specialSelectorHandle: (prim = 65 ifTrue: [19] ifFalse: [20])).
		 ^self].
	arrayReg := self regForSlot: rcvrSlot.
	prim = 171 ifTrue:
		[simStackTop := rcvrSlot - 1.
		 self pushResultOf: OilCharValue b: arrayReg c: 0 site: 0.
		 knownClass at: simStackTop put: smallIntegerClassHandle.
		 ^self].
	prim = 158 ifTrue: "rcvr compareWith: arg, both byte objects: the first byte difference, or the size difference"
		[indexReg := self regForSlot: rcvrSlot + 1.
		 simStackTop := rcvrSlot - 1.
		 self pushSmallIntegerResultOf: OilCompareBytes b: arrayReg c: indexReg.
		 ^self].
	prim = 62 ifTrue:
		[simStackTop := rcvrSlot - 1.
		 self pushResultOf: (isBytes ifTrue: [OilLoadByteSize] ifFalse: [OilLoadSize]) b: arrayReg c: 0 site: 0.
		 knownClass at: simStackTop put: smallIntegerClassHandle.
		 ^self].
	indexReg := self regForSlot: rcvrSlot + 1.
	(prim = 61 or: [prim = 64]) ifTrue:
		[descKind := slotKind at: rcvrSlot + 2.
		 slotVal := slotValue at: rcvrSlot + 2.
		 valReg := self regForSlot: rcvrSlot + 2].
	limitReg := rcvrSlot + numArgs + 1.
	instIndex := self emitOp: (isBytes ifTrue: [OilLoadByteSize] ifFalse: [OilLoadSize]) a: limitReg b: arrayReg c: 0.
	self noteDef: limitReg at: instIndex.
	self emitOp: OilCheckBounds a: indexReg b: limitReg c: (self recordSite: OilSiteBounds).
	knownClass at: indexReg put: smallIntegerClassHandle.
	simStackTop := rcvrSlot - 1.
	(prim = 60 or: [prim = 63]) ifTrue:
		[self pushResultOf: (isBytes
								ifTrue: [prim = 63 ifTrue: [OilLoadChar] ifFalse: [OilLoadByte]]
								ifFalse: [OilLoadElement])
			b: arrayReg c: indexReg site: 0.
		 (isBytes and: [prim = 60]) ifTrue: [knownClass at: simStackTop put: smallIntegerClassHandle].
		 ^self].
	self recordSite: OilSiteStore.
	self emitOp: (isBytes
					ifTrue: [prim = 64 ifTrue: [OilStoreChar] ifFalse: [OilStoreByte]]
					ifFalse: [OilStoreElement])
		a: valReg b: arrayReg c: indexReg.
	(descKind = OilDescReg and: [slotVal = (rcvrSlot + 2)])
		ifTrue: [self emitMove: self pushOwnSlot from: valReg]
		ifFalse: [self push: descKind value: slotVal]! !

!OilBaseCompiler methodsFor: 'sends' stamp: 'cb 10/25/2026 03:00'!
genScanIntrinsic: method selector: selector receiver: rcvrSlot numArgs: numArgs class: rcvrClass guard: guard
	"Byte scans the back end compiles to word-at-a-time (8 bytes per iteration) loops, falling back to the send itself on
	 unexpected operands (so they have no deopt site): ByteString class>>indexOfAscii:inString:startingAt: (the search of
	 ReadStream>>upTo: and String>>indexOf: on byte strings; OilIndexOfByte, laid out like OilCallN), and
	 PositionableStream>>skipSeparators of a ReadStream (OilSkipSeparators, laid out like OilCall0).  The image registers the
	 two methods and the stream class (kinds 9 to 11, see registerSelector:kind:).  Answer whether the send was compiled so."
	| opcode instIndex |
	opcode := (method = oilIndexOfAsciiMethod and: [numArgs = 3])
				ifTrue: [OilIndexOfByte]
				ifFalse:
					[(method = oilSkipSeparatorsMethod and: [numArgs = 0 and: [rcvrClass = oilByteStreamClass]])
						ifTrue: [OilSkipSeparators]
						ifFalse: [^false]].
	(method = 0 or: [(self isEncodableCall: selector super: false) not]) ifTrue: [^false].
	guard ifTrue: [self emitGuardOn: (self regForSlot: rcvrSlot) class: rcvrClass].
	rcvrSlot to: rcvrSlot + numArgs do: [:slotIndex| self materializeSlot: slotIndex].
	failed ifTrue: [^true].
	instIndex := self emitOp: opcode a: rcvrSlot b: rcvrSlot c: numArgs.
	self emit64: selector.
	opcode = OilIndexOfByte ifTrue: [self emitPackedArgs: rcvrSlot + 1 count: numArgs].
	simStackTop := rcvrSlot.
	self setOwn: rcvrSlot.
	self noteDef: rcvrSlot at: instIndex.
	^true! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
genCompare: cond identity: isIdentity frame: frameIndex next: nextPC
	<inline: false>
	"Tagged SmallInteger comparison (or identity comparison).  Folds constants; fuses with a following
	 conditional jump (OilCmpTagged/OilCmpImmTagged + OilBranchTrue/False on the flags, r255);
	 otherwise materializes true/false.  Answer the pc to continue at."
	| slotA slotB scratchA scratchB kindA valA kindB valB condCode regA regB useImm immVal brTag brTarget brNext destSlot resultBool |
	slotA := scratchA := simStackTop - 1.
	slotB := scratchB := simStackTop.
	kindA := slotKind at: slotA. valA := slotValue at: slotA.
	kindB := slotKind at: slotB. valB := slotValue at: slotB.
	condCode := cond.
	(isIdentity and: [(kindA = OilDescBlock or: [kindA = OilDescTempVector]) or: [kindB = OilDescBlock or: [kindB = OilDescTempVector]]]) ifTrue:
		[self requireEagerClosures.
		 ^nextPC].
	(kindA = OilDescConst and: [kindB = OilDescConst]) ifTrue:
		[resultBool := isIdentity
			ifTrue: [(valA = valB) = (condCode = OilCondIdentical)]
			ifFalse: [self compareSmallInteger: (self smallIntegerValueOf: valA) with: (self smallIntegerValueOf: valB) cond: condCode].
		 simStackTop := slotA - 1.
		 self push: OilDescConst value: (resultBool ifTrue: [trueHandle] ifFalse: [falseHandle]).
		 ^nextPC].
	(isIdentity not and: [kindA = OilDescConst and: [kindB ~= OilDescConst]]) ifTrue:
		["constant on the left: swap the operands and reverse the condition"
		 | tempKind tempVal |
		 tempKind := kindA. tempVal := valA. kindA := kindB. valA := valB. kindB := tempKind. valB := tempVal.
		 scratchA := slotB. scratchB := slotA.
		 condCode := self reversedCondition: condCode].
	useImm := isIdentity not
				and: [kindB = OilDescConst
				and: [(self smallIntegerValueOf: valB) between: -128 and: 127]].
	regA := self regForKind: kindA value: valA scratch: scratchA.
	useImm
		ifTrue: [immVal := (self smallIntegerValueOf: valB) bitAnd: 255]
		ifFalse: [regB := self regForKind: kindB value: valB scratch: scratchB].
	simStackTop := slotA - 1.
	(nextPC >= 0 and: [self canFuseBranchAt: nextPC frame: frameIndex]) ifTrue:
		[brTag := opcodeTag. brTarget := oilTargetPC. brNext := oilNextPC.
		 self flushFrame: frameIndex.
		 self emitCompare: condCode reg: regA reg: regB imm: immVal useImm: useImm identity: isIdentity.
		 self emitBranch: (brTag = OilTagJumpTrue ifTrue: [OilBranchTrue] ifFalse: [OilBranchFalse])
			cond: OilFlagsReg to: brTarget frame: frameIndex.
		 ^brNext].
	"Not followed by a conditional jump: answer a lazy comparison result (e.g. the result of an inlined block
	 that the caller tests).  It is compared and branched on when consumed by a jump, materialized as
	 true/false otherwise, or as soon as anything else is emitted."
	numConds >= OilMaxConds ifTrue:
		[^self abortCompilation: OilFailTooManyVirtualObjects].
	"The comparison is emitted later, when consumed, but it must deoptimize to the state at this bytecode:
	 record its deopt site now, its IR index is set when the comparison is emitted (see emitCompare:...)"
	isIdentity
		ifTrue: [condSite at: numConds put: -1]
		ifFalse:
			[| siteIndex |
			 siteIndex := self recordSite: OilSiteArith.
			 failed ifTrue: [^nextPC].
			 siteIR at: siteIndex put: -1.
			 condSite at: numConds put: siteIndex].
	condCond at: numConds put: condCode.
	condRA at: numConds put: regA.
	condRB at: numConds put: (useImm ifTrue: [0] ifFalse: [regB]).
	condImm at: numConds put: (useImm ifTrue: [immVal] ifFalse: [0]).
	condUseImm at: numConds put: useImm.
	condIdentity at: numConds put: isIdentity.
	condFrame at: numConds put: currentFrame.
	condPC at: numConds put: currentPC.
	destSlot := self push: OilDescCond value: numConds.
	pendingCondSlot := destSlot.
	pendingCondIndex := numConds.
	numConds := numConds + 1.
	^nextPC! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
emitCondCompare: condIndex
	"Emit the comparison of the lazy comparison result condIndex (its deopt site is the comparison's bytecode)."
	| savedPC savedFrame savedCond |
	savedPC := currentPC.
	savedFrame := currentFrame.
	currentPC := condPC at: condIndex.
	currentFrame := condFrame at: condIndex.
	savedCond := emittingCond.
	emittingCond := condIndex.
	self emitCompare: (condCond at: condIndex) reg: (condRA at: condIndex) reg: (condRB at: condIndex)
		imm: (condImm at: condIndex) useImm: (condUseImm at: condIndex) identity: (condIdentity at: condIndex).
	emittingCond := savedCond.
	currentPC := savedPC.
	currentFrame := savedFrame! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
emitCond: condIndex booleanInto: destReg
	<inline: false>
	"Materialize the lazy comparison result condIndex as true or false in register destReg."
	| branchFalseJump exitJump |
	pendingCondIndex = condIndex ifTrue: [pendingCondSlot := -1].
	self emitCondCompare: condIndex.
	branchFalseJump := self emitOp: OilBranchFalse a: OilFlagsReg imm16: 0.
	self emitConst: trueHandle into: destReg.
	exitJump := self emitOp: OilJump a: 0 imm16: 0.
	self patchBranch: branchFalseJump to: irIndex.
	self emitConst: falseHandle into: destReg.
	self patchBranch: exitJump to: irIndex.
	lastLabelIR := irIndex.
	knownClass at: destReg put: 0! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
materializePendingCond
	<inline: false>
	| slotIndex |
	slotIndex := pendingCondSlot.
	pendingCondSlot := -1.
	(slotIndex <= simStackTop and: [(slotKind at: slotIndex) = OilDescCond and: [(slotValue at: slotIndex) = pendingCondIndex]]) ifTrue:
		[self emitCond: pendingCondIndex booleanInto: slotIndex.
		 self setOwn: slotIndex]! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
reversedCondition: condCode
	"The condition condCode with its operands swapped: x < y iff y > x."
	condCode = OilCondLt ifTrue: [^OilCondGt].
	condCode = OilCondGt ifTrue: [^OilCondLt].
	condCode = OilCondLe ifTrue: [^OilCondGe].
	condCode = OilCondGe ifTrue: [^OilCondLe].
	^condCode! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
canFuseBranchAt: targetPC frame: frameIndex
	"Is the instruction at targetPC (in frame frameIndex) a conditional jump that is not itself a branch target?"
	targetPC > (frameEndPC at: frameIndex) ifTrue: [^false].
	(pcTarget at: (self pcMapIndex: targetPC frame: frameIndex)) ~= 0 ifTrue: [^false].
	self setScanMethod: (frameMethod at: frameIndex).
	self decodeAt: targetPC.
	^opcodeTag = OilTagJumpTrue or: [opcodeTag = OilTagJumpFalse]! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
emitCompare: condCode reg: regA reg: regB imm: immVal useImm: useImm identity: isIdentity
	isIdentity ifFalse:
		[emittingCond >= 0
			ifTrue: [self useCondSite: (condSite at: emittingCond)]
			ifFalse: [self recordSite: OilSiteArith]].
	useImm
		ifTrue: [self emitOp: OilCmpImmTagged a: condCode b: regA c: immVal]
		ifFalse: [self emitOp: OilCmpTagged a: condCode b: regA c: regB]! !

!OilBaseCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/24/2026 14:00'!
useCondSite: siteIndex
	"The comparison of a lazy comparison result is about to be emitted: bind its deopt site, recorded when the
	 comparison was translated, to the instruction.  If it was already bound (the comparison is emitted again,
	 e.g. materialized on two paths) clone the site, sharing its recorded state."
	| newSiteIndex |
	siteIndex < 0 ifTrue: [^self].
	"Another pending lazy comparison would be materialized by the next emitOp:, shifting the IR index."
	(pendingCondSlot >= 0 and: [pendingCondIndex ~= emittingCond]) ifTrue:
		[self materializePendingCond].
	(siteIR at: siteIndex) = -1 ifTrue:
		[siteIR at: siteIndex put: irIndex.
		 ^self].
	newSiteIndex := numSites.
	newSiteIndex >= OilMaxSites ifTrue:
		[^self abortCompilation: OilFailTooManySites].
	siteIR at: newSiteIndex put: irIndex.
	siteFrame at: newSiteIndex put: (siteFrame at: siteIndex).
	sitePC at: newSiteIndex put: (sitePC at: siteIndex).
	siteKind at: newSiteIndex put: (siteKind at: siteIndex).
	siteSnapBase at: newSiteIndex put: (siteSnapBase at: siteIndex).
	siteSnapTop at: newSiteIndex put: (siteSnapTop at: siteIndex).
	siteSnapHigh at: newSiteIndex put: (siteSnapHigh at: siteIndex).
	numSites := newSiteIndex + 1! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
compareSmallInteger: val1 with: val2 cond: condCode
	condCode = OilCondLt ifTrue: [^val1 < val2].
	condCode = OilCondGt ifTrue: [^val1 > val2].
	condCode = OilCondLe ifTrue: [^val1 <= val2].
	condCode = OilCondGe ifTrue: [^val1 >= val2].
	condCode = OilCondEq ifTrue: [^val1 = val2].
	^val1 ~= val2! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
genArith: selectorIndex
	<inline: false>
	"Special selector arithmetic on (speculated) SmallIntegers: + - * \\ bitShift: // bitAnd: bitOr:.
	 Answer false if not inlinable (the caller then emits an ordinary send)."
	| rcvrSlot argSlot |
	rcvrSlot := simStackTop - 1.
	argSlot := simStackTop.
	((slotKind at: rcvrSlot) = OilDescConst and: [(slotKind at: argSlot) = OilDescConst]) ifTrue:
		[(self foldArith: selectorIndex) ifTrue: [^true]].
	selectorIndex = 0 ifTrue: [^self genAdd].
	selectorIndex = 1 ifTrue: [^self genSub].
	selectorIndex = 8 ifTrue: [^self genMul].
	selectorIndex = 10 ifTrue: [^self genMod].
	selectorIndex = 12 ifTrue: [^self genBitShift].
	selectorIndex = 13 ifTrue: [^self genDiv].
	selectorIndex = 14 ifTrue: [^self genBitOp: OilAndTagged].
	selectorIndex = 15 ifTrue: [^self genBitOp: OilOrTagged].
	^false! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
foldArith: selectorIndex
	"Constant fold SmallInteger arithmetic when the result is a SmallInteger."
	| rcvrSlot val1 val2 resultVal |
	rcvrSlot := simStackTop - 1.
	val1 := self smallIntegerValueOf: (slotValue at: rcvrSlot).
	val2 := self smallIntegerValueOf: (slotValue at: simStackTop).
	resultVal := selectorIndex caseOf: {
		[0] -> [val1 + val2].
		[1] -> [val1 - val2].
		[8] -> [val1 * val2].
		[10] -> [val2 = 0 ifTrue: [^false]. val1 \\ val2].
		[12] -> [(val2 between: -64 and: 64) ifFalse: [^false]. val1 bitShift: val2].
		[13] -> [val2 = 0 ifTrue: [^false]. val1 // val2].
		[14] -> [val1 bitAnd: val2].
		[15] -> [val1 bitOr: val2].
		[18] -> [val1 bitXor: val2] }
		otherwise: [^false].
	(self isSmallIntegerValue: resultVal) ifFalse: [^false].
	simStackTop := rcvrSlot - 1.
	self push: OilDescConst value: (self handleForSmallInteger: resultVal).
	^true! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
genAdd
	| rcvrSlot argSlot |
	rcvrSlot := simStackTop - 1.
	argSlot := simStackTop.
	(slotKind at: argSlot) = OilDescConst ifTrue:
		[^self genAddConstant: (self smallIntegerValueOf: (slotValue at: argSlot)) to: rcvrSlot result: rcvrSlot].
	(slotKind at: rcvrSlot) = OilDescConst ifTrue: "commutative: c + x"
		[^self genAddConstant: (self smallIntegerValueOf: (slotValue at: rcvrSlot)) to: argSlot result: rcvrSlot].
	^self genBinaryTagged: OilAddTagged! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
genSub
	| argSlot |
	argSlot := simStackTop.
	(slotKind at: argSlot) = OilDescConst ifTrue:
		[^self genAddConstant: (self smallIntegerValueOf: (slotValue at: argSlot)) negated to: argSlot - 1 result: argSlot - 1].
	^self genBinaryTagged: OilSubTagged! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 19:20'!
genBinaryTagged: opcode
	"Dest := Src1 op Src2 on tagged SmallIntegers (implicit tag/overflow checks, deopt on failure)."
	| rcvrSlot argSlot regA regB |
	rcvrSlot := simStackTop - 1.
	argSlot := simStackTop.
	regA := self regForSlot: rcvrSlot.
	regB := self regForSlot: argSlot.
	simStackTop := rcvrSlot - 1.
	^self pushSmallIntegerResultOf: opcode b: regA c: regB! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
genAddConstant: constantVal to: operandSlot result: resultSlot
	"x + c with on-the-fly reduction: x + 0 => x; if x = y + c1 (an affine fact still valid) then
	 x + c => y + (c1 + c), so (i - 1) + 1 => i and (i + 1) - 1 => i (no instruction) and (x + c1) - c2 => x + (c1 - c2).
	 Tagged: Tagged(x) + 8c, emitted as OilAddImmTagged when c fits 8 signed bits."
	| descKind slotVal operandReg baseReg totalOffset destReg instIndex scratchReg |
	descKind := slotKind at: operandSlot.
	slotVal := slotValue at: operandSlot.
	constantVal = 0 ifTrue:
		[simStackTop := resultSlot - 1.
		 self push: descKind value: slotVal.
		 ^true].
	operandReg := self regForSlot: operandSlot.
	baseReg := operandReg.
	totalOffset := constantVal.
	((affineBase at: operandReg) >= 0 and: [(affineVersion at: operandReg) = (regVersion at: (affineBase at: operandReg))]) ifTrue:
		[baseReg := affineBase at: operandReg.
		 totalOffset := (affineConst at: operandReg) + constantVal.
		 (operandReg >= resultSlot and: [operandReg <= simStackTop]) ifTrue: "its producer is now dead"
			[self retractIfDeadDefinitionOf: operandReg]].
	simStackTop := resultSlot - 1.
	totalOffset = 0 ifTrue:
		[self push: OilDescReg value: baseReg.
		 ^true].
	destReg := self pushOwnSlot.
	(totalOffset between: -128 and: 127)
		ifTrue:
			[self recordSite: OilSiteArith.
			 instIndex := self emitOp: OilAddImmTagged a: destReg b: baseReg c: (totalOffset bitAnd: 255)]
		ifFalse:
			[scratchReg := operandSlot + 1.
			 self emitConst: (self handleForSmallInteger: totalOffset) into: scratchReg.
			 self recordSite: OilSiteArith.
			 instIndex := self emitOp: OilAddTagged a: destReg b: baseReg c: scratchReg].
	self noteDef: destReg at: instIndex.
	affineBase at: destReg put: baseReg.
	affineConst at: destReg put: totalOffset.
	affineVersion at: destReg put: (regVersion at: baseReg).
	knownClass at: destReg put: smallIntegerClassHandle.
	^true! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
constantPowerOfTwo: number
	"Answer k if number = 2^k (k >= 0), else -1."
	| power |
	number <= 0 ifTrue: [^-1].
	(number bitAnd: number - 1) = 0 ifFalse: [^-1].
	power := 0.
	[(1 bitShift: power) < number] whileTrue: [power := power + 1].
	^power! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
replaceOperandsBy: descKind value: descVal
	"Pop receiver and argument, push (descKind, descVal)."
	simStackTop := simStackTop - 2.
	self push: descKind value: descVal.
	^true! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
emitShift: shiftCount of: srcReg into: destReg
	"OilShiftTagged: shiftCount > 0 arithmetic right shift (exact floor division by 2^k: sarq 3+k, shlq 3, orq 1);
	 shiftCount < 0 left shift by -shiftCount (multiplication by 2^-k, overflow checked)."
	| instIndex |
	self recordSite: OilSiteArith.
	instIndex := self emitOp: OilShiftTagged a: destReg b: srcReg c: (shiftCount bitAnd: 255).
	self noteDef: destReg at: instIndex.
	knownClass at: destReg put: smallIntegerClassHandle! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 19:20'!
genMul
	"x * 1 => x; x * 0 => 0 (x known SmallInteger); x * 2^k => x << k; x * (2^k + 1) => (x << k) + x (e.g. x * 9);
	 x * (2^k - 1) => (x << k) - x (e.g. x * 31, hash codes).  Otherwise an ordinary send."
	| rcvrSlot argSlot operandSlot constantVal power srcReg scratchReg |
	rcvrSlot := simStackTop - 1.
	argSlot := simStackTop.
	(slotKind at: argSlot) = OilDescConst
		ifTrue: [operandSlot := rcvrSlot. constantVal := self smallIntegerValueOf: (slotValue at: argSlot)]
		ifFalse:
			[(slotKind at: rcvrSlot) = OilDescConst ifFalse: [^false].
			 operandSlot := argSlot. constantVal := self smallIntegerValueOf: (slotValue at: rcvrSlot)].
	constantVal = 1 ifTrue: [^self replaceOperandsBy: (slotKind at: operandSlot) value: (slotValue at: operandSlot)].
	constantVal = 0 ifTrue:
		[(self isKnownSmallInteger: operandSlot) ifFalse: [^false].
		 ^self replaceOperandsBy: OilDescConst value: (self handleForSmallInteger: 0)].
	constantVal < 0 ifTrue: [^false].
	srcReg := self regForSlot: operandSlot.
	scratchReg := operandSlot = rcvrSlot ifTrue: [argSlot] ifFalse: [rcvrSlot].
	(power := self constantPowerOfTwo: constantVal) > 0 ifTrue:
		[simStackTop := rcvrSlot - 1.
		 ^self pushSmallIntegerResultOf: OilShiftTagged b: srcReg c: (power negated bitAnd: 255)].
	(power := self constantPowerOfTwo: constantVal - 1) > 0 ifTrue:
		[self emitShift: power negated of: srcReg into: scratchReg.
		 simStackTop := rcvrSlot - 1.
		 ^self pushSmallIntegerResultOf: OilAddTagged b: scratchReg c: srcReg].
	(power := self constantPowerOfTwo: constantVal + 1) > 1 ifTrue:
		[self emitShift: power negated of: srcReg into: scratchReg.
		 simStackTop := rcvrSlot - 1.
		 ^self pushSmallIntegerResultOf: OilSubTagged b: scratchReg c: srcReg].
	^false! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 19:20'!
genDiv
	"x // 1 => x; x // 2^k => arithmetic right shift by k (floor division, no idiv)."
	| rcvrSlot argSlot constantVal power srcReg |
	rcvrSlot := simStackTop - 1.
	argSlot := simStackTop.
	(slotKind at: argSlot) = OilDescConst ifFalse: [^false].
	constantVal := self smallIntegerValueOf: (slotValue at: argSlot).
	constantVal = 1 ifTrue: [^self replaceOperandsBy: (slotKind at: rcvrSlot) value: (slotValue at: rcvrSlot)].
	(power := self constantPowerOfTwo: constantVal) > 0 ifFalse: [^false].
	srcReg := self regForSlot: rcvrSlot.
	simStackTop := rcvrSlot - 1.
	^self pushSmallIntegerResultOf: OilShiftTagged b: srcReg c: (power bitAnd: 255)! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 19:20'!
genMod
	"x \\ 2 => OilOddTagged ((x bitAnd: 8) bitOr: 1 on the tagged value: no division, no branch);
	 x \\ 2^k => x bitAnd: 2^k - 1 (floored modulo by a positive power of two);
	 otherwise OilModTagged (a division; deoptimizes on a zero divisor)."
	| rcvrSlot argSlot constantVal power srcReg |
	rcvrSlot := simStackTop - 1.
	argSlot := simStackTop.
	(slotKind at: argSlot) = OilDescConst ifFalse: [^self genBinaryTagged: OilModTagged].
	constantVal := self smallIntegerValueOf: (slotValue at: argSlot).
	constantVal = 0 ifTrue: [^false]. "ZeroDivide: send it"
	(power := self constantPowerOfTwo: constantVal) > 0 ifFalse: [^self genBinaryTagged: OilModTagged].
	srcReg := self regForSlot: rcvrSlot.
	constantVal = 2 ifTrue:
		[simStackTop := rcvrSlot - 1.
		 ^self pushSmallIntegerResultOf: OilOddTagged b: srcReg c: 0].
	self emitConst: (self handleForSmallInteger: constantVal - 1) into: argSlot.
	simStackTop := rcvrSlot - 1.
	^self pushSmallIntegerResultOf: OilAndTagged b: srcReg c: argSlot! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 19:20'!
genBitShift
	"x bitShift: 0 => x; x bitShift: k => OilShiftTagged (left for k > 0, arithmetic right for k < 0)."
	| rcvrSlot argSlot shiftCount srcReg |
	rcvrSlot := simStackTop - 1.
	argSlot := simStackTop.
	(slotKind at: argSlot) = OilDescConst ifFalse: [^false].
	shiftCount := self smallIntegerValueOf: (slotValue at: argSlot).
	shiftCount = 0 ifTrue: [^self replaceOperandsBy: (slotKind at: rcvrSlot) value: (slotValue at: rcvrSlot)].
	(shiftCount between: -60 and: 60) ifFalse: [^false].
	srcReg := self regForSlot: rcvrSlot.
	simStackTop := rcvrSlot - 1.
	^self pushSmallIntegerResultOf: OilShiftTagged b: srcReg c: (shiftCount negated bitAnd: 255)! !

!OilBaseCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
genBitOp: opcode
	"bitAnd:/bitOr:/bitXor: directly on tagged values: (8a+1) & (8b+1) = 8(a&b)+1, (8a+1) | (8b+1) = 8(a|b)+1,
	 so andq/orq need no untagging; xor needs the tag bit restored.
	 Identities: x bitAnd: -1 => x, x bitAnd: 0 => 0 (x known SmallInteger), x bitOr: 0 => x, x bitXor: 0 => x."
	| rcvrSlot argSlot slotA slotB constantVal |
	rcvrSlot := simStackTop - 1.
	argSlot := simStackTop.
	((slotKind at: rcvrSlot) = OilDescConst and: [(slotKind at: argSlot) = OilDescConst]) ifTrue:
		[opcode = OilXorTagged ifTrue: [^self foldArith: 18]].
	slotA := rcvrSlot. slotB := argSlot.
	((slotKind at: rcvrSlot) = OilDescConst and: [(slotKind at: argSlot) ~= OilDescConst]) ifTrue:
		[slotA := argSlot. slotB := rcvrSlot].
	(slotKind at: slotB) = OilDescConst ifTrue:
		[constantVal := self smallIntegerValueOf: (slotValue at: slotB).
		 ((constantVal = 0 and: [opcode ~= OilAndTagged]) or: [constantVal = -1 and: [opcode = OilAndTagged]]) ifTrue:
			[^self replaceOperandsBy: (slotKind at: slotA) value: (slotValue at: slotA)].
		 (constantVal = 0 and: [opcode = OilAndTagged and: [self isKnownSmallInteger: slotA]]) ifTrue:
			[^self replaceOperandsBy: OilDescConst value: (self handleForSmallInteger: 0)]].
	^self genBinaryTagged: opcode! !

!OilBaseCompiler methodsFor: 'inlining' stamp: 'cb 10/24/2026 19:20'!
inlineMethod: aMethod receiver: rcvrReg numArgs: numArgs class: cls guard: guard
	<inline: false>
	"Inline aMethod, sent to the receiver in rcvrReg with its numArgs arguments in the following registers.
	 The send dissolves: the receiver binds to the inlined method's self, the arguments to its argument registers,
	 its temps follow, and its returns leave the result in rcvrReg and jump to the exit label.
	 cls is the receiver class used for lookup; if guard, it is guarded first (OilGuardClass).
	 Answer false (nothing emitted) if aMethod cannot be inlined."
	| frameIndex |
	frameIndex := self newFrameFor: aMethod base: rcvrReg isBlock: false.
	frameIndex < 0 ifTrue: [^false].
	guard ifTrue: [self emitGuardOn: (self regForSlot: rcvrReg) class: cls].
	self stabilizeIncomingSlot: rcvrReg.
	frameSelfKind at: frameIndex put: (slotKind at: rcvrReg).
	frameSelfValue at: frameIndex put: (slotValue at: rcvrReg).
	frameSelfClass at: frameIndex put: cls.
	(slotKind at: rcvrReg) = OilDescReg ifTrue:
		[knownClass at: (slotValue at: rcvrReg) put: cls].
	self bindFrame: frameIndex base: rcvrReg numArgs: numArgs numCopied: 0.
	self translateFrame: frameIndex.
	self exitFrame: frameIndex.
	^true! !

!OilBaseCompiler methodsFor: 'inlining' stamp: 'cb 10/24/2026 19:20'!
inlineBlock: vobjIndex receiver: closureReg numArgs: numArgs
	<inline: false>
	"Inline the evaluation (value, value:, ...) of the virtual closure vobjIndex held in closureReg: no closure is
	 allocated and no block activation happens.  The block's arguments bind in place, its copied values bind
	 to the captured descriptors, its self is its home's self, its local return leaves the result in closureReg
	 and its non-local returns return from its (inlined) home frame."
	| block frameIndex numCopied baseIndex depth |
	block := vobjLiteral at: vobjIndex.
	(self numArgsOf: block) = numArgs ifFalse: [^false].
	depth := (frameDepth at: currentFrame) + 1.
	(depth > OilMaxInlineDepth or: [irInstCount >= irBudget]) ifTrue: [^false].
	(self isFrameActive: (vobjHome at: vobjIndex)) ifFalse: [^false].
	frameIndex := self newFrameFor: block base: closureReg isBlock: true.
	frameIndex < 0 ifTrue: [^false].
	frameHome at: frameIndex put: (vobjHome at: vobjIndex).
	frameSelfKind at: frameIndex put: (vobjSelfKind at: vobjIndex).
	frameSelfValue at: frameIndex put: (vobjSelfValue at: vobjIndex).
	frameSelfClass at: frameIndex put: (vobjSelfClass at: vobjIndex).
	numCopied := vobjNumCopied at: vobjIndex.
	baseIndex := vobjCopiedBase at: vobjIndex.
	0 to: numCopied - 1 do:
		[:copiedIndex| | copiedReg |
		copiedReg := closureReg + numArgs + 1 + copiedIndex.
		slotFlags at: copiedReg put: OilFlagImmutable.
		self setSlot: copiedReg kind: (capturedKind at: baseIndex + copiedIndex) value: (capturedValue at: baseIndex + copiedIndex)].
	self bindFrame: frameIndex base: closureReg numArgs: numArgs numCopied: numCopied.
	self translateFrame: frameIndex.
	self exitFrame: frameIndex.
	^true! !

!OilBaseCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
opcodeAt: index
	^(oilIRBuffer at: index) bitShift: -24! !

!OilBaseCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
fieldAAt: index
	^((oilIRBuffer at: index) bitShift: -16) bitAnd: 255! !

!OilBaseCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
fieldBAt: index
	^((oilIRBuffer at: index) bitShift: -8) bitAnd: 255! !

!OilBaseCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
fieldCAt: index
	^(oilIRBuffer at: index) bitAnd: 255! !

!OilBaseCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
imm16At: index
	^(oilIRBuffer at: index) bitAnd: 16rFFFF! !

!OilBaseCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
signed8: byte
	^byte > 127 ifTrue: [byte - 256] ifFalse: [byte]! !

!OilBaseCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
signed16: word
	^word > 32767 ifTrue: [word - 65536] ifFalse: [word]! !

!OilBaseCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
word64At: index
	"The 64-bit operand stored at index (low word) and index + 1 (high word), sign extended."
	| val64 |
	val64 := (oilIRBuffer at: index) + ((oilIRBuffer at: index + 1) bitShift: 32).
	^self cCode: [val64] inSmalltalk: [val64 >= (1 bitShift: 63) ifTrue: [val64 - (1 bitShift: 64)] ifFalse: [val64]]! !

!OilBaseCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
instructionLengthAt: index
	| op |
	op := self opcodeAt: index.
	(op = OilConst64 or: [op = OilGuardClass or: [op = OilCall0 or: [op = OilCall1 or: [op = OilStreamNext or: [op = OilStreamNextPut
	 or: [op = OilIdentityHash or: [op = OilSkipSeparators]]]]]]]) ifTrue: [^3].
	op = OilMakeClosure ifTrue: [^4].
	(op = OilCallN or: [op = OilCallSuper or: [op = OilIndexOfByte]]) ifTrue: [^3 + ((self fieldCAt: index) + 3 // 4)].
	^1! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
handleFor: anObject
	"In the VM an oop is its own handle.  In the image, SmallIntegers and Characters are tagged exactly like
	 64-bit Spur immediates (8v+1, 8v+2) and other objects get an 8-byte aligned index into a registry."
	| handleVal |
	^self cCode: [anObject] inSmalltalk:
		[anObject isInteger
			ifTrue: [(anObject bitShift: 3) + 1]
			ifFalse:
				[anObject isCharacter
					ifTrue: [(anObject asInteger bitShift: 3) + 2]
					ifFalse:
						[simHandleIndex at: anObject ifAbsent:
							[simHandles addLast: anObject.
							 handleVal := simHandles size bitShift: 3.
							 simHandleIndex at: anObject put: handleVal.
							 handleVal]]]]! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
objectFor: aHandle
	<doNotGenerate>
	(aHandle bitAnd: 7) = 1 ifTrue: [^aHandle bitShift: -3].
	(aHandle bitAnd: 7) = 2 ifTrue: [^Character value: (aHandle bitShift: -3)].
	^simHandles at: (aHandle bitShift: -3)! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
isSmallIntegerHandle: aHandle
	<inline: true>
	^(aHandle bitAnd: 7) = 1! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
smallIntegerValueOf: aHandle
	<inline: true>
	^self cCode: [objectMemory integerValueOf: aHandle] inSmalltalk: [aHandle bitShift: -3]! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
handleForSmallInteger: anInteger
	<inline: true>
	^self cCode: [objectMemory integerObjectOf: anInteger] inSmalltalk: [(anInteger bitShift: 3) + 1]! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
handleForCharacter: anInteger
	<inline: true>
	^self cCode: [objectMemory characterObjectOf: anInteger] inSmalltalk: [(anInteger bitShift: 3) + 2]! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
isSmallIntegerValue: anInteger
	<inline: true>
	^self cCode: [objectMemory isIntegerValue: anInteger] inSmalltalk: [anInteger between: SmallInteger minVal and: SmallInteger maxVal]! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
classHandleOf: aHandle
	^self cCode: [coInterpreter oilApiFetchClassOf: aHandle] inSmalltalk: [self handleFor: (self objectFor: aHandle) class]! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
oilInstSpecOfClass: classHandle
	^self cCode: [coInterpreter oilApiInstSpecOfClass: classHandle] inSmalltalk: [(self objectFor: classHandle) instSpec]! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
oilLiteral: index ofMethod: aMethod
	<inline: true>
	^self cCode: [coInterpreter literal: index ofMethod: aMethod] inSmalltalk: [aMethod literalAt: index + 1]! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
literalHandle: index frame: frameIndex
	^self handleFor: (self oilLiteral: index ofMethod: (frameMethod at: frameIndex))! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
isReadOnlyBinding: binding
	"Class bindings are read-only: fold them to their value."
	^self cCode: [false] inSmalltalk: [binding isKindOf: ClassBinding]! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
bindingValueHandle: binding
	^self cCode: [objectMemory fetchPointer: 1 ofObject: binding] inSmalltalk: [self handleFor: binding value]! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
specialSelectorHandle: index
	^self cCode: [coInterpreter specialSelector: index] inSmalltalk: [self handleFor: (Smalltalk specialSelectors at: index * 2 + 1)]! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
numArgsOf: aMethod
	<inline: true>
	^self cCode: [coInterpreter argumentCountOf: aMethod] inSmalltalk: [aMethod numArgs]! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
numTempsOf: aMethod
	<inline: true>
	^self cCode: [coInterpreter tempCountOf: aMethod] inSmalltalk: [aMethod numTemps]! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
frameSizeOf: aMethod
	"Slots needed for temps and stack: 16 or 56 (large frame)."
	<inline: true>
	^self
		cCode: [(coInterpreter methodNeedsLargeContext: aMethod) ifTrue: [56] ifFalse: [16]]
		inSmalltalk: [aMethod frameSize]! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
oilPrimitiveIndexOf: aMethod
	<inline: true>
	^self cCode: [coInterpreter primitiveIndexOf: aMethod] inSmalltalk: [aMethod primitive]! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
oilIsQuickPrimitiveIndex: prim
	<inline: true>
	^prim between: 256 and: 519! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
lookup: selector inClass: classHandle
	"Answer the method found by looking up selector in the class, or 0."
	^self
		cCode: [coInterpreter oilApiLookupSelector: selector inClass: classHandle]
		inSmalltalk: [((self objectFor: classHandle) lookupSelector: (self objectFor: selector)) ifNil: [0]]! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
superclassHandleOfMethodClassOf: aMethod
	^self
		cCode: [coInterpreter oilApiSuperclassOf: (coInterpreter methodClassOf: aMethod)]
		inSmalltalk: [self handleFor: aMethod methodClass superclass]! !

!OilBaseCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
profiledClassAt: pc
	"Type feedback for the send at pc in the current frame's method: the receiver class if the site is monomorphic, else 0.
	 In the VM this queries ProfilingCogit's inline caches; in the image, a simulated-execution profile."
	^self
		cCode: [cogit oilMonomorphicClassAt: pc in: (frameMethod at: currentFrame)]
		inSmalltalk:
			[typeFeedback
				ifNil: [0]
				ifNotNil: [(typeFeedback classAt: pc in: (frameMethod at: currentFrame))
							ifNil: [0]
							ifNotNil: [:cls| self handleFor: cls]]]! !

!OilBaseCompiler class methodsFor: 'translation' stamp: 'cb 10/24/2026 19:35'!
declareCVarsIn: aCCodeGenerator
	"All of Pass 1's memory is static: the 16 KB IR buffer and fixed size tables (BSS), invisible to the GC."
	self == OilBaseCompiler ifFalse: [^self].
	"Pass 1 writes Buffer 1, Pass 2 streams it into Buffer 2; oilIRBuffer points to the current one."
	aCCodeGenerator var: #oilIRBuffer1 declareC: 'static unsigned int oilIRBuffer1[OilBufferWords]'.
	aCCodeGenerator var: #oilIRBuffer2 declareC: 'static unsigned int oilIRBuffer2[OilBufferWords]'.
	aCCodeGenerator var: #oilIRBuffer type: #'unsigned int *'.
	"Pass 2 tables."
	aCCodeGenerator var: #oilIRMap declareC: 'static unsigned short oilIRMap[OilBufferWords + 1]'.
	aCCodeGenerator var: #oilIRFlag declareC: 'static unsigned char oilIRFlag[OilBufferWords]'.
	aCCodeGenerator var: #oilIRAux declareC: 'static unsigned char oilIRAux[OilBufferWords]'.
	#(oilVRegDefs oilVRegUses) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilNumRegs]'].
	"Pass 3: in-place tagged adds and their undo stubs."
	aCCodeGenerator var: #oilUndoJump declareC: 'static AbstractInstruction *oilUndoJump[OilMaxUndos]'.
	#(oilUndoSite oilUndoReg oilUndoSrc) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilMaxUndos]'].
	#(slotKind slotValue knownClass affineBase affineConst affineVersion regVersion lastDefIR) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilNumRegs]'].
	aCCodeGenerator var: #slotFlags declareC: 'static unsigned char slotFlags[OilNumRegs]'.
	#(frameMethod frameBase frameParent frameHome frameCallPC frameIsBlock frameSelfKind frameSelfValue frameSelfClass frameTempStart frameStackStart frameMaxReg framePCBase frameStartPC frameEndPC frameExitChain frameHasLazy frameLazyKind frameLazyValue frameDepth) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilMaxFrames]'].
	"The pc map (per inlined frame bytecode labels) is the largest table: keep it compact (8192 x 6 bytes = 48 KB)."
	aCCodeGenerator var: #pcTarget declareC: 'static unsigned char pcTarget[OilPCMapSize]'.
	aCCodeGenerator var: #pcLabelIR declareC: 'static short pcLabelIR[OilPCMapSize]'.
	aCCodeGenerator var: #pcChain declareC: 'static unsigned short pcChain[OilPCMapSize]'.
	aCCodeGenerator var: #pcDepth declareC: 'static unsigned char pcDepth[OilPCMapSize]'.
	aCCodeGenerator var: #pcLoop declareC: 'static unsigned char pcLoop[OilPCMapSize]'.
	aCCodeGenerator var: #oilDisqualified declareC: 'static sqInt oilDisqualified[OilMaxDisqualified]'.
	aCCodeGenerator var: #oilNoInline declareC: 'static sqInt oilNoInline[16]'.
	#(vobjKind vobjLiteral vobjSelfKind vobjSelfValue vobjSelfClass vobjNumCopied vobjCopiedBase vobjHome vobjSize vobjSlotBase) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilMaxVObjs]'].
	#(capturedKind capturedValue) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilMaxCaptured]'].
	#(siteIR siteFrame sitePC siteKind siteSnapBase siteSnapTop siteSnapHigh) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilMaxSites]'].
	#(condCond condRA condRB condImm condUseImm condIdentity condFrame condPC condSite) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilMaxConds]'].
	"Deoptimization metadata: the virtual state at the current bytecode and the states recorded at deopt sites."
	#(snapKind snapValue) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilNumRegs]'].
	#(sitePoolKind sitePoolValue) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilSitePoolSize]'].
	aCCodeGenerator var: #vobjOuter declareC: 'static sqInt vobjOuter[OilMaxVObjs]'.
	"Pass 3 (native code generation) tables."
	#(oilVRegReg oilVRegHome) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilNumRegs]'].
	aCCodeGenerator var: #oilIRTarget declareC: 'static unsigned char oilIRTarget[OilBufferWords]'.
	aCCodeGenerator var: #oilLoopDepth declareC: 'static unsigned char oilLoopDepth[OilBufferWords]'.
	aCCodeGenerator var: #oilTagged declareC: 'static unsigned char oilTagged[OilNumRegs]'.
	aCCodeGenerator var: #oilIRSite declareC: 'static short oilIRSite[OilBufferWords]'.
	aCCodeGenerator var: #oilIRLabel declareC: 'static AbstractInstruction *oilIRLabel[OilBufferWords]'.
	aCCodeGenerator var: #oilFixupJump declareC: 'static AbstractInstruction *oilFixupJump[OilBufferWords]'.
	aCCodeGenerator var: #oilFixupTarget declareC: 'static sqInt oilFixupTarget[OilBufferWords]'.
	aCCodeGenerator var: #oilStubJump declareC: 'static AbstractInstruction *oilStubJump[OilBufferWords]'.
	aCCodeGenerator var: #oilStubSite declareC: 'static sqInt oilStubSite[OilBufferWords]'.
	aCCodeGenerator var: #oilSiteResume declareC: 'static AbstractInstruction *oilSiteResume[OilMaxSites]'.
	aCCodeGenerator var: #oilSiteStub declareC: 'static AbstractInstruction *oilSiteStub[OilMaxSites]'.
	aCCodeGenerator var: #oilSiteUsed declareC: 'static unsigned char oilSiteUsed[OilMaxSites]'.
	aCCodeGenerator var: #oilAllocRegs declareC: 'static sqInt oilAllocRegs[16]'.
	"Float chains: the XMM registers, the register whose value each holds (or -1) and how it was loaded (-1: computed)."
	#(oilXmmRegs oilXmmVReg oilXmmKind) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilNumXmms]'].
	aCCodeGenerator var: #valueSelectors declareC: 'static sqInt valueSelectors[5]'.
	aCCodeGenerator var: #iteratorSelectors declareC: 'static sqInt iteratorSelectors[32]'.
	aCCodeGenerator var: #coldSelectors declareC: 'static sqInt coldSelectors[32] /* OilMaxColdSelectors */'.
	#(typeFeedback simHandles simHandleIndex) do:
		[:var| aCCodeGenerator removeVariable: var]! !
