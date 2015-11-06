"
An InLineLiteralsManager is a dummy class that understands the OutOfLineLiteralsManager API but does nothing.  It is used to allow the Cogits to work with back-ends that generate either in-line or out-of-line literals.
"
Class {
	#name : #InLineLiteralsManager,
	#superclass : #VMClass,
	#instVars : [
		'cogit'
	],
	#category : #'VMMaker-JIT'
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

{ #category : #'closed PIC parsing' }
InLineLiteralsManager >> cPICCase: caseIndex relocateJumpLongBefore: pc by: delta [
	<inline: true>
	cogit backEnd
		relocateJumpLongBeforeFollowingAddress: pc
		by: delta
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

{ #category : #'garbage collection' }
InLineLiteralsManager >> classRefInClosedPICAt: mcpc [
	<inline: true>
	^cogit backEnd literalBeforeFollowingAddress: mcpc - cogit backEnd loadLiteralByteSize
]

{ #category : #initialization }
InLineLiteralsManager >> cogit: aCogit [
	<doNotGenerate>
	cogit := aCogit
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
	<inline: true>
	^0
]

{ #category : #'garbage collection' }
InLineLiteralsManager >> literalBytesFollowingJumpInClosedPIC [
	<inline: true>
	^0
]

{ #category : #testing }
InLineLiteralsManager >> mustDumpLiterals: currentOpcodeIndex [
	<inline: true>
	^false
]

{ #category : #'garbage collection' }
InLineLiteralsManager >> objRefInClosedPICAt: mcpc [
	"'mcpc' refers to the jump/branch instruction at the end of
	each cpic case. The method objRef is the method object referenced by the
	movI $0x0bada553, %ebx 
	or
	ldr    r6, [pc, #64]    ; 0x000017d4 16rBADA553
	type instruction preceeding this"
	<inline: true>
	^cogit backEnd literalBeforeFollowingAddress: mcpc
]

{ #category : #'compile abstract instructions' }
InLineLiteralsManager >> resetForBlockCompile [
	<inline: true>
]

{ #category : #initialization }
InLineLiteralsManager >> resetLiterals [
	<inline: true>
]

{ #category : #'compile abstract instructions' }
InLineLiteralsManager >> saveForBlockCompile [
	<inline: true>
]

{ #category : #'garbage collection' }
InLineLiteralsManager >> storeClassRef: classObj inClosedPICAt: address [
	<var: #address type: #usqInt>
	<inline: true>
	cogit backEnd storeLiteral: classObj beforeFollowingAddress: address - cogit backEnd loadLiteralByteSize
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

{ #category : #'garbage collection' }
InLineLiteralsManager >> storeObjRef: literal inClosedPICAt: address [
	"'mcpc' refers to the jump/branch instruction at the end of
	each cpic case. The objRef is the literal referenced by the
	movI $0x0bada553, %ebx or
	ldr    r6, [pc, #64]    ; 0x000017d4 16rBADA553
	type instruction preceeding this"
	<var: #address type: #usqInt>
	<inline: true>
	cogit backEnd storeLiteral: literal beforeFollowingAddress: address
]

{ #category : #'compile abstract instructions' }
InLineLiteralsManager >> uniqueLiteral: literal forInstruction: anInstruction [
	<var: #anInstruction type: #'AbstractInstruction *'>
	<returnTypeC: #'AbstractInstruction *'>
	<inline: true>
	^anInstruction
]
