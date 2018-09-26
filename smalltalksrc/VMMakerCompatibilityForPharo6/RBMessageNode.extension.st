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
	| rcvrOrNil args ifNotNilBlock |
	rcvrOrNil := receiver ifNotNil: [receiver asTranslatorNodeIn: aTMethod].
	(rcvrOrNil notNil
	and: [rcvrOrNil isVariable
	and: [rcvrOrNil name = 'super']]) ifTrue:
		[^aTMethod superExpansionNodeFor: selector args: arguments].
	selector == #halt ifTrue: [^rcvrOrNil].
	(selector == #cCode:inSmalltalk: "extracting here rather than in translation allows inlining in the block."
	  or: [selector == #cCode:]) ifTrue:
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
	(selector == #ifTrue:ifFalse: and: [arguments first statements isEmpty]) ifTrue:
		[selector := #ifFalse:. args := {args last}].
	(selector == #ifTrue:ifFalse: and: [arguments last statements isEmpty]) ifTrue:
		[selector := #ifTrue:. args := {args first}].
	(selector == #ifFalse:ifTrue: and: [arguments first statements isEmpty]) ifTrue:
		[selector := #ifTrue:. args := {args last}].
	(selector == #ifFalse:ifTrue: and: [arguments last statements isEmpty]) ifTrue:
		[selector := #ifTrue:. args := {args first}].
	((CCodeGenerator isVarargsSelector: selector)
	 and: [args last isCollection
	 and: [args last isSequenceable]]) ifTrue:
		[args := args allButLast, args last].
	^TSendNode new
		setSelector: selector
		receiver: rcvrOrNil
		arguments: args
]
