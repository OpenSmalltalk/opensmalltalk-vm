"
This is a concrete class which generates a thread-aware VM and threaded FFI CogVM for Unix. This VM is normally known as CogMTVM.

Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #CogMTUnixConfig,
	#superclass : #CogUnixConfig,
	#category : #'CMakeVMMaker-Unix'
}

{ #category : #'compiler flags' }
CogMTUnixConfig >> commonCompilerFlags [

	"Common compiler flags
	
	
	LSB_FIRST=1 means that target platform is little endian. 
	set it to 0 for big-endian platforms
	
	"
	
	^ {
		'-DLSB_FIRST=1'. 
		'-DUSE_GLOBAL_STRUCT=0'. 
		'-DCOGMTVM=1'. 
		'-m32' }
]

{ #category : #'plugin extra rules' }
CogMTUnixConfig >> configureReentrantIA32FFIPlugin: maker [
	self error: 'use ThreadedIA32FFIPlugin instead'

]

{ #category : #sources }
CogMTUnixConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #plugins }
CogMTUnixConfig >> defaultExternalPlugins [

	^ #(
		B3DAcceleratorPlugin
		"UUIDPlugin"
		ThreadedIA32FFIPlugin "SqueakFFIPrims"
		"UnixOSProcessPlugin ?? "
	)
]

{ #category : #accessing }
CogMTUnixConfig >> executableName [
	^ 'CogMTVM'
]

{ #category : #'source generation' }
CogMTUnixConfig >> interpreterClass [
	^ CoInterpreterMT
]
