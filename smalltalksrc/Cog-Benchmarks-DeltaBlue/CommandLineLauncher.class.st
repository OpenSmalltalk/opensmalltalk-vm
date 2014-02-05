Class {
	#name : #CommandLineLauncher,
	#superclass : #AbstractLauncher,
	#category : #'Cog-Scripting'
}

{ #category : #activation }
CommandLineLauncher class >> activate [
	"Register this launcher with the auto start class"

	self autoStarter addLauncherFirst: self
]

{ #category : #accessing }
CommandLineLauncher class >> extractParameters [

	| pName value index globals |
	globals := Dictionary new.
	index := 2.
	[pName := Smalltalk getSystemAttribute: index.
	pName isEmptyOrNil] whileFalse:[
		index := index + 1.
		value := Smalltalk getSystemAttribute: index.
		value ifNil: [value := ''].
 		globals at: pName asLowercase put: value.
		index := index + 1].
	^globals
]

{ #category : #'class initialization' }
CommandLineLauncher class >> initialize [
	self activate
]

{ #category : #running }
CommandLineLauncher >> parameters: startupParameters [
	"AnstractLauncher class>>extractParameters extracts from the wrong index for Mac OS"
	super parameters: self class extractParameters
]

{ #category : #running }
CommandLineLauncher >> startUp [
	"UnixProcess stdOut print: parameters; nl."
	(parameters includesKey: '-doit') ifTrue:
		[Compiler evaluate: (parameters at: '-doit').
		 Smalltalk quitPrimitive]
]
