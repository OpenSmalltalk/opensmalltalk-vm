"
Main entry point to generate the VM code from the command line.
"
Class {
	#name : #PharoVMMaker,
	#superclass : #Object,
	#category : #'VMMakerCompatibilityForPharo6-CommandLine'
}

{ #category : #generation }
PharoVMMaker class >> generate: aClassName [

	Transcript 
		nextPutAll: 'Generating ';
	 	nextPutAll: aClassName printString;
		nextPutAll: '...';
		cr;
		flush.
		
	self perform: #generate , aClassName asSymbol
]

{ #category : #generation }
PharoVMMaker class >> generateCoInterpreter [

	VMMaker initializeForPharo.
	(CoInterpreter bindingOf: #COGMTVM) value: false.

	[ VMMaker
		generateMainVM: CoInterpreter
		and: StackToRegisterMappingCogit
		with: #(COGMTVM false
				ObjectMemory Spur64BitCoMemoryManager
				MULTIPLEBYTECODESETS true
				bytecodeTableInitializer initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid)
		to: FileSystem workingDirectory / 'generated'
		platformDir: FileSystem workingDirectory / 'generated'
		including: #() ] valueSupplyingAnswer:true.
]

{ #category : #generation }
PharoVMMaker class >> generateCoInterpreterMT [

	VMMaker initializeForPharo.
	[VMMaker
		generateMainVM: CoInterpreterMT
		and: StackToRegisterMappingCogit
		with: #(COGMTVM true
				ObjectMemory Spur64BitCoMemoryManager
				MULTIPLEBYTECODESETS true
				bytecodeTableInitializer initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid)
		to: FileSystem workingDirectory parent / 'extracted'
		platformDir: FileSystem workingDirectory parent / 'extracted'
		including:#()] valueSupplyingAnswer: true.
]

{ #category : #generation }
PharoVMMaker class >> generateCoInterpreterWithQueueFFI [

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
		to: FileSystem workingDirectory / 'generated'
		platformDir: FileSystem workingDirectory / 'generated'
		including: #() ] valueSupplyingAnswer:true.
]
