"
A CMakeConfigUnDefine looks like


	CONFIG_DEFINE (SQ_VERSION)


CONFIG_UNDEFINE is a Macro defined in  CPlatformConfigForSqueak class utilsCMake

MACRO (CONFIG_UNDEFINE var)
  LIST (REMOVE_ITEM config_vars ""${var}"")
ENDMACRO (CONFIG_UNDEFINE var)




"
Class {
	#name : #CMakeConfigUnDefine,
	#superclass : #CMakeTemplate,
	#instVars : [
		'variable'
	],
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #'initialize-release' }
CMakeConfigUnDefine >> initialize [
	variable:='foo'.
	self content:'
  config_undefine(',variable,')'
]

{ #category : #accessing }
CMakeConfigUnDefine >> variable: aString [ 

	variable := aString.
	self content:'
  CONFIG_UNDEFINE(',variable,')'
]
