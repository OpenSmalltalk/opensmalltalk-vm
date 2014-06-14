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

{ #category : #cmake }
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

{ #category : #cmake }
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

{ #category : #'compiler flags' }
TCPlatformConfigForSqueak >> compilerFlagsAssert [
	self required
]

{ #category : #'compiler flags' }
TCPlatformConfigForSqueak >> compilerFlagsAssertITimerHeartbeat [
	self required
]

{ #category : #'compiler flags' }
TCPlatformConfigForSqueak >> compilerFlagsBuild [
	"backwards compatability with pharo. If adding, override compilerFlagsRelease in your configuration."
	^self compilerFlagsRelease.
]

{ #category : #'compiler flags' }
TCPlatformConfigForSqueak >> compilerFlagsDebug [
	self required
]

{ #category : #'compiler flags' }
TCPlatformConfigForSqueak >> compilerFlagsDebugITimerHeartbeat [
	self required
]

{ #category : #'compiler flags' }
TCPlatformConfigForSqueak >> compilerFlagsDebugMultiThreaded [
	self required
]

{ #category : #'compiler flags' }
TCPlatformConfigForSqueak >> compilerFlagsIHeartbeatTimer [
	self required
]

{ #category : #'compiler flags' }
TCPlatformConfigForSqueak >> compilerFlagsMultiThreaded [
	self required
]

{ #category : #'compiler flags' }
TCPlatformConfigForSqueak >> compilerFlagsMultiThreadedAssert [
	self required
]

{ #category : #'compiler flags' }
TCPlatformConfigForSqueak >> compilerFlagsMultiThreadedDebug [
	self required
]

{ #category : #'compiler flags' }
TCPlatformConfigForSqueak >> compilerFlagsNoBuildType [
	self shouldNotImplement.
]

{ #category : #'headers generation' }
TCPlatformConfigForSqueak >> configH [
	" right now its like  that "
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

#define OS_TYPE "unix"

#define VM_HOST "i386-freebsd8.2"
#define VM_HOST_CPU "i386"
/* #undef       VM_HOST_VENDOR */
#define VM_HOST_OS "freebsd8.2"
#define VM_BUILD_STRING "Unix built on "__DATE__ " "__TIME__" Compiler: "__VERSION__

/* #undef       WORDS_BIGENDIAN */
/* #undef       DOUBLE_WORD_ALIGNMENT */

/* damage containment */

/* #undef       DARWIN */

#ifdef NEED_SUNOS_H
# include "sunos.h"
#endif

/* other configured variables */

#define SQ_VERSION "3.9a-7024"
#define VM_VERSION "3.9-7"
#define VM_MODULE_PREFIX ""
/* #undef VM_DLSYM_PREFIX */
#define VM_X11DIR "/usr/X11R6/lib"

/* avoid dependencies on glibc2.3 */

/* #undef HAVE_FEATURES_H */

#if defined(HAVE_FEATURES_H)
# include "glibc.h"
#endif

#endif /* __sq_config_h */
																																																																					
																																																																				'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureBuild [
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureBuildAssert [
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureBuildAssertITimerHeartbeat [
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureBuildDebug [
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureBuildDebugITimerHeartbeat [
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureBuildDebugMultiThreaded [
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureBuildIHeartbeatTimer [
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureBuildMultiThreaded [
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureBuildMultiThreadedAssert [
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureBuildMultiThreadedDebug [
	self required
]

{ #category : #cmake }
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

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureNoBuildType [
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirARMv6 [
	^'cmake.build.arm.v6'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirAndroid [
	^'Do Not Build. See Class Comment'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirBSD32x86 [
	^'cmake.build.bsd32x86'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirBuild [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #build
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirBuildAssert [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildAssert
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirBuildAssertITimerHeartbeat [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildAssertITimerHeartbeat
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirBuildDebug [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #debug
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirBuildDebugITimerHeartbeat [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #debugITimerHeartbeat
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirBuildDebugMultiThreaded [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #debugMultiThreaded
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirBuildITimerHeartbeat [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildITimerHeartbeat
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirBuildMultiThreaded [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildMultiThreaded
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirBuildMultiThreadedAssert [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildMultiThreadedAssert
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirBuildMultiThreadedDebug [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildMultiThreadedDebug
]

{ #category : #cmake }
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

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirIA32Bochs [
	^'cmake.build.ia32bochs'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirIOS [
	^'cmake.build.ios'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirInstall [
	"the directory of the finished product.. the place where 'make install' puts stuff.
	SystemNavigation default browseMethodsWhoseNamesContain: 'outputDir'
      "
self required.

]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirLinux32Armv6 [
	^'cmake.build.linux32armv6'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirLinux32x86 [
	^'cmake.build.linux32x86'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirLinux32x8664 [
	^'cmake.build.linux32_64x86'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirMacOS [
	^'cmake.build.macos'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirMacOSPowerPC [
	^'cmake.build.macospowerpc'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirMacOSX32x86 [
	^'cmake.build.macosx32x86'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirOutput [
	^'cmake.products'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirSource [
	^'src'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirSunOS32x86 [
	^'cmake.build.sunos32x86'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirWin32x86 [
	^'cmake.build.win32x86'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> eventStackV3 [
	"needed by Android config to pass internal tests. Android config is not built"
	^'do not build'
]

{ #category : #cmake }
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
	"will fix that later"
	self write: self configH toFile: 'config.h'
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

{ #category : #cmake }
TCPlatformConfigForSqueak >> newspeakCogSpur [
	^'newspeak.cog.spur'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> newspeakCogV3 [
	^'newspeak.cog.v3'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> newspeakSistaSpur [
	^'newspeak.sista.Spur'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> newspeakSistaV3 [
	^'newspeak.sista.v3'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> newspeakStackSpur [
	^'newspeak.stack.spur'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> newspeakStackV3 [
	^'newspeak.stack.v3'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> oscogvm [
	^'oscogvm'
]

{ #category : #'squeak compatibility' }
TCPlatformConfigForSqueak >> outputDir [
	self required


]

{ #category : #cmake }
TCPlatformConfigForSqueak >> outputDirName [
	^ 'products'
]

{ #category : #'source files' }
TCPlatformConfigForSqueak >> preferredIncludes [
	^ #()

"SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'"
	
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

{ #category : #'squeak compatibility' }
TCPlatformConfigForSqueak >> setupDirectories:gen [
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> squeakCogSpur [
	^'squeak.cog.spur'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> squeakCogV3 [
	^'squeak.cog.v3'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> squeakSistaSpur [
	^'squeak.sista.Spur'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> squeakSistaV3 [
	^'squeak.sista.v3'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> squeakStackSpur [
	^'squeak.stack.spur'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> squeakStackV3 [
	^'squeak.stack.v3'
]

{ #category : #'squeak compatibility' }
TCPlatformConfigForSqueak >> srcDir [
	self required
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

{ #category : #'squeak compatibility' }
TCPlatformConfigForSqueak >> write: aContents toFile: aFileName [
	self required
]
