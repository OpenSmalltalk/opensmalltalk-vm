"
A CMakeCompilerIsGNUCC looks like this

        IF (CMAKE_COMPILER_IS_GNUCC)
          SET (interp gnu-interp)
        ELSE ()
          SET (interp interp)
        ENDIF (CMAKE_COMPILER_IS_GNUCC)

"
Class {
	#name : #CMakeCompilerIsGNUCC,
	#superclass : #CMakeTemplate,
	#instVars : [
		'ifterp',
		'elseterm',
		'ifmessage',
		'elsemessage'
	],
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #'initialize-release' }
CMakeCompilerIsGNUCC >> initialize [
	self content:'
  IF (CMAKE_COMPILER_IS_GNUCC)
    SET (interp gnu-interp)
  ELSE ()
    SET (interp interp)
  ENDIF (CMAKE_COMPILER_IS_GNUCC)'
]
