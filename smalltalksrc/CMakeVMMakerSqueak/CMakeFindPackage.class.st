"
A CMakeFindPackage can look like this:

        FIND_PACKAGE (X11)
        IF (X11_FOUND)
         LIST (REMOVE_DUPLICATES X11_INCLUDE_DIR)
         SET(USE_X11 1)
         CONFIG_DEFINE(USE_X11)
        ENDIF ()

"
Class {
	#name : #CMakeFindPackage,
	#superclass : #CMakeTemplate,
	#instVars : [
		'packagename'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #'initialize-release' }
CMakeFindPackage >> initialize [
	packagename := 'DUDE'.
	content:='
  FIND_PACKAGE (', packagename ,')
  IF (',packagename,'_FOUND)
    LIST (REMOVE_DUPLICATES ',packagename,'_INCLUDE_DIR)
    SET(USE_', packagename,' 1)
    CONFIG_DEFINE(USE_', packagename,')
  ENDIF (',packagename,'_FOUND)
'.
]

{ #category : #accessing }
CMakeFindPackage >> packagename: anObject [
	packagename := anObject.
	content:='  find_package(', packagename ,')
  if (',packagename,'_FOUND)
    list (REMOVE_DUPLICATES ',packagename,'_INCLUDE_DIR)
    set(USE_', packagename,' 1)
    config_define(USE_', packagename,')
  endif (',packagename,'_FOUND)
'.
]
