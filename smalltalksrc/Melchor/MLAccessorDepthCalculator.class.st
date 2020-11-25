Class {
	#name : #MLAccessorDepthCalculator,
	#superclass : #Object,
	#instVars : [
		'codeGenerator'
	],
	#category : #Melchor
}

{ #category : #'as yet unclassified' }
MLAccessorDepthCalculator class >> forCodeGenerator: aCodeGenerator [

	^ self new
		codeGenerator: aCodeGenerator;
		yourself
]

{ #category : #'spur primitive compilation' }
MLAccessorDepthCalculator >> accessorChainsForMethod: method interpreterClass: interpreterClass [
	"Answer a set of access paths from arguments through objects, in the method, assuming
	 it is a primitive. This is in support of Spur's lazy become.  A primitive may fail because it
	 may encounter a forwarder.  The primitive failure code needs to know to what depth it
	 must follow arguments to follow forwarders and, if any are found and followed, retry the
	 primitive. This method determines that depth. It starts by collecting references to the
	 stack and then follows these through assignments to variables and use of accessor
	 methods such as fetchPointer:ofObject:. For example
		| obj field  |
		obj := self stackTop.
		field := objectMemory fetchPointer: 1 ofObject: obj.
		self storePointer: 1 ofObject: field withValue: (self stackValue: 1)
	has depth 2, since field is accessed, and field is an element of obj."

	| accessors assignments roots chains extendedChains extended lastPass |
	self accessorsAndAssignmentsForMethod: method
		actuals: (self actualsForMethod: method)
		depth: 0
		interpreterClass: interpreterClass
		into: [:theRoots :theAccessors :theAssignments|
			roots := theRoots.
			accessors := theAccessors.
			assignments := theAssignments].
	"Compute the transitive closure of assignments of accessor sends or variables to variables from the roots.
	 Start from the stack accesses (the roots).
	 On the last pass look only for accessors of the targets of the tip assignments."
	chains := OrderedCollection new.
	roots do: [:root| chains addAll: (assignments
									select: [:assignment| assignment expression = root]
									thenCollect: [:assignment| OrderedCollection with: assignment])].
	lastPass := false.
	[extended := false.
	 extendedChains := OrderedCollection new: chains size * 2.
	 chains do:
		[:chain| | tip refs accessorRefs variableRefs |
		tip := chain last variable.
		refs := accessors select: [:send| send args anySatisfy: [:arg| tip isSameAs: arg]].
		lastPass ifFalse:
			[accessorRefs := refs collect: [:send|
											assignments
												detect: [:assignment|
														assignment expression = send
														and: [(chain includes: assignment) not]]
												ifNone: []]
									thenSelect: [:assignmentOrNil| assignmentOrNil notNil].
			 variableRefs := assignments select:
								[:assignment|
								 (tip isSameAs: assignment expression)
								 and: [(tip isSameAs: assignment variable) not
								 and: [(chain includes: assignment) not]]].
			 refs := (Set withAll: accessorRefs) addAll: variableRefs; yourself].
		refs isEmpty
			ifTrue:
				[extendedChains add: chain]
			ifFalse:
				[lastPass ifFalse: [extended := true].
				 self assert: (refs noneSatisfy: [:assignment| chain includes: assignment]).
				 extendedChains addAll: (refs collect: [:assignment| chain, {assignment}])]].
	 extended or: [lastPass not]] whileTrue:
		[chains := extendedChains.
		 extended ifFalse: [lastPass := true]].
	^chains
]

{ #category : #'spur primitive compilation' }
MLAccessorDepthCalculator >> accessorDepthDeterminationFollowsSelfSends [
	^false
]

{ #category : #'spur primitive compilation' }
MLAccessorDepthCalculator >> accessorDepthForChain: chain [ "OrderedCollection"
	"Answer the actual number of accessors in the access chain, filtering out assignments of variables to variables."
	| accessorDepth |
	accessorDepth := 0.
	chain do:
		[:node|
		 ((node isAssignment and: [node expression isVariable])
		  or: [node isSend and: [codeGenerator vmmakerConfiguration baseObjectMemoryManagerClass isSameLevelObjectAccessor: node selector]]) ifFalse:
			[accessorDepth := accessorDepth + 1]].
	^accessorDepth
]

{ #category : #'spur primitive compilation' }
MLAccessorDepthCalculator >> accessorDepthForMethod: method [
	"Compute the depth the method traverses object structure, assuming it is a primitive.
	 This is in support of Spur's lazy become.  A primitive may fail because it may encounter
	 a forwarder.  The primitive failure code needs to know to what depth it must follow
	  arguments to follow forwarders and, if any are found and followed, retry the primitive.
	 This method determines that depth. It starts by collecting references to the stack and
	 then follows these through assignments to variables and use of accessor methods
	 such as fetchPointer:ofObject:. For example
		| obj field  |
		obj := self stackTop.
		field := objectMemory fetchPointer: 1 ofObject: obj.
		self storePointer: 1 ofObject: field withValue: (self stackValue: 1)
	has depth 2, since field is accessed, and field is an element of obj."
	codeGenerator vmClass ifNil: [ self error: 'Maybe we should have a vmClass' ].
	
	^((method definingClass includesSelector: method selector) ifTrue:
			[(method definingClass >> method selector) pragmaAt: #accessorDepth:])
		ifNil:
			[((self
					accessorChainsForMethod: method
					interpreterClass: codeGenerator vmClass)
				inject: 0
				into: [:length :chain| length max: (self accessorDepthForChain: chain)]) - 1]
		ifNotNil: [:pragma| pragma arguments first]
]

{ #category : #'spur primitive compilation' }
MLAccessorDepthCalculator >> accessorDepthForSelector: selector [
	^(selector = #initialiseModule
	   or: [codeGenerator vmmakerConfiguration interpreterPluginClass includesSelector: selector]) ifFalse:
		[(codeGenerator methodNamed: selector) ifNotNil:
			[:m| self accessorDepthForMethod: m]]
]

{ #category : #'spur primitive compilation' }
MLAccessorDepthCalculator >> accessorsAndAssignmentsForMethod: method actuals: actualParameters depth: depth interpreterClass: interpreterClass into: aTrinaryBlock [
	"Evaluate aTrinaryBlock with the root accessor sends, accessor sends and assignments in the method."
	| accessors assignments roots |
	accessors := Set new.
	assignments := Set new.
	roots := Set new.
	actualParameters with: method args do:
		[:actual :argName|
		 (actual isVariable or: [actual isSend]) ifTrue:
			[(actual isSend and: [self isStackAccessor: actual selector given: interpreterClass]) ifTrue:
				[roots add: actual].
			assignments add: (TAssignmentNode new
									setVariable: (TVariableNode new setName: argName)
									expression: actual)]].
	method parseTree nodesDo:
		[:node|
		node isSend ifTrue:
			[(self isStackAccessor: node selector given: interpreterClass) ifTrue:
				[roots add: node].
			 (self isObjectAccessor: node selector given: interpreterClass) ifTrue:
				[accessors add: node].
			 (self accessorDepthDeterminationFollowsSelfSends
			  and: [node receiver isVariable
			  and: [node receiver name = 'self'
			  and: [roots isEmpty
				or: [node args anySatisfy:
					[:arg|
					 (roots includes: arg)
					 or: [(accessors includes: arg)
					 or: [assignments anySatisfy: [:assignment| assignment variable isSameAs: arg]]]]]]]]) ifTrue:
				[self accessorsAndAssignmentsForSubMethodNamed: node selector
					actuals: node args
					depth: depth + 1
					interpreterClass: interpreterClass
					into: [:subRoots :subAccessors :subAssignments|
						(subRoots isEmpty and: [subAccessors isEmpty and: [subAssignments isEmpty]]) ifFalse:
							[roots addAll: subRoots.
							 accessors add: node.
							 accessors addAll: subAccessors.
							 assignments addAll: subAssignments]]]].
		(node isAssignment
		 and: [(node expression isSend and: [codeGenerator vmmakerConfiguration baseObjectMemoryManagerClass isTerminalObjectAccessor: node expression selector]) not
		 and: [(roots includes: node expression)
			or: [(accessors includes: node expression)
			or: [node expression isVariable and: [node expression name ~= 'nil']]]]]) ifTrue:
			[assignments add: node]].
	^aTrinaryBlock
		value: roots
		value: accessors
		value: assignments
]

{ #category : #'spur primitive compilation' }
MLAccessorDepthCalculator >> actualsForMethod: aTMethod [
	"Normal primitives have no arguments, but translated primitives do.
	 This class doesn't handle translated primitives and so smply answers an empty array.
	 Subclasses override as required."
	^#()
]

{ #category : #accessing }
MLAccessorDepthCalculator >> codeGenerator [
	^ codeGenerator
]

{ #category : #accessing }
MLAccessorDepthCalculator >> codeGenerator: anObject [
	codeGenerator := anObject
]

{ #category : #'spur primitive compilation' }
MLAccessorDepthCalculator >> isObjectAccessor: selector given: interpreterClass [
	^interpreterClass isObjectAccessor: selector
]

{ #category : #'spur primitive compilation' }
MLAccessorDepthCalculator >> isStackAccessor: selector given: interpreterClass [
	^interpreterClass isStackAccessor: selector
]
