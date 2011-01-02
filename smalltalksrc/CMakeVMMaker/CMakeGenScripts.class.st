"
This class is a collection of scripts for generating both
C source files (using VMMaker) and Cmake files.
"
Class {
	#name : #CMakeGenScripts,
	#superclass : #Object,
	#category : #CMakeVMMaker
}

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

{ #category : #'as yet unclassified' }
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

{ #category : #'as yet unclassified' }
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

{ #category : #'as yet unclassified' }
CMakeGenScripts >> seeClassSide [
]
