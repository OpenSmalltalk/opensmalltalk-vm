Class {
	#name : #SpurBootstrapNewspeakFilePatcher,
	#superclass : #Object,
	#instVars : [
		'source',
		'substitutions'
	],
	#category : #'Cog-Bootstrapping'
}

{ #category : #patching }
SpurBootstrapNewspeakFilePatcher >> editTo: dest [ "<FileStream>"
	source reopen.
	[substitutions do:
		[:tuple|
		 [:start :end :substitution|
		  [source position + 1 < start] whileTrue:
			[dest nextPut: source next].
		   dest nextPutAll: (substitution
							copyReplaceAll: (String with: Character cr)
							with: (String with: Character lf)).
		   source skip: end - start + 1] valueWithArguments: tuple].
	 dest nextPutAll: source upToEnd]
		ensure: [source close]
]

{ #category : #parsing }
SpurBootstrapNewspeakFilePatcher >> findClassDeclarationFor: className in: ast [ "<ClassDeclarationAST>" "^(ClassDeclarationAST|nil)"
	^ast instanceSide nestedClasses
		detect: [:classDecl| classDecl name = className]
		ifNone: []
]

{ #category : #parsing }
SpurBootstrapNewspeakFilePatcher >> findMethodDeclarationFor: selector "<Symbol>" in: ast [ "<ClassDeclarationAST>" "^(MethodAST|nil)"
	ast instanceSide categories do:
		[:categoryAST|
		 categoryAST methods do:
			[:methodAST|
			methodAST pattern selector = selector ifTrue:
				[^methodAST]]].
	^nil
]

{ #category : #'initialize-release' }
SpurBootstrapNewspeakFilePatcher >> initialize [
	substitutions := SortedCollection sortBlock: [:tupleA :tupleB | tupleA first <= tupleB first]
]

{ #category : #patching }
SpurBootstrapNewspeakFilePatcher >> newspeakSourceFor: method "<CompiledMethod>" selector: selector [ "<Symbol>"
	| source startIndex nextIndex |
	source := method getSourceFromFile asString allButFirst: method selector size - selector size.
	source first ~= selector first ifTrue:
		[source replaceFrom: 1 to: selector size with: selector startingAt: 1].

	"map comments to Newspeak format..."
	startIndex := 1.
	[(startIndex := source indexOf: $" startingAt: startIndex) > 0] whileTrue:
		[nextIndex := source indexOf: $" startingAt: startIndex + 1.
		 nextIndex < startIndex ifTrue:
			[self error: 'matching close comment not found'].
		 source := source copyReplaceFrom: nextIndex to: nextIndex with: ' *)'.
		 source := source copyReplaceFrom: startIndex to: startIndex with: '(* '.
		 startIndex := nextIndex + 5].

	"map assignments to Newspeak format"
	startIndex := 1.
	[(startIndex := source indexOfSubCollection: ':=' startingAt: startIndex) > 0] whileTrue:
		[nextIndex := startIndex.
		 [(source at: nextIndex - 1) isSeparator] whileTrue:
			[nextIndex := nextIndex - 1].
		 source := source copyReplaceFrom: nextIndex to: startIndex + 1 with: '::'.
		 startIndex := nextIndex + 1].

	"add the horror-show parentheses"
	startIndex := source indexOf: Character cr.
	source := source copyReplaceFrom: startIndex to: startIndex - 1 with: ' = ('.
	source := source, (String with: Character cr with: $) ).
	^source
]

{ #category : #parsing }
SpurBootstrapNewspeakFilePatcher >> parse [
	| platform |
	platform := BlackMarket platform.
	^[(NewspeakParsing
			usingPlatform: platform
			grammar: (NewspeakGrammar parserLib: (CombinatorialParsing usingPlatform: platform))
			asts: (NewspeakASTs usingLib: platform)) Parser new compilationUnit parse: source]
		ensure: [source close]
]

{ #category : #patching }
SpurBootstrapNewspeakFilePatcher >> patch: className inDirectory: dir [
	"SpurBootstrapNewspeakFilePatcher new
		patch: 'KernelForSqueak'
		inDirectory: '../newspeak'"
	| directory |
	directory := FileDirectory default directoryNamed: dir.
	source := directory oldFileNamed: className, '.ns3'.
	self substitute: self parse.
	self editTo: (directory forceNewFileNamed: className, '.ns3.patched')
]

{ #category : #patching }
SpurBootstrapNewspeakFilePatcher >> substitute: ast [ "<ClassDeclarationAST>"
															
	SpurBootstrap new prototypeClassNameMetaSelectorMethodDo:
		[:className :isMeta :selector :method| | source |
		 method primitive = 0 ifTrue: "all primitives are in the VMMirror package"
		 	[(self findClassDeclarationFor: className in: ast) ifNotNil:
				[:classDecl|
				 (self findMethodDeclarationFor: selector in: classDecl) ifNotNil:
					[:methodDecl|
					 source := self newspeakSourceFor: method selector: selector.
					 substitutions add: {methodDecl start. methodDecl end. source}]]]]
]
