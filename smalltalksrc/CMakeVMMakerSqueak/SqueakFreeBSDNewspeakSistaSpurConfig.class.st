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
	#name : #SqueakFreeBSDNewspeakSistaSpurConfig,
	#superclass : #SqueakBSDConfig,
	#category : #'CMakeVMMakerSqueak-BSD32x86'
}

{ #category : #'squeak compatibility' }
SqueakFreeBSDNewspeakSistaSpurConfig >> buildDirName [
	buildType isNil
		ifTrue:[^self dirBuildPlatform, self dirBuildLanguageVMMM, 'build']
		ifFalse:[^self dirBuildPlatform, self dirBuildLanguageVMMM, buildType asString]
]

{ #category : #cmake }
SqueakFreeBSDNewspeakSistaSpurConfig >> excludeFromBuild [
	^false

]
