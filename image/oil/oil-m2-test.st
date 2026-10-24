"Oil Milestone 2 acceptance test: OilCompiler Pass 1 (linear IR, inlining, peepholes).
 Files in the Oil sources, records type feedback by simulated execution (standing in for ProfilingCogit's PICs),
 compiles the probes, dumps the flattened IR, and validates it by executing the IR (OilIRInterpreter) against
 the real execution of each method."
| dir |
Utilities authorInitials: 'cb'.
dir := Smalltalk at: #OilSourceDir ifAbsentPut: ['/usr/local/google/home/clementbera/.gemini/jetski/brain/d1466531-7c6e-4182-90d9-4bed24e00db9/scratch/osvm/image/oil/'].
#('OilConstants.st' 'OilBytecodeScanner.st' 'OilCompiler.st' 'OilCompilerBackend.st' 'OilSimulation.st') do:
	[:f | (FileStream readOnlyFileNamed: dir, f) fileIn]!

| dir out model coll arr mixed pass fail check compile run results probes c fb ok hist irs |
dir := Smalltalk at: #OilSourceDir.
out := FileStream forceNewFileNamed: (Smalltalk at: #OilResultFile ifAbsent: [dir, 'm2-test-result.txt']).
pass := 0. fail := 0.
check := [:name :bool |
	bool == true
		ifTrue: [pass := pass + 1. out nextPutAll: 'PASS  '; nextPutAll: name; cr]
		ifFalse: [fail := fail + 1. out nextPutAll: 'FAIL  '; nextPutAll: name; cr]. out flush].
model := OilTestModel new.
coll := OrderedCollection new.
1 to: 12 do: [:i | coll add: (OilTestItem new score: i; yourself)].
coll removeFirst; removeFirst. "firstIndex > 1, like a real queue"
arr := (1 to: 10) collect: [:i | OilTestItem new score: i * 3; yourself].
mixed := OrderedCollection new. coll do: [:e | mixed add: e]. mixed add: OilTestOther new.

"compile: a selector with sample arguments (list of arg arrays) -> compiler"
compile := [:sel :argLists :budget |
	| fbk comp |
	fbk := OilSimulatedTypeFeedback new.
	argLists do: [:args | fbk record: [model perform: sel withArguments: args]].
	comp := OilCompiler new.
	comp typeFeedback: fbk.
	budget ifNotNil: [comp irBudget: budget].
	comp compileMethod: OilTestModel >> sel receiverClass: (comp handleFor: OilTestModel).
	out cr; nextPutAll: comp irString; flush.
	comp].
run := [:comp :sel :args | (OilIRInterpreter new on: comp) run: model with: args].

"--- 1. sumScores: (the acceptance method) ---"
c := compile value: #sumScores: value: {{coll}} value: nil.
hist := c opcodeHistogram.
check value: 'sumScores: compiles' value: c failed not.
check value: 'sumScores: zero BlockClosure allocation (no OilMakeClosure, no OilNewArray temp vector)' value: ((hist occurrencesOf: 'MakeClosure') = 0 and: [(hist occurrencesOf: 'NewArray') = 0]).
check value: 'sumScores: zero sends (do:, value:, score, at:, <=, + all inlined: no OilCall*)' value: ((hist occurrencesOf: 'Call0') + (hist occurrencesOf: 'Call1') + (hist occurrencesOf: 'CallN') + (hist occurrencesOf: 'CallSuper')) = 0.
check value: 'sumScores: inlined score getter and do: fields (OilLoadField)' value: (hist occurrencesOf: 'LoadField') >= 3.
check value: 'sumScores: direct array element load with bounds check' value: ((hist occurrencesOf: 'LoadElement') = 1 and: [(hist occurrencesOf: 'CheckBounds') = 1]).
check value: 'sumScores: loop: index increment (OilAddImmTagged +1), compare+branch, back jump' value: ((hist occurrencesOf: 'AddImmTagged') = 1 and: [(hist occurrencesOf: 'CmpTagged') = 1 and: [(hist occurrencesOf: 'BranchFalse') = 1 and: [(hist occurrencesOf: 'Jump') = 1]]]).
check value: 'sumScores: accumulator as tagged add into the scalar replaced temp vector slot' value: (hist occurrencesOf: 'AddTagged') = 1.
check value: 'sumScores: IR result = real result' value: (run value: c value: #sumScores: value: {coll}) = (model sumScores: coll).
check value: 'sumScores: IR on empty collection = 0' value: (run value: c value: #sumScores: value: {OrderedCollection new}) = 0.
check value: 'sumScores: deopt (class guard) on a foreign element' value: ((run value: c value: #sumScores: value: {mixed}) isKindOf: Association).
check value: 'sumScores: deopt (receiver class guard) on an Array argument' value: ((run value: c value: #sumScores: value: {coll asArray}) isKindOf: Association).
check value: 'sumScores: IR fits the budget (< 1024 instructions)' value: c irInstCount < 1024.

"--- 2. IR budget exhausted: do: is not inlined, the closure must exist ---"
c := compile value: #sumScores: value: {{coll}} value: 2.
hist := c opcodeHistogram.
check value: 'budget 2: do: stays a send (OilCall1) and the closure/temp vector are materialized (eager)' value: ((hist occurrencesOf: 'Call1') = 1 and: [(hist occurrencesOf: 'MakeClosure') = 1 and: [c eagerClosures]]).
check value: 'budget 2: IR result = real result' value: (run value: c value: #sumScores: value: {coll}) = (model sumScores: coll).

"--- 3. Array iteration: SequenceableCollection>>do: with the size intrinsic ---"
c := compile value: #sumArray: value: {{arr}} value: nil.
hist := c opcodeHistogram.
check value: 'sumArray: inlined (no calls), size via OilLoadSize' value: ((hist occurrencesOf: 'Call1') + (hist occurrencesOf: 'Call0') = 0 and: [(hist occurrencesOf: 'LoadSize') >= 1]).
check value: 'sumArray: IR result = real result' value: (run value: c value: #sumArray: value: {arr}) = (model sumArray: arr).

"--- 4. 1-based indexing: (i - 1) + 1 and + 0 fold away ---"
c := compile value: #sumIndexed: value: {{arr}} value: nil.
hist := c opcodeHistogram.
check value: 'sumIndexed: (i - 1) + 1 folded (only the loop increment remains as OilAddImmTagged)' value: (hist occurrencesOf: 'AddImmTagged') = 1.
check value: 'sumIndexed: + 0 folded (single accumulator OilAddTagged)' value: (hist occurrencesOf: 'AddTagged') = 1.
check value: 'sumIndexed: IR result = real result' value: (run value: c value: #sumIndexed: value: {arr}) = (model sumIndexed: arr).

"--- 5. Peepholes on tagged SmallIntegers ---"
c := compile value: #peepholes:with: value: {{37. 12}. {-5. 7}} value: nil.
hist := c opcodeHistogram.
check value: 'peepholes: no sends at all' value: ((hist occurrencesOf: 'Call1') + (hist occurrencesOf: 'Call0') + (hist occurrencesOf: 'CallN')) = 0.
check value: 'peepholes: (i-1)+1, (i+1)-1, i+0, 0+i, i-0, (i-1)+1+0, i*1, i//1, bitAnd: -1, bitOr: 0 emit nothing (12 Moves into the brace only)' value: (hist occurrencesOf: 'Move') = 10.
check value: 'peepholes: 3 + 4 constant folded' value: (hist occurrencesOf: 'ConstTagged') = 2.
check value: 'peepholes: bitAnd:/bitOr:/bitXor: as single tagged ops' value: ((hist occurrencesOf: 'AndTagged') >= 1 and: [(hist occurrencesOf: 'OrTagged') = 1 and: [(hist occurrencesOf: 'XorTagged') = 1]]).
check value: 'peepholes: // 4 and bitShift: as OilShiftTagged, * 31 / * 9 / * 8 via shifts' value: (hist occurrencesOf: 'ShiftTagged') = 6.
check value: 'peepholes: \\ 2 as OilOddTagged' value: (hist occurrencesOf: 'OddTagged') = 1.
check value: 'peepholes: (i+5)-2 and (i-3)+1 combined into one OilAddImmTagged each' value: (hist occurrencesOf: 'AddImmTagged') = 2.
#((37 12) (-5 7) (0 0) (1000000 -3) (-1 -1)) do: [:pair |
	check value: 'peepholes: IR result = real result for ', pair printString value: (run value: c value: #peepholes:with: value: pair) = (model peepholes: pair first with: pair last)].
check value: 'peepholes: SmallInteger overflow deopts (no wrong result)' value: ((run value: c value: #peepholes:with: value: {SmallInteger maxVal. 1}) isKindOf: Association).

"--- 6. Calls: polymorphic receiver, 0/1/2/3 arguments ---"
c := compile value: #callProbe:with:with: value: {{coll first. 1. 2}. {OilTestOther new. 3. 4}} value: nil.
hist := c opcodeHistogram.
check value: 'callProbe: OilCall0, OilCall1 and two OilCallN (packed args)' value: ((hist occurrencesOf: 'Call0') = 1 and: [(hist occurrencesOf: 'Call1') = 1 and: [(hist occurrencesOf: 'CallN') = 2]]).
check value: 'callProbe: IR result = real result (OilTestItem)' value: (run value: c value: #callProbe:with:with: value: {coll first. 5. 6}) = (model callProbe: coll first with: 5 with: 6).
check value: 'callProbe: IR result = real result (OilTestOther)' value: (run value: c value: #callProbe:with:with: value: {OilTestOther new. 5. 6}) = (model callProbe: OilTestOther new with: 5 with: 6).

"--- 7. Nested iterators, blocks passed through 3 methods, non-local return from an inlined block ---"
c := compile value: #detectProbe: value: {{coll}} value: nil.
hist := c opcodeHistogram.
check value: 'detectProbe: detect:ifNone: -> detect:ifFound:ifNone: -> do: -> blocks all inlined (no calls, no closures)' value: ((hist occurrencesOf: 'Call1') + (hist occurrencesOf: 'Call0') + (hist occurrencesOf: 'CallN') + (hist occurrencesOf: 'MakeClosure')) = 0.
check value: 'detectProbe: the inlined block''s comparison result is branched on directly (no true/false materialized)' value: (c irString includesSubstring: ':= true') not.
check value: 'detectProbe: IR result = real result (found)' value: (run value: c value: #detectProbe: value: {coll}) = (model detectProbe: coll).
check value: 'detectProbe: IR result = real result (not found)' value: (run value: c value: #detectProbe: value: {OrderedCollection with: (OilTestItem new score: 1; yourself)}) = 0.

"--- 8. x \\ 2 = 0 fused into a branch ---"
c := compile value: #countEven: value: {{arr}} value: nil.
hist := c opcodeHistogram.
check value: 'countEven: OilOddTagged + OilCmpImmTagged fused with branch' value: ((hist occurrencesOf: 'OddTagged') = 1 and: [(hist occurrencesOf: 'CmpImmTagged') = 1]).
check value: 'countEven: IR result = real result' value: (run value: c value: #countEven: value: {arr}) = (model countEven: arr).

"--- 8b. Hash probe: Set>>includes: -> scanFor: ---"
c := compile value: #hashProbe:with: value: {{(Set withAll: (1 to: 40 by: 3)). 7}. {(Set withAll: (1 to: 40 by: 3)). 8}} value: nil.
hist := c opcodeHistogram.
check value: 'hashProbe: includes: and scanFor: inlined (probe loop in the IR)' value: (c numFrames >= 3 and: [(hist occurrencesOf: 'LoadElement') >= 2]).
check value: 'hashProbe: errorNoFreeSpace is cold: a call, not inlined' value: ((c irString includesSubstring: '#errorNoFreeSpace') and: [(c irString includesSubstring: 'Object>>#error:') not]).
#(7 8 1 40 37 100 -3) do: [:k | | s |
	s := Set withAll: (1 to: 40 by: 3).
	check value: 'hashProbe: IR result = real result for key ', k printString value: (run value: c value: #hashProbe:with: value: {s. k}) = (model hashProbe: s with: k)].

"--- 8c. Interval>>do: (two loops, block inlined twice) and inject:into: ---"
c := compile value: #sumInterval: value: {{10}} value: nil.
hist := c opcodeHistogram.
check value: 'sumInterval: Interval>>do: inlined with the block in both loops' value: ((hist occurrencesOf: 'Jump') >= 2 and: [(hist occurrencesOf: 'MakeClosure') = 0]).
#(0 1 10 1000) do: [:n | check value: 'sumInterval: IR result = real result for ', n printString value: (run value: c value: #sumInterval: value: {n}) = (model sumInterval: n)].
c := compile value: #injectScores: value: {{arr}} value: nil.
hist := c opcodeHistogram.
check value: 'injectScores: inject:into: -> do: -> 2-arg block inlined (no calls, no closures)' value: ((hist occurrencesOf: 'Call1') + (hist occurrencesOf: 'CallN') + (hist occurrencesOf: 'MakeClosure')) = 0.
check value: 'injectScores: IR result = real result' value: (run value: c value: #injectScores: value: {arr}) = (model injectScores: arr).

"--- 9. Escaping closure: restart in eager mode ---"
c := compile value: #escapeProbe: value: {{10}} value: nil.
check value: 'escapeProbe: eager mode, OilMakeClosure' value: (c eagerClosures and: [(c opcodeHistogram occurrencesOf: 'MakeClosure') = 1]).
check value: 'escapeProbe: materialized closure evaluates correctly' value: ((run value: c value: #escapeProbe: value: {10}) value: 5) = 15.

"--- 9b. SistaV1 only: a method using the SqueakV3PlusClosures bytecode set is left to the baseline Cogit ---"
[| oldEncoder v3 comp |
 oldEncoder := CompiledCode preferredBytecodeSetEncoderClass.
 [CompiledCode preferredBytecodeSetEncoderClass: EncoderForV3PlusClosures.
  v3 := OilTestModel newCompiler compile: (OilTestModel >> #sumScores:) getSource asString in: OilTestModel notifying: nil ifFail: [nil]]
	ensure: [CompiledCode preferredBytecodeSetEncoderClass: oldEncoder].
 v3 := v3 isCompiledMethod ifTrue: [v3] ifFalse: [v3 generate].
 comp := OilCompiler new.
 comp compileMethod: v3 receiverClass: (comp handleFor: OilTestModel).
 check value: 'SistaV1 only: a V3PlusClosures method is rejected (FailNotSistaV1)' value: (v3 signFlag not and: [comp failed and: [(OilConstants failureNames at: comp failureCode + 1) = #FailNotSistaV1]])] value.

"--- 10. Robustness: compile every method of a few classes (receiver class known, no type feedback) ---"
results := Bag new.
{OrderedCollection. Set. Dictionary. Interval. String. Array. Point. Rectangle. Integer. SmallInteger. Float. Collection. SequenceableCollection} do: [:cls |
	cls selectorsDo: [:sel | | m comp |
		m := cls >> sel.
		comp := OilCompiler new.
		[comp compileMethod: m receiverClass: (comp handleFor: cls).
		 results add: (comp failed ifTrue: [OilConstants failureNames at: comp failureCode + 1] ifFalse: [#ok])]
			on: Error do: [:e | results add: #ERROR. out nextPutAll: 'ERROR compiling '; print: m; nextPutAll: ': '; nextPutAll: e description; cr]]].
out cr; nextPutAll: 'Robustness sweep: '; print: results size; nextPutAll: ' methods: '.
results asSet asSortedCollection do: [:k | out nextPutAll: k; nextPutAll: '='; print: (results occurrencesOf: k); space].
out cr.
check value: 'robustness: no Smalltalk error while compiling library methods' value: (results occurrencesOf: #ERROR) = 0.

"--- 11. Pass 1 compile time (in-image simulation, i.e. Smalltalk code JIT-compiled by baseline Cog) ---"
[| fbk comp us n |
 fbk := OilSimulatedTypeFeedback new.
 fbk record: [model sumScores: coll].
 comp := OilCompiler new. comp typeFeedback: fbk.
 n := 2000.
 us := Time microsecondsToRun: [n timesRepeat: [comp compileMethod: OilTestModel >> #sumScores: receiverClass: (comp handleFor: OilTestModel)]].
 out cr; nextPutAll: 'Pass 1 compile time for sumScores: (in-image, simulated object access): '; print: (us / n) asFloat; nextPutAll: ' us per compilation'; cr] value.

out cr; nextPutAll: 'TOTAL: '; print: pass; nextPutAll: ' passed, '; print: fail; nextPutAll: ' failed'; cr.
out close!
