"
A SqueakIA32BochsMacOSConfig  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

Usage:
  SqueakIA32BochsMacOSConfig generate
Or:
  SqueakIA32BochsMacOSConfig generateWithSources
Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me
"
Class {
	#name : #SqueakIA32BochsMacOSConfig,
	#superclass : #SqueakIA32BochsConfig,
	#category : #'CMakeVMMakerSqueak-IA32-Bochs'
}

{ #category : #'as yet unclassified' }
SqueakIA32BochsMacOSConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogSpur
]

{ #category : #'as yet unclassified' }
SqueakIA32BochsMacOSConfig >> todo [
	self flag:'tty'
]
