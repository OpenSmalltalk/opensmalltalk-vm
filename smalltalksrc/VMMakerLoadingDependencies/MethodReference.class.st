"
A MethodReference is is a lightweight proxy for a CompiledMethod.  Has methods for pointed to the CompileMethod's source statements, byte codes. Is heavily used by Tools.

Instance Variables
	classIsMeta:		     Boolean class vs. instance
	classSymbol:		Symbol for method's class (without class keyword if meta)
	methodSymbol:		Symbol for method's selector
	stringVersion:		'Class>>selector:' format
"
Class {
	#name : #MethodReference,
	#superclass : #Object,
	#instVars : [
		'classSymbol',
		'classIsMeta',
		'methodSymbol',
		'stringVersion',
		'category',
		'environment'
	],
	#classVars : [
		'InvalidReference'
	],
	#category : #VMMakerLoadingDependencies
}

{ #category : #'instance creation' }
MethodReference class >> class: aClass selector: aSelector [
	^ self class: aClass selector: aSelector environment: aClass environment.
]

{ #category : #'instance creation' }
MethodReference class >> class: aClass selector: aSelector environment: anEnvironment [
	^ self new setStandardClass: aClass methodSymbol: aSelector environment: anEnvironment.
]

{ #category : #'class initialization' }
MethodReference class >> cleanUp: aggressive [

	aggressive ifTrue: [InvalidReference := nil].
]

{ #category : #'instance creation' }
MethodReference class >> invalid [
	"Creates an invalid method reference to avoid the usage of nil."
	
	^ InvalidReference ifNil: [
		InvalidReference := self new
			setClassSymbol: #NonExistentClass
			classIsMeta: false
			methodSymbol: #nonExistentSelector
			stringVersion: '<The Invalid Method Reference>']
]

{ #category : #comparing }
MethodReference >> <= anotherMethodReference [

	classSymbol < anotherMethodReference classSymbol ifTrue: [^true].
	classSymbol > anotherMethodReference classSymbol ifTrue: [^false].
	classIsMeta = anotherMethodReference classIsMeta ifFalse: [^classIsMeta not].
	^methodSymbol <= anotherMethodReference methodSymbol
]

{ #category : #comparing }
MethodReference >> = anotherMethodReference [ 
	"Answer whether the receiver and the argument represent the 
	same object."
	^ self species == anotherMethodReference species
		and: [self classSymbol = anotherMethodReference classSymbol
		and: [self classIsMeta = anotherMethodReference classIsMeta
		and: [self methodSymbol = anotherMethodReference methodSymbol
		and: [self environment == anotherMethodReference environment]]]]
]

{ #category : #accessing }
MethodReference >> actualClass [ 
	^self environment at: classSymbol ifPresent: [ :actualClass |
		classIsMeta
			ifTrue: [ actualClass classSide ]
			ifFalse: [ actualClass ] ]
]

{ #category : #converting }
MethodReference >> asCodeReference [

	^ self
]

{ #category : #converting }
MethodReference >> asString [

	^(stringVersion ifNil: [ self stringVersionDefault ]) asString
]

{ #category : #converting }
MethodReference >> asStringOrText [

	^stringVersion ifNil: [ self stringVersionDefault ]
]

{ #category : #converting }
MethodReference >> asValid [
	"Sometimes persistent MethodReferences may become stale after a refactoring which moved some methods to a superclass.  This method answers the new valid MethodReference if that happened."
	^ self isValid
		ifTrue: [ self ]
		ifFalse:
			[ | cm |
			cm := self actualClass lookupSelector: self selector.
			cm ifNotNil: [ cm methodReference ] ]
]

{ #category : #accessing }
MethodReference >> category [
	"Answers the class category (cached for reuse via MC and other tools)"
	^ category ifNil: [category := self actualClass organization categoryOfElement: methodSymbol]
]

{ #category : #'initialize-release' }
MethodReference >> category: aSymbol [
	category := aSymbol
]

{ #category : #testing }
MethodReference >> classIsMeta [

	^classIsMeta
]

{ #category : #accessing }
MethodReference >> classSymbol [

	^classSymbol
]

{ #category : #accessing }
MethodReference >> compiledMethod [
	^self actualClass compiledMethodAt: methodSymbol ifAbsent: nil
]

{ #category : #accessing }
MethodReference >> environment [
	^ environment ifNil: [
		"We will probably have MethodReferences already instantiated when this commit lands. We lazily move these over to the new, Environment aware, order of things."
		environment := Smalltalk globals].
]

{ #category : #comparing }
MethodReference >> hash [
	"Answer a SmallInteger whose value is related to the receiver's  
	identity."
	^ (self species hash bitXor: self classSymbol hash)
		bitXor: self methodSymbol hash
]

{ #category : #testing }
MethodReference >> isClassReference [

	^ false
]

{ #category : #testing }
MethodReference >> isMethodReference [

	^ true
]

{ #category : #testing }
MethodReference >> isValid [
	"Answer whether the receiver represents a current selector or Comment"

	| aClass |
	methodSymbol isDoIt ifTrue: [^ false].
	(aClass := self actualClass) ifNil: [^ false].
	^ (aClass includesSelector: methodSymbol) or:
		[methodSymbol == #Comment]
]

{ #category : #accessing }
MethodReference >> methodSymbol [

	^methodSymbol
]

{ #category : #printing }
MethodReference >> printOn: aStream [
	| actualClass |
	"Print the receiver on a stream"
	actualClass := classSymbol asString.
	classIsMeta ifTrue: [actualClass := actualClass, ' class'].
	super printOn: aStream.
	aStream nextPutAll: ' ', actualClass, ' >> ', methodSymbol printString.
]

{ #category : #accessing }
MethodReference >> selector [

	^methodSymbol
]

{ #category : #'initialize-release' }
MethodReference >> setClass: aClass methodSymbol: methodSym stringVersion: aString [ 

	classSymbol := aClass theNonMetaClass name.
	classIsMeta := aClass isMeta.
	methodSymbol := methodSym.
	environment := aClass environment.
	stringVersion := aString.
]

{ #category : #'initialize-release' }
MethodReference >> setClassAndSelectorIn: csBlock [

	^csBlock value: self actualClass value: methodSymbol
]

{ #category : #'initialize-release' }
MethodReference >> setClassSymbol: classSym classIsMeta: isMeta methodSymbol: methodSym stringVersion: aString [ 

	classSymbol := classSym.
	classIsMeta := isMeta.
	methodSymbol := methodSym.
	stringVersion := aString.
]

{ #category : #'initialize-release' }
MethodReference >> setStandardClass: aClass methodSymbol: methodSym [

	classSymbol := aClass theNonMetaClass name.
	environment := aClass environment.
	classIsMeta := aClass isMeta.
	methodSymbol := methodSym.
	stringVersion := nil.
]

{ #category : #'initialize-release' }
MethodReference >> setStandardClass: aClass methodSymbol: aSelector environment: anEnvironment [
	classSymbol := aClass instanceSide name.
	classIsMeta := aClass isMeta.
	methodSymbol := aSelector.
	environment := anEnvironment.
	stringVersion := nil
]

{ #category : #accessing }
MethodReference >> source [
	^ (self actualClass sourceCodeAt: methodSymbol) asString withSqueakLineEndings
]

{ #category : #accessing }
MethodReference >> sourceCode [

	^ self actualClass sourceCodeAt: self methodSymbol
]

{ #category : #accessing }
MethodReference >> sourceString [

	^ self sourceCode asString
]

{ #category : #accessing }
MethodReference >> stringVersion [

	^stringVersion ifNil: [self asStringOrText]
]

{ #category : #accessing }
MethodReference >> stringVersion: aString [

	stringVersion := aString
]

{ #category : #accessing }
MethodReference >> stringVersionDefault [

	^classSymbol, (classIsMeta ifTrue: [ ' class ' ] ifFalse: [' ']), methodSymbol  
]

{ #category : #accessing }
MethodReference >> timeStamp [
	^ self compiledMethod timeStamp
]
