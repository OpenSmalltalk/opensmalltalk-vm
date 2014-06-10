"
A SqueakMacOSConfig  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

"
Class {
	#name : #SqueakMacOSConfig,
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
		ifTrue:[^self dirBuildPlatform, self dirBuildLanguageVMMM, 'build']
		ifFalse:[^self dirBuildPlatform, self dirBuildLanguageVMMM, buildType asString]
]

{ #category : #'squeak compatibility' }
SqueakMacOSConfig >> buildType: aSymbol [
	buildType:= aSymbol
]

{ #category : #cmake }
SqueakMacOSConfig >> configureForAssert [
	generateForAssert := true

]

{ #category : #cmake }
SqueakMacOSConfig >> configureForAssertWithHeartbeatTimer [
	generateForAssertHeartbeatTimer := true.

]

{ #category : #cmake }
SqueakMacOSConfig >> configureForDebug [
	generateForDebug := true

]

{ #category : #cmake }
SqueakMacOSConfig >> configureForDebugMultiThreadedFFI [
	generateForDebugMultiThreadedFFI := true

]

{ #category : #cmake }
SqueakMacOSConfig >> configureForDebugWithHeartbeatTimer [
	generateForDebugWithHeartbeatTimer := true

]

{ #category : #cmake }
SqueakMacOSConfig >> configureForRelease [
	"this variable is in pharo class CPlatformConfig"
	generateForRelease := true.

]

{ #category : #cmake }
SqueakMacOSConfig >> configureForReleaseHeartbeatTimer [
	generateForReleaseHeartbeatTimer := true.

]

{ #category : #cmake }
SqueakMacOSConfig >> configureForReleaseMultiThreadedFFI [
	generateForReleaseMultiThreadedFFI := true

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
	^ outputDir ifNil: [ outputDir := (self topDir / self outputDirName) ]	
]

{ #category : #'squeak compatibility' }
SqueakMacOSConfig >> srcDir [
		^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'src' )]
]

{ #category : #'squeak compatibility' }
SqueakMacOSConfig >> topDir [
		^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
]
