"
I am a facade.

I query, and invoke CMakeVMMakerSqueak configurations.

HelpBrowser openOn: CMakeVMMakerSqueakHelp.
"
Class {
	#name : #SqueakLinux32x86Builder,
	#superclass : #SqueakCMakeVMMakerAbstractBuilder,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #queries }
SqueakLinux32x86Builder >> configurationsCategory [
	^'CMakeVMMakerSqueak-Linux32x86'
]
