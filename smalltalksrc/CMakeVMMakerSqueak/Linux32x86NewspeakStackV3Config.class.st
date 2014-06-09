"
A Linux32x86NewspeakStackV3Config  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

Usage:
 Linux32x86NewspeakStackV3Config generate
Or:
 Linux32x86NewspeakStackV3Config generateWithSources
Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me
"
Class {
	#name : #Linux32x86NewspeakStackV3Config,
	#superclass : #Linux32x86Config,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #cmake }
Linux32x86NewspeakStackV3Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackV3
]

{ #category : #cmake }
Linux32x86NewspeakStackV3Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build"
	^false
]

{ #category : #'as yet unclassified' }
Linux32x86NewspeakStackV3Config >> todo [
	self flag:'tty'
]
