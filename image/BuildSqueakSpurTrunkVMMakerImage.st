| manifest load repositories |

"Update Trunk image"
[MCMcmUpdater default doUpdate: false] on: Warning do: [:ex | ex resume: true].

"Disable underscore as assignment, allowing underscores in method names."
Scanner allowUnderscoreAsAssignment: false.
TranscriptStream characterLimit: 1000000.

manifest := #(	
	squeak	'FFI'
		0	('FFI-Pools' 'FFI-Kernel') (ffiInbox)
	squeak	'FFI' "Split up because of how extension methods are loaded"
		1	('FFI-Libraries' 'FFI-Tools' 'FFI-Callbacks'
			'FFI-Tests' 'FFI-PoolsTests' 'FFI-CallbacksTests') (ffiInbox)
	squeak	'VMMaker'
		6	('CogPools-ISAs' 'BytecodeSets.spur' 'VMMaker.oscog' 'VMMakerUI'
			'Cog' 'CogTools' 'ImageFormat' 'FileAttributesPlugin.oscog') (vmMakerInbox)
	squeaksource		'AioPlugin'
		7	('VMConstruction-Plugins-AioPlugin.oscog') (vmMakerInbox)
	squeaksource		'Alien'			
		0	('Alien-Core' 'Alien-Tests-Core' 'Alien-Win32') (vmMakerInbox)
	squeaksource	'FreeType'
		5	('FreeTypeConstants' "'FreeType'") nil
	squeaksource		'FreetypePlugin'
		8	('Freetype-Plugin') nil
	squeaksource		'OSProcess'
		4	('OSProcess') (inbox)
	squeaksource		'OSProcessPlugin'
		9	('VMConstruction-Plugins-OSProcessPlugin.oscog') (vmMakerInbox)
	squeaksource		'rb'
		5	('AST-Core' 'AST-Semantic' 'AST-Tests-Core' 'AST-Tests-Semantic'
			'Refactoring-Changes' 'Refactoring-Core' 'Refactoring-Environment'
			'Refactoring-Tests-Changes' 'Refactoring-Tests-Core'
			'Refactoring-Tests-Environment' 'Refactoring-Squeak-Platform'
			'Refactoring-Critics' 'Refactoring-Spelling') (inbox)
	squeaksource		'Speech' "This for the Klatt speech synthesiser, but seems to be AWOL"
		2	('SharedPool-Speech' ) (inbox)
	squeaksource		'XDCP'
		9	('VMConstruction-Plugins-XDisplayControlPlugin.oscog' ) (vmMakerInbox)
	squeaksource		'Balloon3D'
		9	('Balloon3D-Constants' 'Balloon3D-Plugins'  ) (vmMakerInbox)
	squeaksource		'Cryptography'
		9	('CryptographyPlugins'  ) (vmMakerInbox)
	squeaksource		'NumberPrinter'
		5	('NumberPrinter') (vmMakerInbox)
	squeaksource		'Printf'
		5	('Printf') (vmMakerInbox)
	squeaksource		'VectorEnginePlugin'
		9	('VectorEnginePlugin') (vmMakerInbox)
	squeaksource		'dbus'
		9	('DBus-Plugin') (vmMakerInbox)
	squeaksource		'Rome'
		9	('Rome-Base' 'Rome-PluginCanvas' 'Rome-Plugin') (vmMakerInbox)
	squeaksource		'GStreamer'
		9	('GStreamer-Plugins') (vmMakerInbox)
	).
"AndreasSystemProfiler and AssemblerMethod are now in trunk now in trunk"
#(AndreasSystemProfiler AssemblerMethod)
	with: #((squeak	'VMMaker' 9	('AndreasProfiler') nil)
			 (squeak	'VMMaker'	3	('MethodMassage') nil))
	do: [:className :addition|
		(Smalltalk classNamed: className) ifNil:
			[manifest := manifest, addition]].

repositories := Dictionary new.
load := Array streamContents: [:s |
	manifest groupsDo: [:installerSymbol :project :order :packages :inboxNames |
		| installer |
		installer := Installer perform: installerSymbol.
		installer project: project.
		installer packages addAll: packages.
		s nextPut: order -> installer.
		(inboxNames ifNil: [#(vmMakerInbox)]) do: [:inboxName |
			(repositories at: inboxName ifAbsentPut: [OrderedCollection new]) addAll: packages]]].
load := (load sorted: [:a :b | a key <= b key]) collect: [:ea | ea value].
load do: [:installer | installer installQuietly].
repositories keysAndValuesDo: [:inboxName :packages |
	| inbox |
	inbox := MCRepository perform: inboxName.
	MCRepositoryGroup default addRepository: inbox.
	packages do: [:package |
		| packageName |
		packageName := package readStream upTo: $.. "strip away branch name, if any"
		(MCWorkingCopy forPackageNamed: packageName) repositoryGroup addRepository: inbox]].

self currentWorld findATranscript: nil.

Project uiManager
	edit: (FileDirectory default fileNamed: 'Workspace.text') contentsOfEntireFile
	label: 'Overview'
	shouldStyle: false.

#('VM Simulation' 'Source Generation' 'Slang Test' 'In-image Compilation')
	reverseDo: [:nickname| | label |
	label := nickname, ' Workspace'.
	Project uiManager
		edit: (FileDirectory default fileNamed: label, '.text') contentsOfEntireFile
		label: label
		shouldStyle: true].

Utilities appendToCommonRequests: '-\VMMaker generateConfiguration\VMMaker generateAllConfigurationsUnderVersionControl\VMClass openCogMultiWindowBrowser\VMClass openObjectMemoriesInterpretersBrowser\VMClass openSpurMultiWindowBrowser' withCRs.

CodeHolder useMultiWindowBrowsers: true.

#('Cog' 'CogTools' 'VMMaker') do:
	[:pkg|
	(PackageInfo named: pkg) classes do:
		[:c|
		c organization sortCategories.
		c class organization sortCategories]].

(Smalltalk classNamed: #StackInterpreter) withAllSubclasses do:
	[:sic| sic reorganizeAsISeeFit].

Smalltalk snapshot: true andQuit: true
