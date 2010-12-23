Class {
	#name : #CMakeVMGenerator,
	#superclass : #CMakeGenerator,
	#instVars : [
		'internalPlugins',
		'externalPlugins',
		'config'
	],
	#category : #CMakeVMMaker
}

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> append: aString toAll: list [
	"flatten the list, adding prefix for each element"
	^ list inject: '' into: [:result :each | result, ' ', aString, each ].
]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> config [
	^ config
]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> executableName [
	^ 'Squeak'
]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> generate [
	
	| libs |
	libs := OrderedCollection new.
	
	output := String new writeStream.
		
	self 
		printHeader;
		printProjectName;
		set: #topDir toString: '../';
		setupDirectories.
		
	self set: 'CMAKE_CONFIGURATION_TYPES' to: 'Debug Release'.
	self message: '${CMAKE_CONFIGURATION_TYPES}'.
	
	self includeDirectories: self includeDirs.	
	config standardIncludes do: [:each |
		self includeDirectories: each ].

	config internalPlugins do: [:each | | plugin |
		plugin := Smalltalk at: each.
		plugin generateFor: self internal: true.
		libs add: plugin moduleName ].

	self addDefinitions: config compilerFlags.
	
	self puts: 'add_executable(' , self executableName, ' ' , self sources , ')'.

	"linker flags "
	self puts: 'set_target_properties(',self executableName, ' PROPERTIES LINK_FLAGS "', config linkFlags,'")'.
	
	self puts: 'target_link_libraries(' , self executableName , ' ' ,
		(libs inject: '' into: [:res :ea | res, ' ' , ea ]) , ')'.

	self generateExportsH: libs.
	
	self saveFile.
	
]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> generate: aConfigClass [
	config := aConfigClass new.
	^ self generate
]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> generateExportsH: libs [
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

	(self buildDir forceNewFileNamed: 'sqNamedPrims.h') nextPutAll: (config fixLineEndsOf: content); close.
	
]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> generatePlugin: aPlugin internal: aBoolean extraRules: aBlock [
	" this method called back from plugin"
	^ CMakePluginGenerator new
		generate: aPlugin for: self internal: aBoolean extraRules: aBlock
]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> includeDirs [

	^ '${crossDir}/vm ${srcVMDir} ${targetPlatform}/vm ${buildDir}'.
]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> internalPlugins: intList externalPlugins: extList [

	internalPlugins := intList.
	externalPlugins := extList.
]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> mainSettings [

	self 
		set: #platformsDir toString: '${topDir}/platforms';
		set: #srcDir toString: '${topDir}/src';
		set: #srcPluginsDir toString: '${srcDir}/plugins';
		set: #srcVMDir toString: '${srcDir}/vm';
		set: #platformName toString: self platformName;
		set: #targetPlatform to: '${platformsDir}/${platformName}';
		set: #crossDir toString: '${platformsDir}/Cross';
		set: #buildDir toString: '${topDir}/build'.

]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> platformName [
	^ config platformName

]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> saveFile [
	
	(self buildDir forceNewFileNamed: self outputFileName)
		nextPutAll: (config fixLineEndsOf: output contents);
		close.
]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> sources [

	self set: #coreSources to: 
		(self append: '${srcVMDir}/' toAll: config coreSources).
		
	self set: #platformVMSources to: 
		(self append: '${targetPlatform}/vm/' toAll: config platformSources).
	
	
	self set: #crossVMSources to: 
		(self append: '${crossDir}/vm/' toAll: #(
			'sqHeapMap.c'
			'sqTicker.c'
			'sqExternalSemaphores.c'
			'sqNamedPrims.c'
			'sqVirtualMachine.c'
		)).
		
	self set: #extraSources to: config extraSources.
	
	^ '${coreSources} ${crossVMSources} ${platformVMSources} ${extraSources}'
]
