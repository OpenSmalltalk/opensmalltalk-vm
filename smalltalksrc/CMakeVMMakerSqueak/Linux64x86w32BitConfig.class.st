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

{ #category : #cmake }
Linux64x86w32BitConfig >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder default allBuildConfigurations copyWithoutAll:#(#releaseMultiThreadedFFI #debugMultiThreadedFFI)

]

{ #category : #'compiler flags' }
Linux64x86w32BitConfig >> commonCompilerFlags [
	self flag: 'tty'. "pull up common flags from subclasses on a refactoring pass."
	^#()
]

{ #category : #'compiler flags' }
Linux64x86w32BitConfig >> compilerFlags [
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
Linux64x86w32BitConfig >> compilerFlagsAssert [
	self required
]

{ #category : #'compiler flags' }
Linux64x86w32BitConfig >> compilerFlagsAssertITimerHeartbeat [
	self required
]

{ #category : #'compiler flags' }
Linux64x86w32BitConfig >> compilerFlagsBuild [
	"backwards compatability with pharo. If adding, override compilerFlagsRelease in your configuration."

	^self compilerFlagsRelease.
]

{ #category : #cmake }
Linux64x86w32BitConfig >> compilerFlagsDebug [

	^ {
		'-g3'. 
		'-O0'. 
		'-msse2'. 
		'-D_GNU_SOURCE'. 
		'-DITIMER_HEARTBEAT=1'. 
		'-DNO_VM_PROFILE=1'. 
		'-DDEBUGVM=1' }
]

{ #category : #'compiler flags' }
Linux64x86w32BitConfig >> compilerFlagsDebugITimerHeartbeat [
	self required
]

{ #category : #'compiler flags' }
Linux64x86w32BitConfig >> compilerFlagsDebugMultiThreaded [
	self required
]

{ #category : #'compiler flags' }
Linux64x86w32BitConfig >> compilerFlagsIHeartbeatTimer [
	self required
]

{ #category : #'compiler flags' }
Linux64x86w32BitConfig >> compilerFlagsMultiThreaded [
	self required
]

{ #category : #'compiler flags' }
Linux64x86w32BitConfig >> compilerFlagsMultiThreadedAssert [
	self required
]

{ #category : #'compiler flags' }
Linux64x86w32BitConfig >> compilerFlagsMultiThreadedDebug [
	self required
]

{ #category : #'compiler flags' }
Linux64x86w32BitConfig >> compilerFlagsNoBuildType [
	self shouldNotImplement.
]

{ #category : #cmake }
Linux64x86w32BitConfig >> configureBuild [
	"configure this Configuration for a buildType #build"
	self 
		preferredIncludesBuild;
		standardIncludesBuild;
		compilerFlagsBuild;
		internalPluginsBuild;
		externalPluginsBuild;
		thirdpartyLibsBuild.

]

{ #category : #cmake }
Linux64x86w32BitConfig >> configureBuildAssert [
	self required
]

{ #category : #cmake }
Linux64x86w32BitConfig >> configureBuildAssertITimerHeartbeat [
	generateBuildAssertITimerHeartbeat:=true.
]

{ #category : #cmake }
Linux64x86w32BitConfig >> configureBuildDebug [
	self required
]

{ #category : #cmake }
Linux64x86w32BitConfig >> configureBuildDebugITimerHeartbeat [
	self required
]

{ #category : #cmake }
Linux64x86w32BitConfig >> configureBuildDebugMultiThreaded [
	self required
]

{ #category : #cmake }
Linux64x86w32BitConfig >> configureBuildIHeartbeatTimer [
	self required
]

{ #category : #cmake }
Linux64x86w32BitConfig >> configureBuildMultiThreaded [
	self required
]

{ #category : #cmake }
Linux64x86w32BitConfig >> configureBuildMultiThreadedAssert [
	self required
]

{ #category : #cmake }
Linux64x86w32BitConfig >> configureBuildMultiThreadedDebug [
	self required
]

{ #category : #cmake }
Linux64x86w32BitConfig >> configureForBuildType: aSymbol [
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
Linux64x86w32BitConfig >> configureNoBuildType [
		generateBuild:=generateBuildAssert:=generateBuildAssertITimerHeartbeat:=generateBuildDebug:=generateBuildDebugITimerHeartbeat:= generateBuildDebugMultiThreaded:= generateBuildIHeartbeatTimer:= generateBuildMultiThreaded:= generateBuildMultiThreadedAssert:= generateBuildMultiThreadedDebug:=false.
]

{ #category : #sources }
Linux64x86w32BitConfig >> coreSources [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
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
Linux64x86w32BitConfig >> dirARMv6 [
	^'cmake.build.arm.v6'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirAndroid [
	^'Do Not Build. See Class Comment'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirArmv6 [
	^'cmake.build.arm.v6'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirBSD32x86 [
	^'cmake.build.bsd32x86'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirBuild [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #build
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirBuildAssert [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildAssert
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirBuildAssertITimerHeartbeat [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildAssertITimerHeartbeat
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirBuildDebug [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #debug
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirBuildDebugITimerHeartbeat [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #debugITimerHeartbeat
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirBuildDebugMultiThreaded [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #debugMultiThreaded
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirBuildITimerHeartbeat [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildITimerHeartbeat
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogV3
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirBuildMultiThreaded [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildMultiThreaded
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirBuildMultiThreadedAssert [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildMultiThreadedAssert
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirBuildMultiThreadedDebug [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildMultiThreadedDebug
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirLinux32x86
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirIA32Bochs [
	^'cmake.build.ia32bochs'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirIOS [
	^'cmake.build.ios'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirInstall [
	"the directory of the finished product.. the place where 'make install' puts stuff.
	SystemNavigation default browseMethodsWhoseNamesContain: 'outputDir'
      "
self required.

]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirLinux32Armv6 [
	^'cmake.build.linux32armv6'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirLinux32x86 [
	^'cmake.build.linux32x86'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirLinux32x8664 [
	^'cmake.build.linux32_64x86'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirMacOS [
	^'cmake.build.macos'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirMacOSPowerPC [
	^'cmake.build.macospowerpc'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirMacOSX32x86 [
	^'cmake.build.macosx32x86'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirOutput [
	^'cmake.products'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirSource [
	^'src'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirSunOS32x86 [
	^'cmake.build.sunos32x86'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> dirWin32x86 [
	^'cmake.build.win32x86'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> eventStackV3 [
	"needed by Android config to pass internal tests. Android config is not built"
	^'do not build'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #accessing }
Linux64x86w32BitConfig >> executableName [
	self subclassResponsibility
]

{ #category : #'plugin extra rules' }
Linux64x86w32BitConfig >> extraPluginSettings: maker [
	super extraPluginSettings: maker.  
	maker set: #linkFlags toString: '${linkFlags} -m32'
]

{ #category : #sources }
Linux64x86w32BitConfig >> extraSources [
	self flag: 'tty'. "what is this?"
	^ 'version.c'
]

{ #category : #settings }
Linux64x86w32BitConfig >> extraVMSettings: maker [
	| versionC |
	self generateConfigH.
	
	"add a generated version.c"
	
	versionC := 'version.c'.
	
	maker cmd: 'add_custom_command' params: 'OUTPUT ',
		versionC , '
		COMMAND ${platformsDir}/unix/config/verstamp ',versionC,' gcc
		COMMENT "Generating version.c"
	'.
	
	
]

{ #category : #'headers generation' }
Linux64x86w32BitConfig >> generateConfigH [
	"	
	used to be: 	
		self write: self configH toFile: 'config.h'
      but with variable buildTypes we need:
"
	self write: (self generateConfigH: buildType asSymbol) toFile: 'config.h'   

]

{ #category : #'headers generation' }
Linux64x86w32BitConfig >> generateConfigH: aBuildType [
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

{ #category : #'initialize-release' }
Linux64x86w32BitConfig >> initialize [
	super initialize.
	"this should be in my superclass, but I do not have permission to modify it. tty"
 generateBuild:=generateBuildAssert:=generateBuildAssertITimerHeartbeat:=generateBuildDebug:=generateBuildDebugITimerHeartbeat :=generateBuildDebugMultiThreaded:=generateBuildIHeartbeatTimer:=generateBuildMultiThreaded:=generateBuildMultiThreadedAssert:= generateBuildMultiThreadedDebug:=false

]

{ #category : #accessing }
Linux64x86w32BitConfig >> linkFlags [
"	^ super linkFlags , ' -luuid -lSM -lICE -ldl -lGL -lpthread -lm -lnsl -lX11'"
	^ super linkFlags , ' -luuid -lSM -lICE -ldl  -lpthread -lm -lnsl -lX11'


]

{ #category : #cmake }
Linux64x86w32BitConfig >> newspeakCogSpur [
	^'newspeak.cog.spur'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> newspeakCogV3 [
	^'newspeak.cog.v3'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> newspeakSistaSpur [
	^'newspeak.sista.Spur'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> newspeakSistaV3 [
	^'newspeak.sista.v3'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> newspeakStackSpur [
	^'newspeak.stack.spur'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> newspeakStackV3 [
	^'newspeak.stack.v3'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> oscogvm [
	^ 'oscogvm'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> outputDirName [
	^ 'products'
]

{ #category : #sources }
Linux64x86w32BitConfig >> platformSources [
	"files added from platform/unix/vm dir "
	^ #(
	'aio.c'
	'debug.c'
"	'dlfcn-dyld.c'
	'mac-alias.c' "
	'osExports.c'
	'sqUnixCharConv.c'
"	'sqUnixEvent.c' "
	'sqUnixExternalPrims.c'
	'sqUnixHeartbeat.c'
	'sqUnixMain.c'
	'sqUnixMemory.c'
	'sqUnixThreads.c'
	'sqUnixVMProfile.c'
	)
]

{ #category : #'source files' }
Linux64x86w32BitConfig >> preferredIncludes [
	self flag:'tty'. "pharo does not support newspeak or sista., yet sets this in CogUnixConfig. Is this appropriate here? Revisit when coding newspeak etc"
	^ #(  '${targetPlatform}/plugins/AioPlugin'
 '${targetPlatform}/plugins/B3DAcceleratorPlugin'
 '${targetPlatform}/plugins/DropPlugin'
 '${targetPlatform}/plugins/FilePlugin'
 '${targetPlatform}/plugins/HostWindowPlugin'
 '${targetPlatform}/plugins/JPEGReadWriter2Plugin'
 '${targetPlatform}/plugins/LocalePlugin'
 '${targetPlatform}/plugins/Mpeg3Plugin'
 '${targetPlatform}/plugins/PseudoTTYPlugin'
 '${targetPlatform}/plugins/SerialPlugin'
 '${targetPlatform}/plugins/SoundPlugin'
 '${crossDir}/plugins/SoundGenerationPlugin'
 '${targetPlatform}/plugins/SqueakSSL'
 '${targetPlatform}/plugins/UnixOSProcessPlugin'
 '${targetPlatform}/plugins/AsynchFilePlugin'
 '${targetPlatform}/plugins/BochsIA32Plugin'
 '${targetPlatform}/plugins/FileCopyPlugin'
 '${targetPlatform}/plugins/FloatMathPlugin'
 '${targetPlatform}/plugins/InternetConfigPlugin'
 '${targetPlatform}/plugins/JoystickTabletPlugin'
 '${targetPlatform}/plugins/MIDIPlugin'
 '${targetPlatform}/plugins/PrintJobPlugin'
 '${targetPlatform}/plugins/SecurityPlugin'
 '${targetPlatform}/plugins/SocketPlugin'
 '${targetPlatform}/plugins/SqueakFFIPrims'
 '${targetPlatform}/plugins/UUIDPlugin'    
 '${targetPlatform}/plugins/XDisplayControlPlugin'

)


	

"SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'"
	
]

{ #category : #utils }
Linux64x86w32BitConfig >> setExtraTargetProperties: maker [
	self flag:'tty'. "I am nervous about this method up here in this class, but pharo has it in CogUnixConfig, so using as is for now"

	maker setTargetProperties: 'LINK_FLAGS "-m32"'.
		
	maker puts: 'set_source_files_properties( ${srcVMDir}/cogit.c PROPERTIES 
		COMPILE_FLAGS "-O1 -fno-omit-frame-pointer -momit-leaf-frame-pointer -mno-rtd -mno-accumulate-outgoing-args")'.
		
	
	maker 
		cmd: 'set_source_files_properties'
		params: ' ${targetPlatform}/vm/sqUnixHeartbeat.c PROPERTIES 
		COMPILE_FLAGS "-O1 -fno-omit-frame-pointer -mno-rtd -mno-accumulate-outgoing-args"'.
	
	maker addExternalLibraries: 
		#(
			'uuid'  ""
			'ssl'  ""
			'crypto' ""
		).
					
	super setExtraTargetProperties: maker.

]

{ #category : #utils }
Linux64x86w32BitConfig >> setGlobalOptions: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions:'
	
	we subclass this in our concrete builder and route it to "

	^self setGlobalOptions: aMaker buildType: (buildType asSymbol)

]

{ #category : #utils }
Linux64x86w32BitConfig >> setGlobalOptions: aMaker buildType: aBuildType [
	"invoke correct setGlobalOptions for this buildType to allow per-buildType customization'"

	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self setGlobalOptionsBuild: aMaker];
		at: #buildAssert  put: [self setGlobalOptionsBuildAssert: aMaker];
		at: #buildAssertITimerHeartbeat  put: [self setGlobalOptionsBuildAssertITimerHeartbeat: aMaker];
            at:#buildDebug  put: [self setGlobalOptionsBuildDebug: aMaker];   "located in CMakeVMMaker CPlatformConfig"
		at: #buildDebugITimerHeartbeat  put: [self setGlobalOptionsBuildDebugITimerHeartbeat: aMaker ];
		at: #buildITimerHeartbeat  put: [self setGlobalOptionsBuildITimerHeartbeat: aMaker];
		at: #buildMultiThreaded  put: [self setGlobalOptionsBuildMultiThreaded: aMaker ];
		at: #buildMultiThreadedAssert  put: [self setGlobalOptionsBuildMultiThreadedAssert: aMaker];
		at: #buildMultiThreadedDebug   put: [self setGlobalOptionsBuildMultiThreadedDebug: aMaker ];
		at: #buildNone put:[self setGlobalOptionsBuildNone: aMaker].

	 ^((d at: ( aBuildType)) value)

]

{ #category : #utils }
Linux64x86w32BitConfig >> setGlobalOptionsAfterDetermineSystem: aMaker buildType: aBuildType [
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
Linux64x86w32BitConfig >> setGlobalOptionsAfterDetermineSystemBuild: aMaker [ 
	self required
]

{ #category : #'cmake config build type ' }
Linux64x86w32BitConfig >> setGlobalOptionsBuild: aMaker [
	"convenience method to customize setGlobalOptions: aMaker for this build type. 
	Default is in CPlatformConfig>setGlobalOptions: aMaker setGlobalOptions: aMaker"
	^super setGlobalOptions: aMaker
]

{ #category : #'cmake config build type ' }
Linux64x86w32BitConfig >> setGlobalOptionsBuildAssert: aMaker [
	"convenience method to customize setGlobalOptions: aMaker for this build type. 
	Default is in CPlatformConfig>setGlobalOptions: aMaker setGlobalOptions: aMaker"
	^super setGlobalOptions: aMaker
]

{ #category : #'cmake config build type ' }
Linux64x86w32BitConfig >> setGlobalOptionsBuildAssertITimerHeartbeat: aMaker [
	"convenience method to customize setGlobalOptions: aMaker for this build type. 
	Default is in CPlatformConfig>setGlobalOptions: aMaker setGlobalOptions: aMaker"
	^super setGlobalOptions: aMaker
]

{ #category : #'cmake config build type ' }
Linux64x86w32BitConfig >> setGlobalOptionsBuildDebug: aMaker [
	"convenience method to customize setGlobalOptions: aMaker for this build type. 
	Default is in CPlatformConfig>setGlobalOptions: aMaker setGlobalOptions: aMaker"
	^super setGlobalOptions: aMaker
]

{ #category : #'cmake config build type ' }
Linux64x86w32BitConfig >> setGlobalOptionsBuildDebugITimerHeartbeat: aMaker [
	"convenience method to customize setGlobalOptions: aMaker for this build type. 
	Default is in CPlatformConfig>setGlobalOptions: aMaker setGlobalOptions: aMaker"
	^super setGlobalOptions: aMaker
]

{ #category : #'cmake config build type ' }
Linux64x86w32BitConfig >> setGlobalOptionsBuildITimerHeartbeat: aMaker [
	"convenience method to customize setGlobalOptions: aMaker for this build type. 
	Default is in CPlatformConfig>setGlobalOptions: aMaker setGlobalOptions: aMaker"
	self break.
	^super setGlobalOptions: aMaker
]

{ #category : #'cmake config build type ' }
Linux64x86w32BitConfig >> setGlobalOptionsBuildMultiThreaded: aMaker [
	"convenience method to customize setGlobalOptions: aMaker for this build type. 
	Default is in CPlatformConfig>setGlobalOptions: aMaker setGlobalOptions: aMaker"
	^super setGlobalOptions: aMaker
]

{ #category : #'cmake config build type ' }
Linux64x86w32BitConfig >> setGlobalOptionsBuildMultiThreadedAssert: aMaker [
	"convenience method to customize setGlobalOptions: aMaker for this build type. 
	Default is in CPlatformConfig>setGlobalOptions: aMaker setGlobalOptions: aMaker"
	^super setGlobalOptions: aMaker
]

{ #category : #'cmake config build type ' }
Linux64x86w32BitConfig >> setGlobalOptionsBuildMultiThreadedDebug: aMaker [
	"convenience method to customize setGlobalOptions: aMaker for this build type. 
	Default is in CPlatformConfig>setGlobalOptions: aMaker setGlobalOptions: aMaker"
	^super setGlobalOptions: aMaker
]

{ #category : #cmake }
Linux64x86w32BitConfig >> squeakCogSpur [
	^'squeak.cog.spur'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> squeakCogV3 [
	^'squeak.cog.v3'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> squeakSistaSpur [
	^'squeak.sista.Spur'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> squeakSistaV3 [
	^'squeak.sista.v3'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> squeakStackSpur [
	^'squeak.stack.spur'
]

{ #category : #cmake }
Linux64x86w32BitConfig >> squeakStackV3 [
	^'squeak.stack.v3'
]
