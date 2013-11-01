"
This class builds a VM codebase from the in-image and on-file code.

The platforms file tree you need can be downloaded via cvs from http://squeak.Sourceforge.net. See also the swiki (http://minnow.cc.gatech.edu/squeak/2106) for instructions.

It is fairly configurable as to where directories live and can handle multiple platform's source trees at once. It's main purpose is to allow easy building of source trees with any combination of internal/external/unused plugins to suit your platform needs and capabilities. For example, the Acorn has no need of Sound or AsynchFile plugins since I haven't written any platform code for them. 

There is a simple UI tool for this 
	VMMakerTool openInWorld
will open a reasonably self explanatory tool with balloon help to explain all the fields - and a help window on top of that.

There are some simple workspace & inspector commands, allowing scripted building:
	VMMaker default initializeAllExternal generateEntire
for example will build sources for a system with all the plugins external whereas 
	VMMaker default initializeAllInternal generateEntire
would build all applicable plugins for internal compilation.
	(VMMaker forPlatform: 'Mac OS') initializeAllExternal generateEntire
would build a source tree for a Mac even on a Windows machine (err, ignoring for now the irritation of lineends).

	If you have a slightly more complex configuration you want to use, perhaps with Socket and Serial support external (because for your case they are rarely used and saving the space has some value) then you could try
		(VMMaker default initializeAllInternalBut: #(SocketPlugin SerialPlugin) generateEntire
	More complex still would be
		(VMMaker default initializeInternal: #(BitBltPlugin MiscPrimsPlugin FilePlugin) external: #(SocketPlugin ZipPlugin B2DPlugin)
which allows you to precisely list all the plugins to use.

WARNING If you miss out a plugin you need, it won't be there. This message is really best suited to use by a UI like VMMakerTool.

	To save a configuration for later use, you need to send #saveConfiguration to an active instance of VMMaker. Obviously you could simply use
		(VMMaker default initializeAllInternalBut: #(SocketPlugin SerialPlugin) saveConfiguration
but inspecting 
		VMMaker default
and altering the internalPlugins and externalPlugins or the boolean flags for inline or forBrowser followed by saving the configuration allows ultimate power for now. To load a saved configuration file, use #loadConfigurationFrom: aFilename whilst inspecting a VMMaker. The loaded state will completely override any pre-existing state, so take care.
	You can generate only parts of the source tree if you wish; as shown above #generateEntire will create the whole collection of internal and external plugins as well as the core VM. To create only  the external plugins use #generateExternalPlugins, or create a single  plugin with #generateExternalPlugin: name. To assemble the main VM including the internal plugins, use #generateMainVM. The interpreter 'interp.c' file is made with #generateInterpreterFile. You can generate a single internal plugin with #generateInternalPlugin: only if it has already been generated before; this interlocking is intended to make sure the named primitive table in the vm is correct.

There are some rules to observe in order to use this:-
- under the working directory (by default - you can configure it) you need a directory called 'platforms' (also configurable) with subdirectories named as the platform names returned by Smalltalk platformName (ie unix, RiscOS, Mac OS, etc - this isn't configurable). At the very least you need the one for your own platform and the pseudo-platform called 'Cross'. By adding a 'DirNames' entry for #machineType you can cross 'compile' for some other platform. Now all we need is a cross-compiler for the C code :-)
- under this directory you must have a simple structure of directories for each generated plugin that you support on the platform, plus 'vm'. In each directory you place any/all platform specific files (and subdirectories) for that plugin. In 'misc' you can place any miscellaneous files such as makefiles, resources etc. For example, for unix you have
	platforms/
		unix/
			plugins/
				AsynchFilePlugin /
					sqUnixAsynchfile.c
			vm/
				sqGnu.h
				Profile/
			misc/
				makefile.in
				util/
				
				...etc
Any plugins requiring platform files that you don't support shouldn't appear in the resulting code tree. If you try to include an unsupported plugin in the list to be made external, the VMMaker simply ignores it. However, if you include it in the list to be made internal you will get an error since that seems like a potentially serious source of confusion.

There are three lists of plugins maintained herein:-
1) the list of all known generatable plugins. We scan this list and compare with the supported plugins as indicated by the file tree.
2) the list of chosen internal plugins.
3) the list of chosen external plugins.
See initializeAllPlugins, initialiseAllExternal etc for fairly obvious usage.
There is also a short list of directory names in the class variable 'DirNames' that you can alter if needed.

Known problems:-
a) since Squeak has really poor filename handling, you can't simply change the directory names to '/foo/bar/myEvilCodeBase' and expect it to work. You fix file names and I'll fix VMMaker :-)
b) Squeak copying of a file loses the assorted permissions, filetype info and other useful bits. To workaround this problem, see the FileCopyPlugin, which provides the platform independent part of a simple access for the OS filecopy capability. So far there are functional plugins for unix, Mac and Acorn. DOS machines appear not to need one. This is less of a problem in practise now that unix, Acorn & Mac no longer copy files from /platforms to /src.

inline <Boolean> - is the generated code to be inlined or not
forBrowser <Boolean> - is this to be a build for in-Browser use? Only relevent to Macs
allPlugins <Collection> - all the known possible plugins
internalPlugins <Collection> - the plugins chosen to be generated for internal linking
externalPlugins <Collection> - the plugins intended to be external plugins
exportList <Collection> - a list of function names exported from plugins intended to be internal
platformName <String> - the name of the platform for which we are building a source tree. It is possible to do 'cross-compiles'
sourceDirName, platformRootDirName <String> - the name of the directory into which we write the generated sources and the name of the directory where we should find the platforms tree.
"
Class {
	#name : #VMMaker,
	#superclass : #Object,
	#instVars : [
		'inline',
		'forBrowser',
		'allPlugins',
		'internalPlugins',
		'externalPlugins',
		'platformName',
		'sourceDirName',
		'platformRootDirName',
		'logger',
		'interpreterClassName',
		'cogitClassName',
		'is64BitVM',
		'optionsDictionary'
	],
	#classVars : [
		'DirNames'
	],
	#category : #'VMMaker-Building'
}

