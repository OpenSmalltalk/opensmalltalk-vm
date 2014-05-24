"
A CMakePluginGeneratorForSqueak overides some CMakeVMPluginGenerator methods for squeak compatibility. 

Instance Variables

"
Class {
	#name : #CMakePluginGeneratorForSqueak,
	#superclass : #CMakePluginGenerator,
	#category : #CMakeVMMakerSqueak
}

{ #category : #'squeak compatibility' }
CMakePluginGeneratorForSqueak >> saveFile [
	
	| reference |
	reference := ((vmGen config dirFrom: vmGen buildDir) / plugin moduleName).
	reference assureExistence.
	reference 
		forceNewFileNamed: (self outputFileName)
		do:[:s | s nextPutAll:(self config fixLineEndsOf: output contents)]

]
