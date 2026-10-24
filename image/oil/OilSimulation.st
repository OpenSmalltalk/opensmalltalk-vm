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
printInstructionAt: instIndex on: aStream
	<doNotGenerate>
	| opcode regA regB regC name siteIndex |
	opcode := self opcodeAt: instIndex. regA := self fieldAAt: instIndex. regB := self fieldBAt: instIndex. regC := self fieldCAt: instIndex.
	name := (opcode between: 1 and: OilLastOpcode) ifTrue: [OilConstants opcodeNames at: opcode] ifFalse: ['?', opcode printString].
	aStream nextPutAll: '  '; nextPutAll: (instIndex printPaddedWith: bash to: 4); nextPutAll: '  ';
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
		[OilXorTagged]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' bitXor: ', (self reg: regC), '   (xorq; orq )'].
		[OilShiftTagged]	-> [| shiftVal | shiftVal := self signed8: regC.
							 aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB),
								(shiftVal > 0 ifTrue: [' >> ', shiftVal printString, '   (// ', (1 bitShift: shiftVal) printString, ': sarq $', (3 + shiftVal) printString, '; shlq ; orq )']
									ifFalse: [' << ', shiftVal negated printString, '   (* ', (1 bitShift: shiftVal negated) printString, ')'])].
		[OilOddTagged]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' \ 2   ((x bitAnd: 8) bitOr: 1)'].
		[OilLoadField]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), '.slot[', regC printString, ']'].
		[OilStoreField]	-> [aStream nextPutAll: (self reg: regB), '.slot[', regC printString, '] := ', (self reg: regA), '   (store check)'].
		[OilLoadElement]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), '[', (self reg: regC), ']   (movq -1(arr,idx))'].
		[OilStoreElement]	-> [aStream nextPutAll: (self reg: regB), '[', (self reg: regC), '] := ', (self reg: regA), '   (store check)'].
		[OilCmpTagged]	-> [aStream nextPutAll: (self reg: regB), ' ', (self condName: regA), ' ', (self reg: regC)].
		[OilCmpImmTagged]	-> [aStream nextPutAll: (self reg: regB), ' ', (self condName: regA), ' ', (self signed8: regC) printString].
		[OilBranchTrue]	-> [aStream nextPutAll: (regA = OilFlagsReg ifTrue: ['flags'] ifFalse: [self reg: regA]), ' -> L', ((self imm16At: instIndex) printPaddedWith: bash to: 4)].
		[OilBranchFalse]	-> [aStream nextPutAll: (regA = OilFlagsReg ifTrue: ['flags'] ifFalse: [self reg: regA]), ' -> L', ((self imm16At: instIndex) printPaddedWith: bash to: 4)].
		[OilJump]			-> [aStream nextPutAll: '-> L', ((self imm16At: instIndex) printPaddedWith: bash to: 4)].
		[OilReturn]		-> [aStream nextPutAll: (self reg: regA)].
		[OilGuardClass]	-> [aStream nextPutAll: 'class(', (self reg: regA), ') == ', (self printHandle: (self word64At: instIndex + 1))].
		[OilCheckBounds]	-> [aStream nextPutAll: '1 <= ', (self reg: regA), ' <= ', (self reg: regB)].
		[OilCall0]			-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' ', (self printHandle: (self word64At: instIndex + 1))].
		[OilCall1]			-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' ', (self printHandle: (self word64At: instIndex + 1)), ' ', (self reg: regC)].
		[OilCallN]			-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' ', (self printHandle: (self word64At: instIndex + 1)), ' (', (self packedArgsAt: instIndex + 3 count: regC), ')'].
		[OilCallSuper]		-> [aStream nextPutAll: (self reg: regA), ' := super ', (self printHandle: (self word64At: instIndex + 1)), ' rcvr ', (self reg: regB), ' (', (self packedArgsAt: instIndex + 3 count: regC), ')'].
		[OilAddImmTagged]	-> [| immVal | immVal := self signed8: regC. aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), (immVal >= 0 ifTrue: [' + '] ifFalse: [' - ']), immVal abs printString, '   (addq $', (immVal * 8) printString, ')'].
		[OilTrap]			-> [aStream nextPutAll: 'uncommon trap'].
		[OilStreamNext]		-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' next   (inlined, else sent)'].
		[OilStreamNextPut]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' nextPut: ', (self reg: regC), '   (inlined, else sent)'].
		[OilCharValue]		-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' asInteger'].
		[OilLoadByteSize]	-> [aStream nextPutAll: (self reg: regA), ' := byteSize(', (self reg: regB), ')'].
		[OilLoadByte]		-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), '[', (self reg: regC), '] (byte)'].
		[OilLoadChar]		-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), '[', (self reg: regC), '] (Character)'].
		[OilStoreByte]		-> [aStream nextPutAll: (self reg: regB), '[', (self reg: regC), '] := ', (self reg: regA), ' (byte)'].
		[OilStoreChar]		-> [aStream nextPutAll: (self reg: regB), '[', (self reg: regC), '] := ', (self reg: regA), ' (Character)'].
		[OilCompareBytes]	-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' compareWith: ', (self reg: regC)].
		[OilModTagged]		-> [aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), ' \ ', (self reg: regC), '   (idiv; floored)'].
		[OilAddImmTaggedNC]	-> [| immVal | immVal := self signed8: regC. aStream nextPutAll: (self reg: regA), ' := ', (self reg: regB), (immVal >= 0 ifTrue: [' + '] ifFalse: [' - ']), immVal abs printString, '   (addq $', (immVal * 8) printString, ', no overflow check)'].
		[OilLoadSize]		-> [aStream nextPutAll: (self reg: regA), ' := size(', (self reg: regB), ')'].
		[OilMakeClosure]	-> [aStream nextPutAll: (self reg: regA), ' := closure ', (self printHandle: (self word64At: instIndex + 1)), ' self ', (self reg: (self fieldCAt: instIndex + 3)), ' copied ', regC printString, ' from ', (self reg: regB)].
		[OilNewArray]		-> [aStream nextPutAll: (self reg: regA), ' := Array new: ', regC printString, (regB = OilFlagsReg ifTrue: ['   (nil filled)'] ifFalse: ['   from ', (self reg: regB), '..', (self reg: regB + regC - 1)])] }
		otherwise: [].
	siteIndex := (0 to: numSites - 1) detect: [:s| (siteIR at: s) = instIndex] ifNone: [nil].
	siteIndex ifNotNil:
		[aStream nextPutAll: '   ; deopt#'; print: siteIndex; nextPutAll: ' #'; print: (siteFrame at: siteIndex); nextPutAll: ' pc '; print: (sitePC at: siteIndex)].
	aStream cr! !

!OilBaseCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
hexWord: word
	<doNotGenerate>
	| hexString |
	hexString := (word printStringBase: 16) asUppercase.
	^(String new: (8 - hexString size max: 0) withAll: bash), hexString! !

!OilBaseCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
reg: registerIndex
	<doNotGenerate>
	^'r', registerIndex printString! !

!OilBaseCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
condName: condCode
	<doNotGenerate>
	^#('<' '>' '<=' '>=' '=' '~=' '==' '~~') at: condCode! !

!OilBaseCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
printHandle: handleVal
	<doNotGenerate>
	| obj |
	obj := self objectFor: handleVal.
	^(obj isKindOf: CompiledCode)
		ifTrue: [obj printString]
		ifFalse: [obj printString contractTo: 60]! !

!OilBaseCompiler methodsFor: '*VMMaker-JIT-OilDebugging-printing' stamp: 'cb 10/24/2026 10:40'!
packedArgsAt: index count: count
	<doNotGenerate>
	^String streamContents:
		[:stream|
		0 to: count - 1 do:
			[:argIndex| | word |
			word := oilIRBuffer at: index + (argIndex // 4).
			argIndex > 0 ifTrue: [stream space].
			stream nextPutAll: (self reg: ((word bitShift: (3 - (argIndex \ 4)) * -8) bitAnd: 255))]]! !

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
	poolDictionaries: 'OilInstructionConstants OilConstants'
	category: 'VMMaker-JIT-OilDebugging'!

!OilIRInterpreter commentStamp: 'cb 10/24/2026 10:40' prior: 0!
I execute an OilCompiler's linear IR on host objects: run: receiver with: arguments answers the IR's result, or #deopt if a guard, a bounds check, a tag check or an overflow check fails (the VM would then deoptimize to the interpreter at the recorded deopt site).  Tagged SmallInteger opcodes are executed on untagged values with the SmallInteger checks they imply.!

!OilIRInterpreter methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:40'!
on: anOilCompiler
	compiler := anOilCompiler.
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
	^regs at: regIndex + 1 put: aValue! !

!OilIRInterpreter methodsFor: 'running' stamp: 'cb 10/24/2026 10:40'!
smallInt: anObject
	^anObject class == SmallInteger! !

!OilIRInterpreter methodsFor: 'running' stamp: 'cb 10/24/2026 10:40'!
tagged: aValue
	"Result of a tagged op: deopt on overflow."
	^(self smallInt: aValue) ifTrue: [aValue] ifFalse: [nil]! !

!OilIRInterpreter methodsFor: 'running' stamp: 'cb 10/24/2026 10:40'!
step: instIndex
	"Execute the instruction at instIndex.  Answer the next index, or an Association #result -> value / #deopt -> site."
	| comp opcode destReg srcReg1 srcReg2 nextIndex val1 val2 resVal |
	comp := compiler.
	opcode := comp opcodeAt: instIndex. destReg := comp fieldAAt: instIndex. srcReg1 := comp fieldBAt: instIndex. srcReg2 := comp fieldCAt: instIndex.
	nextIndex := instIndex + (comp instructionLengthAt: instIndex).
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
		 self r: destReg put: val1 \ val2. ^nextIndex].
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
	(opcode = OilCall0 or: [opcode = OilCall1 or: [opcode = OilCallN]]) ifTrue:
		[| selector args |
		 selector := comp objectFor: (comp word64At: instIndex + 1).
		 args := (1 to: selector numArgs) collect: [:argIndex| self r: srcReg1 + argIndex].
		 self r: destReg put: ((self r: srcReg1) perform: selector withArguments: args). ^nextIndex].
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
