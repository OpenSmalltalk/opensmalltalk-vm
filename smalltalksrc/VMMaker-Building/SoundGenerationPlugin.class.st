"
This class is a stub for the directly generated primitives in AbstractSound and subclasses.
"
Class {
	#name : #SoundGenerationPlugin,
	#superclass : #InterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
SoundGenerationPlugin class >> declareCVarsIn: cg [
	cg addHeaderFile: '"SoundGenerationPlugin.h"'.
]

{ #category : #accessing }
SoundGenerationPlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #accessing }
SoundGenerationPlugin class >> translateInDirectory: directory doInlining: inlineFlag [
"handle a special case code string rather than generated code. 
NB sqOldSoundsPrims IS NOT FULLY INTEGRATED - it still isn't included in the exports list"
	| cg |
	self initialize.

	cg := self buildCodeGeneratorUpTo: InterpreterPlugin.

	cg addMethodsForPrimitives: AbstractSound translatedPrimitives.
	self storeString: cg generateCodeStringForPrimitives onFileNamed: (directory fullNameFor: self moduleName, '.c').
	"What we need here is some way to derive the prim names from sqOldSoundPrims - or dump it entirely. Perhaps add this class (without then generating the file again) using fake entry points like SurfacePlugin does"

	^cg exportedPrimitiveNames asArray

]
