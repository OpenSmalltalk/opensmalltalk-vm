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

	^CCodeGeneratorGlobalStructure new
		vmMaker: self;
		logger: logger;
		options: optionsDictionary;
		yourself
]
