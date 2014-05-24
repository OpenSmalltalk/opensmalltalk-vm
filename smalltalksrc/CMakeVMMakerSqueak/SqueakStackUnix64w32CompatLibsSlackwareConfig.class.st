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
	#name : #SqueakStackUnix64w32CompatLibsSlackwareConfig,
	#superclass : #SqueakStackUnixConfig,
	#traits : 'TSqueakStackUnixConfig - {#externalPlugins. #internalPlugins}',
	#classTraits : 'TSqueakStackUnixConfig classTrait',
	#category : #'CMakeVMMakerSqueak-Unix'
}

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareConfig >> addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs [
	super addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs
]

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareConfig >> buildDir [
	^super buildDir
]

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareConfig >> buildDirName [
	^super buildDirName
]

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareConfig >> compilerFlags [
	^super compilerFlags
]

{ #category : #plugins }
SqueakStackUnix64w32CompatLibsSlackwareConfig >> defaultExternalPlugins [
	"Removed the B3DAcceleratorPlugin since we don't have OpenGL bindings here"
	^ (super defaultExternalPlugins copyWithoutAll: #(#ThreadedIA32FFIPlugin #InternetConfigPlugin #FT2Plugin #InternetConfigPlugin))
]

{ #category : #plugins }
SqueakStackUnix64w32CompatLibsSlackwareConfig >> defaultInternalPlugins [
	"Removed the B3DAcceleratorPlugin since we don't have OpenGL bindings here"
	^ (super defaultInternalPlugins copyWithoutAll: #(#IA32ABIPlugin #JoystickTabletPlugin #StarSqueakPlugin #SurfacePlugin #SqueakFFIPrims #ThreadedIA32FFIPlugin))
]

{ #category : #accessing }
SqueakStackUnix64w32CompatLibsSlackwareConfig >> executableName [
	^super executableName
]

{ #category : #public }
SqueakStackUnix64w32CompatLibsSlackwareConfig >> generate [ 
	self generatePluginsList. 
	self generateLicense. 
	"^super generate"
	^CMakeVMGeneratorForSqueak generate:self    "Bypass CPlatformConfig generate to invoke our compatibility class"

]

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareConfig >> outputDir [
	^super outputDir


]

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareConfig >> prepareVMMaker [
	^super prepareVMMaker
]

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareConfig >> setupDirectories:gen [
	super setupDirectories: gen
]

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareConfig >> srcDir [
	^super srcDir
]

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareConfig >> topDir [
	^super topDir
]

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareConfig >> validateSourcesPresent [
	super validateSourcesPresent
]

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareConfig >> write: aContents toFile: aFileName [
	super write: aContents toFile: aFileName
]
