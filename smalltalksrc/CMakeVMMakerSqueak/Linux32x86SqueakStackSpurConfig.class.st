"
A Linux32x86SqueakStackSpurConfig configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

Usage:
Linux32x86SqueakStackSpurConfig generate
Or: 
Linux32x86SqueakStackSpurConfig generateWithSources
Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me


"
Class {
	#name : #Linux32x86SqueakStackSpurConfig,
	#superclass : #CPlatformConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #'as yet unclassified' }
Linux32x86SqueakStackSpurConfig class >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder allBuildConfigurations
]

{ #category : #'as yet unclassified' }
Linux32x86SqueakStackSpurConfig >> todo [
	self flag:'tty'
]
