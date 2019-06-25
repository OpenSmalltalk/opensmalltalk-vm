"
A CMakeDirDefs looks like this:

  FOREACH( d ${DirDefs} )
     MESSAGE( STATUS ""Found Define: "" ${d} )
  ENDFOREACH()
  MESSAGE( STATUS ""DirDefs: "" ${DirDefs} )'
"
Class {
	#name : #CMakeDirDefs,
	#superclass : #CMakeTemplate,
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #'initialize-release' }
CMakeDirDefs >> initialize [
	self content:'  
  FOREACH( d ${DirDefs} )
     MESSAGE( STATUS "Found Define: " ${d} )
  ENDFOREACH()
  MESSAGE( STATUS "DirDefs: " ${DirDefs} )'.
]
