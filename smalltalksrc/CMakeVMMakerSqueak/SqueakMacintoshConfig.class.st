"
A SqueakMacintoshConfig is a top level configuration for Mac configuratons.
My immediate sub-classes are Abstract Base classes for specific Mac variants.
The sub-classes of my Abstract Base Classes are concrete configurations of the form
[Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf
I am not meant to be built.

HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp
"
Class {
	#name : #SqueakMacintoshConfig,
	#superclass : #CPlatformConfigForSqueak,
	#instVars : [
		'resourcesDir'
	],
	#category : #CMakeVMMakerSqueak
}

{ #category : #cmake }
SqueakMacintoshConfig >> addFrameworksByTemplate: aCollection maker: aMaker [
	"for mac only "
	self flag:'tty'. "TODO: replace the CMakeCommand with CMakeFindLibrary. cmake --help-command find_library"
	aCollection
		do: [:each | 
			aMaker templates
				addLast:((CMakeCommand new) command: 'find_library' params:each , '_FMWK ', each );
				addLast:((CMakeListAppend new) list:'LINKLIBS' elements: (OrderedCollection with: '${', each , '_FMWK}'))]
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> addVMPluginsBuild: aMaker [
	"do nothing. "
]

{ #category : #cmake }
SqueakMacintoshConfig >> cmakeWriteDirectoriesDotCmake: aMaker [
	|temp o|
	"We could put these inline, but other components include the directories.cmake file. So, we continue that convention"
	o := String new writeStream.
	temp := OrderedCollection new.
	temp
		addLast: ((CMakeSet new) variable: 'topDir' quotedValue: (self topDir fullName));
		addLast: ((CMakeSet new) variable: 'buildDir' quotedValue: (self buildDir ifNil: ['${topDir}/build'] ifNotNil: [self buildDir fullName]));
		addLast: ((CMakeSet new) variable: 'thirdpartyDir' quotedValue: '${buildDir}/thirdParty');
		addLast: ((CMakeSet new) variable: 'platformsDir' quotedValue: (self platformsDir));
		addLast: ((CMakeSet new) variable: 'srcDir' quotedValue: (self dirSource pathName));    "where the vm source directory lives"
		addLast: ((CMakeSet new) variable: 'cogDir' quotedValue: (self cogDir pathName));        "oscogvm/src  for historical reasons" 
		addLast: ((CMakeSet new) variable: 'srcPluginsDir' quotedValue: (pluginsDir ifNil: [ '${cogDir}/plugins' ]));  "plugin source directory only in oscogvm/src/plugins"
		addLast: ((CMakeSet new) variable: 'srcVMDir' quotedValue: '${srcDir}/vm');
		addLast: ((CMakeSet new) variable: 'platformName' quotedValue: (self platformName));
		addLast: ((CMakeSet new) variable: 'targetPlatform' quotedValue: '${platformsDir}/${platformName}');
		addLast: ((CMakeSet new) variable: 'crossDir' quotedValue: '${platformsDir}/Cross');
		addLast: ((CMakeSet new) variable: 'platformVMDir' quotedValue: '${targetPlatform}/vm}');
		addLast: ((CMakeSet new) variable: 'outputDir' quotedValue: (self outputDir fullName));
		addLast: ((CMakeSet new) variable: 'externalModulesDir' quotedValue: (self externalModulesDir)).
	temp do: [:each |  o nextPutAll: (each content); cr].
	self write: (o contents) toFile: 'directories.cmake'.
	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast:((CMakeMessage new) message: (self class name), ' setDirectories: aMaker' )
	].
	templates addLast: ((CMakeInclude new) file: 'directories.cmake').


]

{ #category : #compiling }
SqueakMacintoshConfig >> compilerDefinitions [
	self deprecated: 'Legacy method from pharo approach. We need different definitions for each buildType'.

	self flag:'tty'. "cut-n-paste from representative pharo macOS configs"
	^ { 
		'-DCOGMTVM=0'. 
		'-DUSE_GLOBAL_STRUCT=0'. 
		'-DTARGET_API_MAC_CARBON'. 
		'-DBUILD_FOR_OSX'. 
		'-DHAVE_SYS_TIME_H'}	

]

{ #category : #compiling }
SqueakMacintoshConfig >> compilerFlags [
	"Macintosh Common compiler flags"
	self flag:'tty'. "cut-n-paste from representative pharo macOS configs"
	^ { 
		'-fmessage-length=0'. 
		'-Wno-trigraphs'. 
		'-fpascal-strings'. 
		'-fasm-blocks'. 
		'-mmacosx-version-min=10.5' }	

]

{ #category : #'plugin extra rules' }
SqueakMacintoshConfig >> configureByTemplateB3DAcceleratorPlugin: aMaker [
	self flag:'tty'.  "check portability issue"
	super configureByTemplateB3DAcceleratorPlugin: aMaker.  
	aMaker templates 
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with:  '/usr/X11/include'));  "<--not portable. for GL.h"
		addLast:((CMakeListAppend new) 
				list:'sources' 
				elements: (OrderedCollection 
					with: '${pluginPlatform}/sqMacOpenGL.c'
					with: '${pluginPlatform}/sqMacOpenGLInfo.c'))


]

{ #category : #'plugin extra rules' }
SqueakMacintoshConfig >> configureByTemplateClipboardExtendedPlugin: aMaker [
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqMacExtendedClipboard.c'))
	

	
]

{ #category : #'plugin extra rules' }
SqueakMacintoshConfig >> configureByTemplateCroquetPlugin: aMaker [ 
	super configureByTemplateCroquetPlugin: aMaker.  
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqMacCroquet.c'))



]

{ #category : #'plugin extra rules' }
SqueakMacintoshConfig >> configureByTemplateFFIPlugin: aMaker [
	super configureByTemplateFFIPlugin: aMaker.
	aMaker templates 
		addLast:((CMakeListAppend new) 
			list:'sources' 
			elements: (OrderedCollection 
				with: '${pluginPlatform}/x86-sysv-MacIntel.c'
				with: '${pluginPlatform}/x86-sysv-asm-MacIntel.S')).

]

{ #category : #'plugin extra rules' }
SqueakMacintoshConfig >> configureByTemplateFT2Plugin: aMaker [
	| lib |
	self flag:'tty'. "is internalFT2 still not supported?"
	aMaker isExternal ifFalse: [self error: 'building internal FT2Plugin is not supported yet' ]. 	
	self flag:'tty'. "I haven't been down the addThirdpartyLibrary rabbit hole yet"
	lib := self addThirdpartyLibrary: 'freetype2'.
	aMaker templates   	"link plugin with freetype lib"
		addLast:((CMakeListAppend new) list:'LINKLIBS' elements: (OrderedCollection with:  (lib targetForLinking)));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: lib includeDir)).


]

{ #category : #'plugin extra rules' }
SqueakMacintoshConfig >> configureByTemplateInternetConfigPlugin: aMaker [
	self flag:'tty'. "pharo's configureInternetConfigPlugin has a super call to an empty method that I omit here. "
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqMacInternetConfiguration.c')).



]

{ #category : #'plugin extra rules' }
SqueakMacintoshConfig >> configureByTemplateJoystickTabletPlugin: aMaker [ 
	self flag:'tty'. "pharo's configureJoystickTabletPlugin has a super call to an empty method that I omit here. "
	aMaker templates 
		addLast:((CMakeListAppend new) 
			list:'sources' 
			elements: (OrderedCollection 
					with: '${pluginPlatform}/HID_Error_Handler.c'
					with: '${pluginPlatform}/HID_Name_Lookup.c'
					with: '${pluginPlatform}/HID_Queue_Utilities.c'
					with: '${pluginPlatform}/HID_Utilities.c'
					with: '${pluginPlatform}/sqMacJoystickAndTablet.c')).


]

{ #category : #'plugin extra rules' }
SqueakMacintoshConfig >> configureByTemplateLocalePlugin: aMaker [ 
	self flag:'tty'. "pharo's configureLocalePlugin: has a super call to an empty method that I omit here. "
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqMacLocaleCarbon.c'))



]

{ #category : #'plugin extra rules' }
SqueakMacintoshConfig >> configureByTemplateMIDIPlugin: aMaker [ 
	self flag:'tty'. "pharo's configureMIDIPlugin: has a super call to an empty method that I omit here. "
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqMacMIDI.c')).

]

{ #category : #'plugin extra rules' }
SqueakMacintoshConfig >> configureByTemplateMpeg3Plugin: aMaker [

	super configureByTemplateMpeg3Plugin: aMaker.
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqMacFileBits.c'))

	

]

{ #category : #'plugin extra rules' }
SqueakMacintoshConfig >> configureByTemplateObjectiveCPlugin: aMaker [
	aMaker doNotGenerate: true

	

]

{ #category : #'plugin extra rules' }
SqueakMacintoshConfig >> configureByTemplateQuicktimePlugin: aMaker [
	aMaker templates 
		addLast: ((CMakeIncludeDirectories new)  
			dirs: (OrderedCollection 	
					 with: '${pluginPlatform}'
					 with: '${crossDir}/plugins/SurfacePlugin'));
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqMacQuicktimeInteface.c')). 
           " not a typo , a file is named 'inteface' instead of 'interface' "
	aMaker addFrameworksByTemplate: #( 'Carbon' 'QuickTime' ) maker: aMaker.
]

{ #category : #'plugin extra rules' }
SqueakMacintoshConfig >> configureByTemplateSecurityPlugin: aMaker [ 
	self flag:'tty'. "pharo's configureSecurityPlugin: has a super call to an empty method that I omit here. "
	aMaker templates 
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${crossDir}/plugins/FilePlugin'));
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqMacSecurity.c')).


]

{ #category : #'plugin extra rules' }
SqueakMacintoshConfig >> configureByTemplateSerialPlugin: aMaker [ 
	aMaker templates 
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with:  '${platformsDir}/unix/plugins/SerialPlugin' ));
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${platformsDir}/unix/plugins/SerialPlugin/sqUnixSerial.c'))


]

{ #category : #'plugin extra rules' }
SqueakMacintoshConfig >> configureByTemplateSocketPlugin: aMaker [ 
	aMaker templates 
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${platformsDir}/unix/plugins/SocketPlugin'));
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${platformsDir}/unix/plugins/SocketPlugin/sqUnixSocket.c')).


]

{ #category : #'plugin extra rules' }
SqueakMacintoshConfig >> configureByTemplateSoundGenerationPlugin: maker [ 
	maker doNotGenerate: true. 
	"pharo code comment:  The sources in platforms/Cross/plugins/SoundGenerationPlugin/sqOldSoundPrims.c 
	are out of date and need to be fixed before it can be built 

	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '$(pluginCross)/sqOldSoundPrims.c'));
	"

]

{ #category : #'plugin extra rules' }
SqueakMacintoshConfig >> configureByTemplateTestOSAPlugin: aMaker [
	aMaker addFrameworksByTemplate: #( 'Carbon'  'ApplicationServices' ).
]

{ #category : #'plugin extra rules' }
SqueakMacintoshConfig >> configureByTemplateUnixOSProcessPlugin: aMaker [ 
	aMaker templates 
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${crossDir}/plugins/FilePlugin')).

]

{ #category : #'cmake configuration' }
SqueakMacintoshConfig >> configureForBuildType: aSymbol [
	"Set my internal state appropriate for my build type".
	self flag:'tty'. 
	self configureNoBuildType.                "reset all internal flags"
	buildType:= aSymbol.                       "error checking was handled previously"
	self 	
		preferredIncludes;
		standardIncludes;

		internalPlugins;
		externalPlugins.


]

{ #category : #plugins }
SqueakMacintoshConfig >> customizeVMPlugins [
	"do nothing,. only used on linux?"
]

{ #category : #accessing }
SqueakMacintoshConfig >> defaultDirectoriesFromGitDir: gitRepository [
	"Set the default values for all necessary directories taking into account the Git repostiory. An example to use this method is:
	MTCocoaIOSCogJitDebugConfig new
	defaultDirectoriesFromGitDir: '/Users/mariano/Pharo/vm/git/cogVM/blessed';
	generateSources; 
	generate.
	"
	| gitRepositoryString |
	self flag:'tty'. "Squeak don't git"
	gitRepositoryString :=  gitRepository, '/'.
	self srcDir: gitRepositoryString, self srcDirName.
    	self platformsDir: gitRepositoryString, self platformsDirName.
    	self buildDir: gitRepositoryString, self buildDirName.
	self resourcesDir: gitRepositoryString, self resourcesDirName.
	self outputDir: gitRepositoryString, self outputDirName.
	
	
	
]

{ #category : #accessing }
SqueakMacintoshConfig >> executableType [
	^ 'MACOSX_BUNDLE'
]

{ #category : #accessing }
SqueakMacintoshConfig >> externalModulesDir [
	"answer the location in VM bundle, where plugins and rest of dynamic libs will be copied,
	by default, it is Framerowks subdir. i.e: 
	
		Cog.app/Contents/Frameworks
		
	"
	
	^ '${outputDir}/', self executableName, '.app/Contents/MacOS/Plugins'
]

{ #category : #'source files' }
SqueakMacintoshConfig >> extraSources [
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> frameworksBuild [
	^ #()
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> frameworksBuildAssert [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> frameworksBuildAssertITimerHeartbeat [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> frameworksBuildDebug [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> frameworksBuildDebugITimerHeartbeat [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> frameworksBuildITimerHeartbeat [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> frameworksBuildMultiThreaded [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> frameworksBuildMultiThreadedAssert [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> frameworksBuildMultiThreadedDebug [
	^ self frameworksBuild
]

{ #category : #'source generation' }
SqueakMacintoshConfig >> generateByTemplate [
	"You can write out supporting CMake output here. See this method in SqueakUnixConfig for example"
	^ CMakeVMGeneratorForSqueak generateByTemplate: self 
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> generateVmConfigCmake [
	"do nothing. Unless Mac uses this, then push me down"
]

{ #category : #'source files' }
SqueakMacintoshConfig >> initializePlatformSources [
	"files added from platform/Mac OS/vm dir 	Your configuration will need a subset of these based on buildType
	SystemNavigation browseAllImplementorsOf: #setPlatformSourcesBuild:
	"
		
	platformSources :=#(
	'NSCursorWrappers.m'
	'nsPoolManagement.m'
	'osExports.c'
	'sqMacEncoding.c'
	'sqMacImageIO.c'
	'sqMacMain.c'
	'sqMacMemory.c'
	'sqMacNSPluginUILogic2.c'
	'sqMacTime.c'
	'sqMacUIAppleEvents.c'
	'sqMacUIClipBoard.c'
	'sqMacUIEventsUniversal.c'  " instead of: sqMacUIEvents.c "
	'sqMacUIMenuBarUniversal.c'
	'sqMacUnixCommandLineInterface.c'
	'sqMacUnixExternalPrims.c'
	'sqMacWindowUniversal.c'
	'version.c'	
	)
]

{ #category : #accessing }
SqueakMacintoshConfig >> platformName [
	^self macOSPlatformName
]

{ #category : #accessing }
SqueakMacintoshConfig >> resourcesDir [ 
	"Answer the value of resourcesDir"
	self flag:'tty'. "I modified resourcesDir to 'assureExistence' from 'fullname'. if this causes problems, look into that"
	^ resourcesDir ifNil: [ resourcesDir := (self topDir / self resourcesDirName) assureExistence ]
	
]

{ #category : #accessing }
SqueakMacintoshConfig >> resourcesDir: anObject [
	"Set the value of platformsDir"

	resourcesDir := anObject
]

{ #category : #accessing }
SqueakMacintoshConfig >> resourcesDirName [
	^self dirBuild, FileDirectory slash,'resources'.
"	^ 'macbuild/resources'"
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> setGlobalOptionsAfterDetermineSystemBuild: aMaker [
	"Set CMake commands that are common for a this platform'"
	(enabledebugmessages)
		ifTrue:[			
	templates 
		addLast: ((CMakeMessage new) message: (self class name), '  setGlobalOptionsAfterDetermineSystemBuild: aMaker')].




	


]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> setResourceProperties: maker [
	templates
		addLast:((CMakeMessage new) message: (self class name), ' setResourceProperties: maker' )
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> standardIncludesBuild [
	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: (self class name), ' standardIncludesBuild' )
	].

	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_PATH =  ${CMAKE_INCLUDE_PATH}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_SYSTEM_INCLUDE_PATH =  ${CMAKE_SYSTEM_INCLUDE_PATH}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES = ${CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES =  ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_FIND_ROOT_PATH_MODE_INCLUDE =  ${CMAKE_FIND_ROOT_PATH_MODE_INCLUDE}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_FIND_ROOT_PATH_MODE_INCLUDE =  ${CMAKE_INCLUDE_CURRENT_DIR}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_CURRENT_DIR_IN_INTERFACE =  ${CMAKE_INCLUDE_CURRENT_DIR_IN_INTERFACE}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_DIRECTORIES_BEFORE =  ${CMAKE_INCLUDE_DIRECTORIES_BEFORE}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_DIRECTORIES_PROJECT_BEFORE =  ${CMAKE_INCLUDE_DIRECTORIES_PROJECT_BEFORE}' )
	].

]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> thirdpartyLibsBuild [
	^ thirdpartyLibs ifNil: [ thirdpartyLibs := OrderedCollection new ].
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> thirdpartyLibsBuildAssert [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> thirdpartyLibsBuildAssertITimerHeartbeat [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> thirdpartyLibsBuildDebug [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> thirdpartyLibsBuildDebugITimerHeartbeat [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> thirdpartyLibsBuildITimerHeartbeat [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> thirdpartyLibsBuildMultiThreaded [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> thirdpartyLibsBuildMultiThreadedAssert [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakMacintoshConfig >> thirdpartyLibsBuildMultiThreadedDebug [
	^ self thirdpartyLibs 
]
