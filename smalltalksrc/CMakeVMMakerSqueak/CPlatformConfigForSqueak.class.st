"
A CPlatformConfigForSqueak acts as a compatability layer for Squeak and an Abstract Base Class for extended functionality required for the Squeak CMakeVMMaker use-case.

I make (very) heavy use of a specific design pattern for configuring myself and remaining compatible with pharo's CMakeVMMaker.
The entry point for that pattern is my method 'configureForBuildType: aSymbol' . Each method send in there detects my buildType and routes the send
to the approriate method for that buildType.

Subclasses of me 'must' configure themselves for each build type per that pattern. 
However this can be very easy by just returning the base configuration.

Tests are written to verify that this support infrastructure is in place.

I have two important variables.

excludeFromBuild and isAbstractBaseClass.

excludeFromBuild 
		is used to exclude a configuration from being built by a Builder.
		is used to exclude a configuration from Testing.

isAbstractBaseClass 
		is a class instance variable used by configurations that exclude themselves from being built by a Builder BUT need to be included in 		Testing.

										
excludeFromBuild  | isAbstractBaseClass  | should build  | should test
	T					    T                            NO                  YES
      T					    F                             NO                   NO
      F					    T                            YES                  YES
      F                                 F                            YES                  YES


The use-case is as follows.

An abstract base class contains a lot of functionality that must be implemented and tested for the system to work, but it is not meant to be compiled.

concrete classes of that AbstractBase class can exclude themselves from being built by builders and by doing so are not tested.
However, once a concrete configuration is enabled to be built, it must pass all tests.

Linux32x86Config is an example of an AbstractBase class that must pass all testing, but is not buildable.
Its subclass Linux32x86SqueakCogV3Config needs testing, but a developer can toggle 'exclude from build' to hide it from Builders or make it available to them.

Tests make the decision on what configurations to test. Here are some examples.
	(o excludeFromBuild not) & (configuration isAbstractBaseClass not)  this is a concrete [Lang][VM][MemoryManager][etc] configuration that will be built. No platform classes considered
	(o excludeFromBuild) & (configuration isAbstractBaseClass not)         This is a concrete [Lang][VM][MemoryManager][etc] configuration that will be NOT built.
	(o excludeFromBuild not) | (configuration isAbstractBaseClass)          concrete implementation may depend on its [OS][VMWordSize][Processor] AbstractBaseClass for platform level methods. 
																		   example: Linux32x86Config ccBuild has the '-m32' compiler flag that is common to all builds on that platform
	(o excludeFromBuild not) & (configuration isAbstractBaseClass)       Not allowed. [OS][VMWordSize][Processor] AbstractBaseClasses should not be built. This is a useful test in its own right.
	(o excludeFromBuild) & (configuration isAbstractBaseClass)             These are the AbstractBaseClasses. An AbstractBaseClass should always be excluded from a build

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
	#classInstVars : [
		'isAbstractBaseClass'
	],
	#category : #CMakeVMMakerSqueak
}

