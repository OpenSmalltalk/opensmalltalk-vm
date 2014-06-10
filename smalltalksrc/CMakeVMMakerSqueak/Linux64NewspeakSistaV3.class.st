Class {
	#name : #Linux64NewspeakSistaV3,
	#superclass : #Linux64Config,
	#category : #'CMakeVMMakerSqueak-LinuxX86_64'
}

{ #category : #cmake }
Linux64NewspeakSistaV3 >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default noBuildConfigurations
]

{ #category : #cmake }
Linux64NewspeakSistaV3 >> dirBuildLanguageVMMM [
	^self newspeakSistaV3
]

{ #category : #'as yet unclassified' }
Linux64NewspeakSistaV3 >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirLinux32x8664
]

{ #category : #cmake }
Linux64NewspeakSistaV3 >> excludeFromBuild [
	^true

]
