"
A CMakeAppendConfigStatus looks like this:

FILE (WRITE ${CMAKE_BINARY_DIR}/config.status """")
FOREACH (var ${tmp})
  FILE (APPEND ${CMAKE_BINARY_DIR}/config.status ""${var}=${${var}}\n"")
ENDFOREACH ()'

"
Class {
	#name : #CMakeAppendConfigStatus,
	#superclass : #CMakeTemplate,
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #'initialize-release' }
CMakeAppendConfigStatus >> initialize [
	self content:'
FOREACH (var ${config_vars})
  FILE (APPEND ${CMAKE_BINARY_DIR}/config.h.in "#cmakedefine ${var} @${var}@\n")
ENDFOREACH (var)'.

]
