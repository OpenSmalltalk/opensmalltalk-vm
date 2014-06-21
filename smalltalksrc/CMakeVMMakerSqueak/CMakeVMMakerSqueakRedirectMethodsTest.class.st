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
CMakeVMMakerSqueakRedirectMethodsTest >> testCompilerFlags [
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder | | o |
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (builder configurationsCategory))
					ifTrue:[ 
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
							self assert:(o  compilerFlagsBuildMultiThreadedDebug isArray)]]]]








]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakRedirectMethodsTest >> testLinkFlags [
	"make sure each enabled Configuration returns from each buildType configuration correctly"
	|buildTypes|
	SqueakCMakeVMMakerAbstractBuilder	reset.
	SqueakCMakeVMMakerAbstractBuilder 
		subclassesDo:[:builder |
	 | concreteConfiguration concreteBuilder|
			concreteBuilder:=(Smalltalk at: (builder name asSymbol)) new.
			Smalltalk globals 
				allClassesDo:[:configuration | (configuration class category asString withoutQuoting startsWith: (concreteBuilder configurationsCategory))
					ifTrue:[ 
							concreteConfiguration:= configuration new.
							(concreteConfiguration excludeFromBuild not)
								ifTrue:[
									buildTypes := concreteBuilder availableBuildTypesFor: concreteConfiguration class name asSymbol.
									buildTypes do:[:buildType |
											builder configureA: (configuration name) forBuildType: buildType.
													self assert:(concreteConfiguration  linkFlags isString)]]]]]
											










]
