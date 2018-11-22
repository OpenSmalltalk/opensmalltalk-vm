"
This is a concrete class which generates a thread-aware VM and threaded FFI CogVM for Mac using the Carbon library. This VM is normally known as CogMTVM.

Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #CogMTMacOSConfig,
	#superclass : #CogMacOSConfig,
	#category : #'CMakeVMMaker-MacOS'
}

{ #category : #'compiler flags' }
CogMTMacOSConfig >> commonCompilerFlags [

	"Common compiler flags"
	
	^ { 
		'-fmessage-length=0'.
		'-Wno-trigraphs'. 
		'-fpascal-strings'. 
		'-fasm-blocks'. 
		'-DCOGMTVM=1'.
		'-DUSE_GLOBAL_STRUCT=0'.
		'-DTARGET_API_MAC_CARBON'.
		'-DHAVE_SYS_TIME_H'.
		'-mmacosx-version-min=10.5' }
]

{ #category : #'plugin extra rules' }
CogMTMacOSConfig >> configureReentrantIA32FFIPlugin: maker [
	self error: 'use ThreadedIA32FFIPlugin instead'

]

{ #category : #'source files' }
CogMTMacOSConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #plugins }
CogMTMacOSConfig >> defaultExternalPlugins [

	^ #(
		BochsIA32Plugin
		CroquetPlugin
		ThreadedIA32FFIPlugin "SqueakFFIPrims"
		FloatArrayPlugin
		FloatMathPlugin
		Mpeg3Plugin
		"UnixOSProcessPlugin ?? "
	)
]

{ #category : #accessing }
CogMTMacOSConfig >> executableName [
	^ 'CogMTVM'
]

{ #category : #'source generation' }
CogMTMacOSConfig >> interpreterClass [
	^ CoInterpreterMT
]
