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

{ #category : #translation }
SoundGenerationPlugin class >> monticelloDescription [
	"Override to include the AbstractSound class."
	"self monticelloDescription"
	^super monticelloDescription, '\' withCRs, (CCodeGenerator monticelloDescriptionFor: AbstractSound)
]

{ #category : #translation }
SoundGenerationPlugin class >> translatedPrimitives [
	"Answer an Array of Class, selector pair Arrays for any primitives to
	 be translated from Smalltalk methods elsewhere in the system."
	^AbstractSound translatedPrimitives
]
