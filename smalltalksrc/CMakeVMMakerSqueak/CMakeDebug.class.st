Class {
	#name : #CMakeDebug,
	#superclass : #CMakeTemplate,
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #'initialize-release' }
CMakeDebug >> initialize [
	self content:'
  MESSAGE("CMAKE_C_FLAGS=${CMAKE_C_FLAGS}")
  MESSAGE("CMAKE_C_FLAGS_RELEASE=${CMAKE_C_FLAGS_RELEASE}")
  MESSAGE("CMAKE_C_FLAGS_DEBUG=${CMAKE_C_FLAGS_DEBUG}")
  MESSAGE("CMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}")
  MESSAGE("CMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG}")
  GET_DIRECTORY_PROPERTY( DirDefs DIRECTORY ${CMAKE_SOURCE_DIR} COMPILE_DEFINITIONS )
  FOREACH( d ${DirDefs} )
    MESSAGE( STATUS "Found Define: " ${d} )
  ENDFOREACH()
  MESSAGE( STATUS "DirDefs: " ${DirDefs} )'
]
