"
A MacOSX32x86SqueakStackSpur  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

"
Class {
	#name : #MacOSX32x86SqueakStackSpur,
	#superclass : #SqueakMacOSX32x86Config,
	#category : #'CMakeVMMakerSqueak-MacOSX32x86'
}

{ #category : #cmake }
MacOSX32x86SqueakStackSpur >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
MacOSX32x86SqueakStackSpur >> excludeFromBuild [
	^false

]
