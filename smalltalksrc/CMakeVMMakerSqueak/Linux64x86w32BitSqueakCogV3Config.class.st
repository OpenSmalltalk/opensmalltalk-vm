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
	#name : #Linux64x86w32BitSqueakCogV3Config,
	#superclass : #Linux64x86w32BitConfigUsrLib,
	#category : #'CMakeVMMakerSqueak-Linux64X86-32BitCompatibility'
}

{ #category : #'as yet unclassified' }
Linux64x86w32BitSqueakCogV3Config class >> isAbstractBaseClass [
	^false

]

{ #category : #'as yet unclassified' }
Linux64x86w32BitSqueakCogV3Config >> availableBuildTypes [ 
"2.14.12.09 only buildType implemented is #build so I remove #build from the below OrderedCollection."
	^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes copyWithoutAll: #( #buildAssertITimerHeartbeat #buildDebug #buildDebugITimerHeartbeat #buildITimerHeartbeat #buildMultiThreaded #buildMultiThreadedAssert #buildMultiThreadedDebug #buildNone)
]

{ #category : #'source generation' }
Linux64x86w32BitSqueakCogV3Config >> cogitClass [
	^ StackToRegisterMappingCogit 

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> compilerDefinitionsBuild [
	^#(
	 '-DNDEBUG'          
 	 '-DDEBUGVM=0'
	 ' -DLSB_FIRST=1'
	 '-D_GNU_SOURCE'
 	 '-D_FILE_OFFSET_BITS=64'
"	  '-DUSE_GLOBAL_STRUCT=0'"
 	 '-DCOGMTVM=0') .

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> compilerFlagsBuild [
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
Linux64x86w32BitSqueakCogV3Config >> defaultExternalPlugins [
	""
	^#()
]

{ #category : #cmake }
Linux64x86w32BitSqueakCogV3Config >> dirBuildLanguageVMMM [
	^self squeakCogV3
]

{ #category : #cmake }
Linux64x86w32BitSqueakCogV3Config >> dirSource [
	^self src
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
	^self externalLibraries asOrderedCollection.

]

{ #category : #'source generation' }
Linux64x86w32BitSqueakCogV3Config >> interpreterClass [
	^ CoInterpreter
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> setPlatformSourcesBuild:aMaker [
	|mysubset iwantonly|

	"trim the platformSources collection .c files I want.  for  this OS/platform"
	self flag:'tty. go through the Cog svn tree and see exactly what files should be included here.'.
	iwantonly := #(		
	'aio.c'
	'debug.c'	
	'osExports.c'
	'sqUnixCharConv.c'
	'sqUnixExternalPrims.c'
	'sqUnixHeartbeat.c'
	'sqUnixMain.c'
	'sqUnixMemory.c'
	'sqUnixThreads.c'
	'sqUnixVMProfile.c'
	).		
	mysubset := platformSources select: [:c | 0 < (iwantonly occurrencesOf: c)]. 
	platformSources := mysubset.
	super setPlatformSourcesBuild:aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitSqueakCogV3Config >> setPlatformSourcesBuildAssert:aMaker [
	|mysubset iwantonly|

	"trim the platformSources collection .c files I want.  for  this OS/platform"
	self flag:'tty. go through the Cog svn tree and see exactly what files should be included here.'.	
	iwantonly := #(		
	'aio.c'
	'debug.c'	
	'osExports.c'
	'sqUnixCharConv.c'
	'sqUnixExternalPrims.c'
	'sqUnixHeartbeat.c'
	'sqUnixMain.c'
	'sqUnixMemory.c'
	'sqUnixThreads.c'
	'sqUnixVMProfile.c'
	).		
	mysubset := platformSources select: [:c | 0 < (iwantonly occurrencesOf: c)]. 
	platformSources := mysubset.
	super setPlatformSourcesBuild:aMaker
]
