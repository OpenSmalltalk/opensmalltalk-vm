!OilBaseCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
printIROn: aStream
	"Dump the flattened linear IR buffer: frames, instructions (index, opcode, operands, deopt site), deopt sites, statistics."
	<doNotGenerate>
	| labels i |
	aStream nextPutAll: (oilIRBuffer == oilIRBuffer2 ifTrue: ['=== Oil Pass 2 IR: '] ifFalse: ['=== Oil Pass 1 IR: ']); print: rootMethod; nextPutAll: ' for receiver class '; print: (self objectFor: rootClass).
	aStream nextPutAll: (eagerClosures ifTrue: ['  [eager closures]'] ifFalse: ['  [virtual closures]']); cr.
	failed ifTrue:
		[aStream nextPutAll: 'FAILED: '; nextPutAll: (OilConstants failureNames at: failureCode + 1); cr].
	aStream nextPutAll: 'Inlined frames:'; cr.
	0 to: numFrames - 1 do:
		[:f|
		aStream tab; nextPut: $#; print: f; nextPutAll: ' depth '; print: (frameDepth at: f);
			nextPutAll: (String new: (frameDepth at: f) * 2 withAll: $ ); space;
			print: (frameMethod at: f); nextPutAll: '  base r'; print: (frameBase at: f).
		(frameParent at: f) >= 0 ifTrue:
			[aStream nextPutAll: '  (from #'; print: (frameParent at: f); nextPutAll: ' pc '; print: (frameCallPC at: f); nextPut: $)].
		aStream cr].
	labels := Set new.
	i := 0.
	[i < irIndex] whileTrue:
		[(self isBranch: (self opcodeAt: i)) ifTrue: [labels add: (self imm16At: i)].
		 i := i + (self instructionLengthAt: i)].
	aStream nextPutAll: 'IR ('; print: irInstCount; nextPutAll: ' instructions, '; print: irIndex; nextPutAll: ' words, ';
		print: irIndex * 4; nextPutAll: ' bytes):'; cr.
	i := 0.
	[i < irIndex] whileTrue:
		[(labels includes: i) ifTrue: [aStream nextPutAll: 'L'; nextPutAll: (i printPaddedWith: $0 to: 4); nextPut: $:; cr].
		 self printInstructionAt: i on: aStream.
		 i := i + (self instructionLengthAt: i)].
	aStream nextPutAll: 'Deopt sites ('; print: numSites; nextPutAll: '):'; cr.
	0 to: numSites - 1 do:
		[:s|
		aStream tab; nextPutAll: 'deopt#'; print: s; nextPutAll: ' IR '; nextPutAll: ((siteIR at: s) printPaddedWith: $0 to: 4);
			nextPutAll: ' '; nextPutAll: (#('guard' 'arith' 'bounds' 'call' 'branch' 'store' 'alloc') at: (siteKind at: s));
			nextPutAll: ' -> frame #'; print: (siteFrame at: s); nextPutAll: ' '; print: (frameMethod at: (siteFrame at: s));
			nextPutAll: ' pc '; print: (sitePC at: s); cr].
	aStream nextPutAll: 'Stats: virtual objects '; print: numVObjs;
		nextPutAll: ', high registers '; print: OilMaxReg - highRegTop; cr! !

!OilBaseCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
printInstructionAt: i on: aStream
	<doNotGenerate>
	| op a b c name site |
	op := self opcodeAt: i. a := self fieldAAt: i. b := self fieldBAt: i. c := self fieldCAt: i.
	name := (op between: 1 and: OilLastOpcode) ifTrue: [OilConstants opcodeNames at: op] ifFalse: ['?', op printString].
	aStream nextPutAll: '  '; nextPutAll: (i printPaddedWith: $0 to: 4); nextPutAll: '  ';
		nextPutAll: ((self hexWord: (oilIRBuffer at: i))); nextPutAll: '  ';
		nextPutAll: (name , (String new: (14 - name size max: 1) withAll: $ )).
	op caseOf: {
		[OilConstTagged]	-> [| t | t := self signed16: (self imm16At: i).
							 aStream nextPutAll: (self reg: a), ' := ', ((t - 1) // 8) printString, '   (tagged ', t printString, ')'].
		[OilConst64]		-> [aStream nextPutAll: (self reg: a), ' := ', (self printHandle: (self word64At: i + 1))].
		[OilMove]			-> [aStream nextPutAll: (self reg: a), ' := ', (self reg: b)].
		[OilAddTagged]	-> [aStream nextPutAll: (self reg: a), ' := ', (self reg: b), ' + ', (self reg: c)].
		[OilSubTagged]	-> [aStream nextPutAll: (self reg: a), ' := ', (self reg: b), ' - ', (self reg: c)].
		[OilAndTagged]	-> [aStream nextPutAll: (self reg: a), ' := ', (self reg: b), ' bitAnd: ', (self reg: c), '   (andq, no untagging)'].
		[OilOrTagged]		-> [aStream nextPutAll: (self reg: a), ' := ', (self reg: b), ' bitOr: ', (self reg: c), '   (orq, no untagging)'].
		[OilXorTagged]	-> [aStream nextPutAll: (self reg: a), ' := ', (self reg: b), ' bitXor: ', (self reg: c), '   (xorq; orq $1)'].
		[OilShiftTagged]	-> [| k | k := self signed8: c.
							 aStream nextPutAll: (self reg: a), ' := ', (self reg: b),
								(k > 0 ifTrue: [' >> ', k printString, '   (// ', (1 bitShift: k) printString, ': sarq $', (3 + k) printString, '; shlq $3; orq $1)']
									ifFalse: [' << ', k negated printString, '   (* ', (1 bitShift: k negated) printString, ')'])].
		[OilOddTagged]	-> [aStream nextPutAll: (self reg: a), ' := ', (self reg: b), ' \\ 2   ((x bitAnd: 8) bitOr: 1)'].
		[OilLoadField]	-> [aStream nextPutAll: (self reg: a), ' := ', (self reg: b), '.slot[', c printString, ']'].
		[OilStoreField]	-> [aStream nextPutAll: (self reg: b), '.slot[', c printString, '] := ', (self reg: a), '   (store check)'].
		[OilLoadElement]	-> [aStream nextPutAll: (self reg: a), ' := ', (self reg: b), '[', (self reg: c), ']   (movq -1(arr,idx))'].
		[OilStoreElement]	-> [aStream nextPutAll: (self reg: b), '[', (self reg: c), '] := ', (self reg: a), '   (store check)'].
		[OilCmpTagged]	-> [aStream nextPutAll: (self reg: b), ' ', (self condName: a), ' ', (self reg: c)].
		[OilCmpImmTagged]	-> [aStream nextPutAll: (self reg: b), ' ', (self condName: a), ' ', (self signed8: c) printString].
		[OilBranchTrue]	-> [aStream nextPutAll: (a = OilFlagsReg ifTrue: ['flags'] ifFalse: [self reg: a]), ' -> L', ((self imm16At: i) printPaddedWith: $0 to: 4)].
		[OilBranchFalse]	-> [aStream nextPutAll: (a = OilFlagsReg ifTrue: ['flags'] ifFalse: [self reg: a]), ' -> L', ((self imm16At: i) printPaddedWith: $0 to: 4)].
		[OilJump]			-> [aStream nextPutAll: '-> L', ((self imm16At: i) printPaddedWith: $0 to: 4)].
		[OilReturn]		-> [aStream nextPutAll: (self reg: a)].
		[OilGuardClass]	-> [aStream nextPutAll: 'class(', (self reg: a), ') == ', (self printHandle: (self word64At: i + 1))].
		[OilCheckBounds]	-> [aStream nextPutAll: '1 <= ', (self reg: a), ' <= ', (self reg: b)].
		[OilCall0]			-> [aStream nextPutAll: (self reg: a), ' := ', (self reg: b), ' ', (self printHandle: (self word64At: i + 1))].
		[OilCall1]			-> [aStream nextPutAll: (self reg: a), ' := ', (self reg: b), ' ', (self printHandle: (self word64At: i + 1)), ' ', (self reg: c)].
		[OilCallN]			-> [aStream nextPutAll: (self reg: a), ' := ', (self reg: b), ' ', (self printHandle: (self word64At: i + 1)), ' (', (self packedArgsAt: i + 3 count: c), ')'].
		[OilCallSuper]		-> [aStream nextPutAll: (self reg: a), ' := super ', (self printHandle: (self word64At: i + 1)), ' rcvr ', (self reg: b), ' (', (self packedArgsAt: i + 3 count: c), ')'].
		[OilAddImmTagged]	-> [| k | k := self signed8: c. aStream nextPutAll: (self reg: a), ' := ', (self reg: b), (k >= 0 ifTrue: [' + '] ifFalse: [' - ']), k abs printString, '   (addq $', (k * 8) printString, ')'].
		[OilTrap]			-> [aStream nextPutAll: 'uncommon trap'].
		[OilStreamNext]		-> [aStream nextPutAll: (self reg: a), ' := ', (self reg: b), ' next   (inlined, else sent)'].
		[OilStreamNextPut]	-> [aStream nextPutAll: (self reg: a), ' := ', (self reg: b), ' nextPut: ', (self reg: c), '   (inlined, else sent)'].
		[OilCharValue]		-> [aStream nextPutAll: (self reg: a), ' := ', (self reg: b), ' asInteger'].
		[OilLoadByteSize]	-> [aStream nextPutAll: (self reg: a), ' := byteSize(', (self reg: b), ')'].
		[OilLoadByte]		-> [aStream nextPutAll: (self reg: a), ' := ', (self reg: b), '[', (self reg: c), '] (byte)'].
		[OilLoadChar]		-> [aStream nextPutAll: (self reg: a), ' := ', (self reg: b), '[', (self reg: c), '] (Character)'].
		[OilStoreByte]		-> [aStream nextPutAll: (self reg: b), '[', (self reg: c), '] := ', (self reg: a), ' (byte)'].
		[OilStoreChar]		-> [aStream nextPutAll: (self reg: b), '[', (self reg: c), '] := ', (self reg: a), ' (Character)'].
		[OilCompareBytes]	-> [aStream nextPutAll: (self reg: a), ' := ', (self reg: b), ' compareWith: ', (self reg: c)].
		[OilModTagged]		-> [aStream nextPutAll: (self reg: a), ' := ', (self reg: b), ' \\ ', (self reg: c), '   (idiv; floored)'].
		[OilAddImmTaggedNC]	-> [| k | k := self signed8: c. aStream nextPutAll: (self reg: a), ' := ', (self reg: b), (k >= 0 ifTrue: [' + '] ifFalse: [' - ']), k abs printString, '   (addq $', (k * 8) printString, ', no overflow check)'].
		[OilLoadSize]		-> [aStream nextPutAll: (self reg: a), ' := size(', (self reg: b), ')'].
		[OilMakeClosure]	-> [aStream nextPutAll: (self reg: a), ' := closure ', (self printHandle: (self word64At: i + 1)), ' self ', (self reg: (self fieldCAt: i + 3)), ' copied ', c printString, ' from ', (self reg: b)].
		[OilNewArray]		-> [aStream nextPutAll: (self reg: a), ' := Array new: ', c printString, (b = OilFlagsReg ifTrue: ['   (nil filled)'] ifFalse: ['   from ', (self reg: b), '..', (self reg: b + c - 1)])] }
		otherwise: [].
	site := (0 to: numSites - 1) detect: [:s| (siteIR at: s) = i] ifNone: [nil].
	site ifNotNil:
		[aStream nextPutAll: '   ; deopt#'; print: site; nextPutAll: ' #'; print: (siteFrame at: site); nextPutAll: ' pc '; print: (sitePC at: site)].
	aStream cr! !

!OilBaseCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
hexWord: w
	<doNotGenerate>
	| s |
	s := (w printStringBase: 16) asUppercase.
	^(String new: (8 - s size max: 0) withAll: $0), s! !

!OilBaseCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
reg: r
	<doNotGenerate>
	^'r', r printString! !

!OilBaseCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
condName: c
	<doNotGenerate>
	^#('<' '>' '<=' '>=' '=' '~=' '==' '~~') at: c! !

!OilBaseCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
printHandle: h
	<doNotGenerate>
	| o |
	o := self objectFor: h.
	^(o isKindOf: CompiledCode)
		ifTrue: [o printString]
		ifFalse: [o printString contractTo: 60]! !

!OilBaseCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
packedArgsAt: index count: n
	<doNotGenerate>
	^String streamContents:
		[:s|
		0 to: n - 1 do:
			[:j| | w |
			w := oilIRBuffer at: index + (j // 4).
			j > 0 ifTrue: [s space].
			s nextPutAll: (self reg: ((w bitShift: (3 - (j \\ 4)) * -8) bitAnd: 255))]]! !

!OilBaseCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
irString
	<doNotGenerate>
	^String streamContents: [:s| self printIROn: s]! !

!OilBaseCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
opcodeHistogram
	"Answer a Bag of the opcode names in the buffer (for tests)."
	<doNotGenerate>
	| bag i |
	bag := Bag new.
	i := 0.
	[i < irIndex] whileTrue:
		[bag add: (OilConstants opcodeNames at: (self opcodeAt: i)).
		 i := i + (self instructionLengthAt: i)].
	^bag! !


Object subclass: #OilSimulatedTypeFeedback
	instanceVariableNames: 'sites'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'VMMaker-JIT-OilDebugging'!

!OilSimulatedTypeFeedback commentStamp: 'cb 10/24/2026 10:40' prior: 0!
I play the role of ProfilingCogit's inline caches when OilCompiler runs in the image: I record, for each send site (CompiledCode, pc), the classes of the receivers seen while running a block under the image's bytecode simulator (Context>>runSimulated:contextAtEachStep:).  classAt:in: answers the class of a monomorphic site, nil otherwise, like monomorphicTargetFor:in: does for a linked inline cache.!

!OilSimulatedTypeFeedback methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:40'!
initialize
	sites := Dictionary new! !

!OilSimulatedTypeFeedback methodsFor: 'recording' stamp: 'cb 10/24/2026 10:40'!
record: aBlock
	"Run aBlock in the bytecode simulator, recording the receiver class of every send.  Answer aBlock's value."
	^thisContext
		runSimulated: aBlock
		contextAtEachStep:
			[:ctx| | sel |
			sel := ctx selectorToSendOrSelf.
			sel == ctx ifFalse:
				[| rcvr |
				 rcvr := ctx at: ctx stackPtr - sel numArgs.
				 (sites at: {ctx method. ctx pc} ifAbsentPut: [IdentitySet new]) add: rcvr class]]! !

!OilSimulatedTypeFeedback methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:40'!
classAt: pc in: aCompiledCode
	| classes |
	classes := sites at: {aCompiledCode. pc} ifAbsent: [^nil].
	^classes size = 1 ifTrue: [classes anyOne] ifFalse: [nil]! !

!OilSimulatedTypeFeedback methodsFor: 'accessing' stamp: 'cb 10/24/2026 14:00'!
hasSiteAt: pc in: aCompiledCode
	"Has the send at pc been executed at all (like a linked, monomorphic or polymorphic, inline cache)?"
	^sites includesKey: {aCompiledCode. pc}! !


Object subclass: #OilIRInterpreter
	instanceVariableNames: 'compiler regs flag steps'
	classVariableNames: ''
	poolDictionaries: 'OilConstants'
	category: 'VMMaker-JIT-OilDebugging'!

!OilIRInterpreter commentStamp: 'cb 10/24/2026 10:40' prior: 0!
I execute an OilCompiler's linear IR on host objects: run: receiver with: arguments answers the IR's result, or #deopt if a guard, a bounds check, a tag check or an overflow check fails (the VM would then bail out to the interpreter at the recorded deopt site).  Tagged SmallInteger opcodes are executed on untagged values with the SmallInteger checks they imply.!

!OilIRInterpreter methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:40'!
on: anOilCompiler
	compiler := anOilCompiler.
	regs := Array new: 256! !

!OilIRInterpreter methodsFor: 'running' stamp: 'cb 10/24/2026 10:40'!
run: receiver with: arguments
	| i |
	regs at: 1 put: receiver.
	arguments doWithIndex: [:arg :j| regs at: j + 1 put: arg].
	i := 0. steps := 0.
	[steps := steps + 1.
	 steps > 10000000 ifTrue: [^#runaway].
	 i := self step: i.
	 i isInteger] whileTrue.
	^i key == #result ifTrue: [i value] ifFalse: [i]! !

!OilIRInterpreter methodsFor: 'running' stamp: 'cb 10/24/2026 10:40'!
r: n
	^regs at: n + 1! !

!OilIRInterpreter methodsFor: 'running' stamp: 'cb 10/24/2026 10:40'!
r: n put: v
	^regs at: n + 1 put: v! !

!OilIRInterpreter methodsFor: 'running' stamp: 'cb 10/24/2026 10:40'!
smallInt: x
	^x class == SmallInteger! !

!OilIRInterpreter methodsFor: 'running' stamp: 'cb 10/24/2026 10:40'!
tagged: v
	"Result of a tagged op: deopt on overflow."
	^(self smallInt: v) ifTrue: [v] ifFalse: [nil]! !

!OilIRInterpreter methodsFor: 'running' stamp: 'cb 10/24/2026 10:40'!
step: i
	"Execute the instruction at i.  Answer the next index, or an Association #result -> value / #deopt -> site."
	| c op a b cc next x y v |
	c := compiler.
	op := c opcodeAt: i. a := c fieldAAt: i. b := c fieldBAt: i. cc := c fieldCAt: i.
	next := i + (c instructionLengthAt: i).
	op = OilConstTagged ifTrue:
		[self r: a put: (c signed16: (c imm16At: i)) - 1 // 8. ^next].
	op = OilConst64 ifTrue: [self r: a put: (c objectFor: (c word64At: i + 1)). ^next].
	op = OilMove ifTrue: [self r: a put: (self r: b). ^next].
	(op between: OilAddTagged and: OilXorTagged) ifTrue:
		[x := self r: b. y := self r: cc.
		 ((self smallInt: x) and: [self smallInt: y]) ifFalse: [^#deopt -> i].
		 v := self tagged: (op caseOf: {
				[OilAddTagged] -> [x + y]. [OilSubTagged] -> [x - y]. [OilAndTagged] -> [x bitAnd: y].
				[OilOrTagged] -> [x bitOr: y]. [OilXorTagged] -> [x bitXor: y] }).
		 v ifNil: [^#deopt -> i].
		 self r: a put: v. ^next].
	op = OilAddImmTagged ifTrue:
		[x := self r: b. (self smallInt: x) ifFalse: [^#deopt -> i].
		 v := self tagged: x + (c signed8: cc). v ifNil: [^#deopt -> i]. self r: a put: v. ^next].
	op = OilTrap ifTrue: [^#deopt -> i].
	op = OilStreamNext ifTrue: [self r: a put: (self r: b) next. ^next].
	op = OilStreamNextPut ifTrue: [self r: a put: ((self r: b) nextPut: (self r: cc)). ^next].
	op = OilCharValue ifTrue: [self r: a put: (self r: b) asInteger. ^next].
	op = OilLoadByteSize ifTrue: [self r: a put: (self r: b) basicSize. ^next].
	op = OilLoadByte ifTrue: [self r: a put: ((self r: b) basicAt: (self r: cc)). ^next].
	op = OilLoadChar ifTrue: [self r: a put: (Character value: ((self r: b) basicAt: (self r: cc))). ^next].
	(op = OilStoreByte or: [op = OilStoreChar]) ifTrue:
		[v := self r: a.
		 x := op = OilStoreChar
				ifTrue: [(v isCharacter and: [v asInteger <= 255]) ifTrue: [v asInteger] ifFalse: [nil]]
				ifFalse: [((self smallInt: v) and: [v between: 0 and: 255]) ifTrue: [v] ifFalse: [nil]].
		 (x isNil or: [(self r: b) isReadOnlyObject]) ifTrue: [^#deopt -> i].
		 (self r: b) basicAt: (self r: cc) put: x. ^next].
	op = OilCompareBytes ifTrue:
		[| s1 s2 |
		 s1 := self r: b. s2 := self r: cc.
		 (s2 class isBytes and: [s2 class isVariable]) ifFalse: [^#deopt -> i].
		 1 to: (s1 basicSize min: s2 basicSize) do:
			[:j| (s1 basicAt: j) = (s2 basicAt: j) ifFalse: [self r: a put: (s1 basicAt: j) - (s2 basicAt: j). ^next]].
		 self r: a put: s1 basicSize - s2 basicSize. ^next].
	op = OilModTagged ifTrue:
		[x := self r: b. y := self r: cc.
		 ((self smallInt: x) and: [(self smallInt: y) and: [y ~= 0]]) ifFalse: [^#deopt -> i].
		 self r: a put: x \\ y. ^next].
	op = OilAddImmTaggedNC ifTrue: "Pass 2 proved it cannot fail: if it would, Pass 2 is wrong"
		[x := self r: b.
		 v := x + (c signed8: cc).
		 ((self smallInt: x) and: [self smallInt: v]) ifFalse: [^#unsound -> i].
		 self r: a put: v. ^next].
	op = OilShiftTagged ifTrue:
		[| k | x := self r: b. (self smallInt: x) ifFalse: [^#deopt -> i].
		 k := c signed8: cc.
		 v := self tagged: (x bitShift: k negated). v ifNil: [^#deopt -> i]. self r: a put: v. ^next].
	op = OilOddTagged ifTrue:
		[x := self r: b. (self smallInt: x) ifFalse: [^#deopt -> i]. self r: a put: (x bitAnd: 1). ^next].
	op = OilLoadField ifTrue: [self r: a put: ((self r: b) instVarAt: cc + 1). ^next].
	op = OilStoreField ifTrue: [(self r: b) instVarAt: cc + 1 put: (self r: a). ^next].
	op = OilLoadSize ifTrue: [self r: a put: (self r: b) basicSize. ^next].
	op = OilCheckBounds ifTrue:
		[x := self r: a. y := self r: b.
		 ((self smallInt: x) and: [x between: 1 and: y]) ifFalse: [^#deopt -> i]. ^next].
	op = OilLoadElement ifTrue: [self r: a put: ((self r: b) basicAt: (self r: cc)). ^next].
	op = OilStoreElement ifTrue: [(self r: b) basicAt: (self r: cc) put: (self r: a). ^next].
	(op = OilCmpTagged or: [op = OilCmpImmTagged]) ifTrue:
		[x := self r: b. y := op = OilCmpImmTagged ifTrue: [c signed8: cc] ifFalse: [self r: cc].
		 a >= OilCondIdentical
			ifTrue: [flag := (x == y) = (a = OilCondIdentical)]
			ifFalse:
				[((self smallInt: x) and: [self smallInt: y]) ifFalse: [^#deopt -> i].
				 flag := c compareSmallInteger: x with: y cond: a].
		 ^next].
	(op = OilBranchTrue or: [op = OilBranchFalse]) ifTrue:
		[| cond |
		 cond := a = OilFlagsReg ifTrue: [flag] ifFalse: [self r: a].
		 (cond == true or: [cond == false]) ifFalse: [^#deopt -> i].
		 ^cond = (op = OilBranchTrue) ifTrue: [c imm16At: i] ifFalse: [next]].
	op = OilJump ifTrue: [^c imm16At: i].
	op = OilReturn ifTrue: [^#result -> (self r: a)].
	op = OilGuardClass ifTrue:
		[(self r: a) class == (c objectFor: (c word64At: i + 1)) ifFalse: [^#deopt -> i]. ^next].
	(op = OilCall0 or: [op = OilCall1 or: [op = OilCallN]]) ifTrue:
		[| sel args |
		 sel := c objectFor: (c word64At: i + 1).
		 args := (1 to: sel numArgs) collect: [:j| self r: b + j].
		 self r: a put: ((self r: b) perform: sel withArguments: args). ^next].
	op = OilNewArray ifTrue:
		[self r: a put: (b = OilFlagsReg
			ifTrue: [Array new: cc]
			ifFalse: [(0 to: cc - 1) collect: [:j| self r: b + j]]). ^next].
	op = OilMakeClosure ifTrue:
		[self r: a put: (FullBlockClosure
			receiver: (self r: (c fieldCAt: i + 3))
			outerContext: nil
			method: (c objectFor: (c word64At: i + 1))
			copiedValues: ((0 to: cc - 1) collect: [:j| self r: b + j]) asArray). ^next].
	^self error: 'unknown Oil opcode ', op printString! !


Object subclass: #OilTestItem
	instanceVariableNames: 'score'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'VMMaker-JIT-OilDebugging'!

!OilTestItem methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:40'!
score
	^score! !

!OilTestItem methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:40'!
score: anInteger
	score := anInteger! !

!OilTestItem methodsFor: 'probes' stamp: 'cb 10/24/2026 10:40'!
oilProbe0
	^score! !

!OilTestItem methodsFor: 'probes' stamp: 'cb 10/24/2026 10:40'!
oilProbe1: a
	^score + a! !

!OilTestItem methodsFor: 'probes' stamp: 'cb 10/24/2026 10:40'!
oilProbe2: a with: b
	^score + a + b! !

!OilTestItem methodsFor: 'probes' stamp: 'cb 10/24/2026 10:40'!
oilProbe3: a with: b with: c
	^score + a + b + c! !


Object subclass: #OilTestOther
	instanceVariableNames: 'score'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'VMMaker-JIT-OilDebugging'!

!OilTestOther methodsFor: 'probes' stamp: 'cb 10/24/2026 10:40'!
score
	^score ifNil: [100]! !

!OilTestOther methodsFor: 'probes' stamp: 'cb 10/24/2026 10:40'!
oilProbe0
	^1000! !

!OilTestOther methodsFor: 'probes' stamp: 'cb 10/24/2026 10:40'!
oilProbe1: a
	^1000 + a! !

!OilTestOther methodsFor: 'probes' stamp: 'cb 10/24/2026 10:40'!
oilProbe2: a with: b
	^1000 + a + b! !

!OilTestOther methodsFor: 'probes' stamp: 'cb 10/24/2026 10:40'!
oilProbe3: a with: b with: c
	^1000 + a + b + c! !


Object subclass: #OilTestModel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'VMMaker-JIT-OilDebugging'!

!OilTestModel methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
sumScores: anOrderedCollection
	| total |
	total := 0.
	anOrderedCollection do: [ :each |
		total := total + (each score)
	].
	^total! !

!OilTestModel methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
sumArray: anArray
	| total |
	total := 0.
	anArray do: [:each | total := total + each score].
	^total! !

!OilTestModel methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
sumIndexed: anArray
	"1-based indexing arithmetic: (i - 1) + 1 and + 0 must fold away."
	| total |
	total := 0.
	1 to: anArray size do: [:i | total := total + ((anArray at: (i - 1) + 1) score + 0)].
	^total! !

!OilTestModel methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
peepholes: i with: j
	"Braces of at most 8 elements compile to pushNewArray (larger ones use Array braceStream:)."
	^{ { (i - 1) + 1. (i + 1) - 1. i + 0. 0 + i. (i + 5) - 2. (i - 3) + 1. i - 0. (i - 1) + 1 + 0 }.
	   { i bitAnd: j. i bitOr: j. i bitXor: j. i bitAnd: -1. i bitOr: 0. 3 + 4 }.
	   { i // 4. i // 1. i \\ 2. i \\ 8. i * 31. i * 9. i * 8. i * 1 }.
	   { i bitShift: 3. i bitShift: -2 } }! !

!OilTestModel methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
callProbe: x with: a with: b
	"x is polymorphic (OilTestItem / OilTestOther): sends stay calls (0, 1, 2 and 3 arguments)."
	^x oilProbe0 + (x oilProbe1: a) + (x oilProbe2: a with: b) + (x oilProbe3: a with: b with: a)! !

!OilTestModel methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
detectProbe: anOrderedCollection
	"Nested iterators and blocks with a non-local return from an inlined block."
	^(anOrderedCollection detect: [:each | each score > 3] ifNone: [nil]) ifNil: [0] ifNotNil: [:found | found score]! !

!OilTestModel methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
countEven: anArray
	| count |
	count := 0.
	anArray do: [:each | each score \\ 2 = 0 ifTrue: [count := count + 1]].
	^count! !

!OilTestModel methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
hashProbe: aSet with: key
	"The second pillar: Set>>includes: -> scanFor: linear probe loop inlined."
	^aSet includes: key! !

!OilTestModel methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
sumInterval: n
	"Interval>>do: has two loops (step < 0 / >= 0): the block is inlined in both."
	| total |
	total := 0.
	(1 to: n) do: [:i | total := total + i].
	^total! !

!OilTestModel methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
injectScores: anArray
	"A two-argument block passed through inject:into: to do:."
	^anArray inject: 0 into: [:acc :each | acc + each score]! !

!OilTestModel methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
escapeProbe: n
	"The closure escapes: compiled in eager mode (materialized with OilMakeClosure)."
	^[:x | x + n]! !
