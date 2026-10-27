"Oil M9 acceptance test (in image): loop unrolling (OilLoopOptimizer>>unrollLoops).
 Full unrolling: a leaf loop whose iterations are counted by a constant (to:do: with constant bounds, timesRepeat: of a
 constant), at most OilUnrollMaxTrips of them and iterations * body size <= OilUnrollFullBudget, becomes straight-line copies
 of its body (no test, no branch, no step: the induction variable is assigned its values), then optimized again (value
 numbering removes the checks the copies repeat); the deopt sites of the copies are cloned.  The other counted leaf loops are
 rotated, not unrolled (Oil no longer unrolls loops partially).  Rotation also covers loops tested against an immediate, and
 against a limit not known to be a SmallInteger that the loop does not assign (the bottom test gets a clone of the header's
 deopt site).
 Files in the Oil sources, compiles probes (Pass 1 with simulated type feedback, then pipe), checks the statistics, the IR
 and the deopt sites, and validates the IR by executing it (OilIRInterpreter) against the real execution of each method."
| dir |
Utilities authorInitials: 'cb'.
dir := Smalltalk at: #OilSourceDir ifAbsentPut: [((FileDirectory default fileExists: 'OilConstants.st') ifTrue: [FileDirectory default] ifFalse: [FileDirectory default directoryNamed: 'oil']) pathName, '/'].
#('OilInstructionConstants.st' 'OilConstants.st' 'OilBytecodeScanner.st' 'OilCompiler.st' 'OilCompilerBackend.st' 'OilCompilerPass2.st' 'OilSimulation.st') do:
	[:f | (FileStream readOnlyFileNamed: dir, f) fileIn]!

