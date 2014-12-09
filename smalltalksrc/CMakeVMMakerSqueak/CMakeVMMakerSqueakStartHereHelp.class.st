"
A CMakeVMMakerSqueakStartHereHelp provides examples of usage for newbies.



"
Class {
	#name : #CMakeVMMakerSqueakStartHereHelp,
	#superclass : #CMakeVMMakerSqueakDeveloperHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakStartHereHelp class >> bookName [
	^'Start Here'
]

{ #category : #pages }
CMakeVMMakerSqueakStartHereHelp class >> exampleWorkFlow [
	^HelpTopic
		title: 'Example Workflow'
		contents:
'I want to build a Cog VM for Squeak with the V3 memory model. on a SlackwareLinux64 with 32 bit Compatability libs platform.  

To do this, I ...

1. Choose the Builder for my platform.  
2. Choose the Configuration I need for my [Platform][Language][VM][Memory Model] 
3. Choose a Build Type for the Configuration. 
4. Write the CMake output.

So, here we go.

I choose the appropriate Builder from the CMakeVMMakerSqueak-Builder category for my platform; in my case it is the SqueakLinux64x86w32CompatBuilder.
SqueakLinux64x86w32CompatBuilder browse.

I can query the Builder for available Configurations and BuildTypes for that Configuration and where it will put its output by sending the following messages: (presented here with output from my system below the message send)

SqueakLinux64x86w32CompatBuilder availableBuildConfigurations.  
--> a SortedCollection(#Linux64x86w32BitSqueakCogV3Config)

SqueakLinux64x86w32CompatBuilder allBuildTypes.  
--> an OrderedCollection(#build #buildAssert #buildAssertITimerHeartbeat #buildDebug #buildDebugITimerHeartbeat #buildITimerHeartbeat #buildMultiThreaded #buildMultiThreadedAssert #buildMultiThreadedDebug #buildNone)

SqueakLinux64x86w32CompatBuilder availableBuildTypesFor:(SqueakLinux64x86w32CompatBuilder availableBuildConfigurations at:1).
--> an OrderedCollection(#build)

SqueakLinux64x86w32CompatBuilder buildDirectory 
-->  ''cmake.build.linux32_64x86''

The availableBuildConfigurations message shows I have a Linux64x86w32BitSqueakCogV3Config available.  (As additional Configurations and their buildTypes are added to the system they will show up in these queries). 


The allBuildTypes message shows the universe of possible build types:  
--> an OrderedCollection(#build #buildAssert #buildAssertITimerHeartbeat #buildDebug #buildDebugITimerHeartbeat #buildITimerHeartbeat #buildMultiThreaded #buildMultiThreadedAssert #buildMultiThreadedDebug #buildNone)

Out of the universe of allBuildTypes, The availableBuildTypes message shows me that (at the time of this writing) the Linux64x86w32BitSqueakCogV3Config only supports one build type:
-->  an OrderedCollection(#build)

Now that I know what is possible, I  instruct the Builder to ask the Linux64x86w32BitSqueakCogV3Config Configuration to configure itself for the buildType: #build ,  enable trace messages in the CMake files to make troubleshooting easier and generate the CMake build tree: 

SqueakLinux64x86w32CompatBuilder 
	configureA: #Linux32x86SqueakCogV3Config forBuildType: #build;   
	enableMessageTracking: true;
	generateByTemplate.

(FYI the above provides no user feedback)

The Linux32x86SqueakCogV3Config writes itself to a directory that matches its [cmake.Platform]/[Language].[VM].[MemoryModel]/[BuildType]

On my system that is:

/home/tty/usr/src/smalltalk/CMake.oscog/cogVMMaker/oscogvm/cmake.[Platform]/[Language].[VM].[MemoryModel]/build
i.e.
/home/tty/usr/src/smalltalk/CMake.oscog/cogVMMaker/oscogvm/cmake.build.linux32_64x86/squeak.cog.v3/build

I open a terminal and navigate to that directory:

cd /home/tty/usr/src/smalltalk/CMake.oscog/cogVMMaker/oscogvm/cmake.build.linux32_64x86/squeak.cog.v3/build

I run the commands in the generated ''build.sh'' file.  (I have had some wierd issues with running it directly, so I just run the commands therein)
bash-4.2$ cat build.sh 
#!/usr/bin/env bash
export CC=gcc
export CXX=g++
cmake .
make

If things work, you will have a working VM in the products directory on my system I see:

bash-4.2$ ls /home/tty/usr/src/smalltalk/CMake.oscog/cogVMMaker/oscogvm/cmake.products/squeak.cog.v3/
cog  vm-display-X11  vm-display-null  vm-sound-ALSA  vm-sound-null

I test the VM

bash-4.2$ cd /home/tty/usr/src/smalltalk/CMake.oscog/cogVMMaker/oscogvm/cmake.products/squeak.cog.v3/

bash-4.2$ ./cog -version
. #1 Tue Dec  9 13:17:50 EST 2014 gcc 4.8.2 [Production VM]
CoInterpreter VMMaker.oscog-eem.973 uuid: 1c182b73-874c-48f7-a4f4-61255efdc565 Dec  9 2014
StackToRegisterMappingCogit VMMaker.oscog-eem.972 uuid: 741005af-763d-4a93-918d-014972c404ef Dec  9 2014
VM: r3164 http://www.squeakvm.org/svn/squeak/branches/Cog Date: 2014-12-06 20:38:11 -0500
Plugins: r3131 http://squeakvm.org/svn/squeak/trunk/platforms/Cross/plugins
Linux flipper 3.10.17 #2 SMP Wed Oct 23 16:34:38 CDT 2013 x86_64 AMD Phenom(tm) II X4 965 Processor AuthenticAMD GNU/Linux
plugin path: /home/tty/usr/src/smalltalk/CMake.oscog/cogVMMaker/oscogvm/cmake.products/squeak.cog.v3/ [default: /home/tty/usr/src/smalltalk/CMake.oscog/cogVMMaker/oscogvm/cmake.products/squeak.cog.v3/]

And, that''s about it.'
]

{ #category : #pages }
CMakeVMMakerSqueakStartHereHelp class >> overview [
	^HelpTopic
		title: 'Overview'
		contents:
'CMakeVMMakerSqueak is a collection of tools for generating CMake files. The high-level workflow is:

1. Instruct  CMakeVMMakerSqueak to generate CMake build directories and CMake configuration files.

2. Invoke the  ''cmake'' command at the top level of the generated cmake build tree

3. CMake configures and outputs the build system files for that platform.

4. The user invokes the native build system.

5. A VM is produced under a ~/...../''cmake.platforms'' subdirectory.

The ''Example Workflow'' page in this Help book provides an example of the above workflow with minimal explanation.

In-depth explanations of the system(s), tools and how to use them, see the ''CMakeVMMaker Developer Guide'''
]

{ #category : #accessing }
CMakeVMMakerSqueakStartHereHelp class >> pages [
	^#(overview requirements exampleWorkFlow)
]

{ #category : #pages }
CMakeVMMakerSqueakStartHereHelp class >> requirements [
	^HelpTopic
		title: 'Requirements'
		contents:
'CMakeVMakerSqueak (as of 2014.12.09) depends on the Pharo package CMakeVMMaker. A (possibly out-of-sync) Monticello version is available at:

MCHttpRepository
	location: ''http://source.squeak.org/VMMaker''
	user: ''''
	password: ''''

CMakeVMMakerSqueak is available at:

MCHttpRepository
	location: ''http://source.squeak.org/VMMaker''
	user: ''''
	password: ''''

CMake is available from http://www.cmake.org. The version of CMake used as of 2014.12.09 is 2.8.12  

CMake provides a cmake_minimum_required(..) command, so newer versions should be ok.

The Example Workflow is presented on a GNU Linux system with the standard development tools. Macintosh and Windows dev tools will differ.'
]
