"
A SqueakWindowsConfig is a top level config for Windows boxes
"
Class {
	#name : #SqueakWindowsConfig,
	#superclass : #CPlatformConfigForSqueak,
	#category : #CMakeVMMakerSqueak
}

{ #category : #'compiler flags' }
SqueakWindowsConfig >> commonCompilerFlags [
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
		'-D_MT'.
		'-msse2'. 
		'-mthreads'. 
		'-mwin32'.
		'-mno-rtd'. 
		'-mms-bitfields'. 
		'-mno-accumulate-outgoing-args ', self winVer.
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

{ #category : #'cmake configuration' }
SqueakWindowsConfig >> configureForBuildType: aSymbol [
	"Set my internal state appropriate for my build type".
	self configureNoBuildType.                "reset all internal flags"
	buildType:= aSymbol.                       "error checking was handled previously"
	self
		preferredIncludes;
		standardIncludes;
"		configureFlags;       configure --without-npsqueak --with-src=stacksrc --with-plugins=src/plugins --disable-cogi --without-vm-display-fbdev  --x-libraries=/usr/lib --without-gl "
		cC;                         " CC=''gcc -m32 -v''"
		cXX;                        "CXX=''g++ -m32'"
		lDFlags;                    " LDFLAGS=-Wl,-z,now"
		libs;                         " LIBS=''-lpthread -luuid''"
		internalPlugins;
		externalPlugins.


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

{ #category : #accessing }
SqueakWindowsConfig >> frameworks [
	"leave empty for all platforms but Mac OS"
	^ #()
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
