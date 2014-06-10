"
A Linux32x86SqueakCogSpurConfig  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

Usage:
Linux32x86SqueakCogSpurConfig generate
Or:
Linux32x86SqueakCogSpurConfig generateWithSources
Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me

"
Class {
	#name : #Linux32x86SqueakSistaV3Config,
	#superclass : #Linux32x86Config,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #plugins }
Linux32x86SqueakSistaV3Config >> defaultExternalPlugins [
	^ #(#B3DAcceleratorPlugin 
		 #BochsIA32Plugin 
		#SqueakFFIPrims 
		#SqueakSSL 
		#LocalePlugin 
		#UnixOSProcessPlugin 
		#UUIDPlugin)
]

{ #category : #plugins }
Linux32x86SqueakSistaV3Config >> defaultInternalPlugins [
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

{ #category : #cmake }
Linux32x86SqueakSistaV3Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakSistaV3
]

{ #category : #cmake }
Linux32x86SqueakSistaV3Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build"
	^false
]

{ #category : #'as yet unclassified' }
Linux32x86SqueakSistaV3Config >> todo [
	self flag:'tty'
]
