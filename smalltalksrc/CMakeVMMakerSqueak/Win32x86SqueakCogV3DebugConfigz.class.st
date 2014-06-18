"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

Usage:
Win32x86SqueakCogV3DebugConfig generateWithSources
Or:
Win32x86SqueakCogV3DebugConfig generate
Or: 
find my Builder in CMakeVMMakerSqueak-Builder category and use that to invoke me.

"
Class {
	#name : #Win32x86SqueakCogV3DebugConfigz,
	#superclass : #Win32x86SqueakCogV3Config,
	#category : #'CMakeVMMakerSqueak-IslandOfMisfitToys'
}

{ #category : #'source generation' }
Win32x86SqueakCogV3DebugConfigz >> cogitClass [
	^ StackToRegisterMappingCogit 

]

{ #category : #directories }
Win32x86SqueakCogV3DebugConfigz >> compilerFlags [
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

{ #category : #cmake }
Win32x86SqueakCogV3DebugConfigz >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #'source generation' }
Win32x86SqueakCogV3DebugConfigz >> interpreterClass [
	^ CoInterpreter

]

{ #category : #utils }
Win32x86SqueakCogV3DebugConfigz >> setExtraTargetProperties: maker [

	maker addExternalLibraries: self externalLibraries.
	maker set: 'EXECUTABLE_OUTPUT_PATH' toString: '${outputDir}'.


]
