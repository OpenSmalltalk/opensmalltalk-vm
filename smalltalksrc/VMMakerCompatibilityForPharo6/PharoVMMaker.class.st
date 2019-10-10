"
Main entry point to generate the VM code from the command line.
"
Class {
	#name : #PharoVMMaker,
	#superclass : #Object,
	#instVars : [
		'outputDirectory'
	],
	#category : #'VMMakerCompatibilityForPharo6-CommandLine'
}

{ #category : #generation }
PharoVMMaker class >> generate: aClassName [

	self generate: aClassName outputDirectory: FileSystem workingDirectory
]

{ #category : #generation }
PharoVMMaker class >> generate: aClassName outputDirectory: aDirectory [

	Transcript 
		nextPutAll: 'Generating ';
	 	nextPutAll: aClassName printString;
		nextPutAll: ' in ';
		nextPutAll: aDirectory printString;
		nextPutAll: '...';
		cr;
		flush.
	
	self new
		outputDirectory: aDirectory;
		perform: #generate , aClassName asSymbol
]

{ #category : #generation }
PharoVMMaker >> generateCoInterpreter [

	VMMaker initializeForPharo.
	(CoInterpreter bindingOf: #COGMTVM) value: false.

	[ VMMaker
		generateMainVM: CoInterpreter
		and: StackToRegisterMappingCogit
		with: #(COGMTVM false
				ObjectMemory Spur64BitCoMemoryManager
				MULTIPLEBYTECODESETS true
				bytecodeTableInitializer initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid)
		to: self outputDirectory / 'generated'
		platformDir: self outputDirectory / 'generated'
		including: #() ] valueSupplyingAnswer:true.
]

{ #category : #generation }
PharoVMMaker >> generateCoInterpreterMT [

	VMMaker initializeForPharo.
	[VMMaker
		generateMainVM: CoInterpreterMT
		and: StackToRegisterMappingCogit
		with: #(COGMTVM true
				ObjectMemory Spur64BitCoMemoryManager
				MULTIPLEBYTECODESETS true
				bytecodeTableInitializer initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid)
		to: self outputDirectory / 'generated'
		platformDir: self outputDirectory / 'generated'
		including:#()] valueSupplyingAnswer: true.
]

{ #category : #generation }
PharoVMMaker >> generateCoInterpreterWithQueueFFI [

	| interpreterClass | 

	VMMaker initializeForPharo.
	interpreterClass := CoInterpreterWithQueueFFI.
	(interpreterClass bindingOf: #COGMTVM) value: false.

	[ VMMaker
		generateMainVM: interpreterClass
		and: StackToRegisterMappingCogit
		with: #(COGMTVM false
				ObjectMemory Spur64BitCoMemoryManager
				MULTIPLEBYTECODESETS true
				bytecodeTableInitializer initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid)
		to: self outputDirectory / 'generated'
		platformDir: self outputDirectory / 'generated'
		including: #() ] valueSupplyingAnswer:true.
]

{ #category : #generation }
PharoVMMaker >> generateStackVM [

	| interpreterClass | 

	VMMaker initializeForPharo.
	interpreterClass := StackInterpreter.
	(interpreterClass bindingOf: #COGMTVM) value: false.

	[ VMMaker
		generateMainVM: interpreterClass
		and: StackToRegisterMappingCogit
		with: #(COGMTVM false
				ObjectMemory Spur64BitMemoryManager
				MULTIPLEBYTECODESETS true
				bytecodeTableInitializer initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid)
		to: self outputDirectory / 'generated'
		platformDir: self outputDirectory / 'generated'
		including: #() ] valueSupplyingAnswer:true.
]

{ #category : #accessing }
PharoVMMaker >> outputDirectory [
	^ outputDirectory
]

{ #category : #accessing }
PharoVMMaker >> outputDirectory: anObject [
	outputDirectory := anObject asFileReference
]
