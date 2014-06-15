"
A Linux32x86SqueakCogV3SlackwareConfig is a configuration for CMake on a 64 bit Slackware linux with 32 bit compat libs and includes linking to GL. 


SqueakLinux64x86w32CompatBuilder 
	configureABuildFor: #Linux32x86SqueakCogV3SlackwareConfig withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp
"
Class {
	#name : #Linux32x86SqueakCogV3SlackwareConfig,
	#superclass : #Linux64x86w32BitConfigSlackware,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#category : #'CMakeVMMakerSqueak-Linux64X86-32BitCompatibility'
}

{ #category : #accessing }
Linux32x86SqueakCogV3SlackwareConfig class >> licenseTemplate [
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
Linux32x86SqueakCogV3SlackwareConfig class >> pluginsTemplate [
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
Linux32x86SqueakCogV3SlackwareConfig >> addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs [
	super addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default allBuildConfigurations copyWithoutAll:#(#assert #assertWithHeartbeatTimer #debug  #debugMultiThreadedFFI #debugWithHeartbeatTimer #releaseHeartbeatTimer #releaseMultiThreadedFFI)



]

{ #category : #'squeak compatibility' }
Linux32x86SqueakCogV3SlackwareConfig >> buildDir [
	^super buildDir
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakCogV3SlackwareConfig >> buildDirName [
	^super buildDirName
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> buildType: aSymbol [	
	"force suclass to implement instance var accessor"
	self required.
]

{ #category : #'source generation' }
Linux32x86SqueakCogV3SlackwareConfig >> cogitClass [
	"answer a class for machine code generation or nil"
	^ StackToRegisterMappingCogit 



]

{ #category : #'compiler flags' }
Linux32x86SqueakCogV3SlackwareConfig >> commonCompilerFlags [
	^#()
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakCogV3SlackwareConfig >> compilerFlags [
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

{ #category : #'compiler flags' }
Linux32x86SqueakCogV3SlackwareConfig >> compilerFlagsAssert [
	self required
]

{ #category : #'compiler flags' }
Linux32x86SqueakCogV3SlackwareConfig >> compilerFlagsAssertITimerHeartbeat [
	self required
]

{ #category : #'compiler flags' }
Linux32x86SqueakCogV3SlackwareConfig >> compilerFlagsBuild [
	"backwards compatability with pharo. If adding, override compilerFlagsRelease in your configuration."
	^self compilerFlagsRelease.
]

{ #category : #'compiler flags' }
Linux32x86SqueakCogV3SlackwareConfig >> compilerFlagsDebug [
	self required
]

{ #category : #'compiler flags' }
Linux32x86SqueakCogV3SlackwareConfig >> compilerFlagsDebugITimerHeartbeat [
	self required
]

{ #category : #'compiler flags' }
Linux32x86SqueakCogV3SlackwareConfig >> compilerFlagsDebugMultiThreaded [
	self required
]

{ #category : #'compiler flags' }
Linux32x86SqueakCogV3SlackwareConfig >> compilerFlagsIHeartbeatTimer [
	self required
]

{ #category : #'compiler flags' }
Linux32x86SqueakCogV3SlackwareConfig >> compilerFlagsMultiThreaded [
	self required
]

{ #category : #'compiler flags' }
Linux32x86SqueakCogV3SlackwareConfig >> compilerFlagsMultiThreadedAssert [
	self required
]

{ #category : #'compiler flags' }
Linux32x86SqueakCogV3SlackwareConfig >> compilerFlagsMultiThreadedDebug [
	self required
]

{ #category : #'compiler flags' }
Linux32x86SqueakCogV3SlackwareConfig >> compilerFlagsNoBuildType [
	self shouldNotImplement.
]

{ #category : #'headers generation' }
Linux32x86SqueakCogV3SlackwareConfig >> configH [
	self flag:'tty' . "TODO: express correctly the 'what' and 'why' of this method"
	self required
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

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> configureBuild [
	self required
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> configureBuildAssert [
	self required
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> configureBuildAssertITimerHeartbeat [
	self required
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> configureBuildDebug [
	self required
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> configureBuildDebugITimerHeartbeat [
	self required
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> configureBuildDebugMultiThreaded [
	self required
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> configureBuildIHeartbeatTimer [
	self required
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> configureBuildMultiThreaded [
	self required
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> configureBuildMultiThreadedAssert [
	self required
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> configureBuildMultiThreadedDebug [
	self required
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> configureForBuildType: aSymbol [
	| d info |
	"provide a concrete builder with the buildType and configureBuildX method to invoke"
	info := SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	self configureNoBuildType.                "reset all internal flags"
	d 
		at: #build 
		put: [self buildType:(info at:#build).  self configureBuild];

		at: #buildAssert 
		put: [self buildType:(info at: #buildAssert).  	self configureBuildAssert];

		at: #buildAssertITimerHeartbeat 
		put:     [ self buildType:(info at: #buildAssertITimerHeartbeat ).   self configureBuildAssertITimerHeartbeat];

            at:#buildDebug 
		put: [self buildType:(info at: #buildDebug ).  self configureBuildDebug];

		at: #buildDebugITimerHeartbeat 
		put:  [self buildType:(info at: #buildDebugITimerHeartbeat).   self configureBuildDebugITimerHeartbeat];

		at: #buildDebugMultiThreaded 
		put: [self buildType:(info at: #buildDebugMultiThreaded ).   self configureBuildDebugMultiThreaded];

		at: #buildITimerHeartbeat 
		put: [self buildType:(info at:#buildITimerHeartbeat ).    self configureBuildIHeartbeatTimer];

		at: #buildMultiThreaded 
		put:  [self buildType:(info at:#buildMultiThreaded ). self configureBuildMultiThreaded];

		at: #buildMultiThreadedAssert 
		put: [self buildType:(info at: #buildMultiThreadedAssert). self configureBuildMultiThreadedAssert];

		at: #buildMultiThreadedDebug  
		put: [self buildType: (info at: #buildMultiThreadedDebug). self configureBuildMultiThreadedDebug].

     ^(d at: aSymbol).
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> configureNoBuildType [
	self required
]

{ #category : #plugins }
Linux32x86SqueakCogV3SlackwareConfig >> defaultExternalPlugins [
	"Removed the B3DAcceleratorPlugin since we don't have OpenGL bindings here"
	^ (super defaultExternalPlugins copyWithoutAll: #(#ThreadedIA32FFIPlugin #InternetConfigPlugin #FT2Plugin #InternetConfigPlugin))
]

{ #category : #plugins }
Linux32x86SqueakCogV3SlackwareConfig >> defaultInternalPlugins [
	"Removed the B3DAcceleratorPlugin since we don't have OpenGL bindings here"
	^ (super defaultInternalPlugins copyWithoutAll: #(#IA32ABIPlugin #JoystickTabletPlugin #StarSqueakPlugin #SurfacePlugin #SqueakFFIPrims #ThreadedIA32FFIPlugin))
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirARMv6 [
	^'cmake.build.arm.v6'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirAndroid [
	^'Do Not Build. See Class Comment'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirBSD32x86 [
	^'cmake.build.bsd32x86'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirBuild [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #build
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirBuildAssert [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildAssert
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirBuildAssertITimerHeartbeat [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildAssertITimerHeartbeat
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirBuildDebug [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #debug
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirBuildDebugITimerHeartbeat [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #debugITimerHeartbeat
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirBuildDebugMultiThreaded [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #debugMultiThreaded
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirBuildITimerHeartbeat [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildITimerHeartbeat
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackV3
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirBuildMultiThreaded [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildMultiThreaded
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirBuildMultiThreadedAssert [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildMultiThreadedAssert
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirBuildMultiThreadedDebug [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildMultiThreadedDebug
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirLinux32x8664
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakCogV3SlackwareConfig >> dirFrom: aStringOrDir [
	^ aStringOrDir isString
		ifTrue: [ FileDirectory forFileName: aStringOrDir  ]
		ifFalse: [ aStringOrDir ]
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirIA32Bochs [
	^'cmake.build.ia32bochs'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirIOS [
	^'cmake.build.ios'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirInstall [
	"the directory of the finished product.. the place where 'make install' puts stuff.
	SystemNavigation default browseMethodsWhoseNamesContain: 'outputDir'
      "
self required.

]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirLinux32Armv6 [
	^'cmake.build.linux32armv6'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirLinux32x86 [
	^'cmake.build.linux32x86'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirLinux32x8664 [
	^'cmake.build.linux32_64x86'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirMacOS [
	^'cmake.build.macos'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirMacOSPowerPC [
	^'cmake.build.macospowerpc'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirMacOSX32x86 [
	^'cmake.build.macosx32x86'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirOutput [
	^'cmake.products'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirSource [
	^'src'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirSunOS32x86 [
	^'cmake.build.sunos32x86'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> dirWin32x86 [
	^'cmake.build.win32x86'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> eventStackV3 [
	"needed by Android config to pass internal tests. Android config is not built"
	^'do not build'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #accessing }
Linux32x86SqueakCogV3SlackwareConfig >> executableName [
	^super executableName
]

{ #category : #accessing }
Linux32x86SqueakCogV3SlackwareConfig >> executableType [
	self required.

"
SystemNavigation default browseMethodsWhoseNamesContain: ''executableType''
	^ 'MACOSX_BUNDLE'
	^ 'WIN32'\
	^ ''
"
]

{ #category : #'plugin extra rules' }
Linux32x86SqueakCogV3SlackwareConfig >> extraPluginSettings: maker [
	super extraPluginSettings: maker.  
"	This is a very active method depending on Platform 

	CPlatformConfig browse.
	
"
]

{ #category : #settings }
Linux32x86SqueakCogV3SlackwareConfig >> extraVMSettings: maker [
	self required
]

{ #category : #accessing }
Linux32x86SqueakCogV3SlackwareConfig >> frameworks [
	"leave empty for all platforms but Mac OS"
	^ #()
]

{ #category : #public }
Linux32x86SqueakCogV3SlackwareConfig >> generate [ 
	self generatePluginsList. 
	self generateLicense. 
	"^super generate"
	^CMakeVMGeneratorForSqueak generate:self    "Bypass CPlatformConfig generate to invoke our compatibility class"

]

{ #category : #'headers generation' }
Linux32x86SqueakCogV3SlackwareConfig >> generateConfigH [
	"will fix that later"
	self write: self configH toFile: 'config.h'
]

{ #category : #accessing }
Linux32x86SqueakCogV3SlackwareConfig >> generateLicense [ 
	self 
		write:  (self class licenseTemplate 
			format: { self version })
		toFile: 'LICENSE.txt'
	
]

{ #category : #accessing }
Linux32x86SqueakCogV3SlackwareConfig >> generatePluginsList [ 
	self 
		write:  (self class pluginsTemplate 
			format: {
				self version. 
				String streamContents: [ :stream | self internalPlugins asStringOn: stream delimiter: String cr ].
				String streamContents: [ :stream | self externalPlugins asStringOn: stream delimiter: String cr ].
				self executableName })
		toFile: 'PLUGINS.txt'
	
]

{ #category : #'source generation' }
Linux32x86SqueakCogV3SlackwareConfig >> interpreterClass [
	self required.
	"
	^ CoInterpreter
	^ CoInterpreterMT
	^ StackInterpreter
	^ StackEvtAndroidInterpreter
	??other
	"
]

{ #category : #accessing }
Linux32x86SqueakCogV3SlackwareConfig >> linkFlags [
	self required

"example:
	^ super linkFlags , ' -m32'
"
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> newspeakCogSpur [
	^'newspeak.cog.spur'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> newspeakCogV3 [
	^'newspeak.cog.v3'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> newspeakSistaSpur [
	^'newspeak.sista.Spur'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> newspeakSistaV3 [
	^'newspeak.sista.v3'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> newspeakStackSpur [
	^'newspeak.stack.spur'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> newspeakStackV3 [
	^'newspeak.stack.v3'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> oscogvm [
	^'oscogvm'
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakCogV3SlackwareConfig >> outputDir [
	^super outputDir


]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> outputDirName [
	^ 'products'
]

{ #category : #'source files' }
Linux32x86SqueakCogV3SlackwareConfig >> preferredIncludes [
	self required

"
	^#()

SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'"
	
]

{ #category : #'source generation' }
Linux32x86SqueakCogV3SlackwareConfig >> prepareForGeneration [
	self required

	"^self prepareForCogGeneration
	  ^self prepareForStackVMGeneration
		
	  CPlatformConfig browse"

]

{ #category : #'squeak compatibility' }
Linux32x86SqueakCogV3SlackwareConfig >> prepareVMMaker [
	^super prepareVMMaker
]

{ #category : #utils }
Linux32x86SqueakCogV3SlackwareConfig >> setExtraTargetProperties: maker [
	"override me if needed. Super call is to CPlatformConfig which does nothing"
	super setExtraTargetProperties: maker.
"
SystemNavigation default browseMethodsWhoseNamesContain: 'setExtraTargetProperties:' 

"
]

{ #category : #utils }
Linux32x86SqueakCogV3SlackwareConfig >> setGlobalOptions: maker [
	self required
	"set any CMake global options, before declaring a project in cmake file
	
	maker set: 'CMAKE_C_COMPILER' to: '/usr/bin/gcc'.
	maker set: 'CMAKE_CXX_COMPILER' to: '/usr/bin/g++'.
	
	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions:'
"
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakCogV3SlackwareConfig >> setupDirectories:gen [
	super setupDirectories: gen
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> squeakCogSpur [
	^'squeak.cog.spur'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> squeakCogV3 [
	^'squeak.cog.v3'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> squeakSistaSpur [
	^'squeak.sista.Spur'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> squeakSistaV3 [
	^'squeak.sista.v3'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> squeakStackSpur [
	^'squeak.stack.spur'
]

{ #category : #cmake }
Linux32x86SqueakCogV3SlackwareConfig >> squeakStackV3 [
	^'squeak.stack.v3'
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakCogV3SlackwareConfig >> srcDir [
	^super srcDir
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakCogV3SlackwareConfig >> topDir [
	^super topDir
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakCogV3SlackwareConfig >> validateSourcesPresent [
	super validateSourcesPresent
]

{ #category : #accessing }
Linux32x86SqueakCogV3SlackwareConfig >> version [
	^ ''
]

{ #category : #'squeak compatibility' }
Linux32x86SqueakCogV3SlackwareConfig >> write: aContents toFile: aFileName [
	super write: aContents toFile: aFileName
]
