Class {
	#name : #MTCogFreeBSDConfig,
	#superclass : #CogFreeBSDConfig,
	#category : #'CMakeVMMaker-FreeBSD-Cog'
}

{ #category : #'compiler flags' }
MTCogFreeBSDConfig >> commonCompilerFlags [

	"Common compiler flags
	
	
	LSB_FIRST=1 means that target platform is little endian. 
	set it to 0 for big-endian platforms
	
	"
	
	^ ' -DLSB_FIRST=1 -DUSE_GLOBAL_STRUCT=0 -DCOGMTVM=1'	
	
]

{ #category : #'plugin extra rules' }
MTCogFreeBSDConfig >> configureReentrantIA32FFIPlugin: maker [
	self error: 'use ThreadedIA32FFIPlugin instead'

]

{ #category : #sources }
MTCogFreeBSDConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #plugins }
MTCogFreeBSDConfig >> defaultExternalPlugins [

	^ #(
		B3DAcceleratorPlugin
		UUIDPlugin
		ThreadedIA32FFIPlugin "SqueakFFIPrims"
		"UnixOSProcessPlugin ?? "
	)
]

{ #category : #accessing }
MTCogFreeBSDConfig >> executableName [
	^ 'CogMTVM'
]

{ #category : #'source generation' }
MTCogFreeBSDConfig >> interpreterClass [
	^ CoInterpreterMT
]
