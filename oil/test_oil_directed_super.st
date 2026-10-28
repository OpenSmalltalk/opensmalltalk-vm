"Oil end-to-end test (native) of directed super sends: a super send of a method inlined in an Oil method
 (OilCallDirectedSuper) is a call through the directed super send trampolines, whose lookup starts in the superclass of
 the method class of the inlined method (not of the root method, of the receiver's class or of its superclass).
 OilDirectedSuperMid>>compute: is inlined into the root OilDirectedSuperModel>>run:n:, and the targets of its super sends are cold selectors
 (never inlined), so they are called: with 0, 1, 2 and 3 arguments (registers and stack), with selectors that are not
 literals of the root (the Oil selector table).  Checks the IR, the results against the baseline JIT, deoptimization
 (another receiver class), the redefinition of a super send target and of an override, a full GC and voidCogVMState.
 A super send in a block (OilDirectedSuperMid>>blockSum:) is compiled as a directed super send bytecode (push the class binding,
 then send super with extB >= 64), which the scanner does not support: such a block is not inlined, and the method is
 called; only the results are checked.
 Run with run-st.sh on a Squeak 6.x 64-bit image with the Oil VM.  Writes oil-directed-super-result.txt next to the image."
| out failures check sels setSelectors cls model base mid leaf res last opcodes info expected expectedBlock words r |
Utilities authorInitials: 'cb'.
out := FileStream forceNewFileNamed: (FileDirectory default fullNameFor: 'oil-directed-super-result.txt').
failures := OrderedCollection new.
check := [:name :bool |
	out nextPutAll: (bool == true ifTrue: ['PASS '] ifFalse: ['FAIL ']); nextPutAll: name; cr; flush.
	bool == true ifFalse: [failures add: name]].
Object subclass: #OilDirectedSuperBase instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
(Smalltalk at: #OilDirectedSuperBase) subclass: #OilDirectedSuperMid instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
(Smalltalk at: #OilDirectedSuperMid) subclass: #OilDirectedSuperLeaf instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
Object subclass: #OilDirectedSuperModel instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
base := Smalltalk at: #OilDirectedSuperBase. mid := Smalltalk at: #OilDirectedSuperMid. leaf := Smalltalk at: #OilDirectedSuperLeaf. cls := Smalltalk at: #OilDirectedSuperModel.
#('dsBase0 | t | t := 3. ^t + 4'
  'dsBase1: x ^x + 1'
  'dsBase2: x with: y ^x * 100 + y'
  'dsBase3: x with: y with: z ^x * 10000 + (y * 100) + z') do: [:src | base compile: src classified: 'tests'].
"overrides that a wrong lookup (from the receiver's class or from its superclass) would find"
{mid. leaf} doWithIndex: [:c :k |
	#('dsBase0 ^-1000' 'dsBase1: x ^-1000' 'dsBase2: x with: y ^-1000' 'dsBase3: x with: y with: z ^-1000')
		do: [:src | c compile: (src copyReplaceAll: '1000' with: (k * 1000) printString) classified: 'tests']].
mid compile: 'compute: x ^(super dsBase1: x) * 2 + (super dsBase2: x with: 3) + super dsBase0 + (super dsBase3: 1 with: 2 with: x)' classified: 'tests'.
mid compile: 'blockSum: x | s | s := 0. #(1 2 3) do: [:k | s := s + (super dsBase1: k + x)]. ^s' classified: 'tests'.
#('run: obj n: n | s | s := 0. 1 to: n do: [:i | s := s + (obj compute: i)]. ^s'
  'runBlock: obj n: n | s | s := 0. 1 to: n do: [:i | s := s + (obj blockSum: i)]. ^s') do: [:src |
	cls compile: src classified: 'tests'.
	"the same method, left to the baseline JIT"
	cls compile: (src copyReplaceAll: ': obj n:' with: 'Base: obj n:') classified: 'tests'].
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
"cold selectors (never inlined): the targets of the super sends are called"
#(error: errorNoFreeSpace errorSubscriptBounds: errorNotIndexable subclassResponsibility halt doesNotUnderstand: primitiveFailed makeRoomAtLast makeRoomAtFirst
  dsBase0 dsBase1: dsBase2:with: dsBase3:with:with:)
	do: [:s | sels add: 7; add: s].
