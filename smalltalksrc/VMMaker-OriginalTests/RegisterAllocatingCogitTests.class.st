Class {
	#name : #RegisterAllocatingCogitTests,
	#superclass : #TestCase,
	#pools : [
		'CogAbstractRegisters'
	],
	#category : #'VMMaker-OriginalTests'
}

{ #category : #tests }
RegisterAllocatingCogitTests >> testMergeRegisterSwappingForX64InBlockNodeAnalysis [
	"Test the first merge in BlockNode>>#analyseTempsWithin:rootNode:assignmentPools:"
	"self new testMergeRegisterSwappingForX64InBlockNodeAnalysis"
	| cogit fixup start |
	cogit := self x64Cogit.
	cogit
		instVarNamed: 'methodOrBlockNumArgs' put: 3;
		instVarNamed: 'methodOrBlockNumTemps' put: 5;
		initSimStackForFramefulMethod: nil.
	(cogit simStackAt: 0) liveRegister: ReceiverResultReg.
	(cogit simStackAt: 1) liveRegister: Extra4Reg.
	(cogit simStackAt: 5) liveRegister: Extra5Reg.
	cogit ssPushDesc: (cogit simStackAt: 1).
	(fixup := cogit bytecodeFixupClass for: cogit)
		mergeSimStack: cogit copySimStack;
		simStackPtr: (cogit instVarNamed: 'simStackPtr');
		becomeMergeFixup.
	cogit
		ssPop: 1;
		ssPushDesc: (cogit simStackAt: 0).
	(cogit simStackAt: 1) liveRegister: NoReg.
	(cogit simStackAt: 5) liveRegister: Extra5Reg.

	self assert: '
0		(bo FPReg-24 (spilled) (live: ReceiverResultReg))
1		(bo FPReg+32 (spilled))
2		(bo FPReg+24 (spilled))
3		(bo FPReg+16 (spilled))
4		(bo FPReg-32 (spilled))
5		(bo FPReg-40 (spilled) (live: Extra5Reg))
6<-(sb)	(bo FPReg-24 (live: ReceiverResultReg))
'		 equals: cogit simStackPrintString.
	self assert:'
0		(bo FPReg-24 (spilled) (live: ReceiverResultReg))
1		(bo FPReg+32 (spilled) (live: Extra4Reg))
2		(bo FPReg+24 (spilled))
3		(bo FPReg+16 (spilled))
4		(bo FPReg-32 (spilled))
5		(bo FPReg-40 (spilled) (live: Extra5Reg))
6<-		(bo FPReg+32 (live: Extra4Reg))
'		equals: fixup simStackPrintString.

	start := cogit getOpcodeIndex.
	[cogit mergeCurrentSimStackWith: fixup]
		on: AssertionFailure
		do: [:ex|
			self assert: false description: 'assertion failure in cogit'.
			ex resume: nil].

	self assert: '
0		(bo FPReg-24 (spilled) (live: ReceiverResultReg))
1		(bo FPReg+32 (spilled))
2		(bo FPReg+24 (spilled))
3		(bo FPReg+16 (spilled))
4		(bo FPReg-32 (spilled))
5		(bo FPReg-40 (spilled) (live: Extra5Reg))
6<-(sb)	(spill @ FPReg-48 (live: Extra4Reg))
'		 equals: cogit simStackPrintString.

	self assert:  '(MoveRR ReceiverResultReg Extra4Reg)'
		equals: (cogit opcodePrintStringFrom: start to: cogit getOpcodeIndex - 1)
]

{ #category : #tests }
RegisterAllocatingCogitTests >> testMergeRegisterSwappingForX64InSmallIntegerPrinting [
	"self new testMergeRegisterSwappingForX64InSmallIntegerPrinting"
	| cogit fixup start |
	cogit := self x64Cogit.
	cogit
		instVarNamed: 'methodOrBlockNumArgs' put: 4;
		instVarNamed: 'methodOrBlockNumTemps' put: 9;
		initSimStackForFramefulMethod: nil;
		ssPushConstant: (cogit objectMemory integerObjectOf: 0).
	(fixup := cogit bytecodeFixupClass for: cogit)
		mergeSimStack: cogit copySimStack;
		simStackPtr: (cogit instVarNamed: 'simStackPtr');
		becomeMergeFixup.
	(cogit simStackAt: 0) liveRegister: Extra5Reg.
	(cogit simStackAt: 5) liveRegister: Extra4Reg.
	(cogit simStackAt: 7) liveRegister: Extra3Reg.
	(cogit simStack: fixup mergeSimStack at: 10) constant: (cogit objectMemory integerObjectOf: 1).
	(cogit simStack: fixup mergeSimStack at: 5) liveRegister: Extra5Reg.
	(cogit simStack: fixup mergeSimStack at: 7) liveRegister: Extra4Reg.
	(cogit simStack: fixup mergeSimStack at: 10) liveRegister: Extra3Reg.

	self assert: '
0		(bo FPReg-24 (spilled) (live: Extra5Reg))
1		(bo FPReg+40 (spilled))
2		(bo FPReg+32 (spilled))
3		(bo FPReg+24 (spilled))
4		(bo FPReg+16 (spilled))
5		(bo FPReg-32 (spilled) (live: Extra4Reg))
6		(bo FPReg-40 (spilled))
7		(bo FPReg-48 (spilled) (live: Extra3Reg))
8		(bo FPReg-56 (spilled))
9		(bo FPReg-64 (spilled))
10<-(sb)	(const =0 (16r0))
'		 equals: cogit simStackPrintString.
	self assert: '
0		(bo FPReg-24 (spilled))
1		(bo FPReg+40 (spilled))
2		(bo FPReg+32 (spilled))
3		(bo FPReg+24 (spilled))
4		(bo FPReg+16 (spilled))
5		(bo FPReg-32 (spilled) (live: Extra5Reg))
6		(bo FPReg-40 (spilled))
7		(bo FPReg-48 (spilled) (live: Extra4Reg))
8		(bo FPReg-56 (spilled))
9		(bo FPReg-64 (spilled))
10<-		(const =1 (16r1) (live: Extra3Reg))
'		equals: fixup simStackPrintString.

	start := cogit getOpcodeIndex.
	[cogit mergeCurrentSimStackWith: fixup]
		on: AssertionFailure
		do: [:ex|
			self assert: false description: 'assertion failure in cogit'.
			ex resume: nil].

	self assert: '
0		(bo FPReg-24 (spilled))
1		(bo FPReg+40 (spilled))
2		(bo FPReg+32 (spilled))
3		(bo FPReg+24 (spilled))
4		(bo FPReg+16 (spilled))
5		(bo FPReg-32 (spilled) (live: Extra5Reg))
6		(bo FPReg-40 (spilled))
7		(bo FPReg-48 (spilled) (live: Extra4Reg))
8		(bo FPReg-56 (spilled))
9		(bo FPReg-64 (spilled))
10<-(sb)	(reg Extra3Reg)
'		 equals: cogit simStackPrintString.

	self assert:  '(XCHGRR 15 14) (XCHGRR 14 13) (MoveCqR 1 Extra3Reg)'
		equals: (cogit opcodePrintStringFrom: start to: cogit getOpcodeIndex - 1)
]

{ #category : #private }
RegisterAllocatingCogitTests >> x64Cogit [
	^RegisterAllocatingCogit initializedInstanceForTests: #(ObjectMemory Spur64BitCoMemoryManager
															ISA X64
															MULTIPLEBYTECODESETS true)
]
