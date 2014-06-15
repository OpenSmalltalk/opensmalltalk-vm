"
A Linux64x86w32BitConfigDebian  encapsulates configurations for building Squeak on 64 bit  Ubuntu with some compatability libs installed.

The author of this comment does not use Ubuntu, so optaining those libs is up to you Ubuntu/Debian afficianados

Debian/Ubuntu places  its 64 bit libs in /lib and 32 bit compatibility libs in /lib32.

Slackware differs from Debian/Unbuntu in that Slackware64 puts its base system 64 bit libraries  /lib64/  with the 32 bit compatibility stuff (if it is manually installed) in /lib

I am not meant to be built.

SqueakLinux64x86w32CompatBuilder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp


"
Class {
	#name : #Linux64x86w32BitConfigDebian,
	#superclass : #Linux64x86w32BitConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#category : #'CMakeVMMakerSqueak-Linux64X86-32BitCompatibility'
}

{ #category : #cmake }
Linux64x86w32BitConfigDebian >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]
