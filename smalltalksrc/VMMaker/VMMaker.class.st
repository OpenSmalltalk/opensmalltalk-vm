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
1) 'allPlugins' -  the list of all remaining generatable plugins. We scan this list and compare with the supported plugins as indicated by the file tree.
2) 'internalPlugins' -  the list of chosen internal plugins as moved from the allPlugins list.
3) 'externalPlugins' - the list of chosen external plugins as moved from the allPlugins list.
allPlugins is initialised with all the known plugins that can be built  with the classes and external files provided. This may well include some that are not applicable to the chosen platform and those will be filtered out if you try to move them to internalPlugins or externalPlugins later.
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
		'allFilesList',
		'interpreterClassName'
	],
	#classVars : [
		'CodeGeneratorCache',
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
	^self forPlatform: SmalltalkImage current platformName
]

{ #category : #initialisation }
VMMaker class >> forConfigurationFile: aFileName [
	| config  fileStream vmMaker |

	fileStream := FileStream oldFileNamed: aFileName.
	config := fileStream fileInObjectAndCode.
	vmMaker := self forPlatform: (config at: 5).
	vmMaker loadConfiguration: config.
	^vmMaker
]

{ #category : #initialisation }
VMMaker class >> forPlatform: platformName [
	"return a VMMaker initialised to build a default no-internal-plugins, no-external-plugins vm codebase"
	^(self activeVMMakerClassFor: platformName) new initialize setPlatName: platformName
]

{ #category : #'version testing' }
VMMaker class >> headerNotice [
"return a string to be put at the front of generated code files"
	^String streamContents:[:strm|
		strm nextPutAll: 'Automatically generated from Squeak on '.
		Time dateAndTimeNow do: [:e | strm nextPutAll: e asString; nextPut: Character space].
		strm cr.
		strm nextPutAll: '   by VMMaker '.
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
		at: #sourceDir put: 'src'.
	(self respondsTo: #initializeBrowserSupport)
		ifTrue: [self initializeBrowserSupport "see package SlangBrowser"]
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

{ #category : #'fetching updates' }
VMMaker class >> updateFromServer [
	"Update the image by loading all pending updates from the server. Also save local
	copies of the update files if the #updateSavesFile preference is set to true"

	"VMMaker updateFromServer"

	(Smalltalk hasClassNamed: #MCMcmUpdater)
		ifTrue: [(Smalltalk at: #MCMcmUpdater)
				updateFromRepositories: #('http://squeaksource.com/VMMaker' )]
		ifFalse: [self notify: 'MonticelloConfigurations not installed in this image']
]

{ #category : #'version testing' }
VMMaker class >> versionString [

	"VMMaker versionString"

	^'4.4.11'
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

{ #category : #'plugin lists' }
VMMaker >> canSupportPlugin: pluginClassName [ 
	"see if this plugin needs any external files and if so, check to see if 
	they seem to exist, as well as checking to see if the chosen platform can support it"
	[self validatePlugin: pluginClassName in: allPlugins , internalPlugins , externalPlugins]
		on: VMMakerException
		do: [:ex | self inform: ex messageText. ^false].
	^ true
]

{ #category : #'objects from disk' }
VMMaker >> configurationInfo [
	"build a simple Array of the configuration information that would be 
	usefully saved for later reloading:- 
	the list of internal & external plugins, the flags, the platform name, and the two major directory names"
	^ Array new writeStream nextPut: internalPlugins;
		 nextPut: externalPlugins;
		 nextPut: inline;
		 nextPut: forBrowser;
		 nextPut: self platformName;
		 nextPut: self sourceDirectory pathName;
		 nextPut: self platformRootDirectory pathName;
	contents
]

{ #category : #'copying files' }
VMMaker >> copyAssortedFiles [
	"copy any miscellaneous files/dirs from the cross-platformDirectory/misc/ToCopy -  
	general readme files etc, then from the platform specific directory/misc/ToCopy - makefiles, 
	utils etc that have to be copied."
	| srcDir |
	"Is there a crossPlatformDirectory subdirectory called 'misc'?"
	(self crossPlatformDirectory directoryExists: 'misc')
		ifTrue: [srcDir := self crossPlatformDirectory directoryNamed: 'misc'.
			"Is there a subdirectory called 'ToCopy' ?"
			(srcDir directoryExists: 'ToCopy') ifTrue:[
				srcDir := srcDir directoryNamed: 'ToCopy'.
				self copyFilesFromSourceDirectory: srcDir toTargetDirectory: self sourceDirectory]].
	"Is there a platformDirectory subdirectory called 'misc'?"
	(self platformDirectory directoryExists: 'misc')
		ifTrue: [srcDir := self platformDirectory directoryNamed: 'misc'.
			"Is there a subdirectory called 'ToCopy' ?"
			(srcDir directoryExists: 'ToCopy') ifTrue:[
				srcDir := srcDir directoryNamed: 'ToCopy'.
				self copyFilesFromSourceDirectory: srcDir toTargetDirectory: self sourceDirectory]]
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

{ #category : #'private - copying files' }
VMMaker >> copyFilesFrom: srcDir to: dstDir [
"This really ought to be a facility in file system. The major annoyance here is that file types and permissions are not handled by current Squeak code"
	[srcDir fileNames do: [:filenm | 
		self copyFileNamed: (srcDir fullNameFor: filenm) to: (dstDir fullNameFor: filenm)]] on: InvalidDirectoryError do:["do nothing if the directory is invalid"]

]

{ #category : #'private - copying files' }
VMMaker >> copyFilesFromSourceDirectory: srcDir toTargetDirectory: dstDir [ 
	"copy all the files and directories from srcDir to dstDir, recursively"	
	self copyFilesFromSourceDirectory: srcDir
			toTargetDirectory: dstDir
			recursively: true
]

{ #category : #'private - copying files' }
VMMaker >> copyFilesFromSourceDirectory: srcDir toTargetDirectory: dstDir recursively: recurseBoolean [
	"copy all files and subdirectories from srcDir to dstDir, optionally recursing down the tree.
	It is assumed that both directories already exist and have appropriate 
	permissions - proper error handling ought to be provided sometime. 
	Note how nice it would be if the file system classes already did this; 
	why, they could even defer to an improved file plugin for some of 
	these things."
	"copy all the files"
	| dirList  |
	srcDir localName = 'CVS' ifTrue:[logger show: 'CVS files NOT copied by VMMaker'; cr. ^self].
	srcDir localName = '.svn' ifTrue:[logger show: 'SVN files NOT copied by VMMaker'; cr. ^self].

	self copyFilesFrom: srcDir to: dstDir.

	recurseBoolean ifFalse:[^self].
	"If we are recursing create the subdirectories of srcDir in dstDir, and then copy that 
	subtree "
	dirList := srcDir directoryNames copyWithout: 'CVS'.
	dirList := srcDir directoryNames copyWithout: '.svn'.
	dirList do: 
		[:newDstDir | 
		(dstDir directoryExists: newDstDir)
			ifFalse: [dstDir createDirectory: newDstDir].
		self copyFilesFromSourceDirectory: (srcDir directoryNamed: newDstDir)
			toTargetDirectory: (dstDir directoryNamed: newDstDir)
			recursively: true]
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
	(VMMakerException new messageText: self class name, ' could not find directory ', dirName) signal
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
	^CCodeGenerator new initialize
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
	"delete directories in the external plugins tree with names not in the list  
	of external plugins. This will make sure that only wanted plugins are  
	left after generating external plugins - no previous ones will get left  
	there like unwanted porridge"
	(self externalPluginsDirectory directoryNames copyWithoutAll: self externalModuleNames)
		do: [:nm | (self externalPluginsDirectory directoryNamed: nm) recursiveDelete]
]

{ #category : #'target directories' }
VMMaker >> deleteUnwantedInternalPluginDirectories [
	"delete directories in the internal plugins tree with names not in the list  
	of internal plugins. This will make sure that only wanted plugins are  
	left after generating internal plugins - no previous ones will get left  
	there like unwanted porridge"
	(self internalPluginsDirectory directoryNames copyWithoutAll: self internalModuleNames)
		do: [:nm | (self internalPluginsDirectory directoryNamed: nm) recursiveDelete]
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

{ #category : #'generate sources' }
VMMaker >> generateEntire [
"generate the interp, internal plugins and exports as well as the external plugins"

	self generateMainVM.
	self generateExternalPlugins.
	self generateUtilityPrograms

]

{ #category : #exports }
VMMaker >> generateExportsFile [
	^self storeExportsOn: self interpreterExportsFilePath

]

{ #category : #'generate sources' }
VMMaker >> generateExternalPlugin: pluginName [ 
	"generate the named external plugin"
	| exports plugin |

	"Refuse to translate this plugin if it is not in the external plugins list or requires platform specific support and it is not present."
	[plugin := self validateExternalPlugin: pluginName] on: VMMakerException do:[:ex | ^self inform: ex messageText].

	exports := plugin
				translateInDirectory: (self externalPluginsDirectoryFor: plugin)
				doInlining: inline.
	logger show: 'external plugin ' , plugin name , ' generated as ' , plugin moduleName; cr.
	exports ifNotNil: ["if exp is nil we skip this since the plugin was already up to date"
			self export: exports forExternalPlugin: plugin].
	self processFilesForExternalPlugin: plugin
]

{ #category : #'generate sources' }
VMMaker >> generateExternalPlugins [
	"generate the external plugins"

	self deleteUnwantedExternalPluginDirectories.
	self externalPluginsDo: [:plugin | 
		self generateExternalPlugin: plugin].
	self storeExternalPluginList.
]

{ #category : #'generate sources' }
VMMaker >> generateInternalPlugin: pluginName [ 
	"generate the named internal plugin. Make sure the exports list is actually 
	correct and write it out"
	self deleteUnwantedInternalPluginDirectories.
	self privateGenerateInternalPlugin: pluginName.
	self generateExportsFile
]

{ #category : #'generate sources' }
VMMaker >> generateInternalPlugins [
	"generate the internal plugins and add their exports to the main list. te exports list is NOT written to file by this method"

	self deleteUnwantedInternalPluginDirectories.
	self internalPluginsDo: [:plugin | 
		self privateGenerateInternalPlugin: plugin].
	self storeInternalPluginList.
]

{ #category : #'generate sources' }
VMMaker >> generateInterpreterFile [
	"Translate the Smalltalk description of the virtual machine into C.  If 'self doInlining' is true, small method bodies are inlined to reduce procedure call overhead.  On the PPC, this results in a factor of three speedup with only 30% increase in code size.  Subclasses can use specialised versions of CCodeGenerator and interpreterClass."

	| cg cls |
	self needsToRegenerateInterpreterFile ifFalse: [^nil].
	self interpreterClass initialize.
	ObjectMemory initializeConstants.
	Interpreter initializeInterpreterSourceVersion.
	cg := self createCodeGenerator.
	cls := self interpreterClass.
	[cls == Object]
		whileFalse:
			[cg addClass: cls.
			cls := cls superclass].
	cg storeHeaderOnFile: self interpreterHeaderPath.
	cg storeCodeOnFile: self interpreterFilePath doInlining: self doInlining
]

{ #category : #'generate sources' }
VMMaker >> generateMainVM [
"generate the interp, internal plugins and exports"

	self generateInterpreterFile;
		processFilesForCoreVM;
		processAssortedFiles;
		generateInternalPlugins;
		generateExportsFile
]

{ #category : #'generate sources' }
VMMaker >> generateUtilityPrograms [
	"Any additional sources not directly part of the VM may be generated here"

	Smalltalk
		at: #ImageFormat
		ifPresent: [:cls |  "generate ckformat utility program"
			cls storeCkstatusOnFile: (self sourceDirectory fullNameFor: 'ckformat.c')]
]

{ #category : #'private - errors' }
VMMaker >> inform: aProblemString [
"log the problem in the transcript window"
	logger show: aProblemString; cr
]

{ #category : #initialize }
VMMaker >> initialize [
	logger := Transcript.
	inline := true.
	forBrowser := false.
	internalPlugins := SortedCollection new.
	externalPlugins := SortedCollection new.
	platformName := self class machinesDirName.
	allFilesList := Dictionary new.
	interpreterClassName := Interpreter name
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
"build the initial list of all possible plugins installed in the image"
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
	"try to set up with the listed internal and external plugins. Check that they are supportable plugins, reject those that are not - remember that this depends on the platform etc. This is the batch equivalent of using the VMMakerTool to drag each plugin to the relevant list(s) "

	"the intersection of the availablePlugins list and the input list stops any attempt to force in an improper plugin class"
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

	^Smalltalk at: interpreterClassName asSymbol
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
	interpreterClassName := aString.
	tmp := Smalltalk at: aString asSymbol ifAbsent: [nil].
	(tmp isNil or: [tmp isBehavior not]) ifTrue:
		[self invalidInterpreterClassName].
]

{ #category : #'generate sources' }
VMMaker >> interpreterExportsFilePath [
	"return the full path for the interpreter exports file"
	^self coreVMDirectory fullNameFor: 'sqNamedPrims.h'
]

{ #category : #'generate sources' }
VMMaker >> interpreterFilePath [
	"Answer the fully-qualified path for the generated interpreter file."

	^self coreVMDirectory fullNameFor: self interpreterFilename
]

{ #category : #'target directories' }
VMMaker >> interpreterFilename [
	"Answer the filename for the core interpreter.  Default is 'interp.c'."

	^'interp.c'
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
VMMaker >> invalidInterpreterClassName [
	"This should raise a nice exception to a UI"
	(VMMakerException new messageText: 'Problem - ''', interpreterClassName, ''' - is invalid as an interpreter class name: ') signal
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

	inline := aConfigArray at:3.
	forBrowser := aConfigArray at: 4.
	"This part must be ignored --> self setPlatName: (aConfigArray at: 5)."
	self sourceDirectoryName: (aConfigArray at: 6).
	self platformRootDirectoryName: ( aConfigArray at:7).
	self initializeAllPlugins.
	self internal: (aConfigArray at:1) external:(aConfigArray at:2).
	"Note - reserve slots 7 and 8 for backward compatibility. Slot 8 was
	previously used for the 32bit / 64bit flag, which is no longer required
	for the standard interpreter VM. Any new slots added should begin at 9."
	self changed: #reinitialize 
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
	"the VMMakerTool UI has been used to drag a plugin from one list to another "
	"we need to do some tests - 
		+are the lists actually ours? 
		+is the plugin ours? 
		+is the destination list one where we must check the plugin for 
		acceptability?
	return true if all is ok, false otherwise"
	| dstList srcList |
	dstList := self listOfName: dstListName.
	srcList := self listOfName: srcListName.
	dstList == allPlugins
		ifTrue: [dstList
				add: (srcList remove: pluginName)]
		ifFalse: ["the dest must be internal or external, so check the plugin for acceptability "
			(self canSupportPlugin: pluginName)
				ifTrue: [dstList
						add: (srcList remove: pluginName)]]
]

{ #category : #initialize }
VMMaker >> needsToRegenerateInterpreterFile [
"check the timestamp for the relevant classes and then the timestamp for the interp.c file if it already exists. Return true if the file needs regenerating, false if not"

	| tStamp fstat |
	tStamp := {self interpreterClass. ObjectMemory}
				inject: 0
				into: [:tS :cl | tS max: cl timeStamp].

	"don't translate if the file is newer than my timeStamp"
	fstat := self coreVMDirectory entryAt: self interpreterFilename ifAbsent:[nil].
	fstat ifNotNil:[tStamp < fstat modificationTime ifTrue:[^false]].
	^true

]

{ #category : #'processing external files' }
VMMaker >> nonAdminFilesIn: directory [ 
	"Answer file names in directory tree, excluding those associated with
	version control systems"
	^ directory fullNamesOfAllFilesInSubtree
		reject: [:el | (el findString: 'CVS' startingAt: 1) ~= 0
				or: [(el findString: '.svn' startingAt: 1) ~= 0]]
]

{ #category : #'private - errors' }
VMMaker >> notSuitablePlugin: pluginClass forPlatform: platName [
	(VMMakerException new messageText: pluginClass name, ' is not suitable for building for ', platName) signal
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
				^self couldNotFindPluginClass: sym]]
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
	"Refuse to translate this plugin if it is not in the internal plugins list or requires platform specific support and it is not present."
	[plugin := self validateInternalPlugin: pluginName] on: VMMakerException do:[:ex | self inform: ex messageText].

	plugin
		ifNil: [^ self couldNotFindPluginClass: pluginName].
	plugin
		translateInDirectory: (self internalPluginsDirectoryFor: plugin)
		doInlining: inline.
	logger show: 'internal plugin ' , plugin name , ' generated as ' , plugin moduleName; cr.
	self processFilesForInternalPlugin: plugin.

]

{ #category : #'processing external files' }
VMMaker >> processAssortedFiles [
	"Here is where we get a chance to process any files needed as part of the make process; instructions, makefile fragments, resources etc.
	The default is to copy any miscellaneous files/dirs from the cross-platformDirectory/misc/ToCopy, then from the platform specific directory/misc/ToCopy. You can put any tree structure you like under misc/ToCopy, should that be important to you."
	| srcDir |
	"Is there a crossPlatformDirectory subdirectory called 'misc'?"
	(self crossPlatformDirectory directoryExists: 'misc')
		ifTrue: [srcDir := self crossPlatformDirectory directoryNamed: 'misc'.
			"Is there a subdirectory called 'ToCopy' ?"
			(srcDir directoryExists: 'ToCopy') ifTrue:[
				srcDir := srcDir directoryNamed: 'ToCopy'.
				self copyFilesFromSourceDirectory: srcDir toTargetDirectory: self sourceDirectory]].
	"Is there a platformDirectory subdirectory called 'misc'?"
	(self platformDirectory directoryExists: 'misc')
		ifTrue: [srcDir := self platformDirectory directoryNamed: 'misc'.
			"Is there a subdirectory called 'ToCopy' ?"
			(srcDir directoryExists: 'ToCopy') ifTrue:[
				srcDir := srcDir directoryNamed: 'ToCopy'.
				self copyFilesFromSourceDirectory: srcDir toTargetDirectory: self sourceDirectory]]
]

{ #category : #'processing external files' }
VMMaker >> processFilesForCoreVM [
	"process any cross-platform files from the crossPlatformDir and then any files relating to the core vm from the platformDirectory's vm subdirectory."
	"This is a stub ready for collecting all the filenames etc that might be needed to write a makefile. No details are yet certain."

	| vmDirName fList |
	vmDirName := self class coreVMDirName.
	fList := OrderedCollection new.
	{self crossPlatformDirectory directoryNamed: vmDirName.
	self platformDirectory directoryNamed: vmDirName.
	self coreVMDirectory}
		do:[:dir| fList addAll: (self nonAdminFilesIn: dir)].
	allFilesList at: 'vm' put: fList

]

{ #category : #'processing external files' }
VMMaker >> processFilesForExternalPlugin: plugin [ 
	"process any files relating to the external plugin.
	This also provides a  stub ready for collecting all the filenames etc that might be needed to write a makefile, carefully weeding out any CVS related files. No details are yet certain."
	|fList|
	fList := OrderedCollection new.
	{self crossPlatformPluginsDirectory directoryNamed:  plugin moduleName.
	self platformPluginsDirectory directoryNamed:  plugin moduleName.
	self externalPluginsDirectoryFor: plugin}
		do:[:dir| fList addAll: (self nonAdminFilesIn: dir)].
	allFilesList at: plugin moduleName put: fList
]

{ #category : #'processing external files' }
VMMaker >> processFilesForInternalPlugin: plugin [ 
	"process any files relating to the internal plugin.
	This also provides a  stub ready for collecting all the filenames etc that might be needed to write a makefile, carefully weeding out any CVS related files. No details are yet certain."
	|fList|
	fList := OrderedCollection new.
	{self crossPlatformPluginsDirectory directoryNamed:  plugin moduleName.
	self platformPluginsDirectory directoryNamed:  plugin moduleName.
	self internalPluginsDirectoryFor: plugin}
		do:[:dir| fList addAll: (self nonAdminFilesIn: dir)].
	allFilesList at: plugin moduleName put: fList
]

{ #category : #initialize }
VMMaker >> providedPlugins [
	"generate the list by asking the InterpreterPlugins"
	^ ((InterpreterPlugin allSubclasses
		select: [:cl | cl shouldBeTranslated])
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
VMMaker >> reinitializePluginsLists [
	"something has changed that affects the validity of the plugin lists. Recalculate them as best we can. It is probably possible to check on the current lists and keep the configuration as close as possible the same; but for the moment just try to use the same lists "
	self initializeAllPlugins.
	self internal: internalPlugins external: externalPlugins.
	self changed: #reinitialize 
]

{ #category : #'objects from disk' }
VMMaker >> saveConfigurationTo: aFile [
	"write info about the current configuration to a file."
	| fileStream |
	fileStream := FileStream newFileNamed: aFile.
	fileStream fileOutClass: nil andObject: self configurationInfo
]

{ #category : #initialize }
VMMaker >> setPlatName: aString [
	"private - just set the platform name string, nothing else. Go away...."
	platformName := aString
]

{ #category : #'target directories' }
VMMaker >> sourceDirectory [
	| fd |
	fd := FileDirectory default
				directoryNamed: (sourceDirName
						ifNil: [self class sourceDirName]).
	fd assureExistence.
	^ fd
]

{ #category : #'target directories' }
VMMaker >> sourceDirectoryName: aString [
	"Sanity check really ought to be added, This is the root directory for where the sources will be WRITTEN"
	sourceDirName := aString.
	(FileDirectory on: aString) assureExistence.
	self changed: #sourceDirectory.
	^true
]

{ #category : #exports }
VMMaker >> storeExportsOn: aFilename [ 
	"Store the exports on the given file"
	| s |
	[s := CrLfFileStream forceNewFileNamed: aFilename] 
		on: FileDoesNotExistException 
		do:[^self couldNotOpenFile: aFilename].
	s nextPutAll: '/* '.
	s nextPutAll: VMMaker headerNotice.
	s nextPutAll: ' */'; cr.
	s nextPutAll:'/* This is an automatically generated table of all builtin modules in the VM */'; cr.
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
	s cr; nextPutAll:'};'; cr.
	s close
]

{ #category : #exports }
VMMaker >> storeExternalPluginList [
	| s fileName |
	fileName := self makefileDirectory fullNameFor: 'plugins.ext'.
	[s := CrLfFileStream forceNewFileNamed: fileName] 
		on: FileDoesNotExistException 
		do:[^self couldNotOpenFile: fileName].
	s nextPutAll:'# Automatically generated makefile include for external plugins'.
	s cr; nextPutAll:'EXTERNAL_PLUGINS ='.
	self externalPluginsDo:[:cls|
		s space; nextPutAll: cls moduleName.
	].
	s cr; close
]

{ #category : #exports }
VMMaker >> storeInternalPluginList [
	| s fileName |
	fileName := self makefileDirectory fullNameFor: 'plugins.int'.
	[s := CrLfFileStream forceNewFileNamed: fileName] 
		on: FileDoesNotExistException 
		do:[^self couldNotOpenFile: fileName].
	s nextPutAll:'# Automatically generated makefile include for internal plugins'.
	s cr; nextPutAll:'INTERNAL_PLUGINS ='.
	self internalPluginsDo:[:cls|
		s space; nextPutAll: cls moduleName.
	].
	s cr; close
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

	"Make sure we have any and all platform and file support for this plugin"

	(plugin isSuitablePluginForPlatform: self platformName) ifFalse:[^self notSuitablePlugin: plugin forPlatform: self platformName].
		
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
