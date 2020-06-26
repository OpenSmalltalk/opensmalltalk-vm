Class {
	#name : #LibFFI,
	#superclass : #VMClass,
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

{ #category : #translation }
LibFFI class >> ancilliaryClasses [ 

	^ { LibFFICIF. LibFFIType }
]

{ #category : #'call simulations' }
LibFFI >> cifAtAddress: anInteger [
	<doNotGenerate>
	^ cifs at: anInteger
]

{ #category : #'type constants' }
LibFFI >> double [
	<doNotGenerate>
	
	^ LibFFIType type: FFI_TYPE_DOUBLE size: 8 on: self.
]

{ #category : #'call simulations' }
LibFFI >> ffiCall: aCif _: externalFunctionAddress _: returnHolder _: parameters [

	<doNotGenerate>

	| retValue |
	retValue := (functions at: externalFunctionAddress)
		valueWithArguments: (aCif parametersToSmalltalk: parameters).
	^ aCif returnType fromSmalltalk: retValue putInto: returnHolder
]

{ #category : #'type constants' }
LibFFI >> float [
	<doNotGenerate>
	
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
	<doNotGenerate>	
	^ interpreter
]

{ #category : #accessing }
LibFFI >> interpreter: anInterpreter [ 
	<doNotGenerate>	
	interpreter := anInterpreter
]

{ #category : #'instance creation' }
LibFFI >> newCif [
	<doNotGenerate>	

	| cif |
	cif := LibFFICIF new.
	cif libFFI: self.
	cif address: nextAddress.
	cifs at: nextAddress put: cif.
	
	nextAddress := nextAddress + 1.
	
	^ cif
]

{ #category : #'type constants' }
LibFFI >> pointer [

	<doNotGenerate>

	^ LibFFIType type: FFI_TYPE_POINTER size: interpreter objectMemory wordSize on: self
]

{ #category : #'registering functions' }
LibFFI >> registerFunction: aBlockClosure [ 
	<doNotGenerate>	
	
	| functionAddress |
	
	functionAddress := nextAddress.
	functions at: nextAddress put: aBlockClosure.
	nextAddress := nextAddress + 1.
	
	^ functionAddress
]

{ #category : #'type constants' }
LibFFI >> void [

	<doNotGenerate>

	^ LibFFIType type: FFI_TYPE_VOID size: 0 on: self
]
