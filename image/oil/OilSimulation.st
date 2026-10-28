!OilInliningCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
printIROn: aStream
	"Dump the flattened linear IR buffer: frames, instructions (index, opcode, operands, deopt site), deopt sites, statistics."
	<doNotGenerate>
	| labels i |
	aStream nextPutAll: (oilIRBuffer == oilIRBuffer2 ifTrue: ['=== Oil Pass 2 IR: '] ifFalse: ['=== Oil Pass 1 IR: ']); print: oilHomeMethod; nextPutAll: ' for receiver class '; print: (self objectFor: receiverClass).
	aStream nextPutAll: (eagerClosures ifTrue: ['  [eager closures]'] ifFalse: ['  [virtual closures]']); cr.
	failed ifTrue:
		[aStream nextPutAll: 'FAILED: '; nextPutAll: (OilConstants failureNames at: failureCode + 1); cr].
	aStream nextPutAll: 'Inlined frames:'; cr.
	0 to: numFrames - 1 do:
		[:f|
		aStream tab; nextPut: $#; print: f; nextPutAll: ' depth '; print: (self frameAt: f) depth;
			nextPutAll: (String new: (self frameAt: f) depth * 2 withAll: $ ); space;
			print: (self frameAt: f) method; nextPutAll: '  base r'; print: (self frameAt: f) base.
		(self frameAt: f) parent >= 0 ifTrue:
			[aStream nextPutAll: '  (from #'; print: (self frameAt: f) parent; nextPutAll: ' pc '; print: (self frameAt: f) callPC; nextPut: $)].
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
			nextPutAll: ' -> frame #'; print: (siteFrame at: s); nextPutAll: ' '; print: (self frameAt: (siteFrame at: s)) method;
			nextPutAll: ' pc '; print: (sitePC at: s); cr].
	aStream nextPutAll: 'Stats: virtual objects '; print: numVObjs;
		nextPutAll: ', high registers '; print: OilMaxReg - highRegTop; cr! !

!OilInliningCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/26/2026 09:30'!
printInstructionAt: instIndex on: aStream
	<doNotGenerate>
	| opcode regA regB regC name siteIndex |
	opcode := self opcodeAt: instIndex. regA := self fieldAAt: instIndex. regB := self fieldBAt: instIndex. regC := self fieldCAt: instIndex.
	name := (opcode between: 1 and: OilLastOpcode) ifTrue: [OilConstants opcodeNames at: opcode] ifFalse: ['?', opcode printString].
	aStream nextPutAll: '  '; nextPutAll: (instIndex printPaddedWith: $0 to: 4); nextPutAll: '  ';
		nextPutAll: ((self hexWord: (oilIRBuffer at: instIndex))); nextPutAll: '  ';
		nextPutAll: (name , (String new: (14 - name size max: 1) withAll: $ )).
	opcode caseOf: {
		[OilConstTagged]	-> [| immVal | immVal := self signed16: (self imm16At: instIndex).
							 aStream nextPutAll: (self reg: regA), ' := ', ((immVal - 1) // 8) printString, '   (tagged ', immVal printString, ')'].
		[OilConst64]		-> [aStream nextPutAll: (self reg: regA), ' := ', (self printHandle: (self word64At: instIndex + 1))].
		[OilMove]			-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB)].
		[OilAddTagged]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' + ', (self reg: regC)].
		[OilSubTagged]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' - ', (self reg: regC)].
		[OilAndTagged]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' bitAnd: ', (self reg: regC), '   (andq, no untagging)'].
		[OilOrTagged]		-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' bitOr: ', (self reg: regC), '   (orq, no untagging)'].
		[OilXorTagged]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' bitXor: ', (self reg: regC), '   (xorq; orq $1)'].
		[OilShiftTagged]	-> [| shiftVal | shiftVal := self signed8: regC.
							 aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB),
								(shiftVal > 0 ifTrue: [' >> ', shiftVal printString, '   (// ', (1 bitShift: shiftVal) printString, ': sarq $', (3 + shiftVal) printString, '; shlq $3; orq $1)']
									ifFalse: [' << ', shiftVal negated printString, '   (* ', (1 bitShift: shiftVal negated) printString, ')'])].
		[OilOddTagged]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' \\ 2   ((x bitAnd: 8) bitOr: 1)'].
		[OilLoadField]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), '.slot[', regC printString, ']'].
		[OilStoreField]	-> [aStream nextPutAll: (self reg: regB), '.slot[', regC printString, '] := ', (self reg: regA), '   (store check)'].
		[OilLoadElement]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), '[', (self reg: regC), ']   (movq -1(arr,idx))'].
		[OilStoreElement]	-> [aStream nextPutAll: (self reg: regB), '[', (self reg: regC), '] := ', (self reg: regA), '   (store check)'].
		[OilCmpTagged]	-> [aStream nextPutAll: (self reg: regB), ' ', (self condName: regA), ' ', (self reg: regC)].
		[OilCmpImmTagged]	-> [aStream nextPutAll: (self reg: regB), ' ', (self condName: regA), ' ', (self signed8: regC) printString].
		[OilBranchTrue]	-> [aStream nextPutAll: (regA = OilFlagsReg ifTrue: ['flags'] ifFalse: [self reg: regA]), ' -> L', ((self imm16At: instIndex) printPaddedWith: $0 to: 4)].
		[OilBranchFalse]	-> [aStream nextPutAll: (regA = OilFlagsReg ifTrue: ['flags'] ifFalse: [self reg: regA]), ' -> L', ((self imm16At: instIndex) printPaddedWith: $0 to: 4)].
		[OilJump]			-> [aStream nextPutAll: '-> L', ((self imm16At: instIndex) printPaddedWith: $0 to: 4)].
		[OilReturn]		-> [aStream nextPutAll: (self reg: regA)].
		[OilGuardClass]	-> [aStream nextPutAll: 'class(', (self reg: regA), ') == ', (self printHandle: (self word64At: instIndex + 1))].
		[OilCheckBounds]	-> [aStream nextPutAll: '1 <= ', (self reg: regA), ' <= ', (self reg: regB)].
		[OilCall0]			-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' ', (self printHandle: (self word64At: instIndex + 1))].
		[OilCall1]			-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' ', (self printHandle: (self word64At: instIndex + 1)), ' ', (self reg: regC)].
		[OilCallN]			-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' ', (self printHandle: (self word64At: instIndex + 1)), ' (', (self packedArgsAt: instIndex + 3 count: regC), ')'].
		[OilCallSuper]		-> [aStream nextPutAll: (self reg: regA), ' := super ', (self printHandle: (self word64At: instIndex + 1)), ' rcvr ', (self reg: regB), ' (', (self packedArgsAt: instIndex + 3 count: regC), ')'].
		[OilCallDirectedSuper]	-> [aStream nextPutAll: (self reg: regA), ' := super ', (self printHandle: (self word64At: instIndex + 1)), ' above ', (self printHandle: (self word64At: instIndex + 3)), ' rcvr ', (self reg: regB), ' (', (self packedArgsAt: instIndex + 5 count: regC), ')'].
		[OilAddImmTagged]	-> [| immVal | immVal := self signed8: regC. aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), (immVal >= 0 ifTrue: [' + '] ifFalse: [' - ']), immVal abs printString, '   (addq $', (immVal * 8) printString, ')'].
		[OilTrap]			-> [aStream nextPutAll: 'uncommon trap'].
		[OilStreamNext]		-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' next   (inlined, else sent)'].
		[OilStreamNextPut]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' nextPut: ', (self reg: regC), '   (inlined, else sent)'].
		[OilCharValue]		-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' asInteger'].
		[OilIdentityHash]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' identityHash   (from the header, else sent)'].
		[OilIndexOfByte]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' ', (self printHandle: (self word64At: instIndex + 1)), ' (', (self packedArgsAt: instIndex + 3 count: regC), ')   (8 bytes at a time, else sent)'].
		[OilSkipSeparators]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' skipSeparators   (8 bytes at a time, else sent)'].
		[OilLoadByteSize]	-> [aStream nextPutAll: (self reg: regA), ' := byteSize(', (self reg: regB), ')'].
		[OilLoadByte]		-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), '[', (self reg: regC), '] (byte)'].
		[OilLoadChar]		-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), '[', (self reg: regC), '] (Character)'].
		[OilStoreByte]		-> [aStream nextPutAll: (self reg: regB), '[', (self reg: regC), '] := ', (self reg: regA), ' (byte)'].
		[OilStoreChar]		-> [aStream nextPutAll: (self reg: regB), '[', (self reg: regC), '] := ', (self reg: regA), ' (Character)'].
		[OilCompareBytes]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' compareWith: ', (self reg: regC)].
		[OilModTagged]		-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' \\ ', (self reg: regC), '   (idiv; floored)'].
		[OilAddImmTaggedNC]	-> [| immVal | immVal := self signed8: regC. aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), (immVal >= 0 ifTrue: [' + '] ifFalse: [' - ']), immVal abs printString, '   (addq $', (immVal * 8) printString, ', no overflow check)'].
		[OilLoadSize]		-> [aStream nextPutAll: (self reg: regA), ' := size(', (self reg: regB), ')'].
		[OilMakeClosure]	-> [aStream nextPutAll: (self reg: regA), ' := closure ', (self printHandle: (self word64At: instIndex + 1)), ' self ', (self reg: (self fieldCAt: instIndex + 3)), ' copied ', regC printString, ' from ', (self reg: regB)].
		[OilNewArray]		-> [aStream nextPutAll: (self reg: regA), ' := Array new: ', regC printString, (regB = OilFlagsReg ifTrue: ['   (nil filled)'] ifFalse: ['   from ', (self reg: regB), '..', (self reg: regB + regC - 1)])].
		[OilAddFloat]		-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' + ', (self reg: regC), '   (Float)'].
		[OilSubFloat]		-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' - ', (self reg: regC), '   (Float)'].
		[OilMulFloat]		-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' * ', (self reg: regC), '   (Float)'].
		[OilDivFloat]		-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' / ', (self reg: regC), '   (Float)'].
		[OilCmpFloat]		-> [aStream nextPutAll: (self reg: regB), ' ', (self condName: regA), ' ', (self reg: regC), '   (Float)'].
		[OilSqrtFloat]		-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' sqrt   (Float)'].
		[OilAbsFloat]		-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' abs   (Float)'].
		[OilNegatedFloat]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' negated   (Float)'].
		[OilNewObject]		-> [aStream nextPutAll: (self reg: regA), ' := ', (self printHandle: (self word64At: instIndex + 1)), ' new from ', (self reg: regB), '..', (self reg: regB + regC - 1), '   (materialized, not nil filled)'].
		[OilCmpClass]		-> [aStream nextPutAll: 'class(', (self reg: regB), ') ', (self condName: regA), ' ', (self printHandle: (self word64At: instIndex + 1))].
		[OilGuardClass2]	-> [aStream nextPutAll: 'class(', (self reg: regA), ') == ', (self printHandle: (self word64At: instIndex + 1)), ' or ', (self printHandle: (self word64At: instIndex + 3))].
		[OilStringHash]		-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' hashWithInitialHash: ', (self reg: regC), '   (inlined, else sent)'].
		[OilFindSubstring]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' ', (self printHandle: (self word64At: instIndex + 1)), ' (', (self packedArgsAt: instIndex + 3 count: regC), ')   (inlined, else sent)'].
		[OilFindFirstInString]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' ', (self printHandle: (self word64At: instIndex + 1)), ' (', (self packedArgsAt: instIndex + 3 count: regC), ')   (inlined, else sent)'] }
		otherwise: [].
	siteIndex := (0 to: numSites - 1) detect: [:s| (siteIR at: s) = instIndex] ifNone: [nil].
	siteIndex ifNotNil:
		[aStream nextPutAll: '   ; deopt#'; print: siteIndex; nextPutAll: ' #'; print: (siteFrame at: siteIndex); nextPutAll: ' pc '; print: (sitePC at: siteIndex)].
	(oilIRBuffer == oilIRBuffer2 and: [((oilIRFlag at: instIndex) bitAnd: OilFloatChained) ~= 0]) ifTrue:
		[aStream nextPutAll: '   ; chain deopt#'; print: (oilIRAux at: instIndex).
		 ((oilIRFlag at: instIndex) bitAnd: OilFloatUnboxed) ~= 0 ifTrue: [aStream nextPutAll: ' unboxed']].
	aStream cr! !

!OilInliningCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
hexWord: word
	<doNotGenerate>
	| hexString |
	hexString := (word printStringBase: 16) asUppercase.
	^(String new: (8 - hexString size max: 0) withAll: $0), hexString! !

!OilInliningCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
reg: registerIndex
	<doNotGenerate>
	^'r', registerIndex printString! !

!OilInliningCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
condName: condCode
	<doNotGenerate>
	^#('<' '>' '<=' '>=' '=' '~=' '==' '~~') at: condCode! !

!OilInliningCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
printHandle: handleVal
	<doNotGenerate>
	| obj |
	obj := self objectFor: handleVal.
	^(obj isKindOf: CompiledCode)
		ifTrue: [obj printString]
		ifFalse: [obj printString contractTo: 60]! !

!OilInliningCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
packedArgsAt: index count: count
	<doNotGenerate>
	^String streamContents:
		[:stream|
		0 to: count - 1 do:
			[:argIndex| | word |
			word := oilIRBuffer at: index + (argIndex // 4).
			argIndex > 0 ifTrue: [stream space].
			stream nextPutAll: (self reg: ((word bitShift: (3 - (argIndex \\ 4)) * -8) bitAnd: 255))]]! !

!OilInliningCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/25/2026 02:30'!
irFlagAt: index
	<doNotGenerate>
	^oilIRFlag at: index! !

!OilInliningCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/25/2026 02:30'!
irAuxAt: index
	<doNotGenerate>
	^oilIRAux at: index! !

!OilInliningCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
irString
	<doNotGenerate>
	^String streamContents: [:s| self printIROn: s]! !

!OilInliningCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
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

!OilSimulatedTypeFeedback methodsFor: 'accessing' stamp: 'cb 10/25/2026 09:30'!
class: index of: numClasses at: pc in: aCompiledCode
	"The index-th (1-based, by name) of the receiver classes of a site that saw exactly numClasses classes (a closed PIC), else nil."
	| classes |
	classes := sites at: {aCompiledCode. pc} ifAbsent: [^nil].
	classes size = numClasses ifFalse: [^nil].
	^(classes asArray sort: [:a :b | a name <= b name]) at: index! !

!OilSimulatedTypeFeedback methodsFor: 'accessing' stamp: 'cb 10/24/2026 14:00'!
hasSiteAt: pc in: aCompiledCode
	"Has the send at pc been executed at all (like a linked, monomorphic or polymorphic, inline cache)?"
	^sites includesKey: {aCompiledCode. pc}! !


Object subclass: #OilIRInterpreter
	instanceVariableNames: 'compiler regs flag steps xmms xmmChain'
	classVariableNames: ''
	poolDictionaries: 'OilInstructionConstants OilConstants'
	category: 'VMMaker-JIT-OilDebugging'!

!OilIRInterpreter commentStamp: 'cb 10/24/2026 10:40' prior: 0!
I execute an OilCompiler's linear IR on host objects: run: receiver with: arguments answers the IR's result, or #deopt if a guard, a bounds check, a tag check or an overflow check fails (the VM would then deoptimize to the interpreter at the recorded deopt site).  Tagged SmallInteger opcodes are executed on untagged values with the SmallInteger checks they imply.  The unboxed results of float chains (OilFullCompiler>>fuseFloats) are kept aside (xmms), as in XMM registers, and only read by the float instructions of their chain: if anything else read them, it would read a stale register.!

!OilIRInterpreter methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:40'!
on: anOilCompiler
	compiler := anOilCompiler.
	xmms := Dictionary new.
	xmmChain := -1.
	regs := Array new: 256! !

!OilIRInterpreter methodsFor: 'running' stamp: 'cb 10/24/2026 10:40'!
run: receiver with: arguments
	| currentInst |
	regs at: 1 put: receiver.
	arguments doWithIndex: [:arg :argIndex| regs at: argIndex + 1 put: arg].
	currentInst := 0. steps := 0.
	[steps := steps + 1.
	 steps > 10000000 ifTrue: [^#runaway].
	 currentInst := self step: currentInst.
	 currentInst isInteger] whileTrue.
	^currentInst key == #result ifTrue: [currentInst value] ifFalse: [currentInst]! !

!OilIRInterpreter methodsFor: 'running' stamp: 'cb 10/24/2026 10:40'!
r: regIndex
	^regs at: regIndex + 1! !

!OilIRInterpreter methodsFor: 'running' stamp: 'cb 10/24/2026 10:40'!
r: regIndex put: aValue
	xmms removeKey: regIndex ifAbsent: [].
	^regs at: regIndex + 1 put: aValue! !

!OilIRInterpreter methodsFor: 'running' stamp: 'cb 10/24/2026 10:40'!
smallInt: anObject
	^anObject class == SmallInteger! !

!OilIRInterpreter methodsFor: 'running' stamp: 'cb 10/24/2026 10:40'!
tagged: aValue
	"Result of a tagged op: deopt on overflow."
	^(self smallInt: aValue) ifTrue: [aValue] ifFalse: [nil]! !

!OilIRInterpreter methodsFor: 'running' stamp: 'cb 10/26/2026 09:30'!
step: instIndex
	"Execute the instruction at instIndex.  Answer the next index, or an Association #result -> value / #deopt -> site."
	| comp opcode destReg srcReg1 srcReg2 nextIndex val1 val2 resVal chainSite |
	comp := compiler.
	opcode := comp opcodeAt: instIndex. destReg := comp fieldAAt: instIndex. srcReg1 := comp fieldBAt: instIndex. srcReg2 := comp fieldCAt: instIndex.
	nextIndex := instIndex + (comp instructionLengthAt: instIndex).
	chainSite := ((comp irFlagAt: instIndex) bitAnd: OilFloatChained) ~= 0 ifTrue: [comp irAuxAt: instIndex] ifFalse: [-1].
	chainSite ~= xmmChain ifTrue: [xmms removeAll. xmmChain := chainSite].
	opcode = OilConstTagged ifTrue:
		[self r: destReg put: (comp signed16: (comp imm16At: instIndex)) - 1 // 8. ^nextIndex].
	opcode = OilConst64 ifTrue: [self r: destReg put: (comp objectFor: (comp word64At: instIndex + 1)). ^nextIndex].
	opcode = OilMove ifTrue: [self r: destReg put: (self r: srcReg1). ^nextIndex].
	(opcode between: OilAddTagged and: OilXorTagged) ifTrue:
		[val1 := self r: srcReg1. val2 := self r: srcReg2.
		 ((self smallInt: val1) and: [self smallInt: val2]) ifFalse: [^#deopt -> instIndex].
		 resVal := self tagged: (opcode caseOf: {
				[OilAddTagged] -> [val1 + val2]. [OilSubTagged] -> [val1 - val2]. [OilAndTagged] -> [val1 bitAnd: val2].
				[OilOrTagged] -> [val1 bitOr: val2]. [OilXorTagged] -> [val1 bitXor: val2] }).
		 resVal ifNil: [^#deopt -> instIndex].
		 self r: destReg put: resVal. ^nextIndex].
	opcode = OilAddImmTagged ifTrue:
		[val1 := self r: srcReg1. (self smallInt: val1) ifFalse: [^#deopt -> instIndex].
		 resVal := self tagged: val1 + (comp signed8: srcReg2). resVal ifNil: [^#deopt -> instIndex]. self r: destReg put: resVal. ^nextIndex].
	opcode = OilTrap ifTrue: [^#deopt -> instIndex].
	(opcode between: OilAddFloat and: OilCmpFloat) ifTrue: "a Float receiver, a Float or SmallInteger argument, no zero divisor"
		[val1 := xmms at: srcReg1 ifAbsent: [self r: srcReg1]. val2 := xmms at: srcReg2 ifAbsent: [self r: srcReg2].
		 (val1 isFloat and: [val2 isFloat or: [self smallInt: val2]]) ifFalse: [^#deopt -> instIndex].
		 opcode = OilCmpFloat ifTrue:
			[flag := #(< > <= >= = ~=) at: destReg.
			 flag := val1 perform: flag with: val2.
			 ^nextIndex].
		 (opcode = OilDivFloat and: [val2 isZero]) ifTrue: [^#deopt -> instIndex].
		 resVal := val1 perform: (#(+ - * /) at: opcode - OilAddFloat + 1) with: val2.
		 ((comp irFlagAt: instIndex) bitAnd: OilFloatUnboxed) ~= 0
			ifTrue: [xmms at: destReg put: resVal]
			ifFalse: [self r: destReg put: resVal].
		 ^nextIndex].
	(opcode between: OilSqrtFloat and: OilNegatedFloat) ifTrue:
		[val1 := xmms at: srcReg1 ifAbsent: [self r: srcReg1].
		 val1 isFloat ifFalse: [^#deopt -> instIndex].
		 (opcode = OilSqrtFloat and: [(val1 >= 0.0) not]) ifTrue: [^#deopt -> instIndex].
		 resVal := val1 perform: (#(sqrt abs negated) at: opcode - OilSqrtFloat + 1).
		 ((comp irFlagAt: instIndex) bitAnd: OilFloatUnboxed) ~= 0
			ifTrue: [xmms at: destReg put: resVal]
			ifFalse: [self r: destReg put: resVal].
		 ^nextIndex].
	opcode = OilStreamNext ifTrue: [self r: destReg put: (self r: srcReg1) next. ^nextIndex].
	opcode = OilStreamNextPut ifTrue: [self r: destReg put: ((self r: srcReg1) nextPut: (self r: srcReg2)). ^nextIndex].
	opcode = OilCharValue ifTrue: [self r: destReg put: (self r: srcReg1) asInteger. ^nextIndex].
	opcode = OilLoadByteSize ifTrue: [self r: destReg put: (self r: srcReg1) basicSize. ^nextIndex].
	opcode = OilLoadByte ifTrue: [self r: destReg put: ((self r: srcReg1) basicAt: (self r: srcReg2)). ^nextIndex].
	opcode = OilLoadChar ifTrue: [self r: destReg put: (Character value: ((self r: srcReg1) basicAt: (self r: srcReg2))). ^nextIndex].
	(opcode = OilStoreByte or: [opcode = OilStoreChar]) ifTrue:
		[resVal := self r: destReg.
		 val1 := opcode = OilStoreChar
				ifTrue: [(resVal isCharacter and: [resVal asInteger <= 255]) ifTrue: [resVal asInteger] ifFalse: [nil]]
				ifFalse: [((self smallInt: resVal) and: [resVal between: 0 and: 255]) ifTrue: [resVal] ifFalse: [nil]].
		 (val1 isNil or: [(self r: srcReg1) isReadOnlyObject]) ifTrue: [^#deopt -> instIndex].
		 (self r: srcReg1) basicAt: (self r: srcReg2) put: val1. ^nextIndex].
	opcode = OilCompareBytes ifTrue:
		[| s1 s2 |
		 s1 := self r: srcReg1. s2 := self r: srcReg2.
		 (s2 class isBytes and: [s2 class isVariable]) ifFalse: [^#deopt -> instIndex].
		 1 to: (s1 basicSize min: s2 basicSize) do:
			[:byteIndex| (s1 basicAt: byteIndex) = (s2 basicAt: byteIndex) ifFalse: [self r: destReg put: (s1 basicAt: byteIndex) - (s2 basicAt: byteIndex). ^nextIndex]].
		 self r: destReg put: s1 basicSize - s2 basicSize. ^nextIndex].
	opcode = OilModTagged ifTrue:
		[val1 := self r: srcReg1. val2 := self r: srcReg2.
		 ((self smallInt: val1) and: [(self smallInt: val2) and: [val2 ~= 0]]) ifFalse: [^#deopt -> instIndex].
		 self r: destReg put: val1 \\ val2. ^nextIndex].
	opcode = OilAddImmTaggedNC ifTrue: "Pass 2 proved it cannot fail: if it would, Pass 2 is wrong"
		[val1 := self r: srcReg1.
		 resVal := val1 + (comp signed8: srcReg2).
		 ((self smallInt: val1) and: [self smallInt: resVal]) ifFalse: [^#unsound -> instIndex].
		 self r: destReg put: resVal. ^nextIndex].
	opcode = OilShiftTagged ifTrue:
		[| shiftAmount | val1 := self r: srcReg1. (self smallInt: val1) ifFalse: [^#deopt -> instIndex].
		 shiftAmount := comp signed8: srcReg2.
		 resVal := self tagged: (val1 bitShift: shiftAmount negated). resVal ifNil: [^#deopt -> instIndex]. self r: destReg put: resVal. ^nextIndex].
	opcode = OilOddTagged ifTrue:
		[val1 := self r: srcReg1. (self smallInt: val1) ifFalse: [^#deopt -> instIndex]. self r: destReg put: (val1 bitAnd: 1). ^nextIndex].
	opcode = OilLoadField ifTrue: [self r: destReg put: ((self r: srcReg1) instVarAt: srcReg2 + 1). ^nextIndex].
	opcode = OilStoreField ifTrue: [(self r: srcReg1) instVarAt: srcReg2 + 1 put: (self r: destReg). ^nextIndex].
	opcode = OilLoadSize ifTrue: [self r: destReg put: (self r: srcReg1) basicSize. ^nextIndex].
	opcode = OilCheckBounds ifTrue:
		[val1 := self r: destReg. val2 := self r: srcReg1.
		 ((self smallInt: val1) and: [val1 between: 1 and: val2]) ifFalse: [^#deopt -> instIndex]. ^nextIndex].
	opcode = OilLoadElement ifTrue: [self r: destReg put: ((self r: srcReg1) basicAt: (self r: srcReg2)). ^nextIndex].
	opcode = OilStoreElement ifTrue: [(self r: srcReg1) basicAt: (self r: srcReg2) put: (self r: destReg). ^nextIndex].
	(opcode = OilCmpTagged or: [opcode = OilCmpImmTagged]) ifTrue:
		[val1 := self r: srcReg1. val2 := opcode = OilCmpImmTagged ifTrue: [comp signed8: srcReg2] ifFalse: [self r: srcReg2].
		 destReg >= OilCondIdentical
			ifTrue: [flag := (val1 == val2) = (destReg = OilCondIdentical)]
			ifFalse:
				[((self smallInt: val1) and: [self smallInt: val2]) ifFalse: [^#deopt -> instIndex].
				 flag := comp compareSmallInteger: val1 with: val2 cond: destReg].
		 ^nextIndex].
	(opcode = OilBranchTrue or: [opcode = OilBranchFalse]) ifTrue:
		[| branchCondition |
		 branchCondition := destReg = OilFlagsReg ifTrue: [flag] ifFalse: [self r: destReg].
		 (branchCondition == true or: [branchCondition == false]) ifFalse: [^#deopt -> instIndex].
		 ^branchCondition = (opcode = OilBranchTrue) ifTrue: [comp imm16At: instIndex] ifFalse: [nextIndex]].
	opcode = OilJump ifTrue: [^comp imm16At: instIndex].
	opcode = OilReturn ifTrue: [^#result -> (self r: destReg)].
	opcode = OilGuardClass ifTrue:
		[(self r: destReg) class == (comp objectFor: (comp word64At: instIndex + 1)) ifFalse: [^#deopt -> instIndex]. ^nextIndex].
	opcode = OilGuardClass2 ifTrue:
		[((self r: destReg) class == (comp objectFor: (comp word64At: instIndex + 1))
		  or: [(self r: destReg) class == (comp objectFor: (comp word64At: instIndex + 3))]) ifFalse: [^#deopt -> instIndex]. ^nextIndex].
	opcode = OilCmpClass ifTrue:
		[flag := ((self r: srcReg1) class == (comp objectFor: (comp word64At: instIndex + 1))) = (destReg = OilCondIdentical). ^nextIndex].
	opcode = OilNewObject ifTrue:
		[| obj | obj := (comp objectFor: (comp word64At: instIndex + 1)) basicNew.
		 0 to: srcReg2 - 1 do: [:slotIndex| obj instVarAt: slotIndex + 1 put: (self r: srcReg1 + slotIndex)].
		 self r: destReg put: obj. ^nextIndex].
	opcode = OilStringHash ifTrue:
		[val1 := self r: srcReg1. val2 := self r: srcReg2.
		 ((comp word64At: instIndex + 1) <= 1
		  and: [(val1 class isBytes and: [val1 class isVariable]) not or: [(self smallInt: val2) not]]) ifTrue:
			[^#deopt -> instIndex].
		 self r: destReg put: (ByteArray hashBytes: val1 startingWith: val2). ^nextIndex].
	(opcode = OilCall0 or: [opcode = OilCall1 or: [opcode = OilCallN or: [(opcode between: OilIdentityHash and: OilSkipSeparators) or: [opcode = OilFindSubstring or: [opcode = OilFindFirstInString]]]]]) ifTrue:
		[| selector args |
		 selector := comp objectFor: (comp word64At: instIndex + 1).
		 args := (1 to: selector numArgs) collect: [:argIndex| self r: srcReg1 + argIndex].
		 self r: destReg put: ((self r: srcReg1) perform: selector withArguments: args). ^nextIndex].
	opcode = OilCallDirectedSuper ifTrue: "the lookup starts in the superclass of the method class"
		[| selector args |
		 selector := comp objectFor: (comp word64At: instIndex + 1).
		 args := (1 to: selector numArgs) collect: [:argIndex| self r: srcReg1 + argIndex].
		 self r: destReg put: ((self r: srcReg1)
									perform: selector
									withArguments: args
									inSuperclass: (comp objectFor: (comp word64At: instIndex + 3)) superclass). ^nextIndex].
	opcode = OilNewArray ifTrue:
		[self r: destReg put: (srcReg1 = OilFlagsReg
			ifTrue: [Array new: srcReg2]
			ifFalse: [(0 to: srcReg2 - 1) collect: [:elemIndex| self r: srcReg1 + elemIndex]]). ^nextIndex].
	opcode = OilMakeClosure ifTrue:
		[self r: destReg put: (FullBlockClosure
			receiver: (self r: (comp fieldCAt: instIndex + 3))
			outerContext: nil
			method: (comp objectFor: (comp word64At: instIndex + 1))
			copiedValues: ((0 to: srcReg2 - 1) collect: [:elemIndex| self r: srcReg1 + elemIndex]) asArray). ^nextIndex].
	^self error: 'unknown Oil opcode ', opcode printString! !


Object subclass: #OilCoreSimulationItem
	instanceVariableNames: 'score'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'VMMaker-JIT-OilTest'!

!OilCoreSimulationItem methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:40'!
score
	^score! !

!OilCoreSimulationItem methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:40'!
score: anInteger
	score := anInteger! !

!OilCoreSimulationItem methodsFor: 'probes' stamp: 'cb 10/24/2026 10:40'!
oilProbe0
	^score! !

!OilCoreSimulationItem methodsFor: 'probes' stamp: 'cb 10/24/2026 10:40'!
oilProbe1: a
	^score + a! !

!OilCoreSimulationItem methodsFor: 'probes' stamp: 'cb 10/24/2026 10:40'!
oilProbe2: a with: b
	^score + a + b! !

!OilCoreSimulationItem methodsFor: 'probes' stamp: 'cb 10/24/2026 10:40'!
oilProbe3: a with: b with: c
	^score + a + b + c! !


Object subclass: #OilCoreSimulationOther
	instanceVariableNames: 'score'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'VMMaker-JIT-OilTest'!

!OilCoreSimulationOther methodsFor: 'probes' stamp: 'cb 10/24/2026 10:40'!
score
	^score ifNil: [100]! !

!OilCoreSimulationOther methodsFor: 'probes' stamp: 'cb 10/24/2026 10:40'!
oilProbe0
	^1000! !

!OilCoreSimulationOther methodsFor: 'probes' stamp: 'cb 10/24/2026 10:40'!
oilProbe1: a
	^1000 + a! !

!OilCoreSimulationOther methodsFor: 'probes' stamp: 'cb 10/24/2026 10:40'!
oilProbe2: a with: b
	^1000 + a + b! !

!OilCoreSimulationOther methodsFor: 'probes' stamp: 'cb 10/24/2026 10:40'!
oilProbe3: a with: b with: c
	^1000 + a + b + c! !


Object subclass: #OilCoreSimulationModelTest
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'VMMaker-JIT-OilTest'!

!OilCoreSimulationModelTest methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
sumScores: anOrderedCollection
	| total |
	total := 0.
	anOrderedCollection do: [ :each |
		total := total + (each score)
	].
	^total! !

!OilCoreSimulationModelTest methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
sumArray: anArray
	| total |
	total := 0.
	anArray do: [:each | total := total + each score].
	^total! !

!OilCoreSimulationModelTest methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
sumIndexed: anArray
	"1-based indexing arithmetic: (i - 1) + 1 and + 0 must fold away."
	| total |
	total := 0.
	1 to: anArray size do: [:i | total := total + ((anArray at: (i - 1) + 1) score + 0)].
	^total! !

!OilCoreSimulationModelTest methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
peepholes: i with: j
	"Braces of at most 8 elements compile to pushNewArray (larger ones use Array braceStream:)."
	^{ { (i - 1) + 1. (i + 1) - 1. i + 0. 0 + i. (i + 5) - 2. (i - 3) + 1. i - 0. (i - 1) + 1 + 0 }.
	   { i bitAnd: j. i bitOr: j. i bitXor: j. i bitAnd: -1. i bitOr: 0. 3 + 4 }.
	   { i // 4. i // 1. i \\ 2. i \\ 8. i * 31. i * 9. i * 8. i * 1 }.
	   { i bitShift: 3. i bitShift: -2 } }! !

!OilCoreSimulationModelTest methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
callProbe: x with: a with: b
	"x is polymorphic (OilCoreSimulationItem / OilCoreSimulationOther): sends stay calls (0, 1, 2 and 3 arguments)."
	^x oilProbe0 + (x oilProbe1: a) + (x oilProbe2: a with: b) + (x oilProbe3: a with: b with: a)! !

!OilCoreSimulationModelTest methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
detectProbe: anOrderedCollection
	"Nested iterators and blocks with a non-local return from an inlined block."
	^(anOrderedCollection detect: [:each | each score > 3] ifNone: [nil]) ifNil: [0] ifNotNil: [:found | found score]! !

!OilCoreSimulationModelTest methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
countEven: anArray
	| count |
	count := 0.
	anArray do: [:each | each score \\ 2 = 0 ifTrue: [count := count + 1]].
	^count! !

!OilCoreSimulationModelTest methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
hashProbe: aSet with: key
	"The second pillar: Set>>includes: -> scanFor: linear probe loop inlined."
	^aSet includes: key! !

!OilCoreSimulationModelTest methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
sumInterval: n
	"Interval>>do: has two loops (step < 0 / >= 0): the block is inlined in both."
	| total |
	total := 0.
	(1 to: n) do: [:i | total := total + i].
	^total! !

!OilCoreSimulationModelTest methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
injectScores: anArray
	"A two-argument block passed through inject:into: to do:."
	^anArray inject: 0 into: [:acc :each | acc + each score]! !

!OilCoreSimulationModelTest methodsFor: 'benchmarks' stamp: 'cb 10/24/2026 10:40'!
escapeProbe: n
	"The closure escapes: compiled in eager mode (materialized with OilMakeClosure)."
	^[:x | x + n]! !

OilFullCompiler subclass: #OilConvolutedCompiler
	instanceVariableNames: 'oilXmmPinned oilFloatLoopHead oilFloatLoopEnd oilFloatLoopSite oilFloatLoopNum oilFloatLoopVReg oilFloatLoopKind oilNumFloatLoops oilFloatLoopCurrent oilSiteFloatLoop oilFloatExitJump oilFloatExitTarget oilNumFloatExits'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'VMMaker-JIT-OilDebugging'!

!OilConvolutedCompiler commentStamp: 'cb 10/28/2026 03:20' prior: 0!
I hold the extracted float-loop register unboxing analysis and CFG worklist liveness helpers (formerly on OilInliningCompiler), kept in the VMMaker-JIT-OilDebugging package (with the simulation classes) out of the core VMMaker-JIT-Oil pipeline.  I am not translated to C (gen_simplify.sh does not file in OilSimulation.st); float loop tests exercise me in simulation.!

!OilConvolutedCompiler class methodsFor: 'translation' stamp: 'cb 10/27/2026 12:00'!
declareCVarsIn: aCCodeGenerator
	self == OilConvolutedCompiler ifFalse: [^self].
	aCCodeGenerator var: #oilXmmPinned declareC: 'static sqInt oilXmmPinned[OilNumRegs]'.
	#(oilFloatLoopHead oilFloatLoopEnd oilFloatLoopSite oilFloatLoopNum) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilMaxFloatLoops]'].
	#(oilFloatLoopVReg oilFloatLoopKind) do:
		[:var| aCCodeGenerator var: var declareC: 'static sqInt ', var, '[OilMaxFloatLoops * OilMaxPinnedXmms]'].
	aCCodeGenerator var: #oilSiteFloatLoop declareC: 'static unsigned char oilSiteFloatLoop[OilMaxSites]'.
	aCCodeGenerator var: #oilFloatExitJump declareC: 'static AbstractInstruction *oilFloatExitJump[OilMaxFloatExits]'.
	aCCodeGenerator var: #oilFloatExitTarget declareC: 'static sqInt oilFloatExitTarget[OilMaxFloatExits]'! !

!OilConvolutedCompiler methodsFor: 'initialization' stamp: 'cb 10/27/2026 12:00'!
setUpSimulationTables
	<doNotGenerate>
	super setUpSimulationTables.
	oilXmmPinned := self newTable: OilNumRegs.
	oilFloatLoopHead := self newTable: OilMaxFloatLoops.
	oilFloatLoopEnd := self newTable: OilMaxFloatLoops.
	oilFloatLoopSite := self newTable: OilMaxFloatLoops.
	oilFloatLoopNum := self newTable: OilMaxFloatLoops.
	oilFloatLoopVReg := self newTable: OilMaxFloatLoops * OilMaxPinnedXmms.
	oilFloatLoopKind := self newTable: OilMaxFloatLoops * OilMaxPinnedXmms.
	oilSiteFloatLoop := self newTable: OilMaxSites.
	oilFloatExitJump := self newTable: OilMaxFloatExits.
	oilFloatExitTarget := self newTable: OilMaxFloatExits.
	oilNumFloatLoops := oilNumFloatExits := 0.
	oilFloatLoopCurrent := -1! !

!OilConvolutedCompiler methodsFor: 'float fusion' stamp: 'cb 10/26/2026 20:30'!
mayRead: vreg paths: stack count: numPaths states: withStates
	<inline: false>
	<var: #stack type: #'sqInt *'>
	| sp irOffset opcode budget |
	sp := numPaths.
	budget := withStates ifTrue: [256] ifFalse: [512].
	[sp > 0] whileTrue:
		[sp := sp - 1.
		 irOffset := stack at: sp.
		 withStates ifFalse: [irOffset := self firstVisitOf: irOffset].
		 [irOffset < irIndex] whileTrue:
			[(budget := budget - 1) < 0 ifTrue: [^true].
			 opcode := self opcodeAt: irOffset.
			 (self instruction: irOffset reads: vreg) ifTrue: [^true].
			 (withStates and: [self liveStateAt: irOffset refersTo: vreg]) ifTrue: [^true].
			 ((opcode = OilReturn or: [opcode = OilTrap])
			  or: [(self opcodeHasDest: opcode) and: [(self fieldAAt: irOffset) = vreg]])
				ifTrue: [irOffset := irIndex]
				ifFalse:
					[(opcode = OilBranchTrue or: [opcode = OilBranchFalse]) ifTrue:
						[sp >= 16 ifTrue: [^true].
						 stack at: sp put: (self imm16At: irOffset).
						 sp := sp + 1].
					 irOffset := opcode = OilJump
									ifTrue: [self imm16At: irOffset]
									ifFalse: [irOffset + (self instructionLengthAt: irOffset)].
					 (withStates not and: [irOffset < irIndex and: [(oilIRTarget at: irOffset) ~= 0]]) ifTrue:
						[irOffset := self firstVisitOf: irOffset]]]].
	^false! !

!OilConvolutedCompiler methodsFor: 'float fusion' stamp: 'cb 10/26/2026 20:30'!
firstVisitOf: irOffset
	irOffset >= irIndex ifTrue: [^irIndex].
	(oilIRMap at: irOffset) ~= 0 ifTrue: [^irIndex].
	oilIRMap at: irOffset put: 1.
	^irOffset! !

!OilConvolutedCompiler methodsFor: 'float loop registers' stamp: 'cb 10/25/2026 22:30'!
prepareFloatLoops
	| irOffset |
	oilNumFloatLoops := oilNumFloatExits := 0.
	oilFloatLoopCurrent := -1.
	0 to: OilNumRegs - 1 do: [:vreg| oilXmmPinned at: vreg put: -1].
	0 to: OilMaxSites - 1 do: [:siteIndex| oilSiteFloatLoop at: siteIndex put: 0].
	irOffset := 0.
	[irOffset < irIndex] whileTrue:
		[(((self opcodeAt: irOffset) = OilJump
		   or: [(self opcodeAt: irOffset) = OilBranchTrue and: [(self fieldAAt: irOffset) = OilFlagsReg]])
		  and: [(self imm16At: irOffset) <= irOffset]) ifTrue:
			[self analyzeFloatLoop: (self imm16At: irOffset) end: irOffset].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)]! !

!OilConvolutedCompiler methodsFor: 'float loop registers' stamp: 'cb 10/26/2026 20:30'!
analyzeFloatLoop: loopHead end: backJump
	| site entryOffset irOffset opcode target numCandidates candidate kind changed numPinned wanted candidates kinds |
	<var: #candidates declareC: 'sqInt candidates[16]'>
	<var: #kinds declareC: 'sqInt kinds[16]'>
	self cCode: [] inSmalltalk: [candidates := CArrayAccessor on: (Array new: 16). kinds := CArrayAccessor on: (Array new: 16)].
	oilNumFloatLoops >= OilMaxFloatLoops ifTrue: [^self].
	site := oilIRSite at: loopHead.
	entryOffset := loopHead.
	((self opcodeAt: backJump) = OilBranchTrue
	 and: [loopHead >= 2
	 and: [(self opcodeAt: loopHead - 1) = OilBranchFalse
	 and: [(self fieldAAt: loopHead - 1) = OilFlagsReg
	 and: [(oilIRTarget at: loopHead - 1) = 0
	 and: [(self opcodeAt: loopHead - 2) = OilCmpTagged or: [(self opcodeAt: loopHead - 2) = OilCmpImmTagged]]]]]]) ifTrue:
		[entryOffset := loopHead - 2.
		 ((oilIRSite at: entryOffset) >= 0 and: [self siteHasState: (oilIRSite at: entryOffset)]) ifTrue:
			[site := oilIRSite at: entryOffset]].
	site < 0 ifTrue: [site := self entrySiteAfter: loopHead].
	(site >= 0 and: [(self siteHasState: site) and: [numSites < OilMaxSites]]) ifFalse: [^self].
	numCandidates := 0.
	irOffset := 0.
	[irOffset < irIndex] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (self isBranch: opcode) ifTrue:
			[target := self imm16At: irOffset.
			 (irOffset ~= backJump and: [target = loopHead]) ifTrue: [^self].
			 (irOffset > loopHead and: [irOffset < backJump and: [target <= irOffset]]) ifTrue: [^self]].
		 (irOffset >= loopHead and: [irOffset < backJump]) ifTrue:
			[((self mayClobberXmms: opcode) or: [opcode = OilReturn]) ifTrue: [^self].
			 (self isFloatOpcode: opcode) ifTrue:
				[numCandidates := self addCandidate: (self fieldBAt: irOffset) to: candidates count: numCandidates.
				 (self opcode: opcode has: OilOpReadsC) ifTrue:
					[numCandidates := self addCandidate: (self fieldCAt: irOffset) to: candidates count: numCandidates].
				 opcode ~= OilCmpFloat ifTrue:
					[numCandidates := self addCandidate: (self fieldAAt: irOffset) to: candidates count: numCandidates].
				 numCandidates < 0 ifTrue: [^self]]].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	numCandidates = 0 ifTrue: [^self].
	0 to: numCandidates - 1 do:
		[:index|
		candidate := candidates at: index.
		(self isAssigned: candidate from: loopHead to: backJump - 1)
			ifTrue: [kind := (self isTempFloat: candidate from: loopHead to: backJump) ifTrue: [2] ifFalse: [1]]
			ifFalse: [kind := 100 + (self floatIntModeOf: candidate from: loopHead to: backJump)].
		kinds at: index put: kind].
	changed := true.
	[changed] whileTrue:
		[changed := false.
		 0 to: numCandidates - 1 do:
			[:index|
			kind := kinds at: index.
			((kind = 1 or: [kind = 2])
			 and: [(self isFloatVariable: (candidates at: index) from: loopHead to: backJump candidates: candidates kinds: kinds count: numCandidates) not
				or: [kind = 1
						ifTrue: [(self isFloatEntering: (candidates at: index) loop: loopHead entry: entryOffset) not
									and: [(self isFloatReceiver: (candidates at: index) atStartOf: loopHead) not]]
						ifFalse: [self isFloat: (candidates at: index) readAfterLoop: loopHead end: backJump]]]) ifTrue:
				[kinds at: index put: -1.
				 changed := true]]].
	numPinned := 0.
	wanted := 0.
	[wanted < 2] whileTrue:
		[0 to: numCandidates - 1 do:
			[:index|
			kind := kinds at: index.
			((wanted = 0 ifTrue: [kind = 1 or: [kind = 2]] ifFalse: [kind >= 100]) and: [numPinned < OilMaxPinnedXmms]) ifTrue:
				[oilFloatLoopVReg at: oilNumFloatLoops * OilMaxPinnedXmms + numPinned put: (candidates at: index).
				 oilFloatLoopKind at: oilNumFloatLoops * OilMaxPinnedXmms + numPinned put: kind.
				 numPinned := numPinned + 1]].
		 wanted := wanted + 1].
	numPinned = 0 ifTrue: [^self].
	oilFloatLoopHead at: oilNumFloatLoops put: loopHead.
	oilFloatLoopEnd at: oilNumFloatLoops put: backJump.
	oilFloatLoopNum at: oilNumFloatLoops put: numPinned.
	oilFloatLoopSite at: oilNumFloatLoops put: (self cloneSite: site at: loopHead).
	oilNumFloatLoops := oilNumFloatLoops + 1! !

!OilConvolutedCompiler methodsFor: 'float loop registers' stamp: 'cb 10/26/2026 20:30'!
entrySiteAfter: loopHead
	| irOffset opcode siteIndex |
	irOffset := loopHead.
	[irOffset < irIndex] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (irOffset > loopHead and: [(oilIRTarget at: irOffset) ~= 0]) ifTrue: [^-1].
		 siteIndex := oilIRSite at: irOffset.
		 (siteIndex >= 0 and: [self siteHasState: siteIndex]) ifTrue:
			[irOffset := loopHead.
			 [(oilIRSite at: irOffset) ~= siteIndex] whileTrue:
				[(self state: siteIndex refersTo: (self fieldAAt: irOffset)) ifTrue: [^-1].
				 irOffset := irOffset + (self instructionLengthAt: irOffset)].
			 ^siteIndex].
		 (opcode = OilConstTagged or: [opcode = OilConst64 or: [opcode = OilMove or: [opcode = OilLoadField
		  or: [opcode = OilLoadSize or: [opcode = OilLoadByteSize]]]]]) ifFalse: [^-1].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^-1! !

!OilConvolutedCompiler methodsFor: 'float loop registers' stamp: 'cb 10/26/2026 20:30'!
isFloatReceiver: vreg atStartOf: loopHead
	| irOffset opcode |
	irOffset := loopHead.
	[irOffset < irIndex] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 ((irOffset > loopHead and: [(oilIRTarget at: irOffset) ~= 0])
		  or: [(self isBranch: opcode) or: [opcode = OilReturn]]) ifTrue: [^false].
		 ((self isFloatOpcode: opcode) and: [(self fieldBAt: irOffset) = vreg]) ifTrue: [^true].
		 ((self opcodeHasDest: opcode) and: [(self fieldAAt: irOffset) = vreg]) ifTrue: [^false].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^false! !

!OilConvolutedCompiler methodsFor: 'float loop registers' stamp: 'cb 10/26/2026 20:30'!
floatIntModeOf: vreg from: loopHead to: backJump
	| irOffset opcode intMode |
	intMode := 1.
	irOffset := loopHead.
	[irOffset < backJump] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 (self isFloatOpcode: opcode) ifTrue:
			[(self fieldBAt: irOffset) = vreg ifTrue: [intMode := 0].
			 ((self fieldCAt: irOffset) = vreg and: [opcode = OilCmpFloat and: [intMode = 1]]) ifTrue: [intMode := 2]].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^intMode! !

!OilConvolutedCompiler methodsFor: 'float loop registers' stamp: 'cb 10/26/2026 20:30'!
isTempFloat: vreg from: loopHead to: backJump
	| irOffset assigned |
	assigned := false.
	irOffset := loopHead.
	[irOffset < backJump] whileTrue:
		[(oilIRTarget at: irOffset) ~= 0 ifTrue: [assigned := false].
		 (assigned not and: [self instruction: irOffset reads: vreg]) ifTrue: [^false].
		 ((self opcodeHasDest: (self opcodeAt: irOffset)) and: [(self fieldAAt: irOffset) = vreg]) ifTrue: [assigned := true].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^true! !

!OilConvolutedCompiler methodsFor: 'float loop registers' stamp: 'cb 10/26/2026 20:30'!
isFloatEntering: vreg loop: loopHead entry: entryOffset
	| irOffset defOffset opcode |
	defOffset := -1.
	irOffset := self regionStartBefore: entryOffset.
	[irOffset < loopHead] whileTrue:
		[((self opcodeHasDest: (self opcodeAt: irOffset)) and: [(self fieldAAt: irOffset) = vreg]) ifTrue: [defOffset := irOffset].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	defOffset < 0 ifTrue: [^false].
	opcode := self opcodeAt: defOffset.
	opcode = OilConst64 ifTrue: [^self isFloatHandle: (self word64At: defOffset + 1)].
	^(self isFloatArith: opcode) and: [(self flag: defOffset has: OilFloatUnboxed) not]! !

!OilConvolutedCompiler methodsFor: 'float loop registers' stamp: 'cb 10/26/2026 20:30'!
isFloat: vreg readAfterLoop: loopHead end: backJump
	<inline: false>
	| stack sp irOffset opcode target |
	<var: #stack declareC: 'sqInt stack[16]'>
	self cCode: [] inSmalltalk: [stack := CArrayAccessor on: (Array new: 16)].
	0 to: irIndex - 1 do: [:offset| oilIRMap at: offset put: 0].
	sp := 0.
	(self opcodeAt: backJump) ~= OilJump ifTrue:
		[stack at: sp put: backJump + (self instructionLengthAt: backJump).
		 sp := sp + 1].
	irOffset := loopHead.
	[irOffset <= backJump] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 ((self isBranch: opcode) and: [(target := self imm16At: irOffset) < loopHead or: [target > backJump]]) ifTrue:
			[sp >= 16 ifTrue: [^true].
			 stack at: sp put: target.
			 sp := sp + 1].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^self mayRead: vreg paths: stack count: sp states: false! !

!OilConvolutedCompiler methodsFor: 'float loop registers' stamp: 'cb 10/27/2026 13:55'!
genFloatLoopEntryAt: irOffset
	| loopIndex resume vreg xmmIndex kind |
	<var: #resume type: #'AbstractInstruction *'>
	loopIndex := -1.
	0 to: oilNumFloatLoops - 1 do:
		[:index| (oilFloatLoopHead at: index) = irOffset ifTrue: [loopIndex := index]].
	loopIndex < 0 ifTrue: [^self].
	self resetXmms.
	resume := cogit Label.
	oilSiteResume at: (oilFloatLoopSite at: loopIndex) put: resume.
	0 to: (oilFloatLoopNum at: loopIndex) - 1 do:
		[:index|
		vreg := oilFloatLoopVReg at: loopIndex * OilMaxPinnedXmms + index.
		kind := oilFloatLoopKind at: loopIndex * OilMaxPinnedXmms + index.
		xmmIndex := OilNumXmms + index.
		kind = 2
			ifTrue:
				[cogit MoveCq: 0 R: TempReg.
				 cogit ConvertR: TempReg Rd: DPFPReg0 + xmmIndex]
			ifFalse:
				[self genLoadDouble: vreg into: DPFPReg0 + xmmIndex ints: (kind = 1 ifTrue: [0] ifFalse: [kind - 100]) site: (oilFloatLoopSite at: loopIndex).
				 kind = 1 ifTrue:
					[cogit MoveRd: DPFPReg0 + xmmIndex R: ClassReg.
					 self deopt: (cogit oilGenJumpNotSmallFloatValueBits: ClassReg scratch: TempReg) site: (oilFloatLoopSite at: loopIndex)]].
		oilXmmPinned at: vreg put: xmmIndex].
	oilFloatLoopCurrent := loopIndex! !

!OilConvolutedCompiler methodsFor: 'float loop registers' stamp: 'cb 10/25/2026 22:30'!
genFloatLoopExits
	| loopIndex label jumpOver |
	<var: #label type: #'AbstractInstruction *'>
	<var: #jumpOver type: #'AbstractInstruction *'>
	loopIndex := oilFloatLoopCurrent.
	oilFloatLoopCurrent := -1.
	jumpOver := nil.
	(self opcodeAt: (oilFloatLoopEnd at: loopIndex)) ~= OilJump ifTrue:
		[self genBoxFloatLoopVariables: loopIndex.
		 oilNumFloatExits > 0 ifTrue: [jumpOver := cogit Jump: 0]].
	0 to: oilNumFloatExits - 1 do:
		[:exitIndex|
		label := cogit Label.
		(oilFloatExitJump at: exitIndex) jmpTarget: label.
		self genBoxFloatLoopVariables: loopIndex.
		self branch: (cogit Jump: 0) to: (oilFloatExitTarget at: exitIndex)].
	oilNumFloatExits := 0.
	jumpOver ~= nil ifTrue: [jumpOver jmpTarget: cogit Label].
	0 to: (oilFloatLoopNum at: loopIndex) - 1 do:
		[:index| oilXmmPinned at: (oilFloatLoopVReg at: loopIndex * OilMaxPinnedXmms + index) put: -1].
	self resetXmms! !

!OilConvolutedCompiler methodsFor: 'float loop registers' stamp: 'cb 10/27/2026 13:55'!
genBoxFloatLoopVariables: loopIndex
	0 to: (oilFloatLoopNum at: loopIndex) - 1 do:
		[:index|
		(oilFloatLoopKind at: loopIndex * OilMaxPinnedXmms + index) < 100 ifTrue:
			[cogit MoveRd: DPFPReg0 + OilNumXmms + index R: ClassReg.
			 cogit oilGenConvertBitsToSmallFloatIn: ClassReg scratch: TempReg.
			 self setDst: (oilFloatLoopVReg at: loopIndex * OilMaxPinnedXmms + index) from: ClassReg]]! !

!OilConvolutedCompiler methodsFor: 'float loop registers' stamp: 'cb 10/25/2026 22:30'!
addCandidate: vreg to: candidates count: numCandidates
	<var: #candidates type: #'sqInt *'>
	numCandidates < 0 ifTrue: [^numCandidates].
	vreg >= OilFlagsReg ifTrue: [^numCandidates].
	0 to: numCandidates - 1 do: [:index| (candidates at: index) = vreg ifTrue: [^numCandidates]].
	numCandidates >= 16 ifTrue: [^-1].
	candidates at: numCandidates put: vreg.
	^numCandidates + 1! !

!OilConvolutedCompiler methodsFor: 'float loop registers' stamp: 'cb 10/26/2026 20:30'!
isFloatVariable: vreg from: loopHead to: backJump candidates: candidates kinds: kinds count: numCandidates
	<var: #candidates type: #'sqInt *'>
	<var: #kinds type: #'sqInt *'>
	| irOffset opcode |
	irOffset := loopHead.
	[irOffset < backJump] whileTrue:
		[opcode := self opcodeAt: irOffset.
		 opcode = OilMove
			ifTrue:
				[((self fieldAAt: irOffset) = vreg
				  and: [(self isVariableCandidate: (self fieldBAt: irOffset) in: candidates kinds: kinds count: numCandidates) not]) ifTrue: [^false].
				 ((self fieldBAt: irOffset) = vreg
				  and: [(self isVariableCandidate: (self fieldAAt: irOffset) in: candidates kinds: kinds count: numCandidates) not]) ifTrue: [^false]]
			ifFalse:
				[(self isFloatOpcode: opcode)
					ifTrue:
						[((self fieldAAt: irOffset) = vreg
						  and: [opcode ~= OilCmpFloat
						  and: [self flag: irOffset has: OilFloatUnboxed]]) ifTrue: [^false]]
					ifFalse:
						[((self opcodeHasDest: opcode) and: [(self fieldAAt: irOffset) = vreg]) ifTrue: [^false].
						 (self instruction: irOffset reads: vreg) ifTrue: [^false]]].
		 irOffset := irOffset + (self instructionLengthAt: irOffset)].
	^true! !

!OilConvolutedCompiler methodsFor: 'float loop registers' stamp: 'cb 10/25/2026 22:30'!
isVariableCandidate: vreg in: candidates kinds: kinds count: numCandidates
	<var: #candidates type: #'sqInt *'>
	<var: #kinds type: #'sqInt *'>
	0 to: numCandidates - 1 do:
		[:index| ((candidates at: index) = vreg and: [(kinds at: index) = 1 or: [(kinds at: index) = 2]]) ifTrue: [^true]].
	^false! !
