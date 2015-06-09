"
An InLineLiteralsManager is a dummy class that understands the OutOfLineLiteralsManager API but does nothing.  It is used to allow the Cogits to work with back-ends that generate either in-line or out-of-line literals.
"
Class {
	#name : #InLineLiteralsManager,
	#superclass : #VMClass,
	#category : #'VMMaker-JIT'
}

{ #category : #initialization }
InLineLiteralsManager >> allocateLiterals: initialNumLiterals [
	<inline: true>
]

{ #category : #'compile abstract instructions' }
InLineLiteralsManager >> checkLiteral: literal forInstruction: anInstruction [
	<var: #anInstruction type: #'AbstractInstruction *'>
	<returnTypeC: #'AbstractInstruction *'>
	<inline: true>
	^anInstruction
]

{ #category : #'compile abstract instructions' }
InLineLiteralsManager >> checkQuickConstant: literal forInstruction: anInstruction [
	<var: #anInstruction type: #'AbstractInstruction *'>
	<returnTypeC: #'AbstractInstruction *'>
	<inline: true>
	^anInstruction
]

{ #category : #initialization }
InLineLiteralsManager >> cogit: aCogit [
	<doNotGenerate>
]

{ #category : #'compile abstract instructions' }
InLineLiteralsManager >> dumpLiterals [
	<inline: true>
]

{ #category : #testing }
InLineLiteralsManager >> mustDumpLiterals: opcodeIndex [
	<inline: true>
	^false
]

{ #category : #initialization }
InLineLiteralsManager >> resetLiterals: numLiteralsHint [
	<inline: true>
]
