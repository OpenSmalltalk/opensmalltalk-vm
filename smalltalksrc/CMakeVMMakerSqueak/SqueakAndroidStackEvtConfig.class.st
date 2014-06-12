"
A class to configure the Event-driven Stack Cog for Android. This configuration does not lead to building an executable; rather it prepares the source tree to be plugged into the jni subdirectory of an Android project.

Requires AndroidPlugin

Ported from pharo to squeak. 
"
Class {
	#name : #SqueakAndroidStackEvtConfig,
	#superclass : #CPlatformConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#instVars : [
		'buildType',
		'generateBuild',
		'generateBuildAssert',
		'generateBuildAssertITimerHeartbeat',
		'generateBuildDebug',
		'generateBuildDebugITimerHeartbeat',
		'generateBuildDebugMultiThreaded',
		'generateBuildIHeartbeatTimer',
		'generateBuildMultiThreaded',
		'generateBuildMultiThreadedAssert',
		'generateBuildMultiThreadedDebug'
	],
	#category : #'CMakeVMMakerSqueak-Android'
}

{ #category : #'as yet unclassified' }
SqueakAndroidStackEvtConfig class >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
SqueakAndroidStackEvtConfig >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default  noBuildConfigurations

]

{ #category : #directories }
SqueakAndroidStackEvtConfig >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #'squeak compatibility' }
SqueakAndroidStackEvtConfig >> buildDirName [
	^'do not build. see class comment'
]

{ #category : #'squeak compatibility' }
SqueakAndroidStackEvtConfig >> buildType: aSymbol [
	buildType:= aSymbol
]

{ #category : #'source generation' }
SqueakAndroidStackEvtConfig >> compilerFlags [
	"Compiler flags for Android. Leave empty for now"
	^  ' -DDEBUG=22 '
]

{ #category : #'source files' }
SqueakAndroidStackEvtConfig >> configH [
	" right now its borrowed directly from unix, but likely will change"
	^ '
#ifndef __sq_config_h
#define __sq_config_h

/* explicit image width */

#define	HAVE_INTERP_H 1

/* package options */

#define	USE_X11 1
#define	USE_X11_GLX 1
/* #undef	USE_QUARTZ */
/* #undef	USE_QUARTZ_CGL */
/* #undef	USE_RFB */

/* libraries */

/* #undef	HAVE_LIBX11 */
/* #undef	HAVE_LIBXEXT */
#define	HAVE_LIBDL 1
/* #undef	HAVE_DYLD */
/* #undef	HAVE_LIBFFI */
/* #undef	HAVE_ICONV */

/* #undef	USE_AUDIO_NONE */
/* #undef	USE_AUDIO_SUN */
/* #undef	USE_AUDIO_NAS */
/* #undef	USE_AUDIO_OSS */
/* #undef	USE_AUDIO_MACOSX */
/* #undef	OSS_DEVICE */

/* header files */

#define	HAVE_UNISTD_H 1
/* #undef	NEED_GETHOSTNAME_P */

#define	HAVE_DIRENT_H 1
/* #undef	HAVE_SYS_NDIR_H */
/* #undef	HAVE_SYS_DIR_H */
/* #undef	HAVE_NDIR_H */

#define	HAVE_SYS_TIME_H 1
#define	TIME_WITH_SYS_TIME 1

/* #undef	HAVE_SYS_FILIO_H */

/* #undef	HAVE_SYS_AUDIOIO_H */
/* #undef	HAVE_SUN_AUDIOIO_H */

#define	HAVE_PTY_H 1
/* #undef	HAVE_UTIL_H */
/* #undef	HAVE_LIBUTIL_H */
#define	HAVE_STROPTS_H 1

#define	HAVE_GL_GL_H 1
/* #undef	HAVE_OPENGL_GL_H */

/* #undef	NEED_SUNOS_H */

/* system calls/library functions */

#define	AT_EXIT atexit

#define	HAVE_TZSET 1

#define	HAVE_OPENPTY 1
/* #undef	HAVE_UNIX98_PTYS */

#define	HAVE_SNPRINTF 1
/* #undef	HAVE___SNPRINTF */

#define	HAVE_MMAP 1

/* #undef	HAVE_DYLD */

#define	HAVE_LANGINFO_CODESET 1

#define	HAVE_ALLOCA 1
#define	HAVE_ALLOCA_H 1

#define	HAVE_UNSETENV 1

#define	HAVE_NANOSLEEP 1

/* widths of primitive types */

#define	SIZEOF_INT 4
#define	SIZEOF_LONG 4
#define	SIZEOF_LONG_LONG 8
#define	SIZEOF_VOID_P 4

/* structures */

#define	HAVE_TM_GMTOFF 1
#define	HAVE_TIMEZONE 1

/* typedefs */

/* #undef	size_t */
/* #undef	socklen_t */

#define	squeakInt64 long long

/* architecture */

#define	OS_TYPE "unix"

#define	VM_HOST "i686-pc-linux-gnu"
#define	VM_HOST_CPU "i686"
/* #undef	VM_HOST_VENDOR */
#define	VM_HOST_OS "linux-gnu"
#define	VM_BUILD_STRING "Unix built on "__DATE__ " "__TIME__" Compiler: "__VERSION__

/* #undef	WORDS_BIGENDIAN */
/* #undef	DOUBLE_WORD_ALIGNMENT */

/* damage containment */

/* #undef	DARWIN */

#ifdef NEED_SUNOS_H
# include "sunos.h"
#endif

/* other configured variables */

#define SQ_VERSION "3.9a-7024"
#define VM_VERSION "3.9-7"
#define VM_MODULE_PREFIX ""
/* #undef VM_DLSYM_PREFIX */
#define VM_X11DIR ""

/* avoid dependencies on glibc2.3 */

#define HAVE_FEATURES_H 1

#if defined(HAVE_FEATURES_H)
# include "glibc.h"
#endif


/* used by UUID plugin: */

#define HAVE_UUID_H 1

#endif /* __sq_config_h */
																																																																					
																																																																				'
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

{ #category : #cmake }
SqueakAndroidStackEvtConfig >> configureNoBuildType [
		generateBuild:=generateBuildAssert:=generateBuildAssertITimerHeartbeat:=generateBuildDebug:=generateBuildDebugITimerHeartbeat:= generateBuildDebugMultiThreaded:= generateBuildIHeartbeatTimer:= generateBuildMultiThreaded:= generateBuildMultiThreadedAssert:= generateBuildMultiThreadedDebug:=false.
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
	^ #(
	)
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
"	^false"   "build this configuration"
	^true
]

{ #category : #'source generation' }
SqueakAndroidStackEvtConfig >> extraVMSettings: maker [
	| versionC |
	self generateConfigH.
	
	"add a generated version.c"
	
	versionC := 'version.c'.

	maker 
		puts: '$(buildDir)/',versionC, ':' ;
		puts: ({Character tab}, '$(platformsDir)/android/config/verstamp ', '$(buildDir)/', versionC,' gcc');
		puts: {Character cr};
		puts: ('LOCAL_SRC_FILES += $(buildDir)/', versionC);
		puts: {Character cr}.
	.
	
]

{ #category : #utils }
SqueakAndroidStackEvtConfig >> fixLineEndsOf: string [
	^ string copyReplaceAll: String cr with: String lf
]

{ #category : #'source generation' }
SqueakAndroidStackEvtConfig >> generate [
	^ CMakeAndroidGenerator generate: self 	


]

{ #category : #'source files' }
SqueakAndroidStackEvtConfig >> generateConfigH [
	"will fix that later"
	self write: self configH toFile: 'config.h'
]

{ #category : #'initialize-release' }
SqueakAndroidStackEvtConfig >> initialize [
	super initialize.
	"this should be in my superclass, but I do not have permission to modify it. tty"
	 generateForAssert:= generateForAssertHeartbeatTimer:= generateForDebug :=generateForDebugWithHeartbeatTimer:= generateForDebugMultiThreadedFFI:= generateForReleaseHeartbeatTimer:= generateForReleaseMultiThreadedFFI:=false
]

{ #category : #'source generation' }
SqueakAndroidStackEvtConfig >> interpreterClass [
	^ StackEvtAndroidInterpreter
]

{ #category : #utils }
SqueakAndroidStackEvtConfig >> mkFileList: anArray baseDir: aDir [
	"answer the concatenated contents of the array interspersed with backslash-newline sequences"
	^ (anArray collect: [ :s | aDir, s]) inject: '' into: [ :s :n | s , #($\), {Character cr}, n ].
]

{ #category : #directories }
SqueakAndroidStackEvtConfig >> outputDir [
	^outputDir ifNil: [ outputDir := (self topDir / self outputDirName) ]	
	
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

{ #category : #'source generation' }
SqueakAndroidStackEvtConfig >> prepareForGeneration [

	"force using LF on Macs"
	CrLfFileStream defaultToLF.

	^ self prepareForStackVMGeneration

]

{ #category : #directories }
SqueakAndroidStackEvtConfig >> setupDirectories: gen [
	"same logic as the super has, but use gmake syntax instead of cmake"
	| dirsInclude |

	" write the directories in separate include file"
	dirsInclude := gen captureOutputDuring: [
		gen
			set: #topDir to: ('$(ROOT)/', self topDir fullName); 
			set: #buildDir to: (self buildDir ifNil: ['$(topDir)/build'] ifNotNil: ['$(ROOT)/', self buildDir fullName] );
			set: #platformsDir to: ('$(ROOT)/', self platformsDir);
			set: #srcDir to: ('$(ROOT)/', self srcDir);
			set: #srcPluginsDir to: (pluginsDir ifNil: [ '$(srcDir)/plugins' ]);
			set: #srcVMDir to: '$(srcDir)/vm';
			set: #platformName to: self platformName;
			set: #targetPlatform to: '$(platformsDir)/$(platformName)';
			set: #crossDir to: '$(platformsDir)/Cross';
			set: #platformVMDir to: '$(targetPlatform)/vm'.
	].

	self write: dirsInclude toFile: 'cogdirs.mk'

]

{ #category : #directories }
SqueakAndroidStackEvtConfig >> srcDir [
		^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'stacksrc' )]
]

{ #category : #directories }
SqueakAndroidStackEvtConfig >> topDir [
		^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
]
