Class {
	#name : #FileDirectory,
	#superclass : #Object,
	#instVars : [
		'fileReference'
	],
	#category : #'VMMakerCompatibilityForPharo6-FileDirectoryToFileSystem'
}

{ #category : #'instance creation' }
FileDirectory class >> default [
	
	^ self
]

{ #category : #testing }
FileDirectory class >> directoryExists: aString [ 
	
	| ref |
	ref := aString asFileReference.
	^ ref exists and: [ ref isDirectory ]
]

{ #category : #'instance-creation' }
FileDirectory class >> directoryNamed: aString [ 
	
	^ self on: aString
]

{ #category : #testing }
FileDirectory class >> fileExists: aString [ 
	
	| ref |
	ref := aString asFileReference.
	^ ref exists and: [ ref isFile ]
]

{ #category : #'file-opening' }
FileDirectory class >> oldFileNamed: aString [ 
	
	^ VMMakerFile on: aString
]

{ #category : #'instance-creation' }
FileDirectory class >> on: aString [ 
	
	^ self new
		fileReference: aString asFileReference;
		yourself
]

{ #category : #checking }
FileDirectory >> assureExistence [
	
	fileReference ensureCreateDirectory
]

{ #category : #'file-system' }
FileDirectory >> deleteFileNamed: aString [ 
	
	(self fileNamed: aString) delete
]

{ #category : #accessing }
FileDirectory >> directoryNamed: aString [ 
	
	^ self class on: fileReference / aString
]

{ #category : #accessing }
FileDirectory >> entryAt: aString ifAbsent: aBlockClosure [ 
	
	| ref |
	ref := fileReference / aString.
	ref exists ifFalse: [ ^ aBlockClosure value ].
	^ ref
]

{ #category : #testing }
FileDirectory >> fileExists: aString [ 
	
	^ (VMMakerFile on: (fileReference / aString)) exists
]

{ #category : #accessing }
FileDirectory >> fileNamed: aString [ 
	
	^ fileReference / aString
]

{ #category : #accessing }
FileDirectory >> fileNamesMatching: aString [ 
	
	^ fileReference children
		select: [ :e | e basename match: aString ]
		thenCollect: [ :e | e halt ]
]

{ #category : #accessing }
FileDirectory >> fileReference: aFileReference [

	fileReference := aFileReference
]

{ #category : #accessing }
FileDirectory >> fullNameFor: aString [ 
	
	^ (self fileNamed: aString) fullName
]

{ #category : #'file-opening' }
FileDirectory >> oldFileNamed: aString [ 
	
	^ (self fileNamed: aString) readStream
]
