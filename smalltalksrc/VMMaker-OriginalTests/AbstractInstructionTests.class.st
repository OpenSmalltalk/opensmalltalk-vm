Class {
	#name : #AbstractInstructionTests,
	#superclass : #TestCase,
	#instVars : [
		'processor',
		'opcodes'
	],
	#pools : [
		'CogAbstractRegisters',
		'CogRTLOpcodes'
	],
	#category : #'VMMaker-OriginalTests'
}

{ #category : #utilities }
AbstractInstructionTests class >> defaultTestClass [
	"self defaultTestClass"
	| defaultInstructionCompilerClass |
	defaultInstructionCompilerClass := (Cogit classPool at: #ProcessorClass) new abstractInstructionCompilerClass.
	^self subclasses detect: [:sc| sc new concreteCompilerClass inheritsFrom: defaultInstructionCompilerClass]
]

{ #category : #utilities }
AbstractInstructionTests class >> defaultTester [
	^self defaultTestClass new
]

{ #category : #testing }
AbstractInstructionTests class >> isAbstract [
	"Override to true if a TestCase subclass is Abstract and should not have
	TestCase instances built from it"

	^self name = #AbstractInstructionTests
]

{ #category : #'generating machine code' }
AbstractInstructionTests >> MoveR: reg1 R: reg2 [
	^self gen: MoveRR operand: reg1 operand: reg2
]

{ #category : #'generating machine code' }
AbstractInstructionTests >> PopR: reg [
	^self gen: PopR operand: reg
]

{ #category : #'generating machine code' }
AbstractInstructionTests >> PushR: reg [
	^self gen: PushR operand: reg
]

{ #category : #'generating machine code' }
AbstractInstructionTests >> abstractInstruction: theAbstractInstruction follows: anAbstractInstruction [
	<var: #theAbstractInstruction type: #'AbstractInstruction *'>
	<var: #anAbstractInstruction  type: #'AbstractInstruction *'>
	^opcodes notNil
	   and: [(opcodes identityIndexOf: theAbstractInstruction ifAbsent: [0])
			> (opcodes identityIndexOf: anAbstractInstruction ifAbsent: [1])]
]

{ #category : #'cogit compatibility' }
AbstractInstructionTests >> addressIsInCurrentCompilation: address [
	"Provide a range of addresses that are assumed to be in the current compilation.  Within this range operands
	 can be interpreted as pc-relative addresses, and hence allow testing of pc-relative addresses,"
	^self currentCompilationBase <= address
	  and: [address - self currentCompilationBase < 1024]
]

{ #category : #'generating machine code' }
AbstractInstructionTests >> addressIsInFixups: abstractInstruction [ 
	^false
]

{ #category : #'generating machine code' }
AbstractInstructionTests >> addressIsInInstructions: anAbstractOpcode [ 
	^opcodes notNil and: [(opcodes identityIndexOf: anAbstractOpcode ifAbsent: []) notNil]
]

{ #category : #accessing }
AbstractInstructionTests >> assert: expected equals: actual [
	"Override to use a case-insensitive comparison for strings."
	^self
		assert: (expected isString
				ifTrue: [expected sameAs: actual]
				ifFalse: [expected = actual])
		description: [ self comparingStringBetween: expected and: actual ]

]

{ #category : #running }
AbstractInstructionTests >> assertCheckQuickArithOpCodeSize: bytes [
	self subclassResponsibility
]

{ #category : #'cogit compatibility' }
AbstractInstructionTests >> assertSaneJumpTarget: jumpTarget [
	<var: #jumpTarget type: #'AbstractInstruction *'>

	self assert: (self addressIsInInstructions: jumpTarget)
]

{ #category : #'generating machine code' }
AbstractInstructionTests >> cCoerceSimple: anAbstractOpcode to: aSymbol [
	"hack compatibility with Cogit"
	^anAbstractOpcode
]

{ #category : #accessing }
AbstractInstructionTests >> coInterpreter [
	"hack for testing"
	^nil
]

{ #category : #accessing }
AbstractInstructionTests >> concreteCompilerClass [
	"Answer the concreate subclass of CogAbstractInstruction the concrete test class is testing."
	self subclassResponsibility
]

{ #category : #'cogit compatibility' }
AbstractInstructionTests >> currentCompilationBase [
	"Provide a range of addresses that are assumed to be in the current compilation.  Within this range operands
	 can be interpreted as pc-relative addresses, and hence allow testing of pc-relative addresses,"
	^16r8000
]

{ #category : #disassembly }
AbstractInstructionTests >> disassembleOpcodesIn: memory to: aStream [
	self processor
		disassembleFrom: opcodes first address
		to: opcodes last address + opcodes last machineCodeSize - 1
		in: (self memoryAsBytes: memory)
		on: aStream
]

{ #category : #'generating machine code' }
AbstractInstructionTests >> gen: opcode [
	| abstractInstruction |
	abstractInstruction := self concreteCompilerClass new.
	abstractInstruction
		opcode: opcode;
		cogit: self.
	^opcodes ifNil: [abstractInstruction] ifNotNil: [opcodes addLast: abstractInstruction]
]

{ #category : #'generating machine code' }
AbstractInstructionTests >> gen: opcode operand: operandOne [
	| abstractInstruction |
	abstractInstruction := self concreteCompilerClass new.
	abstractInstruction
		opcode: opcode;
		cogit: self.
	abstractInstruction operands at: 0 put: operandOne.
	^opcodes ifNil: [abstractInstruction] ifNotNil: [opcodes addLast: abstractInstruction]
]

{ #category : #'generating machine code' }
AbstractInstructionTests >> gen: opcode operand: operandOne operand: operandTwo [
	| abstractInstruction |
	abstractInstruction := self concreteCompilerClass new.
	abstractInstruction
		opcode: opcode;
		cogit: self.
	abstractInstruction operands at: 0 put: operandOne.
	abstractInstruction operands at: 1 put: operandTwo.
	^opcodes ifNil: [abstractInstruction] ifNotNil: [opcodes addLast: abstractInstruction]
]

{ #category : #'generating machine code' }
AbstractInstructionTests >> gen: opcode operand: operandOne operand: operandTwo operand: operandThree [
	| abstractInstruction |
	abstractInstruction := self concreteCompilerClass new.
	abstractInstruction
		opcode: opcode;
		cogit: self.
	abstractInstruction operands at: 0 put: operandOne.
	abstractInstruction operands at: 1 put: operandTwo.
	abstractInstruction operands at: 2 put: operandThree.
	^opcodes ifNil: [abstractInstruction] ifNotNil: [opcodes addLast: abstractInstruction]
]

{ #category : #'generating machine code' }
AbstractInstructionTests >> genConditionalBranch: opcode operand: operandOne [
	^self previousInstruction noteFollowingConditionalBranch: (self gen: opcode operand: operandOne)
]

{ #category : #'generating machine code' }
AbstractInstructionTests >> generateInstructions [
	"See Cogit>>computeMaximumSizes, generateInstructionsAt: & outputInstructionsAt:.
	 This is a pure Smalltalk (non-Slang) version of that trio of methods."
	| address pcDependentInstructions instructions |
	address := 0.
	pcDependentInstructions := OrderedCollection new.
	opcodes do:
		[:abstractInstruction|
		abstractInstruction
			address: address;
			maxSize: abstractInstruction computeMaximumSize.
		address := address + abstractInstruction maxSize].
	address := 0.
	opcodes do:
		[:abstractInstruction|
		abstractInstruction isPCDependent
			ifTrue:
				[abstractInstruction sizePCDependentInstructionAt: address.
				 pcDependentInstructions addLast: abstractInstruction.
				 address := address + abstractInstruction machineCodeSize]
			ifFalse:
				[address := abstractInstruction concretizeAt: address]].
	pcDependentInstructions do:
		[:abstractInstruction|
		abstractInstruction concretizeAt: abstractInstruction address].
	instructions := ByteArray new: address.
	address := 0.
	opcodes do:
		[:abstractInstruction| | machineCodeBytes |
		self assert: abstractInstruction address = address.
		machineCodeBytes := self memoryAsBytes: abstractInstruction machineCode object.
		1 to: abstractInstruction machineCodeSize do:
			[:j|
			instructions at: address + 1 put: (machineCodeBytes at: j).
			address := address + 1]].
	^instructions
]

{ #category : #private }
AbstractInstructionTests >> memoryAsBytes: instructionMachineCode [
	"Answer an AbstractInstruction's machine code as a ByteArray.  Subclasses that represent instruction
	 data using Array should override to convert appropriately."
	instructionMachineCode isCObjectAccessor ifTrue:
		[^self memoryAsBytes: instructionMachineCode object].
	self assert: instructionMachineCode class isBits.
	^instructionMachineCode
]

{ #category : #'cogit compatibility' }
AbstractInstructionTests >> methodLabel [
	^nil
]

{ #category : #accessing }
AbstractInstructionTests >> objectMemory [
	"hack for testing"
	^nil
]

{ #category : #private }
AbstractInstructionTests >> pairs: aRange do: aBinaryBlock [
	aRange do: [:a| aRange do: [:b| aBinaryBlock value: a value: b]]
]

{ #category : #accessing }
AbstractInstructionTests >> previousInstruction [
	<returnTypeC: #'AbstractInstruction *'>
	^opcodes last
]

{ #category : #accessing }
AbstractInstructionTests >> processor [
	self subclassResponsibility
]

{ #category : #'generating machine code' }
AbstractInstructionTests >> resetGen [
	opcodes := OrderedCollection new
]

{ #category : #running }
AbstractInstructionTests >> runAddCqR: assertPrintBar [
	"self defaultTester runAddCqR: true"
	"self defaultTester runAddCqR: false"
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:reg :rgetter :rsetter|
		self pairs: (-2 to: 2)  do:
			[:a :b| | inst len bogus memory |
			inst := self gen: AddCqR operand: a operand: reg.
			len := inst concretizeAt: 0.
			memory := self memoryAsBytes: inst machineCode.
			self processor
				reset;
				perform: rsetter with: (processor convertIntegerToInternal: b).
			[[processor pc < len] whileTrue:
				[self processor singleStepIn: memory]]
				on: Error
				do: [:ex| ].
			"self processor printRegistersOn: Transcript.
			 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr"
			assertPrintBar
				ifTrue: [self assert: processor pc equals: inst machineCodeSize.
						self assertCheckQuickArithOpCodeSize: inst machineCodeSize]
				ifFalse: [bogus := processor pc ~= inst machineCodeSize].
			self concreteCompilerClass dataRegistersWithAccessorsDo:
				[:ireg :getter :setter| | expected |
				expected := getter == rgetter ifTrue: [a + b] ifFalse: [0].
				assertPrintBar
					ifTrue: [self assert: (self processor convertInternalToInteger: (self processor perform: getter)) equals: expected]
					ifFalse:
						[(self processor convertInternalToInteger: (self processor perform: getter)) ~= expected ifTrue:
							[bogus := true]]].
				assertPrintBar ifFalse:
					[Transcript
						nextPutAll: rgetter; nextPut: $(; print: b; nextPutAll: ') + '; print: a; nextPutAll: ' = ';
						print: (self processor convertInternalToInteger: (self processor perform: rgetter)); cr; flush.
					 bogus ifTrue:
						[self processor printRegistersOn: Transcript.
						 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr]]]]
]

{ #category : #running }
AbstractInstructionTests >> runAddCwR: assertPrintBar [
	"self defaultTester runAddCwR: false"
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:reg :rgetter :rsetter|
		self pairs: (-2 to: 2)  do:
			[:a :b| | inst len bogus memory |
			inst := self gen: AddCwR operand: a operand: reg.
			len := inst concretizeAt: 0.
			memory := self memoryAsBytes: inst machineCode.
			self processor
				reset;
				perform: rsetter with: (self processor convertIntegerToInternal: b).
			[[processor pc < len] whileTrue:
				[self processor singleStepIn: memory]]
				on: Error
				do: [:ex| ].
			"self processor printRegistersOn: Transcript.
			 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr"
			assertPrintBar
				ifTrue: [self assert: processor pc = inst machineCodeSize.
						self assertCheckLongArithOpCodeSize: inst machineCodeSize]
				ifFalse: [bogus := processor pc ~= inst machineCodeSize].
			self concreteCompilerClass dataRegistersWithAccessorsDo:
				[:ireg :getter :setter| | expected |
				(self concreteCompilerClass isRISCTempRegister: ireg) ifFalse:
					[expected := getter == rgetter ifTrue: [b + a] ifFalse: [0].
					assertPrintBar
						ifTrue: [self assert: (self processor convertInternalToInteger: (self processor perform: getter)) equals: expected]
						ifFalse:
							[(self processor convertInternalToInteger: (self processor perform: getter)) ~= expected ifTrue:
								[bogus := true]]].
					assertPrintBar ifFalse:
						[Transcript
							nextPutAll: rgetter; nextPut: $(; print: b; nextPutAll: ') + '; print: a; nextPutAll: ' = ';
							print: (self processor convertInternalToInteger: (self processor perform: rgetter)); cr; flush.
						 bogus ifTrue:
							[self processor printRegistersOn: Transcript.
							 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr]]]]]
]

{ #category : #running }
AbstractInstructionTests >> runAddRR: assertPrintBar [
	"self defaultTester runAddRR: false"
	"self defaultTester runAddRR: true"
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:sreg :srgetter :srsetter|
		self concreteCompilerClass dataRegistersWithAccessorsDo:
			[:dreg :drgetter :drsetter| | inst len memory |
			inst := self gen: AddRR operand: sreg operand: dreg.
			len := inst concretizeAt: 0.
			memory := self memoryAsBytes: inst machineCode.
			self pairs: (-2 to: 2)  do:
				[:a :b| | bogus |
				self processor
					reset;
					perform: srsetter with: (processor convertIntegerToInternal: a);
					perform: drsetter with: (processor convertIntegerToInternal: b).
				[[processor pc < len] whileTrue:
					[self processor singleStepIn: memory]]
					on: Error
					do: [:ex| ].
				"self processor printRegistersOn: Transcript.
				 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr"
				assertPrintBar
					ifTrue: [self assert: processor pc equals: inst machineCodeSize]
					ifFalse: [bogus := processor pc ~= inst machineCodeSize].
				self concreteCompilerClass dataRegistersWithAccessorsDo:
					[:ireg :getter :setter| | expected |
					expected := getter == drgetter
									ifTrue: [srgetter == drgetter
												ifTrue: [b + b]
												ifFalse: [a + b]]
									ifFalse: [getter = srgetter
												ifTrue: [a]
												ifFalse: [0]].
					assertPrintBar
						ifTrue: [self assert: (self processor convertInternalToInteger: (self processor perform: getter)) equals: expected]
						ifFalse:
							[(self processor convertInternalToInteger: (self processor perform: getter)) ~= expected ifTrue:
								[bogus := true]]].
					assertPrintBar ifFalse:
						[Transcript
							nextPutAll: drgetter; nextPut: $(; print: b; nextPutAll: ') + ';
							nextPutAll: srgetter; nextPut: $(; print: a; nextPutAll: ') = ';
							print: (self processor convertInternalToInteger: (self processor perform: drgetter)); cr; flush.
						 bogus ifTrue:
							[self processor printRegistersOn: Transcript.
							 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr]]]]]
]

{ #category : #running }
AbstractInstructionTests >> runArithmeticShiftRightRR: assertPrintBar [
	"self defaultTester runArithmeticShiftRightRR: false"
	"self defaultTester runArithmeticShiftRightRR: true"
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:sreg :srgetter :srsetter|
		self concreteCompilerClass dataRegistersWithAccessorsDo:
			[:dreg :drgetter :drsetter| | inst len memory |
			inst := self gen: ArithmeticShiftRightRR operand: sreg operand: dreg.
			len := inst concretizeAt: 0.
			memory := self memoryAsBytes: inst machineCode.
			self pairs: (-5 to: 19 by: 6)  do:
				[:a :b| | bogus |
				(a >= 0 and: [sreg ~= dreg or: [b >= 0]]) ifTrue:
					[self processor
						reset;
						perform: srsetter with: (processor convertIntegerToInternal: a);
						perform: drsetter with: (processor convertIntegerToInternal: b).
					[self processor singleStepIn: memory.
					 self processor pc ~= inst machineCodeSize] whileTrue.
					"self processor printRegistersOn: Transcript.
					 self processor disassembleFrom: 0 to: inst machineCodeSize in: memory on: Transcript"
					assertPrintBar
						ifTrue: [self assert: processor pc = inst machineCodeSize]
						ifFalse: [bogus := processor pc ~= inst machineCodeSize].
					self concreteCompilerClass dataRegistersWithAccessorsDo:
						[:ireg :getter :setter| | expected |
						expected := getter == drgetter
										ifTrue: [srgetter == drgetter
													ifTrue: [b >> b]
													ifFalse: [b >> a]]
										ifFalse: [getter = srgetter
													ifTrue: [a]
													ifFalse: [0]].
						assertPrintBar
							ifTrue: [self assert: (self processor convertInternalToInteger: (self processor perform: getter)) equals: expected]
							ifFalse:
								[(self processor convertInternalToInteger: (self processor perform: getter)) ~= expected ifTrue:
								[bogus := true]]].
						assertPrintBar ifFalse:
							[Transcript
								nextPutAll: drgetter; nextPut: $(; print: b; nextPutAll: ') >> ';
								nextPutAll: srgetter; nextPut: $(; print: a; nextPutAll: ') = ';
								print: (self processor convertInternalToInteger: (self processor perform: drgetter)); cr; flush.
							 bogus ifTrue:
								[self processor printRegistersOn: Transcript.
								 self processor disassembleFrom: 0 to: inst machineCodeSize in: memory on: Transcript]]]]]]
]

{ #category : #running }
AbstractInstructionTests >> runBinaryConditionalJumps: assertPrintBar [
	"self defaultTester runBinaryConditionalJumps: false"
	| mask count reg1 reg2 reg3 reg1Getter reg2Setter reg3Setter |
	mask := (1 << self processor bitsInWord) - 1.
	count := 0.
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:n :get :set|
		count = 0 ifTrue: [reg1 := n. reg1Getter := get].
		count = 1 ifTrue: [reg2 := n. reg2Setter := set].
		count = 2 ifTrue: [reg3 := n. reg3Setter := set].
		count := count + 1].
	self assert: reg1 ~= nil.
	self assert: reg2 ~= nil.
	self assert: reg3 ~= nil.
	#(	(JumpAbove > unsigned)			(JumpBelowOrEqual <= unsigned)
		(JumpBelow < unsigned)			(JumpAboveOrEqual >= unsigned)
		(JumpGreater > signed)			(JumpLessOrEqual <= signed)
		(JumpLess < signed)				(JumpGreaterOrEqual >= signed)
		(JumpZero = signed)				(JumpNonZero ~= signed)) do:
		[:triple|
		[:opName :relation :signednessOrResult| | opcode jumpNotTaken jumpTaken nop memory bogus |
		self resetGen.
		opcode := CogRTLOpcodes classPool at: opName.
		self gen: CmpRR operand: reg3 operand: reg2.
		jumpTaken := self genConditionalBranch: opcode operand: 0.
		self gen: MoveCqR operand: 0 operand: reg1.
		jumpNotTaken := self gen: Jump.
		jumpTaken jmpTarget: (self gen: MoveCqR operand: 1 operand: reg1).
		jumpNotTaken jmpTarget: (nop := self gen: Nop).
		memory := self generateInstructions.
		"self processor disassembleFrom: 0 to: memory size in: memory on: Transcript."
		bogus := false.
		self pairs: (-2 to: 2)  do:
			[:a :b| | taken |
			self processor
				reset;
				perform: reg2Setter with: (processor convertIntegerToInternal: a);
				perform: reg3Setter with: (processor convertIntegerToInternal: b).
			[self processor singleStepIn: memory.
			 self processor pc ~= nop address] whileTrue.
			taken := (self processor perform: reg1Getter) = 1.
			assertPrintBar
				ifTrue:
					[self assert: taken equals: (signednessOrResult == #unsigned
												ifTrue: [(a bitAnd: mask) perform: relation with: (b bitAnd: mask)]
												ifFalse: [a perform: relation with: b])]
				ifFalse:
					[Transcript
						nextPutAll: reg2; nextPut: $(; print: a; nextPutAll: ') '; nextPutAll: relation; space;
						nextPutAll: reg3; nextPut: $(; print: b; nextPutAll: ') = ';
						print: taken; cr; flush.
					 taken = (signednessOrResult == #unsigned
											ifTrue: [(a bitAnd: mask) perform: relation with: (b bitAnd: mask)]
											ifFalse: [a perform: relation with: b]) ifFalse:
						[bogus := true]]].
			 bogus ifTrue:
				[self processor printRegistersOn: Transcript.
				 Transcript show: (self processor disassembleInstructionAt: jumpTaken address In: memory); cr]]
					valueWithArguments: triple]
]

{ #category : #running }
AbstractInstructionTests >> runBinaryConditionalJumpsViaCmpCqR: assertPrintBar [
	"self defaultTester runBinaryConditionalJumpsViaCmpCqR: false"
	| mask count reg1 reg2 resultRegNum operandRegNum |
	mask := (1 << self processor bitsInWord) - 1.
	count := 0.
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:n :get :set|
		count = 0 ifTrue: [resultRegNum := n. reg1 := get].
		count = 1 ifTrue: [operandRegNum := n. reg2 := set].
		count := count + 1].
	self assert: resultRegNum ~= nil.
	self assert: operandRegNum ~= nil.
	#(	(JumpAbove > unsigned)			(JumpBelowOrEqual <= unsigned)
		(JumpBelow < unsigned)			(JumpAboveOrEqual >= unsigned)
		(JumpGreater > signed)			(JumpLessOrEqual <= signed)
		(JumpLess < signed)				(JumpGreaterOrEqual >= signed)
		(JumpZero = signed)				(JumpNonZero ~= signed)) do:
		[:triple|
		[:opName :relation :signednessOrResult| | opcode |
		opcode := CogRTLOpcodes classPool at: opName.
		(-2 to: 2) do:
			[:b| | jumpNotTaken jumpTaken nop memory bogus |
			self resetGen.
			self gen: CmpCqR operand: b operand: operandRegNum.
			jumpTaken := self genConditionalBranch: opcode operand: 0.
			self gen: MoveCqR operand: 0 operand: resultRegNum.
			jumpNotTaken := self gen: Jump.
			jumpTaken jmpTarget: (self gen: MoveCqR operand: 1 operand: resultRegNum).
			jumpNotTaken jmpTarget: (nop := self gen: Nop).
			memory := self generateInstructions.
			assertPrintBar ifFalse:
				[Transcript print: triple; cr.
				 self disassembleOpcodesIn: memory to: Transcript].
			bogus := false.
			(-2 to: 2) do:
				[:a| | taken expected |
				self processor
					reset;
					perform: reg2 with: (processor convertIntegerToInternal: a).
				[self processor singleStepIn: memory.
				 self processor pc ~= nop address] whileTrue.
				taken := (self processor perform: reg1) = 1.
				expected := signednessOrResult == #unsigned
								ifTrue: [(a bitAnd: mask) perform: relation with: (b bitAnd: mask)]
								ifFalse: [a perform: relation with: b].
				assertPrintBar
					ifTrue:
						[self assert: taken equals: expected]
					ifFalse:
						[Transcript
							nextPutAll: 'CmpCqR '; print: b; space; nextPutAll: reg2; tab; tab;
							nextPutAll: reg2; nextPut: $(; print: a; nextPut: $); space;
							nextPutAll: relation; space; print: b; nextPutAll: ' = ';
							print: taken;  nextPutAll: ' ('; print: expected; nextPut: $).
						 taken ~= expected ifTrue:
							[Transcript nextPutAll: ' !!'.
							 bogus := true].
						 Transcript cr; flush]].
				bogus ifTrue:
					[self processor printRegistersOn: Transcript.
					 Transcript nextPutAll: jumpTaken symbolic; tab; show: (self processor disassembleInstructionAt: jumpTaken address In: memory); cr]]]
						valueWithArguments: triple]
]

{ #category : #running }
AbstractInstructionTests >> runBinaryConditionalJumpsViaSubCqR: assertPrintBar [
	"self defaultTester runBinaryConditionalJumpsViaSubCqR: false"
	| mask count reg1 reg2 setreg2 resultRegNum operandRegNum |
	mask := (1 << self processor bitsInWord) - 1.
	count := 0.
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:n :get :set|
		count = 0 ifTrue: [resultRegNum := n. reg1 := get].
		count = 1 ifTrue: [operandRegNum := n. reg2 := get. setreg2 := set].
		count := count + 1].
	self assert: resultRegNum ~= nil.
	self assert: operandRegNum ~= nil.
	
	#(	(JumpAbove > unsigned)			(JumpBelowOrEqual <= unsigned)
		(JumpBelow < unsigned)			(JumpAboveOrEqual >= unsigned)
		(JumpGreater > signed)			(JumpLessOrEqual <= signed)
		(JumpLess < signed)				(JumpGreaterOrEqual >= signed)
		(JumpZero = signed)				(JumpNonZero ~= signed)) do:
		[:triple|
		[:opName :relation :signednessOrResult| | opcode |
		opcode := CogRTLOpcodes classPool at: opName.
		(-2 to: 2) do:
			[:b| | jumpNotTaken jumpTaken nop memory bogus |
			self resetGen.
			self gen: SubCqR operand: b operand: operandRegNum.
			jumpTaken := self genConditionalBranch: opcode operand: 0.
			self gen: MoveCqR operand: 0 operand: resultRegNum.
			jumpNotTaken := self gen: Jump.
			jumpTaken jmpTarget: (self gen: MoveCqR operand: 1 operand: resultRegNum).
			jumpNotTaken jmpTarget: (nop := self gen: Nop).
			memory := self generateInstructions.
			assertPrintBar ifFalse:
				[Transcript print: triple; cr.
				 self disassembleOpcodesIn: memory to: Transcript].
			bogus := false.
			(-2 to: 2) do:
				[:a| | taken result expected |
				self processor
					reset;
					perform: setreg2 with: (self processor convertIntegerToInternal: a).
				[self processor singleStepIn: memory.
				 self processor pc ~= nop address] whileTrue.
				taken := (self processor perform: reg1) = 1.
				result := signednessOrResult == #unsigned
							ifTrue: [(a bitAnd: mask) - (b bitAnd: mask)]
							ifFalse: [a - b].
				expected := result perform: relation with: 0.
				assertPrintBar
					ifTrue:
						[self assert: (taken = expected
									  and: [(result bitAnd: mask) = (processor perform: reg2)])]
					ifFalse:
						[Transcript
							nextPutAll: 'SubCqR '; print: b; space; nextPutAll: reg2; tab; tab;
							print: b; space; nextPutAll: relation; space;
							nextPutAll: reg2; nextPut: $(; print: a; nextPutAll: ') = ';
							print: taken;  nextPutAll: ' ('; print: expected; nextPut: $).
						 taken ~= expected ifTrue:
							[Transcript nextPutAll: ' !!'.
							 bogus := true].
						 Transcript cr; flush]].
				bogus ifTrue:
					[self processor printRegistersOn: Transcript.
					 Transcript nextPutAll: jumpTaken symbolic; tab; show: (self processor disassembleInstructionAt: jumpTaken address In: memory); cr]]]
						valueWithArguments: triple]
]

{ #category : #running }
AbstractInstructionTests >> runCmpRdRd: assertPrintBar [
	"self defaultTester runCmpRdRd: false"
	"self defaultTester runCmpRdRd: true"
	| resultReg result reg1 reg2 setreg1 setreg2 |
	self concreteCompilerClass new hasDoublePrecisionFloatingPointSupport ifFalse: [^true].
	resultReg := 0.
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:n :get :set| n = resultReg ifTrue: [result := get]].
	self concreteCompilerClass fp64RegistersWithAccessorsDo:
		[:n :get :set|
		n = DPFPReg0 ifTrue: [reg1 := get. setreg1 := set].
		n = DPFPReg1 ifTrue: [reg2 := set. setreg2 := set]].
	#(	(genJumpFPGreater: > false nan)	(genJumpFPLessOrEqual: <= false nil)
		(genJumpFPLess: < false nil)				(genJumpFPGreaterOrEqual: <= true nan)
		(genJumpFPGreater: < true nan)		(genJumpFPGreaterOrEqual: >= false nan)
		(genJumpFPEqual: = false nan)		(genJumpFPNotEqual: ~= false nan)) do:
		[:tuple|
		[:opName :relation :invert :nan| | them inst jumpNotTaken jumpTaken nop memory |
		them := nan ifNil: [-2.0 to: 2.0] ifNotNil: [(-2.0 to: 2.0), { Float nan }].
		self resetGen.
		inst := invert
				ifTrue: [self gen: CmpRdRd operand: DPFPReg0 operand: DPFPReg1]
				ifFalse: [self gen: CmpRdRd operand: DPFPReg1 operand: DPFPReg0].
		jumpTaken := inst perform: opName with: 0.
		self gen: MoveCqR operand: 0 operand: resultReg.
		jumpNotTaken := self gen: Jump.
		jumpTaken jmpTarget: (self gen: MoveCqR operand: 1 operand: resultReg).
		jumpNotTaken jmpTarget: (nop := self gen: Nop).
		memory := self generateInstructions.
		assertPrintBar ifFalse:
			[Transcript print: tuple; cr.
			 self disassembleOpcodesIn: memory to: Transcript].
		them do:
			[:a|
			them do:
				[:b| | taken expected |
				self processor
					reset;
					perform: setreg1 with: a asIEEE64BitWord;
					perform: setreg2 with: b asIEEE64BitWord.
				[self processor singleStepIn: memory.
				 self processor pc ~= nop address] whileTrue.
				taken := (self processor perform: result) = 1.
				expected := a perform: relation with: b.
				assertPrintBar
					ifTrue:
						[self assert: taken = expected]
					ifFalse:
						[Transcript
							nextPutAll: 'CmpRdRd ', reg1, ' ', reg2; tab; tab;
							nextPutAll: reg1; nextPut: $(; print: a; nextPut: $); space;
							nextPutAll: relation; space;
							nextPutAll: reg2; nextPut: $(; print: b; nextPut: $); space;
							nextPutAll: ' = '; print: taken;  nextPutAll: ' ('; print: expected; nextPut: $).
						 taken ~= expected ifTrue:
							[Transcript nextPutAll: ' !!'; cr.
							 self processor printRegistersOn: Transcript.].
						 Transcript cr; flush]]]]
						valueWithArguments: tuple]
]

{ #category : #running }
AbstractInstructionTests >> runSubCqR: assertPrintBar [
	"self defaultTester runSubCqR: false"
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:reg :rgetter :rsetter|
		self pairs: (-2 to: 2)  do:
			[:a :b| | inst len bogus memory |
			inst := self gen: SubCqR operand: a operand: reg.
			len := inst concretizeAt: 0.
			memory := self memoryAsBytes: inst machineCode.
			self processor
				reset;
				perform: rsetter with: (processor convertIntegerToInternal: b).
			[[processor pc < len] whileTrue:
				[self processor singleStepIn: memory]]
				on: Error
				do: [:ex| ].
			"self processor printRegistersOn: Transcript.
			 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr"
			assertPrintBar
				ifTrue: [self assert: processor pc = inst machineCodeSize.
						self assertCheckQuickArithOpCodeSize: inst machineCodeSize]
				ifFalse: [bogus := processor pc ~= inst machineCodeSize].
			self concreteCompilerClass dataRegistersWithAccessorsDo:
				[:ireg :getter :setter| | expected |
				expected := getter == rgetter ifTrue: [b - a] ifFalse: [0].
				assertPrintBar
					ifTrue: [self assert: (self processor convertInternalToInteger: (self processor perform: getter)) equals: expected]
					ifFalse:
						[(self processor convertInternalToInteger: (self processor perform: getter)) ~= expected ifTrue:
							[bogus := true]]].
				assertPrintBar ifFalse:
					[Transcript
						nextPutAll: rgetter; nextPut: $(; print: b; nextPutAll: ') - '; print: a; nextPutAll: ' = ';
						print: (self processor convertInternalToInteger: (self processor perform: rgetter)); cr; flush.
					 bogus ifTrue:
						[self processor printRegistersOn: Transcript.
						 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr]]]]
]

{ #category : #running }
AbstractInstructionTests >> runSubCwR: assertPrintBar [
	"self defaultTester runSubCwR: false"
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:reg :rgetter :rsetter|
		self pairs: (-2 to: 2)  do:
			[:a :b| | inst len bogus memory |
			inst := self gen: SubCwR operand: a operand: reg.
			len := inst concretizeAt: 0.
			memory := self memoryAsBytes: inst machineCode.
			self processor
				reset;
				perform: rsetter with: (self processor convertIntegerToInternal: b).
			[[processor pc < len] whileTrue:
				[self processor singleStepIn: memory]]
				on: Error
				do: [:ex| ].
			"self processor printRegistersOn: Transcript.
			 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr"
			assertPrintBar
				ifTrue: [self assert: processor pc = inst machineCodeSize.
						self assertCheckLongArithOpCodeSize: inst machineCodeSize]
				ifFalse: [bogus := processor pc ~= inst machineCodeSize].
			self concreteCompilerClass dataRegistersWithAccessorsDo:
				[:ireg :getter :setter| | expected |
				(self concreteCompilerClass isRISCTempRegister: ireg) ifFalse:
					[expected := getter == rgetter ifTrue: [b - a] ifFalse: [0].
					assertPrintBar
						ifTrue: [self assert: (self processor convertInternalToInteger: (self processor perform: getter)) equals: expected]
						ifFalse:
							[(self processor convertInternalToInteger: (self processor perform: getter)) ~= expected ifTrue:
								[bogus := true]]].
					assertPrintBar ifFalse:
						[Transcript
							nextPutAll: rgetter; nextPut: $(; print: b; nextPutAll: ') - '; print: a; nextPutAll: ' = ';
							print: (self processor convertInternalToInteger: (self processor perform: rgetter)); cr; flush.
						 bogus ifTrue:
							[self processor printRegistersOn: Transcript.
							 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr]]]]]
]

{ #category : #running }
AbstractInstructionTests >> runSubRR: assertPrintBar [
	"self defaultTester runSubRR: false"
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:sreg :srgetter :srsetter|
		self concreteCompilerClass dataRegistersWithAccessorsDo:
			[:dreg :drgetter :drsetter| | inst len memory |
			inst := self gen: SubRR operand: sreg operand: dreg.
			len := inst concretizeAt: 0.
			memory := self memoryAsBytes: inst machineCode.
			self pairs: (-2 to: 2)  do:
				[:a :b| | bogus |
				self processor
					reset;
					perform: srsetter with: (processor convertIntegerToInternal: a);
					perform: drsetter with: (processor convertIntegerToInternal: b).
				[[processor pc < len] whileTrue:
					[self processor singleStepIn: memory]]
					on: Error
					do: [:ex| ].
				"self processor printRegistersOn: Transcript.
				 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr"
				assertPrintBar
					ifTrue: [self assert: processor pc = inst machineCodeSize]
					ifFalse: [bogus := processor pc ~= inst machineCodeSize].
				self concreteCompilerClass dataRegistersWithAccessorsDo:
					[:ireg :getter :setter| | expected |
					expected := drgetter == srgetter
									ifTrue: [0]
									ifFalse:
										[getter == drgetter
											ifTrue: [b - a]
											ifFalse: [getter = srgetter
														ifTrue: [a]
														ifFalse: [0]]].
					assertPrintBar
						ifTrue: [self assert: (self processor convertInternalToInteger: (self processor perform: getter)) equals: expected]
						ifFalse:
							[(self processor convertInternalToInteger: (self processor perform: getter)) ~= expected ifTrue:
								[bogus := true]]].
					assertPrintBar ifFalse:
						[Transcript
							nextPutAll: drgetter; nextPut: $(; print: b; nextPutAll: ') - ';
							nextPutAll: srgetter; nextPut: $(; print: a; nextPutAll: ') = ';
							print: (self processor convertInternalToInteger: (self processor perform: drgetter)); cr; flush.
						 bogus ifTrue:
							[self processor printRegistersOn: Transcript.
							 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr]]]]]
]

{ #category : #running }
AbstractInstructionTests >> setUp [
	self concreteCompilerClass initializeAbstractRegisters
]

{ #category : #tests }
AbstractInstructionTests >> testBinaryConditionalJumps [
	"self defaultTester testBinaryConditionalJumps"
	"self defaultTester runBinaryConditionalJumps: false"
	self runBinaryConditionalJumps: true
]

{ #category : #tests }
AbstractInstructionTests >> testBinaryConditionalJumpsViaCmpCqR [
	"self defaultTester testBinaryConditionalJumpsViaCmpCqR"
	"self defaultTester runBinaryConditionalJumpsViaCmpCqR: false"
	self runBinaryConditionalJumpsViaCmpCqR: true
]

{ #category : #tests }
AbstractInstructionTests >> testBinaryConditionalJumpsViaSubCqR [
	"self defaultTester testBinaryConditionalJumpsViaSubCqR"
	"self defaultTester runBinaryConditionalJumpsViaSubCqR: false"
	self runBinaryConditionalJumpsViaSubCqR: true
]

{ #category : #running }
AbstractInstructionTests >> testNegateR [
	"self defaultTester testNegateR"
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:reg :rgetter :rsetter|
		-2 to: 2 do:
			[:a| | inst len memory |
			inst := self gen: NegateR operand: reg.
			len := inst concretizeAt: 0.
			memory := self memoryAsBytes: inst machineCode.
			self processor
				reset;
				perform: rsetter with: (processor convertIntegerToInternal: a).
			[[processor pc < len] whileTrue:
				[self processor singleStepIn: memory]]
				on: Error
				do: [:ex| ].
			"self processor printRegistersOn: Transcript.
			 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr"
			self assert: processor pc equals: inst machineCodeSize.
			self concreteCompilerClass dataRegistersWithAccessorsDo:
				[:ireg :getter :setter| | expected |
				expected := getter == rgetter ifTrue: [ a negated ] ifFalse: [0].
				self assert: (processor convertInternalToInteger: (processor perform: getter)) equals: expected]]]
]

{ #category : #tests }
AbstractInstructionTests >> testRunAddCqR [
	"self defaultTester testRunAddCqR"
	self runAddCqR: true
]

{ #category : #tests }
AbstractInstructionTests >> testRunAddCwR [
	"self defaultTester testRunAddCwR"
	self runAddCwR: true
]

{ #category : #tests }
AbstractInstructionTests >> testRunAddRR [
	"self defaultTester testRunAddRR"
	self runAddRR: true
]

{ #category : #tests }
AbstractInstructionTests >> testRunArithmeticShiftRightRR [
	"self defaultTester testRunArithmeticShiftRightRR"
	self runArithmeticShiftRightRR: true
]

{ #category : #tests }
AbstractInstructionTests >> testRunCmpRdRd [
	"self defaultTester testRunCmpRdRd"
	self runCmpRdRd: true
]

{ #category : #tests }
AbstractInstructionTests >> testRunSubCqR [
	"self defaultTester testRunSubCqR"
	self runSubCqR: true
]

{ #category : #tests }
AbstractInstructionTests >> testRunSubCwR [
	"self defaultTester testRunSubCwR"
	self runSubCwR: true
]

{ #category : #tests }
AbstractInstructionTests >> testRunSubRR [
	"self defaultTester testRunSubRR"
	self runSubRR: true
]

{ #category : #'cogit compatibility' }
AbstractInstructionTests >> varBaseAddress [
	"Answer a value that should be sufficiently high that var base relative addressing is never generated."
	^1 << 60
]
