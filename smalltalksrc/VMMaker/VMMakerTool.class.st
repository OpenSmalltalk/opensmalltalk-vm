"
VMMakerTool help information
------------------------------------
If you really get stuck, send mail to the Squeak mailing list, squeak-dev@lists.squeakfoundation.org

	VMMakerTool openInWorld

What this is
--------------
This tool is a simple interactive interface to VMMaker. You can change the directory paths for where the system looks for the platform files (those C files that are handwritten for each platform) and where it will put the assembled sources (the appropriate platform files and generated files) ready for you to compile into a new vm. You can change the platform for which it will generate files. You can choose which plugins are built and whether they are built for internal or external use. 

How to use it
---------------
To build a configuration, drag plugins from the leftmost  'Plugins not built' list to either the 'Internal Plugins' list or the 'External Plugins' list.  Plugins that cannot be built on your machine due to missing files will not be draggable.
Once you have a configuration, you can save it for later retrieval by pressing the 'Save Configuration' button. Unsurprisingly you can reload a saved configuration with the 'Load Configuration' button.

To generate an entire code tree, press the 'Generate All' button. This will process all the vm and plugin files needed for your configuration. To generate only the files for the vm and any internal plugins, use the 'Generate Core VM' button. This will be most useful if you are experimenting with the design of the vm internals or new object memory layouts etc. The 'Generate External Plugins' button will regenerate all the plugins in the External Plugins list. Note that 'excess' directories will be deleted each time you generate the vm in order to reduce potential confusion if you move a plugin from internal to external etc. If you repeatedly generate the vm only the files that appear to be out of date will be recreated; this drastically reduces the time taken if you have only changed a single plugin class for example.

You can also generate internal or external plugins singly, using the menus in the lists but be warned - internal plugins are tightly related to the generated file 'vm/sqNamedPrims.h' and adding or removing an internal plugin without regenerating this (via 'Generate Core VM' or 'Generate All') will cause much grief. The application attempts to prevent this, but there are surely ways to confuse both yourself and the code. In general when writing experimental plugins it is much simpler to build them as external during the development cycle. 

If the default path for the platforms code is not correct for your machine you can use the 'Find Path' button to search for a plausible directory. Note that this could take an arbitrarily long time on a machine with connections to other machines since you may end up searching all their disc space as well.

You can choose from a menu of all known platforms (at least, all those known in the set of files on your machine) by using the 'Find platform' button. This is useful if you want to generate files for some other platform and feel uncertain of the exact spelling. By default the platform will be set to that upon which you are running.

If you feel the need to delete all the generated files you can press the 'Clean out' button - this will recursively delete everything below the path for the generated sources.

Details
-------
You really ought to read the class comment for VMMaker. Really. Go on, do it now.

Errors
-------
A number of errors are possible, mostly relating to the two directory paths and the platform name. As much as possible these are trapped and you will see 'inform' menus to let you know. Inevitably, if you put in the effort, you will be able to confuse the tool and break it.

"
Class {
	#name : #VMMakerTool,
	#superclass : #Model,
	#instVars : [
		'vmMaker',
		'allPluginsList',
		'allPluginsSelection',
		'allPluginsSelectionsArray',
		'internalPluginsList',
		'internalPluginsSelection',
		'internalPluginsSelectionsArray',
		'externalPluginsList',
		'externalPluginsSelection',
		'externalPluginsSelectionsArray',
		'logger',
		'interpreterClassMorph',
		'platformPathMorph',
		'platformNameMorph',
		'generatedPathMorph'
	],
	#category : 'VMMaker-Building'
}

