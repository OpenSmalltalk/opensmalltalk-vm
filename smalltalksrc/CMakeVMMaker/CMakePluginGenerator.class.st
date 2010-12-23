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
		set: #topDir toString: '../..'.
				
	self message: (internal ifTrue: [ 'Adding internal plugin: '] ifFalse: ['Adding external plugin'])  , name.
	
	self setupDirectories.
	
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
	
	((self buildDir / plugin moduleName) assureExistence forceNewFileNamed: self outputFileName) 
		nextPutAll: self contents; close.

]

{ #category : #'as yet unclassified' }
CMakePluginGenerator >> vmGenerator [
	"Make it accessible from plugin generator side"
	^ vmGen
]
