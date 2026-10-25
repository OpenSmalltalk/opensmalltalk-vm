"Oil end-to-end test (native) of Milestone 7: method-level multi-specialization (several Oil versions of one method,
 one per receiver class, dispatched by the method's baseline code, which runs every other receiver), the identityHash
 intrinsic (IdentitySet and IdentityDictionary probes without sends), the word-at-a-time byte scans (upTo: and
 skipSeparators on ByteString streams), and their robustness (full GC, Smalltalk voidCogVMState, recompilation).
 Run with run-st.sh on a Squeak 6.x 64-bit image with the Oil VM.  Writes oil-m7-result.txt next to the image."
| out failures check sels model cls res last ir opcodes countOps r info t base oil n syms set dict keys expected text
  big specs oc times trips latencies seqDo classes colls ocDo sorted sub counts compileUs copy |
Utilities authorInitials: 'cb'.
out := FileStream forceNewFileNamed: (FileDirectory default fullNameFor: 'oil-m7-result.txt').
failures := OrderedCollection new.
check := [:name :bool |
	out nextPutAll: (bool == true ifTrue: ['PASS '] ifFalse: ['FAIL ']); nextPutAll: name; cr; flush.
	bool == true ifFalse: [failures add: name]].
Object subclass: #OilM7Model instanceVariableNames: 'total' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
cls := Smalltalk at: #OilM7Model.
#('count: syms in: aSet | n | n := 0. 1 to: syms size do: [:i | (aSet includes: (syms at: i)) ifTrue: [n := n + 1]]. ^n'
  'sum: keys in: aDict | s | s := 0. 1 to: keys size do: [:i | s := s + (aDict at: (keys at: i) ifAbsent: [0])]. ^s'
  'hashOf: anObject ^anObject identityHash'
  'scaledHashOf: anObject ^anObject scaledIdentityHash'
  'tokens: aString | in n | in := ReadStream on: aString. n := 0. [in skipSeparators. in atEnd] whileFalse: [in upTo: $;. n := n + 1]. ^n'
  'positions: aString | in out | in := ReadStream on: aString. out := OrderedCollection new. [in skipSeparators. out add: in position. in atEnd] whileFalse: [in upTo: $;. out add: in position]. ^out asArray'
  'upTo: c in: aString from: k | in | in := ReadStream on: aString. in position: k. ^{in upTo: c. in position}'
  'skip: aString from: k | in | in := ReadStream on: aString. in position: k. in skipSeparators. ^in position'
  'skipStream: aStream aStream skipSeparators. ^aStream position'
  'indexOf: c in: aString from: k ^aString indexOf: c startingAt: k'
  'countOf: aCollection | n | n := 0. aCollection do: [:e | n := n + 1]. ^n'
  'sumOf: aCollection | s | s := 0. aCollection do: [:e | s := s + e]. ^s'
  'total: n total := n')
	do: [:s | cls compile: s classified: 'tests'].
cls class compile: 'oilSetSelectors: anArray <primitive: ''primitiveOilSetSelectors''> ^#failed' classified: 'oil'.
cls class compile: 'oilTripLog: anArray <primitive: ''primitiveOilTripLog''> ^#failed' classified: 'oil'.
CompiledMethod compile: 'oilCompileFor: aClass <primitive: ''primitiveOilCompile''> ^#failed' classified: 'oil'.
CompiledMethod compile: 'oilSpecializeFor: aClass <primitive: ''primitiveOilSpecialize''> ^#failed' classified: 'oil'.
CompiledMethod compile: 'oilSpecializations <primitive: ''primitiveOilSpecializations''> ^#failed' classified: 'oil'.
CompiledMethod compile: 'oilInfo <primitive: ''primitiveOilMethodInfo''> ^#failed' classified: 'oil'.
CompiledMethod class compile: 'oilLastCompilation <primitive: ''primitiveOilLastCompilation''> ^#failed' classified: 'oil'.
sels := OrderedCollection new.
#(value value: value:value: value:value:value: value:value:value:value:) doWithIndex: [:s :i | sels add: i - 1; add: s].
sels add: 5; add: #bitXor:.
#(do: reverseDo: collect: select: reject: detect: detect:ifNone: inject:into: doWithIndex: withIndexDo: timesRepeat: to:do: to:by:do: scanFor: findElementOrNil:)
	do: [:s | sels add: 6; add: s].
