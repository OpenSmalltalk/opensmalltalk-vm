Class {
	#name : #CogX64CompilerTests,
	#superclass : #AbstractInstructionTests,
	#category : #'VMMaker-OriginalTests'
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
CogX64CompilerTests >> testAddCqR [
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
					herIntended := 'addq $0x', (const printStringBase: 16 length: 16 padded: true), ', ', regname.
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]
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
					"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
					plainJane := self strip: str.
					herIntended := 'andq $0x', (const printStringBase: 16 length: 16 padded: true), ', ', regname.
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]
]

{ #category : #tests }
CogX64CompilerTests >> testAndRR [
	"CogX64CompilerTests new testAndRR"
	self concreteCompilerClass registersWithNamesDo:
		[:sreg :sregname|
		self concreteCompilerClass registersWithNamesDo:
			[:dreg :dregname| | inst len |
			inst := self gen: AndRR operand: sreg operand: dreg.
			len := inst concretizeAt: 0.
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
					plainJane := self strip: str.
					herIntended := 'andq ', sregname, ', ', dregname.
					self assert: herIntended equals: plainJane.
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
					self assert: herIntended equals: plainJane.
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
							self assert: herIntended equals: plainJane.
							self assert: memory size = sz]]]]]
]

{ #category : #tests }
CogX64CompilerTests >> testCallR [
	"self new testCallR"
	self concreteCompilerClass registersWithNamesDo:
		[:reg :regname| | inst len|
			inst := self gen: CallR operand: reg.
			len := inst concretizeAt: 0.
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
					plainJane := self strip: str.
					herIntended := 'call ', regname.
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]
]

{ #category : #tests }
CogX64CompilerTests >> testCmpC32R [
	"self new testCmpC32R"
	self concreteCompilerClass doubleWordRegistersWithNamesDo:
		[:reg :regname|
		#(16r1 16r3 16r7 16r555555 16rAAAAAA) do:
			[:const| | inst len|
			inst := self gen: CmpC32R operand: const operand: reg.
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
CogX64CompilerTests >> testCmpCqR [
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
					herIntended := 'cmpq $0x', (const printStringBase: 16 length: 16 padded: true), ', ', regname.
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]
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
								self assert: value equals: (self processor perform: accessor)]]]]]].
	^ops
]

{ #category : #tests }
CogX64CompilerTests >> testJumpR [
	"self new testJumpR"
	self concreteCompilerClass registersWithNamesDo:
		[:reg :regname| | inst len|
			inst := self gen: JumpR operand: reg.
			len := inst concretizeAt: 0.
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
					plainJane := self strip: str.
					herIntended := 'jmp ', regname.
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]
]

{ #category : #tests }
CogX64CompilerTests >> testMoveAbR [
	"self neb testMoveAbR"
	self concreteCompilerClass byteRegistersWithNamesDo:
		[:reg :regname| | reg64name |
		reg64name := self processor registerStateGetters at: reg + 1.
		#(16r555555 16rAAAAAA 16r5A5A5A5A5A5A) do:
			[:addr| | inst len totalsz |
			inst := self gen: MoveAbR operand: addr operand: reg.
			len := inst concretizeAt: 0.
			totalsz := 0.
			regname ~= '%al' ifTrue:
				[self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended |
						plainJane := self strip: str.
						herIntended := 'xchgq %rax, %', reg64name.
						self assert: herIntended equals: plainJane.
						totalsz := sz]].
			self processor
				disassembleInstructionAt: totalsz
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'movb 0x', (addr printStringBase: 16 length: 16 padded: true), ', %al'.
					self assert: herIntended equals: plainJane.
					totalsz := totalsz + sz].
			regname ~= '%al' ifTrue:
				[self processor
					disassembleInstructionAt: totalsz
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended |
						plainJane := self strip: str.
						herIntended := 'xchgq %rax, %', reg64name.
						self assert: herIntended equals: plainJane.
						totalsz := totalsz + sz]].
			self assert: len = totalsz]]
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
						self assert: herIntended equals: plainJane.
						totalsz := sz]].
			self processor
				disassembleInstructionAt: totalsz
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'movq 0x', (addr printStringBase: 16 length: 16 padded: true), ', %rax'.
					self assert: herIntended equals: plainJane.
					totalsz := totalsz + sz].
			regname ~= '%rax' ifTrue:
				[self processor
					disassembleInstructionAt: totalsz
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended |
						plainJane := self strip: str.
						herIntended := 'xchgq %rax, ', regname.
						self assert: herIntended equals: plainJane.
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
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]
]

