Class {
	#name : #VMMethodBytecodeToIRMapping,
	#superclass : #Object,
	#instVars : [
		'method',
		'ir',
		'mappingList'
	],
	#category : #'VMMaker-Tools'
}

{ #category : #'instance creation' }
VMMethodBytecodeToIRMapping class >> on: aMethod [

	^ self new
		method: aMethod;
		yourself
]

{ #category : #accessing }
VMMethodBytecodeToIRMapping >> computeIR [

	| coggedResult cogit |
	coggedResult := StackToRegisterMappingCogit
		cog: method
		selectorOrNumCopied: (method isCompiledBlock ifFalse: [ method selector ] ifTrue: [ method numTemps ])
		options: #(
			COGMTVM false
			ObjectMemory Spur64BitCoMemoryManager
			ISA aarch64
			#bytecodeTableInitializer initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid
			MULTIPLEBYTECODESETS true).
			
	cogit := coggedResult second.
	^ ir := (0 to: cogit getOpcodeIndex - 1) collect: [ :i | cogit abstractOpcodes at: i ]
]

{ #category : #accessing }
VMMethodBytecodeToIRMapping >> gtInspectorMappingIn: composite [
	<gtInspectorPresentationOrder: 0>
	^ composite fastTable
		title: 'Bytecode -> IR';
		display: [ :anObject | self mappingList ];
		column: 'Bytecode' evaluated: [ :aMapping | aMapping bytecodeString ];
		column: 'IR' evaluated: [ :aMapping | aMapping irString ]	
]

{ #category : #accessing }
VMMethodBytecodeToIRMapping >> ir [
	^ ir ifNil: [ self computeIR ]
]

{ #category : #accessing }
VMMethodBytecodeToIRMapping >> mappingList [
	
	| irStream mappings |
	mappingList ifNotNil: [ ^ mappingList ].

	irStream := self ir readStream.
	mappings := OrderedCollection new.
	[ irStream atEnd ] whileFalse: [ | irInstruction bytecode mapping |
		irInstruction := irStream next.
		mapping := VMBytecodeToIRMapping new.
		bytecode := irInstruction bcpc
			ifNil: [ nil ]
			ifNotNil: [ method symbolicBytecodes
				detect: [ :e | e offset = (irInstruction bcpc + 1) ]
				ifNone: [ 'Bad bcpc mapping?' ] ].
		mapping bytecodeInstruction: bytecode.
		mapping irInstruction: irInstruction.
		mappings add: mapping.
	].
	^ mappingList := mappings
]

{ #category : #accessing }
VMMethodBytecodeToIRMapping >> method: aMethod [

	method := aMethod
]
