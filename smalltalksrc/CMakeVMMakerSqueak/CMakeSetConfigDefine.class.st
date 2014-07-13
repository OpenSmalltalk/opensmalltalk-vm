"
A CMakeSetTemplate 's contents look like 

	SET (VM_X11DIR \""${X11_LIBRARY_DIR}\"")
	CONFIG_DEFINE (VM_X11DIR)
"
Class {
	#name : #CMakeSetConfigDefine,
	#superclass : #CMakeTemplate,
	#instVars : [
		'variable',
		'value'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #'initialize-release' }
CMakeSetConfigDefine >> initialize [
	variable:='foo'.
	value:='bar'.
	self content:'
  SET(',variable,' ',value,')
  CONFIG_DEFINE (',variable,')'
]

{ #category : #accessing }
CMakeSetConfigDefine >> variable: aString value: vString [

	variable := aString.
	value := vString.
	self content:'
  SET(',variable,' ',value,')
  CONFIG_DEFINE (',variable,')'.

]
