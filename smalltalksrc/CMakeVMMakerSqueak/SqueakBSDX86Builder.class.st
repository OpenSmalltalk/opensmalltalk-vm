"
I am a facade.

I query, and invoke CMakeVMMakerSqueak configurations.


"
Class {
	#name : #SqueakBSDX86Builder,
	#superclass : #SqueakCMakeVMMakerAbstractBuilder,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #documentation }
SqueakBSDX86Builder class >> availableBuildTypesForTarget: aSymbol [
	self flag:'tty'. "I do not like the hard coding of the category name. Also, how will inform kludge up auto-builds?"
	[
	((Smalltalk at: aSymbol)  category) = (self configurationsCategory)
		ifTrue:[	^super availableBuildsTypesForTarget: aSymbol inCategory: ((Smalltalk at: aSymbol)  category).]
		ifFalse:[self inform: (self userErrorInvalidTarget: aSymbol)]
	] ifError:[self inform: (self userErrorInvalidTarget: aSymbol)].
	^nil.
]

{ #category : #documentation }
SqueakBSDX86Builder class >> availableTargets [
	^super availableTargets: (self configurationsCategory)
]

{ #category : #documentation }
SqueakBSDX86Builder class >> configurationsCategory [
	^ 'CMakeVMMakerSqueak-BSD32x86'
]
