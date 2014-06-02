"
This is an abstract class for all Mac Cocoa configurations. It is intended to share code between different concrete implementations. 

For more information, check the class comments of all the superclasses.

"
Class {
	#name : #SqueakCocoaIOSConfig,
	#superclass : #SqueakMacOSConfig,
	#category : #'CMakeVMMakerSqueak-IOS'
}

{ #category : #'bundle strings' }
SqueakCocoaIOSConfig >> CFBundleExecutable [
	^ self executableName 
]

{ #category : #'bundle strings' }
SqueakCocoaIOSConfig >> CFBundleGetInfoString [
	^ self CFBundleShortVersionString

]

{ #category : #'bundle strings' }
SqueakCocoaIOSConfig >> CFBundleIconFile [
	"An application icon"
	^ 'Squeak.icns'
]

{ #category : #'bundle strings' }
SqueakCocoaIOSConfig >> CFBundleIdentifier [
	"A Java package style name (like 'com.myCompany.MyBundle') which is used to uniquely identify bundles."
	^ 'org.squeakfoundation.Squeak'
]

{ #category : #'bundle strings' }
SqueakCocoaIOSConfig >> CFBundleName [
	"An application name"
	^ self executableName", ' (Cocoa) 32bits'"
]

{ #category : #'bundle strings' }
SqueakCocoaIOSConfig >> CFBundleShortVersionString [
	"An application version"
	^ self executableName, ' VM ' , self CFBundleVersion
]

{ #category : #'bundle strings' }
SqueakCocoaIOSConfig >> CFBundleVersion [
	"An application version"
	^ '6.0'
]

{ #category : #'bundle strings' }
SqueakCocoaIOSConfig >> NSMainNibFile [
	^'MainMenu'
]

{ #category : #'bundle strings' }
SqueakCocoaIOSConfig >> SqueakDebug [
	^self isGenerateForRelease 
		ifTrue: [ 0 ]
		ifFalse: [ 1 ]
]

{ #category : #accessing }
SqueakCocoaIOSConfig >> architecture [ 
	^'i386'
]

{ #category : #accessing }
SqueakCocoaIOSConfig >> commonCompilerFlags [
	"Common compiler flags"
	^{
	'-arch i386'. 
	'-mmacosx-version-min=10.5'. 
	'-DHAVE_UUID_GENERATE'. 
	'-DDEFAULT_IMAGE_NAME="', self executableName, '.image"'}
]

{ #category : #accessing }
SqueakCocoaIOSConfig >> compilerFlagsRelease [ 
	^#(
	"'-fobjc-direct-dispatch'" 
	'-msse3'
	"'-msse4.1'"
	"'-msse4.2'"
	"'-mdynamic-no-pic'" 
	"'-fwritable-strings'" 
	'-Os' 
	'-fvisibility=default'
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
	'-std=gnu99' 
	'-DBUILD_FOR_OSX' 
	"'-DUSE_INLINE_MEMORY_ACCESSORS'" 
	'-DLSB_FIRST' 
	'-DUSE_INLINE_MEMORY_ACCESSORS' 
	'-DHAVE_SYS_TIME_H' 
	'-DHAVE_NANOSLEEP' 
	'-DICC_DEBUG=0'
	'-DICC_OPTLEVEL="speedHLO"' 
	'-DICC_OPT_IPO_FOR_SINGLE_FILE_COMPILATION=1' 
	'-DICC_OPT_PARALLEL=0' 
	'-DICC_OPT_PREFETCH_INSERTION=1' 
	'-DICC_OPT_PROVIDE_FRAME_PTR=0' 
	'-DICC_OPT_USE_ARCH_IA32="SSE42"')
]

{ #category : #'plugin extra rules' }
SqueakCocoaIOSConfig >> configureB3DAcceleratorPlugin: maker [
	"extra rules for B3DAcceleratorPlugin"
	
	super configureB3DAcceleratorPlugin: maker. 
	maker addFrameworks: self frameworks.	 
	maker addPlatformSources: #( 'sqMacOpenGL.c' 'sqMacOpenGLInfo.c')
]

{ #category : #'plugin extra rules' }
SqueakCocoaIOSConfig >> configureClipboardExtendedPlugin: maker [
	
	maker addPlatformSources: #('sqMacExtendedClipboard.m' ) 
	
]

{ #category : #'plugin extra rules' }
SqueakCocoaIOSConfig >> configureHostWindowPlugin: maker [
	super configureHostWindowPlugin: maker.
	maker 
		addSources: #('sqMacHostWindow.m' ) 
		prefixed: '${platformsDir}/iOS/vm/OSX/plugins/HostWindowPlugin/'

]

{ #category : #'plugin extra rules' }
SqueakCocoaIOSConfig >> configureJoystickTabletPlugin: maker [ 
	"extra rules for JoystickTabletPlugin"
	
	super configureJoystickTabletPlugin: maker.  
	maker addPlatformSources:
		#( 
			'HID_Error_Handler.c'
			'HID_Name_Lookup.c'
			'HID_Queue_Utilities.c'
			'HID_Utilities.c'
			'sqMacJoystickAndTablet.c'
			)

]

{ #category : #'plugin extra rules' }
SqueakCocoaIOSConfig >> configureLocalePlugin: maker [
	maker addFrameworks: #('CoreFoundation').
	maker addPlatformSources: #( 'sqIOSLocale.c' )	.

]

{ #category : #'plugin extra rules' }
SqueakCocoaIOSConfig >> configureMIDIPlugin: maker [ 
	"extra rules for MIDIPlugin"

	maker addPlatformSources: #( 'sqMacMIDI.m')
]

{ #category : #'plugin extra rules' }
SqueakCocoaIOSConfig >> configureMacMenubarPlugin: maker [
	maker includeDirectories: '${platformsDir}/iOS/plugins/MacMenubarPlugin'.
	maker 
		addSources: #('MacMenuOS9ToOSX.m') 
		prefixed: '${platformsDir}/iOS/plugins/MacMenubarPlugin/'

]

{ #category : #'plugin extra rules' }
SqueakCocoaIOSConfig >> configureObjectiveCPlugin: maker [ 
	"extra rules for ObjectiveCPlugin"

	maker addDefinitions: ' -x objective-c'.
	maker addFrameworks: self frameworks.
	maker includeDirectories: '${platformsDir}/iOS/plugins/SqueakObjectiveC'.
	maker 
		addSources: #('squeakProxy.m' 'squeakSUnitTester.m') 
		prefixed: '${platformsDir}/iOS/plugins/SqueakObjectiveC/'.
	
]

{ #category : #'plugin extra rules' }
SqueakCocoaIOSConfig >> configureSoundPlugin: maker [
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
SqueakCocoaIOSConfig >> configureUUIDPlugin: maker [
	super configureUUIDPlugin: maker.
	maker addFrameworks: #(CoreFoundation).  
	maker addDefinitions: '-x objective-c'.  
	maker addPlatformSources: #('sqMacUUID.c' )
]

{ #category : #'source files' }
SqueakCocoaIOSConfig >> coreSources [
	^#('interp.c')
]

{ #category : #'source files' }
SqueakCocoaIOSConfig >> crossSources [ 
	^#(
		'sqNamedPrims.c'
		'sqVirtualMachine.c')
]

{ #category : #plugins }
SqueakCocoaIOSConfig >> defaultExternalPlugins [
	^#()
]

{ #category : #plugins }
SqueakCocoaIOSConfig >> defaultInternalPlugins [
	^ #(
		ADPCMCodecPlugin
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
		RePlugin 
		SecurityPlugin 
		SocketPlugin 
		SoundCodecPlugin 
		SoundGenerationPlugin 
		SoundPlugin 
		StarSqueakPlugin 
		SurfacePlugin)
]

{ #category : #accessing }
SqueakCocoaIOSConfig >> executableType [
	^ 'MACOSX_BUNDLE'
]

{ #category : #'plugin extra rules' }
SqueakCocoaIOSConfig >> extraPluginSettings: maker [	
	maker set: 'CMAKE_OSX_ARCHITECTURES' to: 'i386'.
	
	maker 
		setTargetProperty: 'COMPILE_FLAGS' 
		to: '"-include \"', (self buildDir / self prefixHeaderFileName) fullName, '\""'.  

	maker isExternal ifTrue: [
		"copy result to results dir "
		
		maker set: 'LIBRARY_OUTPUT_PATH' toString: self outputDir fullName.
		maker set: 'EXECUTABLE_OUTPUT_PATH' toString: self outputDir fullName.
		maker puts: 'list(APPEND linkFlags "-undefined dynamic_lookup")' ].
	
	"maker addXCodeProperty: 'GCC_VERSION' value: '4.3'."
	maker addXCodeProperty: 'GCC_PREFIX_HEADER' value: '${buildDir}/' , self executableName , '_Prefix.pch'.
	

]

{ #category : #'source files' }
SqueakCocoaIOSConfig >> extraSources [
	^'${buildDir}/', self prefixHeaderFileName, '
 ${resources} ', 
	'${buildDir}/', self prefixHeaderFileName, '
 ${resourcesLocaleEnglish}'
]

{ #category : #settings }
SqueakCocoaIOSConfig >> extraVMSettings: maker [
	self architecture
		ifNotNil: [ :arch | maker set: 'CMAKE_OSX_ARCHITECTURES' toString: arch ].
	self setResourceProperties: maker.

]

{ #category : #accessing }
SqueakCocoaIOSConfig >> frameworks [
	^ #(
	Cocoa
	Foundation
	AudioToolbox
	CoreAudio
	SystemConfiguration
	ApplicationServices
	QuartzCore
	OpenGL
	AGL
	QuickTime)
]

{ #category : #accessing }
SqueakCocoaIOSConfig >> freetypeLibClass [ 
	^CMOSXFreetype2
]

{ #category : #accessing }
SqueakCocoaIOSConfig >> platformName [ 
	^'iOS'
]

{ #category : #'source files' }
SqueakCocoaIOSConfig >> platformSources [
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
		'iPhone/osExports.c')
]

{ #category : #'bundle strings' }
SqueakCocoaIOSConfig >> plistFile [
	| plist |
	
	plist := self plistTemplate.	
	self plistKeys
		do: [:key | 
			plist := plist 
				copyReplaceAll: '@' , key , '@' 
				with: (self perform: key) asString ].

	^ self fixLineEndsOf: plist
]

{ #category : #'bundle strings' }
SqueakCocoaIOSConfig >> plistKeys [ 
	^#(
	CFBundleExecutable
	CFBundleGetInfoString
	CFBundleName
	CFBundleShortVersionString
	CFBundleVersion
	CFBundleIconFile
	CFBundleIdentifier
	NSMainNibFile
	SqueakDebug)
]

{ #category : #'bundle strings' }
SqueakCocoaIOSConfig >> plistTemplate [ 
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
	<integer>@SqueakDebug@</integer>
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
SqueakCocoaIOSConfig >> pluginsDir [ 
	^'${srcDir}/vm/intplugins'
]

{ #category : #settings }
SqueakCocoaIOSConfig >> precompiledHeaders [ 
	^
'//
// Prefix header for all source files of the ''', self executableName, ''' target in the ''', self executableName, ''' project
//

#ifdef __OBJC__
	', 
	(String streamContents: [ :stream | 
		self precompiledImports 
			do: [ :each | 
				stream 
					nextPutAll: '#import ';
					nextPut: $<;
					nextPutAll: each; 
					nextPut: $> ]
			separatedBy: [ 
				stream cr ] ]),  '
#endif
'
]

{ #category : #settings }
SqueakCocoaIOSConfig >> precompiledImports [ 
	^#('Cocoa/Cocoa.h')
]

{ #category : #'source files' }
SqueakCocoaIOSConfig >> preferredIncludes [
	^ #(
	'${buildDir}/'
	'${platformsDir}/iOS/vm/iPhone' "config.h is here. Why???"
	)
	
]

{ #category : #accessing }
SqueakCocoaIOSConfig >> prefixHeaderFileName [ 
	^self executableName, '_Prefix.pch'
]

{ #category : #'source generation' }
SqueakCocoaIOSConfig >> prepareVMMaker [
	
	| maker allPlugins |
	
	"In CogVMs (in contrast to Interpreter VM) the generated sources are platform independent, therefore Cross is ok"
	maker := VMMaker forPlatform: 'Cross'.
	
	maker sourceDirectoryName: self srcDir pathName.
	maker platformRootDirectoryName: self platformsDir.
	
	
	allPlugins := self internalPlugins , self externalPlugins.
	
	"touch plugins to force their source generation unconditionally"
	allPlugins do: [:name | (Smalltalk globals at: name) touch ].
	
	" Why we put all plugins as external?   Because the generated sources are not different whether the plugins were defined as internal or external. VMMaker used to need this to to generate plugins.int and plugins.ext files. But since this is achieved in another way with CMakeVMMaker, there is no different at all to put all plugins as internal or as external."
	maker externalModules addAll:  allPlugins.
	
	^ maker
]

{ #category : #settings }
SqueakCocoaIOSConfig >> resources [ 
	^#('Squeak VM.r'
	'Cog.icns'
	'Squeak.icns'
	'SqueakChanges.icns'
	'SqueakPlugin.icns'
	'SqueakScript.icns'
	'SqueakGeneric.icns'
	'SqueakProject.icns'
	'SqueakSources.icns')


]

{ #category : #settings }
SqueakCocoaIOSConfig >> setExtraTargetProperties: maker [
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
		addXCodeProperty: 'PER_ARCH_CFLAGS_i386' value: '-finline-functions -mfpmath=sse -march=pentium-m -mtune=prescott -falign-functions=16  -fno-gcse -DLSB_FIRST';
		addXCodeProperty: 'PER_ARCH_CFLAGS_ppc' value: '-fast -mtune=7450 -mcpu=7450 -D_BSD_SOCKLEN_T_=int'
]

{ #category : #accessing }
SqueakCocoaIOSConfig >> srcDir [ 
	^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'platforms/iOS/vm/src' )]

]

{ #category : #'source files' }
SqueakCocoaIOSConfig >> standardIncludes [
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

{ #category : #directories }
SqueakCocoaIOSConfig >> write: aContents toFile: aFileName [
	"write a file to current output directory (buildDir).
	use line end convention appropriate for config platform"

	| bldDir |
	bldDir := self buildDir.
	bldDir isString
		ifTrue: [ bldDir := FileDirectory directoryEntryFor: bldDir ].
	bldDir assureExistence.
	bldDir
		forceNewFileNamed: aFileName
		do: [:s | s
				nextPutAll: (self fixLineEndsOf: aContents)]


]
