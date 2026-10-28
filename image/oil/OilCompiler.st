VMStructType subclass: #OilVirtualFrame
	instanceVariableNames: 'method base parent home callPC isBlockFrame selfKind selfValue selfClass tempStart stackStart maxReg pcBase startPC endPC exitChain hasLazy lazyKind lazyValue depth'
	classVariableNames: ''
	poolDictionaries: 'OilInstructionConstants OilConstants'
	category: 'VMMaker-JIT-Oil'!

!OilVirtualFrame commentStamp: 'cb 10/26/2026 23:00' prior: 0!
I am an inlined frame of the method Oil compiles (OilInliningCompiler>>frameAt:): the compiled method itself is frame 0, each method or block inlined into it gets the next one (see newFrameFor:base:isBlock:).  In the VM the frames are a static C array of OilVirtualFrame structs (oilFrames); in the image an Array of instances of me.

method	the CompiledMethod (or CompiledBlock) inlined in this frame
base	the virtual register of its receiver (its arguments and temporaries follow)
parent	the frame that inlined it (-1 for frame 0)
home	the frame of its home method (itself for a method), the target of a block's non-local return
callPC	the pc of the inlined send in its parent
isBlockFrame	whether it is an inlined block
selfKind	the descriptor kind of its receiver (OilDesc*)
selfValue	the descriptor value of its receiver
selfClass	the class of its receiver (0 if unknown)
tempStart	the first virtual register of its temporaries
stackStart	the first virtual register of its operand stack
maxReg	the last virtual register it may use
pcBase	the index of its first bytecode in the pc map
startPC	the pc of its first bytecode
endPC	the pc of its last bytecode
exitChain	the chain of the jumps to its exit (OilNoLink if none)
hasLazy	whether its result is the lazy descriptor below (not yet in a register)
lazyKind	the descriptor kind of its lazy result
lazyValue	the descriptor value of its lazy result
depth	its inlining depth (0 for frame 0)!

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
method
	^method! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
method: anInteger
	^method := anInteger! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
base
	^base! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
base: anInteger
	^base := anInteger! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
parent
	^parent! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
parent: anInteger
	^parent := anInteger! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
home
	^home! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
home: anInteger
	^home := anInteger! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
callPC
	^callPC! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
callPC: anInteger
	^callPC := anInteger! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
isBlockFrame
	^isBlockFrame! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
isBlockFrame: anInteger
	^isBlockFrame := anInteger! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
selfKind
	^selfKind! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
selfKind: anInteger
	^selfKind := anInteger! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
selfValue
	^selfValue! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
selfValue: anInteger
	^selfValue := anInteger! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
selfClass
	^selfClass! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
selfClass: anInteger
	^selfClass := anInteger! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
tempStart
	^tempStart! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
tempStart: anInteger
	^tempStart := anInteger! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
stackStart
	^stackStart! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
stackStart: anInteger
	^stackStart := anInteger! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
maxReg
	^maxReg! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
maxReg: anInteger
	^maxReg := anInteger! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
pcBase
	^pcBase! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
pcBase: anInteger
	^pcBase := anInteger! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
startPC
	^startPC! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
startPC: anInteger
	^startPC := anInteger! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
endPC
	^endPC! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
endPC: anInteger
	^endPC := anInteger! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
exitChain
	^exitChain! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
exitChain: anInteger
	^exitChain := anInteger! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
hasLazy
	^hasLazy! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
hasLazy: anInteger
	^hasLazy := anInteger! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
lazyKind
	^lazyKind! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
lazyKind: anInteger
	^lazyKind := anInteger! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
lazyValue
	^lazyValue! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
lazyValue: anInteger
	^lazyValue := anInteger! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
depth
	^depth! !

!OilVirtualFrame methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
depth: anInteger
	^depth := anInteger! !

!OilVirtualFrame methodsFor: 'initialization' stamp: 'cb 10/26/2026 23:00'!
initialize
	"All my fields start at 0, as in the static C array."
	<doNotGenerate>
	self class instVarNames do: [:ivn| self instVarNamed: ivn put: 0]! !

