"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf



"
Class {
	#name : #Win32x86SqueakCogSpurConfig,
	#superclass : #CPlatformConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#instVars : [
		'buildType'
	],
	#category : #'CMakeVMMakerSqueak-Win32x86'
}

{ #category : #'squeak compatibility' }
Win32x86SqueakCogSpurConfig >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #'squeak compatibility' }
Win32x86SqueakCogSpurConfig >> buildDirName [
	buildType isNil
		ifTrue:[^self dirBuildPlatform, self dirBuildLanguageVMMM, 'build']
		ifFalse:[^self dirBuildPlatform, self dirBuildLanguageVMMM, buildType asString]
]

{ #category : #'squeak compatibility' }
Win32x86SqueakCogSpurConfig >> buildType: aSymbol [
	buildType:= aSymbol
]

{ #category : #cmake }
Win32x86SqueakCogSpurConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogSpur
]

{ #category : #cmake }
Win32x86SqueakCogSpurConfig >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirWin32x86
]

{ #category : #'as yet unclassified' }
Win32x86SqueakCogSpurConfig >> todo [
	self flag:'tty'
]

{ #category : #'squeak compatibility' }
Win32x86SqueakCogSpurConfig >> topDir [
		^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
]
