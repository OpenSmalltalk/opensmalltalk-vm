"
A Linux64x86w32BitConfigUsrLib is an Abstract base class that provides common information for my subclasses.
I am not meant to be built.

I am a configuration for linux64x86 where the 32 bit compatibility libraries reside in /usr/lib  (example: Slackware64 14.1)

Some linux platforms (such as Ubuntu). store their 32 bit compat libs in /usr/lib32.  For those, use subclasses of Linux64x86w32BitConfigUsrLib32


I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf[Foo]

SqueakLinux64x86w32CompatBuilder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	enableMessageTracking: true;
	generateByTemplate.



HelpBrowser openOn: CMakeVMMakerSqueakHelp



"
Class {
	#name : #Linux64x86w32BitConfigUsrLib,
	#superclass : #SqueakUnixConfig,
	#category : #'CMakeVMMakerSqueak-Linux64X86-32BitCompatibility'
}

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfigUsrLib >> addVMPluginsBuild: aMaker [
	|temp o|
	self flag:'tty'. "I am writing sub-directory CMakeLists.txt here. Should I also write the config.cmake files?"
	enabledebugmessages
		ifTrue: [templates  "this message will go to the top level CMakeLists.txt file"
				addLast: (CMakeMessage new message: self class name , 'addVMPluginsBuild: aMaker')].
	vmplugins do:[ :vmp |                    
		o := String new writeStream.   "each VMPlugin gets its own CMakeLists.txt file in its own directory"
		temp := OrderedCollection new.	
		temp
			addAllLast:((CMakePluginVm new)    "this is the CMakeCompositTemplate"
					config: self 
					definitions: (vmp compilerdefinitions)
					module: (vmp module)
					sources: (vmp sources)
					includedirectories: (vmp includedirectories)).
		temp do: [:each |  o nextPutAll: (each content); cr].
	((self buildDir) directoryExists: (vmp module))
		ifFalse:[	(self buildDir) createDirectory: (vmp module)].
		self write: (o contents) toFile: vmp module , FileDirectory slash , aMaker outputFileName.
		templates   "this will go to the top level CMakeLists.txt file"
			addLast: ((CMakeAddSubDirectory new) sourcedir: (vmp module)) 
	].










]

{ #category : #cmake }
Linux64x86w32BitConfigUsrLib >> availableBuildTypes [
 	 ^SqueakCMakeVMMakerAbstractBuilder  default  noBuildTypes
"

subclasses should use

  ^super allBuildTypes copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))   "
	

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfigUsrLib >> coreSourcesBuild [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
		)
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfigUsrLib >> coreSourcesBuildMultiThreaded [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'cointerpmt.c'
		)
]

