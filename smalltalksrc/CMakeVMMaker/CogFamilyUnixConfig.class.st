"
This is an abstract class for all Cog VMs for Unix. 

For ALSA sound driver you need to install a 

 - libasound2
 - libasound2-dev

For UUID you might also need: 

- uuid-dev
 packages  

For SSL Plugins you need libssl & development headers:

sudo apt-get install openssl
sudo apt-get install libssl-dev


Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #CogFamilyUnixConfig,
	#superclass : #CPlatformConfig,
	#category : #'CMakeVMMaker-Unix'
}

{ #category : #utils }
CogFamilyUnixConfig >> addDriver: name sources: aSources generator: cmakeGen [

	| cfg srcs |
	
	srcs := aSources inject: '' into: [:res :each | res , ' "', each, '"' ].
	cfg := cmakeGen
		captureOutputDuring: [
			cmakeGen printHeader;
			project: name;
			include: '../directories.cmake';
		
			message: 'Adding module: ', name;
			
			addDefinitions:  self compilerFlags;
			addDefinitions: '-fPIC -DPIC';
			set: #sources to: srcs;
			cmd: 'add_library' params: name, ' SHARED ${sources}'; 
			includeDirectories: '${crossDir}/plugins/FilePlugin';
			includeDirectories: '${targetPlatform}/plugins/B3DAcceleratorPlugin';
			includeDirectories: '${crossDir}/plugins/B3DAcceleratorPlugin';
			set: 'LIBRARY_OUTPUT_PATH' toString: self outputDir;
			cmd: 'set_target_properties' params: name , ' PROPERTIES PREFIX "" SUFFIX "" 
			LINK_FLAGS "', self linkFlags , '"'
	].
	
		
	self write: cfg toFile: ((self buildDir / name) assureExistence / cmakeGen outputFileName) fullName.
	cmakeGen addSubdirectory:  name.
	
]

{ #category : #utils }
CogFamilyUnixConfig >> addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs [

	| cfg srcs |
	
	srcs := aSources inject: '' into: [:res :each | res , ' "', each, '"' ].
	cfg := cmakeGen
		captureOutputDuring: [
			cmakeGen printHeader;
			project: name;
			include: '../directories.cmake';
		
			message: 'Adding module: ', name;
			
			addDefinitions:  self compilerFlags;
			addDefinitions: '-fPIC -DPIC';
			set: #sources to: srcs;
			cmd: 'add_library' params: name, ' SHARED ${sources}'; 
			includeDirectories: '${crossDir}/plugins/FilePlugin';
			includeDirectories: '${targetPlatform}/plugins/B3DAcceleratorPlugin';
			includeDirectories: '${crossDir}/plugins/B3DAcceleratorPlugin';
			set: 'LIBRARY_OUTPUT_PATH' toString: self outputDir;
			addExternalLibraries: extLibs;
			cmd: 'target_link_libraries' params: name , ' ${LINKLIBS}';
			cmd: 'set_target_properties' params: name , ' PROPERTIES PREFIX "" SUFFIX "" 
			LINK_FLAGS -m32' 
	].
	
		
	self write: cfg toFile: ((self buildDir / name) assureExistence / cmakeGen outputFileName) fullName.
	cmakeGen addSubdirectory:  name.
	
]

{ #category : #utils }
CogFamilyUnixConfig >> addVMDrivers: maker [
"
libICE
ICE is the Inter Client Exchange protocol, part of X11

libSM
session management library for X11

"
	 self 
		addDriver: 'vm-display-null' 
		sources: #( 
			'${targetPlatform}/vm-display-null/sqUnixDisplayNull' )
		generator: maker
		externalLibs: #();
		
		
		addDriver: 'vm-display-X11' 
		sources: #( 
			'${targetPlatform}/vm-display-X11/sqUnixX11'
			'${targetPlatform}/vm-display-X11/sqUnixMozilla' )
		generator: maker
		
		"-lSM -lICE -ldl -lGL -lpthread -lm -lnsl -lX11'"
		externalLibs: #( SM ICE GL X11 nsl dl);
		

		addDriver: 'vm-sound-ALSA' 
		sources: #( 
			'${targetPlatform}/vm-sound-ALSA/sqUnixSoundALSA' )
		generator: maker
		externalLibs: #();

		addDriver: 'vm-sound-null' 
		sources: #( 
			'${targetPlatform}/vm-sound-null/sqUnixSoundNull' )
		generator: maker
		externalLibs: #().
	
