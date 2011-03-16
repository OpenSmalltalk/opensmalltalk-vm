Class {
	#name : #CogMethodSurrogate,
	#superclass : #Object,
	#instVars : [
		'address',
		'memory',
		'cogit'
	],
	#category : #'VMMaker-JITSimulation'
}

{ #category : #accessing }
CogMethodSurrogate class >> alignedByteSizeForClient: aVMClass [
	^self alignedByteSize
]

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
CogMethodSurrogate >> = aCogMethodOrAddressOrNil [
	^address = (aCogMethodOrAddressOrNil
					ifNil: [0]
					ifNotNil: [aCogMethodOrAddressOrNil asInteger])
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
CogMethodSurrogate >> at: anAddress memory: aBitmap cogit: aCogit [
	address := anAddress.
	memory := aBitmap.
	cogit := aCogit
]

{ #category : #accessing }
CogMethodSurrogate >> cPICNumCases [
	^self stackCheckOffset
]

{ #category : #accessing }
CogMethodSurrogate >> cPICNumCases: n [
	^self stackCheckOffset: n
]

{ #category : #comparing }
CogMethodSurrogate >> isZero [
	^address = 0
]

{ #category : #accessing }
CogMethodSurrogate >> nextOpenPIC [
	| moField |
	moField := self methodObject.
	^moField ~= 0 ifTrue:
		[cogit cogMethodSurrogateAt: moField - self homeOffset]
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
