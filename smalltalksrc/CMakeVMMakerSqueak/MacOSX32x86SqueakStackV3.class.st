"
A MacOSX32x86SqueakStackV3  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

"
Class {
	#name : #MacOSX32x86SqueakStackV3,
	#superclass : #SqueakMacOSX32x86Config,
	#category : #'CMakeVMMakerSqueak-MacOSX32x86'
}

{ #category : #cmake }
MacOSX32x86SqueakStackV3 >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
MacOSX32x86SqueakStackV3 >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackV3
]

{ #category : #cmake }
MacOSX32x86SqueakStackV3 >> excludeFromBuild [
	^false

]
