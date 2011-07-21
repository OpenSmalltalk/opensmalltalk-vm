"
This is an abstract class and it is the root configuration for building all types of Cog VMs on MS-Windows platform.


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


Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #CogFamilyWindowsConfig,
	#superclass : #CPlatformConfig,
	#category : #'CMakeVMMaker-Windows'
}

{ #category : #'compiler flags' }
CogFamilyWindowsConfig >> commonCompilerFlags [
	^ '-march=pentium4 -mwindows -D_MT -msse2 -ggdb2 -mthreads -mno-cygwin -mwin32 -mno-rtd -mms-bitfields -mno-accumulate-outgoing-args ', self winVer ,

	' -DWIN32 -DWIN32_FILE_SUPPORT -DNO_ISNAN -DNO_SERVICE -DNO_STD_FILE_SUPPORT ',
	'-DLSB_FIRST -DVM_NAME="', self executableName,'" -DX86 '
]

{ #category : #'plugin extra rules' }
CogFamilyWindowsConfig >> configureAsynchFilePlugin:  maker [ 
	"extra rules for AsynchFilePlugin "

	super configureAsynchFilePlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32AsyncFilePrims.c')



]

{ #category : #'plugin extra rules' }
CogFamilyWindowsConfig >> configureB3DAcceleratorPlugin:  maker [ 
	"extra rules for B3DAcceleratorPlugin "

	super configureB3DAcceleratorPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32DualB3DX.c' 'sqWin32D3D.c' 'sqWin32OpenGL.c')



]

{ #category : #'plugin extra rules' }
CogFamilyWindowsConfig >> configureCroquetPlugin:  maker [ 
	"extra rules for CroquetPlugin "

	super configureCroquetPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32CroquetPlugin.c')



]

{ #category : #'plugin extra rules' }
CogFamilyWindowsConfig >> configureDropPlugin:  maker [ 
	"extra rules for DropPlugin "

	super configureDropPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32Drop')



]

{ #category : #'plugin extra rules' }
CogFamilyWindowsConfig >> configureFT2Plugin: maker [ 
	"extra rules for FT2Plugin"
	

	"extra rules for Freetype plugin.
	a custom rule to build freetype library"

	maker set: #freetypeLibDir toString: '${buildDir}/FT2Plugin'.
	maker set: #freetypeLib toString: '${freetypeLibDir}/libfreetype.dll.a'.


	maker cmd: 'add_custom_command' params: 'OUTPUT ${freetypeLib} 
		COMMAND "${pluginPlatform}/makeFreetype.dynamic.win32" "${freetypeLibDir}" "${outputDir}"
		COMMENT "Building freetype library"
	'.

	maker addSource: '${freetypeLib}'.
	maker addExternalLibrary:  '"${freetypeLib}"'.

	"the freetype sources are located in {build}/FT2Plugin/freetype2/include "
	maker includeDirectories: '${freetypeLibDir}/freetype2/include'


]

{ #category : #'plugin extra rules' }
CogFamilyWindowsConfig >> configureFilePlugin: maker [ 
	
	super configureFilePlugin: maker.
	
	maker addPlatformSources:
		#( 'sqWin32FilePrims.c')



]

{ #category : #'plugin extra rules' }
CogFamilyWindowsConfig >> configureHostWindowPlugin:    maker [ 
	"extra rules for HostWindowPlugin "

	super configureHostWindowPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32HostWindowPlugin.c')



]

{ #category : #'plugin extra rules' }
CogFamilyWindowsConfig >> configureJoystickTabletPlugin:  maker [ 
	
	super configureJoystickTabletPlugin:  maker.
	
	maker addPlatformSources:
		#( 'sqWin32Joystick.c')



]

{ #category : #'plugin extra rules' }
CogFamilyWindowsConfig >> configureLocalePlugin:   maker [ 
	"extra rules for LocalePlugin "

	super configureLocalePlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32Locale.c')



]

{ #category : #'plugin extra rules' }
CogFamilyWindowsConfig >> configureMIDIPlugin:  maker [ 
	"extra rules for MIDIPlugin "

	super configureMIDIPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32MIDI.c')



]

{ #category : #'plugin extra rules' }
CogFamilyWindowsConfig >> configureMpeg3Plugin:  maker [ 
	"extra rules for Mpeg3Plugin "

	super configureMpeg3Plugin:  maker.
	
	maker addDefinitions: '-DNOPTHREADS'.

	maker addPlatformSources: #( 'sqOpenFile.c')
]

{ #category : #'plugin extra rules' }
CogFamilyWindowsConfig >> configureSecurityPlugin: maker [ 
	"extra rules for SecurityPlugin"

	super configureSecurityPlugin: maker.
	
	maker addPlatformSources: #( 'sqWin32Security')



]

{ #category : #'plugin extra rules' }
CogFamilyWindowsConfig >> configureSerialPlugin:     maker [ 
	"extra rules for SerialPlugin "

	super configureSerialPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32SerialPort.c')



]

{ #category : #'plugin extra rules' }
CogFamilyWindowsConfig >> configureSocketPlugin:  maker [ 
	"extra rules for SocketPlugin "

	super configureSocketPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32NewNet.c')



]

{ #category : #'plugin extra rules' }
CogFamilyWindowsConfig >> configureUUIDPlugin: maker [ 
	"extra rules for UUIDPlugin"
	
	maker addPlatformSources:
		#( 'sqWin32UUID.c')



]

{ #category : #'plugin extra rules' }
CogFamilyWindowsConfig >> configureWin32OSProcessPlugin: maker [ 
	"extra rules for Win32OSProcessPlugin"

	maker includeDirectories: '${crossDir}/plugins/FilePlugin'.
	maker includeDirectories: '${crossDir}/plugins/SocketPlugin'.

]

{ #category : #'as yet unclassified' }
CogFamilyWindowsConfig >> executableType [
	^ 'WIN32'
]

{ #category : #'as yet unclassified' }
CogFamilyWindowsConfig >> fixLineEndsOf: string [
	^ string copyReplaceAll: String cr with: String crlf
]

{ #category : #'as yet unclassified' }
CogFamilyWindowsConfig >> msysPathFor: aPath [
	| path |
	
	path := aPath.
	
	path := path copyReplaceAll: '\' with: '/'.
	
	^ path " copyReplaceAll: '\' with: '\\'"
]

{ #category : #directories }
CogFamilyWindowsConfig >> outputDir [

	"the directory where built binaries will be stored"

	^ outputDir ifNil: [ outputDir := self msysPathFor: (self buildDir containingDirectory fullName , '/', self outputDirName) ]
	
]

{ #category : #'as yet unclassified' }
CogFamilyWindowsConfig >> platformName [
	^ 'win32'
]

{ #category : #'as yet unclassified' }
CogFamilyWindowsConfig >> setupDirectories: gen [
	"we have to override that, because we need to convert windoze paths to msys ones"
	
	| dirsInclude |
	

	" write the directories in separate include file"
	dirsInclude := gen captureOutputDuring: [
		gen
			set: #topDir toString: (self msysPathFor: self topDir fullName); 
			set: #buildDir toString: (self buildDir ifNil: ['${topDir}/build'] ifNotNil:[ self msysPathFor: self buildDir fullName ]);
			set: #platformsDir toString: (self msysPathFor: self platformsDir);
			set: #srcDir toString: (self msysPathFor: self srcDir);
			set: #srcPluginsDir toString: (pluginsDir ifNil: [ '${srcDir}/plugins' ]);
			set: #srcVMDir toString: '${srcDir}/vm';
			set: #platformName toString: self platformName;
			set: #targetPlatform to: '${platformsDir}/${platformName}';
			set: #crossDir toString: '${platformsDir}/Cross';
			set: #platformVMDir toString: '${targetPlatform}/vm';
			set: #outputDir toString: (self msysPathFor: self outputDir).
	].

	self write: dirsInclude toFile: 'directories.cmake'
]

{ #category : #'as yet unclassified' }
CogFamilyWindowsConfig >> winVer [
	"Set minimum version to WindowsXP (see /cygwin/usr/include//w32api/w32api.h)"
	
	^ '-D_WIN32_WINNT=0x0501 -DWINVER=0x0501'
]
