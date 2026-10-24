# Oil JIT: `ProfilingCogit` and Native Runtime

`ProfilingCogit` (a subclass of `StackToRegisterMappingCogit`) is the VM integration tier of Oil, the optimizing JIT for the 64-bit Spur Cog VM. It adds lightweight trip counters to baseline code, queries inline caches for type feedback, drives the Oil optimizing compiler (`OilBaseCompiler` -> `OilLoopCompiler` -> `OilFullCompiler`), manages the Oil selector table and deoptimization metadata, and implements the bailout/deoptimization runtime in `CoInterpreter`.

## Files and Load Order

To generate the 64-bit Spur Oil VM (`src/spur64.oil`), file into `Spur64VMMaker.image` in this order:

1. `oil/oil-m1-profiling-cogit.st` — `ProfilingCogit` class definition, trip counters at loop back jumps and frameful block entries, `CoInterpreter>>ceOilTrip:`, `primitiveOilTripLog`, `primitiveOilMonomorphicTarget`, and `VMMaker class>>generateSqueakSpurCogOil64VM`.
2. `image/oil/OilConstants.st` — shared pool of opcodes, descriptors, and constants.
3. `image/oil/OilBytecodeScanner.st` — `OilBytecodeDescriptor` and `OilBytecodeScanner`.
4. `image/oil/OilCompiler.st` — `OilBaseCompiler` (Pass 1 and `#pipe` hook).
5. `image/oil/OilCompilerBackend.st` — `OilBaseCompiler` (Pass 3 native code generation).
6. `image/oil/OilCompilerPass2.st` — `OilLoopCompiler` (Pass 2 loop optimizer) and `OilFullCompiler`.
7. `oil/oil-m3-native-backend.st` — `ProfilingCogit` Oil driver (`oilMethod:receiverClass:`, `oilCompile:receiverClass:`, `oilGenerate:`), deoptimization metadata (`fillMetadata:cogMethod:`), `CoInterpreter>>ceOilBailout:`, selector table, invalidation on selector flush (`unlinkSendsOf:isMNUSelector:`), and primitives (`primitiveOilCompile`, `primitiveOilSetSelectors`, `primitiveOilMethodInfo`, `primitiveOilLastCompilation`).

Then run `VMMaker generateSqueakSpurCogOil64VM` and build with `building/linux64x64/squeak.cog.spur/build.oil/mvm` (produces `products/sqcogspur64linuxht.oil/squeak`).

## Native Tests

- `oil/test_profiling_cogit.st` — trip counter and inline cache query tests.
- `oil/test_oil_m3.st` — end-to-end compilation, `sumScores:` benchmark, class guard and overflow deoptimization, forwarding fast path, and GC robustness.
- `oil/test_oil_m5.st` — deopt disqualification, escaping closures and brace arrays (`OilMakeClosure`, `OilNewArray`), byte/stream intrinsics, selector table (`OilExtraSelectorBase`), and constant-left arithmetic/comparison probes.

## Key Runtime Mechanisms

- **Trip counters**: 32-bit counters (initialized to 65535) are placed only at loop back jumps (`genJumpBackTo:`) and frameful block entries (`compileBlockFrameBuild:`, `compileFullBlockMethodFrameBuild:`), stored in a pinned heap object referenced by `SistaCogMethod>>counters`. When a counter reaches zero it calls `ceOilTripTrampoline` -> `CoInterpreter>>ceOilTrip:`, which identifies the outer home method and records it in `oilTripLog`.
- **Entry points**: `ProfilingCogit>>oilMethod:receiverClass:` compiles a method and answers its `CogMethod *` (or `nil`). `primitiveOilCompile` runs `oilCompile:receiverClass:` (Pass 1) while baseline inline caches are still linked, frees the baseline `CogMethod` and divorces its frames, and runs `oilGenerate:` (`#pipe` + Pass 3).
- **Deoptimization metadata & `ceOilBailout:`**: An Oil `CogMethod` stores the oop of a pinned metadata `Array` tagged with `1` in its `counters` field (`isOilMethod:`). On a failed guard or check, the bailout stub passes the site index to `ceOilBailoutTrampoline` -> `CoInterpreter>>ceOilBailout:`, which either unforwards a forwarded receiver/argument and resumes machine code in place, or reconstructs the interpreter frame stack (rematerializing any virtual closures and temp vectors) and continues in the interpreter. After `OilDisqualifyDeopts` deoptimizations, the Oil method is freed and disqualified from future Oil compilation.
- **Oil selector table**: Sends of selectors from inlined methods that are not among the root method's literals are indexed via `oilExtraSelectors` (`OilExtraSelectorBase + k`) and dereferenced by `ceOilDereferenceSelectorIndex`. When a selector is flushed (`unlinkSendsOf:isMNUSelector:`), any Oil method that inlined that selector is discarded if not currently active on the stack.
- **Code zone size**: `ProfilingCogit>>defaultCogCodeSize` defaults to 4 MB (clamped in `CoInterpreter>>checkImageHeaderLoad`) so baseline and Oil methods share ample room without premature code compactions.
