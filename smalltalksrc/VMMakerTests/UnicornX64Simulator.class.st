Class {
	#name : #UnicornX64Simulator,
	#superclass : #UnicornSimulator,
	#category : #VMMakerTests
}

{ #category : #'phisical-registers' }
UnicornX64Simulator >> baseRegister [

	^ UcX86Registers rbx
]

{ #category : #'virtual-registers' }
UnicornX64Simulator >> classRegister [
	
	^ UcX86Registers rcx
]

{ #category : #'as yet unclassified' }
UnicornX64Simulator >> createUnicorn [

	^ Unicorn x8664
]

{ #category : #disassembling }
UnicornX64Simulator >> disassembler [
	
	^ LLVMDisassembler amd64
]

{ #category : #'virtual-registers' }
UnicornX64Simulator >> framePointerRegister [
	
	^ UcX86Registers rbp
]

{ #category : #accessing }
UnicornX64Simulator >> getReturnAddress [
	
	^ self peekAddress 
]

{ #category : #'virtual-registers' }
UnicornX64Simulator >> instructionPointerRegister [
	
	^ UcX86Registers rip
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> r10 [

	^ self readRegister: UcX86Registers r10
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> r11 [

	^ self readRegister: UcX86Registers r11
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> r12 [

	^ self readRegister: UcX86Registers r12
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> r8 [

	^ self readRegister: UcX86Registers r8
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> r9 [

	^ self readRegister: UcX86Registers r9
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> rax [

	^ self readRegister: UcX86Registers rax
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> rbp [

	^ self readRegister: UcX86Registers rbp
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> rbp: anInteger [ 
1halt.
	^ self writeRegister: UcX86Registers rbp value: anInteger
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> rbx [

	^ self readRegister: UcX86Registers rbx
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> rbx: aValue [

	^ self writeRegister: UcX86Registers rbx value: aValue
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> rcx [

	^ self readRegister: UcX86Registers rcx
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> rcx: anInteger [ 

	^ self writeRegister: UcX86Registers rcx value: anInteger
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> rdi [

	^ self readRegister: UcX86Registers rdi
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> rdx [

	^ self readRegister: UcX86Registers rdx
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> rdx: anInteger [ 

	^ self writeRegister: UcX86Registers rdx value: anInteger
]

{ #category : #'virtual-registers' }
UnicornX64Simulator >> receiverRegister [
	
	^ UcX86Registers rdx
]

{ #category : #accessing }
UnicornX64Simulator >> registerDescriptors [
	
	^ #(rip rax rbx rcx rdx rsp rbp r8 r9 r10 r11 r12 rsi rdi) collect: [ :e |
		UnicornRegisterDescriptor new
			simulator: self;
			name: e;
			yourself ]
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> rip [

	^ self readRegister: UcX86Registers rip
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> rsi [

	^ self readRegister: UcX86Registers rsi
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> rsp [

	^ self readRegister: UcX86Registers rsp
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> rsp: anInteger [ 
	
	^ self writeRegister: UcX86Registers rsp value: anInteger
]

{ #category : #'virtual-registers' }
UnicornX64Simulator >> sendNumberOfArgumentsRegister [
	
	^ UcX86Registers r9
]

{ #category : #'virtual-registers' }
UnicornX64Simulator >> stackPointerRegister [

	^ UcX86Registers rsp
]

{ #category : #accessing }
UnicornX64Simulator >> wordSize [
	
	^ 8
]
