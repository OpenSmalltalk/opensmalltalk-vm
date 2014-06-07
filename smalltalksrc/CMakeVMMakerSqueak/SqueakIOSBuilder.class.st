"
I am a facade.

I query, and invoke CMakeVMMakerSqueak configurations.


"
Class {
	#name : #SqueakIOSBuilder,
	#superclass : #SqueakCMakeVMMakerAbstractBuilder,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #documentation }
SqueakIOSBuilder class >> availableBuildTypesForTarget: aSymbol [
	self flag:'tty'. "I do not like the hard coding of the category name. Also, how will inform kludge up auto-builds?"
	[
	((Smalltalk at: aSymbol)  category) = (self configurationsCategory) 
		ifTrue:[	^super availableBuildsTypesForTarget: aSymbol inCategory: ((Smalltalk at: aSymbol)  category).]
		ifFalse:[self inform: (self userErrorInvalidTarget: aSymbol)]
	] ifError:[self inform: (self userErrorInvalidTarget: aSymbol)].
	^nil.
]

{ #category : #documentation }
SqueakIOSBuilder class >> availableTargets [
	^super availableTargets: (self configurationsCategory)
]

{ #category : #documentation }
SqueakIOSBuilder class >> configurationsCategory [
	^'CMakeVMMakerSqueak-IOS'
]
