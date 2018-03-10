Class {
	#name : #CurrentImageCoInterpreterFacadeForSpurObjectRepresentation,
	#superclass : #CurrentImageCoInterpreterFacade,
	#instVars : [
		'hiddenRoots'
	],
	#category : #'VMMaker-Support'
}

{ #category : #'accessing class hierarchy' }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation class >> objectMemoryClass [
	^Spur32BitCoMemoryManager
]

{ #category : #'accessing class hierarchy' }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation class >> objectRepresentationClass [
	^CogObjectRepresentationFor32BitSpur
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> accessorDepthForPrimitiveIndex: anInteger [
	^StackInterpreterPrimitives primitiveAccessorDepthTable at: anInteger + 1
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
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> ceCheckAndMaybeRetryPrimitive: primIndex [
	^coInterpreter ceCheckAndMaybeRetryPrimitive: primIndex
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

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> defaultNativeStackFrameSize [
	^ coInterpreter defaultNativeStackFrameSize
]

{ #category : #'cog jit support' }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> eeInstantiateClassIndex: knownClassIndex format: objFormat numSlots: numSlots [
	self assert: knownClassIndex = ClassArrayCompactIndex.
	^self oopForObject: (Array new: numSlots)
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> fetchClassTagOf: anOop [
	| class |
	self assert: SmalltalkImage current isRunningSpur.
	class := (self objectForOop: anOop) class.
	^SystemVersion current isPharo
		ifTrue: [class basicIdentityHash]
		ifFalse: [class identityHash]
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> firstShortFormat [
	^objectMemory firstShortFormat
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> fixedFieldsOfClassFormatMask [
	^objectMemory fixedFieldsOfClassFormatMask
]

{ #category : #forwarding }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> followForwardedObjectFields: objOop toDepth: depth [ 
	"This is a noop in the facade"
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> formatMask [
	^objectMemory formatMask
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> formatOfClass: classOop [ 
	^(self objectForOop: classOop) format
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> formatShift [
	^objectMemory formatShift
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> getScavengeThreshold [
	^variables
		at: 'scavengeThreshold'
		ifAbsentPut: [objectMemory getScavengeThreshold ifNil: [16r24680]]
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> headerForSlots: numSlots format: formatField classIndex: classIndex [
	^objectMemory headerForSlots: numSlots format: formatField classIndex: classIndex
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> identityHashFullWordShift [
	^objectMemory identityHashFullWordShift
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> immutableBitMask [
	^objectMemory immutableBitMask
]

{ #category : #'cog jit support' }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> instSpecOfClassFormat: classFormat [
	^objectMemory instSpecOfClassFormat: classFormat
]

{ #category : #'cog jit support' }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> isFixedSizePointerFormat: formatOop [
	^objectMemory isFixedSizePointerFormat: formatOop
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
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> maybeMethodClassOf: methodObj seemsToBeInstantiating: format [
	"Answers if the code is installed in a class instantiating objects with the format. Used in primitive 
	 generation to make a quick path based on where the method is installed. This method cannot
	 be used as a guarantee as there can be false positive, it's just a heuristic.
	 Tries to interpret the last literal of the method as a behavior (more than 3 fields, 3rd field a Smi).
	 If it can be interpreted as a behavior, answers if instSpec matches the format, else answers false."
	<api>
	| maybeClassObj|
	maybeClassObj := (self objectForOop: methodObj) methodClass.
	^maybeClassObj isBehavior
	 and: [maybeClassObj instSpec = format]
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> needGCFlagAddress [
	^self addressForLabel: #needGCFlag
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> numSlotsFullShift [
	^objectMemory numSlotsFullShift
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> numSlotsMask [
	^objectMemory numSlotsMask
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> numTagBits [
	^objectMemory numTagBits
]

{ #category : #'private-cacheing' }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> objectForOop: anOop [
	"This is a keyAtValue: search and so needs speeding up either by a reverse map or a simple cache."
	^(anOop bitAnd: 3) caseOf: {
		[0] -> [anOop = cachedOop
				ifTrue: [cachedObject]
				ifFalse: [cachedObject := objectMap keyAtValue: anOop. "may raise Error"
						cachedOop := anOop. "Don't assign until accessed without error"
						cachedObject]].
		[1] -> [anOop signedIntFromLong >> 1].
		[2] -> [Character value: anOop >> 2].
		[3] -> [anOop signedIntFromLong >> 1] }
]

{ #category : #'object map' }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> oopForObject: o [
	^(o isInteger and: [o between: objectMemory minSmallInteger and: objectMemory maxSmallInteger])
		ifTrue: [o << 1 + 1]
		ifFalse:
			[o isCharacter
				ifTrue: [o asInteger << 2 + 2]
				ifFalse: [objectMap at: o ifAbsentPut: [objectMap size * 8 + (1024 * 1024)]]]
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> rawHashBitsOf: obj [
	^(self objectForOop: obj) identityHash
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> receiverTagBitsForMethod: methodOop [
	^(self objectForOop: methodOop) methodClass
		caseOf: {
			[SmallInteger]	-> [objectMemory smallIntegerTag].
			[Character]		-> [objectMemory characterTag].
			[SmallFloat64]	-> [objectMemory smallFloatTag] }
		otherwise: [0]
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> rememberedBitShift [
	^objectMemory rememberedBitShift
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> remoteIsInstVarAccess [
	^ 128
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSpurObjectRepresentation >> scavengeThreshold [
	^objectMemory scavengeThreshold
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
