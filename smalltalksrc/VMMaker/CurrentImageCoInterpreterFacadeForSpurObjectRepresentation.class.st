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
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation class >> objectMemoryClass [
	^Spur32BitCoMemoryManager
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation class >> objectRepresentationClass [
	^CogObjectRepresentationFor32BitSpur
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> arrayFormat [
	^objectMemory arrayFormat
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
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> getScavengeThreshold [
	^objectMemory getScavengeThreshold ifNil: [16r24680]
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> headerForSlots: numSlots format: formatField classIndex: classIndex [
	^objectMemory headerForSlots: numSlots format: formatField classIndex: classIndex
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

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> numSlotsMask [
	^objectMemory numSlotsMask
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> rememberedBitShift [
	^objectMemory rememberedBitShift
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> smallObjectBytesForSlots: numSlots [
	^objectMemory smallObjectBytesForSlots: numSlots
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> storeCheckBoundary [
	^objectMemory storeCheckBoundary ifNil: [16r12345678]
]

{ #category : #testing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> tagMask [
	^self memMgr tagMask
]
