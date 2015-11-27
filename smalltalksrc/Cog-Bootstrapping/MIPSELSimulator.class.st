"
Simulator for little-endian 32-bit MIPS.
"
Class {
	#name : #MIPSELSimulator,
	#superclass : #MIPSSimulator,
	#category : #'Cog-Processors'
}

{ #category : #accessing }
MIPSELSimulator >> endianness [
	^#little
]

{ #category : #memory }
MIPSELSimulator >> executeFault: address [
	| jumpInstruction type |
	self assert: inDelaySlot not.
	jumpInstruction := MIPSInstruction new value: (self fetchInstruction: jumpingPC).
	jumpInstruction opcode = J ifTrue: [type := #jump].
	jumpInstruction opcode = JAL ifTrue: [type := #call].
	jumpInstruction opcode = SPECIAL ifTrue: 
		[jumpInstruction function = JR ifTrue:
			[jumpInstruction rs = RA
				ifTrue: [type := #return]
				ifFalse: [type := #jump]].
		jumpInstruction function = JALR ifTrue:
			[type := #call]].
	self assert: type ~~ nil.

	^(ProcessorSimulationTrap
			pc: nil
			nextpc: nil
			address: address
			type: type
			accessor: nil)
		signal
]

{ #category : #memory }
MIPSELSimulator >> fetchInstruction: address [
	address < exectuableBase ifTrue: [self executeFault: address].
	address > exectuableLimit ifTrue: [self executeFault: address].
	(address bitAnd: 3) = 0 ifFalse: [self error: 'Unaligned read'].
	^memory unsignedLongAt: address + 1 bigEndian: false
]

{ #category : #memory }
MIPSELSimulator >> readFault: address [
	| destReg |
	self assert: inDelaySlot not. "Or we have to store nextPC somewhere."
	destReg := (MIPSInstruction new value: (self fetchInstruction: pc)) rt.
	
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 4
			address: address
			type: #read
			accessor: (self setterForRegister: destReg))
		signal

]

{ #category : #memory }
MIPSELSimulator >> signedByte: address [
	address < readableBase ifTrue: [self readFault: address].
	address > readableLimit ifTrue: [self readFault: address].
	^memory signedByteAt: address + 1
]

{ #category : #memory }
MIPSELSimulator >> signedByte: address put: value [
	address < writableBase ifTrue: [self writeFault: address].
	address > writableLimit ifTrue: [self writeFault: address].
	^memory signedByteAt: address + 1 put: value
]

{ #category : #memory }
MIPSELSimulator >> signedHalfword: address [
	(address bitAnd: 1) = 0 ifFalse: [self error: 'Unaligned read'].
	address < readableBase ifTrue: [self readFault: address].
	address > readableLimit ifTrue: [self readFault: address].
	^memory signedShortAt: address + 1
]

{ #category : #memory }
MIPSELSimulator >> signedHalfword: address put: value [
	(address bitAnd: 1) = 0 ifFalse: [self error: 'Unaligned read'].
	address < writableBase ifTrue: [self writeFault: address].
	address > writableLimit ifTrue: [self writeFault: address].
	^memory signedShortAt: address + 1 put: value
]

{ #category : #memory }
MIPSELSimulator >> signedWord: address [
	(address bitAnd: 3) = 0 ifFalse: [self error: 'Unaligned read'].
	address < readableBase ifTrue: [self readFault: address].
	address > readableLimit ifTrue: [self readFault: address].		
	^memory longAt: address + 1
]

{ #category : #memory }
MIPSELSimulator >> signedWord: address put: value [
	(address bitAnd: 3) = 0 ifFalse: [self error: 'Unaligned read'].
	address < writableBase ifTrue: [self writeFault: address].
	address > writableLimit ifTrue: [self writeFault: address].
	^memory longAt: address + 1 put: value
]

{ #category : #memory }
MIPSELSimulator >> unsignedByte: address [
	address < readableBase ifTrue: [self readFault: address].
	address > readableLimit ifTrue: [self readFault: address].
	^memory byteAt: address + 1
]

{ #category : #memory }
MIPSELSimulator >> unsignedByte: address put: value [
	address < writableBase ifTrue: [self writeFault: address].
	address > writableLimit ifTrue: [self writeFault: address].
	^memory byteAt: address + 1 put: value
]

{ #category : #memory }
MIPSELSimulator >> unsignedHalfword: address [
	address < readableBase ifTrue: [self readFault: address].
	address > readableLimit ifTrue: [self readFault: address].
	(address bitAnd: 1) = 0 ifFalse: [self error: 'Unaligned read'].
	^memory unsignedShortAt: address + 1
]

{ #category : #memory }
MIPSELSimulator >> unsignedHalfword: address put: value [
	(address bitAnd: 1) = 0 ifFalse: [self error: 'Unaligned read'].
	address < writableBase ifTrue: [self writeFault: address].
	address > writableLimit ifTrue: [self writeFault: address].
	^memory unsignedShortAt: address + 1 put: value
]

{ #category : #memory }
MIPSELSimulator >> unsignedWord: address [
	address < readableBase ifTrue: [self readFault: address].
	address > readableLimit ifTrue: [self readFault: address].
	(address bitAnd: 3) = 0 ifFalse: [self error: 'Unaligned read'].
	^memory unsignedLongAt: address + 1 bigEndian: false
]

{ #category : #memory }
MIPSELSimulator >> writeFault: address [
	| srcReg |
	self assert: inDelaySlot not. "Or we have to store nextPC somewhere."
	srcReg := (MIPSInstruction new value: (self fetchInstruction: pc)) rt.
	
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 4
			address: address
			type: #write
			accessor: (self getterForRegister: srcReg))
		signal

]
