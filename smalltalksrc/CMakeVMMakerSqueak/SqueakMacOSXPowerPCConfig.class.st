"
N.B. Don't use me until I am refactored for this platform by somebody who owns a PowerPC. tty.

SqueakMacOSXPowerPCConfig iis an Abstract base class that provides common information for my subclasses.
I am not meant to be built.

I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakMacOSPowerPCBuilder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	enableMessageTracking: true;
	generateByTemplate.

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

{ #category : #cmake }
SqueakMacOSXPowerPCConfig >> availableBuildTypes [
	 ^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes
"	subclasses should use

  ^super availableBuildTypes copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))   "
	

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

{ #category : #cmake }
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
SqueakMacOSXPowerPCConfig >> extraVMSettingsBuild: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettingsBuild:'"
	(enabledebugmessages)
		ifTrue:[	templates 
		addLast:((CMakeMessage new) message: (self class name) , 'extraVMSettingsBuild: aMaker')
	] .
	templates
		addLast:((CMakeSet new) variable: 'CMAKE_OSX_ARCHITECTURES' value: 'i386');
		addLast:((CMakeSet new) variable: 'resourceDir' quotedValue: ((self resourcesDir pathName), FileDirectory slash, 'ProjectBuilder'));
		addLast:((CMakeSet new) 
			variable: 'resources' 
			value:'"${resourceDir}/Squeak VM.r"
		"${resourceDir}/Cog.icns"
		"${resourceDir}/Squeak.icns"
		"${resourceDir}/SqueakChanges.icns"
		"${resourceDir}/SqueakImage.icns"
		"${resourceDir}/SqueakPlugin.icns"
		"${resourceDir}/SqueakScript.icns"
		"${resourceDir}/SqueakGeneric.icns"
		"${resourceDir}/SqueakProject.icns"
		"${resourceDir}/SqueakSources.icns"').



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
SqueakMacOSXPowerPCConfig >> standardIncludesBuild [ 
	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: (self class name), ' standardIncludesBuild' )
	].
	templates
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${crossDir}/plugins/SerialPlugin'   ));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${targetPlatform}/plugins/FilePlugin'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${crossDir}/plugins/FilePlugin'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${targetPlatform}/plugins/HostWindowPlugin'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${platformsDir}/iOS/vm/iPhone/plugins/HostWindowPlugin' ));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with:  '${crossDir}/plugins/HostWindowPlugin'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${crossDir}/plugins/DropPlugin'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${crossDir}/plugins/SocketPlugin'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${crossDir}/plugins/SoundPlugin'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${crossDir}/plugins/AsynchFilePlugin'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${platformsDir}/unix/vm'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${platformsDir}/iOS/plugins/SoundPlugin'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${platformsDir}/iOS/vm/OSX/plugins/SoundPlugin'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${platformsDir}/iOS/vm/Common/Classes'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${platformsDir}/iOS/vm/OSX')).
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
