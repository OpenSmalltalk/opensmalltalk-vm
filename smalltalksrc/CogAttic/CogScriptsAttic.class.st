Class {
	#name : #CogScriptsAttic,
	#superclass : #CogScripts,
	#category : #'CogAttic-Scripts'
}

{ #category : #'separate vm scripts' }
CogScriptsAttic class >> createSVMTree [
	"Create the parallel StackInterpreterS, CoInterpreterS tree in which
	 objectMemory is an inst var rather than ObjectMemory et al being a superclass"
	"CogScripts createSVMTree"

	| changes map |
	changes := Cursor execute showWhile: [self changedMethodsForObjectMemorySends].

	map := Cursor execute showWhile: [self createStackInterpreterSHierarchy].

	(ChangeSet superclassOrder: (StackInterpreter withAllSubclasses select: [:c| map includesKey: c]) asArray) do:
		[:sourceClass|
		sourceClass selectors do:
			[:sel| | destClass source stamp |
			destClass := map
							at: (((sel beginsWith: 'primitive')
								and: [sel last ~~ $:
								and: [sel ~~ #primitiveFail]])
									ifTrue: [{sourceClass. #primitives}]
									ifFalse: [sourceClass])
							ifAbsent: [map at: sourceClass].
			(changes detect: [:c| c changeClass == sourceClass and: [c selector = sel]] ifNone: [])
				ifNotNil:
					[:change|
					source := change source.
					stamp := Utilities changeStamp copyReplaceAll: Utilities authorInitials with: Utilities authorInitials, ' (objmem refactor)']
				ifNil:
					[source := sourceClass sourceCodeAt: sel.
					stamp := (sourceClass >> sel) timeStamp].
			[destClass
					compile: source
					classified: (sourceClass whichCategoryIncludesSelector: sel)
					withStamp: stamp
					notifying: nil]
				on: SyntaxErrorNotification
				do: [:ex| | newBrowser |
					newBrowser := Browser new setClass: destClass selector: nil.
					newBrowser selectMessageCategoryNamed: (sourceClass whichCategoryIncludesSelector: sel).
					Browser
						openBrowserView: (newBrowser openMessageCatEditString: source)
						label: 'category "', (sourceClass whichCategoryIncludesSelector: sel), '" in ', destClass name]]].

	self readWriteVars, self readOnlyVars do:
		[:sym|
		(NewObjectMemory whichClassIncludesSelector: sym) ifNil:
			[(NewObjectMemory whichClassDefinesInstVar: sym asString)
				compile: sym, (String with: Character cr with: Character tab with: $^), sym
				classified: #accessing]].
	self readWriteVars do:
		[:sym| | setter | setter := (sym, ':') asSymbol.
		(NewObjectMemory whichClassIncludesSelector: setter) ifNil:
			[(NewObjectMemory whichClassDefinesInstVar: sym asString)
				compile: setter, ' aValue', (String with: Character cr with: Character tab with: $^), sym, ' := aValue'
				classified: #accessing]].
]

{ #category : #'separate vm scripts' }
CogScriptsAttic class >> createStackInterpreterSHierarchy [
	"Create the parallel StackInterpreterS, CoInterpreterS tree (without methods).
	 Answer a Dictionary maping source class to dest class with {source. #primitives} -> dest
	 for the added primitives classes."

	| map |
	(Smalltalk classNamed: #StackInterpreterS) ifNotNil:
		[:sis|
		(Object confirm: 'StackInterpreterS exists, nuke?') ifTrue:
			[(ChangeSet superclassOrder: sis withAllSubclasses asArray) reverseDo:
				[:sissc| sissc removeFromSystemUnlogged]]].

	map := Dictionary new.
	(ChangeSet superclassOrder: (StackInterpreter withAllSubclasses
									remove: SchizophrenicClosureFormatStackInterpreter;
									yourself) asArray) do:
		[:sisc| | def |
		def := sisc definition.
		def := sisc == StackInterpreter
				ifTrue: [((def copyReplaceAll: sisc superclass name, ' ' with: ObjectMemory superclass name, ' ')
							copyReplaceAll: 'instanceVariableNames: ''' with: 'instanceVariableNames: ''objectMemory ')
							copyReplaceAll: 'poolDictionaries: ''' with: 'poolDictionaries: ''', (ObjectMemory poolDictionaryNames fold: [:a :b| a, ' ', b]), ' ']
				ifFalse: [def copyReplaceAll: sisc superclass name, ' ' with: sisc superclass name, 'S '].
		def := def copyReplaceAll: sisc name printString with: sisc name printString, 'S'.
		map at: sisc put: (Compiler evaluate: def)].

	map at: {StackInterpreter. #primitives}
		put: (Compiler
				evaluate: 'StackInterpreterS subclass: #StackInterpreterSPrimitives
							instanceVariableNames: ''''
							classVariableNames: ''''
							poolDictionaries: ''''
							category: ''VMMaker-Interpreter''');
		at: {CoInterpreter. #primitives}
		put: (Compiler
				evaluate: 'CoInterpreterS subclass: #CoInterpreterSPrimitives
						instanceVariableNames: ''''
						classVariableNames: ''''
						poolDictionaries: ''''
						category: ''VMMaker-Interpreter''');
		at: {StackInterpreter. #objmem}
		put: (Compiler
				evaluate: 'NewObjectMemory subclass: #NewObjectMemoryS
						instanceVariableNames: ''coInterpreter''
							classVariableNames: ''''
							poolDictionaries: ''''
							category: ''VMMaker-Interpreter''');
		at: {CoInterpreter. #objmem}
		put: (Compiler
				evaluate: 'NewObjectMemoryS subclass: #NewCoObjectMemoryS
						instanceVariableNames: ''''
						classVariableNames: ''''
						poolDictionaries: ''''
						category: ''VMMaker-Interpreter''').

	"reparent subclasses underneath StackInterpreterSPrimitives & CoInterpreterSPrimitives"
	#(StackInterpreterS CoInterpreterS) do:
		[:cn|
		((Smalltalk classNamed: cn) subclasses reject: [:c| c name endsWith: 'Primitives']) do:
			[:sisc| | def |
			def := sisc definition.
			def := def copyReplaceAll: cn, ' ' with: cn, 'Primitives '.
			Compiler evaluate: def]].
	^map
]
