Extension { #name : #RBMethodNode }

{ #category : #'*VMMakerCompatibilityForPharo6-C translation' }
RBMethodNode >> asTranslationMethodOfClass: aTMethodClass [
 	"Answer a TMethod (or subclass) derived from the receiver."
	^aTMethodClass new
		setSelector: selector
		definingClass: scope instanceScope outerScope class
		args: arguments
		locals: ((self allDefinedVariables copyWithoutAll: arguments) collect: [:string| string -> string])
		block: body
		primitive: ((pragmas ifNotNil:
							[pragmas detect: [:pragmaNode| pragmaNode selector beginsWith: #primitve:] ifNone: []])
						ifNil: [0]
						ifNotNil: [:pragmaNode| pragmaNode arguments first value])
		properties: (properties ifNil: [AdditionalMethodState new])
		comment: self missingCommentNeededForCTranslation
]

{ #category : #'*VMMakerCompatibilityForPharo6-results' }
RBMethodNode >> printSchematicTempsFor: blockNode in: blockScope on: stream [
	| startPos vectorStartPos |
	startPos := stream position.
	blockNode arguments do:
		[:n|
		 stream position > startPos ifTrue: [stream space].
		 stream nextPutAll: n name].
	blockScope isBlockScope ifTrue:
		[(blockScope copiedVars "filter out remotes, e.g. 0vector0"
				reject: [:var| var name first isDigit]) do:
			[:var|
			 stream position > startPos ifTrue: [stream space].
			 stream nextPutAll: var name]].
	(blockNode temporaries reject: [:var| (blockScope lookupVar: var name) isRemote]) do:
		[:var|
		 stream position > startPos ifTrue: [stream space].
		 stream nextPutAll: var name].
	vectorStartPos := stream position.
	(blockNode temporaries select: [:var| (blockScope lookupVar: var name) isRemote]) do:
		[:var|
		 stream position = vectorStartPos ifTrue:
			[vectorStartPos > startPos ifTrue: [stream space].
			 stream nextPut: $(].
		 stream nextPutAll: var name].
	stream position > vectorStartPos ifTrue: [stream nextPut: $)]
]

{ #category : #'*VMMakerCompatibilityForPharo6-results' }
RBMethodNode >> schematicTempNamesString [
	scope ifNil: [self generateIR].
	^String streamContents:
		[:s|
		 self printSchematicTempsFor: self in: scope on: s.
		 scope
			childrenDo:
				[:childBlockScope|
				 childBlockScope isOptimizedBlockScope ifFalse:
					[s nextPut: $[.
					 self printSchematicTempsFor: childBlockScope node in: childBlockScope on: s]]
			after:
				[:childBlockScope|
				 childBlockScope isOptimizedBlockScope ifFalse:
					[s nextPut: $]]]
			suchThat: [:childScope| childScope isBlockScope]]
		  
]
