Class {
	#name : #CMakeVMMakerSqueakEndUserHelp,
	#superclass : #CMakeVMMakerSqueakHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakEndUserHelp class >> bookName [ 
	^'End User Guide'
]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakEndUserHelp class >> builders [
	^HelpTopic
		title: 'Builders'
		contents:
'
CMakeVMakerSqueak Builders provide a facade to CMakeVMmakerSqueak Configurations.

A Builder is both a ''query'' tool and a ''build'' tool.

With a  Builder, you can 
	query its configurationsCategory''s Configurations
	invoke a Configuration to generate CMake files or 
	invoke a Configuration to generateSources which
			invokes VMMaker.oscog to generate source

Builders are concrete instances of the Abstract Base Class:SqueakCMakeVMMakerAbstractBuilder
View SqueakCMakeVMMakerAbstractBuilder''s class comments for an overview of this tool.

SqueakCMakeVMMakerAbstractBuilder  browseHierarchy.

Information on creating your own is available via HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp

'
]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakEndUserHelp class >> pages [
	^#(builders queryingBuilders scratch)
]

{ #category : #'as yet unclassified' }
CMakeVMMakerSqueakEndUserHelp class >> queryingBuilders [
	^HelpTopic
		title: 'Querying Builders'
		contents:
'

Below are some queries avaiable via various Builders in the CMakeVMMakerSqueak package:
SqueakCMakeVMMakerAbstractBuilder  reset                                     "reset internal state of the Abstract Builder"
SqueakCMakeVMMakerAbstractBuilder showExcludeFromBuild:false    "buildable configurations"
SqueakCMakeVMMakerAbstractBuilder showExcludeFromBuild:true.    "edit that configs ''excludeFromBuild'' method to change"
SqueakCMakeVMMakerAbstractBuilder availableBuildTypes
SqueakCMakeVMMakerAbstractBuilder  reset                                     "reset internal state of the Abstract Builder"


SqueakAndroidBuilder configurationsCategory
SqueakAndroidBuilder  buildDirectory
SqueakAndroidBuilder  availableBuilds
SqueakAndroidBuilder  availableBuildTypesFor:(SqueakAndroidBuilder availableBuilds at:1)
SqueakAndroidBuilder  sourceDirectoryFor:(SqueakAndroidBuilder availableBuilds at:1)

SqueakBSDx86Builder configurationsCategory
SqueakBSDx86Builder buildDirectory
SqueakBSDx86Builder availableBuilds
SqueakBSDx86Builder availableBuildTypesFor:(SqueakBSDx86Builder availableBuilds at:1)
SqueakBSDx86Builder sourceDirectoryFor:(SqueakBSDx86Builder availableBuilds at:1)

SqueakIA32BochsBuilder configurationsCategory
SqueakIA32BochsBuilder buildDirectory
SqueakIA32BochsBuilder availableBuilds
SqueakIA32BochsBuilder availableBuildTypesFor:(SqueakIA32BochsBuilder availableBuilds at:1)
SqueakIA32BochsBuilder sourceDirectoryFor:(SqueakIA32BochsBuilder availableBuilds at:1)

SqueakIOSBuilder configurationsCategory
SqueakIOSBuilder buildDirectory
SqueakIOSBuilder availableBuilds
SqueakIOSBuilder availableBuildTypesFor:(SqueakIOSBuilder availableBuilds at:1)
SqueakIOSBuilder sourceDirectoryFor:(SqueakIOSBuilder availableBuilds at:1)

SqueakLinux32ARMv6Builder configurationsCategory
SqueakLinux32ARMv6Builder buildDirectory
SqueakLinux32ARMv6Builder availableBuilds
SqueakLinux32ARMv6Builder availableBuildTypesFor:(SqueakLinux32ARMv6Builder availableBuilds at:1)
SqueakLinux32ARMv6Builder sourceDirectoryFor:(SqueakLinux32ARMv6Builder availableBuilds at:1)


SqueakLinux32x86Builder configurationsCategory
SqueakLinux32x86Builder buildDirectory
SqueakLinux32x86Builder availableBuilds
SqueakLinux32x86Builder availableBuildTypesFor:(SqueakLinux32x86Builder availableBuilds at:1)
SqueakLinux32x86Builder sourceDirectoryFor:(SqueakLinux32x86Builder availableBuilds at:1)

SqueakLinux32x86_64Builder configurationsCategory
SqueakLinux32x86_64Builder SqueakLinux32x86_64Builder
SqueakLinux32x86_64Builder SqueakLinux32x86_64Builder
SqueakLinux32x86_64Builder availableBuildTypesFor:(SqueakLinux32x86_64Builder availableBuilds at:1)
SqueakLinux32x86_64Builder sourceDirectoryFor:(SqueakLinux32x86_64Builder availableBuilds at:1)

SqueakLinux64x86w32CompatBuilder configurationsCategory
SqueakLinux64x86w32CompatBuilder buildDirectory
SqueakLinux64x86w32CompatBuilder availableBuilds
SqueakLinux64x86w32CompatBuilder availableBuildTypesFor:(SqueakLinux64x86w32CompatBuilder availableBuilds at:1)
SqueakLinux64x86w32CompatBuilder sourceDirectoryFor:(SqueakLinux64x86w32CompatBuilder availableBuilds at:1)

SqueakMacOSBuilder configurationsCategory
SqueakMacOSBuilder buildDirectory
SqueakMacOSBuilder availableBuilds
SqueakMacOSBuilder availableBuildTypesFor:(SqueakMacOSBuilder availableBuilds at:1)
SqueakMacOSBuilder sourceDirectoryFor:(SqueakMacOSBuilder availableBuilds at:1)

SqueakMacOSPowerPCBuilder configurationsCategory
SqueakMacOSPowerPCBuilder buildDirectory
SqueakMacOSPowerPCBuilder availableBuilds
SqueakMacOSPowerPCBuilder availableBuildTypesFor:(SqueakMacOSPowerPCBuilder availableBuilds at:1)
SqueakMacOSPowerPCBuilder sourceDirectoryFor:(SqueakMacOSPowerPCBuilder availableBuilds at:1)

SqueakMacOSX32x86Builder configurationsCategory
SqueakMacOSX32x86Builder buildDirectory
SqueakMacOSX32x86Builder availableBuilds
SqueakMacOSX32x86Builder availableBuildTypesFor:(SqueakMacOSX32x86Builder availableBuilds at:1)
SqueakMacOSX32x86Builder sourceDirectoryFor:(SqueakMacOSX32x86Builder availableBuilds at:1)

SqueakSunOS32x86Builder configurationsCategory
SqueakSunOS32x86Builder buildDirectory
SqueakSunOS32x86Builder availableBuilds
SqueakSunOS32x86Builder availableBuildTypesFor:(SqueakSunOS32x86Builder availableBuilds at:1)
SqueakSunOS32x86Builder sourceDirectoryFor:(SqueakSunOS32x86Builder availableBuilds at:1)

SqueakWin32x86Builder configurationsCategory
SqueakWin32x86Builder buildDirectory
SqueakWin32x86Builder availableBuilds
SqueakWin32x86Builder availableBuildTypesFor:(SqueakWin32x86Builder availableBuilds at:1)
SqueakWin32x86Builder sourceDirectoryFor:(SqueakWin32x86Builder availableBuilds at:1)


'
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
