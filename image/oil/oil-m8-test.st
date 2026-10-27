"Oil M8 acceptance test (in image): scalar replacement of objects (OilDescObject: dissolved Points and Associations,
 materialized only where they escape, with OilNewObject), bimorphic inlining (a class test and both methods inlined; a
 predicate answering true for one class and false for the other is the class test itself: OilCmpClass, no boolean), and the
 sends removed from hashed collection probes (Behavior>>identityHash and String>>hash of constants folded, OilStringHash).
 Files in the Oil sources, compiles probes (Pass 1 with simulated type feedback, then pipe), checks the statistics and the
 IR, and validates the IR by executing it (OilIRInterpreter) against the real execution of each method."
| dir |
Utilities authorInitials: 'cb'.
dir := Smalltalk at: #OilSourceDir ifAbsentPut: [((FileDirectory default fileExists: 'OilConstants.st') ifTrue: [FileDirectory default] ifFalse: [FileDirectory default directoryNamed: 'oil']) pathName, '/'].
#('OilInstructionConstants.st' 'OilConstants.st' 'OilBytecodeScanner.st' 'OilCompiler.st' 'OilCompilerBackend.st' 'OilCompilerPass2.st' 'OilSimulation.st') do:
	[:f | (FileStream readOnlyFileNamed: dir, f) fileIn]!

