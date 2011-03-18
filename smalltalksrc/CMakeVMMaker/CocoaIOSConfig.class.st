Class {
	#name : #CocoaIOSConfig,
	#superclass : #MacOSConfig,
	#category : #'CMakeVMMaker-IOS'
}

{ #category : #'bundle strings' }
CocoaIOSConfig >> CFBundleExecutable [
	^ self executableName 
]

{ #category : #'bundle strings' }
CocoaIOSConfig >> CFBundleGetInfoString [
	^ self CFBundleShortVersionString

]

{ #category : #'bundle strings' }
CocoaIOSConfig >> CFBundleIconFile [

	"An application icon"
	^ 'Cog.icns'
]

{ #category : #'bundle strings' }
CocoaIOSConfig >> CFBundleIdentifier [
	"A Java package style name (like 'com.myCompany.MyBundle') which is used to uniquely identify bundles."
	^ 'org.squeakfoundation.Squeak'
]

{ #category : #'bundle strings' }
CocoaIOSConfig >> CFBundleName [
	"An application name"
	^ self executableName, ' (Cocoa) 32bits'
]

{ #category : #'bundle strings' }
CocoaIOSConfig >> CFBundleShortVersionString [
	"An application version"
	^ self executableName, ' VM ' , self CFBundleVersion
]

{ #category : #'bundle strings' }
CocoaIOSConfig >> CFBundleVersion [
	"An application version"
	^ '5.7.4'
]

{ #category : #'bundle strings' }
CocoaIOSConfig >> NSMainNibFile [
	^'MainMenu'
]

{ #category : #accessing }
CocoaIOSConfig >> commonCompilerFlags [
	"Common compiler flags"
	^#('-arch i386' '-fnext-runtime' '-mmacosx-version-min=10.5')
]

{ #category : #accessing }
CocoaIOSConfig >> compilerFlags [ 
	^String streamContents: [ :stream |
		(self commonCompilerFlags, self compilerFlagsRelease)
			do: [ :each | stream nextPutAll: each ]
			separatedBy: [ stream space ] ]
]

{ #category : #accessing }
CocoaIOSConfig >> compilerFlagsRelease [ 
	^#(
	"'-fobjc-direct-dispatch'" 
	'-msse3'
	"'-msse4.1'"
	"'-msse4.2'"
	"'-mdynamic-no-pic'" 
	"'-fwritable-strings'" 
	'-Os' 
	'-fvisibility=hidden' 
	'-funroll-loops' 
	"'-fno-asm'" 
	'-fasm-blocks' 
	'-finline-functions' 
	'-mfpmath=sse' 
	'-fomit-frame-pointer' 
	'-march=pentium-m' 
	'-mtune=prescott' 
	'-falign-functions=16'  
	'-fno-gcse' 
	'-fno-cse-follow-jumps' 
	'-std=gnu99' 
	'-DBUILD_FOR_OSX' 
	'-DUSE_INLINE_MEMORY_ACCESSORS' 
	'-DLSB_FIRST' 
	'-DUSE_INLINE_MEMORY_ACCESSORS' 
	'-DHAVE_SYS_TIME_H' 
	'-DHAVE_NANOSLEEP' 
	'-DSQUEAK_BUILTIN_PLUGIN'
	'-DICC_DEBUG=0'
	'-DICC_OPTLEVEL="speedHLO"' 
	'-DICC_OPT_IPO_FOR_SINGLE_FILE_COMPILATION=1' 
	'-DICC_OPT_PARALLEL=0' 
	'-DICC_OPT_PREFETCH_INSERTION=1' 
	'-DICC_OPT_PROVIDE_FRAME_PTR=0' 
	'-DICC_OPT_USE_ARCH_IA32="SSE42"')
]

{ #category : #'plugin extra rules' }
CocoaIOSConfig >> configureClipboardExtendedPlugin: maker [
	maker includeDirectories: '${platformsDir}/iOS/plugins/ClipboardExtended'.
	maker 
		addSources: #('sqMacExtendedClipboard.m' ) 
		prefixed: '${platformsDir}/iOS/plugins/ClipboardExtended/'

]

{ #category : #'plugin extra rules' }
CocoaIOSConfig >> configureHostWindowPlugin: maker [
	super configureHostWindowPlugin: maker.
	maker 
		addSources: #('sqMacHostWindow.c' ) 
		prefixed: '${platformsDir}/iOS/vm/iPhone/plugins/HostWindowPlugin/'

]

{ #category : #'plugin extra rules' }
CocoaIOSConfig >> configureMacMenubarPlugin: maker [
	maker includeDirectories: '${platformsDir}/iOS/plugins/MacMenubarPlugin'.
	maker 
		addSources: #('MacMenuOS9ToOSX.m') 
		prefixed: '${platformsDir}/iOS/plugins/MacMenubarPlugin/'

]

{ #category : #'plugin extra rules' }
CocoaIOSConfig >> configureSoundPlugin: maker [
	super configureSoundPlugin: maker.
	
	maker includeDirectories: '${platformsDir}/Cross/plugins/SoundPlugin ${platformsDir}/iOS/vm/OSX/plugins/SoundPlugin'.
	maker 
		addSources: #('sqSqueakSoundCoreAudio.m' 'sqSqueakSoundCoreAudioAPI.m' ) 
		prefixed: '${platformsDir}/iOS/plugins/SoundPlugin/'.
	maker 
		addSources: #('sqSqueakOSXSoundCoreAudio.m' ) 
		prefixed: '${platformsDir}/iOS/vm/OSX/plugins/SoundPlugin/'
]

{ #category : #'plugin extra rules' }
CocoaIOSConfig >> configureUUIDPlugin: maker [
	super configureUUIDPlugin: maker.
	maker addSources: #('sqUnixUUID.c' ) prefixed: '${platformsDir}/unix/plugins/UUIDPlugin/'

]

{ #category : #'source files' }
CocoaIOSConfig >> coreSources [
	^#('interp.c')
]

{ #category : #'source files' }
CocoaIOSConfig >> crossSources [ 
	^#(
		'sqNamedPrims.c'
		'sqVirtualMachine.c')
]

{ #category : #plugins }
CocoaIOSConfig >> defaultExternalPlugins [
	^#()
]

{ #category : #plugins }
CocoaIOSConfig >> defaultInternalPlugins [
	^ #(
		ADPCMCodecPlugin
		"B3DAcceleratorPlugin"
		BMPReadWriterPlugin 
		BalloonEnginePlugin 
		BitBltSimulation 
		ClipboardExtendedPlugin 
		DSAPlugin 
		DeflatePlugin 
		DropPlugin 
		FFIPlugin
		FFTPlugin 
		FilePlugin 
		FloatArrayPlugin 
		GeniePlugin 
		HostWindowPlugin 
		JPEGReadWriter2Plugin 
		JPEGReaderPlugin 
		KlattSynthesizerPlugin 
		LargeIntegersPlugin 
		MacMenubarPlugin 
		Matrix2x3Plugin 
		MiscPrimitivePlugin 
		"IA32ABIPlugin" 
		"ObjectiveCPlugin" 
		RePlugin 
		SecurityPlugin 
		SocketPlugin 
		SoundCodecPlugin 
		SoundGenerationPlugin 
		SoundPlugin 
		StarSqueakPlugin 
		SurfacePlugin 
		"UUIDPlugin")
]

{ #category : #accessing }
CocoaIOSConfig >> executableType [
	^ 'MACOSX_BUNDLE'
]

{ #category : #'plugin extra rules' }
CocoaIOSConfig >> extraPluginSettings: maker [	
	maker set: 'CMAKE_OSX_ARCHITECTURES' to: 'i386'.
	
	maker 
		cmd: 'set_target_properties' 
		params: maker moduleName, ' PROPERTIES COMPILE_FLAGS "-include ', (self topDir / 'build' / self prefixHeaderFileName) fullName, '"'. 
	
	maker addXCodeProperty: 'GCC_VERSION' value: '4.2'.
	maker addXCodeProperty: 'GCC_PREFIX_HEADER' value: '${buildDir}/' , self executableName , '_Prefix.pch'.
	

]

{ #category : #'source files' }
CocoaIOSConfig >> extraSources [
	^'${buildDir}/', self prefixHeaderFileName, '
 ${resources}'
]

{ #category : #settings }
CocoaIOSConfig >> extraVMSettings: maker [
	maker set: 'CMAKE_OSX_ARCHITECTURES' to: 'i386'.

	maker set: 'resourceDir' to: '${topDir}/macbuild/resources/ProjectBuilder'.
	maker set: 'resources' to: 
		'"${resourceDir}/Squeak VM.r"
		"${resourceDir}/Squeak.icns"
		"${resourceDir}/SqueakChanges.icns"
		"${resourceDir}/SqueakImage.icns"
		"${resourceDir}/SqueakPlugin.icns"
		"${resourceDir}/SqueakScript.icns"
		"${resourceDir}/SqueakGeneric.icns"
		"${resourceDir}/SqueakProject.icns"
		"${resourceDir}/SqueakSources.icns"
		"${resourceDir}/MainMenu.nib"'

]

{ #category : #accessing }
CocoaIOSConfig >> frameworks [
	^ #(
	Cocoa
	Foundation
	AudioToolbox
	CoreAudio
	SystemConfiguration
	ApplicationServices
	QuartzCore
	OpenGL)
]

{ #category : #accessing }
CocoaIOSConfig >> platformName [ 
	^'iOS'
]

{ #category : #'source files' }
CocoaIOSConfig >> platformSources [
	"files added from platform/iOS/vm dir "
	^ #(
		'Common/main.m'
		'Common/aio.c'
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
		'iPhone/osExports.c')
]

{ #category : #'bundle strings' }
CocoaIOSConfig >> plistFile [

	| plist |
	
	plist := self plistTemplate.
	
	#(
	CFBundleExecutable
	CFBundleGetInfoString
	CFBundleName
	CFBundleShortVersionString
	CFBundleVersion
	CFBundleIconFile
	CFBundleIdentifier
	NSMainNibFile) do: [:key |
		plist := plist copyReplaceAll: '@' , key , '@' with: (self perform: key)
	].

	^ self fixLineEndsOf: plist
]

{ #category : #'bundle strings' }
CocoaIOSConfig >> plistTemplate [ 
^'<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
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
			<string>SqueakImage.icns</string>
			<key>CFBundleTypeName</key>
			<string>Squeak Image File</string>
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
			<string>SqueakSources.icns</string>
			<key>CFBundleTypeName</key>
			<string>Squeak Sources File</string>
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
			<string>SqueakChanges.icns</string>
			<key>CFBundleTypeName</key>
			<string>Squeak Changes File</string>
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
	<string>FAST</string>
	<key>CFBundleVersion</key>
	<string>21.0</string>
	<key>LSBackgroundOnly</key>
	<false/>
	<key>LSMinimumSystemVersion</key>
	<string>${MACOSX_DEPLOYMENT_TARGET}</string>
	<key>NSMainNibFile</key>
	<string>@NSMainNibFile@</string>
	<key>NSPrincipalClass</key>
	<string>SqueakOSXApplication</string>
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
	<key>SqueakExplicitWindowOpenNeeded</key>
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
	<key>SqueakQuitOnQuitAppleEvent</key>
	<false/>
	<key>SqueakResourceDirectory</key>
	<string></string>
	<key>SqueakTrustedDirectory</key>
	<string>/foobar/tooBar/forSqueak/bogus/</string>
	<key>SqueakUIFlushPrimaryDeferNMilliseconds</key>
	<integer>20</integer>
	<key>SqueakUnTrustedDirectory</key>
	<string>~/Library/Preferences/Squeak/Internet/My Squeak/</string>
	<key>SqueakUseFileMappedMMAP</key>
	<false/>
	<key>SqueakUIFadeForFullScreenInSeconds</key>
	<real>0.5</real>
	<key>UTExportedTypeDeclarations</key>
	<array>
		<dict>
			<key>UTTypeConformsTo</key>
			<array>
				<string>public.data</string>
			</array>
			<key>UTTypeDescription</key>
			<string>Squeak Image File</string>
			<key>UTTypeIdentifier</key>
			<string>org.squeak.image</string>
			<key>UTTypeTagSpecification</key>
			<dict>
				<key>com.apple.ostype</key>
				<string>STim</string>
				<key>public.filename-extension</key>
				<array>
					<string>image</string>
				</array>
				<key>public.mime-type</key>
				<string>application/squeak-image</string>
			</dict>
		</dict>
		<dict>
			<key>UTTypeConformsTo</key>
			<array>
				<string>public.utf8-plain-text</string>
			</array>
			<key>UTTypeDescription</key>
			<string>Squeak Sources File</string>
			<key>UTTypeIdentifier</key>
			<string>org.squeak.sources</string>
			<key>UTTypeTagSpecification</key>
			<dict>
				<key>com.apple.ostype</key>
				<string>STso</string>
				<key>public.filename-extension</key>
				<array>
					<string>sources</string>
				</array>
				<key>public.mime-type</key>
				<string>application/squeak-sources</string>
			</dict>
		</dict>
		<dict>
			<key>UTTypeConformsTo</key>
			<array>
				<string>public.utf8-plain-text</string>
			</array>
			<key>UTTypeDescription</key>
			<string>Squeak Changes File</string>
			<key>UTTypeIdentifier</key>
			<string>org.squeak.changes</string>
			<key>UTTypeTagSpecification</key>
			<dict>
				<key>com.apple.ostype</key>
				<string>STch</string>
				<key>public.filename-extension</key>
				<array>
					<string>changes</string>
				</array>
				<key>public.mime-type</key>
				<string>application/squeak-changes</string>
			</dict>
		</dict>
		<dict>
			<key>UTTypeConformsTo</key>
			<array>
				<string>public.data</string>
			</array>
			<key>UTTypeDescription</key>
			<string>Squeak Script File</string>
			<key>UTTypeIdentifier</key>
			<string>org.squeak.script</string>
			<key>UTTypeTagSpecification</key>
			<dict>
				<key>com.apple.ostype</key>
				<string>SOBJ</string>
				<key>public.filename-extension</key>
				<array>
					<string>sobj</string>
				</array>
				<key>public.mime-type</key>
				<string>application/squeak-script</string>
			</dict>
		</dict>
		<dict>
			<key>UTTypeConformsTo</key>
			<array>
				<string>public.data</string>
			</array>
			<key>UTTypeDescription</key>
			<string>Squeak Project File</string>
			<key>UTTypeIdentifier</key>
			<string>org.squeak.project</string>
			<key>UTTypeTagSpecification</key>
			<dict>
				<key>com.apple.ostype</key>
				<string>STpr</string>
				<key>public.filename-extension</key>
				<array>
					<string>pr</string>
				</array>
				<key>public.mime-type</key>
				<string>application/x-squeak-project</string>
			</dict>
		</dict>
	</array>
</dict>
</plist>
'
]

{ #category : #accessing }
CocoaIOSConfig >> pluginsDir [ 
	^'${srcDir}/vm/intplugins'
]

{ #category : #settings }
CocoaIOSConfig >> precompiledHeaders [ 
	^
'//
// Prefix header for all source files of the ''', self executableName, ''' target in the ''', self executableName, ''' project
//

#ifdef __OBJC__
    #import <Cocoa/Cocoa.h>
#endif
'
]

{ #category : #'source files' }
CocoaIOSConfig >> preferredIncludes [
	^ #(
	'${buildDir}/'
	'${platformsDir}/iOS/vm/iPhone' "config.h is here. Why???"
	)
	
]

{ #category : #accessing }
CocoaIOSConfig >> prefixHeaderFileName [ 
	^self executableName, '_Prefix.pch'
]

{ #category : #settings }
CocoaIOSConfig >> setExtraTargetProperties: maker [
	| plist precompiledHeaders |

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
			
	precompiledHeaders := (self executableName, '_Prefix.pch').
	(maker buildDir forceNewFileNamed: precompiledHeaders) 
		nextPutAll: self precompiledHeaders;
		close.
		
	maker addXCodeProperty: 'GCC_PREFIX_HEADER' value: '${buildDir}/', precompiledHeaders.

	"maker 
		addXCodeProperty: 'GCC_ENABLE_SSE3_EXTENSIONS' value: 'YES';  
		addXCodeProperty: 'GCC_ENABLE_SSE41_EXTENSIONS' value: 'YES';
		addXCodeProperty: 'GCC_ENABLE_SSE42_EXTENSIONS' value: 'YES';
		addXCodeProperty: 'GCC_GENERATE_DEBUGGING_SYMBOLS' value: 'NO';  
		addXCodeProperty: 'GCC_INLINES_ARE_PRIVATE_EXTERN' value: 'YES';
		addXCodeProperty: 'GCC_UNROLL_LOOPS' value: 'YES'.	"
	
	"Extras"
	maker 
		addXCodeProperty: 'ICC_DEBUG' value: 'NO';
		addXCodeProperty: 'ICC_OPTLEVEL' value: 'speedHLO';
		addXCodeProperty: 'ICC_OPT_IPO_FOR_SINGLE_FILE_COMPILATION' value: 'YES';
		addXCodeProperty: 'ICC_OPT_PARALLEL' value: 'NO';
		addXCodeProperty: 'ICC_OPT_PREFETCH_INSERTION' value: 'YES';
		addXCodeProperty: 'ICC_OPT_PROVIDE_FRAME_PTR' value: 'NO';
		addXCodeProperty: 'ICC_OPT_USE_ARCH_IA32' value: 'SSE41';
		addXCodeProperty: 'PER_ARCH_CFLAGS_i386' value: '-finline-functions -mfpmath=sse -fomit-frame-pointer -march=pentium-m -mtune=prescott -falign-functions=16  -fno-gcse -fno-cse-follow-jumps  -DLSB_FIRST -DUSE_INLINE_MEMORY_ACCESSORS';
		addXCodeProperty: 'PER_ARCH_CFLAGS_ppc' value: '-fast -mtune=7450 -mcpu=7450 -D_BSD_SOCKLEN_T_=int'
]

{ #category : #accessing }
CocoaIOSConfig >> srcDir [ 
	^'${topDir}/platforms/iOS/vm/src'
]

{ #category : #'source files' }
CocoaIOSConfig >> standardIncludes [
	^ #(
	'${crossDir}/plugins/SerialPlugin'   
	'${targetPlatform}/plugins/FilePlugin'
	'${crossDir}/plugins/FilePlugin'
	'${targetPlatform}/plugins/HostWindowPlugin'
	'${platformsDir}/iOS/vm/iPhone/plugins/HostWindowPlugin' 
	'${crossDir}/plugins/HostWindowPlugin'
	'${crossDir}/plugins/DropPlugin'
	'${crossDir}/plugins/SocketPlugin'
	'${crossDir}/plugins/SoundPlugin'
	'${crossDir}/plugins/AsynchFilePlugin'
	'${platformsDir}/unix/vm'
	'${platformsDir}/iOS/plugins/SoundPlugin'
	'${platformsDir}/iOS/vm/OSX/plugins/SoundPlugin'
	'${platformsDir}/iOS/vm/Common/Classes'
	'${platformsDir}/iOS/vm/OSX'
)
	
]
