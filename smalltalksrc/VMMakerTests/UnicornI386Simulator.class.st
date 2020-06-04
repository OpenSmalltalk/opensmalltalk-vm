Class {
	#name : #UnicornI386Simulator,
	#superclass : #UnicornSimulator,
	#category : #VMMakerTests
}

{ #category : #registers }
UnicornI386Simulator >> baseRegister [

	^ UcX86Registers ebx
]

{ #category : #registers }
UnicornI386Simulator >> classRegister [

	^ UcX86Registers ecx
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> createUnicorn [

	^ Unicorn x86
]

{ #category : #disassembling }
UnicornI386Simulator >> disassembler [
	
	^ LLVMDisassembler i386
]

{ #category : #accessing }
UnicornI386Simulator >> eax [
	
	^ self readRegister: UcX86Registers eax
]

{ #category : #accessing }
UnicornI386Simulator >> ebp [
	^ self readRegister: UcX86Registers ebp
]

{ #category : #accessing }
UnicornI386Simulator >> ebx [
	
	^ self readRegister: UcX86Registers ebx
]

{ #category : #accessing }
UnicornI386Simulator >> ecx [
	^ self readRegister: UcX86Registers ecx
]

{ #category : #accessing }
UnicornI386Simulator >> edi [
	
	^ self readRegister: UcX86Registers edi
]

{ #category : #accessing }
UnicornI386Simulator >> edx [
	^ self readRegister: UcX86Registers edx
]

{ #category : #registers }
UnicornI386Simulator >> eip [
	
	^ self readRegister: UcX86Registers eip
]

{ #category : #accessing }
UnicornI386Simulator >> esi [
	
	^ self readRegister: UcX86Registers esi
]

{ #category : #accessing }
UnicornI386Simulator >> esp [
	
	^ self readRegister: UcX86Registers esp
]

{ #category : #registers }
UnicornI386Simulator >> framePointerRegister [
	
	^ UcX86Registers ebp
]

{ #category : #accessing }
UnicornI386Simulator >> getReturnAddress [
	
	^ self peekAddress
]

{ #category : #registers }
UnicornI386Simulator >> instructionPointerRegister [
	
	^ UcX86Registers eip
]

{ #category : #registers }
UnicornI386Simulator >> receiverRegister [
	
	^ UcX86Registers edx
]

{ #category : #accessing }
UnicornI386Simulator >> registerDescriptors [
	
	^ #(eip eax ebx ecx edx esp ebp esi edi) collect: [ :e |
		UnicornRegisterDescriptor new
			simulator: self;
			name: e;
			yourself ]
]

{ #category : #registers }
UnicornI386Simulator >> sendNumberOfArgumentsRegister [

	^ UcX86Registers ebx
]

{ #category : #registers }
UnicornI386Simulator >> stackPointerRegister [
	
	^ UcX86Registers esp
]

{ #category : #accessing }
UnicornI386Simulator >> wordSize [
	
	^ 4
]
