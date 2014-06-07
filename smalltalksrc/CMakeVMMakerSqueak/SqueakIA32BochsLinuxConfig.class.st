"
A SqueakIA32BochsLinuxConfig  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

Usage:
  SqueakIA32BochsLinuxConfig generate
Or:
  SqueakIA32BochsLinuxConfig generateWithSources
Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me
"
Class {
	#name : #SqueakIA32BochsLinuxConfig,
	#superclass : #SqueakIA32BochsConfig,
	#category : #'CMakeVMMakerSqueak-IA32-Bochs'
}

{ #category : #'as yet unclassified' }
SqueakIA32BochsLinuxConfig >> todo [
	self flag:'tty'
]
