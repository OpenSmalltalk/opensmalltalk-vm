Class {
	#name : #PharoVMMethodConverter,
	#superclass : #VMMethodConverter,
	#category : #'CogTools-VMProfiler'
}

{ #category : #'as yet unclassified' }
PharoVMMethodConverter >> convertAsString: aBlock [

	^ aBlock asString
]

{ #category : #'as yet unclassified' }
PharoVMMethodConverter >> deleteContentsOf: aDirectory [

	aDirectory deleteAll. 
	
]

{ #category : #public }
PharoVMMethodConverter >> ensureExistenceOfDirectory: aDirName [
	^ aDirName ensureCreateDirectory 
]

{ #category : #public }
PharoVMMethodConverter >> exists: aFilename [
	
	^ aFilename asFileReference exists
]

{ #category : #'as yet unclassified' }
PharoVMMethodConverter >> nameFordirPath: aDirPath plus: aProcessId [
	
	^ (aDirPath, aProcessId) asFileReference   
]

{ #category : #'as yet unclassified' }
PharoVMMethodConverter >> nameOfFile: aFilename in: aDirectory [

	^ aFilename asFileReference basename 
]

{ #category : #'as yet unclassified' }
PharoVMMethodConverter >> parentPathOfFile: aFilename [

	^ (aFilename asFileReference) parent pathString  
]

{ #category : #'as yet unclassified' }
PharoVMMethodConverter >> print: anInteger showingDecimalPlaces: decimalPlaces [

	^ anInteger printShowingDecimalPlaces: decimalPlaces
]
