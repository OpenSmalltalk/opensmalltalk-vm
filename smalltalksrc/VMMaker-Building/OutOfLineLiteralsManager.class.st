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
		'firstOpcodeIndex',
		'nextLiteralIndex',
		'lastDumpedLiteralIndex',
		'literals',
		'literalsSize'
	],
	#pools : [
		'CogCompilationConstants',
		'CogRTLOpcodes'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'compile abstract instructions' }
OutOfLineLiteralsManager >> allocateLiteral: aLiteral [
	"Allocate a n unsharable Literal instruction for the literal and answer it."
	<returnTypeC: #'AbstractInstruction *'>
	<inline: true>
	| litInst |
	<var: 'litInst' type: #'AbstractInstruction *'>
	nextLiteralIndex >= literalsSize ifTrue:
		[self allocateLiterals: literalsSize + 8].
	litInst := self literalInstructionAt: nextLiteralIndex.
	litInst
		opcode: Literal;
		operand0: aLiteral;
		setIsUnique;
		setLiteralOpcodeIndex: -1. "means as-yet-unassigned; see literalInstructionInRange:"
	nextLiteralIndex := nextLiteralIndex + 1.
	"Record the opcodeIndex of the first dependent instructuon (the first instruction that references an out-of-line literal)"
	firstOpcodeIndex > cogit getOpcodeIndex ifTrue:
		[firstOpcodeIndex := cogit getOpcodeIndex - 1].
	^litInst
]

{ #category : #initialization }
OutOfLineLiteralsManager >> allocateLiterals: initialNumLiterals [
	<inline: true>
	initialNumLiterals > literalsSize ifTrue:
		[self cCode:
				[literals := self re: literals alloc: initialNumLiterals * (self sizeof: CogAbstractInstruction)]
			inSmalltalk:
				[| newLiterals |
				 newLiterals := Array new: initialNumLiterals.
				 literals ifNotNil:
					[:existingLiterals| newLiterals replaceFrom: 1 to: literalsSize with: existingLiterals object startingAt: 1].
				 literals := CArrayAccessor on: newLiterals].
		 literalsSize := initialNumLiterals]
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
	anInstruction usesOutOfLineLiteral ifTrue:
		[anInstruction dependent: (self locateLiteral: literal)].
	^anInstruction
]

{ #category : #initialization }
OutOfLineLiteralsManager >> cogit: aCogit [
	<doNotGenerate>
	cogit := aCogit.
	literalsSize := 0
]

{ #category : #'compile abstract instructions' }
OutOfLineLiteralsManager >> dumpLiterals [
	"Output all pending literal instructions, making the originals dependents of the generated ones
	 so that a later pass will copy the address of each generated literl inst to its original in literals,
	 and hence allow the instruction using the literal to compute the correct address.."
	| litInst |
	<var: 'litInst' type: #'AbstractInstruction *'>
	lastDumpedLiteralIndex to: nextLiteralIndex - 1 do:
		[:i|
		litInst := self literalInstructionAt: i.
		(cogit gen: Literal operand: (litInst operands at: 0)) dependent: litInst].
	firstOpcodeIndex := cogit getOpcodeIndex.
	lastDumpedLiteralIndex := nextLiteralIndex
]

{ #category : #'compile abstract instructions' }
OutOfLineLiteralsManager >> literalInstructionAt: index [
	<cmacro: '(index) (&literals[index])'>
	^(literals at: index)
		ifNil: [literals at: index put: (CogCompilerClass for: cogit)]
		ifNotNil: [:litInst| litInst]
]

{ #category : #testing }
OutOfLineLiteralsManager >> literalInstructionInRange: litInst [
	"A literal is in range if its opcode index is within outOfLineLiteralOpcodeLimit, or if
	 its index has yet to be assigned."
	| opcodeIndex |
	opcodeIndex := litInst literalOpcodeIndex.
	^opcodeIndex asInteger < 0
	  or: [self assert cogit opcodeIndex >= opcodeIndex.
		cogit getOpcodeIndex - opcodeIndex < cogit backEnd outOfLineLiteralOpcodeLimit]
]

{ #category : #'compile abstract instructions' }
OutOfLineLiteralsManager >> locateLiteral: aLiteral [
	"Search for a Literal instruction that is in-range and answer it.  Otherwise
	 allocate a new Literal instruction for the literal and answer it."
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
	litInst
		opcode: Literal;
		operand0: aLiteral;
		setLiteralOpcodeIndex: -1. "means as-yet-unassigned; see literalInstructionInRange:"
	nextLiteralIndex := nextLiteralIndex + 1.
	"Record the opcodeIndex of the first dependent instructuon (the first instruction that references an out-of-line literal)"
	firstOpcodeIndex > cogit getOpcodeIndex ifTrue:
		[firstOpcodeIndex := cogit getOpcodeIndex - 1].
	^litInst
]

{ #category : #testing }
OutOfLineLiteralsManager >> mustDumpLiterals: opcodeIndex [
	<inline: true>
	^cogit getOpcodeIndex >= firstOpcodeIndex
	  and: [cogit getOpcodeIndex - firstOpcodeIndex >= cogit backEnd outOfLineLiteralOpcodeLimit]
]

{ #category : #initialization }
OutOfLineLiteralsManager >> resetLiterals: numLiteralsHint [
	<inline: true>
	self cCode:
			[self me: literals ms: 0 et: literalsSize * (self sizeof: CogAbstractInstruction)]
		inSmalltalk:
			[0 to: literalsSize - 1 do: [:i| literals at: i put: nil]].
	firstOpcodeIndex := 1 << 16. "an impossibly high value"
	nextLiteralIndex := lastDumpedLiteralIndex := 0
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
