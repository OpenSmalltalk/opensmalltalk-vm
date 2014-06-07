"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf


"
Class {
	#name : #Win32x86SqueakStackSpurConfig,
	#superclass : #CPlatformConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#instVars : [
		'buildType'
	],
	#category : #'CMakeVMMakerSqueak-Win32x86'
}

{ #category : #'squeak compatibility' }
Win32x86SqueakStackSpurConfig >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #'squeak compatibility' }
Win32x86SqueakStackSpurConfig >> buildDirName [
	buildType isNil
		ifTrue:[^self dirBuildPlatform, self dirBuildLanguageVMMM, 'build']
		ifFalse:[^self dirBuildPlatform, self dirBuildLanguageVMMM, buildType asString]
]

{ #category : #'squeak compatibility' }
Win32x86SqueakStackSpurConfig >> buildType: aSymbol [
	buildType:= aSymbol
]

{ #category : #cmake }
Win32x86SqueakStackSpurConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackSpur
]

{ #category : #cmake }
Win32x86SqueakStackSpurConfig >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirWin32x86
]

{ #category : #'as yet unclassified' }
Win32x86SqueakStackSpurConfig >> todo [
	self flag:'tty'
]

{ #category : #'squeak compatibility' }
Win32x86SqueakStackSpurConfig >> topDir [
		^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
]
