"
This is an abstract class for all Mac Carbon configurations. It is intended to share code between different concrete implementations. 

It is using a Carbon framework , which eventually will be replaced by Cocoa. (see CocoaIOSConfig and its subclasses).


Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #MacOSConfig,
	#superclass : #CPlatformConfig,
	#instVars : [
		'resourcesDir'
	],
	#category : #'CMakeVMMaker-MacOS'
}

{ #category : #'build script' }
MacOSConfig >> buildScript [
	"answer the build script for building everything"
	

	^ 
'#!bash

if [ ! -e vmVersionInfo.h ]; then
	../codegen-scripts/extract-commit-info.sh
fi
cmake .
make
make install

'
]

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
MacOSConfig >> configureFT2Plugin: maker [
	"extra rules for Freetype plugin.
	a custom rule to build freetype library"
	| lib |
	
	maker isExternal ifFalse: [
		self error: 'building internal FT2Plugin is not supported yet'  	
	].

	"add freetype library into loop"
	lib := self addThirdpartyLibrary: 'freetype2'.

	"link plugin with freetype lib"
	maker addExternalLibrary: lib targetForLinking.
	maker includeDirectories: lib includeDir.

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
			toString: '${externalModulesDir}'
		].
	^ super configurePlugin: aPlugin with: generator

]

{ #category : #'plugin extra rules' }
MacOSConfig >> configureQuicktimePlugin: maker [
	
	maker includeDirectories: '${pluginPlatform}'.
	maker includeDirectories: '${crossDir}/plugins/SurfacePlugin'.
	
	" yes, this is not a typo , a file is named 'inteface' instead of 'interface' "

	maker addPlatformSources: #( 'sqMacQuicktimeInteface.c' ).
	
	maker addFrameworks: #( 'Carbon' 'QuickTime' ).
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

	super configureSoundPlugin: maker.  
	maker includeDirectories: '${platformsDir}/unix/plugins/SerialPlugin'.
	maker 
		addSources: #('sqUnixSerial.c') 
		prefixed: '${platformsDir}/unix/plugins/SerialPlugin/'



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

{ #category : #'plugin extra rules' }
MacOSConfig >> configureSoundGenerationPlugin: maker [ 
	"extra rules for SoundPlugin"

	maker doNotGenerate: true. 
	" The sources in platforms/Cross/plugins/SoundGenerationPlugin/sqOldSoundPrims.c 
	are out of date and need to be fixed before it can be built 
	
	
	maker 
		addCrossSources: #('sqOldSoundPrims.c') 

	"

]

{ #category : #'plugin extra rules' }
MacOSConfig >> configureTestOSAPlugin: maker [
		
	maker addFrameworks: #( 'Carbon'  'ApplicationServices' ).
]

{ #category : #'plugin extra rules' }
MacOSConfig >> configureUnixOSProcessPlugin: maker [ 
	"extra rules for UnixOSProcessPlugin"

	maker includeDirectories: '${crossDir}/plugins/FilePlugin'.

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

{ #category : #accessing }
MacOSConfig >> externalModulesDir [
	"answer the location in VM bundle, where plugins and rest of dynamic libs will be copied,
	by default, it is Framerowks subdir. i.e: 
	
		Cog.app/Contents/Frameworks
		
	"
	
	^ '${outputDir}/', self executableName, '.app/Contents/MacOS/Plugins'
]

{ #category : #utils }
MacOSConfig >> fixLibsTemplate [

^
'include(GetPrerequisites)

message("Fixing library references in: ${externalModulesDir}")

FILE(GLOB libs  "${externalModulesDir}/*.dylib")

set(all_imports "")

foreach(lib ${libs})
	get_filename_component(libName "${lib}" NAME)
	list(APPEND libNames "${libName}")
	
	set(prereq "")
	get_prerequisites(${lib} prereq 1 0 "${bundlePath}" "")


	list(APPEND all_imports ${prereq})

endforeach(lib)

list(REMOVE_DUPLICATES all_imports)
set(replacements "")
message ( "Found imports: ${all_imports} " )

foreach(import ${all_imports})
	foreach(lib ${libNames})
		set(match "^.*${lib}$")
		if(import MATCHES ${match})
			set(replacement "${pluginsRelPath}/${lib}")
			message("Will replace: ${import} with: ${replacement}")
			set(replacements ${replacements} "-change" "${import}" "${replacement}")
		endif(import MATCHES ${match})
	endforeach(lib)
endforeach(import)

foreach(lib ${libs})
	get_filename_component(name ${lib} NAME)
	set(fixedName "${pluginsRelPath}/${name}")
	message("Fixing up: ${name}")

 	execute_process(COMMAND install_name_tool -id "${fixedName}" "${lib}" )

 	execute_process(COMMAND install_name_tool  ${replacements} ${lib} )

endforeach(lib)
'


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

{ #category : #utils }
MacOSConfig >> postBuildActions: gen [

	" override to add custom rules after all targets is defined "
	
	self write: self fixLibsTemplate toFile: 'fix_libs.cmake'.
	
	
	gen
		set: #bundlePath toString: '${outputDir}/', self executableName, '.app';
		set: #pluginsRelPath toString: '@executable_path/Plugins'.

	gen
		puts: '
		INSTALL(CODE "
			set(externalModulesDir \"${externalModulesDir}\")
			set(bundlePath \"${bundlePath}\")
			set(pluginsRelPath \"${pluginsRelPath}\")
			
			include(fix_libs.cmake)
		")'
			
"					FILE(GLOB_RECURSE bLibs /${externalModulesDir}/*.*)
"
]

{ #category : #'source generation' }
MacOSConfig >> prepareForGeneration [
	
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

{ #category : #'source generation' }
MacOSConfig >> setupDirectories: gen [

	super setupDirectories: gen.
	
	gen set: #externalModulesDir toString: self externalModulesDir.

]
