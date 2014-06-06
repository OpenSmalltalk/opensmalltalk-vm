"
I serve as a facade to ease building Cog VM with CMakeVMMakerSqueak configs


"
Class {
	#name : #SqueakAndroidBuilder,
	#superclass : #SqueakCMakeVMMakerAbstractBuilder,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #documentation }
SqueakAndroidBuilder class >> availableBuildTypesForTarget: aSymbol [
	[
	((Smalltalk at: aSymbol)  category) = 'CMakeVMMakerSqueak-Android'
		ifTrue:[	^super availableBuildsTypesForTarget: aSymbol inCategory: ((Smalltalk at: aSymbol)  category).]
		ifFalse:[self inform: (self userErrorInvalidTarget: aSymbol)]
	] ifError:[self inform: (self userErrorInvalidTarget: aSymbol)].
	^nil.
]

{ #category : #documentation }
SqueakAndroidBuilder class >> availableTargets [
	^super availableTargets: 'CMakeVMMakerSqueak-Android'
]
