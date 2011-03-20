"
MTCogMacOSConfig generateWithSources
"
Class {
	#name : #MTCogMacOSConfig,
	#superclass : #CogMacOSConfig,
	#category : #'CMakeVMMaker-MacOS'
}

{ #category : #'as yet unclassified' }
MTCogMacOSConfig >> commonCompilerFlags [

	"Common compiler flags"
	
	^ ' -fmessage-length=0 -Wno-trigraphs -fpascal-strings -fasm-blocks -DCOGMTVM=1 -DUSE_GLOBAL_STRUCT=0 -DTARGET_API_MAC_CARBON -DHAVE_SYS_TIME_H -mmacosx-version-min=10.5'	
	
]

{ #category : #'as yet unclassified' }
MTCogMacOSConfig >> configureReentrantIA32FFIPlugin: maker [
	self error: 'use ThreadedIA32FFIPlugin instead'

]

{ #category : #'as yet unclassified' }
MTCogMacOSConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #'as yet unclassified' }
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

{ #category : #'as yet unclassified' }
MTCogMacOSConfig >> interpreterClass [
	^ CoInterpreterMT
]