| out pass fail check model compile run probes cls opcodes stats syms set dict |
out := FileStream forceNewFileNamed: (Smalltalk at: #OilResultFile ifAbsent: [(Smalltalk at: #OilSourceDir), 'm8-test-result.txt']).
pass := 0. fail := 0.
check := [:name :bool |
	bool == true
		ifTrue: [pass := pass + 1. out nextPutAll: 'PASS  '; nextPutAll: name; cr]
		ifFalse: [fail := fail + 1. out nextPutAll: 'FAIL  '; nextPutAll: name; cr]. out flush].
Object subclass: #OilM8Model instanceVariableNames: 'total' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
Object subclass: #OilM8A instanceVariableNames: 'x' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
Object subclass: #OilM8B instanceVariableNames: 'y' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
(Smalltalk at: #OilM8A) compile: 'oilM8Size ^3' classified: 'tests'.
(Smalltalk at: #OilM8B) compile: 'oilM8Size ^y * 2 + 1' classified: 'tests'.
(Smalltalk at: #OilM8B) compile: 'y: v y := v' classified: 'tests'.
(Smalltalk at: #OilM8A) compile: 'oilM8Maybe ^nil' classified: 'tests'.
(Smalltalk at: #OilM8B) compile: 'oilM8Maybe ^self' classified: 'tests'.
cls := Smalltalk at: #OilM8Model.
#('pointSum: n | s | s := 0. 1 to: n do: [:i | | p | p := i @ (i + 1). s := s + p x + p y]. ^s'
  'pointNew: n | s | s := 0. 1 to: n do: [:i | | p | p := Point x: i y: 3. s := s + (p x * p y)]. ^s'
  'assocSum: n | s | s := 0. 1 to: n do: [:i | | a | a := i -> (i * 2). s := s + a key + a value]. ^s'
  'pointAdd: n | s | s := 0 @ 0. 1 to: n do: [:i | s := s + (i @ 1)]. ^s x + s y'
  'pointEscape: n | a | a := Array new: n. 1 to: n do: [:i | a at: i put: i @ i]. ^a'
  'pointBranch: n | p | p := n @ n. n > 3 ifTrue: [^p]. ^p x'
  'assocPoint: n ^(n -> (n @ 1)) value x'
  'assocPointEscape: n ^n -> (n @ 1)'
  'pointEq: n ^(n @ 1) == (n @ 1)'
  'isSymProbe: coll | c | c := 0. coll do: [:e | e isSymbol ifTrue: [c := c + 1]]. ^c'
  'sizeSum: coll | s | s := 0. coll do: [:e | s := s + e oilM8Size]. ^s'
  'nilCount: coll | c | c := 0. coll do: [:e | e oilM8Maybe ifNil: [c := c + 1] ifNotNil: [c := c + 10]]. ^c'
  'symHash: s ^s == #hashWithInitialHash: ifTrue: [0] ifFalse: [s hash]'
  'constHash ^#foo hash + ByteString identityHash'
  'probe: anArray key: key | index length element | length := anArray size. index := (key hash \\ length) + 1. [element := anArray at: index. element == nil ifTrue: [^index]. element == key ifTrue: [^index]. index := index \\ length + 1] repeat'
  'count: keys in: aSet | n | n := 0. 1 to: keys size do: [:i | (aSet includes: (keys at: i)) ifTrue: [n := n + 1]]. ^n')
	do: [:s | cls compile: s classified: 'tests'].
model := cls new.
syms := #(#foo #bar #baz #qux #printOn: #size #at:put:).
set := Set withAll: (syms first: 4).
compile := [:sel :argLists | | fbk comp |
	fbk := OilSimulatedTypeFeedback new.
	argLists do: [:args | fbk record: [[model perform: sel withArguments: args] on: Error do: [:e | e return: nil]]].
	comp := OilCompiler new.
	comp typeFeedback: fbk.
	comp compileMethod: cls >> sel receiverClass: (comp handleFor: cls).
	comp failed ifFalse: [comp pipe].
	comp].
run := [:comp :args | [(OilIRInterpreter new on: comp) run: model with: args] on: Error do: [:e | #error -> e description]].
opcodes := [:comp | comp opcodeHistogram].
stats := [:comp | #(oilNumVirtualized oilNumMaterialized oilNumBimorphic oilNumPredicates 0 oilNumSelects) collect: [:v | v isSymbol ifTrue: [comp instVarNamed: v] ifFalse: [v]]].
"{selector. sample arguments (type feedback). arguments to check. check on {virtualized. materialized. bimorphic. predicates. eager sites} and the opcode histogram}"
probes := {
	{#pointSum:. {{3}}. {{3}. {10}. {0}}. [:st :h | (st at: 1) = 1 and: [(st at: 2) = 0 and: [(h occurrencesOf: #NewObject) = 0 and: [(h occurrencesOf: #Call1) = 0]]]]}.
	{#pointNew:. {{3}}. {{3}. {10}}. [:st :h | (st at: 1) = 1 and: [(st at: 2) = 0 and: [(h occurrencesOf: #CallN) = 0]]]}.
	{#assocSum:. {{3}}. {{3}. {10}}. [:st :h | (st at: 1) = 1 and: [(st at: 2) = 0 and: [(h occurrencesOf: #Call1) = 0]]]}.
	{#pointAdd:. {{3}}. {{3}. {10}. {0}}. [:st :h | (st at: 1) = 3 and: [(h occurrencesOf: #NewObject) = 2 and: [(h occurrencesOf: #Call1) = 0]]]}.
	{#pointEscape:. {{3}}. {{3}. {5}}. [:st :h | (st at: 2) = 1 and: [(h occurrencesOf: #NewObject) = 1]]}.
	{#pointBranch:. {{3}. {5}}. {{3}. {5}}. [:st :h | (st at: 2) = 1]}.
	{#assocPoint:. {{3}}. {{3}. {5}}. [:st :h | (st at: 1) = 2 and: [(st at: 2) = 0 and: [(h occurrencesOf: #NewObject) = 0]]]}.
	{#assocPointEscape:. {{3}}. {{3}. {5}}. [:st :h | (st at: 2) = 2 and: [(h occurrencesOf: #NewObject) = 2]]}.
	{#pointEq:. {{3}}. {{3}}. [:st :h | (st at: 2) = 0 and: [(h occurrencesOf: #NewObject) = 0]]}.
	{#isSymProbe:. {{#(#a 'b' #c 'd')}}. {{#(#a 'b' #c 'd')}. {#(#a #b)}. {#()}}. [:st :h | (st at: 4) = 1 and: [(h occurrencesOf: #CmpClass) = 1 and: [(h occurrencesOf: #GuardClass2) = 1 and: [(h occurrencesOf: #Call0) = 0]]]]}.
	{#sizeSum:. {{{(Smalltalk at: #OilM8A) new. (Smalltalk at: #OilM8B) new y: 5; yourself}}}. {{{(Smalltalk at: #OilM8A) new. (Smalltalk at: #OilM8B) new y: 5; yourself. (Smalltalk at: #OilM8A) new}}}. [:st :h | (st at: 3) = 1 and: [(h occurrencesOf: #CmpClass) = 1 and: [(h occurrencesOf: #Call0) = 0]]]}.
	{#nilCount:. {{{(Smalltalk at: #OilM8A) new. (Smalltalk at: #OilM8B) new}}}. {{{(Smalltalk at: #OilM8A) new. (Smalltalk at: #OilM8B) new. (Smalltalk at: #OilM8B) new}}. {{3}}}. [:st :h | (st at: 6) = 1 and: [(h occurrencesOf: #CmpClass) = 1 and: [(h occurrencesOf: #GuardClass2) = 1 and: [(h occurrencesOf: #Call0) = 0]]]]}.
	{#symHash:. {{#foo}}. {{#foo}. {#bar}. {#at:put:}}. [:st :h | (h occurrencesOf: #StringHash) = 1 and: [(h occurrencesOf: #Call0) + (h occurrencesOf: #Call1) = 0]]}.
	{#constHash. {{}}. {{}}. [:st :h | (h occurrencesOf: #StringHash) + (h occurrencesOf: #Call0) + (h occurrencesOf: #Call1) = 0]}.
	{#probe:key:. {{#(nil 4 nil 6 nil). 4}. {#(nil 4 nil 6 nil). 6}}. {{#(nil 4 nil 6 nil). 4}. {#(nil 4 nil 6 nil). 6}. {#(nil 4 nil 6 nil). 7}}. [:st :h | (h occurrencesOf: #Call0) + (h occurrencesOf: #Call1) = 0]}.
	{#count:in:. {{syms. set}}. {{syms. set}. {#(#qux #zork). set}}. [:st :h | true]}}.
probes do: [:spec | | sel comp st h |
	sel := spec first.
	comp := compile value: sel value: (spec at: 2).
	st := stats value: comp.
	h := opcodes value: comp.
	out cr; nextPutAll: comp irString; nextPutAll: sel; nextPutAll: ': virtualized, materialized, bimorphic, predicates, eager sites: '; print: st; cr.
	check value: sel, ' compiles' value: comp failed not.
	check value: sel, ' statistics and IR' value: ((spec at: 4) value: st value: h).
	(spec at: 3) do: [:args | | r real |
		r := run value: comp value: args.
		real := [model perform: sel withArguments: args] on: Error do: [:e | #error].
		((r isKindOf: Association) and: [r key == #deopt or: [r key == #error]])
			ifFalse: [check value: sel, ' IR = real for ', (args printString contractTo: 50) value: r = real]
			ifTrue:
				[out nextPutAll: '   '; print: args; nextPutAll: ' -> '; print: r; cr.
				 check value: sel, ' deoptimizes for ', (args printString contractTo: 50) value: r key == #deopt]]].
out cr; nextPutAll: 'TOTAL: '; print: pass; nextPutAll: ' passed, '; print: fail; nextPutAll: ' failed'; cr.
out close!
