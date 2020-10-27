Class {
	#name : #CCodeGeneratorInlineNeverStrategy,
	#superclass : #CCodeGeneratorAbsoluteInlineStrategy,
	#category : #Slang
}

{ #category : #asserting }
CCodeGeneratorInlineNeverStrategy >> shouldInlineMethod: aMethod [

	^ false
]
