"
A Linux32x86Config is a Squeak Compatibility Layer between the Pharo code in CMakeVMMaker and CMakeVMakerSqueak.

I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf


I am not meant to be built.

SqueakLinux32x86Builder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp


"
Class {
	#name : #Linux32x86Config,
	#superclass : #SqueakUnixConfig,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #'as yet unclassified' }
Linux32x86Config class >> initialize [
	isAbstractBaseClass:=true
]

{ #category : #'cmake configuration' }
Linux32x86Config >> availableBuildTypes [
	 ^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes
"	subclasses should use

  ^super availableBuildTypes copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))   "
	

]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> cCBuild [
	^{ 'gcc -m32'}
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> cCBuildAssert [
	^self cCBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> cCBuildAssertITimerHeartbeat [
	^self cCBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> cCBuildDebug [
	^self cCBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> cCBuildDebugITimerHeartbeat [
	^self cCBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> cCBuildITimerHeartbeat [
	^self cCBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> cCBuildMultiThreaded [
	^self cCBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> cCBuildMultiThreadedAssert [
	^self cCBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> cCBuildMultiThreadedDebug [
	^self cCBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> cXXBuild [
	^{ 'g++ -m32'}
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> cXXBuildAssert [
	^self cXXBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> cXXBuildAssertITimerHeartbeat [
	^self cXXBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> cXXBuildDebug [
	^self cXXBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> cXXBuildDebugITimerHeartbeat [
	^self cXXBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> cXXBuildITimerHeartbeat [
	^self cXXBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> cXXBuildMultiThreaded [
	^self cXXBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> cXXBuildMultiThreadedAssert [
	^self cXXBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> cXXBuildMultiThreadedDebug [
	^self cXXBuild
]

{ #category : #'compiler flags' }
Linux32x86Config >> commonCompilerFlags [
	"avoid premature optimization. push this decision down lower if it is needed at all"
	^{'-m32'}

]

{ #category : #'headers generation' }
Linux32x86Config >> configH [
	self flag:'tty'. "This needs to be customized"
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
#define	HAVE_DLFCN_H 1
#define	HAVE_ICONV_H 1

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

#define	ENABLE_FAST_BLT 1
#define	squeakInt64 long long

/* architecture */

#define	OS_TYPE "unix"
#define __arm__ 1
#define __ARM_ARCH_6__ 1
#define	VM_HOST "arm-pc-linux-gnu"
#define	VM_HOST_CPU "arm"
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

{ #category : #sources }
Linux32x86Config >> coreSources [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
		)
]

{ #category : #sources }
Linux32x86Config >> crossSources [ 
	^#(
			'sqHeapMap.c'
			'sqTicker.c'
			'sqExternalSemaphores.c'
			'sqNamedPrims.c'
			'sqVirtualMachine.c'
		)
]

{ #category : #plugins }
Linux32x86Config >> defaultExternalPlugins [
" tty 2014.06.10  cut-n-paste from Cog/build.linux32x86/newspeak.cog.spur/build/plugins.ext"
	^ #(B3DAcceleratorPlugin 
		BochsIA32Plugin 
	      ThreadedFFIPlugin    "moduleName->SqueakFFIPrims "
		"FFIPlugin"                   "moduleName->SqueakFFIPrims "
		SqueakSSLPlugin       "moduleName->SqueakSSL" 
		LocalePlugin 
		UnixOSProcessPlugin 
		UUIDPlugin)


"N.B. Regarding ThreadedFFIPlugin and FFIPlugin from eem:

Use  ThreadedFFIPlugin.  The FFIPlugin is obsolete (it requires assembler support files, and is non-reentrant).  This should generate in src/plugins/SqueakFFIPrims/{SqueakFFIPrims.c,ARM32FFIPlugin.c,IA32FFIPlugin.c} and you should compile only src/plugins/SqueakFFIPrims/SqueakFFIPrims.c.  src/plugins/SqueakFFIPrims/SqueakFFIPrims.c is a simple wrapper that includes ARM32FFIPlugin.c or IA32FFIPlugin.c as appropriate (and others can be added as they are developed).


"
]

{ #category : #plugins }
Linux32x86Config >> defaultInternalPlugins [
" tty 2014.06.10  cut-n-paste from Cog/build.linux32x86/newspeak.cog.spur/build/plugins.int
   N.B. moduleName->XYZ means XYZ appears in the GNU-Build's plugins.int/ext. However, Smalltalk requires the class name.
                                 XYZSmalltalkClass  moduleName->XYZ as it appears in plugins.int/ext
"
	^ #(
	    ADPCMCodecPlugin
    AsynchFilePlugin
    BalloonEnginePlugin "moduleName -->B2DPlugin"
    BitBltSimulation        "moduleName->BitBltPlugin"
    BMPReadWriterPlugin
    CroquetPlugin
    DeflatePlugin               "moduleName->ZipPlugin"
    DropPlugin
    DSAPlugin                    "moduleName->DSAPrims"
    FFTPlugin
    FileCopyPlugin
    FilePlugin
    FloatArrayPlugin
    FloatMathPlugin
    IA32ABIPlugin             "moduleName->IA32ABI"
   " InflatePlugin"               "moduleName->ZipPlugin"   "already included with the DeflatePlugin"
    JoystickTabletPlugin
    JPEGReaderPlugin
    JPEGReadWriter2Plugin
    KlattSynthesizerPlugin  "moduleName->Klatt"
    LargeIntegersPlugin      "moduleName->LargeIntegers"
    Matrix2x3Plugin
    MIDIPlugin
    MiscPrimitivePlugin
    Mpeg3Plugin
    RePlugin
    SecurityPlugin
    SerialPlugin
    SocketPlugin
    SoundCodecPlugin        "moduleName->SoundCodecPrims"
    SoundGenerationPlugin
    SoundPlugin
    StarSqueakPlugin
    SurfacePlugin
    VMProfileLinuxSupportPlugin)
]

{ #category : #cmake }
Linux32x86Config >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirLinux32x86
]

{ #category : #cmake }
Linux32x86Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build"
	^true
]

{ #category : #cmake }
Linux32x86Config >> executableName [
	"AbstractBaseClass configurations are not meant to be executable"
	^ self vmIShouldNotBeHereExecutableName
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> externalPluginsBuild [
	^ externalPlugins ifNil: [ externalPlugins := self defaultExternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> externalPluginsBuildAssert [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> externalPluginsBuildAssertITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> externalPluginsBuildDebug [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> externalPluginsBuildDebugITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> externalPluginsBuildITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> externalPluginsBuildMultiThreaded [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> externalPluginsBuildMultiThreadedAssert [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> externalPluginsBuildMultiThreadedDebug [
	^ self externalPluginsBuild
]

{ #category : #'plugin extra rules' }
Linux32x86Config >> extraPluginSettings: maker [
	super extraPluginSettings: maker.  
	maker set: #linkFlags toString: '${linkFlags} -m32'
]

{ #category : #settings }
Linux32x86Config >> extraVMSettings: maker [
	| versionC |
	self generateConfigH.
	
	"add a generated version.c"
	
	versionC := 'version.c'.
	
	maker cmd: 'add_custom_command' params: 'OUTPUT ',
		versionC , '
		COMMAND ${platformsDir}/unix/config/verstamp ',versionC,' gcc
		COMMENT "Generating version.c"
	'.
	
	
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> internalPluginsBuild [
	^ internalPlugins ifNil: [ internalPlugins := self defaultInternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> internalPluginsBuildAssert [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> internalPluginsBuildAssertITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> internalPluginsBuildDebug [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> internalPluginsBuildDebugITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> internalPluginsBuildITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> internalPluginsBuildMultiThreaded [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> internalPluginsBuildMultiThreadedAssert [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> internalPluginsBuildMultiThreadedDebug [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> lDFlagsBuild [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^ { 
		'-Wl'
           . '-z'
           . 'now'
	   }

]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> lDFlagsBuildAssert [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> lDFlagsBuildAssertITimerHeartbeat [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> lDFlagsBuildDebug [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> lDFlagsBuildDebugITimerHeartbeat [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> lDFlagsBuildITimerHeartbeat [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> lDFlagsBuildMultiThreaded [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> lDFlagsBuildMultiThreadedAssert [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> lDFlagsBuildMultiThreadedDebug [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> libsBuild [
	"Answer array of flags like the 	LIBS=''-lpthread -luuid''  line in the GNU system's mvm file
	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm 	SystemNavigation default browseMethodsWhoseNamesContain: 'libsBuild'"
	^ { 
		'-lpthread'
           . '-luuid'
	   }
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> libsBuildAssert [
	^self libsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> libsBuildAssertITimerHeartbeat [
	^self libsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> libsBuildDebug [
	^self libsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> libsBuildDebugITimerHeartbeat [
	^self libsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> libsBuildITimerHeartbeat [
	^self libsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> libsBuildMultiThreaded [
	^self libsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> libsBuildMultiThreadedAssert [
	^self libsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> libsBuildMultiThreadedDebug [
	^self libsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> postBuildActionsBuild: gen [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActionsBuild:'"
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> postBuildActionsBuildAssert: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> postBuildActionsBuildAssertITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> postBuildActionsBuildDebug: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> postBuildActionsBuildDebugITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> postBuildActionsBuildITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> postBuildActionsBuildMultiThreaded: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> postBuildActionsBuildMultiThreadedAssert: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux32x86Config >> postBuildActionsBuildMultiThreadedDebug: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'source files' }
Linux32x86Config >> preferredIncludesBuild [
	self flag:'tty'. "pharo does not support newspeak or sista., yet sets this in CogUnixConfig. Is this appropriate here? Revisit when coding newspeak etc"
	^ #(  '${targetPlatform}/plugins/AioPlugin'
 '${targetPlatform}/plugins/B3DAcceleratorPlugin'
 '${targetPlatform}/plugins/DropPlugin'
 '${targetPlatform}/plugins/FilePlugin'
 '${targetPlatform}/plugins/HostWindowPlugin'
 '${targetPlatform}/plugins/JPEGReadWriter2Plugin'
 '${targetPlatform}/plugins/LocalePlugin'
 '${targetPlatform}/plugins/Mpeg3Plugin'
 '${targetPlatform}/plugins/PseudoTTYPlugin'
 '${targetPlatform}/plugins/SerialPlugin'
 '${targetPlatform}/plugins/SoundPlugin'
 '${crossDir}/plugins/SoundGenerationPlugin'
 '${targetPlatform}/plugins/SqueakSSL'
 '${targetPlatform}/plugins/UnixOSProcessPlugin'
 '${targetPlatform}/plugins/AsynchFilePlugin'
 '${targetPlatform}/plugins/BochsIA32Plugin'
 '${targetPlatform}/plugins/FileCopyPlugin'
 '${targetPlatform}/plugins/FloatMathPlugin'
 '${targetPlatform}/plugins/InternetConfigPlugin'
 '${targetPlatform}/plugins/JoystickTabletPlugin'
 '${targetPlatform}/plugins/MIDIPlugin'
 '${targetPlatform}/plugins/PrintJobPlugin'
 '${targetPlatform}/plugins/SecurityPlugin'
 '${targetPlatform}/plugins/SocketPlugin'
 '${targetPlatform}/plugins/SqueakFFIPrims'
 '${targetPlatform}/plugins/UUIDPlugin'    
 '${targetPlatform}/plugins/XDisplayControlPlugin'

)


	

"SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'"
	

]

{ #category : #'source files' }
Linux32x86Config >> preferredIncludesBuildAssert [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux32x86Config >> preferredIncludesBuildAssertITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux32x86Config >> preferredIncludesBuildDebug [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux32x86Config >> preferredIncludesBuildDebugITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux32x86Config >> preferredIncludesBuildITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux32x86Config >> preferredIncludesBuildMultiThreaded [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux32x86Config >> preferredIncludesBuildMultiThreadedAssert [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux32x86Config >> preferredIncludesBuildMultiThreadedDebug [
	^self preferredIncludesBuild

]

{ #category : #utils }
Linux32x86Config >> setExtraTargetPropertiesBuild: aMaker [
	self flag:'tty'. "I am nervous about this method up here in this class, but pharo has it in CogUnixConfig, so using as is for now"

	aMaker setTargetProperties: 'LINK_FLAGS "-m32"'.
		
	aMaker puts: 'set_source_files_properties( ${srcVMDir}/cogit.c PROPERTIES 
		COMPILE_FLAGS "-O1 -fno-omit-frame-pointer -momit-leaf-frame-pointer -mno-rtd -mno-accumulate-outgoing-args")'.
		
	
	aMaker 
		cmd: 'set_source_files_properties'
		params: ' ${targetPlatform}/vm/sqUnixHeartbeat.c PROPERTIES 
		COMPILE_FLAGS "-O1 -fno-omit-frame-pointer -mno-rtd -mno-accumulate-outgoing-args"'.
	
	aMaker addExternalLibraries: 
		#(
			'uuid'  ""
			'ssl'  ""
			'crypto' ""
		).
					

]

{ #category : #utils }
Linux32x86Config >> setExtraTargetPropertiesBuildAssert: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #utils }
Linux32x86Config >> setExtraTargetPropertiesBuildAssertITimerHeartbeat: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #utils }
Linux32x86Config >> setExtraTargetPropertiesBuildDebug: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #utils }
Linux32x86Config >> setExtraTargetPropertiesBuildDebugITimerHeartbeat: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #utils }
Linux32x86Config >> setExtraTargetPropertiesBuildITimerHeartbeat: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #utils }
Linux32x86Config >> setExtraTargetPropertiesBuildMultiThreaded: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #utils }
Linux32x86Config >> setExtraTargetPropertiesBuildMultiThreadedAssert: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #utils }
Linux32x86Config >> setExtraTargetPropertiesBuildMultiThreadedDebug: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsAfterDetermineSystemBuild: aMaker [
	"do nothing (so far) on Unix.
	
	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsAfterDetermineSystemBuild:'
	"
]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsAfterDetermineSystemBuildAssert: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsAfterDetermineSystemBuildAssertITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsAfterDetermineSystemBuildDebug: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsAfterDetermineSystemBuildDebugITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsAfterDetermineSystemBuildITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsAfterDetermineSystemBuildMultiThreaded: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedAssert: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedDebug: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsBuild: aMaker [

	aMaker set: 'CMAKE_C_COMPILER' to: '/usr/bin/gcc'.
	aMaker set: 'CMAKE_CXX_COMPILER' to: '/usr/bin/g++'.

]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsBuildAssert: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsBuildAssertITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsBuildDebug: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsBuildDebugITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsBuildITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsBuildMultiThreaded: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsBuildMultiThreadedAssert: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #utils }
Linux32x86Config >> setGlobalOptionsBuildMultiThreadedDebug: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'source files' }
Linux32x86Config >> standardIncludesBuild [ 
	^#()
]

{ #category : #'source files' }
Linux32x86Config >> standardIncludesBuildAssert [ 
	^ self standardIncludesBuild
]

{ #category : #'source files' }
Linux32x86Config >> standardIncludesBuildAssertITimerHeartbeat [ 
	^ self standardIncludesBuild
]

{ #category : #'source files' }
Linux32x86Config >> standardIncludesBuildDebug [ 
	^ self standardIncludesBuild
]

{ #category : #'source files' }
Linux32x86Config >> standardIncludesBuildDebugITimerHeartbeat [ 
	^ self standardIncludesBuild
]

{ #category : #'source files' }
Linux32x86Config >> standardIncludesBuildITimerHeartbeat [ 
	^ self standardIncludesBuild
]

{ #category : #'source files' }
Linux32x86Config >> standardIncludesBuildMultiThreaded [ 
	^ self standardIncludesBuild
]

{ #category : #'source files' }
Linux32x86Config >> standardIncludesBuildMultiThreadedAssert [ 
	^ self standardIncludesBuild
]

{ #category : #'source files' }
Linux32x86Config >> standardIncludesBuildMultiThreadedDebug [ 
	^ self standardIncludesBuild
]
