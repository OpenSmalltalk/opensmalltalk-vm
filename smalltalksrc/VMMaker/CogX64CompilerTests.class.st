Class {
	#name : #CogX64CompilerTests,
	#superclass : #AbstractInstructionTests,
	#category : #'VMMaker-Tests'
}

{ #category : #'abstract instructions' }
CogX64CompilerTests >> Label [
	^self gen: Label operand: opcodes size
]

{ #category : #running }
CogX64CompilerTests >> assertCheckLongArithOpCodeSize: bytes [
	self assert: bytes > 5
]

{ #category : #running }
CogX64CompilerTests >> assertCheckQuickArithOpCodeSize: bytes [
	self assert: bytes <= 4
]

{ #category : #accessing }
CogX64CompilerTests >> concreteCompilerClass [
	^CogX64CompilerForTests
]

{ #category : #accessing }
CogX64CompilerTests >> methodLabel [
	"There is no methodLabel in test code."
	^nil
]

{ #category : #accessing }
CogX64CompilerTests >> processor [
	processor ifNil:
		[processor := BochsX64Alien new].
	^processor
]

{ #category : #accessing }
CogX64CompilerTests >> strip: aFancyDisassembledInstruction [
	"Convert e.g. '00000000: movl %rax, 0x2(%rax) : 89 40 02' to  'movl %rax, 0x2(%rax)'"
	^((((aFancyDisassembledInstruction
		copyReplaceAll: '%ds:' with: '')
			copyReplaceAll: '%ss:' with: '')
				allButFirst: (aFancyDisassembledInstruction indexOf: $:) + 1)
					copyUpTo: $:)
						allButLast: 1
]

{ #category : #tests }
CogX64CompilerTests >> testAndCqR [
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
					"Convert e.g. '00000000: movl %rax, 0x2(%rax) : 48 89 40 02' to  'movl %rax, 0x2(%rax)'"
					plainJane := self strip: str.
					herIntended := 'andq $0x', (const printStringBase: 16 length: 16 padded: true), ', ', regname.
					self assert: (plainJane match: herIntended).
					self assert: len = sz]]]
]

{ #category : #tests }
CogX64CompilerTests >> testArithmeticShiftRightRR [
	"CogX64CompilerTests new testArithmeticShiftRightRR"
	self concreteCompilerClass dataRegistersWithAccessorsDo:
		[:sreg :srgetter :srsetter|
		self concreteCompilerClass dataRegistersWithAccessorsDo:
			[:dreg :drgetter :drsetter| | inst len |
			inst := self gen: ArithmeticShiftRightRR operand: sreg operand: dreg.
			len := inst concretizeAt: 0.
			self assert: len = (srgetter = #rcx
								ifTrue: [3]
								ifFalse:
									[srgetter = #rax
										ifTrue: [7]
										ifFalse: [9]])
			"self processor disassembleFrom: 0 to: inst machineCodeSize in: inst machineCode object on: Transcript"]]
]

{ #category : #tests }
CogX64CompilerTests >> testCMPXCHGAwR [
	"self new testCMPXCHGAwR"
	| cmpxchgAwR |
	cmpxchgAwR := CogX64Compiler classPool at: #CMPXCHGAwR.
	self concreteCompilerClass registersWithNamesDo:
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
					self assert: (plainJane match: herIntended).
					self assert: len = sz]]]
]

{ #category : #tests }
CogX64CompilerTests >> testCMPXCHGMwrR [
	"self new testCMPXCHGMwrR"
	| cmpxchgMwrR lock |
	cmpxchgMwrR := CogX64Compiler classPool at: #CMPXCHGMwrR.
	lock := CogX64Compiler classPool at: #LOCK.
	self concreteCompilerClass registersWithNamesDo:
		[:sreg :srname|
		self concreteCompilerClass registersWithNamesDo:
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
							self assert: (plainJane match: herIntended).
							self assert: memory size = sz]]]]]
]

{ #category : #tests }
CogX64CompilerTests >> testDivQuoRem [
	"| failures ops |
	 failures := Set new.
	 [ops := (CogX64CompilerTests new testDivQuoRem)]
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
	self concreteCompilerClass dataRegistersWithAccessorsExcept: #(rbp rsp) do:
		[:sreg :srget :srset|
		self concreteCompilerClass dataRegistersWithAccessorsExcept: { #rbp. #rsp. srget } do:
			[:dreg :drget :drset|
			 | instructions op |
			self concreteCompilerClass dataRegistersWithAccessorsExcept: #(rbp rsp) do:
				[:qreg :qrget :qrset| 
				self concreteCompilerClass dataRegistersWithAccessorsExcept: { #rbp. #rsp. qrget } do:
					[:rreg :rrget :rrset|
					self resetGen.
					op := qrget, ' := ', drget, ' quo: ', srget, '. ', rrget, ' := ', drget, ' rem: ', srget.
					ops add: op.
					compiler genDivR: sreg R: dreg Quo: qreg Rem: rreg.
					instructions := self generateInstructions.
					memory atAllPut: 0; replaceFrom: 1 to: instructions size with: instructions startingAt: 1; at: instructions size + 1 put: self processor nopOpcode.
					#(-768 -456 -123 123 456 789)
						with: #(987 654 321 -321 -654 -987)
						do: [:dd :dv| "| calc mask |
							mask := 16rFFFFFFFFFFFFFFFF.
							calc := ((dd quo: dv) bitAnd: mask) hex, ' := ', (dd bitAnd: mask) hex, ' quo: ', (dv bitAnd: mask) hex, '. ', ((dd rem: dv) bitAnd: mask) hex, ' := ', (dd bitAnd: mask) hex, ' rem: ', (dv bitAnd: mask) hex.
							calc := calc."
							"Transcript cr; cr; nextPutAll: op; cr; nextPutAll: calc; cr.
							 self processor
								disassembleFrom: 0 to: instructions size in: memory on: Transcript;
								printIntegerRegistersOn: Transcript."
							map
								at: #rax put: (self processor rax: 16rA5A5A5A5);
								at: #rbx put: (self processor rbx: 16rB5B5B5B5);
								at: #rcx put: (self processor rcx: 16rC5C5C5C5);
								at: #rdx put: (self processor rdx: 16rD5D5D5D5);
								at: #rsi put: (self processor rsi: 16r51515151);
								at: #rdi put: (self processor rdi: 16rD1D1D1D1);
								at: srget put: (self processor perform: srset with: (self processor convertIntegerToInternal: dv));
								at: drget put: (self processor perform: drset with: (self processor convertIntegerToInternal: dd)).
							self processor rsp: memory size; rip: 0.
							self shouldnt:
								[[self processor pc < instructions size] whileTrue:
									[self processor singleStepIn: memory readExecuteOnlyBelow: memory size / 2]]
								raise: Error.
							map
								at: qrget put: (self processor convertIntegerToInternal: (dd quo: dv));
								at: rrget put: (self processor convertIntegerToInternal: (dd rem: dv)).
							map keysAndValuesDo:
								[:accessor :value|
								self assert: value = (self processor perform: accessor)]]]]]].
	^ops
]

{ #category : #tests }
CogX64CompilerTests >> testMoveAwR [
	"self new testMoveAwR"
	self concreteCompilerClass registersWithNamesDo:
		[:reg :regname|
		#(16r555555 16rAAAAAA 16r5A5A5A5A5A5A) do:
			[:addr| | inst len totalsz |
			inst := self gen: MoveAwR operand: addr operand: reg.
			len := inst concretizeAt: 0.
			totalsz := 0.
			regname ~= '%rax' ifTrue:
				[self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended |
						plainJane := self strip: str.
						herIntended := 'xchgq %rax, ', regname.
						self assert: (plainJane match: herIntended).
						totalsz := sz]].
			self processor
				disassembleInstructionAt: totalsz
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'movq 0x', (addr printStringBase: 16 length: 16 padded: true), ', %rax'.
					self assert: (plainJane match: herIntended).
					totalsz := totalsz + sz].
			regname ~= '%rax' ifTrue:
				[self processor
					disassembleInstructionAt: totalsz
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended |
						plainJane := self strip: str.
						herIntended := 'xchgq %rax, ', regname.
						self assert: (plainJane match: herIntended).
						totalsz := totalsz + sz]].
			self assert: len = totalsz]]
]

{ #category : #tests }
CogX64CompilerTests >> testMoveC32R [
	"self new testMoveMwrR"
	self concreteCompilerClass registersWithNamesDo:
		[:reg :rname|
		#(0 64 65536 -64 -65536) do:
			[:offset| | inst len |
			inst := self gen: MoveC32R operand: offset operand: reg.
			len := inst concretizeAt: 0.
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended po |
					plainJane := self strip: str.
					po := offset bitAnd: 1 << self processor bitsInWord - 1.
					herIntended := 'movq $0x', (po printStringBase: 16 length: 16 padded: true), ', ', rname.
					self assert: (plainJane match: herIntended).
					self assert: len = sz]]]
]

{ #category : #tests }
CogX64CompilerTests >> testMoveM64rRd [
	"self new testMoveM64rRd"
	self concreteCompilerClass registersWithNamesDo:
		[:sreg :srname|
		self concreteCompilerClass xmmRegistersWithNamesDo:
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
						self assert: (plainJane match: herIntended).
						self assert: len = sz]]]]
]