{ #category : #'as yet unclassified' }
CPlatformConfigForSqueak class >> isAbstractBaseClass [
	^isAbstractBaseClass ifNil:[false] ifNotNil:[isAbstractBaseClass]

]

{ #category : #'as yet unclassified' }
CPlatformConfigForSqueak class >> isAbstractBaseClass: aBoolean [
	isAbstractBaseClass := aBoolean

]

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

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMDrivers: aMaker [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self addVMDriversBuild: aMaker];
		at: #buildAssert  put: [self addVMDriversBuildAssert: aMaker];
		at: #buildAssertITimerHeartbeat  put: [self addVMDriversBuildAssertITimerHeartbeat: aMaker];
            at:#buildDebug  put: [self addVMDriversBuildDebug: aMaker];   
		at: #buildDebugITimerHeartbeat  put: [self addVMDriversBuildDebugITimerHeartbeat: aMaker ];
		at: #buildITimerHeartbeat  put: [self addVMDriversBuildITimerHeartbeat: aMaker];
		at: #buildMultiThreaded  put: [self addVMDriversBuildMultiThreaded: aMaker ];
		at: #buildMultiThreadedAssert  put: [self addVMDriversBuildMultiThreadedAssert: aMaker];
		at: #buildMultiThreadedDebug   put: [self addVMDriversBuildMultiThreadedDebug: aMaker ];
		at: #buildNone put:[self addVMDriversNoBuildType:  aMaker].
	^(d at: buildType) value

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMDriversBuild: aMaker [
	"SqueakUnixConfig browse"
	self subclassResponsibility.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMDriversBuildAssert: aMaker [
	"SqueakUnixConfig browse"
	self subclassResponsibility.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMDriversBuildAssertITimerHeartbeat: aMaker [
	"SqueakUnixConfig browse"
	self subclassResponsibility.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMDriversBuildDebug: aMaker [
	"SqueakUnixConfig browse"
	self subclassResponsibility.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMDriversBuildDebugITimerHeartbeat: aMaker [
	"SqueakUnixConfig browse"
	self subclassResponsibility.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMDriversBuildITimerHeartbeat: aMaker [
	"SqueakUnixConfig browse"
	self subclassResponsibility.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMDriversBuildMultiThreadedAssert: aMaker [
	"SqueakUnixConfig browse"
	self subclassResponsibility.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMDriversBuildMultiThreadedDebug: aMaker [
	"SqueakUnixConfig browse"
	self subclassResponsibility.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMDriversNoBuildType: aMaker [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> androidPlatformName [
	^'android'
]

{ #category : #'cmake configuration' }
CPlatformConfigForSqueak >> availableBuildTypes [
	self subclassResponsibility.

	" ^SqueakCMakeVMMakerAbstractBuilder  default  noBuildTypes
	  ^(SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes
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
	"answer the build script build.sh"
	^ '#!/usr/bin/env bash
cmake .
make'
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

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> comilerFlagsBuildAssertITimerHeartbeat [
	 "This will be going away in place of cC, cXX, lDFlags, libs methods 
	^self cFlagsBuild
"

	self subclassResponsibility
]

{ #category : #'compiler flags' }
CPlatformConfigForSqueak >> commonCompilerFlags [
	self	subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> compilerFlags [
	|d flags|
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 		
		at: #build put: [self compilerFlagsBuild];
		at: #buildAssert  put: [self compilerFlagsBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self compilerFlagsBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self compilerFlagsBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self compilerFlagsBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self compilerFlagsBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self compilerFlagsBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self compilerFlagsBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self compilerFlagsBuildMultiThreadedDebug ];
		at: #buildNone put:[self compilerFlagsNoBuildType].
	flags := String
				streamContents: [:stream | ((d at: buildType) value collect: #withBlanksTrimmed as: Set)
						asStringOn: stream
						delimiter: ' '].
	^flags.

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> compilerFlagsBuild [
	 ""
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> compilerFlagsBuildAssert [
	 "^self comilerFlagsBuild
"

	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> compilerFlagsBuildDebug [
	 "^self compilerFlagsBuild"

	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> compilerFlagsBuildDebugITimerHeartbeat [
	 "	^self compilerFlagsBuild"

	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> compilerFlagsBuildITimerHeartbeat [
	 "^self comilerFlagsBuild
"

	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> compilerFlagsBuildMultiThreaded [
	 "^self comilerFlagsBuild
"

	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> compilerFlagsBuildMultiThreadedAssert [
	 "^self comilerFlagsBuild
"

	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> compilerFlagsBuildMultiThreadedDebug [
	 "^self comilerFlagsBuild
"

	self subclassResponsibility
]

{ #category : #'gnu build system mvm file' }
CPlatformConfigForSqueak >> configureFlags [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self configureFlagsBuild];
		at: #buildAssert  put: [self configureFlagsBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self configureFlagsBuildAssertITimerHeartbeat];
                at:#buildDebug  put: [self configureFlagsBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self configureFlagsBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self configureFlagsBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self configureFlagsBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self configureFlagsBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self configureFlagsBuildMultiThreadedDebug ];
		at: #buildNone put:[self configureFlagsNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> configureFlagsBuild [
	"flags to feed to a configure command in GNU
	configure --without-npsqueak --with-src=stacksrc --with-plugins=src/plugins --disable-cogi --without-vm-display-fbdev  --x-libraries=/usr/lib --without-gl 

	^{
		'-without-npsqueak' 
		. '--with-src=stacksrc' 
		. '--with-plugins=src/plugins' 
		. '--disable-cogit'
		. '--without-vm-display-fbdev'
		. '--x-libraries=/usr/lib'
		. '--without-gl'
		}"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> configureFlagsBuildAssert [
	"flags to feed to a configure command in GNU
	configure --without-npsqueak --with-src=stacksrc --with-plugins=src/plugins --disable-cogi --without-vm-display-fbdev  --x-libraries=/usr/lib --without-gl 

	^{
		'-without-npsqueak' 
		. '--with-src=stacksrc' 
		. '--with-plugins=src/plugins' 
		. '--disable-cogit'
		. '--without-vm-display-fbdev'
		. '--x-libraries=/usr/lib'
		. '--without-gl'
		}

	^self configureFlagsBuild
	"

	
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> configureFlagsBuildAssertITimerHeartbeat [
	"flags to feed to a configure command in GNU
	configure --without-npsqueak --with-src=stacksrc --with-plugins=src/plugins --disable-cogi --without-vm-display-fbdev  --x-libraries=/usr/lib --without-gl 

	^{
		'-without-npsqueak' 
		. '--with-src=stacksrc' 
		. '--with-plugins=src/plugins' 
		. '--disable-cogit'
		. '--without-vm-display-fbdev'
		. '--x-libraries=/usr/lib'
		. '--without-gl'
		}

	^self configureFlagsBuild
	"


	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> configureFlagsBuildDebug [
	"flags to feed to a configure command in GNU
	configure --without-npsqueak --with-src=stacksrc --with-plugins=src/plugins --disable-cogi --without-vm-display-fbdev  --x-libraries=/usr/lib --without-gl 

	^{
		'-without-npsqueak' 
		. '--with-src=stacksrc' 
		. '--with-plugins=src/plugins' 
		. '--disable-cogit'
		. '--without-vm-display-fbdev'
		. '--x-libraries=/usr/lib'
		. '--without-gl'
		}

	^self configureFlagsBuild
	"


	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> configureFlagsBuildDebugITimerHeartbeat [
	"flags to feed to a configure command in GNU
	configure --without-npsqueak --with-src=stacksrc --with-plugins=src/plugins --disable-cogi --without-vm-display-fbdev  --x-libraries=/usr/lib --without-gl 

	^{
		'-without-npsqueak' 
		. '--with-src=stacksrc' 
		. '--with-plugins=src/plugins' 
		. '--disable-cogit'
		. '--without-vm-display-fbdev'
		. '--x-libraries=/usr/lib'
		. '--without-gl'
		}

	^self configureFlagsBuild
	"


	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> configureFlagsBuildITimerHeartbeat [
	"flags to feed to a configure command in GNU
	configure --without-npsqueak --with-src=stacksrc --with-plugins=src/plugins --disable-cogi --without-vm-display-fbdev  --x-libraries=/usr/lib --without-gl 

	^{
		'-without-npsqueak' 
		. '--with-src=stacksrc' 
		. '--with-plugins=src/plugins' 
		. '--disable-cogit'
		. '--without-vm-display-fbdev'
		. '--x-libraries=/usr/lib'
		. '--without-gl'
		}

	^self configureFlagsBuild
	"


	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> configureFlagsBuildMultiThreaded [
	"flags to feed to a configure command in GNU
	configure --without-npsqueak --with-src=stacksrc --with-plugins=src/plugins --disable-cogi --without-vm-display-fbdev  --x-libraries=/usr/lib --without-gl 

	^{
		'-without-npsqueak' 
		. '--with-src=stacksrc' 
		. '--with-plugins=src/plugins' 
		. '--disable-cogit'
		. '--without-vm-display-fbdev'
		. '--x-libraries=/usr/lib'
		. '--without-gl'
		}

	^self configureFlagsBuild
	"


	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> configureFlagsBuildMultiThreadedAssert [
	"flags to feed to a configure command in GNU
	configure --without-npsqueak --with-src=stacksrc --with-plugins=src/plugins --disable-cogi --without-vm-display-fbdev  --x-libraries=/usr/lib --without-gl 

	^{
		'-without-npsqueak' 
		. '--with-src=stacksrc' 
		. '--with-plugins=src/plugins' 
		. '--disable-cogit'
		. '--without-vm-display-fbdev'
		. '--x-libraries=/usr/lib'
		. '--without-gl'
		}

	^self configureFlagsBuild
	"


	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> configureFlagsNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'cmake configuration' }
CPlatformConfigForSqueak >> configureForBuildType: aSymbol [
	"Set my internal state appropriate for my build type".
	self subclassResponsibility.

]

{ #category : #'cmake configuration' }
CPlatformConfigForSqueak >> configureNoBuildType [
		generateBuild:=generateBuildAssert:=generateBuildAssertITimerHeartbeat:=generateBuildDebug:=generateBuildDebugITimerHeartbeat:= generateBuildDebugMultiThreaded:= generateBuildIHeartbeatTimer:= generateBuildMultiThreaded:= generateBuildMultiThreadedAssert:= generateBuildMultiThreadedDebug:=false.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSources [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self coreSourcesBuild];
		at: #buildAssert  put: [self coreSourcesBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self coreSourcesBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self coreSourcesBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self coreSourcesBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self coreSourcesBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self coreSourcesBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self coreSourcesBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self coreSourcesBuildMultiThreadedDebug ];
		at: #buildNone put:[self coreSourcesNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSourcesBuild [
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSourcesBuildAssert [
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSourcesBuildAssertITimerHeartbeat [
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSourcesBuildDebug [
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSourcesBuildDebugITimerHeartbeat [
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSourcesBuildITimerHeartbeat [
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSourcesBuildMultiThreaded [
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSourcesBuildMultiThreadedAssert [
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSourcesBuildMultiThreadedDebug [
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSourcesNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'source files' }
CPlatformConfigForSqueak >> crossSources [ 
"	
	SystemNavigation default browseMethodsWhoseNamesContain: 'crossSources'

^#(
			'sqHeapMap.c'
			'sqTicker.c'
			'sqExternalSemaphores.c'
			'sqNamedPrims.c'
			'sqVirtualMachine.c'
		)
"
self subclassResponsibility
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

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPlugins [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self externalPluginsBuild];
		at: #buildAssert  put: [self externalPluginsBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self externalPluginsBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self externalPluginsBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self externalPluginsBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self externalPluginsBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self externalPluginsBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self externalPluginsBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self externalPluginsBuildMultiThreadedDebug ];
		at: #buildNone put:[self externalPluginsNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPluginsBuild [ 
	"convenience method to customize plugins for this build. 
	^self externalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPluginsBuildAssert [ 
	"convenience method to customize plugins for this build. 
	^self externalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPluginsBuildAssertITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins
	^self externalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPluginsBuildDebug [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins
	^self externalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPluginsBuildDebugITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins
	^self externalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPluginsBuildITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins
	^self externalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPluginsBuildMultiThreaded [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins
	^self externalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPluginsBuildMultiThreadedAssert [
	"convenience method to customize plugins for this build.  default is 
	^self externalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPluginsBuildMultiThreadedDebug [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins
	^self externalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPluginsNoBuildType [
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

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettingsBuild: maker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraPluginSettings'
	"
	self subclassResponsibility


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildAssert: maker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraPluginSettings'
	"
	self subclassResponsibility


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildAssertITimerHeartbeat: maker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraPluginSettings'
	"
	self subclassResponsibility


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildDebug: maker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraPluginSettings'
	"
	self subclassResponsibility


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildDebugITimerHeartbeat: maker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraPluginSettings'
	"
	self subclassResponsibility


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildITimerHeartbeat: maker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraPluginSettings'
	"
	self subclassResponsibility


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildMultiThreaded: maker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraPluginSettings'
	"
	self subclassResponsibility


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildMultiThreadedAssert: maker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraPluginSettings'
	"
	self subclassResponsibility


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildMultiThreadedDebug: maker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraPluginSettings'
	"
	self subclassResponsibility


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettingsNoBuildType: maker [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'source files' }
CPlatformConfigForSqueak >> extraSources [
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettings: aMaker [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self extraVMSettingsBuild: aMaker];
		at: #buildAssert  put: [self extraVMSettingsBuildAssert: aMaker];
		at: #buildAssertITimerHeartbeat  put: [self extraVMSettingsBuildAssertITimerHeartbeat: aMaker];
            at:#buildDebug  put: [self extraVMSettingsBuildDebug: aMaker];   
		at: #buildDebugITimerHeartbeat  put: [self extraVMSettingsBuildDebugITimerHeartbeat: aMaker ];
		at: #buildITimerHeartbeat  put: [self extraVMSettingsBuildITimerHeartbeat: aMaker];
		at: #buildMultiThreaded  put: [self extraVMSettingsBuildMultiThreaded: aMaker ];
		at: #buildMultiThreadedAssert  put: [self extraVMSettingsBuildMultiThreadedAssert: aMaker];
		at: #buildMultiThreadedDebug   put: [self extraVMSettingsBuildMultiThreadedDebug: aMaker ];
		at: #buildNone put:[self extraVMSettingsNoBuildType:  aMaker].
	^(d at: buildType) value

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettingsBuild: maker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettings'
	"

	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettingsBuildAssert: maker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettings'
	"

	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettingsBuildAssertITimerHeartbeat: maker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettings'
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettingsBuildDebug: maker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettings'
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettingsBuildDebugITimerHeartbeat: maker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettings'
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettingsBuildITimerHeartbeat: maker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettings'
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettingsBuildMultiThreaded: maker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettings'
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettingsBuildMultiThreadedAssert: maker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettings'
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettingsBuildMultiThreadedDebug: maker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettings'
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettingsNoBuildType: maker [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> fixLineEndsOf: string [
	^ string copyReplaceAll: String cr with: String crlf
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> frameworks [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self frameworksBuild];
		at: #buildAssert  put: [self frameworksBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self frameworksBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self frameworksBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self frameworksBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self frameworksBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self frameworksBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self frameworksBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self frameworksBuildMultiThreadedDebug ];
		at: #buildNone put:[self frameworksNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> frameworksBuild [
	"^#()"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> frameworksBuildAssert [ 
	"convenience method to customize plugins for this build default to internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> frameworksBuildAssertITimerHeartbeat [ 
	"convenience method to customize plugins for this build default to internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> frameworksBuildDebug [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> frameworksBuildDebugITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> frameworksBuildITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> frameworksBuildMultiThreaded [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> frameworksBuildMultiThreadedAssert [
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> frameworksBuildMultiThreadedDebug [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
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

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPlugins [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self internalPluginsBuild];
		at: #buildAssert  put: [self internalPluginsBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self internalPluginsBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self internalPluginsBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self internalPluginsBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self internalPluginsBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self internalPluginsBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self internalPluginsBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self internalPluginsBuildMultiThreadedDebug ];
		at: #buildNone put:[self internalPluginsNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPluginsBuild [ 
	"convenience method to customize plugins for this build default to internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPluginsBuildAssert [ 
	"convenience method to customize plugins for this build default to internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPluginsBuildAssertITimerHeartbeat [ 
	"convenience method to customize plugins for this build default to internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPluginsBuildDebug [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPluginsBuildDebugITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPluginsBuildITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPluginsBuildMultiThreaded [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPluginsBuildMultiThreadedAssert [
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPluginsBuildMultiThreadedDebug [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPluginsNoBuildType [
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

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> interpreterClassBuild [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClass



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> interpreterClassBuildAssert [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClass



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> interpreterClassBuildAssertITimerHeartbeat [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClass



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> interpreterClassBuildDebug [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClass



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> interpreterClassBuildDebugITImerHeartbeat [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClass



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> interpreterClassBuildITimerHeartbeat [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClass



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> interpreterClassBuildITimerMultiThreaded [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^CoInterpreterMT



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> interpreterClassBuildITimerMultiThreadedAssert [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClassBuildITimerMultiThreaded



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> interpreterClassBuildITimerMultiThreadedDebug [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClassBuildITimerMultiThreaded



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> interpreterClassNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.



]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> iosPlatformName [
	^'iOS'
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> lDFlags [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self lDFlagsBuild];
		at: #buildAssert  put: [self lDFlagsBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self lDFlagsBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self lDFlagsBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self lDFlagsBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self lDFlagsBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self lDFlagsBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self lDFlagsBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self lDFlagsBuildMultiThreadedDebug ];
		at: #buildNone put:[self lDFlagsNoBuildType].
	^(d at: buildType) value

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> lDFlagsBuild [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file
	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm
	^ { 
		'-Wl'
           . '-z'
           . 'now'
	   }

	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> lDFlagsBuildAssert [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file
	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm
	^ { 
		'-Wl'
           . '-z'
           . 'now'
	   }

	^self lDFlagsBuild
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> lDFlagsBuildAssertITimerHeartbeat [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file
	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm
	^ { 
		'-Wl'
           . '-z'
           . 'now'
	   }

	^self lDFlagsBuild
	"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> lDFlagsBuildDebug [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file
	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm
	^ { 
		'-Wl'
           . '-z'
           . 'now'
	   }

	^self lDFlagsBuild
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> lDFlagsBuildDebugITimerHeartbeat [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file
	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm
	^ { 
		'-Wl'
           . '-z'
           . 'now'
	   }

	^self lDFlagsBuild
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> lDFlagsBuildITimerHeartbeat [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file
	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm
	^ { 
		'-Wl'
           . '-z'
           . 'now'
	   }

	^self lDFlagsBuild
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> lDFlagsBuildMultiThreaded [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file
	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm
	^ { 
		'-Wl'
           . '-z'
           . 'now'
	   }

	^self lDFlagsBuild
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> lDFlagsBuildMultiThreadedAssert [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file
	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm
	^ { 
		'-Wl'
           . '-z'
           . 'now'
	   }

	^self lDFlagsBuild
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> lDFlagsBuildMultiThreadedDebug [
	"Answer array of flags like the  LDFLAGS=-Wl,-z,now  line in the GNU system's mvm file
	 cat Cog/build.linux32x86/squeak.cog.v3/build/mvm
	^ { 
		'-Wl'
           . '-z'
           . 'now'
	   }

	^self lDFlagsBuild
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> lDFlagsNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> linkFlags [
	" '-lSM -lICE -ldl -lGL -lpthread -lm -lnsl -lX11' -L/usr/lib32 etc..."
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self linkFlagsBuild];
		at: #buildAssert  put: [self linkFlagsBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self linkFlagsBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self linkFlagsBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self linkFlagsBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self linkFlagsBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self linkFlagsBuildMultiThreaded ];
		at: #buildMultiThreadedAssert  put: [self linkFlagsBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self linkFlagsBuildMultiThreadedDebug ];
		at: #buildNone put:[self linkFlagsNoBuildType].
	^(d at: buildType) value

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> linkFlagsBuild [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'linkFlagsBuild'

	^ { 
		'-lpthread'
           . '-luuid'
	   }
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> linkFlagsBuildAssert [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'linkFlagsBuildAssert'

	^ { 
		'-lpthread'
           . '-luuid'
	   }
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> linkFlagsBuildAssertITimerHeartbeat [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'linkFlagsBuildAssertITimerHeartbeat'

	^ { 
		'-lpthread'
           . '-luuid'
	   }
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> linkFlagsBuildDebug [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'linkFlagsBuildDebug'

	^ { 
		'-lpthread'
           . '-luuid'
	   }
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> linkFlagsBuildDebugITimerHeartbeat [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'linkFlagsBuildDebugITimerHeartbeat'

	^ { 
		'-lpthread'
           . '-luuid'
	   }
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> linkFlagsBuildITimerHeartbeat [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'linkFlagsBuildITimerHeartbeat'

	^ { 
		'-lpthread'
           . '-luuid'
	   }
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> linkFlagsBuildMultiThreaded [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'linkFlagsBuildMultiThreaded'

	^ { 
		'-lpthread'
           . '-luuid'
	   }
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> linkFlagsBuildMultiThreadedAssert [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'linkFlagsBuildMultiThreadedAssert'

	^ { 
		'-lpthread'
           . '-luuid'
	   }
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> linkFlagsBuildMultiThreadedDebug [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'linkFlagsBuildMultiThreadedDebug'

	^ { 
		'-lpthread'
           . '-luuid'
	   }
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> linkFlagsNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> macOSPlatformName [
	^'Mac OS'
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

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> nilPlatformName [
	^nil
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

"	
	SystemNavigation default browseMethodsWhoseNamesContain: 'platformSources'

^#( platform specific array)
"

	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActions: aMaker [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self postBuildActionsBuild: aMaker];
		at: #buildAssert  put: [self postBuildActionsBuildAssert: aMaker];
		at: #buildAssertITimerHeartbeat  put: [self postBuildActionsBuildAssertITimerHeartbeat: aMaker];
            at:#buildDebug  put: [self postBuildActionsBuildDebug: aMaker];   
		at: #buildDebugITimerHeartbeat  put: [self postBuildActionsBuildDebugITimerHeartbeat: aMaker ];
		at: #buildITimerHeartbeat  put: [self postBuildActionsBuildITimerHeartbeat: aMaker];
		at: #buildMultiThreaded  put: [self postBuildActionsBuildMultiThreaded: aMaker ];
		at: #buildMultiThreadedAssert  put: [self postBuildActionsBuildMultiThreadedAssert: aMaker];
		at: #buildMultiThreadedDebug   put: [self postBuildActionsBuildMultiThreadedDebug: aMaker ];
		at: #buildNone put:[self postBuildActionsNoBuildType:  aMaker].
	^(d at: buildType) value

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActionsBuild: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActions'

	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActionsBuildAssert: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActions'

	^self postBuildActionsBuild:: aMaker
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActionsBuildAssertITimerHeartbeat: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActions'

	^self postBuildActionsBuild:: aMaker
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActionsBuildDebug: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActions'

	^self postBuildActionsBuild:: aMaker
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActionsBuildDebugITimerHeartbeat: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActions'

	^self postBuildActionsBuild:: aMaker
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActionsBuildITimerHeartbeat: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActions'

	^self postBuildActionsBuild:: aMaker
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActionsBuildMultiThreaded: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActions'

	^self postBuildActionsBuild:: aMaker
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActionsBuildMultiThreadedAssert: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActions'

	^self postBuildActionsBuild:: aMaker
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActionsBuildMultiThreadedDebug: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActions'

	^self postBuildActionsBuild:: aMaker
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActionsNoBuildType: aMaker [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludes [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self preferredIncludesBuild];
		at: #buildAssert  put: [self preferredIncludesBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self preferredIncludesBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self preferredIncludesBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self preferredIncludesBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self preferredIncludesBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self preferredIncludesBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self preferredIncludesBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self preferredIncludesBuildMultiThreadedDebug ];
		at: #buildNone put:[self preferredIncludesNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludesBuild [	
	"convencience method to customize for this build.

	SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'

	^self preferredIncludes"
	self subclassResponsibility


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludesBuildAssert [
	"convencience method to customize for this build.

	SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'

	^self preferredIncludes"

	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludesBuildAssertITimerHeartbeat [
	"convencience method to customize for this build.

	SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'

	^self preferredIncludes"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludesBuildDebug [
	"convencience method to customize for this build.

	SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'

	^self preferredIncludes"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludesBuildDebugITimerHeartbeat [
	"convencience method to customize for this build.

	SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'

	^self preferredIncludes"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludesBuildITimerHeartbeat [
	"convencience method to customize for this build.

	SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'

	^self preferredIncludes"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludesBuildMultiThreaded [
	"convencience method to customize for this build.

	SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'

	^self preferredIncludes"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludesBuildMultiThreadedAssert [
	"convencience method to customize for this build.

	SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'

	^self preferredIncludes"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludesBuildMultiThreadedDebug [
	"convencience method to customize for this build.

	SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'

	^self preferredIncludes"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludesNoBuildType [
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

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setExtraTargetProperties: aMaker [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self setExtraTargetPropertiesBuild: aMaker];
		at: #buildAssert  put: [self setExtraTargetPropertiesBuildAssert: aMaker];
		at: #buildAssertITimerHeartbeat  put: [self setExtraTargetPropertiesBuildAssertITimerHeartbeat: aMaker];
            at:#buildDebug  put: [self setExtraTargetPropertiesBuildDebug: aMaker];   
		at: #buildDebugITimerHeartbeat  put: [self setExtraTargetPropertiesBuildDebugITimerHeartbeat: aMaker ];
		at: #buildITimerHeartbeat  put: [self setExtraTargetPropertiesBuildITimerHeartbeat: aMaker];
		at: #buildMultiThreaded  put: [self setExtraTargetPropertiesBuildMultiThreaded: aMaker ];
		at: #buildMultiThreadedAssert  put: [self setExtraTargetPropertiesBuildMultiThreadedAssert: aMaker];
		at: #buildMultiThreadedDebug   put: [self setExtraTargetPropertiesBuildMultiThreadedDebug: aMaker ];
		at: #buildNone put:[self setExtraTargetPropertiesNoBuildType:  aMaker].
	^(d at: buildType) value


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setExtraTargetPropertiesBuild: aMaker [
	"convenience method for this buildType.

	SystemNavigation default browseMethodsWhoseNamesContain: 'setExtraTargetProperties'

	do nothing is an option"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setExtraTargetPropertiesBuildAssert: aMaker [ 
	"convenience method for this buildType.

	SystemNavigation default browseMethodsWhoseNamesContain: 'setExtraTargetProperties'

	do nothing is an option"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setExtraTargetPropertiesBuildAssertITimerHeartbeat: aMaker [
	"convenience method for this buildType.

	SystemNavigation default browseMethodsWhoseNamesContain: 'setExtraTargetProperties'

	do nothing is an option"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setExtraTargetPropertiesBuildDebug: aMaker [
	"convenience method for this buildType.

	SystemNavigation default browseMethodsWhoseNamesContain: 'setExtraTargetProperties'

	do nothing is an option"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setExtraTargetPropertiesBuildDebugITimerHeartbeat: aMaker [
	"convenience method for this buildType.

	SystemNavigation default browseMethodsWhoseNamesContain: 'setExtraTargetProperties'

	do nothing is an option"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setExtraTargetPropertiesBuildITimerHeartbeat: aMaker [
	"convenience method for this buildType.

	SystemNavigation default browseMethodsWhoseNamesContain: 'setExtraTargetProperties'

	do nothing is an option"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setExtraTargetPropertiesBuildMultiThreaded: aMaker [
	"convenience method for this buildType.

	SystemNavigation default browseMethodsWhoseNamesContain: 'setExtraTargetProperties'

	do nothing is an option"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setExtraTargetPropertiesBuildMultiThreadedAssert: aMaker [
	"convenience method for this buildType.

	SystemNavigation default browseMethodsWhoseNamesContain: 'setExtraTargetProperties'

	do nothing is an option"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setExtraTargetPropertiesBuildMultiThreadedDebug: aMaker [
	"convenience method for this buildType.

	SystemNavigation default browseMethodsWhoseNamesContain: 'setExtraTargetProperties'

	do nothing is an option"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setExtraTargetPropertiesNoBuildType: aMaker [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptions: aMaker [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self setGlobalOptionsBuild: aMaker];
		at: #buildAssert  put: [self setGlobalOptionsBuildAssert: aMaker];
		at: #buildAssertITimerHeartbeat  put: [self setGlobalOptionsBuildAssertITimerHeartbeat: aMaker];
            at:#buildDebug  put: [self setGlobalOptionsBuildDebug: aMaker];   
		at: #buildDebugITimerHeartbeat  put: [self setGlobalOptionsBuildDebugITimerHeartbeat: aMaker ];
		at: #buildITimerHeartbeat  put: [self setGlobalOptionsBuildITimerHeartbeat: aMaker];
		at: #buildMultiThreaded  put: [self setGlobalOptionsBuildMultiThreaded: aMaker ];
		at: #buildMultiThreadedAssert  put: [self setGlobalOptionsBuildMultiThreadedAssert: aMaker];
		at: #buildMultiThreadedDebug   put: [self setGlobalOptionsBuildMultiThreadedDebug: aMaker ];
		at: #buildNone put:[self setGlobalOptionsNoBuildType: aMaker].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystem: aMaker [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self setGlobalOptionsAfterDetermineSystemBuild: aMaker];
		at: #buildAssert  put: [self setGlobalOptionsAfterDetermineSystemBuildAssert: aMaker];
		at: #buildAssertITimerHeartbeat  put: [self setGlobalOptionsAfterDetermineSystemBuildAssertITimerHeartbeat: aMaker];
            at:#buildDebug  put: [self setGlobalOptionsAfterDetermineSystemBuildDebug: aMaker];   
		at: #buildDebugITimerHeartbeat  put: [self setGlobalOptionsAfterDetermineSystemBuildDebugITimerHeartbeat: aMaker ];
		at: #buildITimerHeartbeat  put: [self setGlobalOptionsAfterDetermineSystemBuildITimerHeartbeat: aMaker];
		at: #buildMultiThreaded  put: [self setGlobalOptionsAfterDetermineSystemBuildMultiThreaded: aMaker ];
		at: #buildMultiThreadedAssert  put: [self setGlobalOptionsAfterDetermineSystemBuildMultiThreadedAssert: aMaker];
		at: #buildMultiThreadedDebug   put: [self setGlobalOptionsAfterDetermineSystemBuildMultiThreadedDebug: aMaker ];
		at: #buildNone put:[self setGlobalOptionsAfterDetermineSystemNoBuildType: aMaker].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuild: aMaker [
	"convenience method to customize for this build type. 

	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsAfterDetermineSystem'

	usually do nothing"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildAssert: aMaker [
	"convenience method to customize for this build type. 

	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsAfterDetermineSystem'

	usually do nothing"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildAssertITimerHeartbeat: aMaker [
	"convenience method to customize for this build type. 

	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsAfterDetermineSystem'

	usually do nothing"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildDebug: aMaker [
	"convenience method to customize for this build type. 

	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsAfterDetermineSystem'

	usually do nothing"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildDebugITimerHeartbeat: aMaker [
	"convenience method to customize for this build type. 

	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsAfterDetermineSystem'

	usually do nothing"
	self subclassResponsibility
 

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildITimerHeartbeat: aMaker [
	"convenience method to customize for this build type. 

	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsAfterDetermineSystem'

	usually do nothing"
	self subclassResponsibility.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildMultiThreaded: aMaker [
	"convenience method to customize for this build type. 

	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsAfterDetermineSystem'

	usually do nothing"
	self subclassResponsibility.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedDebug: aMaker [
	"convenience method to customize for this build type. 

	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsAfterDetermineSystem'

	usually do nothing"
	self subclassResponsibility.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemNoBuildType: aMaker [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsBuild: aMaker [
	"convenience method to customize for this build type. 

	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions'

	usually do nothing"

	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildAssert: aMaker [
	"convenience method to customize for this build type. 

	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions'

	usually do nothing"

	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildAssertITimerHeartbeat: aMaker [
	"convenience method to customize for this build type. 

	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions'

	usually do nothing"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildDebug: aMaker [
	"convenience method to customize for this build type. 

	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions'

	usually do nothing"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildDebugITimerHeartbeat: aMaker [
	"convenience method to customize for this build type. 

	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions'

	usually do nothing"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildITimerHeartbeat: aMaker [
	"convenience method to customize for this build type. 

	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions'

	usually do nothing"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildMultiThreaded: aMaker [
	"convenience method to customize for this build type. 

	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions'

	usually do nothing"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildMultiThreadedAssert: aMaker [
	"convenience method to customize for this build type. 

	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions'

	usually do nothing"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildMultiThreadedDebug: aMaker [
	"convenience method to customize for this build type. 

	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions'

	usually do nothing"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsNoBuildType: aMaker [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> setupDirectories: aMaker [
	| dirsInclude |
	" write the directories in separate include file. "
	self flag: 'tty'. "This message send is not re-routed per build type. My reasoning is that each variable here is set at configure time."
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

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludes [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self standardIncludesBuild];
		at: #buildAssert  put: [self standardIncludesBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self standardIncludesBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self standardIncludesBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self standardIncludesBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self standardIncludesBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self standardIncludesBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self standardIncludesBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self standardIncludesBuildMultiThreadedDebug ];
		at: #buildNone put:[self standardIncludesNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludesBuild [ 
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludesBuildAssert [ 
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludesBuildAssertITimerHeartbeat [ 
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludesBuildDebug [ 
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludesBuildDebugITimerHeartbeat [ 
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludesBuildITimerHeartbeat [ 
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludesBuildMultiThreaded [ 
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludesBuildMultiThreadedAssert [ 
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludesBuildMultiThreadedDebug [ 
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludesNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdPartyLibs [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self thirdpartyLibsBuild];
		at: #buildAssert  put: [self thirdpartyLibsBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self thirdpartyLibsBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self thirdpartyLibsBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self thirdpartyLibsBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self thirdpartyLibsBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self thirdpartyLibsBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self thirdpartyLibsBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self thirdpartyLibsBuildMultiThreadedDebug ];
		at: #buildNone put:[self thirdpartyLibsBuildNone].
	^(d at: buildType) value

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibsBuild [ 
	"convenience method to customize third party libs for this buildType.  

	SystemNavigation default browseMethodsWhoseNamesContain: 'addThirdpartyLibrary:'

	SystemNavigation default browseMethodsWhoseNamesContain: 'processThirdpartyLibraries'	

	SystemNavigation default browseMethodsWhoseNamesContain: 'thirdpartyLibs'

	do nothing is an option
	"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildAssert [ 
	"convenience method to customize third party libs for this buildType.  

	SystemNavigation default browseMethodsWhoseNamesContain: 'addThirdpartyLibrary:'

	SystemNavigation default browseMethodsWhoseNamesContain: 'processThirdpartyLibraries'	

	SystemNavigation default browseMethodsWhoseNamesContain: 'thirdpartyLibs'

	^self thirdpartyLibs"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildAssertITimerHeartbeat [ 
	"convenience method to customize third party libs for this buildType.  

	SystemNavigation default browseMethodsWhoseNamesContain: 'addThirdpartyLibrary:'

	SystemNavigation default browseMethodsWhoseNamesContain: 'processThirdpartyLibraries'	

	SystemNavigation default browseMethodsWhoseNamesContain: 'thirdpartyLibs'

	^self thirdpartyLibs"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildDebug [ 
	"convenience method to customize third party libs for this buildType.  

	SystemNavigation default browseMethodsWhoseNamesContain: 'addThirdpartyLibrary:'

	SystemNavigation default browseMethodsWhoseNamesContain: 'processThirdpartyLibraries'	

	SystemNavigation default browseMethodsWhoseNamesContain: 'thirdpartyLibs'

	^self thirdpartyLibs"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildDebugITimerHeartbeat [ 
	"convenience method to customize third party libs for this buildType.  

	SystemNavigation default browseMethodsWhoseNamesContain: 'addThirdpartyLibrary:'

	SystemNavigation default browseMethodsWhoseNamesContain: 'processThirdpartyLibraries'	

	SystemNavigation default browseMethodsWhoseNamesContain: 'thirdpartyLibs'

	^self thirdpartyLibs"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildITimerHeartbeat [ 
	"convenience method to customize third party libs for this buildType.  

	SystemNavigation default browseMethodsWhoseNamesContain: 'addThirdpartyLibrary:'

	SystemNavigation default browseMethodsWhoseNamesContain: 'processThirdpartyLibraries'	

	SystemNavigation default browseMethodsWhoseNamesContain: 'thirdpartyLibs'

	^self thirdpartyLibs"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildMultiThreaded [ 
	"convenience method to customize third party libs for this buildType.  

	SystemNavigation default browseMethodsWhoseNamesContain: 'addThirdpartyLibrary:'

	SystemNavigation default browseMethodsWhoseNamesContain: 'processThirdpartyLibraries'	

	SystemNavigation default browseMethodsWhoseNamesContain: 'thirdpartyLibs'

	^self thirdpartyLibs"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildMultiThreadedAssert [
	"convenience method to customize third party libs for this buildType.  

	SystemNavigation default browseMethodsWhoseNamesContain: 'addThirdpartyLibrary:'

	SystemNavigation default browseMethodsWhoseNamesContain: 'processThirdpartyLibraries'	

	SystemNavigation default browseMethodsWhoseNamesContain: 'thirdpartyLibs'

	^self thirdpartyLibs"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildMultiThreadedDebug [ 
	"convenience method to customize third party libs for this buildType.  

	SystemNavigation default browseMethodsWhoseNamesContain: 'addThirdpartyLibrary:'

	SystemNavigation default browseMethodsWhoseNamesContain: 'processThirdpartyLibraries'	

	SystemNavigation default browseMethodsWhoseNamesContain: 'thirdpartyLibs'

	^self thirdpartyLibs"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> topDir [
	^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
	
]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> unixPlatformName [

	^'unix'
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

	^'cog'
]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> vmIShouldNotBeHereExecutableName [

	^'IShouldNotBeHere'
]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> vmSistaExecutableName [

	^'sista'
]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> vmStackExecutableName [

	^'squeak'
]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> win32PlatformName [
	^'win32'
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
