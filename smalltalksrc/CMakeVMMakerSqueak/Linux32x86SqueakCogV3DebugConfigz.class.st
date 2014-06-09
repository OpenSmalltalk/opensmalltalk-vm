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

{ #category : #'squeak compatibility' }
Linux32x86SqueakCogV3DebugConfigz >> compilerFlags [
	^  String streamContents:  [ :stream |
	self commonCompilerFlags asStringOn: stream delimiter: ' '. 
	self compilerFlagsDebug asStringOn: stream delimiter: ' ' ]
]

{ #category : #plugins }
Linux32x86SqueakCogV3DebugConfigz >> defaultExternalPlugins [
	^ (super defaultExternalPlugins copyWithoutAll: #(#ThreadedIA32FFIPlugin #InternetConfigPlugin))


]

{ #category : #cmake }
Linux32x86SqueakCogV3DebugConfigz >> excludeFromBuild [
"	^false"   "build this configuration"
	^true


]