| out pass fail check model compile run cls probes stats sitesOK arrays items abs sweep sweepStats |
out := FileStream forceNewFileNamed: (Smalltalk at: #OilResultFile ifAbsent: [(Smalltalk at: #OilSourceDir), 'm9-test-result.txt']).
pass := 0. fail := 0.
check := [:name :bool |
	bool == true
		ifTrue: [pass := pass + 1. out nextPutAll: 'PASS  '; nextPutAll: name; cr]
		ifFalse: [fail := fail + 1. out nextPutAll: 'FAIL  '; nextPutAll: name; cr]. out flush].
Object subclass: #OilM9Model instanceVariableNames: 'total' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
Object subclass: #OilM9Item instanceVariableNames: 'score' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
(Smalltalk at: #OilM9Item) compile: 'score ^score' classified: 'tests'.
(Smalltalk at: #OilM9Item) compile: 'score: n score := n' classified: 'tests'.
Object subclass: #OilM9A instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
Object subclass: #OilM9B instanceVariableNames: 'y' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
(Smalltalk at: #OilM9A) compile: 'm9Size ^3' classified: 'tests'.
(Smalltalk at: #OilM9B) compile: 'm9Size ^y + y + 1' classified: 'tests'.
(Smalltalk at: #OilM9B) compile: 'y: v y := v' classified: 'tests'.
(Smalltalk at: #OilM9A) compile: 'm9Maybe ^nil' classified: 'tests'.
(Smalltalk at: #OilM9B) compile: 'm9Maybe ^self' classified: 'tests'.
cls := Smalltalk at: #OilM9Model.
#(
  "full unrolling"
  'sum3: a | s | s := 0. 1 to: 3 do: [:i | s := s + (a at: i)]. ^s'
  'times4: x | s | s := 0. 4 timesRepeat: [s := s + x]. ^s'
  'tri5 | s | s := 0. 1 to: 5 do: [:i | s := s + i + i]. ^s'
  'down4: a | s | s := 0. 4 to: 1 by: -1 do: [:i | s := s * 2 + (a at: i)]. ^s'
  'find3: a 1 to: 3 do: [:i | (a at: i) = 0 ifTrue: [^i]]. ^0'
  'byTwo: x | s | s := 0. 1 to: 9 by: 2 do: [:i | s := s + i + x]. ^s'
  'scores3: a | s | s := 0. 1 to: 3 do: [:i | s := s + (a at: i) score]. ^s'
  "not fully unrolled: too many iterations or too big a body, or not a constant count"
  'sum9 | s | s := 0. 1 to: 9 do: [:i | s := s + i]. ^s'
  'big5: a | s | s := 0. 1 to: 5 do: [:i | s := s + (a at: i) + (a at: 6 - i) + (a at: i + 1) + (a at: 7 - i) + i]. ^s'
  "rotated counted loops"
  'sumArr: a | s | s := 0. 1 to: a size do: [:i | s := s + (a at: i)]. ^s'
  'sumN: n | s | s := 0. 1 to: n do: [:i | s := s + i]. ^s'
  'whileSum: n | s i | s := 0. i := 0. [i < n] whileTrue: [s := s + i. i := i + 1]. ^s'
  'sum100 | s | s := 0. 1 to: 100 do: [:i | s := s + i]. ^s'
  'sum1000 | s | s := 0. 1 to: 1000 do: [:i | s := s + i]. ^s'
  'absSum: a | s | s := 0. 1 to: a size do: [:i | | e | e := a at: i. e > 0 ifTrue: [s := s + e] ifFalse: [s := s - e]]. ^s'
  'firstNeg: a 1 to: a size do: [:i | (a at: i) < 0 ifTrue: [^i]]. ^0'
  'sumScores: a | s | s := 0. 1 to: a size do: [:i | s := s + (a at: i) score]. ^s'
  'pointSum: n | s | s := 0. 1 to: n do: [:i | | p | p := i @ (i + 1). s := s + p x + p y]. ^s'
  'countA: aString | n | n := 0. 1 to: aString size do: [:i | (aString at: i) == $a ifTrue: [n := n + 1]]. ^n'
  'fill: a with: x 1 to: a size do: [:i | a at: i put: x]. ^a'
  'step3: n | s | s := 0. 1 to: n by: 3 do: [:i | s := s + i]. ^s'
  "bimorphic inlining in counted loops (class tests)"
  'isSymCount: coll | c | c := 0. coll do: [:e | e isSymbol ifTrue: [c := c + 1]]. ^c'
  'sizeSum: coll | s | s := 0. coll do: [:e | s := s + e m9Size]. ^s'
  'nilCount: coll | c | c := 0. coll do: [:e | e m9Maybe ifNil: [c := c + 1] ifNotNil: [c := c + 10]]. ^c'
  "a body with branches"
  'absSum2: a | s | s := 0. 1 to: a size do: [:i | | e | e := a at: i. e > 0 ifTrue: [s := s + e] ifFalse: [s := s - e]]. ^s'
  "not unrolled: a send in the body, a loop that is not counted"
  'printSizes: n | s | s := 0. 1 to: n do: [:i | s := s + i printString size]. ^s'
  'halve: n | k c | k := n. c := 0. [k > 1] whileTrue: [k := k // 2. c := c + 1]. ^c')
	do: [:s | cls compile: s classified: 'tests'].
model := cls new.
items := (1 to: 9) collect: [:i | (Smalltalk at: #OilM9Item) new score: i; yourself].
abs := {{(Smalltalk at: #OilM9A) new. (Smalltalk at: #OilM9B) new y: 5; yourself. (Smalltalk at: #OilM9A) new. (Smalltalk at: #OilM9B) new y: 1; yourself. (Smalltalk at: #OilM9A) new}}.
compile := [:sel :argLists | | fbk comp |
	fbk := OilSimulatedTypeFeedback new.
	argLists do: [:args | fbk record: [[model perform: sel withArguments: args] on: Error do: [:e | e return: nil]]].
	comp := OilCompiler new.
	comp typeFeedback: fbk.
	comp compileMethod: cls >> sel receiverClass: (comp handleFor: cls).
	comp failed ifFalse: [comp pipe].
	comp].
run := [:comp :args | [(OilIRInterpreter new on: comp) run: model with: (args collect: [:e | e copy])] on: Error do: [:e | #error -> e description]].
stats := [:comp | {comp pass2Statistics: 23. comp pass2Statistics: 24. comp pass2Statistics: 0}].
"The deopt sites of the final IR: every live site is at an instruction (a distinct one), the site held by OilGuardClass,
 OilGuardClass2 and OilCheckBounds is theirs, and every instruction that must have a site (tagged arithmetic, guards, bounds
 checks) has one."
sitesOK := [:comp | | ok starts siteOf numSites i opcode |
	ok := true.
	starts := Set new.
	i := 0.
	[i < comp irIndex] whileTrue: [starts add: i. i := i + (comp instructionLengthAt: i)].
	numSites := comp instVarNamed: 'numSites'.
	siteOf := Dictionary new.
	0 to: numSites - 1 do: [:s | | at |
		at := (comp instVarNamed: 'siteIR') at: s.
		at >= 0 ifTrue:
			[(starts includes: at) ifFalse: [ok := false].
			 (siteOf includesKey: at) ifTrue: [ok := false].
			 siteOf at: at put: s]].
	starts do: [:at |
		opcode := OilConstants opcodeNames at: (comp opcodeAt: at).
		(#(#GuardClass #GuardClass2 #AddTagged #SubTagged #AddImmTagged #CheckBounds) includes: opcode) ifTrue:
			[(siteOf includesKey: at) ifFalse: [ok := false]].
		(#(#GuardClass #GuardClass2) includes: opcode) ifTrue:
			[(siteOf at: at ifAbsent: [-1]) = (comp imm16At: at) ifFalse: [ok := false]].
		opcode = #CheckBounds ifTrue:
			[(siteOf at: at ifAbsent: [-1]) = (comp fieldCAt: at) ifFalse: [ok := false]]].
	ok].
arrays := {#(). #(5). #(5 -3). #(5 -3 7). #(1 2 3 4). #(1 -2 3 -4 5). #(9 8 7 6 5 4). #(1 2 3 4 5 6 7). #(1 2 0 4 5 6 7 8). (1 to: 9) asArray. (1 to: 33) asArray}.
"{selector. sample arguments (type feedback). arguments to check. check on {fully unrolled. partially unrolled. rotated} and the opcode histogram}"
probes := {
	{#sum3:. {{#(1 2 3 4)}}. {{#(1 2 3 4)}. {#(1 2 3)}. {#(1 2)}. {#(1 2 SmallInteger)}. {{1. 2. SmallInteger maxVal}}. {'abc'}}.
		[:st :h | st first = 1 and: [(h occurrencesOf: #Jump) + (h occurrencesOf: #BranchTrue) + (h occurrencesOf: #BranchFalse) = 0
			and: [(h occurrencesOf: #GuardClass) = 2 and: [(h occurrencesOf: #LoadSize) = 1 and: [(h occurrencesOf: #CheckBounds) = 3]]]]]}.
	{#times4:. {{5}}. {{5}. {-7}. {SmallInteger maxVal}. {nil}}.
		[:st :h | st = #(0 0 0)]}.
	{#tri5. {{}}. {{}}. [:st :h | st first = 1 and: [(h occurrencesOf: #AddTagged) = 10 and: [(h occurrencesOf: #Jump) = 0]]]}.
	{#down4:. {{#(1 2 3 4)}}. {{#(1 2 3 4)}. {#(4 3 2 1 0)}. {#(1 2)}}. [:st :h | st first = 1 and: [(h occurrencesOf: #Jump) + (h occurrencesOf: #BranchTrue) = 0]]}.
	{#find3:. {{#(1 0 3 4)}. {#(1 2 3 4)}}. {{#(1 0 3 4)}. {#(1 2 3 4)}. {#(0 0 0 0)}. {#(1 2 0)}. {#(1 2)}}. [:st :h | st first = 1 and: [(h occurrencesOf: #Jump) = 0]]}.
	{#byTwo:. {{1}}. {{1}. {-100}. {SmallInteger maxVal}}. [:st :h | st first = 1 and: [(h occurrencesOf: #AddTagged) = 10]]}.
	{#scores3:. {{items}}. {{items}. {items reverse}. {items first: 2}. {#(1 2 3)}}. [:st :h | st first = 1 and: [(h occurrencesOf: #Call0) = 0]]}.
	{#sum9. {{}}. {{}}. [:st :h | st = #(0 0 1)]}.
	{#big5:. {{(1 to: 6) asArray}}. {{(1 to: 6) asArray}. {#(1 2 3)}}. [:st :h | st first = 0]}.
	{#sumArr:. {{#(1 2 3 4)}}. arrays, {{#(1 2 nil 4 5 6 7 8)}. {{1. SmallInteger maxVal. 3. 4. 5}}. {'abcdef'}}.
		[:st :h | st = #(0 0 1) and: [(h occurrencesOf: #LoadElement) = 1 and: [(h occurrencesOf: #CheckBounds) = 0]]]}.
	{#sumN:. {{10}}. {{0}. {1}. {2}. {3}. {4}. {5}. {6}. {7}. {8}. {100}. {-5}. {nil}. {3/2}}.
		[:st :h | st = #(0 0 1) and: [(h occurrencesOf: #AddTagged) = 1]]}.
	{#whileSum:. {{10}}. {{0}. {1}. {3}. {4}. {5}. {9}. {nil}}. [:st :h | st = #(0 0 1)]}.
	{#sum100. {{}}. {{}}. [:st :h | st = #(0 0 1) and: [(h occurrencesOf: #AddImmTagged) = 0]]}.
	{#sum1000. {{}}. {{}}. [:st :h | st = #(0 0 1) and: [(h occurrencesOf: #AddImmTagged) = 0]]}.
	{#absSum:. {{#(1 -2 3)}}. arrays. [:st :h | st = #(0 0 1)]}.
	{#firstNeg:. {{#(1 -2 3)}}. arrays. [:st :h | (st at: 2) = 0]}.
	{#sumScores:. {{items}}. {{items}. {items first: 3}. {items first: 5}. {#()}. {items copyWith: 3}}. [:st :h | st = #(0 0 1) and: [(h occurrencesOf: #Call0) = 0]]}.
	{#pointSum:. {{3}}. {{0}. {1}. {3}. {10}}. [:st :h | (st at: 2) = 0 and: [(h occurrencesOf: #NewObject) = 0]]}.
	{#countA:. {{'banana'}}. {{'banana'}. {''}. {'a'}. {'aaaaaaa'}. {'xyz'}}. [:st :h | (st at: 2) = 0]}.
	{#fill:with:. {{Array new: 3. 7}}. {{Array new: 0. 7}. {Array new: 3. 7}. {Array new: 9. 'x'}. {#(1 2) beReadOnlyObject; yourself. 3}}. [:st :h | (st at: 2) = 0]}.
	{#step3:. {{10}}. {{0}. {1}. {10}. {11}. {12}. {13}. {100}}. [:st :h | st = #(0 0 1)]}.
	{#isSymCount:. {{#(#a 'b' #c 'd')}}. {{#(#a 'b' #c 'd')}. {#(#a #b)}. {#()}. {#(#a #b #c #d #e 'f' #g)}. {#(#a 3)}}. [:st :h | (st at: 2) = 0]}.
	{#sizeSum:. {abs}. {abs. {abs first, abs first}. {abs first first: 1}. {{}}. {{(Smalltalk at: #OilM9A) new. 3}}}. [:st :h | (st at: 2) = 0 and: [(h occurrencesOf: #Call0) = 0]]}.
	{#nilCount:. {abs}. {abs. {abs first, abs first}. {{}}. {{(Smalltalk at: #OilM9B) new. 3}}}. [:st :h | (st at: 2) = 0 and: [(h occurrencesOf: #Call0) = 0]]}.
	{#absSum2:. {{#(1 -2 3)}}. arrays. [:st :h | st = #(0 0 1)]}.
	{#printSizes:. {{3}}. {{3}}. [:st :h | st first + (st at: 2) = 0]}.
	{#halve:. {{100}}. {{100}. {1}}. [:st :h | st first + (st at: 2) = 0]}}.
probes do: [:spec | | sel comp st h |
	sel := spec first.
	comp := compile value: sel value: (spec at: 2).
	st := stats value: comp.
	h := comp opcodeHistogram.
	out cr; nextPutAll: comp irString; nextPutAll: sel; nextPutAll: ': fully unrolled, partially unrolled, rotated: '; print: st; nextPutAll: '; IR words '; print: comp irIndex; cr.
	check value: sel, ' compiles' value: comp failed not.
	check value: sel, ' unrolling statistics and IR' value: ((spec at: 4) value: st value: h).
	check value: sel, ' deopt sites' value: (sitesOK value: comp).
	(spec at: 3) do: [:args | | r real |
		r := run value: comp value: args.
		real := [model perform: sel withArguments: (args collect: [:e | e copy])] on: Error do: [:e | #error].
		((r isKindOf: Association) and: [r key == #deopt or: [r key == #error]])
			ifFalse: [check value: sel, ' IR = real for ', (args printString contractTo: 50) value: r = real]
			ifTrue:
				[out nextPutAll: '   '; print: args; nextPutAll: ' -> '; print: r; cr.
				 check value: sel, ' deoptimizes for ', (args printString contractTo: 50) value: r key == #deopt]]].

"Robustness: Pass 1 + Pass 2 on every method of a few classes."
sweep := Bag new.
sweepStats := Array new: 3 withAll: 0.
{OrderedCollection. Set. Dictionary. Interval. String. Array. Point. Rectangle. Integer. SmallInteger. Float. Collection. SequenceableCollection. ArrayedCollection. Bag. Symbol. ByteArray. LargePositiveInteger. Bitmap. WordArray. Matrix} do: [:c |
	c selectorsDo: [:sel | | comp |
		comp := OilCompiler new.
		[comp compileMethod: c >> sel receiverClass: (comp handleFor: c).
		 comp failed ifFalse:
			[comp pipe.
			 comp failed ifFalse:
				[(stats value: comp) withIndexDo: [:v :k | sweepStats at: k put: (sweepStats at: k) + v].
				 (sitesOK value: comp) ifFalse: [sweep add: #BADSITES. out nextPutAll: 'BAD SITES in '; print: c >> sel; cr]]].
		 sweep add: (comp failed ifTrue: [OilConstants failureNames at: comp failureCode + 1] ifFalse: [#ok])]
			on: Error do: [:e | sweep add: #ERROR. out nextPutAll: 'ERROR compiling '; print: c >> sel; nextPutAll: ': '; nextPutAll: e description; cr]]].
out cr; nextPutAll: 'Robustness sweep: '; print: sweep size; nextPutAll: ' methods: '.
sweep asSet asSortedCollection do: [:k | out nextPutAll: k; nextPutAll: '='; print: (sweep occurrencesOf: k); space].
out cr; nextPutAll: 'Sweep totals: fully unrolled '; print: (sweepStats at: 1); nextPutAll: ', rotated '; print: (sweepStats at: 3); cr.
check value: 'robustness: no Smalltalk error' value: (sweep occurrencesOf: #ERROR) = 0.
check value: 'robustness: consistent deopt sites' value: (sweep occurrencesOf: #BADSITES) = 0.
check value: 'robustness: no compilation fails for lack of room' value: (sweep occurrencesOf: #FailBufferFull) + (sweep occurrencesOf: #FailTooManySites) = 0.
check value: 'robustness: some loops unrolled or rotated' value: (sweepStats at: 1) + (sweepStats at: 3) > 0.

out cr; nextPutAll: 'TOTAL: '; print: pass; nextPutAll: ' passed, '; print: fail; nextPutAll: ' failed'; cr.
out close!
