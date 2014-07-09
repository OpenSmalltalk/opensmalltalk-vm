"
A class to configure the Event-driven Stack Cog for Android. This configuration does not lead to building an executable; rather it prepares the source tree to be plugged into the jni subdirectory of an Android project.

Requires AndroidPlugin

Ported from pharo to squeak. 

tty: a lot of 'build' methods are included in this class in order to let the testing framework work consistently. They are not used.
"
Class {
	#name : #SqueakAndroidStackEvtConfig,
	#superclass : #SqueakUnixConfig,
	#category : #'CMakeVMMakerSqueak-Android'
}

{ #category : #'cmake configuration' }
SqueakAndroidStackEvtConfig >> availableBuildTypes [
	 ^SqueakCMakeVMMakerAbstractBuilder  default  noBuildTypes

]

{ #category : #'squeak compatibility' }
SqueakAndroidStackEvtConfig >> buildDirName [
	^'do not build. see class comment'
]

{ #category : #'source generation' }
SqueakAndroidStackEvtConfig >> cogitClass [
	^ StackToRegisterMappingCogit 

]

{ #category : #'source generation' }
SqueakAndroidStackEvtConfig >> compilerFlags [
	"Compiler flags for Android. Leave empty for now"
	^  ' -DDEBUG=22 '
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> configHBuild [
	"does nothing. included for framework consistency/testing 
	
	SystemNavigation default browseMethodsWhoseNamesContain: 'configHBuild'
	"
	
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> configHBuildAssert [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> configHBuildAssertITimerHeartbeat [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> configHBuildDebug [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> configHBuildDebugITimerHeartbeat [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> configHBuildITimerHeartbeat [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> configHBuildMultiThreaded [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> configHBuildMultiThreadedAssert [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> configHBuildMultiThreadedDebug [
	^ self configHBuild
]

{ #category : #'plugin extra rules' }
SqueakAndroidStackEvtConfig >> configureFileCopyPlugin: maker [
	"extra rules for DropPlugin"

	maker addPlatformSources: #( 'sqAndroidFileCopyPlugin.c')

]

{ #category : #'plugin extra rules' }
SqueakAndroidStackEvtConfig >> configureFilePlugin: maker [
	"extra rules for FilePlugin"

	super configureFilePlugin: maker.  
	
	maker addPlatformSources: #( 'sqAndroidFile.c')
]

{ #category : #'plugin extra rules' }
SqueakAndroidStackEvtConfig >> configureFloatMathPlugin: maker [
	"extra rules for FloatMathPlugin"

	maker addCrossSources: #(
		'acos.c' 'acosh.c' 'asin.c' 'asinh.c' 'atan.c' 'atan2.c' 'atanh.c'
		'copysign.c' 'cos.c' 'cosh.c' 'exp.c' 'expm1.c' 'finite.c' 'fmod.c'
		'hypot.c' 'isnan.c' 'k_cos.c' 'k_rem_pio2.c' 'k_sin.c' 'k_tan.c' 'ldexp.c'
		'log.c' 'log10.c' 'log1p.c' 'modf.c' 'pow.c' 'rem_pio2.c' 'rint.c'
		'scalb.c' 'scalbn.c' 'sin.c' 'sinh.c' 'sqrt.c' 'tan.c' 'tanh.c' ).

	
	"according to http://www.netlib.org/fdlibm/readme
	it should be compiled with no optimizations"
	maker addDefinitions: '-O0'.
	
	" compile with -D__LITTLE_ENDIAN
		This macro is set automatically in fdlibm.h when compiled ith -m32 but
		not when compiled with -m64 (Nicolas Cellier)
	"
	self isLittleEndian ifTrue: [
		maker addDefinitions: '-D__LITTLE_ENDIAN=1' ].

	maker addDefinitions: '-DNO_ISNAN'.
	


]

{ #category : #'plugin extra rules' }
SqueakAndroidStackEvtConfig >> configureJoystickTabletPlugin: maker [ 
	"extra rules for JoystickTabletPlugin"
	
	super configureJoystickTabletPlugin: maker.  
	maker addPlatformSources:
		#( 'sqAndroidJoystickTablet.c' )

]

{ #category : #'plugin extra rules' }
SqueakAndroidStackEvtConfig >> configureLocalePlugin: maker [
	"extra rules for LocalePlugin"

	super configureLocalePlugin: maker.  
	
	maker addPlatformSources: #( 'sqAndroidLocale.c')
]

{ #category : #'plugin extra rules' }
SqueakAndroidStackEvtConfig >> configureSecurityPlugin: maker [ 
	"extra rules for MIDIPlugin"

	super configureSecurityPlugin: maker.
	
	maker addPlatformSources: #( 'sqAndroidSecurity.c')
]

{ #category : #'plugin extra rules' }
SqueakAndroidStackEvtConfig >> configureSocketPlugin: maker [ 
	"extra rules for SocketPlugin"
	
	maker addPlatformSources: #( 'sqAndroidSocket.c')
]

{ #category : #'source files' }
SqueakAndroidStackEvtConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #'source files' }
SqueakAndroidStackEvtConfig >> crossSources [ 
	^#(
			'sqHeapMap.c'
			'sqNamedPrims.c'
			'sqVirtualMachine.c'
		)
]

{ #category : #plugins }
SqueakAndroidStackEvtConfig >> defaultExternalPlugins [
	^ #()
]

{ #category : #plugins }
SqueakAndroidStackEvtConfig >> defaultInternalPlugins [
" took from unixbuild/bld/plugins.int"
	^ #(
		AndroidPlugin
		BitBltSimulation "BitBltPlugin"
		BalloonEnginePlugin "B2DPlugin" 
		BMPReadWriterPlugin 
		CroquetPlugin 
		DSAPlugin "DSAPrims" 
		FFTPlugin 
		FileCopyPlugin 
		FilePlugin 
		FloatArrayPlugin 
		FloatMathPlugin 
		JoystickTabletPlugin 
		JPEGReaderPlugin 
		LargeIntegersPlugin "LargeIntegers"
		Matrix2x3Plugin 
		LocalePlugin
		RePlugin 	
		SecurityPlugin 
		JPEGReadWriter2Plugin 
		SocketPlugin 
		MiscPrimitivePlugin 
		DeflatePlugin  "ZipPlugin"
		)
]

{ #category : #cmake }
SqueakAndroidStackEvtConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self eventStackV3
]

{ #category : #cmake }
SqueakAndroidStackEvtConfig >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirAndroid
]

{ #category : #cmake }
SqueakAndroidStackEvtConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
SqueakAndroidStackEvtConfig >> executableName [
	^ self vmStackExecutableName
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> externalPluginsBuildAssert [
	^ self externalPluginsBuild
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> externalPluginsBuildAssertITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> externalPluginsBuildDebug [
	^ self externalPluginsBuild
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> externalPluginsBuildDebugITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> externalPluginsBuildITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> externalPluginsBuildMultiThreaded [
	^ self externalPluginsBuild
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> externalPluginsBuildMultiThreadedAssert [
	^ self externalPluginsBuild
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> externalPluginsBuildMultiThreadedDebug [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> extraPluginSettingsBuild: maker [
	^super extraPluginSettingsBuild: maker.  

]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> extraPluginSettingsBuildAssert: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> extraPluginSettingsBuildAssertITimerHeartbeat: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> extraPluginSettingsBuildDebug: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> extraPluginSettingsBuildDebugITimerHeartbeat: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> extraPluginSettingsBuildITimerHeartbeat: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> extraPluginSettingsBuildMultiThreaded: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> extraPluginSettingsBuildMultiThreadedAssert: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> extraPluginSettingsBuildMultiThreadedDebug: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> extraVMSettingsBuild: aMaker [
	| versionC |

	versionC := 'version.c'.

	aMaker 
		puts: '$(buildDir)/',versionC, ':' ;
		puts: ({Character tab}, '$(platformsDir)/android/config/verstamp ', '$(buildDir)/', versionC,' gcc');
		puts: {Character cr};
		puts: ('LOCAL_SRC_FILES += $(buildDir)/', versionC);
		puts: {Character cr}.
	.
	
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> extraVMSettingsBuildAssert: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> extraVMSettingsBuildAssertITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> extraVMSettingsBuildDebug: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> extraVMSettingsBuildDebugITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> extraVMSettingsBuildITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> extraVMSettingsBuildMultiThreaded: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> extraVMSettingsBuildMultiThreadedAssert: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> extraVMSettingsBuildMultiThreadedDebug: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'source generation' }
SqueakAndroidStackEvtConfig >> generate [
	^ CMakeAndroidGenerator generate: self 	


]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> internalPluginsBuild [
	^ internalPlugins ifNil: [ internalPlugins := self defaultInternalPlugins ]
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> internalPluginsBuildAssert [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> internalPluginsBuildAssertITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> internalPluginsBuildDebug [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> internalPluginsBuildDebugITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> internalPluginsBuildITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> internalPluginsBuildMultiThreaded [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> internalPluginsBuildMultiThreadedAssert [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> internalPluginsBuildMultiThreadedDebug [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'source generation' }
SqueakAndroidStackEvtConfig >> interpreterClass [
"Does not exist in squeak"
"	^ StackEvtAndroidInterpreter"
]

{ #category : #utils }
SqueakAndroidStackEvtConfig >> mkFileList: anArray baseDir: aDir [
	"answer the concatenated contents of the array interspersed with backslash-newline sequences"
	^ (anArray collect: [ :s | aDir, s]) inject: '' into: [ :s :n | s , #($\), {Character cr}, n ].
]

{ #category : #'source generation' }
SqueakAndroidStackEvtConfig >> platformName [
	^ 'android'
]

{ #category : #'source files' }
SqueakAndroidStackEvtConfig >> platformSources [
	"files added from platform/android/vm dir "
	^ #(
	'aio.c'
	'debug.c'
	'osExports.c'
	'sqAndroidCharConv.c'
	'sqAndroidExternalPrims.c'
	'sqAndroidEvtBeat.c'
	'sqAndroidEvtMain.c'
	'sqAndroidMemory.c'
	'sqAndroidVMProfile.c'
	'sqAndroidSemaphores.c'
	'sqAndroidSoundNull.c'
	'sqAndroidDisplay.c'
	)
]

{ #category : #'source files' }
SqueakAndroidStackEvtConfig >> preferredIncludesBuild [
^ #()
]

{ #category : #'source files' }
SqueakAndroidStackEvtConfig >> preferredIncludesBuildAssert [ 
	^ self preferredIncludesBuild
]

{ #category : #'source files' }
SqueakAndroidStackEvtConfig >> preferredIncludesBuildAssertITimerHeartbeat [ 
	^ self preferredIncludesBuild
]

{ #category : #'source files' }
SqueakAndroidStackEvtConfig >> preferredIncludesBuildDebug [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
SqueakAndroidStackEvtConfig >> preferredIncludesBuildDebugITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
SqueakAndroidStackEvtConfig >> preferredIncludesBuildITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
SqueakAndroidStackEvtConfig >> preferredIncludesBuildMultiThreaded [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
SqueakAndroidStackEvtConfig >> preferredIncludesBuildMultiThreadedAssert [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
SqueakAndroidStackEvtConfig >> preferredIncludesBuildMultiThreadedDebug [
	^self preferredIncludesBuild

]

{ #category : #'source generation' }
SqueakAndroidStackEvtConfig >> prepareForGeneration [

	"force using LF on Macs"
	CrLfFileStream defaultToLF.

	^ self prepareForStackVMGeneration

]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> setGlobalOptionsAfterDetermineSystemBuild: aMaker [
	"do nothing (so far) on Unix.
	
	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsAfterDetermineSystemBuild:'
	"
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> setGlobalOptionsAfterDetermineSystemBuildAssert: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> setGlobalOptionsAfterDetermineSystemBuildAssertITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> setGlobalOptionsAfterDetermineSystemBuildDebug: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> setGlobalOptionsAfterDetermineSystemBuildDebugITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> setGlobalOptionsAfterDetermineSystemBuildITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> setGlobalOptionsAfterDetermineSystemBuildMultiThreaded: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedAssert: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedDebug: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> setGlobalOptionsBuild: aMaker [
	"does nothing. included for framework consistency/testing 
	
	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsBuild'
	"
	
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> setGlobalOptionsBuildAssert: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> setGlobalOptionsBuildAssertITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> setGlobalOptionsBuildDebug: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> setGlobalOptionsBuildDebugITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> setGlobalOptionsBuildITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> setGlobalOptionsBuildMultiThreaded: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> setGlobalOptionsBuildMultiThreadedAssert: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> setGlobalOptionsBuildMultiThreadedDebug: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> standardIncludesBuild [ 
	^#()
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> standardIncludesBuildAssert [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> standardIncludesBuildAssertITimerHeartbeat [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> standardIncludesBuildDebug [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> standardIncludesBuildDebugITimerHeartbeat [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> standardIncludesBuildITimerHeartbeat [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> standardIncludesBuildMultiThreaded [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> standardIncludesBuildMultiThreadedAssert [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakAndroidStackEvtConfig >> standardIncludesBuildMultiThreadedDebug [ 
	^ self standardIncludesBuild
]
