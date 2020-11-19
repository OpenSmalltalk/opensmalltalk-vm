Class {
	#name : #SlangAbstractTestCase,
	#superclass : #TestCase,
	#instVars : [
		'ccg'
	],
	#category : #Slang
}

{ #category : #running }
SlangAbstractTestCase >> setUp [
	super setUp.
	ccg := CCodeGenerator new.

]
