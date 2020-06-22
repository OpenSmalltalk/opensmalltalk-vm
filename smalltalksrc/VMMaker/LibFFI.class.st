Class {
	#name : #LibFFI,
	#superclass : #Object,
	#instVars : [
		'nextAddress',
		'cifs',
		'functions',
		'interpreter'
	],
	#pools : [
		'LibFFIConstants'
	],
	#category : #'VMMaker-FFI'
}

{ #category : #types }
LibFFI >> FFI_TYPE_FLOAT [
	
	^ FFI_TYPE_FLOAT
]

{ #category : #'accessing objects' }
LibFFI >> cifAtAddress: anInteger [ 
	
	^ cifs at: anInteger
]

{ #category : #'call simulations' }
LibFFI >> ffiCall: aCif _: externalFunctionAddress _: returnHolder _: parameters [

	| retValue |

	retValue := (functions at: externalFunctionAddress)
		valueWithArguments: (aCif parametersToSmalltalk: parameters).

	^ aCif returnType fromSmalltalk: retValue putInto: returnHolder
]

{ #category : #'instance creation' }
LibFFI >> float [
	
	^ LibFFIType type: FFI_TYPE_FLOAT size: 4 on: self.
]

{ #category : #'instance creation' }
LibFFI >> initialize [

	super initialize.
	cifs := Dictionary new.
	functions := Dictionary new.
	nextAddress := 1.

]

{ #category : #accessing }
LibFFI >> interpreter [
	^ interpreter
]

{ #category : #accessing }
LibFFI >> interpreter: anInterpreter [ 
	
	interpreter := anInterpreter
]

{ #category : #'instance creation' }
LibFFI >> newCif [
	
	| cif |
	cif := LibFFICIF new.
	cif libFFI: self.
	cif address: nextAddress.
	cifs at: nextAddress put: cif.
	
	nextAddress := nextAddress + 1.
	
	^ cif
]

{ #category : #'registering functions' }
LibFFI >> registerFunction: aBlockClosure [ 
	
	| functionAddress |
	
	functionAddress := nextAddress.
	functions at: nextAddress put: aBlockClosure.
	nextAddress := nextAddress + 1.
	
	^ functionAddress
]

{ #category : #'type constants' }
LibFFI >> void [

	^ LibFFIType type: FFI_TYPE_VOID size: 0 on: self
]
