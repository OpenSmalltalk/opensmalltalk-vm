"
Usage:
SqueakStackVMBuilder 	buildSlackwareUnix64w32Libs
Or:
SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig generateWithSources.
Or:
SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig generate

"
Class {
	#name : #SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig,
	#superclass : #SqueakStackUnix64w32CompatLibsSlackwareConfig,
	#traits : 'TSqueakStackUnixConfig - {#externalPlugins. #internalPlugins}',
	#classTraits : 'TSqueakStackUnixConfig classTrait',
	#category : #'CMakeVMMakerSqueak-Linux64-32Compatibility'
}

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig >> addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs [
	super addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs
]

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig >> buildDir [
	^super buildDir
]

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig >> buildDirName [
	^super buildDirName
]

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig >> compilerFlags [
		^super compilerFlags
]

{ #category : #plugins }
SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig >> defaultExternalPlugins [
	"Removed the B3DAcceleratorPlugin since we don't have OpenGL bindings here"
	^ (super defaultExternalPlugins copyWithoutAll: #(#B3DAcceleratorPlugin #ThreadedIA32FFIPlugin #InternetConfigPlugin #FT2Plugin))
]

{ #category : #plugins }
SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig >> defaultInternalPlugins [
	"Removed the B3DAcceleratorPlugin since we don't have OpenGL bindings here"
	^ (super defaultInternalPlugins copyWithoutAll: #(#IA32ABIPlugin #JoystickTabletPlugin #StarSqueakPlugin #SurfacePlugin #SqueakFFIPrims #ThreadedIA32FFIPlugin))
]

{ #category : #accessing }
SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig >> executableName [
		^super executableName
]

{ #category : #public }
SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig >> generate [ 
	self generatePluginsList. 
	self generateLicense. 
	"^super generate"
	^CMakeVMGeneratorForSqueak generate:self   "Bypass CPlatformConfig generate to invoke our compatibility class"

]

{ #category : #'compiler flags' }
SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig >> linkFlags [
	 ^ '-lSM -lICE -ldl  -lpthread -lm -lnsl -lX11'
]

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig >> outputDir [
	^super outputDir


]

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig >> prepareVMMaker [
		^super prepareVMMaker
]

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig >> setupDirectories:gen [
		super setupDirectories: gen
]

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig >> srcDir [
	^super srcDir
]

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig >> topDir [
	^super topDir
]

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig >> validateSourcesPresent [
		super validateSourcesPresent
]

{ #category : #'squeak compatibility' }
SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig >> write: aContents toFile: aFileName [
	super write: aContents toFile: aFileName
]
