Class {
	#name : #Linux32x86SqueakStackSpurConfigz,
	#superclass : #CPlatformConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#instVars : [
		'buildType'
	],
	#category : #'CMakeVMMakerSqueak-IslandOfMisfitToys'
}

{ #category : #plugins }
Linux32x86SqueakStackSpurConfigz >> defaultExternalPlugins [
	^ #(SqueakSSL	)
]

{ #category : #plugins }
Linux32x86SqueakStackSpurConfigz >> defaultInternalPlugins [
" cut-n-paste from Cog/build.linux32x86/squeak.stack.spur/build"
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
		VMProfileLinuxSupportPlugin
		)
]

{ #category : #cmake }
Linux32x86SqueakStackSpurConfigz >> excludeFromBuild [
"	^false"   "build this configuration"
	^true


]

{ #category : #'as yet unclassified' }
Linux32x86SqueakStackSpurConfigz >> todo [
	self flag:'tty'
]
