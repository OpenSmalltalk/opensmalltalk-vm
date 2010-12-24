Class {
	#name : #CPlatformConfig,
	#superclass : #Object,
	#instVars : [
		'topDir',
		'buildDir',
		'srcDir',
		'platformsDir'
	],
	#category : #CMakeVMMaker
}

{ #category : #accessing }
CPlatformConfig >> buildDir [
	"Answer the value of buildDir"

	^ buildDir
]

{ #category : #accessing }
CPlatformConfig >> buildDir: anObject [
	"Set the value of buildDir"

	buildDir := anObject
]

{ #category : #'as yet unclassified' }
CPlatformConfig >> executableName [
	"default one"
	^ 'Squeak'
]

{ #category : #'as yet unclassified' }
CPlatformConfig >> executableType [
	^ ''
]

{ #category : #'as yet unclassified' }
CPlatformConfig >> fixLineEndsOf: string [
	^ string 
]

{ #category : #'as yet unclassified' }
CPlatformConfig >> frameworks [
	"leave empty for all platforms but Mac OS"
	^ #()
]

{ #category : #accessing }
CPlatformConfig >> platformsDir [
	^ platformsDir
]

{ #category : #accessing }
CPlatformConfig >> platformsDir: anObject [
	"Set the value of platformsDir"

	platformsDir := anObject
]

{ #category : #accessing }
CPlatformConfig >> srcDir [
	"Answer the value of srcDir"

	^ srcDir
]

{ #category : #accessing }
CPlatformConfig >> srcDir: anObject [
	"Set the value of srcDir"

	srcDir := anObject
]

{ #category : #accessing }
CPlatformConfig >> topDir [
	"Answer the value of topDir"

	^ topDir
]

{ #category : #accessing }
CPlatformConfig >> topDir: anObject [
	"Set the value of topDir"

	topDir := anObject
]
