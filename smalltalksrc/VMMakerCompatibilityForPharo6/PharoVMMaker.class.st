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
PharoVMMaker >> generate: interpreterClass memoryManager: memoryManager [

	VMMakerConfiguration initializeForPharo.
	(interpreterClass bindingOf: #COGMTVM) value: false.

	[ 
	
	(VMMaker
		makerFor: interpreterClass
		and: StackToRegisterMappingCogit
		with: {#COGMTVM. false.
				#ObjectMemory. memoryManager.
				#MULTIPLEBYTECODESETS. true.
				#bytecodeTableInitializer. #initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid}
		to: self outputDirectory / 'generated'
		platformDir: self outputDirectory / 'generated'
		including: #()
		configuration: VMMakerConfiguration)
			internal: #() external: #(FilePlugin);
			doCleanupOldFiles;
			generateInterpreterFile;
			generateCogitFiles;
			generateExternalPlugins] valueSupplyingAnswer:true.
]

{ #category : #generation }
PharoVMMaker >> generateCoInterpreter [

	self generate: CoInterpreter memoryManager: #Spur64BitCoMemoryManager.
]

{ #category : #generation }
PharoVMMaker >> generateStackVM [

	self generate: StackInterpreter memoryManager: #Spur64BitMemoryManager.


]

{ #category : #accessing }
PharoVMMaker >> outputDirectory [
	^ outputDirectory
]

{ #category : #accessing }
PharoVMMaker >> outputDirectory: anObject [
	outputDirectory := anObject asFileReference
]
