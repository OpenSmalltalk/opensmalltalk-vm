"
A CMakeIfAddDefinitionsElseAddDefinitions  looks something like this:

if (${WIN32})
	add_definitions(-Werror-implicit-function-declaration)	
else(${WIN32})
	add_definitions(-DNO_ISNAN)
endif (${WIN32})'.

CPlatformConfig>>configureFloatMathPlugin is the motivation
CMakePlatformConfigForSqueak>>configureByTemplateFilePlugin is where this is used
"
Class {
	#name : #CMakeIfAddDefinitionsElseAddDefinitions,
	#superclass : #CMakeTemplate,
	#instVars : [
		'condition',
		'ifdefinitions',
		'elsedefinitions'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #accessing }
CMakeIfAddDefinitionsElseAddDefinitions >> condition: cString ifdefinitions:iString elsedefinitions:eString [
	condition:=cString.
	ifdefinitions:= iString.
	elsedefinitions:=eString.
	self content:'
IF(', condition ,')
	 add_definitions(', ifdefinitions,')
ELSE(', condition ,')
	 add_definitions(', elsedefinitions,')
ENDIF(', condition ,')'

]

{ #category : #'initialize-release' }
CMakeIfAddDefinitionsElseAddDefinitions >> initialize [
	condition:='foo'.
      ifdefinitions:='-Wifbar'.
	elsedefinitions:='-Welsebar'.
	self content:'
  IF(', condition ,')
	 add_definitions(', ifdefinitions,')
ELSE(', condition ,')
	 add_definitions(', elsedefinitions,')
ENDIF(', condition ,')'


]
