"
tty. Don't use me until I am refactored for this platform

I am not sure what this does yet. I have put this here to keep a consistent pattern of top level configuration per platform.
I need to be configured for the job I am advertised to do.

I am not meant to be built.

SqueakMacOSPowerPCBuilder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp
"
Class {
	#name : #SqueakMacOSXPowerPCConfig,
	#superclass : #SqueakMacintoshConfig,
	#category : #'CMakeVMMakerSqueak-MacOSPowerPC'
}

{ #category : #'as yet unclassified' }
SqueakMacOSXPowerPCConfig class >> licenseTemplate [
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
SqueakMacOSXPowerPCConfig class >> pluginsTemplate [
	^'Squeak {1} ships with the following plugins already built:
		
Internal: 
=========
{2}

External: 
=========
{3}

'
]

{ #category : #'cmake configuration' }
SqueakMacOSXPowerPCConfig >> availableBuildTypes [
	 ^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes
"	subclasses should use

  ^super availableBuildTypes copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))   "
	

]

{ #category : #accessing }
SqueakMacOSXPowerPCConfig >> cMakeMacros [ 
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
SqueakMacOSXPowerPCConfig >> configureB3DAcceleratorPlugin: maker [
	"extra rules for B3DAcceleratorPlugin"
	
	super configureB3DAcceleratorPlugin: maker.  
	
	maker 
		includeDirectories: '/usr/X11/include';  "for GL.h"
		addPlatformSources: #( 'sqMacOpenGL.c' 'sqMacOpenGLInfo.c')

]

{ #category : #'plugin extra rules' }
SqueakMacOSXPowerPCConfig >> configureClipboardExtendedPlugin: maker [
	
]

{ #category : #'plugin extra rules' }
SqueakMacOSXPowerPCConfig >> configureCroquetPlugin: maker [ 
	"extra rules for CroquetPlugin"

	super configureCroquetPlugin: maker.  
	maker addPlatformSources: #('sqMacCroquet.c').

]

{ #category : #'plugin extra rules' }
SqueakMacOSXPowerPCConfig >> configureFFIPlugin: maker [
	super configureFFIPlugin: maker.
	maker addPlatformSources: #( "'sqMacIntel-Win32.c'"
		'x86-sysv-MacIntel.c'
		'x86-sysv-asm-MacIntel.S'
	)
]

{ #category : #'plugin extra rules' }
SqueakMacOSXPowerPCConfig >> configureFT2Plugin: maker [
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
SqueakMacOSXPowerPCConfig >> configureInternetConfigPlugin: maker [
	"extra rules for InternetConfigPlugin"
	
	super configureInternetConfigPlugin: maker.  
	maker addPlatformSources: #( 'sqMacInternetConfiguration.c')

]

{ #category : #'plugin extra rules' }
SqueakMacOSXPowerPCConfig >> configureJoystickTabletPlugin: maker [ 
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
SqueakMacOSXPowerPCConfig >> configureLocalePlugin: maker [ 
	"extra rules for LocalePlugin"

	super configureLocalePlugin: maker.  
	maker addPlatformSources: #( 'sqMacLocaleCarbon.c' )

]

{ #category : #'plugin extra rules' }
SqueakMacOSXPowerPCConfig >> configureMIDIPlugin: maker [ 
	"extra rules for MIDIPlugin"

	super configureMIDIPlugin: maker.  
	maker addPlatformSources: #( 'sqMacMIDI.c')
]

{ #category : #'plugin extra rules' }
SqueakMacOSXPowerPCConfig >> configureMpeg3Plugin: maker [

	super configureMpeg3Plugin: maker.
	
	maker addPlatformSources: #(	
		'sqMacFileBits.c')
	
]

{ #category : #'plugin extra rules' }
SqueakMacOSXPowerPCConfig >> configureObjectiveCPlugin: maker [
	maker doNotGenerate: true
]

{ #category : #'plugin extra rules' }
SqueakMacOSXPowerPCConfig >> configurePlugin: aPlugin with: generator [

	generator isExternal ifTrue: [
		" set output directory for dynamic library to Resources subdir in .app bundle location "
		generator 
			set: 'CMAKE_LIBRARY_OUTPUT_DIRECTORY' 
			toString: '${externalModulesDir}'
		].
	^ super configurePlugin: aPlugin with: generator

]

{ #category : #'plugin extra rules' }
SqueakMacOSXPowerPCConfig >> configureQuicktimePlugin: maker [
	
	maker includeDirectories: '${pluginPlatform}'.
	maker includeDirectories: '${crossDir}/plugins/SurfacePlugin'.
	
	" yes, this is not a typo , a file is named 'inteface' instead of 'interface' "

	maker addPlatformSources: #( 'sqMacQuicktimeInteface.c' ).
	
	maker addFrameworks: #( 'Carbon' 'QuickTime' ).
]

{ #category : #'plugin extra rules' }
SqueakMacOSXPowerPCConfig >> configureSecurityPlugin: maker [ 
	"extra rules for SecurityPlugin"

	super configureSecurityPlugin: maker.  
	maker includeDirectories: '${crossDir}/plugins/FilePlugin'.
	maker addPlatformSources: #( 'sqMacSecurity.c' )
]

{ #category : #'plugin extra rules' }
SqueakMacOSXPowerPCConfig >> configureSerialPlugin: maker [ 
	"extra rules for SerialPlugin"

	super configureSoundPlugin: maker.  
	maker includeDirectories: '${platformsDir}/unix/plugins/SerialPlugin'.
	maker 
		addSources: #('sqUnixSerial.c') 
		prefixed: '${platformsDir}/unix/plugins/SerialPlugin/'



]

{ #category : #'plugin extra rules' }
SqueakMacOSXPowerPCConfig >> configureSocketPlugin: maker [ 
	"extra rules for SoundPlugin"

	super configureSoundPlugin: maker.  
	maker includeDirectories: '${platformsDir}/unix/plugins/SocketPlugin'.
	maker 
		addSources: #('sqUnixSocket.c') 
		prefixed: '${platformsDir}/unix/plugins/SocketPlugin/'



]

{ #category : #'plugin extra rules' }
SqueakMacOSXPowerPCConfig >> configureSoundGenerationPlugin: maker [ 
	"extra rules for SoundPlugin"

	maker doNotGenerate: true. 
	" The sources in platforms/Cross/plugins/SoundGenerationPlugin/sqOldSoundPrims.c 
	are out of date and need to be fixed before it can be built 
	
	
	maker 
		addCrossSources: #('sqOldSoundPrims.c') 

	"

]

{ #category : #'plugin extra rules' }
SqueakMacOSXPowerPCConfig >> configureTestOSAPlugin: maker [
		
	maker addFrameworks: #( 'Carbon'  'ApplicationServices' ).
]

{ #category : #'plugin extra rules' }
SqueakMacOSXPowerPCConfig >> configureUnixOSProcessPlugin: maker [ 
	"extra rules for UnixOSProcessPlugin"

	maker includeDirectories: '${crossDir}/plugins/FilePlugin'.

]

{ #category : #plugins }
SqueakMacOSXPowerPCConfig >> defaultExternalPlugins [

	^ #(
		BochsIA32Plugin
		CroquetPlugin
		ThreadedIA32FFIPlugin "SqueakFFIPrims"
		FloatArrayPlugin
		FloatMathPlugin
		Mpeg3Plugin
		QuicktimePlugin
"		TestOSAPlugin  - not works"
		"UnixOSProcessPlugin ?? "
		)
]

{ #category : #plugins }
SqueakMacOSXPowerPCConfig >> defaultInternalPlugins [

	^ #(
		ADPCMCodecPlugin
		AsynchFilePlugin
		B3DAcceleratorPlugin
		BalloonEnginePlugin "B2DPlugin" 
		BitBltSimulation "BitBltPlugin"
		BMPReadWriterPlugin
		DeflatePlugin  "ZipPlugin"
		DropPlugin
		DSAPlugin "DSAPrims"
		FFTPlugin
		FilePlugin
		HostWindowPlugin
		IA32ABIPlugin "IA32ABI"
		InternetConfigPlugin
		JoystickTabletPlugin
		JPEGReaderPlugin
		JPEGReadWriter2Plugin
		KlattSynthesizerPlugin "Klatt"
		LargeIntegersPlugin "LargeIntegers"
		LocalePlugin
		MacMenubarPlugin
		Matrix2x3Plugin
		MIDIPlugin
		MiscPrimitivePlugin
		QVMProfileMacSupportPlugin
		RePlugin
		SecurityPlugin
		SerialPlugin
		SocketPlugin
		SoundCodecPlugin "SoundCodecPrims"
		SoundGenerationPlugin
		SoundPlugin
		StarSqueakPlugin
		SurfacePlugin
		UUIDPlugin
		)
]

{ #category : #'cmake directory ' }
SqueakMacOSXPowerPCConfig >> dirBuildPlatform [	
	^self dirMacOSPowerPC
]

{ #category : #cmake }
SqueakMacOSXPowerPCConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
SqueakMacOSXPowerPCConfig >> executableName [
	"AbstractBaseClass configurations are not meant to be executable"
	^ self vmIShouldNotBeHereExecutableName
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> externalPluginsBuild [
	^ externalPlugins ifNil: [ externalPlugins := self defaultExternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> externalPluginsBuildAssert [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> externalPluginsBuildAssertITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> externalPluginsBuildDebug [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> externalPluginsBuildDebugITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> externalPluginsBuildITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> externalPluginsBuildMultiThreaded [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> externalPluginsBuildMultiThreadedAssert [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> externalPluginsBuildMultiThreadedDebug [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> extraPluginSettingsBuild: aMaker [
	"default browseMethodsWhoseNamesContain: 'extraPluginSettingsBuild' "
	self subclassResponsibility.
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> extraPluginSettingsBuildAssert: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> extraPluginSettingsBuildAssertITimerHeartbeat: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> extraPluginSettingsBuildDebug: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> extraPluginSettingsBuildDebugITimerHeartbeat: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> extraPluginSettingsBuildITimerHeartbeat: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> extraPluginSettingsBuildMultiThreaded: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> extraPluginSettingsBuildMultiThreadedAssert: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> extraPluginSettingsBuildMultiThreadedDebug: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> extraVMSettingsBuild: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettingsBuild:'"

	"Cog currently runs only in 32 bit mode" 
	aMaker set: 'CMAKE_OSX_ARCHITECTURES' to: 'i386'.

	aMaker set: 'resourceDir' toString: ((self resourcesDir pathName), FileDirectory slash, 'ProjectBuilder').
	aMaker set: 'resources' to: 
		'"${resourceDir}/Squeak VM.r"
		"${resourceDir}/Cog.icns"
		"${resourceDir}/Squeak.icns"
		"${resourceDir}/SqueakChanges.icns"
		"${resourceDir}/SqueakImage.icns"
		"${resourceDir}/SqueakPlugin.icns"
		"${resourceDir}/SqueakScript.icns"
		"${resourceDir}/SqueakGeneric.icns"
		"${resourceDir}/SqueakProject.icns"
		"${resourceDir}/SqueakSources.icns"'

]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> extraVMSettingsBuildAssert: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> extraVMSettingsBuildAssertITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> extraVMSettingsBuildDebug: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> extraVMSettingsBuildDebugITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> extraVMSettingsBuildITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> extraVMSettingsBuildMultiThreaded: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> extraVMSettingsBuildMultiThreadedAssert: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> extraVMSettingsBuildMultiThreadedDebug: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #utils }
SqueakMacOSXPowerPCConfig >> fixLibsTemplate [

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

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> internalPluginsBuild [
	^ internalPlugins ifNil: [ internalPlugins := self defaultInternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> internalPluginsBuildAssert [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> internalPluginsBuildAssertITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> internalPluginsBuildDebug [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> internalPluginsBuildDebugITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> internalPluginsBuildITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> internalPluginsBuildMultiThreaded [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> internalPluginsBuildMultiThreadedAssert [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> internalPluginsBuildMultiThreadedDebug [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> postBuildActionsBuild: gen [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActionsBuild:'"
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> postBuildActionsBuildAssert: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> postBuildActionsBuildAssertITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> postBuildActionsBuildDebug: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> postBuildActionsBuildDebugITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> postBuildActionsBuildITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> postBuildActionsBuildMultiThreaded: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> postBuildActionsBuildMultiThreadedAssert: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> postBuildActionsBuildMultiThreadedDebug: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'source files' }
SqueakMacOSXPowerPCConfig >> preferredIncludesBuild [
"SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'"
	^ #( )

	

]

{ #category : #'source files' }
SqueakMacOSXPowerPCConfig >> preferredIncludesBuildAssert [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
SqueakMacOSXPowerPCConfig >> preferredIncludesBuildAssertITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
SqueakMacOSXPowerPCConfig >> preferredIncludesBuildDebug [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
SqueakMacOSXPowerPCConfig >> preferredIncludesBuildDebugITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
SqueakMacOSXPowerPCConfig >> preferredIncludesBuildITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
SqueakMacOSXPowerPCConfig >> preferredIncludesBuildMultiThreaded [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
SqueakMacOSXPowerPCConfig >> preferredIncludesBuildMultiThreadedAssert [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
SqueakMacOSXPowerPCConfig >> preferredIncludesBuildMultiThreadedDebug [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> setGlobalOptionsAfterDetermineSystemBuild: aMaker [
	self flag: 'tty'. "I do not know if this is appropriate for MacOSX32x86. It is in IOS, so I figured what the heck.
	
	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsAfterDetermineSystemBuild:'
	"
	aMaker set: 'CMAKE_OSX_DEPLOYMENT_TARGET' to: '10.5'.
	aMaker 
		set: 'CMAKE_OSX_SYSROOT' 
		to: '/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX', self sdkVersion, '.sdk'
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> setGlobalOptionsAfterDetermineSystemBuildAssert: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> setGlobalOptionsAfterDetermineSystemBuildAssertITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> setGlobalOptionsAfterDetermineSystemBuildDebug: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> setGlobalOptionsAfterDetermineSystemBuildDebugITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> setGlobalOptionsAfterDetermineSystemBuildITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> setGlobalOptionsAfterDetermineSystemBuildMultiThreaded: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedAssert: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedDebug: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> setGlobalOptionsBuild: aMaker [
	"does nothing. included for framework consistency/testing 
	
	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsBuild'
	"
	
]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> setGlobalOptionsBuildAssert: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> setGlobalOptionsBuildAssertITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> setGlobalOptionsBuildDebug: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> setGlobalOptionsBuildDebugITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> setGlobalOptionsBuildITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> setGlobalOptionsBuildMultiThreaded: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> setGlobalOptionsBuildMultiThreadedAssert: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
SqueakMacOSXPowerPCConfig >> setGlobalOptionsBuildMultiThreadedDebug: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'source files' }
SqueakMacOSXPowerPCConfig >> standardIncludesBuild [ 
	^ #(
	'${crossDir}/plugins/SerialPlugin'   
	'${targetPlatform}/plugins/FilePlugin'
	'${crossDir}/plugins/FilePlugin'
	'${targetPlatform}/plugins/HostWindowPlugin'
	'${platformsDir}/iOS/vm/iPhone/plugins/HostWindowPlugin' 
	'${crossDir}/plugins/HostWindowPlugin'
	'${crossDir}/plugins/DropPlugin'
	'${crossDir}/plugins/SocketPlugin'
	'${crossDir}/plugins/SoundPlugin'
	'${crossDir}/plugins/AsynchFilePlugin'
	'${platformsDir}/unix/vm'
	'${platformsDir}/iOS/plugins/SoundPlugin'
	'${platformsDir}/iOS/vm/OSX/plugins/SoundPlugin'
	'${platformsDir}/iOS/vm/Common/Classes'
	'${platformsDir}/iOS/vm/OSX'
)
	
]

{ #category : #'source files' }
SqueakMacOSXPowerPCConfig >> standardIncludesBuildAssert [ 
	^ self standardIncludesBuild
]

{ #category : #'source files' }
SqueakMacOSXPowerPCConfig >> standardIncludesBuildAssertITimerHeartbeat [ 
	^ self standardIncludesBuild
]

{ #category : #'source files' }
SqueakMacOSXPowerPCConfig >> standardIncludesBuildDebug [ 
	^ self standardIncludesBuild
]

{ #category : #'source files' }
SqueakMacOSXPowerPCConfig >> standardIncludesBuildDebugITimerHeartbeat [
	^self standardIncludesBuild

]

{ #category : #'source files' }
SqueakMacOSXPowerPCConfig >> standardIncludesBuildITimerHeartbeat [ 
	^ self standardIncludesBuild
]

{ #category : #'source files' }
SqueakMacOSXPowerPCConfig >> standardIncludesBuildMultiThreaded [ 
	^ self standardIncludesBuild
]

{ #category : #'source files' }
SqueakMacOSXPowerPCConfig >> standardIncludesBuildMultiThreadedAssert [ 
	^ self standardIncludesBuild
]

{ #category : #'source files' }
SqueakMacOSXPowerPCConfig >> standardIncludesBuildMultiThreadedDebug [ 
	^ self standardIncludesBuild
]
