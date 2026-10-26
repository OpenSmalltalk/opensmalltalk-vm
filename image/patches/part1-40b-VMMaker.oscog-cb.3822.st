"Part 1 of 2 (VMMaker.oscog-cb.3822): accessors for CogAbstractInstruction's machine code and address.
 Mechanical: the back ends' direct references to the machineCode and address inst vars become
 self machineCodeBuffer and self address / self address: sends (statement-level cascades on
 machineCode are split into separate statements).  machineCodeBuffer simply answers machineCode,
 and address/address: are the existing accessors, so the generated C is unchanged.
 Part 2 (VMMaker.oscog-cb.3823) then generates machine code into a scratch buffer and compresses
 the address, which shrinks AbstractInstruction to 40 bytes."!

!CogAbstractInstruction methodsFor: 'accessing' stamp: 'cb 10/26/2026 22:30'!
machineCodeBuffer
	"Answer the array into which machine code is generated when concretizing.
	 The return type is only used where Slang does not inline (in asserts on byte back ends)."
	<inline: #always>
	<returnTypeC: #'unsigned char *'>
	^machineCode! !

!CogAbstractInstruction methodsFor: 'generate machine code' stamp: 'cb 10/26/2026 22:30'!
computeJumpTargetOffsetPlus: anPCOffset
	<inline: true> "Since it's an extraction from other methods."
	| jumpTarget |
	<var: #jumpTarget type: #'AbstractInstruction *'>
	jumpTarget := self jumpTargetAddress.
	^objectMemory wordSize = 8
		ifTrue: [jumpTarget signedIntFromLong64 - (self address + anPCOffset) signedIntFromLong64]
		ifFalse: [jumpTarget signedIntFromLong - (self address + anPCOffset) signedIntFromLong]! !

!CogAbstractInstruction methodsFor: 'generate machine code' stamp: 'cb 10/26/2026 22:30'!
concretizeAt: actualAddress
	"Generate concrete machine code for the instruction at actualAddress,
	 setting machineCodeSize, and answer the following address."

	self address: actualAddress.
	machineCodeSize := self dispatchConcretize.
	self assert: (maxSize = nil or: [maxSize >= machineCodeSize]).
	^actualAddress + machineCodeSize! !

!CogAbstractInstruction methodsFor: 'generate machine code' stamp: 'cb 10/26/2026 22:30'!
mapEntryAddress
	"Typically map entries apply to the end of an instruction, for two reasons:
	  a)	to cope with literals embedded in variable-length instructions, since, e.g.
		on x86, the literal typically comes at the end of the instruction.
	  b)	in-line cache detection is based on return addresses, which are typically
		to the instruction following a call."
	<inline: true>
	^self address + machineCodeSize! !

!CogAbstractInstruction methodsFor: 'initialization' stamp: 'cb 10/26/2026 22:30'!
cloneLiteralFrom: existingLiteral
	"For out-of-line literal support, clone a literal from a literal."
	<var: 'existingLiteral' type: #'AbstractInstruction *'>
	self assert: (existingLiteral opcode = Literal and: [dependent isNil and: [self address isNil]]).
	opcode := Literal.
	annotation := existingLiteral annotation.
	operands
		at: 0 put: (existingLiteral operands at: 0);
		at: 1 put: (existingLiteral operands at: 1);
		at: 2 put: (existingLiteral operands at: 2).
	self cCode: nil inSmalltalk:
		[bcpc := existingLiteral bcpc]! !

!CogAbstractInstruction methodsFor: 'initialization' stamp: 'cb 10/26/2026 22:30'!
initializeSharableLiteral: literal
	"For out-of-line literal support, initialize a sharable literal."
	opcode := Literal.
	annotation := nil. "separate := nil for Slang"
	self address: nil.
	dependent := nil.
	operands
		at: 0 put: literal;
		at: 1 put: (1 + (objectMemory bytesPerOop << 1));	"isSharable/isUnique not plus the size of the literal"
		at: 2 put: -1			"opcodeIndex"! !

!CogAbstractInstruction methodsFor: 'initialization' stamp: 'cb 10/26/2026 22:30'!
initializeUniqueLiteral: literal
	"For out-of-line literal support, initialize an unsharable literal."
	opcode := Literal.
	annotation := nil. "separate := nil for Slang"
	self address: nil.
	dependent := nil.
	operands
		at: 0 put: literal;
		at: 1 put: 0 + (objectMemory bytesPerOop << 1);	"isSharable/isUnique not plus the size of the literal"
		at: 2 put: -1										"opcodeIndex"! !

!CogAbstractInstruction methodsFor: 'printing' stamp: 'cb 10/26/2026 22:30'!
printStateOn: aStream
	| opcodeName orneryOperands format |
	<doNotGenerate> "Smalltalk-side only"
	opcode ifNil:
		[^self].
	aStream space; nextPut: $(; nextPutAll: (opcodeName := self class nameForOpcode: opcode).
	orneryOperands := operands isCObjectAccessor
							ifTrue: [operands object]
							ifFalse: [operands].
	format := ((CogRTLOpcodes classPool includesKey: opcodeName)
				ifTrue: [CogRTLOpcodes]
				ifFalse: [self class]) printFormatForOpcodeName: opcodeName.
	(format ifNil: [orneryOperands] ifNotNil: [orneryOperands first: (format size min: orneryOperands size)]) withIndexDo:
		[:operand :index|
		operand ifNotNil:
			[aStream space.
			 index >= (orneryOperands identityIndexOf: nil ifAbsent: [orneryOperands size + 1]) ifTrue:
				[aStream print: index - 1; nextPut: $:].
			 (format notNil and: ['rf' includes: (format at: index ifAbsent: $-)])
				ifTrue: [aStream nextPutAll: ((format at: index) = $r
												ifTrue: [self nameForRegister: operand]
												ifFalse: [self nameForFPRegister: operand])]
				ifFalse:
					[| operandNameOrNil |
					 operandNameOrNil := operand isInteger ifTrue:
												[(cogit coInterpreter lookupAddress: operand) ifNil:
													[objectMemory lookupAddress: operand]].
					 operandNameOrNil ifNotNil: [aStream nextPut: ${].
					 aStream print: operand.
					 (operand isInteger and: [operand > 16 and: [opcode ~= Label]]) ifTrue:
						[objectMemory wordSize = 8
							ifTrue:
								[(operand allMask: 1 << 63) ifTrue:
									[aStream nextPut: $/; print: operand signedIntFromLong64]]
							ifFalse:
								[(operand allMask: 1 << 31) ifTrue:
									[aStream nextPut: $/; print: operand signedIntFromLong]].
						 aStream nextPut: $/.
						 operand printOn: aStream base: 16.
						 operandNameOrNil ifNotNil:
							[aStream nextPut: $=; nextPutAll: operandNameOrNil; nextPut: $}]]]]].
	machineCodeSize ifNotNil:
		[(machineCodeSize between: 1 and: machineCode size) ifTrue:
			[0 to: machineCodeSize - 1 by: self codeGranularity do:
				[:i|
				 aStream space.
				 (self machineCodeAt: i)
					ifNil: [aStream nextPut: $.]
					ifNotNil:
						[:mc|
						mc isInteger
							ifTrue: [mc printOn: aStream base: 16]
							ifFalse: [mc printOn: aStream]]]]].
	self address ifNotNil:
		[aStream space; nextPut: $@.
		 self address printOn: aStream base: 16].
	aStream nextPut: $)! !

