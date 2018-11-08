"
A CMakeVMMakerSqueakRedirectMethodsWithArgTest tests that all Concrete Configuration implement the abstract methods of form:

""
x: aMaker
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self xBuild: aMaker];
		at: #buildAssert  put: [self xBuildAssert: aMaker];
		at: #buildAssertITimerHeartbeat  put: [self xBuildAssertITimerHeartbeat: aMaker];
            at:#buildDebug  put: [self xBuildDebug: aMaker];   
		at: #buildDebugITimerHeartbeat  put: [self xBuildDebugITimerHeartbeat: aMaker ];
		at: #buildITimerHeartbeat  put: [self xBuildITimerHeartbeat: aMaker];
		at: #buildMultiThreaded  put: [self xBuildMultiThreaded: aMaker ];
		at: #buildMultiThreadedAssert  put: [self xBuildMultiThreadedAssert: aMaker];
		at: #buildMultiThreadedDebug   put: [self xBuildMultiThreadedDebug: aMaker ];
		at: #buildNone put:[self xNoBuildType:  aMaker].
	^(d at: buildType) value


""
"
Class {
	#name : #CMakeVMMakerSqueakRedirectMethodsWithArgTest,
	#superclass : #TestCase,
	#category : #'CMakeVMMakerSqueak-Tests'
}

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsWithArgTest >> testExtraPluginSettings [
	self flag:'tty'. "Is the self shouldnt sufficient?"
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes vmGenerator pluginGenerator|
					o:= configuration basicNew.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								o enabledebugmessages:true.			
								o templates: OrderedCollection new. 																
								vmGenerator:=CMakeVMGeneratorForSqueak new.
								vmGenerator config: o.
								vmGenerator output:(String new writeStream).
								pluginGenerator := CMakePluginGeneratorForSqueak new.
								pluginGenerator vmGenerator: vmGenerator.
								pluginGenerator isInternal: false.
								pluginGenerator output:(String new writeStream).
								pluginGenerator templates: OrderedCollection new.
								self shouldnt: [o extraPluginSettings: pluginGenerator] raise: Error]]]].

]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsWithArgTest >> testExtraVMSettings [
	self flag:'tty'. "Is the self shouldnt sufficient?"
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes vmGenerator|
					o:= configuration basicNew.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								o enabledebugmessages:true.
								o templates: OrderedCollection new. 
								vmGenerator:=CMakeVMGeneratorForSqueak new.
								vmGenerator config: o.
								vmGenerator output:(String new writeStream).
								o extraVMSettings: vmGenerator.
								self shouldnt: [o extraVMSettings: vmGenerator] raise: Error]]]].

]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsWithArgTest >> testSetGlobalOptions [
	self flag:'tty'. "Is the self shouldnt sufficient?"
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes vmGenerator|
					o:= configuration basicNew.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								o enabledebugmessages:true.
								o templates: OrderedCollection new. 
								vmGenerator:=CMakeVMGeneratorForSqueak new.
								vmGenerator output:(String new writeStream).
								self shouldnt: [o setGlobalOptions: vmGenerator] raise: Error]]]].

]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsWithArgTest >> testSetGlobalOptionsAfterDetermineSystem [
	self flag:'tty'. "Is the self shouldnt sufficient?"
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes vmGenerator|
					o:= configuration basicNew.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								o enabledebugmessages:true.
								o templates: OrderedCollection new. 
								vmGenerator:=CMakeVMGeneratorForSqueak new.
								vmGenerator output:(String new writeStream).
								self shouldnt: [o setGlobalOptionsAfterDetermineSystem: vmGenerator] raise: Error]]]].

]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsWithArgTest >> testSetPlatformSources [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes vmGenerator|
					o:= configuration basicNew.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								o enabledebugmessages: true.
								o templates: OrderedCollection new.
								o initializePlatformSources.
								vmGenerator:=CMakeVMGeneratorForSqueak new.
								vmGenerator config: o.
								vmGenerator output:(String new writeStream).
								self shouldnt: [o setPlatformSources: vmGenerator] raise: Error]]]].

]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsWithArgTest >> testSetPostBuildActions [
	self flag:'tty'. "This test will probably fail if the oscogvm/cmake.build.xzy/language.vm.memorymanager/buildtype/ directory is not in place"
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o buildTypes vmGenerator|
					o:= configuration basicNew.
					(o excludeFromBuild not) & (configuration isAbstractBaseClass not)
						ifTrue:[
							buildTypes:=o availableBuildTypes copyWithoutAll:#(#buildNone).
							buildTypes do:[:buildType |
								o configureForBuildType: buildType.
								o enabledebugmessages: true.
								o templates: OrderedCollection new.
								vmGenerator:=CMakeVMGeneratorForSqueak new.
								vmGenerator config: o.
								vmGenerator output:(String new writeStream).
								self shouldnt: [o postBuildActions: vmGenerator] raise: Error]]]].

]
