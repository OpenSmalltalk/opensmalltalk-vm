Class {
	#name : #StackCocoaIOSARMConfig,
	#superclass : #StackCocoaIOSCLANGConfig,
	#category : #'CMakeVMMaker-IOS'
}

{ #category : #settings }
StackCocoaIOSARMConfig >> architecture [ 
	^'"armv6" "armv7"'
]

{ #category : #accessing }
StackCocoaIOSARMConfig >> commonCompilerFlags [
	"Common compiler flags"
	^#('-arch armv6' 
	'-arch armv7' 
	'-miphoneos-version-min=4.3' 
	'-isysroot /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS4.3.sdk' 
	'-x objective-c'
	'-DTARGET_OS_IS_IPHONE'
	'-DHAVE_UUID_GENERATE')
]

{ #category : #settings }
StackCocoaIOSARMConfig >> compilerFlagsDebug [
	^#('-g3' '-O0' '-fvisibility=hidden' '-funroll-loops' '-fasm-blocks' '-finline-functions' '-mfpmath=sse' '-march=pentium-m' '-mtune=prescott' '-falign-functions=16' '-fno-gcse' '-fno-cse-follow-jumps' '-std=gnu99'  '-DUSE_INLINE_MEMORY_ACCESSORS' '-DLSB_FIRST' '-DUSE_INLINE_MEMORY_ACCESSORS' '-DHAVE_SYS_TIME_H' '-DHAVE_NANOSLEEP' '-DDEBUGVM=1' '-DCOGMTVM=0' '-DUSE_GLOBAL_STRUCT=0' '-DBASE_HEADER_SIZE=4')
]

{ #category : #settings }
StackCocoaIOSARMConfig >> compilerFlagsRelease [ 
	^#('-g0' '-Os' '-fvisibility=hidden' '-funroll-loops' '-fasm-blocks' '-finline-functions' '-mfpmath=sse' '-fomit-frame-pointer' '-march=pentium-m' '-mtune=prescott' '-falign-functions=16' '-fno-gcse' '-fno-cse-follow-jumps' '-std=gnu99' '-DUSE_INLINE_MEMORY_ACCESSORS' '-DLSB_FIRST' '-DUSE_INLINE_MEMORY_ACCESSORS' '-DHAVE_SYS_TIME_H' '-DHAVE_NANOSLEEP' '-DNDEBUG' '-DDEBUGVM=0' '-DCOGMTVM=0' '-DUSE_GLOBAL_STRUCT=0' '-DBASE_HEADER_SIZE=4')
]

{ #category : #settings }
StackCocoaIOSARMConfig >> defaultExternalPlugins [ 
	^#()
]

{ #category : #settings }
StackCocoaIOSARMConfig >> defaultInternalPlugins [
	^#()
	"^ #(
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
		LargeIntegersPlugin 
		Matrix2x3Plugin 
		MiscPrimitivePlugin 
		RePlugin 
		SecurityPlugin 
		SocketPlugin 
		SoundCodecPlugin 
		SoundGenerationPlugin 
		SoundPlugin
		SurfacePlugin
		UUIDPlugin
		IOSPlugin
		)"
]

{ #category : #accessing }
StackCocoaIOSARMConfig >> executableName [
	^ 'iStackVM'
]

{ #category : #accessing }
StackCocoaIOSARMConfig >> frameworks [
	^ #(
	"AppKit"
	"Cocoa"
	AudioToolbox
	CoreAudio
	CoreGraphics
	CoreLocation
	UIKit
	Foundation
	SystemConfiguration
	"ApplicationServices"
	QuartzCore
	OpenGLES)
]

{ #category : #'source files' }
StackCocoaIOSARMConfig >> platformSources [
	"files added from platform/iOS/vm dir "
	^ #(
		'Common/main.m'
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
		'iPhone/Classes/SqueakNoOGLIPhoneAppDelegate.m'
		'iPhone/Classes/sqSqueakIPhoneApplication.m'
		'iPhone/Classes/sqSqueakIPhoneApplication+attributes.m'
		'iPhone/Classes/sqSqueakIPhoneApplication+clipboard.m'
		'iPhone/Classes/sqSqueakIPhoneApplication+imageReadWrite.m'
		'iPhone/Classes/sqSqueakIPhoneApplication+events.m'
		'iPhone/Classes/sqSqueakIPhoneApplication+Network.m'
		'iPhone/Classes/sqSqueakiPhoneApplication+sound.m'
		'iPhone/Classes/sqSqueakIPhoneFileDirectoryInterface.m'
		'iPhone/Classes/sqSqueakIPhoneInfoPlistInterface.m'
		'iPhone/Classes/sqiPhoneScreenAndWindow.m'
		'iPhone/Classes/SqueakUIView.m'
		'iPhone/Classes/SqueakUIViewCALayer.m'
		'iPhone/Classes/SqueakUIViewOpenGL.m'
		'iPhone/Classes/SqueakUIController.m'
		'iPhone/Classes/sqSqueakIPhoneClipboardAPI.m'
		'iPhone/macintoshextra.c'
		'iPhone/osExports.c'
		'iPhone/sqDummyaio.c'
		'iPhone/sqMacV2Memory.c'
		)
]

{ #category : #settings }
StackCocoaIOSARMConfig >> precompiledImports [ 
	^#(
	'Foundation/Foundation.h' 
	'UIKit/UIKit.h')
]

{ #category : #settings }
StackCocoaIOSARMConfig >> setExtraTargetProperties: maker [
	"super setExtraTargetProperties: maker."

	| precompiledHeaders plist |
	
	precompiledHeaders := (self executableName, '_Prefix.pch').
	(maker buildDir forceNewFileNamed: precompiledHeaders) 
		nextPutAll: self precompiledHeaders;
		close.
	maker addXCodeProperty: 'GCC_PREFIX_HEADER' value: '${buildDir}/', precompiledHeaders.
	
	maker set: 'CMAKE_CROSSCOMPILING' to: 'TRUE'.
	maker set: 'CMAKE_SYSTEM_NAMEG' toString: 'Darwin'.
	maker set: 'CMAKE_SYSTEM_PROCESSOR' toString: 'arm'.

	maker set: 'SDKVER' toString: '5.0'.
	maker set: 'DEVROOT' toString: '/Developer/Platforms/iPhoneOS.platform/Developer'.
	maker set: 'SDKROOT' toString: '${DEVROOT}/SDKs/iPhoneOS${SDKVER}.sdk'.

	maker include: 'CMakeForceCompiler'.
	maker cmd: 'CMAKE_FORCE_C_COMPILER' params: '${DEVROOT}/usr/bin/clang CLang'.	
	maker cmd: 'CMAKE_FORCE_CXX_COMPILER' params: '${DEVROOT}/usr/bin/clang++ CLang'.

	maker set: 'CMAKE_FIND_ROOT_PATH' to: '"${SDKROOT}" "${DEVROOT}"'.
	maker set: 'CMAKE_FIND_ROOT_PATH_MODE_PROGRAM' to: 'NEVER'.
	maker set: 'CMAKE_FIND_ROOT_PATH_MODE_LIBRARY' to: 'ONLY'.
	maker set: 'CMAKE_FIND_ROOT_PATH_MODE_INCLUDE' to: 'ONLY'.
	
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

	maker 
		cmd: 'set_source_files_properties' 
		params: '${resourcesLocaleEnglish} PROPERTIES MACOSX_PACKAGE_LOCATION Resources/English.lproj'.

	maker 
		cmd: 'set_source_files_properties' 
		params: '${ENGLISH_RESOURCES} PROPERTIES MACOSX_PACKAGE_LOCATION Resources/English.lproj'.
			
	maker 
		cmd: 'set_target_properties' 
		params: self executableName, ' PROPERTIES COMPILE_FLAGS "-include \"', (self buildDir / self prefixHeaderFileName) fullName, '\""'. 
	
	maker set: 'EXECUTABLE_OUTPUT_PATH' toString: self outputDir.
	maker set: 'RUNTIME_OUTPUT_DIRECTORY' toString: self outputDir.

]
