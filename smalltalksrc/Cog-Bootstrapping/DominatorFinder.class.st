"
A DominatorFinder is an InstructionStream that finds the dominators of bytecodes.  Specifically it aims to find the dominating conditional branches for join points.  This is part of the register allocation problem, to know the common height of the stack at a join point.  Only items above the common height need to be merged.

I believe finding dominators in bytecode can be done with a simple scan using an FSM, e.g. in scanMethod.  This class is part of an experiment to find out if I'm right.

I observe that
- the first conditional branch that branches to a target that is preceded by an unconditional branch dominates the target of the unconditional branch
- if no conditional branch that branches to a target, branches to a target preceded by an unconditional branch (i.e. all are preceded by returns) then the first conditional branch dominates the target
- a conditional branch that branches to a target preceded by a backward branch dominates its target (loops)

Instance Variables
	cameFroms:			<Array>
	dominators:			<Dictionary>
	encoderClass:			<BytecodeEncoder>
	previousInstruction:	<Symbol>
	thisInstruction:			<Symbol>
	thisPC:					<Integer>

cameFroms
	- the pcs of dominating conditional branches

dominators
	- dictionary of dominating pc to dominated pc

encoderClass
	- the encoderClass for the current method

previousInstruction
	- the selector of the Message for the previous bytecode during the scan

thisInstruction
	- the selector of the Message for the current bytecode during the scan

thisPC
	- the pc for the current bytecode during the scan

"
Class {
	#name : #DominatorFinder,
	#superclass : #InstructionStream,
	#instVars : [
		'cameFroms',
		'dominators',
		'encoderClass',
		'thisInstruction',
		'previousInstruction',
		'jumpTarget',
		'thisPC'
	],
	#classVars : [
		'ReturnSelectors'
	],
	#category : #'Cog-Explorations'
}

{ #category : #exploration }
DominatorFinder class >> dominatorTupleForMethod: aCompiledMethod [
	"Answer a tuple of
		dominating optimized nodes, (inlined if's that are found by DominatorFinder)
		anomalous optimized nodes, (inlined if's that are not found by DominatorFinder)
		dominated nodes, (inlined if's nested within other inlined if's that occur at teh end of a basic block and hence jump to the same oplacfe as their parent)
		dominator pcs (the dominatopr pcs found by the DominatorFinder)
	 for aCompiledMethod"
	| mn dominators offenders dominatorPCs dominated |
	mn := CompiledMethod
			noCheckSetPreferredBytecodeSetTo: aCompiledMethod encoderClass
			while:
				[[:c :s| c compile:(c sourceCodeAt: s)
					environment: c environment
					notifying: nil
					trailer: aCompiledMethod trailer 
					ifFail: [nil]] value: aCompiledMethod methodClass value: aCompiledMethod selector].
	dominatorPCs := (self on: aCompiledMethod) dominators.
	dominated := Set new. "The last statement of an inlined if cannot dominate the join of its enclosing if"
	mn node nodesDo:
		[:n| | lastStatement |
		(n isMessage and: [n isOptimizedConditional]) ifTrue:
			[lastStatement := n lastBlockOfOptimizedConditional statements last.
			(lastStatement isMessage and: [lastStatement isOptimizedConditional]) ifTrue:
				[dominated add: lastStatement]]].
	dominators := OrderedCollection new.
	offenders := OrderedCollection new.
	mn node nodesDo:
		[:n|
		(n isMessage and: [n isOptimized and: [n isSingleReturningIf not and: [(dominated includes: n) not]]]) ifTrue:
			[((dominatorPCs at: n pc ifAbsent: nil)
				ifNil: [offenders]
				ifNotNil: [dominators]) addLast: n]].
	^{ dominators. offenders. dominated. dominatorPCs }
]

{ #category : #'class initialization' }
DominatorFinder class >> initialize [
	"self initialize"
	ReturnSelectors := ((self systemNavigation allCallsOn: #return:from: localTo: Context) collect: [:mr| mr selector]) as: IdentitySet.
]

{ #category : #'message handling' }
DominatorFinder >> doesNotUnderstand: aMessage [
	self recordThisInstruction: aMessage selector
]

{ #category : #accessing }
DominatorFinder >> dominators [
	"Scan to find the dominating conditional branches."
	| end |
	end := self method endPC.
	[pc <= end] whileTrue:
		[self interpretNextInstructionFor: self].
	^dominators
]

{ #category : #decoding }
DominatorFinder >> interpretNextInstructionFor: client [
	| result |
	(cameFroms at: pc) ifNotNil:
		[:cameFromPC|
		"the first conditional branch that branches to a target that is preceded by an unconditional branch dominates the target of the unconditional branch"
		previousInstruction == #jump:
			ifTrue:
		 		[(jumpTarget >= pc
				  and: [(cameFroms at: jumpTarget) isNil]) ifTrue:
					[self assert: (dominators includesKey: cameFromPC) not.
					 dominators at: cameFromPC put: jumpTarget]]
			ifFalse:
				"the first conditional branch that branches to a target not preceded by an unconditional branch dominates the target of the conditional branch"
				[(dominators at: cameFromPC ifAbsent: nil) ifNil:
					[dominators at: cameFromPC put: pc]]].
	thisPC := pc.
	result := encoderClass interpretNextInstructionFor: client in: self.
	previousInstruction := thisInstruction
]

{ #category : #private }
DominatorFinder >> isReturn: aMessageSelector [
	^ReturnSelectors includes: aMessageSelector
]

{ #category : #'instruction decoding' }
DominatorFinder >> jump: distance [
	jumpTarget := pc + distance.
	self recordThisInstruction: #jump:
]

{ #category : #'instruction decoding' }
DominatorFinder >> jump: distance if: condition [
	| target |
	target := pc + distance.
	(cameFroms at: target)
		ifNil: [cameFroms at: target put: thisPC]
		ifNotNil: [:cameFromPC| self assert: cameFromPC < thisPC].
	self recordThisInstruction: #jump:if:
]

{ #category : #private }
DominatorFinder >> method: method pc: startpc [
	super method: method pc: startpc.
	cameFroms := Array new: method endPC.
	encoderClass := method encoderClass.
	dominators := Dictionary new
]

{ #category : #private }
DominatorFinder >> recordThisInstruction: aSelector [
	thisInstruction := aSelector
]
