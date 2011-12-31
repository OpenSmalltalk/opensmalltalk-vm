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

{ #category : #'sources generation' }
CMakeGenScripts class >> generateCocoaVM [
	| platformDirectoryName |

"B3DAcceleratorPlugin" "Not using it right now"

	platformDirectoryName := (FileDirectory default 
		containingDirectory 
			directoryNamed: 'platforms') 
				fullName.
	VMMaker default 
		platformRootDirectoryName:  platformDirectoryName; 
		sourceDirectoryName: platformDirectoryName, '/iOS/vm/src';
		internal: #(
			ADPCMCodecPlugin 
			B3DEnginePlugin 
			BalloonEnginePlugin
			BitBltSimulation 
			BMPReadWriterPlugin 
			ClipboardExtendedPlugin 
			DeflatePlugin 
			DSAPlugin 
			FFIPlugin 
			FFTPlugin 
			FilePlugin 
			FloatArrayPlugin 
			GeniePlugin 
			HostWindowPlugin 
			JPEGReaderPlugin 
			JPEGReadWriter2Plugin 
			KlattSynthesizerPlugin 
			LargeIntegersPlugin 
			Matrix2x3Plugin 
			MacMenubarPlugin 
			MiscPrimitivePlugin
			NewsqueakIA32ABIPlugin 
			ObjectiveCPlugin
			RePlugin 
			SecurityPlugin 
			SocketPlugin 
			SoundCodecPlugin 
			SoundGenerationPlugin 
			SoundPlugin 
			StarSqueakPlugin 
			SurfacePlugin 
			UUIDPlugin 
			DropPlugin)	
		external: #(
			UnixOSProcessPlugin);
		generateMainVM;
		generateExternalPlugins.

	"Gnuifier"
	(Gnuifier on:((FileDirectory on: platformDirectoryName, '/iOS/vm/src/vm') pathName)) gnuify.	

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
		
	StackMacOSConfig generate.

	
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

"
Gofer new
	squeaksource: 'MetacelloRepository';
	package: 'ConfigurationOfCog';
	load.
	
((Smalltalk at: #ConfigurationOfCog) project
	version: '1.7') load.

(Smalltalk saveAs: 'generator.image') ifFalse: [
				 Smalltalk snapshot: false andQuit: true]
"

" i put it into comment to avoid double quoting "

^  thisContext  method methodNode comment first


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
