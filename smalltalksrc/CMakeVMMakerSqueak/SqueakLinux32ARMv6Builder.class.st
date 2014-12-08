"
I am a facade.

I query, and invoke CMakeVMMakerSqueak configurations.

HelpBrowser openOn: CMakeVMMakerSqueakBuildersHelp.
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp.
HelpBrowser openOn: CMakeVMMakerSqueakStartHereHelp.

"
Class {
	#name : #SqueakLinux32ARMv6Builder,
	#superclass : #SqueakCMakeVMMakerAbstractBuilder,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #queries }
SqueakLinux32ARMv6Builder >> configurationsCategory [
	^'CMakeVMMakerSqueak-Linux32ARMv6'
]
