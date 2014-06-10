"
A MacOSX32x86NewspeakCogSpur configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

"
Class {
	#name : #SqueakSunOS32x86SqueakStackSpurConfig,
	#superclass : #SqueakSunOS32x86Config,
	#category : #'CMakeVMMakerSqueak-SunOS32x86'
}

{ #category : #cmake }
SqueakSunOS32x86SqueakStackSpurConfig >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
SqueakSunOS32x86SqueakStackSpurConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackSpur
]

{ #category : #cmake }
SqueakSunOS32x86SqueakStackSpurConfig >> excludeFromBuild [
	^false

]
