"
I provide access to the Bochs C++ IA32 processor emulator.
"
Class {
	#name : #BochsIA32Plugin,
	#superclass : #BochsPlugin,
	#category : #'Cog-ProcessorPlugins'
}

{ #category : #translation }
BochsIA32Plugin class >> declareCVarsIn: aCCodeGenerator [
	"prevInterruptCheckChain lives in sqBochsIA32Plugin.c"
	super declareCVarsIn: aCCodeGenerator.
	aCCodeGenerator removeVariable: 'prevInterruptCheckChain'
]

{ #category : #translation }
BochsIA32Plugin class >> hasHeaderFile [
	"We need a header to declare newcpu and pull in bochs.h & cpu.h"
	^true
]
