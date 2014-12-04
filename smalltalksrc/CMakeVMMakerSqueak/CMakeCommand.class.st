"
A CMakeSetTemplate 's contents look like


	CONFIG_DEFINE (SQ_VERSION)


CONFIG_DEFINE is a Macro Ian Piumarta wrote that looks like this:

MACRO (CONFIG_DEFINE var)
  LIST (APPEND config_vars ""${var}"")
ENDMACRO (CONFIG_DEFINE var)

You can see it in CPlatformConfigForSqueak class utilsCMake


"
Class {
	#name : #CMakeCommand,
	#superclass : #CMakeTemplate,
	#instVars : [
		'command',
		'params'
	],
	#category : #'CMakeVMMakerSqueak-CMakeTemplates'
}

{ #category : #accessing }
CMakeCommand >> command: cString params: pString [
	command:=cString.
	params:=pString.
	self content: command,'(', params ,')'


]

{ #category : #'initialize-release' }
CMakeCommand >> initialize [
	command:='foo'.
	params:='bar'.
	self content: command,'(', params ,')'
]
