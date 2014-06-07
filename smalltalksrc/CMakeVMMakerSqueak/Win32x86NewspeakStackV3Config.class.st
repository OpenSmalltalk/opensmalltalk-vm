"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf



"
Class {
	#name : #Win32x86NewspeakStackV3Config,
	#superclass : #CPlatformConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#category : #'CMakeVMMakerSqueak-Win32x86'
}

{ #category : #'as yet unclassified' }
Win32x86NewspeakStackV3Config >> todo [
	self flag:'tty'
]
