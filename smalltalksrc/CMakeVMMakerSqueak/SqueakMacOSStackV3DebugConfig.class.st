"
This is a concrete class which generates a DEBUG StackVM for Mac using Carbon library. This VM is normally known as a debug StackVM. The debug means that it is compiled with all the necessary symbolic symbols for debugging and can be debugged, for example, with GDB.

For more information, check the class comments of all the superclasses.

Usage:
SqueakStackMacOSDebugConfig generateWithSources.
Or:
SqueakStackMacOSDebugConfig generate.




"
Class {
	#name : #SqueakMacOSStackV3DebugConfig,
	#superclass : #SqueakMacOSStackV3Config,
	#category : #'CMakeVMMakerSqueak-MacOS'
}

{ #category : #'as yet unclassified' }
SqueakMacOSStackV3DebugConfig >> compilerFlags [
    ^ String streamContents:  [ :stream |
	self commonCompilerFlags asStringOn: stream delimiter: ' '. 
	self compilerFlagsDebug asStringOn: stream delimiter: ' ' ]
]
