"
I test CMakeVMMakerSqueak Builder classes.
"
Class {
	#name : #CMakeVMMakerSqueakBuildersTest,
	#superclass : #TestCase,
	#category : #'CMakeVMMakerSqueak-Tests'
}

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakBuildersTest >> testAvailableBuilds [
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:c | 
			self assert: (c default availableBuilds size > 0).]	
]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakBuildersTest >> testBuildConfigurations [
	self assert: (SqueakCMakeVMMakerAbstractBuilder default allBuildConfigurations size > 0).
	self assert: (SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations size > 0).
	
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
