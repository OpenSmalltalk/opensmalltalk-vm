Class {
	#name : #CurrentImageCoInterpreterFacadeFor64BitSpurObjectRepresentation,
	#superclass : #CurrentImageCoInterpreterFacadeForSpurObjectRepresentation,
	#category : #'VMMaker-Support'
}

{ #category : #'accessing class hierarchy' }
CurrentImageCoInterpreterFacadeFor64BitSpurObjectRepresentation class >> objectMemoryClass [
	^Spur64BitCoMemoryManager
]

{ #category : #'accessing class hierarchy' }
CurrentImageCoInterpreterFacadeFor64BitSpurObjectRepresentation class >> objectRepresentationClass [
	^CogObjectRepresentationFor64BitSpur
]

{ #category : #'private-cacheing' }
CurrentImageCoInterpreterFacadeFor64BitSpurObjectRepresentation >> objectForOop: anOop [
	"This is a keyAtValue: search and so needs speeding up either by a reverse map or a simple cache."
	^(anOop bitAnd: 7) caseOf: {
		[0] -> [anOop = cachedOop
				ifTrue: [cachedObject]
				ifFalse: [cachedObject := objectMap keyAtValue: anOop. "may raise Error"
						cachedOop := anOop. "Dom't assign until accessed without error"
						cachedObject]].
		[1] -> [anOop signedIntFromLong64 >> 3].
		[2] -> [Character value: anOop >> 3].
		[4] -> [objectMemory smallFloatValueOf: anOop] }
]

{ #category : #'object map' }
CurrentImageCoInterpreterFacadeFor64BitSpurObjectRepresentation >> oopForObject: o [
	o isNumber
		ifTrue:
			[o isInteger
				ifTrue:
					[(o between: objectMemory minSmallInteger and: objectMemory maxSmallInteger) ifTrue:
						[^objectMemory integerObjectOf: o asInteger]]
				ifFalse:
					[o isFloat ifTrue:
						[(objectMemory isSmallFloatValue: o) ifTrue:
							[^objectMemory smallFloatValueOf: o]]]]
		ifFalse:
			[o isCharacter ifTrue:
				[^objectMemory characterObjectOf: o asInteger]].
	^objectMap at: o ifAbsentPut: [objectMap size * 8 + (1024 * 1024)]
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeFor64BitSpurObjectRepresentation >> smallFloatExponentOffset [
	^objectMemory smallFloatExponentOffset
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeFor64BitSpurObjectRepresentation >> smallFloatMantissaBits [
	^objectMemory smallFloatMantissaBits
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeFor64BitSpurObjectRepresentation >> smallFloatTag [
	^objectMemory smallFloatTag
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeFor64BitSpurObjectRepresentation >> specialObjectsArrayAddress [
	^self addressForLabel: #specialObjectsOop
]
