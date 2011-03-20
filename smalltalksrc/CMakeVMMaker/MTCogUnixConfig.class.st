Class {
	#name : #MTCogUnixConfig,
	#superclass : #CogUnixConfig,
	#category : #'CMakeVMMaker-Unix-Cog'
}

{ #category : #'as yet unclassified' }
MTCogUnixConfig >> commonCompilerFlags [

	"Common compiler flags
	
	
	LSB_FIRST=1 means that target platform is little endian. 
	set it to 0 for big-endian platforms
	
	"
	
	^ ' -DLSB_FIRST=1 -DUSE_GLOBAL_STRUCT=0 -DCOGMTVM=1'	
	
]

{ #category : #'as yet unclassified' }
MTCogUnixConfig >> configureReentrantIA32FFIPlugin: maker [
	self error: 'use ThreadedIA32FFIPlugin instead'

]

{ #category : #'as yet unclassified' }
MTCogUnixConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #'as yet unclassified' }
MTCogUnixConfig >> defaultExternalPlugins [

	^ #(
		B3DAcceleratorPlugin
		UUIDPlugin
		ThreadedIA32FFIPlugin "SqueakFFIPrims"
		"UnixOSProcessPlugin ?? "
	)
]

{ #category : #'as yet unclassified' }
MTCogUnixConfig >> interpreterClass [
	^ CoInterpreterMT
]
