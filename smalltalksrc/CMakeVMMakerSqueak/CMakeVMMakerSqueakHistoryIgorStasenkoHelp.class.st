Class {
	#name : #CMakeVMMakerSqueakHistoryIgorStasenkoHelp,
	#superclass : #CMakeVMMakerSqueakHistoryHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakHistoryIgorStasenkoHelp class >> bookName [ 
	^'Igor Sasenko''s CMake'
]

{ #category : #accessing }
CMakeVMMakerSqueakHistoryIgorStasenkoHelp class >> key [
	^'CMakeVMMakerSqueakHistoryIgorStasenkoHelp'
]

{ #category : #pages }
CMakeVMMakerSqueakHistoryIgorStasenkoHelp class >> overview [ 
	^HelpTopic
		title:'Overview'
		contents:
'CMakeVMMakerSqueak extends Igor Stasenko''s pharo work in CMMakeVMMaker. 

The system employs the Visitor design pattern in two places.

1. When a CPlatformConfigForSqueak subclass invokes CMakeVMGeneratorForSqueak>>generate passing itself as the visitor.
2. In SqueakCMakeVMMakerAbstractBuilder when Configuration information is cached in a CMakeVMakerConfigurationInfo.

The CPlatformConfigForSqueak makes heavy use of a Template pattern. This pattern is used extensively in the protocol ''cmake buildType redirects''.
This is used to force correct implementation of configurations. It also extends the pharo system to support the build types required for the 

Fairly extensive Tests are written to ensure correct implementation of Configurations.
'
]

{ #category : #pages }
CMakeVMMakerSqueakHistoryIgorStasenkoHelp class >> pages [
	^#( overview)
]