{ #category : #tests }
CogX64CompilerTests >> testMoveMbrR [
	"self new testMoveMbrR"
	self concreteCompilerClass registersWithNamesDo:
		[:sreg :srname|
		self concreteCompilerClass registersWithNamesDo:
			[:dreg :drname|
			((1 to: 19 by: 3) collect: [:po2| 2 raisedToInteger: po2]) do:
				[:offset| | inst len |
				inst := self gen: MoveMbrR operand: offset operand: sreg operand: dreg.
				len := inst concretizeAt: 0.
				self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended po |
						po := offset bitAnd: 1 << self processor bitsInWord - 1.
						plainJane := self strip: str.
						herIntended := 'movzbq ', (offset = 0 ifTrue: [''] ifFalse: ['0x', (po printStringBase: 16 length: 16 padded: true)]), '(', srname, '), ', drname.
						self assert: (plainJane match: herIntended).
						self assert: len = sz]]]]
]

{ #category : #tests }
CogX64CompilerTests >> testMoveMwrR [
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
						herIntended := 'movq ', (offset = 0 ifTrue: [''] ifFalse: ['0x', (po printStringBase: 16 length: 16 padded: true)]), '(', srname, '), ', drname.
						self assert: (plainJane match: herIntended).
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
						herIntended := 'movq ', (offset = 0 ifTrue: [''] ifFalse: ['0x', (po printStringBase: 16 length: 16 padded: true)]), '(', srname, '), ', drname.
						((plainJane match: herIntended) and: [len = sz]) ifFalse:
							[failures at: herIntended put: plainJane]]]]].
	 failures"
]

