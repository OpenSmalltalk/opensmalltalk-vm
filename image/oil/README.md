# Oil: Pass 1 (M2), Pass 2 (M4) and Pass 3 (M3) of the optimizing compiler

Clean-room Slang/Smalltalk sources for Pass 1 of Oil, the optimizing JIT for the 64-bit Spur Cog VM
(design: `oil-jit-design.md`). Author: cb.

| File | Contents |
|---|---|
| `OilConstants.st` | Shared pool: IR opcodes, condition codes, scanner tags/modes, descriptor kinds, limits, deopt site kinds, failure codes (generated from one spec). |
| `OilBytecodeScanner.st` | `OilBytecodeDescriptor` (8-byte struct) and `OilBytecodeScanner`: a 256-entry SistaV1 `oilGeneratorTable` and a zero-allocation decoder (`decodeAt:`, `scanMethod:do:`) that folds extA/extB prefixes. Oil only compiles SistaV1 methods (others: `OilFailNotSistaV1`, left to the Cogit). |
| `OilCompiler.st` | `OilCompiler` (Pass 1): static 4096 x 32-bit IR buffer, register-window virtual registers with descriptors, structural inlining, tagged SmallInteger peepholes, deopt sites, frame table. |
| `OilCompilerBackend.st` | Pass 3 (M3): register allocation, `generateNativeCode` (IR to Cogit abstract instructions), bailout stubs, tagged-register analysis. |
| `OilCompilerPass2.st` | Pass 2 (M4): `pass2Optimize`, streaming Buffer 1 into Buffer 2 (see below). |
| `OilSimulation.st` | IR printer (`printIROn:`), `OilSimulatedTypeFeedback` (receiver classes recorded per send site by simulated execution, standing in for ProfilingCogit's PICs), `OilIRInterpreter` (runs the IR on host objects to validate it), test classes. |
| `oil-scanner-test.st` | Checks the scanner against the image's `InstructionStream` on 9220 SistaV1 methods and blocks. |
| `oil-m2-test.st` | Acceptance test: compiles the probes (`sumScores:` and others), dumps the IR, checks its shape, and compares the IR interpreter's result with the real execution. |
| `oil-m4-test.st` | Pass 2 acceptance test: IR shape of the optimized loops, and Pass 2 IR = Pass 1 IR = real execution on every probe (deopts included), plus a robustness sweep. |
| `oil-translate.st` | Translates `OilBytecodeScanner` and `OilCompiler` to C with VMMaker's `CCodeGenerator` (standalone, not yet wired into the Cogit). |

## Running

```bash
SK=~/.gemini/config/skills/opensmalltalk-slang/scripts
# Use a copy of image/Spur64VMMaker.image: filing in appends to its .changes file.
nice -n 10 $SK/run-st.sh --answer true <copy>/Spur64VMMaker.image oil-scanner-test.st   # -> scanner-test-result.txt
nice -n 10 $SK/run-st.sh --answer true <copy>/Spur64VMMaker.image oil-m2-test.st        # -> m2-test-result.txt (IR dumps + PASS/FAIL)
nice -n 10 $SK/run-st.sh --answer true <copy>/Spur64VMMaker.image oil-m4-test.st        # -> m4-test-result.txt
nice -n 10 $SK/run-st.sh --answer true <copy>/Spur64VMMaker.image oil-translate.st      # -> oil-pass1.c
```

The scripts look for the sources in `Smalltalk at: #OilSourceDir`. The default is this directory in the M2 worktree, so edit the
first chunk to run them from somewhere else.

## IR format notes and differences from the brief

- The buffer holds 32-bit words: `unsigned int oilIRBuffer[4096]`, 16 KB, static. The brief's `sqInt` would be 64-bit.
  A 64-bit operand (literal, selector, class tag) takes the 2 words after the instruction, low word first.
- Branch targets are absolute IR word indices. Forward branches are chained through their 16-bit target field until the
  label is bound, so no fixup table is needed.
- The `OilCmpTagged` Dest field holds the condition code (`< > <= >= = ~= == ~~`). `OilBranchTrue/False` on register r255
  branch on the flags set by the previous compare. On any other register they test a boolean (mustBeBoolean deopt).
- The 16-bit `DeoptBC` field of `OilGuardClass` (and the 8-bit one of `OilCheckBounds`) is an index into the deopt site
  table. Each entry holds the IR index, the inlined frame and the bytecode pc. A bytecode pc alone would be ambiguous
  across inlined frames. Tagged arithmetic, calls and boolean branches also get sites, looked up by IR index.
- Six opcodes were added to the core set: `OilAddImmTagged` (25), `OilCmpImmTagged` (26), `OilLoadSize` (27),
  `OilMakeClosure` (28) and `OilNewArray` (29), used for escaping closures in eager mode and for brace arrays, and
  `OilCallSuper` (30). `OilShiftTagged` with a negative immediate is a left shift, used for `* 2^k`, `x * 31`, `x * 9`
  and `bitShift:`.
- Tagged arithmetic and compare opcodes include the SmallInteger tag check and the overflow check. On failure they bail
  out at their deopt site. Constants never need a check.
- `OilCallN` and `OilCallSuper` put four 8-bit argument registers in each packed word.

## Integration points for M1 and M3

- Type feedback: `OilCompiler>>profiledClassAt:` calls `cogit oilMonomorphicClassAt: pc in: method` in C. This should be
  a thin adapter over M1's `monomorphicTargetFor:in:` that answers the class tag of a monomorphic site, or 0.
- Selectors: `registerSelector:kind:` (`<api>`) tells Oil the value, bitXor:, iterator and cold selectors at startup.
- Entry point: `compileMethod:receiverClass:` (`<api>`). The IR, the deopt site table and the frame table are then
  ready for M3's back end.

## Pass 2 (Milestone 4): `OilCompiler>>pass2Optimize`

Pass 1 writes `oilIRBuffer1`; Pass 2 streams it into `oilIRBuffer2` (both static, 16 KB) and makes it the current IR
(`oilIRBuffer` points to the current buffer); Pass 3 translates it. `ProfilingCogit>>oilGenerate:` runs Pass 2 then Pass 3.

1. Analysis: definition counts, branch targets, `analyzeTaggedRegisters` (registers that always hold SmallIntegers).
2. Innermost, call-free loops entered only by falling into their header (`p2OptimizeLoop:backJump:`):
   - Rotation: a header test that cannot fail (`CmpTagged` on SmallIntegers) is copied to the bottom as
     `CmpTagged; BranchTrue body`, replacing the back `Jump`.
   - Counted loops: index `iv` from a constant >= 1, only incremented, tested `iv <= lim` / `iv < lim` with
     `lim := size(x)` assigned once before the loop and `x` never assigned. The increments become `OilAddImmTaggedNC`
     (no tag/overflow check), `size(x)` in the loop becomes `Move lim` (shared size), and the `CheckBounds iv`
     right after the test are deleted.
3. Dead code: pure instructions whose destination nothing reads, globally or before it is reassigned in the
   straight-line code that follows. Reads include the deopt states of the live sites.
4. Emission: layout pass (`oilIRMap`), then emit, then remap `siteIR` (sites of deleted or unchecked instructions die).

Pass 3 additions: `OilAddImmTaggedNC` (in place `addq $8`), in-place accumulation `a := a + c`
(`lea -1(c), t; add t, a; jo undo`, the undo stub subtracting `t` before bailing out), and array loads with the
x64 instruction `movq -1(arr, taggedIndex, 1)`, a new x64-specific opcode `MoveTaggedXwrRR`
(`oil/oil-m4-pass2.st`, which patches `CogX64Compiler`; other back ends untag and scale).

`sumScores:` on an Array, inner loop (16 instructions, every one needed for soundness: element class guard, score
tag check, overflow check):

```
L: movq  -0x1(%r10,%r12,1),%r13    ; element (tagged index, -1 displacement)
   testb $0x7,%r13b ; jne guard     ; element is an object...
   movl  (%r13),%r9d ; andq $0x3fffff,%r9 ; cmpq $0x1433,%r9 ; jne guard   ; ...of class OilTestItem
   movq  0x8(%r13),%r15             ; score
   testb $0x1,%r15b ; je arith      ; score is a SmallInteger
   leaq  -0x1(%r15),%r9 ; addq %r9,%r14 ; jo undo   ; total := total + score
   addq  $0x8,%r12                  ; index + 1, no check
   cmpq  %r11,%r12 ; jle L
```

Not done yet: hoisting loop invariant field loads (the OrderedCollection>>do: loop reloads its array/lastIndex
fields and keeps its bounds check), loop unrolling, and register allocation by live ranges (Pass 3 still gives
the heaviest virtual registers machine registers for the whole method).

## Milestone 5 (base completion)

- **Deopt disqualification**: an Oil method that deoptimizes `OilDisqualifyDeopts` (2) times is freed (sends to it
  unlinked, `CoInterpreter>>oilDisqualifyCogMethod:`) unless other activations still run it, so the baseline JIT
  compiles its method again, and it is not Oil-compiled again (`OilFailDisqualified`, 16). The limit can be set with
  the selector registration pair `8, <SmallInteger>` (test_oil_m3 uses 1000).
- **Escaping closures and brace arrays** (`OilMakeClosure`, `OilNewArray`): eden bump allocation in machine code
  (`genAllocate:header:site:`). Past the scavenge threshold the allocation bails out to the interpreter at its
  `OilSiteAlloc` site, which is not counted as a deopt: Oil code has no interrupt checks, so it must not keep allocating
  past the threshold the way baseline code does. A closure's outerContext is the root frame's context, which marries the
  frame through the baseline JIT's active context trampoline, or nil for a clean block.
- **Encodable sends**: Pass 1 compiles again without inlining the method (sent by the root) that leads to an inlined
  frame needing a send of a selector outside the root's literals, a super send, or a closure whose outerContext would be
  that frame's context (`refuseInliningOfFrameOf:`). `MicroBench>>benchmarkHashProbe` now compiles; its loop still runs
  in the block's baseline code.
- **Byte objects**: intrinsics for `at:` / `at:put:` / `size` of ByteArray and ByteString (prims 60-64; new opcodes
  `OilLoadByteSize`, `OilLoadByte`, `OilLoadChar`, `OilStoreByte`, `OilStoreChar`) and for `compareWith:` (prim 158,
  `OilCompareBytes`: 8 bytes at a time, then byte by byte, exact primitive result), so `String>>=` inlines without
  calls when its argument's class is known. Counted loops over `size` of byte objects get Pass 2's bounds check
  elimination too.
- Not done: inline `,` (concatenation), SWAR delimiter scanning, dead nil-store elimination.

Tests: `oil/test_oil_m5.st` (native, ALL PASS), `oil-m4-test.st` (in image, byte probes added), test_oil_m3 ALL PASS.
