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
	#superclass : #SqueakMacintoshConfig,
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
SqueakMacOSConfig >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirMacOS
]

{ #category : #cmake }
SqueakMacOSConfig >> excludeFromBuild [
	^true

]

{ #category : #'source files' }
SqueakMacOSConfig >> extraSources [
	" mac VM using some unix sources"
	
	^ 
	'${platformsDir}/unix/plugins/SocketPlugin/sqUnixSocket.c 
	${platformsDir}/unix/vm/aio.c 
	${platformsDir}/unix/plugins/AsynchFilePlugin/sqUnixAsynchFile.c
	${platformsDir}/unix/vm/sqUnixHeartbeat.c
	${platformsDir}/unix/vm/sqUnixVMProfile.c
	${platformsDir}/unix/vm/sqUnixThreads.c
	${resources}'
]
