Class {
	#name : #CocoaIOSCogStackConfig,
	#superclass : #CocoaIOSCogConfig,
	#category : #CMakeVMMaker
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
CocoaIOSCogStackConfig >> pluginsDir [ 
	^'${topDir}/stacksrc/plugins'
]

{ #category : #accessing }
CocoaIOSCogStackConfig >> srcDir [ 
	^'${topDir}/stacksrc'
]
