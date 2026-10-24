"Oil Milestone 1 (ProfilingCogit) end-to-end test.  Run with run-st.sh on a Squeak 6.x 64-bit image
 using the VM built from src/spur64.oil.  Writes oil-m1-result.txt into the image's directory
 and signals an error if any check fails."
| resultPath out failures check log setLog count records recordsFor m oc small items blk pc scanner target poly warm beforeCount newRecs rec mCountTo mSumScores mMySum mMyDo blkSum blkMySum |
Utilities authorInitials: 'cb'.
resultPath := FileDirectory default fullNameFor: 'oil-m1-result.txt'.
out := WriteStream on: String new.
failures := OrderedCollection new.
check := [:name :bool |
	out nextPutAll: (bool ifTrue: ['PASS '] ifFalse: ['FAIL ']); nextPutAll: name; cr.
	bool ifFalse: [failures add: name]].

"--- Test classes ---"
Object subclass: #OilTestItem instanceVariableNames: 'score' classVariableNames: '' poolDictionaries: '' category: 'Cogit-Oil-Debugging'.
(Smalltalk at: #OilTestItem) compile: 'score ^score' classified: 'accessing'.
(Smalltalk at: #OilTestItem) compile: 'score: aNumber score := aNumber' classified: 'accessing'.
(Smalltalk at: #OilTestItem) subclass: #OilTestItem2 instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'Cogit-Oil-Debugging'.
(Smalltalk at: #OilTestItem2) compile: 'score ^score * 2' classified: 'accessing'.
Object subclass: #OilTestModel instanceVariableNames: 'items' classVariableNames: '' poolDictionaries: '' category: 'Cogit-Oil-Debugging'.
(Smalltalk at: #OilTestModel) compile: 'items: anArray items := anArray' classified: 'accessing'.
(Smalltalk at: #OilTestModel) compile: 'countTo: n | count | count := 0. 1 to: n do: [:i | count := count + 1]. ^count' classified: 'tests'.
(Smalltalk at: #OilTestModel) compile: 'sumScores: aCollection | total | total := 0. aCollection do: [:each | total := total + each score]. ^total' classified: 'tests'.
(Smalltalk at: #OilTestModel) compile: 'polySum: aCollection | total | total := 0. aCollection do: [:each | total := total + each score]. ^total' classified: 'tests'.
(Smalltalk at: #OilTestModel) compile: 'myDo: aBlock 1 to: items size do: [:i | aBlock value: (items at: i)]' classified: 'tests'.
(Smalltalk at: #OilTestModel) compile: 'mySumScores | total | total := 0. self myDo: [:each | total := total + each score]. ^total' classified: 'tests'.
(Smalltalk at: #OilTestModel) class compile: 'oilTripLog: anArrayOrNil <primitive: ''primitiveOilTripLog''> ^#failed' classified: 'oil'.
(Smalltalk at: #OilTestModel) class compile: 'oilTripLog <primitive: ''primitiveOilTripLog''> ^#failed' classified: 'oil'.
CompiledCode compile: 'oilMonomorphicTargetAt: pc <primitive: ''primitiveOilMonomorphicTarget''> ^#failed' classified: 'oil'.

mCountTo := (Smalltalk at: #OilTestModel) >> #countTo:.
mSumScores := (Smalltalk at: #OilTestModel) >> #sumScores:.
mMySum := (Smalltalk at: #OilTestModel) >> #mySumScores.
mMyDo := (Smalltalk at: #OilTestModel) >> #myDo:.
blkSum := mSumScores literals detect: [:l | l isCompiledCode].
blkMySum := mMySum literals detect: [:l | l isCompiledCode].
"The pc of the #score send in [] in sumScores:"
pc := nil.
scanner := InstructionStream on: blkSum.
[scanner pc <= blkSum endPC] whileTrue:
	[scanner selectorToSendOrSelf == #score ifTrue: [pc := scanner pc].
	 scanner interpretNextInstructionFor: InstructionClient new].

"--- Trip log helpers ---"
log := Array new: 1 + (6 * 256).
setLog := (Smalltalk at: #OilTestModel) oilTripLog: log.
check value: 'primitiveOilTripLog available (VM has ProfilingCogit)' value: setLog ~~ #failed.
setLog == #failed ifTrue:
	[(FileStream forceNewFileNamed: resultPath) nextPutAll: out contents; close.
	 self error: 'ProfilingCogit primitives missing'].
check value: 'trip log installed' value: (Smalltalk at: #OilTestModel) oilTripLog == log.
count := [(log at: 1) ifNil: [0]].
records := [| n all | n := count value. all := OrderedCollection new.
	(n - 256 max: 0) to: n - 1 do: [:k | | base | base := k \\ 256 * 6 + 2.
		all add: (log copyFrom: base to: base + 5)].
	all].
recordsFor := [:aMethod | records value select: [:r | (r at: 2) == aMethod]].
out nextPutAll: 'trips recorded before tests: '; print: count value; cr.

m := (Smalltalk at: #OilTestModel) new.

"--- T1: back jump counter threshold (65535) and trip-once semantics ---"
warm := (1 to: 5) collect: [:i | m countTo: 0]. "jit countTo: without executing its back jump"
beforeCount := (recordsFor value: mCountTo) size.
check value: 'countTo: 65534 computes correctly' value: (m countTo: 65534) = 65534.
check value: 'no trip after 65534 back jumps' value: (recordsFor value: mCountTo) size = beforeCount.
check value: 'countTo: 1 computes correctly' value: (m countTo: 1) = 1.
newRecs := recordsFor value: mCountTo.
check value: 'trip on the 65535th back jump' value: newRecs size = (beforeCount + 1).
newRecs notEmpty ifTrue:
	[rec := newRecs last.
	 check value: 'T1 trip kind is back jump (0)' value: (rec at: 1) = 0.
	 check value: 'T1 home method is countTo: itself (no closure involved)' value: (rec at: 3) == mCountTo.
	 check value: 'T1 no home context' value: (rec at: 4) isNil].
check value: 'countTo: 200000 computes correctly' value: (m countTo: 200000) = 200000.
check value: 'counter trips only once' value: (recordsFor value: mCountTo) size = (beforeCount + 1).

"--- T2: frameful block entry inside a collection iteration; home method via homeContext ---"
small := OrderedCollection new. 1 to: 10 do: [:i | small add: ((Smalltalk at: #OilTestItem) new score: i)].
warm := (1 to: 5) collect: [:i | m sumScores: small].
oc := OrderedCollection new.
"Leading spare capacity: remove from the front so the backing array starts with nils."
1 to: 100 do: [:i | oc add: ((Smalltalk at: #OilTestItem) new score: 0)].
1 to: 70000 do: [:i | oc add: ((Smalltalk at: #OilTestItem) new score: 1)].
1 to: 100 do: [:i | oc removeFirst].
check value: 'sumScores: computes correctly' value: (m sumScores: oc) = 70000.
check value: 'T2 #score send in [] in sumScores: is linked monomorphically' value: ((blkSum oilMonomorphicTargetAt: pc) isArray).
newRecs := recordsFor value: blkSum.
check value: 'block entry of [] in sumScores: tripped once' value: newRecs size = 1.
newRecs notEmpty ifTrue:
	[rec := newRecs last.
	 check value: 'T2 trip kind is block entry (1)' value: (rec at: 1) = 1.
	 check value: 'T2 home method is sumScores: (outer method framing the loop)' value: (rec at: 3) == mSumScores.
	 check value: 'T2 home context is a sumScores: context' value: (((rec at: 4) isKindOf: Context) and: [(rec at: 4) method == mSumScores]).
	 check value: 'T2 sampled element is a live OilTestItem' value: (((rec at: 5) isKindOf: (Smalltalk at: #OilTestItem)) and: [(rec at: 6) == (Smalltalk at: #OilTestItem)])].

"--- T3: back jump in an iterator whose argument is a closure; currentPosition sampling ---"
items := (1 to: 70000) collect: [:i | (Smalltalk at: #OilTestItem) new score: 2].
m items: ((1 to: 10) collect: [:i | (Smalltalk at: #OilTestItem) new score: 2]).
warm := (1 to: 5) collect: [:i | m mySumScores].
m items: items.
check value: 'mySumScores computes correctly' value: m mySumScores = 140000.
newRecs := recordsFor value: mMyDo.
check value: 'back jump in myDo: tripped once' value: newRecs size = 1.
newRecs notEmpty ifTrue:
	[rec := newRecs last.
	 check value: 'T3 trip kind is back jump (0)' value: (rec at: 1) = 0.
	 check value: 'T3 home method is mySumScores (home of the closure argument)' value: (rec at: 3) == mMySum.
	 check value: 'T3 home context is a mySumScores context' value: (((rec at: 4) isKindOf: Context) and: [(rec at: 4) method == mMySum]).
	 check value: 'T3 sample is items at: currentPosition (an OilTestItem)' value: (((rec at: 5) isKindOf: (Smalltalk at: #OilTestItem)) and: [(rec at: 6) == (Smalltalk at: #OilTestItem)])].
newRecs := recordsFor value: blkMySum.
check value: 'block entry of [] in mySumScores tripped once with home mySumScores' value: (newRecs size = 1 and: [(newRecs last at: 3) == mMySum]).

"--- T4: monomorphicTargetFor:in: (inline cache query) ---"
check value: 'found the #score send in [] in sumScores:' value: pc notNil.
"Any full GC flushes the method cache, which unlinks all sends (CoInterpreter>>flushMethodCache),
 so re-run sumScores: to relink its sends before querying the inline cache."
warm := (1 to: 5) collect: [:i | m sumScores: small].
target := blkSum oilMonomorphicTargetAt: pc.
out nextPutAll: 'monomorphic target of #score in [] in sumScores: '; print: target; cr.
check value: 'monomorphic send answers {OilTestItem. OilTestItem>>score}' value: ((target isArray and: [target first == (Smalltalk at: #OilTestItem) and: [target last == ((Smalltalk at: #OilTestItem) >> #score)]])).
"A polymorphic send site answers nil."
poly := OrderedCollection new.
1 to: 20 do: [:i | poly add: ((Smalltalk at: (i odd ifTrue: [#OilTestItem] ifFalse: [#OilTestItem2])) new score: 1)].
warm := (1 to: 10) collect: [:i | m polySum: poly].
check value: 'polySum: computes correctly' value: (m polySum: poly) = 30.
blk := ((Smalltalk at: #OilTestModel) >> #polySum:) literals detect: [:l | l isCompiledCode].
check value: 'polymorphic send answers nil' value: (blk oilMonomorphicTargetAt: pc) isNil.
check value: 'non-send pc answers nil' value: (blkSum oilMonomorphicTargetAt: 1) isNil.

"--- T5: GC robustness of counters and the trip log ---"
Smalltalk garbageCollect.
Smalltalk garbageCollect.
newRecs := recordsFor value: blkSum.
check value: 'trip log survives full GCs' value: (newRecs size = 1 and: [(newRecs last at: 3) == mSumScores]).
check value: 'sumScores: still correct after GC' value: (m sumScores: oc) = 70000.
check value: 'jitted code still runs after GC' value: (m countTo: 100000) = 100000.
3 timesRepeat: [1 to: 200000 do: [:i | Array new: 10]. Smalltalk garbageCollectMost].
check value: 'log still installed after scavenges' value: (Smalltalk at: #OilTestModel) oilTripLog == log.

(Smalltalk at: #OilTestModel) oilTripLog: nil.
out nextPutAll: 'total trips recorded: '; print: count value; cr.
out nextPutAll: (failures isEmpty ifTrue: ['ALL PASSED'] ifFalse: ['FAILURES: ', failures size printString]); cr.
(FileStream forceNewFileNamed: resultPath) nextPutAll: out contents; close.
failures isEmpty ifFalse: [self error: 'Oil M1 test failures: ', failures size printString]
