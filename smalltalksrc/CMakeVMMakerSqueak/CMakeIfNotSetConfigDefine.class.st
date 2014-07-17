"
A CMakeHeaderFilesTemplate looks something like this:

  	IF (NOT without-SUGAR)
 	 SET (SUGAR 1)
	ENDIF ()
	CONFIG_DEFINE (SUGAR)

"
Class {
	#name : #CMakeIfNotSetConfigDefine,
	#superclass : #CMakeTemplate,
	#instVars : [
		'variable'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #'initialize-release' }
CMakeIfNotSetConfigDefine >> initialize [
	variable:='bar'.
	self content:'
  IF(NOT ', variable ,')
	SET (',variable,' 1)
  ENDIF(', variable ,')
 CONFIG_DEFINE(', variable,')'

]

{ #category : #accessing }
CMakeIfNotSetConfigDefine >> variable: vString [
	variable:=vString.
	self content:'  if(NOT ', variable ,')
	set (',variable,' 1)
  endif(NOT', variable ,')
 config_define(', variable,')'

	

]
