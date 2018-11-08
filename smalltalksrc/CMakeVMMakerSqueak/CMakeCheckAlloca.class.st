"
A CMakeCheckAlloca looks like this:


        CHECK_INCLUDE_FILE (alloca.h HAVE_ALLOCA_H)
        CONFIG_DEFINE (HAVE_ALLOCA_H)
        IF (HAVE_ALLOCA_H)
         SET (HAVE_ALLOCA 1)
        ELSE ()
          CHECK_FUNCTION_EXISTS (alloca HAVE_ALLOCA)
        ENDIF ()

        CONFIG_DEFINE (HAVE_ALLOCA)

"
Class {
	#name : #CMakeCheckAlloca,
	#superclass : #CMakeCheckIncludeFile,
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #'as yet unclassified' }
CMakeCheckAlloca >> initialize [
	content:='
  CHECK_INCLUDE_FILE (alloca.h HAVE_ALLOCA_H)
  CONFIG_DEFINE (HAVE_ALLOCA_H)
  IF (HAVE_ALLOCA_H)
    SET (HAVE_ALLOCA 1)
  ELSE ()
    CHECK_FUNCTION_EXISTS (alloca HAVE_ALLOCA)
  ENDIF ()
  CONFIG_DEFINE (HAVE_ALLOCA)
'
]
