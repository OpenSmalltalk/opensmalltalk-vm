"
A CMakeCommand  is a generic template for implementing cmake commands if one doesn't exist and you are too lazy to write a template (:
cmake --help-command-list




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
