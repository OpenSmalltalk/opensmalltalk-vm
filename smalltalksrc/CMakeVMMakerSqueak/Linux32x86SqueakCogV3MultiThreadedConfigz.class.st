"
This is a concrete class which generates a thread-aware VM and threaded FFI CogVM for Unix. This VM is normally known as CogMTVM.

For more information, check the class comments of all the superclasses.

Linux32x86SqueakCogV3MultiThreadedConfig generateWithSources.
Linux32x86SqueakCogV3MultiThreadedConfig generate.

"
Class {
	#name : #Linux32x86SqueakCogV3MultiThreadedConfigz,
	#superclass : #Linux32x86Config,
	#category : #'CMakeVMMakerSqueak-IslandOfMisfitToys'
}

{ #category : #'squeak compatibility' }
Linux32x86SqueakCogV3MultiThreadedConfigz >> buildDirName [
	^ 'cmake_unixbuild/mtbld'
]

{ #category : #'compiler flags' }
Linux32x86SqueakCogV3MultiThreadedConfigz >> commonCompilerFlags [

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
Linux32x86SqueakCogV3MultiThreadedConfigz >> configureReentrantIA32FFIPlugin: maker [
	self error: 'use ThreadedIA32FFIPlugin instead'

]

{ #category : #sources }
Linux32x86SqueakCogV3MultiThreadedConfigz >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #plugins }
Linux32x86SqueakCogV3MultiThreadedConfigz >> defaultExternalPlugins [
	^ (super defaultExternalPlugins copyWithoutAll: #(#ThreadedIA32FFIPlugin #InternetConfigPlugin))


]

{ #category : #cmake }
Linux32x86SqueakCogV3MultiThreadedConfigz >> excludeFromBuild [
"	^false"   "build this configuration"
	^true


]

{ #category : #accessing }
Linux32x86SqueakCogV3MultiThreadedConfigz >> executableName [
	^ 'CogMTVM'
]

{ #category : #'source generation' }
Linux32x86SqueakCogV3MultiThreadedConfigz >> interpreterClass [
	^ CoInterpreterMT
]
