"
I am an abstract base class for various CMakeVMMakerSqueak builders.

I am a singleton.
I am a facade to the various Squeak[Platform][WordSize][VM][MemoryManager]Config classes
I provide facilities to query my configurations.
I use the Visitor pattern in collecting information about my configurations.

Usage: 
-------------------------Using CMakeVMMakerSqueak-------------------------
The easiest way to use this is to utilize one of the concrete Builders in category CMakeVMMakerSqueak-Builder.

With a builder, you can query it for information and then invoke it to generate configurations and or source.

Printing or inspecting the following lines will give you a flavor of a typical work-flow.

-------------Buildable/non-buildable configurations---------

SqueakCMakeVMMakerAbstractBuilder showExcludeFromBuild:false    ""buildable configurations""
SqueakCMakeVMMakerAbstractBuilder showExcludeFromBuild:true.    ""edit that configs 'excludeFromBuild' method to change""
SqueakCMakeVMMakerAbstractBuilder availableBuildTypes

-------------------------Querying Builders and CMake Configurations---------------

SqueakLinux32X86Builder configurationsCategory 
SqueakLinux32X86Builder buildDirectory 
SqueakLinux32X86Builder availableBuilds	 
SqueakLinux32X86Builder availableBuildTypesFor:(SqueakLinux32X86Builder availableBuilds at:1)
SqueakLinux32X86Builder availableBuildTypesFor: #Linux32x86SqueakStackSpurConfig
SqueakLinux32X86Builder availableBuildTypesFor: #Linux32x86SqueakStackV3Config
SqueakLinux32X86Builder sourceDirectoryFor:(SqueakLinux32X86Builder availableBuilds at:1)

-------------------------Generating CMake files and/or Source code-------------------------

SqueakLinux32X86Builder 
	configureABuildFor: #Linux32x86SqueakCogV3Config withBuildType: #debug
	generate   ""generate only CMake config files""

SqueakLinux32X86Builder 
	configureABuildFor: #Linux32x86SqueakCogV3Config withBuildType: #debug
	generateWithSources  ""generate configurations and invoke VMMaker to generate source code""

-------------------------Compiling Instructions-------------------------
open a terminal and go to the configurations build directory for that configuration. (SqueakLinux32X86Builder buildDirectory)
change into the build type subdirectory (build, build.assert, build.debug...etc)
source build.sh will run the build process
executable is placed in  /products folder.  (SqueakLinux32X86Builder ouputDirectory)


