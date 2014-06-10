Class {
	#name : #SqueakIA32BochsWin32Config,
	#superclass : #SqueakIA32BochsConfig,
	#category : #'CMakeVMMakerSqueak-IA32-Bochs'
}

{ #category : #cmake }
SqueakIA32BochsWin32Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogSpur
]

{ #category : #'as yet unclassified' }
SqueakIA32BochsWin32Config >> todo [
	self flag:'tty'
]
