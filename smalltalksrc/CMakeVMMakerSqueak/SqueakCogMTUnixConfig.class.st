"
This is a concrete class which generates a thread-aware VM and threaded FFI CogVM for Unix. This VM is normally known as CogMTVM.

For more information, check the class comments of all the superclasses.

SqueakCogMTUnixConfig generateWithSources.
SqueakCogMTUnixConfig generate.

"
Class {
	#name : #SqueakCogMTUnixConfig,
	#superclass : #SqueakCogUnixConfig,
	#category : #'CMakeVMMakerSqueak-Unix'
}

{ #category : #'squeak compatibility' }
SqueakCogMTUnixConfig >> buildDirName [
	^ 'cmake_unixbuild/mtbld'
]

{ #category : #'compiler flags' }
SqueakCogMTUnixConfig >> commonCompilerFlags [

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
SqueakCogMTUnixConfig >> configureReentrantIA32FFIPlugin: maker [
	self error: 'use ThreadedIA32FFIPlugin instead'

]

{ #category : #sources }
SqueakCogMTUnixConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #plugins }
SqueakCogMTUnixConfig >> defaultExternalPlugins [
	^ (super defaultExternalPlugins copyWithoutAll: #(#ThreadedIA32FFIPlugin #InternetConfigPlugin))


]

{ #category : #accessing }
SqueakCogMTUnixConfig >> executableName [
	^ 'CogMTVM'
]

{ #category : #'source generation' }
SqueakCogMTUnixConfig >> interpreterClass [
	^ CoInterpreterMT
]
