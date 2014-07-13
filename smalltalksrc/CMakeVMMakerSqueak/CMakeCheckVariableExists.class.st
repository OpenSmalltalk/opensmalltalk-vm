"
A CMakeCheckVariableExistsTemplate looks like this:

	CHECK_VARIABLE_EXISTS (timezone	HAVE_TIMEZONE)

My CMake documentation reads...

 - Check if the variable exists.
#  CHECK_VARIABLE_EXISTS(VAR VARIABLE)
#
#  VAR      - the name of the variable
#  VARIABLE - variable to store the result
#
# This macro is only for C variables.
#
# The following variables may be set before calling this macro to
# modify the way the check is run:
#
#  CMAKE_REQUIRED_FLAGS = string of compile command line flags
#  CMAKE_REQUIRED_DEFINITIONS = list of macros to define (-DFOO=bar)
#  CMAKE_REQUIRED_LIBRARIES = list of libraries to link




"
Class {
	#name : #CMakeCheckVariableExists,
	#superclass : #CMakeTemplate,
	#instVars : [
		'var',
		'variable'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #'initialize-release' }
CMakeCheckVariableExists >> initialize [
	var:='var'.
	variable:= 'HAVE_',(var asUppercase).
	content:='
  CHECK_VARIABLE_EXISTS(', var ,' ', variable,')
  IF(', variable ,')
    CONFIG_DEFINE(', variable,')
  ENDIF(', variable ,')'
]

{ #category : #accessing }
CMakeCheckVariableExists >> var [

	^ var
]

{ #category : #accessing }
CMakeCheckVariableExists >> var: anObject [

	var := anObject
]

{ #category : #accessing }
CMakeCheckVariableExists >> var: varString variable: vString [
	var := varString.
	variable:= vString.
	content:='
  CHECK_VARIABLE_EXISTS(', var ,' ', variable,')
  IF(', variable ,')
    CONFIG_DEFINE(', variable,')
  ENDIF(', variable ,')'
]

{ #category : #accessing }
CMakeCheckVariableExists >> variable [

	^ variable
]

{ #category : #accessing }
CMakeCheckVariableExists >> variable: anObject [

	variable := anObject
]
