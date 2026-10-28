"ProfilingCogit end-to-end test: the trip counters and autonomous compilation (Milestone 15).  A counter trips at the
 8191st execution of its site (a loop back jump), and the trip compiles the home method of the
 tripping frame with Oil (the method itself; for a block, or an iterator whose argument is a closure, the home method of
 the closure) and installs its Oil code for its next activations, while the running activations finish in the baseline
 code (see CoInterpreter>>ceOilTrip: and oilAutoCompile:receiver:).  Run with run-st.sh on a Squeak 6.x 64-bit image
 using the VM built from src/spur64.oil.  Writes oil-m1-result.txt into the image's directory and signals an error if any
 check fails."
| resultPath out failures check m oc small items warm hasOil cls mCountTo mSumScores mMySum mMyDo mPolySum mOffSum ocDo |
Utilities authorInitials: 'cb'.
resultPath := FileDirectory default fullNameFor: 'oil-m1-result.txt'.
out := WriteStream on: String new.
failures := OrderedCollection new.
check := [:name :bool |
	out nextPutAll: (bool == true ifTrue: ['PASS '] ifFalse: ['FAIL ']); nextPutAll: name; cr.
	bool == true ifFalse: [failures add: name]].

"--- Test classes ---"
Object subclass: #OilCoreSimulationItem instanceVariableNames: 'score' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
(Smalltalk at: #OilCoreSimulationItem) compile: 'score ^score' classified: 'accessing'.
(Smalltalk at: #OilCoreSimulationItem) compile: 'score: aNumber score := aNumber' classified: 'accessing'.
(Smalltalk at: #OilCoreSimulationItem) subclass: #OilCoreSimulationItem2 instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
(Smalltalk at: #OilCoreSimulationItem2) compile: 'score ^score * 2' classified: 'accessing'.
Object subclass: #OilCoreSimulationModelTest instanceVariableNames: 'items' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
cls := Smalltalk at: #OilCoreSimulationModelTest.
cls compile: 'items: anArray items := anArray' classified: 'accessing'.
cls compile: 'countTo: n | count | count := 0. 1 to: n do: [:i | count := count + 1]. ^count' classified: 'tests'.
cls compile: 'sumScores: aCollection | total | total := 0. aCollection do: [:each | total := total + each score]. ^total' classified: 'tests'.
cls compile: 'polySum: aCollection | total | total := 0. aCollection do: [:each | total := total + each score]. ^total' classified: 'tests'.
cls compile: 'offSum: n | total | total := 0. 1 to: n do: [:i | total := total + i]. ^total' classified: 'tests'.
cls compile: 'myDo: aBlock 1 to: items size do: [:i | aBlock value: (items at: i)]' classified: 'tests'.
cls compile: 'mySumScores | total | total := 0. self myDo: [:each | total := total + each score]. ^total' classified: 'tests'.
cls class compile: 'oilSetParameter: index to: value <primitive: ''primitiveOilGetOrSetParameter''> ^#failed' classified: 'oil'.
cls class compile: 'oilSetParameter: index <primitive: ''primitiveOilGetOrSetParameter''> ^#failed' classified: 'oil'.
cls class compile: 'autonomousCompilation: aBoolean ^self oilSetParameter: 19 to: aBoolean' classified: 'oil'.
cls class compile: 'disqualifyLimit: anInteger ^self oilSetParameter: 8 to: anInteger' classified: 'oil'.
cls class compile: 'oilSetColdSelectors: anArray ^self oilSetParameter: 7 to: anArray' classified: 'oil'.
cls class compile: 'oilColdSelectors ^self oilSetParameter: 7' classified: 'oil'.
CompiledMethod compile: 'oilInfo <primitive: ''primitiveOilMethodInfo''> ^#failed' classified: 'oil'.
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

mCountTo := cls >> #countTo:.
mSumScores := cls >> #sumScores:.
mPolySum := cls >> #polySum:.
mOffSum := cls >> #offSum:.
mMySum := cls >> #mySumScores.
mMyDo := cls >> #myDo:.
ocDo := OrderedCollection >> #do:.
hasOil := [:aMethod | aMethod oilInfo notNil].
check value: 'primitiveOilGetOrSetParameter available (VM has ProfilingCogit)' value: (cls autonomousCompilation: true) ~~ #failed.
check value: 'primitiveOilMethodInfo available' value: mCountTo oilInfo ~~ #failed.

m := cls new.

"--- T1: back jump counter threshold (8191): the trip compiles the method; the running activation finishes in the baseline code ---"
warm := (1 to: 5) collect: [:i | m countTo: 0]. "jit countTo: without executing its back jump"
check value: 'countTo: 8190 computes correctly' value: (m countTo: 8190) = 8190.
check value: 'no trip after 8190 back jumps: no Oil code' value: (hasOil value: mCountTo) not.
check value: 'countTo: 1 computes correctly (the 8191st back jump trips)' value: (m countTo: 1) = 1.
check value: 'T1 the trip installed Oil code for countTo: (no closure involved)' value: (hasOil value: mCountTo).
check value: 'countTo: 200000 computes correctly in the Oil code' value: (m countTo: 200000) = 200000.
check value: 'countTo: still Oil code' value: (hasOil value: mCountTo).
"a single activation that trips in the middle of its loop finishes correctly in the baseline code"
warm := (1 to: 5) collect: [:i | m offSum: 0].
check value: 'offSum: tripping in the middle of its loop computes correctly' value: (m offSum: 100000) = 5000050000.
check value: 'offSum: then has Oil code' value: (hasOil value: mOffSum).
check value: 'offSum: in the Oil code computes correctly' value: (m offSum: 100000) = 5000050000.

"--- T2: a block evaluated by a collection iteration (OrderedCollection>>do:): its home method is compiled ---"
small := OrderedCollection new. 1 to: 10 do: [:i | small add: ((Smalltalk at: #OilCoreSimulationItem) new score: i)].
warm := (1 to: 5) collect: [:i | m sumScores: small].
oc := OrderedCollection new.
"Leading spare capacity: remove from the front so the backing array starts with nils."
1 to: 100 do: [:i | oc add: ((Smalltalk at: #OilCoreSimulationItem) new score: 0)].
1 to: 70000 do: [:i | oc add: ((Smalltalk at: #OilCoreSimulationItem) new score: 1)].
1 to: 100 do: [:i | oc removeFirst].
check value: 'sumScores: computes correctly (tripping)' value: (m sumScores: oc) = 70000.
check value: 'T2 the home method sumScores: got Oil code' value: (hasOil value: mSumScores).
check value: 'T2 the iterator OrderedCollection>>do: did not (its closure argument''s home did)' value: (hasOil value: ocDo) not.
check value: 'sumScores: computes correctly in the Oil code' value: (m sumScores: oc) = 70000.

"--- T3: back jump in an iterator whose argument is a closure: the closure's home method is compiled ---"
items := (1 to: 70000) collect: [:i | (Smalltalk at: #OilCoreSimulationItem) new score: 2].
m items: ((1 to: 10) collect: [:i | (Smalltalk at: #OilCoreSimulationItem) new score: 2]).
warm := (1 to: 5) collect: [:i | m mySumScores].
m items: items.
check value: 'mySumScores computes correctly (tripping)' value: m mySumScores = 140000.
check value: 'T3 the home method mySumScores got Oil code' value: (hasOil value: mMySum).
check value: 'T3 the iterator myDo: did not' value: (hasOil value: mMyDo) not.
check value: 'mySumScores computes correctly in the Oil code' value: m mySumScores = 140000.

"--- T4: autonomous compilation off (parameter 19 = 0): trips compile nothing ---"
check value: 'autonomous compilation off' value: (cls oilSetParameter: 19 to: 0) ~~ #failed.
warm := (1 to: 5) collect: [:i | m polySum: small].
check value: 'polySum: computes correctly' value: (m polySum: oc) = 70000.
check value: 'T4 no Oil code for polySum:' value: (hasOil value: mPolySum) not.
cls oilSetParameter: 19 to: 1.

"--- T5: GC robustness of the counters and of the installed Oil code ---"
Smalltalk garbageCollect.
Smalltalk garbageCollect.
check value: 'sumScores: still Oil code after full GCs' value: (hasOil value: mSumScores).
check value: 'sumScores: still correct after GC' value: (m sumScores: oc) = 70000.
check value: 'countTo: still correct after GC' value: (m countTo: 100000) = 100000.
3 timesRepeat: [1 to: 200000 do: [:i | Array new: 10]. Smalltalk garbageCollectMost].
check value: 'mySumScores still correct after scavenges' value: m mySumScores = 140000.
Smalltalk voidCogVMState.
check value: 'voidCogVMState frees the Oil code' value: (hasOil value: mSumScores) not.
check value: 'sumScores: correct after voidCogVMState' value: (m sumScores: oc) = 70000.

"--- T6: the cold selectors (built in, or the image's) and the parameters ---"
check value: 'oilColdSelectors: none set (the built-in list)' value: cls oilColdSelectors isNil.
check value: 'oilSetColdSelectors: answers the previous list (none)' value: (cls oilSetColdSelectors: #(foo: bar)) isNil.
check value: 'oilColdSelectors: answers the list set' value: cls oilColdSelectors = #(foo: bar).
check value: 'oilSetColdSelectors: nil (the built-in list) answers the previous list' value: (cls oilSetColdSelectors: nil) = #(foo: bar).
check value: 'oilColdSelectors: nil again' value: cls oilColdSelectors isNil.
check value: 'oilSetColdSelectors: rejects a non-Array' value: (cls oilSetColdSelectors: 3) == #failed.
check value: 'oilSetColdSelectors: rejects an Array of non-Symbols' value: ((cls oilSetColdSelectors: #(1 2)) == #failed and: [cls oilColdSelectors isNil]).
check value: 'autonomousCompilation: accepts true, false, 1 and 0' value: ({true. false. 1. 0} allSatisfy: [:flag | (cls autonomousCompilation: flag) ~~ #failed]).
check value: 'autonomousCompilation: rejects anything else' value: ((cls autonomousCompilation: 2) == #failed and: [(cls autonomousCompilation: nil) == #failed]).
check value: 'disqualifyLimit: accepts an integer, rejects anything else' value: ((cls disqualifyLimit: 0) ~~ #failed and: [(cls disqualifyLimit: nil) == #failed]).

"--- T7: autonomous multi-specialization of an inherited method across multiple receiver subclasses ---"
cls autonomousCompilation: true.
cls subclass: #OilCoreSimulationModelSub instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
[| sub specs |
 sub := (Smalltalk at: #OilCoreSimulationModelSub) new.
 1 to: 5 do: [:i | m countTo: 0. sub countTo: 0].
 check value: 'T7 trip countTo: on OilCoreSimulationModelTest' value: (m countTo: 10000) = 10000.
 check value: 'T7 countTo: has 1 specialization (OilCoreSimulationModelTest)' value: mCountTo oilSpecializations size = 2.
 check value: 'T7 trip countTo: on OilCoreSimulationModelSub' value: (sub countTo: 10000) = 10000.
 specs := mCountTo oilSpecializations.
 check value: 'T7 countTo: has 2 specializations (OilCoreSimulationModelTest and OilCoreSimulationModelSub)'
	value: (specs size = 4 and: [(specs at: 1) == cls and: [(specs at: 3) == (Smalltalk at: #OilCoreSimulationModelSub)]]).
 check value: 'T7 both specializations have Oil code and run with 0 deopts'
	value: (((m countTo: 50000) = 50000) and: [((sub countTo: 50000) = 50000)
		and: [((specs at: 2) oilInfo at: 1) = 0 and: [((specs at: 4) oilInfo at: 1) = 0]]])] value.

out nextPutAll: (failures isEmpty ifTrue: ['ALL PASSED'] ifFalse: ['FAILURES: ', failures size printString]); cr.
(FileStream forceNewFileNamed: resultPath) nextPutAll: out contents; close.
failures isEmpty ifFalse: [self error: 'Oil M1/M15 test failures: ', failures printString]
