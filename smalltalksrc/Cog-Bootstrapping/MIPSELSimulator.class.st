"
Simulator for little-endian 32-bit MIPS.
"
Class {
	#name : #MIPSELSimulator,
	#superclass : #MIPSSimulator,
	#category : #'Cog-Processors'
}

{ #category : #'as yet unclassified' }
MIPSELSimulator >> signedByte: address [
	^memory signedByteAt: address + 1
]

{ #category : #memory }
MIPSELSimulator >> signedByte: address put: value [
	^memory signedByteAt: address + 1 put: value
]

{ #category : #'as yet unclassified' }
MIPSELSimulator >> signedHalfword: address [
	(address bitAnd: 1) = 0 ifFalse: [self error: 'Unaligned read'].
	^memory signedShortAt: address + 1
]

{ #category : #memory }
MIPSELSimulator >> signedHalfword: address put: value [
	(address bitAnd: 1) = 0 ifFalse: [self error: 'Unaligned read'].
	^memory signedShortAt: address + 1 put: value
]

{ #category : #'as yet unclassified' }
MIPSELSimulator >> signedWord: address [
	(address bitAnd: 3) = 0 ifFalse: [self error: 'Unaligned read'].
	^memory signedLongAt: address + 1
]

{ #category : #memory }
MIPSELSimulator >> signedWord: address put: value [
	(address bitAnd: 3) = 0 ifFalse: [self error: 'Unaligned read'].
	^memory signedLongAt: address + 1 put: value
]

{ #category : #'as yet unclassified' }
MIPSELSimulator >> snsignedWord: address [
	(address bitAnd: 3) = 0 ifFalse: [self error: 'Unaligned read'].
	^memory unsignedLongAt: address + 1 bigEndian: false
]

{ #category : #'as yet unclassified' }
MIPSELSimulator >> unsignedByte: address [
	^memory at: address + 1
]

{ #category : #memory }
MIPSELSimulator >> unsignedByte: address put: value [
	^memory at: address + 1 put: value
]

{ #category : #'as yet unclassified' }
MIPSELSimulator >> unsignedHalfword: address [
	(address bitAnd: 1) = 0 ifFalse: [self error: 'Unaligned read'].
	^memory unsignedShortAt: address + 1 bigEndian: false
]

{ #category : #memory }
MIPSELSimulator >> unsignedHalfword: address put: value [
	(address bitAnd: 1) = 0 ifFalse: [self error: 'Unaligned read'].
	^memory unsignedShortAt: address + 1 put: value
]

{ #category : #'as yet unclassified' }
MIPSELSimulator >> unsignedWord: address [
	(address bitAnd: 3) = 0 ifFalse: [self error: 'Unaligned read'].
	^memory unsignedLongAt: address + 1 bigEndian: false
]
