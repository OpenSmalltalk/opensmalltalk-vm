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
	#instVars : [
		'buildType'
	],
	#category : #'CMakeVMMakerSqueak-SunOS32x86_64'
}

{ #category : #cmake }
SqueakSunOS32x8664CogConfig >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default  noBuildConfigurations


]

{ #category : #'squeak compatibility' }
SqueakSunOS32x8664CogConfig >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #'squeak compatibility' }
SqueakSunOS32x8664CogConfig >> buildDirName [
	buildType isNil
		ifTrue:[^self dirBuildPlatform, self dirBuildLanguageVMMM, 'build']
		ifFalse:[^self dirBuildPlatform, self dirBuildLanguageVMMM, buildType asString]
]

{ #category : #'squeak compatibility' }
SqueakSunOS32x8664CogConfig >> buildType: aSymbol [
	buildType:= aSymbol
]

{ #category : #cmake }
SqueakSunOS32x8664CogConfig >> defaultExternalPlugins [
	^#(	)
]

{ #category : #cmake }
SqueakSunOS32x8664CogConfig >> defaultInternalPlugins [
	^#(	)
]

{ #category : #cmake }
SqueakSunOS32x8664CogConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogV3
]

{ #category : #cmake }
SqueakSunOS32x8664CogConfig >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirSunOS32x8664
]

{ #category : #'squeak compatibility' }
SqueakSunOS32x8664CogConfig >> outputDir [
	^ outputDir ifNil: [ outputDir := (self topDir / self outputDirName) ]	

]

{ #category : #'squeak compatibility' }
SqueakSunOS32x8664CogConfig >> srcDir [
		^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'src' )]
]

{ #category : #'as yet unclassified' }
SqueakSunOS32x8664CogConfig >> todo [
	self flag:'tty'
]

{ #category : #'squeak compatibility' }
SqueakSunOS32x8664CogConfig >> topDir [
		^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
]
