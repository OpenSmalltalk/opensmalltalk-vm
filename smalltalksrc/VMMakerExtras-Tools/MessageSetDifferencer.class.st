"
This is a variation of MessageSet that allows diffing of arbitrary definitions.  It is initialized with pairs of definitions, each pair being compared against each other.
"
Class {
	#name : #MessageSetDifferencer,
	#superclass : #Browser,
	#instVars : [
		'messageList',
		'leftSet',
		'rightSet',
		'autoSelectString'
	],
	#category : #'VMMakerExtras-Tools'
}

{ #category : #'instance creation' }
MessageSetDifferencer class >> compareClass: aClass to: bClass [
	^self compareClass: aClass to: bClass keepSame: true

	"MessageSetDifferencer compareClass: InterpreterStackPages to: CoInterpreterStackPages"
	"MessageSetTextDifferencer compareClass: InterpreterStackPages to: CoInterpreterStackPages"
]

{ #category : #'instance creation' }
MessageSetDifferencer class >> compareClass: aClass to: bClass keepSame: keepSame [
	| definitionPairSequence |
	definitionPairSequence := { { ClassReference class: aClass. ClassReference class: bClass } },
							((aClass selectors, bClass selectors) asSet asSortedCollection
								select: [:s| keepSame or: [(aClass sourceCodeAt: s ifAbsent: ['']) asString ~= (bClass sourceCodeAt: s ifAbsent: ['']) asString]]
								thenCollect:
									[:s| {
										MethodReference class: aClass selector: s. 
										MethodReference class: bClass selector: s }]).
	^self openMessageList: definitionPairSequence name: aClass name, ' <-> ', bClass name autoSelect: nil

	"MessageSetDifferencer compareClass: InterpreterStackPages to: CoInterpreterStackPages keepSame: true"
	"MessageSetTextDifferencer compareClass: ReentrantFFIPlugin to: ThreadedFFIPlugin keepSame: false"
	"MessageSetDifferencer compareClass: NewsqueakIA32ABIPlugin to: IA32ABIPlugin keepSame: false"
]

{ #category : #'instance creation' }
MessageSetDifferencer class >> definitionPairs: aSequence [
	^self new initializeDefinitionPairs: aSequence
]

{ #category : #'instance creation' }
MessageSetDifferencer class >> openMessageList: definitionPairSequence name: labelString autoSelect: autoSelectString [
	"Open a system view for a MessageSetDifferencer on definitionPairSequence. "

	| differencer |
	differencer := self definitionPairs: definitionPairSequence.
	differencer autoSelectString: autoSelectString.
	^ToolBuilder open: differencer label: labelString
]

{ #category : #contents }
MessageSetDifferencer >> aboutToStyle: aPluggableShoutMorphOrView [
	"Style if there is only one definition (none styles nothing)"
	^(leftSet selection isNil or: [rightSet selection isNil])
	   and: [aPluggableShoutMorphOrView classOrMetaClass:
				(leftSet selection
					ifNotNil: [leftSet selection isClassReference ifFalse: [leftSet selection actualClass]]
					ifNil: [rightSet selection ifNotNil:
							[rightSet selection isClassReference ifFalse: [rightSet selection actualClass]]]).
			true]
]

{ #category : #accessing }
MessageSetDifferencer >> annotation [
	"Provide a line of content for an annotation pane, representing information about
	 the method associated with the selected class and selector in the receiver."
	| left right |
	(left := leftSet annotation) = (right := rightSet annotation) ifTrue:
		[^left].
	left = '------' ifTrue:
		[^'> ', right].
	right = '------' ifTrue:
		[^left, ' <'].
	^left, ' <-> ', right
]

{ #category : #private }
MessageSetDifferencer >> autoSelectString [
	"Return the string to be highlighted when making new selections"
	^ autoSelectString
]

{ #category : #private }
MessageSetDifferencer >> autoSelectString: aString [
	"Set the string to be highlighted when making new selections"
	autoSelectString := aString
]

{ #category : #toolbuilder }
MessageSetDifferencer >> buildWith: builder [
	| windowSpec max result |
	self wantsOptionalButtons ifTrue:[max := 0.3] ifFalse:[max := 0.3].
	windowSpec := self buildWindowWith: builder specs: {
		(0@0 corner: 1@max) -> [self buildMessageListWith: builder].
		(0@max corner: 1@1) -> [self buildCodePaneWith: builder].
	}.
	result := builder build: windowSpec.
	autoSelectString ifNotNil:[self changed: #autoSelect].
	^result
]

{ #category : #'message list' }
MessageSetDifferencer >> changeDefinitions: newList [
	leftSet initializeMessageList:  (newList collect: [:ea| ea first]).
	rightSet initializeMessageList:  (newList collect: [:ea| ea last]).
	messageList := newList.
	self reformulateList;
		changed: #messageList
]

{ #category : #contents }
MessageSetDifferencer >> contents [
	"Answer the contents of the receiver"

	| left right |
	left := leftSet selection.
	right := rightSet selection.
	left ifNil:
		[right ifNil:
			[currentCompiledMethod := nil.
			 ^''].
		 ^rightSet contents].
	right ifNil:
		[^leftSet contents].
	^left isMethodReference
		ifTrue:
			[CodeDiffBuilder
				buildDisplayPatchFrom: rightSet contents
				to: leftSet contents
				inClass: (left isMethodReference ifTrue: [left actualClass])
				prettyDiffs: true]
		ifFalse:
			[CodeDiffBuilder buildDisplayPatchFrom: rightSet contents to: leftSet contents]
]

{ #category : #'initialize-release' }
MessageSetDifferencer >> initializeDefinitionPairs: aSequence [
	leftSet := MessageSet messageList: (aSequence collect: [:ea| ea first]).
	rightSet := MessageSet messageList: (aSequence collect: [:ea| ea last]).
	messageList := aSequence.
	contents := ''
]

{ #category : #'message list' }
MessageSetDifferencer >> listEntryForIndex: index [
	^(leftSet messageList at: index) asStringOrText, ' <-> ', (rightSet messageList at: index) asStringOrText
]

{ #category : #'message list' }
MessageSetDifferencer >> messageList [
	"Answer the current list of messages."

	^messageList
]

{ #category : #'message list' }
MessageSetDifferencer >> messageListIndex: anInteger [ 
	"Set the index of the selected item to be anInteger."

	leftSet messageListIndex: anInteger.
	rightSet messageListIndex: anInteger.
	currentCompiledMethod := leftSet selection
								ifNotNil: [[leftSet selection compiledMethod]
											on: KeyNotFound
											do: [:ex| nil]]
								ifNil: [rightSet selection ifNotNil:
										[[rightSet selection compiledMethod
											on: KeyNotFound
											do: [:ex| nil]]]].
	contents := ''.
	self changed: #messageListIndex.	 "update my selection"
	self editSelection: #editMessage.
	self contentsChanged.
	autoSelectString ifNotNil: [self changed: #autoSelect].
	self decorateButtons
]

{ #category : #'message list' }
MessageSetDifferencer >> messageListMenu: aMenu shifted: shifted [ 
	"Answer the message-list menu"
	| newMenu |
	(newMenu := self menuHook: aMenu named: #messageListMenu shifted: shifted) ~~ aMenu ifTrue:[^newMenu].
	shifted ifTrue: [^ self shiftedMessageListMenu: aMenu].
	aMenu addList: #(
			('browse full (b)' 			browseMethodFull)
			('browse hierarchy (h)'			classHierarchy)
			('browse method (O)'			openSingleMessageBrowser)
			('browse protocol (p)'			browseFullProtocol)
			-
			('fileOut'				fileOutMessage)
			('printOut'				printOutMessage)
			-
			('senders of... (n)'			browseSendersOfMessages)
			('implementors of... (m)'		browseMessages)
			('inheritance (i)'			methodHierarchy)
			('versions (v)'				browseVersions)
			-
			('inst var refs...'			browseInstVarRefs)
			('inst var defs...'			browseInstVarDefs)
			('class var refs...'			browseClassVarRefs)
			('class variables'			browseClassVariables)
			('class refs (N)'			browseClassRefs)
			-
			('remove unchanged'		removeUnchangedDefinitions)
			('remove changed'			removeChangedDefinitions)
			-
			('more...'				shiftedYellowButtonActivity)).
	^ aMenu
]

{ #category : #'message list' }
MessageSetDifferencer >> removeChangedDefinitions [
	self changeDefinitions: (messageList select: [:pair| pair first sourceString = pair second sourceString])
]

{ #category : #'message list' }
MessageSetDifferencer >> removeUnchangedDefinitions [
	self changeDefinitions: (messageList reject: [:pair| pair first sourceString = pair second sourceString])
]

{ #category : #'class list' }
MessageSetDifferencer >> selectedClassOrMetaClass [
	"Answer the currently selected class (or metaclass)."
	^leftSet selectedClassOrMetaClass
		ifNotNil: [:leftBehavior| leftBehavior]
		ifNil: [rightSet selectedClassOrMetaClass ifNotNil:
				[:rightBehavior| rightBehavior]]
]

{ #category : #accessing }
MessageSetDifferencer >> selectedMessageName [
	"Answer the message selector of the currently selected message, if any. 
	 Answer nil otherwise."
	| selectedMessageName class tree plainClassDefinition |
	selectedMessageName := leftSet selectedMessageName
								ifNotNil: [:leftMessage| leftMessage]
								ifNil: [rightSet selectedMessageName ifNotNil:
										[:rightMessage| rightMessage]].
	(#(Definition Hierarchy Comment) includes: selectedMessageName) ifFalse:
		[^selectedMessageName].
	#Definition ~~ selectedMessageName ifTrue:
		[^nil].
	(plainClassDefinition := leftSet contents) isEmpty ifTrue:
							[plainClassDefinition := rightSet contents].
	class := self selectedClassOrMetaClass.
	tree := class subclassDefinerClass parserClass new
				parse: plainClassDefinition readStream
				class: class
				noPattern: true
				notifying: nil
				ifFail: [].
	"Demeter, who (tf) is Demeter??"
	^tree block statements first expr selector key
]
