"
A CMakeVMGeneratorForSqueak overides some CMakeVMGenerator methos for squeak compatibility. 


"
Class {
	#name : #CMakeVMGeneratorForSqueak,
	#superclass : #CMakeGenerator,
	#instVars : [
		'internalPlugins',
		'externalPlugins',
		'config'
	],
	#category : #CMakeVMMakerSqueak
}

{ #category : #'as yet unclassified' }
CMakeVMGeneratorForSqueak class >> generateByTemplate: aConfigOrClass [  
	^self new 
		generateByTemplate: aConfigOrClass;
		yourself  
]

{ #category : #'as yet unclassified' }
CMakeVMGeneratorForSqueak >> append: aString toAll: list [
	"flatten the list, adding prefix for each element"
	^ list inject: '' into: [:result :each | result, ' ', aString, each ].
]

{ #category : #'as yet unclassified' }
CMakeVMGeneratorForSqueak >> buildDir [
	^ config buildDir
]

{ #category : #accessing }
CMakeVMGeneratorForSqueak >> config [
	^ config
]

{ #category : #accessing }
CMakeVMGeneratorForSqueak >> config: aCPlatformConfigForSqueak [
	config:=aCPlatformConfigForSqueak
	"accessor method needed for testing"
]

{ #category : #'as yet unclassified' }
CMakeVMGeneratorForSqueak >> configurationName [
	^ config class name
]

{ #category : #'as yet unclassified' }
CMakeVMGeneratorForSqueak >> generateBuildScript [

	(FileStream forceNewFileNamed: (self buildDir / 'build.sh') fullName) nextPutAll: (config fixLineEndsOf: config buildScript); close.
	
]

{ #category : #'code generation' }
CMakeVMGeneratorForSqueak >> generateByTemplate [
	"attempt to move way from string based writing to  template based. Think Seaside renderOn composition"
	| extPlugins intPlugins |
	self flag: 'tty'. "refactor so that the cascade reflects CMake terminilogy"
	output := String new writeStream.
	config templates: OrderedCollection new. 
	self break.
	config 
		setGlobalOptions: self;    
		cmakePrefixPath;
		cmakeIncludePath;
		cmakeLibraryPath;
		cmakeIncludeModules;
		cmakeCFlags;          
		cmakeAddDefinitions;
		cmakeWriteDirectoriesDotCmake:  self;
		cmakeIncludeDirectories:  self;   "<---"
		preferredIncludes;                      "<---why 3  of em?"
		standardIncludes;                       "<---"
		setGlobalOptionsAfterDetermineSystem: self;    
		extraVMSettings: self;                "<--catch-all method. os/platform specific"
		setCoreSources: self;
		setPlatformSources: self;
		setCrossSources: self;
		setExtraSources;
		cmakeSetSourceFilesProperties;
		cmakeListAppend:'LINKLIBS' elements: (config externalLibs);
		cmakeAddExecutableNameOptionSource: self;
	      setExecutableOutputPath;
		addVMPlugins: self.
	config templates do: [:each | self puts: each content].
	config templates: OrderedCollection new. 
	extPlugins := self generatePluginConfigs: config internalPlugins internal: true.
	 intPlugins := self generatePluginConfigs: config externalPlugins internal: false.
	self processThirdpartyLibraries.                       "<--unused in Pharo code? What exactly does this do?"
	self processPlugins:  intPlugins, extPlugins.
	self config templates	addLast:((CMakeCommand new) command:'target_link_libraries' params:(self moduleName , ' ${LINKLIBS}')).
"	self cmd: 'target_link_libraries'
		params: self moduleName , ' ${LINKLIBS}'."
	config postBuildActions: self..
	config templates do: [:each | self puts: each content].
	self saveFile.
	self generateBuildScript
]

{ #category : #'as yet unclassified' }
CMakeVMGeneratorForSqueak >> generateByTemplate: aConfigOrClass [
	
	config := aConfigOrClass isBehavior ifTrue: [ aConfigOrClass new ] ifFalse: [aConfigOrClass].
	^ self generateByTemplate
]

{ #category : #'as yet unclassified' }
CMakeVMGeneratorForSqueak >> generateExportsH: libs [
	| content |
	content := String streamContents: [:str |
	
		str nextPutAll: '/* This is automatically generated file using CVMMaker on ',
			Date current asString, ' ' , Time current asString , ' */'; cr.
		
		str nextPutAll: 
'extern sqExport vm_exports[];
extern sqExport os_exports[];
'.
		libs do: [:each | 
			str nextPutAll: 'extern sqExport ', each ,'_exports [];'; cr ].
		
		str cr; nextPutAll: 'sqExport *pluginExports[] = {
	vm_exports,
	os_exports,
'.

		libs do: [:each | 
			str nextPutAll:  each ,'_exports,'; cr ].
	
		str nextPutAll: 'NULL
};'

	].

	(FileStream forceNewFileNamed: (self buildDir /'sqNamedPrims.h') fullName) nextPutAll: (config fixLineEndsOf: content); close.
	
]

{ #category : #'as yet unclassified' }
CMakeVMGeneratorForSqueak >> generatePlugin: aPlugin internal: aBoolean extraRules: aBlock [
	" this method called back from plugin"
	^ CMakePluginGeneratorForSqueak new
		generate: aPlugin for: self internal: aBoolean extraRules: aBlock
]

{ #category : #'as yet unclassified' }
CMakeVMGeneratorForSqueak >> generatePluginConfigs: plugins internal: bool [
	"Answers a collection of CMakePluginGenerator instances"
	
	^ plugins collect: [:each | | plugin |
		plugin := Smalltalk at: each.
		plugin generateFor: self internal: bool.
	].
	

]

{ #category : #'sources management' }
CMakeVMGeneratorForSqueak >> includeDirs [

	^ '${crossDir}/vm ${srcVMDir} ${targetPlatform}/vm ${buildDir}'.
]

{ #category : #accessing }
CMakeVMGeneratorForSqueak >> moduleName [ 
	^config executableName
]

{ #category : #'as yet unclassified' }
CMakeVMGeneratorForSqueak >> processPlugins: pluginGenerators [
	| libs libDeps |
	libs := OrderedCollection new.
	libDeps := Dictionary new.
	pluginGenerators do: [:gen |
		gen doNotGenerate ifFalse: [
			self  puts: (gen configDotCMake at: (gen plugin name) ifAbsent:[gen configDotCmakeEmpty]). 
			gen isInternal 
				ifTrue: [
					libs add: gen plugin moduleName ]
				ifFalse: [
					"make main module to depend on external plugin, just to make sure it is built 
					 before main module built"
					self 
						cmd: 'add_dependencies' 
						params: config executableName, ' ' , gen plugin moduleName ].
				gen externalDependencies 
					ifNotEmpty: [ :deps |
						libDeps 
							at: gen plugin moduleName
							put: (deps fold: [ :a :b | a, ' ', b ]) ].
			self addSubdirectory: gen plugin moduleName ] ].

	self cmd: 'target_link_libraries' params:  config executableName , ' ' ,
		(libs inject: '' into: [:res :ea | res, ' ' , ea ]).

	libDeps keysAndValuesDo: [ :moduleName :dependencies |
		self 
			cmd: 'add_dependencies' 
			params: moduleName, ' ', dependencies ].  

	self generateExportsH: libs.
]

{ #category : #'as yet unclassified' }
CMakeVMGeneratorForSqueak >> processThirdpartyLibraries [
	self flag:'tty'. "This generate call must be transformed to generateByTemplateFor:"
	config thirdpartyLibs do: [:each | 
		each generateFor: self ]


]

{ #category : #'as yet unclassified' }
CMakeVMGeneratorForSqueak >> saveFile [
	
	config write: output contents toFile: (self outputFileName).
	
]

{ #category : #'as yet unclassified' }
CMakeVMGeneratorForSqueak >> sources [
	self flag: 'tty'. "code smell. I have moved the 'self set:' stuff to addCMakeExectuableTemplate: aMaker"
"	self set: #coreSources to: 	(self append: '${srcVMDir}/' toAll: config coreSources).
	self set: #platformVMSources to: (self append: '${targetPlatform}/vm/' toAll: config platformSources).
	self set: #crossVMSources to: 	(self append: '${crossDir}/vm/' toAll: config crossSources).
	self set: #extraSources to: config extraSources."	
	^ '${coreSources} ${crossVMSources} ${platformVMSources} ${extraSources}'
]
