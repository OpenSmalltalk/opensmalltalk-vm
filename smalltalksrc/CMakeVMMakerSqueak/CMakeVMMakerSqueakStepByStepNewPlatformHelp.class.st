"
A CMakeVMMakerSqueakNewConfigurationStepByStepHelp itemizes the steps needed to create a new build configuration.

HelpBrowser openOn: CMakeVMMakerSqueakNewConfigurationStepByStepHelp
"
Class {
	#name : #CMakeVMMakerSqueakStepByStepNewPlatformHelp,
	#superclass : #CMakeVMMakerSqueakConfigurationsHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakStepByStepNewPlatformHelp class >> bookName [ 
	^'Example Workflow: New Platform'
]

{ #category : #accessing }
CMakeVMMakerSqueakStepByStepNewPlatformHelp class >> key [
	^'CMakeVMMakerSqueakStepByStepNewPlatformHelp'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewPlatformHelp class >> overview [
	^HelpTopic
		title:'Overview'
		contents:
' Write me.
'
]

{ #category : #accessing }
CMakeVMMakerSqueakStepByStepNewPlatformHelp class >> pages [
	^#(overview step1)
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewPlatformHelp class >> step1 [
	^HelpTopic
		title:'Step 1. '
		contents:
' Write me
'
]
