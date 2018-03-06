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
	#category : #'VMMaker-Building'
}

{ #category : #'instance creation' }
VMMakerTool class >> initialize [

	Smalltalk at: #TheWorldMenu ifPresent: [ :class |
		((class compiledMethodAt: #registerOpenCommand: ifAbsent: [^self]) sendsSelector: #deprecated:) 
			ifFalse: [class registerOpenCommand: (Array with: 'VMMaker' with: (Array with: self with: #openInWorld))]]
	
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

	^self moveItem: transferMorph passenger from: transferMorph source to: aMorph
]

{ #category : #'window construction' }
VMMakerTool >> addSecondButtonRowToWindow: sysWin startingAt: initialVerticalOffset [ 
	| verticalOffset box |
	verticalOffset := initialVerticalOffset.
	"add a row of buttons to start up various actions"
	box := AlignmentMorph new vResizing: #shrinkWrap;  layoutInset: 6@3; cellInset: 6@0; wrapCentering: #center.
	box addMorph: (TextMorph new contents: 'Generate:' translated asText allBold) lock.
	box addMorphBack: (SimpleButtonMorph new target: self;
			 label: 'Entire';
			 actionSelector: #generateAll;
			 hResizing: #spaceFill;
			 setBalloonText: 'Generate the sources for the core VM and all chosen internal and external plugins').
	box addMorphBack: (SimpleButtonMorph new target: self;
			 label: 'Core+Internal';
			 actionSelector: #generateCore;
			 hResizing: #spaceFill;
			 setBalloonText: 'Generate the sources for the core vm and any internal plugins').

	box addMorphBack: (SimpleButtonMorph new target: self;
			 label: 'External Plugins';
			 actionSelector: #generateExternal;
			 hResizing: #spaceFill;
			 setBalloonText: 'Generate the sources for all external plugins').
	box addMorphBack: ((AlignmentMorph inARow: {StringMorph new contents: '64 bit VM?'. UpdatingThreePhaseButtonMorph checkBox target: self;
				 actionSelector: #toggle64BitVM;
				 getSelector: #isFor64BitVM}) layoutInset: 3;
			 cellInset: 5;
			 color: Color blue veryMuchLighter;
			 setBalloonText: 'Set to build a 64 bit VM or a 32bit VM' yourself).
	sysWin
		addMorph: box
		fullFrame: (LayoutFrame
				fractions: (0 @ 0 corner: 1 @ 0)
				offsets: (0 @ verticalOffset corner: 0 @ (verticalOffset := verticalOffset + box height - 1))).

	^verticalOffset.
]

{ #category : #'window construction' }
VMMakerTool >> addTopButtonRowToWindow: sysWin [
	| verticalOffset box |
	verticalOffset := 0.

	"add a row of buttons to start up various actions"
	box := AlignmentMorph new vResizing: #shrinkWrap;
				 layoutInset: 6 @ 3;
				 cellInset: 6 @ 0;
				 wrapCentering: #center.
	box addMorphBack: (SimpleButtonMorph new target: self;
			 label: 'Help';
			 actionSelector: #helpText;
			 hResizing: #spaceFill;
			 setBalloonText: 'Open the help window').
	box addMorphBack: (TextMorph new contents: 'Configuration File:' translated asText allBold) lock.	
	box addMorphBack: (SimpleButtonMorph new target: self;
			 label: 'Load';
			 actionSelector: #loadConfig;
			 hResizing: #spaceFill;
			 setBalloonText: 'Load a previously saved configuration').
	box addMorphBack: (SimpleButtonMorph new target: self;
			 label: 'Save';
			 actionSelector: #saveConfig;
			 hResizing: #spaceFill;
			 setBalloonText: 'Save the current configuration').
	sysWin
		addMorph: box
		fullFrame: (LayoutFrame
				fractions: (0 @ 0 corner: 1 @ 0)
				offsets: (0 @ verticalOffset corner: 0 @ (verticalOffset := verticalOffset + box height - 1))).
	^ verticalOffset
]

{ #category : #menus }
VMMakerTool >> availableListMenu: aMenu [

	aMenu addTranslatedList: #(
			('make all external'						makeAllPluginsExternal)
			('make all internal'						makeAllPluginsInternal)
			('make all available'					makeAllPluginsAvailable)
			-
			('browse plugin' 						browseSelectedAvailablePlugin)
			('refresh list' 							refreshAvailablePluginsList)).
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

{ #category : #'window construction' }
VMMakerTool >> buildCenterRows [
	| rows color1 color2 |
	color1 := Color blue veryMuchLighter.
	color2 := Color green veryMuchLighter.
	rows := Morph new color: Color transparent;
				layoutPolicy: TableLayout new;
				vResizing: #spaceFill;
				extent: 550 @ (TextStyle defaultFont height * 14);
				hResizing: #spaceFill;
				listDirection: #topToBottom;
				borderStyle: (BorderStyle complexAltRaised width: 2);
				wrapDirection: #none;
				wrapCentering: #center;
				yourself.
	rows
		addMorphBack: ((self
				entryRowWithLabel: 'Interpreter class name:'
				balloonText: 'The name of the Interpreter class'
				getFieldText: #interpreterClassName
				setFieldText: #interpreterClassName:
				buttonLabel: nil
				buttonAction: nil
				buttonBalloonText: nil)
				color: color1).
	interpreterClassMorph := rows submorphs last submorphs first.

	rows
		addMorphBack: ((self
				entryRowWithLabel: 'Path to platforms code:'
				balloonText: 'The directory where the platform source tree is found; can be edited in text field to the right. Default of {working directory}/src is strongly recommended'
				getFieldText: #platformsPathText
				setFieldText: #platformsPathText:
				buttonLabel: 'Find Path'
				buttonAction: #findPlatformsPath
				buttonBalloonText: 'Choose the directory where you keep the platform specific code from a file dialogue')
				color: color2).
	platformPathMorph := rows submorphs last submorphs second.

	rows
		addMorphBack: ((self
				entryRowWithLabel: 'Platform name:'
				balloonText: 'The platform name (as returned by Smalltalk platformName - unix, Mac OS, RISCOS, win32 etc); can be edited (in text field to the right) to cross generate'
				getFieldText: #platformNameText
				setFieldText: #platformNameText:
				buttonLabel: 'Find platform'
				buttonAction: #platformsListMenu
				buttonBalloonText: 'Choose from a list of known platforms. The default is this current platform.')
				color: color1).
	platformNameMorph := rows submorphs last submorphs second.

	rows
		addMorphBack: ((self
				entryRowWithLabel: 'Path to generated sources'
				balloonText: 'The directory where the built sources will be placed; can be edited in text field to the right. The default is strongly recommended; makefile alterations may be needed if you use a different path.'
				getFieldText: #sourcePathText
				setFieldText: #sourcePathText:
				buttonLabel: 'Clean out'
				buttonAction: #cleanoutSrcDir
				buttonBalloonText: 'Clean out all the files in the target directory, ready for a clean build')
				color: color2).
	generatedPathMorph := rows submorphs last submorphs second.

	^ rows
]

{ #category : #'window construction' }
VMMakerTool >> buildWindow [
	"VMMakerTool openInWorld"
	| sysWin box verticalOffset |
	sysWin := (SystemWindow labelled: 'VMMaker')
				model: self.
	verticalOffset := self addTopButtonRowToWindow: sysWin.
	verticalOffset := self addSecondButtonRowToWindow: sysWin startingAt: verticalOffset.
	box := self buildCenterRows.
	sysWin
		addMorph: box
		fullFrame: (LayoutFrame
				fractions: (0 @ 0 corner: 1 @ 0)
				offsets: (0 @ verticalOffset corner: 0 @ (verticalOffset := verticalOffset + box height - 1))).
	"Add the list of plugins that are available to build"
	allPluginsList := (PluggableListMorph
				on: self
				list: #availableModules
				selected: #currentAvailableModuleIndex
				changeSelected: #currentAvailableModuleIndex:
				menu: #availableListMenu:
				keystroke: nil) enableDragNDrop.
	allPluginsList hResizing: #spaceFill;
		 vResizing: #spaceFill;
		 borderWidth: 0.
	box := AlignmentMorph newColumn.
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
	internalPluginsList := (PluggableListMorph
				on: self
				list: #internalModules
				selected: #currentInternalModuleIndex
				changeSelected: #currentInternalModuleIndex:
				menu: #internalListMenu:
				keystroke: nil) enableDragNDrop.
	internalPluginsList hResizing: #spaceFill;
		 vResizing: #spaceFill;
		 borderWidth: 0.
	box := AlignmentMorph newColumn.
	box addMorphBack: (TextMorph new contents: 'Internal Plugins' asText allBold;
			 lock);
		 setBalloonText: 'List of plugins chosen to be built internally'.
	box addMorphBack: internalPluginsList.
	sysWin
		addMorph: box
		fullFrame: (LayoutFrame
				fractions: (1 / 3 @ 0 corner: 2 / 3 @ 1)
				offsets: (0 @ verticalOffset corner: 0 @ -100)).
	"make the list for plugins to be built externally (ie as DLLs, SO
	or 
	whatever suits the platform"
	externalPluginsList := (PluggableListMorph
				on: self
				list: #externalModules
				selected: #currentExternalModuleIndex
				changeSelected: #currentExternalModuleIndex:
				menu: #externalListMenu:
				keystroke: nil) enableDragNDrop.
	externalPluginsList hResizing: #spaceFill;
		 vResizing: #spaceFill;
		 borderWidth: 0.
	box := AlignmentMorph newColumn.
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
		addMorph: (PluggableTextMorph
				on: logger
				text: nil
				accept: nil
				readSelection: nil
				menu: nil)
		fullFrame: (LayoutFrame
				fractions: (0 @ 1 corner: 1 @ 1)
				offsets: (0 @ -100 corner: 0 @ 0)).
	^ sysWin
]

{ #category : #settings }
VMMakerTool >> checkOK [
	"check as many settings as we can and report true if all seems ok"
	(interpreterClassMorph accept; hasUnacceptedEdits) ifTrue:[^false].
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
	allPluginsSelection := anInteger.
	self changed: #currentAvailableModuleIndex
]

{ #category : #'list access' }
VMMakerTool >> currentExternalModuleIndex [
	externalPluginsSelection ifNil:[^0].
	^externalPluginsSelection
]

{ #category : #'list access' }
VMMakerTool >> currentExternalModuleIndex: anInteger [
	externalPluginsSelection := anInteger.
	self changed: #currentExternalModuleIndex
]

{ #category : #'list access' }
VMMakerTool >> currentInternalModuleIndex [
	internalPluginsSelection ifNil:[^0].
	^internalPluginsSelection
]

{ #category : #'list access' }
VMMakerTool >> currentInternalModuleIndex: anInteger [
	internalPluginsSelection := anInteger.
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

{ #category : #'window construction' }
VMMakerTool >> entryRowWithLabel: label balloonText: balloonText getFieldText: getTextSelector setFieldText: setTextSelector buttonLabel: buttonLabel buttonAction: buttonAction buttonBalloonText: buttonBalloonText [ 
	| row lWidth |
	lWidth := TextStyle defaultFont pixelSize * 11.
	row := Morph new color: Color transparent;
				 hResizing: #spaceFill;
				 vResizing: #spaceFill;
				 extent: 550 @ 40;
				 layoutPolicy: ProportionalLayout new;
				 borderWidth: 2;
				 setBalloonText: balloonText translated;
				 yourself.
	row
		addMorph: (TextMorph new contents: label translated asText allBold) lock
		fullFrame: (LayoutFrame
				fractions: (0 @ 0 corner: 0 @ 1)
				offsets: (3 @ 3 corner: lWidth @ -3)).
	row
		addMorph: ((PluggableTextMorph
				on: self
				text: getTextSelector
				accept: setTextSelector) vScrollBarPolicy: #never;
				 acceptOnCR: true)
		fullFrame: (LayoutFrame
				fractions: (0 @ 0 corner: 1 @ 1)
				offsets: (lWidth + 10 @ 0 corner: (lWidth / 1.8 + 10) negated @ 0)).
	buttonAction
		ifNotNil: [row
				addMorph: (SimpleButtonMorph new target: self;
						 label: buttonLabel translated;
						 actionSelector: buttonAction;
						 hResizing: #spaceFill;
						 setBalloonText: buttonBalloonText translated)
				fullFrame: (LayoutFrame
						fractions: (1 @ 0 corner: 1 @ 1)
						offsets: ((lWidth / 1.8 + 5) negated @ 3 corner: -5 @ -3))].
	^ row
]

{ #category : #menus }
VMMakerTool >> externalListMenu: aMenu [

	aMenu addTranslatedList:#(
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
	dir := FileList2 modalFolderSelector.
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

	| pluginName |
	pluginName := self externalModules
						at: self currentExternalModuleIndex
						ifAbsent: [^self inform: 'no such plugin'].
	vmMaker interpreterClass
		ifNil: [^self inform: 'please set an interpreter class']
		ifNotNil: [:interpreterClass| interpreterClass initialize].
	self checkOK ifTrue:
		[[(Smalltalk classNamed: pluginName) touch.
		  vmMaker generateExternalPlugin: pluginName; logDateAndTime]
			on: VMMakerException
			do: [:ex| self inform: ex messageText]]
]

{ #category : #'generate sources' }
VMMakerTool >> generateSelectedInternalPlugin [

	| pluginName |
	pluginName := self internalModules
						at: self currentInternalModuleIndex
						ifAbsent: [^self inform: 'no such plugin'].
	vmMaker interpreterClass
		ifNil: [^self inform: 'please set an interpreter class']
		ifNotNil: [:interpreterClass| interpreterClass initialize].
	self checkOK ifTrue:
		[[(Smalltalk classNamed: pluginName) touch.
		  vmMaker generateInternalPlugin: pluginName]
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
	vmMaker := VMMaker default.
	vmMaker logger: logger.
	vmMaker addDependent: self.
	allPluginsSelectionsArray := Array new: self availableModules size withAll: false.
	internalPluginsSelectionsArray := Array new.
	externalPluginsSelectionsArray := Array new.
]

{ #category : #menus }
VMMakerTool >> internalListMenu: aMenu [

	aMenu addTranslatedList:#(
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

{ #category : #'generate sources' }
VMMakerTool >> isFor64BitVM [
"do I build a 64bit VM or not?"
	^vmMaker isFor64BitVM
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
	fileResult := (StandardFileMenu oldFileMenu: FileDirectory default withPattern: '*.config')
				startUpWithCaption: 'Select VMMaker configuration...'.
	fileResult
		ifNotNil: [file := fileResult directory fullNameFor: fileResult name.
			[vmMaker := VMMaker forConfigurationFile: file.
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

	(destlist := self listForMorph: destListMorph)
		ifNil: [^ false].
	(srclist := self listForMorph: sourceListMorph)
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
	| prevVMMaker newVMMaker |
	prevVMMaker := vmMaker.
	"make a new vmmaker and ensure I depend on it correctly"
	newVMMaker := VMMaker forPlatform: aText string.
	newVMMaker logger: logger.
	"configure the new vmmaker to match the old one"
	[newVMMaker loadConfiguration: prevVMMaker configurationInfo.
	 newVMMaker platformDirectory]
		on: VMMakerException
		do: [self inform: 'Possible problem with path settings or platform name? Check path, permissions or spellings'.
			^false].
	newVMMaker addDependent: self.
	prevVMMaker removeDependent: self.
	vmMaker := newVMMaker.
	^true
]

{ #category : #menus }
VMMakerTool >> platformsListMenu [
	"create a menu of all known platforms"

	| choice platnames |
	platnames := vmMaker platformRootDirectory directoryNames reject:
					[:dirName|
					dirName first = $. ".svn .git et al"
					or: [dirName ='CVS']].
	choice := (PopUpMenu labelArray: platnames lines: #()) startUp.
	choice ~= 0 ifTrue:
		[self platformNameText: (platnames at: choice) asText]
]

{ #category : #'path access' }
VMMakerTool >> platformsPathText [
	"return a Text for the path to the platform sources"
	^(vmMaker platformRootDirectoryName ifNil: ['']),
	  ([vmMaker platformRootDirectory. ''] 
		on: VMMakerException 
		do:[:ex| ex return: '<path not valid>']) asText
]

{ #category : #'path access' }
VMMakerTool >> platformsPathText: aText [
	"set the path to the platform sources"
	[^vmMaker platformRootDirectoryName: aText asString] on: VMMakerException do:[:ex| self inform:'problem with this directory name; check the path settings, permissions or spelling?'. ex return: false]
]

{ #category : #menus }
VMMakerTool >> refreshAvailablePluginsList [
	vmMaker recomputeProvidedPlugins.
	self changed: #availableModules
]

{ #category : #menus }
VMMakerTool >> release [
	vmMaker ifNotNil: [ vmMaker removeDependent: self ].
	super release.
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

{ #category : #'generate sources' }
VMMakerTool >> set64BitVM: boolean [
"do I build a 64bit VM or not?"
	boolean ifTrue:[vmMaker for64BitVM] ifFalse:[vmMaker for32BitVM].
	self changed: #sourcePathText
]

{ #category : #'path access' }
VMMakerTool >> sourcePathText [
	"return a Text for the path to the generated sources"
	^(vmMaker sourceDirectoryName ifNil: ['']),
	  ([vmMaker sourceDirectory. ''] 
		on: VMMakerException 
		do:[:ex| ex return: '<path not valid>']) asText
]

{ #category : #'path access' }
VMMakerTool >> sourcePathText: aText [
	"set the path to the generated sources"
	^vmMaker sourceDirectoryName: aText asString
]

{ #category : #settings }
VMMakerTool >> toggle64BitVM [
	self set64BitVM: self isFor64BitVM not
]

{ #category : #initialisation }
VMMakerTool >> update: anObject [ 
	"some related object has changed. Try to handle it"
	anObject == #reinitialize ifTrue: [self updateAllViews]
]

{ #category : #initialisation }
VMMakerTool >> updateAllViews [
	self changed: #interpreterClassName;
		changed: #platformsPathText;
		changed: #platformsPathText;
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

	(transferMorph isKindOf: HandleMorph) ifTrue: [ ^false ].

	(transferMorph isKindOf: TransferMorph) ifFalse: [ ^false ].

	transferMorph source model = self ifFalse:[^false].

	^self listMorphs includes: destinationLM
]
