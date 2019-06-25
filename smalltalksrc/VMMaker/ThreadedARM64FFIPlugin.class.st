"
A ThreadedARM64FFIPlugin is for the 64-bit ARM ABI.  It typically has 8 integer registers

Instance Variables

"
Class {
	#name : #ThreadedARM64FFIPlugin,
	#superclass : #ThreadedARMFFIPlugin,
	#category : #'VMMaker-Plugins-FFI'
}

{ #category : #translation }
ThreadedARM64FFIPlugin class >> identifyingPredefinedMacros [
	^#('__ARM_ARCH_ISA_A64' '__aarch64__' '__arm64__' 'ARM64')
]

{ #category : #'class initialization' }
ThreadedARM64FFIPlugin class >> initialize [
	super initialize.
	NumIntRegArgs     := 8.
	NumFloatRegArgs := 16
]

{ #category : #translation }
ThreadedARM64FFIPlugin class >> moduleName [
	^'ARM64FFIPlugin'
]

{ #category : #'simulation support' }
ThreadedARM64FFIPlugin >> wordSize [

	^ 8  "arm64/aarch64"
]
