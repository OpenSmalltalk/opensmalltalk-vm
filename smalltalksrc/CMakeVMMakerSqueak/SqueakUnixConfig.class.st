"
A SqueakUnixConfig is a top level configuration for *nix configuratons.

"
Class {
	#name : #SqueakUnixConfig,
	#superclass : #CPlatformConfigForSqueak,
	#category : #CMakeVMMakerSqueak
}

{ #category : #'compiler flags' }
SqueakUnixConfig >> commonCompilerFlags [
	"avoid premature optimization. push this decision down lower if it is needed at all"
	self deprecated: ' its much easier to have all the flags in your configuration class.  '.
	^{}


]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureAsynchFilePlugin: maker [

	maker addPlatformSources:
	#( 
		'sqUnixAsynchFile.c'
	)


]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureB3DAcceleratorPlugin: maker [
	"extra rules for B3DAcceleratorPlugin"
	
	super configureB3DAcceleratorPlugin: maker.
	
	maker 
		addPlatformSources: #( 'sqUnixOpenGL.c' ) 
		

]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureDropPlugin: maker [
	"extra rules for DropPlugin"
	super configureDropPlugin: maker.  
	maker includeDirectories: '${crossDir}/plugins/FilePlugin'. 
	maker addPlatformSources: #( 'sqUnixDragDrop')

]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureFT2Plugin: maker [ 

	"extra rules for FT2Plugin" 
	
	maker addExternalLibraries: #('freetype' ).
	
	"
	ft2build.h. says: 
	<prefix>/include/freetype2' must be in your current inclusion path "
	self flag:'tty'. "is this generic?"
	maker includeDirectories:  '/usr/include/freetype2'
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureFileCopyPlugin: maker [
	"extra rules for DropPlugin"

	maker addPlatformSources: #( 'sqUnixFileCopyPlugin')

]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureFilePlugin: maker [
	"extra rules for FilePlugin"

	super configureFilePlugin: maker.  
	
	maker addPlatformSources: #( 'sqUnixFile')
]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configureForBuildType: aSymbol [
	"Set my internal state appropriate for my build type".
	self configureNoBuildType.                "reset all internal flags"
	buildType:= aSymbol.                       "error checking was handled previously"
	self
		preferredIncludes;
		standardIncludes;
		configureFlags;     "  configure --without-npsqueak --with-src=stacksrc --with-plugins=src/plugins --disable-cogi --without-vm-display-fbdev  --x-libraries=/usr/lib --without-gl "
		compilerFlags;
		linkFlags;                         " LIBS=''-lpthread -luuid''"
		internalPlugins;
		externalPlugins.


]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureInternetConfigPlugin: maker [
	super configureInternetConfigPlugin: maker.
	maker addPlatformSources: #( 'sqUnixInternetConfiguration' )
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureJoystickTabletPlugin: maker [ 
	"extra rules for JoystickTabletPlugin"
	
	super configureJoystickTabletPlugin: maker.  
	maker addPlatformSources:
		#( 'sqUnixJoystickTablet' )

]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureLocalePlugin: maker [ 
	"extra rules for LocalePlugin"

	super configureLocalePlugin:  maker.
	
	maker addPlatformSources: #( 'sqUnixLocale.c')
	
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureMIDIPlugin: maker [ 
	"extra rules for MIDIPlugin"

	super configureMIDIPlugin: maker.  

	"requires ALSA"

	maker addPlatformSources: #( 'sqUnixMIDI')
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureSecurityPlugin: maker [ 
	"extra rules for MIDIPlugin"

	super configureSecurityPlugin: maker.
	
	maker addPlatformSources: #( 'sqUnixSecurity')
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureSerialPlugin: maker [ 
	"extra rules for SerialPlugin"
	
	maker addPlatformSources: #( 'sqUnixSerial')
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureSocketPlugin: maker [ 
	"extra rules for SocketPlugin"
	
	maker addPlatformSources: #( 'sqUnixSocket')
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureSoundPlugin: maker [ 
	"extra rules for SoundPlugin"
	
	maker addPlatformSources: #( 'sqUnixSound').
	maker addExternalLibraries: #( 'asound' )
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureSqueakSSLPlugin: maker [ 
	"extra rules for SqueakSSLPlugin"
	
	maker addPlatformSources: #( 'sqUnixOpenSSL.c').
	
	maker addExternalLibraries: #('ssl' ).
	
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureUUIDPlugin: maker [ 
	"extra rules for UUIDPlugin"

	super configureUUIDPlugin: maker.    
	
	maker includeDirectories: '/usr/include/uuid'.
	
	maker addPlatformSources:
		#( 'sqUnixUUID.c')



]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureUnixOSProcessPlugin: maker [ 
	"extra rules for UnixOSProcessPlugin"

	maker includeDirectories: '${crossDir}/plugins/FilePlugin'.
	maker includeDirectories: '${crossDir}/plugins/SocketPlugin'.
	
	maker addDefinitions: '-DSQAIO_H=\"sqaio.h\"'

]

{ #category : #accessing }
SqueakUnixConfig >> executableType [
	^ ''

]

{ #category : #accessing }
SqueakUnixConfig >> externalModulesDir [
	"answer the location in VM bundle, where plugins and rest of dynamic libs will be copied,
	"
	^ '${outputDir}'
]

{ #category : #'source files' }
SqueakUnixConfig >> extraSources [	
	^ ''
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuild [
	"leave empty for all platforms but Mac OS"
	^ #()
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildAssert [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildAssertITimerHeartbeat [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildDebug [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildDebugITimerHeartbeat [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildITimerHeartbeat [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildMultiThreaded [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildMultiThreadedAssert [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildMultiThreadedDebug [
	^ self frameworksBuild
]

{ #category : #accessing }
SqueakUnixConfig >> platformName [
	^self unixPlatformName
]

{ #category : #'source files' }
SqueakUnixConfig >> platformSources [
	"files added from platform/unix/vm dir "
	^ #(
	'aio.c'
	'debug.c'
"	'dlfcn-dyld.c'
	'mac-alias.c' "
	'osExports.c'
	'sqUnixCharConv.c'
"	'sqUnixEvent.c' "
	'sqUnixExternalPrims.c'
	'sqUnixHeartbeat.c'
	'sqUnixMain.c'
	'sqUnixMemory.c'
	'sqUnixThreads.c'
	'sqUnixVMProfile.c'
	)
]

{ #category : #'squeak compatability' }
SqueakUnixConfig >> setupDirectories: gen [
	super setupDirectories: gen.
	gen set: #externalModulesDir toString: self externalModulesDir.
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuild [
	^ thirdpartyLibs ifNil: [ thirdpartyLibs := OrderedCollection new ].
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildAssert [
	^ self thirdpartyLibsBuild 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildAssertITimerHeartbeat [
	^ self thirdpartyLibsBuild 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildDebug [
	^ self thirdpartyLibsBuild 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildDebugITimerHeartbeat [
	^ self thirdpartyLibsBuild 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildITimerHeartbeat [
	^ self thirdpartyLibsBuild 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildMultiThreaded [
	^ self thirdpartyLibsBuild 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildMultiThreadedAssert [
	^ self thirdpartyLibsBuild 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildMultiThreadedDebug [
	^ self thirdpartyLibsBuild 
]
