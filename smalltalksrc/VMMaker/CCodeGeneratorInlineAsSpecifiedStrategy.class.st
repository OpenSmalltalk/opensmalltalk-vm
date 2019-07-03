Class {
	#name : #CCodeGeneratorInlineAsSpecifiedStrategy,
	#superclass : #CCodeGeneratorInlineStrategy,
	#instVars : [
		'selectorsOfMethodsNotToInline'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #'as yet unclassified' }
CCodeGeneratorInlineAsSpecifiedStrategy >> initialize [

	super initialize.
	selectorsOfMethodsNotToInline := Set new.
]

{ #category : #asserting }
CCodeGeneratorInlineAsSpecifiedStrategy >> isSelectiveInlineStrategy [

	^ true
]

{ #category : #'as yet unclassified' }
CCodeGeneratorInlineAsSpecifiedStrategy >> noteSelectorNotToInline: aSelector [
	
	selectorsOfMethodsNotToInline add: aSelector
]

{ #category : #'as yet unclassified' }
CCodeGeneratorInlineAsSpecifiedStrategy >> noteSelectorsNotToInline: selectors [
	
	selectorsOfMethodsNotToInline addAll: selectors
]

{ #category : #asserting }
CCodeGeneratorInlineAsSpecifiedStrategy >> shouldInlineMethod: aMethod [

	^ (super shouldInlineMethod: aMethod) and: [ self wantsInline: aMethod ]
]

{ #category : #'as yet unclassified' }
CCodeGeneratorInlineAsSpecifiedStrategy >> shouldNotInlineSelector: aSelector [
	
	^ selectorsOfMethodsNotToInline includesKey: aSelector
]
