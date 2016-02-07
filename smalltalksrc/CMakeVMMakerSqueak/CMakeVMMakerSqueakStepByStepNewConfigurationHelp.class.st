"
A CMakeVMMakerSqueakNewConfigurationStepByStepHelp itemizes the steps needed to create a new build configuration.

HelpBrowser openOn: CMakeVMMakerSqueakNewConfigurationStepByStepHelp
"
Class {
	#name : #CMakeVMMakerSqueakStepByStepNewConfigurationHelp,
	#superclass : #CMakeVMMakerSqueakConfigurationsHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> aNoteOnFoo [
	^HelpTopic
		title:'A Note On FOO'
		contents:
'Since we have customized plugins, now is a good time to introduce the FOO in [PLATFORM][Language][VM][Memory Manager][BuildType][foo] 

The purpose of FOO is to accomadate personal plugins that ''just work'' for an odd-ball platform or odd set of plugins or some obscure operating system..

Some examples will suffice to convey the purpose of FOO. (below I encase [FOO] for clarity)

Linux64x86w32BitSqueakCogV3[WithoutGL]Config

SqueakBSD32x86[TTYsConfigurationFromHell]Config

Linux32x86SqueakCogV3[BillyBobVeryOwn]Config

Linux32x86SqueakCogV3[withoutIA32BOCHSPLugin]Config

you get the idea. 


'
]

