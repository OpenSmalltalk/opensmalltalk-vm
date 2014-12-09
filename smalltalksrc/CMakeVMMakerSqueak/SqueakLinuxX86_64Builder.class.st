"
I am a facade.

I query, and invoke CMakeVMMakerSqueak configurations.

HelpBrowser openOn: CMakeVMMakerSqueakHelp.

"
Class {
	#name : #'SqueakLinuxX86_64Builder',
	#superclass : #SqueakCMakeVMMakerAbstractBuilder,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #queries }
SqueakLinuxX86_64Builder >> configurationsCategory [
	^'CMakeVMMakerSqueak-LinuxX86-64'
]
