"Oil FloatFusion acceptance test (in image): OilFullCompiler's dominator-scoped value numbering (OilFullCompiler>>valueNumber)
 and float fusion (OilFullCompiler>>fuseFloats).  Files in the Oil sources, compiles probes (Pass 1 with simulated type
 feedback, then pipe: Pass 2 with value numbering, then float fusion), checks the statistics and the IR, and validates
 the IR by executing it (OilIRInterpreter, which keeps unboxed float results aside like XMM registers) against the real
 execution of each method."
| dir |
Utilities authorInitials: 'cb'.
dir := Smalltalk at: #OilSourceDir ifAbsentPut: [((FileDirectory default fileExists: 'OilConstants.st') ifTrue: [FileDirectory default] ifFalse: [FileDirectory default directoryNamed: 'oil']) pathName, '/'].
#('OilInstructionConstants.st' 'OilConstants.st' 'OilBytecodeScanner.st' 'OilCompiler.st' 'OilCompilerBackend.st' 'OilCompilerPass2.st' 'OilSimulation.st') do:
	[:f | (FileStream readOnlyFileNamed: dir, f) fileIn]!

| out pass fail check model compile run probes |
out := FileStream forceNewFileNamed: (Smalltalk at: #OilResultFile ifAbsent: [(Smalltalk at: #OilSourceDir), 'oil-full-compiler-test-result.txt']).
pass := 0. fail := 0.
check := [:name :bool |
	bool == true
		ifTrue: [pass := pass + 1. out nextPutAll: 'PASS  '; nextPutAll: name; cr]
		ifFalse: [fail := fail + 1. out nextPutAll: 'FAIL  '; nextPutAll: name; cr]. out flush].
Object subclass: #OilFloatFusionTest instanceVariableNames: 'total' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
#('mandel: cr with: ci | zr zi tr i | zr := 0.0. zi := 0.0. i := 0. [i < 50 and: [zr * zr + (zi * zi) <= 4.0]] whileTrue: [tr := zr * zr - (zi * zi) + cr. zi := 2.0 * zr * zi + ci. zr := tr. i := i + 1]. ^i'
  'axpy: a x: x y: y ^a * x + y'
  'poly: x ^(x * x * 3.0) - (x * 2.0) + 1.0'
  'reuse: x | t | t := x * 2.0. ^t * t + t'
  'twice: x ^2 * x'
  'ratio: a by: b ^a / b + 1.0'
  'unaryFloat: x y: y ^(x squared + y squared) sqrt abs negated'
  'sqrtOf: x ^x sqrt + 1.0'
  'less: a than: b ^a < b ifTrue: [1] ifFalse: [2]'
  'lvnLoop: anArray | s | s := 0. 1 to: anArray size do: [:i | s := s + (anArray at: i) + (anArray at: i)]. ^s + total + total'
  'lvnBranch: anArray at: i | a | a := anArray at: i. ^a > 0 ifTrue: [(anArray at: i) + total] ifFalse: [(anArray at: i) - total]'
  'lvnStore: x total := x. ^total + total'
  'total: n total := n')
	do: [:s | (Smalltalk at: #OilFloatFusionTest) compile: s classified: 'tests'].
model := (Smalltalk at: #OilFloatFusionTest) new total: 7; yourself.
compile := [:sel :argLists | | fbk comp |
	fbk := OilSimulatedTypeFeedback new.
	argLists do: [:args | fbk record: [[model perform: sel withArguments: args] on: Error do: [:e | e return: nil]]].
	comp := OilCompiler new.
	comp typeFeedback: fbk.
	comp compileMethod: (Smalltalk at: #OilFloatFusionTest) >> sel receiverClass: (comp handleFor: (Smalltalk at: #OilFloatFusionTest)).
	comp failed ifFalse: [comp pipe].
	comp].
run := [:comp :args | [(OilIRInterpreter new on: comp) run: model with: args] on: Error do: [:e | #error -> e description]].
"{selector. sample arguments (type feedback). arguments to check. checks on {loads removed. checks removed. unboxed}}"
probes := {
	{#mandel:with:. {{-0.5. 0.5}}. {{-0.5. 0.5}. {0.0. 0.0}. {1.0. 1.0}. {-2.0. 0.0}. {0.25. 0.5}}. [:st | (st at: 3) >= 4]}.
	{#axpy:x:y:. {{2.0. 3.5. 0.25}}. {{2.0. 3.5. 0.25}. {2.0. 3. 1}. {1.0e300. 1.0e10. 1.0}. {2. 3.0. 1.0}}. [:st | (st at: 3) = 1]}.
	{#poly:. {{1.5}}. {{1.5}. {-2.0}. {0.0}. {3}}. [:st | (st at: 3) >= 3]}.
	{#reuse:. {{1.5}}. {{1.5}. {-0.25}}. [:st | true]}.
	{#twice:. {{1.5}}. {{1.5}. {-3.0}}. [:st | true]}.
	{#ratio:by:. {{3.0. 2.0}}. {{3.0. 2.0}. {3.0. 0.0}. {1. 2.0}}. [:st | (st at: 3) = 1]}.
	{#unaryFloat:y:. {{3.0. 4.0}}. {{3.0. 4.0}. {-3.0. 4.0}. {0.0. 0.0}. {3. 4.0}}. [:st | (st at: 3) = 5]}.
	{#sqrtOf:. {{4.0}}. {{4.0}. {0.0}. {-0.0}. {-1.0}. {Float nan}}. [:st | (st at: 3) = 1]}.
	{#less:than:. {{1.0. 2.0}}. {{1.0. 2.0}. {2.0. 1.0}. {Float nan. 1.0}. {2.5. 3}}. [:st | true]}.
	{#lvnLoop:. {{#(1 2 3)}}. {{#(1 2 3)}. {#()}. {(1 to: 100) asArray}. {#(1 nil)}}. [:st | (st at: 1) >= 1]}.
	{#lvnBranch:at:. {{#(5 -5). 1}. {#(5 -5). 2}}. {{#(5 -5). 1}. {#(5 -5). 2}. {#(5 -5). 3}}. [:st | (st at: 2) >= 2]}.
	{#lvnStore:. {{3}}. {{3}. {21}}. [:st | (st at: 1) >= 2]}}.
probes do: [:spec | | sel comp st |
	sel := spec first.
	comp := compile value: sel value: (spec at: 2).
	st := (8 to: 10) collect: [:k | comp pass2Statistics: k].
	out cr; nextPutAll: comp irString; nextPutAll: sel; nextPutAll: ': loads removed, checks removed, unboxed float results: '; print: st; cr.
	check value: sel, ' compiles' value: comp failed not.
	check value: sel, ' statistics' value: ((spec at: 4) value: st).
	(spec at: 3) do: [:args | | r real |
		r := run value: comp value: args.
		real := [model perform: sel withArguments: args] on: Error do: [:e | #error].
		(r isKindOf: Association) ifFalse:
			[check value: sel, ' IR = real for ', (args printString contractTo: 50) value: (r = real or: [r isFloat and: [real isFloat and: [r isNaN and: [real isNaN]]]])]
			ifTrue:
				[out nextPutAll: '   '; print: args; nextPutAll: ' -> '; print: r; cr.
				 check value: sel, ' IR deopts (not an error) for ', (args printString contractTo: 50) value: r key == #deopt]]].
model total: 7.
out cr; nextPutAll: 'TOTAL: '; print: pass; nextPutAll: ' passed, '; print: fail; nextPutAll: ' failed'; cr.
out close!