!OilVirtualFrame class methodsFor: 'translation' stamp: 'cb 10/26/2026 23:00'!
instVarNamesAndTypesForTranslationDo: aBinaryBlock
	"All my fields are sqInts."
	self instVarNames do: [:ivn| aBinaryBlock value: ivn value: #sqInt]! !

!OilVirtualFrame class methodsFor: 'translation' stamp: 'cb 10/26/2026 23:00'!
structTypeName
	^'OilVirtualFrame'! !


VMStructType subclass: #OilVirtualObject
	instanceVariableNames: 'kind literal rcvrKind rcvrValue vobjClass copiedCount copiedBase homeFrame numSlots slotBase outer epoch allocPC materialized'
	classVariableNames: ''
	poolDictionaries: 'OilInstructionConstants OilConstants'
	category: 'VMMaker-JIT-Oil'!

!OilVirtualObject commentStamp: 'cb 10/26/2026 23:00' prior: 0!
I am a virtual object (OilInliningCompiler>>vobjAt:): an object that the compiled code does not allocate unless it escapes (scalar replacement, see newVObj:), a closure (OilDescBlock) or an object whose slots live in virtual registers (OilDescObject, e.g. an Array or a new instance).  Deoptimization rematerializes the virtual objects its frames reference.  In the VM the virtual objects are a static C array of OilVirtualObject structs (oilVObjs); in the image an Array of instances of me.

kind	OilDescBlock or OilDescObject
literal	the CompiledBlock of a closure, or the method allocating an object
rcvrKind	the descriptor kind of the receiver of a closure
rcvrValue	the descriptor value of the receiver of a closure
vobjClass	the class of the receiver of a closure, or the class of an object (0 if unknown)
copiedCount	the number of copied values of a closure
copiedBase	the index of its first copied value in capturedKind/capturedValue
homeFrame	the home frame of a closure
numSlots	the number of slots of an object
slotBase	the virtual register of the first slot of an object
outer	the frame whose context is the closure's outerContext
epoch	the flow epoch (oilFlowEpoch) of its creation
allocPC	the pc of the bytecode that created it
materialized	the virtual register holding its materialized object, or -1!

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
kind
	^kind! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
kind: anInteger
	^kind := anInteger! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
literal
	^literal! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
literal: anInteger
	^literal := anInteger! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
rcvrKind
	^rcvrKind! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
rcvrKind: anInteger
	^rcvrKind := anInteger! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
rcvrValue
	^rcvrValue! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
rcvrValue: anInteger
	^rcvrValue := anInteger! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
vobjClass
	^vobjClass! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
vobjClass: anInteger
	^vobjClass := anInteger! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
copiedCount
	^copiedCount! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
copiedCount: anInteger
	^copiedCount := anInteger! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
copiedBase
	^copiedBase! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
copiedBase: anInteger
	^copiedBase := anInteger! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
homeFrame
	^homeFrame! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
homeFrame: anInteger
	^homeFrame := anInteger! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
numSlots
	^numSlots! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
numSlots: anInteger
	^numSlots := anInteger! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
slotBase
	^slotBase! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
slotBase: anInteger
	^slotBase := anInteger! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
outer
	^outer! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
outer: anInteger
	^outer := anInteger! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
epoch
	^epoch! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
epoch: anInteger
	^epoch := anInteger! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
allocPC
	^allocPC! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
allocPC: anInteger
	^allocPC := anInteger! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
materialized
	^materialized! !

!OilVirtualObject methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
materialized: anInteger
	^materialized := anInteger! !

!OilVirtualObject methodsFor: 'initialization' stamp: 'cb 10/26/2026 23:00'!
initialize
	"All my fields start at 0, as in the static C array."
	<doNotGenerate>
	self class instVarNames do: [:ivn| self instVarNamed: ivn put: 0]! !

!OilVirtualObject class methodsFor: 'translation' stamp: 'cb 10/26/2026 23:00'!
instVarNamesAndTypesForTranslationDo: aBinaryBlock
	"All my fields are sqInts."
	self instVarNames do: [:ivn| aBinaryBlock value: ivn value: #sqInt]! !

!OilVirtualObject class methodsFor: 'translation' stamp: 'cb 10/26/2026 23:00'!
structTypeName
	^'OilVirtualObject'! !


VMStructType subclass: #OilLazyCondition
	instanceVariableNames: 'cond regA regB imm useImm identity frame pc site testClass'
	classVariableNames: ''
	poolDictionaries: 'OilInstructionConstants OilConstants'
	category: 'VMMaker-JIT-Oil'!

!OilLazyCondition commentStamp: 'cb 10/27/2026 12:55' prior: 0!
I am a lazy condition (OilInliningCompiler>>condAt:): a comparison or class test whose boolean result is not materialized until needed, so that a following conditional jump can fuse with it (see pushLazyCond:class:ra:rb:imm:useImm:identity:site: and emitCondCompare:).  In the VM the conditions are a static C array of OilLazyCondition structs (oilConds); in the image an Array of instances of me.

cond	the condition code (OilCond*)
regA	the virtual register of the first operand
regB	the virtual register of the second operand (unless useImm)
imm	the immediate second operand (if useImm)
useImm	whether the second operand is imm
identity	whether the comparison is an identity comparison
frame	the frame of the comparison
pc	the pc of the comparison
site	its deoptimization site, or -1
testClass	the class of a class test (0 for a comparison)!

!OilLazyCondition methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
cond
	^cond! !

!OilLazyCondition methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
cond: anInteger
	^cond := anInteger! !

!OilLazyCondition methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
regA
	^regA! !

!OilLazyCondition methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
regA: anInteger
	^regA := anInteger! !

!OilLazyCondition methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
regB
	^regB! !

!OilLazyCondition methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
regB: anInteger
	^regB := anInteger! !

!OilLazyCondition methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
imm
	^imm! !

!OilLazyCondition methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
imm: anInteger
	^imm := anInteger! !

!OilLazyCondition methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
useImm
	^useImm! !

!OilLazyCondition methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
useImm: anInteger
	^useImm := anInteger! !

!OilLazyCondition methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
identity
	^identity! !

!OilLazyCondition methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
identity: anInteger
	^identity := anInteger! !

!OilLazyCondition methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
frame
	^frame! !

!OilLazyCondition methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
frame: anInteger
	^frame := anInteger! !

!OilLazyCondition methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
pc
	^pc! !

!OilLazyCondition methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
pc: anInteger
	^pc := anInteger! !

!OilLazyCondition methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
site
	^site! !

!OilLazyCondition methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
site: anInteger
	^site := anInteger! !

!OilLazyCondition methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
testClass
	^testClass! !

!OilLazyCondition methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
testClass: anInteger
	^testClass := anInteger! !

!OilLazyCondition methodsFor: 'initialization' stamp: 'cb 10/26/2026 23:00'!
initialize
	"All my fields start at 0, as in the static C array."
	<doNotGenerate>
	self class instVarNames do: [:ivn| self instVarNamed: ivn put: 0]! !

!OilLazyCondition class methodsFor: 'translation' stamp: 'cb 10/26/2026 23:00'!
instVarNamesAndTypesForTranslationDo: aBinaryBlock
	"All my fields are sqInts."
	self instVarNames do: [:ivn| aBinaryBlock value: ivn value: #sqInt]! !

!OilLazyCondition class methodsFor: 'translation' stamp: 'cb 10/26/2026 23:00'!
structTypeName
	^'OilLazyCondition'! !


OilBytecodeScanner subclass: #OilInliningCompiler
	instanceVariableNames: 'oilIRBuffer irIndex irInstCount lastInstIR lastLabelIR irBudget slotKind slotValue slotFlags knownClass lastDefIR simStackTop highRegTop oilFrames oilVObjs oilConds numFrames currentFrame currentPC pcTarget pcLabelIR pcChain pcDepth pcMapTop numVObjs capturedKind capturedValue capturedTop siteIR siteFrame sitePC siteKind numSites oilDeadCode failed failureCode needsRestart eagerClosures nilHandle trueHandle falseHandle smallIntegerClassHandle bitXorSelector valueSelectors coldSelectors numColdSelectors numConds pendingCondSlot pendingCondIndex typeFeedback simHandles simHandleIndex oilHomeMethod receiverClass snapFrame snapPC snapTop snapHighTop snapKind snapValue sitePoolKind sitePoolValue sitePoolTop siteSnapBase siteSnapTop siteSnapHigh emittingCond oilUseWeight oilVRegReg oilVRegSpillTemp oilNumSpillTemps oilIRTarget oilIRLabel oilIRSite oilNumFixups oilFixupJump oilFixupTarget oilNumStubJumps oilStubJump oilStubSite oilSiteResume oilSiteStub oilSiteUsed oilAllocRegs oilNumAllocRegs oilLoopDepth oilFailIndex oilTagged oilIRBuffer1 oilIRBuffer2 oilIRMap oilIRFlag oilIRAux oilVRegDefs oilVRegUses oilPass1Words oilNumRotated oilNumBoundsRemoved oilNumSizesShared oilNumNoCheck oilUndoJump oilUndoSite oilUndoReg oilUndoSrc oilNumUndos oilUseProbe oilUseProbeHit pcLoop oilNumGuardsRemoved oilDisqualified oilNumDisqualified oilDisqualifyLimitValue oilNoInline oilNumNoInline oilRestartNoInline oilXmmVReg oilXmmKind oilXmmChain oilIndexOfAsciiMethod oilSkipSeparatorsMethod oilByteStreamClass oilFlowEpoch oilClassBindingClass oilNumVirtualized oilNumMaterialized oilNumBimorphic oilNumPredicates oilLiveMark oilNumSelects oilEagerPC oilEagerDepth oilRefusePC oilRefuseDepth oilSnapStale oilInlinedSelectors oilNumInlinedSelectors oilMDLiterals oilMDLitHash oilNumMDLiterals oilMDNumBytes oilDefaultColdSelectorNames oilPollPending oilNumPolls oilPollJump oilPollResume oilPollSite oilOpInfo fusedBranchTag fusedBranchTarget fusedBranchNext oilMaxInlineDepthValue oilAccessorBytesValue oilMaxCalleeBytesValue oilMaxSpecializationValue oilUnrollMaxTripsValue oilUnrollFullBudgetValue'
	classVariableNames: ''
	poolDictionaries: 'OilInstructionConstants OilConstants CogAbstractRegisters VMStackFrameOffsets VMObjectIndices VMSqueakClassIndices'
	category: 'VMMaker-JIT-Oil'!

!OilInliningCompiler commentStamp: 'cb 10/25/2026 00:45' prior: 0!
I am the base compiler of Oil, the lightweight compiler for the 64-bit Spur Cog VM (OilBytecodeScanner -> OilInliningCompiler -> OilLoopOptimizer -> OilFullCompiler).  Given the outer (home) method of a hot loop and the class of its receiver, Pass 1 translates its bytecodes, recursively inlining blocks, collection iterators and small methods, into a flat 32-bit compact linear IR in a preallocated static buffer, applying peephole reductions for tagged SmallInteger arithmetic on the fly.  Subclasses add optimization passes in #pipe (OilLoopOptimizer adds Pass 2, the streaming loop optimizer), and Pass 3 (the native backend) generates machine code.  I allocate nothing: every table is a fixed size array (static/BSS memory in the VM, invisible to the GC).

IR format: oilIRBuffer is an array of OilBufferWords (4096) 32-bit words (16 KB).  An instruction is one word [Opcode:8 | Dest:8 | Src1:8 | Src2/Imm:8], possibly followed by a 64-bit operand (2 words, low word first) and packed argument words.  See the OilConstants class comment and OilInliningCompiler>>printIROn: (OilSimulation.st) for the opcode set.  Branch targets are absolute IR word indices.  Instructions that can deoptimize (guards, bounds checks, tagged arithmetic, calls, non-boolean branches) are recorded in a side table of deopt sites (IR index, inlined frame, bytecode pc), and the frame table describes the inlined frames (method, base register, caller frame, call site pc) for the deoptimization metadata.

Virtual registers (256, 8-bit operands) are allocated like a register window: the root method's receiver is r0, its arguments r1..rN, its temporaries follow, then its expression stack.  An inlined method's frame starts at the register holding its receiver on the caller's stack, so arguments are bound in place and the method's result is left in the register the caller expects for the send's result.  Scalar replaced temp vectors live in high registers (allocated downwards from r254); r255 means "condition flags".

Each register has a descriptor (slotKind/slotValue): its own register, an alias of another register, a not yet materialized constant, a virtual (not allocated) closure, or a virtual temp vector.  Expression stack entries are descriptors, which enables constant folding, copy propagation and the dissolving of closures and temp vectors whose blocks are inlined.  At every control flow merge all mutable registers are made canonical (own register), which keeps the linear pass simple and correct without SSA or phis.  If a closure must exist (it escapes), compilation restarts once in eager mode where closures and temp vectors are materialized.

Inlining policy: see shouldInline:selector:numArgs:receiver:.  Receiver classes come from constants, from facts established by guards and inlining, or from type feedback (the inline caches of ProfilingCogit in the VM, simulated execution in the image).  Sends that are not inlined become OilCall0/OilCall1/OilCallN/OilCallSuper/OilCallDirectedSuper or uncommon traps (OilTrap).!

!OilInliningCompiler methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:30'!
initialize
	"Simulation only: in the VM all tables are static (BSS) arrays, see OilCompiler class>>declareCVarsIn:."
	<doNotGenerate>
	super initialize.
	self setUpSimulationTables! !

!OilInliningCompiler methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:30'!
setUpSimulationTables
	<doNotGenerate>
	oilOpInfo := CArrayAccessor on: OilInstructionConstants opInfoTable.
	oilIRBuffer1 := CArrayAccessor on: (WordArray new: OilBufferWords).
	oilIRBuffer2 := CArrayAccessor on: (WordArray new: OilBufferWords).
	oilIRBuffer := oilIRBuffer1.
	slotKind := self newTable: OilNumRegs.
	slotValue := self newTable: OilNumRegs.
	slotFlags := self newTable: OilNumRegs.
	knownClass := self newTable: OilNumRegs.
	lastDefIR := self newTable: OilNumRegs.
	oilFrames := CArrayAccessor on: ((1 to: OilMaxFrames) collect: [:i| OilVirtualFrame new]).
	pcTarget := self newTable: OilPCMapSize.
	pcLabelIR := self newTable: OilPCMapSize.
	pcChain := self newTable: OilPCMapSize.
	pcDepth := self newTable: OilPCMapSize.
	pcLoop := self newTable: OilPCMapSize.
	oilDisqualified := self newTable: OilMaxDisqualified.
	oilNoInline := self newTable: 16.
	oilInlinedSelectors := self newTable: OilMaxInlinedSelectors.
	oilMDLiterals := self newTable: OilMaxMDLiterals.
	oilMDLitHash := self newTable: OilMDLiteralHashSize.
	oilNumNoInline := 0.
	oilNumDisqualified := 0.
	oilVObjs := CArrayAccessor on: ((1 to: OilMaxVObjs) collect: [:i| OilVirtualObject new]).
	capturedKind := self newTable: OilMaxCaptured.
	capturedValue := self newTable: OilMaxCaptured.
	siteIR := self newTable: OilMaxSites.
	siteFrame := self newTable: OilMaxSites.
	sitePC := self newTable: OilMaxSites.
	siteKind := self newTable: OilMaxSites.
	valueSelectors := self newTable: 5.
	coldSelectors := self newTable: OilMaxColdSelectors.
	oilConds := CArrayAccessor on: ((1 to: OilMaxConds) collect: [:i| OilLazyCondition new]).
	snapKind := self newTable: OilNumRegs.
	snapValue := self newTable: OilNumRegs.
	sitePoolKind := self newTable: OilSitePoolSize.
	sitePoolValue := self newTable: OilSitePoolSize.
	siteSnapBase := self newTable: OilMaxSites.
	siteSnapTop := self newTable: OilMaxSites.
	siteSnapHigh := self newTable: OilMaxSites.
	oilNumSelects := 0.
	oilLiveMark := self newTable: OilPCMapSize.
	oilNumVirtualized := oilNumMaterialized := oilNumBimorphic := oilNumPredicates := 0.
	oilIRMap := self newTable: OilBufferWords + 1.
	oilIRFlag := self newTable: OilBufferWords.
	oilIRAux := self newTable: OilBufferWords.
	oilVRegDefs := self newTable: OilNumRegs.
	oilVRegUses := self newTable: OilNumRegs.
	oilTagged := self newTable: OilNumRegs.
	oilLoopDepth := self newTable: OilBufferWords.
	oilIRTarget := self newTable: OilBufferWords.
	oilIRSite := self newTable: OilBufferWords.
	oilPollJump := self newTable: OilMaxPolls.
	oilPollResume := self newTable: OilMaxPolls.
	oilPollSite := self newTable: OilMaxPolls.
	oilXmmVReg := self newTable: OilNumXmms.
	oilXmmKind := self newTable: OilNumXmms.
	simHandles := OrderedCollection new.
	simHandleIndex := IdentityDictionary new.
	irBudget := OilIRBudget.
	oilMaxInlineDepthValue := OilMaxInlineDepth.
	oilAccessorBytesValue := OilAccessorBytes.
	oilMaxCalleeBytesValue := OilMaxCalleeBytes.
	oilMaxSpecializationValue := OilMaxSpecialization.
	oilDisqualifyLimitValue := OilDisqualifyDeopts.
	oilUnrollMaxTripsValue := OilUnrollMaxTrips.
	oilUnrollFullBudgetValue := OilUnrollFullBudget.
	self setUpSimulationHandles.
	self resetForCompilation! !

!OilInliningCompiler methodsFor: 'initialization' stamp: 'cb 10/25/2026 00:45'!
newTable: tableSize
	<doNotGenerate>
	^CArrayAccessor on: (Array new: tableSize withAll: 0)! !

!OilInliningCompiler methodsFor: 'initialization' stamp: 'cb 10/25/2026 00:45'!
setUpSimulationHandles
	"In the VM, nil/true/false/SmallInteger are the object memory's oops (see resetForCompilation) and the special
	 selectors are registered before compilation with registerSelector:kind:.  In the image they are simulated handles (see handleFor:)."
	<doNotGenerate>
	nilHandle := self handleFor: nil.
	trueHandle := self handleFor: true.
	falseHandle := self handleFor: false.
	smallIntegerClassHandle := self handleFor: SmallInteger.
	numColdSelectors := 0.
	#(value value: value:value: value:value:value: value:value:value:value:) doWithIndex:
		[:sel :selIdx| self registerSelector: (self handleFor: sel) kind: selIdx - 1].
	self registerSelector: (self handleFor: #bitXor:) kind: 5.
	"Error paths are cold: never inlined (they would bloat the IR of the hot loop for nothing)."
	#(error: errorNoFreeSpace errorNotFound: errorSubscriptBounds: errorNoSuchElement errorEmptyCollection errorKeyNotFound: errorKeyNotFound errorImproperStore errorNonIntegerIndex errorNotIndexable subclassResponsibility shouldNotImplement notYetImplemented halt halt: deprecated: deprecated signal signal: doesNotUnderstand: cannotReturn: primitiveFailed primitiveFailed:) do:
		[:sel| self registerSelector: (self handleFor: sel) kind: 7].
	"Slow paths are cold too: OrderedCollection>>addLast: inlines its fast path (store, bump) and calls makeRoomAtLast."
	#(makeRoomAtLast makeRoomAtFirst) do:
		[:sel| self registerSelector: (self handleFor: sel) kind: 7].
	"The methods and the stream class of the word-at-a-time byte scans (see genScanIntrinsic:selector:receiver:numArgs:class:guard:)."
	self registerSelector: (ByteString class >> #indexOfAscii:inString:startingAt:) kind: 9.
	self registerSelector: (PositionableStream >> #skipSeparators) kind: 10.
	self registerSelector: (self handleFor: ReadStream) kind: 11! !

!OilInliningCompiler methodsFor: 'initialization' stamp: 'cb 10/25/2026 00:45'!
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
		[^self].
	numColdSelectors < OilMaxColdSelectors ifTrue:
		[coldSelectors at: numColdSelectors put: selector.
		 numColdSelectors := numColdSelectors + 1]! !

!OilInliningCompiler methodsFor: 'initialization' stamp: 'cb 10/26/2026 15:00'!
useDefaultColdSelectors
	"In the VM, recognize the default cold selectors by name (see isColdSelector:)."
	numColdSelectors := -1! !

!OilInliningCompiler methodsFor: 'initialization' stamp: 'cb 10/25/2026 00:45'!
resetSelectorRegistry
	"Forget the registered special selectors (the VM re-registers them before each compilation, since
	 selector oops move when the garbage collector compacts the heap).  In the VM those not registered are recognized by
	 name (see isValueSelector:numArgs:, isColdSelector:)."
	0 to: 4 do: [:selIndex| valueSelectors at: selIndex put: 0].
	bitXorSelector := oilIndexOfAsciiMethod := oilSkipSeparatorsMethod := oilByteStreamClass := 0.
	numColdSelectors := 0! !

!OilInliningCompiler methodsFor: 'initialization' stamp: 'cb 10/25/2026 00:45'!
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
		lastDefIR at: vreg put: -1].
	simStackTop := -1.
	highRegTop := OilMaxReg.
	numFrames := pcMapTop := numVObjs := capturedTop := numSites := numConds := oilNumInlinedSelectors := oilNumMDLiterals := oilMDNumBytes := 0.
	sitePoolTop := 0.
	snapFrame := snapPC := snapTop := snapHighTop := -1.
	emittingCond := -1.
	pendingCondSlot := -1.
	currentFrame := -1.
	currentPC := 0.
	oilDeadCode := failed := needsRestart := oilRestartNoInline := oilSnapStale := false.
	oilFlowEpoch := 0.
	oilClassBindingClass := 0.
	failureCode := OilOK! !

!OilInliningCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
irBudget: anInteger
	irBudget := anInteger! !

!OilInliningCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
typeFeedback: aTypeFeedbackOracle
	<doNotGenerate>
	typeFeedback := aTypeFeedbackOracle! !

!OilInliningCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
failed
	^failed! !

!OilInliningCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
failureCode
	^failureCode! !

!OilInliningCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
eagerClosures
	^eagerClosures! !

!OilInliningCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
irIndex
	^irIndex! !

!OilInliningCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
irInstCount
	^irInstCount! !

!OilInliningCompiler methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:30'!
numFrames
	^numFrames! !

!OilInliningCompiler methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
frameAt: index
	<returnTypeC: #'OilVirtualFrame *'>
	<cmacro: '(index) (&oilFrames[index])'>
	^oilFrames at: index! !

!OilInliningCompiler methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
vobjAt: index
	<returnTypeC: #'OilVirtualObject *'>
	<cmacro: '(index) (&oilVObjs[index])'>
	^oilVObjs at: index! !

!OilInliningCompiler methodsFor: 'accessing' stamp: 'cb 10/26/2026 23:00'!
condAt: index
	<returnTypeC: #'OilLazyCondition *'>
	<cmacro: '(index) (&oilConds[index])'>
	^oilConds at: index! !

!OilInliningCompiler methodsFor: 'compilation' stamp: 'cb 10/24/2026 19:35'!
pipe
	"Optimization pipeline hook between Pass 1 and Pass 3. Subclasses override to add optimization passes."
	<inline: true>
	oilPass1Words := irIndex.
	^OilOK! !

!OilInliningCompiler methodsFor: 'compilation' stamp: 'cb 10/27/2026 14:05'!
compileMethod: aMethod receiverClass: classOop
	"Pass 1: translate aMethod, the outer (home) method of a hot loop, specialized for receivers of class classOop,
	 into the linear IR buffer.  Closures and temp vectors are first kept virtual (dissolved when their blocks are inlined);
	 restarts (up to 12 times) materialize them when one escapes or stop inlining a frame the back end cannot encode.
	 Answer true on success."
	| restarts |
	eagerClosures := false.
	irBudget = 0 ifTrue: [irBudget := OilIRBudget]. "in the VM nothing else initializes it"
	oilMaxInlineDepthValue = 0 ifTrue: [oilMaxInlineDepthValue := OilMaxInlineDepth].
	oilAccessorBytesValue = 0 ifTrue: [oilAccessorBytesValue := OilAccessorBytes].
	oilMaxCalleeBytesValue = 0 ifTrue: [oilMaxCalleeBytesValue := OilMaxCalleeBytes].
	oilNumNoInline := 0.
	oilEagerPC := oilEagerDepth := oilRefusePC := oilRefuseDepth := -1.
	restarts := 0.
	[oilNumVirtualized := oilNumMaterialized := oilNumBimorphic := oilNumPredicates := oilNumSelects := 0.
	 self compileOnce: aMethod receiverClass: classOop.
	 needsRestart and: [restarts < 12]] whileTrue:
		[restarts := restarts + 1.
		 oilRestartNoInline ifFalse:
			[eagerClosures ifTrue: [^false].
			 eagerClosures := true]].
	^failed not! !

!OilInliningCompiler methodsFor: 'compilation' stamp: 'cb 10/25/2026 00:45'!
compileOnce: aMethod receiverClass: classOop
	<inline: false>
	| rootFrame |
	self resetForCompilation.
	oilHomeMethod := aMethod.
	receiverClass := classOop.
	(self oilIsSistaV1Method: aMethod) ifFalse: "Oil only decodes SistaV1: leave the method to the baseline Cogit"
		[^self abortCompilation: OilFailNotSistaV1].
	(self oilIsDisqualified: aMethod) ifTrue: "it deoptimized too often"
		[^self abortCompilation: OilFailDisqualified].
	(self isContextClass: classOop) ifTrue: "see isContextClass:"
		[^self abortCompilation: OilFailUnsupportedBytecode].
	(self oilPrimitiveIndexOf: aMethod) ~= 0 ifTrue:
		[^self abortCompilation: OilFailPrimitiveMethod].
	rootFrame := self newFrameFor: aMethod base: 0 isBlock: false.
	rootFrame < 0 ifTrue:
		[^self abortCompilation: OilFailUnsupportedBytecode].
	(self frameAt: rootFrame) selfKind: OilDescReg.
	(self frameAt: rootFrame) selfValue: 0.
	(self frameAt: rootFrame) selfClass: classOop.
	knownClass at: 0 put: classOop.
	self bindFrame: rootFrame base: 0 numArgs: (self numArgsOf: aMethod) numCopied: 0.
	"The receiver's class is a speculation (inlined self sends are bound to it): guard it at entry.
	 Deoptimizing there resumes the method from its first bytecode in the interpreter."
	currentFrame := rootFrame.
	currentPC := (self frameAt: rootFrame) startPC.
	self takeSnapshotFrame: rootFrame pc: currentPC.
	self emitGuardOn: 0 class: classOop.
	self translateFrame: rootFrame! !

!OilInliningCompiler methodsFor: 'disqualification' stamp: 'cb 10/24/2026 17:30'!
oilDisqualify: aMethod
	"Remember that aMethod deoptimized too often: it will not be compiled again (oilDisqualified is a ring of the
	 last OilMaxDisqualified methods; the entries are only compared, so stale ones after a compaction are harmless)."
	<api>
	(self oilIsDisqualified: aMethod) ifTrue: [^self].
	oilDisqualified at: oilNumDisqualified \\ OilMaxDisqualified put: aMethod.
	oilNumDisqualified := oilNumDisqualified + 1! !

!OilInliningCompiler methodsFor: 'disqualification' stamp: 'cb 10/24/2026 17:30'!
oilDisqualifyLimit
	"The number of deoptimizations after which an Oil method is disqualified (see CoInterpreter>>oilDisqualify:)."
	<api>
	^oilDisqualifyLimitValue > 0 ifTrue: [oilDisqualifyLimitValue] ifFalse: [OilDisqualifyDeopts]! !

!OilInliningCompiler methodsFor: 'disqualification' stamp: 'cb 10/27/2026 14:05'!
oilSetDisqualifyLimit: limit
	"See CoInterpreterPrimitives>>primitiveOilSetDisqualifyLimit."
	<api>
	oilDisqualifyLimitValue := limit! !

!OilInliningCompiler methodsFor: 'disqualification' stamp: 'cb 10/27/2026 14:05'!
oilMaxSpecialization
	"The maximum number of class specializations of a method (1..OilMaxSpecialization)."
	<api>
	^(oilMaxSpecializationValue between: 1 and: OilMaxSpecialization)
		ifTrue: [oilMaxSpecializationValue]
		ifFalse: [OilMaxSpecialization]! !

!OilInliningCompiler methodsFor: 'disqualification' stamp: 'cb 10/27/2026 14:05'!
oilParameterAt: index
	"Get tuning parameter index (or -1 if unknown):
	 1: OilMaxInlineDepth, 2: OilIRBudget, 3: OilAccessorBytes, 4: OilMaxCalleeBytes,
	 5: OilMaxSpecialization (clamped to 1..OilMaxSpecialization), 8: OilDisqualifyDeopts,
	 12: OilUnrollMaxTrips, 14: OilUnrollFullBudget."
	<api>
	index = 1 ifTrue: [^oilMaxInlineDepthValue > 0 ifTrue: [oilMaxInlineDepthValue] ifFalse: [OilMaxInlineDepth]].
	index = 2 ifTrue: [^irBudget > 0 ifTrue: [irBudget] ifFalse: [OilIRBudget]].
	index = 3 ifTrue: [^oilAccessorBytesValue > 0 ifTrue: [oilAccessorBytesValue] ifFalse: [OilAccessorBytes]].
	index = 4 ifTrue: [^oilMaxCalleeBytesValue > 0 ifTrue: [oilMaxCalleeBytesValue] ifFalse: [OilMaxCalleeBytes]].
	index = 5 ifTrue: [^self oilMaxSpecialization].
	index = 8 ifTrue: [^self oilDisqualifyLimit].
	index = 12 ifTrue: [^oilUnrollMaxTripsValue > 0 ifTrue: [oilUnrollMaxTripsValue] ifFalse: [OilUnrollMaxTrips]].
	index = 14 ifTrue: [^oilUnrollFullBudgetValue > 0 ifTrue: [oilUnrollFullBudgetValue] ifFalse: [OilUnrollFullBudget]].
	^-1! !

!OilInliningCompiler methodsFor: 'disqualification' stamp: 'cb 10/27/2026 14:05'!
oilParameterAt: index put: val
	"Set tuning parameter index to val (0 or less resets to the default) and answer the previous value (or -1 if unknown)."
	<api>
	| prev |
	prev := self oilParameterAt: index.
	prev < 0 ifTrue: [^-1].
	index = 1 ifTrue: [oilMaxInlineDepthValue := val].
	index = 2 ifTrue: [irBudget := val > 0 ifTrue: [val min: OilBufferWords - 64] ifFalse: [OilIRBudget]].
	index = 3 ifTrue: [oilAccessorBytesValue := val].
	index = 4 ifTrue: [oilMaxCalleeBytesValue := val].
	index = 5 ifTrue: [oilMaxSpecializationValue := val > 0 ifTrue: [(val max: 1) min: OilMaxSpecialization] ifFalse: [OilMaxSpecialization]].
	index = 8 ifTrue: [oilDisqualifyLimitValue := val].
	index = 12 ifTrue: [oilUnrollMaxTripsValue := val].
	index = 14 ifTrue: [oilUnrollFullBudgetValue := val].
	^prev! !

!OilInliningCompiler methodsFor: 'disqualification' stamp: 'cb 10/25/2026 00:45'!
includes: anItem in: table count: count
	<var: #table type: #'sqInt *'>
	0 to: count - 1 do:
		[:index| (table at: index) = anItem ifTrue: [^true]].
	^false! !

!OilInliningCompiler methodsFor: 'disqualification' stamp: 'cb 10/25/2026 00:45'!
oilIsDisqualified: aMethod
	<api>
	^self includes: aMethod in: oilDisqualified count: (oilNumDisqualified min: OilMaxDisqualified)! !

!OilInliningCompiler methodsFor: 'compilation' stamp: 'cb 10/25/2026 00:45'!
abortCompilation: code
	failed ifFalse: [failureCode := code].
	failed := true! !

!OilInliningCompiler methodsFor: 'compilation' stamp: 'cb 10/25/2026 00:45'!
requireEagerClosures
	"A virtual closure or temp vector must be materialized.  Restart in eager mode (or give up if already eager)."
	eagerClosures
		ifTrue: [self abortCompilation: OilFailEagerClosuresFailed]
		ifFalse:
			["(for debugging: where the first attempt found an escaping closure)"
			 oilEagerPC := currentPC.
			 oilEagerDepth := currentFrame < 0 ifTrue: [-1] ifFalse: [(self frameAt: currentFrame) depth].
			 needsRestart := true. failed := true]! !

!OilInliningCompiler methodsFor: 'frames' stamp: 'cb 10/25/2026 00:45'!
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
	(self frameAt: frameIndex) method: aMethod.
	(self frameAt: frameIndex) base: baseReg.
	(self frameAt: frameIndex) isBlockFrame: isBlock.
	(self frameAt: frameIndex) home: frameIndex.
	(self frameAt: frameIndex) startPC: (self startPCOf: aMethod).
	(self frameAt: frameIndex) endPC: (self oilEndPCOf: aMethod).
	(self frameAt: frameIndex) pcBase: pcMapTop.
	(self frameAt: frameIndex) maxReg: regsNeeded.
	(self frameAt: frameIndex) exitChain: OilNoLink.
	(self frameAt: frameIndex) hasLazy: false.
	(self frameAt: frameIndex) parent: currentFrame.
	(self frameAt: frameIndex) callPC: currentPC.
	(self frameAt: frameIndex) depth: (currentFrame < 0 ifTrue: [0] ifFalse: [(self frameAt: currentFrame) depth + 1]).
	(self preScanFrame: frameIndex) ifFalse: [^-1].
	numFrames := frameIndex + 1.
	pcMapTop := pcMapTop + mapSize.
	^frameIndex! !

!OilInliningCompiler methodsFor: 'frames' stamp: 'cb 10/25/2026 00:45'!
bindFrame: frameIndex base: baseReg numArgs: numArgs numCopied: numCopied
	"Registers of frame frameIndex, whose receiver (or closure) is in baseReg: receiver and arguments are immutable
	 (copied values, bound by the caller, follow the arguments), temps start as nil, then the stack."
	| numTemps firstTemp |
	slotFlags at: baseReg put: OilFlagImmutable.
	1 to: numArgs do:
		[:argIndex|
		self stabilizeIncomingSlot: baseReg + argIndex.
		slotFlags at: baseReg + argIndex put: OilFlagImmutable].
	numTemps := self numTempsOf: (self frameAt: frameIndex) method.
	firstTemp := baseReg + numArgs + numCopied + 1.
	firstTemp to: baseReg + numTemps do:
		[:tempReg|
		slotFlags at: tempReg put: 0.
		self setSlot: tempReg kind: OilDescConst value: nilHandle.
		knownClass at: tempReg put: 0].
	(self frameAt: frameIndex) tempStart: firstTemp.
	(self frameAt: frameIndex) stackStart: baseReg + numTemps + 1.
	simStackTop := baseReg + numTemps! !

!OilInliningCompiler methodsFor: 'frames' stamp: 'cb 10/25/2026 00:45'!
preScanFrame: frameIndex
	"Mark the branch targets of frame frameIndex's method in its pc map region, and the pcs inside loops (pcLoop, from a
	 backward branch's target to the branch).  Answer false if the method contains a bytecode Oil does not translate."
	| pc end start base |
	start := (self frameAt: frameIndex) startPC.
	end := (self frameAt: frameIndex) endPC.
	base := (self frameAt: frameIndex) pcBase.
	base to: base + (end - start) + 1 do:
		[:entryIndex|
		pcTarget at: entryIndex put: 0.
		pcLabelIR at: entryIndex put: -1.
		pcChain at: entryIndex put: OilNoLink.
		pcDepth at: entryIndex put: 0.
		pcLoop at: entryIndex put: 0].
	self setScanMethod: (self frameAt: frameIndex) method.
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

!OilInliningCompiler methodsFor: 'frames' stamp: 'cb 10/25/2026 00:45'!
isFrameActive: frameIndex
	| activeFrame |
	activeFrame := currentFrame.
	[activeFrame >= 0] whileTrue:
		[activeFrame = frameIndex ifTrue: [^true].
		 activeFrame := (self frameAt: activeFrame) parent].
	^false! !

!OilInliningCompiler methodsFor: 'frames' stamp: 'cb 10/25/2026 00:45'!
isMethodOnInlineStack: aMethod
	| activeFrame |
	activeFrame := currentFrame.
	[activeFrame >= 0] whileTrue:
		[(self frameAt: activeFrame) method = aMethod ifTrue: [^true].
		 activeFrame := (self frameAt: activeFrame) parent].
	^false! !

!OilInliningCompiler methodsFor: 'frames' stamp: 'cb 10/24/2026 10:30'!
tempReg: index frame: frameIndex
	<inline: true>
	^(self frameAt: frameIndex) base + 1 + index! !

!OilInliningCompiler methodsFor: 'frames' stamp: 'cb 10/25/2026 00:45'!
pcMapIndex: pc frame: frameIndex
	<inline: true>
	^(self frameAt: frameIndex) pcBase + pc - (self frameAt: frameIndex) startPC! !

!OilInliningCompiler methodsFor: 'frames' stamp: 'cb 10/26/2026 22:05'!
exitFrame: frameIndex
	"Bind the exit label of the inlined frame frameIndex: all its returns leave the result in its base register
	 (or, for a single final return, as a lazy descriptor).  The base register becomes the caller's stack top."
	| baseReg chain |
	baseReg := (self frameAt: frameIndex) base.
	chain := (self frameAt: frameIndex) exitChain.
	currentFrame := (self frameAt: frameIndex) parent.
	currentPC := (self frameAt: frameIndex) callPC.
	chain ~= OilNoLink
		ifTrue:
			["A final jump to the exit label that immediately precedes it is useless, unless a label was bound after it (e.g.
			  the else branch of a final ifTrue:ifFalse: whose arm is empty, like ^self in Number>>abs): the branches to that label
			  were patched to the index after the jump, which would then skip what the caller emits next."
			 (oilDeadCode and: [lastInstIR = chain and: [(self opcodeAt: chain) = OilJump and: [lastLabelIR <= chain]]]) ifTrue:
				[chain := self imm16At: chain.
				 self retractLastInstruction].
			 self patchChain: chain to: irIndex.
			 oilDeadCode := false.
			 self forgetKnowledgeAtLabel.
			 self resetTVSlotsToOwn.
			 self setOwn: baseReg]
		ifFalse:
			[(self frameAt: frameIndex) hasLazy ifTrue:
				[(self frameAt: frameIndex) hasLazy: false. "(consumed: no longer a reference to a scalar replaced object)"
				 self setSlot: baseReg kind: (self frameAt: frameIndex) lazyKind value: (self frameAt: frameIndex) lazyValue.
				 (self isLazyKind: (self frameAt: frameIndex) lazyKind) ifTrue:
					[pendingCondSlot := baseReg.
					 pendingCondIndex := (self frameAt: frameIndex) lazyValue].
				 oilDeadCode := false]].
	simStackTop := baseReg.
	baseReg to: (self frameAt: frameIndex) maxReg do: [:regIndex| slotFlags at: regIndex put: 0].
	pcMapTop := (self frameAt: frameIndex) pcBase! !

!OilInliningCompiler methodsFor: 'translation' stamp: 'cb 10/25/2026 00:45'!
translateFrame: frameIndex
	<inline: false>
	"Translate the bytecodes of frame frameIndex into the IR buffer.  Answer false if compilation failed."
	| pc end next tag op1 op2 target ipc |
	pc := (self frameAt: frameIndex) startPC.
	end := (self frameAt: frameIndex) endPC.
	[pc <= end and: [failed not]] whileTrue:
		[self setScanMethod: (self frameAt: frameIndex) method.
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

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/25/2026 00:45'!
takeSnapshotFrame: frameIndex pc: pc
	"Record the virtual state at the start of the bytecode at pc of frame frameIndex: the descriptors of all live
	 registers (the register window 0..simStackTop, which holds the receivers, temps and stacks of frameIndex and of
	 all the frames inlining it) and of the scalar replaced temp vector slots and captures (high registers).
	 A deopt site recorded while translating this bytecode resumes the interpreter right before it, in this
	 state.  Descriptors are copied: the translation of the bytecode may change them before the site."
	<inline: false>
	snapFrame := frameIndex.
	snapPC := pc.
	oilSnapStale := false.
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

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/25/2026 10:45'!
snapshotRefersTo: reg
	"Answer whether a register descriptor of the current snapshot refers to reg."
	<inline: false>
	0 to: snapTop do:
		[:vreg|
		((snapKind at: vreg) = OilDescReg and: [(snapValue at: vreg) = reg]) ifTrue: [^true]].
	snapHighTop + 1 to: OilMaxReg do:
		[:vreg|
		((snapKind at: vreg) = OilDescReg and: [(snapValue at: vreg) = reg]) ifTrue: [^true]].
	^false! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/25/2026 00:45'!
copySnapshotToSite: siteIndex
	"Append the current snapshot to the site pool for deopt site siteIndex.  A lazy comparison in the snapshot
	 is materialized (in its own register) before the site's instruction is emitted (see recordSite:),
	 so it is recorded as that register."
	| base |
	<inline: false>
	"A lazy comparison of the snapshot that is not (or no longer) materialized in its own register, e.g. the condition
	 genJumpIf:to:frame: consumes when its flush materializes a scalar replaced object, has no value to deoptimize to:
	 record no state (the back end refuses the site)."
	0 to: snapTop do:
		[:vreg|
		((self isLazyKind: (snapKind at: vreg))
		 and: [vreg > simStackTop or: [(slotKind at: vreg) ~= OilDescReg or: [(slotValue at: vreg) ~= vreg]]]) ifTrue:
			[siteSnapBase at: siteIndex put: -1.
			 ^self]].
	base := sitePoolTop.
	base + snapTop + 1 + (OilMaxReg - snapHighTop) > OilSitePoolSize ifTrue:
		[siteSnapBase at: siteIndex put: -1.
		 ^self].
	siteSnapBase at: siteIndex put: base.
	siteSnapTop at: siteIndex put: snapTop.
	siteSnapHigh at: siteIndex put: snapHighTop.
	0 to: snapTop do:
		[:vreg|
		(self isLazyKind: (snapKind at: vreg))
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

!OilInliningCompiler methodsFor: 'translation' stamp: 'cb 10/25/2026 00:45'!
translateTag: tag op1: op1 op2: op2 target: target next: next frame: frameIndex
	<inline: false>
	"Translate one (logical) bytecode.  Answer the pc of the next bytecode to translate."
	| isBlock |
	isBlock := (self frameAt: frameIndex) isBlockFrame.
	tag caseOf: {
		[OilTagPushRcvrVar]		-> [self genPushRcvrVar: op1 frame: frameIndex].
		[OilTagPushLitVar]		-> [self genPushLitVar: op1 frame: frameIndex].
		[OilTagPushLitConst]		-> [self push: OilDescConst value: (self literalHandle: op1 frame: frameIndex)].
		[OilTagPushTemp]			-> [self genPushTemp: op1 frame: frameIndex].
		[OilTagPushSelf]			-> [self push: (self frameAt: frameIndex) selfKind value: (self frameAt: frameIndex) selfValue].
		[OilTagPushTrue]			-> [self push: OilDescConst value: trueHandle].
		[OilTagPushFalse]		-> [self push: OilDescConst value: falseHandle].
		[OilTagPushNil]			-> [self push: OilDescConst value: nilHandle].
		[OilTagPushInteger]		-> [self push: OilDescConst value: (self handleForSmallInteger: op1)].
		[OilTagPushCharacter]	-> [self push: OilDescConst value: (self handleForCharacter: op1)].
		[OilTagDup]				-> [self genDup].
		[OilTagPop]				-> [simStackTop := simStackTop - 1].
		[OilTagNop]				-> [].
		[OilTagReturnSelf]		-> [self genReturnKind: (self frameAt: frameIndex) selfKind value: (self frameAt: frameIndex) selfValue nonLocal: isBlock frame: frameIndex next: next].
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

!OilInliningCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
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
			[self takeSnapshotFrame: frameIndex pc: pc. "(a scalar replaced object materialized by the flush deoptimizes here)"
			 self flushFrame: frameIndex].
	self patchChain: (pcChain at: mapIndex) to: irIndex.
	pcChain at: mapIndex put: OilNoLink.
	pcLabelIR at: mapIndex put: irIndex.
	self forgetKnowledgeAtLabel! !

!OilInliningCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
patchChain: head to: targetIndex
	"Forward branches to a not yet bound label are chained through their 16-bit target fields."
	| link next |
	link := head.
	[link ~= OilNoLink] whileTrue:
		[next := self imm16At: link.
		 self patchBranch: link to: targetIndex.
		 link := next]! !

!OilInliningCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
patchBranch: index to: targetIndex
	oilIRBuffer at: index put: (((oilIRBuffer at: index) bitAnd: 16rFFFF0000) bitOr: (targetIndex bitAnd: 16rFFFF))! !

!OilInliningCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
forgetKnowledgeAtLabel
	"At a merge point, facts established on one path are lost: tagged-arithmetic relations and guarded classes.
	 Only the classes of the active frames' receivers dominate every label (guarded before frame entry)."
	| ancestorFrame |
	lastLabelIR := irIndex.
	oilFlowEpoch := oilFlowEpoch + 1.
	0 to: OilMaxReg do:
		[:regIndex| knownClass at: regIndex put: 0].
	ancestorFrame := currentFrame.
	[ancestorFrame >= 0] whileTrue:
		[(self frameAt: ancestorFrame) selfKind = OilDescReg ifTrue:
			[knownClass at: (self frameAt: ancestorFrame) selfValue put: (self frameAt: ancestorFrame) selfClass].
		 ancestorFrame := (self frameAt: ancestorFrame) parent]! !

!OilInliningCompiler methodsFor: 'labels' stamp: 'cb 10/27/2026 14:05'!
flushFrame: frameIndex
	"Before a branch or a label: make every mutable register of frame frameIndex (temps and stack) and every
	 scalar replaced temp vector slot hold its value in its own register, so that all paths agree."
	"Lazy comparisons first: the deopt state of an allocation (a scalar replaced object materialized below) records them
	 as their registers."
	0 to: simStackTop do:
		[:slotIndex|
		(self isLazyKind: (slotKind at: slotIndex)) ifTrue:
			[self materializeSlot: slotIndex]].
	"The slots of the frames inlining frameIndex are not flushed, but one aliasing a temp vector or scalar replaced object
	 slot register would be copied (invalidateAliasesOf:) on the paths that assign that register only: copy it now."
	0 to: (self frameAt: frameIndex) tempStart - 1 do:
		[:slotIndex|
		((slotKind at: slotIndex) = OilDescReg
		 and: [(slotValue at: slotIndex) ~= slotIndex
		 and: [(self isImmutable: slotIndex) not
		 and: [((slotFlags at: (slotValue at: slotIndex)) bitAnd: OilFlagTVSlot) ~= 0]]]) ifTrue:
			[self materializeSlot: slotIndex]].
	(self frameAt: frameIndex) tempStart to: simStackTop do:
		[:slotIndex| ((self isImmutable: slotIndex) or: [(slotKind at: slotIndex) = OilDescTempVector]) ifFalse:
			[((slotKind at: slotIndex) = OilDescObject
			  and: [slotIndex < (self frameAt: frameIndex) stackStart
			  and: [self isTemp: slotIndex - (self frameAt: frameIndex) base - 1 deadFrom: currentPC frame: frameIndex]]) ifTrue:
				"a scalar replaced object in a dead temp: nil rather than materializing it"
				[self setSlot: slotIndex kind: OilDescConst value: nilHandle].
			 self materializeSlot: slotIndex]].
	self flushTVSlots! !

!OilInliningCompiler methodsFor: 'labels' stamp: 'cb 10/27/2026 14:05'!
flushTVSlots
	"Scalar replaced objects cannot cross control flow (a branch, a merge or an inlined return): materialize any live one
	 anywhere in the register window or temp vector slots."
	0 to: simStackTop do:
		[:slotIndex|
		(slotKind at: slotIndex) = OilDescObject ifTrue:
			[self materializeSlot: slotIndex]].
	self releaseDeadVObjSlots.
	highRegTop + 1 to: OilMaxReg do:
		[:highReg| ((slotFlags at: highReg) bitAnd: OilFlagTVSlot) ~= 0 ifTrue: [self materializeSlot: highReg]]! !

!OilInliningCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
resetMutableSlotsOfFrame: frameIndex
	(self frameAt: frameIndex) tempStart to: simStackTop do:
		[:slotIndex|
		((self isImmutable: slotIndex) or: [(slotKind at: slotIndex) = OilDescTempVector]) ifFalse:
			[self setOwn: slotIndex]].
	self resetTVSlotsToOwn! !

!OilInliningCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
resetTVSlotsToOwn
	highRegTop + 1 to: OilMaxReg do:
		[:highReg| ((slotFlags at: highReg) bitAnd: OilFlagTVSlot) ~= 0 ifTrue: [self setOwn: highReg]]! !

!OilInliningCompiler methodsFor: 'labels' stamp: 'cb 10/24/2026 10:30'!
emitBranch: opcode cond: condReg to: target frame: frameIndex
	"Emit a jump/branch to bytecode pc target of frame frameIndex: backward branches go to a bound label,
	 forward branches are chained until their label is bound."
	| mapIndex labelIndex chainInst |
	mapIndex := self pcMapIndex: target frame: frameIndex.
	target <= currentPC
		ifTrue:
			[labelIndex := pcLabelIR at: mapIndex.
			 labelIndex < 0 ifTrue: [^self abortCompilation: OilFailInternal].
			 self emitOp: opcode a: condReg imm16: labelIndex]
		ifFalse:
			[chainInst := self emitOp: opcode a: condReg imm16: (pcChain at: mapIndex).
			 pcChain at: mapIndex put: chainInst.
			 pcDepth at: mapIndex put: simStackTop]! !

!OilInliningCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
emitOp: opcode a: a b: b c: c
	<inline: false>
	"Append the one word instruction [op | a | b | c].  Answer its index.
	 A pending lazy comparison result is materialized first: nothing may clobber its operands."
	| idx |
	self materializePendingCondIfAny.
	irIndex >= (OilBufferWords - 8) ifTrue:
		[self abortCompilation: OilFailBufferFull.
		 ^0].
	idx := irIndex.
	(self isBranch: opcode) ifTrue:
		[oilFlowEpoch := oilFlowEpoch + 1].
	oilIRBuffer at: idx put: ((opcode bitShift: 24)
								bitOr: (((a bitAnd: 255) bitShift: 16)
								bitOr: (((b bitAnd: 255) bitShift: 8)
								bitOr: (c bitAnd: 255)))).
	irIndex := idx + 1.
	irInstCount := irInstCount + 1.
	lastInstIR := idx.
	^idx! !

!OilInliningCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
emitOp: opcode a: a imm16: imm
	^self emitOp: opcode a: a b: ((imm bitShift: -8) bitAnd: 255) c: (imm bitAnd: 255)! !

!OilInliningCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
emitWord: word
	irIndex < OilBufferWords ifTrue:
		[oilIRBuffer at: irIndex put: (word bitAnd: 16rFFFFFFFF).
		 irIndex := irIndex + 1]! !

!OilInliningCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
emit64: value
	"64-bit operand (an oop: literal, selector, class tag), low word first."
	self emitWord: (value bitAnd: 16rFFFFFFFF).
	self emitWord: ((value bitShift: -32) bitAnd: 16rFFFFFFFF)! !

!OilInliningCompiler methodsFor: 'emitting' stamp: 'cb 10/26/2026 09:30'!
emitPackedArgs: firstReg count: n
	"OilCallN/OilCallSuper/OilCallDirectedSuper argument registers, four 8-bit register numbers per word (unused bytes are 255)."
	| word |
	0 to: n - 1 by: 4 do:
		[:i|
		word := 0.
		0 to: 3 do:
			[:j|
			word := (word bitShift: 8) bitOr: (i + j < n ifTrue: [firstReg + i + j] ifFalse: [255])].
		self emitWord: word]! !

!OilInliningCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
noteDef: virtualReg at: index
	"Register r is (re)defined by the instruction at index."
	lastDefIR at: virtualReg put: index.
	knownClass at: virtualReg put: 0! !

!OilInliningCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
emitConst: handle into: virtualReg
	"OilConstTagged for SmallIntegers whose tagged value fits 16 signed bits, OilConst64 otherwise."
	| idx |
	((self isSmallIntegerHandle: handle)
	 and: [(self smallIntegerValueOf: handle) between: -4096 and: 4095])
		ifTrue:
			[idx := self emitOp: OilConstTagged a: virtualReg imm16: (handle bitAnd: 16rFFFF).
			 self noteDef: virtualReg at: idx.
			 knownClass at: virtualReg put: smallIntegerClassHandle]
		ifFalse:
			[idx := self emitOp: OilConst64 a: virtualReg b: 0 c: 0.
			 self emit64: handle.
			 self noteDef: virtualReg at: idx]! !

!OilInliningCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
emitMove: dst from: src
	| idx |
	dst = src ifTrue: [^self].
	idx := self emitOp: OilMove a: dst b: src c: 0.
	self noteDef: dst at: idx.
	knownClass at: dst put: (knownClass at: src)! !

!OilInliningCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
emitGuardOn: virtualReg class: classOop
	| site |
	site := self recordSite: OilSiteGuard.
	self emitOp: OilGuardClass a: virtualReg imm16: site.
	self emit64: classOop.
	knownClass at: virtualReg put: classOop! !

!OilInliningCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
recordSite: kind
	"Record a deopt site for the instruction about to be emitted: its IR index, the inlined frame and the bytecode pc,
	 plus a copy of the virtual state at the start of that bytecode (see takeSnapshotFrame:pc:).  A pending lazy
	 comparison is materialized first so that the site's IR index is the index of its instruction.  A site recorded
	 outside of the bytecode whose state was snapshotted, or after a register that state refers to was retargeted (see
	 retarget:to:), has no state (siteSnapBase -1): the back end refuses it."
	| siteIndex |
	self materializePendingCondIfAny.
	siteIndex := numSites.
	siteIndex >= OilMaxSites ifTrue:
		[self abortCompilation: OilFailTooManySites.
		 ^0].
	siteIR at: siteIndex put: irIndex.
	siteFrame at: siteIndex put: currentFrame.
	sitePC at: siteIndex put: currentPC.
	siteKind at: siteIndex put: kind.
	(currentFrame = snapFrame and: [currentPC = snapPC and: [oilSnapStale not]])
		ifTrue: [self copySnapshotToSite: siteIndex]
		ifFalse: [siteSnapBase at: siteIndex put: -1].
	numSites := siteIndex + 1.
	^siteIndex! !

!OilInliningCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
retractLastInstruction
	"Delete the last emitted instruction (a one word instruction).  Its deopt site, if any, becomes dead
	 (IR index -2); sites are not removed since a pending lazy comparison site (IR index -1) may follow."
	irIndex := lastInstIR.
	irInstCount := irInstCount - 1.
	numSites - 1 to: 0 by: -1 do:
		[:siteIndex| (siteIR at: siteIndex) >= irIndex ifTrue: [siteIR at: siteIndex put: -2]].
	lastInstIR := -1! !

!OilInliningCompiler methodsFor: 'emitting' stamp: 'cb 10/24/2026 10:30'!
retarget: src to: dst
	"src is a dead expression stack register.  If the last instruction defined it, make it define dst instead.
	 Answer whether this was done (otherwise the caller emits a move)."
	| idx word |
	idx := lastDefIR at: src.
	(idx >= 0 and: [idx = lastInstIR and: [idx >= lastLabelIR]]) ifFalse: [^false].
	(slotFlags at: src) ~= 0 ifTrue: [^false]. "(e.g. a materialized object's register, to which descriptors refer)"
	"the deopt state of this bytecode may refer to src, which no longer receives the value"
	(self snapshotRefersTo: src) ifTrue: [oilSnapStale := true].
	word := oilIRBuffer at: idx.
	(self opcodeHasDest: (word bitShift: -24)) ifFalse: [^false].
	((word bitShift: -16) bitAnd: 255) = src ifFalse: [^false].
	oilIRBuffer at: idx put: ((word bitAnd: 16rFF00FFFF) bitOr: (dst bitShift: 16)).
	lastDefIR at: dst put: idx.
	lastDefIR at: src put: -1.
	knownClass at: dst put: (knownClass at: src).
	^true! !

!OilInliningCompiler methodsFor: 'emitting' stamp: 'cb 10/26/2026 20:30'!
opcode: opcode has: propertyMask
	"Has opcode the OilOp* property (see OilInstructionConstants class>>opInfoSpec)?"
	<inline: true>
	^((oilOpInfo at: opcode) bitAnd: propertyMask) ~= 0! !

!OilInliningCompiler methodsFor: 'emitting' stamp: 'cb 10/26/2026 20:30'!
isSendOpcode: opcode
	"Is opcode a send (OilCall0, OilCall1, OilCallN, OilCallSuper or OilCallDirectedSuper)?"
	<inline: true>
	^self opcode: opcode has: OilOpSend! !

!OilInliningCompiler methodsFor: 'emitting' stamp: 'cb 10/26/2026 20:30'!
opcodeHasDest: opcode
	<inline: true>
	^self opcode: opcode has: OilOpDest! !

!OilInliningCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
setSlot: i kind: kind value: value
	<inline: true>
	slotKind at: i put: kind.
	slotValue at: i put: value! !

!OilInliningCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
setOwn: i
	<inline: true>
	slotKind at: i put: OilDescReg.
	slotValue at: i put: i! !

!OilInliningCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
isImmutable: i
	<inline: true>
	^((slotFlags at: i) bitAnd: OilFlagImmutable) ~= 0! !

!OilInliningCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
push: kind value: value
	| i |
	i := simStackTop + 1.
	i >= highRegTop ifTrue:
		[self abortCompilation: OilFailOutOfRegisters.
		 ^i].
	simStackTop := i.
	slotFlags at: i put: 0.
	self setSlot: i kind: kind value: value.
	^i! !

!OilInliningCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
pushOwnSlot
	"Push a stack entry whose value the caller is about to compute into its own register."
	| newSlot |
	newSlot := self push: OilDescReg value: simStackTop + 1.
	knownClass at: newSlot put: 0.
	^newSlot! !

!OilInliningCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
pushResultOf: opcode b: srcReg1 c: srcReg2 site: aSiteKind
	"Push a stack entry computed into its own register by the one word instruction [opcode | dest | srcReg1 | srcReg2]
	 (which can deoptimize if aSiteKind ~= 0).  Answer the instruction's index (64-bit operands may follow)."
	| destReg instIndex |
	aSiteKind ~= 0 ifTrue: [self recordSite: aSiteKind].
	destReg := self pushOwnSlot.
	instIndex := self emitOp: opcode a: destReg b: srcReg1 c: srcReg2.
	self noteDef: destReg at: instIndex.
	^instIndex! !

!OilInliningCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
pushSmallIntegerResultOf: opcode b: srcReg1 c: srcReg2
	"Tagged SmallInteger arithmetic: deoptimizes on a non-SmallInteger operand or on overflow."
	self pushResultOf: opcode b: srcReg1 c: srcReg2 site: OilSiteArith.
	knownClass at: simStackTop put: smallIntegerClassHandle.
	^true! !

!OilInliningCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
regForKind: descKind value: descValue scratch: scratchReg
	"Answer a register holding the value described by (descKind, descValue), materializing a constant into scratchReg."
	descKind = OilDescReg ifTrue: [^descValue].
	descKind = OilDescConst ifTrue:
		[self emitConst: descValue into: scratchReg.
		 ^scratchReg].
	descKind = OilDescCond ifTrue:
		[self emitCond: descValue booleanInto: scratchReg.
		 ^scratchReg].
	descKind = OilDescObject ifTrue:
		[^self materializeVObj: descValue scratch: scratchReg].
	self requireEagerClosures.
	^scratchReg! !

!OilInliningCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
regForSlot: slotIndex
	"Answer a register holding slotIndex's value.  A constant is materialized in slotIndex's own register
	 (re-materialized at each use if slotIndex is immutable, so that no path dependent state is created)."
	((slotKind at: slotIndex) = OilDescConst and: [self isImmutable: slotIndex]) ifTrue:
		[^self regForKind: OilDescConst value: (slotValue at: slotIndex) scratch: slotIndex].
	(slotKind at: slotIndex) = OilDescReg ifTrue: [^slotValue at: slotIndex].
	self materializeSlot: slotIndex.
	^slotIndex! !

!OilInliningCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
materializeSlot: slotIndex
	"Make slotIndex hold its value in its own register (e.g. for a send's receiver and arguments)."
	(slotKind at: slotIndex) = OilDescObject ifTrue: "materialized into a register of its own, then copied"
		[self materializeVObj: (slotValue at: slotIndex) scratch: slotIndex.
		 (slotKind at: slotIndex) = OilDescObject ifTrue: [^self]]. "(failed: a restart)"
	(slotKind at: slotIndex) = OilDescReg
		ifTrue: [self emitMove: slotIndex from: (slotValue at: slotIndex)]
		ifFalse: [self regForKind: (slotKind at: slotIndex) value: (slotValue at: slotIndex) scratch: slotIndex].
	self setOwn: slotIndex! !

!OilInliningCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
stabilizeIncomingSlot: slotIndex
	"An inlined frame's receiver/argument must not alias a temp vector slot register, which inlined blocks may assign."
	| regVal |
	(self isLazyKind: (slotKind at: slotIndex)) ifTrue: [^self materializeSlot: slotIndex].
	(slotKind at: slotIndex) = OilDescReg ifFalse: [^self].
	regVal := slotValue at: slotIndex.
	(regVal ~= slotIndex and: [((slotFlags at: regVal) bitAnd: OilFlagTVSlot) ~= 0]) ifTrue:
		[self emitMove: slotIndex from: regVal.
		 self setOwn: slotIndex]! !

!OilInliningCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
invalidateAliasesOf: targetReg
	"targetReg, a named temp or temp vector slot register, is about to be assigned.  Copy its current value into
	 every live mutable slot aliasing it.  A live virtual closure or immutable slot that captured targetReg
	 forces eager closures."
	| descKind |
	(pendingCondSlot >= 0
	 and: [(self condAt: pendingCondIndex) regA = targetReg
		or: [(self condAt: pendingCondIndex) useImm not and: [(self condAt: pendingCondIndex) regB = targetReg]]]) ifTrue:
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

!OilInliningCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
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
		 ((self vobjAt: currentVObj) rcvrKind = OilDescReg and: [(self vobjAt: currentVObj) rcvrValue = targetReg]) ifTrue: [^true].
		 baseIndex := (self vobjAt: currentVObj) copiedBase.
		 0 to: (self vobjAt: currentVObj) copiedCount - 1 do:
			[:copiedIndex|
			descKind := capturedKind at: baseIndex + copiedIndex.
			(descKind = OilDescReg and: [(capturedValue at: baseIndex + copiedIndex) = targetReg]) ifTrue: [^true].
			(descKind = OilDescBlock and: [sp < OilMaxVObjs]) ifTrue:
				[stack at: sp put: (capturedValue at: baseIndex + copiedIndex).
				 sp := sp + 1]]].
	^false! !

!OilInliningCompiler methodsFor: 'descriptors' stamp: 'cb 10/24/2026 10:30'!
newVObj: kind
	| vobjIndex |
	numVObjs >= OilMaxVObjs ifTrue:
		[self abortCompilation: OilFailTooManyVirtualObjects.
		 ^0].
	vobjIndex := numVObjs.
	numVObjs := vobjIndex + 1.
	(self vobjAt: vobjIndex) kind: kind.
	(self vobjAt: vobjIndex) copiedCount: 0.
	(self vobjAt: vobjIndex) copiedBase: capturedTop.
	(self vobjAt: vobjIndex) numSlots: 0.
	(self vobjAt: vobjIndex) slotBase: 0.
	(self vobjAt: vobjIndex) vobjClass: 0.
	(self vobjAt: vobjIndex) materialized: -1.
	(self vobjAt: vobjIndex) epoch: oilFlowEpoch.
	^vobjIndex! !

!OilInliningCompiler methodsFor: 'stores' stamp: 'cb 10/24/2026 10:30'!
storeTopIntoReg: targetReg pop: popFlag
	"Store the top of stack into targetReg, a named temp or a scalar replaced temp vector slot.
	 Constants and virtual temp vectors are stored as descriptors; a value just computed into the stack top
	 is retargeted to targetReg instead of being moved."
	| topSlot descKind slotVal |
	topSlot := simStackTop.
	(self isLazyKind: (slotKind at: topSlot)) ifTrue: [self materializeSlot: topSlot].
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
			[(descKind = OilDescConst or: [descKind = OilDescObject])
				ifTrue:
					[self setSlot: targetReg kind: descKind value: slotVal.
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

!OilInliningCompiler methodsFor: 'stores' stamp: 'cb 10/24/2026 10:30'!
genStoreRcvrVar: instVarIndex pop: popFlag frame: frameIndex
	| valReg rcvrReg |
	instVarIndex > 255 ifTrue: [^self abortCompilation: OilFailUnsupportedBytecode].
	(self frameAt: frameIndex) selfKind = OilDescObject ifTrue: "a slot of a scalar replaced object"
		[^self storeTopIntoReg: (self vobjAt: (self frameAt: frameIndex) selfValue) slotBase + instVarIndex pop: popFlag].
	valReg := self regForSlot: simStackTop.
	rcvrReg := self selfRegOfFrame: frameIndex scratch: simStackTop + 1.
	self emitStoreField: valReg into: rcvrReg index: instVarIndex pop: popFlag! !

!OilInliningCompiler methodsFor: 'stores' stamp: 'cb 10/26/2026 20:55'!
emitStoreField: valReg into: objReg index: slotIndex pop: popFlag
	"Store valReg (the stack top) into slot slotIndex of objReg.  The store fails on an immutable object: its deopt site
	 makes the interpreter retry it."
	self recordSite: OilSiteStore.
	self emitOp: OilStoreField a: valReg b: objReg c: slotIndex.
	popFlag ifTrue: [simStackTop := simStackTop - 1]! !

!OilInliningCompiler methodsFor: 'stores' stamp: 'cb 10/24/2026 10:30'!
genStoreLitVar: literalIndex pop: popFlag frame: frameIndex
	"Store into a global/class variable's binding (value is slot 1 of the binding)."
	| valReg scratchReg |
	valReg := self regForSlot: simStackTop.
	scratchReg := simStackTop + 1.
	self emitConst: (self literalHandle: literalIndex frame: frameIndex) into: scratchReg.
	self emitStoreField: valReg into: scratchReg index: 1 pop: popFlag! !

!OilInliningCompiler methodsFor: 'stores' stamp: 'cb 10/24/2026 10:30'!
genStoreRemoteTemp: remoteIndex inVector: vectorIndex pop: popFlag frame: frameIndex
	| vectorReg valReg vecReg |
	vectorReg := self tempReg: vectorIndex frame: frameIndex.
	(slotKind at: vectorReg) = OilDescTempVector ifTrue:
		[^self storeTopIntoReg: (self vobjAt: (slotValue at: vectorReg)) slotBase + remoteIndex pop: popFlag].
	valReg := self regForSlot: simStackTop.
	vecReg := self regForSlot: vectorReg.
	self emitStoreField: valReg into: vecReg index: remoteIndex pop: popFlag! !

!OilInliningCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
selfRegOfFrame: frameIndex scratch: scratchReg
	^self regForKind: (self frameAt: frameIndex) selfKind value: (self frameAt: frameIndex) selfValue scratch: scratchReg! !

!OilInliningCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
genPushTemp: tempIndex frame: frameIndex
	| tempReg |
	tempReg := self tempReg: tempIndex frame: frameIndex.
	self push: (slotKind at: tempReg) value: (slotValue at: tempReg)! !

!OilInliningCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
genDup
	| top |
	top := simStackTop.
	(self isLazyKind: (slotKind at: top)) ifTrue: [self materializeSlot: top].
	self push: (slotKind at: top) value: (slotValue at: top)! !

!OilInliningCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
genPushRcvrVar: instVarIndex frame: frameIndex
	instVarIndex > 255 ifTrue: [^self abortCompilation: OilFailUnsupportedBytecode].
	(self frameAt: frameIndex) selfKind = OilDescObject ifTrue: "a slot of a scalar replaced object"
		[^self pushVObjSlot: instVarIndex of: (self frameAt: frameIndex) selfValue].
	self pushResultOf: OilLoadField b: (self selfRegOfFrame: frameIndex scratch: simStackTop + 1) c: instVarIndex site: 0! !

!OilInliningCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
genPushLitVar: literalIndex frame: frameIndex
	"Read-only bindings (classes) fold to their value; other globals load slot 1 (value) of their binding."
	| binding |
	binding := self oilLiteral: literalIndex ofMethod: (self frameAt: frameIndex) method.
	(self isReadOnlyBinding: binding) ifTrue:
		[^self push: OilDescConst value: (self bindingValueHandle: binding)].
	self emitConst: (self handleFor: binding) into: simStackTop + 1.
	self pushResultOf: OilLoadField b: simStackTop + 1 c: 1 site: 0! !

!OilInliningCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
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
	(self vobjAt: vobjIndex) numSlots: arraySize.
	(self vobjAt: vobjIndex) slotBase: baseReg.
	highRegTop := baseReg - 1.
	baseReg to: baseReg + arraySize - 1 do:
		[:highReg|
		slotFlags at: highReg put: OilFlagTVSlot.
		self setSlot: highReg kind: OilDescConst value: nilHandle].
	self push: OilDescTempVector value: vobjIndex! !

!OilInliningCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
genPushRemoteTemp: remoteIndex inVector: vectorIndex frame: frameIndex
	| vectorReg slotRegister |
	vectorReg := self tempReg: vectorIndex frame: frameIndex.
	(slotKind at: vectorReg) = OilDescTempVector ifTrue:
		[slotRegister := (self vobjAt: (slotValue at: vectorReg)) slotBase + remoteIndex.
		 ^self push: (slotKind at: slotRegister) value: (slotValue at: slotRegister)].
	self pushResultOf: OilLoadField b: (self regForSlot: vectorReg) c: remoteIndex site: 0! !

!OilInliningCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
genPushFullClosure: literalIndex flags: closureFlags frame: frameIndex
	"SistaV1 pushFullClosure.  flags = siyyyyyy: yyyyyy numCopied, s receiverOnStack, i ignoreOuterContext.
	 Normally the closure stays virtual (no allocation): its copied values are captured as descriptors.
	 In eager mode it is materialized with OilMakeClosure."
	| block numCopied rcvrOnStack firstSlot lowestSlot selfReg vobjIndex |
	block := self oilLiteral: literalIndex ofMethod: (self frameAt: frameIndex) method.
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
	(self vobjAt: vobjIndex) literal: block.
	(self vobjAt: vobjIndex) homeFrame: (self frameAt: frameIndex) home.
	"the frame whose context is the closure's outerContext (deoptimization), none (-1, nil) if it ignores it"
	(self vobjAt: vobjIndex) outer: ((closureFlags bitAnd: 64) ~= 0 ifTrue: [-1] ifFalse: [frameIndex]).
	rcvrOnStack
		ifTrue:
			[self capture: firstSlot - 1 frame: frameIndex.
			 capturedTop := capturedTop - 1.
			 (self vobjAt: vobjIndex) rcvrKind: (capturedKind at: capturedTop).
			 (self vobjAt: vobjIndex) rcvrValue: (capturedValue at: capturedTop)]
		ifFalse:
			[(self vobjAt: vobjIndex) rcvrKind: (self frameAt: frameIndex) selfKind.
			 (self vobjAt: vobjIndex) rcvrValue: (self frameAt: frameIndex) selfValue.
			 (self vobjAt: vobjIndex) vobjClass: (self frameAt: frameIndex) selfClass].
	(self vobjAt: vobjIndex) copiedBase: capturedTop.
	(self vobjAt: vobjIndex) copiedCount: numCopied.
	firstSlot to: simStackTop do: [:slotIndex| self capture: slotIndex frame: frameIndex].
	simStackTop := lowestSlot - 1.
	self push: OilDescBlock value: vobjIndex! !

!OilInliningCompiler methodsFor: 'pushes' stamp: 'cb 10/24/2026 10:30'!
capture: slotIndex frame: frameIndex
	"Append slotIndex's descriptor to the captured values pool.  A value living in one of the current frame's
	 expression stack registers (about to be reused) is first copied to a stable high register."
	| descKind slotVal highReg |
	capturedTop >= OilMaxCaptured ifTrue:
		[^self abortCompilation: OilFailTooManyVirtualObjects].
	((self isLazyKind: (slotKind at: slotIndex)) or: [(slotKind at: slotIndex) = OilDescObject]) ifTrue:
		[self materializeSlot: slotIndex].
	descKind := slotKind at: slotIndex.
	slotVal := slotValue at: slotIndex.
	(descKind = OilDescReg and: [slotVal >= (self frameAt: frameIndex) stackStart and: [slotVal <= simStackTop]]) ifTrue:
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

!OilInliningCompiler methodsFor: 'returns' stamp: 'cb 10/24/2026 10:30'!
genReturnTopNonLocal: isNonLocal frame: frameIndex next: nextPC
	| topSlot |
	topSlot := simStackTop.
	simStackTop := topSlot - 1.
	self genReturnKind: (slotKind at: topSlot) value: (slotValue at: topSlot) nonLocal: isNonLocal frame: frameIndex next: nextPC! !

!OilInliningCompiler methodsFor: 'returns' stamp: 'cb 10/24/2026 10:30'!
genReturnKind: descKind value: descValue nonLocal: isNonLocal frame: frameIndex next: nextPC
	<inline: false>
	"Return (descKind, descValue) from frameIndex, or, for a non-local return from an inlined block, from its home frame.
	 From the compiled method this is OilReturn.  From an inlined frame the result is left in the frame's base
	 register (or, for a single final return, kept as a lazy descriptor) and control jumps to the frame's exit."
	| targetFrame baseReg retReg isLast instIndex retVal |
	oilDeadCode := true.
	targetFrame := isNonLocal ifTrue: [(self frameAt: frameIndex) home] ifFalse: [frameIndex].
	(descKind = OilDescBlock or: [descKind = OilDescTempVector]) ifTrue:
		[^self requireEagerClosures].
	(descKind = OilDescObject
	 and: [targetFrame = 0 or: [isNonLocal or: [(self frameAt: frameIndex) exitChain ~= OilNoLink
		or: [nextPC <= (self frameAt: frameIndex) endPC and: [(self isFrame: frameIndex deadFrom: nextPC) not]]]]]) ifTrue:
		"it escapes: not the single final return of an inlined frame (whose result stays a descriptor)"
		[retReg := self materializeVObj: descValue scratch: simStackTop + 1.
		 failed ifTrue: [^self].
		 ^self genReturnKind: OilDescReg value: retReg nonLocal: isNonLocal frame: frameIndex next: nextPC].
	targetFrame = 0 ifTrue:
		[retReg := self regForKind: descKind value: descValue scratch: simStackTop + 1.
		 self emitOp: OilReturn a: retReg b: 0 c: 0.
		 ^self].
	(self isFrameActive: targetFrame) ifFalse:
		[^self abortCompilation: OilFailInternal].
	baseReg := (self frameAt: targetFrame) base.
	isLast := isNonLocal not and: [nextPC > (self frameAt: frameIndex) endPC or: [self isFrame: frameIndex deadFrom: nextPC]].
	(isLast and: [(self frameAt: frameIndex) exitChain = OilNoLink]) ifTrue:
		[retVal := descValue.
		 (descKind = OilDescReg and: [descValue > baseReg and: [descValue <= highRegTop]]) ifTrue:
			"the value lives in a register of the dying frame: bring it to the result register"
			[(self retarget: descValue to: baseReg) ifFalse: [self emitMove: baseReg from: descValue].
			 retVal := baseReg].
		 (self frameAt: frameIndex) hasLazy: true.
		 (self frameAt: frameIndex) lazyKind: descKind.
		 (self frameAt: frameIndex) lazyValue: retVal.
		 ^self].
	"Scalar replaced objects are materialized first: their allocations deoptimize to the state at this bytecode, whose
	 registers (the result's, baseReg) must not have been reassigned yet."
	self flushTVSlots.
	descKind = OilDescReg
		ifTrue: [descValue ~= baseReg ifTrue: [(self retarget: descValue to: baseReg) ifFalse: [self emitMove: baseReg from: descValue]]]
		ifFalse: [self regForKind: descKind value: descValue scratch: baseReg].
	isLast ifTrue: [^self]. "falls through into the exit label"
	instIndex := self emitOp: OilJump a: 0 imm16: (self frameAt: targetFrame) exitChain.
	(self frameAt: targetFrame) exitChain: instIndex! !

!OilInliningCompiler methodsFor: 'jumps' stamp: 'cb 10/24/2026 10:30'!
genJumpTo: targetPC frame: frameIndex
	self flushFrame: frameIndex.
	self emitBranch: OilJump cond: 0 to: targetPC frame: frameIndex.
	oilDeadCode := true! !

!OilInliningCompiler methodsFor: 'jumps' stamp: 'cb 10/24/2026 10:30'!
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

!OilInliningCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
genSpecialSend: index numArgs: numArgs frame: frameIndex next: nextPC
	<inline: false>
	"Special selectors: inline tagged SmallInteger arithmetic and comparisons, Float arithmetic and comparisons, identity,
	 class, and Character equality; others are ordinary sends.  Answer the pc to continue at (a comparison may be fused with the following
	 conditional jump)."
	| floatPC |
	(index between: 2 and: 7) ifTrue:
		[(self canInlineSmallIntegerOpOn: simStackTop - 1 arg: simStackTop) ifTrue:
			[^self genCompare: index - 1 identity: false frame: frameIndex next: nextPC].
		 ((index = 6 or: [index = 7]) and: [self canInlineCharacterEqOn: simStackTop - 1 arg: simStackTop]) ifTrue:
			[^self genCompare: (index = 6 ifTrue: [OilCondIdentical] ifFalse: [OilCondNotIdentical]) identity: true frame: frameIndex next: nextPC]] "OilCondLt..OilCondNe".
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

!OilInliningCompiler methodsFor: 'sends' stamp: 'cb 10/25/2026 07:30'!
canInlineCharacterEqOn: rcvrSlot arg: argSlot
	| rcvrKind rcvrVal argKind argVal |
	rcvrKind := slotKind at: rcvrSlot.
	rcvrVal := slotValue at: rcvrSlot.
	argKind := slotKind at: argSlot.
	argVal := slotValue at: argSlot.
	(rcvrKind = OilDescConst and: [self isCharacterHandle: rcvrVal]) ifTrue: [^true].
	(argKind = OilDescConst and: [self isCharacterHandle: argVal]) ifTrue: [^true].
	^false! !

!OilInliningCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
canInlineSmallIntegerOpOn: rcvrSlot arg: argSlot
	"Speculate SmallInteger arithmetic if the receiver is a SmallInteger constant, is known to be a SmallInteger,
	 or its send site only saw SmallIntegers; the argument must not be a non-SmallInteger constant or a virtual object.
	 The tagged opcodes check their operands' tags and deoptimize on failure or overflow."
	| argKind profiledCls |
	argKind := slotKind at: argSlot.
	(argKind = OilDescReg or: [argKind = OilDescConst and: [self isSmallIntegerHandle: (slotValue at: argSlot)]]) ifFalse: [^false].
	(self isFloatSlot: argSlot) ifTrue: [^false]. "e.g. 2 * aFloat: see genFloatSend:frame:next:"
	(self isKnownSmallInteger: rcvrSlot) ifTrue: [^true].
	(slotKind at: rcvrSlot) = OilDescReg ifFalse: [^false].
	"The baseline JIT inlines SmallInteger arithmetic and comparisons and only sends the message for other
	 receivers.  So a send site whose inline cache is still unlinked has only ever seen SmallIntegers: speculate."
	profiledCls := self profiledClassAt: currentPC.
	^profiledCls = smallIntegerClassHandle
	  or: [profiledCls = 0 and: [self isUnlinkedSendAt: currentPC]]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 14:00'!
isUnlinkedSendAt: pc
	"Has the send at pc in the current frame's method never been sent (no inline cache information at all)?"
	^self
		cCode: [cogit oilSendSiteUnlinkedAt: pc in: (self frameAt: currentFrame) method]
		inSmalltalk:
			[typeFeedback isNil
			 or: [(typeFeedback hasSiteAt: pc in: (self frameAt: currentFrame) method) not]]! !

!OilInliningCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
isKnownSmallInteger: slotIndex
	(slotKind at: slotIndex) = OilDescConst ifTrue: [^self isSmallIntegerHandle: (slotValue at: slotIndex)].
	^(slotKind at: slotIndex) = OilDescReg and: [(knownClass at: (slotValue at: slotIndex)) = smallIntegerClassHandle]! !

!OilInliningCompiler methodsFor: 'float arithmetic' stamp: 'cb 10/25/2026 02:00'!
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

!OilInliningCompiler methodsFor: 'float arithmetic' stamp: 'cb 10/25/2026 02:00'!
genFloatCompare: cond rcvr: rcvrReg arg: argReg frame: frameIndex next: nextPC
	"OilCmpFloat fused with the following conditional jump, or, if there is none, answering true or false."
	(nextPC >= 0 and: [self canFuseBranchAt: nextPC frame: frameIndex]) ifTrue:
		[self flushFrame: frameIndex.
		 self recordSite: OilSiteArith.
		 self emitOp: OilCmpFloat a: cond b: rcvrReg c: argReg.
		 ^self emitFusedBranch: frameIndex].
	self recordSite: OilSiteArith.
	self emitOp: OilCmpFloat a: cond b: rcvrReg c: argReg.
	self emitDiamondInto: self pushOwnSlot trueKind: OilDescConst value: trueHandle falseKind: OilDescConst value: falseHandle.
	^nextPC! !

!OilInliningCompiler methodsFor: 'float arithmetic' stamp: 'cb 10/25/2026 02:00'!
canInlineFloatOpOn: rcvrSlot arg: argSlot
	"Speculate Float arithmetic if the receiver is known to be a Float or its send site only saw Floats (SmallFloat64
	 or BoxedFloat64) and the argument may be a number."
	(self isNumberSlot: argSlot) ifFalse: [^false].
	(self isFloatSlot: rcvrSlot) ifTrue: [^true].
	^(slotKind at: rcvrSlot) = OilDescReg
	  and: [self isFloatClass: (self profiledClassAt: currentPC)]! !

!OilInliningCompiler methodsFor: 'float arithmetic' stamp: 'cb 10/25/2026 02:00'!
isNumberSlot: slotIndex
	"May slotIndex hold a SmallInteger or a Float (a register, or such a constant)?"
	(slotKind at: slotIndex) = OilDescReg ifTrue: [^true].
	^(slotKind at: slotIndex) = OilDescConst
	  and: [(self isSmallIntegerHandle: (slotValue at: slotIndex)) or: [self isFloatHandle: (slotValue at: slotIndex)]]! !

!OilInliningCompiler methodsFor: 'float arithmetic' stamp: 'cb 10/26/2026 23:45'!
isFloatSlot: slotIndex
	"Is slotIndex a Float constant, or a register of a known Float class or last assigned by Float arithmetic?"
	| reg defOffset |
	(slotKind at: slotIndex) = OilDescConst ifTrue: [^self isFloatHandle: (slotValue at: slotIndex)].
	(slotKind at: slotIndex) = OilDescReg ifFalse: [^false].
	reg := slotValue at: slotIndex.
	(self isFloatClass: (knownClass at: reg)) ifTrue: [^true].
	defOffset := lastDefIR at: reg.
	^defOffset >= 0 and: [defOffset < irIndex and: [self isFloatArith: (self opcodeAt: defOffset)]]! !

!OilInliningCompiler methodsFor: 'float arithmetic' stamp: 'cb 10/26/2026 23:45'!
unaryFloatOpcodeOf: selector
	"OilSqrtFloat, OilAbsFloat, OilNegatedFloat or OilMulFloat (#squared) if selector is one of them, else 0."
	(self cCode: [self oilSelector: selector isNamed: 'sqrt'] inSmalltalk: [(self objectFor: selector) == #sqrt])
		ifTrue: [^OilSqrtFloat].
	(self cCode: [self oilSelector: selector isNamed: 'abs'] inSmalltalk: [(self objectFor: selector) == #abs])
		ifTrue: [^OilAbsFloat].
	(self cCode: [self oilSelector: selector isNamed: 'negated'] inSmalltalk: [(self objectFor: selector) == #negated])
		ifTrue: [^OilNegatedFloat].
	(self cCode: [self oilSelector: selector isNamed: 'squared'] inSmalltalk: [(self objectFor: selector) == #squared])
		ifTrue: [^OilMulFloat].
	^0! !

!OilInliningCompiler methodsFor: 'float arithmetic' stamp: 'cb 10/26/2026 23:45'!
genUnaryFloatSend: selector receiver: rcvrSlot
	"#sqrt, #abs, #negated and #squared on a Float receiver."
	| opcode rcvrReg |
	opcode := self unaryFloatOpcodeOf: selector.
	opcode = 0 ifTrue: [^false].
	rcvrReg := self regForSlot: rcvrSlot.
	simStackTop := rcvrSlot - 1.
	self pushResultOf: opcode b: rcvrReg c: (opcode = OilMulFloat ifTrue: [rcvrReg] ifFalse: [0]) site: OilSiteArith.
	^true! !

!OilInliningCompiler methodsFor: 'float arithmetic' stamp: 'cb 10/25/2026 02:00'!
isFloatClass: classOop
	"Is classOop SmallFloat64 or BoxedFloat64?"
	classOop = 0 ifTrue: [^false].
	^self
		cCode: [(objectMemory classTagForClass: classOop) = objectMemory smallFloatTag
				or: [(objectMemory classTagForClass: classOop) = ClassFloatCompactIndex]]
		inSmalltalk: [(self objectFor: classOop) includesBehavior: Float]! !

!OilInliningCompiler methodsFor: 'float arithmetic' stamp: 'cb 10/25/2026 02:00'!
isFloatHandle: aHandle
	^self isFloatClass: (self classOopOf: aHandle)! !

!OilInliningCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
genClassOf: slotIndex
	"#class: fold when the receiver's class is known."
	| classOop |
	classOop := self staticClassOfSlot: slotIndex.
	classOop = 0 ifTrue: [^false].
	simStackTop := slotIndex - 1.
	self push: OilDescConst value: classOop.
	^true! !

!OilInliningCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
genSend: selector numArgs: numArgs super: isSuper frame: frameIndex
	<inline: false>
	"A message send: inline a virtual block's evaluation, a quick method, an intrinsic primitive or the method
	 itself when the receiver's class is known (constant, established fact, or monomorphic type feedback guarded
	 by OilGuardClass); otherwise emit a call."
	| rcvrSlot descKind rcvrClass lookupClass guard method prim |
	rcvrSlot := simStackTop - numArgs.
	descKind := slotKind at: rcvrSlot.
	(descKind = OilDescBlock and: [isSuper not]) ifTrue:
		[((self isValueSelector: selector numArgs: numArgs)
		  and: [self inlineBlock: (slotValue at: rcvrSlot) receiver: rcvrSlot numArgs: numArgs]) ifTrue: [^self].
		 ((self isValueSelector: selector numArgs: numArgs) not
		  and: [self inlineSendToVirtualBlock: selector numArgs: numArgs receiver: rcvrSlot]) ifTrue: [^self].
		 ^self genCall: selector numArgs: numArgs receiver: rcvrSlot super: false].
	(isSuper not and: [(self isBitXorSelector: selector) and: [numArgs = 1
	 and: [self canInlineSmallIntegerOpOn: rcvrSlot arg: rcvrSlot + 1]]]) ifTrue:
		[(self genBitOp: OilXorTagged) ifTrue: [^self]].
	guard := false.
	"A super send looks up in the superclass of its home method's class, but its receiver keeps its own (static) class:
	 the inlined method's self sends, self class and intrinsics depend on the receiver's class (0 if unknown)."
	isSuper
		ifTrue:
			[lookupClass := self superclassOopOfMethodClassOf: (self frameAt: (self frameAt: frameIndex) home) method.
			 rcvrClass := self staticClassOfSlot: rcvrSlot]
		ifFalse:
			[rcvrClass := self staticClassOfSlot: rcvrSlot.
			 rcvrClass = 0 ifTrue:
				[rcvrClass := self profiledClassAt: currentPC.
				 guard := rcvrClass ~= 0].
			 lookupClass := rcvrClass].
	(isSuper not and: [numArgs = 0 and: [(self isFloatSlot: rcvrSlot) or: [self isFloatClass: rcvrClass]]]) ifTrue:
		[(self genUnaryFloatSend: selector receiver: rcvrSlot) ifTrue: [^self]].
	(rcvrClass = 0 and: [isSuper not and: [descKind = OilDescReg]]) ifTrue:
		[(self genBimorphicSend: selector numArgs: numArgs receiver: rcvrSlot) ifTrue: [^self]].
	(lookupClass = 0 or: [(self isContextClass: lookupClass) or: [self isContextClass: rcvrClass]]) ifTrue:
		[^self genCall: selector numArgs: numArgs receiver: rcvrSlot super: isSuper].
	method := self lookup: selector inClass: lookupClass.
	method = 0 ifTrue: [^self genCall: selector numArgs: numArgs receiver: rcvrSlot super: isSuper].
	prim := self oilPrimitiveIndexOf: method.
	(self oilIsQuickPrimitiveIndex: prim) ifTrue:
		[guard ifTrue: [self emitGuardOn: (self regForSlot: rcvrSlot) class: rcvrClass].
		 ^self genQuickMethod: prim receiver: rcvrSlot numArgs: numArgs].
	"(The intrinsics whose slow path is a send cannot compile super sends.)"
	(isSuper not
	 and: [self genScanIntrinsic: method selector: selector receiver: rcvrSlot numArgs: numArgs class: rcvrClass guard: guard]) ifTrue:
		[^self].
	(prim = 175 and: [numArgs = 0 and: [(slotKind at: rcvrSlot) = OilDescConst
	 and: [(self classIndexOfClass: (slotValue at: rcvrSlot)) > 0]]]) ifTrue:
		["Behavior>>identityHash of a constant class: its class index"
		 simStackTop := rcvrSlot - 1.
		 ^self push: OilDescConst value: (self handleForSmallInteger: (self classIndexOfClass: (slotValue at: rcvrSlot)))].
	(isSuper not and: [(prim = 70 and: [numArgs = 0]) or: [prim = 18 and: [numArgs = 1]]]) ifTrue:
		[(self genNewObject: prim receiver: rcvrSlot class: rcvrClass guard: guard) ifTrue: [^self]].
	(isSuper not
	 and: [(numArgs = 1 or: [numArgs = 2])
	 and: [prim = 152 or: [prim = 117 and: [self isStringHashMethod: method]]]]) ifTrue:
		[(self genStringHash: selector receiver: rcvrSlot numArgs: numArgs class: rcvrClass guard: guard) ifTrue: [^self]].
	prim ~= 0 ifTrue:
		[((isSuper not or: [(prim = 65 or: [prim = 66 or: [prim = 75]]) not])
		  and: [self canInlineIntrinsic: prim class: rcvrClass numArgs: numArgs]) ifTrue:
			[guard ifTrue: [self emitGuardOn: (self regForSlot: rcvrSlot) class: rcvrClass].
			 self genIntrinsic: prim selector: selector receiver: rcvrSlot numArgs: numArgs bytes: (self oilInstSpecOfClass: rcvrClass) >= 16.
			 ^self].
		 ^self genCall: selector numArgs: numArgs receiver: rcvrSlot super: isSuper].
	((self hasVirtualObjectFrom: rcvrSlot to: rcvrSlot + numArgs) and: [self isNeverSentAt: currentPC]) ifTrue:
		["never executed so far (a cold path), and inlining it or calling it would make a virtual closure or object escape"
		 ^self genUncommonTrapForSendAt: rcvrSlot numArgs: numArgs].
	(self shouldInline: method selector: selector numArgs: numArgs receiver: rcvrSlot) ifTrue:
		[(self inlineMethod: method receiver: rcvrSlot numArgs: numArgs class: rcvrClass guard: guard) ifTrue:
			[^self]].
	self genCall: selector numArgs: numArgs receiver: rcvrSlot super: isSuper! !

!OilInliningCompiler methodsFor: 'selectors by name' stamp: 'cb 10/27/2026 11:50'!
isIndexOfAsciiMethod: method
	"ByteString class>>indexOfAscii:inString:startingAt: (registered, or by its primitive/selector and class)."
	oilIndexOfAsciiMethod ~= 0 ifTrue: [^method = oilIndexOfAsciiMethod].
	^self cCode:
			[method ~= 0
			 and: [(self oilSelector: (coInterpreter maybeSelectorOfMethod: method) isNamed: 'indexOfAscii:inString:startingAt:')
			 and: [(coInterpreter oilApiMethodClassOf: method) = coInterpreter oilApiByteStringMetaclass]]]
		inSmalltalk:
			[(method literalAt: 1) isArray
			 and: [((method literalAt: 1) at: 2 ifAbsent: [nil]) = 'primitiveIndexOfAsciiInString']]! !

!OilInliningCompiler methodsFor: 'selectors by name' stamp: 'cb 10/27/2026 11:50'!
isFindSubstringMethod: method
	"ByteString>>findSubstring:in:startingAt:matchTable: (primitive 117 when not yet numbered 154)."
	^self cCode:
			[method ~= 0
			 and: [self oilSelector: (coInterpreter maybeSelectorOfMethod: method) isNamed: 'findSubstring:in:startingAt:matchTable:']]
		inSmalltalk:
			[(method literalAt: 1) isArray
			 and: [((method literalAt: 1) at: 2 ifAbsent: [nil]) = 'primitiveFindSubstring']]! !

!OilInliningCompiler methodsFor: 'selectors by name' stamp: 'cb 10/27/2026 11:50'!
isFindFirstInStringMethod: method
	"String class>>findFirstInString:inSet:startingAt: (primitive 117 when not yet numbered 155)."
	^self cCode:
			[method ~= 0
			 and: [self oilSelector: (coInterpreter maybeSelectorOfMethod: method) isNamed: 'findFirstInString:inSet:startingAt:']]
		inSmalltalk:
			[(method literalAt: 1) isArray
			 and: [((method literalAt: 1) at: 2 ifAbsent: [nil]) = 'primitiveFindFirstInString']]! !

!OilInliningCompiler methodsFor: 'selectors by name' stamp: 'cb 10/26/2026 15:00'!
isSkipSeparatorsMethod: method
	"PositionableStream>>skipSeparators (registered, or in the VM, by its selector and class)."
	oilSkipSeparatorsMethod ~= 0 ifTrue: [^method = oilSkipSeparatorsMethod].
	^self cCode:
			[method ~= 0
			 and: [(self oilSelector: (coInterpreter maybeSelectorOfMethod: method) isNamed: 'skipSeparators')
			 and: [coInterpreter oilApiClass: (coInterpreter oilApiMethodClassOf: method) isNamed: 'PositionableStream']]]
		inSmalltalk: [false]! !

!OilInliningCompiler methodsFor: 'selectors by name' stamp: 'cb 10/26/2026 15:00'!
isByteStreamClass: aClass
	"ReadStream (registered, or in the VM, by name)."
	oilByteStreamClass ~= 0 ifTrue: [^aClass = oilByteStreamClass].
	^self cCode: [aClass ~= 0 and: [coInterpreter oilApiClass: aClass isNamed: 'ReadStream']] inSmalltalk: [false]! !

!OilInliningCompiler methodsFor: 'sends' stamp: 'cb 10/25/2026 03:00'!
isContextClass: classOop
	"Is classOop Context?  The sender, pc and stackp of a context married to a stack frame are not in its slots (the
	 interpreter and the baseline JIT map them from the frame), so Oil neither compiles nor inlines methods of contexts."
	classOop = 0 ifTrue: [^false].
	^self
		cCode: [(objectMemory classTagForClass: classOop) = ClassMethodContextCompactIndex]
		inSmalltalk: [(self objectFor: classOop) == Context]! !

!OilInliningCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
staticClassOfSlot: slotIndex
	| descKind |
	descKind := slotKind at: slotIndex.
	descKind = OilDescConst ifTrue: [^self classOopOf: (slotValue at: slotIndex)].
	descKind = OilDescReg ifTrue: [^knownClass at: (slotValue at: slotIndex)].
	descKind = OilDescObject ifTrue: [^(self vobjAt: (slotValue at: slotIndex)) vobjClass].
	^0! !

!OilInliningCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
isValueSelector: selector numArgs: numArgs
	"value, value:, value:value:, value:value:value: or value:value:value:value: (registered, or in the VM, by name)."
	numArgs > 4 ifTrue: [^false].
	(valueSelectors at: numArgs) ~= 0 ifTrue: [^(valueSelectors at: numArgs) = selector].
	^self cCode: [self oilIsValueSelectorNamed: selector numArgs: numArgs] inSmalltalk: [false]! !

!OilInliningCompiler methodsFor: 'sends' stamp: 'cb 10/26/2026 15:00'!
isBitXorSelector: selector
	"bitXor: (registered, or in the VM, by name)."
	bitXorSelector ~= 0 ifTrue: [^selector = bitXorSelector].
	^self cCode: [self oilSelector: selector isNamed: 'bitXor:'] inSmalltalk: [false]! !

!OilInliningCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
isColdSelector: selector
	"Is selector never inlined (error paths, slow paths)?  The cold selectors are registered (the image's list, see
	 CoInterpreterPrimitives>>primitiveOilSetColdSelectors), or numColdSelectors is -1 and, in the VM, the default ones
	 (defaultColdSelectors) are recognized by name."
	numColdSelectors < 0 ifTrue:
		[^self cCode: [self oilIsDefaultColdSelector: selector] inSmalltalk: [false]].
	^self includes: selector in: coldSelectors count: numColdSelectors! !

!OilInliningCompiler methodsFor: 'selectors by name' stamp: 'cb 10/26/2026 15:00'!
oilSelector: selector isNamed: aCString
	"Is selector the Symbol whose characters are aCString (VM only)?"
	<var: #aCString type: #'const char *'>
	<inline: false>
	| length |
	length := self strlen: aCString.
	^selector ~= 0 "(maybeSelectorOfMethod: answers 0 for none)"
	  and: [(objectMemory isBytes: selector)
	  and: [(objectMemory numBytesOf: selector) = length
	  and: [(self strncmp: (self cCoerceSimple: (objectMemory firstIndexableField: selector) to: #'char *') _: aCString _: length) = 0]]]! !

!OilInliningCompiler methodsFor: 'selectors by name' stamp: 'cb 10/26/2026 15:00'!
oilIsValueSelectorNamed: selector numArgs: numArgs
	"Is selector value (numArgs 0) or value: repeated numArgs times (VM only)?"
	<inline: false>
	| chars |
	<var: #chars type: #'char *'>
	numArgs = 0 ifTrue: [^self oilSelector: selector isNamed: 'value'].
	((objectMemory isBytes: selector)
	 and: [(objectMemory numBytesOf: selector) = (6 * numArgs)]) ifFalse: [^false].
	chars := self cCoerceSimple: (objectMemory firstIndexableField: selector) to: #'char *'.
	0 to: numArgs - 1 do:
		[:keywordIndex| (self strncmp: chars + (6 * keywordIndex) _: 'value:' _: 6) = 0 ifFalse: [^false]].
	^true! !

!OilInliningCompiler methodsFor: 'selectors by name' stamp: 'cb 10/26/2026 15:00'!
oilIsDefaultColdSelector: selector
	"Is selector one of defaultColdSelectors (VM only)?"
	<inline: false>
	0 to: (self cCode: '(sqInt)(sizeof(oilDefaultColdSelectorNames) / sizeof(oilDefaultColdSelectorNames[0]))' inSmalltalk: [0]) - 1 do:
		[:index| (self oilSelector: selector isNamed: (oilDefaultColdSelectorNames at: index)) ifTrue: [^true]].
	^false! !

!OilInliningCompiler class methodsFor: 'translation' stamp: 'cb 10/26/2026 15:00'!
defaultColdSelectors
	"The selectors of the error paths and slow paths, never inlined (they would bloat the IR of the hot loop for nothing),
	 unless the image supplies its own list (see CoInterpreterPrimitives>>primitiveOilSetColdSelectors)."
	^#(error: errorNoFreeSpace errorNotFound: errorSubscriptBounds: errorNoSuchElement errorEmptyCollection errorKeyNotFound: errorKeyNotFound errorImproperStore errorNonIntegerIndex errorNotIndexable subclassResponsibility shouldNotImplement notYetImplemented halt halt: deprecated: deprecated signal signal: doesNotUnderstand: cannotReturn: primitiveFailed primitiveFailed: makeRoomAtLast makeRoomAtFirst)! !

!OilInliningCompiler methodsFor: 'sends' stamp: 'cb 10/27/2026 14:05'!
shouldInline: method selector: selector numArgs: numArgs receiver: rcvrSlot
	"Inlining policy (see the class comment)."
	| depth size takesBlock inLoop maxDepth limit |
	limit := oilMaxInlineDepthValue > 0 ifTrue: [oilMaxInlineDepthValue] ifFalse: [OilMaxInlineDepth].
	(self frameAt: currentFrame) depth + 1 > (2 * limit) ifTrue: [^false].
	"The depth counts from the closest block of the root method's code inlined (e.g. the loop of a benchmark under
	 timeToRun, millisecondsToRun: and microsecondsToRun:): that block is the root's code."
	depth := self policyDepthOf: currentFrame.
	inLoop := self isInLoopFrame: currentFrame pc: currentPC.
	maxDepth := inLoop ifTrue: [limit] ifFalse: [limit // 2].
	depth > maxDepth ifTrue: [^false].
	(self isColdSelector: selector) ifTrue: [^false].
	(self isNoInline: method) ifTrue: [^false].
	(self isSynchronizationMethod: method) ifTrue: [^false].
	(self isMethodOnInlineStack: method) ifTrue: [^false].
	size := (self oilEndPCOf: method) - (self startPCOf: method) + 1.
	irInstCount + size > irBudget ifTrue: [^false].
	takesBlock := false.
	rcvrSlot + 1 to: rcvrSlot + numArgs do: [:slotIndex| (slotKind at: slotIndex) = OilDescBlock ifTrue: [takesBlock := true]].
	takesBlock ifTrue:
		[^size <= (oilMaxCalleeBytesValue > 0 ifTrue: [oilMaxCalleeBytesValue] ifFalse: [OilMaxCalleeBytes])].
	size <= (oilAccessorBytesValue > 0 ifTrue: [oilAccessorBytesValue] ifFalse: [OilAccessorBytes]) ifTrue: [^true].
	"A method with Oil code of its own: calling it runs that code, while an inlined copy would lack the type feedback of
	 its baseline inline caches (gone with its baseline code), so its own sends would not be inlined."
	(self hasOilCode: method) ifTrue: [^false].
	^size <= (oilMaxCalleeBytesValue > 0 ifTrue: [oilMaxCalleeBytesValue] ifFalse: [OilMaxCalleeBytes])! !

!OilInliningCompiler methodsFor: 'inlining' stamp: 'cb 10/24/2026 17:00'!
isInLoopFrame: frameIndex pc: targetPC
	"Is targetPC of frameIndex inside a loop of its method, or is frameIndex inlined (transitively) from a pc inside a loop?"
	| walkFrame walkPC |
	walkFrame := frameIndex.
	walkPC := targetPC.
	[walkFrame >= 0] whileTrue:
		[(pcLoop at: (self pcMapIndex: walkPC frame: walkFrame)) ~= 0 ifTrue: [^true].
		 walkPC := (self frameAt: walkFrame) callPC.
		 walkFrame := (self frameAt: walkFrame) parent].
	^false! !

!OilInliningCompiler methodsFor: 'inlining' stamp: 'cb 10/24/2026 18:30'!
isNeverSentAt: pc
	"Has the method of the current frame machine code whose send at pc was never executed (an unlinked inline cache)?"
	^self
		cCode: [cogit oilSendSiteNeverSentAt: pc in: (self frameAt: currentFrame) method]
		inSmalltalk: [typeFeedback notNil and: [(typeFeedback hasSiteAt: pc in: (self frameAt: currentFrame) method) not]]! !

!OilInliningCompiler methodsFor: 'inlining' stamp: 'cb 10/24/2026 18:30'!
genUncommonTrapForSendAt: rcvrSlot numArgs: numArgs
	"A send in an inlined frame that the back end cannot encode, but that never executed: instead of a call, deoptimize
	 there (an uncommon trap: the interpreter then performs the send; this counts as a deoptimization).  The send's
	 result is an unknown own register (the code after the trap is unreachable)."
	"(The deopt state of the send's bytecode describes its receiver and arguments, virtual or not.)"
	failed ifTrue: [^self].
	self emitOp: OilTrap a: 0 b: 0 c: (self recordSite: OilSiteCall).
	simStackTop := rcvrSlot - 1.
	self pushResultOf: OilConstTagged b: 0 c: 1 site: 0! !

!OilInliningCompiler methodsFor: 'inlining' stamp: 'cb 10/27/2026 20:25'!
hasOilCode: aMethod
	^self
		cCode: [(cogit oilMethodHasOilCode: aMethod) or: [(cogit oilFirstSpecializedCogMethodOf: aMethod) ~= nil]]
		inSmalltalk: [false]! !

!OilInliningCompiler methodsFor: 'inlining' stamp: 'cb 10/26/2026 16:30'!
isSynchronizationMethod: aMethod
	"A method of the process synchronization and timer classes is never inlined (in the VM; see
	 CoInterpreter>>oilApiIsSynchronizationMethod:)."
	^self cCode: [coInterpreter oilApiIsSynchronizationMethod: aMethod] inSmalltalk: [false]! !

!OilInliningCompiler methodsFor: 'inlining' stamp: 'cb 10/24/2026 17:30'!
isNoInline: aMethod
	^self includes: aMethod in: oilNoInline count: oilNumNoInline! !

!OilInliningCompiler methodsFor: 'inlining' stamp: 'cb 10/26/2026 09:30'!
isEncodableCall: selector super: isSuper
	"Can the back end emit a send of selector?  Inline caches hold the index of their selector in the literals of the
	 method (the root), among the special selectors or in the Oil selector table (which this adds selector to, see
	 ProfilingCogit>>oilExtraSelectorIndexOf:add:).  A super send of the root binds to the root method's class; one of an
	 inlined frame is a directed super send, which needs the class of the frame's method."
	isSuper ifTrue:
		[currentFrame = 0 ifTrue: [^true].
		 (self methodClassOopOfFrame: currentFrame) = 0 ifTrue: [^false]].
	0 to: 31 do:
		[:index| (self specialSelectorHandle: index) = selector ifTrue: [^true]].
	0 to: (self cCode: [objectMemory literalCountOf: oilHomeMethod] inSmalltalk: [oilHomeMethod numLiterals]) - 1 do:
		[:index|
		(self cCode: [coInterpreter literal: index ofMethod: oilHomeMethod]
			inSmalltalk: [self handleFor: (oilHomeMethod literalAt: index + 1)]) = selector ifTrue: [^true]].
	^self cCode: [(cogit oilExtraSelectorIndexOf: selector add: true) ~= OilNoLink] inSmalltalk: [false]! !

!OilInliningCompiler methodsFor: 'inlining' stamp: 'cb 10/26/2026 09:30'!
refuseInliningOfFrameOf: frameIndex
	"Frame frameIndex (inlined) needs something the back end cannot do: a send of a selector that is not among the root
	 method's literals, a super send of a method without a method class, or a closure whose outerContext is frameIndex's context.  Compile again without inlining
	 the method that the root sends and that leads to frameIndex (its send is encodable)."
	| walkFrame |
	walkFrame := frameIndex.
	[walkFrame > 0 and: [(self frameAt: walkFrame) parent > 0]] whileTrue:
		[walkFrame := (self frameAt: walkFrame) parent].
	(walkFrame <= 0 or: [(self frameAt: walkFrame) isBlockFrame or: [oilNumNoInline >= 16]]) ifTrue:
		[^self abortCompilation: OilFailBackend].
	oilRefusePC := currentPC. "(for debugging)"
	oilRefuseDepth := (self frameAt: frameIndex) depth.
	oilNoInline at: oilNumNoInline put: (self frameAt: walkFrame) method.
	oilNumNoInline := oilNumNoInline + 1.
	oilRestartNoInline := true.
	needsRestart := true.
	failed := true! !

!OilInliningCompiler methodsFor: 'sends' stamp: 'cb 10/26/2026 09:30'!
genCall: selector numArgs: numArgs receiver: rcvrSlot super: isSuper
	"A non-inlined send: receiver and arguments in consecutive registers rcvrSlot..rcvrSlot+numArgs, result in rcvrSlot.
	 OilCall0 [Op|Dest|Rcvr|0], OilCall1 [Op|Dest|Rcvr|Arg0], OilCallN/OilCallSuper/OilCallDirectedSuper [Op|Dest|Rcvr|NumArgs];
	 then the 64-bit selector; then, for OilCallDirectedSuper (a super send of an inlined frame), the 64-bit method class
	 of the frame's method; then, for OilCallN/OilCallSuper/OilCallDirectedSuper, the packed argument registers."
	| instIndex |
	((self hasVirtualObjectFrom: rcvrSlot to: rcvrSlot + numArgs) and: [self isNeverSentAt: currentPC]) ifTrue:
		["A send never executed so far would make a virtual closure or object escape (e.g. the high resolution clock path
		  of Time class>>microsecondsToRun:, whose block is the loop of a benchmark): an uncommon trap keeps it virtual."
		 ^self genUncommonTrapForSendAt: rcvrSlot numArgs: numArgs].
	(self isEncodableCall: selector super: isSuper) ifFalse:
		[(currentFrame > 0 and: [self isNeverSentAt: currentPC]) ifTrue:
			[^self genUncommonTrapForSendAt: rcvrSlot numArgs: numArgs].
		 ^self refuseInliningOfFrameOf: currentFrame].
	rcvrSlot to: rcvrSlot + numArgs do: [:slotIndex| self materializeSlot: slotIndex].
	failed ifTrue: [^self].
	self recordSite: OilSiteCall.
	(isSuper or: [numArgs >= 2])
		ifTrue:
			[instIndex := self emitOp: (isSuper
										ifTrue: [currentFrame = 0 ifTrue: [OilCallSuper] ifFalse: [OilCallDirectedSuper]]
										ifFalse: [OilCallN]) a: rcvrSlot b: rcvrSlot c: numArgs.
			 self emit64: selector.
			 (isSuper and: [currentFrame > 0]) ifTrue:
				[self emit64: (self methodClassOopOfFrame: currentFrame)].
			 self emitPackedArgs: rcvrSlot + 1 count: numArgs]
		ifFalse:
			[instIndex := self emitOp: (numArgs = 0 ifTrue: [OilCall0] ifFalse: [OilCall1]) a: rcvrSlot b: rcvrSlot c: (numArgs = 0 ifTrue: [0] ifFalse: [rcvrSlot + 1]).
			 self emit64: selector].
	simStackTop := rcvrSlot.
	self setOwn: rcvrSlot.
	self noteDef: rcvrSlot at: instIndex! !

!OilInliningCompiler methodsFor: 'sends' stamp: 'cb 10/26/2026 20:45'!
quickPrimitiveConstant: prim
	"The constant answered by the quick primitive prim, 257 to 263: true, false, nil, -1, 0, 1 or 2."
	prim = 257 ifTrue: [^trueHandle].
	prim = 258 ifTrue: [^falseHandle].
	prim = 259 ifTrue: [^nilHandle].
	^self handleForSmallInteger: prim - 261! !

!OilInliningCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
genQuickMethod: prim receiver: rcvrSlot numArgs: numArgs
	"Quick primitives: 256 ^self, 257 ^true, 258 ^false, 259 ^nil, 260-263 ^-1/0/1/2, 264-519 ^instVar (prim - 264)."
	| descKind slotVal rcvrReg |
	descKind := slotKind at: rcvrSlot.
	slotVal := slotValue at: rcvrSlot.
	prim = 256 ifTrue:
		[simStackTop := rcvrSlot - 1.
		 ^self push: descKind value: slotVal].
	prim <= 263 ifTrue:
		[simStackTop := rcvrSlot - 1.
		 ^self push: OilDescConst value: (self quickPrimitiveConstant: prim)].
	descKind = OilDescObject ifTrue: "a slot of a scalar replaced object"
		[simStackTop := rcvrSlot - 1.
		 ^self pushVObjSlot: prim - 264 of: slotVal].
	rcvrReg := self regForSlot: rcvrSlot.
	simStackTop := rcvrSlot - 1.
	self pushResultOf: OilLoadField b: rcvrReg c: prim - 264 site: 0! !

!OilInliningCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
canInlineIntrinsic: prim class: classObj numArgs: n
	"at: (60), at:put: (61) and size (62) of pointer indexable objects without fixed fields (Array) and of byte objects
	 (ByteArray, ByteString), at: (63) and at:put: (64) of byte strings (Characters), compareWith: (158, the byte
	 comparison of String>>=) of byte objects, == (110), identityHash (75) of non-immediates, Character>>asInteger (171),
	 and ReadStream>>next (65) and WriteStream>>nextPut: (66)."
	| spec |
	prim = 110 ifTrue: [^n = 1].
	spec := self oilInstSpecOfClass: classObj.
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

!OilInliningCompiler methodsFor: 'sends' stamp: 'cb 10/24/2026 10:30'!
genIntrinsic: prim selector: selector receiver: rcvrSlot numArgs: numArgs bytes: isBytes
	<inline: false>
	| arrayReg indexReg valReg limitReg instIndex descKind slotVal |
	prim = 110 ifTrue:
		[^self genCompare: OilCondIdentical identity: true frame: currentFrame next: -1].
	prim = 75 ifTrue: "the hash in the header (no deopt site: the back end falls back to the send if there is none yet)"
		[(slotKind at: rcvrSlot) = OilDescConst ifTrue: "of a constant: computed now (assigned if it has none yet, as the send would)"
			[simStackTop := rcvrSlot - 1.
			 ^self push: OilDescConst value: (self handleForSmallInteger: (self identityHashOf: (slotValue at: rcvrSlot)))].
		 (self isEncodableCall: selector super: false) ifFalse:
			[^self genCall: selector numArgs: numArgs receiver: rcvrSlot super: false].
		 arrayReg := self regForSlot: rcvrSlot.
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

!OilInliningCompiler methodsFor: 'sends' stamp: 'cb 10/27/2026 11:50'!
genScanIntrinsic: method selector: selector receiver: rcvrSlot numArgs: numArgs class: rcvrClass guard: guard
	"Byte scans the back end compiles to word-at-a-time (8 bytes per iteration) or byte loops, falling back to the send
	 itself on unexpected operands (so they have no deopt site):
	 - primitive 153 / ByteString class>>indexOfAscii:inString:startingAt: (OilIndexOfByte, 2 or 3 args);
	 - primitive 154 / ByteString>>findSubstring:in:startingAt:matchTable: (OilFindSubstring, 2, 3 or 4 args);
	 - primitive 155 / String class>>findFirstInString:inSet:startingAt: (OilFindFirstInString, 2 or 3 args);
	 - PositionableStream>>skipSeparators of a ReadStream (OilSkipSeparators, 0 args).
	 Answer whether the send was compiled so."
	| prim isBytes opcode instIndex |
	method = 0 ifTrue: [^false].
	prim := self oilPrimitiveIndexOf: method.
	isBytes := (self oilInstSpecOfClass: rcvrClass) between: 16 and: 23.
	opcode := 0.
	((prim = 153 and: [numArgs = 3 or: [numArgs = 2 and: [isBytes]]])
	 or: [(self isIndexOfAsciiMethod: method) and: [numArgs = 3]]) ifTrue:
		[opcode := OilIndexOfByte].
	((prim = 154 and: [numArgs = 3 or: [numArgs = 4 or: [numArgs = 2 and: [isBytes]]]])
	 or: [prim = 117 and: [numArgs = 4 and: [self isFindSubstringMethod: method]]]) ifTrue:
		[opcode := OilFindSubstring].
	((prim = 155 and: [numArgs = 3 or: [numArgs = 2 and: [isBytes]]])
	 or: [prim = 117 and: [numArgs = 3 and: [self isFindFirstInStringMethod: method]]]) ifTrue:
		[opcode := OilFindFirstInString].
	((self isSkipSeparatorsMethod: method) and: [numArgs = 0 and: [self isByteStreamClass: rcvrClass]]) ifTrue:
		[opcode := OilSkipSeparators].
	(opcode = 0 or: [(self isEncodableCall: selector super: false) not]) ifTrue: [^false].
	guard ifTrue: [self emitGuardOn: (self regForSlot: rcvrSlot) class: rcvrClass].
	rcvrSlot to: rcvrSlot + numArgs do: [:slotIndex| self materializeSlot: slotIndex].
	failed ifTrue: [^true].
	instIndex := self emitOp: opcode a: rcvrSlot b: rcvrSlot c: numArgs.
	self emit64: selector.
	opcode ~= OilSkipSeparators ifTrue: [self emitPackedArgs: rcvrSlot + 1 count: numArgs].
	simStackTop := rcvrSlot.
	self setOwn: rcvrSlot.
	self noteDef: rcvrSlot at: instIndex.
	^true! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
genCompare: cond identity: isIdentity frame: frameIndex next: nextPC
	<inline: false>
	"Tagged SmallInteger comparison (or identity comparison).  Folds constants; fuses with a following
	 conditional jump (OilCmpTagged/OilCmpImmTagged + OilBranchTrue/False on the flags, r255);
	 otherwise materializes true/false.  Answer the pc to continue at."
	| slotA slotB scratchA scratchB kindA valA kindB valB condCode regA regB useImm immVal siteIndex resultBool |
	slotA := scratchA := simStackTop - 1.
	slotB := scratchB := simStackTop.
	kindA := slotKind at: slotA. valA := slotValue at: slotA.
	kindB := slotKind at: slotB. valB := slotValue at: slotB.
	condCode := cond.
	(isIdentity and: [kindA = OilDescObject or: [kindB = OilDescObject]]) ifTrue:
		"a scalar replaced object exists nowhere else: it is identical only to itself"
		[resultBool := (kindA = kindB and: [valA = valB]) = (condCode = OilCondIdentical).
		 simStackTop := slotA - 1.
		 self push: OilDescConst value: (resultBool ifTrue: [trueHandle] ifFalse: [falseHandle]).
		 ^nextPC].
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
		[self flushFrame: frameIndex.
		 self emitCompare: condCode reg: regA reg: regB imm: immVal useImm: useImm identity: isIdentity.
		 ^self emitFusedBranch: frameIndex].
	"Not followed by a conditional jump: answer a lazy comparison result (e.g. the result of an inlined block
	 that the caller tests).  It is compared and branched on when consumed by a jump, materialized as
	 true/false otherwise, or as soon as anything else is emitted."
	numConds >= OilMaxConds ifTrue:
		[^self abortCompilation: OilFailTooManyVirtualObjects].
	"The comparison is emitted later, when consumed, but it must deoptimize to the state at this bytecode:
	 record its deopt site now, its IR index is set when the comparison is emitted (see emitCompare:...)"
	isIdentity
		ifTrue: [siteIndex := -1]
		ifFalse:
			[siteIndex := self recordSite: OilSiteArith.
			 failed ifTrue: [^nextPC].
			 siteIR at: siteIndex put: -1].
	self pushLazyCond: condCode class: 0 ra: regA rb: (useImm ifTrue: [0] ifFalse: [regB]) imm: (useImm ifTrue: [immVal] ifFalse: [0])
		useImm: useImm identity: isIdentity site: siteIndex.
	^nextPC! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/27/2026 12:55'!
pushLazyCond: condCode class: classOop ra: regA rb: regB imm: immVal useImm: useImm identity: isIdentity site: siteIndex
	"Push the lazy comparison result (OilDescCond) numConds, a comparison (see emitCondCompare:) or, if classOop is not 0,
	 a class test, and make it the pending one (materializing the previous one first).  Answer its index."
	| condIndex |
	self materializePendingCondIfAny.
	condIndex := numConds.
	(self condAt: condIndex) cond: condCode.
	(self condAt: condIndex) testClass: classOop.
	(self condAt: condIndex) regA: regA.
	(self condAt: condIndex) regB: regB.
	(self condAt: condIndex) imm: immVal.
	(self condAt: condIndex) useImm: useImm.
	(self condAt: condIndex) identity: isIdentity.
	(self condAt: condIndex) frame: currentFrame.
	(self condAt: condIndex) pc: currentPC.
	(self condAt: condIndex) site: siteIndex.
	pendingCondSlot := self push: OilDescCond value: condIndex.
	pendingCondIndex := condIndex.
	numConds := condIndex + 1.
	^condIndex! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/26/2026 20:45'!
emitFusedBranch: frameIndex
	"Emit the conditional jump that canFuseBranchAt:frame: found after the comparison just emitted, as a branch on the flags,
	 and answer the pc to continue at."
	self emitBranch: (fusedBranchTag = OilTagJumpTrue ifTrue: [OilBranchTrue] ifFalse: [OilBranchFalse])
		cond: OilFlagsReg to: fusedBranchTarget frame: frameIndex.
	^fusedBranchNext! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/26/2026 20:45'!
emitDiamondInto: destReg trueKind: trueKind value: trueValue falseKind: falseKind value: falseValue
	"After a comparison (on the flags): destReg := its true value if it holds, else its false value, each a constant
	 (OilDescConst) or a register (OilDescReg)."
	| branchFalseJump exitJump |
	branchFalseJump := self emitOp: OilBranchFalse a: OilFlagsReg imm16: 0.
	self emitValueKind: trueKind value: trueValue into: destReg.
	exitJump := self emitOp: OilJump a: 0 imm16: 0.
	self patchBranch: branchFalseJump to: irIndex.
	self emitValueKind: falseKind value: falseValue into: destReg.
	self patchBranch: exitJump to: irIndex.
	lastLabelIR := irIndex.
	knownClass at: destReg put: 0! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/26/2026 20:45'!
emitValueKind: kind value: value into: destReg
	"destReg := the register value (kind OilDescReg) or the constant value (OilDescConst)."
	kind = OilDescReg
		ifTrue: [self emitMove: destReg from: value]
		ifFalse: [self emitConst: value into: destReg]! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
emitCondCompare: condIndex
	"Emit the comparison of the lazy comparison result condIndex (its deopt site is the comparison's bytecode)."
	| savedPC savedFrame savedCond |
	savedPC := currentPC.
	savedFrame := currentFrame.
	currentPC := (self condAt: condIndex) pc.
	currentFrame := (self condAt: condIndex) frame.
	savedCond := emittingCond.
	emittingCond := condIndex.
	(self condAt: condIndex) testClass ~= 0
		ifTrue: "the class test of a bimorphic predicate (see genBimorphicPredicate:...): no deopt"
			[self emitOp: OilCmpClass a: (self condAt: condIndex) cond b: (self condAt: condIndex) regA c: 0.
			 self emit64: (self condAt: condIndex) testClass]
		ifFalse: [self emitCompare: (self condAt: condIndex) cond reg: (self condAt: condIndex) regA reg: (self condAt: condIndex) regB
		imm: (self condAt: condIndex) imm useImm: (self condAt: condIndex) useImm identity: (self condAt: condIndex) identity].
	emittingCond := savedCond.
	currentPC := savedPC.
	currentFrame := savedFrame! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
emitCond: condIndex booleanInto: destReg
	<inline: false>
	"Materialize the lazy comparison result condIndex as true or false in register destReg."
	pendingCondIndex = condIndex ifTrue: [pendingCondSlot := -1].
	self emitCondCompare: condIndex.
	self emitDiamondInto: destReg trueKind: OilDescConst value: trueHandle falseKind: OilDescConst value: falseHandle! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/27/2026 12:55'!
isLazyKind: descKind
	"Is descKind that of a lazy comparison result (OilDescCond)?"
	<inline: true>
	^descKind = OilDescCond! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/26/2026 20:50'!
materializePendingCondIfAny
	"Materialize the pending lazy comparison result, if any, before emitting anything that may clobber its operands."
	<inline: true>
	pendingCondSlot >= 0 ifTrue: [self materializePendingCond]! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/27/2026 12:55'!
materializePendingCond
	<inline: false>
	| slotIndex |
	slotIndex := pendingCondSlot.
	pendingCondSlot := -1.
	(slotIndex <= simStackTop and: [(slotKind at: slotIndex) = OilDescCond and: [(slotValue at: slotIndex) = pendingCondIndex]]) ifTrue:
		[self emitCond: pendingCondIndex booleanInto: slotIndex.
		 self setOwn: slotIndex]! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
reversedCondition: condCode
	"The condition condCode with its operands swapped: x < y iff y > x."
	condCode = OilCondLt ifTrue: [^OilCondGt].
	condCode = OilCondGt ifTrue: [^OilCondLt].
	condCode = OilCondLe ifTrue: [^OilCondGe].
	condCode = OilCondGe ifTrue: [^OilCondLe].
	^condCode! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
canFuseBranchAt: targetPC frame: frameIndex
	"Is the instruction at targetPC (in frame frameIndex) a conditional jump that is not itself a branch target?  If so,
	 note it for emitFusedBranch: (flushing the frame decodes other bytecodes)."
	targetPC > (self frameAt: frameIndex) endPC ifTrue: [^false].
	(pcTarget at: (self pcMapIndex: targetPC frame: frameIndex)) ~= 0 ifTrue: [^false].
	self setScanMethod: (self frameAt: frameIndex) method.
	self decodeAt: targetPC.
	(opcodeTag = OilTagJumpTrue or: [opcodeTag = OilTagJumpFalse]) ifFalse: [^false].
	fusedBranchTag := opcodeTag.
	fusedBranchTarget := oilTargetPC.
	fusedBranchNext := oilNextPC.
	^true! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
emitCompare: condCode reg: regA reg: regB imm: immVal useImm: useImm identity: isIdentity
	isIdentity ifFalse:
		[emittingCond >= 0
			ifTrue: [self useCondSite: (self condAt: emittingCond) site]
			ifFalse: [self recordSite: OilSiteArith]].
	useImm
		ifTrue: [self emitOp: OilCmpImmTagged a: condCode b: regA c: immVal]
		ifFalse: [self emitOp: OilCmpTagged a: condCode b: regA c: regB]! !

!OilInliningCompiler methodsFor: 'deoptimization metadata' stamp: 'cb 10/24/2026 14:00'!
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

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
compareSmallInteger: val1 with: val2 cond: condCode
	condCode = OilCondLt ifTrue: [^val1 < val2].
	condCode = OilCondGt ifTrue: [^val1 > val2].
	condCode = OilCondLe ifTrue: [^val1 <= val2].
	condCode = OilCondGe ifTrue: [^val1 >= val2].
	condCode = OilCondEq ifTrue: [^val1 = val2].
	^val1 ~= val2! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
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

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
foldArith: selectorIndex
	"Constant fold SmallInteger arithmetic when the result is a SmallInteger.  The same in C, where / and % truncate
	 (\\ and // are floored here) and products and left shifts must not overflow 64 bits (they are not folded then)."
	| rcvrSlot val1 val2 resultVal |
	rcvrSlot := simStackTop - 1.
	val1 := self smallIntegerValueOf: (slotValue at: rcvrSlot).
	val2 := self smallIntegerValueOf: (slotValue at: simStackTop).
	resultVal := selectorIndex caseOf: {
		[0] -> [val1 + val2].
		[1] -> [val1 - val2].
		[8] -> [((val1 between: -16r40000000 and: 16r40000000) and: [val2 between: -16r40000000 and: 16r40000000]) ifFalse: [^false].
				val1 * val2].
		[10] -> [val2 = 0 ifTrue: [^false]. self flooredModulo: val1 by: val2].
		[12] -> [(val1 >= 0 and: [val2 between: -60 and: 60]) ifFalse: [^false].
				(val2 > 0 and: [((val1 bitShift: val2) bitShift: 0 - val2) ~= val1]) ifTrue: [^false].
				val1 bitShift: val2].
		[13] -> [val2 = 0 ifTrue: [^false]. (val1 - (self flooredModulo: val1 by: val2)) // val2].
		[14] -> [val1 bitAnd: val2].
		[15] -> [val1 bitOr: val2].
		[18] -> [val1 bitXor: val2] }
		otherwise: [^false].
	(self isSmallIntegerValue: resultVal) ifFalse: [^false].
	simStackTop := rcvrSlot - 1.
	self push: OilDescConst value: (self handleForSmallInteger: resultVal).
	^true! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/28/2026 04:10'!
flooredModulo: val1 by: val2
	"val1 \\ val2 (floored: the sign of val2), val2 ~= 0, in Smalltalk and in C (whose % truncates: the sign of val1)."
	| remainder |
	remainder := val1 \\ val2.
	(remainder ~= 0 and: [(remainder < 0) ~= (val2 < 0)]) ifTrue:
		[remainder := remainder + val2].
	^remainder! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
genAdd
	| rcvrSlot argSlot |
	rcvrSlot := simStackTop - 1.
	argSlot := simStackTop.
	(slotKind at: argSlot) = OilDescConst ifTrue:
		[^self genAddConstant: (self smallIntegerValueOf: (slotValue at: argSlot)) to: rcvrSlot result: rcvrSlot].
	(slotKind at: rcvrSlot) = OilDescConst ifTrue: "commutative: c + x"
		[^self genAddConstant: (self smallIntegerValueOf: (slotValue at: rcvrSlot)) to: argSlot result: rcvrSlot].
	^self genBinaryTagged: OilAddTagged! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
genSub
	| argSlot |
	argSlot := simStackTop.
	(slotKind at: argSlot) = OilDescConst ifTrue:
		[^self genAddConstant: (self smallIntegerValueOf: (slotValue at: argSlot)) negated to: argSlot - 1 result: argSlot - 1].
	^self genBinaryTagged: OilSubTagged! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 19:20'!
genBinaryTagged: opcode
	"Dest := Src1 op Src2 on tagged SmallIntegers (implicit tag/overflow checks, deopt on failure)."
	| rcvrSlot argSlot regA regB |
	rcvrSlot := simStackTop - 1.
	argSlot := simStackTop.
	regA := self regForSlot: rcvrSlot.
	regB := self regForSlot: argSlot.
	simStackTop := rcvrSlot - 1.
	^self pushSmallIntegerResultOf: opcode b: regA c: regB! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/26/2026 21:45'!
genAddConstant: constantVal to: operandSlot result: resultSlot
	"x + c: x + 0 => x, else Tagged(x) + 8c, emitted as OilAddImmTagged when c fits 8 signed bits."
	| descKind slotVal operandReg destReg instIndex scratchReg |
	descKind := slotKind at: operandSlot.
	slotVal := slotValue at: operandSlot.
	constantVal = 0 ifTrue:
		[simStackTop := resultSlot - 1.
		 self push: descKind value: slotVal.
		 ^true].
	operandReg := self regForSlot: operandSlot.
	simStackTop := resultSlot - 1.
	destReg := self pushOwnSlot.
	(constantVal between: -128 and: 127)
		ifTrue:
			[self recordSite: OilSiteArith.
			 instIndex := self emitOp: OilAddImmTagged a: destReg b: operandReg c: (constantVal bitAnd: 255)]
		ifFalse:
			[scratchReg := operandSlot + 1.
			 self emitConst: (self handleForSmallInteger: constantVal) into: scratchReg.
			 self recordSite: OilSiteArith.
			 instIndex := self emitOp: OilAddTagged a: destReg b: operandReg c: scratchReg].
	self noteDef: destReg at: instIndex.
	knownClass at: destReg put: smallIntegerClassHandle.
	^true! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
constantPowerOfTwo: number
	"Answer k if number = 2^k (k >= 0), else -1."
	| power |
	number <= 0 ifTrue: [^-1].
	(number bitAnd: number - 1) = 0 ifFalse: [^-1].
	power := 0.
	[(1 bitShift: power) < number] whileTrue: [power := power + 1].
	^power! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
replaceOperandsBy: descKind value: descValue
	"Pop receiver and argument, push (descKind, descValue)."
	simStackTop := simStackTop - 2.
	self push: descKind value: descValue.
	^true! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
emitShift: shiftCount of: srcReg into: destReg
	"OilShiftTagged: shiftCount > 0 arithmetic right shift (exact floor division by 2^k: sarq 3+k, shlq 3, orq 1);
	 shiftCount < 0 left shift by -shiftCount (multiplication by 2^-k, overflow checked)."
	| instIndex |
	self recordSite: OilSiteArith.
	instIndex := self emitOp: OilShiftTagged a: destReg b: srcReg c: (shiftCount bitAnd: 255).
	self noteDef: destReg at: instIndex.
	knownClass at: destReg put: smallIntegerClassHandle! !

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 19:20'!
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

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 19:20'!
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

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 19:20'!
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

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 19:20'!
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

!OilInliningCompiler methodsFor: 'arithmetic' stamp: 'cb 10/24/2026 10:30'!
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

!OilInliningCompiler methodsFor: 'inlining' stamp: 'cb 10/27/2026 14:05'!
inlineMethod: aMethod receiver: rcvrReg numArgs: numArgs class: classObj guard: guard
	<inline: false>
	"Inline aMethod, sent to the receiver in rcvrReg with its numArgs arguments in the following registers.
	 The send dissolves: the receiver binds to the inlined method's self, the arguments to its argument registers,
	 its temps follow, and its returns leave the result in rcvrReg and jump to the exit label.
	 classObj is the receiver class used for lookup; if guard, it is guarded first (OilGuardClass).
	 Answer false (nothing emitted) if aMethod cannot be inlined."
	| frameIndex |
	frameIndex := self newFrameFor: aMethod base: rcvrReg isBlock: false.
	frameIndex < 0 ifTrue: [^false].
	((slotKind at: rcvrReg) = OilDescObject and: [(self canInlineOnVObj: frameIndex) not]) ifTrue:
		[self materializeSlot: rcvrReg].
	guard ifTrue: [self emitGuardOn: (self regForSlot: rcvrReg) class: classObj].
	self stabilizeIncomingSlot: rcvrReg.
	(self frameAt: frameIndex) selfKind: (slotKind at: rcvrReg).
	(self frameAt: frameIndex) selfValue: (slotValue at: rcvrReg).
	(self frameAt: frameIndex) selfClass: classObj.
	(slotKind at: rcvrReg) = OilDescReg ifTrue:
		[knownClass at: (slotValue at: rcvrReg) put: classObj].
	self bindFrame: frameIndex base: rcvrReg numArgs: numArgs numCopied: 0.
	self translateFrame: frameIndex.
	self exitFrame: frameIndex.
	^true! !

!OilInliningCompiler methodsFor: 'inlining' stamp: 'cb 10/27/2026 14:05'!
inlineBlock: vobjIndex receiver: closureReg numArgs: numArgs
	<inline: false>
	"Inline the evaluation (value, value:, ...) of the virtual closure vobjIndex held in closureReg: no closure is
	 allocated and no block activation happens.  The block's arguments bind in place, its copied values bind
	 to the captured descriptors, its self is its home's self, its local return leaves the result in closureReg
	 and its non-local returns return from its (inlined) home frame."
	| block frameIndex numCopied baseIndex depth limit |
	block := (self vobjAt: vobjIndex) literal.
	(self numArgsOf: block) = numArgs ifFalse: [^false].
	depth := (self frameAt: currentFrame) depth + 1.
	limit := oilMaxInlineDepthValue > 0 ifTrue: [oilMaxInlineDepthValue] ifFalse: [OilMaxInlineDepth].
	(depth > limit or: [irInstCount >= irBudget]) ifTrue: [^false].
	(self isFrameActive: (self vobjAt: vobjIndex) homeFrame) ifFalse: [^false].
	frameIndex := self newFrameFor: block base: closureReg isBlock: true.
	frameIndex < 0 ifTrue: [^false].
	(self frameAt: frameIndex) home: (self vobjAt: vobjIndex) homeFrame.
	(self frameAt: frameIndex) selfKind: (self vobjAt: vobjIndex) rcvrKind.
	(self frameAt: frameIndex) selfValue: (self vobjAt: vobjIndex) rcvrValue.
	(self frameAt: frameIndex) selfClass: (self vobjAt: vobjIndex) vobjClass.
	numCopied := (self vobjAt: vobjIndex) copiedCount.
	baseIndex := (self vobjAt: vobjIndex) copiedBase.
	0 to: numCopied - 1 do:
		[:copiedIndex| | copiedReg |
		copiedReg := closureReg + numArgs + 1 + copiedIndex.
		slotFlags at: copiedReg put: OilFlagImmutable.
		self setSlot: copiedReg kind: (capturedKind at: baseIndex + copiedIndex) value: (capturedValue at: baseIndex + copiedIndex)].
	self bindFrame: frameIndex base: closureReg numArgs: numArgs numCopied: numCopied.
	self translateFrame: frameIndex.
	self exitFrame: frameIndex.
	^true! !

!OilInliningCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
opcodeAt: index
	^(oilIRBuffer at: index) bitShift: -24! !

!OilInliningCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
fieldAAt: index
	^((oilIRBuffer at: index) bitShift: -16) bitAnd: 255! !

!OilInliningCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
fieldBAt: index
	^((oilIRBuffer at: index) bitShift: -8) bitAnd: 255! !

!OilInliningCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
fieldCAt: index
	^(oilIRBuffer at: index) bitAnd: 255! !

!OilInliningCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
imm16At: index
	^(oilIRBuffer at: index) bitAnd: 16rFFFF! !

!OilInliningCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
signed8: byte
	^byte > 127 ifTrue: [byte - 256] ifFalse: [byte]! !

!OilInliningCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
signed16: word
	^word > 32767 ifTrue: [word - 65536] ifFalse: [word]! !

!OilInliningCompiler methodsFor: 'IR access' stamp: 'cb 10/24/2026 10:30'!
word64At: index
	"The 64-bit operand stored at index (low word) and index + 1 (high word), sign extended."
	| val64 |
	val64 := (oilIRBuffer at: index) + ((oilIRBuffer at: index + 1) bitShift: 32).
	^self cCode: [val64] inSmalltalk: [val64 >= (1 bitShift: 63) ifTrue: [val64 - (1 bitShift: 64)] ifFalse: [val64]]! !

!OilInliningCompiler methodsFor: 'IR access' stamp: 'cb 10/26/2026 20:30'!
instructionLengthAt: index
	"The length in words of the instruction at index: its fixed part, plus the words of its packed argument registers."
	| info |
	info := oilOpInfo at: (self opcodeAt: index).
	^(info bitAnd: OilOpPackedArgs) = 0
		ifTrue: [info bitAnd: OilOpLengthMask]
		ifFalse: [(info bitAnd: OilOpLengthMask) + ((self fieldCAt: index) + 3 // 4)]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
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

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
objectFor: aHandle
	<doNotGenerate>
	(aHandle bitAnd: 7) = 1 ifTrue: [^aHandle bitShift: -3].
	(aHandle bitAnd: 7) = 2 ifTrue: [^Character value: (aHandle bitShift: -3)].
	^simHandles at: (aHandle bitShift: -3)! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
isSmallIntegerHandle: aHandle
	<inline: true>
	^(aHandle bitAnd: 7) = 1! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/25/2026 07:30'!
isCharacterHandle: aHandle
	<inline: true>
	^self cCode: [objectMemory isCharacterObject: aHandle] inSmalltalk: [(aHandle bitAnd: 7) = 2]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
smallIntegerValueOf: aHandle
	<inline: true>
	^self cCode: [objectMemory integerValueOf: aHandle] inSmalltalk: [aHandle bitShift: -3]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
handleForSmallInteger: anInteger
	<inline: true>
	^self cCode: [objectMemory integerObjectOf: anInteger] inSmalltalk: [(anInteger bitShift: 3) + 1]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
handleForCharacter: anInteger
	<inline: true>
	^self cCode: [objectMemory characterObjectOf: anInteger] inSmalltalk: [(anInteger bitShift: 3) + 2]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
isSmallIntegerValue: anInteger
	<inline: true>
	^self cCode: [objectMemory isIntegerValue: anInteger] inSmalltalk: [anInteger between: SmallInteger minVal and: SmallInteger maxVal]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
classOopOf: aHandle
	^self cCode: [coInterpreter oilApiFetchClassOf: aHandle] inSmalltalk: [self handleFor: (self objectFor: aHandle) class]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/27/2026 12:25'!
oilInstSpecOfClass: classOop
	classOop = 0 ifTrue: [^-1].
	^self cCode: [coInterpreter oilApiInstSpecOfClass: classOop] inSmalltalk: [(self objectFor: classOop) instSpec]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
oilLiteral: index ofMethod: aMethod
	<inline: true>
	^self cCode: [coInterpreter literal: index ofMethod: aMethod] inSmalltalk: [aMethod literalAt: index + 1]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
literalHandle: index frame: frameIndex
	^self handleFor: (self oilLiteral: index ofMethod: (self frameAt: frameIndex) method)! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
isReadOnlyBinding: binding
	"Class bindings are read-only: fold them to their value."
	^self cCode: [self isClassBinding: binding] inSmalltalk: [binding isKindOf: ClassBinding]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/25/2026 09:30'!
isClassBinding: binding
	"In the VM: is binding an instance of the class of class bindings (ClassBinding in Squeak 6), which is the class of
	 the last literal (the method class association) of the instance side methods (whose key is the class's name; on the
	 class side, the key is nil)?  It is found in the root method or the method of the current frame."
	| meta |
	oilClassBindingClass <= 0 ifTrue:
		[oilClassBindingClass := coInterpreter oilApiClassBindingClassOf:
									((oilClassBindingClass = 0 or: [currentFrame < 0])
										ifTrue: [oilHomeMethod]
										ifFalse: [(self frameAt: currentFrame) method]).
		 oilClassBindingClass = 0 ifTrue: [oilClassBindingClass := -1]].
	oilClassBindingClass <= 0 ifTrue: [^false].
	((objectMemory isNonImmediate: binding)
	  and: [(coInterpreter oilApiFetchClassOf: binding) = oilClassBindingClass
	  and: [(objectMemory fetchPointer: 1 ofObject: binding) ~= nilHandle]]) ifFalse: [^false].
	"and its value is a Behavior: m, the class of its class, is Metaclass (Metaclass class for a metaclass); only
	 those satisfy m class class == m"
	meta := coInterpreter oilApiFetchClassOf: (coInterpreter oilApiFetchClassOf: (objectMemory fetchPointer: 1 ofObject: binding)).
	^(coInterpreter oilApiFetchClassOf: (coInterpreter oilApiFetchClassOf: meta)) = meta! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/25/2026 09:30'!
identityHashOf: aHandle
	"The identity hash of a non-immediate constant (assigned now if it has none yet, as primitive 75 would)."
	^self cCode: [coInterpreter oilApiHashBitsOf: aHandle] inSmalltalk: [(self objectFor: aHandle) identityHash]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
bindingValueHandle: binding
	^self cCode: [objectMemory fetchPointer: 1 ofObject: binding] inSmalltalk: [self handleFor: binding value]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
specialSelectorHandle: index
	^self cCode: [coInterpreter specialSelector: index] inSmalltalk: [self handleFor: (Smalltalk specialSelectors at: index * 2 + 1)]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
numArgsOf: aMethod
	<inline: true>
	^self cCode: [coInterpreter argumentCountOf: aMethod] inSmalltalk: [aMethod numArgs]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
numTempsOf: aMethod
	<inline: true>
	^self cCode: [coInterpreter tempCountOf: aMethod] inSmalltalk: [aMethod numTemps]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
frameSizeOf: aMethod
	"Slots needed for temps and stack: 16 or 56 (large frame)."
	<inline: true>
	^self
		cCode: [(coInterpreter methodNeedsLargeContext: aMethod) ifTrue: [56] ifFalse: [16]]
		inSmalltalk: [aMethod frameSize]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
oilPrimitiveIndexOf: aMethod
	<inline: true>
	^self cCode: [coInterpreter primitiveIndexOf: aMethod] inSmalltalk: [aMethod primitive]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
oilIsQuickPrimitiveIndex: prim
	<inline: true>
	^prim between: 256 and: 519! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
lookup: selector inClass: classOop
	"Answer the method found by looking up selector in the class, or 0.  Note the selector: the code may depend on the
	 lookup (an inlined method, quick method or intrinsic; see noteInlinedSelector:)."
	| method |
	method := self
		cCode: [coInterpreter oilApiLookupSelector: selector inClass: classOop]
		inSmalltalk: [((self objectFor: classOop) lookupSelector: (self objectFor: selector)) ifNil: [0]].
	method ~= 0 ifTrue: [self noteInlinedSelector: selector].
	^method! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/25/2026 23:10'!
noteInlinedSelector: selector
	"Record selector in the inlined selectors of the method being compiled, which go into its metadata: defining or
	 removing a method of that selector (ProfilingCogit>>unlinkSendsOf:isMNUSelector:) frees the Oil method.  This records
	 every selector Oil looked up at compile time (a superset of those it inlined, which is safe).  Past
	 OilMaxInlinedSelectors, oilNumInlinedSelectors is OilMaxInlinedSelectors + 1: any selector invalidates the method."
	oilNumInlinedSelectors > OilMaxInlinedSelectors ifTrue: [^self].
	(self includes: selector in: oilInlinedSelectors count: oilNumInlinedSelectors) ifTrue: [^self].
	oilNumInlinedSelectors = OilMaxInlinedSelectors ifTrue:
		[oilNumInlinedSelectors := OilMaxInlinedSelectors + 1.
		 ^self].
	oilInlinedSelectors at: oilNumInlinedSelectors put: selector.
	oilNumInlinedSelectors := oilNumInlinedSelectors + 1! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/25/2026 23:10'!
numInlinedSelectorsInMetadata
	"The number of selectors in the metadata's inlined selectors section (none when there are too many to record)."
	^oilNumInlinedSelectors > OilMaxInlinedSelectors ifTrue: [0] ifFalse: [oilNumInlinedSelectors]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/26/2026 09:30'!
methodClassOopOfFrame: frameIndex
	"The class a super send of frame frameIndex binds to: the method class of its home method, or 0 if it has none."
	| homeMethod methodClass |
	homeMethod := (self frameAt: (self frameAt: frameIndex) home) method.
	methodClass := self
						cCode: [coInterpreter methodClassOf: homeMethod]
						inSmalltalk: [self handleFor: homeMethod methodClass].
	^methodClass = nilHandle ifTrue: [0] ifFalse: [methodClass]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
superclassOopOfMethodClassOf: aMethod
	^self
		cCode: [coInterpreter oilApiSuperclassOf: (coInterpreter methodClassOf: aMethod)]
		inSmalltalk: [self handleFor: aMethod methodClass superclass]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/24/2026 10:30'!
profiledClassAt: pc
	"Type feedback for the send at pc in the current frame's method: the receiver class if the site is monomorphic, else 0.
	 In the VM this queries ProfilingCogit's inline caches; in the image, a simulated-execution profile."
	^self
		cCode: [cogit oilMonomorphicClassAt: pc in: (self frameAt: currentFrame) method]
		inSmalltalk:
			[typeFeedback
				ifNil: [0]
				ifNotNil: [(typeFeedback classAt: pc in: (self frameAt: currentFrame) method)
							ifNil: [0]
							ifNotNil: [:classObj| self handleFor: classObj]]]! !

!OilInliningCompiler class methodsFor: 'translation' stamp: 'cb 10/24/2026 19:35'!
declareCVarsIn: aCCodeGenerator
	"All of Pass 1's memory is static: the 16 KB IR buffer and fixed size tables (BSS), invisible to the GC."
	self == OilInliningCompiler ifFalse: [^self].
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
	#(slotKind slotValue knownClass lastDefIR) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilNumRegs]'].
	aCCodeGenerator var: #slotFlags declareC: 'static unsigned char slotFlags[OilNumRegs]'.
	aCCodeGenerator var: #oilFrames declareC: 'static OilVirtualFrame oilFrames[OilMaxFrames]'.
	"The pc map (per inlined frame bytecode labels) is the largest table: keep it compact (8192 x 6 bytes = 48 KB)."
	aCCodeGenerator var: #pcTarget declareC: 'static unsigned char pcTarget[OilPCMapSize]'.
	aCCodeGenerator var: #pcLabelIR declareC: 'static short pcLabelIR[OilPCMapSize]'.
	aCCodeGenerator var: #pcChain declareC: 'static unsigned short pcChain[OilPCMapSize]'.
	aCCodeGenerator var: #pcDepth declareC: 'static unsigned char pcDepth[OilPCMapSize]'.
	aCCodeGenerator var: #pcLoop declareC: 'static unsigned char pcLoop[OilPCMapSize]'.
	aCCodeGenerator var: #oilDisqualified declareC: 'static sqInt oilDisqualified[OilMaxDisqualified]'.
	aCCodeGenerator var: #oilNoInline declareC: 'static sqInt oilNoInline[16]'.
	aCCodeGenerator var: #oilInlinedSelectors declareC: 'static sqInt oilInlinedSelectors[OilMaxInlinedSelectors]'.
	"Deoptimization metadata planning (see planMetadata): the literals, slot indices from 1, and their hash table."
	aCCodeGenerator var: #oilMDLiterals declareC: 'static sqInt oilMDLiterals[OilMaxMDLiterals]'.
	aCCodeGenerator var: #oilMDLitHash declareC: 'static unsigned short oilMDLitHash[OilMDLiteralHashSize]'.
	aCCodeGenerator var: #oilVObjs declareC: 'static OilVirtualObject oilVObjs[OilMaxVObjs]'.
	#(capturedKind capturedValue) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilMaxCaptured]'].
	#(siteIR siteFrame sitePC siteKind siteSnapBase siteSnapTop siteSnapHigh) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilMaxSites]'].
	aCCodeGenerator var: #oilConds declareC: 'static OilLazyCondition oilConds[OilMaxConds]'.
	"Deoptimization metadata: the virtual state at the current bytecode and the states recorded at deopt sites."
	#(snapKind snapValue) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilNumRegs]'].
	#(sitePoolKind sitePoolValue) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilSitePoolSize]'].
	aCCodeGenerator var: #oilLiveMark declareC: 'static unsigned char oilLiveMark[OilPCMapSize]'.
	"Pass 3 (native code generation) tables."
	#(oilVRegReg oilVRegSpillTemp) do:
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
	#(oilXmmVReg oilXmmKind) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilNumXmms]'].
	aCCodeGenerator var: #oilPollJump declareC: 'static AbstractInstruction *oilPollJump[OilMaxPolls]'.
	aCCodeGenerator var: #oilPollResume declareC: 'static AbstractInstruction *oilPollResume[OilMaxPolls]'.
	aCCodeGenerator var: #oilPollSite declareC: 'static sqInt oilPollSite[OilMaxPolls]'.
	aCCodeGenerator
		var: #oilOpInfo
		declareC: 'static const unsigned short oilOpInfo[OilLastOpcode + 1] = {',
					((OilInstructionConstants opInfoTable collect: [:info| info printString]) inject: '' into: [:all :each| all isEmpty ifTrue: [each] ifFalse: [all, ', ', each]]),
					'}'.
	aCCodeGenerator var: #valueSelectors declareC: 'static sqInt valueSelectors[5]'.
	aCCodeGenerator var: #coldSelectors declareC: 'static sqInt coldSelectors[32] /* OilMaxColdSelectors */'.
	aCCodeGenerator
		var: #oilDefaultColdSelectorNames
		declareC: 'static const char *oilDefaultColdSelectorNames[] = {',
					(String streamContents: [:stream | self defaultColdSelectors do: [:selector | stream nextPut: $"; nextPutAll: selector; nextPut: $"] separatedBy: [stream nextPutAll: ', ']]),
					'}'.
	#(typeFeedback simHandles simHandleIndex) do:
		[:var| aCCodeGenerator removeVariable: var]! !

!OilInliningCompiler methodsFor: 'scalar replacement' stamp: 'cb 10/25/2026 09:30'!
genNewObject: prim receiver: rcvrSlot class: rcvrClass guard: guard
	"Scalar replacement of objects of classes with fixed pointer fields only: basicNew (primitive 70) of a constant class,
	 and Number>>@ (primitive 18, a Point of the receiver and the argument, which its fallback code answers too) are not
	 allocated but answer a virtual object (OilDescObject) whose slots are high registers (like the slots of a scalar
	 replaced temp vector: named temps of the object, flushed at labels).  Inlined methods of the object read and write
	 them (genPushRcvrVar:frame:, genStoreRcvrVar:pop:frame:, genQuickMethod:receiver:numArgs:), and if the object never
	 escapes it is never allocated.  If it escapes it is materialized (see materializeVObj:scratch:).  Answer whether the
	 send was compiled so."
	| classObj numSlots baseReg vobjIndex |
	prim = 70
		ifTrue:
			[(slotKind at: rcvrSlot) = OilDescConst ifFalse: [^false].
			 classObj := slotValue at: rcvrSlot.
			 (self isScalarReplaceableClass: classObj) ifFalse: [^false]]
		ifFalse:
			[classObj := self pointClassHandle.
			 (self isScalarReplaceableClass: classObj) ifFalse: [^false]].
	numSlots := self oilFixedFieldsOfClass: classObj.
	(numSlots > OilMaxVObjSlots or: [prim = 18 and: [numSlots ~= 2]]) ifTrue: [^false].
	((highRegTop - numSlots) <= (simStackTop + 32) or: [numVObjs >= OilMaxVObjs]) ifTrue: [^false].
	guard ifTrue: [self emitGuardOn: (self regForSlot: rcvrSlot) class: rcvrClass].
	failed ifTrue: [^true].
	vobjIndex := self newVObj: OilDescObject.
	baseReg := highRegTop - numSlots + 1.
	highRegTop := baseReg - 1.
	(self vobjAt: vobjIndex) numSlots: numSlots.
	(self vobjAt: vobjIndex) slotBase: baseReg.
	(self vobjAt: vobjIndex) vobjClass: classObj.
	(self vobjAt: vobjIndex) rcvrKind: OilDescConst.
	(self vobjAt: vobjIndex) rcvrValue: nilHandle.
	(self vobjAt: vobjIndex) literal: (self frameAt: currentFrame) method.
	(self vobjAt: vobjIndex) allocPC: currentPC.
	baseReg to: baseReg + numSlots - 1 do:
		[:slotReg|
		slotFlags at: slotReg put: OilFlagTVSlot.
		self setSlot: slotReg kind: OilDescConst value: nilHandle].
	prim = 18
		ifTrue: "x := the receiver, y := the argument (moved, not retargeted: the deopt state refers to their registers)"
			[self initVObjSlot: baseReg + 1 from: rcvrSlot + 1.
			 self initVObjSlot: baseReg from: rcvrSlot].
	simStackTop := rcvrSlot - 1.
	self push: OilDescObject value: vobjIndex.
	oilNumVirtualized := oilNumVirtualized + 1.
	^true! !

!OilInliningCompiler methodsFor: 'scalar replacement' stamp: 'cb 10/25/2026 09:30'!
isScalarReplaceableClass: classOop
	"Instances of classOop have fixed pointer fields only (format 0 or 1: no indexable fields, not weak, not an
	 ephemeron), and it has a class index (its instances can be allocated with it)."
	| spec |
	classOop = 0 ifTrue: [^false].
	spec := self oilInstSpecOfClass: classOop.
	(spec = 0 or: [spec = 1]) ifFalse: [^false].
	^self cCode: [(coInterpreter oilApiClassIndexOfClass: classOop) > 0] inSmalltalk: [true]! !

!OilInliningCompiler methodsFor: 'scalar replacement' stamp: 'cb 10/25/2026 09:30'!
pointClassHandle
	^self cCode: [objectMemory splObj: ClassPoint] inSmalltalk: [self handleFor: Point]! !

!OilInliningCompiler methodsFor: 'scalar replacement' stamp: 'cb 10/25/2026 09:30'!
oilFixedFieldsOfClass: classOop
	^self cCode: [coInterpreter oilApiFixedFieldsOfClass: classOop] inSmalltalk: [(self objectFor: classOop) instSize]! !

!OilInliningCompiler methodsFor: 'scalar replacement' stamp: 'cb 10/25/2026 09:30'!
pushVObjSlot: slotIndex of: vobjIndex
	"Push slot slotIndex of the scalar replaced object vobjIndex (the descriptor of its slot register)."
	| slotReg |
	slotIndex >= (self vobjAt: vobjIndex) numSlots ifTrue:
		[^self abortCompilation: OilFailInternal].
	slotReg := (self vobjAt: vobjIndex) slotBase + slotIndex.
	self push: (slotKind at: slotReg) value: (slotValue at: slotReg)! !

!OilInliningCompiler methodsFor: 'scalar replacement' stamp: 'cb 10/27/2026 14:05'!
materializeVObj: vobjIndex scratch: scratchReg
	"The scalar replaced object vobjIndex escapes: allocate it (OilNewObject, which stores its slot registers into it,
	 without nil filling it first) into an immutable high register of its own, to which every descriptor of the object is
	 then rewritten.  Always materializable in place: scalar replaced objects are flushed at every branch, merge or
	 inlined return (flushTVSlots), materialized when captured by a closure (capture:frame:), and only bound as the
	 receiver of branch-free inlined methods that do not reference self as a value (canInlineOnVObj:), which must not be
	 active (see refuseMaterializingSelfOfActiveFrame:).  Answer the register (scratchReg on failure)."
	| baseReg numSlots objReg instIndex |
	(self vobjAt: vobjIndex) materialized >= 0 ifTrue: [^(self vobjAt: vobjIndex) materialized].
	failed ifTrue: [^scratchReg].
	(self refuseMaterializingSelfOfActiveFrame: vobjIndex) ifTrue: [^scratchReg].
	baseReg := (self vobjAt: vobjIndex) slotBase.
	numSlots := (self vobjAt: vobjIndex) numSlots.
	"Nested scalar replaced objects first, then every slot in its own register."
	baseReg to: baseReg + numSlots - 1 do:
		[:slotReg|
		self materializeSlot: slotReg.
		failed ifTrue: [^scratchReg]].
	objReg := highRegTop.
	objReg <= (simStackTop + 32) ifTrue:
		[self abortCompilation: OilFailOutOfRegisters.
		 ^scratchReg].
	highRegTop := objReg - 1.
	slotFlags at: objReg put: OilFlagImmutable.
	self recordSite: OilSiteAlloc. "(the state before the allocation: the object is still virtual there)"
	instIndex := self emitOp: OilNewObject a: objReg b: baseReg c: numSlots.
	self emit64: (self vobjAt: vobjIndex) vobjClass.
	self noteDef: objReg at: instIndex.
	knownClass at: objReg put: (self vobjAt: vobjIndex) vobjClass.
	self setOwn: objReg.
	(self vobjAt: vobjIndex) materialized: objReg.
	oilNumMaterialized := oilNumMaterialized + 1.
	self rewriteVObj: vobjIndex asReg: objReg.
	^objReg! !

!OilInliningCompiler methodsFor: 'scalar replacement' stamp: 'cb 10/28/2026 04:00'!
refuseMaterializingSelfOfActiveFrame: vobjIndex
	"Is the scalar replaced object vobjIndex the self of an active inlined frame (see canInlineOnVObj:), e.g. a label in a
	 method that frame inlines materializes it?  That frame reads and writes its self's slot registers (which the
	 materialization releases) and its deoptimization record describes its self as virtual.  If so, compile again without
	 inlining that frame's method (it is then sent its receiver, materialized) and answer true."
	| activeFrame |
	activeFrame := currentFrame.
	[activeFrame >= 0] whileTrue:
		[((self frameAt: activeFrame) selfKind = OilDescObject and: [(self frameAt: activeFrame) selfValue = vobjIndex]) ifTrue:
			[oilNumNoInline >= 16
				ifTrue: [self abortCompilation: OilFailEagerClosuresFailed]
				ifFalse:
					[oilNoInline at: oilNumNoInline put: (self frameAt: activeFrame) method.
					 oilNumNoInline := oilNumNoInline + 1.
					 oilRestartNoInline := true.
					 needsRestart := true.
					 failed := true].
			 ^true].
		 activeFrame := (self frameAt: activeFrame) parent].
	^false! !

!OilInliningCompiler methodsFor: 'scalar replacement' stamp: 'cb 10/27/2026 14:05'!
canInlineOnVObj: frameIndex
	"Can the method of frameIndex be inlined with a scalar replaced object as its self?  Only if it has no jumps or
	 closures and only accesses self's instance variables (no pushSelf, no super send), so that self never escapes or
	 crosses control flow while frameIndex is active."
	| pc end tag |
	self setScanMethod: (self frameAt: frameIndex) method.
	pc := (self frameAt: frameIndex) startPC.
	end := (self frameAt: frameIndex) endPC.
	[pc <= end] whileTrue:
		[self decodeAt: pc.
		 tag := opcodeTag.
		 (tag = OilTagPushSelf
		  or: [tag = OilTagSendSuper
		  or: [tag = OilTagPushFullClosure
		  or: [tag = OilTagJump or: [tag = OilTagJumpTrue or: [tag = OilTagJumpFalse]]]]]) ifTrue: [^false].
		 pc := oilNextPC].
	^true! !

!OilInliningCompiler methodsFor: 'scalar replacement' stamp: 'cb 10/25/2026 09:30'!
rewriteVObj: vobjIndex asReg: objReg
	"The scalar replaced object vobjIndex now lives in objReg: rewrite its descriptors (in the register window, the high
	 registers, the pending results of inlined frames, and the deopt state of the current bytecode, for the deopt sites
	 recorded after the allocation)."
	0 to: simStackTop do:
		[:slotIndex|
		((slotKind at: slotIndex) = OilDescObject and: [(slotValue at: slotIndex) = vobjIndex]) ifTrue:
			[self setSlot: slotIndex kind: OilDescReg value: objReg]].
	highRegTop + 1 to: OilMaxReg do:
		[:slotIndex|
		((slotKind at: slotIndex) = OilDescObject and: [(slotValue at: slotIndex) = vobjIndex]) ifTrue:
			[self setSlot: slotIndex kind: OilDescReg value: objReg]].
	0 to: numFrames - 1 do:
		[:frameIndex|
		((self frameAt: frameIndex) hasLazy and: [(self frameAt: frameIndex) lazyKind = OilDescObject and: [(self frameAt: frameIndex) lazyValue = vobjIndex]]) ifTrue:
			[(self frameAt: frameIndex) lazyKind: OilDescReg.
			 (self frameAt: frameIndex) lazyValue: objReg]].
	0 to: snapTop do:
		[:slotIndex|
		((snapKind at: slotIndex) = OilDescObject and: [(snapValue at: slotIndex) = vobjIndex]) ifTrue:
			[snapKind at: slotIndex put: OilDescReg.
			 snapValue at: slotIndex put: objReg]].
	snapHighTop + 1 to: OilMaxReg do:
		[:slotIndex|
		((snapKind at: slotIndex) = OilDescObject and: [(snapValue at: slotIndex) = vobjIndex]) ifTrue:
			[snapKind at: slotIndex put: OilDescReg.
			 snapValue at: slotIndex put: objReg]]! !

!OilInliningCompiler methodsFor: 'scalar replacement' stamp: 'cb 10/27/2026 14:05'!
vobjIsReferenced: vobjIndex
	"Does anything still refer to the scalar replaced object vobjIndex (but its own slots)?"
	| baseReg |
	baseReg := (self vobjAt: vobjIndex) slotBase.
	0 to: simStackTop do:
		[:slotIndex|
		((slotKind at: slotIndex) = OilDescObject and: [(slotValue at: slotIndex) = vobjIndex]) ifTrue: [^true]].
	highRegTop + 1 to: OilMaxReg do:
		[:slotIndex|
		((slotIndex < baseReg or: [slotIndex >= (baseReg + (self vobjAt: vobjIndex) numSlots)])
		 and: [(slotKind at: slotIndex) = OilDescObject and: [(slotValue at: slotIndex) = vobjIndex]]) ifTrue: [^true]].
	0 to: numFrames - 1 do:
		[:frameIndex|
		((self frameAt: frameIndex) hasLazy and: [(self frameAt: frameIndex) lazyKind = OilDescObject and: [(self frameAt: frameIndex) lazyValue = vobjIndex]]) ifTrue: [^true]].
	^false! !

!OilInliningCompiler methodsFor: 'scalar replacement' stamp: 'cb 10/25/2026 09:30'!
releaseDeadVObjSlots
	"The slot registers of the scalar replaced objects that nothing refers to any more, or that were materialized, are free:
	 they need not be flushed at labels any more (the deopt states already recorded keep their descriptors)."
	| baseReg |
	0 to: numVObjs - 1 do:
		[:vobjIndex|
		baseReg := (self vobjAt: vobjIndex) slotBase.
		((self vobjAt: vobjIndex) kind = OilDescObject
		 and: [(self vobjAt: vobjIndex) numSlots > 0
		 and: [((slotFlags at: baseReg) bitAnd: OilFlagTVSlot) ~= 0
		 and: [(self vobjAt: vobjIndex) materialized >= 0 or: [(self vobjIsReferenced: vobjIndex) not]]]]) ifTrue:
			[baseReg to: baseReg + (self vobjAt: vobjIndex) numSlots - 1 do:
				[:slotReg|
				slotFlags at: slotReg put: 0.
				self setSlot: slotReg kind: OilDescConst value: nilHandle]]]! !

!OilInliningCompiler methodsFor: 'scalar replacement' stamp: 'cb 10/25/2026 09:30'!
isTemp: tempIndex deadFrom: startPC frame: frameIndex
	"Is temp tempIndex of frame frameIndex dead at startPC: on every path from startPC through the frame's bytecodes, is it
	 assigned (or the frame left) before it is read (pushed, or used as the temp vector of a remote temp)?  The interpreter
	 then never reads its value.  Conservatively false if the path worklist overflows."
	| startPC0 frameLastPC base work numWork pc tag |
	<var: #work declareC: 'sqInt work[32]'>
	self cCode: [] inSmalltalk: [work := CArrayAccessor on: (Array new: 32)].
	startPC0 := (self frameAt: frameIndex) startPC.
	frameLastPC := (self frameAt: frameIndex) endPC.
	base := (self frameAt: frameIndex) pcBase.
	base to: base + (frameLastPC - startPC0) do: [:entryIndex| oilLiveMark at: entryIndex put: 0].
	self setScanMethod: (self frameAt: frameIndex) method.
	work at: 0 put: startPC.
	numWork := 1.
	[numWork > 0] whileTrue:
		[numWork := numWork - 1.
		 pc := work at: numWork.
		 [pc >= startPC0 and: [pc <= frameLastPC and: [(oilLiveMark at: base + pc - startPC0) = 0]]] whileTrue:
			[oilLiveMark at: base + pc - startPC0 put: 1.
			 self decodeAt: pc.
			 tag := opcodeTag.
			 (tag = OilTagPushTemp and: [operand1 = tempIndex]) ifTrue: [^false].
			 ((tag = OilTagPushRemoteTemp or: [tag = OilTagStoreRemoteTemp or: [tag = OilTagPopIntoRemoteTemp]])
			  and: [operand2 = tempIndex]) ifTrue: [^false].
			 ((tag = OilTagStoreTemp or: [tag = OilTagPopIntoTemp]) and: [operand1 = tempIndex])
				ifTrue: [pc := frameLastPC + 1] "assigned: this path is done"
				ifFalse:
					[(tag between: OilTagReturnSelf and: OilTagBlockReturnTop)
						ifTrue: [pc := frameLastPC + 1]
						ifFalse:
							[tag = OilTagJump
								ifTrue: [pc := oilTargetPC]
								ifFalse:
									[(tag = OilTagJumpTrue or: [tag = OilTagJumpFalse]) ifTrue:
										[numWork >= 32 ifTrue: [^false].
										 work at: numWork put: oilTargetPC.
										 numWork := numWork + 1].
									 pc := oilNextPC]]]]].
	^true! !

!OilInliningCompiler methodsFor: 'bimorphic inlining' stamp: 'cb 10/25/2026 09:30'!
profiledClass: caseIndex at: pc
	"Type feedback for a polymorphic send at pc in the current frame's method: the receiver class of case caseIndex (0 or 1)
	 of an inline cache that saw exactly two classes (a closed PIC of two cases), else 0."
	^self
		cCode: [cogit oilPolymorphicClass: caseIndex at: pc in: (self frameAt: currentFrame) method]
		inSmalltalk:
			[typeFeedback
				ifNil: [0]
				ifNotNil: [(typeFeedback class: caseIndex + 1 of: 2 at: pc in: (self frameAt: currentFrame) method)
							ifNil: [0]
							ifNotNil: [:classObj| self handleFor: classObj]]]! !

!OilInliningCompiler methodsFor: 'bimorphic inlining' stamp: 'cb 10/27/2026 14:05'!
isBimorphicTarget: aMethod prim: prim selector: selector numArgs: numArgs receiver: rcvrSlot
	"Can aMethod be inlined in one of the two paths of a bimorphic send: a quick method, or a small method (at most
	 OilAccessorBytes bytecodes) that the inlining policy accepts?"
	aMethod = 0 ifTrue: [^false].
	(self oilIsQuickPrimitiveIndex: prim) ifTrue: [^true].
	prim ~= 0 ifTrue: [^false].
	(self oilEndPCOf: aMethod) - (self startPCOf: aMethod) + 1
		> (oilAccessorBytesValue > 0 ifTrue: [oilAccessorBytesValue] ifFalse: [OilAccessorBytes]) ifTrue: [^false].
	^self shouldInline: aMethod selector: selector numArgs: numArgs receiver: rcvrSlot! !

!OilInliningCompiler methodsFor: 'bimorphic inlining' stamp: 'cb 10/25/2026 09:30'!
genBimorphicSend: selector numArgs: numArgs receiver: rcvrSlot
	"A send whose inline cache saw exactly two receiver classes, whose methods are quick or small: inline both, behind a
	 class test (OilCmpClass) of the receiver.  If both are quick methods answering true and false (a predicate such as
	 isSymbol), the class test itself is the result (genBimorphicPredicate:...): no boolean object, no merge.  Otherwise:
		CmpClass rcvr == C1; BranchFalse Lelse; <method1 inlined>; Jump Lexit;
		Lelse: GuardClass rcvr == C2; <method2 inlined>; Lexit:
	 with the result in the receiver's register.  Answer false (nothing emitted) if the send does not qualify."
	| classObj1 classObj2 method1 method2 prim1 prim2 rcvrReg elseSite elseJump exitJump |
	classObj1 := self profiledClass: 0 at: currentPC.
	classObj2 := self profiledClass: 1 at: currentPC.
	(classObj1 = 0 or: [classObj2 = 0 or: [classObj1 = classObj2 or: [(self isContextClass: classObj1) or: [self isContextClass: classObj2]]]]) ifTrue: [^false].
	method1 := self lookup: selector inClass: classObj1.
	method2 := self lookup: selector inClass: classObj2.
	(method1 = 0 or: [method2 = 0]) ifTrue: [^false].
	prim1 := self oilPrimitiveIndexOf: method1.
	prim2 := self oilPrimitiveIndexOf: method2.
	((self isBimorphicTarget: method1 prim: prim1 selector: selector numArgs: numArgs receiver: rcvrSlot)
	 and: [self isBimorphicTarget: method2 prim: prim2 selector: selector numArgs: numArgs receiver: rcvrSlot]) ifFalse: [^false].
	((prim1 = 257 or: [prim1 = 258]) and: [(prim2 = 257 or: [prim2 = 258]) and: [prim1 ~= prim2]]) ifTrue:
		[^self genBimorphicPredicate: (prim1 = 257 ifTrue: [classObj1] ifFalse: [classObj2]) other: (prim1 = 257 ifTrue: [classObj2] ifFalse: [classObj1])
				receiver: rcvrSlot].
	(prim1 = 259 and: [self isNonNilQuickPrimitive: prim2 class: classObj2]) ifTrue:
		[^self genBimorphicSelect: classObj1 other: classObj2 prim: prim2 receiver: rcvrSlot].
	(prim2 = 259 and: [self isNonNilQuickPrimitive: prim1 class: classObj1]) ifTrue:
		[^self genBimorphicSelect: classObj2 other: classObj1 prim: prim1 receiver: rcvrSlot].
	numSites >= (OilMaxSites - 1) ifTrue: [^false].
	rcvrReg := self regForSlot: rcvrSlot.
	"Both paths start from the same canonical state, and leave the result in the receiver's own register."
	self flushFrame: currentFrame.
	rcvrReg := self regForSlot: rcvrSlot.
	failed ifTrue: [^true].
	"The deopt site of the second path's guard is recorded now, while the state of the send's bytecode is at hand; its
	 instruction is bound later (see useCondSite:)."
	elseSite := self recordSite: OilSiteGuard.
	siteIR at: elseSite put: -1.
	self emitOp: OilCmpClass a: OilCondIdentical b: rcvrReg c: 0.
	self emit64: classObj1.
	elseJump := self emitOp: OilBranchFalse a: OilFlagsReg imm16: 0.
	self genBimorphicPath: method1 prim: prim1 selector: selector numArgs: numArgs receiver: rcvrSlot class: classObj1.
	failed ifTrue: [^true].
	exitJump := self emitOp: OilJump a: 0 imm16: 0.
	self patchBranch: elseJump to: irIndex.
	self forgetKnowledgeAtLabel.
	simStackTop := rcvrSlot + numArgs.
	self resetMutableSlotsOfFrame: currentFrame.
	self materializePendingCondIfAny.
	siteIR at: elseSite put: irIndex.
	self emitOp: OilGuardClass a: rcvrReg imm16: elseSite.
	self emit64: classObj2.
	self genBimorphicPath: method2 prim: prim2 selector: selector numArgs: numArgs receiver: rcvrSlot class: classObj2.
	failed ifTrue: [^true].
	self patchBranch: exitJump to: irIndex.
	self forgetKnowledgeAtLabel.
	simStackTop := rcvrSlot.
	self resetMutableSlotsOfFrame: currentFrame.
	oilNumBimorphic := oilNumBimorphic + 1.
	^true! !

!OilInliningCompiler methodsFor: 'bimorphic inlining' stamp: 'cb 10/25/2026 09:30'!
genBimorphicPath: aMethod prim: prim selector: selector numArgs: numArgs receiver: rcvrSlot class: classObj
	"One path of a bimorphic send: the receiver is an instance of classObj; inline aMethod (or send it if it cannot be inlined
	 after all), then make the result and the frame canonical."
	knownClass at: (self regForSlot: rcvrSlot) put: classObj.
	(self oilIsQuickPrimitiveIndex: prim)
		ifTrue: [self genQuickMethod: prim receiver: rcvrSlot numArgs: numArgs]
		ifFalse:
			[(self inlineMethod: aMethod receiver: rcvrSlot numArgs: numArgs class: classObj guard: false) ifFalse:
				[self genCall: selector numArgs: numArgs receiver: rcvrSlot super: false]].
	failed ifTrue: [^self].
	simStackTop := rcvrSlot.
	self materializeSlot: rcvrSlot.
	self flushFrame: currentFrame! !

!OilInliningCompiler methodsFor: 'bimorphic inlining' stamp: 'cb 10/27/2026 12:55'!
genBimorphicPredicate: trueClass other: falseClass receiver: rcvrSlot
	"A predicate (e.g. isSymbol) answering true for the instances of trueClass and false for those of falseClass, the two
	 classes its send saw: guard that the receiver is an instance of one of them (OilGuardClass2), then answer the class
	 test as a lazy comparison (OilDescCond): the conditional jump that consumes it branches on the flags of OilCmpClass,
	 and no boolean object is materialized nor tested."
	| rcvrReg |
	numConds >= OilMaxConds ifTrue: [^false].
	rcvrReg := self emitGuard2On: rcvrSlot class: trueClass or: falseClass.
	failed ifTrue: [^true].
	self pushLazyCond: OilCondIdentical class: trueClass ra: rcvrReg rb: 0 imm: 0 useImm: false identity: true site: -1.
	oilNumPredicates := oilNumPredicates + 1.
	^true! !

!OilInliningCompiler methodsFor: 'bimorphic inlining' stamp: 'cb 10/26/2026 20:45'!
emitGuard2On: rcvrSlot class: classA or: classB
	"Pop the receiver at rcvrSlot, guarding that it is an instance of classA or classB (OilGuardClass2), and answer its
	 register (check failed after)."
	| rcvrReg site |
	rcvrReg := self regForSlot: rcvrSlot.
	site := self recordSite: OilSiteArith. "(not OilSiteGuard: no unforwarding fast path for two classes)"
	failed ifTrue: [^rcvrReg].
	self emitOp: OilGuardClass2 a: rcvrReg imm16: site.
	self emit64: classA.
	self emit64: classB.
	simStackTop := rcvrSlot - 1.
	^rcvrReg! !

!OilInliningCompiler methodsFor: 'sends' stamp: 'cb 10/27/2026 12:25'!
isStringHashMethod: aMethod
	"Is aMethod's primitive primitiveStringHash of the MiscPrimitivePlugin?"
	^self
		cCode: [coInterpreter oilApiIsStringHashMethod: aMethod]
		inSmalltalk: [(aMethod literalAt: 1) isArray and: [((aMethod literalAt: 1) at: 2 ifAbsent: [nil]) = 'primitiveStringHash']]! !

!OilInliningCompiler methodsFor: 'sends' stamp: 'cb 10/27/2026 12:25'!
genStringHash: selector receiver: rcvrSlot numArgs: numArgs class: rcvrClass guard: guard
	"String>>hashWithInitialHash: (1 arg) or ByteArray class>>hashBytes:startingWith: (2 args), primitive 152 /
	 primitiveStringHash of a byte object: computed now if both the byte object and the initial hash are constants (e.g. the
	 hash of a literal Symbol), else by OilStringHash."
	| byteSlot hashSlot byteClass rcvrReg argReg |
	byteSlot := numArgs = 1 ifTrue: [rcvrSlot] ifFalse: [rcvrSlot + 1].
	hashSlot := byteSlot + 1.
	byteClass := numArgs = 1 ifTrue: [rcvrClass] ifFalse: [self staticClassOfSlot: byteSlot].
	(numArgs = 1 or: [byteClass ~= 0]) ifTrue:
		[((self oilInstSpecOfClass: byteClass) between: 16 and: 23) ifFalse: [^false]].
	(byteClass ~= 0
	 and: [(slotKind at: byteSlot) = OilDescConst
	 and: [(slotKind at: hashSlot) = OilDescConst
	 and: [(self isSmallIntegerHandle: (slotValue at: hashSlot))
	 and: [self isImmutableObject: (slotValue at: byteSlot)]]]]) ifTrue: "(a Symbol literal: its hash cannot change)"
		[simStackTop := rcvrSlot - 1.
		 self push: OilDescConst value: (self handleForSmallInteger:
											(self stringHashOf: (slotValue at: byteSlot)
												initialHash: (self smallIntegerValueOf: (slotValue at: hashSlot)))).
		 ^true].
	(numArgs = 1 and: [(self isEncodableCall: selector super: false) not]) ifTrue: [^false].
	guard ifTrue: [self emitGuardOn: (self regForSlot: rcvrSlot) class: rcvrClass].
	rcvrReg := self regForSlot: byteSlot.
	argReg := self regForSlot: hashSlot.
	simStackTop := rcvrSlot - 1.
	self pushResultOf: OilStringHash b: rcvrReg c: argReg site: (numArgs = 2 ifTrue: [OilSiteArith] ifFalse: [0]).
	self emit64: (numArgs = 2 ifTrue: [byteClass ~= 0 ifTrue: [1] ifFalse: [0]] ifFalse: [selector]).
	^true! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/27/2026 11:50'!
stringHashOf: aHandle initialHash: initialHash
	"primitiveStringHash of the byte object aHandle (a constant)."
	^self
		cCode: [coInterpreter oilApiStringHashOf: aHandle initialHash: initialHash]
		inSmalltalk: [ByteArray hashBytes: (self objectFor: aHandle) startingWith: initialHash]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/27/2026 20:25'!
isByteConstant: aHandle
	"Is the constant handle aHandle a byte object (format 16..23, e.g. a ByteString, Symbol or ByteArray)?"
	(aHandle = 0 or: [(aHandle bitAnd: 7) ~= 0]) ifTrue: [^false].
	^((self oilInstSpecOfClass: (self classOopOf: aHandle)) between: 16 and: 23)! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/27/2026 20:25'!
numBytesOfConstant: aHandle
	^self cCode: [objectMemory numBytesOf: aHandle] inSmalltalk: [(self objectFor: aHandle) basicSize]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/27/2026 20:25'!
byteAt: byteIndex ofConstant: aHandle
	^self cCode: [objectMemory fetchByte: byteIndex ofObject: aHandle] inSmalltalk: [(self objectFor: aHandle) basicAt: byteIndex + 1]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/27/2026 20:25'!
word64AtByte: baseByte count: count ofConstant: aHandle
	"Pack count bytes (1..8) from 0-based byte offset baseByte of the byte constant aHandle into a little-endian 64-bit word."
	| word |
	<var: #word type: #usqInt>
	word := 0.
	count - 1 to: 0 by: -1 do:
		[:offset|
		word := (word bitShift: 8) + (self byteAt: baseByte + offset ofConstant: aHandle)].
	^self cCode: [word] inSmalltalk: [word >= (1 bitShift: 63) ifTrue: [word - (1 bitShift: 64)] ifFalse: [word]]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/27/2026 21:30'!
associationValueOf: aHandle
	^self cCode: [coInterpreter oilApiAssociationValueOf: aHandle]
		inSmalltalk:
			[| obj |
			obj := self objectFor: aHandle.
			(obj isVariableBinding and: [obj value ~~ nil]) ifTrue: [self handleFor: obj value] ifFalse: [0]]! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/27/2026 21:30'!
isBijectiveByteTable: aHandle
	"Is aHandle a 256-byte constant whose 256 bytes are a permutation of 0..255 (e.g., CaseSensitiveOrder or AsciiOrder)?"
	| seen b |
	<var: #seen declareC: 'unsigned char seen[256]'>
	(aHandle ~= 0 and: [(self isByteConstant: aHandle) and: [(self numBytesOfConstant: aHandle) >= 256]]) ifFalse: [^false].
	self cCode: [] inSmalltalk: [seen := ByteArray new: 256].
	0 to: 255 do: [:idx| self cCode: [seen at: idx put: 0] inSmalltalk: [seen at: idx + 1 put: 0]].
	0 to: 255 do:
		[:idx|
		b := self byteAt: idx ofConstant: aHandle.
		(self cCode: [seen at: b] inSmalltalk: [seen at: b + 1]) ~= 0 ifTrue: [^false].
		self cCode: [seen at: b put: 1] inSmalltalk: [seen at: b + 1 put: 1]].
	^true! !

!OilInliningCompiler methodsFor: 'returns' stamp: 'cb 10/25/2026 09:30'!
isFrame: frameIndex deadFrom: pc
	"After a return: is the rest of frame frameIndex's bytecodes, from pc, unreachable (no pending forward branch targets
	 it)?  Then the return is the frame's last (e.g. ^(x + aPoint x) @ (y + aPoint y) in Point>>+ when the test before it
	 was folded), and its result can stay a descriptor (see genReturnKind:value:nonLocal:frame:next:)."
	| frameLastPC |
	frameLastPC := (self frameAt: frameIndex) endPC.
	pc to: frameLastPC do:
		[:laterPC| (pcChain at: (self pcMapIndex: laterPC frame: frameIndex)) ~= OilNoLink ifTrue: [^false]].
	^true! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/25/2026 09:30'!
classIndexOfClass: classOop
	"The class index of a class (its identity hash, primitive 175), or 0 if it has none yet."
	^self cCode: [coInterpreter oilApiClassIndexOfClass: classOop] inSmalltalk: [(self objectFor: classOop) identityHash]! !

!OilInliningCompiler methodsFor: 'bimorphic inlining' stamp: 'cb 10/25/2026 09:30'!
isNonNilQuickPrimitive: prim class: classObj
	"Does the quick method prim (sent to an instance of classObj) answer a value known not to be nil: self (unless classObj is
	 UndefinedObject), true, false or a SmallInteger?"
	prim = 256 ifTrue: [^classObj ~= (self classOopOf: nilHandle)].
	^prim = 257 or: [prim = 258 or: [prim between: 260 and: 263]]! !

!OilInliningCompiler methodsFor: 'bimorphic inlining' stamp: 'cb 10/27/2026 12:55'!
genBimorphicSelect: nilClass other: otherClass prim: prim receiver: rcvrSlot
	"A send whose two receiver classes answer nil (nilClass) and a known non-nil value (otherClass, quick method prim): guard
	 that the receiver is an instance of one of them (OilGuardClass2) and select nil or the other value via OilCmpClass and a
	 diamond, which Pass 2 folds into the class test itself when compared with nil (see OilLoopOptimizer>>foldSelectDiamonds)."
	| rcvrReg destReg |
	rcvrReg := self emitGuard2On: rcvrSlot class: nilClass or: otherClass.
	failed ifTrue: [^true].
	destReg := self pushOwnSlot.
	self emitOp: OilCmpClass a: OilCondIdentical b: rcvrReg c: 0.
	self emit64: nilClass.
	self emitDiamondInto: destReg trueKind: OilDescConst value: nilHandle
		falseKind: (prim = 256 ifTrue: [OilDescReg] ifFalse: [OilDescConst])
		value: (prim = 256 ifTrue: [rcvrReg] ifFalse: [self quickPrimitiveConstant: prim]).
	oilNumSelects := oilNumSelects + 1.
	^true! !

!OilInliningCompiler methodsFor: 'inlining' stamp: 'cb 10/25/2026 09:30'!
hasVirtualObjectFrom: firstSlot to: lastSlot
	"Does a slot from firstSlot to lastSlot hold a virtual closure, temp vector or object (which a call would materialize)?"
	| descKind |
	firstSlot to: lastSlot do:
		[:slotIndex|
		descKind := slotKind at: slotIndex.
		(descKind = OilDescBlock or: [descKind = OilDescTempVector or: [descKind = OilDescObject]]) ifTrue: [^true]].
	^false! !

!OilInliningCompiler methodsFor: 'inlining' stamp: 'cb 10/25/2026 09:30'!
inlineSendToVirtualBlock: selector numArgs: numArgs receiver: rcvrSlot
	"A send other than value... to a virtual closure (e.g. aBlock timeToRun): inline the method of FullBlockClosure if it is
	 not a primitive, the closure staying virtual as its self (and as an argument of what it sends, e.g. Time
	 millisecondsToRun: self, down to the inlined evaluation of the block).  Answer whether the send was inlined."
	| classObj method |
	classObj := self fullBlockClosureClassHandle.
	method := self lookup: selector inClass: classObj.
	(method = 0 or: [(self oilPrimitiveIndexOf: method) ~= 0]) ifTrue: [^false].
	(self shouldInline: method selector: selector numArgs: numArgs receiver: rcvrSlot) ifFalse: [^false].
	^self inlineMethod: method receiver: rcvrSlot numArgs: numArgs class: classObj guard: false! !

!OilInliningCompiler methodsFor: 'inlining' stamp: 'cb 10/25/2026 09:30'!
fullBlockClosureClassHandle
	^self cCode: [coInterpreter oilApiClassAtIndex: ClassFullBlockClosureCompactIndex] inSmalltalk: [self handleFor: FullBlockClosure]! !

!OilInliningCompiler methodsFor: 'inlining' stamp: 'cb 10/25/2026 09:30'!
policyDepthOf: frameIndex
	"The inlining depth of a send in frameIndex for the inlining policy: the depth below the closest inlined block whose home
	 is the root frame (a block of the root method's own code), or below the root."
	| walkFrame |
	walkFrame := frameIndex.
	[walkFrame > 0] whileTrue:
		[((self frameAt: walkFrame) isBlockFrame and: [(self frameAt: walkFrame) home = 0]) ifTrue:
			[^(self frameAt: frameIndex) depth - (self frameAt: walkFrame) depth + 1].
		 walkFrame := (self frameAt: walkFrame) parent].
	^(self frameAt: frameIndex) depth + 1! !

!OilInliningCompiler methodsFor: 'scalar replacement' stamp: 'cb 10/25/2026 09:30'!
initVObjSlot: slotReg from: srcSlot
	"Initialize the slot register slotReg of a new scalar replaced object with the value of the stack slot srcSlot."
	| descKind |
	(self isLazyKind: (slotKind at: srcSlot)) ifTrue:
		[self materializeSlot: srcSlot].
	descKind := slotKind at: srcSlot.
	(descKind = OilDescConst or: [descKind = OilDescObject]) ifTrue:
		[^self setSlot: slotReg kind: descKind value: (slotValue at: srcSlot)].
	descKind = OilDescReg ifFalse: [^self requireEagerClosures].
	self emitMove: slotReg from: (slotValue at: srcSlot).
	self setOwn: slotReg! !

!OilInliningCompiler methodsFor: 'object access' stamp: 'cb 10/25/2026 09:30'!
isImmutableObject: aHandle
	"Is the non-immediate constant aHandle read-only (e.g. a Symbol)?"
	^self cCode: [coInterpreter oilApiIsImmutable: aHandle] inSmalltalk: [(self objectFor: aHandle) isReadOnlyObject]! !
