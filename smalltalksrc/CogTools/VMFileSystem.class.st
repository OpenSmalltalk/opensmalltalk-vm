"
I dispatch between the file systems of Pharo (FileSystem) and Squeak (FileDirectory)
"
Class {
	#name : #VMFileSystem,
	#superclass : #Object,
	#category : #'CogTools-VMProfiler'
}

{ #category : #'as yet unclassified' }
VMFileSystem >> deleteContentsOf: aDirectory [
	self subclassResponsability
]

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
"answers a FileSystem/Directory object representing a directory. The name of this directory is its path+the name of a process id"
	
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
