Class {
	#name : #VMMakerFile,
	#superclass : #Object,
	#instVars : [
		'fileReference'
	],
	#category : #'VMMakerCompatibilityForPharo6-FileDirectoryToFileSystem'
}

{ #category : #'instance-creation' }
VMMakerFile class >> on: aString [ 
	
	^ self new
		fileReference: aString asFileReference;
		yourself
]

{ #category : #accessing }
VMMakerFile >> contentsOfEntireFile [
	
	^ fileReference contents
]

{ #category : #testing }
VMMakerFile >> exists [
	
	^ fileReference exists and: [ fileReference isFile ]
]

{ #category : #accessing }
VMMakerFile >> fileReference: aFileReference [ 
	fileReference := aFileReference
]
