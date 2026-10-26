"Oil end-to-end test (native) of Milestone 9: loop unrolling.  Full unrolling of leaf loops counted by a constant (at most
 OilUnrollMaxTrips iterations, iterations * body <= OilUnrollFullBudget), rotation of the other counted leaf loops (Oil no
 longer unrolls them partially), of loops tested against an immediate or against a limit not known to be a SmallInteger (an
 argument), and stores into young objects (with their store checks: Oil no longer elides them).  Each probe is compiled twice, with
 unrolling (the default) and without (a copy of the method compiled with parameter 12 = 3 of primitiveOilSetParameter), and both are
 checked against the baseline JIT, including deoptimizations inside the unrolled copies, and timed.
 Run with run-st.sh on a Squeak 6.x 64-bit image with the Oil VM.  Writes oil-m9-result.txt next to the image."
| out failures check sels setSelectors model cls res last ir opcodes countOps r t times statsOf info irNames dump
  arr arr1k items expected bench probes noUnroll probeExtra |
Utilities authorInitials: 'cb'.
out := FileStream forceNewFileNamed: (FileDirectory default fullNameFor: 'oil-m9-result.txt').
failures := OrderedCollection new.
check := [:name :bool |
	out nextPutAll: (bool == true ifTrue: ['PASS '] ifFalse: ['FAIL ']); nextPutAll: name; cr; flush.
	bool == true ifFalse: [failures add: name]].
