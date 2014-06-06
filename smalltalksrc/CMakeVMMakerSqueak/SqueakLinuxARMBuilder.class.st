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
	[
	((Smalltalk at: aSymbol)  category) =  'CMakeVMMakerSqueak-Linux32ARMv6'
		ifTrue:[	^super availableBuildsTypesForTarget: aSymbol inCategory: ((Smalltalk at: aSymbol)  category).]
		ifFalse:[self inform: (self userErrorInvalidTarget: aSymbol). ]
	] ifError:[self inform: (self userErrorInvalidTarget: aSymbol)].
	^nil.

]

{ #category : #documentation }
SqueakLinuxARMBuilder class >> availableTargets [
	^super availableTargets: 'CMakeVMMakerSqueak-Linux32ARMv6'
]
