| manifest load |
manifest := #(	('http://source.squeak.org/FFI'					1	('FFI-Pools' 'FFI-Kernel'))
				('http://source.squeak.org/VMMaker'				6	('Balloon-Engine-Pools' 'BytecodeSets.spur' 'VMMaker.oscog' 'Cog' 'CogTools' 'ImageFormat'))
				('http://ss3.gemstone.com/ss/MethodMassage'		3	('MethodMassage' 'MethodMassageCompatibility'))
				('http://www.squeaksource.com/AioPlugin'		7	('VMConstruction-Plugins-AioPlugin'))
				('http://www.squeaksource.com/Alien'			0	('Alien-Core' 'Alien-Tests-Core' 'Alien-Win32'))
				"('http://www.squeaksource.com/FreeTypePlus'	5	('FreeType')) can't load this.  it is toxic to Squeak 4.5"
				('http://www.squeaksource.com/FreetypePlugin'	8	('Freetype-Plugin'))
				('http://www.squeaksource.com/OSProcess'		4	('OSProcess'))
				('http://www.squeaksource.com/OSProcessPlugin'	9	('VMConstruction-Plugins-OSProcessPlugin.oscog'))
				('http://www.squeaksource.com/rb'				5	('AST-Core' 'AST-Semantic' 'AST-Tests-Core' 'AST-Tests-Semantic' 'Refactoring-Changes' 'Refactoring-Core' 'Refactoring-Environment' 'Refactoring-Tests-Changes' 'Refactoring-Tests-Core' 'Refactoring-Tests-Environment' 'Refactoring-Squeak-Platform'))
				"This for the Klatt speech synthesiser, but seems to be AWOL"
				('http://www.squeaksource.com/Speech'			2	('SharedPool-Speech' ))
				('http://www.squeaksource.com/XDCP'				9	('VMConstruction-Plugins-XDisplayControlPlugin' ))
				('http://www.squeaksource.com/Balloon3D'		9	('Balloon3D-Constants' 'Balloon3D-Plugins'  ))
				('http://www.squeaksource.com/Cryptography'		9	('CryptographyPlugins'  ))
				('http://smalltalkhub.com/mc/Alistair/FileAttributesPlugin/main'		9	('FileAttributesPlugin.oscog'  ))
				('http://ss3.gemstone.com/ss/AndreasSystemProfiler'	9	('AndreasProfiler'))
				('http://www.squeaksource.com/Printf'			5	('Printf'))
				).

load := (manifest collect:
				[:tuple|
				[:path :order :packages| | repository |
				repository := MCHttpRepository
								location: path
								user: 'squeak'
								password: 'squeak'.
				MCRepositoryGroup default addRepository: repository.
				{repository. order. packages}] valueWithArguments: tuple])
			sort: [:a :b| a second <= b second].

#(	"'FT2Constants.st'"
	'Object-performwithwithwithwithwith.st' ) do:
	[:fileName| (FileDirectory default fileNamed: fileName) fileIn].

load do:
	[:tuple|
	 [:repository :order :packages|
	  packages do:
		[:package | | packageVersions latestVersion |
		"We need to filter-out branches of unbranched packages, but can't assume
		the package list is (reverse) ordered."
		packageVersions := ((repository versionNamesForPackageNamed: package)
			select: [:versionName| (versionName at: package size + 1) = $-])
			asSortedCollection: [ :a :b | a versionNumber < b versionNumber ].
		latestVersion := packageVersions last.
		[| version |
		version := ((MCCacheRepository default includesVersionNamed: latestVersion)
					ifTrue: [MCCacheRepository default]
					ifFalse: [repository]) versionNamed: latestVersion.
		 version load.
		 version workingCopy repositoryGroup addRepository: repository]
			on: Warning
			do: [:ex|
				((ex messageText beginsWith: 'This package depends on the following classes')
				 or: [ex messageText beginsWith: 'About to serialize an empty diffy version.']) ifFalse:
					[ex pass].
				ex resume]]]
		valueWithArguments: tuple].

World findATranscript: nil.

UIManager default
	edit: (FileDirectory default fileNamed: 'Workspace.text') contentsOfEntireFile
	label: 'Overview'.


#('VM Simulation' 'Source Generation' 'Slang Test' 'In-image Compilation') reverseDo:
	[:nickname| | label workspace |
	label := nickname, ' Workspace'.
	workspace := (UIManager default
					edit: (FileDirectory default fileNamed: label, '.text') contentsOfEntireFile
					label: label) model.
	workspace shouldStyle ifFalse:
		[workspace toggleStyling]].

(Utilities classPool at: #CommonRequestStrings) ifNotNil:
	[:crs|
	crs contents: crs contents, '\-\VMMaker generateConfiguration\VMMaker generateAllConfigurationsUnderVersionControl\VMClass openCogMultiWindowBrowser\VMClass openObjectMemoriesInterpretersBrowser\VMClass openSpurMultiWindowBrowser' withCRs].

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
