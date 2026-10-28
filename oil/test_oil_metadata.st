"Oil end-to-end test (native) of the compact deoptimization metadata.  The metadata of an Oil method is a
 hidden pinned object of CompiledMethod format: a literal frame (the root method, the inlined selectors, the methods of
 the inlined frames, CompiledBlocks, classes, constants), which the garbage collectors trace like a method's, then bytes
 (the frame, virtual object and site records, 2-byte descriptors, the spill offsets of the spilled registers only).
 Checks the size of the metadata of typical methods, and that
 deoptimization still works after scavenges and full GCs moved the objects its literals refer to (methods compiled by
 this test, so young when Oil compiles the root, and literal objects), with closures and scalar replaced objects.
 Run with run-st.sh on a Squeak 6.x 64-bit image with the Oil VM.  Writes oil-metadata-result.txt next to the image."
| out failures check sels cls model item other res last info sizes garbage items r holes before |
Utilities authorInitials: 'cb'.
out := FileStream forceNewFileNamed: (FileDirectory default fullNameFor: 'oil-metadata-result.txt').
failures := OrderedCollection new.
check := [:name :bool |
	out nextPutAll: (bool == true ifTrue: ['PASS '] ifFalse: ['FAIL ']); nextPutAll: name; cr; flush.
	bool == true ifFalse: [failures add: name]].
Object subclass: #OilMetadataItem instanceVariableNames: 'score' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
Object subclass: #OilMetadataOther instanceVariableNames: 'score' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
Object subclass: #OilMetadataModel instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
item := Smalltalk at: #OilMetadataItem. other := Smalltalk at: #OilMetadataOther. cls := Smalltalk at: #OilMetadataModel.
item compile: 'score ^score' classified: 'tests'.
item compile: 'score: n score := n' classified: 'tests'.
item compile: 'bonus: k ^score * k + #(''a literal'' 7) size' classified: 'tests'.
other compile: 'score ^1000' classified: 'tests'.
other compile: 'bonus: k ^1000 + k' classified: 'tests'.
#('sumScores: a | s | s := 0. 1 to: a size do: [:i | s := s + (a at: i) score]. ^s'
  'sumBonus: a | s | s := 0. 1 to: a size do: [:i | s := s + ((a at: i) bonus: i)]. ^s'
  'pointSum: a | s | s := 0. 1 to: a size do: [:i | | p | p := (a at: i) score @ i. s := s + p x + p y]. ^s'
  'blockSum: a | s | s := 0. a do: [:e | s := s + e score]. ^s'
  'injectSum: a ^a inject: 0 into: [:acc :e | acc + (e bonus: 2)]')
	do: [:src | cls compile: src classified: 'tests'].
cls class compile: 'oilSetParameter: index to: value <primitive: ''primitiveOilGetOrSetParameter''> ^#failed' classified: 'oil'.
cls class compile: 'autonomousCompilation: aBoolean ^self oilSetParameter: 19 to: aBoolean' classified: 'oil'.
cls class compile: 'disqualifyLimit: anInteger ^self oilSetParameter: 8 to: anInteger' classified: 'oil'.
cls class compile: 'oilSetColdSelectors: anArray ^self oilSetParameter: 7 to: anArray' classified: 'oil'.
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
CompiledMethod compile: 'oilSpecializeFor: aClass <primitive: ''primitiveOilSpecialize''> ^#failed' classified: 'oil'.
CompiledMethod compile: 'oilCompileFor: aClass ^self oilSpecializeFor: aClass' classified: 'oil'.
CompiledMethod compile: 'oilInfo <primitive: ''primitiveOilMethodInfo''> ^#failed' classified: 'oil'.
CompiledMethod class compile: 'oilLastCompilation <primitive: ''primitiveOilLastCompilation''> ^#failed' classified: 'oil'.
sels := OrderedCollection new.
#(value value: value:value: value:value:value: value:value:value:value:) doWithIndex: [:s :i | sels add: i - 1; add: s].
sels add: 5; add: #bitXor:.
#(do: reverseDo: collect: select: reject: detect: detect:ifNone: inject:into: doWithIndex: withIndexDo: timesRepeat: to:do: to:by:do: scanFor: findElementOrNil:)
	do: [:s | sels add: 6; add: s].
#(error: errorNoFreeSpace errorSubscriptBounds: errorNotIndexable subclassResponsibility halt doesNotUnderstand: primitiveFailed makeRoomAtLast makeRoomAtFirst)
	do: [:s | sels add: 7; add: s].
check value: 'primitiveOilSetSelectors' value: (cls oilSetSelectors: sels asArray) ~~ #failed.
model := cls new.
items := (1 to: 100) collect: [:k | item new score: k; yourself].
info := [:sel | (cls >> sel) oilInfo].
sizes := Dictionary new.
"compile: warm up (baseline JIT), Oil-compile, note the metadata size"
res := [:sel | | cm |
	cm := cls >> sel.
	3 timesRepeat: [model perform: sel with: items].
	r := cm oilCompileFor: cls.
	last := CompiledMethod oilLastCompilation.
	sizes at: sel put: (last at: 12).
	out nextPutAll: sel; nextPutAll: ': oilCompileFor: -> '; print: r; nextPutAll: ', '; print: (last at: 5); nextPutAll: ' sites, ';
		print: (last at: 6); nextPutAll: ' frames, metadata '; print: (last at: 12); nextPutAll: ' bytes'; cr; flush.
	r].
