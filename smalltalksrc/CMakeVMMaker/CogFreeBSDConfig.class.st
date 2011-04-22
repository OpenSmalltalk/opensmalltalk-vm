Class {
	#name : #CogFreeBSDConfig,
	#superclass : #CogUnixConfig,
	#category : #'CMakeVMMaker-FreeBSD-Cog'
}

{ #category : #'as yet unclassified' }
CogFreeBSDConfig >> addDriver: name sources: aSources generator: cmakeGen [

	| cfg srcs |
	
	srcs := aSources inject: '' into: [:res :each | res , ' "', each, '"' ].
	cfg := cmakeGen
		captureOutputDuring: [
			cmakeGen printHeader;
			project: name;
			include: '../directories.cmake';
		
			message: 'Adding module: ', name;
			
			addDefinitions:  self compilerFlags;
			addDefinitions: '-fPIC -DPIC';
			set: #sources to: srcs;
			cmd: 'add_library' params: name, ' SHARED ${sources}'; 
			includeDirectories: '${crossDir}/plugins/FilePlugin';
			includeDirectories: '${targetPlatform}/plugins/B3DAcceleratorPlugin';
			includeDirectories: '${crossDir}/plugins/B3DAcceleratorPlugin';
			set: 'LIBRARY_OUTPUT_PATH' toString: self outputDir;
			cmd: 'set_target_properties' params: name , ' PROPERTIES PREFIX "" SUFFIX "" 
			LINK_FLAGS "-pthread -lm"'
	].
	
		
	self write: cfg toFile: ((self buildDir / name) assureExistence / cmakeGen outputFileName) fullName.
	cmakeGen addSubdirectory:  name.
	
]

{ #category : #'as yet unclassified' }
CogFreeBSDConfig >> addVMDrivers: maker [

	 self 
		addDriver: 'vm-display-null' 
		sources: #( 
			'${targetPlatform}/vm-display-null/sqUnixDisplayNull' )
		generator: maker;
		
		addDriver: 'vm-display-X11' 
		sources: #( 
			'${targetPlatform}/vm-display-X11/sqUnixX11'
			'${targetPlatform}/vm-display-X11/sqUnixMozilla' )
		generator: maker;
		
		addDriver: 'vm-sound-null' 
		sources: #( 
			'${targetPlatform}/vm-sound-null/sqUnixSoundNull' )
		generator: maker.
	
"
vm-display-null
	vm-display-X11
	vm-sound-null"
]

