"
I am a facade.

I query, and invoke CMakeVMMakerSqueak configurations.
"
Class {
	#name : #SqueakMacOSBuilder,
	#superclass : #SqueakCMakeVMMakerAbstractBuilder,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #queries }
SqueakMacOSBuilder >> configurationsCategory [
	^'CMakeVMMakerSqueak-MacOS'
]
