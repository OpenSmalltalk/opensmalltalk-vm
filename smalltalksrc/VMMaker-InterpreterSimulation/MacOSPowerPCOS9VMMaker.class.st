"
A VMMaker subclass to suit Mac OS
"
Class {
	#name : #MacOSPowerPCOS9VMMaker,
	#superclass : #VMMaker,
	#category : #'VMMaker-Building'
}

{ #category : #initialisation }
MacOSPowerPCOS9VMMaker class >> isActiveVMMakerClassFor: platformName [
	"Does this class claim to be that properly active subclass of VMMaker for this platform?"

	^platformName = 'Mac OS'" and: [Smalltalk platformSubtype = 'PowerPC'] <- this used to be used but prevents any attempt to do the crossplatform generation thang. How can we handle that bit properly?"
]

{ #category : #initialize }
MacOSPowerPCOS9VMMaker >> createCodeGenerator [
"set up a CCodeGenerator for this VMMaker - Mac OS uses the global struct and local def of the structure"
	^CCodeGeneratorGlobalStructure new initialize; globalStructDefined: true
]
