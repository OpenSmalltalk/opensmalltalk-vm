Class {
	#name : #CMakeVMMakerSqueakBuildersHelp,
	#superclass : #CMakeVMMakerSqueakDeveloperHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakBuildersHelp class >> bookName [ 
	^'Builders'
]

{ #category : #pages }
CMakeVMMakerSqueakBuildersHelp class >> buildTypes [
	^HelpTopic
		title:'Build types'
		contents:
'N.B. This query is dependent on the developer taking the time to maintain his Configuration correctly. If they do not, then invalid information will be conveyed.

Configurations are built over time. There is a possibility that a particulare build type is not available for a given Configuration simply because a developer has not gotten around to the task.

For example, at the time of this writing, Linux64x86w32BitSqueakCogV3Config only has buildType #build available.

Since builds are sometimes not available and/or under development  a developer *should* restrict what build types are avaiable for a configurations Builder by modifying the configuration''s "availableBuilds" method.

The purpose of this method is to present the end user with the avaiable buildTypes for a configuration category. when they invoke a Builder like so:

	SqueakLinux64x86w32CompatBuilder availableBuildTypesFor: #Linux64x86w32BitSqueakCogV3Config

The default is all buildTypes:  
	^SqueakCMakeVMMakerAbstractBuilder  default  allBuildConfigurations
(NOTE: Why? Shouldn''t default be no build types? tty.)


You can display no buildTypes with:
	^SqueakCMakeVMMakerAbstractBuilder  default  noBuildConfigurations.

or you can customize it like so:
	^(SqueakCMakeVMMakerAbstractBuilder  default  allBuildConfigurations 
			copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))  


'
]

{ #category : #pages }
CMakeVMMakerSqueakBuildersHelp class >> builders [
	^HelpTopic
		title: 'Overview'
		contents:
'A CMakeVMakerSqueak Builder is both a ''query'' tool and a ''build'' tool.

Builders provide a facade to CMakeVMmakerSqueak Configurations.

With a  Builder, you can 
	query its configurationsCategory''s Configurations
	invoke a Configuration to generate CMake files or... 
	invoke a Configuration to generateSources which...
			invokes VMMaker.oscog to generate source

Builders are concrete instances of the Abstract Base Class:SqueakCMakeVMMakerAbstractBuilder
View SqueakCMakeVMMakerAbstractBuilder''s class comments for an overview of this tool.

SqueakCMakeVMMakerAbstractBuilder  browseHierarchy.


Information on creating your own is available via HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp

'
]

{ #category : #pages }
CMakeVMMakerSqueakBuildersHelp class >> generatingCMakeBuilds [
	^HelpTopic
		title: 'Generating CMake Builds'
		contents:
'CMake Builds require CMake files.

We generate those files using a Builder.

In the following message sends we are asking Builder to instruct a Configuration to...
configure itself for a specific build type
debug trace messages in its output.
output itself as CMake.

SqueakLinux64x86w32CompatBuilder
	configureA: #Linux64x86w32BitSqueakCogV3Config forBuildType:#build; 
	enableMessageTracking: true;
	generateByTemplate.



'
]

{ #category : #accessing }
CMakeVMMakerSqueakBuildersHelp class >> key [
	^'CMakeVMMakerSqueakBuildersHelp'
]

{ #category : #pages }
CMakeVMMakerSqueakBuildersHelp class >> overview [
	^HelpTopic
		title: 'Overview'
		contents:
'Builders are a facade interfact to CMakeVMmakerSqueak Configurations.

A CMakeVMakerSqueak Builder is both a ''query'' tool and a ''build'' tool.


With a  Builder, you can 
	query its configurationsCategory''s Configurations
	invoke a Configuration to generate CMake files or... 
	invoke a Configuration to generateSources which...
	invokes VMMaker.oscog to generate source

Builders are concrete instances of the Abstract Base Class:SqueakCMakeVMMakerAbstractBuilder
Browse its class comment an heirarchy to get a feel for it.

HelpBrowser openOn: SqueakCMakeVMMakerAbstractBuilder
SqueakCMakeVMMakerAbstractBuilder  browseHierarchy.

Information on creating your own is available via HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp


'
]

{ #category : #accessing }
CMakeVMMakerSqueakBuildersHelp class >> pages [
	^#(overview queryingBuilders buildTypes  generatingCMakeBuilds CMakeVMMakerSqueakTutorialNewBuilderHelp)
	
"#(overview queryingBuilders buildTypes  generatingCMakeBuilds scratch)"
]

{ #category : #pages }
CMakeVMMakerSqueakBuildersHelp class >> queryingBuilders [
	^HelpTopic
		title: 'Querying Builders'
		contents:
'You can query Builders for Configuration information for a specific platform.

SqueakCMakeVMMakerAbstractBuilder availableBuildConfigurationsFor: ''CMakeVMMakerSqueak-Linux32x86''.
SqueakCMakeVMMakerAbstractBuilder availableBuildConfigurationsFor: ''CMakeVMMakerSqueak-MacOSX32x86''.
SqueakCMakeVMMakerAbstractBuilder allBuildTypes

SqueakLinux64x86w32CompatBuilder configurationsCategory.
SqueakLinux64x86w32CompatBuilder buildDirectory.
SqueakLinux64x86w32CompatBuilder availableBuildConfigurations a SortedCollection(#Linux64x86w32BitSqueakCogV3Config).
SqueakLinux64x86w32CompatBuilder availableBuildTypesFor:(SqueakLinux64x86w32CompatBuilder availableBuildConfigurations at:1).
SqueakLinux64x86w32CompatBuilder sourceDirectoryFor:(SqueakLinux64x86w32CompatBuilder availableBuildConfigurations at:1).


The hope is that an app like Seaside would autogenerate build configurations while intelligently selecting/de-selecting based on the systems built-in configuration. 

ToolSet browseMessageCategory: ''queries'' inClass: SqueakCMakeVMMakerAbstractBuilder'
]

{ #category : #pages }
CMakeVMMakerSqueakBuildersHelp class >> scratch [
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
