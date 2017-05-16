"
I am a bridge between the file systems of Pharo and Squeak.
I am used in the VMProfiler to keep it generic.
"
Class {
	#name : #VMFileSystem,
	#superclass : #Object,
	#category : #'CogTools-VMProfiler'
}

{ #category : #public }
VMFileSystem >> ensureExistenceOfDirectory: aDirName [
	self subclassResponsibility 
]

{ #category : #public }
VMFileSystem >> exists: aFilename [
	self subclassResponsibility 
]

{ #category : #'as yet unclassified' }
VMFileSystem >> nameFordirPath: aDirPath plus: aProcessId [
	
	self subclassResponsibility 
]

{ #category : #'as yet unclassified' }
VMFileSystem >> nameOfFile: aFilename in: aDirectory [

	self subclassResponsibility 
]

{ #category : #'as yet unclassified' }
VMFileSystem >> parentPathOfFile: aFilename [

	self subclassResponsibility 
]