{ #category : #initialisation }
VMMaker class >> activeVMMakerClassFor: platformName [
	"Return the concrete VMMaker subclass for the platform on which we are currently running."

	VMMaker allSubclasses do: [:class |
		(class isActiveVMMakerClassFor: platformName) ifTrue: [^ class]].

	"no responding subclass; use VMMaker"
	^ VMMaker

]

{ #category : #accessing }
VMMaker class >> coreVMDirName [
	^DirNames at: #coreVMDir
]

{ #category : #initialisation }
VMMaker class >> default [
	"return a VMMaker initialised to build a default no-internal-plugins, no-external-plugins vm codebase"
	^self forPlatform: (true
						ifTrue: ['Cross'] 
						ifFalse: [SmalltalkImage current platformName])
]

{ #category : #initialisation }
VMMaker class >> forConfigurationFile: aFileName [
	| config fileStream vmMaker |

	fileStream := FileStream oldFileNamed: aFileName.
	config := ('#(' includes: fileStream peek) "for storeOn: format"
				ifTrue: [Object readFrom: fileStream]
				ifFalse: [fileStream fileInObjectAndCode].
	vmMaker := self forPlatform: (config at: 5).
	vmMaker loadConfiguration: config.
	^vmMaker
]

{ #category : #initialisation }
VMMaker class >> forPlatform: platformName [
	"return a VMMaker initialised to build a default no-internal-plugins, no-external-plugins vm codebase"
	^(self activeVMMakerClassFor: platformName) new initialize setPlatName: platformName
]

{ #category : #utilities }
VMMaker class >> forceNewFileNamed: aFilename [
	"Always output files in unix lf format.
		A single format is friendlier to e.g. external version control systems.
		The Microsoft and old MacOS classic C compilers all accept lf format files."

	^(MultiByteFileStream forceNewFileNamed: aFilename)
		lineEndConvention: #lf;
		yourself
]

{ #category : #utilities }
VMMaker class >> generate: interpreterClass and: cogitClass to: srcDirName platformDir: platDirName excluding: exclusions [
	"Generate the VM to the given target directory. Exclude plugins in pluginList.
	 Example:
		(VMMaker
			generate: CoInterpreter
			and: SimpleStackBasedCogit
			to: (FileDirectory default pathFromURI: '../src')
			platformDir: (FileDirectory default pathFromURI: '../platforms')
			excluding:#(
				BrokenPlugin DShowVideoDecoderPlugin IA32ABIPluginSimulator
				NewsqueakIABIPlugin NewsqueakIABIPluginAttic
				QuicktimePlugin QVideoCodecPlugin QwaqMediaPlugin
				SlangTestPlugin TestOSAPlugin ThreadedFFIPlugin 
				Win32OSProcessPlugin
			))"
	(self
		makerFor: interpreterClass
		and: cogitClass
		with: #()
		to: srcDirName
		platformDir: platDirName
		excluding: exclusions) generateEntire
]

{ #category : #utilities }
VMMaker class >> generate: interpreterClass and: cogitClass to: srcDirName platformDir: platDirName including: inclusions [
	"Generate the VM to the given target directory. Include only plugins in pluginList.
	 Example:
		(VMMaker
			generate: CoInterpreter
			and: SimpleStackBasedCogit
			to: (FileDirectory default pathFromURI: '../src')
			platformDir: (FileDirectory default pathFromURI: '../platforms')
			including:#(	AsynchFilePlugin FloatArrayPlugin RePlugin B2DPlugin FloatMathPlugin SecurityPlugin
						BMPReadWriterPlugin IA32ABI SocketPlugin BitBltPlugin JPEGReadWriter2Plugin SurfacePlugin
						DSAPrims JPEGReaderPlugin UUIDPlugin DropPlugin LargeIntegers UnixOSProcessPlugin
						FileCopyPlugin Matrix2x3Plugin Win32OSProcessPlugin FilePlugin MiscPrimitivePlugin ZipPlugin))"
	^self generate: interpreterClass and: cogitClass with: #() to: srcDirName platformDir: platDirName including: inclusions
]

{ #category : #utilities }
VMMaker class >> generate: interpreterClass and: cogitClass with: optionsPairsArray to: srcDirName platformDir: platDirName including: inclusions [
	"Generate the VM to the given target directory. Include only plugins in pluginList.
	 Example:
		(VMMaker
			generate: CoInterpreter
			and: SimpleStackBasedCogit
			to: (FileDirectory default pathFromURI: '../src')
			platformDir: (FileDirectory default pathFromURI: '../platforms')
			including:#(	AsynchFilePlugin FloatArrayPlugin RePlugin B2DPlugin FloatMathPlugin SecurityPlugin
						BMPReadWriterPlugin IA32ABI SocketPlugin BitBltPlugin JPEGReadWriter2Plugin SurfacePlugin
						DSAPrims JPEGReaderPlugin UUIDPlugin DropPlugin LargeIntegers UnixOSProcessPlugin
						FileCopyPlugin Matrix2x3Plugin Win32OSProcessPlugin FilePlugin MiscPrimitivePlugin ZipPlugin))"
	(self
		makerFor: interpreterClass
		and: cogitClass
		with: optionsPairsArray
		to: srcDirName
		platformDir: platDirName
		including: inclusions) generateEntire
]

{ #category : #utilities }
VMMaker class >> generate: interpreterClass to: srcDirName platformDir: platDirName excluding: exclusions [
	"Generate the VM to the given target directory. Exclude plugins in pluginList.
	 Example:
		(VMMaker
			generate: CoInterpreter
			to: (FileDirectory default pathFromURI: '../src')
			platformDir: (FileDirectory default pathFromURI: '../platforms')
			excluding:#(
				BrokenPlugin DShowVideoDecoderPlugin IA32ABIPluginSimulator
				NewsqueakIABIPlugin NewsqueakIABIPluginAttic
				QuicktimePlugin QVideoCodecPlugin QwaqMediaPlugin
				SlangTestPlugin TestOSAPlugin ThreadedFFIPlugin 
				Win32OSProcessPlugin
			))."
	(self
		makerFor: interpreterClass
		and: nil
		with: #()
		to: srcDirName
		platformDir: platDirName
		excluding: exclusions) generateEntire
]

{ #category : #utilities }
VMMaker class >> generate: interpreterClass to: srcDirName platformDir: platDirName including: inclusions [
	"Generate the VM to the given target directory. Include only plugins in pluginList.
	 Example:
		(VMMaker
			generate: NewspeakInterpreter
			to: (FileDirectory default pathFromURI: 'cogvm/newspeaksrc')
			platformDir: (FileDirectory default pathFromURI: 'cogvm/platforms')
			including:#(	AsynchFilePlugin FloatArrayPlugin RePlugin B2DPlugin FloatMathPlugin SecurityPlugin
						BMPReadWriterPlugin IA32ABI SocketPlugin BitBltPlugin JPEGReadWriter2Plugin SurfacePlugin
						DSAPrims JPEGReaderPlugin UUIDPlugin DropPlugin LargeIntegers UnixOSProcessPlugin
						FileCopyPlugin Matrix2x3Plugin Win32OSProcessPlugin FilePlugin MiscPrimitivePlugin ZipPlugin))."
	self generate: interpreterClass with: #() to: srcDirName platformDir: platDirName including: inclusions
]

{ #category : #utilities }
VMMaker class >> generate: interpreterClass with: optionsPairsArray to: srcDirName platformDir: platDirName excluding: exclusions [
	"Generate the VM to the given target directory. Include only plugins in pluginList.
	 Example:
		(VMMaker
			generate: StackInterpreter
			with: #(ObjectMemory Spur32BitMemoryManager)
			to: (FileDirectory default directoryNamed: 'oscogvm/spurstacksrc') fullName
			platformDir: (FileDirectory default directoryNamed: 'oscogvm/platforms') fullName
			excluding: (InterpreterPlugin withAllSubclasses collect: [:ea| ea name]))."
	(self makerFor: interpreterClass and: nil with: optionsPairsArray to: srcDirName platformDir: platDirName excluding: exclusions) generateEntire
]

{ #category : #utilities }
VMMaker class >> generate: interpreterClass with: optionsPairsArray to: srcDirName platformDir: platDirName including: inclusions [
	"Generate the VM to the given target directory. Include only plugins in pluginList.
	 Example:
		(VMMaker
			generate: NewspeakInterpreter
			to: (FileDirectory default pathFromURI: 'cogvm/newspeaksrc')
			with: #(IMMUTABILITY true)
			platformDir: (FileDirectory default pathFromURI: 'cogvm/platforms')
			including:#(	AsynchFilePlugin FloatArrayPlugin RePlugin B2DPlugin FloatMathPlugin SecurityPlugin
						BMPReadWriterPlugin IA32ABI SocketPlugin BitBltPlugin JPEGReadWriter2Plugin SurfacePlugin
						DSAPrims JPEGReaderPlugin UUIDPlugin DropPlugin LargeIntegers UnixOSProcessPlugin
						FileCopyPlugin Matrix2x3Plugin Win32OSProcessPlugin FilePlugin MiscPrimitivePlugin ZipPlugin))."
	(self makerFor: interpreterClass and: nil with: optionsPairsArray to: srcDirName platformDir: platDirName including: inclusions) generateEntire
]

{ #category : #configurations }
VMMaker class >> generateConfiguration [
	"VMMaker generateConfiguration"
	| configCategoryName selectors |
	configCategoryName := self class whichCategoryIncludesSelector: thisContext selector.
	selectors := Set new.
	self class organization categories do:
		[:cat|
		(cat endsWith: configCategoryName) ifTrue:
			[selectors addAll: (self class organization listAtCategoryNamed: cat)]].
	selectors remove: thisContext selector.
	selectors := selectors asArray sort.
	(UIManager default
			chooseFrom: (selectors collect:
							[:sel| (sel piecesCutWhere: [:a :b| a isLowercase and: [b isUppercase]]) allButFirst
									fold: [:a :b| a, ' ', b]])
			values: selectors) ifNotNil:
		[:choice|
		self perform: choice]
]

{ #category : #configurations }
VMMaker class >> generateNewSqueakCogVM [
	"self generateNewSqueakCogVM"
	^VMMaker
		generate: (Smalltalk at: ([:choices| choices at: (UIManager default chooseFrom: choices) ifAbsent: [^self]]
									value: #(CoInterpreter CoInterpreterMT)))
		and: StackToRegisterMappingCogit
		with: #(	MULTIPLEBYTECODESETS false
				NewspeakVM false
				bytecodeTableInitializer newInitializeBytecodeTableForSqueakV3PlusClosures)
		to: (FileDirectory default pathFromURI: 'oscogvm/src')
		platformDir: (FileDirectory default pathFromURI: 'oscogvm/platforms')
		including:#(	ADPCMCodecPlugin AsynchFilePlugin BalloonEnginePlugin B3DAcceleratorPlugin
					BMPReadWriterPlugin BitBltSimulation BochsIA32Plugin CroquetPlugin DSAPlugin
					DeflatePlugin DropPlugin FT2Plugin FFTPlugin FileCopyPlugin FilePlugin FloatArrayPlugin
					FloatMathPlugin GeniePlugin HostWindowPlugin IA32ABIPlugin InternetConfigPlugin
					JPEGReadWriter2Plugin JPEGReaderPlugin JoystickTabletPlugin KlattSynthesizerPlugin
					LargeIntegersPlugin LocalePlugin MIDIPlugin MacMenubarPlugin Matrix2x3Plugin
					MiscPrimitivePlugin Mpeg3Plugin QuicktimePlugin RePlugin SecurityPlugin SerialPlugin
					SocketPlugin SoundCodecPlugin SoundGenerationPlugin SoundPlugin SqueakSSLPlugin StarSqueakPlugin
					ThreadedIA32FFIPlugin UnixAioPlugin UUIDPlugin UnixOSProcessPlugin
					Win32OSProcessPlugin VMProfileLinuxSupportPlugin VMProfileMacSupportPlugin)
]

{ #category : #configurations }
VMMaker class >> generateNewspeakCogVM [
	^VMMaker
		generate: CoInterpreter
		and: StackToRegisterMappingCogit"Cogit chooseCogitClass"
		with: #(	NewspeakVM true
				MULTIPLEBYTECODESETS true)
		to: (FileDirectory default pathFromURI: 'oscogvm/nscogsrc')
		platformDir: (FileDirectory default pathFromURI: 'oscogvm/platforms')
		including:#(	AsynchFilePlugin BMPReadWriterPlugin BalloonEnginePlugin BitBltSimulation DSAPlugin DropPlugin
					FileCopyPlugin FilePlugin FloatArrayPlugin FloatMathPlugin InflatePlugin JPEGReadWriter2Plugin
					JPEGReaderPlugin LargeIntegersPlugin Matrix2x3Plugin MiscPrimitivePlugin NewsqueakIA32ABIPlugin
					RePlugin SecurityPlugin SocketPlugin SoundPlugin SqueakSSLPlugin SurfacePlugin ThreadedIA32FFIPlugin
					UUIDPlugin UnixOSProcessPlugin VMProfileLinuxSupportPlugin VMProfileMacSupportPlugin Win32OSProcessPlugin)
]

{ #category : #configurations }
VMMaker class >> generateNewspeakInterpreterVM [
	^VMMaker
		generate: NewspeakInterpreter
		to: (FileDirectory default pathFromURI: 'oscogvm/nssrc')
		platformDir: (FileDirectory default pathFromURI: 'oscogvm/platforms')
		including:#(	AsynchFilePlugin BMPReadWriterPlugin BalloonEnginePlugin BitBltSimulation DSAPlugin DropPlugin
					FileCopyPlugin FilePlugin FloatArrayPlugin FloatMathPlugin InflatePlugin JPEGReadWriter2Plugin
					JPEGReaderPlugin LargeIntegersPlugin Matrix2x3Plugin MiscPrimitivePlugin NewsqueakIA32ABIPlugin
					RePlugin SecurityPlugin SocketPlugin SoundPlugin SqueakSSLPlugin SurfacePlugin
					UUIDPlugin UnixOSProcessPlugin VMProfileLinuxSupportPlugin VMProfileMacSupportPlugin Win32OSProcessPlugin)
]

{ #category : #configurations }
VMMaker class >> generateNewspeakStackVM [
	^VMMaker
		generate: StackInterpreter
		with: #(NewspeakVM true MULTIPLEBYTECODESETS true)
		to: (FileDirectory default pathFromURI: 'oscogvm/nsstacksrc')
		platformDir: (FileDirectory default pathFromURI: 'oscogvm/platforms')
		including:#(	AsynchFilePlugin BMPReadWriterPlugin BalloonEnginePlugin BitBltSimulation DSAPlugin DropPlugin
					FileCopyPlugin FilePlugin FloatArrayPlugin FloatMathPlugin InflatePlugin JPEGReadWriter2Plugin
					JPEGReaderPlugin LargeIntegersPlugin Matrix2x3Plugin MiscPrimitivePlugin NewsqueakIA32ABIPlugin
					RePlugin SecurityPlugin SocketPlugin SoundPlugin SurfacePlugin SqueakSSLPlugin ThreadedIA32FFIPlugin
					UUIDPlugin UnixOSProcessPlugin VMProfileLinuxSupportPlugin VMProfileMacSupportPlugin Win32OSProcessPlugin)
]

{ #category : #configurations }
VMMaker class >> generateSqueakCogSistaVM [
	^VMMaker
		generate: CoInterpreter
		and: SistaStackToRegisterMappingCogit
		to: (FileDirectory default pathFromURI: 'oscogvm/sistasrc')
		platformDir: (FileDirectory default pathFromURI: 'oscogvm/platforms')
		excluding: (InterpreterPlugin withAllSubclasses collect: [:ea| ea name])
]

{ #category : #configurations }
VMMaker class >> generateSqueakCogVM [
	^VMMaker
		generate: (Smalltalk at: ([:choices| choices at: (UIManager default chooseFrom: choices) ifAbsent: [^self]]
									value: #(CoInterpreter CoInterpreterMT)))
		and: StackToRegisterMappingCogit
		with: #(	MULTIPLEBYTECODESETS false
				NewspeakVM false)
		to: (FileDirectory default pathFromURI: 'oscogvm/src')
		platformDir: (FileDirectory default pathFromURI: 'oscogvm/platforms')
		including:#(	ADPCMCodecPlugin AsynchFilePlugin BalloonEnginePlugin B3DAcceleratorPlugin
					BMPReadWriterPlugin BitBltSimulation BochsIA32Plugin CroquetPlugin DSAPlugin
					DeflatePlugin DropPlugin FT2Plugin FFTPlugin FileCopyPlugin FilePlugin FloatArrayPlugin
					FloatMathPlugin GeniePlugin HostWindowPlugin IA32ABIPlugin InternetConfigPlugin
					JPEGReadWriter2Plugin JPEGReaderPlugin JoystickTabletPlugin KlattSynthesizerPlugin
					LargeIntegersPlugin LocalePlugin MIDIPlugin MacMenubarPlugin Matrix2x3Plugin
					MiscPrimitivePlugin Mpeg3Plugin QuicktimePlugin RePlugin SecurityPlugin SerialPlugin
					SocketPlugin SoundCodecPlugin SoundGenerationPlugin SoundPlugin SqueakSSLPlugin StarSqueakPlugin
					ThreadedIA32FFIPlugin UnixAioPlugin UUIDPlugin UnixOSProcessPlugin
					Win32OSProcessPlugin VMProfileLinuxSupportPlugin VMProfileMacSupportPlugin)
]

{ #category : #configurations }
VMMaker class >> generateSqueakSpurStackVM [
	"No primitives since we can use those for the Cog VM"
	^VMMaker
		generate: StackInterpreter
		with: #(ObjectMemory Spur32BitMemoryManager)
		to: (FileDirectory default directoryNamed: 'oscogvm/spurstacksrc') fullName
		platformDir: (FileDirectory default directoryNamed: 'oscogvm/platforms') fullName
		excluding: (InterpreterPlugin withAllSubclasses collect: [:ea| ea name])
]

{ #category : #configurations }
VMMaker class >> generateSqueakStackVM [
	"No primitives since we can use those for the Cog VM"
	^VMMaker
		generate: StackInterpreter
		to: (FileDirectory default directoryNamed: 'oscogvm/stacksrc') fullName
		platformDir: (FileDirectory default directoryNamed: 'oscogvm/platforms') fullName
		excluding: (InterpreterPlugin withAllSubclasses collect: [:ea| ea name])
]

{ #category : #'version testing' }
VMMaker class >> headerNotice [
"return a string to be put at the front of generated code files"
	^String streamContents:[:strm|
		strm nextPutAll: 'Automatically generated from Squeak on '.
		strm nextPutAll: Time dateAndTimeNow printString.
		strm cr.
		strm nextPutAll: 'by VMMaker '.
		strm nextPutAll: self  versionString.
		strm cr]
]

{ #category : #initialisation }
VMMaker class >> initialize [
	"VMMaker initialize"
	DirNames := Dictionary new.
	DirNames at: #coreVMDir put: 'vm';
		at: #platformsDir put: 'platforms';
		at: #pluginsDir put: 'plugins';
		at: #sourceDir put: 'src'
]

{ #category : #initialisation }
VMMaker class >> isActiveVMMakerClassFor: platformName [ 
	"Does this class claim to be that properly active subclass of VMMaker for 
	this platform? Subclasses are welcome to override this default"
	^ platformName , '*' match: self name
]

{ #category : #accessing }
VMMaker class >> machinesDirName [
	^DirNames at: #machineType ifAbsent:[SmalltalkImage current platformName]
]

{ #category : #utilities }
VMMaker class >> makerFor: interpreterClass and: cogitClassOrNil to: srcDirName platformDir: platDirName [
	"Initialize a VMMaker to generate the VM to the given target directory. Include plugins in pluginList.
	Example:
		(VMMaker
			generate: NewspeakInterpreter
			to: (FileDirectory default pathFromURI: 'cogvm/newspeaksrc')
			platformDir: (FileDirectory default pathFromURI: 'cogvm/platforms')
			including:#(	AsynchFilePlugin FloatArrayPlugin RePlugin B2DPlugin FloatMathPlugin SecurityPlugin
						BMPReadWriterPlugin IA32ABI SocketPlugin BitBltPlugin JPEGReadWriter2Plugin SurfacePlugin
						DSAPrims JPEGReaderPlugin UUIDPlugin DropPlugin LargeIntegers UnixOSProcessPlugin
						FileCopyPlugin Matrix2x3Plugin Win32OSProcessPlugin FilePlugin MiscPrimitivePlugin ZipPlugin))"
	| maker |
	maker := self forPlatform: 'Cross'.
	maker sourceDirectoryName: srcDirName.
	maker platformRootDirectoryName: platDirName.
	maker interpreterClass: interpreterClass.
	cogitClassOrNil ifNotNil: [maker cogitClass: cogitClassOrNil].
	^maker

]

{ #category : #utilities }
VMMaker class >> makerFor: interpreterClass and: cogitClassOrNil with: optionsPairsArray to: srcDirName platformDir: platDirName [
	"Initialize a VMMaker to generate the VM to the given target directory. Include plugins in pluginList.
	Example:
		(VMMaker
			generate: NewspeakInterpreter
			to: (FileDirectory default pathFromURI: 'cogvm/newspeaksrc')
			platformDir: (FileDirectory default pathFromURI: 'cogvm/platforms')
			including:#(	AsynchFilePlugin FloatArrayPlugin RePlugin B2DPlugin FloatMathPlugin SecurityPlugin
						BMPReadWriterPlugin IA32ABI SocketPlugin BitBltPlugin JPEGReadWriter2Plugin SurfacePlugin
						DSAPrims JPEGReaderPlugin UUIDPlugin DropPlugin LargeIntegers UnixOSProcessPlugin
						FileCopyPlugin Matrix2x3Plugin Win32OSProcessPlugin FilePlugin MiscPrimitivePlugin ZipPlugin))"
	| maker |
	maker := self forPlatform: 'Cross'.
	maker sourceDirectoryName: srcDirName.
	maker platformRootDirectoryName: platDirName.
	maker interpreterClass: interpreterClass.
	cogitClassOrNil ifNotNil: [maker cogitClass: cogitClassOrNil].
	maker options: optionsPairsArray.
	^maker

]

{ #category : #utilities }
VMMaker class >> makerFor: interpreterClass and: cogitClassOrNil with: optionsPairsArray to: srcDirName platformDir: platDirName excluding: exclusions [
	"Initialize a VMMaker to generate the VM to the given target directory. Exclude plugins in pluginList.
	Example:
		(VMMaker
			makerFor: CoInterpreter
			and: SimpleStackBasedCogit
			to: (FileDirectory default pathFromURI: '../src')
			platformDir: (FileDirectory default pathFromURI: '../platforms')
			excluding:#(
				BrokenPlugin DShowVideoDecoderPlugin IA32ABIPluginSimulator
				NewsqueakIABIPlugin NewsqueakIABIPluginAttic
				QuicktimePlugin QVideoCodecPlugin QwaqMediaPlugin
				SlangTestPlugin TestOSAPlugin ThreadedFFIPlugin 
				Win32OSProcessPlugin))
			generateInterpreterFile.
	"
	| maker |
	maker := self makerFor: interpreterClass and: cogitClassOrNil with: optionsPairsArray to: srcDirName platformDir: platDirName.
	maker externalModules addAll: 
		(maker availablePlugins reject:[:plugin| exclusions includes: plugin]).
	^maker

]

{ #category : #utilities }
VMMaker class >> makerFor: interpreterClass and: cogitClassOrNil with: optionsPairsArray to: srcDirName platformDir: platDirName including: inclusions [
	"Initialize a VMMaker to generate the VM to the given target directory. Include plugins in pluginList.
	Example:
		(VMMaker
			generate: NewspeakInterpreter
			to: (FileDirectory default pathFromURI: 'cogvm/newspeaksrc')
			platformDir: (FileDirectory default pathFromURI: 'cogvm/platforms')
			including:#(	AsynchFilePlugin FloatArrayPlugin RePlugin B2DPlugin FloatMathPlugin SecurityPlugin
						BMPReadWriterPlugin IA32ABI SocketPlugin BitBltPlugin JPEGReadWriter2Plugin SurfacePlugin
						DSAPrims JPEGReaderPlugin UUIDPlugin DropPlugin LargeIntegers UnixOSProcessPlugin
						FileCopyPlugin Matrix2x3Plugin Win32OSProcessPlugin FilePlugin MiscPrimitivePlugin ZipPlugin))"
	| maker |
	maker := self makerFor: interpreterClass and: cogitClassOrNil with: optionsPairsArray to: srcDirName platformDir: platDirName.
	maker externalModules addAll: inclusions.
	^maker

]

{ #category : #accessing }
VMMaker class >> platformsDirName [
	^DirNames at: #platformsDir
]

{ #category : #accessing }
VMMaker class >> pluginsDirName [
	^DirNames at: #pluginsDir
]

{ #category : #accessing }
VMMaker class >> sourceDirName [
	^DirNames at: #sourceDir
]

{ #category : #'version testing' }
VMMaker class >> versionString [
	"VMMaker versionString"

	^'4.7.0 (Cog)'
]

{ #category : #'plugin lists' }
VMMaker >> allModuleNames [
	"return the list of all the all plugins' moduleNames"
	^Array streamContents:[:strm| self allPluginsDo:[:pl| strm nextPut: pl moduleName ]]
]

{ #category : #'plugin lists' }
VMMaker >> allPluginsDo: aBlock [ 
	"for each class that should be an external plugin, evaluate aBlock"
	self externalPluginsDo: aBlock.
	self internalPluginsDo: aBlock.
]

{ #category : #'UI access' }
VMMaker >> availablePlugins [
	allPlugins ifNil:[self initializeAllPlugins].
	^allPlugins
]

{ #category : #'generate sources' }
VMMaker >> buildCodeGeneratorForCogit [
	"Answer the code generator for translating the cogit."

	^self buildCodeGeneratorForCogit: true
]

{ #category : #'generate sources' }
VMMaker >> buildCodeGeneratorForCogit: getAPIMethods [
	"Answer the code generator for translating the cogit."

	| cg cogitClass cogitClasses apicg |
	cg := self createCogitCodeGenerator.

	cg vmClass: (cogitClass := self cogitClass).
	{ cogitClass. self interpreterClass. self interpreterClass objectMemoryClass } do:
		[:cgc|
		(cgc respondsTo: #initializeWithOptions:)
			ifTrue: [cgc initializeWithOptions: optionsDictionary]
			ifFalse: [cgc initialize]].

	cogitClasses := OrderedCollection new.
	[cogitClasses addFirst: cogitClass.
	 cogitClass ~~ Cogit
	 and: [cogitClass inheritsFrom: Cogit]] whileTrue:
		[cogitClass := cogitClass superclass].
	cogitClasses addFirst: VMClass.
	cogitClasses addAllLast: ((self cogitClass ancilliaryClasses: optionsDictionary) reject: [:class| class isStructClass]).
	cogitClasses do: [:cgc| cg addClass: cgc].
	cg addStructClasses: (cg structClassesForTranslationClasses: cogitClasses).

	getAPIMethods ifTrue:
		[apicg := self buildCodeGeneratorForInterpreter: false.
		 cg apiMethods: apicg selectAPIMethods].

	^cg
]

{ #category : #'generate sources' }
VMMaker >> buildCodeGeneratorForInterpreter [
	"Answer the code generator for translating the interpreter."

	^self buildCodeGeneratorForInterpreter: true
]

{ #category : #'generate sources' }
VMMaker >> buildCodeGeneratorForInterpreter: getAPIMethods [
	"Answer the code generator for translating the interpreter."

	| cg interpreterClass interpreterClasses apicg |
	interpreterClasses := OrderedCollection new.

	interpreterClass := self interpreterClass.
	interpreterClass initializeWithOptions: optionsDictionary.

	(cg := self createCodeGenerator) vmClass: interpreterClass.

	[interpreterClass ~~ VMClass] whileTrue:
		[interpreterClasses addFirst: interpreterClass.
		 interpreterClass := interpreterClass superclass].
	
	cg vmClass objectMemoryClass ifNotNil:
		[:objectMemoryClass|
		interpreterClass := objectMemoryClass.
		[interpreterClass ~~ VMClass] whileTrue:
			[interpreterClasses addFirst: interpreterClass.
			 interpreterClass := interpreterClass superclass]].

	interpreterClasses addFirst: VMClass.
	interpreterClasses addAllLast: (cg nonStructClassesForTranslationClasses: interpreterClasses).

	interpreterClasses do:
		[:ic|
		(ic respondsTo: #initializeWithOptions:)
			ifTrue: [ic initializeWithOptions: optionsDictionary]
			ifFalse: [ic initialize]].
	(cg structClassesForTranslationClasses: interpreterClasses) do:
		[:structClass| structClass initialize].

	cg addStructClasses: (cg structClassesForTranslationClasses: interpreterClasses).

	interpreterClasses do: [:ic| cg addClass: ic].

	(getAPIMethods
	and: [self interpreterClass needsCogit]) ifTrue:
		[apicg := self buildCodeGeneratorForCogit: false.
		 cg apiMethods: apicg selectAPIMethods].

	^cg
]

{ #category : #'plugin lists' }
VMMaker >> canSupportPlugin: pluginClassName [ 
	"see if this plugin needs any external files and if so, check to see if 
	they seem to exist."
	[self validatePlugin: pluginClassName in: allPlugins , internalPlugins , externalPlugins]
		on: VMMakerException
		do: [^ false].
	^ true
]

{ #category : #'generate sources' }
VMMaker >> cogitClass [
	^(cogitClassName
		ifNil: [self interpreterClass cogitClass]
		ifNotNil: [Smalltalk classNamed: cogitClassName]) translationClass
]

{ #category : #'generate sources' }
VMMaker >> cogitClass: aClass [

	cogitClassName := aClass name asString
]

{ #category : #'generate sources' }
VMMaker >> cogitClassName [
	^cogitClassName
]

{ #category : #'objects from disk' }
VMMaker >> configurationInfo [
	"build a simple Array of the configuration information that would be 
	 usefully saved for later reloading:- 
		the list of internal & external plugins,
		the flags,
		the platform name,
		the two major directory names,
		bytePerWord
		two flags indicating whether each directory is relative to the current directory or not.
		the interpreter class name"
	| isRelative makeRelative |
	isRelative := [:pn| pn beginsWith: FileDirectory default pathName].
	makeRelative := [:pn|
					(isRelative value: pn)
						ifTrue: [pn allButFirst: FileDirectory default pathName size + 1]
						ifFalse: [pn]].
	^{ internalPlugins asArray.
		externalPlugins asArray.
		inline.
		forBrowser.
		platformName.
		makeRelative value: self sourceDirectory pathName.
		makeRelative value: self platformRootDirectory pathName.
		self wordSize.
		isRelative value: self sourceDirectory pathName.
		isRelative value: self platformRootDirectory pathName.
		self interpreterClassName
	  }
]

{ #category : #'private - copying files' }
VMMaker >> copyFileNamed: srcName to: dstName [ 
	| dstEntry srcEntry |
	dstEntry := FileDirectory directoryEntryFor: dstName.
	dstEntry ifNotNil:[
		srcEntry := FileDirectory directoryEntryFor: srcName.
		srcEntry ifNil:[^self couldNotOpenFile: srcName].
		dstEntry modificationTime >= srcEntry modificationTime ifTrue:[^self].
	].
	logger show:'==> ', dstName; cr.
	^self primitiveCopyFileNamed: srcName to: dstName 
]

{ #category : #'target directories' }
VMMaker >> coreVMDirectory [
	"return the target directory for the main VM sources, interp.c etc"
	| fd |
	fd := self sourceDirectory directoryNamed: self class coreVMDirName.
	fd assureExistence.
	^ fd
]

{ #category : #'private - errors' }
VMMaker >> couldNotFindDirectory: dirName [
	"This should raise a nice exception to a UI"
	^(VMMakerException new messageText: self class name, ' could not find directory ', dirName) signal
]

{ #category : #'private - errors' }
VMMaker >> couldNotFindPlatformDirectoryFor: platName [
	"This should raise a nice exception to a UI"
	self couldNotFindDirectory: 'for: ', platName, ' specific files; is the platform root path set correctly?'
]

{ #category : #'private - errors' }
VMMaker >> couldNotFindPlatformFilesFor: plugin [
	"This should raise a nice exception to a UI"
	(VMMakerException new messageText: self class name, ' could not find platform specific files for: ', plugin moduleName) signal
]

{ #category : #'private - errors' }
VMMaker >> couldNotFindPluginClass: pluginSymbol [
	"This should raise a nice exception to a UI"
	(VMMakerException new messageText: self class name, ' could not find the class for: ', pluginSymbol) signal
]

{ #category : #'private - errors' }
VMMaker >> couldNotOpenFile: fileName [
	"This should raise a nice exception to a UI"
	(VMMakerException new messageText: self class name, ' could not open file: ', fileName) signal
]

{ #category : #initialize }
VMMaker >> createCodeGenerator [
"set up a CCodeGenerator for this VMMaker"
	^CCodeGenerator new
		vmMaker: self;
		logger: logger;
		options: optionsDictionary;
		yourself
]

{ #category : #initialize }
VMMaker >> createCogitCodeGenerator [
	^CCodeGenerator new
		vmMaker: self;
		logger: logger;
		options: optionsDictionary;
		yourself
]

{ #category : #'source directories' }
VMMaker >> crossPlatformDirectory [
	"return the directory where we should find the cross-platform literal 
	sources - <sq.h> etc"
	| fd machDirNm |
	fd := self platformRootDirectory.
	(fd directoryExists: (machDirNm := 'Cross'))
		ifFalse: ["The supposed directory for the actual cross-platform code  
			does not exist."
			^ self couldNotFindPlatformDirectoryFor: 'cross-platform '].
	^ fd directoryNamed: machDirNm
]

{ #category : #'source directories' }
VMMaker >> crossPlatformPluginsDirectory [
	"return the directory where we should find the cross-platform plugin specific sources"

	(self crossPlatformDirectory directoryExists: self class pluginsDirName)
		ifFalse: ["The supposed directory for the plugins code does not 
					exist. We need to raise a suitable exception, but cant 
					think of one right now."
					^self couldNotFindPlatformDirectoryFor: 'any plugins needing cross-platform'].
	^self crossPlatformDirectory directoryNamed: self class pluginsDirName
]

{ #category : #'target directories' }
VMMaker >> deleteEntireGeneratedTree [
	"remove all the files - all of them I say"
	self sourceDirectory recursiveDelete
]

{ #category : #'target directories' }
VMMaker >> deleteUnwantedExternalPluginDirectories [
	"don't. in real life people back plugin directories with source code controls and simply deleting them really doesn't help."
]

{ #category : #'target directories' }
VMMaker >> deleteUnwantedInternalPluginDirectories [
	"don't. in real life people back plugin directories with source code controls and simply deleting them really doesn't help."
]

{ #category : #'generate sources' }
VMMaker >> doInlining [
	"default is true but see VMMaker>initialize for details"
	^inline
]

{ #category : #exports }
VMMaker >> export: exportList forExternalPlugin: aPlugin [
"it may be useful on certain platforms to do something with the export list of external plugins, just as the internal plugins' exports get added to the VM list. Default is to do nothing though."
]

{ #category : #'plugin lists' }
VMMaker >> externalFilesRequiredFor: plugin [
	^plugin requiresCrossPlatformFiles or:[plugin requiresPlatformFiles]
]

{ #category : #'plugin lists' }
VMMaker >> externalModuleNames [
	"return the list of all the external plugins' moduleNames"
	^Array streamContents:[:strm| self externalPluginsDo:[:pl| strm nextPut: pl moduleName ]]
]

{ #category : #'UI access' }
VMMaker >> externalModules [
	^externalPlugins
]

{ #category : #'target directories' }
VMMaker >> externalPluginListName [
	"Answer the filename for the list of external plugins"

	^'plugins.ext'
]

{ #category : #'target directories' }
VMMaker >> externalPluginsDirectory [
	"return the target directory for the external plugins sources"
	| fd |
	fd := self sourceDirectory directoryNamed: self class pluginsDirName.
	fd assureExistence.
	^fd
]

{ #category : #'target directories' }
VMMaker >> externalPluginsDirectoryFor: plugin [
	"return the directory for the external plugin sources"
	|fd|
	fd := self externalPluginsDirectory directoryNamed: plugin moduleName.
	fd assureExistence.
	^fd
]

{ #category : #'plugin lists' }
VMMaker >> externalPluginsDo: aBlock [ 
	"for each class that should be an external plugin, evaluate aBlock"
	self plugins: externalPlugins do: aBlock
]

{ #category : #initialize }
VMMaker >> for32BitVM [
"set my flag to make a 32bit pointer model VM"
	is64BitVM := false.
	self changed: #sourcePathText.
]

{ #category : #initialize }
VMMaker >> for64BitVM [
"set my flag to make a 64bit pointer model VM"
	is64BitVM := true.
	self changed: #sourceDirectory.
]

{ #category : #'generate sources' }
VMMaker >> generateCogitFile [
	"Translate the Smalltalk description of the virtual machine into C.  If 'self doInlining' is true, small method bodies are inlined to reduce procedure call overhead.  On the PPC, this results in a factor of three speedup with only 30% increase in code size.  Subclasses can use specialised versions of CCodeGenerator and interpreterClass."

	| cg cogitClass |
	self interpreterClass needsCogit ifFalse: [^nil].
	cg := [self buildCodeGeneratorForCogit]
			on: Notification
			do: [:ex|
				ex tag == #getVMMaker
					ifTrue: [ex resume: self]
					ifFalse: [(ex respondsTo: #rearmHandlerDuring:)
								ifTrue: [ex rearmHandlerDuring: [ex pass]]
								ifFalse: [ex pass]]].
	self needsToRegenerateCogitFile ifFalse: [^nil].
	cogitClass := self cogitClass.
	cg removeUnneededBuiltins.
	cg vmClass preGenerationHook: cg.

	cg inferTypesForImplicitlyTypedVariablesAndMethods.

	cg storeCodeOnFile: (self sourceFilePathFor: cogitClass sourceFileName) doInlining: cogitClass doInlining.
	cg vmClass additionalHeadersDo:
		[:headerName :headerContents| | filePath |
		 filePath := self coreVMDirectory fullNameFor: headerName.
		 (cg needToGenerateHeader: headerName file: filePath contents: headerContents) ifTrue:
			 [cg storeHeaderOnFile: filePath contents: headerContents]].
	cogitClass apiExportHeaderName ifNotNil:
		[cg storeAPIExportHeader: cogitClass apiExportHeaderName
			OnFile: (self sourceFilePathFor: cogitClass apiExportHeaderName)]
]

{ #category : #'generate sources' }
VMMaker >> generateEntire [
	"Generate the interp, internal plugins and exports as well as the external plugins.
	 If this comes from a generator, log it for convenience."
	(thisContext findContextSuchThat: [:ctxt| ctxt selector == #generateConfiguration]) ifNotNil:
		[:root|
		(thisContext findContextSuchThat: [:ctxt| ctxt sender == root]) ifNotNil:
			[:generator|
			logger cr; nextPutAll: (generator selector copyReplaceAll: 'generate' with: '').
			interpreterClassName ifNotNil: [logger space; nextPutAll: interpreterClassName].
			logger cr; flush]].
	self generateMainVM.
	self generateExternalPlugins
]

{ #category : #exports }
VMMaker >> generateExportsFile [
	"Store the exports on the given file"
	| cg contents filePath fileStream |
	cg := self createCodeGenerator.
	cg vmClass: self interpreterClass.
	contents := String streamContents:
		[:s|
		s
			nextPutAll:'/* This is an automatically generated table of all builtin modules in the VM';
			cr;
			next: 3 put: Character space;
			nextPutAll: (cg shortMonticelloDescriptionForClass: cg vmClass);
			cr;
			nextPutAll:' */';
			cr.
		s cr; nextPutAll:'extern sqExport vm_exports[];'.
		s cr; nextPutAll: 'extern sqExport os_exports[];'.
		self internalPluginsDo:[:cls|
			s cr; nextPutAll: 'extern sqExport '; nextPutAll: cls moduleName; nextPutAll:'_exports[];'.
		].
		s cr.

		s cr; nextPutAll:'sqExport *pluginExports[] = {'.
		s crtab; nextPutAll:'vm_exports,'.
		s crtab; nextPutAll: 'os_exports,'.
		self internalPluginsDo:[:cls|
			s crtab; nextPutAll: cls moduleName; nextPutAll:'_exports,'
		].
		s crtab; nextPutAll:'NULL'.
		s cr; nextPutAll:'};'; cr].
	filePath := self interpreterExportsFilePath.
	(cg needToGenerateHeader: (FileDirectory baseNameFor: filePath) file: filePath contents: contents) ifTrue:
		[[fileStream := VMMaker forceNewFileNamed: filePath] 
			on: FileDoesNotExistException 
			do:[^self couldNotOpenFile: filePath].
		 fileStream nextPutAll: contents; close]
]

{ #category : #'generate sources' }
VMMaker >> generateExternalPlugin: pluginName [ 
	"generate the named external plugin"
	| exports plugin |

	"Refuse to translate this plugin if it requires platform specific files and they are not present."
	[plugin := self validateExternalPlugin: pluginName]
		on: VMMakerException
		do: [:ex|
			logger show: 'external plugin ' , plugin name , ' failed to validate: ' , ex messageText; cr.
			^self].

	[exports := plugin
					translateInDirectory: (self externalPluginsDirectoryFor: plugin)
					doInlining: inline]
		on:  ProvideAnswerNotification
		do: [:ex|
			ex tag == #logger
				ifTrue: [ex resume: logger]
				ifFalse: [ex pass]].
	exports ifNotNil: "if exp is nil we skip this since the plugin was already up to date"
		[logger show: 'external plugin ' , plugin name , ' generated as ' , plugin moduleName; cr.
		 self export: exports forExternalPlugin: plugin.
		 self processFilesForExternalPlugin: plugin]
]

{ #category : #'generate sources' }
VMMaker >> generateExternalPlugins [
	"generate the external plugins"

	self deleteUnwantedExternalPluginDirectories.
	InterpreterPlugin initialize.
	self externalPluginsDo: [:plugin | 
		self generateExternalPlugin: plugin].
	self storeExternalPluginList.
	self logDateAndTime
]

{ #category : #'generate sources' }
VMMaker >> generateInternalPlugin: pluginName [ 
	"generate the named internal plugin. Make sure the exports list is actually 
	correct and write it out"
	self deleteUnwantedInternalPluginDirectories.
	self privateGenerateInternalPlugin: pluginName.
	self generateExportsFile.
	self logDateAndTime
]

{ #category : #'generate sources' }
VMMaker >> generateInternalPlugins [
	"generate the internal plugins and add their exports to the main list. te exports list is NOT written to file by this method"

	self deleteUnwantedInternalPluginDirectories.
	InterpreterPlugin initialize.
	self internalPluginsDo: [:plugin | 
		self privateGenerateInternalPlugin: plugin].
	self logDateAndTime.
	self storeInternalPluginList.
]

{ #category : #'generate sources' }
VMMaker >> generateInterpreterFile [
	"Translate the Smalltalk description of the virtual machine into C.  If 'self doInlining' is true, small method bodies are inlined to reduce procedure call overhead.  On the PPC, this results in a factor of three speedup with only 30% increase in code size.  Subclasses can use specialised versions of CCodeGenerator and interpreterClass."

	| cg vmHeaderContents |
	cg := [self buildCodeGeneratorForInterpreter]
			on: Notification
			do: [:ex|
				ex tag == #getVMMaker
					ifTrue: [ex resume: self]
					ifFalse: [(ex respondsTo: #rearmHandlerDuring:)
								ifTrue: [ex rearmHandlerDuring: [ex pass]]
								ifFalse: [ex pass]]].
	self needsToRegenerateInterpreterFile ifFalse: [^nil].
	cg removeUnneededBuiltins.
	self interpreterClass preGenerationHook: cg.

	cg inferTypesForImplicitlyTypedVariablesAndMethods.

	vmHeaderContents := cg vmHeaderContentsWithBytesPerWord: self wordSize.
	(cg needToGenerateHeader: self interpreterHeaderName file: self interpreterHeaderPath contents: vmHeaderContents) ifTrue:
		[cg storeHeaderOnFile: self interpreterHeaderPath contents: vmHeaderContents].
	cg storeCodeOnFile: (self sourceFilePathFor: self interpreterClass sourceFileName) doInlining: self doInlining.
	self interpreterClass additionalHeadersDo:
		[:headerName :headerContents| | filePath |
		 filePath := self coreVMDirectory fullNameFor: headerName.
		 (cg needToGenerateHeader: headerName file: filePath contents: headerContents) ifTrue:
			 [cg storeHeaderOnFile: filePath contents: headerContents]].
	self interpreterClass apiExportHeaderName ifNotNil:
		[cg storeAPIExportHeader: self interpreterClass apiExportHeaderName
			OnFile: (self sourceFilePathFor: self interpreterClass apiExportHeaderName)].
	self gnuifyInterpreterFile
]

{ #category : #'generate sources' }
VMMaker >> generateMainVM [
"generate the interp (and optionally the cogit), internal plugins and exports"

	self generateCogitFile;
		generateInterpreterFile;
		processFilesForCoreVM;
		generateInternalPlugins;
		generateExportsFile
]

{ #category : #'processing external files' }
VMMaker >> gnuifyInterpreterFile [
"post-process the interp.c file to make it gcc friendly"
	(Gnuifier on: self coreVMDirectory)
		interpreterFilename: self interpreterFilename;
		gnuify.
]

{ #category : #initialize }
VMMaker >> initialize [
	logger := Transcript.
	inline := true.
	forBrowser := false.
	internalPlugins := SortedCollection new.
	externalPlugins := SortedCollection new.
	platformName := self class machinesDirName.
	is64BitVM := Smalltalk wordSize == 8.
	interpreterClassName := Interpreter name.
	optionsDictionary := Dictionary new.
	optionsDictionary at: #BytesPerWord put: Smalltalk wordSize.
	VMStructType voidStructTypeCache
]

{ #category : #initialize }
VMMaker >> initializeAllExternal [
	"add all the plugins to the external list and make sure the internal list is empty"

	self initializeInternal: #() external: self availablePlugins 
]

{ #category : #initialize }
VMMaker >> initializeAllExternalBut: arrayOfInternalPluginNames [
	"add all the plugins to the external list except for those listed, which should be added to the internal list"

	self initializeInternal: arrayOfInternalPluginNames external: (self availablePlugins copyWithoutAll: arrayOfInternalPluginNames )
]

{ #category : #initialize }
VMMaker >> initializeAllInternal [
	"add all the plugins to the internal list and make sure the external list is empty"

	self initializeInternal: self availablePlugins  external: #()
]

{ #category : #initialize }
VMMaker >> initializeAllInternalBut: arrayOfExternalPluginNames [
	"add all the plugins to the internal list except for those listed, which should be added to the external list"

	self initializeInternal: (self availablePlugins copyWithoutAll: arrayOfExternalPluginNames) external:  arrayOfExternalPluginNames
]

{ #category : #initialize }
VMMaker >> initializeAllPlugins [
	allPlugins := self providedPlugins
]

{ #category : #initialize }
VMMaker >> initializeInternal: arrayOfInternalPluginNames external: arrayOfExternalPluginNames [
	"try to set up with the listed internal and external plugins."

	self initialize.

	self internal: arrayOfInternalPluginNames external: arrayOfExternalPluginNames
]

{ #category : #initialize }
VMMaker >> internal: arrayOfInternalPluginNames external: arrayOfExternalPluginNames [
	"try to set up with the listed internal and external plugins. Check that they are supportable plugins, reject those that are not - remember that this depends on the platform etc "

	"since we went to some trouble to drop plugins we cannot handle, don't add them now"
	internalPlugins := (self availablePlugins intersection: arrayOfInternalPluginNames) select: [:pl | self canSupportPlugin: pl].
	allPlugins := allPlugins copyWithoutAll: internalPlugins.
	externalPlugins := (allPlugins intersection: arrayOfExternalPluginNames) select: [:pl | self canSupportPlugin: pl ].
	allPlugins := allPlugins copyWithoutAll: externalPlugins.
	
]

{ #category : #'plugin lists' }
VMMaker >> internalModuleNames [
	"return the list of all the internal plugins' moduleNames"
	^Array streamContents:[:strm| self internalPluginsDo:[:pl| strm nextPut: pl moduleName ]]
]

{ #category : #'UI access' }
VMMaker >> internalModules [
	^internalPlugins
]

{ #category : #'target directories' }
VMMaker >> internalPluginListName [
	"Answer the filename for the list of internal plugins"

	^'plugins.int'
]

{ #category : #'target directories' }
VMMaker >> internalPluginsDirectory [
	"return the directory for the internal plugins sources"
	|fd|
	fd := self coreVMDirectory directoryNamed: 'intplugins'.
	fd assureExistence.
	^fd
]

{ #category : #'target directories' }
VMMaker >> internalPluginsDirectoryFor: plugin [
	"return the directory for the internal plugin sources"
	|fd|
	fd := self internalPluginsDirectory directoryNamed: plugin moduleName.
	fd assureExistence.
	^fd
]

{ #category : #'plugin lists' }
VMMaker >> internalPluginsDo: aBlock [ 
	"for each class that should be an internal plugin, evaluate aBlock"
	self plugins: internalPlugins do: aBlock
]

{ #category : #'generate sources' }
VMMaker >> interpreterClass [

	^(Smalltalk classNamed: interpreterClassName) ifNotNil:
		[:interpreterClass| interpreterClass translationClass]
]

{ #category : #'generate sources' }
VMMaker >> interpreterClass: aClass [

	interpreterClassName := aClass name asString
]

{ #category : #'generate sources' }
VMMaker >> interpreterClassName [

	^interpreterClassName
]

{ #category : #'generate sources' }
VMMaker >> interpreterClassName: aString [
	| tmp |
	tmp := Smalltalk at: aString asSymbol ifAbsent: [nil].
	tmp isBehavior
		ifTrue: [self interpreterClass: tmp]
		ifFalse: [self invalidClassName]
]

{ #category : #'generate sources' }
VMMaker >> interpreterExportsFilePath [
	"return the full path for the interpreter exports file"
	^self coreVMDirectory fullNameFor: 'sqNamedPrims.h'
]

{ #category : #'target directories' }
VMMaker >> interpreterFilename [
	"Answer the filename for the core interpreter.  Default is 'interp.c'."

	^self interpreterClass sourceFileName
]

{ #category : #'target directories' }
VMMaker >> interpreterHeaderName [
	"Answer the filename for the core interpreter header.  Default is 'interp.h'."

	^'interp.h'
]

{ #category : #'generate sources' }
VMMaker >> interpreterHeaderPath [
	"Answer the fully-qualified path for the generated interpreter header file."

	^self coreVMDirectory fullNameFor: self interpreterHeaderName
]

{ #category : #'private - errors' }
VMMaker >> invalidClassName [
	"This should raise a nice exception to a UI"
	(VMMakerException new messageText: self class name, ' invalid interpreter class name: ', interpreterClassName) signal
]

{ #category : #initialize }
VMMaker >> isFor32BitVM [
"is my flag to make a 32bit pointer model VM?"
	^is64BitVM not
]

{ #category : #initialize }
VMMaker >> isFor64BitVM [
"is my flag to make a 64bit pointer model VM?"
	^is64BitVM
]

{ #category : #'UI access' }
VMMaker >> listOfName: aSymbol [
	"work out which list is the one associated with this symbol"
	#availableModules = aSymbol ifTrue:[^allPlugins].
	#internalModules = aSymbol ifTrue:[^internalPlugins].
	#externalModules =aSymbol ifTrue:[^externalPlugins].
	^nil
]

{ #category : #'objects from disk' }
VMMaker >> loadConfiguration: aConfigArray [
	"load the configuration but ignore the platformName - the platform name must have been handled during the creation of this vmmaker in order for it to work correctly"

	inline := aConfigArray at: 3.
	forBrowser := aConfigArray at: 4.
	"This part must be ignored --> self setPlatName: (aConfigArray at: 5)."
	"Don't go through the setters sourceDirectoryName: & platformRootDirectoryName:.
	 They do validation which only works on certain platforms and create bogus directories, etc.
	 They're broken for non-interactive use."
	sourceDirName := aConfigArray at: 6.
	platformRootDirName := aConfigArray at: 7.
	self initializeAllPlugins.
	self internal: (aConfigArray at: 1) asSortedCollection
		external:(aConfigArray at: 2) asSortedCollection.
	aConfigArray size >= 9 ifTrue: "new enough to have 64bitness flag"
		[(aConfigArray at: 8) = 8 ifTrue: [self for64BitVM].
		 (aConfigArray at: 8) = 4 ifTrue: [self for32BitVM]].
	aConfigArray size >= 11 ifTrue: "new enough to include the interpreter name"
		[self interpreterClassName: (aConfigArray at: 11)].
	self changed: #sourceDirectory;
		 changed: #reinitialize
]

{ #category : #'UI access' }
VMMaker >> logDateAndTime [
	| now |
	"do it this way since Time now includes milliseconds in some versions."
	now := Time dateAndTimeNow.
	logger print: now first; space; print: now last; cr; flush
]

{ #category : #'UI access' }
VMMaker >> logger [
	^logger
]

{ #category : #'UI access' }
VMMaker >> logger: aStream [
	logger := aStream.
]

{ #category : #'UI access' }
VMMaker >> makeAllModulesAvailable [
	self internal: #() external: #().
	self reinitializePluginsLists
]

{ #category : #'UI access' }
VMMaker >> makeAllModulesExternal [
	self initializeAllPlugins.
	self internal: #() external: self availablePlugins.
	self changed: #reinitialize 
]

{ #category : #'UI access' }
VMMaker >> makeAllModulesInternal [
	self initializeAllPlugins.
	self internal: self availablePlugins external: #().
	self changed: #reinitialize 
]

{ #category : #'target directories' }
VMMaker >> makefileDirectory [
"where to put generated makefile related files"
	^self sourceDirectory
]

{ #category : #'UI access' }
VMMaker >> movePlugin: pluginName from: srcListName to: dstListName [
	"the VMMakerTool UI has been used to drag a plugin from one list to 
	another "
	"we need to do some tests - 
	are the lists actually ours? 
	is the plugin ours? 
	is the destination list one where we must check the plugin for 
	acceptability? return true if all is ok, false otherwise"
	| dstList srcList |
	dstList := self listOfName: dstListName.
	srcList := self listOfName: srcListName.
	dstList == allPlugins
		ifTrue: [dstList
				add: (srcList remove: pluginName)]
		ifFalse: ["the dest must be internal or external, so check the plugin for 
			acceptability "
			(self canSupportPlugin: pluginName)
				ifTrue: [dstList
						add: (srcList remove: pluginName)]]
]

{ #category : #'generate sources' }
VMMaker >> needsToRegenerateCogitFile [
	"Check the timestamp for the relevant classes and then the timestamp for the main source file (e.g. interp.c)
	 file if it already exists. Answer if the file needs regenerating."

	| cogitClass cogitClasses tStamp |
	cogitClasses := (cogitClass := self cogitClass) withAllSuperclasses copyUpThrough: Cogit.
	cogitClasses addAllLast: (cogitClass ancilliaryClasses: self options).
	tStamp := cogitClasses inject: 0 into: [:tS :cl| tS max: cl timeStamp].

	"don't translate if the file is newer than my timeStamp"
	(self coreVMDirectory entryAt: cogitClass sourceFileName ifAbsent: [nil]) ifNotNil:
		[:fstat|
		tStamp < fstat modificationTime ifTrue:
			[^self confirm: 'The ', cogitClass printString, ' classes have not been modified since\ the source file was last generated.\Do you still want to regenerate it?' withCRs]].
	^true

]

{ #category : #initialize }
VMMaker >> needsToRegenerateInterpreterFile [
	"Check the timestamp for the relevant classes and then the timestamp for the main
	 source file (e.g. interp.c) if it already exists.  Answer if the file needs regenerating."

	| classes tStamp |
	classes := self interpreterClass withAllSuperclasses copyUpTo: VMClass.
	self interpreterClass objectMemoryClass ifNotNil:
		[:objectMemoryClass|
		classes addAllLast: (objectMemoryClass  withAllSuperclasses copyUpTo: VMClass)].
	classes copy do:
		[:class| classes addAllLast: (class ancilliaryClasses: self options)].
	tStamp := classes inject: 0 into: [:tS :cl| tS max: cl timeStamp].

	"don't translate if the file is newer than my timeStamp"
	(self coreVMDirectory entryAt: self interpreterFilename ifAbsent: [nil]) ifNotNil:
		[:fstat|
		tStamp < fstat modificationTime ifTrue:
			[^self confirm: 'The interpreter classes have not been modified since\ the interpreter file was last generated.\Do you still want to regenerate their source file?' withCRs]].
	^true

]

{ #category : #accessing }
VMMaker >> options [
	^optionsDictionary
]

{ #category : #initialize }
VMMaker >> options: anArrayOfPairs [
	self assert: anArrayOfPairs size even.
	1 to: anArrayOfPairs size by: 2 do:
		[:i| | key |
		key := anArrayOfPairs at: i.
		self assert: key isSymbol.
		optionsDictionary at: key put: (anArrayOfPairs at: i + 1)]
]

{ #category : #'target directories' }
VMMaker >> platformDirectories [
	| root |
	^((root := self platformRootDirectory) directoryNames
		reject: [:dirName|
				dirName first = $. ".svn .git et al"
				or: [dirName ='CVS']])
		collect: [:dirName|
				root directoryNamed: dirName]
]

{ #category : #'source directories' }
VMMaker >> platformDirectory [
	"return the directory where we should find the platform specific sources"
	| fd platNm |
	fd := self platformRootDirectory.
	(fd directoryExists: (platNm := self platformName))
		ifFalse: ["The supposed directory for the actual platform code  
			does not exist."
			^ self couldNotFindPlatformDirectoryFor: platNm].
	^ fd directoryNamed: platNm
]

{ #category : #'UI access' }
VMMaker >> platformName [
	^platformName
]

{ #category : #'target directories' }
VMMaker >> platformPluginsDirectories [

	^self platformDirectories
		select: [:dir| dir directoryExists: self class pluginsDirName]
		thenCollect: [:dir| dir directoryNamed: self class pluginsDirName]
]

{ #category : #'source directories' }
VMMaker >> platformPluginsDirectory [
	"return the directory where we should find the platform plugin specific sources"

	(self platformDirectory directoryExists: self class pluginsDirName)
		ifFalse: ["The supposed directory for the plugins code does not 
					exist. We need to raise a suitable exception, but cant 
					think of one right now."
					^self couldNotFindPlatformDirectoryFor: 'any plugins needing ', self platformName].
	^self platformDirectory directoryNamed: self class pluginsDirName
]

{ #category : #'source directories' }
VMMaker >> platformRootDirectory [
	"return the directory where we should find all platform's sources"
	(FileDirectory default
			directoryExists: (platformRootDirName
					ifNil: [self class platformsDirName]))
		ifFalse: ["The supposed directory for the platforms code does not  
			exist."
			^ self couldNotFindDirectory: 'the platform code tree'].
	^ FileDirectory default
		directoryNamed: (platformRootDirName
				ifNil: [self class platformsDirName])
]

{ #category : #'source directories' }
VMMaker >> platformRootDirectoryName [
	"Answer the name of the directory where we should find all platform's sources"
	^platformRootDirName
]

{ #category : #'source directories' }
VMMaker >> platformRootDirectoryName: aString [
	"set the directory where we should find all platform's sources
	There really ought to be plausible sanity checks done here"
	platformRootDirName := aString.
	(FileDirectory default directoryExists: aString) ifFalse:[self couldNotFindDirectory: aString. ^false].
	self reinitializePluginsLists.
	^true
]

{ #category : #'plugin lists' }
VMMaker >> plugins: aCollection do: aBlock [ 
	"for each class in aCollection that should be a plugin, evaluate aBlock"
	aCollection do: [:sym | (Smalltalk hasClassNamed: sym)
			ifTrue: [aBlock value: (Smalltalk classNamed: sym)]
			ifFalse:["Another place to raise a sensible error to the UI"
				self couldNotFindPluginClass: sym]]
]

{ #category : #'private - copying files' }
VMMaker >> primitiveCopyFileNamed: srcName to: dstName [ 
	"This really ought to be a facility in file system. The major annoyance 
	here is that file types and permissions are not handled by current 
	Squeak code"
	| buffer src dst |
	<primitive: 'primitiveFileCopyNamedTo' module:'FileCopyPlugin'> "primitiveExternalCall" 
	"If the plugin doesn't do it, go the slow way and lose the filetype info"
	"This method may signal FileDoesNotExistException if either the source or 
	dest files cannnot be opened; possibly permissions or bad name problems"
	[[src := FileStream readOnlyFileNamed: srcName]
		on: FileDoesNotExistException
		do: [^ self couldNotOpenFile: srcName].
	src binary.
	[dst := FileStream forceNewFileNamed: dstName]
		on: FileDoesNotExistException
		do: [^ self couldNotOpenFile: dstName].
	dst binary.
	buffer := ByteArray new: 50000.
	[src atEnd]
		whileFalse: [dst
				nextPutAll: (src nextInto: buffer)]]
		ensure: [src
				ifNotNil: [src close].
			dst
				ifNotNil: [dst close]]
]

{ #category : #'generate sources' }
VMMaker >> privateGenerateInternalPlugin: pluginName [ 
	"generate the named internal plugin"
	| plugin |
	"Refuse translate this plugin if it requires platform specific files and  
	they are not present."
	plugin := self validateInternalPlugin: pluginName.

	plugin ifNil:
		[^self couldNotFindPluginClass: pluginName].
	[plugin
			translateInDirectory: (self internalPluginsDirectoryFor: plugin)
			doInlining: inline]
		on:  ProvideAnswerNotification
		do: [:ex|
			ex tag == #logger
				ifTrue: [ex resume: logger]
				ifFalse: [ex pass]].
	logger show: 'internal plugin ' , plugin name , ' generated as ' , plugin moduleName; cr.
	self processFilesForInternalPlugin: plugin
]

{ #category : #'processing external files' }
VMMaker >> processFilesForCoreVM [

]

{ #category : #'processing external files' }
VMMaker >> processFilesForExternalPlugin: plugin [ 

]

{ #category : #'processing external files' }
VMMaker >> processFilesForInternalPlugin: plugin [ 

]

{ #category : #initialize }
VMMaker >> providedPlugins [
	"generate the list by asking the InterpreterPlugins"
	^ ((InterpreterPlugin allSubclasses
		select: [:cl | cl shouldBeTranslatedFor: platformName])
		collect: [:cl | cl name]) asSortedCollection
]

{ #category : #'objects from disk' }
VMMaker >> readConfigurationFrom: aFileName [
	"read info about the current configuration from a file. Return the array that would have been made by #configurationInfo"
	|  fileStream |

	fileStream := FileStream oldFileNamed: aFileName.
	^fileStream fileInObjectAndCode
]

{ #category : #'UI access' }
VMMaker >> recomputeProvidedPlugins [
	allPlugins := self providedPlugins reject: [:p| (internalPlugins includes: p) or: [externalPlugins includes: p]]
]

{ #category : #'UI access' }
VMMaker >> reinitializePluginsLists [
	"something has changed that affects the validity of the plugin lists. Recalculate them as best we can. It is probably possible to check on the current lists and keep the configuration as close as possible the same; but for the moment just try to use the same lists "
	self initializeAllPlugins.
	self internal: internalPlugins external: externalPlugins.
	self changed: #reinitialize 
]

{ #category : #'objects from disk' }
VMMaker >> saveConfigurationTo: aFile [
	"Write info about the current configuration to a file.
	 Use a hack CrForSpaceWriteStream so that things
	 appear on separate lines to be friendly to configuration
	 management systems diffing facilities."
	| stream |
	stream := CrForSpaceWriteStream on: String new.
	self configurationInfo storeOn: stream.
	(MultiByteFileStream newFileNamed: aFile)
		lineEndConvention: #lf;
		nextPutAll: stream contents;
		close
]

{ #category : #initialize }
VMMaker >> setPlatName: aString [
	"private - just set the platform name string, nothing else. Go away...."
	platformName := aString
]

{ #category : #'target directories' }
VMMaker >> sourceDirectory [
	| fd |
	fd := FileDirectory default directoryNamed: (sourceDirName
		ifNil: [self class sourceDirName, self vmBitnessString]).
	fd assureExistence.
	^ fd
]

{ #category : #'target directories' }
VMMaker >> sourceDirectoryName [
	^sourceDirName
]

{ #category : #'target directories' }
VMMaker >> sourceDirectoryName: aString [
	"Sanity check really ought to be added, This is the root directory for where the sources will be WRITTEN"
	sourceDirName := aString.
	(aString first == $.
		ifTrue: [FileDirectory default directoryNamed: aString]
		ifFalse: [FileDirectory on: aString]) assureExistence.
	self changed: #sourceDirectory.
	^true
]

{ #category : #'target directories' }
VMMaker >> sourceFileNameFor: aVMClass [
	"Answer the source file name for a VM class."

	^aVMClass sourceFileName
]

{ #category : #'generate sources' }
VMMaker >> sourceFilePathFor: sourceFileName [
	"Answer the fully-qualified path for the generated source file."
	^self coreVMDirectory fullNameFor: sourceFileName
]

{ #category : #exports }
VMMaker >> storeExternalPluginList [
	| contents filePath fileStream |
	contents := String streamContents:
		[:s|
		s nextPutAll:'# Automatically generated makefile include for external plugins'.
		s cr; nextPutAll:'EXTERNAL_PLUGINS ='.
		self externalPluginsDo:
			[:cls|
			s space; nextPut: $\; cr; nextPutAll: cls moduleName].
		s cr].
	filePath := self makefileDirectory fullNameFor: self externalPluginListName.
	(CCodeGenerator basicNew needToGenerateHeader: filePath file: filePath contents: contents) ifTrue:
		[[fileStream := VMMaker forceNewFileNamed: filePath] 
			on: FileDoesNotExistException 
			do:[^self couldNotOpenFile: filePath].
		 fileStream nextPutAll: contents; close]
]

{ #category : #exports }
VMMaker >> storeInternalPluginList [
	| contents filePath fileStream |
	contents := String streamContents:
		[:s|
		s nextPutAll:'# Automatically generated makefile include for internal plugins'.
		s cr; nextPutAll:'INTERNAL_PLUGINS ='.
		self internalPluginsDo:
			[:cls|
			s space; nextPut: $\; cr; nextPutAll: cls moduleName].
		s cr].
	filePath := self makefileDirectory fullNameFor: self internalPluginListName.
	(CCodeGenerator basicNew needToGenerateHeader: filePath file: filePath contents: contents) ifTrue:
		[[fileStream := VMMaker forceNewFileNamed: filePath] 
			on: FileDoesNotExistException 
			do:[^self couldNotOpenFile: filePath].
		 fileStream nextPutAll: contents; close]
]

{ #category : #'generate sources' }
VMMaker >> validateExternalPlugin:	plName [

	^self validatePlugin: plName in: externalPlugins
]

{ #category : #'generate sources' }
VMMaker >> validateInternalPlugin:	plName [

	^self validatePlugin: plName in: internalPlugins
]

{ #category : #'generate sources' }
VMMaker >> validatePlugin:	plName in: listOfPlugins [
"check that the plName is either an actual plugin class or a plugin class name. Return the plugin class or raise an error if nil"
	| plugin |
	plName isString
		ifTrue: [(listOfPlugins includes: plName)
				ifTrue: [plugin := Smalltalk classNamed: plName]]
		ifFalse: [((plName isBehavior
						and: [plName inheritsFrom: InterpreterPlugin])
					and: [listOfPlugins includes: plName name])
				ifTrue: [plugin := plName]].
	plugin ifNil: [^ self couldNotFindPluginClass: plName].

	"Is there a cross-platform or platform files directory of the same name as this plugin?"
	plugin requiresPlatformFiles
		ifTrue: [(self platformPluginsDirectory directoryExists: plugin moduleName)
				ifFalse: [logger show: 'No platform specific files found for ' , plugin moduleName printString; cr.
					^ self couldNotFindPlatformFilesFor: plugin]].
	plugin requiresCrossPlatformFiles
		ifTrue: [(self crossPlatformPluginsDirectory directoryExists: plugin moduleName)
				ifFalse: [logger show: 'No cross platform files found for ' , plugin moduleName printString; cr.
					^ self couldNotFindPlatformFilesFor: plugin]].

	^plugin
]

{ #category : #'target directories' }
VMMaker >> vmBitnessString [
	"Return a string of 32 or 64 depending on the is64BitVM valuse"
	^is64BitVM ifTrue:['64'] ifFalse:['32']
]

{ #category : #initialize }
VMMaker >> wordSize [
	"Return the bytes in a word for the chosen 32bit/64bit pointer setup chosen"
	^is64BitVM ifTrue:[8] ifFalse:[4]
]
