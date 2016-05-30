"
A CMakeVMMakerSqueakTerseGuideHelp provides a simple walkthrough of a build using the CMakeVMMaker package.



"
Class {
	#name : #CMakeVMMakerSqueakTutorialEndUserHelp,
	#superclass : #CMakeVMMakerSqueakTutorialsHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakTutorialEndUserHelp class >> bookName [
	^'Tutorial: End User'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialEndUserHelp class >> configureAndGenerate [
	^HelpTopic
		title: 'Configure and Generate'
		contents:
' The final step is to instruct the Configuration to configure itself for an available buildType , enable/disable debugging trace messages and generate the output.

SqueakLinux64x86w32CompatBuilder 
	configureA: #Linux32x86SqueakCogV3Config forBuildType: #build;   
	enableMessageTracking: true;
	generateByTemplate.

Running the above cascade provides no feedback to the user. If all went well, there should be a CMake build tree as discussed on the next page.



'



]

{ #category : #pages }
CMakeVMMakerSqueakTutorialEndUserHelp class >> examiningOutput [
	"This method was automatically generated. Edit it using:"
	"a HelpBrowser edit: #examiningOutput"
	^HelpTopic
		title: 'Examining Output'
		contents: 
'TODO: tty fix apperent but in build directory as it is outputing to DO THIS NEXT /cmake.build.linux64x86w32BitCompatibility/squeak.cog.v3/build/ 
and not cmake.build.linux32_64x86

Examining the output requires two queries (both intuitive, via the intention revealing names of the Builder and Configuration)

First, we ask the builder where it has its Configurations put their output:

SqueakLinux64x86w32CompatBuilder buildDirectory 
-->  ''cmake.build.linux32_64x86''


The Linux32x86SqueakCogV3Config writes itself to a directory that matches its [cmake.Platform]/[Language].[VM].[MemoryModel]/[BuildType]

On my system that is:

~./..../cogVMMaker/oscogvm/cmake.[Platform]/[Language].[VM].[MemoryModel]/build
i.e.
~./..../cogVMMaker/oscogvm/cmake.build.linux32_64x86/squeak.cog.v3/build

I open a terminal and navigate to that directory:

cd ~./..../cogVMMaker/oscogvm/cmake.build.linux32_64x86/squeak.cog.v3/build

and list the contents 

bash-4.2$ ls
ADPCMCodecPlugin      LICENSE.txt            SurfacePlugin
AsynchFilePlugin      LargeIntegers          Utils.cmake
B2DPlugin             LocalePlugin           ZipPlugin
BMPReadWriterPlugin   MIDIPlugin             build.cmake
BitBltPlugin          Matrix2x3Plugin        build.sh
CMakeLists.txt        MiscPrimitivePlugin    config.cmake
CroquetPlugin         Mpeg3Plugin            config.in
DSAPrims              PLUGINS.txt            directories.cmake
DropPlugin            Plugins.cmake          sqNamedPrims.h
FFTPlugin             SecurityPlugin         testDoubleWordAlignment.c
FileCopyPlugin        SerialPlugin           testDoubleWordOrder.c
FilePlugin            SocketPlugin           testLanginfoCodeset.c
FloatArrayPlugin      SoundCodecPrims        vm-display-X11
FloatMathPlugin       SoundGenerationPlugin  vm-display-null
JoystickTabletPlugin  SoundPlugin            vm-sound-ALSA
Klatt                 StarSqueakPlugin       vm-sound-null
....


(NOTE TODO tty: build a query to have a configuration return its build directory path.)

!' readStream nextChunkText
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialEndUserHelp class >> invokeCMake [
	^HelpTopic
		title: 'Invoke cmake'
		contents:
'The next step is to tell CMake to create the native build files.

On linux the commands are:

cmake .                    <----N.B. note the ''dot'' after the cmake
make

As a convenience, the commands are duplicated in a generated ''build.sh'' file .  (I have had some wierd issues with running it directly, so I just run the commands therein)
bash-4.2$ cat build.sh 
#!/usr/bin/env bash
export CC=gcc
export CXX=g++
cmake .
make


When CMakeVMMakerSqueak is ported to different platforms, then the ''make'' command could be replaced by a different native build system command.


'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialEndUserHelp class >> overview [
	^HelpTopic
		title: 'Overview'
		contents:
'This tutorial covers how to generate a CMake build tree using an existing Builder and an existing Configuration. If you need a new Builder or Configuration see the Developer Guide.

On a given Platform, a platform specific Builder configures a platform specific Configuration for a buildType and instructs it to  write its CMake output to that Configuration''s build directory.

This terse example shows a typicall use-case of the tools.

In this terse example, I want to build a Cog VM for Squeak with the V3 memory model. on a SlackwareLinux64 with 32 bit Compatability libs platform.  

To do this, I ...

1. Select the Builder for my platform.  
2. Query the Builder
3  Select a Configuration
4 Instruct  the Configuration (via the Builder) to configure itself for a builtType
5. Instruct the Configuration (via the Builder) to enable message tracking (useful for debugging output)
6. Instruct the Configuration (via the Builder) to generate its CMake output.
7 
8 Invoke the native build system.
9. Test the generated VM.
'
]

{ #category : #accessing }
CMakeVMMakerSqueakTutorialEndUserHelp class >> pages [
	^#(overview selectBuilder queryBuilder selectConfiguration configureAndGenerate examiningOutput invokeCMake testDrive)
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialEndUserHelp class >> priority [

	^ 3
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialEndUserHelp class >> queryBuilder [
	^HelpTopic
		title: 'Query the Builder'
		contents:
'I can query the Builder for information on available Configurations and BuildTypes

SqueakLinux64x86w32CompatBuilder 
	availableBuildConfigurations.

SqueakLinux64x86w32CompatBuilder 
	allBuildTypes.

SqueakLinux64x86w32CompatBuilder 
	availableBuildTypesFor:(SqueakLinux64x86w32CompatBuilder availableBuildConfigurations at:1).

SqueakLinux64x86w32CompatBuilder 
	buildDirectory.

The ''queries'' protocol of the SqueakCMakeVMMakerAbstractBuilder contains additional queries.

SqueakCMakeVMMakerAbstractBuilder class browse.
'



]

{ #category : #pages }
CMakeVMMakerSqueakTutorialEndUserHelp class >> selectBuilder [
	^HelpTopic
		title: 'Select a Builder'
		contents:
'I select the appropriate Builder from the CMakeVMMakerSqueak-Builder category for my platform; in my case it is the SqueakLinux64x86w32CompatBuilder.


SqueakLinux64x86w32CompatBuilder browseHierarchy.

SqueakCMakeVMMakerAbstractBuilder browseHierarchy.

'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialEndUserHelp class >> selectConfiguration [
	^HelpTopic
		title: 'Select a Configuration'
		contents:
'The Configuration Linux64x86w32BitSqueakCogV3Config is available for my platform. (i.e. a developer has done the work of encapsulating the custom CMake for us).

As stated before, I can view what Configurations are available for a platform by asking the platform Builder what it has available:

SqueakLinux64x86w32CompatBuilder 
	availableBuildConfigurations.

As of this writing the Linux64x86w32BitSqueakCogV3Config is available and I decide to use it.

Note that the class name of the Configuration is intention-revealing. It is a Configuration for the Linux 64 platform with 32 Bit compatibility libs that encapsulates the CMake required to build the Squeak Cog V3 virtual machine. From this convention, The organization of configurations is straight-forward:

CPlatformConfigForSqueak  browseHierarchy

Linux64x86w32BitSqueakCogV3Config browseHierarchy
'



]

{ #category : #pages }
CMakeVMMakerSqueakTutorialEndUserHelp class >> testDrive [
	^HelpTopic
		title: 'Test Driving the VM'
		contents:
'The Cog svn tree contains a directory named ''products'' where it stores its make output.

The CMakeVMMakerSqueak system mirrors that with a cmake.products directory that is created at the same level.


The newly generated VM is stored in a subdirectory of ''cmake.products" that mimics the [Language][VM][MemoryModel] naming convention of the Configuration

Since I built a #Linux32x86SqueakCogV3Config the cog vm is placed in the cmake.products/squeak.cog.v3  directory.

TODO: Add a message name showing where this is customized.
'
]
