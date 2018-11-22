"
A CMakeHeaderFilesTemplate looks something like this:

	IF (DEFINED SQ_VI_BYTES_PER_WORD)
 	 CONFIG_DEFINE (SQ_VI_BYTES_PER_WORD)
	ENDIF (DEFINED SQ_VI_BYTES_PER_WORD)
"
Class {
	#name : #CMakeIfDefinedConfigDefine,
	#superclass : #CMakeTemplate,
	#instVars : [
		'variable'
	],
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #'initialize-release' }
CMakeIfDefinedConfigDefine >> initialize [
	variable:='bar'.
	self content:'
  IF(DEFINED ', variable ,')
	 CONFIG_DEFINE(', variable,')
  ENDIF(DEFINED ', variable ,')'


]

{ #category : #accessing }
CMakeIfDefinedConfigDefine >> variable: vString [
	variable:=vString.
	self content:'  if (DEFINED ', variable ,')
	 config_define(', variable,')
  endif (DEFINED ', variable ,')'

	

]
