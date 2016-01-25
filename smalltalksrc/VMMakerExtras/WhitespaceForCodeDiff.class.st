"
I am a special form of whitespace for code diffing.  I masquerade as a string of a single space but remember my actual whitespace. Depending on the definition of at: I may differentiate between whitespace containing a line break from whitespace that doesn't, (which may result in better-formatted diffs).
"
Class {
	#name : #WhitespaceForCodeDiff,
	#superclass : #DiffElement,
	#category : #'VMMakerExtras-Tools'
}

{ #category : #comparing }
WhitespaceForCodeDiff >> = anOtherObject [
	^self species == anOtherObject species
]

{ #category : #accessing }
WhitespaceForCodeDiff >> at: index [
	^1 = index
		ifTrue: ["(string includes: Character cr)
					ifTrue: [Character cr]
					ifFalse: ["Character space"]"]
		ifFalse: [super at: index]
]

{ #category : #testing }
WhitespaceForCodeDiff >> isOctetString [
	"For DiffElement>>string:"
	^false
]

{ #category : #comparing }
WhitespaceForCodeDiff >> match: anOtherObject [
	^self species == anOtherObject species
]

{ #category : #accessing }
WhitespaceForCodeDiff >> size [
	^1
]

{ #category : #accessing }
WhitespaceForCodeDiff >> string: aString [
	super string: aString.
	hash := ' ' hash
]
