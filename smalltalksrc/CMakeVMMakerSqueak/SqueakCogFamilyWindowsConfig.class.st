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
	#name : #SqueakCogFamilyWindowsConfig,
	#superclass : #CPlatformConfig,
	#category : #'CMakeVMMakerSqueak-Windows'
}

{ #category : #'as yet unclassified' }
SqueakCogFamilyWindowsConfig class >> licenseTemplate [
	^'Squeak  {1} license information
==============================

About Squeak
-----------


Squeak is a modern, open source, full-featured implementation of the powerful Smalltalk programming language and environment. Squeak is highly-portable, running on almost any platform you could name and you can really truly write once run anywhere.  Squeak is the vehicle for a wide range of projects from multimedia applications and educational platforms to commercial web application development. Read on and join in!

http://www.squeak.org


LIcense

Note: The current release of Squeak is a combination of source code originating from it''s origins at Apple which Apple agreed to license under the Apache license and more recent contributions licensed under the MIT license. The vast majority of the code is under the MIT license.
MIT License

Copyright (c) The individual, corporate, and institutional contributors who have collectively contributed elements to this software ("The Squeak Community"), 1996-2010 All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
Portions of Squeak are covered by the following license:
Apache License, Version 2.0

Copyright (c) Xerox Corp. 1981, 1982 All rights reserved. Copyright (c) Apple Computer, Inc. 1985-1996 All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.


About Cog
---------

Cog is a virtual machine designed for Smalltalk and other similar dynamic languages.  Cog builds on the
Squeak virtual machine adding a stack-to-register-mapping just-in-time compiler, aggressive in-line message
cacheing and effective optimization of Smalltalk’s first-class activation records.  Cog is the virtual machine
underlying Teleplace''s Croquet-based enterprise virtual collaboration spaces software, the fastest virtual
machine for Squeak, and for Gilad Bracha''s Newspeak modular language inspired by Beta and Smalltalk.  
Like the original Squeak VM, Cog is implemented and developed in Smalltalk, and translated into a lower-level
language to produce the production VM.  Being a Smalltalk program it is a delight to develop.  Cog is
available under the MIT open source license and is unencumbered for commercial deployment.

Cog''s performance relative to the existing Squeak interpreter varies, depending on the benchmark chosen.
As of early-2011, the Cog JIT uses strong inline cacheing techniques and stack-to-register mapping that
results in a register-based calling convention for low-arity methods.  Due to the complexity of the Squeak
object representation it has a limited set of primitives implemented in machine code that, for example,
exclude object allocation.  Performance of the early-2011 JIT for the nbody, binarytrees and chameneos
redux benchmarks from the computer language shootout is in the range of 4 to 6 times faster than the
interpreter.
'
]

{ #category : #'as yet unclassified' }
SqueakCogFamilyWindowsConfig class >> pluginsTemplate [
	^'Squeak {1} ships with the following plugins already built:
		
Internal: 
=========
{2}

External: 
=========
{3}

'
]

{ #category : #'as yet unclassified' }
SqueakCogFamilyWindowsConfig >> addThirdpartyLibrary: libName [
	| libs lib |
	
	libs := self thirdpartyLibs.
	
	lib :=  libs 
		detect: [:each | each canonicalName = libName ] 
		ifNone: [ nil ].
		
	lib ifNil: [ 
		lib := SqueakCMThirdpartyLibrary named: libName config: self.
		"add dependencies first, so thirpartyLibs collection will be naturally dependency sorted"
		lib dependencies do: [:dep | self addThirdpartyLibrary: dep ].
		libs add: lib ].

	^ lib
]

{ #category : #directories }
SqueakCogFamilyWindowsConfig >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #directories }
SqueakCogFamilyWindowsConfig >> buildDirName [
	^ 'cmake_cygwinbuild'
]

{ #category : #'build script' }
SqueakCogFamilyWindowsConfig >> buildScript [
	"answer the build script for building everything"
	

	^ 
'#!/usr/bin/env bash

cmake -G "MSYS Makefiles" .
make

'
]

{ #category : #'compiler flags' }
SqueakCogFamilyWindowsConfig >> commonCompilerFlags [
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

{ #category : #directories }
SqueakCogFamilyWindowsConfig >> compilerFlags [ 
	| releaseFlags |
	
	releaseFlags := self isGenerateForRelease 
		ifTrue: [ self compilerFlagsRelease ]
		ifFalse: [ self compilerFlagsDebug ].
		
	^ String streamContents: [ :stream |
		((self commonCompilerFlags, releaseFlags)
			asStringOn: stream 
			delimiter: ' ' )]
]

{ #category : #'plugin extra rules' }
SqueakCogFamilyWindowsConfig >> configureAsynchFilePlugin:  maker [ 
	"extra rules for AsynchFilePlugin "

	super configureAsynchFilePlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32AsyncFilePrims.c')



]

{ #category : #'plugin extra rules' }
SqueakCogFamilyWindowsConfig >> configureB3DAcceleratorPlugin:  maker [ 
	"extra rules for B3DAcceleratorPlugin "

	super configureB3DAcceleratorPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32DualB3DX.c' 'sqWin32D3D.c' 'sqWin32OpenGL.c')



]

{ #category : #'plugin extra rules' }
SqueakCogFamilyWindowsConfig >> configureCroquetPlugin:  maker [ 
	"extra rules for CroquetPlugin "

	super configureCroquetPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32CroquetPlugin.c')



]

{ #category : #'plugin extra rules' }
SqueakCogFamilyWindowsConfig >> configureDropPlugin:  maker [ 
	"extra rules for DropPlugin "

	super configureDropPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32Drop')



]

{ #category : #'plugin extra rules' }
SqueakCogFamilyWindowsConfig >> configureFT2Plugin: maker [
	"extra rules for Freetype plugin.
	a custom rule to build freetype library"
	| lib |
	
"	maker isExternal ifFalse: [
		self error: 'building internal FT2Plugin is not supported yet'  	
	].
"
	"add freetype library into loop"
	lib := self addThirdpartyLibrary: 'freetype2'.

	"link plugin with freetype lib"
	maker addExternalLibrary: lib targetForLinking.
	maker includeDirectories: lib includeDir.


]

{ #category : #'plugin extra rules' }
SqueakCogFamilyWindowsConfig >> configureFilePlugin: maker [ 
	
	super configureFilePlugin: maker.
	
	maker addPlatformSources:
		#( 'sqWin32FilePrims.c')



]

{ #category : #'plugin extra rules' }
SqueakCogFamilyWindowsConfig >> configureHostWindowPlugin:    maker [ 
	"extra rules for HostWindowPlugin "

	super configureHostWindowPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32HostWindowPlugin.c')



]

{ #category : #'plugin extra rules' }
SqueakCogFamilyWindowsConfig >> configureJoystickTabletPlugin:  maker [ 
	
	super configureJoystickTabletPlugin:  maker.
	
	maker addPlatformSources:
		#( 'sqWin32Joystick.c')



]

{ #category : #'plugin extra rules' }
SqueakCogFamilyWindowsConfig >> configureLocalePlugin:   maker [ 
	"extra rules for LocalePlugin "

	super configureLocalePlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32Locale.c')



]

{ #category : #'plugin extra rules' }
SqueakCogFamilyWindowsConfig >> configureMIDIPlugin:  maker [ 
	"extra rules for MIDIPlugin "

	super configureMIDIPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32MIDI.c')



]

{ #category : #'plugin extra rules' }
SqueakCogFamilyWindowsConfig >> configureMpeg3Plugin:  maker [ 
	"extra rules for Mpeg3Plugin "

	super configureMpeg3Plugin:  maker.
	
	maker addDefinitions: '-DNOPTHREADS'.

	maker addPlatformSources: #( 'sqOpenFile.c')
]

{ #category : #'plugin extra rules' }
SqueakCogFamilyWindowsConfig >> configureSecurityPlugin: maker [ 
	"extra rules for SecurityPlugin"

	super configureSecurityPlugin: maker.
	
	maker addPlatformSources: #( 'sqWin32Security')



]

{ #category : #'plugin extra rules' }
SqueakCogFamilyWindowsConfig >> configureSerialPlugin:     maker [ 
	"extra rules for SerialPlugin "

	super configureSerialPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32SerialPort.c')



]

{ #category : #'plugin extra rules' }
SqueakCogFamilyWindowsConfig >> configureSocketPlugin:  maker [ 
	"extra rules for SocketPlugin "

	super configureSocketPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32NewNet.c')



]

{ #category : #'plugin extra rules' }
SqueakCogFamilyWindowsConfig >> configureSoundPlugin: maker [ 
	"extra rules for SoundPlugin"
	
	maker addPlatformSources: #( 'sqWin32Sound' )
]

{ #category : #'plugin extra rules' }
SqueakCogFamilyWindowsConfig >> configureSqueakSSLPlugin: maker [
	| lib |
	maker addPlatformSources: #('sqUnixOpenSSL.c').
	
	lib := self addThirdpartyLibrary: 'openssl'.

	maker includeDirectories: lib includeDir.
	maker linkDirectories: '${outputDir}'.
	
	maker addExternalLibraries: 
		#( 
			'libeay32.dll' 
			'ssleay32.dll'
		).
		
	maker addDependency: lib buildTarget

]

{ #category : #'plugin extra rules' }
SqueakCogFamilyWindowsConfig >> configureUUIDPlugin: maker [ 
	"extra rules for UUIDPlugin"
	
	maker addPlatformSources:
		#( 'sqWin32UUID.c')



]

{ #category : #'plugin extra rules' }
SqueakCogFamilyWindowsConfig >> configureWin32OSProcessPlugin: maker [ 
	"extra rules for Win32OSProcessPlugin"

	maker includeDirectories: '${crossDir}/plugins/FilePlugin'.
	maker includeDirectories: '${crossDir}/plugins/SocketPlugin'.

]

{ #category : #accessing }
SqueakCogFamilyWindowsConfig >> executableType [
	^ 'WIN32'
]

{ #category : #accessing }
SqueakCogFamilyWindowsConfig >> externalModulesDir [
	"answer the location in VM bundle, where plugins and rest of dynamic libs will be copied,
	"
	^ '${outputDir}'
]

{ #category : #utils }
SqueakCogFamilyWindowsConfig >> fixLineEndsOf: string [
	^ string copyReplaceAll: String cr with: String crlf
]

{ #category : #public }
SqueakCogFamilyWindowsConfig >> generate [ 
	self generatePluginsList. 
	self generateLicense. 
	"^super generate"
	^CMakeVMGeneratorForSqueak generate:self    "Bypass CPlatformConfig generate to invoke our compatibility class"
]

{ #category : #'as yet unclassified' }
SqueakCogFamilyWindowsConfig >> generateLicense [ 
	self 
		write:  (self class licenseTemplate 
			format: { self version })
		toFile: 'LICENSE.txt'
	
]

{ #category : #'as yet unclassified' }
SqueakCogFamilyWindowsConfig >> generatePluginsList [ 
	self 
		write:  (self class pluginsTemplate 
			format: {
				self version. 
				String streamContents: [ :stream | self internalPlugins asStringOn: stream delimiter: String cr ].
				String streamContents: [ :stream | self externalPlugins asStringOn: stream delimiter: String cr ].
				self executableName })
		toFile: 'PLUGINS.txt'
	
]

{ #category : #accessing }
SqueakCogFamilyWindowsConfig >> msysPathFor: aPath [
	| path |
	self flag:'tty'. "code smell alert"
	^aPath isString
		ifTrue:[	path := aPath  copyReplaceAll: '\' with: '/'.]
		ifFalse:[	path := aPath pathName copyReplaceAll: '\' with: '/'.]

	

]

{ #category : #directories }
SqueakCogFamilyWindowsConfig >> outputDir [

	"the directory where built binaries will be stored"

	^ outputDir ifNil: [ outputDir := self msysPathFor: (self topDir / self outputDirName) ]
]

{ #category : #accessing }
SqueakCogFamilyWindowsConfig >> platformName [
	^ 'win32'
]

{ #category : #'source generation' }
SqueakCogFamilyWindowsConfig >> prepareVMMaker [
	
	| maker allPlugins |
	
	"In CogVMs (in contrast to Interpreter VM) the generated sources are platform independent, therefore Cross is ok"
	maker := VMMaker forPlatform: 'Cross'.
	
	maker sourceDirectoryName: self srcDir pathName.
	maker platformRootDirectoryName: self platformsDir.
	
	
	allPlugins := self internalPlugins , self externalPlugins.
	
	"touch plugins to force their source generation unconditionally"
	allPlugins do: [:name | (Smalltalk globals at: name) touch ].
	
	" Why we put all plugins as external?   Because the generated sources are not different whether the plugins were defined as internal or external. VMMaker used to need this to to generate plugins.int and plugins.ext files. But since this is achieved in another way with CMakeVMMaker, there is no different at all to put all plugins as internal or as external."
	maker externalModules addAll:  allPlugins.
	
	^ maker
]

{ #category : #directories }
SqueakCogFamilyWindowsConfig >> setupDirectories: gen [
	"we have to override that, because we need to convert windoze paths to msys ones"
	| dirsInclude |
	
	" write the directories in separate include file"
	dirsInclude := gen captureOutputDuring: [
		gen
			set: #topDir toString: (self msysPathFor: self topDir fullName); 
			set: #buildDir toString: (self buildDir ifNil: ['${topDir}/build'] ifNotNil:[ self msysPathFor: self buildDir fullName ]);
			set: #thirdpartyDir toString: '${buildDir}/thirdparty';
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

	self write: dirsInclude toFile: 'directories.cmake'.
	
	gen include: 'directories.cmake'.
	
	gen set: #externalModulesDir toString: self externalModulesDir.

]

{ #category : #accessing }
SqueakCogFamilyWindowsConfig >> srcDir [
		^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'src' )]
]

{ #category : #directories }
SqueakCogFamilyWindowsConfig >> topDir [
	^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: 'oscogvm' ]
]

{ #category : #'source generation' }
SqueakCogFamilyWindowsConfig >> validateSourcesPresent [
	| sources |
	sources := Smalltalk sourcesName.
	
	(sources == nil)
		ifTrue: [	self error: 'VM source code cannot be generated without .sources file'.]		
]

{ #category : #'as yet unclassified' }
SqueakCogFamilyWindowsConfig >> version [
	^ ''
]

{ #category : #accessing }
SqueakCogFamilyWindowsConfig >> winVer [
	"Set minimum version to WindowsXP (see /cygwin/usr/include//w32api/w32api.h)"
	
	^ '-D_WIN32_WINNT=0x0501 -DWINVER=0x0501'
]
