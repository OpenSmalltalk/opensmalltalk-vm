Class {
	#name : #ClassHierarchyDuplicator,
	#superclass : #Object,
	#instVars : [
		'xlator',
		'classes',
		'prefix'
	],
	#category : #'Cog-Morphing Bytecode Set'
}

{ #category : #'code editing' }
ClassHierarchyDuplicator >> edit [
	(ChangeSet superclassOrder: classes asArray) do:
		[:class| | newClass |
		newClass := class subclassDefinerClass evaluate: (self editClassDefinitionOf: class).
		{ class. class class }
			with: { newClass. newClass class }
			do: [:b :nb|
				b selectors do:
					[:s|
					nb
						compile: (self editCode: (b sourceCodeAt: s) inClass: b withSelector: s)
						classified: (class organization categoryOfElement: s)]]]

	"self new edit"
]

{ #category : #'code editing' }
ClassHierarchyDuplicator >> editClassDefinitionOf: aClass [
	| classDef categoryString |
	categoryString := 'category: '''.
	classDef := self editCode: aClass definition inClass: nil withSelector: nil.
	classDef := classDef
					copyReplaceAll: categoryString
					with: categoryString, prefix.
	^classDef
		copyReplaceAll: aClass classVariablesString
		with: (String streamContents: [:s| aClass classVariablesString subStrings do: [:ea| s nextPutAll: prefix; nextPutAll: ea; space]])

	"self new editClassDefinitionOf: MessageNode"
]

{ #category : #'code editing' }
ClassHierarchyDuplicator >> editCode: sourceText inClass: class withSelector: selector [
	| ranges index codeIndex output codeString range |
	ranges := SHParserST80 new
				rangesIn: (codeString := sourceText asString)
				classOrMetaClass: class
				workspace: nil
				environment: nil.
	index := codeIndex := 1.
	output := (String new: codeString size) writeStream.
	[index <= ranges size] whileTrue:
		[range := ranges at: index.
		 index := index + 1.
		 [codeIndex < range start] whileTrue:
			[output nextPut: (codeString at: codeIndex).
			 codeIndex := codeIndex + 1].
		range type == #assignment
			ifTrue: [output nextPutAll: ':='.
					codeIndex := range end + 1]
			ifFalse:
				[(#(globalVar classVar) includes: range type)
					ifTrue:
						[output nextPutAll: (xlator value: (codeString copyFrom: range start to: range end)).
						 codeIndex := range end + 1]
					ifFalse:
						[#symbol == range type
							ifTrue:
								[output
									nextPut: (codeString at: range start); "#"
									nextPutAll: (xlator value: (codeString copyFrom: range start + 1 to: range end)).
								 codeIndex := range end + 1]
							ifFalse:
								[[codeIndex <= range end] whileTrue:
									[output nextPut: (codeString at: codeIndex).
									 codeIndex := codeIndex + 1].
								"kill whitespace after up-arrow in ^ expr"
								(range type == #return and: [index <= ranges size]) ifTrue:
									[codeIndex := (ranges at: index) start]]]]].
	^output contents

	"SHParserST80 new
		rangesIn: (ClassHierarchyDuplicator sourceCodeAt: #editCode:inClass:withSelector:) asString
		classOrMetaClass: ClassHierarchyDuplicator
		workspace: nil
		environment: nil"

	"SHParserST80 new
		rangesIn: ClassHierarchyDuplicator definition asString
		classOrMetaClass: nil
		workspace: nil
		environment: nil"

	"ClassHierarchyDuplicator new editCode: LeafNode definition inClass: nil withSelector: nil"
	"ClassHierarchyDuplicator new editCode: (MessageNode sourceCodeAt: #emitToDo:on:value:) inClass: MethodNode withSelector: #emitToDo:on:value:"
	"ClassHierarchyDuplicator new editCode: (MessageNode class sourceCodeAt: #initialize) inClass: MessageNode class withSelector: #initialize"
]

{ #category : #'initialize-release' }
ClassHierarchyDuplicator >> initialize [
	| globalNames |
	prefix := 'XXX'.
	classes := Set new.
	((SystemOrganization categories reject: [:c| c beginsWith: prefix]) select:
		[:c| ('*Compiler*' match: c) and: [#'Compiler-Morphing Bytecode Set' ~= c]]) do:
			[:cat|
			(SystemOrganization listAtCategoryNamed: cat) do:
				[:cn|
				classes add: (Smalltalk at: cn)]].
	globalNames := classes collect: [:ea| ea name asString].
	classes do: [:c| c classPool keys do: [:sym| globalNames add: sym asString]].
	xlator := [:s| (globalNames includes: s) ifTrue: [prefix, s] ifFalse: [s]]

	"self new edit"
]
