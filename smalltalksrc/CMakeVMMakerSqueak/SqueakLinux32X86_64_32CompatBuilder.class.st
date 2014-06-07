"
I am a facade.

I query, and invoke CMakeVMMakerSqueak configurations.




"
Class {
	#name : #'SqueakLinux32X86_64_32CompatBuilder',
	#superclass : #SqueakCMakeVMMakerAbstractBuilder,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #documentation }
SqueakLinux32X86_64_32CompatBuilder class >> availableBuildTypesForTarget: aSymbol [
	self flag:'tty'. "I do not like the hard coding of the category name. Also, how will inform kludge up auto-builds?"
	[
	((Smalltalk at: aSymbol)  category) =  (self configurationsCategory)
		ifTrue:[	^super availableBuildsTypesForTarget: aSymbol inCategory: ((Smalltalk at: aSymbol)  category).]
		ifFalse:[self inform: (self userErrorInvalidTarget: aSymbol)]
	] ifError:[self inform: (self userErrorInvalidTarget: aSymbol)].
	^nil.
]

{ #category : #documentation }
SqueakLinux32X86_64_32CompatBuilder class >> availableTargets [
	^super availableTargets: (self configurationsCategory)
]

{ #category : #documentation }
SqueakLinux32X86_64_32CompatBuilder class >> configurationsCategory [
	^'CMakeVMMakerSqueak-LinuxX86_64-32Compatibility'
]
