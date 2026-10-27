"Oil M10 acceptance test (in image): the analysis of the float loop registers (OilInliningCompiler>>prepareFloatLoops, run by
 Pass 3).  In an innermost loop without calls, guards or stores, the float variables (assigned only float results or moves of
 float variables, read only by float instructions) get XMM registers across iterations: kind 1 when read before assigned
 (unboxed when entering, they must hold a Float there: the code before the loop assigns them a Float literal or a float
 result), kind 2 when always assigned before read and dead after the loop (0.0 when entering); and the float invariants
 (kind 100 + how they are unboxed: 0 a Float, 1 or a SmallInteger, 2 or an exactly representable SmallInteger).  Pass 2 no
 longer unrolls loops with float arithmetic (they get registers instead).  The code generation is tested natively
 (oil/test_oil_m10.st).
 Files in the Oil sources, compiles probes (Pass 1 with simulated type feedback, then pipe, then the analysis), checks the
 loops and their registers, and that the IR still runs like the real methods (OilIRInterpreter)."
| dir |
Utilities authorInitials: 'cb'.
dir := Smalltalk at: #OilSourceDir ifAbsentPut: [((FileDirectory default fileExists: 'OilConstants.st') ifTrue: [FileDirectory default] ifFalse: [FileDirectory default directoryNamed: 'oil']) pathName, '/'].
#('OilInstructionConstants.st' 'OilConstants.st' 'OilBytecodeScanner.st' 'OilCompiler.st' 'OilCompilerBackend.st' 'OilCompilerPass2.st' 'OilSimulation.st') do:
	[:f | (FileStream readOnlyFileNamed: dir, f) fileIn]!

| out pass fail check model compile run cls probes floatLoops |
out := FileStream forceNewFileNamed: (Smalltalk at: #OilResultFile ifAbsent: [(Smalltalk at: #OilSourceDir), 'm10-test-result.txt']).
pass := 0. fail := 0.
check := [:name :bool |
	bool == true
		ifTrue: [pass := pass + 1. out nextPutAll: 'PASS  '; nextPutAll: name; cr]
		ifFalse: [fail := fail + 1. out nextPutAll: 'FAIL  '; nextPutAll: name; cr]. out flush].
Object subclass: #OilM10Model instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
cls := Smalltalk at: #OilM10Model.
#('mandelbrot: size
    | count zr zi cr ci tr i |
    count := 0.
    0 to: size - 1 do: [:y |
        ci := 2.0 * y / size - 1.0.
        0 to: size - 1 do: [:x |
            cr := 2.0 * x / size - 1.5.
            zr := 0.0. zi := 0.0. i := 0.
            [i < 50 and: [zr * zr + (zi * zi) <= 4.0]] whileTrue:
                [tr := zr * zr - (zi * zi) + cr.
                 zi := 2.0 * zr * zi + ci.
                 zr := tr.
                 i := i + 1].
            i = 50 ifTrue: [count := count + 1]]].
    ^count'
  'floatSum: n | s x | s := 0.0. x := 1.5. 1 to: n do: [:i | s := s + x]. ^s'
  'poly: x n: n | s | s := 0.0. 1 to: n do: [:i | s := s * x + 1.0]. ^s'
  'intStart: n | s | s := 0. 1 to: n do: [:i | s := s + 1.5]. ^s'
  'escapes: n | s | s := 0.0. 1 to: n do: [:i | s := s + 1.5. s printString]. ^s'
  'tempAfter: n | s t | s := 0.0. t := nil. 1 to: n do: [:i | t := s * 2.0. s := t + 1.0]. ^t'
  'intLoop: n | s | s := 0. 1 to: n do: [:i | s := s + i]. ^s')
	do: [:s | cls compile: s classified: 'tests'].
model := cls new.
compile := [:sel :argLists | | fbk comp |
	fbk := OilSimulatedTypeFeedback new.
	argLists do: [:args | fbk record: [[model perform: sel withArguments: args] on: Error do: [:e | e return: nil]]].
	comp := OilConvolutedCompiler new.
	comp typeFeedback: fbk.
	comp compileMethod: cls >> sel receiverClass: (comp handleFor: cls).
	comp failed ifFalse: [comp pipe. comp failed ifFalse: [comp prepareFloatLoops]].
	comp].
run := [:comp :args | [(OilIRInterpreter new on: comp) run: model with: args] on: Error do: [:e | #error -> e description]].
"floatLoops: {{head. end. {{vreg. kind}...}}...}, the vregs named by the method's temporaries where possible"
floatLoops := [:comp | (0 to: (comp instVarNamed: 'oilNumFloatLoops') - 1) collect: [:k |
	{(comp instVarNamed: 'oilFloatLoopHead') at: k. (comp instVarNamed: 'oilFloatLoopEnd') at: k.
	 (0 to: ((comp instVarNamed: 'oilFloatLoopNum') at: k) - 1) collect: [:j |
		{(comp instVarNamed: 'oilFloatLoopVReg') at: k * 8 + j. (comp instVarNamed: 'oilFloatLoopKind') at: k * 8 + j}]}]].
"{selector. sample arguments. arguments to check. check on the float loops (kinds of the pinned registers, sorted)}"
probes := {
	{#mandelbrot:. {{8}}. {{0}. {1}. {8}}. [:fl | fl size = 1 and: [((fl first at: 3) collect: [:p | p last]) asSortedCollection asArray = #(1 1 2 101 101)]]}.
	{#floatSum:. {{10}}. {{0}. {1}. {10}}. [:fl | fl size = 1 and: [((fl first at: 3) collect: [:p | p last]) asSortedCollection asArray = #(1 101)]]}.
	{#poly:n:. {{1.5. 10}}. {{1.5. 10}. {0.5. 0}}. [:fl | fl size = 1 and: [((fl first at: 3) collect: [:p | p last]) asSortedCollection asArray = #(1 101)]]}.
	{#intStart:. {{10}}. {{0}. {10}}. [:fl | fl isEmpty or: [((fl first at: 3) collect: [:p | p last]) allSatisfy: [:kind | kind >= 100]]]}.
	{#escapes:. {{3}}. {{3}}. [:fl | fl isEmpty]}.
	{#tempAfter:. {{3}}. {{0}. {3}}. [:fl | fl size = 1 and: [((fl first at: 3) collect: [:p | p last]) asSortedCollection asArray = #(1)]]}.
	{#intLoop:. {{3}}. {{3}}. [:fl | fl isEmpty]}}.
probes do: [:spec | | sel comp fl |
	sel := spec first.
	comp := compile value: sel value: (spec at: 2).
	fl := floatLoops value: comp.
	out cr; nextPutAll: comp irString; nextPutAll: sel; nextPutAll: ': float loops '; print: fl; cr.
	check value: sel, ' compiles' value: comp failed not.
	check value: sel, ' float loop registers' value: ((spec at: 4) value: fl).
	(spec at: 3) do: [:args | | r real |
		r := run value: comp value: args.
		real := [model perform: sel withArguments: args] on: Error do: [:e | #error].
		check value: sel, ' IR = real for ', (args printString contractTo: 40) value: (r = real or: [(r isKindOf: Association) and: [r key == #deopt]])]].
out cr; nextPutAll: 'TOTAL: '; print: pass; nextPutAll: ' passed, '; print: fail; nextPutAll: ' failed'; cr.
out close!