{ #category : #tests }
CogX64CompilerTests >> testMoveM16rR [
	"self new testMoveM16rR"
	self concreteCompilerClass registersWithNamesDo:
		[:sreg :srname|
		self concreteCompilerClass registersWithNamesDo:
			[:dreg :drname|
			((1 to: 19 by: 3) collect: [:po2| 2 raisedToInteger: po2]) do:
				[:offset| | inst len |
				inst := self gen: MoveM16rR operand: offset operand: sreg operand: dreg.
				self deny: inst byteReadsZeroExtend.
				len := inst concretizeAt: 0.
				self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended po |
						po := offset bitAnd: 1 << self processor bitsInWord - 1.
						plainJane := self strip: str.
						herIntended := 'movzwq ', (offset = 0 ifTrue: [''] ifFalse: ['0x', (po printStringBase: 16 length: 16 padded: true)]), '(', srname, '), ', drname.
						self assert: herIntended equals: plainJane.
						self assert: len = sz]]]]
]

{ #category : #tests }
CogX64CompilerTests >> testMoveM64rRd [
	"self new testMoveM64rRd"
	self concreteCompilerClass registersWithNamesDo:
		[:sreg :srname|
		self concreteCompilerClass xmmRegistersWithNamesDo:
			[:dreg :drname|
			#(0 8 32760) do:
				[:offset| | inst len |
				inst := self gen: MoveM64rRd operand: offset operand: sreg operand: dreg.
				len := inst concretizeAt: 0.
				self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended |
						plainJane := self strip: str.
						herIntended := 'movq ',
										(offset = 0
											ifTrue: ['']
											ifFalse: ['0x', ((offset printStringBase: 16 length: 16 padded: true) asLowercase)]),
										'(', srname, '), ', drname.
						"N.B. bochs 2.3.7 gets many cases wrong, e.g.
							movq %ds:(%rax), %xmm8 : F3 44 0F 7E 00
						 is disassembled as
							rep movq %ds:(%rax), %xmm8 : F3 44 0F 7E 00"
						(plainJane beginsWith: 'rep ') ifTrue:
							[plainJane := plainJane allButFirst: 4].
						self assert: herIntended equals: plainJane.
						self assert: len = sz]]]]

"| them it |
them := OrderedCollection new.
[(it := CogX64CompilerTests new) testMoveM64rRd]
	on: AssertionFailure, TestResult failure
	do: [:ex| | inst |
		ex class == AssertionFailure
			ifTrue:
				[inst := ex signalerContext receiver.
				it processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| them addLast: (it strip: str)]]
			ifFalse:
				[ResumableTestFailure adoptInstance: ex].
		ex resume].
them size"
"| them it |
them := OrderedCollection new.
[(it := CogX64CompilerTests new) testMoveM64rRd]
	on: TestResult failure
	do: [:ex| | ctxt |
		ctxt := ex signalerContext findContextSuchThat: [:c| c selector == #assert:equals:]..
		them addLast: {ctxt tempAt: 1. ctxt tempAt: 2}.
		ResumableTestFailure adoptInstance: ex.
		ex resume].
them size"
]

{ #category : #tests }
CogX64CompilerTests >> testMoveMbrR [
	"self new testMoveMbrR"
	self concreteCompilerClass registersWithNamesDo:
		[:sreg :srname|
		self concreteCompilerClass byteRegistersWithNamesDo:
			[:dreg :drname|
			((1 to: 19 by: 3) collect: [:po2| 2 raisedToInteger: po2]) do:
				[:offset| | inst len |
				inst := self gen: MoveMbrR operand: offset operand: sreg operand: dreg.
				self deny: inst byteReadsZeroExtend.
				len := inst concretizeAt: 0.
				self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended po |
						po := offset bitAnd: 1 << self processor bitsInWord - 1.
						plainJane := self strip: str.
						herIntended := 'movb ', (offset = 0 ifTrue: [''] ifFalse: ['0x', (po printStringBase: 16 length: 16 padded: true)]), '(', srname, '), ', drname.
						self assert: herIntended equals: plainJane.
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
						herIntended := 'movq ', (offset = 0 ifTrue: [''] ifFalse: ['0x', (po printStringBase: 16 length: 16 padded: true)]), '(', srname, '), ', drname.
						((plainJane match: herIntended) and: [len = sz]) ifFalse:
							[failures at: herIntended put: plainJane]]]]].
	 failures"
]

