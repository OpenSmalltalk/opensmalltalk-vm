"
A CMakePluginGeneratorForSqueak overides some CMakeVMPluginGenerator methods for squeak compatibility. 

Instance Variables

"
Class {
	#name : #CMakePluginGeneratorForSqueak,
	#superclass : #CMakeGeneratorForSqueak,
	#instVars : [
		'plugin',
		'vmGen',
		'internal',
		'extraRules',
		'doNotGenerate',
		'externalDependencies'
	],
	#category : #CMakeVMMakerSqueak
}

{ #category : #'squeak compatibility' }
CMakePluginGeneratorForSqueak >> generate: aPlugin for: aCMakeVMGenerator internal: aBoolean extraRules: aBlock [

	doNotGenerate := false.
	internal := aBoolean.
	plugin := aPlugin.
	vmGen := aCMakeVMGenerator.
	extraRules := aBlock.
		
	^ self generate
]

{ #category : #'squeak compatibility' }
CMakePluginGeneratorForSqueak >> saveFile [
	
	| reference |
	reference := ((vmGen config dirFrom: vmGen buildDir) / plugin moduleName).
	reference assureExistence.
	reference 
		forceNewFileNamed: (self outputFileName)
		do:[:s | s nextPutAll:(self config fixLineEndsOf: output contents)]

]
