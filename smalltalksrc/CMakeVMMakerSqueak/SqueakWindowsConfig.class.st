"
A SqueakWindowsConfig is is a top level configuration for MSWindows configuratons.
My immediate sub-classes are Abstract Base classes for specific MSWindows variants.
The sub-classes of my Abstract Base Classes are concrete configurations of the form
[Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf
I am not meant to be built.

HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp

N.B. tty.  below are comments from pharo's CogFamilyWindowsConfig. I have not tested them as of 2014.12.09

What you need to get started:
Download and install Msys, with C/C++ compiler support:
	http://www.mingw.org/wiki/msys
Download and install Git:
	http://code.google.com/p/msysgit/

///
Optional: add git to the PATH variable:

Add path to git for msys:
Control panel -> System -> System Properies / Advanced  [ Environment Variables ]

There should be already:
C:\Program Files\Git\cmd

add:

C:\Program Files\Git\bin

/// For automated builds, add SQUEAKVM environment variable and set it to the full path to squeak executable.

(Control panel -> System -> System Properies / Advanced  [ Environment Variables ])

in windows shell you can use it then to run squeak: %SQUEAKVM%  , and in mingw bash shell, use $SQUEAKVM

/// Install CMake:
http://www.cmake.org/cmake/resources/software.html

(during installation, in install options , make sure that you choose to add CMake to PATH)


Note, to run cmake under msys shell, you have to explicitly specify the msys makefiles generator, because default one is MS:

cmake . -G""MSYS Makefiles""


"
Class {
	#name : #SqueakWindowsConfig,
	#superclass : #CPlatformConfigForSqueak,
	#category : #CMakeVMMakerSqueak
}

{ #category : #cmake }
SqueakWindowsConfig >> cmakeWriteDirectoriesDotCmake: aMaker [
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
SqueakWindowsConfig >> compilerDefinitions [
	self deprecated: 'Legacy method from pharo approach. We need different definitions for each buildType'.

	^ {  
		'-D_MT'.
		'-DWIN32'. 
		'-DWIN32_FILE_SUPPORT'. 
		'-DNO_ISNAN'.
		'-DNO_SERVICE'. 
		'-DNO_STD_FILE_SUPPORT'.
		'-DLSB_FIRST'. 
		'-DVM_NAME="', self executableName,'"'.
		'-DX86 '.
		'-DSTACK_ALIGN_BYTES=16'. 
		'-DALLOCA_LIES_SO_USE_GETSP=0'. 
		'-DENABLE_FAST_BLT ' }
]

{ #category : #compiling }
SqueakWindowsConfig >> compilerFlags [
	"omit -ggdb2 to prevent generating debug info"
	"Some flags explanation: 
	
	STACK_ALIGN_BYTES=16 is needed in mingw and FFI (and I suppose on other modules too).
	DALLOCA_LIES_SO_USE_GETSP=0 Some compilers return the stack address+4 on alloca function, 
	then FFI module needs to adjust that. It is NOT the case of mingw.
	For more information see this thread: http://forum.world.st/There-are-something-fishy-with-FFI-plugin-td4584226.html
	"
	^ {  
		'-march=pentium4'.
		'-mwindows'.
		'-msse2'. 
		'-mthreads'. 
		'-mwin32'.
		'-mno-rtd'. 
		'-mms-bitfields'. 
		'-mno-accumulate-outgoing-args ', self winVer }
]

{ #category : #'cmake configuration' }
SqueakWindowsConfig >> configureForBuildType: aSymbol [
	"Set my internal state appropriate for my build type".
	self configureNoBuildType.                "reset all internal flags"
	buildType:= aSymbol.                       "error checking was handled previously"


]

{ #category : #'initialize-release' }
SqueakWindowsConfig >> customizeVMDrivers [
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
SqueakWindowsConfig >> customizeVMPlugins [
	"do nothing,. only used on linux?"
]

{ #category : #accessing }
SqueakWindowsConfig >> executableType [
	^ 'WIN32'
]

{ #category : #accessing }
SqueakWindowsConfig >> externalModulesDir [
	"answer the location in VM bundle, where plugins and rest of dynamic libs will be copied,
	"
	^ '${outputDir}'
]

{ #category : #'source files' }
SqueakWindowsConfig >> extraSources [

	^ 
	'${resources}'
]

{ #category : #'cmake buildType redirects' }
SqueakWindowsConfig >> frameworksBuild [
	"leave empty for all platforms but Mac OS"
	^ #()
]

{ #category : #'cmake buildType redirects' }
SqueakWindowsConfig >> frameworksBuildAssert [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakWindowsConfig >> frameworksBuildAssertITimerHeartbeat [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakWindowsConfig >> frameworksBuildDebug [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakWindowsConfig >> frameworksBuildDebugITimerHeartbeat [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakWindowsConfig >> frameworksBuildITimerHeartbeat [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakWindowsConfig >> frameworksBuildMultiThreaded [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakWindowsConfig >> frameworksBuildMultiThreadedAssert [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakWindowsConfig >> frameworksBuildMultiThreadedDebug [
	^ self frameworksBuild
]

{ #category : #accessing }
SqueakWindowsConfig >> msysPathFor: aPath [
	| path |
	self flag:'tty'. "code smell alert"
	^aPath isString
		ifTrue:[	path := aPath  copyReplaceAll: '\' with: '/'.]
		ifFalse:[	path := aPath pathName copyReplaceAll: '\' with: '/'.]

	

]

{ #category : #accessing }
SqueakWindowsConfig >> platformName [
	^self win32PlatformName
]

{ #category : #'source files' }
SqueakWindowsConfig >> platformSources [
	"files added from platform/win32/vm dir "
	^ #(
		'sqWin32Alloc.c'
		'sqWin32Directory.c'
		'sqWin32Heartbeat.c'
		'sqWin32Service.c'
		'sqWin32VMProfile.c'
		'sqWin32Args.c'
		'sqWin32Exports.c'
		'sqWin32Intel.c'
		'sqWin32Stubs.c'
		'sqWin32Window.c'
		'sqWin32Backtrace.c'
		'sqWin32ExternalPrims.c'
		'sqWin32PluginSupport.c'
		'sqWin32Threads.c'
		'version.c'
		'sqWin32DirectInput.c'
		'sqWin32GUID.c'
		'sqWin32Prefs.c'
		'sqWin32Utils.c'
	)
]

{ #category : #'cmake buildType redirects' }
SqueakWindowsConfig >> setGlobalOptionsAfterDetermineSystemBuild: aMaker [
	"Set CMake commands that are common for a this platform'"
	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: (self class name), '  setGlobalOptionsAfterDetermineSystemBuild: aMaker').
	].





]

{ #category : #'cmake buildType redirects' }
SqueakWindowsConfig >> standardIncludesBuild [
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
SqueakWindowsConfig >> thirdpartyLibsBuild [
	^ thirdpartyLibs ifNil: [ thirdpartyLibs := OrderedCollection new ].
]

{ #category : #'cmake buildType redirects' }
SqueakWindowsConfig >> thirdpartyLibsBuildAssert [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakWindowsConfig >> thirdpartyLibsBuildAssertITimerHeartbeat [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakWindowsConfig >> thirdpartyLibsBuildDebug [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakWindowsConfig >> thirdpartyLibsBuildDebugITimerHeartbeat [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakWindowsConfig >> thirdpartyLibsBuildITimerHeartbeat [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakWindowsConfig >> thirdpartyLibsBuildMultiThreaded [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakWindowsConfig >> thirdpartyLibsBuildMultiThreadedAssert [
	^ self thirdpartyLibs 
]

{ #category : #'cmake buildType redirects' }
SqueakWindowsConfig >> thirdpartyLibsBuildMultiThreadedDebug [
	^ self thirdpartyLibs 
]

{ #category : #accessing }
SqueakWindowsConfig >> winVer [
	"Set minimum version to WindowsXP (see /cygwin/usr/include//w32api/w32api.h)"
	
	^ '-D_WIN32_WINNT=0x0501 -DWINVER=0x0501'
]
