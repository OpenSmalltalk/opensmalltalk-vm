Extension { #name : #MessageNode }

{ #category : #'*VMMaker-C translation' }
MessageNode >> asTranslatorNodeIn: aTMethod [
	"make a CCodeGenerator equivalent of me"
	"selector is sometimes a Symbol, sometimes a SelectorNode!
	On top of this, numArgs is needed due to the (truly grody) use of
	arguments as a place to store the extra expressions needed to generate
	code for in-line to:by:do:, etc.  see below, where it is used."
	| sel args |
	sel := (selector isSymbol) ifTrue: [selector] ifFalse: [selector key].
	args := (1 to: sel numArgs) collect:
			[:i | (arguments at: i) asTranslatorNodeIn: aTMethod].
	(sel = #to:by:do: and: [arguments size = 7 and: [(arguments at: 7) notNil]])
		ifTrue: ["Restore limit expr that got moved by transformToDo:"
				args at: 1 put: ((arguments at: 7) value asTranslatorNodeIn: aTMethod)].
	(sel = #or: and: [arguments size = 2 and: [(arguments at: 2) notNil]])
		ifTrue: ["Restore argument block that got moved by transformOr:"
				args at: 1 put: ((arguments at: 2) asTranslatorNodeIn: aTMethod)].
	(sel = #ifFalse: and: [arguments size = 2 and: [(arguments at: 2) notNil]])
		ifTrue: ["Restore argument block that got moved by transformIfFalse:"
				args at: 1 put: ((arguments at: 2) asTranslatorNodeIn: aTMethod)].
	^ TSendNode new
		setSelector: sel
		receiver: (receiver ~~ nil ifTrue: [receiver asTranslatorNodeIn: aTMethod])
		arguments: args
]
