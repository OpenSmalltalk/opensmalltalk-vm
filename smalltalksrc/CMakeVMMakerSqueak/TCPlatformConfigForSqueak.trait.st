"
A TSqueakCPlatformConfig provides a template of methods which must be customized for Squeak compatibility with  pharo CMakeVMMaker classes. I also act as a repository of paths and directories. 

I exist because tty does not have (and, should not have) permission to modify  to the existing inheritence tree in the pharo CMakeVMMaker categories.


my protocol 'squeak compatibility' are the pharo override methods.
my protocol 'cmake' contains helper methods unique to the squeak implementation of CMakeVMMakerSqueak and do not exist in the pharo stack.







"
Trait {
	#name : #TCPlatformConfigForSqueak,
	#category : #CMakeVMMakerSqueak
}

{ #category : #accessing }
TCPlatformConfigForSqueak classSide >> licenseTemplate [
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
TCPlatformConfigForSqueak classSide >> pluginsTemplate [
	^'{4} {1} ships with this plugins already built:
		
Internal: 
=========
{2}

External: 
=========
{3}

'
]

{ #category : #'cmake configuration' }
TCPlatformConfigForSqueak >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default  allBuildConfigurations

	" ^SqueakCMakeVMMakerAbstractBuilder  default  noBuildConfigurations.
	  ^(SqueakCMakeVMMakerAbstractBuilder  default  allBuildConfigurations 
			copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))   
	"
]

{ #category : #'squeak compatibility' }
TCPlatformConfigForSqueak >> buildDir [
	self required
]

{ #category : #'squeak compatibility' }
TCPlatformConfigForSqueak >> buildDirName [
	self required
]

{ #category : #'cmake configuration' }
TCPlatformConfigForSqueak >> buildType: aSymbol [	
	"force suclass to implement instance var accessor"
	self required.
]

{ #category : #'source generation' }
TCPlatformConfigForSqueak >> cogitClass [
	"answer a class for machine code generation or nil"
	^ StackToRegisterMappingCogit 



]

{ #category : #'compiler flags' }
TCPlatformConfigForSqueak >> commonCompilerFlags [
	^#()
]

{ #category : #'compiler flags' }
TCPlatformConfigForSqueak >> compilerFlags [
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> compilerFlagsAssert [
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> compilerFlagsAssertITimerHeartbeat [
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> compilerFlagsBuild [
	"backwards compatability with pharo. If adding, override compilerFlagsRelease in your configuration."
	^self compilerFlagsRelease.
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> compilerFlagsDebug [
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> compilerFlagsDebugITimerHeartbeat [
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> compilerFlagsIHeartbeatTimer [
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> compilerFlagsMultiThreaded [
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> compilerFlagsMultiThreadedAssert [
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> compilerFlagsMultiThreadedDebug [
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> compilerFlagsNoBuildType [
	self shouldNotImplement.
]

{ #category : #'headers generation' }
TCPlatformConfigForSqueak >> configH [
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
TCPlatformConfigForSqueak >> configHBuild [
	"convenience method to customize configH for this buildType. default is self configH"
	^self configH

]

{ #category : #'headers generation' }
TCPlatformConfigForSqueak >> configHBuildAssert [
	"convenience method to customize configH for this buildType. default is self configH"
	^self configH

]

{ #category : #'headers generation' }
TCPlatformConfigForSqueak >> configHBuildAssertITimerHeartbeat [
	"convenience method to customize configH for this buildType. default is self configH"
	^self configH

]

{ #category : #'headers generation' }
TCPlatformConfigForSqueak >> configHBuildDebug [
	"convenience method to customize configH for this buildType. default is self configH"
	^self configH

]

{ #category : #'headers generation' }
TCPlatformConfigForSqueak >> configHBuildDebugITimerHeartbeat [
	"convenience method to customize configH for this buildType. default is self configH"
	^self configH

]

{ #category : #'headers generation' }
TCPlatformConfigForSqueak >> configHBuildITimerHeartbeat [
	"convenience method to customize configH for this buildType. default is self configH"
	^self configH

]

{ #category : #'headers generation' }
TCPlatformConfigForSqueak >> configHBuildMultiThreaded [
	"convenience method to customize configH for this buildType. default is self configH"
	^self configH

]

{ #category : #'headers generation' }
TCPlatformConfigForSqueak >> configHBuildMultiThreadedAssert [
	"convenience method to customize configH for this buildType. default is self configH"
	^self configH

]

{ #category : #'headers generation' }
TCPlatformConfigForSqueak >> configHBuildMultiThreadedDebug [
	"convenience method to customize configH for this buildType. default is self configH"
	^self configH

]

{ #category : #'headers generation' }
TCPlatformConfigForSqueak >> configHNoBuildType [
	"SHOULD NOT GET HERE"	
	self halt.
]

{ #category : #'cmake configuration' }
TCPlatformConfigForSqueak >> configureBuild [
	"configure this Configuration for a buildType #build"
	self 
"		setGlobalOptionsBuild: aMaker"
"		setGlobalOptionsAfterDetermineSystemBuild: aMaker"
"		setupDirectoriesBuild: aMaker;"
		preferredIncludesBuild;
		standardIncludesBuild;
		compilerFlagsBuild;
"		extraVMSettingsBuild: aMaker"
		internalPluginsBuild;
		externalPluginsBuild;
		thirdpartyLibsBuild
"		postBuildActionsBuild:"
"		configHBuild."
		


		
		
		
]

{ #category : #'cmake configuration' }
TCPlatformConfigForSqueak >> configureBuildAssert [
	self required
]

{ #category : #'cmake configuration' }
TCPlatformConfigForSqueak >> configureBuildAssertITimerHeartbeat [
	self required
]

{ #category : #'cmake configuration' }
TCPlatformConfigForSqueak >> configureBuildDebug [
	self required
]

{ #category : #'cmake configuration' }
TCPlatformConfigForSqueak >> configureBuildDebugITimerHeartbeat [
	self required
]

{ #category : #'cmake configuration' }
TCPlatformConfigForSqueak >> configureBuildDebugMultiThreaded [
	self required
]

{ #category : #'cmake configuration' }
TCPlatformConfigForSqueak >> configureBuildIHeartbeatTimer [
	self required
]

{ #category : #'cmake configuration' }
TCPlatformConfigForSqueak >> configureBuildMultiThreaded [
	self required
]

{ #category : #'cmake configuration' }
TCPlatformConfigForSqueak >> configureBuildMultiThreadedAssert [
	self required
]

{ #category : #'cmake configuration' }
TCPlatformConfigForSqueak >> configureBuildMultiThreadedDebug [
	self required
]

{ #category : #'cmake configuration' }
TCPlatformConfigForSqueak >> configureForBuildType: aSymbol [
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

{ #category : #'cmake configuration' }
TCPlatformConfigForSqueak >> configureNoBuildType [
	self required
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirARMv6 [
	^'cmake.build.arm.v6'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirAndroid [
	^'Do Not Build. See Class Comment'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirBSD32x86 [
	^'cmake.build.bsd32x86'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirBuild [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #build
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirBuildAssert [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildAssert
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirBuildAssertITimerHeartbeat [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildAssertITimerHeartbeat
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirBuildDebug [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #debug
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirBuildDebugITimerHeartbeat [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #debugITimerHeartbeat
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirBuildDebugMultiThreaded [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #debugMultiThreaded
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirBuildITimerHeartbeat [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildITimerHeartbeat
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	self required
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirBuildMultiThreaded [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildMultiThreaded
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirBuildMultiThreadedAssert [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildMultiThreadedAssert
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirBuildMultiThreadedDebug [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildMultiThreadedDebug
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	self required
]

{ #category : #'squeak compatibility' }
TCPlatformConfigForSqueak >> dirFrom: aStringOrDir [
	^ aStringOrDir isString
		ifTrue: [ FileDirectory forFileName: aStringOrDir  ]
		ifFalse: [ aStringOrDir ]
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirIA32Bochs [
	^'cmake.build.ia32bochs'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirIOS [
	^'cmake.build.ios'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirInstall [
	"the directory of the finished product.. the place where 'make install' puts stuff.
	SystemNavigation default browseMethodsWhoseNamesContain: 'outputDir'
      "
self required.

]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirLinux32Armv6 [
	^'cmake.build.linux32armv6'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirLinux32x86 [
	^'cmake.build.linux32x86'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirLinux32x8664 [
	^'cmake.build.linux32_64x86'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirMacOS [
	^'cmake.build.macos'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirMacOSPowerPC [
	^'cmake.build.macospowerpc'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirMacOSX32x86 [
	^'cmake.build.macosx32x86'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirOutput [
	^'cmake.products'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirSource [
	^'src'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirSunOS32x86 [
	^'cmake.build.sunos32x86'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> dirWin32x86 [
	^'cmake.build.win32x86'
]

{ #category : #'cmake executable names' }
TCPlatformConfigForSqueak >> eventStackV3 [
	"needed by Android config to pass internal tests. Android config is not built"
	^'do not build'
]

{ #category : #'cmake configuration' }
TCPlatformConfigForSqueak >> excludeFromBuild [
"	^false"   "build this configuration"
"	^true"   "do not build this configuration"
	self required

]

{ #category : #accessing }
TCPlatformConfigForSqueak >> executableName [
	self required.

"browse subclasses of CPLatformConfig for context
^'CogVM'
^ 'CogMTVM'
^ 'EventVM'.
^'iStackVMSimulator'
^ 'iStackVM'
^'Squeak'
^ 'StackVM'



"
]

{ #category : #accessing }
TCPlatformConfigForSqueak >> executableType [
	self required.

"
SystemNavigation default browseMethodsWhoseNamesContain: ''executableType''
	^ 'MACOSX_BUNDLE'
	^ 'WIN32'\
	^ ''
"
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> externalPluginsBuild [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins"
	^self externalPlugins

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> externalPluginsBuildAssert [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins"
	^self externalPlugins

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> externalPluginsBuildAssertITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins"
	^self externalPlugins

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> externalPluginsBuildDebug [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins"
	^self externalPlugins

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> externalPluginsBuildDebugITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins"
	^self externalPlugins

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> externalPluginsBuildITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins"
	^self externalPlugins

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> externalPluginsBuildMultiThreaded [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins"
	^self externalPlugins

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> externalPluginsBuildMultiThreadedAssert [
	"convenience method to customize plugins for this build.  default is self  externalPluins"
	^self externalPlugins

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> externalPluginsBuildMultiThreadedDebug [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins"
	^self externalPlugins

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> externalPluginsBuildNone [
	"convenience method to customize plugins for this build.  default is self  externalPluins"
	^self externalPlugins

]

{ #category : #'plugin extra rules' }
TCPlatformConfigForSqueak >> extraPluginSettings: maker [
	super extraPluginSettings: maker.  
"	This is a very active method depending on Platform 

	CPlatformConfig browse.
	
"
]

{ #category : #settings }
TCPlatformConfigForSqueak >> extraVMSettings: maker [
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> extraVMSettingsBuild [ 
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> extraVMSettingsBuildAssert [ 
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> extraVMSettingsBuildAssertITimerHeartbeat [ 
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> extraVMSettingsBuildDebug [ 
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> extraVMSettingsBuildDebugITimerHeartbeat [ 
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> extraVMSettingsBuildITimerHeartbeat [ 
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> extraVMSettingsBuildMultiThreaded [ 
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> extraVMSettingsBuildMultiThreadedAssert [
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> extraVMSettingsBuildMultiThreadedDebug [ 
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> extraVMSettingsBuildNone [ 
	self required
]

{ #category : #accessing }
TCPlatformConfigForSqueak >> frameworks [
	"leave empty for all platforms but Mac OS"
	^ #()
]

{ #category : #accessing }
TCPlatformConfigForSqueak >> generate [
	self generatePluginsList. 
	self generateLicense. 
	^ CMakeVMGeneratorForSqueak generate: self 
]

{ #category : #'headers generation' }
TCPlatformConfigForSqueak >> generateConfigH [
	"	
	used to be: 	
		self write: self configH toFile: 'config.h'
      but with variable buildTypes we need:
		self write: (generateConfigH: (self buildType))toFile: 'config.h'   
      However, I cannot use an instanceVariable in a Trait. so must implement in concrete class
"
	self required.


]

{ #category : #'headers generation' }
TCPlatformConfigForSqueak >> generateConfigH: aBuildType [
	"self write: self configH toFile: 'config.h'"

	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self configHBuild];
		at: #buildAssert  put: [self configHBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self configHBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self configHBuildDebug];   "located in CMakeVMMaker CPlatformConfig"
		at: #buildDebugITimerHeartbeat  put: [self configHBuildDebugITimerHeartbeat ];
		at: #buildDebugMultiThreaded  put: [self configHBuildDebugMultiThreaded];
		at: #buildITimerHeartbeat  put: [self configHBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self configHBuildMultiThreaded ];
		at: #buildMultiThreadedAssert  put: [self configHBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self configHBuildMultiThreadedDebug ];
		at: #buildNone put:[self configHNoBuildType].


	 ^(d at: ( aBuildType)) value




]

{ #category : #accessing }
TCPlatformConfigForSqueak >> generateLicense [ 
	self 
		write:  (self class licenseTemplate 
			format: { self version })
		toFile: 'LICENSE.txt'
	
]

{ #category : #accessing }
TCPlatformConfigForSqueak >> generatePluginsList [ 
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
TCPlatformConfigForSqueak >> internalPluginsBuild [ 
	"convenience method to customize plugins for this build default to internalPluins"
	^self internalPlugins

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> internalPluginsBuildAssert [ 
	"convenience method to customize plugins for this build default to internalPluins"
	^self internalPlugins

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> internalPluginsBuildAssertITimerHeartbeat [ 
	"convenience method to customize plugins for this build default to internalPluins"
	^self internalPlugins

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> internalPluginsBuildDebug [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins"
	^self internalPlugins

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> internalPluginsBuildDebugITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins"
	^self internalPlugins

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> internalPluginsBuildITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins"
	^self internalPlugins

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> internalPluginsBuildMultiThreaded [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins"
	^self internalPlugins

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> internalPluginsBuildMultiThreadedAssert [
	"convenience method to customize plugins for this build.  default is self  internalPluins"
	^self internalPlugins

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> internalPluginsBuildMultiThreadedDebug [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins"
	^self internalPlugins

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> internalPluginsBuildNone [
	"convenience method to customize plugins for this build.  default is self  internalPluins"
	^self internalPlugins

]

{ #category : #'source generation' }
TCPlatformConfigForSqueak >> interpreterClass [
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
TCPlatformConfigForSqueak >> linkFlags [
	self required

"example:
	^ super linkFlags , ' -m32'
"
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> newspeakCogSpur [
	^'newspeak.cog.spur'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> newspeakCogV3 [
	^'newspeak.cog.v3'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> newspeakSistaSpur [
	^'newspeak.sista.Spur'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> newspeakSistaV3 [
	^'newspeak.sista.v3'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> newspeakStackSpur [
	^'newspeak.stack.spur'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> newspeakStackV3 [
	^'newspeak.stack.v3'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> oscogvm [
	^'oscogvm'
]

{ #category : #'squeak compatibility' }
TCPlatformConfigForSqueak >> outputDir [
	self required


]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> outputDirName [
	^ 'products'
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> postBuildActionsBuild: aMaker [
	"convenience method for this buildType. default is self postBuildActions"
	^self postBuildActions:aMaker

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> postBuildActionsBuildAssert: aMaker [
	"convenience method for this buildType. default is self postBuildActions"
	^self postBuildActions:aMaker

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> postBuildActionsBuildAssertITimerHeartbeat: aMaker [
	"convenience method for this buildType. default is self postBuildActions"
	^self postBuildActions:aMaker

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> postBuildActionsBuildDebug: aMaker [
	"convenience method for this buildType. default is self postBuildActions: aMaker"
	^self postBuildActions:aMaker

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> postBuildActionsBuildDebugITimerHeartbeat: aMaker [
	"convenience method for this buildType. default is self postBuildActions: aMaker"
	^self postBuildActions:aMaker

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> postBuildActionsBuildITimerHeartbeat: aMaker [
	"convenience method for this buildType. default is self postBuildActions: aMaker"
	^self postBuildActions:aMaker

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> postBuildActionsBuildMultiThreaded: aMaker [
	"convenience method for this buildType. default is self postBuildActions: aMaker"
	^self postBuildActions:aMaker

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> postBuildActionsBuildMultiThreadedAssert: aMaker [
	"convenience method for this buildType. default is self postBuildActions: aMaker"
	^self postBuildActions:aMaker

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> postBuildActionsBuildMultiThreadedDebug: aMaker [ 
	"convenience method for this buildType. default is self postBuildActions: aMaker"
	^self postBuildActions:aMaker

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> postBuildActionsBuildNone: aMaker [
	"convenience method for this buildType. default is self postBuildActions: aMaker"
	^self postBuildActions:aMaker

]

{ #category : #'source files' }
TCPlatformConfigForSqueak >> preferredIncludes [
	self required

"
	^#()

SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'"
	
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> preferredIncludesBuild [	
	"convencience method to customize for this build. default is self preferredIncludes"
	^self preferredIncludes


]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> preferredIncludesBuildAssert [
	"convencience method to customize for this build. default is self preferredIncludes"
	^self preferredIncludes

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> preferredIncludesBuildAssertITimerHeartbeat [
	"convencience method to customize for this build. default is self preferredIncludes"
	^self preferredIncludes

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> preferredIncludesBuildDebug [
	"convencience method to customize for this build. default is self preferredIncludes"
	^self preferredIncludes

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> preferredIncludesBuildDebugITimerHeartbeat [
	"convencience method to customize for this build. default is self preferredIncludes"
	^self preferredIncludes

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> preferredIncludesBuildITimerHeartbeat [
	"convencience method to customize for this build. default is self preferredIncludes"
	^self preferredIncludes

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> preferredIncludesBuildMultiThreaded [
	"convencience method to customize for this build. default is self preferredIncludes"
	^self preferredIncludes

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> preferredIncludesBuildMultiThreadedAssert [
	"convencience method to customize for this build. default is self preferredIncludes"
	^self preferredIncludes

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> preferredIncludesBuildMultiThreadedDebug [
	"convencience method to customize for this build. default is self preferredIncludes"
	^self preferredIncludes

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> preferredIncludesBuildNone [
	"SHOULD NOT GET HERE"
	self halt

]

{ #category : #'source generation' }
TCPlatformConfigForSqueak >> prepareForGeneration [
	self required

	"^self prepareForCogGeneration
	  ^self prepareForStackVMGeneration
		
	  CPlatformConfig browse"

]

{ #category : #utils }
TCPlatformConfigForSqueak >> setExtraTargetProperties: maker [
	"override me if needed. Super call is to CPlatformConfig which does nothing"
	super setExtraTargetProperties: maker.
"
SystemNavigation default browseMethodsWhoseNamesContain: 'setExtraTargetProperties:' 

"
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setExtraTargetPropertiesBuild: aMaker [
	"convenience method for this buildType. default is self setExtraTargetProperties"
	^self setExtraTargetProperties

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setExtraTargetPropertiesBuildAssert: aMaker [ 
	"convenience method for this buildType. default is self setExtraTargetProperties"
	^self setExtraTargetProperties

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setExtraTargetPropertiesBuildAssertITimerHeartbeat: aMaker [
	"convenience method for this buildType. default is self setExtraTargetProperties"
	^self setExtraTargetProperties

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setExtraTargetPropertiesBuildDebug: aMaker [
	"convenience method for this buildType. default is self setExtraTargetProperties"
	^self setExtraTargetProperties

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setExtraTargetPropertiesBuildDebugITimerHeartbeat: aMaker [
	"convenience method for this buildType. default is self setExtraTargetProperties"
	^self setExtraTargetProperties

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setExtraTargetPropertiesBuildITimerHeartbeat: aMaker [
	"convenience method for this buildType. default is self setExtraTargetProperties"
	^self setExtraTargetProperties

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setExtraTargetPropertiesBuildMultiThreaded: aMaker [
	"convenience method for this buildType. default is self setExtraTargetProperties"
	^self setExtraTargetProperties

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setExtraTargetPropertiesBuildMultiThreadedAssert: aMaker [
	"convenience method for this buildType. default is self setExtraTargetProperties"
	^self setExtraTargetProperties

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setExtraTargetPropertiesBuildMultiThreadedDebug: aMaker [
	"convenience method for this buildType. default is self setExtraTargetProperties"
	^self setExtraTargetProperties

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setExtraTargetPropertiesBuildNone: aMaker [
	"convenience method for this buildType. default is self setExtraTargetProperties"
	^self setExtraTargetProperties

]

{ #category : #utils }
TCPlatformConfigForSqueak >> setGlobalOptions: maker [
	self required
	"set any CMake global options, before declaring a project in cmake file
	
	maker set: 'CMAKE_C_COMPILER' to: '/usr/bin/gcc'.
	maker set: 'CMAKE_CXX_COMPILER' to: '/usr/bin/g++'.
	
	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions:'
"
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuild [ 
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildAssert [ 
	self required

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildAssertITimerHeartbeat [ 
	self required

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildDebug [ 
	self required

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildDebugITimerHeartbeat [ 
	self required

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildITimerHeartbeat [ 
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildMultiThreaded [ 
	self required

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedAssert [
	self required

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedDebug [ 
	self required

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildNone [
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setGlobalOptionsBuild: aMaker [
	self required.
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setGlobalOptionsBuildAssert: aMaker [
	self required.
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setGlobalOptionsBuildAssertITimerHeartbeat: aMaker [
	self required.
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setGlobalOptionsBuildDebug: aMaker [
	self required.
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setGlobalOptionsBuildDebugITimerHeartbeat: aMaker [
	self required.
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setGlobalOptionsBuildITimerHeartbeat: aMaker [
	self required.
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setGlobalOptionsBuildMultiThreaded: aMaker [
	self required.
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setGlobalOptionsBuildMultiThreadedAssert: aMaker [
	self required.
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setGlobalOptionsBuildMultiThreadedDebug: aMaker [
	self required.
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setGlobalOptionsBuildNone: aMaker [
	self required.
]

{ #category : #'squeak compatibility' }
TCPlatformConfigForSqueak >> setupDirectories:gen [
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setupDirectoriesBuild: aMaker [ 
	"convencience method to customize for this build. default is self setupDirectories: aMaker"
	self setupDirectories: aMaker

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setupDirectoriesBuildAssert: aMaker [ 
	"convencience method to customize for this build. default is self setupDirectories: aMaker"
	self setupDirectories: aMaker


]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setupDirectoriesBuildAssertITimerHeartbeat: aMaker [ 
	"convencience method to customize for this build. default is self setupDirectories: aMaker"
	self setupDirectories: aMaker




]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setupDirectoriesBuildDebug: aMaker [ 
	"convencience method to customize for this build. default is self setupDirectories: aMaker"
	self setupDirectories: aMaker




]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setupDirectoriesBuildDebugITimerHeartbeat: aMaker [ 
	"convencience method to customize for this build. default is self setupDirectories: aMaker"
	self setupDirectories: aMaker


]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setupDirectoriesBuildITimerHeartbeat: aMaker [ 
	"convencience method to customize for this build. default is self setupDirectories: aMaker"
	self setupDirectories: aMaker
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setupDirectoriesBuildMultiThreaded: aMaker [ 
	"convencience method to customize for this build. default is self setupDirectories: aMaker"
	self setupDirectories: aMaker
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setupDirectoriesBuildMultiThreadedAssert: aMaker [ 
	"convencience method to customize for this build. default is self setupDirectories: aMaker"
	self setupDirectories: aMaker
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setupDirectoriesBuildMultiThreadedDebug: aMaker [ 
	"convencience method to customize for this build. default is self setupDirectories: aMaker"
	self setupDirectories: aMaker
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> setupDirectoriesBuildNone: aMaker [ 
	"WE SHOULD NEVER GET HERE"
	self halt.

]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> squeakCogSpur [
	^'squeak.cog.spur'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> squeakCogV3 [
	^'squeak.cog.v3'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> squeakSistaSpur [
	^'squeak.sista.Spur'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> squeakSistaV3 [
	^'squeak.sista.v3'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> squeakStackSpur [
	^'squeak.stack.spur'
]

{ #category : #'cmake directory ' }
TCPlatformConfigForSqueak >> squeakStackV3 [
	^'squeak.stack.v3'
]

{ #category : #'squeak compatibility' }
TCPlatformConfigForSqueak >> srcDir [
	self required
]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> standardIncludesBuild [
	"convencience method to customize for this build. default is self standardIncludes"
	^self standardIncludes

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> standardIncludesBuildAssert [ 
	"convencience method to customize for this build. default is self standardIncludes"
	^self standardIncludes

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> standardIncludesBuildAssertITimerHeartbeat [ 
	"convencience method to customize for this build. default is self standardIncludes"
	^self standardIncludes

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> standardIncludesBuildDebug [ 
	"convencience method to customize for this build. default is self standardIncludes"
	^self standardIncludes

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> standardIncludesBuildDebugITimerHeartbeat [ 
	"convencience method to customize for this build. default is self standardIncludes"
	^self standardIncludes

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> standardIncludesBuildITimerHeartbeat [ 
	"convencience method to customize for this build. default is self standardIncludes"
	^self standardIncludes

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> standardIncludesBuildMultiThreaded [ 
	"convencience method to customize for this build. default is self standardIncludes"
	^self standardIncludes

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> standardIncludesBuildMultiThreadedAssert [
	"convencience method to customize for this build. default is self standardIncludes"
	^self standardIncludes

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> standardIncludesBuildMultiThreadedDebug [ 
	"convencience method to customize for this build. default is self standardIncludes"
	^self standardIncludes

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> standardIncludesBuildNone [
	"SHOULD NOT GET HERE"
	^self halt

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> thirdpartyLibsBuild [ 
	"convenience method to customize third party libs for this buildType.  default is self  thirdpartyLibs"
	^self thirdpartyLibs

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> thirdpartyLibsBuildAssert [ 
	"convenience method to customize third party libs for this buildType.  default is self  thirdpartyLibs"
	^self thirdpartyLibs

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> thirdpartyLibsBuildAssertITimerHeartbeat [ 
	"convenience method to customize third party libs for this buildType.  default is self  thirdpartyLibs"
	^self thirdpartyLibs

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> thirdpartyLibsBuildDebug [ 
	"convenience method to customize third party libs for this buildType.  default is self  thirdpartyLibs"
	^self thirdpartyLibs

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> thirdpartyLibsBuildDebugITimerHeartbeat [ 
	"convenience method to customize third party libs for this buildType.  default is self  thirdpartyLibs"
	^self thirdpartyLibs

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> thirdpartyLibsBuildITimerHeartbeat [ 
	"convenience method to customize third party libs for this buildType.  default is self  thirdpartyLibs"
	^self thirdpartyLibs

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> thirdpartyLibsBuildMultiThreaded [ 
	"convenience method to customize third party libs for this buildType.  default is self  thirdpartyLibs"
	^self thirdpartyLibs

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> thirdpartyLibsBuildMultiThreadedAssert [
	"convenience method to customize third party libs for this buildType.  default is self  thirdpartyLibs"
	^self thirdpartyLibs

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> thirdpartyLibsBuildMultiThreadedDebug [ 
	"convenience method to customize third party libs for this buildType.  default is self  thirdpartyLibs"
	^self thirdpartyLibs

]

{ #category : #'cmake config build type ' }
TCPlatformConfigForSqueak >> thirdpartyLibsBuildNone [ 
	"convenience method to customize third party libs for this buildType.  default is self  thirdpartyLibs"
	^self thirdpartyLibs

]

{ #category : #'squeak compatibility' }
TCPlatformConfigForSqueak >> topDir [
	self required
]

{ #category : #'squeak compatibility' }
TCPlatformConfigForSqueak >> validateSourcesPresent [
	self required
]

{ #category : #accessing }
TCPlatformConfigForSqueak >> version [
	^ ''
]

{ #category : #'cmake executable names' }
TCPlatformConfigForSqueak >> vmCogExecutableName [
	"the name of the cog vm executable"
	^'cog'
]

{ #category : #'cmake executable names' }
TCPlatformConfigForSqueak >> vmSistaExecutableName [
	"the name of the sista vm executable"
	^'sista'
]

{ #category : #'cmake executable names' }
TCPlatformConfigForSqueak >> vmStackExecutableName [
	"the name of the stack vm executable"
	^'squeak'
]

{ #category : #'squeak compatibility' }
TCPlatformConfigForSqueak >> write: aContents toFile: aFileName [
	self required
]
