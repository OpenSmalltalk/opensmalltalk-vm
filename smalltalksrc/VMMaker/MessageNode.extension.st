Extension { #name : #MessageNode }

{ #category : #'*VMMaker-C translation' }
MessageNode >> asTranslatorNodeIn: aTMethod [
	"make a CCodeGenerator equivalent of me"
	"selector is sometimes a Symbol, sometimes a SelectorNode!
	 On top of this, numArgs is needed due to the (truly grody) use of
	 arguments as a place to store the extra expressions needed to generate
	 code for in-line to:by:do:, etc.  see below, where it is used.

	 Expand super nodes in place. Elide sends of halt so that halts can be
	 sprinkled through the simulator but will be eliminated from the generated C."
	| rcvrOrNil sel args ifNotNilBlock |
	rcvrOrNil := receiver ifNotNil: [receiver asTranslatorNodeIn: aTMethod].
	(rcvrOrNil notNil
	and: [rcvrOrNil isVariable
	and: [rcvrOrNil name = 'super']]) ifTrue:
		[^aTMethod superExpansionNodeFor: selector key args: arguments].
	sel := selector isSymbol ifTrue: [selector] ifFalse: [selector key].
	sel == #halt ifTrue: [^rcvrOrNil].
	(sel == #cCode:inSmalltalk: "extracting here rather than in translation allows inlining in the block."
	  or: [sel == #cCode:]) ifTrue:
		[arguments first isBlockNode ifTrue:
			[| block |
			 ^(block := arguments first asTranslatorNodeIn: aTMethod) statements size = 1
				ifTrue: [block statements first]
				ifFalse: [block]].
		 (arguments first isLiteralNode
		 and: [arguments first key isString
		 and: [arguments first key isEmpty]]) ifTrue:
			[^arguments first asTranslatorNodeIn: aTMethod]].
	args := arguments
				select: [:arg| arg notNil]
				thenCollect: [:arg| arg asTranslatorNodeIn: aTMethod].
	(sel = #to:by:do: and: [arguments size = 7 and: [(arguments at: 7) notNil]]) ifTrue:
		["Restore limit expr that got moved by transformToDo:"
		 args := {(arguments at: 7) value asTranslatorNodeIn: aTMethod. 
				  args second.
				  args third. "add the limit var as a hidden extra argument; we may need it later"
				  TVariableNode new setName: arguments first key}].
	(sel == #ifTrue:ifFalse: and: [arguments first isJust: NodeNil]) ifTrue:
		[sel := #ifFalse:. args := {args last}].
	(sel == #ifTrue:ifFalse: and: [arguments last isJust: NodeNil]) ifTrue:
		[sel := #ifTrue:. args := {args first}].
	(sel == #ifFalse:ifTrue: and: [arguments first isJust: NodeNil]) ifTrue:
		[sel := #ifTrue:. args := {args last}].
	(sel == #ifFalse:ifTrue: and: [arguments last isJust: NodeNil]) ifTrue:
		[sel := #ifTrue:. args := {args first}].
	((sel == #ifFalse: or: [sel == #or:])
	 and: [arguments size = 2 and: [(arguments at: 2) notNil]]) ifTrue:
		["Restore argument block that got moved by transformOr: or transformIfFalse:"
		 args := {(arguments at: 2) asTranslatorNodeIn: aTMethod}].
	(args size > sel numArgs and: [sel ~~ #to:by:do:]) ifTrue: "to:by:do: has iLimiT hidden in last arg"
		["prune the extra blocks left by ifTrue:, ifFalse:, and: & or:"
		 self assert: args size - sel numArgs = 1.
		 self assert: (args last isStmtList
					  and: [args last statements size = 1
					  and: [(args last statements first isVariable
							or: [args last statements first isConstant])
					  and: [#('nil' true false) includes: args last statements first nameOrValue]]]).
		 args := args first: sel numArgs].
	"For the benefit of later passes, e.g. value: inlining,
	 transform e ifNotNil: [:v| ...] into  v := e. v ifNotNil: [...],
	 which in fact means transforming (v := e) ifTrue: [:v|...] into v := e. v ifTrue: [...]."
	((sel == #ifTrue: or: [sel == #ifFalse: or: [sel == #ifTrue:ifFalse: or: [sel == #ifFalse:ifTrue:]]])
	 and: [receiver notNil
	 and: [receiver isAssignmentEqualsEqualsNil
	 and: [(ifNotNilBlock := args detect: [:arg| arg isStmtList and: [arg args size = 1]] ifNone: []) notNil]]]) ifTrue:
		[ifNotNilBlock setArguments: #().
		 ^TStmtListNode new
			setArguments: #()
			statements:
				{	receiver receiver asTranslatorNodeIn: aTMethod.
					TSendNode new
						setSelector: sel
						receiver: (TSendNode new
									setSelector: #==
									receiver: (receiver receiver variable asTranslatorNodeIn: aTMethod)
									arguments: {receiver arguments first asTranslatorNodeIn: aTMethod})
						arguments: args }].
	((CCodeGenerator isVarargsSelector: sel)
	 and: [args last isCollection
	 and: [args last isSequenceable]]) ifTrue:
		[args := args allButLast, args last].
	^TSendNode new
		setSelector: sel
		receiver: rcvrOrNil
		arguments: args
]

{ #category : #'*VMMaker-C translation' }
MessageNode >> isAssignmentEqualsEqualsNil [
	"Answer if the receiver if of the form (v := e) == nil, which underlies e ifNotNil: [:v|...]"
	^#== == (selector isSymbol ifTrue: [selector] ifFalse: [selector key])
	  and: [receiver notNil
	  and: [receiver isAssignmentNode
	  and: [(arguments first isJust: NodeNil)
		    or: [arguments first isVariableNode
			    and: [arguments first key = 'nil']]]]]
]
