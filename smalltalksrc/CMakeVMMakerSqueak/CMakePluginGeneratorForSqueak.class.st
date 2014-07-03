"
A CMakePluginGeneratorForSqueak overides some CMakeVMPluginGenerator methods for squeak compatibility. 

Instance Variables

"
Class {
	#name : #CMakePluginGeneratorForSqueak,
	#superclass : #CMakeGeneratorForSqueak,
	#instVars : [
		'plugin',
		'vmGen',
		'internal',
		'extraRules',
		'doNotGenerate',
		'externalDependencies'
	],
	#category : #CMakeVMMakerSqueak
}

{ #category : #'as yet unclassified' }
CMakePluginGeneratorForSqueak >> addCrossSources: sources [

	^ self addSources: sources prefixed: '${pluginCross}/'

]

{ #category : #'as yet unclassified' }
CMakePluginGeneratorForSqueak >> addExternalDependency: aString [ 
	"We need to collect external dependencies to internal plugins because we need to force its 
	resolve before, and if we just add teh dependency in executable some times is not enough. 
	check StackIPhoneConfig>>#configureFT2Plugin: as an example"
	externalDependencies := externalDependencies copyWith: aString.
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> addExternalLibrary: aLibrary [ 
	self isInternal 
		ifTrue: [ vmGen addExternalLibrary: aLibrary ]
		ifFalse: [ super addExternalLibrary: aLibrary ].
]

{ #category : #'as yet unclassified' }
CMakePluginGeneratorForSqueak >> addPlatformSources: sources [

	^ self addSources: sources prefixed: '${pluginPlatform}/'

]

{ #category : #'as yet unclassified' }
CMakePluginGeneratorForSqueak >> config [
	^ vmGen config
]

{ #category : #'as yet unclassified' }
CMakePluginGeneratorForSqueak >> configurationName [
	^ vmGen configurationName
]

{ #category : #'as yet unclassified' }
CMakePluginGeneratorForSqueak >> doNotGenerate [

	"Forcely exclude plugin form build. Use this method only for debugging purposes.
	
	Front-end users should simply specify different list of plugins for building VM,
	effectively excluding any unwanted stuff "
	
	^doNotGenerate
]

{ #category : #'as yet unclassified' }
CMakePluginGeneratorForSqueak >> doNotGenerate: aValue [

	"Forcely exclude plugin form build. Use this method only for debugging purposes.
	
	Front-end users should simply specify different list of plugins for building VM,
	effectively excluding any unwanted stuff "
	
	doNotGenerate := aValue
]

{ #category : #'as yet unclassified' }
CMakePluginGeneratorForSqueak >> externalDependencies [
	^ externalDependencies
]

{ #category : #'squeak compatibility' }
CMakePluginGeneratorForSqueak >> generate [

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

{ #category : #'squeak compatibility' }
CMakePluginGeneratorForSqueak >> generate: aPlugin for: aCMakeVMGenerator internal: aBoolean extraRules: aBlock [

	doNotGenerate := false.
	internal := aBoolean.
	plugin := aPlugin.
	vmGen := aCMakeVMGenerator.
	extraRules := aBlock.
		
	^ self generate
]

{ #category : #'initialize-release' }
CMakePluginGeneratorForSqueak >> initialize [ 
	super initialize.
	externalDependencies := #().
]

{ #category : #'as yet unclassified' }
CMakePluginGeneratorForSqueak >> isExternal [
	^ internal not
]

{ #category : #accessing }
CMakePluginGeneratorForSqueak >> isInternal [
	^ internal
]

{ #category : #accessing }
CMakePluginGeneratorForSqueak >> isInternal: aBoolean [
	internal:= aBoolean
]

{ #category : #accessing }
CMakePluginGeneratorForSqueak >> moduleName [ 
	^plugin moduleName
]

{ #category : #'as yet unclassified' }
CMakePluginGeneratorForSqueak >> plugin [
	^ plugin
]

{ #category : #'squeak compatibility' }
CMakePluginGeneratorForSqueak >> saveFile [
	
	| reference |
	reference := ((vmGen config dirFrom: vmGen buildDir) / plugin moduleName).
	reference assureExistence.
	reference 
		forceNewFileNamed: (self outputFileName)
		do:[:s | s nextPutAll:(self config fixLineEndsOf: output contents)]

]

{ #category : #accessing }
CMakePluginGeneratorForSqueak >> vmGenerator [
	"Make it accessible from plugin generator side"
	^ vmGen
]

{ #category : #accessing }
CMakePluginGeneratorForSqueak >> vmGenerator: aCMakeVMGeneratorForSqueak [
	"needed for tests"
	vmGen := aCMakeVMGeneratorForSqueak
]
