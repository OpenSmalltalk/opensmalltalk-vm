Class {
	#name : #CurrentImageCoInterpreterFacadeForSpurObjectRepresentation,
	#superclass : #CurrentImageCoInterpreterFacade,
	#instVars : [
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

{ #category : #'cog jit support' }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> allocatePinnedSlots: nSlots [
	^(objectMemory allocatePinnedSlots: nSlots)
		ifNil: [nil]
		ifNotNil:
			[:objOop |
			 objectMap at: objOop put: objOop]
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
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> characterTag [
	^objectMemory characterTag
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> classIndexMask [
	^objectMemory classIndexMask
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> classTableMajorIndexShift [
	^objectMemory classTableMajorIndexShift
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> classTableMinorIndexMask [
	^objectMemory classTableMinorIndexMask
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> classTablePageSize [
	^objectMemory classTablePageSize
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> classTableRootObj [
	hiddenRoots ifNil:
		[hiddenRoots := Array new: objectMemory classTableRootSlots + objectMemory hiddenRootSlots].
	^self oopForObject: hiddenRoots
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> classTagForClass: classOop [
	^(self objectForOop: classOop) identityHash
]

{ #category : #'cog jit support' }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> eeInstantiateClassIndex: knownClassIndex format: objFormat numSlots: numSlots [
	self assert: knownClassIndex = ClassArrayCompactIndex.
	^self oopForObject: (Array new: numSlots)
]

{ #category : #forwarding }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> followForwardedObjectFields: objOop toDepth: depth [ 
	"This is a noop in the facade"
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> getScavengeThreshold [
	^objectMemory getScavengeThreshold ifNil: [16r24680]
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> headerForSlots: numSlots format: formatField classIndex: classIndex [
	^objectMemory headerForSlots: numSlots format: formatField classIndex: classIndex
]

{ #category : #'initialize-release' }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> initialize [
	super initialize.
	objectMemory
		initializeFreeSpaceForFacadeFrom: self startOfMemory
		to: self variablesBase
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> isForwardedObjectClassIndexPun [
	^objectMemory isForwardedObjectClassIndexPun
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> isImmediateClass: classOop [
	"Can't rely on the host image; may be running on SqueakV3.  hence..."
	^#(Character SmallInteger SmallFloat) includes: (self objectForOop: classOop) name
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
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> shiftForWord [
	^objectMemory shiftForWord
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> smallIntegerTag [
	^objectMemory smallIntegerTag
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
	^objectMemory tagMask
]
