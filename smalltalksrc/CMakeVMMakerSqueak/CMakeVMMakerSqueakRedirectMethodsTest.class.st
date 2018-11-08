"
A CMakeVMMakerSqueakRedirectMethodsTest tests that all Concrete Configuration implement the abstract methods of form:

""
x
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self xBuild];
		at: #buildAssert  put: [self xBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self xBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self xBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self xBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self xBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self xBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self xBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self xBuildMultiThreadedDebug ];
		at: #buildNone put:[self xNoBuildType].
	^(d at: buildType) value

""

"
Class {
	#name : #CMakeVMMakerSqueakRedirectMethodsTest,
	#superclass : #TestCase,
	#category : #'CMakeVMMakerSqueak-Tests'
}

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsTest >> testCompilerDefinitions [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes|
					o:= configuration basicNew.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								self assert:(o  compilerDefinitions isKindOf: Collection).
								self assert:(o  compilerDefinitions size > 0)]]]].








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsTest >> testCompilerFlags [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes|
					o:= configuration basicNew.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								self assert:(o  compilerFlags isKindOf: Collection).
								self assert:(o  compilerFlags size > 0)]]]].








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsTest >> testCoreSources [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes|
					o:= configuration basicNew.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								self assert:(o  coreSources isKindOf:Collection).
								self assert:((o  coreSources size) > 0)]]]].








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsTest >> testExternalLibs [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes|
					o:= configuration basicNew.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								self assert:(o  externalLibs isKindOf: Collection).
								]]]].








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsTest >> testExternalPlugins [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes|
					o:= configuration basicNew.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								self assert:(o  externalPlugins isArray).
								]]]].








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsTest >> testFrameworks [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes|
					o:= configuration basicNew.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								self assert:(o  frameworks isKindOf: Collection)]]]].

]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsTest >> testInternalPlugins [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes|
					o:= configuration basicNew.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								self assert:(o  externalPlugins isArray).
								]]]].








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsTest >> testLinkerFlags [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes|
					o:= configuration basicNew.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								self assert:(o  linkerFlags isKindOf: Collection).
								self assert:(o  linkerFlags size > 0)]]]].








]
