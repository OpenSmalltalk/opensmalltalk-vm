"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf


I am not meant to be built.

SqueakLinux32x86Builder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp

"
Class {
	#name : #Linux32x86SqueakCogV3Config,
	#superclass : #Linux32x86Config,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #'source generation' }
Linux32x86SqueakCogV3Config >> cogitClass [
	"answer a class for machine code generation or nil"
	
	^ StackToRegisterMappingCogit 
]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> compilerFlagsBuild [
	"Some gcc versions (3.4*) create a broken VM using -O2, so try -O1 if you have problems"
	^{ 
'-g3'                                               "more debugging"
.'-O1'                                              "low optiomization level"
.'-m32'
.'-msse2'
.'-D_GNU_SOURCE'
.'-D_FILE_OFFSET_BITS=64'
.'-DNDEBUG'                                      "disable assertions"
.'-DLSB_FIRST=1'                               ""
.'-DUSE_GLOBAL_STRUCT=0'
.'-DDEBUGVM=0'
.'-DCOGMTVM=0'
.'-fno-tree-pre	'
.'-fno-caller-saves'
}



]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> compilerFlagsBuildAssert [
	^ self compilerFlagsBuild

]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> compilerFlagsBuildAssertITimerHeartbeat [
	^ self compilerFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> compilerFlagsBuildDebug [
	^ self compilerFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> compilerFlagsBuildDebugITimerHeartbeat [
	^self compilerFlagsBuild

]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> compilerFlagsBuildITimerHeartbeat [
	^self compilerFlagsBuild

]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> compilerFlagsBuildMultiThreaded [
	^self compilerFlagsBuild

]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> compilerFlagsBuildMultiThreadedAssert [
	^self compilerFlagsBuild

]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> compilerFlagsBuildMultiThreadedDebug [
	^self compilerFlagsBuild

]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> configureFlagsBuild [
	^{'-without-npsqueak' . ''}
]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> configureFlagsBuildAssert [
	^self configureFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> configureFlagsBuildAssertITimerHeartbeat [
	^self configureFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> configureFlagsBuildDebug [
	^self configureFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> configureFlagsBuildDebugITimerHeartbeat [
	^self configureFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> configureFlagsBuildITimerHeartbeat [
	^self configureFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> configureFlagsBuildMultiThreaded [
	^self configureFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> configureFlagsBuildMultiThreadedAssert [
	^self configureFlagsBuild
]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> configureFlagsBuildMultiThreadedDebug [
	^self configureFlagsBuild
]

{ #category : #cmake }
Linux32x86SqueakCogV3Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogV3
]

{ #category : #'cmake directory ' }
Linux32x86SqueakCogV3Config >> dirInstall [
	"the directory of the finished product.. the place where 'make install' puts stuff.
	SystemNavigation default browseMethodsWhoseNamesContain: 'outputDir'
      "
	^self squeakCogV3
]

{ #category : #cmake }
Linux32x86SqueakCogV3Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^false
]

{ #category : #cmake }
Linux32x86SqueakCogV3Config >> executableName [
	^ self vmCogExecutableName
]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> externalLibsBuild [
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
Linux32x86SqueakCogV3Config >> externalLibsBuildAssert [
		^ self externalLibsBuild

]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> externalLibsBuildAssertITimerHeartbeat [
		^ self externalLibsBuild

]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> externalLibsBuildDebug [
		^ self externalLibsBuild

]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> externalLibsBuildDebugITimerHeartbeat [
		^ self externalLibsBuild

]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> externalLibsBuildITimerHeartbeat [
		^ self externalLibsBuild

]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> externalLibsBuildMultiThreaded [
		^ self externalLibsBuild

]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> externalLibsBuildMultiThreadedAssert [
		^ self externalLibsBuild

]

{ #category : #'cmake buildType redirects' }
Linux32x86SqueakCogV3Config >> externalLibsBuildMultiThreadedDebug [
		^ self externalLibsBuild

]

{ #category : #'source generation' }
Linux32x86SqueakCogV3Config >> interpreterClass [
	^ CoInterpreter
]
