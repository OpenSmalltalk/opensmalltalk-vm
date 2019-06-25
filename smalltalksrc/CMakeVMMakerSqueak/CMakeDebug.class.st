"
A CMakeDebug  looks like this: (hack me however you want for your needs)

  message(""CMAKE_C_COMPILER=${CMAKE_C_COMPILER}"")
  message(""CMAKE_C_FLAGS=${CMAKE_C_FLAGS}"")
  message(""CMAKE_C_FLAGS_RELEASE=${CMAKE_C_FLAGS_RELEASE}"")
  message(""CMAKE_C_FLAGS_DEBUG=${CMAKE_C_FLAGS_DEBUG}"")
  message(""CMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}"")
  message(""CMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG}"")
  get_directory_property ( DirDefs DIRECTORY ${CMAKE_SOURCE_DIR} COMPILE_DEFINITIONS )
  foreach( d ${DirDefs} )
    message( STATUS ""Found Define: "" ${d} )
  endforeach()
  message( STATUS ""DirDefs: "" ${DirDefs} )
"
Class {
	#name : #CMakeDebug,
	#superclass : #CMakeTemplate,
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #'initialize-release' }
CMakeDebug >> initialize [
	self content:'
  message("CMAKE_C_COMPILER=${CMAKE_C_COMPILER}")
  message("CMAKE_C_FLAGS=${CMAKE_C_FLAGS}")
  message("CMAKE_C_FLAGS_RELEASE=${CMAKE_C_FLAGS_RELEASE}")
  message("CMAKE_C_FLAGS_DEBUG=${CMAKE_C_FLAGS_DEBUG}")
  message("CMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}")
  message("CMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG}")
  get_directory_property ( DirDefs DIRECTORY ${CMAKE_SOURCE_DIR} COMPILE_DEFINITIONS )
  foreach( d ${DirDefs} )
    message( STATUS "Found Define: " ${d} )
  endforeach()
  message( STATUS "DirDefs: " ${DirDefs} )'


]
