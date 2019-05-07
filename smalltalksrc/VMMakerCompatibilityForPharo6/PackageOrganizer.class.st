Class {
	#name : #PackageOrganizer,
	#superclass : #Object,
	#category : #'VMMakerCompatibilityForPharo6-PackageOrganizer'
}

{ #category : #accessing }
PackageOrganizer class >> default [
	
	^ self new
]

{ #category : #accessing }
PackageOrganizer >> packageOfClass: aClass [ 
	
	^ aClass package
]
