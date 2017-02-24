Class {
	#name : #CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation,
	#superclass : #CurrentImageCoInterpreterFacade,
	#category : #'VMMaker-Support'
}

{ #category : #'accessing class hierarchy' }
CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation class >> objectMemoryClass [
	^NewCoObjectMemory
]

{ #category : #'accessing class hierarchy' }
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

{ #category : #'private-cacheing' }
CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation >> objectForOop: anOop [
	"This is a keyAtValue: search and so needs speeding up either by a reverse map or a simple cache."
	^(anOop bitAnd: 3) caseOf: {
		[0] -> [anOop = cachedOop
				ifTrue: [cachedObject]
				ifFalse: [cachedObject := objectMap keyAtValue: anOop. "may raise Error"
						cachedOop := anOop. "Dom't assign until accessed without error"
						cachedObject]].
		[1] -> [anOop signedIntFromLong >> 1].
		[3] -> [anOop signedIntFromLong >> 1] }
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation >> youngStartAddress [
	^16r4E5E400
]