Object subclass: #OilM9Model instanceVariableNames: 'total' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
Object subclass: #OilM9Item instanceVariableNames: 'score' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
(Smalltalk at: #OilM9Item) compile: 'score ^score' classified: 'tests'.
(Smalltalk at: #OilM9Item) compile: 'score: n score := n' classified: 'tests'.
Object subclass: #OilM9A instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
Object subclass: #OilM9B instanceVariableNames: 'y' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
(Smalltalk at: #OilM9A) compile: 'm9Size ^3' classified: 'tests'.
(Smalltalk at: #OilM9B) compile: 'm9Size ^y + y + 1' classified: 'tests'.
(Smalltalk at: #OilM9B) compile: 'y: v y := v' classified: 'tests'.
cls := Smalltalk at: #OilM9Model.
"Each probe three times: sel (unrolled), selRef (compiled without unrolling) and selBase (left to the baseline JIT, for the
 expected results: running sel and selRef on unusual arguments before compiling them would make their sends polymorphic)."
#('sum3: a | s | s := 0. 1 to: 3 do: [:i | s := s + (a at: i)]. ^s'
  'times4: x | s | s := 0. 4 timesRepeat: [s := s + x]. ^s'
  'find3: a 1 to: 3 do: [:i | (a at: i) = 0 ifTrue: [^i]]. ^0'
  'scores3: a | s | s := 0. 1 to: 3 do: [:i | s := s + (a at: i) score]. ^s'
  'sumArr: a | s | s := 0. 1 to: a size do: [:i | s := s + (a at: i)]. ^s'
  'sumN: n | s | s := 0. 1 to: n do: [:i | s := s + i]. ^s'
  'whileSum: n | s i | s := 0. i := 0. [i < n] whileTrue: [s := s + i. i := i + 1]. ^s'
  'sum100 | s | s := 0. 1 to: 100 do: [:i | s := s + i]. ^s'
  'absSum: a | s | s := 0. 1 to: a size do: [:i | | e | e := a at: i. e > 0 ifTrue: [s := s + e] ifFalse: [s := s - e]]. ^s'
  'absSum2: a | s | s := 0. 1 to: a size do: [:i | | e | e := a at: i. e > 0 ifTrue: [s := s + e] ifFalse: [s := s - e]]. ^s'
  'sumScores: a | s | s := 0. 1 to: a size do: [:i | s := s + (a at: i) score]. ^s'
  'pointSum: n | s | s := 0. 1 to: n do: [:i | | p | p := i @ (i + 1). s := s + p x + p y]. ^s'
  'countA: aString | n | n := 0. 1 to: aString size do: [:i | (aString at: i) == $a ifTrue: [n := n + 1]]. ^n'
  'fill: a with: x 1 to: a size do: [:i | a at: i put: x]. ^a'
  'sizeSum: coll | s | s := 0. coll do: [:e | s := s + e m9Size]. ^s'
  'young: x | a | a := {nil. nil. nil}. a at: 2 put: x. ^a'
  'youngLoop: n | s | s := 0. 1 to: n do: [:i | | a | a := {nil. i. nil}. a at: 1 put: i -> i. a at: 3 put: (a at: 1). s := s + (a at: 3) key]. ^s')
	do: [:src | | sel |
		cls compile: src classified: 'tests'.
		sel := (Parser new parseSelector: src) asString.
		#('Ref' 'Base') do: [:suffix |
			cls compile: (sel last = $:
					ifTrue: [(src copyFrom: 1 to: (src indexOf: $:) - 1), suffix, (src copyFrom: (src indexOf: $:) to: src size)]
					ifFalse: [sel, suffix, (src allButFirst: sel size)]) classified: 'tests']].
cls class compile: 'oilSetColdSelectors: anArray <primitive: ''primitiveOilSetColdSelectors''> ^#failed' classified: 'oil'.
cls class compile: 'oilSetParameter: index to: value <primitive: ''primitiveOilSetParameter''> ^#failed' classified: 'oil'.
"(the kind/value pairs of the former primitiveOilSetSelectors: the cold selectors, kind 7, and the parameters, kinds 8 and 12 to 18,
 the others at their default; the value selectors, bitXor: and the iterators are built in; no autonomous compilation)"
cls class compile: 'oilSetSelectors: pairs
	| cold |
	(self oilSetParameter: 19 to: 0) == #failed ifTrue: [^#failed].
	#(8 12 13 14 15 16 17 18) do: [:index | self oilSetParameter: index to: 0].
	cold := OrderedCollection new.
	1 to: pairs size by: 2 do: [:i | | kind value |
		kind := pairs at: i. value := pairs at: i + 1.
		kind = 7 ifTrue: [cold add: value].
		(kind = 8 or: [kind between: 12 and: 18]) ifTrue: [self oilSetParameter: kind to: value]].
	^self oilSetColdSelectors: cold asArray' classified: 'oil'.
CompiledMethod compile: 'oilCompileFor: aClass <primitive: ''primitiveOilCompile''> ^#failed' classified: 'oil'.
CompiledMethod compile: 'oilInfo <primitive: ''primitiveOilMethodInfo''> ^#failed' classified: 'oil'.
CompiledMethod class compile: 'oilLastCompilation <primitive: ''primitiveOilLastCompilation''> ^#failed' classified: 'oil'.
"Tenure the methods just compiled (primitive 138, someObject, flushes new space; a full GC does not tenure): the baseline
 JIT links a send site whose new target method is young to an open PIC, which records no receiver classes, instead of a
 closed PIC (see Cogit>>ceSICMiss:), so sizeSum: would not inline m9Size bimorphically."
cls class compile: 'oilTenureAll <primitive: 138> ^nil' classified: 'oil'.
cls oilTenureAll.
sels := OrderedCollection new.
#(value value: value:value: value:value:value: value:value:value:value:) doWithIndex: [:s :i | sels add: i - 1; add: s].
sels add: 5; add: #bitXor:.
#(do: reverseDo: collect: select: reject: detect: detect:ifNone: inject:into: doWithIndex: withIndexDo: timesRepeat: to:do: to:by:do: scanFor: findElementOrNil:)
	do: [:s | sels add: 6; add: s].
#(error: errorNoFreeSpace errorSubscriptBounds: errorNotIndexable subclassResponsibility halt doesNotUnderstand: primitiveFailed makeRoomAtLast makeRoomAtFirst)
	do: [:s | sels add: 7; add: s].
sels add: 9; add: ByteString class >> #indexOfAscii:inString:startingAt:.
sels add: 10; add: PositionableStream >> #skipSeparators.
sels add: 11; add: ReadStream.
"setSelectors: the selectors, the extra pairs of the probe, plus kind 12 (unrolling mode) 3 (no unrolling) if off"
probeExtra := #().
setSelectors := [:off | cls oilSetSelectors: sels asArray, probeExtra, (off ifTrue: [#(12 3)] ifFalse: [#()])].
check value: 'primitiveOilSetSelectors' value: (setSelectors value: false) ~~ #failed.
model := cls new.
irNames := #(ConstTagged Const64 Move AddTagged SubTagged AndTagged OrTagged XorTagged ShiftTagged OddTagged LoadField StoreField LoadElement StoreElement CmpTagged BranchTrue BranchFalse Jump Return GuardClass CheckBounds Call0 Call1 CallN AddImmTagged CmpImmTagged LoadSize MakeClosure NewArray CallSuper AddImmTaggedNC ModTagged LoadByteSize LoadByte LoadChar StoreByte StoreChar CompareBytes Trap CharValue StreamNext StreamNextPut AddFloat SubFloat MulFloat DivFloat CmpFloat IdentityHash IndexOfByte SkipSeparators NewObject CmpClass GuardClass2 StringHash).
opcodes := [| words i ops op |
	words := (CompiledMethod oilLastCompilation) at: 2.
	ops := OrderedCollection new. i := 1.
	[i <= words size] whileTrue:
		[op := (words at: i) bitShift: -24.
		 ops add: (irNames at: op ifAbsent: [#unknown]).
		 i := i + ((#(2 20 22 23 41 42 48 50 51 52 54) includes: op)
				ifTrue: [3]
				ifFalse: [op = 28 ifTrue: [4] ifFalse: [op = 53 ifTrue: [5] ifFalse: [(#(24 30 49) includes: op) ifTrue: [3 + (((words at: i) bitAnd: 255) + 3 // 4)] ifFalse: [1]]]])].
	ops].
countOps := [:ops :wanted | ops count: [:op | wanted includes: op]].
dump := [| ops | ops := opcodes value. out tab; print: ops asArray; cr; flush].
"stats: {fully unrolled. partially unrolled. young stores without store check. rotated} of the last compilation (the
 second and third are 0: Oil does neither any more)"
statsOf := [| st | st := (CompiledMethod oilLastCompilation) at: 11. {st at: 24. st at: 25. st at: 26. st at: 1}].
"compile: warm up (baseline JIT), Oil-compile (without unrolling if noUnroll), answer the result code"
res := [:sel :warm :off | | cm |
	cm := cls >> sel.
	3 timesRepeat: warm.
	setSelectors value: off.
	r := cm oilCompileFor: cls.
	setSelectors value: false.
	last := CompiledMethod oilLastCompilation.
	ir := opcodes value.
	out nextPutAll: sel; nextPutAll: ': oilCompileFor: -> '; print: r; nextPutAll: ' in '; print: (last at: 9); nextPutAll: ' us, '; print: ir size; nextPutAll: ' IR instructions; fully, partially unrolled, young stores, rotated: '; print: statsOf value; cr; flush.
	r].
times := [:block | | best | best := SmallInteger maxVal. 5 timesRepeat: [best := best min: (Time millisecondsToRun: block)]. best].
info := [:sel | (cls >> sel) oilInfo].
arr := (1 to: 1000000) asArray.
arr1k := (1 to: 1000) collect: [:k | k odd ifTrue: [k] ifFalse: [k negated]].
items := (1 to: 1000) collect: [:k | (Smalltalk at: #OilM9Item) new score: k; yourself].

"--- Probes: {selector. arguments for warming up. argument lists checked (results and deopts). check of the statistics {full. partial. young. rotated}. benchmark block (or nil). [extra selector pairs, e.g. #(12 8): unroll bodies with branches too]} ---"
probes := {
	{#sum3:. {#(1 2 3)}. {{#(1 2 3)}. {#(4 5 6 7)}. {#(1 2)}. {{1. 2. nil}}. {{1. SmallInteger maxVal. 1}}}. [:st | st first = 1]. [:sel | 3000000 timesRepeat: [model perform: sel with: #(1 2 3)]]}.
	{#times4:. {5}. {{5}. {-3}. {SmallInteger maxVal}. {2.5}}. [:st | st first = 1]. [:sel | 3000000 timesRepeat: [model perform: sel with: 7]]}.
	{#find3:. {#(1 0 3)}. {{#(1 0 3)}. {#(1 2 3)}. {#(0)}}. [:st | st first = 1]. nil}.
	{#scores3:. {items}. {{items}. {items reverse}. {{items first. 3. items last}}}. [:st | st first = 1]. [:sel | 3000000 timesRepeat: [model perform: sel with: items]]}.
	{#sumArr:. {arr1k}. {{arr}. {#()}. {#(1)}. {#(1 2)}. {#(1 2 3)}. {#(1 2 3 4 5)}. {#(1 2 nil 4 5 6 7 8 9)}. {{1. 2. 3. 4. 5. 6. SmallInteger maxVal. 8}}}. [:st | (st at: 2) = 0 and: [(st at: 4) >= 1]]. [:sel | 20 timesRepeat: [model perform: sel with: arr]]}.
	{#sumN:. {100}. {{0}. {1}. {2}. {3}. {4}. {5}. {10000001}. {-3}. {2.5}. {nil}}. [:st | (st at: 2) = 0 and: [(st at: 4) >= 1]]. [:sel | 10 timesRepeat: [model perform: sel with: 10000000]]}.
	{#whileSum:. {100}. {{0}. {1}. {3}. {5}. {1000001}. {2.5}}. [:st | (st at: 2) = 0 and: [(st at: 4) >= 1]]. [:sel | 10 timesRepeat: [model perform: sel with: 10000000]]}.
	{#sum100. {}. {{}}. [:st | (st at: 2) = 0 and: [(st at: 4) >= 1]]. [:sel | 300000 timesRepeat: [model perform: sel]]}.
	{#absSum:. {arr1k}. {{arr1k}. {#()}. {#(-1 2 -3)}. {#(1 2 3.5 4)}}. [:st | (st at: 2) = 0 and: [(st at: 4) >= 1]]. [:sel | 30000 timesRepeat: [model perform: sel with: arr1k]]. #(12 8)}.
	{#absSum2:. {arr1k}. {{arr1k}. {#(-1 2 -3)}}. [:st | (st at: 2) = 0]. nil}.
	{#sumScores:. {items}. {{items}. {items first: 3}. {items copyWith: 3}}. [:st | (st at: 2) = 0 and: [(st at: 4) >= 1]]. [:sel | 30000 timesRepeat: [model perform: sel with: items]]}.
	{#pointSum:. {100}. {{0}. {1}. {7}. {1000}}. [:st | (st at: 2) = 0 and: [(st at: 4) >= 1]]. [:sel | 10 timesRepeat: [model perform: sel with: 1000000]]}.
	{#countA:. {'banana'}. {{'banana'}. {''}. {'aaaaaaaaa'}. {(String new: 100000 withAll: $a)}}. [:st | (st at: 2) = 0 and: [(st at: 4) >= 1]]. [:sel | 20 timesRepeat: [model perform: sel with: (String new: 1000000 withAll: $a)]]. #(12 8)}.
	{#fill:with:. {Array new: 10. 3}. {{Array new: 0. 3}. {Array new: 7. 'x'}. {Array new: 100000. 3 @ 4}. {#(1 2 3) beReadOnlyObject; yourself. 9}}. [:st | (st at: 2) = 0 and: [(st at: 4) >= 1]]. [:sel | 20 timesRepeat: [model perform: sel with: (Array new: 1000000) with: 'x']]}.
	{#sizeSum:. {{(Smalltalk at: #OilM9A) new. (Smalltalk at: #OilM9B) new y: 2; yourself}}. {{(1 to: 1001) collect: [:k | k odd ifTrue: [(Smalltalk at: #OilM9A) new] ifFalse: [(Smalltalk at: #OilM9B) new y: k; yourself]]}. {{(Smalltalk at: #OilM9A) new. 3. (Smalltalk at: #OilM9A) new}}}. [:st | (st at: 2) = 0 and: [(st at: 4) >= 1]]. nil. #(12 8)}.
	{#young:. {3}. {{3}. {'x'}. {#foo}}. [:st | (st at: 3) = 0]. nil}.
	{#youngLoop:. {10}. {{0}. {1}. {10}. {300000}}. [:st | (st at: 3) = 0]. [:sel | 10 timesRepeat: [model perform: sel with: 100000]]}}.
probes do: [:spec | | sel refSel baseSel results codes st |
	sel := spec first.
	probeExtra := spec size >= 6 ifTrue: [spec at: 6] ifFalse: [#()].
	refSel := sel last = $: ifTrue: [((sel copyFrom: 1 to: (sel indexOf: $:) - 1), 'Ref', (sel copyFrom: (sel indexOf: $:) to: sel size)) asSymbol] ifFalse: [(sel, 'Ref') asSymbol].
	baseSel := sel last = $: ifTrue: [((sel copyFrom: 1 to: (sel indexOf: $:) - 1), 'Base', (sel copyFrom: (sel indexOf: $:) to: sel size)) asSymbol] ifFalse: [(sel, 'Base') asSymbol].
	results := (spec at: 3) collect: [:args | [model perform: baseSel withArguments: (args collect: [:a | a copy])] on: Error do: [:e | #error]].
	codes := OrderedCollection new.
	codes add: (res value: sel value: [model perform: sel withArguments: (spec at: 2)] value: false).
	st := statsOf value.
	dump value.
	codes add: (res value: refSel value: [model perform: refSel withArguments: (spec at: 2)] value: true).
	dump value.
	check value: sel, ' compiles, with and without unrolling' value: codes asArray = #(0 0).
	check value: sel, ' unrolled as expected' value: ((spec at: 4) value: st).
	"benchmark first: the deopts of the checks below may disqualify the Oil code"
	(spec at: 5) ifNotNil: [:block | | tu tr |
		Smalltalk garbageCollect.
		tr := times value: [block value: refSel].
		tu := times value: [block value: sel].
		out nextPutAll: 'BENCH '; nextPutAll: sel; nextPutAll: ' unrolled '; print: tu; nextPutAll: ' ms, not unrolled '; print: tr; nextPutAll: ' ms'; cr; flush.
		check value: sel, ' no deopt while benchmarked' value: ((info value: sel) ifNil: [false] ifNotNil: [:i | (i at: 1) = 0])].
	(spec at: 3) with: results do: [:args :expectedResult |
		check value: sel, ' = baseline for ', (args printString contractTo: 40) value: ([model perform: sel withArguments: (args collect: [:a | a copy])] on: Error do: [:e | #error]) = expectedResult.
		check value: refSel, ' = baseline for ', (args printString contractTo: 40) value: ([model perform: refSel withArguments: (args collect: [:a | a copy])] on: Error do: [:e | #error]) = expectedResult]].

"--- Young stores survive scavenges and full GCs (results after GCs) ---"
Smalltalk garbageCollect.
check value: 'youngLoop: after a full GC' value: (model youngLoop: 100000) = (100000 * 100001 // 2).
check value: 'young: contents' value: ((1 to: 1000) allSatisfy: [:k | (model young: k) = {nil. k. nil}]).
Smalltalk voidCogVMState.
check value: 'voidCogVMState: results' value: ((model sumArr: arr1k) = (arr1k inject: 0 into: [:a :b | a + b]) and: [(model sum3: #(1 2 3)) = 6]).
out nextPutAll: (failures isEmpty ifTrue: ['ALL PASS'] ifFalse: ['FAILURES: ', failures size printString]); cr.
out close.
failures isEmpty ifFalse: [self error: 'Oil M9 test failures: ', failures printString]
