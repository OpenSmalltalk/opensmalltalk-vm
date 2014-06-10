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

{ #category : #'squeak compatibility' }
TCPlatformConfigForSqueak >> buildType: aSymbol [
	self required
]

{ #category : #'squeak compatibility' }
TCPlatformConfigForSqueak >> compilerFlags [
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureForAssert [
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureForAssertWithHeartbeatTimer [
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureForBuildType: aSymbol [
	| d |
	self configureForNoBuildType.                "reset all internal flags"
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo.
	d 
		at: #assert put:[self configureForAssert];
		at: #assertWithHeartbeatTimer put: [self configureForAssertWithHeartbeatTimer];
            at:#debug put: [self configureForDebug];
		at: #debugWithHeartbeatTimer put: [self configureForDebugWithHeartbeatTimer];
		at: #debugMultiThreadedFFI put: [self configureForDebugMultiThreadedFFI];
		at: #release put: [self configureForRelease];
		at: #releaseHeartbeatTimer put: [self configureForReleaseHeartbeatTimer];
		at: #releaseMultiThreadedFFI put: [self configureForReleaseMultiThreadedFFI].
     ^(d at: aSymbol) value
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureForDebug [
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureForDebugMultiThreadedFFI [
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureForDebugWithHeartbeatTimer [
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureForNoBuildType [
	"this could be dangerous. If it becomes so, then just reset all the generateForXYZ flags in the topmost config. Currently that is all that initialize does."
	self initialize
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureForRelease [
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureForReleaseHeartbeatTimer [
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> configureForReleaseMultiThreadedFFI [
	self required
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirAndroid [
	^'Do Not Build. See Class Comment'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirBSD32x86 [
	^'cmake_build.bsd32x86'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirBuild [
	^'build'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirBuildAssert [
	^'build.assert'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirBuildDebug [
	^'build.debug'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirBuildDebugITimerHeartbeat [
	^'build.debug.itimerheartbeat'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirBuildITimerHeartbeat [
	^'build.itimerheartbeat'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	self required
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
	^'cmake_build.ia32bochs'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirIOS [
	^'cmake_build.ios'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirLinux32Armv6 [
	^'cmake_build.linux32armv6'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirLinux32x86 [
	^'cmake_build.linux32x86'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirLinux32x8664 [
	^'cmake_build.linux32x86_64'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirMacOS [
	^'cmake_build.macos'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirMacOSPowerPC [
	^'cmake_build.macospowerpc'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirMacOSX32x86 [
	^'cmake_build.macosx32x86'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirOutput [
	^'cmake_products'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirSource [
	^'src'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirSunOS32x86 [
	^'cmake_build.sunos32x86'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirSunOS32x8664 [
	^'cmake_build.sunos32x86_64'
]

{ #category : #cmake }
TCPlatformConfigForSqueak >> dirWin32x86 [
	^'cmake_build.win32x86'
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

{ #category : #'squeak compatibility' }
TCPlatformConfigForSqueak >> write: aContents toFile: aFileName [
	self required
]
