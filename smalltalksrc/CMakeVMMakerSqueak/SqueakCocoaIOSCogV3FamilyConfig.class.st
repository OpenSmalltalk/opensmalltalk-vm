"
This is an abstract class for all Mac Cocoa Cog VMs family. That is, for all CogVMS (StackVM, CogVM, CogMTVM, etc). 

I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf


I am not meant to be built.

SqueakIOSBuilder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp







"
Class {
	#name : #SqueakCocoaIOSCogV3FamilyConfig,
	#superclass : #SqueakCocoaIOSConfig,
	#category : #'CMakeVMMakerSqueak-IOS'
}

{ #category : #'bundle strings' }
SqueakCocoaIOSCogV3FamilyConfig >> CFBundleIconFile [

	"An application icon"
	^ 'Cog.icns'
]

{ #category : #'bundle strings' }
SqueakCocoaIOSCogV3FamilyConfig >> CFBundleVersion [
	"An application version"
	^ '6.0-pre'
]

{ #category : #settings }
SqueakCocoaIOSCogV3FamilyConfig >> commonCompilerFlags [
	^super commonCompilerFlags,  #(
	"CLANG >>"
	'-fwrapv' "Non optimization of stackoverflow (to allow number conversions)"
	'-Wno-return-type' "to avoid clang to complain about plugins that do not return properly."	
	'-Qunused-arguments'
	"CLANG <<"
	'-funroll-loops' 
	'-fasm-blocks' 
	'-fno-inline-functions' 
	'-mfpmath=sse' 
	'-march=pentium-m' 
	'-mtune=prescott' 
	'-falign-functions=16' 
	'-fno-gcse' 
	'-std=gnu99'
	'-fmessage-length=0' 
	'-fpascal-strings' 
	'-DBUILD_FOR_OSX' 
	"'-DUSE_INLINE_MEMORY_ACCESSORS=1' "
	'-DLSB_FIRST' 
	'-DHAVE_SYS_TIME_H' 
	'-DHAVE_NANOSLEEP' 
	'-DCOGMTVM=0' 
	'-DUSE_GLOBAL_STRUCT=0' 
	'-DBASE_HEADER_SIZE=4'
	'-DENABLE_FAST_BLT')
]

{ #category : #settings }
SqueakCocoaIOSCogV3FamilyConfig >> compilerFlagsDebug [
	^#('-g3' '-O0' '-DDEBUGVM=1')
]

{ #category : #settings }
SqueakCocoaIOSCogV3FamilyConfig >> compilerFlagsRelease [ 
	^#('-g0' '-O3' '-fomit-frame-pointer' '-DNDEBUG' '-DDEBUGVM=0')
]

{ #category : #'plugin extra rules' }
SqueakCocoaIOSCogV3FamilyConfig >> configureFFIPlugin: maker [
	"extra rules for FFIPlugin"

	
	"Never generate this plugin. Because it is a legacy code.
	For Cog FFI, use ReentrantFFIPlugin  (ReentrantIA32FFIPlugin for x86) "
	
	maker doNotGenerate: true.
]

{ #category : #'plugin extra rules' }
SqueakCocoaIOSCogV3FamilyConfig >> configureHostWindowPlugin: maker [
	super configureHostWindowPlugin: maker.
	maker includeDirectories: '${platformsDir}/Cross/plugins/HostWindowPlugin'.
]

{ #category : #'plugin extra rules' }
SqueakCocoaIOSCogV3FamilyConfig >> configureQuicktimePlugin: maker [
	"extra rules for QuicktimePlugin"
	
	maker includeDirectories: '${platformsDir}/Cross/plugins/QuicktimePlugin'.
]

{ #category : #'plugin extra rules' }
SqueakCocoaIOSCogV3FamilyConfig >> configureSqueakSSLPlugin: maker [
	maker addPlatformSources: #('sqMacSSL.c').
]

{ #category : #'plugin extra rules' }
SqueakCocoaIOSCogV3FamilyConfig >> configureSystemInfoPlugin: maker [
	maker includeDirectories: '${platformsDir}/Cross/plugins/SystemInfoPlugin'.
	maker addPlatformSources: #('sqSystemInfo.m' ).
]

{ #category : #'plugin extra rules' }
SqueakCocoaIOSCogV3FamilyConfig >> configureUnixAioPlugin: maker [
	maker includeDirectories: '${crossDir}/plugins/FilePlugin'.
	maker includeDirectories: '${platformsDir}/Cross/plugins/SocketPlugin'.
]

{ #category : #'plugin extra rules' }
SqueakCocoaIOSCogV3FamilyConfig >> configureUnixOSProcessPlugin: maker [
	super configureHostWindowPlugin: maker.
	maker includeDirectories: '${platformsDir}/Cross/plugins/SocketPlugin'.
]

{ #category : #'source files' }
SqueakCocoaIOSCogV3FamilyConfig >> crossSources [ 
	^super crossSources, #(
	'sqExternalSemaphores.c'
	'sqHeapMap.c'
	'sqTicker.c')
]

{ #category : #plugins }
SqueakCocoaIOSCogV3FamilyConfig >> defaultExternalPlugins [ 
	^(self versionExternalPlugins),
		#(
		UUIDPlugin
		FloatMathPlugin
		AsynchFilePlugin
		Mpeg3Plugin
		CroquetPlugin
		JoystickTabletPlugin
		B3DAcceleratorPlugin
		JPEGReadWriter2Plugin 
		JPEGReaderPlugin
		RePlugin
		LocalePlugin
		ObjectiveCPlugin
		QuicktimePlugin
	"	TestOSAPlugin  Broken?"
		SqueakSSLPlugin
		SerialPlugin
		MIDIPlugin
	)
]

{ #category : #plugins }
SqueakCocoaIOSCogV3FamilyConfig >> defaultInternalPlugins [
	^ #(
		ADPCMCodecPlugin
		BMPReadWriterPlugin 
		BalloonEnginePlugin 
		BitBltSimulation 
		ClipboardExtendedPlugin
		DSAPlugin 
		DeflatePlugin 
		DropPlugin 
		FFTPlugin 
		FilePlugin 
		FloatArrayPlugin 
		GeniePlugin 
		HostWindowPlugin 
		"JPEGReadWriter2Plugin 
		JPEGReaderPlugin" 
		KlattSynthesizerPlugin
		LargeIntegersPlugin 
		Matrix2x3Plugin 
		MiscPrimitivePlugin 
		"RePlugin" 
		SecurityPlugin 
		SocketPlugin 
		SoundCodecPlugin 
		SoundGenerationPlugin 
		SoundPlugin
		StarSqueakPlugin 
		SurfacePlugin 
		UnixAioPlugin
		UnixOSProcessPlugin
		)
]

{ #category : #cmake }
SqueakCocoaIOSCogV3FamilyConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
SqueakCocoaIOSCogV3FamilyConfig >> executableName [
	^ self vmCogExecutableName
]

{ #category : #'source files' }
SqueakCocoaIOSCogV3FamilyConfig >> extraSources [
	" mac VM using some unix sources "
	
	^super extraSources,'
	${platformsDir}/unix/vm/aio.c 
	${platformsDir}/unix/vm/sqUnixHeartbeat.c 
	${platformsDir}/unix/vm/sqUnixVMProfile.c 
	${platformsDir}/unix/vm/sqUnixThreads.c '
]

{ #category : #'source files' }
SqueakCocoaIOSCogV3FamilyConfig >> platformSources [
	"files added from platform/iOS/vm dir "
	^ #(
		'Common/main.m'
		"'Common/aio.c'"
		'Common/Classes/Queue.m'
		'Common/Classes/sqMacV2Time.c'
		'Common/Classes/sqSqueakAppDelegate.m'
		'Common/Classes/sqSqueakFileDirectoryAPI.m'
		'Common/Classes/sqSqueakFileDirectoryInterface.m'
		'Common/Classes/sqSqueakInfoPlistInterface.m'
		'Common/Classes/sqSqueakMainApp.m'
		'Common/Classes/sqSqueakMainApplication.m'
		'Common/Classes/sqSqueakMainApplication+attributes.m'
		'Common/Classes/sqSqueakAttributesAPI.m'
		'Common/Classes/sqSqueakMainApplication+events.m'
		'Common/Classes/sqSqueakEventsAPI.m'
		'Common/Classes/sqSqueakMainApplication+imageReadWrite.m'
		'Common/Classes/sqSqueakMainApplication+sound.m'
		'Common/Classes/sqSqueakSoundAPI.m'
		'Common/Classes/sqSqueakMainApplication+vmAndImagePath.m'
		'Common/Classes/sqSqueakVmAndImagePathAPI.m'
		'Common/Classes/sqSqueakMainApplication+screen.m'
		'Common/Classes/sqSqueakScreenAPI.m'
		'Common/Classes/sqSqueakScreenAndWindow.m'
		'Common/Classes/sqSqueakCursorAPI.m'
		'Common/Classes/sqSqueakMainApplication+cursor.m'
		'OSX/SqueakOSXAppDelegate.m'
		'OSX/sqMacV2Browser.m'
		'OSX/sqMacUnixExternalPrims.m'
		'OSX/sqSqueakOSXApplication.m'
		'OSX/sqSqueakOSXFileDirectoryInterface.m'
		'OSX/sqSqueakOSXApplication+attributes.m'
		'OSX/sqSqueakOSXInfoPlistInterface.m'
		'OSX/sqSqueakOSXApplication+imageReadWrite.m'
		'OSX/sqSqueakOSXScreenAndWindow.m'
		'OSX/sqSqueakOSXCGView.m'
		'OSX/sqSqueakOSXOpenGLView.m'
		'OSX/SqViewClut.m'
		'OSX/BitMapConversionLogicFromX11.c'
		'OSX/SqViewBitmapConversion.m'
		'OSX/macintoshosxextra.c'
		'OSX/sqSqueakOSXApplication+cursor.m'
		'OSX/sqSqueakOSXApplication+events.m'
		'OSX/keyBoardStrokeDetails.m'
		'OSX/SqueakOSXApplication.m'
		'OSX/sqSqueakOSXClipboardAPI.m'
		'OSX/sqSqueakOSXApplication+clipboard.m'
		'OSX/sqSqueakOSXDropAPI.m'
		'iPhone/sqMacV2Memory.c'
		'iPhone/osExports.c'
	  	'Common/Classes/sqSqueakScreenAPI.m')
]

{ #category : #accessing }
SqueakCocoaIOSCogV3FamilyConfig >> sdkVersion [ 
	^'10.6'
]

{ #category : #settings }
SqueakCocoaIOSCogV3FamilyConfig >> setExtraTargetProperties: maker [
	| plist |

	maker addFrameworks: self frameworks.

	" generated and add Info.plist file "
	plist := self plistFile.

	(FileStream forceNewFileNamed: (maker buildDir / 'Info.plist') fullName) 
		nextPutAll: plist; 
		close.

	maker 
		addProperty: 'MACOSX_BUNDLE_INFO_PLIST' 
		value: '${buildDir}/Info.plist'.  

	(FileStream forceNewFileNamed: (maker buildDir / self prefixHeaderFileName) fullName )
		nextPutAll: self precompiledHeaders;
		close.
	maker addXCodeProperty: 'GCC_PREFIX_HEADER' value: '${buildDir}/', self prefixHeaderFileName.

	maker 
		addXCodeProperty: 'PER_ARCH_CFLAGS_i386' value: '-DLSB_FIRST -mfpmath=sse -finline-functions  -fno-gcse -mtune=prescott -march=pentium-m -falign-functions=16'.
		
	"maker 
		addXCodeProperty: 'GCC_VERSION' value: '4.3'."

	maker 
		cmd: 'set_target_properties' 
		params: self executableName, ' PROPERTIES COMPILE_FLAGS "-include \"', (self buildDir / self prefixHeaderFileName) fullName, '\""'. 
		
"	maker set: 'CMAKE_C_COMPILER' to: '/usr/bin/gcc-4.2'.
	maker set: 'CMAKE_CXX_COMPILER' to: '/usr/bin/g++-4.2'.		
"
	maker set: 'EXECUTABLE_OUTPUT_PATH' toString: self outputDir fullName.
	maker set: 'RUNTIME_OUTPUT_DIRECTORY' toString: self outputDir fullName.
]

{ #category : #settings }
SqueakCocoaIOSCogV3FamilyConfig >> setGlobalOptions: maker [

	"set any CMake global options, before declaring a project in cmake file"
	
	maker set: 'CMAKE_C_COMPILER' to: '/usr/bin/gcc'.
	maker set: 'CMAKE_CXX_COMPILER' to: '/usr/bin/g++'.
]

{ #category : #settings }
SqueakCocoaIOSCogV3FamilyConfig >> setGlobalOptionsAfterDetermineSystem:  maker [
	maker set: 'CMAKE_OSX_DEPLOYMENT_TARGET' to: '10.5'.
	maker 
		set: 'CMAKE_OSX_SYSROOT' 
		to: '/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX', self sdkVersion, '.sdk'
]

{ #category : #settings }
SqueakCocoaIOSCogV3FamilyConfig >> setResourceProperties: maker [
	maker set: 'resourceDir' toString: self resourcesDir, '/ProjectBuilder'.

	maker 
		set: 'resources' 
		to: (String streamContents: [ :stream | 
			self  resources
				do: [ :each | 
					stream 
						nextPut: $";
						nextPutAll: '${resourceDir}/';
						nextPutAll: each;
						nextPut: $"]
				separatedBy: [ stream space ] ]).
		
	maker 
		set: 'resourcesLocaleEnglish' 
		to: '"${resourceDir}/English.lproj/InfoPlist.strings" "${resourceDir}/English.lproj/MainMenu.nib"'.

	maker 
		cmd: 'set_source_files_properties' 
		params: '${resources} PROPERTIES MACOSX_PACKAGE_LOCATION Resources'.

	maker 
		cmd: 'set_source_files_properties' 
		params: '${resourcesLocaleEnglish} PROPERTIES MACOSX_PACKAGE_LOCATION Resources/English.lproj'.


]

{ #category : #'source files' }
SqueakCocoaIOSCogV3FamilyConfig >> standardIncludes [
	^#(
	'${srcDir}/vm'
	'${platformsDir}/iOS/vm/OSX'
	'${platformsDir}/unix/vm'
	'${platformsDir}/iOS/vm/Common/Classes'
	'${platformsDir}/iOS/plugins/SoundPlugin'
	'${platformsDir}/iOS/vm/OSX/plugins/SoundPlugin'
	'${crossDir}/plugins/SoundPlugin'
	'${crossDir}/plugins/HostWindowPlugin'
	'${platformsDir}/Cross/plugins/HostWindowPlugin'
	'${platformsDir}/iOS/vm/iPhone/plugins/HostWindowPlugin' "Sources are here :("
	'${crossDir}/plugins/FilePlugin'
	)	

]

{ #category : #plugins }
SqueakCocoaIOSCogV3FamilyConfig >> versionExternalPlugins [ 
	"Cog Version Specific Plugins. Some times you can't use same plugins in a version (for instance, CogMT uses a diferent FFI, and you can't build IA32ABIPlugin in MT for now)"
	^Array 
		with: #FFIPlugin
		with: #IA32ABIPlugin
]
