"
I am using for generating CMakeLists.txt (cmake config files) for specific plugin.
The direct use of my instances is not recommended.
Use CMakeVMGenerator and appropriate configuration to generate both VM and plugins cmake config files.
"
Class {
	#name : #CMakePluginGenerator,
	#superclass : #CMakeGenerator,
	#instVars : [
		'plugin',
		'vmGen',
		'internal',
		'extraRules',
		'doNotGenerate'
	],
	#category : #CMakeVMMaker
}

{ #category : #'as yet unclassified' }
CMakePluginGenerator >> addCrossSources: sources [

	^ self addSources: sources prefixed: '${pluginCross}/'

]

{ #category : #'as yet unclassified' }
CMakePluginGenerator >> addExternalLibrary: aLibrary [ 

	self isInternal ifTrue: [
		vmGen addExternalLibrary: aLibrary  
		]
	ifFalse: [ super addExternalLibrary: aLibrary ]

]

{ #category : #'as yet unclassified' }
CMakePluginGenerator >> addPlatformSources: sources [

	^ self addSources: sources prefixed: '${pluginPlatform}/'

]

{ #category : #'as yet unclassified' }
CMakePluginGenerator >> config [
	^ vmGen config
]

{ #category : #'as yet unclassified' }
CMakePluginGenerator >> configurationName [
	^ vmGen configurationName
]

{ #category : #accessing }
CMakePluginGenerator >> doNotGenerate [

	"Forcely exclude plugin form build. Use this method only for debugging purposes.
	
	Front-end users should simply specify different list of plugins for building VM,
	effectively excluding any unwanted stuff "
	
	^doNotGenerate
]

{ #category : #accessing }
CMakePluginGenerator >> doNotGenerate: aValue [

	"Forcely exclude plugin form build. Use this method only for debugging purposes.
	
	Front-end users should simply specify different list of plugins for building VM,
	effectively excluding any unwanted stuff "
	
	doNotGenerate := aValue
]

{ #category : #'code generation' }
CMakePluginGenerator >> generate [

	| name |
	output := String new writeStream.

	name := plugin moduleName.
#(	vmGen config setGlobalOptions: self.
	
	self 
		printHeader;
		project: name;
		"include directories generated for build"
		include: '../directories.cmake'.
	
	self set: 'CMAKE_CONFIGURATION_TYPES' to: 'Release'.
).

	self message: (internal ifTrue: [ 'Adding internal plugin: '] ifFalse: ['Adding external plugin: '])  , name.

	self 
		set: #pluginName toString: name;
		set: #pluginSrc toString: '${srcPluginsDir}/', name;
		set: #pluginCross toString: '${crossDir}/plugins/', name;
		set: #pluginPlatform toString: '${targetPlatform}/plugins/', name.

	"clear LINKLIBS variable"
	self set: #LINKLIBS to: ''.		
	
	internal 
		ifTrue: [ self puts: 'add_definitions(-DSQUEAK_BUILTIN_PLUGIN)'].
	
	self addSources: { name , '.c' } prefixed: '${pluginSrc}/'.

	" default include directories for plugin "
	self includeDirectories: '${pluginSrc} ${pluginCross} ${targetPlatform}/plugins/${pluginName}'.
	
	"Not needed because there are already there (inherited from main configuration)"
	"self addDefinitions: vmGen config compilerFlags."

	" perform config's configureXYZ: message to apply per-plugin custom rules, if any "
	
	vmGen config configurePlugin: plugin with: self.
	
	extraRules ifNotNil: [ extraRules value: self ].
	
	" generate a static lib for internal plugin, or shared for external"
	internal ifTrue: [
		self cmd: 'add_library' params:  name , ' STATIC ${sources}'.
	] ifFalse: [
		self cmd: 'add_library' params: name , ' SHARED ${sources}'.
		
	"	self cmd: 'set_property' params: 'TARGET ' , name , ' PROPERTY LINK_FLAGS -bundle'"
	].

	vmGen config extraPluginSettings: self.
	
	self isExternal ifTrue: [
		self cmd: 'target_link_libraries'
			params: self moduleName , ' ${LINKLIBS}'.
		].
	
	" see senders of #linkFlags "
	self 
		cmd: 'set_property' 
		params: 'TARGET ', name, ' PROPERTY LINK_FLAGS "${linkFlags}"'.
	
	"set dependencies"
	self puts: 'IF (',self moduleName , '_dependencies)'.
	
	self cmd: 'add_dependencies'
		params: name , ' ${', self moduleName , '_dependencies}'.
	
	self puts: 'ENDIF (',self moduleName , '_dependencies)'.
	self saveFile.
]

{ #category : #'as yet unclassified' }
CMakePluginGenerator >> generate: aPlugin for: aCMakeVMGenerator internal: aBoolean extraRules: aBlock [

	doNotGenerate := false.
	internal := aBoolean.
	plugin := aPlugin.
	vmGen := aCMakeVMGenerator.
	extraRules := aBlock.
		
	^ self generate
]

{ #category : #testing }
CMakePluginGenerator >> isExternal [
	^ internal not
]

{ #category : #accessing }
CMakePluginGenerator >> isInternal [
	^ internal
]

{ #category : #accessing }
CMakePluginGenerator >> moduleName [ 
	^plugin moduleName
]

{ #category : #accessing }
CMakePluginGenerator >> plugin [
	^ plugin
]

{ #category : #'as yet unclassified' }
CMakePluginGenerator >> saveFile [
	
	| reference |
	reference := ((vmGen config dirFrom: vmGen buildDir) / plugin moduleName) ensureDirectory; yourself.
	(FileStream forceNewFileNamed: (reference / self outputFileName) fullName)
		nextPutAll: (self config fixLineEndsOf: output contents);
		close.
]

{ #category : #accessing }
CMakePluginGenerator >> vmGenerator [
	"Make it accessible from plugin generator side"
	^ vmGen
]
