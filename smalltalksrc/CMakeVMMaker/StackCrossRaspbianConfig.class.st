"
This is a concrete class which generates a StackVM for Raspbian (debian on RaspberryPi). But in cross compilation usage.


Usage: 
StackCrossRaspbianConfig generateWithSources


Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #StackCrossRaspbianConfig,
	#superclass : #StackUnixConfig,
	#category : #'CMakeVMMaker-Unix'
}

{ #category : #'as yet unclassified' }
StackCrossRaspbianConfig >> addDriver: name sources: aSources generator: cmakeGen [

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
			linkDirectories: '${CMAKE_FIND_ROOT_PATH}/usr/lib/arm-linux-gnueabihf/';
	 		includeDirectories: '${CMAKE_FIND_ROOT_PATH}/usr/include/';
			includeDirectories: '${crossDir}/plugins/FilePlugin';
			includeDirectories: '${targetPlatform}/plugins/B3DAcceleratorPlugin';
			includeDirectories: '${crossDir}/plugins/B3DAcceleratorPlugin';
			set: 'LIBRARY_OUTPUT_PATH' toString: self outputDir;
			cmd: 'set_target_properties' params: name , ' PROPERTIES PREFIX "" SUFFIX "" 
			LINK_FLAGS "', self linkFlags , '"'
	].
	
		
	self write: cfg toFile: ((self buildDir / name) assureExistence / cmakeGen outputFileName) fullName.
	cmakeGen addSubdirectory:  name.
	
]

{ #category : #'as yet unclassified' }
StackCrossRaspbianConfig >> addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs [

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
	 		includeDirectories: '${CMAKE_FIND_ROOT_PATH}/usr/include';
			includeDirectories: '${crossDir}/plugins/FilePlugin';
			includeDirectories: '${targetPlatform}/plugins/B3DAcceleratorPlugin';
			includeDirectories: '${crossDir}/plugins/B3DAcceleratorPlugin';
			set: 'LIBRARY_OUTPUT_PATH' toString: self outputDir fullName;
			linkDirectories: '${CMAKE_FIND_ROOT_PATH}/usr/lib/arm-linux-gnueabihf/';
		
			addExternalLibraries: extLibs;
			
			cmd: 'target_link_libraries' params: name , ' ${LINKLIBS}';
			cmd: 'set_target_properties' params: name , ' PROPERTIES PREFIX "" SUFFIX "" ' 
	].
	
	(self buildDir / name) ensureDirectory.
	self write: cfg toFile: name , '/', cmakeGen outputFileName.
	cmakeGen addSubdirectory:  name.
	
]

