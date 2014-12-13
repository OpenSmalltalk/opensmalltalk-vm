"
A CMakeTestBigEndian looks like this:

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
	#name : #CMakeIOSInstallCode,
	#superclass : #CMakeTemplate,
	#category : #'CMakeVMMakerSqueak-CMakeCustomTemplates'
}

{ #category : #'initialize-release' }
CMakeIOSInstallCode >> initialize [
	self content:'
		INSTALL(CODE "
			set(externalModulesDir \"${externalModulesDir}\")
			set(bundlePath \"${bundlePath}\")
			set(pluginsRelPath \"${pluginsRelPath}\")
			
			include(fix_libs.cmake)
		")'
]
