Class {
	#name : #CCodeGeneratorInlineNeverStrategy,
	#superclass : #CCodeGeneratorAbsoluteInlineStrategy,
	#category : #'Slang-CodeGeneration'
}

{ #category : #asserting }
CCodeGeneratorInlineNeverStrategy >> shouldInlineMethod: aMethod [

	^ false
]
