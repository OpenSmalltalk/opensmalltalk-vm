"Oil end-to-end test (native) of the interrupt checks of Oil loops (Milestone 14).  A loop of Oil code whose body sends
 nothing that builds a frame checks the stack limit once per iteration (OilInliningCompiler>>genPollBefore:), so the timer,
 process switches and interrupts are serviced.  Each probe spins on a flag that only a higher priority process, woken by
 a Delay, sets: the loop must be preempted at its interrupt check.  While the spinner is suspended there, that process
 inspects the spinner's context (Context>>contexts: the activations at the check), collects garbage (the registers were
 spilled) and, for some probes, deoptimizes the frame (Context>>deoptimize), after which the loop finishes in the contexts.
 Run with run-st.sh on a Squeak 6.x 64-bit image with the Oil VM.  Writes oil-poll-result.txt next to the image.
 OilDeoptMetadataReader.st (image/oil) must be next to the image or in OilSourceDir."
| out failures check cls item model dir readerFile r spinFor limit probes |
Utilities authorInitials: 'cb'.
out := FileStream forceNewFileNamed: (FileDirectory default fullNameFor: 'oil-poll-result.txt').
failures := OrderedCollection new.
check := [:name :bool |
	out nextPutAll: (bool == true ifTrue: ['PASS '] ifFalse: ['FAIL ']); nextPutAll: name; cr; flush.
	bool == true ifFalse: [failures add: name]].
dir := Smalltalk at: #OilSourceDir ifAbsent: [FileDirectory default pathName, '/'].
readerFile := (FileDirectory default fileExists: 'OilDeoptMetadataReader.st')
	ifTrue: [FileDirectory default fullNameFor: 'OilDeoptMetadataReader.st']
	ifFalse: [dir, 'OilDeoptMetadataReader.st'].
