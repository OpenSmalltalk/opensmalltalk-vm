"
A Linux64x86w32BitConfig is an Abstract base class that provides common information for my subclasses.
I am not meant to be built.

I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakLinux64x86w32CompatBuilder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	enableMessageTracking: true;
	generateByTemplate.



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
Linux64x86w32BitConfig >> addVMPluginsBuild: aMaker [
	|temp o|
	self flag:'tty'. "I am writing sub-directory CMakeLists.txt here. Should I also write the config.cmake files?"
	enabledebugmessages
		ifTrue: [templates  "this message will go to the top level CMakeLists.txt file"
				addLast: (CMakeMessage new message: self class name , 'addVMPluginsBuild: aMaker')].
	vmplugins do:[ :vmp |                    
		o := String new writeStream.   "each VMPlugin gets its own CMakeLists.txt file in its own directory"
		temp := OrderedCollection new.	
		temp
			addAllLast:((CMakePluginVm new)    "this is the CMakeCompositTemplate"
					config: self 
					definitions: (vmp compilerdefinitions)
					module: (vmp module)
					sources: (vmp sources)
					includedirectories: (vmp includedirectories)).
		temp do: [:each |  o nextPutAll: (each content); cr].
	((self buildDir) directoryExists: (vmp module))
		ifFalse:[	(self buildDir) createDirectory: (vmp module)].
		self write: (o contents) toFile: vmp module , FileDirectory slash , aMaker outputFileName.
		templates   "this will go to the top level CMakeLists.txt file"
			addLast: ((CMakeAddSubDirectory new) sourcedir: (vmp module)) 
	].










]

{ #category : #cmake }
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
Linux64x86w32BitConfig >> coreSourcesBuildMultiThreaded [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'cointerpmt.c'
		)
]

