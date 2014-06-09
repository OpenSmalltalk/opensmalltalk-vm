"
Usage:
Linux32x86SqueakStackV3SlackwareNoGLConfig generateWithSources.
Or:
Linux32x86SqueakStackV3SlackwareNoGLConfig generate
Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me


"
Class {
	#name : #Linux32x86SqueakStackV3SlackwareNoGLConfig,
	#superclass : #Linux32x86SqueakStackV3SlackwareConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#category : #'CMakeVMMakerSqueak-LinuxX86_64-32Compatibility'
}

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareNoGLConfig >> addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs [
	super addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs
]

{ #category : #cmake }
Linux32x86SqueakStackV3SlackwareNoGLConfig >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default  allBuildConfigurations

	" ^SqueakCMakeVMMakerAbstractBuilder  default  noBuildConfigurations.
	  ^(SqueakCMakeVMMakerAbstractBuilder  default  allBuildConfigurations 
			copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))   
	"
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareNoGLConfig >> buildDir [
	^super buildDir
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareNoGLConfig >> buildDirName [
	^super buildDirName
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareNoGLConfig >> compilerFlags [
		^super compilerFlags
]

{ #category : #plugins }
Linux32x86SqueakStackV3SlackwareNoGLConfig >> defaultExternalPlugins [
	"Removed the B3DAcceleratorPlugin since we don't have OpenGL bindings here"
	^ (super defaultExternalPlugins copyWithoutAll: #(#B3DAcceleratorPlugin #ThreadedIA32FFIPlugin #InternetConfigPlugin #FT2Plugin))
]

{ #category : #plugins }
Linux32x86SqueakStackV3SlackwareNoGLConfig >> defaultInternalPlugins [
	"Removed the B3DAcceleratorPlugin since we don't have OpenGL bindings here"
	^ (super defaultInternalPlugins copyWithoutAll: #(#IA32ABIPlugin #JoystickTabletPlugin #StarSqueakPlugin #SurfacePlugin #SqueakFFIPrims #ThreadedIA32FFIPlugin))
]

{ #category : #cmake }
Linux32x86SqueakStackV3SlackwareNoGLConfig >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirLinux32x8664
]

{ #category : #cmake }
Linux32x86SqueakStackV3SlackwareNoGLConfig >> excludeFromBuild [
	^false

]

{ #category : #accessing }
Linux32x86SqueakStackV3SlackwareNoGLConfig >> executableName [
		^super executableName
]

{ #category : #public }
Linux32x86SqueakStackV3SlackwareNoGLConfig >> generate [ 
	self generatePluginsList. 
	self generateLicense. 
	"^super generate"
	^CMakeVMGeneratorForSqueak generate:self   "Bypass CPlatformConfig generate to invoke our compatibility class"

]

{ #category : #'compiler flags' }
Linux32x86SqueakStackV3SlackwareNoGLConfig >> linkFlags [
	 ^ '-lSM -lICE -ldl  -lpthread -lm -lnsl -lX11'
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareNoGLConfig >> outputDir [
	^super outputDir


]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareNoGLConfig >> prepareVMMaker [
		^super prepareVMMaker
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareNoGLConfig >> setupDirectories:gen [
		super setupDirectories: gen
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareNoGLConfig >> srcDir [
	^super srcDir
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareNoGLConfig >> topDir [
	^super topDir
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareNoGLConfig >> validateSourcesPresent [
		super validateSourcesPresent
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareNoGLConfig >> write: aContents toFile: aFileName [
	super write: aContents toFile: aFileName
]
