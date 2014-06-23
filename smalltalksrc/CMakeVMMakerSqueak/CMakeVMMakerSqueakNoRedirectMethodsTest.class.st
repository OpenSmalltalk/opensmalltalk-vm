"
A CMakeVMMakerSqueakRedirectMethodsTest tests that all Concrete Configuration implement the abstract methods of form:
makes sure that all the redirect methods are implemented by calling them directly instead of through the redirect mechanism
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
	#name : #CMakeVMMakerSqueakNoRedirectMethodsTest,
	#superclass : #TestCase,
	#category : #'CMakeVMMakerSqueak-Tests'
}

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakNoRedirectMethodsTest >> testCommonCompilerFlags [
"	#(#SqueakWindowsConfig #SqueakUnixConfig #SqueakMacintoshConfig) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
					o:= configuration new.
					(o excludeFromBuild not)  |(configuration isAbstractBaseClass)  
						ifTrue:[
							self assert:(o  commonCompilerFlags isArray).
							self assert:(o  compilerFlagsAssert isArray).
							self assert:(o  compilerFlagsAssertITimerHeartbeat isArray).
							self assert:(o  compilerFlagsBuild isArray).
							self assert:(o  compilerFlagsDebug isArray).
							self assert:(o  compilerFlagsDebugITimerHeartbeat isArray).
							self assert:(o  compilerFlagsIHeartbeatTimer isArray).
							self assert:(o  compilerFlagsMultiThreaded isArray).
							self assert:(o  compilerFlagsMultiThreadedAssert isArray).
							self assert:(o  compilerFlagsMultiThreadedDebug isArray)]]]"
]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakNoRedirectMethodsTest >> testCompilerFlags [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				allSubclassesDo:[:configuration | | o |
					o:= configuration new.
					(o excludeFromBuild not)  
						ifTrue:[
							self assert:(o  compilerFlagsBuild isArray).
							self assert:(o  compilerFlagsBuildAssert isArray).
							self assert:(o  compilerFlagsBuildAssertITimerHeartbeat isArray).
							self assert:(o  compilerFlagsBuildDebug isArray).
							self assert:(o  compilerFlagsBuildDebugITimerHeartbeat isArray).
							self assert:(o  compilerFlagsBuildITimerHeartbeat isArray).
							self assert:(o  compilerFlagsBuildMultiThreaded isArray).
							self assert:(o  compilerFlagsBuildMultiThreadedAssert isArray).
							self assert:(o  compilerFlagsBuildMultiThreadedDebug isArray)]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakNoRedirectMethodsTest >> testLinkFlags [
	#(#SqueakMacintoshConfig #SqueakUnixConfig #SqueakWindowsConfig ) 
		do:[:each | 
			(Smalltalk at:each) 
				subclassesDo:[:configuration | | o |
							o:= configuration new.
							(o excludeFromBuild not)  |(configuration isAbstractBaseClass)  
								ifTrue:[
							o:= configuration new.
							(o excludeFromBuild not)
								ifTrue:[]]]]
]
