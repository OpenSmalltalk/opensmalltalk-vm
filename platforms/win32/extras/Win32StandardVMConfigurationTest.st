'From Squeak3.4 of 1 March 2003 [latest update: #5170] on 9 March 2003 at 1:59:33 am'!
TestCase subclass: #Win32StandardVMConfigurationTest
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tests-Win32-VM'!
!Win32StandardVMConfigurationTest commentStamp: 'ar 3/9/2003 01:58' prior: 0!
Win32StandardVMConfigurationTest consists of a series of tests for determining whether the current system runs the "standard" configuration for Win32 VMs. "Standard" is rather loosely defined as of now and essentially means what is contained in this test. The test case can be used for two purposes:

* Determining if a VM build adheres to the standard configuration, e.g., figuring out if you (or rather _I_) forgot to include a plugin or made a mistake wrt. to internal vs. external plugins. In this sense, this test is the ultimate reference for what is considered standard and what isn't.

* Determining if a running system adheres to the standard configuration, e.g., validating that in particular none of the internal plugins get "shadowed" by an external one (this can lead to crashes). In this sense, this tests serves the purpose of identifying "non-conforming" configurations.

The configuration tests have been written in a way that allows them to pass if they're run on any other platform.!


!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 01:26'!
externalPlugin: pluginName
	"see if the plugin with the given name is present as a plugin"
	| pluginString theMethod spec result |
	Smalltalk platformName = 'Win32' ifFalse:[^self].
	pluginString := Smalltalk listBuiltinModules
		detect:[:any| any beginsWith: pluginName,' ']
		ifNone:[nil].
	self assert: pluginString isNil.

	"try loading the plugin"
	theMethod _ self class lookupSelector: #tryNamedPrimitive.
	self assert: theMethod notNil.
	theMethod ifNil:[^self].
	spec _ theMethod literalAt: 1.
	spec at: 1 put: pluginName asSymbol.
	spec at: 2 put: #''.
	spec at: 3 put: 0.
	spec at: 4 put: 0.
	theMethod flushCache.
	result := self tryNamedPrimitive.
	self assert: (result == ContextPart primitiveFailToken).

	pluginString := Smalltalk listLoadedModules
		detect:[:any| any beginsWith: pluginName,' ']
		ifNone:[nil].
	self assert: pluginString notNil.
	pluginString ifNil:[^self].
	self assert: (pluginString endsWith: ' (e)').
! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 01:26'!
internalPlugin: pluginName
	"see if the plugin with the given name is present as a plugin"
	| pluginString theMethod spec result |
	Smalltalk platformName = 'Win32' ifFalse:[^self].
	pluginString := Smalltalk listBuiltinModules
		detect:[:any| any beginsWith: pluginName,' ']
		ifNone:[nil].
	self assert: pluginString notNil.
	pluginString ifNil:[^self].

	"try loading the plugin"
	theMethod _ self class lookupSelector: #tryNamedPrimitive.
	self assert: theMethod notNil.
	theMethod ifNil:[^self].
	spec _ theMethod literalAt: 1.
	spec at: 1 put: pluginName asSymbol.
	spec at: 2 put: #''.
	spec at: 3 put: 0.
	spec at: 4 put: 0.

	theMethod flushCache.
	result := self tryNamedPrimitive.
	self assert: (result == ContextPart primitiveFailToken).

	pluginString := Smalltalk listLoadedModules
		detect:[:any| any beginsWith: pluginName,' ']
		ifNone:[nil].
	self assert: pluginString notNil.
	pluginString ifNil:[^self].
	self assert: (pluginString endsWith: ' (i)').
! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:40'!
testADPCMCodecPlugin
	self internalPlugin: 'ADPCMCodecPlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:40'!
testAsynchFilePlugin
	self internalPlugin: 'AsynchFilePlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:40'!
testB3DAcceleratorPlugin
	self internalPlugin: 'B3DAcceleratorPlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:41'!
testBMPReadWriterPlugin
	self internalPlugin: 'BMPReadWriterPlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:41'!
testDropPlugin
	self internalPlugin: 'DropPlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:41'!
testFFTPlugin
	self internalPlugin: 'FFTPlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:41'!
testFilePlugin
	self internalPlugin: 'FilePlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:42'!
testFloatArrayPlugin
	self internalPlugin: 'FloatArrayPlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:42'!
testFontPlugin
	self internalPlugin: 'FontPlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:42'!
testGeniePlugin
	self internalPlugin: 'GeniePlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:42'!
testIntegerPokerPlugin
	self internalPlugin: 'IntegerPokerPlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:42'!
testJPEGReadWriter2Plugin
	self internalPlugin: 'JPEGReadWriter2Plugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:43'!
testJPEGReaderPlugin
	self internalPlugin: 'JPEGReaderPlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:43'!
testJoystickTabletPlugin
	self internalPlugin: 'JoystickTabletPlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:43'!
testKlattPlugin
	self internalPlugin: 'Klatt'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:43'!
testLargeIntegersPlugin
	self internalPlugin: 'LargeIntegers'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:43'!
testMIDIPlugin
	self internalPlugin: 'MIDIPlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:43'!
testMatrix2x3Plugin
	self internalPlugin: 'Matrix2x3Plugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:44'!
testMiscPrimitivePlugin
	self internalPlugin: 'MiscPrimitivePlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:44'!
testMpeg3Plugin
	self internalPlugin: 'Mpeg3Plugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:44'!
testRePlugin
	self internalPlugin: 'RePlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:44'!
testSecurityPlugin
	self internalPlugin: 'SecurityPlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:44'!
testSerialPlugin
	self internalPlugin: 'SerialPlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:44'!
testSocketPlugin
	self internalPlugin: 'SocketPlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:45'!
testSoundCodecPrims
	self internalPlugin: 'SoundCodecPrims'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:45'!
testSoundGenerationPlugin
	self internalPlugin: 'SoundGenerationPlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:45'!
testSoundPlugin
	self internalPlugin: 'SoundPlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:41'!
testSqueak3DPlugin
	self internalPlugin: 'Squeak3D'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:46'!
testSqueakFFIPrims
	self externalPlugin: 'SqueakFFIPrims'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:45'!
testStarSqueakPlugin
	self internalPlugin: 'StarSqueakPlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:45'!
testSurfacePlugin
	self internalPlugin: 'SurfacePlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 01:12'!
testUUIDPlugin
	self internalPlugin: 'UUIDPlugin'.! !

!Win32StandardVMConfigurationTest methodsFor: 'as yet unclassified' stamp: 'ar 3/9/2003 00:41'!
testZipPlugin
	self internalPlugin: 'ZipPlugin'.! !
