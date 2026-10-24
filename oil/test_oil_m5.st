"Oil Milestone 5 end-to-end test (native): deopt disqualification, escaping closures and brace arrays (OilMakeClosure,
 OilNewArray, eden bump allocation with the allocation bailout), benchmarkHashProbe.
 Run with run-st.sh on a Squeak 6.x 64-bit image with the Oil VM.  Writes oil-m5-result.txt next to the image."
| out failures check sels model m r info res last items wrong expected t array counter blk arr n before |
Utilities authorInitials: 'cb'.
out := FileStream forceNewFileNamed: (FileDirectory default fullNameFor: 'oil-m5-result.txt').
failures := OrderedCollection new.
check := [:name :bool |
	out nextPutAll: (bool == true ifTrue: ['PASS '] ifFalse: ['FAIL ']); nextPutAll: name; cr; flush.
	bool == true ifFalse: [failures add: name]].
Object subclass: #OilTestItem instanceVariableNames: 'score' classVariableNames: '' poolDictionaries: '' category: 'Cogit-Oil-Debugging'.
(Smalltalk at: #OilTestItem) compile: 'score ^score' classified: 'accessing'.
(Smalltalk at: #OilTestItem) compile: 'score: aNumber score := aNumber' classified: 'accessing'.
Object subclass: #OilWrongItem instanceVariableNames: 'weight' classVariableNames: '' poolDictionaries: '' category: 'Cogit-Oil-Debugging'.
(Smalltalk at: #OilWrongItem) compile: 'score ^1000000' classified: 'accessing'.
Object subclass: #OilTestModel instanceVariableNames: 'total' classVariableNames: '' poolDictionaries: '' category: 'Cogit-Oil-Debugging'.
#('sumScores: aCollection | sum | sum := 0. aCollection do: [:each | sum := sum + each score]. ^sum'
  'braceOf: a and: b ^{a. b. a + b. nil}'
  'makeCounter | count | count := 0. ^[count := count + 1]'
  'adderFor: x ^[:y | x + y + total]'
  'cleanBlock ^[:a :b | a + b]'
  'detectFirstOver: limit in: aCollection aCollection do: [:e | e score > limit ifTrue: [^e]]. ^nil'
  'escapeAndCall: aCollection | blk | blk := [:e | e score * 2]. ^aCollection collect: blk'
  'allocLoop: count | last | 1 to: count do: [:i | last := {i. i + 1. i + 2}]. ^last'
  'total: n total := n'
  'hashProbe: anArray key: key
    | index length element |
    length := anArray size.
    index := (key hash BS length) + 1.
    [element := anArray at: index.
     element == nil ifTrue: [^ index].
     element == key ifTrue: [^ index].
     index := index BS length + 1] repeat'
  'benchmarkHashProbe
    | array |
    array := Array new: 8191.
    1 to: 4000 do: [:i | array at: (i * 17 BS 8191) + 1 put: i * 17].
    ^ [10 to: 1000000 do: [:i | self hashProbe: array key: (4000 * 17)]] timeToRun')
	do: [:s | (Smalltalk at: #OilTestModel) compile: (s copyReplaceAll: 'BS' with: (String with: $\ with: $\)) classified: 'tests'].
(Smalltalk at: #OilTestModel) class compile: 'oilSetSelectors: anArray <primitive: ''primitiveOilSetSelectors''> ^#failed' classified: 'oil'.
CompiledMethod compile: 'oilCompileFor: aClass <primitive: ''primitiveOilCompile''> ^#failed' classified: 'oil'.
CompiledMethod compile: 'oilInfo <primitive: ''primitiveOilMethodInfo''> ^#failed' classified: 'oil'.
CompiledMethod class compile: 'oilLastCompilation <primitive: ''primitiveOilLastCompilation''> ^#failed' classified: 'oil'.
sels := OrderedCollection new.
#(value value: value:value: value:value:value: value:value:value:value:) doWithIndex: [:s :i | sels add: i - 1; add: s].
sels add: 5; add: #bitXor:.
#(do: reverseDo: collect: select: reject: detect: detect:ifNone: detect:ifFound:ifNone: inject:into: do:separatedBy: doWithIndex: withIndexDo: keysAndValuesDo: timesRepeat: to:do: to:by:do: scanFor: findElementOrNil: with:do: allSatisfy: anySatisfy: noneSatisfy: count: detectMax: detectMin:)
	do: [:s | sels add: 6; add: s].
#(error: errorNoFreeSpace errorNotFound: errorSubscriptBounds: errorNoSuchElement errorEmptyCollection errorKeyNotFound: errorKeyNotFound errorImproperStore errorNonIntegerIndex errorNotIndexable subclassResponsibility shouldNotImplement notYetImplemented halt halt: deprecated: deprecated signal signal: doesNotUnderstand: cannotReturn: primitiveFailed primitiveFailed:)
	do: [:s | sels add: 7; add: s].
check value: 'primitiveOilSetSelectors' value: ((Smalltalk at: #OilTestModel) oilSetSelectors: sels asArray) ~~ #failed.
model := (Smalltalk at: #OilTestModel) new total: 0; yourself.
"compile: warm up (baseline JIT), Oil-compile, answer the compile result"
res := [:sel :warm | | cm |
	cm := (Smalltalk at: #OilTestModel) >> sel.
	3 timesRepeat: warm.
	r := cm oilCompileFor: (Smalltalk at: #OilTestModel).
	last := CompiledMethod oilLastCompilation.
	out nextPutAll: sel; nextPutAll: ': oilCompileFor: -> '; print: r; nextPutAll: ' (Pass 2 '; print: (last at: 11); nextPutAll: ')'; cr; flush.
	r].

"--- 1. Brace arrays (OilNewArray) ---"
check value: 'braceOf:and: compiles (OilNewArray)' value: (res value: #braceOf:and: value: [model braceOf: 3 and: 4]) = 0.
check value: 'braceOf:and: has Oil code' value: ((Smalltalk at: #OilTestModel) >> #braceOf:and:) oilInfo notNil.
check value: 'braceOf:and: result' value: (model braceOf: 3 and: 4) = {3. 4. 7. nil}.
check value: 'braceOf:and: with Floats (deopts on the SmallInteger add)' value: (model braceOf: 1.5 and: 2) = {1.5. 2. 3.5. nil}.
arr := (1 to: 1000) collect: [:k | model braceOf: k and: 1].
check value: 'braceOf:and: many results (young arrays)' value: ((arr collect: [:e | e at: 3]) = ((1 to: 1000) collect: [:k | k + 1])).
Smalltalk garbageCollect.
check value: 'braceOf:and: results survive a full GC' value: ((arr collect: [:e | e at: 3]) = ((1 to: 1000) collect: [:k | k + 1])).

"--- 2. Escaping closures (OilMakeClosure) ---"
check value: 'makeCounter compiles (closure + temp vector)' value: (res value: #makeCounter value: [model makeCounter]) = 0.
counter := model makeCounter.
check value: 'makeCounter: counter works' value: (counter value = 1 and: [counter value = 2 and: [counter value = 3]]).
check value: 'makeCounter: counters are independent' value: (model makeCounter value = 1).
check value: 'makeCounter: outerContext is the home context' value: (counter outerContext notNil and: [counter outerContext method == ((Smalltalk at: #OilTestModel) >> #makeCounter)]).
check value: 'adderFor: compiles' value: (res value: #adderFor: value: [model adderFor: 1]) = 0.
model total: 100.
check value: 'adderFor: closure (copied value + self)' value: ((model adderFor: 5) value: 7) = 112.
check value: 'cleanBlock compiles' value: (res value: #cleanBlock value: [model cleanBlock]) = 0.
check value: 'cleanBlock works' value: (model cleanBlock value: 3 value: 4) = 7.
items := (1 to: 10) collect: [:k | (Smalltalk at: #OilTestItem) new score: k; yourself].
check value: 'escapeAndCall: compiles' value: (res value: #escapeAndCall: value: [model escapeAndCall: items]) = 0.
check value: 'escapeAndCall: result' value: (model escapeAndCall: items) = ((1 to: 10) collect: [:k | k * 2]).
check value: 'detectFirstOver:in: compiles' value: (res value: #detectFirstOver:in: value: [model detectFirstOver: 5 in: items]) = 0.
check value: 'detectFirstOver:in: non-local return' value: (model detectFirstOver: 5 in: items) score = 6.
check value: 'detectFirstOver:in: not found' value: (model detectFirstOver: 50 in: items) isNil.

"--- 3. Allocation beyond the scavenge threshold: bails out (not counted), still correct ---"
check value: 'allocLoop: compiles' value: (res value: #allocLoop: value: [model allocLoop: 10]) = 0.
check value: 'allocLoop: small' value: (model allocLoop: 10) = #(10 11 12).
check value: 'allocLoop: 3,000,000 arrays (crosses the scavenge threshold)' value: (model allocLoop: 3000000) = #(3000000 3000001 3000002).
info := ((Smalltalk at: #OilTestModel) >> #allocLoop:) oilInfo.
check value: 'allocLoop: still Oil code (allocation bailouts do not disqualify)' value: info notNil.
check value: 'allocLoop: no deoptimization counted' value: (info notNil and: [(info at: 1) = 0]).
check value: 'allocLoop: again' value: (model allocLoop: 3000000) = #(3000000 3000001 3000002).
t := Time millisecondsToRun: [model allocLoop: 3000000].
out nextPutAll: 'allocLoop: 3,000,000 brace arrays: '; print: t; nextPutAll: ' ms'; cr.

"--- 4. Disqualification after 2 deoptimizations ---"
items := (1 to: 1000) asArray collect: [:k | (Smalltalk at: #OilTestItem) new score: k; yourself].
expected := 1000 * 1001 // 2.
check value: 'sumScores: compiles' value: (res value: #sumScores: value: [model sumScores: items]) = 0.
m := (Smalltalk at: #OilTestModel) >> #sumScores:.
check value: 'sumScores: Oil code' value: m oilInfo notNil.
wrong := items copy. wrong at: 500 put: (Smalltalk at: #OilWrongItem) new.
check value: 'sumScores: first deopt correct' value: (model sumScores: wrong) = (expected - 500 + 1000000).
info := m oilInfo.
check value: 'sumScores: after 1 deopt still Oil code' value: (info notNil and: [(info at: 1) = 1]).
check value: 'sumScores: second deopt correct' value: (model sumScores: wrong) = (expected - 500 + 1000000).
check value: 'sumScores: after 2 deopts, the Oil code is freed' value: m oilInfo isNil.
check value: 'sumScores: correct afterwards' value: ((1 to: 5) collect: [:k | model sumScores: wrong]) asSet asArray = {expected - 500 + 1000000}.
check value: 'sumScores: correct on the original items' value: (model sumScores: items) = expected.
check value: 'sumScores: back to baseline machine code, not Oil' value: m oilInfo isNil.
check value: 'sumScores: not compiled again (FailDisqualified = 16)' value: (m oilCompileFor: (Smalltalk at: #OilTestModel)) = 16.

"--- 5. benchmarkHashProbe compiles ---"
before := model benchmarkHashProbe.
out nextPutAll: 'benchmarkHashProbe (baseline): '; print: before; nextPutAll: ' ms'; cr.
check value: 'benchmarkHashProbe compiles (no OilFailBackend)' value: (res value: #benchmarkHashProbe value: [model benchmarkHashProbe]) = 0.
t := (1 to: 3) collect: [:k | model benchmarkHashProbe].
out nextPutAll: 'benchmarkHashProbe (Oil home method, the loop is in the timeToRun block): '; print: t; nextPutAll: ' ms'; cr.
check value: 'benchmarkHashProbe still runs' value: (t allSatisfy: [:e | e isInteger]).

Smalltalk garbageCollect.
check value: 'full GC after all tests' value: (model braceOf: 1 and: 2) = {1. 2. 3. nil}.
out nextPutAll: (failures isEmpty ifTrue: ['ALL PASS'] ifFalse: ['FAILURES: ', failures size printString]); cr.
out close.
