"Oil regression test (in image) for the bugs the long stress run (oil/test_oil_stress_long.st) found in Pass 1.
 1. (x + 1) - 1 folded to x when x is a register of the expression stack (the stack of an inlined frame that answered
    x + 1, e.g. OrderedCollection>>size): the result referred to that register, which the next push reused, so
    (coll size - 1) * (enc sizeDup) multiplied the result of sizeDup by itself (CascadeNode>>sizeCodeForValue:, which
    made the compiler fail with 'Compiler code size discrepancy').  The result must be a copy.
 2. x + c computed in place (x a register of the expression stack, e.g. self size + 1) recorded the affine fact
    'x = x + c' on its own register, so a later - c folded to that register, which holds x + c: String>>, (start :=
    self size + 1, then start - 1 in copyReplaceFrom:to:with:) copied one character too many (Scanner>>xBinary).
 Compiles probes (Pass 1 with simulated type feedback, then pipe) and runs their IR (OilIRInterpreter) against the
 methods' real execution."
| dir |
Utilities authorInitials: 'cb'.
dir := Smalltalk at: #OilSourceDir ifAbsentPut: [((FileDirectory default fileExists: 'OilConstants.st') ifTrue: [FileDirectory default] ifFalse: [FileDirectory default directoryNamed: 'oil']) pathName, '/'].
#('OilInstructionConstants.st' 'OilConstants.st' 'OilBytecodeScanner.st' 'OilCompiler.st' 'OilCompilerBackend.st' 'OilCompilerPass2.st' 'OilSimulation.st') do:
	[:f | (FileStream readOnlyFileNamed: dir, f) fileIn]!

| out pass fail check cls enc model colls |
out := FileStream forceNewFileNamed: (Smalltalk at: #OilResultFile ifAbsent: [(Smalltalk at: #OilSourceDir), 'regression-test-result.txt']).
pass := 0. fail := 0.
check := [:name :bool |
	bool == true
		ifTrue: [pass := pass + 1. out nextPutAll: 'PASS  '; nextPutAll: name; cr]
		ifFalse: [fail := fail + 1. out nextPutAll: 'FAIL  '; nextPutAll: name; cr]. out flush].
Object subclass: #OilRegModel instanceVariableNames: 'messages' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
Object subclass: #OilRegEnc instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
cls := Smalltalk at: #OilRegModel.
cls compile: 'messages: m messages := m' classified: 'tests'.
#('sizeDup: encoder ^messages size - 1 * encoder sizeDup'
  'sizeDupPop: encoder ^messages size - 1 * (encoder sizeDup + encoder sizePop)'
  'sizeTimes: encoder ^messages size * encoder sizeDup'
  'sizePlus: encoder ^messages size - 1 + encoder sizeDup'
  'tempMinus: encoder | x | x := 4. ^x + 1 - 1 * encoder sizeDup'
  'sizeOffset: encoder ^messages size + 1 - 1'
  'sizeArgOffset: encoder ^self minusOne: messages size + 1'
  'minusOne: n ^n - 1'
  'concat: encoder | token | token := String with: $a. 1 to: messages size do: [:i | token := token , (String with: $b)]. ^token')
	do: [:s | cls compile: s classified: 'tests'].
(Smalltalk at: #OilRegEnc) compile: 'sizeDup | s | s := WriteStream on: (Array new: 4). s nextPut: 1; nextPut: 2. ^s contents size + 5' classified: 'tests'.
(Smalltalk at: #OilRegEnc) compile: 'sizePop | s | s := WriteStream on: (Array new: 4). s nextPut: 1. ^s contents size + 1' classified: 'tests'.
enc := (Smalltalk at: #OilRegEnc) new.
colls := {OrderedCollection new add: 1; add: 2; add: 3; add: 4; add: 5; yourself. OrderedCollection new add: 1; yourself. OrderedCollection new}.
model := cls new.
{#(#sizeDup: #sizeDupPop: #sizeTimes: #sizePlus: #tempMinus:) -> colls.
 #(#sizeOffset: #sizeArgOffset: #concat:) -> {#(1 2 3 4 5). #(1). #()}} do: [:selsAndColls |
 selsAndColls key do: [:sel | | fbk comp |
	colls := selsAndColls value.
	fbk := OilSimulatedTypeFeedback new.
	model messages: colls first.
	fbk record: [model perform: sel with: enc].
	comp := OilCompiler new.
	comp typeFeedback: fbk.
	comp compileMethod: cls >> sel receiverClass: (comp handleFor: cls).
	check value: sel, ' compiles' value: comp failed not.
	comp failed ifFalse:
		[comp pipe.
		 colls do: [:coll | | expected actual |
			model messages: coll.
			expected := model perform: sel with: enc.
			actual := [(OilIRInterpreter new on: comp) run: model with: {enc}] on: Error do: [:e | #error -> e description].
			check value: sel, ' on ', coll size printString, ' elements = ', expected printString value: actual = expected]]]].

out cr; nextPutAll: 'TOTAL: '; print: pass; nextPutAll: ' passed, '; print: fail; nextPutAll: ' failed'; cr.
out close!
