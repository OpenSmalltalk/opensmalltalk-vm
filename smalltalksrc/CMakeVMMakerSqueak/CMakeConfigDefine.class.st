"
A CMakeSetTemplate 's contents look like


	CONFIG_DEFINE (SQ_VERSION)

"
Class {
	#name : #CMakeConfigDefine,
	#superclass : #CMakeTemplate,
	#instVars : [
		'variable',
		'value'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #'initialize-release' }
CMakeConfigDefine >> initialize [
	variable:='foo'.
	value:='bar'.
	self content:'
  CONFIG_DEFINE(',variable,' ',value,')'
]

{ #category : #accessing }
CMakeConfigDefine >> variable: aString [ 

	variable := aString.
	value := nil.
	self content:'
  CONFIG_DEFINE(',variable,')'
]

{ #category : #accessing }
CMakeConfigDefine >> variable: aString value: vString [

	variable := aString.
	value := vString.
	self content:'
  CONFIG_DEFINE(',variable,' ',value,')'
]
