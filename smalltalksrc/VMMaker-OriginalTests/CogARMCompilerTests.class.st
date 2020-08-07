Class {
	#name : #CogARMCompilerTests,
	#superclass : #AbstractInstructionTests,
	#category : #'VMMaker-OriginalTests'
}

{ #category : #running }
CogARMCompilerTests >> assertCheckLongArithOpCodeSize: bytes [
	self assert: bytes > 4
]

{ #category : #running }
CogARMCompilerTests >> assertCheckQuickArithOpCodeSize: bytes [
	"The problem is that there are negative value, which are not quick encodable in ARM"
	self assert: bytes <= 4
]

{ #category : #accessing }
CogARMCompilerTests >> concreteCompilerClass [
	^CogARMCompilerForTests
]

{ #category : #private }
CogARMCompilerTests >> disassembleInstructionAt: index In: inst into: binaryBlock [
	"Manage the fact that in the simulator inst machineCode object is an Array and the disassembler requires a ByteArray or some such."
	^self processor
		disassembleInstructionAt: index
		In: (self memoryAsBytes: inst machineCode object)
		into: binaryBlock
]

{ #category : #private }
CogARMCompilerTests >> memoryAsBytes: instructionMachineCode [
	"Manage the fact that in the simulator inst machineCode object is an Array and the disassembler requires a ByteArray or some such."
	| bytes |
	instructionMachineCode isCObjectAccessor ifTrue:
		[^self memoryAsBytes: instructionMachineCode object].
	instructionMachineCode isArray ifFalse:
		[self assert: instructionMachineCode class isBits.
		 ^instructionMachineCode].
	bytes := ByteArray new: instructionMachineCode size * 4.
	1 to: instructionMachineCode size do:
		[:i|
		(instructionMachineCode at: i) ifNotNil:
			[:word|
			bytes unsignedLongAt: i - 1* 4 + 1 put: word]].
	^bytes
]

{ #category : #'cogit compatibility' }
CogARMCompilerTests >> objectMemory [
	^self
]

{ #category : #accessing }
CogARMCompilerTests >> processor [
	processor ifNil:
		[processor := GdbARMAlien new].
	^processor
]

{ #category : #accessing }
CogARMCompilerTests >> strip: aFancyDisassembledInstruction [
	"When an immediate > 15, the disassembler appends '	; 0x\d\d'. That is stripped. Also strip any prepended stuff delimted by $: - perhaps memory addresses etc?"
	^((aFancyDisassembledInstruction 
		allButFirst: (aFancyDisassembledInstruction indexOf: $: ifAbsent:[-1]) + 1)
			copyUpTo: $;) withBlanksTrimmed
]

{ #category : #tests }
CogARMCompilerTests >> testAdd [
	"self new testAdd"
	
	"the forms are valid, "
	"test AddCqR"
	self concreteCompilerClass registersWithNamesDo: [ :reg :regName |
		#(0 16rF 16rFF) do:
			[:n| | inst len |
			inst := self gen: AddCqR operand: n operand: reg.
			len := inst concretizeAt: 0.
			self
				disassembleInstructionAt: 0
				In: inst
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'adds	', regName, ', ', regName, ', #', n asString.
					self assert: herIntended equals: plainJane]]].
		
	"test AddCwR"
	self concreteCompilerClass registersWithNamesDo: [ :reg :regName |
		#(16rFFFFFFFF 16r88888888 0) do:
			[:n| | inst len |
			inst := self gen: AddCwR operand: n operand: reg.
			len := inst concretizeAt: 0.
			self
				disassembleInstructionAt: 0
				In: inst
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'mov	ip, #', (n bitAnd: 16rFF << 24) signedIntFromLong asString.
					self assert: herIntended equals: plainJane].
			self
				disassembleInstructionAt: 4
				In: inst
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'orr	ip, ip, #', (n bitAnd: 16rFF << 16) asString.
					self assert: herIntended equals: plainJane].
			self
				disassembleInstructionAt: 8
				In: inst
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'orr	ip, ip, #', (n bitAnd: 16rFF << 8) signedIntFromLong asString.
					self assert: herIntended equals: plainJane].
			self
				disassembleInstructionAt: 12
				In: inst
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'orr	ip, ip, #', (n bitAnd: 16rFF) asString.
					self assert: herIntended equals: plainJane].
			self
				disassembleInstructionAt: 16
				In: inst
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'adds	', regName, ', ', regName, ', ip'.
					self assert: herIntended equals: plainJane]]]

]

{ #category : #tests }
CogARMCompilerTests >> testGenerateMul [
	"self new testGenerateMul"
	"Currently demonstrates that the CogARMCompiler>genMulR:R: algorithm ain't gonna work too well"
	
	|memory compiler |
	compiler := self gen: nil. "grab something usefully like a compiler for later abuse"
	self resetGen. "initialise important stuff"

	"test MulRR"
	self gen: LogicalShiftLeftCqR operand: 1 operand:1. "LSL r1 - to make the right bit pattern for a SmallInt that has had the flag masked out"
	self gen: LogicalShiftLeftCqR operand: 1 operand:0. "LSL r1 - to make the right bit pattern for a SmallInt that has had the flag masked out"
	self gen: MoveRR operand: 0 operand: 2.
	compiler genMulR: 1 R: 0.
	memory := self generateInstructions.
	self disassembleOpcodesIn: memory to: Transcript	.
	{SmallInteger maxVal@2. SmallInteger minVal@2. 0@0. 1@1. -1@0. -1@1. -1@ -1} do:[:val | | x y |
			x := val x.
			y := val y.
			self processor reset.
			processor signedLongAt: 13 put: x;
				signedLongAt: 17 put: y.
			[[processor pc < memory size] whileTrue:
						[self processor singleStepIn: memory]]
						on: Error
						do: [:ex| ].
			Transcript show: x asString, ' * ', y asString; cr.
			processor printRegisterState: processor registerState on: Transcript.
			Transcript flush]
	

]

{ #category : #tests }
CogARMCompilerTests >> testMoveCwR [
	"self new testMoveCwR"
	
	#(16rFF00FF00 16r00000012 16r12345678) do:
		[:n|
		self concreteCompilerClass dataRegistersWithAccessorsDo: 
			[ :r :rgetter :rset | | inst len memory |
			inst := self gen: MoveCwR operand: n operand: r.
			len := inst concretizeAt: 0.
			memory := self memoryAsBytes: inst machineCode.
			self processor
				reset.
			[[processor pc < inst machineCodeSize] whileTrue:
				[self processor singleStepIn: memory]]
				on: Error
				do: [:ex| ].
			self concreteCompilerClass dataRegistersWithAccessorsDo:
				[:ireg :getter :setter| | expected |
				expected := getter == rgetter ifTrue: [ n ] ifFalse: [0].
				self assert: (self processor perform: getter) = expected].
			self assert: self processor pc = 16]]

]

{ #category : #tests }
CogARMCompilerTests >> testPerformAdd [
	"self new testPerformAdd"
	
	| memory |
	#(16rFF00FF00 16r00000012 16r12345678) do:
		[:n| | |
		self concreteCompilerClass dataRegistersWithAccessorsDo: 
			[ :r :rgetter :rset |
			self resetGen. "initialise important stuff"
 			self gen: MoveCwR operand: n operand: r.
			self gen: AddCqR operand: 42 operand: r.
			memory := self generateInstructions.
			"self disassembleOpcodesIn: memory to: Transcript."
			self processor
				reset.
			[[processor pc < memory size] whileTrue:
				[self processor singleStepIn: memory]]
				on: Error
				do: [:ex| ].
			self concreteCompilerClass dataRegistersWithAccessorsDo:
				[:ireg :getter :setter| | expected |
				expected := getter == rgetter ifTrue: [ n + 42] ifFalse: [0].
				self assert: (self processor perform: getter) = expected].
			self assert: self processor pc = 20]]

]

{ #category : #tests }
CogARMCompilerTests >> testPrefetchAw [
	"self new testPrefetchAw"
	
	#(16rFF00FF00 16r00000012) do:
		[:n| | inst len |
		inst := self gen: PrefetchAw operand: n.
		len := inst concretizeAt: 0.
		self
			disassembleInstructionAt: 12
			In: inst
			into: [:str :sz| | plainJane herIntended |
				"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
				plainJane := self strip: str.
				herIntended := 'pld	[sl', ((n bitAnd: 16rFF) = 0 ifTrue: [''] ifFalse: [', #', (n bitAnd: 16rFF) asString]) ,']'.
				self assert: herIntended equals: plainJane.
				self assert: len = 16]].

]

{ #category : #tests }
CogARMCompilerTests >> testPushR [
	"self new testPushR"
	
	self concreteCompilerClass registersWithNamesDo:
		[:r :name | | inst len |
		inst := self gen: PushR operand: r.
		len := inst concretizeAt: 0.
		self
			disassembleInstructionAt: 0
			In: inst
			into: [:str :sz| | plainJane herIntended |
				"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
				plainJane := self strip: str.
				herIntended := 'push	{', name ,'}'.
				self assert: herIntended equals: plainJane.
				self assert: len = 4]].

]

{ #category : #tests }
CogARMCompilerTests >> testRetN [
	"self new testRetN"
	
	#(0) do:
		[:n| | inst len |
		inst := self gen: RetN operand: n.
		len := inst concretizeAt: 0.
		self
			disassembleInstructionAt: 0
			In: inst
			into: [:str :sz| | plainJane  |
				"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
				plainJane := self strip: str.
				self assert: (plainJane match: 'mov	pc, lr').
				self assert: len = sz]].
	
	#(1 2 3 4 5 6 7) do:
		[:n| | inst len |
		inst := self gen: RetN operand: n * 4.
		len := inst concretizeAt: 0.
		self
			disassembleInstructionAt: 0
			In: inst
			into: [:str :sz| | plainJane herIntended |
				plainJane := self strip: str.
				herIntended := 'add	sp, sp, #', (n * 4 )asString.
				self assert: herIntended equals: plainJane].
		self
			disassembleInstructionAt: 4
			In: inst
			into: [:str :sz| | plainJane |
				plainJane := self strip: str.
				self assert: (plainJane match: 'mov	pc, lr').		
		self assert: len = 8]]
]

{ #category : #'cogit compatibility' }
CogARMCompilerTests >> wordSize [
	^4
]
