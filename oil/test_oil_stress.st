"Oil full-system stress (native): run SUnit with the trip log on, Oil-compile every hot (tripped) home method, run SUnit
 again on the Oil code, then Compiler recompileAll (which flushes every selector: the Oil code that inlined them is
 discarded, see ProfilingCogit>>unlinkSendsOf:isMNUSelector:) and SUnit once more.  Writes oil-stress-result.txt."
| out sels classes runSuites log methods results compiled failedCompiles t |
Utilities authorInitials: 'cb'.
out := FileStream forceNewFileNamed: (FileDirectory default fullNameFor: 'oil-stress-result.txt').
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
classes := #(#BlockClosureTest #FullBlockClosureTest #ContextTest #OrderedCollectionTest #ArrayTest #IntervalTest #DictionaryTest #SetTest #IntegerTest #SmallIntegerTest #LargePositiveIntegerTest #FloatTest #StringTest #SymbolTest #BagTest #SortedCollectionTest #ExceptionTests #ProcessTest #WeakSetTest #CompiledMethodTest #ClassTest #BehaviorTest #MethodContextTest #BlockLocalTempCounterTest #CompilerTest).
runSuites := [:label | | total failed |
	total := failed := 0.
	classes do: [:name |
		(Smalltalk at: name ifAbsent: [nil]) ifNotNil: [:cls | | r |
			r := cls suite run.
			total := total + r runCount.
			failed := failed + r failureCount + r errorCount.
			(r failures, r errors) do: [:tc | out tab; nextPutAll: label; space; print: tc; cr; flush]]].
	out nextPutAll: label; nextPutAll: ': SUnit run '; print: total; nextPutAll: ' failed+errors '; print: failed; cr; flush.
	failed].
"1. SUnit with the trip log on"
log := Array new: 65535. log at: 1 put: 0.
(Smalltalk at: #OilStress) oilTripLog: log.
results := OrderedCollection new.
results add: (runSuites value: 'baseline').
(Smalltalk at: #OilStress) oilTripLog: nil.
"2. Oil-compile the tripped home methods"
methods := IdentitySet new.
0 to: (log at: 1) - 1 do: [:k | | m |
	m := log at: (k \\ 256) * 6 + 2 + 2.
	(m isCompiledMethod and: [m methodClass notNil]) ifTrue: [methods add: m]].
compiled := 0. failedCompiles := Bag new.
t := Time millisecondsToRun: [methods do: [:m | | r |
	r := m oilCompileFor: m methodClass.
	r = 0 ifTrue: [compiled := compiled + 1] ifFalse: [failedCompiles add: r]]].
out nextPutAll: 'trips '; print: (log at: 1); nextPutAll: ', hot methods '; print: methods size; nextPutAll: ', Oil-compiled '; print: compiled;
	nextPutAll: ' in '; print: t; nextPutAll: ' ms, failure codes '; print: failedCompiles sortedCounts; cr; flush.
"3. SUnit on the Oil code"
results add: (runSuites value: 'oil').
out nextPutAll: 'Oil methods still installed: '; print: (methods count: [:m | m oilInfo notNil]); cr; flush.
"4. Compiler recompileAll, then SUnit"
t := Time millisecondsToRun: [Compiler recompileAll].
out nextPutAll: 'Compiler recompileAll: '; print: t; nextPutAll: ' ms; Oil methods left: '; print: (methods count: [:m | m oilInfo notNil]); cr; flush.
results add: (runSuites value: 'after recompileAll').
Smalltalk garbageCollect.
out nextPutAll: (results asSet = (Set with: 0) ifTrue: ['ALL PASS'] ifFalse: ['FAILURES ', results asArray printString]); cr.
out close
