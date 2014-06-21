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
