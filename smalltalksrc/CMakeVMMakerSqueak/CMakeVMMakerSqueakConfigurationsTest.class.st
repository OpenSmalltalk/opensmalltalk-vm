Class {
	#name : #CMakeVMMakerSqueakConfigurationsTest,
	#superclass : #TestCase,
	#category : #'CMakeVMMakerSqueak-Tests'
}

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testBuildDirName [
	"for each builder, make sure all its configurations provide a buildDirectory "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  buildDirName isString)] 

]]








]

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
CMakeVMMakerSqueakConfigurationsTest >> testDefaultExternalPlugins [
	"for each builder, make sure all its configurations provide a buildDirectory "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  defaultExternalPlugins isArray)] 

]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testDefaultInternalPlugins [
	"for each builder, make sure all its configurations provide a buildDirectory "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  defaultInternalPlugins isArray)] 

]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testExectuableName [
	"for each builder, make sure all its configurations provide a buildDirectory "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  executableName isString)] 

]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testExternalPlugins [
	"for each builder, make sure all its configurations provide a buildDirectory "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  externalPlugins isArray)] 

]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testInternalPlugins [
	"for each builder, make sure all its configurations provide a buildDirectory "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  internalPlugins isArray)] 

]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testOutputDir [
	"for each builder, make sure all its configurations provide a buildDirectory "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  outputDir isKindOf: FileDirectory)] 

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
