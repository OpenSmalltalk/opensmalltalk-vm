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
	#superclass : #SqueakUnixConfig,
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

{ #category : #'cmake buildType redirects' }
Linux64Config >> addVMDriversBuild: aMaker [
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
		externalLibs: (self linkFlags);

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
Linux64Config >> addVMDriversBuildAssert: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> addVMDriversBuildAssertITimerHeartbeat: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> addVMDriversBuildDebug: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> addVMDriversBuildDebugITimerHeartbeat: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> addVMDriversBuildITimerHeartbeat: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> addVMDriversBuildMultiThreaded: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> addVMDriversBuildMultiThreadedAssert: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> addVMDriversBuildMultiThreadedDebug: aMaker [
	^self addVMDriversBuild: aMaker
]

{ #category : #'cmake configuration' }
Linux64Config >> availableBuildTypes [
	 ^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes
"	subclasses should use

  ^super availableBuildTypes copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))   "
	

]

{ #category : #'as yet unclassified' }
Linux64Config >> configHBuild [
	self flag:'tty'. "This needs to be customized"
	^ '
#ifndef __sq_config_h
#define __sq_config_h

/* explicit image width */

#define	HAVE_INTERP_H 1

/* package options */

#define	USE_X11 1
#define	USE_X11_GLX 1
/* #undef	USE_QUARTZ */
/* #undef	USE_QUARTZ_CGL */
/* #undef	USE_RFB */

/* libraries */

/* #undef	HAVE_LIBX11 */
/* #undef	HAVE_LIBXEXT */
#define	HAVE_LIBDL 1
/* #undef	HAVE_DYLD */
/* #undef	HAVE_LIBFFI */
/* #undef	HAVE_ICONV */

/* #undef	USE_AUDIO_NONE */
/* #undef	USE_AUDIO_SUN */
/* #undef	USE_AUDIO_NAS */
/* #undef	USE_AUDIO_OSS */
/* #undef	USE_AUDIO_MACOSX */
/* #undef	OSS_DEVICE */

/* header files */

#define	HAVE_UNISTD_H 1
/* #undef	NEED_GETHOSTNAME_P */

#define	HAVE_DIRENT_H 1
/* #undef	HAVE_SYS_NDIR_H */
/* #undef	HAVE_SYS_DIR_H */
/* #undef	HAVE_NDIR_H */
#define	HAVE_DLFCN_H 1
#define	HAVE_ICONV_H 1

#define	HAVE_SYS_TIME_H 1
#define	TIME_WITH_SYS_TIME 1

/* #undef	HAVE_SYS_FILIO_H */

/* #undef	HAVE_SYS_AUDIOIO_H */
/* #undef	HAVE_SUN_AUDIOIO_H */

#define	HAVE_PTY_H 1
/* #undef	HAVE_UTIL_H */
/* #undef	HAVE_LIBUTIL_H */
#define	HAVE_STROPTS_H 1

#define	HAVE_GL_GL_H 1
/* #undef	HAVE_OPENGL_GL_H */

/* #undef	NEED_SUNOS_H */

/* system calls/library functions */

#define	AT_EXIT atexit

#define	HAVE_TZSET 1

#define	HAVE_OPENPTY 1
/* #undef	HAVE_UNIX98_PTYS */

#define	HAVE_SNPRINTF 1
/* #undef	HAVE___SNPRINTF */

#define	HAVE_MMAP 1

/* #undef	HAVE_DYLD */

#define	HAVE_LANGINFO_CODESET 1

#define	HAVE_ALLOCA 1
#define	HAVE_ALLOCA_H 1

#define	HAVE_UNSETENV 1

#define	HAVE_NANOSLEEP 1

/* widths of primitive types */

#define	SIZEOF_INT 4
#define	SIZEOF_LONG 4
#define	SIZEOF_LONG_LONG 8
#define	SIZEOF_VOID_P 4

/* structures */

#define	HAVE_TM_GMTOFF 1
#define	HAVE_TIMEZONE 1

/* typedefs */

/* #undef	size_t */
/* #undef	socklen_t */

#define	ENABLE_FAST_BLT 1
#define	squeakInt64 long long

/* architecture */

#define	OS_TYPE "unix"
#define __arm__ 1
#define __ARM_ARCH_6__ 1
#define	VM_HOST "arm-pc-linux-gnu"
#define	VM_HOST_CPU "arm"
/* #undef	VM_HOST_VENDOR */
#define	VM_HOST_OS "linux-gnu"
#define	VM_BUILD_STRING "Unix built on "__DATE__ " "__TIME__" Compiler: "__VERSION__

/* #undef	WORDS_BIGENDIAN */
/* #undef	DOUBLE_WORD_ALIGNMENT */

/* damage containment */

/* #undef	DARWIN */

#ifdef NEED_SUNOS_H
# include "sunos.h"
#endif

/* other configured variables */

#define SQ_VERSION "3.9a-7024"
#define VM_VERSION "3.9-7"
#define VM_MODULE_PREFIX ""
/* #undef VM_DLSYM_PREFIX */
#define VM_X11DIR ""

/* avoid dependencies on glibc2.3 */

#define HAVE_FEATURES_H 1

#if defined(HAVE_FEATURES_H)
# include "glibc.h"
#endif


/* used by UUID plugin: */

#define HAVE_UUID_H 1

#endif /* __sq_config_h */
																																																																					
																																																																				'
]

{ #category : #'as yet unclassified' }
Linux64Config >> configHBuildAssert [
	^ self configHBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> configHBuildAssertITimerHeartbeat [
	^ self configHBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> configHBuildDebug [
	^ self configHBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> configHBuildDebugITimerHeartbeat [
	^ self configHBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> configHBuildITimerHeartbeat [
	^ self configHBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> configHBuildMultiThreaded [
	^ self configHBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> configHBuildMultiThreadedAssert [
	^ self configHBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> configHBuildMultiThreadedDebug [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> coreSourcesBuild [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
		)
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> coreSourcesBuildAssert [
	^self coreSourcesBuild	
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> coreSourcesBuildAssertITimerHeartbeat [
	^self coreSourcesBuild	
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> coreSourcesBuildDebug [
	^self coreSourcesBuild	
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> coreSourcesBuildDebugITimerHeartbeat [
	^self coreSourcesBuild	
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> coreSourcesBuildITimerHeartbeat [
	^self coreSourcesBuild	
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> coreSourcesBuildMultiThreaded [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'cointerpmt.c'
		)
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> coreSourcesBuildMultiThreadedAssert [
	^self coreSourcesBuildMultiThreaded	
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> coreSourcesBuildMultiThreadedDebug [
	^self coreSourcesBuildMultiThreaded	
]

{ #category : #'source files' }
Linux64Config >> crossSources [ 
	^#(
			'sqHeapMap.c'
			'sqTicker.c'
			'sqExternalSemaphores.c'
			'sqNamedPrims.c'
			'sqVirtualMachine.c'
		)
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
Linux64Config >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirLinux64
]

{ #category : #cmake }
Linux64Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build"
	^true
]

{ #category : #cmake }
Linux64Config >> executableName [
	"AbstractBaseClass configurations are not meant to be executable"
	^ self vmIShouldNotBeHereExecutableName
]

{ #category : #'as yet unclassified' }
Linux64Config >> externalPluginsBuild [
	^ externalPlugins ifNil: [ externalPlugins := self defaultExternalPlugins ]
]

{ #category : #'as yet unclassified' }
Linux64Config >> externalPluginsBuildAssert [
	^ self externalPluginsBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> externalPluginsBuildAssertITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> externalPluginsBuildDebug [
	^ self externalPluginsBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> externalPluginsBuildDebugITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> externalPluginsBuildITimerHeartbeat [
	^ self externalPluginsBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> externalPluginsBuildMultiThreaded [
	^ self externalPluginsBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> externalPluginsBuildMultiThreadedAssert [
	^ self externalPluginsBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> externalPluginsBuildMultiThreadedDebug [
	^ self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> extraVMSettingsBuild: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettingsBuild:'"
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> extraVMSettingsBuildAssert: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> extraVMSettingsBuildAssertITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> extraVMSettingsBuildDebug: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> extraVMSettingsBuildDebugITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> extraVMSettingsBuildITimerHeartbeat: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> extraVMSettingsBuildMultiThreaded: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> extraVMSettingsBuildMultiThreadedAssert: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> extraVMSettingsBuildMultiThreadedDebug: aMaker [
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'as yet unclassified' }
Linux64Config >> internalPluginsBuild [
	^ internalPlugins ifNil: [ internalPlugins := self defaultInternalPlugins ]
]

{ #category : #'as yet unclassified' }
Linux64Config >> internalPluginsBuildAssert [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> internalPluginsBuildAssertITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> internalPluginsBuildDebug [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> internalPluginsBuildDebugITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> internalPluginsBuildITimerHeartbeat [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> internalPluginsBuildMultiThreaded [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> internalPluginsBuildMultiThreadedAssert [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'as yet unclassified' }
Linux64Config >> internalPluginsBuildMultiThreadedDebug [
   "	 internalPlugins := self defaultInternalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> postBuildActionsBuild: gen [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActionsBuild:'"
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> postBuildActionsBuildAssert: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> postBuildActionsBuildAssertITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> postBuildActionsBuildDebug: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> postBuildActionsBuildDebugITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> postBuildActionsBuildITimerHeartbeat: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> postBuildActionsBuildMultiThreaded: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> postBuildActionsBuildMultiThreadedAssert: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> postBuildActionsBuildMultiThreadedDebug: aMaker [
	^self postBuildActionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> preferredIncludesBuild [
"SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'"
	^ #( )

	

]

{ #category : #'cmake buildType redirects' }
Linux64Config >> preferredIncludesBuildAssert [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
Linux64Config >> preferredIncludesBuildAssertITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
Linux64Config >> preferredIncludesBuildDebug [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
Linux64Config >> preferredIncludesBuildDebugITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
Linux64Config >> preferredIncludesBuildITimerHeartbeat [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
Linux64Config >> preferredIncludesBuildMultiThreaded [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
Linux64Config >> preferredIncludesBuildMultiThreadedAssert [
	^self preferredIncludesBuild

]

{ #category : #'cmake buildType redirects' }
Linux64Config >> preferredIncludesBuildMultiThreadedDebug [
	^self preferredIncludesBuild

]

{ #category : #'as yet unclassified' }
Linux64Config >> setGlobalOptionsAfterDetermineSystemBuild: aMaker [
	"do nothing is an option

		SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsAfterDetermineSystemBuild:'"

]

{ #category : #'as yet unclassified' }
Linux64Config >> setGlobalOptionsAfterDetermineSystemBuildAssert: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'as yet unclassified' }
Linux64Config >> setGlobalOptionsAfterDetermineSystemBuildAssertITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'as yet unclassified' }
Linux64Config >> setGlobalOptionsAfterDetermineSystemBuildDebug: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'as yet unclassified' }
Linux64Config >> setGlobalOptionsAfterDetermineSystemBuildDebugITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'as yet unclassified' }
Linux64Config >> setGlobalOptionsAfterDetermineSystemBuildITimerHeartbeat: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'as yet unclassified' }
Linux64Config >> setGlobalOptionsAfterDetermineSystemBuildMultiThreaded: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'as yet unclassified' }
Linux64Config >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedAssert: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'as yet unclassified' }
Linux64Config >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedDebug: aMaker [
	^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
	
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> setGlobalOptionsBuild: aMaker [

	aMaker set: 'CMAKE_C_COMPILER' to: '/usr/bin/gcc'.
	aMaker set: 'CMAKE_CXX_COMPILER' to: '/usr/bin/g++'.

]

{ #category : #'as yet unclassified' }
Linux64Config >> setGlobalOptionsBuildAssert: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'as yet unclassified' }
Linux64Config >> setGlobalOptionsBuildAssertITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'as yet unclassified' }
Linux64Config >> setGlobalOptionsBuildDebug: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'as yet unclassified' }
Linux64Config >> setGlobalOptionsBuildDebugITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'as yet unclassified' }
Linux64Config >> setGlobalOptionsBuildITimerHeartbeat: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'as yet unclassified' }
Linux64Config >> setGlobalOptionsBuildMultiThreaded: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'as yet unclassified' }
Linux64Config >> setGlobalOptionsBuildMultiThreadedAssert: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'as yet unclassified' }
Linux64Config >> setGlobalOptionsBuildMultiThreadedDebug: aMaker [
	^self setGlobalOptionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
Linux64Config >> standardIncludesBuild [ 
	^#()
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> standardIncludesBuildAssert [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> standardIncludesBuildAssertITimerHeartbeat [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> standardIncludesBuildDebug [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> standardIncludesBuildDebugITimerHeartbeat [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> standardIncludesBuildITimerHeartbeat [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> standardIncludesBuildMultiThreaded [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> standardIncludesBuildMultiThreadedAssert [ 
	^ self standardIncludesBuild
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> standardIncludesBuildMultiThreadedDebug [ 
	^ self standardIncludesBuild
]
