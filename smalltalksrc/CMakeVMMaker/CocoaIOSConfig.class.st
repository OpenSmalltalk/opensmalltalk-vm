Class {
	#name : #CocoaIOSConfig,
	#superclass : #MacOSConfig,
	#category : #CMakeVMMaker
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
	^ 'SqueakImage.icns'
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

{ #category : #accessing }
CocoaIOSConfig >> commonCompilerFlags [
	"Common compiler flags"
	^ '-arch i386 -mmacosx-version-min=10.5 '	
	

]

{ #category : #accessing }
CocoaIOSConfig >> compilerFlags [ 
	^self commonCompilerFlags, self compilerFlagsRelease
]

{ #category : #accessing }
CocoaIOSConfig >> compilerFlagsRelease [ 
	self flag: #review. "There are more configurations in .xcodeproj"
	^'-fobjc-direct-dispatch -fno-objc-call-cxx-cdtors -msse3 -msse4.1 -msse4.2 -mdynamic-no-pic -fvisibility-inlines-hidden -mtune=G4 -fwritable-strings -Os -fvisibility=hidden -funroll-loops -fno-asm -std=gnu99 -fasm-blocks -finline-functions -mfpmath=sse -fomit-frame-pointer -march=pentium-m -mtune=prescott -falign-functions=16  -fno-gcse -fno-cse-follow-jumps  -DLSB_FIRST -DUSE_INLINE_MEMORY_ACCESSORS'
]

{ #category : #'plugin extra rules' }
CocoaIOSConfig >> configureHostWindowPlugin: maker [
	"extra rules for HostWindowPlugin"

	super configureHostWindowPlugin: maker.  
	maker 
		addSources: #( 'sqMacHostWindow.c' ) 
		prefixed: '${platformsDir}/iOS/vm/iPhone/plugins/HostWindowPlugin/'

]

{ #category : #'source files' }
CocoaIOSConfig >> coreSources [
	^#('interp.c')
]

{ #category : #'source files' }
CocoaIOSConfig >> crossSources [ 
	^#()
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
		ObjectiveCPlugin 
		RePlugin 
		SecurityPlugin 
		SocketPlugin 
		SoundCodecPlugin 
		SoundGenerationPlugin 
		SoundPlugin 
		StarSqueakPlugin 
		SurfacePlugin 
		UUIDPlugin)
]

{ #category : #plugins }
CocoaIOSConfig >> externalPlugins [
	^ externalPlugins ifNil: [ externalPlugins := self defaultExternalPlugins ]
]

{ #category : #settings }
CocoaIOSConfig >> extraPluginSettings: maker [
	maker set: 'CMAKE_OSX_ARCHITECTURES' to: 'i386'
]

{ #category : #'source files' }
CocoaIOSConfig >> extraSources [
	self flag: #todo. "This needs to be reified... it does't has any sense compared with #coreSources or #platformSources"
	^'${resources}'
]

{ #category : #settings }
CocoaIOSConfig >> extraVMSettings: maker [
	
	"Cog currently runs only in 32 bit mode" 
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
		"${resourceDir}/SqueakSources.icns"'

]

{ #category : #utils }
CocoaIOSConfig >> fixLineEndsOf: string [
	^ string copyReplaceAll: String cr with: String lf
]

{ #category : #accessing }
CocoaIOSConfig >> frameworks [
	^ #(
	Cocoa
	CoreFoundation
	Foundation
	AudioToolbox
	CoreAudio
	SystemConfiguration
	ApplicationServices
	QuartzCore
	OpenGL)
]

{ #category : #plugins }
CocoaIOSConfig >> internalPlugins [
	^ internalPlugins ifNil: [ internalPlugins := self defaultInternalPlugins ]
]

{ #category : #accessing }
CocoaIOSConfig >> linkFlags [ 
	^''
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
	)
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
	CFBundleIdentifier ) do: [:key |
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
	<string>${EXECUTABLE_NAME}</string>
	<key>CFBundleGetInfoString</key>
	<string>Squeak VM 5.7b3 http://www.squeak.org</string>
	<key>CFBundleIconFile</key>
	<string>Squeak.icns</string>
	<key>CFBundleIdentifier</key>
	<string>org.squeak.${PRODUCT_NAME:rfc1034identifier}</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>Squeak VM Host 64/32bits</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>5.7b3</string>
	<key>CFBundleSignature</key>
	<string>FAST</string>
	<key>CFBundleVersion</key>
	<string>21.0</string>
	<key>LSBackgroundOnly</key>
	<false/>
	<key>LSMinimumSystemVersion</key>
	<string>${MACOSX_DEPLOYMENT_TARGET}</string>
	<key>NSMainNibFile</key>
	<string>MainMenu</string>
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
CocoaIOSConfig >> setExtraTargetProperties: maker [

	| plist |

	" generated and add Info.plist file "
	plist := self plistFile.

	(maker buildDir forceNewFileNamed: 'Info.plist') 
		nextPutAll: plist; 
		close.
	
	maker targetPropertyAt: 'MACOSX_BUNDLE_INFO_PLIST' put: '${buildDir}/Info.plist'.

	maker cmd: 'set_source_files_properties' params: '${resources} PROPERTIES MACOSX_PACKAGE_LOCATION Resources'.
]

{ #category : #accessing }
CocoaIOSConfig >> srcDir [ 
	^'${topDir}/platforms/iOS/vm/src'
]

{ #category : #'source files' }
CocoaIOSConfig >> standardIncludes [
	^ #(
	'${crossDir}/plugins/SerialPlugin'   "for platforms/Mac OS/vm/osExports.c to work"
	'${targetPlatform}/plugins/FilePlugin'   "for sqMacFileLogic.h to work"
	'${targetPlatform}/plugins/HostWindowPlugin'  "for sqMacNSPluginUILogic2.c to work"
	'${platformsDir}/iOS/vm/iPhone/plugins/HostWindowPlugin' "for same... "
	'${crossDir}/plugins/DropPlugin' "include DropPlugin.h"
	'${crossDir}/plugins/SocketPlugin'
	'${crossDir}/plugins/AsynchFilePlugin'
	'${platformsDir}/unix/vm' "suppressing following:
		platforms/Mac OS/vm/sqMacMain.c:94:19: error: sqaio.h: No such file or directory
		platforms/Mac OS/vm/sqMacMain.c:96:28: error: sqUnixCharConv.h: No such file or directory"
	'${platformsDir}/iOS/vm/iPhone' "config.h is here. Why???"
)
	
]
