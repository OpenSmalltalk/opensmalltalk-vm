"
A SqueakSunOS32x86CogConfig is xxxxxxxxx.


usage: 
SqueakSunOS32x86CogConfig generate
or
SqueakSunOS32x86CogConfig generateWithSources
or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me
"
Class {
	#name : #SqueakSunOS32x86Config,
	#superclass : #CPlatformConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#instVars : [
		'buildType',
		'generateForAssert',
		'generateForDebug',
		'generateForDebugWithHeartbeatTimer',
		'generateForDebugMultiThreadedFFI',
		'generateForReleaseHeartbeatTimer',
		'generateForReleaseMultiThreadedFFI',
		'generateForAssertHeartbeatTimer'
	],
	#category : #'CMakeVMMakerSqueak-SunOS32x86'
}

{ #category : #cmake }
SqueakSunOS32x86Config >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default  noBuildConfigurations

]

{ #category : #'squeak compatibility' }
SqueakSunOS32x86Config >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #'squeak compatibility' }
SqueakSunOS32x86Config >> buildDirName [
	buildType isNil
		ifTrue:[^self dirBuildPlatform, FileDirectory slash, self dirBuildLanguageVMMM, FileDirectory slash, 'build']
		ifFalse:[^self dirBuildPlatform, FileDirectory slash, self dirBuildLanguageVMMM, FileDirectory slash, buildType asString]
]

{ #category : #'squeak compatibility' }
SqueakSunOS32x86Config >> buildType: aSymbol [
	buildType:= aSymbol
]

{ #category : #cmake }
SqueakSunOS32x86Config >> configureForAssert [
	generateForAssert := true

]

{ #category : #cmake }
SqueakSunOS32x86Config >> configureForAssertWithHeartbeatTimer [
	generateForAssertHeartbeatTimer := true.

]

{ #category : #cmake }
SqueakSunOS32x86Config >> configureForDebug [
	generateForDebug := true

]

{ #category : #cmake }
SqueakSunOS32x86Config >> configureForDebugMultiThreadedFFI [
	generateForDebugMultiThreadedFFI := true

]

{ #category : #cmake }
SqueakSunOS32x86Config >> configureForDebugWithHeartbeatTimer [
	generateForDebugWithHeartbeatTimer := true

]

{ #category : #cmake }
SqueakSunOS32x86Config >> configureForRelease [
	"this variable is in pharo class CPlatformConfig"
	generateForRelease := true.

]

{ #category : #cmake }
SqueakSunOS32x86Config >> configureForReleaseHeartbeatTimer [
	generateForReleaseHeartbeatTimer := true.

]

{ #category : #cmake }
SqueakSunOS32x86Config >> configureForReleaseMultiThreadedFFI [
	generateForReleaseMultiThreadedFFI := true
]

{ #category : #plugins }
SqueakSunOS32x86Config >> defaultExternalPlugins [
	^#(	)
]

{ #category : #plugins }
SqueakSunOS32x86Config >> defaultInternalPlugins [
	^#(	)
]

{ #category : #cmake }
SqueakSunOS32x86Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self required
]

{ #category : #cmake }
SqueakSunOS32x86Config >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirSunOS32x86
]

{ #category : #cmake }
SqueakSunOS32x86Config >> excludeFromBuild [
	^true

]

{ #category : #'initialize-release' }
SqueakSunOS32x86Config >> initialize [
	super initialize.
	"this should be in my superclass, but I do not have permission to modify it. tty"
	 generateForAssert:= generateForAssertHeartbeatTimer:= generateForDebug :=generateForDebugWithHeartbeatTimer:= generateForDebugMultiThreadedFFI:= generateForReleaseHeartbeatTimer:= generateForReleaseMultiThreadedFFI:=false
]

{ #category : #'squeak compatibility' }
SqueakSunOS32x86Config >> outputDir [
	^ outputDir ifNil: [ outputDir := (self topDir / self outputDirName) ]	

]

{ #category : #'squeak compatibility' }
SqueakSunOS32x86Config >> srcDir [
		^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'src' )]
]

{ #category : #'as yet unclassified' }
SqueakSunOS32x86Config >> todo [
	self flag:'tty'
]

{ #category : #'squeak compatibility' }
SqueakSunOS32x86Config >> topDir [
		^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
]
