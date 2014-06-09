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
	#name : #SqueakSunOS32x86CogConfig,
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
SqueakSunOS32x86CogConfig >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default  noBuildConfigurations

]

{ #category : #'squeak compatibility' }
SqueakSunOS32x86CogConfig >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #'squeak compatibility' }
SqueakSunOS32x86CogConfig >> buildDirName [
	buildType isNil
		ifTrue:[^self dirBuildPlatform, self dirBuildLanguageVMMM, 'build']
		ifFalse:[^self dirBuildPlatform, self dirBuildLanguageVMMM, buildType asString]
]

{ #category : #'squeak compatibility' }
SqueakSunOS32x86CogConfig >> buildType: aSymbol [
	buildType:= aSymbol
]

{ #category : #cmake }
SqueakSunOS32x86CogConfig >> configureForAssert [
	generateForAssert := true

]

{ #category : #cmake }
SqueakSunOS32x86CogConfig >> configureForAssertWithHeartbeatTimer [
	generateForAssertHeartbeatTimer := true.

]

{ #category : #cmake }
SqueakSunOS32x86CogConfig >> configureForDebug [
	generateForDebug := true

]

{ #category : #cmake }
SqueakSunOS32x86CogConfig >> configureForDebugMultiThreadedFFI [
	generateForDebugMultiThreadedFFI := true

]

{ #category : #cmake }
SqueakSunOS32x86CogConfig >> configureForDebugWithHeartbeatTimer [
	generateForDebugWithHeartbeatTimer := true

]

{ #category : #cmake }
SqueakSunOS32x86CogConfig >> configureForRelease [
	"this variable is in pharo class CPlatformConfig"
	generateForRelease := true.

]

{ #category : #cmake }
SqueakSunOS32x86CogConfig >> configureForReleaseHeartbeatTimer [
	generateForReleaseHeartbeatTimer := true.

]

{ #category : #cmake }
SqueakSunOS32x86CogConfig >> configureForReleaseMultiThreadedFFI [
	generateForReleaseMultiThreadedFFI := true
]

{ #category : #plugins }
SqueakSunOS32x86CogConfig >> defaultExternalPlugins [
	^#(	)
]

{ #category : #plugins }
SqueakSunOS32x86CogConfig >> defaultInternalPlugins [
	^#(	)
]

{ #category : #cmake }
SqueakSunOS32x86CogConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogV3
]

{ #category : #cmake }
SqueakSunOS32x86CogConfig >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirSunOS32x86
]

{ #category : #'initialize-release' }
SqueakSunOS32x86CogConfig >> initialize [
	super initialize.
	"this should be in my superclass, but I do not have permission to modify it. tty"
	 generateForAssert:= generateForAssertHeartbeatTimer:= generateForDebug :=generateForDebugWithHeartbeatTimer:= generateForDebugMultiThreadedFFI:= generateForReleaseHeartbeatTimer:= generateForReleaseMultiThreadedFFI:=false
]

{ #category : #'squeak compatibility' }
SqueakSunOS32x86CogConfig >> outputDir [
	^ outputDir ifNil: [ outputDir := (self topDir / self outputDirName) ]	

]

{ #category : #'squeak compatibility' }
SqueakSunOS32x86CogConfig >> srcDir [
		^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'src' )]
]

{ #category : #'as yet unclassified' }
SqueakSunOS32x86CogConfig >> todo [
	self flag:'tty'
]

{ #category : #'squeak compatibility' }
SqueakSunOS32x86CogConfig >> topDir [
		^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
]
