Class {
	#name : #CMakePluginGenerator,
	#superclass : #CMakeGenerator,
	#instVars : [
		'plugin',
		'vmGen',
		'internal',
		'extraRules'
	],
	#category : #CMakeVMMaker
}

{ #category : #'as yet unclassified' }
CMakePluginGenerator >> addCrossSources: sources [

	^ self addSources: sources prefixed: '${pluginCross}/'

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
CMakePluginGenerator >> generate [

	| name |
	output := String new writeStream.

	name := plugin moduleName.
	self 
		printHeader;
		project: name;
		"config's topdir, if set, should be absolute"
		set: #topDir toString: (vmGen topDir fullName). 
		vmGen setupDirectories: self. "take dirs from parent gen"

	self message: (internal ifTrue: [ 'Adding internal plugin: '] ifFalse: ['Adding external plugin'])  , name.

"	self puts: 'set(CMAKE_OSX_ARCHITECTURES i386)'.	
"
	self 
		set: #pluginName toString: name;
		set: #pluginSrc toString: '${srcPluginsDir}/', name;
		set: #pluginCross toString: '${crossDir}/plugins/', name;
		set: #pluginPlatform to: '${targetPlatform}/plugins/', name.
		
	
	internal ifTrue: [
		self puts: 'add_definitions(-DSQUEAK_BUILTIN_PLUGIN)'].
	
	self addSources: { name , '.c' } prefixed: '${pluginSrc}/'.

	" default include directories for plugin "
	self includeDirectories: '${pluginSrc} ${pluginCross} ${targetPlatform}/plugins/${pluginName}'.
	
	self addDefinitions: vmGen config compilerFlags.

	extraRules ifNotNil: [ extraRules value: self ].
	
	vmGen config extraPluginSettings: self.

	self puts: 'add_library(' , name ,
		' STATIC ${sources} )'.
	
	vmGen addSubdirectory: name. 
	
	self saveFile.

]

{ #category : #'as yet unclassified' }
CMakePluginGenerator >> generate: aPlugin for: aCMakeVMGenerator internal: aBoolean extraRules: aBlock [

	internal := aBoolean.
	plugin := aPlugin.
	vmGen := aCMakeVMGenerator.
	extraRules := aBlock.
		
	^ self generate
]

{ #category : #'as yet unclassified' }
CMakePluginGenerator >> saveFile [
	
	((vmGen buildDir / plugin moduleName) assureExistence forceNewFileNamed: self outputFileName) 
		nextPutAll: (self config fixLineEndsOf: output contents); close.

]

{ #category : #'as yet unclassified' }
CMakePluginGenerator >> vmGenerator [
	"Make it accessible from plugin generator side"
	^ vmGen
]
