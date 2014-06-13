"
This is a concrete class which generates a DEBUG CogVM for Mac using Carbon library. This VM is normally known as a debug CogVM. The debug means that it is compiled with all the necessary symbolic symbols for debugging and can be debugged, for example, with GDB.

For more information, check the class comments of all the superclasses.


Usage:
SqueakCogMacOSDebugConfig generateWithSources.
or:
SqueakCogMacOSDebugConfig generate.
"
Class {
	#name : #SqueakMacOSCogV3DebugConfig,
	#superclass : #SqueakMacOSSqueakCogV3Config,
	#category : #'CMakeVMMakerSqueak-IslandOfMisfitToys'
}

{ #category : #accessing }
SqueakMacOSCogV3DebugConfig >> compilerFlags [
	|d releaseFlags|
	self break.
	releaseFlags := self isGenerateForRelease .
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self compilerFlagsBuild];
		at: #buildAssert  put: [self compilerFlagsAssert];
		at: #buildAssertITimerHeartbeat  put: [self compilerFlagsAssertITimerHeartbeat];
            at:#buildDebug  put: [self compilerFlagsDebug];   "located in CMakeVMMaker CPlatformConfig"
		at: #buildDebugITimerHeartbeat  put: [self compilerFlagsDebugITimerHeartbeat ];
		at: #buildDebugMultiThreaded  put: [self compilerFlagsDebugMultiThreaded];
		at: #buildITimerHeartbeat  put: [self compilerFlagsIHeartbeatTimer];
		at: #buildMultiThreaded  put: [self compilerFlagsMultiThreaded ];
		at: #buildMultiThreadedAssert  put: [self compilerFlagsMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self compilerFlagsMultiThreadedDebug ];
		at: #buildNone put:[self compilerFlagsNoBuildType].
     (d at: self buildType) value.

	^ String streamContents: [ :stream |
		((self commonCompilerFlags, releaseFlags)
			asStringOn: stream 
			delimiter: ' ' )]
]

{ #category : #cmake }
SqueakMacOSCogV3DebugConfig >> excludeFromBuild [
	^true

]
