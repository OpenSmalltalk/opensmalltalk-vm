"
I am generating a cmake configuration file (CMakeLists.txt)
for building a Squeak Virtual Machine.


Usage: 

CMakeVMGenerator new generate: CogMacOSConfig

or

CMakeVMGenerator new generate: (CogMacOSConfig new setOption: ... ; yourself)

you can provide any valid configuration for build. 

Generator creating a '../build' directory (relative to current one)
and placing config files there.
Also, it expects that appropriate VM (re)sources can be found simplarily:
  ../platforms
  ../src
 but these settings are just default ones and could be changed in config
 (see senders of #topDir #buildDir and #srcDir )
"
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
		
	output := String new writeStream.
		
	self 
		printHeader;
		project: config executableName;
		"config's topdir, if set, should be absolute"
		set: #topDir toString: (self config topDir ifNil: [ '..']);
		setupDirectories: self.
		
	self message: '${CMAKE_MODULE_PATH}'.
	self set: 'CMAKE_CONFIGURATION_TYPES' to: 'Debug Release'.
	self message: '${CMAKE_CONFIGURATION_TYPES}'.
	
	self includeDirectories: self includeDirs.	
	config standardIncludes do: [:each |
		self includeDirectories: each ].


	self addDefinitions: config compilerFlags.

	config extraVMSettings: self.
	
	self puts: 'add_executable(' , config executableName, ' ', config executableType, ' ' , self sources , ')'.

	"linker flags "
	self puts: 'set_target_properties(', config executableName, ' PROPERTIES LINK_FLAGS "', config linkFlags,'")'.
	
	"maker puts: 'set_property(', 
	maker set: 'MACOSX_PACKAGE_LOCATION' 	maker set: 'RESOURCE' to: '${topdir}/macbuild/resources/ProjectBuilder/Croquet.icns'.
	"

	self processInternalPlugins.	
	self processExternalDependencies.
	
	
	self saveFile.
	
]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> generate: aConfigOrClass [
	
	config := aConfigOrClass isBehavior ifTrue: [ aConfigOrClass new ] ifFalse: [aConfigOrClass].
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
CMakeVMGenerator >> platformName [
	^ config platformName

]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> processExternalDependencies [
	
		config frameworks do: [:each |
		self puts: 'find_library(',each,'_FMWK ', each , ')'.
		self puts: 'target_link_libraries(' , config executableName , ' ${' , each,'_FMWK})'.
	].

]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> processInternalPlugins [

	| libs |
	libs := 
	config internalPlugins collect: [:each | | plugin |
		plugin := Smalltalk at: each.
		plugin generateFor: self internal: true.
		plugin moduleName ].
	
	self puts: 'target_link_libraries(' , config executableName , ' ' ,
		(libs inject: '' into: [:res :ea | res, ' ' , ea ]) , ')'.

	self generateExportsH: libs.

]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> saveFile [
	
	(self buildDir forceNewFileNamed: self outputFileName)
		nextPutAll: (config fixLineEndsOf: output contents);
		close.
]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> setupDirectories: gen [
"
setup  a common directories, relative to the ${topDir}

"
	gen 
		set: #platformsDir toString: (self config platformsDir ifNil: ['${topDir}/platforms']);
		set: #srcDir toString: (self config srcDir ifNil: [ '${topDir}/src']);
		set: #srcPluginsDir toString: '${srcDir}/plugins';
		set: #srcVMDir toString: '${srcDir}/vm';
		set: #platformName toString: self config platformName;
		set: #targetPlatform to: '${platformsDir}/${platformName}';
		set: #crossDir toString: '${platformsDir}/Cross';
		set: #buildDir toString: (self config buildDir ifNil: ['${topDir}/build']);
		set: #platformVMDir toString: '${targetPlatform}/vm'.

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

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> topDir [
	| dir |
	dir := self config topDir ifNil: [ FileDirectory default containingDirectory ].
	dir isString ifTrue: [^ FileDirectory on: ( FileDirectory fullPathForURI: dir) ].
	^ dir
]
