"Oil end-to-end test (native) of the inlined selector invalidation table.  An Oil method records in its metadata every
 selector Oil looked up when compiling it (inlined methods, quick methods/getters, intrinsics); defining a method of one of
 them (Symbol>>flushCache, ProfilingCogit>>unlinkSendsOf:isMNUSelector:) frees the Oil method.  Each probe Oil-compiles a
 caller, redefines a method it depends on, and checks that the Oil code is gone and that the result follows the new
 definition; defining an unrelated selector must keep the Oil code.
 Run with run-st.sh on a Squeak 6.x 64-bit image with the Oil VM.  Writes oil-invalidation-result.txt next to the image."
| out failures check sels model cls items arr compile hasOil |
Utilities authorInitials: 'cb'.
out := FileStream forceNewFileNamed: (FileDirectory default fullNameFor: 'oil-invalidation-result.txt').
failures := OrderedCollection new.
check := [:name :bool |
	out nextPutAll: (bool == true ifTrue: ['PASS '] ifFalse: ['FAIL ']); nextPutAll: name; cr; flush.
	bool == true ifFalse: [failures add: name]].
Object subclass: #OilInvalidationBase instanceVariableNames: 'x y' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
(Smalltalk at: #OilInvalidationBase) subclass: #OilInvalidationItem instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
Array variableSubclass: #OilInvArray instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
Object subclass: #OilInvalidationModel instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'VMMaker-JIT-OilTest'.
#('x ^x' 'y ^y' 'x: ax y: ay x := ax. y := ay' 'double ^x + x') do: [:src | (Smalltalk at: #OilInvalidationBase) compile: src classified: 'accessing'].
cls := Smalltalk at: #OilInvalidationModel.
#('sumX: items | t | t := 0. items do: [:e | t := t + e x]. ^t'
  'sumY: items | t | t := 0. items do: [:e | t := t + e y]. ^t'
  'sumDouble: items | t | t := 0. items do: [:e | t := t + e double]. ^t'
  'sumAt: anArray | t | t := 0. 1 to: anArray size do: [:i | t := t + (anArray at: i)]. ^t'
  'sumBoth: items | t | t := 0. items do: [:e | t := t + e x + e y]. ^t')
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
sels := OrderedCollection new.
#(value value: value:value: value:value:value: value:value:value:value:) doWithIndex: [:s :i | sels add: i - 1; add: s].
sels add: 5; add: #bitXor:.
#(do: reverseDo: collect: select: reject: detect: detect:ifNone: inject:into: doWithIndex: withIndexDo: timesRepeat: to:do: to:by:do:)
	do: [:s | sels add: 6; add: s].
#(error: errorSubscriptBounds: errorNotIndexable subclassResponsibility halt doesNotUnderstand: primitiveFailed)
	do: [:s | sels add: 7; add: s].
