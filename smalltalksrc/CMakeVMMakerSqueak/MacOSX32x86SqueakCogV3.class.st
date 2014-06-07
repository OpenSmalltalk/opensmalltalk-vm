"
A MacOSX32x86SqueakCogV3  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

"
Class {
	#name : #MacOSX32x86SqueakCogV3,
	#superclass : #SqueakMacOSV3Config,
	#category : #'CMakeVMMakerSqueak-MacOSX32x86'
}

{ #category : #'as yet unclassified' }
MacOSX32x86SqueakCogV3 >> todo [
	self flag:'tty'
]
