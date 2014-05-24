"
I serve as a facade to ease building Stack  VM.
"
Class {
	#name : #SqueakStackVMBuilder,
	#superclass : #Object,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #building }
SqueakStackVMBuilder class >> build [
" self build "
	"build for platform we're currently running on"
	| platform |
	
	platform := Smalltalk os platformName.
	
	platform = 'Win32' ifTrue:  [ ^ self buildWin32 ].
	platform = 'Mac OS' ifTrue:  [ ^ self buildMacOSX32 ].
	platform  = 'unix' ifTrue: [ ^ self buildUnix32 ].
]

{ #category : #building }
SqueakStackVMBuilder class >> buildMacOSX32 [
	^ self new buildMacOSX32
]

{ #category : #building }
SqueakStackVMBuilder class >> buildOnJenkins: aPlatformName [
	"entry point for jenkins build jobs.
	currently we use following names:
		win
		mac
		linux
		raspberrypi
	"
	
	aPlatformName = 'win' ifTrue: [ ^ self buildWin32 ].
	aPlatformName = 'mac' ifTrue: [ ^ self buildMacOSX32 ].
	aPlatformName = 'linux' ifTrue: [ ^ self buildUnix32 ].
	aPlatformName = 'raspberrypi' ifTrue: [ ^ self buildRaspberryPi ].
	
	self error: 'no suitable platform'
]

{ #category : #building }
SqueakStackVMBuilder class >> buildRaspberryPi [
	^ self new buildRaspberryPiFBB
]

{ #category : #building }
SqueakStackVMBuilder class >> buildSlackwareUnix64w32Libs [
	^ self new buildSlackwareUnix64w32Libs
]

{ #category : #building }
SqueakStackVMBuilder class >> buildSlackwareUnix64w32LibsNoGL [
	^ self new buildSlackwareUnix64w32LibsNoGL
]

{ #category : #building }
SqueakStackVMBuilder class >> buildUnix32 [
	^ self new buildUnix32
]

{ #category : #building }
SqueakStackVMBuilder class >> buildWin32 [
	^ self new buildWin32
]

{ #category : #building }
SqueakStackVMBuilder >> buildMacOSX32 [ 
	
	PharoSOSXConfig new  
		generateForRelease;
		"generateForDebug;"
		addExternalPlugins: #(  FT2Plugin );
		addInternalPlugins: #( UnixOSProcessPlugin );
		generateSources; generate.

]

{ #category : #building }
SqueakStackVMBuilder >> buildRaspberryPi [
	StackCrossRaspbianConfig new  
		generateSources; generate.


]

{ #category : #building }
SqueakStackVMBuilder >> buildRaspberryPiFBB [
	StackCrossRaspbianFastBltConfig new  
		generateSources; generate.

]

{ #category : #building }
SqueakStackVMBuilder >> buildSlackwareUnix64w32Libs [
	SqueakStackUnix64w32CompatLibsSlackwareConfig new
		addExternalPlugins: #( SqueakSSLPlugin );
		addInternalPlugins: #( UnixOSProcessPlugin  );
		generateSources; generate.

]

{ #category : #building }
SqueakStackVMBuilder >> buildSlackwareUnix64w32LibsNoGL [
	SqueakStackUnix64w32CompatLibsSlackwareNoGLConfig new
		addExternalPlugins: #( SqueakSSLPlugin );
		addInternalPlugins: #( UnixOSProcessPlugin  );
		generateSources; generate.

]

{ #category : #building }
SqueakStackVMBuilder >> buildUnix32 [

	SqueakStackUnix64w32CompatLibsSlackwareConfig new
		addExternalPlugins: #( FT2Plugin SqueakSSLPlugin );
		addInternalPlugins: #( UnixOSProcessPlugin  );
		generateSources; generate.

]

{ #category : #building }
SqueakStackVMBuilder >> buildWin32 [

	PharoSWindowsConfig new  
		addExternalPlugins: #( FT2Plugin SqueakSSLPlugin );
		addInternalPlugins: #( Win32OSProcessPlugin );
		generateSources; generate.

]

{ #category : #'as yet unclassified' }
SqueakStackVMBuilder >> generateCMakeFilesDevForRaspberryPi [
	StackRaspbianFastBltConfig new  
		generate.
]

{ #category : #building }
SqueakStackVMBuilder >> generateCMakeFilesForRaspberryPi [
	StackRaspbianConfig new  
		generate.
]

{ #category : #building }
SqueakStackVMBuilder >> generateCMakeFilesForRaspberryPiFBB [
	StackRaspbianFastBltConfig new  
		generate.
]

{ #category : #building }
SqueakStackVMBuilder >> generateSourcesForRaspberryPi [
	StackRaspbianConfig new  
		generateSources.
]

{ #category : #initialization }
SqueakStackVMBuilder >> initialize [

	"a stupid temporary hack to workaround initialization problems"

	Cogit allSubclassesDo: [ :each | each initializeWithOptions: (VMMaker new instVarNamed: 'optionsDictionary') ]
]
