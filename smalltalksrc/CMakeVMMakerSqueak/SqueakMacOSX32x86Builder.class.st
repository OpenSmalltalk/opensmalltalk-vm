"
I am a facade.

I query, and invoke CMakeVMMakerSqueak configurations.

HelpBrowser openOn: CMakeVMMakerSqueakBuildersHelp.
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp.
HelpBrowser openOn: CMakeVMMakerSqueakStartHereHelp.

"
Class {
	#name : #SqueakMacOSX32x86Builder,
	#superclass : #SqueakCMakeVMMakerAbstractBuilder,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #queries }
SqueakMacOSX32x86Builder >> configurationsCategory [
	^'CMakeVMMakerSqueak-MacOSX32x86'
]