"
vm-display-null
	vm-display-X11
	vm-sound-ALSA
	vm-sound-null"
]

{ #category : #'build script' }
CogFamilyUnixConfig >> buildScript [
	"answer the build script for building everything"
	

	^ 
'#!bash
../codegen-scripts/extract-commit-info.sh
cmake .
make

'
]

{ #category : #'compiler flags' }
CogFamilyUnixConfig >> compilerFlags [
	^ self subclassResponsibility
]

{ #category : #'as yet unclassified' }
CogFamilyUnixConfig >> configureAsynchFilePlugin: maker [

	maker addPlatformSources:
	#( 
		'sqUnixAsynchFile.c'
	)


]

{ #category : #'plugin extra rules' }
CogFamilyUnixConfig >> configureB3DAcceleratorPlugin: maker [
	"extra rules for B3DAcceleratorPlugin"
	
	super configureB3DAcceleratorPlugin: maker.
	
	maker 
		addPlatformSources: #( 'sqUnixOpenGL.c' ) 
		

]

{ #category : #'plugin extra rules' }
CogFamilyUnixConfig >> configureDropPlugin: maker [
	"extra rules for DropPlugin"
	super configureDropPlugin: maker.  
	maker includeDirectories: '${crossDir}/plugins/FilePlugin'. 
	maker addPlatformSources: #( 'sqUnixDragDrop')

]

{ #category : #'plugin extra rules' }
CogFamilyUnixConfig >> configureFT2Plugin: maker [ 
	"extra rules for FT2Plugin" 
	
	maker addExternalLibraries: #('freetype' ).
	
	"
	ft2build.h. says: 
	<prefix>/include/freetype2' must be in your current inclusion path "
	maker includeDirectories:  '/usr/include/freetype2'
]

{ #category : #'as yet unclassified' }
CogFamilyUnixConfig >> configureFileCopyPlugin: maker [
	"extra rules for DropPlugin"

	maker addPlatformSources: #( 'sqUnixFileCopyPlugin')

]

{ #category : #'plugin extra rules' }
CogFamilyUnixConfig >> configureFilePlugin: maker [
	"extra rules for FilePlugin"

	super configureFilePlugin: maker.  
	
	maker addPlatformSources: #( 'sqUnixFile')
]

{ #category : #'plugin extra rules' }
CogFamilyUnixConfig >> configureInternetConfigPlugin: maker [
	super configureInternetConfigPlugin: maker.
	maker addPlatformSources: #( 'sqUnixInternetConfiguration' )
]

{ #category : #'plugin extra rules' }
CogFamilyUnixConfig >> configureJoystickTabletPlugin: maker [ 
	"extra rules for JoystickTabletPlugin"
	
	super configureJoystickTabletPlugin: maker.  
	maker addPlatformSources:
		#( 'sqUnixJoystickTablet' )

]

{ #category : #'plugin extra rules' }
CogFamilyUnixConfig >> configureLocalePlugin: maker [ 
	"extra rules for LocalePlugin"

	super configureLocalePlugin:  maker.
	
	maker addPlatformSources: #( 'sqUnixLocale.c')
	
]

{ #category : #'plugin extra rules' }
CogFamilyUnixConfig >> configureMIDIPlugin: maker [ 
	"extra rules for MIDIPlugin"

	super configureMIDIPlugin: maker.  

	"requires ALSA"

	maker addPlatformSources: #( 'sqUnixMIDI')
]

{ #category : #'plugin extra rules' }
CogFamilyUnixConfig >> configureSecurityPlugin: maker [ 
	"extra rules for MIDIPlugin"

	super configureSecurityPlugin: maker.
	
	maker addPlatformSources: #( 'sqUnixSecurity')
]

{ #category : #'plugin extra rules' }
CogFamilyUnixConfig >> configureSerialPlugin: maker [ 
	"extra rules for SerialPlugin"
	
	maker addPlatformSources: #( 'sqUnixSerial')
]

{ #category : #'plugin extra rules' }
CogFamilyUnixConfig >> configureSocketPlugin: maker [ 
	"extra rules for SocketPlugin"
	
	maker addPlatformSources: #( 'sqUnixSocket')
]

{ #category : #'plugin extra rules' }
CogFamilyUnixConfig >> configureSoundPlugin: maker [ 
	"extra rules for SoundPlugin"
	
	maker addPlatformSources: #( 'sqUnixSound')
]

{ #category : #'plugin extra rules' }
CogFamilyUnixConfig >> configureSqueakSSLPlugin: maker [ 
	"extra rules for SqueakSSLPlugin"
	
	maker addPlatformSources: #( 'sqUnixOpenSSL.c').
	
	maker addExternalLibraries: #('ssl' ).
	
]

{ #category : #'plugin extra rules' }
CogFamilyUnixConfig >> configureUUIDPlugin: maker [ 
	"extra rules for UUIDPlugin"

	super configureUUIDPlugin: maker.    
	
	maker includeDirectories: '/usr/include/uuid'.
	
	maker addPlatformSources:
		#( 'sqUnixUUID.c')



]

{ #category : #'plugin extra rules' }
CogFamilyUnixConfig >> configureUnixOSProcessPlugin: maker [ 
	"extra rules for UnixOSProcessPlugin"

	maker includeDirectories: '${crossDir}/plugins/FilePlugin'.
	maker includeDirectories: '${crossDir}/plugins/SocketPlugin'.
	
	maker addDefinitions: '-DSQAIO_H=\"sqaio.h\"'

]

{ #category : #'plugin extra rules' }
CogFamilyUnixConfig >> extraPluginSettings: maker [

	maker isExternal ifTrue: [
		"copy lib to results dir "
		maker set: 'LIBRARY_OUTPUT_PATH' to: '${outputDir}' 
	].

]

{ #category : #'as yet unclassified' }
CogFamilyUnixConfig >> extraVMSettings: maker [
	| versionC |
	self generateConfigH.
	
	"add a generated version.c"
	
	versionC := 'version.c'.
	
	maker cmd: 'add_custom_command' params: 'OUTPUT ',
		versionC , '
		COMMAND ${platformsDir}/unix/config/verstamp ',versionC,' gcc
		COMMENT "Generating version.c"
	'.
	
	
]

{ #category : #utils }
CogFamilyUnixConfig >> fixLineEndsOf: string [
	^ string copyReplaceAll: String cr with: String lf
]

{ #category : #accessing }
CogFamilyUnixConfig >> frameworks [
	^ #()
]

{ #category : #utils }
CogFamilyUnixConfig >> linkFlags [
	 ^ '-lSM -lICE -ldl -lGL -lpthread -lm -lnsl -lX11'
]

{ #category : #directories }
CogFamilyUnixConfig >> outputDir [

	"the directory where built binaries will be stored"
	^ outputDir ifNil: [ outputDir := (self buildDir containingDirectory fullName , '/', self outputDirName) ]
	
]

{ #category : #'as yet unclassified' }
CogFamilyUnixConfig >> platformName [
	^ 'unix'
]

{ #category : #utils }
CogFamilyUnixConfig >> setExtraTargetProperties: maker [


	maker addExternalLibraries: 
		#(
			'm'  "math lib"
			'dl'  "dynamic loader"
			'pthread' "posix threads" 
		).
		
	maker set: 'EXECUTABLE_OUTPUT_PATH' toString: self outputDir.
	self addVMDrivers: maker.
]
