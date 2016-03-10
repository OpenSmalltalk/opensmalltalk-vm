"
This class inherits from CMakeGenerator and provides the same generation facilities as its parent, but output is more adjusted to the Android NDK requirements.
"
Class {
	#name : #CMakeAndroidGenerator,
	#superclass : #CMakeVMGenerator,
	#category : #'CMakeVMMaker-Android'
}

{ #category : #'gmake commands' }
CMakeAndroidGenerator >> addDefinitions: aString [
	output 
		nextPutAll: ('COG_CFLAGS += ', aString); 
		cr

]

{ #category : #'gmake commands' }
CMakeAndroidGenerator >> addSubdirectory: aDir [

	^ self include: ('$(buildDir)/', aDir, '/', self outputFileName).

]

{ #category : #'gmake commands' }
CMakeAndroidGenerator >> append: variableName with: aValueString [

	output 
		nextPutAll: (variableName, ' += ', aValueString); 
		cr

]

{ #category : #'code generation' }
CMakeAndroidGenerator >> generate [

	"override this method to produce gmake syntax"
	
	output := String new writeStream.
		
	self printHeader.

	config setupDirectories: self.
		
	config preferredIncludes 
		do: [ :each | self includeDirectories: each ].
	self includeDirectories: self includeDirs.	
	config standardIncludes 
		do: [:each | self includeDirectories: each ].

	self addDefinitions: config compilerFlags.

	config extraVMSettings: self.
	
	self append: #LOCAL_SRC_FILES with: self sources.
		
	self processInternalPlugins.	
	config setExtraTargetProperties: self.
	
	self saveFile.
	
]

{ #category : #plugins }
CMakeAndroidGenerator >> generatePlugin: aPlugin internal: aBoolean extraRules: aBlock [
	" this method called back from plugin"
	^ CMakeAndroidPluginGenerator new
		generate: aPlugin for: self internal: aBoolean extraRules: aBlock
]

{ #category : #'gmake commands' }
CMakeAndroidGenerator >> include: aFileName [
	output 
		nextPutAll: ('include ', aFileName); 
		cr

]

{ #category : #'gmake commands' }
CMakeAndroidGenerator >> includeDirectories: aString [
	output 
		nextPutAll: ('COG_INCLUDE_DIRS += ', aString); 
		cr

]

{ #category : #'sources management' }
CMakeAndroidGenerator >> includeDirs [

	^ '-I$(crossDir)/vm -I$(srcVMDir) -I$(targetPlatform)/vm -I$(buildDir)'.
]

{ #category : #accessing }
CMakeAndroidGenerator >> outputFileName [
	"override this to set the file name to create"
	^ 'cogsources.mk'
]

{ #category : #'submakefile creation' }
CMakeAndroidGenerator >> printHeader [
	
	self puts: '# This is automatically generated file using ', self configurationName, ' on ',
		Date current asString, ' ' , Time current asString.

]

{ #category : #plugins }
CMakeAndroidGenerator >> processInternalPlugins [

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
CMakeAndroidGenerator >> set: variableName to: aValueString [

	output 
		nextPutAll: (variableName, ' := ', aValueString); 
		cr

]

{ #category : #accessing }
CMakeAndroidGenerator >> sources [

	self set: #coreSources to: 
		(self append: '$(srcVMDir)/' toAll: config coreSources).
		
	self set: #platformVMSources to: 
		(self append: '$(targetPlatform)/vm/' toAll: config platformSources).
	
	
	self set: #crossVMSources to: 
		(self append: '$(crossDir)/vm/' toAll: config crossSources).
		
	self set: #extraSources to: config extraSources.
	
	^ '$(coreSources) $(crossVMSources) $(platformVMSources) $(extraSources)'
]
