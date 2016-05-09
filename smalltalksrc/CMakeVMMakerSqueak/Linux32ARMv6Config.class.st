"
A Linux64x86w32BitConfig is an Abstract base class that provides common information for my subclasses.
I am not meant to be built.

I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakLinux64x86w32CompatBuilder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	enableMessageTracking: true;
	generateByTemplate.



HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp



"
Class {
	#name : #Linux32ARMv6Config,
	#superclass : #SqueakUnixConfig,
	#category : #'CMakeVMMakerSqueak-Linux32ARMv6'
}

{ #category : #'cmake buildType redirects' }
Linux32ARMv6Config >> addVMPluginsBuild: aMaker [
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
Linux32ARMv6Config >> availableBuildTypes [
 	 ^SqueakCMakeVMMakerAbstractBuilder  default  noBuildTypes
"

subclasses should use

  ^super allBuildTypes copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))   "
	

]

{ #category : #'cmake buildType redirects' }
Linux32ARMv6Config >> coreSourcesBuild [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
		)
]

{ #category : #'cmake buildType redirects' }
Linux32ARMv6Config >> coreSourcesBuildMultiThreaded [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'cointerpmt.c'
		)
]

{ #category : #plugins }
Linux32ARMv6Config >> customizeCMakeVMDisplayNull [
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
Linux32ARMv6Config >> customizeCMakeVMDisplayX11 [
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
Linux32ARMv6Config >> customizeCMakeVMSoundALSA [
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
Linux32ARMv6Config >> customizeCMakeVMSoundNull [
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
Linux32ARMv6Config >> customizeVMPlugins [
	|mysubset iwantonly|
	"trim the vmdrivers ordered collection of CMakeVMDriver subclasses to only those I want. then customize them for use on this OS/platform"
"	iwantonly :=	 #(#CMakeVMDisplayNull  #CMakeVMDisplayX11  #CMakeVMSoundALSA  #CMakeVMSoundNull ).
	mysubset := vmplugins select: [:vmd | 0 < (iwantonly occurrencesOf: (vmd class name) asSymbol)]. 
	vmplugins := mysubset.
	self 
		customizeCMakeVMDisplayNull;
		customizeCMakeVMDisplayX11;
		customizeCMakeVMSoundALSA;
		customizeCMakeVMSoundNull."
]

{ #category : #plugins }
Linux32ARMv6Config >> defaultExternalPlugins [
" tty 2014.06.10  cut-n-paste from Cog/build.linux32x86/newspeak.cog.spur/build/plugins.ext"
	^ #(B3DAcceleratorPlugin 
		BochsIA32Plugin 
	      ThreadedFFIPlugin    "moduleName->SqueakFFIPrims "
		"FFIPlugin"                   "moduleName->SqueakFFIPrims "
		SqueakSSLPlugin       "moduleName->SqueakSSL" 
		LocalePlugin 
		UnixOSProcessPlugin 
		UUIDPlugin)


"N.B. Regarding ThreadedFFIPlugin and FFIPlugin from eem:

Use  ThreadedFFIPlugin.  The FFIPlugin is obsolete (it requires assembler support files, and is non-reentrant).  This should generate in src/plugins/SqueakFFIPrims/{SqueakFFIPrims.c,ARM32FFIPlugin.c,IA32FFIPlugin.c} and you should compile only src/plugins/SqueakFFIPrims/SqueakFFIPrims.c.  src/plugins/SqueakFFIPrims/SqueakFFIPrims.c is a simple wrapper that includes ARM32FFIPlugin.c or IA32FFIPlugin.c as appropriate (and others can be added as they are developed).


"
]

{ #category : #plugins }
Linux32ARMv6Config >> defaultInternalPlugins [
" tty 2014.06.10  cut-n-paste from Cog/build.linux32x86/newspeak.cog.spur/build/plugins.int
   N.B. moduleName->XYZ means XYZ appears in the GNU-Build's plugins.int/ext. However, Smalltalk requires the class name.
                                 XYZSmalltalkClass  moduleName->XYZ as it appears in plugins.int/ext
"
	^ #(
	    ADPCMCodecPlugin
    AsynchFilePlugin
    BalloonEnginePlugin "moduleName -->B2DPlugin"
    BitBltSimulation        "moduleName->BitBltPlugin"
    BMPReadWriterPlugin
    CroquetPlugin
    DeflatePlugin               "moduleName->ZipPlugin"
    DropPlugin
    DSAPlugin                    "moduleName->DSAPrims"
    FFTPlugin
    FileCopyPlugin
    FilePlugin
    FloatArrayPlugin
    FloatMathPlugin
    IA32ABIPlugin             "moduleName->IA32ABI"
   " InflatePlugin"               "moduleName->ZipPlugin"   "already included with the DeflatePlugin"
    JoystickTabletPlugin
    JPEGReaderPlugin
    JPEGReadWriter2Plugin
    KlattSynthesizerPlugin  "moduleName->Klatt"
    LargeIntegersPlugin      "moduleName->LargeIntegers"
    Matrix2x3Plugin
    MIDIPlugin
    MiscPrimitivePlugin
    Mpeg3Plugin
    RePlugin
    SecurityPlugin
    SerialPlugin
    SocketPlugin
    SoundCodecPlugin        "moduleName->SoundCodecPrims"
    SoundGenerationPlugin
    SoundPlugin
    StarSqueakPlugin
    SurfacePlugin
    VMProfileLinuxSupportPlugin)
]

{ #category : #cmake }
Linux32ARMv6Config >> dirBuildPlatform [
	^self dirLinux32Armv6
]

{ #category : #cmake }
Linux32ARMv6Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
Linux32ARMv6Config >> executableName [
	"AbstractBaseClass configurations are not meant to be executable"
	^ self vmIShouldNotBeHereExecutableName
]

{ #category : #'cmake buildType redirects' }
Linux32ARMv6Config >> externalPluginsBuild [
	^ externalPlugins ifNil: [ externalPlugins := self defaultExternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
Linux32ARMv6Config >> extraPluginSettingsBuild: aMaker [
	aMaker isExternal 
		ifTrue:[aMaker templates addLast:((CMakeSet new) variable:'LIBRARY_OUTPUT_PATH' value:'${outputDir}')].

]

{ #category : #'cmake buildType redirects' }
Linux32ARMv6Config >> internalPluginsBuild [
	^ internalPlugins ifNil: [ internalPlugins := self defaultInternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
Linux32ARMv6Config >> preferredIncludesBuild [
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
