# Oil JIT: Milestone 1 (ProfilingCogit)

`ProfilingCogit` is the profiling tier of Oil, the optimizing JIT for the
OpenSmalltalk VM. It is a subclass of `StackToRegisterMappingCogit`. It adds trip
counters at loop back jumps and frameful block entries, plus the
`ceOilTripTrampoline` / `CoInterpreter>>ceOilTrip:` runtime that decides which
method Oil should compile. It also answers inline cache queries
(`monomorphicTargetFor:in:`, `monomorphicClassFor:in:`).

## Files

- `oil-m1-profiling-cogit.st`: Slang source as a chunk-format fileIn. It defines the
  `ProfilingCogit` class, the `CoInterpreter` trip runtime, two named primitives
  (`primitiveOilTripLog`, `primitiveOilMonomorphicTarget`) and the VMMaker
  configuration `VMMaker class>>generateSqueakSpurCogOil64VM`. Every interpreter-side
  method is marked `<essential: #ProfilingCogit>`, so the stock configurations
  generate the same code as before.
- `../src/spur64.oil/`: the C generated from it with VMMaker.oscog-eem.3817. It is not
  committed yet, because the local git-secrets hook flags a false positive
  (`key = fixFollowedField...`) that also appears in the stock generated C. Regenerate
  it as shown below.
- `../building/linux64x64/squeak.cog.spur/build.oil/mvm`: the build script. It is the
  `build/mvm` script with `--with-src=src/spur64.oil`, and it installs into
  `products/sqcogspur64linuxht.oil`.
- `test_profiling_cogit.st`: an end-to-end headless test (34 checks) for a Squeak
  6.x 64-bit image.

## Regenerate, build, test

```
# in a VMMaker image (image/Spur64VMMaker.image), e.g. with run-st.sh --answer true:
(FileStream readOnlyFileNamed: 'oil/oil-m1-profiling-cogit.st') fileIn.
VMMaker generateSqueakSpurCogOil64VM.

cd building/linux64x64/squeak.cog.spur/build.oil && ./mvm

run-st.sh --vm products/sqcogspur64linuxht.oil/squeak <Squeak6.1-64bit.image> oil/test_profiling_cogit.st
```

## Design notes

- **Counter sites.** Counters go only on back jumps (`genJumpBackTo:`) and frameful
  block entries (`compileBlockFrameBuild:` and `compileFullBlockMethodFrameBuild:`).
  Methods without loops or blocks get no counters and no counter object.
- **Counter storage.** Each site has a 32-bit counter. The counters of a method live in
  a pinned heap object (`objectRepresentation allocateCounters:`), and the method header
  (`SistaCogMethod`) points to it through its `counters` field. The VM marks this object
  in full GCs and frees it when the method is freed.
- **Site code.** Each site runs `MoveA32 counter,T; SubCq 1,T; MoveRA32 T,counter;
  JumpNonZero skip; MoveCq kind,SendNumArgsReg; CallRT ceOilTripTrampoline`. Counters
  start at 65535, so a site trips once, on its 65535th execution. After that the
  counter wraps to 16rFFFFFFFF.
- **`ceOilTrip:`.** It finds the root method for an Oil compilation:
  - In a block activation, it walks the closure's outer contexts up to the home
    context. For a clean full block, it uses the static `CompiledBlock` outer-code
    chain instead.
  - At a back jump in a method that has a closure argument (e.g. the to:do: loop in
    `do:`), it uses the home method of that closure.
  - Otherwise it uses the method itself.

  It also samples a live element at `currentPosition`: the block's first argument, or
  `array at: index` taken from the frame's SmallInteger temps and the receiver (or the
  receiver's `Array` inst var). It does not allocate, collect garbage or change the
  stack.
- **Trip log.** If the image has installed a trip log (an `Array`, through
  `primitiveOilTripLog`), each trip is recorded in it as
  `{kind. trippedMethod. homeMethod. homeContext. sample. sampleClass}`. The log
  variable is registered as an extra GC root.
- **Inline cache queries.** `monomorphicTargetFor:in:` answers the target `CogMethod` of
  an ordinary send that is linked monomorphically, or nil for unlinked sends and sends
  linked to PICs. A full GC flushes the method cache, which unlinks all sends
  (`CoInterpreter>>flushMethodCache`), so these queries answer nil until the sends are
  relinked.
