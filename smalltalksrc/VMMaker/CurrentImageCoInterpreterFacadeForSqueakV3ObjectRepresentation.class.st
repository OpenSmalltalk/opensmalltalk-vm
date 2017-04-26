Class {
	#name : #CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation,
	#superclass : #CurrentImageCoInterpreterFacade,
	#category : 'VMMaker-Support'
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
						cachedOop := anOop. "Don't assign until accessed without error"
						cachedObject]].
		[1] -> [anOop signedIntFromLong >> 1].
		[3] -> [anOop signedIntFromLong >> 1] }
]

{ #category : #'object map' }
CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation >> oopForObject: o [
	^(o isInteger and: [o between: objectMemory minSmallInteger and: objectMemory maxSmallInteger])
		ifTrue: [o << 1 bitOr: 1]
		ifFalse: [objectMap at: o ifAbsentPut: [objectMap size * 8 + (1024 * 1024)]]
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation >> receiverTagBitsForMethod: methodOop [
	^(self objectForOop: methodOop) methodClass =SmallInteger
		ifTrue: [1]
		ifFalse: [0]
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation >> youngStartAddress [
	^16r4E5E400
]
