Extension { #name : #MessageNode }

{ #category : #'*Cog-Explorations-testing' }
MessageNode >> isEmptyIf [
	| block |
	^((special between: 1 and: 2) "ifTrue:/ifFalse:"
	    or: [special between: 15 and: 16]) "ifNil:/ifNotNil:"
		and: [((block := self lastBlockOfOptimizedConditional) isJust: NodeNil)
			or: [block returns not and: [block statements size = 1 and: [block statements first isLeaf]]]]
]

{ #category : #'*Cog-Explorations-testing' }
MessageNode >> isOptimizedConditional [
	"Answer if the receiver represents an inlined ifTrue: et al, and: et al, or ifNil: et al."

	^special > 0
	 and: [(special between: 1 and: 6) "ifTrue:...or:"
		or: [special between: 15 and: 18]] "ifNil: ... ifNotNil:ifNil:"

	"MacroSelectors := 
		#(	ifTrue: ifFalse: ifTrue:ifFalse: ifFalse:ifTrue:
			and: or:
			whileFalse: whileTrue: whileFalse whileTrue
			to:do: to:by:do:
			caseOf: caseOf:otherwise:
			ifNil: ifNotNil:  ifNil:ifNotNil: ifNotNil:ifNil:
			repeat )"

]

{ #category : #'*Cog-Explorations-testing' }
MessageNode >> isSingleReturningIf [

	^((special between: 1 and: 2) "ifTrue:/ifFalse:"
	    or: [special between: 15 and: 16]) "ifNil:/ifNotNil:"
		and: [arguments first returns]
]

{ #category : #'*Cog-Explorations-testing' }
MessageNode >> lastBlockOfOptimizedConditional [
	"Answer the actual last block for an inlined conditional"

	^special >= 1 ifTrue:
		[special <= 2 ifTrue: [^arguments at: special].	"ifTrue: ifFalse:"
		 special <= 4 ifTrue: [^arguments last].	"ifTrue:ifFalse: ifFalse:ifTrue:"
		 special <= 6 ifTrue: [^arguments first].	"and: or:"
		 special <= 14 ifTrue: [^nil].
		 special <= 16 ifTrue: [^arguments first].	"ifNil: ifNotNil:"
		 special <= 18 ifTrue: [^arguments last]]	"ifNil:ifNotNil: ifNotNil:ifNil:"
]
