Class {
	#name : #CCodeGeneratorInlineNeverStrategy,
	#superclass : #CCodeGeneratorAbsoluteInlineStrategy,
	#category : #'VMMaker-Slang'
}

{ #category : #asserting }
CCodeGeneratorInlineNeverStrategy >> shouldInlineMethod: aMethod [

	^ false
]
