"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf


I am not meant to be built.

SqueakLinux32x86_64Builder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp

"
Class {
	#name : #Linux64Config,
	#superclass : #CogFamilyUnixConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#instVars : [
		'buildType',
		'generateBuild',
		'generateBuildAssert',
		'generateBuildAssertITimerHeartbeat',
		'generateBuildDebug',
		'generateBuildDebugITimerHeartbeat',
		'generateBuildDebugMultiThreaded',
		'generateBuildIHeartbeatTimer',
		'generateBuildMultiThreaded',
		'generateBuildMultiThreadedAssert',
		'generateBuildMultiThreadedDebug'
	],
	#category : #'CMakeVMMakerSqueak-LinuxX86-64'
}

{ #category : #accessing }
Linux64Config class >> licenseTemplate [
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
Linux64Config class >> pluginsTemplate [
	^'{4} {1} ships with this plugins already built:
		
Internal: 
=========
{2}

External: 
=========
{3}

'
]

{ #category : #'squeak compatibility' }
Linux64Config >> addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs [

	| cfg srcs |
	
	srcs := aSources inject: '' into: [:res :each | res , ' "', each, '"' ].
	cfg := cmakeGen
		captureOutputDuring: [
			cmakeGen printHeader;
			project: name;
			include: '../directories.cmake';
		
			message: 'Adding module: ', name;
			
			addDefinitions:  self compilerFlags;
			addDefinitions: '-fPIC -DPIC';
			set: #sources to: srcs;
			cmd: 'add_library' params: name, ' SHARED ${sources}'; 
			includeDirectories: '${crossDir}/plugins/FilePlugin';
			includeDirectories: '${targetPlatform}/plugins/B3DAcceleratorPlugin';
			includeDirectories: '${crossDir}/plugins/B3DAcceleratorPlugin';
			set: 'LIBRARY_OUTPUT_PATH' toString: self outputDir fullName;
			addExternalLibraries: extLibs;
			cmd: 'target_link_libraries' params: name , ' ${LINKLIBS}';
			cmd: 'set_target_properties' params: name , ' PROPERTIES PREFIX "" SUFFIX "" 
			LINK_FLAGS -m32' 
	].
	
	(self buildDir / name) assureExistence.
	self write: cfg toFile: name , '/', cmakeGen outputFileName.
	cmakeGen addSubdirectory:  name.
	
]

{ #category : #cmake }
Linux64Config >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default allBuildConfigurations copyWithoutAll:#(#releaseMultiThreadedFFI #debugMultiThreadedFFI)

]

{ #category : #'squeak compatibility' }
Linux64Config >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #'squeak compatibility' }
Linux64Config >> buildDirName [
	buildType isNil
		ifTrue:[^self dirBuildPlatform, FileDirectory slash, self dirBuildLanguageVMMM, FileDirectory slash, 'build']
		ifFalse:[^self dirBuildPlatform, FileDirectory slash, self dirBuildLanguageVMMM, FileDirectory slash, buildType asString]
]

{ #category : #'squeak compatibility' }
Linux64Config >> buildScript [
	"answer the build script for building everything"
	

	^ 
'#!/usr/bin/env bash

cmake .
make

'
]

{ #category : #'squeak compatibility' }
Linux64Config >> buildType: aSymbol [
	buildType:= aSymbol
]

{ #category : #'squeak compatibility' }
Linux64Config >> cogitClass [
	"answer a class for machine code generation or nil"
	
	^ StackToRegisterMappingCogit 
]

{ #category : #'squeak compatibility' }
Linux64Config >> commonCompilerFlags [

	"Common compiler flags
	
	
	LSB_FIRST=1 means that target platform is little endian. 
	set it to 0 for big-endian platforms
	
	"
	
	^ {
		'-DLSB_FIRST=1'. 
		'-DUSE_GLOBAL_STRUCT=0'. 
		'-DCOGMTVM=0'. 
		'-m32'.
		'-DENABLE_FAST_BLT ' } 	
	
]

{ #category : #'squeak compatibility' }
Linux64Config >> compilerFlags [
	|d commonFlags flags|
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self compilerFlagsBuild];
		at: #buildAssert  put: [self compilerFlagsAssert];
		at: #buildAssertITimerHeartbeat  put: [self compilerFlagsAssertITimerHeartbeat];
            at:#buildDebug  put: [self compilerFlagsDebug];   "located in CMakeVMMaker CPlatformConfig"
		at: #buildDebugITimerHeartbeat  put: [self compilerFlagsDebugITimerHeartbeat ];
		at: #buildDebugMultiThreaded  put: [self compilerFlagsDebugMultiThreaded];
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

{ #category : #'cmake configuration' }
Linux64Config >> configureForBuildType: aSymbol [
	| d |
	"provide a concrete builder with the buildType and configureBuildX method to invoke"
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	self configureNoBuildType.                "reset all internal flags"
	d 
		at: #build 
		put: [self buildType:#build.  self configureBuild];

		at: #buildAssert 
		put: [self buildType: #buildAssert.  	self configureBuildAssert];

		at: #buildAssertITimerHeartbeat 
		put:     [ self buildType: #buildAssertITimerHeartbeat.   self configureBuildAssertITimerHeartbeat];

            at:#buildDebug 
		put: [self buildType: #buildDebug.  self configureBuildDebug];

		at: #buildDebugITimerHeartbeat 
		put:  [self buildType: #buildDebugITimerHeartbeat.   self configureBuildDebugITimerHeartbeat];

		at: #buildDebugMultiThreaded 
		put: [self buildType: #buildDebugMultiThreaded.   self configureBuildDebugMultiThreaded];

		at: #buildITimerHeartbeat 
		put: [self buildType:#buildITimerHeartbeat.    self configureBuildIHeartbeatTimer];

		at: #buildMultiThreaded 
		put:  [self buildType:#buildMultiThreaded . self configureBuildMultiThreaded];

		at: #buildMultiThreadedAssert 
		put: [self buildType: #buildMultiThreadedAssert. self configureBuildMultiThreadedAssert];

		at: #buildMultiThreadedDebug  
		put: [self buildType: #buildMultiThreadedDebug. self configureBuildMultiThreadedDebug].

     ^(d at: aSymbol).
]

{ #category : #cmake }
Linux64Config >> configureNoBuildType [
		generateBuild:=generateBuildAssert:=generateBuildAssertITimerHeartbeat:=generateBuildDebug:=generateBuildDebugITimerHeartbeat:= generateBuildDebugMultiThreaded:= generateBuildIHeartbeatTimer:= generateBuildMultiThreaded:= generateBuildMultiThreadedAssert:= generateBuildMultiThreadedDebug:=false.
]

{ #category : #plugins }
Linux64Config >> defaultExternalPlugins [
	^ #(SqueakSSL	)
]

{ #category : #plugins }
Linux64Config >> defaultInternalPlugins [
" cut-n-paste from Cog/build.linux32x86/newspeak.cog.v3/build"
	^ #(
		AsynchFilePlugin 
		BMPReadWriterPlugin 
		B2DPlugin 
		BitBltPlugin 
		DSAPrims 
		DropPlugin 
		FileCopyPlugin 
		FilePlugin 
		FloatArrayPlugin 
		FloatMathPlugin 
		ZipPlugin 
		JPEGReadWriter2Plugin 
		JPEGReaderPlugin 
		LargeIntegers 
		Matrix2x3Plugin 
		MiscPrimitivePlugin 
		IA32ABI 
		RePlugin 
		SecurityPlugin 
		SocketPlugin 
		SurfacePlugin 
		UUIDPlugin 
		UnixOSProcessPlugin 
		VMProfileLinuxSupportPlugin)
]

{ #category : #cmake }
Linux64Config >> dirAndroid [
	^'Do Not Build. See Class Comment'
]

{ #category : #cmake }
Linux64Config >> dirBSD32x86 [
	^'cmake_build.bsd32x86'
]

{ #category : #cmake }
Linux64Config >> dirBuild [
	^'build'
]

{ #category : #cmake }
Linux64Config >> dirBuildAssert [
	^'build.assert'
]

{ #category : #cmake }
Linux64Config >> dirBuildDebug [
	^'build.debug'
]

{ #category : #cmake }
Linux64Config >> dirBuildDebugITimerHeartbeat [
	^'build.debug.itimerheartbeat'
]

{ #category : #cmake }
Linux64Config >> dirBuildITimerHeartbeat [
	^'build.itimerheartbeat'
]

{ #category : #cmake }
Linux64Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self required
]

{ #category : #cmake }
Linux64Config >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirLinux32x86
]

{ #category : #'squeak compatibility' }
Linux64Config >> dirFrom: aStringOrDir [
	^ aStringOrDir isString
		ifTrue: [ FileDirectory forFileName: aStringOrDir  ]
		ifFalse: [ aStringOrDir ]
]

{ #category : #cmake }
Linux64Config >> dirIA32Bochs [
	^'cmake_build.ia32bochs'
]

{ #category : #cmake }
Linux64Config >> dirIOS [
	^'cmake_build.ios'
]

{ #category : #cmake }
Linux64Config >> dirLinux32Armv6 [
	^'cmake_build.linux32armv6'
]

{ #category : #cmake }
Linux64Config >> dirLinux32x86 [
	^'cmake_build.linux32x86'
]

{ #category : #cmake }
Linux64Config >> dirLinux32x8664 [
	^'cmake_build.linux32x86_64'
]

{ #category : #cmake }
Linux64Config >> dirMacOS [
	^'cmake_build.macos'
]

{ #category : #cmake }
Linux64Config >> dirMacOSPowerPC [
	^'cmake_build.macospowerpc'
]

{ #category : #cmake }
Linux64Config >> dirMacOSX32x86 [
	^'cmake_build.macosx32x86'
]

{ #category : #cmake }
Linux64Config >> dirOutput [
	^'cmake_products'
]

{ #category : #cmake }
Linux64Config >> dirSource [
	^'src'
]

{ #category : #cmake }
Linux64Config >> dirSunOS32x86 [
	^'cmake_build.sunos32x86'
]

{ #category : #cmake }
Linux64Config >> dirSunOS32x8664 [
	^'cmake_build.sunos32x86_64'
]

{ #category : #cmake }
Linux64Config >> dirWin32x86 [
	^'cmake_build.win32x86'
]

{ #category : #cmake }
Linux64Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build"
	^true
]

{ #category : #'headers generation' }
Linux64Config >> generateConfigH [
	"	
	used to be: 	
		self write: self configH toFile: 'config.h'
      but with variable buildTypes we need:
"
	self write: (self generateConfigH: buildType) toFile: 'config.h'   

]

{ #category : #'initialize-release' }
Linux64Config >> initialize [
	super initialize.
	"this should be in my superclass, but I do not have permission to modify it. tty"
	 generateForAssert:= generateForAssertHeartbeatTimer:= generateForDebug :=generateForDebugWithHeartbeatTimer:= generateForDebugMultiThreadedFFI:= generateForReleaseHeartbeatTimer:= generateForReleaseMultiThreadedFFI:=false
]

{ #category : #cmake }
Linux64Config >> newspeakCogSpur [
	^'newspeak.cog.spur'
]

{ #category : #cmake }
Linux64Config >> newspeakCogV3 [
	^'newspeak.cog.v3'
]

{ #category : #cmake }
Linux64Config >> newspeakSistaSpur [
	^'newspeak.sista.Spur'
]

{ #category : #cmake }
Linux64Config >> newspeakSistaV3 [
	^'newspeak.sista.v3'
]

{ #category : #cmake }
Linux64Config >> newspeakStackSpur [
	^'newspeak.stack.spur'
]

{ #category : #cmake }
Linux64Config >> newspeakStackV3 [
	^'newspeak.stack.v3'
]

{ #category : #cmake }
Linux64Config >> oscogvm [
	^ 'oscogvm'
]

{ #category : #'squeak compatibility' }
Linux64Config >> outputDir [

	"the directory where built binaries will be stored"
	^ outputDir ifNil: [ outputDir := (self topDir / self dirOutput / self dirInstall) ]	


]

{ #category : #'squeak compatibility' }
Linux64Config >> prepareVMMaker [
	
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

{ #category : #'squeak compatibility' }
Linux64Config >> setupDirectories: gen [
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

{ #category : #cmake }
Linux64Config >> squeakCogSpur [
	^'squeak.cog.spur'
]

{ #category : #cmake }
Linux64Config >> squeakCogV3 [
	^'squeak.cog.v3'
]

{ #category : #cmake }
Linux64Config >> squeakSistaSpur [
	^'squeak.sista.Spur'
]

{ #category : #cmake }
Linux64Config >> squeakSistaV3 [
	^'squeak.sista.v3'
]

{ #category : #cmake }
Linux64Config >> squeakStackSpur [
	^'squeak.stack.spur'
]

{ #category : #cmake }
Linux64Config >> squeakStackV3 [
	^'squeak.stack.v3'
]

{ #category : #'squeak compatibility' }
Linux64Config >> srcDir [
		^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'src' )]
]

{ #category : #'squeak compatibility' }
Linux64Config >> topDir [
	"N.B. this is a clash between Trait usage and Inheritence usage due to restrictions on modifying pharo's source"
	^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
	
]

{ #category : #'squeak compatibility' }
Linux64Config >> validateSourcesPresent [
	| sources |
	sources := Smalltalk sourcesName.
	
	(sources == nil)
		ifTrue: [	self error: 'VM source code cannot be generated without .sources file'.]		
]

{ #category : #'squeak compatibility' }
Linux64Config >> write: aContents toFile: aFileName [
	"write a file to current output directory (buildDir).
	use line end convention appropriate for config platform"

	| bldDir |
	bldDir := self buildDir.
	bldDir isString
		ifTrue: [ bldDir := FileDirectory directoryEntryFor: bldDir ].
	bldDir assureExistence.
	bldDir
		forceNewFileNamed: aFileName
		do: [:s | s
				nextPutAll: (self fixLineEndsOf: aContents)]


]
