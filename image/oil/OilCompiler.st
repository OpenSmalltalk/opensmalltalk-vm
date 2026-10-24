OilBytecodeScanner subclass: #OilCompiler
	instanceVariableNames: 'oilIRBuffer irIndex irInstCount lastInstIR lastLabelIR irBudget slotKind slotValue slotFlags knownClass affineBase affineConst affineVersion regVersion lastDefIR simStackTop highRegTop frameMethod frameBase frameParent frameHome frameCallPC frameIsBlock frameSelfKind frameSelfValue frameSelfClass frameTempStart frameStackStart frameMaxReg framePCBase frameStartPC frameEndPC frameExitChain frameHasLazy frameLazyKind frameLazyValue frameDepth frameVObj numFrames currentFrame currentPC pcTarget pcLabelIR pcChain pcDepth pcMapTop vobjKind vobjLiteral vobjSelfKind vobjSelfValue vobjSelfClass vobjNumCopied vobjCopiedBase vobjHome vobjSize vobjSlotBase numVObjs capturedKind capturedValue capturedTop siteIR siteFrame sitePC siteKind numSites oilDeadCode failed failureCode needsRestart eagerClosures inlineClass inlineGuard numInlinedFrames numInlinedQuick numIntrinsics numCalls numGuards numFolds nilHandle trueHandle falseHandle smallIntegerClassHandle bitXorSelector valueSelectors iteratorSelectors numIteratorSelectors coldSelectors numColdSelectors condCond condRA condRB condImm condUseImm condIdentity condFrame condPC numConds pendingCondSlot pendingCondIndex typeFeedback simHandles simHandleIndex rootMethod rootClass snapFrame snapPC snapTop snapHighTop snapKind snapValue sitePoolKind sitePoolValue sitePoolTop siteSnapBase siteSnapTop siteSnapHigh condSite emittingCond vobjOuter oilVRegWeight oilVRegReg oilVRegHome oilNumHomes oilIRTarget oilIRLabel oilIRSite oilNumFixups oilFixupJump oilFixupTarget oilNumStubJumps oilStubJump oilStubSite oilSiteResume oilSiteStub oilSiteUsed oilBailoutCommon oilAllocRegs oilNumAllocRegs oilLoopDepth oilFailIndex oilTraceBuf oilTraceTop oilTagged oilIRBuffer1 oilIRBuffer2 oilIRMap oilIRFlag oilIRAux oilVRegDefs oilVRegUses oilPass1Words oilNumRotated oilNumBoundsRemoved oilNumDeadRemoved oilNumSizesShared oilNumNoCheck oilUndoJump oilUndoSite oilUndoReg oilUndoSrc oilNumUndos oilUseProbe oilUseProbeHit pcLoop oilNumGuardsRemoved'
	classVariableNames: ''
	poolDictionaries: 'OilConstants CogAbstractRegisters VMStackFrameOffsets'
	category: 'Cogit-Oil'!

!OilCompiler commentStamp: 'cb 10/24/2026 10:30' prior: 0!
I am Pass 1 of Oil, the optimizing JIT of the 64-bit Spur Cog VM.  Given the outer (home) method of a hot loop and the class of its receiver, I translate its bytecodes, recursively inlining blocks, collection iterators and small methods, into a flat 32-bit compact linear IR in a preallocated static buffer, applying peephole reductions for tagged SmallInteger arithmetic on the fly.  I allocate nothing: every table is a fixed size array (static/BSS memory in the VM, invisible to the GC).

IR format: oilIRBuffer is an array of OilBufferWords (4096) 32-bit words (16 KB).  An instruction is one word [Opcode:8 | Dest:8 | Src1:8 | Src2/Imm:8], possibly followed by a 64-bit operand (2 words, low word first) and packed argument words.  See the OilConstants class comment and OilCompiler>>printIROn: for the opcode set.  Branch targets are absolute IR word indices.  Instructions that can bail out (guards, bounds checks, tagged arithmetic, calls, non-boolean branches) are recorded in a side table of deopt sites (IR index, inlined frame, bytecode pc), and the frame table describes the inlined frames (method, base register, caller frame, call site pc) for Milestone 3's deoptimization metadata.

Virtual registers (256, 8-bit operands) are allocated like a register window: the root method's receiver is r0, its arguments r1..rN, its temporaries follow, then its expression stack.  An inlined method's frame starts at the register holding its receiver on the caller's stack, so arguments are bound in place and the method's result is left in the register the caller expects for the send's result.  Scalar replaced temp vectors live in high registers (allocated downwards from r254); r255 means "condition flags".

Each register has a descriptor (slotKind/slotValue): its own register, an alias of another register, a not yet materialized constant, a virtual (not allocated) closure, or a virtual temp vector.  Expression stack entries are descriptors, which enables constant folding, copy propagation and the dissolving of closures and temp vectors whose blocks are inlined.  At every control flow merge all mutable registers are made canonical (own register), which keeps the linear pass simple and correct without SSA or phis.  If a closure must exist (it escapes), compilation restarts once in eager mode where closures and temp vectors are materialized.

Inlining policy: blocks evaluated via value* and methods taking a virtual block or known iterators (do:, collect:, select:, detect:, inject:into:, timesRepeat:, scanFor:, findElementOrNil:, ...) up to depth 8 (OilMaxInlineDepth); accessors of at most 10 bytes (and quick methods) up to depth 8; methods up to 30 bytes up to depth 4; larger methods up to depth 2; never beyond the IR budget (irBudget, 1024 instructions by default).  Receiver classes come from constants, from facts established by guards and inlining, or from type feedback (the inline caches of ProfilingCogit in the VM, simulated execution in the image).  Sends that are not inlined become OilCall0/OilCall1/OilCallN.!

!OilCompiler methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:30'!
initialize
	"Simulation only: in the VM all tables are static (BSS) arrays, see OilCompiler class>>declareCVarsIn:."
	<doNotGenerate>
	super initialize.
	self setUpSimulationTables! !

!OilCompiler methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:30'!
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
	frameVObj := self newTable: OilMaxFrames.
	pcTarget := self newTable: OilPCMapSize.
	pcLabelIR := self newTable: OilPCMapSize.
	pcChain := self newTable: OilPCMapSize.
	pcDepth := self newTable: OilPCMapSize.
	pcLoop := self newTable: OilPCMapSize.
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
	emittingCond := -1.
	irBudget := OilIRBudget.
	simHandles := OrderedCollection new.
	simHandleIndex := IdentityDictionary new.
	self setUpSimulationHandles.
	self resetForCompilation! !

!OilCompiler methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:30'!
newTable: n
	<doNotGenerate>
	^CArrayAccessor on: (Array new: n withAll: 0)! !

!OilCompiler methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:30'!
setUpSimulationHandles
	"In the VM, nil/true/false/SmallInteger are the object memory's oops (see resetForCompilation) and the special
	 selectors are registered at startup with registerSelector:kind:.  In the image they are simulated handles (see handleFor:)."
	<doNotGenerate>
	nilHandle := self handleFor: nil.
	trueHandle := self handleFor: true.
	falseHandle := self handleFor: false.
	smallIntegerClassHandle := self handleFor: SmallInteger.
	numIteratorSelectors := numColdSelectors := 0.
	#(value value: value:value: value:value:value: value:value:value:value:) doWithIndex:
		[:sel :i| self registerSelector: (self handleFor: sel) kind: i - 1].
	self registerSelector: (self handleFor: #bitXor:) kind: 5.
	#(do: reverseDo: collect: select: reject: detect: detect:ifNone: detect:ifFound:ifNone: inject:into: do:separatedBy: doWithIndex: withIndexDo: keysAndValuesDo: timesRepeat: to:do: to:by:do: scanFor: findElementOrNil: with:do: allSatisfy: anySatisfy: noneSatisfy: count: detectMax: detectMin:) do:
		[:sel| self registerSelector: (self handleFor: sel) kind: 6].
	"Error paths are cold: never inlined (they would bloat the IR of the hot loop for nothing)."
	#(error: errorNoFreeSpace errorNotFound: errorSubscriptBounds: errorNoSuchElement errorEmptyCollection errorKeyNotFound: errorKeyNotFound errorImproperStore errorNonIntegerIndex errorNotIndexable subclassResponsibility shouldNotImplement notYetImplemented halt halt: deprecated: deprecated signal signal: doesNotUnderstand: cannotReturn: primitiveFailed primitiveFailed:) do:
		[:sel| self registerSelector: (self handleFor: sel) kind: 7]! !

!OilCompiler methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:30'!
registerSelector: selector kind: kind
	"Tell Oil about a selector it treats specially (at VM startup, or from the image via a primitive):
	 kind 0-4: value selectors by arity, 5: bitXor:, 6: collection iterators/hash probes, 7: cold (error paths)."
	<api>
	kind <= 4 ifTrue:
		[valueSelectors at: kind put: selector.
		 ^self].
	kind = 5 ifTrue:
		[bitXorSelector := selector.
		 ^self].
	kind = 6 ifTrue:
		[numIteratorSelectors < 32 ifTrue:
			[iteratorSelectors at: numIteratorSelectors put: selector.
			 numIteratorSelectors := numIteratorSelectors + 1].
		 ^self].
	numColdSelectors < OilMaxColdSelectors ifTrue:
		[coldSelectors at: numColdSelectors put: selector.
		 numColdSelectors := numColdSelectors + 1]! !

!OilCompiler methodsFor: 'initialization' stamp: 'cb 10/24/2026 14:00'!
resetSelectorRegistry
	"Forget the registered special selectors (the VM re-registers them before each compilation, since
	 selector oops move when the garbage collector compacts the heap)."
	0 to: 4 do: [:i| valueSelectors at: i put: 0].
	bitXorSelector := 0.
	numIteratorSelectors := numColdSelectors := 0! !

!OilCompiler methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:30'!
resetForCompilation
	self cCode:
		[nilHandle := objectMemory nilObject.
		 trueHandle := objectMemory trueObject.
		 falseHandle := objectMemory falseObject.
		 smallIntegerClassHandle := objectMemory classSmallInteger].
	oilIRBuffer := oilIRBuffer1. "Pass 1 writes Buffer 1; Pass 2 (pass2Optimize) streams it into Buffer 2"
	irIndex := irInstCount := 0.
	oilPass1Words := 0.
	lastInstIR := -1.
	lastLabelIR := 0.
	0 to: OilNumRegs - 1 do:
		[:r|
		slotKind at: r put: OilDescReg.
		slotValue at: r put: r.
		slotFlags at: r put: 0.
		knownClass at: r put: 0.
		affineBase at: r put: -1.
		affineConst at: r put: 0.
		affineVersion at: r put: 0.
		regVersion at: r put: 0.
		lastDefIR at: r put: -1].
	simStackTop := -1.
	highRegTop := OilMaxReg.
	numFrames := pcMapTop := numVObjs := capturedTop := numSites := numConds := 0.
	sitePoolTop := 0.
	snapFrame := snapPC := snapTop := snapHighTop := -1.
	emittingCond := -1.
	pendingCondSlot := -1.
	currentFrame := -1.
	currentPC := 0.
	oilDeadCode := failed := needsRestart := false.
	failureCode := OilOK.
	inlineClass := 0.
	inlineGuard := false.
	numInlinedFrames := numInlinedQuick := numIntrinsics := numCalls := numGuards := numFolds := 0! !

!OilCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
irBudget: anInteger
	irBudget := anInteger! !

!OilCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
typeFeedback: aTypeFeedbackOracle
	<doNotGenerate>
	typeFeedback := aTypeFeedbackOracle! !

!OilCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
failed
	^failed! !

!OilCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
failureCode
	^failureCode! !

!OilCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
eagerClosures
	^eagerClosures! !

!OilCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
irIndex
	^irIndex! !

!OilCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
irInstCount
	^irInstCount! !

!OilCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
irWordAt: index
	^oilIRBuffer at: index! !

!OilCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
numCalls
	^numCalls! !

!OilCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
numFolds
	^numFolds! !

!OilCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
numFrames
	^numFrames! !

!OilCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
numSites
	^numSites! !

!OilCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
siteIR
	^siteIR! !

!OilCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
siteFrame
	^siteFrame! !

!OilCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
sitePC
	^sitePC! !

!OilCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
frameMethod
	^frameMethod! !

!OilCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
frameCallPC
	^frameCallPC! !

!OilCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
frameParent
	^frameParent! !

!OilCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
frameBase
	^frameBase! !

!OilCompiler methodsFor: 'compilation' stamp: 'cb 10/24/2026 10:30'!
compileMethod: aMethod receiverClass: classHandle
	<api>
	"Pass 1: translate aMethod, the outer (home) method of a hot loop, specialized for receivers of class classHandle,
	 into the linear IR buffer.  Closures and temp vectors are first kept virtual (dissolved when their blocks are inlined);
	 if one escapes, compile again once with eagerClosures, materializing them.  Answer true on success."
	eagerClosures := false.
	irBudget = 0 ifTrue: [irBudget := OilIRBudget]. "in the VM nothing else initializes it"
	oilTraceTop := 0.
	[self compileOnce: aMethod receiverClass: classHandle.
	 needsRestart and: [eagerClosures not]] whileTrue:
		[eagerClosures := true].
	^failed not! !

