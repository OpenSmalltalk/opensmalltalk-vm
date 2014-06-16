"
tty. This layer is should be merged with it's parent.

This is an abstract class for all Mac Carbon configurations. It is intended to share code between different concrete implementations. 

It is using a Carbon framework , which eventually will be replaced by Cocoa. (see CocoaIOSConfig and its subclasses).


I am not meant to be built.

SqueakMacOSBuilder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp

"
Class {
	#name : #SqueakMacOSV3Config,
	#superclass : #SqueakMacOSConfig,
	#instVars : [
		'resourcesDir'
	],
	#category : #'CMakeVMMakerSqueak-MacOS'
}

{ #category : #'as yet unclassified' }
SqueakMacOSV3Config class >> licenseTemplate [
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
SqueakMacOSV3Config class >> pluginsTemplate [
	^'Squeak {1} ships with the following plugins already built:
		
Internal: 
=========
{2}

External: 
=========
{3}

'
]

{ #category : #directories }
SqueakMacOSV3Config >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #'build script' }
SqueakMacOSV3Config >> buildScript [
	"answer the build script for building everything"
	

	^ 
'#!/usr/bin/env bash

cmake .
make
make install

'
]

{ #category : #accessing }
SqueakMacOSV3Config >> cMakeMacros [ 
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

{ #category : #accessing }
SqueakMacOSV3Config >> compilerFlags [
	|d commonFlags flags|
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self compilerFlagsBuild];
		at: #buildAssert  put: [self compilerFlagsAssert];
		at: #buildAssertITimerHeartbeat  put: [self compilerFlagsAssertITimerHeartbeat];
            at:#buildDebug  put: [self compilerFlagsDebug];   "located in CMakeVMMaker CPlatformConfig"
		at: #buildDebugITimerHeartbeat  put: [self compilerFlagsDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self compilerFlagsIHeartbeatTimer];
		at: #buildMultiThreaded  put: [self compilerFlagsMultiThreaded ];
		at: #buildMultiThreadedAssert  put: [self compilerFlagsMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self compilerFlagsMultiThreadedDebug ];
		at: #buildNone put:[self compilerFlagsNoBuildType].

    flags:= String streamContents: [ :stream |
	 (((d at:  buildType) value)  collect: #withBlanksTrimmed as: Set)
		asStringOn: stream 
		delimiter:' '].

    commonFlags:=String streamContents: [ :stream |
		((self commonCompilerFlags) collect: #withBlanksTrimmed as: Set)
			asStringOn: stream 
			delimiter: ' ' ].
	^ commonFlags, ' ' ,flags.
]

{ #category : #'plugin extra rules' }
SqueakMacOSV3Config >> configureB3DAcceleratorPlugin: maker [
	"extra rules for B3DAcceleratorPlugin"
	
	super configureB3DAcceleratorPlugin: maker.  
	
	maker 
		includeDirectories: '/usr/X11/include';  "for GL.h"
		addPlatformSources: #( 'sqMacOpenGL.c' 'sqMacOpenGLInfo.c')

]

{ #category : #'plugin extra rules' }
SqueakMacOSV3Config >> configureClipboardExtendedPlugin: maker [
	
]

{ #category : #'plugin extra rules' }
SqueakMacOSV3Config >> configureCroquetPlugin: maker [ 
	"extra rules for CroquetPlugin"

	super configureCroquetPlugin: maker.  
	maker addPlatformSources: #('sqMacCroquet.c').

]

{ #category : #'plugin extra rules' }
SqueakMacOSV3Config >> configureFFIPlugin: maker [
	super configureFFIPlugin: maker.
	maker addPlatformSources: #( "'sqMacIntel-Win32.c'"
		'x86-sysv-MacIntel.c'
		'x86-sysv-asm-MacIntel.S'
	)
]

{ #category : #'plugin extra rules' }
SqueakMacOSV3Config >> configureFT2Plugin: maker [
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
SqueakMacOSV3Config >> configureInternetConfigPlugin: maker [
	"extra rules for InternetConfigPlugin"
	
	super configureInternetConfigPlugin: maker.  
	maker addPlatformSources: #( 'sqMacInternetConfiguration.c')

]

{ #category : #'plugin extra rules' }
SqueakMacOSV3Config >> configureJoystickTabletPlugin: maker [ 
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
SqueakMacOSV3Config >> configureLocalePlugin: maker [ 
	"extra rules for LocalePlugin"

	super configureLocalePlugin: maker.  
	maker addPlatformSources: #( 'sqMacLocaleCarbon.c' )

]

{ #category : #'plugin extra rules' }
SqueakMacOSV3Config >> configureMIDIPlugin: maker [ 
	"extra rules for MIDIPlugin"

	super configureMIDIPlugin: maker.  
	maker addPlatformSources: #( 'sqMacMIDI.c')
]

{ #category : #'plugin extra rules' }
SqueakMacOSV3Config >> configureMpeg3Plugin: maker [

	super configureMpeg3Plugin: maker.
	
	maker addPlatformSources: #(	
		'sqMacFileBits.c')
	
]

{ #category : #'plugin extra rules' }
SqueakMacOSV3Config >> configureObjectiveCPlugin: maker [
	maker doNotGenerate: true
]

{ #category : #'plugin extra rules' }
SqueakMacOSV3Config >> configurePlugin: aPlugin with: generator [

	generator isExternal ifTrue: [
		" set output directory for dynamic library to Resources subdir in .app bundle location "
		generator 
			set: 'CMAKE_LIBRARY_OUTPUT_DIRECTORY' 
			toString: '${externalModulesDir}'
		].
	^ super configurePlugin: aPlugin with: generator

]

{ #category : #'plugin extra rules' }
SqueakMacOSV3Config >> configureQuicktimePlugin: maker [
	
	maker includeDirectories: '${pluginPlatform}'.
	maker includeDirectories: '${crossDir}/plugins/SurfacePlugin'.
	
	" yes, this is not a typo , a file is named 'inteface' instead of 'interface' "

	maker addPlatformSources: #( 'sqMacQuicktimeInteface.c' ).
	
	maker addFrameworks: #( 'Carbon' 'QuickTime' ).
]

{ #category : #'plugin extra rules' }
SqueakMacOSV3Config >> configureSecurityPlugin: maker [ 
	"extra rules for SecurityPlugin"

	super configureSecurityPlugin: maker.  
	maker includeDirectories: '${crossDir}/plugins/FilePlugin'.
	maker addPlatformSources: #( 'sqMacSecurity.c' )
]

{ #category : #'plugin extra rules' }
SqueakMacOSV3Config >> configureSerialPlugin: maker [ 
	"extra rules for SerialPlugin"

	super configureSoundPlugin: maker.  
	maker includeDirectories: '${platformsDir}/unix/plugins/SerialPlugin'.
	maker 
		addSources: #('sqUnixSerial.c') 
		prefixed: '${platformsDir}/unix/plugins/SerialPlugin/'



]

{ #category : #'plugin extra rules' }
SqueakMacOSV3Config >> configureSocketPlugin: maker [ 
	"extra rules for SoundPlugin"

	super configureSoundPlugin: maker.  
	maker includeDirectories: '${platformsDir}/unix/plugins/SocketPlugin'.
	maker 
		addSources: #('sqUnixSocket.c') 
		prefixed: '${platformsDir}/unix/plugins/SocketPlugin/'



]

{ #category : #'plugin extra rules' }
SqueakMacOSV3Config >> configureSoundGenerationPlugin: maker [ 
	"extra rules for SoundPlugin"

	maker doNotGenerate: true. 
	" The sources in platforms/Cross/plugins/SoundGenerationPlugin/sqOldSoundPrims.c 
	are out of date and need to be fixed before it can be built 
	
	
	maker 
		addCrossSources: #('sqOldSoundPrims.c') 

	"

]

{ #category : #'plugin extra rules' }
SqueakMacOSV3Config >> configureTestOSAPlugin: maker [
		
	maker addFrameworks: #( 'Carbon'  'ApplicationServices' ).
]

{ #category : #'plugin extra rules' }
SqueakMacOSV3Config >> configureUnixOSProcessPlugin: maker [ 
	"extra rules for UnixOSProcessPlugin"

	maker includeDirectories: '${crossDir}/plugins/FilePlugin'.

]

{ #category : #accessing }
SqueakMacOSV3Config >> defaultDirectoriesFromGitDir: gitRepository [
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

{ #category : #cmake }
SqueakMacOSV3Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. default is squeak.cog.v3"
	^self required
]

{ #category : #cmake }
SqueakMacOSV3Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #accessing }
SqueakMacOSV3Config >> executableName [
	^ 'CogVM'
]

{ #category : #accessing }
SqueakMacOSV3Config >> externalModulesDir [
	"answer the location in VM bundle, where plugins and rest of dynamic libs will be copied,
	by default, it is Framerowks subdir. i.e: 
	
		Cog.app/Contents/Frameworks
		
	"
	
	^ '${outputDir}/', self executableName, '.app/Contents/MacOS/Plugins'
]

{ #category : #utils }
SqueakMacOSV3Config >> fixLibsTemplate [

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
SqueakMacOSV3Config >> fixLineEndsOf: string [
	^ string copyReplaceAll: String cr with: String lf
]

{ #category : #public }
SqueakMacOSV3Config >> generate [ 
	self generatePluginsList. 
	self generateLicense. 
	"^super generate"
	^CMakeVMGeneratorForSqueak generate:self    "Bypass CPlatformConfig generate to invoke our compatibility class"
]

{ #category : #'as yet unclassified' }
SqueakMacOSV3Config >> generateLicense [ 
	self 
		write:  (self class licenseTemplate 
			format: { self version })
		toFile: 'LICENSE.txt'
	
]

{ #category : #'as yet unclassified' }
SqueakMacOSV3Config >> generatePluginsList [ 
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
SqueakMacOSV3Config >> outputDir [

	"the directory where built binaries will be stored"
	^ outputDir ifNil: [ outputDir := (self topDir / self dirOutput/ self dirInstall) ]	


]

{ #category : #utils }
SqueakMacOSV3Config >> postBuildActions: gen [

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
SqueakMacOSV3Config >> prepareForGeneration [
	
]

{ #category : #'source generation' }
SqueakMacOSV3Config >> prepareVMMaker [
	
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

{ #category : #accessing }
SqueakMacOSV3Config >> resourcesDir [ 
	"Answer the value of resourcesDir"

	^ resourcesDir ifNil: [ resourcesDir := (self topDir / 'macbuild/resources') fullName ]
	
]

{ #category : #accessing }
SqueakMacOSV3Config >> resourcesDir: anObject [
	"Set the value of platformsDir"

	resourcesDir := anObject
]

{ #category : #accessing }
SqueakMacOSV3Config >> resourcesDirName [
	^ 'macbuild/resources'
]

{ #category : #'source generation' }
SqueakMacOSV3Config >> setupDirectories: gen [
	| dirsInclude |

	" write the directories in separate include file"
	dirsInclude := gen captureOutputDuring: [
		gen
			set: #topDir toString: (self topDir fullName); 
			set: #buildDir toString: (self buildDir ifNil: ['${topDir}/build'] ifNotNil: [self buildDir fullName] );
			set: #thirdpartyDir toString: '${buildDir}/thirdParty';
			set: #platformsDir toString: self platformsDir;
			set: #srcDir toString: self srcDir pathName;
			set: #srcPluginsDir toString: (pluginsDir ifNil: [ '${srcDir}/plugins' ]);
			set: #srcVMDir toString: '${srcDir}/vm';
			set: #platformName toString: self platformName;
			set: #targetPlatform to: '${platformsDir}/${platformName}';
			set: #crossDir toString: '${platformsDir}/Cross';
			set: #platformVMDir toString: '${targetPlatform}/vm';
			set: #outputDir toString: self outputDir fullName.
	].

	self write: dirsInclude toFile: 'directories.cmake'.
	
	gen include: 'directories.cmake'.

]

{ #category : #accessing }
SqueakMacOSV3Config >> srcDir [
		^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'src' )]
]

{ #category : #directories }
SqueakMacOSV3Config >> topDir [
		^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
]

{ #category : #'source generation' }
SqueakMacOSV3Config >> validateSourcesPresent [
	| sources |
	sources := Smalltalk sourcesName.
	
	(sources == nil)
		ifTrue: [	self error: 'VM source code cannot be generated without .sources file'.]		
]

{ #category : #'as yet unclassified' }
SqueakMacOSV3Config >> version [
	^ ''
]
