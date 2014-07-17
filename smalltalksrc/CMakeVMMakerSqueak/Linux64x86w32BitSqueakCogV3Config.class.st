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

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> cmakeAddDefinitionsBuild [
	"from oscogvm/build.linux32x86/squeak.cog.v3/build/mvm"
	(enabledebugmessages)
		ifTrue:[	templates 
		addLast:((CMakeMessage new) message: (self class name) , 'cmakeAddDefinitionsBuild')
	] .
	templates
		addLast:((CMakeAddDefinitions new) definitions: (self compilerDefinitions asOrderedCollection)).

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> cmakeCFlagsBuild [
	|cflags|
	self flag:'tty'. "#build should have -O2"
	cflags:= String streamContents: [:stream | (self compilerFlags) asStringOn: stream delimiter: ' ' ].
	cflags:='"', cflags, '"'.
	(enabledebugmessages)
		ifTrue:[	templates 
		addLast:((CMakeMessage new) message: (self class name) , 'cmakeCFlagsBuild')
	] .
	templates
		addLast:((CMakeSet new) variable:'CMAKE_CXX_FLAGS' value: '${CMAKE_CXX_FLAGS} ', cflags );
		addLast:((CMakeSet new) variable:'CMAKE_C_FLAGS' value: '${CMAKE_C_FLAGS} ', cflags );
		addLast:((CMakeSet new) variable:'CMAKE_CXX_FLAGS_RELEASE' value: '${CMAKE_CXX_FLAGS_RELEASE} ', cflags );
		addLast:((CMakeSet new) variable:'CMAKE_CXX_FLAGS_DEBUG' value: '${CMAKE_CXX_FLAGS_DEBUG} ', cflags ).

	(enabledebugmessages)  "take a peek at em"
		ifTrue:[	templates 
		addLast:((CMakeMessage new) message: 'CMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}');
		addLast:((CMakeMessage new) message: 'CMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG}');
		addLast:((CMakeMessage new) message: 'CMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}');
		addLast:((CMakeMessage new) message: 'CMAKE_C_FLAGS=${CMAKE_C_FLAGS}');
		addLast:((CMakeMessage new) message: 'CMAKE_C_FLAGS_DEBUG=${CMAKE_C_FLAGS_DEBUG}');
		addLast:((CMakeMessage new) message: 'CMAKE_C_FLAGS_RELEASE=${CMAKE_C_FLAGS_RELEASE}')
	] .



]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> cmakeSetSourceFilesPropertiesBuild [
	|cflags|
	cflags:=String streamContents: [:stream | (self compilerFlags) asStringOn: stream delimiter: ' ' ].
	(enabledebugmessages)
		ifTrue:[	templates 
		addLast:((CMakeMessage new) message: (self class name) , 'cmakeSetSourceFilesPropertiesBuild')
	] .
	templates
		addLast:((CMakeSetSourceFilesProperties new) 
			files: (OrderedCollection with: '${srcVMDir}/cogit.c') 
			propertiesandvalues:{'COMPILE_FLAGS' . cflags});
		addLast:((CMakeSetSourceFilesProperties new) 
			files: (OrderedCollection with: '${targetPlatform}/vm/sqUnixHeartbeat.c') 
			propertiesandvalues:{'COMPILE_FLAGS' . cflags}).
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> cmakeSharedLinkerFlagsBuild [

	(enabledebugmessages)
		ifTrue:[	templates 
		addLast:((CMakeMessage new) message: (self class name) , 'cmakeSharedLinkerFlagsBuild')
	] .
	templates
		addLast:((CMakeSet new) 
			variable:'CMAKE_SHARED_LINKER_FLAGS' 
			quotedValue:'${CMAKE_SHARED_LINKER_FLAGS} ', (String streamContents: [:stream | (self linkerFlags ) asStringOn: stream delimiter: ' ' ])).

	(enabledebugmessages)
		ifTrue:[	templates 
			addLast:((CMakeMessage new) message: 'CMAKE_C_LINKER_PREFERENCE = ${CMAKE_C_LINKER_PREFERENCE}');
			addLast:((CMakeMessage new) message: 'CMAKE_C_LINKER_PREFERENCE_PROPAGATES = ${CMAKE_C_LINKER_PREFERENCE_PROPAGATES}');
			addLast:((CMakeMessage new) message: 'CMAKE_CXX_LINKER_PREFERENCE = ${CMAKE_CXX_LINKER_PREFERENCE}');
			addLast:((CMakeMessage new) message: 'CMAKE_CXX_LINKER_PREFERENCE_PROPAGATES = ${CMAKE_CXX_LINKER_PREFERENCE_PROPAGATES}');
			addLast:((CMakeMessage new) message: 'CMAKE_EXE_LINKER_FLAGS = ${CMAKE_EXE_LINKER_FLAGS}');
			addLast:((CMakeMessage new) message: 'CMAKE_EXE_LINKER_FLAGS_DEBUG = ${CMAKE_EXE_LINKER_FLAGS_DEBUG}');
			addLast:((CMakeMessage new) message: 'CMAKE_EXE_LINKER_FLAGS_RELEASE = ${CMAKE_EXE_LINKER_FLAGS_RELEASE}');
			addLast:((CMakeMessage new) message: 'CMAKE_MODULE_LINKER_FLAGS = ${CMAKE_MODULE_LINKER_FLAGS}');
			addLast:((CMakeMessage new) message: 'CMAKE_MODULE_LINKER_FLAGS_DEBUG = ${CMAKE_MODULE_LINKER_FLAGS_DEBUG}');
			addLast:((CMakeMessage new) message: 'CMAKE_MODULE_LINKER_FLAGS_ RELEASE= ${CMAKE_MODULE_LINKER_FLAGS_RELEASE}');
			addLast:((CMakeMessage new) message: 'CMAKE_SHARED_LINKER_FLAGS = ${CMAKE_SHARED_LINKER_FLAGS}');
			addLast:((CMakeMessage new) message: 'CMAKE_SHARED_LINKER_FLAGS_DEBUG = ${CMAKE_SHARED_LINKER_FLAGS_DEBUG}');
			addLast:((CMakeMessage new) message: 'CMAKE_SHARED_LINKER_FLAGS_RELEASE = ${CMAKE_SHARED_LINKER_FLAGS_RELEASE}');
			addLast:((CMakeMessage new) message: 'CMAKE_STATIC_LINKER_FLAGS = ${CMAKE_STATIC_LINKER_FLAGS}');
			addLast:((CMakeMessage new) message: 'CMAKE_STATIC_LINKER_FLAGS_DEBUG= ${CMAKE_STATIC_LINKER_FLAGS_DEBUG}');
			addLast:((CMakeMessage new) message: ' CMAKE_STATIC_LINKER_FLAGS_RELEASE= ${CMAKE_STATIC_LINKER_FLAGS_RELEASE}')		

	] .

]

{ #category : #'source generation' }
Linux64x86w32BitSqueakCogV3Config >> cogitClass [
	^ StackToRegisterMappingCogit 

]

{ #category : #compiling }
Linux64x86w32BitSqueakCogV3Config >> compilerDefinitions [
	^#(
	 '-DNDEBUG'                                   
 	 '-DDEBUGVM=0'
	 '-D_GNU_SOURCE'
 	 '-D_FILE_OFFSET_BITS=64'
	  '-DUSE_GLOBAL_STRUCT=0'
 	 '-DCOGMTVM=0')
	
]

{ #category : #compiling }
Linux64x86w32BitSqueakCogV3Config >> compilerFlags [
	^#('-Wall'
	    '-m32'
	    '-msse2'
	    '-g'
	   '-O1')
	
]

{ #category : #plugins }
Linux64x86w32BitSqueakCogV3Config >> defaultExternalPlugins [
	""
	^#()
]

{ #category : #cmake }
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

{ #category : #compiling }
Linux64x86w32BitSqueakCogV3Config >> externalLibraries [
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
		)
				


]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> externalLibsBuild [
	^self externalLibraries asOrderedCollection.

]

{ #category : #'source generation' }
Linux64x86w32BitSqueakCogV3Config >> interpreterClass [
	^ CoInterpreter
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

{ #category : #compiling }
Linux64x86w32BitSqueakCogV3Config >> linkerFlags [
	^#(	'-Wl'
            '-z'
            'now'
	   )
]
