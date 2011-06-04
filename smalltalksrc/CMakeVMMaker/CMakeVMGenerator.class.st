"
I am generating a cmake configuration file (CMakeLists.txt)
for building a Squeak Virtual Machine.

Usage: 

CMakeVMGenerator new generate: CogMacOSConfig

or

CMakeVMGenerator new generate: (CogMacOSConfig new setOption: ... ; yourself)

you can provide any valid configuration instead of CogMacOSConfig for build. 

Generator creating a '../build' directory (relative to current one)
and placing config files there.
Also, it expects that appropriate VM (re)sources can be found simplarily:
  ../platforms
  ../src
 but these settings are just default ones and could be changed in config
 (see senders of #topDir #buildDir and #srcDir )

Generator and cmake configs are designed so, that any file-system operations are performed in
<build> directory.
So, if you want to build multiple VMs , using same generated sources, but different configs, you can simply
use different build directories.


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

{ #category : #'code generation' }
CMakeVMGenerator class >> generate: aConfigOrClass [  
	^self new 
		generate: aConfigOrClass;
		yourself  
]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> append: aString toAll: list [
	"flatten the list, adding prefix for each element"
	^ list inject: '' into: [:result :each | result, ' ', aString, each ].
]

{ #category : #accessing }
CMakeVMGenerator >> buildDir [
	^ config buildDir
]

{ #category : #accessing }
CMakeVMGenerator >> config [
	^ config
]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> configurationName [
	^ config class name
]

{ #category : #accessing }
CMakeVMGenerator >> executableName [
	^ 'Squeak'
]

{ #category : #'code generation' }
CMakeVMGenerator >> generate [
		
	output := String new writeStream.
		
	self 
		printHeader;
		project: config executableName.

	config setupDirectories: self.
	self include: 'directories.cmake'.
		
	self message: '${CMAKE_MODULE_PATH}'.
	self set: 'CMAKE_CONFIGURATION_TYPES' to: 'Release'.

	config preferredIncludes 
		do: [ :each | self includeDirectories: each ].
	self includeDirectories: self includeDirs.	
	config standardIncludes 
		do: [:each | self includeDirectories: each ].

	self addDefinitions: config compilerFlags.

	config extraVMSettings: self.
	
	self puts: 'add_executable(' , config executableName, ' ', config executableType, ' ' , self sources , ')'.
		
	self processInternalPlugins.	
	config setExtraTargetProperties: self.
	
	self cmd: 'target_link_libraries'
		params: self moduleName , ' ${LINKLIBS}'.
		
	self processExternalPlugins.
	
	self saveFile.
	
]

{ #category : #'code generation' }
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

{ #category : #accessing }
CMakeVMGenerator >> moduleName [ 
	^config executableName
]

{ #category : #accessing }
CMakeVMGenerator >> platformName [
	^ config platformName

]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> processExternalPlugins [

	config externalPlugins do: [:each | | plugin gen |
		plugin := Smalltalk at: each.
		gen := plugin generateFor: self internal: false.
		gen doNotGenerate ifFalse: [
			self addSubdirectory: plugin moduleName.
			]
	].
	

]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> processInternalPlugins [

	| libs |
	libs := OrderedCollection new.

	config internalPlugins collect: [:each | | plugin gen |
		plugin := Smalltalk at: each.
		gen := plugin generateFor: self internal: true.
		gen doNotGenerate ifFalse: [
			libs add: plugin moduleName.
			self addSubdirectory: plugin moduleName.
			 ].
		].
	
	self cmd: 'target_link_libraries' params:  config executableName , ' ' ,
		(libs inject: '' into: [:res :ea | res, ' ' , ea ]) .

	self generateExportsH: libs.

]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> saveFile [
	
	config write: output contents toFile: (self outputFileName).
	
]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> setupMacros: gen [
	self config cMakeMacros
		ifNotNil: [ :macros | gen puts: macros ]
]

{ #category : #accessing }
CMakeVMGenerator >> sources [

	self set: #coreSources to: 
		(self append: '${srcVMDir}/' toAll: config coreSources).
		
	self set: #platformVMSources to: 
		(self append: '${targetPlatform}/vm/' toAll: config platformSources).
	
	
	self set: #crossVMSources to: 
		(self append: '${crossDir}/vm/' toAll: config crossSources).
		
	self set: #extraSources to: config extraSources.
	
	^ '${coreSources} ${crossVMSources} ${platformVMSources} ${extraSources}'
]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> targetPropertyAt: aPropName put: aValue [
	"set target's properties"
	
	self cmd: 'set_property' params: 'TARGET ', config executableName , 
	' PROPERTY ', aPropName , ' ' , aValue.

]

{ #category : #'as yet unclassified' }
CMakeVMGenerator >> targetPropertyAt: aPropName qput: aValue [
	"set target's properties, put value in quotes"
	
	^ self targetPropertyAt: aPropName put: (aValue copyReplaceAll: '"' with: '\"').
]

{ #category : #accessing }
CMakeVMGenerator >> topDir [
	| dir |
	dir := self config topDir ifNil: [ FileDirectory default containingDirectory ].
	dir isString ifTrue: [^ FileDirectory on: ( FileDirectory fullPathForURI: dir) ].
	^ dir
]
