"
A CMakeVMMakerSqueakNewConfigurationStepByStepHelp itemizes the steps needed to create a new build configuration.

HelpBrowser openOn: CMakeVMMakerSqueakNewConfigurationStepByStepHelp
"
Class {
	#name : #CMakeVMMakerSqueakStepByStepNewConfigurationHelp,
	#superclass : #CMakeVMMakerSqueakConfigurationsHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> bookName [ 
	^'Step By Step: New Configurations'
]

{ #category : #accessing }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> key [
	^'CMakeVMMakerSqueakStepByStepNewConfigurationHelp'
]

{ #category : #accessing }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> pages [
	^#(step1 
		step2 
		step3 
		step4 
		step4a 
		step4b 
		step4c 
		step4d 
		step4e 
		step4f 
		step4g 
		step4h 
		step4i 
		step4j 
		step4k 
		step4l 
		step4m
		step5 
)
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> step1 [
	^HelpTopic
		title:'Step 1. Choose Your Category'
		contents:
' CMakeVMMakerSqueak configurations are placed in a Smalltalk category with the naming convention [OS][VMWordSize][Processor]

You start by choosing the correct Smalltalk Category in which to place your new Configuration.

Example; If you need a new configuration for Linux for a 32 bit VM on the x86 platform--[Linux][32][x86]--Choose the CMakeVMMakerSqueak-Linux32x86 category.

A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> step2 [
	^HelpTopic
		title:'Step 2. Copy Existing Concrete Configuration'
		contents:
'Now that you have selected your category to place your new Configuration, you need to create your configuration.

Like Categories, Configurations adhere to a naming convention. It is [language][VM][MemoryManager][etc]Config
example: squeak.cog.v3.tty  is a configuration for compiling Squeak with a Cog VM with the old V3 memory manager and this is a special configuration for tty.

The easiest way to create the config is to subclass an existing configuration. In this case I would subclass squeak.cog.v3.

IMPORTANT: Do not copy a configuration (usually the top one in a category) that has the "	uses: TCPlatformConfigForSqueak"
line in its definition. While there are technical reasons for this warning, the important one is that it makes coding a pain-in-the-butt.


A Reminder: Consistent Naming Conventions Are Our Friends!
'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> step3 [
	^HelpTopic
		title:'Step 4. Customize the "cmake" protocol'
		contents:
'TODO
dirInstall
	"the directory of the finished product.. the place where ''make install'' puts stuff.
	SystemNavigation default browseMethodsWhoseNamesContain: ''dirInstall''
      "
	^self squeakCogV3 , ''.noGL''


excludeFromBuild
	^false   "build this configuration"
"	^true"

executableName
	^ self vmCogExecutableName
A Reminder: Consistent Naming Conventions Are Our Friends!
'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> step4 [
	^HelpTopic
		title:'Step 4. Customize the "cmake build type config" protocol'
		contents:
'When we invoke a Builder with a command like:

SqueakLinux64x86w32CompatBuilder
	configureA: #Linux64x86w32BitSqueakCogV3SlackwareNoGLConfig forBuildType: #buildDebugITimerHeartbeat;
	generateSources;
	generate.  

We are telling the Builder to select a Configuration and have that Configuration configure itself to produce CMake output for the buildType: #buildDebugITimerHeartbeat;

On your configuration the entry point for your configuration is one of:

configureBuild
configureBuildAssert
configureBuildAssertITimerHeartbeat
configureBuildDebug
configureBuildDebugITimerHeartbeat                        <----this one is selected by buildType: #buildDebugITimerHeartbeat;
configureBuildITimerHeartbeat
configureBuildMultiThreaded
configureBuildMultiThreadedAssert
configureBuildMultiThreadedDebug

Within this method, system state is set up and customizable for many methods in CMakeVMaker CPlatformConfig.

"setGlobalOptions: aMaker"
"setGlobalOptionsAfterDetermineSystem: aMaker"
setupDirectories
preferredIncludes
standardIncludes
compilerFlags
"extraVMSettings: aMaker"
internalPlugins
externalPlugins
thirdpartyLibs
"setExtraTargetProperties: aMaker"
"postBuildActions: aMaker"
configH

The methods above that take the : aMaker argument are handled on-the-fly later in the process and are only presented here for informational purposes.



A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> step4a [
	^HelpTopic
		title:'Step 4a. setGlobalOptions'
		contents:
'TODO: summarize this



A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> step4b [
	^HelpTopic
		title:'Step 4b. setGlobalOptionsAfterDetermineSystem'
		contents:
'TODO: summarize this




A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> step4c [
	^HelpTopic
		title:'Step 4c. setupDirectories'
		contents:
'TODO: summarize this



A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> step4d [
	^HelpTopic
		title:'Step 4d. preferredIncludes'
		contents:
'This is handy when ''make'' cannot find a header.

 For example, when compiling 

I got error:
Scanning dependencies of target UnixOSProcessPlugin
/..../oscogvm/src/plugins/UnixOSProcessPlugin/UnixOSProcessPlugin.c:48:26: fatal error: SocketPlugin.h: No such file or directory

From my topDir (oscogvm) I did  a search and found SocketPlugin.h exits in  ./platforms/Cross/plugins/SocketPlugin/SocketPlugin.h

in my root config class for my category, I had...

''${targetPlatform}/plugins/SocketPlugin''

I changed it to 

''${crossDir}/plugins/SocketPlugin''

deleted my files in my build directory, re-ran the generate and...



	SystemNavigation default browseMethodsWhoseNamesContain: ''preferredIncludes''
  

A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> step4e [
	^HelpTopic
		title:'Step 4e. standardIncludes'
		contents:
'TODO: summarize this



A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> step4f [
	^HelpTopic
		title:'Step 4f. compilerFlags'
		contents:
'TODO: summarize this



A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> step4g [
	^HelpTopic
		title:'Step 4g. extraVMSettings'
		contents:
'TODO: summarize this



A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> step4h [
	^HelpTopic
		title:'Step4h internalPlugins'
		contents:
'TODO: summarize this



A Reminder: Consistent Naming Conventions Are Our Friends!
'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> step4i [
	^HelpTopic
		title:'Step4i externalPlugins'
		contents:
'TODO: summarize this




A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> step4j [
	^HelpTopic
		title:'Step4j thirdpartyLibs'
		contents:
'TODO: summarize this


A Reminder: Consistent Naming Conventions Are Our Friends!


'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> step4k [
	^HelpTopic
		title:'Step4k setExtraTargetProperties:aMaker'
		contents:
'TODO: summarize this



A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> step4l [
	^HelpTopic
		title:'Step4k postBuildActions: aMaker'
		contents:
'TODO: summarize this



A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> step4m [
	^HelpTopic
		title:'Step4m configH'
		contents:
' This is the contents of a config.h file in the build directory.
It is used only in Unix builds in CMakeVMMaker.


It is called from the method ''extraVMSettings'' of  CogUnixConfig in CMakeVMMaker when CogUnixConfig sends the message:		self generateConfigH.

To provide a custom config.h CMakeVMakerSqueak subclasses that message ''self generateConfigH'' and routes the call
to ''generateConfigH: aBuildType''

From there, a block is evaluated appropriate for the build type that invokes a ''configHBuildXYZ'' method which can be overridden by you to 
return a custom config.h. The default is to return the base configH.


A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> step5 [
	^HelpTopic
		title:'Step5 set up ''cmake directory'' protocol'
		contents:
'The cmake directories protocol contains directory names for your platform, build directory 

See the chapter titled: ''An Explanation of Protocols in TCPaltformConfigForSqueak'' in 
HelpBrowser openOn:CMakeVMMakerSqueakDeveloperHelp  

The ones that your Configuration must implement are:

dirBuildPlatform
dirBuildLanguageVMMM


Basically, we are building a directory like this:
oscogvm/cmake.build.linux32.x86/squeak.cog.v3/build.assert 

which, when expressed as message names reduces to:

topDir/dirLinux32x86/squeakCogV3/dirBuildAssert

which are further reduced to 

topDir/dirBuildPlatform/dirBuildLanguageVMMM/dirBuildAssert

It is the two in the middle that you must customize. (dirBuildAssert is dynamically set by a Builder in a script, to be covered later)
To see how, take a look at the implementors of the two. its quite intuitive once you see it as it is based off our standard naming conventions.

SystemNavigation default browseMethodsWhoseNamesContain: ''dirBuildPlatform''
SystemNavigation default browseMethodsWhoseNamesContain: ''dirBuildLanguageVMMM''

For our purposes in this example, we want:


dirBuildPlatform
	^self dirLinux32x86
and

dirBuildLanguageVMMM
	^self squeakCogV3


A Reminder: Consistent Naming Conventions Are Our Friends!

'
]