#(error: errorNoFreeSpace errorSubscriptBounds: errorNotIndexable subclassResponsibility halt doesNotUnderstand: primitiveFailed)
	do: [:s | sels add: 7; add: s].
"the word-at-a-time byte scans: the methods they replace and the stream class"
sels add: 9; add: ByteString class >> #indexOfAscii:inString:startingAt:.
sels add: 10; add: PositionableStream >> #skipSeparators.
sels add: 11; add: ReadStream.
check value: 'primitiveOilSetSelectors' value: (cls oilSetSelectors: sels asArray) ~~ #failed.
model := cls new total: 7; yourself.
"opcodes: the opcode numbers of the last compilation's (Pass 2) IR; countOps: how many of the given opcodes"
opcodes := [| words i ops op |
	words := (CompiledMethod oilLastCompilation) at: 2.
	ops := OrderedCollection new. i := 1.
	[i <= words size] whileTrue:
		[op := (words at: i) bitShift: -24.
		 ops add: op.
		 i := i + ((#(2 20 22 23 41 42 48 50) includes: op)
				ifTrue: [3]
				ifFalse: [op = 28 ifTrue: [4] ifFalse: [(#(24 30 49) includes: op) ifTrue: [3 + (((words at: i) bitAnd: 255) + 3 // 4)] ifFalse: [1]]])].
	ops].
countOps := [:ops :wanted | ops count: [:op | wanted includes: op]].
"compile: warm up (baseline JIT), Oil-compile for OilM7Model, answer the result code"
res := [:sel :warm | | cm |
	cm := cls >> sel.
	3 timesRepeat: warm.
	t := Time microsecondsToRun: [r := cm oilCompileFor: cls].
	last := CompiledMethod oilLastCompilation.
	latencies add: sel -> {last at: 9. t}.
	ir := opcodes value.
	out nextPutAll: sel; nextPutAll: ': oilCompileFor: -> '; print: r; nextPutAll: ' in '; print: (last at: 9); nextPutAll: ' us (primitive '; print: t; nextPutAll: ' us)'; nextPutAll: ' ('; print: ir size; nextPutAll: ' IR instructions, calls '; print: (countOps value: ir value: #(22 23 24 30)); nextPutAll: ')'; cr; flush.
	r].
times := [:block | | best | best := SmallInteger maxVal. 3 timesRepeat: [best := best min: (Time millisecondsToRun: block)]. best].
"trips: how many trip counters of the baseline code of aMethod trip while running aBlock (Oil code has none)"
trips := [:aMethod :block | | log count |
	log := Array new: 6 * 1000 + 1. log at: 1 put: 0.
	cls oilTripLog: log.
	block value.
	cls oilTripLog: nil.
	count := 0.
	0 to: ((log at: 1) min: 1000) - 1 do: [:k | (log at: k * 6 + 3) == aMethod ifTrue: [count := count + 1]].
	count].
latencies := OrderedCollection new.

"--- 1. Method-level multi-specialization: one method, several Oil versions (one per receiver class), the baseline code for
 every other class (the 6th case) ---"
seqDo := SequenceableCollection >> #do:.
classes := #(#Array #ByteArray #WordArray #ByteString #ByteSymbol #DoubleWordArray #FloatArray #Float32Array #IntegerArray)
	inject: OrderedCollection new
	into: [:all :name | (Smalltalk at: name ifAbsent: [nil]) ifNotNil: [:c | ((c lookupSelector: #do:) == seqDo and: [all size < 6]) ifTrue: [all add: c]]. all].
check value: 'six collection classes inheriting SequenceableCollection>>do:' value: classes size = 6.
colls := classes collect: [:c | | inst | inst := c new: 300000. c == ByteSymbol ifTrue: [inst := (String new: 300000 withAll: $x) asSymbol]. inst].
counts := colls collect: [:c | model countOf: c].
check value: 'countOf: results before specialization' value: (counts allSatisfy: [:k | k = 300000]).
base := times value: [model countOf: colls first].
1 to: 5 do: [:k |
	3 timesRepeat: [colls do: [:c | model countOf: c]].
	t := Time microsecondsToRun: [r := seqDo oilSpecializeFor: (classes at: k)].
	latencies add: (classes at: k) name -> {(CompiledMethod oilLastCompilation) at: 9. t}.
	check value: 'specialize do: for ', (classes at: k) name value: r = 0].
out nextPutAll: 'oilSpecializeFor: latencies (us: compilation, whole primitive including freeing the baseline code): '; print: latencies asArray; cr; flush.
specs := seqDo oilSpecializations.
check value: 'oilSpecializations: 5 classes, each with Oil code' value: (specs size = 10 and: [(1 to: 10 by: 2) allSatisfy: [:k | (classes includes: (specs at: k)) and: [(specs at: k + 1) oilInfo notNil]]]).
"(a trip counter trips once per compilation of the baseline code, which the last specialization freed)"
n := trips value: seqDo value: [model countOf: colls last].
check value: 'the sixth class runs the baseline code (its trip counter trips)' value: n >= 1.
check value: 'specialize do: for a sixth class: the PIC is full (OilFailSpecialization)' value: (seqDo oilSpecializeFor: classes last) = 17.
check value: 'specialize do: again for Array: already done' value: (seqDo oilSpecializeFor: Array) = 0.
check value: 'mixed receivers: results' value: ((colls collect: [:c | model countOf: c]) = counts).
n := trips value: seqDo value: [3 timesRepeat: [(colls first: 5) do: [:c | model countOf: c]]].
check value: 'mixed receivers of the 5 specialized classes run Oil code (no baseline trip counter trips)' value: n = 0.
check value: 'the sixth class: result' value: (model countOf: colls last) = 300000.
check value: 'no deopt in any specialization' value: ((1 to: 10 by: 2) allSatisfy: [:k | ((specs at: k + 1) oilInfo at: 1) = 0]).
oil := times value: [model countOf: colls first].
out nextPutAll: 'countOf: Array of 300000: specialized do: '; print: oil; nextPutAll: ' ms, baseline '; print: base; nextPutAll: ' ms'; cr; flush.
check value: 'sumOf: Array, ByteArray, WordArray (other block, same specializations)' value: ((model sumOf: (1 to: 1000) asArray) = 500500 and: [(model sumOf: ((1 to: 200) collect: [:k | k]) asByteArray) = 20100 and: [(model sumOf: (WordArray withAll: (1 to: 1000))) = 500500]]).
check value: 'system-wide use of the specialized do:' value: ((Smalltalk allClasses first: 50) collect: [:c | c name size]) size = 50.
"OrderedCollection>>do: for OrderedCollection and SortedCollection; a subclass runs the baseline code"
ocDo := OrderedCollection >> #do:.
oc := OrderedCollection withAll: (1 to: 100000).
sorted := SortedCollection withAll: (1 to: 100000).
OrderedCollection subclass: #OilM7OrderedCollection instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
sub := (Smalltalk at: #OilM7OrderedCollection) withAll: (1 to: 100000).
3 timesRepeat: [model sumOf: oc. model sumOf: sorted. model sumOf: sub].
check value: 'specialize OrderedCollection>>do: for OrderedCollection' value: (ocDo oilSpecializeFor: OrderedCollection) = 0.
3 timesRepeat: [model sumOf: oc. model sumOf: sorted. model sumOf: sub].
check value: 'specialize OrderedCollection>>do: for SortedCollection' value: (ocDo oilSpecializeFor: SortedCollection) = 0.
check value: 'the subclass runs the baseline code' value: (trips value: ocDo value: [model sumOf: sub]) >= 1.
check value: 'OrderedCollection, SortedCollection, subclass: results' value: ((model sumOf: oc) = 5000050000 and: [(model sumOf: sorted) = 5000050000 and: [(model sumOf: sub) = 5000050000]]).
check value: 'OrderedCollection and SortedCollection run Oil code' value: (trips value: ocDo value: [3 timesRepeat: [model sumOf: oc. model sumOf: sorted]]) = 0.
check value: 'OrderedCollection>>do: specializations: no deopt' value: (((ocDo oilSpecializations) at: 2) oilInfo at: 1) = 0.


"--- 2. identityHash (primitive 75) intrinsic: IdentitySet / IdentityDictionary probes without sends ---"
check value: 'hashOf: compiles' value: (res value: #hashOf: value: [model hashOf: model]) = 0.
check value: 'hashOf: uses OilIdentityHash, no call' value: ((countOps value: ir value: #(48)) = 1 and: [(countOps value: ir value: #(22 23 24 30)) = 0]).
check value: 'hashOf: result' value: (model hashOf: model) = model identityHash.
check value: 'hashOf: objects with no hash yet (send, no deopt)'
	value: ((1 to: 64) allSatisfy: [:k | | o h | o := cls new. h := model hashOf: o. h = o identityHash and: [h = (model hashOf: o)]]).
check value: 'hashOf: no deopt' value: ((cls >> #hashOf:) oilInfo at: 1) = 0.
"a super send of identityHash is not compiled to the intrinsic (its slow path would be an ordinary send)"
Object subclass: #OilM7Hashed instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
(Smalltalk at: #OilM7Hashed) compile: 'identityHash ^super identityHash bitXor: 4660' classified: 'tests'.
cls compile: 'hashOfHashed: anObject ^anObject identityHash' classified: 'tests'.
check value: 'hashOfHashed: compiles' value: (res value: #hashOfHashed: value: [model hashOfHashed: (Smalltalk at: #OilM7Hashed) new]) = 0.
check value: 'hashOfHashed: super identityHash in an override: consistent results for objects with no hash yet'
	value: ((1 to: 20) allSatisfy: [:k | | o h | o := (Smalltalk at: #OilM7Hashed) new. h := model hashOfHashed: o. h = (model hashOfHashed: o) and: [h = o identityHash]]).
check value: 'scaledHashOf: compiles' value: (res value: #scaledHashOf: value: [model scaledHashOf: #foo]) = 0.
check value: 'scaledHashOf: result' value: (model scaledHashOf: #bar) = #bar scaledIdentityHash.
check value: 'scaledHashOf: no deopt' value: ((cls >> #scaledHashOf:) oilInfo at: 1) = 0.
"Fresh type feedback for the hashed collection methods (their inline caches have seen all sorts of receivers so far)."
{IdentitySet -> #scanFor:. IdentityDictionary -> #scanFor:. IdentitySet -> #includes:. IdentityDictionary -> #at:ifAbsent:. Object -> #scaledIdentityHash. Object -> #enclosedSetElement. Association -> #key}
	do: [:a | (a key lookupSelector: a value) voidCogVMState].
syms := (1 to: 10000) collect: [:k | ('oilM7Sym', k printString) asSymbol].
set := IdentitySet new. syms doWithIndex: [:s :k | k odd ifTrue: [set add: s]].
dict := IdentityDictionary new. syms doWithIndex: [:s :k | k \\ 3 = 0 ifTrue: [dict at: s put: k]].
expected := model count: syms in: set.
check value: 'count:in: (IdentitySet) result before Oil' value: expected = 5000.
base := times value: [20 timesRepeat: [model count: syms in: set]].
check value: 'count:in: compiles' value: (res value: #count:in: value: [model count: syms in: set]) = 0.
check value: 'count:in: inlines identityHash, no call in the probe loop' value: ((countOps value: ir value: #(48)) >= 1 and: [(countOps value: ir value: #(22 23 24 30)) <= 1]).
out nextPutAll: 'count:in: calls (all ops) '; print: ((ir select: [:op | #(22 23 24 30) includes: op]) size); cr.
check value: 'count:in: result' value: (model count: syms in: set) = expected.
oil := times value: [20 timesRepeat: [model count: syms in: set]].
check value: 'count:in: no deopt' value: ((cls >> #count:in:) oilInfo at: 1) = 0.
out nextPutAll: 'IdentitySet includes: 20 x 10000 symbols: Oil '; print: oil; nextPutAll: ' ms, baseline '; print: base; nextPutAll: ' ms'; cr; flush.
check value: 'count:in: faster than baseline' value: oil < base.
keys := syms.
expected := model sum: keys in: dict.
base := times value: [20 timesRepeat: [model sum: keys in: dict]].
check value: 'sum:in: (IdentityDictionary) compiles' value: (res value: #sum:in: value: [model sum: keys in: dict]) = 0.
check value: 'sum:in: inlines identityHash' value: (countOps value: ir value: #(48)) >= 1.
out nextPutAll: 'sum:in: calls (all ops) '; print: ((ir select: [:op | #(22 23 24 30) includes: op]) size); cr.
check value: 'sum:in: result' value: (model sum: keys in: dict) = expected.
oil := times value: [20 timesRepeat: [model sum: keys in: dict]].
check value: 'sum:in: no deopt' value: ((cls >> #sum:in:) oilInfo at: 1) = 0.
out nextPutAll: 'IdentityDictionary at:ifAbsent: 20 x 10000 symbols: Oil '; print: oil; nextPutAll: ' ms, baseline '; print: base; nextPutAll: ' ms'; cr; flush.
check value: 'sum:in: faster than baseline' value: oil < base.
check value: 'count:in: with a new set (rehashed, other keys)' value: (model count: (syms first: 100) in: (IdentitySet withAll: (syms last: 50))) = 0.

"--- 3. Word-at-a-time byte scans: upTo: (indexOfAscii:inString:startingAt:) and skipSeparators ---"
text := 'alpha;  beta;' , (String new: 37 withAll: $ ), 'gamma ;', (String new: 20 withAll: Character tab), String cr, ';;  delta;eps' , (String with: (Character value: 1) with: Character lf with: (Character value: 12)), 'z;' , (String with: (Character value: 11)), 'vt;', (String with: (Character value: 0)), 'nul'.
expected := model positions: text.
check value: 'positions: compiles' value: (res value: #positions: value: [model positions: text]) = 0.
check value: 'positions: uses OilSkipSeparators and OilIndexOfByte' value: ((countOps value: ir value: #(50)) >= 1 and: [(countOps value: ir value: #(49)) >= 1]).
check value: 'positions: exact delimiter positions' value: (model positions: text) = expected.
"compare with the interpreter-equivalent reference computed by a fresh (never Oil-compiled) copy of the method"
cls compile: 'refPositions: aString | in out | in := ReadStream on: aString. out := OrderedCollection new. [in skipSeparators. out add: in position. in atEnd] whileFalse: [in upTo: $;. out add: in position]. ^out asArray' classified: 'tests'.
check value: 'positions: all suffixes and prefixes equal the reference'
	value: ((1 to: text size) allSatisfy: [:k | (model positions: (text allButFirst: k - 1)) = (model refPositions: (text allButFirst: k - 1)) and: [(model positions: (text first: k)) = (model refPositions: (text first: k))]]).
check value: 'upTo:in:from: compiles' value: (res value: #upTo:in:from: value: [model upTo: $; in: text from: 0]) = 0.
check value: 'upTo:in:from: every start and delimiter'
	value: ((0 to: text size) allSatisfy: [:k | (Array with: $; with: $  with: $z with: $# with: (Character value: 0)) allSatisfy: [:c | | in |
		in := ReadStream on: text. in position: k.
		(model upTo: c in: text from: k) = {in upTo: c. in position}]]).
check value: 'upTo:in:from: on a WideString (send)' value: (model upTo: $b in: 'a', (String with: (Character value: 300)), 'b' from: 0) = {'a', (String with: (Character value: 300)). 3}.
check value: 'upTo:in:from: on an Array (send)' value: (model upTo: 3 in: #(1 2 3 4) from: 0) = {#(1 2). 3}.
check value: 'skip:from: compiles' value: (res value: #skip:from: value: [model skip: text from: 0]) = 0.
check value: 'skip:from: every start' value: ((0 to: text size) allSatisfy: [:k | | in | in := ReadStream on: text. in position: k. in skipSeparators. (model skip: text from: k) = in position]).
check value: 'skipStream: compiles' value: (res value: #skipStream: value: [model skipStream: (ReadStream on: '  x')]) = 0.
check value: 'skipStream: limited stream (readLimit)' value: (model skipStream: (ReadStream on: '      x' from: 1 to: 4)) = 4.
check value: 'skipStream: WideString collection (send)' value: (model skipStream: (ReadStream on: '   ', (String with: (Character value: 300)))) = 3.
check value: 'skipStream: no deopt' value: ((cls >> #skipStream:) oilInfo at: 1) = 0.
check value: 'indexOf:in:from: compiles' value: (res value: #indexOf:in:from: value: [model indexOf: $c in: 'abc' from: 1]) = 0.
check value: 'indexOf:in:from: every start, every byte position'
	value: ((1 to: 40) allSatisfy: [:len | | s | s := String new: len withAll: $a.
		(1 to: len) allSatisfy: [:pos | | s2 | s2 := s copy. s2 at: pos put: $b.
			(1 to: len + 2) allSatisfy: [:k | (model indexOf: $b in: s2 from: k) = (s2 indexOf: $b startingAt: k ifAbsent: [0])]]]).
check value: 'indexOf:in:from: absent, high bytes, ByteArray-like'
	value: ((model indexOf: $z in: 'abc' from: 1) = 0 and: [(model indexOf: (Character value: 255) in: 'ab', (String with: (Character value: 255)) from: 1) = 3 and: [(model indexOf: (Character value: 300) in: 'abc' from: 1) = 0]]).
check value: 'indexOf:in:from: no deopt' value: ((cls >> #indexOf:in:from:) oilInfo at: 1) = 0.
big := String new: 1024 * 1024.
n := 0.
1 to: big size do: [:k | big at: k put: (k \\ 64 < 40 ifTrue: [$ ] ifFalse: [k \\ 64 = 63 ifTrue: [$;] ifFalse: [$x]])].
cls compile: 'tokensRef: aString | in n | in := ReadStream on: aString. n := 0. [in skipSeparators. in atEnd] whileFalse: [in upTo: $;. n := n + 1]. ^n' classified: 'tests'.
expected := model tokensRef: big.
base := times value: [model tokensRef: big].
check value: 'tokens: compiles' value: (res value: #tokens: value: [model tokens: (big first: 1000)]) = 0.
check value: 'tokens: 1 MB result' value: (model tokens: big) = expected.
oil := times value: [model tokens: big].
check value: 'tokens: no deopt' value: ((cls >> #tokens:) oilInfo at: 1) = 0.
out nextPutAll: 'tokens: 1 MB (skipSeparators + upTo:): Oil '; print: oil; nextPutAll: ' ms, baseline '; print: base; nextPutAll: ' ms ('; print: expected; nextPutAll: ' tokens)'; cr; flush.
check value: 'tokens: faster than baseline' value: oil < base.

"--- 4. Robustness: full GC, all machine code freed, recompilation ---"
Smalltalk garbageCollect.
check value: 'full GC: results' value: ((model count: syms in: set) = 5000 and: [(model positions: text) = (model refPositions: text)
	and: [((colls collect: [:c | model countOf: c]) = counts) and: [(model sumOf: oc) = 5000050000]]]).
check value: 'full GC: the specializations still run' value: ((trips value: seqDo value: [(colls first: 5) do: [:c | model countOf: c]]) = 0
	and: [(1 to: 10 by: 2) allSatisfy: [:k | ((specs at: k + 1) oilInfo at: 1) = 0]]).
Smalltalk voidCogVMState.
check value: 'voidCogVMState: specializations lost their Oil code' value: ((1 to: 10 by: 2) allSatisfy: [:k | (specs at: k + 1) oilInfo isNil]).
check value: 'voidCogVMState: results' value: (((colls collect: [:c | model countOf: c]) = counts) and: [(model sumOf: sub) = 5000050000 and: [(model positions: text) = (model refPositions: text)]]).
3 timesRepeat: [model countOf: colls first].
check value: 'voidCogVMState: specialize do: for Array again (same copy)' value: ((seqDo oilSpecializeFor: Array) = 0 and: [(seqDo oilSpecializations at: 2) oilInfo notNil]).
check value: 'voidCogVMState: Array runs Oil code again' value: ((trips value: seqDo value: [model countOf: colls first. model countOf: colls first]) = 0 and: [(model countOf: colls first) = 300000]).
3 timesRepeat: [model countOf: colls last].
check value: 'voidCogVMState: entries without Oil code do not count: specialize do: for the sixth class' value: ((seqDo oilSpecializeFor: classes last) = 0 and: [seqDo oilSpecializations size = 4]).
check value: 'the sixth class runs Oil code now' value: ((trips value: seqDo value: [model countOf: colls last. model countOf: colls last]) = 0 and: [(model countOf: colls last) = 300000]).
copy := (seqDo oilSpecializations) at: 2.
seqDo voidCogVMState.
check value: 'voiding the method''s machine code drops its specializations and frees their Oil code' value: (seqDo oilSpecializations isEmpty and: [copy oilInfo isNil]).
check value: 'after voiding the method: results' value: ((colls collect: [:c | model countOf: c]) = counts).
3 timesRepeat: [model hashOf: model].
check value: 'specializing a method that has Oil code of its own is refused' value: (((cls >> #hashOf:) oilCompileFor: cls) = 0 and: [((cls >> #hashOf:) oilSpecializeFor: cls) = 17]).
cls compile: 'countOf: aCollection | n | n := 0. aCollection do: [:e | n := n + 2]. ^n' classified: 'tests'.
check value: 'countOf: redefined' value: ((colls first: 5) allSatisfy: [:c | (model countOf: c) = 600000]).
t := Time millisecondsToRun: [SequenceableCollection recompile: #do:. OrderedCollection recompile: #do:].
check value: 'recompiled do: has no specialization; results' value: ((SequenceableCollection >> #do:) oilSpecializations isEmpty
	and: [((colls first: 5) allSatisfy: [:c | (model countOf: c) = 600000]) and: [(model sumOf: oc) = 5000050000]]).
3 timesRepeat: [model countOf: colls first].
check value: 'specialize the recompiled do: for Array (system-wide during recompileAll)' value: (((SequenceableCollection >> #do:) oilSpecializeFor: Array) = 0 and: [(model countOf: colls first) = 600000]).
t := Time millisecondsToRun: [Compiler recompileAll].
out nextPutAll: 'Compiler recompileAll: '; print: t; nextPutAll: ' ms'; cr; flush.
Smalltalk garbageCollect.
check value: 'Compiler recompileAll: results' value: ((model count: syms in: set) = 5000 and: [(model positions: text) = (model refPositions: text)
	and: [((colls first: 5) allSatisfy: [:c | (model countOf: c) = 600000]) and: [(model sumOf: sorted) = 5000050000]]]).
out nextPutAll: 'compile latencies (us: compilation, whole primitive): '; print: latencies asArray; cr.
compileUs := (latencies collect: [:a | a value first]) asSortedCollection asArray.
out nextPutAll: 'compilation (Passes 1-3 + assembly) median '; print: (compileUs at: compileUs size + 1 // 2); nextPutAll: ' us, max '; print: compileUs last; nextPutAll: ' us'; cr.
check value: 'compilation latency: median below 1 ms' value: (compileUs at: compileUs size + 1 // 2) < 1000.
out nextPutAll: (failures isEmpty ifTrue: ['ALL PASS'] ifFalse: ['FAILURES: ', failures size printString]); cr.
out close.
failures isEmpty ifFalse: [self error: 'Oil M7 test failures: ', failures printString]
