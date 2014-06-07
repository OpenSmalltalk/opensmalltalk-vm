"
A SqueakSunOS32x86CogConfig is xxxxxxxxx.


usage: 
SqueakSunOS32x86CogConfig generate
or
SqueakSunOS32x86CogConfig generateWithSources
or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me
"
Class {
	#name : #SqueakSunOS32x86CogConfig,
	#superclass : #CPlatformConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#category : #'CMakeVMMakerSqueak-SunOS32x86'
}

{ #category : #'as yet unclassified' }
SqueakSunOS32x86CogConfig >> todo [
	self flag:'tty'
]
