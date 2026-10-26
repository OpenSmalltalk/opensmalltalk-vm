"Oil end-to-end test (native) of Milestone 8: scalar replacement of objects (Points and Associations dissolved into
 registers, materialized with OilNewObject only where they escape, sharing eden bump allocations, rematerialized when
 deoptimizing), bimorphic inlining (a class test with both methods inlined; a predicate answering true for one class and
 false for the other compiled to the class test itself, OilCmpClass), and the sends removed from Set and Dictionary probes
 (String>>hash inlined as OilStringHash, Behavior>>identityHash and the hash of a literal folded).
 Run with run-st.sh on a Squeak 6.x 64-bit image with the Oil VM.  Writes oil-m8-result.txt next to the image."
| out failures check sels model cls res last ir opcodes countOps r t base oil n times stats statsOf syms set dict keys
  expected latencies compileUs probeArray mixed ab info irNames dump |
Utilities authorInitials: 'cb'.
out := FileStream forceNewFileNamed: (FileDirectory default fullNameFor: 'oil-m8-result.txt').
failures := OrderedCollection new.
check := [:name :bool |
	out nextPutAll: (bool == true ifTrue: ['PASS '] ifFalse: ['FAIL ']); nextPutAll: name; cr; flush.
	bool == true ifFalse: [failures add: name]].
