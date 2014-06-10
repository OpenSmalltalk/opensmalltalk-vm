Class {
	#name : #Linux64NewspeakCogSpur,
	#superclass : #Linux64Config,
	#category : #'CMakeVMMakerSqueak-LinuxX86_64'
}

{ #category : #cmake }
Linux64NewspeakCogSpur >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
Linux64NewspeakCogSpur >> dirBuildLanguageVMMM [
	^self newspeakCogSpur
]

{ #category : #'as yet unclassified' }
Linux64NewspeakCogSpur >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirLinux32x8664
]

{ #category : #cmake }
Linux64NewspeakCogSpur >> excludeFromBuild [
	^true

]
