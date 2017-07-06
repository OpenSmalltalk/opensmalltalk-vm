Class {
	#name : #SqueakVMMethodConverter,
	#superclass : #VMMethodConverter,
	#category : #'CogTools-VMProfiler'
}

{ #category : #'as yet unclassified' }
SqueakVMMethodConverter >> convertAsString: aBlock [

	^ aBlock sourceString
]

{ #category : #'as yet unclassified' }
SqueakVMMethodConverter >> deleteContentsOf: aDirectory [

	aDirectory recursiveDelete
]

{ #category : #public }
SqueakVMMethodConverter >> ensureExistenceOfDirectory: aDirName [
	
	^ aDirName assureExistence
]

{ #category : #public }
SqueakVMMethodConverter >> exists: aFilename [

	^FileDirectory default fileExists: aFilename 
]

{ #category : #'as yet unclassified' }
SqueakVMMethodConverter >> nameFordirPath: aDirPath plus: aProcessId [
	
	^ FileDirectory on: aDirPath, aProcessId
]

{ #category : #'as yet unclassified' }
SqueakVMMethodConverter >> nameOfFile: aFilename in: aDirectory [

	^ aDirectory localNameFor: aFilename 
]

{ #category : #'as yet unclassified' }
SqueakVMMethodConverter >> parentPathOfFile: aFilename [

	^ FileDirectory dirPathFor: aFilename 
]

{ #category : #'as yet unclassified' }
SqueakVMMethodConverter >> print: anInteger showingDecimalPlaces: decimalPlaces [

	^ anInteger printShowingMaxDecimalPlaces: decimalPlaces
]