{ #category : #tests }
CogX64CompilerTests >> testMoveRAb [
	"self new testMoveRAb"
	self concreteCompilerClass byteRegistersWithNamesDo:
		[:reg :regname| | reg64name |
		reg64name := self processor registerStateGetters at: reg + 1.
		#(16r555555 16rAAAAAA 16r5A5A5A5A5A5A) do:
			[:addr| | inst len totalsz |
			inst := self gen: MoveRAb operand: reg operand: addr.
			len := inst concretizeAt: 0.
			totalsz := 0.
			regname ~= '%al' ifTrue:
				[self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended |
						plainJane := self strip: str.
						herIntended := 'xchgq %rax, %', reg64name.
						self assert: herIntended equals: plainJane.
						totalsz := sz]].
			self processor
				disassembleInstructionAt: totalsz
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'movb %al, 0x', (addr printStringBase: 16 length: 16 padded: true).
					self assert: herIntended equals: plainJane.
					totalsz := totalsz + sz].
			regname ~= '%al' ifTrue:
				[self processor
					disassembleInstructionAt: totalsz
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended |
						plainJane := self strip: str.
						herIntended := 'xchgq %rax, %', reg64name.
						self assert: herIntended equals: plainJane.
						totalsz := totalsz + sz]].
			self assert: len = totalsz]]
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
						self assert: herIntended equals: plainJane.
						totalsz := sz]].
			self processor
				disassembleInstructionAt: totalsz
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'movq %rax, 0x', (addr printStringBase: 16 length: 16 padded: true).
					self assert: herIntended equals: plainJane.
					totalsz := totalsz + sz].
			regname ~= '%rax' ifTrue:
				[self processor
					disassembleInstructionAt: totalsz
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended |
						plainJane := self strip: str.
						herIntended := 'xchgq %rax, ', regname.
						self assert: herIntended equals: plainJane.
						totalsz := totalsz + sz]].
			self assert: len = totalsz]]
]

{ #category : #tests }
CogX64CompilerTests >> testMoveRIPRelativeCwR [
	"test rip-relative constant generation"
	"self new testMoveRIPRelativeCwR"
	
	| memory |
	memory := ByteArray new: 16.
	{self currentCompilationBase. self currentCompilationBase + 512} do:
		[:n| | inst len |
		self concreteCompilerClass dataRegistersWithAccessorsDo: 
			[ :r :rgetter :rset |
			inst := self gen: MoveCwR operand: n operand: r.
			len := inst concretizeAt: 0.
			memory replaceFrom: 1 to: len with: inst machineCode object startingAt: 1.
			self processor
				reset.
			[[processor pc < len] whileTrue:
				[self processor singleStepIn: memory]]
				on: Error
				do: [:ex| ].
			self concreteCompilerClass dataRegistersWithAccessorsDo:
				[:ireg :getter :setter| | expected |
				expected := getter == rgetter ifTrue: [n] ifFalse: [0].
				self assert: (self processor perform: getter) = expected].
			self assert: self processor pc = inst machineCodeSize]]

	"processor disassembleFrom: 0 to: inst machineCodeSize in: memory on: Transcript"
]

{ #category : #tests }
CogX64CompilerTests >> testMoveRM16r [
	"self new testMoveRM16r"
	self concreteCompilerClass wordRegistersWithNamesDo:
		[:sreg :srname|
		self concreteCompilerClass registersWithNamesDo:
			[:dreg :drname|
			((1 to: 19 by: 3) collect: [:po2| 2 raisedToInteger: po2]) do:
				[:offset| | inst len |
				inst := self gen: MoveRM16r operand: sreg operand: offset operand: dreg.
				len := inst concretizeAt: 0.
				self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended po |
						plainJane := self strip: str.
						po := offset bitAnd: 1 << self processor bitsInWord - 1.
						herIntended := 'movw ', srname, (offset = 0 ifTrue: [', '] ifFalse: [', 0x', (po printStringBase: 16 length: 16 padded: true)]), '(', drname, ')'.
						self assert: herIntended equals: plainJane.
						self assert: len = sz]]]]
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
						self assert: herIntended equals: plainJane.
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
						herIntended := 'movq ', srname, ', ', (offset = 0 ifTrue: [''] ifFalse: ['0x', (po printStringBase: 16 length: 16 padded: true)]), '(',drname,')'.
						((plainJane match: herIntended) and: [len = sz]) ifFalse:
							[failures at: herIntended put: plainJane]]]]].
	 failures"
]

