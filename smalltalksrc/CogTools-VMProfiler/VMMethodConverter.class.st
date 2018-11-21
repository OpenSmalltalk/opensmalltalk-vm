"
I make a link between the methods that are implemented differently between Squeak and Pharo.


"
Class {
	#name : #VMMethodConverter,
	#superclass : #Object,
	#category : #'CogTools-VMProfiler'
}

{ #category : #'as yet unclassified' }
VMMethodConverter >> convertAsString: aBlock [

	self subclassResponsability.
]

{ #category : #'as yet unclassified' }
VMMethodConverter >> deleteContentsOf: aDirectory [
	self subclassResponsability
]

{ #category : #public }
VMMethodConverter >> ensureExistenceOfDirectory: aDirName [
"if the directory doesn't exist, create it"

	self subclassResponsibility 
]

{ #category : #public }
VMMethodConverter >> exists: aFilename [
"checks if a given file exists" 

	self subclassResponsibility 
]

{ #category : #'as yet unclassified' }
VMMethodConverter >> nameFordirPath: aDirPath plus: aProcessId [
"answers a FileSystem/Directory object representing a directory. The name of this directory is its path+the name of a process id"
	
	self subclassResponsibility 
]

{ #category : #'as yet unclassified' }
VMMethodConverter >> nameOfFile: aFilename in: aDirectory [

	self subclassResponsibility 
]

{ #category : #'as yet unclassified' }
VMMethodConverter >> parentPathOfFile: aFilename [

	self subclassResponsibility 
]

{ #category : #'as yet unclassified' }
VMMethodConverter >> print: anInteger showingDecimalPlaces: decimalPlaces [

	self subclassResponsability
]
