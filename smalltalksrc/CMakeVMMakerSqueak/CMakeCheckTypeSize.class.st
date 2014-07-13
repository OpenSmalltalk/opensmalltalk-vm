"
A CMakeCheckTypeSizeTemplate looks like this:

  CHECK_TYPE_SIZE (int SIZEOF_INT)
  CHECK_TYPE_SIZE (long SIZEOF_LONG)
  CHECK_TYPE_SIZE (""long long"" SIZEOF_LONG_LONG)
  CHECK_TYPE_SIZE (""void *"" SIZEOF_VOID_P)

  CONFIG_DEFINE (SIZEOF_INT)
  CONFIG_DEFINE (SIZEOF_LONG)
  CONFIG_DEFINE (SIZEOF_LONG_LONG)
  CONFIG_DEFINE (SIZEOF_VOID_P)
"
Class {
	#name : #CMakeCheckTypeSize,
	#superclass : #CMakeTemplate,
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #'initialize-release' }
CMakeCheckTypeSize >> initialize [
	self content:'
  MESSAGE("Determine Type Sizes")
  CHECK_TYPE_SIZE (int SIZEOF_INT)
  CHECK_TYPE_SIZE (long SIZEOF_LONG)
  CHECK_TYPE_SIZE ("long long" SIZEOF_LONG_LONG)
  CHECK_TYPE_SIZE ("void *" SIZEOF_VOID_P)

  CONFIG_DEFINE (SIZEOF_INT)
  CONFIG_DEFINE (SIZEOF_LONG)
  CONFIG_DEFINE (SIZEOF_LONG_LONG)
  CONFIG_DEFINE (SIZEOF_VOID_P)'
]
