Class {
	#name : #CMakeVMMakerSqueakConfigurationsTest,
	#superclass : #TestCase,
	#category : #'CMakeVMMakerSqueak-Tests'
}

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testBuildDirName [
	"for each builder, make sure all its configurations provide a build directory name "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							o excludeFromBuild not                                                     
								ifTrue:[self assert:(o  buildDirName isString)]]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testBuildDirs [
	"for each builder, make sure all its configurations provides availbale build directories "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							o excludeFromBuild not
								ifTrue:[self assert:(o  buildDir isKindOf: FileDirectory)]]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testCogitClass [
	"for each builder that does not exclude itself from builds, make sure it returns cogitClass "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							o excludeFromBuild not                                                     
							 	ifTrue:[self assert:(o  cogitClass inheritsFrom: Cogit)]]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testDefaultExternalPlugins [
	"for each builder, make sure all its configurations provides defaultExternalPlugins"
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  defaultExternalPlugins isArray)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testDefaultInternalPlugins [
	"for each builder, make sure all its configurations provides defaultInternalPlugins"
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  defaultInternalPlugins isArray)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testDirSource [
	"for each builder, make sure all its configurations provide a dirSource "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  dirSource isString)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testExcludeFromBuild [
	"for each builder, make sure all its includes or excludes itself from a build "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(((o  excludeFromBuild) == true) | ((o  excludeFromBuild) == false))]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testExectuableName [
	"for each builder, make sure all its configurations provide an executableName "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							(o excludeFromBuild not)
								ifTrue:[self assert:(o  executableName isString)]]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testExternalPlugins [
	"for each builder, make sure all its configurations provides externalePlugins "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  externalPlugins isArray)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testInternalPlugins [
	"for each builder, make sure all its configurations provides internalPlutgins "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  internalPlugins isArray)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testInterpreterClass [
	"for each builder that does not exclude itself from builds, make sure it returns an InterpreterClass "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							o excludeFromBuild not                                                     
							 	ifTrue:[
										self assert:(o  interpreterClass inheritsFrom: InterpreterPrimitives).
										self assert:(o  interpreterClassBuild inheritsFrom: InterpreterPrimitives).
										self assert:(o  interpreterClassBuildAssert inheritsFrom: InterpreterPrimitives).
										self assert:(o  interpreterClassBuildAssertITimerHeartbeat inheritsFrom: InterpreterPrimitives).
										self assert:(o  interpreterClassBuildDebug inheritsFrom: InterpreterPrimitives).
										self assert:(o  interpreterClassBuildDebugITImerHeartbeat inheritsFrom: InterpreterPrimitives).
										self assert:(o  interpreterClassBuildITimerHeartbeat inheritsFrom: InterpreterPrimitives).
										self assert:(o  interpreterClassBuildITimerMultiThreaded inheritsFrom: InterpreterPrimitives).
										self assert:(o  interpreterClassBuildITimerMultiThreadedAssert inheritsFrom: InterpreterPrimitives).
										self assert:(o  interpreterClassBuildITimerMultiThreadedDebug inheritsFrom: InterpreterPrimitives)]]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testOutputDir [
	"for each builder, make sure all its configurations provide an outputDir "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							(o excludeFromBuild not)
								ifTrue:[self assert:(o  outputDir isKindOf: FileDirectory)]]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testSrcDirs [
	"for each builder, make sure all its configurations provide a srcDir "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  srcDir isKindOf: FileDirectory)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testTopDirs [
	"for each builder, make sure all its configurations provide a topDir "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							self assert:(o  topDir isKindOf: FileDirectory)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakConfigurationsTest >> testdirBuildLanguageVMMM [
	"for each builder that does not exclude itself from builds, make sure it returns dirBUildLanguageVMMM "
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
							o:= configuration new.
							o excludeFromBuild not                                                     
							 	ifTrue:[self assert:(o  dirBuildLanguageVMMM isString)]]]]








]
