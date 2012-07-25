Class {
	#name : #CogARMCompilerTests,
	#superclass : #AbstractInstructionTests,
	#category : #'VMMaker-Tests'
}

{ #category : #running }
CogARMCompilerTests >> assertCheckQuickArithOpCodeSize: bytes [
	"The problem is that there are negative value, which are not quick encodable in ARM"
	self assert: bytes <= 20
]

{ #category : #accessing }
CogARMCompilerTests >> concreteCompilerClass [
	^CogARMCompilerForTests
]

{ #category : #accessing }
CogARMCompilerTests >> processor [
	processor ifNil:
		[processor := GdbARMAlien new].
	^processor
]

{ #category : #accessing }
CogARMCompilerTests >> strip: aFancyDisassembledInstruction [
	"When havin an immediate > 15, the disassembler appends '	; 0x\d\d'. That is stripped."
	^(aFancyDisassembledInstruction copyUpTo: $;) withBlanksTrimmed
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
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'adds	', regName, ', ', regName, ', #', n asString.
					self assert: (plainJane match: herIntended)]]].
		
	"test AddCwR"
	self concreteCompilerClass registersWithNamesDo: [ :reg :regName |
		#(16rFFFFFFFF 16r88888888 0) do:
			[:n| | inst len |
			inst := self gen: AddCwR operand: n operand: reg.
			len := inst concretizeAt: 0.
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'mov	r3, #', (n bitAnd: 16rFF << 8) asString.
					self assert: (plainJane match: herIntended)].
			self processor
				disassembleInstructionAt: 4
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'orr	r3, r3, #', (n bitAnd: 16rFF << 16) asString.
					self assert: (plainJane match: herIntended)].
			self processor
				disassembleInstructionAt: 8
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'orr	r3, r3, #', (n bitAnd: 16rFF << 24) signedIntFromLong asString.
					self assert: (plainJane match: herIntended)].
			self processor
				disassembleInstructionAt: 12
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'orr	r3, r3, #', (n bitAnd: 16rFF) asString.
					self assert: (plainJane match: herIntended)].
			self processor
				disassembleInstructionAt: 16
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'adds	', regName, ', ', regName, ', r3'.
					self assert: (plainJane match: herIntended)]]]

]

{ #category : #tests }
CogARMCompilerTests >> testRetN [
	"self new testRetN"
	
	#(0) do:
		[:n| | inst len |
		inst := self gen: RetN operand: n.
		len := inst concretizeAt: 0.
		self processor
			disassembleInstructionAt: 0
			In: inst machineCode object
			into: [:str :sz| | plainJane herIntended |
				"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
				plainJane := self strip: str.
				herIntended := 'pop	{pc}'.
				self assert: (plainJane match: herIntended).
				self assert: len = sz]].
	
	#(1 2 4 8 16 31) do:
		[:n| | inst len |
		inst := self gen: RetN operand: n.
		len := inst concretizeAt: 0.
		self processor
			disassembleInstructionAt: 0
			In: inst machineCode object
			into: [:str :sz| | plainJane herIntended |
				"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
				plainJane := self strip: str.
				herIntended := 'add	sp, sp, #', n asString,', 30'.
				self assert: (plainJane match: herIntended).
				self assert: len = 8]]
]