!OilCompiler methodsFor: 'compilation' stamp: 'cb 10/24/2026 10:30'!
compileOnce: aMethod receiverClass: classHandle
	<inline: false>
	| f numArgs numTemps |
	self resetForCompilation.
	rootMethod := aMethod.
	rootClass := classHandle.
	(self oilIsSistaV1Method: aMethod) ifFalse: "Oil only decodes SistaV1: leave the method to the baseline Cogit"
		[^self abortCompilation: OilFailNotSistaV1].
	(self oilPrimitiveIndexOf: aMethod) ~= 0 ifTrue:
		[^self abortCompilation: OilFailPrimitiveMethod].
	f := self newFrameFor: aMethod base: 0 isBlock: false.
	f < 0 ifTrue:
		[^self abortCompilation: OilFailUnsupportedBytecode].
	numArgs := self numArgsOf: aMethod.
	numTemps := self numTempsOf: aMethod.
	frameHome at: f put: f.
	frameSelfKind at: f put: OilDescReg.
	frameSelfValue at: f put: 0.
	frameSelfClass at: f put: classHandle.
	knownClass at: 0 put: classHandle.
	0 to: numArgs do: [:r| slotFlags at: r put: OilFlagImmutable].
	numArgs + 1 to: numTemps do:
		[:r|
		slotFlags at: r put: OilFlagTemp.
		self setSlot: r kind: OilDescConst value: nilHandle].
	frameTempStart at: f put: numArgs + 1.
	frameStackStart at: f put: numTemps + 1.
	simStackTop := numTemps.
	"The receiver's class is a speculation (inlined self sends are bound to it): guard it at entry.
	 Bailing out there resumes the method from its first bytecode in the interpreter."
	currentFrame := f.
	currentPC := frameStartPC at: f.
	self takeSnapshotFrame: f pc: currentPC.
	self emitGuardOn: 0 class: classHandle.
	self translateFrame: f! !

!OilCompiler methodsFor: 'compilation' stamp: 'cb 10/24/2026 10:30'!
abortCompilation: code
	failed ifFalse: [failureCode := code].
	failed := true! !

!OilCompiler methodsFor: 'compilation' stamp: 'cb 10/24/2026 10:30'!
requireEagerClosures
	"A virtual closure or temp vector must be materialized.  Restart in eager mode (or give up if already eager)."
	self oilTrace: currentFrame with: currentPC. "why eager mode was needed (see primitiveOilLastCompilation)"
	eagerClosures
		ifTrue: [self abortCompilation: OilFailEagerClosuresFailed]
		ifFalse: [needsRestart := true. failed := true]! !

!OilCompiler methodsFor: 'frames' stamp: 'cb 10/24/2026 10:30'!
newFrameFor: aMethod base: base isBlock: isBlock
	"Allocate a frame for aMethod whose receiver (or closure) is in register base, and pre-scan its bytecodes
	 for branch targets.  Answer the frame index, or -1 if the method cannot be translated or resources are exhausted."
	| f mapSize regsNeeded |
	(self oilIsSistaV1Method: aMethod) ifFalse: [^-1]. "not inlined: sent instead"
	numFrames >= OilMaxFrames ifTrue: [^-1].
	regsNeeded := base + 2 + (self frameSizeOf: aMethod).
	regsNeeded >= highRegTop ifTrue: [^-1].
	mapSize := (self oilEndPCOf: aMethod) - (self startPCOf: aMethod) + 2.
	pcMapTop + mapSize > OilPCMapSize ifTrue: [^-1].
	f := numFrames.
	frameMethod at: f put: aMethod.
	frameBase at: f put: base.
	frameIsBlock at: f put: isBlock.
	frameStartPC at: f put: (self startPCOf: aMethod).
	frameEndPC at: f put: (self oilEndPCOf: aMethod).
	framePCBase at: f put: pcMapTop.
	frameMaxReg at: f put: regsNeeded.
	frameExitChain at: f put: OilNoLink.
	frameHasLazy at: f put: false.
	frameParent at: f put: currentFrame.
	frameCallPC at: f put: currentPC.
	frameVObj at: f put: -1.
	frameDepth at: f put: (currentFrame < 0 ifTrue: [0] ifFalse: [(frameDepth at: currentFrame) + 1]).
	(self preScanFrame: f) ifFalse: [^-1].
	numFrames := f + 1.
	pcMapTop := pcMapTop + mapSize.
	^f! !

!OilCompiler methodsFor: 'frames' stamp: 'cb 10/24/2026 10:30'!
preScanFrame: f
	"Mark the branch targets of frame f's method in its pc map region, and the pcs inside loops (pcLoop, from a
	 backward branch's target to the branch).  Answer false if the method contains a bytecode Oil does not translate."
	| pc end start base |
	start := frameStartPC at: f.
	end := frameEndPC at: f.
	base := framePCBase at: f.
	base to: base + (end - start) + 1 do:
		[:i|
		pcTarget at: i put: 0.
		pcLabelIR at: i put: -1.
		pcChain at: i put: OilNoLink.
		pcDepth at: i put: 0.
		pcLoop at: i put: 0].
	self setScanMethod: (frameMethod at: f).
	pc := start.
	[pc <= end] whileTrue:
		[self decodeAt: pc.
		 (self isTranslatableTag: opcodeTag) ifFalse: [^false].
		 oilTargetPC >= 0 ifTrue:
			[(oilTargetPC < start or: [oilTargetPC > end]) ifTrue: [^false].
			 pcTarget at: base + oilTargetPC - start put: 1.
			 oilTargetPC <= instrPC ifTrue:
				[oilTargetPC to: instrPC do: [:k| pcLoop at: base + k - start put: 1]]].
		 pc := oilNextPC].
	^true! !

!OilCompiler methodsFor: 'frames' stamp: 'cb 10/24/2026 10:30'!
isTranslatableTag: tag
	^(tag = OilTagUnknown
	   or: [tag = OilTagPushThisContext
	   or: [tag = OilTagPushEmbeddedClosure
	   or: [tag = OilTagCallPrimitive
	   or: [tag = OilTagTrap
	   or: [tag = OilTagBranchOnBehavior
	   or: [tag = OilTagExtension]]]]]]) not! !

!OilCompiler methodsFor: 'frames' stamp: 'cb 10/24/2026 10:30'!
isFrameActive: f
	| g |
	g := currentFrame.
	[g >= 0] whileTrue:
		[g = f ifTrue: [^true].
		 g := frameParent at: g].
	^false! !

!OilCompiler methodsFor: 'frames' stamp: 'cb 10/24/2026 10:30'!
isMethodOnInlineStack: aMethod
	| g |
	g := currentFrame.
	[g >= 0] whileTrue:
		[(frameMethod at: g) = aMethod ifTrue: [^true].
		 g := frameParent at: g].
	^false! !

!OilCompiler methodsFor: 'frames' stamp: 'cb 10/24/2026 10:30'!
tempReg: index frame: f
	<inline: true>
	^(frameBase at: f) + 1 + index! !

!OilCompiler methodsFor: 'frames' stamp: 'cb 10/24/2026 10:30'!
pcMapIndex: pc frame: f
	<inline: true>
	^(framePCBase at: f) + pc - (frameStartPC at: f)! !

!OilCompiler methodsFor: 'frames' stamp: 'cb 10/24/2026 10:30'!
exitFrame: f
	"Bind the exit label of the inlined frame f: all its returns leave the result in its base register
	 (or, for a single final return, as a lazy descriptor).  The base register becomes the caller's stack top."
	| base chain |
	base := frameBase at: f.
	chain := frameExitChain at: f.
	currentFrame := frameParent at: f.
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
			 self setOwn: base]
		ifFalse:
			[(frameHasLazy at: f) ifTrue:
				[self setSlot: base kind: (frameLazyKind at: f) value: (frameLazyValue at: f).
				 (frameLazyKind at: f) = OilDescCond ifTrue:
					[pendingCondSlot := base.
					 pendingCondIndex := frameLazyValue at: f].
				 oilDeadCode := false]].
	simStackTop := base.
	base to: (frameMaxReg at: f) do: [:r| slotFlags at: r put: 0].
	pcMapTop := framePCBase at: f! !

!OilCompiler methodsFor: 'translation' stamp: 'cb 10/24/2026 10:30'!
translateFrame: f
	<inline: false>
	"Translate the bytecodes of frame f into the IR buffer.  Answer false if compilation failed."
	| pc end next tag op1 op2 target ipc |
	pc := frameStartPC at: f.
	end := frameEndPC at: f.
	[pc <= end and: [failed not]] whileTrue:
		[self setScanMethod: (frameMethod at: f).
		 self decodeAt: pc.
		 next := oilNextPC. tag := opcodeTag. op1 := operand1. op2 := operand2. target := oilTargetPC. ipc := instrPC.
		 currentFrame := f.
		 currentPC := ipc.
		 (pcTarget at: (self pcMapIndex: ipc frame: f)) ~= 0 ifTrue:
			[self bindLabelAt: ipc frame: f].
		 oilDeadCode ifFalse:
			[self takeSnapshotFrame: f pc: ipc.
			 next := self translateTag: tag op1: op1 op2: op2 target: target next: next frame: f].
		 pc := next].
	^failed not! !

!OilCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/24/2026 14:00'!
takeSnapshotFrame: f pc: pc
	"Record the virtual state at the start of the bytecode at pc of frame f: the descriptors of all live
	 registers (the register window 0..simStackTop, which holds the receivers, temps and stacks of f and of
	 all the frames inlining it) and of the scalar replaced temp vector slots and captures (high registers).
	 A deopt site recorded while translating this bytecode resumes the interpreter right before it, in this
	 state.  Descriptors are copied: the translation of the bytecode may change them before the site."
	<inline: false>
	snapFrame := f.
	snapPC := pc.
	snapTop := simStackTop.
	snapHighTop := highRegTop.
	0 to: simStackTop do:
		[:r|
		snapKind at: r put: (slotKind at: r).
		snapValue at: r put: (slotValue at: r)].
	highRegTop + 1 to: OilMaxReg do:
		[:r|
		snapKind at: r put: (slotKind at: r).
		snapValue at: r put: (slotValue at: r)]! !

!OilCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/24/2026 14:00'!
copySnapshotToSite: n
	"Append the current snapshot to the site pool for deopt site n.  A lazy comparison in the snapshot
	 is materialized (in its own register) before the site's instruction is emitted (see recordSite:),
	 so it is recorded as that register."
	| base |
	<inline: false>
	base := sitePoolTop.
	base + snapTop + 1 + (OilMaxReg - snapHighTop) > OilSitePoolSize ifTrue:
		[siteSnapBase at: n put: -1.
		 ^self].
	siteSnapBase at: n put: base.
	siteSnapTop at: n put: snapTop.
	siteSnapHigh at: n put: snapHighTop.
	0 to: snapTop do:
		[:r|
		(snapKind at: r) = OilDescCond
			ifTrue:
				[sitePoolKind at: base put: OilDescReg.
				 sitePoolValue at: base put: r]
			ifFalse:
				[sitePoolKind at: base put: (snapKind at: r).
				 sitePoolValue at: base put: (snapValue at: r)].
		base := base + 1].
	snapHighTop + 1 to: OilMaxReg do:
		[:r|
		sitePoolKind at: base put: (snapKind at: r).
		sitePoolValue at: base put: (snapValue at: r).
		base := base + 1].
	sitePoolTop := base! !

