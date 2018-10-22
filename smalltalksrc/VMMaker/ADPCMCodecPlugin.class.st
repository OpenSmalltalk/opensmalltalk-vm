"
This is a kludgy interface to the translated primitive code in ADPCMCodec. The translate.... method gathers the code and writes it to a file. No methods in this class actually implement the codec.
"
Class {
	#name : #ADPCMCodecPlugin,
	#superclass : #InterpreterPlugin,
	#category : 'VMMaker-Plugins'
}

{ #category : #translation }
ADPCMCodecPlugin class >> methodsToBePruned [
	"Since sharing between plugins means that normal pruning
	 can't be done, allow plugins that want to prune specific methods."
	^#(indexForDeltaFrom:to: nextBits: nextBits:put:)
]

{ #category : #translation }
ADPCMCodecPlugin class >> monticelloDescription [
	"Override to include the ADPCMCodec class."
	"self monticelloDescription"
	^super monticelloDescription, '\' withCRs, (CCodeGenerator monticelloDescriptionFor: ADPCMCodec)
]

{ #category : #translation }
ADPCMCodecPlugin class >> translatedPrimitives [
	"Answer an Array of Class, selector pair Arrays for any primitives to
	 be translated from Smalltalk methods elsewhere in the system."
	^ADPCMCodec translatedPrimitives
]
