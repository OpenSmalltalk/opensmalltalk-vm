"
A CMakeVMMakerSqueakStartHereHelp provides examples of usage for newbies.



"
Class {
	#name : #CMakeVMMakerSqueakStartHereHelp,
	#superclass : #CMakeVMMakerSqueakHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakStartHereHelp class >> bookName [
	^'Start Here'
]

{ #category : #accessing }
CMakeVMMakerSqueakStartHereHelp class >> pages [
	^#(scratch shortVersionLinuxBuild)
]

{ #category : #pages }
CMakeVMMakerSqueakStartHereHelp class >> scratch [
	^HelpTopic
		title: 'Start Here Scratch'
		contents:
'Goal is that a complete newbie can open this and get up and running.

'
]

{ #category : #pages }
CMakeVMMakerSqueakStartHereHelp class >> shortVersionLinuxBuild [
	^HelpTopic
		title: 'Short  Version Linux Build'
		contents:
'1. ---Query the Builder for available configurations and build types---
SqueakLinux32x86Builder configurationsCategory.
SqueakLinux32x86Builder availableBuildConfigurations.
SqueakLinux32x86Builder availableBuildTypesFor:(SqueakLinux32x86Builder availableBuildConfigurations at:1). "Replace at:1 as neccessary"


2.---Direct the Builder to invoke a Configuration for a specific build type---
SqueakLinux32x86Builder
	configureA: #Linux32x86SqueakCogV3Config forBuildType:#build;   
	enableMessageTracking: false;
	generateByTemplate.

3.---Direct the Builder to ask the configuration for where it puts its build files---
SqueakLinux32x86Builder buildDirectory 

4.---Open an X-terminal and cd to the above directory and kick off the cmake-build---
cd (some directory)/Contents/Resources/oscogvm/cmake.build.linux32.x86/squeak.cog.v3/build/
./build.sh

5.---view your build---
cd (some directory)/Contents/Resources/oscogvm/products/(FIX ME TTY)
'
]
