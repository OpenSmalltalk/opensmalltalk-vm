Class {
	#name : #SqueakMacOSConfig,
	#superclass : #CPlatformConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#category : #'CMakeVMMakerSqueak-MacOS'
}

{ #category : #'as yet unclassified' }
SqueakMacOSConfig class >> availableBuilds [
	"Answer a subset of SqueakCMakeVMMakerAbstractBuilder allBuildConfigurations"
	self subclassResponsibility
]
