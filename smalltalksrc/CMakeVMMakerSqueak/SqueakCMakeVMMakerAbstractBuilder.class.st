"
I am an abstract base class for various CMakeVMMakerSqueak builders.

I am a singleton.
I am a facade to the various Squeak[Platform][WordSize][VM][MemoryManager]Config classes that provide all the functionality.
I also act as a repository of common information for the various configurations.
Think of me as lipstick on a pig.


Each one of my subclasses manages the CMakeVMMakerSqueak configurations -------->in a specific category<-----. 
Win32Builder handles the Win32 Smalltalk Category, IOSBuilder handles the Smalltalk IOS category.
Yes, its a limitation of the design, but so it goes.











"
Class {
	#name : #SqueakCMakeVMMakerAbstractBuilder,
	#superclass : #Object,
	#instVars : [
		'buildTypeAndDirectoryInfo'
	],
	#classInstVars : [
		'default'
	],
	#category : #'CMakeVMMakerSqueak-Builder'
}

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

{ #category : #'initialize-release' }
SqueakCMakeVMMakerAbstractBuilder class >> default [
	^default ifNil:[default:= self new]
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder class >> dirBuildPlatform [
	default ifNil:[default:= self new].
	^default dirBuildPlatform
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
SqueakCMakeVMMakerAbstractBuilder >> userErrorInvalidTarget: aSymbol [
	^'I cannot build for this target', aSymbol asString.
]

{ #category : #queries }
SqueakCMakeVMMakerAbstractBuilder >> userErrorNoSource: aSymbol [
	^'I cannot find the source directory for ', aSymbol asString.
]