{ #category : #'as yet unclassified' }
StackCrossRaspbianConfig >> commonCompilerFlags [

	"Common compiler flags
	
	
	LSB_FIRST=1 means that target platform is little endian. 
	set it to 0 for big-endian platforms
	
	"
	
	^ {
		'-DLSB_FIRST=1'. 
		'-DUSE_GLOBAL_STRUCT=0'. 
		'-DCOGMTVM=0' } 	
	
]

{ #category : #'as yet unclassified' }
StackCrossRaspbianConfig >> compilerFlagsDebug [

	^ {
	'-g3'.
	'-O0'. 
	'-D_GNU_SOURCE'. 
	'-DITIMER_HEARTBEAT=1'. 
	'-DNO_VM_PROFILE=1'. 
	'-DDEBUGVM=1' }
]

{ #category : #'as yet unclassified' }
StackCrossRaspbianConfig >> compilerFlagsRelease [
"
THIS FLAGS ARE CRASHING COMPILER 
-fschedule-insns2 
-fschedule-insns 

THIS FLAGS ARE CRASHING VM
-ftree-pre  
-fcaller-saves 

THIS FLAGS ARE WORKING 
-O1 -fthread-jumps -falign-functions -falign-jumps -falign-loops -falign-labels -fcrossjumping -fcse-follow-jumps -fcse-skip-blocks -fdelete-null-pointer-checks -fdevirtualize -fexpensive-optimizations -fgcse -fgcse-lm -finline-small-functions -findirect-inlining -fipa-sra -foptimize-sibling-calls -fpeephole2 -fregmove -freorder-blocks -frerun-cse-after-loop -freorder-functions  -fsched-interblock -fsched-spec -fstrict-aliasing -fstrict-overflow  -ftree-switch-conversion -ftree-vrp

THIS IS LIKE: -O2 -fno-tree-pre -fno-caller-saves 

"

	^ {
		'-g0'. 
		'-O2'. 
		'-fno-tree-pre'. 
		'-fno-caller-saves'. 
		'-D_GNU_SOURCE'. 
		'-DNDEBUG'. 
		'-DITIMER_HEARTBEAT=1'. 
		'-DNO_VM_PROFILE=1'. 
		'-DDEBUGVM=0' }
]

{ #category : #'as yet unclassified' }
StackCrossRaspbianConfig >> configH [
	" right now its like  that "
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

{ #category : #'as yet unclassified' }
StackCrossRaspbianConfig >> configureB3DAcceleratorPlugin: maker [
	"extra rules for B3DAcceleratorPlugin"
	
	super configureB3DAcceleratorPlugin: maker.
	maker includeDirectories: '${CMAKE_FIND_ROOT_PATH}/usr/include/'.
]

{ #category : #'as yet unclassified' }
StackCrossRaspbianConfig >> configureBitBltSimulation: maker [
	"extra rules for BitBltSimulation"

	maker includeDirectories: '${pluginCross}'.

	maker addCrossSources: #(
		'BitBltGeneric.c'
		'BitBltDispatch.c'
	).
	
]

{ #category : #'as yet unclassified' }
StackCrossRaspbianConfig >> defaultExternalPlugins [
	^ #(
		B3DAcceleratorPlugin
		JPEGReaderPlugin 
		JPEGReadWriter2Plugin 			
		RePlugin
		InternetConfigPlugin
	)
]

{ #category : #'as yet unclassified' }
StackCrossRaspbianConfig >> defaultInternalPlugins [
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
		JoystickTabletPlugin 
		KlattSynthesizerPlugin "Klatt"
		LargeIntegersPlugin "LargeIntegers"
		Matrix2x3Plugin 
		MIDIPlugin 
		MiscPrimitivePlugin 
		Mpeg3Plugin  	
		SecurityPlugin 
		SerialPlugin 
		SocketPlugin 
		SoundCodecPlugin "SoundCodecPrims"
		SoundGenerationPlugin 
		SoundPlugin 
		StarSqueakPlugin 
		SurfacePlugin	
		LocalePlugin
		)
]

{ #category : #'as yet unclassified' }
StackCrossRaspbianConfig >> executableName [
	^ 'PharoS'
]

{ #category : #'as yet unclassified' }
StackCrossRaspbianConfig >> extraPluginSettings: maker [

	maker isExternal ifTrue: [
		"copy lib to results dir "
		maker set: 'LIBRARY_OUTPUT_PATH' to: '${outputDir}' 
	].	
	
	maker set: #linkFlags toString: '${linkFlags}'

]

{ #category : #'as yet unclassified' }
StackCrossRaspbianConfig >> linkFlags [
	 ^ '-lSM -lICE -ldl -lGL -lpthread -lm -lnsl -lX11'
]

{ #category : #'as yet unclassified' }
StackCrossRaspbianConfig >> preferredIncludes [
	^ #('${CMAKE_FIND_ROOT_PATH}/usr/include/'
	'${targetPlatform}/plugins/B3DAcceleratorPlugin')
	
]

{ #category : #'as yet unclassified' }
StackCrossRaspbianConfig >> setExtraTargetProperties: maker [

	"maker setTargetProperties: 'LINK_FLAGS ""'."
		
	maker puts: 'set_source_files_properties( ${srcVMDir}/cogit.c PROPERTIES 
		COMPILE_FLAGS "-O1 -fno-omit-frame-pointer -momit-leaf-frame-pointer")'.
		
		
	maker 
		cmd: 'set_source_files_properties'
		params: ' ${targetPlatform}/vm/sqUnixHeartbeat.c PROPERTIES 
		COMPILE_FLAGS "-O1 -fno-omit-frame-pointer"'.
						
	maker linkDirectories: '${CMAKE_FIND_ROOT_PATH}/usr/lib/arm-linux-gnueabihf/'.
	
	maker addExternalLibraries: 
		#(
			'm'  "math lib"
			'dl'  "dynamic loader"
			'pthread' "posix threads" 
		).
		
	maker set: 'EXECUTABLE_OUTPUT_PATH' toString: self outputDir fullName.
	self addVMDrivers: maker.
]
