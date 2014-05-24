"
A CMakeVMGeneratorForSqueak overides some CMakeVMGenerator methos for squeak compatibility. 


"
Class {
	#name : #CMakeVMGeneratorForSqueak,
	#superclass : #CMakeVMGenerator,
	#category : #CMakeVMMakerSqueak
}

{ #category : #'as yet unclassified' }
CMakeVMGeneratorForSqueak class >> generate: aConfigOrClass [  
	^self new 
		generate: aConfigOrClass;
		yourself  
]

{ #category : #'as yet unclassified' }
CMakeVMGeneratorForSqueak >> generatePlugin: aPlugin internal: aBoolean extraRules: aBlock [
	" this method called back from plugin"
	^ CMakePluginGeneratorForSqueak new
		generate: aPlugin for: self internal: aBoolean extraRules: aBlock
]