{ #category : #'as yet unclassified' }
CogFreeBSDConfig >> compilerFlags [

	"Common compiler flags
	
	
	LSB_FIRST=1 means that target platform is little endian. 
	set it to 0 for big-endian platforms
	
	"
	
	^ super compilerFlags, ' -I/usr/local/include'
]

{ #category : #'as yet unclassified' }
CogFreeBSDConfig >> compilerFlagsDebug [

	^ '-g3 -O0 -msse2  -DDEBUG=1 -DITIMER_HEARTBEAT=1 
	-DNO_VM_PROFILE=1 -DDEBUGVM=1 -DNOEXECINFO'
]

{ #category : #'as yet unclassified' }
CogFreeBSDConfig >> compilerFlagsRelease [

	^ '-g0 -O2 -msse2  -DNDEBUG=0 -DITIMER_HEARTBEAT=1 
	-DNO_VM_PROFILE=1 -DDEBUGVM=0 -DNOEXECINFO'

]

{ #category : #'as yet unclassified' }
CogFreeBSDConfig >> configH [
	" right now its like  that "
	^ '
#ifndef __sq_config_h
#define __sq_config_h

/* explicit image width */

#define HAVE_INTERP_H 1

/* package options */

#define USE_X11 1
#define USE_X11_GLX 1
/* #undef       USE_QUARTZ */
/* #undef       USE_QUARTZ_CGL */
/* #undef       USE_RFB */

/* libraries */

/* #undef       HAVE_LIBX11 */
#define HAVE_LIBXEXT 1
#define HAVE_LIBDL 1
/* #undef       HAVE_DYLD */
/* #undef       HAVE_LIBFFI */
/* #undef       HAVE_ICONV */

/* #undef       USE_AUDIO_NONE */
/* #undef       USE_AUDIO_SUN */
/* #undef       USE_AUDIO_NAS */
/* #undef       USE_AUDIO_OSS */
/* #undef       USE_AUDIO_MACOSX */
/* #undef       OSS_DEVICE */

/* header files */

#define HAVE_UNISTD_H 1
/* #undef       NEED_GETHOSTNAME_P */

#define HAVE_DIRENT_H 1
/* #undef       HAVE_SYS_NDIR_H */
/* #undef       HAVE_SYS_DIR_H */
/* #undef       HAVE_NDIR_H */
#define HAVE_DLFCN_H 1
/* #undef       HAVE_ICONV_H */

#define HAVE_SYS_TIME_H 1
#define TIME_WITH_SYS_TIME 1

#define HAVE_SYS_FILIO_H 1

/* #undef       HAVE_SYS_AUDIOIO_H */
/* #undef       HAVE_SUN_AUDIOIO_H */

/* #undef       HAVE_PTY_H */
/* #undef       HAVE_UTIL_H */
#define HAVE_LIBUTIL_H 1
/* #undef       HAVE_STROPTS_H */

#define HAVE_GL_GL_H 1
/* #undef       HAVE_OPENGL_GL_H */

/* #undef       NEED_SUNOS_H */


#define HAVE_UUID_H
/* system calls/library functions */

#define AT_EXIT atexit

#define HAVE_TZSET 1

#define HAVE_OPENPTY 1
/* #undef       HAVE_UNIX98_PTYS */

#define HAVE_SNPRINTF 1
/* #undef       HAVE___SNPRINTF */

#define HAVE_MMAP 1

/* #undef       HAVE_DYLD */

#define HAVE_LANGINFO_CODESET 1

#define HAVE_ALLOCA 1
/* #undef       HAVE_ALLOCA_H */

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

/* #undef       size_t */
/* #undef       socklen_t */

#define squeakInt64 long long

/* architecture */

#define OS_TYPE "unix"

#define VM_HOST "i386-freebsd8.2"
#define VM_HOST_CPU "i386"
/* #undef       VM_HOST_VENDOR */
#define VM_HOST_OS "freebsd8.2"
#define VM_BUILD_STRING "Unix built on "__DATE__ " "__TIME__" Compiler: "__VERSION__

/* #undef       WORDS_BIGENDIAN */
/* #undef       DOUBLE_WORD_ALIGNMENT */

/* damage containment */

/* #undef       DARWIN */

#ifdef NEED_SUNOS_H
# include "sunos.h"
#endif

/* other configured variables */

#define SQ_VERSION "3.9a-7024"
#define VM_VERSION "3.9-7"
#define VM_MODULE_PREFIX ""
/* #undef VM_DLSYM_PREFIX */
#define VM_X11DIR "/usr/X11R6/lib"

/* avoid dependencies on glibc2.3 */

/* #undef HAVE_FEATURES_H */

#if defined(HAVE_FEATURES_H)
# include "glibc.h"
#endif

#endif /* __sq_config_h */
																																																																					
																																																																				'
]

{ #category : #'as yet unclassified' }
CogFreeBSDConfig >> configureFloatMathPlugin: maker [
	"extra rules for FloatMathPlugin"

	maker addCrossSources: #(
		'acos.c' 'acosh.c' 'asin.c' 'asinh.c' 'atan.c' 'atan2.c' 'atanh.c'
		'copysign.c' 'cos.c' 'cosh.c' 'exp.c' 'expm1.c' 'finite.c' 'fmod.c'
		'hypot.c' 'isnan.c' 'k_cos.c' 'k_rem_pio2.c' 'k_sin.c' 'k_tan.c' 'ldexp.c'
		'log.c' 'log10.c' 'log1p.c' 'modf.c' 'pow.c' 'rem_pio2.c' 'rint.c'
		'scalb.c' 'scalbn.c' 'sin.c' 'sinh.c' 'sqrt.c' 'tan.c' 'tanh.c' ).

	
	"according to http://www.netlib.org/fdlibm/readme
	it should be compiled with no optimizations
	# 3/25/11 - DSG Removed -mno-fused-madd
	since FreeBSD will not support > GCC42"
	maker addDefinitions: '-O0'.
	
	" compile with -D__LITTLE_ENDIAN
		This macro is set automatically in fdlibm.h when compiled ith -m32 but
		not when compiled with -m64 (Nicolas Cellier)
	"
	self isLittleEndian ifTrue: [
		maker addDefinitions: '-D__LITTLE_ENDIAN=1' ].
	
	"On *nix & mac with -DNO_ISNAN "
	maker puts:'
if (${WIN32})
	add_definitions(-Werror-implicit-function-declaration)	
else(${WIN32})
	add_definitions(-DNO_ISNAN)
endif (${WIN32})'.


]

{ #category : #'as yet unclassified' }
CogFreeBSDConfig >> setExtraTargetProperties: maker [


	maker addExternalLibraries: 
		#(
			'm'  "math lib"
			'pthread' "posix threads" 
		).
		
	maker set: 'EXECUTABLE_OUTPUT_PATH' toString: self outputDir.
	self addVMDrivers: maker.
]
