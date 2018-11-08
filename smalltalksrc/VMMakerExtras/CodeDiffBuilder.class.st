"
I am a differencer that compares source in tokens tokenised by a parser.  I consider comments significant, but consider sequences of whitespace equivalent.  Depending on the definition of WhitespaceForCodeDiff>>at: sequences of whitespace containing carriage-returns may be considered different to sequences of whitespace lacking carriage-returns (which may result in better-formatted diffs).
"
Class {
	#name : #CodeDiffBuilder,
	#superclass : #TextDiffBuilder,
	#instVars : [
		'class'
	],
	#category : #'VMMakerExtras-Tools'
}

{ #category : #initialize }
CodeDiffBuilder >> formatLine: aString [
	^aString
]

{ #category : #initialize }
CodeDiffBuilder >> split: aString [
	^self split: aString parser: (class ifNil: [Object] ifNotNil: [class]) parserClass new
]

{ #category : #initialize }
CodeDiffBuilder >> split: aString parser: aParserOrScanner [
	| tokens index |
	tokens := OrderedCollection new.
	index := 1.
	aParserOrScanner scanTokenPositionsIn: aString into:
		[:start :end|
		index < start ifTrue:
			[tokens add: (WhitespaceForCodeDiff new string: (aString copyFrom: index to: start - 1))].
		tokens addLast: (DiffElement string: (aString copyFrom: start to: end)).
		index := end + 1].
	index < aString size ifTrue:
		[tokens add: (WhitespaceForCodeDiff new string: (aString copyFrom: index to: aString size))].
	^tokens
]
