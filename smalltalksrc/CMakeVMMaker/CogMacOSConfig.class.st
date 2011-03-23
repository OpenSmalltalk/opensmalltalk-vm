"
CogMacOSConfig generateWithSources.

This is a configuration for building Cog VM 32 bit on Mac OS.

It is using a Carbon framework , which eventually will be replaced by Cocoa. (see CocoaIOSConfig and its subclasses).
"
Class {
	#name : #CogMacOSConfig,
	#superclass : #MacOSConfig,
	#category : #'CMakeVMMaker-MacOS'
}

{ #category : #'bundle strings' }
CogMacOSConfig >> CFBundleExecutable [
	^ self executableName 
]

{ #category : #'bundle strings' }
CogMacOSConfig >> CFBundleGetInfoString [

	^ self CFBundleShortVersionString

]

{ #category : #'bundle strings' }
CogMacOSConfig >> CFBundleIconFile [

	"An application icon"
	^ 'Cog.icns'
]

{ #category : #'bundle strings' }
CogMacOSConfig >> CFBundleIdentifier [

	"A Java package style name (like 'com.myCompany.MyBundle') which is used to uniquely identify bundles."
	
	^ 'org.squeak.Cog'
]

{ #category : #'bundle strings' }
CogMacOSConfig >> CFBundleName [

	"An application name"
	^ self executableName, ' (Carbon) 32bits'
]

{ #category : #'bundle strings' }
CogMacOSConfig >> CFBundleShortVersionString [

	"An application version"
	^ self executableName, ' VM ' , self CFBundleVersion
]

{ #category : #'bundle strings' }
CogMacOSConfig >> CFBundleVersion [

	"An application version"
	^ '4.0.0'
]

{ #category : #'source generation' }
CogMacOSConfig >> cogitClass [
	"answer a class for machine code generation or nil"
	
	^ StackToRegisterMappingCogit 
]

{ #category : #'compiler flags' }
CogMacOSConfig >> commonCompilerFlags [

	"Common compiler flags"
	
	^ ' -fmessage-length=0 -Wno-trigraphs -fpascal-strings -fasm-blocks -DCOGMTVM=0 -DUSE_GLOBAL_STRUCT=0 -DTARGET_API_MAC_CARBON -DHAVE_SYS_TIME_H -mmacosx-version-min=10.5'	
	
"	^ '-arch i386 -fmessage-length=0 -Wno-trigraphs -fpascal-strings -fasm-blocks -DCOGMTVM=0 -DUSE_GLOBAL_STRUCT=0 -DTARGET_API_MAC_CARBON -DHAVE_SYS_TIME_H -mmacosx-version-min=10.5'"
]

{ #category : #'compiler flags' }
CogMacOSConfig >> compilerFlags [
	"depends on config ..."
	^ self compilerFlagsRelease
]

{ #category : #'compiler flags' }
CogMacOSConfig >> compilerFlagsDebug [

	^ self commonCompilerFlags , ' -O0 -Wmissing-prototypes -Wmissing-braces -Wparentheses -Wunused-function -Wunused-label -Wunused-parameter -Wunused-variable -Wunused-value -Wsign-compare -DDEBUG -DDEBUGVM=1 -DEXTERNALPRIMSDEBUG=1 -gdwarf-2 '
]

{ #category : #'compiler flags' }
CogMacOSConfig >> compilerFlagsRelease [
" -mdynamic-no-pic "
	^ self commonCompilerFlags , ' -gdwarf-2 -O3 -funroll-loops -ftree-vectorize -msse3 -DDEBUGVM=0 -DNDEBUG=1 -Wunused-value -Wuninitialized -falign-functions=16 -fno-gcse -mtune=prescott -march=pentium-m -mfpmath=sse -finline-functions -Wall -DUSE_INLINE_MEMORY_ACCESSORS'
]

{ #category : #'plugin extra rules' }
CogMacOSConfig >> configureDropPlugin: maker [
	"extra rules for DropPlugin"
	super configureDropPlugin: maker.  
	maker addPlatformSources: #( 'sqMacDragDrop')

]

{ #category : #'plugin extra rules' }
CogMacOSConfig >> configureFFIPlugin: maker [
	"extra rules for FFIPlugin"

	
	"Never generate this plugin. Because it is a legacy code.
	For Cog FFI, use ReentrantFFIPlugin  (ReentrantIA32FFIPlugin for x86) "
	
	maker doNotGenerate: true.
	

]

{ #category : #'plugin extra rules' }
CogMacOSConfig >> configureFilePlugin: maker [
	"extra rules for FilePlugin"

	super configureFilePlugin: maker.  
	
	maker includeDirectories: '${platformsDir}/unix/vm'.
	maker addPlatformSources: #( 'sqMacUnixFileInterface.c' 'sqMacDirectory.c')
]

{ #category : #'plugin extra rules' }
CogMacOSConfig >> configureHostWindowPlugin: maker [
	"extra rules for HostWindowPlugin"

	super configureHostWindowPlugin: maker.  
	maker addPlatformSources: #( 'sqMacHostWindow.c' )

]

{ #category : #'plugin extra rules' }
CogMacOSConfig >> configureSoundPlugin: maker [ 
	"extra rules for SoundPlugin"

	super configureSoundPlugin: maker.  
	maker includeDirectories: '${platformsDir}/unix/vm/'.
	maker addPlatformSources:
		#( 
			'sqMacAudioDeviceList.c' 
			'sqMacUnixInterfaceSound.c' 
			'sqUnixSoundMacOSXJMM.c'
		)



]

{ #category : #'plugin extra rules' }
CogMacOSConfig >> configureUUIDPlugin: maker [ 
	"extra rules for UUIDPlugin"

	super configureUUIDPlugin: maker.    
	maker addPlatformSources:
		#( 'sqMacUUID.c')



]

{ #category : #'source files' }
CogMacOSConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
		)
]

{ #category : #plugins }
CogMacOSConfig >> defaultExternalPlugins [

	^ #(
		BochsIA32Plugin
		CroquetPlugin
		ReentrantIA32FFIPlugin "SqueakFFIPrims"
		FloatArrayPlugin
		FloatMathPlugin
		Mpeg3Plugin
		"UnixOSProcessPlugin ?? "
		)
]

{ #category : #plugins }
CogMacOSConfig >> defaultInternalPlugins [

	^ #(
		ADPCMCodecPlugin
		AsynchFilePlugin
		B3DAcceleratorPlugin
		BalloonEnginePlugin "B2DPlugin" 
		BitBltSimulation "BitBltPlugin"
		BMPReadWriterPlugin
		DeflatePlugin  "ZipPlugin"
		DropPlugin
		DSAPlugin "DSAPrims"
		FFTPlugin
		FilePlugin
		HostWindowPlugin
		IA32ABIPlugin "IA32ABI"
		InternetConfigPlugin
		JoystickTabletPlugin
		JPEGReaderPlugin
		JPEGReadWriter2Plugin
		KlattSynthesizerPlugin "Klatt"
		LargeIntegersPlugin "LargeIntegers"
		LocalePlugin
		MacMenubarPlugin
		Matrix2x3Plugin
		MIDIPlugin
		MiscPrimitivePlugin
		QVMProfileMacSupportPlugin
		RePlugin
		SecurityPlugin
		SerialPlugin
		SocketPlugin
		SoundCodecPlugin "SoundCodecPrims"
		SoundGenerationPlugin
		SoundPlugin
		StarSqueakPlugin
		SurfacePlugin
		UUIDPlugin
		)
]

{ #category : #accessing }
CogMacOSConfig >> executableName [
	^ 'CogVM'
]

{ #category : #accessing }
CogMacOSConfig >> executableType [
	^ 'MACOSX_BUNDLE'
]

{ #category : #settings }
CogMacOSConfig >> extraPluginSettings: maker [
	
	"Cog currently runs only in 32 bit mode" 
	maker set: 'CMAKE_OSX_ARCHITECTURES' to: 'i386'
]

{ #category : #'source files' }
CogMacOSConfig >> extraSources [
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

{ #category : #settings }
CogMacOSConfig >> extraVMSettings: maker [
	
	"Cog currently runs only in 32 bit mode" 
	maker set: 'CMAKE_OSX_ARCHITECTURES' to: 'i386'.

	maker set: 'resourceDir' to: '${topDir}/macbuild/resources/ProjectBuilder'.
	maker set: 'resources' to: 
		'"${resourceDir}/Squeak VM.r"
		"${resourceDir}/Cog.icns"
		"${resourceDir}/Squeak.icns"
		"${resourceDir}/SqueakChanges.icns"
		"${resourceDir}/SqueakImage.icns"
		"${resourceDir}/SqueakPlugin.icns"
		"${resourceDir}/SqueakScript.icns"
		"${resourceDir}/SqueakGeneric.icns"
		"${resourceDir}/SqueakProject.icns"
		"${resourceDir}/SqueakSources.icns"'

]

{ #category : #accessing }
CogMacOSConfig >> frameworks [

	^ #(
	Carbon
	AppKit
	IOKit
	CoreFoundation
	AudioToolbox
	CoreAudio
	OpenGL
	AGL
	QuickTime
	Foundation
	SystemConfiguration
	)
]

{ #category : #'source files' }
CogMacOSConfig >> generateSourceFiles [

	^ CMakeGenScripts generateCogSources: self
]

{ #category : #'source generation' }
CogMacOSConfig >> interpreterClass [
	^ CoInterpreter
]

{ #category : #accessing }
CogMacOSConfig >> platformName [
	^ 'Mac OS'
]

{ #category : #'source files' }
CogMacOSConfig >> platformSources [
	"files added from platform/Mac OS/vm dir "
	^ #(
	'NSCursorWrappers.m'
	'nsPoolManagement.m'
	'osExports.c'
	'sqMacEncoding.c'
	'sqMacImageIO.c'
	'sqMacMain.c'
	'sqMacMemory.c'
	'sqMacNSPluginUILogic2.c'
	'sqMacTime.c'
	'sqMacUIAppleEvents.c'
	'sqMacUIClipBoard.c'
	'sqMacUIEventsUniversal.c'  " instead of: sqMacUIEvents.c "
	'sqMacUIMenuBarUniversal.c'
	'sqMacUnixCommandLineInterface.c'
	'sqMacUnixExternalPrims.c'
	'sqMacWindowUniversal.c'
	'version.c'	
	)
]

{ #category : #'bundle strings' }
CogMacOSConfig >> plistFile [

	| plist |
	
	plist := self plistTemplate.
	
	#(
	CFBundleExecutable
	CFBundleGetInfoString
	CFBundleName
	CFBundleShortVersionString
	CFBundleVersion
	CFBundleIconFile
	CFBundleIdentifier ) do: [:key |
		plist := plist copyReplaceAll: '@' , key , '@' with: (self perform: key)
	].

	^ self fixLineEndsOf: plist
]

{ #category : #'bundle strings' }
CogMacOSConfig >> plistTemplate [
	^ 
	'<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>LSMinimumSystemVersion</key>
	<string>10.5.0</string>
	<key>CFBundleDevelopmentRegion</key>
	<string>English</string>
	<key>CFBundleDocumentTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeExtensions</key>
			<array>
				<string>image</string>
			</array>
			<key>CFBundleTypeIconFile</key>
			<string>Croquet.icns</string>
			<key>CFBundleTypeName</key>
			<string>Croquet Image File</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>STim</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
		</dict>
		<dict>
			<key>CFBundleTypeExtensions</key>
			<array>
				<string>sources</string>
			</array>
			<key>CFBundleTypeIconFile</key>
			<string>Croquet.icns</string>
			<key>CFBundleTypeName</key>
			<string>Croquet Sources File</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>STso</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
		</dict>
		<dict>
			<key>CFBundleTypeExtensions</key>
			<array>
				<string>changes</string>
			</array>
			<key>CFBundleTypeIconFile</key>
			<string>Croquet.icns</string>
			<key>CFBundleTypeName</key>
			<string>Croquet Changes File</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>STch</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
		</dict>
		<dict>
			<key>CFBundleTypeExtensions</key>
			<array>
				<string>sobj</string>
			</array>
			<key>CFBundleTypeIconFile</key>
			<string>SqueakScript.icns</string>
			<key>CFBundleTypeName</key>
			<string>Squeak Script File</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>SOBJ</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
		</dict>
		<dict>
			<key>CFBundleTypeExtensions</key>
			<array>
				<string>pr</string>
			</array>
			<key>CFBundleTypeIconFile</key>
			<string>SqueakProject.icns</string>
			<key>CFBundleTypeName</key>
			<string>Squeak Project File</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>STpr</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>JPEG</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>JPEG</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>TEXT</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>TEXT</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>ttro</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>ttro</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>HTML</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>HTML</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>RTF </string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>RTF</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>TIFF </string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>TIFF</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>PICT </string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>PICT</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>URL  </string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>URL</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>ZIP </string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>ZIP</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>zip </string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>zip</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>BINA</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>BINA</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>GIFf</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>GIFf</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>PNGf</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>PNGf</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>MP3 </string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>MP3</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>MP3!</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>MP3!</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>MP3U</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>MP3U</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>MPEG</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>MPEG</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>mp3!</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>mp3!</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>MPG2</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>MPG2</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>MPG3</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>MPG3</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>MPG </string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>MPG</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>Mp3</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>mp3</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>M3U</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>M3U</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>SRCS</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>SRCS</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>Chng</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>Chng</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeName</key>
			<string>HPS5</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>HPS5</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
		</dict>
		<dict>
			<key>CFBundleTypeExtensions</key>
			<array>
				<string>bundle</string>
			</array>
			<key>CFBundleTypeIconFile</key>
			<string>SqueakPlugin.icns</string>
			<key>CFBundleTypeName</key>
			<string>Squeak Plugin</string>
			<key>CFBundleTypeOSTypes</key>
			<array>
				<string>BNDL</string>
			</array>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
		</dict>
	</array>
	<key>CFBundleExecutable</key>
	<string>@CFBundleExecutable@</string>
	<key>CFBundleGetInfoString</key>
	<string>@CFBundleGetInfoString@</string>
	<key>CFBundleIconFile</key>
	<string>@CFBundleIconFile@</string>
	<key>CFBundleIdentifier</key>
	<string>@CFBundleIdentifier@</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>@CFBundleName@</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>@CFBundleShortVersionString@</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>@CFBundleVersion@</string>
	<key>CGDisableCoalescedUpdates</key>
	<true/>
	<key>LSBackgroundOnly</key>
	<false/>
	<key>NSServices</key>
	<array>
		<dict>
			<key>NSMenuItem</key>
			<dict>
				<key>default</key>
				<string>Squeak DoIt</string>
			</dict>
			<key>NSMessage</key>
			<string>doitandreturn</string>
			<key>NSPortName</key>
			<string>Squeak</string>
			<key>NSReturnTypes</key>
			<array>
				<string>NSStringPboardType</string>
			</array>
			<key>NSSendTypes</key>
			<array>
				<string>NSStringPboardType</string>
			</array>
		</dict>
	</array>
	<key>SqueakBrowserMouseCmdButton1</key>
	<integer>3</integer>
	<key>SqueakBrowserMouseCmdButton2</key>
	<integer>3</integer>
	<key>SqueakBrowserMouseCmdButton3</key>
	<integer>2</integer>
	<key>SqueakBrowserMouseControlButton1</key>
	<integer>1</integer>
	<key>SqueakBrowserMouseControlButton2</key>
	<integer>3</integer>
	<key>SqueakBrowserMouseControlButton3</key>
	<integer>2</integer>
	<key>SqueakBrowserMouseNoneButton1</key>
	<integer>1</integer>
	<key>SqueakBrowserMouseNoneButton2</key>
	<integer>3</integer>
	<key>SqueakBrowserMouseNoneButton3</key>
	<integer>2</integer>
	<key>SqueakBrowserMouseOptionButton1</key>
	<integer>2</integer>
	<key>SqueakBrowserMouseOptionButton2</key>
	<integer>3</integer>
	<key>SqueakBrowserMouseOptionButton3</key>
	<integer>2</integer>
	<key>SqueakDebug</key>
	<integer>0</integer>
	<key>SqueakEncodingType</key>
	<string>UTF-8</string>
	<key>SqueakExplicitWindowOpenNeeded</key>
	<false/>
	<key>SqueakFloatingWindowGetsFocus</key>
	<true/>
	<key>SqueakHasQuitWithoutSaving</key>
	<false/>
	<key>SqueakImageName</key>
	<string>Squeak.image</string>
	<key>SqueakMaxHeapSize</key>
	<integer>536870912</integer>
	<key>SqueakMouseCmdButton1</key>
	<integer>3</integer>
	<key>SqueakMouseCmdButton2</key>
	<integer>3</integer>
	<key>SqueakMouseCmdButton3</key>
	<integer>2</integer>
	<key>SqueakMouseControlButton1</key>
	<integer>1</integer>
	<key>SqueakMouseControlButton2</key>
	<integer>3</integer>
	<key>SqueakMouseControlButton3</key>
	<integer>2</integer>
	<key>SqueakMouseNoneButton1</key>
	<integer>1</integer>
	<key>SqueakMouseNoneButton2</key>
	<integer>3</integer>
	<key>SqueakMouseNoneButton3</key>
	<integer>2</integer>
	<key>SqueakMouseOptionButton1</key>
	<integer>2</integer>
	<key>SqueakMouseOptionButton2</key>
	<integer>3</integer>
	<key>SqueakMouseOptionButton3</key>
	<integer>2</integer>
	<key>SqueakPluginsBuiltInOrLocalOnly</key>
	<false/>
	<key>SqueakUIFlushPrimaryDeferNMilliseconds</key>
	<integer>20</integer>
	<key>SqueakUIFlushSecondaryCheckForPossibleNeedEveryNMilliseconds</key>
	<integer>20</integer>
	<key>SqueakUIFlushSecondaryCleanupDelayMilliseconds</key>
	<integer>25</integer>
	<key>SqueakUIFlushUseHighPercisionClock</key>
	<true/>
	<key>SqueakUnTrustedDirectory</key>
	<string>~/Library/Preferences/Croquet/Internet/Untrusted/</string>
	<key>SqueakWindowAttribute</key>
	<data>ggAAHw==</data>
	<key>SqueakWindowHasTitle</key>
	<true/>
	<key>SqueakWindowType</key>
	<integer>6</integer>
</dict>
</plist>
'
]

{ #category : #'source generation' }
CogMacOSConfig >> prepareForGeneration [

	"force using LF on Macs"
	CrLfFileStream defaultToLF.

	^ self prepareForCogGeneration

]

{ #category : #settings }
CogMacOSConfig >> setExtraTargetProperties: maker [

	super setExtraTargetProperties: maker.

	maker addFrameworks: self frameworks.	

	" generated and add Info.plist file "
	self write: self plistFile toFile: 'Info.plist'.
	maker 
		addProperty: 'MACOSX_BUNDLE_INFO_PLIST' 
		value: '${buildDir}/Info.plist'.

	maker cmd: 'set_source_files_properties' params: '${resources} PROPERTIES MACOSX_PACKAGE_LOCATION Resources'.
]

{ #category : #'source files' }
CogMacOSConfig >> standardIncludes [
	^ #(
	'SYSTEM /Developer/Headers/FlatCarbon'
	'${targetPlatform}/vm/Developer'  "for some unknown reason sqGnu.h is put there"
	
	'${crossDir}/plugins/SerialPlugin'   "for platforms/Mac OS/vm/osExports.c to work"
	'${targetPlatform}/plugins/FilePlugin'   "for sqMacFileLogic.h to work"
	'${targetPlatform}/plugins/HostWindowPlugin'  "for sqMacNSPluginUILogic2.c to work"
	'${crossDir}/plugins/HostWindowPlugin' "for same... "
	'${crossDir}/plugins/DropPlugin' "include DropPlugin.h"
	'${crossDir}/plugins/SocketPlugin'
	'${crossDir}/plugins/AsynchFilePlugin'
	'${platformsDir}/unix/vm'  "suppressing following:
		platforms/Mac OS/vm/sqMacMain.c:94:19: error: sqaio.h: No such file or directory
		platforms/Mac OS/vm/sqMacMain.c:96:28: error: sqUnixCharConv.h: No such file or directory"
	)
	
]
