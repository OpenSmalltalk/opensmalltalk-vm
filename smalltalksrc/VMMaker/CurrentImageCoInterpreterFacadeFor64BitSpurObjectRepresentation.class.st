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

{ #category : #accessing }
CurrentImageCoInterpreterFacadeFor64BitSpurObjectRepresentation >> smallFloatTag [
	^objectMemory smallFloatTag
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeFor64BitSpurObjectRepresentation >> specialObjectsArrayAddress [
	^self addressForLabel: #specialObjectsOop
]
