Class {
	#name : #ClosureLabelsPrintEditor,
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
ClosureLabelsPrintEditor >> edit: generateViewBar [
	"self new edit: true"
	| sn |
	sn := SystemNavigation default.
	xlation keysAndValuesDo:
		[:s :t|
		(sn allImplementorsOf: s localTo: ParseNode) do:
			[:md| | newCode |
			newCode := self editCode: md sourceString inClass: md actualClass withSelector: md methodSymbol.
			generateViewBar
				ifTrue: [md actualClass compile: newCode classified: 'printing']
				ifFalse:
					[(StringHolder new textContents:
						(CodeDiffBuilder buildDisplayPatchFrom: md sourceString to: newCode))
							openLabel: md printString]]]
]

{ #category : #'code editing' }
ClosureLabelsPrintEditor >> editCode: code inClass: class withSelector: selector [
	| codeString |
	ranges := SHParserST80 new rangesIn: code classOrMetaClass: class workspace: nil  environment: nil.
	index := 1.
	codeIndex := 1.
	output := String new writeStream.
	codeString := code asString.
	self process: codeString.
	^output contents
]

{ #category : #'initialize-release' }
ClosureLabelsPrintEditor >> initialize [
	xlator := [:s| s copyReplaceAll: 'print' with: 'printWithClosureAnalysis'].
	xlation := Dictionary new.
	(((ParseNode withAllSubclasses removeAll: Encoder withAllSubclasses; yourself)
		inject: Set new
		into: [:s :c| s addAll: c selectors. s]) select:
			[:s| s beginsWith: 'print']) do:
				[:s|xlation at: s put: (xlator value: s) asSymbol].
	kwdxlation := Dictionary new.
	xlation keysAndValuesDo: [:k :v| kwdxlation at: k keywords first put: v keywords first]
]

{ #category : #'code editing' }
ClosureLabelsPrintEditor >> process: code [
	| range kwd |
	[index <= ranges size] whileTrue:
		[range := ranges at: index.
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
					(kwdxlation includesKey: kwd) ifTrue:
						[output nextPutAll: (kwdxlation at: kwd).
						 codeIndex := range end + 1]]
					ifFalse:
						[[codeIndex <= range end] whileTrue:
							[output nextPut: (code at: codeIndex).
							 codeIndex := codeIndex + 1].
						"kill whitespace after up-arrow in ^ expr"
						(range type == #return and: [index <= ranges size]) ifTrue:
							[codeIndex := (ranges at: index) start]]]]
]