{ #category : #tests }
CogX64CompilerTests >> testMoveRAw [
	"self new testMoveRAw"
	self concreteCompilerClass registersWithNamesDo:
		[:reg :regname|
		#(16r555555 16rAAAAAA 16r5A5A5A5A5A5A) do:
			[:addr| | inst len totalsz |
			inst := self gen: MoveRAw operand: reg operand: addr.
			len := inst concretizeAt: 0.
			totalsz := 0.
			regname ~= '%rax' ifTrue:
				[self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended |
						plainJane := self strip: str.
						herIntended := 'xchgq %rax, ', regname.
						self assert: (plainJane match: herIntended).
						totalsz := sz]].
			self processor
				disassembleInstructionAt: totalsz
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'movq %rax, 0x', (addr printStringBase: 16 length: 16 padded: true).
					self assert: (plainJane match: herIntended).
					totalsz := totalsz + sz].
			regname ~= '%rax' ifTrue:
				[self processor
					disassembleInstructionAt: totalsz
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended |
						plainJane := self strip: str.
						herIntended := 'xchgq %rax, ', regname.
						self assert: (plainJane match: herIntended).
						totalsz := totalsz + sz]].
			self assert: len = totalsz]]
]

{ #category : #tests }
CogX64CompilerTests >> testMoveRMbr [
	"self new testMoveRMbr"
	self concreteCompilerClass byteRegistersWithNamesDo:
		[:sreg :srname|
		self concreteCompilerClass registersWithNamesDo:
			[:dreg :drname|
			((1 to: 19 by: 3) collect: [:po2| 2 raisedToInteger: po2]) do:
				[:offset| | inst len |
				inst := self gen: MoveRMbr operand: sreg operand: offset operand: dreg.
				len := inst concretizeAt: 0.
				self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended po |
						plainJane := self strip: str.
						po := offset bitAnd: 1 << self processor bitsInWord - 1.
						herIntended := 'movb ', srname, (offset = 0 ifTrue: [', '] ifFalse: [', 0x', (po printStringBase: 16 length: 16 padded: true)]), '(', drname, ')'.
						self assert: (plainJane match: herIntended).
						self assert: len = sz]]]]
]

