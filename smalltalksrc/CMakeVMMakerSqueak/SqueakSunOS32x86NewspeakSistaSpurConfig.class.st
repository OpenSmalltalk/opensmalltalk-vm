"
A MacOSX32x86NewspeakCogSpur configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

"
Class {
	#name : #SqueakSunOS32x86NewspeakSistaSpurConfig,
	#superclass : #SqueakSunOS32x86Config,
	#category : #'CMakeVMMakerSqueak-SunOS32x86'
}

{ #category : #cmake }
SqueakSunOS32x86NewspeakSistaSpurConfig >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
SqueakSunOS32x86NewspeakSistaSpurConfig >> dirBuildLanguageVMMM [
	^self newspeakSistaSpur
]

{ #category : #cmake }
SqueakSunOS32x86NewspeakSistaSpurConfig >> excludeFromBuild [
	^false

]
