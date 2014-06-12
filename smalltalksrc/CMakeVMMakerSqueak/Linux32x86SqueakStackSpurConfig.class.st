"
A Linux32x86SqueakCogSpurConfig  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

Usage:
Linux32x86SqueakCogSpurConfig generate
Or:
Linux32x86SqueakCogSpurConfig generateWithSources
Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me

"
Class {
	#name : #Linux32x86SqueakStackSpurConfig,
	#superclass : #Linux32x86Config,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #cmake }
Linux32x86SqueakStackSpurConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackSpur
]

{ #category : #cmake }
Linux32x86SqueakStackSpurConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build"
	^false
]

{ #category : #'as yet unclassified' }
Linux32x86SqueakStackSpurConfig >> todo [
	self flag:'tty'
]
