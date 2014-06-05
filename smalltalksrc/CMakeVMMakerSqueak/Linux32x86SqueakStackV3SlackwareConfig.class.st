"
A SqueakStackUnix64w32CompatLibsSlackwareConfig is a configuration for CMake on a 64 bit Slackware linux with 32 bit compat libs and includes linking to GL. 



Usage:
SqueakStackVMBuilder 	buildSlackwareUnix64w32Libs
Or:
SqueakStackUnix64w32CompatLibsSlackwareConfig generateWithSources.
Or:
SqueakStackUnix64w32CompatLibsSlackwareConfig generate


"
Class {
	#name : #Linux32x86SqueakStackV3SlackwareConfig,
	#superclass : #Linux32x86SqueakStackV3Config,
	#traits : 'TSqueakStackUnixConfig - {#externalPlugins. #internalPlugins}',
	#classTraits : 'TSqueakStackUnixConfig classTrait',
	#category : #'CMakeVMMakerSqueak-Linuxx86_64-32Compatibility'
}

{ #category : #'squeak compatibility' }
Linux32x86SqueakStackV3SlackwareConfig >> addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs [
	super addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs
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
	^super compilerFlags
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
