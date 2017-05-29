Class {
	#name : #PharoVMFileSystem,
	#superclass : #VMFileSystem,
	#category : #'CogTools-VMProfiler'
}

{ #category : #'as yet unclassified' }
PharoVMFileSystem >> deleteContentsOf: aDirectory [

	"not yet implemented. The temp directory created during the profiling will not be deleted when quitting the image"
	
]

{ #category : #public }
PharoVMFileSystem >> ensureExistenceOfDirectory: aDirName [
	^ aDirName ensureCreateDirectory 
]

{ #category : #public }
PharoVMFileSystem >> exists: aFilename [
	
	^ aFilename asFileReference exists
]

{ #category : #'as yet unclassified' }
PharoVMFileSystem >> nameFordirPath: aDirPath plus: aProcessId [
	
	^ (aDirPath, aProcessId) asFileReference   
]

{ #category : #'as yet unclassified' }
PharoVMFileSystem >> nameOfFile: aFilename in: aDirectory [

	^ aFilename asFileReference basename 
]

{ #category : #'as yet unclassified' }
PharoVMFileSystem >> parentPathOfFile: aFilename [

	^ (aFilename asFileReference) parent pathString  
]
