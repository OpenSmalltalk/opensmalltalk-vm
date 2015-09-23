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
