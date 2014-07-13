"
A CMakeCheckLibraryExistsTemplate is a CMake Command in the CheckLibraryExists Module

http://cmake.org/Wiki/CMake:How_To_Write_Platform_Checks

Module
 INCLUDE (CheckLibraryExists) 
Usage
 CHECK_LIBRARY_EXISTS(library function location variable) 
Example
 CHECK_LIBRARY_EXISTS(volmgt volmgt_running """" HAVE_VOLMGT) 

Checks whether the given library exists and contains the given function. This is done by linking a small program which uses the function and links to the library. In the location parameter an additional link directory (-Ldir) can be given if required.

example:

        CHECK_LIBRARY_EXISTS (dl dlopen """" HAVE_LIBDL)
        IF (HAVE_LIBDL)
         CONFIG_DEFINE(HAVE_LIBDL)
        ENDIF (HAVE_LIBDL)

"
Class {
	#name : #CMakeCheckLibraryExists,
	#superclass : #CMakeTemplate,
	#instVars : [
		'library',
		'function',
		'location',
		'variable'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #accessing }
CMakeCheckLibraryExists >> function [

	^ function
]

{ #category : #accessing }
CMakeCheckLibraryExists >> function: anObject [

	function := anObject
]

{ #category : #'initialize-release' }
CMakeCheckLibraryExists >> initialize [
	library:='library'.
	function:='function'.
	location:='-L/location'.
	variable:='HAVE_LIBRARY'.
	content:='
  CHECK_LIBRARY_EXISTS (', library, ' ', function, '  "', location ,'" ', variable ,')
  IF (', variable, ')
      CONFIG_DEFINE(', variable, ')
   ENDIF (', variable, ')'

]

{ #category : #accessing }
CMakeCheckLibraryExists >> library [

	^ library
]

{ #category : #accessing }
CMakeCheckLibraryExists >> library: anObject [

	library := anObject
]

{ #category : #'initialize-release' }
CMakeCheckLibraryExists >> library: lString function: fString location: locString variable: vString [
	library:= lString.
	function:=fString.
	location:=locString.
	variable:=vString.
	content:='
  CHECK_LIBRARY_EXISTS (', library, ' ', function, '  "', location ,'" ', variable ,')
  IF (', variable, ')
      CONFIG_DEFINE(', variable, ')
   ENDIF (', variable, ')'

]

{ #category : #accessing }
CMakeCheckLibraryExists >> location [

	^ location
]

{ #category : #accessing }
CMakeCheckLibraryExists >> location: anObject [

	location := anObject
]

{ #category : #accessing }
CMakeCheckLibraryExists >> variable [

	^ variable
]

{ #category : #accessing }
CMakeCheckLibraryExists >> variable: anObject [

	variable := anObject
]
