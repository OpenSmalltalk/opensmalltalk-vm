Class {
	#name : #CMakeVMMakerSqueakEndUserHelp,
	#superclass : #CMakeVMMakerSqueakHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakEndUserHelp class >> bookName [ 
	^'User''s Guide'
]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakEndUserHelp class >> pages [
	^#(scratch)
]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakEndUserHelp class >> scratch [
	^HelpTopic
		title: 'Scratch Notes To Be Organized'
		contents:
'
HEADS UP! You can ''print it'' in the examples below
-------------------------Using CMakeVMMakerSqueak-------------------------
These instructions are duplicated in SqueakCMakeVMMakerAbstractBuilder class comments.


The easiest way to use this tool is to utilize one of the concrete Builders in category CMakeVMMakerSqueak-Builder.

With a builder, you can query it for information and then invoke it to generate configurations and or source.

Printing or inspecting the following lines will give you a flavor of a typical work-flow.


-------------Buildable/non-buildable configurations---------
SqueakCMakeVMMakerAbstractBuilder showExcludeFromBuild:false    "buildable configurations"
SqueakCMakeVMMakerAbstractBuilder showExcludeFromBuild:true.    "edit that configs ''excludeFromBuild'' method to change"
SqueakCMakeVMMakerAbstractBuilder availableBuildTypes

-------------------------Querying Builders---------------
SqueakLinux32X86Builder configurationsCategory 
SqueakLinux32X86Builder buildDirectory 
SqueakLinux32X86Builder availableBuilds	 
SqueakLinux32X86Builder availableBuildTypesFor:(SqueakLinux32X86Builder availableBuilds at:1)
SqueakLinux32X86Builder availableBuildTypesFor: #Linux32x86SqueakStackSpurConfig
SqueakLinux32X86Builder availableBuildTypesFor: #Linux32x86SqueakStackV3Config
SqueakLinux32X86Builder sourceDirectoryFor:(SqueakLinux32X86Builder availableBuilds at:1)

-------------------------Invoking Builders-------------------------
SqueakCMakeVMMakerAbstractBuilder reset
SqueakCMakeVMMakerAbstractBuilder availableBuildTypes a SortedCollection(#build #buildAssert #buildAssertITimerHeartbeat #buildDebug #buildDebugITimerHeartbeat #buildDebugMultiThreaded #buildITimerHeartbeat #buildMultiThreaded #buildMultiThreadedAssert #buildMultiThreadedDebug)

[SqueakCMakeVMMakerAbstractBuilder availableBuildTypes do: [:type | 
	SqueakLinux32X86Builder
		configureABuildFor: #Linux32x86SqueakCogV3Config withBuildType: type;	
		generate   ]] on: ProvideAnswerNotification do: [:ex | ex resume:true]


"generate only CMake config files"
SqueakLinux32X86Builder 
	configureABuildFor: #Linux32x86SqueakCogV3Config withBuildType: #buildAssertITimerHeartbeat;
	generate   

"generate configurations and invoke VMMaker to generate source code"
SqueakLinux32X86Builder 
	configureABuildFor: #Linux32x86SqueakCogV3Config withBuildType: #buildAssertITimerHeartbeat;
	generateSources  ;
	generate.

-------------------------Compiling Instructions-------------------------
open a terminal and go to the configurations build directory for that configuration. (SqueakLinux32X86Builder buildDirectory)
change into the build type subdirectory (build, build.assert, build.debug...etc)
source build.sh will run ''cmake. make'' 
executable is placed in  /products folder.  (SqueakLinux32X86Builder ouputDirectory)


----------------------Editing/Constructing Configurations--------------

Configurations are organized by category:  OperatingSystem, VM Word Size, Processor . (i.e MacOSX32x86 configurations reside in CMakeVMMakerSqueak-MacOSX32x86a)
For a OperatingSystem,VM Word Size, Processor, configurations are then organized by Language.VM.MemoryManafger (newswpeak.stack.v3, squeak.sista.spur. squeak.cog.spur, etc)

IF an existing configuratin exists, you may edit or subclass it. For a Builder to see it, it must remain in the category.

The flag excludeFromBuild determines wether the builder will build it or not. This flag is set to exclude configurations that are just placeholders.

If you have a special case for an existing [OS][WordSize][Processor].[lang][vm][mm] configuration just subclass it and provide customizations.

TODO: Provide typical customizations and how to implement them

internal/external plugins?
compiler flags?
includes?




----------------------Improvements needed-------------------------

The CMakeVMMakerSqueak package has some design hacks because it extends 
the pharo CMakeVMMaker package without modifying that code base.
Therefore, things that should have been done by introducing squeak sub-classes in the pharo source tree could not be done.

The biggest design ''quirk'' is the use of the Trait TCPlatformConfigForSqueak to enforce a pseudo abstract base class mechanism.
The other design ''quirk'' are the overrides of methods in CPlatformConfig in pharo''s package of incompatible methods. (see protocol squeak-compatibility)
Because of the existing inheritance tree, the overrides could not happen in one squeak compatibility class, but are implemented
in several subclasses of CPlatformConfig.

The Squeak Builders implementation also differs significantly from the pharo implementation.
The pharo code''s ''configForDebug/configForReleaase'' has been expanded to support the squeak build needs.


'
]
