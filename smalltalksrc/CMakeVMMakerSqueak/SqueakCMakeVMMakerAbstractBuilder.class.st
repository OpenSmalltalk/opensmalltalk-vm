"
I am an abstract base class for various CMakeVMMakerSqueak builders.

I am a singleton.
I am a facade to the various Squeak[Platform][WordSize][VM][MemoryManager]Config classes
I provide facilities to query my configurations.
I use the Visitor pattern in collecting information about my configurations.



(HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp) model
   showTopicThat: [:topic | topic title beginsWith: 'Builder']. 


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
SqueakCMakeVMMakerAbstractBuilder class >> allBuildTypes [
	default ifNil:[default:= self new].
	^default allBuildTypes
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder class >> availableBuildConfigurations [
	default ifNil:[default:= self new].
	^default availableBuildConfigurations
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder class >> availableBuildConfigurationsFor: aCategoryName [
	default ifNil:[default:= self new].
	^default availableBuildConfigurationsFor: aCategoryName.
]

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
SqueakCMakeVMMakerAbstractBuilder class >> buildDirectory [
	"buildDirectory is user friendly term. dirBuildPlatform is internal naming convention. "
	^self dirBuildPlatform

]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder class >> configurationsCategory [
	default ifNil:[default:= self new].
	^default configurationsCategory

]

{ #category : #building }
SqueakCMakeVMMakerAbstractBuilder class >> configureA: aSqueakCMakeConfiguration forBuildType: aSymbol [
	"Configure a Configuration for a specific build type. 

	SqueakLinux64x86w32CompatBuilder
		configureA: #Linux64x86w32BitSqueakCogV3SlackwareNoGLConfig forBuildType: #build.itimerheartbeat  "
	default ifNil:[default:= self new].
	^default configureA: aSqueakCMakeConfiguration forBuildType: aSymbol
]

{ #category : #'initialize-release' }
SqueakCMakeVMMakerAbstractBuilder class >> default [
	^default ifNil:[default:= self new]
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder class >> enableMessageTracking: aBoolean [
	default ifNil:[default:= self new].
	^default enableMessageTracking: aBoolean
]

{ #category : #building }
SqueakCMakeVMMakerAbstractBuilder class >> generateByTemplate [
	default ifNil:[default:= self new].
	^default  generateByTemplate
]

{ #category : #building }
SqueakCMakeVMMakerAbstractBuilder class >> generateSources [
	default ifNil:[default:= self new].
	^default  generateSources
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder class >> getInfoForBuilds [
	default ifNil:[default:= self new].
	^default getInfoForBuilds.
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder class >> noBuildTypes [
	default ifNil:[default:= self new].
	^default noBuildTypes
]

{ #category : #'initialize-release' }
SqueakCMakeVMMakerAbstractBuilder class >> reset [
	default:=nil.
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder class >> unAvailableBuildConfigurations [
	default ifNil:[default:= self new].
	^default unAvailableBuildConfigurations
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder class >> unAvailableBuildConfigurationsFor: aCategoryName [
	default ifNil:[default:= self new].
	^default unAvailableBuildConfigurationsFor: aCategoryName.
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> allBuildTypes [
	^buildTypeAndDirectoryInfo keys asOrderedCollection sorted.

]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> availableBuildConfigurations [
	"abstract class pass through for concrete instance"
	^self availableBuildConfigurationsFor: (self configurationsCategory)
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> availableBuildConfigurationsFor: aCategoryName [
	"answer the CMakeVMakerSqueak configurations in a Smalltalk category that are neither Abstract Base Classes nor excluded from builds."



     ^((
	    (self configurationDictionary:aCategoryName) select: [:info| (info isAbstractBaseClass not) &  (info excludeFromBuild not)]
         ) keys asSortedCollection
        ) sort.


]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> availableBuildTypes [
	"abstract class pass through for concrete instance"
	^self availableBuildTypes: (self configurationsCategory)
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> availableBuildTypes: aCategoryName [
	"answer the CMakeVMakerSqueak configurations in a Smalltalk category"
	^((self configurationDictionary:aCategoryName) keys asSortedCollection) sort
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

{ #category : #accessing }
SqueakCMakeVMMakerAbstractBuilder >> buildTypeAndDirectoryInfo [

	^ buildTypeAndDirectoryInfo
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> configurationDictionary: aCategoryName [
	| result info|
	"return a Dictionary of CMakeMakerSqueak-XYZ platform configurations and their associated CMakeVMakerConfigurationInfo "
	result := Dictionary new.
	Smalltalk globals 
		allClassesDo:[:c | (c class category asString withoutQuoting = aCategoryName)  "is there a faster lookup method?"
			ifTrue: [ 
							info := CMakeVMakerConfigurationInfo new.
							info visit: c.
							result at: (c name) put:info]].
	^result


]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> configurationsCategory [
	"Answer the category in which the Builder's configurations reside."
	self subclassResponsibility
]

{ #category : #building }
SqueakCMakeVMMakerAbstractBuilder >> configureA: configSymbol forBuildType: typeSymbol [
	| i |
	self flag:'tty'. "excludeFromBuild returning True does not exit gracefully"
	"Do some sanity checks, then set the internal state of a Configuration for a particular build type. "
	[
	((Smalltalk at: configSymbol)  category) =  (self configurationsCategory)  "verify the class is handled by this concrete builder"
		ifTrue:[	
				config := (Smalltalk at: configSymbol) new.                              "verify this config can handle this build type."
				config excludeFromBuild                                                         "has a developer excluded this build manually?"
					ifTrue:[^self userErrorConfigMarkedAsExcludeFromBuild: configSymbol].   
				i:=config availableBuildTypes indexOf:typeSymbol          
						ifAbsent:[^self userErrorInvalidBuildType: typeSymbol "this config does not support this build type"
										forConfiguration: configSymbol 
										hasTypes: config availableBuildTypes].
				(config configureForBuildType: typeSymbol) value.                             "config configure yourself"
				^self]
		ifFalse:[^self userErrorInvalidTarget: configSymbol]
	] ifError:[^'error configureABuildFor: ''', configSymbol].

	^nil.
	

	
]

{ #category : #building }
SqueakCMakeVMMakerAbstractBuilder >> enableMessageTracking: aBoolean [
	(config isKindOf: CPlatformConfig)
		ifTrue:[config enabledebugmessages: aBoolean]
		
]

{ #category : #building }
SqueakCMakeVMMakerAbstractBuilder >> generateByTemplate [
	self flag:'tty'. "If we ever script builds, this inform must by bypassed"
	(config isKindOf: CPlatformConfigForSqueak)
		ifTrue:[
			(config excludeFromBuild)
				ifTrue:[self inform: '', config class, ' >>"excludeFromBuild" answers #true. Most likely because it is under development']
				ifFalse: [config generateByTemplate]]
		
]

{ #category : #building }
SqueakCMakeVMMakerAbstractBuilder >> generateSources [
	self flag: 'tty'. "This used to work, but it looks like CPlaformConfig>>generateSources breaks at 'maker cogitClass: cg'"
	self error:'Pharo CPlatformConfig is broken. Will fix later'.
	(config isKindOf: CPlatformConfig)
		ifTrue:[config generateSources]
		
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
	self flag:'tty. why is this here? its from pharo...'.
	Cogit allSubclassesDo: [ :each | each initializeWithOptions: (VMMaker new instVarNamed: 'optionsDictionary') ].
"	scriptMode:= false. On the chance that we ever use scripts to invoke builders, here is  a flag to bypass user interaction/informs"
	self initializeBuildTypeAndDirectoryInfo.

	
]

{ #category : #initialization }
SqueakCMakeVMMakerAbstractBuilder >> initializeBuildTypeAndDirectoryInfo [
	"A dictionary of build types and the name of the directory they are stored in"
	buildTypeAndDirectoryInfo := Dictionary new.
	buildTypeAndDirectoryInfo 
			at: #build put: 'build';
			at: #buildAssert put:'build.assert';
		      at: #buildAssertITimerHeartbeat put: 'build.assert.itimerheartbeat';
                  at: #buildDebug put: 'build.debug';                                                                     
			at: #buildDebugITimerHeartbeat put: 'build.debug.itimerheartbeat';
			at: #buildITimerHeartbeat put: 'build.itimerheartbeat';
			at: #buildMultiThreaded put: 'build.multithreaded';
			at: #buildMultiThreadedAssert put: 'build.multithreaded.assert';
			at: #buildMultiThreadedDebug put: 'build.multithreaded.debug';
			at: #buildNone put: 'build.should.not.happen'.

]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> noBuildTypes [
	^#()
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> unAvailableBuildConfigurations [
	"abstract class pass through for concrete instance"
	^self unAvailableBuildConfigurationsFor: (self configurationsCategory)
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> unAvailableBuildConfigurationsFor: aCategoryName [
	"answer the CMakeVMakerSqueak configurations in a Smalltalk category that are neither Abstract Base Classes nor excluded from builds."



     ^((
	    (self configurationDictionary:aCategoryName) select: [:info| (info isAbstractBaseClass) |  (info excludeFromBuild)]
         ) keys asSortedCollection
        ) sort.


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
SqueakCMakeVMMakerAbstractBuilder >> userErrorNoExecutable: aSymbol [
	^aSymbol asString, ' is not meant to be an executable. Read my class comment'
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> userErrorNoSource: aSymbol [
	^'I cannot find the source directory for ', aSymbol asString.
]
