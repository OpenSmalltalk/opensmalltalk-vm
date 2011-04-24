"
This is a concrete class which generates a CogVM for Mac using the Cocoa library

Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #CogCocoaIOSConfig,
	#superclass : #CogFamilyCocoaIOSConfig,
	#category : #'CMakeVMMaker-IOS'
}

{ #category : #'source generation' }
CogCocoaIOSConfig >> cogitClass [
	"answer a class for machine code generation or nil"
	
	^ StackToRegisterMappingCogit 
]

{ #category : #settings }
CogCocoaIOSConfig >> compilerFlagsRelease [ 
	^super compilerFlagsRelease, #('-DCOGVM')
]

{ #category : #'source files' }
CogCocoaIOSConfig >> coreSources [ 
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
		)
]

{ #category : #accessing }
CogCocoaIOSConfig >> executableName [
	^ 'CogVM'
]

{ #category : #plugins }
CogCocoaIOSConfig >> ffiPluginName [ 
	^#ReentrantIA32FFIPlugin
]

{ #category : #'source generation' }
CogCocoaIOSConfig >> interpreterClass [
	^ CoInterpreter
]

{ #category : #accessing }
CogCocoaIOSConfig >> pluginsDir [ 
	^'${srcDir}/plugins'
]

{ #category : #'source generation' }
CogCocoaIOSConfig >> prepareForGeneration [

	"force using LF on Macs"
	CrLfFileStream defaultToLF.

	^ self prepareForCogGeneration

]

{ #category : #accessing }
CogCocoaIOSConfig >> srcDir [ 
	"Answer the value of srcDir"

	^ srcDir ifNil: [ srcDir := (self topDir / self srcDirName) fullName ]
]