{ #category : #tests }
CogX64CompilerTests >> testMoveRMwr [
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
						"Convert e.g. '00000000: movq %rax, 0x2(%rax) : 48 89 40 02' to  'movl %rax, 0x2(%rax)'"
						plainJane := self strip: str.
						po := offset bitAnd: 1 << self processor bitsInWord - 1.
						herIntended := 'movq ', srname, ', ', (offset = 0 ifTrue: [''] ifFalse: ['0x', (po printStringBase: 16 length: 16 padded: true)]), '(',drname,')'.
						self assert: (plainJane match: herIntended).
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
						herIntended := 'movq ', srname, ', ', (offset = 0 ifTrue: [''] ifFalse: ['0x', (po printStringBase: 16 length: 16 padded: true)]), '(',drname,')'.
						((plainJane match: herIntended) and: [len = sz]) ifFalse:
							[failures at: herIntended put: plainJane]]]]].
	 failures"
]

{ #category : #tests }
CogX64CompilerTests >> testMoveRXwrR [
	"self new testMoveXwrRR"
	self concreteCompilerClass registersWithNamesDo:
		[:idxreg :irname|
			irname ~= '%rsp' ifTrue:
				[self concreteCompilerClass registersWithNamesDo:
					[:basereg :brname|
					self concreteCompilerClass registersWithNamesDo:
						[:sreg :srname|
						((1 to: 19 by: 3) collect: [:po2| 2 raisedToInteger: po2]) do:
							[:offset| | inst len |
							inst := self gen: MoveRXwrR operand: sreg operand: idxreg operand: basereg.
							len := inst concretizeAt: 0.
							self processor
								disassembleInstructionAt: 0
								In: inst machineCode object
								into: [:str :sz| | plainJane herIntended |
									"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
									plainJane := self strip: str.
									herIntended := 'movq ', srname, ', (', brname, ',', irname, ',8)'.
									self assert: (plainJane match: herIntended).
									self assert: len = sz]]]]]]
]

{ #category : #tests }
CogX64CompilerTests >> testMoveRdM64r [
	"self new testMoveRdM64r"
	self concreteCompilerClass xmmRegistersWithNamesDo:
		[:sreg :srname|
		self concreteCompilerClass registersWithNamesDo:
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
						self assert: (plainJane match: herIntended).
						self assert: len = sz]]]]
]

