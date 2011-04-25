"
This is a concrete class which generates a thread-aware VM and threaded FFI CogVM for Mac using the Cocoa library. This VM is normally known as CogMTVM.

Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #CogMTCocoaIOSConfig,
	#superclass : #CogCocoaIOSConfig,
	#category : #'CMakeVMMaker-IOS'
}

{ #category : #settings }
CogMTCocoaIOSConfig >> compilerFlagsDebug [ 
	^#('-g3' '-O0' '-msse3' "'-fvisibility=hidden'" '-funroll-loops' '-fasm-blocks' '-finline-functions' '-mfpmath=sse' '-march=pentium-m' '-falign-functions=16' '-fno-gcse' '-fno-cse-follow-jumps' '-std=gnu99' '-DBUILD_FOR_OSX' '-DUSE_INLINE_MEMORY_ACCESSORS' '-DLSB_FIRST' '-DHAVE_SYS_TIME_H' '-DHAVE_NANOSLEEP' '-DNDEBUG=1' '-DDEBUGVM=1' '-DCOGMTVM=1' '-DUSE_GLOBAL_STRUCT=0' '-DBASE_HEADER_SIZE=4' '-DCOGVM')
]

{ #category : #settings }
CogMTCocoaIOSConfig >> compilerFlagsRelease [ 
	^#('-g0' '-Os' '-msse3' "'-fvisibility=hidden'" '-funroll-loops' '-fasm-blocks' '-finline-functions' '-mfpmath=sse' '-fomit-frame-pointer' '-march=pentium-m' '-mtune=prescott' '-falign-functions=16' '-fno-gcse' '-fno-cse-follow-jumps' '-std=gnu99' '-DBUILD_FOR_OSX' '-DUSE_INLINE_MEMORY_ACCESSORS' '-DLSB_FIRST' '-DHAVE_SYS_TIME_H' '-DHAVE_NANOSLEEP' '-DNDEBUG=0' '-DDEBUGVM=0' '-DCOGMTVM=1' '-DUSE_GLOBAL_STRUCT=0' '-DBASE_HEADER_SIZE=4' '-DCOGVM')
]

{ #category : #'source files' }
CogMTCocoaIOSConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerpmt.c'
		)
]

{ #category : #accessing }
CogMTCocoaIOSConfig >> executableName [
	^ 'CogMTVM'
]

{ #category : #plugins }
CogMTCocoaIOSConfig >> ffiPluginName [ 
	^#ThreadedIA32FFIPlugin
]

{ #category : #'source generation' }
CogMTCocoaIOSConfig >> interpreterClass [
	"answer an interpreter class for VM source code generation"
	^ CoInterpreterMT
]
