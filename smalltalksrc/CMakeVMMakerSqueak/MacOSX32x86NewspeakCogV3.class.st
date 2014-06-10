"
A MacOSX32x86NewspeakCogV3  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

"
Class {
	#name : #MacOSX32x86NewspeakCogV3,
	#superclass : #SqueakMacOSX32x86Config,
	#category : #'CMakeVMMakerSqueak-MacOSX32x86'
}

{ #category : #cmake }
MacOSX32x86NewspeakCogV3 >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
MacOSX32x86NewspeakCogV3 >> dirBuildLanguageVMMM [
	^self newspeakCogV3
]

{ #category : #cmake }
MacOSX32x86NewspeakCogV3 >> excludeFromBuild [
	^false

]
