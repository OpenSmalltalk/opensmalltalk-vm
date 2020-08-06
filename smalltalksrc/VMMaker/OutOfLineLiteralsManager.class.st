"
An OutOfLineLiteralsManager manages the dumping of literals for backends that wat to keep literals out-of-line, accessed by pc-relative addressing.

Instance Variables
	cogit:		<Cogit>
"
Class {
	#name : #OutOfLineLiteralsManager,
	#superclass : #VMClass,
	#instVars : [
		'cogit',
		'objectMemory',
		'objectRepresentation',
		'firstOpcodeIndex',
		'nextLiteralIndex',
		'lastDumpedLiteralIndex',
		'literals',
		'literalsSize',
		'savedFirstOpcodeIndex',
		'savedNextLiteralIndex',
		'savedLastDumpedLiteralIndex'
	],
	#pools : [
		'CogAbstractRegisters',
		'CogCompilationConstants',
		'CogRTLOpcodes'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
OutOfLineLiteralsManager class >> declareCVarsIn: aCCodeGenerator [
	aCCodeGenerator var: 'literals' type: #'AbstractInstruction *'
]

{ #category : #translation }
OutOfLineLiteralsManager class >> isNonArgumentImplicitReceiverVariableName: aString [
	^Cogit isNonArgumentImplicitReceiverVariableName: aString
]

{ #category : #'compile abstract instructions' }
OutOfLineLiteralsManager >> allocateLiteral: aLiteral [
	"Allocate an unsharable Literal instruction for the literal and answer it."
	<returnTypeC: #'AbstractInstruction *'>
	<inline: true>
	| litInst |
	<var: 'litInst' type: #'AbstractInstruction *'>
	nextLiteralIndex >= literalsSize ifTrue:
		[self allocateLiterals: literalsSize + 8].
	litInst := self literalInstructionAt: nextLiteralIndex.
	litInst initializeUniqueLiteral: aLiteral.
	nextLiteralIndex := nextLiteralIndex + 1.
	"Record the opcodeIndex of the first dependent instruction (the first instruction that references an out-of-line literal)"
	firstOpcodeIndex > cogit getOpcodeIndex ifTrue:
		[firstOpcodeIndex := cogit getOpcodeIndex - 1].
	^litInst
]

{ #category : #initialization }
OutOfLineLiteralsManager >> allocateLiterals: initialNumLiterals [
	<inline: true>
	| newLiterals newInst existingInst |
	<var: 'newInst' type: #'AbstractInstruction *'>
	<var: 'existingInst' type: #'AbstractInstruction *'>
	<var: 'newLiterals' type: #'AbstractInstruction *'>
	initialNumLiterals > literalsSize ifTrue:
		[newLiterals := self cCode:
								[self c: initialNumLiterals alloc: (self sizeof: CogAbstractInstruction)]
							inSmalltalk:
								[CArrayAccessor on: ((1 to: initialNumLiterals) collect: [:i| CogCompilerClass for: cogit])].
		 "Must copy across state (not using realloc, cuz...) and
		  must also update existing instructions to refer to the new ones...
		  It's either this or modify all generation routines to be able to retry
		  with more literals after running out of literals."
		 literals ifNotNil:
			[0 to: nextLiteralIndex - 1 do:
				[:i|
				existingInst := self literalInstructionAt: i.
				newInst := self addressOf: (newLiterals at: i).
				newInst cloneLiteralFrom: existingInst.
				self assert: existingInst dependent isNil.
				existingInst dependent: newInst].
			0 to: cogit getOpcodeIndex - 1 do:
				[:i|
				existingInst := cogit abstractInstructionAt: i.
				(existingInst dependent notNil
				 and: [existingInst dependent opcode = Literal]) ifTrue:
					[existingInst dependent: existingInst dependent dependent]]].
		 self cCode: [self free: literals] inSmalltalk: [].
		 literals := newLiterals.
		 literalsSize := initialNumLiterals]
]

{ #category : #'generate machine code' }
OutOfLineLiteralsManager >> assertValidAnnotation: annotation for: instruction [
	"Insist that the IsObjectReference applies only to out-of-line literals."
	<var: #instruction type: #'AbstractInstruction *'>
	<inline: true>
	self assert: (annotation ~= cogit getIsObjectReference or: [instruction opcode = Literal])
]

{ #category : #'compile abstract instructions' }
OutOfLineLiteralsManager >> checkLiteral: literal forInstruction: anInstruction [
	<var: #anInstruction type: #'AbstractInstruction *'>
	<returnTypeC: #'AbstractInstruction *'>
	anInstruction usesOutOfLineLiteral ifTrue:
		[anInstruction dependent: (self locateLiteral: literal)].
	^anInstruction
]

{ #category : #'compile abstract instructions' }
OutOfLineLiteralsManager >> checkQuickConstant: literal forInstruction: anInstruction [
	<var: #anInstruction type: #'AbstractInstruction *'>
	<returnTypeC: #'AbstractInstruction *'>
	<inline: true>
	anInstruction usesOutOfLineLiteral ifTrue:
		[anInstruction dependent: (self locateLiteral: (self cCode: [literal] inSmalltalk: [literal bitAnd: 1 << (objectMemory wordSize * 8) - 1]))].
	^anInstruction
]

{ #category : #initialization }
OutOfLineLiteralsManager >> cogit: aCogit [
	<doNotGenerate>
	cogit := aCogit.
	objectMemory := aCogit objectMemory.
	objectRepresentation := aCogit objectRepresentation.
	literalsSize := 0
]

{ #category : #'compile abstract instructions' }
OutOfLineLiteralsManager >> dumpLiterals: generateBranchAround [
	"Output all pending literal instructions, making the originals dependents of the generated ones
	 so that a later pass will copy the address of each generated literl inst to its original in literals,
	 and hence allow the instruction using the literal to compute the correct address.."
	| jump litInst |
	<var: 'jump' type: #'AbstractInstruction *'>
	<var: 'litInst' type: #'AbstractInstruction *'>

	generateBranchAround ifTrue:
		[jump := cogit Jump: 0].
	cogit AlignmentNops: cogit objectMemory wordSize.
	lastDumpedLiteralIndex to: nextLiteralIndex - 1 do:
		[:i|
		litInst := self literalInstructionAt: i.
		(cogit gen: Literal operand: (litInst operands at: 0)) dependent: litInst.
		litInst setLiteralOpcodeIndex: cogit getOpcodeIndex].
	generateBranchAround ifTrue:
		[jump jmpTarget: cogit Label].

	firstOpcodeIndex := cogit getOpcodeIndex.
	lastDumpedLiteralIndex := nextLiteralIndex
]

{ #category : #'closed PIC parsing' }
OutOfLineLiteralsManager >> endSizeOffset [
	"return the offset need from the cPICEndSize in order to point to just after the last instruction - here that means bytesPerOop * list size"
	^nextLiteralIndex * objectMemory bytesPerOop
]

{ #category : #'garbage collection' }
OutOfLineLiteralsManager >> fetchLiteralAtAnnotatedAddress: address using: instruction [
	"With out-of-line literals, the IsObjectReference annotation refers to
	 the start of the literal and hence access the memory directly."
	<var: 'instruction' type: #'AbstractInstruction *'>
	<inline: true>
	^objectMemory longAt: address
]

{ #category : #'compile abstract instructions' }
OutOfLineLiteralsManager >> literalInstructionAt: index [
	<cmacro: '(index) (&literals[index])'>
	<returnTypeC: #'AbstractInstruction *'>
	^(literals at: index)
		ifNil: [literals at: index put: (CogCompilerClass for: cogit)]
		ifNotNil: [:litInst| litInst]
]

{ #category : #testing }
OutOfLineLiteralsManager >> literalInstructionInRange: litInst [
	"A literal is in range if its opcode index is within outOfLineLiteralOpcodeLimit,
	 or if its index has yet to be assigned."
	<var: 'litInst' type: #'AbstractInstruction *'>
	| opcodeIdx |
	opcodeIdx := litInst literalOpcodeIndex.
	^opcodeIdx asInteger < 0
	  or: [self assert: cogit getOpcodeIndex >= opcodeIdx.
		cogit getOpcodeIndex - opcodeIdx < cogit backEnd outOfLineLiteralOpcodeLimit]
]

{ #category : #'compile abstract instructions' }
OutOfLineLiteralsManager >> locateLiteral: aLiteral [
	"Search for a Literal instruction that is in-range and answer it.  Otherwise
	 allocate a new sharable Literal instruction for the literal and answer it."
	<returnTypeC: #'AbstractInstruction *'>
	<inline: false>
	| litInst |
	<var: 'litInst' type: #'AbstractInstruction *'>
	0 to: nextLiteralIndex - 1 do:
		[:i|
		litInst := self literalInstructionAt: i.
		((litInst operands at: 0) = aLiteral
		 and: [litInst isSharable
		 and: [self literalInstructionInRange: litInst]]) ifTrue:
			[^litInst]].
	nextLiteralIndex >= literalsSize ifTrue:
		[self allocateLiterals: literalsSize + 8].
	litInst := self literalInstructionAt: nextLiteralIndex.
	litInst initializeSharableLiteral: aLiteral.
	nextLiteralIndex := nextLiteralIndex + 1.
	"Record the opcodeIndex of the first dependent instruction (the first instruction that references an out-of-line literal)"
	firstOpcodeIndex > cogit getOpcodeIndex ifTrue:
		[firstOpcodeIndex := cogit getOpcodeIndex - 1].
	^litInst
]

{ #category : #testing }
OutOfLineLiteralsManager >> mustDumpLiterals: currentOpcodeIndex [
	<inline: true>
	^currentOpcodeIndex >= firstOpcodeIndex
	  and: [currentOpcodeIndex - firstOpcodeIndex >= cogit backEnd outOfLineLiteralOpcodeLimit]
]

{ #category : #initialization }
OutOfLineLiteralsManager >> resetForRecompile [
	<inline: true>
	firstOpcodeIndex := savedFirstOpcodeIndex.
	nextLiteralIndex := savedNextLiteralIndex.
	lastDumpedLiteralIndex := savedLastDumpedLiteralIndex
]

{ #category : #initialization }
OutOfLineLiteralsManager >> resetLiterals [
	<inline: true>
	firstOpcodeIndex := 1 << 16. "an impossibly high value"
	nextLiteralIndex := lastDumpedLiteralIndex := 0
]

{ #category : #initialization }
OutOfLineLiteralsManager >> saveForRecompile [

	<inline: true>
	savedFirstOpcodeIndex := firstOpcodeIndex.
	savedNextLiteralIndex := nextLiteralIndex.
	savedLastDumpedLiteralIndex := lastDumpedLiteralIndex
]

{ #category : #'garbage collection' }
OutOfLineLiteralsManager >> storeLiteral: literal atAnnotatedAddress: address using: instruction [
	"With out-of-line literals, the IsObjectReference annotation refers to
	 the start of the literal and hence access the memory directly."
	<var: 'address' type: #usqInt>
	<var: 'instruction' type: #'AbstractInstruction *'>
	<inline: true>
	objectMemory longAt: address put: literal
]

{ #category : #'compile abstract instructions' }
OutOfLineLiteralsManager >> uniqueLiteral: literal forInstruction: anInstruction [
	<var: #anInstruction type: #'AbstractInstruction *'>
	<returnTypeC: #'AbstractInstruction *'>
	<inline: true>
	self assert: anInstruction usesOutOfLineLiteral.
	anInstruction dependent: (self allocateLiteral: literal).
	^anInstruction
]
