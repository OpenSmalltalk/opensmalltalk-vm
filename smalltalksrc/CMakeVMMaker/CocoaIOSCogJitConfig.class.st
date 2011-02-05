Class {
	#name : #CocoaIOSCogJitConfig,
	#superclass : #CocoaIOSCogConfig,
	#category : #CMakeVMMaker
}

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

{ #category : #accessing }
CocoaIOSCogJitConfig >> pluginsDir [ 
	^'${topDir}/src/plugins'
]

{ #category : #accessing }
CocoaIOSCogJitConfig >> srcDir [ 
	^'${topDir}/src'
]
