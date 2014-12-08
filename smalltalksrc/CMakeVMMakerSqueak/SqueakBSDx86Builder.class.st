"
I am a facade.

I query, and invoke CMakeVMMakerSqueak configurations.

HelpBrowser openOn: CMakeVMMakerSqueakBuildersHelp.
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp.
HelpBrowser openOn: CMakeVMMakerSqueakStartHereHelp.

"
Class {
	#name : #SqueakBSDx86Builder,
	#superclass : #SqueakCMakeVMMakerAbstractBuilder,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #queries }
SqueakBSDx86Builder >> configurationsCategory [
	^ 'CMakeVMMakerSqueak-BSD32x86'
]
