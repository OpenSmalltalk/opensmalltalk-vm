Class {
	#name : #MockSlangClass,
	#superclass : #SlangClass,
	#instVars : [
		'mockConstantClass',
		'cogitClass',
		'objectMemoryClass',
		'initializationOptions'
	],
	#category : #'Slang-Tests'
}

{ #category : #accessing }
MockSlangClass >> cogitClass [
	
	^ cogitClass
]

{ #category : #accessing }
MockSlangClass >> cogitClass: aClass [ 
	cogitClass := aClass
]

{ #category : #accessing }
MockSlangClass >> constantClass [
	
	^ mockConstantClass
]

{ #category : #accessing }
MockSlangClass >> initializationOptions [
	
	^ initializationOptions
]

{ #category : #accessing }
MockSlangClass >> initialize [

	super initialize.
	initializationOptions := Dictionary new
]

{ #category : #testing }
MockSlangClass >> innerBindingOf: aString [ 
	
	"For compatibility, used by the code generator to lookup for constants"
	
	^ nil
]

{ #category : #accessing }
MockSlangClass >> interpreterClass [
	
	^ nil
]

{ #category : #accessing }
MockSlangClass >> mockConstantClass [
	^ mockConstantClass
]

{ #category : #accessing }
MockSlangClass >> mockConstantClass: anObject [
	mockConstantClass := anObject
]

{ #category : #accessing }
MockSlangClass >> objectMemoryClass [
	
	^ objectMemoryClass
]

{ #category : #accessing }
MockSlangClass >> objectMemoryClass: aClass [ 
	objectMemoryClass := aClass
]

{ #category : #options }
MockSlangClass >> optionsAt: aKey put: aValue [
	
	initializationOptions at: aKey put: aValue
]

{ #category : #testing }
MockSlangClass >> shouldGenerateDeadCode [
	
	^ false
]
