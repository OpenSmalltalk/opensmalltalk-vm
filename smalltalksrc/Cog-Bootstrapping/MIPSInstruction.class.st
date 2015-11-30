"
Wrapper for decoding MIPS instructions.
"
Class {
	#name : #MIPSInstruction,
	#superclass : #Object,
	#instVars : [
		'value'
	],
	#pools : [
		'MIPSConstants'
	],
	#category : #'Cog-Processors'
}

{ #category : #'as yet unclassified' }
MIPSInstruction >> decodeFor: visitor [
	| opcode |
	opcode := self opcode.
	opcode = SPECIAL ifTrue: [^self decodeSpecialFor: visitor].
	opcode = REGIMM ifTrue: [^self decodeRegImmFor: visitor].

	opcode = J ifTrue: [^visitor jump: self].
	opcode = JAL ifTrue: [^visitor jumpAndLink: self].
	opcode = BEQ ifTrue: [^visitor branchEqual: self].
	opcode = BNE ifTrue: [^visitor branchNotEqual: self].
	opcode = BLEZ ifTrue: [^visitor branchLessEqualZero: self].
	opcode = BGTZ ifTrue: [^visitor branchGreaterThanZero: self].
	opcode = ADDIU ifTrue: [^visitor addImmediateUnsigned: self].
	opcode = SLTI ifTrue: [^visitor setOnLessThanImmediate: self].
	opcode = SLTIU ifTrue: [^visitor setOnLessThanImmediateUnsigned: self].
	opcode = ANDI ifTrue: [^visitor andImmediate: self].
	opcode = ORI ifTrue: [^visitor orImmediate: self].
	opcode = XORI ifTrue: [^visitor xorImmediate: self].
	opcode = LUI ifTrue: [^visitor loadUpperImmediate: self].
	opcode = LB ifTrue: [^visitor loadByte: self].
	opcode = LH ifTrue: [^visitor loadHalfword: self].
	opcode = LW ifTrue: [^visitor loadWord: self].
	opcode = LBU ifTrue: [^visitor loadByteUnsigned: self].
	opcode = LHU ifTrue: [^visitor loadHalfwordUnsigned: self].
	opcode = SB ifTrue: [^visitor storeByte: self].
	opcode = SH ifTrue: [^visitor storeHalfword: self].
	opcode = SW ifTrue: [^visitor storeWord: self].
	opcode = PREF ifTrue: [^visitor prefetch: self].

	self error: 'Unknown instruction'.
]

{ #category : #'as yet unclassified' }
MIPSInstruction >> decodeRegImmFor: visitor [
	| fn |
	fn := self rt.
	fn = BLTZ ifTrue: [^visitor branchLessThanZero: self].
	fn = BGEZ ifTrue: [^visitor branchGreaterEqualZero: self].
	
	self error: 'Unknown instruction'.
]

{ #category : #'as yet unclassified' }
MIPSInstruction >> decodeSpecialFor: visitor [
	| function |
	function := self function.
	function = SLL ifTrue: [^visitor shiftLeftLogical: self].
	function = SRL ifTrue: [^visitor shiftRightLogical: self].
	function = SRA ifTrue: [^visitor shiftRightArithmetic: self].
	function = SLLV ifTrue: [^visitor shiftLeftLogicalVariable: self].
	function = SRLV ifTrue: [^visitor shiftRightLogicalVariable: self].
	function = SRAV ifTrue: [^visitor shiftRightArithmeticVariable: self].
	function = JR ifTrue: [^visitor jumpRegister: self].
	function = JALR ifTrue: [^visitor jumpAndLinkRegister: self].
	function = BREAK ifTrue: [^visitor break: self].
	function = MFHI ifTrue: [^visitor moveFromHigh: self].
	function = MFLO ifTrue: [^visitor moveFromLow: self].
	function = MULT ifTrue: [^visitor multiplySigned: self].
	function = DIV ifTrue: [^visitor divideSigned: self].
	function = ADDU ifTrue: [^visitor addUnsigned: self].
	function = SUBU ifTrue: [^visitor subtractUnsigned: self].
	function = AND ifTrue: [^visitor bitwiseAnd: self].
	function = OR ifTrue: [^visitor bitwiseOr: self].
	function = XOR ifTrue: [^visitor bitwiseXor: self].
	function = SLT ifTrue: [^visitor setOnLessThan: self].
	function = SLTU ifTrue: [^visitor setOnLessThanUnsigned: self].
	
	self error: 'Unknown instruction'.
]

{ #category : #fields }
MIPSInstruction >> function [
	^value bitAnd: 63
]

{ #category : #fields }
MIPSInstruction >> opcode [
	^value >> 26
]

{ #category : #fields }
MIPSInstruction >> rd [
	^(value >> 11) bitAnd: 31
]

{ #category : #fields }
MIPSInstruction >> rs [
	^(value >> 21) bitAnd: 31
]

{ #category : #fields }
MIPSInstruction >> rt [
	^(value >> 16) bitAnd: 31
]

{ #category : #fields }
MIPSInstruction >> sa [
	^(value >> 6) bitAnd: 31
]

{ #category : #fields }
MIPSInstruction >> signedImmediate [
	^self unsigned16ToSigned16: (self unsignedImmediate)
]

{ #category : #fields }
MIPSInstruction >> target [
	^value bitAnd: 16r3FFFFFF
]

{ #category : #fields }
MIPSInstruction >> unsigned16ToSigned16: unsignedValue [
	self assert: (unsignedValue between: 0 and: 16rFFFF).
	unsignedValue >= 16r8000 ifTrue: [^unsignedValue - 16r10000].
	^unsignedValue
]

{ #category : #fields }
MIPSInstruction >> unsignedImmediate [
	^value bitAnd: 16rFFFF
]

{ #category : #'as yet unclassified' }
MIPSInstruction >> value [
	^value
]

{ #category : #'as yet unclassified' }
MIPSInstruction >> value: anInteger [
	self assert: (anInteger between: 0 and: 16rFFFFFFFF).
	value := anInteger
]
