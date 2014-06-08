"
A SqueakIA32BochsConfig is a Squeak Compatibility Layer between the Pharo code in CMakeVMMaker and CMakeVMakerSqueak.

I exist because modifying the pharo tree is verbotten as of 2014.06.10
"
Class {
	#name : #SqueakIA32BochsConfig,
	#superclass : #CPlatformConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#instVars : [
		'buildType'
	],
	#category : #'CMakeVMMakerSqueak-IA32-Bochs'
}

{ #category : #accessing }
SqueakIA32BochsConfig class >> availableBuilds [
	"SqueakCMakeVMMakerAbstractBuilder  allBuildConfigurations
	^#(#assert #debug  #release )"
	^SqueakCMakeVMMakerAbstractBuilder noBuildConfigurations
]

{ #category : #cmake }
SqueakIA32BochsConfig >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default  noBuildConfigurations

]

{ #category : #'squeak compatibility' }
SqueakIA32BochsConfig >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #'squeak compatibility' }
SqueakIA32BochsConfig >> buildDirName [
	buildType isNil
		ifTrue:[^self dirBuildPlatform, self dirBuildLanguageVMMM, 'build']
		ifFalse:[^self dirBuildPlatform, self dirBuildLanguageVMMM, buildType asString]
]

{ #category : #'squeak compatibility' }
SqueakIA32BochsConfig >> buildType: aSymbol [
	buildType:= aSymbol
]

{ #category : #plugins }
SqueakIA32BochsConfig >> defaultExternalPlugins [
	^ #()
]

{ #category : #plugins }
SqueakIA32BochsConfig >> defaultInternalPlugins [
	^ #()
]

{ #category : #cmake }
SqueakIA32BochsConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur the default is squeak.cog.v3"
	^self squeakCogV3
]

{ #category : #cmake }
SqueakIA32BochsConfig >> dirBuildPlatform [
	^self dirIA32Bochs
]

{ #category : #'squeak compatibility' }
SqueakIA32BochsConfig >> outputDir [
	^ outputDir ifNil: [ outputDir := (self topDir / self outputDirName) ]	
]

{ #category : #'squeak compatibility' }
SqueakIA32BochsConfig >> srcDir [
		^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'src' )]
]

{ #category : #'squeak compatibility' }
SqueakIA32BochsConfig >> topDir [
		^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
]
