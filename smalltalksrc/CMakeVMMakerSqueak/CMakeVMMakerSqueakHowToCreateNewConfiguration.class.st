"
A CMakeVMMakerSqueakNewConfigurationStepByStepHelp itemizes the steps needed to create a new build configuration.

HelpBrowser openOn: CMakeVMMakerSqueakNewConfigurationStepByStepHelp
"
Class {
	#name : #CMakeVMMakerSqueakHowToCreateNewConfiguration,
	#superclass : #CMakeVMMakerSqueakHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakHowToCreateNewConfiguration class >> bookName [ 
	^'Setting up a Configuration. Step By Step.'
]

{ #category : #accessing }
CMakeVMMakerSqueakHowToCreateNewConfiguration class >> pages [
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
CMakeVMMakerSqueakHowToCreateNewConfiguration class >> step1 [
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
CMakeVMMakerSqueakHowToCreateNewConfiguration class >> step2 [
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
CMakeVMMakerSqueakHowToCreateNewConfiguration class >> step3 [
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
CMakeVMMakerSqueakHowToCreateNewConfiguration class >> step4 [
	^HelpTopic
		title:'Step 4. Customize the "cmake build type config" protocol'
		contents:
'TODO: summarize this

setGlobalOptions
setGlobalOptionsAfterDetermineSystem
setupDirectories
preferredIncludes
standardIncludes
compilerFlags
extraVMSettings
internalPlugins
externalPlugins
thirdpartyLibs
setExtraTargetProperties:aMaker
postBuildActions: aMaker

A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakHowToCreateNewConfiguration class >> step4a [
	^HelpTopic
		title:'Step 4a. setGlobalOptions'
		contents:
'TODO: summarize this



A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakHowToCreateNewConfiguration class >> step4b [
	^HelpTopic
		title:'Step 4b. setGlobalOptionsAfterDetermineSystem'
		contents:
'TODO: summarize this




A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakHowToCreateNewConfiguration class >> step4c [
	^HelpTopic
		title:'Step 4c. setupDirectories'
		contents:
'TODO: summarize this



A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakHowToCreateNewConfiguration class >> step4d [
	^HelpTopic
		title:'Step 4d. preferredIncludes'
		contents:
'TODO: summarize this


A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakHowToCreateNewConfiguration class >> step4e [
	^HelpTopic
		title:'Step 4e. standardIncludes'
		contents:
'TODO: summarize this



A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakHowToCreateNewConfiguration class >> step4f [
	^HelpTopic
		title:'Step 4f. compilerFlags'
		contents:
'TODO: summarize this



A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakHowToCreateNewConfiguration class >> step4g [
	^HelpTopic
		title:'Step 4g. extraVMSettings'
		contents:
'TODO: summarize this



A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakHowToCreateNewConfiguration class >> step4h [
	^HelpTopic
		title:'Step4h internalPlugins'
		contents:
'TODO: summarize this



A Reminder: Consistent Naming Conventions Are Our Friends!
'
]

{ #category : #pages }
CMakeVMMakerSqueakHowToCreateNewConfiguration class >> step4i [
	^HelpTopic
		title:'Step4i externalPlugins'
		contents:
'TODO: summarize this




A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakHowToCreateNewConfiguration class >> step4j [
	^HelpTopic
		title:'Step4j thirdpartyLibs'
		contents:
'TODO: summarize this


A Reminder: Consistent Naming Conventions Are Our Friends!


'
]

{ #category : #pages }
CMakeVMMakerSqueakHowToCreateNewConfiguration class >> step4k [
	^HelpTopic
		title:'Step4k setExtraTargetProperties:aMaker'
		contents:
'TODO: summarize this



A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakHowToCreateNewConfiguration class >> step4l [
	^HelpTopic
		title:'Step4k postBuildActions: aMaker'
		contents:
'TODO: summarize this



A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakHowToCreateNewConfiguration class >> step4m [
	^HelpTopic
		title:'Step4m configH'
		contents:
'TODO: summarize this



A Reminder: Consistent Naming Conventions Are Our Friends!

'
]

{ #category : #pages }
CMakeVMMakerSqueakHowToCreateNewConfiguration class >> step5 [
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
