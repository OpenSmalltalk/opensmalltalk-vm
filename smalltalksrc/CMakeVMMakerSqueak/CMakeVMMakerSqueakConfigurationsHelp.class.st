"
A CMakeVMMakerSqueakNewConfigurationStepByStepHelp itemizes the steps needed to create a new build configuration.

HelpBrowser openOn: CMakeVMMakerSqueakNewConfigurationStepByStepHelp
"
Class {
	#name : #CMakeVMMakerSqueakConfigurationsHelp,
	#superclass : #CMakeVMMakerSqueakDeveloperHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakConfigurationsHelp class >> bookName [ 
	^'Configurations'
]

{ #category : #accessing }
CMakeVMMakerSqueakConfigurationsHelp class >> key [
	^'CMakeVMMakerSqueakConfigurationsHelp'
]

{ #category : #pages }
CMakeVMMakerSqueakConfigurationsHelp class >> overview [
	^HelpTopic
		title:'Overview'
		contents:
'CMakeVMMakerSqueak Configurations. encapsulate CMake output. 

To get a sense of what the CMake output file looks like, open a Transcript and evaluate the following:

Transcript clear.
Transcript show: ((Linux64x86w32BitSqueakCogV3Config new) configureForBuildType: #build) contentForVmConfigCmake   


The CMake encapsulation makes heavy us of CMakeTemplates--small wrapper classes that encapsulate CMake constructs; 
It is the same idiom Seaside uses with its  Components

CMakeTemplate browseHierarchy.

Configurations Are organized by Platform in specific Class Categories. Example: CMakeVMMakerSqueak-MacOSPowerPC contains all the configurations for that platform.

Configurations should adhere to a naming convention that mirror Eliot Miranda''s Autotools build system layout:
[Platform][Language][VM][Memory Model][Foo]Config. 

Examples: 
Plan9NewspeakSistaSpurConfig
MacOSXSqueakCogSpurConfig
Windows32SqueakStackV2JoesPersonalTotallyAweseomeConfig

Configurations can support the available build types: #build, #buildDebug, #buildAssert...etc.
Configurations can exclude themselves from being built.
Configurations can exclude themselves from supporting particular build types.

For each buildType, a Configuration encapsulates the CMake configuration for that buildType..

To use a Configuration, we tell it to configure itself for a particular build type and then generate its output.


'
]

{ #category : #accessing }
CMakeVMMakerSqueakConfigurationsHelp class >> pages [
	^#(overview )

]
