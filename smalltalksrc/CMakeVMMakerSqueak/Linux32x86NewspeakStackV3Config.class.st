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

{ #category : #'as yet unclassified' }
Linux32x86NewspeakStackV3Config >> todo [
	self flag:'tty'
]
