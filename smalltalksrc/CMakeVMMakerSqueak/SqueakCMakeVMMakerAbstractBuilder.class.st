"
I am an abstract base class for various CMakeVMMakerSqueak builders.

most of my methods are on class side.

I am a facade to the various Squeak[Platform][WordSize][VM][MemoryManager]Config classes that provide all the functionality.

Think of me as lipstick on a pig.

oink!


I also act as a repository of common information for the various configurations.



"
Class {
	#name : #SqueakCMakeVMMakerAbstractBuilder,
	#superclass : #Object,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #'as yet unclassified' }
SqueakCMakeVMMakerAbstractBuilder class >> allBuildConfigurations [
	^#(#assert #assertWithHeartbeatTimer #debug #debugWithHeartbeatTimer #debugMultiThreadedFFI #release #releaseHeartbeatTimer #releaseMultiThreadedFFI)
]

{ #category : #'as yet unclassified' }
SqueakCMakeVMMakerAbstractBuilder class >> availableBuildTypesForTarget: aSymbol [
	self subclassResponsibility.



]

{ #category : #'as yet unclassified' }
SqueakCMakeVMMakerAbstractBuilder class >> availableBuildsTypesForTarget: aSymbol inCategory: aCategoryName [
	|d |
	d:=(self configurationDictionary:aCategoryName) at: aSymbol ifAbsent:[^SqueakCMakeVMMakerAbstractBuilder noBuildConfigurations].
	^d value




]

{ #category : #'as yet unclassified' }
SqueakCMakeVMMakerAbstractBuilder class >> availableTargets: aCategoryName [

	^((self configurationDictionary:aCategoryName) keys asSortedCollection) sort


]

{ #category : #'as yet unclassified' }
SqueakCMakeVMMakerAbstractBuilder class >> configurationDictionary: aCategoryName [
	"return a Dictionary of CMakeMakerSqueak-XYZ platform configurations and their associated available builds"
	| result |
	result := Dictionary new.
	Smalltalk globals 
		allClassesDo:[:c | (c class category asString withoutQuoting = aCategoryName)
			ifTrue: [ result at: (c name) put:[c availableBuilds].]].
	^result


]

{ #category : #'as yet unclassified' }
SqueakCMakeVMMakerAbstractBuilder class >> configurationsCategory [
	"Answer the category in which the Builder's configurations reside."
	self subclassResponsibility
]

{ #category : #'as yet unclassified' }
SqueakCMakeVMMakerAbstractBuilder class >> noBuildConfigurations [
	^#(#noBuildsImplementedForThisConfiguration)
]

{ #category : #'as yet unclassified' }
SqueakCMakeVMMakerAbstractBuilder class >> userErrorInvalidTarget: aSymbol [
	^'I cannot build for this target', aSymbol asString.
]

{ #category : #initialization }
SqueakCMakeVMMakerAbstractBuilder >> initialize [

	"a stupid temporary hack to workaround initialization problems"

	Cogit allSubclassesDo: [ :each | each initializeWithOptions: (VMMaker new instVarNamed: 'optionsDictionary') ]
]
