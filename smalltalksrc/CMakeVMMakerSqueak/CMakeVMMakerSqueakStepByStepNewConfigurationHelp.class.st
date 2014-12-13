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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> choosePlugins [
	^HelpTopic
		title:'Choose Plugins'
		contents:
'

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

SInce I am creating a Squeak Cog V3 config for the Linux32x86 Platform I choose the name:

Linux32x86SqueakCogV3Config.

(For a discussion on naming conventions evaluate:
HelpBrowser openOn: CMakeVMMakerSqueakOverviewHelp
)

To create it, I subclass the Abstract Base Class for my Platform like so:

Linux32x86Config subclass: #Linux32x86SqueakCogV3Config
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: ''CMakeVMMakerSqueak-Linux32x86''

However, being lazy, I am going to copy an existing Configuration that is similar to what I want. 

Today I choose Linux64x86w32BitSqueakCogV3Config from the  CMakeVMMakerSqueak-Linux64X86-32BitCompatibility Platform category

I copy the class and then change its parent and class category to get:

Linux32x86Config subclass: #Linux32x86SqueakCogV3Config
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: ''CMakeVMMakerSqueak-Linux32x86''


At this point I re-run all my Tests. For me, all tests pass.

I then query by Builder to see if it sees the new Configuration in the platform:

SqueakLinux32x86Builder configurationsCategory
-->  ''CMakeVMMakerSqueak-Linux32x86''

SqueakLinux32x86Builder  availableBuildConfigurations   
--> a SortedCollection(#Linux32x86SqueakCogV3Config)    "Here we see our new Configuration is visible to the Builder"

SqueakLinux32x86Builder  unAvailableBuildConfigurations
--> a SortedCollection(#Linux32x86Config)  "The Abstract Base Class is not available to be built"

SqueakLinux32x86Builder availableBuildTypesFor: #Linux32x86SqueakCogV3Config 
--> an OrderedCollection(#build)                    "The Configuration I copied has one Build Type coded/available."


SqueakLinux32x86Builder  sourceDirectoryFor:#Linux32x86SqueakCogV3Config
-->  "src"                                                        "Where the vm source code is located"

My new configuration is correctly named and in the correct place. 

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

This functionality is included with an eye towards easing automated builds for all platforms and configurations.

In our case, the Builder shows us that Linux32x86SqueakCogV3Config is capable of being built (I had copied an existing, working Configuration):

SqueakLinux32x86Builder availableBuildConfigurations
--> an OrderedCollection(#Linux32x86SqueakCogV3Config)

To exclude it, override (or alter) the Configurations ''excludeFromBuild'' method

Linux32x86SqueakCogV3Config >>excludeFromBuild
	"over-ride to exclude yourself from a build"
	^true

And the Configuration is hidden from the Builder...

SqueakLinux32x86Builder availableBuildConfigurations 
--> an OrderedCollection()


However, since I am developing locally, I need it to be visible to the Builder , so I set it as so:

Linux32x86SqueakCogV3Config >>excludeFromBuild
	"over-ride to exclude yourself from a build"
	^false

And my Builder can see it again...

SqueakLinux32x86Builder availableBuildConfigurations  
an OrderedCollection(#Linux32x86SqueakCogV3Config)


N.B. tty. My opinion is that this is a weak way of doing this, but I have not thought through how to do this elegantly. 






'
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

Builders are named according to the Platform they manage.

(For a discussion on naming conventions evaluate:
HelpBrowser openOn: CMakeVMMakerSqueakOverviewHelp
)

Builders manage configurations for one Platform in one  class category.

My platform is Linux 32x86.

I suspect that the  SqueakLinux32x86Builder as the Builder that will manage my new configuration.

I confirm this by sending it the ''configurationsCategory'' message as shown below:

SqueakLinux32x86Builder configurationsCategory 
-->''CMakeVMMakerSqueak-Linux32x86''                    <---this is the correct class category for my Platform.

This is correct Builder for my new Configuration. 

I can query  the Builder for some more information:

SqueakLinux32x86Builder  availableBuildConfigurations
 a SortedCollection()    <--there are no concrete configurations in place as of this writing.

SqueakLinux32x86Builder  unAvailableBuildConfigurations 
a SortedCollection(#Linux32x86Config)   <--this is my Abstract Base Class. Abstract Base Classes cannot be built, hence they are unavailable.

SqueakLinux32x86Builder  buildDirectory 
-->''cmake.build.linux32x86''                     <--this matches my platform

We will be using the SqueakLinux32x86Builder in tandem with Tests during Configuration development.'


]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> identifyPlatform [
	^HelpTopic
		title:'Identify Platform'
		contents:
'My target platform is Linux 32 bit x86. 

I identify my Platform in the existing CMakeVMMakerSqueak-xyz class categories.  

I choose the  CMakeVMMakerSqueak-Linux32x86 as the location for my new Configuration.

If I wanted a configuration for MacOSX32x86, I would place my configuration in CMakeVMMakerSqueak-MacOSX32x86.
If SunOSx3x86 then CMakeVMMakerSqueak-SunOS32x86.
etc, etc.


(For a discussion on naming conventions evaluate:
HelpBrowser openOn: CMakeVMMakerSqueakOverviewHelp
)


'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> identifyPlatformAbstractBaseClass [
	^HelpTopic
		title:'Identify Abstract Base Class '
		contents:
'My new configuration must be a subclass of my Platform''s Abstract Base Class. 

In class category CMakeVMMakerSqueak-Linux32x86 the Abstract Base Class is  Linux32x86Config 

Examples of Abstract Base Classes in other class categories  (category->Abstract Base Class) include:

CMakeVMMakerSqueak-BSD32x86                                -> SqueakBSD32x86Config
CMakeVMMakerSqueak-IA32-Bochs                               -> SqueakIA32BochsConfig
CMakeVMMakerSqueak-IOS                                           -> SqueakIOSConfig
CMakeVMMakerSqueak-IOS                                           -> SqueakIOSConfig
CMakeVMMakerSqueak-Linux32ARMv6                          -> Linux32ARMv6Config
CMakeVMMakerSqueak-Linux64X86-32BitCompatibility -> Linux64x86w32BitConfig
CMakeVMMakerSqueak-LinuxX86-64                             -> Linux64Config
CMakeVMMakerSqueak-MacOSPowerPC                        -> SqueakMacOSXPowerPCConfig
CMakeVMMakerSqueak-MacOSX32x86                          -> SqueakMacOSX32x86Config
CMakeVMMakerSqueak-SunOS32x86                            -> SqueakSunOS32x86Config
CMakeVMMakerSqueak-Win32x86                                 -> SqueakWin32x86Config

I can identify the Abstract Base Class in several ways

1. It is the topmost class in the class category for that platform
2. It is named after its platform
3. It answers #true to the message isAbstractBaseClass
Linux32x86Config  isAbstractBaseClass 
--> true
4. Its class initialize method sets its isAbstractBaseClass class instance variable to #true
5. It is the only Abstract Base Class in its immediate class heirarchy.

My new configurations will be a subclass of the AbstractBaseClass for my platform. 

In this workflow example the AbstractBaseClass for my Platform is Linux32x86Config

'
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
'This Help Topic is a running commentary on how I created Squeak, Cog, V3 CMake configuration for a pure 32 bit Slackware 14.1 system.


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
setOutputPath
settingPlugins
aNoteOnFoo
)
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> setAvailableBuildTypes [
	^HelpTopic
		title:'Setting Available Build Types'
		contents:
'Configurations  inform Builders what BuildTypes they support. via the availableBuildTypes method*

Here is my Builder asking my new Configuration what build types it supports (remember, this Configuration was copied, so it has been configured already)

SqueakLinux32x86Builder availableBuildTypesFor: #Linux32x86SqueakCogV3Config 
-->an OrderedCollection(#build)

In our Abstract Base Class (Which, you recall cannot be buil)for our Platform, we default to all build types.

Linux32x86Config>>availableBuildTypes
	 ^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes

Evaluating  the return gives us:

SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes 
-->an OrderedCollection(#build #buildAssert #buildAssertITimerHeartbeat #buildDebug #buildDebugITimerHeartbeat #buildITimerHeartbeat #buildMultiThreaded #buildMultiThreadedAssert #buildMultiThreadedDebug #buildNone)


To set the available build types for a Concrete Configurations we override the AbstactBaseClass''s method and SUBTRACT OUT what we do not want. Like so:

Linux32x86SqueakCogV3Config >> availableBuildTypes 
	^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes copyWithoutAll: #( #buildAssert #buildAssertITimerHeartbeat #buildDebug #buildDebugITimerHeartbeat #buildITimerHeartbeat #buildMultiThreaded #buildMultiThreadedAssert #buildMultiThreadedDebug #buildNone)


Here I show what happens when I subtract more from the available pool. Here I set my Configuration to only omit 2 build types:

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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> setOutputPath [
	^HelpTopic
		title:'Set Output Path'
		contents:
'WRITE ME

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

And read the secion on the Method Redirect Pattern before continuing.
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
