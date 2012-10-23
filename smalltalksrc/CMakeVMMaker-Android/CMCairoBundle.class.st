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

{ #category : #'as yet unclassified' }
CMCairoBundle >> macOSXBuildFlags [
	^ 'CFLAGS=''-m32 -march=pentium4'' LDFLAGS=''-m32 -march=pentium4"'
]

{ #category : #'as yet unclassified' }
CMCairoBundle >> win32BuildFlags [
	^ 'CFLAGS=''-m32 -march=pentium4'' LDFLAGS=''-m32 -march=pentium4"'
]