{ #category : #'instance creation' }
VMMakerTool class >> initialize [

	 (TheWorldMenu respondsTo: #registerOpenCommand:)

         ifTrue: [TheWorldMenu registerOpenCommand: {'VMMaker'. {self. #openInWorld}. 'The VM making tool'}].
]

{ #category : #'instance creation' }
VMMakerTool class >> new [
	^super new initialize
]

{ #category : #'instance creation' }
VMMakerTool class >> openInWorld [
	"Build a VMMakerTool and open it"
	"VMMakerTool openInWorld"

	^self new buildWindow openInWorld
]

{ #category : #unloading }
VMMakerTool class >> unload [

	TheWorldMenu unregisterOpenCommandWithReceiver: self
]

{ #category : #'drag and drop' }
VMMakerTool >> acceptDroppingMorph: transferMorph event: evt inMorph: aMorph [
	"Here we are fetching information from the dropped transferMorph and performing the correct action for this drop.
	As long as the source is part of this tool, move the dragged item from the source list to the destination list"

	transferMorph source model = self ifFalse:[^false].

	^self moveItem: transferMorph passenger from: transferMorph source to: aMorph
]

{ #category : #menus }
VMMakerTool >> availableListMenu: aMenu [

	aMenu addList:#(
			('make all external'						makeAllPluginsExternal)
			('make all internal'						makeAllPluginsInternal)
			('make all available'					makeAllPluginsAvailable)
			-
			('browse plugin' 						browseSelectedAvailablePlugin)).
	^ aMenu
]

{ #category : #'list access' }
VMMakerTool >> availableListSelectionAt: index [
"return the boolean to say if the available plugin at index is selected"
	^allPluginsSelectionsArray at: index
]

{ #category : #'list access' }
VMMakerTool >> availableListSelectionAt: index put: bool [
"set the boolean to say if the available plugin at index is selected"
	^allPluginsSelectionsArray at: index put: bool
]

{ #category : #'list access' }
VMMakerTool >> availableModules [
	^vmMaker availablePlugins
]

{ #category : #menus }
VMMakerTool >> browseSelectedAvailablePlugin [

	| plugin |
	plugin := self availableModules at: self currentAvailableModuleIndex ifAbsent: [^self].
	(Smalltalk classNamed: plugin) browseHierarchy
]

{ #category : #menus }
VMMakerTool >> browseSelectedExternalPlugin [

	| plugin |
	plugin := self externalModules at: self currentExternalModuleIndex ifAbsent: [^self].
	(Smalltalk classNamed: plugin) browseHierarchy
]

{ #category : #menus }
VMMakerTool >> browseSelectedInternalPlugin [

	| plugin |
	plugin := self internalModules at: self currentInternalModuleIndex ifAbsent: [^self].
	(Smalltalk classNamed: plugin) browseHierarchy
]

{ #category : #initialisation }
VMMakerTool >> buildWindow [
"VMMakerTool openInWorld"
	| sysWin box verticalOffset |
	sysWin _ (SystemWindow labelled: 'VMMaker')
				model: self.

	verticalOffset _ 0.
	"add a row of buttons to start up various actions"
	box _ AlignmentMorph new vResizing: #shrinkWrap.
	box addMorphBack: (SimpleButtonMorph new target: self;
			 label: 'Generate All';
			 actionSelector: #generateAll;
			 hResizing: #spaceFill;
			 setBalloonText: 'Generate the sources for the core VM and all chosen plugins').
	box addMorphBack: (SimpleButtonMorph new target: self;
			 label: 'Generate Core VM';
			 actionSelector: #generateCore;
			 hResizing: #spaceFill;
			 setBalloonText: 'Generate the sources for the core vm and any internal plugins').

	box addMorphBack: (SimpleButtonMorph new target: self;
			 label: 'Generate External Plugins';
			 actionSelector: #generateExternal;
			 hResizing: #spaceFill;
			 setBalloonText: 'Generate the sources for all external plugins').
	sysWin
		addMorph: box
		fullFrame: (LayoutFrame
				fractions: (0 @ 0 corner: 1 @ 0)
				offsets: (0 @ verticalOffset corner: 0 @ (verticalOffset _ verticalOffset + box height - 1))).

	"add a row of buttons to start up various actions"
	box _ AlignmentMorph new vResizing: #shrinkWrap.
	box addMorphBack: (SimpleButtonMorph new target: self;
			 label: 'Load Configuration';
			 actionSelector: #loadConfig;
			 hResizing: #spaceFill;
			 setBalloonText: 'Load a previously saved configuration').
	box addMorphBack: (SimpleButtonMorph new target: self;
			 label: 'Save Configuration';
			 actionSelector: #saveConfig;
			 hResizing: #spaceFill;
			 setBalloonText: 'Save the current configuration').
	box addMorphBack: (SimpleButtonMorph new target: self;
			 label: 'Help';
			 actionSelector: #helpText;
			 hResizing: #spaceFill;
			 setBalloonText: 'Open the help window').
	sysWin
		addMorph: box
		fullFrame: (LayoutFrame
				fractions: (0 @ 0 corner: 1 @ 0)
				offsets: (0 @ verticalOffset corner: 0 @ (verticalOffset _ verticalOffset + box height - 1))).

	"add the labelled text field for the interpreter class name - 
	typically Interpreter"
	box _ AlignmentMorph new.
	box addMorph: (TextMorph new contents: 'Interpreter class name:' asText allBold) lock;
		 setBalloonText: 'The name of the Interpreter class'.
	sysWin
		addMorph: box
		fullFrame: (LayoutFrame
				fractions: (0 @ 0 corner: 0.3 @ 0)
				offsets: (0 @ verticalOffset corner: 0 @ (verticalOffset + box height - 1))).
	box _ AlignmentMorph new.
	sysWin
		addMorph: box
		fullFrame: (LayoutFrame
				fractions: (1 @ 0 corner: 1 @ 0)
				offsets: (-100 @ verticalOffset corner: 0 @ (verticalOffset + box height - 1))).
	sysWin
		addMorph: ((interpreterClassMorph _ PluggableTextMorph
				on: self
				text: #interpreterClassName
				accept: #interpreterClassName:)
				acceptOnCR: true)
		fullFrame: (LayoutFrame
				fractions: (0.3 @ 0 corner: 1 @ 0)
				offsets: (0 @ verticalOffset corner: -100 @ (verticalOffset _ verticalOffset + box height - 1))).

	"add the labelled text field for the path to the platform sources - 
	typically {current dir}/platforms"
	box _ AlignmentMorph new.
	box addMorph: (TextMorph new contents: 'Path to platforms code:' asText allBold) lock;
		 setBalloonText: 'The directory where the platform source tree is found; can be edited in text field to the right. Default of {working directory}/src is strongly recommended'.
	sysWin
		addMorph: box
		fullFrame: (LayoutFrame
				fractions: (0 @ 0 corner: 0.3 @ 0)
				offsets: (0 @ verticalOffset corner: 0 @ (verticalOffset + box height - 1))).
	box _ AlignmentMorph new.
	box addMorphBack: (SimpleButtonMorph new target: self;
			 label: 'Find Path';
			 actionSelector: #findPlatformsPath;
			 hResizing: #spaceFill;
			 setBalloonText: 'Choose the directory where you keep the platform specific code from a file dialogue').
	sysWin
		addMorph: box
		fullFrame: (LayoutFrame
				fractions: (1 @ 0 corner: 1 @ 0)
				offsets: (-100 @ verticalOffset corner: 0 @ (verticalOffset + box height - 1))).
	sysWin
		addMorph: ((platformPathMorph _ PluggableTextMorph
				on: self
				text: #platformsPathText
				accept: #platformsPathText:)
				acceptOnCR: true)
		fullFrame: (LayoutFrame
				fractions: (0.3 @ 0 corner: 1 @ 0)
				offsets: (0 @ verticalOffset corner: -100 @ (verticalOffset _ verticalOffset + box height - 1))).

	"add the labelled text field for the name of the platform - typically the 
	current platform"
	box _ AlignmentMorph new.
	box addMorph: (TextMorph new contents: 'Platform name:' asText allBold) lock;
		 setBalloonText: 'The platform name (as returned by Smalltalk platformName - unix, Mac OS, RISCOS, win32 etc); can be edited (in text field to the right) to cross generate'.
	sysWin
		addMorph: box
		fullFrame: (LayoutFrame
				fractions: (0 @ 0 corner: 0.3 @ 0)
				offsets: (0 @ verticalOffset corner: 0 @ (verticalOffset + box height - 1))).
	box _ AlignmentMorph new.
	box addMorphBack: (SimpleButtonMorph new target: self;
			 label: 'Find platform';
			 actionSelector: #platformsListMenu;
			 hResizing: #spaceFill;
			 setBalloonText: 'Choose from a list of known platforms. The default is this current platform.').
	sysWin
		addMorph: box
		fullFrame: (LayoutFrame
				fractions: (1 @ 0 corner: 1 @ 0)
				offsets: (-100 @ verticalOffset corner: 0 @ (verticalOffset + box height - 1))).
	sysWin
		addMorph: ((platformNameMorph _ PluggableTextMorph
				on: self
				text: #platformNameText
				accept: #platformNameText:)
				acceptOnCR: true)
		fullFrame: (LayoutFrame
				fractions: (0.3 @ 0 corner: 1 @ 0)
				offsets: (0 @ verticalOffset corner: -100 @ (verticalOffset _ verticalOffset + box height - 1))).

	"Add the labelled text field to specify where the generated code should 
	go; typically {current dir}/sources"
	box _ AlignmentMorph new.
	box addMorph: (TextMorph new contents: 'Path to generated sources' asText allBold;
			 lock);
		 setBalloonText: 'The directory where the built sources will be placed; can be edited in text field to the right. The default is strongly recommended; makefile alterations may be needed if you use a different path.'.
	sysWin
		addMorph: box
		fullFrame: (LayoutFrame
				fractions: (0 @ 0 corner: 0.3 @ 0)
				offsets: (0 @ verticalOffset corner: 0 @ (verticalOffset + box height - 1))).
	box _ AlignmentMorph new.
	box addMorphBack: (SimpleButtonMorph new target: self;
			 label: 'Clean out';
			 actionSelector: #cleanoutSrcDir;
			 hResizing: #spaceFill;
			 setBalloonText: 'Clean out all the files in the target directory, ready for a clean build').
	sysWin
		addMorph: box
		fullFrame: (LayoutFrame
				fractions: (1 @ 0 corner: 1 @ 0)
				offsets: (-100 @ verticalOffset corner: 0 @ (verticalOffset + box height - 1))).
	sysWin
		addMorph: ((generatedPathMorph _ PluggableTextMorph
				on: self
				text: #sourcePathText
				accept: #sourcePathText:)
				acceptOnCR: true)
		fullFrame: (LayoutFrame
				fractions: (0.3 @ 0 corner: 1 @ 0)
				offsets: (0 @ verticalOffset corner: -100 @ (verticalOffset _ verticalOffset + box height - 1))).

	"Add the list of plugins that are available to build"
	allPluginsList _ (PluggableListMorph
				on: self
				list: #availableModules
				selected: #currentAvailableModuleIndex
				changeSelected: #currentAvailableModuleIndex:
				menu: #availableListMenu:
				keystroke: nil) enableDragNDrop.
	allPluginsList hResizing: #spaceFill;
		 vResizing: #spaceFill;
		 borderWidth: 0.
	box _ AlignmentMorph newColumn.
	box addMorphBack: (TextMorph new contents: 'Plugins not built' asText allBold;
			 lock);
		 setBalloonText: 'List of plugins that are available to build but not yet chosen. Drag to either other list or use menu option to move in bulk'.
	box addMorphBack: allPluginsList.
	sysWin
		addMorph: box
		fullFrame: (LayoutFrame
				fractions: (0 @ 0 corner: 1 / 3 @ 1)
				offsets: (0 @ verticalOffset corner: 0 @ -100)).
	"make the list for plugins that will be built for internal linking"
	internalPluginsList _ (PluggableListMorph
				on: self
				list: #internalModules
				selected: #currentInternalModuleIndex
				changeSelected: #currentInternalModuleIndex:
				menu: #internalListMenu:
				keystroke: nil) enableDragNDrop.
	internalPluginsList hResizing: #spaceFill;
		 vResizing: #spaceFill;
		 borderWidth: 0.
	box _ AlignmentMorph newColumn.
	box addMorphBack: (TextMorph new contents: 'Internal Plugins' asText allBold;
			 lock);
		 setBalloonText: 'List of plugins chosen to be built internally'.
	box addMorphBack: internalPluginsList.
	sysWin
		addMorph: box
		fullFrame: (LayoutFrame
				fractions: (1 / 3 @ 0 corner: 2 / 3 @ 1)
				offsets: (0 @ verticalOffset corner: 0 @ -100)).

	"make the list for plugins to be built externally (ie as DLLs, SO or 
	whatever suits the platform"
	externalPluginsList _ (PluggableListMorph
				on: self
				list: #externalModules
				selected: #currentExternalModuleIndex
				changeSelected: #currentExternalModuleIndex:
				menu: #externalListMenu:
				keystroke: nil) enableDragNDrop.
	externalPluginsList hResizing: #spaceFill;
		 vResizing: #spaceFill;
		 borderWidth: 0.
	box _ AlignmentMorph newColumn.
	box addMorphBack: (TextMorph new contents: 'External Plugins' asText allBold;
			 lock);
		 setBalloonText: 'List of plugins chosen to be built externally'.
	box addMorphBack: externalPluginsList.
	sysWin
		addMorph: box
		fullFrame: (LayoutFrame
				fractions: (2 / 3 @ 0 corner: 1 @ 1)
				offsets: (0 @ verticalOffset corner: 0 @ -100)).
	sysWin
		addMorph: (PluggableTextMorph on: logger text: nil accept: nil
			readSelection: nil menu: nil)
		fullFrame: (LayoutFrame
				fractions: (0 @ 1 corner: 1 @ 1)
				offsets: (0 @ -100 corner: 0 @ 0)).
	^ sysWin
]

{ #category : #'as yet unclassified' }
VMMakerTool >> checkOK [
	"check as many settings as we can and report true if all seems ok"
	(platformPathMorph accept; hasUnacceptedEdits) ifTrue:[^false].
	(platformNameMorph accept; hasUnacceptedEdits) ifTrue:[^false].
	(generatedPathMorph accept; hasUnacceptedEdits) ifTrue:[^false].

	[vmMaker platformPluginsDirectory; crossPlatformPluginsDirectory]
		on: VMMakerException
		do: [:ex| self inform: ex messageText.
			^ false].
	^ true
]

{ #category : #'path access' }
VMMakerTool >> cleanoutSrcDir [
	"remove the entire generated src tree, ready for a nice clean build"
	vmMaker deleteEntireGeneratedTree
]

{ #category : #'list access' }
VMMakerTool >> currentAvailableModuleIndex [
	allPluginsSelection ifNil:[^0].
	^allPluginsSelection
]

{ #category : #'list access' }
VMMakerTool >> currentAvailableModuleIndex: anInteger [
	allPluginsSelection _ anInteger.
	self changed: #currentAvailableModuleIndex
]

{ #category : #'list access' }
VMMakerTool >> currentExternalModuleIndex [
	externalPluginsSelection ifNil:[^0].
	^externalPluginsSelection
]

{ #category : #'list access' }
VMMakerTool >> currentExternalModuleIndex: anInteger [
	externalPluginsSelection _ anInteger.
	self changed: #currentExternalModuleIndex
]

{ #category : #'list access' }
VMMakerTool >> currentInternalModuleIndex [
	internalPluginsSelection ifNil:[^0].
	^internalPluginsSelection
]

{ #category : #'list access' }
VMMakerTool >> currentInternalModuleIndex: anInteger [
	internalPluginsSelection _ anInteger.
	self changed: #currentInternalModuleIndex
]

{ #category : #'drag and drop' }
VMMakerTool >> dragPassengerFor: item inMorph: dragSource [ 
	(dragSource isKindOf: PluggableListMorph)
		ifFalse: [^item].
	^item contents
]

{ #category : #'drag and drop' }
VMMakerTool >> dragTransferTypeForMorph: dragSource [ 
	^(dragSource isKindOf: PluggableListMorph)
		ifTrue: [dragSource getListSelector]
]

{ #category : #menus }
VMMakerTool >> externalListMenu: aMenu [

	aMenu addList:#(
			('make all external'						makeAllPluginsExternal)
			('make all internal'						makeAllPluginsInternal)
			('make all available'					makeAllPluginsAvailable)
			-
			('browse plugin' 						browseSelectedExternalPlugin)
			-
			('generate plugin'						generateSelectedExternalPlugin)).
	^ aMenu
]

{ #category : #'list access' }
VMMakerTool >> externalListSelectionAt: index [
"return the boolean to say if the external plugin at index is selected"
	^externalPluginsSelectionsArray at: index
]

{ #category : #'list access' }
VMMakerTool >> externalListSelectionAt: index put: bool [
"set the boolean to say if the external plugin at index is selected"
	^externalPluginsSelectionsArray at: index put: bool
]

{ #category : #'list access' }
VMMakerTool >> externalModules [
	^vmMaker externalModules
]

{ #category : #'path access' }
VMMakerTool >> findPlatformsPath [
	| dir |
	dir _ FileList2 modalFolderSelector.
	dir ifNil: [^nil].
	self platformsPathText: dir pathName
]

{ #category : #'path access' }
VMMakerTool >> findPlatformsPathFrom: fd [
	| path |
	Utilities informUserDuring:[:bar|
		path := self findPlatformsPathFrom: fd informing: bar.
	].
	^path
]

{ #category : #'path access' }
VMMakerTool >> findPlatformsPathFrom: fd informing: bar [
	| dirNames possiblePath |
	bar value: 'Searching in ', fd pathName.
	dirNames := fd directoryNames.
	(dirNames includes: 'platforms') ifTrue:[
		possiblePath := fd pathName, fd pathNameDelimiter asString, 'platforms'.
		(self confirm: 'Found a platforms directory at
', possiblePath,'
Do you want me to use it?') ifTrue:[^possiblePath].
	].
	dirNames do:[:dd|
		possiblePath := self findPlatformsPathFrom: (fd directoryNamed: dd) informing: bar.
		possiblePath ifNotNil:[^possiblePath].
	].
	^nil
]

{ #category : #'generate sources' }
VMMakerTool >> generateAll [
	"tell the vmMaker to build all the sources"
	self checkOK
		ifTrue: [[vmMaker generateEntire]
				on: VMMakerException
				do: [:ex| self inform: ex messageText]]
]

{ #category : #'generate sources' }
VMMakerTool >> generateCore [
	"tell the vmMaker to build all the core vm sources"
	self checkOK
		ifTrue: [[vmMaker generateMainVM]
		on: VMMakerException
		do: [:ex| self inform: ex messageText]]
]

{ #category : #'generate sources' }
VMMakerTool >> generateExternal [
	"tell the vmMaker to build all the externally linked plugin sources"
	self checkOK
		ifTrue: [[vmMaker generateExternalPlugins]
		on: VMMakerException
		do: [:ex | self inform: ex messageText]]
]

{ #category : #'generate sources' }
VMMakerTool >> generateSelectedExternalPlugin [

	| plugin |
	plugin := self externalModules at: self currentExternalModuleIndex ifAbsent: [^self].
	self checkOK
		ifTrue: [[vmMaker generateExternalPlugin: plugin]
		on: VMMakerException
		do: [:ex| self inform: ex messageText]]

]

{ #category : #'generate sources' }
VMMakerTool >> generateSelectedInternalPlugin [

	| plugin |
	plugin := self internalModules at: self currentInternalModuleIndex ifAbsent: [^self].
	self checkOK
		ifTrue: [[vmMaker generateInternalPlugin: plugin]
		on: VMMakerException
		do: [:ex| self inform: ex messageText]]

]

{ #category : #menus }
VMMakerTool >> helpText [
	(StringHolder new contents: self class comment)
		openLabel: 'VMMakerTool help'

]

{ #category : #initialisation }
VMMakerTool >> initialExtent [
 	^600@450
]

{ #category : #'list access' }
VMMakerTool >> initialModules [
	^vmMaker availableModules
]

{ #category : #initialisation }
VMMakerTool >> initialize [
	logger := TranscriptStream new.
	vmMaker _ VMMaker default.
	vmMaker logger: logger.
	vmMaker addDependent: self.
	allPluginsSelectionsArray _ Array new: self availableModules size withAll: false.
	internalPluginsSelectionsArray _ Array new.
	externalPluginsSelectionsArray _ Array new.
]

{ #category : #menus }
VMMakerTool >> internalListMenu: aMenu [

	aMenu addList:#(
			('make all external'						makeAllPluginsExternal)
			('make all internal'						makeAllPluginsInternal)
			('make all available'					makeAllPluginsAvailable)
			-
			('browse plugin' 						browseSelectedInternalPlugin)
			-
			('generate plugin'						generateSelectedInternalPlugin)).
	^ aMenu
]

{ #category : #'list access' }
VMMakerTool >> internalListSelectionAt: index [
"return the boolean to say if the internal plugin at index is selected"
	^internalPluginsSelectionsArray at: index
]

{ #category : #'list access' }
VMMakerTool >> internalListSelectionAt: index put: bool [
"set the boolean to say if the internal plugin at index is selected"
	^internalPluginsSelectionsArray at: index put: bool
]

{ #category : #'list access' }
VMMakerTool >> internalModules [
	^vmMaker internalModules
]

{ #category : #'path access' }
VMMakerTool >> interpreterClassName [
	"return a Text for the path to the generated sources"
	^[vmMaker interpreterClass name asString] 
		on: VMMakerException 
		do:[:ex| ex return:'<invalid class>'].
]

{ #category : #'path access' }
VMMakerTool >> interpreterClassName: aText [
	"set the interpreter class name"

	[vmMaker interpreterClassName: aText asString] 
		on: VMMakerException 
		do: [:ex| self inform:'problem with this class name; does this class exist?'. 
			^false].
	^true
]

{ #category : #'list access' }
VMMakerTool >> listForMorph: aMorph [
	"work out which list is the one associated with this morph"
	allPluginsList = aMorph ifTrue:[^allPluginsList getListSelector].
	internalPluginsList = aMorph ifTrue:[^internalPluginsList getListSelector].
	externalPluginsList =aMorph ifTrue:[^externalPluginsList getListSelector].
	^nil
]

{ #category : #'list access' }
VMMakerTool >> listMorphs [
	^Array with: allPluginsList with: internalPluginsList with: externalPluginsList
]

{ #category : #configurations }
VMMakerTool >> loadConfig [
	| fileResult file |
	fileResult _ (StandardFileMenu oldFileMenu: FileDirectory default withPattern: '*.config')
				startUpWithCaption: 'Select VMMaker configuration...'.
	fileResult
		ifNotNil: [file _ fileResult directory fullNameFor: fileResult name.
			[vmMaker _ VMMaker forConfigurationFile: file.
			vmMaker logger: logger.
			vmMaker platformDirectory]
				on: Error
				do: [self inform: 'Possible problem with path settings or platform name?'].
			self updateAllViews]
]

{ #category : #menus }
VMMakerTool >> makeAllPluginsAvailable [


	vmMaker makeAllModulesAvailable
]

{ #category : #menus }
VMMakerTool >> makeAllPluginsExternal [


	vmMaker makeAllModulesExternal
]

{ #category : #menus }
VMMakerTool >> makeAllPluginsInternal [


	vmMaker makeAllModulesInternal
]

{ #category : #'drag and drop' }
VMMakerTool >> moveItem: transferedMorph from: sourceListMorph to: destListMorph [ 
	"As part of a drag operation we have to move the item carried by the  
	transfer morph from a source list to a destination list"
	"work out which list is involved and add the item to it"
	| destlist srclist |

	"no need to do anything if we drop on the same place from which we dragged" 
	sourceListMorph = destListMorph
		ifTrue: [^ false].

	(destlist _ self listForMorph: destListMorph)
		ifNil: [^ false].
	(srclist _ self listForMorph: sourceListMorph)
		ifNil: [^ false].
	vmMaker
		movePlugin: transferedMorph contents
		from: srclist
		to: destlist.
	self changed: sourceListMorph getListSelector.
	self changed: destListMorph getListSelector.
	^ true
]

{ #category : #menus }
VMMakerTool >> perform: selector orSendTo: otherTarget [
	"Selector was just chosen from a menu by a user.  If can respond, then
perform it on myself. If not, send it to otherTarget, presumably the
editPane from which the menu was invoked."

	(self respondsTo: selector)
		ifTrue: [^ self perform: selector]
		ifFalse: [^ otherTarget perform: selector]
]

{ #category : #'path access' }
VMMakerTool >> platformNameText [
	"return a Text for the platform name"
	^vmMaker platformName asText
]

{ #category : #menus }
VMMakerTool >> platformNameText: aText [ 
	"set the platform name - this will almost certainly mean replacing the  
	vmMaker with one suited to the platform so we do it anyway."
	| prevVMMaker |
	prevVMMaker _ vmMaker.
	"make a new vmmaker and ensure I depend on it correctly"
	vmMaker _ VMMaker forPlatform: aText string.
	vmMaker logger: logger.
	vmMaker addDependent: self.
	prevVMMaker removeDependent: self.
	"configure the new vmmaker to match the old one"
	[vmMaker loadConfiguration: prevVMMaker configurationInfo.
	vmMaker platformDirectory]
		on: VMMakerException
		do: [self inform: 'Possible problem with path settings or platform name? Check path, permissions or spellings'.
			^ false].
	^ true
]

{ #category : #menus }
VMMakerTool >> platformsListMenu [
	"create a menu of all known platforms"
	|choice  platnames|
	platnames _ vmMaker platformRootDirectory directoryNames copyWithoutAll: #('Cross' 'CVS').
	choice  _ (PopUpMenu labelArray: platnames lines: #()) startUp.
	choice = 0 ifTrue:[^self].
	self platformNameText: (platnames at: choice) asText
]

{ #category : #'path access' }
VMMakerTool >> platformsPathText [
	"return a Text for the path to the platform sources"
	[^vmMaker platformRootDirectory fullName asText] on: VMMakerException do:[^'Problem with directory name for platform code: enter correct path or consult help text' asText]
]

{ #category : #'path access' }
VMMakerTool >> platformsPathText: aText [
	"set the path to the platform sources"
	[^vmMaker platformRootDirectoryName: aText asString] on: VMMakerException do:[:ex| self inform:'problem with this directory name; check the path settings, permissions or spelling?'. ex return: false]
]

{ #category : #configurations }
VMMakerTool >> saveConfig [

	"write info about the current configuration to a file."
	| fileResult file |
	fileResult := (StandardFileMenu newFileMenu: FileDirectory default withPattern: '*.config')
		startUpWithCaption: 'Save VMMaker configuration...'.
	fileResult ifNotNil: [
		('*.config' match: fileResult name)
			ifFalse: [fileResult name: (fileResult name, '.config')].
		file := fileResult directory fullNameFor: fileResult name.
		vmMaker saveConfigurationTo: file].

]

{ #category : #'path access' }
VMMakerTool >> sourcePathText [
	"return a Text for the path to the generated sources"
	^[vmMaker sourceDirectory fullName asText] 
		on: VMMakerException 
		do:[:ex| ex return:'<path not valid>'].
]

{ #category : #'path access' }
VMMakerTool >> sourcePathText: aText [
	"set the path to the generated sources"
	^vmMaker sourceDirectoryName: aText asString
]

{ #category : #initialisation }
VMMakerTool >> update: anObject [ 
	"some related object has changed. Try to handle it"
	anObject == #reinitialize ifTrue: [self updateAllViews]
]

{ #category : #initialisation }
VMMakerTool >> updateAllViews [
	self changed: #platformsPathText;
				 changed: #platformNameText;
				 changed: #sourcePathText;
				 changed: #availableModules;
				 changed: #internalModules;
				 changed: #externalModules
]

{ #category : #'drag and drop' }
VMMakerTool >> wantsDroppedMorph: transferMorph event: anEvent inMorph: destinationLM [ 
	"We are only interested in TransferMorphs as wrappers for             
	information. If their content is really interesting for us, will             
	determined later in >>acceptDroppingMorph:event:."

	"only want drops on the lists"
	^self listMorphs includes: destinationLM
]
