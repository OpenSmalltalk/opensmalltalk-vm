"
This is a concrete class which generates a thread-aware VM and threaded FFI CogVM for FreeBSD. This VM is normally known as CogMTVM.

Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #CogMTFreeBSDConfig,
	#superclass : #CogFreeBSDConfig,
	#category : #'CMakeVMMaker-FreeBSD'
}

{ #category : #'compiler flags' }
CogMTFreeBSDConfig >> commonCompilerFlags [

	"Common compiler flags
	
	
	LSB_FIRST=1 means that target platform is little endian. 
	set it to 0 for big-endian platforms
	
	"
	
	^ {
		'-DLSB_FIRST=1'. 
		'-DUSE_GLOBAL_STRUCT=0'. 
		'-DCOGMTVM=1' }
]

{ #category : #'plugin extra rules' }
CogMTFreeBSDConfig >> configureReentrantIA32FFIPlugin: maker [
	self error: 'use ThreadedIA32FFIPlugin instead'

]

{ #category : #sources }
CogMTFreeBSDConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #plugins }
CogMTFreeBSDConfig >> defaultExternalPlugins [

	^ #(
		B3DAcceleratorPlugin
		UUIDPlugin
		ThreadedIA32FFIPlugin "SqueakFFIPrims"
		"UnixOSProcessPlugin ?? "
	)
]

{ #category : #accessing }
CogMTFreeBSDConfig >> executableName [
	^ 'CogMTVM'
]

{ #category : #'source generation' }
CogMTFreeBSDConfig >> interpreterClass [
	^ CoInterpreterMT
]
