"Oil stress test (native) of the multi-specialization Dispatcher (oil-m7-specialization.st): a method specialized for up to
 OilMaxSpecialization receiver classes, whose Dispatcher must always route each receiver to its own specialization or to the
 baseline code, through
 - machine-code sends, perform:, and the interpreter's activation of a cogged method (withArgs:executeMethod:);
 - machine-code zone compactions with live Dispatchers (relocation of the Dispatcher's case jumps and its baseline jump, and
   freeOlderMethodsForCompaction, which keeps or frees a Dispatcher with all its targets);
 - invalidation of single specializations (an inlined selector redefined: the Dispatcher is compacted) and of all of them
   (the Dispatcher is torn down and the method's header restored to its baseline code);
 - a class reshape (the specialization's class tag becomes a forwarded class index);
 - recompilation of the method, full GCs, and autonomous compilation (trip counters) for all classes.
 Each receiver class answers a different weight, which the specializations inline, so a receiver run by the wrong
 specialization computes a wrong sum.  Writes oil-dispatcher-stress-result.txt next to the image.  Rounds: OilStressRounds
 (default 6).  Author: cb."
| out failures check base classes objs items expect checkAll compactions fillers fill rounds specialize
  specCount t0 rng codeZone reshaped |
Utilities authorInitials: 'cb'.
out := FileStream forceNewFileNamed: (FileDirectory default fullNameFor: 'oil-dispatcher-stress-result.txt').
failures := OrderedCollection new.
check := [:name :bool |
	out nextPutAll: (bool == true ifTrue: ['PASS '] ifFalse: ['FAIL ']); nextPutAll: name; cr; flush.
	bool == true ifFalse: [failures add: name]].
rounds := Smalltalk at: #OilStressRounds ifAbsent: [6].
rng := Random seed: 4711.
CompiledMethod compile: 'oilSpecializeFor: aClass <primitive: ''primitiveOilSpecialize''> ^#failed' classified: 'oil'.
(CompiledMethod includesSelector: #oilMetadata) ifFalse:
	[CompiledMethod compile: 'oilMetadata <primitive: ''primitiveOilMetadata''> ^nil' classified: 'oil'].
CompiledMethod compile: 'oilSpecializations
	| meta res |
	meta := self oilMetadata.
	meta ifNil: [^#()].
	res := Array new: meta size * 2.
	1 to: meta size do: [:i |
		res at: i * 2 - 1 put: (meta at: i) first.
		res at: i * 2 put: self].
	^res' classified: 'oil'.
CompiledMethod compile: 'oilInfo <primitive: ''primitiveOilMethodInfo''> ^#failed' classified: 'oil'.
Object subclass: #OilDispatcherStressBase instanceVariableNames: 'items bias' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
base := Smalltalk at: #OilDispatcherStressBase.
base class compile: 'oilSetParameter: index to: value <primitive: ''primitiveOilGetOrSetParameter''> ^#failed' classified: 'oil'.
base class compile: 'autonomousCompilation: aBoolean ^self oilSetParameter: 19 to: aBoolean' classified: 'oil'.
base compile: 'items: anArray bias: n items := anArray. bias := n' classified: 'tests'.
base compile: 'weight ^1' classified: 'tests'.
base compile: 'sum | s | s := 0. 1 to: items size do: [:i | s := s + ((items at: i) * self weight) + bias]. ^s' classified: 'tests'.
classes := (1 to: 7) collect: [:j |
	base subclass: ('OilDispatcherStress', j printString) asSymbol instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'].
classes doWithIndex: [:c :j | c compile: 'weight ^', (j * 10) printString classified: 'tests'].
items := (1 to: 2000) asArray.
objs := classes collectWithIndex: [:c :j | c new items: items bias: j].
"the expected sum of objs at: j, given the weight its class answers"
expect := [:j | | w | w := (objs at: j) weight. 2001000 * w + (2000 * j)].
check value: 'primitives available' value: ((base autonomousCompilation: false) ~~ #failed and: [(base >> #sum) oilSpecializations ~~ #failed]).
"all the ways to run sum for every receiver, compared with the expected sums"
checkAll := [:label | | ok |
	ok := (1 to: objs size) allSatisfy: [:j | | o e |
		o := objs at: j. e := expect value: j.
		o sum = e
			and: [(o perform: #sum) = e
			and: [(o withArgs: #() executeMethod: base >> #sum) = e
			and: [((1 to: 3) inject: 0 into: [:acc :k | acc + o sum]) = (3 * e)]]]].
	check value: label value: ok].
specCount := [(base >> #sum) oilSpecializations size // 2].
specialize := [:js | (js collect: [:j | (base >> #sum) oilSpecializeFor: (classes at: j)]) asArray].
compactions := [Smalltalk vmParameterAt: 62].
codeZone := Smalltalk vmParameterAt: 46.
out nextPutAll: 'machine code zone: '; print: codeZone; nextPutAll: ' bytes'; cr; flush.
"fill the machine code zone with distinct jitted methods to force code compactions"
fillers := 0.
Object subclass: #OilDispatcherStressFiller instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
fill := [:n | | filler c0 |
	filler := Smalltalk at: #OilDispatcherStressFiller.
	c0 := compactions value.
	1 to: n do: [:i | | sel |
		fillers := fillers + 1.
		sel := ('f', fillers printString) asSymbol.
		filler compile: sel, ' | a | a := ', fillers printString, '. 1 to: 3 do: [:j | a := a + (j * ', (fillers \\ 97) printString, ')]. ^a' classified: 'fill'.
		2 timesRepeat: [filler new perform: sel].
		i \\ 500 = 0 ifTrue: [(objs at: i // 500 \\ objs size + 1) sum]].
	compactions value - c0].

"1. five specializations, the sixth and seventh class run the baseline code"
objs do: [:o | 3 timesRepeat: [o sum]].
check value: 'specialize sum for classes 1-5' value: (specialize value: (1 to: 5)) = #(0 0 0 0 0).
check value: 'the sixth specialization is refused (OilFailSpecialization)' value: ((base >> #sum) oilSpecializeFor: (classes at: 6)) = 17.
check value: '5 specializations with Oil code' value: (specCount value = 5 and: [((base >> #sum) oilSpecializations pairsCollect: [:c :m | m oilInfo notNil]) allSatisfy: [:b | b]]).
checkAll value: 'results: sends, perform:, interpreter activation (withArgs:executeMethod:)'.

"2. rounds of: code compactions, invalidation of some specializations, re-specialization, GC"
1 to: rounds do: [:r | | c js redefined n specialized |
	t0 := Time millisecondClockValue.
	c := fill value: 3000.
	checkAll value: 'round ', r printString, ': results after filling the code zone (', c printString, ' compactions)'.
	"invalidate the specializations of a random subset of the classes: redefine their (inlined) weight"
	specialized := ((base >> #sum) oilSpecializations pairsCollect: [:cls :m | classes indexOf: cls]) asSet.
	redefined := (1 to: 5) select: [:j | (rng nextInt: 2) = 1].
	redefined do: [:j | (classes at: j) compile: 'weight ^', (j * 10 + r) printString classified: 'tests'].
	checkAll value: 'round ', r printString, ': results after redefining weight in classes ', redefined asArray printString.
	n := specCount value.
	check value: 'round ', r printString, ': the redefined classes lost their specializations (', n printString, ' left)'
		value: n <= (specialized reject: [:j | redefined includes: j]) size.
	objs do: [:o | 2 timesRepeat: [o sum]].
	js := (1 to: 7) asOrderedCollection.
	[js size > 5] whileTrue: [js removeAt: (rng nextInt: js size)].
	js := js asArray.
	(specialize value: js) do: [:res | res = 17 ifFalse: [res = 0 ifFalse: [out nextPutAll: '  oilSpecializeFor: answered '; print: res; cr]]].
	checkAll value: 'round ', r printString, ': results after specializing for classes ', js printString, ' (', specCount value printString, ' specializations)'.
	Smalltalk garbageCollect.
	checkAll value: 'round ', r printString, ': results after a full GC'.
	out nextPutAll: '  round '; print: r; nextPutAll: ': '; print: Time millisecondClockValue - t0; nextPutAll: ' ms'; cr; flush].

"3. all specializations invalidated: the Dispatcher is torn down, the header goes back to the baseline code"
objs do: [:o | 3 timesRepeat: [o sum]].
specialize value: (1 to: 5).
classes doWithIndex: [:c :j | c compile: 'weight ^', (j * 1000) printString classified: 'tests'].
check value: 'all weights redefined: no specialization left' value: specCount value = 0.
checkAll value: 'results after the teardown of the Dispatcher'.
check value: 'the method has baseline machine code again (no Oil code)' value: (base >> #sum) oilInfo isNil.
objs do: [:o | 3 timesRepeat: [o sum]].
check value: 're-specialize after the teardown' value: (specialize value: (1 to: 5)) = #(0 0 0 0 0).
checkAll value: 'results after re-specializing'.

"4. a class reshape: the specialization's class tag becomes a forwarded class index"
(classes at: 3) addInstVarName: 'extra'.
reshaped := (Smalltalk at: #OilDispatcherStress3).
classes at: 3 put: reshaped.
check value: 'instance migrated to the reshaped class' value: (objs at: 3) class == reshaped.
checkAll value: 'results after reshaping class 3'.
Smalltalk garbageCollect.
fill value: 2000.
checkAll value: 'results after reshape + GC + code compaction'.
objs do: [:o | 3 timesRepeat: [o sum]].
specialize value: (1 to: 5).
checkAll value: 'results after specializing the reshaped class'.

"5. the method recompiled (a new CompiledMethod; the old one's machine code and Dispatcher are discarded)"
base compile: 'sum | s | s := 0. 1 to: items size do: [:i | s := s + ((items at: i) * self weight) + bias]. ^s' classified: 'tests'.
check value: 'recompiled sum has no specialization' value: specCount value = 0.
checkAll value: 'results after recompiling sum'.

"6. autonomous compilation: the trip counters specialize sum for the hot classes, then compactions"
base autonomousCompilation: true.
objs do: [:o | 20 timesRepeat: [o sum]].
out nextPutAll: 'autonomous compilation: '; print: specCount value; nextPutAll: ' specializations'; cr; flush.
check value: 'autonomous compilation specialized sum (1 to 5 specializations)' value: (specCount value between: 1 and: 5).
checkAll value: 'results with autonomous specializations'.
fill value: 3000.
objs do: [:o | 20 timesRepeat: [o sum]].
checkAll value: 'results with autonomous specializations after code compaction'.
base autonomousCompilation: false.
Smalltalk garbageCollect.
Smalltalk voidCogVMState.
checkAll value: 'results after voidCogVMState'.
out nextPutAll: 'code compactions: '; print: compactions value; nextPutAll: ', filler methods: '; print: fillers; cr.
out nextPutAll: (failures isEmpty ifTrue: ['ALL PASS'] ifFalse: ['FAILURES: ', failures size printString]); cr.
out close.
failures isEmpty ifFalse: [self error: 'Oil Dispatcher stress failures: ', failures printString]
