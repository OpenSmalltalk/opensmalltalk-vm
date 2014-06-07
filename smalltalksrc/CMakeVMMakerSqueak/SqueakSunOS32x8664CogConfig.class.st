"
A SqueakSunOS32x8664CogConfig is xxxxxxxxx.


usage: 
SqueakSunOS32x8664CogConfig generate
or
SqueakSunOS32x8664CogConfig generateWithSources
or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me
"
Class {
	#name : #SqueakSunOS32x8664CogConfig,
	#superclass : #CPlatformConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#category : #'CMakeVMMakerSqueak-SunOS32x86_64'
}

{ #category : #'as yet unclassified' }
SqueakSunOS32x8664CogConfig >> todo [
	self flag:'tty'
]
