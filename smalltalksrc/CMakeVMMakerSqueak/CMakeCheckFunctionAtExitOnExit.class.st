"
A CMakeCheckFunctionAtExitOnExit It looks like this

  CHECK_FUNCTION_EXISTS (atexit           HAVE_ATEXIT)
  CHECK_FUNCTION_EXISTS (on_exit          HAVE_ON_EXIT)
  IF (HAVE_ATEXIT)
     SET (AT_EXIT atexit)
  ELSEIF (HAVE_ON_EXIT)
    SET (AT_EXIT on_exit)
  ENDIF ()
  CONFIG_DEFINE (AT_EXIT)'
"
Class {
	#name : #CMakeCheckFunctionAtExitOnExit,
	#superclass : #CMakeCheckFunctionExists,
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #'as yet unclassified' }
CMakeCheckFunctionAtExitOnExit >> initialize [
	content:='
  CHECK_FUNCTION_EXISTS (atexit           HAVE_ATEXIT)
  CHECK_FUNCTION_EXISTS (on_exit          HAVE_ON_EXIT)
  IF (HAVE_ATEXIT)
     SET (AT_EXIT atexit)
  ELSEIF (HAVE_ON_EXIT)
    SET (AT_EXIT on_exit)
  ENDIF ()
  CONFIG_DEFINE (AT_EXIT)'
]
