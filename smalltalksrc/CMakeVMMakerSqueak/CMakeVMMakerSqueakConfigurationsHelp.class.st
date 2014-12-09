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
' CMakeVMMakerSqueak Configurations. encapsulate CMake output. 

The CMake encapsulation is eased by storing CMakeTemplates--small wrapper classes that encapsulate CMake constructs.

Configurations Are organized by Platform in specific Class Categories. Example: CMakeVMMakerSqueak-MacOSPowerPC contains all the configurations for that platform.

Configurations should adhere to a naming convention that mirror Eliot Miranda''s Autotools build system layout:
[Platform][Language][VM][Memory Model][Foo]Config. 

Examples: 
Plan9NewspeakSistaSpurConfig
MacOSXSqueakCogSpurConfig
Windows32SqueakStackV2JoesPersonalTotallyAweseomeConfig

Configurations can support the available build types: #build, #buildDebug, #buildAssert...etc.
Configurations can exclude themselves from being built by Builders.
Configurations can exclude themselves from supporting particular buildTypes.

For each buildType, a Configuration encapsulates CMake configuration parameters for that buildType..




'
]

{ #category : #accessing }
CMakeVMMakerSqueakConfigurationsHelp class >> pages [
	^#(overview CMakeVMMakerSqueakStepByStepNewConfigurationHelp CMakeVMMakerSqueakStepByStepNewPlatformHelp)
]
