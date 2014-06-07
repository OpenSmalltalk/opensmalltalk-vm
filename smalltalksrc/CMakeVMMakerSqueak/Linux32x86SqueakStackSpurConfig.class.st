"
A Linux32x86SqueakStackSpurConfig configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

Usage:
Linux32x86SqueakStackSpurConfig generate
Or: 
Linux32x86SqueakStackSpurConfig generateWithSources
Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me


"
Class {
	#name : #Linux32x86SqueakStackSpurConfig,
	#superclass : #CPlatformConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#instVars : [
		'buildType'
	],
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #'as yet unclassified' }
Linux32x86SqueakStackSpurConfig class >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder allBuildConfigurations
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackSpurConfig >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackSpurConfig >> buildDirName [
	buildType isNil
		ifTrue:[^self dirBuildPlatform, self dirBuildLanguageVMMM, 'build']
		ifFalse:[^self dirBuildPlatform, self dirBuildLanguageVMMM, buildType asString]
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackSpurConfig >> buildType: aSymbol [
	buildType:= aSymbol
]

{ #category : #cmake }
Linux32x86SqueakStackSpurConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur"
	^self squeakStackSpur
]

{ #category : #cmake }
Linux32x86SqueakStackSpurConfig >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirLinux32x86
]

{ #category : #'as yet unclassified' }
Linux32x86SqueakStackSpurConfig >> todo [
	self flag:'tty'
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackSpurConfig >> topDir [
		^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
]
