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
	<inline: true>
	^cogit backEnd literalBeforeFollowingAddress: mcpc
]

{ #category : #'compile abstract instructions' }
InLineLiteralsManager >> resetForBlockCompile [
	<inline: true>
]

{ #category : #initialization }
InLineLiteralsManager >> resetLiterals: numLiteralsHint [
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
