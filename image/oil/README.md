# Oil Milestone 2: Pass 1 (linear IR, scanner, inlining, peepholes)

Clean-room Slang/Smalltalk sources for Pass 1 of Oil, the optimizing JIT for the 64-bit Spur Cog VM
(design: `oil-jit-design.md`). Author: cb.

| File | Contents |
|---|---|
| `OilConstants.st` | Shared pool: IR opcodes, condition codes, scanner tags/modes, descriptor kinds, limits, deopt site kinds, failure codes (generated from one spec). |
| `OilBytecodeScanner.st` | `OilBytecodeDescriptor` (8-byte struct) and `OilBytecodeScanner`: a 512-entry `oilGeneratorTable` (0-255 SqueakV3PlusClosures, 256-511 SistaV1) and a zero-allocation decoder (`decodeAt:`, `scanMethod:do:`) that folds extA/extB prefixes. |
| `OilCompiler.st` | `OilCompiler` (Pass 1): static 4096 x 32-bit IR buffer, register-window virtual registers with descriptors, structural inlining, tagged SmallInteger peepholes, deopt sites, frame table. |
| `OilSimulation.st` | IR printer (`printIROn:`), `OilSimulatedTypeFeedback` (receiver classes recorded per send site by simulated execution, standing in for ProfilingCogit's PICs), `OilIRInterpreter` (runs the IR on host objects to validate it), test classes. |
| `oil-scanner-test.st` | Checks the scanner against the image's `InstructionStream` on 9220 SistaV1 methods and blocks and 200 V3 methods. |
| `oil-m2-test.st` | Acceptance test: compiles the probes (`sumScores:` and others), dumps the IR, checks its shape, and compares the IR interpreter's result with the real execution. |
| `oil-translate.st` | Translates `OilBytecodeScanner` and `OilCompiler` to C with VMMaker's `CCodeGenerator` (standalone, not yet wired into the Cogit). |

## Running

```bash
SK=~/.gemini/config/skills/opensmalltalk-slang/scripts
# Use a copy of image/Spur64VMMaker.image: filing in appends to its .changes file.
nice -n 10 $SK/run-st.sh --answer true <copy>/Spur64VMMaker.image oil-scanner-test.st   # -> scanner-test-result.txt
nice -n 10 $SK/run-st.sh --answer true <copy>/Spur64VMMaker.image oil-m2-test.st        # -> m2-test-result.txt (IR dumps + PASS/FAIL)
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
