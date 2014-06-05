"
I serve as a facade to ease building Stack  VM.
"
Class {
	#name : #SqueakStackV3Builder,
	#superclass : #Object,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #building }
SqueakStackV3Builder class >> build [
" self build "
	"build for platform we're currently running on"
	| platform |
	
	platform := Smalltalk os platformName.
	
	platform = 'Win32' ifTrue:  [ ^ self buildWin32 ].
	platform = 'Mac OS' ifTrue:  [ ^ self buildMacOSX32 ].
	platform  = 'unix' ifTrue: [ ^ self buildUnix32 ].
]

{ #category : #building }
SqueakStackV3Builder class >> buildMacOSX32 [
	^ self new buildMacOSX32
]

{ #category : #building }
SqueakStackV3Builder class >> buildOnJenkins: aPlatformName [
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
SqueakStackV3Builder class >> buildRaspberryPi [
	^ self new buildRaspberryPiFBB
]

{ #category : #building }
SqueakStackV3Builder class >> buildSlackwareUnix64w32Libs [
	^ self new buildSlackwareUnix64w32Libs
]

{ #category : #building }
SqueakStackV3Builder class >> buildSlackwareUnix64w32LibsNoGL [
	^ self new buildSlackwareUnix64w32LibsNoGL
]

{ #category : #building }
SqueakStackV3Builder class >> buildUnix32 [
	^ self new buildUnix32
]

{ #category : #building }
SqueakStackV3Builder class >> buildWin32 [
	^ self new buildWin32
]

{ #category : #building }
SqueakStackV3Builder >> buildMacOSX32 [ 
	
	PharoSOSXConfig new  
		generateForRelease;
		"generateForDebug;"
		addExternalPlugins: #(  FT2Plugin );
		addInternalPlugins: #( UnixOSProcessPlugin );
		generateSources; generate.

]

{ #category : #building }
SqueakStackV3Builder >> buildRaspberryPi [
	StackCrossRaspbianConfig new  
		generateSources; generate.


]

{ #category : #building }
SqueakStackV3Builder >> buildRaspberryPiFBB [
	StackCrossRaspbianFastBltConfig new  
		generateSources; generate.

]

{ #category : #building }
SqueakStackV3Builder >> buildSlackwareUnix64w32Libs [
	Linux32x86SqueakStackV3SlackwareConfig new
		addExternalPlugins: #( SqueakSSLPlugin );
		addInternalPlugins: #( UnixOSProcessPlugin  );
		generateSources; generate.

]

{ #category : #building }
SqueakStackV3Builder >> buildSlackwareUnix64w32LibsNoGL [
	Linux32x86SqueakStackV3SlackwareNoGLConfig new
		addExternalPlugins: #( SqueakSSLPlugin );
		addInternalPlugins: #( UnixOSProcessPlugin  );
		generateSources; generate.

]

{ #category : #building }
SqueakStackV3Builder >> buildUnix32 [

	Linux32x86SqueakStackV3SlackwareConfig new
		addExternalPlugins: #( FT2Plugin SqueakSSLPlugin );
		addInternalPlugins: #( UnixOSProcessPlugin  );
		generateSources; generate.

]

{ #category : #building }
SqueakStackV3Builder >> buildWin32 [

	PharoSWindowsConfig new  
		addExternalPlugins: #( FT2Plugin SqueakSSLPlugin );
		addInternalPlugins: #( Win32OSProcessPlugin );
		generateSources; generate.

]

{ #category : #'as yet unclassified' }
SqueakStackV3Builder >> generateCMakeFilesDevForRaspberryPi [
	StackRaspbianFastBltConfig new  
		generate.
]

{ #category : #building }
SqueakStackV3Builder >> generateCMakeFilesForRaspberryPi [
	StackRaspbianConfig new  
		generate.
]

{ #category : #building }
SqueakStackV3Builder >> generateCMakeFilesForRaspberryPiFBB [
	StackRaspbianFastBltConfig new  
		generate.
]

{ #category : #building }
SqueakStackV3Builder >> generateSourcesForRaspberryPi [
	StackRaspbianConfig new  
		generateSources.
]

{ #category : #initialization }
SqueakStackV3Builder >> initialize [

	"a stupid temporary hack to workaround initialization problems"

	Cogit allSubclassesDo: [ :each | each initializeWithOptions: (VMMaker new instVarNamed: 'optionsDictionary') ]
]

{ #category : #'as yet unclassified' }
SqueakStackV3Builder >> todo [
	self flag:'tty'
"massive refactor this to support assert, debug, i-timer, mt and production builds"
]
