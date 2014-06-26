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
CMakeVMMakerSqueakRedirectMethodsTest >> testCommonCompilerFlags [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes|
					o:= configuration new.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								self assert:(o  commonCompilerFlags isArray)]]]].

]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsTest >> testCompilerFlags [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes|
					o:= configuration new.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								self assert:(o  compilerFlags isString).
								self assert:(o  compilerFlags size > 0)]]]].








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsTest >> testConfigH [
	#(#SqueakUnixConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes|
	
					o:= configuration new.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								self assert:(o  configH isString).
								self assert:(o  configH size > 0)]]]].








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsTest >> testExternalPlugins [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes|
					o:= configuration new.
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
					o:= configuration new.
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
					o:= configuration new.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								self assert:(o  externalPlugins isArray).
								]]]].








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsTest >> testLinkFlags [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes|
					o:= configuration new.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								self assert:(o  linkFlags isArray)]]]].
]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsTest >> testPreferredIncludes [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes|
					o:= configuration new.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								self assert:(o  preferredIncludes isKindOf: Collection)]]]].

]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsTest >> testStandardIncludes [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes|
					o:= configuration new.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								self assert:(o  standardIncludes isKindOf: Collection)]]]].

]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsTest >> testThirdPartyLibs [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes|
					o:= configuration new.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								self assert:(o  thirdPartyLibs isKindOf: Collection).
								]]]].








]
