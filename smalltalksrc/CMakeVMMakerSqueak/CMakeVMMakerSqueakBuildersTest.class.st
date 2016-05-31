"
I test CMakeVMMakerSqueak Builder classes.
"
Class {
	#name : #CMakeVMMakerSqueakBuildersTest,
	#superclass : #TestCase,
	#category : #'CMakeVMMakerSqueak-Tests'
}

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakBuildersTest >> testAllAndNoneBuildTypes [
	self assert: (SqueakCMakeVMMakerAbstractBuilder  allBuildTypes isKindOf: Collection).
	self assert: (SqueakCMakeVMMakerAbstractBuilder  allBuildTypes size > 0).
	self assert: (SqueakCMakeVMMakerAbstractBuilder  noBuildTypes isEmpty).
	
]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakBuildersTest >> testAvailableBuildConfigurations [
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | 
				self assert: (builder availableBuildConfigurations isKindOf:Collection)]


]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakBuildersTest >> testAvailableBuildTypes [
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | 
			self assert:(builder availableBuildTypes isKindOf: Collection)]
	
]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakBuildersTest >> testConfigurationsCategory [
	|oc|
	"ensure builders have a category with configs in it and make sure it is unique. This does not guarantee it is correct, but it helps"
	oc:= OrderedCollection new.
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:c | 
			self assert: (c default configurationsCategory isString).
			oc addLast: c.
			self assert: ( (oc occurrencesOf: c) = 1)]	
]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakBuildersTest >> testConfigureABuilderForBuildType [
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | 
				builder availableBuildConfigurations do:[:configuration | |availablebuildtypes|
					availablebuildtypes:= builder availableBuildTypesFor: configuration.
					self assert:(availablebuildtypes isKindOf: Collection).
					availablebuildtypes do:[:buildtype | 
						self shouldnt: [builder configureA: configuration forBuildType: buildtype] raise: Error]]]


]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakBuildersTest >> testGetInfoForBuilds [
	|dict |
	dict:=SqueakCMakeVMMakerAbstractBuilder getInfoForBuilds.
	self assert: (dict isKindOf:Dictionary).
	dict valuesDo:[:anotherDict | 
				self assert:(anotherDict isKindOf: Dictionary).
				anotherDict valuesDo:[:info |
					self assert:( info isKindOf: CMakeVMakerConfigurationInfo)]]


]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakBuildersTest >> testUnAvailableBuildConfigurations [
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | 
				self assert: (builder unAvailableBuildConfigurations isKindOf:Collection)]


]