!OilCompiler methodsFor: 'translation' stamp: 'cb 10/24/2026 10:30'!
translateTag: tag op1: op1 op2: op2 target: target next: next frame: f
	<inline: false>
	"Translate one (logical) bytecode.  Answer the pc of the next bytecode to translate."
	| isBlock |
	isBlock := frameIsBlock at: f.
	tag caseOf: {
		[OilTagPushRcvrVar]		-> [self genPushRcvrVar: op1 frame: f].
		[OilTagPushLitVar]		-> [self genPushLitVar: op1 frame: f].
		[OilTagPushLitConst]		-> [self push: OilDescConst value: (self literalHandle: op1 frame: f)].
		[OilTagPushTemp]			-> [self genPushTemp: op1 frame: f].
		[OilTagPushSelf]			-> [self push: (frameSelfKind at: f) value: (frameSelfValue at: f)].
		[OilTagPushTrue]			-> [self push: OilDescConst value: trueHandle].
		[OilTagPushFalse]		-> [self push: OilDescConst value: falseHandle].
		[OilTagPushNil]			-> [self push: OilDescConst value: nilHandle].
		[OilTagPushInteger]		-> [self push: OilDescConst value: (self handleForSmallInteger: op1)].
		[OilTagPushCharacter]	-> [self push: OilDescConst value: (self handleForCharacter: op1)].
		[OilTagDup]				-> [self genDup].
		[OilTagPop]				-> [simStackTop := simStackTop - 1].
		[OilTagNop]				-> [].
		[OilTagReturnSelf]		-> [self genReturnKind: (frameSelfKind at: f) value: (frameSelfValue at: f) nonLocal: isBlock frame: f next: next].
		[OilTagReturnTrue]		-> [self genReturnKind: OilDescConst value: trueHandle nonLocal: isBlock frame: f next: next].
		[OilTagReturnFalse]		-> [self genReturnKind: OilDescConst value: falseHandle nonLocal: isBlock frame: f next: next].
		[OilTagReturnNil]		-> [self genReturnKind: OilDescConst value: nilHandle nonLocal: isBlock frame: f next: next].
		[OilTagReturnTop]		-> [self genReturnTopNonLocal: isBlock frame: f next: next].
		[OilTagBlockReturnNil]	-> [self genReturnKind: OilDescConst value: nilHandle nonLocal: false frame: f next: next].
		[OilTagBlockReturnTop]	-> [self genReturnTopNonLocal: false frame: f next: next].
		[OilTagSendSpecial]		-> [^self genSpecialSend: op1 numArgs: op2 frame: f next: next].
		[OilTagSend]				-> [self genSend: (self literalHandle: op1 frame: f) numArgs: op2 super: false frame: f].
		[OilTagSendSuper]		-> [self genSend: (self literalHandle: op1 frame: f) numArgs: op2 super: true frame: f].
		[OilTagJump]				-> [self genJumpTo: target frame: f].
		[OilTagJumpTrue]			-> [self genJumpIf: true to: target frame: f].
		[OilTagJumpFalse]		-> [self genJumpIf: false to: target frame: f].
		[OilTagStoreRcvrVar]		-> [self genStoreRcvrVar: op1 pop: false frame: f].
		[OilTagPopIntoRcvrVar]	-> [self genStoreRcvrVar: op1 pop: true frame: f].
		[OilTagStoreTemp]		-> [self storeTopIntoReg: (self tempReg: op1 frame: f) pop: false].
		[OilTagPopIntoTemp]		-> [self storeTopIntoReg: (self tempReg: op1 frame: f) pop: true].
		[OilTagStoreLitVar]		-> [self genStoreLitVar: op1 pop: false frame: f].
		[OilTagPopIntoLitVar]	-> [self genStoreLitVar: op1 pop: true frame: f].
		[OilTagPushNewArray]		-> [self genPushNewArray: op1 pop: op2 = 1].
		[OilTagPushRemoteTemp]	-> [self genPushRemoteTemp: op1 inVector: op2 frame: f].
		[OilTagStoreRemoteTemp]	-> [self genStoreRemoteTemp: op1 inVector: op2 pop: false frame: f].
		[OilTagPopIntoRemoteTemp] -> [self genStoreRemoteTemp: op1 inVector: op2 pop: true frame: f].
		[OilTagPushFullClosure]	-> [self genPushFullClosure: op1 flags: op2 frame: f] }
		otherwise: [self abortCompilation: OilFailUnsupportedBytecode].
	^next! !

!OilCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
bindLabelAt: pc frame: f
	"pc is a branch target of frame f.  Make the state canonical (or, coming out of dead code,
	 adopt the canonical state of the branches to it), resolve pending forward branches and record the label."
	| idx |
	idx := self pcMapIndex: pc frame: f.
	oilDeadCode
		ifTrue:
			[(pcChain at: idx) = OilNoLink ifTrue: [^self]. "unreachable"
			 oilDeadCode := false.
			 simStackTop := pcDepth at: idx.
			 self resetMutableSlotsOfFrame: f]
		ifFalse:
			[self flushFrame: f].
	self patchChain: (pcChain at: idx) to: irIndex.
	pcChain at: idx put: OilNoLink.
	pcLabelIR at: idx put: irIndex.
	self forgetKnowledgeAtLabel! !

!OilCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
patchChain: head to: targetIndex
	"Forward branches to a not yet bound label are chained through their 16-bit target fields."
	| link next |
	link := head.
	[link ~= OilNoLink] whileTrue:
		[next := self imm16At: link.
		 self patchBranch: link to: targetIndex.
		 link := next]! !

!OilCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
patchBranch: index to: targetIndex
	oilIRBuffer at: index put: (((oilIRBuffer at: index) bitAnd: 16rFFFF0000) bitOr: (targetIndex bitAnd: 16rFFFF))! !

!OilCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
forgetKnowledgeAtLabel
	"At a merge point, facts established on one path are lost: tagged-arithmetic relations and guarded classes.
	 Only the classes of the active frames' receivers dominate every label (guarded before frame entry)."
	| g |
	lastLabelIR := irIndex.
	0 to: OilMaxReg do:
		[:r|
		affineBase at: r put: -1.
		knownClass at: r put: 0].
	g := currentFrame.
	[g >= 0] whileTrue:
		[(frameSelfKind at: g) = OilDescReg ifTrue:
			[knownClass at: (frameSelfValue at: g) put: (frameSelfClass at: g)].
		 g := frameParent at: g]! !

!OilCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
flushFrame: f
	"Before a branch or a label: make every mutable register of frame f (temps and stack) and every
	 scalar replaced temp vector slot hold its value in its own register, so that all paths agree."
	(frameTempStart at: f) to: simStackTop do:
		[:i| (self isImmutable: i) ifFalse: [self flushSlot: i]].
	self flushTVSlots! !

!OilCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
flushTVSlots
	highRegTop + 1 to: OilMaxReg do:
		[:h| ((slotFlags at: h) bitAnd: OilFlagTVSlot) ~= 0 ifTrue: [self flushSlot: h]]! !

!OilCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
flushSlot: i
	| k v |
	k := slotKind at: i.
	v := slotValue at: i.
	k = OilDescReg ifTrue:
		[v ~= i ifTrue: [self emitMove: i from: v. self setOwn: i].
		 ^self].
	k = OilDescConst ifTrue:
		[self emitConst: v into: i.
		 self setOwn: i.
		 ^self].
	k = OilDescCond ifTrue:
		[self emitCond: v booleanInto: i.
		 self setOwn: i.
		 ^self].
	k = OilDescBlock ifTrue: "a virtual closure live across a merge: materialize"
		[self requireEagerClosures]
	"a virtual temp vector is an identity, never redefined after its creation at frame start: canonical as is"! !

!OilCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
resetMutableSlotsOfFrame: f
	(frameTempStart at: f) to: simStackTop do:
		[:i|
		((self isImmutable: i) or: [(slotKind at: i) = OilDescTempVector]) ifFalse:
			[self setOwn: i]].
	self resetTVSlotsToOwn! !

!OilCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
resetTVSlotsToOwn
	highRegTop + 1 to: OilMaxReg do:
		[:h| ((slotFlags at: h) bitAnd: OilFlagTVSlot) ~= 0 ifTrue: [self setOwn: h]]! !

!OilCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
emitBranch: op cond: condReg to: target frame: f
	"Emit a jump/branch to bytecode pc target of frame f: backward branches go to a bound label,
	 forward branches are chained until their label is bound."
	| idx label i |
	idx := self pcMapIndex: target frame: f.
	target <= currentPC
		ifTrue:
			[label := pcLabelIR at: idx.
			 label < 0 ifTrue: [^self abortCompilation: OilFailInternal].
			 self emitOp: op a: condReg imm16: label]
		ifFalse:
			[i := self emitOp: op a: condReg imm16: (pcChain at: idx).
			 pcChain at: idx put: i.
			 pcDepth at: idx put: simStackTop]! !

!OilCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
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

!OilCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
emitOp: op a: a imm16: imm
	^self emitOp: op a: a b: ((imm bitShift: -8) bitAnd: 255) c: (imm bitAnd: 255)! !

!OilCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
emitWord: word
	irIndex < OilBufferWords ifTrue:
		[oilIRBuffer at: irIndex put: (word bitAnd: 16rFFFFFFFF).
		 irIndex := irIndex + 1]! !

!OilCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
emit64: value
	"64-bit operand (an oop: literal, selector, class tag), low word first."
	self emitWord: (value bitAnd: 16rFFFFFFFF).
	self emitWord: ((value bitShift: -32) bitAnd: 16rFFFFFFFF)! !

!OilCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
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

!OilCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
noteDef: r at: index
	"Register r is (re)defined by the instruction at index."
	lastDefIR at: r put: index.
	regVersion at: r put: (regVersion at: r) + 1.
	affineBase at: r put: -1.
	knownClass at: r put: 0! !

!OilCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
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

!OilCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
emitMove: dst from: src
	| idx |
	dst = src ifTrue: [^self].
	idx := self emitOp: OilMove a: dst b: src c: 0.
	self noteDef: dst at: idx.
	knownClass at: dst put: (knownClass at: src)! !

!OilCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
emitGuardOn: r class: classHandle
	| site |
	site := self recordSite: OilSiteGuard.
	self emitOp: OilGuardClass a: r imm16: site.
	self emit64: classHandle.
	knownClass at: r put: classHandle.
	numGuards := numGuards + 1! !

!OilCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
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

!OilCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
retractLastInstruction
	"Delete the last emitted instruction (a one word instruction).  Its deopt site, if any, becomes dead
	 (IR index -2); sites are not removed since a pending lazy comparison site (IR index -1) may follow."
	irIndex := lastInstIR.
	irInstCount := irInstCount - 1.
	numSites - 1 to: 0 by: -1 do:
		[:s| (siteIR at: s) >= irIndex ifTrue: [siteIR at: s put: -2]].
	lastInstIR := -1! !

!OilCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
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

!OilCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
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

!OilCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
opcodeHasDest: op
	^op = OilConstTagged or: [op = OilConst64 or: [op = OilMove or: [(op between: OilAddTagged and: OilOddTagged)
		or: [op = OilLoadField or: [op = OilLoadElement or: [(op between: OilCall0 and: OilAddImmTagged)
		or: [op = OilLoadSize or: [op = OilMakeClosure or: [op = OilNewArray or: [op = OilCallSuper or: [op = OilAddImmTaggedNC or: [op = OilModTagged]]]]]]]]]]]]! !

!OilCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
setSlot: i kind: k value: v
	<inline: true>
	slotKind at: i put: k.
	slotValue at: i put: v! !

!OilCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
setOwn: i
	<inline: true>
	slotKind at: i put: OilDescReg.
	slotValue at: i put: i! !

!OilCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
isImmutable: i
	<inline: true>
	^((slotFlags at: i) bitAnd: OilFlagImmutable) ~= 0! !

!OilCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
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

!OilCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
pushOwnSlot
	"Push a stack entry whose value the caller is about to compute into its own register."
	| i |
	i := self push: OilDescReg value: simStackTop + 1.
	knownClass at: i put: 0.
	affineBase at: i put: -1.
	^i! !

!OilCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
regForKind: k value: v scratch: scratch
	"Answer a register holding the value described by (k, v), materializing a constant into scratch."
	k = OilDescReg ifTrue: [^v].
	k = OilDescConst ifTrue:
		[self emitConst: v into: scratch.
		 ^scratch].
	k = OilDescCond ifTrue:
		[self emitCond: v booleanInto: scratch.
		 ^scratch].
	self requireEagerClosures.
	^scratch! !

!OilCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
regForSlot: i
	"Answer a register holding slot i's value.  A constant is materialized in i's own register
	 (re-materialized at each use if i is immutable, so that no path dependent state is created)."
	| k v |
	k := slotKind at: i.
	v := slotValue at: i.
	k = OilDescReg ifTrue: [^v].
	k = OilDescConst ifTrue:
		[self emitConst: v into: i.
		 (self isImmutable: i) ifFalse: [self setOwn: i].
		 ^i].
	k = OilDescCond ifTrue:
		[self emitCond: v booleanInto: i.
		 self setOwn: i.
		 ^i].
	self requireEagerClosures.
	^i! !

!OilCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
materializeSlot: i
	"Make slot i hold its value in its own register (e.g. for a send's receiver and arguments)."
	| k v |
	k := slotKind at: i.
	v := slotValue at: i.
	k = OilDescReg ifTrue:
		[v ~= i ifTrue: [self emitMove: i from: v. self setOwn: i].
		 ^self].
	k = OilDescConst ifTrue:
		[self emitConst: v into: i.
		 self setOwn: i.
		 ^self].
	k = OilDescCond ifTrue:
		[self emitCond: v booleanInto: i.
		 self setOwn: i.
		 ^self].
	self requireEagerClosures! !

!OilCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
stabilizeIncomingSlot: i
	"An inlined frame's receiver/argument must not alias a temp vector slot register, which inlined blocks may assign."
	| v |
	(slotKind at: i) = OilDescCond ifTrue: [^self materializeSlot: i].
	(slotKind at: i) = OilDescReg ifFalse: [^self].
	v := slotValue at: i.
	(v ~= i and: [((slotFlags at: v) bitAnd: OilFlagTVSlot) ~= 0]) ifTrue:
		[self emitMove: i from: v.
		 self setOwn: i]! !

!OilCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
invalidateAliasesOf: r
	"r, a named temp or temp vector slot register, is about to be assigned.  Copy its current value into
	 every live mutable slot aliasing it.  A live virtual closure or immutable slot that captured r
	 forces eager closures."
	| k |
	(pendingCondSlot >= 0
	 and: [(condRA at: pendingCondIndex) = r
		or: [(condUseImm at: pendingCondIndex) not and: [(condRB at: pendingCondIndex) = r]]]) ifTrue:
		[self materializePendingCond].
	0 to: simStackTop do:
		[:i|
		k := slotKind at: i.
		(k = OilDescReg and: [(slotValue at: i) = r and: [i ~= r]]) ifTrue:
			[(self isImmutable: i)
				ifTrue: [self requireEagerClosures]
				ifFalse: [self emitMove: i from: r. self setOwn: i]].
		(k = OilDescBlock and: [self virtualBlock: (slotValue at: i) captures: r]) ifTrue:
			[self requireEagerClosures]]! !

!OilCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
virtualBlock: v0 captures: r
	"Does the virtual closure v0 (or a virtual closure it captured, transitively) capture register r?
	 Iterative (explicit work stack) so that it translates to plain C."
	| stack sp v base k |
	<inline: false>
	<var: #stack declareC: 'sqInt stack[OilMaxVObjs]'>
	self cCode: [] inSmalltalk: [stack := CArrayAccessor on: (Array new: OilMaxVObjs)].
	stack at: 0 put: v0.
	sp := 1.
	[sp > 0] whileTrue:
		[sp := sp - 1.
		 v := stack at: sp.
		 ((vobjSelfKind at: v) = OilDescReg and: [(vobjSelfValue at: v) = r]) ifTrue: [^true].
		 base := vobjCopiedBase at: v.
		 0 to: (vobjNumCopied at: v) - 1 do:
			[:j|
			k := capturedKind at: base + j.
			(k = OilDescReg and: [(capturedValue at: base + j) = r]) ifTrue: [^true].
			(k = OilDescBlock and: [sp < OilMaxVObjs]) ifTrue:
				[stack at: sp put: (capturedValue at: base + j).
				 sp := sp + 1]]].
	^false! !

!OilCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
newVObj: kind
	| v |
	numVObjs >= OilMaxVObjs ifTrue:
		[self abortCompilation: OilFailTooManyVirtualObjects.
		 ^0].
	v := numVObjs.
	numVObjs := v + 1.
	vobjKind at: v put: kind.
	vobjNumCopied at: v put: 0.
	vobjCopiedBase at: v put: capturedTop.
	vobjSize at: v put: 0.
	vobjSlotBase at: v put: 0.
	vobjSelfClass at: v put: 0.
	^v! !

!OilCompiler methodsFor: 'stores' stamp: 'cb 10/24/2026 10:30'!
storeTopIntoReg: r pop: popFlag
	"Store the top of stack into r, a named temp or a scalar replaced temp vector slot.
	 Constants and virtual temp vectors are stored as descriptors; a value just computed into the stack top
	 is retargeted to r instead of being moved."
	| top k v |
	top := simStackTop.
	(slotKind at: top) = OilDescCond ifTrue: [self materializeSlot: top].
	k := slotKind at: top.
	v := slotValue at: top.
	(k = OilDescReg and: [v = r]) ifTrue: "x := x"
		[popFlag ifTrue: [simStackTop := top - 1].
		 ^self].
	self invalidateAliasesOf: r.
	k = OilDescBlock ifTrue:
		[^self requireEagerClosures].
	k = OilDescTempVector
		ifTrue:
			[((slotFlags at: r) bitAnd: OilFlagTVSlot) ~= 0 ifTrue:
				[^self requireEagerClosures].
			 self setSlot: r kind: k value: v]
		ifFalse:
			[k = OilDescConst
				ifTrue:
					[self setSlot: r kind: k value: v.
					 regVersion at: r put: (regVersion at: r) + 1.
					 affineBase at: r put: -1.
					 knownClass at: r put: 0]
				ifFalse:
					[(v = top and: [self retarget: top to: r]) ifFalse:
						[self emitMove: r from: v].
					 self setOwn: r]].
	popFlag
		ifTrue: [simStackTop := top - 1]
		ifFalse:
			[(slotKind at: r) = OilDescReg
				ifTrue: [self setSlot: top kind: OilDescReg value: r]
				ifFalse: [self setSlot: top kind: (slotKind at: r) value: (slotValue at: r)]]! !

!OilCompiler methodsFor: 'stores' stamp: 'cb 10/24/2026 10:30'!
genStoreRcvrVar: index pop: popFlag frame: f
	| val rcvr |
	index > 255 ifTrue: [^self abortCompilation: OilFailUnsupportedBytecode].
	val := self regForSlot: simStackTop.
	rcvr := self selfRegOfFrame: f scratch: simStackTop + 1.
	self recordSite: OilSiteStore. "the store fails on an immutable object: the interpreter retries it"
	self emitOp: OilStoreField a: val b: rcvr c: index.
	popFlag ifTrue: [simStackTop := simStackTop - 1]! !

!OilCompiler methodsFor: 'stores' stamp: 'cb 10/24/2026 10:30'!
genStoreLitVar: index pop: popFlag frame: f
	"Store into a global/class variable's binding (value is slot 1 of the binding)."
	| val scratch |
	val := self regForSlot: simStackTop.
	scratch := simStackTop + 1.
	self emitConst: (self literalHandle: index frame: f) into: scratch.
	self recordSite: OilSiteStore.
	self emitOp: OilStoreField a: val b: scratch c: 1.
	popFlag ifTrue: [simStackTop := simStackTop - 1]! !

!OilCompiler methodsFor: 'stores' stamp: 'cb 10/24/2026 10:30'!
genStoreRemoteTemp: index inVector: vectorIndex pop: popFlag frame: f
	| vr val vec |
	vr := self tempReg: vectorIndex frame: f.
	(slotKind at: vr) = OilDescTempVector ifTrue:
		[^self storeTopIntoReg: (vobjSlotBase at: (slotValue at: vr)) + index pop: popFlag].
	val := self regForSlot: simStackTop.
	vec := self regForSlot: vr.
	self recordSite: OilSiteStore.
	self emitOp: OilStoreField a: val b: vec c: index.
	popFlag ifTrue: [simStackTop := simStackTop - 1]! !

!OilCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
selfRegOfFrame: f scratch: scratch
	^self regForKind: (frameSelfKind at: f) value: (frameSelfValue at: f) scratch: scratch! !

!OilCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
genPushTemp: index frame: f
	| r k |
	r := self tempReg: index frame: f.
	k := slotKind at: r.
	self push: k value: (slotValue at: r)! !

!OilCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
genDup
	| top |
	top := simStackTop.
	(slotKind at: top) = OilDescCond ifTrue: [self materializeSlot: top].
	self push: (slotKind at: top) value: (slotValue at: top)! !

!OilCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
genPushRcvrVar: index frame: f
	| dest rcvr idx |
	index > 255 ifTrue: [^self abortCompilation: OilFailUnsupportedBytecode].
	dest := self pushOwnSlot.
	rcvr := self selfRegOfFrame: f scratch: dest.
	idx := self emitOp: OilLoadField a: dest b: rcvr c: index.
	self noteDef: dest at: idx! !

!OilCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
genPushLitVar: index frame: f
	"Read-only bindings (classes) fold to their value; other globals load slot 1 (value) of their binding."
	| binding dest idx |
	binding := self oilLiteral: index ofMethod: (frameMethod at: f).
	(self isReadOnlyBinding: binding) ifTrue:
		[^self push: OilDescConst value: (self bindingValueHandle: binding)].
	dest := self pushOwnSlot.
	self emitConst: (self handleFor: binding) into: dest.
	idx := self emitOp: OilLoadField a: dest b: dest c: 1.
	self noteDef: dest at: idx! !

!OilCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
genPushNewArray: size pop: popFlag
	"A brace array {a. b} is allocated.  A temp vector (Array new: n, created by the bytecode compiler for
	 temps assigned in closures) is scalar replaced: its slots become high registers."
	| first dest idx v base |
	popFlag ifTrue:
		[first := simStackTop - size + 1.
		 first to: simStackTop do: [:i| self materializeSlot: i].
		 simStackTop := first - 1.
		 dest := self pushOwnSlot.
		 idx := self emitOp: OilNewArray a: dest b: first c: size.
		 self noteDef: dest at: idx.
		 ^self].
	eagerClosures ifTrue:
		[dest := self pushOwnSlot.
		 idx := self emitOp: OilNewArray a: dest b: OilFlagsReg c: size.
		 self noteDef: dest at: idx.
		 ^self].
	base := highRegTop - size + 1.
	base <= (simStackTop + 32) ifTrue:
		[^self abortCompilation: OilFailOutOfRegisters].
	v := self newVObj: OilDescTempVector.
	vobjSize at: v put: size.
	vobjSlotBase at: v put: base.
	highRegTop := base - 1.
	base to: base + size - 1 do:
		[:h|
		slotFlags at: h put: OilFlagTVSlot.
		self setSlot: h kind: OilDescConst value: nilHandle].
	self push: OilDescTempVector value: v! !

!OilCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
genPushRemoteTemp: index inVector: vectorIndex frame: f
	| vr h vec dest idx |
	vr := self tempReg: vectorIndex frame: f.
	(slotKind at: vr) = OilDescTempVector ifTrue:
		[h := (vobjSlotBase at: (slotValue at: vr)) + index.
		 ^self push: (slotKind at: h) value: (slotValue at: h)].
	vec := self regForSlot: vr.
	dest := self pushOwnSlot.
	idx := self emitOp: OilLoadField a: dest b: vec c: index.
	self noteDef: dest at: idx! !

!OilCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
genPushFullClosure: literalIndex flags: flags frame: f
	"SistaV1 pushFullClosure.  flags = siyyyyyy: yyyyyy numCopied, s receiverOnStack, i ignoreOuterContext.
	 Normally the closure stays virtual (no allocation): its copied values are captured as descriptors.
	 In eager mode it is materialized with OilMakeClosure."
	| block numCopied rcvrOnStack first lowest selfReg dest idx v |
	block := self oilLiteral: literalIndex ofMethod: (frameMethod at: f).
	numCopied := flags bitAnd: 63.
	rcvrOnStack := (flags bitAnd: 128) ~= 0.
	first := simStackTop - numCopied + 1.
	lowest := rcvrOnStack ifTrue: [first - 1] ifFalse: [first].
	eagerClosures ifTrue:
		[lowest to: simStackTop do: [:i| self materializeSlot: i].
		 selfReg := rcvrOnStack
						ifTrue: [first - 1]
						ifFalse: [self selfRegOfFrame: f scratch: simStackTop + 1].
		 simStackTop := lowest - 1.
		 dest := self pushOwnSlot.
		 idx := self emitOp: OilMakeClosure a: dest b: first c: numCopied.
		 self emit64: (self handleFor: block).
		 self emitWord: selfReg.
		 self noteDef: dest at: idx.
		 ^self].
	v := self newVObj: OilDescBlock.
	failed ifTrue: [^self].
	vobjLiteral at: v put: block.
	vobjHome at: v put: ((frameIsBlock at: f) ifTrue: [frameHome at: f] ifFalse: [f]).
	vobjOuter at: v put: f. "the frame whose context is the closure's outerContext (deoptimization)"
	rcvrOnStack
		ifTrue:
			[self capture: first - 1 frame: f.
			 capturedTop := capturedTop - 1.
			 vobjSelfKind at: v put: (capturedKind at: capturedTop).
			 vobjSelfValue at: v put: (capturedValue at: capturedTop).
			 vobjSelfClass at: v put: 0]
		ifFalse:
			[vobjSelfKind at: v put: (frameSelfKind at: f).
			 vobjSelfValue at: v put: (frameSelfValue at: f).
			 vobjSelfClass at: v put: (frameSelfClass at: f)].
	vobjCopiedBase at: v put: capturedTop.
	vobjNumCopied at: v put: numCopied.
	first to: simStackTop do: [:i| self capture: i frame: f].
	simStackTop := lowest - 1.
	self push: OilDescBlock value: v! !

!OilCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
capture: i frame: f
	"Append slot i's descriptor to the captured values pool.  A value living in one of the current frame's
	 expression stack registers (about to be reused) is first copied to a stable high register."
	| k v h |
	capturedTop >= OilMaxCaptured ifTrue:
		[^self abortCompilation: OilFailTooManyVirtualObjects].
	(slotKind at: i) = OilDescCond ifTrue: [self materializeSlot: i].
	k := slotKind at: i.
	v := slotValue at: i.
	(k = OilDescReg and: [v >= (frameStackStart at: f) and: [v <= simStackTop]]) ifTrue:
		[h := highRegTop.
		 h <= (simStackTop + 32) ifTrue: [^self abortCompilation: OilFailOutOfRegisters].
		 highRegTop := h - 1.
		 slotFlags at: h put: (OilFlagCapture bitOr: OilFlagImmutable).
		 self emitMove: h from: v.
		 self setOwn: h.
		 v := h].
	capturedKind at: capturedTop put: k.
	capturedValue at: capturedTop put: v.
	capturedTop := capturedTop + 1! !

!OilCompiler methodsFor: 'returns' stamp: 'cb 10/24/2026 10:30'!
genReturnTopNonLocal: isNonLocal frame: f next: next
	| top |
	top := simStackTop.
	simStackTop := top - 1.
	self genReturnKind: (slotKind at: top) value: (slotValue at: top) nonLocal: isNonLocal frame: f next: next! !

