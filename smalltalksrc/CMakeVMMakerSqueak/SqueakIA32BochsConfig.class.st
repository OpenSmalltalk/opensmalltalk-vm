"
A SqueakIA32BochsConfig is a Squeak Compatibility Layer between the Pharo code in CMakeVMMaker and CMakeVMakerSqueak.

I exist because modifying the pharo tree is verbotten as of 2014.06.10
"
Class {
	#name : #SqueakIA32BochsConfig,
	#superclass : #CPlatformConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#category : #'CMakeVMMakerSqueak-IA32-Bochs'
}

{ #category : #accessing }
SqueakIA32BochsConfig class >> availableBuilds [
	"SqueakCMakeVMMakerAbstractBuilder  allBuildConfigurations
	^#(#assert #debug  #release )"
	^SqueakCMakeVMMakerAbstractBuilder noBuildConfigurations
]