check value: 'primitiveOilSetSelectors' value: (cls oilSetSelectors: sels asArray) ~~ #failed.
model := cls new.
"the opcodes of the last compilation (OilCallDirectedSuper = 55: 5 words then the packed arguments)"
opcodes := [| i ops op |
	words := (CompiledMethod oilLastCompilation) at: 2.
	ops := OrderedCollection new. i := 1.
	[i <= words size] whileTrue:
		[op := (words at: i) bitShift: -24.
		 ops add: op.
		 i := i + ((#(2 20 22 23 41 42 48 50 51 52 54) includes: op)
				ifTrue: [3]
				ifFalse: [op = 28 ifTrue: [4] ifFalse: [op = 53 ifTrue: [5] ifFalse: [(#(24 30 49) includes: op)
					ifTrue: [3 + (((words at: i) bitAnd: 255) + 3 // 4)]
					ifFalse: [op = 55 ifTrue: [5 + (((words at: i) bitAnd: 255) + 3 // 4)] ifFalse: [1]]]]])].
	ops].
res := [:sel :warm | | cm ops |
	cm := cls >> sel.
	3 timesRepeat: warm.
	r := cm oilCompileFor: cls.
	last := CompiledMethod oilLastCompilation.
	ops := opcodes value.
	out nextPutAll: sel; nextPutAll: ': oilCompileFor: -> '; print: r; nextPutAll: ', '; print: ops size; nextPutAll: ' IR instructions, ';
		print: (ops occurrencesOf: 55); nextPutAll: ' OilCallDirectedSuper, '; print: (ops occurrencesOf: 30); nextPutAll: ' OilCallSuper, ';
		print: (ops count: [:op | op between: 22 and: 24]); nextPutAll: ' other calls'; cr; flush.
	ops].
info := [:sel | (cls >> sel) oilInfo].
expected := [:n | (1 to: n) inject: 0 into: [:s :i | s + ((i + 1) * 2) + (i * 100 + 3) + 7 + (10200 + i)]].
expectedBlock := [:n | (1 to: n) inject: 0 into: [:s :i | s + (3 * i) + 9]].
check value: 'baseline run:n: (directed super sends from compute:)' value: (model runBase: leaf new n: 10) = (expected value: 10).
check value: 'baseline runBlock:n:' value: (model runBlockBase: leaf new n: 10) = (expectedBlock value: 10).

"--- compute: inlined into run:n:, its four super sends become OilCallDirectedSuper ---"
(res value: #run:n: value: [model run: leaf new n: 50]) in: [:ops |
	check value: 'run:n: compiles' value: r = 0.
	check value: 'run:n: has 4 OilCallDirectedSuper' value: (ops occurrencesOf: 55) = 4.
	check value: 'run:n: has no OilCallSuper' value: (ops occurrencesOf: 30) = 0].
check value: 'run:n: has Oil code' value: (info value: #run:n:) notNil.
check value: 'run:n: = expected (leaf, 1000)' value: (model run: leaf new n: 1000) = (expected value: 1000).
check value: 'run:n: = expected (leaf, 0)' value: (model run: leaf new n: 0) = 0.
check value: 'run:n: no deopt' value: ((info value: #run:n:) ifNil: [false] ifNotNil: [:i | (i at: 1) = 0]).
check value: 'run:n: = baseline for 100000 iterations' value: (model run: leaf new n: 100000) = (model runBase: leaf new n: 100000).
check value: 'run:n: still no deopt' value: ((info value: #run:n:) ifNil: [false] ifNotNil: [:i | (i at: 1) = 0]).
"another receiver class: the class guard of the inlined compute: deoptimizes; the super sends of OilDirectedSuperMid>>compute: start in
 OilDirectedSuperBase whatever the receiver"
check value: 'run:n: with an OilDirectedSuperMid receiver (deopt)' value: (model run: mid new n: 20) = (expected value: 20).
check value: 'run:n: with a leaf after the deopt' value: (model run: leaf new n: 20) = (expected value: 20).

"--- a super send in a block (a directed super send bytecode, not supported by the scanner: blockSum: is called) ---"
res value: #runBlock:n: value: [model runBlock: leaf new n: 50].
check value: 'runBlock:n: compiles' value: r = 0.
check value: 'runBlock:n: = expected (1000)' value: (model runBlock: leaf new n: 1000) = (expectedBlock value: 1000).
check value: 'runBlock:n: no deopt' value: ((info value: #runBlock:n:) ifNil: [false] ifNotNil: [:i | (i at: 1) = 0]).

"--- a full GC (the method class embedded in the machine code may move) and voidCogVMState ---"
Smalltalk garbageCollect.
check value: 'run:n: after a full GC' value: (model run: leaf new n: 1000) = (expected value: 1000).
check value: 'runBlock:n: after a full GC' value: (model runBlock: leaf new n: 1000) = (expectedBlock value: 1000).

"--- redefining a target of the directed super sends: the linked sends must reach the new method ---"
base compile: 'dsBase1: x ^x + 2' classified: 'tests'.
expected := [:n | (1 to: n) inject: 0 into: [:s :i | s + ((i + 2) * 2) + (i * 100 + 3) + 7 + (10200 + i)]].
expectedBlock := [:n | (1 to: n) inject: 0 into: [:s :i | s + (3 * i) + 12]].
check value: 'run:n: after redefining OilDirectedSuperBase>>dsBase1:' value: (model run: leaf new n: 1000) = (expected value: 1000).
check value: 'runBlock:n: after redefining OilDirectedSuperBase>>dsBase1:' value: (model runBlock: leaf new n: 1000) = (expectedBlock value: 1000).
"recompile with the new definition, then redefine the override in OilDirectedSuperMid: the super sends must not find it"
(res value: #run:n: value: [model run: leaf new n: 50]) in: [:ops |
	check value: 'run:n: recompiles with 4 OilCallDirectedSuper' value: (r = 0 and: [(ops occurrencesOf: 55) = 4])].
mid compile: 'dsBase2: x with: y ^-7' classified: 'tests'.
check value: 'run:n: after redefining the OilDirectedSuperMid override' value: (model run: leaf new n: 1000) = (expected value: 1000).
Smalltalk voidCogVMState.
check value: 'run:n: after voidCogVMState' value: (model run: leaf new n: 1000) = (expected value: 1000).
(res value: #run:n: value: [model run: leaf new n: 50]) in: [:ops |
	check value: 'run:n: recompiles after voidCogVMState' value: (r = 0 and: [(ops occurrencesOf: 55) = 4])].
check value: 'run:n: = expected after recompiling' value: (model run: leaf new n: 100000) = (expected value: 100000).
out nextPutAll: (failures isEmpty ifTrue: ['ALL PASS'] ifFalse: ['FAILURES: ', failures size printString]); cr.
out close.
failures isEmpty ifFalse: [self error: 'Oil directed super test failures: ', failures printString]