!CogX64Compiler methodsFor: 'accessing' stamp: 'cb 10/26/2026 22:30'!
machineCodeAt: anOffset
	^self machineCodeBuffer at: anOffset! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeAlignmentNops
	<inline: true>
	self flag: 'if performance is an issue generate longer nops'.
	0 to: machineCodeSize - 1 do:
		[:i|
		self machineCodeBuffer at: i put: 16r90].
	^machineCodeSize! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeArithCqRWithRO: regOpcode raxOpcode: raxOpcode
	"Will get inlined into concretizeAt: switch."
	<inline: false>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	self machineCodeBuffer
		at: 0 put: (self rexR: 0 x: 0 b: reg).
	(self isQuick: value) ifTrue:
		[self machineCodeBuffer at: 1 put: 16r83.
		 self machineCodeBuffer at: 2 put: (self mod: ModReg RM: reg RO: regOpcode).
		 self machineCodeBuffer at: 3 put: (value bitAnd: 16rFF).
		 ^4].
	(self is32BitSignedImmediate: value) ifTrue:
		[reg = RAX ifTrue:
			[self machineCodeBuffer at: 1 put: raxOpcode.
			 self machineCodeBuffer at: 2 put: (value bitAnd: 16rFF).
			 self machineCodeBuffer at: 3 put: (value >> 8 bitAnd: 16rFF).
			 self machineCodeBuffer at: 4 put: (value >> 16 bitAnd: 16rFF).
			 self machineCodeBuffer at: 5 put: (value >> 24 bitAnd: 16rFF).
			 ^6].
		self machineCodeBuffer at: 1 put: 16r81.
		self machineCodeBuffer at: 2 put: (self mod: ModReg RM: reg RO: regOpcode).
		self machineCodeBuffer at: 3 put: (value bitAnd: 16rFF).
		self machineCodeBuffer at: 4 put: (value >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (value >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 6 put: (value >> 24 bitAnd: 16rFF).
		 ^7].
	^self concretizeArithCwR: (raxOpcode = 16r3D "Cmp" ifTrue: [16r39] ifFalse: [raxOpcode - 2])! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeCall
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| offset |
	self assert: (operands at: 0) ~= 0.
	offset := (operands at: 0) signedIntFromLong - (self address + 5) signedIntFromLong.
	self machineCodeBuffer at: 0 put: 16rE8.
	self machineCodeBuffer at: 1 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 2 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (offset >> 24 bitAnd: 16rFF).
	^5! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeCallFull
	"Since CallFull (and JumpFull) is used to invoke code in dynamically-loaded plugins it shouldn't
	 assume that code will be loaded within 2Gb of the code zone.  Hence generate a full 64-bit call,
	 movabsq $0x123456789abcdef0, %rax; callq *%rax."
	<inline: true>
	| operand |
	operand := operands at: 0.
	self machineCodeBuffer at: 0 put: 16r48.
	self machineCodeBuffer at: 1 put: 16rB8.
	self machineCodeBuffer at: 2 put: (operand bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (operand >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (operand >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (operand >> 24 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (operand >> 32 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 put: (operand >> 40 bitAnd: 16rFF).
	self machineCodeBuffer at: 8 put: (operand >> 48 bitAnd: 16rFF).
	self machineCodeBuffer at: 9 put: (operand >> 56 bitAnd: 16rFF).
	self machineCodeBuffer at: 10 put: 16rFF.
	self machineCodeBuffer at: 11 put: (self mod: ModReg RM: RAX RO: 2).
	^12! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeCallR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg |
	reg := operands at: 0.
	self machineCodeBuffer at: 0 put: (self rexR: 0 x: 0 b: reg).
	self machineCodeBuffer at: 1 put: 16rFF.
	self machineCodeBuffer at: 2 put: (self mod: ModReg RM: reg RO: 2).
	^3! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeClzRR
	"Count leading zeros
	 First operand is input (mask)
	 Second operand is output (dest)"
	"LZCNT"
	<inline: true>
	| maskReg dest |
	self assert: self hasLZCNTInstructions.
	maskReg := operands at: 0.
	dest := operands at: 1.
	self machineCodeBuffer at: 0 put: 16rF3.
	self machineCodeBuffer at: 1 put: (self rexw: true r: dest x: 0 b: maskReg).
	self machineCodeBuffer at: 2 put: 16r0F.
	self machineCodeBuffer at: 3 put: 16rBD.
	self machineCodeBuffer at: 4 put: (self mod: ModReg RM: maskReg RO: dest).
	 ^5! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeCmpC32R
	"Will get inlined into concretizeAt: switch."
	"N.B. This use of 32-bit comparisons allows us to squeak by and use a short jump
	 in PIC case dispatch, where a jump to the abort is 126 bytes (!!!!)."
	<inline: true>
	| value reg skip |
	value := operands at: 0.
	reg := operands at: 1.
	reg = RAX
		ifTrue:
			[self machineCodeBuffer at: 0 put: 16r3D.
			 skip := 0]
		ifFalse:
			[reg > 7
				ifTrue:
					[self machineCodeBuffer at: 0 put: 16r41.
					 skip := 2]
				ifFalse:
					[skip := 1].
			 self machineCodeBuffer at: skip - 1 put: 16r81.
			 self machineCodeBuffer at: skip put:  (self mod: ModReg RM: reg RO: 7)].
	self machineCodeBuffer at: skip + 1 put: (value bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 2 put: (value >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 3 put: (value >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 4 put: (value >> 24 bitAnd: 16rFF).
	 ^5 + skip! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeCmpRdRd
	"Will get inlined into concretizeAt: switch.
	 We use UCOMISD (see p 4-260 [2])"
	<inline: true>
	| regLHS regRHS skip |
	"CmpRR RHS LHS computes LHS - RHS, i.e. apparently reversed.  You have to think subtract."
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	
	self machineCodeBuffer
		at: 0 put: 16r66.
	(regLHS <= 7 and: [regRHS <= 7])
		ifTrue: [skip := 0]
		ifFalse: [self machineCodeBuffer at: (skip := 1) put: (self rexw: false r: regLHS x: 0 b: regRHS)].	
	
	self machineCodeBuffer at: skip + 1 put: 16r0F.
	self machineCodeBuffer at: skip + 2 put: 16r2E.
	self machineCodeBuffer at: skip + 3 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^skip + 4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeCmpRsRs
	"Will get inlined into concretizeAt: switch.
	 We use UCOMISS"
	<inline: true>
	| regLHS regRHS skip |
	"CmpRR RHS LHS computes LHS - RHS, i.e. apparently reversed.  You have to think subtract."
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	
	(regLHS <= 7 and: [regRHS <= 7])
		ifTrue: [skip := 0]
		ifFalse: [self machineCodeBuffer at: (skip := 1) put: (self rexw: false r: regLHS x: 0 b: regRHS)].
		
	self machineCodeBuffer at: skip + 0 put: 16r0F.
	self machineCodeBuffer at: skip + 1 put: 16r2E.
	self machineCodeBuffer at: skip + 2 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^skip + 3! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConditionalJump: conditionCode
	"Will get inlined into concretizeAt: switch."
	"Sizing/generating jumps.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: true>
	| offset |
	offset := self computeJumpTargetOffsetPlus: 2.
	(machineCodeSize = 0 "size not determined because no sizeJump pass; generating initial trampolines"
		ifTrue: [self isQuick: offset]
		ifFalse: [machineCodeSize = 2]) ifTrue:
		[self machineCodeBuffer at: 0 put: 16r70 + conditionCode.
		 self machineCodeBuffer at: 1 put: (offset bitAnd: 16rFF).
		 ^2].
	^self concretizeConditionalJumpLong: conditionCode! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConditionalJumpLong: conditionCode
	"Will get inlined into concretizeAt: switch."
	"Sizing/generating jumps.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: true>
	| offset |
	offset := self computeJumpTargetOffsetPlus: 6.
	self machineCodeBuffer at: 0 put: 16r0F.
	self machineCodeBuffer at: 1 put: 16r80 + conditionCode.
	self machineCodeBuffer at: 2 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (offset >> 24 bitAnd: 16rFF).
	^6! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConvertRRd
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg destReg |
	srcReg := operands at:0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: 16rF2.
	self machineCodeBuffer at: 1 put: (self rexR: destReg x: 0 b: srcReg).
	self machineCodeBuffer at: 2 put: 16r0F.
	self machineCodeBuffer at: 3 put: 16r2A.
	self machineCodeBuffer at: 4 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^5! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConvertRRs
	"Will get inlined into concretizeAt: switch."
	"CVTSI2SS"
	<inline: true>
	| srcReg destReg skip |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer
		at: 0 put: 16rF3.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [self machineCodeBuffer at: (skip := 1) put: (self rexw: false r: destReg x: 0 b: srcReg)].
		
	self machineCodeBuffer at: skip + 1 put: 16r0F.
	self machineCodeBuffer at: skip + 2 put: 16r2A.
	self machineCodeBuffer at: skip + 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^skip + 4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConvertRdR
	"Will get inlined into concretizeAt: switch."
	"CVTSD2SI"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at:0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: 16rF2.
	self machineCodeBuffer at: 1 put: (self rexR: destReg x: 0 b: srcReg).
	self machineCodeBuffer at: 2 put: 16r0F.
	self machineCodeBuffer at: 3 put: 16r2D.
	self machineCodeBuffer at: 4 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^5! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConvertRdRs
	"Will get inlined into concretizeAt: switch."
	"CVTSD2SS"
	<inline: true>
	| srcReg destReg skip |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer
		at: 0 put: 16rF2.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [self machineCodeBuffer at: (skip := 1) put: (self rexw: false r: destReg x: 0 b: srcReg)].
		
	self machineCodeBuffer at: skip + 1 put: 16r0F.
	self machineCodeBuffer at: skip + 2 put: 16r5A.
	self machineCodeBuffer at: skip + 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^skip + 4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConvertRsR
	"Will get inlined into concretizeAt: switch."
	"CVTSS2SI"
	<inline: true>
	| srcReg destReg skip |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer
		at: 0 put: 16rF3.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [self machineCodeBuffer at: (skip := 1) put: (self rexw: false r: destReg x: 0 b: srcReg)].
		
	self machineCodeBuffer at: skip + 1 put: 16r0F.
	self machineCodeBuffer at: skip + 2 put: 16r2D.
	self machineCodeBuffer at: skip + 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^skip + 4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConvertRsRd
	"Will get inlined into concretizeAt: switch."
	"CVTSS2SD"
	<inline: true>
	| srcReg destReg skip |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer
		at: 0 put: 16rF3.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [self machineCodeBuffer at: (skip := 1) put: (self rexw: false r: destReg x: 0 b: srcReg)].
		
	self machineCodeBuffer at: skip + 1 put: 16r0F.
	self machineCodeBuffer at: skip + 2 put: 16r5A.
	self machineCodeBuffer at: skip + 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^skip + 4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeFill32
	<inline: true>
	| word |
	<var: #word type: #'usqIntptr_t'>
	word := operands at: 0.
	self machineCodeBuffer at: 0 put: (word bitAnd: 16rFF).
	self machineCodeBuffer at: 1 put: (word >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 2 put: (word >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (word >> 24 bitAnd: 16rFF).
	^4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeJump
	"Will get inlined into concretizeAt: switch."
	"Sizing/generating jumps.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: true>
	| jumpTarget offset |
	<var: #jumpTarget type: #'AbstractInstruction *'>
	jumpTarget := cogit cCoerceSimple: (operands at: 0) to: #'AbstractInstruction *'.
	cogit assertSaneJumpTarget: jumpTarget.
	(self isAnInstruction: jumpTarget) ifTrue:
		[jumpTarget := cogit cCoerceSimple: jumpTarget address to: #'AbstractInstruction *'].
	self assert: jumpTarget ~= 0.
	offset := (jumpTarget asCharPointer - (self address + 2) asCharPointer) signedIntFromLong.
	(machineCodeSize = 0 "size not determined because no sizeJump pass; generating initial trampolines"
		ifTrue: [self isQuick: offset]
		ifFalse: [machineCodeSize = 2]) ifTrue:
		[self machineCodeBuffer at: 0 put: 16rEB.
		 self machineCodeBuffer at: 1 put: (offset bitAnd: 16rFF).
		 ^2].
	offset := (jumpTarget asCharPointer - (self address + 5) asCharPointer) signedIntFromLong.
	self machineCodeBuffer at: 0 put: 16rE9.
	self machineCodeBuffer at: 1 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 2 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (offset >> 24 bitAnd: 16rFF).
	^5! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeJumpFull
	"Since JumpFull (and CallFull) is used to invoke code in dynamically-loaded plugins it shouldn't
	 assume that code will be loaded within 2Gb of the code zone.  Hence generate a full 64-bit call,
	 movabsq 0x123456789abcdef0, %rax; jmpq *%rax."
	<inline: true>
	| operand |
	operand := operands at: 0.
	self machineCodeBuffer at: 0 put: 16r48.
	self machineCodeBuffer at: 1 put: 16rB8.
	self machineCodeBuffer at: 2 put: (operand bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (operand >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (operand >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (operand >> 24 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (operand >> 32 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 put: (operand >> 40 bitAnd: 16rFF).
	self machineCodeBuffer at: 8 put: (operand >> 48 bitAnd: 16rFF).
	self machineCodeBuffer at: 9 put: (operand >> 56 bitAnd: 16rFF).
	self machineCodeBuffer at: 10 put: 16rFF.
	self machineCodeBuffer at: 11 put: (self mod: ModReg RM: RAX RO: 4).
	^12! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeJumpLong
	"Will get inlined into concretizeAt: switch."
	"Sizing/generating jumps.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: true>
	| jumpTarget offset |
	<var: #jumpTarget type: #'AbstractInstruction *'>
	jumpTarget := cogit cCoerceSimple: (operands at: 0) to: #'AbstractInstruction *'.
	(self isAnInstruction: jumpTarget) ifTrue:
		[jumpTarget := cogit cCoerceSimple: jumpTarget address to: #'AbstractInstruction *'].
	self assert: jumpTarget ~= 0.
	offset := (jumpTarget asCharPointer - (self address + 5) asCharPointer) signedIntFromLong.
	self machineCodeBuffer at: 0 put: 16rE9.
	self machineCodeBuffer at: 1 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 2 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (offset >> 24 bitAnd: 16rFF).
	^5! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeJumpR
	<inline: true>
	| reg |
	reg := operands at: 0.
	self machineCodeBuffer at: 0 put: (self rexR: 0 x: 0 b: reg).
	self machineCodeBuffer at: 1 put: 16rFF.
	self machineCodeBuffer at: 2 put: (self mod: ModReg RM: reg RO: 4).
	^3! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeLoadEffectiveAddressMwrR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	self machineCodeBuffer at: 0 put: (self rexR: destReg x: 0 b: srcReg).
	self machineCodeBuffer at: 1 put: 16r8D.
	(srcReg ~= RSP and: [srcReg ~= R12]) ifTrue:
		[(self isQuick: offset) ifTrue:
			[self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
			 self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
			 ^4].
		self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
		self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 4 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^7].
	"ESP/R12:"
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
		 self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: srcReg).
		 self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
		 ^5].
	self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
	self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: srcReg).
	self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 put: (offset >> 24 bitAnd: 16rFF).
	^8! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveA32R
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg offset |
	addressOperand := operands at: 0.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	reg := operands at: 1.
	reg = RAX
		ifTrue: [offset := 0]
		ifFalse:
			[self machineCodeBuffer at: 0 put: (self rexR: 0 x: 0 b: reg).
			 self machineCodeBuffer at: 1 put: 16r90 + (reg \\ 8).
			 offset := 2].
	self machineCodeBuffer at: 0 + offset put: 16rA1.
	self machineCodeBuffer at: 1 + offset put: (addressOperand bitAnd: 16rFF).
	self machineCodeBuffer at: 2 + offset put: (addressOperand >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 3 + offset put: (addressOperand >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 + offset put: (addressOperand >> 24 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 + offset put: (addressOperand >> 32 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 + offset put: (addressOperand >> 40 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 + offset put: (addressOperand >> 48 bitAnd: 16rFF).
	self machineCodeBuffer at: 8 + offset put: (addressOperand >> 56 bitAnd: 16rFF).
	reg = RAX ifTrue:
		[^9].
	self machineCodeBuffer at: 11 put: (self machineCodeBuffer at: 0).
	self machineCodeBuffer at: 12 put: (self machineCodeBuffer at: 1).
	^13! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveAbR
	"N.B. The Cogit makes no assumption about the upper bits being set to zero because we
	 deny byteReadsZeroExtend.  The cogit will clear the register before hand if necessary."
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg offset save0 save1 savedSize |
	addressOperand := operands at: 0.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	(self isAddressRelativeToVarBase: addressOperand) ifTrue:
		[save0 := operands at: 0.
		 save1 := operands at: 1.
		 operands
			at: 0 put: addressOperand - cogit varBaseAddress;
			at: 1 put: RBX;
			at: 2 put: save1.
		 savedSize := self concretizeMoveMbrR.
		 operands
			at: 0 put: save0;
			at: 1 put: save1;
			at: 2 put: 0.
		^savedSize].
	reg := operands at: 1.
	reg = RAX
		ifTrue: [offset := 0]
		ifFalse:
			[self machineCodeBuffer at: 0 put: (self rexR: 0 x: 0 b: reg).
			 self machineCodeBuffer at: 1 put: 16r90 + (reg \\ 8).
			 offset := 2].
	self machineCodeBuffer at: 0 + offset put: 16r48.
	self machineCodeBuffer at: 1 + offset put: 16rA0.
	self machineCodeBuffer at: 2 + offset put: (addressOperand bitAnd: 16rFF).
	self machineCodeBuffer at: 3 + offset put: (addressOperand >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 + offset put: (addressOperand >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 + offset put: (addressOperand >> 24 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 + offset put: (addressOperand >> 32 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 + offset put: (addressOperand >> 40 bitAnd: 16rFF).
	self machineCodeBuffer at: 8 + offset put: (addressOperand >> 48 bitAnd: 16rFF).
	self machineCodeBuffer at: 9 + offset put: (addressOperand >> 56 bitAnd: 16rFF).
	reg = RAX ifTrue:
		[^10].
	self machineCodeBuffer at: 12 put: (self machineCodeBuffer at: 0).
	self machineCodeBuffer at: 13 put: (self machineCodeBuffer at: 1).
	^14! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveAwR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg offset save0 save1 savedSize |
	addressOperand := operands at: 0.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	(self isAddressRelativeToVarBase: addressOperand) ifTrue:
		[save0 := operands at: 0.
		 save1 := operands at: 1.
		 operands
			at: 0 put: addressOperand - cogit varBaseAddress;
			at: 1 put: RBX;
			at: 2 put: save1.
		 savedSize := self concretizeMoveMwrR.
		 operands
			at: 0 put: save0;
			at: 1 put: save1;
			at: 2 put: 0.
		^savedSize].
	reg := operands at: 1.
	"If fetching RAX, fetch directly, otherwise, because of instruction encoding limitations, the register
	 _must_ be fetched through RAX.  If reg = RBP or RSP simply fetch directly, otherwise swap RAX with
	 the register before and after the fetch through RAX.  We avoid swapping before hand with RBP
	 and RSP because setting RSP to whatever the contents of RAX is can cause disastrous results if
	 an interrupt is delivered immediately after that point.  See mail threads beginning with
		http://lists.squeakfoundation.org/pipermail/vm-dev/2019-September/031428.html
		http://lists.squeakfoundation.org/pipermail/vm-dev/2019-October/031499.html"
	(reg = RAX or: [reg = RBP or: [reg = RSP]])
		ifTrue: [offset := 0]
		ifFalse:
			[self machineCodeBuffer at: 0 put: (self rexR: 0 x: 0 b: reg).
			 self machineCodeBuffer at: 1 put: 16r90 + (reg \\ 8).
			 offset := 2].
	self machineCodeBuffer at: 0 + offset put: 16r48.
	self machineCodeBuffer at: 1 + offset put: 16rA1.
	self machineCodeBuffer at: 2 + offset put: (addressOperand bitAnd: 16rFF).
	self machineCodeBuffer at: 3 + offset put: (addressOperand >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 + offset put: (addressOperand >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 + offset put: (addressOperand >> 24 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 + offset put: (addressOperand >> 32 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 + offset put: (addressOperand >> 40 bitAnd: 16rFF).
	self machineCodeBuffer at: 8 + offset put: (addressOperand >> 48 bitAnd: 16rFF).
	self machineCodeBuffer at: 9 + offset put: (addressOperand >> 56 bitAnd: 16rFF).
	reg = RAX ifTrue:
		[^10].
	"Now effect the assignment via xchg, which saves a byte over a move"
	(reg = RBP or: [reg = RSP]) ifTrue:
		[self machineCodeBuffer at: 10 put: (self rexR: RAX x: 0 b: reg).
		 self machineCodeBuffer at: 11 put: 16r90 + (reg \\ 8).
		^12].
	self machineCodeBuffer at: 12 put: (self machineCodeBuffer at: 0).
	self machineCodeBuffer at: 13 put: (self machineCodeBuffer at: 1).
	^14! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveC32R
	"Will get inlined into concretizeAt: switch."
	"N.B. the selector dereferencing scheme depends on this being a sign-extending 32-bit to 64-bit move.
	 See CogObjectRepresentationFor64BitSpur>>#maybeGenerateSelectorIndexDereferenceRoutine."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	self machineCodeBuffer at: 0 put: (self rexR: 0 x: 0 b: reg).
	self machineCodeBuffer at: 1 put: 16rC7.
	self machineCodeBuffer at: 2 put: (self mod: ModReg RM: reg RO: 0).
	self machineCodeBuffer at: 3 put: (value bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (value >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (value >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (value >> 24 bitAnd: 16rFF).
	^7! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveCqR
	"Will get inlined into concretizeAt: switch.
	 On x64 we can short-cut mov 0, reg using xor, and use signed 32-bit displacement, if possible."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	(self is32BitSignedImmediate: value) ifTrue:
		[value = 0 ifTrue:
			[self machineCodeBuffer at: 0 put: (self rexR: reg x: 0 b: reg).
			 self machineCodeBuffer at: 1 put: 16r31.
			 self machineCodeBuffer at: 2 put: (self mod: ModReg RM: reg RO: reg).
			 ^3].
		 self machineCodeBuffer at: 0 put: (self rexR: 0 x: 0 b: reg).
		 self machineCodeBuffer at: 1 put: 16rC7.
		 self machineCodeBuffer at: 2 put: (self mod: ModReg RM: reg RO: 0).
		 self machineCodeBuffer at: 3 put: (value bitAnd: 16rFF).
		 self machineCodeBuffer at: 4 put: (value >> 8 bitAnd: 16rFF).
		 self machineCodeBuffer at: 5 put: (value >> 16 bitAnd: 16rFF).
		 self machineCodeBuffer at: 6 put: (value >> 24 bitAnd: 16rFF).
		 ^7].

	self machineCodeBuffer at:  0 put: (self rexR: 0 x: 0 b: reg).
	self machineCodeBuffer at:  1 put: 16rB8 + (reg bitAnd: 7).
	self machineCodeBuffer at:  2 put: (value bitAnd: 16rFF).
	self machineCodeBuffer at:  3 put: (value >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at:  4 put: (value >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at:  5 put: (value >> 24 bitAnd: 16rFF).
	self machineCodeBuffer at:  6 put: (value >> 32 bitAnd: 16rFF).
	self machineCodeBuffer at:  7 put: (value >> 40 bitAnd: 16rFF).
	self machineCodeBuffer at:  8 put: (value >> 48 bitAnd: 16rFF).
	self machineCodeBuffer at:  9 put: (value >> 56 bitAnd: 16rFF).
	^10! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveM16rR
	"N.B. The Cogit compiler makes no assumption about the upper bits being set to zero.
	 It will clear the register before hand if necessary."
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	self machineCodeBuffer at: 0 put: (self rexR: destReg x: 0 b: srcReg).
	self machineCodeBuffer at: 1 put: 16r0f.
	self machineCodeBuffer at: 2 put: 16rb7.
	(srcReg ~= RSP and: [srcReg ~= R12]) ifTrue:
		[(offset = 0 and: [srcReg ~= RBP and: [srcReg ~= R13]]) ifTrue:
			[self machineCodeBuffer
				at: 3 put: (self mod: ModRegInd RM: srcReg RO: destReg).
			 ^4].
		 (self isQuick: offset) ifTrue:
			[self machineCodeBuffer at: 3 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
			 self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
			 ^5].
		self machineCodeBuffer at: 3 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
		self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 6 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 7 put: (offset >> 24 bitAnd: 16rFF).
		^8].
	"RSP & R12:"
	(offset = 0 and: [srcReg ~= RBP and: [srcReg ~= R13]]) ifTrue:
		[self machineCodeBuffer at: 3 put: (self mod: ModRegInd RM: srcReg RO: destReg).
		 self machineCodeBuffer at: 4 put: (self s: SIB1 i: 4 b: srcReg).
		 ^5].
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: 3 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
		 self machineCodeBuffer at: 4 put: (self s: SIB1 i: 4 b: srcReg).
		 self machineCodeBuffer at: 5 put: (offset bitAnd: 16rFF).
		 ^6].
	self machineCodeBuffer at: 3 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
	self machineCodeBuffer at: 4 put: (self s: SIB1 i: 4 b: srcReg).
	self machineCodeBuffer at: 5 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 8 put: (offset >> 24 bitAnd: 16rFF).
	^9! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveM32rR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| offset srcReg destReg skip |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [skip := 1. self machineCodeBuffer at: 0 put: (self rexw: false r: destReg x: 0 b: srcReg)].
	self machineCodeBuffer
		at: skip + 0 put: 16r8b.
	offset = 0 ifTrue:
		[(srcReg bitAnd: 6) ~= RSP ifTrue:
			[self machineCodeBuffer at: skip + 1 put: (self mod: ModRegInd RM: srcReg RO: destReg).
			 ^skip + 2].
		 (srcReg bitAnd: 7) = RSP ifTrue: "RBP & R13 fall through"
			[self machineCodeBuffer at: skip + 1 put: (self mod: ModRegInd RM: srcReg RO: destReg).
			 self machineCodeBuffer at: skip + 2 put: (self s: SIB1 i: 4 b: srcReg).
			 ^skip + 3]].
	(self isQuick: offset) ifTrue:
		[(srcReg bitAnd: 7) ~= RSP ifTrue:
			[self machineCodeBuffer at: skip + 1 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
			 self machineCodeBuffer at: skip + 2 put: (offset bitAnd: 16rFF).
			 ^skip + 3].
		 self machineCodeBuffer at: skip + 1 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
		 self machineCodeBuffer at: skip + 2 put: (self s: SIB1 i: 4 b: srcReg).
		 self machineCodeBuffer at: skip + 3 put: (offset bitAnd: 16rFF).
		 ^skip + 4].
	self machineCodeBuffer at: skip + 1 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
	(srcReg bitAnd: 7) = RSP ifTrue:
		[self machineCodeBuffer at: skip + 2 put: (self s: SIB1 i: 4 b: srcReg).
		 skip := skip + 1].
	self machineCodeBuffer at: skip + 2 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 3 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 4 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 5 put: (offset >> 24 bitAnd: 16rFF).
	^skip + 6! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveM32rRs
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| offset srcReg destReg skip |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	self machineCodeBuffer at: 0 put: 16r66.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [self machineCodeBuffer at: (skip := 1) put: (self rexw: false r: destReg x: 0 b: srcReg)].
	self machineCodeBuffer at: skip + 1 put: 16r0f.
	self machineCodeBuffer at: skip + 2 put: 16r6e.
	offset = 0 ifTrue:
		[(srcReg bitAnd: 6) ~= RSP ifTrue:
			[self machineCodeBuffer at: skip + 3 put: (self mod: ModRegInd RM: srcReg RO: destReg).
			 ^skip + 4].
		 (srcReg bitAnd: 7) = RSP ifTrue: "RBP & R13 fall through"
			[self machineCodeBuffer at: skip + 3 put: (self mod: ModRegInd RM: srcReg RO: destReg).
			 self machineCodeBuffer at: skip + 4 put: (self s: SIB1 i: 4 b: srcReg).
			 ^skip + 5]].
	(self isQuick: offset) ifTrue:
		[(srcReg bitAnd: 7) ~= RSP ifTrue:
			[self machineCodeBuffer at: skip + 3 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
			 self machineCodeBuffer at: skip + 4 put: (offset bitAnd: 16rFF).
			 ^skip + 5].
		 self machineCodeBuffer at: skip + 3 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
		 self machineCodeBuffer at: skip + 4 put: (self s: SIB1 i: 4 b: srcReg).
		 self machineCodeBuffer at: skip + 5 put: (offset bitAnd: 16rFF).
		 ^skip + 6].
	self machineCodeBuffer at: skip + 3 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
	(srcReg bitAnd: 7) = RSP ifTrue:
		[self machineCodeBuffer at: skip + 4 put: (self s: SIB1 i: 4 b: srcReg).
		 skip := skip + 1].
	self machineCodeBuffer at: skip + 4 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 5 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 6 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 7 put: (offset >> 24 bitAnd: 16rFF).
	^skip + 8! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveM64rRd
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| offset srcReg destReg skip |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	self machineCodeBuffer at: 0 put: 16rF3.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [self machineCodeBuffer at: (skip := 1) put: (self rexw: false r: destReg x: 0 b: srcReg)].
	self machineCodeBuffer at: skip + 1 put: 16r0f.
	self machineCodeBuffer at: skip + 2 put: 16r7e.
	offset = 0 ifTrue:
		[(srcReg bitAnd: 6) ~= RSP ifTrue:
			[self machineCodeBuffer at: skip + 3 put: (self mod: ModRegInd RM: srcReg RO: destReg).
			 ^skip + 4].
		 (srcReg bitAnd: 7) = RSP ifTrue: "RBP & R13 fall through"
			[self machineCodeBuffer at: skip + 3 put: (self mod: ModRegInd RM: srcReg RO: destReg).
			 self machineCodeBuffer at: skip + 4 put: (self s: SIB1 i: 4 b: srcReg).
			 ^skip + 5]].
	(self isQuick: offset) ifTrue:
		[(srcReg bitAnd: 7) ~= RSP ifTrue:
			[self machineCodeBuffer at: skip + 3 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
			 self machineCodeBuffer at: skip + 4 put: (offset bitAnd: 16rFF).
			 ^skip + 5].
		 self machineCodeBuffer at: skip + 3 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
		 self machineCodeBuffer at: skip + 4 put: (self s: SIB1 i: 4 b: srcReg).
		 self machineCodeBuffer at: skip + 5 put: (offset bitAnd: 16rFF).
		 ^skip + 6].
	self machineCodeBuffer at: skip + 3 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
	(srcReg bitAnd: 7) = RSP ifTrue:
		[self machineCodeBuffer at: skip + 4 put: (self s: SIB1 i: 4 b: srcReg).
		 skip := skip + 1].
	self machineCodeBuffer at: skip + 4 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 5 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 6 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 7 put: (offset >> 24 bitAnd: 16rFF).
	^skip + 8! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveMbrR
	"N.B. The Cogit makes no assumption about the upper bits being set to zero because we
	 deny byteReadsZeroExtend.  The cogit will clear the register before hand if necessary."
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	self machineCodeBuffer at: 0 put: (self rexR: destReg x: 0 b: srcReg).
	self machineCodeBuffer at: 1 put: 16r8A.
	(srcReg ~= RSP and: [srcReg ~= R12]) ifTrue:
		[(offset = 0 and: [srcReg ~= RBP and: [srcReg ~= R13]]) ifTrue:
			[self machineCodeBuffer
				at: 2 put: (self mod: ModRegInd RM: srcReg RO: destReg).
			 ^3].
		(self isQuick: offset) ifTrue:
			[self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
			 self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
			 ^4].
		self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
		self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 4 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^7].
	"RSP:"
	offset = 0 ifTrue:
		[self machineCodeBuffer at: 2 put: (self mod: ModRegInd RM: srcReg RO: destReg).
		 self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: srcReg).
		 ^4].
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
		 self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: srcReg).
		 self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
		 ^5].
	self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
	self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: srcReg).
	self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 put: (offset >> 24 bitAnd: 16rFF).
	^8! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveMwrR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	self machineCodeBuffer at: 0 put: (self rexR: destReg x: 0 b: srcReg).
	self machineCodeBuffer at: 1 put: 16r8B.
	(srcReg ~= RSP and: [srcReg ~= R12]) ifTrue:
		[(offset = 0 and: [srcReg ~= RBP and: [srcReg ~= R13]]) ifTrue:
			[self machineCodeBuffer
				at: 2 put: (self mod: ModRegInd RM: srcReg RO: destReg).
			 ^3].
		(self isQuick: offset) ifTrue:
			[self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
			 self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
			 ^4].
		self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
		self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 4 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^7].
	"RSP:"
	offset = 0 ifTrue:
		[self machineCodeBuffer at: 2 put: (self mod: ModRegInd RM: srcReg RO: destReg).
		 self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: srcReg).
		 ^4].
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
		 self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: srcReg).
		 self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
		 ^5].
	self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
	self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: srcReg).
	self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 put: (offset >> 24 bitAnd: 16rFF).
	^8! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMovePerfCnt64RL
	"Generate code for
		0x0: 50					pushq	%rax
		0x1: 52					pushq	%rdx
		0x2: 0f 31				rdtsc
		0x4: 48 c1 e2 20		shlq	$0x20, %rdx
		0x8: 48 09 d0			orq		%rdx, %rax
		0xb: 48 89 f8			movq	%rdi, %rax
		0xe: 5a					popq	%rdx
		0xf: 58					popq	%rax
	 et al"
	| reg liveRegisterMask offset |
	reg := operands at: 0.
	liveRegisterMask := operands at: 1.
	offset := 0.
	(liveRegisterMask anyMask: (cogit registerMaskFor: RAX)) ifTrue:
		[self machineCodeBuffer at: 0 put: 16r50. "push %rax"
		 offset := offset + 1].
	(liveRegisterMask anyMask: (cogit registerMaskFor: RDX)) ifTrue:
		[self machineCodeBuffer at: offset put: 16r52. "push %rdx"
		 offset := offset + 1].
	"too lazy to define the swap cases for the moment..."
	self deny: reg = RDX.
	self machineCodeBuffer at: offset		put: 16r0F. "rdtsc"
	self machineCodeBuffer at: offset + 1	put: 16r31.
	self machineCodeBuffer at: offset + 2	put: (self rexR: 0 x: 0 b: RDX). "shlq   $0x20, %rdx"
	self machineCodeBuffer at: offset + 3	put: 16rC1.
	self machineCodeBuffer at: offset + 4	put: (self mod: ModReg RM: RDX RO: 4).
	self machineCodeBuffer at: offset + 5	put: 32.
	self machineCodeBuffer at: offset + 6	put: (self rexR: RAX x: 0 b: RDX). "orq 	%rax, %rdx (%rax := %rax bitOr: %rdx"
	self machineCodeBuffer at: offset + 7	put: 16r0B.
	self machineCodeBuffer at: offset + 8	put: (self mod: ModReg RM: RDX RO: RAX).
	offset := offset + 9.
	reg ~= RAX ifTrue:
		[self machineCodeBuffer at: offset put: (self rexR: RAX x: 0 b: reg). "movq	%rDEST, %rax"
		 self machineCodeBuffer at: offset + 1 put: 16r89.
		 self machineCodeBuffer at: offset + 2 put: (self mod: ModReg RM: reg RO: RAX).
		 offset := offset + 3].
	(liveRegisterMask anyMask: (cogit registerMaskFor: RDX)) ifTrue:
		[self machineCodeBuffer at: offset put: 16r5A. "pop %rdx"
		 offset := offset + 1].
	(liveRegisterMask anyMask: (cogit registerMaskFor: RAX)) ifTrue:
		[self machineCodeBuffer at: offset put: 16r58. "pop %rax"
		 offset := offset + 1].
	^offset

	"{	cogit processor disassembleInstructionAt: 0 In: machineCode object.
		cogit processor disassembleInstructionAt: 2 In: machineCode object.
		cogit processor disassembleInstructionAt: 6 In: machineCode object.
		cogit processor disassembleInstructionAt: 9 In: machineCode object }"! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRA32
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg offset |
	reg := operands at: 0.
	addressOperand := operands at: 1.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	reg = RAX
		ifTrue: [offset := 0]
		ifFalse:
			[self machineCodeBuffer at: 0 put: (self rexR: 0 x: 0 b: reg).
			 self machineCodeBuffer at: 1 put: 16r90 + (reg \\ 8).
			 offset := 2].
	self machineCodeBuffer at: 0 + offset put: 16rA3.
	self machineCodeBuffer at: 1 + offset put: (addressOperand bitAnd: 16rFF).
	self machineCodeBuffer at: 2 + offset put: (addressOperand >>   8 bitAnd: 16rFF).
	self machineCodeBuffer at: 3 + offset put: (addressOperand >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 + offset put: (addressOperand >> 24 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 + offset put: (addressOperand >> 32 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 + offset put: (addressOperand >> 40 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 + offset put: (addressOperand >> 48 bitAnd: 16rFF).
	self machineCodeBuffer at: 8 + offset put: (addressOperand >> 56 bitAnd: 16rFF).
	reg = RAX ifTrue:
		[^9].
	self machineCodeBuffer at: 11 put: (self machineCodeBuffer at: 0).
	self machineCodeBuffer at: 12 put: (self machineCodeBuffer at: 1).
	^13! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRAb
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg offset save1 savedSize |
	reg := operands at: 0.
	addressOperand := operands at: 1.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	(self isAddressRelativeToVarBase: addressOperand) ifTrue:
		[save1 := operands at: 1.
		 operands
			at: 1 put: addressOperand - cogit varBaseAddress;
			at: 2 put: RBX.
		 savedSize := self concretizeMoveRMbr.
		 operands
			at: 1 put: save1;
			at: 2 put: 0.
		^savedSize].
	reg = RAX
		ifTrue: [offset := 0]
		ifFalse:
			[self machineCodeBuffer at: 0 put: (self rexR: 0 x: 0 b: reg).
			 self machineCodeBuffer at: 1 put: 16r90 + (reg \\ 8).
			 offset := 2].
	self machineCodeBuffer at: 0 + offset put: 16r48.
	self machineCodeBuffer at: 1 + offset put: 16rA2.
	self machineCodeBuffer at: 2 + offset put: (addressOperand bitAnd: 16rFF).
	self machineCodeBuffer at: 3 + offset put: (addressOperand >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 + offset put: (addressOperand >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 + offset put: (addressOperand >> 24 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 + offset put: (addressOperand >> 32 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 + offset put: (addressOperand >> 40 bitAnd: 16rFF).
	self machineCodeBuffer at: 8 + offset put: (addressOperand >> 48 bitAnd: 16rFF).
	self machineCodeBuffer at: 9 + offset put: (addressOperand >> 56 bitAnd: 16rFF).
	reg = RAX ifTrue:
		[^10].
	self machineCodeBuffer at: 12 put: (self machineCodeBuffer at: 0).
	self machineCodeBuffer at: 13 put: (self machineCodeBuffer at: 1).
	^14! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRAw
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg offset save1 savedSize |
	reg := operands at: 0.
	addressOperand := operands at: 1.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	(self isAddressRelativeToVarBase: addressOperand) ifTrue:
		[save1 := operands at: 1.
		 operands
			at: 1 put: addressOperand - cogit varBaseAddress;
			at: 2 put: RBX.
		 savedSize := self concretizeMoveRMwr.
		 operands
			at: 1 put: save1;
			at: 2 put: 0.
		^savedSize].
	"If storing RAX, store directly, otherwise, because of instruction encoding limitations, the register
	 _must_ be stored through RAX.  If reg = RBP or RSP simply store directly, otherwise swap RAX with
	 the register before and after the store through RAX.  We avoid swapping before hand with RBP
	 and RSP because setting RSP to whatever the contents of RAX is can cause disastrous results if
	 an interrupt is delivered immediately after that point.  See mail threads beginning with
		http://lists.squeakfoundation.org/pipermail/vm-dev/2019-September/031428.html
		http://lists.squeakfoundation.org/pipermail/vm-dev/2019-October/031499.html"
	(reg = RAX or: [reg = RBP or: [reg = RSP]])
		ifTrue: [offset := 0]
		ifFalse:
			[(reg = RBP or: [reg = RSP])
				ifTrue:
					[self machineCodeBuffer at: 0 put: (self rexR: reg x: 0 b: RAX).
					 self machineCodeBuffer at: 1 put: 16r89.
					 self machineCodeBuffer at: 2 put: (self mod: ModReg RM: RAX RO: reg).
					 offset := 3]
				ifFalse:
					[self machineCodeBuffer at: 0 put: (self rexR: RAX x: 0 b: reg).
					 self machineCodeBuffer at: 1 put: 16r90 + (reg \\ 8).
					 offset := 2]].
	self machineCodeBuffer at: 0 + offset put: 16r48.
	self machineCodeBuffer at: 1 + offset put: 16rA3.
	self machineCodeBuffer at: 2 + offset put: (addressOperand bitAnd: 16rFF).
	self machineCodeBuffer at: 3 + offset put: (addressOperand >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 + offset put: (addressOperand >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 + offset put: (addressOperand >> 24 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 + offset put: (addressOperand >> 32 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 + offset put: (addressOperand >> 40 bitAnd: 16rFF).
	self machineCodeBuffer at: 8 + offset put: (addressOperand >> 48 bitAnd: 16rFF).
	self machineCodeBuffer at: 9 + offset put: (addressOperand >> 56 bitAnd: 16rFF).
	reg = RAX ifTrue:
		[^10].
	(reg = RBP or: [reg = RSP]) ifTrue:
		[^13].
	"Now effect the assignment via xchg, which restores RAX"
	self machineCodeBuffer at: 12 put: (self machineCodeBuffer at: 0).
	self machineCodeBuffer at: 13 put: (self machineCodeBuffer at: 1).
	^14! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRM16r
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg skip |
	srcReg := operands at: 0.
	offset := operands at: 1.
	destReg := operands at: 2.
	self machineCodeBuffer at: 0 put: 16r66.
	(srcReg > 7 or: [destReg > 7])
		ifTrue:
			[self machineCodeBuffer at: 1 put: (self rexw: false r: srcReg x: 0 b: destReg).
			 skip := 1]
		ifFalse:
			[skip := 0].
	(destReg bitAnd: 7) ~= RSP ifTrue:
		[(self isQuick: offset) ifTrue:
			[self machineCodeBuffer at: skip + 1 put: 16r89.
			 self machineCodeBuffer at: skip + 2 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
			 self machineCodeBuffer at: skip + 3 put: (offset bitAnd: 16rFF).
			 ^skip + 4].
		self machineCodeBuffer at: skip + 1 put: 16r89.
		self machineCodeBuffer at: skip + 2 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
		self machineCodeBuffer at: skip + 3 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: skip + 4 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: skip + 5 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: skip + 6 put: (offset >> 24 bitAnd: 16rFF).
		^skip + 7].
	"RSP:"
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: skip + 1 put: 16r89.
		 self machineCodeBuffer at: skip + 2 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
		 self machineCodeBuffer at: skip + 3 put: (self s: SIB1 i: 4 b: destReg).
		 self machineCodeBuffer at: skip + 4 put: (offset bitAnd: 16rFF).
		 ^skip + 5].
	self machineCodeBuffer at: skip + 1 put: 16r89.
	self machineCodeBuffer at: skip + 2 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
	self machineCodeBuffer at: skip + 3 put: (self s: SIB1 i: 4 b: destReg).
	self machineCodeBuffer at: skip + 4 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 5 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 6 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 7 put: (offset >> 24 bitAnd: 16rFF).
	^skip + 8! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRM32r
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| offset srcReg destReg skip |
	srcReg := operands at: 0.
	offset := operands at: 1.
	destReg := operands at: 2.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [skip := 1. self machineCodeBuffer at: 0 put: (self rexw: false r: srcReg x: 0 b: destReg)].
	self machineCodeBuffer
		at: skip + 0 put: 16r89.
	offset = 0 ifTrue:
		[(destReg bitAnd: 6) ~= RSP ifTrue:
			[self machineCodeBuffer at: skip + 1 put: (self mod: ModRegInd RM: destReg RO: srcReg).
			 ^skip + 2].
		 (destReg bitAnd: 7) = RSP ifTrue: "RBP & R13 fall through"
			[self machineCodeBuffer at: skip + 1 put: (self mod: ModRegInd RM: destReg RO: srcReg).
			 self machineCodeBuffer at: skip + 2 put: (self s: SIB1 i: 4 b: destReg).
			 ^skip + 3]].
	(self isQuick: offset) ifTrue:
		[(destReg bitAnd: 7) ~= RSP ifTrue:
			[self machineCodeBuffer at: skip + 1 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
			 self machineCodeBuffer at: skip + 2 put: (offset bitAnd: 16rFF).
			 ^skip + 3].
		 self machineCodeBuffer at: skip + 1 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
		 self machineCodeBuffer at: skip + 2 put: (self s: SIB1 i: 4 b: destReg).
		 self machineCodeBuffer at: skip + 3 put: (offset bitAnd: 16rFF).
		 ^skip + 4].
	self machineCodeBuffer at: skip + 1 put: (self mod: ModRegRegDisp32  RM: destReg RO: srcReg).
	(destReg bitAnd: 7) = RSP ifTrue:
		[self machineCodeBuffer at: skip + 2 put: (self s: SIB1 i: 4 b: destReg).
		 skip := skip + 1].
	self machineCodeBuffer at: skip + 2 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 3 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 4 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 5 put: (offset >> 24 bitAnd: 16rFF).
	^skip + 6! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRMbr
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset baseReg |
	srcReg := operands at: 0.
	offset := operands at: 1.
	baseReg := operands at: 2.
	self machineCodeBuffer at: 0 put: (self rexR: srcReg x: 0 b: baseReg).
	self machineCodeBuffer at: 1 put: 16r88.
	(baseReg ~= RSP and: [baseReg ~= R12]) ifTrue:
		[(offset = 0 and: [baseReg ~= RBP and: [baseReg ~= R13]]) ifTrue:
			[self machineCodeBuffer
				at: 2 put: (self mod: ModRegInd RM: baseReg RO: srcReg).
			 ^3].
		 (self isQuick: offset) ifTrue:
			[self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: baseReg RO: srcReg).
			 self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
			 ^4].
		self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp32 RM: baseReg RO: srcReg).
		self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 4 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^7].
	"RSP:"
	offset = 0 ifTrue:
		[self machineCodeBuffer at: 2 put: (self mod: ModRegInd RM: baseReg RO: srcReg).
		 self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: baseReg).
		 ^4].
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: baseReg RO: srcReg).
		 self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: baseReg).
		 self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
		 ^5].
	self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp32 RM: baseReg RO: srcReg).
	self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: baseReg).
	self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 put: (offset >> 24 bitAnd: 16rFF).
	^8! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRMwr
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	srcReg := operands at: 0.
	offset := operands at: 1.
	destReg := operands at: 2.
	self machineCodeBuffer at: 0 put: (self rexR: srcReg x: 0 b: destReg).
	self machineCodeBuffer at: 1 put: 16r89.
	(destReg ~= RSP and: [destReg ~= R12]) ifTrue:
		[(offset = 0 and: [destReg ~= RBP and: [destReg ~= R13]]) ifTrue:
			[self machineCodeBuffer
				at: 2 put: (self mod: ModRegInd RM: destReg RO: srcReg).
			 ^3].
		 (self isQuick: offset) ifTrue:
			[self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
			 self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
			 ^4].
		self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
		self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 4 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^7].
	"RSP:"
	offset = 0 ifTrue:
		[self machineCodeBuffer at: 2 put: (self mod: ModRegInd RM: destReg RO: srcReg).
		 self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: destReg).
		 ^4].
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
		 self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: destReg).
		 self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
		 ^5].
	self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
	self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: destReg).
	self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 put: (offset >> 24 bitAnd: 16rFF).
	^8! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRRd
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: 16r66.
	self machineCodeBuffer at: 1 put: (self rexR: destReg x: 0 b: srcReg).
	self machineCodeBuffer at: 2 put: 16r0f.
	self machineCodeBuffer at: 3 put: 16r6e.
	self machineCodeBuffer at: 4 put: (self mod: ModReg RM: srcReg RO: destReg).
	^5! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRX32rR
	| index base src offset |
	src := operands at: 0.
	index := operands at: 1.
	base := operands at: 2.
	(index > 7 or: [base > 7 or: [src > 7]])
		ifTrue:
			[self machineCodeBuffer at: 0 put: (self rexw: false r: src x: index b: base).
			 offset := 1]
		ifFalse:
			[offset := 0].
	(base bitAnd: 7) ~= RBP ifTrue:
		[self machineCodeBuffer at: offset + 0 put: 16r89.
		 self machineCodeBuffer at: offset + 1 put: (self mod: ModRegInd RM: 4 RO: src).
		 self machineCodeBuffer at: offset + 2 put: (self s: SIB4 i: index b: base).
		 ^offset + 3].
	self machineCodeBuffer at: offset + 0 put: 16r89.
	self machineCodeBuffer at: offset + 1 put: (self mod: ModRegRegDisp8 RM: 4 RO: src).
	self machineCodeBuffer at: offset + 2 put: (self s: SIB4 i: index b: base).
	self machineCodeBuffer at: offset + 3 put: 0.
	 ^offset + 4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRXbrR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| src index base offset |
	src := operands at: 0.
	index := operands at: 1.
	base := operands at: 2.
	offset := 0.
	(src > 3 or: [base > 7 or: [index > 7]]) ifTrue:
		[self machineCodeBuffer at: 0 put: (self rexR: src x: index b: base).
		 offset := 1].
	self machineCodeBuffer at: 0 + offset put: 16r88.
	(base bitAnd: 7) ~= RBP "RBP,R13" ifTrue:
		[self machineCodeBuffer at: 1 + offset put: (self mod: ModRegInd RM: 4 RO: src).
		 self machineCodeBuffer at: 2 + offset put: (self s: SIB1 i: index b: base).
		 ^3 + offset].
	self machineCodeBuffer at: 1 + offset put: (self mod: ModRegRegDisp8 RM: 4 RO: src).
	self machineCodeBuffer at: 2 + offset put: (self s: SIB1 i: index b: base).
	self machineCodeBuffer at: 3 + offset put: 0.
	 ^4 + offset! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRXwrR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| index base src |
	src := operands at: 0.
	index := operands at: 1.
	base := operands at: 2.
	self machineCodeBuffer
		at: 0 put: (self rexR: src x: index b: base).
	(base ~= RBP and: [base ~= R13]) ifTrue:
		[self machineCodeBuffer at: 1 put: 16r89.
		 self machineCodeBuffer at: 2 put: (self mod: ModRegInd RM: 4 RO: src).
		 self machineCodeBuffer at: 3 put: (self s: SIB8 i: index b: base).
		 ^4].
	self machineCodeBuffer at: 1 put: 16r89.
	self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: 4 RO: src).
	self machineCodeBuffer at: 3 put: (self s: SIB8 i: index b: base).
	self machineCodeBuffer at: 4 put: 0.
	 ^5! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRdM64r
	<inline: true>
	| offset srcReg destReg skip |
	srcReg := operands at: 0.
	offset := operands at: 1.
	destReg := operands at: 2.
	self machineCodeBuffer at: 0 put: 16r66.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [self machineCodeBuffer at: (skip := 1) put: (self rexw: false r: srcReg x: 0 b: destReg)].
	self machineCodeBuffer at: skip + 1 put: 16r0f.
	self machineCodeBuffer at: skip + 2 put: 16rd6.
	offset = 0 ifTrue:
		[(destReg bitAnd: 6) ~= RSP ifTrue:
			[self machineCodeBuffer at: skip + 3 put: (self mod: ModRegInd RM: destReg RO: srcReg).
			 ^skip + 4].
		 (destReg bitAnd: 7) = RSP ifTrue: "RBP & R13 fall through"
			[self machineCodeBuffer at: skip + 3 put: (self mod: ModRegInd RM: destReg RO: srcReg).
			 self machineCodeBuffer at: skip + 4 put: (self s: SIB1 i: 4 b: destReg).
			 ^skip + 5]].
	(self isQuick: offset) ifTrue:
		[(destReg bitAnd: 7) ~= RSP ifTrue:
			[self machineCodeBuffer at: skip + 3 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
			 self machineCodeBuffer at: skip + 4 put: (offset bitAnd: 16rFF).
			 ^skip + 5].
		 self machineCodeBuffer at: skip + 3 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
		 self machineCodeBuffer at: skip + 4 put: (self s: SIB1 i: 4 b: destReg).
		 self machineCodeBuffer at: skip + 5 put: (offset bitAnd: 16rFF).
		 ^skip + 6].
	self machineCodeBuffer at: skip + 3 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
	(destReg bitAnd: 7) = RSP ifTrue:
		[self machineCodeBuffer at: skip + 4 put: (self s: SIB1 i: 4 b: destReg).
		 skip := skip + 1].
	self machineCodeBuffer at: skip + 4 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 5 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 6 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 7 put: (offset >> 24 bitAnd: 16rFF).
	^skip + 8! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRdR
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: 16r66.
	self machineCodeBuffer at: 1 put: (self rexR: srcReg x: 0 b: destReg).
	self machineCodeBuffer at: 2 put: 16r0f.
	self machineCodeBuffer at: 3 put: 16r7e.
	self machineCodeBuffer at: 4 put: (self mod: ModReg RM: destReg RO: srcReg).
	^5! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRdRd
	"Will get inlined into concretizeAt: switch."
	"MOVSD"
	<inline: true>
	| srcReg destReg skip |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer
		at: 0 put: 16rF2.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [self machineCodeBuffer at: (skip := 1) put: (self rexw: false r: srcReg x: 0 b: destReg)].
	self machineCodeBuffer at: skip + 1 put: 16r0F.
	self machineCodeBuffer at: skip + 2 put: 16r11.
	self machineCodeBuffer at: skip + 3 put: (self mod: ModReg RM: destReg RO: srcReg).
	^skip + 4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRsM32r
	<inline: true>
	| offset srcReg destReg skip |
	srcReg := operands at: 0.
	offset := operands at: 1.
	destReg := operands at: 2.
	self machineCodeBuffer at: 0 put: 16r66.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [self machineCodeBuffer at: (skip := 1) put: (self rexw: false r: srcReg x: 0 b: destReg)].
	self machineCodeBuffer at: skip + 1 put: 16r0f.
	self machineCodeBuffer at: skip + 2 put: 16r7e.
	offset = 0 ifTrue:
		[(destReg bitAnd: 6) ~= RSP ifTrue:
			[self machineCodeBuffer at: skip + 3 put: (self mod: ModRegInd RM: destReg RO: srcReg).
			 ^skip + 4].
		 (destReg bitAnd: 7) = RSP ifTrue: "RBP & R13 fall through"
			[self machineCodeBuffer at: skip + 3 put: (self mod: ModRegInd RM: destReg RO: srcReg).
			 self machineCodeBuffer at: skip + 4 put: (self s: SIB1 i: 4 b: destReg).
			 ^skip + 5]].
	(self isQuick: offset) ifTrue:
		[(destReg bitAnd: 7) ~= RSP ifTrue:
			[self machineCodeBuffer at: skip + 3 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
			 self machineCodeBuffer at: skip + 4 put: (offset bitAnd: 16rFF).
			 ^skip + 5].
		 self machineCodeBuffer at: skip + 3 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
		 self machineCodeBuffer at: skip + 4 put: (self s: SIB1 i: 4 b: destReg).
		 self machineCodeBuffer at: skip + 5 put: (offset bitAnd: 16rFF).
		 ^skip + 6].
	self machineCodeBuffer at: skip + 3 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
	(destReg bitAnd: 7) = RSP ifTrue:
		[self machineCodeBuffer at: skip + 4 put: (self s: SIB1 i: 4 b: destReg).
		 skip := skip + 1].
	self machineCodeBuffer at: skip + 4 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 5 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 6 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: skip + 7 put: (offset >> 24 bitAnd: 16rFF).
	^skip + 8! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRsRs
	"Will get inlined into concretizeAt: switch."
	"MOVSS"
	<inline: true>
	| srcReg destReg skip |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer
		at: 0 put: 16rF3.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [self machineCodeBuffer at: (skip := 1) put: (self rexw: false r: srcReg x: 0 b: destReg)].
	self machineCodeBuffer at: skip + 1 put: 16r0F.
	self machineCodeBuffer at: skip + 2 put: 16r11.
	self machineCodeBuffer at: skip + 3 put: (self mod: ModReg RM: destReg RO: srcReg).
	^skip + 4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveX32rRR
	"MoveX32rRR is expected to zero-extend, so explicitly zero the destination."
	| index base dest offset |
	index := operands at: 0.
	base := operands at: 1.
	dest := operands at: 2.
	self machineCodeBuffer at: 0 put: (self rexR: dest x: 0 b: dest).
	self machineCodeBuffer at: 1 put: 16r31.
	self machineCodeBuffer at: 2 put: (self mod: ModReg RM: dest RO: dest).
	(index > 7 or: [base > 7 or: [dest > 7]])
		ifTrue:
			[self machineCodeBuffer at: 3 put: (self rexw: false r: dest x: index b: base).
			 offset := 1]
		ifFalse:
			[offset := 0].
	(base bitAnd: 7) ~= RBP ifTrue:
		[self machineCodeBuffer at: offset + 3 put: 16r8B.
		 self machineCodeBuffer at: offset + 4 put: (self mod: ModRegInd RM: 4 RO: dest).
		 self machineCodeBuffer at: offset + 5 put: (self s: SIB4 i: index b: base).
		 ^offset + 6].
	self machineCodeBuffer at: offset + 3 put: 16r8B.
	self machineCodeBuffer at: offset + 4 put: (self mod: ModRegRegDisp8 RM: 4 RO: dest).
	self machineCodeBuffer at: offset + 5 put: (self s: SIB4 i: index b: base).
	self machineCodeBuffer at: offset + 6 put: 0.
	 ^offset + 7! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveXbrRR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| index base dest |
	index := operands at: 0.
	base := operands at: 1.
	dest := operands at: 2.
	self machineCodeBuffer at: 0 put: (self rexR: dest x: index b: base).
	self machineCodeBuffer at: 1 put: 16r8A.
	(base ~= RBP and: [base ~= R13]) ifTrue:
		[self machineCodeBuffer at: 2 put: (self mod: ModRegInd RM: 4 RO: dest).
		 self machineCodeBuffer at: 3 put: (self s: SIB1 i: index b: base).
		 ^4].
	self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: 4 RO: dest).
	self machineCodeBuffer at: 3 put: (self s: SIB1 i: index b: base).
	self machineCodeBuffer at: 4 put: 0.
	 ^5! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveXwrRR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| index base dest |
	index := operands at: 0.
	base := operands at: 1.
	dest := operands at: 2.
	self machineCodeBuffer
		at: 0 put: (self rexR: dest x: index b: base).
	(base ~= RBP and: [base ~= R13]) ifTrue:
		[self machineCodeBuffer at: 1 put: 16r8B.
		 self machineCodeBuffer at: 2 put: (self mod: ModRegInd RM: 4 RO: dest).
		 self machineCodeBuffer at: 3 put: (self s: SIB8 i: index b: base).
		 ^4].
	self machineCodeBuffer at: 1 put: 16r8B.
	self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: 4 RO: dest).
	self machineCodeBuffer at: 3 put: (self s: SIB8 i: index b: base).
	self machineCodeBuffer at: 4 put: 0.
	 ^5! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMulRR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg1 reg2 |
	reg1 := operands at: 0.
	reg2 := operands at: 1.
	self machineCodeBuffer at: 0 put: (self rexR: reg2 x: 0 b: reg1).
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16rAF.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: reg1 RO: reg2).
	^4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeNegateR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg |
	reg := operands at: 0.
	self machineCodeBuffer at: 0 put: (self rexR: 0 x: 0 b: reg).
	self machineCodeBuffer at: 1 put: 16rF7.
	self machineCodeBuffer at: 2 put: (self mod: ModReg RM: reg RO: 3).
	^3! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeNop
	<inline: true>
	self machineCodeBuffer at: 0 put: 16r90.
	^1! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeOpRR: x64opcode
	| regLHS regRHS |
	regLHS := operands at: 0.
	regRHS := operands at: 1.
	self machineCodeBuffer at: 0 put: (self rexR: regRHS x: 0 b: regLHS).
	self machineCodeBuffer at: 1 put: x64opcode.
	self machineCodeBuffer at: 2 put: (self mod: ModReg RM: regLHS RO: regRHS).
	^3! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizePopR
	<inline: true>
	| reg |
	reg := operands at: 0.
	reg < 8 ifTrue:
		[self machineCodeBuffer at: 0 put: 16r58 + reg.
		^1].
	self machineCodeBuffer at: 0 put: 16r41.
	self machineCodeBuffer at: 1 put: 16r58 + (reg - 8).
	^2! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizePrefetchAw
	"We support only prefetches for addresses that are variables relative to VarBase"
	| operand offset |
	operand := operands at: 0.
	(self isAddressRelativeToVarBase: operand) ifFalse:
		[^0].
	offset := operand - cogit varBaseAddress.
	self machineCodeBuffer at: 0 put: 16r0f.
	self machineCodeBuffer at: 1 put: 16r18.
	self machineCodeBuffer at: 2 put: 16r93.
	self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: offset >> 24.
	^7! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizePushCq
	<inline: true>
	| value |
	value := operands at: 0.
	(self isQuick: value) ifTrue:
		[self machineCodeBuffer at: 0 put: 16r6A.
		 self machineCodeBuffer at: 1 put: (value bitAnd: 16rFF).
		^2].
	(self is32BitSignedImmediate: value) ifTrue:
		[self machineCodeBuffer at: 0 put: 16r68.
		 self machineCodeBuffer at: 1 put: (value bitAnd: 16rFF).
		 self machineCodeBuffer at: 2 put: (value >> 8 bitAnd: 16rFF).
		 self machineCodeBuffer at: 3 put: (value >> 16 bitAnd: 16rFF).
		 self machineCodeBuffer at: 4 put: (value >> 24 bitAnd: 16rFF).
		^5].
	^self concretizePushCw! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizePushR
	<inline: true>
	| reg |
	reg := operands at: 0.
	reg < 8 ifTrue:
		[self machineCodeBuffer at: 0 put: 16r50 + reg.
		^1].
	self machineCodeBuffer at: 0 put: 16r41.
	self machineCodeBuffer at: 1 put: 16r50 + (reg - 8).
	^2! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeRetN
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| offset |
	offset := operands at: 0.
	offset = 0 ifTrue:
		[self machineCodeBuffer at: 0 put: 16rC3.
		^1].
	self machineCodeBuffer at: 0 put: 16rC2.
	self machineCodeBuffer at: 1 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 2 put: (offset >> 8).
	^3! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeReverseOpRR: x64opcode
	| regLHS regRHS |
	"CmpRR/MoveRR RHS LHS computes LHS - RHS, i.e. apparently reversed.  You have to think subtract."
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	self machineCodeBuffer at: 0 put: (self rexR: regRHS x: 0 b: regLHS).
	self machineCodeBuffer at: 1 put: x64opcode.
	self machineCodeBuffer at: 2 put: (self mod: ModReg RM: regLHS RO: regRHS).
	^3! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeSEE2OpRdRd: x64opcode
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS skip |
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	self machineCodeBuffer
		at: 0 put: 16rF2.
	(regLHS <= 7 and: [regRHS <= 7])
		ifTrue: [skip := 0]
		ifFalse: [self machineCodeBuffer at: (skip := 1) put: (self rexw: false r: regLHS x: 0 b: regRHS)].
	self machineCodeBuffer at: skip + 1 put: 16r0F.
	self machineCodeBuffer at: skip + 2 put: x64opcode.
	self machineCodeBuffer at: skip + 3 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^skip + 4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeSEEOpRsRs: x64opcode
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS skip |
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	self machineCodeBuffer
		at: 0 put: 16rF3.
	(regLHS <= 7 and: [regRHS <= 7])
		ifTrue: [skip := 0]
		ifFalse: [self machineCodeBuffer at: (skip := 1) put: (self rexw: false r: regLHS x: 0 b: regRHS)].
	self machineCodeBuffer at: skip + 1 put: 16r0F.
	self machineCodeBuffer at: skip + 2 put: x64opcode.
	self machineCodeBuffer at: skip + 3 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^skip + 4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeShiftCqRegOpcode: regOpcode
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| distance reg |
	distance := operands at: 0.
	self assert: (distance between: 1 and: 63).
	reg := operands at: 1.
	self machineCodeBuffer at: 0 put: (self rexR: 0 x: 0 b: reg).
	distance = 1 ifTrue:
		[self machineCodeBuffer at: 1 put: 16rD1.
		 self machineCodeBuffer at: 2 put: (self mod: ModReg RM: reg RO: regOpcode).
		 ^3].
	self machineCodeBuffer at: 1 put: 16rC1.
	self machineCodeBuffer at: 2 put: (self mod: ModReg RM: reg RO: regOpcode).
	self machineCodeBuffer at: 3 put: distance.
	^4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeShiftRegRegOpcode: regOpcode
	"On the x64 the only instructions that shift by the value of a
	 register require the shift count to be  in %ecx.  So we may
	 have to use swap instructions to get the count into %ecx."
	<inline: true>
	| shiftCountReg destReg regToShift |
	shiftCountReg := operands at: 0.
	destReg := operands at: 1.
	shiftCountReg = RCX ifTrue:
		[self machineCodeBuffer at: 0 put: (self rexR: 0 x: 0 b: destReg).
		 self machineCodeBuffer at: 1 put: 16rD3.
		 self machineCodeBuffer at: 2 put: (self mod: ModReg RM: destReg RO: regOpcode).
		 ^3].
	regToShift := destReg = shiftCountReg
					ifTrue: [RCX]
					ifFalse: [destReg = RCX
								ifTrue: [shiftCountReg]
								ifFalse: [destReg]].
	shiftCountReg = RAX ifTrue:
		[self machineCodeBuffer at: 0 put: 16r48.
		 self machineCodeBuffer at: 1 put: 16r90 + RCX. "XCHG RAX,RCX"
		 self machineCodeBuffer at: 2 put: (self rexR: 0 x: 0 b: regToShift).
		 self machineCodeBuffer at: 3 put: 16rD3. "SAR RCX,RAX"
		 self machineCodeBuffer at: 4 put: (self mod: ModReg RM: regToShift RO: regOpcode).
		 self machineCodeBuffer at: 5 put: 16r48.
		 self machineCodeBuffer at: 6 put: 16r90 + RCX. "XCHG RAX,RCX"
		 ^7].
	self machineCodeBuffer at: 0 put: (self rexR: shiftCountReg x: 0 b: RCX). "XCHG R?X,RCX"
	self machineCodeBuffer at: 1 put: 16r87.
	self machineCodeBuffer at: 2 put: (self mod: ModReg RM: RCX RO: shiftCountReg).
	self machineCodeBuffer at: 3 put: (self rexR: 0 x: 0 b: regToShift). "SAR RCX,R!!X"
	self machineCodeBuffer at: 4 put: 16rD3.
	self machineCodeBuffer at: 5 put: (self mod: ModReg RM: regToShift RO: regOpcode).
	self machineCodeBuffer at: 6 put: (self rexR: shiftCountReg x: 0 b: RCX). "XCHG R?X,RCX"
	self machineCodeBuffer at: 7 put: 16r87.
	self machineCodeBuffer at: 8 put: (self mod: ModReg RM: RCX RO: shiftCountReg).
	^9! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeSignExtend16RR
	"Will get inlined into concretizeAt: switch."
	"movsxwq"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: (self rexw: true r: destReg x: 0 b: srcReg).
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16rBF.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	^ 4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeSignExtend32RR
	"Will get inlined into concretizeAt: switch."
	"movsxdq"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: (self rexw: true r: destReg x: 0 b: srcReg).
	self machineCodeBuffer at: 1 put: 16r63.
	self machineCodeBuffer at: 2 put: (self mod: ModReg RM: srcReg RO: destReg).
	^ 3! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeSignExtend8RR
	"Will get inlined into concretizeAt: switch."
	"movsxbq"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: (self rexw: true r: destReg x: 0 b: srcReg).
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16rBE.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	^ 4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeSqrtRd
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg skip |
	reg := operands at: 0.
	self machineCodeBuffer
		at: 0 put: 16rF2.
	(reg <= 7)
		ifTrue: [skip := 0]
		ifFalse: [self machineCodeBuffer at: (skip := 1) put: (self rexw: false r: reg x: 0 b: reg)].
	self machineCodeBuffer at: skip + 1 put: 16r0F.
	self machineCodeBuffer at: skip + 2 put: 16r51.
	self machineCodeBuffer at: skip + 3 put: (self mod: ModReg RM: reg RO: reg).
	^skip + 4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeSqrtRs
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg skip |
	reg := operands at: 0.
	self machineCodeBuffer
		at: 0 put: 16rF3.
	(reg <= 7)
		ifTrue: [skip := 0]
		ifFalse: [self machineCodeBuffer at: (skip := 1) put: (self rexw: false r: reg x: 0 b: reg)].
	self machineCodeBuffer at: skip + 1 put: 16r0F.
	self machineCodeBuffer at: skip + 2 put: 16r51.
	self machineCodeBuffer at: skip + 3 put: (self mod: ModReg RM: reg RO: reg).
	^skip + 4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeStop
	<inline: true>
	self machineCodeBuffer at: 0 put: 16rCC.
	^1! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeTstCqR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	self machineCodeBuffer
		at: 0 put: (self rexR: 0 x: 0 b: reg).
	(self isQuick: value) ifTrue:
		[self machineCodeBuffer at: 1 put: 16rF6.
		 self machineCodeBuffer at: 2 put: (self mod: ModReg RM: reg RO: 0).
		 self machineCodeBuffer at: 3 put: (value bitAnd: 16rFF).
		 ^4].
	
	(self is32BitSignedImmediate: value) ifTrue:
		[reg = RAX ifTrue:
			[self machineCodeBuffer at: 1 put: 16rA9.
			 self machineCodeBuffer at: 2 put: (value bitAnd: 16rFF).
			 self machineCodeBuffer at: 3 put: (value >> 8 bitAnd: 16rFF).
			 self machineCodeBuffer at: 4 put: (value >> 16 bitAnd: 16rFF).
			 self machineCodeBuffer at: 5 put: (value >> 24 bitAnd: 16rFF).
			 ^6].
		self machineCodeBuffer at: 1 put: 16rF7.
		self machineCodeBuffer at: 2 put: (self mod: ModReg RM: reg RO: 0).
		self machineCodeBuffer at: 3 put: (value bitAnd: 16rFF).
		self machineCodeBuffer at: 4 put: (value >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (value >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 6 put: (value >> 24 bitAnd: 16rFF).
		 ^7].
	^self concretizeArithCwR: 16r85! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeXorRdRd
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS skip |
	regRHS := self operands at: 0.
	regLHS := self operands at: 1.
	self machineCodeBuffer
		at: 0 put: 16r66.
	(regLHS <= 7 and: [regRHS <= 7])
		ifTrue: [skip := 0]
		ifFalse: [self machineCodeBuffer at: (skip := 1) put: (self rexw: false r: regLHS x: 0 b: regRHS)].
	self machineCodeBuffer at: skip + 1 put: 16r0f.
	self machineCodeBuffer at: skip + 2 put: 16r57.
	self machineCodeBuffer at: skip + 3 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^skip + 4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeXorRsRs
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS skip |
	regRHS := self operands at: 0.
	regLHS := self operands at: 1.
	self machineCodeBuffer
		at: 0 put: 16r0F.
	(regLHS <= 7 and: [regRHS <= 7])
		ifTrue: [skip := 0]
		ifFalse: [self machineCodeBuffer at: (skip := 1) put: (self rexw: false r: regLHS x: 0 b: regRHS)].
	
	self machineCodeBuffer at: skip + 1 put: 16r57.
	self machineCodeBuffer at: skip + 2 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^skip + 3! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeZeroExtend16RR
	"Will get inlined into concretizeAt: switch."
	"movzxwq"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: (self rexw: true r: destReg x: 0 b: srcReg).
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16rB7.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	^ 4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeZeroExtend32RR
	"Will get inlined into concretizeAt: switch."
	"movzxbq"
	<inline: true>
	| srcReg destReg skip |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	(srcReg <= 7 and: [destReg <= 7])
		ifTrue: [skip := 0]
		ifFalse: [skip := 1. self machineCodeBuffer at: 0 put: (self rexw: false r: destReg x: 0 b: srcReg)].
		
	self machineCodeBuffer at: skip + 0 put: 16r8b.
	self machineCodeBuffer at: skip + 1 put: (self mod: ModReg RM: srcReg RO: destReg).
	^ skip + 2! !

!CogX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeZeroExtend8RR
	"Will get inlined into concretizeAt: switch."
	"movzxbq"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: (self rexw: true r: destReg x: 0 b: srcReg).
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16rB6.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	^ 4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeBSR
	"Bit Scan Reverse
	First operand is input register (mask)
	Second operand is output register (dest)"
	"BSR"
	<inline: true>
	| dest maskReg |
	maskReg := operands at: 0.
	dest := operands at: 1.
	self machineCodeBuffer at: 0 put: (self rexw: true r: dest x: 0 b: maskReg).
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16rBD.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: maskReg RO: dest).
	 ^4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeCDQ
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	self machineCodeBuffer at: 0 put: 16r48.
	self machineCodeBuffer at: 1 put: 16r99.
	^2! !

!CogX64Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeCLD
	<inline: true>
	self machineCodeBuffer at: 0 put: 16rFC.
	^1! !

!CogX64Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeCMPXCHGRMr
	<inline: true>
	| valueReg addressReg |
	valueReg := operands at: 0.
	addressReg := operands at: 1.
	
		"REX.W + 0F B1/r		CMPXCHG r64"
		self machineCodeBuffer at: 0 put: (self rexR: valueReg x: 0 b: addressReg).
	self machineCodeBuffer at: 1 put: 16r0f.
	self machineCodeBuffer at: 2 put: 16rB1.
	self machineCodeBuffer at: 3 put: (self mod: ModRegInd RM: addressReg RO: valueReg).
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogX64Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeCPUID
	<inline: true>
	self machineCodeBuffer at: 0 put: 16r0F.
	self machineCodeBuffer at: 1 put: 16rA2.
	^2! !

!CogX64Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeIDIVR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regDivisor |
	regDivisor := operands at: 0.
	self machineCodeBuffer at: 0 put: (self rexR: 0 x: 0 b: regDivisor).
	self machineCodeBuffer at: 1 put: 16rF7.
	self machineCodeBuffer at: 2 put: (self mod: ModReg RM: regDivisor RO: 7).
	^3! !

!CogX64Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeMOVSB
	<inline: true>
	self machineCodeBuffer at: 0 put: 16rA4.
	^1! !

!CogX64Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeMOVSQ
	<inline: true>
	self machineCodeBuffer at: 0 put: (self rexw: true r: 0 x: 0 b: 0).
	self machineCodeBuffer at: 1 put: 16rA5.
	^2! !

!CogX64Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRAwNoVBR
	"A version of concretizeMoveRAw tat does not use VarBaseReg."
	<inline: true>
	| addressOperand reg offset |
	reg := operands at: 0.
	addressOperand := operands at: 1.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	"If storing RAX, store directly, otherwise, because of instruction encoding limitations, the register
	 _must_ be stored through RAX.  If reg = RBP or RSP simply store directly, otherwise swap RAX with
	 the register before and after the store through RAX.  We avoid sweapping before hand with RBP
	 and RSP because setting RSP to whatever the contents of RAX is can cause disastrous results if
	 an interrupt is delivered immediately after that point.  See mail threads beginning with
		http://lists.squeakfoundation.org/pipermail/vm-dev/2019-September/031428.html
		http://lists.squeakfoundation.org/pipermail/vm-dev/2019-October/031499.html"
	(reg = RAX or: [reg = RBP or: [reg = RSP]])
		ifTrue: [offset := 0]
		ifFalse:
			[(reg = RBP or: [reg = RSP])
				ifTrue:
					[self machineCodeBuffer at: 0 put: (self rexR: reg x: 0 b: RAX).
					 self machineCodeBuffer at: 1 put: 16r89.
					 self machineCodeBuffer at: 2 put: (self mod: ModReg RM: RAX RO: reg).
					 offset := 3]
				ifFalse:
					[self machineCodeBuffer at: 0 put: (self rexR: RAX x: 0 b: reg).
					 self machineCodeBuffer at: 1 put: 16r90 + (reg \\ 8).
					 offset := 2]].
	self machineCodeBuffer at: 0 + offset put: 16r48.
	self machineCodeBuffer at: 1 + offset put: 16rA3.
	self machineCodeBuffer at: 2 + offset put: (addressOperand bitAnd: 16rFF).
	self machineCodeBuffer at: 3 + offset put: (addressOperand >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 + offset put: (addressOperand >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 + offset put: (addressOperand >> 24 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 + offset put: (addressOperand >> 32 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 + offset put: (addressOperand >> 40 bitAnd: 16rFF).
	self machineCodeBuffer at: 8 + offset put: (addressOperand >> 48 bitAnd: 16rFF).
	self machineCodeBuffer at: 9 + offset put: (addressOperand >> 56 bitAnd: 16rFF).
	reg = RAX ifTrue:
		[^10].
	(reg = RBP or: [reg = RSP]) ifTrue:
		[^13].
	"Now effect the assignment via xchg, which restores RAX"
	self machineCodeBuffer at: 12 put: (self machineCodeBuffer at: 0).
	self machineCodeBuffer at: 13 put: (self machineCodeBuffer at: 1).
	^14! !

!CogX64Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeREP
	<inline: true>
	self machineCodeBuffer at: 0 put: 16rF3.
	^1! !

!CogX64Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeXCHGAwR
	"This is a very limited implementation that assumes RAX is available."
	<inline: true>
	| addressOperand reg scratch |
	addressOperand := operands at: 0.
	reg := operands at: 1.
	scratch := operands at: 2.
	self deny: reg = scratch.
	
		"movq addressOperand, %rscratch"
		self machineCodeBuffer at:  0 put: (self rexR: 0 x: 0 b: scratch).
	self machineCodeBuffer at:  1 put: 16rB8 + (scratch bitAnd: 7).
	self machineCodeBuffer at:  2 put: (addressOperand bitAnd: 16rFF).
	self machineCodeBuffer at:  3 put: (addressOperand >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at:  4 put: (addressOperand >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at:  5 put: (addressOperand >> 24 bitAnd: 16rFF).
	self machineCodeBuffer at:  6 put: (addressOperand >> 32 bitAnd: 16rFF).
	self machineCodeBuffer at:  7 put: (addressOperand >> 40 bitAnd: 16rFF).
	self machineCodeBuffer at:  8 put: (addressOperand >> 48 bitAnd: 16rFF).
	self machineCodeBuffer at:  9 put: (addressOperand >> 56 bitAnd: 16rFF).
		"xchgq %reg, (%rscratch)" "0xf: 49 87 45 00              xchgq  %rax, (%r13)"
		self machineCodeBuffer at: 10 put: (self rexR: reg x: 0 b: scratch).
	self machineCodeBuffer at: 11 put: 16r87.
	self machineCodeBuffer at: 12 put: (self s: SIB1 i: 0 b: scratch).
	"cogit processor disassembleInstructionAt: 0 In: machineCode object."
	"cogit processor disassembleInstructionAt: 10 In: machineCode object"
	^13! !

!CogX64Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeXCHGRR
	| r1 r2 |
	r1 := operands at: 0.
	r2 := operands at: 1.
	r2 = RAX ifTrue:
		[r2 := r1. r1 := RAX].
	r1 = RAX ifTrue:
		[self machineCodeBuffer at: 0 put: (self rexR: 0 x: 0 b: r2).
		 self machineCodeBuffer at: 1 put: 16r90 + (r2 \\ 8).
		 ^2].
	self machineCodeBuffer at: 0 put: (self rexR: r1 x: 0 b: r2).
	self machineCodeBuffer at: 1 put: 16r87.
	self machineCodeBuffer at: 2 put: (self mod: ModReg RM: r2 RO: r1).
	^3! !

!CogInLineLiteralsX64Compiler methodsFor: 'generate machine code' stamp: 'cb 10/26/2026 22:30'!
sizePCDependentInstructionAt: eventualAbsoluteAddress
	"Size a jump and set its address.  The target may be another instruction
	 or an absolute address.  On entry the address inst var holds our virtual
	 address. On exit address is set to eventualAbsoluteAddress, which is
	 where this instruction will be output.  The span of a jump to a following
	 instruction is therefore between that instruction's address and this
	 instruction's address ((which are both still their virtual addresses), but the
	 span of a jump to a preceding instruction or to an absolute address is
	 between that instruction's address (which by now is its eventual absolute
	 address) or absolute address and eventualAbsoluteAddress."

	| target maximumSpan abstractInstruction |
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	opcode = AlignmentNops ifTrue:
		[| alignment |
		 self address: eventualAbsoluteAddress.
		 alignment := operands at: 0.
		 ^machineCodeSize := (eventualAbsoluteAddress + (alignment - 1) bitAnd: alignment negated)
							   - eventualAbsoluteAddress].
	self assert: self isJump.
	target := operands at: 0.
	abstractInstruction := cogit cCoerceSimple: target to: #'AbstractInstruction *'.
	(self isAnInstruction: abstractInstruction)
		ifTrue:
			[maximumSpan := abstractInstruction address
							- (((cogit abstractInstruction: self follows: abstractInstruction)
								ifTrue: [eventualAbsoluteAddress]
								ifFalse: [self address]) + 2)]
		ifFalse:
			[maximumSpan := target - (eventualAbsoluteAddress + 2)].
	self address: eventualAbsoluteAddress.
	opcode >= FirstShortJump
		ifTrue:
			[machineCodeSize := (self isQuick: maximumSpan)
									ifTrue: [2]
									ifFalse: [opcode = Jump
												ifTrue: [5]
												ifFalse: [6]]]
		ifFalse:
			[machineCodeSize := opcode caseOf:
									{	[JumpLong]				->	[5].
										[JumpFull]				->	[12].
										[JumpLongZero]		->	[6].
										[JumpLongNonZero]	->	[6] }].
	^machineCodeSize "Slang can't inline the switch into the ifTrue:ifFalse: correctly"! !

!CogInLineLiteralsX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeArithCwR: x64opcode
	| value reg reverse |
	value := operands at: 0.
	reg := operands at: 1.
	reverse := x64opcode = 16r85 or: [x64opcode = 16r39]. "Tst & Cmp; backwards"
	self machineCodeBuffer at:  0 put: (self rexR: RISCTempReg x: 0 b: RISCTempReg).
	self machineCodeBuffer at:  1 put: 16rB8 + (RISCTempReg bitAnd: 7).
	self machineCodeBuffer at:  2 put: (value bitAnd: 16rFF).
	self machineCodeBuffer at:  3 put: (value >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at:  4 put: (value >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at:  5 put: (value >> 24 bitAnd: 16rFF).
	self machineCodeBuffer at:  6 put: (value >> 32 bitAnd: 16rFF).
	self machineCodeBuffer at:  7 put: (value >> 40 bitAnd: 16rFF).
	self machineCodeBuffer at:  8 put: (value >> 48 bitAnd: 16rFF).
	self machineCodeBuffer at:  9 put: (value >> 56 bitAnd: 16rFF).
	self machineCodeBuffer at: 10 put: (reverse
					ifTrue: [self rexR: RISCTempReg x: 0 b: reg]
					ifFalse: [self rexR: reg x: 0 b: RISCTempReg]).
	self machineCodeBuffer at: 11 put: x64opcode.
	self machineCodeBuffer at: 12 put: (reverse
					ifTrue: [self mod: ModReg RM: reg RO: RISCTempReg]
					ifFalse: [self mod: ModReg RM: RISCTempReg RO: reg]).
	self assert: (self machineCodeBuffer at: 12) > 16r90. "See literalBeforeFollowingAddress:"
	^13! !

!CogInLineLiteralsX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveCwR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg offset |
	value := operands at: 0.
	reg := operands at: 1.
	(self isAnInstruction: (cogit cCoerceSimple: value to: #'AbstractInstruction *')) ifTrue:
		[value := (cogit cCoerceSimple: value to: #'AbstractInstruction *') address].
	(cogit addressIsInCurrentCompilation: value) ifTrue:
		[offset := value - (self address + 7).
		 self machineCodeBuffer at: 0 put: (self rexR: reg x: 0 b: 0).
		 self machineCodeBuffer at: 1 put: 16r8D. "LoadEffectiveAddress"
		 self machineCodeBuffer at: 2 put: (self mod: ModRegInd RM: 5 RO: reg).
		 self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
		 self machineCodeBuffer at: 4 put: (offset >> 8 bitAnd: 16rFF).
		 self machineCodeBuffer at: 5 put: (offset >> 16 bitAnd: 16rFF).
		 self machineCodeBuffer at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^7].
	self machineCodeBuffer at:  0 put: (self rexR: 0 x: 0 b: reg).
	self machineCodeBuffer at:  1 put: 16rB8 + (reg bitAnd: 7).
	self machineCodeBuffer at:  2 put: (value bitAnd: 16rFF).
	self machineCodeBuffer at:  3 put: (value >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at:  4 put: (value >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at:  5 put: (value >> 24 bitAnd: 16rFF).
	self machineCodeBuffer at:  6 put: (value >> 32 bitAnd: 16rFF).
	self machineCodeBuffer at:  7 put: (value >> 40 bitAnd: 16rFF).
	self machineCodeBuffer at:  8 put: (value >> 48 bitAnd: 16rFF).
	self machineCodeBuffer at:  9 put: (value >> 56 bitAnd: 16rFF).
	"Add a nop to disambiguate between MoveCwR/PushCw and ArithCwR, which ends with a (self mod: ModReg RM: 0 RO: 0)"
	self machineCodeBuffer at: 10 put: 16r90.
	^11! !

!CogInLineLiteralsX64Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizePushCw
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value offset |
	value := operands at: 0.
	(self isAnInstruction: (cogit cCoerceSimple: value to: #'AbstractInstruction *')) ifTrue:
		[value := (cogit cCoerceSimple: value to: #'AbstractInstruction *') address].
	(cogit addressIsInCurrentCompilation: value) ifTrue:
		[offset := value - (self address + 7).
		 self machineCodeBuffer at: 0 put: (self rexR: RISCTempReg x: 0 b: 0).
		 self machineCodeBuffer at: 1 put: 16r8D. "LoadEffectiveAddress"
		 self machineCodeBuffer at: 2 put: (self mod: ModRegInd RM: 5 RO: RISCTempReg).
		 self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
		 self machineCodeBuffer at: 4 put: (offset >> 8 bitAnd: 16rFF).
		 self machineCodeBuffer at: 5 put: (offset >> 16 bitAnd: 16rFF).
		 self machineCodeBuffer at: 6 put: (offset >> 24 bitAnd: 16rFF).
		 self machineCodeBuffer at: 7 put: 16r41.
		 self machineCodeBuffer at: 8 put: 16r48 + RISCTempReg.
		^9].
	self machineCodeBuffer at:  0 put: (self rexR: RISCTempReg x: 0 b: RISCTempReg).
	self machineCodeBuffer at:  1 put: 16rB8 + (RISCTempReg bitAnd: 7).
	self machineCodeBuffer at:  2 put: (value bitAnd: 16rFF).
	self machineCodeBuffer at:  3 put: (value >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at:  4 put: (value >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at:  5 put: (value >> 24 bitAnd: 16rFF).
	self machineCodeBuffer at:  6 put: (value >> 32 bitAnd: 16rFF).
	self machineCodeBuffer at:  7 put: (value >> 40 bitAnd: 16rFF).
	self machineCodeBuffer at:  8 put: (value >> 48 bitAnd: 16rFF).
	self machineCodeBuffer at:  9 put: (value >> 56 bitAnd: 16rFF).
	self machineCodeBuffer at: 10 put: 16r41.
	self machineCodeBuffer at: 11 put: 16r48 + RISCTempReg. "The 48 will disambiguate between MoveCwR, PushCw and ArithCwR, which ends with a (self mod: ModReg RM: 0 RO: 0)"
	self assert: (self machineCodeBuffer at: 11) < 16r90. "see literalBeforeFollowingAddress:"
	^12! !

!CogARMv8Compiler methodsFor: 'accessing' stamp: 'cb 10/26/2026 22:30'!
machineCodeAt: anOffset
	"read aWord from machineCode, with little endian"
	<inline: true>
	^self machineCodeBuffer at: anOffset // 4! !

!CogARMv8Compiler methodsFor: 'accessing' stamp: 'cb 10/26/2026 22:30'!
machineCodeAt: anOffset put: aWord
	"add aWord to machineCode, with little endian"
	<inline: true>
	self machineCodeBuffer at: anOffset // 4 put: aWord! !

!CogARMv8Compiler methodsFor: 'generate machine code' stamp: 'cb 10/26/2026 22:30'!
mapEntryAddress
	"Typically map entries apply to the end of an instruction, for two reasons:
	  a)	to cope with literals embedded in variable-length instructions, since, e.g.
		on x86, the literal typically comes at the end of the instruction.
	  b)	in-line cache detection is based on return addresses, which are typically
		to the instruction following a call.
	 But on ARMv8 we use out-of-line literals so the mapEntryAddress of a literal is simply the instruction's address."
	<inline: true>
	^opcode = Literal
		ifTrue: [self address]
		ifFalse: [self address + machineCodeSize]! !

!CogARMv8Compiler methodsFor: 'generate machine code' stamp: 'cb 10/26/2026 22:30'!
sizePCDependentInstructionAt: eventualAbsoluteAddress
	"Size a jump and set its address.  The target may be another instruction
	 or an absolute address.  On entry the address inst var holds our virtual
	 address. On exit address is set to eventualAbsoluteAddress, which is
	 where this instruction will be output.  The span of a jump to a following
	 instruction is therefore between that instruction's address and this
	 instruction's address ((which are both still their virtual addresses), but the
	 span of a jump to a preceding instruction or to an absolute address is
	 between that instruction's address (which by now is its eventual absolute
	 address) or absolute address and eventualAbsoluteAddress.

	 ARMv8 is simple; the 26-bit call/jump range (for a signed 28 bit extent, +/- 128Mb) and
	 19 bit conditional branch range  (for a signed 21 bit extent, +/- 1Mb) means no short
	 jumps.  This routine only has to determine the targets of jumps, not determine sizes.

	 This version also deals with out-of-line literals.  If this is the real literal,
	 update the stand-in in literalsManager with the address (because instructions
	 referring to the literal are referring to the stand-in).  If this is annotated with
	 IsObjectReference transfer the annotation to the stand-in, whence it will be
	 transferred to the real literal, simplifying update of literals."

	opcode = AlignmentNops ifTrue:
		[| alignment |
		 self address: eventualAbsoluteAddress.
		 alignment := operands at: 0.
		 ^machineCodeSize := (eventualAbsoluteAddress + (alignment - 1) bitAnd: alignment negated)
							   - eventualAbsoluteAddress].
	self assert: (self isJump or: [opcode = Call or: [opcode = CallFull
				or: [dependent notNil and: [dependent opcode = Literal]]]]).
	self isJump ifTrue: [self resolveJumpTarget].
	self address: eventualAbsoluteAddress.
	(dependent notNil and: [dependent opcode = Literal]) ifTrue:
		[opcode = Literal ifTrue:
			[dependent address: self address].
		 annotation = cogit getIsObjectReference ifTrue:
			[dependent annotation: annotation.
			 annotation := nil]].
	^machineCodeSize := maxSize! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeAddCqRDest: destReg
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| constant srcReg offset |
	<var: #constant type: #sqInt>
	constant := (operands at: 0) signedIntFromLong64.
	srcReg := operands at: 1.

	self isPossiblyShiftableImm12: constant
		ifTrue:
			[:shift|
			"C6.2.4		ADD (immediate)	C6-761
			 C6.2.8		ADDS (immediate)	C6-769"
			self machineCodeBuffer
				at: 0
				put: (srcReg = SP
						ifTrue:  [2r100100010 "ADD"]
						ifFalse: [2r101100010 "ADDS"]) << 23
					+ (shift ifTrue: [constant >> 2 + (1 << 22)] ifFalse: [constant << 10])
					+ (srcReg << 5)
					+ destReg.
			^4]
		ifFalse: [].
	self isPossiblyShiftableImm12: constant negated
		ifTrue:
			[:shift|
			"C6.2.308		SUB (immediate)	C6-1311
			 C6.2.314		SUBS (immediate)	C6-1321"
			self machineCodeBuffer
				at: 0
				put: (srcReg = SP
						ifTrue:  [2r110100010 "SUB"]
						ifFalse: [2r111100010 "SUBS"]) << 23
					+ (shift ifTrue: [constant negated >> 2 + (1 << 22)] ifFalse: [constant negated << 10])
					+ (srcReg << 5)
					+ destReg.
			^4]
		ifFalse: [].
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	"cogit processor disassembleInstructionAt: 4 In: machineCode object"
	offset := self emitMoveCw: constant intoR: RISCTempReg at: 0.
	"C6.2.7		ADDS (extended register)		C6-766"
	self machineCodeBuffer
				at: offset // 4
				put: 2r10101011001 << 21
					+ (RISCTempReg << 16)
					+ (SXTX << 13)
					+ (srcReg << 5)
					+ destReg.
	^offset + 4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeAlignmentNops
	<inline: true>
	"See outputMachineCodeAt:"
	self assert: machineCodeSize \\ 4 = 0.
	self machineCodeBuffer at: 0 put: NOP.
	^machineCodeSize! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeArithmeticShiftRightCqR
	<inline: true>
	"C6.2.17 	ASR (immediate)	C6-785		100100110 (1)
	 C6.2.177	LSL (immediate)	C6-1075	110100110 (1)
	 C6.2.180	LSR (immediate)	C6-1081	110100110 (1)"
	| reg constant |
	constant := operands at: 0.
	reg := operands at: 1.
	self assert: (constant between: 1 and: 63).
	self machineCodeBuffer
		at: 0
		put: 2r1001001101 << 22
			+ (constant << 16)
			+ (63 << 10)
			+ (reg << 5)
			+ reg.
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeArithmeticShiftRightCqRR
	<inline: true>
	"C6.2.17 	ASR (immediate)	C6-785		100100110 (1)
	 C6.2.177	LSL (immediate)	C6-1075	110100110 (1)
	 C6.2.180	LSR (immediate)	C6-1081	110100110 (1)"
	| constant srcReg  destReg |
	constant := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	self assert: (constant between: 1 and: 63).
	self machineCodeBuffer
		at: 0
		put: 2r1001001101 << 22
			+ (constant << 16)
			+ (63 << 10)
			+ (srcReg << 5)
			+ destReg.
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeCall
	<inline: true>
	| offset |
	offset := ((operands at: 0) - self address) signedIntFromLong64.
	self assert: (offset noMask: 3).
	self assert: (self isInImmediateBranchAndLinkRange: offset).
	"C6.2.33	BL		C6-812"
	self machineCodeBuffer at: 0 put: (self bl: offset).
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeCallJumpFull: link
	"Sizing/generating calls.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: true>
	| jumpTarget instrOffset|
	<var: #jumpTarget type: #'AbstractInstruction *'>
	jumpTarget := self longJumpTargetAddress.
	instrOffset := self emitMoveCw: jumpTarget asUnsignedInteger intoR: RISCTempReg at: 0.
	self machineCodeBuffer
		at: instrOffset // 4
		put: (self brlink: link reg: RISCTempReg).
	self assert: instrOffset = self literalLoadInstructionBytes.
	^instrOffset + 4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeClzRR
	"C6.2.56	CLZ		C6-849"
	<inline: true>
	| maskReg dest  |
	maskReg := operands at: 0.
	dest := operands at: 1.
	self machineCodeBuffer
		at: 0
		put: 2r11011010110000000001 << 12
			+ (maskReg << 5)
			+ dest.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeCmpC32R
	<inline: true>
	| constant rn |
	constant := operands at: 0.
	rn := operands at: 1.

	self assert: (cogit addressIsInCurrentCompilation: dependent address).
	self assert: dependent address \\ 4 = 0.
	self assert: (dependent address asUnsignedInteger - self address asUnsignedInteger) abs < (1<<18).
	"C6.2.131	LDR (literal)		C6-979"
	self machineCodeBuffer
		at: 0
		put: 2r00011 << 27
			+ (dependent address - self address << 3 "5 - 2")
			+ RISCTempReg.

	"C6.2.60	CMP (extended register)	C6-856"
	self machineCodeBuffer
		at: 1
		put: 2r01101011001 << 21 "N.B. sf == 0!!!!"
			+ (RISCTempReg << 16)
			+ (UXTX << 13)
			+ (rn << 5)
			+ XZR.
	^8! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeCmpCqR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| constant rn offset |
	<var: #constant type: #sqInt>
	constant := (operands at: 0) signedIntFromLong64.
	rn := operands at: 1.

	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	self isPossiblyShiftableImm12: constant
		ifTrue:
			[:shift|
			"C6.2.61	CMP (immediate)	C6-858
			 C6.2.314	SUBS (immediate)	C6-1321"
			self machineCodeBuffer
				at: 0
				put: 2r111100010 << 23
					+ (shift ifTrue: [constant >> 2 + (1 << 22)] ifFalse: [constant << 10])
					+ (rn << 5)
					+ XZR.
			^4]
		ifFalse: [].
	self isPossiblyShiftableImm12: constant negated
		ifTrue:
			[:shift|
			"C6.2.58	CMN (immediate)	C6-852
			 C6.2.8		ADDS (immediate)	C6-769"
			self machineCodeBuffer
				at: 0
				put: 2r101100010 << 23
					+ (shift ifTrue: [constant negated >> 2 + (1 << 22)] ifFalse: [constant negated << 10])
					+ (rn << 5)
					+ XZR.
			^4]
		ifFalse: [].
	offset := self emitMoveCw: constant intoR: RISCTempReg at: 0.
	"C6.2.60	CMP (extended register)	C6-856"
	self machineCodeBuffer
				at: offset // 4
				put: 2r11101011001 << 21
					+ (RISCTempReg << 16)
					+ (UXTX << 13)
					+ (rn << 5)
					+ XZR.
	^offset + 4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeCmpRdRd
	"C7.2.59	FCMP	C7-1506"
	<inline: true>
	self machineCodeBuffer
		at: 0
		put: 2r11110011 << 21
		+ ((operands at: 0) << 16)
		+ (1 << 13)
		+ ((operands at: 1) << 5).
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConditionalJump: conditionCode
	"Will get inlined into concretizeAt: switch."
	"Sizing/generating jumps.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: false>
	| offset |
	offset := self computeJumpTargetOffset.
 	self assert: (offset ~= 0 and: [self isInImmediateBranchRange: offset]).
	self machineCodeBuffer at: 0 put: (self cond: conditionCode offset: offset). "B offset"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConditionalLongJump: conditionCode
	"Generate a short conditional branch around a long unconditional jump.
	 C6.2.25	B.cond		C6-798
	 C6.2.26	B			C6-799
	 Note that C6.2.44 CBNZ and C6.2.45 CBZ aren't useful for Closed PIC jumps.
	 They compare against zero and have only a +/-1Mb range."
	<inline: true>
	| offset |
	self assert: (conditionCode = EQ or: [conditionCode = NE]).
	offset := (operands at: 0) - (self address + 4).
	self assert: (offset noMask: 3).
	self assert: (offset >>> 2 between: -1 << 26 and: 1 << 26 - 1).
	self machineCodeBuffer at: 0
		put: 2r101010 << 25
			+ (2 << 5 "skip next instruction")
			+ (conditionCode = EQ ifTrue: [NE] ifFalse: [EQ]).
	self machineCodeBuffer at: 1
		put: 2r101 << 26 + (offset >>> 2 bitAnd: 1 << 26 - 1).
	^8! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConvertRRd
	"Table C3-67 Floating-point and integer or fixed-point conversion instructions	C3-229
	 SCVTF (scalar, integer) on page C7-1894"
	<inline: true>
	self machineCodeBuffer
		at: 0
		put: 2r1001111001100010 << 16
			+ ((operands at: 0) << 5)
			+ (operands at: 1).
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConvertRdR
	"Table C3-67 Floating-point and integer or fixed-point conversion instructions	C3-229
	 FCVTZS (scalar, integer) on page C7-1568"
	<inline: true>
	self machineCodeBuffer
		at: 0
		put: 2r1001111001111 << 19
			+ ((operands at: 0) << 5)
			+ (operands at: 1).
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeCwRArithmetic: arithOp Rd: destRegOrXZR
	| instrBytes |
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	"cogit processor disassembleInstructionAt: 4 In: machineCode object"
	instrBytes := self emitMoveCw: (operands at: 0) intoR: RISCTempReg at: 0.
	"ADD (extended register) on page C6-758
	 ADDS (extended register) on page C6-766
	 SUB (extended register) on page C6-1308
	 SUBS (extended register) on page C6-1318"
	self machineCodeBuffer
		at: instrBytes // 4
		put: 2r10001011001 << 21
			+ (arithOp << 29)
			+ (RISCTempReg <<16)
			+ (UXTX << 13)
			+ ((operands at: 1) << 5)
			+ destRegOrXZR.
	^instrBytes + 4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeCwRLogical: op
	| destReg constant offset |
	constant := operands at: 0.
	destReg := operands at: 1.
	offset := self emitMoveCw: constant intoR: RISCTempReg at: 0.
	"AND	(shifted register) - 64-bit variant on page C6-777
	 BIC	(shifted register) - 64-bit variant on page C6-808
	 ORR	(shifted register) - 64-bit variant on page C6-1127
	 ORN	(shifted register) - 64-bit variant on page C6-1123
	  EOR	(shifted register) - 64-bit variant on page C6-898
	  EON	(shifted register) - 64-bit variant on page C6-894
	  ANDS	(shifted register) - 64-bit variant on page C6-781
	  BICS	(shifted register) - 64-bit variant on page C6-810"
	self machineCodeBuffer
				at: offset // 4
				put: 2r1000101 << 25
					+ (op << 29)
					+ (RISCTempReg << 16)
					+ (destReg << 5)
					+ destReg.
	^offset + 4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeFill32
	"fill with operand 0 according to the processor's endianness"
	<inline: true>
	self machineCodeBuffer at: 0 put: (operands at: 0).
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeJumpLong
	"C6.2.26 	B		C6-799"
	<inline: true>
	| offset |
	offset := (operands at: 0) - self address.
	self assert: (offset noMask: 3).
	self assert: (offset >>> 2 between: -1 << 26 and: 1 << 26 - 1).
	self machineCodeBuffer
		at: 0
		put: 2r101 << 26 + (offset >>> 2 bitAnd: 1 << 26 - 1).
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeJumpR
	"C6.2.36	BR	C6-816"
	<inline: true>
	self machineCodeBuffer
		at: 0
		put: 2r1101011 << 25
			+ (XZR << 16)
			+ ((operands at: 0) << 5).
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeLDAXR
	"C6.2.113		LDAXR		C6-944"
	<inline: true>
	| targetReg addressReg |
	targetReg := operands at: 0.
	addressReg := operands at: 1.
	self machineCodeBuffer
		at: 0
		put: 2r1100100001011111111111 << 10
			+ (addressReg << 5)
			+ targetReg.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeLiteral
	"Generate an out-of-line literal.  Copy the value and any annotation from the stand-in in the literals manager."
	| literalAsInstruction literal |
	<var: 'literal' type: #usqInt>
	literalAsInstruction := cogit cCoerceSimple: (operands at: 0) to: #'AbstractInstruction *'.
	literal := (self isAnInstruction: literalAsInstruction)
				ifTrue: [literalAsInstruction address]
				ifFalse: [self cCode: [literalAsInstruction asUnsignedInteger]
							inSmalltalk: [literalAsInstruction]].
	self assert: (dependent notNil and: [dependent opcode = Literal]).
	dependent annotation ifNotNil:
		[self assert: annotation isNil.
		 annotation := dependent annotation].
	dependent address ifNotNil: [self assert: dependent address = self address].
	dependent address: self address.
	self machineCodeBuffer at: 0 put: (literal bitAnd: 16rFFFFFFFF).
	self literalSize = 4 ifTrue:
		[^4].
	self machineCodeBuffer at: 1 put: (literal >> 32).
	^8! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeLoadEffectiveAddressMwrR
	| baseReg offset destReg instrBytes |
	<var: #offset type: #sqInt>
	offset := operands at: 0.
	baseReg := operands at: 1.
	destReg := operands at: 2.
	self isPossiblyShiftableImm12: offset
		ifTrue:
			[:shift|
			"C6.2.4		ADD (immediate)	C6-761"
			self machineCodeBuffer
				at: 0
				put: 2r100100010 << 23
					+ (shift ifTrue: [offset >> 2] ifFalse: [offset << 10])
					+ (baseReg << 5)
					+ destReg.
			^4]
		ifFalse: [].
	self isPossiblyShiftableImm12: offset negated
		ifTrue:
			[:shift|
			"C6.2.308		SUB (immediate)	C6-1311"
			self machineCodeBuffer
				at: 0
				put: 2r110100010 << 23
					+ (shift ifTrue: [offset negated >> 2] ifFalse: [offset negated << 10])
					+ (baseReg << 5)
					+ destReg.
			^4]
		ifFalse: [].
	instrBytes := self emitMoveCw: offset intoR: RISCTempReg at: 0.
	"C6.2.3		ADD (extended register) C6-758"
	self machineCodeBuffer
		at: instrBytes // 4
		put: 2r10001011001 << 21
			+ (destReg << 16)
			+ (UXTX << 13)
			+ (RISCTempReg << 5)
			+ destReg.
	^instrBytes + 4

	"cogit processor disassembleInstructionAt: 0 In: machineCode object"! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeLogicalOp: op CqRDest: destReg
	"AND	(immediate) - 64-bit variant on page C6-775
	 ORR	(immediate) - 64-bit variant on page C6-1125
	 EOR	(immediate) - 64-bit variant on page C6-896
	 ANDS	(immediate) - 64-bit variant on page C6-779
	 C6.2.329	TST (immediate)	C6-1346"
	<inline: false>
	| srcReg constant effectiveDestReg offset |
	constant := (operands at: 0) signedIntFromLong64.
	srcReg := operands at: 1.
	"N.B. For three operand logical ops only support AndCq: const R: reg R: NativeSPReg, which is used for alignment."
	effectiveDestReg := (opcode = AndCqRR and: [destReg = SP]) ifTrue: [RISCTempReg] ifFalse: [destReg].
	self isImmNImmSImmREncodableBitmask: constant
		ifTrue:
			[:n :imms :immr|
			 self machineCodeBuffer
				at: 0
				put: 2r1001001 << 25
					+ (op << 29)
					+ (n << 22)
					+ (immr << 16)
					+ (imms << 10)
					+ (srcReg << 5)
					+ effectiveDestReg.
			 offset := 4]
		ifFalse:
			[offset := self emitMoveCw: constant intoR: RISCTempReg at: 0.
			"OPC	N
			 00		0	AND (shifted register) - 64-bit variant on page C6-777
			 00		1	BIC (shifted register) - 64-bit variant on page C6-808
			 01		0	ORR (shifted register) - 64-bit variant on page C6-1127
			 01		1	ORN (shifted register) - 64-bit variant on page C6-1123
			 10		0	EOR (shifted register) - 64-bit variant on page C6-898
			 10		1	EON (shifted register) - 64-bit variant on page C6-894
			 11		0	ANDS (shifted register) - 64-bit variant on page C6-781
			 11		0	BICS (shifted register) - 64-bit variant on page C6-810"
			self machineCodeBuffer
				at: offset // 4
				put: 2r1000101 << 25
					+ (op << 29)
					+ (RISCTempReg << 16)
					+ (srcReg << 5)
					+ effectiveDestReg.
			offset := offset + 4].
	(opcode = AndCqRR and: [destReg = SP]) ifFalse:
		[^offset].
	self machineCodeBuffer at: offset // 4 put: (self movern: effectiveDestReg rd: destReg).
	^offset + 4
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	"cogit processor disassembleInstructionAt: 4 In: machineCode object"
	"cogit processor disassembleInstructionAt: 8 In: machineCode object"! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeLogicalShiftLeftCqR
	<inline: true>
	"C6.2.17 	ASR (immediate)	C6-785		100100110 (1)
	 C6.2.177	LSL (immediate)	C6-1075	110100110 (1)
	 C6.2.180	LSR (immediate)	C6-1081	110100110 (1)"
	| reg constant |
	constant := operands at: 0.
	reg := operands at: 1.
	self assert: (constant between: 1 and: 63).
	self machineCodeBuffer
		at: 0
		put: 2r1101001101 << 22
			+ (64 - constant << 16)
			+ (63 - constant << 10)
			+ (reg << 5)
			+ reg.
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeLogicalShiftLeftCqRR
	<inline: true>
	"C6.2.17 	ASR (immediate)	C6-785		100100110 (1)
	 C6.2.177	LSL (immediate)	C6-1075	110100110 (1)
	 C6.2.180	LSR (immediate)	C6-1081	110100110 (1)"
	| constant srcReg  destReg |
	constant := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	self assert: (constant between: 1 and: 63).
	self machineCodeBuffer
		at: 0
		put: 2r1101001101 << 22
			+ (64 - constant << 16)
			+ (63 - constant << 10)
			+ (srcReg << 5)
			+ destReg.
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeLogicalShiftRightCqR
	<inline: true>
	"C6.2.17 	ASR (immediate)	C6-785		100100110 (1)
	 C6.2.177	LSL (immediate)	C6-1075	110100110 (1)
	 C6.2.180	LSR (immediate)	C6-1081	110100110 (1)"
	| reg constant |
	constant := operands at: 0.
	reg := operands at: 1.
	self assert: (constant between: 1 and: 63).
	self machineCodeBuffer
		at: 0
		put: 2r1101001101 << 22
			+ (constant << 16)
			+ (63 << 10)
			+ (reg << 5)
			+ reg.
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeLogicalShiftRightCqRR
	<inline: true>
	"C6.2.17 	ASR (immediate)	C6-785		100100110 (1)
	 C6.2.177	LSL (immediate)	C6-1075	110100110 (1)
	 C6.2.180	LSR (immediate)	C6-1081	110100110 (1)"
	| constant srcReg  destReg |
	constant := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	self assert: (constant between: 1 and: 63).
	self machineCodeBuffer
		at: 0
		put: 2r1101001101 << 22
			+ (constant << 16)
			+ (63 << 10)
			+ (srcReg << 5)
			+ destReg.
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMathRdRd: floatArithOp
	"C7.2.43	FADD (scalar)	C7-1426"
	"C7.2.91	FDIV (scalar)	C7-1582"
	"C7.2.129	FMUL (scalar)	C7-1664"
	"C7.2.167	FSUB (scalar)	C7-1747"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer
		at: 0
		put: 2r11110011 << 21
			+ (srcReg << 16)
			+ (floatArithOp << 10)
			+ (destReg << 5)
			+ destReg.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveA32R
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcAddr destReg instrOffset |
	srcAddr := operands at: 0.
	destReg := operands at: 1.
	"ldr srcReg, [VarBaseReg, #offset] except that this is illegal for SP/X31"
	(self isAddressRelativeToVarBase: srcAddr) ifTrue:
		[destReg ~= SP ifTrue:
			[^self emitLd: 2 rn: VarBaseReg rt: destReg imm: srcAddr - cogit varBaseAddress shiftBy12: false at: 0].
		 instrOffset := self emitLd: 2 rn: VarBaseReg rt: RISCTempReg imm: srcAddr - cogit varBaseAddress shiftBy12: false at: 0.
		 self machineCodeBuffer
			at: instrOffset / 4
			put: (self movern: RISCTempReg rd: destReg).
		^instrOffset + 4].
	instrOffset := self emitMoveCw: srcAddr intoR: RISCTempReg at: 0.
	SP ~= destReg ifTrue:
		[^self emitLd: 2 rn: RISCTempReg rt: destReg imm: 0 shiftBy12: false at: instrOffset].
	instrOffset := self emitLd: 2 rn: RISCTempReg rt: RISCTempReg imm: 0 shiftBy12: false at: instrOffset.
	self machineCodeBuffer
		at: instrOffset // 4
		put: (self movern: RISCTempReg rd: destReg).
	^instrOffset + 4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveAwR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcAddr destReg instrOffset |
	srcAddr := operands at: 0.
	destReg := operands at: 1.
	"ldr srcReg, [VarBaseReg, #offset] except that this is illegal for SP/X31"
	(self isAddressRelativeToVarBase: srcAddr) ifTrue:
		[destReg ~= SP ifTrue:
			[^self emitLd: 3 rn: VarBaseReg rt: destReg imm: srcAddr - cogit varBaseAddress shiftBy12: false at: 0].
		 instrOffset := self emitLd: 3 rn: VarBaseReg rt: RISCTempReg imm: srcAddr - cogit varBaseAddress shiftBy12: false at: 0.
		 self machineCodeBuffer
			at: instrOffset / 4
			put: (self movern: RISCTempReg rd: destReg).
		^instrOffset + 4].
	instrOffset := self emitMoveCw: srcAddr intoR: RISCTempReg at: 0.
	SP ~= destReg ifTrue:
		[^self emitLd: 3 rn: RISCTempReg rt: destReg imm: 0 shiftBy12: false at: instrOffset].
	instrOffset := self emitLd: 3 rn: RISCTempReg rt: RISCTempReg imm: 0 shiftBy12: false at: instrOffset.
	self machineCodeBuffer
		at: instrOffset // 4
		put: (self movern: RISCTempReg rd: destReg).
	^instrOffset + 4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveC32R
	"N.B. the selector dereferencing scheme depends on this being a sign-extending 32-bit to 64-bit move.
	 See CogObjectRepresentationFor64BitSpur>>#maybeGenerateSelectorIndexDereferenceRoutine."
	<inline: true>
	| constant rn |
	constant := operands at: 0.
	rn := operands at: 1.

	self assert: (cogit addressIsInCurrentCompilation: dependent address).
	self assert: dependent address \\ 4 = 0.
	self assert: (dependent address - self address) < (1 << 20).
	"C6.2.143	LDRSW (literal)	C6-1008"
	self machineCodeBuffer
		at: 0
		put: 2r10011 << 27
			+ ((dependent address - self address  bitAnd: 1 << 21 - 1) << 3 "5 - 2")
			+ rn.
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveCqR
	"C3.3.4		Move (immediate)	C3-215

	 The Move (immediate) instructions are aliases for a single MOVZ, MOVN, or ORR (immediate with zero register),
	 instruction to load an immediate value into the destination register. An assembler must permit a signed or
	 unsigned immediate, as long as its binary representation can be generated using one of these instructions,
	 and an assembler error results if the immediate cannot be generated in this way. On disassembly, it is
	 unspecified whether the immediate is output as a signed or an unsigned value.

	 C6.2.191	MOVZ	C6-1102	Move wide with zero moves an optionally-shifted 16-bit immediate value to a register.
	 C6.2.190	MOVN	C6-1100	Move wide with NOT moves the inverse of an optionally-shifted 16-bit immediate value to a register.
	 C6.2.204	ORR (immediate)	C6-1125
										Bitwise OR (immediate) performs a bitwise (inclusive) OR of a register value and an immediate
										register value, and writes the result to the destination register."

	| constant destReg |
	constant := operands at: 0.
	destReg := operands at: 1.
	destReg ~= SP ifTrue:
		[| lowBit lowBitMod16 mask |
		lowBit := constant > 0
					ifTrue: [self cCode: [self computeLowBit: constant] inSmalltalk: [constant lowBit - 1]]
					ifFalse: [0].
		lowBitMod16 := lowBit // 16 * 16.
		mask := 1 << 16 - 1 << lowBitMod16.
		(constant bitAnd: mask) = constant ifTrue:
			["Use MOVZ"
			 self machineCodeBuffer
				at: 0
				put: 2r110100101 << 23
					+ (lowBitMod16 // 16 << 21)
					+ (constant >> lowBitMod16 << 5)
					+ destReg.
			 ^4].
		lowBit := constant signedIntFromLong64 < -1
					ifTrue: [self cCode: [self computeLowBit: constant bitInvert64] inSmalltalk: [constant bitInvert64 lowBit - 1]]
					ifFalse: [0].
		(constant bitOr: mask) signedIntFromLong64 = -1 ifTrue:
			["Use MOVN"
			 self machineCodeBuffer
				at: 0
				put: 2r100100101 << 23
					+ (lowBitMod16 // 16 << 21)
					+ ((constant bitInvert64 >> lowBitMod16 bitAnd: mask) << 5)
					+ destReg.
			 ^4]].
	^self isImmNImmSImmREncodableBitmask: constant
		ifTrue:
			[:n :imms :immr| "Use ORR"
			self machineCodeBuffer
				at: 0
				put: 2r1011001 << 25
					+ (n << 22)
					+ (immr << 16)
					+ (imms << 10)
					+ (XZR << 5)
					+ destReg.
			4]
		ifFalse: [self emitMoveCw: constant intoR: destReg at: 0]

	"cogit processor disassembleInstructionAt: 0 In: machineCode object"! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveM64rRd
	"Load/Store Vector on page C3-206.
	 C7.2.184	LDR (immediate, SIMD&FP)	C7-1800"
	<inline: true>
	| rd offset baseReg |
	offset := operands at: 0.
	baseReg := operands at: 1.
	rd := operands at: 2.
	self assert: (offset noMask: 7).
	self machineCodeBuffer
		at: 0
		put: 2r1111110101 << 22
			+ (offset << 7 "10 - 3")
			+ (baseReg << 5)
			+ rd.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMovePerfCnt64RL
	"C6.2.192		MRS		Move System Register						p C6-1104"
	"D13.4.2		PMCCNTR_EL0, Counter-timer Virtual Count register		p D13-3531		this is a cycle frequency counter"
	"D13.8.26		CNTVCT_EL0, Counter-timer Virtual Count register		p D13-3774		this is a 24MHz to 1GHz counter depending on implementation"

	"MRS <Xt>, PMCCNTR_EL0	op0:0b11 op1:0b011 CRn:0b1001 CRm:0b1101 op2:0b000
	 MRS <Xt>, CNTVCT_EL0		op0:0b11 op1:0b011 CRn:0b1110 CRm:0b0000 op2:0b010"

	"Use CNTVCT_EL0; we would prefer to use PMCCNTR_EL0 but at least macOS makes it a priviledged instruction."
	self machineCodeBuffer
		at: 0
		put: (2r1101010100111 << 19 "MRS + op0"
			+ (2r011 << 16)	"op1"
			+ (2r1110 << 12)	"CRn"
			+ (2r0000 << 8)	"CRm"
			+ (2r010 << 5) "op2"
			+ (operands at: 0)).
	^4
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRA32
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg destAddr instrOffset |
	srcReg := operands at: 0.
	destAddr := operands at: 1.
	"str srcReg, [VarBaseReg, #offset] except that this is illegal for srcReg = SP/X31"
	(self isAddressRelativeToVarBase: destAddr) ifTrue:
		[srcReg ~= SP ifTrue:
			[self machineCodeBuffer
				at: 0
				put: (self st: 2 rn: VarBaseReg rt: srcReg imm: destAddr - cogit varBaseAddress shiftBy12: false).
			 ^4].
		self machineCodeBuffer at: 0
			put: (self movern: srcReg rd: RISCTempReg).
		self machineCodeBuffer at: 1
			put: (self st: 2 rn: VarBaseReg rt: RISCTempReg imm: destAddr - cogit varBaseAddress shiftBy12: false).
		^8].
	instrOffset := self emitMoveCw: destAddr intoR: RISCTempReg at: 0.
	SP ~= srcReg ifTrue:
		[self machineCodeBuffer
			at: instrOffset // 4
			put: (self st: 2 rn: RISCTempReg rt: srcReg imm: 0 shiftBy12: false).
		^instrOffset + 4].
	self machineCodeBuffer at: instrOffset // 4
		put: (self movern: srcReg rd: CArg1Reg).
	self machineCodeBuffer at: instrOffset // 4 + 1
		put: (self st: 2 rn: RISCTempReg rt: CArg1Reg imm: 0 shiftBy12: false).
	^instrOffset + 8
	! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRAb
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg destAddr instrOffset |
	srcReg := operands at: 0.
	destAddr := operands at: 1.
	self deny: SP = srcReg.
	(self isAddressRelativeToVarBase: destAddr) ifTrue:
		[self machineCodeBuffer
			at: 0
			put: (self st: 0 rn: VarBaseReg rt: srcReg imm: destAddr - cogit varBaseAddress shiftBy12: false).
		 ^4].
	instrOffset := self emitMoveCw: destAddr intoR: RISCTempReg at: 0.
	self machineCodeBuffer
		at: instrOffset // 4
		put: (self st: 0 rn: RISCTempReg rt: srcReg imm: 0 shiftBy12: false).
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^instrOffset + 4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRAw
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg destAddr instrOffset |
	srcReg := operands at: 0.
	destAddr := operands at: 1.
	"str srcReg, [VarBaseReg, #offset] except that this is illegal for srcReg = SP/X31"
	(self isAddressRelativeToVarBase: destAddr) ifTrue:
		[srcReg ~= SP ifTrue:
			[self machineCodeBuffer
				at: 0
				put: (self st: 3 rn: VarBaseReg rt: srcReg imm: destAddr - cogit varBaseAddress shiftBy12: false).
			 ^4].
		self machineCodeBuffer at: 0
			put: (self movern: srcReg rd: RISCTempReg).
		self machineCodeBuffer at: 1
			put: (self st: 3 rn: VarBaseReg rt: RISCTempReg imm: destAddr - cogit varBaseAddress shiftBy12: false).
		^8].
	instrOffset := self emitMoveCw: destAddr intoR: RISCTempReg at: 0.
	SP ~= srcReg ifTrue:
		[self machineCodeBuffer
			at: instrOffset // 4
			put: (self st: 3 rn: RISCTempReg rt: srcReg imm: 0 shiftBy12: false).
		^instrOffset + 4].
	self machineCodeBuffer at: instrOffset // 4
		put: (self movern: srcReg rd: CArg1Reg).
	self machineCodeBuffer at: instrOffset // 4 + 1
		put: (self st: 3 rn: RISCTempReg rt: CArg1Reg imm: 0 shiftBy12: false).
	^instrOffset + 8
	! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	"C6.2.184 MOV (to/from SP) p1089
	 C6.2.188 MOV (register) p1096"
	self machineCodeBuffer
		at: 0
		put: ((srcReg = SP or: [destReg = SP])
				ifTrue:  [2r10010001 << 24
						+ (srcReg << 5)
						+ destReg]
				ifFalse: [2r10101010 << 24
						 + (srcReg << 16)
						 + (XZR << 5)
						 + destReg]).
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRRd
	<inline: true>
	"C7.2.124	FMOV (general)		C7-1651"
	self machineCodeBuffer
		at: 0
		put: 2r1001111001100111 << 16
			+ ((operands at: 0) << 5)
			+ (operands at: 1).
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRXSrR: unitSizeLog2MinusOne
	"Xwr/X32r/X16r/Xbr - memory unit whose address is r * unit size away from an address in a register"
	"C6.2.274	STR (register)	C6-1242"
	| src index base |
	src := operands at: 0.
	index := operands at: 1.
	base := operands at: 2.
	self deny: (SP = src or: [SP = index]).
	self machineCodeBuffer
		at: 0
		put: unitSizeLog2MinusOne << 30
			+ (2r111000001 << 21)
			+ (index << 16)
			+ (UXTX << 13)
			+ (3 << 11)
			+ (base << 5)
			+ src.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRXbrR
	<inline: true>
	"Xbr - byte in mwemory whose address is r away from an address in a register"
	"C6.2.274	STR (register)	C6-1242"
	| src index base |
	src := operands at: 0.
	index := operands at: 1.
	base := operands at: 2.
	self deny: (SP = src or: [SP = index]).
	self machineCodeBuffer
		at: 0
		put: 2r00111000001 << 21
			+ (index << 16)
			+ (UXTX << 13)
			+ (3 << 11)
			+ (base << 5)
			+ src.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRdM64r
	"Load/Store Vector on page C3-206.
	 C7.2.323	STR (immediate, SIMD&FP)	C7-2114"
	<inline: true>
	| rd offset baseReg |
	rd := operands at: 0.
	offset := operands at: 1.
	baseReg := operands at: 2.
	self assert: (offset noMask: 7).
	self machineCodeBuffer
		at: 0
		put: 2r11111101 << 24
			+ (offset << 7 "10 - 3")
			+ (baseReg << 5)
			+ rd.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRdR
	<inline: true>
	"C7.2.124	FMOV (general)		C7-1651"
	self machineCodeBuffer
		at: 0
		put: 2r1001111001100110 << 16
			+ ((operands at: 0) << 5)
			+ (operands at: 1).
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveXSrRR: unitSizeLog2MinusOne
	"Xwr/X32r/X16r/Xbr - memory unit whose address is r * unit size away from an address in a register"
	"C6.2.132	LDR (register)	C6-981"
	| index base dest |
	index := operands at: 0.
	base := operands at: 1.
	dest := operands at: 2.
	self deny: SP = dest.
	self machineCodeBuffer
		at: 0
		put: unitSizeLog2MinusOne << 30
			+ (2r111000011 << 21)
			+ (index << 16)
			+ (UXTX << 13)
			+ (3 << 11)
			+ (base << 5)
			+ dest.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMulRRR
	"C6.2.196	MUL	C6-1111"
	<inline: true>
	"reg3 := reg1 * reg2"
	| reg1 reg2 reg3 |
	reg1 := operands at: 0.
	reg2 := operands at: 1.
	reg3 := operands at: 2.
	self machineCodeBuffer
		at: 0
		put: 2r10011011 << 24
			+ (reg1 << 16)
			+ (XZR << 10)
			+ (reg2 << 5)
			+ reg3.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeNegateR
	<inline: true>
	"C6.2.309	SUB (shifted register) 1313
	 C6.2.313	SUBS (extended register)	C6-1318"
	| reg |
	reg := operands at: 0.
	self deny: SP = reg.
	self machineCodeBuffer
		at: 0
		put: 2r11001011 << 24
			+ (reg << 16)
			+ (XZR << 5)
			+ reg.
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeNop
	<inline: true>
	self machineCodeBuffer at: 0 put: NOP.
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizePopR
	<inline: true>
	"C6.2.130	LDR (immediate)	C6-976
	 Post-index"
	| reg |
	reg := operands at: 0.
	self deny: SP = reg.
	self machineCodeBuffer
		at: 0
		put: 2r1111100001 << 22
			+ (8 << 12)
			+ (2r01 << 10)
			+ (SPReg << 5)
			+ reg.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizePrefetchAw
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcAddr |
	srcAddr := operands at: 0.
	(self isAddressRelativeToVarBase: srcAddr) ifTrue:
		[srcAddr < cogit varBaseAddress ifTrue:
			[self shouldBeImplemented.
			 ^4].
		 self machineCodeBuffer
			at: 0
			put: (self prn: VarBaseReg imm: srcAddr - cogit varBaseAddress shiftBy12: false).
		 ^4].
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	self asserta: (self emitMoveCw: srcAddr intoR: RISCTempReg at: 0) = 4.
	self machineCodeBuffer
		at: 1
		put: (self prn: RISCTempReg imm: 0 shiftBy12: false).
	"cogit processor disassembleInstructionAt: 4 In: machineCode object"
	^8! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizePushCq
	"ARMv8 has no push costant insructions (no store immediate pre-index).
	 Instead load the constant into RISCTempReg and push that."
	<inline: true>
	| instrBytes |
	operands at: 1 put: RISCTempReg.
	instrBytes := self concretizeMoveCqR.
	"C6.2.273	STR (immediate)	Pre-index	C6-1239"
	self machineCodeBuffer
		at: instrBytes // 4
		put: 2r11111 << 27
			+ ((-8 bitAnd: 1 << 9 - 1) << 12)
			+ (2r11 << 10)
			+ (SPReg << 5)
			+ RISCTempReg.
	^instrBytes + 4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizePushCw
	<inline: true>
	| instrBytes |
	instrBytes := self emitMoveCw: (operands at: 0) intoR: RISCTempReg at: 0.
	"C6.2.273	STR (immediate)	Pre-index	C6-1239"
	self machineCodeBuffer
		at: instrBytes // 4
		put: 2r11111 << 27
			+ ((-8 bitAnd: 1 << 9 - 1) << 12)
			+ (2r11 << 10)
			+ (SPReg << 5)
			+ RISCTempReg.
	^instrBytes + 4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizePushR
	<inline: true>
	"C6.2.273	STR (immediate)	C6-1239
	 Pre-index"
	| reg |
	reg := operands at: 0.
	self deny: SP = reg.
	self machineCodeBuffer
		at: 0
		put: 2r11111 << 27
			+ ((-8 bitAnd: 1 << 9 - 1) << 12)
			+ (2r11 << 10)
			+ (SPReg << 5)
			+ reg.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeRRArithmetic: arithOp Rd: rd
	"rd := regA op regB "
	| regA regB |
	regB := operands at: 0.
	regA := operands at: 1.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	"cogit processor disassembleInstructionAt: 4 In: machineCode object"
	SP = regB ifTrue:	"Arithmetic with the sp; we must use the extended register forms, and negate
						 on subtract because we can't have Rm as SP, Rm = 31 is interoreted as XZR."
		["ADD (extended register) on page C6-758
		  ADDS (extended register) on page C6-766
		  SUB (extended register) on page C6-1308
		  SUBS (extended register) on page C6-1318"
		 self machineCodeBuffer
			at: 0
			put: 2r10001011001 << 21
				+ (arithOp << 29)
				+ (regA << 16)
				+ (UXTX << 13)
				+ (regB << 5)
				+ rd.
		 (arithOp = ArithmeticSub or: [arithOp = ArithmeticSubS]) ifFalse:
			[^4].
		 self machineCodeBuffer
			at: 1
			put: 2r10001011 << 24
				+ (arithOp << 29)
				+ (rd << 16)
				+ (XZR << 5)
				+ rd.
		 ^8].
	SP = regA ifTrue: "Arithmetic with the sp; we must use the extended register forms."
		["ADD (extended register) on page C6-758
		  ADDS (extended register) on page C6-766
		  SUB (extended register) on page C6-1308
		  SUBS (extended register) on page C6-1318
		  CMN (extended register) on page C6-850
		  CMP (extended register) on page C6-856"
		 self machineCodeBuffer
			at: 0
			put: 2r10001011001 << 21
					+ (arithOp << 29)
					+ (regB << 16)
					+ (UXTX << 13)
					+ (regA << 5)
					+ rd.
		 rd ~= XZR ifTrue: [self halt].
		 ^4].
	self assert: (regA ~= SP and: [regB ~= SP]).
	"ADD (shifted register) on page C6-763
	 ADDS (shifted register) on page C6-771
	 CMN (shifted register) on page C6-854
	 CMP (shifted register) on page C6-860
	 SUB (shifted register) on page C6-1313
	 SUBS (shifted register) on page C6-1323"
	 self machineCodeBuffer
		at: 0
		put: 2r10001011 << 24
			+ (arithOp << 29)
			+ (regB << 16)
			+ (regA << 5)
			+ rd.
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeRRLogical: logicalOp
	"AND (shifted register) - 64-bit variant on page C6-777
	 BIC (shifted register) - 64-bit variant on page C6-808
	 ORR (shifted register) - 64-bit variant on page C6-1127
	 ORN (shifted register) - 64-bit variant on page C6-1123
	 EOR (shifted register) - 64-bit variant on page C6-898
	 EON (shifted register) - 64-bit variant on page C6-894
	 ANDS (shifted register) - 64-bit variant on page C6-781
	 BICS (shifted register) - 64-bit variant on page C6-810"
	| destReg srcReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer
		at: 0
		put: 2r1000101 << 25
			+ (logicalOp << 29)
			+ (srcReg << 16)
			+ (destReg << 5)
			+ destReg.
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeRetN
	"Will get inlined into concretizeAt: switch."
	<var: #offset type: #sqInt>
	<inline: true>
	| offset |
	offset := operands at: 0.
	"C6.2.218 RET p1147"
	offset = 0 ifTrue:
		[self machineCodeBuffer
			at: 0
			put: 2r1101011001 << 22
				+ (XZR << 16)
				+ (LR << 5).
		^4].

	"C6.2.4 ADD (immediate) p761"
	self machineCodeBuffer at: 0 put: (self addrn: SPReg rd: SPReg imm: offset shiftBy12: false).
	self machineCodeBuffer at: 1 put: 2r1101011001 << 22
				+ (XZR << 16)
				+ (LR << 5).
	^8! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeRotateCqR
	"C6.2.225	ROR (immediate)	C6-1157"
	<inline: true>
	| constant reg |
	constant := operands at: 0.
	reg := operands at: 1.
	self assert: (constant between: 1 and: 63).
	self machineCodeBuffer
		at: 0
		put: 2r1001001111 << 22
			+ (reg << 16)
			+ ((RotateRightCqR = opcode ifTrue: [constant] ifFalse: [64 - constant]) << 10)
			"+ (1 << 10)"
			+ (reg << 5)
			+ reg.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeShiftRR: shiftOp
	"C6.2.18 	ASRV	C6-787		(a.k.a	C6.2.16 	ASR (register)	
	 C6.2.178	LSLV	C6-1077	(a.k.a	C6.2.176	LSL (register)	
	 C6.2.181	LSRV	C6-1083	(a.k.a	C6.2.179	LSR (register)"
	<inline: true>
	| shiftedReg shiftCountReg |
	shiftCountReg := operands at: 0.
	shiftedReg := operands at: 1.
	self machineCodeBuffer
		at: 0
		put: 2r10011010110 << 21
			+ (shiftCountReg << 16)
			+ (shiftOp << 10)
			+ (shiftedReg << 5)
			+ shiftedReg.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeSignExtendRR: width
	"C6.2.320 	SXTB	C6-1332
	 C6.2.321 	SXTH	C6-1334
	 C6.2.322 	SXTW	C6-1336"
	| rn rd |
	rn := operands at: 0.
	rd := operands at: 1.
	self machineCodeBuffer
		at: 0
		put: 2r1001001101 << 22
			+ (width - 1 << 10)
			+ (rn << 5)
			+ rd.
	^4

	"cogit processor disassembleInstructionAt: 0 In: machineCode object"! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeSqrtRd
	"C7.2.165	FSQRT (scalar)	C7-1743"
	<inline: true>
	| reg |
	reg := operands at: 0.
	self machineCodeBuffer
		at: 0
		put: 2r111100110000111 << 14
			+ (reg << 5)
			+ reg.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeStop
	<inline: true>
	self machineCodeBuffer at: 0 put: self stop.
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeSubCqR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| constant reg offset |
	<var: #constant type: #sqInt>
	constant := (operands at: 0) signedIntFromLong64.
	reg := operands at: 1.

	self isPossiblyShiftableImm12: constant
		ifTrue:
			[:shift|
			"C6.2.308		SUB (immediate)	C6-1311
			 C6.2.314		SUBS (immediate)	C6-1321"
			self machineCodeBuffer
				at: 0
				put: (reg = SP
						ifTrue:  [2r110100010]
						ifFalse: [2r111100010]) << 23
					+ (shift ifTrue: [constant >> 2 + (1 << 22)] ifFalse: [constant << 10])
					+ (reg << 5)
					+ reg.
			^4]
		ifFalse: [].
	self isPossiblyShiftableImm12: constant negated
		ifTrue:
			[:shift|
			"C6.2.4		ADDS (immediate)	C6-761
			 C6.2.8		ADDS (immediate)	C6-769"
			self machineCodeBuffer
				at: 0
				put: (reg = SP
						ifTrue:  [2r100100010]
						ifFalse: [2r101100010]) << 23
					+ (shift ifTrue: [constant negated >> 2 + (1 << 22)] ifFalse: [constant negated << 10])
					+ (reg << 5)
					+ reg.
			^4]
		ifFalse: [].
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	"cogit processor disassembleInstructionAt: 4 In: machineCode object"
	offset := self emitMoveCw: constant intoR: RISCTempReg at: 0.
	self deny: SP = reg.
	"C6.2.313	SUBS (extended register)		C6-1318"
	self machineCodeBuffer
				at: offset // 4
				put: 2r10001011 << 24
				+ (ArithmeticSubS << 29)
				+ (RISCTempReg << 16)
				+ (reg << 5)
				+ reg.
	^offset + 4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeXorRdRd
	"C7.2.34	EOR (vector)	C7-1440"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer
		at: 0
		put: 2r101110001 << 21
			+ (srcReg << 16)
			+ (2r111 << 10)
			+ (destReg << 5)
			+ destReg.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeZeroExtendRR: width
	"C6.2.333	UBFX	C6-1353
	 C6.2.341 	UXTB	C6-1364
	 C6.2.342 	UXTH	C6-1366"
	| rn rd |
	rn := operands at: 0.
	rd := operands at: 1.
	self machineCodeBuffer
		at: 0
		put: 2r1101001101 << 22
			+ (width - 1 << 10)
			+ (rn << 5)
			+ rd.
	^4

	"cogit processor disassembleInstructionAt: 0 In: machineCode object"! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeCASAL
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| constantReg "Xs" valueReg "Xt" baseReg "Xn" |
	constantReg := operands at: 0.
	valueReg := operands at: 1.
	baseReg := operands at: 2.
	self machineCodeBuffer
		at: 0
		put: 2r11001000111 << 21
			+ (constantReg << 16)
			+ (63 << 10)
			+ (baseReg << 5)
			+ valueReg.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeCB
	"C6.2.44/45 		CBNZ/CBZ 			C6-831..."
	<inline: true>
	| offset reg |
	offset := self computeJumpTargetOffset.
 	self assert: (offset ~= 0 and: [self isInImmediateBranchRange: offset]).
	reg := operands at: 1.
	self machineCodeBuffer
		at: 0
		put: 2r101101 << 26
			"+ (opcode = CBNZ ifTrue: [1 << 24] ifFalse: [0])""Since this method is obsolete and unsent, comment out the undeclared reference"
			+ ((offset bitAnd: 1 << 21 - 1) << 3)
			+ reg.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeCCMPNE
	"C6.2.49 CCMP (register)	C6-839"
	<inline: true>
	| rM rN flags |
	rM := operands at: 0.
	rN := operands at: 1.
	flags := operands at: 2.
	self machineCodeBuffer
		at: 0
		put: 2r11111010010 << 21
			+ (rM << 16)
			+ (NE << 12)
			+ (rN << 5)
			+ flags.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeCLREX
	"C6.2.54		CLREX 			C6-847"
	<inline: true>
	self machineCodeBuffer
		at: 0
		put: 2r11010101000000110011111101011111.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeCSET
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg condition |
	reg := operands at: 0.
	condition := operands at: 1.
	self machineCodeBuffer
		at: 0
		put: 2r1001101010011111 << 16
			+ ((condition bitXor: 1) "strange, but true" << 12)
			+ (2r111111 << 5)
			+ reg.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeCacheControlOp1: op1 CRm: crm Op2: op2
	<inline: true>
	self machineCodeBuffer
		at: 0
		put: 2r1101010100001 << 19
			+ (op1 << 16)
			+ (2r0111 << 12) "CRn"
			+ (crm << 8)
			+ (op2 << 5)
			+ (operands at: 0).
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4

"Scripture (see DminLine & IminLine below):

D13.2.33	CTR_EL0, Cache Type Register		D13-2912

	Provides information about the architecture of the caches.

	AArch64 System register CTR_EL0[31:0] is architecturally mapped to AArch32 System register CTR[31:0].

	CTR_EL0 is a 64-bit register.

	DIC, bit [29]
		Instruction cache invalidation requirements for instruction to data coherence. The meaning of this bit is:
			0b0	Instruction cache invalidation to the Point of Unification is required for instruction to data coherence.
			0b1	Instruction cache cleaning to the Point of Unification is not required for instruction to data coherence.

	IDC, bit [28]
		Data cache clean requirements for instruction to data coherence. The meaning of this bit is:
			0b0	Data cache clean to the Point of Unification is required for instruction to data coherence,
					unless CLIDR.LoC == 0b000 or (CLIDR.LoUIS == 0b000 && CLIDR.LoUU == 0b000).
			0b1 Data cache clean to the Point of Unification is not required for instruction to data coherence.

	CWG, bits [27:24]
		Cache writeback granule. Log2 of the number of words of the maximum size of memory that can be overwritten as a result of the eviction of a cache entry that has had a memory location in it modified.
		A value of 0b0000 indicates that this register does not provide Cache writeback granule information and either:
			- The architectural maximum of 512 words (2KB) must be assumed.
			- The Cache writeback granule can be determined from maximum cache line size encoded in the Cache Size ID Registers.
		Values greater than 0b1001 are reserved.
		Arm recommends that an implementation that does not support cache write-back implements this field as 0b0001. This applies, for example, to an implementation that supports only write-through caches.

	ERG, bits [23:20]
		Exclusives reservation granule. Log2 of the number of words of the maximum size of the reservation granule that has been implemented for the Load-Exclusive and Store-Exclusive instructions.
		The use of the value 0b0000 is deprecated.
		The value 0b0001 and values greater than 0b1001 are reserved.

	DminLine, bits [19:16]
		Log2 of the number of words in the smallest cache line of all the data caches and unified caches that are controlled by the PE.

	L1Ip, bits [15:14]
		Level 1 instruction cache policy. Indicates the indexing and tagging policy for the L1 instruction cache. Possible values of this field are:
			0b00 VMID aware Physical Index, Physical tag (VPIPT)
			0b01 ASID-tagged Virtual Index, Virtual Tag (AIVIVT)
			0b10 Virtual Index, Physical Tag (VIPT)
			0b11 Physical Index, Physical Tag (PIPT)
		The value 0b01 is reserved in Armv8.
		The value 0b00 is permitted only in an implementation that includes ARMv8.2-VPIPT, otherwise the value is reserved.

	Bits [13:4] Reserved, RES0.

	IminLine, bits [3:0]
		Log2 of the number of words in the smallest cache line of all the instruction caches that are controlled by the PE."! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeDataSynchronizationBarrier
	"C6.2.81	DSB	C6-891"
	<inline: true>
	| CRm |
	CRm := (operands at: 0) << 2 + (operands at: 1).
	self machineCodeBuffer
		at: 0
		put: 2r11010101000000110011000010011111
			+ (CRm << 8).
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeDivRRR
	"C6.2.234	SDIV	C6-1174"
	<inline: true>
	"Rd := Rn / Rm"
	"reg3 := reg1 / reg2"
	| reg1 reg2 reg3 |
	reg1 := operands at: 0.
	reg2 := operands at: 1.
	reg3 := operands at: 2.
	self machineCodeBuffer
		at: 0
		put: 2r10011010110 << 21
			+ (reg2 << 16)
			+ (2r000011 << 10)
			+ (reg1 << 5)
			+ reg3.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeInstructionSynchronizationBarrier
	"C6.2.96	ISB		C6-912"
	<inline: true>
	| CRm |
	CRm := 2r1111.
	self machineCodeBuffer
		at: 0
		put: 2r11010101000000110011000011011111
			+ (CRm << 8).
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeMRSOp1: op1 CRn: crn CRm: crm Op2: op2
	"C6.2.192	MRS	C6-1104
	 Move System Register allows the PE to read an AArch64 System register into a general-purpose register."
	<inline: true>
	self machineCodeBuffer
		at: 0
		put: 2r1101010100111 << 19
			+ (op1 << 16)
			+ (crn << 12)
			+ (crm << 8)
			+ (op2 << 5)
			+ (operands at: 0).
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeMSubRRR
	"C6.2.195	MSUB	C6-1109
	 Xd := Xa - (Xn * Xm)"
	<inline: true>
	"rD := rA - (rN * rM)"
	| rN rA rM rD |
	rM := (operands at: 0) >> 5.
	rN := (operands at: 0) bitAnd: 31.
	rA := operands at: 1.
	rD := operands at: 2.
	self machineCodeBuffer
		at: 0
		put: 2r10011011 << 24
			+ (rM << 16)	"Xm"
			+ (1 << 15)
			+ (rA << 10)	"Xa"
			+ (rN << 5)	"Xn"
			+ rD.			"Xd"
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveAwRR
	"C6.2.128 	LDP		C6-970"
	| pairAddress reg1 reg2 |
	<inline: true>
	pairAddress := operands at: 0.
	reg1 := operands at: 1.
	reg2 := operands at: 2.
	self assert: reg1 ~= reg2.
	self assert: (reg1 ~= RISCTempReg and: [reg2 ~= RISCTempReg]).
	self assert: (self isAddressRelativeToVarBase: pairAddress).
	(self asserta: pairAddress - cogit varBaseAddress / 8 < (1 << 6)) ifFalse:
		[self error: 'unhandled immediate offset in concretizeMoveAwRR'].
	reg1 = SP ifTrue: [reg1 := RISCTempReg].
	reg2 = SP ifTrue: [reg2 := RISCTempReg].
	self machineCodeBuffer
		at: 0
		put: 2r1010100101 << 22
			+ (pairAddress - cogit varBaseAddress / 8 << 15)
			+ (reg2 << 10)
			+ (VarBaseReg << 5)
			+ reg1.
	(reg1 ~= RISCTempReg and: [reg2 ~= RISCTempReg]) ifTrue:
		[^4].
	self machineCodeBuffer
		at: 1
		put: (self movern: RISCTempReg rd: SP).
	^8

	"cogit processor
		disassembleInstructionAt: 0 In: machineCode object;
		disassembleInstructionAt: 4 In: machineCode object"! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRRAw
	"C6.2.272 	STP		C6-1236"
	<inline: true>
	| pairAddress reg1 reg2 offset |
	reg1 := operands at: 0.
	reg2 := operands at: 1.
	pairAddress := operands at: 2.
	self assert: reg1 ~= reg2.
	self assert: (reg1 ~= RISCTempReg and: [reg2 ~= RISCTempReg]).
	self assert: (self isAddressRelativeToVarBase: pairAddress).
	(self asserta: pairAddress - cogit varBaseAddress / 8 < (1 << 6)) ifFalse:
		[self error: 'unhandled immediate offset in concretizeMoveRRAw'].
	reg1 = SP ifTrue: [reg1 := RISCTempReg].
	reg2 = SP ifTrue: [reg2 := RISCTempReg].
	(reg1 = RISCTempReg or: [reg2 = RISCTempReg])
		ifTrue:
			[self machineCodeBuffer
				at: 0
				put: (self movern: SP rd: RISCTempReg).
			 offset := 1]
		ifFalse:
			[offset := 0].
	self machineCodeBuffer
		at: offset
		put: 2r1010100100 << 22
			+ (pairAddress - cogit varBaseAddress / 8 << 15)
			+ (reg2 << 10)
			+ (VarBaseReg << 5)
			+ reg1.
	"cogit processor
		disassembleInstructionAt: 0 In: machineCode object;
		disassembleInstructionAt: 4 In: machineCode object"
	^offset + 1 * 4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeMulOverflowJump
	"Sizing/generating jumps.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: false>
	| offset |
	offset := self computeJumpTargetOffset - 4. "-4 because the jump is from the second word..."
 	self assert: (offset ~= 0 and: [self isInImmediateBranchRange: offset]).
	"See concretizeMulOverflowRRR
	 RISCTempReg := RISCTempReg + CArg1Reg/sign.
	 JumpZero/NonZero"
	self machineCodeBuffer at: 0
		put: 2r10001011 << 24
			+ (ArithmeticAddS << 29)
			+ (CArg1Reg << 16)
			+ (RISCTempReg << 5)
			+ RISCTempReg.
	self machineCodeBuffer at: 1
		put: (self
				cond: (opcode = JumpMulOverflow ifTrue: [NE] ifFalse: [EQ])
				offset: offset). "B offset"
	^8! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeMulOverflowRRR
	"Will get inlined into concretizeAt: switch."
	"ARMv8 has no multiply overflow detection.  Instead it is synthesized from the two halves of
	 a 64x64=>128 bit multiply. The upper 64-bits are tested.  The sequence is
		high64 := SMULH a,b
		a/low64 := MUL a,b
		signBit := low64/a >> 63
		high64 := high64 + signBit
	 If high64 is zero after this sequence then the multiply has not overflowed,
	 since high64 is an extension of signBit if no overflow (either 0 or -1) and
	 both -1 + 1 = 0 and 0 + 0 = 0. Note that because we restrict ourselves to
	 three concrete ARMv8 instructions per abstract instruction the last operation
	 of the sequence is generated in concretizeMulOverflowJump.

	 C6.2.196	MUL				C6-1111
	 C6.2.242	SMULH				C6-1184
	 C6.2.180	LSR (immediate)	C6-1081	110100110 (1)"

	<inline: true>
	| reg1 reg2 reg3 |
	reg1 := operands at: 0.
	reg2 := operands at: 1.
	reg3 := operands at: 2.
	"RISCTempReg := high(reg1 * reg2); must precede destructive MUL"
	self machineCodeBuffer
		at: 0
		put: 2r1001101101 << 22
			+ (reg1 << 16)
			+ (XZR << 10)
			+ (reg2 << 5)
			+ RISCTempReg.
	"reg3 := reg1 * reg2"
	self machineCodeBuffer
		at: 1
		put: 2r10011011 << 24
			+ (reg1 << 16)
			+ (XZR << 10)
			+ (reg2 << 5)
			+ reg3.
	"CArg1Reg := sign(reg3)"
	self machineCodeBuffer
		at: 2
		put: 2r1101001101 << 22
			+ (63 << 16) "constant to shift by"
			+ (63 << 10)
			+ (reg3 << 5)
			+ CArg1Reg. "cuz CArg0Reg == TempReg"
	"RISCTempReg := RISCTempReg + CArg1Reg/sign
	 is in concretizeMulOverflowJump"
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	"cogit processor disassembleInstructionAt: 4 In: machineCode object"
	"cogit processor disassembleInstructionAt: 8 In: machineCode object"
	^12! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeNativePopRR
	"C6.2.128 	LDP		C6-970"
	<inline: true>
	| reg1 reg2 |
	reg1 := operands at: 0.
	reg2 := operands at: 1.
	"Post-index"
	self machineCodeBuffer
		at: 0
		put: 2r10101000110000010 << 15
			+ (reg2 << 10)
			+ (SP << 5)
			+ reg1.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeNativePushRR
	"C6.2.272 	STP		C6-1236"
	<inline: true>
	| reg1 reg2 |
	reg1 := operands at: 0.
	reg2 := operands at: 1.
	"Pre-index"
	self machineCodeBuffer
		at: 0
		put: 2r10101001101111110 << 15
			+ (reg2 << 10)
			+ (SP << 5)
			+ reg1.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeNativeRetN
	"Will get inlined into concretizeAt: switch."
	<var: #offset type: #sqInt>
	<inline: true>
	| offset |
	offset := operands at: 0.
	"C6.2.218 RET p1147"
	offset = 0 ifTrue:
		[self machineCodeBuffer
			at: 0
			put: 2r1101011001 << 22
				+ (XZR << 16)
				+ (LR << 5).
		^4].

	"C6.2.4 ADD (immediate) p761"
	self machineCodeBuffer at: 0 put: (self addrn: SP rd: SP imm: offset shiftBy12: false).
	self machineCodeBuffer at: 1 put: 2r1101011001 << 22
				+ (XZR << 16)
				+ (LR << 5).
	^8! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeSTLR
	<inline: true>
	| valueReg "Xt" baseReg "Xn" |
	valueReg := operands at: 0.
	baseReg := operands at: 1.
	self machineCodeBuffer
		at: 0
		put: 2r1100100010011111111111 << 10
			+ (baseReg << 5)
			+ valueReg.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object '00000000: stlr	x0, [x1]'"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeSTLXR
	"C6.2.268		STLXR		C6-1228"
	<inline: true>
	| valueReg addressReg statusReg |
	valueReg := operands at: 0.
	addressReg := operands at: 1.
	statusReg := operands at: 2.
	self machineCodeBuffer
		at: 0
		put: 2r11001 << 27
			+ (statusReg << 16)
			+ (63 << 10)
			+ (addressReg << 5)
			+ valueReg.
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^4! !

!CogARMv8Compiler methodsFor: 'generate machine code - support' stamp: 'cb 10/26/2026 22:30'!
computeJumpTargetOffset
	<inline: true>
	| jumpTarget |
	<var: #jumpTarget type: #'AbstractInstruction *'>
	jumpTarget := self jumpTargetAddress.
	^jumpTarget signedIntFromLong64 - self address signedIntFromLong64! !

!CogARMv8Compiler methodsFor: 'generate machine code - support' stamp: 'cb 10/26/2026 22:30'!
emitLd: unitSizeLog2MinusOne rn: baseReg rt: targetReg imm: offset shiftBy12: shiftBy12 at: instrOffset
	"C6.2.130	LDR (immediate)	C6-976
	 C6.2.132	LDR (register)		C6-981
	 C6.2.136	LDRH (immediate)	C6-990
	 C6.2.166	LDUR				C6-1058
	 C6.2.134	LDRB (immediate)	C6-985
	 C6.2.135	LDRB (register)		C6-988"

	"cogit processor disassembleInstructionAt: instrOffset In: machineCode object"
	| unitSize instrBytes |
	unitSize := 1 << unitSizeLog2MinusOne.
	"Unsigned offset, C6-977"
	(offset \\ unitSize = 0
	 and: [offset / unitSize between: 0 and: 1 << 12 - 1]) ifTrue:
		[self machineCodeBuffer
			at: instrOffset / 4
			put: unitSizeLog2MinusOne << 30
				+ (2r11100101 << 22)
				+ (offset << (10 - unitSizeLog2MinusOne))
				+ (baseReg << 5)
				+ targetReg.
		 ^instrOffset + 4].
	(offset between: -256 and: 255) ifTrue: "Unscaled signed 9-bit offset, C6-1058"
		[self machineCodeBuffer
			at: instrOffset / 4
			put: unitSizeLog2MinusOne << 30
				+ (2r11100001 << 22)
				+ ((offset bitAnd: 511) << 12)
				+ (baseReg << 5)
				+ targetReg.
		 ^instrOffset + 4].
	"C6.2.132	LDR (register)	C6-981"
	instrBytes := self emitMoveCw: offset intoR: RISCTempReg at: instrOffset.
	self machineCodeBuffer
		at: instrBytes // 4
		put: unitSizeLog2MinusOne << 30
			+ (2r111000011 << 21)
			+ (RISCTempReg << 16)
			+ (UXTX << 13)
			+ (1 << 11)
			+ (baseReg << 5)
			+ targetReg.
	^instrBytes + 4! !

!CogARMv8Compiler methodsFor: 'generate machine code - support' stamp: 'cb 10/26/2026 22:30'!
emitLdfprn: baseReg rt: targetDPReg imm: offset shiftBy12: shiftBy12 at: instrOffset
	"C7.2.184	LDR (immediate, SIMD&FP)	C7-1800
	 C7.2.186	LDR (register, SIMD&FP)	C7-1806"

	"cogit processor disassembleInstructionAt: instrOffset In: machineCode object"
	| instrBytes |
	"Unsigned offset, C7-1801"
	(offset \\ 8 = 0
	 and: [offset / 8 between: 0 and: 1 << 12 - 1]) ifTrue:
		[self machineCodeBuffer
			at: instrOffset / 4
			put: 2r1111110101 << 22
				+ (offset << 7 "10 - 3")
				+ (baseReg << 5)
				+ targetDPReg.
		 ^instrOffset + 4].
	"No unscaled signed 9-bit offset because there is only post-index and pre-index, see C7-1800"
	"C6.2.132	LDR (register)	C6-981"
	instrBytes := self emitMoveCw: offset intoR: RISCTempReg at: instrOffset.
	"C7.2.186	LDR (register, SIMD&FP)	C7-1806"
	self machineCodeBuffer
		at: instrBytes // 4
		put: 2r11111100011 << 21
			+ (RISCTempReg << 16)
			+ (UXTX << 13)
			+ (1 << 11)
			+ (baseReg << 5)
			+ targetDPReg.
	^instrBytes + 4! !

!CogARMv8Compiler methodsFor: 'generate machine code - support' stamp: 'cb 10/26/2026 22:30'!
emitMoveCw: constantArg intoR: destReg at: offsetBytes
	"Emit a load of constant into destReg.  Answer the number of bytes of machine code
	 generated. Literals are stored out-of-line; emit a LDR (literal) with the relevant offset."
	 <var: 'constantArg' type: #usqInt>
	| constant |
	 <var: 'constant' type: #usqInt>
	<inline: false>
	self deny: destReg = SP.
	"cogit processor disassembleInstructionAt: offsetBytes // 4 In: machineCode object"
	constant := (self isAnInstruction: (cogit cCoerceSimple: constantArg to: #'AbstractInstruction *'))
					ifTrue: [(cogit cCoerceSimple: constantArg to: #'AbstractInstruction *') address]
					ifFalse: [constantArg].
	((opcode = MoveCwR or: [opcode = PushCw])
	 and: [self inCurrentCompilation: constant]) ifTrue:
		[| aligned unaligned pcRelativeOffset |
		 "C6.2.10 	ADR	C6-773"
		 unaligned := constant bitAnd: 3.
		 aligned := constant - unaligned.
		 pcRelativeOffset := aligned - self address asInteger >>> 2.
		 self assert: (pcRelativeOffset between: -1 << 18 and: 1 << 18 - 1).
		 self machineCodeBuffer
			at: offsetBytes // 4
			put: unaligned << 29
				+ (1 << 28)
				+ ((pcRelativeOffset bitAnd: 1 << 19 - 1) << 5)
				+ destReg.
		 ^offsetBytes + 4].
	self assert: (cogit addressIsInCurrentCompilation: dependent address).
	self assert: dependent address \\ 4 = 0.
	self assert: (dependent address asUnsignedInteger - (self address + offsetBytes) asUnsignedInteger) abs < (1 << 20).
	"C6.2.131	LDR (literal)		C6-979"
	self machineCodeBuffer
		at: offsetBytes // 4
		put: 2r01011 << 27
			+ ((dependent address - (self address + offsetBytes) bitAnd: 1 << 21 - 1) << 3 "5 - 2")
			+ destReg.
	^offsetBytes + 4! !

!CogARMv8Compiler methodsFor: 'generate machine code - support' stamp: 'cb 10/26/2026 22:30'!
emitSt: unitSizeLog2MinusOne rn: baseReg rt: sourceReg imm: offset shiftBy12: shiftBy12
	"C6.2.273	STR (immediate)	C6-1239
	 C6.2.274	STR (register)		C6-1242
	 C6.2.275	STRB (immediate)	C6-1244"

	| unitSize instrBytes |
	unitSize := 1 << unitSizeLog2MinusOne.
	self deny: SP = sourceReg.
	self deny: baseReg = sourceReg.
	"Unsigned offset, C6-1240"
	(offset \\ unitSize = 0
	 and: [offset / unitSize between: 0 and: 1 << 12 - 1]) ifTrue:
		[self machineCodeBuffer
			at: 0
			put: unitSizeLog2MinusOne << 30
				+ (2r11100100 << 22)
				+ (offset << (10 - unitSizeLog2MinusOne))
				+ (baseReg << 5)
				+ sourceReg.
		 ^4].
	(offset between: -256 and: 255) ifTrue: "Unscaled signed 9-bit offset, C6-1244"
		[self machineCodeBuffer
			at: 0
			put: unitSizeLog2MinusOne << 30
				+ (2r111000000 << 21)
				+ ((offset bitAnd: 511) << 12)
				+ (baseReg << 5)
				+ sourceReg.
		 ^4].
	"If the offset fits in an add or subtract immediate then do an
	 add into RISCTempReg, avoiding using an out-of-line literal..."
	(self isPossiblyShiftableNegatableImm12: offset) ifTrue:
		[self isPossiblyShiftableImm12: offset
			ifTrue:
				[:shift| "C6.2.8		ADDS (immediate)	C6-769"
				self machineCodeBuffer
					at: 0
					put: 2r101100010 << 23
						+ (shift ifTrue: [offset >> 2 + (1 << 22)] ifFalse: [offset << 10])
						+ (baseReg << 5)
						+ RISCTempReg]
			ifFalse:
				[self isPossiblyShiftableImm12: offset negated
					ifTrue:
						[:shift| "C6.2.314		SUBS (immediate)	C6-1321"
						self machineCodeBuffer
							at: 0
							put: 2r111100010 "SUBS" << 23
								+ (shift ifTrue: [offset negated >> 2 + (1 << 22)] ifFalse: [offset negated << 10])
								+ (baseReg << 5)
								+ RISCTempReg]
					ifFalse: [self error: 'cannot happen']].
		self machineCodeBuffer
			at: 1
			put: unitSizeLog2MinusOne << 30
				+ (2r111000001 << 21)
				+ (XZR << 16)
				+ (UXTX << 13)
				+ (1 << 11)
				+ (RISCTempReg << 5)
				+ sourceReg.
		^8].
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	"cogit processor disassembleInstructionAt: 4 In: machineCode object"
	instrBytes := self emitMoveCw: offset intoR: RISCTempReg at: 0.
	self assert: instrBytes = 4.
	self machineCodeBuffer
		at: 1
		put: unitSizeLog2MinusOne << 30
			+ (2r111000001 << 21)
			+ (RISCTempReg << 16)
			+ (UXTX << 13)
			+ (1 << 11)
			+ (baseReg << 5)
			+ sourceReg.
	^8! !

!CogIA32Compiler methodsFor: 'accessing' stamp: 'cb 10/26/2026 22:30'!
machineCodeAt: anOffset
	^self machineCodeBuffer at: anOffset! !

!CogIA32Compiler methodsFor: 'generate machine code' stamp: 'cb 10/26/2026 22:30'!
sizePCDependentInstructionAt: eventualAbsoluteAddress
	"Size a jump and set its address.  The target may be another instruction
	 or an absolute address.  On entry the address inst var holds our virtual
	 address. On exit address is set to eventualAbsoluteAddress, which is
	 where this instruction will be output.  The span of a jump to a following
	 instruction is therefore between that instruction's address and this
	 instruction's address ((which are both still their virtual addresses), but the
	 span of a jump to a preceding instruction or to an absolute address is
	 between that instruction's address (which by now is its eventual absolute
	 address) or absolute address and eventualAbsoluteAddress."

	| target maximumSpan abstractInstruction |
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	opcode = AlignmentNops ifTrue:
		[| alignment |
		 self address: eventualAbsoluteAddress.
		 alignment := operands at: 0.
		 ^machineCodeSize := (eventualAbsoluteAddress + (alignment - 1) bitAnd: alignment negated)
							   - eventualAbsoluteAddress].
	self assert: self isJump.
	target := operands at: 0.
	abstractInstruction := cogit cCoerceSimple: target to: #'AbstractInstruction *'.
	(self isAnInstruction: abstractInstruction)
		ifTrue:
			[maximumSpan := abstractInstruction address
							- (((cogit abstractInstruction: self follows: abstractInstruction)
								ifTrue: [eventualAbsoluteAddress]
								ifFalse: [self address]) + 2)]
		ifFalse:
			[maximumSpan := target - (eventualAbsoluteAddress + 2)].
	self address: eventualAbsoluteAddress.
	^machineCodeSize := opcode >= FirstShortJump
							ifTrue:
								[(self isQuick: maximumSpan)
									ifTrue: [2]
									ifFalse: [opcode = Jump
												ifTrue: [5]
												ifFalse: [6]]]
							ifFalse:
								[(opcode = JumpLong or: [opcode = JumpFull])
									ifTrue: [5]
									ifFalse: [6]]! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeAddCwR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	reg = EAX ifTrue:
		[self machineCodeBuffer at: 0 put: 16r05.
		 self machineCodeBuffer at: 1 put: (value bitAnd: 16rFF).
		 self machineCodeBuffer at: 2 put: (value >> 8 bitAnd: 16rFF).
		 self machineCodeBuffer at: 3 put: (value >> 16 bitAnd: 16rFF).
		 self machineCodeBuffer at: 4 put: (value >> 24 bitAnd: 16rFF).
		 ^5].
	self machineCodeBuffer at: 0 put: 16r81.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: 0).
	self machineCodeBuffer at: 2 put: (value bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (value >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (value >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (value >> 24 bitAnd: 16rFF).
	 ^6! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeAddcRR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	"Assemble the ADC instruction"
	| regLHS regRHS |
	regLHS := operands at: 0.
	regRHS := operands at: 1.
	self machineCodeBuffer at: 0 put: 16r13.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: regLHS RO: regRHS).
	^2! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeAlignmentNops
	<inline: true>
	self flag: 'if performance is an issue generate longer nops'.
	0 to: machineCodeSize - 1 do:
		[:i|
		self machineCodeBuffer at: i put: 16r90].
	^machineCodeSize! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeAndCwR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	reg = EAX ifTrue:
		[self machineCodeBuffer at: 0 put: 16r25.
		 self machineCodeBuffer at: 1 put: (value bitAnd: 16rFF).
		 self machineCodeBuffer at: 2 put: (value >> 8 bitAnd: 16rFF).
		 self machineCodeBuffer at: 3 put: (value >> 16 bitAnd: 16rFF).
		 self machineCodeBuffer at: 4 put: (value >> 24 bitAnd: 16rFF).
		 ^5].
	self machineCodeBuffer at: 0 put: 16r83.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: 4).
	self machineCodeBuffer at: 2 put: (value bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (value >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (value >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (value >> 24 bitAnd: 16rFF).
	 ^6! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeArithCqRWithRO: regOpcode eaxOpcode: eaxOpcode
	"Will get inlined into concretizeAt: switch."
	<inline: false>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	(self isQuick: value) ifTrue:
		[self machineCodeBuffer at: 0 put: 16r83.
		 self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: regOpcode).
		 self machineCodeBuffer at: 2 put: (value bitAnd: 16rFF).
		 ^3].
	reg = EAX ifTrue:
		[self machineCodeBuffer at: 0 put: eaxOpcode.
		 self machineCodeBuffer at: 1 put: (value bitAnd: 16rFF).
		 self machineCodeBuffer at: 2 put: (value >> 8 bitAnd: 16rFF).
		 self machineCodeBuffer at: 3 put: (value >> 16 bitAnd: 16rFF).
		 self machineCodeBuffer at: 4 put: (value >> 24 bitAnd: 16rFF).
		 ^5].
	self machineCodeBuffer at: 0 put: 16r81.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: regOpcode).
	self machineCodeBuffer at: 2 put: (value bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (value >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (value >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (value >> 24 bitAnd: 16rFF).
	 ^6

	"cogit processor disassembleInstructionAt: 0 In: machineCode object"! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeArithmeticShiftRightCqR
	<inline: true>
	| shiftCount reg |
	shiftCount := (operands at: 0) min: 31.
	reg := operands at: 1.
	shiftCount = 1 ifTrue:
		[self machineCodeBuffer at: 0 put: 16rD1.
		 self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: 7).
		^2].

	self machineCodeBuffer at: 0 put: 16rC1.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: 7).
	self machineCodeBuffer at: 2 put: shiftCount.
	^3! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeArithmeticShiftRightRR
	"On the x86 the only instructions that shift by the value of a
	 register require the shift count to be  in %ecx.  So we may
	 have to use swap instructions to get the count into %ecx."
	<inline: true>
	| shiftCountReg destReg regToShift |
	shiftCountReg := operands at: 0.
	destReg := operands at: 1.
	shiftCountReg = ECX ifTrue:
		[self machineCodeBuffer at: 0 put: 16rD3.
		 self machineCodeBuffer at: 1 put: (self mod: ModReg RM: destReg RO: 7).
		 ^2].
	regToShift := destReg == shiftCountReg
					ifTrue: [ECX]
					ifFalse: [destReg = ECX
								ifTrue: [shiftCountReg]
								ifFalse: [destReg]].
	shiftCountReg = EAX ifTrue:
		[self machineCodeBuffer at: 0 put: 16r90 + ECX. "XCHG EAX,ECX"
		 self machineCodeBuffer at: 1 put: 16rD3. "SAR ECX,EAX"
		 self machineCodeBuffer at: 2 put: (self mod: ModReg RM: regToShift RO: 7).
		 self machineCodeBuffer at: 3 put: 16r90 + ECX. "XCHG EAX,ECX"
		 ^4].
	self machineCodeBuffer at: 0 put: 16r87. "XCHG E?X,ECX"
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: ECX RO: shiftCountReg).
	self machineCodeBuffer at: 2 put: 16rD3. "SAR ECX,E!!X"
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: regToShift RO: 7).
	self machineCodeBuffer at: 4 put: 16r87. "XCHG E?X,ECX"
	self machineCodeBuffer at: 5 put: (self mod: ModReg RM: ECX RO: shiftCountReg).
	^6! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeCall
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| offset |
	self assert: (operands at: 0) ~= 0.
	offset := (operands at: 0) signedIntFromLong - (self address + 5) signedIntFromLong.
	self machineCodeBuffer at: 0 put: 16rE8.
	self machineCodeBuffer at: 1 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 2 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (offset >> 24 bitAnd: 16rFF).
	^5! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeCallR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg |
	"CmpRR RHS LHS computes LHS - RHS, i.e. apparently reversed.  You have to think subtract."
	reg := operands at: 0.
	self machineCodeBuffer at: 0 put: 16rFF.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: 2).
	^2! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeClzRR
	"Count leading zeros
	 First operand is input (mask)
	 Second operand is output (dest)"
	"LZCNT"
	<inline: true>
	| maskReg dest |
	self assert: self hasLZCNTInstructions.
	maskReg := operands at: 0.
	dest := operands at: 1.
	self machineCodeBuffer at: 0 put: 16rF3.
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16rBD.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: maskReg RO: dest).
	 ^4! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeCmpCwR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	reg = EAX ifTrue:
		[self machineCodeBuffer at: 0 put: 16r3D.
		 self machineCodeBuffer at: 1 put: (value bitAnd: 16rFF).
		 self machineCodeBuffer at: 2 put: (value >> 8 bitAnd: 16rFF).
		 self machineCodeBuffer at: 3 put: (value >> 16 bitAnd: 16rFF).
		 self machineCodeBuffer at: 4 put: (value >> 24 bitAnd: 16rFF).
		 ^5].
	self machineCodeBuffer at: 0 put: 16r81.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: 7).
	self machineCodeBuffer at: 2 put: (value bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (value >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (value >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (value >> 24 bitAnd: 16rFF).
	 ^6! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeCmpRdRd
	"Will get inlined into concretizeAt: switch.
	 We use UCOMISD (see p 4-260 [2])"
	<inline: true>
	| regLHS regRHS |
	"CmpRR RHS LHS computes LHS - RHS, i.e. apparently reversed.  You have to think subtract."
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	self machineCodeBuffer at: 0 put: 16r66.
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16r2E.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^4! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeCmpRsRs
	"Will get inlined into concretizeAt: switch.
	 We use UCOMISS (see p 4-260 [2])"
	<inline: true>
	| regLHS regRHS |
	"CmpRR RHS LHS computes LHS - RHS, i.e. apparently reversed.  You have to think subtract."
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	self machineCodeBuffer at: 0 put: 16r0F.
	self machineCodeBuffer at: 1 put: 16r2E.
	self machineCodeBuffer at: 2 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^3! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConditionalJump: conditionCode
	"Will get inlined into concretizeAt: switch."
	"Sizing/generating jumps.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: true>
	| offset |
	offset := self computeJumpTargetOffsetPlus: 2.
	(machineCodeSize = 0 "size not determined because no sizeJump pass; generating initial trampolines"
		ifTrue: [self isQuick: offset]
		ifFalse: [machineCodeSize = 2]) ifTrue:
		[self machineCodeBuffer at: 0 put: 16r70 + conditionCode.
		 self machineCodeBuffer at: 1 put: (offset bitAnd: 16rFF).
		 ^2].
	^self concretizeConditionalJumpLong: conditionCode! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConditionalJumpLong: conditionCode
	"Will get inlined into concretizeAt: switch."
	"Sizing/generating jumps.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: true>
	| offset |
	offset := self computeJumpTargetOffsetPlus: 6.
	self machineCodeBuffer at: 0 put: 16r0F.
	self machineCodeBuffer at: 1 put: 16r80 + conditionCode.
	self machineCodeBuffer at: 2 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (offset >> 24 bitAnd: 16rFF).
	^6! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConvertRRd
	"Will get inlined into concretizeAt: switch."
	"CVTSI2D"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: 16rF2.
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16r2A.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^4! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConvertRRs
	"Will get inlined into concretizeAt: switch."
	"CVTSI2SS"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: 16rF3.
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16r2A.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^4! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConvertRdR
	"Will get inlined into concretizeAt: switch."
	"CVTSD2SI"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at:0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: 16rF2.
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16r2D.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^4! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConvertRdRs
	"Will get inlined into concretizeAt: switch."
	"CVTSD2SS"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: 16rF2.
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16r5A.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^4! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConvertRsR
	"Will get inlined into concretizeAt: switch."
	"CVTSS2SI"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: 16rF3.
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16r2D.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^4! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConvertRsRd
	"Will get inlined into concretizeAt: switch."
	"CVTSS2SD"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: 16rF3.
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16r5A.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: srcReg RO: destReg).
	 ^4! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeFill32
	<inline: true>
	| word |
	<var: #word type: #'usqIntptr_t'>
	word := operands at: 0.
	self machineCodeBuffer at: 0 put: (word bitAnd: 16rFF).
	self machineCodeBuffer at: 1 put: (word >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 2 put: (word >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (word >> 24 bitAnd: 16rFF).
	^4! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeJump
	"Will get inlined into concretizeAt: switch."
	"Sizing/generating jumps.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: true>
	| jumpTarget offset |
	<var: #jumpTarget type: #'AbstractInstruction *'>
	jumpTarget := cogit cCoerceSimple: (operands at: 0) to: #'AbstractInstruction *'.
	cogit assertSaneJumpTarget: jumpTarget.
	(self isAnInstruction: jumpTarget) ifTrue:
		[jumpTarget := cogit cCoerceSimple: jumpTarget address to: #'AbstractInstruction *'].
	self assert: jumpTarget ~= 0.
	offset := jumpTarget signedIntFromLong - (self address + 2) signedIntFromLong.
	(machineCodeSize = 0 "size not determined because no sizeJump pass; generating initial trampolines"
		ifTrue: [self isQuick: offset]
		ifFalse: [machineCodeSize = 2]) ifTrue:
		[self machineCodeBuffer at: 0 put: 16rEB.
		 self machineCodeBuffer at: 1 put: (offset bitAnd: 16rFF).
		 ^2].
	offset := jumpTarget signedIntFromLong - (self address + 5) signedIntFromLong.
	self machineCodeBuffer at: 0 put: 16rE9.
	self machineCodeBuffer at: 1 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 2 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (offset >> 24 bitAnd: 16rFF).
	^5! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeJumpLong
	"Will get inlined into concretizeAt: switch."
	"Sizing/generating jumps.
		Jump targets can be to absolute addresses or other abstract instructions.
		Generating initial trampolines instructions may have no maxSize and be to absolute addresses.
		Otherwise instructions must have a machineCodeSize which must be kept to."
	<inline: true>
	| jumpTarget offset |
	<var: #jumpTarget type: #'AbstractInstruction *'>
	jumpTarget := cogit cCoerceSimple: (operands at: 0) to: #'AbstractInstruction *'.
	(self isAnInstruction: jumpTarget) ifTrue:
		[jumpTarget := cogit cCoerceSimple: jumpTarget address to: #'AbstractInstruction *'].
	self assert: jumpTarget ~= 0.
	offset := jumpTarget signedIntFromLong - (self address + 5) signedIntFromLong.
	self machineCodeBuffer at: 0 put: 16rE9.
	self machineCodeBuffer at: 1 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 2 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (offset >> 24 bitAnd: 16rFF).
	^5! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeJumpR
	<inline: true>
	| reg |
	reg := operands at: 0.
	self machineCodeBuffer at: 0 put: 16rFF.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: 4).
	^2! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeLoadEffectiveAddressMwrR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	srcReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[self machineCodeBuffer at: 0 put: 16r8D.
			 self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
			 self machineCodeBuffer at: 2 put: (offset bitAnd: 16rFF).
			 ^3].
		self machineCodeBuffer at: 0 put: 16r8D.
		self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
		self machineCodeBuffer at: 2 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 3 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 4 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 24 bitAnd: 16rFF).
		^6].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: 0 put: 16r8D.
		 self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
		 self machineCodeBuffer at: 2 put: (self s: SIB1 i: 4 b: srcReg).
		 self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
		 ^4].
	self machineCodeBuffer at: 0 put: 16r8D.
	self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
	self machineCodeBuffer at: 2 put: (self s: SIB1 i: 4 b: srcReg).
	self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 24 bitAnd: 16rFF).
	^7! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeLogicalShiftLeftCqR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| distance reg |
	distance := (operands at: 0) min: 31.
	reg := operands at: 1.
	distance = 1 ifTrue:
		[self machineCodeBuffer at: 0 put: 16rD1.
		 self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: 4).
		 ^2].
	self machineCodeBuffer at: 0 put: 16rC1.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: 4).
	self machineCodeBuffer at: 2 put: distance.
	^3! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeLogicalShiftLeftRR
	<inline: true>
	"On the x86 the only instructions that shift by the value of a
	 register require the shift count to be  in %ecx.  So we may
	 have to use swap instructions to get the count into %ecx."
	| shiftCountReg destReg regToShift |
	shiftCountReg := operands at: 0.
	destReg := operands at: 1.
	shiftCountReg = ECX ifTrue:
		[self machineCodeBuffer at: 0 put: 16rD3.
		 self machineCodeBuffer at: 1 put: (self mod: ModReg RM: destReg RO: 4).
		 ^2].
	regToShift := destReg == shiftCountReg
					ifTrue: [ECX]
					ifFalse: [destReg = ECX
								ifTrue: [shiftCountReg]
								ifFalse: [destReg]].
	shiftCountReg = EAX ifTrue:
		[self machineCodeBuffer at: 0 put: 16r90 + ECX. "XCHG EAX,ECX"
		 self machineCodeBuffer at: 1 put: 16rD3. "SAR ECX,EAX"
		 self machineCodeBuffer at: 2 put: (self mod: ModReg RM: regToShift RO: 4).
		 self machineCodeBuffer at: 3 put: 16r90 + ECX. "XCHG EAX,ECX"
		 ^4].
	self machineCodeBuffer at: 0 put: 16r87. "XCHG E?X,ECX"
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: ECX RO: shiftCountReg).
	self machineCodeBuffer at: 2 put: 16rD3. "SAR ECX,E!!X"
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: regToShift RO: 4).
	self machineCodeBuffer at: 4 put: 16r87. "XCHG E?X,ECX"
	self machineCodeBuffer at: 5 put: (self mod: ModReg RM: ECX RO: shiftCountReg).
	^6! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeLogicalShiftRightCqR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| distance reg |
	distance := (operands at: 0) min: 31.
	reg := operands at: 1.
	distance = 1 ifTrue:
		[self machineCodeBuffer at: 0 put: 16rD1.
		 self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: 5).
		 ^2].
	self machineCodeBuffer at: 0 put: 16rC1.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: 5).
	self machineCodeBuffer at: 2 put: distance.
	^3! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveAbR
	"N.B. we zero-extend because we state byteReadsZeroExtend."
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg |
	addressOperand := operands at: 0.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	reg := operands at: 1.
	self machineCodeBuffer at: 0 put: 16r0F.
	self machineCodeBuffer at: 1 put: 16rB6.
	self machineCodeBuffer at: 2 put: (self mod: ModRegInd RM: 5 RO: reg).
	self machineCodeBuffer at: 3 put: (addressOperand bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (addressOperand >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (addressOperand >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (addressOperand >> 24 bitAnd: 16rFF).
	^7! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveAwR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg |
	addressOperand := operands at: 0.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	reg := operands at: 1.
	reg = EAX ifTrue:
		[self machineCodeBuffer at: 0 put: 16rA1.
		 self machineCodeBuffer at: 1 put: (addressOperand bitAnd: 16rFF).
		 self machineCodeBuffer at: 2 put: (addressOperand >> 8 bitAnd: 16rFF).
		 self machineCodeBuffer at: 3 put: (addressOperand >> 16 bitAnd: 16rFF).
		 self machineCodeBuffer at: 4 put: (addressOperand >> 24 bitAnd: 16rFF).
			^5].
	self machineCodeBuffer at: 0 put: 16r8B.
	self machineCodeBuffer at: 1 put: (self mod: ModRegInd RM: 5 RO: reg).
	self machineCodeBuffer at: 2 put: (addressOperand bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (addressOperand >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (addressOperand >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (addressOperand >> 24 bitAnd: 16rFF).
	^6! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveCqR
	"Will get inlined into concretizeAt: switch.
	 Note that for quick constants, xor reg,reg, movq r8 may be shorter.  But
	 we don't consider it worthwhile and so just provide concretizeMoveCwR."
	<inline: true>
	| reg |
	(operands at: 0) ~= 0 ifTrue:
		[^self concretizeMoveCwR].
	reg := operands at: 1.
	self machineCodeBuffer at: 0 put: 16r31.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: reg).
	^2! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveCwR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value |
	value := operands at: 0.
	self machineCodeBuffer at: 0 put: 16rB8 + (operands at: 1).
	self machineCodeBuffer at: 1 put: (value bitAnd: 16rFF).
	self machineCodeBuffer at: 2 put: (value >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (value >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (value >> 24 bitAnd: 16rFF).
	^5! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveM16rR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	srcReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[self machineCodeBuffer at: 0 put: 16r0F.
			 self machineCodeBuffer at: 1 put: 16rB7.
			 self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
			 self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
			 ^4].
		self machineCodeBuffer at: 0 put: 16r0F.
		self machineCodeBuffer at: 1 put: 16rB7.
		self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
		self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 4 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^7].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: 0 put: 16r0F.
		 self machineCodeBuffer at: 1 put: 16rB7.
		 self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
		 self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: srcReg).
		 self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
		 ^5].
	self machineCodeBuffer at: 0 put: 16r0F.
	self machineCodeBuffer at: 1 put: 16rB7.
	self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
	self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: srcReg).
	self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 put: (offset >> 24 bitAnd: 16rFF).
	^8! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveM32rRs
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	srcReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[self machineCodeBuffer at: 0 put: 16rF3.
			 self machineCodeBuffer at: 1 put: 16r0F.
			 self machineCodeBuffer at: 2 put: 16r10.
			 self machineCodeBuffer at: 3 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
			 self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
			 ^5].
		self machineCodeBuffer at: 0 put: 16rF3.
		self machineCodeBuffer at: 1 put: 16r0F.
		self machineCodeBuffer at: 2 put: 16r10.
		self machineCodeBuffer at: 3 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
		self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 6 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 7 put: (offset >> 24 bitAnd: 16rFF).
		^8].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: 0 put: 16rF3.
		 self machineCodeBuffer at: 1 put: 16r0F.
		 self machineCodeBuffer at: 2 put: 16r10.
		 self machineCodeBuffer at: 3 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
		 self machineCodeBuffer at: 4 put: (self s: SIB1 i: 4 b: srcReg).
		 self machineCodeBuffer at: 5 put: (offset bitAnd: 16rFF).
		 ^6].
	self machineCodeBuffer at: 0 put: 16rF3.
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16r10.
	self machineCodeBuffer at: 3 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
	self machineCodeBuffer at: 4 put: (self s: SIB1 i: 4 b: srcReg).
	self machineCodeBuffer at: 5 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 8 put: (offset >> 24 bitAnd: 16rFF).
	^9! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveM64rRd
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	srcReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[self machineCodeBuffer at: 0 put: 16rF2.
			 self machineCodeBuffer at: 1 put: 16r0F.
			 self machineCodeBuffer at: 2 put: 16r10.
			 self machineCodeBuffer at: 3 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
			 self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
			 ^5].
		self machineCodeBuffer at: 0 put: 16rF2.
		self machineCodeBuffer at: 1 put: 16r0F.
		self machineCodeBuffer at: 2 put: 16r10.
		self machineCodeBuffer at: 3 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
		self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 6 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 7 put: (offset >> 24 bitAnd: 16rFF).
		^8].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: 0 put: 16rF2.
		 self machineCodeBuffer at: 1 put: 16r0F.
		 self machineCodeBuffer at: 2 put: 16r10.
		 self machineCodeBuffer at: 3 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
		 self machineCodeBuffer at: 4 put: (self s: SIB1 i: 4 b: srcReg).
		 self machineCodeBuffer at: 5 put: (offset bitAnd: 16rFF).
		 ^6].
	self machineCodeBuffer at: 0 put: 16rF2.
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16r10.
	self machineCodeBuffer at: 3 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
	self machineCodeBuffer at: 4 put: (self s: SIB1 i: 4 b: srcReg).
	self machineCodeBuffer at: 5 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 8 put: (offset >> 24 bitAnd: 16rFF).
	^9! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveM8rR
	"Will get inlined into concretizeAt: switch."
	"movzwl"
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	srcReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[self machineCodeBuffer at: 0 put: 16r0F.
			 self machineCodeBuffer at: 1 put: 16rB6.
			 self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
			 self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
			 ^4].
		self machineCodeBuffer at: 0 put: 16r0F.
		self machineCodeBuffer at: 1 put: 16rB6.
		self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
		self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 4 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^7].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: 0 put: 16r0F.
		 self machineCodeBuffer at: 1 put: 16rB6.
		 self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
		 self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: srcReg).
		 self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
		 ^5].
	self machineCodeBuffer at: 0 put: 16r0F.
	self machineCodeBuffer at: 1 put: 16rB6.
	self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
	self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: srcReg).
	self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 put: (offset >> 24 bitAnd: 16rFF).
	^8! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveMbrR
	"N.B. we zero-extend because we state byteReadsZeroExtend."
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	srcReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[self machineCodeBuffer at: 0 put: 16r0f.
			 self machineCodeBuffer at: 1 put: 16rb6.
			 self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
			 self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
			 ^4].
		self machineCodeBuffer at: 0 put: 16r0f.
		self machineCodeBuffer at: 1 put: 16rb6.
		self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
		self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 4 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^7].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: 0 put: 16r0f.
		 self machineCodeBuffer at: 1 put: 16rb6.
		 self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
		 self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: srcReg).
		 self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
		 ^5].
	self machineCodeBuffer at: 0 put: 16r0f.
	self machineCodeBuffer at: 1 put: 16rb6.
	self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
	self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: srcReg).
	self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 put: (offset >> 24 bitAnd: 16rFF).
	^8! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveMwrR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	srcReg ~= ESP ifTrue:
		[(offset = 0 and: [srcReg ~= EBP]) ifTrue:
			[self machineCodeBuffer at: 0 put: 16r8B.
			 self machineCodeBuffer at: 1 put: (self mod: ModRegInd RM: srcReg RO: destReg).
			 ^2].
		(self isQuick: offset) ifTrue:
			[self machineCodeBuffer at: 0 put: 16r8B.
			 self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
			 self machineCodeBuffer at: 2 put: (offset bitAnd: 16rFF).
			 ^3].
		self machineCodeBuffer at: 0 put: 16r8B.
		self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
		self machineCodeBuffer at: 2 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 3 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 4 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 24 bitAnd: 16rFF).
		^6].
	"ESP:"
	offset = 0 ifTrue:
		[self machineCodeBuffer at: 0 put: 16r8B.
		 self machineCodeBuffer at: 1 put: (self mod: ModRegInd RM: srcReg RO: destReg).
		 self machineCodeBuffer at: 2 put: (self s: SIB1 i: 4 b: srcReg).
		 ^3].
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: 0 put: 16r8B.
		 self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
		 self machineCodeBuffer at: 2 put: (self s: SIB1 i: 4 b: srcReg).
		 self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
		 ^4].
	self machineCodeBuffer at: 0 put: 16r8B.
	self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
	self machineCodeBuffer at: 2 put: (self s: SIB1 i: 4 b: srcReg).
	self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 24 bitAnd: 16rFF).
	^7! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMovePerfCnt64RRL
	"Generate code for
		0x0: 50				pushl  %eax
		0x1: 52				pushl  %edx
		0x2: 0f 31			rdtsc
		0x4: 89 f8			movl   %edi, %eax
		0x6: 89 f2			movl   %esi, %edx
		0x8: 5a				popl   %edx
	 et al"
	| regLo regHi liveRegisters offset |
	regLo := operands at: 0.
	regHi := operands at: 1.
	liveRegisters := operands at: 2.
	offset := 0.
	(liveRegisters anyMask: (cogit registerMaskFor: EAX)) ifTrue:
		[self machineCodeBuffer at: 0 put: 16r50. "push %eax"
		 offset := offset + 1].
	(liveRegisters anyMask: (cogit registerMaskFor: EDX)) ifTrue:
		[self machineCodeBuffer at: offset put: 16r52. "push %edx"
		 offset := offset + 1].
	"too lazy to define the swap cases for the moment..."
	self deny: (regLo = EDX or: [regHi = EAX]).
	self machineCodeBuffer at: offset		put: 16r0F. "rdtsc"
	self machineCodeBuffer at: offset + 1	put: 16r31.
	offset := offset + 2.
	regHi ~= EDX ifTrue:
		[self machineCodeBuffer at: offset		put: 16r89. "movq	%edx, (=>) %regHi"
		 self machineCodeBuffer at: offset + 1	put: (self mod: ModReg RM: regHi RO: EDX).
		 offset := offset + 2].
	regLo ~= EAX ifTrue:
		[self machineCodeBuffer at: offset + 4	put: 16r89. "movq	%eax, (=>) %regLo"
		 self machineCodeBuffer at: offset + 5	put: (self mod: ModReg RM: regLo RO: EAX).
		 offset := offset + 2].
	(liveRegisters anyMask: (cogit registerMaskFor: EDX)) ifTrue:
		[self machineCodeBuffer at: offset put: 16r5A. "pop %edx"
		 offset := offset + 1].
	(liveRegisters anyMask: (cogit registerMaskFor: EAX)) ifTrue:
		[self machineCodeBuffer at: offset put: 16r58. "pop %eax"
		 offset := offset + 1].
	^offset

	"(liveRegisters anyMask: (cogit registerMaskFor: EAX and: EDX))
		ifTrue:
			[{	cogit processor disassembleInstructionAt: 0 In: machineCode object.
				cogit processor disassembleInstructionAt: 1 In: machineCode object.
				cogit processor disassembleInstructionAt: 2 In: machineCode object.
				cogit processor disassembleInstructionAt: 4 In: machineCode object.
				cogit processor disassembleInstructionAt: 6 In: machineCode object.
				cogit processor disassembleInstructionAt: 8 In: machineCode object.
				cogit processor disassembleInstructionAt: 9 In: machineCode object }]
		ifFalse:
			[{	cogit processor disassembleInstructionAt: 0 In: machineCode object.
				cogit processor disassembleInstructionAt: 2 In: machineCode object.
				cogit processor disassembleInstructionAt: 5 In: machineCode object }]"! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRAb
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg |
	reg := operands at: 0.
	addressOperand := operands at: 1.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	reg = EAX ifTrue:
		[self machineCodeBuffer at: 0 put: 16rA2.
		 self machineCodeBuffer at: 1 put: (addressOperand bitAnd: 16rFF).
		 self machineCodeBuffer at: 2 put: (addressOperand >> 8 bitAnd: 16rFF).
		 self machineCodeBuffer at: 3 put: (addressOperand >> 16 bitAnd: 16rFF).
		 self machineCodeBuffer at: 4 put: (addressOperand >> 24 bitAnd: 16rFF).
			^5].
	self machineCodeBuffer at: 0 put: 16r88.
	self machineCodeBuffer at: 1 put: (self mod: ModRegInd RM: 5 RO: reg).
	self machineCodeBuffer at: 2 put: (addressOperand bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (addressOperand >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (addressOperand >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (addressOperand >> 24 bitAnd: 16rFF).
	^6! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRAw
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand reg |
	reg := operands at: 0.
	addressOperand := operands at: 1.
	(self isAnInstruction: (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *')) ifTrue:
		[addressOperand := (cogit cCoerceSimple: addressOperand to: #'AbstractInstruction *') address].
	reg = EAX ifTrue:
		[self machineCodeBuffer at: 0 put: 16rA3.
		 self machineCodeBuffer at: 1 put: (addressOperand bitAnd: 16rFF).
		 self machineCodeBuffer at: 2 put: (addressOperand >> 8 bitAnd: 16rFF).
		 self machineCodeBuffer at: 3 put: (addressOperand >> 16 bitAnd: 16rFF).
		 self machineCodeBuffer at: 4 put: (addressOperand >> 24 bitAnd: 16rFF).
			^5].
	self machineCodeBuffer at: 0 put: 16r89.
	self machineCodeBuffer at: 1 put: (self mod: ModRegInd RM: 5 RO: reg).
	self machineCodeBuffer at: 2 put: (addressOperand bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (addressOperand >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (addressOperand >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (addressOperand >> 24 bitAnd: 16rFF).
	^6! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRM16r
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 1.
	srcReg := operands at: 0.
	destReg := operands at: 2.
	destReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[self machineCodeBuffer at: 0 put: 16r66.
			 self machineCodeBuffer at: 1 put: 16r89.
			 self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
			 self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
			 ^4].
		self machineCodeBuffer at: 0 put: 16r66.
		self machineCodeBuffer at: 1 put: 16r89.
		self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
		self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 4 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^7].
	self machineCodeBuffer at: 0 put: 16r66.
	self machineCodeBuffer at: 1 put: 16r89.
	self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
	self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: destReg).
	self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 put: (offset >> 24 bitAnd: 16rFF).
	^8! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRMbr
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 1.
	srcReg := operands at: 0.
	destReg := operands at: 2.
	srcReg >= 4 ifTrue: [self error: 'invalid register'].
	destReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[self machineCodeBuffer at: 0 put: 16r88.
			 self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
			 self machineCodeBuffer at: 2 put: (offset bitAnd: 16rFF).
			 ^3].
		self machineCodeBuffer at: 0 put: 16r88.
		self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
		self machineCodeBuffer at: 2 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 3 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 4 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 24 bitAnd: 16rFF).
		^6].
	self machineCodeBuffer at: 0 put: 16r88.
	self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
	self machineCodeBuffer at: 2 put: (self s: SIB1 i: 4 b: destReg).
	self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 24 bitAnd: 16rFF).
	^7! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRMwr
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	srcReg := operands at: 0.
	offset := operands at: 1.
	destReg := operands at: 2.
	destReg ~= ESP ifTrue:
		[(offset = 0 and: [destReg ~= EBP]) ifTrue:
			[self machineCodeBuffer at: 0 put: 16r89.
			 self machineCodeBuffer at: 1 put: (self mod: ModRegInd RM: destReg RO: srcReg).
			 ^2].
		 (self isQuick: offset) ifTrue:
			[self machineCodeBuffer at: 0 put: 16r89.
			 self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
			 self machineCodeBuffer at: 2 put: (offset bitAnd: 16rFF).
			 ^3].
		self machineCodeBuffer at: 0 put: 16r89.
		self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
		self machineCodeBuffer at: 2 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 3 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 4 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 24 bitAnd: 16rFF).
		^6].
	"ESP:"
	offset = 0 ifTrue:
		[self machineCodeBuffer at: 0 put: 16r89.
		 self machineCodeBuffer at: 1 put: (self mod: ModRegInd RM: destReg RO: srcReg).
		 self machineCodeBuffer at: 2 put: (self s: SIB1 i: 4 b: destReg).
		 ^3].
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: 0 put: 16r89.
		 self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
		 self machineCodeBuffer at: 2 put: (self s: SIB1 i: 4 b: destReg).
		 self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
		 ^4].
	self machineCodeBuffer at: 0 put: 16r89.
	self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
	self machineCodeBuffer at: 2 put: (self s: SIB1 i: 4 b: destReg).
	self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 24 bitAnd: 16rFF).
	^7! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRXbrR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| src index base swapreg mcIdx |
	src := operands at: 0.
	index := operands at: 1.
	base := operands at: 2.
	mcIdx := 0.
	swapreg := NoReg.
	src >= 4 ifTrue: "x86 allows movb %rl, mem only with %al, %bl, %cl, %dl, so swap with the first one that isn't used."
		[swapreg := src.
		 index = EAX ifTrue: [index := swapreg].
		 base = EAX ifTrue: [base := swapreg].
		 src := EAX. 
		 mcIdx := 1.
		 self machineCodeBuffer at: 0 put: 16r90 + swapreg].
	base ~= EBP ifTrue:
		[self machineCodeBuffer at: mcIdx + 0 put: 16r88.
		 self machineCodeBuffer at: mcIdx + 1 put: (self mod: ModRegInd RM: 4 RO: src).
		 self machineCodeBuffer at: mcIdx + 2 put: (self s: SIB1 i: index b: base).
		 swapreg ~= NoReg ifTrue:
			[self machineCodeBuffer at: mcIdx + 3 put: 16r90 + swapreg].
		 ^3 + (2 * mcIdx)].
	self machineCodeBuffer at: mcIdx + 0 put: 16r88.
	self machineCodeBuffer at: mcIdx + 1 put: (self mod: ModRegRegDisp8 RM: 4 RO: src).
	self machineCodeBuffer at: mcIdx + 2 put: (self s: SIB1 i: index b: base).
	self machineCodeBuffer at: mcIdx + 3 put: 0.
	swapreg ~= NoReg ifTrue:
		[self machineCodeBuffer at: mcIdx + 4 put: 16r90 + swapreg].
	 ^4 + (2 * mcIdx)! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRXwrR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| index base src |
	src := operands at: 0.
	index := operands at: 1.
	base := operands at: 2.
	base ~= EBP ifTrue:
		[self machineCodeBuffer at: 0 put: 16r89.
		 self machineCodeBuffer at: 1 put: (self mod: ModRegInd RM: 4 RO: src).
		 self machineCodeBuffer at: 2 put: (self s: SIB4 i: index b: base).
		 ^3].
	self machineCodeBuffer at: 0 put: 16r89.
	self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp8 RM: 4 RO: src).
	self machineCodeBuffer at: 2 put: (self s: SIB4 i: index b: base).
	self machineCodeBuffer at: 3 put: 0.
	 ^4! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRdM64r
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	srcReg := operands at: 0.
	offset := operands at: 1.
	destReg := operands at: 2.
	destReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[self machineCodeBuffer at: 0 put: 16rF2.
			 self machineCodeBuffer at: 1 put: 16r0F.
			 self machineCodeBuffer at: 2 put: 16r11.
			 self machineCodeBuffer at: 3 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
			 self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
			 ^5].
		self machineCodeBuffer at: 0 put: 16rF2.
		self machineCodeBuffer at: 1 put: 16r0F.
		self machineCodeBuffer at: 2 put: 16r11.
		self machineCodeBuffer at: 3 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
		self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 6 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 7 put: (offset >> 24 bitAnd: 16rFF).
		^8].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: 0 put: 16rF2.
		 self machineCodeBuffer at: 1 put: 16r0F.
		 self machineCodeBuffer at: 2 put: 16r11.
		 self machineCodeBuffer at: 3 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
		 self machineCodeBuffer at: 4 put: (self s: SIB1 i: 4 b: destReg).
		 self machineCodeBuffer at: 5 put: (offset bitAnd: 16rFF).
		 ^6].
	self machineCodeBuffer at: 0 put: 16rF2.
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16r11.
	self machineCodeBuffer at: 3 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
	self machineCodeBuffer at: 4 put: (self s: SIB1 i: 4 b: destReg).
	self machineCodeBuffer at: 5 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 8 put: (offset >> 24 bitAnd: 16rFF).
	^9! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRdRd
	"Will get inlined into concretizeAt: switch."
	"MOVSD"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: 16rF2.
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16r11.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: destReg RO: srcReg).
	^4! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRsM32r
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	srcReg := operands at: 0.
	offset := operands at: 1.
	destReg := operands at: 2.
	destReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			"MOVSD destReg, srcReg"
			[self machineCodeBuffer at: 0 put: 16rF3.
			 self machineCodeBuffer at: 1 put: 16r0F.
			 self machineCodeBuffer at: 2 put: 16r11.
			 self machineCodeBuffer at: 3 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
			 self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
			 ^5].
		"MOVSD destReg, srcReg"
		self machineCodeBuffer at: 0 put: 16rF3.
		self machineCodeBuffer at: 1 put: 16r0F.
		self machineCodeBuffer at: 2 put: 16r11.
		self machineCodeBuffer at: 3 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
		self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 6 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 7 put: (offset >> 24 bitAnd: 16rFF).
		^8].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: 0 put: 16rF3.
		 self machineCodeBuffer at: 1 put: 16r0F.
		 self machineCodeBuffer at: 2 put: 16r11.
		 self machineCodeBuffer at: 3 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
		 self machineCodeBuffer at: 4 put: (self s: SIB1 i: 4 b: destReg).
		 self machineCodeBuffer at: 5 put: (offset bitAnd: 16rFF).
		 ^6].
	self machineCodeBuffer at: 0 put: 16rF3.
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16r11.
	self machineCodeBuffer at: 3 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
	self machineCodeBuffer at: 4 put: (self s: SIB1 i: 4 b: destReg).
	self machineCodeBuffer at: 5 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 8 put: (offset >> 24 bitAnd: 16rFF).
	^9! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRsRs
	"Will get inlined into concretizeAt: switch."
	"MOVSS"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: 16rF3.
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16r11.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: destReg RO: srcReg).
	^4! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveXbrRR
	"N.B. we zero-extend because we state byteReadsZeroExtend."
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| index base dest |
	index := operands at: 0.
	base := operands at: 1.
	dest := operands at: 2.
	base ~= EBP ifTrue:
		[self machineCodeBuffer at: 0 put: 16r0F.
		 self machineCodeBuffer at: 1 put: 16rB6.
		 self machineCodeBuffer at: 2 put: (self mod: ModRegInd RM: 4 RO: dest).
		 self machineCodeBuffer at: 3 put: (self s: SIB1 i: index b: base).
		 ^4].
	self machineCodeBuffer at: 0 put: 16r0F.
	self machineCodeBuffer at: 1 put: 16rB6.
	self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: 4 RO: dest).
	self machineCodeBuffer at: 3 put: (self s: SIB1 i: index b: base).
	self machineCodeBuffer at: 4 put: 0.
	 ^5! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveXwrRR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| index base dest |
	index := operands at: 0.
	base := operands at: 1.
	dest := operands at: 2.
	base ~= EBP ifTrue:
		[self machineCodeBuffer at: 0 put: 16r8B.
		 self machineCodeBuffer at: 1 put: (self mod: ModRegInd RM: 4 RO: dest).
		 self machineCodeBuffer at: 2 put: (self s: SIB4 i: index b: base).
		 ^3].
	self machineCodeBuffer at: 0 put: 16r8B.
	self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp8 RM: 4 RO: dest).
	self machineCodeBuffer at: 2 put: (self s: SIB4 i: index b: base).
	self machineCodeBuffer at: 3 put: 0.
	 ^4! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMulRR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg1 reg2 |
	reg1 := operands at: 0.
	reg2 := operands at: 1.
	self machineCodeBuffer at: 0 put: 16r0F.
	self machineCodeBuffer at: 1 put: 16rAF.
	self machineCodeBuffer at: 2 put: (self mod: ModReg RM: reg1 RO: reg2).
	^3! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeNegateR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg |
	reg := operands at: 0.
	self machineCodeBuffer at: 0 put: 16rF7.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: 3).
	^2! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeNop
	<inline: true>
	self machineCodeBuffer at: 0 put: 16r90.
	^1! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeNotR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg |
	reg := operands at: 0.
	self machineCodeBuffer at: 0 put: 16rF7.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: 2).
	^2! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeOpRR: x86opcode
	| regLHS regRHS |
	regLHS := operands at: 0.
	regRHS := operands at: 1.
	self machineCodeBuffer at: 0 put: x86opcode.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: regLHS RO: regRHS).
	^2! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeOrCwR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	reg = EAX ifTrue:
		[self machineCodeBuffer at: 0 put: 16r0D.
		 self machineCodeBuffer at: 1 put: (value bitAnd: 16rFF).
		 self machineCodeBuffer at: 2 put: (value >> 8 bitAnd: 16rFF).
		 self machineCodeBuffer at: 3 put: (value >> 16 bitAnd: 16rFF).
		 self machineCodeBuffer at: 4 put: (value >> 24 bitAnd: 16rFF).
		 ^5].
	self machineCodeBuffer at: 0 put: 16r83.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: 1).
	self machineCodeBuffer at: 2 put: (value bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (value >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (value >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (value >> 24 bitAnd: 16rFF).
	 ^6! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizePopR
	<inline: true>
	self machineCodeBuffer at: 0 put: 16r58 + (operands at: 0).
	^1! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizePrefetchAw
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| addressOperand |
	"Note that maxSize has been set to 7 or 0 in computeMaximumSize whether hasSSEInstructions or not"
	maxSize > 0 ifTrue:
		[addressOperand := operands at: 0.
		 self machineCodeBuffer at: 0 put: 16r0f.
		 self machineCodeBuffer at: 1 put: 16r18.
		 self machineCodeBuffer at: 2 put: (self mod: 0 RM: 5 RO: 1). "prefetch0, prefetch using the T0 temporal data hint"
		 self machineCodeBuffer at: 3 put: (addressOperand bitAnd: 16rFF).
		 self machineCodeBuffer at: 4 put: (addressOperand >> 8 bitAnd: 16rFF).
		 self machineCodeBuffer at: 5 put: (addressOperand >> 16 bitAnd: 16rFF).
		 self machineCodeBuffer at: 6 put: (addressOperand >> 24 bitAnd: 16rFF)].
	^maxSize! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizePushCq
	<inline: true>
	| value |
	value := operands at: 0.
	(self isQuick: value) ifTrue:
		[self machineCodeBuffer at: 0 put: 16r6A.
		 self machineCodeBuffer at: 1 put: (value bitAnd: 16rFF).
		^2].
	self machineCodeBuffer at: 0 put: 16r68.
	self machineCodeBuffer at: 1 put: (value bitAnd: 16rFF).
	self machineCodeBuffer at: 2 put: (value >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (value >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (value >> 24 bitAnd: 16rFF).
	^5! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizePushCw
	<inline: true>
	| value |
	value := operands at: 0.
	self machineCodeBuffer at: 0 put: 16r68.
	self machineCodeBuffer at: 1 put: (value bitAnd: 16rFF).
	self machineCodeBuffer at: 2 put: (value >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (value >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (value >> 24 bitAnd: 16rFF).
	^5! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizePushR
	<inline: true>
	self machineCodeBuffer at: 0 put: 16r50 + (operands at: 0).
	^1! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeRetN
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| offset |
	offset := operands at: 0.
	offset = 0 ifTrue:
		[self machineCodeBuffer at: 0 put: 16rC3.
		^1].
	self machineCodeBuffer at: 0 put: 16rC2.
	self machineCodeBuffer at: 1 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 2 put: (offset >> 8).
	^3! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeReverseOpRR: x86opcode
	| regLHS regRHS |
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	self machineCodeBuffer at: 0 put: x86opcode.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: regLHS RO: regRHS).
	^2! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeSEE2OpRdRd: opCode
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS |
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	self machineCodeBuffer at: 0 put: 16rF2.
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: opCode.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^4! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeSEEOpRsRs: opCode
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS |
	regRHS := self operands at: 0.
	regLHS := self operands at: 1.
	self machineCodeBuffer at: 0 put: 16rF3.
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: opCode.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^4! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeSignExtend16RR
	"Will get inlined into concretizeAt: switch."
	"movswl"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: 16r0F.
	self machineCodeBuffer at: 1 put: 16rBF.
	self machineCodeBuffer at: 2 put: (self mod: ModReg RM: srcReg RO: destReg).
	^ 3! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeSignExtend8RR
	"Will get inlined into concretizeAt: switch."
	"movsbl"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: 16r0F.
	self machineCodeBuffer at: 1 put: 16rBE.
	self machineCodeBuffer at: 2 put: (self mod: ModReg RM: srcReg RO: destReg).
	^ 3! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeSqrtRd
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| reg |
	reg := operands at: 0.
	self machineCodeBuffer at: 0 put: 16rF2.
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16r51.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: reg RO: reg).
	^4! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeSqrtRs
	"Will get inlined into concretizeAt: switch."
	"SRTSS"
	<inline: true>
	| reg |
	reg := operands at: 0.
	self machineCodeBuffer at: 0 put: 16rF3.
	self machineCodeBuffer at: 1 put: 16r0F.
	self machineCodeBuffer at: 2 put: 16r51.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: reg RO: reg).
	^4! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeStop
	<inline: true>
	self machineCodeBuffer at: 0 put: 16rCC.
	^1! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeSubCwR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	reg = EAX ifTrue:
		[self machineCodeBuffer at: 0 put: 16r2D.
		 self machineCodeBuffer at: 1 put: (value bitAnd: 16rFF).
		 self machineCodeBuffer at: 2 put: (value >> 8 bitAnd: 16rFF).
		 self machineCodeBuffer at: 3 put: (value >> 16 bitAnd: 16rFF).
		 self machineCodeBuffer at: 4 put: (value >> 24 bitAnd: 16rFF).
		 ^5].
	self machineCodeBuffer at: 0 put: 16r81.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: 5).
	self machineCodeBuffer at: 2 put: (value bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (value >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (value >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (value >> 24 bitAnd: 16rFF).
	 ^6! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeTstCqR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| mask reg |
	mask := operands at: 0.
	reg := operands at: 1.
	((self isQuick: mask) and: [reg < 4]) ifTrue:
		[self machineCodeBuffer at: 0 put: 16rF6.
		 self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: 0).
		 self machineCodeBuffer at: 2 put: (mask bitAnd: 16rFF).
		 ^3].
	reg = EAX ifTrue:
		[self machineCodeBuffer at: 0 put: 16rA9.
		 self machineCodeBuffer at: 1 put: (mask bitAnd: 16rFF).
		 self machineCodeBuffer at: 2 put: (mask >> 8 bitAnd: 16rFF).
		 self machineCodeBuffer at: 3 put: (mask >> 16 bitAnd: 16rFF).
		 self machineCodeBuffer at: 4 put: (mask >> 24 bitAnd: 16rFF).
		 ^5].
	self machineCodeBuffer at: 0 put: 16rF7.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: 0).
	self machineCodeBuffer at: 2 put: (mask bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (mask >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (mask >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (mask >> 24 bitAnd: 16rFF).
	 ^6! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeXorCwR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| value reg |
	value := operands at: 0.
	reg := operands at: 1.
	reg = EAX ifTrue:
		[self machineCodeBuffer at: 0 put: 16r35.
		 self machineCodeBuffer at: 1 put: (value bitAnd: 16rFF).
		 self machineCodeBuffer at: 2 put: (value >> 8 bitAnd: 16rFF).
		 self machineCodeBuffer at: 3 put: (value >> 16 bitAnd: 16rFF).
		 self machineCodeBuffer at: 4 put: (value >> 24 bitAnd: 16rFF).
		 ^5].
	self machineCodeBuffer at: 0 put: 16r81.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg RO: 6).
	self machineCodeBuffer at: 2 put: (value bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (value >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (value >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (value >> 24 bitAnd: 16rFF).
	 ^6! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeXorRdRd
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS |
	regRHS := self operands at: 0.
	regLHS := self operands at: 1.
	self machineCodeBuffer at: 0 put: 16r66.
	self machineCodeBuffer at: 1 put: 16r0f.
	self machineCodeBuffer at: 2 put: 16r57.
	self machineCodeBuffer at: 3 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^4! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeXorRsRs
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS |
	regRHS := self operands at: 0.
	regLHS := self operands at: 1.
	self machineCodeBuffer at: 0 put: 16r0F.
	self machineCodeBuffer at: 1 put: 16r57.
	self machineCodeBuffer at: 2 put: (self mod: ModReg RM: regRHS RO: regLHS).
	^3! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeZeroExtend16RR
	"Will get inlined into concretizeAt: switch."
	"movzwl"
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: 16r0F.
	self machineCodeBuffer at: 1 put: 16rB7.
	self machineCodeBuffer at: 2 put: (self mod: ModReg RM: srcReg RO: destReg).
	^ 3! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeZeroExtend8RR
	"Will get inlined into concretizeAt: switch."
	"movzbl"
	<inline: true>
	| srcReg destReg |
	srcReg := operands at: 0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put: 16r0F.
	self machineCodeBuffer at: 1 put: 16rB6.
	self machineCodeBuffer at: 2 put: (self mod: ModReg RM: srcReg RO: destReg).
	^ 3! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeBSR
	"Bit Scan Reverse
	First operand is input register (mask)
	Second operand is output register (dest)"
	"BSR"
	<inline: true>
	| dest maskReg |
	maskReg := operands at: 0.
	dest := operands at: 1.
	self machineCodeBuffer at: 0 put: 16r0F.
	self machineCodeBuffer at: 1 put: 16rBD.
	self machineCodeBuffer at: 2 put: (self mod: ModReg RM: maskReg RO: dest).
	 ^3! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeCDQ
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	self machineCodeBuffer at: 0 put: 16r99.
	^1! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeCLD
	<inline: true>
	self machineCodeBuffer at: 0 put: 16rFC.
	^1! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeCMPXCHGAwR
	<inline: true>
	| addressOperand reg |
	addressOperand := operands at: 0.
	reg := operands at: 1.
	self machineCodeBuffer at: 0 put: 16r0F.
	self machineCodeBuffer at: 1 put: 16rB1.
	self machineCodeBuffer at: 2 put: (self mod: ModRegInd RM: 5 RO: reg).
	self machineCodeBuffer at: 3 put: (addressOperand bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (addressOperand >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (addressOperand >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (addressOperand >> 24 bitAnd: 16rFF).
	^7! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeCMPXCHGMwrR
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	srcReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[self machineCodeBuffer at: 0 put: 16r0F.
			 self machineCodeBuffer at: 1 put: 16rB1.
			 self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
			 self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
			 ^4].
		self machineCodeBuffer at: 0 put: 16r0F.
		self machineCodeBuffer at: 1 put: 16rB1.
		self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
		self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 4 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 6 put: (offset >> 24 bitAnd: 16rFF).
		^7].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: 0 put: 16r0F.
		 self machineCodeBuffer at: 1 put: 16rB1.
		 self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
		 self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: srcReg).
		 self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
		 ^5].
	self machineCodeBuffer at: 0 put: 16r0F.
	self machineCodeBuffer at: 1 put: 16rB1.
	self machineCodeBuffer at: 2 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
	self machineCodeBuffer at: 3 put: (self s: SIB1 i: 4 b: srcReg).
	self machineCodeBuffer at: 4 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 7 put: (offset >> 24 bitAnd: 16rFF).
	^8! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeCMPXCHGRAw
	<inline: true>
	| addressOperand reg |
	reg := operands at: 0.
	addressOperand := operands at: 1.
	self machineCodeBuffer at: 0 put: 16r0F.
	self machineCodeBuffer at: 1 put: 16rB1.
	self machineCodeBuffer at: 2 put: (self mod: ModRegInd RM: 5 RO: reg).
	self machineCodeBuffer at: 3 put: (addressOperand bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (addressOperand >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (addressOperand >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (addressOperand >> 24 bitAnd: 16rFF).
	"cogit processor disassembleInstructionAt: 0 In: machineCode object"
	^7! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeCPUID
	<inline: true>
	self machineCodeBuffer at: 0 put: 16r0F.
	self machineCodeBuffer at: 1 put: 16rA2.
	^2! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeFSTPD
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	srcReg := 3.
	offset := operands at: 0.
	destReg := operands at: 1.
	destReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			"FSTP dest"
			[self machineCodeBuffer at: 0 put: 16rDD.
			 self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
			 self machineCodeBuffer at: 2 put: (offset bitAnd: 16rFF).
			 ^3].
		"FSTP dest"
		self machineCodeBuffer at: 0 put: 16rDD.
		self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
		self machineCodeBuffer at: 2 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 3 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 4 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 24 bitAnd: 16rFF).
		^6].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: 0 put: 16rDD.
		 self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
		 self machineCodeBuffer at: 2 put: (self s: SIB1 i: 4 b: destReg).
		 self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
		 ^4].
	self machineCodeBuffer at: 0 put: 16rDD.
	self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
	self machineCodeBuffer at: 2 put: (self s: SIB1 i: 4 b: destReg).
	self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 24 bitAnd: 16rFF).
	^7! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeFSTPS
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg offset destReg |
	srcReg := 3.
	offset := operands at: 0.
	destReg := operands at: 1.
	destReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			"FSTP dest"
			[self machineCodeBuffer at: 0 put: 16rD9.
			 self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
			 self machineCodeBuffer at: 2 put: (offset bitAnd: 16rFF).
			 ^3].
		"FSTP dest"
		self machineCodeBuffer at: 0 put: 16rD9.
		self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
		self machineCodeBuffer at: 2 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 3 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 4 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 24 bitAnd: 16rFF).
		^6].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: 0 put: 16rD9.
		 self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp8 RM: destReg RO: srcReg).
		 self machineCodeBuffer at: 2 put: (self s: SIB1 i: 4 b: destReg).
		 self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
		 ^4].
	self machineCodeBuffer at: 0 put: 16rD9.
	self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp32 RM: destReg RO: srcReg).
	self machineCodeBuffer at: 2 put: (self s: SIB1 i: 4 b: destReg).
	self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 24 bitAnd: 16rFF).
	^7! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeIDIVR
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regDivisor |
	regDivisor := operands at: 0.
	self machineCodeBuffer at: 0 put: 16rF7.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: regDivisor RO: 7).
	^2! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeMOVSB
	<inline: true>
	self machineCodeBuffer at: 0 put: 16rA4.
	^1! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeMOVSD
	<inline: true>
	self machineCodeBuffer at: 0 put: 16rA5.
	^1! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeREP
	<inline: true>
	self machineCodeBuffer at: 0 put: 16rF3.
	^1! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeXCHGAwR
	<inline: true>
	| addressOperand reg |
	addressOperand := operands at: 0.
	reg := operands at: 1.
	self machineCodeBuffer at: 0 put: 16r87.
	self machineCodeBuffer at: 1 put: (self mod: ModRegInd RM: 5 RO: reg).
	self machineCodeBuffer at: 2 put: (addressOperand bitAnd: 16rFF).
	self machineCodeBuffer at: 3 put: (addressOperand >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (addressOperand >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (addressOperand >> 24 bitAnd: 16rFF).
	^6! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeXCHGMwrR
	<inline: true>
	| srcReg offset destReg |
	offset := operands at: 0.
	srcReg := operands at: 1.
	destReg := operands at: 2.
	srcReg ~= ESP ifTrue:
		[(self isQuick: offset) ifTrue:
			[self machineCodeBuffer at: 0 put: 16r87.
			 self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
			 self machineCodeBuffer at: 2 put: (offset bitAnd: 16rFF).
			 ^3].
		self machineCodeBuffer at: 0 put: 16r87.
		self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
		self machineCodeBuffer at: 2 put: (offset bitAnd: 16rFF).
		self machineCodeBuffer at: 3 put: (offset >> 8 bitAnd: 16rFF).
		self machineCodeBuffer at: 4 put: (offset >> 16 bitAnd: 16rFF).
		self machineCodeBuffer at: 5 put: (offset >> 24 bitAnd: 16rFF).
		^6].
	"ESP:"
	(self isQuick: offset) ifTrue:
		[self machineCodeBuffer at: 0 put: 16r87.
		 self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp8 RM: srcReg RO: destReg).
		 self machineCodeBuffer at: 2 put: (self s: SIB1 i: 4 b: srcReg).
		 self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
		 ^4].
	self machineCodeBuffer at: 0 put: 16r87.
	self machineCodeBuffer at: 1 put: (self mod: ModRegRegDisp32 RM: srcReg RO: destReg).
	self machineCodeBuffer at: 2 put: (self s: SIB1 i: 4 b: srcReg).
	self machineCodeBuffer at: 3 put: (offset bitAnd: 16rFF).
	self machineCodeBuffer at: 4 put: (offset >> 8 bitAnd: 16rFF).
	self machineCodeBuffer at: 5 put: (offset >> 16 bitAnd: 16rFF).
	self machineCodeBuffer at: 6 put: (offset >> 24 bitAnd: 16rFF).
	^7! !

!CogIA32Compiler methodsFor: 'generate machine code - concretize processor-specific' stamp: 'cb 10/26/2026 22:30'!
concretizeXCHGRR
	<inline: true>
	| reg1 reg2 |
	reg1 := operands at: 0.
	reg2 := operands at: 1.
	reg2 = EAX ifTrue:
		[reg2 := reg1.
		 reg1 := EAX].
	reg1 = EAX ifTrue:
		[self machineCodeBuffer at: 0 put: 16r90 + reg2.
		 ^1].
	self machineCodeBuffer at: 0 put: 16r87.
	self machineCodeBuffer at: 1 put: (self mod: ModReg RM: reg1 RO: reg2).
	^2! !

!CogARMCompiler methodsFor: 'accessing' stamp: 'cb 10/26/2026 22:30'!
machineCodeAt: anOffset
	"read aWord from machineCode, with little endian"
	<inline: true>
	^self machineCodeBuffer at: anOffset // 4! !

!CogARMCompiler methodsFor: 'accessing' stamp: 'cb 10/26/2026 22:30'!
machineCodeAt: anOffset put: aWord
	"add aWord to machineCode, with little endian"
	<inline: true>
	self machineCodeBuffer at: anOffset // 4 put: aWord! !

!CogARMCompiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeAddRdRd
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	"Add FP regRHS to FP regLHS and stick result in FP regLHS"
	| regLHS regRHS |
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	self machineCodeBuffer at: 0 put:(self faddd: regLHS with: regRHS).
	^4
	! !

!CogARMCompiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeCall
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	"Call is used only for calls within code-space, See CallFull for general anywhere in address space calling"
	| offset |
	self assert: (operands at: 0) ~= 0.
	self assert: (operands at: 0) \\ 4 = 0.
	offset := (operands at: 0) signedIntFromLong - (self address + 8 "normal pc offset") signedIntFromLong.
	self assert: (self isInImmediateJumpRange: offset). "+- 24Mb is plenty of range in code space"
	self machineCodeAt: 0 put: (self bl: offset).
	^4! !

!CogARMCompiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeCmpRdRd
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	"Compare FP regB with FP regA and leave the FP status reg ready to be transferred back to ARM with next instruction"
	| regB regA |
	regA := operands at:0.
	regB := operands at: 1.
	self machineCodeBuffer at: 0 put:(self fcmpFrom: regB to: regA).
	^4
		
! !

!CogARMCompiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeConvertRRd
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| srcReg destReg |
	srcReg := operands at:0.
	destReg := operands at: 1.
	self machineCodeBuffer at: 0 put:(self fmsrFrom: srcReg to: 9).
	self machineCodeBuffer at: 1 put: (self fsitodFrom: 9 to: destReg). "probably not quite right"
	^8
		
! !

!CogARMCompiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeDivRdRd
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	"FP divide regLHS by regRHS and stick result in regLHS"
	| regLHS regRHS |
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	self machineCodeBuffer at: 0 put:(self fdivd: regLHS by: regRHS).
	^4
	! !

!CogARMCompiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveM64rRd
	"Will get inlined into concretizeAt: switch."	
	<inline: true>
	"Load a float from srcReg+offset into FP destReg"
	| srcReg offset destReg u|
	offset := operands at: 0.
	u := offset >0 ifTrue:[1] ifFalse:[0].
	srcReg := operands at: 1.
	destReg := operands at: 2.
	self machineCodeBuffer at: 0 put: (self fldd: destReg rn: srcReg plus: u imm: offset>>2).
	^4
! !

!CogARMCompiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMoveRdM64r
	"Will get inlined into concretizeAt: switch."	
	<inline: true>
	"Store FP fpReg to dstReg+offset"
	| dstReg offset fpReg u|
	offset := operands at: 1.
	u := offset >0 ifTrue:[1] ifFalse:[0].
	dstReg := operands at: 2.
	fpReg := operands at: 0.
	self machineCodeBuffer at: 0 put: (self fstd: fpReg rn: dstReg plus: u imm: offset>>2).
	^4
! !

!CogARMCompiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeMulRdRd
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	"FP multiply regLHS by regRHS and stick result in regLHS"
	| regLHS regRHS |
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	self machineCodeBuffer at: 0 put:(self fmuld: regLHS with: regRHS).
	^4
	! !

!CogARMCompiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizePushOrPopMultipleRegisters: doPush
	self assert: (operands at: 0) ~= 0.
	self machineCodeBuffer at: 0 put: AL << 28
						  + (doPush     "2r100PUSWL"
								ifTrue: [2r10010010 << 20]
								ifFalse: [2r10001011 << 20])
						  + (SP << 16)
						  + (operands at: 0).
	^4! !

!CogARMCompiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeSqrtRd
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	"Square root of FP regLHS into regLHS"
	| regLHS  |
	regLHS := operands at: 0.
	self machineCodeBuffer at: 0 put:(self fsqrtd: regLHS).
	^4
	! !

!CogARMCompiler methodsFor: 'generate machine code - concretize' stamp: 'cb 10/26/2026 22:30'!
concretizeSubRdRd
	"Will get inlined into concretizeAt: switch."
	<inline: true>
	| regLHS regRHS |
	"Subtract FP regRHS from FP regLHS and leave the result in FP regLHS"
	regRHS := operands at: 0.
	regLHS := operands at: 1.
	self machineCodeBuffer at: 0 put:(self fsubd: regLHS with: regRHS).
	^4
	! !

!CogARMCompiler methodsFor: 'generate machine code - support' stamp: 'cb 10/26/2026 22:30'!
loadCwInto: destReg
	"Load the operand into the destination register, answering
	 the size of the instructions generated to do so."
	| operand distance |
	operand := operands at: 0.
	self cCode:[] inSmalltalk:[operand := operand bitAnd: 16rFFFFFFFF]. "Need to clamp the value to a word size since one or two usages actually generate double sized values and rely upon the C code to narrow it within the running VM"
	(self isAnInstruction: (cogit cCoerceSimple: operand to: #'AbstractInstruction *')) ifTrue:
		[operand := (cogit cCoerceSimple: operand to: #'AbstractInstruction *') address].
	"First try and encode as a pc-relative reference..."
	(cogit addressIsInCurrentCompilation: operand) ifTrue:
		[distance := operand - (self address + 8).
		 self rotateable8bitSignedImmediate: distance
		 	ifTrue:
				[:rot :immediate :negate|
		 		 self machineCodeAt: 0 put: (negate
												ifTrue: [self sub: destReg rn: PC imm: immediate ror: rot]
												ifFalse: [self add: destReg rn: PC imm: immediate ror: rot]).
		 		^4]
		 	ifFalse:
		 		[self deny: (self isAnInstruction: (cogit cCoerceSimple: (operands at: 0) to: #'AbstractInstruction *'))]].
	"If this fails, use the conventional literal load sequence."
	^self moveCw: operand intoR: destReg! !

!CogOutOfLineLiteralsARMCompiler methodsFor: 'generate machine code' stamp: 'cb 10/26/2026 22:30'!
concretizeLiteral
	"Generate an out-of-line literal.  Copy the value and any annotation from the stand-in in the literals manager."
	| literalAsInstruction literal |
	literalAsInstruction := cogit cCoerceSimple: (operands at: 0) to: #'AbstractInstruction *'.
	literal := (self isAnInstruction: literalAsInstruction)
				ifTrue: [literalAsInstruction address]
				ifFalse: [self cCode: [literalAsInstruction asUnsignedInteger]
							inSmalltalk: [literalAsInstruction]].
	self assert: (dependent notNil and: [dependent opcode = Literal]).
	dependent annotation ifNotNil:
		[self assert: annotation isNil.
		 annotation := dependent annotation].
	dependent address ifNotNil: [self assert: dependent address = self address].
	dependent address: self address.
	self machineCodeAt: 0 put: literal.
	^4! !

!CogOutOfLineLiteralsARMCompiler methodsFor: 'generate machine code' stamp: 'cb 10/26/2026 22:30'!
mapEntryAddress
	"Typically map entries apply to the end of an instruction, for two reasons:
	  a)	to cope with literals embedded in variable-length instructions, since, e.g.
		on x86, the literal typically comes at the end of the instruction.
	  b)	in-line cache detection is based on return addresses, which are typically
		to the instruction following a call.
	 But on ARM using CogOutOfLineLiteralsARMCompiler we use out-of-line literals
	 so the mapEntryAddress of a literal is simply the instruction's address."
	<inline: true>
	^opcode = Literal
		ifTrue: [self address]
		ifFalse: [self address + machineCodeSize]! !

!CogOutOfLineLiteralsARMCompiler methodsFor: 'generate machine code' stamp: 'cb 10/26/2026 22:30'!
sizePCDependentInstructionAt: eventualAbsoluteAddress
	"Size a jump and set its address.  The target may be another instruction
	 or an absolute address.  On entry the address inst var holds our virtual
	 address. On exit address is set to eventualAbsoluteAddress, which is
	 where this instruction will be output.  The span of a jump to a following
	 instruction is therefore between that instruction's address and this
	 instruction's address ((which are both still their virtual addresses), but the
	 span of a jump to a preceding instruction or to an absolute address is
	 between that instruction's address (which by now is its eventual absolute
	 address) or absolute address and eventualAbsoluteAddress.

	 ARM is simple; the 26-bit call/jump range means no short jumps.  This
	 routine only has to determine the targets of jumps, not determine sizes.

	 This version also deals with out-of-line literals.  If this is the real literal,
	 update the stand-in in literalsManager with the address (because instructions
	 referring to the literal are referring to the stand-in).  If this is annotated with
	 IsObjectReference transfer the annotation to the stand-in, whence it will be
	 transferred to the real literal, simplifying update of literals."

	opcode = AlignmentNops ifTrue:
		[| alignment |
		 self address: eventualAbsoluteAddress.
		 alignment := operands at: 0.
		 ^machineCodeSize := (eventualAbsoluteAddress + (alignment - 1) bitAnd: alignment negated)
							   - eventualAbsoluteAddress].
	self assert: (self isJump or: [opcode = Call or: [opcode = CallFull
				or: [dependent notNil and: [dependent opcode = Literal]]]]).
	self isJump ifTrue: [self resolveJumpTarget].
	self address: eventualAbsoluteAddress.
	(dependent notNil and: [dependent opcode = Literal]) ifTrue:
		[opcode = Literal ifTrue:
			[dependent address: self address].
		 annotation = cogit getIsObjectReference ifTrue:
			[dependent annotation: annotation.
			 annotation := nil]].
	^machineCodeSize := maxSize! !

!CogOutOfLineLiteralsARMCompiler methodsFor: 'generate machine code - support' stamp: 'cb 10/26/2026 22:30'!
moveCw: constant intoR: destReg
	"Emit a load of aWord into destReg.  Answer the number of bytes of machine code generated.
	 Literals are stored out-of-line; emit a LDR with the relevant offset."
	<inline: true>
	self assert: (cogit addressIsInCurrentCompilation: dependent address).
	self assert: (dependent address - (self address + 8)) abs < (1<<12).
	self machineCodeAt: 0
		put: (self
				ldr: destReg
				rn: PC
				plus: (dependent address >= (self address + 8) ifTrue: [1] ifFalse: [0])
				imm: (dependent address - (self address + 8)) abs).
	^4! !

!CogInLineLiteralsARMCompiler methodsFor: 'generate machine code' stamp: 'cb 10/26/2026 22:30'!
sizePCDependentInstructionAt: eventualAbsoluteAddress
	"Size a jump and set its address.  The target may be another instruction
	 or an absolute address.  On entry the address inst var holds our virtual
	 address. On exit address is set to eventualAbsoluteAddress, which is
	 where this instruction will be output.  The span of a jump to a following
	 instruction is therefore between that instruction's address and this
	 instruction's address ((which are both still their virtual addresses), but the
	 span of a jump to a preceding instruction or to an absolute address is
	 between that instruction's address (which by now is its eventual absolute
	 address) or absolute address and eventualAbsoluteAddress.

	 ARM is simple; the 26-bit call/jump range means no short jumps.  This routine
	 only has to determine the targets of jumps, not determine sizes."

	opcode = AlignmentNops ifTrue:
		[| alignment |
		 self address: eventualAbsoluteAddress.
		 alignment := operands at: 0.
		 ^machineCodeSize := (eventualAbsoluteAddress + (alignment - 1) bitAnd: alignment negated)
							   - eventualAbsoluteAddress].
	self assert: (self isJump or: [opcode = Call or: [opcode = CallFull]]).
	self isJump ifTrue: [self resolveJumpTarget].
	self address: eventualAbsoluteAddress.
	^machineCodeSize := maxSize! !

!CogMIPSELCompiler methodsFor: 'accessing' stamp: 'cb 10/26/2026 22:30'!
machineCodeAt: anOffset
	"read aWord from machineCode, with little endian"
	<inline: true>
	^self machineCodeBuffer at: anOffset // 4! !

!CogMIPSELCompiler methodsFor: 'accessing' stamp: 'cb 10/26/2026 22:30'!
machineCodeAt: anOffset put: aWord
	"add aWord to machineCode, with little endian"
	<inline: true>
	self machineCodeBuffer at: anOffset // 4 put: aWord! !

!CogMIPSELCompiler methodsFor: 'generate machine code' stamp: 'cb 10/26/2026 22:30'!
sizePCDependentInstructionAt: eventualAbsoluteAddress
	"Size a jump and set its address.  The target may be another instruction
	 or an absolute address.  On entry the address inst var holds our virtual
	 address. On exit address is set to eventualAbsoluteAddress, which is
	 where this instruction will be output.  The span of a jump to a following
	 instruction is therefore between that instruction's address and this
	 instruction's address ((which are both still their virtual addresses), but the
	 span of a jump to a preceding instruction or to an absolute address is
	 between that instruction's address (which by now is its eventual absolute
	 address) or absolute address and eventualAbsoluteAddress.

	 ARM is simple; the 26-bit call/jump range means no short jumps.  This routine
	 only has to determine the targets of jumps, not determine sizes."

	opcode = AlignmentNops ifTrue:
		[| alignment |
		 self address: eventualAbsoluteAddress.
		 alignment := operands at: 0.
		 ^machineCodeSize := (eventualAbsoluteAddress + (alignment - 1) bitAnd: alignment negated)
							   - eventualAbsoluteAddress].
	self assert: (self isJump or: [opcode = Call or: [opcode = CallFull]]).
	self isJump ifTrue: [self resolveJumpTarget].
	self address: eventualAbsoluteAddress.
	^machineCodeSize := maxSize! !