{ #category : #tests }
CogX64CompilerTests >> testMoveXbrRR [
	"self new testMoveXbrRR"
	self concreteCompilerClass registersWithNamesDo:
		[:idxreg :irname|
		irname ~= '%rsp' ifTrue:
			[self concreteCompilerClass registersWithNamesDo:
				[:basereg :brname|
				self concreteCompilerClass registersWithNamesDo:
					[:dreg :drname|
					((1 to: 19 by: 3) collect: [:po2| 2 raisedToInteger: po2]) do:
						[:offset| | inst len |
						inst := self gen: MoveXbrRR operand: idxreg operand: basereg operand: dreg.
						len := inst concretizeAt: 0.
						self processor
							disassembleInstructionAt: 0
							In: inst machineCode object
							into: [:str :sz| | plainJane herIntended |
								"Convert e.g. '00000000: movzbq %ds:(%rax,%rax,1), %rax : 48 0F B6 04 00 ' to  'movzbq (%rax,%rax,1), %rax'"
								plainJane := self strip: str.
								herIntended := 'movzbq (', brname, ',', irname, ',1), ',drname.
								self assert: (plainJane match: herIntended).
								self assert: len = sz]]]]]]
]

{ #category : #tests }
CogX64CompilerTests >> testMoveXwrRR [
	"self new testMoveXwrRR"
	self concreteCompilerClass registersWithNamesDo:
		[:idxreg :irname|
			irname ~= '%rsp' ifTrue:
				[self concreteCompilerClass registersWithNamesDo:
					[:basereg :brname|
					self concreteCompilerClass registersWithNamesDo:
						[:dreg :drname|
						((1 to: 19 by: 3) collect: [:po2| 2 raisedToInteger: po2]) do:
							[:offset| | inst len |
							inst := self gen: MoveXwrRR operand: idxreg operand: basereg operand: dreg.
							len := inst concretizeAt: 0.
							self processor
								disassembleInstructionAt: 0
								In: inst machineCode object
								into: [:str :sz| | plainJane herIntended |
									"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
									plainJane := self strip: str.
									herIntended := 'movq (', brname, ',', irname, ',8), ',drname.
									self assert: (plainJane match: herIntended).
									self assert: len = sz]]]]]]
]

{ #category : #tests }
CogX64CompilerTests >> testMul [
	"CogX64CompilerTests new setUp testMul"
	| map compiler memory |
	map := Dictionary new.
	compiler := self gen: nil.
	memory := ByteArray new: 1024.
	self concreteCompilerClass dataRegistersWithAccessorsExcept: #(rbp rsp) do:
		[:sreg :srget :srset|
		self concreteCompilerClass dataRegistersWithAccessorsExcept: { #rbp. #rsp. srget } do:
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
								at: srget put: (self processor perform: srset with: (self processor convertIntegerToInternal: b));
								at: drget put: (self processor perform: drset with: (self processor convertIntegerToInternal: a)).
					self processor esp: memory size; eip: 0.
					self shouldnt:
						[[self processor pc < instructions size] whileTrue:
							[self processor singleStepIn: memory]]
						raise: Error.
					map at: drget put: (self processor convertIntegerToInternal: (a * b)).
					map keysAndValuesDo:
						[:accessor :value|
						self assert: value = (self processor perform: accessor)]]]]
]

{ #category : #tests }
CogX64CompilerTests >> testTstCqR [
	"self new testTstCqR"
	self concreteCompilerClass registersWithNamesDo:
		[:reg :theRegname|
		#(16r1 16r3 16r7 16r555555 16rAAAAAA) do:
			[:const| | op regname inst len constString|
			inst := self gen: TstCqR operand: const operand: reg.
			len := inst concretizeAt: 0.
			(inst isQuick: const)
				ifTrue:
					[op := 'testb'.
					 regname := reg < 8
									ifTrue: [#('%al' '%cl' '%dl' '%bl' '%spl' '%bpl' '%sil' '%dil') at: reg + 1]
									ifFalse: [theRegname, 'b'].
					 constString := const printStringBase: 16 length: 2 padded: true]
				ifFalse:
					[op := 'testq'.
					 regname := theRegname.
					 constString := const printStringBase: 16 length: 16 padded: true].
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
					plainJane := self strip: str.
					herIntended := op, ' $0x', constString, ', ', regname.
					self assert: (plainJane match: herIntended).
					self assert: len = sz]]]
]

{ #category : #tests }
CogX64CompilerTests >> testXCHGAwR [
	"self new testXCHGAwR"
	| xchgAwR |
	xchgAwR := CogX64Compiler classPool at: #XCHGAwR.
	self concreteCompilerClass registersWithNamesDo:
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
					self assert: (plainJane match: herIntended).
					self assert: len = sz]]]
]

{ #category : #tests }
CogX64CompilerTests >> testXCHGMwrR [
	"self new testXCHGMwrR"
	| xchgMwrR |
	xchgMwrR := CogX64Compiler classPool at: #XCHGMwrR.
	self concreteCompilerClass registersWithNamesDo:
		[:sreg :srname|
		self concreteCompilerClass registersWithNamesDo:
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
						self assert: (plainJane match: herIntended).
						self assert: memory size = sz]]]]
]

{ #category : #accessing }
CogX64CompilerTests >> varBaseAddress [
	"Answer a value that should be sufficiently high that var base relative addressing is never generated."
	^1 << 60
]
