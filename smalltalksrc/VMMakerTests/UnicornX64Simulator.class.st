Class {
	#name : #UnicornX64Simulator,
	#superclass : #UnicornSimulator,
	#category : #VMMakerTests
}

{ #category : #registers }
UnicornX64Simulator >> classRegister [
	
	^ UcX86Registers rcx
]

{ #category : #'as yet unclassified' }
UnicornX64Simulator >> createUnicorn [

	^ Unicorn x8664
]

{ #category : #registers }
UnicornX64Simulator >> framePointerRegister [
	
	^ UcX86Registers rbp
]

{ #category : #registers }
UnicornX64Simulator >> instructionPointerRegister [
	
	^ UcX86Registers rip
]

{ #category : #registers }
UnicornX64Simulator >> receiverRegister [
	
	^ UcX86Registers rdx
]

{ #category : #registers }
UnicornX64Simulator >> sendNumberOfArgumentsRegister [
	
	^ UcX86Registers r9
]

{ #category : #registers }
UnicornX64Simulator >> stackPointerRegister [

	^ UcX86Registers rsp
]

{ #category : #accessing }
UnicornX64Simulator >> wordSize [
	
	^ 8
]
