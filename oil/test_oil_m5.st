"Oil end-to-end test (native): deopt disqualification, escaping closures and brace arrays (OilMakeClosure,
 OilNewArray, eden bump allocation with the allocation deoptimization), byte/stream intrinsics, selector table.
 Run with run-st.sh on a Squeak 6.x 64-bit image with the Oil VM.  Writes oil-m5-result.txt next to the image."
| out failures check sels model m info res last items wrong expected t counter blk arr before |
Utilities authorInitials: 'cb'.
out := FileStream forceNewFileNamed: (FileDirectory default fullNameFor: 'oil-m5-result.txt').
failures := OrderedCollection new.
check := [:name :bool |
	out nextPutAll: (bool == true ifTrue: ['PASS '] ifFalse: ['FAIL ']); nextPutAll: name; cr; flush.
	bool == true ifFalse: [failures add: name]].
Object subclass: #OilTestItem instanceVariableNames: 'score' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
(Smalltalk at: #OilTestItem) compile: 'score ^score' classified: 'accessing'.
(Smalltalk at: #OilTestItem) compile: 'score: aNumber score := aNumber' classified: 'accessing'.
Object subclass: #OilWrongItem instanceVariableNames: 'weight' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
(Smalltalk at: #OilWrongItem) compile: 'score ^1000000' classified: 'accessing'.
(Smalltalk at: #OilTestItem) compile: 'extTag ^score' classified: 'accessing'.
(Smalltalk at: #OilWrongItem) compile: 'extTag ^7' classified: 'accessing'.
Object subclass: #OilTestModel instanceVariableNames: 'total' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
#('sumScores: aCollection | sum | sum := 0. aCollection do: [:each | sum := sum + each score]. ^sum'
  'braceOf: a and: b ^{a. b. a + b. nil}'
  'constLeft: x ^(200 + (x * 3)) + ((1000 < (x * 3)) ifTrue: [10] ifFalse: [20])'
  'foldConsts | a b c d one two | a := -7. b := 2. c := 7. d := -2. one := 1. two := 2. ^{a BS b. a // b. c BS d. c // d. one bitShift: 64. two bitShift: 63. a bitShift: 64}'
  'makeCounter | count | count := 0. ^[count := count + 1]'
  'adderFor: x ^[:y | x + y + total]'
  'cleanBlock ^[:a :b | a + b]'
  'detectFirstOver: limit in: aCollection aCollection do: [:e | e score > limit ifTrue: [^e]]. ^nil'
  'escapeAndCall: aCollection | blk | blk := [:e | e score * 2]. ^aCollection collect: blk'
  'allocLoop: count | last | 1 to: count do: [:i | last := {i. i + 1. i + 2}]. ^last'
  'total: n total := n'
  'skipSpaces: aStream [aStream atEnd] whileFalse: [| c | c := aStream peek. c isSeparator ifFalse: [^c]. aStream next]. ^nil'
  'words: aString | in out words c | in := ReadStream on: aString. words := 0. [in atEnd] whileFalse: [out := WriteStream on: String new. [in atEnd not and: [(c := in peek) isSeparator not]] whileTrue: [out nextPut: in next]. out contents isEmpty ifFalse: [words := words + 1]. [in atEnd not and: [in peek isSeparator]] whileTrue: [in next]]. ^words'
  'copyChars: aString | in out | in := ReadStream on: aString. out := WriteStream on: (String new: aString size). [in atEnd] whileFalse: [out nextPut: in next]. ^out contents'
  'extSum: arr | s | s := 0. 1 to: arr size do: [:i | s := s + (self extA: (arr at: i))]. ^s'
  'extA: x ^x extTag + 1'
  'countA: aString | n | n := 0. 1 to: aString size do: [:i | (aString at: i) == $a ifTrue: [n := n + 1]]. ^n'
  'countEqual: aString in: anArray | n | n := 0. anArray do: [:e | e = aString ifTrue: [n := n + 1]]. ^n'
  'fillBytes: aByteArray 1 to: aByteArray size do: [:i | aByteArray at: i put: i BS 256]. ^aByteArray'
  'upcase: aString | s | s := aString copy. 1 to: s size do: [:i | | c | c := s at: i. (c between: $a and: $z) ifTrue: [s at: i put: (Character value: c asInteger - 32)]]. ^s'
  'hashProbe: anArray key: key
    | index length element |
    length := anArray size.
    index := (key hash BS length) + 1.
    [element := anArray at: index.
     element == nil ifTrue: [^ index].
     element == key ifTrue: [^ index].
     index := index BS length + 1] repeat'
  'benchmarkHashProbe
    | array |
    array := Array new: 8191.
    1 to: 4000 do: [:i | array at: (i * 17 BS 8191) + 1 put: i * 17].
    ^ [10 to: 1000000 do: [:i | self hashProbe: array key: (4000 * 17)]] timeToRun')
	do: [:s | (Smalltalk at: #OilTestModel) compile: (s copyReplaceAll: 'BS' with: (String with: $\ with: $\)) classified: 'tests'].
(Smalltalk at: #OilTestModel) class compile: 'oilSetParameter: index to: value <primitive: ''primitiveOilGetOrSetParameter''> ^#failed' classified: 'oil'.
(Smalltalk at: #OilTestModel) class compile: 'autonomousCompilation: aBoolean ^self oilSetParameter: 19 to: aBoolean' classified: 'oil'.
(Smalltalk at: #OilTestModel) class compile: 'disqualifyLimit: anInteger ^self oilSetParameter: 8 to: anInteger' classified: 'oil'.
(Smalltalk at: #OilTestModel) class compile: 'oilSetColdSelectors: anArray ^self oilSetParameter: 7 to: anArray' classified: 'oil'.
"(the kind/value pairs of the former primitiveOilSetSelectors: the cold selectors, kind 7, and the parameters, kinds 8 and 12 to 18,
 the others at their default; the value selectors, bitXor: and the iterators are built in; no autonomous compilation)"
(Smalltalk at: #OilTestModel) class compile: 'oilSetSelectors: pairs
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
#(do: reverseDo: collect: select: reject: detect: detect:ifNone: detect:ifFound:ifNone: inject:into: do:separatedBy: doWithIndex: withIndexDo: keysAndValuesDo: timesRepeat: to:do: to:by:do: scanFor: findElementOrNil: with:do: allSatisfy: anySatisfy: noneSatisfy: count: detectMax: detectMin:)
	do: [:s | sels add: 6; add: s].
#(error: errorNoFreeSpace errorNotFound: errorSubscriptBounds: errorNoSuchElement errorEmptyCollection errorKeyNotFound: errorKeyNotFound errorImproperStore errorNonIntegerIndex errorNotIndexable subclassResponsibility shouldNotImplement notYetImplemented halt halt: deprecated: deprecated signal signal: doesNotUnderstand: cannotReturn: primitiveFailed primitiveFailed:)
	do: [:s | sels add: 7; add: s].
check value: 'primitiveOilSetSelectors' value: ((Smalltalk at: #OilTestModel) oilSetSelectors: sels asArray) ~~ #failed.
check value: 'code zone >= 4 MB' value: (Smalltalk vmParameterAt: 46) >= (4 * 1024 * 1024).
model := (Smalltalk at: #OilTestModel) new total: 0; yourself.
"compile: warm up (baseline JIT), Oil-compile, answer the compile result"
res := [:sel :warm | | cm |
	cm := (Smalltalk at: #OilTestModel) >> sel.
	3 timesRepeat: warm.
	r := cm oilCompileFor: (Smalltalk at: #OilTestModel).
	last := CompiledMethod oilLastCompilation.
	out nextPutAll: sel; nextPutAll: ': oilCompileFor: -> '; print: r; nextPutAll: ' (Pass 2 '; print: (last at: 11); nextPutAll: ')'; cr; flush.
	r].

"--- 1. Brace arrays (OilNewArray) ---"
check value: 'braceOf:and: compiles (OilNewArray)' value: (res value: #braceOf:and: value: [model braceOf: 3 and: 4]) = 0.
check value: 'braceOf:and: has Oil code' value: ((Smalltalk at: #OilTestModel) >> #braceOf:and:) oilInfo notNil.
check value: 'braceOf:and: result' value: (model braceOf: 3 and: 4) = {3. 4. 7. nil}.
check value: 'braceOf:and: with Floats (deopts on the SmallInteger add)' value: (model braceOf: 1.5 and: 2) = {1.5. 2. 3.5. nil}.
arr := (1 to: 1000) collect: [:k | model braceOf: k and: 1].
check value: 'braceOf:and: many results (young arrays)' value: ((arr collect: [:e | e at: 3]) = ((1 to: 1000) collect: [:k | k + 1])).
Smalltalk garbageCollect.
check value: 'braceOf:and: results survive a full GC' value: ((arr collect: [:e | e at: 3]) = ((1 to: 1000) collect: [:k | k + 1])).

"--- 2. Escaping closures (OilMakeClosure) ---"
check value: 'makeCounter compiles (closure + temp vector)' value: (res value: #makeCounter value: [model makeCounter]) = 0.
counter := model makeCounter.
check value: 'makeCounter: counter works' value: (counter value = 1 and: [counter value = 2 and: [counter value = 3]]).
check value: 'makeCounter: counters are independent' value: (model makeCounter value = 1).
check value: 'makeCounter: outerContext is the home context' value: (counter outerContext notNil and: [counter outerContext method == ((Smalltalk at: #OilTestModel) >> #makeCounter)]).
check value: 'adderFor: compiles' value: (res value: #adderFor: value: [model adderFor: 1]) = 0.
model total: 100.
check value: 'adderFor: closure (copied value + self)' value: ((model adderFor: 5) value: 7) = 112.
check value: 'cleanBlock compiles' value: (res value: #cleanBlock value: [model cleanBlock]) = 0.
check value: 'cleanBlock works' value: (model cleanBlock value: 3 value: 4) = 7.
items := (1 to: 10) collect: [:k | (Smalltalk at: #OilTestItem) new score: k; yourself].
check value: 'escapeAndCall: compiles' value: (res value: #escapeAndCall: value: [model escapeAndCall: items]) = 0.
check value: 'escapeAndCall: result' value: (model escapeAndCall: items) = ((1 to: 10) collect: [:k | k * 2]).
check value: 'detectFirstOver:in: compiles' value: (res value: #detectFirstOver:in: value: [model detectFirstOver: 5 in: items]) = 0.
check value: 'detectFirstOver:in: non-local return' value: (model detectFirstOver: 5 in: items) score = 6.
check value: 'detectFirstOver:in: not found' value: (model detectFirstOver: 50 in: items) isNil.

"--- 3. Allocation beyond the scavenge threshold: deoptimizes (not counted), still correct ---"
check value: 'allocLoop: compiles' value: (res value: #allocLoop: value: [model allocLoop: 10]) = 0.
check value: 'allocLoop: small' value: (model allocLoop: 10) = #(10 11 12).
check value: 'allocLoop: 3,000,000 arrays (crosses the scavenge threshold)' value: (model allocLoop: 3000000) = #(3000000 3000001 3000002).
info := ((Smalltalk at: #OilTestModel) >> #allocLoop:) oilInfo.
check value: 'allocLoop: still Oil code (allocation deoptimizations do not disqualify)' value: info notNil.
check value: 'allocLoop: no deoptimization counted' value: (info notNil and: [(info at: 1) = 0]).
check value: 'allocLoop: again' value: (model allocLoop: 3000000) = #(3000000 3000001 3000002).
t := Time millisecondsToRun: [model allocLoop: 3000000].
out nextPutAll: 'allocLoop: 3,000,000 brace arrays: '; print: t; nextPutAll: ' ms'; cr.

"--- 4. Disqualification after 2 deoptimizations ---"
items := (1 to: 1000) asArray collect: [:k | (Smalltalk at: #OilTestItem) new score: k; yourself].
expected := 1000 * 1001 // 2.
check value: 'sumScores: compiles' value: (res value: #sumScores: value: [model sumScores: items]) = 0.
m := (Smalltalk at: #OilTestModel) >> #sumScores:.
check value: 'sumScores: Oil code' value: m oilInfo notNil.
wrong := items copy. wrong at: 500 put: (Smalltalk at: #OilWrongItem) new.
check value: 'sumScores: first deopt correct' value: (model sumScores: wrong) = (expected - 500 + 1000000).
info := m oilInfo.
check value: 'sumScores: after 1 deopt still Oil code' value: (info notNil and: [(info at: 1) = 1]).
check value: 'sumScores: second deopt correct' value: (model sumScores: wrong) = (expected - 500 + 1000000).
check value: 'sumScores: after 2 deopts, the Oil code is freed' value: m oilInfo isNil.
check value: 'sumScores: correct afterwards' value: ((1 to: 5) collect: [:k | model sumScores: wrong]) asSet asArray = {expected - 500 + 1000000}.
check value: 'sumScores: correct on the original items' value: (model sumScores: items) = expected.
check value: 'sumScores: back to baseline machine code, not Oil' value: m oilInfo isNil.
check value: 'sumScores: not compiled again (FailDisqualified = 16)' value: (m oilCompileFor: (Smalltalk at: #OilTestModel)) = 16.

"--- 5. Byte objects: ByteString at:/size/=, ByteArray at:put: ---"
[| text strs bytes base oil info2 |
 text := String new: 10000 withAll: $b. 1 to: 10000 by: 7 do: [:k | text at: k put: $a].
 check value: 'countA: compiles' value: (res value: #countA: value: [model countA: text]) = 0.
 check value: 'countA: result' value: (model countA: text) = (text occurrencesOf: $a).
 check value: 'countA: empty' value: (model countA: '') = 0.
 check value: 'countA: on a WideString (deopt)' value: (model countA: 'aXa' asWideString) = 2.
 strs := (1 to: 1000) collect: [:k | (k \\ 10) printString, 'abcdefghijklmnopqrstuvwxyz'].
 check value: 'countEqual:in: compiles' value: (res value: #countEqual:in: value: [model countEqual: '3abcdefghijklmnopqrstuvwxyz' in: strs]) = 0.
 check value: 'countEqual:in: result' value: (model countEqual: '3abcdefghijklmnopqrstuvwxyz' in: strs) = 100.
 check value: 'countEqual:in: no match' value: (model countEqual: 'zzz' in: strs) = 0.
 check value: 'countEqual:in: prefix' value: (model countEqual: '3abcdefghijklmnopqrstuvwxy' in: strs) = 0.
 check value: 'countEqual:in: last byte differs' value: (model countEqual: '3abcdefghijklmnopqrstuvwxyZ' in: strs) = 0.
 check value: 'countEqual:in: empty strings' value: (model countEqual: '' in: #('' 'a' '')) = 2.
 info2 := ((Smalltalk at: #OilTestModel) >> #countEqual:in:) oilInfo.
 out nextPutAll: 'countEqual:in: deopts: '; print: (info2 ifNotNil: [info2 at: 1]); cr.
 bytes := ByteArray new: 1000.
 check value: 'fillBytes: compiles' value: (res value: #fillBytes: value: [model fillBytes: (ByteArray new: 10)]) = 0.
 check value: 'fillBytes: result' value: (model fillBytes: bytes) = ((1 to: 1000) collect: [:k | k \\ 256]) asByteArray.
 check value: 'upcase: compiles' value: (res value: #upcase: value: [model upcase: 'hello']) = 0.
 check value: 'upcase: result' value: (model upcase: 'hello World 123') = 'HELLO WORLD 123'.
 check value: 'upcase: empty' value: (model upcase: '') = ''.
 base := Time millisecondsToRun: [1000 timesRepeat: [text occurrencesOf: $a]].
 oil := Time millisecondsToRun: [1000 timesRepeat: [model countA: text]].
 out nextPutAll: 'countA: 1000 x 10000 chars: Oil '; print: oil; nextPutAll: ' ms (occurrencesOf: in Cogit '; print: base; nextPutAll: ' ms)'; cr.
 oil := Time millisecondsToRun: [1000 timesRepeat: [model countEqual: '3abcdefghijklmnopqrstuvwxyz' in: strs]].
 base := Time millisecondsToRun: [1000 timesRepeat: [strs count: [:e | e = '3abcdefghijklmnopqrstuvwxyz']]].
 out nextPutAll: 'countEqual:in: 1000 x 1000 strings: Oil '; print: oil; nextPutAll: ' ms (count: with = in Cogit '; print: base; nextPutAll: ' ms)'; cr] value.

"--- 5b. Streams: ReadStream next/peek/atEnd, WriteStream nextPut:, Character isSeparator ---"
[| text base oil r1 |
 text := String new: 20000 withAll: $x. 1 to: 20000 by: 9 do: [:k | text at: k put: $ ].
 check value: 'skipSpaces: compiles' value: (res value: #skipSpaces: value: [model skipSpaces: (ReadStream on: '   a')]) = 0.
 check value: 'skipSpaces: result' value: (model skipSpaces: (ReadStream on: '  	 abc')) = $a.
 check value: 'skipSpaces: at end' value: (model skipSpaces: (ReadStream on: '   ')) isNil.
 check value: 'skipSpaces: on an Array stream' value: (model skipSpaces: (ReadStream on: {Character space. $z})) = $z.
 3 timesRepeat: [model copyChars: text. model words: text].
 base := {Time millisecondsToRun: [100 timesRepeat: [model copyChars: text]]. Time millisecondsToRun: [100 timesRepeat: [model words: text]]}.
 out nextPutAll: 'baseline copyChars:/words: 100 x 20000 chars: '; print: base; nextPutAll: ' ms'; cr.
 check value: 'copyChars: compiles' value: (res value: #copyChars: value: [model copyChars: 'hello']) = 0.
 check value: 'copyChars: result' value: (model copyChars: text) = text.
 check value: 'copyChars: empty' value: (model copyChars: '') = ''.
 check value: 'words: compiles' value: (res value: #words: value: [model words: 'a b c']) = 0.
 r1 := text substrings size.
 check value: 'words: result' value: (model words: text) = r1.
 check value: 'words: small' value: (model words: ' hello  world foo ') = 3.
 out nextPutAll: 'words: deopts '; print: (((Smalltalk at: #OilTestModel) >> #words:) oilInfo ifNotNil: [:x | x at: 1]); cr.
 oil := Time millisecondsToRun: [100 timesRepeat: [model copyChars: text]].
 out nextPutAll: 'copyChars: 100 x 20000 chars: Oil '; print: oil; nextPutAll: ' ms'; cr.
 oil := Time millisecondsToRun: [100 timesRepeat: [model words: text]].
 out nextPutAll: 'words: 100 x 20000 chars: Oil '; print: oil; nextPutAll: ' ms'; cr] value.

"--- 5c. Sends of selectors that are not among the root's literals (the Oil selector table) ---"
[| extArr exp frames |
 extArr := (1 to: 100) collect: [:k | k odd ifTrue: [(Smalltalk at: #OilTestItem) new score: k; yourself] ifFalse: [(Smalltalk at: #OilWrongItem) new]].
 exp := (extArr inject: 0 into: [:a :e | a + e extTag + 1]).
 check value: 'extSum: compiles' value: (res value: #extSum: value: [model extSum: extArr]) = 0.
 frames := last at: 6.
 out nextPutAll: 'extSum: frames '; print: frames; cr.
 check value: 'extSum: inlines extA: (whose polymorphic extTag send is not among the root literals)' value: frames >= 2.
 check value: 'extSum: result' value: (model extSum: extArr) = exp.
 check value: 'extSum: result again (linked)' value: ((1 to: 3) collect: [:k | model extSum: extArr]) asSet asArray = {exp}.
 (Smalltalk at: #OilWrongItem) compile: 'extTag ^8' classified: 'accessing'.
 check value: 'extSum: after redefining extTag (sends unlinked through the selector table)' value: (model extSum: extArr) = (exp + 50).
 Smalltalk garbageCollect.
 check value: 'extSum: after a full GC' value: (model extSum: extArr) = (exp + 50).
 check value: 'extSum: still Oil code' value: ((Smalltalk at: #OilTestModel) >> #extSum:) oilInfo notNil.
 (Smalltalk at: #OilTestModel) compile: 'extA: x ^x extTag + 10' classified: 'tests'.
 check value: 'extSum: Oil code discarded when inlined extA: is redefined' value: ((Smalltalk at: #OilTestModel) >> #extSum:) oilInfo isNil.
 check value: 'extSum: uses redefined extA:' value: (model extSum: extArr) = (exp + 50 + 900)] value.

"--- 6. benchmarkHashProbe compiles ---"
before := model benchmarkHashProbe.
out nextPutAll: 'benchmarkHashProbe (baseline): '; print: before; nextPutAll: ' ms'; cr.
check value: 'benchmarkHashProbe compiles (no OilFailBackend)' value: (res value: #benchmarkHashProbe value: [model benchmarkHashProbe]) = 0.
t := (1 to: 3) collect: [:k | model benchmarkHashProbe].
out nextPutAll: 'benchmarkHashProbe (Oil home method, the loop is in the timeToRun block): '; print: t; nextPutAll: ' ms'; cr.
check value: 'benchmarkHashProbe still runs' value: (t allSatisfy: [:e | e isInteger]).

Smalltalk garbageCollect.
check value: 'constLeft: compiles' value: (res value: #constLeft: value: [model constLeft: 10]) = 0.
check value: 'constLeft: 200 + (x * 3) and 1000 < (x * 3)' value: ((model constLeft: 10) = 250 and: [(model constLeft: 400) = 1410]).
check value: 'foldConsts compiles' value: (res value: #foldConsts value: [model foldConsts]) = 0.
check value: 'foldConsts: Smalltalk semantics of constant folding (floored modulo and //, shifts out of 64 bits)' value: model foldConsts = {1. -4. -1. -4. 1 bitShift: 64. 1 bitShift: 64. -7 bitShift: 64}.
check value: 'full GC after all tests' value: (model braceOf: 1 and: 2) = {1. 2. 3. nil}.
out nextPutAll: (failures isEmpty ifTrue: ['ALL PASS'] ifFalse: ['FAILURES: ', failures size printString]); cr.
out close.
failures isEmpty ifFalse: [self error: 'Oil M5 test failures: ', failures printString].
