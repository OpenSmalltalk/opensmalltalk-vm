"
I serve as a facade to ease building Cog VM with CMakeVMMakerSqueak configs


"
Class {
	#name : #SqueakLinux32X86Builder,
	#superclass : #SqueakCMakeVMMakerAbstractBuilder,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #documentation }
SqueakLinux32X86Builder class >> availableBuildTypesForTarget: aSymbol [
	[
	((Smalltalk at: aSymbol)  category) =  'CMakeVMMakerSqueak-Linux32x86'
		ifTrue:[	^super availableBuildsTypesForTarget: aSymbol inCategory: ((Smalltalk at: aSymbol)  category).]
		ifFalse:[self inform: (self userErrorInvalidTarget: aSymbol)]
	] ifError:[self inform: (self userErrorInvalidTarget: aSymbol)].
	^nil.
]

{ #category : #documentation }
SqueakLinux32X86Builder class >> availableTargets [
	^super availableTargets: 'CMakeVMMakerSqueak-Linux32x86'
]
