Class {
	#name : #Linux64SqueakCogSpur,
	#superclass : #Linux64Config,
	#category : #'CMakeVMMakerSqueak-LinuxX86_64'
}

{ #category : #cmake }
Linux64SqueakCogSpur >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #'as yet unclassified' }
Linux64SqueakCogSpur >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirLinux32x8664
]

{ #category : #cmake }
Linux64SqueakCogSpur >> excludeFromBuild [
	^true

]
