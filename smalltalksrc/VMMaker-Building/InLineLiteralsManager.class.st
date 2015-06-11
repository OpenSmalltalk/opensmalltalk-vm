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
]

{ #category : #'compile abstract instructions' }
InLineLiteralsManager >> dumpLiterals: generateBranchAround [
	<inline: true>
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

{ #category : #testing }
InLineLiteralsManager >> mustDumpLiterals: currentOpcodeIndex [
	<inline: true>
	^false
]

{ #category : #initialization }
InLineLiteralsManager >> resetLiterals: numLiteralsHint [
	<inline: true>
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
