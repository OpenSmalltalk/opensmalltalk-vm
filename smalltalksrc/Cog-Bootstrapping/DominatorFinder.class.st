"
A DominatorFinder is an InstructionStream that finds the dominators of bytecodes.  Specifically it aims to find the dominating conditional branches for join points.  This is part of the register allocation problem, to know the common height of the stack at a join point.  Only items above the common height need to be merged.

I believe finding dominators in bytecode can be done with a simple scan using an FSM, e.g. in scanMethod.  This class is part of an experiment to find out if I'm right.

I observe that
- the first conditional branch that branches to a target that is preceded by an unconditional branch dominates the target of the unconditional branch
- if no conditional branch that branches to a target, branches to a target preceded by an unconditional branch (i.e. all are preceded by returns) then the first conditional branch dominates the target
- a conditional branch that branches to a target preceded by a backward branch dominates its target (loops)

This DominatorFinder attempts to find conditional branches that dominate join points, while filtering out conditional branches that dominate non-joins (i.e. those following single returning ifs and those that jump to the end of loops).

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
DominatorFinder class >> containsAssignedOptimizedConditionalExpressionValue: aCompiledMethod [
	"Answer if aCompiledMethod contains an optimized conditional expression which is assigned."
	[:dominatingNodes
	 :anomalousNodes
	 :dominatedNodes
	 :dominatorMap
	 :newMethod| | encoderClass |
	^dominatorMap notEmpty
	  and: [(encoderClass := newMethod encoderClass) supportsFullBlocks
			ifFalse: "simple; can look at the single method object"
				[| sps |
				 sps := (StackDepthFinder on: newMethod) stackPointers.
				 dominatorMap associations anySatisfy:
					[:a| "Filter out expr ifTrue: [...] ifFalse: [...].  Both arms share a single pop"
					((encoderClass isStorePopAt: a value in: newMethod)
					or: [encoderClass isStoreAt: a value in: newMethod])
					and: [(sps at: a key) <= (sps at: a value)]]]
			ifTrue: "complex; have to locate the relevant sub-method"
				[| asps |
				 asps := (StackDepthFinder on: newMethod) allStackPointers.
				 dominatorMap associations anySatisfy:
					[:a| | dpc sps m |
					a key isInteger
						ifTrue:
							[dpc := a key.
							 m := newMethod]
						ifFalse:
							[dpc := a key value.
							 m := a key key].
						sps := asps at: m.
					"Filter out expr ifTrue: [...] ifFalse: [...].  Both arms share a single pop"
					((encoderClass isStorePopAt: a value in: m)
					or: [encoderClass isStoreAt: a value in: m])
					and: [(sps at: dpc) <= (sps at: a value)]]]]]
		valueWithArguments: (self dominatorTupleForMethod: aCompiledMethod)
]

