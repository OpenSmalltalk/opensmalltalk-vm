"
MTCogMacOSConfig is a concrete class which generates a thread-aware VM and threaded FFI CogVM for Mac using the Carbon library. This VM is normally known as CogMTVM.
"
Class {
	#name : #MTCogMacOSConfig,
	#superclass : #CogMacOSConfig,
	#category : #'CMakeVMMaker-MacOS'
}

{ #category : #'compiler flags' }
MTCogMacOSConfig >> commonCompilerFlags [

	"Common compiler flags"
	
	^ ' -fmessage-length=0 -Wno-trigraphs -fpascal-strings -fasm-blocks -DCOGMTVM=1 -DUSE_GLOBAL_STRUCT=0 -DTARGET_API_MAC_CARBON -DHAVE_SYS_TIME_H -mmacosx-version-min=10.5'	
	
]

{ #category : #'plugin extra rules' }
MTCogMacOSConfig >> configureReentrantIA32FFIPlugin: maker [
	self error: 'use ThreadedIA32FFIPlugin instead'

]

{ #category : #'source files' }
MTCogMacOSConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #plugins }
MTCogMacOSConfig >> defaultExternalPlugins [

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
MTCogMacOSConfig >> executableName [
	^ 'CogMTVM'
]

{ #category : #'source generation' }
MTCogMacOSConfig >> interpreterClass [
	^ CoInterpreterMT
]
