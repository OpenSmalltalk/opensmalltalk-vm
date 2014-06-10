"
A MacOSX32x86NewspeakCogSpur configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

"
Class {
	#name : #SqueakSunOS32x86NewspeakStackSpurConfig,
	#superclass : #SqueakSunOS32x86Config,
	#category : #'CMakeVMMakerSqueak-SunOS32x86'
}

{ #category : #cmake }
SqueakSunOS32x86NewspeakStackSpurConfig >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
SqueakSunOS32x86NewspeakStackSpurConfig >> dirBuildLanguageVMMM [
	^self newspeakStackSpur
]

{ #category : #cmake }
SqueakSunOS32x86NewspeakStackSpurConfig >> excludeFromBuild [
	^false

]