!OilCompiler methodsFor: 'returns' stamp: 'cb 10/24/2026 10:30'!
genReturnKind: k value: v nonLocal: isNonLocal frame: f next: next
	<inline: false>
	"Return (k, v) from frame f, or, for a non-local return from an inlined block, from its home frame.
	 From the compiled method this is OilReturn.  From an inlined frame the result is left in the frame's base
	 register (or, for a single final return, kept as a lazy descriptor) and control jumps to the frame's exit."
	| target base r isLast idx |
	oilDeadCode := true.
	target := isNonLocal ifTrue: [frameHome at: f] ifFalse: [f].
	(k = OilDescBlock or: [k = OilDescTempVector]) ifTrue:
		[^self requireEagerClosures].
	target = 0 ifTrue:
		[r := self regForKind: k value: v scratch: simStackTop + 1.
		 self emitOp: OilReturn a: r b: 0 c: 0.
		 ^self].
	(self isFrameActive: target) ifFalse:
		[^self abortCompilation: OilFailInternal].
	base := frameBase at: target.
	isLast := isNonLocal not
				and: [next > (frameEndPC at: f)
				and: [(frameExitChain at: f) = OilNoLink]].
	isLast ifTrue:
		[| kk vv |
		 kk := k. vv := v.
		 (k = OilDescReg and: [v > base and: [v <= highRegTop]]) ifTrue:
			"the value lives in a register of the dying frame: bring it to the result register"
			[(self retarget: v to: base) ifFalse: [self emitMove: base from: v].
			 vv := base].
		 frameHasLazy at: f put: true.
		 frameLazyKind at: f put: kk.
		 frameLazyValue at: f put: vv.
		 ^self].
	k = OilDescReg
		ifTrue: [v ~= base ifTrue: [(self retarget: v to: base) ifFalse: [self emitMove: base from: v]]]
		ifFalse:
			[k = OilDescCond
				ifTrue: [self emitCond: v booleanInto: base]
				ifFalse: [self emitConst: v into: base]].
	self flushTVSlots.
	(isNonLocal not and: [next > (frameEndPC at: f)]) ifTrue:
		"falls through into the exit label"
		[^self].
	idx := self emitOp: OilJump a: 0 imm16: (frameExitChain at: target).
	frameExitChain at: target put: idx! !

!OilCompiler methodsFor: 'jumps' stamp: 'cb 10/24/2026 10:30'!
genJumpTo: target frame: f
	self flushFrame: f.
	self emitBranch: OilJump cond: 0 to: target frame: f.
	oilDeadCode := true! !

!OilCompiler methodsFor: 'jumps' stamp: 'cb 10/24/2026 10:30'!
genJumpIf: aBoolean to: target frame: f
	| top k v r |
	top := simStackTop.
	k := slotKind at: top.
	v := slotValue at: top.
	simStackTop := top - 1.
	k = OilDescCond ifTrue:
		["a lazy comparison result: compare and branch on the flags"
		 pendingCondSlot := -1.
		 self flushFrame: f.
		 self emitCondCompare: v.
		 self emitBranch: (aBoolean ifTrue: [OilBranchTrue] ifFalse: [OilBranchFalse]) cond: OilFlagsReg to: target frame: f.
		 ^self].
	(k = OilDescConst and: [v = trueHandle or: [v = falseHandle]]) ifTrue:
		["constant condition: the branch is folded"
		 numFolds := numFolds + 1.
		 (v = trueHandle) = aBoolean ifTrue:
			[self genJumpTo: target frame: f].
		 ^self].
	r := self regForKind: k value: v scratch: top.
	self flushFrame: f.
	self recordSite: OilSiteBranch. "mustBeBoolean"
	self emitBranch: (aBoolean ifTrue: [OilBranchTrue] ifFalse: [OilBranchFalse]) cond: r to: target frame: f! !

!OilCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
genSpecialSend: index numArgs: n frame: f next: next
	<inline: false>
	"Special selectors: inline tagged SmallInteger arithmetic and comparisons, identity, class; others are ordinary sends.
	 Answer the pc to continue at (a comparison may be fused with the following conditional jump)."
	(index between: 2 and: 7) ifTrue:
		[(self canInlineSmallIntegerOpOn: simStackTop - 1 arg: simStackTop) ifTrue:
			[^self genCompare: index - 1 identity: false frame: f next: next]] "OilCondLt..OilCondNe".
	(index = 22 or: [index = 24]) ifTrue:
		[^self genCompare: (index = 22 ifTrue: [OilCondIdentical] ifFalse: [OilCondNotIdentical]) identity: true frame: f next: next].
	index = 23 ifTrue:
		[(self genClassOf: simStackTop) ifTrue: [^next]].
	((index between: 0 and: 1) or: [index = 8 or: [(index between: 10 and: 15) and: [index ~= 11]]]) ifTrue:
		[(self canInlineSmallIntegerOpOn: simStackTop - 1 arg: simStackTop) ifTrue:
			[(self genArith: index) ifTrue: [^next]]].
	self genSend: (self specialSelectorHandle: index) numArgs: n super: false frame: f.
	^next! !

!OilCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
canInlineSmallIntegerOpOn: a arg: b
	"Speculate SmallInteger arithmetic if the receiver is a SmallInteger constant, is known to be a SmallInteger,
	 or its send site only saw SmallIntegers; the argument must not be a non-SmallInteger constant or a virtual object.
	 The tagged opcodes check their operands' tags and bail out (deopt) on failure or overflow."
	| ka kb r c |
	ka := slotKind at: a.
	kb := slotKind at: b.
	(kb = OilDescBlock or: [kb = OilDescTempVector or: [kb = OilDescCond]]) ifTrue: [^false].
	(kb = OilDescConst and: [(self isSmallIntegerHandle: (slotValue at: b)) not]) ifTrue: [^false].
	ka = OilDescConst ifTrue: [^self isSmallIntegerHandle: (slotValue at: a)].
	ka = OilDescReg ifFalse: [^false].
	r := slotValue at: a.
	(knownClass at: r) = smallIntegerClassHandle ifTrue: [^true].
	"The baseline JIT inlines SmallInteger arithmetic and comparisons and only sends the message for other
	 receivers.  So a send site whose inline cache is still unlinked has only ever seen SmallIntegers: speculate."
	c := self profiledClassAt: currentPC.
	^c = smallIntegerClassHandle
	  or: [c = 0 and: [self isUnlinkedSendAt: currentPC]]! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 14:00'!
isUnlinkedSendAt: pc
	"Has the send at pc in the current frame's method never been sent (no inline cache information at all)?"
	^self
		cCode: [cogit oilSendSiteUnlinkedAt: pc in: (frameMethod at: currentFrame)]
		inSmalltalk:
			[typeFeedback isNil
			 or: [(typeFeedback hasSiteAt: pc in: (frameMethod at: currentFrame)) not]]! !

!OilCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
isKnownSmallInteger: i
	(slotKind at: i) = OilDescConst ifTrue: [^self isSmallIntegerHandle: (slotValue at: i)].
	^(slotKind at: i) = OilDescReg and: [(knownClass at: (slotValue at: i)) = smallIntegerClassHandle]! !

!OilCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
genClassOf: i
	"#class: fold when the receiver's class is known."
	| k c |
	k := slotKind at: i.
	c := k = OilDescConst
			ifTrue: [self classHandleOf: (slotValue at: i)]
			ifFalse: [k = OilDescReg ifTrue: [knownClass at: (slotValue at: i)] ifFalse: [0]].
	c = 0 ifTrue: [^false].
	simStackTop := i - 1.
	self push: OilDescConst value: c.
	numFolds := numFolds + 1.
	^true! !

!OilCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
genSend: selector numArgs: n super: isSuper frame: f
	<inline: false>
	"A message send: inline a virtual block's evaluation, a quick method, an intrinsic primitive or the method
	 itself when the receiver's class is known (constant, established fact, or monomorphic type feedback guarded
	 by OilGuardClass); otherwise emit a call."
	| s k cls guard method prim |
	s := simStackTop - n.
	k := slotKind at: s.
	(k = OilDescBlock and: [isSuper not]) ifTrue:
		[((self isValueSelector: selector numArgs: n)
		  and: [self inlineBlock: (slotValue at: s) receiver: s numArgs: n]) ifTrue: [^self].
		 ^self genCall: selector numArgs: n receiver: s super: false].
	(isSuper not and: [selector = bitXorSelector and: [n = 1
	 and: [self canInlineSmallIntegerOpOn: s arg: s + 1]]]) ifTrue:
		[(self genBitOp: OilXorTagged) ifTrue: [^self]].
	guard := false.
	isSuper
		ifTrue: [cls := self superclassHandleOfMethodClassOf: (frameMethod at: (frameHome at: f))]
		ifFalse:
			[cls := self staticClassOfSlot: s.
			 cls = 0 ifTrue:
				[cls := self profiledClassAt: currentPC.
				 guard := cls ~= 0]].
	cls = 0 ifTrue: [^self genCall: selector numArgs: n receiver: s super: isSuper].
	method := self lookup: selector inClass: cls.
	method = 0 ifTrue: [^self genCall: selector numArgs: n receiver: s super: isSuper].
	prim := self oilPrimitiveIndexOf: method.
	(self oilIsQuickPrimitiveIndex: prim) ifTrue:
		[guard ifTrue: [self emitGuardOn: (self regForSlot: s) class: cls].
		 ^self genQuickMethod: prim receiver: s numArgs: n].
	prim ~= 0 ifTrue:
		[(self canInlineIntrinsic: prim class: cls numArgs: n) ifTrue:
			[guard ifTrue: [self emitGuardOn: (self regForSlot: s) class: cls].
			 self genIntrinsic: prim receiver: s numArgs: n.
			 ^self].
		 ^self genCall: selector numArgs: n receiver: s super: isSuper].
	(self shouldInline: method selector: selector numArgs: n receiver: s) ifTrue:
		[inlineClass := cls.
		 inlineGuard := guard.
		 (self inlineMethod: method receiver: s arguments: n into: s depth: (frameDepth at: f) + 1) ifTrue:
			[^self]].
	self genCall: selector numArgs: n receiver: s super: isSuper! !

!OilCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
staticClassOfSlot: i
	| k |
	k := slotKind at: i.
	k = OilDescConst ifTrue: [^self classHandleOf: (slotValue at: i)].
	k = OilDescReg ifTrue: [^knownClass at: (slotValue at: i)].
	^0! !

!OilCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
isValueSelector: selector numArgs: n
	^n <= 4 and: [(valueSelectors at: n) = selector]! !

!OilCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
isIteratorSelector: selector
	0 to: numIteratorSelectors - 1 do:
		[:i| (iteratorSelectors at: i) = selector ifTrue: [^true]].
	^false! !

!OilCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
isColdSelector: selector
	0 to: numColdSelectors - 1 do:
		[:i| (coldSelectors at: i) = selector ifTrue: [^true]].
	^false! !

!OilCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
shouldInline: method selector: selector numArgs: n receiver: s
	"Inlining policy (see the class comment)."
	| depth size takesBlock |
	depth := (frameDepth at: currentFrame) + 1.
	depth > OilMaxInlineDepth ifTrue: [^false].
	(self isColdSelector: selector) ifTrue: [^false].
	(self isMethodOnInlineStack: method) ifTrue: [^false].
	size := (self oilEndPCOf: method) - (self startPCOf: method) + 1.
	irInstCount + size > irBudget ifTrue: [^false].
	takesBlock := false.
	s + 1 to: s + n do: [:i| (slotKind at: i) = OilDescBlock ifTrue: [takesBlock := true]].
	(takesBlock or: [self isIteratorSelector: selector]) ifTrue:
		[^size <= OilMaxIteratorBytes].
	size <= OilAccessorBytes ifTrue: [^true].
	"A send in a loop (of this frame or of a frame it is inlined in) is hot: inline larger methods deeper."
	(size <= OilMaxIteratorBytes
	 and: [depth <= OilMediumMethodDepth
	 and: [self isInLoopFrame: currentFrame pc: currentPC]]) ifTrue: [^true].
	size <= OilMediumMethodBytes ifTrue: [^depth <= OilMediumMethodDepth].
	^depth <= OilLargeMethodDepth and: [size <= OilMaxIteratorBytes]! !

!OilCompiler methodsFor: 'inlining' stamp: 'cb 10/24/2026 17:00'!
isInLoopFrame: f pc: pc
	"Is pc of frame f inside a loop of its method, or is f inlined (transitively) from a pc inside a loop?"
	| g p |
	g := f.
	p := pc.
	[g >= 0] whileTrue:
		[(pcLoop at: (self pcMapIndex: p frame: g)) ~= 0 ifTrue: [^true].
		 p := frameCallPC at: g.
		 g := frameParent at: g].
	^false! !

!OilCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
genCall: selector numArgs: n receiver: s super: isSuper
	"A non-inlined send: receiver and arguments in consecutive registers s..s+n, result in s.
	 OilCall0 [Op|Dest|Rcvr|0], OilCall1 [Op|Dest|Rcvr|Arg0], OilCallN/OilCallSuper [Op|Dest|Rcvr|NumArgs];
	 then the 64-bit selector; then, for OilCallN/OilCallSuper, the packed argument registers."
	| idx |
	s to: s + n do: [:i| self materializeSlot: i].
	failed ifTrue: [^self].
	self recordSite: OilSiteCall.
	isSuper
		ifTrue:
			[idx := self emitOp: OilCallSuper a: s b: s c: n.
			 self emit64: selector.
			 self emitPackedArgs: s + 1 count: n]
		ifFalse:
			[n = 0 ifTrue:
				[idx := self emitOp: OilCall0 a: s b: s c: 0.
				 self emit64: selector].
			 n = 1 ifTrue:
				[idx := self emitOp: OilCall1 a: s b: s c: s + 1.
				 self emit64: selector].
			 n >= 2 ifTrue:
				[idx := self emitOp: OilCallN a: s b: s c: n.
				 self emit64: selector.
				 self emitPackedArgs: s + 1 count: n]].
	simStackTop := s.
	self setOwn: s.
	self noteDef: s at: idx.
	numCalls := numCalls + 1! !

!OilCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
genQuickMethod: prim receiver: s numArgs: n
	"Quick primitives: 256 ^self, 257 ^true, 258 ^false, 259 ^nil, 260-263 ^-1/0/1/2, 264-519 ^instVar (prim - 264)."
	| k v r dest idx |
	k := slotKind at: s.
	v := slotValue at: s.
	numInlinedQuick := numInlinedQuick + 1.
	prim = 256 ifTrue:
		[simStackTop := s - 1.
		 ^self push: k value: v].
	prim <= 259 ifTrue:
		[simStackTop := s - 1.
		 ^self push: OilDescConst value: (prim = 257 ifTrue: [trueHandle] ifFalse: [prim = 258 ifTrue: [falseHandle] ifFalse: [nilHandle]])].
	prim <= 263 ifTrue:
		[simStackTop := s - 1.
		 ^self push: OilDescConst value: (self handleForSmallInteger: prim - 261)].
	r := self regForSlot: s.
	simStackTop := s - 1.
	dest := self pushOwnSlot.
	idx := self emitOp: OilLoadField a: dest b: r c: prim - 264.
	self noteDef: dest at: idx! !

!OilCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
canInlineIntrinsic: prim class: cls numArgs: n
	"at: (60), at:put: (61) and size (62) of pointer indexable objects without fixed fields (Array), and == (110)."
	prim = 110 ifTrue: [^n = 1].
	((prim = 60 and: [n = 1]) or: [(prim = 61 and: [n = 2]) or: [prim = 62 and: [n = 0]]]) ifFalse: [^false].
	^(self oilInstSpecOfClass: cls) = 2! !

!OilCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
genIntrinsic: prim receiver: s numArgs: n
	<inline: false>
	| arr index val limit dest idx site k v |
	numIntrinsics := numIntrinsics + 1.
	prim = 110 ifTrue:
		[^self genCompare: OilCondIdentical identity: true frame: currentFrame next: -1].
	arr := self regForSlot: s.
	prim = 62 ifTrue:
		[simStackTop := s - 1.
		 dest := self pushOwnSlot.
		 idx := self emitOp: OilLoadSize a: dest b: arr c: 0.
		 self noteDef: dest at: idx.
		 knownClass at: dest put: smallIntegerClassHandle.
		 ^self].
	index := self regForSlot: s + 1.
	prim = 61 ifTrue:
		[k := slotKind at: s + 2.
		 v := slotValue at: s + 2.
		 val := self regForSlot: s + 2].
	limit := s + n + 1.
	idx := self emitOp: OilLoadSize a: limit b: arr c: 0.
	self noteDef: limit at: idx.
	site := self recordSite: OilSiteBounds.
	self emitOp: OilCheckBounds a: index b: limit c: site.
	knownClass at: index put: smallIntegerClassHandle.
	simStackTop := s - 1.
	prim = 60 ifTrue:
		[dest := self pushOwnSlot.
		 idx := self emitOp: OilLoadElement a: dest b: arr c: index.
		 self noteDef: dest at: idx.
		 ^self].
	self recordSite: OilSiteStore.
	self emitOp: OilStoreElement a: val b: arr c: index.
	(k = OilDescReg and: [v = (s + 2)])
		ifTrue:
			[dest := self pushOwnSlot.
			 self emitMove: dest from: val]
		ifFalse: [self push: k value: v]! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
genCompare: cond identity: isIdentity frame: f next: next
	<inline: false>
	"Tagged SmallInteger comparison (or identity comparison).  Folds constants; fuses with a following
	 conditional jump (OilCmpTagged/OilCmpImmTagged + OilBranchTrue/False on the flags, r255);
	 otherwise materializes true/false.  Answer the pc to continue at."
	| a b ka va kb vb c ra rb useImm imm brTag brTarget brNext dest result |
	a := simStackTop - 1.
	b := simStackTop.
	ka := slotKind at: a. va := slotValue at: a.
	kb := slotKind at: b. vb := slotValue at: b.
	c := cond.
	(isIdentity and: [(ka = OilDescBlock or: [ka = OilDescTempVector]) or: [kb = OilDescBlock or: [kb = OilDescTempVector]]]) ifTrue:
		[self requireEagerClosures.
		 ^next].
	(ka = OilDescConst and: [kb = OilDescConst]) ifTrue:
		[result := isIdentity
			ifTrue: [(va = vb) = (c = OilCondIdentical)]
			ifFalse: [self compareSmallInteger: (self smallIntegerValueOf: va) with: (self smallIntegerValueOf: vb) cond: c].
		 simStackTop := a - 1.
		 self push: OilDescConst value: (result ifTrue: [trueHandle] ifFalse: [falseHandle]).
		 numFolds := numFolds + 1.
		 ^next].
	(isIdentity not and: [ka = OilDescConst and: [kb ~= OilDescConst]]) ifTrue:
		["constant on the left: swap the operands and reverse the condition"
		 | tk tv |
		 tk := ka. tv := va. ka := kb. va := vb. kb := tk. vb := tv.
		 c := self reversedCondition: c].
	useImm := isIdentity not
				and: [kb = OilDescConst
				and: [(self smallIntegerValueOf: vb) between: -128 and: 127]].
	ra := self regForKind: ka value: va scratch: a.
	useImm
		ifTrue: [imm := (self smallIntegerValueOf: vb) bitAnd: 255]
		ifFalse: [rb := self regForKind: kb value: vb scratch: b].
	simStackTop := a - 1.
	(next >= 0 and: [self canFuseBranchAt: next frame: f]) ifTrue:
		[brTag := opcodeTag. brTarget := oilTargetPC. brNext := oilNextPC.
		 self flushFrame: f.
		 self emitCompare: c reg: ra reg: rb imm: imm useImm: useImm identity: isIdentity.
		 self emitBranch: (brTag = OilTagJumpTrue ifTrue: [OilBranchTrue] ifFalse: [OilBranchFalse])
			cond: OilFlagsReg to: brTarget frame: f.
		 ^brNext].
	"Not followed by a conditional jump: answer a lazy comparison result (e.g. the result of an inlined block
	 that the caller tests).  It is compared and branched on when consumed by a jump, materialized as
	 true/false otherwise, or as soon as anything else is emitted."
	numConds >= OilMaxConds ifTrue:
		[^self abortCompilation: OilFailTooManyVirtualObjects].
	"The comparison is emitted later, when consumed, but it must bail out to the state at this bytecode:
	 record its deopt site now, its IR index is set when the comparison is emitted (see emitCompare:...)."
	isIdentity
		ifTrue: [condSite at: numConds put: -1]
		ifFalse:
			[| s |
			 s := self recordSite: OilSiteArith.
			 failed ifTrue: [^next].
			 siteIR at: s put: -1.
			 condSite at: numConds put: s].
	condCond at: numConds put: c.
	condRA at: numConds put: ra.
	condRB at: numConds put: (useImm ifTrue: [0] ifFalse: [rb]).
	condImm at: numConds put: (useImm ifTrue: [imm] ifFalse: [0]).
	condUseImm at: numConds put: useImm.
	condIdentity at: numConds put: isIdentity.
	condFrame at: numConds put: currentFrame.
	condPC at: numConds put: currentPC.
	dest := self push: OilDescCond value: numConds.
	pendingCondSlot := dest.
	pendingCondIndex := numConds.
	numConds := numConds + 1.
	^next! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
emitCondCompare: cond
	"Emit the comparison of the lazy comparison result cond (its deopt site is the comparison's bytecode)."
	| savedPC savedFrame savedCond |
	savedPC := currentPC.
	savedFrame := currentFrame.
	currentPC := condPC at: cond.
	currentFrame := condFrame at: cond.
	savedCond := emittingCond.
	emittingCond := cond.
	self emitCompare: (condCond at: cond) reg: (condRA at: cond) reg: (condRB at: cond)
		imm: (condImm at: cond) useImm: (condUseImm at: cond) identity: (condIdentity at: cond).
	emittingCond := savedCond.
	currentPC := savedPC.
	currentFrame := savedFrame! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
emitCond: cond booleanInto: r
	<inline: false>
	"Materialize the lazy comparison result cond as true or false in register r."
	| i1 i2 |
	pendingCondIndex = cond ifTrue: [pendingCondSlot := -1].
	self emitCondCompare: cond.
	i1 := self emitOp: OilBranchFalse a: OilFlagsReg imm16: 0.
	self emitConst: trueHandle into: r.
	i2 := self emitOp: OilJump a: 0 imm16: 0.
	self patchBranch: i1 to: irIndex.
	self emitConst: falseHandle into: r.
	self patchBranch: i2 to: irIndex.
	lastLabelIR := irIndex.
	knownClass at: r put: 0! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
materializePendingCond
	<inline: false>
	| s |
	s := pendingCondSlot.
	pendingCondSlot := -1.
	(s <= simStackTop and: [(slotKind at: s) = OilDescCond and: [(slotValue at: s) = pendingCondIndex]]) ifTrue:
		[self emitCond: pendingCondIndex booleanInto: s.
		 self setOwn: s]! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
reversedCondition: c
	"The condition c with its operands swapped: x < y iff y > x."
	c = OilCondLt ifTrue: [^OilCondGt].
	c = OilCondGt ifTrue: [^OilCondLt].
	c = OilCondLe ifTrue: [^OilCondGe].
	c = OilCondGe ifTrue: [^OilCondLe].
	^c! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
canFuseBranchAt: pc frame: f
	"Is the instruction at pc (in frame f) a conditional jump that is not itself a branch target?"
	pc > (frameEndPC at: f) ifTrue: [^false].
	(pcTarget at: (self pcMapIndex: pc frame: f)) ~= 0 ifTrue: [^false].
	self setScanMethod: (frameMethod at: f).
	self decodeAt: pc.
	^opcodeTag = OilTagJumpTrue or: [opcodeTag = OilTagJumpFalse]! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
emitCompare: cond reg: ra reg: rb imm: imm useImm: useImm identity: isIdentity
	isIdentity ifFalse:
		[emittingCond >= 0
			ifTrue: [self useCondSite: (condSite at: emittingCond)]
			ifFalse: [self recordSite: OilSiteArith]].
	useImm
		ifTrue: [self emitOp: OilCmpImmTagged a: cond b: ra c: imm]
		ifFalse: [self emitOp: OilCmpTagged a: cond b: ra c: rb]! !

!OilCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/24/2026 14:00'!
useCondSite: s
	"The comparison of a lazy comparison result is about to be emitted: bind its deopt site, recorded when the
	 comparison was translated, to the instruction.  If it was already bound (the comparison is emitted again,
	 e.g. materialized on two paths) clone the site, sharing its recorded state."
	| n |
	s < 0 ifTrue: [^self].
	"Another pending lazy comparison would be materialized by the next emitOp:, shifting the IR index."
	(pendingCondSlot >= 0 and: [pendingCondIndex ~= emittingCond]) ifTrue:
		[self materializePendingCond].
	(siteIR at: s) = -1 ifTrue:
		[siteIR at: s put: irIndex.
		 ^self].
	n := numSites.
	n >= OilMaxSites ifTrue:
		[^self abortCompilation: OilFailTooManySites].
	siteIR at: n put: irIndex.
	siteFrame at: n put: (siteFrame at: s).
	sitePC at: n put: (sitePC at: s).
	siteKind at: n put: (siteKind at: s).
	siteSnapBase at: n put: (siteSnapBase at: s).
	siteSnapTop at: n put: (siteSnapTop at: s).
	siteSnapHigh at: n put: (siteSnapHigh at: s).
	numSites := n + 1! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
compareSmallInteger: x with: y cond: c
	c = OilCondLt ifTrue: [^x < y].
	c = OilCondGt ifTrue: [^x > y].
	c = OilCondLe ifTrue: [^x <= y].
	c = OilCondGe ifTrue: [^x >= y].
	c = OilCondEq ifTrue: [^x = y].
	^x ~= y! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
