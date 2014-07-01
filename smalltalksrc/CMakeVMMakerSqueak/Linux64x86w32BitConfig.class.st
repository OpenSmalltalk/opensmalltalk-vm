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
Linux64x86w32BitConfig >> addVMDrivers: maker [
"
libICE
ICE is the Inter Client Exchange protocol, part of X11

libSM
session management library for X11

"
	 self 
		addDriver: 'vm-display-null' 
		sources: #( 
			'${targetPlatform}/vm-display-null/sqUnixDisplayNull' )
		generator: maker
		externalLibs: #();
		
		
		addDriver: 'vm-display-X11' 
		sources: #( 
			'${targetPlatform}/vm-display-X11/sqUnixX11'
			'${targetPlatform}/vm-display-X11/sqUnixMozilla' )
		generator: maker
		
		"-lSM -lICE -ldl -lGL -lpthread -lm -lnsl -lX11'"
		externalLibs: #( SM ICE GL X11 nsl dl);
		

		addDriver: 'vm-sound-ALSA' 
		sources: #( 
			'${targetPlatform}/vm-sound-ALSA/sqUnixSoundALSA' )
		generator: maker
		externalLibs: #();

		addDriver: 'vm-sound-null' 
		sources: #( 
			'${targetPlatform}/vm-sound-null/sqUnixSoundNull' )
		generator: maker
		externalLibs: #().
	
"
vm-display-null
	vm-display-X11
	vm-sound-ALSA
	vm-sound-null"
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
		externalLibs: #( SM ICE GL X11 nsl dl);  "(self linkFlags);"

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
Linux64x86w32BitConfig >> configHBuild [
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

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> configHBuildAssert [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> configHBuildAssertITimerHeartbeat [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> configHBuildDebug [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> configHBuildDebugITimerHeartbeat [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> configHBuildITimerHeartbeat [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> configHBuildMultiThreaded [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> configHBuildMultiThreadedAssert [
	^ self configHBuild
]

{ #category : #'cmake buildType redirects' }
Linux64x86w32BitConfig >> configHBuildMultiThreadedDebug [
	^ self configHBuild
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
" tty 2014.06.10  cut-n-paste from Cog/build.linux32x86/newspeak.cog.spur/build/plugins.ext"
	^ #(B3DAcceleratorPlugin 
		BochsIA32Plugin 
	      ThreadedFFIPlugin    "moduleName->SqueakFFIPrims "
		"FFIPlugin"                   "moduleName->SqueakFFIPrims "
		SqueakSSLPlugin       "moduleName->SqueakSSL" 
		LocalePlugin 
		UnixOSProcessPlugin 
		UUIDPlugin)


"N.B. Regarding ThreadedFFIPlugin and FFIPlugin from eem:

Use  ThreadedFFIPlugin.  The FFIPlugin is obsolete (it requires assembler support files, and is non-reentrant).  
This should generate in src/plugins/SqueakFFIPrims/{SqueakFFIPrims.c,ARM32FFIPlugin.c,IA32FFIPlugin.c} and 
you should compile only src/plugins/SqueakFFIPrims/SqueakFFIPrims.c.  
src/plugins/SqueakFFIPrims/SqueakFFIPrims.c is a simple wrapper that includes 
ARM32FFIPlugin.c or IA32FFIPlugin.c as appropriate 
(and others can be added as they are developed).


"
]

{ #category : #plugins }
Linux64x86w32BitConfig >> defaultInternalPlugins [
" tty 2014.06.10  cut-n-paste from Cog/build.linux32x86/newspeak.cog.spur/build/plugins.int
   N.B. moduleName->XYZ means XYZ appears in the GNU-Build's plugins.int/ext. However, Smalltalk requires the class name.
                                 XYZSmalltalkClass  moduleName->XYZ as it appears in plugins.int/ext
"
	^ #(
	    ADPCMCodecPlugin
    AsynchFilePlugin
    BalloonEnginePlugin "moduleName -->B2DPlugin"
    BitBltSimulation        "moduleName->BitBltPlugin"
    BMPReadWriterPlugin
    CroquetPlugin
    DeflatePlugin               "moduleName->ZipPlugin"
    DropPlugin
    DSAPlugin                    "moduleName->DSAPrims"
    FFTPlugin
    FileCopyPlugin
    FilePlugin
    FloatArrayPlugin
    FloatMathPlugin
    IA32ABIPlugin             "moduleName->IA32ABI"
   " InflatePlugin"               "moduleName->ZipPlugin"   "already included with the DeflatePlugin"
    JoystickTabletPlugin
    JPEGReaderPlugin
    JPEGReadWriter2Plugin
    KlattSynthesizerPlugin  "moduleName->Klatt"
    LargeIntegersPlugin      "moduleName->LargeIntegers"
    Matrix2x3Plugin
    MIDIPlugin
    MiscPrimitivePlugin
    Mpeg3Plugin
    RePlugin
    SecurityPlugin
    SerialPlugin
    SocketPlugin
    SoundCodecPlugin        "moduleName->SoundCodecPrims"
    SoundGenerationPlugin
    SoundPlugin
    StarSqueakPlugin
    SurfacePlugin
    VMProfileLinuxSupportPlugin)
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
Linux64x86w32BitConfig >> extraVMSettingsBuild: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettingsBuild:'"

	| versionC |
	aMaker message: 'extraVMSettingsBuild: aMaker'.
	self generateConfigH.
	
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



	aMaker message: 'setExtraTargetPropertiesBuild: aMaker'.		

	aMaker setTargetProperties: 'LINK_FLAGS "-m32"'.
	aMaker puts: 'set_source_files_properties( ${srcVMDir}/cogit.c PROPERTIES 
		COMPILE_FLAGS "' , self compilerFlags , '")'.
		
	
	aMaker 
		cmd: 'set_source_files_properties'
		params: ' ${targetPlatform}/vm/sqUnixHeartbeat.c PROPERTIES 
		COMPILE_FLAGS "' , self compilerFlags , '"'.
	
	aMaker addExternalLibraries: 
		#(
			'uuid'  ""
			'ssl'  ""
			'crypto' ""
			'm'  
			'dl' 
			'pthread' 
		).
				

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
"	aMaker set: 'CMAKE_FIND_ROOT_PATH' to: '/usr/lib  ' "	
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
	aMaker linkDirectories: '/usr/lib'.

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
