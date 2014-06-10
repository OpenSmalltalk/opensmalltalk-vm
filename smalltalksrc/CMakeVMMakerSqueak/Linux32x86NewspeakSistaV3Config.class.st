"
A Linux32x86NewspeakCogV3Config  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

Usage:
  Linux32x86NewspeakCogV3Config generate
Or:
  Linux32x86NewspeakCogV3Config generateWithSources
Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me
"
Class {
	#name : #Linux32x86NewspeakSistaV3Config,
	#superclass : #Linux32x86Config,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #cmake }
Linux32x86NewspeakSistaV3Config >> dirBuildLanguageVMMM [
	^self newspeakSistaV3
]

{ #category : #cmake }
Linux32x86NewspeakSistaV3Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build"
	^false
]

{ #category : #'as yet unclassified' }
Linux32x86NewspeakSistaV3Config >> todo [
	self flag:'tty'
]
