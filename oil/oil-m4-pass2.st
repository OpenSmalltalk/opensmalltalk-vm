"Oil Milestone 4: the VM side of Pass 2.  An x64 instruction for Oil's array element loads: movq -1(base,index,1), dest,
 which loads element i (1-based) of an Array, index holding the SmallInteger i, i.e. 8i+1 (element i is at
 base + 8i).  It is added to CogX64Compiler as a processor specific opcode, MoveTaggedXwrRR; other back ends untag
 and scale the index (CogAbstractInstruction>>oilGenMoveTaggedIndex:base:into:scratch:).  Author: cb."!

"Declare MoveTaggedXwrRR as an x64 specific opcode, and size and concretize it, by patching CogX64Compiler class>>initialize,
 CogX64Compiler>>computeMaximumSize and CogX64Compiler>>dispatchConcretizeProcessorSpecific in place (idempotent)."
| patch |
patch := [:class :selector :old :new | | src |
	src := (class >> selector) getSource asString.
	(src includesSubstring: 'MoveTaggedXwrRR') ifFalse:
		[(src includesSubstring: old) ifFalse:
			[self error: 'Oil: cannot patch ', class name, '>>', selector].
		 class
			compile: (src copyReplaceAll: old with: new)
			classified: (class organization categoryOfElement: selector)]].
patch
	value: CogX64Compiler class
	value: #initialize
	value: 'MOVSQ BSR)'
	value: 'MOVSQ BSR
	"Oil array element load:"	MoveTaggedXwrRR)'.
CogX64Compiler initialize.
patch
	value: CogX64Compiler
	value: #computeMaximumSize
	value: '[MOVSQ]'
	value: '[MoveTaggedXwrRR]	-> [^5].
		[MOVSQ]'.
patch
	value: CogX64Compiler
	value: #dispatchConcretizeProcessorSpecific
	value: '[MOVSQ]'
	value: '[MoveTaggedXwrRR]	-> [^self concretizeMoveTaggedXwrRR].
		[MOVSQ]'!

!CogAbstractInstruction methodsFor: '*Cogit-Oil' stamp: 'cb 10/24/2026 16:00'!
oilGenMoveTaggedIndex: indexReg base: baseReg into: destReg scratch: scratchReg
	"Load element i of the Array (no fixed fields) in baseReg, indexReg holding the SmallInteger i, into destReg:
	 untag i into scratchReg and load the word at baseReg + 8i (the header is one word)."
	cogit MoveR: indexReg R: scratchReg.
	cogit ArithmeticShiftRightCq: objectMemory numTagBits R: scratchReg.
	cogit MoveXwr: scratchReg R: baseReg R: destReg! !

!CogX64Compiler methodsFor: '*Cogit-Oil' stamp: 'cb 10/24/2026 16:00'!
oilGenMoveTaggedIndex: indexReg base: baseReg into: destReg scratch: scratchReg
	"Load element i of the Array (no fixed fields) in baseReg, indexReg holding the SmallInteger i (8i+1), into destReg:
	 element i is at baseReg + 8i = baseReg + indexReg - 1, one movq -1(baseReg,indexReg,1), destReg."
	cogit gen: MoveTaggedXwrRR operand: indexReg operand: baseReg operand: destReg! !

!CogX64Compiler methodsFor: '*Cogit-Oil' stamp: 'cb 10/24/2026 16:00'!
concretizeMoveTaggedXwrRR
	"movq -1(base,index,1), dest: REX.W 8B /r, ModRM mod=01 (disp8) rm=100 (SIB), SIB scale 1, disp8 -1.
	 Will get inlined into concretizeAt: switch."
	<inline: true>
	| index base dest |
	index := operands at: 0.
	base := operands at: 1.
	dest := operands at: 2.
	machineCode
		at: 0 put: (self rexR: dest x: index b: base);
		at: 1 put: 16r8B;
		at: 2 put: (self mod: ModRegRegDisp8 RM: 4 RO: dest);
		at: 3 put: (self s: SIB1 i: index b: base);
		at: 4 put: 16rFF.
	^5! !
