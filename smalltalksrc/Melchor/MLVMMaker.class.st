Class {
	#name : #MLVMMaker,
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
		'is64BitVM',
		'optionsDictionary',
		'abortBlock',
		'doCleanupOldFiles',
		'silently',
		'vmmakerConfiguration'
	],
	#category : #Melchor
}

{ #category : #initialisation }
MLVMMaker class >> activeVMMakerClassFor: platformName [
	"Return the concrete VMMaker subclass for the platform on which we are currently running."

	VMMaker allSubclasses do: [:class |
		(class isActiveVMMakerClassFor: platformName) ifTrue: [^ class]].

	"no responding subclass; use VMMaker"
	^ VMMaker

]

{ #category : #'confs-support' }
MLVMMaker class >> chooseCoInterpreterClassIfAbsent: ifAbsentBlock [
	^Smalltalk classNamed:
		 ([:choices|
		   choices
			at: (UIManager default chooseFrom: choices)
			ifAbsent: ifAbsentBlock]
				value: #(CoInterpreter CoInterpreterMT))
]

{ #category : #'confs-support' }
MLVMMaker class >> configurationNameFromSelector: aSelector [
	^(aSelector piecesCutWhere: [:a :b| a isLowercase and: [b isUppercase]]) allButFirst fold: [:a :b| a, ' ', b]
]

{ #category : #initialisation }
MLVMMaker class >> default [
	"return a VMMaker initialised to build a default no-internal-plugins, no-external-plugins vm codebase"
	^self forPlatform: 'Cross'
]

{ #category : #utilities }
MLVMMaker class >> executeDisplayingProgress: anActionsMap [
	| barValue |
	barValue := 0.
	''
		displayProgressFrom: 0
		to: anActionsMap size
		during: [ :bar | 
			anActionsMap
				keysAndValuesDo: [ :label :action | 
					bar value: barValue.
					barValue := barValue + 1.
					ProgressNotification signal: '' extra: label.
					action value ] ]
]

{ #category : #'instance creation' }
MLVMMaker class >> forPlatform: platformName [
	"return a VMMaker initialised to build a default no-internal-plugins, no-external-plugins vm codebase"
	^(self activeVMMakerClassFor: platformName) new setPlatName: platformName
]

{ #category : #'file utilities' }
MLVMMaker class >> forceNewFileNamed: aFilename [
	"Always output files in unix lf format.
		A single format is friendlier to e.g. external version control systems.
		The Microsoft and old MacOS classic C compilers all accept lf format files."

	^(MultiByteFileStream forceNewFileNamed: aFilename)
		lineEndConvention: #lf;
		yourself
]

{ #category : #'file utilities' }
MLVMMaker class >> fullNameForPath: aPathString [

	^ aPathString asFileReference asAbsolute fullName
]

{ #category : #utilities }
MLVMMaker class >> generate: interpreterClass and: cogitClass with: optionsPairsArray to: srcDirName platformDir: platDirName including: inclusions configuration: vmmakerConfiguration [
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
		including: inclusions
		configuration: vmmakerConfiguration) generateEntire
]

{ #category : #'version testing' }
MLVMMaker class >> headerNotice [
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
MLVMMaker class >> isActiveVMMakerClassFor: platformName [ 
	"Does this class claim to be that properly active subclass of VMMaker for 
	this platform? Subclasses are welcome to override this default"
	^ platformName , '*' match: self name
]

{ #category : #'instance creation' }
MLVMMaker class >> makerFor: interpreterClass and: cogitClassOrNil with: optionsPairsArray to: srcDirName platformDir: platDirName configuration: vmmakerConfiguration [
	"Initialize a VMMaker to generate the VM to the given target directory."
	| options|
	
	options := Dictionary newFromPairs: optionsPairsArray.
	
	(cogitClassOrNil isNil or: [ options includes: #Cogit ])
		ifFalse: [ options at: #Cogit put: cogitClassOrNil name ].
		
	(self environment at: (options at: #ObjectMemory)) initializeWithOptions: options.
		
	vmmakerConfiguration initializeForPlugins: options.
	
	^(self forPlatform: 'Cross')
		vmmakerConfiguration: vmmakerConfiguration;
		sourceDirectoryName: (self fullNameForPath: srcDirName);
		platformRootDirectoryName: (self fullNameForPath: platDirName);
		options: options;
		interpreterClass: interpreterClass;
		yourself
]

{ #category : #'instance creation' }
MLVMMaker class >> makerFor: interpreterClass and: cogitClassOrNil with: optionsPairsArray to: srcDirName platformDir: platDirName including: inclusions configuration: vmclassConfiguration [
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
	maker := self makerFor: interpreterClass and: cogitClassOrNil with: optionsPairsArray to: srcDirName platformDir: platDirName configuration: vmclassConfiguration.
	maker externalModules addAll: inclusions.
	^maker
	
]

{ #category : #'file utilities' }
MLVMMaker class >> rootDirectory [
	^ self sourceTree asFileReference
]

{ #category : #'version testing' }
MLVMMaker class >> versionString [
	"VMMaker versionString"

	^'4.7.0 (Cog)'
]

{ #category : #accessing }
MLVMMaker >> abortBlock [
	^abortBlock
]

{ #category : #'plugin lists' }
MLVMMaker >> allModuleNames [
	"return the list of all the all plugins' moduleNames"
	^Array streamContents:[:strm| self allPluginsDo:[:pl| strm nextPut: pl moduleName ]]
]

{ #category : #'plugin lists' }
MLVMMaker >> allPluginsDo: aBlock [ 
	"for each class that should be an external plugin, evaluate aBlock"
	self externalPluginsDo: aBlock.
	self internalPluginsDo: aBlock.
]

{ #category : #'UI access' }
MLVMMaker >> availablePlugins [
	allPlugins ifNil:[self initializeAllPlugins].
	^allPlugins
]

{ #category : #'generate sources' }
MLVMMaker >> buildCodeGeneratorForCogit [

	"Answer the code generator for translating the cogit."

	| cg cogitClasses cogitClass |
	cogitClass := self interpreterClass cogitClass.
	cg := self createCogitCodeGenerator.
	cg vmClass: cogitClass.
	true ifTrue: [ 
		{ 
			cogitClass.
			self interpreterClass.
			self interpreterClass objectMemoryClass } do: [ :cgc | 
			(cgc respondsTo: #initializeWithOptions:)
				ifTrue: [ cgc initializeWithOptions: optionsDictionary ]
				ifFalse: [ cgc initialize ] ] ].
	cogitClasses := OrderedCollection withAll:
		                (cogitClass withAllSuperclasses copyUpThrough:
			                 SlangClass) reverse.
	cogitClasses addAllLast:
		(cogitClass ancilliaryClasses reject: [ :class | 
			 class isStructClass ]).
	cogitClasses do: [ :cgc | cg addClass: cgc ]. "Now make sure to add struct classes that the most specific subclasses specify.
	 This makes sure that struct classes are ordered as the most specific cogitClass desires.
	 This must happen for references between the struct classes to be resolved in a specific order."
	cogitClasses := OrderedCollection
		                with: cogitClass
		                with: cogitClass objectRepresentationClass.
	cogitClasses addAll:
		(cogitClass ancilliaryClasses reject: [ :class | 
			 class isStructClass or: [ 
				 cogitClass objectRepresentationClass includesBehavior: class ] ]).
	cg addStructClasses:
		(cg structClassesForTranslationClasses: cogitClasses).
	true ifTrue: [ 
		cg includeAPIFrom: (self
				 buildCodeGeneratorForInterpreter: self interpreterClass
				 includeAPIMethods: false
				 initializeClasses: false) ].
	^ cg
]

{ #category : #'generate sources' }
MLVMMaker >> buildCodeGeneratorForInterpreter [
	"Answer the code generator for translating the interpreter."

	^ self
		buildCodeGeneratorForInterpreter: self interpreterClass
		includeAPIMethods: true
		initializeClasses: true
]

{ #category : #'generate sources' }
MLVMMaker >> buildCodeGeneratorForInterpreter: interpreterClass includeAPIMethods: getAPIMethods initializeClasses: initializeClasses [

	"Answer the code generator for translating the interpreter."

	| cg interpreterClasses |
	initializeClasses ifTrue: [ 
		interpreterClass initializeWithOptions: optionsDictionary.
		interpreterClass hasCogit ifTrue: [ 
			interpreterClass cogitClass initializeWithOptions:
				optionsDictionary ] ].

	(cg := self createCodeGenerator) vmClass: interpreterClass.

	"Construct interpreterClasses as all classes from interpreterClass &
	 objectMemoryClass up to VMClass in superclass to subclass order."
	interpreterClasses := OrderedCollection new.
	{ 
		interpreterClass.
		interpreterClass objectMemoryClass } do: [ :vmClass | 
		| theClass |
		theClass := vmClass.
		[ theClass ~~ self vmmakerConfiguration baseClass ] whileTrue: [ 
			interpreterClasses addFirst: theClass.
			theClass := theClass superclass ] ].
	interpreterClasses
		addFirst: self vmmakerConfiguration baseClass;
		addAllLast:
			(cg nonStructClassesForTranslationClasses: interpreterClasses).

	initializeClasses ifTrue: [ 
		interpreterClasses do: [ :ic | 
			(ic respondsTo: #initializeWithOptions:)
				ifTrue: [ 
				ic initializeWithOptions: interpreterClass initializationOptions ]
				ifFalse: [ ic initialize ] ].
		(cg structClassesForTranslationClasses: interpreterClasses) do: [ 
			:structClass | structClass initialize ] ].

	cg addStructClasses:
		(cg structClassesForTranslationClasses: interpreterClasses).

	interpreterClasses do: [ :ic | cg addClass: ic ].

	getAPIMethods ifTrue: [ 
		interpreterClass cogitClass ifNotNil: [ :cogitClass | 
			cg includeAPIFrom: (self
					 buildCodeGeneratorForCogit: cogitClass
					 includeAPIMethods: false
					 initializeClasses: false) ] ].

	^ cg
]

{ #category : #'plugin lists' }
MLVMMaker >> canSupportPlugin: pluginClassName [ 
	"see if this plugin needs any external files and if so, check to see if 
	they seem to exist."
	[self validatePlugin: pluginClassName in: allPlugins , internalPlugins , externalPlugins]
		on: VMMakerException
		do: [^ false].
	^ true
]

{ #category : #'generate sources' }
MLVMMaker >> configurationGeneratorNameOrNil [
	"Search the sender chain for the first method in VMMaker class protocol configurations, and answer it if found,
	 otherwise answer nil.  This allows us to name the configuration being generated."
	^thisContext findContextSuchThat:
		[:ctxt|
		 ctxt receiver == VMMaker
		 and: [ctxt method methodReference category = #configurations]]
]

{ #category : #'generate sources' }
MLVMMaker >> configurationNameIfAny [
	^self configurationGeneratorNameOrNil
		ifNotNil: [:ctxt| (self class configurationNameFromSelector: ctxt selector), ' ']
		ifNil: [' ']
]

{ #category : #'target directories' }
MLVMMaker >> coreVMDirectory [
	"return the target directory for the main VM sources, interp.c etc"
	^ (self sourceDirectory / self vmmakerConfiguration coreVMDirName)
		ensureCreateDirectory;
		yourself.

]

{ #category : #'target directories' }
MLVMMaker >> coreVMHeadersDirectory [
	"return the target directory for the main VM sources, interp.c etc"
	| fd |
	fd := self sourceDirectory / self vmmakerConfiguration coreVMHeadersDirName.
	fd ensureCreateDirectory.
	^ fd
]

{ #category : #'private - errors' }
MLVMMaker >> couldNotFindDirectory: dirName [
	"This should raise a nice exception to a UI"
	^(VMMakerException new messageText: self class name, ' could not find directory ', dirName) signal
]

{ #category : #'private - errors' }
MLVMMaker >> couldNotFindPlatformDirectoryFor: platName [
	"This should raise a nice exception to a UI"
	self couldNotFindDirectory: 'for: ', platName, ' specific files; is the platform root path set correctly?'
]

{ #category : #'private - errors' }
MLVMMaker >> couldNotFindPlatformFilesFor: plugin [
	"This should raise a nice exception to a UI"
	(VMMakerException new messageText: self class name, ' could not find platform specific files for: ', plugin moduleName) signal
]

{ #category : #'private - errors' }
MLVMMaker >> couldNotFindPluginClass: pluginSymbol [
	"This should raise a nice exception to a UI"
	(VMMakerException new messageText: self class name, ' could not find the class for: ', pluginSymbol) signal
]

{ #category : #'private - errors' }
MLVMMaker >> couldNotOpenFile: fileName [
	"This should raise a nice exception to a UI"
	(VMMakerException new messageText: self class name, ' could not open file: ', fileName) signal
]

{ #category : #initialize }
MLVMMaker >> createCodeGenerator [
"set up a CCodeGenerator for this VMMaker"
	^CCodeGenerator new
		vmMaker: self;
		logger: logger;
		options: optionsDictionary;
		yourself
]

{ #category : #initialize }
MLVMMaker >> createCogitCodeGenerator [
	^CCodeGenerator new
		vmMaker: self;
		logger: logger;
		options: optionsDictionary;
		yourself
]

{ #category : #'source directories' }
MLVMMaker >> crossPlatformDirectory [
	"return the directory where we should find the cross-platform literal 
	sources - <sq.h> etc"
	| dir |
	dir := self platformRootDirectory directoryNamed: 'Cross'.
	dir exists ifFalse: "The supposed directory for the actual cross-platform code does not exist."
		[^self couldNotFindPlatformDirectoryFor: 'cross-platform '].
	^dir
]

{ #category : #'source directories' }
MLVMMaker >> crossPlatformPluginsDirectory [
	"return the directory where we should find the cross-platform plugin specific sources"
	| dir |
	dir := self crossPlatformDirectory directoryNamed: self class pluginsDirName.
	dir exists ifFalse: "The supposed directory for the plugins code does not exist.
					  We need to raise a suitable exception, but can't think of one right now."
		[^self couldNotFindPlatformDirectoryFor: 'any plugins needing cross-platform'].
	^dir
]

{ #category : #'target directories' }
MLVMMaker >> deleteEntireGeneratedTree [
	"remove all the files - all of them I say"
	self sourceDirectory recursiveDelete
]

{ #category : #'target directories' }
MLVMMaker >> deleteUnwantedExternalPluginDirectories [
	"don't. in real life people back plugin directories with source code controls and simply deleting them really doesn't help."
]

{ #category : #'target directories' }
MLVMMaker >> deleteUnwantedInternalPluginDirectories [
	"don't. in real life people back plugin directories with source code controls and simply deleting them really doesn't help."
]

{ #category : #initialize }
MLVMMaker >> doCleanupOldFiles [

	doCleanupOldFiles := true
]

{ #category : #'generate sources' }
MLVMMaker >> doInlining [
	"default is true but see VMMaker>initialize for details"
	^inline
]

{ #category : #exports }
MLVMMaker >> export: exportList forExternalPlugin: aPlugin [
"it may be useful on certain platforms to do something with the export list of external plugins, just as the internal plugins' exports get added to the VM list. Default is to do nothing though."
]

{ #category : #'UI access' }
MLVMMaker >> externalModules [
	^externalPlugins
]

{ #category : #'target directories' }
MLVMMaker >> externalPluginListName [
	"Answer the filename for the list of external plugins"

	^'plugins.ext'
]

{ #category : #'target directories' }
MLVMMaker >> externalPluginsDirectory [
	"return the target directory for the external plugins sources"
	^ (self sourceDirectory / self vmmakerConfiguration pluginsDirName)
		ensureCreateDirectory;
		yourself. 
]

{ #category : #'target directories' }
MLVMMaker >> externalPluginsDirectoryFor: plugin [
	"return the directory for the external plugin sources"
	
	^ (self externalPluginsDirectory / plugin moduleName)
		ensureCreateDirectory;
		yourself

]

{ #category : #'plugin lists' }
MLVMMaker >> externalPluginsDo: aBlock [ 
	"for each class that should be an external plugin, evaluate aBlock"
	self plugins: externalPlugins do: aBlock
]

{ #category : #initialize }
MLVMMaker >> for32BitVM [
"set my flag to make a 32bit pointer model VM"
	is64BitVM := false.
	self changed: #sourcePathText.
]

{ #category : #initialize }
MLVMMaker >> for64BitVM [
"set my flag to make a 64bit pointer model VM"
	is64BitVM := true.
	self changed: #sourceDirectory.
]

{ #category : #headers }
MLVMMaker >> generateAdditionalHeadersFor: aClass withCodeGenerator: cg [

	aClass additionalHeadersDo: [:headerName :headerContents| | filePath |
		 filePath := (self coreVMHeadersDirectory / headerName) fullName.
		 (cg needToGenerateHeader: headerName file: filePath contents: headerContents) ifTrue:
			 [cg storeHeaderOnFile: filePath contents: headerContents]].
]

{ #category : #'generate sources' }
MLVMMaker >> generateCogitFileFor: cogitClass [
	"Translate the Smalltalk description of the Cogit into C, if required.  Ensure that
	 inferTypesForImplicitlyTypedVariablesAndMethods was done, and answer the code generator."

	| cg |
	cg := self buildCodeGeneratorForCogit.

	cg inferTypesForImplicitlyTypedVariablesAndMethods.
	self needsToRegenerateCogitFile ifFalse: [^cg].

	cg vmClass preGenerationHook: cg.
	cg storeCodeOnFile: (self sourceFilePathFor: cogitClass processorSpecificSourceFileName) doInlining: cogitClass doInlining.
	^cg
]

{ #category : #'generate sources' }
MLVMMaker >> generateCogitFiles [
	"Translate the Smalltalk description of the virtual machine's JITs into C."
	| cogitClass cg |
	(cogitClass := self interpreterClass cogitClass) ifNil: [^nil].
	self generateCogitIncludeFileFor: cogitClass.
	cogitClass translateableInstructionSubclassesAndInstalledOptionsDo:
		[:compilerClass|
		cg := self generateCogitFileFor: cogitClass].

	self generateAdditionalHeadersFor: cg vmClass withCodeGenerator: cg.

	cogitClass apiExportHeaderName ifNotNil:
		[cg storeAPIExportHeader: cogitClass apiExportHeaderName
			OnFile: (self includeFilePathFor: cogitClass apiExportHeaderName)]
]

{ #category : #'generate sources' }
MLVMMaker >> generateCogitIncludeFileFor: cogitClass [
	"Generate the skeletal cogit.c that includes the processor-specific cogit files."

	| code fileName file fileCode |
	code := cogitClass generateCodeStringForCogitDotC.
	fileName := (self coreVMDirectory / cogitClass sourceFileName) fullName.
	((self coreVMDirectory asFileReference / cogitClass sourceFileName) exists
	and: [fileCode := fileName asFileReference contents.
		(fileCode allButFirst: (fileCode indexOf: $#)) = (code allButFirst: (code indexOf: $#))]) ifFalse:
		[file := self class forceNewFileNamed: fileName.
		 [file nextPutAll: code] ensure:
			[file close]]
]

{ #category : #'generate sources' }
MLVMMaker >> generateEntire [
	"Generate the interp, internal plugins and exports as well as the external plugins.
	 If this comes from a generator method, log it for convenience."
	abortBlock := [^self].
	self logGeneration.
	self generateMainVM.
	self generateExternalPlugins
]

{ #category : #exports }
MLVMMaker >> generateExportsFile [
	"Store the exports on the given file"
	| cg contents filePath fileStream |
	filePath := self interpreterExportsFilePath.
	"don't bother endlessly regenerating the example file."
	(internalPlugins isEmpty
	 and: [(filePath includesSubstring: 'example')
	 and: [filePath asFileReference exists]]) ifTrue:
		[^self].
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
	(cg needToGenerateHeader: (filePath asFileReference basename) file: filePath contents: contents) ifTrue:
		[[fileStream := VMMaker forceNewFileNamed: filePath] 
			on: FileDoesNotExistException 
			do:[^self couldNotOpenFile: filePath].
		 fileStream nextPutAll: contents; close]
]

{ #category : #'generate sources' }
MLVMMaker >> generateExternalPlugin: pluginName [ 
	"generate the named external plugin"
	| exports plugin |

	"Refuse to translate this plugin if it requires platform specific files and they are not present."
	[plugin := self validateExternalPlugin: pluginName]
		on: VMMakerException
		do: [:ex|
			logger show: 'external plugin ' , plugin name , ' failed to validate: ' , ex messageText; cr.
			^self].

	vmmakerConfiguration initializeForPlugins: optionsDictionary.
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
MLVMMaker >> generateExternalPlugins [
	"generate the external plugins"

	self logDateAndTime.
	self deleteUnwantedExternalPluginDirectories.
	self vmmakerConfiguration interpreterPluginClass initialize.
	self externalPluginsDo: [:plugin | 
		self generateExternalPlugin: plugin].
	self storeExternalPluginList.
	self logDateAndTime
]

{ #category : #'generate sources' }
MLVMMaker >> generateInternalPlugin: pluginName [ 
	"generate the named internal plugin. Make sure the exports list is actually 
	correct and write it out"
	self deleteUnwantedInternalPluginDirectories.
	self privateGenerateInternalPlugin: pluginName.
	self generateExportsFile.
	self logDateAndTime
]

{ #category : #'generate sources' }
MLVMMaker >> generateInternalPlugins [
	"generate the internal plugins and add their exports to the main list. te exports list is NOT written to file by this method"

	self deleteUnwantedInternalPluginDirectories.
	self vmmakerConfiguration interpreterPluginClass initialize.
	self internalPluginsDo: [:plugin | 
		self privateGenerateInternalPlugin: plugin].
	self logDateAndTime.
	self storeInternalPluginList.
]

{ #category : #'generate sources' }
MLVMMaker >> generateInterpreterFile [
	"Translate the Smalltalk description of the virtual machine into C.  If 'self doInlining' is true, small method bodies are inlined to reduce procedure call overhead.  On the PPC, this results in a factor of three speedup with only 30% increase in code size.  Subclasses can use specialised versions of CCodeGenerator and interpreterClass."

	| cg vmHeaderContents |
	cg := self buildCodeGeneratorForInterpreter.
	self reinitializeWordSizeFrom: cg.

	self generateAdditionalHeadersFor: self interpreterClass withCodeGenerator: cg.

	self needsToRegenerateInterpreterFile ifFalse: [^nil].

	cg inferTypesForImplicitlyTypedVariablesAndMethods.

	self interpreterClass preGenerationHook: cg.
	vmHeaderContents := cg vmHeaderContentsWithBytesPerWord: self wordSize.
	(cg needToGenerateHeader: self interpreterHeaderName file: self interpreterHeaderPath contents: vmHeaderContents) ifTrue:
		[cg storeHeaderOnFile: self interpreterHeaderPath contents: vmHeaderContents].
	cg storeCodeOnFile: (self sourceFilePathFor: self interpreterClass sourceFileName) doInlining: self doInlining.
	self interpreterClass apiExportHeaderName ifNotNil:
		[cg storeAPIExportHeader: self interpreterClass apiExportHeaderName
			OnFile: (self includeFilePathFor: self interpreterClass apiExportHeaderName)].
	self gnuifyInterpreterFile
]

{ #category : #'generate sources' }
MLVMMaker >> generateMainVM [
	"Generate the interp (and optionally the cogit), internal plugins and exports.
	 N.B. generateInterpreterFile *must* precede generateCogitFile so that
	 the objectMemory and interpreter classes are initialized before the Cogit
	 code is generated."

	self logDateAndTime;
		generateInterpreterFile;
		generateCogitFiles;
		generateInternalPlugins;
		generateExportsFile;
		logDateAndTime
]

{ #category : #'generate sources' }
MLVMMaker >> generatePlugins [
	"Generate the ``external'' plugins.
	 If this comes from a generator method, log it for convenience."
	abortBlock := [^self].
	self logGeneration.
	self generateExternalPlugins
]

{ #category : #'processing external files' }
MLVMMaker >> gnuifyInterpreterFile [
"post-process the interp.c file to make it gcc friendly"
	(Gnuifier on: self coreVMDirectory)
		doCleanupOldFile: doCleanupOldFiles;
		interpreterFilename: self interpreterFilename;
		gnuify.
]

{ #category : #'generate sources' }
MLVMMaker >> includeFilePathFor: sourceFileName [
	"Answer the fully-qualified path for the generated source file."
	^ self coreVMHeadersDirectory / sourceFileName
]

{ #category : #initialize }
MLVMMaker >> initialize [
	logger := Transcript.
	inline := true.
	forBrowser := false.
	internalPlugins := SortedCollection new.
	externalPlugins := SortedCollection new.
	platformName := 'Cross'.
	is64BitVM := false.
	doCleanupOldFiles := false.
	interpreterClassName := #StackInterpreterPrimitives.
	optionsDictionary := Dictionary newFromPairs: {#BytesPerWord. 4}.
	SlangStructType voidStructTypeCache
]

{ #category : #initialize }
MLVMMaker >> initializeAllPlugins [
	allPlugins := self providedPlugins
]

{ #category : #initialize }
MLVMMaker >> initializeInternal: arrayOfInternalPluginNames external: arrayOfExternalPluginNames [
	"try to set up with the listed internal and external plugins."

	self initialize.

	self internal: arrayOfInternalPluginNames external: arrayOfExternalPluginNames
]

{ #category : #initialize }
MLVMMaker >> internal: arrayOfInternalPluginNames external: arrayOfExternalPluginNames [
	"try to set up with the listed internal and external plugins. Check that they are supportable plugins, reject those that are not - remember that this depends on the platform etc "

	"since we went to some trouble to drop plugins we cannot handle, don't add them now"
	internalPlugins := (self availablePlugins intersection: arrayOfInternalPluginNames) select: [:pl | self canSupportPlugin: pl].
	allPlugins := allPlugins copyWithoutAll: internalPlugins.
	externalPlugins := (allPlugins intersection: arrayOfExternalPluginNames) select: [:pl | self canSupportPlugin: pl ].
	allPlugins := allPlugins copyWithoutAll: externalPlugins.
	
]

{ #category : #'UI access' }
MLVMMaker >> internalModules [
	^internalPlugins
]

{ #category : #'target directories' }
MLVMMaker >> internalPluginListName [
	"Answer the filename for the list of internal plugins"

	^'plugins.int'
]

{ #category : #'target directories' }
MLVMMaker >> internalPluginsDirectory [
	"return the directory for the internal plugins sources"
	|fd|
	fd := self coreVMDirectory directoryNamed: 'intplugins'.
	fd assureExistence.
	^fd
]

{ #category : #'target directories' }
MLVMMaker >> internalPluginsDirectoryFor: plugin [
	"return the directory for the internal plugin sources"
	|fd|
	fd := self internalPluginsDirectory directoryNamed: plugin moduleName.
	fd assureExistence.
	^fd
]

{ #category : #'plugin lists' }
MLVMMaker >> internalPluginsDo: aBlock [ 
	"for each class that should be an internal plugin, evaluate aBlock"
	self plugins: internalPlugins do: aBlock
]

{ #category : #'generate sources' }
MLVMMaker >> interpreterClass [

	^(Smalltalk classNamed: interpreterClassName) ifNotNil:
		[:interpreterClass| interpreterClass translationClass]
]

{ #category : #'generate sources' }
MLVMMaker >> interpreterClass: aClass [

	interpreterClassName := aClass name asString
]

{ #category : #'generate sources' }
MLVMMaker >> interpreterClassName [

	^interpreterClassName
]

{ #category : #'generate sources' }
MLVMMaker >> interpreterClassName: aString [
	| tmp |
	tmp := Smalltalk at: aString asSymbol ifAbsent: [nil].
	tmp isBehavior
		ifTrue: [self interpreterClass: tmp]
		ifFalse: [self invalidClassName]
]

{ #category : #'generate sources' }
MLVMMaker >> interpreterExportsFilePath [
	"return the full path for the interpreter exports file"
	^self coreVMHeadersDirectory fullNameFor: 'sqNamedPrims.h'
]

{ #category : #'target directories' }
MLVMMaker >> interpreterFilename [
	"Answer the filename for the core interpreter.  Default is 'interp.c'."

	^self interpreterClass sourceFileName
]

{ #category : #'target directories' }
MLVMMaker >> interpreterHeaderName [
	"Answer the filename for the core interpreter header.  Default is 'interp.h'."

	^'interp.h'
]

{ #category : #'generate sources' }
MLVMMaker >> interpreterHeaderPath [
	"Answer the fully-qualified path for the generated interpreter header file."

	^ self coreVMHeadersDirectory / self interpreterHeaderName
]

{ #category : #'private - errors' }
MLVMMaker >> invalidClassName [
	"This should raise a nice exception to a UI"
	(VMMakerException new messageText: self class name, ' invalid interpreter class name: ', interpreterClassName) signal
]

{ #category : #initialize }
MLVMMaker >> isFor64BitVM [
"is my flag to make a 64bit pointer model VM?"
	^is64BitVM
]

{ #category : #'UI access' }
MLVMMaker >> listOfName: aSymbol [
	"work out which list is the one associated with this symbol"
	#availableModules = aSymbol ifTrue:[^allPlugins].
	#internalModules = aSymbol ifTrue:[^internalPlugins].
	#externalModules =aSymbol ifTrue:[^externalPlugins].
	^nil
]

{ #category : #'objects from disk' }
MLVMMaker >> loadConfiguration: aConfigArray [
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
MLVMMaker >> logDateAndTime [
	| now |
	"do it this way since Time now includes milliseconds in some versions."
	now := Time dateAndTimeNow.
	logger print: now first; space; print: now last; cr; flush
]

{ #category : #'generate sources' }
MLVMMaker >> logGeneration [
	self configurationGeneratorNameOrNil ifNotNil:
		[:generator|
		 logger cr; nextPutAll: (generator selector copyReplaceAll: 'generate' with: '').
		 interpreterClassName ifNotNil:
			[logger space; nextPutAll: (CCodeGenerator shortMonticelloDescriptionForClass: (Smalltalk classNamed: interpreterClassName))].
		 sourceDirName ifNotNil:
			[logger nextPutAll: ' to '; nextPutAll: sourceDirName].
		 logger cr; flush]
]

{ #category : #'UI access' }
MLVMMaker >> logger [
	^logger
]

{ #category : #'UI access' }
MLVMMaker >> logger: aStream [
	logger := aStream.
]

{ #category : #'UI access' }
MLVMMaker >> makeAllModulesAvailable [
	self internal: #() external: #().
	self reinitializePluginsLists
]

{ #category : #'UI access' }
MLVMMaker >> makeAllModulesExternal [
	self initializeAllPlugins.
	self internal: #() external: self availablePlugins.
	self changed: #reinitialize 
]

{ #category : #'UI access' }
MLVMMaker >> makeAllModulesInternal [
	self initializeAllPlugins.
	self internal: self availablePlugins external: #().
	self changed: #reinitialize 
]

{ #category : #'target directories' }
MLVMMaker >> makefileDirectory [
"where to put generated makefile related files"
	^self sourceDirectory
]

{ #category : #'UI access' }
MLVMMaker >> movePlugin: pluginName from: srcListName to: dstListName [
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
MLVMMaker >> needsToRegenerateCogitFile [
	"Check the timestamp for the relevant classes and then the timestamp for the main source file (e.g. interp.c)
	 file if it already exists. Answer if the file needs regenerating."

	| cogitClass cogitClasses tStamp files |
	cogitClasses := (cogitClass := self interpreterClass cogitClass) withAllSuperclasses copyUpThrough: self vmmakerConfiguration baseCogitClass.
	cogitClasses addAllLast: cogitClass ancilliaryClasses.
	tStamp := cogitClasses inject: 0 into: [:tS :cl| tS max: cl timeStamp].

	"don't translate if the file(s) is newer than my timeStamp"
	files := (self coreVMDirectory children select: [ :e | e basename match: cogitClass activeCompilerClass moduleName, '*.c' ]).

	files isEmpty ifTrue:
		[^true].
	(files allSatisfy:
		[:fileName|
		(self coreVMDirectory entryAt: fileName ifAbsent: [nil])
			ifNil: [false]
			ifNotNil:
				[:fstat| | mTime |
				mTime := fstat modificationTime.
				mTime isInteger ifFalse: [mTime := mTime asSeconds].
				tStamp < mTime]]) ifTrue:
		[^self confirm: ('The ', self configurationNameIfAny, cogitClass printString,
			', ', cogitClass activeCompilerClass, '\classes have not been modified since the ',
			cogitClass processorSpecificSourceFileName,
			' source file\was last generated.  Do you still want to regenerate it?') withCRs].
	^true
]

{ #category : #initialize }
MLVMMaker >> needsToRegenerateInterpreterFile [
	"Check the timestamp for the relevant classes and then the timestamp for the main
	 source file (e.g. interp.c) if it already exists.  Answer if the file needs regenerating."

	| classes tStamp |
	classes := self interpreterClass withAllSuperclasses copyUpTo: SlangClass.
	self interpreterClass objectMemoryClass ifNotNil:
		[:objectMemoryClass|
		classes addAllLast: (objectMemoryClass withAllSuperclasses copyUpTo: SlangClass)].
	classes copy do:
		[:class| classes addAllLast: class ancilliaryClasses].
	tStamp := classes inject: 0 into: [:tS :cl| tS max: cl timeStamp].

	"don't translate if the file is newer than my timeStamp"
	(self coreVMDirectory / self interpreterFilename) ifExists: [ :aFile | | mTime |
		mTime := aFile modificationTime.
		mTime isInteger ifFalse: [mTime := mTime asSeconds].
		tStamp < mTime ifTrue:
			[^self confirm: 'The ', self configurationNameIfAny, 'interpreter classes have not been modified since\ the interpreter file was last generated.\Do you still want to regenerate the source file?' withCRs]].
	^true
]

{ #category : #accessing }
MLVMMaker >> options [
	^optionsDictionary
]

{ #category : #initialize }
MLVMMaker >> options: aDictionary [
	
	optionsDictionary := aDictionary

]

{ #category : #'target directories' }
MLVMMaker >> platformDirectories [
	| root |
	^((root := self platformRootDirectory) directoryNames
		reject: [:dirName|
				dirName first = $. ".svn .git et al"
				or: [dirName ='CVS']])
		collect: [:dirName|
				root directoryNamed: dirName]
]

{ #category : #'source directories' }
MLVMMaker >> platformDirectory [
	"return the directory where we should find the platform specific sources"
	| dir |
	dir := self platformRootDirectory directoryNamed: self platformName.
	dir exists ifFalse: "The supposed directory for the actual platform code does not exist."
		[^self couldNotFindPlatformDirectoryFor: self platformName].
	^dir
]

{ #category : #'UI access' }
MLVMMaker >> platformName [
	^platformName
]

{ #category : #'target directories' }
MLVMMaker >> platformPluginsDirectories [

	^self platformDirectories
		select: [:dir| dir directoryExists: self class pluginsDirName]
		thenCollect: [:dir| dir directoryNamed: self class pluginsDirName]
]

{ #category : #'source directories' }
MLVMMaker >> platformPluginsDirectory [
	"return the directory where we should find the platform plugin specific sources"

	| dir |
	dir := self platformDirectory directoryNamed: self class pluginsDirName.
	dir exists ifFalse: "The supposed directory for the plugins code does not exist.
					   We need to raise a suitable exception, but can't think of one right now."
		[^self couldNotFindPlatformDirectoryFor: 'any plugins needing ', self platformName].
	^dir
]

{ #category : #'source directories' }
MLVMMaker >> platformRootDirectory [
	"Answer the directory where we should find all platform's sources"
	| dir |
	dir := self platformRootDirectoryName asFileReference.
	dir exists ifFalse: "The supposed directory for the platforms code does not exist."
		 [^self couldNotFindDirectory: 'the platform code tree'].
	^dir
]

{ #category : #'source directories' }
MLVMMaker >> platformRootDirectoryName [
	"Answer the name of the directory where we should find all platform's sources"
	^platformRootDirName ifNil:
		[self class rootDirectory fullNameFor: self class platformsDirName]
]

{ #category : #'source directories' }
MLVMMaker >> platformRootDirectoryName: aString [
	"set the directory where we should find all platform's sources
	There really ought to be plausible sanity checks done here"
	platformRootDirName := aString.
	
	aString asFileReference exists 
		ifFalse:[self couldNotFindDirectory: aString. ^false].
	
	self reinitializePluginsLists.
	^true
]

{ #category : #'plugin lists' }
MLVMMaker >> plugins: aCollection do: aBlock [ 
	"for each class in aCollection that should be a plugin, evaluate aBlock"
	aCollection do: [:sym | (Smalltalk hasClassNamed: sym)
			ifTrue: [aBlock value: (Smalltalk classNamed: sym)]
			ifFalse:["Another place to raise a sensible error to the UI"
				self couldNotFindPluginClass: sym]]
]

{ #category : #'private - copying files' }
MLVMMaker >> primitiveCopyFileNamed: srcName to: dstName [ 
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
MLVMMaker >> privateGenerateInternalPlugin: pluginName [ 
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
MLVMMaker >> processFilesForExternalPlugin: plugin [ 

]

{ #category : #'processing external files' }
MLVMMaker >> processFilesForInternalPlugin: plugin [ 

]

{ #category : #initialize }
MLVMMaker >> providedPlugins [
	"generate the list by asking the InterpreterPlugins"
	^ ((self vmmakerConfiguration interpreterPluginClass allSubclasses
		select: [:cl | cl shouldBeTranslatedFor: platformName])
		collect: [:cl | cl name]) asSortedCollection
]

{ #category : #'UI access' }
MLVMMaker >> recomputeProvidedPlugins [
	allPlugins := self providedPlugins reject: [:p| (internalPlugins includes: p) or: [externalPlugins includes: p]]
]

{ #category : #'UI access' }
MLVMMaker >> reinitializePluginsLists [
	"something has changed that affects the validity of the plugin lists. Recalculate them as best we can. It is probably possible to check on the current lists and keep the configuration as close as possible the same; but for the moment just try to use the same lists "
	self initializeAllPlugins.
	self internal: internalPlugins external: externalPlugins.
	self changed: #reinitialize 
]

{ #category : #initialize }
MLVMMaker >> reinitializeWordSizeFrom: aCCodeGenerator [
	| wordSize |
	wordSize := aCCodeGenerator vmClass objectMemoryClass wordSize.
	optionsDictionary at: #BytesPerWord put: wordSize.
	is64BitVM := wordSize = 8
]

{ #category : #initialize }
MLVMMaker >> setPlatName: aString [
	"private - just set the platform name string, nothing else. Go away...."
	platformName := aString
]

{ #category : #'target directories' }
MLVMMaker >> sourceDirectory [

	^ self sourceDirectoryName asFileReference
		  ensureCreateDirectory;
		  yourself
]

{ #category : #'target directories' }
MLVMMaker >> sourceDirectoryName [
	^sourceDirName ifNil:
		[self class rootDirectory fullNameFor: self class sourceDirName]
]

{ #category : #'target directories' }
MLVMMaker >> sourceDirectoryName: aString [
	"Sanity check really ought to be added, This is the root directory for where the sources will be WRITTEN"
	sourceDirName := aString.
	
	sourceDirName asFileReference ensureCreateDirectory.

	self changed: #sourceDirectory.
	^true
]

{ #category : #'generate sources' }
MLVMMaker >> sourceFilePathFor: sourceFileName [
	"Answer the fully-qualified path for the generated source file."
	^ self coreVMDirectory / sourceFileName
]

{ #category : #exports }
MLVMMaker >> storeExternalPluginList [
	| contents filePath fileStream |
	((self externalPluginListName beginsWith: 'example')
	 and: [(self makefileDirectory asFileReference / self externalPluginListName) exists]) ifTrue:
		[^self].
	contents := String streamContents:
		[:s|
		s nextPutAll:'# Automatically generated makefile include for external plugins'.
		s cr; nextPutAll:'EXTERNAL_PLUGINS ='.
		self externalPluginsDo:
			[:cls|
			s space; nextPut: $\; cr; nextPutAll: cls moduleName].
		s cr].
	filePath := (self makefileDirectory / self externalPluginListName) fullName.
	(CCodeGenerator basicNew needToGenerateHeader: filePath file: filePath contents: contents) ifTrue:
		[[fileStream := VMMaker forceNewFileNamed: filePath] 
			on: FileDoesNotExistException 
			do:[^self couldNotOpenFile: filePath].
		 fileStream nextPutAll: contents; close]
]

{ #category : #exports }
MLVMMaker >> storeInternalPluginList [
	| contents filePath fileStream |
	((self internalPluginListName beginsWith: 'example')
	 and: [(self makefileDirectory asFileReference / self internalPluginListName) exists]) ifTrue:
		[^self].
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
MLVMMaker >> validateExternalPlugin:	plName [

	^self validatePlugin: plName in: externalPlugins
]

{ #category : #'generate sources' }
MLVMMaker >> validateInternalPlugin:	plName [

	^self validatePlugin: plName in: internalPlugins
]

{ #category : #'generate sources' }
MLVMMaker >> validatePlugin:	plName in: listOfPlugins [
"check that the plName is either an actual plugin class or a plugin class name. Return the plugin class or raise an error if nil"
	| plugin |
	plName isString
		ifTrue: [(listOfPlugins includes: plName)
				ifTrue: [plugin := Smalltalk classNamed: plName]]
		ifFalse: [((plName isBehavior
						and: [plName inheritsFrom: self vmmakerConfiguration interpreterPluginClass])
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

{ #category : #accessing }
MLVMMaker >> vmmakerConfiguration [
	
	^ vmmakerConfiguration
]

{ #category : #accessing }
MLVMMaker >> vmmakerConfiguration: aClass [ 
	vmmakerConfiguration := aClass
]

{ #category : #initialize }
MLVMMaker >> wordSize [
	"Return the bytes in a word for the chosen 32bit/64bit pointer setup chosen"
	^is64BitVM ifTrue:[8] ifFalse:[4]
]
