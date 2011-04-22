"
MacOSConfig is an abstract class for all Mac Carbon configurations. It is intended to share code between different concrete implementations. 

It is using a Carbon framework , which eventually will be replaced by Cocoa. (see CocoaIOSConfig and its subclasses).
"
Class {
	#name : #MacOSConfig,
	#superclass : #CPlatformConfig,
	#instVars : [
		'resourcesDir'
	],
	#category : #'CMakeVMMaker-MacOS'
}

{ #category : #accessing }
MacOSConfig >> cMakeMacros [ 
	^'macro(add_framework appname fwname)
    find_library(FRAMEWORK_${fwname}
        NAMES ${fwname}
        PATHS ${CMAKE_OSX_SYSROOT}/System/Library
        PATH_SUFFIXES Frameworks
        NO_DEFAULT_PATH)
    if( ${FRAMEWORK_${fwname}} STREQUAL FRAMEWORK_${fwname}-NOTFOUND)
        message(ERROR ": Framework ${fwname} not found")
    else()
	  include_directories(SYSTEM /System/Library/Frameworks/${fwname}.framework/Headers)
	  target_link_libraries(${appname} ${FRAMEWORK_${fwname}})
    endif()
endmacro(add_framework)'  
]

{ #category : #'plugin extra rules' }
MacOSConfig >> configureB3DAcceleratorPlugin: maker [
	"extra rules for B3DAcceleratorPlugin"
	
	super configureB3DAcceleratorPlugin: maker.  
	
	maker 
		includeDirectories: '/usr/X11/include';  "for GL.h"
		addPlatformSources: #( 'sqMacOpenGL.c' 'sqMacOpenGLInfo.c')

]

{ #category : #'plugin extra rules' }
MacOSConfig >> configureClipboardExtendedPlugin: maker [
	
]

{ #category : #'plugin extra rules' }
MacOSConfig >> configureCroquetPlugin: maker [ 
	"extra rules for CroquetPlugin"

	super configureCroquetPlugin: maker.  
	maker addPlatformSources: #('sqMacCroquet.c').

]

{ #category : #'plugin extra rules' }
MacOSConfig >> configureFFIPlugin: maker [
	super configureFFIPlugin: maker.
	maker addPlatformSources: #( "'sqMacIntel-Win32.c'"
		'x86-sysv-MacIntel.c'
		'x86-sysv-asm-MacIntel.S'
	)
]

{ #category : #'plugin extra rules' }
MacOSConfig >> configureInternetConfigPlugin: maker [
	"extra rules for InternetConfigPlugin"
	
	super configureInternetConfigPlugin: maker.  
	maker addPlatformSources: #( 'sqMacInternetConfiguration.c')

]

{ #category : #'plugin extra rules' }
MacOSConfig >> configureJoystickTabletPlugin: maker [ 
	"extra rules for JoystickTabletPlugin"
	
	super configureJoystickTabletPlugin: maker.  
	maker addPlatformSources:
		#( 
			'HID_Error_Handler.c'
			'HID_Name_Lookup.c'
			'HID_Queue_Utilities.c'
			'HID_Utilities.c'
			'sqMacJoystickAndTablet.c'
			)

]

{ #category : #'plugin extra rules' }
MacOSConfig >> configureLocalePlugin: maker [ 
	"extra rules for LocalePlugin"

	super configureLocalePlugin: maker.  
	maker addPlatformSources: #( 'sqMacLocaleCarbon.c' )

]

{ #category : #'plugin extra rules' }
MacOSConfig >> configureMIDIPlugin: maker [ 
	"extra rules for MIDIPlugin"

	super configureMIDIPlugin: maker.  
	maker addPlatformSources: #( 'sqMacMIDI.c')
]

{ #category : #'plugin extra rules' }
MacOSConfig >> configureMpeg3Plugin: maker [

	super configureMpeg3Plugin: maker.
	
	maker addPlatformSources: #(	
		'sqMacFileBits.c')
	
]

{ #category : #'plugin extra rules' }
MacOSConfig >> configureObjectiveCPlugin: maker [
	maker doNotGenerate: true
]

{ #category : #'plugin extra rules' }
MacOSConfig >> configurePlugin: aPlugin with: generator [

	generator isExternal ifTrue: [
		" set output directory for dynamic library to Resources subdir in .app bundle location "
		generator 
			set: 'CMAKE_LIBRARY_OUTPUT_DIRECTORY' 
			toString: (self outputDir , '/', self executableName,'.app/Contents/Resources')
		].
	^ super configurePlugin: aPlugin with: generator

]

{ #category : #'plugin extra rules' }
MacOSConfig >> configureSecurityPlugin: maker [ 
	"extra rules for SecurityPlugin"

	super configureSecurityPlugin: maker.  
	maker includeDirectories: '${crossDir}/plugins/FilePlugin'.
	maker addPlatformSources: #( 'sqMacSecurity.c' )
]

{ #category : #'plugin extra rules' }
MacOSConfig >> configureSerialPlugin: maker [ 
	"extra rules for SerialPlugin"

	super configureSerialPlugin: maker.  
	maker addPlatformSources: #( 'sqMacSerialPort.c' )


]

{ #category : #'plugin extra rules' }
MacOSConfig >> configureSocketPlugin: maker [ 
	"extra rules for SoundPlugin"

	super configureSoundPlugin: maker.  
	maker includeDirectories: '${platformsDir}/unix/plugins/SocketPlugin'.
	maker 
		addSources: #('sqUnixSocket.c') 
		prefixed: '${platformsDir}/unix/plugins/SocketPlugin/'



]

{ #category : #accessing }
MacOSConfig >> defaultDirectoriesFromGitDir: gitRepository [
	"Set the default values for all necessary directories taking into account the Git repostiory. An example to use this method is:
	MTCocoaIOSCogJitDebugConfig new
	defaultDirectoriesFromGitDir: '/Users/mariano/Pharo/vm/git/cogVM/blessed';
	generateSources; 
	generate.
	"
	| gitRepositoryString |
	gitRepositoryString :=  gitRepository, '/'.
	self srcDir: gitRepositoryString, self srcDirName.
    	self platformsDir: gitRepositoryString, self platformsDirName.
    	self buildDir: gitRepositoryString, self buildDirName.
	self resourcesDir: gitRepositoryString, self resourcesDirName.
	self outputDir: gitRepositoryString, self outputDirName.
	
	
	
]

{ #category : #utils }
MacOSConfig >> fixLineEndsOf: string [
	^ string copyReplaceAll: String cr with: String lf
]

{ #category : #accessing }
MacOSConfig >> outputDir [

	"the directory where built binaries will be stored"
	^ outputDir ifNil: [ outputDir := (self buildDir containingDirectory fullName , '/', self outputDirName) ]
	
]

{ #category : #'source generation' }
MacOSConfig >> prepareForGeneration [

	"force using LF on Macs"
	CrLfFileStream defaultToLF.


]

{ #category : #accessing }
MacOSConfig >> resourcesDir [ 
	"Answer the value of resourcesDir"

	^ resourcesDir ifNil: [ resourcesDir := (self topDir / 'macbuild/resources') fullName ]
	
]

{ #category : #accessing }
MacOSConfig >> resourcesDir: anObject [
	"Set the value of platformsDir"

	resourcesDir := anObject
]

{ #category : #accessing }
MacOSConfig >> resourcesDirName [
	^ 'macbuild/resources'
]
