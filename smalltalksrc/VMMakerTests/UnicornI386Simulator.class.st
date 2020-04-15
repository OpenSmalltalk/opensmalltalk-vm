Class {
	#name : #UnicornI386Simulator,
	#superclass : #UnicornSimulator,
	#category : #VMMakerTests
}

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> createUnicorn [

	^ Unicorn x86
]

{ #category : #registers }
UnicornI386Simulator >> framePointerRegister [
	
	^ UcX86Registers ebp
]

{ #category : #registers }
UnicornI386Simulator >> instructionPointerRegister [
	
	^ UcX86Registers eip
]

{ #category : #registers }
UnicornI386Simulator >> receiverRegister [
	
	^ UcX86Registers edx
]

{ #category : #registers }
UnicornI386Simulator >> stackPointerRegister [
	
	^ UcX86Registers esp
]

{ #category : #accessing }
UnicornI386Simulator >> wordSize [
	
	^ 4
]
