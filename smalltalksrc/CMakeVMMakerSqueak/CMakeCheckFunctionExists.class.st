"
A CMakeCheckFunctionExistsTemplate looks like this:

        CHECK_FUNCTION_EXISTS (atexit           HAVE_ATEXIT)
	  CONFIG_DEFINE(HAVE_ATEXIT)

The addition of the CONFIG_DEFINE is a convenience addition


My CMake documentation reads...

 INCLUDE (CheckFunctionExists) 
Usage
 CHECK_FUNCTION_EXISTS(function variable) 
Example
 CHECK_FUNCTION_EXISTS(madvise HAVE_MADVISE) 

Checks whether the given function exists. This is done by linking a small program, which may not result in undefined references.


"
Class {
	#name : #CMakeCheckFunctionExists,
	#superclass : #CMakeTemplate,
	#instVars : [
		'function',
		'variable'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #accessing }
CMakeCheckFunctionExists >> function [

	^ function
]

{ #category : #accessing }
CMakeCheckFunctionExists >> function: fString [
	function := fString.
	variable:= 'HAVE_',(function asUppercase).
	self function: function variable: variable.
]

{ #category : #accessing }
CMakeCheckFunctionExists >> function: fString variable: vString [
	function := fString.
	variable:= vString.
	content:='  check_function_exists(', function ,' ', variable,')
  IF(', variable ,')
    config_define(', variable,')
  ENDIF(', variable ,')'
]

{ #category : #'initialize-release' }
CMakeCheckFunctionExists >> initialize [
	function:='function'.
	variable:= 'HAVE_',(function asUppercase).
	content:='
  CHECK_FUNCTION_EXISTS(', function ,' ', variable,')'
]
