Class {
	#name : #CogMethodSurrogate,
	#superclass : #Object,
	#instVars : [
		'address',
		'memory'
	],
	#category : #'VMMaker-JITSimulation'
}

{ #category : #arithmetic }
CogMethodSurrogate >> + aCogMethodOrAddress [
	^address + aCogMethodOrAddress asInteger
]

{ #category : #comparing }
CogMethodSurrogate >> < aCogMethodOrAddress [
	^address < aCogMethodOrAddress asInteger
]

{ #category : #comparing }
CogMethodSurrogate >> <= aCogMethodOrAddress [
	^address <= aCogMethodOrAddress asInteger
]

{ #category : #comparing }
CogMethodSurrogate >> = aCogMethodOrAddress [
	^address = aCogMethodOrAddress asInteger
]

{ #category : #comparing }
CogMethodSurrogate >> > aCogMethodOrAddress [
	^address > aCogMethodOrAddress asInteger
]

{ #category : #comparing }
CogMethodSurrogate >> >= aCogMethodOrAddress [
	^address >= aCogMethodOrAddress asInteger
]

{ #category : #arithmetic }
CogMethodSurrogate >> adaptToInteger: rcvr andSend: selector [
	"If no method has been provided for adapting an object to a Integer,
	then it may be adequate to simply adapt it to a number."
	^rcvr perform: selector with: address
]

{ #category : #accessing }
CogMethodSurrogate >> address [
	^address
]

{ #category : #accessing }
CogMethodSurrogate >> asInteger [
	"Answer the surrogate's adress. This is equivalent to a C cast to sqInt,
	 which is precisely what Slang generates for asInteger"
	^address
]

{ #category : #accessing }
CogMethodSurrogate >> asUnsignedInteger [
	"Answer the surrogate's adress. This is equivalent to a C cast to usqInt,
	 which is precisely what Slang generates for asUnsignedInteger"
	^address
]

{ #category : #'instance initialization' }
CogMethodSurrogate >> at: anAddress memory: aBitmap [
	address := anAddress.
	memory := aBitmap
]

{ #category : #accessing }
CogMethodSurrogate >> cPICNumCases [
	^self stackCheckOffset
]

{ #category : #accessing }
CogMethodSurrogate >> cPICNumCases: n [
	^self stackCheckOffset: n
]

{ #category : #accessing }
CogMethodSurrogate >> nextOpenPIC [
	| address |
	address := self methodObject.
	^address ~= 0 ifTrue:
		[self class new at: address memory: memory]
]

{ #category : #accessing }
CogMethodSurrogate >> nextOpenPIC: cogMethodSurrogateOrNil [
	^self methodObject: (cogMethodSurrogateOrNil ifNil: [0] ifNotNil: [cogMethodSurrogateOrNil asUnsignedInteger])
]

{ #category : #printing }
CogMethodSurrogate >> printOn: aStream [
	super printOn: aStream.
	aStream nextPutAll: ' @'; print: address; nextPut: $/; nextPutAll: address hex
]
