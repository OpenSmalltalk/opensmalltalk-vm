"Oil Milestone 3 end-to-end test: native code generation, bailout and deoptimization.
 Run with run-st.sh on a Squeak 6.x 64-bit image, using the VM built from src/spur64.oil (with Oil M3).
 Writes oil-m3-result.txt (and oil-m3-code.bin, the machine code of the Oil-compiled sumScores:) next to the image."
| irDump last dir resultPath out failures check model items wrong oc sum expected r info m bench t0 baseMs oilMs iters sels setSels compileResult deopts fast before arr3 x y codeFile n timeOf ocItems |
Utilities authorInitials: 'cb'.
dir := FileDirectory default.
resultPath := dir fullNameFor: 'oil-m3-result.txt'.
out := FileStream forceNewFileNamed: resultPath.
failures := OrderedCollection new.
check := [:name :bool |
	out nextPutAll: (bool == true ifTrue: ['PASS '] ifFalse: ['FAIL ']); nextPutAll: name; cr; flush.
	bool == true ifFalse: [failures add: name]].

"--- Test classes ---"
Object subclass: #OilTestItem instanceVariableNames: 'score' classVariableNames: '' poolDictionaries: '' category: 'Cogit-Oil-Debugging'.
(Smalltalk at: #OilTestItem) compile: 'score ^score' classified: 'accessing'.
(Smalltalk at: #OilTestItem) compile: 'score: aNumber score := aNumber' classified: 'accessing'.
Object subclass: #OilWrongItem instanceVariableNames: 'weight' classVariableNames: '' poolDictionaries: '' category: 'Cogit-Oil-Debugging'.
(Smalltalk at: #OilWrongItem) compile: 'score ^1000000' classified: 'accessing'.
Object subclass: #OilTestModel instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'Cogit-Oil-Debugging'.
(Smalltalk at: #OilTestModel) compile: 'sumScores: aCollection | total | total := 0. aCollection do: [:each | total := total + each score]. ^total' classified: 'tests'.
(Smalltalk at: #OilTestModel) class compile: 'oilSetSelectors: anArray <primitive: ''primitiveOilSetSelectors''> ^#failed' classified: 'oil'.
CompiledMethod compile: 'oilCompileFor: aClass <primitive: ''primitiveOilCompile''> ^#failed' classified: 'oil'.
CompiledMethod compile: 'oilInfo <primitive: ''primitiveOilMethodInfo''> ^#failed' classified: 'oil'.
CompiledMethod class compile: 'oilLastCompilation <primitive: ''primitiveOilLastCompilation''> ^#failed' classified: 'oil'.
irDump := [:ir | | s i names |
	names := #(ConstTagged Const64 Move AddTagged SubTagged AndTagged OrTagged XorTagged ShiftTagged OddTagged LoadField StoreField LoadElement StoreElement CmpTagged BranchTrue BranchFalse Jump Return GuardClass CheckBounds Call0 Call1 CallN AddImmTagged CmpImmTagged LoadSize MakeClosure NewArray CallSuper AddImmTaggedNC ModTagged LoadByteSize LoadByte LoadChar StoreByte StoreChar CompareBytes Trap CharValue StreamNext StreamNextPut).
	s := WriteStream on: String new.
	i := 1.
	[i <= ir size] whileTrue:
		[| w op len |
		 w := ir at: i. op := w >> 24.
		 s tab; nextPutAll: ((i - 1) printPaddedWith: $0 to: 4); tab; nextPutAll: ((op between: 1 and: names size) ifTrue: [names at: op] ifFalse: ['?']); tab;
			print: (w >> 16 bitAnd: 255); space; print: (w >> 8 bitAnd: 255); space; print: (w bitAnd: 255); cr.
		 len := (#(2 20 22 23 41 42) includes: op) ifTrue: [3] ifFalse: [op = 28 ifTrue: [4] ifFalse: [(op = 24 or: [op = 30]) ifTrue: [3 + ((w bitAnd: 255) + 3 // 4)] ifFalse: [1]]].
		 i := i + len].
	s contents].

"--- Tell Oil its special selectors (kind, selector pairs) ---"
sels := OrderedCollection new.
#(value value: value:value: value:value:value: value:value:value:value:) doWithIndex: [:s :i | sels add: i - 1; add: s].
sels add: 5; add: #bitXor:.
sels add: 8; add: 1000. "this test deoptimizes the same method many times: do not disqualify it"
#(do: reverseDo: collect: select: reject: detect: detect:ifNone: detect:ifFound:ifNone: inject:into: do:separatedBy: doWithIndex: withIndexDo: keysAndValuesDo: timesRepeat: to:do: to:by:do: scanFor: findElementOrNil: with:do: allSatisfy: anySatisfy: noneSatisfy: count: detectMax: detectMin:)
	do: [:s | sels add: 6; add: s].
#(error: errorNoFreeSpace errorNotFound: errorSubscriptBounds: errorNoSuchElement errorEmptyCollection errorKeyNotFound: errorKeyNotFound errorImproperStore errorNonIntegerIndex errorNotIndexable subclassResponsibility shouldNotImplement notYetImplemented halt halt: deprecated: deprecated signal signal: doesNotUnderstand: cannotReturn: primitiveFailed primitiveFailed:)
	do: [:s | sels add: 7; add: s].
setSels := (Smalltalk at: #OilTestModel) oilSetSelectors: sels asArray.
check value: 'primitiveOilSetSelectors available (VM has Oil M3)' value: setSels ~~ #failed.
setSels == #failed ifTrue:
	[out close.
	 self error: 'Oil M3 primitives missing'].

model := (Smalltalk at: #OilTestModel) new.
m := (Smalltalk at: #OilTestModel) >> #sumScores:.
items := (1 to: 10000) asArray collect: [:i | (Smalltalk at: #OilTestItem) new score: i; yourself].
expected := 10000 * 10001 // 2.
timeOf := [:count :coll | | ms | ms := Time millisecondsToRun: [count timesRepeat: [model sumScores: coll]]. ms].

"--- Baseline (Cogit) ---"
check value: 'baseline sumScores: correct' value: (model sumScores: items) = expected.
5 timesRepeat: [model sumScores: items].
check value: 'sumScores: is baseline (not Oil) before compilation' value: m oilInfo isNil.
Smalltalk garbageCollect.
5 timesRepeat: [model sumScores: items]. "relink the inline caches (a full GC unlinks all sends)"
baseMs := timeOf value: 1000 value: items.
out nextPutAll: 'baseline (Cogit) sumScores: 1000 x 10000 elements: '; print: baseMs; nextPutAll: ' ms'; cr.
3 timesRepeat: [model sumScores: items].

"--- Compile with Oil ---"
compileResult := m oilCompileFor: (Smalltalk at: #OilTestModel).
out nextPutAll: 'oilCompileFor: result: '; print: compileResult; cr; flush.
last := CompiledMethod oilLastCompilation.
out nextPutAll: 'last compilation: failure '; print: (last at: 1); nextPutAll: ' eager '; print: (last at: 3); nextPutAll: ' failed at IR '; print: (last at: 4);
	nextPutAll: ' sites '; print: (last at: 5); nextPutAll: ' frames '; print: (last at: 6); nextPutAll: ' homes '; print: (last at: 7); nextPutAll: ' allocated registers '; print: (last at: 8); cr;
	nextPutAll: 'IR ('; print: (last at: 2) size; nextPutAll: ' words):'; cr; nextPutAll: (irDump value: (last at: 2)); nextPutAll: 'trace: '; print: (last at: 9); cr; flush.
last size >= 11 ifTrue: "Oil M4: the IR above is Pass 2's; Pass 1's and Pass 2's statistics"
	[out nextPutAll: 'Pass 1 IR ('; print: (last at: 10) size; nextPutAll: ' words):'; cr; nextPutAll: (irDump value: (last at: 10));
		nextPutAll: 'Pass 2 (loops rotated, bounds checks removed, dead instructions, sizes shared, unchecked increments, Pass 1 words, guards removed, undo stubs): '; print: (last at: 11); cr; flush].
check value: 'Oil compilation succeeds (result 0)' value: compileResult = 0.
info := m oilInfo.
check value: 'sumScores: now has Oil machine code' value: info notNil.
info notNil ifTrue:
	[out nextPutAll: 'Oil CogMethod at 16r'; nextPutAll: ((info at: 4) printStringBase: 16); nextPutAll: ', '; print: (info at: 3) size; nextPutAll: ' bytes (header + code + map)'; cr.
	 codeFile := FileStream forceNewFileNamed: (dir fullNameFor: 'oil-m3-code.bin').
	 codeFile binary; nextPutAll: (info at: 3); close.
	 (FileStream forceNewFileNamed: (dir fullNameFor: 'oil-m3-code.addr')) nextPutAll: ((info at: 4) printStringBase: 16); close].

"--- Native execution ---"
r := model sumScores: items.
check value: 'Oil sumScores: correct (50005000)' value: r = expected.
check value: 'Oil sumScores: on an empty Array is 0' value: (model sumScores: #()) = 0.
check value: 'Oil sumScores: on a 1 element Array' value: (model sumScores: {(Smalltalk at: #OilTestItem) new score: 42; yourself}) = 42.
info := m oilInfo.
check value: 'no deoptimization so far' value: (info notNil and: [(info at: 1) = 0]).
oilMs := timeOf value: 1000 value: items.
out nextPutAll: 'Oil sumScores: 1000 x 10000 elements: '; print: oilMs; nextPutAll: ' ms'; cr.
oilMs := timeOf value: 1000 value: items.
out nextPutAll: 'Oil sumScores: 1000 x 10000 elements (again): '; print: oilMs; nextPutAll: ' ms'; cr.
out nextPutAll: 'speedup: '; print: (baseMs / (oilMs max: 1)) asFloat; cr.
t0 := timeOf value: 10000 value: items.
out nextPutAll: 'Oil sumScores: 10000 x 10000 elements (the bench harness shape, Cogit baseline 1873 ms): '; print: t0; nextPutAll: ' ms'; cr.
check value: 'Oil is faster than the baseline' value: oilMs < baseMs.

"--- Deoptimization: a foreign element trips the class guard in the inlined block ---"
wrong := (items first: 10) copy.
wrong at: 5 put: (Smalltalk at: #OilWrongItem) new.
check value: 'deopt in a 10 element Array at 5' value: (model sumScores: wrong) = (55 - 5 + 1000000).
info := m oilInfo. before := info at: 1.
wrong := items copy.
wrong at: 5000 put: (Smalltalk at: #OilWrongItem) new.
r := model sumScores: wrong.
check value: 'deopt: result with an OilWrongItem at 5000 is correct' value: r = (expected - 5000 + 1000000).
info := m oilInfo.
out nextPutAll: 'deopts after OilWrongItem: '; print: (info at: 1); cr.
check value: 'deopt: the class guard bailed out to the interpreter (deopt count +1)' value: (info at: 1) = (before + 1).
check value: 'after deopt: Oil code still runs correctly' value: (model sumScores: items) = expected.
check value: 'after deopt: still no further deopt' value: (m oilInfo at: 1) = (before + 1).
wrong := items copy. wrong at: 1 put: (Smalltalk at: #OilWrongItem) new.
check value: 'deopt at the first element' value: (model sumScores: wrong) = (expected - 1 + 1000000).
wrong := items copy. wrong at: 10000 put: (Smalltalk at: #OilWrongItem) new.
check value: 'deopt at the last element' value: (model sumScores: wrong) = (expected - 10000 + 1000000).
wrong := items copy. wrong at: 7 put: 3.
check value: 'deopt on a SmallInteger element: the interpreter sends #score, MNU' value:
	([model sumScores: wrong. false] on: MessageNotUnderstood do: [:e | e return: e message selector == #score]).
"Overflow of the tagged add: the interpreter continues with a LargeInteger"
wrong := {(Smalltalk at: #OilTestItem) new score: SmallInteger maxVal; yourself. (Smalltalk at: #OilTestItem) new score: 10; yourself}.
check value: 'deopt on SmallInteger overflow: LargePositiveInteger result' value: (model sumScores: wrong) = (SmallInteger maxVal + 10).
"A different collection class fails the guard on the argument, at the do: send in the root frame: the dissolved
 closure and temp vector are rematerialized, the closure's outerContext is the root frame's context"
ocItems := OrderedCollection withAll: (items first: 100).
check value: 'deopt on an OrderedCollection argument (root frame, rematerialized closure)' value: (model sumScores: ocItems) = (100 * 101 // 2).
info := m oilInfo.
out nextPutAll: 'deopts after all deopt tests: '; print: (info at: 1); cr.

"--- Forwarding fast path: a forwarded element passes the guard after unforwarding, without deopt ---"
arr3 := (1 to: 100) asArray collect: [:i | (Smalltalk at: #OilTestItem) new score: i; yourself].
model sumScores: arr3.
x := arr3 at: 50.
y := (Smalltalk at: #OilTestItem) new score: 1000; yourself.
before := m oilInfo.
x becomeForward: y.
r := model sumScores: arr3.
info := m oilInfo.
out nextPutAll: 'fast path (unforward) count: '; print: (info at: 2); nextPutAll: ' deopts: '; print: (info at: 1); cr.
check value: 'forwarded element: correct result' value: r = (5050 - 50 + 1000).
check value: 'forwarded element: no deoptimization' value: (info at: 1) = (before at: 1).

"--- GC robustness ---"
Smalltalk garbageCollect.
check value: 'after full GC: Oil code still installed' value: m oilInfo notNil.
check value: 'after full GC: correct' value: (model sumScores: items) = expected.
1 to: 20 do: [:i | Array new: 100000].
check value: 'after scavenges: correct' value: (model sumScores: items) = expected.
Smalltalk garbageCollect.
wrong := items copy. wrong at: 3333 put: (Smalltalk at: #OilWrongItem) new.
check value: 'deopt after full GC' value: (model sumScores: wrong) = (expected - 3333 + 1000000).

out nextPutAll: (failures isEmpty ifTrue: ['ALL PASS'] ifFalse: ['FAILURES: ', failures size printString]); cr.
out close.
failures isEmpty ifFalse: [self error: 'Oil M3 test failures: ', failures printString].
