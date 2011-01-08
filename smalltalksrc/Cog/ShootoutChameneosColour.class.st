Class {
	#name : #ShootoutChameneosColour,
	#superclass : #Object,
	#instVars : [
		'color'
	],
	#classVars : [
		'Blue',
		'Red',
		'Yellow'
	],
	#category : #'Cog-Benchmarks'
}

{ #category : #accessing }
ShootoutChameneosColour class >> blue [
   ^Blue
]

{ #category : #accessing }
ShootoutChameneosColour class >> blue: anObject [
   Blue := anObject
]

{ #category : #'initialize-release' }
ShootoutChameneosColour class >> createBlue [
   "comment stating purpose of message"

   ^super new color: #blue
]

{ #category : #'initialize-release' }
ShootoutChameneosColour class >> createRed [
   "comment stating purpose of message"

   ^super new color: #red
]

{ #category : #'initialize-release' }
ShootoutChameneosColour class >> createYellow [
   "comment stating purpose of message"

   ^super new color: #yellow
]

{ #category : #printing }
ShootoutChameneosColour class >> generateReportOfColoursOn: readOut [
   | colours |
   colours := Array
            with: Blue
            with: Red
            with: Yellow.
   colours do:
         [:aColour |
         colours do:
               [:anotherColour |
               aColour printOn: readOut.
               readOut nextPutAll: ' + '.
               anotherColour printOn: readOut.
               readOut nextPutAll: ' -> '.
               (aColour complementaryColourFor: anotherColour) printOn: readOut.
               readOut nl]].
   ^readOut
]

{ #category : #'initialize-release' }
ShootoutChameneosColour class >> initialize [
   "self initialize"

   Red := self createRed.
   Blue := self createBlue.
   Yellow := self createYellow
]

{ #category : #accessing }
ShootoutChameneosColour class >> red [
   ^Red
]

{ #category : #accessing }
ShootoutChameneosColour class >> red: anObject [
   Red := anObject
]

{ #category : #accessing }
ShootoutChameneosColour class >> yellow [
   ^Yellow
]

{ #category : #accessing }
ShootoutChameneosColour class >> yellow: anObject [
   Yellow := anObject
]

{ #category : #accessing }
ShootoutChameneosColour >> color [
   ^color
]

{ #category : #accessing }
ShootoutChameneosColour >> color: aColor [
   color := aColor
]

{ #category : #'as yet unclassified' }
ShootoutChameneosColour >> complementaryColourFor: aChameneosColour [
   "determine the complementary colour defined as..."

   self == aChameneosColour ifTrue: [^self].
   self isBlue
      ifTrue:
         [aChameneosColour isRed
            ifTrue: [^self class yellow]
            ifFalse: [^self class red]].
   self isRed
      ifTrue:
         [aChameneosColour isBlue
            ifTrue: [^self class yellow]
            ifFalse: [^self class blue]].
   aChameneosColour isBlue
      ifTrue: [^self class red]
      ifFalse: [^self class blue]
]

{ #category : #testing }
ShootoutChameneosColour >> hasSameColorAs: aChameneos [
   ^self color == aChameneos color
]

{ #category : #testing }
ShootoutChameneosColour >> isBlue [
   ^self == self class blue
]

{ #category : #testing }
ShootoutChameneosColour >> isRed [
   ^self == self class red
]

{ #category : #testing }
ShootoutChameneosColour >> isYellow [
   ^self == self class yellow
]

{ #category : #printing }
ShootoutChameneosColour >> printOn: aStream [
   aStream nextPutAll: self color
]
