"Oil directed super test (in image): a super send of a method inlined in the compiled method becomes OilCallDirectedSuper
 (the selector, then the method class of the inlined method, whose superclass the lookup starts in), which
 OilIRInterpreter runs with perform:withArguments:inSuperclass:.  Compiles a probe (Pass 1 with simulated type feedback,
 then pipe), checks its IR and runs it against the method's real execution.  (In the image the selectors of the calls
 of inlined frames must be literals of the root: the probe holds them.)"
| dir |
Utilities authorInitials: 'cb'.
dir := Smalltalk at: #OilSourceDir ifAbsentPut: [((FileDirectory default fileExists: 'OilConstants.st') ifTrue: [FileDirectory default] ifFalse: [FileDirectory default directoryNamed: 'oil']) pathName, '/'].
#('OilInstructionConstants.st' 'OilConstants.st' 'OilBytecodeScanner.st' 'OilCompiler.st' 'OilCompilerBackend.st' 'OilCompilerPass2.st' 'OilSimulation.st') do:
	[:f | (FileStream readOnlyFileNamed: dir, f) fileIn]!

| out pass fail check base mid leaf cls model fbk comp ops irText at |
out := FileStream forceNewFileNamed: (Smalltalk at: #OilResultFile ifAbsent: [(Smalltalk at: #OilSourceDir), 'directed-super-test-result.txt']).
pass := 0. fail := 0.
check := [:name :bool |
	bool == true
		ifTrue: [pass := pass + 1. out nextPutAll: 'PASS  '; nextPutAll: name; cr]
		ifFalse: [fail := fail + 1. out nextPutAll: 'FAIL  '; nextPutAll: name; cr]. out flush].
Object subclass: #OilDirectedSuperSimBase instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
(Smalltalk at: #OilDirectedSuperSimBase) subclass: #OilDirectedSuperSimMid instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
(Smalltalk at: #OilDirectedSuperSimMid) subclass: #OilDirectedSuperSimLeaf instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
Object subclass: #OilDirectedSuperSimModel instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
base := Smalltalk at: #OilDirectedSuperSimBase. mid := Smalltalk at: #OilDirectedSuperSimMid. leaf := Smalltalk at: #OilDirectedSuperSimLeaf. cls := Smalltalk at: #OilDirectedSuperSimModel.
base compile: 'dsBase1: x ^x + 1' classified: 'tests'.
base compile: 'dsBase2: x with: y ^x * 100 + y' classified: 'tests'.
"overrides that a lookup from the receiver's class or from its superclass would find"
mid compile: 'dsBase1: x ^-1000' classified: 'tests'.
mid compile: 'dsBase2: x with: y ^-1000' classified: 'tests'.
leaf compile: 'dsBase1: x ^-2000' classified: 'tests'.
leaf compile: 'dsBase2: x with: y ^-2000' classified: 'tests'.
mid compile: 'compute: x ^(super dsBase1: x) * 2 + (super dsBase2: x with: 3)' classified: 'tests'.
cls compile: 'run: obj n: n | s | s := 0. #dsBase1: == #dsBase2:with: ifTrue: [^0]. 1 to: n do: [:i | s := s + (obj compute: i)]. ^s' classified: 'tests'.
model := cls new.
fbk := OilSimulatedTypeFeedback new.
fbk record: [model run: leaf new n: 3].
comp := OilCompiler new.
comp typeFeedback: fbk.
"cold selectors (never inlined): the targets of the super sends are called"
#(dsBase1: dsBase2:with:) do: [:sel | comp registerSelector: (comp handleFor: sel) kind: 7].
comp compileMethod: cls >> #run:n: receiverClass: (comp handleFor: cls).
check value: 'run:n: compiles' value: comp failed not.
comp failed ifFalse:
	[ops := OrderedCollection new. at := 0.
	 [at < comp irIndex] whileTrue: [ops add: (comp opcodeAt: at). at := at + (comp instructionLengthAt: at)].
	 check value: 'run:n: has 2 OilCallDirectedSuper' value: (ops occurrencesOf: (OilInstructionConstants classPool at: #OilCallDirectedSuper)) = 2.
	 check value: 'run:n: has no OilCallSuper' value: (ops occurrencesOf: (OilInstructionConstants classPool at: #OilCallSuper)) = 0.
	 irText := String streamContents: [:s | comp printIROn: s].
	 out nextPutAll: irText; cr.
	 check value: 'printIROn: shows the directed super sends' value: (irText includesSubstring: ' above ').
	 comp pipe.
	 #(0 1 10 100) do: [:n | | expected actual |
		expected := model run: leaf new n: n.
		actual := [(OilIRInterpreter new on: comp) run: model with: {leaf new. n}] on: Error do: [:e | #error -> e description].
		check value: 'run:n: for ', n printString, ' = ', expected printString value: actual = expected]].

out cr; nextPutAll: 'TOTAL: '; print: pass; nextPutAll: ' passed, '; print: fail; nextPutAll: ' failed'; cr.
out close!
