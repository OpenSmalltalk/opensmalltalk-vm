"
A CMakeFindPackageTemplate can look like this:

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
CMakeFindPackage >> packagename [

	^ packagename
]

{ #category : #accessing }
CMakeFindPackage >> packagename: anObject [
	packagename := anObject.
	content:='
  FIND_PACKAGE (', packagename ,')
  IF (',packagename,'_FOUND)
    LIST (REMOVE_DUPLICATES ',packagename,'_INCLUDE_DIR)
    SET(USE_', packagename,' 1)
    CONFIG_DEFINE(USE_', packagename,')
  ENDIF (',packagename,'_FOUND)
'.
]
