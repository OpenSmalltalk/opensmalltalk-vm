Class {
	#name : #CurrentImageCoInterpreterFacadeForSpurObjectRepresentation,
	#superclass : #CurrentImageCoInterpreterFacade,
	#category : #'VMMaker-Support'
}

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation class >> objectRepresentationClass [
	^CogObjectRepresentationFor32BitSpur
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> baseHeaderSize [
	^SpurMemoryManager baseHeaderSize
]
