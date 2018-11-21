"
A CMakeIfNotFlagSetConfigDefineTemplate looks like this:

        IF (NOT without-SUGAR)
         SET (SUGAR 1)
        ENDIF ()

        CONFIG_DEFINE (SUGAR)

"
Class {
	#name : #CMakeIfNotFlagSetConfigDefine,
	#superclass : #CMakeTemplate,
	#instVars : [
		'variable',
		'flag'
	],
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #accessing }
CMakeIfNotFlagSetConfigDefine >> flag: fString variable: vString [
	flag:= fString.
	variable:= vString.
	self content:'  if(NOT ', flag ,')
	set (',variable,' 1)
  endif(NOT ', flag ,')
 config_define(', variable,')'
]

{ #category : #'initialize-release' }
CMakeIfNotFlagSetConfigDefine >> initialize [
	flag:='foo'.
	variable:='bar'.
	self content:'
  IF(NOT ', flag ,')
	SET (',variable,' 1)
  ENDIF(NOT ', flag ,')
 CONFIG_DEFINE(', variable,')'
]
