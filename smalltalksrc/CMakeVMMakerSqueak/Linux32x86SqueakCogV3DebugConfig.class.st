"
THis is a concrete class which generates a DEBUG CogVM for Unix systems. This VM is normally known as a debug CogVM. The debug means that it is compiled with all the necessary symbolic symbols for debugging and can be debugged, for example, with GDB.


Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #Linux32x86SqueakCogV3DebugConfig,
	#superclass : #Linux32x86SqueakCogV3Config,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #'squeak compatibility' }
Linux32x86SqueakCogV3DebugConfig >> compilerFlags [
	^  String streamContents:  [ :stream |
	self commonCompilerFlags asStringOn: stream delimiter: ' '. 
	self compilerFlagsDebug asStringOn: stream delimiter: ' ' ]
]

{ #category : #plugins }
Linux32x86SqueakCogV3DebugConfig >> defaultExternalPlugins [
	^ (super defaultExternalPlugins copyWithoutAll: #(#ThreadedIA32FFIPlugin #InternetConfigPlugin))


]
