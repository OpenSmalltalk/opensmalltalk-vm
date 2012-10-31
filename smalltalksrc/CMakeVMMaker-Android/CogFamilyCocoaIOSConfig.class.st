"
This is an abstract class for all Mac Cocoa Cog VMs family. That is, for all CogVMS (StackVM, CogVM, CogMTVM, etc). 

Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #CogFamilyCocoaIOSConfig,
	#superclass : #CocoaIOSConfig,
	#category : #'CMakeVMMaker-IOS'
}

{ #category : #'bundle strings' }
CogFamilyCocoaIOSConfig >> CFBundleIconFile [

	"An application icon"
	^ 'Cog.icns'
]

{ #category : #'bundle strings' }
CogFamilyCocoaIOSConfig >> CFBundleVersion [
	"An application version"
	^ '6.0-pre'
]

{ #category : #settings }
CogFamilyCocoaIOSConfig >> commonCompilerFlags [
	^super commonCompilerFlags, 
		#(
	'-funroll-loops' 
	'-fasm-blocks' 
	'-finline-functions' 
	'-mfpmath=sse' 
	'-march=pentium-m' 
	'-mtune=prescott' 
	'-falign-functions=16' 
	'-fno-gcse' 
	'-fno-cse-follow-jumps' 
	'-std=gnu99' 
	'-DBUILD_FOR_OSX' 
	"'-DUSE_INLINE_MEMORY_ACCESSORS=1' "
	'-DLSB_FIRST' 
	'-DHAVE_SYS_TIME_H' 
	'-DHAVE_NANOSLEEP' 
	'-DCOGMTVM=0' 
	'-DUSE_GLOBAL_STRUCT=0' 
	'-DBASE_HEADER_SIZE=4')
]

{ #category : #settings }
CogFamilyCocoaIOSConfig >> compilerFlagsDebug [
	^#('-g3' '-O0' '-DDEBUGVM=1')
]

{ #category : #settings }
CogFamilyCocoaIOSConfig >> compilerFlagsRelease [ 
	^#('-g0' '-O3' '-fomit-frame-pointer' '-DNDEBUG' '-DDEBUGVM=0')
]

{ #category : #'plugin extra rules' }
CogFamilyCocoaIOSConfig >> configureFFIPlugin: maker [
	"extra rules for FFIPlugin"

	
	"Never generate this plugin. Because it is a legacy code.
	For Cog FFI, use ReentrantFFIPlugin  (ReentrantIA32FFIPlugin for x86) "
	
	maker doNotGenerate: true.
]

{ #category : #'plugin extra rules' }
CogFamilyCocoaIOSConfig >> configureHostWindowPlugin: maker [
	super configureHostWindowPlugin: maker.
	maker includeDirectories: '${platformsDir}/Cross/plugins/HostWindowPlugin'.
]

{ #category : #'plugin extra rules' }
CogFamilyCocoaIOSConfig >> configureQuicktimePlugin: maker [
	"extra rules for QuicktimePlugin"
	
	maker includeDirectories: '${platformsDir}/Cross/plugins/QuicktimePlugin'.
]

{ #category : #'plugin extra rules' }
CogFamilyCocoaIOSConfig >> configureSqueakSSLPlugin: maker [
	maker addPlatformSources: #('sqMacSSL.c').
]

{ #category : #'plugin extra rules' }
CogFamilyCocoaIOSConfig >> configureSystemInfoPlugin: maker [
	maker includeDirectories: '${platformsDir}/Cross/plugins/SystemInfoPlugin'.
	maker addPlatformSources: #('sqSystemInfo.m' ).
]

{ #category : #'plugin extra rules' }
CogFamilyCocoaIOSConfig >> configureUnixAioPlugin: maker [
	maker includeDirectories: '${crossDir}/plugins/FilePlugin'.
	maker includeDirectories: '${platformsDir}/Cross/plugins/SocketPlugin'.
]

{ #category : #'plugin extra rules' }
CogFamilyCocoaIOSConfig >> configureUnixOSProcessPlugin: maker [
	super configureHostWindowPlugin: maker.
	maker includeDirectories: '${platformsDir}/Cross/plugins/SocketPlugin'.
]

{ #category : #'source files' }
CogFamilyCocoaIOSConfig >> crossSources [ 
	^super crossSources, #(
	'sqExternalSemaphores.c'
	'sqHeapMap.c'
	'sqTicker.c')
]

{ #category : #plugins }
CogFamilyCocoaIOSConfig >> defaultExternalPlugins [ 
	^(self versionExternalPlugins),
		#(
		UUIDPlugin
		FloatMathPlugin
		AsynchFilePlugin
		SerialPlugin
		Mpeg3Plugin
		CroquetPlugin
		JoystickTabletPlugin
		MIDIPlugin
		B3DAcceleratorPlugin
		LocalePlugin
		ObjectiveCPlugin
		QuicktimePlugin
		TestOSAPlugin
		SqueakSSLPlugin
		"UnixOSProcessPlugin"
	)
]

{ #category : #plugins }
CogFamilyCocoaIOSConfig >> defaultInternalPlugins [
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
		JPEGReadWriter2Plugin 
		JPEGReaderPlugin 
		KlattSynthesizerPlugin 
		LargeIntegersPlugin 
		"MacMenubarPlugin" "This plugin is not yet ported"
		Matrix2x3Plugin 
		MiscPrimitivePlugin 
		RePlugin 
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

{ #category : #'source files' }
CogFamilyCocoaIOSConfig >> extraSources [
	" mac VM using some unix sources "
	
	^super extraSources,'
	${platformsDir}/unix/vm/aio.c 
	${platformsDir}/unix/vm/sqUnixHeartbeat.c 
	${platformsDir}/unix/vm/sqUnixVMProfile.c 
	${platformsDir}/unix/vm/sqUnixThreads.c '
]

{ #category : #'source files' }
CogFamilyCocoaIOSConfig >> platformSources [
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

{ #category : #settings }
CogFamilyCocoaIOSConfig >> setExtraTargetProperties: maker [
	| plist |

	maker addFrameworks: self frameworks.

	" generated and add Info.plist file "
	plist := self plistFile.

	(maker buildDir forceNewFileNamed: 'Info.plist') 
		nextPutAll: plist; 
		close.

	maker 
		addProperty: 'MACOSX_BUNDLE_INFO_PLIST' 
		value: '${buildDir}/Info.plist'.  

	(maker buildDir forceNewFileNamed: self prefixHeaderFileName) 
		nextPutAll: self precompiledHeaders;
		close.
	maker addXCodeProperty: 'GCC_PREFIX_HEADER' value: '${buildDir}/', self prefixHeaderFileName.

	maker 
		addXCodeProperty: 'PER_ARCH_CFLAGS_i386' value: '-DLSB_FIRST -mfpmath=sse -finline-functions  -fno-cse-follow-jumps -fno-gcse -mtune=prescott -march=pentium-m -falign-functions=16'.
		
	"maker 
		addXCodeProperty: 'GCC_VERSION' value: '4.3'."

	maker 
		cmd: 'set_target_properties' 
		params: self executableName, ' PROPERTIES COMPILE_FLAGS "-include \"', (self buildDir / self prefixHeaderFileName) fullName, '\""'. 
		
"	maker set: 'CMAKE_C_COMPILER' to: '/usr/bin/gcc-4.2'.
	maker set: 'CMAKE_CXX_COMPILER' to: '/usr/bin/g++-4.2'.		
"
	maker set: 'EXECUTABLE_OUTPUT_PATH' toString: self outputDir.
	maker set: 'RUNTIME_OUTPUT_DIRECTORY' toString: self outputDir.
]

{ #category : #settings }
CogFamilyCocoaIOSConfig >> setGlobalOptions: maker [

	"set any CMake global options, before declaring a project in cmake file"
	
	maker set: 'CMAKE_C_COMPILER' to: '/usr/bin/gcc'.
	maker set: 'CMAKE_CXX_COMPILER' to: '/usr/bin/g++'.	
	maker set: 'CMAKE_OSX_ARCHITECTURES' to: 'i386'.
	maker set: 'CMAKE_OSX_SYSROOT' to: '/'.
	
"	maker set: 'CMAKE_OSX_SYSROOT' to: '/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.6.sdk'"
]

{ #category : #settings }
CogFamilyCocoaIOSConfig >> setResourceProperties: maker [
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
CogFamilyCocoaIOSConfig >> standardIncludes [
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
CogFamilyCocoaIOSConfig >> versionExternalPlugins [ 
	"Cog Version Specific Plugins. Some times you can't use same plugins in a version (for instance, CogMT uses a diferent FFI, and you can't build IA32ABIPlugin in MT for now)"
	^Array 
		with: #FFIPlugin
		with: #IA32ABIPlugin
]
