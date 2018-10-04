"
An InLineLiteralsManager is a dummy class that understands the OutOfLineLiteralsManager API but does nothing.  It is used to allow the Cogits to work with back-ends that generate either in-line or out-of-line literals.
"
Class {
	#name : #InLineLiteralsManager,
	#superclass : #VMClass,
	#instVars : [
		'cogit',
		'objectMemory',
		'objectRepresentation'
	],
	#category : 'VMMaker-JIT'
}

{ #category : #translation }
InLineLiteralsManager class >> isNonArgumentImplicitReceiverVariableName: aString [
	^Cogit isNonArgumentImplicitReceiverVariableName: aString
]

{ #category : #initialization }
InLineLiteralsManager >> allocateLiterals: initialNumLiterals [
	<inline: true>
]

{ #category : #'generate machine code' }
InLineLiteralsManager >> assertValidAnnotation: annotation for: instruction [
	<var: #instruction type: #'AbstractInstruction *'>
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
	cogit := aCogit.
	objectMemory := aCogit objectMemory.
	objectRepresentation := aCogit objectRepresentation.
]

{ #category : #'compile abstract instructions' }
InLineLiteralsManager >> dumpLiterals: generateBranchAround [
	<inline: true>
]

{ #category : #'closed PIC parsing' }
InLineLiteralsManager >> endSizeOffset [
	"return the offset need from the cPICEndSize in order to point to just after the last instruction - here that means 0"
	^0
]

{ #category : #'garbage collection' }
InLineLiteralsManager >> fetchLiteralAtAnnotatedAddress: address using: instruction [
	"Normally literals are embedded in instructions and the annotation is at the start of
	 the following instruction, to cope with literals embedded in variable-length instructions,
	 since, e.g. on x86, the literal typically comes at the end of the instruction."
	<var: 'instruction' type: #'AbstractInstruction *'>
	<inline: true>
	^instruction literalBeforeFollowingAddress: address
]

{ #category : #'garbage collection' }
InLineLiteralsManager >> literalBytesFollowingBranchInClosedPIC [
	^0
]

{ #category : #'garbage collection' }
InLineLiteralsManager >> literalBytesFollowingJumpInClosedPIC [
	^0
]

{ #category : #testing }
InLineLiteralsManager >> mustDumpLiterals: currentOpcodeIndex [
	<inline: true>
	^false
]

{ #category : #'compile abstract instructions' }
InLineLiteralsManager >> resetForRecompile [
]

{ #category : #initialization }
InLineLiteralsManager >> resetLiterals [
]

{ #category : #'compile abstract instructions' }
InLineLiteralsManager >> saveForRecompile [
]

{ #category : #'garbage collection' }
InLineLiteralsManager >> storeLiteral: literal atAnnotatedAddress: address using: instruction [
	"Normally literals are embedded in instructions and the annotation is at the start of
	 the following instruction, to cope with literals embedded in variable-length instructions,
	 since, e.g. on x86, the literal typically comes at the end of the instruction."
	<var: 'address' type: #usqInt>
	<var: 'instruction' type: #'AbstractInstruction *'>
	<inline: true>
	^instruction storeLiteral: literal beforeFollowingAddress: address
]

{ #category : #'compile abstract instructions' }
InLineLiteralsManager >> uniqueLiteral: literal forInstruction: anInstruction [
	<var: #anInstruction type: #'AbstractInstruction *'>
	<returnTypeC: #'AbstractInstruction *'>
	<inline: true>
	^anInstruction
]
