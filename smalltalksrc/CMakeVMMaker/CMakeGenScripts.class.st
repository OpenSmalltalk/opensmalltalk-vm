"
This class is a collection of scripts for generating both
C source files (using VMMaker) and Cmake files.
"
Class {
	#name : #CMakeGenScripts,
	#superclass : #Object,
	#category : #CMakeVMMaker
}

{ #category : #'scripts generation' }
CMakeGenScripts class >> fileout: aString to: aFileName [

	" put that file to ../codegen-scripts directory "
	
 	(FileStream forceNewFileNamed: aFileName) 
		nextPutAll: aString;
		close.
	
]

{ #category : #'scripts generation' }
CMakeGenScripts class >> fileoutLoaderScript [
"self fileoutLoaderScript"


	" put that file to ../codegen-scripts directory "
	
	self fileout: self loaderScript to: self loaderScriptName.
]

{ #category : #'as yet unclassified' }
CMakeGenScripts class >> generateCogMacOS [
	" generate sources for Stack Interpreter of Mac OS"
	| top |
	top := FileDirectory default containingDirectory.				
	
	VMMaker
		generate: CoInterpreter
		to: (top / 'src') fullName
		platformDir: ( top / 'platforms') fullName
		excluding:#(BrokenPlugin IA32ABIPluginSimulator SlangTestPlugin TestOSAPlugin
					FFIPlugin ReentrantARMFFIPlugin ReentrantFFIPlugin ReentrantPPCBEFFIPlugin).
						
	CogMacOSConfig generate.

	
]

{ #category : #'sources generation' }
CMakeGenScripts class >> generateCogSources [
	" self generateCogSources "

	" generate sources for CoInterpreter"

	| top |
	
	CogRTLOpcodes initialize.
	CogIA32Compiler initialize.
	
	top := FileDirectory default containingDirectory.				
	
	VMMaker
		generate: CoInterpreter
		and: StackToRegisterMappingCogit
		to: (top / 'src') fullName
		platformDir: ( top / 'platforms') fullName
		excluding:#(BrokenPlugin IA32ABIPluginSimulator SlangTestPlugin TestOSAPlugin
					FFIPlugin ReentrantARMFFIPlugin ReentrantFFIPlugin ReentrantPPCBEFFIPlugin NewsqueakIA32ABIPlugin
					 NewsqueakIA32ABIPluginAttic).

]

{ #category : #'sources generation' }
CMakeGenScripts class >> generateCogSources: config [
	" self generateCogSources "

	" generate sources for CoInterpreter"

	| top src |
	
	CogRTLOpcodes initialize.
	CogIA32Compiler initialize.
	
	top := config topDir.				
	src := config srcDir assureExistence fullName.
	
	VMMaker
		generate: CoInterpreter
		and: StackToRegisterMappingCogit
		to: src
		platformDir: ( top / 'platforms') fullName
		excluding:#(BrokenPlugin IA32ABIPluginSimulator SlangTestPlugin TestOSAPlugin
					FFIPlugin ReentrantARMFFIPlugin ReentrantFFIPlugin ReentrantPPCBEFFIPlugin NewsqueakIA32ABIPlugin
					 NewsqueakIA32ABIPluginAttic).

]

{ #category : #'sources generation' }
CMakeGenScripts class >> generateCogSourcesEmm40 [
	" self generateCogSourcesEmm40 "


	" generate sources for CoInterpreter"

	| top |
	
	CogRTLOpcodes initialize.
	CogIA32Compiler initialize.
	
	top := FileDirectory default containingDirectory.				
	
	VMMaker
		generate: CoInterpreter
		and: StackToRegisterMappingCogit
		to: (top / 'src') fullName
		platformDir: ( top / 'platforms') fullName
		excluding:#(BrokenPlugin IA32ABIPluginSimulator SlangTestPlugin TestOSAPlugin
					FFIPlugin ReentrantARMFFIPlugin ReentrantFFIPlugin 					ReentrantPPCBEFFIPlugin NewsqueakIA32ABIPlugin
					 NewsqueakIA32ABIPluginAttic).

]

{ #category : #'as yet unclassified' }
CMakeGenScripts class >> generateStackMacOS [
	" generate sources for Stack Interpreter of Mac OS"
	self generateStackSources.
		
	StackInterpreterMacOSConfig generate.

	
]

{ #category : #'sources generation' }
CMakeGenScripts class >> generateStackSources [
	" generate sources for Stack Interpreter of Mac OS"
	| top |
	top := FileDirectory default containingDirectory.
	
	VMMaker
		generate: StackInterpreter
		to: (top / 'src') fullName
		platformDir: ( top / 'platforms') fullName
		excluding: #(BrokenPlugin IA32ABIPluginSimulator SlangTestPlugin TestOSAPlugin
			FFIPlugin ReentrantARMFFIPlugin ReentrantFFIPlugin ReentrantPPCBEFFIPlugin).
			
	

	
]

{ #category : #'scripts generation' }
CMakeGenScripts class >> loaderScript [
	
	" take a necessary files from their respective locations" 

	| s |
	
	s := #(
		'http://source.squeak.org/FFI' 'FFI-Pools'
		'http://www.squeaksource.com/Speech'  'SharedPool-Speech'
		'http://www.squeaksource.com/VMMaker' 'VMMaker'
		'http://www.squeaksource.com/VMMaker' 'CMakeVMMaker'
	) readStream.
	
	^ String streamContents: [:str |
		str nextPutAll: 'Smalltalk isInteractive ifTrue: [
			Smalltalk snapshot: false andQuit: true.
			].'; cr.
		[ s atEnd ] whileFalse: [
			str nextPutAll: '((MCHttpRepository 	location: ''';
				nextPutAll: s next;
				nextPutAll: ''' user: '''' password: '''')' ; cr;
				nextPutAll: 'versionFromFileNamed: ' , (self mcPackage: s next) printString;
				nextPutAll: ') load.'; cr;cr
				
			].
				str nextPutAll: '(Smalltalk saveAs: ''generator.image'') ifFalse: [
				 Smalltalk snapshot: false andQuit: true]'.
		]
]

{ #category : #'scripts generation' }
CMakeGenScripts class >> loaderScriptName [
	^ 'LoadVMMaker.st'
]

{ #category : #'scripts generation' }
CMakeGenScripts class >> mcPackage: name [
	
	|pkg|
	pkg := MCWorkingCopy allManagers detect: [:ea | ea packageName = name ].
	
	^ pkg ancestry ancestorString , '.mcz'
	
]

{ #category : #'as yet unclassified' }
CMakeGenScripts >> seeClassSide [
]
