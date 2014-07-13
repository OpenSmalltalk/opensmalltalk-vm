"
A CMakeCheckLibDLTemplate needs to be refactored.
I look like this:

        CHECK_LIBRARY_EXISTS (dl dlopen """" HAVE_LIBDL)
        IF (HAVE_LIBDL)
         USE_LIBRARY (dl)
        ENDIF (HAVE_LIBDL)
        IF (HAVE_LIBDL)
         SET (HAVE_DLOPEN 1)
        ELSE ()
          CHECK_FUNCTION_EXISTS (dlopen HAVE_DLOPEN)
        ENDIF (HAVE_LIBDL)
"
Class {
	#name : #CMakeCheckLibDL,
	#superclass : #CMakeCheckLibraryExists,
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #'initialize-release' }
CMakeCheckLibDL >> initialize [
	content:='
  CHECK_LIBRARY_EXISTS (dl dlopen "" HAVE_LIBDL)
  IF (HAVE_LIBDL)
    USE_LIBRARY (dl)
  ENDIF (HAVE_LIBDL)
  IF (HAVE_LIBDL)
    SET (HAVE_DLOPEN 1)
  ELSE ()
    CHECK_FUNCTION_EXISTS (dlopen HAVE_DLOPEN)
  ENDIF (HAVE_LIBDL)
  CONFIG_DEFINE (HAVE_DLOPEN)
'
]
