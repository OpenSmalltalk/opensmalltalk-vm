"
A CMakeHeaderFilesTemplate looks something like this:

        check_include_file(""unistd.h"" HAVE_UNISTD_H)
        if(HAVE_UNISTD_H)
         CONFIG_DEFINE(HAVE_UNISTD_H)
        endif()
The addition of the CONFIG_DEFINE is a convenience addition
from the CMake documentation of

- Check if the include file exists.
# CHECK_INCLUDE_FILE(INCLUDE VARIABLE)
# - macro which checks the include file exists.
#  INCLUDE  - name of include file
#  VARIABLE - variable to return result
#
# an optional third argument is the CFlags to add to the compile line
# or you can use CMAKE_REQUIRED_FLAGS
#
# The following variables may be set before calling this macro to
# modify the way the check is run:
#
#  CMAKE_REQUIRED_FLAGS = string of compile command line flags
#  CMAKE_REQUIRED_DEFINITIONS = list of macros to define (-DFOO=bar)
#  CMAKE_REQUIRED_INCLUDES = list of include directories



"
Class {
	#name : #CMakeCheckIncludeFile,
	#superclass : #CMakeTemplate,
	#instVars : [
		'include',
		'variable',
		'path'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #accessing }
CMakeCheckIncludeFile >> include: iString variable: vString [
	include:=iString.
	variable:=vString.
	self content:'  check_include_file("', include  ,'" ', variable,')
  IF(', variable ,')
    config_define(', variable,')
  ENDIF(', variable ,')'


]

{ #category : #accessing }
CMakeCheckIncludeFile >> include: iString variable: vString path: pString [
	include:=iString.
	variable:=vString.
	path:= pString.
	self content:'  check_include_file("', include  ,'" ', variable,' ',  path ,')
  IF(', variable ,')
    config_define(', variable,')
  ENDIF(', variable ,')'


]

{ #category : #'initialize-release' }
CMakeCheckIncludeFile >> initialize [
	include='foo'.
	variable:='bar'.
	path='path'.
	self content:'
  CHECK_INCLUDE_FILE("', include  ,'" ', variable,' ',  path ,')
  IF(', variable ,')
    CONFIG_DEFINE(', variable,')
  ENDIF(', variable ,')'


]
