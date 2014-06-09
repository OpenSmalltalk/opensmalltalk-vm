Class {
	#name : #Linux64SqueakCogV3,
	#superclass : #Linux64Config,
	#category : #'CMakeVMMakerSqueak-LinuxX86_64'
}

{ #category : #cmake }
Linux64SqueakCogV3 >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #'as yet unclassified' }
Linux64SqueakCogV3 >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirLinux32x8664
]

{ #category : #cmake }
Linux64SqueakCogV3 >> excludeFromBuild [
	^true

]
