"
A SqueakMacOSConfig  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

"
Class {
	#name : #SqueakMacOSConfig,
	#superclass : #CPlatformConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#instVars : [
		'buildType'
	],
	#category : #'CMakeVMMakerSqueak-MacOS'
}

{ #category : #'as yet unclassified' }
SqueakMacOSConfig class >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder allBuildConfigurations
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
	^self squeakCogV3
]

{ #category : #cmake }
SqueakMacOSConfig >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirMacOS
]

{ #category : #'squeak compatibility' }
SqueakMacOSConfig >> topDir [
		^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
]
