"Oil long stress run (native), for the inlined selector invalidation table: for OilStressMinutes (default 120) minutes,
 repeat rounds of: SUnit (a random half of the suites) with the trip log on; Oil-compile the hot (tripped) home methods;
 SUnit again on the Oil code; then a random perturbation: Compiler recompileAll, flushing random selectors (Symbol>>flushCache,
 ProfilingCogit>>unlinkSendsOf:isMNUSelector:), recompiling the classes of random Oil methods (new CompiledMethods for the
 inlined selectors), or a full GC.  A test failure that the baseline run does not have is rerun at once (flaky or not) and
 reported.  Writes oil-stress-long-result.txt (one line per round, flushed) next to the image."
| out sels classes runSuites log methods compiled failedCompiles t0 deadline rng round baselineFailures newFailures
  persistent minutes collectFailures actions oilInstalled allMethods flushed |
Utilities authorInitials: 'cb'.
minutes := Smalltalk at: #OilStressMinutes ifAbsent: [120].
out := FileStream forceNewFileNamed: (FileDirectory default fullNameFor: 'oil-stress-long-result.txt').
Object subclass: #OilStress instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
(Smalltalk at: #OilStress) class compile: 'oilSetSelectors: anArray <primitive: ''primitiveOilSetSelectors''> ^#failed' classified: 'oil'.
(Smalltalk at: #OilStress) class compile: 'oilTripLog: anArray <primitive: ''primitiveOilTripLog''> ^#failed' classified: 'oil'.
CompiledMethod compile: 'oilCompileFor: aClass <primitive: ''primitiveOilCompile''> ^#failed' classified: 'oil'.
CompiledMethod compile: 'oilInfo <primitive: ''primitiveOilMethodInfo''> ^#failed' classified: 'oil'.
sels := OrderedCollection new.
#(value value: value:value: value:value:value: value:value:value:value:) doWithIndex: [:s :i | sels add: i - 1; add: s].
sels add: 5; add: #bitXor:.
#(do: reverseDo: collect: select: reject: detect: detect:ifNone: detect:ifFound:ifNone: inject:into: do:separatedBy: doWithIndex: withIndexDo: keysAndValuesDo: timesRepeat: to:do: to:by:do: scanFor: findElementOrNil: with:do: allSatisfy: anySatisfy: noneSatisfy: count: detectMax: detectMin:)
	do: [:s | sels add: 6; add: s].
#(error: errorNoFreeSpace errorNotFound: errorSubscriptBounds: errorNoSuchElement errorEmptyCollection errorKeyNotFound: errorKeyNotFound errorImproperStore errorNonIntegerIndex errorNotIndexable subclassResponsibility shouldNotImplement notYetImplemented halt halt: deprecated: deprecated signal signal: doesNotUnderstand: cannotReturn: primitiveFailed primitiveFailed:)
	do: [:s | sels add: 7; add: s].
(Smalltalk at: #OilStress) oilSetSelectors: sels asArray.
classes := (#(#BlockClosureTest #FullBlockClosureTest #ContextTest #OrderedCollectionTest #ArrayTest #IntervalTest #DictionaryTest #SetTest #IntegerTest #SmallIntegerTest #LargePositiveIntegerTest #FloatTest #StringTest #SymbolTest #BagTest #SortedCollectionTest #ExceptionTests #WeakSetTest #CompiledMethodTest #ClassTest #BehaviorTest #BlockLocalTempCounterTest #CompilerTest #CharacterTest #ByteArrayTest #FractionTest #NumberTest #LinkedListTest #HeapTest #AssociationTest #IdentitySetTest #ReadStreamTest #WriteStreamTest #ReadWriteStreamTest #DateTest #TimeTest #DurationTest)
	collect: [:name | Smalltalk at: name ifAbsent: [nil]]) select: [:cls | cls notNil].
"the failures (class>>selector strings) of running the suites of someClasses"
collectFailures := [:someClasses | | failures |
	failures := Set new.
	someClasses do: [:cls | | r |
		r := [cls suite run] on: Error do: [:e | nil].
		r isNil
			ifTrue: [failures add: cls name, '>>(suite error)']
			ifFalse: [(r failures, r errors) do: [:tc | failures add: cls name, '>>', tc selector]]].
	failures].
rng := Random seed: 4242.
t0 := Time millisecondClockValue.
deadline := t0 + (minutes * 60000).
"0. the baseline failures, twice (a failure in either is flaky or expected)"
baselineFailures := (collectFailures value: classes), (collectFailures value: classes).
out nextPutAll: 'classes '; print: classes size; nextPutAll: ', baseline failures '; print: baselineFailures size; nextPutAll: ' '; print: baselineFailures asSortedCollection asArray; cr; flush.
newFailures := Bag new. persistent := Set new.
allMethods := IdentitySet new.
actions := Bag new.
round := 0.
[Time millisecondClockValue < deadline] whileTrue:
	[| subset action failures detail |
	round := round + 1.
	subset := classes select: [:cls | rng next < 0.5].
	subset isEmpty ifTrue: [subset := {classes atRandom: rng}].
	"1. SUnit with the trip log on"
	log := Array new: 65535. log at: 1 put: 0.
	(Smalltalk at: #OilStress) oilTripLog: log.
	collectFailures value: subset.
	(Smalltalk at: #OilStress) oilTripLog: nil.
	"2. Oil-compile the tripped home methods (not running Oil code already)"
	methods := IdentitySet new.
	0 to: ((log at: 1) min: 256) - 1 do: [:k | | m |
		m := log at: k * 6 + 2 + 2.
		(m isCompiledMethod and: [m methodClass notNil and: [m oilInfo isNil]]) ifTrue: [methods add: m]].
	compiled := 0. failedCompiles := 0.
	methods do: [:m | | r |
		r := m oilCompileFor: m methodClass.
		r = 0 ifTrue: [compiled := compiled + 1. allMethods add: m] ifFalse: [failedCompiles := failedCompiles + 1]].
	allMethods := allMethods select: [:m | m oilInfo notNil].
	oilInstalled := allMethods size.
	"3. SUnit on the Oil code; rerun the new failures (flaky or not)"
	failures := (collectFailures value: subset) reject: [:f | baselineFailures includes: f].
	failures do: [:f | | cls sel r |
		newFailures add: f.
		cls := Smalltalk at: (f copyUpTo: $>) asSymbol.
		sel := (f copyAfterLast: $>) asSymbol.
		r := (sel first = $( or: [(cls includesSelector: sel) not and: [(cls canUnderstand: sel) not]])
			ifTrue: [nil]
			ifFalse: [[(cls selector: sel) run] on: Error do: [:e | nil]].
		(r isNil or: [r hasPassed not]) ifTrue: [persistent add: f]].
	"4. a perturbation"
	action := rng nextInt: 10.
	detail := ''.
	action = 1 ifTrue:
		[actions add: #recompileAll.
		 detail := 'recompileAll ', (Time millisecondsToRun: [Compiler recompileAll]) printString, ' ms'].
	(action between: 2 and: 5) ifTrue:
		["flush the selectors sent by random Oil methods, and random symbols"
		 actions add: #flush.
		 flushed := 0.
		 (allMethods asArray copyFrom: 1 to: (allMethods size min: 8)) do: [:m |
			m messages do: [:s | s flushCache. flushed := flushed + 1]].
		 20 timesRepeat: [(Symbol allSymbols atRandom: rng) flushCache. flushed := flushed + 1].
		 detail := 'flushed ', flushed printString, ' selectors'].
	(action between: 6 and: 8) ifTrue:
		["recompile the classes of random Oil methods: new CompiledMethods for the selectors Oil inlined"
		 actions add: #recompileClasses.
		 detail := 'recompiled'.
		 (allMethods asArray copyFrom: 1 to: (allMethods size min: 3)) do: [:m | | cls |
			cls := m methodClass.
			cls compileAll.
			detail := detail, ' ', cls name]].
	action = 9 ifTrue: [actions add: #gc. Smalltalk garbageCollect. detail := 'full GC'].
	action = 10 ifTrue: [actions add: #none].
	out nextPutAll: 'round '; print: round; nextPutAll: ' at '; print: (Time millisecondClockValue - t0) // 1000; nextPutAll: ' s: suites ';
		print: subset size; nextPutAll: ', trips '; print: (log at: 1); nextPutAll: ', compiled '; print: compiled; nextPutAll: ' (failed ';
		print: failedCompiles; nextPutAll: '), Oil methods installed '; print: oilInstalled; nextPutAll: ' -> ';
		print: (allMethods count: [:m | m oilInfo notNil]); nextPutAll: ', new failures '; print: failures asSortedCollection asArray;
		nextPutAll: '; '; nextPutAll: detail; cr; flush].
out nextPutAll: 'rounds '; print: round; nextPutAll: ', actions '; print: actions sortedCounts asArray; cr.
out nextPutAll: 'new failures (count) '; print: newFailures sortedCounts asArray; cr.
out nextPutAll: 'failing again when rerun '; print: persistent asSortedCollection asArray; cr.
"a final check: the suites with all the Oil code there is"
out nextPutAll: 'final new failures '; print: (((collectFailures value: classes) reject: [:f | baselineFailures includes: f]) asSortedCollection asArray); cr.
out nextPutAll: (persistent isEmpty ifTrue: ['STRESS OK'] ifFalse: ['STRESS FAILURES']); cr.
out close
