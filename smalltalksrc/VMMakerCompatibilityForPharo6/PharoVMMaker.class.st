"
Main entry point to generate the VM code from the command line.
"
Class {
	#name : #PharoVMMaker,
	#superclass : #Object,
	#instVars : [
		'outputDirectory',
		'stopOnErrors'
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

	| platformDirectory |
	
	Author useAuthor: 'vmMaker' during: [
	
		VMMakerConfiguration initializeForPharo.
		(interpreterClass bindingOf: #COGMTVM) value: false.

		platformDirectory := self platformDirectoryFor: memoryManager.

		[ 
		
		(VMMaker
			makerFor: interpreterClass
			and: StackToRegisterMappingCogit
			with: {#COGMTVM. false.
					#ObjectMemory. memoryManager name.
					#MULTIPLEBYTECODESETS. true.
					#bytecodeTableInitializer. #initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid}
			to: platformDirectory
			platformDir:platformDirectory
			including: #()
			configuration: VMMakerConfiguration)
				stopOnErrors: stopOnErrors;
				internal: #() external: #(FilePlugin);
				generateInterpreterFile;
				generateCogitFiles;
				generateExternalPlugins] valueSupplyingAnswer:true.]
]

{ #category : #generation }
PharoVMMaker >> generateCoInterpreter [

	self generate: CoInterpreter memoryManager: Spur64BitCoMemoryManager.
	self generate: CoInterpreter memoryManager: Spur32BitCoMemoryManager.	
]

{ #category : #generation }
PharoVMMaker >> generateStackVM [

	self generate: StackInterpreter memoryManager: Spur64BitMemoryManager.
	self generate: StackInterpreter memoryManager: Spur32BitMemoryManager.


]

{ #category : #accessing }
PharoVMMaker >> initialize [
	super initialize.
	stopOnErrors := false
]

{ #category : #accessing }
PharoVMMaker >> outputDirectory [
	^ outputDirectory
]

{ #category : #accessing }
PharoVMMaker >> outputDirectory: anObject [
	outputDirectory := anObject asFileReference
]

{ #category : #utils }
PharoVMMaker >> platformDirectoryFor: aMemoryManagerClass [ 
	
	^ self outputDirectory / 'generated' / (aMemoryManagerClass wordSize * 8) asString
]

{ #category : #accessing }
PharoVMMaker >> stopOnErrors [
	^ stopOnErrors
]

{ #category : #accessing }
PharoVMMaker >> stopOnErrors: anObject [
	stopOnErrors := anObject
]
