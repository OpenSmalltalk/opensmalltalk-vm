"
I serve as a facade to ease building Cog VM with CMakeVMMakerSqueak configs


"
Class {
	#name : #SqueakCogV3Builder,
	#superclass : #Object,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #building }
SqueakCogV3Builder class >> build [
" self build "
	"build for platform we're currently running on"
	| platform |
	
	platform := Smalltalk os platformName.
	
	platform = 'Win32' ifTrue:  [ ^ self buildWin32 ].
	platform = 'Mac OS' ifTrue:  [ ^ self buildMacOSX32 ].
	platform  = 'unix' ifTrue: [ ^ self buildUnix32 ].
]

{ #category : #building }
SqueakCogV3Builder class >> buildMacOSX32 [
	^ self new buildMacOSX32
]

{ #category : #building }
SqueakCogV3Builder class >> buildOnJenkins: aPlatformName [
	"entry point for jenkins build jobs.
	currently we use following names:
		win
		mac
		linux
	
	"
	
	aPlatformName = 'win' ifTrue: [ ^ self buildWin32 ].
	aPlatformName = 'mac' ifTrue: [ ^ self buildMacOSX32 ].
	aPlatformName = 'linux' ifTrue: [ ^ self buildUnix32 ].
	
	self error: 'no suitable platform'
]

{ #category : #building }
SqueakCogV3Builder class >> buildUnix32 [
	^ self new buildUnix32
]

{ #category : #building }
SqueakCogV3Builder class >> buildWin32 [
	^ self new buildWin32
]

{ #category : #building }
SqueakCogV3Builder >> buildMacOSX32 [ 

	SqueakCocoaIOSCogV3MultiThreadedConfig new  
		generateForRelease;
		"generateForDebug;"
		addExternalPlugins: #(  FT2Plugin );
		addInternalPlugins: #( UnixOSProcessPlugin );
		generateSources; generate.

]

{ #category : #building }
SqueakCogV3Builder >> buildUnix32 [
	
	Linux32x86SqueakCogV3MultiThreadedConfig new
"		addExternalPlugins: #( FT2Plugin SqueakSSLPlugin );"
		addExternalPlugins: #( SqueakSSLPlugin );
		addInternalPlugins: #( UnixOSProcessPlugin  );
		generateSources; generate.

]

{ #category : #building }
SqueakCogV3Builder >> buildWin32 [

	Win32x86SqueakCogV3MultiThreadedConfig new  

		addExternalPlugins: #(  FT2Plugin SqueakSSLPlugin );
		addInternalPlugins: #( Win32OSProcessPlugin );
		
		generateSources; generate.

]

{ #category : #initialization }
SqueakCogV3Builder >> initialize [

	"a stupid temporary hack to workaround initialization problems"

	Cogit allSubclassesDo: [ :each | each initializeWithOptions: (VMMaker new instVarNamed: 'optionsDictionary') ]
]

{ #category : #'as yet unclassified' }
SqueakCogV3Builder >> todo [
	self flag:'tty'
"massive refactor this to support assert, debug, i-timer, mt and production builds"
]
