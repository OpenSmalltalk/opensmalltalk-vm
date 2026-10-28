"Oil full-system stress (native): run SUnit on the baseline code, then with autonomous compilation on (the trip counters
 compile every hot home method with Oil and install its code, see CoInterpreter>>oilAutoCompile:receiver:), again on the
 Oil code, then Compiler recompileAll (which flushes every selector: the Oil code that inlined them is
 discarded, see ProfilingCogit>>unlinkSendsOf:isMNUSelector:) and SUnit once more.  Writes oil-stress-result.txt."
| out sels classes runSuites log methods results compiled failedCompiles t |
Utilities authorInitials: 'cb'.
out := FileStream forceNewFileNamed: (FileDirectory default fullNameFor: 'oil-stress-result.txt').
Object subclass: #OilStress instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
(Smalltalk at: #OilStress) class compile: 'oilSetParameter: index to: value <primitive: ''primitiveOilGetOrSetParameter''> ^#failed' classified: 'oil'.
(Smalltalk at: #OilStress) class compile: 'autonomousCompilation: aBoolean ^self oilSetParameter: 19 to: aBoolean' classified: 'oil'.
(Smalltalk at: #OilStress) class compile: 'disqualifyLimit: anInteger ^self oilSetParameter: 8 to: anInteger' classified: 'oil'.
(Smalltalk at: #OilStress) class compile: 'oilSetColdSelectors: anArray ^self oilSetParameter: 7 to: anArray' classified: 'oil'.
"(the kind/value pairs of the former primitiveOilSetSelectors: the cold selectors, kind 7, and the parameters, kinds 8 and 12 to 18,
 the others at their default; the value selectors, bitXor: and the iterators are built in; no autonomous compilation)"
(Smalltalk at: #OilStress) class compile: 'oilSetSelectors: pairs
	| cold |
	(self oilSetParameter: 19 to: 0) == #failed ifTrue: [^#failed].
	#(8 12 13 14 15 16 17 18) do: [:index | self oilSetParameter: index to: 0].
	cold := OrderedCollection new.
	1 to: pairs size by: 2 do: [:i | | kind value |
		kind := pairs at: i. value := pairs at: i + 1.
		kind = 7 ifTrue: [cold add: value].
		(kind = 8 or: [kind between: 12 and: 18]) ifTrue: [self oilSetParameter: kind to: value]].
	^self oilSetColdSelectors: cold asArray' classified: 'oil'.
CompiledMethod compile: 'oilSpecializeFor: aClass <primitive: ''primitiveOilSpecialize''> ^#failed' classified: 'oil'.
CompiledMethod compile: 'oilCompileFor: aClass ^self oilSpecializeFor: aClass' classified: 'oil'.
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
"1. SUnit on the baseline code"
results := OrderedCollection new.
results add: (runSuites value: 'baseline').
"2. SUnit with autonomous compilation on: the trips compile the hot home methods"
(Smalltalk at: #OilStress) oilSetParameter: 19 to: 1.
t := Time millisecondsToRun: [results add: (runSuites value: 'compiling')].
methods := CompiledMethod allInstances select: [:m | m oilInfo notNil].
out nextPutAll: 'autonomous compilation: Oil methods installed '; print: methods size; nextPutAll: ' (SUnit '; print: t; nextPutAll: ' ms)'; cr; flush.
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
