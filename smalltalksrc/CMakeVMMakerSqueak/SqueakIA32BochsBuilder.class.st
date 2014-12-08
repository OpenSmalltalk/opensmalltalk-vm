"
I am a facade.

I query, and invoke CMakeVMMakerSqueak configurations.

HelpBrowser openOn: CMakeVMMakerSqueakBuildersHelp.
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp.
HelpBrowser openOn: CMakeVMMakerSqueakStartHereHelp.

"
Class {
	#name : #SqueakIA32BochsBuilder,
	#superclass : #SqueakCMakeVMMakerAbstractBuilder,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #queries }
SqueakIA32BochsBuilder >> configurationsCategory [
	^'CMakeVMMakerSqueak-IA32-Bochs'
]
