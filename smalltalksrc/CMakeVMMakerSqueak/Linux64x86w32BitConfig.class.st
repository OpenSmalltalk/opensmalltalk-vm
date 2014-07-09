"
I provide base class functionality.

I am not meant to be built.

SqueakLinux64x86w32CompatBuilder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp



"
Class {
	#name : #Linux64x86w32BitConfig,
	#superclass : #SqueakUnixConfig,
	#category : #'CMakeVMMakerSqueak-Linux64X86-32BitCompatibility'
}

{ #category : #accessing }
Linux64x86w32BitConfig class >> licenseTemplate [
	^'Squeak {1} license information
==============================

About Squeak
-----------
Squeak is a modern, open source, full-featured implementation of the powerful Smalltalk programming language and environment. Squeak is highly-portable, running on almost any platform you could name and you can really truly write once run anywhere.  Squeak is the vehicle for a wide range of projects from multimedia applications and educational platforms to commercial web application development.

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
cacheing and effective optimization of Smalltalk?s first-class activation records.  Cog is the virtual machine
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

{ #category : #accessing }
Linux64x86w32BitConfig class >> pluginsTemplate [
	^'{4} {1} ships with this plugins already built:
		
Internal: 
=========
{2}

External: 
=========
{3}

'
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> addVMDriversBuild: aMaker [
	aMaker message: 'addVMDrivers: aMaker'.
	 self 
		addDriver: 'vm-display-null' 
		sources: #( 
			'${targetPlatform}/vm-display-null/sqUnixDisplayNull' )
		generator: aMaker
		externalLibs: #();
		
		addDriver: 'vm-display-X11' 
		sources: #( 
			'${targetPlatform}/vm-display-X11/sqUnixX11'
			'${targetPlatform}/vm-display-X11/sqUnixMozilla' )
		generator: aMaker
		externalLibs: (self externalLibs);  "#( SM ICE GL X11 nsl dl); "

		addDriver: 'vm-sound-ALSA' 
		sources: #( 
			'${targetPlatform}/vm-sound-ALSA/sqUnixSoundALSA' )
		generator: aMaker
		externalLibs: #();

		addDriver: 'vm-sound-null' 
		sources: #( 
			'${targetPlatform}/vm-sound-null/sqUnixSoundNull' )
		generator: aMaker
		externalLibs: #().

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> addVMDriversBuildAssert: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> addVMDriversBuildAssertITimerHeartbeat: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> addVMDriversBuildDebug: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> addVMDriversBuildDebugITimerHeartbeat: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> addVMDriversBuildITimerHeartbeat: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> addVMDriversBuildMultiThreaded: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> addVMDriversBuildMultiThreadedAssert: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> addVMDriversBuildMultiThreadedDebug: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake configuration' }
Linux64x86w32BitConfig >> availableBuildTypes [
	 ^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes
"	subclasses should use

  ^super availableBuildTypes copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))   "
	

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> coreSourcesBuild [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
		)
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> coreSourcesBuildAssert [
	^self coreSourcesBuild	
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> coreSourcesBuildAssertITimerHeartbeat [
	^self coreSourcesBuild	
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> coreSourcesBuildDebug [
	^self coreSourcesBuild	
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> coreSourcesBuildDebugITimerHeartbeat [
	^self coreSourcesBuild	
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> coreSourcesBuildITimerHeartbeat [
	^self coreSourcesBuild	
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> coreSourcesBuildMultiThreaded [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'cointerpmt.c'
		)
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> coreSourcesBuildMultiThreadedAssert [
	^self coreSourcesBuildMultiThreaded	
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> coreSourcesBuildMultiThreadedDebug [
	^self coreSourcesBuildMultiThreaded	
]

{ #category : #sources }
Linux64x86w32BitConfig >> crossSources [ 
	^#(
			'sqHeapMap.c'
			'sqTicker.c'
			'sqExternalSemaphores.c'
			'sqNamedPrims.c'
			'sqVirtualMachine.c'
		)
]

{ #category : #plugins }
Linux64x86w32BitConfig >> defaultExternalPlugins [
	^ #(
		B3DAcceleratorPlugin
		ThreadedIA32FFIPlugin "SqueakFFIPrims"
		"UUIDPlugin"
		"UnixOSProcessPlugin ?? "	
		JPEGReaderPlugin 
		JPEGReadWriter2Plugin 			
		RePlugin
		InternetConfigPlugin
	)

"debug"
]

{ #category : #plugins }
Linux64x86w32BitConfig >> defaultInternalPlugins [
" took from unixbuild/bld/plugins.int"
	^ #(
		ADPCMCodecPlugin 
		AsynchFilePlugin 
		BalloonEnginePlugin "B2DPlugin" 
		BitBltSimulation "BitBltPlugin"
		BMPReadWriterPlugin 
		CroquetPlugin 
		DeflatePlugin  "ZipPlugin"
		DropPlugin 
		DSAPlugin "DSAPrims" 
		FFTPlugin 
		FileCopyPlugin 
		FilePlugin 
		FloatArrayPlugin 
		FloatMathPlugin 
		JoystickTabletPlugin 
		KlattSynthesizerPlugin "Klatt"
		LargeIntegersPlugin "LargeIntegers"
		Matrix2x3Plugin 
		MIDIPlugin 
		MiscPrimitivePlugin 
		Mpeg3Plugin  	
		SecurityPlugin 
		SerialPlugin 
		SocketPlugin 
		SoundCodecPlugin "SoundCodecPrims"
		SoundGenerationPlugin 
		SoundPlugin 
		StarSqueakPlugin 
		SurfacePlugin	
		LocalePlugin
		)
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirLinux32x8664
]

{ #category : #cmake }
Linux64x86w32BitConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
Linux64x86w32BitConfig >> executableName [
	"AbstractBaseClass configurations are not meant to be executable"
	^ self vmIShouldNotBeHereExecutableName
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> externalPluginsBuild [
	^ externalPlugins ifNil: [ externalPlugins := self defaultExternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> externalPluginsBuildAssert [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> externalPluginsBuildAssertITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> externalPluginsBuildDebug [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> externalPluginsBuildDebugITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> externalPluginsBuildITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> externalPluginsBuildMultiThreaded [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> externalPluginsBuildMultiThreadedAssert [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> externalPluginsBuildMultiThreadedDebug [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> extraPluginSettingsBuild: maker [
	self flag:'tty'. "this dumps the libs into the executable's directory. This breaks the distribution convention squeak has had for a while. However, we probably should handle that in a packaging/redistribution step and not worry about it now" 
	maker isExternal ifTrue: [
		"copy lib to outputDir "
		maker set: 'LIBRARY_OUTPUT_PATH' to: '${outputDir}' 
	].
	maker set: #linkFlags toString: '${linkFlags} -m32'
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> extraPluginSettingsBuildAssert: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> extraPluginSettingsBuildAssertITimerHeartbeat: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> extraPluginSettingsBuildDebug: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> extraPluginSettingsBuildDebugITimerHeartbeat: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> extraPluginSettingsBuildITimerHeartbeat: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> extraPluginSettingsBuildMultiThreaded: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> extraPluginSettingsBuildMultiThreadedAssert: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> extraPluginSettingsBuildMultiThreadedDebug: aMaker [
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> extraVMSettingsBuild: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettingsBuild:'"

	| versionC |
	aMaker message: 'extraVMSettingsBuild: aMaker'.
	"self generateConfigH.   supplanted by new auto generate of config"
	
	"add a generated version.c"
	
	versionC := 'version.c'.
	
	aMaker cmd: 'add_custom_command' params: 'OUTPUT ',
		versionC , '
		COMMAND ${platformsDir}/unix/config/verstamp ',versionC,' gcc
		COMMENT "Generating version.c"
	'.
	
	
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> extraVMSettingsBuildAssert: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> extraVMSettingsBuildAssertITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> extraVMSettingsBuildDebug: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> extraVMSettingsBuildDebugITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> extraVMSettingsBuildITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> extraVMSettingsBuildMultiThreaded: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> extraVMSettingsBuildMultiThreadedAssert: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> extraVMSettingsBuildMultiThreadedDebug: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> internalPluginsBuild [
	^ internalPlugins ifNil: [ internalPlugins := self defaultInternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> internalPluginsBuildAssert [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> internalPluginsBuildAssertITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> internalPluginsBuildDebug [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> internalPluginsBuildDebugITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> internalPluginsBuildITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> internalPluginsBuildMultiThreaded [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> internalPluginsBuildMultiThreadedAssert [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> internalPluginsBuildMultiThreadedDebug [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> postBuildActionsBuild: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActionsBuild:'"
	aMaker message: 'postBuildActionsBuild: aMaker'.
	aMaker  include: 'config.cmake'.
	"# CONFIGURE_PLUGINS"
	aMaker cmd: 'LIST' params:'REMOVE_DUPLICATES config_vars'.
	aMaker cmd: 'FILE' params: 'WRITE ${CMAKE_BINARY_DIR}/config.h.in ""'.
	aMaker puts:'
FOREACH (var ${config_vars})
  FILE (APPEND ${CMAKE_BINARY_DIR}/config.h.in "#cmakedefine ${var} @${var}@\n")
ENDFOREACH (var)'.
	aMaker cmd: 'CONFIGURE_FILE' params:'${CMAKE_BINARY_DIR}/config.h.in ${CMAKE_BINARY_DIR}/config.h'.
	"# INCLUDE(build.cmake) <--this tells me the config needs to be up higher
	# BUILD PLUGINS
	#ADD_SUBDIRECTORY (${unix}/npsqueak)
	#SET (cmake ${unix}/../../cmake)
	#IF (EXISTS ${cmake}/Packages.cmake)
	#  INCLUDE (${cmake}/Packages.cmake)
	#ENDIF ()
	"
	aMaker cmd: 'GET_CMAKE_PROPERTY' params: 'tmp VARIABLES'.
	aMaker cmd: 'LIST' params: 'REMOVE_ITEM tmp tmp'.
	aMaker cmd: 'LIST' params: 'SORT tmp'.
	aMaker cmd: 'FILE' params: 'WRITE ${CMAKE_BINARY_DIR}/config.h.status ""'.
	aMaker puts:'
FILE (WRITE ${CMAKE_BINARY_DIR}/config.status "")
FOREACH (var ${tmp})
  FILE (APPEND ${CMAKE_BINARY_DIR}/config.status "${var}=${${var}}\n")
ENDFOREACH ()'


]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> postBuildActionsBuildAssert: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> postBuildActionsBuildAssertITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> postBuildActionsBuildDebug: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> postBuildActionsBuildDebugITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> postBuildActionsBuildITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> postBuildActionsBuildMultiThreaded: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> postBuildActionsBuildMultiThreadedAssert: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> postBuildActionsBuildMultiThreadedDebug: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'source files' }
Linux64x86w32BitConfig >> preferredIncludesBuild [
	^ #(  '${targetPlatform}/plugins/B3DAcceleratorPlugin')


	

"SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'"
	
]

{ #category : #'source files' }
Linux64x86w32BitConfig >> preferredIncludesBuildAssert [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux64x86w32BitConfig >> preferredIncludesBuildAssertITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux64x86w32BitConfig >> preferredIncludesBuildDebug [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux64x86w32BitConfig >> preferredIncludesBuildDebugITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux64x86w32BitConfig >> preferredIncludesBuildITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux64x86w32BitConfig >> preferredIncludesBuildMultiThreaded [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux64x86w32BitConfig >> preferredIncludesBuildMultiThreadedAssert [
	^self preferredIncludesBuild

]

{ #category : #'source files' }
Linux64x86w32BitConfig >> preferredIncludesBuildMultiThreadedDebug [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setExtraTargetPropertiesBuild: aMaker [
	self flag:'tty'. "I am nervous about this method up here in this class, but pharo has it in CogUnixConfig, so using as is for now"

	aMaker setTargetProperties: 'LINK_FLAGS "-m32"'.
	aMaker puts: 'set_source_files_properties( ${srcVMDir}/cogit.c PROPERTIES 
		COMPILE_FLAGS "' , self compilerFlags , '")'.
		
	
	aMaker 
		cmd: 'set_source_files_properties'
		params: ' ${targetPlatform}/vm/sqUnixHeartbeat.c PROPERTIES 
		COMPILE_FLAGS "' , self compilerFlags , '"'.
	
	aMaker addExternalLibraries: (self externalLibs).

	aMaker set: 'EXECUTABLE_OUTPUT_PATH' toString: self outputDir fullName.
	self addVMDrivers: aMaker.
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setExtraTargetPropertiesBuildAssert: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setExtraTargetPropertiesBuildAssertITimerHeartbeat: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setExtraTargetPropertiesBuildDebug: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setExtraTargetPropertiesBuildDebugITimerHeartbeat: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setExtraTargetPropertiesBuildITimerHeartbeat: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setExtraTargetPropertiesBuildMultiThreaded: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setExtraTargetPropertiesBuildMultiThreadedAssert: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setExtraTargetPropertiesBuildMultiThreadedDebug: aMaker [
	^self setExtraTargetPropertiesBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setGlobalOptionsAfterDetermineSystemBuild: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsAfterDetermineSystemBuild:'"
	aMaker message: 'setGlobalOptionsAfterDetermineSystemBuild: aMaker'.	
	aMaker  
		include: 'Utils.cmake';
	      include: 'Plugins.cmake';
		include:	'TestBigEndian';
		include:	'CheckIncludeFile';
		include:	'CheckLibraryExists';
		include:	'CheckTypeSize';
		include:	'CheckFunctionExists';
		include:	'CheckVariableExists';
		include:	'CheckStructHasMember';
		include:	'FindPkgConfig'.


]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setGlobalOptionsAfterDetermineSystemBuildAssert: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setGlobalOptionsAfterDetermineSystemBuildAssertITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setGlobalOptionsAfterDetermineSystemBuildDebug: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setGlobalOptionsAfterDetermineSystemBuildDebugITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setGlobalOptionsAfterDetermineSystemBuildITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setGlobalOptionsAfterDetermineSystemBuildMultiThreaded: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedAssert: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedDebug: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setGlobalOptionsBuild: aMaker [
	aMaker message: 'setGlobalOptionsBuild: aMaker'.
"	aMaker linkDirectories: '/usr/lib'."

"	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions:'  "
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setGlobalOptionsBuildAssert: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setGlobalOptionsBuildAssertITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setGlobalOptionsBuildDebug: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setGlobalOptionsBuildDebugITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setGlobalOptionsBuildITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setGlobalOptionsBuildMultiThreaded: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setGlobalOptionsBuildMultiThreadedAssert: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> setGlobalOptionsBuildMultiThreadedDebug: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> standardIncludesBuild [ 
	^#()
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> standardIncludesBuildAssert [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> standardIncludesBuildAssertITimerHeartbeat [
	^self standardIncludesBuild

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> standardIncludesBuildDebug [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> standardIncludesBuildDebugITimerHeartbeat [
	^self standardIncludesBuild

]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> standardIncludesBuildITimerHeartbeat [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> standardIncludesBuildMultiThreaded [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> standardIncludesBuildMultiThreadedAssert [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> standardIncludesBuildMultiThreadedDebug [ 
	^ self standardIncludesBuild
]
