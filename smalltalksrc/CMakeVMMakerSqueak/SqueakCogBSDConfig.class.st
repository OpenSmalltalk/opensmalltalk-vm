"
I am a configuration for Cog on BSD.




Usage:
SqueakCogFreeBSDConfig generateWithSources
or:
SqueakCogFreeBSDConfig generate


"
Class {
	#name : #SqueakCogBSDConfig,
	#superclass : #CogUnixConfig,
	#traits : 'TSqueakStackUnixConfig - {#externalPlugins. #internalPlugins}',
	#classTraits : 'TSqueakStackUnixConfig classTrait',
	#category : #'CMakeVMMakerSqueak-FreeBSD'
}

{ #category : #accessing }
SqueakCogBSDConfig >> addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs [

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

{ #category : #'as yet unclassified' }
SqueakCogBSDConfig >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #'as yet unclassified' }
SqueakCogBSDConfig >> buildDirName [
	^ 'cmake_unixbuild/bld'
]

{ #category : #'as yet unclassified' }
SqueakCogBSDConfig >> compilerFlags [ 
	| releaseFlags |
	
	releaseFlags := self isGenerateForRelease 
		ifTrue: [ self compilerFlagsRelease ]
		ifFalse: [ self compilerFlagsDebug ].
		
	^ String streamContents: [ :stream |
		((self commonCompilerFlags, releaseFlags)
			asStringOn: stream 
			delimiter: ' ' )]
]

{ #category : #'as yet unclassified' }
SqueakCogBSDConfig >> defaultExternalPlugins [
	^ (super defaultExternalPlugins copyWithoutAll: #(#IA32ABIPlugin #ThreadedIA32FFIPlugin #InternetConfigPlugin ))

]

{ #category : #'as yet unclassified' }
SqueakCogBSDConfig >> defaultInternalPlugins [
	^ (super defaultInternalPlugins copyWithoutAll: #(#IA32ABIPlugin #JoystickTabletPlugin #StarSqueakPlugin #SurfacePlugin#ThreadedIA32FFIPlugin))

]

{ #category : #accessing }
SqueakCogBSDConfig >> executableName [
	^ 'cogvm'
]

{ #category : #'as yet unclassified' }
SqueakCogBSDConfig >> outputDir [

	"the directory where built binaries will be stored"
	^ outputDir ifNil: [ outputDir := (self topDir / self outputDirName) ]	


]

{ #category : #'as yet unclassified' }
SqueakCogBSDConfig >> prepareVMMaker [
	
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

{ #category : #'as yet unclassified' }
SqueakCogBSDConfig >> setupDirectories: gen [
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

{ #category : #'as yet unclassified' }
SqueakCogBSDConfig >> srcDir [
		^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'src' )]
]

{ #category : #'as yet unclassified' }
SqueakCogBSDConfig >> topDir [
	^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: 'oscogvm' ]
]

{ #category : #'as yet unclassified' }
SqueakCogBSDConfig >> validateSourcesPresent [
	| sources |
	sources := Smalltalk sourcesName.
	
	(sources == nil)
		ifTrue: [	self error: 'VM source code cannot be generated without .sources file'.]		
]

{ #category : #accessing }
SqueakCogBSDConfig >> write: aContents toFile: aFileName [
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
