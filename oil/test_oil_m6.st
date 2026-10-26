"Oil end-to-end test (native) of OilFullCompiler: Float arithmetic and float fusion (unboxed chains, Mandelbrot),
 float deoptimization (non-Float operands, zero divisor, boxed results, exact comparisons), and dominator-scoped value
 numbering (redundant loads and checks).  Run with run-st.sh on a Squeak 6.x 64-bit image with the Oil VM.
 Writes oil-m6-result.txt next to the image."
| out failures check sels model res last stats base oil r expected expected400 info |
Utilities authorInitials: 'cb'.
out := FileStream forceNewFileNamed: (FileDirectory default fullNameFor: 'oil-m6-result.txt').
failures := OrderedCollection new.
check := [:name :bool |
	out nextPutAll: (bool == true ifTrue: ['PASS '] ifFalse: ['FAIL ']); nextPutAll: name; cr; flush.
	bool == true ifFalse: [failures add: name]].
Object subclass: #OilFloatModel instanceVariableNames: 'total' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilDebugging'.
#('mandelbrot: size
    "Escape time Mandelbrot: the number of points of a size x size grid in the set (50 iterations)."
    | count zr zi cr ci tr i |
    count := 0.
    0 to: size - 1 do: [:y |
        ci := 2.0 * y / size - 1.0.
        0 to: size - 1 do: [:x |
            cr := 2.0 * x / size - 1.5.
            zr := 0.0. zi := 0.0. i := 0.
            [i < 50 and: [zr * zr + (zi * zi) <= 4.0]] whileTrue:
                [tr := zr * zr - (zi * zi) + cr.
                 zi := 2.0 * zr * zi + ci.
                 zr := tr.
                 i := i + 1].
            i = 50 ifTrue: [count := count + 1]]].
    ^count'
  'axpy: a x: x y: y ^a * x + y'
  'poly: x ^(x * x * 3.0) - (x * 2.0) + 1.0'
  'ratio: a by: b ^a / b + 1.0'
  'less: a than: b ^a < b ifTrue: [1] ifFalse: [2]'
  'notEqual: a to: b ^a ~= b'
  'twice: x ^2 * x'
  'norm: aPoint | dx dy | dx := aPoint x * 1.0. dy := aPoint y * 1.0. ^dx * dx + (dy * dy)'
  'sumSquares: anArray | s | s := 0.0. 1 to: anArray size do: [:i | s := s + ((anArray at: i) * (anArray at: i))]. ^s'
  'lvnLoop: anArray | s | s := 0. 1 to: anArray size do: [:i | s := s + (anArray at: i) + (anArray at: i)]. ^s + total + total'
  'lvnBranch: anArray at: i | a | a := anArray at: i. ^a > 0 ifTrue: [(anArray at: i) + total] ifFalse: [(anArray at: i) - total]'
  'lvnStore: x total := x. ^total + total'
  'total: n total := n')
	do: [:s | (Smalltalk at: #OilFloatModel) compile: s classified: 'tests'].
(Smalltalk at: #OilFloatModel) class compile: 'oilSetColdSelectors: anArray <primitive: ''primitiveOilSetColdSelectors''> ^#failed' classified: 'oil'.
(Smalltalk at: #OilFloatModel) class compile: 'autonomousCompilation: aBoolean <primitive: ''primitiveOilSetAutonomousCompilation''> ^#failed' classified: 'oil'.
(Smalltalk at: #OilFloatModel) class compile: 'disqualifyLimit: anInteger <primitive: ''primitiveOilSetDisqualifyLimit''> ^#failed' classified: 'oil'.
(Smalltalk at: #OilFloatModel) class compile: 'oilSetParameter: index to: value
	"(the former primitiveOilSetParameter: 19 autonomous compilation, 8 the disqualify limit; the others are gone)"
	index = 19 ifTrue: [^self autonomousCompilation: value ~= 0].
	index = 8 ifTrue: [^self disqualifyLimit: value].
	^self' classified: 'oil'.
"(the kind/value pairs of the former primitiveOilSetSelectors: the cold selectors, kind 7, and the parameters, kinds 8 and 12 to 18,
 the others at their default; the value selectors, bitXor: and the iterators are built in; no autonomous compilation)"
(Smalltalk at: #OilFloatModel) class compile: 'oilSetSelectors: pairs
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
#(do: reverseDo: collect: select: reject: detect: detect:ifNone: inject:into: doWithIndex: withIndexDo: timesRepeat: to:do: to:by:do:)
	do: [:s | sels add: 6; add: s].
#(error: errorSubscriptBounds: errorNotIndexable subclassResponsibility halt doesNotUnderstand: primitiveFailed)
	do: [:s | sels add: 7; add: s].
check value: 'primitiveOilSetSelectors' value: ((Smalltalk at: #OilFloatModel) oilSetSelectors: sels asArray) ~~ #failed.
model := (Smalltalk at: #OilFloatModel) new total: 7; yourself.
"compile: warm up (baseline JIT), Oil-compile, answer the compile result; stats are Pass 2's statistics
 (9 loads removed, 10 checks removed, 11 unboxed float results)"
res := [:sel :warm | | cm |
	cm := (Smalltalk at: #OilFloatModel) >> sel.
	3 timesRepeat: warm.
	r := cm oilCompileFor: (Smalltalk at: #OilFloatModel).
	last := CompiledMethod oilLastCompilation.
	stats := last at: 11.
	out nextPutAll: sel; nextPutAll: ': oilCompileFor: -> '; print: r; nextPutAll: ' (Pass 2 '; print: stats; nextPutAll: ')'; cr; flush.
	r].

"--- 1. Mandelbrot: fused float chains ---"
expected := model mandelbrot: 60.
base := Time millisecondsToRun: [expected400 := model mandelbrot: 400].
check value: 'mandelbrot: compiles' value: (res value: #mandelbrot: value: [model mandelbrot: 20]) = 0.
check value: 'mandelbrot: has unboxed float results' value: (stats at: 11) > 0.
check value: 'mandelbrot: result' value: (model mandelbrot: 60) = expected.
check value: 'mandelbrot: result 400' value: (model mandelbrot: 400) = expected400.
oil := Time millisecondsToRun: [model mandelbrot: 400].
info := ((Smalltalk at: #OilFloatModel) >> #mandelbrot:) oilInfo.
check value: 'mandelbrot: still Oil code, no deopt' value: (info notNil and: [(info at: 1) = 0]).
out nextPutAll: 'mandelbrot: 400x400: Oil '; print: oil; nextPutAll: ' ms, baseline '; print: base; nextPutAll: ' ms'; cr.

"--- 2. Float arithmetic: mixed operands, boxed results, swapped operands ---"
check value: 'axpy:x:y: compiles' value: (res value: #axpy:x:y: value: [model axpy: 2.0 x: 3.5 y: 0.25]) = 0.
check value: 'axpy:x:y: unboxes a * x' value: (stats at: 11) = 1.
check value: 'axpy:x:y: floats' value: (model axpy: 2.0 x: 3.5 y: 0.25) = 7.25.
check value: 'axpy:x:y: SmallInteger arguments' value: (model axpy: 2.0 x: 3 y: 1) = 7.0.
check value: 'axpy:x:y: boxed values' value: (model axpy: 1.0e300 x: 1.0e10 y: 1.0e300) = (1.0e300 * 1.0e10 + 1.0e300).
check value: 'axpy:x:y: tiny values' value: (model axpy: 1.0e-30 x: 1.0e-30 y: 0.0) = (1.0e-30 * 1.0e-30).
check value: 'axpy:x:y: infinity' value: (model axpy: 1.0e300 x: 1.0e300 y: 1.0) = Float infinity.
check value: 'axpy:x:y: no deopt so far' value: (((Smalltalk at: #OilFloatModel) >> #axpy:x:y:) oilInfo at: 1) = 0.
check value: 'axpy:x:y: SmallInteger receiver (deopt)' value: (model axpy: 2 x: 3.0 y: 1.0) = 7.0.
check value: 'poly: compiles' value: (res value: #poly: value: [model poly: 1.5]) = 0.
check value: 'poly: result' value: ((-3 to: 3) collect: [:k | model poly: k / 2.0]) = ((-3 to: 3) collect: [:k | | x | x := k / 2.0. (x * x * 3.0) - (x * 2.0) + 1.0]).
check value: 'twice: compiles (2 * aFloat, swapped)' value: (res value: #twice: value: [model twice: 1.25]) = 0.
check value: 'twice: result' value: (model twice: 1.25) = 2.5.
check value: 'sumSquares: compiles' value: (res value: #sumSquares: value: [model sumSquares: #(1.0 2.0)]) = 0.
check value: 'sumSquares: result' value: (model sumSquares: ((1 to: 1000) collect: [:k | k * 0.5])) = ((1 to: 1000) inject: 0.0 into: [:a :k | a + (k * 0.5 * (k * 0.5))]).
check value: 'norm: compiles' value: (res value: #norm: value: [model norm: 3.0 @ 4.0]) = 0.
check value: 'norm: result' value: (model norm: 3.0 @ 4.0) = 25.0.

"--- 3. Float deoptimization ---"
check value: 'ratio:by: compiles' value: (res value: #ratio:by: value: [model ratio: 3.0 by: 2.0]) = 0.
check value: 'ratio:by: result' value: (model ratio: 3.0 by: 2.0) = 2.5.
check value: 'ratio:by: zero divisor (deopt, ZeroDivide)' value: ([model ratio: 3.0 by: 0.0] on: ZeroDivide do: [:e | #zeroDivide]) = #zeroDivide.
check value: 'less:than: compiles' value: (res value: #less:than: value: [model less: 1.0 than: 2.0]) = 0.
check value: 'less:than: results' value: ((model less: 1.0 than: 2.0) = 1 and: [(model less: 2.0 than: 1.0) = 2 and: [(model less: 1.0 than: 1.0) = 2]]).
check value: 'less:than: NaN' value: ((model less: Float nan than: 1.0) = 2 and: [(model less: 1.0 than: Float nan) = 2]).
check value: 'less:than: SmallInteger argument' value: ((model less: 2.5 than: 3) = 1 and: [(model less: 3.0 than: 3) = 2]).
check value: 'less:than: exact comparison with a large SmallInteger (deopt)' value: (model less: (2 raisedTo: 55) asFloat than: (2 raisedTo: 55) + 1) = 1.
check value: 'notEqual:to: compiles' value: (res value: #notEqual:to: value: [model notEqual: 1.0 to: 2.0]) = 0.
check value: 'notEqual:to: results' value: ((model notEqual: 1.0 to: 2.0) and: [(model notEqual: 2.0 to: 2.0) not and: [model notEqual: Float nan to: Float nan]]).

"--- 4. Dominator-scoped value numbering ---"
check value: 'lvnLoop: compiles' value: (res value: #lvnLoop: value: [model lvnLoop: #(1 2 3)]) = 0.
check value: 'lvnLoop: removes a load (total) and a size' value: (stats at: 9) >= 1.
check value: 'lvnLoop: result' value: (model lvnLoop: (1 to: 100) asArray) = (5050 * 2 + 14).
check value: 'lvnBranch:at: compiles' value: (res value: #lvnBranch:at: value: [model lvnBranch: #(1 -2) at: 1. model lvnBranch: #(1 -2) at: 2]) = 0.
check value: 'lvnBranch:at: removes dominated checks' value: (stats at: 10) >= 2.
check value: 'lvnBranch:at: results' value: ((model lvnBranch: #(5 -5) at: 1) = 12 and: [(model lvnBranch: #(5 -5) at: 2) = -12]).
check value: 'lvnBranch:at: out of bounds still fails' value: ([model lvnBranch: #(5 -5) at: 3] on: Error do: [:e | #error]) = #error.
check value: 'lvnStore: compiles' value: (res value: #lvnStore: value: [model lvnStore: 3]) = 0.
check value: 'lvnStore: forwards the store' value: (stats at: 9) >= 2.
check value: 'lvnStore: result' value: ((model lvnStore: 21) = 42 and: [(model lvnStore: 0.5) = 1.0]).
model total: 7.

"--- 5. Recompilation: Oil code is discarded when its methods change, and everything still works ---"
Smalltalk garbageCollect.
check value: 'full GC' value: (model mandelbrot: 30) = ((Smalltalk at: #OilFloatModel) new mandelbrot: 30).
(Smalltalk at: #OilFloatModel) compile: 'axpy: a x: x y: y ^a * x - y' classified: 'tests'.
check value: 'axpy:x:y: redefined' value: (model axpy: 2.0 x: 3.5 y: 0.25) = 6.75.
out nextPutAll: (failures isEmpty ifTrue: ['ALL PASS'] ifFalse: ['FAILURES: ', failures size printString]); cr.
out close.
failures isEmpty ifFalse: [self error: 'Oil M6 test failures: ', failures printString]
