"
A CMakeHeader is looks something like this:.
	# This is automatically generated file using Linux64x86w32BitSqueakCogV3Config on 14 July 2014 1:33:18.378 pm


"
Class {
	#name : #CMakeHeader,
	#superclass : #CMakeTemplate,
	#instVars : [
		'configurationName'
	],
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #accessing }
CMakeHeader >> configurationName [

	^ configurationName
]

{ #category : #accessing }
CMakeHeader >> configurationName: anObject [

	configurationName := anObject.
	self content:
'# This is automatically generated file using ', self configurationName, ' on ',  Date current asString, ' ' , Time current asString.

]

{ #category : #'initialize-release' }
CMakeHeader >> initialize [
	configurationName='foo'.
	self content: '# This is automatically generated file using ', self configurationName, ' on ',  Date current asString, ' ' , Time current asString.


]