check value: 'primitiveOilSetSelectors' value: (cls oilSetSelectors: sels asArray) ~~ #failed.
model := cls new.
items := (1 to: 10) collect: [:i | (Smalltalk at: #OilInvalidationItem) new x: i y: 100 * i].
arr := (Smalltalk at: #OilInvArray) new: 10.
1 to: 10 do: [:i | arr at: i put: i].
hasOil := [:sel | (cls >> sel) oilInfo notNil].
compile := [:sel :arg | | r |
	3 timesRepeat: [model perform: sel with: arg].
	r := (cls >> sel) oilCompileFor: cls.
	check value: sel, ' Oil-compiles' value: (r = 0 and: [hasOil value: sel]).
	r].
"1. a quick getter (^x), inlined: redefining it frees the Oil code"
compile value: #sumX: value: items.
check value: 'sumX: = 55' value: (model sumX: items) = 55.
(Smalltalk at: #OilInvalidationItem) compile: 'unrelatedOilInvSelector ^3' classified: 'accessing'.
check value: 'an unrelated selector keeps the Oil code of sumX:' value: (hasOil value: #sumX:).
(Smalltalk at: #OilInvalidationBase) compile: 'x ^x * 2' classified: 'accessing'.
check value: 'redefined quick getter x frees the Oil code of sumX:' value: (hasOil value: #sumX:) not.
check value: 'sumX: = 110 after redefining x' value: (model sumX: items) = 110.
"2. a quick getter found in a superclass: an override in the receiver's class frees the Oil code"
compile value: #sumY: value: items.
(Smalltalk at: #OilInvalidationItem) compile: 'y ^1' classified: 'accessing'.
check value: 'override of y frees the Oil code of sumY:' value: (hasOil value: #sumY:) not.
check value: 'sumY: = 10 after overriding y' value: (model sumY: items) = 10.
"3. an inlined method (an inlined frame)"
compile value: #sumDouble: value: items.
(Smalltalk at: #OilInvalidationBase) compile: 'double ^x + x + 1' classified: 'accessing'.
check value: 'redefined double frees the Oil code of sumDouble:' value: (hasOil value: #sumDouble:) not.
check value: 'sumDouble: = 120 after redefining double' value: (model sumDouble: items) = 120.
"4. an intrinsic (Object>>at: of an Array subclass, primitive 60): an override frees the Oil code"
compile value: #sumAt: value: arr.
check value: 'sumAt: = 55' value: (model sumAt: arr) = 55.
(Smalltalk at: #OilInvArray) compile: 'at: index ^(super at: index) + 1000' classified: 'accessing'.
check value: 'override of at: frees the Oil code of sumAt:' value: (hasOil value: #sumAt:) not.
check value: 'sumAt: = 10055 after overriding at:' value: (model sumAt: arr) = 10055.
"5. removing a method: the receivers find the superclass's again"
compile value: #sumBoth: value: items.
check value: 'sumBoth: = 120' value: (model sumBoth: items) = 120.
(Smalltalk at: #OilInvalidationItem) removeSelector: #y.
check value: 'removing y frees the Oil code of sumBoth:' value: (hasOil value: #sumBoth:) not.
check value: 'sumBoth: = 5610 after removing y' value: (model sumBoth: items) = 5610.
"6. recompiled after the change, the Oil code inlines the new definitions"
compile value: #sumX: value: items.
check value: 'sumX: = 110 recompiled' value: (model sumX: items) = 110.
Smalltalk garbageCollect.
(Smalltalk at: #OilInvalidationBase) compile: 'x ^x' classified: 'accessing'.
check value: 'after a full GC, redefining x frees the Oil code of sumX:' value: (hasOil value: #sumX:) not.
check value: 'sumX: = 55 at the end' value: (model sumX: items) = 55.
"7. (found by the stress run) an Oil method deoptimized while called from an interpreter frame, then given baseline code
 by its loop's back jump in the interpreter (convertToMachineCodeFrame:bcpc:) must return to its caller's pc.  Both methods
 are compiled for OilInvalidationBase and run on an OilInvalidationItem: their entry guards fail, and deoptimized twice they are freed."
(Smalltalk at: #OilInvalidationBase) compile: 'val ^x' classified: 'accessing'.
(Smalltalk at: #OilInvalidationBase) compile: 'loop: n | t | t := 0. 1 to: n do: [:i | t := t + self val]. ^t' classified: 'tests'.
(Smalltalk at: #OilInvalidationBase) compile: 'callLoop: n | a | a := self val. ^a + (self loop: n) + 1' classified: 'tests'.
[| base item r1 r2 |
 base := (Smalltalk at: #OilInvalidationBase) new x: 2 y: 0.
 item := (Smalltalk at: #OilInvalidationItem) new x: 3 y: 0.
 3 timesRepeat: [base callLoop: 10].
 r1 := ((Smalltalk at: #OilInvalidationBase) >> #loop:) oilCompileFor: (Smalltalk at: #OilInvalidationBase).
 r2 := ((Smalltalk at: #OilInvalidationBase) >> #callLoop:) oilCompileFor: (Smalltalk at: #OilInvalidationBase).
 check value: 'loop: and callLoop: Oil-compile' value: (r1 = 0 and: [r2 = 0]).
 check value: 'deopted from an interpreter frame, then switched to baseline code'
	value: ((1 to: 4) allSatisfy: [:k | (item callLoop: 1000) = 3004]).
 check value: 'callLoop: of an OilInvalidationBase' value: (base callLoop: 1000) = 2003]
	on: Error do: [:e | check value: 'deopt from an interpreter frame: ', e description value: false].
"8. a method inlined by an Oil method that is running (on the stack) changes: the Oil method cannot be freed, but new
 activations must run the new definition (the running one finishes in the Oil code)."
(Smalltalk at: #OilInvalidationBase) compile: 'w ^x' classified: 'accessing'.
(Smalltalk at: #OilInvalidationBase) compile: 'reent: aBlock ^self w + aBlock value + self w' classified: 'tests'.
[| base r |
 base := (Smalltalk at: #OilInvalidationBase) new x: 1 y: 0.
 5 timesRepeat: [base reent: [0]].
 check value: 'reent: Oil-compiles' value: (((Smalltalk at: #OilInvalidationBase) >> #reent:) oilCompileFor: (Smalltalk at: #OilInvalidationBase)) = 0.
 r := base reent: [(Smalltalk at: #OilInvalidationBase) compile: 'w ^x * 10' classified: 'accessing'. 0].
 check value: 'redefined while running: the running activation answers 2 or 11' value: (r = 2 or: [r = 11]).
 check value: 'redefined while running: no Oil code any more' value: ((Smalltalk at: #OilInvalidationBase) >> #reent:) oilInfo isNil.
 check value: 'redefined while running: the next activation runs the new definition' value: (base reent: [0]) = 20.
 Smalltalk garbageCollect.
 check value: 'redefined while running: after a full GC' value: (base reent: [0]) = 20]
	on: Error do: [:e | check value: 'redefined while running: ', e description value: false].
out nextPutAll: (failures isEmpty ifTrue: ['ALL PASS'] ifFalse: ['FAILURES: ', failures size printString]); cr.
out close.
failures isEmpty ifFalse: [self error: 'Oil invalidation test failures: ', failures printString]
