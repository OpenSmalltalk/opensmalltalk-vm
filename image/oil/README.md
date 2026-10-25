# Oil Optimizing Compiler

Slang/Smalltalk sources for Oil, the optimizing JIT for the 64-bit Spur Cog VM. Author: cb.

## Compiler Hierarchy

```
OilBytecodeScanner
  └── OilBaseCompiler        (Pass 1: bytecode translation + inlining; Pass 3: native codegen)
        └── OilLoopCompiler  (Pass 2: streaming loop optimizer)
              └── OilFullCompiler  (dominator-scoped value numbering, float fusion)
```

| File | Contents |
|---|---|
| `OilInstructionConstants.st` | Shared pool: IR opcodes for the 32-bit compact linear IR (`OilConstTagged`..`OilLastOpcode`). |
| `OilConstants.st` | Shared pool: condition codes, scanner tags/modes, descriptor kinds, limits, deopt site kinds, failure codes (imports `OilInstructionConstants`). |
| `OilBytecodeScanner.st` | `OilBytecodeDescriptor` (6-byte struct) and `OilBytecodeScanner`: a 256-entry SistaV1 `oilGeneratorTable` and a zero-allocation decoder (`decodeAt:`, `scanMethod:do:`) that folds `extA`/`extB` prefixes. Oil only compiles SistaV1 methods (`OilFailNotSistaV1` leaves others to the baseline Cogit). |
| `OilCompiler.st` | `OilBaseCompiler` (Pass 1): static 4096 x 32-bit IR buffer, register-window virtual registers with descriptors, structural inlining, tagged SmallInteger peepholes, deopt sites, frame table, and the `#pipe` optimization hook. |
| `OilCompilerPass2.st` | `OilLoopCompiler` (Pass 2): `loopOptimize` streams Buffer 1 (`oilIRBuffer1`) into Buffer 2 (`oilIRBuffer2`). `OilFullCompiler`: `valueNumber` (run by Pass 2) and `fuseFloats` (on Pass 2's IR). |
| `OilCompilerBackend.st` | `OilBaseCompiler` (Pass 3): register allocation, `generateNativeCode` (IR to Cogit abstract instructions), bailout stubs, tagged-register analysis. |
| `OilSimulation.st` | IR printer (`printIROn:`), `OilSimulatedTypeFeedback` (receiver classes recorded per send site by simulated execution), `OilIRInterpreter` (executes the IR on host objects), test classes. |
| `oil-scanner-test.st` | Checks the scanner against the image's `InstructionStream` on all SistaV1 methods and blocks. |
| `oil-m2-test.st` | Pass 1 acceptance test: compiles probes (`sumScores:` and others), checks the IR shape, and compares `OilIRInterpreter` against real execution. |
| `oil-m4-test.st` | Pass 2 acceptance test: checks loop rotation, bounds-check elimination, shared sizes, unchecked increments, dead code elimination, and equivalence with Pass 1 and real execution. |
| `oil-m6-test.st` | `OilFullCompiler` acceptance test: value numbering and float fusion statistics, and equivalence of the IR (the interpreter keeps unboxed float results aside, like XMM registers) with real execution. |
| `oil-m8-test.st` | M8 acceptance test: scalar replacement (dissolved and materialized Points and Associations), bimorphic inlining (diamonds, predicates, nil-or-object sends), folded hashes and `OilStringHash`, and equivalence of the IR with real execution. |

## Running the In-Image Tests

```bash
# Run on a copy of image/Spur64VMMaker.image:
run-st.sh --answer true Spur64VMMaker.image image/oil/oil-scanner-test.st
run-st.sh --answer true Spur64VMMaker.image image/oil/oil-m2-test.st
run-st.sh --answer true Spur64VMMaker.image image/oil/oil-m4-test.st
run-st.sh --answer true Spur64VMMaker.image image/oil/oil-m6-test.st
run-st.sh --answer true Spur64VMMaker.image image/oil/oil-m8-test.st
```

The scripts look for sources in `Smalltalk at: #OilSourceDir` (defaulting to the current working directory).

## Pass 1 (`OilBaseCompiler>>compileMethod:receiverClass:`)

- **IR format**: `oilIRBuffer` holds up to `OilBufferWords` (4096) 32-bit words (`unsigned int oilIRBuffer[4096]`, 16 KB, static). Each instruction is `[Opcode:8 | Dest:8 | Src1:8 | Src2/Imm:8]`, optionally followed by a 64-bit operand (2 words, low word first) and packed argument words (`OilCallN`, `OilCallSuper`).
- **Control flow & flags**: Branch targets are absolute IR word indices. Forward branches are chained through their 16-bit target field until the label is bound. `OilCmpTagged` / `OilCmpImmTagged` store the condition code in `Dest`; `OilBranchTrue` / `OilBranchFalse` on `OilFlagsReg` (r255) branch on the flags from the preceding compare, and on any other register test a boolean (`mustBeBoolean` deopt).
- **Virtual registers & descriptors**: 256 virtual registers act as a register window (`r0` receiver, `r1..rN` arguments, temporaries, expression stack; scalar-replaced temp vectors allocate downwards from `r254`). Each slot has a descriptor (`slotKind`/`slotValue`): canonical register, register alias, constant, virtual closure, or virtual temp vector. If a closure escapes, compilation restarts in `eagerClosures` mode (`OilMakeClosure`, `OilNewArray`).
- **Deopt sites**: Instructions that can bail out (class guards, bounds checks, tagged arithmetic, calls, boolean branches, allocations) record a deopt site (IR index, inlined frame, bytecode pc, snapshot of live virtual state) for `CoInterpreter>>ceOilBailout:`.

## Scalar replacement, bimorphic inlining (Pass 1, M8)

- **Scalar replacement of objects** (`OilDescObject`, category 'scalar replacement'): `basicNew` (primitive 70) of a constant class with fixed pointer fields only (format 0 or 1, at most `OilMaxVObjSlots` slots) and `Number>>@` (primitive 18) answer a virtual object whose slots are high registers, flushed at labels like the slots of a scalar replaced temp vector. Inlined methods of the object read and write its slots (`genPushRcvrVar:frame:`, `genStoreRcvrVar:pop:frame:`, quick accessors), `==` with it folds, `#class` folds. Class bindings fold to their class in the VM too (`isClassBinding:`), so `Point x: a y: b` and `Object>>->` are dissolved.
- **Materialization** (`materializeVObj:scratch:`): an object that escapes (a send argument or receiver not inlined, a store into the heap, a return from the compiled method, a merge with the object in a live temp) is allocated by `OilNewObject [Op|Dest|FirstSlot|NumSlots]` + class from its slot registers (no nil filling), into an immutable high register to which all its descriptors (and the deopt state of the current bytecode) are rewritten. That is done where it escapes if no branch or label was emitted since its creation (`canMaterializeInPlace:depth:`, the flow epoch); otherwise compilation restarts with its allocation site allocating eagerly (`requestEagerSite:`, `OilMaxEagerSites`). A dead temp holding a virtual object is not materialized at a merge (`isTemp:deadFrom:frame:`, bytecode liveness), and a return whose following bytecodes are unreachable keeps its result virtual (`isFrame:deadFrom:`). Deoptimization rematerializes virtual objects (metadata record kind `OilDescObject`, class in the self descriptor).
- **Bimorphic inlining** (`genBimorphicSend:numArgs:receiver:`): a send whose inline cache is a closed PIC of two cases (`ProfilingCogit>>oilPolymorphicClass:at:in:`; `OilSimulatedTypeFeedback>>class:of:at:in:` in the image), both methods quick or at most `OilAccessorBytes` bytecodes: `OilCmpClass rcvr == C1; BranchFalse; M1 inlined; Jump; GuardClass rcvr == C2; M2 inlined`. A predicate (one class `^true`, the other `^false`) is `OilGuardClass2` then the class test as a lazy comparison (`OilDescCond` with `condClass`), consumed by the following conditional jump: no boolean object. A nil-or-object send (one class `^nil`, the other `^self` or a constant) is a lazy class dependent value (`OilDescSelect`) whose comparison with nil (`ifNil:ifNotNil:`, `== nil`) is the class test (`genSelectIsNil:cond:slot:frame:next:`); elsewhere it is materialized (`emitSelect:into:`).
- **Hashed collection probes**: `Behavior>>identityHash` (primitive 175) and `identityHash` (primitive 75) of constants fold, `String>>hashWithInitialHash:` (primitiveStringHash) of a byte object is `OilStringHash` (or a constant for a literal), so `String>>hash`, hence `Set`/`Dictionary` `scanFor:` with Symbol or String keys, send nothing on their hot path; `Symbol>>=`'s `isSymbol` is a bimorphic predicate. `OrderedCollection>>addLast:` inlines its fast path; `makeRoomAtLast` / `makeRoomAtFirst` are cold selectors (kind 7).
- **Statistics** (`pass2Statistics:` 11 to 17): scalar replaced objects, materialized, bimorphic sends, predicates, eager sites, allocations sharing a threshold check, nil-or-object sends.

## Pass 2 (`OilLoopCompiler>>loopOptimize`)

Invoked via `#pipe` between Pass 1 and Pass 3, streaming `oilIRBuffer1` into `oilIRBuffer2`:

1. **Analysis**: definition counts, branch targets, and `analyzeTaggedRegisters` (registers guaranteed to hold SmallIntegers).
2. **Loop optimization** (`p2OptimizeLoop:backJump:` on innermost call-free loops entered by fall-through):
   - **Invariant checks**: class guards inside the loop redundant with a pre-header guard on the same immutable register are removed.
   - **Loop rotation**: a header compare on SmallIntegers is duplicated before the back jump as `CmpTagged; BranchTrue body`.
   - **Counted loops**: for an induction variable initialized from a constant `>= 1`, incremented by 1, and compared `<=` or `<` against `size(x)` loaded before the loop, increments become `OilAddImmTaggedNC` (unchecked), `size(x)` inside the loop is shared with the pre-header load, and dominated `OilCheckBounds` instructions are eliminated.
3. **Dead code elimination**: pure instructions whose destination register has no reads (neither by instructions nor by live deopt snapshots, or overwritten before use in straight-line code) are deleted.
4. **Streaming emission**: computes `oilIRMap`, emits into `oilIRBuffer2`, and remaps `siteIR`.

## OilFullCompiler

- **Float arithmetic** (Pass 1, `genFloatSend:frame:next:`): `+ - * /` and the comparisons on a Float receiver (constant, result of Float arithmetic, known or profiled `SmallFloat64`/`BoxedFloat64`) become `OilAddFloat`..`OilDivFloat` `[Op|Dest|Rcvr|Arg]` and `OilCmpFloat` `[Op|Cond|Rcvr|Arg]` (fused with the following branch on the flags). The receiver must be a Float and the argument a Float or a SmallInteger (converted; exactly, |n| < 2^53, for comparisons), and a divisor non-zero, else the instruction deoptimizes. For `+ *` and the comparisons a SmallInteger receiver with a Float argument is swapped. Results are boxed: a `SmallFloat64` if in range, else a `BoxedFloat64` allocated in eden.
- **Dominator-scoped value numbering** (`valueNumber`, run by Pass 2 before dead code elimination): walking the IR in order, it remembers loaded fields, sizes, bounds checks and class checks. A label forgets the facts established after the earliest branch to it (a loop header forgets all), assigning a register forgets the facts about it, stores forget the fields they may alias (calls and allocations forget everything) and are forwarded to later loads. A load already done becomes an `OilMove` (`OilP2ToMove`), a check already done is deleted (`OilP2Delete`). No SSA, no phis.
- **Float fusion** (`fuseFloats`, on Pass 2's IR): a float chain is a straight-line run of float instructions (and their constants) whose results, but the last, are only read inside the chain. They stay unboxed in XMM registers (`OilFloatUnboxed`), the inputs are checked and decoded once per chain, and every deopt of the chain goes to the site of its first instruction (`OilFloatChained`, `oilIRAux`): the chain has no side effect and assigns no register its state refers to before its last instruction, so the interpreter redoes it. Chains never span a safepoint (call or allocation but the last result's), so they need no GC maps.

## Pass 3 (`OilBaseCompiler>>prepareNativeCode`, `generateNativeCode`)

- **Register allocation**: weighs virtual registers by use count (10x per loop nesting level), assigns the heaviest up to 9 machine registers, and gives every live virtual register a frame home slot below the method's temporaries.
- **Native codegen**: translates IR instructions to Cogit abstract instructions, including in-place tagged accumulation with undo stubs (`oilUndoJump`), eden bump allocation (`OilMakeClosure`, `OilNewArray`), byte/character/stream intrinsics (`OilLoadByte*`, `OilStoreByte*`, `OilCompareBytes`, `OilStreamNext`, `OilStreamNextPut`), uncommon traps (`OilTrap`), and bailout stubs (`ceOilBailoutTrampoline`).
- **Allocations** (`genAllocate:header:site:combineAfter:`): eden bump sharing: an `OilNewObject`/`OilNewArray` followed in straight-line code, with only constants and moves in between, by other allocations reserves their bytes too (one scavenge threshold check, one `freeStart` bump; `oilPendingAllocBytes`); the followers take their memory just below `freeStart`. Beyond the threshold the first one deoptimizes (`OilSiteAlloc`, not counted), and the interpreter redoes them all. `OilNewObject` writes its slots from registers, without nil filling and without store checks (the object is young).
- **Class tests** (`genClassTagOf:into:`): `OilCmpClass` (fused with its branch) and `OilGuardClass2` compare the class tag (tag bits of an immediate, else the class index in the header).
- **`OilStringHash`** (`genStringHashAt:`): `h := (h + byte) * 16r19660D` per byte, `h bitAnd: 16r0FFFFFFF` (the low 28 bits of 64-bit arithmetic are those of the primitive's 32-bit arithmetic); a non-SmallInteger initial hash sends the message.
- **`OilModTagged`** (`genModTagged:b:c:site:`): operands in [0, 2^31) are divided as doubles (about 14 cycles instead of 40 to 90 for a 64-bit `idiv`): the rounded quotient is exact or one too many, so the remainder is `x - (q * y)`, plus `y` if negative.
- **`identityHash`** (primitive 75, `OilIdentityHash`): the hash field of the receiver's header as a SmallInteger (three instructions), so `IdentitySet`/`IdentityDictionary` probes (`scanFor:`, `scaledIdentityHash`) send nothing; an object without a hash yet gets one from the send.
- **Word-at-a-time byte scans** (`OilIndexOfByte`, `OilSkipSeparators`), for the methods and the stream class the image registers (kinds 9 to 11 of `primitiveOilSetSelectors`): `ByteString class>>indexOfAscii:inString:startingAt:` (the search of `ReadStream>>upTo:` and `String>>indexOf:`) tests 8 bytes per iteration (`w := word bitXor: c * 16r0101010101010101`; a match iff `(w - 16r0101010101010101) bitAnd: (w bitInvert bitAnd: 16r8080808080808080)` is not 0, exact for the word, then bytewise), and `PositionableStream>>skipSeparators` of a `ReadStream` on a `ByteString` skips 8 spaces or 8 tabs per iteration, else tests each byte against `Character>>isSeparator`'s codes (32, 13, 9, 10, 12 and 1: a byte test `< 16r21` would be wrong for 0, 11 and the other control characters). Unexpected operands fall back to the send.
