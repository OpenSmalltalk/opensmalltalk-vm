"
Defines used:

HAVE_MMAP  (how else Cog are supposed to work?)
"
Class {
	#name : #CogUnixConfig,
	#superclass : #CUnixConfig,
	#category : #CMakeVMMaker
}

{ #category : #'as yet unclassified' }
CogUnixConfig >> commonCompilerFlags [

	"Common compiler flags"
	
	^ ' -fmessage-length=0 -Wno-trigraphs -DCOGMTVM=0 -DUSE_GLOBAL_STRUCT=0 -DTARGET_API_MAC_CARBON -DHAVE_SYS_TIME_H'	
	
]

{ #category : #'as yet unclassified' }
CogUnixConfig >> compilerFlags [
	"depends on config ..."
	^ self compilerFlagsRelease
]

{ #category : #'as yet unclassified' }
CogUnixConfig >> compilerFlagsRelease [

	^ '-g -O2 -msse2 -D_GNU_SOURCE -DNDEBUG -DITIMER_HEARTBEAT=1 
	-DNO_VM_PROFILE=1 -DCOGMTVM=0 -DDEBUGVM=0'


]

{ #category : #'as yet unclassified' }
CogUnixConfig >> configH [
	" right now its like  that "
	^ '
	
#ifndef __sq_config_h
#define __sq_config_h

/* explicit image width */

#define HAVE_INTERP_H 1

/* package options */

#define USE_X11 1
/* #undef USE_X11 */
/* #undef USE_X11_GLX */
/* #undef USE_QUARTZ */
/* #undef USE_QUARTZ_CGL */
/* #undef USE_RFB */

/* libraries */

/* #undef HAVE_LIBX11 */
/* #undef HAVE_LIBXEXT */
#define HAVE_LIBDL 1
/* #undef HAVE_DYLD */
/* #undef HAVE_LIBFFI */
/* #undef HAVE_ICONV */

/* #undef USE_AUDIO_NONE */
/* #undef USE_AUDIO_SUN */
/* #undef USE_AUDIO_NAS */
/* #undef USE_AUDIO_OSS */
/* #undef USE_AUDIO_MACOSX */
/* #undef OSS_DEVICE */

/* header files */

#define HAVE_UNISTD_H 1
/* #undef NEED_GETHOSTNAME_P */

#define HAVE_DIRENT_H 1
/* #undef HAVE_SYS_NDIR_H */
/* #undef HAVE_SYS_DIR_H */
/* #undef HAVE_NDIR_H */
#define HAVE_DLFCN_H 1
#define HAVE_ICONV_H 1

#define HAVE_SYS_TIME_H 1
#define TIME_WITH_SYS_TIME 1

/* #undef HAVE_SYS_FILIO_H */

/* #undef HAVE_SYS_AUDIOIO_H */
/* #undef HAVE_SUN_AUDIOIO_H */

#define HAVE_PTY_H 1
/* #undef HAVE_UTIL_H */
/* #undef HAVE_LIBUTIL_H */
#define HAVE_STROPTS_H 1

/* #undef HAVE_GL_GL_H */
/* #undef HAVE_OPENGL_GL_H */

/* #undef NEED_SUNOS_H */

/* system calls/library functions */

#define AT_EXIT atexit

#define HAVE_TZSET 1

#define HAVE_OPENPTY 1
/* #undef HAVE_UNIX98_PTYS */

#define HAVE_SNPRINTF 1
/* #undef HAVE___SNPRINTF */

/* #undef HAVE_MMAP */

/* #undef HAVE_DYLD */

#define HAVE_LANGINFO_CODESET 1

#define HAVE_ALLOCA 1
#define HAVE_ALLOCA_H 1

#define HAVE_UNSETENV 1

#define HAVE_NANOSLEEP 1

/* widths of primitive types */

#define SIZEOF_INT 4
#define SIZEOF_LONG 4
#define SIZEOF_LONG_LONG 8
#define SIZEOF_VOID_P 4

/* structures */

#define HAVE_TM_GMTOFF 1
#define HAVE_TIMEZONE 1

/* typedefs */

/* #undef size_t */
/* #undef socklen_t */

#define squeakInt64 long long

/* architecture */

#define OS_TYPE "unix"

#define VM_HOST "i686-pc-linux-gnu"
#define VM_HOST_CPU "i686"
/* #undef VM_HOST_VENDOR */
#define VM_HOST_OS "linux-gnu"
#define VM_BUILD_STRING "Unix built on "__DATE__ " "__TIME__" Compiler: "__VERSION__

/* #undef WORDS_BIGENDIAN */
/* #undef DOUBLE_WORD_ALIGNMENT */

/* damage containment */

/* #undef DARWIN */

#ifdef NEED_SUNOS_H
# include "sunos.h"
#endif

/* other configured variables */

#define SQ_VERSION "3.9a-7024"
#define VM_VERSION "3.9-7"
#define VM_MODULE_PREFIX ""
/* #undef VM_DLSYM_PREFIX */
/* #undef VM_X11DIR */

/* avoid dependencies on glibc2.3 */


#define HAVE_MMAP 1
#define AVOID_OPENGL_H 1

#define HAVE_FEATURES_H 1

#if defined(HAVE_FEATURES_H)
# include "glibc.h"
#endif

#endif /* __sq_config_h */'
]

{ #category : #sources }
CogUnixConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
		)
]

{ #category : #plugins }
CogUnixConfig >> defaultExternalPlugins [
	^ #()
]

{ #category : #plugins }
CogUnixConfig >> defaultInternalPlugins [
" took from unixbuild/bld/plugins.int"
	^ #(
		ADPCMCodecPlugin 
		AsynchFilePlugin 
		BalloonEnginePlugin "B2DPlugin" 
		BitBltSimulation "BitBltPlugin"
		BMPReadWriterPlugin 
		CroquetPlugin 
		DeflatePlugin  "ZipPlugin"
		DropPlugin 
		DSAPlugin "DSAPrims" 
		FFTPlugin 
		FileCopyPlugin 
		FilePlugin 
		FloatArrayPlugin 
		FloatMathPlugin 
		IA32ABIPlugin "IA32ABI"
		JoystickTabletPlugin 
		JPEGReaderPlugin 
		JPEGReadWriter2Plugin 
		KlattSynthesizerPlugin "Klatt"
		LargeIntegersPlugin "LargeIntegers"
		Matrix2x3Plugin 
		MIDIPlugin 
		MiscPrimitivePlugin 
		Mpeg3Plugin 
		RePlugin 	
		SecurityPlugin 
		SerialPlugin 
		SocketPlugin 
		SoundCodecPlugin "SoundCodecPrims"
		SoundGenerationPlugin 
		SoundPlugin 
		StarSqueakPlugin 
		SurfacePlugin	
		)
]

{ #category : #'as yet unclassified' }
CogUnixConfig >> executableName [
	^ 'Cog'
]

{ #category : #sources }
CogUnixConfig >> extraSources [
	" mac VM using some unix sources"
	
	^ 
	'version.c'
]

{ #category : #'as yet unclassified' }
CogUnixConfig >> generateConfigH [
	"will fix that later"
	self write: self configH toFile: 'config.h'
]

{ #category : #sources }
CogUnixConfig >> platformSources [
	"files added from platform/unix/vm dir "
	^ #(
	'aio.c'
	'debug.c'
"	'dlfcn-dyld.c'
	'mac-alias.c' "
	'osExports.c'
	'sqUnixCharConv.c'
"	'sqUnixEvent.c' "
	'sqUnixExternalPrims.c'
	'sqUnixHeartbeat.c'
	'sqUnixMain.c'
	'sqUnixMemory.c'
	'sqUnixThreads.c'
	'sqUnixVMProfile.c'
	)
]

{ #category : #'as yet unclassified' }
CogUnixConfig >> setExtraTargetProperties: maker [

	
	  maker puts: 'set_source_files_properties( ${srcVMDir}/cogit.c PROPERTIES 
		COMPILE_FLAGS "-O1 -fno-omit-frame-pointer -momit-leaf-frame-pointer -mno-rtd -mno-accumulate-outgoing-args")'.
		
	super setExtraTargetProperties: maker.

]
