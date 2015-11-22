Class {
	#name : #MIPSDisassembler,
	#superclass : #Object,
	#instVars : [
		'pc'
	],
	#pools : [
		'MIPSConstants'
	],
	#category : #'Cog-Processors'
}

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> addImmediateUnsigned: instruction [
	^'addiu ', 
	(MIPSConstants nameForRegister: instruction rt), ', ',
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(instruction signedImmediate printString)
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> addUnsigned: instruction [
	^'addu ', 
	(MIPSConstants nameForRegister: instruction rd), ', ',
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(MIPSConstants nameForRegister: instruction rt)
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> andImmediate: instruction [
	^'andi ', 
	(MIPSConstants nameForRegister: instruction rt), ', ',
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(instruction unsignedImmediate printString)
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> bitwiseAnd: instruction [
	^'and ', 
	(MIPSConstants nameForRegister: instruction rd), ', ',
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(MIPSConstants nameForRegister: instruction rt)
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> bitwiseOr: instruction [
	^'or ', 
	(MIPSConstants nameForRegister: instruction rd), ', ',
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(MIPSConstants nameForRegister: instruction rt)
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> bitwiseXor: instruction [
	^'xor ', 
	(MIPSConstants nameForRegister: instruction rd), ', ',
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(MIPSConstants nameForRegister: instruction rt)
]

{ #category : #'instructions - control' }
MIPSDisassembler >> branchEqual: instruction [
	| offset target |
	offset := instruction signedImmediate << 2.
	target := pc + offset + OneInstruction. "Offset is relative to the delay slot"
	^'beq ', 
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(MIPSConstants nameForRegister: instruction rt), ', ',
	(offset > 0 ifTrue: ['+'] ifFalse: ['']), offset printString, ' ; =', (target printStringBase: 16)
]

{ #category : #'instructions - control' }
MIPSDisassembler >> branchGreaterEqualZero: instruction [
	| offset target |
	offset := instruction signedImmediate << 2.
	target := pc + offset + OneInstruction. "Offset is relative to the delay slot"
	^'bgez ', 
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(offset > 0 ifTrue: ['+'] ifFalse: ['']), offset printString, ' ; =', (target printStringBase: 16)
]

{ #category : #'instructions - control' }
MIPSDisassembler >> branchGreaterThanZero: instruction [
	| offset target |
	offset := instruction signedImmediate << 2.
	target := pc + offset + OneInstruction. "Offset is relative to the delay slot"
	^'bgtz ', 
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(offset > 0 ifTrue: ['+'] ifFalse: ['']), offset printString, ' ; =', (target printStringBase: 16)
]

{ #category : #'instructions - control' }
MIPSDisassembler >> branchLessEqualZero: instruction [
	| offset target |
	offset := instruction signedImmediate << 2.
	target := pc + offset + OneInstruction. "Offset is relative to the delay slot"
	^'blez ', 
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(offset > 0 ifTrue: ['+'] ifFalse: ['']), offset printString, ' ; =', (target printStringBase: 16)
]

{ #category : #'instructions - control' }
MIPSDisassembler >> branchLessThanZero: instruction [
	| offset target |
	offset := instruction signedImmediate << 2.
	target := pc + offset + OneInstruction. "Offset is relative to the delay slot"
	^'bltz ', 
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(offset > 0 ifTrue: ['+'] ifFalse: ['']), offset printString, ' ; =', (target printStringBase: 16)
]

{ #category : #'instructions - control' }
MIPSDisassembler >> branchNotEqual: instruction [
	| offset target |
	offset := instruction signedImmediate << 2.
	target := pc + offset + OneInstruction. "Offset is relative to the delay slot"
	^'bne ', 
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(MIPSConstants nameForRegister: instruction rt), ', ',
	(offset > 0 ifTrue: ['+'] ifFalse: ['']), offset printString, ' ; =', (target printStringBase: 16)
]

{ #category : #'instructions - control' }
MIPSDisassembler >> break: instruction [
	^'break'
]

{ #category : #'as yet unclassified' }
MIPSDisassembler >> disassemble: memory from: startPC to: limitPC [
	| stream |
	stream := WriteStream on: ''.
	self disassemble: memory from: startPC to: limitPC for: nil labels: nil on: stream.
	^stream contents
]

{ #category : #'as yet unclassified' }
MIPSDisassembler >> disassemble: memory from: startPC to: limitPC for: aSymbolManager "<Cogit>" labels: labelDictionary on: aStream [
	pc := startPC.
	[pc < limitPC] whileTrue:
		[ | word instruction |
		pc printOn: aStream base: 16 nDigits: 8.
		aStream space; space.
		word := memory unsignedLongAt: pc + 1.
		word printOn: aStream base: 16 nDigits: 8.
		aStream space; space.
		instruction := MIPSInstruction new value: word.
		aStream nextPutAll: (instruction decodeFor: self).

		aSymbolManager ifNotNil: [
			(aSymbolManager labelForPC: pc) ifNotNil:
				[:label | aStream nextPutAll: ' ;'; nextPutAll: label]].
		"aStream print: (aSymbolManager lookupAddress: pc)."

		aStream cr.
		pc := pc + OneInstruction].
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> divideSigned: instruction [
	self assert: instruction rd = 0.
	self assert: instruction sa = 0.
	^'div ', 
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(MIPSConstants nameForRegister: instruction rt)
]

{ #category : #'instructions - control' }
MIPSDisassembler >> jump: instruction [
	| target |
	target := (pc + OneInstruction) bitAnd: 16rF0000000. "Region is that of the delay slot"
	target := target + (instruction target << 2).
	^'j ', (target printStringBase: 16)
]

{ #category : #'instructions - control' }
MIPSDisassembler >> jumpAndLink: instruction [
	| target |
	target := (pc + OneInstruction) bitAnd: 16rF0000000. "Region is that of the delay slot"
	target := target + (instruction target << 2).
	^'jal ', (target printStringBase: 16)
]

{ #category : #'instructions - control' }
MIPSDisassembler >> jumpAndLinkRegister: instruction [
	instruction rd = 31 ifTrue: [^'jalr ', (MIPSConstants nameForRegister: instruction rs)].
	^'jalr ',
	(MIPSConstants nameForRegister: instruction rd), ', ',
	(MIPSConstants nameForRegister: instruction rs)
]

{ #category : #'instructions - control' }
MIPSDisassembler >> jumpRegister: instruction [
	^'jr ', (MIPSConstants nameForRegister: instruction rs)
]

{ #category : #'instructions - memory' }
MIPSDisassembler >> loadByte: instruction [
	^'lb ', 
	(MIPSConstants nameForRegister: instruction rt), ', ',
	(instruction signedImmediate printString), '(',
	(MIPSConstants nameForRegister: instruction rs), ')'
]

{ #category : #'instructions - memory' }
MIPSDisassembler >> loadByteUnsigned: instruction [
	^'lbu ', 
	(MIPSConstants nameForRegister: instruction rt), ', ',
	(instruction signedImmediate printString), '(',
	(MIPSConstants nameForRegister: instruction rs), ')'
]

{ #category : #'instructions - memory' }
MIPSDisassembler >> loadHalfword: instruction [
	^'lh ', 
	(MIPSConstants nameForRegister: instruction rt), ', ',
	(instruction signedImmediate printString), '(',
	(MIPSConstants nameForRegister: instruction rs), ')'
]

{ #category : #'instructions - memory' }
MIPSDisassembler >> loadHalfwordUnsigned: instruction [
	^'lhu ', 
	(MIPSConstants nameForRegister: instruction rt), ', ',
	(instruction signedImmediate printString), '(',
	(MIPSConstants nameForRegister: instruction rs), ')'
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> loadUpperImmediate: instruction [
	^'lui ', 
	(MIPSConstants nameForRegister: instruction rt), ', ',
	(instruction signedImmediate printString)
]

{ #category : #'instructions - memory' }
MIPSDisassembler >> loadWord: instruction [
	^'lw ', 
	(MIPSConstants nameForRegister: instruction rt), ', ',
	(instruction signedImmediate printString), '(',
	(MIPSConstants nameForRegister: instruction rs), ')'
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> moveFromHigh: instruction [
	self assert: instruction rs = 0.
	self assert: instruction rt = 0.
	self assert: instruction sa = 0.
	^'mfhi ', (MIPSConstants nameForRegister: instruction rd)
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> moveFromLow: instruction [
	self assert: instruction rs = 0.
	self assert: instruction rt = 0.
	self assert: instruction sa = 0.
	^'mflo ', (MIPSConstants nameForRegister: instruction rd)
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> multiplySigned: instruction [
	self assert: instruction rd = 0.
	self assert: instruction sa = 0.
	^'mult ', 
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(MIPSConstants nameForRegister: instruction rt)
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> orImmediate: instruction [
	^'ori ', 
	(MIPSConstants nameForRegister: instruction rt), ', ',
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(instruction unsignedImmediate printString)
]

{ #category : #'instructions - memory' }
MIPSDisassembler >> prefetch: instruction [
	| hintName |
	instruction rt = HintLoad ifTrue: [hintName :=  'load'].
	instruction rt = HintStore ifTrue: [hintName :=  'store'].
	^'pref ', hintName, ', ',
	(instruction signedImmediate printString), '(',
	(MIPSConstants nameForRegister: instruction rs), ')'
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> setOnLessThan: instruction [
	^'slt ', 
	(MIPSConstants nameForRegister: instruction rd), ', ',
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(MIPSConstants nameForRegister: instruction rt)
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> setOnLessThanImmediate: instruction [
	^'slti ', 
	(MIPSConstants nameForRegister: instruction rt), ', ',
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(instruction signedImmediate printString)
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> setOnLessThanImmediateUnsigned: instruction [
	"The immediate is still sign-extended; it is the comparison that is unsigned."
	^'sltiu ', 
	(MIPSConstants nameForRegister: instruction rt), ', ',
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(instruction signedImmediate printString) 
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> setOnLessThanUnsigned: instruction [
	^'sltu ', 
	(MIPSConstants nameForRegister: instruction rd), ', ',
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(MIPSConstants nameForRegister: instruction rt)
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> shiftLeftLogical: instruction [
	instruction value = 0 ifTrue: [^'nop'].
	^'sll ', 
	(MIPSConstants nameForRegister: instruction rd), ', ',
	(MIPSConstants nameForRegister: instruction rt), ', ',
	instruction sa printString
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> shiftLeftLogicalVariable: instruction [
	^'sllv ', 
	(MIPSConstants nameForRegister: instruction rd), ', ',
	(MIPSConstants nameForRegister: instruction rt), ', ',
	(MIPSConstants nameForRegister: instruction rs)
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> shiftRightArithmetic: instruction [
	^'sra ', 
	(MIPSConstants nameForRegister: instruction rd), ', ',
	(MIPSConstants nameForRegister: instruction rt), ', ',
	instruction sa printString
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> shiftRightArithmeticVariable: instruction [
	^'srav ', 
	(MIPSConstants nameForRegister: instruction rd), ', ',
	(MIPSConstants nameForRegister: instruction rt), ', ',
	(MIPSConstants nameForRegister: instruction rs)
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> shiftRightLogical: instruction [
	^'srl ', 
	(MIPSConstants nameForRegister: instruction rd), ', ',
	(MIPSConstants nameForRegister: instruction rt), ', ',
	instruction sa printString
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> shiftRightLogicalVariable: instruction [
	^'srlv ', 
	(MIPSConstants nameForRegister: instruction rd), ', ',
	(MIPSConstants nameForRegister: instruction rt), ', ',
	(MIPSConstants nameForRegister: instruction rs)
]

{ #category : #'instructions - memory' }
MIPSDisassembler >> storeByte: instruction [
	^'sb ', 
	(MIPSConstants nameForRegister: instruction rt), ', ',
	(instruction signedImmediate printString), '(',
	(MIPSConstants nameForRegister: instruction rs), ')'
]

{ #category : #'instructions - memory' }
MIPSDisassembler >> storeHalfword: instruction [
	^'sh ', 
	(MIPSConstants nameForRegister: instruction rt), ', ',
	(instruction signedImmediate printString), '(',
	(MIPSConstants nameForRegister: instruction rs), ')'
]

{ #category : #'instructions - memory' }
MIPSDisassembler >> storeWord: instruction [
	^'sw ', 
	(MIPSConstants nameForRegister: instruction rt), ', ',
	(instruction signedImmediate printString), '(',
	(MIPSConstants nameForRegister: instruction rs), ')'
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> subtractUnsigned: instruction [
	^'subu ', 
	(MIPSConstants nameForRegister: instruction rd), ', ',
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(MIPSConstants nameForRegister: instruction rt)
]

{ #category : #'instructions - arithmetic' }
MIPSDisassembler >> xorImmediate: instruction [
	^'xori ', 
	(MIPSConstants nameForRegister: instruction rt), ', ',
	(MIPSConstants nameForRegister: instruction rs), ', ',
	(instruction unsignedImmediate printString)
]
