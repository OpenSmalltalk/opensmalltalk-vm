Class {
	#name : #CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation,
	#superclass : #CurrentImageCoInterpreterFacade,
	#category : #'VMMaker-Support'
}

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation class >> objectMemoryClass [
	^NewCoObjectMemory
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation class >> objectRepresentationClass [
	^CogObjectRepresentationForSqueakV3
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation >> baseHeaderSize [
	^ObjectMemory baseHeaderSize
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation >> characterTable [
	^self oopForObject: Character characterTable
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation >> formatOfClass: classOop [ 
	^(self objectForOop: classOop) format << 1
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation >> numSlotsOf: objOop [ 
	"Answer the number of slots in the given non-immediate object.
	 Does not adjust the size of contexts by stackPointer."
	| obj elementSize wordSize |
	obj := self objectForOop: objOop.
	self deny: ([obj class isImmediateClass]
				on: MessageNotUnderstood
				do: [:ex| obj class == SmallInteger]).
	wordSize := Smalltalk wordSize.
	elementSize := 
		[obj class elementSize]
			on: MessageNotUnderstood
			do: [:ex| obj class isBytes ifTrue: [1] ifFalse: [wordSize]].
	wordSize = 4 ifTrue:
		[^elementSize caseOf: {
			[1]	->	[obj basicSize + 3 // wordSize].
			[2]	->	[obj basicSize * 2 + 3 // wordSize].
			[4]	->	[obj basicSize + obj class instSize] }].
	^elementSize caseOf: {
		[1]	->	[obj basicSize + (wordSize - 1) // wordSize].
		[2]	->	[obj basicSize * 2 + (wordSize - 1) // wordSize].
		[4]	->	[obj basicSize * 2 + (wordSize - 1) // wordSize].
		[8]	->	[obj basicSize + obj class instSize] }
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation >> youngStartAddress [
	^16r4E5E400
]
