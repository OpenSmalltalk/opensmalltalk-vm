Class {
	#name : #CMakeVMMakerSqueakConfigurationsTest,
	#superclass : #TestCase,
	#category : #'CMakeVMMakerSqueak-Tests'
}

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testBuildDirs [
	"for each builder, make sure all its configurations provide a buildDirectory "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  buildDir isKindOf: FileDirectory)] 

]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testSrcDirs [
	"for each builder, make sure all its configurations provide a buildDirectory "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  srcDir isKindOf: FileDirectory)] 

]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testTopDirs [
	"for each builder, make sure all its configurations provide a buildDirectory "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  topDir isKindOf: FileDirectory)] 

]]








]