{ #category : #plugins }
Linux64x86w32BitConfigUsrLib >> customizeCMakeVMDisplayNull [
	|module|
	module := vmplugins detect: [:vmd | #CMakeVMDisplayNull = ((vmd class name) asSymbol)] ifNone:[nil].  "error handling?"
	module 
		sources: #('${targetPlatform}/vm-display-null/sqUnixDisplayNull') ;
		compilerdefinitions:(OrderedCollection with: '-fPIC' with: '-DPIC');
		compilerflags: (self compilerFlags);
		externallibraries: #();
		linkerflags: (self linkerFlags);
		includedirectories:(OrderedCollection 
										with:'${crossDir}/plugins/FilePlugin' 
										with: '${targetPlatform}/plugins/B3DAcceleratorPlugin'  
 									     with: '${crossDir}/plugins/B3DAcceleratorPlugin').
	self flag:'tty'. "I don't think includedirectories is correct. revisit"







]

{ #category : #plugins }
Linux64x86w32BitConfigUsrLib >> customizeCMakeVMDisplayX11 [
	|module|
	module := vmplugins detect: [:vmd | #CMakeVMDisplayX11 = ((vmd class name) asSymbol)] ifNone:[nil].  "error handling?"
	module 
		sources: #( '${targetPlatform}/vm-display-X11/sqUnixX11' '${targetPlatform}/vm-display-X11/sqUnixMozilla' );
		compilerdefinitions:(OrderedCollection with: '-fPIC' with: '-DPIC');
		compilerflags: (self compilerFlags);
		externallibraries: (self externalLibraries);
		linkerflags: (self linkerFlags);
		includedirectories:(OrderedCollection 
										with:'${crossDir}/plugins/FilePlugin' 
										with: '${targetPlatform}/plugins/B3DAcceleratorPlugin'  
 									     with: '${crossDir}/plugins/B3DAcceleratorPlugin').

]

{ #category : #plugins }
Linux64x86w32BitConfigUsrLib >> customizeCMakeVMSoundALSA [
	|module|
	module := vmplugins detect: [:vmd | #CMakeVMSoundALSA = ((vmd class name) asSymbol)] ifNone:[nil].  "error handling?"
	module 
		sources: #( '${targetPlatform}/vm-sound-ALSA/sqUnixSoundALSA' );
		compilerdefinitions:(OrderedCollection with: '-fPIC' with: '-DPIC');
		compilerflags: (self compilerFlags);
		externallibraries: (self externalLibraries);
		linkerflags: (self linkerFlags);
		includedirectories: #().
	
]

{ #category : #plugins }
Linux64x86w32BitConfigUsrLib >> customizeCMakeVMSoundNull [
	|module|
	module := vmplugins detect: [:vmd | #CMakeVMSoundNull = ((vmd class name) asSymbol)] ifNone:[nil].  "error handling?"
	module 
		sources: #( '${targetPlatform}/vm-sound-null/sqUnixSoundNull' );
		compilerdefinitions:(OrderedCollection with: '-fPIC' with: '-DPIC');
		compilerflags: (self compilerFlags);
		externallibraries: (self externalLibraries);
		linkerflags: (self linkerFlags);
		includedirectories:#()


]

{ #category : #plugins }
Linux64x86w32BitConfigUsrLib >> customizeVMPlugins [
	|mysubset iwantonly|
	self flag: 'tty: consider pushing up to platform level on refactor'.
	"trim the vmdrivers ordered collection of CMakeVMDriver subclasses to only those I want. then customize them for use on this OS/platform"
	iwantonly :=	 #(#CMakeVMDisplayNull  #CMakeVMDisplayX11  #CMakeVMSoundALSA  #CMakeVMSoundNull ).
	mysubset := vmplugins select: [:vmd | 0 < (iwantonly occurrencesOf: (vmd class name) asSymbol)]. 
	vmplugins := mysubset.
	self 
		customizeCMakeVMDisplayNull;
		customizeCMakeVMDisplayX11;
		customizeCMakeVMSoundALSA;
		customizeCMakeVMSoundNull.




]

{ #category : #plugins }
Linux64x86w32BitConfigUsrLib >> defaultExternalPlugins [
	^ #(
		B3DAcceleratorPlugin
		ThreadedIA32FFIPlugin "SqueakFFIPrims"
		"UUIDPlugin"
		"UnixOSProcessPlugin ?? "	
		JPEGReaderPlugin 
		JPEGReadWriter2Plugin 			
		RePlugin
		InternetConfigPlugin
	)

"debug"
]

{ #category : #plugins }
Linux64x86w32BitConfigUsrLib >> defaultInternalPlugins [
" took from unixbuild/bld/plugins.int"
	^ #(
		ADPCMCodecPlugin 
		AsynchFilePlugin 
		BalloonEnginePlugin "B2DPlugin" 
		BitBltSimulation "BitBltPlugin"
		BMPReadWriterPlugin 
		CroquetPlugin 
		DeflatePlugin  "ZipPlugin"
		DropPlugin 
		DSAPlugin "DSAPrims" 
		FFTPlugin 
		FileCopyPlugin 
		FilePlugin 
		FloatArrayPlugin 
		FloatMathPlugin 
		JoystickTabletPlugin 
		KlattSynthesizerPlugin "Klatt"
		LargeIntegersPlugin "LargeIntegers"
		Matrix2x3Plugin 
		MIDIPlugin 
		MiscPrimitivePlugin 
		Mpeg3Plugin  	
		SecurityPlugin 
		SerialPlugin 
		SocketPlugin 
		SoundCodecPlugin "SoundCodecPrims"
		SoundGenerationPlugin 
		SoundPlugin 
		StarSqueakPlugin 
		SurfacePlugin	
		LocalePlugin
		)
]

{ #category : #cmake }
Linux64x86w32BitConfigUsrLib >> dirBuildPlatform [
	^self dirLinux64x86w32BitCompatibility
]

{ #category : #cmake }
Linux64x86w32BitConfigUsrLib >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
Linux64x86w32BitConfigUsrLib >> executableName [
	"AbstractBaseClass configurations are not meant to be executable"
	^ self vmIShouldNotBeHereExecutableName
]

{ #category : #compiling }
Linux64x86w32BitConfigUsrLib >> externalLibraries [
	^#(
		     '-L/usr/lib'
		     '-L/usr/lib/X11'
			'uuid'  ""
			 'ssl'  ""
			 'crypto' ""
			 'm'      	"C math library"
			 'dl'      "dynamic linking library"
			 'pthread' "POSIX threads library"
			 'SM'   "session management library for X11"
			 'ICE'   "ICE is the Inter Client Exchange protocol, part of X11"
			 'GL'    "libGL implements the GLX interface as well as the main OpenGL API entrypoints"
			 'X11'
			 'nsl'    "network services library"
		)
				


]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfigUsrLib >> externalPluginsBuild [
	^ externalPlugins ifNil: [ externalPlugins := self defaultExternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfigUsrLib >> extraPluginSettingsBuild: aMaker [
	aMaker isExternal 
		ifTrue:[aMaker templates addLast:((CMakeSet new) variable:'LIBRARY_OUTPUT_PATH' value:'${outputDir}')].
	aMaker templates addLast:((CMakeSet new) variable:'linkFlags' quotedValue:'${linkFlags} -m32').


"	maker isExternal ifTrue: [
		maker set: 'LIBRARY_OUTPUT_PATH' to: '${outputDir}' 
	].
	maker set: #linkFlags toString: '${linkFlags} -m32'"
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfigUsrLib >> internalPluginsBuild [
	^ internalPlugins ifNil: [ internalPlugins := self defaultInternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfigUsrLib >> preferredIncludesBuild [
	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: (self class name), ' preferredIncludesBuild' )
	].
	templates
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${targetPlatform}/plugins/B3DAcceleratorPlugin')).

	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_PATH =  ${CMAKE_INCLUDE_PATH}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_SYSTEM_INCLUDE_PATH =  ${CMAKE_SYSTEM_INCLUDE_PATH}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES = ${CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES =  ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_FIND_ROOT_PATH_MODE_INCLUDE =  ${CMAKE_FIND_ROOT_PATH_MODE_INCLUDE}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_FIND_ROOT_PATH_MODE_INCLUDE =  ${CMAKE_INCLUDE_CURRENT_DIR}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_CURRENT_DIR_IN_INTERFACE =  ${CMAKE_INCLUDE_CURRENT_DIR_IN_INTERFACE}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_DIRECTORIES_BEFORE =  ${CMAKE_INCLUDE_DIRECTORIES_BEFORE}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_DIRECTORIES_PROJECT_BEFORE =  ${CMAKE_INCLUDE_DIRECTORIES_PROJECT_BEFORE}' )
	].
]
