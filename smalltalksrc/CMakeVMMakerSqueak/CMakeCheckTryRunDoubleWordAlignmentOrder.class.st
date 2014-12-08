"
A CMakeCheckTryRunDoubleWordAlignmentOrder  looks like this:


        TRY_RUN (DOUBLE_WORD_ALIGNMENT tmp ${CMAKE_BINARY_DIR}  ${CMAKE_BINARY_DIR}/testDoubleWordAlignment.c)
        TRY_RUN (DOUBLE_WORD_ORDER tmp ${CMAKE_BINARY_DIR}  ${CMAKE_BINARY_DIR}/testDoubleWordOrder.c)

        CONFIG_DEFINE (DOUBLE_WORD_ALIGNMENT)
        CONFIG_DEFINE (DOUBLE_WORD_ORDER)


"
Class {
	#name : #CMakeCheckTryRunDoubleWordAlignmentOrder,
	#superclass : #CMakeTemplate,
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #'initialize-release' }
CMakeCheckTryRunDoubleWordAlignmentOrder >> initialize [
	self content:'
  MESSAGE("Test Double Word")
  TRY_RUN (DOUBLE_WORD_ALIGNMENT tmp ${CMAKE_BINARY_DIR}  ${CMAKE_BINARY_DIR}/testDoubleWordAlignment.c)
  TRY_RUN (DOUBLE_WORD_ORDER tmp ${CMAKE_BINARY_DIR}  ${CMAKE_BINARY_DIR}/testDoubleWordOrder.c)
  CONFIG_DEFINE (DOUBLE_WORD_ALIGNMENT)
  CONFIG_DEFINE (DOUBLE_WORD_ORDER)'

]
