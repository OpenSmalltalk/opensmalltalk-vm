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

## Running the In-Image Tests

```bash
# Run on a copy of image/Spur64VMMaker.image:
run-st.sh --answer true Spur64VMMaker.image image/oil/oil-scanner-test.st
run-st.sh --answer true Spur64VMMaker.image image/oil/oil-m2-test.st
run-st.sh --answer true Spur64VMMaker.image image/oil/oil-m4-test.st
run-st.sh --answer true Spur64VMMaker.image image/oil/oil-m6-test.st
```

The scripts look for sources in `Smalltalk at: #OilSourceDir` (defaulting to the current working directory).

## Pass 1 (`OilBaseCompiler>>compileMethod:receiverClass:`)

- **IR format**: `oilIRBuffer` holds up to `OilBufferWords` (4096) 32-bit words (`unsigned int oilIRBuffer[4096]`, 16 KB, static). Each instruction is `[Opcode:8 | Dest:8 | Src1:8 | Src2/Imm:8]`, optionally followed by a 64-bit operand (2 words, low word first) and packed argument words (`OilCallN`, `OilCallSuper`).
- **Control flow & flags**: Branch targets are absolute IR word indices. Forward branches are chained through their 16-bit target field until the label is bound. `OilCmpTagged` / `OilCmpImmTagged` store the condition code in `Dest`; `OilBranchTrue` / `OilBranchFalse` on `OilFlagsReg` (r255) branch on the flags from the preceding compare, and on any other register test a boolean (`mustBeBoolean` deopt).
- **Virtual registers & descriptors**: 256 virtual registers act as a register window (`r0` receiver, `r1..rN` arguments, temporaries, expression stack; scalar-replaced temp vectors allocate downwards from `r254`). Each slot has a descriptor (`slotKind`/`slotValue`): canonical register, register alias, constant, virtual closure, or virtual temp vector. If a closure escapes, compilation restarts in `eagerClosures` mode (`OilMakeClosure`, `OilNewArray`).
- **Deopt sites**: Instructions that can bail out (class guards, bounds checks, tagged arithmetic, calls, boolean branches, allocations) record a deopt site (IR index, inlined frame, bytecode pc, snapshot of live virtual state) for `CoInterpreter>>ceOilBailout:`.

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
