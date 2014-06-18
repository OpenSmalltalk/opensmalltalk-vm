"
I need to go away. In the meantime....

THis is a concrete class which generates a DEBUG CogVM for Unix systems. This VM is normally known as a debug CogVM. The debug means that it is compiled with all the necessary symbolic symbols for debugging and can be debugged, for example, with GDB.


Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #Linux32x86SqueakCogV3DebugConfigz,
	#superclass : #Linux32x86Config,
	#category : #'CMakeVMMakerSqueak-IslandOfMisfitToys'
}

{ #category : #'source generation' }
Linux32x86SqueakCogV3DebugConfigz >> cogitClass [
	^ StackToRegisterMappingCogit 

]

{ #category : #'squeak compatibility' }
Linux32x86SqueakCogV3DebugConfigz >> compilerFlags [
	|d commonFlags flags|
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self compilerFlagsBuild];
		at: #buildAssert  put: [self compilerFlagsAssert];
		at: #buildAssertITimerHeartbeat  put: [self compilerFlagsAssertITimerHeartbeat];
            at:#buildDebug  put: [self compilerFlagsDebug];   "located in CMakeVMMaker CPlatformConfig"
		at: #buildDebugITimerHeartbeat  put: [self compilerFlagsDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self compilerFlagsIHeartbeatTimer];
		at: #buildMultiThreaded  put: [self compilerFlagsMultiThreaded ];
		at: #buildMultiThreadedAssert  put: [self compilerFlagsMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self compilerFlagsMultiThreadedDebug ];
		at: #buildNone put:[self compilerFlagsNoBuildType].

    flags:= String streamContents: [ :stream |
	 (((d at:  buildType) value)  collect: #withBlanksTrimmed as: Set)
		asStringOn: stream 
		delimiter:' '].

    commonFlags:=String streamContents: [ :stream |
		((self commonCompilerFlags) collect: #withBlanksTrimmed as: Set)
			asStringOn: stream 
			delimiter: ' ' ].
	^ commonFlags, ' ' ,flags.
]

{ #category : #plugins }
Linux32x86SqueakCogV3DebugConfigz >> defaultExternalPlugins [
	^ (super defaultExternalPlugins copyWithoutAll: #(#ThreadedIA32FFIPlugin #InternetConfigPlugin))


]

{ #category : #cmake }
Linux32x86SqueakCogV3DebugConfigz >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #'source generation' }
Linux32x86SqueakCogV3DebugConfigz >> interpreterClass [
	^ CoInterpreter
]
