"
A CMakeSetTemplate 's contents look like SET(foo ""bar"")

"
Class {
	#name : #CMakeSet,
	#superclass : #CMakeTemplate,
	#instVars : [
		'variable',
		'value'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #'initialize-release' }
CMakeSet >> initialize [
	variable:='foo'.
	value:='bar'.
	self content:'
  SET(',variable,' ',value,')'
]

{ #category : #accessing }
CMakeSet >> variable: aString value: vString [

	variable := aString.
	value := vString.
	self content:'
  SET(',variable,' ',value,')'
]
