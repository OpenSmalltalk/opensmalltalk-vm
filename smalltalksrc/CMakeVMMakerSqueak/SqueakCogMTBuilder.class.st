"
I serve as a facade to ease building Cog VM with CMakeVMMakerSqueak configs


"
Class {
	#name : #SqueakCogMTBuilder,
	#superclass : #Object,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #building }
SqueakCogMTBuilder class >> build [
" self build "
	"build for platform we're currently running on"
	| platform |
	
	platform := Smalltalk os platformName.
	
	platform = 'Win32' ifTrue:  [ ^ self buildWin32 ].
	platform = 'Mac OS' ifTrue:  [ ^ self buildMacOSX32 ].
	platform  = 'unix' ifTrue: [ ^ self buildUnix32 ].
]

{ #category : #building }
SqueakCogMTBuilder class >> buildMacOSX32 [
	^ self new buildMacOSX32
]

{ #category : #building }
SqueakCogMTBuilder class >> buildOnJenkins: aPlatformName [
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
SqueakCogMTBuilder class >> buildUnix32 [
	^ self new buildUnix32
]

{ #category : #building }
SqueakCogMTBuilder class >> buildWin32 [
	^ self new buildWin32
]

{ #category : #building }
SqueakCogMTBuilder >> buildMacOSX32 [ 

	SqueakCogMTCocoaIOSConfig new  
		generateForRelease;
		"generateForDebug;"
		addExternalPlugins: #(  FT2Plugin );
		addInternalPlugins: #( UnixOSProcessPlugin );
		generateSources; generate.

]

{ #category : #building }
SqueakCogMTBuilder >> buildUnix32 [
	
	Linux32x86SqueakCogV3MultiThreadedConfig new
"		addExternalPlugins: #( FT2Plugin SqueakSSLPlugin );"
		addExternalPlugins: #( SqueakSSLPlugin );
		addInternalPlugins: #( UnixOSProcessPlugin  );
		generateSources; generate.

]

{ #category : #building }
SqueakCogMTBuilder >> buildWin32 [

	SqueakCogMTWindowsConfig new  

		addExternalPlugins: #(  FT2Plugin SqueakSSLPlugin );
		addInternalPlugins: #( Win32OSProcessPlugin );
		
		generateSources; generate.

]

{ #category : #initialization }
SqueakCogMTBuilder >> initialize [

	"a stupid temporary hack to workaround initialization problems"

	Cogit allSubclassesDo: [ :each | each initializeWithOptions: (VMMaker new instVarNamed: 'optionsDictionary') ]
]
