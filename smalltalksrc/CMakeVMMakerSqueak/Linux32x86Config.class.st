"
A Linux32x86Config is a Squeak Compatibility Layer between the Pharo code in CMakeVMMaker and CMakeVMakerSqueak.

I exist because modifying the pharo tree is verbotten as of 2014.06.10


"
Class {
	#name : #Linux32x86Config,
	#superclass : #CogFamilyUnixConfig,
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
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #'squeak compatibility' }
Linux32x86Config >> addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs [

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
			set: 'LIBRARY_OUTPUT_PATH' toString: self outputDir fullName;
			addExternalLibraries: extLibs;
			cmd: 'target_link_libraries' params: name , ' ${LINKLIBS}';
			cmd: 'set_target_properties' params: name , ' PROPERTIES PREFIX "" SUFFIX "" 
			LINK_FLAGS -m32' 
	].
	
	(self buildDir / name) assureExistence.
	self write: cfg toFile: name , '/', cmakeGen outputFileName.
	cmakeGen addSubdirectory:  name.
	
]

{ #category : #cmake }
Linux32x86Config >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default allBuildConfigurations copyWithoutAll:#(#releaseMultiThreadedFFI #debugMultiThreadedFFI)

]

{ #category : #'squeak compatibility' }
Linux32x86Config >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> buildDirName [
	buildType isNil
		ifTrue:[^self dirBuildPlatform, FileDirectory slash, self dirBuildLanguageVMMM, FileDirectory slash, 'build']
		ifFalse:[^self dirBuildPlatform, FileDirectory slash, self dirBuildLanguageVMMM, FileDirectory slash, buildType asString]
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> buildScript [
	"answer the build script for building everything"
	

	^ 
'#!/usr/bin/env bash

cmake .
make

'
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> buildType: aSymbol [
	buildType:= aSymbol
]

{ #category : #'source generation' }
Linux32x86Config >> cogitClass [
	^ StackToRegisterMappingCogit 
]

{ #category : #'compiler flags' }
Linux32x86Config >> commonCompilerFlags [
	self flag: 'tty'. "pull up common flags from subclasses on a refactoring pass."
	^#()
]

{ #category : #'compiler flags' }
Linux32x86Config >> compilerFlags [
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self compilerFlagsBuild];
		at: #buildAssert  put: [self compilerFlagsAssert];
		at: #buildAssertITimerHeartbeat  put: [self compilerFlagsAssertITimerHeartbeat];
            at:#buildDebug  put: [self compilerFlagsDebug];   "located in CMakeVMMaker CPlatformConfig"
		at: #buildDebugITimerHeartbeat  put: [self compilerFlagsDebugITimerHeartbeat ];
		at: #buildDebugMultiThreaded  put: [self compilerFlagsDebugMultiThreaded];
		at: #buildITimerHeartbeat  put: [self compilerFlagsIHeartbeatTimer];
		at: #buildMultiThreaded  put: [self compilerFlagsMultiThreaded ];
		at: #buildMultiThreadedAssert  put: [self compilerFlagsMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self compilerFlagsMultiThreadedDebug ];
		at: #buildNone put:[self compilerFlagsNoBuildType].
     (d at:  buildType) value.

	^ String streamContents: [ :stream |
		((self commonCompilerFlags) collect: #withBlanksTrimmed as: Set)
			asStringOn: stream 
			delimiter: ' ' ]
]

{ #category : #cmake }
Linux32x86Config >> compilerFlagsDebug [

	^ {
		'-g3'. 
		'-O0'. 
		'-msse2'. 
		'-D_GNU_SOURCE'. 
		'-DITIMER_HEARTBEAT=1'. 
		'-DNO_VM_PROFILE=1'. 
		'-DDEBUGVM=1' }
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> configH [
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

{ #category : #cmake }
Linux32x86Config >> configureBuildAssertITimerHeartbeat [
	generateBuildAssertITimerHeartbeat:=true.
]

{ #category : #cmake }
Linux32x86Config >> configureForBuildType: aSymbol [
	| d info |
	"provide a concrete builder with the buildType and configureBuildX method to invoke"
	info := SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	self configureNoBuildType.                "reset all internal flags"
	d 
		at: #build 
		put: [self buildType:(info at:#build).  self configureBuild];

		at: #buildAssert 
		put: [self buildType:(info at: #buildAssert).  	self configureBuildAssert];

		at: #buildAssertITimerHeartbeat 
		put:     [ self buildType:(info at: #buildAssertITimerHeartbeat ).   self configureBuildAssertITimerHeartbeat];

            at:#buildDebug 
		put: [self buildType:(info at: #buildDebug ).  self configureBuildDebug];

		at: #buildDebugITimerHeartbeat 
		put:  [self buildType:(info at: #buildDebugITimerHeartbeat).   self configureBuildDebugITimerHeartbeat];

		at: #buildDebugMultiThreaded 
		put: [self buildType:(info at: #buildDebugMultiThreaded ).   self configureBuildDebugMultiThreaded];

		at: #buildITimerHeartbeat 
		put: [self buildType:(info at:#buildITimerHeartbeat ).    self configureBuildIHeartbeatTimer];

		at: #buildMultiThreaded 
		put:  [self buildType:(info at:#buildMultiThreaded ). self configureBuildMultiThreaded];

		at: #buildMultiThreadedAssert 
		put: [self buildType:(info at: #buildMultiThreadedAssert). self configureBuildMultiThreadedAssert];

		at: #buildMultiThreadedDebug  
		put: [self buildType: (info at: #buildMultiThreadedDebug). self configureBuildMultiThreadedDebug].

     ^(d at: aSymbol).
]

{ #category : #cmake }
Linux32x86Config >> configureNoBuildType [
		generateBuild:=generateBuildAssert:=generateBuildAssertITimerHeartbeat:=generateBuildDebug:=generateBuildDebugITimerHeartbeat:= generateBuildDebugMultiThreaded:= generateBuildIHeartbeatTimer:= generateBuildMultiThreaded:= generateBuildMultiThreadedAssert:= generateBuildMultiThreadedDebug:=false.
]

{ #category : #sources }
Linux32x86Config >> coreSources [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
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
Linux32x86Config >> dirArmv6 [
	^'cmake.build.arm.v6'
]

{ #category : #cmake }
Linux32x86Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogV3
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

{ #category : #accessing }
Linux32x86Config >> executableName [
	self required
]

{ #category : #'plugin extra rules' }
Linux32x86Config >> extraPluginSettings: maker [
	super extraPluginSettings: maker.  
	maker set: #linkFlags toString: '${linkFlags} -m32'
]

{ #category : #sources }
Linux32x86Config >> extraSources [
	self flag: 'tty'. "what is this?"
	^ 'version.c'
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> extraVMSettings: maker [
	self generateConfigH.
	
	
	"output a fake version.c file"
	
	self write:
'int vm_serial= 1;
char *vm_date= "<HERE IS SUPPOSED TO BE THE DATE>";
char *cc_version= "<HERE IS SUPPOSED TO BE gcc VERSION>";
char *ux_version= "<FAKE FROZEN VERSION FOR DEBUGGING PURPOSES>";
'
	toFile: 'version.c'.

]

{ #category : #'squeak compatibility' }
Linux32x86Config >> generate [
	self generatePluginsList. 
	self generateLicense. 
	^ CMakeVMGeneratorForSqueak generate: self 
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> generateConfigH [
	"will fix that later"
	self write: self configH toFile: 'config.h'
]

{ #category : #'initialize-release' }
Linux32x86Config >> initialize [
	super initialize.
	"this should be in my superclass, but I do not have permission to modify it. tty"
	 generateForAssert:= generateForAssertHeartbeatTimer:= generateForDebug :=generateForDebugWithHeartbeatTimer:= generateForDebugMultiThreadedFFI:= generateForReleaseHeartbeatTimer:= generateForReleaseMultiThreadedFFI:=false
]

{ #category : #accessing }
Linux32x86Config >> linkFlags [
	^ super linkFlags , ' -m32'


]

{ #category : #cmake }
Linux32x86Config >> oscogvm [
	^ 'oscogvm'
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> outputDir [

	"the directory where built binaries will be stored"
	^ outputDir ifNil: [ outputDir := (self topDir / self outputDirName) ]	


]

{ #category : #sources }
Linux32x86Config >> platformSources [
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

{ #category : #'squeak compatibility' }
Linux32x86Config >> prepareVMMaker [
	
	| maker allPlugins |
	
	"In CogVMs (in contrast to Interpreter VM) the generated sources are platform independent, therefore Cross is ok"
	maker := VMMaker forPlatform: 'Cross'.
	
	maker sourceDirectoryName: self srcDir pathName.
	maker platformRootDirectoryName: self platformsDir.
	
	
	allPlugins := self internalPlugins , self externalPlugins.
	
	"touch plugins to force their source generation unconditionally"
	allPlugins do: [:name | (Smalltalk globals at: name) touch ].
	
	" Why we put all plugins as external?   Because the generated sources are not different whether the plugins were defined as internal or external. VMMaker used to need this to to generate plugins.int and plugins.ext files. But since this is achieved in another way with CMakeVMMaker, there is no different at all to put all plugins as internal or as external."
	maker externalModules addAll:  allPlugins.
	
	^ maker
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> setupDirectories: gen [
	| dirsInclude |

	" write the directories in separate include file"
	dirsInclude := gen captureOutputDuring: [
		gen
			set: #topDir toString: (self topDir fullName); 
			set: #buildDir toString: (self buildDir ifNil: ['${topDir}/build'] ifNotNil: [self buildDir fullName] );
			set: #thirdpartyDir toString: '${buildDir}/thirdParty';
			set: #platformsDir toString: self platformsDir;
			set: #srcDir toString: self srcDir pathName;
			set: #srcPluginsDir toString: (pluginsDir ifNil: [ '${srcDir}/plugins' ]);
			set: #srcVMDir toString: '${srcDir}/vm';
			set: #platformName toString: self platformName;
			set: #targetPlatform to: '${platformsDir}/${platformName}';
			set: #crossDir toString: '${platformsDir}/Cross';
			set: #platformVMDir toString: '${targetPlatform}/vm';
			set: #outputDir toString: self outputDir fullName.
	].

	self write: dirsInclude toFile: 'directories.cmake'.
	
	gen include: 'directories.cmake'.

]

{ #category : #'squeak compatibility' }
Linux32x86Config >> srcDir [
		^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'src' )]
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> topDir [
	"N.B. this is a clash between Trait usage and Inheritence usage due to restrictions on modifying pharo's source"
	^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
	
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> validateSourcesPresent [
	| sources |
	sources := Smalltalk sourcesName.
	
	(sources == nil)
		ifTrue: [	self error: 'VM source code cannot be generated without .sources file'.]		
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> write: aContents toFile: aFileName [
	"write a file to current output directory (buildDir).
	use line end convention appropriate for config platform"

	| bldDir |
	bldDir := self buildDir.
	bldDir isString
		ifTrue: [ bldDir := FileDirectory directoryEntryFor: bldDir ].
	bldDir assureExistence.
	bldDir
		forceNewFileNamed: aFileName
		do: [:s | s
				nextPutAll: (self fixLineEndsOf: aContents)]


]
