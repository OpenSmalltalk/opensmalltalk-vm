Class {
	#name : #CurrentImageCoInterpreterFacadeForSpurObjectRepresentation,
	#superclass : #CurrentImageCoInterpreterFacade,
	#instVars : [
		'memMgr',
		'hiddenRoots'
	],
	#category : #'VMMaker-Support'
}

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation class >> objectRepresentationClass [
	^CogObjectRepresentationFor32BitSpur
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> baseHeaderSize [
	^SpurMemoryManager baseHeaderSize
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> classIndexMask [
	^self memMgr classIndexMask
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> classTableRootObj [
	hiddenRoots ifNil:
		[hiddenRoots := Array new: self memMgr classTableRootSlots + self memMgr hiddenRootSlots].
	^self oopForObject: hiddenRoots
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> memMgr [
	^memMgr ifNil:
		[memMgr := Spur32BitCoMemoryManager new]
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> memMgr: aSpurMemoryManagerSubclassInstance [
	memMgr := aSpurMemoryManagerSubclassInstance
]

{ #category : #testing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> tagMask [
	^self memMgr tagMask
]
