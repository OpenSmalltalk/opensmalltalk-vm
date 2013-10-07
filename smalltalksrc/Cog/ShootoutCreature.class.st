Class {
	#name : #ShootoutCreature,
	#superclass : #Object,
	#instVars : [
		'creatureName',
		'colour',
		'selfMet',
		'creaturesMet'
	],
	#category : #'Cog-Benchmarks-Shootout'
}

{ #category : #'initialize-release' }
ShootoutCreature class >> withName: aName colour: aColour [
   ^(ShootoutCreature new initialize)
      name: aName;
      colour: aColour
]

{ #category : #accessing }
ShootoutCreature >> colour [
   ^colour
]

{ #category : #accessing }
ShootoutCreature >> colour: anObject [
   colour := anObject
]

{ #category : #accessing }
ShootoutCreature >> creaturesMet [
   ^creaturesMet
]

{ #category : #accessing }
ShootoutCreature >> creaturesMet: anObject [
   creaturesMet := anObject
]

{ #category : #'initialize-release' }
ShootoutCreature >> initialize [
   selfMet := 0.
   creaturesMet := 0
]

{ #category : #accessing }
ShootoutCreature >> name [
   ^creatureName
]

{ #category : #accessing }
ShootoutCreature >> name: anObject [
   creatureName := anObject
]

{ #category : #accessing }
ShootoutCreature >> selfMet [
   ^selfMet
]

{ #category : #accessing }
ShootoutCreature >> selfMet: anObject [
   ^selfMet := anObject
]

{ #category : #controlling }
ShootoutCreature >> visitMall: mall [

   [| partner |
   partner := mall visitWith: self.
   partner ifNotNil:
         [colour := colour complementaryColourFor: partner colour.
         self == partner ifTrue: [selfMet := selfMet + 1].
         creaturesMet := creaturesMet + 1].
   partner isNil]
         whileFalse
]
