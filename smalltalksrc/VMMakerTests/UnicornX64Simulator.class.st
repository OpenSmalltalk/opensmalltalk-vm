Class {
	#name : #UnicornX64Simulator,
	#superclass : #UnicornSimulator,
	#category : #VMMakerTests
}

{ #category : #'virtual-registers' }
UnicornX64Simulator >> classRegister [
	
	^ UcX86Registers rcx
]

{ #category : #'as yet unclassified' }
UnicornX64Simulator >> createUnicorn [

	^ Unicorn x8664
]

{ #category : #'virtual-registers' }
UnicornX64Simulator >> framePointerRegister [
	
	^ UcX86Registers rbp
]

{ #category : #'virtual-registers' }
UnicornX64Simulator >> instructionPointerRegister [
	
	^ UcX86Registers rip
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
UnicornX64Simulator >> rbx [

	^ self readRegister: UcX86Registers rbx
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> rcx [

	^ self readRegister: UcX86Registers rcx
]

{ #category : #'phisical-registers' }
UnicornX64Simulator >> rdx [

	^ self readRegister: UcX86Registers rdx
]

{ #category : #'virtual-registers' }
UnicornX64Simulator >> receiverRegister [
	
	^ UcX86Registers rdx
]

{ #category : #accessing }
UnicornX64Simulator >> registerDescriptors [
	
	^ #( rip rax rbx rcx rdx rsp rbp ) collect: [ :e |
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
UnicornX64Simulator >> rsp [

	^ self readRegister: UcX86Registers rsp
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
