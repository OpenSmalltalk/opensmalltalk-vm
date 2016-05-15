"
I am a configuration for 64 bit Linux with 32 Bit compatability libraries.
I have been tested with Slackware64 14.1 which uses /usr/lib for 32 bit compatability  libs and /usr/lib64 for normal libs.

If you have a machine which uses /usr/lib for 64 bit libs and /usr/lib32 for 32 bit compat libs then subclass me and modify (at least) the following methods:

compilerFlags
externalLibraries
linkFlagsBuild
linkerFlags


SqueakLinux64x86w32CompatBuilder 
	configureABuildFor: #Linux64x86w32BitSqueakCogV3Config withBuildType: #build;
	enableMessageTracking: true;
	generateByTemplate.

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
	#name : #Linux64x86w32BitSqueakCogSpurConfig,
	#superclass : #Linux64x86w32BitConfigUsrLib,
	#category : #'CMakeVMMakerSqueak-Linux64X86-32BitCompatibility'
}

{ #category : #'as yet unclassified' }
Linux64x86w32BitSqueakCogSpurConfig class >> isAbstractBaseClass [
	^false

]

{ #category : #'as yet unclassified' }
Linux64x86w32BitSqueakCogSpurConfig >> availableBuildTypes [ 
"2.14.12.09 only buildType implemented is #build so I remove #build from the below OrderedCollection."
	^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes copyWithoutAll: #( #buildAssertITimerHeartbeat #buildDebug #buildDebugITimerHeartbeat #buildITimerHeartbeat #buildMultiThreaded #buildMultiThreadedAssert #buildMultiThreadedDebug #buildNone)
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogSpurConfig >> cmakeAddDefinitionsBuild [
	|definitions|
	definitions:=#(
	 '-DNDEBUG'          
 	 '-DDEBUGVM=0'
	 ' -DLSB_FIRST=1'
	 '-D_GNU_SOURCE'
 	 '-D_FILE_OFFSET_BITS=64'
"	  '-DUSE_GLOBAL_STRUCT=0'"
 	 '-DCOGMTVM=0') .

	(enabledebugmessages)
		ifTrue:[	templates 
		addLast:((CMakeMessage new) message: (self class name) , 'cmakeAddDefinitionsBuild')
	] .
	templates
		addLast:((CMakeAddDefinitions new) definitions: definitions). 

"	templates
		addLast:((CMakeAddDefinitions new) definitions: (self compilerDefinitions asOrderedCollection)). <--this was the old pharo deprecated legacy code approach that is unsuitable for the multiple buildTypes each Configuration must support"


]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogSpurConfig >> cmakeAddDefinitionsBuildAssert [
	|definitions|
"copy-n-paste from /build.linux32x86/squeak.cog.v3/build.assert/mvm  file"
	definitions:=#(
	 '-DDEBUGVM=0'
       '-D_GNU_SOURCE' 
       '-D_FILE_OFFSET_BITS=64' 
        '-DCOGMTVM=0'
	) .

	(enabledebugmessages)
		ifTrue:[	templates 
		addLast:((CMakeMessage new) message: (self class name) , 'cmakeAddDefinitionsBuildAssert')
	] .
	templates
		addLast:((CMakeAddDefinitions new) definitions: definitions). 

"	templates
		addLast:((CMakeAddDefinitions new) definitions: (self compilerDefinitions asOrderedCollection)). <--this was the old pharo deprecated legacy code approach that is unsuitable for the multiple buildTypes each Configuration must support"


]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogSpurConfig >> cmakeCFlagsBuild [
	|cflags|
	self flag:'tty'. "#build should have -O2"
	cflags:= String streamContents: [:stream | (self compilerFlags) asStringOn: stream delimiter: ' ' ].
	cflags:='"', cflags, '"'.
	(enabledebugmessages)
		ifTrue:[	templates 
		addLast:((CMakeMessage new) message: (self class name) , 'cmakeCFlagsBuild')
	] .
	templates
		addLast:((CMakeSet new) variable:'CMAKE_C_FLAGS' value: '${CMAKE_C_FLAGS} ', cflags );
		addLast:((CMakeSet new) variable:'CMAKE_C_FLAGS_RELEASE' value: '${CMAKE_CXX_FLAGS_RELEASE} ', cflags );
		addLast:((CMakeSet new) variable:'CMAKE_C_FLAGS_DEBUG' value: '${CMAKE_CXX_FLAGS_DEBUG} ',cflags);		
		addLast:((CMakeSet new) variable:'CMAKE_CXX_FLAGS' value: '${CMAKE_CXX_FLAGS} ', cflags );
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
Linux64x86w32BitSqueakCogSpurConfig >> cmakeSetSourceFilesPropertiesBuild [
	|cflags|
	cflags:=String streamContents: [:stream | (self compilerFlags) asStringOn: stream 
delimiter: ' ' ].
	cflags := '"' , cflags , '"'.
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

{ #category : #'source generation' }
Linux64x86w32BitSqueakCogSpurConfig >> cogitClass [
	^ StackToRegisterMappingCogit 

]

{ #category : #compiling }
Linux64x86w32BitSqueakCogSpurConfig >> compilerDefinitions [
	
	self deprecated: 'Legacy method from pharo approach. We need different definitions for each buildType'.

	^#(
	 '-DNDEBUG'          
 	 '-DDEBUGVM=0'
	 ' -DLSB_FIRST=1'
	 '-D_GNU_SOURCE'
 	 '-D_FILE_OFFSET_BITS=64'
"	  '-DUSE_GLOBAL_STRUCT=0'"
 	 '-DCOGMTVM=0') 

]

{ #category : #compiling }
Linux64x86w32BitSqueakCogSpurConfig >> compilerFlags [
	^#("'-Wall'"
		'-w'
		'-m32'
		'-msse2'
"		'-g3'                      extra debugging info"
		'-O1'
"	 	'-fno-caller-saves'
		'-fno-tree-pre'") 

]

{ #category : #plugins }
Linux64x86w32BitSqueakCogSpurConfig >> defaultExternalPlugins [
	""
	^#()
]

{ #category : #cmake }
Linux64x86w32BitSqueakCogSpurConfig >> dirBuildLanguageVMMM [
	^self squeakCogSpur
]

{ #category : #cmake }
Linux64x86w32BitSqueakCogSpurConfig >> dirSource [
	^self spursrc
]

{ #category : #cmake }
Linux64x86w32BitSqueakCogSpurConfig >> excludeFromBuild [
	^false   "build this configuration"
"	^true"   "do not build this configuration"


]

{ #category : #cmake }
Linux64x86w32BitSqueakCogSpurConfig >> executableName [
	^ self vmCogExecutableName
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogSpurConfig >> externalLibsBuild [
	^self externalLibraries asOrderedCollection.

]

{ #category : #'source generation' }
Linux64x86w32BitSqueakCogSpurConfig >> interpreterClass [
	^ CoInterpreter
]

{ #category : #compiling }
Linux64x86w32BitSqueakCogSpurConfig >> linkerFlags [
	^#(	'-Wl'
            '-z'
            'now'
	   ) 

]
