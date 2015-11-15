"
Simulator for little-endian 32-bit MIPS.
"
Class {
	#name : #MIPSELSimulator,
	#superclass : #MIPSSimulator,
	#category : #'Cog-Processors'
}

{ #category : #'as yet unclassified' }
MIPSELSimulator >> fetchInstruction: address [
	address < exectuableBase ifTrue: [self executeFault: address].
	address > exectuableLimit ifTrue: [self executeFault: address].
	(address bitAnd: 3) = 0 ifFalse: [self error: 'Unaligned read'].
	^memory unsignedLongAt: address + 1 bigEndian: false
]

{ #category : #'as yet unclassified' }
MIPSELSimulator >> readFault: address [
	^(ProcessorSimulationTrap
			pc: pc
			nextpc: pc + 4
			address: address
			type: #read
			accessor: nil)
		signal

]

{ #category : #'as yet unclassified' }
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

{ #category : #'as yet unclassified' }
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

{ #category : #'as yet unclassified' }
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
	^memory signedLongAt: address + 1 put: value
]

{ #category : #'as yet unclassified' }
MIPSELSimulator >> unsignedByte: address [
	address < readableBase ifTrue: [self readFault: address].
	address > readableLimit ifTrue: [self readFault: address].
	^memory at: address + 1
]

{ #category : #memory }
MIPSELSimulator >> unsignedByte: address put: value [
	address < writableBase ifTrue: [self writeFault: address].
	address > writableLimit ifTrue: [self writeFault: address].
	^memory at: address + 1 put: value
]

{ #category : #'as yet unclassified' }
MIPSELSimulator >> unsignedHalfword: address [
	address < readableBase ifTrue: [self readFault: address].
	address > readableLimit ifTrue: [self readFault: address].
	(address bitAnd: 1) = 0 ifFalse: [self error: 'Unaligned read'].
	^memory unsignedShortAt: address + 1 bigEndian: false
]

{ #category : #memory }
MIPSELSimulator >> unsignedHalfword: address put: value [
	(address bitAnd: 1) = 0 ifFalse: [self error: 'Unaligned read'].
	address < writableBase ifTrue: [self writeFault: address].
	address > writableLimit ifTrue: [self writeFault: address].
	^memory unsignedShortAt: address + 1 put: value
]

{ #category : #'as yet unclassified' }
MIPSELSimulator >> unsignedWord: address [
	address < readableBase ifTrue: [self readFault: address].
	address > readableLimit ifTrue: [self readFault: address].
	(address bitAnd: 3) = 0 ifFalse: [self error: 'Unaligned read'].
	^memory unsignedLongAt: address + 1 bigEndian: false
]
