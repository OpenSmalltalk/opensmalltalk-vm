"
Strengths are used to measure the relative importance of constraints. The hierarchy of available strengths is determined by the class variable StrengthTable (see my class initialization method). Because Strengths are invariant, references to Strength instances are shared (i.e. all references to
""Strength of: #required"" point to a single, shared instance). New strengths may be inserted in the strength hierarchy without disrupting current constraints.

Instance variables:
	symbolicValue		symbolic strength name (e.g. #required) <Symbol>
	arithmeticValue		index of the constraint in the hierarchy, used for comparisons <Number>
"
Class {
	#name : #DBStrength,
	#superclass : #Object,
	#instVars : [
		'symbolicValue',
		'arithmeticValue'
	],
	#classVars : [
		'AbsoluteStrongest',
		'AbsoluteWeakest',
		'Required',
		'StrengthConstants',
		'StrengthTable'
	],
	#category : #'Cog-Benchmarks-DeltaBlue'
}

{ #category : #constants }
DBStrength class >> absoluteStrongest [

	^AbsoluteStrongest
]

{ #category : #constants }
DBStrength class >> absoluteWeakest [

	^AbsoluteWeakest
]

{ #category : #initialize }
DBStrength class >> initialize [
	"Initialize the symbolic strength table. Fix the internally caches
	 values of all existing instances."
	"Strength initialize"

	StrengthTable := Dictionary new.
	StrengthTable at: #absoluteStrongest put: -10000.
	StrengthTable at: #required put: -800.
	StrengthTable at: #strongPreferred put: -600.
	StrengthTable at: #preferred put: -400.
	StrengthTable at: #strongDefault put: -200.
	StrengthTable at: #default put: 0.
	StrengthTable at: #weakDefault put: 500.
	StrengthTable at: #absoluteWeakest put: 10000.

	StrengthConstants := Dictionary new.
	StrengthTable keys do:
		[: strengthSymbol |
			StrengthConstants
				at: strengthSymbol
				put: ((super new) initializeWith: strengthSymbol)].

	AbsoluteStrongest := DBStrength of: #absoluteStrongest.
	AbsoluteWeakest := DBStrength of: #absoluteWeakest.
	Required := DBStrength of: #required.
]

{ #category : #'instance creation' }
DBStrength class >> of: aSymbol [
	"Answer an instance with the specified strength."

	^ StrengthConstants at: aSymbol
]

{ #category : #constants }
DBStrength class >> required [

	^Required
]

{ #category : #private }
DBStrength >> arithmeticValue [
	"Answer my arithmetic value. Used for comparisons. Note that
	 STRONGER constraints have SMALLER arithmetic values."

	^arithmeticValue
]

{ #category : #private }
DBStrength >> initializeWith: symVal [
	"Record my symbolic value and reset my arithmetic value."

	symbolicValue := symVal.
	arithmeticValue := StrengthTable at: symbolicValue.
]

{ #category : #printing }
DBStrength >> printOn: aStream [
	"Append a string which represents my strength onto aStream."

	aStream nextPutAll: '%', symbolicValue, '%'.
]

{ #category : #comparing }
DBStrength >> sameAs: aStrength [
	"Answer true if I am the same strength as the given Strength."

	^ arithmeticValue = aStrength arithmeticValue
]

{ #category : #comparing }
DBStrength >> stronger: aStrength [
	"Answer true if I am stronger than the given Strength."

	^ arithmeticValue < aStrength arithmeticValue
]

{ #category : #'max / min' }
DBStrength >> strongest: aStrength [
	"Answer the stronger of myself and aStrength."

	^ (aStrength stronger: self)
		ifTrue: [aStrength]
		ifFalse: [self]
]

{ #category : #comparing }
DBStrength >> weaker: aStrength [
	"Answer true if I am weaker than the given Strength."

	^ arithmeticValue > aStrength arithmeticValue
]

{ #category : #'max / min' }
DBStrength >> weakest: aStrength [
	"Answer the weaker of myself and aStrength."

	^ (aStrength weaker: self)
		ifTrue: [aStrength]
		ifFalse: [self].
]