#(sumScores: sumBonus: pointSum: blockSum: injectSum:) do: [:sel |
	check value: sel, ' compiles' value: (res value: sel) = 0.
	check value: sel, ' has Oil code' value: (info value: sel) notNil].
"(the bounds include the sites of the interrupt checks of the loops, about 20 bytes each, see genPollBefore:)"
check value: 'sumScores: metadata <= 480 bytes' value: ((sizes at: #sumScores:) <= 480).
check value: 'sumBonus: metadata <= 480 bytes' value: ((sizes at: #sumBonus:) <= 480).
out nextPutAll: 'total metadata '; print: (sizes values inject: 0 into: [:a :size | a + size]); nextPutAll: ' bytes'; cr.
"results with the Oil code"
check value: 'sumScores: = 5050' value: (model sumScores: items) = 5050.
check value: 'sumBonus: = expected' value: (model sumBonus: items) = ((1 to: 100) inject: 0 into: [:a :k | a + (k * k) + 2]).
check value: 'pointSum: = expected' value: (model pointSum: items) = ((1 to: 100) inject: 0 into: [:a :k | a + k + k]).
check value: 'blockSum: = 5050' value: (model blockSum: items) = 5050.
check value: 'injectSum: = expected' value: (model injectSum: items) = ((1 to: 100) inject: 0 into: [:a :k | a + (2 * k) + 2]).
"move objects: scavenges (the methods compiled above were young when the metadata was filled) and full GCs (compaction)"
garbage := nil.
1 to: 200000 do: [:k | garbage := Array new: 20].
Smalltalk garbageCollect.
1 to: 200000 do: [:k | garbage := Array new: 20].
Smalltalk garbageCollect.
"deoptimize (a class guard fails in the middle of each loop): the frames are rebuilt from the metadata"
items at: 50 put: (other new).
check value: 'sumScores: deopt after GCs' value: (model sumScores: items) = (5050 - 50 + 1000).
check value: 'sumBonus: deopt after GCs' value: (model sumBonus: items) = ((1 to: 100) inject: 0 into: [:a :k | a + (k = 50 ifTrue: [1000 + k] ifFalse: [(k * k) + 2])]).
check value: 'pointSum: deopt after GCs' value: (model pointSum: items) = ((1 to: 100) inject: 0 into: [:a :k | a + (k = 50 ifTrue: [1000] ifFalse: [k]) + k]).
check value: 'blockSum: deopt after GCs' value: (model blockSum: items) = (5050 - 50 + 1000).
check value: 'injectSum: deopt after GCs' value: (model injectSum: items) = ((1 to: 100) inject: 0 into: [:a :k | a + (k = 50 ifTrue: [1002] ifFalse: [(2 * k) + 2])]).
check value: 'deopts counted in the metadata' value: (#(sumScores: sumBonus: pointSum: blockSum: injectSum:) allSatisfy: [:sel | (info value: sel) isNil or: [((info value: sel) at: 1) >= 1]]).
"Verify the metadata is not pinned.  Allocate old objects, Oil-compile a method (its metadata lands after them),
 free them and run a full GC: the compaction slides the metadata down, and the method's reference to it must follow."
holes := (1 to: 3000) collect: [:k | Array new: 200].
Smalltalk garbageCollect.
cls compile: 'sumScores2: a | s | s := 0. 1 to: a size do: [:i | s := s + (a at: i) score]. ^s' classified: 'tests'.
items at: 50 put: (item new score: 50; yourself).
check value: 'sumScores2: compiles after old objects' value: (res value: #sumScores2:) = 0.
before := (info value: #sumScores2:) at: 4.
holes := nil.
Smalltalk garbageCollect.
Smalltalk garbageCollect.
check value: 'sumScores2: still Oil code after the compaction' value: ((info value: #sumScores2:) ifNil: [false] ifNotNil: [:i | (i at: 4) = before and: [(i at: 1) = 0]]).
check value: 'sumScores2: = 5050 after the compaction' value: (model sumScores2: items) = 5050.
items at: 50 put: (other new).
check value: 'sumScores2: deopt after the compaction (metadata moved)' value: (model sumScores2: items) = (5050 - 50 + 1000).
check value: 'sumScores2: deopt counted in the moved metadata' value: ((info value: #sumScores2:) isNil or: [((info value: #sumScores2:) at: 1) = 1]).
items at: 50 put: (item new score: 50; yourself).
"recompile and redefine an inlined method: the inlined frames' methods (literals) invalidate the Oil code"
check value: 'sumBonus: recompiles' value: (res value: #sumBonus:) = 0.
item compile: 'bonus: k ^score * k + 3' classified: 'tests'.
check value: 'sumBonus: after redefining bonus:' value: (model sumBonus: items) = ((1 to: 100) inject: 0 into: [:a :k | a + (k * k) + 3]).
Smalltalk voidCogVMState.
check value: 'voidCogVMState' value: (model sumScores: items) = 5050.
out nextPutAll: (failures isEmpty ifTrue: ['ALL PASS'] ifFalse: ['FAILURES: ', failures size printString]); cr.
out close.
failures isEmpty ifFalse: [self error: 'Oil metadata test failures: ', failures printString]
