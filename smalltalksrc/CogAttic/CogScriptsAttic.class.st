Class {
	#name : #CogScriptsAttic,
	#superclass : #CogScripts,
	#category : #'CogAttic-Scripts'
}

{ #category : #'closure scripts' }
CogScriptsAttic class >> bootstrapClosures [
	"CogScripts bootstrapClosures"
	| rep |
	Transcript clear.
	rep := false
			ifTrue: [MCCacheRepository default]
			ifFalse:
				[MCHttpRepository
					location: 'http://dev.qwaq.com/ss/Oinq'
					user: 'qwaq'
					password: ''].
	"This changes load order in Monticello such that additions come in before modifications."
	(rep loadVersionFromFileNamed: 'Monticello-eem.302.mcz') load.
	"This adds some prereqs the compiler uses that are loaded in later packages:
	 Fix the ClassBuilder so redefining CompiledMethod can add and remove class variables.
	 Add Object/Array>>isArray.
	 Add new interface for accessing inst vars & fields on initializing the compiler (Encoder)."
	self bootstrapClosuresCompilerPreloadCode readStream fileIn.
	"This temporarily stops Monticello from unloading code on load and warning about overwriting changes.
	 Since changes span multiple packages need all additions in before any deletions occur.
	 Can't warn about anything until the new debugger api is installed."
	ChangeSet
		newChangesFromStream: self bootstrapClosuresNeuterMonticelloCode readStream
		named: 'neuterMonticello'.
	Smalltalk at: #DoNotUnload put: true.
	1 to: 2 do:
		 [:i|
		  #(	'Compiler-eem.30.mcz'
			'Files-eem.21.mcz'
			'Exceptions-eem.14.mcz'
			'Collections-eem.55.mcz'
			'Tools-eem.45.mcz'
			'Kernel-eem.82.mcz'
			'System-eem.53.mcz'
			'Brad-eem.51.mcz'
			'Morphic-eem.38.mcz'
			'Tweak-Compiler-eem.36.mcz'
			'Tweak-Hacks-eem.30.mcz'
			'Tweak-Basic-eem.151.mcz'
			'Tweak-Core-Proto-eem.56.mcz') do:
				[:pn|
				Transcript clear; nextPutAll: pn; space; nextPut: $(; print: i; nextPut: $); endEntry.
				(rep loadVersionFromFileNamed: pn) load].
		 Smalltalk at: #DoNotUnload put: false].
	"Now remove the temporary hacks to Monticello"
	(ChangeSet named: 'neuterMonticello') changedMessageList do:
		[:mr| | changeRecords |
		changeRecords := mr actualClass changeRecordsAt: mr methodSymbol.
		changeRecords second fileIn].
	"Install BlockClosure in the specialObjectsArray"
	Smalltalk recreateSpecialObjectsArray.
	"Throw the switch to compile to closures"
	self bootstrapClosuresClosureCompilerSwitchCode readStream fileIn.
	"Recompile the system except the one method we can't yet deal with in GeniePlugin (1 too many literals)"
	(Smalltalk forgetDoIts allClasses reject: [:c| c name == #GeniePlugin]) do:
		[:c|
		{ c. c class } do:
			[:b|
			Transcript cr; print: b; endEntry.
			b selectors asSortedCollection do:
				[:s|
				b recompile: s from: b]]].
	UsefulScripts postRecompileCleanup.
	self inform: 'Save and quit and then run UsefulScripts postRecompileCleanup.\Rinse and repeat' withCRs
]

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
