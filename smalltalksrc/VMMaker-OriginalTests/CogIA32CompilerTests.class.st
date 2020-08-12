Class {
	#name : #CogIA32CompilerTests,
	#superclass : #AbstractInstructionTests,
	#category : #'VMMaker-OriginalTests'
}

{ #category : #'abstract instructions' }
CogIA32CompilerTests >> Label [
	^self gen: Label operand: opcodes size
]

{ #category : #running }
CogIA32CompilerTests >> assertCheckLongArithOpCodeSize: bytes [
	self assert: bytes > 4
]

{ #category : #running }
CogIA32CompilerTests >> assertCheckQuickArithOpCodeSize: bytes [
	self assert: bytes <= 3
]

{ #category : #accessing }
CogIA32CompilerTests >> concreteCompilerClass [
	^CogIA32CompilerForTests
]

{ #category : #accessing }
CogIA32CompilerTests >> methodLabel [
	"There is no methodLabel in test code."
	^nil
]

{ #category : #accessing }
CogIA32CompilerTests >> processor [
	processor ifNil:
		[processor := BochsIA32Alien new].
	^processor
]

{ #category : #accessing }
CogIA32CompilerTests >> strip: aFancyDisassembledInstruction [
	"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
	^((((aFancyDisassembledInstruction
		copyReplaceAll: '%ds:' with: '')
			copyReplaceAll: '%ss:' with: '')
				allButFirst: (aFancyDisassembledInstruction indexOf: $:) + 1)
					copyUpTo: $:)
						allButLast: 1
]

{ #category : #tests }
CogIA32CompilerTests >> testAddCqR [
	"self new testAddCqR"
	self concreteCompilerClass registersWithNamesDo:
		[:reg :regname|
		#(16r1 16r3 16r7 16r555555 16rAAAAAA) do:
			[:const| | inst len|
			inst := self gen: AddCqR operand: const operand: reg.
			len := inst concretizeAt: 0.
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
					plainJane := self strip: str.
					herIntended := 'addl $0x', (const printStringBase: 16 length: 8 padded: true), ', ', regname.
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testAndCqR [
	"self new testAndCqR"
	self concreteCompilerClass registersWithNamesDo:
		[:reg :regname|
		#(16r1 16r3 16r7 16r555555 16rAAAAAA) do:
			[:const| | inst len|
			inst := self gen: AndCqR operand: const operand: reg.
			len := inst concretizeAt: 0.
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
					plainJane := self strip: str.
					herIntended := 'andl $0x', (const printStringBase: 16 length: 8 padded: true), ', ', regname.
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testArithmeticShiftRightRR [
	"CogIA32CompilerTests new testArithmeticShiftRightRR"
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:sreg :srgetter :srsetter|
		self concreteCompilerClass dataRegistersWithAccessorsDo:
			[:dreg :drgetter :drsetter| | inst len |
			inst := self gen: ArithmeticShiftRightRR operand: sreg operand: dreg.
			len := inst concretizeAt: 0.
			self assert: len = (srgetter = #ecx
								ifTrue: [2]
								ifFalse:
									[srgetter = #eax
										ifTrue: [4]
										ifFalse: [6]])
			"self processor disassembleFrom: 0 to: inst machineCodeSize in: inst machineCode object on: Transcript"]]
]

{ #category : #tests }
CogIA32CompilerTests >> testCMPXCHGAwR [
	"self new testCMPXCHGAwR"
	| cmpxchgAwR |
	cmpxchgAwR := CogIA32Compiler classPool at: #CMPXCHGAwR.
	CogIA32CompilerForTests registersWithNamesDo:
		[:reg :regname|
		#(16r555555 16rAAAAAA) do:
			[:addr| | inst len |
			inst := self gen: cmpxchgAwR operand: addr operand: reg.
			len := inst concretizeAt: 0.
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
					plainJane := self strip: str.
					herIntended := 'cmpxchgl ', regname, ', 0x', (addr hex allButFirst: 3).
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testCMPXCHGMwrR [
	"self new testCMPXCHGMwrR"
	| cmpxchgMwrR lock |
	cmpxchgMwrR := CogIA32Compiler classPool at: #CMPXCHGMwrR.
	lock := CogIA32Compiler classPool at: #LOCK.
	CogIA32CompilerForTests registersWithNamesDo:
		[:sreg :srname|
		CogIA32CompilerForTests registersWithNamesDo:
			[:dreg :drname|
			((1 to: 19 by: 3) collect: [:po2| 2 raisedToInteger: po2]) do:
				[:offset|
				#(false true) do:
					[:prefixLock| | memory |
					self resetGen.
					prefixLock ifTrue: [self gen: lock].
					self gen: cmpxchgMwrR operand: offset operand: sreg operand: dreg.
					memory := self generateInstructions.
					self processor
						disassembleInstructionAt: 0
						In: memory
						into: [:str :sz| | plainJane herIntended |
							plainJane := self strip: str.
							herIntended := (prefixLock ifTrue: ['lock '] ifFalse: ['']),
											'cmpxchgl ', drname, ', 0x', (offset hex allButFirst: 3), '(', srname, ')'.
							self assert: herIntended equals: plainJane.
							self assert: memory size = sz]]]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testCmpCqR [
	"self new testCmpCqR"
	self concreteCompilerClass registersWithNamesDo:
		[:reg :regname|
		#(16r1 16r3 16r7 16r555555 16rAAAAAA) do:
			[:const| | inst len|
			inst := self gen: CmpCqR operand: const operand: reg.
			len := inst concretizeAt: 0.
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
					plainJane := self strip: str.
					herIntended := 'cmpl $0x', (const printStringBase: 16 length: 8 padded: true), ', ', regname.
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testDivQuoRem [
	"| failures ops |
	 failures := Set new.
	 [ops := (CogIA32CompilerTests new testDivQuoRem)]
		on: TestResult failure
		do: [:ex| | c |
			c := ex signalerContext.
			[c tempNames includes: 'op'] whileFalse:
				[c := c sender].
			failures add: (c namedTempAt: (c tempNames indexOf: 'op')).
			ex resume].
	 { ops size. failures size. ops asSortedCollection asArray. failures asSortedCollection asArray}"
	| map compiler memory ops |
	map := Dictionary new.
	compiler := self gen: nil.
	memory := ByteArray new: 4096 * 2.
	ops := Set new.
	CogIA32CompilerForTests dataRegistersWithAccessorsExcept: #(ebp esp) do:
		[:sreg :srget :srset|
		CogIA32CompilerForTests dataRegistersWithAccessorsExcept: { #ebp. #esp. srget } do:
			[:dreg :drget :drset|
			 | instructions op |
			CogIA32CompilerForTests dataRegistersWithAccessorsExcept: #(ebp esp) do:
				[:qreg :qrget :qrset| 
				CogIA32CompilerForTests dataRegistersWithAccessorsExcept: { #ebp. #esp. qrget } do:
					[:rreg :rrget :rrset|
					self resetGen.
					op := qrget, ' := ', drget, ' quo: ', srget, '. ', rrget, ' := ', drget, ' rem: ', srget.
					ops add: op.
					compiler genDivR: sreg R: dreg Quo: qreg Rem: rreg.
					instructions := self generateInstructions.
					memory atAllPut: 0; replaceFrom: 1 to: instructions size with: instructions startingAt: 1; at: instructions size + 1 put: self processor nopOpcode.
					#(-768 -456 -123 123 456 789)
						with: #(987 654 321 -321 -654 -987)
						do: [:dd :dv| "| calc |
							calc := ((dd quo: dv) bitAnd: 16rFFFFFFFF) hex, ' := ', (dd bitAnd: 16rFFFFFFFF) hex, ' quo: ', (dv bitAnd: 16rFFFFFFFF) hex, '. ', ((dd rem: dv) bitAnd: 16rFFFFFFFF) hex, ' := ', (dd bitAnd: 16rFFFFFFFF) hex, ' rem: ', (dv bitAnd: 16rFFFFFFFF) hex.
							calc := calc."
							"Transcript cr; cr; nextPutAll: op; cr; nextPutAll: calc; cr.
							 self processor
								disassembleFrom: 0 to: instructions size in: memory on: Transcript;
								printIntegerRegistersOn: Transcript."
							map
								at: #eax put: (self processor eax: 16rA5A5A5A5);
								at: #ebx put: (self processor ebx: 16rB5B5B5B5);
								at: #ecx put: (self processor ecx: 16rC5C5C5C5);
								at: #edx put: (self processor edx: 16rD5D5D5D5);
								at: #esi put: (self processor esi: 16r51515151);
								at: #edi put: (self processor edi: 16rD1D1D1D1);
								at: srget put: (self processor perform: srset with: dv signedIntToLong);
								at: drget put: (self processor perform: drset with: dd signedIntToLong).
							self processor esp: memory size; eip: 0.
							self shouldnt:
								[[self processor pc < instructions size] whileTrue:
									[self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2]]
								raise: Error.
							map
								at: qrget put: (dd quo: dv) signedIntToLong;
								at: rrget put: (dd rem: dv) signedIntToLong.
							map keysAndValuesDo:
								[:accessor :value|
								self assert: value = (self processor perform: accessor)]]]]]].
	^ops
]

{ #category : #tests }
CogIA32CompilerTests >> testLogicalShiftRightCqR [
	"CogIA32CompilerTests new testLogicalShiftRightCqR"
	self concreteCompilerClass registersWithNamesDo:
		[:reg :regname|
		1 to: 31 do:
			[:shift| | inst len |
			inst := self gen: LogicalShiftRightCqR operand: shift operand: reg.
			len := inst concretizeAt: 0.
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
					plainJane := self strip: str.
					herIntended := 'shrl $', (shift > 1
												ifTrue: ['0x', (shift printStringBase: 16 length: 2 padded: true)]
												ifFalse: [shift asInteger]), ', ', regname.
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testMoveAbR [
	"self new testMoveAbR"
	CogIA32CompilerForTests registersWithNamesDo:
		[:reg :regname|
		#(16r555555 16rAAAAAA) do:
			[:addr| | inst len |
			inst := self gen: MoveAbR operand: addr operand: reg.
			len := inst concretizeAt: 0.
			self assert: inst byteReadsZeroExtend.
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
					plainJane := self strip: str.
					herIntended := 'movzbl 0x', (addr hex allButFirst: 3), ', ', regname.
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testMoveAwR [
	"self new testMoveAwR"
	CogIA32CompilerForTests registersWithNamesDo:
		[:reg :regname|
		#(16r555555 16rAAAAAA) do:
			[:addr| | inst len |
			inst := self gen: MoveAwR operand: addr operand: reg.
			len := inst concretizeAt: 0.
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
					plainJane := self strip: str.
					herIntended := 'movl 0x', (addr hex allButFirst: 3), ', ', regname.
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testMoveM16rR [
	"self new testMoveM16rR"
	CogIA32CompilerForTests registersWithNamesDo:
		[:sreg :srname|
		CogIA32CompilerForTests registersWithNamesDo:
			[:dreg :drname|
			((1 to: 19 by: 3) collect: [:po2| 2 raisedToInteger: po2]) do:
				[:offset| | inst len |
				inst := self gen: MoveM16rR operand: offset operand: sreg operand: dreg.
				len := inst concretizeAt: 0.
				self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended |
						plainJane := self strip: str.
						herIntended := 'movzwl 0x', (offset hex allButFirst: 3), '(', srname, '), ', drname.
						self assert: herIntended equals: plainJane.
						self assert: len = sz]]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testMoveM64rRd [
	"self new testMoveM64rRd"
	CogIA32CompilerForTests registersWithNamesDo:
		[:sreg :srname|
		CogIA32CompilerForTests xmmRegistersWithNamesDo:
			[:dreg :drname|
			((1 to: 19 by: 3) collect: [:po2| 2 raisedToInteger: po2]) do:
				[:offset| | inst len |
				inst := self gen: MoveM64rRd operand: offset operand: sreg operand: dreg.
				len := inst concretizeAt: 0.
				self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended |
						plainJane := self strip: str.
						herIntended := 'movsd 0x', (offset hex allButFirst: 3), '(', srname, '), ', drname.
						self assert: herIntended equals: plainJane.
						self assert: len = sz]]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testMoveMbrR [
	"self new testMoveMbrR"
	CogIA32CompilerForTests registersWithNamesDo:
		[:sreg :srname|
		CogIA32CompilerForTests registersWithNamesDo:
			[:dreg :drname|
			((1 to: 19 by: 3) collect: [:po2| 2 raisedToInteger: po2]) do:
				[:offset| | inst len |
				inst := self gen: MoveMbrR operand: offset operand: sreg operand: dreg.
				len := inst concretizeAt: 0.
				self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended |
						plainJane := self strip: str.
						herIntended := 'movzbl 0x', (offset hex allButFirst: 3), '(', srname, '), ', drname.
						self assert: herIntended equals: plainJane.
						self assert: len = sz]]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testMoveMwrR [
	"self new testMoveMwrR"
	self concreteCompilerClass registersWithNamesDo:
		[:sreg :srname|
		self concreteCompilerClass registersWithNamesDo:
			[:dreg :drname| | inst len |
			#(0 64 65536 -64 -65536) do:
				[:offset|
				inst := self gen: MoveMwrR operand: offset operand: sreg operand: dreg.
				len := inst concretizeAt: 0.
				self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended po |
						plainJane := self strip: str.
						po := offset bitAnd: 1 << self processor bitsInWord - 1.
						herIntended := 'movl ', (offset = 0 ifTrue: [''] ifFalse: ['0x', (po printStringBase: 16)]), '(', srname, '), ', drname.
						self assert: herIntended equals: plainJane.
						self assert: len = sz]]]]

	"| failures |
	 failures := Dictionary new.
	 self concreteCompilerClass registersWithNamesDo:
		[:sreg :srname|
		self concreteCompilerClass registersWithNamesDo:
			[:dreg :drname| | inst len |
			#(0 64 65536 -64 -65536) do:
				[:offset|
				inst := self gen: MoveMwrR operand: offset operand: sreg operand: dreg.
				len := inst concretizeAt: 0.
				self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended po |
						plainJane := self strip: str.
						po := offset bitAnd: 1 << self processor bitsInWord - 1.
						herIntended := 'movl ', (offset = 0 ifTrue: [''] ifFalse: ['0x', (po printStringBase: 16)]), '(', srname, '), ', drname.
						((plainJane match: herIntended) and: [len = sz]) ifFalse:
							[failures at: herIntended put: plainJane]]]]].
	 failures"
]

{ #category : #tests }
CogIA32CompilerTests >> testMoveRAb [
	"self new testMoveRAb"
	CogIA32CompilerForTests byteRegistersWithNamesDo:
		[:reg :regname|
		#(16r555555 16rAAAAAA) do:
			[:addr| | inst len |
			inst := self gen: MoveRAb operand: reg operand: addr.
			len := inst concretizeAt: 0.
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'movb ', regname, ', 0x', (addr hex allButFirst: 3).
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testMoveRAw [
	"self new testMoveRAw"
	CogIA32CompilerForTests registersWithNamesDo:
		[:reg :regname|
		#(16r555555 16rAAAAAA) do:
			[:addr| | inst len |
			inst := self gen: MoveRAw operand: reg operand: addr.
			len := inst concretizeAt: 0.
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'movl ', regname, ', 0x', (addr hex allButFirst: 3).
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testMoveRM16r [
	"self new testMoveRM16r"
	CogIA32CompilerForTests registersWithNamesDo:
		[:sreg :srname|
		CogIA32CompilerForTests registersWithNamesDo:
			[:dreg :drname|
			((1 to: 19 by: 3) collect: [:po2| 2 raisedToInteger: po2]) do:
				[:offset| | inst len |
				inst := self gen: MoveRM16r operand: sreg operand: offset operand: dreg.
				len := inst concretizeAt: 0.
				self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended |
						plainJane := self strip: str.
						herIntended := 'movw ', (srname copyWithout: $e), ', 0x', (offset hex allButFirst: 3), '(', drname, ')'.
						self assert: herIntended equals: plainJane.
						self assert: len = sz]]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testMoveRMbr [
	"self new testMoveRMbr"
	CogIA32CompilerForTests byteRegistersWithNamesDo:
		[:sreg :srname|
		CogIA32CompilerForTests registersWithNamesDo:
			[:dreg :drname|
			((1 to: 19 by: 3) collect: [:po2| 2 raisedToInteger: po2]) do:
				[:offset| | inst len |
				inst := self gen: MoveRMbr operand: sreg operand: offset operand: dreg.
				len := inst concretizeAt: 0.
				self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended |
						plainJane := self strip: str.
						herIntended := 'movb ', srname, ', 0x', (offset hex allButFirst: 3), '(', drname, ')'.
						self assert: herIntended equals: plainJane.
						self assert: len = sz]]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testMoveRMwr [
	"self new testMoveRMwr"
	self concreteCompilerClass registersWithNamesDo:
		[:sreg :srname|
		self concreteCompilerClass registersWithNamesDo:
			[:dreg :drname| | inst len |
			#(0 64 65536 -64 -65536) do:
				[:offset|
				inst := self gen: MoveRMwr operand: sreg operand: offset operand: dreg.
				len := inst concretizeAt: 0.
				self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended po |
						"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
						plainJane := self strip: str.
						po := offset bitAnd: 1 << self processor bitsInWord - 1.
						herIntended := 'movl ', srname, ', ', (offset = 0 ifTrue: [''] ifFalse: ['0x', (po printStringBase: 16)]), '(',drname,')'.
						self assert: herIntended equals: plainJane.
						self assert: len = sz]]]]

	"| failures |
	 failures := Dictionary new.
	 self concreteCompilerClass registersWithNamesDo:
		[:sreg :srname|
		self concreteCompilerClass registersWithNamesDo:
			[:dreg :drname| | inst len |
			#(0 64 65536 -64 -65536) do:
				[:offset|
				inst := self gen: MoveRMwr operand: sreg operand: offset operand: dreg.
				len := inst concretizeAt: 0.
				self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended po |
						plainJane := self strip: str.
						po := offset bitAnd: 1 << self processor bitsInWord - 1.
						herIntended := 'movl ', srname, ', ', (offset = 0 ifTrue: [''] ifFalse: ['0x', (po printStringBase: 16)]), '(',drname,')'.
						((plainJane match: herIntended) and: [len = sz]) ifFalse:
							[failures at: herIntended put: plainJane]]]]].
	 failures"
]

{ #category : #tests }
CogIA32CompilerTests >> testMoveRXbrR [
	"self new testMoveRXbrR"
	self concreteCompilerClass registersWithNamesDo:
		[:idxreg :irname|
		irname ~= '%esp' ifTrue:
			[self concreteCompilerClass registersWithNamesDo:
				[:basereg :brname|
				self concreteCompilerClass byteRegistersWithNamesDo:
					[:sreg :srname| | inst len |
					inst := self gen: MoveRXbrR operand: sreg operand: idxreg operand: basereg.
					len := inst concretizeAt: 0.
					self processor
						disassembleInstructionAt: 0
						In: inst machineCode object
						into: [:str :sz| | plainJane herIntended |
							plainJane := self strip: str.
							herIntended := 'movb ', srname, ', (', brname, ',', irname, ',1)'.
							self assert: herIntended equals: plainJane.
							self assert: len = sz]]]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testMoveRXwrR [
	"self new testMoveRXwrR"
	self concreteCompilerClass registersWithNamesDo:
		[:idxreg :irname|
		irname ~= '%esp' ifTrue:
			[self concreteCompilerClass registersWithNamesDo:
				[:basereg :brname|
				self concreteCompilerClass registersWithNamesDo:
					[:sreg :srname| | inst len |
					inst := self gen: MoveRXwrR operand: sreg operand: idxreg operand: basereg.
					len := inst concretizeAt: 0.
					self processor
						disassembleInstructionAt: 0
						In: inst machineCode object
						into: [:str :sz| | plainJane herIntended |
							plainJane := self strip: str.
							herIntended := 'movl ', srname, ', (', brname, ',', irname, ',4)'.
							self assert: herIntended equals: plainJane.
							self assert: len = sz]]]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testMoveRdM64r [
	"self new testMoveRdM64r"
	CogIA32CompilerForTests xmmRegistersWithNamesDo:
		[:sreg :srname|
		CogIA32CompilerForTests registersWithNamesDo:
			[:dreg :drname|
			((1 to: 19 by: 3) collect: [:po2| 2 raisedToInteger: po2]) do:
				[:offset| | inst len |
				inst := self gen: MoveRdM64r operand: sreg operand: offset operand: dreg.
				len := inst concretizeAt: 0.
				self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended |
						plainJane := self strip: str.
						herIntended := 'movsd ', srname, ', 0x', (offset hex allButFirst: 3), '(', drname, ')'.
						self assert: herIntended equals: plainJane.
						self assert: len = sz]]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testMoveXbrRR [
	"self new testMoveXbrRR"
	CogIA32CompilerForTests registersWithNamesDo:
		[:idxreg :irname|
		irname ~= '%esp' ifTrue:
			[CogIA32CompilerForTests registersWithNamesDo:
				[:basereg :brname|
				CogIA32CompilerForTests registersWithNamesDo:
					[:dreg :drname| | inst len |
					inst := self gen: MoveXbrRR operand: idxreg operand: basereg operand: dreg.
					len := inst concretizeAt: 0.
					self processor
						disassembleInstructionAt: 0
						In: inst machineCode object
						into: [:str :sz| | plainJane herIntended |
							"Convert e.g. '00000000: movzbl %ds:(%eax,%eax,1), %eax : 0F B6 04 00 ' to  'movzbl (%eax,%eax,1)'"
							plainJane := self strip: str.
							herIntended := 'movzbl (', brname, ',', irname, ',1), ',drname.
							self assert: herIntended equals: plainJane.
							self assert: len = sz]]]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testMoveXwrRR [
	"self new testMoveXwrRR"
	CogIA32CompilerForTests registersWithNamesDo:
		[:idxreg :irname|
			irname ~= '%esp' ifTrue:
				[CogIA32CompilerForTests registersWithNamesDo:
					[:basereg :brname|
					CogIA32CompilerForTests registersWithNamesDo:
						[:dreg :drname| | inst len |
						inst := self gen: MoveXwrRR operand: idxreg operand: basereg operand: dreg.
						len := inst concretizeAt: 0.
						self processor
							disassembleInstructionAt: 0
							In: inst machineCode object
							into: [:str :sz| | plainJane herIntended |
								"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
								plainJane := self strip: str.
								herIntended := 'movl (', brname, ',', irname, ',4), ',drname.
								self assert: herIntended equals: plainJane.
								self assert: len = sz]]]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testMul [
	"CogIA32CompilerTests new setUp testMul"
	| map compiler memory |
	map := Dictionary new.
	compiler := self gen: nil.
	memory := ByteArray new: 1024.
	CogIA32CompilerForTests dataRegistersWithAccessorsExcept: #(ebp esp) do:
		[:sreg :srget :srset|
		CogIA32CompilerForTests dataRegistersWithAccessorsExcept: { #ebp. #esp. srget } do:
			[:dreg :drget :drset| | instructions |
			self resetGen.
			compiler genMulR: sreg R: dreg.
			instructions := self generateInstructions.
			memory atAllPut: 0; replaceFrom: 1 to: instructions size with: instructions startingAt: 1.
			#(-768 -456 -123 123 456 789)
				with: #(987 654 321 -321 -654 -987)
				do: [:a :b|
					"self processor
						disassembleFrom: 0 to: instructions size in: memory on: Transcript;
						printIntegerRegistersOn: Transcript."
					map
						at: #eax put: (self processor eax: 16rA5A5A5A5);
						at: #ebx put: (self processor ebx: 16rB5B5B5B5);
						at: #ecx put: (self processor ecx: 16rC5C5C5C5);
						at: #edx put: (self processor edx: 16rD5D5D5D5);
						at: #esi put: (self processor esi: 16r51515151);
						at: #edi put: (self processor edi: 16rD1D1D1D1);
						at: srget put: (self processor perform: srset with: b signedIntToLong);
						at: drget put: (self processor perform: drset with: a signedIntToLong).
					self processor esp: memory size; eip: 0.
					self shouldnt:
						[[self processor pc < instructions size] whileTrue:
							[self processor singleStepIn: memory]]
						raise: Error.
					map at: drget put: (a * b) signedIntToLong.
					map keysAndValuesDo:
						[:accessor :value|
						self assert: value = (self processor perform: accessor)]]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testOrCqR [
	"self new testOrCqR"
	self concreteCompilerClass registersWithNamesDo:
		[:reg :regname|
		#(16r1 16r3 16r7 16r555555 16rAAAAAA) do:
			[:const| | inst len|
			inst := self gen: OrCqR operand: const operand: reg.
			len := inst concretizeAt: 0.
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
					plainJane := self strip: str.
					herIntended := 'orl $0x', (const printStringBase: 16 length: 8 padded: true), ', ', regname.
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testSubCqR [
	"self new testSubCqR"
	self concreteCompilerClass registersWithNamesDo:
		[:reg :regname|
		#(16r1 16r3 16r7 16r555555 16rAAAAAA) do:
			[:const| | inst len|
			inst := self gen: SubCqR operand: const operand: reg.
			len := inst concretizeAt: 0.
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
					plainJane := self strip: str.
					herIntended := 'subl $0x', (const printStringBase: 16 length: 8 padded: true), ', ', regname.
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testTstCqR [
	"self new testTstCqR"
	self concreteCompilerClass registersWithNamesDo:
		[:reg :theRegname|
		#(16r1 16r3 16r7 16r555555 16rAAAAAA) do:
			[:const| | op regname inst len constString|
			inst := self gen: TstCqR operand: const operand: reg.
			len := inst concretizeAt: 0.
			((inst isQuick: const) and: [reg < 4])
				ifTrue:
					[op := 'testb'.
					 regname := #('%al' '%cl' '%dl' '%bl') at: reg + 1.
					 constString := const printStringBase: 16 length: 2 padded: true]
				ifFalse:
					[op := 'testl'.
					 regname := theRegname.
					 constString := const printStringBase: 16 length: 8 padded: true].
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
					plainJane := self strip: str.
					herIntended := op, ' $0x', constString, ', ', regname.
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testXCHGAwR [
	"self new testXCHGAwR"
	| xchgAwR |
	xchgAwR := CogIA32Compiler classPool at: #XCHGAwR.
	CogIA32CompilerForTests registersWithNamesDo:
		[:reg :regname|
		#(16r555555 16rAAAAAA) do:
			[:addr| | inst len |
			inst := self gen: xchgAwR operand: addr operand: reg.
			len := inst concretizeAt: 0.
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
					plainJane := self strip: str.
					herIntended := 'xchgl ', regname, ', 0x', (addr hex allButFirst: 3).
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]
]

{ #category : #tests }
CogIA32CompilerTests >> testXCHGMwrR [
	"self new testXCHGMwrR"
	| xchgMwrR |
	xchgMwrR := CogIA32Compiler classPool at: #XCHGMwrR.
	CogIA32CompilerForTests registersWithNamesDo:
		[:sreg :srname|
		CogIA32CompilerForTests registersWithNamesDo:
			[:dreg :drname|
			((1 to: 19 by: 3) collect: [:po2| 2 raisedToInteger: po2]) do:
				[:offset| | memory |
				self resetGen.
				self gen: xchgMwrR operand: offset operand: sreg operand: dreg.
				memory := self generateInstructions.
				self processor
					disassembleInstructionAt: 0
					In: memory
					into: [:str :sz| | plainJane herIntended |
						plainJane := self strip: str.
						herIntended := 'xchgl ', drname, ', 0x', (offset hex allButFirst: 3), '(', srname, ')'.
						self assert: herIntended equals: plainJane.
						self assert: memory size = sz]]]]
]
