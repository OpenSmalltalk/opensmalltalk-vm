"
A CPlatformConfigForSqueak acts as a compatability layer for Squeak and an Abstract Base Class for extended functionality required for the Squeak CMakeVMMaker use-case.

I used to be a TCPlatformConfigForSqueak, but if you attempt to load CMakeVMMakerSqueak-tty.63 you will note that massive Traits applied to over a hundred classes load very slowly via Monticello.

tty.
"
Class {
	#name : #CPlatformConfigForSqueak,
	#superclass : #CPlatformConfig,
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
	#category : #CMakeVMMakerSqueak
}

{ #category : #'as yet unclassified' }
CPlatformConfigForSqueak class >> licenseTemplate [
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

{ #category : #'as yet unclassified' }
CPlatformConfigForSqueak class >> pluginsTemplate [
	^'{4} {1} ships with this plugins already built:
		
Internal: 
=========
{2}

External: 
=========
{3}

'
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs [

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

{ #category : #'cmake configuration' }
CPlatformConfigForSqueak >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default  allBuildConfigurations

	" ^SqueakCMakeVMMakerAbstractBuilder  default  noBuildConfigurations.
	  ^(SqueakCMakeVMMakerAbstractBuilder  default  allBuildConfigurations 
			copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))   
	"
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> buildDirName [
	buildType isNil
		ifTrue:[^self dirBuildPlatform, FileDirectory slash, self dirBuildLanguageVMMM, FileDirectory slash, 'build']
		ifFalse:[^self dirBuildPlatform, FileDirectory slash, self dirBuildLanguageVMMM, FileDirectory slash, buildType asString]
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> buildScript [
	"answer the build script for building everything"
	

	^ 
'#!/usr/bin/env bash

cmake .
make

'
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> buildType: aSymbol [
	buildType:= aSymbol
]

{ #category : #'source generation' }
CPlatformConfigForSqueak >> cogitClass [
	self subclassResponsibility

	"
	^SimpleStackBasedCogit
	^ StackToRegisterMappingCogit 
	^SistaStackToRegisterMappingCogit

	Which one?

	ClassCommentVersionsBrowser browseCommentOf: Cogit 

	"

]

{ #category : #'compiler flags' }
CPlatformConfigForSqueak >> commonCompilerFlags [
	self	subclassResponsibility
]

{ #category : #'compiler flags' }
CPlatformConfigForSqueak >> compilerFlags [
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

{ #category : #'compiler flags' }
CPlatformConfigForSqueak >> compilerFlagsAssert [
	self subclassResponsibility
]

{ #category : #'compiler flags' }
CPlatformConfigForSqueak >> compilerFlagsAssertITimerHeartbeat [
	self subclassResponsibility
]

{ #category : #'compiler flags' }
CPlatformConfigForSqueak >> compilerFlagsBuild [
	"backwards compatability with pharo. If adding, override compilerFlagsRelease in your configuration."
	^self compilerFlagsRelease.
]

{ #category : #'compiler flags' }
CPlatformConfigForSqueak >> compilerFlagsDebug [
	self subclassResponsibility
]

{ #category : #'compiler flags' }
CPlatformConfigForSqueak >> compilerFlagsDebugITimerHeartbeat [
	self subclassResponsibility
]

{ #category : #'compiler flags' }
CPlatformConfigForSqueak >> compilerFlagsIHeartbeatTimer [
	self subclassResponsibility
]

{ #category : #'compiler flags' }
CPlatformConfigForSqueak >> compilerFlagsMultiThreaded [
	self subclassResponsibility
]

{ #category : #'compiler flags' }
CPlatformConfigForSqueak >> compilerFlagsMultiThreadedAssert [
	self subclassResponsibility
]

{ #category : #'compiler flags' }
CPlatformConfigForSqueak >> compilerFlagsMultiThreadedDebug [
	self subclassResponsibility
]

{ #category : #'compiler flags' }
CPlatformConfigForSqueak >> compilerFlagsNoBuildType [
	self shouldNotImplement.
]

{ #category : #'headers generation' }
CPlatformConfigForSqueak >> configH [
"ONLY USED ON UNIX CONFIGS included here for completeness and consistency CogUnixConfig browse.
"
"
Use  configH to tell your plugins where to find its libraries etc.
The version of this is platform dependent.
You may also need to edit your oscogvm/platforms/YOUR PLATFORM/plugins/ThePLuginDirectory/acinclude.m4 file so that it conforms to your system.

tty needed a custom version of this in Linux32x86SqueakCogV3NoGLConfig in order to build the UUIDPlugin.

Go to oscogvm/platforms/YOUR PLATFORM/plugins/ThePLuginDirectory and look at the acinclude.m4 file
you may need to edit that .

NOTE: CPlatformConfig contains a useable version of this that you can modify. 

I reproduce it here, but with double quotes changed to two single quotes so that the commenting will hold.
I provide a <---N.B quotes need changing at each place they have been modified.

Again. it is easier to copy the one in CPlatformConfig.


	^ '
#ifndef __sq_config_h
#define __sq_config_h

/* explicit image width */

#define HAVE_INTERP_H 1

/* package options */

#define USE_X11 1
#define USE_X11_GLX 1
/* #undef       USE_QUARTZ */
/* #undef       USE_QUARTZ_CGL */
/* #undef       USE_RFB */

/* libraries */

/* #undef       HAVE_LIBX11 */
#define HAVE_LIBXEXT 1
#define HAVE_LIBDL 1
/* #undef       HAVE_DYLD */
/* #undef       HAVE_LIBFFI */
/* #undef       HAVE_ICONV */

/* #undef       USE_AUDIO_NONE */
/* #undef       USE_AUDIO_SUN */
/* #undef       USE_AUDIO_NAS */
/* #undef       USE_AUDIO_OSS */
/* #undef       USE_AUDIO_MACOSX */
/* #undef       OSS_DEVICE */

/* header files */

#define HAVE_UNISTD_H 1
/* #undef       NEED_GETHOSTNAME_P */

#define HAVE_DIRENT_H 1
/* #undef       HAVE_SYS_NDIR_H */
/* #undef       HAVE_SYS_DIR_H */
/* #undef       HAVE_NDIR_H */
#define HAVE_DLFCN_H 1
/* #undef       HAVE_ICONV_H */

#define HAVE_SYS_TIME_H 1
#define TIME_WITH_SYS_TIME 1

#define HAVE_SYS_FILIO_H 1

/* #undef       HAVE_SYS_AUDIOIO_H */
/* #undef       HAVE_SUN_AUDIOIO_H */

/* #undef       HAVE_PTY_H */
/* #undef       HAVE_UTIL_H */
#define HAVE_LIBUTIL_H 1
/* #undef       HAVE_STROPTS_H */

#define HAVE_GL_GL_H 1
/* #undef       HAVE_OPENGL_GL_H */

/* #undef       NEED_SUNOS_H */


#define HAVE_UUID_H
/* system calls/library functions */

#define AT_EXIT atexit

#define HAVE_TZSET 1

#define HAVE_OPENPTY 1
/* #undef       HAVE_UNIX98_PTYS */

#define HAVE_SNPRINTF 1
/* #undef       HAVE___SNPRINTF */

#define HAVE_MMAP 1

/* #undef       HAVE_DYLD */

#define HAVE_LANGINFO_CODESET 1

#define HAVE_ALLOCA 1
/* #undef       HAVE_ALLOCA_H */

#define HAVE_UNSETENV 1

#define HAVE_NANOSLEEP 1

/* widths of primitive types */

#define SIZEOF_INT 4
#define SIZEOF_LONG 4
#define SIZEOF_LONG_LONG 8
#define SIZEOF_VOID_P 4

/* structures */

#define HAVE_TM_GMTOFF 1
#define HAVE_TIMEZONE 1

/* typedefs */

/* #undef       size_t */
/* #undef       socklen_t */

#define squeakInt64 long long

/* architecture */

#define OS_TYPE ''unix''    <---N.B quotes need changing at each place they have been modifying.

#define VM_HOST ''i386-freebsd8.2''    <---N.B quotes need changing at each place they have been modifying.
#define VM_HOST_CPU ''i386''    <---N.B quotes need changing at each place they have been modifying.
/* #undef       VM_HOST_VENDOR */
#define VM_HOST_OS ''freebsd8.2''   <---N.B quotes need changing at each place they have been modifying.
#define VM_BUILD_STRING ''Unix built on ''__DATE__ '' ''__TIME__'' Compiler: ''__VERSION__          <---N.B quotes need changing at each place they have been modifying.

/* #undef       WORDS_BIGENDIAN */
/* #undef       DOUBLE_WORD_ALIGNMENT */

/* damage containment */

/* #undef       DARWIN */

#ifdef NEED_SUNOS_H
# include ''sunos.h''    <---N.B quotes need changing at each place they have been modifying.
#endif

/* other configured variables */

#define SQ_VERSION ''3.9a-7024''    <---N.B quotes need changing at each place they have been modifying.
#define VM_VERSION ''3.9-7''    <---N.B quotes need changing at each place they have been modifying.
#define VM_MODULE_PREFIX ''    <---N.B quotes need changing at each place they have been modifying.
/* #undef VM_DLSYM_PREFIX */    
#define VM_X11DIR '/usr/X11R6/lib'    <---N.B quotes need changing at each place they have been modifying.

/* avoid dependencies on glibc2.3 */

/* #undef HAVE_FEATURES_H */

#if defined(HAVE_FEATURES_H)
# include ''glibc.h''    <---N.B quotes need changing at each place they have been modifying.
#endif

#endif /* __sq_config_h */
																																																																					
																																																																				'
"
]

{ #category : #'headers generation' }
CPlatformConfigForSqueak >> configHBuild [
	"convenience method to customize configH for this buildType. default is self configH
	^self configH"
	self subclassResponsibility

]

{ #category : #'headers generation' }
CPlatformConfigForSqueak >> configHBuildAssert [
	"convenience method to customize configH for this buildType. default is self configH
	^self configH"
	self subclassResponsibility

]

{ #category : #'headers generation' }
CPlatformConfigForSqueak >> configHBuildAssertITimerHeartbeat [
	"convenience method to customize configH for this buildType. default is self configH
	^self configH"
	self subclassResponsibility

]

{ #category : #'headers generation' }
CPlatformConfigForSqueak >> configHBuildDebug [
	"convenience method to customize configH for this buildType. default is self configH
	^self configH"
	self subclassResponsibility

]

{ #category : #'headers generation' }
CPlatformConfigForSqueak >> configHBuildDebugITimerHeartbeat [
	"convenience method to customize configH for this buildType. default is self configH
	^self configH"
	self subclassResponsibility

]

{ #category : #'headers generation' }
CPlatformConfigForSqueak >> configHBuildITimerHeartbeat [
	"convenience method to customize configH for this buildType. default is self configH
	^self configH"
	self subclassResponsibility

]

{ #category : #'headers generation' }
CPlatformConfigForSqueak >> configHBuildMultiThreaded [
	"convenience method to customize configH for this buildType. default is self configH
	^self configH"
	self subclassResponsibility

]

{ #category : #'headers generation' }
CPlatformConfigForSqueak >> configHBuildMultiThreadedAssert [
	"convenience method to customize configH for this buildType. default is self configH
	^self configH"
	self subclassResponsibility

]

{ #category : #'headers generation' }
CPlatformConfigForSqueak >> configHBuildMultiThreadedDebug [
	"convenience method to customize configH for this buildType. default is self configH
	^self configH"
	self subclassResponsibility

]

{ #category : #'headers generation' }
CPlatformConfigForSqueak >> configHNoBuildType [
	"SHOULD NOT GET HERE"	
	self shouldNotImplement
]

{ #category : #'cmake configuration' }
CPlatformConfigForSqueak >> configureBuild [
	"configure this Configuration for a buildType #build"
	self 
		preferredIncludesBuild;
		standardIncludesBuild;
		compilerFlagsBuild;
		internalPluginsBuild;
		externalPluginsBuild;
		thirdpartyLibsBuild
		
]

{ #category : #'cmake configuration' }
CPlatformConfigForSqueak >> configureBuildAssert [
	self subclassResponsibility
]

{ #category : #'cmake configuration' }
CPlatformConfigForSqueak >> configureBuildAssertITimerHeartbeat [
	self subclassResponsibility
]

{ #category : #'cmake configuration' }
CPlatformConfigForSqueak >> configureBuildDebug [
	self subclassResponsibility
]

{ #category : #'cmake configuration' }
CPlatformConfigForSqueak >> configureBuildDebugITimerHeartbeat [
	self subclassResponsibility
]

{ #category : #'cmake configuration' }
CPlatformConfigForSqueak >> configureBuildDebugMultiThreaded [
	self subclassResponsibility
]

{ #category : #'cmake configuration' }
CPlatformConfigForSqueak >> configureBuildIHeartbeatTimer [
	self subclassResponsibility
]

{ #category : #'cmake configuration' }
CPlatformConfigForSqueak >> configureBuildMultiThreaded [
	self subclassResponsibility
]

{ #category : #'cmake configuration' }
CPlatformConfigForSqueak >> configureBuildMultiThreadedAssert [
	self subclassResponsibility
]

{ #category : #'cmake configuration' }
CPlatformConfigForSqueak >> configureBuildMultiThreadedDebug [
	self subclassResponsibility
]

{ #category : #'cmake configuration' }
CPlatformConfigForSqueak >> configureForBuildType: aSymbol [
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

{ #category : #'cmake configuration' }
CPlatformConfigForSqueak >> configureNoBuildType [
		generateBuild:=generateBuildAssert:=generateBuildAssertITimerHeartbeat:=generateBuildDebug:=generateBuildDebugITimerHeartbeat:= generateBuildDebugMultiThreaded:= generateBuildIHeartbeatTimer:= generateBuildMultiThreaded:= generateBuildMultiThreadedAssert:= generateBuildMultiThreadedDebug:=false.
]

{ #category : #'source files' }
CPlatformConfigForSqueak >> coreSources [
	self subclassResponsibility

]

{ #category : #'source files' }
CPlatformConfigForSqueak >> crossSources [ 
	^#(
			'sqHeapMap.c'
			'sqTicker.c'
			'sqExternalSemaphores.c'
			'sqNamedPrims.c'
			'sqVirtualMachine.c'
		)
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirARMv6 [
	^'cmake.build.arm.v6'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirAndroid [
	^'Do Not Build. See Class Comment'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirBSD32x86 [
	^'cmake.build.bsd32x86'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirBuild [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #build
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirBuildAssert [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildAssert
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirBuildAssertITimerHeartbeat [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildAssertITimerHeartbeat
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirBuildDebug [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #debug
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirBuildDebugITimerHeartbeat [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #debugITimerHeartbeat
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirBuildDebugMultiThreaded [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #debugMultiThreaded
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirBuildITimerHeartbeat [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildITimerHeartbeat
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	self subclassResponsibility
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirBuildMultiThreaded [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildMultiThreaded
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirBuildMultiThreadedAssert [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildMultiThreadedAssert
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirBuildMultiThreadedDebug [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildMultiThreadedDebug
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	self subclassResponsibility
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> dirFrom: aStringOrDir [
	^ aStringOrDir isString
		ifTrue: [ FileDirectory forFileName: aStringOrDir  ]
		ifFalse: [ aStringOrDir ]
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirIA32Bochs [
	^'cmake.build.ia32bochs'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirIOS [
	^'cmake.build.ios'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirInstall [
	"the directory of the finished product.. the place where 'make install' puts stuff.
	SystemNavigation default browseMethodsWhoseNamesContain: 'outputDir'
      "
	self subclassResponsibility

]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirLinux32Armv6 [
	^'cmake.build.linux32armv6'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirLinux32x86 [
	^'cmake.build.linux32x86'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirLinux32x8664 [
	^'cmake.build.linux32_64x86'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirLinux64 [
	^'cmake.build.linux64'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirMacOS [
	^'cmake.build.macos'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirMacOSPowerPC [
	^'cmake.build.macospowerpc'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirMacOSX32x86 [
	^'cmake.build.macosx32x86'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirOutput [
	^'cmake.products'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirSource [
	^'src'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirSunOS32x86 [
	^'cmake.build.sunos32x86'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> dirWin32x86 [
	^'cmake.build.win32x86'
]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> eventStackV3 [
	"needed by Android config to pass internal tests. Android config is not built"
	^'do not build'
]

{ #category : #'cmake configuration' }
CPlatformConfigForSqueak >> excludeFromBuild [
"	^false"   "build this configuration"
"	^true"   "do not build this configuration"
	self subclassResponsibility

]

{ #category : #accessing }
CPlatformConfigForSqueak >> executableName [
	self subclassResponsibility
"
executableName
	^ self vmCogExecutableName
	^ self vmSistaExecutableName
	^ self vmStackExectuableName
"

]

{ #category : #accessing }
CPlatformConfigForSqueak >> executableType [
	self subclassResponsibility.

"
SystemNavigation default browseMethodsWhoseNamesContain: ''executableType''
	^ 'MACOSX_BUNDLE'
	^ 'WIN32'\
	^ ''
"
]

{ #category : #accessing }
CPlatformConfigForSqueak >> externalModulesDir [
	"answer the location in VM bundle, where plugins and rest of dynamic libs will be copied,
	"
	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> externalPluginsBuild [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins
	^self externalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> externalPluginsBuildAssert [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins
	^self externalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> externalPluginsBuildAssertITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins
	^self externalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> externalPluginsBuildDebug [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins
	^self externalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> externalPluginsBuildDebugITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins
	^self externalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> externalPluginsBuildITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins
	^self externalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> externalPluginsBuildMultiThreaded [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins
	^self externalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> externalPluginsBuildMultiThreadedAssert [
	"convenience method to customize plugins for this build.  default is 
	^self externalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> externalPluginsBuildMultiThreadedDebug [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins
	^self externalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> externalPluginsBuildNone [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #plugins }
CPlatformConfigForSqueak >> extraPluginSettings: maker [
	super extraPluginSettings: maker.  
"	This is a very active method depending on Platform 

	CPlatformConfig browse.
	
"
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraPluginSettingsBuild: maker [
	"convenience method to customize plugins for this build.  default is
	super extraPluginSettings: maker.  "
	self subclassResponsibility


]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildAssert: maker [
	"convenience method to customize plugins for this build.  default is
	super extraPluginSettings: maker.  "
	self subclassResponsibility


]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildAssertITimerHeartbeat: maker [
	"convenience method to customize plugins for this build.  default is
	super extraPluginSettings: maker.  "
	self subclassResponsibility


]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildDebug: maker [
	"convenience method to customize plugins for this build.  default is
	super extraPluginSettings: maker.  "
	self subclassResponsibility


]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildDebugITimerHeartbeat: maker [
	"convenience method to customize plugins for this build.  default is
	super extraPluginSettings: maker.  "
	self subclassResponsibility


]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildITimerHeartbeat: maker [
	"convenience method to customize plugins for this build.  default is
	super extraPluginSettings: maker.  "
	self subclassResponsibility


]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildMultiThreaded: maker [
	"convenience method to customize plugins for this build.  default is
	super extraPluginSettings: maker.  "
	self subclassResponsibility


]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildMultiThreadedAssert: maker [
	"convenience method to customize plugins for this build.  default is
	super extraPluginSettings: maker.  "
	self subclassResponsibility


]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildMultiThreadedDebug: maker [
	"convenience method to customize plugins for this build.  default is
	super extraPluginSettings: maker.  "
	self subclassResponsibility


]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildNone: maker [
	"convenience method to customize plugins for this build.  default is
	super extraPluginSettings: maker.  "
	self subclassResponsibility


]

{ #category : #'source files' }
CPlatformConfigForSqueak >> extraSources [
	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraVMSettings: maker [	"convenience method to customize plugins for this build.  default is 
	^super extraVMSettings: maker"

	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraVMSettingsBuild: maker [
	"convenience method to customize plugins for this build.  default is 
	^self extraVMSettings: maker"

	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraVMSettingsBuildAssert: maker [
	"convenience method to customize plugins for this build.  default is 
	^self extraVMSettings: maker"

	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraVMSettingsBuildAssertITimerHeartbeat: maker [
	"convenience method to customize plugins for this build.  default is 
	^self extraVMSettings: maker"

	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraVMSettingsBuildDebug: maker [
	"convenience method to customize plugins for this build.  default is 
	^self extraVMSettings: maker"

	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraVMSettingsBuildDebugITimerHeartbeat: maker [
	"convenience method to customize plugins for this build.  default is 
	^self extraVMSettings: maker"

	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraVMSettingsBuildITimerHeartbeat: maker [
	"convenience method to customize plugins for this build.  default is 
	^self extraVMSettings: maker"

	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraVMSettingsBuildMultiThreaded: maker [
	"convenience method to customize plugins for this build.  default is 
	^self extraVMSettings: maker"

	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraVMSettingsBuildMultiThreadedAssert: maker [
	"convenience method to customize plugins for this build.  default is 
	^self extraVMSettings: maker"

	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraVMSettingsBuildMultiThreadedDebug: maker [
	"convenience method to customize plugins for this build.  default is 
	^self extraVMSettings: maker"

	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> extraVMSettingsBuildNone: maker [
	"convenience method to customize plugins for this build.  default is 
	^self extraVMSettings: maker"
	self subclassResponsibility
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> fixLineEndsOf: string [
	^ string copyReplaceAll: String cr with: String crlf
]

{ #category : #accessing }
CPlatformConfigForSqueak >> frameworks [
	self subclassResponsibility
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> generate [
	self generatePluginsList. 
	self generateLicense. 
	^ CMakeVMGeneratorForSqueak generate: self 
]

{ #category : #'headers generation' }
CPlatformConfigForSqueak >> generateConfigH [
	"	
	used to be: 	
		self write: self configH toFile: 'config.h'
"
	self subclassResponsibility


]

{ #category : #'headers generation' }
CPlatformConfigForSqueak >> generateConfigH: aBuildType [
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

{ #category : #accessing }
CPlatformConfigForSqueak >> generateLicense [ 
	self 
		write:  (self class licenseTemplate 
			format: { self version })
		toFile: 'LICENSE.txt'
	
]

{ #category : #accessing }
CPlatformConfigForSqueak >> generatePluginsList [ 
	self 
		write:  (self class pluginsTemplate 
			format: {
				self version. 
				String streamContents: [ :stream | self internalPlugins asStringOn: stream delimiter: String cr ].
				String streamContents: [ :stream | self externalPlugins asStringOn: stream delimiter: String cr ].
				self executableName })
		toFile: 'PLUGINS.txt'
	
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> internalPluginsBuild [ 
	"convenience method to customize plugins for this build default to internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> internalPluginsBuildAssert [ 
	"convenience method to customize plugins for this build default to internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> internalPluginsBuildAssertITimerHeartbeat [ 
	"convenience method to customize plugins for this build default to internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> internalPluginsBuildDebug [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> internalPluginsBuildDebugITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> internalPluginsBuildITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> internalPluginsBuildMultiThreaded [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> internalPluginsBuildMultiThreadedAssert [
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> internalPluginsBuildMultiThreadedDebug [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> internalPluginsBuildNone [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'source generation' }
CPlatformConfigForSqueak >> interpreterClass [
	"answer an interpreter class for VM source code generation"
	self subclassResponsibility 


"
	^ CoInterpreter
	^ CoInterpreterMT
	^ CoInterpreterMT
	^ StackInterpreter
	^ StackEvtAndroidInterpreter
	??other
"
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> interpreterClassBuild [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClass



]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> interpreterClassBuildAssert [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClass



]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> interpreterClassBuildAssertITimerHeartbeat [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClass



]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> interpreterClassBuildDebug [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClass



]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> interpreterClassBuildDebugITImerHeartbeat [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClass



]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> interpreterClassBuildITimerHeartbeat [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClass



]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> interpreterClassBuildITimerMultiThreaded [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^CoInterpreterMT



]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> interpreterClassBuildITimerMultiThreadedAssert [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClassBuildITimerMultiThreaded



]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> interpreterClassBuildITimerMultiThreadedDebug [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClassBuildITimerMultiThreaded



]

{ #category : #accessing }
CPlatformConfigForSqueak >> linkFlags [
	self subclassResponsibility

"example:
	^ super linkFlags , ' -m32'
"
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> newspeakCogSpur [
	^'newspeak.cog.spur'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> newspeakCogV3 [
	^'newspeak.cog.v3'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> newspeakSistaSpur [
	^'newspeak.sista.Spur'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> newspeakSistaV3 [
	^'newspeak.sista.v3'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> newspeakStackSpur [
	^'newspeak.stack.spur'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> newspeakStackV3 [
	^'newspeak.stack.v3'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> oscogvm [
	^'oscogvm'
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> outputDir [

	"the directory where built binaries will be stored"
	^ outputDir ifNil: [ outputDir := (self topDir / self dirOutput /  self dirInstall) ]	


]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> outputDirName [
	^ 'products'
]

{ #category : #'source files' }
CPlatformConfigForSqueak >> platformSources [
	self subclassResponsibility
]

{ #category : #'source files' }
CPlatformConfigForSqueak >> preferredIncludes [
	"^#() SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'"

	self subclassResponsibility
	
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> preferredIncludesBuild [	
	"convencience method to customize for this build. default is self preferredIncludes
	^self preferredIncludes"
	self subclassResponsibility


]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> preferredIncludesBuildAssert [
	"convencience method to customize for this build. default is self preferredIncludes
	^self preferredIncludes"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> preferredIncludesBuildAssertITimerHeartbeat [
	"convencience method to customize for this build. default is self preferredIncludes
	^self preferredIncludes"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> preferredIncludesBuildDebug [
	"convencience method to customize for this build. default is self preferredIncludes
	^self preferredIncludes"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> preferredIncludesBuildDebugITimerHeartbeat [
	"convencience method to customize for this build. default is self preferredIncludes
	^self preferredIncludes"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> preferredIncludesBuildITimerHeartbeat [
	"convencience method to customize for this build. default is self preferredIncludes
	^self preferredIncludes"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> preferredIncludesBuildMultiThreaded [
	"convencience method to customize for this build. default is self preferredIncludes
	^self preferredIncludes"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> preferredIncludesBuildMultiThreadedAssert [
	"convencience method to customize for this build. default is self preferredIncludes
	^self preferredIncludes"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> preferredIncludesBuildMultiThreadedDebug [
	"convencience method to customize for this build. default is self preferredIncludes
	^self preferredIncludes"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> preferredIncludesBuildNone [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'source generation' }
CPlatformConfigForSqueak >> prepareForGeneration [
	"feel free to override me"
	|i|
	self flag:'tty'. 
	i:= self interpreterClass.
	((i == CoInterpreter) | (i == CoInterpreterMT ))
		ifTrue:[self prepareForCogGeneration].   "what is more efficient? self or super?  tty."
	(i == StackInterpreter) 
		ifTrue:[self prepareForStackVMGeneration].


]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> prepareVMMaker [
	
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

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setExtraTargetPropertiesBuild: aMaker [
	"convenience method for this buildType. default is self setExtraTargetProperties
	^self setExtraTargetProperties"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setExtraTargetPropertiesBuildAssert: aMaker [ 
	"convenience method for this buildType. default is self setExtraTargetProperties
	^self setExtraTargetProperties"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setExtraTargetPropertiesBuildAssertITimerHeartbeat: aMaker [
	"convenience method for this buildType. default is self setExtraTargetProperties
	^self setExtraTargetProperties"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setExtraTargetPropertiesBuildDebug: aMaker [
	"convenience method for this buildType. default is self setExtraTargetProperties
	^self setExtraTargetProperties"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setExtraTargetPropertiesBuildDebugITimerHeartbeat: aMaker [
	"convenience method for this buildType. default is self setExtraTargetProperties
	^self setExtraTargetProperties"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setExtraTargetPropertiesBuildITimerHeartbeat: aMaker [
	"convenience method for this buildType. default is self setExtraTargetProperties
	^self setExtraTargetProperties"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setExtraTargetPropertiesBuildMultiThreaded: aMaker [
	"convenience method for this buildType. default is self setExtraTargetProperties
	^self setExtraTargetProperties"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setExtraTargetPropertiesBuildMultiThreadedAssert: aMaker [
	"convenience method for this buildType. default is self setExtraTargetProperties
	^self setExtraTargetProperties"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setExtraTargetPropertiesBuildMultiThreadedDebug: aMaker [
	"convenience method for this buildType. default is self setExtraTargetProperties
	^self setExtraTargetProperties"
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setExtraTargetPropertiesBuildNone: aMaker [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystem: aMaker buildType: aBuildType [
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

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuild: aMaker [
	"convenience method to customize setGlobalOptionsAfterDetermineSystemBuild: aMaker for this build type. 

	Default is in CPlatformConfig>AfterDetermineSystemBuild aMaker setGlobalOptions: aMaker
	^super setGlobalOptionsAfterDetermineSystemBuild: aMaker "
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildAssert: aMaker [
	"convenience method to customize setGlobalOptionsAfterDetermineSystemBuild: aMaker for this build type. 

	Default is in CPlatformConfig>AfterDetermineSystemBuild aMaker setGlobalOptions: aMaker
	^super setGlobalOptionsAfterDetermineSystemBuildAssert: aMaker "
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildAssertITimerHeartbeat: aMaker [
	"convenience method to customize setGlobalOptionsAfterDetermineSystemBuild: aMaker for this build type. 

	Default is in CPlatformConfig>AfterDetermineSystemBuild aMaker setGlobalOptions: aMaker
	^super setGlobalOptionsAfterDetermineSystemBuildAssertITimerHeartbeat: aMaker "
	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildDebug: aMaker [
	"convenience method to customize setGlobalOptionsAfterDetermineSystemBuild: aMaker for this build type. 

	Default is in CPlatformConfig>AfterDetermineSystemBuild aMaker setGlobalOptions: aMaker
	^super setGlobalOptionsAfterDetermineSystemBuildDebug: aMaker "
	self subclassResponsibility

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildDebugITimerHeartbeat: aMaker [
	"convenience method to customize setGlobalOptionsAfterDetermineSystemBuild: aMaker for this build type. 

	Default is in CPlatformConfig>AfterDetermineSystemBuild aMaker setGlobalOptions: aMaker
	^super setGlobalOptionsAfterDetermineSystemBuildDebugITimerHeartbeat: aMaker "
	self subclassResponsibility
 

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildITimerHeartbeat: aMaker [
	"convenience method to customize setGlobalOptionsAfterDetermineSystemBuild: aMaker for this build type. 

	Default is in CPlatformConfig>AfterDetermineSystemBuild aMaker setGlobalOptions: aMaker
	^super setGlobalOptionsAfterDetermineSystemBuildMultiThreaded: aMaker "

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildMultiThreaded: aMaker [
	"convenience method to customize setGlobalOptionsAfterDetermineSystemBuild: aMaker for this build type. 

	Default is in CPlatformConfig>AfterDetermineSystemBuild aMaker setGlobalOptions: aMaker
	^super setGlobalOptionsAfterDetermineSystemBuildMultiThreaded: aMaker "

	self subclassResponsibility


]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedDebug: aMaker [
	"convenience method to customize setGlobalOptionsAfterDetermineSystemBuild: aMaker for this build type. 

	Default is in CPlatformConfig>AfterDetermineSystemBuild aMaker setGlobalOptions: aMaker
	^super setGlobalOptionsAfterDetermineSystemBuildMultiThreadedDebug: aMaker "
	self subclassResponsibility


]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildNone [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setGlobalOptionsBuild: aMaker [
	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildAssertITimerHeartbeat: aMaker [
	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildDebug: aMaker [
	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildDebugITimerHeartbeat: aMaker [
	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildITimerHeartbeat: aMaker [
	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildMultiThreaded: aMaker [
	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildMultiThreadedAssert: aMaker [
	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildMultiThreadedDebug: aMaker [
	self subclassResponsibility
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildNone: aMaker [
	"SHOULD NOT HAPPEN"
	self halt.
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> setupDirectories: aMaker [
	| dirsInclude |

	" write the directories in separate include file"
	dirsInclude := aMaker captureOutputDuring: [
		aMaker
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
	
	aMaker include: 'directories.cmake'.

]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> squeakCogSpur [
	^'squeak.cog.spur'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> squeakCogV3 [
	^'squeak.cog.v3'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> squeakSistaSpur [
	^'squeak.sista.Spur'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> squeakSistaV3 [
	^'squeak.sista.v3'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> squeakStackSpur [
	^'squeak.stack.spur'
]

{ #category : #'cmake directory ' }
CPlatformConfigForSqueak >> squeakStackV3 [
	^'squeak.stack.v3'
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> srcDir [
		^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'src' )]
]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> standardIncludesBuild [
	"convencience method to customize for this build. default is self standardIncludes
	^self standardIncludes"

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> standardIncludesBuildAssert [ 
	"convencience method to customize for this build. default is self standardIncludes
	^self standardIncludes"

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> standardIncludesBuildAssertITimerHeartbeat [ 
	"convencience method to customize for this build. default is self standardIncludes
	^self standardIncludes"

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> standardIncludesBuildDebug [ 
	"convencience method to customize for this build. default is self standardIncludes
	^self standardIncludes"

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> standardIncludesBuildITimerHeartbeat [ 
	"convencience method to customize for this build. default is self standardIncludes
	^self standardIncludes"

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> standardIncludesBuildMultiThreaded [ 
	"convencience method to customize for this build. default is self standardIncludes
	^self standardIncludes"

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> standardIncludesBuildMultiThreadedAssert [
	"convencience method to customize for this build. default is self standardIncludes
	^self standardIncludes"

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> standardIncludesBuildMultiThreadedDebug [ 
	"convencience method to customize for this build. default is self standardIncludes
	^self standardIncludes"

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> standardIncludesBuildNone [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> thirdpartyLibsBuild [ 
	"convenience method to customize third party libs for this buildType.  default is self  thirdpartyLibs
	^self thirdpartyLibs"

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildAssert [ 
	"convenience method to customize third party libs for this buildType.  default is self  thirdpartyLibs
	^self thirdpartyLibs"

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildAssertITimerHeartbeat [ 
	"convenience method to customize third party libs for this buildType.  default is self  thirdpartyLibs
	^self thirdpartyLibs"

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildDebug [ 
	"convenience method to customize third party libs for this buildType.  default is self  thirdpartyLibs
	^self thirdpartyLibs"

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildDebugITimerHeartbeat [ 
	"convenience method to customize third party libs for this buildType.  default is self  thirdpartyLibs
	^self thirdpartyLibs"

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildITimerHeartbeat [ 
	"convenience method to customize third party libs for this buildType.  default is self  thirdpartyLibs
	^self thirdpartyLibs"

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildMultiThreaded [ 
	"convenience method to customize third party libs for this buildType.  default is self  thirdpartyLibs
	^self thirdpartyLibs"

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildMultiThreadedAssert [
	"convenience method to customize third party libs for this buildType.  default is self  thirdpartyLibs
	^self thirdpartyLibs"

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildMultiThreadedDebug [ 
	"convenience method to customize third party libs for this buildType.  default is self  thirdpartyLibs
	^self thirdpartyLibs"

]

{ #category : #'cmake config build type ' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildNone [ 
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> topDir [
	^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
	
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> validateSourcesPresent [
	| sources |
	sources := Smalltalk sourcesName.
	
	(sources == nil)
		ifTrue: [	self error: 'VM source code cannot be generated without .sources file'.]		
]

{ #category : #accessing }
CPlatformConfigForSqueak >> version [
	^ ''
]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> vmCogExecutableName [
	"the name of the cog vm executable"
	^'cog'
]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> vmSistaExecutableName [
	"the name of the sista vm executable"
	^'sista'
]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> vmStackExecutableName [
	"the name of the stack vm executable"
	^'squeak'
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> write: aContents toFile: aFileName [
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