{ #category : #exploration }
DominatorFinder class >> containsOptimizedConditionalExpressionValue: aCompiledMethod [
	"Answer if aCompiledMethod contains an optimized conditional expression which
	 is used as either a message receiver or parameter, or a value to store or return."
	[:dominatingNodes
	 :anomalousNodes
	 :dominatedNodes
	 :dominatorMap
	 :newMethod| | encoderClass |
	^dominatorMap notEmpty
	  and: [(encoderClass := newMethod encoderClass) supportsFullBlocks
			ifFalse: "simple; can look at the single method object"
				[| sps |
				 sps := (StackDepthFinder on: newMethod) stackPointers.
				 dominatorMap associations anySatisfy:
					[:a| "Filter out expr ifTrue: [...] ifFalse: [...].  Both arms share a single pop"
					(encoderClass isJustPopAt: a value in: newMethod) not
					and: [(sps at: a key) <= (sps at: a value)]]]
			ifTrue: "complex; have to locate the relevant sub-method"
				[| asps |
				 asps := (StackDepthFinder on: newMethod) allStackPointers.
				 dominatorMap associations anySatisfy:
					[:a| | dpc sps m |
					a key isInteger
						ifTrue:
							[dpc := a key.
							 m := newMethod]
						ifFalse:
							[dpc := a key value.
							 m := a key key].
						sps := asps at: m.
					"Filter out expr ifTrue: [...] ifFalse: [...].  Both arms share a single pop"
					(encoderClass isJustPopAt: a value in: m) not
					and: [(sps at: dpc) <= (sps at: a value)]]]]]
		valueWithArguments: (self dominatorTupleForMethod: aCompiledMethod)
]

{ #category : #exploration }
DominatorFinder class >> containsOptimizedConditionalExpressionValueOtherThanForBranching: aCompiledMethod [
	"Answer if aCompiledMethod contains an optimized conditional expression which
	 is used as either a message receiver or parameter, or a value to store or return,
	 but not as a receiver to be branched upon."
	[:dominatingNodes
	 :anomalousNodes
	 :dominatedNodes
	 :dominatorMap
	 :newMethod| | encoderClass |
	^dominatorMap notEmpty
	  and: [(encoderClass := newMethod encoderClass) supportsFullBlocks
			ifFalse: "simple; can look at the single method object"
				[| sps |
				 sps := (StackDepthFinder on: newMethod) stackPointers.
				 dominatorMap associations anySatisfy:
					[:a| "Filter out expr ifTrue: [...] ifFalse: [...].  Both arms share a single pop"
					(encoderClass isJustPopAt: a value in: newMethod) not
					and: [(encoderClass isBranchAt: a value in: newMethod) not
					and: [(sps at: a key) <= (sps at: a value)]]]]
			ifTrue: "complex; have to locate the relevant sub-method"
				[| asps |
				 asps := (StackDepthFinder on: newMethod) allStackPointers.
				 dominatorMap associations anySatisfy:
					[:a| | dpc sps m |
					a key isInteger
						ifTrue:
							[dpc := a key.
							 m := newMethod]
						ifFalse:
							[dpc := a key value.
							 m := a key key].
						sps := asps at: m.
					"Filter out expr ifTrue: [...] ifFalse: [...].  Both arms share a single pop"
					(encoderClass isJustPopAt: a value in: m) not
					and: [(encoderClass isBranchAt: a value in: m) not
					and: [(sps at: dpc) <= (sps at: a value)]]]]]]
		valueWithArguments: (self dominatorTupleForMethod: aCompiledMethod)
]

{ #category : #exploration }
DominatorFinder class >> dominatorTupleForMethod: aCompiledMethod [
	"Answer a tuple of
		dominating optimized nodes, (inlined if's that are found by DominatorFinder)
		anomalous optimized nodes, (inlined if's that are not found by DominatorFinder)
		dominated nodes, (inlined if's nested within other inlined if's that occur at the end of a basic block and hence jump to the same place as their parent)
		dominator pcs (the dominator pcs found by the DominatorFinder)
		recompiled method
	 for aCompiledMethod.  It is expected that the anomaloius nodes should be empty."
	| mn optimizedNodes
	  dominators offenders dominated dominatorPCs |
	aCompiledMethod isQuick ifTrue:
		[^#(#() #() #() #() #())].
	mn := CompiledMethod
			noCheckSetPreferredBytecodeSetTo: aCompiledMethod encoderClass
			while:
				[[:c :s|
				  [c compile:(c sourceCodeAt: s)
					environment: c environment
					notifying: nil
					trailer: aCompiledMethod trailer 
					ifFail: [nil]]
					on: SyntaxErrorNotification
					do: [^#(#() #() #() #() #())]]
						value: aCompiledMethod methodClass
						value: aCompiledMethod selector].
	"mn method ~= aCompiledMethod ifTrue:
		[Transcript cr; show: 'warning: recompilation of ', aCompiledMethod reference, ' generated different code'.
		 ^#(#() #() #() #() #())]."
	dominatorPCs := (self on: mn method) dominators.
	dominated := IdentitySet new. "The last statement of an inlined if cannot dominate the join of its enclosing if"
	optimizedNodes := OrderedCollection new. "Avoid double traversal"
	mn node nodesDo:
		[:n| | lastStatement |
		(n isMessage and: [n isOptimized]) ifTrue:
			[optimizedNodes addLast: n.
			 n isOptimizedConditional ifTrue:
				[lastStatement := n lastBlockOfOptimizedConditional statements last.
				(lastStatement isMessage and: [lastStatement isOptimizedConditional]) ifTrue:
					[dominated add: lastStatement]]]].
	dominators := OrderedCollection new: optimizedNodes size.
	offenders := OrderedCollection new: optimizedNodes size.
	optimizedNodes do:
		[:n|
		(n isOptimizedLoop not				"Loop CBs do dominate, but their target is not a join point"
		 and: [n isSingleReturningIf not		"ifTrue: [^foo] CBs do dominate but their target is not a join point"
		 and: [n isEmptyIf not				"ifTrue: [] generates no code"
		 and: [n pc ~= 0					"caseOf: nodes get assigned a pc of 0; go figure..."
		 and: [(dominated includes: n) not]]]]) ifTrue:
			[((dominatorPCs at: n pc ifAbsent: nil)
				ifNil: [offenders]
				ifNotNil: [dominators]) addLast: n]].
	^{ dominators. offenders. dominated. dominatorPCs. mn method }
]

{ #category : #exploration }
DominatorFinder class >> exampleMethod [
	"(StackDepthFinder on: DominatorFinder class >> #exampleMethod) stackPointers.
	 DominatorFinder dominatorTupleForMethod: DominatorFinder class >> #exampleMethod.
	 (DominatorFinder class >> #exampleMethod) detailedSymbolic"
	self isCollection
		ifTrue: [self at: 1]
		ifFalse: [self at: 2].
	self at: (self isCollection ifTrue: [1] ifFalse: [2]) put: self
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
		"the first conditional branch that branches to a target that is preceded by an unconditional forward branch dominates the target of the unconditional branch.
		 (an unconditional backward branch indicates a loop)"
		(previousInstruction == #jump:
		 and: [jumpTarget >= pc])
			ifTrue:
		 		[(cameFroms at: jumpTarget) ifNil:
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

{ #category : #'instruction decoding' }
DominatorFinder >> pushFullClosure: aCompiledBlock numCopied: numCopied [
	self recordThisInstruction: #pushFullClosure:numCopied:;
		recurseIntoBlock: aCompiledBlock
]

{ #category : #'instruction decoding' }
DominatorFinder >> pushFullClosure: aCompiledBlock numCopied: numCopied receiverOnStack: rcvrOnStack ignoreOuterContext: ignoreOuterContext [
	self recordThisInstruction: #pushFullClosure:numCopied:receiverOnStack:ignoreOuterContext:;
		recurseIntoBlock: aCompiledBlock
]

{ #category : #private }
DominatorFinder >> recordThisInstruction: aSelector [
	thisInstruction := aSelector
]

{ #category : #private }
DominatorFinder >> recurseIntoBlock: aCompiledBlock [
	"Recurse into a full block. Map its dominating pcs appropriately to match
	 BytecodeEncoder>>nextPC's representyation for the pcs in nested full blocks."
	(self class on: aCompiledBlock) dominators keysAndValuesDo:
		[:key :value|
		 dominators
			at: (key isInteger ifTrue: [aCompiledBlock -> key] ifFalse: [key])
			put: value]
]
