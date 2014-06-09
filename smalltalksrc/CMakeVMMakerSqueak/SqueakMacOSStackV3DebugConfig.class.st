"
This is a concrete class which generates a DEBUG StackVM for Mac using Carbon library. This VM is normally known as a debug StackVM. The debug means that it is compiled with all the necessary symbolic symbols for debugging and can be debugged, for example, with GDB.

For more information, check the class comments of all the superclasses.

Usage:
SqueakMacOSStackV3DebugConfig generateWithSources.
Or:
SqueakMacOSStackV3DebugConfig generate.
Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me




"
Class {
	#name : #SqueakMacOSStackV3DebugConfig,
	#superclass : #SqueakMacOSSqueakStackV3Config,
	#category : #'CMakeVMMakerSqueak-IslandOfMisfitToys'
}

{ #category : #accessing }
SqueakMacOSStackV3DebugConfig >> compilerFlags [
    ^ String streamContents:  [ :stream |
	self commonCompilerFlags asStringOn: stream delimiter: ' '. 
	self compilerFlagsDebug asStringOn: stream delimiter: ' ' ]
]

{ #category : #cmake }
SqueakMacOSStackV3DebugConfig >> excludeFromBuild [
	^true

]
