"Oil end-to-end test (native) of Milestone 13: the debugging primitives.
 - Context>>contexts (primitiveOilContexts): the method -> pc associations of the activations the frame of an Oil method
   stands for (the methods and blocks it inlined at the call it is suspended in, then its own), innermost first.
 - Context>>deoptimize (primitiveOilDeoptimize): replaces the frame by real contexts for those activations and answers the
   innermost, whose sender chain leads to the Oil method's context; the computation then resumes in them.
 - CompiledMethod>>oilMetadata (primitiveOilMetadata): copies of the deoptimization metadata, decoded by
   OilDeoptMetadataReader (image/oil/OilDeoptMetadataReader.st, filed in from next to the image or from OilSourceDir).
 The reference for the chains and the contexts' contents is the same send run without Oil (baseline JIT), where every
 activation has its own context.  Also checks the one-argument forms of the primitives (on OilDeoptMetadataReader class).
 Run with run-st.sh on a Squeak 6.x 64-bit image with the Oil VM.  Writes oil-debugging-result.txt next to the image."
| out failures check sels cls item model items readerFile dir runAndCapture expected chainOf stackOf reference oilChain
  oilChain1 info res expectedSum meta reader reader1 callSites site gcReader triple spec r |
Utilities authorInitials: 'cb'.
out := FileStream forceNewFileNamed: (FileDirectory default fullNameFor: 'oil-debugging-result.txt').
failures := OrderedCollection new.
check := [:name :bool |
	out nextPutAll: (bool == true ifTrue: ['PASS '] ifFalse: ['FAIL ']); nextPutAll: name; cr; flush.
	bool == true ifFalse: [failures add: name]].
"OilDeoptMetadataReader, CompiledMethod>>oilMetadata, Context>>contexts / deoptimize"
dir := Smalltalk at: #OilSourceDir ifAbsent: [FileDirectory default pathName, '/'].
readerFile := (FileDirectory default fileExists: 'OilDeoptMetadataReader.st')
	ifTrue: [FileDirectory default fullNameFor: 'OilDeoptMetadataReader.st']
	ifFalse: [dir, 'OilDeoptMetadataReader.st'].
