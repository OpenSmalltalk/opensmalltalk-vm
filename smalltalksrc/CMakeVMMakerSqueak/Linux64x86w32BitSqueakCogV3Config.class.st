"
A slightly modified configuration, which avoids linking with openGL libraries.

SqueakLinux64x86w32CompatBuilder 
	configureABuildFor: #Linux32x86SqueakCogV3NoGLConfig withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp


Getting the UUIDPlugin to compile (not work, unfortunately, but compile) required modifying oscogvm/platforms/unix/plugins/acinclude.m4.
to read: (my Slackware system has <uuid> and uuidgen. then setting the 

# -*- sh -*-

AC_MSG_CHECKING([for UUID support])
AC_TRY_COMPILE([#include <sys/uuid.h>],[uuid_generatorxyz;],[
  AC_MSG_RESULT(yes)
  AC_CHECK_LIB(uuid, uuid_generator_xyz,LIB_UUID=""-luuid"" )
],[
  AC_MSG_RESULT(no)
  AC_MSG_CHECKING([for UUID support uuid/uuid.h] and uuid_generate)
  AC_TRY_COMPILE([#include <uuid/uuid.h>],[uuid_generate;],[
    AC_MSG_RESULT(yes)
    AC_CHECK_LIB(uuid, uuid_generate, LIB_UUID=""-luuid"")],[
    AC_MSG_RESULT(no)
      AC_MSG_CHECKING([for UUID support uuid and uuidgen] )
      AC_TRY_COMPILE([#include <uuid.h>],[uuidgen;],[
      AC_MSG_RESULT(yes)
       AC_CHECK_LIB(uuid, uuidgen, LIB_UUID=""-luuid"" )],[
       AC_MSG_RESULT(no)
        AC_PLUGIN_DISABLE
   ])
 ])
])




#define HAVE_UUID_H 1 
#define HAVE_UUIDGEN 1

fl;ags in my configH method


"
Class {
	#name : #Linux64x86w32BitSqueakCogV3Config,
	#superclass : #Linux64x86w32BitConfig,
	#category : #'CMakeVMMakerSqueak-Linux64X86-32BitCompatibility'
}

{ #category : #'source generation' }
Linux64x86w32BitSqueakCogV3Config >> cogitClass [
	^ StackToRegisterMappingCogit 

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> compilerFlagsBuild [
	"Some gcc versions (3.4*) create a broken VM using -O2, so try -O1 if you have problems"
	^{ 
  '-g3'                                               "more debugging"
 . '-O1'                                              "low optimization level"
 . '-m32'
 . '-msse2'
 . '-D_GNU_SOURCE'
 . '-D_FILE_OFFSET_BITS=64'
 . '-DNDEBUG'                                      "disable assertions"
 . '-DLSB_FIRST=1'                               ""
 . '-DUSE_GLOBAL_STRUCT=0'
 . '-DDEBUGVM=0'
 . '-DCOGMTVM=0'
 . '-fno-tree-pre	'
 . '-fno-caller-saves'
" . '-L/usr/lib'"
}


]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> compilerFlagsBuildAssert [
	^self compilerFlagsBuild

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> compilerFlagsBuildAssertITimerHeartbeat [
	^self compilerFlagsBuild

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> compilerFlagsBuildDebug [
	^self compilerFlagsBuild

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> compilerFlagsBuildDebugITimerHeartbeat [
	^self compilerFlagsBuild

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> compilerFlagsBuildITimerHeartbeat [
	^self compilerFlagsBuild

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> compilerFlagsBuildMultiThreaded [
	^self compilerFlagsBuild

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> compilerFlagsBuildMultiThreadedAssert [
	^self compilerFlagsBuild

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> compilerFlagsBuildMultiThreadedDebug [
	^self compilerFlagsBuild

]

{ #category : #'headers generation' }
Linux64x86w32BitSqueakCogV3Config >> configHBuild [
	^ '

#define HAVE_UUID_H 1 
#define HAVE_UUIDGEN 1

#ifndef __sq_config_h
#define __sq_config_h

/* explicit image width */

#define	HAVE_INTERP_H 1

/* package options */

#define	USE_X11 1

#undef	USE_X11_GLX 
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

#undef	HAVE_GL_GL_H
#undef	HAVE_OPENGL_GL_H 

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

#endif /* __sq_config_h */
																																																																					
																																																																				'
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> configureFlagsBuild [
	^{'-without-npsqueak' . '--without-vm-display-fbdev' . '--x-libraries=/usr/lib' }  
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> configureFlagsBuildAssert [
	^self configureFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> configureFlagsBuildAssertITimerHeartbeat [
	^self configureFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> configureFlagsBuildDebug [
	^self configureFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> configureFlagsBuildDebugITimerHeartbeat [
	^self configureFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> configureFlagsBuildITimerHeartbeat [
	^self configureFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> configureFlagsBuildMultiThreaded [
	^self configureFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> configureFlagsBuildMultiThreadedAssert [
	^self configureFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> configureFlagsBuildMultiThreadedDebug [
	^self configureFlagsBuild
]

{ #category : #plugins }
Linux64x86w32BitSqueakCogV3Config >> defaultExternalPlugins [
	""
		^ #(
		
		ThreadedFFIPlugin "SqueakFFIPrims"
		"UUIDPlugin"
		"UnixOSProcessPlugin ?? "	
		JPEGReaderPlugin 
		JPEGReadWriter2Plugin 			
		RePlugin
	)
]

{ #category : #'cmake directory ' }
Linux64x86w32BitSqueakCogV3Config >> dirBuildLanguageVMMM [
	^self squeakCogV3
]

{ #category : #cmake }
Linux64x86w32BitSqueakCogV3Config >> dirInstall [
	"the directory of the finished product.. the place where 'make install' puts stuff.
	SystemNavigation default browseMethodsWhoseNamesContain: 'outputDir'
      "
	^self squeakCogV3
]

{ #category : #cmake }
Linux64x86w32BitSqueakCogV3Config >> excludeFromBuild [
	^false   "build this configuration"
"	^true"


]

{ #category : #cmake }
Linux64x86w32BitSqueakCogV3Config >> executableName [
	^ self vmCogExecutableName
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> externalLibsBuild [
	self flag:'tty'. "this is dependent on plugins? what if I don't have SqueakSSLPlugin?"
	^#(
			'uuid'  ""
			'ssl'  ""
			'crypto' ""
			'm'      	"C math library"
			'dl'      "dynamic linking library"
			'pthread' "POSIX threads library"
			'SM'   "session management library for X11"
			'ICE'   "ICE is the Inter Client Exchange protocol, part of X11"
			'GL'    "libGL implements the GLX interface as well as the main OpenGL API entrypoints"
			'X11'
			'nsl'    "network services library"
		).
				


]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> externalLibsBuildAssert [
		^ self externalLibsBuild

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> externalLibsBuildAssertITimerHeartbeat [
		^ self externalLibsBuild

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> externalLibsBuildDebug [
		^ self externalLibsBuild

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> externalLibsBuildDebugITimerHeartbeat [
		^ self externalLibsBuild

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> externalLibsBuildITimerHeartbeat [
		^ self externalLibsBuild

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> externalLibsBuildMultiThreaded [
		^ self externalLibsBuild

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> externalLibsBuildMultiThreadedAssert [
		^ self externalLibsBuild

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> externalLibsBuildMultiThreadedDebug [
		^ self externalLibsBuild

]

{ #category : #'source generation' }
Linux64x86w32BitSqueakCogV3Config >> interpreterClass [
	^ CoInterpreter
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> lDFlagsBuild [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^ { 
		'-Wl'
           . '-z'
           . 'now'

	   }

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> lDFlagsBuildAssert [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> lDFlagsBuildAssertITimerHeartbeat [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> lDFlagsBuildDebug [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> lDFlagsBuildDebugITimerHeartbeat [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> lDFlagsBuildITimerHeartbeat [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> lDFlagsBuildMultiThreaded [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> lDFlagsBuildMultiThreadedAssert [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> lDFlagsBuildMultiThreadedDebug [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm"
	^self lDFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> linkFlagsBuild [
	"Answer array of libraries to link to"
	^ { '-L/usr/lib'
	     . '-L/usr/lib/X11'
           . '-luuid'
           . 'lSM' 
           . '-lICE'
           . '-ldl' 
           . '-lGL'
           . '-lpthread'
           . '-lm' 
           . '-lnsl'
           . '-lX11'
	   } 

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> linkFlagsBuildAssert [
	^self linkFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> linkFlagsBuildAssertITimerHeartbeat [
	^self linkFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> linkFlagsBuildDebug [
	^self linkFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> linkFlagsBuildDebugITimerHeartbeat [
	^self linkFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> linkFlagsBuildITimerHeartbeat [
	^self linkFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> linkFlagsBuildMultiThreaded [
	^self linkFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> linkFlagsBuildMultiThreadedAssert [
	^self linkFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> linkFlagsBuildMultiThreadedDebug [
	^self linkFlagsBuild
]
