"
N.B. tty.  This class comment is from my pharo parent..

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
	#name : #SqueakWin32x86Config,
	#superclass : #CPlatformConfig,
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
	#category : #'CMakeVMMakerSqueak-Win32x86'
}

{ #category : #'as yet unclassified' }
SqueakWin32x86Config class >> licenseTemplate [
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
SqueakWin32x86Config class >> pluginsTemplate [
	^'Squeak {1} ships with the following plugins already built:
		
Internal: 
=========
{2}

External: 
=========
{3}

'
]

{ #category : #'thirdparty libs' }
SqueakWin32x86Config >> addThirdpartyLibrary: libName [
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

{ #category : #cmake }
SqueakWin32x86Config >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default allBuildConfigurations copyWithoutAll:#(#assert #assertWithHeartbeatTimer #debugMultiThreadedFFI #debugWithHeartbeatTimer #release #releaseHeartbeatTimer)



]

{ #category : #directories }
SqueakWin32x86Config >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #directories }
SqueakWin32x86Config >> buildDirName [
	buildType isNil
		ifTrue:[^self dirBuildPlatform, FileDirectory slash, self dirBuildLanguageVMMM, FileDirectory slash, 'build']
		ifFalse:[^self dirBuildPlatform, FileDirectory slash, self dirBuildLanguageVMMM, FileDirectory slash, buildType asString]
]

{ #category : #'build script' }
SqueakWin32x86Config >> buildScript [
	"answer the build script for building everything"
	

	^ 
'#!/usr/bin/env bash

cmake -G "MSYS Makefiles" .
make

'
]

{ #category : #'squeak compatibility' }
SqueakWin32x86Config >> buildType: aSymbol [
	buildType:=aSymbol
]

{ #category : #'compiler flags' }
SqueakWin32x86Config >> commonCompilerFlags [
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
SqueakWin32x86Config >> compilerFlags [
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
SqueakWin32x86Config >> configureAsynchFilePlugin:  maker [ 
	"extra rules for AsynchFilePlugin "

	super configureAsynchFilePlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32AsyncFilePrims.c')



]

{ #category : #'plugin extra rules' }
SqueakWin32x86Config >> configureB3DAcceleratorPlugin:  maker [ 
	"extra rules for B3DAcceleratorPlugin "

	super configureB3DAcceleratorPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32DualB3DX.c' 'sqWin32D3D.c' 'sqWin32OpenGL.c')



]

{ #category : #'cmake configuration' }
SqueakWin32x86Config >> configureBuild [
	"configure this Configuration for a buildType #build"
	self 
		preferredIncludesBuild;
		standardIncludesBuild;
		compilerFlagsBuild;
		internalPluginsBuild;
		externalPluginsBuild;
		thirdpartyLibsBuild
		


		
		
		
]

{ #category : #'plugin extra rules' }
SqueakWin32x86Config >> configureCroquetPlugin:  maker [ 
	"extra rules for CroquetPlugin "

	super configureCroquetPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32CroquetPlugin.c')



]

{ #category : #'plugin extra rules' }
SqueakWin32x86Config >> configureDropPlugin:  maker [ 
	"extra rules for DropPlugin "

	super configureDropPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32Drop')



]

{ #category : #'plugin extra rules' }
SqueakWin32x86Config >> configureFT2Plugin: maker [
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
SqueakWin32x86Config >> configureFilePlugin: maker [ 
	
	super configureFilePlugin: maker.
	
	maker addPlatformSources:
		#( 'sqWin32FilePrims.c')



]

{ #category : #'cmake configuration' }
SqueakWin32x86Config >> configureForBuildType: aSymbol [
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
SqueakWin32x86Config >> configureForNoBuildType [
		generateBuild:=generateBuildAssert:=generateBuildAssertITimerHeartbeat:=generateBuildDebug:=generateBuildDebugITimerHeartbeat:= generateBuildDebugMultiThreaded:= generateBuildIHeartbeatTimer:= generateBuildMultiThreaded:= generateBuildMultiThreadedAssert:= generateBuildMultiThreadedDebug:=false.
]

{ #category : #'plugin extra rules' }
SqueakWin32x86Config >> configureHostWindowPlugin:    maker [ 
	"extra rules for HostWindowPlugin "

	super configureHostWindowPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32HostWindowPlugin.c')



]

{ #category : #'plugin extra rules' }
SqueakWin32x86Config >> configureJoystickTabletPlugin:  maker [ 
	
	super configureJoystickTabletPlugin:  maker.
	
	maker addPlatformSources:
		#( 'sqWin32Joystick.c')



]

{ #category : #'plugin extra rules' }
SqueakWin32x86Config >> configureLocalePlugin:   maker [ 
	"extra rules for LocalePlugin "

	super configureLocalePlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32Locale.c')



]

{ #category : #'plugin extra rules' }
SqueakWin32x86Config >> configureMIDIPlugin:  maker [ 
	"extra rules for MIDIPlugin "

	super configureMIDIPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32MIDI.c')



]

{ #category : #'plugin extra rules' }
SqueakWin32x86Config >> configureMpeg3Plugin:  maker [ 
	"extra rules for Mpeg3Plugin "

	super configureMpeg3Plugin:  maker.
	
	maker addDefinitions: '-DNOPTHREADS'.

	maker addPlatformSources: #( 'sqOpenFile.c')
]

{ #category : #'plugin extra rules' }
SqueakWin32x86Config >> configureSecurityPlugin: maker [ 
	"extra rules for SecurityPlugin"

	super configureSecurityPlugin: maker.
	
	maker addPlatformSources: #( 'sqWin32Security')



]

{ #category : #'plugin extra rules' }
SqueakWin32x86Config >> configureSerialPlugin:     maker [ 
	"extra rules for SerialPlugin "

	super configureSerialPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32SerialPort.c')



]

{ #category : #'plugin extra rules' }
SqueakWin32x86Config >> configureSocketPlugin:  maker [ 
	"extra rules for SocketPlugin "

	super configureSocketPlugin:  maker.
	
	maker addPlatformSources: #( 'sqWin32NewNet.c')



]

{ #category : #'plugin extra rules' }
SqueakWin32x86Config >> configureSoundPlugin: maker [ 
	"extra rules for SoundPlugin"
	
	maker addPlatformSources: #( 'sqWin32Sound' )
]

{ #category : #'plugin extra rules' }
SqueakWin32x86Config >> configureSqueakSSLPlugin: maker [
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
SqueakWin32x86Config >> configureUUIDPlugin: maker [ 
	"extra rules for UUIDPlugin"
	
	maker addPlatformSources:
		#( 'sqWin32UUID.c')



]

{ #category : #'plugin extra rules' }
SqueakWin32x86Config >> configureWin32OSProcessPlugin: maker [ 
	"extra rules for Win32OSProcessPlugin"

	maker includeDirectories: '${crossDir}/plugins/FilePlugin'.
	maker includeDirectories: '${crossDir}/plugins/SocketPlugin'.

]

{ #category : #plugins }
SqueakWin32x86Config >> defaultExternalPlugins [
	"expertly cut-n-pasted from Cog/cygwinbuild/plugins.ext"
	^#(
		BochsIA32Plugin 
		SqueakFFIPrims 
		Win32OSProcessPlugin
	)
]

{ #category : #plugins }
SqueakWin32x86Config >> defaultInternalPlugins [
	"expertly cut-n-pasted from Cog/cygwinbuild/plugins.int"
	^#(
		ADPCMCodecPlugin 
		AsynchFilePlugin 
		B3DAcceleratorPlugin 
		B2DPlugin 
		BitBltPlugin 
		BMPReadWriterPlugin 
		CroquetPlugin 
		ZipPlugin 
		DropPlugin 
		DSAPrims 
		FFTPlugin 
		FilePlugin 
		FloatArrayPlugin 
		FloatMathPlugin 
		HostWindowPlugin 
		IA32ABI 
		JoystickTabletPlugin 
		JPEGReaderPlugin 
		JPEGReadWriter2Plugin 
		Klatt 
		LargeIntegers 
		LocalePlugin 
		Matrix2x3Plugin 
		MIDIPlugin 
		MiscPrimitivePlugin 
		Mpeg3Plugin 
		RePlugin 
		SecurityPlugin 
		SerialPlugin 
		SocketPlugin 
		SoundCodecPrims 
		SoundGenerationPlugin 
		SoundPlugin 
		StarSqueakPlugin 
		SurfacePlugin 
		UUIDPlugin
	)
]

{ #category : #cmake }
SqueakWin32x86Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self required
]

{ #category : #cmake }
SqueakWin32x86Config >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirWin32x86
]

{ #category : #cmake }
SqueakWin32x86Config >> excludeFromBuild [
	^true

]

{ #category : #accessing }
SqueakWin32x86Config >> executableType [
	^ 'WIN32'
]

{ #category : #accessing }
SqueakWin32x86Config >> externalModulesDir [
	"answer the location in VM bundle, where plugins and rest of dynamic libs will be copied,
	"
	^ '${outputDir}'
]

{ #category : #utils }
SqueakWin32x86Config >> fixLineEndsOf: string [
	^ string copyReplaceAll: String cr with: String crlf
]

{ #category : #public }
SqueakWin32x86Config >> generate [ 
	self generatePluginsList. 
	self generateLicense. 
	"^super generate"
	^CMakeVMGeneratorForSqueak generate:self    "Bypass CPlatformConfig generate to invoke our compatibility class"
]

{ #category : #'headers generation' }
SqueakWin32x86Config >> generateConfigH [
	"	
	used to be: 	
		self write: self configH toFile: 'config.h'
      but with variable buildTypes we need:
"
	self write: (self generateConfigH: buildType) toFile: 'config.h'   

]

{ #category : #'headers generation' }
SqueakWin32x86Config >> generateConfigH: aBuildType [
	"self write: self configH toFile: 'config.h'"

	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self configHBuild];
		at: #buildAssert  put: [self configHBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self configHBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self configHBuildDebug];   "located in CMakeVMMaker CPlatformConfig"
		at: #buildDebugITimerHeartbeat  put: [self configHBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self configHBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self configHBuildMultiThreaded ];
		at: #buildMultiThreadedAssert  put: [self configHBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self configHBuildMultiThreadedDebug ];
		at: #buildNone put:[self configHNoBuildType].


	 ^(d at: ( aBuildType)) value




]

{ #category : #'as yet unclassified' }
SqueakWin32x86Config >> generateLicense [ 
	self 
		write:  (self class licenseTemplate 
			format: { self version })
		toFile: 'LICENSE.txt'
	
]

{ #category : #'as yet unclassified' }
SqueakWin32x86Config >> generatePluginsList [ 
	self 
		write:  (self class pluginsTemplate 
			format: {
				self version. 
				String streamContents: [ :stream | self internalPlugins asStringOn: stream delimiter: String cr ].
				String streamContents: [ :stream | self externalPlugins asStringOn: stream delimiter: String cr ].
				self executableName })
		toFile: 'PLUGINS.txt'
	
]

{ #category : #'initialize-release' }
SqueakWin32x86Config >> initialize [
	super initialize.
	"this should be in my superclass, but I do not have permission to modify it. tty"
 generateBuild:=generateBuildAssert:=generateBuildAssertITimerHeartbeat:=generateBuildDebug:=generateBuildDebugITimerHeartbeat :=generateBuildDebugMultiThreaded:=generateBuildIHeartbeatTimer:=generateBuildMultiThreaded:=generateBuildMultiThreadedAssert:= generateBuildMultiThreadedDebug:=false

]

{ #category : #accessing }
SqueakWin32x86Config >> msysPathFor: aPath [
	| path |
	self flag:'tty'. "code smell alert"
	^aPath isString
		ifTrue:[	path := aPath  copyReplaceAll: '\' with: '/'.]
		ifFalse:[	path := aPath pathName copyReplaceAll: '\' with: '/'.]

	

]

{ #category : #directories }
SqueakWin32x86Config >> outputDir [

	"the directory where built binaries will be stored"
	^ outputDir ifNil: [ outputDir := (self topDir / self dirOutput/ self dirInstall) ]	


]

{ #category : #accessing }
SqueakWin32x86Config >> platformName [
	^ 'win32'
]

{ #category : #'source generation' }
SqueakWin32x86Config >> prepareVMMaker [
	
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

{ #category : #utils }
SqueakWin32x86Config >> setGlobalOptionsAfterDetermineSystem: aMaker buildType: aBuildType [
	"invoke correct setGlobalOptions for this buildType to allow per-buildType customization'"

	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self setGlobalOptionsAfterDetermineSystemBuild: aMaker];
		at: #buildAssert  put: [self setGlobalOptionsAfterDetermineSystemBuildAssert: aMaker];
		at: #buildAssertITimerHeartbeat  put: [self setGlobalOptionsAfterDetermineSystemBuildAssertITimerHeartbeat: aMaker];
            at:#buildDebug  put: [self setGlobalOptionsAfterDetermineSystemBuildDebug: aMaker];   
		at: #buildITimerHeartbeat  put: [self setGlobalOptionsAfterDetermineSystemBuildITimerHeartbeat: aMaker];
		at: #buildMultiThreaded  put: [self setGlobalOptionsAfterDetermineSystemBuildMultiThreaded: aMaker ];
		at: #buildMultiThreadedAssert  put: [self setGlobalOptionsAfterDetermineSystemBuildMultiThreadedAssert: aMaker];
		at: #buildMultiThreadedDebug   put: [self setGlobalOptionsAfterDetermineSystemBuildMultiThreadedDebug: aMaker ];
		at: #buildNone put:[self setGlobalOptionsBuildNone: aMaker].

	 ^(d at: ( aBuildType)) value

]

{ #category : #directories }
SqueakWin32x86Config >> setupDirectories: gen [
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
SqueakWin32x86Config >> srcDir [
		^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'src' )]
]

{ #category : #directories }
SqueakWin32x86Config >> topDir [
		^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
]

{ #category : #'source generation' }
SqueakWin32x86Config >> validateSourcesPresent [
	| sources |
	sources := Smalltalk sourcesName.
	
	(sources == nil)
		ifTrue: [	self error: 'VM source code cannot be generated without .sources file'.]		
]

{ #category : #'as yet unclassified' }
SqueakWin32x86Config >> version [
	^ ''
]

{ #category : #accessing }
SqueakWin32x86Config >> winVer [
	"Set minimum version to WindowsXP (see /cygwin/usr/include//w32api/w32api.h)"
	
	^ '-D_WIN32_WINNT=0x0501 -DWINVER=0x0501'
]
