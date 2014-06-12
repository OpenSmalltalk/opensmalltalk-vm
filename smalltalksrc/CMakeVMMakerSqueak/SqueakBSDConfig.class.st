"
A SqueakBSDConfig  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

My subclasses do actual configurations, I just sit here and look good. Plus, I encapsulate common behavior. But mostly I just sit here.

"
Class {
	#name : #SqueakBSDConfig,
	#superclass : #CogFamilyUnixConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#instVars : [
		'generateForAssertWithHeartbeatTimer',
		'generateForDebug',
		'generateForDebugMultiThreadedFFI',
		'generateForDebugWithHeartbeatTimer',
		'generateForAssert',
		'generateForAssertHeartbeatTimer',
		'generateForReleaseHeartbeatTimer',
		'generateForReleaseMultiThreadedFFI'
	],
	#category : #'CMakeVMMakerSqueak-BSD32x86'
}

{ #category : #'as yet unclassified' }
SqueakBSDConfig class >> availableBuilds [
	"SqueakCMakeVMMakerAbstractBuilder  allBuildConfigurations"
	^#(#assert #debug  #release )
]

{ #category : #accessing }
SqueakBSDConfig >> addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs [

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
			set: 'LIBRARY_OUTPUT_PATH' toString: self outputDir fullName;
			addExternalLibraries: extLibs;
			cmd: 'target_link_libraries' params: name , ' ${LINKLIBS}';
			cmd: 'set_target_properties' params: name , ' PROPERTIES PREFIX "" SUFFIX "" 
			LINK_FLAGS -m32' 
	].
	
	(self buildDir / name) assureExistence.
	self write: cfg toFile: name , '/', cmakeGen outputFileName.
	cmakeGen addSubdirectory:  name.
	
]

{ #category : #cmake }
SqueakBSDConfig >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default  noBuildConfigurations

]

{ #category : #'squeak compatibility' }
SqueakBSDConfig >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #'squeak compatibility' }
SqueakBSDConfig >> buildDirName [
	buildType isNil
		ifTrue:[^self dirBuildPlatform, FileDirectory slash, self dirBuildLanguageVMMM, FileDirectory slash, 'build']
		ifFalse:[^self dirBuildPlatform, FileDirectory slash, self dirBuildLanguageVMMM, FileDirectory slash, buildType asString]
]

{ #category : #'squeak compatibility' }
SqueakBSDConfig >> compilerFlags [ 
	| releaseFlags |
	
	releaseFlags := self isGenerateForRelease 
		ifTrue: [ self compilerFlagsRelease ]
		ifFalse: [ self compilerFlagsDebug ].
		
	^ String streamContents: [ :stream |
		((self commonCompilerFlags, releaseFlags)
			asStringOn: stream 
			delimiter: ' ' )]
]

{ #category : #cmake }
SqueakBSDConfig >> configureForAssertWithHeartbeatTimer [
	generateForAssertWithHeartbeatTimer := true
]

{ #category : #cmake }
SqueakBSDConfig >> configureForBuildType: aSymbol [
	| d |
	self configureForNoBuildType.                "reset all internal flags"
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo.
	d 
		at: #assert put:[self configureForAssert];
		at: #assertWithHeartbeatTimer put: [self configureForAssertWithHeartbeatTimer];
            at:#debug put: [self configureForDebug];
		at: #debugWithHeartbeatTimer put: [self configureForDebugWithHeartbeatTimer];
		at: #debugMultiThreadedFFI put: [self configureForDebugMultiThreadedFFI];
		at: #release put: [self configureForRelease];
		at: #releaseHeartbeatTimer put: [self configureForReleaseHeartbeatTimer];
		at: #releaseMultiThreadedFFI put: [self configureForReleaseMultiThreadedFFI].
     ^(d at: aSymbol) value
]

{ #category : #cmake }
SqueakBSDConfig >> configureForDebug [
	generateForDebug := true
]

{ #category : #cmake }
SqueakBSDConfig >> configureForDebugMultiThreadedFFI [
	generateForDebugMultiThreadedFFI := true
]

{ #category : #cmake }
SqueakBSDConfig >> configureForDebugWithHeartbeatTimer [
	generateForDebugWithHeartbeatTimer := true
]

{ #category : #cmake }
SqueakBSDConfig >> configureForNoBuildType [
	"this could be dangerous. If it becomes so, then just reset all the generateForXYZ flags in the topmost config. Currently that is all that initialize does."
		 generateForAssert:= generateForAssertHeartbeatTimer:= generateForDebug :=generateForDebugWithHeartbeatTimer:= generateForDebugMultiThreadedFFI:= generateForReleaseHeartbeatTimer:= generateForReleaseMultiThreadedFFI:=false
]

{ #category : #cmake }
SqueakBSDConfig >> configureForRelease [
	"this variable is in pharo class CPlatformConfig"
	generateForRelease := true.
]

{ #category : #cmake }
SqueakBSDConfig >> configureForReleaseHeartbeatTimer [
	generateForReleaseHeartbeatTimer := true.
]

{ #category : #cmake }
SqueakBSDConfig >> configureForReleaseMultiThreadedFFI [
	generateForReleaseMultiThreadedFFI := true
]

{ #category : #plugins }
SqueakBSDConfig >> defaultExternalPlugins [
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
SqueakBSDConfig >> defaultInternalPlugins [
" N.B. THESE MAY BE WILDLY INAPPROPRIATE FOR BSD. cut-n-pasted from Linux32x86Config.
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
    InflatePlugin               "moduleName->ZipPlugin"
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
SqueakBSDConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	self required
]

{ #category : #cmake }
SqueakBSDConfig >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirBSD32x86
]

{ #category : #'squeak compatibility' }
SqueakBSDConfig >> dirFrom: aStringOrDir [
	^ aStringOrDir isString
		ifTrue: [ FileDirectory forFileName: aStringOrDir  ]
		ifFalse: [ aStringOrDir ]
]

{ #category : #cmake }
SqueakBSDConfig >> excludeFromBuild [
	^true

]

{ #category : #'squeak compatibility' }
SqueakBSDConfig >> executableName [
	^ 'cogvm'
]

{ #category : #'squeak compatibility' }
SqueakBSDConfig >> outputDir [

	"the directory where built binaries will be stored"
	^ outputDir ifNil: [ outputDir := (self topDir / self outputDirName) ]	


]

{ #category : #'squeak compatibility' }
SqueakBSDConfig >> prepareVMMaker [
	
	| maker allPlugins |
	
	"In CogVMs (in contrast to Interpreter VM) the generated sources are platform independent, therefore Cross is ok"
	maker := VMMaker forPlatform: 'Cross'.
	
	maker sourceDirectoryName: self srcDir pathName.
	maker platformRootDirectoryName: self platformsDir.
	
	
	allPlugins := self internalPlugins , self externalPlugins.
	
	"touch plugins to force their source generation unconditionally"
	allPlugins do: [:name | (Smalltalk globals at: name) touch ].
	
	" Why we put all plugins as external?   Because the generated sources are not different whether the plugins were defined as internal or external. VMMaker used to need this to to generate plugins.int and plugins.ext files. But since this is achieved in another way with CMakeVMMaker, there is no different at all to put all plugins as internal or as external."
	maker externalModules addAll:  allPlugins.
	
	^ maker
]

{ #category : #'squeak compatibility' }
SqueakBSDConfig >> setupDirectories: gen [
	| dirsInclude |

	" write the directories in separate include file"
	dirsInclude := gen captureOutputDuring: [
		gen
			set: #topDir toString: (self topDir fullName); 
			set: #buildDir toString: (self buildDir ifNil: ['${topDir}/build'] ifNotNil: [self buildDir fullName] );
			set: #thirdpartyDir toString: '${buildDir}/thirdParty';
			set: #platformsDir toString: self platformsDir;
			set: #srcDir toString: self srcDir pathName;
			set: #srcPluginsDir toString: (pluginsDir ifNil: [ '${srcDir}/plugins' ]);
			set: #srcVMDir toString: '${srcDir}/vm';
			set: #platformName toString: self platformName;
			set: #targetPlatform to: '${platformsDir}/${platformName}';
			set: #crossDir toString: '${platformsDir}/Cross';
			set: #platformVMDir toString: '${targetPlatform}/vm';
			set: #outputDir toString: self outputDir fullName.
	].

	self write: dirsInclude toFile: 'directories.cmake'.
	
	gen include: 'directories.cmake'.

]

{ #category : #'squeak compatibility' }
SqueakBSDConfig >> srcDir [
		^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'src' )]
]

{ #category : #'squeak compatibility' }
SqueakBSDConfig >> topDir [
		^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
]

{ #category : #'squeak compatibility' }
SqueakBSDConfig >> validateSourcesPresent [
	| sources |
	sources := Smalltalk sourcesName.
	
	(sources == nil)
		ifTrue: [	self error: 'VM source code cannot be generated without .sources file'.]		
]

{ #category : #'squeak compatibility' }
SqueakBSDConfig >> write: aContents toFile: aFileName [
	"write a file to current output directory (buildDir).
	use line end convention appropriate for config platform"

	| bldDir |
	bldDir := self buildDir.
	bldDir isString
		ifTrue: [ bldDir := FileDirectory directoryEntryFor: bldDir ].
	bldDir assureExistence.
	bldDir
		forceNewFileNamed: aFileName
		do: [:s | s
				nextPutAll: (self fixLineEndsOf: aContents)]


]
