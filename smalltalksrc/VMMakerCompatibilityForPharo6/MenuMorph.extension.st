Extension { #name : #MenuMorph }

{ #category : #'*VMMakerCompatibilityForPharo6-construction' }
MenuMorph >> add: aString action: aSymbolOrValuable [ 
	"Append a menu item with the given label. If the item is selected, it will send the given selector to the default target object."
	"Details: Note that the menu item added captures the default target object at the time the item is added; the default target can later be changed before added additional items without affecting the targets of previously added entries. The model is that each entry is like a button that knows everything it needs to perform its action."
	aSymbolOrValuable isSymbol
		ifTrue:
			[ self
				add: aString
				target: defaultTarget
				selector: aSymbolOrValuable
				argumentList: Array empty ]
		ifFalse:
			[ self
				add: aString
				target: aSymbolOrValuable
				selector: #value
				argumentList: Array empty ]
]

{ #category : #'*VMMakerCompatibilityForPharo6-construction' }
MenuMorph >> add: aString target: aTarget action: aSymbol [ 
	self
		add: aString
		target: aTarget
		selector: aSymbol
		argumentList: Array empty
]
