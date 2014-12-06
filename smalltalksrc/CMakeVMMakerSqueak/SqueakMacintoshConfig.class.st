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
		addLast: ((CMakeSet new) variable: 'srcDir' quotedValue: (self srcDir pathName));
		addLast: ((CMakeSet new) variable: 'srcPluginsDir' quotedValue: (pluginsDir ifNil: [ '${srcDir}/plugins' ]));
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

{ #category : #'initialize-release' }
SqueakMacintoshConfig >> customizeVMDrivers [
	"
	SystemNavigation default browseMethodsWhoseNamesContain:'customizeVMDrivers'
	
	force platform level or lower customization of vm-display-X11 vm-sound-ALSA, etc. 
	The configurations can select what subset they want using something like this.

	|subset iwantonly|
	iwantonly :=	 #(#CMakeVMDisplayNull  #CMakeVMDisplayX11  #CMakeVMSoundALSA  #CMakeVMSoundNull ).
	subset := vmdrivers select: [:vmd | 0 < (iwantonly occurrencesOf: (vmd class name) asSymbol)]. 
	vmdrivers := subset.

	self 
		customizeCMakeVMDisplayNull;
		customizeCMakeVMDisplayX11;
		customizeCMakeVMSoundALSA;
		customizeCMakeVMSoundNull


"
	self flag:'tty'. "revisit this design strategy"
	self subclassResponsibility
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

{ #category : #accessing }
SqueakMacintoshConfig >> platformName [
	^self macOSPlatformName
]

{ #category : #'source files' }
SqueakMacintoshConfig >> platformSources [
	"files added from platform/Mac OS/vm dir "
	^ #(
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
