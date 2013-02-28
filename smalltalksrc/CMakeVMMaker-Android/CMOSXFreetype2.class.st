Class {
	#name : #CMOSXFreetype2,
	#superclass : #CMFreetype2,
	#category : #'CMakeVMMaker-Libs'
}

{ #category : #accessing }
CMOSXFreetype2 class >> platformName [ 
	^'iOS'
]

{ #category : #testing }
CMOSXFreetype2 class >> supports: aConfig [ 
	"just for iPhone"

	^ (super supports: aConfig) 
		and: [ (aConfig isKindOf: StackIPhoneConfig) not ]
]
