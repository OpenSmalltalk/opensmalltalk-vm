"
A SqueakCogSunOSConfig is a copy of the SqueakCogBSDConfig.

As of 2014.05.18 I have not been tested on SunOS and serve merely as a placeholder.

"
Class {
	#name : #SqueakCogSunOSConfig,
	#superclass : #CogUnixConfig,
	#traits : 'TSqueakStackUnixConfig - {#externalPlugins. #internalPlugins}',
	#classTraits : 'TSqueakStackUnixConfig classTrait',
	#category : #'CMakeVMMakerSqueak-SunOS'
}

{ #category : #'squeak compatibility' }
SqueakCogSunOSConfig >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]
