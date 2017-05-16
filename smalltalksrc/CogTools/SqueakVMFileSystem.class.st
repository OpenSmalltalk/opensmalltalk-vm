Class {
	#name : #SqueakVMFileSystem,
	#superclass : #VMFileSystem,
	#category : #'CogTools-VMProfiler'
}

{ #category : #public }
SqueakVMFileSystem >> ensureExistenceOfDirectory: aDirName [
	
	^ aDirName assureExistence
]

{ #category : #public }
SqueakVMFileSystem >> exists: aFilename [

	^FileDirectory default fileExists: aFilename 
]

{ #category : #'as yet unclassified' }
SqueakVMFileSystem >> nameFordirPath: aDirPath plus: aProcessId [
	
	^ FileDirectory on: aDirPath, aProcessId
]

{ #category : #'as yet unclassified' }
SqueakVMFileSystem >> nameOfFile: aFilename in: aDirectory [

	^ aDirectory localNameFor: aFilename 
]

{ #category : #'as yet unclassified' }
SqueakVMFileSystem >> parentPathOfFile: aFilename [

	^ FileDirectory dirPathFor: aFilename 
]
