Class {
	#name : #AbstractInstructionTests,
	#superclass : #TestCase,
	#instVars : [
		'processor',
		'opcodes'
	],
	#pools : [
		'CogRTLOpcodes'
	],
	#category : #'VMMaker-Tests'
}

{ #category : #debugger }
AbstractInstructionTests class >> defaultIntegerBaseInDebugger [
	^16
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

{ #category : #'generating machine code' }
AbstractInstructionTests >> addressIsInFixups: abstractInstruction [ 
	^false
]

{ #category : #'generating machine code' }
AbstractInstructionTests >> addressIsInInstructions: anAbstractOpcode [ 
	^opcodes notNil and: [(opcodes identityIndexOf: anAbstractOpcode ifAbsent: []) notNil]
]

{ #category : #running }
AbstractInstructionTests >> assertCheckQuickArithOpCodeSize: bytes [
	self subclassResponsibility
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

{ #category : #'generating machine code' }
AbstractInstructionTests >> concreteCompilerClass [
	"Answer the concreate subclass of CogAbstractInstruction the concrete test class is testing."
	self subclassResponsibility
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
AbstractInstructionTests >> generateInstructions [
	"See Cogit>>computeMaximumSizes, generateInstructionsAt: & outputInstructionsAt:.
	 This is a pure Smalltalk (non-Slang) version of that trio of methods."
	| address pcDependentInstructions instructions |
	address := 0.
	pcDependentInstructions := OrderedCollection new.
	opcodes do:
		[:abstractInstruction|
		abstractInstruction address: address.
		abstractInstruction computeMaximumSize.
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
		[:abstractInstruction|
		self assert: abstractInstruction address = address.
		0 to: abstractInstruction machineCodeSize - 1 do:
			[:j|
			instructions at: address + 1 put: (abstractInstruction machineCode at: j).
			address := address + 1]].
	^instructions
]

{ #category : #private }
AbstractInstructionTests >> pairs: aRange do: aBinaryBlock [
	aRange do: [:a| aRange do: [:b| aBinaryBlock value: a value: b]]
]

{ #category : #'generating machine code' }
AbstractInstructionTests >> processor [
	self subclassResponsibility
]

{ #category : #'generating machine code' }
AbstractInstructionTests >> resetGen [
	opcodes := OrderedCollection new
]

{ #category : #running }
AbstractInstructionTests >> runAddCqR: assertPrintBar [
	"self new runAddCqR: true"
	"self new runAddCqR: false"
	| memory |
	memory := ByteArray new: 16.
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:reg :rgetter :rsetter|
		self pairs: (-2 to: 2)  do:
			[:a :b| | inst len bogus |
			inst := self gen: AddCqR operand: a operand: reg.
			len := inst concretizeAt: 0.
			memory replaceFrom: 1 to: len with: inst machineCode object startingAt: 1.
			self processor
				reset;
				perform: rsetter with: b signedIntToLong;
				singleStepIn: memory.
			"self processor printRegistersOn: Transcript.
			 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr"
			assertPrintBar
				ifTrue: [self assert: processor pc = inst machineCodeSize.
						self assertCheckQuickArithOpCodeSize: inst machineCodeSize]
				ifFalse: [bogus := processor pc ~= inst machineCodeSize].
			self concreteCompilerClass dataRegistersWithAccessorsDo:
				[:ireg :getter :setter| | expected |
				expected := getter == rgetter ifTrue: [a + b] ifFalse: [0].
				assertPrintBar
					ifTrue: [self assert: (self processor perform: getter) signedIntFromLong = expected]
					ifFalse:
						[(self processor perform: getter) signedIntFromLong ~= expected ifTrue:
							[bogus := true]]].
				assertPrintBar ifFalse:
					[Transcript
						nextPutAll: rgetter; nextPut: $(; print: b; nextPutAll: ') + '; print: a; nextPutAll: ' = ';
						print: (self processor perform: rgetter) signedIntFromLong; cr; flush.
					 bogus ifTrue:
						[self processor printRegistersOn: Transcript.
						 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr]]]]
]

{ #category : #running }
AbstractInstructionTests >> runAddCwR: assertPrintBar [
	"self new runAddCwR: false"
	| memory |
	memory := ByteArray new: 16.
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:reg :rgetter :rsetter|
		self pairs: (-2 to: 2)  do:
			[:a :b| | inst len bogus |
			inst := self gen: AddCwR operand: a operand: reg.
			len := inst concretizeAt: 0.
			memory replaceFrom: 1 to: len with: inst machineCode object startingAt: 1.
			self processor
				reset;
				perform: rsetter with: b signedIntToLong;
				singleStepIn: memory.
			"self processor printRegistersOn: Transcript.
			 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr"
			assertPrintBar
				ifTrue: [self assert: processor pc = inst machineCodeSize.
						self assertCheckLongArithOpCodeSize: inst machineCodeSize]
				ifFalse: [bogus := processor pc ~= inst machineCodeSize].
			self concreteCompilerClass dataRegistersWithAccessorsDo:
				[:ireg :getter :setter| | expected |
				expected := getter == rgetter ifTrue: [a + b] ifFalse: [0].
				assertPrintBar
					ifTrue: [self assert: (self processor perform: getter) signedIntFromLong = expected]
					ifFalse:
						[(self processor perform: getter) signedIntFromLong ~= expected ifTrue:
							[bogus := true]]].
				assertPrintBar ifFalse:
					[Transcript
						nextPutAll: rgetter; nextPut: $(; print: b; nextPutAll: ') + '; print: a; nextPutAll: ' = ';
						print: (self processor perform: rgetter) signedIntFromLong; cr; flush.
					 bogus ifTrue:
						[self processor printRegistersOn: Transcript.
						 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr]]]]
]

{ #category : #running }
AbstractInstructionTests >> runAddRR: assertPrintBar [
	"self new runAddRR: false"
	"self new runAddRR: true"
	| memory |
	memory := ByteArray new: 16.
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:sreg :srgetter :srsetter|
		self concreteCompilerClass dataRegistersWithAccessorsDo:
			[:dreg :drgetter :drsetter| | inst len |
			inst := self gen: AddRR operand: sreg operand: dreg.
			len := inst concretizeAt: 0.
			memory replaceFrom: 1 to: len with: inst machineCode object startingAt: 1.
			self pairs: (-2 to: 2)  do:
				[:a :b| | bogus |
				self processor
					reset;
					perform: srsetter with: a signedIntToLong;
					perform: drsetter with: b signedIntToLong;
					singleStepIn: memory.
				"self processor printRegistersOn: Transcript.
				 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr"
				assertPrintBar
					ifTrue: [self assert: processor pc = inst machineCodeSize]
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
						ifTrue: [self assert: (self processor perform: getter) signedIntFromLong = expected]
						ifFalse:
							[(self processor perform: getter) signedIntFromLong ~= expected ifTrue:
								[bogus := true]]].
					assertPrintBar ifFalse:
						[Transcript
							nextPutAll: drgetter; nextPut: $(; print: b; nextPutAll: ') + ';
							nextPutAll: srgetter; nextPut: $(; print: a; nextPutAll: ') = ';
							print: (self processor perform: drgetter) signedIntFromLong; cr; flush.
						 bogus ifTrue:
							[self processor printRegistersOn: Transcript.
							 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr]]]]]
]

{ #category : #running }
AbstractInstructionTests >> runArithmeticShiftRightRR: assertPrintBar [
	"CogIA32CompilerTests new runArithmeticShiftRightRR: false"
	"CogIA32CompilerTests new runArithmeticShiftRightRR: true"
	| memory |
	memory := ByteArray new: 16.
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:sreg :srgetter :srsetter|
		self concreteCompilerClass dataRegistersWithAccessorsDo:
			[:dreg :drgetter :drsetter| | inst len |
			inst := self gen: ArithmeticShiftRightRR operand: sreg operand: dreg.
			len := inst concretizeAt: 0.
			memory replaceFrom: 1 to: len with: inst machineCode object startingAt: 1.
			self pairs: (-5 to: 19 by: 6)  do:
				[:a :b| | bogus |
				(a >= 0 and: [sreg ~= dreg or: [b >= 0]]) ifTrue:
					[self processor
						reset;
						perform: srsetter with: a signedIntToLong;
						perform: drsetter with: b signedIntToLong.
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
							ifTrue: [self assert: (self processor perform: getter) signedIntFromLong = expected]
							ifFalse:
								[(self processor perform: getter) signedIntFromLong ~= expected ifTrue:
									[bogus := true]]].
						assertPrintBar ifFalse:
							[Transcript
								nextPutAll: drgetter; nextPut: $(; print: b; nextPutAll: ') >> ';
								nextPutAll: srgetter; nextPut: $(; print: a; nextPutAll: ') = ';
								print: (self processor perform: drgetter) signedIntFromLong; cr; flush.
							 bogus ifTrue:
								[self processor printRegistersOn: Transcript.
								 self processor disassembleFrom: 0 to: inst machineCodeSize in: memory on: Transcript]]]]]]
]

{ #category : #running }
AbstractInstructionTests >> runBinaryConditionalJumps: assertPrintBar [
	"CogIA32CompilerTests new runBinaryConditionalJumps: false"
	| mask reg1 reg2 reg3 |
	mask := (1 << self processor bitsInWord) - 1.
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:n :get :set|
		n = 0 ifTrue: [reg1 := get].
		n = 1 ifTrue: [reg2 := set].
		n = 2 ifTrue: [reg3 := set]].
	#(	(JumpAbove > unsigned)			(JumpBelowOrEqual <= unsigned)
		(JumpBelow < unsigned)			(JumpAboveOrEqual >= unsigned)
		(JumpGreater > signed)			(JumpLessOrEqual <= signed)
		(JumpLess < signed)				(JumpGreaterOrEqual >= signed)
		(JumpZero = signed)				(JumpNonZero ~= signed)) do:
		[:triple|
		[:opName :relation :signednessOrResult| | opcode jumpNotTaken jumpTaken nop memory bogus |
		self resetGen.
		opcode := CogRTLOpcodes classPool at: opName.
		self gen: CmpRR operand: 2 operand: 1.
		jumpTaken := self gen: opcode.
		self gen: MoveCqR operand: 0 operand: 0.
		jumpNotTaken := self gen: Jump.
		jumpTaken jmpTarget: (self gen: MoveCqR operand: 1 operand: 0).
		jumpNotTaken jmpTarget: (nop := self gen: Nop).
		memory := self generateInstructions.
		bogus := false.
		self pairs: (-2 to: 2)  do:
			[:a :b| | taken |
			self processor
				reset;
				perform: reg2 with: a signedIntToLong;
				perform: reg3 with: b signedIntToLong.
			[self processor singleStepIn: memory.
			 self processor pc ~= nop address] whileTrue.
			taken := (self processor perform: reg1) = 1.
			assertPrintBar
				ifTrue:
					[self assert: taken = (signednessOrResult == #unsigned
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
	"CogIA32CompilerTests new runBinaryConditionalJumpsViaCmpCqR: false"
	| mask reg1 reg2 reg3 |
	mask := (1 << self processor bitsInWord) - 1.
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:n :get :set|
		n = 0 ifTrue: [reg1 := get].
		n = 1 ifTrue: [reg2 := set].
		n = 2 ifTrue: [reg3 := set]].
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
			self gen: CmpCqR operand: b operand: 2.
			jumpTaken := self gen: opcode.
			self gen: MoveCqR operand: 0 operand: 0.
			jumpNotTaken := self gen: Jump.
			jumpTaken jmpTarget: (self gen: MoveCqR operand: 1 operand: 0).
			jumpNotTaken jmpTarget: (nop := self gen: Nop).
			memory := self generateInstructions.
			bogus := false.
			(-2 to: 2) do:
				[:a| | taken expected |
				self processor
					reset;
					perform: reg3 with: a signedIntToLong.
				[self processor singleStepIn: memory.
				 self processor pc ~= nop address] whileTrue.
				taken := (self processor perform: reg1) = 1.
				expected := signednessOrResult == #unsigned
								ifTrue: [(a bitAnd: mask) perform: relation with: (b bitAnd: mask)]
								ifFalse: [a perform: relation with: b].
				assertPrintBar
					ifTrue:
						[self assert: taken = expected]
					ifFalse:
						[Transcript
							nextPutAll: reg2; nextPut: $(; print: a; nextPutAll: ') '; nextPutAll: relation; space;
							nextPutAll: reg3; nextPut: $(; print: b; nextPutAll: ') = ';
							print: taken;  nextPutAll: ' ('; print: expected; nextPut: $); cr; flush.
						 taken = expected ifFalse:
							[bogus := true]]].
				bogus ifTrue:
					[self processor printRegistersOn: Transcript.
					 Transcript nextPutAll: jumpTaken symbolic; tab; show: (self processor disassembleInstructionAt: jumpTaken address In: memory); cr]]]
						valueWithArguments: triple]
]

{ #category : #running }
AbstractInstructionTests >> runSubCqR: assertPrintBar [
	"self new runSubCqR: false"
	| memory |
	memory := ByteArray new: 16.
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:reg :rgetter :rsetter|
		self pairs: (-2 to: 2)  do:
			[:a :b| | inst len bogus |
			inst := self gen: SubCqR operand: a operand: reg.
			len := inst concretizeAt: 0.
			memory replaceFrom: 1 to: len with: inst machineCode object startingAt: 1.
			self processor
				reset;
				perform: rsetter with: b signedIntToLong;
				singleStepIn: memory.
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
					ifTrue: [self assert: (self processor perform: getter) signedIntFromLong = expected]
					ifFalse:
						[(self processor perform: getter) signedIntFromLong ~= expected ifTrue:
							[bogus := true]]].
				assertPrintBar ifFalse:
					[Transcript
						nextPutAll: rgetter; nextPut: $(; print: b; nextPutAll: ') - '; print: a; nextPutAll: ' = ';
						print: (self processor perform: rgetter) signedIntFromLong; cr; flush.
					 bogus ifTrue:
						[self processor printRegistersOn: Transcript.
						 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr]]]]
]

{ #category : #running }
AbstractInstructionTests >> runSubCwR: assertPrintBar [
	"self new runSubCwR: false"
	| memory |
	memory := ByteArray new: 16.
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:reg :rgetter :rsetter|
		self pairs: (-2 to: 2)  do:
			[:a :b| | inst len bogus |
			inst := self gen: SubCwR operand: a operand: reg.
			len := inst concretizeAt: 0.
			memory replaceFrom: 1 to: len with: inst machineCode object startingAt: 1.
			self processor
				reset;
				perform: rsetter with: b signedIntToLong;
				singleStepIn: memory.
			"self processor printRegistersOn: Transcript.
			 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr"
			assertPrintBar
				ifTrue: [self assert: processor pc = inst machineCodeSize.
						self assertCheckLongArithOpCodeSize: inst machineCodeSize]
				ifFalse: [bogus := processor pc ~= inst machineCodeSize].
			self concreteCompilerClass dataRegistersWithAccessorsDo:
				[:ireg :getter :setter| | expected |
				expected := getter == rgetter ifTrue: [b - a] ifFalse: [0].
				assertPrintBar
					ifTrue: [self assert: (self processor perform: getter) signedIntFromLong = expected]
					ifFalse:
						[(self processor perform: getter) signedIntFromLong ~= expected ifTrue:
							[bogus := true]]].
				assertPrintBar ifFalse:
					[Transcript
						nextPutAll: rgetter; nextPut: $(; print: b; nextPutAll: ') - '; print: a; nextPutAll: ' = ';
						print: (self processor perform: rgetter) signedIntFromLong; cr; flush.
					 bogus ifTrue:
						[self processor printRegistersOn: Transcript.
						 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr]]]]
]

{ #category : #running }
AbstractInstructionTests >> runSubRR: assertPrintBar [
	"self new runSubRR: false"
	| memory |
	memory := ByteArray new: 16.
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:sreg :srgetter :srsetter|
		self concreteCompilerClass dataRegistersWithAccessorsDo:
			[:dreg :drgetter :drsetter| | inst len |
			inst := self gen: SubRR operand: sreg operand: dreg.
			len := inst concretizeAt: 0.
			memory replaceFrom: 1 to: len with: inst machineCode object startingAt: 1.
			self pairs: (-2 to: 2)  do:
				[:a :b| | bogus |
				self processor
					reset;
					perform: srsetter with: a signedIntToLong;
					perform: drsetter with: b signedIntToLong;
					singleStepIn: memory.
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
						ifTrue: [self assert: (self processor perform: getter) signedIntFromLong = expected]
						ifFalse:
							[(self processor perform: getter) signedIntFromLong ~= expected ifTrue:
								[bogus := true]]].
					assertPrintBar ifFalse:
						[Transcript
							nextPutAll: drgetter; nextPut: $(; print: b; nextPutAll: ') - ';
							nextPutAll: srgetter; nextPut: $(; print: a; nextPutAll: ') = ';
							print: (self processor perform: drgetter) signedIntFromLong; cr; flush.
						 bogus ifTrue:
							[self processor printRegistersOn: Transcript.
							 Transcript show: (self processor disassembleInstructionAt: 0 In: memory); cr]]]]]
]

{ #category : #tests }
AbstractInstructionTests >> testBinaryConditionalJumps [
	"CogIA32CompilerTests new testBinaryConditionalJumps"
	"CogIA32CompilerTests new runBinaryConditionalJumps: false"
	self runBinaryConditionalJumps: true
]

{ #category : #tests }
AbstractInstructionTests >> testBinaryConditionalJumpsViaCmpCqR [
	"CogIA32CompilerTests new testBinaryConditionalJumpsViaCmpCqR"
	"CogIA32CompilerTests new runBinaryConditionalJumpsViaCmpCqR: false"
	self runBinaryConditionalJumpsViaCmpCqR: true
]

{ #category : #tests }
AbstractInstructionTests >> testRunAddCqR [
	"self new testRunAddCqR"
	self runAddCqR: true
]

{ #category : #tests }
AbstractInstructionTests >> testRunAddCwR [
	"self new testRunAddCwR"
	self runAddCwR: true
]

{ #category : #tests }
AbstractInstructionTests >> testRunAddRR [
	"self new testRunAddRR"
	self runAddRR: true
]

{ #category : #tests }
AbstractInstructionTests >> testRunArithmeticShiftRightRR [
	"self new testRunArithmeticShiftRightRR"
	self runArithmeticShiftRightRR: true
]

{ #category : #tests }
AbstractInstructionTests >> testRunSubCqR [
	"self new testRunSubCqR"
	self runSubCqR: true
]

{ #category : #tests }
AbstractInstructionTests >> testRunSubCwR [
	"self new testRunSubCwR"
	self runSubCwR: true
]

{ #category : #tests }
AbstractInstructionTests >> testRunSubRR [
	"self new testRunSubRR"
	self runSubRR: true
]
