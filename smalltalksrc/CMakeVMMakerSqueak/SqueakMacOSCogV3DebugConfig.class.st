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
    ^ String streamContents:  [ :stream |
	self commonCompilerFlags asStringOn: stream delimiter: ' '. 
	self compilerFlagsDebug asStringOn: stream delimiter: ' ' ]
]

{ #category : #cmake }
SqueakMacOSCogV3DebugConfig >> excludeFromBuild [
	^true

]
