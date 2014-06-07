"
I serve as a facade to ease building Cog VM with CMakeVMMakerSqueak configs


"
Class {
	#name : #SqueakLinuxARMBuilder,
	#superclass : #SqueakCMakeVMMakerAbstractBuilder,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #documentation }
SqueakLinuxARMBuilder class >> availableBuildTypesForTarget: aSymbol [
	self flag:'tty'. "I do not like the hard coding of the category name. Also, how will inform kludge up auto-builds?"
	[
	((Smalltalk at: aSymbol)  category) =  (self configurationsCategory)
		ifTrue:[	^super availableBuildsTypesForTarget: aSymbol inCategory: ((Smalltalk at: aSymbol)  category).]
		ifFalse:[self inform: (self userErrorInvalidTarget: aSymbol). ]
	] ifError:[self inform: (self userErrorInvalidTarget: aSymbol)].
	^nil.

]

{ #category : #documentation }
SqueakLinuxARMBuilder class >> availableTargets [
	^super availableTargets: (self configurationsCategory)
]

{ #category : #documentation }
SqueakLinuxARMBuilder class >> configurationsCategory [
	^'CMakeVMMakerSqueak-Linux32ARMv6'
]
