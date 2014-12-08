"
I am a facade.

I query, and invoke CMakeVMMakerSqueak configurations.

HelpBrowser openOn: CMakeVMMakerSqueakBuildersHelp.
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp.
HelpBrowser openOn: CMakeVMMakerSqueakStartHereHelp.

"
Class {
	#name : #SqueakSunOS32x86Builder,
	#superclass : #SqueakCMakeVMMakerAbstractBuilder,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #queries }
SqueakSunOS32x86Builder >> configurationsCategory [
	^'CMakeVMMakerSqueak-SunOS32x86'
]
