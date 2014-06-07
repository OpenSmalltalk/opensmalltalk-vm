"
A Linux32x86Config is a Squeak Compatibility Layer between the Pharo code in CMakeVMMaker and CMakeVMakerSqueak.

I exist because modifying the pharo tree is verbotten as of 2014.06.10


"
Class {
	#name : #Linux32x86Config,
	#superclass : #CPlatformConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#instVars : [
		'buildType'
	],
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #'squeak compatibility' }
Linux32x86Config >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> buildDirName [
	buildType isNil
		ifTrue:[^self dirBuildPlatform, self dirBuildLanguageVMMM, 'build']
		ifFalse:[^self dirBuildPlatform, self dirBuildLanguageVMMM, buildType asString]
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> buildType: aSymbol [
	buildType:= aSymbol
]

{ #category : #plugins }
Linux32x86Config >> defaultExternalPlugins [
	^ #(SqueakSSL	)
]

{ #category : #plugins }
Linux32x86Config >> defaultInternalPlugins [
" cut-n-paste from Cog/build.linux32x86/newspeak.cog.v3/build"
	^ #(
		AsynchFilePlugin 
		BMPReadWriterPlugin 
		B2DPlugin 
		BitBltPlugin 
		DSAPrims 
		DropPlugin 
		FileCopyPlugin 
		FilePlugin 
		FloatArrayPlugin 
		FloatMathPlugin 
		ZipPlugin 
		JPEGReadWriter2Plugin 
		JPEGReaderPlugin 
		LargeIntegers 
		Matrix2x3Plugin 
		MiscPrimitivePlugin 
		IA32ABI 
		RePlugin 
		SecurityPlugin 
		SocketPlugin 
		SurfacePlugin 
		UUIDPlugin 
		UnixOSProcessPlugin 
		VMProfileLinuxSupportPlugin)
]

{ #category : #cmake }
Linux32x86Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogV3
]

{ #category : #cmake }
Linux32x86Config >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirLinux32x86
]

{ #category : #cmake }
Linux32x86Config >> oscogvm [
	^ 'oscogvm'
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> outputDir [
	^ outputDir ifNil: [ outputDir := (FileDirectory default directoryNamed: (self oscogvm,FileDirectory slash, self dirOutput)) assureExistence]
	

]

{ #category : #'squeak compatibility' }
Linux32x86Config >> srcDir [
		^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'src' )]
]

{ #category : #'squeak compatibility' }
Linux32x86Config >> topDir [
	"N.B. this is a clash between Trait usage and Inheritence usage due to restrictions on modifying pharo's source"
	^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
	
]