{ #category : #plugins }
Linux64x86w32BitConfig >> customizeCMakeVMDisplayNull [
	|module|
	module := vmplugins detect: [:vmd | #CMakeVMDisplayNull = ((vmd class name) asSymbol)] ifNone:[nil].  "error handling?"
	module 
		sources: #('${targetPlatform}/vm-display-null/sqUnixDisplayNull') ;
		compilerdefinitions:(OrderedCollection with: '-fPIC' with: '-DPIC');
		compilerflags: (self compilerFlags);
		externallibraries: #();
		linkerflags: (self linkerFlags);
		includedirectories:(OrderedCollection 
										with:'${crossDir}/plugins/FilePlugin' 
										with: '${targetPlatform}/plugins/B3DAcceleratorPlugin'  
 									     with: '${crossDir}/plugins/B3DAcceleratorPlugin').
	self flag:'tty'. "I don't think includedirectories is correct. revisit"







]

{ #category : #plugins }
Linux64x86w32BitConfig >> customizeCMakeVMDisplayX11 [
	|module|
	module := vmplugins detect: [:vmd | #CMakeVMDisplayX11 = ((vmd class name) asSymbol)] ifNone:[nil].  "error handling?"
	module 
		sources: #( '${targetPlatform}/vm-display-X11/sqUnixX11' '${targetPlatform}/vm-display-X11/sqUnixMozilla' );
		compilerdefinitions:(OrderedCollection with: '-fPIC' with: '-DPIC');
		compilerflags: (self compilerFlags);
		externallibraries: (self externalLibraries);
		linkerflags: (self linkerFlags);
		includedirectories:(OrderedCollection 
										with:'${crossDir}/plugins/FilePlugin' 
										with: '${targetPlatform}/plugins/B3DAcceleratorPlugin'  
 									     with: '${crossDir}/plugins/B3DAcceleratorPlugin').

]

{ #category : #plugins }
Linux64x86w32BitConfig >> customizeCMakeVMSoundALSA [
	|module|
	module := vmplugins detect: [:vmd | #CMakeVMSoundALSA = ((vmd class name) asSymbol)] ifNone:[nil].  "error handling?"
	module 
		sources: #( '${targetPlatform}/vm-sound-ALSA/sqUnixSoundALSA' );
		compilerdefinitions:(OrderedCollection with: '-fPIC' with: '-DPIC');
		compilerflags: (self compilerFlags);
		externallibraries: (self externalLibraries);
		linkerflags: (self linkerFlags);
		includedirectories: #().
	
]

{ #category : #plugins }
Linux64x86w32BitConfig >> customizeCMakeVMSoundNull [
	|module|
	module := vmplugins detect: [:vmd | #CMakeVMSoundNull = ((vmd class name) asSymbol)] ifNone:[nil].  "error handling?"
	module 
		sources: #( '${targetPlatform}/vm-sound-null/sqUnixSoundNull' );
		compilerdefinitions:(OrderedCollection with: '-fPIC' with: '-DPIC');
		compilerflags: (self compilerFlags);
		externallibraries: (self externalLibraries);
		linkerflags: (self linkerFlags);
		includedirectories:#()


]

{ #category : #plugins }
Linux64x86w32BitConfig >> customizeVMPlugins [
	|mysubset iwantonly|
	"trim the vmdrivers ordered collection of CMakeVMDriver subclasses to only those I want. then customize them for use on this OS/platform"
	iwantonly :=	 #(#CMakeVMDisplayNull  #CMakeVMDisplayX11  #CMakeVMSoundALSA  #CMakeVMSoundNull ).
	mysubset := vmplugins select: [:vmd | 0 < (iwantonly occurrencesOf: (vmd class name) asSymbol)]. 
	vmplugins := mysubset.
	self 
		customizeCMakeVMDisplayNull;
		customizeCMakeVMDisplayX11;
		customizeCMakeVMSoundALSA;
		customizeCMakeVMSoundNull.




]

{ #category : #plugins }
Linux64x86w32BitConfig >> defaultExternalPlugins [
"developing template model for plugins one at a time"
	^ #()

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
Linux64x86w32BitConfig >> extraPluginSettingsBuild: aMaker [
	aMaker isExternal 
		ifTrue:[aMaker templates addLast:((CMakeSet new) variable:'LIBRARY_OUTPUT_PATH' value:'${outputDir}')].
	aMaker templates addLast:((CMakeSet new) variable:'linkFlags' quotedValue:'${linkFlags} -m32').


"	maker isExternal ifTrue: [
		maker set: 'LIBRARY_OUTPUT_PATH' to: '${outputDir}' 
	].
	maker set: #linkFlags toString: '${linkFlags} -m32'"
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> internalPluginsBuild [
	^ internalPlugins ifNil: [ internalPlugins := self defaultInternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> postBuildActionsBuild: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActionsBuild:'"
	(aMaker config enabledebugmessages)
		ifTrue:[	
	aMaker config templates 
		addLast: ((CMakeMessage new) message: (self class name), ' postBuildActionsBuild' )
	].
	aMaker config templates 
		addLast: ((CMakeMessage new) message: 'postBuildActionsBuild: aMaker' );
		addLast:((CMakeCommand new) command:'include' params:'config.cmake');                                                 "cmake --help-command include "
		addLast:((CMakeCommand new) command:'LIST' params:'REMOVE_DUPLICATES config_vars');                      "cmake --help-command LIST"
		addLast:((CMakeCommand new) command:'FILE' params:'WRITE ${CMAKE_BINARY_DIR}/config.h.in ""');          "cmake --help-command FILE"
		addLast:(CMakeAppendConfigHIn new);
		addLast:((CMakeCommand new) command:'CONFIGURE_FILE' params:'${CMAKE_BINARY_DIR}/config.h.in ${CMAKE_BINARY_DIR}/config.h');
		addLast:((CMakeCommand new) command:'GET_CMAKE_PROPERTY' params:'tmp VARIABLES');
		addLast:((CMakeCommand new) command:'LIST' params:'REMOVE_ITEM tmp tmp');
		addLast:((CMakeCommand new) command:'LIST' params:'SORT tmp');
		addLast:((CMakeCommand new) command:'FILE' params:'WRITE ${CMAKE_BINARY_DIR}/config.h.status ""');
		addLast:(CMakeAppendConfigStatus new).


]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> preferredIncludesBuild [
	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: (self class name), ' preferredIncludesBuild' )
	].
	templates
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${targetPlatform}/plugins/B3DAcceleratorPlugin')).

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
