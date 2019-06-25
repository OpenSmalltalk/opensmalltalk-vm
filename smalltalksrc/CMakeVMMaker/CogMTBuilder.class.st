Class {
	#name : #CogMTBuilder,
	#superclass : #Object,
	#category : #'CMakeVMMaker-Builder'
}

{ #category : #building }
CogMTBuilder class >> build [
" self build "
	"build for platform we're currently running on"
	| platform |
	
	platform := Smalltalk os platformName.
	
	platform = 'Win32' ifTrue:  [ ^ self buildWin32 ].
	platform = 'Mac OS' ifTrue:  [ ^ self buildMacOSX32 ].
	platform  = 'unix' ifTrue: [ ^ self buildUnix32 ].
]

{ #category : #building }
CogMTBuilder class >> buildMacOSX32 [
	^ self new buildMacOSX32
]

{ #category : #building }
CogMTBuilder class >> buildOnJenkins: aPlatformName [
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
CogMTBuilder class >> buildUnix32 [
	^ self new buildUnix32
]

{ #category : #building }
CogMTBuilder class >> buildWin32 [
	^ self new buildWin32
]

{ #category : #building }
CogMTBuilder >> buildMacOSX32 [ 

	CogMTCocoaIOSConfig new  
		generateForRelease;
		"generateForDebug;"
		addExternalPlugins: #(  FT2Plugin );
		addInternalPlugins: #( UnixOSProcessPlugin );
		generateSources; generate.

]

{ #category : #building }
CogMTBuilder >> buildUnix32 [
	
	CogMTUnixConfig new
		addExternalPlugins: #( FT2Plugin SqueakSSLPlugin );
		addInternalPlugins: #( UnixOSProcessPlugin  );
		generateSources; generate.

]

{ #category : #building }
CogMTBuilder >> buildWin32 [

	CogMTWindowsConfig new  

		addExternalPlugins: #(  FT2Plugin SqueakSSLPlugin );
		addInternalPlugins: #( Win32OSProcessPlugin );
		
		generateSources; generate.

]

{ #category : #initialization }
CogMTBuilder >> initialize [

	"a stupid temporary hack to workaround initialization problems"

	Cogit allSubclassesDo: [ :each | each initializeWithOptions: (VMMaker new instVarNamed: 'optionsDictionary') ]
]
