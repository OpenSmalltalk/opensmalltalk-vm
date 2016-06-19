"
A CMakeVMMakerSqueakCommonConfigTest  tests simple functionality that is supported by both AbstractBaseClass configurations and concrete implemntations.

Redirect method tests are farmed out to CMakeVMMakerSqueakRedirectMethodsTest and CMakeVMMakerSqueakRedirectMethodsWithArgTest
"
Class {
	#name : #CMakeVMMakerSqueakCommonConfigTest,
	#superclass : #TestCase,
	#category : #'CMakeVMMakerSqueak-Tests'
}

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testAvailableBuildTypes [
	"each concrete configuration must report what buildTypes it supports  "
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | config |
					config:= configuration basicNew.
					(config excludeFromBuild not)                               ""
						ifTrue:[  self assert:(config  availableBuildTypes isKindOf: Collection)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testBuildDir [
	"for each builder, make sure all its configurations provides availbale build directories "
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
							o:= configuration basicNew.
							o excludeFromBuild not
								ifTrue:[self assert:(o  buildDir isKindOf: FileDirectory)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testBuildDirName [
	"for each builder, make sure all its configurations provide a build directory name "
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
							o:= configuration basicNew.
							(o excludeFromBuild not)                               ""
								ifTrue:[
									self assert:(o  buildDirName isString).
									self assert:(o  buildDirName size > 0)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testBuildScript [
	"for each builder, make sure all its configurations provide a build directory name "
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
							o:= configuration basicNew.
							(o excludeFromBuild not)                               ""
								ifTrue:[
									self assert:(o  buildScript isString).
									self assert:(o  buildScript size > 0)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testCogitClass [
	"for each builder that does not exclude itself from builds, make sure it returns cogitClass "
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
							o:= configuration basicNew.
							o excludeFromBuild not                                                     
							 	ifTrue:[self assert:(o  cogitClass inheritsFrom: Cogit)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testCrossSources [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
					configuration isAbstractBaseClass not
						ifTrue:[
							o:= configuration basicNew.
							(o excludeFromBuild not)
								ifTrue:[	self assert:(o  crossSources isArray)]]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testCustomizeVMPlugins [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes|
					o:= configuration basicNew.							
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.	
								o initializeVMPlugins.
							 	self assert:(o  vmplugins isKindOf:Collection)]]]]






]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testDirBuildPlatform [
	"for each builder, make sure all its configurations provide a dirSource "
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
									o:= configuration basicNew.
									self assert:(o  dirBuildPlatform isString)]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testExcludeFromBuild [
	"for each builder, make sure all its includes or excludes itself from a build "
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
							o:= configuration basicNew.
							self assert:((o excludeFromBuild  basicType) = #Boolean)]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testExectuableName [
	"for each builder, make sure all its configurations provide an executableName "
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
							o:= configuration basicNew.
							(o excludeFromBuild not)
								ifTrue:[self assert:(o  executableName isString)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testExecutableType [
	"for each builder, make sure all its configurations provide an executableName "
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
							o:= configuration basicNew.
							(o excludeFromBuild not)
								ifTrue:[self assert:(o  executableType isString)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testExternalsModuleDir [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
							o:= configuration basicNew.
							o excludeFromBuild not                                                     
								ifTrue:[self assert:(o  externalModulesDir isString)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testExtraSources [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
							o:= configuration basicNew.
							(o excludeFromBuild not)
								ifTrue:[self assert:(o  extraSources isString)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testInitializeVMPlugins [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
							o:= configuration basicNew.
							o initializeVMPlugins.
							o excludeFromBuild not                                                     
							 	ifTrue:[self assert:(o  vmplugins isKindOf:Collection)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testInterpreterClass [
	"for each builder that does not exclude itself from builds, make sure it returns an InterpreterClass "
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
							o:= configuration basicNew.
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
										self assert:(o  interpreterClassBuildITimerMultiThreadedDebug inheritsFrom: InterpreterPrimitives)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testIsAbstractBaseClass [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | 
					self assert:(configuration isAbstractBaseClass basicType = #Boolean)]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testIsLittleEndian [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
					configuration isAbstractBaseClass not
						ifTrue:[
							o:= configuration basicNew.
							(o excludeFromBuild not)
								ifTrue:[	self assert:(o  isLittleEndian)]]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testOutputDir [
	"for each builder, make sure all its configurations provide an outputDir "
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
							o:= configuration basicNew.
							(o excludeFromBuild not)
								ifTrue:[self assert:(o  outputDir isKindOf: FileDirectory)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testOutputDirName [
	"for each builder, make sure all its configurations provide a build directory name "
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
							o:= configuration basicNew.
							(o excludeFromBuild not)                               ""
								ifTrue:[
									self assert:(o  outputDirName isString).
									self assert:(o  outputDirName size > 0)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testSrcDir [
	"for each builder, make sure all its configurations provide a srcDir via their dirSource method "
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
					o:= configuration basicNew.
					(o excludeFromBuild not | configuration isAbstractBaseClass not)
						ifTrue:[self assert:(o  srcDir isKindOf: FileDirectory)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testTopDir [
	"for each builder, make sure all its configurations provide a topDir "
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
					o:= configuration basicNew.
					(o excludeFromBuild not) | (configuration isAbstractBaseClass)
						ifTrue:[self assert:(o  topDir isKindOf: FileDirectory)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testVersion [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
					o:= configuration basicNew.
					(o excludeFromBuild not) | (configuration isAbstractBaseClass)
						ifTrue:[self assert:(o  version isString)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakCommonConfigTest >> testdirBuildLanguageVMMM [
	"for each builder that does not exclude itself from builds, make sure it returns dirBUildLanguageVMMM "
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
							o:= configuration basicNew.
							o excludeFromBuild not                                                     
							 	ifTrue:[self assert:(o  dirBuildLanguageVMMM isString)]]]








]
