Class {
	#name : #VMBytecodeMethod,
	#superclass : #Object,
	#instVars : [
		'virtualMachine',
		'methodOop'
	],
	#category : #'VMMakerTests-Visualisation'
}

{ #category : #'instance creation' }
VMBytecodeMethod class >> newOnInterpreter: virtualMachine methodOop: methodOop [
	
	^ self new
		virtualMachine: virtualMachine;
		methodOop: methodOop;
		yourself
]

{ #category : #accessing }
VMBytecodeMethod >> at: index [

	^ virtualMachine objectMemory fetchByte: index - 1 "0 based" ofObject: methodOop
]

{ #category : #accessing }
VMBytecodeMethod >> disassemble [
	| symbolicBytecodes |
	symbolicBytecodes := SymbolicBytecodeBuilder decode: self.
	^ '
' join: (symbolicBytecodes collect: [ :sbc | sbc description ])
]

{ #category : #accessing }
VMBytecodeMethod >> encoderClass [
	^ (virtualMachine methodUsesAlternateBytecodeSet: methodOop)
		ifTrue: [ EncoderForSistaV1 ]
		ifFalse: [ EncoderForV3PlusClosures ]
]

{ #category : #accessing }
VMBytecodeMethod >> endPC [
	
	^ virtualMachine objectMemory bytesInObject: methodOop
]

{ #category : #accessing }
VMBytecodeMethod >> initialPC [
	"Answer the program counter for the receiver's first bytecode."

	^ (self numLiterals + 1) * virtualMachine objectMemory wordSize + 1
]

{ #category : #accessing }
VMBytecodeMethod >> literalAt: anInteger [ 
	
	^ 'literal key' -> 'literal?'
]

{ #category : #accessing }
VMBytecodeMethod >> methodOop [
	^ methodOop
]

{ #category : #accessing }
VMBytecodeMethod >> methodOop: anObject [
	methodOop := anObject
]

{ #category : #accessing }
VMBytecodeMethod >> numLiterals [
	
	^ virtualMachine objectMemory literalCountOf: methodOop 
]

{ #category : #accessing }
VMBytecodeMethod >> virtualMachine [
	^ virtualMachine
]

{ #category : #accessing }
VMBytecodeMethod >> virtualMachine: anObject [
	virtualMachine := anObject
]