"
Class {
	#name : #SqueakCMakeVMMakerAbstractBuilder,
	#superclass : #Object,
	#instVars : [
		'buildTypeAndDirectoryInfo',
		'config'
	],
	#classInstVars : [
		'default'
	],
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder class >> availableBuildTypes [
	default ifNil:[default:= self new].
	^default availableBuildTypes.
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder class >> availableBuildTypesFor: aSymbol [
	default ifNil:[default:= self new].
	^default availableBuildTypesFor: aSymbol
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder class >> availableBuilds [
	default ifNil:[default:= self new].
	^default availableBuilds
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder class >> buildDirectory [
	"buildDirectory is user friendly term. dirBuildPlatform is internal naming convention. "
	^self dirBuildPlatform

]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder class >> buildTypeDirectoriesFor: aSymbol [
	default ifNil:[default:= self new].
	^default buildTypeDirectoriesFor: aSymbol
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder class >> configurationsCategory [
	default ifNil:[default:= self new].
	^default configurationsCategory

]

{ #category : #building }
SqueakCMakeVMMakerAbstractBuilder class >> configureABuildFor: aSqueakCMakeConfiguration withBuildType: aSymbol [
	default ifNil:[default:= self new].
	^default configureABuildFor: aSqueakCMakeConfiguration withBuildType: aSymbol
]

{ #category : #'initialize-release' }
SqueakCMakeVMMakerAbstractBuilder class >> default [
	^default ifNil:[default:= self new]
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder class >> dirBuildPlatform [
	default ifNil:[default:= self new].
	^default dirBuildPlatform
]

{ #category : #building }
SqueakCMakeVMMakerAbstractBuilder class >> generate [
	default ifNil:[default:= self new].
	^default  generate
]

{ #category : #building }
SqueakCMakeVMMakerAbstractBuilder class >> generateWithSource [
	default ifNil:[default:= self new].
	^default  generateWithSource
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder class >> showExcludeFromBuild: aBoolean [
	default ifNil:[default:= self new].
	^default showExcludeFromBuild: aBoolean
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder class >> sourceDirectoryFor: aSymbol [
	default ifNil:[default:= self new].
	^default sourceDirectoryFor: aSymbol
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> allBuildConfigurations [
	^buildTypeAndDirectoryInfo keys asOrderedCollection sorted.

]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> availableBuildTypes [
	^self buildTypeAndDirectoryInfo keys asSortedCollection

]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> availableBuildTypesFor: aSymbol [
	"answer a build type. somthing like #assert, #debug, #release. Each configuration is in charge of letting us know what it does"
	[
	((Smalltalk at: aSymbol)  category) =  (self configurationsCategory)  "verify the class is handled by this concrete builder"
		ifTrue:[	^self availableBuildTypesFor: aSymbol inCategory: ((Smalltalk at: aSymbol)  category).]  "if so, go get its info"
		ifFalse:[^self userErrorInvalidTarget: aSymbol]
	] ifError:[^'BuildTypeForTarget: ''', aSymbol , ''' not found' ].
	^nil.
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> availableBuildTypesFor: aSymbol inCategory: aCategoryName [
	|d |
	"extract the CMakeVMakerConfigurationInfo object for a configuration and return the availableBuildTypes ."
	d:=(self configurationDictionary:aCategoryName) at: aSymbol ifAbsent:[^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations].
	^d availableBuildTypes




]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> availableBuilds [
	"abstract class pass through for concrete instance"
	^self availableBuilds: (self configurationsCategory)
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> availableBuilds: aCategoryName [
	"answer the CMakeVMakerSqueak configurations in a Smalltalk category"
	^((self configurationDictionary:aCategoryName) keys asSortedCollection) sort


]

{ #category : #accessing }
SqueakCMakeVMMakerAbstractBuilder >> buildTypeAndDirectoryInfo [

	^ buildTypeAndDirectoryInfo
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> buildTypeDirectoriesFor: aSymbol [
	"answer a subset of buildTypeAndDirectoryInfo based on the buildTypes the configuration supports   "
	[
	((Smalltalk at: aSymbol)  category) =  (self configurationsCategory)  "verify the class is handled by this concrete builder"
		ifTrue:[	^self buildTypeDirectoriesFor: aSymbol inCategory: ((Smalltalk at: aSymbol)  category).]  "if so, go get its info"
		ifFalse:[^self userErrorInvalidTarget: aSymbol]
	] ifError:[^'BuildTypeDirectoriesFor: ''', aSymbol , ''' not found' ].
	^nil.
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> buildTypeDirectoriesFor: aSymbol inCategory: aCategoryName [
	|d |
	"extract the CMakeVMakerConfigurationInfo object for a configuration and return the availableBuildTypes ."
	d:=(self configurationDictionary:aCategoryName) at: aSymbol ifAbsent:[^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations].
	^d availableBuildTypes




]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> configurationDictionary: aCategoryName [
	| result info|
	self flag:'tty'. "building this on the fly is slow. Should I cache/lazy initialize?"

	"return a Dictionary of CMakeMakerSqueak-XYZ platform configurations and their associated CMakeVMakerConfigurationInfo "

	result := Dictionary new.
	Smalltalk globals 
		allClassesDo:[:c | (c class category asString withoutQuoting = aCategoryName)    "is there a faster lookup method?"
			ifTrue: [ 
				info := CMakeVMakerConfigurationInfo new.
				info visit: c.
				result at: (c name) put:info.]].
	^result


]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> configurationsCategory [
	"Answer the category in which the Builder's configurations reside."
	self subclassResponsibility
]

{ #category : #building }
SqueakCMakeVMMakerAbstractBuilder >> configureABuildFor: configSymbol withBuildType: typeSymbol [
	| i |
	"Do some sanity checks, then set the internal state of a Configuration for a particular build type. "
	[
	((Smalltalk at: configSymbol)  category) =  (self configurationsCategory)  "verify the class is handled by this concrete builder"
		ifTrue:[	
				config := (Smalltalk at: configSymbol) new.                              "verify this config can handle this build type."
				config excludeFromBuild                                                         "has a developer excluded this build manually?"
					ifTrue:[^self userErrorConfigMarkedAsExcludeFromBuild: configSymbol].
				i:=config availableBuilds indexOf:typeSymbol                                    
						ifAbsent:[^self userErrorInvalidBuildType: typeSymbol "this config does not support this build type"
										forConfiguration: configSymbol 
										hasTypes: config availableBuilds].
				config configureForBuildType: typeSymbol.                             "config configure yourself"
				^self]
		ifFalse:[^self userErrorInvalidTarget: configSymbol]
	] ifError:[^'error configureABuildFor: ''', configSymbol].

	^nil.
	

	
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> dirBuildPlatform [
	"Answer the root directory for this configuration's build that contains build, build.assert...etc directories. example:  cmake_build.linux32x86."
	^self dirBuildPlatform:(self configurationsCategory)
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> dirBuildPlatform: aCategoryName [
	|info|
	"All the configurations in a category share the same build platform."
	info:=(self configurationDictionary:aCategoryName) at: ((self configurationDictionary:aCategoryName) keys at:1).  "i.e. aDictionary at:1"
	^info dirBuildPlatform
	
	

]

{ #category : #building }
SqueakCMakeVMMakerAbstractBuilder >> generate [
	(config isKindOf: CPlatformConfig)
		ifTrue:[config generate]
		
]

{ #category : #building }
SqueakCMakeVMMakerAbstractBuilder >> generateWithSource [
	(config isKindOf: CPlatformConfig)
		ifTrue:[config generateWithSource]
		
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> getInfoForBuild: aSymbol [
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> getInfoForBuilds [
	| result|
	"return a Dictionary of CMakeMakerSqueak-XYZ platform configurations and their associated CMakeVMakerConfigurationInfo "
	result := Dictionary new.
	self class allSubclassesDo:[:c | |configurationsCategory |
				configurationsCategory := c default configurationsCategory.
				result at:(configurationsCategory asSymbol)  put: (self configurationDictionary: configurationsCategory).
	].
.	^result


]

{ #category : #initialization }
SqueakCMakeVMMakerAbstractBuilder >> initialize [
	"a stupid <cough>temporary</cough> hack to workaround initialization problems"
	Cogit allSubclassesDo: [ :each | each initializeWithOptions: (VMMaker new instVarNamed: 'optionsDictionary') ].

	self initializeBuildTypeAndDirectoryInfo.

	
]

{ #category : #initialization }
SqueakCMakeVMMakerAbstractBuilder >> initializeBuildTypeAndDirectoryInfo [
	"A dictionary of build types and the name of the directory they are stored in"
	buildTypeAndDirectoryInfo := Dictionary new.
	buildTypeAndDirectoryInfo 
			at: #assert put:'build.assert';
		      at: #assertWithHeartbeatTimer put: 'build.assert.itimerheartbeat';
                  at:#debug put: 'build.debug';
			at: #debugWithHeartbeatTimer put: 'build.debug.itimerheartbeat';
			at: #debugMultiThreadedFFI put: 'build.debug.multithreaded';
			at: #release put: 'build';
			at: #releaseHeartbeatTimer put: 'build.itimerheartbeat';
			at: #releaseMultiThreadedFFI put: 'build.multithreaded'.
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> noBuildConfigurations [
	^#(#noBuildsImplementedForThisConfiguration)
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> showExcludeFromBuild: aBoolean [
	|dictionary result msg s|
	"return all configurations that where the  excludeFromBuid matches aBoolean. excludeFromBuild is manually set by the developer"	
	aBoolean
		ifTrue:[msg:= 'available configurations are: '. s:='']
		ifFalse:[msg:= 'disabled configurations are: '. s:= ' edit method excludeFromBuild to toggle'].
	result := OrderedCollection new.
	dictionary:=self getInfoForBuilds.
	dictionary do:[:dict | 
			dict keysAndValuesDo: [:config :configinfo | 
				aBoolean == (configinfo excludeFromBuild) 
					ifTrue:[ result add:  config]]].
	^'Configurations where excludeFromBuild ==', aBoolean ,'->',result, s.
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> sourceDirectoryFor: aSymbol [
	"answer a subset of buildTypeAndDirectoryInfo based on the buildTypes the configuration supports   "
	[
	((Smalltalk at: aSymbol)  category) =  (self configurationsCategory)  "verify the class is handled by this concrete builder"
		ifTrue:[	^self sourceDirectoryFor: aSymbol inCategory: ((Smalltalk at: aSymbol)  category).]  "if so, go get its info"
		ifFalse:[^self userErrorInvalidTarget: aSymbol]
	] ifError:[^'sourceDirectoryFor: ''', aSymbol , ''' not found' ].
	^nil.
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> sourceDirectoryFor: aSymbol inCategory: aCategoryName [
	|info |
	"extract the CMakeVMakerConfigurationInfo object for a configuration and return the sourceDirectory ."
	info:=(self configurationDictionary:aCategoryName) at: aSymbol ifAbsent:[^SqueakCMakeVMMakerAbstractBuilder default userErrorNoSource:aSymbol].
	^info dirSource




]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> userErrorConfigMarkedAsExcludeFromBuild: aSymbol [
	^'Class ', aSymbol ,'has been manually excluded from building. edit method ''excludeFromBuild'' to change this' .
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> userErrorInvalidBuildType: typeSymbol forConfiguration: configSymbol hasTypes: anOrderedCollection [
	^'The configuration: ', configSymbol, 'does not support buildType ', typeSymbol, '. supported types are:', anOrderedCollection

]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> userErrorInvalidTarget: aSymbol [
	^'I cannot build for this target', aSymbol asString.
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> userErrorNoSource: aSymbol [
	^'I cannot find the source directory for ', aSymbol asString.
]