genArith: index
	<inline: false>
	"Special selector arithmetic on (speculated) SmallIntegers: + - * \\ bitShift: // bitAnd: bitOr:.
	 Answer false if not inlinable (the caller then emits an ordinary send)."
	| a b |
	a := simStackTop - 1.
	b := simStackTop.
	((slotKind at: a) = OilDescConst and: [(slotKind at: b) = OilDescConst]) ifTrue:
		[(self foldArith: index) ifTrue: [^true]].
	index = 0 ifTrue: [^self genAdd].
	index = 1 ifTrue: [^self genSub].
	index = 8 ifTrue: [^self genMul].
	index = 10 ifTrue: [^self genMod].
	index = 12 ifTrue: [^self genBitShift].
	index = 13 ifTrue: [^self genDiv].
	index = 14 ifTrue: [^self genBitOp: OilAndTagged].
	index = 15 ifTrue: [^self genBitOp: OilOrTagged].
	^false! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
foldArith: index
	"Constant fold SmallInteger arithmetic when the result is a SmallInteger."
	| a x y r |
	a := simStackTop - 1.
	x := self smallIntegerValueOf: (slotValue at: a).
	y := self smallIntegerValueOf: (slotValue at: simStackTop).
	r := index caseOf: {
		[0] -> [x + y].
		[1] -> [x - y].
		[8] -> [x * y].
		[10] -> [y = 0 ifTrue: [^false]. x \\ y].
		[12] -> [(y between: -64 and: 64) ifFalse: [^false]. x bitShift: y].
		[13] -> [y = 0 ifTrue: [^false]. x // y].
		[14] -> [x bitAnd: y].
		[15] -> [x bitOr: y].
		[18] -> [x bitXor: y] }
		otherwise: [^false].
	(self isSmallIntegerValue: r) ifFalse: [^false].
	simStackTop := a - 1.
	self push: OilDescConst value: (self handleForSmallInteger: r).
	numFolds := numFolds + 1.
	^true! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
genAdd
	| a b |
	a := simStackTop - 1.
	b := simStackTop.
	(slotKind at: b) = OilDescConst ifTrue:
		[^self genAddConstant: (self smallIntegerValueOf: (slotValue at: b)) to: a result: a].
	(slotKind at: a) = OilDescConst ifTrue: "commutative: c + x"
		[^self genAddConstant: (self smallIntegerValueOf: (slotValue at: a)) to: b result: a].
	^self genBinaryTagged: OilAddTagged! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
genSub
	| b |
	b := simStackTop.
	(slotKind at: b) = OilDescConst ifTrue:
		[^self genAddConstant: (self smallIntegerValueOf: (slotValue at: b)) negated to: b - 1 result: b - 1].
	^self genBinaryTagged: OilSubTagged! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
genBinaryTagged: op
	"Dest := Src1 op Src2 on tagged SmallIntegers (implicit tag/overflow checks, deopt on failure)."
	| a b ra rb dest idx |
	a := simStackTop - 1.
	b := simStackTop.
	ra := self regForSlot: a.
	rb := self regForSlot: b.
	simStackTop := a - 1.
	dest := self pushOwnSlot.
	self recordSite: OilSiteArith.
	idx := self emitOp: op a: dest b: ra c: rb.
	self noteDef: dest at: idx.
	knownClass at: dest put: smallIntegerClassHandle.
	^true! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
genAddConstant: c to: operandSlot result: resultSlot
	"x + c with on-the-fly reduction: x + 0 => x; if x = y + c1 (an affine fact still valid) then
	 x + c => y + (c1 + c), so (i - 1) + 1 => i and (i + 1) - 1 => i (no instruction) and (x + c1) - c2 => x + (c1 - c2).
	 Tagged: Tagged(x) + 8c, emitted as OilAddImmTagged when c fits 8 signed bits."
	| k v xr base total dest idx scratch |
	k := slotKind at: operandSlot.
	v := slotValue at: operandSlot.
	c = 0 ifTrue:
		[simStackTop := resultSlot - 1.
		 self push: k value: v.
		 numFolds := numFolds + 1.
		 ^true].
	xr := self regForSlot: operandSlot.
	base := xr.
	total := c.
	((affineBase at: xr) >= 0 and: [(affineVersion at: xr) = (regVersion at: (affineBase at: xr))]) ifTrue:
		[base := affineBase at: xr.
		 total := (affineConst at: xr) + c.
		 numFolds := numFolds + 1.
		 (xr >= resultSlot and: [xr <= simStackTop]) ifTrue: "its producer is now dead"
			[self retractIfDeadDefinitionOf: xr]].
	simStackTop := resultSlot - 1.
	total = 0 ifTrue:
		[self push: OilDescReg value: base.
		 ^true].
	dest := self pushOwnSlot.
	(total between: -128 and: 127)
		ifTrue:
			[self recordSite: OilSiteArith.
			 idx := self emitOp: OilAddImmTagged a: dest b: base c: (total bitAnd: 255)]
		ifFalse:
			[scratch := dest + 1.
			 self emitConst: (self handleForSmallInteger: total) into: scratch.
			 self recordSite: OilSiteArith.
			 idx := self emitOp: OilAddTagged a: dest b: base c: scratch].
	self noteDef: dest at: idx.
	affineBase at: dest put: base.
	affineConst at: dest put: total.
	affineVersion at: dest put: (regVersion at: base).
	knownClass at: dest put: smallIntegerClassHandle.
	^true! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
constantPowerOfTwo: c
	"Answer k if c = 2^k (k >= 0), else -1."
	| k |
	c <= 0 ifTrue: [^-1].
	(c bitAnd: c - 1) = 0 ifFalse: [^-1].
	k := 0.
	[(1 bitShift: k) < c] whileTrue: [k := k + 1].
	^k! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
replaceOperandsBy: k value: v
	"Pop receiver and argument, push (k, v)."
	simStackTop := simStackTop - 2.
	self push: k value: v.
	numFolds := numFolds + 1.
	^true! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
emitShift: k of: x into: dest
	"OilShiftTagged: k > 0 arithmetic right shift (exact floor division by 2^k: sarq 3+k, shlq 3, orq 1);
	 k < 0 left shift by -k (multiplication by 2^-k, overflow checked)."
	| idx |
	self recordSite: OilSiteArith.
	idx := self emitOp: OilShiftTagged a: dest b: x c: (k bitAnd: 255).
	self noteDef: dest at: idx.
	knownClass at: dest put: smallIntegerClassHandle! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
genMul
	"x * 1 => x; x * 0 => 0 (x known SmallInteger); x * 2^k => x << k; x * (2^k + 1) => (x << k) + x (e.g. x * 9);
	 x * (2^k - 1) => (x << k) - x (e.g. x * 31, hash codes).  Otherwise an ordinary send."
	| a b xs c k x scratch dest idx |
	a := simStackTop - 1.
	b := simStackTop.
	(slotKind at: b) = OilDescConst
		ifTrue: [xs := a. c := self smallIntegerValueOf: (slotValue at: b)]
		ifFalse:
			[(slotKind at: a) = OilDescConst ifFalse: [^false].
			 xs := b. c := self smallIntegerValueOf: (slotValue at: a)].
	c = 1 ifTrue: [^self replaceOperandsBy: (slotKind at: xs) value: (slotValue at: xs)].
	c = 0 ifTrue:
		[(self isKnownSmallInteger: xs) ifFalse: [^false].
		 ^self replaceOperandsBy: OilDescConst value: (self handleForSmallInteger: 0)].
	c < 0 ifTrue: [^false].
	x := self regForSlot: xs.
	scratch := xs = a ifTrue: [b] ifFalse: [a].
	(k := self constantPowerOfTwo: c) > 0 ifTrue:
		[simStackTop := a - 1.
		 dest := self pushOwnSlot.
		 self emitShift: k negated of: x into: dest.
		 ^true].
	(k := self constantPowerOfTwo: c - 1) > 0 ifTrue:
		[self emitShift: k negated of: x into: scratch.
		 simStackTop := a - 1.
		 dest := self pushOwnSlot.
		 self recordSite: OilSiteArith.
		 idx := self emitOp: OilAddTagged a: dest b: scratch c: x.
		 self noteDef: dest at: idx.
		 knownClass at: dest put: smallIntegerClassHandle.
		 ^true].
	(k := self constantPowerOfTwo: c + 1) > 1 ifTrue:
		[self emitShift: k negated of: x into: scratch.
		 simStackTop := a - 1.
		 dest := self pushOwnSlot.
		 self recordSite: OilSiteArith.
		 idx := self emitOp: OilSubTagged a: dest b: scratch c: x.
		 self noteDef: dest at: idx.
		 knownClass at: dest put: smallIntegerClassHandle.
		 ^true].
	^false! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
genDiv
	"x // 1 => x; x // 2^k => arithmetic right shift by k (floor division, no idiv)."
	| a b c k x dest |
	a := simStackTop - 1.
	b := simStackTop.
	(slotKind at: b) = OilDescConst ifFalse: [^false].
	c := self smallIntegerValueOf: (slotValue at: b).
	c = 1 ifTrue: [^self replaceOperandsBy: (slotKind at: a) value: (slotValue at: a)].
	(k := self constantPowerOfTwo: c) > 0 ifFalse: [^false].
	x := self regForSlot: a.
	simStackTop := a - 1.
	dest := self pushOwnSlot.
	self emitShift: k of: x into: dest.
	^true! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
genMod
	"x \\ 2 => OilOddTagged ((x bitAnd: 8) bitOr: 1 on the tagged value: no division, no branch);
	 x \\ 2^k => x bitAnd: 2^k - 1 (floored modulo by a positive power of two);
	 otherwise OilModTagged (a division; bails out on a zero divisor)."
	| a b c k x dest idx scratch |
	a := simStackTop - 1.
	b := simStackTop.
	(slotKind at: b) = OilDescConst ifFalse: [^self genBinaryTagged: OilModTagged].
	c := self smallIntegerValueOf: (slotValue at: b).
	c = 0 ifTrue: [^false]. "ZeroDivide: send it"
	(k := self constantPowerOfTwo: c) > 0 ifFalse: [^self genBinaryTagged: OilModTagged].
	x := self regForSlot: a.
	c = 2 ifTrue:
		[simStackTop := a - 1.
		 dest := self pushOwnSlot.
		 self recordSite: OilSiteArith.
		 idx := self emitOp: OilOddTagged a: dest b: x c: 0.
		 self noteDef: dest at: idx.
		 knownClass at: dest put: smallIntegerClassHandle.
		 ^true].
	scratch := b.
	self emitConst: (self handleForSmallInteger: c - 1) into: scratch.
	simStackTop := a - 1.
	dest := self pushOwnSlot.
	self recordSite: OilSiteArith.
	idx := self emitOp: OilAndTagged a: dest b: x c: scratch.
	self noteDef: dest at: idx.
	knownClass at: dest put: smallIntegerClassHandle.
	^true! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
genBitShift
	"x bitShift: 0 => x; x bitShift: k => OilShiftTagged (left for k > 0, arithmetic right for k < 0)."
	| a b k x dest |
	a := simStackTop - 1.
	b := simStackTop.
	(slotKind at: b) = OilDescConst ifFalse: [^false].
	k := self smallIntegerValueOf: (slotValue at: b).
	k = 0 ifTrue: [^self replaceOperandsBy: (slotKind at: a) value: (slotValue at: a)].
	(k between: -60 and: 60) ifFalse: [^false].
	x := self regForSlot: a.
	simStackTop := a - 1.
	dest := self pushOwnSlot.
	self emitShift: k negated of: x into: dest.
	^true! !

!OilCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
genBitOp: op
	"bitAnd:/bitOr:/bitXor: directly on tagged values: (8a+1) & (8b+1) = 8(a&b)+1, (8a+1) | (8b+1) = 8(a|b)+1,
	 so andq/orq need no untagging; xor needs the tag bit restored.
	 Identities: x bitAnd: -1 => x, x bitAnd: 0 => 0 (x known SmallInteger), x bitOr: 0 => x, x bitXor: 0 => x."
	| a b xs ys c |
	a := simStackTop - 1.
	b := simStackTop.
	((slotKind at: a) = OilDescConst and: [(slotKind at: b) = OilDescConst]) ifTrue:
		[op = OilXorTagged ifTrue: [^self foldArith: 18]].
	xs := a. ys := b.
	((slotKind at: a) = OilDescConst and: [(slotKind at: b) ~= OilDescConst]) ifTrue:
		[xs := b. ys := a].
	(slotKind at: ys) = OilDescConst ifTrue:
		[c := self smallIntegerValueOf: (slotValue at: ys).
		 ((c = 0 and: [op ~= OilAndTagged]) or: [c = -1 and: [op = OilAndTagged]]) ifTrue:
			[^self replaceOperandsBy: (slotKind at: xs) value: (slotValue at: xs)].
		 (c = 0 and: [op = OilAndTagged and: [self isKnownSmallInteger: xs]]) ifTrue:
			[^self replaceOperandsBy: OilDescConst value: (self handleForSmallInteger: 0)]].
	^self genBinaryTagged: op! !

!OilCompiler methodsFor: 'inlining' stamp: 'cb 10/24/2026 10:30'!
inlineMethod: aMethod receiver: rcvrReg arguments: numArgs into: resultReg depth: depth
	<inline: false>
	"Inline aMethod, sent to the receiver in rcvrReg with its numArgs arguments in the following registers.
	 The send dissolves: the receiver binds to the inlined method's self, the arguments to its argument registers,
	 its temps follow, and its returns leave the result in resultReg (= rcvrReg) and jump to the exit label.
	 inlineClass is the receiver class used for lookup; if inlineGuard, it is guarded first (OilGuardClass).
	 Answer false (nothing emitted) if aMethod cannot be inlined."
	| f numTemps caller callerPC |
	caller := currentFrame.
	callerPC := currentPC.
	f := self newFrameFor: aMethod base: rcvrReg isBlock: false.
	f < 0 ifTrue: [^false].
	frameDepth at: f put: depth.
	inlineGuard ifTrue: [self emitGuardOn: (self regForSlot: rcvrReg) class: inlineClass].
	frameHome at: f put: f.
	self stabilizeIncomingSlot: rcvrReg.
	slotFlags at: rcvrReg put: OilFlagImmutable.
	frameSelfKind at: f put: (slotKind at: rcvrReg).
	frameSelfValue at: f put: (slotValue at: rcvrReg).
	frameSelfClass at: f put: inlineClass.
	(slotKind at: rcvrReg) = OilDescReg ifTrue:
		[knownClass at: (slotValue at: rcvrReg) put: inlineClass].
	1 to: numArgs do:
		[:i|
		self stabilizeIncomingSlot: rcvrReg + i.
		slotFlags at: rcvrReg + i put: OilFlagImmutable].
	numTemps := self numTempsOf: aMethod.
	rcvrReg + numArgs + 1 to: rcvrReg + numTemps do:
		[:r|
		slotFlags at: r put: OilFlagTemp.
		self setSlot: r kind: OilDescConst value: nilHandle.
		knownClass at: r put: 0.
		affineBase at: r put: -1].
	frameTempStart at: f put: rcvrReg + numArgs + 1.
	frameStackStart at: f put: rcvrReg + numTemps + 1.
	simStackTop := rcvrReg + numTemps.
	numInlinedFrames := numInlinedFrames + 1.
	self translateFrame: f.
	self exitFrame: f.
	currentFrame := caller.
	currentPC := callerPC.
	^true! !

!OilCompiler methodsFor: 'inlining' stamp: 'cb 10/24/2026 10:30'!
inlineBlock: v receiver: closureReg numArgs: numArgs
	<inline: false>
	"Inline the evaluation (value, value:, ...) of the virtual closure v held in closureReg: no closure is
	 allocated and no block activation happens.  The block's arguments bind in place, its copied values bind
	 to the captured descriptors, its self is its home's self, its local return leaves the result in closureReg
	 and its non-local returns return from its (inlined) home frame."
	| block f numCopied base numTemps caller callerPC depth |
	block := vobjLiteral at: v.
	(self numArgsOf: block) = numArgs ifFalse: [^false].
	depth := (frameDepth at: currentFrame) + 1.
	(depth > OilMaxInlineDepth or: [irInstCount >= irBudget]) ifTrue: [^false].
	(self isFrameActive: (vobjHome at: v)) ifFalse: [^false].
	caller := currentFrame.
	callerPC := currentPC.
	f := self newFrameFor: block base: closureReg isBlock: true.
	f < 0 ifTrue: [^false].
	frameVObj at: f put: v.
	frameHome at: f put: (vobjHome at: v).
	frameSelfKind at: f put: (vobjSelfKind at: v).
	frameSelfValue at: f put: (vobjSelfValue at: v).
	frameSelfClass at: f put: (vobjSelfClass at: v).
	slotFlags at: closureReg put: OilFlagImmutable.
	1 to: numArgs do:
		[:i|
		self stabilizeIncomingSlot: closureReg + i.
		slotFlags at: closureReg + i put: OilFlagImmutable].
	numCopied := vobjNumCopied at: v.
	base := vobjCopiedBase at: v.
	0 to: numCopied - 1 do:
		[:j| | r |
		r := closureReg + numArgs + 1 + j.
		slotFlags at: r put: OilFlagImmutable.
		self setSlot: r kind: (capturedKind at: base + j) value: (capturedValue at: base + j)].
	numTemps := self numTempsOf: block.
	closureReg + numArgs + numCopied + 1 to: closureReg + numTemps do:
		[:r|
		slotFlags at: r put: OilFlagTemp.
		self setSlot: r kind: OilDescConst value: nilHandle.
		knownClass at: r put: 0.
		affineBase at: r put: -1].
	frameTempStart at: f put: closureReg + numArgs + numCopied + 1.
	frameStackStart at: f put: closureReg + numTemps + 1.
	simStackTop := closureReg + numTemps.
	numInlinedFrames := numInlinedFrames + 1.
	self translateFrame: f.
	self exitFrame: f.
	currentFrame := caller.
	currentPC := callerPC.
	^true! !

!OilCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
opcodeAt: index
	^(oilIRBuffer at: index) bitShift: -24! !

!OilCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
fieldAAt: index
	^((oilIRBuffer at: index) bitShift: -16) bitAnd: 255! !

!OilCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
fieldBAt: index
	^((oilIRBuffer at: index) bitShift: -8) bitAnd: 255! !

!OilCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
fieldCAt: index
	^(oilIRBuffer at: index) bitAnd: 255! !

!OilCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
imm16At: index
	^(oilIRBuffer at: index) bitAnd: 16rFFFF! !

!OilCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
signed8: byte
	^byte > 127 ifTrue: [byte - 256] ifFalse: [byte]! !

!OilCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
word64At: index
	"The 64-bit operand stored at index (low word) and index + 1 (high word), sign extended."
	| v |
	v := (oilIRBuffer at: index) + ((oilIRBuffer at: index + 1) bitShift: 32).
	^self cCode: [v] inSmalltalk: [v >= (1 bitShift: 63) ifTrue: [v - (1 bitShift: 64)] ifFalse: [v]]! !

!OilCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
instructionLengthAt: index
	| op |
	op := self opcodeAt: index.
	(op = OilConst64 or: [op = OilGuardClass or: [op = OilCall0 or: [op = OilCall1]]]) ifTrue: [^3].
	op = OilMakeClosure ifTrue: [^4].
	(op = OilCallN or: [op = OilCallSuper]) ifTrue: [^3 + ((self fieldCAt: index) + 3 // 4)].
	^1! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
handleFor: anObject
	"In the VM an oop is its own handle.  In the image, SmallIntegers and Characters are tagged exactly like
	 64-bit Spur immediates (8v+1, 8v+2) and other objects get an 8-byte aligned index into a registry."
	| h |
	^self cCode: [anObject] inSmalltalk:
		[anObject isInteger
			ifTrue: [(anObject bitShift: 3) + 1]
			ifFalse:
				[anObject isCharacter
					ifTrue: [(anObject asInteger bitShift: 3) + 2]
					ifFalse:
						[simHandleIndex at: anObject ifAbsent:
							[simHandles addLast: anObject.
							 h := simHandles size bitShift: 3.
							 simHandleIndex at: anObject put: h.
							 h]]]]! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
objectFor: aHandle
	<doNotGenerate>
	(aHandle bitAnd: 7) = 1 ifTrue: [^aHandle bitShift: -3].
	(aHandle bitAnd: 7) = 2 ifTrue: [^Character value: (aHandle bitShift: -3)].
	^simHandles at: (aHandle bitShift: -3)! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
isSmallIntegerHandle: aHandle
	<inline: true>
	^(aHandle bitAnd: 7) = 1! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
smallIntegerValueOf: aHandle
	<inline: true>
	^self cCode: [objectMemory integerValueOf: aHandle] inSmalltalk: [aHandle bitShift: -3]! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
handleForSmallInteger: anInteger
	<inline: true>
	^self cCode: [objectMemory integerObjectOf: anInteger] inSmalltalk: [(anInteger bitShift: 3) + 1]! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
handleForCharacter: anInteger
	<inline: true>
	^self cCode: [objectMemory characterObjectOf: anInteger] inSmalltalk: [(anInteger bitShift: 3) + 2]! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
isSmallIntegerValue: anInteger
	<inline: true>
	^self cCode: [objectMemory isIntegerValue: anInteger] inSmalltalk: [anInteger between: SmallInteger minVal and: SmallInteger maxVal]! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
classHandleOf: aHandle
	^self cCode: [coInterpreter oilApiFetchClassOf: aHandle] inSmalltalk: [self handleFor: (self objectFor: aHandle) class]! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
oilInstSpecOfClass: classHandle
	^self cCode: [coInterpreter oilApiInstSpecOfClass: classHandle] inSmalltalk: [(self objectFor: classHandle) instSpec]! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
oilLiteral: index ofMethod: aMethod
	<inline: true>
	^self cCode: [coInterpreter literal: index ofMethod: aMethod] inSmalltalk: [aMethod literalAt: index + 1]! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
literalHandle: index frame: f
	^self handleFor: (self oilLiteral: index ofMethod: (frameMethod at: f))! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
isReadOnlyBinding: binding
	"Class bindings are read-only: fold them to their value."
	^self cCode: [false] inSmalltalk: [binding isKindOf: ClassBinding]! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
bindingValueHandle: binding
	^self cCode: [objectMemory fetchPointer: 1 ofObject: binding] inSmalltalk: [self handleFor: binding value]! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
specialSelectorHandle: index
	^self cCode: [coInterpreter specialSelector: index] inSmalltalk: [self handleFor: (Smalltalk specialSelectors at: index * 2 + 1)]! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
numArgsOf: aMethod
	<inline: true>
	^self cCode: [coInterpreter argumentCountOf: aMethod] inSmalltalk: [aMethod numArgs]! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
numTempsOf: aMethod
	<inline: true>
	^self cCode: [coInterpreter tempCountOf: aMethod] inSmalltalk: [aMethod numTemps]! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
frameSizeOf: aMethod
	"Slots needed for temps and stack: 16 or 56 (large frame)."
	<inline: true>
	^self
		cCode: [(coInterpreter methodNeedsLargeContext: aMethod) ifTrue: [56] ifFalse: [16]]
		inSmalltalk: [aMethod frameSize]! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
oilPrimitiveIndexOf: aMethod
	<inline: true>
	^self cCode: [coInterpreter primitiveIndexOf: aMethod] inSmalltalk: [aMethod primitive]! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
oilIsQuickPrimitiveIndex: prim
	<inline: true>
	^prim between: 256 and: 519! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
lookup: selector inClass: classHandle
	"Answer the method found by looking up selector in the class, or 0."
	^self
		cCode: [coInterpreter oilApiLookupSelector: selector inClass: classHandle]
		inSmalltalk: [((self objectFor: classHandle) lookupSelector: (self objectFor: selector)) ifNil: [0]]! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
superclassHandleOfMethodClassOf: aMethod
	^self
		cCode: [coInterpreter oilApiSuperclassOf: (coInterpreter methodClassOf: aMethod)]
		inSmalltalk: [self handleFor: aMethod methodClass superclass]! !

!OilCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
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

!OilCompiler class methodsFor: 'translation' stamp: 'cb 10/24/2026 10:30'!
declareCVarsIn: aCCodeGenerator
	"All of Pass 1's memory is static: the 16 KB IR buffer and fixed size tables (BSS), invisible to the GC."
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
	#(frameMethod frameBase frameParent frameHome frameCallPC frameIsBlock frameSelfKind frameSelfValue frameSelfClass frameTempStart frameStackStart frameMaxReg framePCBase frameStartPC frameEndPC frameExitChain frameHasLazy frameLazyKind frameLazyValue frameDepth frameVObj) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilMaxFrames]'].
	"The pc map (per inlined frame bytecode labels) is the largest table: keep it compact (8192 x 6 bytes = 48 KB)."
	aCCodeGenerator var: #pcTarget declareC: 'static unsigned char pcTarget[OilPCMapSize]'.
	aCCodeGenerator var: #pcLabelIR declareC: 'static short pcLabelIR[OilPCMapSize]'.
	aCCodeGenerator var: #pcChain declareC: 'static unsigned short pcChain[OilPCMapSize]'.
	aCCodeGenerator var: #pcDepth declareC: 'static unsigned char pcDepth[OilPCMapSize]'.
	aCCodeGenerator var: #pcLoop declareC: 'static unsigned char pcLoop[OilPCMapSize]'.
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
	#(oilVRegWeight oilVRegReg oilVRegHome) do:
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
	aCCodeGenerator var: #oilBailoutCommon type: #'AbstractInstruction *'.
	aCCodeGenerator var: #oilTraceBuf declareC: 'static sqInt oilTraceBuf[256]'.
	aCCodeGenerator var: #valueSelectors declareC: 'static sqInt valueSelectors[5]'.
	aCCodeGenerator var: #iteratorSelectors declareC: 'static sqInt iteratorSelectors[32]'.
	aCCodeGenerator var: #coldSelectors declareC: 'static sqInt coldSelectors[32] /* OilMaxColdSelectors */'.
	#(typeFeedback simHandles simHandleIndex) do:
		[:var| aCCodeGenerator removeVariable: var]! !
