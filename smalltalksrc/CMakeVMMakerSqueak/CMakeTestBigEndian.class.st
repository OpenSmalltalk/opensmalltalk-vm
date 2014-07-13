"
A CMakeTestBigEndianTemplate looks like this:

        TEST_BIG_ENDIAN (WORDS_BIGENDIAN)
        IF (WORDS_BIGENDIAN)
          SET (MSB_FIRST 1)
        ELSE ()
          SET (LSB_FIRST 1)
        ENDIF ()

        CONFIG_DEFINE (WORDS_BIGENDIAN)
        CONFIG_DEFINE (LSB_FIRST)
        CONFIG_DEFINE (MSB_FIRST)
"
Class {
	#name : #CMakeTestBigEndian,
	#superclass : #CMakeTemplate,
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #'initialize-release' }
CMakeTestBigEndian >> initialize [
	self content:'
  TEST_BIG_ENDIAN (WORDS_BIGENDIAN)
  IF (WORDS_BIGENDIAN)
    SET (MSB_FIRST 1)
  ELSE ()
    SET (LSB_FIRST 1)
  ENDIF (WORDS_BIGENDIAN)

  CONFIG_DEFINE (WORDS_BIGENDIAN)
  CONFIG_DEFINE (LSB_FIRST)
  CONFIG_DEFINE (MSB_FIRST)'
]
