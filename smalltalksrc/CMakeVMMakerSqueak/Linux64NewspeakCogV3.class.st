Class {
	#name : #Linux64NewspeakCogV3,
	#superclass : #Linux64Config,
	#category : #'CMakeVMMakerSqueak-LinuxX86_64'
}

{ #category : #cmake }
Linux64NewspeakCogV3 >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #'as yet unclassified' }
Linux64NewspeakCogV3 >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirLinux32x8664
]

{ #category : #cmake }
Linux64NewspeakCogV3 >> excludeFromBuild [
	^true

]
