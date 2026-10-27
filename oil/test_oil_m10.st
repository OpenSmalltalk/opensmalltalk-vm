"Oil end-to-end test (native) of Milestone 10: float loop registers.  In an innermost loop without calls, the float
 variables live in XMM registers across iterations (unboxed once when the loop is entered, boxed as SmallFloat64s only at
 its exits and before deoptimizing; their values are checked to fit a SmallFloat64), and the float invariants are unboxed
 once.  Each probe is compiled, checked against the baseline JIT (a copy of the method left to it; deopts included: a
 variable that stops fitting a SmallFloat64, a non-Float entering the loop) and timed.
 Run with run-st.sh on a Squeak 6.x 64-bit image with the Oil VM.  Writes oil-m10-result.txt next to the image."
| out failures check sels setSelectors model cls res last ir opcodes statsOf info times probes irNames |
Utilities authorInitials: 'cb'.
out := FileStream forceNewFileNamed: (FileDirectory default fullNameFor: 'oil-m10-result.txt').
failures := OrderedCollection new.
check := [:name :bool |
	out nextPutAll: (bool == true ifTrue: ['PASS '] ifFalse: ['FAIL ']); nextPutAll: name; cr; flush.
	bool == true ifFalse: [failures add: name]].
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
  'geom: n | s r | s := 1.0. r := 1.0001. 1 to: n do: [:i | s := s * r]. ^s'
  'poly: x n: n | s | s := 0.0. 1 to: n do: [:i | s := s * x + 1.0]. ^s'
  'whileHalve: x | v c | v := x. c := 0. [v > 1.0] whileTrue: [v := v / 2.0. c := c + 1]. ^c'
  'leaky: x | v | v := 0.5. 1 to: 10 do: [:i | v := v * x]. ^v')
	do: [:src | | sel |
		cls compile: src classified: 'tests'.
		sel := (Parser new parseSelector: src) asString.
		#('Base') do: [:suffix |
			cls compile: (sel last = $:
					ifTrue: [(src copyFrom: 1 to: (src indexOf: $:) - 1), suffix, (src copyFrom: (src indexOf: $:) to: src size)]
					ifFalse: [sel, suffix, (src allButFirst: sel size)]) classified: 'tests']].
cls class compile: 'oilSetColdSelectors: anArray <primitive: ''primitiveOilSetColdSelectors''> ^#failed' classified: 'oil'.
cls class compile: 'autonomousCompilation: aBoolean <primitive: ''primitiveOilSetAutonomousCompilation''> ^#failed' classified: 'oil'.
cls class compile: 'disqualifyLimit: anInteger <primitive: ''primitiveOilSetDisqualifyLimit''> ^#failed' classified: 'oil'.
cls class compile: 'oilSetParameter: index to: value
	"(the former primitiveOilSetParameter: 19 autonomous compilation, 8 the disqualify limit; the others are gone)"
	index = 19 ifTrue: [^self autonomousCompilation: value ~= 0].
	index = 8 ifTrue: [^self disqualifyLimit: value].
	^self' classified: 'oil'.
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
sels := OrderedCollection new.
#(value value: value:value: value:value:value: value:value:value:value:) doWithIndex: [:s :i | sels add: i - 1; add: s].
sels add: 5; add: #bitXor:.
#(do: reverseDo: collect: select: reject: detect: detect:ifNone: inject:into: doWithIndex: withIndexDo: timesRepeat: to:do: to:by:do: scanFor: findElementOrNil:)
	do: [:s | sels add: 6; add: s].
#(error: errorNoFreeSpace errorSubscriptBounds: errorNotIndexable subclassResponsibility halt doesNotUnderstand: primitiveFailed makeRoomAtLast makeRoomAtFirst)
	do: [:s | sels add: 7; add: s].
