Class {
	#name : #CogMacOSConfig,
	#superclass : #CPlatformConfig,
	#instVars : [
		'internalPlugins',
		'externalPlugins'
	],
	#category : #CMakeVMMaker
}

{ #category : #'as yet unclassified' }
CogMacOSConfig >> commonCompilerFlags [

	"Common compiler flags"
	
	^ '-arch i386 -fmessage-length=0 -Wno-trigraphs -fpascal-strings -fasm-blocks -DCOGMTVM=0 -DUSE_GLOBAL_STRUCT=0 -DTARGET_API_MAC_CARBON -DHAVE_SYS_TIME_H -mmacosx-version-min=10.5'
]

{ #category : #'as yet unclassified' }
CogMacOSConfig >> compilerFlags [
	"depends on config ..."
	^ self compilerFlagsRelease
]

{ #category : #'as yet unclassified' }
CogMacOSConfig >> compilerFlagsDebug [

	^ self commonCompilerFlags , ' -O0 -Wmissing-prototypes -Wmissing-braces -Wparentheses -Wunused-function -Wunused-label -Wunused-parameter -Wunused-variable -Wunused-value -Wsign-compare -DDEBUG -DDEBUGVM=1 -DEXTERNALPRIMSDEBUG=1 -gdwarf-2 '
]

{ #category : #'as yet unclassified' }
CogMacOSConfig >> compilerFlagsRelease [

	^ self commonCompilerFlags , ' -O3 -funroll-loops -ftree-vectorize -msse3 -DDEBUGVM=0 -DNDEBUG=1 -mdynamic-no-pic -Wunused-value -Wuninitialized -falign-functions=16 -fno-gcse -mtune=prescott -march=pentium-m -mfpmath=sse -finline-functions -Wall -DUSE_INLINE_MEMORY_ACCESSORS'
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
		FFIPlugin "SqueakFFIPrims"
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

{ #category : #plugins }
CogMacOSConfig >> externalPlugins [
	^ externalPlugins ifNil: [ externalPlugins := self defaultExternalPlugins ]
]

{ #category : #plugins }
CogMacOSConfig >> externalPlugins: aColl [

	externalPlugins := aColl
]

{ #category : #'as yet unclassified' }
CogMacOSConfig >> extraSources [
	" mac VM using some unix sources"
	
	^ 
	'${platformsDir}/unix/plugins/SocketPlugin/sqUnixSocket.c 
	${platformsDir}/unix/vm/aio.c 
	${platformsDir}/unix/plugins/AsynchFilePlugin/sqUnixAsynchFile.c
	${platformsDir}/unix/vm/sqUnixHeartbeat.c
	${platformsDir}/unix/vm/sqUnixVMProfile.c
	${platformsDir}/unix/vm/sqUnixThreads.c
	'
	
]

{ #category : #'as yet unclassified' }
CogMacOSConfig >> fixLineEndsOf: string [
	^ string copyReplaceAll: String cr with: String lf
]

{ #category : #'as yet unclassified' }
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
	inject: '' into: [:res :each | res , ' -framework ', each ]
]

{ #category : #'as yet unclassified' }
CogMacOSConfig >> ifMac: aBlock [ 
	^ aBlock value
]

{ #category : #plugins }
CogMacOSConfig >> internalPlugins [
	^ internalPlugins ifNil: [ internalPlugins := self defaultInternalPlugins ]
]

{ #category : #plugins }
CogMacOSConfig >> internalPlugins: aColl [

	internalPlugins := aColl
]

{ #category : #'as yet unclassified' }
CogMacOSConfig >> linkFlags [

	^ '-arch i386 ' , self frameworks
]

{ #category : #'as yet unclassified' }
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
	'sqMacUIEventsUniversal.c'  " -- not used: sqMacUIEvents.c "
	'sqMacUIMenuBarUniversal.c'
	'sqMacUnixCommandLineInterface.c'
	'sqMacUnixExternalPrims.c'
	'sqMacWindowUniversal.c'
	'version.c'	
	)
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
	)
	
]
