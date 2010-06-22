"
I am an abstract superclass for object representations whose job it is to generate abstract instructions for accessing objects.  It is hoped that this level of indirection between the Cogit code generator and object access makes it easier to adapt the code generator to different garbage collectors, object representations and languages.
"
Class {
	#name : #CogObjectRepresentation,
	#superclass : #CogClass,
	#instVars : [
		'cogit',
		'coInterpreter'
	],
	#pools : [
		'CogMethodConstants',
		'CogRTLOpcodes',
		'VMBasicConstants',
		'VMObjectOffsets'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'instance creation' }
CogObjectRepresentation class >> for: aCogit [
	^self new setCogit: aCogit
]

{ #category : #translation }
CogObjectRepresentation class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #translation }
CogObjectRepresentation class >> typeForSelf [
	^#implicit
]

{ #category : #initialization }
CogObjectRepresentation >> setCogit: aCogit [
	<doNotGenerate>
	cogit := aCogit.
	coInterpreter := aCogit coInterpreter
]
