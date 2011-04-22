"
MTCogUnixConfig is a concrete class which generates a thread-aware VM and threaded FFI CogVM for Unix. This VM is normally known as CogMTVM.
"
Class {
	#name : #MTCogUnixConfig,
	#superclass : #CogUnixConfig,
	#category : #'CMakeVMMaker-Unix-Cog'
}

{ #category : #'compiler flags' }
MTCogUnixConfig >> commonCompilerFlags [

	"Common compiler flags
	
	
	LSB_FIRST=1 means that target platform is little endian. 
	set it to 0 for big-endian platforms
	
	"
	
	^ ' -DLSB_FIRST=1 -DUSE_GLOBAL_STRUCT=0 -DCOGMTVM=1 -m32' 	
	
]

{ #category : #'plugin extra rules' }
MTCogUnixConfig >> configureReentrantIA32FFIPlugin: maker [
	self error: 'use ThreadedIA32FFIPlugin instead'

]

{ #category : #sources }
MTCogUnixConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #plugins }
MTCogUnixConfig >> defaultExternalPlugins [

	^ #(
		B3DAcceleratorPlugin
		"UUIDPlugin"
		ThreadedIA32FFIPlugin "SqueakFFIPrims"
		"UnixOSProcessPlugin ?? "
	)
]

{ #category : #accessing }
MTCogUnixConfig >> executableName [
	^ 'CogMTVM'
]

{ #category : #'source generation' }
MTCogUnixConfig >> interpreterClass [
	^ CoInterpreterMT
]
