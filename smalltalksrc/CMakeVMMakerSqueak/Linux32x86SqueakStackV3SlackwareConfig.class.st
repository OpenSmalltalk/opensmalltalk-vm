"
A Linux32x86SqueakStackV3SlackwareConfig is a configuration for CMake on a 64 bit Slackware linux with 32 bit compat libs and includes linking to GL. 



SqueakLinux64x86w32CompatBuilder 
	configureABuildFor: #Linux32x86SqueakStackV3SlackwareConfig withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp
"
Class {
	#name : #Linux32x86SqueakStackV3SlackwareConfig,
	#superclass : #Linux64x86w32BitConfigSlackware,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#category : #'CMakeVMMakerSqueak-Linux64X86-32BitCompatibility'
}

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareConfig >> addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs [
	super addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs
]

{ #category : #cmake }
Linux32x86SqueakStackV3SlackwareConfig >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default allBuildConfigurations copyWithoutAll:#(#assert #assertWithHeartbeatTimer #debug  #debugMultiThreadedFFI #debugWithHeartbeatTimer #releaseHeartbeatTimer #releaseMultiThreadedFFI)



]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareConfig >> buildDir [
	^super buildDir
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareConfig >> buildDirName [
	^super buildDirName
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareConfig >> compilerFlags [
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
Linux32x86SqueakStackV3SlackwareConfig >> defaultExternalPlugins [
	"Removed the B3DAcceleratorPlugin since we don't have OpenGL bindings here"
	^ (super defaultExternalPlugins copyWithoutAll: #(#ThreadedIA32FFIPlugin #InternetConfigPlugin #FT2Plugin #InternetConfigPlugin))
]

{ #category : #plugins }
Linux32x86SqueakStackV3SlackwareConfig >> defaultInternalPlugins [
	"Removed the B3DAcceleratorPlugin since we don't have OpenGL bindings here"
	^ (super defaultInternalPlugins copyWithoutAll: #(#IA32ABIPlugin #JoystickTabletPlugin #StarSqueakPlugin #SurfacePlugin #SqueakFFIPrims #ThreadedIA32FFIPlugin))
]

{ #category : #cmake }
Linux32x86SqueakStackV3SlackwareConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackV3
]

{ #category : #cmake }
Linux32x86SqueakStackV3SlackwareConfig >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirLinux32x8664
]

{ #category : #cmake }
Linux32x86SqueakStackV3SlackwareConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #accessing }
Linux32x86SqueakStackV3SlackwareConfig >> executableName [
	^super executableName
]

{ #category : #public }
Linux32x86SqueakStackV3SlackwareConfig >> generate [ 
	self generatePluginsList. 
	self generateLicense. 
	"^super generate"
	^CMakeVMGeneratorForSqueak generate:self    "Bypass CPlatformConfig generate to invoke our compatibility class"

]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareConfig >> outputDir [
	^super outputDir


]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareConfig >> prepareVMMaker [
	^super prepareVMMaker
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareConfig >> setupDirectories:gen [
	super setupDirectories: gen
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareConfig >> srcDir [
	^super srcDir
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareConfig >> topDir [
	^super topDir
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareConfig >> validateSourcesPresent [
	super validateSourcesPresent
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareConfig >> write: aContents toFile: aFileName [
	super write: aContents toFile: aFileName
]
