"
A SqueakMacOSConfig  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf


I am not meant to be built.

SqueakMacOSBuilder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp

"
Class {
	#name : #SqueakMacOSConfig,
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
	#category : #'CMakeVMMakerSqueak-MacOS'
}

{ #category : #'as yet unclassified' }
SqueakMacOSConfig class >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default  allBuildConfigurations
]

{ #category : #cmake }
SqueakMacOSConfig >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default allBuildConfigurations copyWithoutAll:#(#assert #assertWithHeartbeatTimer #debugMultiThreadedFFI #debugWithHeartbeatTimer #releaseHeartbeatTimer )

]

{ #category : #'squeak compatibility' }
SqueakMacOSConfig >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #'squeak compatibility' }
SqueakMacOSConfig >> buildDirName [
	buildType isNil
		ifTrue:[^self dirBuildPlatform, FileDirectory slash, self dirBuildLanguageVMMM, FileDirectory slash, 'build']
		ifFalse:[^self dirBuildPlatform, FileDirectory slash, self dirBuildLanguageVMMM, FileDirectory slash, buildType asString]
]

{ #category : #'squeak compatibility' }
SqueakMacOSConfig >> buildType: aSymbol [
	buildType:= aSymbol
]

{ #category : #'compiler flags' }
SqueakMacOSConfig >> compilerFlags [
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

{ #category : #cmake }
SqueakMacOSConfig >> configureNoBuildType [
		generateBuild:=generateBuildAssert:=generateBuildAssertITimerHeartbeat:=generateBuildDebug:=generateBuildDebugITimerHeartbeat:= generateBuildDebugMultiThreaded:= generateBuildIHeartbeatTimer:= generateBuildMultiThreaded:= generateBuildMultiThreadedAssert:= generateBuildMultiThreadedDebug:=false.
]

{ #category : #plugins }
SqueakMacOSConfig >> defaultExternalPlugins [
	"cut-n-pasted with exquisite expertise from Cog/macbuild/plugin.ext"
	^#(BochsIA32Plugin 
		CroquetPlugin 
		SqueakFFIPrims 
		SqueakSSL 
		FloatArrayPlugin 
		FloatMathPlugin 
		Mpeg3Plugin 
		UnixOSProcessPlugin
		)
]

{ #category : #plugins }
SqueakMacOSConfig >> defaultInternalPlugins [
	"cut-n-past from Cog/macbuild/plugin.int"
	^#(ADPCMCodecPlugin 
		AioPlugin 
		AsynchFilePlugin 
		B3DAcceleratorPlugin 
		B2DPlugin 
		BitBltPlugin 
		BMPReadWriterPlugin 
		ZipPlugin 
		DropPlugin 
		DSAPrims 
		FFTPlugin 
		FilePlugin 
		HostWindowPlugin 
		IA32ABI 
		InternetConfigPlugin 
		JoystickTabletPlugin 
		JPEGReaderPlugin 
		JPEGReadWriter2Plugin 
		Klatt 
		LargeIntegers 
		LocalePlugin 
		MacMenubarPlugin 
		Matrix2x3Plugin 
		MIDIPlugin 
		MiscPrimitivePlugin 
		RePlugin 
		SecurityPlugin 
		SerialPlugin 
		SocketPlugin 
		SoundCodecPrims 
		SoundGenerationPlugin 
		SoundPlugin 
		StarSqueakPlugin 
		SurfacePlugin 
		UUIDPlugin 
		VMProfileMacSupportPlugin 
		)
]

{ #category : #cmake }
SqueakMacOSConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. default is squeak.cog.v3"
	^self required
]

{ #category : #cmake }
SqueakMacOSConfig >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirMacOS
]

{ #category : #cmake }
SqueakMacOSConfig >> excludeFromBuild [
	^true

]

{ #category : #'initialize-release' }
SqueakMacOSConfig >> initialize [
	super initialize.
	"this should be in my superclass, but I do not have permission to modify it. tty"
	 generateForAssert:= generateForAssertHeartbeatTimer:= generateForDebug :=generateForDebugWithHeartbeatTimer:= generateForDebugMultiThreadedFFI:= generateForReleaseHeartbeatTimer:= generateForReleaseMultiThreadedFFI:=false
]

{ #category : #'squeak compatibility' }
SqueakMacOSConfig >> outputDir [

	"the directory where built binaries will be stored"
	^ outputDir ifNil: [ outputDir := (self topDir / self dirOutput/ self dirInstall) ]	


]

{ #category : #'squeak compatibility' }
SqueakMacOSConfig >> srcDir [
		^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'src' )]
]

{ #category : #'squeak compatibility' }
SqueakMacOSConfig >> topDir [
		^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
]
