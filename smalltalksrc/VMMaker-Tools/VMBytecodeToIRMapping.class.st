Class {
	#name : #VMBytecodeToIRMapping,
	#superclass : #Object,
	#instVars : [
		'bytecodeInstruction',
		'irInstruction'
	],
	#category : #'VMMaker-Tools'
}

{ #category : #accessing }
VMBytecodeToIRMapping >> bytecodeInstruction [
	^ bytecodeInstruction
]

{ #category : #accessing }
VMBytecodeToIRMapping >> bytecodeInstruction: anObject [
	bytecodeInstruction := anObject
]

{ #category : #accessing }
VMBytecodeToIRMapping >> bytecodeString [
	
	^ bytecodeInstruction asString
]

{ #category : #accessing }
VMBytecodeToIRMapping >> irInstruction [
	^ irInstruction
]

{ #category : #accessing }
VMBytecodeToIRMapping >> irInstruction: anObject [
	irInstruction := anObject
]

{ #category : #accessing }
VMBytecodeToIRMapping >> irString [
	
	irInstruction ifNil: [ ^ '' ].
	^ String streamContents: [:s| irInstruction printStateOn: s]
]
