"
A CMakeCheckTryCompileHaveLangInfoCodeset  looks like this.

        IF (HAVE_LANGINFO_H)
         TRY_COMPILE (HAVE_LANGINFO_CODESET ${CMAKE_BINARY_DIR}  ${CMAKE_BINARY_DIR}/testLanginfoCodeset.c)
        ENDIF (HAVE_LANGINFO_H)

"
Class {
	#name : #CMakeCheckTryCompileHaveLangInfoCodeset,
	#superclass : #CMakeTemplate,
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #'as yet unclassified' }
CMakeCheckTryCompileHaveLangInfoCodeset >> initialize [
	self flag:'tty'. "generalize me http://www.cmake.org/cmake/help/v3.0/command/try_compile.html"
	content:='
  IF (HAVE_LANGINFO_H)
    TRY_COMPILE (HAVE_LANGINFO_CODESET ${CMAKE_BINARY_DIR}  ${CMAKE_BINARY_DIR}/testLanginfoCodeset.c)
  ENDIF (HAVE_LANGINFO_H)
  IF(HAVE_LANGINFO_CODESET)
	CONFIG_DEFINE(HAVE_LANGINFO_CODESET)
  ENDIF(HAVE_LANGINFO_CODESET)
'

]
