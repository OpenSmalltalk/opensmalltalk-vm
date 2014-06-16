"
A SqueakSunOS32x86CogConfig provides common informatin for my subclasses.

I am not meant to be built.

SqueakSunOS32x86Builder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp
"
Class {
	#name : #SqueakSunOS32x86Config,
	#superclass : #CPlatformConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#instVars : [
		'buildType',
		'generateBuild',
		'generateBuildAssert',
		'generateBuildAssertITimerHeartbeat',
		'generateBuildDebug',
		'generateBuildDebugITimerHeartbeat',
		'generateBuildDebugMultiThreaded',
		'generateBuildIHeartbeatTimer',
		'generateBuildMultiThreaded',
		'generateBuildMultiThreadedAssert',
		'generateBuildMultiThreadedDebug'
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

{ #category : #'compiler flags' }
SqueakSunOS32x86Config >> compilerFlags [
	|d commonFlags flags|
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self compilerFlagsBuild];
		at: #buildAssert  put: [self compilerFlagsAssert];
		at: #buildAssertITimerHeartbeat  put: [self compilerFlagsAssertITimerHeartbeat];
            at:#buildDebug  put: [self compilerFlagsDebug];   "located in CMakeVMMaker CPlatformConfig"
		at: #buildDebugITimerHeartbeat  put: [self compilerFlagsDebugITimerHeartbeat ];
		at: #buildDebugMultiThreaded  put: [self compilerFlagsDebugMultiThreaded];
		at: #buildITimerHeartbeat  put: [self compilerFlagsIHeartbeatTimer];
		at: #buildMultiThreaded  put: [self compilerFlagsMultiThreaded ];
		at: #buildMultiThreadedAssert  put: [self compilerFlagsMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self compilerFlagsMultiThreadedDebug ];
		at: #buildNone put:[self compilerFlagsNoBuildType].

    flags:= String streamContents: [ :stream |
	 (((d at:  buildType) value)  collect: #withBlanksTrimmed as: Set)
		asStringOn: stream 
		delimiter:' '].

    commonFlags:=String streamContents: [ :stream |
		((self commonCompilerFlags) collect: #withBlanksTrimmed as: Set)
			asStringOn: stream 
			delimiter: ' ' ].
	^ commonFlags, ' ' ,flags.
]

{ #category : #'cmake configuration' }
SqueakSunOS32x86Config >> configureForBuildType: aSymbol [
	| d |
	"provide a concrete builder with the buildType and configureBuildX method to invoke"
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	self configureNoBuildType.                "reset all internal flags"
	d 
		at: #build 
		put: [self buildType:#build.  self configureBuild];

		at: #buildAssert 
		put: [self buildType: #buildAssert.  	self configureBuildAssert];

		at: #buildAssertITimerHeartbeat 
		put:     [ self buildType: #buildAssertITimerHeartbeat.   self configureBuildAssertITimerHeartbeat];

            at:#buildDebug 
		put: [self buildType: #buildDebug.  self configureBuildDebug];

		at: #buildDebugITimerHeartbeat 
		put:  [self buildType: #buildDebugITimerHeartbeat.   self configureBuildDebugITimerHeartbeat];

		at: #buildDebugMultiThreaded 
		put: [self buildType: #buildDebugMultiThreaded.   self configureBuildDebugMultiThreaded];

		at: #buildITimerHeartbeat 
		put: [self buildType:#buildITimerHeartbeat.    self configureBuildIHeartbeatTimer];

		at: #buildMultiThreaded 
		put:  [self buildType:#buildMultiThreaded . self configureBuildMultiThreaded];

		at: #buildMultiThreadedAssert 
		put: [self buildType: #buildMultiThreadedAssert. self configureBuildMultiThreadedAssert];

		at: #buildMultiThreadedDebug  
		put: [self buildType: #buildMultiThreadedDebug. self configureBuildMultiThreadedDebug].

     ^(d at: aSymbol).
]

{ #category : #cmake }
SqueakSunOS32x86Config >> configureNoBuildType [
			generateBuild:=generateBuildAssert:=generateBuildAssertITimerHeartbeat:=generateBuildDebug:=generateBuildDebugITimerHeartbeat:= generateBuildDebugMultiThreaded:= generateBuildIHeartbeatTimer:= generateBuildMultiThreaded:= generateBuildMultiThreadedAssert:= generateBuildMultiThreadedDebug:=false.
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
SqueakSunOS32x86Config >> dirInstall [
	"the directory of the finished product.. the place where 'make install' puts stuff.
	SystemNavigation default browseMethodsWhoseNamesContain: 'dirInstall'
      "
self required.

]

{ #category : #cmake }
SqueakSunOS32x86Config >> excludeFromBuild [
	^true

]

{ #category : #'headers generation' }
SqueakSunOS32x86Config >> generateConfigH [
	"	
	used to be: 	
		self write: self configH toFile: 'config.h'
      but with variable buildTypes we need:
"
	self write: (self generateConfigH: buildType) toFile: 'config.h'   

]

{ #category : #'initialize-release' }
SqueakSunOS32x86Config >> initialize [
	super initialize.
	"this should be in my superclass, but I do not have permission to modify it. tty"
	 generateForAssert:= generateForAssertHeartbeatTimer:= generateForDebug :=generateForDebugWithHeartbeatTimer:= generateForDebugMultiThreadedFFI:= generateForReleaseHeartbeatTimer:= generateForReleaseMultiThreadedFFI:=false
]

{ #category : #'squeak compatibility' }
SqueakSunOS32x86Config >> outputDir [

	"the directory where built binaries will be stored"
	^ outputDir ifNil: [ outputDir := (self topDir / self dirOutput/ self dirInstall) ]	


]

{ #category : #'squeak compatibility' }
SqueakSunOS32x86Config >> srcDir [
		^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'src' )]
]

{ #category : #'squeak compatibility' }
SqueakSunOS32x86Config >> topDir [
		^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
]
