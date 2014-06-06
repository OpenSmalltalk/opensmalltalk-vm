Class {
	#name : #Linux32x86SqueakCogSpurConfig,
	#superclass : #Linux32x86Config,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #'as yet unclassified' }
Linux32x86SqueakCogSpurConfig >> defaultExternalPlugins [
	^ #(#B3DAcceleratorPlugin 
		 #BochsIA32Plugin 
		#SqueakFFIPrims 
		#SqueakSSL 
		#LocalePlugin 
		#UnixOSProcessPlugin 
		#UUIDPlugin)
]

{ #category : #'as yet unclassified' }
Linux32x86SqueakCogSpurConfig >> defaultInternalPlugins [
	^ #(#AsynchFilePlugin
		#BMPReadWriterPlugin
		#B2DPlugin
		#BitBltPlugin
		#DSAPrims
		#DropPlugin
		#FileCopyPlugin
		#FilePlugin
		#FloatArrayPlugin
		#FloatMathPlugin
		#ZipPlugin
		#JPEGReadWriter2Plugin
		#JPEGReaderPlugin
		#LargeIntegers
		#Matrix2x3Plugin
		#MiscPrimitivePlugin
		#IA32ABI
		#RePlugin
		#SecurityPlugin
		#SocketPlugin
		#SurfacePlugin
		#UUIDPlugin
		#UnixOSProcessPlugin
		#VMProfileLinuxSupportPlugin)
]

{ #category : #'as yet unclassified' }
Linux32x86SqueakCogSpurConfig >> todo [
	self flag:'tty'
]
