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
	#name : #SqueakFreeBSDSqueakCogV3Config,
	#superclass : #SqueakBSDConfig,
	#category : #'CMakeVMMakerSqueak-BSD32x86'
}

{ #category : #'squeak compatibility' }
SqueakFreeBSDSqueakCogV3Config >> buildDirName [
	buildType isNil
		ifTrue:[^self dirBuildPlatform, self dirBuildLanguageVMMM, 'build']
		ifFalse:[^self dirBuildPlatform, self dirBuildLanguageVMMM, buildType asString]
]

{ #category : #cmake }
SqueakFreeBSDSqueakCogV3Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogV3
]

{ #category : #cmake }
SqueakFreeBSDSqueakCogV3Config >> excludeFromBuild [
	^false

]