setSelectors := [cls oilSetSelectors: sels asArray].
check value: 'primitiveOilSetSelectors' value: setSelectors value ~~ #failed.
model := cls new.
irNames := #(ConstTagged Const64 Move AddTagged SubTagged AndTagged OrTagged XorTagged ShiftTagged OddTagged LoadField StoreField LoadElement StoreElement CmpTagged BranchTrue BranchFalse Jump Return GuardClass CheckBounds Call0 Call1 CallN AddImmTagged CmpImmTagged LoadSize MakeClosure NewArray CallSuper AddImmTaggedNC ModTagged LoadByteSize LoadByte LoadChar StoreByte StoreChar CompareBytes Trap CharValue StreamNext StreamNextPut AddFloat SubFloat MulFloat DivFloat CmpFloat IdentityHash IndexOfByte SkipSeparators NewObject CmpClass GuardClass2 StringHash).
"stats: {loops with float registers. fully unrolled} of the last compilation"
statsOf := [| st | st := (CompiledMethod oilLastCompilation) at: 11. {st at: 27. st at: 24}].
res := [:sel :warm | | cm r |
	cm := cls >> sel.
	3 timesRepeat: warm.
	r := cm oilCompileFor: cls.
	last := CompiledMethod oilLastCompilation.
	out nextPutAll: sel; nextPutAll: ': oilCompileFor: -> '; print: r; nextPutAll: ' in '; print: (last at: 9); nextPutAll: ' us; float loops, fully unrolled: '; print: statsOf value; cr; flush.
	r].
times := [:block | | best | best := SmallInteger maxVal. 5 timesRepeat: [best := best min: (Time millisecondsToRun: block)]. best].
info := [:sel | (cls >> sel) oilInfo].
"{selector. warm-up arguments. argument lists checked. check of {float loops. full}. benchmark block or nil}"
probes := {
	{#mandelbrot:. {20}. {{0}. {1}. {20}. {100}}. [:st | st first >= 0]. [:sel | model perform: sel with: 400]}.
	{#floatSum:. {100}. {{0}. {1}. {7}. {1000}}. [:st | st first >= 0]. [:sel | 10 timesRepeat: [model perform: sel with: 1000000]]}.
	{#geom:. {100}. {{0}. {10}. {1000}. {10000000}}. [:st | st first >= 0]. [:sel | 1000 timesRepeat: [model perform: sel with: 10000]]}.
	{#poly:n:. {1.0001. 100}. {{1.0001. 10}. {0.5. 1000}. {3. 10}. {2.0. 2000}. {nil. 3}. {2.5. 0}}. [:st | st first >= 0]. [:sel | 10 timesRepeat: [model perform: sel with: 0.999 with: 1000000]]}.
	{#whileHalve:. {1000.0}. {{1000.0}. {0.5}. {1.0e300}. {7}. {1.0e10}}. [:st | st first >= 0]. nil}.
	{#leaky:. {1.5}. {{1.5}. {1.0e30}. {2}. {1.0e-30}}. [:st | true]. nil}}.
probes do: [:spec | | sel baseSel results code st |
	sel := spec first.
	baseSel := ((sel copyFrom: 1 to: (sel indexOf: $:) - 1), 'Base', (sel copyFrom: (sel indexOf: $:) to: sel size)) asSymbol.
	results := (spec at: 3) collect: [:args | [model perform: baseSel withArguments: args] on: Error do: [:e | #error]].
	code := res value: sel value: [model perform: sel withArguments: (spec at: 2)].
	st := statsOf value.
	check value: sel, ' compiles' value: code = 0.
	check value: sel, ' float loop registers as expected' value: ((spec at: 4) value: st).
	(spec at: 5) ifNotNil: [:block | | tf tb |
		Smalltalk garbageCollect.
		tb := times value: [block value: baseSel].
		tf := times value: [block value: sel].
		out nextPutAll: 'BENCH '; nextPutAll: sel; nextPutAll: ' float registers '; print: tf; nextPutAll: ' ms, baseline JIT '; print: tb; nextPutAll: ' ms'; cr; flush.
		check value: sel, ' no deopt while benchmarked' value: ((info value: sel) ifNil: [false] ifNotNil: [:i | (i at: 1) = 0])].
	(spec at: 3) with: results do: [:args :expectedResult |
		check value: sel, ' = baseline for ', (args printString contractTo: 40) value: ([model perform: sel withArguments: args] on: Error do: [:e | #error]) = expectedResult]].
Smalltalk garbageCollect.
check value: 'after a full GC' value: ((model mandelbrot: 50) = (model mandelbrotBase: 50) and: [(model floatSum: 1000) = 1500.0]).
Smalltalk voidCogVMState.
check value: 'voidCogVMState' value: (model mandelbrot: 30) = (model mandelbrotBase: 30).
out nextPutAll: (failures isEmpty ifTrue: ['ALL PASS'] ifFalse: ['FAILURES: ', failures size printString]); cr.
out close.
failures isEmpty ifFalse: [self error: 'Oil M10 test failures: ', failures printString]
