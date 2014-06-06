Class {
	#name : #SqueakIA32BochsLinuxConfig,
	#superclass : #SqueakIA32BochsConfig,
	#category : #'CMakeVMMakerSqueak-IA32-Bochs'
}

{ #category : #'as yet unclassified' }
SqueakIA32BochsLinuxConfig class >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder noBuildConfigurations
]

{ #category : #'as yet unclassified' }
SqueakIA32BochsLinuxConfig >> todo [
	self flag:'tty'
]
