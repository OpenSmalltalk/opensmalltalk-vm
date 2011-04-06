"
For ALSA sound driver you need to install a 

 - libasound2
 - libasound2-dev

For UUID you might also need: 

- uuid-dev
 packages  



"
Class {
	#name : #CUnixConfig,
	#superclass : #CPlatformConfig,
	#category : #'CMakeVMMaker-Unix'
}

{ #category : #utils }
CUnixConfig >> addDriver: name sources: aSources generator: cmakeGen [

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
CUnixConfig >> addVMDrivers: maker [

	 self 
		addDriver: 'vm-display-null' 
		sources: #( 
			'${targetPlatform}/vm-display-null/sqUnixDisplayNull' )
		generator: maker;
		
		addDriver: 'vm-display-X11' 
		sources: #( 
			'${targetPlatform}/vm-display-X11/sqUnixX11'
			'${targetPlatform}/vm-display-X11/sqUnixMozilla' )
		generator: maker;
		
		addDriver: 'vm-sound-ALSA' 
		sources: #( 
			'${targetPlatform}/vm-sound-ALSA/sqUnixSoundALSA' )
		generator: maker;

		addDriver: 'vm-sound-null' 
		sources: #( 
			'${targetPlatform}/vm-sound-null/sqUnixSoundNull' )
		generator: maker.
	
"
vm-display-null
	vm-display-X11
	vm-sound-ALSA
	vm-sound-null"
]

{ #category : #'compiler flags' }
CUnixConfig >> compilerFlags [
	^ self subclassResponsibility
]

{ #category : #'as yet unclassified' }
CUnixConfig >> configureAsynchFilePlugin: maker [

	maker addPlatformSources:
	#( 
		'sqUnixAsynchFile.c'
	)


]

{ #category : #'plugin extra rules' }
CUnixConfig >> configureB3DAcceleratorPlugin: maker [
	"extra rules for B3DAcceleratorPlugin"
	
	super configureB3DAcceleratorPlugin: maker.
	
	maker 
		addPlatformSources: #( 'sqUnixOpenGL.c' ) 
		

]

{ #category : #'plugin extra rules' }
CUnixConfig >> configureDropPlugin: maker [
	"extra rules for DropPlugin"
	super configureDropPlugin: maker.  
	maker includeDirectories: '${crossDir}/plugins/FilePlugin'. 
	maker addPlatformSources: #( 'sqUnixDragDrop')

]

{ #category : #'as yet unclassified' }
CUnixConfig >> configureFileCopyPlugin: maker [
	"extra rules for DropPlugin"

	maker addPlatformSources: #( 'sqUnixFileCopyPlugin')

]

{ #category : #'plugin extra rules' }
CUnixConfig >> configureFilePlugin: maker [
	"extra rules for FilePlugin"

	super configureFilePlugin: maker.  
	
	maker addPlatformSources: #( 'sqUnixFile')
]

{ #category : #'plugin extra rules' }
CUnixConfig >> configureJoystickTabletPlugin: maker [ 
	"extra rules for JoystickTabletPlugin"
	
	super configureJoystickTabletPlugin: maker.  
	maker addPlatformSources:
		#( 'sqUnixJoystickTablet' )

]

{ #category : #'plugin extra rules' }
CUnixConfig >> configureMIDIPlugin: maker [ 
	"extra rules for MIDIPlugin"

	super configureMIDIPlugin: maker.  

	"requires ALSA"

	maker addPlatformSources: #( 'sqUnixMIDI')
]

{ #category : #'plugin extra rules' }
CUnixConfig >> configureSecurityPlugin: maker [ 
	"extra rules for MIDIPlugin"

	super configureSecurityPlugin: maker.
	
	maker addPlatformSources: #( 'sqUnixSecurity')
]

{ #category : #'plugin extra rules' }
CUnixConfig >> configureSerialPlugin: maker [ 
	"extra rules for SerialPlugin"
	
	maker addPlatformSources: #( 'sqUnixSerial')
]

{ #category : #'plugin extra rules' }
CUnixConfig >> configureSocketPlugin: maker [ 
	"extra rules for SocketPlugin"
	
	maker addPlatformSources: #( 'sqUnixSocket')
]

{ #category : #'plugin extra rules' }
CUnixConfig >> configureSoundPlugin: maker [ 
	"extra rules for SoundPlugin"
	
	maker addPlatformSources: #( 'sqUnixSound')
]

{ #category : #'plugin extra rules' }
CUnixConfig >> configureUUIDPlugin: maker [ 
	"extra rules for UUIDPlugin"

	super configureUUIDPlugin: maker.    
	
	maker includeDirectories: '/usr/include/uuid'.
	
	maker addPlatformSources:
		#( 'sqUnixUUID.c')



]

{ #category : #'plugin extra rules' }
CUnixConfig >> extraPluginSettings: maker [

	maker isExternal ifTrue: [
		"copy result to results dir "
		maker set: 'LIBRARY_OUTPUT_PATH' toString: self outputDir

	].

]

{ #category : #'as yet unclassified' }
CUnixConfig >> extraVMSettings: maker [
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
CUnixConfig >> fixLineEndsOf: string [
	^ string copyReplaceAll: String cr with: String lf
]

{ #category : #accessing }
CUnixConfig >> frameworks [
	^ #()
]

{ #category : #utils }
CUnixConfig >> linkFlags [
	 ^ '-lSM -lICE -ldl -lGL -lpthread -lm -lnsl -lX11'
]

{ #category : #directories }
CUnixConfig >> outputDir [

	"the directory where built binaries will be stored"
	^ self buildDir containingDirectory fullName , '/results'
]

{ #category : #'as yet unclassified' }
CUnixConfig >> platformName [
	^ 'unix'
]

{ #category : #utils }
CUnixConfig >> setExtraTargetProperties: maker [


	maker addExternalLibraries: 
		#(
			'm'  "math lib"
			'dl'  "dynamic loader"
			'pthread' "posix threads" 
		).
		
	maker set: 'EXECUTABLE_OUTPUT_PATH' toString: self outputDir.
	self addVMDrivers: maker.
]
