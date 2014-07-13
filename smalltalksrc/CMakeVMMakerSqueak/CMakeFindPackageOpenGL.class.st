"
A CMakeFindPackageOpenGLTemplate  looks like this.

	message(""without-gl = ${without_gl}"")

        IF (NOT without-gl)
          FIND_PACKAGE (OpenGL)
         LIST (REMOVE_DUPLICATES OPENGL_INCLUDE_DIR)
        ENDIF ()

        IF (NOT OPENGL_FOUND)
          SET (OPENGL_INCLUDE_DIR """")
        ENDIF ()



"
Class {
	#name : #CMakeFindPackageOpenGL,
	#superclass : #CMakeFindPackage,
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #'initialize-release' }
CMakeFindPackageOpenGL >> initialize [
	content:='	
  MESSAGE("without-gl = ${without_gl}")

  IF (NOT without-gl)
    FIND_PACKAGE (OpenGL)
    LIST (REMOVE_DUPLICATES OPENGL_INCLUDE_DIR)
  ENDIF ()
  IF (NOT OPENGL_FOUND)
    SET (OPENGL_INCLUDE_DIR "")
  ENDIF ()'
]
