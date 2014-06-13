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
	#name : #Linux32x86SqueakCogSpurConfig,
	#superclass : #Linux32x86Config,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #cmake }
Linux32x86SqueakCogSpurConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogSpur
]

{ #category : #cmake }
Linux32x86SqueakCogSpurConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build"
	^false
]

{ #category : #'source generation' }
Linux32x86SqueakCogSpurConfig >> prepareForGeneration [
	^ self prepareForCogGeneration

]

{ #category : #'as yet unclassified' }
Linux32x86SqueakCogSpurConfig >> todo [
	self flag:'tty'
]
