"
A class to configure the Event-driven Stack Cog for Android. This configuration does not lead to building an executable; rather it prepares the source tree to be plugged into the jni subdirectory of an Android project.
"
Class {
	#name : #StackEvtAndroidConfig,
	#superclass : #CPlatformConfig,
	#category : #'CMakeVMMaker-Android'
}

{ #category : #'source generation' }
StackEvtAndroidConfig >> compilerFlags [
	"Compiler flags for Android. Leave empty for now"
	^  ' -DDEBUG=22 '
]

{ #category : #'source files' }
StackEvtAndroidConfig >> configH [
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
StackEvtAndroidConfig >> configureFT2Plugin: maker [
	"extra rules for Freetype plugin.
	a custom rule to build freetype library"

	maker addPlatformSources: #(  
	'src/base/ftbbox.c'
	'src/base/ftbitmap.c'
	'src/base/ftfstype.c'
	'src/base/ftglyph.c'
	'src/base/ftlcdfil.c'
	'src/base/ftstroke.c'
	'src/base/fttype1.c'
	'src/base/ftxf86.c'
	'src/base/ftbase.c'
	'src/base/ftsystem.c'
	'src/base/ftinit.c'
	'src/base/ftgasp.c'
	'src/raster/raster.c'
	'src/sfnt/sfnt.c'
	'src/smooth/smooth.c'
	'src/autofit/autofit.c'
	'src/truetype/truetype.c'
	'src/cff/cff.c'
	'src/psnames/psnames.c'
	'src/pshinter/pshinter.c'
	).

"
	maker addPlatformSources: #(  
                'src/psnames/pspic.c'
                'src/psnames/psmodule.c'
                'src/psnames/psnames.c'
                'src/raster/raster.c'
                'src/raster/ftraster.c'
                'src/raster/rastpic.c'
                'src/raster/ftrend1.c'
                'src/base/ftfstype.c'
                'src/base/ftbase.c'
                'src/base/ftbitmap.c'
                'src/base/fttype1.c'
                'src/base/ftgloadr.c'
                'src/base/ftxf86.c'
                'src/base/ftgasp.c'
                'src/base/ftobjs.c'
                'src/base/basepic.c'
                'src/base/ftsynth.c'
                'src/base/ftbbox.c'
                'src/base/ftsystem.c'
                'src/base/ftrfork.c'
                'src/base/ftpatent.c'
                'src/base/ftoutln.c'
                'src/base/ftsnames.c'
                'src/base/ftutil.c'
                'src/base/ftdbgmem.c'
                'src/base/fttrigon.c'
                'src/base/ftinit.c'
                'src/base/ftapi.c'
                'src/base/ftstroke.c'
                'src/base/ftcalc.c'
                'src/base/ftglyph.c'
                'src/base/ftstream.c'
                'src/base/ftlcdfil.c'
                'src/base/ftdebug.c'
                'src/base/ftpic.c'
                'src/base/ftadvanc.c'
                'src/base/ftmm.c'
                'src/base/ftwinfnt.c'
                'src/psaux/psaux.c'
                'src/psaux/afmparse.c'
                'src/psaux/psconv.c'
                'src/psaux/t1cmap.c'
                'src/psaux/psauxmod.c'
                'src/psaux/psobjs.c'
                'src/psaux/t1decode.c'
                'src/truetype/ttinterp.c'
                'src/truetype/ttgxvar.c'
                'src/truetype/ttobjs.c'
                'src/truetype/ttdriver.c'
                'src/truetype/ttpload.c'
                'src/truetype/ttgload.c'
                'src/truetype/truetype.c'
                'src/truetype/ttpic.c'
                'src/sfnt/ttmtx.c'
                'src/sfnt/ttpost.c'
                'src/sfnt/ttsbit.c'
                'src/sfnt/ttcmap.c'
                'src/sfnt/ttkern.c'
                'src/sfnt/ttbdf.c'
                'src/sfnt/sfnt.c'
                'src/sfnt/sfntpic.c'
                'src/sfnt/ttsbit0.c'
                'src/sfnt/ttload.c'
                'src/sfnt/sfobjs.c'
                'src/sfnt/sfdriver.c'
                'src/smooth/ftsmooth.c'
                'src/smooth/ftspic.c'
                'src/smooth/ftgrays.c'
                'src/smooth/smooth.c'
                'src/pshinter/pshrec.c'
                'src/pshinter/pshinter.c'
                'src/pshinter/pshmod.c'
                'src/pshinter/pshalgo.c'
                'src/pshinter/pshglob.c'
                'src/pshinter/pshpic.c'
                'src/cff/cff.c'
                'src/cff/cffpic.c'
                'src/cff/cffload.c'
                'src/cff/cffgload.c'
                'src/cff/cffparse.c'
                'src/cff/cffdrivr.c'
                'src/cff/cffcmap.c'
                'src/cff/cffobjs.c'
                'src/autofit/afloader.c'
                'src/autofit/afangles.c'
                'src/autofit/afindic.c'
                'src/autofit/aflatin2.c'
                'src/autofit/aflatin.c'
                'src/autofit/afwarp.c'
                'src/autofit/afglobal.c'
                'src/autofit/autofit.c'
                'src/autofit/afpic.c'
                'src/autofit/afmodule.c'
                'src/autofit/afcjk.c'
                'src/autofit/afdummy.c'
                'src/autofit/afhints.c'	
	).
	
"
	maker includeDirectories: '-I$(pluginPlatform)/include'.

]

{ #category : #'plugin extra rules' }
StackEvtAndroidConfig >> configureFileCopyPlugin: maker [
	"extra rules for FileCopyPlugin"

	maker addPlatformSources: #( 'sqAndroidFileCopyPlugin.c')

]

{ #category : #'plugin extra rules' }
StackEvtAndroidConfig >> configureFilePlugin: maker [
	"extra rules for FilePlugin"

	super configureFilePlugin: maker.  
	
	maker addPlatformSources: #( 'sqAndroidFile.c')
]

{ #category : #'plugin extra rules' }
StackEvtAndroidConfig >> configureFloatMathPlugin: maker [
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
StackEvtAndroidConfig >> configureJoystickTabletPlugin: maker [ 
	"extra rules for JoystickTabletPlugin"
	
	super configureJoystickTabletPlugin: maker.  
	maker addPlatformSources:
		#( 'sqAndroidJoystickTablet.c' )

]

{ #category : #'plugin extra rules' }
StackEvtAndroidConfig >> configureLocalePlugin: maker [
	"extra rules for LocalePlugin"

	super configureLocalePlugin: maker.  
	
	maker addPlatformSources: #( 'sqAndroidLocale.c')
]

{ #category : #'plugin extra rules' }
StackEvtAndroidConfig >> configureSecurityPlugin: maker [ 
	"extra rules for MIDIPlugin"

	super configureSecurityPlugin: maker.
	
	maker addPlatformSources: #( 'sqAndroidSecurity.c')
]

{ #category : #'plugin extra rules' }
StackEvtAndroidConfig >> configureSocketPlugin: maker [ 
	"extra rules for SocketPlugin"
	
	maker addPlatformSources: #( 'sqAndroidSocket.c')
]

{ #category : #'source files' }
StackEvtAndroidConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #'source files' }
StackEvtAndroidConfig >> crossSources [ 
	^#(
			'sqHeapMap.c'
			'sqNamedPrims.c'
			'sqVirtualMachine.c'
		)
]

{ #category : #plugins }
StackEvtAndroidConfig >> defaultExternalPlugins [
	^ #(
	)
]

{ #category : #plugins }
StackEvtAndroidConfig >> defaultInternalPlugins [
" took from unixbuild/bld/plugins.int"
	^ #(
		AndroidPlugin
		BitBltSimulation "BitBltPlugin"
		BalloonEnginePlugin "B2DPlugin" 
		BMPReadWriterPlugin 
		CroquetPlugin 
		DSAPlugin "DSAPrims" 
		FFTPlugin 
		FT2Plugin "FreeType"
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

{ #category : #'source generation' }
StackEvtAndroidConfig >> extraVMSettings: maker [
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
StackEvtAndroidConfig >> fixLineEndsOf: string [
	^ string copyReplaceAll: String cr with: String lf
]

{ #category : #'source generation' }
StackEvtAndroidConfig >> generate [
	^ CMakeAndroidGenerator generate: self 	


]

{ #category : #'source files' }
StackEvtAndroidConfig >> generateConfigH [
	"will fix that later"
	self write: self configH toFile: 'config.h'
]

{ #category : #'source generation' }
StackEvtAndroidConfig >> interpreterClass [
	^ StackEvtAndroidInterpreter
]

{ #category : #utils }
StackEvtAndroidConfig >> mkFileList: anArray baseDir: aDir [
	"answer the concatenated contents of the array interspersed with backslash-newline sequences"
	^ (anArray collect: [ :s | aDir, s]) inject: '' into: [ :s :n | s , #($\), {Character cr}, n ].
]

{ #category : #directories }
StackEvtAndroidConfig >> outputDir [

	"the directory where built binaries will be stored - for now it is copied from CogFamilyUnixConfig"
	^ outputDir ifNil: [ outputDir := (self buildDir containingDirectory fullName , '/', self outputDirName) ]
	
]

{ #category : #'source generation' }
StackEvtAndroidConfig >> platformName [
	^ 'android'
]

{ #category : #'source files' }
StackEvtAndroidConfig >> platformSources [
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
StackEvtAndroidConfig >> prepareForGeneration [

	"force using LF on Macs"
	CrLfFileStream defaultToLF.

	^ self prepareForStackVMGeneration

]

{ #category : #directories }
StackEvtAndroidConfig >> setupDirectories: gen [
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
