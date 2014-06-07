"
This is a concrete class which generates a thread-aware VM and threaded FFI CogVM for Unix. This VM is normally known as CogMTVM.

For more information, check the class comments of all the superclasses.

Linux32x86SqueakCogV3MultiThreadedConfig generateWithSources.
Linux32x86SqueakCogV3MultiThreadedConfig generate.

"
Class {
	#name : #Linux32x86SqueakCogV3MultiThreadedConfig,
	#superclass : #Linux32x86SqueakCogV3Config,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #'squeak compatibility' }
Linux32x86SqueakCogV3MultiThreadedConfig >> buildDirName [
	^ 'cmake_unixbuild/mtbld'
]

{ #category : #'compiler flags' }
Linux32x86SqueakCogV3MultiThreadedConfig >> commonCompilerFlags [

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
Linux32x86SqueakCogV3MultiThreadedConfig >> configureReentrantIA32FFIPlugin: maker [
	self error: 'use ThreadedIA32FFIPlugin instead'

]

{ #category : #sources }
Linux32x86SqueakCogV3MultiThreadedConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #plugins }
Linux32x86SqueakCogV3MultiThreadedConfig >> defaultExternalPlugins [
	^ (super defaultExternalPlugins copyWithoutAll: #(#ThreadedIA32FFIPlugin #InternetConfigPlugin))


]

{ #category : #accessing }
Linux32x86SqueakCogV3MultiThreadedConfig >> executableName [
	^ 'CogMTVM'
]

{ #category : #'source generation' }
Linux32x86SqueakCogV3MultiThreadedConfig >> interpreterClass [
	^ CoInterpreterMT
]
