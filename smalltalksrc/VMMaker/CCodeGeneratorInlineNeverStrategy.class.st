Class {
	#name : #CCodeGeneratorInlineNeverStrategy,
	#superclass : #CCodeGeneratorAbsoluteInlineStrategy,
	#category : #'VMMaker-Translation to C'
}

{ #category : #asserting }
CCodeGeneratorInlineNeverStrategy >> shouldInlineMethod: aMethod [

	^ false
]
