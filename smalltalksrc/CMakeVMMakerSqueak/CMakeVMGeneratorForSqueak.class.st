"
A CMakeVMGeneratorForSqueak overides some CMakeVMGenerator methos for squeak compatibility. 


"
Class {
	#name : #CMakeVMGeneratorForSqueak,
	#superclass : #CMakeGeneratorForSqueak,
	#instVars : [
		'internalPlugins',
		'externalPlugins',
		'config'
	],
	#category : #CMakeVMMakerSqueak
}

{ #category : #'as yet unclassified' }
CMakeVMGeneratorForSqueak class >> generate: aConfigOrClass [  
	^self new 
		generate: aConfigOrClass;
		yourself  
]

{ #category : #'as yet unclassified' }
CMakeVMGeneratorForSqueak >> configurationName [
	^ config class name
]

{ #category : #'code generation' }
CMakeVMGeneratorForSqueak >> generate [
	"overriding CMakeVMGenerator to provide additional method calls"
	| intPlugins extPlugins |
			
	output := String new writeStream.
	config setGlobalOptions: self.
	
	self 
		printHeader;
		project: config executableName.

	config setGlobalOptionsAfterDetermineSystem: self.
	config setupDirectories: self.
	
	self message: '${CMAKE_MODULE_PATH}'.
	self set: 'CMAKE_CONFIGURATION_TYPES' to: 'Release'.

	config preferredIncludes 	do: [ :each | self includeDirectories: each ].
	self includeDirectories: self includeDirs.	
	config standardIncludes 	do: [:each | self includeDirectories: each ].

	"tty. 
	we replace the catchAll compilerFlags with methods that reflect the 'mvm' file used in the gnu-build system
	i.e. oscogvm/build.linux32x86/squeak.cog.v3/build/mvm
	My intent is to make setup of a new configuration easier for somebody coming from GNU-land"

	"self addDefinitions: config compilerFlags."
	config configureFlags do:[:each | self configureFlags: each].
	config cC do:[:each | self cC: each].
	config cXX do:[:each | self cXX: each].
	config lDFlags do:[:each | self lDFlags: each].
	config libs do:[:each | self libs: each].
	self flag:'tty'. "This should be replaced with judicious use of above"
	 self addDefinitions: config cFlags.   "CFLAGS=$OPT -msse2 -D_GNU_SOURCE -D_FILE_OFFSET_BITS=64 -DCOGMTVM=0" 
	self flag:'tty'. "end this should be replaced"

	config extraVMSettings: self.
	
	self puts: 'add_executable(' , config executableName, ' ', config executableType, ' ' , self sources , ')'.
	
	intPlugins := self generatePluginConfigs: config internalPlugins internal: true.
	extPlugins := self generatePluginConfigs: config externalPlugins internal: false.

	self processThirdpartyLibraries.
	
	self processPlugins:  intPlugins, extPlugins.

	config setExtraTargetProperties: self.
	
	self cmd: 'target_link_libraries'
		params: self moduleName , ' ${LINKLIBS}'.

	config postBuildActions: self.
	
	self saveFile.
	self generateBuildScript.
]

{ #category : #'as yet unclassified' }
CMakeVMGeneratorForSqueak >> generate: aConfigOrClass [
	
	config := aConfigOrClass isBehavior ifTrue: [ aConfigOrClass new ] ifFalse: [aConfigOrClass].
	^ self generate
]

{ #category : #'as yet unclassified' }
CMakeVMGeneratorForSqueak >> generatePlugin: aPlugin internal: aBoolean extraRules: aBlock [
	" this method called back from plugin"
	^ CMakePluginGeneratorForSqueak new
		generate: aPlugin for: self internal: aBoolean extraRules: aBlock
]