{ #category : #accessing }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> bookName [ 
	^'Example Workflow: New Configuration'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> compilingLinkingSetup [
	^HelpTopic
		title:'Compiling and Linking Setup'
		contents:
'In your concrete configuration''s ''compiling'' protocol contains the methods that you must customize for your Configuration

cmakeAddDefinitionsBuild
cmakeCFlagsBuild
externalLibsBuild
linkerFlags


'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> configureAbstractBaseClass [
	^HelpTopic
		title:'Configure Abstract Base Class'
		contents:
'Abstract Base Classes contain configuration information for a specific platform.

Let''s start from the top and work are way down. evaluate:

CPlatformConfigForSqueak browseHierarchy

CPlatformConfigForSqueak is a fairly involved class, but focusing on the protocol ''cmake directory'' for now, we see a bunch of dirFOO methods.

selectinng: 

CPlatformConfigForSqueak >>dirLinux32x86
	^''cmake.build.linux32x86'' 

We see the top-level directory for our new platform specific build. 

The next level down in our hierarchy is SqueakUnixConfig which contains configuration info specific to Unix platforms. An example being: 

SqueakUnixConfig>>platformName
	^self unixPlatformName


The next level down is our Abstract Base Class for our specific variant of Unix--specifically Linux32x86Config.

The methods in this class contain system wide configuratin information for this Platform. On a mature platform tree, this class''s configuration should be rock-solid. However, as of 2014.12.09, the Abstract Base Class has not been configured correctly and I must set it up here. 

Setting it up is not difficult and an existing Abstract Base Class can provide a good starting point. However, a familiarity with the design patterns of the Configurations is helpful (particularly the Redirect Method pattern)

HelpBrowser openOn: CMakeVMMakerSqueakDesignPatternsHelp




'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> createTheConfiguration [
	^HelpTopic
		title:'Create the Configuration'
		contents:
'Our new Concrete Configuration must be created as a subclass of our Platform''s Abstract Base Class.

SInce I am creating a Squeak Cog Spur config for the CMakeVMMakerSqueak-Linux64X86-32BitCompatibility Platform I choose the name:

Linux64x86w32BitSqueakCogSpurConfig.

(For a discussion on naming conventions evaluate:
HelpBrowser openOn: CMakeVMMakerSqueakOverviewHelp
)

To create it, I must subclass the Abstract Base Class for my Platform like so:

Linux64x86w32BitConfigUsrLib subclass: #Linux64x86w32BitSqueakCogSpurConfig
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: ''CMakeVMMakerSqueak-Linux64X86-32BitCompatibility''

However, being lazy, I am going to copy an existing Configuration that is similar to what I want. 

Today I choose Linux64x86w32BitSqueakCogV3Config from the  CMakeVMMakerSqueak-Linux64X86-32BitCompatibility Platform category

I copy the class and then change its name, parent and class category to get:

Linux64x86w32BitConfigUsrLib subclass: #Linux64x86w32BitSqueakCogSpurConfig
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: ''CMakeVMMakerSqueak-Linux64X86-32BitCompatibility''


I then query by Builder to see if it sees the new Configuration in the platform:

SqueakLinux64x86w32CompatBuilder configurationsCategory
-->  ''CMakeVMMakerSqueak-Linux64X86-32BitCompatibility''

SqueakLinux64x86w32CompatBuilder  availableBuildConfigurations  
-->  a SortedCollection(#Linux64x86w32BitSqueakCogSpurConfig #Linux64x86w32BitSqueakCogV3Config)
   "Here we see our new Configuration is visible to the Builder"

SqueakLinux64x86w32CompatBuilder  unAvailableBuildConfigurations
-->  a SortedCollection(#Linux64x86w32BitConfigUsrLib #Linux64x86w32BitConfigUsrLib32)  "Our Abstract Base Classes are not available to be built"

SqueakLinux64x86w32CompatBuilder availableBuildTypesFor: #Linux64x86w32BitSqueakCogSpurConfig
--> an OrderedCollection(#build #buildAssert) "The Configuration I copied has two Build Types coded and available."


SqueakLinux64x86w32CompatBuilder  sourceDirectoryFor:#Linux64x86w32BitSqueakCogSpurConfig
-->  "src"                                                        "Where the vm source code is located (we will be changing this)"

My new configuration is correctly named and in the correct place. 

At this point I re-run all my Tests.
TestRunner open
 For me, all tests pass.

In the next topic we cover how to hide our new Configuration from a builder. 

'

]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> customizePlugins [
	^HelpTopic
		title:'customize Plugins'
		contents:
'We can customize which plugins we want on our configuration by overriding our platform''s defaultExternalPlugins and defaultInternalPlugins methods.

The default set can be further customized according to buildType if desired via the externalPlugins[BuildType] and internalPlugins[BuildType] redirect pattern


'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> customizeVMDrivers [
	^HelpTopic
		title:'Specify VM Drivers'
		contents:
'The SqueakUnixConfig contains the unverisal list of VM Drivers for *nix.

In our concrete Configuration, we need to specify which ones we want for out build.

We do this by overloading the SqueakUnixConfig>>customizeVMDrivers method.

'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> excludingConfigFromBuilds [
	^HelpTopic
		title:'Excluding a Config From Builds'
		contents:
'Configurations can hide themselves from , or make themselves visible to Builders via their ''excludeFromBuild'' method.

excludeFromBuild
	^false   "build this configuration"
"	^true     do not build this configuration"   

In our case, the Builder shows us that Linux32x86SqueakCogSpurConfig is capable of being built (I had copied an existing, working Configuration):

SqueakLinux64x86w32CompatBuilder availableBuildConfigurations
--> a SortedCollection(#Linux64x86w32BitSqueakCogSpurConfig #Linux64x86w32BitSqueakCogV3Config)


To exclude it, override (or alter) the Configurations ''excludeFromBuild'' method

Linux64x86w32BitSqueakCogSpurConfig >>excludeFromBuild
	"over-ride to exclude yourself from a build"
	^true

And the Configuration is hidden from the Builder...

SqueakLinux64x86w32CompatBuilder availableBuildConfigurations
-->  a SortedCollection(#Linux64x86w32BitSqueakCogV3Config)


However, since I am developing locally, I need it to be visible to the Builder , so I set it as so:

Linux64x86w32BitSqueakCogSpurConfig >>excludeFromBuild
	"over-ride to exclude yourself from a build"
	^false

And my Builder can see it again...

SqueakLinux64x86w32CompatBuilder availableBuildConfigurations  
-->  a SortedCollection(#Linux64x86w32BitSqueakCogSpurConfig #Linux64x86w32BitSqueakCogV3Config)


N.B. tty. My opinion is that this is a weak way of doing this, but I have not thought through how to do this elegantly. 
This functionality is included with an eye towards easing automated builds for all platforms and configurations.'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> firstCMakeGeneration [
	^HelpTopic
		title:'First CMake Generation'
		contents:
'For didactic purposes I am going to do a sanity check and generate CMake code from the configuration for the first time. 

If you are not familiar with the CMakeVMMakerSqueak naming conventions, please evaluate:
HelpBrowser openOn: CMakeVMMakerSqueakOverviewHelp

On my system the Cog svn tree is located under my Squeak install directory in the folder ''oscogvm".

Opening an X-term and navigating there it looks like this:

bash-4.2$ pwd
/home/tty/usr/src/smalltalk/CMake.oscog/cogVMMaker/oscogvm

The contents of the directory look something like this. Note the subdirectory that starts with ""cmake.""

bash-4.2$ ls --width=1
CHANGES
LICENSE
README
README.old
build
build.linux32ARM
build.linux32x86
build.macos32x86
build.macos64x64
build.win32x86
cmake.build.linux64x86w32BitCompatibility  <-----created by CMakeVMMakerSqueak for the Linux64x86w32BitSqueakCogV3Config
history
image
.....

That cmake.build.linux64x86w32BitCompatibility directory was generated by a previous cmake generation for the Linux64X86-32BitCompatibility Platform.

For demonstration sake, I remove the directory. 
bash-4.2$ rm -Rf cmake.*   

Now, I ask the Builder to configure my new configuration for a buildType and output its contents. I do so by evaluating:

SqueakLinux32x86Builder
	configureA: #Linux32x86SqueakCogV3Config forBuildType:#build; 
	enableMessageTracking: true;
	generateByTemplate.

(Note: if you get errors during the generatation, shut down squeak and restart. I think it has something to do with open file handles):

and look again 

bash-4.2$ ls  cmake.build.linux64x86w32BitCompatibility/
squeak.cog.v3

bash-4.2$ tree cmake.build.linux64x86w32BitCompatibility/
`-- squeak.cog.v3
    `-- build
        |-- ADPCMCodecPlugin
        |   `-- CMakeLists.txt
...etc
We see that the configuration has generated its build heirarchy.

Note, however that the cmake.build.linux64x86w32BitCompatibility directory is for a different Platform! Since we copied an existing Configuration from a different platform, this make sense.

To change it, we go to our Abstract Base Class and modify

Linux32x86Config>>dirBuildPlatform
	^self dirLinux32x86

Then regenerate our CMake

SqueakLinux32x86Builder
	configureA: #Linux32x86SqueakCogV3Config forBuildType:#build; 
	enableMessageTracking: true;
	generateByTemplate.

And examine our directory:

bash-4.2$ ls cmake.build.linux* 
cmake.build.linux32x86:                         <dirLinux32X86
squeak.cog.v3

and examining the heirarchy we see:

bash-4.2$ tree -d cmake.build.linux32x86/
cmake.build.linux32x86/
`-- squeak.cog.v3
    `-- build
        |-- ADPCMCodecPlugin
        |-- AsynchFilePlugin
        |-- B2DPlugin
        |-- BMPReadWriterPlugin
        |-- BitBltPlugin
        |-- CroquetPlugin
        |-- DSAPrims
        |-- DropPlugin
        |-- FFTPlugin
        |-- FileCopyPlugin
        |-- FilePlugin
        |-- FloatArrayPlugin
        |-- FloatMathPlugin
        |-- JoystickTabletPlugin
        |-- Klatt
        |-- LargeIntegers
        |-- LocalePlugin
        |-- MIDIPlugin
        |-- Matrix2x3Plugin
        |-- MiscPrimitivePlugin
        |-- Mpeg3Plugin
        |-- SecurityPlugin
        |-- SerialPlugin
        |-- SocketPlugin
        |-- SoundCodecPrims
        |-- SoundGenerationPlugin
        |-- SoundPlugin
        |-- StarSqueakPlugin
        |-- SurfacePlugin
        |-- ZipPlugin
        |-- vm-display-X11
        |-- vm-display-null
        |-- vm-sound-ALSA
        `-- vm-sound-nul


Congratulations. You are almost done.

From here on out your only task is to correctly customize your Concrete Configuration such that it correctly builds for your [platform][language][vm][memorymodel][buildType]



'


]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> identifyBuilder [
	^HelpTopic
		title:'Identify Builder'
		contents:
'My new Configuration will be managed by a Builder.

Builders are located in the CMakeVMMakerSqueak-Builder class category.

Builders are subclasses of SqueakCMakeVMMakerAbstractBuilder.
SqueakCMakeVMMakerAbstractBuilder browseHierarchy

Builders are named according to the Platform they manage.

(For a discussion on naming conventions evaluate:
HelpBrowser openOn: CMakeVMMakerSqueakOverviewHelp
)

Builders manage configurations for one Platform in one  class category.


My platform is Linux Linux64x86 with 32 bit compatability libs stored in /usr/lib (other linux use /usr/lib32 for this.)

I suspect that the  SqueakLinux64x86w32CompatBuilder as the Builder that will manage my new configuration.

I confirm this by sending it the ''configurationsCategory'' message as shown below:

SqueakLinux64x86w32CompatBuilder configurationsCategory 
-->''CMakeVMMakerSqueak-Linux64X86-32BitCompatibility''                    <---this is the correct class category for my Platform.

This is correct Builder for my new Configuration. 

I can query  the Builder for some more information:

SqueakLinux64x86w32CompatBuilder  availableBuildConfigurations
  a SortedCollection(#Linux64x86w32BitSqueakCogV3Config)   <--A Cog V3 configuration exists. 

SqueakLinux64x86w32CompatBuilder  unAvailableBuildConfigurations 
--> a SortedCollection(#Linux64x86w32BitConfigUsrLib #Linux64x86w32BitConfigUsrLib32)
 <--these are platform specific Abstract Base Classes. Abstract Base Classes cannot be built, hence they are unavailable.

SqueakLinux64x86w32CompatBuilder  buildDirectory 
-->''cmake.build.linux64x86w32BitCompatibility''                     <--this matches my platform

We will be using the SqueakLinux64x86w32CompatBuilder in tandem with Tests during Configuration development.'


]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> identifyPlatform [
	^HelpTopic
		title:'Identify Platform'
		contents:
'My target platform is 64 bit Linux on X86 with 32 bit compatibility libraries stored in /usr/lib.

I identify my Platform in the existing CMakeVMMakerSqueak-xyz class categories.  


If I wanted a configuration for MacOSX32x86, I would place my configuration in CMakeVMMakerSqueak-MacOSX32x86.
If SunOSx3x86 then CMakeVMMakerSqueak-SunOS32x86.
etc.

For a discussion on naming conventions evaluate:
HelpBrowser openOn: CMakeVMMakerSqueakOverviewHelp
'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> identifyPlatformAbstractBaseClass [
	^HelpTopic
		title:'Identify Abstract Base Class '
		contents:
'My new configuration must be a subclass of my Platform''s Abstract Base Class. 

A Platform Abstract Base Class encapsulates common platform information. 

In CMakeVMMakerSqueak-Linux64X86-32BitCompatibility class category I see two Abstract Base Classes (typically there is only one). They are:

Linux64x86w32BitConfigUsrLib 
Linux64x86w32BitConfigUsrLib32

The Suffixes ''UsrLib'' and ''UsrLib32'' refer to the location of the 32 bit compatablity libs. 
On my system they are in /usr/lib,  so I choose  Linux64x86w32BitConfigUsrLib as my Abstract Base Class

Examples of Abstract Base Classes in other class categories  include:

CMakeVMMakerSqueak-BSD32x86                                -> SqueakBSD32x86Config
CMakeVMMakerSqueak-IA32-Bochs                               -> SqueakIA32BochsConfig
CMakeVMMakerSqueak-IOS                                           -> SqueakIOSConfig
CMakeVMMakerSqueak-IOS                                           -> SqueakIOSConfig
CMakeVMMakerSqueak-Linux32ARMv6                          -> Linux32ARMv6Config
CMakeVMMakerSqueak-Linux64x64                              -> Linux64x64Config
CMakeVMMakerSqueak-MacOSPowerPC                        -> SqueakMacOSXPowerPCConfig
CMakeVMMakerSqueak-MacOSX32x86                          -> SqueakMacOSX32x86Config
CMakeVMMakerSqueak-SunOS32x86                            -> SqueakSunOS32x86Config
CMakeVMMakerSqueak-Win32x86                                 -> SqueakWin32x86Config

I can identify the Abstract Base Class in several ways

1. It is a  topmost class in the class heirarchy for that platform/class category
2. It is named after its platform
3. It answers #true to the message isAbstractBaseClass
Linux64x86w32BitConfigUsrLib  isAbstractBaseClass 
--> true

In this workflow example I ideduce that the  AbstractBaseClass for my Platform is Linux64x86w32BitConfigUsrLib'
]

{ #category : #accessing }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> key [
	^'CMakeVMMakerSqueakStepByStepNewConfigurationHelp'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> overview [
	^HelpTopic
		title:'Overview'
		contents:
'This Help Topic presents the workflow the author used in creating the  Squeak, Cog, Spur CMake configuration for a 64 bit Slackware 14.1 system.with 32 bit compatability libs in /usr/lib

The steps involved should be the same for any platform.'
]

{ #category : #accessing }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> pages [
	^#(overview 
tests 
identifyPlatform 
identifyPlatformAbstractBaseClass
identifyBuilder
createTheConfiguration
excludingConfigFromBuilds
setAvailableBuildTypes
firstCMakeGeneration
takingStock
theVMGenerator
reviewMethodRedirectPattern
setOutputDirectory
settingPlugins
compilingLinkingSetup
customizeVMDrivers
customizePlugins
aNoteOnFoo
)
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> reviewMethodRedirectPattern [
	^HelpTopic
		title:'Review of Method Redirect Pattern'
		contents:
'Besides the VMGenerator>>generateByTemplate, the system relies heavily on what I call a Method Redirect Pattern.

If you have not read it yet, its a short read here:

HelpBrowser openOn: CMakeVMMakerSqueakDesignPatternsHelp

'


]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> setAvailableBuildTypes [
	^HelpTopic
		title:'Setting Available Build Types'
		contents:
'Configurations  inform Builders what BuildTypes they support. via the availableBuildTypes method

Here is my Builder asking my new Configuration what build types it supports (remember, this Configuration was copied, so it has been configured already)

SqueakLinux64x86w32CompatBuilder availableBuildTypesFor: #Linux64x86w32BitSqueakCogSpurConfig
-->  an OrderedCollection(#build #buildAssert)


In our Abstract Base Class (Which, you recall cannot be buil)for our Platform, we default to no build types.

Linux64x86w32BitConfigUsrLib>>availableBuildTypes
 	 ^SqueakCMakeVMMakerAbstractBuilder  default  noBuildTypes


To get an idea of what buildTypes are available system wide evaluate
SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes 
-->an OrderedCollection(#build #buildAssert #buildAssertITimerHeartbeat #buildDebug #buildDebugITimerHeartbeat #buildITimerHeartbeat #buildMultiThreaded #buildMultiThreadedAssert #buildMultiThreadedDebug #buildNone)


To set the available build types for a Concrete Configurations we override the AbstactBaseClass''s method and SUBTRACT OUT what we do not want. Like so:

Since I am starting simple, I want my configuration to build a vanilla build. To do this I remove all but #build buildType like so

Linux64x86w32BitSqueakCogSpurConfig >> availableBuildTypes 
	^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes copyWithoutAll: #( #buildAssert #buildAssertITimerHeartbeat #buildDebug #buildDebugITimerHeartbeat #buildITimerHeartbeat #buildMultiThreaded #buildMultiThreadedAssert #buildMultiThreadedDebug #buildNone)


As I code more build types in my configuration, I subtract out 

Linux32x86SqueakCogV3Config >> availableBuildTypes 
	^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes copyWithoutAll: #(  #buildMultiThreadedDebug #buildNone)

With the result that my Builder shows the removed items as Available Build Types:

SqueakLinux32x86Builder availableBuildTypesFor: #Linux32x86SqueakCogV3Config 
--> an OrderedCollection(#build #buildAssert #buildAssertITimerHeartbeat #buildDebug #buildDebugITimerHeartbeat #buildITimerHeartbeat #buildMultiThreaded #buildMultiThreadedAssert)

Since I will only be developing the #build buildType for now, I put it as so:

Linux32x86SqueakCogV3Config>>availableBuildTypes 
	^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes copyWithoutAll: #( #buildAssert #buildAssertITimerHeartbeat #buildDebug #buildDebugITimerHeartbeat #buildITimerHeartbeat #buildMultiThreaded #buildMultiThreadedAssert #buildMultiThreadedDebug #buildNone)


and verify it is correct:

SqueakLinux32x86Builder availableBuildTypesFor: #Linux32x86SqueakCogV3Config 
-->an OrderedCollection(#build)


*N.B. tty. In my opinion, this is a weak design on my part. as it relies on the developr to set it up. If there is an elegant way to do this , I am for it.
'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> setOutputDirectory [
	^HelpTopic
		title:'Set Output Directory'
		contents:
'The output directory is where the finished product is placed when the compilation is successful.

Typically this is ''oscogvm/cmake.products/foo/

The topmost configuration CPlatformConfigForSqueak defines the output directory as such:

outputDir
	"the directory where built binaries will be stored"
	^ outputDir ifNil: [ outputDir := (self topDir / self dirOutput /  self dirInstall) ]	

which (on linux) translates to ''oscogvm/cmaike.products/(subclass resposibility))''

Its that (subclass responsibility) we have to customize in our new configuration.

The convention we use is [Language][VM][MemoryModel]

Since I am building a Squeak Cog V3 configuration, my method should return "squeak.cog.v3"

If you look at implementors of dirInstall, you will see that they typically return some pre-defined strings that are defined in the ''cmake directory'' protocol of CPlatformConfigForSqueak.

For my configuration you can see that I return the "^self squeakCogV3" which returns the directory name that matches the [Language][VM][Memory Model] pattern I need.




'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> settingPlugins [
	^HelpTopic
		title:'Setting Plugins'
		contents:
'Write Me.'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> takingStock [
	^HelpTopic
		title:'Where You Are Now'
		contents:
' If your Concrete Builder has successfully generate the CMake tree in the correct folder structure then you are almost done.

The rest of the process from here on out is tweaking the Concrete Configuration so that it generates valid CMake for your platform and buildTypes.

If you have not generated CMake output at this point, go back and try until you can.

At this point, please evaluate:
HelpBrowser openOn: CMakeVMMakerSqueakDesignPatternsHelp

And read the section on the Method Redirect Pattern before continuing.
'


]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> tests [
	^HelpTopic
		title:'Tests'
		contents:
'We start with Tests.

The Tests are in class category CMakeVMMakerSqueak-Tests.

They are:

CMakeVMMakerSqueakBuildersTest
CMakeVMMakerSqueakCommonConfigTest
CMakeVMMakerSqueakMacintoshConfigTest
CMakeVMMakerSqueakRedirectMethodsTest
CMakeVMMakerSqueakRedirectMethodsWithArgTest
CMakeVMMakerSqueakUnixConfigTest
CMakeVMMakerSqueakWindowsConfigTest

As of 2014.12.09 all tests pass. 

As we create the Configuration these tests will be an important check on our work and we will return to them often.'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> theVMGenerator [
	^HelpTopic
		title:'The VM Generator'
		contents:
'Before we move onto setting the most common directives and flags in the Concrete Configuration, lets take a quick look at the method that actually generates the CMake files for us. You probably will not need this, but its handy to know of.

CMakeVMGeneratorForSqueak browse

Look at the generateByTemplate method and the long cascade that starts with:

	config 
		setGlobalOptions: self;    
		cmakePrefixPath;
		cmakeIncludePath;.....


Here you see the generator extracting CMake data from your Configuration in a straighforward order.

The names of the methods are a bit of a holdover from the pharo code and do not conceptually match the sections of Ian Piumarta''s CMake template. 

If you generate your CMake files with message tracking enabled as per below

SqueakLinux32x86Builder
	configureA: #Linux32x86SqueakCogV3Config forBuildType:#build; 
	enableMessageTracking: true;                                                 <---message tracking 
	generateByTemplate.


You can see in your CMakeLists.txt which method is responsible for which bits of code.

Here we see these two lines from the VMGenerator

	config 
	      ....
		cmakeIncludeDirectories:  self;
		preferredIncludes;     
            ....

tracked in the CMakeLists.txt

  message( "Linux32x86SqueakCogV3Config includeDirs: aMaker")                                             <---message tracking message
  include_directories(  ${crossDir}/vm ${srcVMDir} ${targetPlatform}/vm ${buildDir})                <--output of cmakeIncludeDirectories:self
  message( "Linux32x86SqueakCogV3Config preferredIncludesBuild")                                       <--message tracking message
  include_directories(  ${targetPlatform}/plugins/B3DAcceleratorPlugin)                                     <-- output of preferredIncludesBuild

'


]
