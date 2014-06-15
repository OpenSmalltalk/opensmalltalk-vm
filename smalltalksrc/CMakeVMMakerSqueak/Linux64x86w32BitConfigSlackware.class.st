"
Linux64x86w32BitConfigSlackware encapsulates configurations for building Squeak on Slackware64 with Alien Bob's 32 bit compatibility libs installed.

I am not meant to be built.

SqueakLinux64x86w32CompatBuilder 
	configureABuildFor: #ONE OF MY SUBCLASSES NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp




Slackware differs from Debian/Unbuntu in that Slackware64 puts its base system 64 bit libraries  /lib64/  with the 32 bit compatibility stuff (if it is manually installed) in /lib

Debian/Ubuntu reverses this convention, putting its 64 bit libs in /lib and 32 bit compatibility libs in /lib32.

N.B. The author is not a Ubuntu user, so he may have his head up his butt on this.


"
Class {
	#name : #Linux64x86w32BitConfigSlackware,
	#superclass : #Linux64x86w32BitConfig,
	#traits : 'TCPlatformConfigForSqueak',
	#classTraits : 'TCPlatformConfigForSqueak classTrait',
	#category : #'CMakeVMMakerSqueak-Linux64X86-32BitCompatibility'
}

{ #category : #cmake }
Linux64x86w32BitConfigSlackware >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]
