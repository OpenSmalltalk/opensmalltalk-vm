"
A SqueakUnixConfig is a top level configuration for *nix configuratons.

"
Class {
	#name : #SqueakUnixConfig,
	#superclass : #CPlatformConfigForSqueak,
	#category : #CMakeVMMakerSqueak
}

{ #category : #'compiler flags' }
SqueakUnixConfig >> commonCompilerFlags [

	"Common compiler flags
	
	
	LSB_FIRST=1 means that target platform is little endian. 
	set it to 0 for big-endian platforms
	
	"
	
	^ {
		'-DLSB_FIRST=1'. 
		'-DUSE_GLOBAL_STRUCT=0'. 
		'-DCOGMTVM=0'. 
		'-m32'.
		'-DENABLE_FAST_BLT ' } 	
	
]

{ #category : #'headers generation' }
SqueakUnixConfig >> configH [
"ONLY USED ON UNIX CONFIGS included here for completeness and consistency CogUnixConfig browse.
"
"
Use  configH to tell your plugins where to find its libraries etc.
The version of this is platform dependent.
You may also need to edit your oscogvm/platforms/YOUR PLATFORM/plugins/ThePLuginDirectory/acinclude.m4 file so that it conforms to your system.

tty needed a custom version of this in Linux32x86SqueakCogV3NoGLConfig in order to build the UUIDPlugin.

Go to oscogvm/platforms/YOUR PLATFORM/plugins/ThePLuginDirectory and look at the acinclude.m4 file
you may need to edit that .

NOTE: CPlatformConfig contains a useable version of this that you can modify. 

I reproduce it here, but with double quotes changed to two single quotes so that the commenting will hold.
I provide a <---N.B quotes need changing at each place they have been modified.

Again. it is easier to copy the one in CPlatformConfig.


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

#define OS_TYPE ''unix''    <---N.B quotes need changing at each place they have been modifying.

#define VM_HOST ''i386-freebsd8.2''    <---N.B quotes need changing at each place they have been modifying.
#define VM_HOST_CPU ''i386''    <---N.B quotes need changing at each place they have been modifying.
/* #undef       VM_HOST_VENDOR */
#define VM_HOST_OS ''freebsd8.2''   <---N.B quotes need changing at each place they have been modifying.
#define VM_BUILD_STRING ''Unix built on ''__DATE__ '' ''__TIME__'' Compiler: ''__VERSION__          <---N.B quotes need changing at each place they have been modifying.

/* #undef       WORDS_BIGENDIAN */
/* #undef       DOUBLE_WORD_ALIGNMENT */

/* damage containment */

/* #undef       DARWIN */

#ifdef NEED_SUNOS_H
# include ''sunos.h''    <---N.B quotes need changing at each place they have been modifying.
#endif

/* other configured variables */

#define SQ_VERSION ''3.9a-7024''    <---N.B quotes need changing at each place they have been modifying.
#define VM_VERSION ''3.9-7''    <---N.B quotes need changing at each place they have been modifying.
#define VM_MODULE_PREFIX ''    <---N.B quotes need changing at each place they have been modifying.
/* #undef VM_DLSYM_PREFIX */    
#define VM_X11DIR '/usr/X11R6/lib'    <---N.B quotes need changing at each place they have been modifying.

/* avoid dependencies on glibc2.3 */

/* #undef HAVE_FEATURES_H */

#if defined(HAVE_FEATURES_H)
# include ''glibc.h''    <---N.B quotes need changing at each place they have been modifying.
#endif

#endif /* __sq_config_h */
																																																																					
																																																																				'
"
]

{ #category : #accessing }
SqueakUnixConfig >> executableType [
	^ ''

]

{ #category : #accessing }
SqueakUnixConfig >> externalModulesDir [
	"answer the location in VM bundle, where plugins and rest of dynamic libs will be copied,
	"
	^ '${outputDir}'
]

{ #category : #'source files' }
SqueakUnixConfig >> extraSources [	
	self flag:'tty'. "?"
	^ 'version.c'
]

{ #category : #accessing }
SqueakUnixConfig >> frameworks [
	"leave empty for all platforms but Mac OS"
	^ #()
]

{ #category : #'headers generation' }
SqueakUnixConfig >> generateConfigH [
		self write: self configH toFile: 'config.h'

]

{ #category : #'source files' }
SqueakUnixConfig >> platformSources [
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

{ #category : #'squeak compatability' }
SqueakUnixConfig >> setupDirectories: gen [
	super setupDirectories: gen.
	gen set: #externalModulesDir toString: self externalModulesDir.
]
