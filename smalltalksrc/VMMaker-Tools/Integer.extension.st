Extension { #name : #Integer }

{ #category : #'*VMMaker-Tools' }
Integer >> aarch64Disassembled [
	
	^ self disassembleWith: LLVMDisassembler aarch64
]

{ #category : #'*VMMaker-Tools' }
Integer >> disassembleWith: aLLVMDisassembler [ 
	
	"Create a byte array big enough to encode the instruction"
	| array |
	array := ByteArray new: self asByteArray size.
	array integerAt: 1 put: self size: array size signed: false.
	^ aLLVMDisassembler disassembleInstructionIn: array pc: 0
]
