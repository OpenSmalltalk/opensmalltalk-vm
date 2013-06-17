Class {
	#name : #CMakeAndroidPluginGenerator,
	#superclass : #CMakePluginGenerator,
	#category : #'CMakeVMMaker-Android'
}

{ #category : #'sources management' }
CMakeAndroidPluginGenerator >> addCrossSources: sources [

	^ self addSources: sources prefixed: '$(pluginCross)/'

]

{ #category : #'gmake commands' }
CMakeAndroidPluginGenerator >> addDefinitions: aString [
	output 
		nextPutAll: ('COG_CFLAGS += ', aString); 
		cr

]

{ #category : #'sources management' }
CMakeAndroidPluginGenerator >> addSources: aFileNames prefixed: aPrefix [

	| names |
	names := aFileNames inject: '' into: [:res :each | res ,  aPrefix, each, ' ' ].
	self append: #LOCAL_SRC_FILES with: names.

]

{ #category : #'gmake commands' }
CMakeAndroidPluginGenerator >> addSubdirectory: aDir [

	^ self include: ('$(buildDir)/', aDir, '/', self outputFileName).

]

{ #category : #'gmake commands' }
CMakeAndroidPluginGenerator >> append: variableName with: aValueString [

	output 
		nextPutAll: (variableName, ' += ', aValueString); 
		cr

]

{ #category : #'gmake commands' }
CMakeAndroidPluginGenerator >> generate [

	| name |
	output := String new writeStream.

	name := plugin moduleName.
	self printHeader.
	
	self 
		set: #pluginName to: name;
		set: #pluginSrc to: '$(srcPluginsDir)/', name;
		set: #pluginCross to: '$(crossDir)/plugins/', name;
		set: #pluginPlatform to: '$(targetPlatform)/plugins/', name.
		
	self addDefinitions: '-DSQUEAK_BUILTIN_PLUGIN'.
	
	self addSources: { name , '.c' } prefixed: '$(pluginSrc)/'.

	self includeDirectories: '-I$(pluginSrc) -I$(pluginCross) -I$(targetPlatform)/plugins/$(pluginName)'.

	self addDefinitions: vmGen config compilerFlags.

	" perform config's configureXYZ: message to apply per-plugin custom rules, if any "
	
	vmGen config configurePlugin: plugin with: self.
	
	extraRules ifNotNil: [ extraRules value: self ].
	
	vmGen config extraPluginSettings: self.
	
	self saveFile.
]

{ #category : #plugins }
CMakeAndroidPluginGenerator >> generatePlugin: aPlugin internal: aBoolean extraRules: aBlock [
	doNotGenerate := false.
	internal := aBoolean.
	plugin := aPlugin.
	vmGen := CMakeAndroidGenerator.
	extraRules := aBlock.
		
	^ self generate
]

{ #category : #'gmake commands' }
CMakeAndroidPluginGenerator >> include: aFileName [
	output 
		nextPutAll: ('include ', aFileName); 
		cr

]

{ #category : #'gmake commands' }
CMakeAndroidPluginGenerator >> includeDirectories: aString [
	output 
		nextPutAll: ('COG_INCLUDE_DIRS += ', aString); 
		cr

]

{ #category : #'sources management' }
CMakeAndroidPluginGenerator >> includeDirs [

	^ '-I$(crossDir)/vm -I$(srcVMDir) -I$(targetPlatform)/vm -I$(buildDir)'.
]

{ #category : #accessing }
CMakeAndroidPluginGenerator >> outputFileName [
	"override this to set the file name to create"
	^ 'cogsources.mk'
]

{ #category : #'submakefile creation' }
CMakeAndroidPluginGenerator >> printHeader [
	
	self puts: '# This is automatically generated file using ', self configurationName, ' on ',
		Date current asString, ' ' , Time current asString.

]

{ #category : #plugins }
CMakeAndroidPluginGenerator >> processInternalPlugins [

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
	
	self generateExportsH: libs.

]

{ #category : #'gmake commands' }
CMakeAndroidPluginGenerator >> set: variableName to: aValueString [

	output 
		nextPutAll: (variableName, ' := ', aValueString); 
		cr

]

{ #category : #accessing }
CMakeAndroidPluginGenerator >> sources [

	self set: #coreSources to: 
		(self append: '$(srcVMDir)/' toAll: config coreSources).
		
	self set: #platformVMSources to: 
		(self append: '$(targetPlatform)/vm/' toAll: config platformSources).
	
	
	self set: #crossVMSources to: 
		(self append: '$(crossDir)/vm/' toAll: config crossSources).
		
	self set: #extraSources to: config extraSources.
	
	^ '$(coreSources) $(crossVMSources) $(platformVMSources) $(extraSources)'
]
