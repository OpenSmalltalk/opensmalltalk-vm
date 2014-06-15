"
I am like my parent, but no GL.



SqueakLinux64x86w32CompatBuilder 
	configureABuildFor: #Linux32x86SqueakStackV3SlackwareConfig withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp
"
Class {
	#name : #Linux64x86w32BitSqueakStackV3SlackwareNoGLConfig,
	#superclass : #Linux64x86w32BitSqueakStackV3SlackwareConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#category : #'CMakeVMMakerSqueak-IslandOfMisfitToys'
}

{ #category : #'squeak compatibility' }
Linux64x86w32BitSqueakStackV3SlackwareNoGLConfig >> addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs [
	super addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs
]

{ #category : #cmake }
Linux64x86w32BitSqueakStackV3SlackwareNoGLConfig >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default  allBuildConfigurations

	" ^SqueakCMakeVMMakerAbstractBuilder  default  noBuildConfigurations.
	  ^(SqueakCMakeVMMakerAbstractBuilder  default  allBuildConfigurations 
			copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))   
	"
]

{ #category : #'squeak compatibility' }
Linux64x86w32BitSqueakStackV3SlackwareNoGLConfig >> buildDir [
	^super buildDir
]

{ #category : #'squeak compatibility' }
Linux64x86w32BitSqueakStackV3SlackwareNoGLConfig >> buildDirName [
	^super buildDirName
]

{ #category : #'squeak compatibility' }
Linux64x86w32BitSqueakStackV3SlackwareNoGLConfig >> compilerFlags [
	|d commonFlags flags|
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

    flags:= String streamContents: [ :stream |
	 (((d at:  buildType) value)  collect: #withBlanksTrimmed as: Set)
		asStringOn: stream 
		delimiter:' '].

    commonFlags:=String streamContents: [ :stream |
		((self commonCompilerFlags) collect: #withBlanksTrimmed as: Set)
			asStringOn: stream 
			delimiter: ' ' ].
	^ commonFlags, ' ' ,flags.
]

{ #category : #plugins }
Linux64x86w32BitSqueakStackV3SlackwareNoGLConfig >> defaultExternalPlugins [
	"Removed the B3DAcceleratorPlugin since we don't have OpenGL bindings here"
	^ (super defaultExternalPlugins copyWithoutAll: #(#B3DAcceleratorPlugin #ThreadedIA32FFIPlugin #InternetConfigPlugin #FT2Plugin))
]

{ #category : #plugins }
Linux64x86w32BitSqueakStackV3SlackwareNoGLConfig >> defaultInternalPlugins [
	"Removed the B3DAcceleratorPlugin since we don't have OpenGL bindings here"
	^ (super defaultInternalPlugins copyWithoutAll: #(#IA32ABIPlugin #JoystickTabletPlugin #StarSqueakPlugin #SurfacePlugin #SqueakFFIPrims #ThreadedIA32FFIPlugin))
]

{ #category : #cmake }
Linux64x86w32BitSqueakStackV3SlackwareNoGLConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackV3
]

{ #category : #cmake }
Linux64x86w32BitSqueakStackV3SlackwareNoGLConfig >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirLinux32x8664
]

{ #category : #cmake }
Linux64x86w32BitSqueakStackV3SlackwareNoGLConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #accessing }
Linux64x86w32BitSqueakStackV3SlackwareNoGLConfig >> executableName [
		^super executableName
]

{ #category : #public }
Linux64x86w32BitSqueakStackV3SlackwareNoGLConfig >> generate [ 
	self generatePluginsList. 
	self generateLicense. 
	"^super generate"
	^CMakeVMGeneratorForSqueak generate:self   "Bypass CPlatformConfig generate to invoke our compatibility class"

]

{ #category : #'compiler flags' }
Linux64x86w32BitSqueakStackV3SlackwareNoGLConfig >> linkFlags [
	 ^ '-lSM -lICE -ldl  -lpthread -lm -lnsl -lX11'
]

{ #category : #'squeak compatibility' }
Linux64x86w32BitSqueakStackV3SlackwareNoGLConfig >> outputDir [
	^super outputDir


]

{ #category : #'squeak compatibility' }
Linux64x86w32BitSqueakStackV3SlackwareNoGLConfig >> prepareVMMaker [
		^super prepareVMMaker
]

{ #category : #'squeak compatibility' }
Linux64x86w32BitSqueakStackV3SlackwareNoGLConfig >> setupDirectories:gen [
		super setupDirectories: gen
]

{ #category : #'squeak compatibility' }
Linux64x86w32BitSqueakStackV3SlackwareNoGLConfig >> srcDir [
	^super srcDir
]

{ #category : #'squeak compatibility' }
Linux64x86w32BitSqueakStackV3SlackwareNoGLConfig >> topDir [
	^super topDir
]

{ #category : #'squeak compatibility' }
Linux64x86w32BitSqueakStackV3SlackwareNoGLConfig >> write: aContents toFile: aFileName [
	super write: aContents toFile: aFileName
]
