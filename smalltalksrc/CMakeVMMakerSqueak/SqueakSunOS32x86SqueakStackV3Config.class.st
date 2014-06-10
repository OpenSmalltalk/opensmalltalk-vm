"
A MacOSX32x86NewspeakCogSpur configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

"
Class {
	#name : #SqueakSunOS32x86SqueakStackV3Config,
	#superclass : #SqueakSunOS32x86Config,
	#category : #'CMakeVMMakerSqueak-SunOS32x86'
}

{ #category : #cmake }
SqueakSunOS32x86SqueakStackV3Config >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
SqueakSunOS32x86SqueakStackV3Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackV3
]

{ #category : #cmake }
SqueakSunOS32x86SqueakStackV3Config >> excludeFromBuild [
	^false

]
