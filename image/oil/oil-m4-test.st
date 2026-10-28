"Oil Pass 2 acceptance test (in image): OilLoopCompiler>>loopOptimize.
 Files in the Oil sources, compiles probes with Pass 1, runs Pass 2, dumps both IRs, checks the loop optimizations
 (rotation, bounds check elimination, shared sizes, unchecked index increments, dead code), and validates Pass 2's IR
 by executing it (OilIRInterpreter) against Pass 1's IR and the real execution of each method, deopts included."
| dir |
Utilities authorInitials: 'cb'.
dir := Smalltalk at: #OilSourceDir ifAbsentPut: [((FileDirectory default fileExists: 'OilConstants.st') ifTrue: [FileDirectory default] ifFalse: [FileDirectory default directoryNamed: 'oil']) pathName, '/'].
#('OilInstructionConstants.st' 'OilConstants.st' 'OilBytecodeScanner.st' 'OilCompiler.st' 'OilCompilerBackend.st' 'OilCompilerPass2.st' 'OilSimulation.st') do:
	[:f | (FileStream readOnlyFileNamed: dir, f) fileIn]!

| dir out model coll arr mixed pass fail check compile run same c hist stats results probes loopHist arrWithOther arrWithInt arrOverflow |
dir := Smalltalk at: #OilSourceDir.
out := FileStream forceNewFileNamed: (Smalltalk at: #OilResultFile ifAbsent: [dir, 'm4-test-result.txt']).
pass := 0. fail := 0.
check := [:name :bool |
	bool == true
		ifTrue: [pass := pass + 1. out nextPutAll: 'PASS  '; nextPutAll: name; cr]
		ifFalse: [fail := fail + 1. out nextPutAll: 'FAIL  '; nextPutAll: name; cr]. out flush].
model := OilCoreSimulationModelTest new.
coll := OrderedCollection new.
1 to: 12 do: [:i | coll add: (OilCoreSimulationItem new score: i; yourself)].
coll removeFirst; removeFirst.
arr := (1 to: 10) collect: [:i | OilCoreSimulationItem new score: i * 3; yourself].
mixed := OrderedCollection new. coll do: [:e | mixed add: e]. mixed add: OilCoreSimulationOther new.
arrWithOther := arr copy. arrWithOther at: 5 put: OilCoreSimulationOther new.
arrWithInt := arr copy. arrWithInt at: 7 put: 42.
arrOverflow := arr copy. arrOverflow at: 3 put: (OilCoreSimulationItem new score: SmallInteger maxVal; yourself).

"compile: Pass 1 with type feedback from sample arguments, then (if pass2) Pass 2"
compile := [:sel :argLists :pass2 |
	| fbk comp |
	fbk := OilSimulatedTypeFeedback new.
	argLists do: [:args | fbk record: [[model perform: sel withArguments: args] on: Error do: [:e | e return: nil]]].
	comp := OilCompiler new.
	comp typeFeedback: fbk.
	comp compileMethod: OilCoreSimulationModelTest >> sel receiverClass: (comp handleFor: OilCoreSimulationModelTest).
	pass2 ifTrue: [comp loopOptimize].
	comp].
run := [:comp :sel :args | [(OilIRInterpreter new on: comp) run: model with: args] on: Error do: [:e | #error -> e description]].
"Pass 2's IR must behave like Pass 1's: the same result, or a deopt where Pass 1 deopts (possibly earlier, never later)."
same := [:r1 :r2 |
	(r1 isKindOf: Association)
		ifTrue: [(r2 isKindOf: Association) and: [r2 key == #deopt]]
		ifFalse: [(r2 isKindOf: Association) not and: [r1 = r2]]].
stats := [:comp | (0 to: 5) collect: [:k | comp pass2Statistics: k]].

"--- 1. sumScores: on an Array (the M3/M4 benchmark shape) ---"
c := compile value: #sumScores: value: {{arr}} value: false.
out cr; nextPutAll: c irString.
c loopOptimize.
out cr; nextPutAll: c irString; nextPutAll: 'Pass 2 statistics (rotated, bounds removed, dead, sizes shared, unchecked increments, Pass 1 words): '; print: (stats value: c); cr; flush.
hist := c opcodeHistogram.
check value: 'sumScores:(Array) Pass 2 succeeds' value: c failed not.
check value: 'sumScores:(Array) loop rotated: one backward BranchTrue, no Jump' value: ((hist occurrencesOf: 'BranchTrue') = 1 and: [(hist occurrencesOf: 'Jump') = 0]).
check value: 'sumScores:(Array) bounds check eliminated (no CheckBounds)' value: (hist occurrencesOf: 'CheckBounds') = 0.
check value: 'sumScores:(Array) one LoadSize left, before the loop (the loop''s size is shared, then dead)' value: (hist occurrencesOf: 'LoadSize') = 1.
check value: 'sumScores:(Array) index increment unchecked (AddImmTaggedNC)' value: ((hist occurrencesOf: 'AddImmTaggedNC') = 1 and: [(hist occurrencesOf: 'AddImmTagged') = 0]).
check value: 'sumScores:(Array) element class guard and tagged add kept (deopt sites)' value: ((hist occurrencesOf: 'GuardClass') = 3 and: [(hist occurrencesOf: 'AddTagged') = 1]).
check value: 'sumScores:(Array) statistics: 1 rotated, 1 bounds check removed, 1 size shared, 1 unchecked increment' value: ((stats value: c) in: [:st | (st at: 1) = 1 and: [(st at: 2) = 1 and: [(st at: 4) = 1 and: [(st at: 5) = 1]]]]).
#(0 1 2 10 1000) do: [:n | | a |
	a := (1 to: n) asArray collect: [:i | OilCoreSimulationItem new score: i; yourself].
	check value: 'sumScores:(Array) Pass 2 IR result = real result for ', n printString, ' elements' value: (run value: c value: #sumScores: value: {a}) = (model sumScores: a)].
check value: 'sumScores:(Array) Pass 2 IR deopts on a foreign element' value: ((run value: c value: #sumScores: value: {arrWithOther}) in: [:r | (r isKindOf: Association) and: [r key == #deopt]]).
check value: 'sumScores:(Array) Pass 2 IR deopts on a SmallInteger element' value: ((run value: c value: #sumScores: value: {arrWithInt}) in: [:r | (r isKindOf: Association) and: [r key == #deopt]]).
check value: 'sumScores:(Array) Pass 2 IR deopts on SmallInteger overflow' value: ((run value: c value: #sumScores: value: {arrOverflow}) in: [:r | (r isKindOf: Association) and: [r key == #deopt]]).
check value: 'sumScores:(Array) Pass 2 IR deopts on an OrderedCollection argument' value: ((run value: c value: #sumScores: value: {coll}) in: [:r | (r isKindOf: Association) and: [r key == #deopt]]).
check value: 'sumScores:(Array) Pass 2 IR fits Buffer 2' value: c irIndex < 4096.

"--- 1b. A hash probe (repeat loop, \\ by the array size) called from a loop: inlined, no calls ---"
OilCoreSimulationModelTest compile: 'probeHash: anArray key: key
	| index length element |
	length := anArray size.
	index := (key hash \\ length) + 1.
	[element := anArray at: index.
	 element == nil ifTrue: [^index].
	 element == key ifTrue: [^index].
	 index := index \\ length + 1] repeat' classified: 'probes'.
OilCoreSimulationModelTest compile: 'probeLoop: anArray key: key
	| sum |
	sum := 0.
	1 to: 100 do: [:i | sum := sum + (self probeHash: anArray key: key)].
	^sum' classified: 'probes'.
[| table |
 table := Array new: 8191.
 1 to: 4000 do: [:i | table at: (i * 17 \\ 8191) + 1 put: i * 17].
 c := compile value: #probeLoop:key: value: {{table. 68000}. {table. 5}} value: false.
 out cr; nextPutAll: c irString.
 c loopOptimize.
 out cr; nextPutAll: c irString; nextPutAll: 'Pass 2 statistics: '; print: ((0 to: 6) collect: [:k | c pass2Statistics: k]); cr; flush.
 hist := c opcodeHistogram.
 check value: 'probeLoop: probeHash:key: inlined into the caller loop (2 frames, no calls)' value: (c numFrames = 2 and: [((hist occurrencesOf: 'Call0') + (hist occurrencesOf: 'Call1') + (hist occurrencesOf: 'CallN')) = 0]).
 check value: 'probeLoop: \\ by the array size inlined (OilModTagged)' value: (hist occurrencesOf: 'ModTagged') = 2.
 check value: 'probeLoop: the probe loop does not guard the array again (Pass 2)' value: (c pass2Statistics: 6) >= 1.
 #(68000 5 17 34 0 -17) do: [:k |
	check value: 'probeLoop: Pass 2 IR result = real result for key ', k printString value: (run value: c value: #probeLoop:key: value: {table. k}) = (model probeLoop: table key: k)].
 check value: 'probeLoop: Pass 2 IR deopts on an empty table (ZeroDivide)' value: ((run value: c value: #probeLoop:key: value: {#(). 5}) in: [:r | (r isKindOf: Association) and: [r key == #deopt]])] value.

"--- 1c. Byte objects: ByteString at:/size, String>>= (inlined, compareWith: as an intrinsic), ByteArray at:put: ---"
OilCoreSimulationModelTest compile: 'countA: aString
	| n |
	n := 0.
	1 to: aString size do: [:i | (aString at: i) == $a ifTrue: [n := n + 1]].
	^n' classified: 'probes'.
OilCoreSimulationModelTest compile: 'countEqual: aString in: anArray
	| n |
	n := 0.
	anArray do: [:e | e = aString ifTrue: [n := n + 1]].
	^n' classified: 'probes'.
OilCoreSimulationModelTest compile: 'fillBytes: aByteArray
	1 to: aByteArray size do: [:i | aByteArray at: i put: i \\ 256].
	^aByteArray' classified: 'probes'.
OilCoreSimulationModelTest compile: 'upcase: aString
	| s |
	s := aString copy.
	1 to: s size do: [:i | | c | c := s at: i. (c between: $a and: $z) ifTrue: [s at: i put: (Character value: c asInteger - 32)]].
	^s' classified: 'probes'.
[| strs bstrs |
 strs := #('abc' 'abd' 'ab' 'abcd' 'abc' 'xyz' #abc 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaab' 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaab' 3) collect: [:e | e isString ifTrue: [e copy] ifFalse: [e]].
 strs at: 7 put: #abc.
 bstrs := strs select: [:e | e class == ByteString].
 {{#countA:. {{'banana'}}. {{'banana'}. {''}. {'aaaa'}. {'xyz'}}}.
  {#countEqual:in:. {{'abc'. bstrs}}. {{'abc'. bstrs}. {'aaaaaaaaaaaaaaaaaaaaaaaaaaaaab'. bstrs}. {'zz'. bstrs}. {''. bstrs}. {'abc'. strs}}}.
  {#fillBytes:. {{ByteArray new: 10}}. {{ByteArray new: 300}. {ByteArray new: 0}. {#[1 2 3] copy}}}.
  {#upcase:. {{'hello'}}. {{'hello world'}. {''}. {'ABC'}}}} do: [:spec | | sel c1 c2 |
	sel := spec first.
	c1 := compile value: sel value: (spec at: 2) value: false.
	c2 := compile value: sel value: (spec at: 2) value: true.
	out cr; nextPutAll: c2 irString.
	check value: sel, ' compiles without calls to at:, at:put:, size, =' value: (c2 failed not and: [(c2 irString includesSubstring: '#at:') not and: [(c2 irString includesSubstring: '#=') not and: [(c2 irString includesSubstring: '#size') not]]]).
	(spec at: 3) do: [:args | | r1 r2 real a1 a2 |
		a1 := args collect: [:e | e copy].
		a2 := args collect: [:e | e copy].
		r1 := run value: c1 value: sel value: a1.
		r2 := run value: c2 value: sel value: a2.
		real := model perform: sel withArguments: (args collect: [:e | e copy]).
		check value: sel, ' Pass 2 = Pass 1 = real for ', (args printString contractTo: 50) value: ((same value: r1 value: r2) and: [(r1 isKindOf: Association) or: [r1 = real]])]]] value.

"--- 2. Every M2 probe: Pass 2 IR = Pass 1 IR = real execution ---"
probes := {
	{#sumScores:. {{coll}}. {{coll}. {OrderedCollection new}. {mixed}. {coll asArray}}}.
	{#sumArray:. {{arr}}. {{arr}. {#()}. {arrWithOther}. {arrWithInt}. {arrOverflow}}}.
	{#sumIndexed:. {{arr}}. {{arr}. {#()}. {arrWithOther}. {arrOverflow}}}.
	{#peepholes:with:. {{37. 12}. {-5. 7}}. {{37. 12}. {-5. 7}. {0. 0}. {1000000. -3}. {-1. -1}. {SmallInteger maxVal. 1}}}.
	{#callProbe:with:with:. {{coll first. 1. 2}. {OilCoreSimulationOther new. 3. 4}}. {{coll first. 5. 6}. {OilCoreSimulationOther new. 5. 6}}}.
	{#detectProbe:. {{coll}}. {{coll}. {OrderedCollection with: (OilCoreSimulationItem new score: 1; yourself)}}}.
	{#countEven:. {{arr}}. {{arr}. {#()}. {arrWithOther}}}.
	{#hashProbe:with:. {{(Set withAll: (1 to: 40 by: 3)). 7}. {(Set withAll: (1 to: 40 by: 3)). 8}}. (#(7 8 1 40 37 100 -3) collect: [:k | {Set withAll: (1 to: 40 by: 3). k}])}.
	{#sumInterval:. {{10}}. {{0}. {1}. {10}. {1000}}}.
	{#injectScores:. {{arr}}. {{arr}. {#()}. {arrWithOther}. {arrOverflow}}}.
	{#escapeProbe:. {{10}}. {}} }.
probes do: [:spec | | sel c1 c2 ok |
	sel := spec first.
	c1 := compile value: sel value: (spec at: 2) value: false.
	c2 := compile value: sel value: (spec at: 2) value: true.
	out nextPutAll: sel; nextPutAll: ': Pass 1 '; print: c1 irIndex; nextPutAll: ' words, Pass 2 '; print: c2 irIndex; nextPutAll: ' words, statistics '; print: (stats value: c2); cr.
	check value: sel, ' Pass 2 succeeds' value: (c1 failed or: [c2 failed not]).
	(spec at: 3) do: [:args | | r1 r2 real |
		r1 := run value: c1 value: sel value: args.
		r2 := run value: c2 value: sel value: args.
		real := [model perform: sel withArguments: args] on: Error do: [:e | #error].
		ok := (same value: r1 value: r2) and: [(r1 isKindOf: Association) or: [r1 = real]].
		ok ifFalse: [out nextPutAll: '   Pass 1 '; print: r1; nextPutAll: ' Pass 2 '; print: r2; nextPutAll: ' real '; print: real; cr].
		check value: sel, ' Pass 2 = Pass 1 = real for ', (args printString contractTo: 60) value: ok]].

"--- 3. Robustness: Pass 1 + Pass 2 on every method of a few classes ---"
results := Bag new.
loopHist := Array new: 6 withAll: 0.
{OrderedCollection. Set. Dictionary. Interval. String. Array. Point. Rectangle. Integer. SmallInteger. Float. Collection. SequenceableCollection. ArrayedCollection. Bag. Symbol. ByteArray} do: [:cls |
	cls selectorsDo: [:sel | | m comp |
		m := cls >> sel.
		comp := OilCompiler new.
		[comp compileMethod: m receiverClass: (comp handleFor: cls).
		 comp failed ifFalse:
			[comp loopOptimize.
			 comp failed ifFalse: [(stats value: comp) withIndexDo: [:v :k | k <= 5 ifTrue: [loopHist at: k put: (loopHist at: k) + v]]]].
		 results add: (comp failed ifTrue: [OilConstants failureNames at: comp failureCode + 1] ifFalse: [#ok])]
			on: Error do: [:e | results add: #ERROR. out nextPutAll: 'ERROR compiling '; print: m; nextPutAll: ': '; nextPutAll: e description; cr]]].
out cr; nextPutAll: 'Robustness sweep (Pass 1 + Pass 2): '; print: results size; nextPutAll: ' methods: '.
results asSet asSortedCollection do: [:k | out nextPutAll: k; nextPutAll: '='; print: (results occurrencesOf: k); space].
out cr; nextPutAll: 'Pass 2 totals: loops rotated '; print: (loopHist at: 1); nextPutAll: ', bounds checks removed '; print: (loopHist at: 2);
	nextPutAll: ', dead instructions removed '; print: (loopHist at: 3); nextPutAll: ', sizes shared '; print: (loopHist at: 4);
	nextPutAll: ', unchecked increments '; print: (loopHist at: 5); cr.
check value: 'robustness: no Smalltalk error in Pass 1 + Pass 2' value: (results occurrencesOf: #ERROR) = 0.
check value: 'robustness: Pass 2 optimized some loops' value: (loopHist at: 1) > 0.

"--- 4. Pass 2 time (in image) ---"
[| fbk comp us n |
 fbk := OilSimulatedTypeFeedback new.
 fbk record: [model sumScores: arr].
 comp := OilCompiler new. comp typeFeedback: fbk.
 n := 1000.
 us := Time microsecondsToRun: [n timesRepeat: [comp compileMethod: OilCoreSimulationModelTest >> #sumScores: receiverClass: (comp handleFor: OilCoreSimulationModelTest). comp loopOptimize]].
 out cr; nextPutAll: 'Pass 1 + Pass 2 time for sumScores: (in image, simulated object access): '; print: (us / n) asFloat; nextPutAll: ' us per compilation'; cr] value.

out cr; nextPutAll: 'TOTAL: '; print: pass; nextPutAll: ' passed, '; print: fail; nextPutAll: ' failed'; cr.
out close!
