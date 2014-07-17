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
		externalLibs: (self externalLibs);

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

{ #category : #'cmake configuration' }
Linux64Config >> availableBuildTypes [
	 ^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes
"	subclasses should use

  ^super availableBuildTypes copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))   "
	

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
Linux64Config >> coreSourcesBuildMultiThreaded [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'cointerpmt.c'
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

{ #category : #'cmake configuration' }
Linux64Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build"
	^true
]

{ #category : #cmake }
Linux64Config >> executableName [
	"AbstractBaseClass configurations are not meant to be executable"
	^ self vmIShouldNotBeHereExecutableName
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> externalPluginsBuild [
	^ externalPlugins ifNil: [ externalPlugins := self defaultExternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> internalPluginsBuild [
	^ internalPlugins ifNil: [ internalPlugins := self defaultInternalPlugins ]
]

{ #category : #'cmake buildType redirects' }
Linux64Config >> postBuildActionsBuild: gen [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActionsBuild:'"
]