{ #category : #tests }
CogX64CompilerTests >> testMoveRRd [
	"self new testMoveRRd"
	self concreteCompilerClass registersWithNamesDo:
		[:sreg :srname|
		self concreteCompilerClass xmmRegistersWithNamesDo:
			[:dreg :drname| | inst len |
			inst := self gen: MoveRRd operand: sreg operand: dreg.
			len := inst concretizeAt: 0.
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'movq ', srname, ', ', drname.
					"N.B. bochs 2.3.7 gets many cases wrong, e.g.
						movq %ds:(%rax), %xmm8 : F3 44 0F 7E 00
					 is disassembled as
						rep movq %ds:(%rax), %xmm8 : F3 44 0F 7E 00"
					(plainJane beginsWith: 'rep ') ifTrue:
						[plainJane := plainJane allButFirst: 4].
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]

"| them it |
them := OrderedCollection new.
[(it := CogX64CompilerTests new) testMoveRRd]
	on: AssertionFailure, TestResult failure
	do: [:ex| | inst |
		ex class == AssertionFailure
			ifTrue:
				[inst := ex signalerContext receiver.
				it processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| them addLast: (it strip: str)]]
			ifFalse:
				[ResumableTestFailure adoptInstance: ex].
		ex resume].
them size"
"| them it |
them := OrderedCollection new.
[(it := CogX64CompilerTests new) testMoveRRd]
	on: TestResult failure
	do: [:ex| | ctxt |
		ctxt := ex signalerContext findContextSuchThat: [:c| c selector == #assert:equals:]..
		them addLast: {ctxt tempAt: 1. ctxt tempAt: 2}.
		ResumableTestFailure adoptInstance: ex.
		ex resume].
them size"
]

{ #category : #tests }
CogX64CompilerTests >> testMoveRX32rR [
	"self new testMoveRX32rR"
	self concreteCompilerClass registersWithNamesDo:
		[:idxreg :irname|
			irname ~= '%rsp' ifTrue:
				[self concreteCompilerClass registersWithNamesDo:
					[:basereg :brname|
					self concreteCompilerClass doubleWordRegistersWithNamesDo:
						[:sreg :srname| | inst len |
						inst := self gen: MoveRX32rR operand: sreg operand: idxreg operand: basereg.
						len := inst concretizeAt: 0.
						self processor
							disassembleInstructionAt: 0
							In: inst machineCode object
							into: [:str :sz| | plainJane herIntended |
								"Convert e.g. '00000000: movl %rax, 0x2(%rax) : 89 40 02' to  'movl %rax, 0x2(%rax)'"
								plainJane := self strip: str.
								herIntended := 'movl ', srname, ', (', brname, ',', irname, ',4)'.
								self assert: herIntended equals: plainJane.
								self assert: len = sz]]]]]
]

{ #category : #tests }
CogX64CompilerTests >> testMoveRXbrR [
	"self new testMoveXbrRR"
	self concreteCompilerClass registersWithNamesDo:
		[:idxreg :irname|
		irname ~= '%rsp' ifTrue:
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
CogX64CompilerTests >> testMoveRXwrR [
	"self new testMoveXwrRR"
	self concreteCompilerClass registersWithNamesDo:
		[:idxreg :irname|
			irname ~= '%rsp' ifTrue:
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
								"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
								plainJane := self strip: str.
								herIntended := 'movq ', srname, ', (', brname, ',', irname, ',8)'.
								self assert: herIntended equals: plainJane.
								self assert: len = sz]]]]]
]

{ #category : #tests }
CogX64CompilerTests >> testMoveRdM64r [
	"self new testMoveRdM64r"
	self concreteCompilerClass xmmRegistersWithNamesDo:
		[:sreg :srname|
		self concreteCompilerClass registersWithNamesDo:
			[:dreg :drname|
			#(0 8 256 32760) do:
				[:offset| | inst len |
				inst := self gen: MoveRdM64r operand: sreg operand: offset operand: dreg.
				len := inst concretizeAt: 0.
				self processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| | plainJane herIntended |
						plainJane := self strip: str.
						herIntended := 'movq ', srname,
											(offset = 0
												ifTrue: [', ']
												ifFalse: [', 0x', ((offset printStringBase: 16 length: 16 padded: true))]),
											'(', drname, ')'.
						self assert: herIntended equals: plainJane.
						self assert: len = sz]]]]

"| them it |
them := OrderedCollection new.
[(it := CogX64CompilerTests new) testMoveRdM64r]
	on: AssertionFailure, TestResult failure
	do: [:ex| | inst |
		ex class == AssertionFailure
			ifTrue:
				[inst := ex signalerContext receiver.
				it processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| them addLast: (it strip: str)]]
			ifFalse:
				[ResumableTestFailure adoptInstance: ex].
		ex resume].
them size"
"| them it |
them := OrderedCollection new.
[(it := CogX64CompilerTests new) testMoveRdM64r]
	on: TestResult failure
	do: [:ex| | ctxt |
		ctxt := ex signalerContext findContextSuchThat: [:c| c selector == #assert:equals:]..
		them addLast: {ctxt tempAt: 1. ctxt tempAt: 2}.
		ResumableTestFailure adoptInstance: ex.
		ex resume].
them size"
]

{ #category : #tests }
CogX64CompilerTests >> testMoveRdR [
	"self new testMoveRdR"
	self concreteCompilerClass registersWithNamesDo:
		[:dreg :drname|
		self concreteCompilerClass xmmRegistersWithNamesDo:
			[:sreg :srname| | inst len |
			inst := self gen: MoveRdR operand: sreg operand: dreg.
			len := inst concretizeAt: 0.
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					plainJane := self strip: str.
					herIntended := 'movq ', srname, ', ', drname.
					"N.B. bochs 2.3.7 gets many cases wrong, e.g.
						movq %ds:(%rax), %xmm8 : F3 44 0F 7E 00
					 is disassembled as
						rep movq %ds:(%rax), %xmm8 : F3 44 0F 7E 00"
					(plainJane beginsWith: 'rep ') ifTrue:
						[plainJane := plainJane allButFirst: 4].
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]

"| them it |
them := OrderedCollection new.
[(it := CogX64CompilerTests new) testMoveRdR]
	on: AssertionFailure, TestResult failure
	do: [:ex| | inst |
		ex class == AssertionFailure
			ifTrue:
				[inst := ex signalerContext receiver.
				it processor
					disassembleInstructionAt: 0
					In: inst machineCode object
					into: [:str :sz| them addLast: (it strip: str)]]
			ifFalse:
				[ResumableTestFailure adoptInstance: ex].
		ex resume].
them size"
"| them it |
them := OrderedCollection new.
[(it := CogX64CompilerTests new) testMoveRdR]
	on: TestResult failure
	do: [:ex| | ctxt |
		ctxt := ex signalerContext findContextSuchThat: [:c| c selector == #assert:equals:]..
		them addLast: {ctxt tempAt: 1. ctxt tempAt: 2}.
		ResumableTestFailure adoptInstance: ex.
		ex resume].
them size"
]

{ #category : #tests }
CogX64CompilerTests >> testMoveX32rRR [
	"self new testMoveX32rRR"
	self concreteCompilerClass registersWithNamesDo:
		[:idxreg :irname|
			irname ~= '%rsp' ifTrue:
				[self concreteCompilerClass registersWithNamesDo:
					[:basereg :brname|
					self concreteCompilerClass doubleWordRegistersWithNamesDo:
						[:dreg :drname| | inst len |
						inst := self gen: MoveX32rRR operand: idxreg operand: basereg operand: dreg.
						len := inst concretizeAt: 0.
						self processor
							disassembleInstructionAt: 3
							In: inst machineCode object
							into: [:str :sz| | plainJane herIntended |
								"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
								plainJane := self strip: str.
								herIntended := 'movl (', brname, ',', irname, ',4), ',drname.
								self assert: herIntended equals: plainJane.
								self assert: len - 3 = sz]]]]]
]

{ #category : #tests }
CogX64CompilerTests >> testMoveXbrRR [
	"self new testMoveXbrRR"
	self concreteCompilerClass registersWithNamesDo:
		[:idxreg :irname|
		irname ~= '%rsp' ifTrue:
			[self concreteCompilerClass registersWithNamesDo:
				[:basereg :brname|
				self concreteCompilerClass byteRegistersWithNamesDo:
					[:dreg :drname| | inst len |
					inst := self gen: MoveXbrRR operand: idxreg operand: basereg operand: dreg.
					self deny: inst byteReadsZeroExtend.
					len := inst concretizeAt: 0.
					self processor
						disassembleInstructionAt: 0
						In: inst machineCode object
						into: [:str :sz| | plainJane herIntended |
							"Convert e.g. '00000000: movzbq %ds:(%rax,%rax,1), %rax : 48 0F B6 04 00 ' to  'movzbq (%rax,%rax,1), %rax'"
							plainJane := self strip: str.
							herIntended := 'movb (', brname, ',', irname, ',1), ',drname.
							self assert: herIntended equals: plainJane.
							self assert: len = sz]]]]]
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
						[:dreg :drname| | inst len |
						inst := self gen: MoveXwrRR operand: idxreg operand: basereg operand: dreg.
						len := inst concretizeAt: 0.
						self processor
							disassembleInstructionAt: 0
							In: inst machineCode object
							into: [:str :sz| | plainJane herIntended |
								"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
								plainJane := self strip: str.
								herIntended := 'movq (', brname, ',', irname, ',8), ',drname.
								self assert: herIntended equals: plainJane.
								self assert: len = sz]]]]]
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
						at: #rax put: (self processor rax: 16rA5A5A5A5);
						at: #rbx put: (self processor rbx: 16rB5B5B5B5);
						at: #rcx put: (self processor rcx: 16rC5C5C5C5);
						at: #rdx put: (self processor rdx: 16rD5D5D5D5);
						at: #rsi put: (self processor rsi: 16r51515151);
						at: #rdi put: (self processor rdi: 16rD1D1D1D1);
								at: srget put: (self processor perform: srset with: (self processor convertIntegerToInternal: b));
								at: drget put: (self processor perform: drset with: (self processor convertIntegerToInternal: a)).
					self processor rsp: memory size; rip: 0.
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
CogX64CompilerTests >> testOrCqR [
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
					herIntended := 'orq $0x', (const printStringBase: 16 length: 16 padded: true), ', ', regname.
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]
]

{ #category : #tests }
CogX64CompilerTests >> testShiftCqR [
	"CogX64CompilerTests new testShiftCqR"
	{LogicalShiftRightCqR. LogicalShiftLeftCqR. ArithmeticShiftRightCqR}
		with: #('shrq' 'shlq' 'sarq')
		do: [:op :opname|
			self concreteCompilerClass registersWithNamesDo:
				[:reg :regname|
				1 to: 63 do:
					[:shift| | inst len |
					inst := self gen: op operand: shift operand: reg.
					len := inst concretizeAt: 0.
					self processor
						disassembleInstructionAt: 0
						In: inst machineCode object
						into: [:str :sz| | plainJane herIntended |
							"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
							plainJane := self strip: str.
							herIntended := opname ,' $', (shift > 1
														ifTrue: ['0x', (shift printStringBase: 16 length: 2 padded: true)]
														ifFalse: [shift asInteger]), ', ', regname.
							self assert: herIntended equals: plainJane.
							self assert: len = sz]]]]
]

{ #category : #tests }
CogX64CompilerTests >> testSubCqR [
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
					herIntended := 'subq $0x', (const printStringBase: 16 length: 16 padded: true), ', ', regname.
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]
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
					self assert: herIntended equals: plainJane.
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
					self assert: herIntended equals: plainJane.
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
						self assert: herIntended equals: plainJane.
						self assert: memory size = sz]]]]
]

{ #category : #tests }
CogX64CompilerTests >> testXCHGRR [
	"CogX64CompilerTests new testXCHGRR"
	| xchgrr |
	xchgrr := (self concreteCompilerClass bindingOf: #XCHGRR) value.
	self concreteCompilerClass registersWithNamesDo:
		[:sreg :sregname|
		self concreteCompilerClass registersWithNamesDo:
			[:dreg :dregname| | inst len |
			inst := self gen: xchgrr operand: sreg operand: dreg.
			len := inst concretizeAt: 0.
			self processor
				disassembleInstructionAt: 0
				In: inst machineCode object
				into: [:str :sz| | plainJane herIntended |
					"Convert e.g. '00000000: movl %eax, 0x2(%eax) : 89 40 02' to  'movl %eax, 0x2(%eax)'"
					plainJane := self strip: str.
					herIntended := dreg = 0
										ifTrue: [sreg = 0 ifTrue: ['nop '] ifFalse: ['xchgq ', dregname, ', ', sregname]]
										ifFalse: ['xchgq ', sregname, ', ', dregname].
					self assert: herIntended equals: plainJane.
					self assert: len = sz]]]
]
