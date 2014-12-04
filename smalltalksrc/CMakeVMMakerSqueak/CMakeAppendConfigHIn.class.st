"
A CMakeAppendConfigHIn looks like this:

FOREACH (var ${config_vars})
  FILE (APPEND ${CMAKE_BINARY_DIR}/config.h.in ""#cmakedefine ${var} @${var}@\n"")
ENDFOREACH (var)'.
"
Class {
	#name : #CMakeAppendConfigHIn,
	#superclass : #CMakeTemplate,
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #'initialize-release' }
CMakeAppendConfigHIn >> initialize [
	self content:'
FOREACH (var ${config_vars})
  FILE (APPEND ${CMAKE_BINARY_DIR}/config.h.in "#cmakedefine ${var} @${var}@\n")
ENDFOREACH (var)'.

]