Object subclass: #OilM8Model instanceVariableNames: 'total' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
Object subclass: #OilM8A instanceVariableNames: 'x' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
Object subclass: #OilM8B instanceVariableNames: 'y' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
(Smalltalk at: #OilM8A) compile: 'oilM8Size ^3' classified: 'tests'.
(Smalltalk at: #OilM8B) compile: 'oilM8Size ^y * 2 + 1' classified: 'tests'.
(Smalltalk at: #OilM8B) compile: 'y: v y := v' classified: 'tests'.
(Smalltalk at: #OilM8A) compile: 'oilM8Maybe ^nil' classified: 'tests'.
(Smalltalk at: #OilM8B) compile: 'oilM8Maybe ^self' classified: 'tests'.
(Smalltalk at: #OilM8B) subclass: #OilM8C instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
cls := Smalltalk at: #OilM8Model.
#('pointSum: n | s | s := 0. 1 to: n do: [:i | | p | p := i @ (i + 1). s := s + p x + p y]. ^s'
  'pointNew: n | s | s := 0. 1 to: n do: [:i | | p | p := Point x: i y: 3. s := s + (p x * p y)]. ^s'
  'assocSum: n | s | s := 0. 1 to: n do: [:i | | a | a := i -> (i * 2). s := s + a key + a value]. ^s'
  'pointAdd: n | s | s := 0 @ 0. 1 to: n do: [:i | s := s + (i @ 1)]. ^s x + s y'
  'pointEscape: n | a | a := Array new: n. 1 to: n do: [:i | a at: i put: i @ i]. ^a'
  'pairs: n | a | a := Array new: n. 1 to: n do: [:i | a at: i put: i -> (i @ i)]. ^a'
  'deoptPoint: x | p | p := 7 @ 8. ^(x + 1) + p x'
  'deoptEscape: x | p | p := 7 @ x. ^{x + 1. p}'
  'pointEq: n ^(n @ 1) == (n @ 1)'
  'isSymCount: coll | c | c := 0. coll do: [:e | e isSymbol ifTrue: [c := c + 1]]. ^c'
  'sizeSum: coll | s | s := 0. coll do: [:e | s := s + e oilM8Size]. ^s'
  'nilCount: coll | c | c := 0. coll do: [:e | e oilM8Maybe ifNil: [c := c + 1] ifNotNil: [c := c + 10]]. ^c'
  'count: keys in: aSet | n | n := 0. 1 to: keys size do: [:i | (aSet includes: (keys at: i)) ifTrue: [n := n + 1]]. ^n'
  'sum: keys in: aDict | s | s := 0. 1 to: keys size do: [:i | s := s + (aDict at: (keys at: i) ifAbsent: [0])]. ^s'
  'symHash: s ^s hash'
  'constHash ^#foo hash'
  'hashProbe: anArray key: key | index length element | length := anArray size. index := (key hash \\ length) + 1. [element := anArray at: index. element == nil ifTrue: [^index]. element == key ifTrue: [^index]. index := index \\ length + 1] repeat'
  'probeLoop: anArray n: n | s | s := 0. 1 to: n do: [:i | s := s + (self hashProbe: anArray key: 68000)]. ^s'
  'ocAddTo: oc n: n 1 to: n do: [:i | oc add: i]. ^oc'
  'total: n total := n')
	do: [:s | cls compile: s classified: 'tests'].
cls class compile: 'oilSetColdSelectors: anArray <primitive: ''primitiveOilSetColdSelectors''> ^#failed' classified: 'oil'.
cls class compile: 'oilSetParameter: index to: value <primitive: ''primitiveOilSetParameter''> ^#failed' classified: 'oil'.
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
CompiledMethod compile: 'oilCompileFor: aClass <primitive: ''primitiveOilCompile''> ^#failed' classified: 'oil'.
CompiledMethod compile: 'oilInfo <primitive: ''primitiveOilMethodInfo''> ^#failed' classified: 'oil'.
CompiledMethod class compile: 'oilLastCompilation <primitive: ''primitiveOilLastCompilation''> ^#failed' classified: 'oil'.
sels := OrderedCollection new.
#(value value: value:value: value:value:value: value:value:value:value:) doWithIndex: [:s :i | sels add: i - 1; add: s].
sels add: 5; add: #bitXor:.
#(do: reverseDo: collect: select: reject: detect: detect:ifNone: inject:into: doWithIndex: withIndexDo: timesRepeat: to:do: to:by:do: scanFor: findElementOrNil:)
	do: [:s | sels add: 6; add: s].
#(error: errorNoFreeSpace errorSubscriptBounds: errorNotIndexable subclassResponsibility halt doesNotUnderstand: primitiveFailed makeRoomAtLast makeRoomAtFirst)
	do: [:s | sels add: 7; add: s].
sels add: 9; add: ByteString class >> #indexOfAscii:inString:startingAt:.
sels add: 10; add: PositionableStream >> #skipSeparators.
sels add: 11; add: ReadStream.
sels add: 12; add: 3. "no loop unrolling (M9, see test_oil_m9.st): these checks count the instructions of loops"
check value: 'primitiveOilSetSelectors' value: (cls oilSetSelectors: sels asArray) ~~ #failed.
model := cls new total: 7; yourself.
"opcodes: the opcode numbers of the last compilation's (Pass 2) IR; countOps: how many of the given opcodes"
opcodes := [| words i ops op |
	words := (CompiledMethod oilLastCompilation) at: 2.
	ops := OrderedCollection new. i := 1.
	[i <= words size] whileTrue:
		[op := (words at: i) bitShift: -24.
		 ops add: op.
		 i := i + ((#(2 20 22 23 41 42 48 50 51 52 54) includes: op)
				ifTrue: [3]
				ifFalse: [op = 28 ifTrue: [4] ifFalse: [op = 53 ifTrue: [5] ifFalse: [(#(24 30 49) includes: op) ifTrue: [3 + (((words at: i) bitAnd: 255) + 3 // 4)] ifFalse: [1]]]])].
	ops].
countOps := [:ops :wanted | ops count: [:op | wanted includes: op]].
irNames := #(ConstTagged Const64 Move AddTagged SubTagged AndTagged OrTagged XorTagged ShiftTagged OddTagged LoadField StoreField LoadElement StoreElement CmpTagged BranchTrue BranchFalse Jump Return GuardClass CheckBounds Call0 Call1 CallN AddImmTagged CmpImmTagged LoadSize MakeClosure NewArray CallSuper AddImmTaggedNC ModTagged LoadByteSize LoadByte LoadChar StoreByte StoreChar CompareBytes Trap CharValue StreamNext StreamNextPut AddFloat SubFloat MulFloat DivFloat CmpFloat IdentityHash IndexOfByte SkipSeparators NewObject CmpClass GuardClass2 StringHash).
"dump: the last compilation's (Pass 2) IR, for the record"
dump := [| words i op |
	words := (CompiledMethod oilLastCompilation) at: 2.
	i := 1.
	[i <= words size] whileTrue:
		[op := (words at: i) bitShift: -24.
		 out tab; print: i - 1; tab; nextPutAll: ((op between: 1 and: irNames size) ifTrue: [irNames at: op] ifFalse: ['?']); tab; print: ((words at: i) >> 16 bitAnd: 255); space; print: ((words at: i) >> 8 bitAnd: 255); space; print: ((words at: i) bitAnd: 255); cr.
		 i := i + ((#(2 20 22 23 41 42 48 50 51 52 54) includes: op)
				ifTrue: [3]
				ifFalse: [op = 28 ifTrue: [4] ifFalse: [op = 53 ifTrue: [5] ifFalse: [(#(24 30 49) includes: op) ifTrue: [3 + (((words at: i) bitAnd: 255) + 3 // 4)] ifFalse: [1]]]])].
	out flush].
"stats: Pass 1 and 3 statistics of the last compilation: {scalar replaced objects. materialized. bimorphic sends. bimorphic predicates. eager allocation sites. allocations sharing a threshold check}"
statsOf := [((CompiledMethod oilLastCompilation) at: 11) copyFrom: 12 to: 18].
"compile: warm up (baseline JIT), Oil-compile for OilM8Model, answer the result code"
res := [:sel :warm | | cm |
	cm := cls >> sel.
	3 timesRepeat: warm.
	t := Time microsecondsToRun: [r := cm oilCompileFor: cls].
	last := CompiledMethod oilLastCompilation.
	latencies add: sel -> {last at: 9. t}.
	ir := opcodes value.
	stats := statsOf value.
	out nextPutAll: sel; nextPutAll: ': oilCompileFor: -> '; print: r; nextPutAll: ' in '; print: (last at: 9); nextPutAll: ' us ('; print: ir size; nextPutAll: ' IR instructions, calls '; print: (countOps value: ir value: #(22 23 24 30)); nextPutAll: ', NewObject '; print: (countOps value: ir value: #(51)); nextPutAll: '); virtualized, materialized, bimorphic, predicates, eager sites, shared allocations, nil-or-object sends: '; print: stats; cr; flush.
	r].
times := [:block | | best | best := SmallInteger maxVal. 3 timesRepeat: [best := best min: (Time millisecondsToRun: block)]. best].
latencies := OrderedCollection new.
info := [:sel | (cls >> sel) oilInfo].

"--- 1. Scalar replacement: objects that do not escape are dissolved ---"
expected := model pointSum: 1000000.
base := times value: [model pointSum: 1000000].
check value: 'pointSum: compiles' value: (res value: #pointSum: value: [model pointSum: 100]) = 0.
check value: 'pointSum: the Point is dissolved (no allocation, no call)' value: ((stats at: 1) = 1 and: [(stats at: 2) = 0 and: [(countOps value: ir value: #(51 22 23 24 30)) = 0]]).
check value: 'pointSum: result' value: (model pointSum: 1000000) = expected.
oil := times value: [model pointSum: 1000000].
out nextPutAll: 'pointSum: 1000000 Points: Oil '; print: oil; nextPutAll: ' ms, baseline '; print: base; nextPutAll: ' ms'; cr; flush.
check value: 'pointSum: faster than baseline' value: oil < base.
check value: 'pointSum: no deopt' value: ((info value: #pointSum:) at: 1) = 0.
expected := model pointNew: 1000000.
base := times value: [model pointNew: 1000000].
check value: 'pointNew: (Point x:y:, a class constant) compiles' value: (res value: #pointNew: value: [model pointNew: 100]) = 0.
check value: 'pointNew: dissolved' value: ((stats at: 1) = 1 and: [(stats at: 2) = 0 and: [(countOps value: ir value: #(51 22 23 24 30)) = 0]]).
check value: 'pointNew: result' value: (model pointNew: 1000000) = expected.
oil := times value: [model pointNew: 1000000].
out nextPutAll: 'pointNew: 1000000 Points: Oil '; print: oil; nextPutAll: ' ms, baseline '; print: base; nextPutAll: ' ms'; cr; flush.
check value: 'pointNew: faster than baseline' value: oil < base.
expected := model assocSum: 1000000.
base := times value: [model assocSum: 1000000].
check value: 'assocSum: (Object>>->) compiles' value: (res value: #assocSum: value: [model assocSum: 100]) = 0.
check value: 'assocSum: dissolved' value: ((stats at: 1) = 1 and: [(stats at: 2) = 0 and: [(countOps value: ir value: #(51 22 23 24 30)) = 0]]).
check value: 'assocSum: result' value: (model assocSum: 1000000) = expected.
oil := times value: [model assocSum: 1000000].
out nextPutAll: 'assocSum: 1000000 Associations: Oil '; print: oil; nextPutAll: ' ms, baseline '; print: base; nextPutAll: ' ms'; cr; flush.
check value: 'assocSum: faster than baseline' value: oil < base.
check value: 'pointEq: compiles' value: (res value: #pointEq: value: [model pointEq: 3]) = 0.
check value: 'pointEq: two new objects are not identical (folded)' value: ((model pointEq: 3) == false and: [(countOps value: ir value: #(51)) = 0]).

"--- 2. Materialization where they escape: OilNewObject (slots written directly), shared eden bumps ---"
expected := model pointAdd: 200000.
Smalltalk garbageCollectMost.
base := times value: [model pointAdd: 200000].
check value: 'pointAdd: compiles' value: (res value: #pointAdd: value: [model pointAdd: 100]) = 0.
check value: 'pointAdd: the loop-carried sum is materialized once per iteration, its argument dissolved' value: ((stats at: 1) = 3 and: [(countOps value: ir value: #(51)) = 2 and: [(countOps value: ir value: #(22 23 24 30)) = 0]]).
check value: 'pointAdd: result' value: (model pointAdd: 200000) = expected.
Smalltalk garbageCollectMost.
oil := times value: [model pointAdd: 200000].
out nextPutAll: 'pointAdd: 200000 Point additions (within eden): Oil '; print: oil; nextPutAll: ' ms, baseline '; print: base; nextPutAll: ' ms'; cr; flush.
check value: 'pointAdd: faster than baseline' value: oil < base.
check value: 'pointAdd: no deopt (allocations beyond the scavenge threshold do not count)' value: ((info value: #pointAdd:) at: 1) = 0.
check value: 'pointEscape: compiles' value: (res value: #pointEscape: value: [model pointEscape: 10]) = 0.
check value: 'pointEscape: materialized' value: ((stats at: 2) = 1 and: [(countOps value: ir value: #(51)) = 1]).
r := model pointEscape: 300000.
check value: 'pointEscape: 300000 Points (several scavenges)' value: (r size = 300000 and: [(r allSatisfy: [:p | p class == Point]) and: [(1 to: r size) allSatisfy: [:k | (r at: k) = (k @ k)]]]).
check value: 'pairs: compiles' value: (res value: #pairs: value: [model pairs: 10]) = 0.
check value: 'pairs: two materializations sharing one threshold check' value: ((countOps value: ir value: #(51)) = 2 and: [(stats at: 6) >= 1]).
r := model pairs: 300000.
check value: 'pairs: 300000 Associations of Points' value: (r size = 300000 and: [(1 to: r size) allSatisfy: [:k | | as | as := r at: k. as class == Association and: [as key = k and: [as value class == Point and: [as value = (k @ k)]]]]]).
Smalltalk garbageCollect.
check value: 'pairs: after a full GC' value: ((model pairs: 1000) = (model pairs: 1000) and: [((model pairs: 1000) collect: [:as | as value x]) asArray = (1 to: 1000) asArray]).

"--- 3. Deoptimization with scalar replaced objects in the state: they are rematerialized ---"
check value: 'deoptPoint: compiles' value: (res value: #deoptPoint: value: [model deoptPoint: 3]) = 0.
check value: 'deoptPoint: dissolved' value: ((stats at: 1) = 1 and: [(countOps value: ir value: #(51)) = 0]).
check value: 'deoptPoint: SmallInteger' value: (model deoptPoint: 3) = 11.
check value: 'deoptPoint: a Float deoptimizes (the Point is rematerialized)' value: (model deoptPoint: 1.5) = 9.5.
check value: 'deoptPoint: one deopt' value: ((info value: #deoptPoint:) ifNil: [true] ifNotNil: [:i | (i at: 1) = 1]).
check value: 'deoptEscape: compiles' value: (res value: #deoptEscape: value: [model deoptEscape: 3]) = 0.
r := model deoptEscape: 3.
check value: 'deoptEscape: SmallInteger' value: (r first = 4 and: [r last class == Point and: [r last = (7 @ 3)]]).
r := model deoptEscape: 2.5.
check value: 'deoptEscape: a Float deoptimizes, the Point is rematerialized and escapes' value: (r first = 3.5 and: [r last class == Point and: [r last = (7 @ 2.5)]]).

"--- 4. Bimorphic inlining ---"
mixed := (1 to: 10000) collect: [:k | k odd ifTrue: [('sym', k printString) asSymbol] ifFalse: ['str', k printString]].
expected := model isSymCount: mixed.
check value: 'isSymCount: result before Oil' value: expected = 5000.
base := times value: [100 timesRepeat: [model isSymCount: mixed]].
check value: 'isSymCount: compiles' value: (res value: #isSymCount: value: [model isSymCount: mixed]) = 0.
check value: 'isSymCount: isSymbol (ByteSymbol ^true, ByteString ^false) is a class test: no call, no boolean'
	value: ((stats at: 4) = 1 and: [(countOps value: ir value: #(52)) = 1 and: [(countOps value: ir value: #(53)) = 1 and: [(countOps value: ir value: #(22 23 24 30)) = 0]]]).
check value: 'isSymCount: result' value: (model isSymCount: mixed) = expected.
oil := times value: [100 timesRepeat: [model isSymCount: mixed]].
out nextPutAll: 'isSymCount: 100 x 10000: Oil '; print: oil; nextPutAll: ' ms, baseline '; print: base; nextPutAll: ' ms'; cr; flush.
check value: 'isSymCount: faster than baseline' value: oil < base.
check value: 'isSymCount: no deopt' value: ((info value: #isSymCount:) at: 1) = 0.
check value: 'isSymCount: a third class deoptimizes, result' value: (model isSymCount: #(#a 1 'b' #c)) = 2.
ab := (1 to: 10000) collect: [:k | k odd ifTrue: [(Smalltalk at: #OilM8A) new] ifFalse: [(Smalltalk at: #OilM8B) new y: k; yourself]].
expected := model sizeSum: ab.
base := times value: [100 timesRepeat: [model sizeSum: ab]].
check value: 'sizeSum: compiles' value: (res value: #sizeSum: value: [model sizeSum: ab]) = 0.
check value: 'sizeSum: both methods inlined behind a class test' value: ((stats at: 3) = 1 and: [(countOps value: ir value: #(52)) = 1 and: [(countOps value: ir value: #(22 23 24 30)) = 0]]).
check value: 'sizeSum: result' value: (model sizeSum: ab) = expected.
oil := times value: [100 timesRepeat: [model sizeSum: ab]].
out nextPutAll: 'sizeSum: 100 x 10000: Oil '; print: oil; nextPutAll: ' ms, baseline '; print: base; nextPutAll: ' ms'; cr; flush.
check value: 'sizeSum: faster than baseline' value: oil < base.
check value: 'sizeSum: no deopt' value: ((info value: #sizeSum:) at: 1) = 0.

expected := model nilCount: ab.
base := times value: [100 timesRepeat: [model nilCount: ab]].
check value: 'nilCount: compiles' value: (res value: #nilCount: value: [model nilCount: ab]) = 0.
check value: 'nilCount: oilM8Maybe (OilM8A ^nil, OilM8B ^self) ifNil:ifNotNil: is the class test: no call, no nil test'
	value: ((stats at: 7) = 1 and: [(countOps value: ir value: #(52)) = 1 and: [(countOps value: ir value: #(53)) = 1 and: [(countOps value: ir value: #(22 23 24 30)) = 0]]]).
check value: 'nilCount: result' value: (model nilCount: ab) = expected.
oil := times value: [100 timesRepeat: [model nilCount: ab]].
out nextPutAll: 'nilCount: 100 x 10000: Oil '; print: oil; nextPutAll: ' ms, baseline '; print: base; nextPutAll: ' ms'; cr; flush.
check value: 'nilCount: faster than baseline' value: oil < base.
check value: 'nilCount: a third class deoptimizes, result' value: (model nilCount: {(Smalltalk at: #OilM8A) new. (Smalltalk at: #OilM8C) new. (Smalltalk at: #OilM8B) new}) = 21.

"--- 5. Set and Dictionary probes without sends ---"
{Set -> #scanFor:. Dictionary -> #scanFor:. Set -> #includes:. Dictionary -> #at:ifAbsent:. String -> #hash. Symbol -> #=. Object -> #enclosedSetElement. Association -> #key. Object -> #isSymbol. Symbol -> #isSymbol}
	do: [:as | (as key lookupSelector: as value) voidCogVMState].
syms := (1 to: 10000) collect: [:k | ('oilM8Sym', k printString) asSymbol].
set := Set new. syms doWithIndex: [:s :k | k odd ifTrue: [set add: s]].
dict := Dictionary new. syms doWithIndex: [:s :k | k \\ 3 = 0 ifTrue: [dict at: s put: k]].
check value: 'symHash: compiles' value: (res value: #symHash: value: [model symHash: #foo]) = 0.
check value: 'symHash: String>>hash inlined (OilStringHash), no call' value: ((countOps value: ir value: #(54)) = 1 and: [(countOps value: ir value: #(22 23 24 30)) = 0]).
check value: 'symHash: results' value: (syms allSatisfy: [:s | (model symHash: s) = s hash]).
check value: 'symHash: a ByteString' value: (model symHash: 'oilM8Sym1' copy) = #oilM8Sym1 hash.
check value: 'constHash compiles' value: (res value: #constHash value: [model constHash]) = 0.
check value: 'constHash: the hash of a literal Symbol is a constant' value: ((countOps value: ir value: #(54 22 23 24 30)) = 0 and: [model constHash = #foo hash]).
expected := model count: syms in: set.
check value: 'count:in: (Set) result before Oil' value: expected = 5000.
base := times value: [20 timesRepeat: [model count: syms in: set]].
check value: 'count:in: compiles' value: (res value: #count:in: value: [model count: syms in: set]) = 0.
dump value.
check value: 'count:in: inlines String>>hash; calls only on cold paths (errorNoFreeSpace, String>>= of a non-Symbol)' value: ((countOps value: ir value: #(54)) >= 1 and: [(countOps value: ir value: #(22 23 24 30)) <= 2]).
out nextPutAll: 'count:in: calls (all ops) '; print: (countOps value: ir value: #(22 23 24 30)); cr.
check value: 'count:in: result' value: (model count: syms in: set) = expected.
oil := times value: [20 timesRepeat: [model count: syms in: set]].
check value: 'count:in: no deopt' value: ((info value: #count:in:) at: 1) = 0.
out nextPutAll: 'Set includes: 20 x 10000 symbols: Oil '; print: oil; nextPutAll: ' ms, baseline '; print: base; nextPutAll: ' ms'; cr; flush.
check value: 'count:in: faster than baseline' value: oil < base.
expected := model sum: syms in: dict.
base := times value: [20 timesRepeat: [model sum: syms in: dict]].
check value: 'sum:in: (Dictionary) compiles' value: (res value: #sum:in: value: [model sum: syms in: dict]) = 0.
dump value.
check value: 'sum:in: inlines String>>hash' value: (countOps value: ir value: #(54)) >= 1.
out nextPutAll: 'sum:in: calls (all ops) '; print: (countOps value: ir value: #(22 23 24 30)); cr.
check value: 'sum:in: result' value: (model sum: syms in: dict) = expected.
oil := times value: [20 timesRepeat: [model sum: syms in: dict]].
check value: 'sum:in: no deopt' value: ((info value: #sum:in:) at: 1) = 0.
out nextPutAll: 'Dictionary at:ifAbsent: 20 x 10000 symbols: Oil '; print: oil; nextPutAll: ' ms, baseline '; print: base; nextPutAll: ' ms'; cr; flush.
check value: 'sum:in: faster than baseline' value: oil < base.
check value: 'count:in: with other keys (ByteStrings equal to the symbols)' value: (model count: ((syms first: 100) collect: [:s | s asString]) in: set) = 50.
probeArray := Array new: 8191.
1 to: 4000 do: [:k | probeArray at: (k * 17 \\ 8191) + 1 put: k * 17].
expected := model probeLoop: probeArray n: 1000000.
base := times value: [model probeLoop: probeArray n: 1000000].
check value: 'probeLoop:n: compiles' value: (res value: #probeLoop:n: value: [model probeLoop: probeArray n: 10]) = 0.
check value: 'probeLoop:n: no call' value: (countOps value: ir value: #(22 23 24 30)) = 0.
check value: 'probeLoop:n: result' value: (model probeLoop: probeArray n: 1000000) = expected.
oil := times value: [model probeLoop: probeArray n: 1000000].
out nextPutAll: 'probeLoop (hashProbe: x 1000000): Oil '; print: oil; nextPutAll: ' ms, baseline '; print: base; nextPutAll: ' ms'; cr; flush.

"--- 6. OrderedCollection>>add: inlined fast path (makeRoomAtLast is a call, a cold slow path) ---"
Smalltalk garbageCollect.
r := OrderedCollection new.
base := times value: [r := OrderedCollection new. model ocAddTo: r n: 1000000].
check value: 'ocAddTo:n: compiles' value: (res value: #ocAddTo:n: value: [model ocAddTo: OrderedCollection new n: 1000]) = 0.
dump value.
check value: 'ocAddTo:n: add: inlined, makeRoomAtLast the only call' value: (countOps value: ir value: #(22 23 24 30)) = 1.
r := model ocAddTo: OrderedCollection new n: 1000000.
check value: 'ocAddTo:n: result' value: (r size = 1000000 and: [r first = 1 and: [r last = 1000000 and: [(r at: 500000) = 500000]]]).
Smalltalk garbageCollect.
oil := times value: [r := OrderedCollection new. model ocAddTo: r n: 1000000].
out nextPutAll: 'ocAddTo:n: 1000000 add: Oil '; print: oil; nextPutAll: ' ms, baseline '; print: base; nextPutAll: ' ms'; cr; flush.
check value: 'ocAddTo:n: faster than baseline' value: oil < base.
check value: 'ocAddTo:n: no deopt' value: ((info value: #ocAddTo:n:) at: 1) = 0.
check value: 'ocAddTo:n: an OrderedCollection with room at the front' value: ((model ocAddTo: ((OrderedCollection new: 20) addFirst: 0; yourself) n: 50) asArray = (0 to: 50) asArray).

"--- 7. Robustness ---"
Smalltalk garbageCollect.
check value: 'full GC: results' value: ((model count: syms in: set) = 5000 and: [(model pointSum: 1000) = ((1 to: 1000) sum * 2 + 1000)
	and: [(model isSymCount: mixed) = 5000 and: [(model sizeSum: ab) = (ab inject: 0 into: [:s :e | s + e oilM8Size])]]]).
Smalltalk voidCogVMState.
check value: 'voidCogVMState: results' value: ((model count: syms in: set) = 5000 and: [(model pairs: 100) size = 100 and: [(model pointAdd: 1000) = (model pointAdd: 1000)]]).
out nextPutAll: 'compile latencies (us: compilation, whole primitive): '; print: latencies asArray; cr.
compileUs := (latencies collect: [:as | as value first]) asSortedCollection asArray.
out nextPutAll: 'compilation (Passes 1-3 + assembly) median '; print: (compileUs at: compileUs size + 1 // 2); nextPutAll: ' us, max '; print: compileUs last; nextPutAll: ' us'; cr.
check value: 'compilation latency: median below 1 ms' value: (compileUs at: compileUs size + 1 // 2) < 1000.
out nextPutAll: (failures isEmpty ifTrue: ['ALL PASS'] ifFalse: ['FAILURES: ', failures size printString]); cr.
out close.
failures isEmpty ifFalse: [self error: 'Oil M8 test failures: ', failures printString]