(FileStream readOnlyFileNamed: readerFile) fileIn.
check value: 'OilDeoptMetadataReader filed in' value: (Smalltalk includesKey: #OilDeoptMetadataReader).
Object subclass: #OilDbgItem instanceVariableNames: 'score' classVariableNames: '' poolDictionaries: '' category: 'OilJIT-debugging-tests'.
Object subclass: #OilDbgModel instanceVariableNames: '' classVariableNames: '' poolDictionaries: '' category: 'OilJIT-debugging-tests'.
item := Smalltalk at: #OilDbgItem. cls := Smalltalk at: #OilDbgModel.
item compile: 'score ^score' classified: 'tests'.
item compile: 'score: n score := n' classified: 'tests'.
"bonus: is inlined into the loops; probe: (thisContext: not inlinable) is a call from the inlined frame"
item compile: 'bonus: k ^k = 50 ifTrue: [self probe: k] ifFalse: [score * k]' classified: 'tests'.
item compile: 'probe: k | ctx | ctx := thisContext sender. (Smalltalk at: #OilDbgProbe) value: ctx value: thisContext. ^k * 1000' classified: 'tests'.
cls compile: 'run: a | s | s := 0. 1 to: a size do: [:i | s := s + ((a at: i) bonus: i)]. ^s' classified: 'tests'.
cls compile: 'blockRun: a | s | s := 0. a do: [:e | s := s + (e bonus: e score)]. ^s' classified: 'tests'.
cls compile: 'specRun: a | s | s := 0. 1 to: a size do: [:i | s := s + ((a at: i) bonus: i)]. ^s' classified: 'tests'.
cls class compile: 'oilSetSelectors: anArray <primitive: ''primitiveOilSetSelectors''> ^#failed' classified: 'oil'.
CompiledMethod compile: 'oilCompileFor: aClass <primitive: ''primitiveOilCompile''> ^#failed' classified: 'oil'.
CompiledMethod compile: 'oilSpecializeFor: aClass <primitive: ''primitiveOilSpecialize''> ^#failed' classified: 'oil'.
CompiledMethod compile: 'oilInfo <primitive: ''primitiveOilMethodInfo''> ^#failed' classified: 'oil'.
sels := OrderedCollection new.
#(value value: value:value: value:value:value: value:value:value:value:) doWithIndex: [:s :i | sels add: i - 1; add: s].
sels add: 5; add: #bitXor:.
#(do: reverseDo: collect: select: reject: detect: detect:ifNone: inject:into: doWithIndex: withIndexDo: timesRepeat: to:do: to:by:do: scanFor: findElementOrNil:)
	do: [:s | sels add: 6; add: s].
#(error: errorNoFreeSpace errorSubscriptBounds: errorNotIndexable subclassResponsibility halt doesNotUnderstand: primitiveFailed makeRoomAtLast makeRoomAtFirst)
	do: [:s | sels add: 7; add: s].
check value: 'primitiveOilSetSelectors' value: (cls oilSetSelectors: sels asArray) ~~ #failed.
model := cls new.
items := (1 to: 100) collect: [:k | item new score: k; yourself].
expectedSum := (1 to: 100) inject: 0 into: [:acc :k | acc + (k = 50 ifTrue: [50000] ifFalse: [k * k])].
"the activations from the probe's sender up to the one of the method sel, as method -> pc, and their temps and stacks"
chainOf := [:ctx :sel | | c chain |
	chain := OrderedCollection new. c := ctx.
	[chain add: c method -> c pc. c method == (cls >> sel)] whileFalse: [c := c sender].
	chain asArray].
"(a closure as its CompiledBlock: deoptimizing rematerializes the closures Oil dissolved)"
stackOf := [:ctx | (1 to: ctx size) collect: [:index | (ctx tempAt: index) in: [:value | (value isKindOf: BlockClosure) ifTrue: [value method] ifFalse: [value]]]].
runAndCapture := [:sel :probe | Smalltalk at: #OilDbgProbe put: probe. model perform: sel with: items].
"1. The reference: run without Oil code (baseline JIT), capturing the chains at the probe."
reference := Dictionary new.
#(run: blockRun:) do: [:sel |
	3 timesRepeat: [runAndCapture value: sel value: [:ctx :me | | c contexts |
		contexts := OrderedCollection new. c := ctx.
		(chainOf value: ctx value: sel) do: [:assoc | contexts add: c. c := c sender].
		reference at: sel put: {chainOf value: ctx value: sel. contexts collect: [:each | stackOf value: each]}]].
	check value: sel, ' without Oil = expected' value: (runAndCapture value: sel value: [:ctx :me | ]) = expectedSum].
check value: 'run: reference chain is bonus:, run:' value: ((reference at: #run:) first collect: [:assoc | assoc key selector]) = #(bonus: run:).
out nextPutAll: 'reference run: '; print: (reference at: #run:) first; cr; nextPutAll: 'reference blockRun: '; print: (reference at: #blockRun:) first; cr; flush.
"2. Oil-compile (the type feedback includes the probe: sends)."
#(run: blockRun:) do: [:sel |
	r := (cls >> sel) oilCompileFor: cls.
	out nextPutAll: sel; nextPutAll: ' oilCompileFor: -> '; print: r; cr; flush.
	check value: sel, ' compiles' value: r = 0.
	check value: sel, ' has Oil code' value: (cls >> sel) oilInfo notNil].
"3. Context>>contexts (and the one argument form) at the probe, in the Oil frame: the inlined activations."
#(run: blockRun:) do: [:sel |
	oilChain := oilChain1 := nil.
	res := runAndCapture value: sel value: [:ctx :me |
		oilChain := ctx contexts.
		oilChain1 := (OilDeoptMetadataReader contextChainOf: ctx) ifNotNil: [:pairs | pairs pairsCollect: [:m :pc | m -> pc]]].
	out nextPutAll: sel; nextPutAll: ' contexts: '; print: oilChain; cr; flush.
	check value: sel, ' with Oil = expected' value: res = expectedSum.
	check value: sel, ' contexts: several activations' value: (oilChain notNil and: [oilChain size >= 2]).
	check value: sel, ' contexts = the reference chain' value: oilChain = (reference at: sel) first.
	check value: sel, ' contextChainOf: (1 arg) = contexts' value: oilChain1 = oilChain].
"4. Context>>deoptimize at the probe: the contexts it answers are the reference's, and the computation resumes in them."
#(run: blockRun:) do: [:sel |
	info := nil.
	res := runAndCapture value: sel value: [:ctx :me | | leaf contexts c |
		leaf := sel == #run: ifTrue: [ctx deoptimize] ifFalse: [OilDeoptMetadataReader deoptimize: ctx].
		contexts := OrderedCollection new. c := leaf.
		[contexts add: c. c == ctx or: [c isNil]] whileFalse: [c := c sender].
		info := {leaf ~~ ctx. me sender == leaf. c == ctx.
				(contexts collect: [:each | each method -> each pc]) asArray.
				contexts collect: [:each | stackOf value: each].
				ctx contexts. ctx deoptimize == ctx.
				leaf receiver == (items at: 50).
				(contexts detect: [:each | each closure notNil] ifNone: [nil])
					ifNil: [true]
					ifNotNil: [:blockContext | blockContext closure outerContext == ctx and: [blockContext closure receiver == model]]}].
	out nextPutAll: sel; nextPutAll: ' deoptimize: '; print: (info ifNotNil: [info at: 4]); cr; flush.
	check value: sel, ' deoptimize answers another context' value: (info notNil and: [info first]).
	check value: sel, ' deoptimize: the probe''s sender is the leaf' value: (info notNil and: [info at: 2]).
	check value: sel, ' deoptimize: the leaf''s senders lead to the context' value: (info notNil and: [info at: 3]).
	check value: sel, ' deoptimize: methods and pcs = reference' value: (info notNil and: [(info at: 4) = (reference at: sel) first]).
	check value: sel, ' deoptimize: temps and stacks = reference' value: (info notNil and: [(info at: 5) = (reference at: sel) last]).
	check value: sel, ' deoptimize: the context is then an ordinary one' value: (info notNil and: [(info at: 6) size = 1 and: [info at: 7]]).
	check value: sel, ' deoptimize: the leaf''s receiver' value: (info notNil and: [info at: 8]).
	check value: sel, ' deoptimize: a rematerialized closure''s outerContext and receiver' value: (info notNil and: [info at: 9]).
	(info notNil and: [(info at: 5) ~= (reference at: sel) last]) ifTrue:
		[out nextPutAll: '  stacks '; print: (info at: 5); nextPutAll: ' reference '; print: (reference at: sel) last; cr; flush].
	check value: sel, ' deoptimize: computation resumes correctly' value: res = expectedSum.
	check value: sel, ' still Oil code after deoptimize' value: (cls >> sel) oilInfo notNil.
	check value: sel, ' again with Oil = expected' value: (runAndCapture value: sel value: [:ctx :me | ]) = expectedSum].
"5. Contexts that are not Oil frames."
check value: 'contexts of a baseline context' value: (thisContext contexts size = 1 and: [thisContext contexts first key == thisContext method]).
check value: 'deoptimize of a baseline context' value: thisContext deoptimize == thisContext.
check value: 'deoptimize: of a non-context fails (fallback answers it)' value: (OilDeoptMetadataReader deoptimize: 3) == 3.
"6. CompiledMethod>>oilMetadata: copies, decoded by OilDeoptMetadataReader."
meta := (cls >> #run:) oilMetadata.
check value: 'oilMetadata: one triple, for the own Oil code' value: (meta isArray and: [meta size = 1 and: [meta first first isNil]]).
reader := OilDeoptMetadataReader on: meta.
out nextPutAll: 'run: '; print: reader; cr; nextPutAll: 'frames: '; print: (reader frames collect: [:f | (f at: #method) selector]); cr; flush.
check value: 'reader: valid' value: reader isValid.
check value: 'reader: root method' value: reader rootMethod == (cls >> #run:).
check value: 'reader: frames include bonus:' value: (reader frames anySatisfy: [:f | (f at: #method) == (item >> #bonus:)]).
check value: 'reader: inlined selectors include bonus:' value: (reader inlinedSelectors notNil and: [reader inlinedSelectors includes: #bonus:]).
callSites := reader callSites.
site := callSites detect: [:each | ((reader frameAt: (each at: #frameIndex)) at: #method) == (item >> #bonus:)] ifNone: [nil].
check value: 'reader: the call site of probe:' value: site notNil.
check value: 'reader: contextsAtSite: = contexts' value: (site notNil and: [(reader contextsAtSite: site) = (reference at: #run:) first]).
check value: 'reader: deopts counted' value: reader deopts = 0.
reader1 := OilDeoptMetadataReader on: (OilDeoptMetadataReader metadataOf: cls >> #run:).
check value: 'metadataOf: (1 arg) = oilMetadata' value: (reader1 bytes = reader bytes and: [reader1 literals = reader literals]).
triple := (cls >> #run:) oilMetadataFor: cls.
check value: 'oilMetadataFor: a class (own Oil code)' value: (triple notNil and: [(triple at: 3) = reader bytes]).
check value: 'oilMetadata of a method without Oil code' value: (item >> #bonus:) oilMetadata isNil.
"the copies survive GCs that move the objects they refer to (and the Oil code's metadata keeps working)"
1 to: 100000 do: [:k | Array new: 20].
Smalltalk garbageCollect.
gcReader := OilDeoptMetadataReader on: (cls >> #run:) oilMetadata.
check value: 'reader after GC: valid, same bytes' value: (reader isValid and: [gcReader bytes = reader bytes and: [reader rootMethod == (cls >> #run:)]]).
check value: 'run: deoptimize after GC' value: (runAndCapture value: #run: value: [:ctx :me | ctx deoptimize]) = expectedSum.
"7. A specialization: one triple, with its class."
3 timesRepeat: [runAndCapture value: #specRun: value: [:ctx :me | ]].
r := (cls >> #specRun:) oilSpecializeFor: cls.
check value: 'specRun: specializes' value: r = 0.
spec := (cls >> #specRun:) oilMetadata.
check value: 'oilMetadata of a specialization: its class' value: (spec isArray and: [spec size = 1 and: [spec first first == cls]]).
check value: 'oilMetadataFor: the specialization''s class' value: (((cls >> #specRun:) oilMetadataFor: cls) ifNil: [false] ifNotNil: [:t | t first == cls]).
check value: 'oilMetadataFor: another class' value: ((cls >> #specRun:) oilMetadataFor: Object) isNil.
check value: 'specRun: deoptimize = expected' value: (runAndCapture value: #specRun: value: [:ctx :me | ctx deoptimize]) = expectedSum.
"8. Freed Oil code: its metadata is reclaimed by the GC (not freed explicitly); copies stay valid."
Smalltalk voidCogVMState.
Smalltalk garbageCollect.
check value: 'oilMetadata after voidCogVMState' value: (cls >> #run:) oilMetadata isNil.
check value: 'copy still valid after the Oil code is freed' value: (reader isValid and: [reader rootMethod == (cls >> #run:)]).
check value: 'run: after voidCogVMState' value: (runAndCapture value: #run: value: [:ctx :me | ]) = expectedSum.
out nextPutAll: (failures isEmpty ifTrue: ['ALL PASS'] ifFalse: ['FAILURES: ', failures size printString]); cr.
out close.
failures isEmpty ifFalse: [self error: 'Oil M13 test failures: ', failures printString]