(FileStream readOnlyFileNamed: readerFile) fileIn.
check value: 'OilDeoptMetadataReader filed in' value: (Smalltalk includesKey: #OilDeoptMetadataReader).
Object subclass: #OilPollItem instanceVariableNames: 'score' classVariableNames: '' poolDictionaries: '' category: 'OilJIT-poll-tests'.
Object subclass: #OilPollModel instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'OilJIT-poll-tests'.
item := Smalltalk at: #OilPollItem. cls := Smalltalk at: #OilPollModel.
item compile: 'score ^score' classified: 'tests'.
item compile: 'score: n score := n' classified: 'tests'.
"spin:max: a loop without any call; spinItem: the same with an inlined send (score); spinFloat: a float accumulator"
cls compile: 'spin: flag max: m | n | n := 0. [(flag at: 1) == true or: [n >= m]] whileFalse: [n := n + 1]. ^n' classified: 'tests'.
cls compile: 'spinItem: it flag: flag max: m | n | n := 0. [(flag at: 1) == true or: [n >= m]] whileFalse: [n := n + it score]. ^n' classified: 'tests'.
cls compile: 'spinTo: flag max: m | n | n := 0. 1 to: m do: [:i | (flag at: 1) == true ifTrue: [^n]. n := n + 1]. ^n' classified: 'tests'.
cls compile: 'spinFloat: flag max: m | n f | n := 0. f := 0.0. [(flag at: 1) == true or: [n >= m]] whileFalse: [n := n + 1. f := f + 1.5]. ^n' classified: 'tests'.
cls class compile: 'oilSetParameter: index to: value <primitive: ''primitiveOilSetParameter''> ^#failed' classified: 'oil'.
cls class compile: 'oilTenureAll <primitive: 138> ^nil' classified: 'oil'.
CompiledMethod compile: 'oilCompileFor: aClass <primitive: ''primitiveOilCompile''> ^#failed' classified: 'oil'.
CompiledMethod compile: 'oilInfo <primitive: ''primitiveOilMethodInfo''> ^#failed' classified: 'oil'.
check value: 'no autonomous compilation' value: (cls oilSetParameter: 19 to: 0) ~~ #failed.
cls oilTenureAll.
model := cls new.
"(SmallInteger iterations; a loop that is never preempted runs for seconds and answers limit)"
limit := 3000000000.
"spinFor: run the probe (a block of the flag) in this process while a higher priority process, after 50 ms, inspects the
 suspended spinner (and deoptimizes its frame if deopt, reading the loop variable n, temp nIndex, in the leaf), then sets
 the flag.  Answers {result. info}."
spinFor := [:probe :deopt :nIndex | | flag spinner info sem result |
	flag := {false}. info := nil. sem := Semaphore new.
	spinner := Processor activeProcess.
	[| ctx leaf |
	 (Delay forMilliseconds: 50) wait.
	 ctx := spinner suspendedContext.
	 info := Dictionary new.
	 info at: #method put: ctx method.
	 info at: #contexts put: ctx contexts.
	 1 to: 30000 do: [:k | Array new: 20].
	 Smalltalk garbageCollect.
	 deopt ifTrue:
		[leaf := ctx deoptimize.
		 info at: #leaf put: leaf.
		 info at: #leafN put: (leaf tempAt: nIndex)].
	 flag at: 1 put: true.
	 sem signal] forkAt: Processor activePriority + 1.
	result := probe value: flag.
	sem wait.
	{result. info}].
"probes: {selector. run (a block of the flag). warm-up. index of the temp n}"
probes := {
	{#spin:max:. [:flag | model spin: flag max: limit]. [model spin: {false} max: 1000]. 3}.
	{#spinItem:flag:max:. [:flag | model spinItem: (item new score: 1; yourself) flag: flag max: limit]. [model spinItem: (item new score: 1; yourself) flag: {false} max: 1000]. 4}.
	{#spinTo:max:. [:flag | model spinTo: flag max: limit]. [model spinTo: {false} max: 1000]. 3}.
	{#spinFloat:max:. [:flag | model spinFloat: flag max: limit]. [model spinFloat: {false} max: 1000]. 3}}.
probes do: [:spec | | sel run res info |
	sel := spec first.
	3 timesRepeat: [spec third value].
	r := (cls >> sel) oilCompileFor: cls.
	out nextPutAll: sel; nextPutAll: ' oilCompileFor: -> '; print: r; cr; flush.
	check value: sel, ' compiles' value: r = 0.
	#(false true) do: [:deopt |
		run := spinFor value: spec second value: deopt value: (spec at: 4).
		res := run first. info := run last.
		out nextPutAll: sel; nextPutAll: (deopt ifTrue: [' (deoptimized)'] ifFalse: ['']); nextPutAll: ' -> '; print: res;
			nextPutAll: ' contexts '; print: (info ifNotNil: [info at: #contexts ifAbsent: [nil]]); cr; flush.
		check value: sel, (deopt ifTrue: [' deoptimized'] ifFalse: ['']), ': preempted in the loop (flag seen)' value: (res isInteger and: [res > 0 and: [res < limit]]).
		check value: sel, (deopt ifTrue: [' deoptimized'] ifFalse: ['']), ': the spinner was suspended in it' value: (info notNil and: [(info at: #method) == (cls >> sel)]).
		sel == #spinFloat:max: ifFalse:
			[check value: sel, (deopt ifTrue: [' deoptimized'] ifFalse: ['']), ': contexts at the check' value: (info notNil and: [(info at: #contexts) size = 1 and: [(info at: #contexts) first key == (cls >> sel)]])].
		deopt ifFalse:
			[| reader |
			 reader := OilDeoptMetadataReader on: (cls >> sel) oilMetadata.
			 check value: sel, ': the metadata records the check (contextsAtSite: = contexts)' value: (info notNil and: [reader interruptChecks anySatisfy: [:site | (reader contextsAtSite: site) = (info at: #contexts)]])].
		deopt ifTrue:
			[check value: sel, ' deoptimized: the loop variable' value: (((info at: #leafN ifAbsent: [nil]) isInteger) and: [(info at: #leafN) <= res])]].
	check value: sel, ' still Oil code' value: (cls >> sel) oilInfo notNil.
	check value: sel, ' = baseline on a short run' value: (model perform: sel withArguments: (sel == #spinItem:flag:max:
		ifTrue: [{item new score: 2; yourself. {false}. 1001}] ifFalse: [{{false}. 1000}])) = (sel == #spinItem:flag:max: ifTrue: [1002] ifFalse: [1000])].
out nextPutAll: (failures isEmpty ifTrue: ['ALL PASS'] ifFalse: ['FAILURES: ', failures size printString]); cr.
out close.
failures isEmpty ifFalse: [self error: 'Oil poll test failures: ', failures printString]
