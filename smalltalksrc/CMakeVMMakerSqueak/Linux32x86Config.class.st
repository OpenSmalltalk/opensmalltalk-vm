"
A Linux32x86Config is a Squeak Compatibility Layer between the Pharo code in CMakeVMMaker and CMakeVMakerSqueak.

I exist because modifying the pharo tree is verbotten as of 2014.06.10


"
Class {
	#name : #Linux32x86Config,
	#superclass : #CogFamilyUnixConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#instVars : [
		'buildType',
		'generateForAssert',
		'generateForAssertWithHeartbeatTimer',
		'generateForDebug',
		'generateForDebugWithHeartbeatTimer',
		'generateForDebugMultiThreadedFFI',
		'generateForReleaseHeartbeatTimer',
		'generateForReleaseMultiThreadedFFI',
		'generateForAssertHeartbeatTimer'
	],
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #'squeak compatibility' }
Linux32x86Config >> addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs [

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
Linux32x86Config >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default allBuildConfigurations copyWithoutAll:#(#releaseMultiThreadedFFI #debugMultiThreadedFFI)

]

{ #category : #'squeak compatibility' }
Linux32x86Config >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> buildDirName [
	buildType isNil
		ifTrue:[^self dirBuildPlatform, self dirBuildLanguageVMMM, 'build']
		ifFalse:[^self dirBuildPlatform, self dirBuildLanguageVMMM, buildType asString]
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> buildScript [
	"answer the build script for building everything"
	

	^ 
'#!/usr/bin/env bash

cmake .
make

'
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> buildType: aSymbol [
	buildType:= aSymbol
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> cogitClass [
	"answer a class for machine code generation or nil"
	
	^ StackToRegisterMappingCogit 
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> commonCompilerFlags [

	"Common compiler flags
	
	
	LSB_FIRST=1 means that target platform is little endian. 
	set it to 0 for big-endian platforms
	
	"
	
	^ {
		'-DLSB_FIRST=1'. 
		'-DUSE_GLOBAL_STRUCT=0'. 
		'-DCOGMTVM=0'. 
		'-m32'.
		'-DENABLE_FAST_BLT ' } 	
	
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> compilerFlags [ 
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
Linux32x86Config >> configureForAssert [
	generateForAssert := true.
]

{ #category : #cmake }
Linux32x86Config >> configureForAssertWithHeartbeatTimer [
	generateForAssertWithHeartbeatTimer := true
]

{ #category : #cmake }
Linux32x86Config >> configureForDebug [
	generateForDebug := true
]

{ #category : #cmake }
Linux32x86Config >> configureForDebugMultiThreadedFFI [
	generateForDebugMultiThreadedFFI := true
]

{ #category : #cmake }
Linux32x86Config >> configureForDebugWithHeartbeatTimer [
	generateForDebugWithHeartbeatTimer := true
]

{ #category : #cmake }
Linux32x86Config >> configureForRelease [
	"this variable is in pharo class CPlatformConfig"
	generateForRelease := true.
]

{ #category : #cmake }
Linux32x86Config >> configureForReleaseHeartbeatTimer [
	generateForReleaseHeartbeatTimer := true.
]

{ #category : #cmake }
Linux32x86Config >> configureForReleaseMultiThreadedFFI [
	generateForReleaseMultiThreadedFFI := true
]

{ #category : #plugins }
Linux32x86Config >> defaultExternalPlugins [
	^ #(SqueakSSL	)
]

{ #category : #plugins }
Linux32x86Config >> defaultInternalPlugins [
" cut-n-paste from Cog/build.linux32x86/newspeak.cog.v3/build"
	^ #(
		AsynchFilePlugin 
		BMPReadWriterPlugin 
		B2DPlugin 
		BitBltPlugin 
		DSAPrims 
		DropPlugin 
		FileCopyPlugin 
		FilePlugin 
		FloatArrayPlugin 
		FloatMathPlugin 
		ZipPlugin 
		JPEGReadWriter2Plugin 
		JPEGReaderPlugin 
		LargeIntegers 
		Matrix2x3Plugin 
		MiscPrimitivePlugin 
		IA32ABI 
		RePlugin 
		SecurityPlugin 
		SocketPlugin 
		SurfacePlugin 
		UUIDPlugin 
		UnixOSProcessPlugin 
		VMProfileLinuxSupportPlugin)
]

{ #category : #cmake }
Linux32x86Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogV3
]

{ #category : #cmake }
Linux32x86Config >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirLinux32x86
]

{ #category : #cmake }
Linux32x86Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build"
	^true
]

{ #category : #'initialize-release' }
Linux32x86Config >> initialize [
	super initialize.
	"this should be in my superclass, but I do not have permission to modify it. tty"
	 generateForAssert:= generateForAssertHeartbeatTimer:= generateForDebug :=generateForDebugWithHeartbeatTimer:= generateForDebugMultiThreadedFFI:= generateForReleaseHeartbeatTimer:= generateForReleaseMultiThreadedFFI:=false
]

{ #category : #cmake }
Linux32x86Config >> oscogvm [
	^ 'oscogvm'
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> outputDir [

	"the directory where built binaries will be stored"
	^ outputDir ifNil: [ outputDir := (self topDir / self outputDirName) ]	


]

{ #category : #'squeak compatibility' }
Linux32x86Config >> prepareVMMaker [
	
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
Linux32x86Config >> setupDirectories: gen [
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
Linux32x86Config >> srcDir [
		^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'src' )]
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> topDir [
	"N.B. this is a clash between Trait usage and Inheritence usage due to restrictions on modifying pharo's source"
	^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
	
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> validateSourcesPresent [
	| sources |
	sources := Smalltalk sourcesName.
	
	(sources == nil)
		ifTrue: [	self error: 'VM source code cannot be generated without .sources file'.]		
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> write: aContents toFile: aFileName [
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
