"Oil regression test (in image) for the bugs the long stress run (oil/test_oil_stress_long.st) found in Pass 1.
 1. (x + 1) - 1 folded to x when x is a register of the expression stack (the stack of an inlined frame that answered
    x + 1, e.g. OrderedCollection>>size): the result referred to that register, which the next push reused, so
    (coll size - 1) * (enc sizeDup) multiplied the result of sizeDup by itself (CascadeNode>>sizeCodeForValue:, which
    made the compiler fail with 'Compiler code size discrepancy').  The result must be a copy.
 2. x + c computed in place (x a register of the expression stack, e.g. self size + 1) recorded the affine fact
    'x = x + c' on its own register, so a later - c folded to that register, which holds x + c: String>>, (start :=
    self size + 1, then start - 1 in copyReplaceFrom:to:with:) copied one character too many (Scanner>>xBinary).
    (Oil no longer folds affine facts; the probes still check the results.)
 3. 0 - x abs (AWFY Ball>>bounce): the final jump to the exit label of the inlined Number>>abs (after its ifTrue: arm) was
    retracted although the label of its empty else arm (^self) had been bound after it, so the branch to that label skipped
    the caller's 0, materialized next: 0 - x abs computed y - x with y whatever the register held.
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
Object subclass: #OilRegressionModel instanceVariableNames: 'messages' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
Object subclass: #OilRegressionEncoder instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
cls := Smalltalk at: #OilRegressionModel.
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
(Smalltalk at: #OilRegressionEncoder) compile: 'sizeDup | s | s := WriteStream on: (Array new: 4). s nextPut: 1; nextPut: 2. ^s contents size + 5' classified: 'tests'.
(Smalltalk at: #OilRegressionEncoder) compile: 'sizePop | s | s := WriteStream on: (Array new: 4). s nextPut: 1. ^s contents size + 1' classified: 'tests'.
enc := (Smalltalk at: #OilRegressionEncoder) new.
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

"3. 0 - x abs after the exit of the inlined Number>>abs"
Object subclass: #OilRegressionBall instanceVariableNames: 'x xVel' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
(Smalltalk at: #OilRegressionBall) compile: 'x: a xVel: b x := a. xVel := b' classified: 'tests'.
(Smalltalk at: #OilRegressionBall) compile: 'step x := x + xVel. x > 500 ifTrue: [x := 500. xVel := 0 - xVel abs]. ^xVel' classified: 'tests'.
[| ballCls fbk comp |
 ballCls := Smalltalk at: #OilRegressionBall.
 fbk := OilSimulatedTypeFeedback new.
 fbk record: [(ballCls new x: 490 xVel: 20) step. (ballCls new x: 490 xVel: -20) step].
 comp := OilCompiler new.
 comp typeFeedback: fbk.
 comp compileMethod: ballCls >> #step receiverClass: (comp handleFor: ballCls).
 check value: 'step compiles' value: comp failed not.
 comp failed ifFalse:
	[comp pipe.
	 #(#(490 20) #(490 -20) #(600 -20) #(600 30) #(10 5)) do: [:pair | | expected actual |
		expected := (ballCls new x: pair first xVel: pair last) step.
		actual := [(OilIRInterpreter new on: comp) run: (ballCls new x: pair first xVel: pair last) with: #()] on: Error do: [:e | #error -> e description].
		check value: 'step for x ', pair first printString, ' xVel ', pair last printString, ' = ', expected printString value: actual = expected]]] value.

"4. Pass 1 probes of the fixes of the Pillar 1 review (each compiled and run against the real execution):
 - tvAlias: the caller's stack slot holding the remote temp t (an alias of its temp vector slot register) was copied on
   the arm of the inlined bump:if: that assigns t only (invalidateAliasesOf:), and then believed copied on both paths."
cls compile: 'bump: aBlock if: c c ifTrue: [aBlock value]. ^0' classified: 'tests'.
#('tvAlias: n | t s | t := 0. s := 0. 1 to: n do: [:i | s := s + (t + (self bump: [t := t + i] if: i odd))]. ^s')
	do: [:s | cls compile: s classified: 'tests'].
{#tvAlias: -> #(5 10)} do: [:selAndArgs | | sel fbk comp |
	sel := selAndArgs key.
	fbk := OilSimulatedTypeFeedback new.
	fbk record: [model perform: sel with: selAndArgs value first].
	comp := OilCompiler new.
	comp typeFeedback: fbk.
	comp compileMethod: cls >> sel receiverClass: (comp handleFor: cls).
	check value: sel, ' compiles' value: comp failed not.
	comp failed ifFalse:
		[comp pipe.
		 selAndArgs value do: [:arg | | expected actual |
			expected := model perform: sel with: arg.
			actual := [(OilIRInterpreter new on: comp) run: model with: {arg}] on: Error do: [:e | #error -> e description].
			check value: sel, ' for ', arg printString, ' = ', expected printString value: actual = expected]]].

out cr; nextPutAll: 'TOTAL: '; print: pass; nextPutAll: ' passed, '; print: fail; nextPutAll: ' failed'; cr.
out close!
