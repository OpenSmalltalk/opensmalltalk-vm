"
Hack to allow comparing method sources with specific texts
"
Class {
	#name : #TextReference,
	#superclass : #Object,
	#instVars : [
		'text',
		'selector',
		'class'
	],
	#category : #'VMMakerExtras-Tools'
}

{ #category : #'hack puns' }
TextReference >> compiledMethodAt: selector ifAbsent: aBlock [
	^nil
]

{ #category : #testing }
TextReference >> isMethodReference [
	^true
]

{ #category : #'hack puns' }
TextReference >> organization [
	^class organization
]

{ #category : #'hack puns' }
TextReference >> parserClass [
	^class parserClass
]

{ #category : #setting }
TextReference >> setClassAndSelectorIn: csBlock [

	^csBlock value: class value: selector
]

{ #category : #accessing }
TextReference >> source [
	^text
]

{ #category : #accessing }
TextReference >> sourceCode [
	^text
]

{ #category : #'hack puns' }
TextReference >> sourceMethodAt: selector ifAbsent: aBlock [
	^text
]

{ #category : #accessing }
TextReference >> sourceString [
	^text asString
]

{ #category : #'initialize-release' }
TextReference >> text: aText class: aBehavior selector: aSelector [
	text := aText.
	class := aBehavior.
	selector := aSelector
]

{ #category : #'hack puns' }
TextReference >> theNonMetaClass [
	^self
]

{ #category : #'hack puns' }
TextReference >> ultimateSourceCodeAt: selector ifAbsent: aBlock [
	^text
]
