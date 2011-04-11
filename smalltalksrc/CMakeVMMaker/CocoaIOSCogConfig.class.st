Class {
	#name : #CocoaIOSCogConfig,
	#superclass : #CocoaIOSConfig,
	#category : #'CMakeVMMaker-IOS'
}

{ #category : #'bundle strings' }
CocoaIOSCogConfig >> CFBundleIconFile [

	"An application icon"
	^ 'Cog.icns'
]

{ #category : #'bundle strings' }
CocoaIOSCogConfig >> CFBundleVersion [
	"An application version"
	^ '6.0-pre'
]

{ #category : #settings }
CocoaIOSCogConfig >> compilerFlagsDebug [
	^#('-g3' '-O0' '-fvisibility=hidden' '-funroll-loops' '-fasm-blocks' '-finline-functions' '-mfpmath=sse' '-fomit-frame-pointer' '-march=pentium-m' '-mtune=prescott' '-falign-functions=16' '-fno-gcse' '-fno-cse-follow-jumps' '-std=gnu99' '-DBUILD_FOR_OSX' '-DUSE_INLINE_MEMORY_ACCESSORS' '-DLSB_FIRST' '-DUSE_INLINE_MEMORY_ACCESSORS' '-DHAVE_SYS_TIME_H' '-DHAVE_NANOSLEEP' '-DNDEBUG=1' '-DDEBUGVM=0' '-DCOGMTVM=0' '-DUSE_GLOBAL_STRUCT=0' '-DBASE_HEADER_SIZE=4')
]

{ #category : #settings }
CocoaIOSCogConfig >> compilerFlagsRelease [ 
	^#('-g3' '-Os' '-fvisibility=hidden' '-funroll-loops' '-fasm-blocks' '-finline-functions' '-mfpmath=sse' '-fomit-frame-pointer' '-march=pentium-m' '-mtune=prescott' '-falign-functions=16' '-fno-gcse' '-fno-cse-follow-jumps' '-std=gnu99' '-DBUILD_FOR_OSX' '-DUSE_INLINE_MEMORY_ACCESSORS' '-DLSB_FIRST' '-DUSE_INLINE_MEMORY_ACCESSORS' '-DHAVE_SYS_TIME_H' '-DHAVE_NANOSLEEP' '-DNDEBUG=1' '-DDEBUGVM=0' '-DCOGMTVM=0' '-DUSE_GLOBAL_STRUCT=0' '-DBASE_HEADER_SIZE=4')
]

{ #category : #'plugin extra rules' }
CocoaIOSCogConfig >> configureFFIPlugin: maker [
	"extra rules for FFIPlugin"

	
	"Never generate this plugin. Because it is a legacy code.
	For Cog FFI, use ReentrantFFIPlugin  (ReentrantIA32FFIPlugin for x86) "
	
	maker doNotGenerate: true.
]

{ #category : #plugins }
CocoaIOSCogConfig >> configureHostWindowPlugin: maker [
	super configureHostWindowPlugin: maker.
	maker includeDirectories: '${platformsDir}/Cross/plugins/HostWindowPlugin'.
]

{ #category : #'source files' }
CocoaIOSCogConfig >> crossSources [ 
	^super crossSources, #(
	'sqExternalSemaphores.c'
	'sqHeapMap.c'
	'sqTicker.c')
]

{ #category : #plugins }
CocoaIOSCogConfig >> defaultExternalPlugins [ 
	^(Array with: self ffiPluginName),
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
		LocalePlugin)
]

{ #category : #plugins }
CocoaIOSCogConfig >> defaultInternalPlugins [
	^ #(
		ADPCMCodecPlugin
		BMPReadWriterPlugin 
		BalloonEnginePlugin 
		BitBltSimulation 
		"ClipboardExtendedPlugin"
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
		)
]

{ #category : #'source files' }
CocoaIOSCogConfig >> extraSources [
	" mac VM using some unix sources "
	
	^super extraSources,'
	${platformsDir}/unix/vm/aio.c 
	${platformsDir}/unix/vm/sqUnixHeartbeat.c 
	${platformsDir}/unix/vm/sqUnixVMProfile.c 
	${platformsDir}/unix/vm/sqUnixThreads.c '
]

{ #category : #plugins }
CocoaIOSCogConfig >> ffiPluginName [ 
	^#FFIPlugin 
]

{ #category : #'source files' }
CocoaIOSCogConfig >> platformSources [
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
		'OSX/sqSqueakOSXNSView.m'
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
CocoaIOSCogConfig >> setExtraTargetProperties: maker [
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

	maker 
		cmd: 'set_source_files_properties' 
		params: '${resources} PROPERTIES MACOSX_PACKAGE_LOCATION Resources'.
			
	(maker buildDir forceNewFileNamed: self prefixHeaderFileName) 
		nextPutAll: self precompiledHeaders;
		close.
	maker addXCodeProperty: 'GCC_PREFIX_HEADER' value: '${buildDir}/', self prefixHeaderFileName.

	maker 
		addXCodeProperty: 'PER_ARCH_CFLAGS_i386' value: '-DLSB_FIRST -mfpmath=sse -finline-functions  -fomit-frame-pointer -fno-cse-follow-jumps -fno-gcse -mtune=prescott -march=pentium-m -falign-functions=16'.
		
	maker 
		addXCodeProperty: 'GCC_VERSION' value: '4.2'.

	maker 
		cmd: 'set_target_properties' 
		params: self executableName, ' PROPERTIES COMPILE_FLAGS "-include \"', (self topDir / 'build' / self prefixHeaderFileName) fullName, '\""'. 
	
	maker set: 'EXECUTABLE_OUTPUT_PATH' toString: self outputDir.
]

{ #category : #'source files' }
CocoaIOSCogConfig >> standardIncludes [
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
