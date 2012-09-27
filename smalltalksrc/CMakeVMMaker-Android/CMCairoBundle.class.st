"
this is common superclass for defining settings for building cairo and accompanied libraries
"
Class {
	#name : #CMCairoBundle,
	#superclass : #CMThirdpartyLibrary,
	#category : #'CMakeVMMaker-Libs'
}

{ #category : #'as yet unclassified' }
CMCairoBundle class >> canonicalName [
	^ nil
]

{ #category : #'as yet unclassified' }
CMCairoBundle class >> supports: aConfig [
	"right now, Mac only"
	^  aConfig platformName  = 'iOS'
]
