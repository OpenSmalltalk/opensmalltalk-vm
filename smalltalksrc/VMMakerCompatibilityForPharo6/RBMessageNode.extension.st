Extension { #name : #RBMessageNode }

{ #category : #'*VMMakerCompatibilityForPharo6-C translation' }
RBMessageNode >> asTranslatorNodeIn: aTMethod [
	"Answer a TParseNode subclass equivalent of me"
	"selector is sometimes a Symbol, sometimes a SelectorNode!
	 On top of this, numArgs is needed due to the (truly grody) use of
	 arguments as a place to store the extra expressions needed to generate
	 code for in-line to:by:do:, etc.  see below, where it is used.

	 Expand super nodes in place. Elide sends of halt so that halts can be
	 sprinkled through the simulator but will be eliminated from the generated C."
	| usedSelector rcvrOrNil args |
	usedSelector := selector.
	rcvrOrNil := receiver ifNotNil: [receiver asTranslatorNodeIn: aTMethod].
	(rcvrOrNil notNil
	and: [rcvrOrNil isVariable
	and: [rcvrOrNil name = 'super']]) ifTrue:
		[^aTMethod superExpansionNodeFor: usedSelector args: arguments].
	usedSelector == #halt ifTrue: [^rcvrOrNil].
	(usedSelector == #cCode:inSmalltalk: "extracting here rather than in translation allows inlining in the block."
	  or: [usedSelector == #cCode:]) ifTrue:
		[arguments first isBlockNode ifTrue:
			[| block |
			 ^(block := arguments first asTranslatorNodeIn: aTMethod) statements size = 1
				ifTrue: [block statements first]
				ifFalse: [block]].
		 (arguments first isLiteralNode
		 and: [arguments first value isString
		 and: [arguments first value isEmpty]]) ifTrue:
			[^arguments first asTranslatorNodeIn: aTMethod]].
	args := arguments collect: [:arg| arg asTranslatorNodeIn: aTMethod].
	
	(usedSelector == #to:do:) ifTrue: [ | block |
		usedSelector := #to:by:do:.
		block := args second.
		args := OrderedCollection
			with: args first
			with: (TConstantNode new setValue: 1)
			with: args second
			with: (TAssignmentNode new
						setVariable: (arguments first asTranslatorNodeIn: aTMethod)
						expression: (TConstantNode new setValue: 1);
						yourself)
			with: (TSendNode new
				setSelector: #<=
				receiver: (TVariableNode new setName: block args first)
				arguments: { receiver asTranslatorNodeIn: aTMethod })
			with: (TAssignmentNode new
						setVariable: (TVariableNode new setName: block args first)
						expression: (TSendNode new
							setSelector: #+
							receiver: (TVariableNode new setName: block args first)
							arguments: { TConstantNode new setValue: 1 });
							yourself)
	].
	
	"If in the form of ifNil: [ :obj | ], replace that by an assignment and an ifFalse"
	((usedSelector == #ifNotNil:) and: [ args first args notEmpty ]) ifTrue: [
		^ TStmtListNode new
			setArguments: #();
			setStatements: {
				TAssignmentNode new
					setVariable: (TVariableNode new setName: args first args first)
					expression: rcvrOrNil.
	
				TSendNode new
					setSelector: #ifFalse:
					receiver: (TSendNode new
						setSelector: #==
						receiver: (TVariableNode new setName: args first args first)
						arguments: {(TVariableNode new setName: 'nil')};
						yourself)
					arguments: {args first}
			};
			yourself ].
	
	(#(#ifNotNil:ifNil: #ifNil:ifNotNil:) includes: usedSelector) ifTrue: [ | comparand expression blockWithPossibleArgument |
		"We turn it always to an ifTrueIfFalse"
		usedSelector = #ifNotNil:ifNil:
			ifTrue: [ args := args reversed ].
		blockWithPossibleArgument := args second.
		expression := rcvrOrNil.
		comparand := blockWithPossibleArgument args
			ifEmpty: [ expression ]
			ifNotEmpty: [ (TVariableNode new setName: blockWithPossibleArgument args first) ].
		
		usedSelector := #ifTrue:ifFalse:.
		rcvrOrNil := TSendNode new
			setSelector: #==
			receiver: comparand
			arguments: { TVariableNode new setName: 'nil' }.

		"If there is a variable we should epand the message as a statement"
		blockWithPossibleArgument args notEmpty ifTrue: [ 
			^ TStmtListNode new
				setArguments: #();
				setStatements: {
					TAssignmentNode new
						setVariable: (TVariableNode new setName: blockWithPossibleArgument args first)
						expression: expression.
		
					TSendNode new
						setSelector: usedSelector
						receiver: rcvrOrNil
						arguments: args
				};
				yourself
		 ] ].
	
	(usedSelector == #ifNil:ifNotNil:) ifTrue: [
		usedSelector := #ifTrue:ifFalse:.
		rcvrOrNil := TSendNode new
			setSelector: #==
			receiver: rcvrOrNil
			arguments: { TVariableNode new setName: 'nil' } ].
	
	(usedSelector == #ifTrue:ifFalse: and: [arguments first statements isEmpty]) ifTrue:
		[usedSelector := #ifFalse:. args := {args last}].
	(usedSelector == #ifTrue:ifFalse: and: [arguments last statements isEmpty]) ifTrue:
		[usedSelector := #ifTrue:. args := {args first}].
	(usedSelector == #ifFalse:ifTrue: and: [arguments first statements isEmpty]) ifTrue:
		[usedSelector := #ifTrue:. args := {args last}].
	(usedSelector == #ifFalse:ifTrue: and: [arguments last statements isEmpty]) ifTrue:
		[usedSelector := #ifTrue:. args := {args first}].
	
	((usedSelector == #ifFalse: or: [usedSelector == #or:])
	 and: [arguments size = 2 and: [(arguments at: 2) notNil]]) ifTrue:
		["Restore argument block that got moved by transformOr: or transformIfFalse:"
		 args := {(arguments at: 2) asTranslatorNodeIn: aTMethod}].
	(args size > usedSelector numArgs and: [usedSelector ~~ #to:by:do:]) ifTrue: "to:by:do: has iLimiT hidden in last arg"
		["prune the extra blocks left by ifTrue:, ifFalse:, and: & or:"
		 self assert: args size - usedSelector numArgs = 1.
		 self assert: (args last isStmtList
					  and: [args last statements size = 1
					  and: [(args last statements first isVariable
							or: [args last statements first isConstant])
					  and: [#('nil' true false) includes: args last statements first nameOrValue]]]).
		 args := args first: usedSelector numArgs].
	
	((CCodeGenerator isVarargsSelector: usedSelector)
	 and: [args last isCollection
	 and: [args last isSequenceable]]) ifTrue:
		[args := args allButLast, args last].
	^TSendNode new
		setSelector: usedSelector
		receiver: rcvrOrNil
		arguments: args
]
