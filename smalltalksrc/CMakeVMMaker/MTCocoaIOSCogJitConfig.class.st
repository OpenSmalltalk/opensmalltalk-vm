"
This config for building Thread-aware VM and threaded FFI
"
Class {
	#name : #MTCocoaIOSCogJitConfig,
	#superclass : #CocoaIOSCogJitConfig,
	#category : #'CMakeVMMaker-IOS'
}

{ #category : #settings }
MTCocoaIOSCogJitConfig >> compilerFlagsDebug [ 
	^#('-O0' '-fvisibility=hidden' '-funroll-loops' '-fasm-blocks' '-finline-functions' '-mfpmath=sse' '-fomit-frame-pointer' '-march=pentium-m' '-falign-functions=16' '-fno-gcse' '-fno-cse-follow-jumps' '-std=gnu99' '-DBUILD_FOR_OSX' '-DUSE_INLINE_MEMORY_ACCESSORS' '-DLSB_FIRST' '-DHAVE_SYS_TIME_H' '-DHAVE_NANOSLEEP' '-DNDEBUG=0' '-DDEBUGVM=1' '-DCOGMTVM=1' '-DUSE_GLOBAL_STRUCT=0' '-DBASE_HEADER_SIZE=4' '-DCOGVM')
]

{ #category : #settings }
MTCocoaIOSCogJitConfig >> compilerFlagsRelease [ 
	^#('-g1' '-O3' '-fvisibility=hidden' '-funroll-loops' '-fasm-blocks' '-finline-functions' '-mfpmath=sse' '-fomit-frame-pointer' '-march=pentium-m' '-mtune=prescott' '-falign-functions=16' '-fno-gcse' '-fno-cse-follow-jumps' '-std=gnu99' '-DBUILD_FOR_OSX' '-DUSE_INLINE_MEMORY_ACCESSORS' '-DLSB_FIRST' '-DHAVE_SYS_TIME_H' '-DHAVE_NANOSLEEP' '-DNDEBUG=0' '-DDEBUGVM=1' '-DCOGMTVM=1' '-DUSE_GLOBAL_STRUCT=0' '-DBASE_HEADER_SIZE=4' '-DCOGVM')
]

{ #category : #'source files' }
MTCocoaIOSCogJitConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #accessing }
MTCocoaIOSCogJitConfig >> executableName [
	^ 'CogMTVM'
]

{ #category : #plugins }
MTCocoaIOSCogJitConfig >> ffiPluginName [ 
	^#ThreadedIA32FFIPlugin
]

{ #category : #'source generation' }
MTCocoaIOSCogJitConfig >> interpreterClass [
	"answer an interpreter class for VM source code generation"
	^ CoInterpreterMT
]
