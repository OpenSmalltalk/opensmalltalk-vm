"
I am a MethodNode that uses the size and emit methods that use the BytecodeEncoder hierarchy's bytecode generation facilities.  This means my nodes no longer need encode specifics about the bytecode set.

To compile edited versions of the size* and emit* methods use
	BytecodeEncoderPutschEditor new edit

In 3.8:
To get the source of the new version of MethodNode>>generate: for BytecodeAgnosticMethodNode use
BytecodeEncoderPutschEditor new
	editCode: (MethodNode sourceCodeAt: #generate:) asString
	inClass: BytecodeAgnosticMethodNode
	withSelector: #generate:

In 3.9:
To get the source of the new version of MethodNode>>generateWith:using: for BytecodeAgnosticMethodNode use
BytecodeEncoderPutschEditor new
	editCode: (BytecodeAgnosticMethodNode sourceCodeAt: #generateWith:using:) asString
	inClass: BytecodeAgnosticMethodNode
	withSelector: #generateWith:using:
"
Class {
	#name : #BytecodeEncoderPutschEditor,
	#superclass : #Object,
	#instVars : [
		'xlator',
		'xlation',
		'kwdxlation',
		'ranges',
		'index',
		'output',
		'codeIndex'
	],
	#category : #'Cog-Morphing Bytecode Set'
}

{ #category : #'code editing' }
BytecodeEncoderPutschEditor >> edit [
	| sn |
	sn := SystemNavigation default.
	xlation keysAndValuesDo:
		[:s :t|
		(sn allImplementorsOf: s localTo: ParseNode) do:
			[:md|
			md actualClass
				compile: (self editCode: md sourceString inClass: md actualClass withSelector: md methodSymbol)
				classified: 'code generation (new scheme)']]
]

{ #category : #'code editing' }
BytecodeEncoderPutschEditor >> editCode: code inClass: class withSelector: selector [
	| codeString |
	ranges := SHParserST80 new rangesIn: code classOrMetaClass: class workspace: nil  environment: nil.
	index := 1.
	codeIndex := 1.
	output := String new writeStream.
	codeString := code asString.
	self process: codeString while: [:ign| true].
	"(StringHolder new textContents:
		(TextDiffBuilder buildDisplayPatchFrom: code to: output contents))
			openLabel: class name , '>>', selector."
	^output contents
]

{ #category : #'initialize-release' }
BytecodeEncoderPutschEditor >> initialize [
	xlator := [:s|
			((((s allButFirst: 4) beginsWith: 'For') or: [((s allButFirst: 4) beginsWith: 'Except') or: [s fifth = $:]])
				ifTrue: [(s first: 4), 'Code', (s allButFirst: 4)]
				ifFalse: [(s first: 4), 'CodeFor', (s allButFirst: 4)]) copyReplaceAll: ':on:' with: ':encoder:'].
	xlation := Dictionary new.
	(((ParseNode withAllSubclasses removeAll: Encoder withAllSubclasses; yourself)
		inject: Set new
		into: [:s :c| s addAll: c selectors. s])
			select:
				[:s| ((s beginsWith: 'emit') or: [s beginsWith: 'size'])
					and: [(s includesSubstring: 'Code' caseSensitive: true) not]]) do:
					[:s|xlation at: s put: (xlator value: s) asSymbol].
	kwdxlation := Dictionary new.
	xlation keysAndValuesDo: [:k :v| kwdxlation at: k keywords first put: v keywords first]
]

{ #category : #'code editing' }
BytecodeEncoderPutschEditor >> process: code while: aBlock [
	| range mapOnToEncoder kwd |
	mapOnToEncoder := false.
	[index <= ranges size] whileTrue:
		[range := ranges at: index.
		  (aBlock value: range) ifFalse:
			[^self].
		 index := index + 1.
		 [codeIndex < range start] whileTrue:
			[output nextPut: (code at: codeIndex).
			 codeIndex := codeIndex + 1].
		range type == #assignment
			ifTrue: [output nextPutAll: ':='.
					codeIndex := range end + 1]
			ifFalse:
				[(#(keyword patternKeyword) includes: range type) ifTrue:
					[kwd := code copyFrom: range start to: range end.
					(mapOnToEncoder and: [kwd = 'on:'])
						ifTrue:
							[output nextPutAll: 'encoder: encoder'.
							 mapOnToEncoder := false.
							 codeIndex := (ranges at: index) end + 1.
							 index := index + 1]
						ifFalse:
							[(kwdxlation includesKey: kwd) ifTrue:
								[(kwd beginsWith: 'emit') ifTrue:
									[mapOnToEncoder := true].
								 output nextPutAll: (kwdxlation at: kwd).
								 codeIndex := range end + 1]]]
					ifFalse:
						[[codeIndex <= range end] whileTrue:
							[output nextPut: (code at: codeIndex).
							 codeIndex := codeIndex + 1].
						"kill whitespace after up-arrow in ^ expr"
						(range type == #return and: [index <= ranges size]) ifTrue:
							[codeIndex := (ranges at: index) start]]]]
]
