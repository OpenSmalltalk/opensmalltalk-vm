"
A CMakeProject looks like this:

	PROJECT (squeak)
"
Class {
	#name : #CMakeProject,
	#superclass : #CMakeTemplate,
	#instVars : [
		'variable'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #'initialize-release' }
CMakeProject >> initialize [
	variable := 'foo'.
	self content:'
  PROJECT (', variable, ')'

]

{ #category : #accessing }
CMakeProject >> variable [

	^ variable
]

{ #category : #accessing }
CMakeProject >> variable: anObject [

	variable := anObject.
	self content:'  project (', variable, ')'
]
