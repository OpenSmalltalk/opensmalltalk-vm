Class {
	#name : #Linux32x86SqueakStackSpurConfig,
	#superclass : #CPlatformConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #'as yet unclassified' }
Linux32x86SqueakStackSpurConfig class >> availableBuilds [
	"Answer a subset of SqueakCMakeVMMakerAbstractBuilder allBuildConfigurations"
	self flag:'tty'. "This really should be at the top of the inheritence tree, but that resides in Pharo's code. Please refactor me"
	self subclassResponsibility
]

{ #category : #'as yet unclassified' }
Linux32x86SqueakStackSpurConfig >> todo [
	self flag:'tty'
]
