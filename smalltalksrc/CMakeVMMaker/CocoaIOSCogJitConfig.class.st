Class {
	#name : #CocoaIOSCogJitConfig,
	#superclass : #CocoaIOSCogConfig,
	#category : #'CMakeVMMaker-IOS'
}

{ #category : #'source generation' }
CocoaIOSCogJitConfig >> cogitClass [
	"answer a class for machine code generation or nil"
	
	^ StackToRegisterMappingCogit 
]

{ #category : #settings }
CocoaIOSCogJitConfig >> compilerFlagsRelease [ 
	^super compilerFlagsRelease, #('-DCOGVM')
]

{ #category : #'source files' }
CocoaIOSCogJitConfig >> coreSources [ 
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
		)
]

{ #category : #defaults }
CocoaIOSCogJitConfig >> defaultExternalPlugins [
	^#()
]

{ #category : #accessing }
CocoaIOSCogJitConfig >> executableName [
	^ 'Cog'
]

{ #category : #'source generation' }
CocoaIOSCogJitConfig >> interpreterClass [
	^ CoInterpreter
]

{ #category : #accessing }
CocoaIOSCogJitConfig >> pluginsDir [ 
	^'${topDir}/src/plugins'
]

{ #category : #'source generation' }
CocoaIOSCogJitConfig >> prepareForGeneration [

	"force using LF on Macs"
	CrLfFileStream defaultToLF.

	^ self prepareForCogGeneration

]

{ #category : #accessing }
CocoaIOSCogJitConfig >> srcDir [ 
	"Answer the value of srcDir"

	^ srcDir ifNil: [ srcDir := self topDir / 'src' ]
]
