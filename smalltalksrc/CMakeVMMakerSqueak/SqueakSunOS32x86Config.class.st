"
A SqueakSunOS32x86CogConfig provides common informatin for my subclasses.

I am not meant to be built.

SqueakSunOS32x86Builder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp
"
Class {
	#name : #SqueakSunOS32x86Config,
	#superclass : #SqueakUnixConfig,
	#category : #'CMakeVMMakerSqueak-SunOS32x86'
}

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> addVMDriversBuild: aMaker [
	aMaker message: 'addVMDrivers: aMaker'.
	 self 
		addDriver: 'vm-display-null' 
		sources: #( 
			'${targetPlatform}/vm-display-null/sqUnixDisplayNull' )
		generator: aMaker
		externalLibs: #();
		
		addDriver: 'vm-display-X11' 
		sources: #( 
			'${targetPlatform}/vm-display-X11/sqUnixX11'
			'${targetPlatform}/vm-display-X11/sqUnixMozilla' )
		generator: aMaker
		externalLibs: (self linkFlags);

		addDriver: 'vm-sound-ALSA' 
		sources: #( 
			'${targetPlatform}/vm-sound-ALSA/sqUnixSoundALSA' )
		generator: aMaker
		externalLibs: #();

		addDriver: 'vm-sound-null' 
		sources: #( 
			'${targetPlatform}/vm-sound-null/sqUnixSoundNull' )
		generator: aMaker
		externalLibs: #().

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> addVMDriversBuildAssert: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> addVMDriversBuildAssertITimerHeartbeat: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> addVMDriversBuildDebug: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> addVMDriversBuildDebugITimerHeartbeat: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> addVMDriversBuildITimerHeartbeat: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> addVMDriversBuildMultiThreaded: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> addVMDriversBuildMultiThreadedAssert: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> addVMDriversBuildMultiThreadedDebug: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake configuration' }
SqueakSunOS32x86Config >> availableBuildTypes [
	 ^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes
"	subclasses should use

  ^super availableBuildTypes copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))   "
	

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> configHBuild [
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

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> configHBuildAssert [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> configHBuildAssertITimerHeartbeat [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> configHBuildDebug [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> configHBuildDebugITimerHeartbeat [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> configHBuildITimerHeartbeat [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> configHBuildMultiThreaded [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> configHBuildMultiThreadedAssert [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> configHBuildMultiThreadedDebug [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> coreSourcesBuild [
	self flag:'tty'. "Is this correct for this platform?"
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
		)
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> coreSourcesBuildAssert [
	^self coreSourcesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> coreSourcesBuildAssertITimerHeartbeat [
	^self coreSourcesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> coreSourcesBuildDebug [
	^self coreSourcesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> coreSourcesBuildDebugITimerHeartbeat [
	^self coreSourcesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> coreSourcesBuildITimerHeartbeat [
	^self coreSourcesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> coreSourcesBuildMultiThreaded [
	^self coreSourcesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> coreSourcesBuildMultiThreadedAssert [
	^self coreSourcesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> coreSourcesBuildMultiThreadedDebug [
	^self coreSourcesBuild

]

{ #category : #plugins }
SqueakSunOS32x86Config >> defaultExternalPlugins [
	^#(	)
]

{ #category : #plugins }
SqueakSunOS32x86Config >> defaultInternalPlugins [
	^#(	)
]

{ #category : #cmake }
SqueakSunOS32x86Config >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirSunOS32x86
]

{ #category : #cmake }
SqueakSunOS32x86Config >> excludeFromBuild [
	^true

]

{ #category : #cmake }
SqueakSunOS32x86Config >> executableName [
	"AbstractBaseClass configurations are not meant to be executable"
	^ self vmIShouldNotBeHereExecutableName
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> externalPluginsBuild [
	^ externalPlugins ifNil: [ externalPlugins := self defaultExternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> externalPluginsBuildAssert [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> externalPluginsBuildAssertITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> externalPluginsBuildDebug [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> externalPluginsBuildDebugITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> externalPluginsBuildITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> externalPluginsBuildMultiThreaded [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> externalPluginsBuildMultiThreadedAssert [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> externalPluginsBuildMultiThreadedDebug [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraVMSettingsBuild: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettingsBuild:'"
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraVMSettingsBuildAssertITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraVMSettingsBuildDebug: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraVMSettingsBuildDebugITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraVMSettingsBuildITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraVMSettingsBuildMultiThreaded: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraVMSettingsBuildMultiThreadedAssert: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> extraVMSettingsBuildMultiThreadedDebug: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> internalPluginsBuild [
	^ internalPlugins ifNil: [ internalPlugins := self defaultInternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> internalPluginsBuildAssert [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> internalPluginsBuildAssertITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> internalPluginsBuildDebug [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> internalPluginsBuildDebugITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> internalPluginsBuildITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> internalPluginsBuildMultiThreaded [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> internalPluginsBuildMultiThreadedAssert [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> internalPluginsBuildMultiThreadedDebug [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> postBuildActionsBuild: gen [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActionsBuild:'"
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> postBuildActionsBuildAssert: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> postBuildActionsBuildAssertITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> postBuildActionsBuildDebug: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> postBuildActionsBuildDebugITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> postBuildActionsBuildITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> postBuildActionsBuildMultiThreaded: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> postBuildActionsBuildMultiThreadedAssert: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> postBuildActionsBuildMultiThreadedDebug: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> preferredIncludesBuild [
"SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'"
	^ #( )

	

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> preferredIncludesBuildAssert [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> preferredIncludesBuildAssertITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> preferredIncludesBuildDebug [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> preferredIncludesBuildDebugITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> preferredIncludesBuildITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> preferredIncludesBuildMultiThreaded [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> preferredIncludesBuildMultiThreadedAssert [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> preferredIncludesBuildMultiThreadedDebug [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsAfterDetermineSystemBuild: aMaker [
	"do nothing (so far) on Unix.
	
	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsAfterDetermineSystemBuild:'
	"
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsAfterDetermineSystemBuildAssert: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsAfterDetermineSystemBuildAssertITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsAfterDetermineSystemBuildDebug: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsAfterDetermineSystemBuildDebugITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsAfterDetermineSystemBuildITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsAfterDetermineSystemBuildMultiThreaded: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedAssert: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedDebug: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsBuild: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsBuild'
	"
	self flag:'tty'. "I do not know that SunOS uses these compilers. This probably needs to change"
	aMaker set: 'CMAKE_C_COMPILER' to: '/usr/bin/gcc'.
	aMaker set: 'CMAKE_CXX_COMPILER' to: '/usr/bin/g++'.

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsBuildAssert: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsBuildAssertITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsBuildDebug: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsBuildDebugITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsBuildITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsBuildMultiThreaded: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsBuildMultiThreadedAssert: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> setGlobalOptionsBuildMultiThreadedDebug: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> standardIncludesBuild [ 
	^ #()
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> standardIncludesBuildAssert [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> standardIncludesBuildAssertITimerHeartbeat [
	^self standardIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> standardIncludesBuildDebug [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> standardIncludesBuildDebugITimerHeartbeat [
	^self standardIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> standardIncludesBuildITimerHeartbeat [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> standardIncludesBuildMultiThreaded [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> standardIncludesBuildMultiThreadedAssert [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
SqueakSunOS32x86Config >> standardIncludesBuildMultiThreadedDebug [ 
	^ self standardIncludesBuild
]
