Class {
	#name : #UnixVMMaker,
	#superclass : #VMMaker,
	#category : #'VMMaker-Building'
}

{ #category : #initialisation }
UnixVMMaker class >> isActiveVMMakerClassFor: platformName [

	^platformName = 'unix'
]

{ #category : #initialisation }
UnixVMMaker >> createCodeGenerator [

	^CCodeGeneratorGlobalStructure new initialize;
		globalStructDefined: true;
		logger: logger;
		yourself
]
