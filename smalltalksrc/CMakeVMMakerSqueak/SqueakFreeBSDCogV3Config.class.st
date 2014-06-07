"
A SqueakFreeBSDCogV3Config  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

Usage:
  SqueakFreeBSDCogV3Config generate
Or:
  SqueakFreeBSDCogV3Config generateWithSources
Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me
"
Class {
	#name : #SqueakFreeBSDCogV3Config,
	#superclass : #SqueakBSDCogV3Config,
	#category : #'CMakeVMMakerSqueak-BSD32x86'
}

{ #category : #'as yet unclassified' }
SqueakFreeBSDCogV3Config >> buildDirName [
	^ 'cmake_build.linux32x86/squeak.cog.v3/bld'
]
