"
A SqueakIA32BochsConfig is a Squeak Compatibility Layer between the Pharo code in CMakeVMMaker and CMakeVMakerSqueak.

I exist because modifying the pharo tree is verbotten as of 2014.06.10
"
Class {
	#name : #SqueakIA32BochsConfig,
	#superclass : #CPlatformConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#instVars : [
		'buildType',
		'generateForAssert',
		'generateForAssertWithHeartbeatTimer',
		'generateForDebug',
		'generateForDebugWithHeartbeatTimer',
		'generateForDebugMultiThreadedFFI',
		'generateForReleaseHeartbeatTimer',
		'generateForReleaseMultiThreadedFFI',
		'generateForAssertHeartbeatTimer'
	],
	#category : #'CMakeVMMakerSqueak-IA32-Bochs'
}

{ #category : #accessing }
SqueakIA32BochsConfig class >> availableBuilds [
	"SqueakCMakeVMMakerAbstractBuilder  allBuildConfigurations
	^#(#assert #debug  #release )"
	^SqueakCMakeVMMakerAbstractBuilder noBuildConfigurations
]

{ #category : #cmake }
SqueakIA32BochsConfig >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default  noBuildConfigurations

]

{ #category : #'squeak compatibility' }
SqueakIA32BochsConfig >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #'squeak compatibility' }
SqueakIA32BochsConfig >> buildDirName [
	buildType isNil
		ifTrue:[^self dirBuildPlatform, FileDirectory slash, self dirBuildLanguageVMMM, FileDirectory slash, 'build']
		ifFalse:[^self dirBuildPlatform, FileDirectory slash, self dirBuildLanguageVMMM, FileDirectory slash, buildType asString]
]

{ #category : #'squeak compatibility' }
SqueakIA32BochsConfig >> buildType: aSymbol [
	buildType:= aSymbol
]

{ #category : #cmake }
SqueakIA32BochsConfig >> configureForAssert [
	generateForAssert := true

]

{ #category : #cmake }
SqueakIA32BochsConfig >> configureForAssertWithHeartbeatTimer [
	generateForAssertHeartbeatTimer := true.

]

{ #category : #cmake }
SqueakIA32BochsConfig >> configureForDebug [
	generateForDebug := true

]

{ #category : #cmake }
SqueakIA32BochsConfig >> configureForDebugMultiThreadedFFI [
	generateForDebugMultiThreadedFFI := true

]

{ #category : #cmake }
SqueakIA32BochsConfig >> configureForDebugWithHeartbeatTimer [
	generateForDebugWithHeartbeatTimer := true

]

{ #category : #cmake }
SqueakIA32BochsConfig >> configureForNoBuildType [
		 generateForAssert:= generateForAssertHeartbeatTimer:= generateForDebug :=generateForDebugWithHeartbeatTimer:= generateForDebugMultiThreadedFFI:= generateForReleaseHeartbeatTimer:= generateForReleaseMultiThreadedFFI:=false
]

{ #category : #cmake }
SqueakIA32BochsConfig >> configureForRelease [
	"this variable is in pharo class CPlatformConfig"
	generateForRelease := true.

]

{ #category : #cmake }
SqueakIA32BochsConfig >> configureForReleaseHeartbeatTimer [
	generateForReleaseHeartbeatTimer := true.

]

{ #category : #cmake }
SqueakIA32BochsConfig >> configureForReleaseMultiThreadedFFI [
	generateForReleaseMultiThreadedFFI := true

]

{ #category : #plugins }
SqueakIA32BochsConfig >> defaultExternalPlugins [
	^ #()
]

{ #category : #plugins }
SqueakIA32BochsConfig >> defaultInternalPlugins [
	^ #()
]

{ #category : #cmake }
SqueakIA32BochsConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur the default is squeak.cog.v3"
	^self required
]

{ #category : #cmake }
SqueakIA32BochsConfig >> dirBuildPlatform [
	^self dirIA32Bochs
]

{ #category : #cmake }
SqueakIA32BochsConfig >> excludeFromBuild [
	^true

]

{ #category : #'initialize-release' }
SqueakIA32BochsConfig >> initialize [
	super initialize.
	"this should be in my superclass, but I do not have permission to modify it. tty"
	 generateForAssert:= generateForAssertHeartbeatTimer:= generateForDebug :=generateForDebugWithHeartbeatTimer:= generateForDebugMultiThreadedFFI:= generateForReleaseHeartbeatTimer:= generateForReleaseMultiThreadedFFI:=false
]

{ #category : #'squeak compatibility' }
SqueakIA32BochsConfig >> outputDir [
	^ outputDir ifNil: [ outputDir := (self topDir / self outputDirName) ]	
]

{ #category : #'squeak compatibility' }
SqueakIA32BochsConfig >> srcDir [
		^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'src' )]
]

{ #category : #'squeak compatibility' }
SqueakIA32BochsConfig >> topDir [
		^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
]
