"
CocoaIOSCogStackConfig is a concrete class which generates a StackVM for Mac using the Cocoa library
"
Class {
	#name : #CocoaIOSCogStackConfig,
	#superclass : #CocoaIOSCogConfig,
	#category : #'CMakeVMMaker-IOS'
}

{ #category : #settings }
CocoaIOSCogStackConfig >> compilerFlagsRelease [ 
	^super compilerFlagsRelease, #('-DSTACKVM')
]

{ #category : #'source files' }
CocoaIOSCogStackConfig >> coreSources [ 
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #accessing }
CocoaIOSCogStackConfig >> executableName [
	^ 'StackVM'
]

{ #category : #plugins }
CocoaIOSCogStackConfig >> ffiPluginName [ 
	^#ReentrantIA32FFIPlugin
]

{ #category : #'source generation' }
CocoaIOSCogStackConfig >> interpreterClass [
	^ StackInterpreter
]

{ #category : #accessing }
CocoaIOSCogStackConfig >> pluginsDir [ 
	^'${topDir}/stacksrc/plugins'
]

{ #category : #'source generation' }
CocoaIOSCogStackConfig >> prepareForGeneration [

	"force using LF on Macs"
	CrLfFileStream defaultToLF.

	^ self prepareForStackVMGeneration

]

{ #category : #accessing }
CocoaIOSCogStackConfig >> srcDir [ 
	"Answer the value of srcDir"

	^ srcDir ifNil: [ srcDir := (self topDir / self srcDirName) fullName ]
]

{ #category : #accessing }
CocoaIOSCogStackConfig >> srcDirName [
	^ 'stacksrc'
]
