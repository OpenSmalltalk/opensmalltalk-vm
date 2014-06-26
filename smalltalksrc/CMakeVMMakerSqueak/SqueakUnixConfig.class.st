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
	"avoid premature optimization. push this decision down lower if it is needed at all"
	^{}


]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> configH [
	"Route this message send to the message appropriate for my buildType "
	|d |
	self flag:'tty'. "this should be replaced by cC cXX lDFlags libs "
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self configHBuild];
		at: #buildAssert  put: [self configHBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self configHBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self cFlagsBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self configHBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self configHBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self configHBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self configHBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self configHBuildMultiThreadedDebug ];
		at: #buildNone put:[self configHNoBuildType].
	^(d at: buildType) value


"ONLY USED ON UNIX CONFIGS included here for completeness and consistency CogUnixConfig browse.

Use  configH to tell your plugins where to find its libraries etc.
The version of this is platform dependent.
You may also need to edit your oscogvm/platforms/YOUR PLATFORM/plugins/ThePLuginDirectory/acinclude.m4 file so that it conforms to your system.

tty needed a custom version of this in Linux32x86SqueakCogV3NoGLConfig in order to build the UUIDPlugin.

Go to oscogvm/platforms/YOUR PLATFORM/plugins/ThePLuginDirectory and look at the acinclude.m4 file
you may need to edit that .

NOTE: CPlatformConfig contains a useable version of this that you can modify. 

I reproduce it here, but with double quotes changed to two single quotes so that the commenting will hold.
I provide a <---N.B quotes need changing at each place they have been modified.

Again. it is easier to copy the one in CPlatformConfig."



]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> configHBuild [
	"convenience method to customize configH for this buildType. default is self configH
	^self configH"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> configHBuildAssert [
	"convenience method to customize configH for this buildType. default is self configH
	^self configH"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> configHBuildAssertITimerHeartbeat [
	"convenience method to customize configH for this buildType. default is self configH
	^self configH"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> configHBuildDebug [
	"convenience method to customize configH for this buildType. default is self configH
	^self configH"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> configHBuildDebugITimerHeartbeat [
	"convenience method to customize configH for this buildType. default is self configH
	^self configH"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> configHBuildITimerHeartbeat [
	"convenience method to customize configH for this buildType. default is self configH
	^self configH"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> configHBuildMultiThreaded [
	"convenience method to customize configH for this buildType. default is self configH
	^self configH"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> configHBuildMultiThreadedAssert [
	"convenience method to customize configH for this buildType. default is self configH
	^self configH"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> configHBuildMultiThreadedDebug [
	"convenience method to customize configH for this buildType. default is self configH
	^self configH"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> configHNoBuildType [
	"SHOULD NOT GET HERE"	
	self shouldNotImplement
]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configureForBuildType: aSymbol [
	"Set my internal state appropriate for my build type".
	self configureNoBuildType.                "reset all internal flags"
	buildType:= aSymbol.                       "error checking was handled previously"
	self
		preferredIncludes;
		standardIncludes;
		configureFlags;     "  configure --without-npsqueak --with-src=stacksrc --with-plugins=src/plugins --disable-cogi --without-vm-display-fbdev  --x-libraries=/usr/lib --without-gl "
		cC;                         " CC=''gcc -m32 -v''"
		cXX;                        "CXX=''g++ -m32'"
		lDFlags;                    " LDFLAGS=-Wl,-z,now"
		libs;                         " LIBS=''-lpthread -luuid''"
		internalPlugins;
		externalPlugins.


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

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuild [
	"leave empty for all platforms but Mac OS"
	^ #()
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildAssert [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildAssertITimerHeartbeat [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildDebug [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildDebugITimerHeartbeat [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildITimerHeartbeat [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildMultiThreaded [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildMultiThreadedAssert [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildMultiThreadedDebug [
	^ self frameworksBuild
]

{ #category : #'headers generation' }
SqueakUnixConfig >> generateConfigH [
		self write: self configH toFile: 'config.h'

]

{ #category : #accessing }
SqueakUnixConfig >> platformName [
	^self unixPlatformName
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

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuild [
	^ thirdpartyLibs ifNil: [ thirdpartyLibs := OrderedCollection new ].
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildAssert [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildAssertITimerHeartbeat [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildDebug [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildDebugITimerHeartbeat [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildITimerHeartbeat [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildMultiThreaded [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildMultiThreadedAssert [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildMultiThreadedDebug [
	^ self thirdpartyLibs 
]
